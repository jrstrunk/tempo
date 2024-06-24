import gleam/bool
import gleam/order
import gleam/result
import gleam/string
import tempo
import tempo/date
import tempo/duration
import gtempo/internal as unit
import tempo/offset
import tempo/time

/// Creates a new naive datetime from a date and time value.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.new(
///   date.literal("2024-06-21"), 
///   time.literal("23:04:00.009"),
/// )
/// // -> naive_datetime.literal("2024-06-21T23:04:00.009")
/// ```
pub fn new(date: tempo.Date, time: tempo.Time) -> tempo.NaiveDateTime {
  tempo.NaiveDateTime(date, time)
}

/// Creates a new naive datetime value from a string literal, but will panic 
/// if the string is invalid.
/// 
/// Useful for declaring date literals that you know are valid within your  
/// program.
///
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:04:00.009")
/// |> naive_datetime.to_string
/// // -> "2024-06-21T23:04:00.009"
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:04:00.009-04:00")
/// // panic
/// ```
pub fn literal(naive_datetime: String) -> tempo.NaiveDateTime {
  case from_string(naive_datetime) {
    Ok(naive_datetime) -> naive_datetime
    Error(tempo.NaiveDateTimeInvalidFormat) ->
      panic as "Invalid naive datetime literal format"
    Error(tempo.DateOutOfBounds) ->
      panic as "Invalid date in naive datetime literal"
    Error(tempo.TimeOutOfBounds) ->
      panic as "Invalid time in naive datetime literal"
    Error(_) -> panic as "Invalid naive datetime literal"
  }
}

/// Gets the current local naive datetime of the host.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.now_local()
/// |> naive_datetime.to_string
/// // -> "2024-06-21T12:23:23.380956212"
/// ```
pub fn now_local() -> tempo.NaiveDateTime {
  now_utc()
  |> subtract(offset.to_duration(offset.local()))
}

/// Gets the current UTC naive datetime of the host.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.now_utc()
/// |> naive_datetime.to_string
/// // -> "2024-06-21T16:23:23.380413364"
/// ```
pub fn now_utc() -> tempo.NaiveDateTime {
  let now_ts_nano = tempo.now_utc()

  new(
    date.from_unix_utc(now_ts_nano / 1_000_000_000),
    time.from_unix_nano_utc(now_ts_nano),
  )
}

/// Parses a naive datetime string in the format `YYYY-MM-DDThh:mm:ss.s`,
/// `YYYY-MM-DD hh:mm:ss.s`, `YYYY-MM-DD`, `YYYY-M-D`, `YYYY/MM/DD`, 
/// `YYYY/M/D`, `YYYY.MM.DD`, `YYYY.M.D`, `YYYY_MM_DD`, `YYYY_M_D`, 
/// `YYYY MM DD`, `YYYY M D`, or `YYYYMMDD`.
/// 
/// ## Examples
/// ```gleam
/// naive_datetime.from_string("20240612")
/// // -> Ok(naive_datetime.literal("2024-06-12T00:00:00"))
/// ```
/// 
/// ```gleam
/// naive_datetime.from_string("2024-06-21 23:17:00")
/// // -> Ok(naive_datetime.literal("2024-06-21T23:17:00"))
/// ```
/// 
/// ```gleam
/// naive_datetime.from_string("24-06-12|23:17:00")
/// // -> Error(tempo.NaiveDateTimeInvalidFormat)
/// ```
pub fn from_string(datetime: String) -> Result(tempo.NaiveDateTime, tempo.Error) {
  let split_dt = case string.contains(datetime, "T") {
    True -> string.split(datetime, "T")
    False -> string.split(datetime, " ")
  }

  case split_dt {
    [date, time] -> {
      use date: tempo.Date <- result.try(date.from_string(date))
      use time: tempo.Time <- result.map(time.from_string(time))
      tempo.NaiveDateTime(date, time)
    }
    [date] -> {
      use date: tempo.Date <- result.map(date.from_string(date))
      tempo.NaiveDateTime(date, tempo.Time(0, 0, 0, 0))
      |> to_second_precision
    }
    _ -> Error(tempo.NaiveDateTimeInvalidFormat)
  }
}

/// Returns a string representation of a naive datetime value in the ISO 8601
/// format
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.to_string
/// // -> "2024-06-21T23:17:00"
/// ```
pub fn to_string(datetime: tempo.NaiveDateTime) -> String {
  datetime.date
  |> date.to_string
  <> "T"
  <> datetime.time
  |> time.to_string
}

