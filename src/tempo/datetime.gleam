import gleam/bool
import gleam/order
import gleam/result
import gleam/string
import tempo
import tempo/date
import tempo/naive_datetime
import tempo/offset
import tempo/time

/// Create a new datetime from a date, time, and offset.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.new(
///   date.literal("2024-06-13"), 
///   time.literal("23:04:00.009"),
///   offset.literal("+10:00"),
/// )
/// // -> datetime.literal("2024-06-13T23:04:00.009+10:00")
/// ```
pub fn new(
  date date: tempo.Date,
  time time: tempo.Time,
  offset offset: tempo.Offset,
) -> tempo.DateTime {
  tempo.DateTime(naive_datetime.new(date, time), offset: offset)
}

/// Create a new datetime value from a string literal, but will panic if
/// the string is invalid. Accepted formats are `YYYY-MM-DDThh:mm:ss.sTZD` or
/// `YYYYMMDDThhmmss.sTZD`
/// 
/// Useful for declaring datetime literals that you know are valid within your  
/// program.
///
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-13T23:04:00.009+10:00")
/// |> datetime.to_string
/// // -> "2024-06-13T23:04:00.009+10:00"
/// ```
pub fn literal(datetime: String) -> tempo.DateTime {
  case from_string(datetime) {
    Ok(datetime) -> datetime
    Error(tempo.DateTimeInvalidFormat) ->
      panic as "Invalid datetime literal format"
    Error(tempo.DateTimeOutOfBounds) ->
      panic as "Invalid datetime literal value"
    Error(_) -> panic as "Invalid datetime literal"
  }
}

/// Gets the current local datetime of the host.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.now()
/// |> datetime.to_string
/// // -> "2024-06-14T04:19:20.006809349-04:00"
/// ```
pub fn now_local() -> tempo.DateTime {
  // This should always be precise because it is the current time.
  case now_utc() |> to_local {
    tempo.Precise(datetime) -> datetime
    tempo.Imprecise(datetime) -> datetime
  }
}

/// Gets the current UTC datetime of the host.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.now_utc()
/// |> datetime.to_string
/// // -> "2024-06-14T08:19:20.006809349Z"
/// ```
pub fn now_utc() -> tempo.DateTime {
  let now_ts_nano = tempo.now_utc()

  new(
    date.from_unix_utc(now_ts_nano / 1_000_000_000),
    time.from_unix_nano_utc(now_ts_nano),
    offset.utc,
  )
}

/// Gets the current local datetime of the host as a string in milliseconds
/// precision. For easy reading by humans in text formats, like log 
/// statements, etc.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.now_text()
/// // -> "2024-06-14 04:19:20.349"
/// ```
pub fn now_text() -> String {
  now_local()
  |> drop_offset
  |> naive_datetime.to_milli_precision
  |> naive_datetime.to_string
  |> string.replace("T", " ")
}

/// Parses a datetime string in the format `YYYY-MM-DDThh:mm:ss.sTZD`,
/// `YYYYMMDDThhmmss.sTZD`, `YYYY-MM-DD`, `YYYY-M-D`, `YYYY/MM/DD`, 
/// `YYYY/M/D`, `YYYY.MM.DD`, `YYYY.M.D`, `YYYY_MM_DD`, `YYYY_M_D`, 
/// `YYYY MM DD`, `YYYY M D`, or `YYYYMMDD`.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.from_string("20240613T230400.009+00:00")
/// // -> datetime.literal("2024-06-13T23:04:00.009Z")
/// ```
pub fn from_string(datetime: String) -> Result(tempo.DateTime, tempo.Error) {
  case string.split(datetime, "T") {
    [date, time] -> {
      use date: tempo.Date <- result.try(date.from_string(date))

      use #(time, offset): #(String, String) <- result.try(
        split_time_and_offset(time),
      )

      use time: tempo.Time <- result.try(time.from_string(time))
      use offset: tempo.Offset <- result.map(offset.from_string(offset))

      new(date, time, offset)
    }

    [date] ->
      date.from_string(date)
      |> result.map(new(_, tempo.Time(0, 0, 0, 0), offset.utc))

    _ -> Error(tempo.DateTimeInvalidFormat)
  }
}

