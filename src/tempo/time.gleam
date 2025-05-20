//// Functions to use with the `Time` type in Tempo. The time values are wall
//// time values unless explicitly stated otherwise.
//// 
//// ## Examples
//// 
//// ```gleam
//// import tempo/time
//// 
//// pub fn is_past_5pm() {
////   tempo.is_time_later(than: time.literal("17:00"))
//// }
//// ```
//// 
//// ```gleam
//// import tempo/time
//// 
//// pub fn get_enthusiastic_time() {
////   time.literal("13:42")
////   |> time.format(tempo.CustomTime(
////     "[The hour is:] HH, [wow! And even better the minute is:] mm!"
////   ))
////   // -> "The hour is: 13, wow! And even better the minute is: 42!"
//// }
//// ```

import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/regexp
import gleam/result
import gleam/string
import gleam/string_tree
import gleam/time/calendar
import gleam/time/duration
import gtempo/internal as unit
import tempo
import tempo/date
import tempo/duration as tempo_duration
import tempo/error as tempo_error

/// The first second of the day.
/// 
/// ## Example
/// 
/// ```gleam
/// time.start_of_day
/// |> time.to_string
/// // "00:00:00.000000"
/// ```
/// 
/// ```gleam
/// tempo.DateTime(date.literal("2024-06-21"), time.start_of_day, offset.utc)
/// |> datetime.to_string
/// // "2024-06-21T00:00:00.000000Z"
/// ```
pub const start_of_day = tempo.time_start_of_day

/// The end of the last second of the day.
/// 
/// ## Example
/// 
/// ```gleam
/// time.end_of_day
/// |> time.to_string
/// // "24:00:00.000000"
/// ```
/// 
/// ```gleam
/// tempo.DateTime(date.literal("2024-06-21"), time.end_of_day, offset.utc)
/// |> datetime.to_string
/// // "2024-06-21T24:00:00.000000Z"
/// ```
pub const end_of_day = tempo.time_end_of_day

/// Creates a new time value with second precision.
/// 
/// ## Example
/// 
/// ```gleam
/// time.new(13, 42, 11)
/// // -> Ok(time.literal("13:42:11"))
/// ```
/// 
/// ```gleam
/// time.new(53, 42, 61)
/// // -> Error(tempo_error.TimeOutOfBounds)
/// ```
pub fn new(
  hour: Int,
  minute: Int,
  second: Int,
) -> Result(tempo.Time, tempo_error.TimeOutOfBoundsError) {
  tempo.new_time(hour, minute, second)
}

/// Creates a new time value with millisecond precision.
/// 
/// ## Example
/// 
/// ```gleam
/// time.new_milli(13, 42, 11, 20)
/// // -> Ok(time.literal("13:42:11.020"))
/// ```
/// 
/// ```gleam
/// time.new_milli(13, 42, 11, 200)
/// // -> Ok(time.literal("13:42:11.200"))
/// ```
/// 
/// ```gleam
/// time.new_milli(13, 42, 11, 7_500)
/// // -> Error(tempo_error.TimeOutOfBounds)
/// ```
pub fn new_milli(
  hour: Int,
  minute: Int,
  second: Int,
  millisecond: Int,
) -> Result(tempo.Time, tempo_error.TimeOutOfBoundsError) {
  tempo.new_time_milli(hour, minute, second, millisecond)
}

/// Creates a new time value with microsecond precision.
/// 
/// ## Example
/// 
/// ```gleam
/// time.new_micro(13, 42, 11, 20)
/// // -> Ok(time.literal("13:42:11.000020"))
/// ```
/// 
/// ```gleam
/// time.new_micro(13, 42, 11, 200_000)
/// // -> Ok(time.litteral("13:42:11.200000"))
/// ```
/// 
/// ```gleam
/// time.new_micro(13, 42, 11, 7_500_000)
/// |> result.map_error(time.describe_out_of_bounds_error)
/// // -> Error("Subsecond value out of bounds in time: 13:42:11.7500000")
/// ```
pub fn new_micro(
  hour: Int,
  minute: Int,
  second: Int,
  microsecond: Int,
) -> Result(tempo.Time, tempo_error.TimeOutOfBoundsError) {
  tempo.new_time_micro(hour, minute, second, microsecond)
}