/// Sets a naive datetime's offset to UTC, leaving the date and time unchanged
/// while returning a datetime value. 
/// Alias for `set_offset(naive_datetime, offset.utc)`.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.set_utc
/// // -> datetime.literal("2024-06-21T23:17:00Z")
/// ```
pub fn set_utc(datetime: tempo.NaiveDateTime) -> tempo.DateTime {
  set_offset(datetime, offset.utc)
}

/// Gets the date of a naive datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.get_date
/// // -> date.literal("2024-06-21")
/// ```
pub fn get_date(datetime: tempo.NaiveDateTime) -> tempo.Date {
  datetime.date
}

/// Gets the time of a naive datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.get_time
/// // -> time.literal("23:17:00")
/// ```
pub fn get_time(datetime: tempo.NaiveDateTime) -> tempo.Time {
  datetime.time
}

/// Drops the time of a naive datetime, setting it to zero.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-13T23:17:00")
/// |> naive_datetime.drop_time
/// // -> datetime.literal("2024-06-13T00:00:00")
/// ```
pub fn drop_time(datetime: tempo.NaiveDateTime) -> tempo.NaiveDateTime {
  tempo.NaiveDateTime(datetime.date, tempo.Time(0, 0, 0, 0))
}

/// Sets a naive datetime's offset to the provided offset, leaving the date and
/// time unchanged while returning a datetime value. 
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.set_offset(offset.literal("+10:00"))
/// // -> datetime.literal("2024-06-21T23:17:00+10:00")
/// ```
pub fn set_offset(
  datetime: tempo.NaiveDateTime,
  offset: tempo.Offset,
) -> tempo.DateTime {
  tempo.DateTime(naive: datetime, offset: offset)
}

/// Sets a naive datetime's time value to a second precision. Drops any 
/// milliseconds from the underlying time value.
/// 
/// ## Example
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-13T13:42:11.195423")
/// |> naive_datetime.to_second_precision
/// |> naive_datetime.to_string
/// // -> "2024-06-13T13:42:11"
/// ```
pub fn to_second_precision(
  naive_datetime: tempo.NaiveDateTime,
) -> tempo.NaiveDateTime {
  new(naive_datetime.date, naive_datetime.time |> time.to_second_precision)
}

/// Sets a naive datetime's time value to a millisecond precision. Drops any 
/// microseconds from the underlying time value.
/// 
/// ## Example
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-13T13:42:11.195423")
/// |> naive_datetime.to_milli_precision
/// |> naive_datetime.to_string
/// // -> "2024-06-13T13:42:11.195"
/// ```
pub fn to_milli_precision(
  naive_datetime: tempo.NaiveDateTime,
) -> tempo.NaiveDateTime {
  new(naive_datetime.date, naive_datetime.time |> time.to_milli_precision)
}

/// Sets a naive datetime's time value to a microsecond precision. Drops any 
/// nanoseconds from the underlying time value.
/// 
/// ## Example
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-13T13:42:11.195423534")
/// |> naive_datetime.to_micro_precision
/// |> naive_datetime.to_string
/// // -> "2024-06-13T13:42:11.195423"
/// ```
pub fn to_micro_precision(
  naive_datetime: tempo.NaiveDateTime,
) -> tempo.NaiveDateTime {
  new(naive_datetime.date, naive_datetime.time |> time.to_micro_precision)
}

/// Sets a naive datetime's time value to a nanosecond precision. Leaves the
/// underlying time value unchanged.
/// 
/// ## Example
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-13T13:42:11.195")
/// |> naive_datetime.to_nano_precision
/// |> naive_datetime.to_string
/// // -> "2024-06-13T13:42:11.195000000"
/// ```
pub fn to_nano_precision(
  naive_datetime: tempo.NaiveDateTime,
) -> tempo.NaiveDateTime {
  new(naive_datetime.date, naive_datetime.time |> time.to_nano_precision)
}

/// Compares two naive datetimes.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.compare(to: naive_datetime.literal("2024-06-21T23:17:00"))
/// // -> order.Eq
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("2023-05-11T13:15:00")
/// |> naive_datetime.compare(to: naive_datetime.literal("2024-06-21T23:17:00"))
/// // -> order.Lt
/// ```
pub fn compare(a: tempo.NaiveDateTime, to b: tempo.NaiveDateTime) {
  case date.compare(a.date, b.date) {
    order.Eq -> time.compare(a.time, b.time)
    od -> od
  }
}

