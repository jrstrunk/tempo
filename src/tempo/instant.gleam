//// The `Instant` type is the most complete representation of system time. It is
//// a monotonic type that represents a unique point in time on the host system.
//// It is the only way to get the current time on the host system as a value, 
//// and means very little on other systems. Try to keep `Instant` values as
//// this type as long as possible in your programs. It can be safely used for 
//// timing tasks, sorting times, and recording times.
//// 
//// If you would like to send this value outside of Gleam, it will have 
//// to be converted to a `DateTime` value first.
//// 
//// ## Timing Tasks
//// 
//// ```gleam
//// import tempo/instant
//// 
//// pub fn main() {
////   let monotonic_timer = instant.now()
////   // Do long task ...
////   instant.since(monotonic_timer)
////   // -> duration.minutes(42)
//// 
////   instant.format_since(monotonic_timer)
////   // -> "42 minutes"
//// }
//// ```
//// 
//// ## Sorting Times
//// 
//// ```gleam
//// import tempo/instant
//// 
//// pub fn main() {
////   let completed_async_tasks = // ...
//// 
////   let task_by_completion_time = 
////     list.sort(
////       completed_async_tasks,
////       fn(a, b) { instant.compare(a.completion_time, b.completion_time) },
////     )
//// }
//// ```
//// 
//// ## Recording Times
////
//// ```gleam
//// import tempo/instant
//// 
//// pub type Record {
////   Record(name: String, created_time: instant.Instant)
//// }
//// 
//// pub fn new_record(name) {
////   Record(name: name, created_time: instant.now())
//// }
//// 
//// pub fn render_record_created_time(record: Record) {
////   instant.format(record.created_time, tempo.ISO8601Milli)
//// }
//// ```

import gleam/order
import gleam/time/duration
import gleam/time/timestamp
import tempo
import tempo/datetime

/// The current instant on the host system.
pub fn now() {
  tempo.now()
}

/// Gets the duration between the current system time and the provided instant.
/// 
/// ## Example
/// 
/// ```gleam
/// let monotonic_timer = instant.now()
/// // Do long task ...
/// instant.since(monotonic_timer)
/// // -> duration.minutes(42)
pub fn since(start start: tempo.Instant) -> duration.Duration {
  tempo.instant_since(start)
}

/// Formats the duration between the current system time and the provided 
/// instant.
/// 
/// ## Example
/// 
/// ```gleam
/// let monotonic_timer = instant.now()
/// // Do long task ...
/// instant.format_since(monotonic_timer)
/// // -> "42 minutes"
pub fn format_since(start start: tempo.Instant) -> String {
  tempo.instant_since_formatted(start)
}

/// Converts an instant to a UTC datetime value. Do not use this with 
/// `datetime.difference` to time tasks!
/// 
/// ## Example
/// 
/// ```gleam
/// instant.now()
/// |> instant.as_utc_datetime
/// // -> datetime.literal("2024-12-26T16:32:34Z")
/// ```
pub fn as_utc_datetime(instant: tempo.Instant) -> tempo.DateTime {
  tempo.instant_as_utc_datetime(instant)
}

/// Converts an instant to a local datetime value. Do not use this with 
/// `datetime.difference` to time tasks!
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.now()
/// |> instant._as_local_datetime
/// // -> datetime.literal("2024-12-26T12:32:34-04:00")
/// ```
pub fn as_local_datetime(instant: tempo.Instant) -> tempo.DateTime {
  tempo.instant_as_local_datetime(instant)
}

@internal
pub fn as_unix_seconds(instant: tempo.Instant) -> Int {
  tempo.instant_as_unix_seconds(instant)
}

@internal
pub fn as_unix_milli(instant: tempo.Instant) -> Int {
  tempo.instant_as_unix_milli(instant)
}

pub fn as_timestamp(instant: tempo.Instant) -> timestamp.Timestamp {
  let seconds = tempo.instant_as_unix_micro(instant) / 1_000_000
  let nanoseconds = { tempo.instant_as_unix_micro(instant) % 1_000_000 } * 1000

  timestamp.from_unix_seconds_and_nanoseconds(seconds, nanoseconds)
}

/// Converts an instant to a UTC date value.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.now()
/// |> instant.as_utc_date
/// // -> date.literal("2024-12-27")
/// ```
pub fn as_utc_date(instant: tempo.Instant) -> tempo.Date {
  tempo.instant_as_utc_date(instant)
}

