//// The main module of this package. Contains most package types and general 
//// purpose functions.
//// Look in specific modules for more functionality!

import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/regexp
import gleam/result
import gleam/string
import gleam/string_tree
import gtempo/internal as unit
import tempo/error as tempo_error

// This is a big file. The contents are generally ordered (and searchable) by:
// - Tempo now functions
// - Instant logic (functions starting with `_instant`)
// - DateTime logic (funcctions starting with `datetime_`)
// - NaiveDateTime logic (functions starting with `naive_datetime_`)
// - Offset logic (functions starting with `offset_`)
// - Date logic (functions starting with `date_`)
// - Month logic (functions starting with `month_`)
// - Year logic (functions starting with `year_`)
// - Time logic (functions starting with `time_`)
// - Duration logic (functions starting with `dur_`)
// - Period logic (functions starting with `period_`)
// - Format logic
// - FFI logic

// -------------------------------------------------------------------------- //
//                              Now Logic                                     //
// -------------------------------------------------------------------------- //
// These functions were written to be released in the tempo module itself to
// avoid the need to make a call to `now()` and then pass it to a second
// function, but it ended up being too clunky and verbose. Instead, the instant
// module is the sole entrypoint into the system time

/// The current instant on the host system.
@internal
pub fn now() -> Instant {
  Instant(
    timestamp_utc_us: now_utc_ffi(),
    offset_local_us: offset_local_micro(),
    monotonic_us: now_monotonic_ffi(),
    unique: now_unique_ffi(),
  )
}

/// Get the current UTC system time adjusted by the given duration. Useful for
/// checking if a time is more than some time in the past or future. Though
/// this uses UTC time, UTC datetimes are directly comparable to local datetimes;
/// formatting is where the difference really shows itself. If you want to 
/// format this value as a local datetime, you can localise it before formatting.
/// 
/// ## Example
/// 
/// ```gleam
/// // Is the given datetime more than 30 mins old?
/// datetime.literal("2024-12-26T00:00:00Z")
/// |> datetime.is_earlier(than: 
///   tempo.now_adjusted(by: duration.minutes(-30))
/// )
@internal
pub fn now_adjusted(by duration: Duration) -> DateTime {
  let new_ts = now().timestamp_utc_us + duration.microseconds

  DateTime(
    date_from_unix_utc(new_ts / 1_000_000),
    time_from_unix_micro_utc(new_ts),
    offset: utc,
  )
}

/// Formats the current UTC system time using the provided format.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.format_utc(tempo.ISO8601)
/// // -> "2024-12-26T16:32:34Z"
/// ```
pub fn format_utc(in format: DateTimeFormat) -> String {
  now() |> instant_as_utc_datetime |> datetime_format(format)
}

/// Formats the current local system time using the provided format.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.format_local(tempo.ISO8601)
/// // -> "2024-12-26T12:32:34-04:00"
/// ```
pub fn format_local(in format: DateTimeFormat) -> String {
  case format {
    HTTP -> format_utc(HTTP)
    _ -> now() |> instant_as_local_datetime |> datetime_format(format)
  }
}

/// Gets the duration between the current system time and the provided instant.
/// 
/// ## Example
/// 
/// ```gleam
/// let monotonic_timer = tempo.now()
/// // Do long task ...
/// tempo.since(monotonic_timer)
/// // -> duration.minutes(42)
@internal
pub fn since(start start: Instant) -> Duration {
  now() |> instant_difference(from: start) |> duration_absolute
}

/// Formats the duration between the current system time and the provided 
/// instant.
/// 
/// ## Example
/// 
/// ```gleam
/// let monotonic_timer = tempo.now()
/// // Do long task ...
/// tempo.since_formatted(monotonic_timer)
/// // -> "42 minutes"
@internal
pub fn since_formatted(start start: Instant) -> String {
  let dur = since(start:)
  unit.format(dur.microseconds)
}

/// Compares the current system datetime to the provided datetime value.
///
/// ## Example
///
/// ```gleam
/// tempo.compare(datetime.literal("2024-12-26T00:00:00Z"))
/// // -> order.Lt
@internal
pub fn compare(to datetime: DateTime) -> order.Order {
  datetime_compare(now() |> instant_as_utc_datetime, to: datetime)
}

/// Checks if the current UTC system datetime is earlier than the provided datetime.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_earlier(than: datetime.literal("2024-12-26T00:00:00Z"))
/// // -> False
/// ```
@internal
pub fn is_earlier(than datetime: DateTime) -> Bool {
  datetime_is_earlier(now() |> instant_as_utc_datetime, than: datetime)
}

/// Checks if the current UTC system datetime is earlier or equal to the provided 
/// datetime.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_earlier_or_equal(to: datetime.literal("2024-12-26T00:00:00Z"))
/// // -> True
/// ```
@internal
pub fn is_earlier_or_equal(to datetime: DateTime) -> Bool {
  datetime_is_earlier_or_equal(now() |> instant_as_utc_datetime, to: datetime)
}

/// Checks if the current UTC system datetime is equal to the provided datetime.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_equal(to: datetime.literal("2024-12-26T00:00:00Z"))
/// // -> False
@internal
pub fn is_equal(to datetime: DateTime) -> Bool {
  datetime_is_equal(now() |> instant_as_utc_datetime, to: datetime)
}

/// Checks if the current UTC system datetime is later than the provided datetime.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_later(than: datetime.literal("2024-12-26T00:00:00Z"))
/// // -> True
/// ```
@internal
pub fn is_later(than datetime: DateTime) -> Bool {
  datetime_is_later(now() |> instant_as_utc_datetime, than: datetime)
}

/// Checks if the current UTC system datetime is later or equal to the provided 
/// datetime.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_later_or_equal(to: datetime.literal("2024-12-26T00:00:00Z"))
/// // -> True
/// ```
@internal
pub fn is_later_or_equal(to datetime: DateTime) -> Bool {
  datetime_is_later_or_equal(now() |> instant_as_utc_datetime, to: datetime)
}

/// Compares the current UTC system date to the provided date value. The same
/// as `date.current_utc() |> date.compare`.
///
/// ## Example
///
/// ```gleam
/// case tempo.compare_utc_date(to: date.literal("2024-12-26")) {
///   order.Eq | order.Lt -> "Less than or equal to"
///   order.Gt -> "Greater than"
/// }
/// ``` 
@internal
pub fn compare_utc_date(date: Date) -> order.Order {
  now() |> instant_as_utc_date |> date_compare(to: date)
}

/// Compares the current local system date to the provided date value. The same
/// as `date.current_local() |> date.compare`.
///
/// ## Example
///
/// ```gleam
/// case tempo.compare_local_date(to: date.literal("2024-12-26")) {
///   order.Eq | order.Lt -> "Less than or equal to"
///   order.Gt -> "Greater than"
/// }
/// ```
@internal
pub fn compare_local_date(date: Date) -> order.Order {
  now() |> instant_as_local_date |> date_compare(to: date)
}

/// Checks if the current UTC system date is earlier than the provided date.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_utc_date_earlier(than: date.literal("2024-12-26"))
/// // -> False
/// ```
@internal
pub fn is_utc_date_earlier(than date: Date) -> Bool {
  date_is_earlier(now() |> instant_as_utc_date, than: date)
}

/// Checks if the current local system date is earlier than the provided date.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_local_date_earlier(than: date.literal("2024-12-26"))
/// // -> False
/// ```
@internal
pub fn is_local_date_earlier(than date: Date) -> Bool {
  date_is_earlier(now() |> instant_as_local_date, than: date)
}

/// Checks if the current UTC system date is earlier or equal to the provided date.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_utc_date_earlier_or_equal(to: date.literal("2024-12-26"))
/// // -> False
/// ```
@internal
pub fn is_utc_date_earlier_or_equal(to date: Date) -> Bool {
  date_is_earlier_or_equal(now() |> instant_as_utc_date, to: date)
}

/// Checks if the current local system date is earlier or equal to the provided date.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_local_date_earlier_or_equal(to: date.literal("2024-12-26"))
/// // -> False
/// ```
@internal
pub fn is_local_date_earlier_or_equal(to date: Date) -> Bool {
  date_is_earlier_or_equal(now() |> instant_as_local_date, to: date)
}

/// Checks if the current UTC system date is equal to the provided date.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_utc_date_equal(to: date.literal("2024-12-26"))
/// // -> False
/// ```
@internal
pub fn is_utc_date_equal(to date: Date) -> Bool {
  date_is_equal(now() |> instant_as_utc_date, to: date)
}

/// Checks if the current local system date is equal to the provided date.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_local_date_equal(to: date.literal("2024-12-26"))
/// // -> False
/// ```
@internal
pub fn is_local_date_equal(to date: Date) -> Bool {
  date_is_equal(now() |> instant_as_local_date, to: date)
}

/// Checks if the current UTC system date is later than the provided date.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_utc_date_later(than: date.literal("2024-12-26"))
/// // -> True
/// ```
@internal
pub fn is_utc_date_later(than date: Date) -> Bool {
  date_is_later(now() |> instant_as_utc_date, than: date)
}

/// Checks if the current local system date is later than the provided date.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_local_date_later(than: date.literal("2024-12-26"))
/// // -> True
/// ```
@internal
pub fn is_local_date_later(than date: Date) -> Bool {
  date_is_later(now() |> instant_as_local_date, than: date)
}

/// Checks if the current UTC system date is later or equal to the provided date.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_utc_date_later_or_equal(to: date.literal("2024-12-26"))
/// // -> True
/// ```
@internal
pub fn is_utc_date_later_or_equal(to date: Date) -> Bool {
  date_is_later_or_equal(now() |> instant_as_utc_date, to: date)
}

/// Checks if the current local system date is later or equal to the provided date.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_local_date_later_or_equal(to: date.literal("2024-12-26"))
/// // -> True
/// ```
@internal
pub fn is_local_date_later_or_equal(to date: Date) -> Bool {
  date_is_later_or_equal(now() |> instant_as_local_date, to: date)
}

/// Compares the current utc system time to the provided time value.
///
/// ## Example
///
/// ```gleam
/// tempo.compare_utc_time(time.literal("12:55:12"))
/// // -> order.Gt
/// ```
@internal
pub fn compare_utc_time(to time: Time) -> order.Order {
  time_compare(now() |> instant_as_utc_time, to: time)
}

/// Compares the current local system time to the provided time value.
///
/// ## Example
///
/// ```gleam
/// tempo.compare_local_time(time.literal("12:55:12"))
/// // -> order.Lt
/// ```
@internal
pub fn compare_local_time(to time: Time) -> order.Order {
  time_compare(now() |> instant_as_local_time, to: time)
}

/// Checks if the current UTC system time is earlier than the provided time.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_utc_time_earlier(than: time.literal("13:42:11"))
/// // -> False
/// ```
@internal
pub fn is_utc_time_earlier(than time: Time) -> Bool {
  time_is_earlier(now() |> instant_as_utc_time, than: time)
}

/// Checks if the current local system time is earlier than the provided time.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_local_time_earlier(than: time.literal("13:42:11"))
/// // -> False
/// ```
@internal
pub fn is_local_time_earlier(than time: Time) -> Bool {
  time_is_earlier(now() |> instant_as_local_time, than: time)
}

/// Checks if the current UTC system time is earlier or equal to the provided time.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_utc_time_earlier_or_equal(to: time.literal("13:42:11"))
/// // -> False
/// ```
@internal
pub fn is_utc_time_earlier_or_equal(to time: Time) -> Bool {
  time_is_earlier_or_equal(now() |> instant_as_utc_time, to: time)
}

/// Checks if the current local system time is earlier or equal to the provided time.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_local_time_earlier_or_equal(to: time.literal("13:42:11"))
/// // -> False
/// ```
@internal
pub fn is_local_time_earlier_or_equal(to time: Time) -> Bool {
  time_is_earlier_or_equal(now() |> instant_as_local_time, to: time)
}

/// Checks if the current UTC system time is equal to the provided time.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_utc_time_equal(to: time.literal("13:42:11"))
/// // -> False
/// ```
@internal
pub fn is_utc_time_equal(to time: Time) -> Bool {
  time_is_equal(now() |> instant_as_utc_time, to: time)
}

/// Checks if the current local system time is equal to the provided time.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_local_time_equal(to: time.literal("13:42:11"))
/// // -> False
/// ```
@internal
pub fn is_local_time_equal(to time: Time) -> Bool {
  time_is_equal(now() |> instant_as_local_time, to: time)
}

/// Checks if the current UTC system time is later than the provided time.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_utc_time_later(than: time.literal("13:42:11"))
/// // -> True
/// ```
@internal
pub fn is_utc_time_later(than time: Time) -> Bool {
  time_is_later(now() |> instant_as_utc_time, than: time)
}

/// Checks if the current local system time is later than the provided time.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_local_time_later(than: time.literal("13:42:11"))
/// // -> True
/// ```
@internal
pub fn is_local_time_later(than time: Time) -> Bool {
  time_is_later(now() |> instant_as_local_time, than: time)
}

/// Checks if the current UTC system time is later or equal to the provided time.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_utc_time_later_or_equal(to: time.literal("13:42:11"))
/// // -> True
/// ```
@internal
pub fn is_utc_time_later_or_equal(to time: Time) -> Bool {
  time_is_later_or_equal(now() |> instant_as_utc_time, to: time)
}

