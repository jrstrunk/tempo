%% Erlang target support for tempo/time_zone.
-module(tempo_time_zone_ffi).

-export([local_timezone/0, is_valid_timezone/1, calculate_offset/7]).

-define(DATABASE_KEY, {tempo_time_zone_ffi, os_database}).

%% Seconds from year 0 to the Unix epoch, for converting the gregorian seconds
%% that the `calendar` module works in into the unix seconds `gleam_time` wants.
-define(UNIX_EPOCH_GREGORIAN_SECONDS, 62167219200).

%% Whether the operating system's database knows `Timezone`. This backs
%% `time_zone.new/1`, whose JavaScript counterpart asks `Intl` instead.
is_valid_timezone(Timezone) ->
    case os_database() of
        {ok, Db} ->
            lists:member(Timezone, tzif@database:get_available_timezones(Db));
        _ ->
            false
    end.

%% The offset from UTC, in minutes, that `Timezone` was at the given UTC
%% wall-clock time, according to the operating system's database.
%%
%% This deliberately duplicates the offset lookup inside `time_zone.from_database`.
%% That one serves caller supplied databases and so must run on both targets;
%% this one keeps the whole `new/1` path in FFI on Erlang, mirroring the
%% `Intl` implementation in tempo_time_zone_ffi.mjs. The two must be kept in
%% step — `time_zone_test.ffi_matches_gleam_implementation_test` checks that.
%%
%% Any failure yields 0, matching the JavaScript side. Callers never observe it
%% because `new/1` checks `is_valid_timezone/1` first.
calculate_offset(Year, Month, Day, Hour, Minute, Second, Timezone) ->
    case os_database() of
        {ok, Db} ->
            zone_offset_minutes(Db, Year, Month, Day, Hour, Minute, Second, Timezone);
        _ ->
            0
    end.

zone_offset_minutes(Db, Year, Month, Day, Hour, Minute, Second, Timezone) ->
    % datetime_to_gregorian_seconds/1 raises on a date that does not exist, so
    % an out of range field yields 0 rather than taking down the caller.
    try
        GregorianSeconds =
            calendar:datetime_to_gregorian_seconds(
                {{Year, Month, Day}, {Hour, Minute, Second}}
            ),
        Timestamp =
            gleam@time@timestamp:from_unix_seconds(
                GregorianSeconds - ?UNIX_EPOCH_GREGORIAN_SECONDS
            ),
        case tzif@database:get_zone_parameters(Timestamp, Timezone, Db) of
            % A Gleam record is a tagged tuple, so ZoneParameters(offset, is_dst,
            % designation) reaches Erlang as this shape.
            {ok, {zone_parameters, Offset, _IsDst, _Designation}} ->
                {OffsetSeconds, _Nanoseconds} =
                    gleam@time@duration:to_seconds_and_nanoseconds(Offset),
                % `div` truncates toward zero, as Gleam's `/` on Ints does, so
                % both implementations agree on sub-minute historical offsets.
                OffsetSeconds div 60;
            _ ->
                0
        end
    catch
        _:_ -> 0
    end.

%% Loads the operating system's TZif database via `tzif`, memoized in
%% persistent_term. Parsing /usr/share/zoneinfo means reading several hundred
%% files, so it must not happen once per offset lookup. Returns the Gleam
%% `Result(TzDatabase, Nil)` that `tzif@database:load_from_os/0` produces,
%% caching failures too so a machine without a zoneinfo tree does not rescan on
%% every call. Two processes racing here just load twice and store the same
%% thing, which is harmless.
os_database() ->
    case persistent_term:get(?DATABASE_KEY, undefined) of
        undefined ->
            Result = tzif@database:load_from_os(),
            persistent_term:put(?DATABASE_KEY, Result),
            Result;
        Result ->
            Result
    end.

%% Host time zone detection. Mirrors what the standard C library and most tz
%% libraries do, in order:
%%
%%   1. The TZ environment variable (a leading ":" is stripped, per POSIX).
%%      A path value is reduced to the part after "zoneinfo/".
%%   2. The symlink target of /etc/localtime, which is how most Linux distros
%%      and macOS record the zone (macOS points into /var/db/timezone).
%%   3. The contents of /etc/timezone (Debian/Ubuntu) or
%%      /etc/sysconfig/clock (older RHEL/SUSE).
%%   4. "UTC" as a last resort.
%%
%% Only IANA-style names are accepted; POSIX TZ strings such as "EST5EDT,M3.2.0"
%% are not zone names and are skipped so a later source can answer.

