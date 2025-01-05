//// Functions to use with the `Duration` type in Tempo.
//// 
//// ## Example
//// 
//// ```gleam
//// import gleam/io
//// import tempo/duration
//// import tempo/time
//// 
//// pub fn main() {
////   time.literal("01:42:11")
////   |> time.since(time.literal("00:00:01"))
////   |> duration.format
////   // -> "1 hour, 42 minutes, 10 seconds"
//// }
//// ```

import gleam/int
import gleam/list
import gleam/order
import gtempo/internal as unit
import tempo

/// Formats the duration as the specified unit with the specified number 
/// of decimals.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.minutes(1)
/// |> duration.format_as(duration.Second, decimals: 3)
/// // -> "60.000 minutes"
/// ```
pub fn format_as(
  duration: tempo.Duration,
  unit unit: Unit,
  decimals decimals: Int,
) -> String {
  as_internal_unit(unit)
  |> unit.format_as(duration |> tempo.duration_get_microseconds, _, decimals)
}

/// Formats the duration as the specified units, with the last unit having
/// the specified number of decimals.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.milliseconds(100_303)
/// |> duration.format_as_many(
///   [duration.Minute, duration.Second],
///   decimals: 2,
/// )
/// // -> "1 minute and 40.30 seconds"
/// ```
pub fn format_as_many(
  duration: tempo.Duration,
  units units: List(Unit),
  decimals decimals,
) {
  list.map(units, as_internal_unit)
  |> unit.format_as_many(
    duration |> tempo.duration_get_microseconds,
    _,
    decimals,
  )
}

/// Formats the duration as a string, inferring the units to use.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.microseconds(172_980_000_000)
/// |> duration.format
/// // -> "2 days, 0 hours, and 3 minutes"
/// ```
/// 
/// ```gleam
/// duration.seconds(691_332_000_000)
/// |> duration.format
/// // -> "1 week, 1 day, 0 hours, and 2 minutes"
/// ```
pub fn format(duration: tempo.Duration) {
  duration |> tempo.duration_get_microseconds |> unit.format
}

pub type Unit {
  YearImprecise
  Week
  Day
  Hour
  Minute
  Second
  Millisecond
  Microsecond
}

fn as_internal_unit(u: Unit) -> unit.Unit {
  case u {
    YearImprecise -> unit.Year
    Week -> unit.Week
    Day -> unit.Day
    Hour -> unit.Hour
    Minute -> unit.Minute
    Second -> unit.Second
    Millisecond -> unit.Millisecond
    Microsecond -> unit.Microsecond
  }
}

/// Creates a new duration from the value and unit provided.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.new(100, duration.Millisecond)
/// |> duration.as_seconds_fractional
/// // -> 0.0000001
/// ```
pub fn new(duration: Int, unit: Unit) -> tempo.Duration {
  case unit {
    YearImprecise -> years_imprecise(duration)
    Week -> weeks(duration)
    Day -> days(duration)
    Hour -> hours(duration)
    Minute -> minutes(duration)
    Second -> seconds(duration)
    Millisecond -> milliseconds(duration)
    Microsecond -> microseconds(duration)
  }
}

/// Creates a new duration value of the specified number of whole years,
/// assuming a year is 365 days.
///
/// ## Example
/// 
/// ```gleam
/// duration.years_imprecise(1)
/// |> duration.format
/// // -> "1 ~year"
/// ```
pub fn years_imprecise(years: Int) -> tempo.Duration {
  years |> unit.imprecise_years |> tempo.duration
}

/// Creates a new duration value of the specified number of whole weeks.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.weeks(3)
/// |> duration.format
/// // -> "3 weeks"
/// ```
pub fn weeks(weeks: Int) -> tempo.Duration {
  weeks |> unit.imprecise_weeks |> tempo.duration
}

