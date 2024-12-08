//// Functions to use with the `DateTime` type in Tempo.
//// 
//// ## Examples
//// 
//// ```gleam
//// import tempo/datetime
//// 
//// pub fn main() {
//// datetime.literal("2024-12-25T06:00:00+05:00")
////   |> datetime.format("ddd @ h:mm A, Z")
////   // -> "Fri @ 6:00 AM, +05:00"
//// 
////   datetime.parse("06:21:2024 23:17:07.123Z", "MM:DD:YYYY HH:mm:ss.SSSZ")
////   |> datetime.to_text
////   // -> "2024-06-21T23:17:07.123Z"
//// 
////   datetime.now_local()
////   // -> "2024-10-09T13:42:11.195Z"
//// }
//// ```
//// 
//// ```gleam
//// import tempo/datetime
//// 
//// pub fn is_30_mins_old(unix_ts: Int) {
////   datetime.from_unix_utc(unix_ts)
////   |> datetime.is_equal_or_earlier(
////      to: tempo.now_utc_adjusted(by: duration.minutes(-30))
////   )
//// }
//// ```
//// 
//// ```gleam
//// import tempo/datetime
//// import tempo/period
//// 
//// pub fn get_every_friday_between(datetime1, datetime2) {
////   period.new(datetime1, datetime2)
////   |> period.comprising_dates
////   |> iterator.filter(fn(date) { 
////     date |> date.to_day_of_week == date.Fri
////   })
////   |> iterator.to_list
////   // -> ["2024-06-21", "2024-06-28", "2024-07-05"]
//// }
//// ```

import gleam/bool
import gleam/dynamic
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/string_tree
import tempo
import tempo/date
import tempo/month
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
  tempo.datetime(naive_datetime.new(date, time), offset: offset)
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
/// |> datetime.to_text
/// // -> "2024-06-13T23:04:00.009+10:00"
/// ```
pub fn literal(datetime: String) -> tempo.DateTime {
  case from_string(datetime) {
    Ok(datetime) -> datetime
    Error(tempo.DateTimeInvalidFormat) ->
      panic as "Invalid datetime literal format"
    Error(tempo.DateTimeDateParseError(_)) ->
      panic as "Invalid date in datetime literal value"
    Error(tempo.DateTimeTimeParseError(_)) ->
      panic as "Invalid time in datetime literal value"
    Error(_) -> panic as "Invalid datetime literal"
  }
}

/// Gets the current local datetime of the host as an ISO-8601 formatted 
/// string with millisecond precision. To record the current time (including 
/// monotonic and unique), use `tempo.now_utc`. To get the current datetime
/// for other purposes, use `tempo.now_utc |> moment.as_datetime`.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.now_local_string()
/// // -> "2024-06-14T04:19:20.086-04:00"
/// ```
pub fn now_local_string() -> String {
  let now_utc = {
    let now_ts_micro = tempo.now_utc_ffi()

    new(
      date.from_unix_utc(now_ts_micro / 1_000_000),
      time.from_unix_micro_utc(now_ts_micro),
      tempo.utc,
    )
  }

  // This should always be precise because it is the current time.
  case now_utc |> to_local {
    tempo.Precise(datetime) -> datetime
    tempo.Imprecise(datetime) -> datetime
  }
  |> format(in: "YYYY-MM-DDTHH:mm:ss.SSSZ")
}

/// Gets the current UTC datetime of the host as an ISO-8601 formatted string
/// with millisecond precision. To record the current time (including 
/// monotonic and unique), use `tempo.now_utc`. To get the current datetime 
/// for other purposes, use `tempo.now_utc |> moment.as_datetime`.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.now_utc_string()
/// // -> "2024-06-14T08:19:20.056Z"
/// ```
pub fn now_utc_string() -> String {
  let now_ts_micro = tempo.now_utc_ffi()

  new(
    date.from_unix_utc(now_ts_micro / 1_000_000),
    time.from_unix_micro_utc(now_ts_micro),
    tempo.utc,
  )
  |> format(in: "YYYY-MM-DDTHH:mm:ss.SSSZ")
}

