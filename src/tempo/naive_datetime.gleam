//// Functions to use with the `NaiveDateTime` type in Tempo. Naive datetimes
//// are datetime values without an offset or timezone value.
//// 
//// ## Example
//// 
//// ```gleam
//// import tempo/naive_datetime
//// import tempo/date
//// import tempo/time
//// 
//// pub fn get_date_and_time() {
////   naive_datetime.now_local()
////   |> naive_datetime.to_string
////   // -> "2024-06-21T13:42:11"
//// }

import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/regexp
import gleam/result
import gleam/string
import tempo
import tempo/date
import tempo/error as tempo_error
import tempo/month
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
  tempo.naive_datetime(date, time)
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
    Error(tempo_error.NaiveDateTimeInvalidFormat(..)) ->
      panic as "Invalid naive datetime literal format"
    Error(tempo_error.NaiveDateTimeTimeParseError(
      _,
      tempo_error.TimeInvalidFormat(_),
    )) -> panic as "Invalid time format in naive datetime literal"
    Error(tempo_error.NaiveDateTimeTimeParseError(
      _,
      tempo_error.TimeOutOfBounds(_, tempo_error.TimeHourOutOfBounds(..)),
    )) -> panic as "Invalid hour value in naive datetime literal"
    Error(tempo_error.NaiveDateTimeTimeParseError(
      _,
      tempo_error.TimeOutOfBounds(_, tempo_error.TimeMinuteOutOfBounds(..)),
    )) -> panic as "Invalid minute value in naive datetime literal"
    Error(tempo_error.NaiveDateTimeTimeParseError(
      _,
      tempo_error.TimeOutOfBounds(_, tempo_error.TimeSecondOutOfBounds(..)),
    )) -> panic as "Invalid second value in naive datetime literal"
    Error(tempo_error.NaiveDateTimeTimeParseError(
      _,
      tempo_error.TimeOutOfBounds(_, tempo_error.TimeMicroSecondOutOfBounds(..)),
    )) -> panic as "Invalid subsecond value in naive datetime literal"
    Error(tempo_error.NaiveDateTimeDateParseError(
      _,
      tempo_error.DateInvalidFormat(_),
    )) -> panic as "Invalid date format in naive datetime literal"
    Error(tempo_error.NaiveDateTimeDateParseError(
      _,
      tempo_error.DateOutOfBounds(_, tempo_error.DateDayOutOfBounds(..)),
    )) -> panic as "Invalid date day in naive datetime literal"
    Error(tempo_error.NaiveDateTimeDateParseError(
      _,
      tempo_error.DateOutOfBounds(_, tempo_error.DateMonthOutOfBounds(..)),
    )) -> panic as "Invalid date month in naive datetime literal"
    Error(tempo_error.NaiveDateTimeDateParseError(
      _,
      tempo_error.DateOutOfBounds(_, tempo_error.DateYearOutOfBounds(..)),
    )) -> panic as "Invalid date year in naive datetime literal"
  }
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
pub fn from_string(
  datetime: String,
) -> Result(tempo.NaiveDateTime, tempo_error.NaiveDateTimeParseError) {
  let split_dt = case string.contains(datetime, "T") {
    True -> string.split(datetime, "T")
    False -> string.split(datetime, " ")
  }

  case split_dt {
    [date, time] -> {
      use date: tempo.Date <- result.try(
        date.from_string(date)
        |> result.map_error(tempo_error.NaiveDateTimeDateParseError(
          "Unable to parse date in input: " <> datetime,
          _,
        )),
      )
      use time: tempo.Time <- result.map(
        time.from_string(time)
        |> result.map_error(tempo_error.NaiveDateTimeTimeParseError(
          "Unable to parse time in input: " <> datetime,
          _,
        )),
      )
      tempo.naive_datetime(date, time)
    }
    [date] -> {
      use date: tempo.Date <- result.map(
        date.from_string(date)
        |> result.map_error(tempo_error.NaiveDateTimeDateParseError(
          "Unable to parse date in input: " <> datetime,
          _,
        )),
      )
      tempo.naive_datetime(date, tempo.time(0, 0, 0, 0))
    }
    _ ->
      Error(tempo_error.NaiveDateTimeInvalidFormat(
        "Unable to determine date and time delimiter in input: " <> datetime,
      ))
  }
}

/// Returns a string representation of a naive datetime value in the ISO 8601
/// format with millisecond precision. If a different precision is needed, 
/// use the `format` function. 
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.to_string
/// // -> "2024-06-21T23:17:00.000"
/// ```
pub fn to_string(datetime: tempo.NaiveDateTime) -> String {
  tempo.naive_datetime_to_string(datetime)
}