/// Converts an instant to a local date value.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.now()
/// |> instant.as_local_date
/// // -> date.literal("2024-12-26")
/// ```
pub fn as_local_date(instant: tempo.Instant) -> tempo.Date {
  tempo.instant_as_local_date(instant)
}

/// Converts an instant to a UTC time value.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.now()
/// |> instant.as_utc_time
/// // -> time.literal("16:32:34")
/// ```
pub fn as_utc_time(instant: tempo.Instant) -> tempo.Time {
  tempo.instant_as_utc_time(instant)
}

/// Converts an instant to a local time value.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.now()
/// |> instant.as_local_time
/// // -> time.literal("12:32:34")
/// ```
pub fn as_local_time(instant: tempo.Instant) -> tempo.Time {
  tempo.instant_as_local_time(instant)
}

/// Formats an instant as a UTC datetime value.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.now()
/// |> instant.format_utc(tempo.ISO8601Milli)
/// // -> "2024-12-26T16:32:34.254Z"
/// ```
pub fn format_utc(
  instant: tempo.Instant,
  in format: tempo.DateTimeFormat,
) -> String {
  tempo.instant_as_utc_datetime(instant) |> datetime.format(in: format)
}

/// Formats an instant as a local datetime value.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.now()
/// |> instant.format_local(tempo.ISO8601Micro)
/// // -> "2024-12-26T12:32:34.534223-04:00"
/// ```
pub fn format_local(
  instant: tempo.Instant,
  in format: tempo.DateTimeFormat,
) -> String {
  tempo.instant_as_local_datetime(instant) |> datetime.format(in: format)
}

/// Gets the difference between two instants.
/// 
/// ## Example
/// 
/// ```gleam
/// let start = tempo.now()
/// let end = tempo.now()
/// 
/// instant.difference(from: start, to: end)
/// // -> duration.microseconds(1)
/// ```
pub fn difference(
  from a: tempo.Instant,
  to b: tempo.Instant,
) -> duration.Duration {
  tempo.instant_difference(from: a, to: b)
}

/// Compares two instants.
/// 
/// ## Example
/// 
/// ```gleam
/// let start = tempo.now()
/// let end = tempo.now()
/// 
/// instant.compare(start, end)
/// // -> order.Lt
/// ```
pub fn compare(a: tempo.Instant, b: tempo.Instant) -> order.Order {
  tempo.instant_compare(a, b)
}

/// Checks if the first instant is earlier than the second instant.
/// 
/// ## Example
/// 
/// ```gleam
/// let start = tempo.now()
/// let end = tempo.now()
/// 
/// instant.is_earlier(start, than: end)
/// // -> True
/// ```
pub fn is_earlier(a: tempo.Instant, than b: tempo.Instant) -> Bool {
  tempo.instant_is_earlier(a, than: b)
}

/// Checks if the first instant is earlier or equal to the second instant.
/// 
/// ## Example
/// 
/// ```gleam
/// let start = tempo.now()
/// let end = tempo.now()
/// 
/// instant.is_earlier_or_equal(start, to: end)
/// // -> True
/// ```
pub fn is_earlier_or_equal(a: tempo.Instant, to b: tempo.Instant) -> Bool {
  tempo.instant_is_earlier_or_equal(a, to: b)
}

/// Checks if the first instant is equal to the second instant.
/// 
/// ## Example
/// 
/// ```gleam
/// let start = tempo.now()
/// let end = tempo.now()
/// 
/// instant.is_equal(start, to: end)
/// // -> False
/// ```
pub fn is_equal(a: tempo.Instant, to b: tempo.Instant) -> Bool {
  tempo.instant_is_equal(a, to: b)
}

/// Checks if the first instant is later than the second instant.
/// 
/// ## Example
/// 
/// ```gleam
/// let start = tempo.now()
/// let end = tempo.now()
/// 
/// instant.is_later(start, than: end)
/// // -> False
/// ```
pub fn is_later(a: tempo.Instant, than b: tempo.Instant) -> Bool {
  tempo.instant_is_later(a, than: b)
}

/// Checks if the first instant is later or equal to the second instant.
/// 
/// ## Example
/// 
/// ```gleam
/// let start = tempo.now()
/// let end = tempo.now()
/// 
/// instant.is_later_or_equal(start, to: end)
/// // -> False
/// ```
pub fn is_later_or_equal(a: tempo.Instant, to b: tempo.Instant) -> Bool {
  tempo.instant_is_later_or_equal(a, to: b)
}