/// Converts a time out of bounds error to a human readable error message.
/// 
/// ## Example
/// 
/// ```gleam
/// time.new(23, 59, 60)
/// |> snag.map_error(with: time.describe_out_of_bounds_error)
/// // -> snag.error("Second out of bounds in time: 60")
pub fn describe_out_of_bounds_error(error: tempo_error.TimeOutOfBoundsError) {
  tempo_error.describe_time_out_of_bounds_error(error)
}

/// Creates a new time value from a string literal, but will panic if
/// the string is invalid. Accepted formats are
/// `hh:mm:ss.s`, `hhmmss.s`, `hh:mm:ss`, `hhmmss`, `hh:mm`, or `hhmm`.
/// 
/// Useful for declaring time literals that you know are valid within your 
/// program.
/// 
/// ## Example
/// 
/// ```gleam
/// case 
///   time.now_local() 
///   |> time.is_later(than: time.literal("11:50:00")) 
/// { 
///   True -> "We are late!"
///   False -> "No rush :)"
/// }
/// ```
pub fn literal(time: String) -> tempo.Time {
  case from_string(time) {
    Ok(time) -> time
    Error(tempo_error.TimeInvalidFormat(..)) ->
      panic as "Invalid time literal format"
    Error(tempo_error.TimeOutOfBounds(_, tempo_error.TimeHourOutOfBounds(..))) ->
      panic as "Invalid time literal hour value"
    Error(tempo_error.TimeOutOfBounds(_, tempo_error.TimeMinuteOutOfBounds(..))) ->
      panic as "Invalid time literal minute value"
    Error(tempo_error.TimeOutOfBounds(_, tempo_error.TimeSecondOutOfBounds(..))) ->
      panic as "Invalid time literal second value"
    Error(tempo_error.TimeOutOfBounds(
      _,
      tempo_error.TimeMicroSecondOutOfBounds(..),
    )) -> panic as "Invalid time literal microsecond value"
  }
}

/// Early on these were part of the public API and used in a lot of tests, 
/// but since have been removed from the public API. The tests should be 
/// updated and these functions removed.
@internal
pub fn test_literal(hour: Int, minute: Int, second: Int) -> tempo.Time {
  let assert Ok(time) = tempo.validate_time(hour, minute, second, 0)
  time
}

@internal
pub fn test_literal_milli(
  hour: Int,
  minute: Int,
  second: Int,
  millisecond: Int,
) -> tempo.Time {
  let assert Ok(time) =
    tempo.validate_time(hour, minute, second, millisecond * 1000)
  time
}

@internal
pub fn test_literal_micro(
  hour: Int,
  minute: Int,
  second: Int,
  microsecond: Int,
) -> tempo.Time {
  let assert Ok(time) = tempo.validate_time(hour, minute, second, microsecond)
  time
}

/// Gets the hour value of a time.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("13:42:11")
/// |> time.get_hour
/// // -> 13
/// ```
pub fn get_hour(time: tempo.Time) -> Int {
  time |> tempo.time_get_hour
}

/// Gets the minute value of a time.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("13:42:11")
/// |> time.get_minute
/// // -> 42
/// ```
pub fn get_minute(time: tempo.Time) -> Int {
  time |> tempo.time_get_minute
}

/// Gets the second value of a time.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("13:42:11")
/// |> time.get_second
/// // -> 11
/// ```
pub fn get_second(time: tempo.Time) -> Int {
  time |> tempo.time_get_second
}

/// Gets the microsecond value of a time.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("13:42:11.123")
/// |> time.get_microsecond
/// // -> 123000
/// ```
pub fn get_microsecond(time: tempo.Time) -> Int {
  time |> tempo.time_get_micro
}

