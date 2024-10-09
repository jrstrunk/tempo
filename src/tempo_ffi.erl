-module(tempo_ffi).

-export([
    now/0,
    now_monotonic/0,
    now_unique/0,
    local_offset/0,
    current_year/0
]).

now() -> erlang:system_time(nanosecond).

now_monotonic() -> erlang:monotonic_time(nanosecond).

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