/// Creates a new duration value of the specified number of whole days.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.days(3)
/// |> duration.format_as(duration.Hour, decimals: 0)
/// // -> "36 hours"
/// ```
pub fn days(days: Int) -> tempo.Duration {
  tempo.duration_days(days)
}

/// Creates a new duration value of the specified number of whole hours.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.hours(13)
/// |> duration.format
/// // -> "13 hours, 0 minutes, 0.0 seconds"
/// ```
pub fn hours(hours: Int) -> tempo.Duration {
  hours |> unit.hours |> tempo.duration
}

/// Creates a new duration value of the specified number of whole minutes.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.minutes(13)
/// |> duration.format
/// // -> "13 minutes and 0.0 seconds"
/// ```
pub fn minutes(minutes: Int) -> tempo.Duration {
  minutes |> unit.minutes |> tempo.duration
}

/// Creates a new duration value of the specified number of whole seconds.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.minutes(1)
/// |> duration.increase(by: duration.seconds(13))
/// |> duration.format_as(duration.Second, decimals: 0)
/// // -> "73 seconds"
/// ```
pub fn seconds(seconds: Int) -> tempo.Duration {
  seconds |> unit.seconds |> tempo.duration
}

/// Creates a new duration value of the specified number of whole milliseconds.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.seconds(1)
/// |> duration.increase(by: duration.milliseconds(13))
/// |> duration.format_as(duration.Millisecond, decimals: 0)
/// // -> "113 milliseconds"
/// ```
pub fn milliseconds(milliseconds: Int) {
  milliseconds |> unit.milliseconds |> tempo.duration
}

/// Creates a new duration value of the specified number of whole microseconds.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.milliseconds(1)
/// |> duration.increase(by: duration.microseconds(13))
/// |> duration.format_as(duration.Microsecond, decimals: 0)
/// // -> "113 microseconds"
/// ```
pub fn microseconds(microseconds: Int) {
  microseconds |> tempo.duration
}

/// Increases a duration by the specified duration. If a negative value is 
/// passed, the duration will be decreased.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.days(1)
/// |> duration.increase(by: duration.days(6))
/// |> duration.format_as(duration.Day, decimals: 0)
/// // -> "7 days"
/// ```
pub fn increase(a: tempo.Duration, by b: tempo.Duration) -> tempo.Duration {
  tempo.duration_increase(a, b)
}

/// Decreases a duration by the specified duration. If a negative value is 
/// passed, the duration will be increased.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.days(1)
/// |> duration.decrease(by: duration.days(6))
/// |> duration.format_as(duration.Day, decimals: 0)
/// // -> "-5 days"
/// ```
/// 
/// ```gleam
/// duration.days(1)
/// |> duration.decrease(by: duration.days(6))
/// |> duration.abosulte
/// |> duration.format_as(duration.Day, decimals: 0)
/// // -> "5 days"
/// ```
pub fn decrease(a: tempo.Duration, by b: tempo.Duration) -> tempo.Duration {
  tempo.duration_decrease(a, by: b)
}

/// Converts a duration to the specified whole units.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.minutes(1)
/// |> duration.as_unit(duration.Second)
/// // -> 60
/// ```
pub fn as_unit(duration: tempo.Duration, unit: Unit) -> Int {
  as_internal_unit(unit)
  |> unit.as_unit(duration |> tempo.duration_get_microseconds, _)
}

/// Converts a duration to the specified fractional units.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.days(8)
/// |> duration.as_unit_fractional(duration.Week)
/// // -> 1.142857143
/// ```
pub fn as_unit_fractional(duration: tempo.Duration, unit: Unit) -> Float {
  as_internal_unit(unit)
  |> unit.as_unit_fractional(duration |> tempo.duration_get_microseconds, _)
}

/// Converts a duration to the equivalent number of whole years, assuming 
/// a year is 365 days.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.days(375)
/// |> duration.as_years_imprecise
/// // -> 1
/// ```
pub fn as_years_imprecise(duration: tempo.Duration) -> Int {
  duration |> tempo.duration_get_microseconds |> unit.as_years_imprecise
}

