import gleam/int
import gleam/order
import gleam/result
import gleam/string
import gleam/string_builder
import tempo
import tempo/date

pub fn new(hour: Int, minute: Int, second: Int) -> Result(tempo.NaiveTime, Nil) {
  tempo.NaiveTime(hour, minute, second, 0) |> validate
}

/// Useful for declaring time literals that you know are valid within your 
/// program. Will crash if an invalid time is provided.
pub fn literal(time: String) -> tempo.NaiveTime {
  let assert Ok(time) = from_string(time)
  let assert Ok(time) = validate(time)
  time
}

pub fn now_local() {
  let now_ts_nano = tempo.now_utc()

  // Subtract the nanoseconds that are responsible for the date and the local
  // offset nanoseconds.
  nanoseconds_to_time(
    now_ts_nano
    - {
      date.to_unix_utc(date.from_unix_utc(now_ts_nano / 1_000_000_000))
      * 1_000_000_000
    }
    + tempo.local_offset_nano(),
  )
}

pub fn now_utc() {
  let now_ts_nano = tempo.now_utc()

  // Subtract the nanoseconds that are responsible for the date.
  nanoseconds_to_time(
    now_ts_nano
    - {
      date.to_unix_utc(date.from_unix_utc(now_ts_nano / 1_000_000_000))
      * 1_000_000_000
    },
  )
}

@internal
pub fn test_literal(hour: Int, minute: Int, second: Int) -> tempo.NaiveTime {
  let assert Ok(time) = tempo.NaiveTime(hour, minute, second, 0) |> validate
  time
}

pub fn new_milli(
  hour: Int,
  minute: Int,
  second: Int,
  millisecond: Int,
) -> Result(tempo.NaiveTime, Nil) {
  tempo.NaiveTimeMilli(hour, minute, second, millisecond * 1_000_000) |> validate
}

@internal
pub fn test_literal_milli(hour: Int, minute: Int, second: Int, millisecond: Int) -> tempo.NaiveTime {
  let assert Ok(time) =
    tempo.NaiveTimeMilli(hour, minute, second, millisecond * 1_000_000) |> validate
  time
}

pub fn new_micro(
  hour: Int,
  minute: Int,
  second: Int,
  microsecond: Int,
) -> Result(tempo.NaiveTime, Nil) {
  tempo.NaiveTimeMicro(hour, minute, second, microsecond * 1000) |> validate
}

@internal
pub fn test_literal_micro(hour: Int, minute: Int, second: Int, microsecond: Int) -> tempo.NaiveTime {
  let assert Ok(time) =
    tempo.NaiveTimeMicro(hour, minute, second, microsecond * 1000) |> validate
  time
}

pub fn new_nano(
  hour: Int,
  minute: Int,
  second: Int,
  nanosecond: Int,
) -> Result(tempo.NaiveTime, Nil) {
  tempo.NaiveTimeNano(hour, minute, second, nanosecond) |> validate
}

@internal
pub fn test_literal_nano(hour: Int, minute: Int, second: Int, nanosecond: Int) -> tempo.NaiveTime {
  let assert Ok(time) =
    tempo.NaiveTimeNano(hour, minute, second, nanosecond) |> validate
  time
}

fn validate(time: tempo.NaiveTime) -> Result(tempo.NaiveTime, Nil) {
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
    // For leap seconds https://en.wikipedia.org/wiki/Leap_second
    || { time.hour == 23 && time.minute == 59 && time.second == 60 }
  {
    True ->
      case time {
        tempo.NaiveTime(_, _, _, _) -> Ok(time)
        tempo.NaiveTimeMilli(_, _, _, millis) if millis <= 999_000_000 -> Ok(time)
        tempo.NaiveTimeMicro(_, _, _, micros) if micros <= 999_999_000 -> Ok(time)
        tempo.NaiveTimeNano(_, _, _, nanos) if nanos <= 999_999_999 -> Ok(time)
        _ -> Error(Nil)
      }
    False -> Error(Nil)
  }
}

