//// Provides function to mock out the system time as seen by the tempo 
//// package for testing purposes.

import tempo
import tempo/duration

/// Freezes the current system time (as seen by this package) to the 
/// provided datetime. Time will not progress until the 'unfreeze_time' function 
/// is called.
/// 
/// ## Examples
/// 
/// ```gleam
/// mock.freeze_time(datetime.literal("2024-06-21T00:10:00.000Z"))
/// tempo.format_utc(tempo.ISO8601Seconds)
/// // -> "2024-06-21T00:10:00Z"
/// process.sleep(duration.seconds(10))
/// tempo.format_utc(tempo.ISO8601Seconds)
/// // -> "2024-06-21T00:10:00Z"
/// ```
pub fn freeze_time(at datetime: tempo.DateTime) {
  tempo.datetime_to_unix_micro(datetime)
  |> tempo.freeze_time_ffi
}

/// Unfreezes the current system time (as seen by this package) back to the
/// real system time.
/// 
/// ## Examples
/// 
/// ```gleam
/// mock.freeze_time(datetime.literal("2024-06-21T00:10:00.000Z"))
/// tempo.format_utc(tempo.ISO8601Seconds)
/// // -> "2024-06-21T00:10:00Z"
/// mock.unfreeze_time()
/// tempo.format_utc(tempo.ISO8601Seconds)
/// // -> "2025-01-31T22:48:00.000Z"
/// ```
pub fn unfreeze_time() {
  tempo.unfreeze_time_ffi()
}

/// Sets the current system time (as seen by this package) to the provided
/// datetime, allowing time to progress after with a speedup factor. If the 
/// speedup is 1.0, then time will progress at the normal rate after being set.
/// If the speedup is less than 1.0, time will progress slower than normal. If
/// the speedup is greater than 1.0, time will progress faster than normal. This
/// can be useful for quickly testing logic that may periodically wait for some
/// amount of time.
/// 
/// ## Examples
/// 
/// ```gleam
/// mock.set_time(datetime.literal("2024-06-21T00:10:00.000Z"), 1.0)
/// tempo.format_utc(tempo.ISO8601Seconds)
/// // -> "2024-06-21T00:00:00Z"
/// process.sleep(duration.seconds(10))
/// tempo.format_utc(tempo.ISO8601Seconds)
/// // -> "2024-06-21T00:00:10Z"
/// ```
/// 
/// ```gleam
/// mock.set_time(datetime.literal("2024-06-21T00:10:00.000Z"), 0.5)
/// tempo.format_utc(tempo.ISO8601Seconds)
/// // -> "2024-06-21T00:00:00Z"
/// process.sleep(duration.seconds(10))
/// tempo.format_utc(tempo.ISO8601Seconds)
/// // -> "2024-06-21T00:00:05Z"
/// ```
/// 
/// ```gleam
/// mock.set_time(datetime.literal("2024-06-21T00:10:00.000Z"), 3.0)
/// tempo.format_utc(tempo.ISO8601Seconds)
/// // -> "2024-06-21T00:00:00Z"
/// process.sleep(duration.seconds(10))
/// tempo.format_utc(tempo.ISO8601Seconds)
/// // -> "2024-06-21T00:00:30Z"
/// ```
pub fn set_time(to datetime: tempo.DateTime) {
  set_time_with_speedup(datetime, 1.0)
}

/// I am not sure if this should be part of the public API, it is still
/// experimental.
@internal
pub fn set_time_with_speedup(
  to datetime: tempo.DateTime,
  speedup speedup: Float,
) {
  tempo.datetime_to_unix_micro(datetime)
  |> tempo.set_reference_time_ffi(speedup)
}

/// Sets the current system time (as seen by this package) back to the real
/// system time.
/// 
/// ## Examples
/// 
/// ```gleam
/// mock.set_time(datetime.literal("2024-06-21T00:10:00.000Z"), 1.0)
/// tempo.format_utc(tempo.ISO8601Seconds)
/// // -> "2024-06-21T00:00:00Z"
/// mock.unset_time()
/// tempo.format_utc(tempo.ISO8601Seconds)
/// // -> "2025-02-01T09:12:00Z"
/// ```
pub fn unset_time() {
  tempo.unset_reference_time_ffi()
}

pub fn enable_sleep_warp() {
  tempo.set_sleep_warp_ffi(True)
}

pub fn disable_sleep_warp() {
  tempo.set_sleep_warp_ffi(False)
}

pub fn warp_time(by duration: tempo.Duration) {
  duration.as_microseconds(duration) |> tempo.add_warp_time_ffi
}

pub fn reset_warp_time() {
  tempo.reset_warp_time_ffi()
}
