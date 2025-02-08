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
    unset_reference_time/0,
    sleep/1,
    set_sleep_warp/1,
    add_warp_time/1,
    reset_warp_time/0
]).

-define(MOCK_TIME_TABLE, tempo_mock_time).

% Make sure table exists before any operation
init_mock_table() ->
    case ets:info(?MOCK_TIME_TABLE) of
        undefined ->
            ets:new(?MOCK_TIME_TABLE, [set, public, named_table]);
        _ ->
            ok
    end.

now() ->
    init_mock_table(),
    case ets:lookup(?MOCK_TIME_TABLE, frozen_time) of
        [{frozen_time, Value}] ->
            Value + get_warp_time();
        [] ->
            case ets:lookup(?MOCK_TIME_TABLE, set_time) of
                [{set_time, {ReferenceTime, RealStart, _, SpeedupFactor}}] ->
                    RealElapsed = get_warped_now() - RealStart,
                    SpedUpElapsed = round(RealElapsed * SpeedupFactor),
                    ReferenceTime + SpedUpElapsed;
                [] ->
                    get_warped_now()
            end
    end.

freeze_time(Value) when is_integer(Value) ->
    init_mock_table(),
    ets:insert(?MOCK_TIME_TABLE, {frozen_time, Value}),
    nil.

unfreeze_time() ->
    init_mock_table(),
    catch ets:delete(?MOCK_TIME_TABLE, frozen_time),
    nil.

set_reference_time(Value, SpeedupFactor) ->
    init_mock_table(),
    ets:insert(
        ?MOCK_TIME_TABLE,
        {
            set_time,
            {
                Value,
                get_warped_now(),
                get_warped_now_monotonic(),
                SpeedupFactor
            }
        }
    ),
    nil.

unset_reference_time() ->
    init_mock_table(),
    catch ets:delete(?MOCK_TIME_TABLE, set_time),
    nil.

sleep(Millseconds) ->
    init_mock_table(),
    case ets:lookup(?MOCK_TIME_TABLE, do_sleep_warp) of
        [{do_sleep_warp, true}] ->
            add_warp_time(Millseconds * 1000);
        [] ->
            timer:sleep(Millseconds)
    end,
    nil.

set_sleep_warp(DoWarp) ->
    init_mock_table(),
    case DoWarp of
        true ->
            ets:insert(?MOCK_TIME_TABLE, {do_sleep_warp, DoWarp});
        false ->
            ets:delete(?MOCK_TIME_TABLE, do_sleep_warp)
    end,
    nil.

reset_warp_time() ->
    init_mock_table(),
    catch ets:delete(?MOCK_TIME_TABLE, warp_time),
    nil.

add_warp_time(Microseconds) ->
    init_mock_table(),
    case ets:lookup(?MOCK_TIME_TABLE, warp_time) of
        [{warp_time, WarpTime}] ->
            ets:insert(?MOCK_TIME_TABLE, {warp_time, WarpTime + Microseconds}),
            nil;
        [] ->
            ets:insert(?MOCK_TIME_TABLE, {warp_time, Microseconds}),
            nil
    end,
    nil.

get_warp_time() ->
    init_mock_table(),
    case ets:lookup(?MOCK_TIME_TABLE, warp_time) of
        [{warp_time, WarpTime}] ->
            WarpTime;
        [] ->
            0
    end.

get_warped_now() ->
    erlang:system_time(microsecond) + get_warp_time().

get_warped_now_monotonic() ->
    erlang:monotonic_time(microsecond) + get_warp_time().

now_monotonic() ->
    init_mock_table(),
    case ets:lookup(?MOCK_TIME_TABLE, frozen_time) of
        [{frozen_time, Value}] ->
            Value + get_warp_time();
        [] ->
            case ets:lookup(?MOCK_TIME_TABLE, set_time) of
                [{set_time, {ReferenceTime, _, RealMonotonicStart, SpeedupFactor}}] ->
                    RealElapsed = get_warped_now_monotonic() - RealMonotonicStart,
                    SpedUpElapsed = round(RealElapsed * SpeedupFactor),
                    ReferenceTime + SpedUpElapsed;
                [] ->
                    get_warped_now_monotonic()
            end
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