/// Parses a datetime string in the format `YYYY-MM-DDThh:mm:ss.sTZD`,
/// `YYYYMMDDThhmmss.sTZD`, `YYYY-MM-DD hh:mm:ss.sTZD`,
/// `YYYYMMDD hhmmss.sTZD`, `YYYY-MM-DD`, `YYYY-M-D`, `YYYY/MM/DD`, 
/// `YYYY/M/D`, `YYYY.MM.DD`, `YYYY.M.D`, `YYYY_MM_DD`, `YYYY_M_D`, 
/// `YYYY MM DD`, `YYYY M D`, or `YYYYMMDD`.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.from_string("20240613T230400.009+00:00")
/// // -> datetime.literal("2024-06-13T23:04:00.009Z")
/// ```
pub fn from_string(
  datetime: String,
) -> Result(tempo.DateTime, tempo.DateTimeParseError) {
  let split_dt = case string.contains(datetime, "T") {
    True -> string.split(datetime, "T")
    False -> string.split(datetime, " ")
  }

  case split_dt {
    [date, time] -> {
      use date: tempo.Date <- result.try(
        date.from_string(date)
        |> result.map_error(fn(e) { tempo.DateTimeDateParseError(e) }),
      )

      use #(time, offset): #(String, String) <- result.try(
        split_time_and_offset(time),
      )

      use time: tempo.Time <- result.try(
        time.from_string(time)
        |> result.map_error(fn(e) { tempo.DateTimeTimeParseError(e) }),
      )
      use offset: tempo.Offset <- result.map(
        offset.from_string(offset)
        |> result.map_error(fn(e) { tempo.DateTimeOffsetParseError(e) }),
      )

      new(date, time, offset)
    }

    [date] ->
      date.from_string(date)
      |> result.map(new(_, tempo.time(0, 0, 0, 0), tempo.utc))
      |> result.map_error(fn(e) { tempo.DateTimeDateParseError(e) })

    _ -> Error(tempo.DateTimeInvalidFormat)
  }
}