fn split_time_and_offset(
  time_with_offset: String,
) -> Result(#(String, String), tempo.Error) {
  case string.slice(time_with_offset, at_index: -1, length: 1) {
    "Z" -> #(string.drop_right(time_with_offset, 1), "Z") |> Ok
    "z" -> #(string.drop_right(time_with_offset, 1), "Z") |> Ok
    _ ->
      case string.split(time_with_offset, "-") {
        [time, offset] -> #(time, "-" <> offset) |> Ok
        _ ->
          case string.split(time_with_offset, "+") {
            [time, offset] -> #(time, "+" <> offset) |> Ok
            _ -> Error(tempo.DateTimeInvalidFormat)
          }
      }
  }
}

/// Returns a string representation of a datetime value in the ISO 8601
/// format.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.now_utc()
/// |> datetime.to_string
/// // -> "2024-06-21T05:22:22.009Z" 
/// ```
pub fn to_string(datetime: tempo.DateTime) -> String {
  datetime.naive |> naive_datetime.to_string
  <> case datetime.offset.minutes {
    0 -> "Z"
    _ -> datetime.offset |> offset.to_string
  }
}

/// Returns the UTC datetime of a unix timestamp.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.from_unix_utc(1_718_829_191)
/// // -> datetime.literal("2024-06-17T12:59:51Z")
/// ```
pub fn from_unix_utc(unix_ts: Int) -> tempo.DateTime {
  new(date.from_unix_utc(unix_ts), time.from_unix_utc(unix_ts), offset.utc)
}

/// Returns the UTC unix timestamp of a datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-17T12:59:51Z")
/// |> datetime.to_unix_utc
/// // -> 1_718_829_191
/// ```
pub fn to_unix_utc(datetime: tempo.DateTime) -> Int {
  let utc_dt = datetime |> apply_offset

  date.to_unix_utc(utc_dt.date)
  + { time.to_nanoseconds(utc_dt.time) / 1_000_000_000 }
}

/// Returns the UTC datetime of a unix timestamp in milliseconds.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.from_unix_milli_utc(1_718_629_314_334)
/// // -> datetime.literal("2024-06-17T13:01:54.334Z")
/// ```
pub fn from_unix_milli_utc(unix_ts: Int) -> tempo.DateTime {
  new(
    date.from_unix_milli_utc(unix_ts),
    time.from_unix_milli_utc(unix_ts),
    offset.utc,
  )
}

/// Returns the UTC unix timestamp in milliseconds of a datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-17T13:01:54.334Z")
/// |> datetime.to_unix_milli_utc
/// // -> 1_718_629_314_334
/// ```
pub fn to_unix_milli_utc(datetime: tempo.DateTime) -> Int {
  let utc_dt = datetime |> apply_offset

  date.to_unix_milli_utc(utc_dt.date)
  + { time.to_nanoseconds(utc_dt.time) / 1_000_000 }
}

/// Returns the UTC datetime of a unix timestamp in microseconds.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.from_unix_micro_utc(1_718_629_314_334_734)
/// // -> datetime.literal("2024-06-17T13:01:54.334734Z")
/// ```
pub fn from_unix_micro_utc(unix_ts: Int) -> tempo.DateTime {
  new(
    date.from_unix_micro_utc(unix_ts),
    time.from_unix_micro_utc(unix_ts),
    offset.utc,
  )
}

/// Returns the UTC unix timestamp in microseconds of a datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-17T13:01:54.334734Z")
/// |> datetime.to_unix_micro_utc
/// // -> 1_718_629_314_334_734
/// ```
pub fn to_unix_micro_utc(datetime: tempo.DateTime) -> Int {
  let utc_dt = datetime |> apply_offset

  date.to_unix_micro_utc(utc_dt.date)
  + { time.to_nanoseconds(utc_dt.time) / 1000 }
}

/// Gets the date of a datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-21T13:42:11.195Z")
/// |> datetime.get_date
/// // -> date.literal("2024-06-21")
/// ```
pub fn get_date(datetime: tempo.DateTime) -> tempo.Date {
  datetime.naive.date
}

/// Gets the time of a datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-21T13:42:11.195Z")
/// |> datetime.get_time
/// // -> time.literal("13:42:11.195")
/// ```
pub fn get_time(datetime: tempo.DateTime) -> tempo.Time {
  datetime.naive.time
}