/// Checks if the current local system time is later or equal to the provided time.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.is_local_time_later_or_equal(to: time.literal("13:42:11"))
/// // -> True
/// ```
@internal
pub fn is_local_time_later_or_equal(to time: Time) -> Bool {
  time_is_later_or_equal(now() |> instant_as_local_time, to: time)
}

/// Gets the difference between the current system datetime and the provided
/// datetime.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.difference_from(date.literal("2024-10-26"))
/// |> duration.format
/// // -> "54 days, 13 hours, and 46 minutes"
/// ```
@internal
pub fn difference_from(from start: DateTime) -> Duration {
  now() |> instant_as_utc_datetime |> datetime_difference(from: start)
}

/// Gets the time since the provided datetime relative to the current system
/// datetime. A duration of 0 will be returned if the datetime is in the future.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.since_datetime(datetime.literal("2024-10-26T00:00:00Z"))
/// |> duration.format
/// // -> "54 days, 13 hours, and 46 minutes"
/// ```
/// 
/// ```gleam
/// tempo.since_datetime(datetime.literal("9099-12-26T00:00:00Z"))
/// |> duration.format
/// // -> "none"
/// ```
@internal
pub fn since_datetime(start start: DateTime) -> Duration {
  case difference_from(start) {
    Duration(diff) if diff > 0 -> Duration(diff)
    _ -> Duration(0)
  }
}

/// Gets the time until the provided datetime relative to the current system
/// datetime. A duration of 0 will be returned if the datetime in the past.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.until_datetime(datetime.literal("2024-10-26T00:00:00Z"))
/// |> duration.format
/// // -> "none"
/// ```
/// 
/// ```gleam
/// tempo.until_datetime(datetime.literal("2025-02-26T00:00:00Z"))
/// |> duration.format
/// // -> "54 days, 13 hours, and 46 minutes"
/// ```
@internal
pub fn until_datetime(end end: DateTime) -> Duration {
  case now() |> instant_as_utc_datetime |> datetime_difference(to: end) {
    Duration(diff) if diff > 0 -> Duration(diff)
    _ -> Duration(0)
  }
}

/// Gets the difference between the current UTC system time and the provided time.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.utc_time_difference_from(time.literal("13:42:11"))
/// |> duration.format
/// // -> "42 minutes"
@internal
pub fn utc_time_difference_from(from start: Time) -> Duration {
  now() |> instant_as_utc_time |> time_difference(from: start)
}

/// Gets the difference between the current local system time and the provided 
/// time.
///
/// ## Example
///
/// ```gleam
/// tempo.local_time_difference_from(time.literal("13:42:11"))
/// |> duration.format
/// // -> "4 hours and 42 minutes"
/// ```
@internal
pub fn local_time_difference_from(from start: Time) -> Duration {
  now() |> instant_as_utc_time |> time_difference(from: start)
}

/// Gets the time since the provided time relative to the current UTC system time.
/// A duration of 0 will be returned if the time is in the future.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.utc_time_since(time.literal("13:42:11"))
/// |> duration.format
/// // -> "42 minutes"
/// ```
@internal
pub fn utc_time_since(start start: Time) -> Duration {
  case utc_time_difference_from(from: start) {
    Duration(diff) if diff > 0 -> Duration(diff)
    _ -> Duration(0)
  }
}

/// Gets the time since the provided time relative to the current local system 
/// time. A duration of 0 will be returned if the time is in the future.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.local_time_since(time.literal("13:42:11"))
/// |> duration.format
/// // -> "4 hours and 42 minutes"
/// ```
@internal
pub fn local_time_since(start start: Time) -> Duration {
  case local_time_difference_from(from: start) {
    Duration(diff) if diff > 0 -> Duration(diff)
    _ -> Duration(0)
  }
}

/// Gets the time until the provided time relative to the current UTC system time.
/// A duration of 0 will be returned if the time in the past.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.utc_time_until(time.literal("13:42:11"))
/// |> duration.format
/// // -> "none"
/// ```
@internal
pub fn utc_time_until(end end: Time) -> Duration {
  case now() |> instant_as_utc_time |> time_difference(to: end) {
    Duration(diff) if diff > 0 -> Duration(diff)
    _ -> Duration(0)
  }
}

/// Gets the time until the provided time relative to the current local system 
/// time. A duration of 0 will be returned if the time in the past.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.local_time_until(time.literal("13:42:11"))
/// |> duration.format
/// // -> "4 hours and 42 minutes"
/// ```
@internal
pub fn local_time_until(end end: Time) -> Duration {
  case now() |> instant_as_local_time |> time_difference(to: end) {
    Duration(diff) if diff > 0 -> Duration(diff)
    _ -> Duration(0)
  }
}

/// Gets the difference between the current UTC system date and the provided date.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.utc_date_difference_from(date.literal("2024-10-26"))
/// // -> 54
/// ```
@internal
pub fn utc_date_difference_from(from start: Date) -> Int {
  now() |> instant_as_utc_date |> date_days_apart(from: start)
}

/// Gets the difference between the current local system date and the provided date.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.local_date_difference_from(date.literal("2024-10-26"))
/// // -> 54
/// ```
@internal
pub fn local_date_difference_from(from start: Date) -> Int {
  now() |> instant_as_local_date |> date_days_apart(from: start)
}

/// Gets the number of days since the provided date relative to the current UTC 
/// system date. A value of 0 will be returned if the date is in the future.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.utc_days_since(date.literal("2024-10-26"))
/// // -> 54
/// ```
@internal
pub fn utc_days_since(start start: Date) -> Int {
  case utc_date_difference_from(from: start) {
    diff if diff > 0 -> diff
    _ -> 0
  }
}

/// Gets the number of days since the provided date relative to the current local 
/// system date. A value of 0 will be returned if the date is in the future.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.local_days_since(date.literal("2024-10-26"))
/// // -> 54
/// ```
@internal
pub fn local_days_since(start start: Date) -> Int {
  case local_date_difference_from(from: start) {
    diff if diff > 0 -> diff
    _ -> 0
  }
}

/// Gets the number of days until the provided date relative to the current UTC 
/// system date. A value of 0 will be returned if the date is in the past.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.utc_days_until(date.literal("2024-10-26"))
/// // -> 0
/// ```
@internal
pub fn utc_days_until(end end: Date) -> Int {
  case now() |> instant_as_utc_date |> date_days_apart(to: end) {
    diff if diff > 0 -> diff
    _ -> 0
  }
}

/// Gets the number of days until the provided date relative to the current local 
/// system date. A value of 0 will be returned if the date is in the past.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.local_days_until(date.literal("2025-10-26"))
/// // -> 365
/// ```
@internal
pub fn local_days_until(end end: Date) -> Int {
  case now() |> instant_as_local_date |> date_days_apart(to: end) {
    diff if diff > 0 -> diff
    _ -> 0
  }
}

// -------------------------------------------------------------------------- //
//                             Instant Logic                                  //
// -------------------------------------------------------------------------- //

/// A monotonic type that reperesents a unique point in time on the host system. 
/// It can be converted to all other date time types, but cannot be serialized
/// itself. An instant constructed on one host has no meaningful purpose on
/// another host.
pub opaque type Instant {
  Instant(
    timestamp_utc_us: Int,
    offset_local_us: Int,
    monotonic_us: Int,
    unique: Int,
  )
}

@internal
pub fn instant_as_utc_datetime(instant: Instant) -> DateTime {
  DateTime(
    date: instant_as_utc_date(instant),
    time: instant_as_utc_time(instant),
    offset: utc,
  )
}

@internal
pub fn instant_as_local_datetime(instant: Instant) -> DateTime {
  DateTime(
    date: instant_as_local_date(instant),
    time: instant_as_local_time(instant),
    offset: Offset(instant.offset_local_us / 60_000_000),
  )
}

@internal
pub fn instant_as_unix_utc(instant: Instant) -> Int {
  instant.offset_local_us / 1_000_000
}

@internal
pub fn instant_as_unix_milli_utc(instant: Instant) -> Int {
  instant.offset_local_us / 1000
}

@internal
pub fn instant_to_utc_string(instant: Instant) -> String {
  instant |> instant_as_utc_datetime |> datetime_to_string
}

@internal
pub fn instant_to_local_string(instant: Instant) -> String {
  instant |> instant_as_local_datetime |> datetime_to_string
}

@internal
pub fn instant_as_utc_date(instant: Instant) -> Date {
  date_from_unix_utc(instant.timestamp_utc_us / 1_000_000)
}

@internal
pub fn instant_as_local_date(instant: Instant) -> Date {
  date_from_unix_utc(
    { instant.timestamp_utc_us + instant.offset_local_us } / 1_000_000,
  )
}

@internal
pub fn instant_as_utc_time(instant: Instant) -> Time {
  time_from_unix_micro_utc(instant.timestamp_utc_us)
}

@internal
pub fn instant_as_local_time(instant: Instant) -> Time {
  time_from_unix_micro_utc(instant.timestamp_utc_us + instant.offset_local_us)
}

@internal
pub fn instant_compare(a: Instant, b: Instant) -> order.Order {
  int.compare(a.unique, b.unique)
}

@internal
pub fn instant_is_earlier(a: Instant, than b: Instant) {
  instant_compare(a, b) == order.Lt
}

@internal
pub fn instant_is_earlier_or_equal(a: Instant, to b: Instant) {
  instant_compare(a, b) == order.Lt || instant_compare(a, b) == order.Eq
}

@internal
pub fn instant_is_equal(a: Instant, to b: Instant) {
  instant_compare(a, b) == order.Eq
}

@internal
pub fn instant_is_later(a: Instant, than b: Instant) {
  instant_compare(a, b) == order.Gt
}

@internal
pub fn instant_is_later_or_equal(a: Instant, to b: Instant) {
  instant_compare(a, b) == order.Gt || instant_compare(a, b) == order.Eq
}

@internal
pub fn instant_difference(from a: Instant, to b: Instant) -> Duration {
  Duration(b.monotonic_us - a.monotonic_us)
}

// -------------------------------------------------------------------------- //
//                            DateTime Logic                                  //
// -------------------------------------------------------------------------- //

/// A datetime value with a timezone offset associated with it. It has the 
/// most amount of information about a point in time, and can be compared to 
/// all other types in this package by getting its lesser parts.
pub type DateTime {
  DateTime(date: Date, time: Time, offset: Offset)
  LocalDateTime(date: Date, time: Time, offset: Offset, tz: TimeZoneProvider)
}

/// A type for external packages to provide so that datetimes can be converted
/// between timezones. The package `gtz` was created to provide this and must
/// be added as a project dependency separately.
pub type TimeZoneProvider {
  TimeZoneProvider(
    get_name: fn() -> String,
    calculate_offset: fn(NaiveDateTime) -> Offset,
  )
}

@internal
pub fn datetime(date date, time time, offset offset) {
  DateTime(date, time, offset)
}

@internal
pub fn datetime_get_naive(datetime: DateTime) {
  NaiveDateTime(datetime.date, datetime.time)
}

@internal
pub fn datetime_get_offset(datetime: DateTime) {
  datetime.offset
}

@internal
pub fn datetime_to_utc(datetime: DateTime) -> DateTime {
  datetime
  |> datetime_apply_offset
  |> naive_datetime_set_offset(utc)
}

@internal
pub fn datetime_to_offset(datetime: DateTime, offset: Offset) -> DateTime {
  datetime
  |> datetime_to_utc
  |> datetime_subtract(offset_to_duration(offset))
  |> datetime_drop_offset
  |> naive_datetime_set_offset(offset)
}

@internal
pub fn datetime_to_tz(datetime: DateTime, tz: TimeZoneProvider) {
  let utc_dt = datetime_apply_offset(datetime)

  let offset = tz.calculate_offset(utc_dt)

  let naive =
    datetime_to_offset(utc_dt |> naive_datetime_set_offset(utc), offset)
    |> datetime_drop_offset

  LocalDateTime(date: naive.date, time: naive.time, offset:, tz:)
}

@internal
pub fn datetime_get_tz(datetime: DateTime) -> option.Option(String) {
  case datetime {
    DateTime(..) -> None
    LocalDateTime(_, _, _, tz:) -> Some(tz.get_name())
  }
}

@internal
pub fn datetime_to_string(datetime: DateTime) -> String {
  NaiveDateTime(date: datetime.date, time: datetime.time)
  |> naive_datetime_to_string
  <> case datetime.offset.minutes {
    0 -> "Z"
    _ -> datetime.offset |> offset_to_string
  }
}

@deprecated("Use `datetime.to_string` instead")
@internal
pub fn datetime_serialize(datetime: DateTime) -> String {
  let d = datetime.date
  let t = datetime.time
  let o = datetime.offset

  string_tree.from_strings([
    d.year |> int.to_string |> string.pad_start(4, with: "0"),
    d.month
      |> month_to_int
      |> int.to_string
      |> string.pad_start(2, with: "0"),
    d.day |> int.to_string |> string.pad_start(2, with: "0"),
    "T",
    t.hour |> int.to_string |> string.pad_start(2, with: "0"),
    t.minute |> int.to_string |> string.pad_start(2, with: "0"),
    t.second |> int.to_string |> string.pad_start(2, with: "0"),
    ".",
    t.microsecond |> int.to_string |> string.pad_start(6, with: "0"),
    case o |> offset_get_minutes {
      0 -> "Z"
      _ -> {
        let str_offset = o |> offset_to_string

        case str_offset |> string.split(":") {
          [hours, "00"] -> hours
          _ -> str_offset
        }
      }
    },
  ])
  |> string_tree.to_string
}