/// Converts a time value to a string in the format `hh:mm:ss.s` with 
/// millisecond precision. If a different precision is needed, use the `format` 
/// function.
/// 
/// ## Example
/// 
/// ```gleam
/// time.to_string(my_time)
/// // -> "21:53:03.534"
/// ```
pub fn to_string(time: tempo.Time) -> String {
  string_tree.from_strings([
    time
      |> tempo.time_get_hour
      |> int.to_string
      |> string.pad_start(2, with: "0"),
    ":",
    time
      |> tempo.time_get_minute
      |> int.to_string
      |> string.pad_start(2, with: "0"),
    ":",
    time
      |> tempo.time_get_second
      |> int.to_string
      |> string.pad_start(2, with: "0"),
  ])
  |> string_tree.append(".")
  |> string_tree.append(
    tempo.time_get_micro(time)
    |> int.to_string
    |> string.pad_start(6, with: "0"),
  )
  |> string_tree.to_string
}

/// Converts a string to a time value. Accepted formats are `hh:mm:ss.s`, 
/// `hhmmss.s`, `hh:mm:ss`, `hhmmss`, `hh:mm`, or `hhmm`.
/// 
/// ## Example
/// 
/// ```gleam
/// time.from_string("00:00:00.000000300")
/// // -> Ok(time.literal("00:00:00.000000300"))
/// ```
/// 
/// ```gleam
/// time.from_string("34:54:16")
/// // -> Error(tempo_error.TimeOutOfBounds)
/// ```
pub fn from_string(
  time_str: String,
) -> Result(tempo.Time, tempo_error.TimeParseError) {
  use #(hour, minute, second): #(String, String, String) <- result.try(
    // Parse hh:mm:ss.s or hh:mm format
    case string.split(time_str, ":") {
      [hour, minute, second] -> Ok(#(hour, minute, second))
      [hour, minute] -> Ok(#(hour, minute, "0"))
      _ -> Error(Nil)
    }
    // Parse hhmmss.s or hhmm format
    |> result.try_recover(fn(_) {
      case string.length(time_str), string.contains(time_str, ".") {
        6, False ->
          Ok(#(
            string.slice(time_str, at_index: 0, length: 2),
            string.slice(time_str, at_index: 2, length: 2),
            string.slice(time_str, at_index: 4, length: 2),
          ))
        4, False ->
          Ok(#(
            string.slice(time_str, at_index: 0, length: 2),
            string.slice(time_str, at_index: 2, length: 2),
            "0",
          ))
        l, True if l >= 7 ->
          Ok(#(
            string.slice(time_str, at_index: 0, length: 2),
            string.slice(time_str, at_index: 2, length: 2),
            string.slice(time_str, at_index: 4, length: 12),
          ))
        _, _ -> Error(tempo_error.TimeInvalidFormat(time_str))
      }
    }),
  )

  use time <- result.try(
    case int.parse(hour), int.parse(minute), string.split(second, ".") {
      Ok(hour), Ok(minute), [second, second_fraction] -> {
        let second_fraction_length = string.length(second_fraction)
        case second_fraction_length {
          len if len <= 3 ->
            case
              int.parse(second),
              int.parse(second_fraction |> string.pad_end(3, with: "0"))
            {
              Ok(second), Ok(milli) ->
                Ok(tempo.validate_time(hour, minute, second, milli * 1000))
              _, _ -> Error(tempo_error.TimeInvalidFormat(time_str))
            }
          len if len <= 6 ->
            case
              int.parse(second),
              int.parse(second_fraction |> string.pad_end(6, with: "0"))
            {
              Ok(second), Ok(micro) ->
                Ok(tempo.validate_time(hour, minute, second, micro))
              _, _ -> Error(tempo_error.TimeInvalidFormat(time_str))
            }
          _ -> Error(tempo_error.TimeInvalidFormat(time_str))
        }
      }

      Ok(hour), Ok(minute), _ ->
        case int.parse(second) {
          Ok(second) -> Ok(tempo.validate_time(hour, minute, second, 0))
          _ -> Error(tempo_error.TimeInvalidFormat(time_str))
        }

      _, _, _ -> Error(tempo_error.TimeInvalidFormat(time_str))
    },
  )

  result.map_error(time, tempo_error.TimeOutOfBounds(time_str, _))
}