pub fn set_hour(time: tempo.NaiveTime, hour: Int) -> Result(tempo.NaiveTime, Nil) {
  case time {
    tempo.NaiveTime(_, m, s, _) -> new(hour, m, s)
    tempo.NaiveTimeMilli(_, m, s, n) -> new_milli(hour, m, s, n)
    tempo.NaiveTimeMicro(_, m, s, n) -> new_micro(hour, m, s, n)
    tempo.NaiveTimeNano(_, m, s, n) -> new_nano(hour, m, s, n)
  }
}

pub fn set_minute(time: tempo.NaiveTime, minute: Int) -> Result(tempo.NaiveTime, Nil) {
  case time {
    tempo.NaiveTime(h, _, s, _) -> new(h, minute, s)
    tempo.NaiveTimeMilli(h, _, s, n) -> new_milli(h, minute, s, n)
    tempo.NaiveTimeMicro(h, _, s, n) -> new_micro(h, minute, s, n)
    tempo.NaiveTimeNano(h, _, s, n) -> new_nano(h, minute, s, n)
  }
}

pub fn set_second(time: tempo.NaiveTime, second: Int) -> Result(tempo.NaiveTime, Nil) {
  case time {
    tempo.NaiveTime(h, m, _, _) -> new(h, m, second)
    tempo.NaiveTimeMilli(h, m, _, n) -> new_milli(h, m, second, n)
    tempo.NaiveTimeMicro(h, m, _, n) -> new_micro(h, m, second, n)
    tempo.NaiveTimeNano(h, m, _, n) -> new_nano(h, m, second, n)
  }
}

pub fn set_milli(time: tempo.NaiveTime, millisecond: Int) -> Result(tempo.NaiveTime, Nil) {
  new_milli(time.hour, time.minute, time.second, millisecond)
}

pub fn set_micro(time: tempo.NaiveTime, microsecond: Int) -> Result(tempo.NaiveTime, Nil) {
  new_micro(time.hour, time.minute, time.second, microsecond)
}

pub fn set_nano(time: tempo.NaiveTime, nanosecond: Int) -> Result(tempo.NaiveTime, Nil) {
  new_nano(time.hour, time.minute, time.second, nanosecond)
}

pub fn to_second_precision(time: tempo.NaiveTime) -> tempo.NaiveTime {
  // Drop any milliseconds
  tempo.NaiveTime(time.hour, time.minute, time.second, 0)
}

pub fn to_milli_precision(time: tempo.NaiveTime) -> tempo.NaiveTime {
  tempo.NaiveTimeMilli(
    time.hour,
    time.minute,
    time.second,
    // Drop any microseconds
    { time.nanosecond / 1_000_000 } * 1_000_000,
  )
}

pub fn to_micro_precision(time: tempo.NaiveTime) -> tempo.NaiveTime {
  tempo.NaiveTimeMicro(
    time.hour,
    time.minute,
    time.second,
    // Drop any nanoseconds
    { time.nanosecond / 1000 } * 1000,
  )
}

pub fn to_nano_precision(time: tempo.NaiveTime) -> tempo.NaiveTime {
  tempo.NaiveTimeNano(time.hour, time.minute, time.second, time.nanosecond)
}

pub fn to_string(time: tempo.NaiveTime) -> String {
  string_builder.from_strings([
    time.hour |> int.to_string |> string.pad_left(2, with: "0"),
    ":",
    time.minute |> int.to_string |> string.pad_left(2, with: "0"),
    ":",
    time.second |> int.to_string |> string.pad_left(2, with: "0"),
  ])
  |> fn(sb) {
    case time {
      tempo.NaiveTime(_, _, _, _) -> sb
      tempo.NaiveTimeMilli(_, _, _, nanos) ->
        string_builder.append(sb, ".")
        |> string_builder.append(
          { nanos / 1_000_000 }
          |> int.to_string
          |> string.pad_left(3, with: "0"),
        )
      tempo.NaiveTimeMicro(_, _, _, nanos) ->
        string_builder.append(sb, ".")
        |> string_builder.append(
          { nanos / 1000 } |> int.to_string |> string.pad_left(6, with: "0"),
        )
      tempo.NaiveTimeNano(_, _, _, nanos) ->
        string_builder.append(sb, ".")
        |> string_builder.append(
          nanos |> int.to_string |> string.pad_left(9, with: "0"),
        )
    }
  }
  |> string_builder.to_string
}