@internal
pub fn datetime_format(datetime: DateTime, in format: DateTimeFormat) -> String {
  let format_str = get_datetime_format_str(format)

  let assert Ok(re) = regexp.from_string(format_regex)

  regexp.scan(re, format_str)
  |> list.reverse
  |> list.fold(from: [], with: fn(acc, match) {
    case match {
      regexp.Match(content, []) -> [
        content
          |> date_replace_format(datetime.date)
          |> time_replace_format(datetime.time)
          |> offset_replace_format(datetime.offset),
        ..acc
      ]

      // If there is a non-empty subpattern, then the escape 
      // character "[ ... ]" matched, so we should not change anything here.
      regexp.Match(_, [Some(sub)]) -> [sub, ..acc]

      // This case is not expected, not really sure what to do with it 
      // so just prepend whatever was found
      regexp.Match(content, _) -> [content, ..acc]
    }
  })
  |> string.join("")
}

@internal
pub fn datetime_compare(a: DateTime, to b: DateTime) {
  datetime_apply_offset(a)
  |> naive_datetime_compare(to: datetime_apply_offset(b))
}

@internal
pub fn datetime_is_earlier(a: DateTime, than b: DateTime) -> Bool {
  datetime_compare(a, b) == order.Lt
}

@internal
pub fn datetime_is_earlier_or_equal(a: DateTime, to b: DateTime) -> Bool {
  datetime_compare(a, b) == order.Lt || datetime_compare(a, b) == order.Eq
}

@internal
pub fn datetime_is_equal(a: DateTime, to b: DateTime) -> Bool {
  datetime_compare(a, b) == order.Eq
}

@internal
pub fn datetime_is_later_or_equal(a: DateTime, to b: DateTime) -> Bool {
  datetime_compare(a, b) == order.Gt || datetime_compare(a, b) == order.Eq
}

@internal
pub fn datetime_is_later(a: DateTime, than b: DateTime) -> Bool {
  datetime_compare(a, b) == order.Gt
}

@internal
pub fn datetime_difference(from a: DateTime, to b: DateTime) -> Duration {
  naive_datetime_difference(
    from: datetime_apply_offset(a),
    to: datetime_apply_offset(b),
  )
}

@internal
pub fn datetime_apply_offset(datetime: DateTime) -> NaiveDateTime {
  let applied =
    datetime
    |> datetime_drop_offset
    |> naive_datetime_add(offset_to_duration(datetime.offset))

  // Applying an offset does not change the abosolute time value, so we need
  // to preserve the monotonic and unique values.zzzz
  NaiveDateTime(date: applied.date, time: applied.time)
}

@internal
pub fn datetime_drop_offset(datetime: DateTime) -> NaiveDateTime {
  NaiveDateTime(date: datetime.date, time: datetime.time)
}

@internal
pub fn datetime_add(
  datetime: DateTime,
  duration duration_to_add: Duration,
) -> DateTime {
  case datetime {
    DateTime(date:, time:, offset:) -> {
      let NaiveDateTime(date: new_date, time: new_time) =
        naive_datetime_add(
          NaiveDateTime(date:, time:),
          duration: duration_to_add,
        )

      DateTime(date: new_date, time: new_time, offset:)
    }

    LocalDateTime(_, _, _, tz:) -> {
      let utc_dt_added =
        datetime_to_utc(datetime)
        |> datetime_add(duration: duration_to_add)

      let offset = utc_dt_added |> datetime_drop_offset |> tz.calculate_offset

      let NaiveDateTime(date:, time:) =
        datetime_to_offset(utc_dt_added, offset)
        |> datetime_drop_offset

      LocalDateTime(date:, time:, offset:, tz:)
    }
  }
}

@internal
pub fn datetime_subtract(
  datetime: DateTime,
  duration duration_to_subtract: Duration,
) -> DateTime {
  case datetime {
    DateTime(date:, time:, offset:) -> {
      let NaiveDateTime(date: new_date, time: new_time) =
        naive_datetime_subtract(
          NaiveDateTime(date:, time:),
          duration: duration_to_subtract,
        )

      DateTime(date: new_date, time: new_time, offset:)
    }
    LocalDateTime(_, _, _, tz:) -> {
      let utc_dt_sub =
        datetime_to_utc(datetime)
        |> datetime_subtract(duration: duration_to_subtract)

      let offset = utc_dt_sub |> datetime_drop_offset |> tz.calculate_offset

      let NaiveDateTime(date:, time:) =
        datetime_to_offset(utc_dt_sub, offset)
        |> datetime_drop_offset

      LocalDateTime(date:, time:, offset:, tz:)
    }
  }
}

// -------------------------------------------------------------------------- //
//                         Naive DateTime Logic                               //
// -------------------------------------------------------------------------- //

/// A datetime value that does not have a timezone or offset associated with it. 
/// It cannot be compared to datetimes with a timezone offset accurately, but
/// can be compared to dates, times, and other naive datetimes.
pub type NaiveDateTime {
  NaiveDateTime(date: Date, time: Time)
}

@internal
pub fn naive_datetime(date date: Date, time time: Time) -> NaiveDateTime {
  NaiveDateTime(date: date, time: time)
}

@internal
pub fn naive_datetime_get_date(naive_datetime: NaiveDateTime) -> Date {
  naive_datetime.date
}

@internal
pub fn naive_datetime_get_time(naive_datetime: NaiveDateTime) -> Time {
  naive_datetime.time
}

@internal
pub fn naive_datetime_set_offset(
  naive: NaiveDateTime,
  offset: Offset,
) -> DateTime {
  DateTime(date: naive.date, time: naive.time, offset: offset)
}

@internal
pub fn naive_datetime_to_string(datetime: NaiveDateTime) -> String {
  datetime.date
  |> date_to_string
  <> "T"
  <> datetime.time
  |> time_to_string
}

@internal
pub fn naive_datetime_compare(a: NaiveDateTime, to b: NaiveDateTime) {
  case date_compare(a.date, b.date) {
    order.Eq -> time_compare(a.time, b.time)
    od -> od
  }
}

@internal
pub fn naive_datetime_is_earlier(
  a: NaiveDateTime,
  than b: NaiveDateTime,
) -> Bool {
  naive_datetime_compare(a, b) == order.Lt
}

@internal
pub fn naive_datetime_is_earlier_or_equal(
  a: NaiveDateTime,
  to b: NaiveDateTime,
) -> Bool {
  naive_datetime_compare(a, b) == order.Lt
  || naive_datetime_compare(a, b) == order.Eq
}

@internal
pub fn naive_datetime_is_later_or_equal(
  a: NaiveDateTime,
  to b: NaiveDateTime,
) -> Bool {
  naive_datetime_compare(a, b) == order.Gt
  || naive_datetime_compare(a, b) == order.Eq
}

@internal
pub fn naive_datetime_difference(
  from a: NaiveDateTime,
  to b: NaiveDateTime,
) -> Duration {
  date_days_apart(from: a.date, to: b.date)
  |> duration_days
  |> duration_increase(by: time_difference(from: a.time, to: b.time))
}

@internal
pub fn naive_datetime_add(
  datetime: NaiveDateTime,
  duration duration_to_add: Duration,
) -> NaiveDateTime {
  // Positive date overflows are only handled in this function, while negative
  // date overflows are only handled in the subtract function -- so if the 
  // duration is negative, we can just subtract the absolute value of it.
  use <- bool.lazy_guard(when: duration_to_add.microseconds < 0, return: fn() {
    datetime |> naive_datetime_subtract(duration_absolute(duration_to_add))
  })

  let days_to_add: Int = duration_as_days(duration_to_add)
  let time_to_add: Duration =
    duration_decrease(duration_to_add, by: duration_days(days_to_add))

  let new_time_as_micro =
    datetime.time
    |> time_to_duration
    |> duration_increase(by: time_to_add)
    |> duration_as_microseconds

  // If the time to add crossed a day boundary, add an extra day to the 
  // number of days to add and adjust the time to add.
  let #(new_time_as_micro, days_to_add): #(Int, Int) = case
    new_time_as_micro >= unit.imprecise_day_microseconds
  {
    True -> #(
      new_time_as_micro - unit.imprecise_day_microseconds,
      days_to_add + 1,
    )
    False -> #(new_time_as_micro, days_to_add)
  }

  let time_to_add =
    Duration(new_time_as_micro - time_to_microseconds(datetime.time))

  let new_date = datetime.date |> date_add(days: days_to_add)
  let new_time = datetime.time |> time_add(duration: time_to_add)

  NaiveDateTime(date: new_date, time: new_time)
}

@internal
pub fn naive_datetime_subtract(
  datetime: NaiveDateTime,
  duration duration_to_subtract: Duration,
) -> NaiveDateTime {
  // Negative date overflows are only handled in this function, while positive
  // date overflows are only handled in the add function -- so if the 
  // duration is negative, we can just add the absolute value of it.
  use <- bool.lazy_guard(
    when: duration_to_subtract.microseconds < 0,
    return: fn() {
      datetime |> naive_datetime_add(duration_absolute(duration_to_subtract))
    },
  )

  let days_to_sub: Int = duration_as_days(duration_to_subtract)
  let time_to_sub: Duration =
    duration_decrease(duration_to_subtract, by: duration_days(days_to_sub))

  let new_time_as_micro =
    datetime.time
    |> time_to_duration
    |> duration_decrease(by: time_to_sub)
    |> duration_as_microseconds

  // If the time to subtract crossed a day boundary, add an extra day to the 
  // number of days to subtract and adjust the time to subtract.
  let #(new_time_as_micro, days_to_sub) = case new_time_as_micro < 0 {
    True -> #(
      new_time_as_micro + unit.imprecise_day_microseconds,
      days_to_sub + 1,
    )
    False -> #(new_time_as_micro, days_to_sub)
  }

  let time_to_sub =
    Duration(time_to_microseconds(datetime.time) - new_time_as_micro)

  // Using the proper subtract functions here to modify the date and time
  // values instead of declaring a new date is important for perserving date 
  // correctness and time precision.
  let new_date =
    datetime.date
    |> date_subtract(days: days_to_sub)
  let new_time =
    datetime.time
    |> time_subtract(duration: time_to_sub)

  NaiveDateTime(date: new_date, time: new_time)
}

// -------------------------------------------------------------------------- //
//                             Offset Logic                                   //
// -------------------------------------------------------------------------- //

/// A datetime offset value. It represents the difference between UTC and the
/// datetime value it is associated with.
pub opaque type Offset {
  Offset(minutes: Int)
}

@internal
pub fn offset(minutes minutes) {
  Offset(minutes)
}

@internal
pub fn offset_get_minutes(offset: Offset) {
  offset.minutes
}

@internal
pub const utc = Offset(0)

@internal
pub fn new_offset(offset_minutes minutes: Int) -> Result(Offset, Nil) {
  Offset(minutes) |> validate_offset
}

@internal
pub fn offset_from_string(
  offset_str: String,
) -> Result(Offset, tempo_error.OffsetParseError) {
  use offset <- result.try(case offset_str {
    // Parse Z format
    "Z" -> Ok(utc)
    "z" -> Ok(utc)

    // Parse +-hh:mm format
    _ -> {
      use #(sign, hour, minute): #(String, String, String) <- result.try(case
        string.split(offset_str, ":")
      {
        [hour, minute] ->
          case string.length(hour), string.length(minute) {
            3, 2 ->
              Ok(#(
                string.slice(hour, at_index: 0, length: 1),
                string.slice(hour, at_index: 1, length: 2),
                minute,
              ))
            _, _ -> Error(tempo_error.OffsetInvalidFormat(offset_str))
          }
        _ ->
          // Parse +-hhmm format, +-hh format, or +-h format
          case string.length(offset_str) {
            5 ->
              Ok(#(
                string.slice(offset_str, at_index: 0, length: 1),
                string.slice(offset_str, at_index: 1, length: 2),
                string.slice(offset_str, at_index: 3, length: 2),
              ))
            3 ->
              Ok(#(
                string.slice(offset_str, at_index: 0, length: 1),
                string.slice(offset_str, at_index: 1, length: 2),
                "0",
              ))
            2 ->
              Ok(#(
                string.slice(offset_str, at_index: 0, length: 1),
                string.slice(offset_str, at_index: 1, length: 1),
                "0",
              ))
            _ -> Error(tempo_error.OffsetInvalidFormat(offset_str))
          }
      })

      case sign, int.parse(hour), int.parse(minute) {
        _, Ok(0), Ok(0) -> Ok(utc)
        "-", Ok(hour), Ok(minute) if hour <= 24 && minute <= 60 ->
          Ok(Offset(-{ hour * 60 + minute }))
        "+", Ok(hour), Ok(minute) if hour <= 24 && minute <= 60 ->
          Ok(Offset(hour * 60 + minute))
        _, _, _ -> Error(tempo_error.OffsetInvalidFormat(offset_str))
      }
    }
  })
  validate_offset(offset)
  |> result.replace_error(tempo_error.OffsetOutOfBounds(offset_str))
}