/// Parses a time string in the provided format. Always prefer using
/// this over `parse_any`. All parsed formats must have an hour and a second.
/// 
/// Values can be escaped by putting brackets around them, like "[Hello!] HH".
/// 
/// Available directives: H (hour), HH (two-digit hour), h (12-hour clock hour), hh 
/// (two-digit 12-hour clock hour), m (minute), mm (two-digit minute),
/// s (second), ss (two-digit second), SSS (millisecond), SSSS (microsecond), 
/// A (AM/PM), a (am/pm),
/// 
/// ## Example
/// 
/// ```gleam
/// time.parse("2024/06/08, 13:42:11", "YYYY/MM/DD")
/// // -> Ok(time.literal("13:42:11"))
/// ```
/// 
/// ```gleam
/// time.parse("January 13, 2024", "MMMM DD, YYYY")
/// |> result.map_error(time.describe_parse_error)
/// // -> Error("Invlid time format: January 13, 2024")
/// ```
/// 
/// ```gleam
/// time.parse("Hi! 12 2 am", "[Hi!] h m a")
/// // -> Ok(time.literal("00:02:00"))
/// ```
pub fn parse(
  str: String,
  in format: tempo.TimeFormat,
) -> Result(tempo.Time, tempo_error.TimeParseError) {
  let format_str = tempo.get_time_format_str(format)

  use #(parts, _) <- result.try(
    tempo.consume_format(str, in: format_str)
    |> result.map_error(tempo_error.TimeInvalidFormat),
  )

  tempo.find_time(in: parts)
}

/// Tries to parse a given date string without a known format. It will not 
/// parse two digit years and will assume the month always comes before the 
/// day in a date. Will leave off any time offset values present.
/// 
/// ## Example
/// 
/// ```gleam
/// time.parse_any("2024.06.21 01:32 PM -04:00")
/// // -> Ok(time.literal("13:32:00"))
/// ```
/// 
/// ```gleam
/// time.parse_any("2024.06.21")
/// // -> Error(tempo.ParseMissingTime)
/// ```
pub fn parse_any(str: String) -> Result(tempo.Time, tempo_error.TimeParseError) {
  case tempo.parse_any(str) {
    #(_, Some(time), _) -> Ok(time)
    #(_, None, _) ->
      Error(tempo_error.TimeInvalidFormat("Unable to find time in " <> str))
  }
}

/// Converts a time parse error to a human readable error message.
/// 
/// ## Example
/// 
/// ```gleam
/// time.parse("13 42 11", "HH:mm:ss")
/// |> snag.map_error(with: time.describe_parse_error)
/// // -> snag.error("Invalid time format: "13 42 11"")
pub fn describe_parse_error(error: tempo_error.TimeParseError) {
  tempo_error.describe_time_parse_error(error)
}

