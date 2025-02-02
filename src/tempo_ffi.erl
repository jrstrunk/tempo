-module(tempo_ffi).

-export([
    now/0,
    now_monotonic/0,
    now_unique/0,
    local_offset/0,
    current_year/0,
    freeze_time/1,
    unfreeze_time/0,
    set_reference_time/2,
    unset_reference_time/0
]).

-define(TIME_TABLE, tempo_mock_time).

% Initialize ETS table in module init
-on_load(init/0).

% Make sure table exists before any operation
ensure_table() ->
    case ets:info(?TIME_TABLE) of
        undefined ->
            ets:new(?TIME_TABLE, [set, public, named_table]);
        _ ->
            ok
    end.

init() ->
    ets:new(?TIME_TABLE, [set, public, named_table]),
    ok.

now() ->
    ensure_table(),
    case ets:lookup(?TIME_TABLE, mock_time) of
        [{mock_time, Value}] ->
            Value;
        [] ->
            case ets:lookup(?TIME_TABLE, reference_time_delta) of
                [{reference_time_delta, {ReferenceTime, RealStart, _, SpeedupFactor}}] ->
                    RealElapsed = erlang:system_time(microsecond) - RealStart,
                    SpedUpElapsed = round(RealElapsed * SpeedupFactor),
                    ReferenceTime + SpedUpElapsed;
                [] ->
                    erlang:system_time(microsecond)
            end
    end.

freeze_time(Value) when is_integer(Value) ->
    ensure_table(),
    ets:insert(?TIME_TABLE, {mock_time, Value}),
    nil.

unfreeze_time() ->
    ensure_table(),
    catch ets:delete(?TIME_TABLE, mock_time),
    nil.

set_reference_time(Value, SpeedupFactor) ->
    ensure_table(),
    ets:insert(
        ?TIME_TABLE,
        {
            reference_time_delta,
            {
                Value,
                erlang:system_time(microsecond),
                erlang:monotonic_time(microsecond),
                SpeedupFactor
            }
        }
    ),
    nil.

unset_reference_time() ->
    ensure_table(),
    catch ets:delete(?TIME_TABLE, reference_time_delta),
    nil.

now_monotonic() ->
    case ets:lookup(?TIME_TABLE, reference_time_delta) of
        [{reference_time_delta, {ReferenceTime, _, RealMonotonicStart, SpeedupFactor}}] ->
            RealElapsed = erlang:monotonic_time(microsecond) - RealMonotonicStart,
            SpedUpElapsed = round(RealElapsed * SpeedupFactor),
            ReferenceTime + SpedUpElapsed;
        [] ->
            erlang:monotonic_time(microsecond)
    end.

now_unique() -> erlang:unique_integer([positive, monotonic]).

local_offset() ->
    {Date, Time} = calendar:local_time(),
    [UTC] = calendar:local_time_to_universal_time_dst({Date, Time}),
    (calendar:datetime_to_gregorian_seconds({Date, Time}) -
        calendar:datetime_to_gregorian_seconds(UTC)) div
        60.

current_year() ->
    {{Year, _, _}, _} = calendar:local_time(),
    Year.