pub fn from_string(time: String) -> Result(tempo.NaiveTime, Nil) {
  case string.split(time, ":") {
    [hour, minute, second] ->
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
                  Ok(tempo.NaiveTimeMilli(hour, minute, second, milli * 1_000_000))
                _, _ -> Error(Nil)
              }
            len if len <= 6 ->
              case
                int.parse(second),
                int.parse(second_fraction |> string.pad_right(6, with: "0"))
              {
                Ok(second), Ok(micro) ->
                  Ok(tempo.NaiveTimeMicro(hour, minute, second, micro * 1000))
                _, _ -> Error(Nil)
              }
            len if len <= 9 ->
              case
                int.parse(second),
                int.parse(second_fraction |> string.pad_right(9, with: "0"))
              {
                Ok(second), Ok(nano) ->
                  Ok(tempo.NaiveTimeNano(hour, minute, second, nano))
                _, _ -> Error(Nil)
              }
            _ -> Error(Nil)
          }
        }

        Ok(hour), Ok(minute), _ ->
          case int.parse(second) {
            Ok(second) -> Ok(tempo.NaiveTime(hour, minute, second, 0))
            _ -> Error(Nil)
          }

        _, _, _ -> Error(Nil)
      }
    _ -> Error(Nil)
  }
  |> result.try(validate)
}