/// Formats a time value using the provided format.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("13:42:11")
/// |> time.format(tempo.ISO8601TimeMilli)
/// // -> "13:42:11.000"
/// ```
/// 
/// ```gleam
/// time.literal("13:42:11.314")
/// |> time.format("h:mm A")
/// // -> "1:42 PM"
/// ```
/// 
/// ```gleam 
/// time.literal("09:02:01.014920202")
/// |> time.format("HH:mm:ss SSS SSSS SSSSS")
/// // -> "09:02:01 014 014920 014920202"
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("13:02:01")
/// |> naive_datetime.format("H HH h hh m mm s ss a A [An ant]")
/// // -------------------> "13 13 1 01 2 02 1 01 pm PM An ant"
/// ```
pub fn format(time: tempo.Time, in format: tempo.TimeFormat) -> String {
  let format_str = tempo.get_time_format_str(format)

  let assert Ok(re) = regexp.from_string(tempo.format_regex)

  regexp.scan(re, format_str)
  |> list.reverse
  |> list.fold(from: [], with: fn(acc, match) {
    case match {
      regexp.Match(content, []) -> [
        tempo.time_replace_format(content, time),
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

/// Gets the UTC time value of a unix timestamp.
/// 
/// ## Example
/// 
/// ```gleam
/// time.from_unix_seconds(1_718_829_395)
/// // -> time.literal("20:36:35")
/// ```
/// 
/// I am making this internal because it is created but I am not sure if it
/// should be part of the public API. I think it is too easy to use incorrectly.
/// Users should probably use the 'datetime' module's 'from_unix_seconds' function
/// instead and get the time from there if they need it.
@internal
pub fn from_unix_seconds(unix_ts: Int) -> tempo.Time {
  // Subtract the microseconds that are responsible for the date.
  { unix_ts - { date.to_unix_seconds(date.from_unix_seconds(unix_ts)) } }
  * 1_000_000
  |> tempo.time_from_microseconds
}

/// Gets the UTC time value of a unix timestamp in milliseconds.
/// 
/// ## Example
/// 
/// ```gleam
/// time.from_unix_milli(1_718_829_586_791)
/// // -> time.literal("20:39:46.791")
/// ```
/// 
/// I am making this internal because it is created but I am not sure if it
/// should be part of the public API. I think it is too easy to use incorrectly.
/// Users should probably use the 'datetime' module's 'from_unix_seconds' function
/// instead and get the time from there if they need it.
@internal
pub fn from_unix_milli(unix_ts: Int) -> tempo.Time {
  // Subtract the microseconds that are responsible for the date.
  { unix_ts - { date.to_unix_milli(date.from_unix_milli(unix_ts)) } } * 1000
  |> tempo.time_from_microseconds
}

/// Gets the UTC time value of a unix timestamp in microseconds.
/// 
/// ## Example
/// 
/// ```gleam
/// time.from_unix_micro(1_718_829_586_791_832)
/// // -> time.literal("20:39:46.791832")
/// ```
/// 
/// I am making this internal because it is created but I am not sure if it
/// should be part of the public API. I think it is too easy to use incorrectly.
/// Users should probably use the 'datetime' module's 'from_unix_seconds' function
/// instead and get the time from there if they need it.
@internal
pub fn from_unix_micro(unix_ts: Int) -> tempo.Time {
  tempo.time_from_unix_micro(unix_ts)
}

/// Returns a time value as a tuple of hours, minutes, and seconds. Useful 
/// for using with another time library.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("13:42:11")
/// |> time.to_tuple
/// // -> #(13, 42, 11)
/// ```
pub fn to_tuple(time: tempo.Time) -> #(Int, Int, Int) {
  #(
    time |> tempo.time_get_hour,
    time |> tempo.time_get_minute,
    time |> tempo.time_get_second,
  )
}

/// Converts a tempo time to a time of day type in the core gleam time package.
pub fn to_calendar_time_of_day(time: tempo.Time) -> calendar.TimeOfDay {
  let #(hour, minute, second, microsecond) = to_tuple_microsecond(time)
  calendar.TimeOfDay(hour, minute, second, microsecond * 1000)
}

/// Converts a core gleam time time of day to a tempo time.
pub fn from_calendar_time_of_day(
  time: calendar.TimeOfDay,
) -> Result(tempo.Time, tempo_error.TimeOutOfBoundsError) {
  let calendar.TimeOfDay(hour, minute, second, nanosecond) = time
  from_tuple_microsecond(#(hour, minute, second, nanosecond / 1000))
}

/// Converts a tuple of hours, minutes, and seconds to a time value. Useful 
/// for using with another time library.
/// 
/// ## Example
/// 
/// ```gleam
/// #(13, 42, 11)
/// |> time.from_tuple
/// // -> time.literal("13:42:11")
/// ```
pub fn from_tuple(
  time: #(Int, Int, Int),
) -> Result(tempo.Time, tempo_error.TimeOutOfBoundsError) {
  new(time.0, time.1, time.2)
}

/// Returns a time value as a tuple of hours, minutes, seconds, and microseconds. 
/// Useful for using with another time library.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("13:42:11.872")
/// |> time.to_tuple_microsecond
/// // -> #(13, 42, 11, 872000)
/// ```
pub fn to_tuple_microsecond(time: tempo.Time) -> #(Int, Int, Int, Int) {
  #(
    time |> tempo.time_get_hour,
    time |> tempo.time_get_minute,
    time |> tempo.time_get_second,
    time |> tempo.time_get_micro,
  )
}

/// Converts a tuple of hours, minutes, seconds, and microseconds to a time 
/// value. Useful for using with another time library.
/// 
/// ## Example
/// 
/// ```gleam
/// #(13, 42, 11, 872000)
/// |> time.from_tuple_microsecond
/// // -> time.literal("13:42:11.872")
/// ```
pub fn from_tuple_microsecond(
  time: #(Int, Int, Int, Int),
) -> Result(tempo.Time, tempo_error.TimeOutOfBoundsError) {
  new_micro(time.0, time.1, time.2, time.3)
}

/// Converts a time to duration, assuming the duration epoch is "00:00:00".
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("00:00:00.000300")
/// |> time.to_duration
/// |> duration.as_microseconds
/// // -> 300
/// ```
///
/// ```gleam
/// time.literal("00:03:06")
/// |> time.to_duration 
/// |> duration.as_milliseconds
/// // -> 186_000
/// ```
pub fn to_duration(time: tempo.Time) -> duration.Duration {
  tempo.time_to_duration(time)
}

/// Converts a duration to the equivalent time of day, assuming the 
/// duration epoch is "00:00:00". Durations longer than 24 hours will be 
/// wrapped to fit within a 24 hour representation.
/// 
/// ## Example
/// 
/// ```gleam
/// duration.seconds(58)
/// |> time.from_duration
/// |> time.to_second_precision
/// |> time.to_string
/// // -> "00:00:58"
/// ```
/// 
/// ```gleam
/// duration.minutes(17)
/// |> time.from_duration
/// |> time.to_string
/// // -> "00:17:00.000000000"
/// ```
/// 
/// ```gleam
/// duration.hours(25)
/// |> time.from_duration
/// |> time.to_string
/// // -> "01:00:00.000000000"
/// ```
/// 
/// ```gleam
/// duration.microseconds(-3_000_000)
/// |> time.from_duration
/// |> time.to_string
/// // -> "23:59:57.000000"
/// ```
pub fn from_duration(duration: duration.Duration) -> tempo.Time {
  duration |> tempo.duration_get_microseconds |> tempo.time_from_microseconds
}

/// Compares two time values.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("13:42:11")
/// |> time.compare(to: time.literal("13:42:11"))
/// // -> order.Eq
/// ```
/// 
/// ```gleam
/// time.literal("15:32:01")
/// |> time.compare(to: time.literal("13:42:11"))
/// // -> order.Gt
/// ```
/// 
/// ```gleam
/// time.literal("13:10:11")
/// |> time.compare(to: time.literal("13:42:11"))
/// // -> order.Lt
/// ```
pub fn compare(a: tempo.Time, to b: tempo.Time) -> order.Order {
  tempo.time_compare(a, to: b)
}

/// Checks if the first time is earlier than the second time.
///
/// ## Example
///
/// ```gleam
/// time.literal("13:42:11")
/// |> time.is_earlier(than: time.literal("13:42:12"))
/// // -> True
/// ```
///
/// ```gleam
/// time.literal("13:42:11")
/// |> time.is_earlier(than: time.literal("13:42:11"))
/// // -> False
/// ```
///
/// ```gleam
/// time.literal("13:22:15")
/// |> time.is_earlier(than: time.literal("07:42:11"))
/// // -> False
/// ```
pub fn is_earlier(a: tempo.Time, than b: tempo.Time) -> Bool {
  tempo.time_is_earlier(a, than: b)
}

/// Checks if the first time is earlier or equal to the second time.
///
/// ## Example
///
/// ```gleam
/// time.literal("13:42:11")
/// |> time.is_earlier_or_equal(to: time.literal("13:42:12"))
/// // -> True
/// ```
///
/// ```gleam
/// time.literal("13:42:11")
/// |> time.is_earlier_or_equal(to: time.literal("13:42:11.000"))
/// // -> True
/// ```
///
/// ```gleam
/// time.literal("13:22:15")
/// |> time.is_earlier_or_equal(to: time.literal("07:42:12"))
/// // -> False
pub fn is_earlier_or_equal(a: tempo.Time, to b: tempo.Time) -> Bool {
  tempo.time_is_earlier_or_equal(a, to: b)
}

/// Checks if the first time is equal to the second time.
///
/// ## Example
///
/// ```gleam
/// time.literal("13:42:11.000")
/// |> time.is_equal(to: time.literal("13:42:11"))
/// // -> True
/// ```
///
/// ```gleam
/// time.literal("13:42:11.002")
/// |> time.is_equal(to: time.literal("13:42:11"))
/// // -> False
/// ```
pub fn is_equal(a: tempo.Time, to b: tempo.Time) -> Bool {
  tempo.time_is_equal(a, to: b)
}

/// Checks if the first time is later than the second time.
///
/// ## Example
///
/// ```gleam
/// time.literal("13:22:15")
/// |> time.is_later(than: time.literal("07:42:11"))
/// // -> True
/// ```
/// 
/// ```gleam
/// time.literal("13:42:11")
/// |> time.is_later(than: time.literal("13:42:12"))
/// // -> False
/// ```
///
/// ```gleam
/// time.literal("13:42:11")
/// |> time.is_later(than: time.literal("13:42:11"))
/// // -> False
/// ```
pub fn is_later(a: tempo.Time, than b: tempo.Time) -> Bool {
  tempo.time_is_later(a, than: b)
}

/// Checks if the first time is earlier or equal to the second time.
///
/// ## Example
///
/// ```gleam
/// time.literal("13:22:15")
/// |> time.is_later_or_equal(to: time.literal("07:42:12"))
/// // -> True
///
/// ```gleam
/// time.literal("13:42")
/// |> time.is_later_or_equal(to: time.literal("13:42:00.000"))
/// // -> True
/// ```
/// 
/// ```gleam
/// time.literal("13:42:11")
/// |> time.is_later_or_equal(to: time.literal("13:42:12"))
/// // -> False
/// ```
pub fn is_later_or_equal(a: tempo.Time, to b: tempo.Time) -> Bool {
  tempo.time_is_later_or_equal(a, to: b)
}

pub type Boundary {
  Boundary(time: tempo.Time, inclusive: Bool)
}

/// Checks if a time is between two boundaries.
/// 
/// ## Example
///
/// ```gleam
/// time.literal("13:42:11")
/// |> time.is_between(
///     Boundary(time.literal("05:00:00"), inclusive: True), 
///     and: Boundary(time.literal("15:00:00"), inclusive: False),
///   )
/// // -> True
/// ```
pub fn is_between(time: tempo.Time, start: Boundary, and end: Boundary) -> Bool {
  case start.inclusive {
    True -> is_later_or_equal(time, to: start.time)
    False -> is_later(time, than: start.time)
  }
  && case end.inclusive {
    True -> is_earlier_or_equal(time, to: end.time)
    False -> is_earlier(time, than: end.time)
  }
}

/// Checks if a time is outside of two boundaries.
/// 
/// ## Example
///
/// ```gleam
/// time.literal("13:42:11")
/// |> time.is_outside(
///     time.Boundary(time.literal("05:00:00"), inclusive: True), 
///     and: time.Boundary(time.literal("15:00:00"), inclusive: False),
///   )
/// // -> False
/// ```
pub fn is_outside(time: tempo.Time, start: Boundary, and end: Boundary) -> Bool {
  case start.inclusive {
    True -> is_earlier_or_equal(time, to: start.time)
    False -> is_earlier(time, than: start.time)
  }
  || case end.inclusive {
    True -> is_later_or_equal(time, to: end.time)
    False -> is_later(time, than: end.time)
  }
}

/// Gets the difference between two times as a duration. Always prefer using
/// `duration.start_monotonic` and `duration.stop_monotonic` to record live 
/// time passing, as it is more precise.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("23:42:11.435")
/// |> time.difference(from: time.literal("23:42:09.743"))
/// |> duration.as_milliseconds
/// // -> 1692
/// ```
/// 
/// ```gleam
/// time.literal("13:30:11")
/// |> time.difference(from: time.literal("13:55:13"))
/// |> duration.as_minutes
/// // -> -25
/// ```
pub fn difference(from a: tempo.Time, to b: tempo.Time) -> duration.Duration {
  tempo.time_difference(from: a, to: b)
}

/// Gets the absolute difference between two times as a duration.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("23:42:11.435")
/// |> time.difference(from: time.literal("23:42:09.743"))
/// |> duration.as_milliseconds
/// // -> 1692
/// ```
/// 
/// ```gleam
/// time.literal("13:30:11")
/// |> time.difference(from: time.literal("13:55:13"))
/// |> duration.as_minutes
/// // -> 25
/// ```
pub fn difference_abs(a: tempo.Time, from b: tempo.Time) -> duration.Duration {
  case tempo.time_to_microseconds(a) - tempo.time_to_microseconds(b) {
    diff if diff < 0 -> -diff |> tempo.duration_microseconds
    diff -> diff |> tempo.duration_microseconds
  }
}

/// Adds a duration to a time.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("08:42:53")
/// |> time.add(duration.mintues(36))
/// // -> time.literal("09:18:53")
/// ```
pub fn add(a: tempo.Time, duration b: duration.Duration) -> tempo.Time {
  tempo.time_add(a, duration: b)
}

/// Subtracts a duration from a time.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("13:42:02")
/// |> time.subtract(duration.hours(2))
/// // -> time.literal("11:42:02")
/// ```
pub fn subtract(a: tempo.Time, duration b: duration.Duration) -> tempo.Time {
  tempo.time_subtract(a, duration: b)
}

/// Converts a time to the equivalent time left in the day.
///
/// ## Example
///
/// ```gleam
/// time.literal("23:59:03") |> time.left_in_day
/// // -> time.literal("00:00:57")
/// ```
///
/// ```gleam
/// time.literal("08:05:20") |> time.left_in_day
/// // -> time.literal("15:54:40")
/// ```
pub fn left_in_day(time: tempo.Time) -> tempo.Time {
  unit.day_microseconds - { time |> tempo.time_to_microseconds }
  |> tempo.time_from_microseconds
}

/// Returns a duration representing the time left from the first time 
/// until a given time. 
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("23:54:00")
/// |> time.until(time.literal("23:59:04"))
/// |> duration.as_seconds
/// // -> 304
/// ```
/// 
/// ```gleam
/// time.literal("23:59:03")
/// |> time.until(time.literal("22:00:00"))
/// |> duration.as_milliseconds
/// // -> 0
/// ```
pub fn until(time: tempo.Time, until: tempo.Time) -> duration.Duration {
  let dur = time |> difference(from: until) |> tempo_duration.inverse

  case dur |> tempo_duration.is_negative {
    True -> tempo_duration.microseconds(0)
    False -> dur
  }
}

/// Returns a duration representing the time since the first time to the 
/// given time.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("23:54:00")
/// |> time.since(time.literal("13:30:04"))
/// |> duration.as_hours
/// // -> 10
/// ```
/// 
/// ```gleam
/// time.literal("12:30:54")
/// |> time.since(time.literal("22:00:00"))
/// |> duration.as_milliseconds
/// // -> 0
/// ```
pub fn since(
  time time: tempo.Time,
  since since: tempo.Time,
) -> duration.Duration {
  let dur = time |> difference(from: since)

  case dur |> tempo_duration.is_negative {
    True -> tempo_duration.microseconds(0)
    False -> dur
  }
}