fn split_time_and_offset(time_with_offset: String) {
  case string.slice(time_with_offset, at_index: -1, length: 1) {
    "Z" -> #(string.drop_end(time_with_offset, 1), "Z") |> Ok
    "z" -> #(string.drop_end(time_with_offset, 1), "Z") |> Ok
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
/// format with millisecond precision. If a different precision is needed, 
/// use the `format` function. If serializing to send outside of Gleam and then
/// parse back into a datetime value, use the `serialize` function.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.to_string(my_datetime)
/// // -> "2024-06-21T05:22:22.009534Z" 
/// ```
@deprecated("Use `to_text` for the same functionality, or `serialize` for sending datetime values outside of Gleam to later be parsed by this library.")
pub fn to_string(datetime: tempo.DateTime) -> String {
  tempo.datetime_to_string(datetime)
}

/// Returns a string representation of a datetime value in the ISO 8601
/// format with millisecond precision. If a different precision is needed, 
/// use the `format` function. If serializing to send outside of Gleam and then
/// parse back into a datetime value, use the `serialize` function.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.to_text(my_datetime)
/// // -> "2024-06-21T05:22:22.009Z" 
/// ```
pub fn to_text(datetime: tempo.DateTime) -> String {
  datetime |> tempo.datetime_get_naive |> naive_datetime.to_string
  <> case datetime |> tempo.datetime_get_offset |> tempo.offset_get_minutes {
    0 -> "Z"
    _ -> datetime |> tempo.datetime_get_offset |> offset.to_string
  }
}

/// Serializes a datetime value to a string in the compact, precise format  
/// `YYYYMMDDTHHmmss.SSSSSz`. Useful for sending a complete datetime value
/// outside of Gleam then parsing it back into a datetime value later.
/// 
/// ## Example
/// 
/// ```gleam
/// let my_dt = datetime.literal("2024-06-21T23:17:07.3752Z")
///
/// let recovered_dt = 
///   datetime.serialize(my_dt)
///   |> dynamic.from
///   // store in a database, then retrieve it
///   |> datetime.from_dynamic_string
/// 
/// my_dt == recovered_dt
/// // -> True
/// ```
pub fn serialize(datetime: tempo.DateTime) -> String {
  let d = get_date(datetime)
  let t = get_time(datetime)
  let o = get_offset(datetime)

  string_tree.from_strings([
    date.get_year(d) |> int.to_string |> string.pad_start(4, with: "0"),
    date.get_month(d)
      |> month.to_int
      |> int.to_string
      |> string.pad_start(2, with: "0"),
    date.get_day(d) |> int.to_string |> string.pad_start(2, with: "0"),
    "T",
    time.get_hour(t) |> int.to_string |> string.pad_start(2, with: "0"),
    time.get_minute(t) |> int.to_string |> string.pad_start(2, with: "0"),
    time.get_second(t) |> int.to_string |> string.pad_start(2, with: "0"),
    ".",
    time.get_nanosecond(t) |> int.to_string |> string.pad_start(9, with: "0"),
    case o |> tempo.offset_get_minutes {
      0 -> "Z"
      _ -> {
        let str_offset = o |> offset.to_string

        case str_offset |> string.split(":") {
          [hours, "00"] -> hours
          _ -> str_offset
        }
      }
    },
  ])
  |> string_tree.to_string
}

/// Parses a datetime string in the provided format. Always prefer using
/// this over `parse_any`. All parsed formats must have all parts of a
/// datetime (date, time, offset). Use the other modules for parsing lesser
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
/// Z (offset from UTC), ZZ (offset from UTC with no ":"),
/// z (short offset from UTC "-04", "Z"), A (AM/PM), a (am/pm).
/// 
/// ## Example
/// 
/// ```gleam
/// datetime.parse("2024/06/08, 13:42:11, -04:00", "YYYY/MM/DD, HH:mm:ss, Z")
/// // -> Ok(datetime.literal("2024-06-08T13:42:11-04"))
/// ```
/// 
/// ```gleam
/// datetime.parse("January 13, 2024. 3:42:11Z", "MMMM DD, YYYY. H:mm:ssz")
/// // -> Ok(datetime.literal("2024-01-13T03:42:11Z"))
/// ```
/// 
/// ```gleam
/// datetime.parse("Hi! 2024 11 13 12 2 am Z", "[Hi!] YYYY M D h m a z")
/// // -> Ok(datetime.literal("2024-11-13T00:02:00Z"))
/// ```
pub fn parse(
  str: String,
  in fmt: String,
) -> Result(tempo.DateTime, tempo.DateTimeParseError) {
  use #(parts, _) <- result.try(
    tempo.consume_format(str, in: fmt)
    |> result.replace_error(tempo.DateTimeInvalidFormat),
  )

  use date <- result.try(
    tempo.find_date(in: parts)
    |> result.map_error(fn(e) { tempo.DateTimeDateParseError(e) }),
  )

  use time <- result.try(
    tempo.find_time(in: parts)
    |> result.map_error(fn(e) { tempo.DateTimeTimeParseError(e) }),
  )

  use offset <- result.try(
    tempo.find_offset(in: parts)
    |> result.map_error(fn(e) { tempo.DateTimeOffsetParseError(e) }),
  )

  Ok(new(date, time, offset))
}

/// Tries to parse a given date string without a known format. It will not 
/// parse two digit years and will assume the month always comes before the 
/// day in a date.
/// 
/// ## Example
/// 
/// ```gleam
/// parse_any.parse_any("2024.06.21 01:32 PM -0400")
/// // -> Ok(datetime.literal("2024-06-21T13:32:00-04:00"))
/// ```
/// 
/// ```gleam
/// parse_any.parse_any("2024.06.21 01:32 PM")
/// // -> Error(tempo.ParseMissingOffset)
/// ```
pub fn parse_any(
  str: String,
) -> Result(tempo.DateTime, tempo.DateTimeParseAnyError) {
  case tempo.parse_any(str) {
    #(Some(date), Some(time), Some(offset)) -> Ok(new(date, time, offset))
    #(_, _, None) -> Error(tempo.DateTimeMissingOffset)
    #(_, None, _) -> Error(tempo.DateTimeMissingTime)
    #(None, _, _) -> Error(tempo.DateTimeMissingDate)
  }
}

/// Formats a datetime value into a string using the provided format string.
/// Implements the same formatting directives as the great Day.js 
/// library: https://day.js.org/docs/en/display/format, plus short timezones.
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
/// Z (offset from UTC), ZZ (offset from UTC with no ":"),
/// z (short offset from UTC "-04", "Z"), A (AM/PM), a (am/pm).
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-21T13:42:11.314-04:00")
/// |> datetime.format("ddd @ h:mm A (z)")
/// // -> "Fri @ 1:42 PM (-04)"
/// ```
/// 
/// ```gleam
/// datetime.literal("2024-06-03T09:02:01-04:00")
/// |> datetime.format("YY YYYY M MM MMM MMMM D DD d dd ddd")
/// // --------------> "24 2024 6 06 Jun June 3 03 1 Mo Mon"
/// ```
/// 
/// ```gleam 
/// datetime.literal("2024-06-03T09:02:01.014920202-00:00")
/// |> datetime.format("dddd SSS SSSS SSSSS Z ZZ z")
/// // -> "Monday 014 014920 014920202 -00:00 -0000 Z"
/// ```
/// 
/// ```gleam
/// datetime.literal("2024-06-03T13:02:01-04:00")
/// |> datetime.format("H HH h hh m mm s ss a A [An ant]")
/// // -------------> "13 13 1 01 2 02 1 01 pm PM An ant"
/// ```
pub fn format(datetime: tempo.DateTime, in fmt: String) -> String {
  tempo.datetime_format(datetime, in: fmt)
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
  new(date.from_unix_utc(unix_ts), time.from_unix_utc(unix_ts), tempo.utc)
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

  date.to_unix_utc(utc_dt |> tempo.naive_datetime_get_date)
  + {
    tempo.time_to_microseconds(utc_dt |> tempo.naive_datetime_get_time)
    / 1_000_000
  }
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
    tempo.utc,
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

  date.to_unix_milli_utc(utc_dt |> tempo.naive_datetime_get_date)
  + {
    tempo.time_to_microseconds(utc_dt |> tempo.naive_datetime_get_time) / 1000
  }
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
    tempo.utc,
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

  date.to_unix_micro_utc(utc_dt |> tempo.naive_datetime_get_date)
  + { tempo.time_to_microseconds(utc_dt |> tempo.naive_datetime_get_time) }
}

/// Checks if a dynamic value is a valid datetime string, and returns the
/// datetime if it is.
/// 
/// ## Examples
/// 
/// ```gleam
/// dynamic.from("2024-06-13T13:42:11.195Z")
/// |> datetime.from_dynamic_string
/// // -> Ok(datetime.literal("2024-06-13T13:42:11.195Z"))
/// ```
/// 
/// ```gleam
/// dynamic.from("24-06-13,13:42:11.195")
/// |> datetime.from_dynamic_string
/// // -> Error([
/// //   dynamic.DecodeError(
/// //     expected: "tempo.DateTime",
/// //     found: "Invalid format: 24-06-13,13:42:11.195",
/// //     path: [],
/// //   ),
/// // ])
/// ```
pub fn from_dynamic_string(
  dynamic_string: dynamic.Dynamic,
) -> Result(tempo.DateTime, List(dynamic.DecodeError)) {
  use dt: String <- result.try(dynamic.string(dynamic_string))

  case from_string(dt) {
    Ok(datetime) -> Ok(datetime)
    Error(tempo_error) ->
      Error([
        dynamic.DecodeError(
          expected: "tempo.DateTime",
          found: case tempo_error {
            tempo.DateTimeInvalidFormat -> "Invalid format: "
            tempo.DateTimeTimeParseError(tempo.TimeInvalidFormat(_)) ->
              "Invalid time format: "
            tempo.DateTimeTimeParseError(tempo.TimeOutOfBounds(
              tempo.TimeHourOutOfBounds,
            )) -> "Invalid time hour value: "
            tempo.DateTimeTimeParseError(tempo.TimeOutOfBounds(
              tempo.TimeMinuteOutOfBounds,
            )) -> "Invalid time minute value: "
            tempo.DateTimeTimeParseError(tempo.TimeOutOfBounds(
              tempo.TimeSecondOutOfBounds,
            )) -> "Invalid time second value: "
            tempo.DateTimeTimeParseError(tempo.TimeOutOfBounds(
              tempo.TimeMicroSecondOutOfBounds,
            )) -> "Invalid time subsecond value: "
            tempo.DateTimeDateParseError(tempo.DateInvalidFormat(_)) ->
              "Invalid date format: "
            tempo.DateTimeDateParseError(tempo.DateOutOfBounds(
              tempo.DateDayOutOfBounds,
            )) -> "Invalid date day value: "
            tempo.DateTimeDateParseError(tempo.DateOutOfBounds(
              tempo.DateMonthOutOfBounds,
            )) -> "Invalid date month value: "
            tempo.DateTimeDateParseError(tempo.DateOutOfBounds(
              tempo.DateYearOutOfBounds,
            )) -> "Invalid date year value: "
            tempo.DateTimeOffsetParseError(tempo.OffsetInvalidFormat(_)) ->
              "Invalid offset format: "
            tempo.DateTimeOffsetParseError(tempo.OffsetOutOfBounds) ->
              "Invalid offset value: "
          }
            <> dt,
          path: [],
        ),
      ])
  }
}

/// Checks if a dynamic value is a valid unix timestamp in seconds, and 
/// returns the datetime if it is.
/// 
/// ## Examples
/// 
/// ```gleam
/// dynamic.from(1_718_629_314)
/// |> datetime.from_dynamic_unix_utc
/// // -> Ok(datetime.literal("2024-06-17T13:01:54Z"))
/// ```
/// 
/// ```gleam
/// dynamic.from("hello")
/// |> datetime.from_dynamic_unix_utc
/// // -> Error([
/// //   dynamic.DecodeError(
/// //     expected: "Int",
/// //     found: "String",
/// //     path: [],
/// //   ),
/// // ])
/// ```
pub fn from_dynamic_unix_utc(
  dynamic_ts: dynamic.Dynamic,
) -> Result(tempo.DateTime, List(dynamic.DecodeError)) {
  use dt: Int <- result.map(dynamic.int(dynamic_ts))

  from_unix_utc(dt)
}

/// Checks if a dynamic value is a valid unix timestamp in milliseconds, and 
/// returns the datetime if it is.
/// 
/// ## Examples
/// 
/// ```gleam
/// dynamic.from(1_718_629_314_334)
/// |> datetime.from_dynamic_unix_utc
/// // -> Ok(datetime.literal("2024-06-17T13:01:54.334Z"))
/// ```
/// 
/// ```gleam
/// dynamic.from("hello")
/// |> datetime.from_dynamic_unix_utc
/// // -> Error([
/// //   dynamic.DecodeError(
/// //     expected: "Int",
/// //     found: "String",
/// //     path: [],
/// //   ),
/// // ])
/// ```
pub fn from_dynamic_unix_milli_utc(
  dynamic_ts: dynamic.Dynamic,
) -> Result(tempo.DateTime, List(dynamic.DecodeError)) {
  use dt: Int <- result.map(dynamic.int(dynamic_ts))

  from_unix_milli_utc(dt)
}

/// Checks if a dynamic value is a valid unix timestamp in microseconds, and 
/// returns the datetime if it is.
/// 
/// ## Examples
/// 
/// ```gleam
/// dynamic.from(1_718_629_314_334_734)
/// |> datetime.from_dynamic_unix_utc
/// // -> Ok(datetime.literal("2024-06-17T13:01:54.334734Z"))
/// ```
/// 
/// ```gleam
/// dynamic.from("hello")
/// |> datetime.from_dynamic_unix_utc
/// // -> Error([
/// //   dynamic.DecodeError(
/// //     expected: "Int",
/// //     found: "String",
/// //     path: [],
/// //   ),
/// // ])
/// ```
pub fn from_dynamic_unix_micro_utc(
  dynamic_ts: dynamic.Dynamic,
) -> Result(tempo.DateTime, List(dynamic.DecodeError)) {
  use dt: Int <- result.map(dynamic.int(dynamic_ts))

  from_unix_micro_utc(dt)
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
  datetime |> tempo.datetime_get_naive |> tempo.naive_datetime_get_date
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
  datetime |> tempo.datetime_get_naive |> tempo.naive_datetime_get_time
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
  datetime |> tempo.datetime_get_offset
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
  tempo.datetime_drop_offset(datetime)
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
  tempo.datetime(
    naive_datetime.drop_time(datetime |> tempo.datetime_get_naive),
    offset: datetime |> tempo.datetime_get_offset,
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
  tempo.datetime_apply_offset(datetime)
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
  tempo.datetime_to_utc(datetime)
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
  tempo.datetime_to_offset(datetime, offset)
}

/// Converts a datetime to the equivalent local datetime. The return value
/// indicates if the conversion was precise or imprecise. Use pattern
/// matching or the `tempo.accept_imprecision` function to handle the two cases.
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
  use <- bool.lazy_guard(
    when: datetime |> tempo.datetime_get_offset == offset.local(),
    return: fn() { tempo.Precise(datetime) },
  )

  let local_dt = datetime |> to_offset(offset.local())

  case
    local_dt |> tempo.datetime_get_naive |> tempo.naive_datetime_get_date
    == date.current_local()
  {
    True -> tempo.Precise(local_dt)
    False -> tempo.Imprecise(local_dt)
  }
}

/// Converts a datetime to the equivalent local time. The return value
/// indicates if the conversion was precise or imprecise. Use pattern
/// matching or the `tempo.accept_imprecision` function to handle the two cases.
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
    tempo.Precise(datetime) ->
      datetime
      |> tempo.datetime_get_naive
      |> tempo.naive_datetime_get_time
      |> tempo.Precise
    tempo.Imprecise(datetime) ->
      datetime
      |> tempo.datetime_get_naive
      |> tempo.naive_datetime_get_time
      |> tempo.Imprecise
  }
}