/// Checks if the first naive datetime is earlier than the second naive 
/// datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.is_earlier(
///   than: naive_datetime.literal("2024-06-21T23:17:00"),
/// )
/// // -> False
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("2013-06-12T23:17:00")
/// |> naive_datetime.is_earlier(
///   than: naive_datetime.literal("2024-06-12T23:17:00"),
/// )
/// // -> True
/// ```
pub fn is_earlier(a: tempo.NaiveDateTime, than b: tempo.NaiveDateTime) -> Bool {
  compare(a, b) == order.Lt
}

/// Checks if the first naive datetime is earlier or equal to the second naive 
/// datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-08-12T23:17:00")
/// |> naive_datetime.is_earlier_or_equal(
///   to: naive_datetime.literal("2024-06-12T00:00:00"),
/// )
/// // -> False
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.is_earlier_or_equal(
///   to: naive_datetime.literal("2024-06-21T23:17:00"),
/// )
/// // -> True
/// ```
pub fn is_earlier_or_equal(
  a: tempo.NaiveDateTime,
  to b: tempo.NaiveDateTime,
) -> Bool {
  compare(a, b) == order.Lt || compare(a, b) == order.Eq
}

/// Checks if the first naive datetime is equal to the second naive datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.is_equal(
///   to: naive_datetime.literal("2024-06-21T23:17:00"),
/// )
/// // -> True
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.is_equal(
///   to: naive_datetime.literal("2024-06-21T23:17:01"),
/// )
/// // -> False
/// ```
pub fn is_equal(a: tempo.NaiveDateTime, to b: tempo.NaiveDateTime) -> Bool {
  compare(a, b) == order.Eq
}

/// Checks if the first naive datetime is later than the second naive datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.is_later(
///   than: naive_datetime.literal("2024-06-21T23:17:00"),
/// )
/// // -> False
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.is_later(
///   than: naive_datetime.literal("2022-04-12T00:00:00"),
/// )
/// // -> True
/// ```
pub fn is_later(a: tempo.NaiveDateTime, than b: tempo.NaiveDateTime) -> Bool {
  compare(a, b) == order.Gt
}

/// Checks if the first naive datetime is later or equal to the second naive 
/// datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.is_later_or_equal(
///   to: naive_datetime.literal("2024-06-21T23:17:00"),
/// )
/// // -> True
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("2022-04-12T00:00:00")
/// |> naive_datetime.is_later_or_equal(
///   to: naive_datetime.literal("2024-06-21T23:17:00"),
/// )
/// // -> False
/// ```
pub fn is_later_or_equal(
  a: tempo.NaiveDateTime,
  to b: tempo.NaiveDateTime,
) -> Bool {
  compare(a, b) == order.Gt || compare(a, b) == order.Eq
}

/// Returns the difference between two naive datetimes as a period between them.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-12T23:17:00")
/// |> naive_datetime.difference(
///   from: naive_datetime.literal("2024-06-16T01:16:12"),
/// )
/// |> period.as_days
/// // -> 3
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-12T23:17:00")
/// |> naive_datetime.difference(
///   from: naive_datetime.literal("2024-06-16T01:18:12"),
/// )
/// |> period.format
/// // -> "3 days, 2 hours, and 1 minute"
/// ```
pub fn difference(
  from a: tempo.NaiveDateTime,
  to b: tempo.NaiveDateTime,
) -> tempo.Period {
  to_period(a, b)
}

/// Creates a period between two naive datetimes.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.to_period(
///   start: naive_datetime.literal("2024-06-12T23:17:00")
///   end: naive_datetime.literal("2024-06-16T01:16:12"),
/// )
/// |> period.as_days
/// // -> 3
/// ```
/// 
/// ```gleam
/// naive_datetime.to_period(
///   start: naive_datetime.literal("2024-06-12T23:17:00"),
///   end: naive_datetime.literal("2024-06-16T01:18:12"),
/// )
/// |> period.format
/// // -> "3 days, 2 hours, and 1 minute"
/// ```
pub fn to_period(
  start start: tempo.NaiveDateTime,
  end end: tempo.NaiveDateTime,
) -> tempo.Period {
  let #(start, end) = case start |> is_earlier_or_equal(to: end) {
    True -> #(start, end)
    False -> #(end, start)
  }

  tempo.Period(start, end)
}

/// Adds a duration to a naive datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.add(duration.minutes(3))
/// // -> naive_datetime.literal("2024-06-21T23:20:00")
/// ```
pub fn add(
  datetime: tempo.NaiveDateTime,
  duration duration_to_add: tempo.Duration,
) -> tempo.NaiveDateTime {
  // Positive date overflows are only handled in this function, while negative
  // date overflows are only handled in the subtract function -- so if the 
  // duration is negative, we can just subtract the absolute value of it.
  use <- bool.lazy_guard(when: duration_to_add.nanoseconds < 0, return: fn() {
    datetime |> subtract(duration.absolute(duration_to_add))
  })

  let days_to_add: Int = duration.as_days(duration_to_add)
  let time_to_add: tempo.Duration =
    duration.decrease(duration_to_add, by: duration.days(days_to_add))

  let new_time_as_ns =
    datetime.time
    |> time.to_duration
    |> duration.increase(by: time_to_add)
    |> duration.as_nanoseconds

  // If the time to add crossed a day boundary, add an extra day to the 
  // number of days to add and adjust the time to add.
  let #(new_time_as_ns, days_to_add): #(Int, Int) = case
    new_time_as_ns
    >= unit.imprecise_day_nanoseconds
  {
    True -> #(new_time_as_ns - unit.imprecise_day_nanoseconds, days_to_add + 1)
    False -> #(new_time_as_ns, days_to_add)
  }

  let time_to_add =
    duration.nanoseconds(new_time_as_ns - time.to_nanoseconds(datetime.time))

  let new_date = datetime.date |> date.add(days: days_to_add)
  let new_time = datetime.time |> time.add(duration: time_to_add)

  tempo.NaiveDateTime(new_date, new_time)
}

/// Subtracts a duration from a naive datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-12T23:17:00")
/// |> naive_datetime.subtract(duration.days(3))
/// // -> naive_datetime.literal("2024-06-09T23:17:00")
/// ```
pub fn subtract(
  datetime: tempo.NaiveDateTime,
  duration duration_to_subtract: tempo.Duration,
) -> tempo.NaiveDateTime {
  // Negative date overflows are only handled in this function, while positive
  // date overflows are only handled in the add function -- so if the 
  // duration is negative, we can just add the absolute value of it.
  use <- bool.lazy_guard(
    when: duration_to_subtract.nanoseconds < 0,
    return: fn() { datetime |> add(duration.absolute(duration_to_subtract)) },
  )

  let days_to_sub: Int = duration.as_days(duration_to_subtract)
  let time_to_sub: tempo.Duration =
    duration.decrease(duration_to_subtract, by: duration.days(days_to_sub))

  let new_time_as_ns =
    datetime.time
    |> time.to_duration
    |> duration.decrease(by: time_to_sub)
    |> duration.as_nanoseconds

  // If the time to subtract crossed a day boundary, add an extra day to the 
  // number of days to subtract and adjust the time to subtract.
  let #(new_time_as_ns, days_to_sub) = case new_time_as_ns < 0 {
    True -> #(new_time_as_ns + unit.imprecise_day_nanoseconds, days_to_sub + 1)
    False -> #(new_time_as_ns, days_to_sub)
  }

  let time_to_sub =
    duration.nanoseconds(time.to_nanoseconds(datetime.time) - new_time_as_ns)

  // Using the proper subtract functions here to modify the date and time
  // values instead of declaring a new date is important for perserving date 
  // correctness and time precision.
  let new_date = datetime.date |> date.subtract(days: days_to_sub)
  let new_time = datetime.time |> time.subtract(duration: time_to_sub)

  tempo.NaiveDateTime(new_date, new_time)
}

/// Gets the time left in the day.
/// 
/// Does **not** account for leap seconds like the rest of the package.
/// 
/// ## Examples
///
/// ```gleam
/// naive_datetime.literal("2015-06-30T23:59:03")
/// |> naive_datetime.time_left_in_day
/// // -> time.literal("00:00:57")
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-18T08:05:20")
/// |> naive_datetime.time_left_in_day
/// // -> time.literal("15:54:40")
/// ```
pub fn time_left_in_day(naive_datetime: tempo.NaiveDateTime) -> tempo.Time {
  naive_datetime.time |> time.left_in_day
}
