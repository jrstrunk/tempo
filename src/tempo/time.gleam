import gleam/int
import gleam/order
import gleam/result
import gleam/string
import gleam/string_builder
import tempo
import tempo/date
import tempo/internal/unit
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
/// // -> Error(Nil)
/// ```
pub fn new(hour: Int, minute: Int, second: Int) -> Result(tempo.Time, Nil) {
  tempo.Time(hour, minute, second, 0) |> validate
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
/// // -> Error(Nil)
/// ```
pub fn new_milli(
  hour: Int,
  minute: Int,
  second: Int,
  millisecond: Int,
) -> Result(tempo.Time, Nil) {
  tempo.TimeMilli(hour, minute, second, millisecond * 1_000_000)
  |> validate
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
/// // -> Error(Nil)
/// ```
pub fn new_micro(
  hour: Int,
  minute: Int,
  second: Int,
  microsecond: Int,
) -> Result(tempo.Time, Nil) {
  tempo.TimeMicro(hour, minute, second, microsecond * 1000) |> validate
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
/// // -> Error(Nil)
/// ```
pub fn new_nano(
  hour: Int,
  minute: Int,
  second: Int,
  nanosecond: Int,
) -> Result(tempo.Time, Nil) {
  tempo.TimeNano(hour, minute, second, nanosecond) |> validate
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
    Error(Nil) -> panic as "Invalid time literal"
  }
}

/// Gets the UTC time of the host.
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

/// Gets the local time of the host.
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

/// Early on these were part of the public API and used in a lot of tests, 
/// but since have been removed from the public API. The tests should be 
/// updated and these functions removed.
@internal
pub fn test_literal(hour: Int, minute: Int, second: Int) -> tempo.Time {
  let assert Ok(time) = tempo.Time(hour, minute, second, 0) |> validate
  time
}

@internal
pub fn test_literal_milli(hour: Int, minute: Int, second: Int, millisecond: Int) -> tempo.Time {
  let assert Ok(time) =
    tempo.TimeMilli(hour, minute, second, millisecond * 1_000_000)
    |> validate
  time
}

@internal
pub fn test_literal_micro(hour: Int, minute: Int, second: Int, microsecond: Int) -> tempo.Time {
  let assert Ok(time) =
    tempo.TimeMicro(hour, minute, second, microsecond * 1000) |> validate
  time
}

@internal
pub fn test_literal_nano(hour: Int, minute: Int, second: Int, nanosecond: Int) -> tempo.Time {
  let assert Ok(time) =
    tempo.TimeNano(hour, minute, second, nanosecond) |> validate
  time
}

fn validate(time: tempo.Time) -> Result(tempo.Time, Nil) {
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
    || { time.hour == 24 && time.minute == 0 && time.second == 0 }
    // For leap seconds https://en.wikipedia.org/wiki/Leap_second. Leap seconds
    // are not fully supported by this package, but can be parsed from ISO 8601
    // dates.
    || { time.minute == 59 && time.second == 60 }
  {
    True ->
      case time {
        tempo.Time(_, _, _, _) -> Ok(time)
        tempo.TimeMilli(_, _, _, millis) if millis <= 999_000_000 -> Ok(time)
        tempo.TimeMicro(_, _, _, micros) if micros <= 999_999_000 -> Ok(time)
        tempo.TimeNano(_, _, _, nanos) if nanos <= 999_999_999 -> Ok(time)
        _ -> Error(Nil)
      }
    False -> Error(Nil)
  }
}

/// I made this but idk if it should be in the public API, it may lead people
/// to anti-patterns.
@internal
pub fn set_hour(time: tempo.Time, hour: Int) -> Result(tempo.Time, Nil) {
  case time {
    tempo.Time(_, m, s, _) -> new(hour, m, s)
    tempo.TimeMilli(_, m, s, n) -> new_milli(hour, m, s, n)
    tempo.TimeMicro(_, m, s, n) -> new_micro(hour, m, s, n)
    tempo.TimeNano(_, m, s, n) -> new_nano(hour, m, s, n)
  }
}

/// I made this but idk if it should be in the public API, it may lead people
/// to anti-patterns.
@internal
pub fn set_minute(time: tempo.Time, minute: Int) -> Result(tempo.Time, Nil) {
  case time {
    tempo.Time(h, _, s, _) -> new(h, minute, s)
    tempo.TimeMilli(h, _, s, n) -> new_milli(h, minute, s, n)
    tempo.TimeMicro(h, _, s, n) -> new_micro(h, minute, s, n)
    tempo.TimeNano(h, _, s, n) -> new_nano(h, minute, s, n)
  }
}

/// I made this but idk if it should be in the public API, it may lead people
/// to anti-patterns.
@internal
pub fn set_second(time: tempo.Time, second: Int) -> Result(tempo.Time, Nil) {
  case time {
    tempo.Time(h, m, _, _) -> new(h, m, second)
    tempo.TimeMilli(h, m, _, n) -> new_milli(h, m, second, n)
    tempo.TimeMicro(h, m, _, n) -> new_micro(h, m, second, n)
    tempo.TimeNano(h, m, _, n) -> new_nano(h, m, second, n)
  }
}

/// I made this but idk if it should be in the public API, it may lead people
/// to anti-patterns.
@internal
pub fn set_milli(time: tempo.Time, millisecond: Int) -> Result(tempo.Time, Nil) {
  new_milli(time.hour, time.minute, time.second, millisecond)
}

/// I made this but idk if it should be in the public API, it may lead people
/// to anti-patterns.
@internal
pub fn set_micro(time: tempo.Time, microsecond: Int) -> Result(tempo.Time, Nil) {
  new_micro(time.hour, time.minute, time.second, microsecond)
}

/// I made this but idk if it should be in the public API, it may lead people
/// to anti-patterns.
@internal
pub fn set_nano(time: tempo.Time, nanosecond: Int) -> Result(tempo.Time, Nil) {
  new_nano(time.hour, time.minute, time.second, nanosecond)
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
  tempo.Time(time.hour, time.minute, time.second, 0)
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
  tempo.TimeMilli(
    time.hour,
    time.minute,
    time.second,
    // Drop any microseconds
    { time.nanosecond / 1_000_000 } * 1_000_000,
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
  tempo.TimeMicro(
    time.hour,
    time.minute,
    time.second,
    // Drop any nanoseconds
    { time.nanosecond / 1000 } * 1000,
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
  tempo.TimeNano(time.hour, time.minute, time.second, time.nanosecond)
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
  string_builder.from_strings([
    time.hour |> int.to_string |> string.pad_left(2, with: "0"),
    ":",
    time.minute |> int.to_string |> string.pad_left(2, with: "0"),
    ":",
    time.second |> int.to_string |> string.pad_left(2, with: "0"),
  ])
  |> fn(sb) {
    case time {
      tempo.Time(_, _, _, _) -> sb
      tempo.TimeMilli(_, _, _, nanos) ->
        string_builder.append(sb, ".")
        |> string_builder.append(
          { nanos / 1_000_000 }
          |> int.to_string
          |> string.pad_left(3, with: "0"),
        )
      tempo.TimeMicro(_, _, _, nanos) ->
        string_builder.append(sb, ".")
        |> string_builder.append(
          { nanos / 1000 } |> int.to_string |> string.pad_left(6, with: "0"),
        )
      tempo.TimeNano(_, _, _, nanos) ->
        string_builder.append(sb, ".")
        |> string_builder.append(
          nanos |> int.to_string |> string.pad_left(9, with: "0"),
        )
    }
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
/// // -> Error(Nil)
/// ```
pub fn from_string(time: String) -> Result(tempo.Time, Nil) {
  use #(hour, minute, second): #(String, String, String) <- result.try(
    // Parse hh:mm:ss.s or hh:mm format
    case string.split(time, ":") {
      [hour, minute, second] -> Ok(#(hour, minute, second))
      [hour, minute] -> Ok(#(hour, minute, "0"))
      _ -> Error(Nil)
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
        _, _ -> Error(Nil)
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
              Ok(tempo.TimeMilli(hour, minute, second, milli * 1_000_000))
            _, _ -> Error(Nil)
          }
        len if len <= 6 ->
          case
            int.parse(second),
            int.parse(second_fraction |> string.pad_right(6, with: "0"))
          {
            Ok(second), Ok(micro) ->
              Ok(tempo.TimeMicro(hour, minute, second, micro * 1000))
            _, _ -> Error(Nil)
          }
        len if len <= 9 ->
          case
            int.parse(second),
            int.parse(second_fraction |> string.pad_right(9, with: "0"))
          {
            Ok(second), Ok(nano) ->
              Ok(tempo.TimeNano(hour, minute, second, nano))
            _, _ -> Error(Nil)
          }
        _ -> Error(Nil)
      }
    }

    Ok(hour), Ok(minute), _ ->
      case int.parse(second) {
        Ok(second) -> Ok(tempo.Time(hour, minute, second, 0))
        _ -> Error(Nil)
      }

    _, _, _ -> Error(Nil)
  }
  |> result.try(validate)
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
  #(time.hour, time.minute, time.second)
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
pub fn from_tuple(time: #(Int, Int, Int)) -> Result(tempo.Time, Nil) {
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
  #(time.hour, time.minute, time.second, time.nanosecond)
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
) -> Result(tempo.Time, Nil) {
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
  to_nanoseconds(time) |> tempo.Duration
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
  from_nanoseconds(duration.nanoseconds)
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
  case a.hour == b.hour {
    True ->
      case a.minute == b.minute {
        True ->
          case a.second == b.second {
            True ->
              case a.nanosecond == b.nanosecond {
                True -> order.Eq
                False ->
                  case a.nanosecond < b.nanosecond {
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
  to_nanoseconds(a) - to_nanoseconds(b) |> tempo.Duration
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
    diff if diff < 0 -> -diff |> tempo.Duration
    diff -> diff |> tempo.Duration
  }
}

@internal
pub fn to_nanoseconds(time: tempo.Time) -> Int {
  { time.hour * unit.hour_nanoseconds }
  + { time.minute * unit.minute_nanoseconds }
  + { time.second * unit.second_nanoseconds }
  + time.nanosecond
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

  tempo.TimeNano(hours, minutes, seconds, nanoseconds)
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
  let new_time = to_nanoseconds(a) + b.nanoseconds |> from_nanoseconds
  case a {
    tempo.Time(_, _, _, _) -> to_second_precision(new_time)
    tempo.TimeMilli(_, _, _, _) -> to_milli_precision(new_time)
    tempo.TimeMicro(_, _, _, _) -> to_micro_precision(new_time)
    tempo.TimeNano(_, _, _, _) -> to_nano_precision(new_time)
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
  let new_time = to_nanoseconds(a) - b.nanoseconds |> from_nanoseconds
  // Restore original time precision
  case a {
    tempo.Time(_, _, _, _) -> to_second_precision(new_time)
    tempo.TimeMilli(_, _, _, _) -> to_milli_precision(new_time)
    tempo.TimeMicro(_, _, _, _) -> to_micro_precision(new_time)
    tempo.TimeNano(_, _, _, _) -> to_nano_precision(new_time)
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
  case time {
    tempo.Time(_, _, _, _) -> to_second_precision(new_time)
    tempo.TimeMilli(_, _, _, _) -> to_milli_precision(new_time)
    tempo.TimeMicro(_, _, _, _) -> to_micro_precision(new_time)
    tempo.TimeNano(_, _, _, _) -> to_nano_precision(new_time)
  }
}
