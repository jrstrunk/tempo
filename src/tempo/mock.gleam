//// Provides functions to mock the system time as seen by the tempo 
//// package for testing purposes.
//// 
//// There are four main ways to mock time for testing in this package:
//// 
//// ## Freezing the system time
//// By freezing the system time to a specific time so that calls to the current
//// system time will return a known value, you can reliably test code that 
//// gets the current system time once. Frozen time can also be warped, allowing
//// for fine-grained control over the system time. More on that below.
//// 
//// ```gleam
//// import tempo
//// import tempo/mock
//// import gleeunit/should
//// 
//// pub fn format_system_time() {
////   tempo.format_utc(tempo.Custom("dddd @ HH:mm:ss"))
//// }
//// 
//// pub fn format_system_time_test() {
////   // We can test that this function returns the expected value by first
////   // freezing the system time to a specific, known time.
////   mock.freeze_time(datetime.literal("2024-06-21T11:10:35.000Z"))
//// 
////   format_system_time()
////   |> should.equal("Friday @ 11:10:35")
//// 
////   mock.unfreeze_time()
//// }
//// ```
//// 
//// ## Setting the current system time to a reference time
//// By setting the current system time to a specific reference time and   
//// letting it progress forward from there, you can reliably test code
//// that may get the system time multiple times but executes different 
//// logic depending on the date or time of day.
//// 
//// An example of this would be complex, so the implementation is left out.
//// 
//// ```gleam
//// import app
//// import tempo
//// import tempo/mock
//// import gleeunit/should
//// 
//// pub fn thursday_run_test() {
////   // We can test that this function returns the expected value on Thursdays
////   // by first setting the current system time to a reference time.
////   mock.set_time(datetime.literal("2024-06-20T11:10:35.000Z"))
//// 
////   app.run()
////   |> should.equal(42)
//// 
////   mock.unset_time()
//// }
//// ```
//// 
//// ## Warping system time instead of sleeping
//// By changing sleep operations to time warps, you can instantly test any 
//// function with sleeps in it. Sleeps will warp frozen time when this is 
//// enabled.
//// 
//// ```gleam
//// import app
//// import tempo
//// import tempo/instant
//// import tempo/mock
//// import gleeunit/should
//// 
//// pub fn do_logic_after_sleep() {
////  tempo.sleep(duration.seconds(10))
////  app.do_logic()
//// }
//// 
//// pub fn do_logic_after_sleep_test() {
////  tempo.enable_sleep_warp()
//// 
////  let start = instant.now()
////  do_logic_after_sleep()
//// 
////  // This test executes immediately, but it appears to have taken 10
////  // seconds to this package.
////  instant.since(start) |> duration.as_seconds |> should.equal(10)
//// 
////  tempo.disable_sleep_warp()
//// }
//// ```
//// 
//// ## Manually warping system time
//// By manually warping the system time by a specific duration, you can instantly
//// run logic after exact durations. You can also warp time when it is frozen
//// to manually progress it.
//// 
//// ```gleam
//// import app
//// import tempo
//// import tempo/mock
//// 
//// pub fn test_spaced_calls() {
////   mock.freeze_time(datetime.literal("2024-06-21T00:10:00.000Z"))
//// 
////   app.do_side_effect()
////   |> should.equal(Ok(Nil))
//// 
////   mock.warp_time(duration.minutes(30))
////
////   app.do_side_effect()
////   |> should.equal(Ok(Nil))
//// 
////   mock.unfreeze_time()
////   mock.reset_warp_time()
//// }

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

/// Resets the current system time (as seen by this package) back to the real
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

/// Enables warping of the system time (as seen by this package) instead of
/// sleeping when calls to `tempo.sleep` are made. This is useful for instantly
/// testing code that may have sleeps in it.
/// 
/// ## Examples
/// 
/// ```gleam
/// mock.enable_sleep_warp()
/// tempo.sleep(duration.seconds(10))
/// // -> This will warp perceived system time to 10 seconds in the future 
/// // instead of waiting for 10 real seconds.
/// ```
pub fn enable_sleep_warp() {
  tempo.set_sleep_warp_ffi(True)
}

/// Disables warping of the system time (as seen by this package) instead of
/// sleeping when calls to `tempo.sleep` are made.
/// 
/// ## Examples
/// 
/// ```gleam
/// mock.enable_sleep_warp()
/// do_some_sleepy_test()
/// mock.disable_sleep_warp()
/// ```
pub fn disable_sleep_warp() {
  tempo.set_sleep_warp_ffi(False)
}

/// Warps the current system time (as seen by this package) by the provided
/// duration. This is useful for instantly testing code after a precise duration.
pub fn warp_time(by duration: tempo.Duration) {
  duration.as_microseconds(duration) |> tempo.add_warp_time_ffi
}

/// Resets the warp time (as seen by this package) back to the real system time.
/// This will clear any warp time added by either `mock.warp_time` or 
/// `mock.enable_sleep_warp` with subsequent calls to `tempo.sleep`.
/// 
/// ## Examples
/// 
/// ```gleam
/// mock.enable_sleep_warp()
/// tempo.sleep(duration.seconds(10))
/// tempo.format_utc(tempo.ISO8601Seconds)
/// // -> "2024-06-21T00:10:00Z"
/// mock.reset_warp_time()
/// tempo.format_utc(tempo.ISO8601Seconds)
/// // -> "2024-06-21T00:00:00Z"
/// ```
pub fn reset_warp_time() {
  tempo.reset_warp_time_ffi()
}
