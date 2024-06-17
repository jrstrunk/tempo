import gleam/float
import gleam/int
import gleam/list
import gleam/order
import gleam/string
import tempo

const year_nanoseconds = 31_449_600_000_000_000

const week_nanoseconds = 604_800_000_000_000

@internal
pub const day_nanoseconds = 86_400_000_000_000

@internal
pub const hour_nanoseconds = 3_600_000_000_000

@internal
pub const minute_nanoseconds = 60_000_000_000

@internal
pub const second_nanoseconds = 1_000_000_000

@internal
pub const millisecond_nanoseconds = 1_000_000

@internal
pub const mircosecond_nanoseconds = 1000

pub opaque type MonotomicTime {
  MonotomicTime(nanoseconds: Int)
}

pub fn start() -> MonotomicTime {
  tempo.now_utc() |> MonotomicTime
}

pub fn stop(start: MonotomicTime) -> tempo.Duration {
  tempo.now_utc() - start.nanoseconds |> tempo.Duration
}

pub fn format_as(
  duration: tempo.Duration,
  unit unit: Unit,
  decimals decimals: Int,
) -> String {
  let in_unit = as_unit_fractional(duration, unit)

  let decimal =
    float.truncate(in_unit)
    |> int.to_float
    |> float.subtract(in_unit, _)

  let decimal_formatted =
    decimal
    |> float.to_string
    |> string.slice(at_index: 2, length: decimals)
    |> string.pad_right(to: decimals, with: "0")

  let whole =
    float.truncate(in_unit)
    |> int.to_string

  whole
  <> case decimals > 0 {
    True -> "."
    False -> ""
  }
  <> decimal_formatted
  <> " "
  <> unit_to_string(unit)
  <> case whole == "1" && decimal == 0.0 {
    True -> ""
    False -> "s"
  }
}

pub fn format_as_many(duration, units units: List(Unit), decimals decimals) {
  list.index_fold(units, #(duration, ""), fn(accumulator, unit: Unit, i) {
    case list.length(units) == i + 1 {
      // Handle the last unit differently
      True -> #(
        tempo.Duration(0),
        accumulator.1
          // If there is more than 2 units, add an "and" before the last unit
          <> case list.length(units) != 1 {
          True -> "and "
          False -> ""
        }
          // Apply decimals to the last unit
          <> format_as(accumulator.0, unit, decimals),
      )

      // Handle every non-last unit the same
      False -> {
        // The duration left after the taking off the whole current unit
        let remaining_duration =
          duration.nanoseconds % unit_nanosecond_representation(unit)
          |> tempo.Duration

        let formated_current_unit =
          accumulator.0
          |> decrease(by: remaining_duration)
          |> format_as(unit, 0)

        #(
          remaining_duration,
          accumulator.1
            <> formated_current_unit
            // If there is more than 2 units, add a comma after each 
            // non-last unit
            <> case list.length(units) > 2 {
            True -> ", "
            False -> " "
          },
        )
      }
    }
  }).1
}

pub fn format(duration: tempo.Duration) {
  case duration.nanoseconds {
    n if n >= year_nanoseconds ->
      format_as_many(duration, [Year, Week, Day, Hour, Minute], decimals: 0)
    n if n >= week_nanoseconds ->
      format_as_many(duration, [Week, Day, Hour, Minute], decimals: 0)
    n if n >= day_nanoseconds ->
      format_as_many(duration, [Day, Hour, Minute], decimals: 0)
    n if n >= hour_nanoseconds ->
      format_as_many(duration, [Hour, Minute, Second], decimals: 2)
    n if n >= minute_nanoseconds ->
      format_as_many(duration, [Minute, Second], decimals: 3)
    n if n >= second_nanoseconds -> format_as(duration, Second, decimals: 3)
    n if n >= millisecond_nanoseconds ->
      format_as(duration, Millisecond, decimals: 0)
    n if n >= mircosecond_nanoseconds ->
      format_as(duration, Microsecond, decimals: 0)
    _ -> format_as(duration, Nanosecond, decimals: 0)
  }
}