/// Returns a tuple of the date and time values in the format used in Erlang.
/// 
/// ## Example
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:07")
/// |> naive_datetime.to_tuple
/// // -> #(#(2024, 6, 21), #(23, 17, 7))
/// ```
pub fn to_tuple(
  naive_datetime: tempo.NaiveDateTime,
) -> #(#(Int, Int, Int), #(Int, Int, Int)) {
  #(
    #(
      naive_datetime |> tempo.naive_datetime_get_date |> tempo.date_get_year,
      month.to_int(
        naive_datetime |> tempo.naive_datetime_get_date |> tempo.date_get_month,
      ),
      naive_datetime |> tempo.naive_datetime_get_date |> tempo.date_get_day,
    ),
    #(
      naive_datetime |> tempo.naive_datetime_get_time |> tempo.time_get_hour,
      naive_datetime |> tempo.naive_datetime_get_time |> tempo.time_get_minute,
      naive_datetime |> tempo.naive_datetime_get_time |> tempo.time_get_second,
    ),
  )
}

/// Parses a naive datetime string in the provided format. Always prefer using
/// this over `parse_any`. All parsed formats must have all parts of a naive
/// datetime (date and time). Use the other modules for parsing lesser
/// date time values.
/// 
/// Values can be escaped by putting brackets around them, like "[Hello!] YYYY".
/// 
/// Available directives: YY (two-digit year), YYYY (four-digit year), M (month), 
/// MM (two-digit month), MMM (short month name), MMMM (full month name), 
/// D (day of the month), DD (two-digit day of the month),
/// H (hour), HH (two-digit hour), h (12-hour clock hour), hh 
/// (two-digit 12-hour clock hour), m (minute), mm (two-digit minute),
/// s (second), ss (two-digit second), SSS (millisecond), SSSS (microsecond), 
/// A (AM/PM), a (am/pm).
/// 
/// ## Example
/// 
/// ```gleam
/// naive_datetime.parse("2024/06/08, 13:42:11", "YYYY/MM/DD, HH:mm:ss")
/// // -> Ok(naive_datetime.literal("2024-06-08T13:42:11"))
/// ```
/// 
/// ```gleam
/// naive_datetime.parse("January 13, 2024. 3:42:11", "MMMM DD, YYYY. H:mm:ss")
/// // -> Ok(naive_datetime.literal("2024-01-13T03:42:11"))
/// ```
/// 
/// ```gleam
/// naive_datetime.parse("Hi! 2024 11 13 12 2 am", "[Hi!] YYYY M D h m a")
/// // -> Ok(naive_datetime.literal("2024-11-13T00:02:00"))
/// ```
pub fn parse(
  str: String,
  in fmt: String,
) -> Result(tempo.NaiveDateTime, tempo_error.NaiveDateTimeParseError) {
  use #(parts, _) <- result.try(
    tempo.consume_format(str, in: fmt)
    |> result.map_error(tempo_error.NaiveDateTimeInvalidFormat(_)),
  )

  use date <- result.try(
    tempo.find_date(in: parts)
    |> result.map_error(tempo_error.NaiveDateTimeDateParseError(str, _)),
  )

  use time <- result.try(
    tempo.find_time(in: parts)
    |> result.map_error(tempo_error.NaiveDateTimeTimeParseError(str, _)),
  )

  Ok(new(date, time))
}

/// Tries to parse a given date string without a known format. It will not 
/// parse two digit years and will assume the month always comes before the 
/// day in a date. Will leave off any time offset values present.
/// 
/// ## Example
/// 
/// ```gleam
/// naive_datetime.parse_any("2024.06.21 01:32 PM -04:00")
/// // -> Ok(naive_datetime.literal("2024-06-21T13:32:00"))
/// ```
/// 
/// ```gleam
/// naive_datetime.parse_any("2024.06.21")
/// // -> Error(tempo.ParseMissingTime)
/// ```
pub fn parse_any(
  str: String,
) -> Result(tempo.NaiveDateTime, tempo_error.NaiveDateTimeParseError) {
  case tempo.parse_any(str) {
    #(Some(date), Some(time), _) -> Ok(new(date, time))
    #(_, None, _) ->
      Error(tempo_error.NaiveDateTimeInvalidFormat(
        "Unable to find date in " <> str,
      ))
    #(None, _, _) ->
      Error(tempo_error.NaiveDateTimeInvalidFormat(
        "Unable to find time in " <> str,
      ))
  }
}

/// Converts a naive datetime parse error to a human readable error message.
/// 
/// ## Example
/// 
/// ```gleam
/// naive_datetime.parse("2024 06 21 23:17:00")
/// |> snag.map_error(with: naive_datetime.describe_parse_error)
/// // -> snag.error("Invalid date format in naive datetime: 2024 06 21 23:17:00")
/// ```
pub fn describe_parse_error(
  error: tempo_error.NaiveDateTimeParseError,
) -> String {
  tempo_error.describe_naive_datetime_parse_error(error)
}