local_timezone() ->
    first_ok([fun from_env/0, fun from_localtime_link/0, fun from_config_files/0], <<"UTC">>).

first_ok([], Default) ->
    Default;
first_ok([F | Rest], Default) ->
    case F() of
        {ok, Name} -> Name;
        error -> first_ok(Rest, Default)
    end.

from_env() ->
    case os:getenv("TZ") of
        false ->
            error;
        Value ->
            % POSIX allows a leading ":" to force the "implementation defined"
            % (i.e. file based) interpretation of the value.
            zone_name(string:trim(string:trim(Value, leading, ":")))
    end.

from_localtime_link() ->
    case file:read_link_all("/etc/localtime") of
        {ok, Target} -> zone_name(Target);
        {error, _} -> error
    end.

from_config_files() ->
    first_of([
        fun() -> read_zone_file("/etc/timezone") end,
        fun() -> read_clock_file("/etc/sysconfig/clock") end
    ]).

first_of([]) ->
    error;
first_of([F | Rest]) ->
    case F() of
        {ok, Name} -> {ok, Name};
        error -> first_of(Rest)
    end.

read_zone_file(Path) ->
    case file:read_file(Path) of
        {ok, Contents} -> zone_name(string:trim(Contents));
        {error, _} -> error
    end.

%% /etc/sysconfig/clock holds shell style assignments, one of which is
%% ZONE="Area/City".
read_clock_file(Path) ->
    case file:read_file(Path) of
        {error, _} ->
            error;
        {ok, Contents} ->
            Lines = string:split(Contents, "\n", all),
            case [L || L <- Lines, string:prefix(string:trim(L), "ZONE=") =/= nomatch] of
                [Line | _] ->
                    Value = string:prefix(string:trim(Line), "ZONE="),
                    zone_name(string:trim(string:trim(Value), both, "\"'"));
                [] ->
                    error
            end
    end.

%% Reduces a raw value to an IANA zone name, or `error` if it is not one.
zone_name(Value) ->
    Binary = unicode:characters_to_binary(Value),
    case Binary of
        <<>> ->
            error;
        _ ->
            % A path such as "/usr/share/zoneinfo/America/New_York" or the
            % relative "../usr/share/zoneinfo/America/New_York" keeps only the
            % part below the database root.
            Name =
                case string:split(Binary, <<"zoneinfo/">>, trailing) of
                    [_, Rest] -> Rest;
                    [Whole] -> Whole
                end,
            case is_zone_name(Name) of
                true -> {ok, Name};
                false -> error
            end
    end.

%% Zone names are relative paths of alphanumeric components, and may contain
%% "+", "-", "_" and ".". This rejects POSIX TZ strings (which contain digits
%% right after letters and often ",") and anything path-traversing.
is_zone_name(<<>>) ->
    false;
is_zone_name(Name) ->
    case binary:match(Name, [<<"..">>, <<",">>]) of
        nomatch ->
            binary:first(Name) =/= $/ andalso
                lists:all(fun is_zone_char/1, binary_to_list(Name)) andalso
                not is_posix_tz(Name);
        _ ->
            false
    end.

is_zone_char(C) ->
    (C >= $a andalso C =< $z) orelse
        (C >= $A andalso C =< $Z) orelse
        (C >= $0 andalso C =< $9) orelse
        lists:member(C, "/+-_.").

%% A POSIX TZ string like "EST5EDT" or "GMT0BST" has an offset digit that is
%% not preceded by "/" or one of the digits of a numbered zone such as
%% "Etc/GMT+5". Names containing no "/" but containing a digit are treated as
%% POSIX strings.
is_posix_tz(Name) ->
    binary:match(Name, <<"/">>) =:= nomatch andalso
        lists:any(fun(C) -> C >= $0 andalso C =< $9 end, binary_to_list(Name)).