pub type Unit {
  Year
  Week
  Day
  Hour
  Minute
  Second
  Millisecond
  Microsecond
  Nanosecond
}

pub fn unit_to_string(unit: Unit) -> String {
  case unit {
    Year -> "year"
    Week -> "week"
    Day -> "day"
    Hour -> "hour"
    Minute -> "minute"
    Second -> "second"
    Millisecond -> "millisecond"
    Microsecond -> "microsecond"
    Nanosecond -> "nanosecond"
  }
}

pub fn unit_nanosecond_representation(unit) {
  case unit {
    Year -> year_nanoseconds
    Week -> week_nanoseconds
    Day -> day_nanoseconds
    Hour -> hour_nanoseconds
    Minute -> minute_nanoseconds
    Second -> second_nanoseconds
    Millisecond -> millisecond_nanoseconds
    Microsecond -> mircosecond_nanoseconds
    Nanosecond -> 1
  }
}

pub fn new(hours hr: Int, minutes min: Int, seconds sec: Int) {
  hr * hour_nanoseconds + min * minute_nanoseconds + sec * second_nanoseconds
  |> tempo.Duration
}

pub fn literal(duration: Int, unit: Unit) -> tempo.Duration {
  case unit {
    Year -> years(duration)
    Week -> weeks(duration)
    Day -> days(duration)
    Hour -> hours(duration)
    Minute -> minutes(duration)
    Second -> seconds(duration)
    Millisecond -> milliseconds(duration)
    Microsecond -> microseconds(duration)
    Nanosecond -> nanoseconds(duration)
  }
}

pub fn as_unit(duration: tempo.Duration, unit: Unit) -> Int {
  case unit {
    Year -> as_years(duration)
    Week -> as_weeks(duration)
    Day -> as_days(duration)
    Hour -> as_hours(duration)
    Minute -> as_minutes(duration)
    Second -> as_seconds(duration)
    Millisecond -> as_milliseconds(duration)
    Microsecond -> as_microseconds(duration)
    Nanosecond -> as_nanoseconds(duration)
  }
}

pub fn as_unit_fractional(duration: tempo.Duration, unit: Unit) -> Float {
  case unit {
    Year -> as_years_fractional(duration)
    Week -> as_weeks_fractional(duration)
    Day -> as_days_fractional(duration)
    Hour -> as_hours_fractional(duration)
    Minute -> as_minutes_fractional(duration)
    Second -> as_seconds_fractional(duration)
    Millisecond -> as_milliseconds_fractional(duration)
    Microsecond -> as_microseconds_fractional(duration)
    Nanosecond -> as_nanoseconds(duration) |> int.to_float
  }
}

pub fn years(years: Int) -> tempo.Duration {
  years * year_nanoseconds |> tempo.Duration
}

pub fn weeks(weeks: Int) -> tempo.Duration {
  weeks * week_nanoseconds |> tempo.Duration
}

pub fn days(days: Int) -> tempo.Duration {
  days * day_nanoseconds |> tempo.Duration
}

pub fn hours(hours: Int) -> tempo.Duration {
  hours * hour_nanoseconds |> tempo.Duration
}

pub fn minutes(minutes: Int) -> tempo.Duration {
  minutes * minute_nanoseconds |> tempo.Duration
}

pub fn seconds(seconds: Int) -> tempo.Duration {
  seconds * second_nanoseconds |> tempo.Duration
}

pub fn milliseconds(milliseconds: Int) {
  milliseconds * millisecond_nanoseconds |> tempo.Duration
}

pub fn microseconds(microseconds: Int) {
  microseconds * mircosecond_nanoseconds |> tempo.Duration
}

pub fn nanoseconds(nanoseconds: Int) {
  nanoseconds |> tempo.Duration
}