/// Gets the offset of a datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-12T13:42:11.195-04:00")
/// |> datetime.get_offset
/// // -> offset.literal("+04:00")
/// ```
pub fn get_offset(datetime: tempo.DateTime) -> tempo.Offset {
  datetime.offset
}

/// Drops the time of a datetime, leaving the date and time values unchanged.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-13T13:42:11.195Z")
/// |> datetime.drop_offset
/// // -> naive_datetime.literal("2024-06-13T13:42:11")
/// ```
pub fn drop_offset(datetime: tempo.DateTime) -> tempo.NaiveDateTime {
  datetime.naive
}

/// Drops the time of a datetime, leaving the date value unchanged.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-18T13:42:11.195Z")
/// |> datetime.drop_time
/// // -> naive_datetime.literal("2024-06-18T00:00:00Z")
/// ```
pub fn drop_time(datetime: tempo.DateTime) -> tempo.DateTime {
  tempo.DateTime(
    naive_datetime.drop_time(datetime.naive),
    offset: datetime.offset,
  )
}

/// Applies the offset of a datetime to the date and time values, resulting
/// in a new naive datetime value that represents the original datetime in 
/// UTC time.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-21T05:36:11.195-04:00")
/// |> datetime.apply_offset
/// // -> naive_datetime.literal("2024-06-21T09:36:11.195")
/// ```
pub fn apply_offset(datetime: tempo.DateTime) -> tempo.NaiveDateTime {
  datetime
  |> add(offset.to_duration(datetime.offset))
  |> drop_offset
}

/// Converts a datetime to the equivalent UTC time.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-21T05:36:11.195-04:00")
/// |> datetime.to_utc
/// // -> datetime.literal("2024-06-21T09:36:11.195Z")
/// ```
pub fn to_utc(datetime: tempo.DateTime) -> tempo.DateTime {
  datetime
  |> add(offset.to_duration(datetime.offset))
  |> drop_offset
  |> naive_datetime.set_offset(offset.utc)
}

/// Converts a datetime to the equivalent time in an offset.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-21T05:36:11.195-04:00")
/// |> datetime.to_offset(offset.literal("+10:00"))
/// // -> datetime.literal("2024-06-21T19:36:11.195+10:00")
/// ```
pub fn to_offset(
  datetime: tempo.DateTime,
  offset: tempo.Offset,
) -> tempo.DateTime {
  datetime
  |> to_utc
  |> subtract(offset.to_duration(offset))
  |> drop_offset
  |> naive_datetime.set_offset(offset)
}

/// Converts a datetime to the equivalent local datetime. The return value
/// indicates if the conversion was precise or imprecise. Use mattern
/// matching to handle the two cases.
/// 
/// Conversion is based on the host's current offset. If the date of the
/// supplied datetime matches the date of the host, then we can apply the
/// current host's offset to get the local time safely, resulting in a precise
/// conversion. If the date does not match the host's, then we can not be 
/// sure the current offset is still applicable, and will perform an 
/// imprecise conversion. The imprecise conversion can be inaccurate to the
/// degree the local offset changes throughout the year. For example, in 
/// North America where Daylight Savings Time is observed with a one-hour
/// time shift, the imprecise conversion can be off by up to an hour depending
/// on the time of year.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-21T09:57:11.195Z")
/// |> datetime.to_local
/// // -> tempo.Precise(datetime.literal("2024-06-21T05:57:11.195-04:00"))
/// ```
/// 
/// ```gleam
/// datetime.literal("1998-08-23T09:57:11.195Z")
/// |> datetime.to_local
/// // -> tempo.Imprecise(datetime.literal("1998-08-23T05:57:11.195-04:00"))
/// ```
pub fn to_local(
  datetime: tempo.DateTime,
) -> tempo.UncertainConversion(tempo.DateTime) {
  use <- bool.lazy_guard(when: datetime.offset == offset.local(), return: fn() {
    tempo.Precise(datetime)
  })

  let local_dt = datetime |> to_offset(offset.local())

  case local_dt.naive.date == date.current_local() {
    True -> tempo.Precise(local_dt)
    False -> tempo.Imprecise(local_dt)
  }
}