@internal
pub fn offset_to_string(offset: Offset) -> String {
  let #(is_negative, hours) = case offset_get_minutes(offset) / 60 {
    h if h <= 0 -> #(True, -h)
    h -> #(False, h)
  }

  let mins = case offset_get_minutes(offset) % 60 {
    m if m < 0 -> -m
    m -> m
  }

  case is_negative, hours, mins {
    _, 0, 0 -> "-00:00"

    _, 0, m -> "-00:" <> int.to_string(m) |> string.pad_start(2, with: "0")

    True, h, m ->
      "-"
      <> int.to_string(h) |> string.pad_start(2, with: "0")
      <> ":"
      <> int.to_string(m) |> string.pad_start(2, with: "0")

    False, h, m ->
      "+"
      <> int.to_string(h) |> string.pad_start(2, with: "0")
      <> ":"
      <> int.to_string(m) |> string.pad_start(2, with: "0")
  }
}

@internal
pub fn validate_offset(offset: Offset) -> Result(Offset, Nil) {
  // Valid time offsets are between -12:00 and +14:00
  case offset.minutes >= -720 && offset.minutes <= 840 {
    True -> Ok(offset)
    False -> Error(Nil)
  }
}

@internal
pub fn offset_to_duration(offset: Offset) -> Duration {
  -offset.minutes * 60_000_000 |> Duration
}

fn offset_replace_format(content: String, offset: Offset) -> String {
  case content {
    "z" ->
      case offset.minutes {
        0 -> "Z"
        _ -> {
          let str_offset = offset |> offset_to_string

          case str_offset |> string.split(":") {
            [hours, "00"] -> hours
            _ -> str_offset
          }
        }
      }
    "Z" -> offset |> offset_to_string
    "ZZ" ->
      offset
      |> offset_to_string
      |> string.replace(":", "")
    _ -> content
  }
}

// -------------------------------------------------------------------------- //
//                              Date Logic                                    //
// -------------------------------------------------------------------------- //

/// A date value. It represents a specific day on the civil calendar with no
/// time of day associated with it.
pub opaque type Date {
  Date(year: Int, month: Month, day: Int)
}

@internal
pub fn date(year year, month month, day day) {
  Date(year: year, month: month, day: day)
}

@internal
pub fn date_get_year(date: Date) {
  date.year
}

@internal
pub fn date_get_month(date: Date) {
  date.month
}

@internal
pub fn date_get_month_year(date: Date) {
  MonthYear(date.month, date.year)
}

@internal
pub fn date_get_day(date: Date) {
  date.day
}

