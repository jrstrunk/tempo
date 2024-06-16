import gleam/int
import gleam/order
import gleam/result
import gleam/string
import gleam/string_builder
import tempo
import tempo/date
import tempo/duration
import tempo/offset

pub fn new(hour: Int, minute: Int, second: Int) -> Result(tempo.Time, Nil) {
  tempo.Time(hour, minute, second, 0) |> validate
}

/// Useful for declaring time literals that you know are valid within your 
/// program. Will crash if an invalid time is provided.
pub fn literal(time: String) -> tempo.Time {
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
    + offset.local_nano(),
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
pub fn test_literal(hour: Int, minute: Int, second: Int) -> tempo.Time {
  let assert Ok(time) = tempo.Time(hour, minute, second, 0) |> validate
  time
}

pub fn new_milli(
  hour: Int,
  minute: Int,
  second: Int,
  millisecond: Int,
) -> Result(tempo.Time, Nil) {
  tempo.TimeMilli(hour, minute, second, millisecond * 1_000_000)
  |> validate
}

@internal
pub fn test_literal_milli(hour: Int, minute: Int, second: Int, millisecond: Int) -> tempo.Time {
  let assert Ok(time) =
    tempo.TimeMilli(hour, minute, second, millisecond * 1_000_000)
    |> validate
  time
}

pub fn new_micro(
  hour: Int,
  minute: Int,
  second: Int,
  microsecond: Int,
) -> Result(tempo.Time, Nil) {
  tempo.TimeMicro(hour, minute, second, microsecond * 1000) |> validate
}

@internal
pub fn test_literal_micro(hour: Int, minute: Int, second: Int, microsecond: Int) -> tempo.Time {
  let assert Ok(time) =
    tempo.TimeMicro(hour, minute, second, microsecond * 1000) |> validate
  time
}

pub fn new_nano(
  hour: Int,
  minute: Int,
  second: Int,
  nanosecond: Int,
) -> Result(tempo.Time, Nil) {
  tempo.TimeNano(hour, minute, second, nanosecond) |> validate
}

@internal
pub fn test_literal_nano(hour: Int, minute: Int, second: Int, nanosecond: Int) -> tempo.Time {
  let assert Ok(time) =
    tempo.TimeNano(hour, minute, second, nanosecond) |> validate
  time
}

@internal
pub fn validate(time: tempo.Time) -> Result(tempo.Time, Nil) {
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
        tempo.Time(_, _, _, _) -> Ok(time)
        tempo.TimeMilli(_, _, _, millis) if millis <= 999_000_000 -> Ok(time)
        tempo.TimeMicro(_, _, _, micros) if micros <= 999_999_000 -> Ok(time)
        tempo.TimeNano(_, _, _, nanos) if nanos <= 999_999_999 -> Ok(time)
        _ -> Error(Nil)
      }
    False -> Error(Nil)
  }
}

pub fn set_hour(time: tempo.Time, hour: Int) -> Result(tempo.Time, Nil) {
  case time {
    tempo.Time(_, m, s, _) -> new(hour, m, s)
    tempo.TimeMilli(_, m, s, n) -> new_milli(hour, m, s, n)
    tempo.TimeMicro(_, m, s, n) -> new_micro(hour, m, s, n)
    tempo.TimeNano(_, m, s, n) -> new_nano(hour, m, s, n)
  }
}

pub fn set_minute(time: tempo.Time, minute: Int) -> Result(tempo.Time, Nil) {
  case time {
    tempo.Time(h, _, s, _) -> new(h, minute, s)
    tempo.TimeMilli(h, _, s, n) -> new_milli(h, minute, s, n)
    tempo.TimeMicro(h, _, s, n) -> new_micro(h, minute, s, n)
    tempo.TimeNano(h, _, s, n) -> new_nano(h, minute, s, n)
  }
}

pub fn set_second(time: tempo.Time, second: Int) -> Result(tempo.Time, Nil) {
  case time {
    tempo.Time(h, m, _, _) -> new(h, m, second)
    tempo.TimeMilli(h, m, _, n) -> new_milli(h, m, second, n)
    tempo.TimeMicro(h, m, _, n) -> new_micro(h, m, second, n)
    tempo.TimeNano(h, m, _, n) -> new_nano(h, m, second, n)
  }
}

pub fn set_milli(time: tempo.Time, millisecond: Int) -> Result(tempo.Time, Nil) {
  new_milli(time.hour, time.minute, time.second, millisecond)
}

pub fn set_micro(time: tempo.Time, microsecond: Int) -> Result(tempo.Time, Nil) {
  new_micro(time.hour, time.minute, time.second, microsecond)
}

pub fn set_nano(time: tempo.Time, nanosecond: Int) -> Result(tempo.Time, Nil) {
  new_nano(time.hour, time.minute, time.second, nanosecond)
}

pub fn to_second_precision(time: tempo.Time) -> tempo.Time {
  // Drop any milliseconds
  tempo.Time(time.hour, time.minute, time.second, 0)
}