pub fn increase(a: tempo.Duration, by b: tempo.Duration) -> tempo.Duration {
  tempo.Duration(a.nanoseconds + b.nanoseconds)
}

pub fn decrease(a: tempo.Duration, by b: tempo.Duration) -> tempo.Duration {
  tempo.Duration(a.nanoseconds - b.nanoseconds)
}

pub fn as_years(duration: tempo.Duration) -> Int {
  duration.nanoseconds / year_nanoseconds
}

pub fn as_years_fractional(duration: tempo.Duration) -> Float {
  int.to_float(duration.nanoseconds) /. int.to_float(year_nanoseconds)
}

pub fn as_weeks(duration: tempo.Duration) -> Int {
  duration.nanoseconds / week_nanoseconds
}

pub fn as_weeks_fractional(duration: tempo.Duration) -> Float {
  int.to_float(duration.nanoseconds) /. int.to_float(week_nanoseconds)
}

pub fn as_days(duration: tempo.Duration) -> Int {
  duration.nanoseconds / day_nanoseconds
}

pub fn as_days_fractional(duration: tempo.Duration) -> Float {
  int.to_float(duration.nanoseconds) /. int.to_float(day_nanoseconds)
}

pub fn as_hours(duration: tempo.Duration) -> Int {
  duration.nanoseconds / hour_nanoseconds
}

pub fn as_hours_fractional(duration: tempo.Duration) -> Float {
  int.to_float(duration.nanoseconds) /. int.to_float(hour_nanoseconds)
}

pub fn as_minutes(duration: tempo.Duration) -> Int {
  duration.nanoseconds / minute_nanoseconds
}

pub fn as_minutes_fractional(duration: tempo.Duration) -> Float {
  int.to_float(duration.nanoseconds) /. int.to_float(minute_nanoseconds)
}

pub fn as_seconds(duration: tempo.Duration) -> Int {
  duration.nanoseconds / second_nanoseconds
}

pub fn as_seconds_fractional(duration: tempo.Duration) -> Float {
  int.to_float(duration.nanoseconds) /. int.to_float(second_nanoseconds)
}

pub fn as_milliseconds(duration: tempo.Duration) -> Int {
  duration.nanoseconds / millisecond_nanoseconds
}

pub fn as_milliseconds_fractional(duration: tempo.Duration) -> Float {
  int.to_float(duration.nanoseconds) /. int.to_float(millisecond_nanoseconds)
}

pub fn as_microseconds(duration: tempo.Duration) -> Int {
  duration.nanoseconds / mircosecond_nanoseconds
}

pub fn as_microseconds_fractional(duration: tempo.Duration) -> Float {
  int.to_float(duration.nanoseconds) /. int.to_float(mircosecond_nanoseconds)
}

pub fn as_nanoseconds(duration: tempo.Duration) -> Int {
  duration.nanoseconds
}

pub fn compare(a: tempo.Duration, to b: tempo.Duration) -> order.Order {
  int.compare(a.nanoseconds, b.nanoseconds)
}

pub fn is_less(a: tempo.Duration, than b: tempo.Duration) -> Bool {
  compare(a, b) == order.Lt
}

pub fn is_less_or_equal(a: tempo.Duration, to b: tempo.Duration) -> Bool {
  compare(a, b) == order.Lt || compare(a, b) == order.Eq
}

pub fn is_equal(a: tempo.Duration, to b: tempo.Duration) -> Bool {
  compare(a, b) == order.Eq
}

pub fn is_greater(a: tempo.Duration, than b: tempo.Duration) -> Bool {
  compare(a, b) == order.Gt
}

pub fn is_greater_or_equal(a: tempo.Duration, to b: tempo.Duration) -> Bool {
  compare(a, b) == order.Gt || compare(a, b) == order.Eq
}

pub fn absolute(duration: tempo.Duration) -> tempo.Duration {
  case duration.nanoseconds < 0 {
    True -> -duration.nanoseconds |> tempo.Duration
    False -> duration
  }
}