/// Converts a duration to the equivalent number of fractional years, 
/// assuming a year is 365 days.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.days(375)
/// |> duration.as_years_fractional_imprecise
/// // -> 1.02739726
/// ```
pub fn as_years_fractional_imprecise(duration: tempo.Duration) -> Float {
  duration
  |> tempo.duration_get_microseconds
  |> unit.as_years_imprecise_fractional
}

/// Converts a duration to the equivalent number of whole weeks.
pub fn as_weeks(duration: tempo.Duration) -> Int {
  duration |> tempo.duration_get_microseconds |> unit.as_weeks_imprecise
}

/// Converts a duration to the equivalent number of fractional weeks.
pub fn as_weeks_fractional(duration: tempo.Duration) -> Float {
  duration
  |> tempo.duration_get_microseconds
  |> unit.as_weeks_imprecise_fractional
}

/// Converts a duration to the equivalent number of whole days.
pub fn as_days(duration: tempo.Duration) -> Int {
  tempo.duration_as_days(duration)
}

/// Converts a duration to the equivalent number of fractional days.
pub fn as_days_fractional(duration: tempo.Duration) -> Float {
  duration |> tempo.duration_get_microseconds |> unit.as_days_fractional
}

/// Converts a duration to the equivalent number of whole hours.
pub fn as_hours(duration: tempo.Duration) -> Int {
  duration |> tempo.duration_get_microseconds |> unit.as_hours
}

/// Converts a duration to the equivalent number of fractional hours.
pub fn as_hours_fractional(duration: tempo.Duration) -> Float {
  duration |> tempo.duration_get_microseconds |> unit.as_hours_fractional
}

/// Converts a duration to the equivalent number of whole minutes.
pub fn as_minutes(duration: tempo.Duration) -> Int {
  duration |> tempo.duration_get_microseconds |> unit.as_minutes
}

/// Converts a duration to the equivalent number of fractional minutes.
pub fn as_minutes_fractional(duration: tempo.Duration) -> Float {
  duration |> tempo.duration_get_microseconds |> unit.as_minutes_fractional
}

/// Converts a duration to the equivalent number of whole seconds.
pub fn as_seconds(duration: tempo.Duration) -> Int {
  duration |> tempo.duration_get_microseconds |> unit.as_seconds
}

/// Converts a duration to the equivalent number of fractional seconds.
pub fn as_seconds_fractional(duration: tempo.Duration) -> Float {
  duration |> tempo.duration_get_microseconds |> unit.as_seconds_fractional
}

/// Converts a duration to the equivalent number of whole milliseconds.
pub fn as_milliseconds(duration: tempo.Duration) -> Int {
  duration |> tempo.duration_get_microseconds |> unit.as_milliseconds
}

/// Converts a duration to the equivalent number of fractional milliseconds.
pub fn as_milliseconds_fractional(duration: tempo.Duration) -> Float {
  duration |> tempo.duration_get_microseconds |> unit.as_milliseconds_fractional
}

/// Converts a duration to the equivalent number of whole microseconds.
pub fn as_microseconds(duration: tempo.Duration) -> Int {
  duration |> tempo.duration_get_microseconds |> unit.as_microseconds
}

/// Converts a duration to the equivalent number of fractional microseconds.
/// Microseconds are the smallest unit of time that are used in this package.
pub fn as_microseconds_fractional(duration: tempo.Duration) -> Float {
  duration |> tempo.duration_get_microseconds |> unit.as_microseconds_fractional
}

/// Compares two durations.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.days(1)
/// |> duration.compare(to: duration.days(1))
/// // -> order.Eq
/// ```
/// 
/// ```gleam
/// duration.days(1)
/// |> duration.compare(to: duration.days(2))
/// // -> order.Lt
/// ```
pub fn compare(a: tempo.Duration, to b: tempo.Duration) -> order.Order {
  int.compare(
    tempo.duration_get_microseconds(a),
    tempo.duration_get_microseconds(b),
  )
}