/// Converts a datetime to the equivalent local time. The return value
/// indicates if the conversion was precise or imprecise. Use mattern
/// matching to handle the two cases.
/// 
/// Conversion is based on the host's current offset. If the date of the
/// supplied datetime matches the date of the host, then we can apply the
/// current host's offset to get the local time safely, resulting in a precise
/// conversion. If the date does not match the host's, then we can not be 
/// sure the current offset is still applicable, and will perform an 
/// imprecise conversion. The imprecise conversion can be inaccurate to the
/// degree the local offset changes throughout the year. For example, in 
/// North America where Daylight Savings Time is observed with a one-hour
/// time shift, the imprecise conversion can be off by up to an hour depending
/// on the time of year.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-21T09:57:11.195Z")
/// |> datetime.to_local_time
/// // -> tempo.Precise(time.literal("05:57:11.195"))
/// ```
/// 
/// ```gleam
/// datetime.literal("1998-08-23T09:57:11.195Z")
/// |> datetime.to_local_time
/// // -> tempo.Imprecise(time.literal("05:57:11.195"))
/// ```
pub fn to_local_time(
  datetime: tempo.DateTime,
) -> tempo.UncertainConversion(tempo.Time) {
  case to_local(datetime) {
    tempo.Precise(datetime) -> datetime.naive.time |> tempo.Precise
    tempo.Imprecise(datetime) -> datetime.naive.time |> tempo.Imprecise
  }
}

/// Converts a datetime to the equivalent local time. The return value
/// indicates if the conversion was precise or imprecise. Use mattern
/// matching to handle the two cases.
/// 
/// Conversion is based on the host's current offset. If the date of the
/// supplied datetime matches the date of the host, then we can apply the
/// current host's offset to get the local time safely, resulting in a precise
/// conversion. If the date does not match the host's, then we can not be 
/// sure the current offset is still applicable, and will perform an 
/// imprecise conversion. The imprecise conversion can be inaccurate to the
/// degree the local offset changes throughout the year. For example, in 
/// North America where Daylight Savings Time is observed with a one-hour
/// time shift, the imprecise conversion can be off by up to an hour depending
/// on the time of year.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-19T01:35:11.195Z")
/// |> datetime.to_local_date
/// // -> tempo.Precise(date.literal("2024-06-18"))
/// ```
/// 
/// ```gleam
/// datetime.literal("1998-08-23T01:57:11.195Z")
/// |> datetime.to_local_date
/// // -> tempo.Imprecise(date.literal("1998-08-22"))
/// ```
pub fn to_local_date(
  datetime: tempo.DateTime,
) -> tempo.UncertainConversion(tempo.Date) {
  case to_local(datetime) {
    tempo.Precise(datetime) -> datetime.naive.date |> tempo.Precise
    tempo.Imprecise(datetime) -> datetime.naive.date |> tempo.Imprecise
  }
}

/// Sets a datetime's time value to a second precision. Drops any milliseconds
/// from the underlying time value.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-13T13:42:11.195423Z")
/// |> datetime.to_second_precision
/// |> datetime.to_string
/// // -> "2024-06-13T13:42:11Z"
/// ```
pub fn to_second_precision(datetime: tempo.DateTime) -> tempo.DateTime {
  new(
    datetime.naive.date,
    datetime.naive.time |> time.to_second_precision,
    datetime.offset,
  )
}

/// Sets a datetime's time value to a millisecond precision. Drops any 
/// microseconds from the underlying time value.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-13T13:42:11.195423Z")
/// |> datetime.to_milli_precision
/// |> datetime.to_string
/// // -> "2024-06-13T13:42:11.195Z"
/// ```
pub fn to_milli_precision(datetime: tempo.DateTime) -> tempo.DateTime {
  new(
    datetime.naive.date,
    datetime.naive.time |> time.to_milli_precision,
    datetime.offset,
  )
}

/// Sets a datetime's time value to a microsecond precision. Drops any 
/// nanoseconds from the underlying time value.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-13T13:42:11.195423534Z")
/// |> datetime.to_micro_precision
/// |> datetime.to_string
/// // -> "2024-06-13T13:42:11.195423Z"
/// ```
pub fn to_micro_precision(datetime: tempo.DateTime) -> tempo.DateTime {
  new(
    datetime.naive.date,
    datetime.naive.time |> time.to_micro_precision,
    datetime.offset,
  )
}