/// Converts a datetime to the equivalent local time. The return value
/// indicates if the conversion was precise or imprecise. Use pattern
/// matching or the `tempo.accept_imprecision` function to handle the two cases.
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
    tempo.Precise(datetime) ->
      datetime
      |> tempo.datetime_get_naive
      |> tempo.naive_datetime_get_date
      |> tempo.Precise
    tempo.Imprecise(datetime) ->
      datetime
      |> tempo.datetime_get_naive
      |> tempo.naive_datetime_get_date
      |> tempo.Imprecise
  }
}

/// Converts a datetime to the specified timezone. Relies on an external 
/// package like `gtz` to provide timezone information. Try to prefer using
/// `to_local` when converting datetimes to local time, as that does not depend
/// on any external package.
/// 
/// ## Example
/// 
/// ```gleam
/// import gtz
/// let assert Ok(tz) = gtz.timezone("America/New_York")
/// datetime.literal("2024-06-21T06:30:02.334Z")
/// |> datetime.to_timezone(tz)
/// |> datetime.to_text
/// // -> "2024-01-03T02:30:02.334-04:00"
/// ```
/// 
/// ```gleam
/// import gtz
/// let assert Ok(local_tz) = gtz.local_name() |> gtz.timezone
/// datetime.from_unix_utc(1_729_257_776)
/// |> datetime.to_timezone(local_tz)
/// |> datetime.to_text
/// // -> "2024-10-18T14:22:56.000+01:00"
/// ```
pub fn to_timezone(
  datetime: tempo.DateTime,
  tz: tempo.TimeZoneProvider,
) -> tempo.DateTime {
  tempo.datetime_to_tz(datetime, tz)
}