pub fn compare(a: tempo.NaiveTime, to b: tempo.NaiveTime) -> order.Order {
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

pub fn is_earlier(a: tempo.NaiveTime, than b: tempo.NaiveTime) -> Bool {
  compare(a, b) == order.Lt
}

pub fn is_earlier_or_equal(a: tempo.NaiveTime, than b: tempo.NaiveTime) -> Bool {
  compare(a, b) == order.Lt || compare(a, b) == order.Eq
}

pub fn is_equal(a: tempo.NaiveTime, to b: tempo.NaiveTime) -> Bool {
  compare(a, b) == order.Eq
}

pub fn is_later(a: tempo.NaiveTime, than b: tempo.NaiveTime) -> Bool {
  compare(a, b) == order.Gt
}

pub fn is_later_or_equal(a: tempo.NaiveTime, than b: tempo.NaiveTime) -> Bool {
  compare(a, b) == order.Gt || compare(a, b) == order.Eq
}

pub opaque type Duration {
  Duration(nanoseconds: Int)
}

pub fn to_duration(time: tempo.NaiveTime) -> Duration {
  time_to_nanoseconds(time) |> Duration
}

pub fn difference(a: tempo.NaiveTime, from b: tempo.NaiveTime) -> Duration {
  time_to_nanoseconds(b) - time_to_nanoseconds(a)
  |> Duration
}

pub fn difference_abs(a: tempo.NaiveTime, from b: tempo.NaiveTime) -> Duration {
  case time_to_nanoseconds(b) - time_to_nanoseconds(a) {
    diff if diff < 0 -> -diff |> Duration
    diff -> diff |> Duration
  }
}

/// Can not account for leap seconds.
pub fn add_duration(a: tempo.NaiveTime, b: Duration) -> tempo.NaiveTime {
  let new_time = time_to_nanoseconds(a) + b.nanoseconds |> nanoseconds_to_time
  case a {
    tempo.NaiveTime(_, _, _, _) -> to_second_precision(new_time)
    tempo.NaiveTimeMilli(_, _, _, _) -> to_milli_precision(new_time)
    tempo.NaiveTimeMicro(_, _, _, _) -> to_micro_precision(new_time)
    tempo.NaiveTimeNano(_, _, _, _) -> to_nano_precision(new_time)
  }
}

/// Can not account for leap seconds.
pub fn substract_duration(a: tempo.NaiveTime, b: Duration) -> tempo.NaiveTime {
  let new_time = time_to_nanoseconds(a) - b.nanoseconds |> nanoseconds_to_time
  case a {
    tempo.NaiveTime(_, _, _, _) -> to_second_precision(new_time)
    tempo.NaiveTimeMilli(_, _, _, _) -> to_milli_precision(new_time)
    tempo.NaiveTimeMicro(_, _, _, _) -> to_micro_precision(new_time)
    tempo.NaiveTimeNano(_, _, _, _) -> to_nano_precision(new_time)
  }
}

@internal
pub fn time_to_nanoseconds(time: tempo.NaiveTime) -> Int {
  hours_to_nanoseconds(time.hour)
  + minutes_to_nanoseconds(time.minute)
  + seconds_to_nanoseconds(time.second)
  + time.nanosecond
}

@internal
pub fn nanoseconds_to_time(nanoseconds: Int) -> tempo.NaiveTime {
  let in_range_ns = nanoseconds % 86_400_000_000_000

  let adj_ns = case in_range_ns < 0 {
    True -> in_range_ns + 86_400_000_000_000
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

  tempo.NaiveTimeNano(hours, minutes, seconds, nanoseconds)
}

pub fn new_duration(hours hr: Int, minutes min: Int, seconds sec: Int) {
  hours_to_nanoseconds(hr)
  + minutes_to_nanoseconds(min)
  + seconds_to_nanoseconds(sec)
  |> Duration
}

pub fn new_duration_hours(hours: Int) -> Duration {
  hours_to_nanoseconds(hours) |> Duration
}

pub fn new_duration_minutes(minutes: Int) -> Duration {
  minutes_to_nanoseconds(minutes) |> Duration
}

pub fn new_duration_seconds(seconds: Int) -> Duration {
  seconds_to_nanoseconds(seconds) |> Duration
}

pub fn new_duration_milli(milliseconds: Int) {
  milliseconds * 1_000_000 |> Duration
}

pub fn new_duration_micro(microseconds: Int) {
  microseconds * 1000 |> Duration
}

pub fn new_duration_nano(nanoseconds: Int) {
  nanoseconds |> Duration
}

pub fn increase_duration(a: Duration, by b: Duration) -> Duration {
  Duration(a.nanoseconds + b.nanoseconds)
}

pub fn decrease_duration(a: Duration, by b: Duration) -> Duration {
  Duration(a.nanoseconds - b.nanoseconds)
}

fn hours_to_nanoseconds(hours: Int) -> Int {
  hours * 3_600_000_000_000
}

fn minutes_to_nanoseconds(minutes: Int) -> Int {
  minutes * 60_000_000_000
}

fn seconds_to_nanoseconds(seconds: Int) -> Int {
  seconds * 1_000_000_000
}

pub fn as_hours(duration: Duration) -> Int {
  duration.nanoseconds / 3_600_000_000_000
}

pub fn as_hours_fractional(duration: Duration) -> Float {
  int.to_float(duration.nanoseconds) /. 3_600_000_000_000.0
}

pub fn as_minutes(duration: Duration) -> Int {
  duration.nanoseconds / 60_000_000_000
}

pub fn as_minutes_fractional(duration: Duration) -> Float {
  int.to_float(duration.nanoseconds) /. 60_000_000_000.0
}

pub fn as_seconds(duration: Duration) -> Int {
  duration.nanoseconds / 1_000_000_000
}

pub fn as_seconds_fractional(duration: Duration) -> Float {
  int.to_float(duration.nanoseconds) /. 1_000_000_000.0
}

pub fn as_milliseconds(duration: Duration) -> Int {
  duration.nanoseconds / 1_000_000
}

pub fn as_milliseconds_fractional(duration: Duration) -> Float {
  int.to_float(duration.nanoseconds) /. 1_000_000.0
}

pub fn as_microseconds(duration: Duration) -> Int {
  duration.nanoseconds / 1000
}

pub fn as_microseconds_fractional(duration: Duration) -> Float {
  int.to_float(duration.nanoseconds) /. 1000.0
}

pub fn as_nanoseconds(duration: Duration) -> Int {
  duration.nanoseconds
}