/// Sets a datetime's time value to a nanosecond precision. Leaves the
/// underlying time value unchanged.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-13T13:42:11.195Z")
/// |> datetime.to_nano_precision
/// |> datetime.to_string
/// // -> "2024-06-13T13:42:11.195000000Z"
/// ```
pub fn to_nano_precision(datetime: tempo.DateTime) -> tempo.DateTime {
  new(
    datetime.naive.date,
    datetime.naive.time |> time.to_nano_precision,
    datetime.offset,
  )
}

/// Compares two datetimes.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-21T23:47:00+09:05")
/// |> datetime.compare(to: datetime.literal("2024-06-21T23:47:00+09:05"))
/// // -> order.Eq
/// ```
/// 
/// ```gleam
/// datetime.literal("2023-05-11T13:30:00-04:00")
/// |> datetime.compare(to: datetime.literal("2023-05-11T13:15:00Z"))
/// // -> order.Lt
/// ```
/// 
/// ```gleam
/// datetime.literal("2024-06-12T23:47:00+09:05")
/// |> datetime.compare(to: datetime.literal("2022-04-12T00:00:00"))
/// // -> order.Gt
/// ```
pub fn compare(a: tempo.DateTime, to b: tempo.DateTime) {
  apply_offset(a) |> naive_datetime.compare(to: apply_offset(b))
}

/// Checks if the first datetime is earlier than the second datetime.
///
/// ## Examples
///
/// ```gleam
/// datetime.literal("2024-06-21T23:47:00+09:05")
/// |> datetime.is_earlier(
///   than: datetime.literal("2024-06-21T23:47:00+09:05"),
/// )
/// // -> False
/// ```
///
/// ```gleam
/// datetime.literal("2023-05-11T13:30:00-04:00")
/// |> datetime.is_earlier(
///   than: datetime.literal("2023-05-11T13:15:00Z"),
/// )
/// // -> True
/// ```
pub fn is_earlier(a: tempo.DateTime, than b: tempo.DateTime) -> Bool {
  compare(a, b) == order.Lt
}

/// Checks if the first datetime is earlier or equal to the second datetime.
/// 
/// ## Examples
/// ```gleam
/// datetime.literal("2024-06-21T23:47:00+09:05")
/// |> datetime.is_earlier_or_equal(
///   to: datetime.literal("2024-06-21T23:47:00+09:05"),
/// )
/// // -> True
/// ```
/// 
/// ```gleam
/// datetime.literal("2024-07-15T23:40:00-04:00")
/// |> datetime.is_earlier_or_equal(
///   to: datetime.literal("2023-05-11T13:15:00Z"),
/// )
/// // -> False
/// ```
pub fn is_earlier_or_equal(a: tempo.DateTime, to b: tempo.DateTime) -> Bool {
  compare(a, b) == order.Lt || compare(a, b) == order.Eq
}

/// Checks if the first datetime is equal to the second datetime.
/// 
/// ## Examples
/// ```gleam
/// datetime.literal("2024-06-21T09:44:00Z")
/// |> datetime.is_equal(
///   to: datetime.literal("2024-06-21T05:44:00-04:00"),
/// )
/// // -> True
/// ```
/// 
/// ```gleam
/// datetime.literal("2024-06-21T09:44:00Z")
/// |> datetime.is_equal(
///   to: datetime.literal("2024-06-21T09:44:00.045Z"),
/// )
/// // -> False
/// ```
pub fn is_equal(a: tempo.DateTime, to b: tempo.DateTime) -> Bool {
  compare(a, b) == order.Eq
}

/// Checks if the first datetime is later than the second datetime.
///
/// ## Examples
///
/// ```gleam
/// datetime.literal("2024-06-21T23:47:00+09:05")
/// |> datetime.is_later(
///   than: datetime.literal("2024-06-21T23:47:00+09:05"),
/// )
/// // -> False
/// ```
///
/// ```gleam
/// datetime.literal("2023-05-11T13:00:00+04:00")
/// |> datetime.is_later(
///   than: datetime.literal("2023-05-11T13:15:00.534Z"),
/// )
/// // -> True
/// ```
pub fn is_later(a: tempo.DateTime, than b: tempo.DateTime) -> Bool {
  compare(a, b) == order.Gt
}

