//// Functions to use with the `Time` type in Tempo. The time values are wall
//// time values unless explicitly stated otherwise.
//// 
//// ## Example
//// 
//// ```gleam
//// import tempo/time
//// 
//// pub fn is_past_5pm() {
////   time.now_utc()
////   |> time.is_later(than: time.literal("17:00"))
//// }
//// ```
//// 
//// ```gleam
//// import tempo/time
//// 
//// pub fn get_enthusiastic_time() {
////   time.now_local()
////   |> time.format(
////     "[The hour is:] HH, [wow! And even better the minute is:] mm!"
////   )
////   // -> "The hour is: 13, wow! And even better the minute is: 42!"
//// }
//// ```
//// 
//// ```gleam
//// import tempo/time
//// 
//// pub fn run_task() {
////   let resuult = do_long_task()
//// 
////   let end_time = time.now_unique()
//// 
////   #(end_time, resuult)
//// }
//// // -> These tasks are now sortable by end time
//// ```

import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/regex
import gleam/result
import gleam/string
import gleam/string_builder
import gtempo/internal as unit
import tempo
import tempo/date
import tempo/duration
import tempo/offset

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
/// // -> Error(tempo.TimeOutOfBounds)
/// ```
pub fn new(
  hour: Int,
  minute: Int,
  second: Int,
) -> Result(tempo.Time, tempo.Error) {
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
/// // -> Error(tempo.TimeOutOfBounds)
/// ```
pub fn new_milli(
  hour: Int,
  minute: Int,
  second: Int,
  millisecond: Int,
) -> Result(tempo.Time, tempo.Error) {
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
/// // -> Ok(time.literal("13:42:11.200000"))
/// ```
/// 
/// ```gleam
/// time.new_micro(13, 42, 11, 7_500_000)
/// // -> Error(tempo.TimeOutOfBounds)
/// ```
pub fn new_micro(
  hour: Int,
  minute: Int,
  second: Int,
  microsecond: Int,
) -> Result(tempo.Time, tempo.Error) {
  tempo.new_time_micro(hour, minute, second, microsecond)
}

/// Creates a new time value with nanosecond precision.
/// 
/// ## Example
/// 
/// ```gleam
/// time.new_nano(13, 42, 11, 20)
/// // -> Ok(time.literal("13:42:11.000000020"))
/// ```
/// 
/// ```gleam
/// time.new_nano(13, 42, 11, 200_000_000)
/// // -> Ok(time.literal("13:42:11.200000000"))
/// ```
/// 
/// ```gleam
/// time.new_nano(13, 42, 11, 7_500_000_000)
/// // -> Error(tempo.TimeOutOfBounds)
/// ```
pub fn new_nano(
  hour: Int,
  minute: Int,
  second: Int,
  nanosecond: Int,
) -> Result(tempo.Time, tempo.Error) {
  tempo.new_time_nano(hour, minute, second, nanosecond)
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
    Error(tempo.TimeInvalidFormat) -> panic as "Invalid time literal format"
    Error(tempo.TimeOutOfBounds) -> panic as "Invalid time literal value"
    Error(_) -> panic as "Invalid time literal"
  }
}

/// Gets the UTC wall time of the host.
///
/// ## Example
/// 
/// ```gleam
/// case 
///   time.now_utc() 
///   |> time.is_later(than: time.literal("11:50:00")) 
/// { 
///   True -> "We are all late!"
///   False -> "No rush :)"
/// }
/// ```
pub fn now_utc() {
  let now_ts_nano = tempo.now_utc()
  let date_ts_nano =
    { date.to_unix_utc(date.from_unix_utc(now_ts_nano / 1_000_000_000)) }
    * 1_000_000_000

  // Subtract the nanoseconds that are responsible for the date and the local
  // offset nanoseconds.
  from_nanoseconds(now_ts_nano - date_ts_nano)
}

/// Gets the local wall time of the host.
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
pub fn now_local() {
  let now_ts_nano = tempo.now_utc()
  let date_ts_nano =
    { date.to_unix_utc(date.from_unix_utc(now_ts_nano / 1_000_000_000)) }
    * 1_000_000_000

  // Subtract the nanoseconds that are responsible for the date and the local
  // offset nanoseconds.
  from_nanoseconds(now_ts_nano - date_ts_nano + offset.local_nano())
}

/// Gets the monotonic time of the host on the Erlang target. Returns the
/// current UTC wall time in nanoseconds on the JavaScript target becuase 
/// monotonic time in JavaScript is dependent on the runtime. Monotonic time
///  is useful for timing events; `now_utc` and `now_local` should not be
/// used for timing events. The `duration` module has nicer functions to use
/// for timing events and should be preferred over this function.
/// 
/// ## Example
/// 
/// ```gleam
/// time.now_monotonic()
/// // -> -576_460_750_802_442_634
/// ```
pub fn now_monotonic() {
  tempo.now_monotonic()
}

/// Gets a positive unique integer based on the monotonic time of the 
/// Erlang VM on the Erlang target. Returns the a value that starts at 1 and
/// increments by 1 with each call on the JavaScript target. This is useful
/// for tagging and then ordering events by time, but should not be assumed
/// to represent wall time.
/// 
/// ## Example
/// 
/// ```gleam
/// time.now_unique()
/// // -> 1
/// 
/// time.now_unique()
/// // -> 2
/// ```
pub fn now_unique() {
  tempo.now_unique()
}

/// Early on these were part of the public API and used in a lot of tests, 
/// but since have been removed from the public API. The tests should be 
/// updated and these functions removed.
@internal
pub fn test_literal(hour: Int, minute: Int, second: Int) -> tempo.Time {
  let assert Ok(time) =
    tempo.time(hour, minute, second, 0, tempo.Sec) |> validate
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
    tempo.time(hour, minute, second, millisecond * 1_000_000, tempo.Milli)
    |> validate
  time
}

@internal
pub fn test_literal_micro(
  hour: Int,
  minute: Int,
  second: Int,
  microsecond: Int,
) -> tempo.Time {
  let assert Ok(time) =
    tempo.time(hour, minute, second, microsecond * 1000, tempo.Micro)
    |> validate
  time
}

@internal
pub fn test_literal_nano(
  hour: Int,
  minute: Int,
  second: Int,
  nanosecond: Int,
) -> tempo.Time {
  let assert Ok(time) =
    tempo.time(hour, minute, second, nanosecond, tempo.Nano) |> validate
  time
}

fn validate(time: tempo.Time) -> Result(tempo.Time, tempo.Error) {
  tempo.validate_time(time)
}

/// I made this but idk if it should be in the public API, it may lead people
/// to anti-patterns.
@internal
pub fn set_hour(time: tempo.Time, hour: Int) -> Result(tempo.Time, tempo.Error) {
  case time |> tempo.time_get_prec {
    tempo.Sec ->
      new(hour, time |> tempo.time_get_minute, time |> tempo.time_get_second)
    tempo.Milli ->
      new_milli(
        hour,
        time |> tempo.time_get_minute,
        time |> tempo.time_get_second,
        time |> tempo.time_get_nano,
      )
    tempo.Micro ->
      new_micro(
        hour,
        time |> tempo.time_get_minute,
        time |> tempo.time_get_second,
        time |> tempo.time_get_nano,
      )
    tempo.Nano ->
      new_nano(
        hour,
        time |> tempo.time_get_minute,
        time |> tempo.time_get_second,
        time |> tempo.time_get_nano,
      )
  }
}

/// I made this but idk if it should be in the public API, it may lead people
/// to anti-patterns.
@internal
pub fn set_minute(
  time: tempo.Time,
  minute: Int,
) -> Result(tempo.Time, tempo.Error) {
  case time |> tempo.time_get_prec {
    tempo.Sec ->
      new(time |> tempo.time_get_hour, minute, time |> tempo.time_get_second)
    tempo.Milli ->
      new_milli(
        time |> tempo.time_get_hour,
        minute,
        time |> tempo.time_get_second,
        time |> tempo.time_get_nano,
      )
    tempo.Micro ->
      new_micro(
        time |> tempo.time_get_hour,
        minute,
        time |> tempo.time_get_second,
        time |> tempo.time_get_nano,
      )
    tempo.Nano ->
      new_nano(
        time |> tempo.time_get_hour,
        minute,
        time |> tempo.time_get_second,
        time |> tempo.time_get_nano,
      )
  }
}

/// I made this but idk if it should be in the public API, it may lead people
/// to anti-patterns.
@internal
pub fn set_second(
  time: tempo.Time,
  second: Int,
) -> Result(tempo.Time, tempo.Error) {
  case time |> tempo.time_get_prec {
    tempo.Sec ->
      new(time |> tempo.time_get_hour, time |> tempo.time_get_minute, second)
    tempo.Milli ->
      new_milli(
        time |> tempo.time_get_hour,
        time |> tempo.time_get_minute,
        second,
        time |> tempo.time_get_nano,
      )
    tempo.Micro ->
      new_micro(
        time |> tempo.time_get_hour,
        time |> tempo.time_get_minute,
        second,
        time |> tempo.time_get_nano,
      )
    tempo.Nano ->
      new_nano(
        time |> tempo.time_get_hour,
        time |> tempo.time_get_minute,
        second,
        time |> tempo.time_get_nano,
      )
  }
}

/// I made this but idk if it should be in the public API, it may lead people
/// to anti-patterns.
@internal
pub fn set_milli(
  time: tempo.Time,
  millisecond: Int,
) -> Result(tempo.Time, tempo.Error) {
  new_milli(
    time |> tempo.time_get_hour,
    time |> tempo.time_get_minute,
    time |> tempo.time_get_second,
    millisecond,
  )
}

/// I made this but idk if it should be in the public API, it may lead people
/// to anti-patterns.
@internal
pub fn set_micro(
  time: tempo.Time,
  microsecond: Int,
) -> Result(tempo.Time, tempo.Error) {
  new_micro(
    time |> tempo.time_get_hour,
    time |> tempo.time_get_minute,
    time |> tempo.time_get_second,
    microsecond,
  )
}

/// I made this but idk if it should be in the public API, it may lead people
/// to anti-patterns.
@internal
pub fn set_nano(
  time: tempo.Time,
  nanosecond: Int,
) -> Result(tempo.Time, tempo.Error) {
  new_nano(
    time |> tempo.time_get_hour,
    time |> tempo.time_get_minute,
    time |> tempo.time_get_second,
    nanosecond,
  )
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

/// Gets the nanosecond value of a time.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("13:42:11.123")
/// |> time.get_nanosecond
/// // -> 123000000
/// ```
pub fn get_nanosecond(time: tempo.Time) -> Int {
  time |> tempo.time_get_nano
}

/// Sets the time to a second precision. Drops any milliseconds from the
/// underlying time value.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("21:53:30.730673092")
/// |> time.to_second_precision
/// |> time.to_string
/// // -> "21:53:30"
/// ```
pub fn to_second_precision(time: tempo.Time) -> tempo.Time {
  // Drop any milliseconds
  tempo.time(
    time |> tempo.time_get_hour,
    time |> tempo.time_get_minute,
    time |> tempo.time_get_second,
    0,
    tempo.Sec,
  )
}

/// Sets the time to a millisecond precision. Drops any microseconds from the
/// underlying time value.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("21:53:03.530673092")
/// |> time.to_milli_precision
/// |> time.to_string
/// // -> "21:53:03.530"
/// ```
pub fn to_milli_precision(time: tempo.Time) -> tempo.Time {
  tempo.time(
    time |> tempo.time_get_hour,
    time |> tempo.time_get_minute,
    time |> tempo.time_get_second,
    // Drop any microseconds
    { tempo.time_get_nano(time) / 1_000_000 } * 1_000_000,
    tempo.Milli,
  )
}

/// Sets the time to a microsecond precision. Drops any nanoseconds from the
/// underlying time value.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("21:53:03.534670892")
/// |> time.to_micro_precision
/// |> time.to_string
/// // -> "21:53:03.534670"
/// ```
pub fn to_micro_precision(time: tempo.Time) -> tempo.Time {
  tempo.time(
    time |> tempo.time_get_hour,
    time |> tempo.time_get_minute,
    time |> tempo.time_get_second,
    // Drop any nanoseconds
    { tempo.time_get_nano(time) / 1000 } * 1000,
    tempo.Micro,
  )
}

/// Sets the time to a nanosecond precision. Does not alter the underlying 
/// time value.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("21:53:03.534")
/// |> time.to_nano_precision
/// |> time.to_string
/// // -> "21:53:03.534000000"
/// ```
pub fn to_nano_precision(time: tempo.Time) -> tempo.Time {
  tempo.time(
    time |> tempo.time_get_hour,
    time |> tempo.time_get_minute,
    time |> tempo.time_get_second,
    time |> tempo.time_get_nano,
    tempo.Nano,
  )
}

/// Converts a time value to a string in the format `hh:mm:ss.s`
/// 
/// ## Example
/// 
/// ```gleam
/// time.to_string(my_time)
/// |> time.to_string
/// // -> "21:53:03.534"
/// ```
pub fn to_string(time: tempo.Time) -> String {
  let sb =
    string_builder.from_strings([
      time
        |> tempo.time_get_hour
        |> int.to_string
        |> string.pad_left(2, with: "0"),
      ":",
      time
        |> tempo.time_get_minute
        |> int.to_string
        |> string.pad_left(2, with: "0"),
      ":",
      time
        |> tempo.time_get_second
        |> int.to_string
        |> string.pad_left(2, with: "0"),
    ])

  case time |> tempo.time_get_prec {
    tempo.Sec -> sb
    tempo.Milli ->
      string_builder.append(sb, ".")
      |> string_builder.append(
        { tempo.time_get_nano(time) / 1_000_000 }
        |> int.to_string
        |> string.pad_left(3, with: "0"),
      )
    tempo.Micro ->
      string_builder.append(sb, ".")
      |> string_builder.append(
        { tempo.time_get_nano(time) / 1000 }
        |> int.to_string
        |> string.pad_left(6, with: "0"),
      )
    tempo.Nano ->
      string_builder.append(sb, ".")
      |> string_builder.append(
        tempo.time_get_nano(time)
        |> int.to_string
        |> string.pad_left(9, with: "0"),
      )
  }
  |> string_builder.to_string
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
/// // -> Error(tempo.TimeOutOfBounds)
/// ```
pub fn from_string(time: String) -> Result(tempo.Time, tempo.Error) {
  use #(hour, minute, second): #(String, String, String) <- result.try(
    // Parse hh:mm:ss.s or hh:mm format
    case string.split(time, ":") {
      [hour, minute, second] -> Ok(#(hour, minute, second))
      [hour, minute] -> Ok(#(hour, minute, "0"))
      _ -> Error(tempo.TimeInvalidFormat)
    }
    // Parse hhmmss.s or hhmm format
    |> result.try_recover(fn(_) {
      case string.length(time), string.contains(time, ".") {
        6, False ->
          Ok(#(
            string.slice(time, at_index: 0, length: 2),
            string.slice(time, at_index: 2, length: 2),
            string.slice(time, at_index: 4, length: 2),
          ))
        4, False ->
          Ok(#(
            string.slice(time, at_index: 0, length: 2),
            string.slice(time, at_index: 2, length: 2),
            "0",
          ))
        l, True if l >= 7 ->
          Ok(#(
            string.slice(time, at_index: 0, length: 2),
            string.slice(time, at_index: 2, length: 2),
            string.slice(time, at_index: 4, length: 12),
          ))
        _, _ -> Error(tempo.TimeInvalidFormat)
      }
    }),
  )

  case int.parse(hour), int.parse(minute), string.split(second, ".") {
    Ok(hour), Ok(minute), [second, second_fraction] -> {
      let second_fraction_length = string.length(second_fraction)
      case second_fraction_length {
        len if len <= 3 ->
          case
            int.parse(second),
            int.parse(second_fraction |> string.pad_right(3, with: "0"))
          {
            Ok(second), Ok(milli) ->
              Ok(tempo.time(
                hour,
                minute,
                second,
                milli * 1_000_000,
                tempo.Milli,
              ))
            _, _ -> Error(tempo.TimeInvalidFormat)
          }
        len if len <= 6 ->
          case
            int.parse(second),
            int.parse(second_fraction |> string.pad_right(6, with: "0"))
          {
            Ok(second), Ok(micro) ->
              Ok(tempo.time(hour, minute, second, micro * 1000, tempo.Micro))
            _, _ -> Error(tempo.TimeInvalidFormat)
          }
        len if len <= 9 ->
          case
            int.parse(second),
            int.parse(second_fraction |> string.pad_right(9, with: "0"))
          {
            Ok(second), Ok(nano) ->
              Ok(tempo.time(hour, minute, second, nano, tempo.Nano))
            _, _ -> Error(tempo.TimeInvalidFormat)
          }
        _ -> Error(tempo.TimeInvalidFormat)
      }
    }

    Ok(hour), Ok(minute), _ ->
      case int.parse(second) {
        Ok(second) -> Ok(tempo.time(hour, minute, second, 0, tempo.Sec))
        _ -> Error(tempo.TimeInvalidFormat)
      }

    _, _, _ -> Error(tempo.TimeInvalidFormat)
  }
  |> result.try(validate)
}

/// Parses a time string in the provided format. Always prefer using
/// this over `parse_any`. All parsed formats must have an hour and a second.
/// 
/// Values can be escaped by putting brackets around them, like "[Hello!] HH".
/// 
/// Available directives: H (hour), HH (two-digit hour), h (12-hour clock hour), hh 
/// (two-digit 12-hour clock hour), m (minute), mm (two-digit minute),
/// s (second), ss (two-digit second), SSS (millisecond), SSSS (microsecond), 
/// SSSSS (nanosecond), A (AM/PM), a (am/pm),
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
/// // -> Error(tempo.ParseMissingTime)
/// ```
/// 
/// ```gleam
/// time.parse("Hi! 12 2 am", "[Hi!] h m a")
/// // -> Ok(time.literal("00:02:00"))
/// ```
pub fn parse(str: String, in fmt: String) -> Result(tempo.Date, tempo.Error) {
  use #(parts, _) <- result.try(tempo.consume_format(str, in: fmt))

  tempo.find_date(in: parts)
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
pub fn parse_any(str: String) -> Result(tempo.Time, tempo.Error) {
  case tempo.parse_any(str) {
    Ok(#(_, Some(time), _)) -> Ok(time)
    Ok(#(_, None, _)) -> Error(tempo.ParseMissingTime)
    Error(err) -> Error(err)
  }
}

/// Formats a time value using the provided format string.
/// Implements the same formatting directives as the great Day.js 
/// library: https://day.js.org/docs/en/display/format.
/// 
/// Values can be escaped by putting brackets around them, like "[Hello!] HH".
/// 
/// Available directives: H (hour), HH (two-digit hour), h (12-hour clock hour),
/// hh (two-digit 12-hour clock hour), m (minute), mm (two-digit minute),
/// s (second), ss (two-digit second), SSS (millisecond), SSSS (microsecond), 
/// SSSSS (nanosecond), A (AM/PM), a (am/pm).
/// 
/// ## Example
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
pub fn format(time: tempo.Time, in fmt: String) -> String {
  let assert Ok(re) = regex.from_string(tempo.format_regex)

  regex.scan(re, fmt)
  |> list.reverse
  |> list.fold(from: [], with: fn(acc, match) {
    case match {
      regex.Match(content, []) -> [replace_format(content, time), ..acc]

      // If there is a non-empty subpattern, then the escape 
      // character "[ ... ]" matched, so we should not change anything here.
      regex.Match(_, [Some(sub)]) -> [sub, ..acc]

      // This case is not expected, not really sure what to do with it 
      // so just prepend whatever was found
      regex.Match(content, _) -> [content, ..acc]
    }
  })
  |> string.join("")
}

@internal
pub fn replace_format(content: String, time) -> String {
  case content {
    "H" -> time |> get_hour |> int.to_string
    "HH" ->
      time
      |> get_hour
      |> int.to_string
      |> string.pad_left(with: "0", to: 2)
    "h" ->
      time
      |> get_hour
      |> fn(hour) {
        case hour {
          _ if hour == 0 -> 12
          _ if hour > 12 -> hour - 12
          _ -> hour
        }
      }
      |> int.to_string
    "hh" ->
      time
      |> get_hour
      |> fn(hour) {
        case hour {
          _ if hour == 0 -> 12
          _ if hour > 12 -> hour - 12
          _ -> hour
        }
      }
      |> int.to_string
      |> string.pad_left(with: "0", to: 2)
    "a" ->
      time
      |> get_hour
      |> fn(hour) {
        case hour >= 12 {
          True -> "pm"
          False -> "am"
        }
      }
    "A" ->
      time
      |> get_hour
      |> fn(hour) {
        case hour >= 12 {
          True -> "PM"
          False -> "AM"
        }
      }
    "m" -> time |> get_minute |> int.to_string
    "mm" ->
      time
      |> get_minute
      |> int.to_string
      |> string.pad_left(with: "0", to: 2)
    "s" -> time |> get_second |> int.to_string
    "ss" ->
      time
      |> get_second
      |> int.to_string
      |> string.pad_left(with: "0", to: 2)
    "SSS" ->
      time
      |> get_nanosecond
      |> fn(nano) { nano / 1_000_000 }
      |> int.to_string
      |> string.pad_left(with: "0", to: 3)
    "SSSS" ->
      time
      |> get_nanosecond
      |> fn(nano) { nano / 1000 }
      |> int.to_string
      |> string.pad_left(with: "0", to: 6)
    "SSSSS" ->
      time
      |> get_nanosecond
      |> int.to_string
      |> string.pad_left(with: "0", to: 9)
    _ -> content
  }
}

/// Gets the UTC time value of a unix timestamp. If the local time is needed,
/// use the 'datetime' module's 'to_local_time' function.
/// 
/// ## Example
/// 
/// ```gleam
/// time.from_unix_utc(1_718_829_395)
/// // -> time.literal("20:36:35")
/// ```
/// 
/// I am making this internal because it is created but I am not sure if it
/// should be part of the public API. I think it is too easy to use incorrectly.
/// Users should probably use the 'datetime' module's 'from_unix_utc' function
/// instead and get the time from there if they need it.
@internal
pub fn from_unix_utc(unix_ts: Int) -> tempo.Time {
  // Subtract the nanoseconds that are responsible for the date.
  { unix_ts - { date.to_unix_utc(date.from_unix_utc(unix_ts)) } }
  * 1_000_000_000
  |> from_nanoseconds
  |> to_second_precision
}

/// Gets the UTC time value of a unix timestamp in milliseconds. If the local
/// time is needed, use the 'datetime' module's 'to_local_time' function.
/// 
/// ## Example
/// 
/// ```gleam
/// time.from_unix_milli_utc(1_718_829_586_791)
/// // -> time.literal("20:39:46.791")
/// ```
/// 
/// I am making this internal because it is created but I am not sure if it
/// should be part of the public API. I think it is too easy to use incorrectly.
/// Users should probably use the 'datetime' module's 'from_unix_utc' function
/// instead and get the time from there if they need it.
@internal
pub fn from_unix_milli_utc(unix_ts: Int) -> tempo.Time {
  // Subtract the nanoseconds that are responsible for the date.
  { unix_ts - { date.to_unix_milli_utc(date.from_unix_milli_utc(unix_ts)) } }
  * 1_000_000
  |> from_nanoseconds
  |> to_milli_precision
}

/// Gets the UTC time value of a unix timestamp in microseconds. If the local
/// time is needed, use the 'datetime' module's 'to_local_time' function.
/// 
/// ## Example
/// 
/// ```gleam
/// time.from_unix_micro_utc(1_718_829_586_791_832)
/// // -> time.literal("20:39:46.791832")
/// ```
/// 
/// I am making this internal because it is created but I am not sure if it
/// should be part of the public API. I think it is too easy to use incorrectly.
/// Users should probably use the 'datetime' module's 'from_unix_utc' function
/// instead and get the time from there if they need it.
@internal
pub fn from_unix_micro_utc(unix_ts: Int) -> tempo.Time {
  // Subtract the nanoseconds that are responsible for the date.
  { unix_ts - { date.to_unix_micro_utc(date.from_unix_micro_utc(unix_ts)) } }
  * 1000
  |> from_nanoseconds
  |> to_micro_precision
}

/// Gets the UTC time value of a unix timestamp in nanoseconds. If the local
/// time is needed, use the 'datetime' module's 'to_local_time' function.
/// 
/// ## Example
/// 
/// ```gleam
/// time.from_unix_micro_utc(1_718_829_586_791_832)
/// // -> time.literal("20:39:46.791832")
/// ```
/// 
/// I am making this internal because it is created but I am not sure if it
/// should be part of the public API. I think it is too easy to use incorrectly.
/// Users should probably use the 'datetime' module's 'from_unix_utc' function
/// instead and get the time from there if they need it.
@internal
pub fn from_unix_nano_utc(unix_ts: Int) -> tempo.Time {
  // Subtract the nanoseconds that are responsible for the date.
  {
    unix_ts
    - { date.to_unix_micro_utc(date.from_unix_micro_utc(unix_ts / 1000)) }
    * 1000
  }
  |> from_nanoseconds
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
pub fn from_tuple(time: #(Int, Int, Int)) -> Result(tempo.Time, tempo.Error) {
  new(time.0, time.1, time.2)
}

/// Returns a time value as a tuple of hours, minutes, seconds, and nanoseconds. 
/// Useful for using with another time library.
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("13:42:11.872")
/// |> time.to_tuple_nanosecond
/// // -> #(13, 42, 11, 872000000)
/// ```
pub fn to_tuple_nanosecond(time: tempo.Time) -> #(Int, Int, Int, Int) {
  #(
    time |> tempo.time_get_hour,
    time |> tempo.time_get_minute,
    time |> tempo.time_get_second,
    time |> tempo.time_get_nano,
  )
}

/// Converts a tuple of hours, minutes, seconds, and nanoseconds to a time 
/// value. Useful for using with another time library.
/// 
/// ## Example
/// 
/// ```gleam
/// #(13, 42, 11, 872000000)
/// |> time.from_tuple_nanosecond
/// |> time.to_milli_precision
/// // -> time.literal("13:42:11.872")
/// ```
pub fn from_tuple_nanosecond(
  time: #(Int, Int, Int, Int),
) -> Result(tempo.Time, tempo.Error) {
  new_nano(time.0, time.1, time.2, time.3)
}

/// Converts a time to duration, assuming the duration epoch is "00:00:00".
/// 
/// ## Example
/// 
/// ```gleam
/// time.literal("00:00:00.000000300")
/// |> time.to_duration
/// |> duration.as_nanoseconds
/// // -> 300
/// ```
///
/// ```gleam
/// time.literal("00:03:06")
/// |> time.to_duration 
/// |> duration.as_milliseconds
/// // -> 186_000
/// ```
pub fn to_duration(time: tempo.Time) -> tempo.Duration {
  to_nanoseconds(time) |> tempo.duration
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
/// duration.nanoseconds(-3_000_000_000)
/// |> time.from_duration
/// |> time.to_string
/// // -> "23:59:57.000000000"
/// ```
pub fn from_duration(duration: tempo.Duration) -> tempo.Time {
  duration |> tempo.duration_get_ns |> from_nanoseconds
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
  case a |> tempo.time_get_hour == b |> tempo.time_get_hour {
    True ->
      case a |> tempo.time_get_minute == b |> tempo.time_get_minute {
        True ->
          case a |> tempo.time_get_second == b |> tempo.time_get_second {
            True ->
              case a |> tempo.time_get_nano == b |> tempo.time_get_nano {
                True -> order.Eq
                False ->
                  case a |> tempo.time_get_nano < b |> tempo.time_get_nano {
                    True -> order.Lt
                    False -> order.Gt
                  }
              }
            False ->
              case a |> tempo.time_get_second < b |> tempo.time_get_second {
                True -> order.Lt
                False -> order.Gt
              }
          }
        False ->
          case a |> tempo.time_get_minute < b |> tempo.time_get_minute {
            True -> order.Lt
            False -> order.Gt
          }
      }
    False ->
      case a |> tempo.time_get_hour < b |> tempo.time_get_hour {
        True -> order.Lt
        False -> order.Gt
      }
  }
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
  compare(a, b) == order.Lt
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
  compare(a, b) == order.Lt || compare(a, b) == order.Eq
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
  compare(a, b) == order.Eq
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
  compare(a, b) == order.Gt
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
  compare(a, b) == order.Gt || compare(a, b) == order.Eq
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

/// Gets the difference between two times as a duration.
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
pub fn difference(a: tempo.Time, from b: tempo.Time) -> tempo.Duration {
  to_nanoseconds(a) - to_nanoseconds(b) |> tempo.duration
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
pub fn difference_abs(a: tempo.Time, from b: tempo.Time) -> tempo.Duration {
  case to_nanoseconds(a) - to_nanoseconds(b) {
    diff if diff < 0 -> -diff |> tempo.duration
    diff -> diff |> tempo.duration
  }
}

@internal
pub fn to_nanoseconds(time: tempo.Time) -> Int {
  { tempo.time_get_hour(time) * unit.hour_nanoseconds }
  + { tempo.time_get_minute(time) * unit.minute_nanoseconds }
  + { tempo.time_get_second(time) * unit.second_nanoseconds }
  + tempo.time_get_nano(time)
}

@internal
pub fn from_nanoseconds(nanoseconds: Int) -> tempo.Time {
  let in_range_ns = nanoseconds % unit.imprecise_day_nanoseconds

  let adj_ns = case in_range_ns < 0 {
    True -> in_range_ns + unit.imprecise_day_nanoseconds
    False -> in_range_ns
  }

  let hours = adj_ns / 3_600_000_000_000

  let minutes = { adj_ns - hours * 3_600_000_000_000 } / 60_000_000_000

  let seconds =
    { adj_ns - hours * 3_600_000_000_000 - minutes * 60_000_000_000 }
    / 1_000_000_000

  let nanoseconds =
    adj_ns
    - hours
    * 3_600_000_000_000
    - minutes
    * 60_000_000_000
    - seconds
    * 1_000_000_000

  tempo.time(hours, minutes, seconds, nanoseconds, tempo.Nano)
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
pub fn add(a: tempo.Time, duration b: tempo.Duration) -> tempo.Time {
  let new_time =
    to_nanoseconds(a) + tempo.duration_get_ns(b) |> from_nanoseconds
  case a |> tempo.time_get_prec {
    tempo.Sec -> to_second_precision(new_time)
    tempo.Milli -> to_milli_precision(new_time)
    tempo.Micro -> to_micro_precision(new_time)
    tempo.Nano -> to_nano_precision(new_time)
  }
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
pub fn subtract(a: tempo.Time, duration b: tempo.Duration) -> tempo.Time {
  let new_time =
    to_nanoseconds(a) - tempo.duration_get_ns(b) |> from_nanoseconds
  // Restore original time precision
  case a |> tempo.time_get_prec {
    tempo.Sec -> to_second_precision(new_time)
    tempo.Milli -> to_milli_precision(new_time)
    tempo.Micro -> to_micro_precision(new_time)
    tempo.Nano -> to_nano_precision(new_time)
  }
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
  let new_time =
    unit.imprecise_day_nanoseconds - { time |> to_nanoseconds }
    |> from_nanoseconds

  // Restore original time precision
  case time |> tempo.time_get_prec {
    tempo.Sec -> to_second_precision(new_time)
    tempo.Milli -> to_milli_precision(new_time)
    tempo.Micro -> to_micro_precision(new_time)
    tempo.Nano -> to_nano_precision(new_time)
  }
}

/// Returns a duration representing the time left until a given time.
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
pub fn until(time: tempo.Time, until: tempo.Time) -> tempo.Duration {
  let dur = time |> difference(from: until) |> duration.inverse

  case dur |> duration.is_negative {
    True -> duration.nanoseconds(0)
    False -> dur
  }
}

/// Returns a duration representing the time since a given time.
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
pub fn since(time: tempo.Time, since: tempo.Time) -> tempo.Duration {
  let dur = time |> difference(from: since)

  case dur |> duration.is_negative {
    True -> duration.nanoseconds(0)
    False -> dur
  }
}