@internal
pub fn new_date(
  year year: Int,
  month month: Int,
  day day: Int,
) -> Result(Date, tempo_error.DateOutOfBoundsError) {
  date_from_tuple(#(year, month, day))
}

@internal
pub fn date_to_string(date: Date) -> String {
  string_tree.from_strings([
    int.to_string(date.year),
    "-",
    month_to_int(date.month)
      |> int.to_string
      |> string.pad_start(2, with: "0"),
    "-",
    int.to_string(date.day) |> string.pad_start(2, with: "0"),
  ])
  |> string_tree.to_string
}

@internal
pub fn date_replace_format(content: String, date: Date) -> String {
  case content {
    "YY" ->
      date.year
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
      |> string.slice(at_index: -2, length: 2)
    "YYYY" ->
      date.year
      |> int.to_string
      |> string.pad_start(with: "0", to: 4)
    "M" ->
      date.month
      |> month_to_int
      |> int.to_string
    "MM" ->
      date.month
      |> month_to_int
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "MMM" ->
      date.month
      |> month_to_short_string
    "MMMM" ->
      date.month
      |> month_to_long_string
    "D" ->
      date.day
      |> int.to_string
    "DD" ->
      date.day
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "d" ->
      date
      |> date_to_day_of_week_number
      |> int.to_string
    "dd" ->
      date
      |> date_to_day_of_week_short
      |> string.slice(at_index: 0, length: 2)
    "ddd" -> date |> date_to_day_of_week_short
    "dddd" -> date |> date_to_day_of_week_long
    _ -> content
  }
}

fn date_to_day_of_week_short(date: Date) -> String {
  case date_to_day_of_week_number(date) {
    0 -> "Sun"
    1 -> "Mon"
    2 -> "Tue"
    3 -> "Wed"
    4 -> "Thu"
    5 -> "Fri"
    6 -> "Sat"
    _ -> panic as "Invalid day of week found after modulo by 7"
  }
}

fn date_to_day_of_week_long(date: Date) -> String {
  case date_to_day_of_week_number(date) {
    0 -> "Sunday"
    1 -> "Monday"
    2 -> "Tuesday"
    3 -> "Wednesday"
    4 -> "Thursday"
    5 -> "Friday"
    6 -> "Saturday"
    _ -> panic as "Invalid day of week found after modulo by 7"
  }
}

@internal
pub fn date_to_day_of_week_number(date: Date) -> Int {
  let year_code =
    date.year % 100
    |> fn(short_year) { { short_year + { short_year / 4 } } % 7 }

  let month_code = case date.month {
    Jan -> 0
    Feb -> 3
    Mar -> 3
    Apr -> 6
    May -> 1
    Jun -> 4
    Jul -> 6
    Aug -> 2
    Sep -> 5
    Oct -> 0
    Nov -> 3
    Dec -> 5
  }

  let century_code = case date.year {
    year if year < 1752 -> 0
    year if year < 1800 -> 4
    year if year < 1900 -> 2
    year if year < 2000 -> 0
    year if year < 2100 -> 6
    year if year < 2200 -> 4
    year if year < 2300 -> 2
    year if year < 2400 -> 4
    _ -> 0
  }

  let leap_year_code = case is_leap_year(date.year) {
    True ->
      case date.month {
        Jan | Feb -> 1
        _ -> 0
      }
    False -> 0
  }

  { year_code + month_code + century_code + date.day - leap_year_code } % 7
}

@internal
pub fn date_from_tuple(
  date: #(Int, Int, Int),
) -> Result(Date, tempo_error.DateOutOfBoundsError) {
  let year = date.0
  let month = date.1
  let day = date.2

  use month <- result.try(
    month_from_int(month)
    |> result.replace_error(
      tempo_error.DateMonthOutOfBounds(int.to_string(month)),
    ),
  )

  case year >= 1000 && year <= 9999 {
    True ->
      case day >= 1 && day <= month_days_of(month, in: year) {
        True -> Ok(Date(year, month, day))
        False ->
          Error(tempo_error.DateDayOutOfBounds(
            month_to_short_string(month) <> " " <> int.to_string(day),
          ))
      }
    False -> Error(tempo_error.DateYearOutOfBounds(int.to_string(year)))
  }
}

@internal
pub fn date_from_unix_utc(unix_ts: Int) -> Date {
  let z = unix_ts / 86_400 + 719_468
  let era =
    case z >= 0 {
      True -> z
      False -> z - 146_096
    }
    / 146_097
  let doe = z - era * 146_097
  let yoe = { doe - doe / 1460 + doe / 36_524 - doe / 146_096 } / 365
  let y = yoe + era * 400
  let doy = doe - { 365 * yoe + yoe / 4 - yoe / 100 }
  let mp = { 5 * doy + 2 } / 153
  let d = doy - { 153 * mp + 2 } / 5 + 1
  let m =
    mp
    + case mp < 10 {
      True -> 3
      False -> -9
    }
  let y = case m <= 2 {
    True -> y + 1
    False -> y
  }

  let assert Ok(month) = month_from_int(m)

  Date(y, month, d)
}

@internal
pub fn date_to_unix_utc(date: Date) -> Int {
  let full_years_since_epoch = date_get_year(date) - 1970
  // Offset the year by one to cacluate the number of leap years since the
  // epoch since 1972 is the first leap year after epoch. 1972 is a leap year,
  // so when the date is 1972, the elpased leap years (1972 has not elapsed
  // yet) is equal to (2 + 1) / 4, which is 0. When the date is 1973, the
  // elapsed leap years is equal to (3 + 1) / 4, which is 1, because one leap
  // year, 1972, has fully elapsed.
  let full_elapsed_leap_years_since_epoch = { full_years_since_epoch + 1 } / 4
  let full_elapsed_non_leap_years_since_epoch =
    full_years_since_epoch - full_elapsed_leap_years_since_epoch

  let year_sec =
    { full_elapsed_non_leap_years_since_epoch * 31_536_000 }
    + { full_elapsed_leap_years_since_epoch * 31_622_400 }

  let feb_milli = case is_leap_year(date |> date_get_year) {
    True -> 2_505_600
    False -> 2_419_200
  }

  let month_sec = case date |> date_get_month {
    Jan -> 0
    Feb -> 2_678_400
    Mar -> 2_678_400 + feb_milli
    Apr -> 5_356_800 + feb_milli
    May -> 7_948_800 + feb_milli
    Jun -> 10_627_200 + feb_milli
    Jul -> 13_219_200 + feb_milli
    Aug -> 15_897_600 + feb_milli
    Sep -> 18_576_000 + feb_milli
    Oct -> 21_168_000 + feb_milli
    Nov -> 23_846_400 + feb_milli
    Dec -> 26_438_400 + feb_milli
  }

  let day_sec = { date_get_day(date) - 1 } * 86_400

  year_sec + month_sec + day_sec
}

@internal
pub fn date_from_unix_micro_utc(unix_ts: Int) -> Date {
  date_from_unix_utc(unix_ts / 1_000_000)
}

@internal
pub fn date_to_unix_micro_utc(date: Date) -> Int {
  date_to_unix_utc(date) * 1_000_000
}

@internal
pub fn date_add(date: Date, days days: Int) -> Date {
  let days_left_this_month = month_days_of(date.month, in: date.year) - date.day

  case days <= days_left_this_month {
    True -> Date(date.year, date.month, { date.day } + days)
    False -> {
      let next_month = month_year_next(date |> date_get_month_year)
      date_add(
        Date(next_month.year, next_month.month, 1),
        days - days_left_this_month - 1,
      )
    }
  }
}

@internal
pub fn date_subtract(date: Date, days days: Int) -> Date {
  case days < date.day {
    True -> Date(date.year, date.month, { date.day } - days)
    False -> {
      let prior_month = month_year_prior(date |> date_get_month_year)

      date_subtract(
        Date(
          prior_month.year,
          prior_month.month,
          month_year_days_of(prior_month),
        ),
        days - date_get_day(date),
      )
    }
  }
}

@internal
pub fn date_days_apart(from start_date: Date, to end_date: Date) {
  case start_date |> date_is_earlier_or_equal(to: end_date) {
    True -> date_days_apart_positive(start_date, end_date)
    False -> -date_days_apart_positive(end_date, start_date)
  }
}

/// Returns the difference between two dates, assuming the start date
/// is sooner than the end_date
fn date_days_apart_positive(from start_date: Date, to end_date: Date) {
  // Caclulate the number of days in the years that are between (exclusive)
  // the start and end dates.
  let days_in_the_years_between = case
    calendar_years_apart(end_date, start_date)
  {
    years_apart if years_apart >= 2 ->
      list.range(1, years_apart - 1)
      |> list.map(fn(i) { date_get_year(end_date) + i |> year_days })
      |> int.sum
    _ -> 0
  }

  // Now that we have the number of days in the years between, we can ignore 
  // the fact that the start and end dates (may) be in different years and 
  // calculate the number of days in the months between (exclusive).
  let days_in_the_months_between =
    exclusive_months_between_days(start_date, end_date)

  // Now that we have the number of days in both the years and months between
  // the start and end dates, we can calculate the difference between the two 
  // dates and can ignore the fact that they may be in different years or 
  // months.
  let days_apart = case
    date_get_year(end_date) == date_get_year(start_date)
    && {
      date_get_month(end_date) |> month_to_int
      <= date_get_month(start_date) |> month_to_int
    }
  {
    True -> date_get_day(end_date) - date_get_day(start_date)
    False ->
      date_get_day(end_date)
      + {
        month_days_of(date_get_month(start_date), date_get_year(start_date))
        - date_get_day(start_date)
      }
  }

  // Now add the days from each section back up together.
  days_in_the_years_between + days_in_the_months_between + days_apart
}

fn exclusive_months_between_days(from: Date, to: Date) {
  use <- bool.guard(
    when: {
      to.year == from.year
      && {
        month_year_prior(MonthYear(to.month, to.year)) |> month_year_to_int
        < month_year_next(MonthYear(from.month, from.year)) |> month_year_to_int
      }
    },
    return: 0,
  )

  case to.year == from.year {
    True ->
      list.range(
        month_to_int({ from |> date_get_month_year |> month_year_next }.month),
        month_to_int({ to |> date_get_month_year |> month_year_prior }.month),
      )
      |> list.map(fn(m) {
        let assert Ok(m) = month_from_int(m)
        m
      })
    False -> {
      case to |> date_get_month == Jan {
        True -> []
        False ->
          list.range(
            1,
            month_to_int(
              { to |> date_get_month_year |> month_year_prior }.month,
            ),
          )
      }
      |> list.map(fn(m) {
        let assert Ok(m) = month_from_int(m)
        m
      })
      |> list.append(
        case from |> date_get_month == Dec {
          True -> []
          False ->
            list.range(
              month_to_int(
                { from |> date_get_month_year |> month_year_next }.month,
              ),
              12,
            )
        }
        |> list.map(fn(m) {
          let assert Ok(m) = month_from_int(m)
          m
        }),
      )
    }
  }
  |> list.map(fn(m) { month_days_of(m, in: to |> date_get_year) })
  |> int.sum
}

fn calendar_years_apart(later: Date, from earlier: Date) -> Int {
  later.year - earlier.year
}

@internal
pub fn date_compare(a: Date, to b: Date) -> order.Order {
  case a.year == b.year {
    True ->
      case a.month == b.month {
        True ->
          case a.day == b.day {
            True -> order.Eq
            False -> int.compare(a.day, b.day)
          }
        False ->
          int.compare(
            month_to_int(a |> date_get_month),
            month_to_int(b |> date_get_month),
          )
      }
    False -> int.compare(a.year, b.year)
  }
}

@internal
pub fn date_is_earlier(a: Date, than b: Date) -> Bool {
  date_compare(a, b) == order.Lt
}

@internal
pub fn date_is_earlier_or_equal(a: Date, to b: Date) -> Bool {
  date_compare(a, b) == order.Lt || date_compare(a, b) == order.Eq
}

@internal
pub fn date_is_equal(a: Date, to b: Date) -> Bool {
  date_compare(a, b) == order.Eq
}

@internal
pub fn date_is_later(a: Date, than b: Date) -> Bool {
  date_compare(a, b) == order.Gt
}

@internal
pub fn date_is_later_or_equal(a: Date, to b: Date) -> Bool {
  date_compare(a, b) == order.Gt || date_compare(a, b) == order.Eq
}

// -------------------------------------------------------------------------- //
//                              Month Logic                                   //
// -------------------------------------------------------------------------- //

/// A specific month on the civil calendar. 
pub type Month {
  Jan
  Feb
  Mar
  Apr
  May
  Jun
  Jul
  Aug
  Sep
  Oct
  Nov
  Dec
}

@internal
pub const months = [Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec]

@internal
pub fn month_from_int(month: Int) -> Result(Month, Nil) {
  case month {
    1 -> Ok(Jan)
    2 -> Ok(Feb)
    3 -> Ok(Mar)
    4 -> Ok(Apr)
    5 -> Ok(May)
    6 -> Ok(Jun)
    7 -> Ok(Jul)
    8 -> Ok(Aug)
    9 -> Ok(Sep)
    10 -> Ok(Oct)
    11 -> Ok(Nov)
    12 -> Ok(Dec)
    _ -> Error(Nil)
  }
}

@internal
pub fn month_from_short_string(month: String) -> Result(Month, Nil) {
  case month {
    "Jan" -> Ok(Jan)
    "Feb" -> Ok(Feb)
    "Mar" -> Ok(Mar)
    "Apr" -> Ok(Apr)
    "May" -> Ok(May)
    "Jun" -> Ok(Jun)
    "Jul" -> Ok(Jul)
    "Aug" -> Ok(Aug)
    "Sep" -> Ok(Sep)
    "Oct" -> Ok(Oct)
    "Nov" -> Ok(Nov)
    "Dec" -> Ok(Dec)
    _ -> Error(Nil)
  }
}

@internal
pub fn month_from_long_string(month: String) {
  case month {
    "January" -> Ok(Jan)
    "February" -> Ok(Feb)
    "March" -> Ok(Mar)
    "April" -> Ok(Apr)
    "May" -> Ok(May)
    "June" -> Ok(Jun)
    "July" -> Ok(Jul)
    "August" -> Ok(Aug)
    "September" -> Ok(Sep)
    "October" -> Ok(Oct)
    "November" -> Ok(Nov)
    "December" -> Ok(Dec)
    _ -> Error(Nil)
  }
}

@internal
pub fn month_to_int(month: Month) -> Int {
  case month {
    Jan -> 1
    Feb -> 2
    Mar -> 3
    Apr -> 4
    May -> 5
    Jun -> 6
    Jul -> 7
    Aug -> 8
    Sep -> 9
    Oct -> 10
    Nov -> 11
    Dec -> 12
  }
}

@internal
pub fn month_to_short_string(month: Month) -> String {
  case month {
    Jan -> "Jan"
    Feb -> "Feb"
    Mar -> "Mar"
    Apr -> "Apr"
    May -> "May"
    Jun -> "Jun"
    Jul -> "Jul"
    Aug -> "Aug"
    Sep -> "Sep"
    Oct -> "Oct"
    Nov -> "Nov"
    Dec -> "Dec"
  }
}

@internal
pub fn month_to_long_string(month: Month) -> String {
  case month {
    Jan -> "January"
    Feb -> "February"
    Mar -> "March"
    Apr -> "April"
    May -> "May"
    Jun -> "June"
    Jul -> "July"
    Aug -> "August"
    Sep -> "September"
    Oct -> "October"
    Nov -> "November"
    Dec -> "December"
  }
}

@internal
pub fn month_days_of(month: Month, in year: Int) -> Int {
  month_year_days_of(MonthYear(month, year))
}

// -------------------------------------------------------------------------- //
//                             Month Year Logic                               //
// -------------------------------------------------------------------------- //

/// A month in a specific year.
pub type MonthYear {
  MonthYear(month: Month, year: Int)
}

@internal
pub fn month_year_to_int(month_year: MonthYear) -> Int {
  month_year.year * 100 + month_to_int(month_year.month)
}

@internal
pub fn month_year_prior(month_year: MonthYear) -> MonthYear {
  case month_year.month {
    Jan -> MonthYear(Dec, month_year.year - 1)
    Feb -> MonthYear(Jan, month_year.year)
    Mar -> MonthYear(Feb, month_year.year)
    Apr -> MonthYear(Mar, month_year.year)
    May -> MonthYear(Apr, month_year.year)
    Jun -> MonthYear(May, month_year.year)
    Jul -> MonthYear(Jun, month_year.year)
    Aug -> MonthYear(Jul, month_year.year)
    Sep -> MonthYear(Aug, month_year.year)
    Oct -> MonthYear(Sep, month_year.year)
    Nov -> MonthYear(Oct, month_year.year)
    Dec -> MonthYear(Nov, month_year.year)
  }
}

@internal
pub fn month_year_next(month_year: MonthYear) -> MonthYear {
  case month_year.month {
    Jan -> MonthYear(Feb, month_year.year)
    Feb -> MonthYear(Mar, month_year.year)
    Mar -> MonthYear(Apr, month_year.year)
    Apr -> MonthYear(May, month_year.year)
    May -> MonthYear(Jun, month_year.year)
    Jun -> MonthYear(Jul, month_year.year)
    Jul -> MonthYear(Aug, month_year.year)
    Aug -> MonthYear(Sep, month_year.year)
    Sep -> MonthYear(Oct, month_year.year)
    Oct -> MonthYear(Nov, month_year.year)
    Nov -> MonthYear(Dec, month_year.year)
    Dec -> MonthYear(Jan, month_year.year + 1)
  }
}

@internal
pub fn month_year_days_of(my: MonthYear) -> Int {
  case my.month {
    Jan -> 31
    Mar -> 31
    May -> 31
    Jul -> 31
    Aug -> 31
    Oct -> 31
    Dec -> 31
    _ ->
      case my.month {
        Apr -> 30
        Jun -> 30
        Sep -> 30
        Nov -> 30
        _ ->
          case is_leap_year(my.year) {
            True -> 29
            False -> 28
          }
      }
  }
}

// -------------------------------------------------------------------------- //
//                              Year Logic                                    //
// -------------------------------------------------------------------------- //

@internal
pub fn is_leap_year(year: Int) -> Bool {
  case year % 4 == 0 {
    True ->
      case year % 100 == 0 {
        True ->
          case year % 400 == 0 {
            True -> True
            False -> False
          }
        False -> True
      }
    False -> False
  }
}

@internal
pub fn year_days(of year: Int) -> Int {
  case is_leap_year(year) {
    True -> 366
    False -> 365
  }
}

// -------------------------------------------------------------------------- //
//                              Time Logic                                    //
// -------------------------------------------------------------------------- //

/// A time of day value. It represents a specific time on an unspecified date.
/// It cannot be greater than 24 hours or less than 0 hours. It has microsecond
/// precision.
pub opaque type Time {
  Time(hour: Int, minute: Int, second: Int, microsecond: Int)
}

@internal
pub fn time(hour hour, minute minute, second second, micro microsecond) {
  Time(hour:, minute:, second:, microsecond:)
}

@internal
pub fn time_get_hour(time: Time) {
  time.hour
}

@internal
pub fn time_get_minute(time: Time) {
  time.minute
}

@internal
pub fn time_get_second(time: Time) {
  time.second
}

@internal
pub fn time_get_micro(time: Time) {
  time.microsecond
}

@internal
pub fn new_time(
  hour: Int,
  minute: Int,
  second: Int,
) -> Result(Time, tempo_error.TimeOutOfBoundsError) {
  Time(hour, minute, second, 0) |> validate_time
}

@internal
pub fn new_time_milli(
  hour: Int,
  minute: Int,
  second: Int,
  millisecond: Int,
) -> Result(Time, tempo_error.TimeOutOfBoundsError) {
  Time(hour, minute, second, millisecond * 1000)
  |> validate_time
}

@internal
pub fn new_time_micro(
  hour: Int,
  minute: Int,
  second: Int,
  microsecond: Int,
) -> Result(Time, tempo_error.TimeOutOfBoundsError) {
  Time(hour, minute, second, microsecond)
  |> validate_time
}

@internal
pub fn validate_time(
  time: Time,
) -> Result(Time, tempo_error.TimeOutOfBoundsError) {
  case
    {
      time.hour >= 0
      && time.hour <= 23
      && time.minute >= 0
      && time.minute <= 59
      && time.second >= 0
      && time.second <= 59
    }
    // For end of day time https://en.wikipedia.org/wiki/ISO_8601
    || {
      time.hour == 24
      && time.minute == 0
      && time.second == 0
      && time.microsecond == 0
    }
    // For leap seconds https://en.wikipedia.org/wiki/Leap_second. Leap seconds
    // are not fully supported by this package, but can be parsed from ISO 8601
    // dates.
    || { time.minute == 59 && time.second == 60 && time.microsecond == 0 }
  {
    True ->
      case time.microsecond <= 999_999 {
        True -> Ok(time)
        False ->
          Error(tempo_error.TimeMicroSecondOutOfBounds(time_to_string(time)))
      }
    False ->
      case time.hour, time.minute, time.second {
        _, _, s if s > 59 || s < 0 ->
          Error(tempo_error.TimeSecondOutOfBounds(time_to_string(time)))
        _, m, _ if m > 59 || m < 0 ->
          Error(tempo_error.TimeMinuteOutOfBounds(time_to_string(time)))
        _, _, _ -> Error(tempo_error.TimeHourOutOfBounds(time_to_string(time)))
      }
  }
}

@internal
pub fn time_to_string(time: Time) -> String {
  string_tree.from_strings([
    time.hour
      |> int.to_string
      |> string.pad_start(2, with: "0"),
    ":",
    time.minute
      |> int.to_string
      |> string.pad_start(2, with: "0"),
    ":",
    time.second
      |> int.to_string
      |> string.pad_start(2, with: "0"),
  ])
  |> string_tree.append(".")
  |> string_tree.append(
    time.microsecond
    |> int.to_string
    |> string.pad_start(6, with: "0"),
  )
  |> string_tree.to_string
}

@internal
pub fn time_replace_format(content: String, time: Time) -> String {
  case content {
    "H" -> time.hour |> int.to_string
    "HH" ->
      time.hour
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "h" ->
      case time.hour {
        hour if hour == 0 -> 12
        hour if hour > 12 -> hour - 12
        hour -> hour
      }
      |> int.to_string
    "hh" ->
      case time.hour {
        hour if hour == 0 -> 12
        hour if hour > 12 -> hour - 12
        hour -> hour
      }
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "a" ->
      case time.hour >= 12 {
        True -> "pm"
        False -> "am"
      }
    "A" ->
      case time.hour >= 12 {
        True -> "PM"
        False -> "AM"
      }
    "m" -> time.minute |> int.to_string
    "mm" ->
      time.minute
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "s" -> time.second |> int.to_string
    "ss" ->
      time.second
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "SSS" ->
      { time.microsecond / 1000 }
      |> int.to_string
      |> string.pad_start(with: "0", to: 3)
    "SSSS" ->
      { time.microsecond }
      |> int.to_string
      |> string.pad_start(with: "0", to: 6)
    _ -> content
  }
}

@internal
pub fn adjust_12_hour_to_24_hour(hour, am am) {
  case am, hour {
    True, _ if hour == 12 -> 0
    True, _ -> hour
    False, _ if hour == 12 -> hour
    False, _ -> hour + 12
  }
}

@internal
pub fn time_difference(from a: Time, to b: Time) -> Duration {
  time_to_microseconds(b) - time_to_microseconds(a) |> Duration
}

@internal
pub fn time_to_microseconds(time: Time) -> Int {
  { time.hour * unit.hour_microseconds }
  + { time.minute * unit.minute_microseconds }
  + { time.second * unit.second_microseconds }
  + { time.microsecond }
}

@internal
pub fn time_from_microseconds(microseconds: Int) -> Time {
  let in_range_micro = microseconds % unit.imprecise_day_microseconds

  let adj_micro = case in_range_micro < 0 {
    True -> in_range_micro + unit.imprecise_day_microseconds
    False -> in_range_micro
  }

  let hour = adj_micro / 3_600_000_000

  let minute = { adj_micro - hour * 3_600_000_000 } / 60_000_000

  let second =
    { adj_micro - hour * 3_600_000_000 - minute * 60_000_000 } / 1_000_000

  let microsecond =
    adj_micro - hour * 3_600_000_000 - minute * 60_000_000 - second * 1_000_000

  Time(hour:, minute:, second:, microsecond:)
}

@internal
pub fn time_from_unix_micro_utc(unix_ts: Int) -> Time {
  // Subtract the microseconds that are responsible for the date.
  { unix_ts - { date_to_unix_micro_utc(date_from_unix_micro_utc(unix_ts)) } }
  |> time_from_microseconds
}

@internal
pub fn time_to_duration(time: Time) -> Duration {
  time_to_microseconds(time) |> Duration
}

@internal
pub fn time_compare(a: Time, to b: Time) -> order.Order {
  case a.hour == b.hour {
    True ->
      case a.minute == b.minute {
        True ->
          case a.second == b.second {
            True ->
              case a.microsecond == b.microsecond {
                True -> order.Eq
                False ->
                  case a.microsecond < b.microsecond {
                    True -> order.Lt
                    False -> order.Gt
                  }
              }
            False ->
              case a.second < b.second {
                True -> order.Lt
                False -> order.Gt
              }
          }
        False ->
          case a.minute < b.minute {
            True -> order.Lt
            False -> order.Gt
          }
      }
    False ->
      case a.hour < b.hour {
        True -> order.Lt
        False -> order.Gt
      }
  }
}

@internal
pub fn time_is_earlier(a: Time, than b: Time) -> Bool {
  time_compare(a, b) == order.Lt
}

@internal
pub fn time_is_earlier_or_equal(a: Time, to b: Time) -> Bool {
  time_compare(a, b) == order.Lt || time_compare(a, b) == order.Eq
}

@internal
pub fn time_is_equal(a: Time, to b: Time) -> Bool {
  time_compare(a, b) == order.Eq
}

@internal
pub fn time_is_later(a: Time, than b: Time) -> Bool {
  time_compare(a, b) == order.Gt
}

@internal
pub fn time_is_later_or_equal(a: Time, to b: Time) -> Bool {
  time_compare(a, b) == order.Gt || time_compare(a, b) == order.Eq
}

@internal
pub fn time_add(a: Time, duration b: Duration) -> Time {
  time_to_microseconds(a) + b.microseconds |> time_from_microseconds
}

@internal
pub fn time_subtract(a: Time, duration b: Duration) -> Time {
  time_to_microseconds(a) - b.microseconds |> time_from_microseconds
}

// -------------------------------------------------------------------------- //
//                            Duration Logic                                  //
// -------------------------------------------------------------------------- //

/// A duration between two times. It represents a range of time values and
/// can be span more than a day. It can be used to calculate the number of
/// days, weeks, hours, minutes, or seconds between two times, but cannot
/// accurately be used to calculate the number of years or months between.
/// 
/// It is also used as the basis for specifying how to increase or decrease
/// a datetime or time value.
pub opaque type Duration {
  Duration(microseconds: Int)
}

@internal
pub fn duration(microseconds microseconds) {
  Duration(microseconds)
}

@internal
pub fn duration_get_microseconds(duration: Duration) -> Int {
  duration.microseconds
}

@internal
pub fn duration_days(days: Int) -> Duration {
  days |> unit.imprecise_days |> duration
}

@internal
pub fn duration_increase(a: Duration, by b: Duration) -> Duration {
  Duration(a.microseconds + b.microseconds)
}

@internal
pub fn duration_decrease(a: Duration, by b: Duration) -> Duration {
  Duration(a.microseconds - b.microseconds)
}

@internal
pub fn duration_absolute(duration: Duration) -> Duration {
  case duration.microseconds < 0 {
    True -> -{ duration.microseconds } |> Duration
    False -> duration
  }
}

@internal
pub fn duration_as_days(duration: Duration) -> Int {
  duration.microseconds |> unit.as_days_imprecise
}

@internal
pub fn duration_as_microseconds(duration: Duration) -> Int {
  duration.microseconds
}

// -------------------------------------------------------------------------- //
//                             Period Logic                                   //
// -------------------------------------------------------------------------- //

/// A period between two calendar datetimes. It represents a range of
/// datetimes and can be used to calculate the number of days, weeks, months, 
/// or years between two dates. It can also be interated over and datetime 
/// values can be checked for inclusion in the period.
pub opaque type Period {
  DateTimePeriod(start: DateTime, end: DateTime)
  NaiveDateTimePeriod(start: NaiveDateTime, end: NaiveDateTime)
  DatePeriod(start: Date, end: Date)
}

@internal
pub fn period_new(start start, end end) {
  let #(start, end) = case start |> datetime_is_earlier_or_equal(to: end) {
    True -> #(start, end)
    False -> #(end, start)
  }

  DateTimePeriod(start:, end:)
}