/// Checks if the first datetime is later or equal to the second datetime.
/// 
/// ## Examples
/// ```gleam
/// datetime.literal("2016-01-11T03:47:00+09:05")
/// |> datetime.is_later_or_equal(
///   to: datetime.literal("2024-06-21T23:47:00+09:05"),
/// )
/// // -> False
/// ```
/// 
/// ```gleam
/// datetime.literal("2024-07-15T23:40:00-04:00")
/// |> datetime.is_later_or_equal(
///   to: datetime.literal("2023-05-11T13:15:00Z"),
/// )
/// // -> True
/// ```
pub fn is_later_or_equal(a: tempo.DateTime, to b: tempo.DateTime) -> Bool {
  compare(a, b) == order.Gt || compare(a, b) == order.Eq
}

/// Returns the difference between two datetimes as a period between their
/// equivalent UTC times.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-12T23:17:00Z")
/// |> datetime.difference(
///   from: datetime.literal("2024-06-16T01:16:12Z"),
/// )
/// |> period.as_days
/// // -> 3
/// ```
/// 
/// ```gleam
/// datetime.literal("2024-06-12T23:17:00Z")
/// |> datetime.difference(
///   from: datetime.literal("2024-06-16T01:18:12Z"),
/// )
/// |> period.format
/// // -> "3 days, 2 hours, and 1 minute"
/// ```
pub fn difference(from a: tempo.DateTime, to b: tempo.DateTime) -> tempo.Period {
  apply_offset(a) |> naive_datetime.difference(to: apply_offset(b))
}

/// Creates a period between two datetimes, where the start and end times are
/// the equivalent UTC times of the provided datetimes.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.to_period(
///   start: datetime.literal("2024-06-12T23:17:00Z")
///   end: datetime.literal("2024-06-16T01:16:12Z"),
/// )
/// |> period.as_days
/// // -> 3
/// ```
/// 
/// ```gleam
/// datetime.to_period(
///   start: datetime.literal("2024-06-12T23:17:00Z")
///   end: datetime.literal("2024-06-16T01:18:12Z"),
/// )
/// |> period.format
/// // -> "3 days, 2 hours, and 1 minute"
/// ```
pub fn to_period(
  start start: tempo.DateTime,
  end end: tempo.DateTime,
) -> tempo.Period {
  apply_offset(start) |> naive_datetime.to_period(end: apply_offset(end))
}

/// Adds a duration to a datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-12T23:17:00Z")
/// |> datetime.add(duration.minutes(3))
/// // -> datetime.literal("2024-06-12T23:20:00Z")
/// ```
pub fn add(
  datetime: tempo.DateTime,
  duration duration_to_add: tempo.Duration,
) -> tempo.DateTime {
  datetime
  |> drop_offset
  |> naive_datetime.add(duration: duration_to_add)
  |> naive_datetime.set_offset(datetime.offset)
}

/// Subtracts a duration from a datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-21T23:17:00Z")
/// |> datetime.subtract(duration.days(3))
/// // -> datetime.literal("2024-06-18T23:17:00Z")
/// ```
pub fn subtract(
  datetime: tempo.DateTime,
  duration duration_to_subtract: tempo.Duration,
) -> tempo.DateTime {
  datetime
  |> drop_offset
  |> naive_datetime.subtract(duration: duration_to_subtract)
  |> naive_datetime.set_offset(datetime.offset)
}

/// Gets the time left in the day.
/// 
/// Does **not** account for leap seconds like the rest of the package.
/// 
/// ## Examples
///
/// ```gleam
/// naive_datetime.literal("2015-06-30T23:59:03Z")
/// |> naive_datetime.time_left_in_day
/// // -> time.literal("00:00:57")
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-18T08:05:20-04:00")
/// |> naive_datetime.time_left_in_day
/// // -> time.literal("15:54:40")
/// ```
pub fn time_left_in_day(datetime: tempo.DateTime) -> tempo.Time {
  datetime.naive.time |> time.left_in_day
}
