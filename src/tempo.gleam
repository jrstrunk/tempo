//// The main module of this package. Contains most package types and general
//// purpose functions.
//// Look in specific modules for more functionality!

import gleam/bit_array
import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/result
import gleam/string
import gleam/string_tree
import gleam/time/calendar
import gleam/time/duration
import gtempo/internal
import tempo/error as tempo_error

// This is a big file. The contents are generally ordered (and searchable) by:
// - Tempo now functions
// - Instant logic (functions starting with `_instant`)
// - DateTime logic (functions starting with `datetime_`)
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
// module is the sole entry point into the system time

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
pub fn now_adjusted(by duration: duration.Duration) -> DateTime {
  let new_ts = now().timestamp_utc_us + duration_get_microseconds(duration)

  DateTime(
    date_from_unix_micro(new_ts),
    time_from_unix_micro(new_ts),
    offset: utc,
  )
}

/// Formats the current UTC system time using the provided format.
///
/// ## Example
///
/// ```gleam
/// tempo.format_utc(tempo.ISO8601Seconds)
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
/// tempo.format_local(tempo.ISO8601Seconds)
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
pub fn instant_since(start start: Instant) -> duration.Duration {
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
pub fn instant_since_formatted(start start: Instant) -> String {
  instant_since(start:)
  |> duration_get_microseconds
  |> internal.format
}

/// Compares the current system time to the provided datetime value.
///
/// ## Example
///
/// ```gleam
/// tempo.compare(datetime.literal("2024-12-26T00:00:00Z"))
/// // -> order.Lt
pub fn compare(to datetime: DateTime) -> order.Order {
  datetime_compare(now() |> instant_as_utc_datetime, to: datetime)
}

/// Checks if the current system time is earlier than the provided datetime.
///
/// ## Example
///
/// ```gleam
/// tempo.is_earlier(than: datetime.literal("2024-12-26T00:00:00Z"))
/// // -> False
/// ```
pub fn is_earlier(than datetime: DateTime) -> Bool {
  datetime_is_earlier(now() |> instant_as_utc_datetime, than: datetime)
}

/// Checks if the current system time is earlier or equal to the provided
/// datetime.
///
/// ## Example
///
/// ```gleam
/// tempo.is_earlier_or_equal(to: datetime.literal("2024-12-26T00:00:00Z"))
/// // -> True
/// ```
pub fn is_earlier_or_equal(to datetime: DateTime) -> Bool {
  datetime_is_earlier_or_equal(now() |> instant_as_utc_datetime, to: datetime)
}

/// Checks if the current system time is equal to the provided datetime.
///
/// ## Example
///
/// ```gleam
/// tempo.is_equal(to: datetime.literal("2024-12-26T00:00:00Z"))
/// // -> False
pub fn is_equal(to datetime: DateTime) -> Bool {
  datetime_is_equal(now() |> instant_as_utc_datetime, to: datetime)
}

/// Checks if the current system time is later than the provided datetime.
///
/// ## Example
///
/// ```gleam
/// tempo.is_later(than: datetime.literal("2024-12-26T00:00:00Z"))
/// // -> True
/// ```
pub fn is_later(than datetime: DateTime) -> Bool {
  datetime_is_later(now() |> instant_as_utc_datetime, than: datetime)
}

/// Checks if the current system time is later or equal to the provided
/// datetime.
///
/// ## Example
///
/// ```gleam
/// tempo.is_later_or_equal(to: datetime.literal("2024-12-26T00:00:00Z"))
/// // -> True
/// ```
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

/// Checks if the current UTC system time equals the provided time.
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

/// Checks if the current local system time equals the provided time.
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
/// tempo.difference(from: datetime.literal("2024-10-26T00:00:00Z"))
/// |> duration.format
/// // -> "54 days, 13 hours, and 46 minutes"
/// ```
pub fn difference(from start: DateTime) -> duration.Duration {
  now() |> instant_as_utc_datetime |> datetime_difference(from: start)
}

/// Gets the time since the provided datetime relative to the current system
/// time. The same as `tempo.difference`, but a duration of 0 will be
/// returned instead if the datetime is in the future.
///
/// ## Example
///
/// ```gleam
/// tempo.since(datetime.literal("2024-10-26T00:00:00Z"))
/// |> duration.format
/// // -> "54 days, 13 hours, and 46 minutes"
/// ```
///
/// ```gleam
/// tempo.since(datetime.literal("9099-12-26T00:00:00Z"))
/// |> duration.format
/// // -> "none"
/// ```
pub fn since(start start: DateTime) -> duration.Duration {
  difference(start) |> duration_clamp_to_zero
}

/// Gets the time until the provided datetime relative to the current system
/// time. A duration of 0 will be returned if the datetime is in the past.
///
/// ## Example
///
/// ```gleam
/// tempo.until(datetime.literal("2024-10-26T00:00:00Z"))
/// |> duration.format
/// // -> "none"
/// ```
///
/// ```gleam
/// tempo.until(datetime.literal("2025-02-26T00:00:00Z"))
/// |> duration.format
/// // -> "54 days, 13 hours, and 46 minutes"
/// ```
pub fn until(end end: DateTime) -> duration.Duration {
  now()
  |> instant_as_utc_datetime
  |> datetime_difference(to: end)
  |> duration_clamp_to_zero
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
pub fn utc_time_difference_from(from start: Time) -> duration.Duration {
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
pub fn local_time_difference_from(from start: Time) -> duration.Duration {
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
pub fn utc_time_since(start start: Time) -> duration.Duration {
  utc_time_difference_from(from: start)
  |> duration_clamp_to_zero
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
pub fn local_time_since(start start: Time) -> duration.Duration {
  local_time_difference_from(from: start)
  |> duration_clamp_to_zero
}

/// Gets the time until the provided time relative to the current UTC system time.
/// A duration of 0 will be returned if the time is in the past.
///
/// ## Example
///
/// ```gleam
/// tempo.utc_time_until(time.literal("13:42:11"))
/// |> duration.format
/// // -> "none"
/// ```
@internal
pub fn utc_time_until(end end: Time) -> duration.Duration {
  now()
  |> instant_as_utc_time
  |> time_difference(to: end)
  |> duration_clamp_to_zero
}

/// Gets the time until the provided time relative to the current local system
/// time. A duration of 0 will be returned if the time is in the past.
///
/// ## Example
///
/// ```gleam
/// tempo.local_time_until(time.literal("13:42:11"))
/// |> duration.format
/// // -> "4 hours and 42 minutes"
/// ```
@internal
pub fn local_time_until(end end: Time) -> duration.Duration {
  now()
  |> instant_as_local_time
  |> time_difference(to: end)
  |> duration_clamp_to_zero
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

/// Sleeps the current process for the provided duration. If the duration is
/// less than a millisecond, the process will not sleep at all.
pub fn sleep(for duration: duration.Duration) {
  let sleep_ms = case duration_get_microseconds(duration) / 1000 {
    ms if ms > 0 -> ms
    _ -> 0
  }

  sleep_ffi(sleep_ms)
}

// -------------------------------------------------------------------------- //
//                             Instant Logic                                  //
// -------------------------------------------------------------------------- //

/// A monotonic type that represents a unique point in time on the host system.
/// It can be converted to all other date time types but cannot be serialized
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
pub fn instant_get_unique(instant: Instant) -> Int {
  instant.unique
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
pub fn instant_as_unix_seconds(instant: Instant) -> Int {
  instant.timestamp_utc_us / 1_000_000
}

@internal
pub fn instant_as_unix_milli(instant: Instant) -> Int {
  instant.timestamp_utc_us / 1000
}

@internal
pub fn instant_as_unix_micro(instant: Instant) -> Int {
  instant.timestamp_utc_us
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
  date_from_unix_micro(instant.timestamp_utc_us)
}

@internal
pub fn instant_as_local_date(instant: Instant) -> Date {
  date_from_unix_micro(instant.timestamp_utc_us + instant.offset_local_us)
}

@internal
pub fn instant_as_utc_time(instant: Instant) -> Time {
  time_from_unix_micro(instant.timestamp_utc_us)
}

@internal
pub fn instant_as_local_time(instant: Instant) -> Time {
  time_from_unix_micro(instant.timestamp_utc_us + instant.offset_local_us)
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
pub fn instant_difference(from a: Instant, to b: Instant) -> duration.Duration {
  duration_microseconds(b.monotonic_us - a.monotonic_us)
}

// -------------------------------------------------------------------------- //
//                            DateTime Logic                                  //
// -------------------------------------------------------------------------- //

/// A datetime value with a time zone offset associated with it. It has the
/// most amount of information about a point in time, and can be compared to
/// all other types in this package by getting its lesser parts.
pub type DateTime {
  DateTime(date: Date, time: Time, offset: Offset)
  LocalDateTime(date: Date, time: Time, offset: Offset, tz: TimeZoneProvider)
}

@internal
pub const unix_epoch = DateTime(Date(0), TimeOfDay(0), utc)

@internal
pub const unix_epoch_date = Date(0)

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
  |> datetime_add(offset_to_duration(offset))
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

@internal
pub fn datetime_to_unix_micro(datetime: DateTime) -> Int {
  let utc_dt = datetime |> datetime_apply_offset

  date_to_unix_micro(utc_dt.date) + { time_to_microseconds(utc_dt.time) }
}

@internal
pub fn datetime_format(
  datetime: DateTime,
  in format: DateTimeFormat,
) -> String {
  get_datetime_format_str(format)
  |> tokenise_format
  |> list.map(fn(token) {
    case token {
      Directive(directive) ->
        directive
        |> date_replace_format(datetime.date)
        |> time_replace_format(datetime.time)
        |> offset_replace_format(datetime.offset)

      Escaped(literal) -> literal
    }
  })
  |> string.concat
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
pub fn datetime_difference(
  from a: DateTime,
  to b: DateTime,
) -> duration.Duration {
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
    |> naive_datetime_subtract(offset_to_duration(datetime.offset))

  // Applying an offset does not change the absolute time value, so we need
  // to preserve the monotonic and unique values.
  NaiveDateTime(date: applied.date, time: applied.time)
}

@internal
pub fn datetime_drop_offset(datetime: DateTime) -> NaiveDateTime {
  NaiveDateTime(date: datetime.date, time: datetime.time)
}

@internal
pub fn datetime_add(
  datetime: DateTime,
  duration duration_to_add: duration.Duration,
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
  duration duration_to_subtract: duration.Duration,
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

/// A datetime value with no time zone or offset associated with it.
/// It cannot be compared to datetimes with a time zone offset accurately, but
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
) -> duration.Duration {
  date_days_apart(from: a.date, to: b.date)
  |> duration_days
  |> duration_increase(by: time_difference(from: a.time, to: b.time))
}

@internal
pub fn naive_datetime_add(
  datetime: NaiveDateTime,
  duration duration_to_add: duration.Duration,
) -> NaiveDateTime {
  // Positive date overflows are only handled in this function, while negative
  // date overflows are only handled in the subtract function -- so if the
  // duration is negative, we can just subtract the absolute value of it.
  use <- bool.lazy_guard(
    when: !duration_is_positive(duration_to_add),
    return: fn() {
      datetime |> naive_datetime_subtract(duration_absolute(duration_to_add))
    },
  )

  let days_to_add: Int = duration_as_days(duration_to_add)
  let time_to_add: duration.Duration =
    duration_decrease(duration_to_add, by: duration_days(days_to_add))

  let new_time_as_micro =
    datetime.time
    |> time_to_duration
    |> duration_increase(by: time_to_add)
    |> duration_as_microseconds

  // If the time to add crossed a day boundary, add an extra day to the
  // number of days to add and adjust the time to add.
  let #(new_time_as_micro, days_to_add): #(Int, Int) = case
    new_time_as_micro >= internal.day_microseconds
  {
    True -> #(new_time_as_micro - internal.day_microseconds, days_to_add + 1)
    False -> #(new_time_as_micro, days_to_add)
  }

  let time_to_add =
    duration_microseconds(
      new_time_as_micro - time_to_microseconds(datetime.time),
    )

  let new_date = datetime.date |> date_add(days: days_to_add)
  let new_time = datetime.time |> time_add(duration: time_to_add)

  NaiveDateTime(date: new_date, time: new_time)
}

@internal
pub fn naive_datetime_subtract(
  datetime: NaiveDateTime,
  duration duration_to_subtract: duration.Duration,
) -> NaiveDateTime {
  // Negative date overflows are only handled in this function, while positive
  // date overflows are only handled in the add function -- so if the
  // duration is negative, we can just add the absolute value of it.
  use <- bool.lazy_guard(
    when: !duration_is_positive(duration_to_subtract),
    return: fn() {
      datetime |> naive_datetime_add(duration_absolute(duration_to_subtract))
    },
  )

  let days_to_sub: Int = duration_as_days(duration_to_subtract)
  let time_to_sub: duration.Duration =
    duration_decrease(duration_to_subtract, by: duration_days(days_to_sub))

  let new_time_as_micro =
    datetime.time
    |> time_to_duration
    |> duration_decrease(by: time_to_sub)
    |> duration_as_microseconds

  // If the time to subtract crossed a day boundary, add an extra day to the
  // number of days to subtract and adjust the time to subtract.
  let #(new_time_as_micro, days_to_sub) = case new_time_as_micro < 0 {
    True -> #(new_time_as_micro + internal.day_microseconds, days_to_sub + 1)
    False -> #(new_time_as_micro, days_to_sub)
  }

  let time_to_sub =
    duration_microseconds(
      time_to_microseconds(datetime.time) - new_time_as_micro,
    )

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
pub fn new_offset(from duration: duration.Duration) -> Result(Offset, Nil) {
  duration_as_mintues(duration) |> Offset |> validate_offset
}

@internal
pub fn new_offset_unchecked(from duration: duration.Duration) -> Offset {
  duration_as_mintues(duration) |> Offset
}

@internal
pub fn offset_from_string(
  offset_str: String,
) -> Result(Offset, tempo_error.OffsetParseError) {
  use offset <- result.try(
    parse_offset_string(bit_array.from_string(offset_str))
    |> result.replace_error(tempo_error.OffsetInvalidFormat(offset_str)),
  )

  validate_offset(offset)
  |> result.replace_error(tempo_error.OffsetOutOfBounds(offset_str))
}

fn parse_offset_string(input: BitArray) -> Result(Offset, Nil) {
  use #(minutes, input) <- result.try(internal.take_offset_minutes(input))
  use Nil <- result.map(internal.accept_empty(input))

  Offset(minutes)
}

@internal
pub fn offset_to_string(offset: Offset) -> String {
  let is_negative = offset_get_minutes(offset) < 0

  let hours = case offset_get_minutes(offset) / 60 {
    h if h < 0 -> -h
    h -> h
  }

  let mins = case offset_get_minutes(offset) % 60 {
    m if m < 0 -> -m
    m -> m
  }

  case is_negative, hours, mins {
    _, 0, 0 -> "+00:00"

    True, 0, m -> "-00:" <> int.to_string(m) |> string.pad_start(2, with: "0")

    False, 0, m -> "+00:" <> int.to_string(m) |> string.pad_start(2, with: "0")

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
pub fn offset_to_duration(offset: Offset) -> duration.Duration {
  offset.minutes * 60_000_000 |> duration_microseconds
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
    "zz" ->
      case offset.minutes {
        0 -> "Z"
        _ -> offset |> offset_to_string
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
  Date(unix_days: Int)
}

@internal
pub fn date(unix_days unix_days) {
  Date(unix_days:)
}

@internal
pub fn date_get_unix_days(date: Date) {
  date.unix_days
}

@internal
pub fn date_to_calendar_date(date: Date) {
  date_calendar_from_unix_days(date.unix_days)
}

@internal
pub fn date_from_calendar_date(calendar_date: calendar.Date) {
  date_calendar_to_unix_days(calendar_date)
}

@internal
pub fn date_get_month_year(date: Date) {
  let calendar_date = date_to_calendar_date(date)
  MonthYear(calendar_date.month, calendar_date.year)
}

@internal
pub fn date_get_year(date: Date) {
  let rd = date_to_rata_die(date)

  let #(n400, r400) =
    // -- 400 * 365 + 97
    internal.div_with_remainder(rd, 146_097)

  let #(n100, r100) =
    // -- 100 * 365 + 24
    internal.div_with_remainder(r400, 36_524)

  let #(n4, r4) =
    // -- 4 * 365 + 1
    internal.div_with_remainder(r100, 1461)

  let #(n1, r1) = internal.div_with_remainder(r4, 365)

  let n = case r1 == 0 {
    True -> 0
    False -> 1
  }

  n400 * 400 + n100 * 100 + n4 * 4 + n1 + n
}

@internal
pub fn date_get_month(date: Date) {
  date_to_calendar_date(date).month
}

@internal
pub fn date_get_day(date: Date) {
  date_to_calendar_date(date).day
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
pub fn date_from_unix_seconds(unix_ts) {
  Date(unix_ts / 86_400)
}

@internal
pub fn date_from_unix_milli(unix_milli) {
  Date(unix_milli / 86_400_000)
}

@internal
pub fn date_from_unix_micro(unix_micro) {
  Date(unix_micro / internal.day_microseconds)
}

@internal
pub fn date_to_string(date: Date) -> String {
  let calendar_date = date_to_calendar_date(date)

  string_tree.from_strings([
    int.to_string(calendar_date.year),
    "-",
    month_to_int(calendar_date.month)
      |> int.to_string
      |> string.pad_start(2, with: "0"),
    "-",
    int.to_string(calendar_date.day) |> string.pad_start(2, with: "0"),
  ])
  |> string_tree.to_string
}

@internal
pub fn date_replace_format(content: String, date: Date) -> String {
  let calendar_date = date_to_calendar_date(date)

  case content {
    "YY" ->
      calendar_date.year
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
      |> string.slice(at_index: -2, length: 2)
    "YYYY" ->
      calendar_date.year
      |> int.to_string
      |> string.pad_start(with: "0", to: 4)
    "M" ->
      calendar_date.month
      |> month_to_int
      |> int.to_string
    "MM" ->
      calendar_date.month
      |> month_to_int
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "MMM" ->
      calendar_date.month
      |> month_to_short_string
    "MMMM" ->
      calendar_date.month
      |> month_to_long_string
    "D" ->
      calendar_date.day
      |> int.to_string
    "DD" ->
      calendar_date.day
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "d" ->
      date
      |> date_to_day_of_week_number_us_convention
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
  case date_to_day_of_week_number_us_convention(date) {
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
  case date_to_day_of_week_number_us_convention(date) {
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
pub fn date_to_day_of_week_number_us_convention(date: Date) -> Int {
  case int.modulo(date.unix_days + 4, 7) {
    Ok(val) -> val
    Error(Nil) -> panic as "Invalid int modulo operation"
  }
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
        True -> Ok(date_from_calendar_date(calendar.Date(year, month, day)))
        False ->
          Error(tempo_error.DateDayOutOfBounds(
            month_to_short_string(month) <> " " <> int.to_string(day),
          ))
      }
    False -> Error(tempo_error.DateYearOutOfBounds(int.to_string(year)))
  }
}

fn date_calendar_from_unix_days(unix_days) {
  case unix_days >= 0 {
    // This calculation is faster but only works for dates after the unix epoch
    True -> {
      let z = unix_days + 719_468
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

      calendar.Date(year: y, month: month, day: d)
    }

    // If the date is before unix time, then we will have to use another
    // method to get the calendar date. Here uses the rata die calculation.
    False -> {
      let rata_die = Date(unix_days) |> date_to_rata_die
      let ordinal_year = Date(unix_days) |> date_get_year
      let ordinal_date = rata_die - date_days_before_year(ordinal_year)

      do_calculate_rata_die(ordinal_year, calendar.January, ordinal_date)
    }
  }
}

fn do_calculate_rata_die(year: Int, month: calendar.Month, ordinal_day: Int) {
  let days_in_month = month_days_of(month, in: year)

  case month_to_int(month) < 12 && ordinal_day > days_in_month {
    True -> {
      do_calculate_rata_die(
        year,
        case month {
          calendar.January -> calendar.February
          calendar.February -> calendar.March
          calendar.March -> calendar.April
          calendar.April -> calendar.May
          calendar.May -> calendar.June
          calendar.June -> calendar.July
          calendar.July -> calendar.August
          calendar.August -> calendar.September
          calendar.September -> calendar.October
          calendar.October -> calendar.November
          _ -> calendar.December
        },
        ordinal_day - days_in_month,
      )
    }
    False -> {
      calendar.Date(year:, month:, day: ordinal_day)
    }
  }
}

@internal
pub fn date_calendar_from_unix_seconds(unix_ts: Int) {
  date_calendar_from_unix_days(unix_ts / 86_400)
}

@internal
pub fn date_calendar_to_unix_days(date: calendar.Date) {
  let year_days = date_days_before_year(date.year)

  let leap_days = case is_leap_year(date.year) {
    True -> 1
    False -> 0
  }

  let month_days = case date.month {
    calendar.January -> 0
    calendar.February -> 31
    calendar.March -> 59 + leap_days
    calendar.April -> 90 + leap_days
    calendar.May -> 120 + leap_days
    calendar.June -> 151 + leap_days
    calendar.July -> 181 + leap_days
    calendar.August -> 212 + leap_days
    calendar.September -> 243 + leap_days
    calendar.October -> 273 + leap_days
    calendar.November -> 304 + leap_days
    calendar.December -> 334 + leap_days
  }

  year_days + month_days + date.day |> date_from_rata_die
}

@internal
pub fn date_to_unix_seconds(date: Date) -> Int {
  date.unix_days * 86_400
}

@internal
pub fn date_to_unix_milli(date: Date) -> Int {
  date.unix_days * 86_400_000
}

@internal
pub fn date_to_unix_micro(date: Date) -> Int {
  date.unix_days * 86_400_000_000
}

const unix_epoch_in_rata_die = 719_163

pub fn date_to_rata_die(date: Date) -> Int {
  date.unix_days + unix_epoch_in_rata_die
}

pub fn date_from_rata_die(rata_die: Int) -> Date {
  Date(rata_die - unix_epoch_in_rata_die)
}

@internal
pub fn date_add(date: Date, days days: Int) -> Date {
  Date(date.unix_days + days)
}

@internal
pub fn date_subtract(date: Date, days days: Int) -> Date {
  Date(date.unix_days - days)
}

@internal
pub fn date_days_apart(from start_date: Date, to end_date: Date) {
  end_date.unix_days - start_date.unix_days
}

@internal
pub fn date_compare(a: Date, to b: Date) -> order.Order {
  int.compare(a.unix_days, b.unix_days)
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

fn date_days_before_year(year1: Int) -> Int {
  let year = year1 - 1
  let leap_years =
    internal.floor_div(year, 4)
    - internal.floor_div(year, 100)
    + internal.floor_div(year, 400)

  365 * year + leap_years
}

// -------------------------------------------------------------------------- //
//                              Month Logic                                   //
// -------------------------------------------------------------------------- //

@internal
pub fn month_from_int(month: Int) -> Result(calendar.Month, Nil) {
  case month {
    1 -> Ok(calendar.January)
    2 -> Ok(calendar.February)
    3 -> Ok(calendar.March)
    4 -> Ok(calendar.April)
    5 -> Ok(calendar.May)
    6 -> Ok(calendar.June)
    7 -> Ok(calendar.July)
    8 -> Ok(calendar.August)
    9 -> Ok(calendar.September)
    10 -> Ok(calendar.October)
    11 -> Ok(calendar.November)
    12 -> Ok(calendar.December)
    _ -> Error(Nil)
  }
}

@internal
pub fn month_from_short_string(month: String) -> Result(calendar.Month, Nil) {
  case month {
    "Jan" -> Ok(calendar.January)
    "Feb" -> Ok(calendar.February)
    "Mar" -> Ok(calendar.March)
    "Apr" -> Ok(calendar.April)
    "May" -> Ok(calendar.May)
    "Jun" -> Ok(calendar.June)
    "Jul" -> Ok(calendar.July)
    "Aug" -> Ok(calendar.August)
    "Sep" -> Ok(calendar.September)
    "Oct" -> Ok(calendar.October)
    "Nov" -> Ok(calendar.November)
    "Dec" -> Ok(calendar.December)
    _ -> Error(Nil)
  }
}

@internal
pub fn month_from_long_string(month: String) {
  case month {
    "January" -> Ok(calendar.January)
    "February" -> Ok(calendar.February)
    "March" -> Ok(calendar.March)
    "April" -> Ok(calendar.April)
    "May" -> Ok(calendar.May)
    "June" -> Ok(calendar.June)
    "July" -> Ok(calendar.July)
    "August" -> Ok(calendar.August)
    "September" -> Ok(calendar.September)
    "October" -> Ok(calendar.October)
    "November" -> Ok(calendar.November)
    "December" -> Ok(calendar.December)
    _ -> Error(Nil)
  }
}

@internal
pub fn month_to_int(month: calendar.Month) -> Int {
  case month {
    calendar.January -> 1
    calendar.February -> 2
    calendar.March -> 3
    calendar.April -> 4
    calendar.May -> 5
    calendar.June -> 6
    calendar.July -> 7
    calendar.August -> 8
    calendar.September -> 9
    calendar.October -> 10
    calendar.November -> 11
    calendar.December -> 12
  }
}

@internal
pub fn month_to_short_string(month: calendar.Month) -> String {
  case month {
    calendar.January -> "Jan"
    calendar.February -> "Feb"
    calendar.March -> "Mar"
    calendar.April -> "Apr"
    calendar.May -> "May"
    calendar.June -> "Jun"
    calendar.July -> "Jul"
    calendar.August -> "Aug"
    calendar.September -> "Sep"
    calendar.October -> "Oct"
    calendar.November -> "Nov"
    calendar.December -> "Dec"
  }
}

@internal
pub fn month_to_long_string(month: calendar.Month) -> String {
  case month {
    calendar.January -> "January"
    calendar.February -> "February"
    calendar.March -> "March"
    calendar.April -> "April"
    calendar.May -> "May"
    calendar.June -> "June"
    calendar.July -> "July"
    calendar.August -> "August"
    calendar.September -> "September"
    calendar.October -> "October"
    calendar.November -> "November"
    calendar.December -> "December"
  }
}

@internal
pub fn month_days_of(month: calendar.Month, in year: Int) -> Int {
  month_year_days_of(MonthYear(month, year))
}

// -------------------------------------------------------------------------- //
//                             Month Year Logic                               //
// -------------------------------------------------------------------------- //

/// A month in a specific year.
pub type MonthYear {
  MonthYear(month: calendar.Month, year: Int)
}

@internal
pub fn month_year_to_int(month_year: MonthYear) -> Int {
  month_year.year * 100 + month_to_int(month_year.month)
}

@internal
pub fn month_year_prior(month_year: MonthYear) -> MonthYear {
  case month_year.month {
    calendar.January -> MonthYear(calendar.December, month_year.year - 1)
    calendar.February -> MonthYear(calendar.January, month_year.year)
    calendar.March -> MonthYear(calendar.February, month_year.year)
    calendar.April -> MonthYear(calendar.March, month_year.year)
    calendar.May -> MonthYear(calendar.April, month_year.year)
    calendar.June -> MonthYear(calendar.May, month_year.year)
    calendar.July -> MonthYear(calendar.June, month_year.year)
    calendar.August -> MonthYear(calendar.July, month_year.year)
    calendar.September -> MonthYear(calendar.August, month_year.year)
    calendar.October -> MonthYear(calendar.September, month_year.year)
    calendar.November -> MonthYear(calendar.October, month_year.year)
    calendar.December -> MonthYear(calendar.November, month_year.year)
  }
}

@internal
pub fn month_year_next(month_year: MonthYear) -> MonthYear {
  case month_year.month {
    calendar.January -> MonthYear(calendar.February, month_year.year)
    calendar.February -> MonthYear(calendar.March, month_year.year)
    calendar.March -> MonthYear(calendar.April, month_year.year)
    calendar.April -> MonthYear(calendar.May, month_year.year)
    calendar.May -> MonthYear(calendar.June, month_year.year)
    calendar.June -> MonthYear(calendar.July, month_year.year)
    calendar.July -> MonthYear(calendar.August, month_year.year)
    calendar.August -> MonthYear(calendar.September, month_year.year)
    calendar.September -> MonthYear(calendar.October, month_year.year)
    calendar.October -> MonthYear(calendar.November, month_year.year)
    calendar.November -> MonthYear(calendar.December, month_year.year)
    calendar.December -> MonthYear(calendar.January, month_year.year + 1)
  }
}

@internal
pub fn month_year_days_of(my: MonthYear) -> Int {
  case my.month {
    calendar.January -> 31
    calendar.February ->
      case is_leap_year(my.year) {
        True -> 29
        False -> 28
      }
    calendar.March -> 31
    calendar.April -> 30
    calendar.May -> 31
    calendar.June -> 30
    calendar.July -> 31
    calendar.August -> 31
    calendar.September -> 30
    calendar.October -> 31
    calendar.November -> 30
    calendar.December -> 31
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
  // Represents the microseconds since the beginning of the day.
  TimeOfDay(microseconds: Int)
  // Represents the 24:00:00 time, which cannot be represented by microseconds
  // since the beginning of the day.
  LastInstantOfDay
  EndOfDayLeapSecond(microseconds: Int)
}

@internal
pub const time_start_of_day = TimeOfDay(0)

@internal
pub const time_end_of_day = LastInstantOfDay

/// Used only internally to construct a time value after the inputs have been
/// validated.
@internal
pub fn time(hour hour, minute minute, second second, micro microsecond) {
  case hour == 24 && minute == 0 && second == 0 && microsecond == 0 {
    True -> LastInstantOfDay
    False ->
      case hour == 23 && minute == 59 && second == 60 {
        True -> EndOfDayLeapSecond(microsecond)
        False ->
          TimeOfDay(
            { hour * internal.hour_microseconds }
            + { minute * internal.minute_microseconds }
            + { second * internal.second_microseconds }
            + microsecond,
          )
      }
  }
}

/// We really only want to normalise on the way out of the time type
/// representation (like displaying a time) to preserve correct comparibility.
fn time_normalise(time: Time) {
  case time {
    TimeOfDay(microseconds) if microseconds < 0 -> {
      TimeOfDay(
        internal.day_microseconds + { microseconds % internal.day_microseconds },
      )
    }
    TimeOfDay(microseconds) if microseconds >= internal.day_microseconds -> {
      TimeOfDay(microseconds % internal.day_microseconds)
    }
    _ -> time
  }
}

@internal
pub fn time_from_microseconds(microseconds) {
  TimeOfDay(microseconds)
}

@internal
pub fn time_get_hour(time: Time) {
  case time_normalise(time) {
    TimeOfDay(microseconds) -> microseconds / internal.hour_microseconds
    LastInstantOfDay -> 24
    EndOfDayLeapSecond(..) -> 23
  }
}

@internal
pub fn time_get_minute(time: Time) {
  case time_normalise(time) {
    TimeOfDay(microseconds) -> {
      let hour = microseconds / internal.hour_microseconds

      { microseconds - hour * internal.hour_microseconds }
      / internal.minute_microseconds
    }
    LastInstantOfDay -> 0
    EndOfDayLeapSecond(..) -> 59
  }
}

@internal
pub fn time_get_second(time: Time) {
  case time_normalise(time) {
    TimeOfDay(microseconds) -> {
      let hour = microseconds / internal.hour_microseconds

      let minute =
        { microseconds - hour * internal.hour_microseconds }
        / internal.minute_microseconds

      {
        microseconds
        - hour
        * internal.hour_microseconds
        - minute
        * internal.minute_microseconds
      }
      / internal.second_microseconds
    }
    LastInstantOfDay -> 0
    EndOfDayLeapSecond(..) -> 60
  }
}

@internal
pub fn time_get_micro(time: Time) {
  case time_normalise(time) {
    TimeOfDay(microseconds) -> {
      let hour = microseconds / internal.hour_microseconds

      let minute =
        { microseconds - hour * internal.hour_microseconds }
        / internal.minute_microseconds

      let second =
        {
          microseconds
          - hour
          * internal.hour_microseconds
          - minute
          * internal.minute_microseconds
        }
        / internal.second_microseconds

      microseconds
      - hour
      * internal.hour_microseconds
      - minute
      * internal.minute_microseconds
      - second
      * internal.second_microseconds
    }
    LastInstantOfDay -> 0
    EndOfDayLeapSecond(microsecond) -> microsecond
  }
}

@internal
pub fn new_time(
  hour: Int,
  minute: Int,
  second: Int,
) -> Result(Time, tempo_error.TimeOutOfBoundsError) {
  validate_time(hour, minute, second, 0)
}

@internal
pub fn new_time_milli(
  hour: Int,
  minute: Int,
  second: Int,
  millisecond: Int,
) -> Result(Time, tempo_error.TimeOutOfBoundsError) {
  validate_time(hour, minute, second, millisecond * 1000)
}

@internal
pub fn new_time_micro(
  hour: Int,
  minute: Int,
  second: Int,
  microsecond: Int,
) -> Result(Time, tempo_error.TimeOutOfBoundsError) {
  validate_time(hour, minute, second, microsecond)
}

@internal
pub fn validate_time(
  hour: Int,
  minute: Int,
  second: Int,
  microsecond: Int,
) -> Result(Time, tempo_error.TimeOutOfBoundsError) {
  case
    {
      hour >= 0
      && hour <= 23
      && minute >= 0
      && minute <= 59
      && second >= 0
      && second <= 59
    }
    // For end of day time https://en.wikipedia.org/wiki/ISO_8601
    || { hour == 24 && minute == 0 && second == 0 && microsecond == 0 }
    // For leap seconds https://en.wikipedia.org/wiki/Leap_second. Leap seconds
    // are not fully supported by this package, but can be parsed from ISO 8601
    // dates.
    || { hour == 23 && minute == 59 && second == 60 }
  {
    True ->
      case microsecond <= 999_999 {
        True -> Ok(time(hour, minute, second, microsecond))
        False ->
          Error(
            tempo_error.TimeMicroSecondOutOfBounds(time_parts_to_string(
              hour,
              minute,
              second,
              microsecond,
            )),
          )
      }
    False ->
      case hour, minute, second {
        _, _, s if s > 59 || s < 0 ->
          Error(
            tempo_error.TimeSecondOutOfBounds(time_parts_to_string(
              hour,
              minute,
              second,
              microsecond,
            )),
          )
        _, m, _ if m > 59 || m < 0 ->
          Error(
            tempo_error.TimeMinuteOutOfBounds(time_parts_to_string(
              hour,
              minute,
              second,
              microsecond,
            )),
          )
        _, _, _ ->
          Error(
            tempo_error.TimeHourOutOfBounds(time_parts_to_string(
              hour,
              minute,
              second,
              microsecond,
            )),
          )
      }
  }
}

fn time_parts_to_string(hour, minute, second, microsecond) {
  string_tree.from_strings([
    hour
      |> int.to_string
      |> string.pad_start(2, with: "0"),
    ":",
    minute
      |> int.to_string
      |> string.pad_start(2, with: "0"),
    ":",
    second
      |> int.to_string
      |> string.pad_start(2, with: "0"),
  ])
  |> string_tree.append(".")
  |> string_tree.append(
    microsecond
    |> int.to_string
    |> string.pad_start(6, with: "0"),
  )
  |> string_tree.to_string
}

@internal
pub fn time_to_string(time: Time) -> String {
  let #(hour, minute, second, microsecond) = time_to_parts(time)
  string_tree.from_strings([
    hour
      |> int.to_string
      |> string.pad_start(2, with: "0"),
    ":",
    minute
      |> int.to_string
      |> string.pad_start(2, with: "0"),
    ":",
    second
      |> int.to_string
      |> string.pad_start(2, with: "0"),
  ])
  |> string_tree.append(".")
  |> string_tree.append(
    microsecond
    |> int.to_string
    |> string.pad_start(6, with: "0"),
  )
  |> string_tree.to_string
}

@internal
pub fn time_to_calendar_time_of_day(time: Time) -> calendar.TimeOfDay {
  calendar.TimeOfDay(
    time_get_hour(time),
    time_get_minute(time),
    time_get_second(time),
    time_get_micro(time) * 1000,
  )
}

@internal
pub fn time_replace_format(content: String, time: Time) -> String {
  case content {
    "H" -> time_get_hour(time) |> int.to_string
    "HH" ->
      time_get_hour(time)
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "h" ->
      case time_get_hour(time) {
        hour if hour == 0 -> 12
        hour if hour > 12 -> hour - 12
        hour -> hour
      }
      |> int.to_string
    "hh" ->
      case time_get_hour(time) {
        hour if hour == 0 -> 12
        hour if hour > 12 -> hour - 12
        hour -> hour
      }
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "a" ->
      case time_get_hour(time) >= 12 {
        True -> "pm"
        False -> "am"
      }
    "A" ->
      case time_get_hour(time) >= 12 {
        True -> "PM"
        False -> "AM"
      }
    "m" -> time_get_minute(time) |> int.to_string
    "mm" ->
      time_get_minute(time)
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "s" -> time_get_second(time) |> int.to_string
    "ss" ->
      time_get_second(time)
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "SSS" ->
      { time_get_micro(time) / 1000 }
      |> int.to_string
      |> string.pad_start(with: "0", to: 3)
    "SSSS" ->
      { time_get_micro(time) }
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
pub fn time_difference(from a: Time, to b: Time) -> duration.Duration {
  time_to_microseconds(b) - time_to_microseconds(a) |> duration_microseconds
}

@internal
pub fn time_to_microseconds(time: Time) -> Int {
  case time_normalise(time) {
    TimeOfDay(microseconds) -> microseconds
    LastInstantOfDay -> internal.day_microseconds
    EndOfDayLeapSecond(microsecond) -> internal.day_microseconds + microsecond
  }
}

@internal
pub fn time_to_parts(time: Time) {
  case time_normalise(time) {
    TimeOfDay(microseconds) -> {
      let hour = microseconds / internal.hour_microseconds

      let minute =
        { microseconds - hour * internal.hour_microseconds }
        / internal.minute_microseconds

      let second =
        {
          microseconds
          - hour
          * internal.hour_microseconds
          - minute
          * internal.minute_microseconds
        }
        / internal.second_microseconds

      let microsecond =
        microseconds
        - hour
        * internal.hour_microseconds
        - minute
        * internal.minute_microseconds
        - second
        * internal.second_microseconds

      #(hour, minute, second, microsecond)
    }
    LastInstantOfDay -> #(24, 0, 0, 0)
    EndOfDayLeapSecond(microsecond) -> #(23, 59, 60, microsecond)
  }
}

@internal
pub fn time_from_unix_micro(unix_ts: Int) -> Time {
  // Subtract the microseconds that are responsible for the date.
  time_from_microseconds(unix_ts % internal.day_microseconds)
}

@internal
pub fn time_to_duration(time: Time) -> duration.Duration {
  time_to_microseconds(time) |> duration_microseconds
}

@internal
pub fn time_compare(a: Time, to b: Time) -> order.Order {
  int.compare(time_to_microseconds(a), time_to_microseconds(b))
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
pub fn time_add(a: Time, duration b: duration.Duration) -> Time {
  let b_microseconds = duration_get_microseconds(b)

  case b_microseconds == 0 {
    True -> a
    False -> {
      case a {
        EndOfDayLeapSecond(microsecond)
          if b_microseconds + microsecond < 1_000_000
        -> EndOfDayLeapSecond(microsecond + b_microseconds)
        EndOfDayLeapSecond(..) ->
          time_to_microseconds(a) + { b_microseconds - 1_000_000 }
          |> time_from_microseconds
          |> time_normalise
        _ ->
          time_to_microseconds(a) + b_microseconds
          |> time_from_microseconds
          |> time_normalise
      }
    }
  }
}

@internal
pub fn time_subtract(a: Time, duration b: duration.Duration) -> Time {
  case duration_get_microseconds(b) == 0 {
    True -> a
    False ->
      time_to_microseconds(a) - duration_get_microseconds(b)
      |> time_from_microseconds
      |> time_normalise
  }
}

// -------------------------------------------------------------------------- //
//                            Duration Logic                                  //
// -------------------------------------------------------------------------- //

@internal
pub fn duration_microseconds(microseconds microseconds) {
  duration.nanoseconds(microseconds * 1000)
}

@internal
pub fn duration_get_microseconds(duration: duration.Duration) -> Int {
  let #(seconds, nanoseconds) = duration.to_seconds_and_nanoseconds(duration)
  { seconds * 1_000_000 } + { nanoseconds / 1000 }
}

@internal
pub fn duration_seconds_and_nanoseconds(seconds: Int, nanoseconds: Int) {
  duration.seconds(seconds)
  |> duration.add(duration.nanoseconds(nanoseconds))
}

@internal
pub fn duration_as_mintues(duration: duration.Duration) -> Int {
  duration_get_microseconds(duration) |> internal.as_minutes
}

@internal
pub fn duration_minutes(minutes: Int) -> duration.Duration {
  minutes |> internal.minutes |> duration_microseconds
}

@internal
pub fn duration_days(days: Int) -> duration.Duration {
  days |> internal.imprecise_days |> duration_microseconds
}

@internal
pub fn duration_increase(
  a: duration.Duration,
  by b: duration.Duration,
) -> duration.Duration {
  duration.add(a, b)
}

@internal
pub fn duration_decrease(
  a: duration.Duration,
  by b: duration.Duration,
) -> duration.Duration {
  duration.add(a, duration_inverse(b))
}

@internal
pub fn duration_absolute(duration: duration.Duration) -> duration.Duration {
  let #(seconds, nanoseconds) = duration.to_seconds_and_nanoseconds(duration)
  case seconds >= 0 && nanoseconds >= 0 {
    True -> duration
    False -> {
      let seconds = case seconds < 0 {
        True -> -seconds
        False -> seconds
      }

      let nanoseconds = case nanoseconds < 0 {
        True -> -nanoseconds
        False -> nanoseconds
      }

      duration_seconds_and_nanoseconds(seconds, nanoseconds)
    }
  }
}

@internal
pub fn duration_inverse(dur: duration.Duration) -> duration.Duration {
  duration.difference(dur, duration.seconds(0))
}

@internal
pub fn duration_clamp_to_zero(dur: duration.Duration) -> duration.Duration {
  case duration_is_positive(dur) {
    True -> dur
    False -> duration.seconds(0)
  }
}

@internal
pub fn duration_is_positive(dur: duration.Duration) -> Bool {
  let #(seconds, nanoseconds) = duration.to_seconds_and_nanoseconds(dur)
  seconds >= 0 && nanoseconds >= 0
}

@internal
pub fn duration_as_days(duration: duration.Duration) -> Int {
  duration_get_microseconds(duration) |> internal.as_days_imprecise
}

@internal
pub fn duration_as_microseconds(duration: duration.Duration) -> Int {
  duration_get_microseconds(duration)
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
pub fn period_as_duration(period: Period) -> duration.Duration {
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
    DatePeriod(start, end) -> #(start, end, time_start_of_day, time_end_of_day)
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

  let start_date = start_date |> date_to_calendar_date

  do_period_comprising_months(
    [],
    MonthYear(start_date.month, start_date.year),
    end_date,
  )
  |> list.reverse
}

fn do_period_comprising_months(mys, my: MonthYear, end_date) {
  case
    date_from_calendar_date(calendar.Date(my.year, my.month, 1))
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
  ISO8601Seconds
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
/// Z (full offset from UTC in the format "+-00:00"), ZZ (full offset from UTC
/// with no ":"), z (short offset from UTC as "-04" or "Z" if UTC), zz (full
/// offset from UTC as "-04:00" or "Z" if UTC), A (AM/PM), a (am/pm), or
/// GMT (to parse "GMT" as a 0 offset from UTC).
pub type NaiveDateTimeFormat {
  NaiveISO8601Seconds
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
/// A (AM/PM), or a (am/pm).
pub type TimeFormat {
  ISO8601TimeSeconds
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
    ISO8601Seconds -> "YYYY-MM-DDTHH:mm:sszz"
    ISO8601Milli -> "YYYY-MM-DDTHH:mm:ss.SSSzz"
    ISO8601Micro -> "YYYY-MM-DDTHH:mm:ss.SSSSzz"
    HTTP -> "ddd, DD MMM YYYY HH:mm:ss GMT"
    DateFormat(ISO8601Date) -> "YYYY-MM-DD"
    TimeFormat(ISO8601TimeSeconds) -> "HH:mm:ss"
    TimeFormat(ISO8601TimeMilli) -> "HH:mm:ss.SSS"
    TimeFormat(ISO8601TimeMicro) -> "HH:mm:ss.SSSS"
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
    NaiveISO8601Seconds -> "YYYY-MM-DDTHH:mm:ss"
    NaiveISO8601Milli -> "YYYY-MM-DDTHH:mm:ss.SSS"
    NaiveISO8601Micro -> "YYYY-MM-DDTHH:mm:ss.SSSS"
    CustomNaive(format) -> format
    CustomNaiveLocalised(format, _locale) -> format
    NaiveDateFormat(ISO8601Date) -> "YYYY-MM-DD"
    NaiveTimeFormat(ISO8601TimeSeconds) -> "HH:mm:ss"
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
    ISO8601TimeSeconds -> "HH:mm:ss"
    ISO8601TimeMilli -> "HH:mm:ss.SSS"
    ISO8601TimeMicro -> "HH:mm:ss.SSSS"
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

/// A single piece of a format string.
@internal
pub type FormatToken {
  /// A formatting directive like `YYYY`, or, when the character is not part of
  /// any directive, the character itself.
  Directive(String)
  /// The contents of an escape sequence, `[like this]`, which is always taken
  /// literally.
  Escaped(String)
}

/// Splits a format string into the directives it is made of. Directives are
/// matched greedily and longest first, so `"YYYYY"` is the `YYYY` directive
/// followed by a lone `Y` character.
@internal
pub fn tokenise_format(format_str: String) -> List(FormatToken) {
  do_tokenise_format(bit_array.from_string(format_str), [])
}

fn do_tokenise_format(
  bytes: BitArray,
  acc: List(FormatToken),
) -> List(FormatToken) {
  case bytes {
    <<>> -> list.reverse(acc)

    <<"[", rest:bytes>> ->
      case take_escaped(rest) {
        Ok(#(escaped, rest)) ->
          do_tokenise_format(rest, [Escaped(escaped), ..acc])
        // Without a closing bracket there is no escape sequence, so the
        // bracket is just another character.
        Error(Nil) -> do_tokenise_format(rest, [Directive("["), ..acc])
      }

    <<"YYYY", rest:bytes>> ->
      do_tokenise_format(rest, [Directive("YYYY"), ..acc])
    <<"YYY", rest:bytes>> -> do_tokenise_format(rest, [Directive("YYY"), ..acc])
    <<"YY", rest:bytes>> -> do_tokenise_format(rest, [Directive("YY"), ..acc])
    <<"Y", rest:bytes>> -> do_tokenise_format(rest, [Directive("Y"), ..acc])

    // Checked before the month directives so that the "M" in "GMT" is not
    // mistaken for one.
    <<"GMT", rest:bytes>> -> do_tokenise_format(rest, [Directive("GMT"), ..acc])

    <<"MMMM", rest:bytes>> ->
      do_tokenise_format(rest, [Directive("MMMM"), ..acc])
    <<"MMM", rest:bytes>> -> do_tokenise_format(rest, [Directive("MMM"), ..acc])
    <<"MM", rest:bytes>> -> do_tokenise_format(rest, [Directive("MM"), ..acc])
    <<"M", rest:bytes>> -> do_tokenise_format(rest, [Directive("M"), ..acc])

    <<"DD", rest:bytes>> -> do_tokenise_format(rest, [Directive("DD"), ..acc])
    <<"D", rest:bytes>> -> do_tokenise_format(rest, [Directive("D"), ..acc])

    <<"dddd", rest:bytes>> ->
      do_tokenise_format(rest, [Directive("dddd"), ..acc])
    <<"ddd", rest:bytes>> -> do_tokenise_format(rest, [Directive("ddd"), ..acc])
    <<"dd", rest:bytes>> -> do_tokenise_format(rest, [Directive("dd"), ..acc])
    <<"d", rest:bytes>> -> do_tokenise_format(rest, [Directive("d"), ..acc])

    <<"HH", rest:bytes>> -> do_tokenise_format(rest, [Directive("HH"), ..acc])
    <<"H", rest:bytes>> -> do_tokenise_format(rest, [Directive("H"), ..acc])

    <<"hh", rest:bytes>> -> do_tokenise_format(rest, [Directive("hh"), ..acc])
    <<"h", rest:bytes>> -> do_tokenise_format(rest, [Directive("h"), ..acc])

    <<"mm", rest:bytes>> -> do_tokenise_format(rest, [Directive("mm"), ..acc])
    <<"m", rest:bytes>> -> do_tokenise_format(rest, [Directive("m"), ..acc])

    <<"ss", rest:bytes>> -> do_tokenise_format(rest, [Directive("ss"), ..acc])
    <<"s", rest:bytes>> -> do_tokenise_format(rest, [Directive("s"), ..acc])

    <<"SSSS", rest:bytes>> ->
      do_tokenise_format(rest, [Directive("SSSS"), ..acc])
    <<"SSS", rest:bytes>> -> do_tokenise_format(rest, [Directive("SSS"), ..acc])

    <<"ZZ", rest:bytes>> -> do_tokenise_format(rest, [Directive("ZZ"), ..acc])
    <<"Z", rest:bytes>> -> do_tokenise_format(rest, [Directive("Z"), ..acc])

    <<"zz", rest:bytes>> -> do_tokenise_format(rest, [Directive("zz"), ..acc])
    <<"z", rest:bytes>> -> do_tokenise_format(rest, [Directive("z"), ..acc])

    <<"a", rest:bytes>> -> do_tokenise_format(rest, [Directive("a"), ..acc])
    <<"A", rest:bytes>> -> do_tokenise_format(rest, [Directive("A"), ..acc])

    _ ->
      case internal.take_character(bytes) {
        Ok(#(character, rest)) ->
          do_tokenise_format(rest, [Directive(character), ..acc])
        // Not valid UTF-8, which a Gleam string can never be.
        Error(Nil) -> list.reverse(acc)
      }
  }
}

/// Takes the contents of an escape sequence, everything up to the `]` that
/// closes it. An empty escape sequence is not one.
fn take_escaped(bytes: BitArray) -> Result(#(String, BitArray), Nil) {
  use length <- result.try(escaped_length(bytes, 0))
  use #(escaped, rest) <- result.try(internal.take_string(bytes, length))
  use rest <- result.map(internal.skip(rest, 1))
  #(escaped, rest)
}

fn escaped_length(bytes: BitArray, length: Int) -> Result(Int, Nil) {
  case bytes {
    <<"]", _:bytes>> if length > 0 -> Ok(length)
    <<"]", _:bytes>> -> Error(Nil)
    <<_, rest:bytes>> -> escaped_length(rest, length + 1)
    _ -> Error(Nil)
  }
}

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
  let input = bit_array.from_string(str)

  // Ten or more digits in a row is much more likely to be a serial number
  // than it is to be a date.
  use <- bool.guard(when: internal.has_digit_run(in: input, of: 10), return: #(
    None,
    None,
    None,
  ))

  // Each value is cut out of the input as it is found so that the values
  // looked for after it cannot match the same characters again.
  let #(date, input) = scan_date(input)
  let #(offset, input) = scan_offset(input)
  let #(time, _) = scan_time(input)

  #(date, time, offset)
}

/// Looks for the leftmost run of characters that `matcher` accepts and that
/// `build` can make a real value out of, returning that value and the input
/// with those characters cut out of it.
///
/// Text that is shaped like a date or a time but does not describe one, such
/// as `2024 00:00`, is left in the input for a later pattern to make sense of.
fn scan_for(
  in input: BitArray,
  with matcher: fn(BitArray) -> Result(#(a, BitArray), Nil),
  build build: fn(a) -> Result(b, Nil),
) -> #(option.Option(b), BitArray) {
  case internal.scan(in: input, with: matcher) {
    Error(Nil) -> #(None, input)
    Ok(#(matched, rest)) ->
      case build(matched) {
        Ok(value) -> #(Some(value), rest)
        Error(Nil) -> #(None, input)
      }
  }
}

fn scan_date(input: BitArray) -> #(option.Option(Date), BitArray) {
  case scan_for(input, with: match_numeric_date, build: build_date) {
    #(Some(date), input) -> #(Some(date), input)
    #(None, input) ->
      scan_for(input, with: match_written_date, build: build_date)
  }
}

fn scan_offset(input: BitArray) -> #(option.Option(Offset), BitArray) {
  case scan_for(input, with: match_offset, build: build_offset) {
    #(Some(offset), input) -> #(Some(offset), input)
    #(None, input) -> scan_utc_designator(input)
  }
}

fn scan_time(input: BitArray) -> #(option.Option(Time), BitArray) {
  scan_for(input, with: match_time, build: build_time)
}

/// Matches a date written with the year first, like `2024-06-21`, `2024.6.21`,
/// or `20240621`.
fn match_numeric_date(
  input: BitArray,
) -> Result(#(#(Int, Int, Int), BitArray), Nil) {
  use #(year, input) <- result.try(internal.take_digits(input, count: 4))
  use month, input <- take_separated_number(input)
  use day, input <- take_separated_number(input)
  Ok(#(#(year, month, day), input))
}

/// Matches a date written with the month first, like `06/21/2024` or
/// `June 21st, 2024`.
fn match_written_date(
  input: BitArray,
) -> Result(#(#(Int, Int, Int), BitArray), Nil) {
  use month, input <- take_month(input)
  use day, input <- take_separated_number(input)
  let input = skip_ordinal_suffix(input)
  use separators <- internal.backtrack(over: [2, 1, 0])
  use input <- result.try(skip_date_separators(input, separators))
  use #(year, input) <- result.map(internal.take_digits(input, count: 4))
  #(#(year, month, day), input)
}

fn build_date(parts: #(Int, Int, Int)) -> Result(Date, Nil) {
  let #(year, month, day) = parts
  new_date(year, month, day) |> result.replace_error(Nil)
}

/// Matches a number of one or two digits, preceded by up to two of the
/// characters that dates are commonly separated by.
///
/// Both the separators and the digits are matched greedily, backtracking into
/// shorter matches when what comes after them does not fit, so that a date
/// like `2024-6-21` is read the same way a regular expression would read it.
fn take_separated_number(
  from input: BitArray,
  then continue: fn(Int, BitArray) -> Result(a, Nil),
) -> Result(a, Nil) {
  use separators <- internal.backtrack(over: [2, 1, 0])
  use input <- result.try(skip_date_separators(input, separators))
  use digits <- internal.backtrack(over: [2, 1])
  use #(number, input) <- result.try(internal.take_digits(input, count: digits))
  continue(number, input)
}

/// Matches a month written as a number, or written out in full or shortened,
/// in either title case or lower case.
fn take_month(
  from input: BitArray,
  then continue: fn(Int, BitArray) -> Result(a, Nil),
) -> Result(a, Nil) {
  use _ <- result.try_recover({
    use digits <- internal.backtrack(over: [2, 1])
    use #(month, input) <- result.try(internal.take_digits(input, count: digits))
    continue(month, input)
  })

  use #(month, input) <- result.try(take_month_name(input))
  continue(month, input)
}

fn take_month_name(input: BitArray) -> Result(#(Int, BitArray), Nil) {
  case input {
    <<"January", input:bytes>> | <<"january", input:bytes>> -> Ok(#(1, input))
    <<"Jan", input:bytes>> | <<"jan", input:bytes>> -> Ok(#(1, input))
    <<"February", input:bytes>> | <<"february", input:bytes>> -> Ok(#(2, input))
    <<"Feb", input:bytes>> | <<"feb", input:bytes>> -> Ok(#(2, input))
    <<"March", input:bytes>> | <<"march", input:bytes>> -> Ok(#(3, input))
    <<"Mar", input:bytes>> | <<"mar", input:bytes>> -> Ok(#(3, input))
    <<"April", input:bytes>> | <<"april", input:bytes>> -> Ok(#(4, input))
    <<"Apr", input:bytes>> | <<"apr", input:bytes>> -> Ok(#(4, input))
    <<"May", input:bytes>> | <<"may", input:bytes>> -> Ok(#(5, input))
    <<"June", input:bytes>> | <<"june", input:bytes>> -> Ok(#(6, input))
    <<"Jun", input:bytes>> | <<"jun", input:bytes>> -> Ok(#(6, input))
    <<"July", input:bytes>> | <<"july", input:bytes>> -> Ok(#(7, input))
    <<"Jul", input:bytes>> | <<"jul", input:bytes>> -> Ok(#(7, input))
    <<"August", input:bytes>> | <<"august", input:bytes>> -> Ok(#(8, input))
    <<"Aug", input:bytes>> | <<"aug", input:bytes>> -> Ok(#(8, input))
    <<"September", input:bytes>> | <<"september", input:bytes>> ->
      Ok(#(9, input))
    <<"Sep", input:bytes>> | <<"sep", input:bytes>> -> Ok(#(9, input))
    <<"October", input:bytes>> | <<"october", input:bytes>> -> Ok(#(10, input))
    <<"Oct", input:bytes>> | <<"oct", input:bytes>> -> Ok(#(10, input))
    <<"November", input:bytes>> | <<"november", input:bytes>> ->
      Ok(#(11, input))
    <<"Nov", input:bytes>> | <<"nov", input:bytes>> -> Ok(#(11, input))
    <<"December", input:bytes>> | <<"december", input:bytes>> ->
      Ok(#(12, input))
    <<"Dec", input:bytes>> | <<"dec", input:bytes>> -> Ok(#(12, input))
    _ -> Error(Nil)
  }
}

fn skip_date_separators(input: BitArray, count: Int) -> Result(BitArray, Nil) {
  case count <= 0 {
    True -> Ok(input)
    False ->
      case input {
        <<"-", input:bytes>>
        | <<"_", input:bytes>>
        | <<"/", input:bytes>>
        | <<".", input:bytes>>
        | <<",", input:bytes>>
        | <<" ", input:bytes>>
        | <<"\t", input:bytes>>
        | <<"\n", input:bytes>>
        | <<"\r", input:bytes>> -> skip_date_separators(input, count - 1)
        _ -> Error(Nil)
      }
  }
}

/// Skips the `st` of `21st` and its friends, which say nothing the day did
/// not already say.
fn skip_ordinal_suffix(input: BitArray) -> BitArray {
  case input {
    <<"st", input:bytes>>
    | <<"nd", input:bytes>>
    | <<"rd", input:bytes>>
    | <<"th", input:bytes>> -> input
    input -> input
  }
}

/// Matches an offset from UTC like `-04:00`, `+0530`, or `-05`, returning how
/// many minutes it is.
fn match_offset(input: BitArray) -> Result(#(Int, BitArray), Nil) {
  use #(is_negative, input) <- result.try(take_offset_direction(input))
  use #(hours, input) <- result.try(internal.take_digits(input, count: 2))
  let input = skip_colon(input)
  let #(minutes, _, input) = internal.take_digits_up_to(input, limit: 2)

  let minutes = hours * 60 + minutes

  Ok(#(
    case is_negative {
      True -> -minutes
      False -> minutes
    },
    input,
  ))
}

fn build_offset(minutes: Int) -> Result(Offset, Nil) {
  new_offset(duration_minutes(minutes))
}

fn take_offset_direction(input: BitArray) -> Result(#(Bool, BitArray), Nil) {
  case input {
    <<"-", input:bytes>> -> Ok(#(True, input))
    <<"+", input:bytes>> -> Ok(#(False, input))
    _ -> Error(Nil)
  }
}

fn skip_colon(input: BitArray) -> BitArray {
  case input {
    <<":", input:bytes>> -> input
    input -> input
  }
}

/// Finds a `Z` standing on its own, which means UTC. A `Z` with a letter on
/// either side of it is part of a word, not an offset.
fn scan_utc_designator(input: BitArray) -> #(option.Option(Offset), BitArray) {
  case find_utc_designator(input, at: 0, after_letter: False) {
    Error(Nil) -> #(None, input)
    Ok(at) -> {
      let size = bit_array.byte_size(input)
      let assert Ok(before) = bit_array.slice(input, 0, at)
      let assert Ok(after) = bit_array.slice(input, at + 1, size - at - 1)
      #(Some(utc), <<before:bits, after:bits>>)
    }
  }
}

fn find_utc_designator(
  input: BitArray,
  at at: Int,
  after_letter after_letter: Bool,
) -> Result(Int, Nil) {
  case input {
    <<byte, rest:bytes>> -> {
      let is_designator = case after_letter, byte, rest {
        True, _, _ -> False
        False, 0x5A, <<next, _:bytes>> | False, 0x7A, <<next, _:bytes>> ->
          !internal.is_letter(next)
        False, 0x5A, _ | False, 0x7A, _ -> True
        False, _, _ -> False
      }

      case is_designator {
        True -> Ok(at)
        False -> find_utc_designator(rest, at + 1, internal.is_letter(byte))
      }
    }
    _ -> Error(Nil)
  }
}

/// The parts of a time as they were found in the input, before anything has
/// checked that they describe a real time.
type MatchedTime {
  MatchedTime(
    hour: Int,
    minute: Int,
    second: option.Option(Int),
    /// The digits after the second and how many of them there were, which is
    /// what says whether they are milliseconds, microseconds, or nanoseconds.
    fraction: option.Option(#(Int, Int)),
    /// `Some(True)` for AM and `Some(False)` for PM.
    am: option.Option(Bool),
  )
}

/// Matches a time like `13:42:11.314`, `1:42 PM`, or `134211`. Everything
/// after the minute is optional.
fn match_time(input: BitArray) -> Result(#(MatchedTime, BitArray), Nil) {
  use hour, input <- take_clock_number(input)
  use separators <- internal.backtrack(over: [1, 0])
  use input <- result.try(skip_time_separators(input, separators))
  use minute, input <- take_clock_number(input)

  let input = skip_time_separators(input, 1) |> result.unwrap(input)
  let #(second, second_digits, input) =
    internal.take_digits_up_to(input, limit: 2)
  let input = skip_decimal_point(input)
  let #(fraction, fraction_digits, input) =
    internal.take_digits_up_to(input, limit: 9)
  let input = skip_whitespace(input)
  let #(am, input) = take_period(input)

  Ok(#(
    MatchedTime(
      hour:,
      minute:,
      second: case second_digits {
        0 -> None
        _ -> Some(second)
      },
      fraction: case fraction_digits {
        0 -> None
        _ -> Some(#(fraction, fraction_digits))
      },
      am:,
    ),
    input,
  ))
}

fn build_time(matched: MatchedTime) -> Result(Time, Nil) {
  let MatchedTime(hour:, minute:, second:, fraction:, am:) = matched

  let hour = case am {
    Some(am) -> adjust_12_hour_to_24_hour(hour, am:)
    None -> hour
  }

  // A fraction is only a fraction when there is a second for it to be a
  // fraction of, and how many digits it has is what says whether it is
  // milliseconds, microseconds, or nanoseconds.
  use #(second, microsecond) <- result.try(case second, fraction {
    None, _ -> Ok(#(0, 0))
    Some(second), None -> Ok(#(second, 0))
    Some(second), Some(#(milli, 3)) -> Ok(#(second, milli * 1000))
    Some(second), Some(#(micro, 6)) -> Ok(#(second, micro))
    Some(second), Some(#(nano, 9)) -> Ok(#(second, nano / 1000))
    // Any other number of digits is not a precision that can be represented.
    Some(_), Some(_) -> Error(Nil)
  })

  new_time_micro(hour, minute, second, microsecond)
  |> result.replace_error(Nil)
}

/// Matches an hour or a minute, which may be written with or without a
/// leading zero.
fn take_clock_number(
  from input: BitArray,
  then continue: fn(Int, BitArray) -> Result(a, Nil),
) -> Result(a, Nil) {
  use digits <- internal.backtrack(over: [2, 1])
  use #(number, input) <- result.try(internal.take_digits(input, count: digits))
  continue(number, input)
}

fn skip_time_separators(input: BitArray, count: Int) -> Result(BitArray, Nil) {
  case count <= 0 {
    True -> Ok(input)
    False ->
      case input {
        <<":", input:bytes>>
        | <<"_", input:bytes>>
        | <<".", input:bytes>>
        | <<" ", input:bytes>>
        | <<"\t", input:bytes>>
        | <<"\n", input:bytes>>
        | <<"\r", input:bytes>> -> skip_time_separators(input, count - 1)
        _ -> Error(Nil)
      }
  }
}

fn skip_decimal_point(input: BitArray) -> BitArray {
  case input {
    <<".", input:bytes>> -> input
    input -> input
  }
}

fn skip_whitespace(input: BitArray) -> BitArray {
  case input {
    <<" ", input:bytes>>
    | <<"\t", input:bytes>>
    | <<"\n", input:bytes>>
    | <<"\r", input:bytes>> -> skip_whitespace(input)
    input -> input
  }
}

fn take_period(input: BitArray) -> #(option.Option(Bool), BitArray) {
  case input {
    <<"AM", input:bytes>> | <<"am", input:bytes>> -> #(Some(True), input)
    <<"PM", input:bytes>> | <<"pm", input:bytes>> -> #(Some(False), input)
    input -> #(None, input)
  }
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
  do_consume_format(tokenise_format(fmt), bit_array.from_string(str), [])
}

fn do_consume_format(
  tokens: List(FormatToken),
  input: BitArray,
  consumed: List(DatetimePart),
) -> Result(List(DatetimePart), String) {
  case tokens {
    [] -> Ok(consumed)

    [Directive(directive), ..tokens] ->
      case consume_part(directive, from: input) {
        Ok(#(part, input)) ->
          do_consume_format(tokens, input, [part, ..consumed])
        Error(error) -> Error(error)
      }

    // An escape sequence consumes nothing, but the input still has to match it.
    [Escaped(literal), ..tokens] ->
      case consume_literal(literal, from: input) {
        Ok(input) -> do_consume_format(tokens, input, [Passthrough, ..consumed])
        Error(Nil) ->
          Error(
            "Input does not match expected escape sequence \""
            <> literal
            <> "\"",
          )
      }
  }
}

/// Consumes the given literal text from the front of the input.
fn consume_literal(
  literal: String,
  from input: BitArray,
) -> Result(BitArray, Nil) {
  let literal = bit_array.from_string(literal)
  let length = bit_array.byte_size(literal)

  case bit_array.slice(input, 0, length) == Ok(literal) {
    True -> internal.skip(input, length)
    False -> Error(Nil)
  }
}

fn consume_part(
  directive: String,
  from input: BitArray,
) -> Result(#(DatetimePart, BitArray), String) {
  case directive {
    "YY" -> {
      use #(year, input) <- result.map(internal.take_digits(input, count: 2))

      // A two digit year is taken to be in the hundred years leading up to
      // today, so "99" is 1999 rather than 2099.
      let current_year = current_year()
      let current_century = { current_year / 100 } * 100

      case year > current_year % 100 {
        True -> #(Year(current_century - 100 + year), input)
        False -> #(Year(current_century + year), input)
      }
    }
    "YYYY" -> {
      use #(year, input) <- result.map(internal.take_digits(input, count: 4))
      #(Year(year), input)
    }

    "M" -> consume_one_or_two_digits(input, into: Month)
    "MM" -> consume_two_digits(input, into: Month)
    "MMM" ->
      case input {
        <<"Jan", input:bytes>> -> Ok(#(Month(1), input))
        <<"Feb", input:bytes>> -> Ok(#(Month(2), input))
        <<"Mar", input:bytes>> -> Ok(#(Month(3), input))
        <<"Apr", input:bytes>> -> Ok(#(Month(4), input))
        <<"May", input:bytes>> -> Ok(#(Month(5), input))
        <<"Jun", input:bytes>> -> Ok(#(Month(6), input))
        <<"Jul", input:bytes>> -> Ok(#(Month(7), input))
        <<"Aug", input:bytes>> -> Ok(#(Month(8), input))
        <<"Sep", input:bytes>> -> Ok(#(Month(9), input))
        <<"Oct", input:bytes>> -> Ok(#(Month(10), input))
        <<"Nov", input:bytes>> -> Ok(#(Month(11), input))
        <<"Dec", input:bytes>> -> Ok(#(Month(12), input))
        _ -> Error(Nil)
      }
    "MMMM" ->
      case input {
        <<"January", input:bytes>> -> Ok(#(Month(1), input))
        <<"February", input:bytes>> -> Ok(#(Month(2), input))
        <<"March", input:bytes>> -> Ok(#(Month(3), input))
        <<"April", input:bytes>> -> Ok(#(Month(4), input))
        <<"May", input:bytes>> -> Ok(#(Month(5), input))
        <<"June", input:bytes>> -> Ok(#(Month(6), input))
        <<"July", input:bytes>> -> Ok(#(Month(7), input))
        <<"August", input:bytes>> -> Ok(#(Month(8), input))
        <<"September", input:bytes>> -> Ok(#(Month(9), input))
        <<"October", input:bytes>> -> Ok(#(Month(10), input))
        <<"November", input:bytes>> -> Ok(#(Month(11), input))
        <<"December", input:bytes>> -> Ok(#(Month(12), input))
        _ -> Error(Nil)
      }

    "D" -> consume_one_or_two_digits(input, into: Day)
    "DD" -> consume_two_digits(input, into: Day)

    // The day of the week is implied by the rest of the date, so it only has
    // to be recognised, not remembered.
    "d" -> consume_any(["0", "1", "2", "3", "4", "5", "6"], from: input)
    "dd" -> consume_any(["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"], from: input)
    "ddd" ->
      consume_any(
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
        from: input,
      )
    "dddd" ->
      consume_any(
        [
          "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday",
          "Saturday",
        ],
        from: input,
      )

    "H" -> consume_one_or_two_digits(input, into: Hour)
    "HH" -> consume_two_digits(input, into: Hour)
    "h" -> consume_one_or_two_digits(input, into: TwelveHour)
    "hh" -> consume_two_digits(input, into: TwelveHour)

    "a" ->
      case input {
        <<"am", input:bytes>> -> Ok(#(AMPeriod, input))
        <<"pm", input:bytes>> -> Ok(#(PMPeriod, input))
        _ -> Error(Nil)
      }
    "A" ->
      case input {
        <<"AM", input:bytes>> -> Ok(#(AMPeriod, input))
        <<"PM", input:bytes>> -> Ok(#(PMPeriod, input))
        _ -> Error(Nil)
      }

    "m" -> consume_one_or_two_digits(input, into: Minute)
    "mm" -> consume_two_digits(input, into: Minute)
    "s" -> consume_one_or_two_digits(input, into: Second)
    "ss" -> consume_two_digits(input, into: Second)

    "SSS" -> {
      use #(milli, input) <- result.map(internal.take_digits(input, count: 3))
      #(Millisecond(milli), input)
    }
    "SSSS" -> {
      use #(micro, input) <- result.map(internal.take_digits(input, count: 6))
      #(Microsecond(micro), input)
    }

    // Offsets can be 1, 3, 5, or 6 characters long. Try parsing from largest
    // to smallest because a small pattern may incorrectly match a subset of a
    // larger value.
    "z" -> {
      use #(offset, input) <- result.map(
        internal.backtrack(
          over: [
            take_hour_colon_minute_offset,
            take_hour_minute_offset,
            take_hour_offset,
            take_utc_designator,
          ],
          with: internal.take_matched(input, _),
        ),
      )
      #(OffsetStr(offset), input)
    }
    "zz" ->
      case input {
        <<"Z">> -> Ok(#(OffsetStr("Z"), <<>>))
        <<"z">> -> Ok(#(OffsetStr("z"), <<>>))
        _ -> Ok(consume_offset_text(input, length: 6))
      }
    "Z" -> Ok(consume_offset_text(input, length: 6))
    "ZZ" -> Ok(consume_offset_text(input, length: 5))

    "GMT" ->
      case input {
        <<"GMT">> -> Ok(#(OffsetStr("Z"), <<>>))
        _ -> Error(Nil)
      }

    // Anything that is not a directive has to appear in the input as-is.
    literal ->
      consume_literal(literal, from: input)
      |> result.map(fn(input) { #(Passthrough, input) })
  }
  |> result.replace_error("Unable to parse directive " <> directive)
}

/// Consumes whichever of the given literals comes next in the input, keeping
/// none of it.
fn consume_any(
  literals: List(String),
  from input: BitArray,
) -> Result(#(DatetimePart, BitArray), Nil) {
  use input <- result.map(
    internal.backtrack(over: literals, with: consume_literal(_, from: input)),
  )
  #(Passthrough, input)
}

/// Takes an offset that has already been vouched for by its directive, so it
/// is handed on as-is for `offset_from_string` to make sense of.
fn consume_offset_text(
  input: BitArray,
  length length: Int,
) -> #(DatetimePart, BitArray) {
  let #(offset, input) = internal.take_string_up_to(input, length)
  #(OffsetStr(offset), input)
}

/// Matches `+hh:mm`.
fn take_hour_colon_minute_offset(input: BitArray) -> Result(BitArray, Nil) {
  use input <- result.try(take_offset_sign(input))
  use #(_, input) <- result.try(internal.take_digits(input, count: 2))
  use input <- result.try(internal.accept_byte(
    input,
    value: internal.byte_colon,
  ))
  use #(_, input) <- result.map(internal.take_digits(input, count: 2))
  input
}

/// Matches `+hhmm`.
fn take_hour_minute_offset(input: BitArray) -> Result(BitArray, Nil) {
  use input <- result.try(take_offset_sign(input))
  use #(_, input) <- result.map(internal.take_digits(input, count: 4))
  input
}

/// Matches `+hh`.
fn take_hour_offset(input: BitArray) -> Result(BitArray, Nil) {
  use input <- result.try(take_offset_sign(input))
  use #(_, input) <- result.map(internal.take_digits(input, count: 2))
  input
}

/// Matches the `Z` that stands for an offset of UTC.
fn take_utc_designator(input: BitArray) -> Result(BitArray, Nil) {
  case input {
    <<"Z", input:bytes>> | <<"z", input:bytes>> -> Ok(input)
    _ -> Error(Nil)
  }
}

fn take_offset_sign(input: BitArray) -> Result(BitArray, Nil) {
  case input {
    <<"+", input:bytes>> | <<"-", input:bytes>> -> Ok(input)
    _ -> Error(Nil)
  }
}

fn consume_one_or_two_digits(
  from input: BitArray,
  into constructor: fn(Int) -> DatetimePart,
) -> Result(#(DatetimePart, BitArray), Nil) {
  use #(value, input) <- result.map(internal.take_one_or_two_digits(input))
  #(constructor(value), input)
}

fn consume_two_digits(
  from input: BitArray,
  into constructor: fn(Int) -> DatetimePart,
) -> Result(#(DatetimePart, BitArray), Nil) {
  use #(value, input) <- result.map(internal.take_digits(input, count: 2))
  #(constructor(value), input)
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
@external(javascript, "./tempo_ffi.mjs", "local_offset")
@internal
pub fn offset_local_minutes() -> Int

@external(erlang, "tempo_ffi", "current_year")
@external(javascript, "./tempo_ffi.mjs", "current_year")
fn current_year() -> Int

@external(erlang, "tempo_ffi", "freeze_time")
@external(javascript, "./tempo_ffi.mjs", "freeze_time")
@internal
pub fn freeze_time_ffi(
  microseconds microseconds: Int,
  offset_minutes offset_minutes: Int,
) -> Nil

@external(erlang, "tempo_ffi", "unfreeze_time")
@external(javascript, "./tempo_ffi.mjs", "unfreeze_time")
@internal
pub fn unfreeze_time_ffi() -> Nil

@external(erlang, "tempo_ffi", "set_reference_time")
@external(javascript, "./tempo_ffi.mjs", "set_reference_time")
@internal
pub fn set_reference_time_ffi(
  microseconds microseconds: Int,
  offset_minutes offset_minutes: Int,
  speedup speedup: Float,
) -> Nil

@external(erlang, "tempo_ffi", "unset_reference_time")
@external(javascript, "./tempo_ffi.mjs", "unset_reference_time")
@internal
pub fn unset_reference_time_ffi() -> Nil

@external(erlang, "tempo_ffi", "sleep")
@external(javascript, "./tempo_ffi.mjs", "sleep")
@internal
pub fn sleep_ffi(milliseconds milliseconds: Int) -> Nil

@external(erlang, "tempo_ffi", "set_sleep_warp")
@external(javascript, "./tempo_ffi.mjs", "set_sleep_warp")
@internal
pub fn set_sleep_warp_ffi(do_warp: Bool) -> Nil

@external(erlang, "tempo_ffi", "add_warp_time")
@external(javascript, "./tempo_ffi.mjs", "add_warp_time")
@internal
pub fn add_warp_time_ffi(microseconds: Int) -> Nil

@external(erlang, "tempo_ffi", "reset_warp_time")
@external(javascript, "./tempo_ffi.mjs", "reset_warp_time")
@internal
pub fn reset_warp_time_ffi() -> Nil