@internal
pub fn period_new_naive(start start, end end) {
  let #(start, end) = case
    start |> naive_datetime_is_earlier_or_equal(to: end)
  {
    True -> #(start, end)
    False -> #(end, start)
  }

  NaiveDateTimePeriod(start:, end:)
}

@internal
pub fn period_new_date(start start, end end) {
  let #(start, end) = case start |> date_is_earlier_or_equal(to: end) {
    True -> #(start, end)
    False -> #(end, start)
  }

  DatePeriod(start:, end:)
}

@internal
pub fn period_as_duration(period: Period) -> Duration {
  let #(start_date, end_date, start_time, end_time) =
    period_get_start_and_end_date_and_time(period)

  date_days_apart(start_date, end_date)
  |> duration_days
  |> duration_increase(by: time_difference(end_time, from: start_time))
}

@internal
pub fn period_get_start_and_end_date_and_time(
  period,
) -> #(Date, Date, Time, Time) {
  case period {
    DatePeriod(start, end) -> #(start, end, Time(0, 0, 0, 0), Time(24, 0, 0, 0))
    NaiveDateTimePeriod(start, end) -> #(
      start.date,
      end.date,
      start.time,
      end.time,
    )
    DateTimePeriod(start, end) -> #(start.date, end.date, start.time, end.time)
  }
}

@internal
pub fn period_contains_datetime(period: Period, datetime: DateTime) -> Bool {
  case period {
    DateTimePeriod(start, end) ->
      datetime
      |> datetime_is_later_or_equal(to: start)
      && datetime
      |> datetime_is_earlier_or_equal(to: end)

    _ ->
      period_contains_naive_datetime(
        period,
        NaiveDateTime(date: datetime.date, time: datetime.time),
      )
  }
}

@internal
pub fn period_contains_naive_datetime(
  period: Period,
  naive_datetime: NaiveDateTime,
) -> Bool {
  let #(start_date, end_date, start_time, end_time) =
    period_get_start_and_end_date_and_time(period)

  naive_datetime
  |> naive_datetime_is_later_or_equal(NaiveDateTime(start_date, start_time))
  && naive_datetime
  |> naive_datetime_is_earlier_or_equal(NaiveDateTime(end_date, end_time))
}

@internal
pub fn period_comprising_dates(period: Period) -> List(Date) {
  let #(start_date, end_date): #(Date, Date) = case period {
    DatePeriod(start, end) -> #(start, end)
    NaiveDateTimePeriod(start, end) -> #(start.date, end.date)
    DateTimePeriod(start, end) -> #(start.date, end.date)
  }

  do_period_comprising_dates([], end_date, start_date)
}

fn do_period_comprising_dates(dates, date, start_date) {
  case date |> date_is_later_or_equal(to: start_date) {
    True ->
      do_period_comprising_dates(
        [date, ..dates],
        date |> date_subtract(days: 1),
        start_date,
      )
    False -> dates
  }
}

@internal
pub fn period_comprising_months(period: Period) -> List(MonthYear) {
  let #(start_date, end_date) = case period {
    DatePeriod(start, end) -> #(start, end)
    NaiveDateTimePeriod(start, end) -> #(
      start |> naive_datetime_get_date,
      end |> naive_datetime_get_date,
    )
    DateTimePeriod(start, end) -> #(
      start |> datetime_get_naive |> naive_datetime_get_date,
      end |> datetime_get_naive |> naive_datetime_get_date,
    )
  }

  do_period_comprising_months(
    [],
    MonthYear(start_date.month, start_date.year),
    end_date,
  )
  |> list.reverse
}

fn do_period_comprising_months(mys, my: MonthYear, end_date) {
  case
    date(my.year, my.month, 1)
    |> date_is_earlier_or_equal(to: end_date)
  {
    True ->
      do_period_comprising_months([my, ..mys], month_year_next(my), end_date)
    False -> mys
  }
}

// -------------------------------------------------------------------------- //
//                             Format Logic                                   //
// -------------------------------------------------------------------------- //

/// Provides common datetime formatting templates.
/// 
/// The Custom format takes a format string that implements the same 
/// formatting directives as the nice Day.js 
/// library: https://day.js.org/docs/en/display/format, plus condensed offsets.
/// 
/// Values can be escaped by putting brackets around them, like "[Hello!] YYYY".
/// 
/// Available custom format directives: YY (two-digit year), YYYY (four-digit year), M (month), 
/// MM (two-digit month), MMM (short month name), MMMM (full month name), 
/// D (day of the month), DD (two-digint day of the month), d (day of the week), 
/// dd (min day of the week), ddd (short day of week), dddd (full day of the week), 
/// H (hour), HH (two-digit hour), h (12-hour clock hour), hh 
/// (two-digit 12-hour clock hour), m (minute), mm (two-digit minute),
/// s (second), ss (two-digit second), SSS (millisecond), SSSS (microsecond), 
/// Z (offset from UTC), ZZ (offset from UTC with no ":"),
/// z (short offset from UTC "-04", "Z"), A (AM/PM), a (am/pm).
pub type DateTimeFormat {
  ISO8601Sec
  ISO8601Milli
  ISO8601Micro
  HTTP
  Custom(format: String)
  CustomLocalised(format: String, locale: Locale)
  DateFormat(DateFormat)
  TimeFormat(TimeFormat)
  // LanguageLong
  // LanguageLongLocalised(locale: Locale)
  // LanguageShort
  // LanguageShortLocalised(locale: Locale)
  // HumanReadable
  // HumanReadable
}

/// Provides common naive datetime formatting templates.
/// 
/// The CustomNaive format takes a format string that implements the same 
/// formatting directives as the nice Day.js 
/// library: https://day.js.org/docs/en/display/format, plus condensed offsets.
/// 
/// Values can be escaped by putting brackets around them, like "[Hello!] YYYY".
/// 
/// Available custom format directives: YY (two-digit year), YYYY (four-digit year), M (month), 
/// MM (two-digit month), MMM (short month name), MMMM (full month name), 
/// D (day of the month), DD (two-digint day of the month), d (day of the week), 
/// dd (min day of the week), ddd (short day of week), dddd (full day of the week), 
/// H (hour), HH (two-digit hour), h (12-hour clock hour), hh 
/// (two-digit 12-hour clock hour), m (minute), mm (two-digit minute),
/// s (second), ss (two-digit second), SSS (millisecond), SSSS (microsecond), 
/// Z (offset from UTC), ZZ (offset from UTC with no ":"),
/// z (short offset from UTC "-04", "Z"), A (AM/PM), a (am/pm).
pub type NaiveDateTimeFormat {
  NaiveISO8601Sec
  NaiveISO8601Milli
  NaiveISO8601Micro
  CustomNaive(format: String)
  CustomNaiveLocalised(format: String, locale: Locale)
  NaiveDateFormat(DateFormat)
  NaiveTimeFormat(TimeFormat)
  // LanguageLong
  // LanguageLongLocalised(locale: Locale)
  // LanguageShort
  // LanguageShortLocalised(locale: Locale)
  // HumanReadable
  // HumanReadable
}

/// Provides common date formatting templates.
/// 
/// The CustomDate format takes a format string that implements the same 
/// formatting directives as the nice Day.js 
/// library: https://day.js.org/docs/en/display/format.
/// 
/// Values can be escaped by putting brackets around them, like "[Hello!] YYYY".
/// 
/// Available custom format directives: YY (two-digit year), YYYY (four-digit year), M (month), 
/// MM (two-digit month), MMM (short month name), MMMM (full month name), 
/// D (day of the month), DD (two-digit day of the month), d (day of the week), 
/// dd (min day of the week), ddd (short day of week), and
/// dddd (full day of the week).
pub type DateFormat {
  ISO8601Date
  CustomDate(format: String)
  CustomDateLocalised(format: String, locale: Locale)
  // LanguageDate
  // LanguageDateLocalised(locale: Locale)
  // HumanDate
}