/// Gets the name of the timezone the datetime is in.
/// 
/// ## Example
/// 
/// ```gleam
/// datetime.literal("2024-06-21T06:30:02.334Z")
/// |> datetime.get_timezone_name
/// // -> None
/// ```
/// 
/// ```gleam
/// import gtz
/// let assert Ok(tz) = gtz.timezone("Europe/London")
/// datetime.to_timezone(my_datetime, tz)
/// |> datetime.get_timezone_name
/// // -> Some("Europe/London")
/// ```
pub fn get_timezone_name(datetime: tempo.DateTime) -> option.Option(String) {
  tempo.datetime_get_tz(datetime)
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
  tempo.datetime_compare(a, to: b)
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
  tempo.datetime_is_earlier(a, than: b)
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
  tempo.datetime_is_earlier_or_equal(a, b)
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
  tempo.datetime_is_equal(a, to: b)
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
  tempo.datetime_is_later(a, than: b)
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
  tempo.datetime_is_later_or_equal(a, b)
}

/// Returns the difference between two datetimes as a duration between their
/// equivalent UTC times.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-12T23:17:00Z")
/// |> datetime.difference(
///   from: datetime.literal("2024-06-16T01:16:12Z"),
/// )
/// |> duration.as_days
/// // -> 3
/// ```
/// 
/// ```gleam
/// datetime.literal("2024-06-12T23:17:00Z")
/// |> datetime.difference(
///   from: datetime.literal("2024-06-16T01:18:12Z"),
/// )
/// |> duration.format
/// // -> "3 days, 2 hours, and 1 minute"
/// ```
pub fn difference(
  from a: tempo.DateTime,
  to b: tempo.DateTime,
) -> tempo.Duration {
  naive_datetime.difference(
    from: tempo.datetime_apply_offset(a),
    to: tempo.datetime_apply_offset(b),
  )
}

/// Creates a period between two datetimes, where the start and end times are
/// the equivalent UTC times of the provided datetimes. The specified start 
/// and end datetimes will be swapped if the start datetime is later than the 
/// end datetime.
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
pub fn as_period(
  start start: tempo.DateTime,
  end end: tempo.DateTime,
) -> tempo.Period {
  tempo.period_new(start:, end:)
}

/// Adds a duration to a datetime.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-12T23:17:00Z")
/// |> datetime.add(duration |> tempo.offset_get_minutes(3))
/// // -> datetime.literal("2024-06-12T23:20:00Z")
/// ```
pub fn add(
  datetime: tempo.DateTime,
  duration duration_to_add: tempo.Duration,
) -> tempo.DateTime {
  tempo.datetime_add(datetime, duration_to_add)
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
  tempo.datetime_subtract(datetime, duration: duration_to_subtract)
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
  datetime
  |> tempo.datetime_get_naive
  |> tempo.naive_datetime_get_time
  |> time.left_in_day
}