/// Formats a naive datetime value using the provided format string.
/// Implements the same formatting directives as the great Day.js 
/// library: https://day.js.org/docs/en/display/format.
/// 
/// Values can be escaped by putting brackets around them, like "[Hello!] YYYY".
/// 
/// Available directives: YY (two-digit year), YYYY (four-digit year), M (month), 
/// MM (two-digit month), MMM (short month name), MMMM (full month name), 
/// D (day of the month), DD (two-digit day of the month), d (day of the week), 
/// dd (min day of the week), ddd (short day of week), dddd (full day of the week), 
/// H (hour), HH (two-digit hour), h (12-hour clock hour), hh 
/// (two-digit 12-hour clock hour), m (minute), mm (two-digit minute),
/// s (second), ss (two-digit second), SSS (millisecond), SSSS (microsecond), 
/// A (AM/PM), a (am/pm).
/// 
/// ## Example
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T13:42:11.314")
/// |> naive_datetime.format("ddd @ h:mm A")
/// // -> "Fri @ 1:42 PM"
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-03T09:02:01")
/// |> naive_datetime.format("YY YYYY M MM MMM MMMM D DD d dd ddd")
/// // --------------------> "24 2024 6 06 Jun June 3 03 1 Mo Mon"
/// ```
/// 
/// ```gleam 
/// naive_datetime.literal("2024-06-03T09:02:01.014920202")
/// |> naive_datetime.format("dddd SSS SSSS SSSSS")
/// // -> "Monday 014 014920 014920202"
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-03T13:02:01")
/// |> naive_datetime.format("H HH h hh m mm s ss a A [An ant]")
/// // -------------------> "13 13 1 01 2 02 1 01 pm PM An ant"
/// ```
pub fn format(naive_datetime: tempo.NaiveDateTime, in format: tempo.DateTimeFormat) -> String {
  let format_str = tempo.get_datetime_format_str(format)

  let assert Ok(re) = regexp.from_string(tempo.format_regex)

  regexp.scan(re, format_str)
  |> list.reverse
  |> list.fold(from: [], with: fn(acc, match) {
    case match {
      regexp.Match(content, []) -> [
        content
          |> tempo.date_replace_format(naive_datetime |> get_date)
          |> tempo.time_replace_format(naive_datetime |> get_time),
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

/// Sets a naive datetime's offset to UTC, leaving the date and time unchanged
/// while returning a datetime value. 
/// Alias for `set_offset(naive_datetime, offset.utc)`.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.as_utc
/// // -> datetime.literal("2024-06-21T23:17:00Z")
/// ```
pub fn as_utc(datetime: tempo.NaiveDateTime) -> tempo.DateTime {
  set_offset(datetime, tempo.utc)
}

/// Sets a naive datetime's offset to the host's local offset, leaving the 
/// date and time unchanged while returning a datetime value. 
/// Alias for `set_offset(naive_datetime, offset.local())`.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-21T23:17:00")
/// |> naive_datetime.as_local
/// // -> datetime.literal("2024-06-21T23:17:00+01:00")
/// ```
pub fn as_local(datetime: tempo.NaiveDateTime) -> tempo.DateTime {
  set_offset(datetime, offset.local())
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
  tempo.naive_datetime_get_date(datetime)
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
  tempo.naive_datetime_get_time(datetime)
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
  tempo.naive_datetime_get_date(datetime)
  |> tempo.naive_datetime(tempo.time(0, 0, 0, 0))
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
  tempo.naive_datetime_set_offset(datetime, offset)
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
  tempo.naive_datetime_compare(a, b)
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
  tempo.naive_datetime_is_earlier(a, b)
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
  tempo.naive_datetime_is_earlier_or_equal(a, b)
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
  tempo.naive_datetime_is_later_or_equal(a, b)
}

/// Returns the difference between two naive datetimes as a duration.
/// 
/// ## Examples
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-16T01:16:12")
/// |> naive_datetime.difference(
///   naive_datetime.literal("2024-06-12T23:17:00"),
/// )
/// |> duration.as_days
/// // -> 3
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-16T01:18:12")
/// |> naive_datetime.difference(
///   naive_datetime.literal("2024-06-12T23:17:00"),
/// )
/// |> duration.format
/// // -> "3 days, 2 hours, and 1 minute"
/// ```
pub fn difference(
  from a: tempo.NaiveDateTime,
  to b: tempo.NaiveDateTime,
) -> tempo.Duration {
  tempo.naive_datetime_difference(from: a, to: b)
}

/// Creates a period between two naive datetimes. The specified start and end
/// datetimes will be swapped if the start datetime is later than the end
/// datetime.
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
pub fn as_period(
  start start: tempo.NaiveDateTime,
  end end: tempo.NaiveDateTime,
) -> tempo.Period {
  tempo.period_new_naive(start:, end:)
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
  tempo.naive_datetime_add(datetime, duration_to_add)
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
  tempo.naive_datetime_subtract(datetime, duration_to_subtract)
}

/// Gets the time left in the day.
/// 
/// Does **not** account for leap seconds like the rest of the package.
/// 
/// ## Examples
///
/// ```gleam
/// naive_datetime.literal("2015-06-30T23:59:03")
/// |> naive_datetime |> tempo.naive_datetime_get_time_left_in_day
/// // -> time.literal("00:00:57")
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-18T08:05:20")
/// |> naive_datetime |> tempo.naive_datetime_get_time_left_in_day
/// // -> time.literal("15:54:40")
/// ```
pub fn time_left_in_day(naive_datetime: tempo.NaiveDateTime) -> tempo.Time {
  naive_datetime |> tempo.naive_datetime_get_time |> time.left_in_day
}