pub fn to_milli_precision(time: tempo.Time) -> tempo.Time {
  tempo.TimeMilli(
    time.hour,
    time.minute,
    time.second,
    // Drop any microseconds
    { time.nanosecond / 1_000_000 } * 1_000_000,
  )
}

pub fn to_micro_precision(time: tempo.Time) -> tempo.Time {
  tempo.TimeMicro(
    time.hour,
    time.minute,
    time.second,
    // Drop any nanoseconds
    { time.nanosecond / 1000 } * 1000,
  )
}

pub fn to_nano_precision(time: tempo.Time) -> tempo.Time {
  tempo.TimeNano(time.hour, time.minute, time.second, time.nanosecond)
}

/// Applies an offset to the naive time value, changing the hours and minutes
/// by the offset value.
pub fn apply_offset(time: tempo.Time, offset: tempo.Offset) -> tempo.Time {
  time
  |> add_duration(offset.to_duration(offset))
}

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

pub fn from_string(time: String) -> Result(tempo.Time, Nil) {
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
    _ -> Error(Nil)
  }
  |> result.try(validate)
}

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

pub fn is_earlier(a: tempo.Time, than b: tempo.Time) -> Bool {
  compare(a, b) == order.Lt
}

pub fn is_earlier_or_equal(a: tempo.Time, than b: tempo.Time) -> Bool {
  compare(a, b) == order.Lt || compare(a, b) == order.Eq
}

pub fn is_equal(a: tempo.Time, to b: tempo.Time) -> Bool {
  compare(a, b) == order.Eq
}

pub fn is_later(a: tempo.Time, than b: tempo.Time) -> Bool {
  compare(a, b) == order.Gt
}

pub fn is_later_or_equal(a: tempo.Time, than b: tempo.Time) -> Bool {
  compare(a, b) == order.Gt || compare(a, b) == order.Eq
}

pub fn to_duration(time: tempo.Time) -> tempo.Duration {
  time_to_nanoseconds(time) |> tempo.Duration
}

pub fn difference(a: tempo.Time, from b: tempo.Time) -> tempo.Duration {
  time_to_nanoseconds(b) - time_to_nanoseconds(a)
  |> tempo.Duration
}

pub fn difference_abs(a: tempo.Time, from b: tempo.Time) -> tempo.Duration {
  case time_to_nanoseconds(b) - time_to_nanoseconds(a) {
    diff if diff < 0 -> -diff |> tempo.Duration
    diff -> diff |> tempo.Duration
  }
}

@internal
pub fn time_to_nanoseconds(time: tempo.Time) -> Int {
  { time.hour * duration.hour_nanoseconds }
  + { time.minute * duration.minute_nanoseconds }
  + { time.second * duration.second_nanoseconds }
  + time.nanosecond
}

pub fn nanoseconds_to_time(nanoseconds: Int) -> tempo.Time {
  let in_range_ns = nanoseconds % duration.day_nanoseconds

  let adj_ns = case in_range_ns < 0 {
    True -> in_range_ns + duration.day_nanoseconds
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

@internal
pub fn nanoseconds_to_unbound_time(nanoseconds: Int) -> tempo.Time {
  let hours = nanoseconds / 3_600_000_000_000

  let minutes = { nanoseconds - hours * 3_600_000_000_000 } / 60_000_000_000

  let seconds =
    { nanoseconds - hours * 3_600_000_000_000 - minutes * 60_000_000_000 }
    / 1_000_000_000

  let nanoseconds =
    nanoseconds
    - hours
    * 3_600_000_000_000
    - minutes
    * 60_000_000_000
    - seconds
    * 1_000_000_000

  tempo.TimeNano(hours, minutes, seconds, nanoseconds)
}

/// Can not account for leap seconds.
pub fn add_duration(a: tempo.Time, b: tempo.Duration) -> tempo.Time {
  let new_time = time_to_nanoseconds(a) + b.nanoseconds |> nanoseconds_to_time
  case a {
    tempo.Time(_, _, _, _) -> to_second_precision(new_time)
    tempo.TimeMilli(_, _, _, _) -> to_milli_precision(new_time)
    tempo.TimeMicro(_, _, _, _) -> to_micro_precision(new_time)
    tempo.TimeNano(_, _, _, _) -> to_nano_precision(new_time)
  }
}

/// Can not account for leap seconds.
pub fn substract_duration(a: tempo.Time, b: tempo.Duration) -> tempo.Time {
  let new_time = time_to_nanoseconds(a) - b.nanoseconds |> nanoseconds_to_time
  case a {
    tempo.Time(_, _, _, _) -> to_second_precision(new_time)
    tempo.TimeMilli(_, _, _, _) -> to_milli_precision(new_time)
    tempo.TimeMicro(_, _, _, _) -> to_micro_precision(new_time)
    tempo.TimeNano(_, _, _, _) -> to_nano_precision(new_time)
  }
}