/// Checks if a duration is less than another duration.
///
/// ## Example
///
/// ```gleam
/// duration.days(1)
/// |> duration.is_less(than: duration.hours(25))
/// // -> True
/// ```
///
/// ```gleam
/// duration.days(1)
/// |> duration.is_less(than: duration.days(1))
/// // -> False
/// ```
pub fn is_less(a: tempo.Duration, than b: tempo.Duration) -> Bool {
  compare(a, b) == order.Lt
}

/// Checks if a duration is less than or equal to another duration.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.days(1)
/// |> duration.is_less_or_equal(to: duration.days(2))
/// // -> True
/// ```
/// 
/// ```gleam
/// duration.days(1)
/// |> duration.is_less_or_equal(to: duration.days(1))
/// // -> True
/// ```
pub fn is_less_or_equal(a: tempo.Duration, to b: tempo.Duration) -> Bool {
  compare(a, b) == order.Lt || compare(a, b) == order.Eq
}

/// Checks if a duration is equal to another duration.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.weeks(1)
/// |> duration.is_equal(to: duration.days(7))
/// // -> True
/// ```
/// 
/// ```gleam
/// duration.days(1)
/// |> duration.is_equal(to: duration.days(2))
/// // -> False
/// ```
pub fn is_equal(a: tempo.Duration, to b: tempo.Duration) -> Bool {
  compare(a, b) == order.Eq
}

/// Checks if a duration is greater than another duration.
///
/// ## Example
///
/// ```gleam
/// duration.days(1)
/// |> duration.is_greater(than: duration.days(2))
/// // -> False
/// ```
///
/// ```gleam
/// duration.weeks(1)
/// |> duration.is_greater(than: duration.days(1))
/// // -> True
/// ``` 
pub fn is_greater(a: tempo.Duration, than b: tempo.Duration) -> Bool {
  compare(a, b) == order.Gt
}

/// Checks if a duration is greater than or equal to another duration.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.days(1)
/// |> duration.is_greater_or_equal(to: duration.days(2))
/// // -> False
/// ```
/// 
/// ```gleam
/// duration.seconds(60)
/// |> duration.is_greater_or_equal(to: duration.minutes(1))
/// // -> True
/// ```
pub fn is_greater_or_equal(a: tempo.Duration, to b: tempo.Duration) -> Bool {
  compare(a, b) == order.Gt || compare(a, b) == order.Eq
}

/// Returns the absolute value of a duration.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.days(1)
/// |> duration.decrease(by: duration.days(6))
/// |> duration.abosulte
/// |> duration.format_as(duration.Day, decimals: 0)
/// // -> "5 days"
/// ```
pub fn absolute(duration: tempo.Duration) -> tempo.Duration {
  tempo.duration_absolute(duration)
}

/// Returns the inverse of a duration.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.days(1)
/// |> duration.inverse
/// |> duration.format_as(duration.Day, decimals: 0)
/// // -> "-1 days"
/// ```
/// 
pub fn inverse(duration: tempo.Duration) -> tempo.Duration {
  -{ duration |> tempo.duration_get_microseconds } |> tempo.duration
}

/// Checks if a duration is negative.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.days(1)
/// |> duration.is_negative
/// // -> False
/// ```
/// 
/// ```gleam
/// case 
///   time.literal("13:42:05")
///   |> time.difference(from: time.literal("13:42:10"))
///   |> duration.is_negative
/// {
///   True -> "we are ahead of time!"
///   False -> "We are either on time or late!"
/// }
/// ```
pub fn is_negative(duration: tempo.Duration) -> Bool {
  duration |> tempo.duration_get_microseconds < 0
}