/// Provides common time formatting templates.
/// 
/// The CustomTime format takes a format string that implements the same 
/// formatting directives as the nice Day.js 
/// library: https://day.js.org/docs/en/display/format.
/// 
/// Values can be escaped by putting brackets around them, like "[Hello!] HH".
/// 
/// Available custom format directives: H (hour), HH (two-digit hour), h (12-hour clock hour),
/// hh (two-digit 12-hour clock hour), m (minute), mm (two-digit minute),
/// s (second), ss (two-digit second), SSS (millisecond), SSSS (microsecond), 
/// A (AM/PM), a (am/pm).
pub type TimeFormat {
  ISO8601Time
  ISO8601TimeMilli
  ISO8601TimeMicro
  CustomTime(format: String)
  CustomTimeLocalised(format: String, locale: Locale)
  // LanguageTime
  // LanguageTimeLocalised(locale: Locale)
  // HumanTime
}

// Provide the locale API for now with no logic
/// A type that provides information on how to format dates and times for a 
/// specific region or language.
pub type Locale

@internal
pub fn get_datetime_format_str(format: DateTimeFormat) {
  case format {
    ISO8601Sec -> "YYYY/MM/DDTHH:mm:ssZ"
    ISO8601Milli -> "YYYY/MM/DDTHH:mm:ss.SSSZ"
    ISO8601Micro -> "YYYY/MM/DDTHH:mm:ss.SSSSZ"
    HTTP -> "ddd, DD MMM YYYY HH:mm:ss [GMT]"
    DateFormat(ISO8601Date) -> "YYYY/MM/DD"
    TimeFormat(ISO8601Time) -> "HH:mm:ssZ"
    TimeFormat(ISO8601TimeMilli) -> "HH:mm:ss.SSSZ"
    TimeFormat(ISO8601TimeMicro) -> "HH:mm:ss.SSSSZ"
    TimeFormat(CustomTime(format)) -> format
    TimeFormat(CustomTimeLocalised(format, _locale)) -> format
    DateFormat(CustomDate(format)) -> format
    DateFormat(CustomDateLocalised(format, _locale)) -> format
    Custom(format) -> format
    CustomLocalised(format, _locale) -> format
  }
}

@internal
pub fn get_naive_datetime_format_str(format: NaiveDateTimeFormat) {
  case format {
    NaiveISO8601Sec -> "YYYY-MM-DDTHH:mm:ss"
    NaiveISO8601Milli -> "YYYY-MM-DDTHH:mm:ss.SSS"
    NaiveISO8601Micro -> "YYYY-MM-DDTHH:mm:ss.SSSS"
    CustomNaive(format) -> format
    CustomNaiveLocalised(format, _locale) -> format
    NaiveDateFormat(ISO8601Date) -> "YYYY-MM-DD"
    NaiveTimeFormat(ISO8601Time) -> "HH:mm:ss"
    NaiveTimeFormat(ISO8601TimeMilli) -> "HH:mm:ss.SSS"
    NaiveTimeFormat(ISO8601TimeMicro) -> "HH:mm:ss.SSSS"
    NaiveTimeFormat(CustomTime(format)) -> format
    NaiveTimeFormat(CustomTimeLocalised(format, _locale)) -> format
    NaiveDateFormat(CustomDate(format)) -> format
    NaiveDateFormat(CustomDateLocalised(format, _locale)) -> format
  }
}

@internal
pub fn get_time_format_str(format: TimeFormat) {
  case format {
    ISO8601Time -> "HH:mm:ssZ"
    ISO8601TimeMilli -> "HH:mm:ss.SSSZ"
    ISO8601TimeMicro -> "HH:mm:ss.SSSSZ"
    CustomTime(format) -> format
    CustomTimeLocalised(format, _locale) -> format
  }
}

@internal
pub fn get_date_format_str(format: DateFormat) {
  case format {
    ISO8601Date -> "YYYY-MM-DD"
    CustomDate(format) -> format
    CustomDateLocalised(format, _locale) -> format
  }
}

@internal
pub const format_regex = "\\[([^\\]]+)\\]|Y{1,4}|M{1,4}|D{1,2}|d{1,4}|H{1,2}|h{1,2}|a|A|m{1,2}|s{1,2}|Z{1,2}|z|SSSSS|SSSS|SSS|."

/// Tries to parse a given date string without a known format. It will not 
/// parse two digit years and will assume the month always comes before the 
/// day in a date. Always prefer to use a module's specific `parse` function
/// when possible.
/// 
/// Using pattern matching, you can explicitly specify what to with the 
/// missing values from the input. Many libaries will assume a missing time
/// value means 00:00:00 or a missing offset means UTC. This design
/// lets the user decide how fallbacks are handled. 
/// 
/// ## Example
/// 
/// ```gleam
/// case tempo.parse_any("06/21/2024 at 01:42:11 PM") {
///   #(Some(date), Some(time), Some(offset)) ->
///     datetime.new(date, time, offset)
/// 
///   #(Some(date), Some(time), None) ->
///     datetime.new(date, time, offset.local())
/// 
///   _ -> datetime.now_local()
/// }
/// // -> datetime.literal("2024-06-21T13:42:11-04:00")
/// ```
/// 
/// ```gleam
/// tempo.parse_any("2024.06.21 11:32 AM -0400")
/// // -> #(
/// //  Some(date.literal("2024-06-21")), 
/// //  Some(time.literal("11:32:00")),
/// //  Some(offset.literal("-04:00"))
/// // )
/// ```
/// 
/// ```gleam
/// tempo.parse_any("Dec 25, 2024 at 6:00 AM")
/// // -> #(
/// //  Some(date.literal("2024-12-25")), 
/// //  Some(time.literal("06:00:00")),
/// //  None
/// // )
/// ```
pub fn parse_any(
  str: String,
) -> #(option.Option(Date), option.Option(Time), option.Option(Offset)) {
  let empty_result = #(None, None, None)

  use serial_re <- result_guard(
    when_error: regexp.from_string("\\d{9,}"),
    return: empty_result,
  )

  use <- bool.guard(when: regexp.check(serial_re, str), return: empty_result)

  use date_re <- result_guard(
    when_error: regexp.from_string(
      "(\\d{4})[-_/\\.\\s,]{0,2}(\\d{1,2})[-_/\\.\\s,]{0,2}(\\d{1,2})",
    ),
    return: empty_result,
  )

  use date_human_re <- result_guard(
    when_error: regexp.from_string(
      "(\\d{1,2}|January|Jan|january|jan|February|Feb|february|feb|March|Mar|march|mar|April|Apr|april|apr|May|may|June|Jun|june|jun|July|Jul|july|jul|August|Aug|august|aug|September|Sep|september|sep|October|Oct|october|oct|November|Nov|november|nov|December|Dec|december|dec)[-_/\\.\\s,]{0,2}(\\d{1,2})(?:st|nd|rd|th)?[-_/\\.\\s,]{0,2}(\\d{4})",
    ),
    return: empty_result,
  )

  use time_re <- result_guard(
    when_error: regexp.from_string(
      "(\\d{1,2})[:_\\.\\s]{0,1}(\\d{1,2})[:_\\.\\s]{0,1}(\\d{0,2})[\\.]{0,1}(\\d{0,9})\\s*(AM|PM|am|pm)?",
    ),
    return: empty_result,
  )

  use offset_re <- result_guard(
    when_error: regexp.from_string("([-+]\\d{2}):{0,1}(\\d{1,2})?"),
    return: empty_result,
  )

  use offset_char_re <- result_guard(
    when_error: regexp.from_string("(?<![a-zA-Z])[Zz](?![a-zA-Z])"),
    return: empty_result,
  )

  let unconsumed = str

  let #(date, unconsumed): #(option.Option(Date), String) = {
    case regexp.scan(date_re, unconsumed) {
      [regexp.Match(content, [Some(year), Some(month), Some(day)]), ..] ->
        case int.parse(year), int.parse(month), int.parse(day) {
          Ok(year), Ok(month), Ok(day) ->
            case new_date(year, month, day) {
              Ok(date) -> #(Some(date), string.replace(unconsumed, content, ""))

              _ -> #(None, unconsumed)
            }

          _, _, _ -> #(None, unconsumed)
        }

      _ -> #(None, unconsumed)
    }
  }

  let #(date, unconsumed): #(option.Option(Date), String) = {
    case date {
      Some(d) -> #(Some(d), unconsumed)
      None ->
        case regexp.scan(date_human_re, unconsumed) {
          [regexp.Match(content, [Some(month), Some(day), Some(year)]), ..] ->
            case
              int.parse(year),
              // Parse an int month or a written month
              int.parse(month)
              |> result.try(month_from_int)
              |> result.try_recover(fn(_) {
                month_from_short_string(month)
                |> result.try_recover(fn(_) { month_from_long_string(month) })
              }),
              int.parse(day)
            {
              Ok(year), Ok(month), Ok(day) ->
                case new_date(year, month_to_int(month), day) {
                  Ok(date) -> #(
                    Some(date),
                    string.replace(unconsumed, content, ""),
                  )

                  _ -> #(None, unconsumed)
                }

              _, _, _ -> #(None, unconsumed)
            }

          _ -> #(None, unconsumed)
        }
    }
  }

  let #(offset, unconsumed): #(option.Option(Offset), String) = {
    case regexp.scan(offset_re, unconsumed) {
      [regexp.Match(content, [Some(hours), Some(minutes)]), ..] ->
        case int.parse(hours), int.parse(minutes) {
          Ok(hour), Ok(minute) ->
            case new_offset(hour * 60 + minute) {
              Ok(offset) -> #(
                Some(offset),
                string.replace(unconsumed, content, ""),
              )

              _ -> #(None, unconsumed)
            }

          _, _ -> #(None, unconsumed)
        }

      _ -> #(None, unconsumed)
    }
  }

  let #(offset, unconsumed): #(option.Option(Offset), String) = {
    case offset {
      Some(o) -> #(Some(o), unconsumed)
      None ->
        case regexp.scan(offset_char_re, unconsumed) {
          [regexp.Match(content, _), ..] -> #(
            Some(utc),
            string.replace(unconsumed, content, ""),
          )

          _ -> #(None, unconsumed)
        }
    }
  }

  let #(time, _): #(option.Option(Time), String) = {
    let scan_results = regexp.scan(time_re, unconsumed)

    let adj_hour = case scan_results {
      [regexp.Match(_, [_, _, _, _, Some("PM")]), ..] -> adjust_12_hour_to_24_hour(
        _,
        am: False,
      )
      [regexp.Match(_, [_, _, _, _, Some("pm")]), ..] -> adjust_12_hour_to_24_hour(
        _,
        am: False,
      )
      [regexp.Match(_, [_, _, _, _, Some("AM")]), ..] -> adjust_12_hour_to_24_hour(
        _,
        am: True,
      )
      [regexp.Match(_, [_, _, _, _, Some("am")]), ..] -> adjust_12_hour_to_24_hour(
        _,
        am: True,
      )
      _ -> fn(hour) { hour }
    }

    case scan_results {
      [regexp.Match(content, [Some(h), Some(m), Some(s), Some(d), ..]), ..] ->
        case int.parse(h), int.parse(m), int.parse(s) {
          Ok(hour), Ok(minute), Ok(second) ->
            case string.length(d), int.parse(d) {
              3, Ok(milli) ->
                case adj_hour(hour) |> new_time_milli(minute, second, milli) {
                  Ok(date) -> #(
                    Some(date),
                    string.replace(unconsumed, content, ""),
                  )

                  _ -> #(None, unconsumed)
                }
              6, Ok(micro) ->
                case adj_hour(hour) |> new_time_micro(minute, second, micro) {
                  Ok(date) -> #(
                    Some(date),
                    string.replace(unconsumed, content, ""),
                  )

                  _ -> #(None, unconsumed)
                }

              _, _ -> #(None, unconsumed)
            }

          _, _, _ -> #(None, unconsumed)
        }

      [regexp.Match(content, [Some(h), Some(m), Some(s), ..]), ..] ->
        case int.parse(h), int.parse(m), int.parse(s) {
          Ok(hour), Ok(minute), Ok(second) ->
            case adj_hour(hour) |> new_time(minute, second) {
              Ok(date) -> #(Some(date), string.replace(unconsumed, content, ""))

              _ -> #(None, unconsumed)
            }

          _, _, _ -> #(None, unconsumed)
        }

      [regexp.Match(content, [Some(h), Some(m), ..]), ..] ->
        case int.parse(h), int.parse(m) {
          Ok(hour), Ok(minute) ->
            case adj_hour(hour) |> new_time(minute, 0) {
              Ok(date) -> #(Some(date), string.replace(unconsumed, content, ""))

              _ -> #(None, unconsumed)
            }

          _, _ -> #(None, unconsumed)
        }

      _ -> #(None, unconsumed)
    }
  }

  #(date, time, offset)
}

@internal
pub type DatetimePart {
  Year(Int)
  Month(Int)
  Day(Int)
  Hour(Int)
  Minute(Int)
  Second(Int)
  Millisecond(Int)
  Microsecond(Int)
  OffsetStr(String)
  TwelveHour(Int)
  AMPeriod
  PMPeriod
  Passthrough
}

