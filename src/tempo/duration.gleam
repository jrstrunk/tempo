import gleam/int
import gleam/list
import gleam/order
import tempo
import tempo/internal/unit

pub opaque type MonotomicTime {
  MonotomicTime(nanoseconds: Int)
}

pub fn start() -> MonotomicTime {
  tempo.now_utc() |> MonotomicTime
}

pub fn stop(start: MonotomicTime) -> tempo.Duration {
  tempo.now_utc() - start.nanoseconds |> tempo.Duration
}

pub fn since(start: MonotomicTime) -> String {
  stop(start) |> format
}

pub fn format_as(
  duration: tempo.Duration,
  unit unit: Unit,
  decimals decimals: Int,
) -> String {
  as_internal_unit(unit) |> unit.format_as(duration.nanoseconds, _, decimals)
}

pub fn format_as_many(
  duration: tempo.Duration,
  units units: List(Unit),
  decimals decimals,
) {
  list.map(units, as_internal_unit)
  |> unit.format_as_many(duration.nanoseconds, _, decimals)
}

pub fn format(duration: tempo.Duration) {
  case duration.nanoseconds {
    n if n >= unit.imprecise_year_nanoseconds ->
      format_as_many(duration, [Year, Week, Day, Hour, Minute], decimals: 0)
    n if n >= unit.imprecise_week_nanoseconds ->
      format_as_many(duration, [Week, Day, Hour, Minute], decimals: 0)
    n if n >= unit.imprecise_day_nanoseconds ->
      format_as_many(duration, [Day, Hour, Minute], decimals: 0)
    n if n >= unit.hour_nanoseconds ->
      format_as_many(duration, [Hour, Minute, Second], decimals: 2)
    n if n >= unit.minute_nanoseconds ->
      format_as_many(duration, [Minute, Second], decimals: 3)
    n if n >= unit.second_nanoseconds ->
      format_as(duration, Second, decimals: 3)
    n if n >= unit.millisecond_nanoseconds ->
      format_as(duration, Millisecond, decimals: 0)
    n if n >= unit.microsecond_nanoseconds ->
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

pub fn as_internal_unit(u: Unit) -> unit.Unit {
  case u {
    Year -> unit.Year
    Week -> unit.Week
    Day -> unit.Day
    Hour -> unit.Hour
    Minute -> unit.Minute
    Second -> unit.Second
    Millisecond -> unit.Millisecond
    Microsecond -> unit.Microsecond
    Nanosecond -> unit.Nanosecond
  }
}

pub fn new(hours hr: Int, minutes min: Int, seconds sec: Int) {
  hr
  * unit.hour_nanoseconds
  + min
  * unit.minute_nanoseconds
  + sec
  * unit.second_nanoseconds
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
  as_internal_unit(unit) |> unit.as_unit(duration.nanoseconds, _)
}

pub fn as_unit_fractional(duration: tempo.Duration, unit: Unit) -> Float {
  as_internal_unit(unit) |> unit.as_unit_fractional(duration.nanoseconds, _)
}

pub fn years(years: Int) -> tempo.Duration {
  years |> unit.imprecise_years |> tempo.Duration
}

pub fn weeks(weeks: Int) -> tempo.Duration {
  weeks |> unit.imprecise_weeks |> tempo.Duration
}

pub fn days(days: Int) -> tempo.Duration {
  days |> unit.imprecise_days |> tempo.Duration
}

pub fn hours(hours: Int) -> tempo.Duration {
  hours |> unit.hours |> tempo.Duration
}

pub fn minutes(minutes: Int) -> tempo.Duration {
  minutes |> unit.minutes |> tempo.Duration
}

pub fn seconds(seconds: Int) -> tempo.Duration {
  seconds |> unit.seconds |> tempo.Duration
}

pub fn milliseconds(milliseconds: Int) {
  milliseconds |> unit.milliseconds |> tempo.Duration
}

pub fn microseconds(microseconds: Int) {
  microseconds |> unit.microseconds |> tempo.Duration
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
  duration.nanoseconds |> unit.as_years_imprecise
}

pub fn as_years_fractional(duration: tempo.Duration) -> Float {
  duration.nanoseconds |> unit.as_years_imprecise_fractional
}

pub fn as_weeks(duration: tempo.Duration) -> Int {
  duration.nanoseconds |> unit.as_weeks_imprecise
}

pub fn as_weeks_fractional(duration: tempo.Duration) -> Float {
  duration.nanoseconds |> unit.as_weeks_imprecise_fractional
}

pub fn as_days(duration: tempo.Duration) -> Int {
  duration.nanoseconds |> unit.as_days_imprecise
}

pub fn as_days_fractional(duration: tempo.Duration) -> Float {
  duration.nanoseconds |> unit.as_days_fractional
}

pub fn as_hours(duration: tempo.Duration) -> Int {
  duration.nanoseconds |> unit.as_hours
}

pub fn as_hours_fractional(duration: tempo.Duration) -> Float {
  duration.nanoseconds |> unit.as_hours_fractional
}

pub fn as_minutes(duration: tempo.Duration) -> Int {
  duration.nanoseconds |> unit.as_minutes
}

pub fn as_minutes_fractional(duration: tempo.Duration) -> Float {
  duration.nanoseconds |> unit.as_minutes_fractional
}

pub fn as_seconds(duration: tempo.Duration) -> Int {
  duration.nanoseconds |> unit.as_seconds
}

pub fn as_seconds_fractional(duration: tempo.Duration) -> Float {
  duration.nanoseconds |> unit.as_seconds_fractional
}

pub fn as_milliseconds(duration: tempo.Duration) -> Int {
  duration.nanoseconds |> unit.as_milliseconds
}

pub fn as_milliseconds_fractional(duration: tempo.Duration) -> Float {
  duration.nanoseconds |> unit.as_milliseconds_fractional
}

pub fn as_microseconds(duration: tempo.Duration) -> Int {
  duration.nanoseconds |> unit.as_microseconds
}

pub fn as_microseconds_fractional(duration: tempo.Duration) -> Float {
  duration.nanoseconds |> unit.as_microseconds_fractional
}

pub fn as_nanoseconds(duration: tempo.Duration) -> Int {
  duration.nanoseconds |> unit.as_nanoseconds
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