@internal
pub fn consume_format(str: String, in fmt: String) {
  let assert Ok(re) =
    regexp.from_string(
      "\\[([^\\]]+)\\]|Y{1,4}|M{1,4}|D{1,2}|d{1,4}|H{1,2}|h{1,2}|a|A|m{1,2}|s{1,2}|Z{1,2}|SSS{3,5}|.",
    )

  regexp.scan(re, fmt)
  |> list.fold(from: Ok(#([], str)), with: fn(acc, match) {
    case acc {
      Ok(acc) -> {
        let #(consumed, input) = acc

        let res = case match {
          regexp.Match(content, []) -> consume_part(content, input)

          // If there is a non-empty subpattern, then the escape 
          // character "[ ... ]" matched, so we should not change anything here.
          regexp.Match(_, [Some(sub)]) ->
            Ok(#(Passthrough, string.drop_start(input, string.length(sub))))

          // This case is not expected, not really sure what to do with it 
          // so just pass through whatever was found
          regexp.Match(content, _) ->
            Ok(#(Passthrough, string.drop_start(input, string.length(content))))
        }

        case res {
          Ok(#(part, not_consumed)) -> Ok(#([part, ..consumed], not_consumed))
          Error(err) -> Error(err)
        }
      }
      Error(err) -> Error(err)
    }
  })
}

fn consume_part(fmt, from str) {
  case fmt {
    "YY" -> {
      use val <- result.map(
        string.slice(str, at_index: 0, length: 2) |> int.parse,
      )

      let current_year = current_year()

      let current_century = { current_year / 100 } * 100
      let current_two_year_date = current_year % 100

      case val > current_two_year_date {
        True -> #(
          Year({ current_century - 100 } + val),
          string.drop_start(str, 2),
        )
        False -> #(Year(current_century + val), string.drop_start(str, 2))
      }
    }
    "YYYY" -> {
      use year <- result.map(
        string.slice(str, at_index: 0, length: 4) |> int.parse,
      )

      #(Year(year), string.drop_start(str, 4))
    }
    "M" -> consume_one_or_two_digits(str, Month)
    "MM" -> consume_two_digits(str, Month)
    "MMM" -> {
      case str {
        "Jan" <> rest -> Ok(#(Month(1), rest))
        "Feb" <> rest -> Ok(#(Month(2), rest))
        "Mar" <> rest -> Ok(#(Month(3), rest))
        "Apr" <> rest -> Ok(#(Month(4), rest))
        "May" <> rest -> Ok(#(Month(5), rest))
        "Jun" <> rest -> Ok(#(Month(6), rest))
        "Jul" <> rest -> Ok(#(Month(7), rest))
        "Aug" <> rest -> Ok(#(Month(8), rest))
        "Sep" <> rest -> Ok(#(Month(9), rest))
        "Oct" <> rest -> Ok(#(Month(10), rest))
        "Nov" <> rest -> Ok(#(Month(11), rest))
        "Dec" <> rest -> Ok(#(Month(12), rest))
        _ -> Error(Nil)
      }
    }
    "MMMM" -> {
      case str {
        "January" <> rest -> Ok(#(Month(1), rest))
        "February" <> rest -> Ok(#(Month(2), rest))
        "March" <> rest -> Ok(#(Month(3), rest))
        "April" <> rest -> Ok(#(Month(4), rest))
        "May" <> rest -> Ok(#(Month(5), rest))
        "June" <> rest -> Ok(#(Month(6), rest))
        "July" <> rest -> Ok(#(Month(7), rest))
        "August" <> rest -> Ok(#(Month(8), rest))
        "September" <> rest -> Ok(#(Month(9), rest))
        "October" <> rest -> Ok(#(Month(10), rest))
        "November" <> rest -> Ok(#(Month(11), rest))
        "December" <> rest -> Ok(#(Month(12), rest))
        _ -> Error(Nil)
      }
    }
    "D" -> consume_one_or_two_digits(str, Day)
    "DD" -> consume_two_digits(str, Day)
    "H" -> consume_one_or_two_digits(str, Hour)
    "HH" -> consume_two_digits(str, Hour)
    "h" -> consume_one_or_two_digits(str, TwelveHour)
    "hh" -> consume_two_digits(str, TwelveHour)
    "a" -> {
      case str {
        "am" <> rest -> Ok(#(AMPeriod, rest))
        "pm" <> rest -> Ok(#(PMPeriod, rest))
        _ -> Error(Nil)
      }
    }
    "A" -> {
      case str {
        "AM" <> rest -> Ok(#(AMPeriod, rest))
        "PM" <> rest -> Ok(#(PMPeriod, rest))
        _ -> Error(Nil)
      }
    }
    "m" -> consume_one_or_two_digits(str, Minute)
    "mm" -> consume_two_digits(str, Minute)
    "s" -> consume_one_or_two_digits(str, Second)
    "ss" -> consume_two_digits(str, Second)
    "SSS" -> {
      use milli <- result.map(
        string.slice(str, at_index: 0, length: 3) |> int.parse,
      )

      #(Millisecond(milli), string.drop_start(str, 3))
    }
    "SSSS" -> {
      use micro <- result.map(
        string.slice(str, at_index: 0, length: 6) |> int.parse,
      )

      #(Microsecond(micro), string.drop_start(str, 6))
    }
    "z" -> {
      // Offsets can be 1, 3, 5, or 6 characters long. Try parsing from
      // largest to smallest because a small pattern may incorrectly match
      // a subset of a larger value.
      use _ <- result.try_recover(
        string.slice(str, at_index: 0, length: 6)
        |> fn(offset) {
          use re <- result.try(
            regexp.from_string("[-+]\\d\\d:\\d\\d") |> result.replace_error(Nil),
          )

          case regexp.check(re, offset) {
            True -> Ok(offset)
            False -> Error(Nil)
          }
        }
        |> result.map(fn(offset) {
          #(OffsetStr(offset), string.drop_start(str, 6))
        }),
      )

      use _ <- result.try_recover(
        string.slice(str, at_index: 0, length: 5)
        |> fn(offset) {
          use re <- result.try(
            regexp.from_string("[-+]\\d\\d\\d\\d") |> result.replace_error(Nil),
          )

          case regexp.check(re, offset) {
            True -> Ok(offset)
            False -> Error(Nil)
          }
        }
        |> result.map(fn(offset) {
          #(OffsetStr(offset), string.drop_start(str, 5))
        }),
      )

      use _ <- result.try_recover(
        string.slice(str, at_index: 0, length: 3)
        |> fn(offset) {
          use re <- result.try(
            regexp.from_string("[-+]\\d\\d") |> result.replace_error(Nil),
          )

          case regexp.check(re, offset) {
            True -> Ok(offset)
            False -> Error(Nil)
          }
        }
        |> result.map(fn(offset) {
          #(OffsetStr(offset), string.drop_start(str, 3))
        }),
      )

      use _ <- result.try_recover(
        string.slice(str, at_index: 0, length: 1)
        |> fn(offset) {
          case offset == "Z" || offset == "z" {
            True -> Ok(offset)
            False -> Error(Nil)
          }
        }
        |> result.map(fn(offset) {
          #(OffsetStr(offset), string.drop_start(str, 1))
        }),
      )

      Error(Nil)
    }
    "Z" -> {
      Ok(#(
        OffsetStr(string.slice(str, at_index: 0, length: 6)),
        string.drop_start(str, 6),
      ))
    }
    "ZZ" -> {
      Ok(#(
        OffsetStr(string.slice(str, at_index: 0, length: 5)),
        string.drop_start(str, 5),
      ))
    }
    passthrough -> {
      let fmt_length = string.length(passthrough)
      let str_slice = string.slice(str, at_index: 0, length: fmt_length)

      case str_slice == passthrough {
        True -> Ok(#(Passthrough, string.drop_start(str, fmt_length)))
        False -> Error(Nil)
      }
    }
  }
  |> result.map_error(fn(_) { "Unable to parse directive " <> fmt })
}

fn consume_one_or_two_digits(str, constructor) {
  case string.slice(str, at_index: 0, length: 2) |> int.parse {
    Ok(val) -> Ok(#(constructor(val), string.drop_start(str, 2)))
    Error(_) ->
      case string.slice(str, at_index: 0, length: 1) |> int.parse {
        Ok(val) -> Ok(#(constructor(val), string.drop_start(str, 1)))
        Error(_) -> Error(Nil)
      }
  }
}

fn consume_two_digits(str, constructor) {
  use val <- result.map(string.slice(str, at_index: 0, length: 2) |> int.parse)

  #(constructor(val), string.drop_start(str, 2))
}

@internal
pub fn find_date(in parts) {
  use year <- result.try(
    list.find_map(parts, fn(p) {
      case p {
        Year(y) -> Ok(y)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(tempo_error.DateInvalidFormat("Missing year")),
  )

  use month <- result.try(
    list.find_map(parts, fn(p) {
      case p {
        Month(m) -> Ok(m)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(tempo_error.DateInvalidFormat("Missing month")),
  )

  use day <- result.try(
    list.find_map(parts, fn(p) {
      case p {
        Day(d) -> Ok(d)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(tempo_error.DateInvalidFormat("Missing day")),
  )

  new_date(year, month, day)
  |> result.map_error(tempo_error.DateOutOfBounds("Out of bounds", _))
}

@internal
pub fn find_time(in parts) {
  use hour <- result.try({
    use _ <- result.try_recover(
      list.find_map(parts, fn(p) {
        case p {
          Hour(h) -> Ok(h)
          _ -> Error(Nil)
        }
      }),
    )

    use twelve_hour <- result.try(
      list.find_map(parts, fn(p) {
        case p {
          TwelveHour(o) -> Ok(o)
          _ -> Error(Nil)
        }
      })
      |> result.replace_error(tempo_error.TimeInvalidFormat("Missing hour")),
    )

    let am_period =
      list.find_map(parts, fn(p) {
        case p {
          AMPeriod -> Ok(Nil)
          _ -> Error(Nil)
        }
      })

    let pm_period =
      list.find_map(parts, fn(p) {
        case p {
          PMPeriod -> Ok(Nil)
          _ -> Error(Nil)
        }
      })

    case am_period, pm_period {
      Ok(Nil), Error(Nil) ->
        adjust_12_hour_to_24_hour(twelve_hour, am: True) |> Ok
      Error(Nil), Ok(Nil) ->
        adjust_12_hour_to_24_hour(twelve_hour, am: False) |> Ok

      _, _ ->
        Error(tempo_error.TimeInvalidFormat("Missing period in 12 hour time"))
    }
  })

  use minute <- result.try(
    list.find_map(parts, fn(p) {
      case p {
        Minute(m) -> Ok(m)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(tempo_error.TimeInvalidFormat("Missing minute")),
  )

  let second =
    list.find_map(parts, fn(p) {
      case p {
        Second(s) -> Ok(s)
        _ -> Error(Nil)
      }
    })
    |> result.unwrap(0)

  let millisecond =
    list.find_map(parts, fn(p) {
      case p {
        Millisecond(n) -> Ok(n)
        _ -> Error(Nil)
      }
    })

  let microsecond =
    list.find_map(parts, fn(p) {
      case p {
        Microsecond(n) -> Ok(n)
        _ -> Error(Nil)
      }
    })

  case microsecond, millisecond {
    Ok(micro), _ -> new_time_micro(hour, minute, second, micro)
    _, Ok(milli) -> new_time_milli(hour, minute, second, milli)
    _, _ -> new_time(hour, minute, second)
  }
  |> result.map_error(tempo_error.TimeOutOfBounds("Out of bounds", _))
}

@internal
pub fn find_offset(in parts) {
  use offset_str <- result.try(
    list.find_map(parts, fn(p) {
      case p {
        OffsetStr(o) -> Ok(o)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(tempo_error.OffsetInvalidFormat("Missing offset")),
  )

  offset_from_string(offset_str)
}

fn result_guard(when_error e, return v, or run) {
  case e {
    Error(_) -> v
    Ok(ok) -> run(ok)
  }
}

// -------------------------------------------------------------------------- //
//                              FFI Logic                                     //
// -------------------------------------------------------------------------- //

@external(erlang, "tempo_ffi", "now")
@external(javascript, "./tempo_ffi.mjs", "now")
@internal
pub fn now_utc_ffi() -> Int

@external(erlang, "tempo_ffi", "now_monotonic")
@external(javascript, "./tempo_ffi.mjs", "now_monotonic")
@internal
pub fn now_monotonic_ffi() -> Int

@external(erlang, "tempo_ffi", "now_unique")
@external(javascript, "./tempo_ffi.mjs", "now_unique")
@internal
pub fn now_unique_ffi() -> Int

@internal
pub fn offset_local_micro() -> Int {
  offset_local_minutes() * 60_000_000
}

@external(erlang, "tempo_ffi", "local_offset")
@external(javascript, "../tempo_ffi.mjs", "local_offset")
@internal
pub fn offset_local_minutes() -> Int

@external(erlang, "tempo_ffi", "current_year")
@external(javascript, "./tempo_ffi.mjs", "current_year")
fn current_year() -> Int
