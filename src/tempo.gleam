import gleam/int
import gleam/io
import gleam/string

pub fn main() {
  io.println("Hello from tempo!")
  io.debug(now_utc())
  io.debug(local_offset_minutes() / 60)
  io.debug(local_offset_str())
}

pub type Offset {
  UTC
  Local
}

pub type Date {
  Date(year: Int, month: Month, day: Int)
}

// Second precision is defined as different variants to have a way to 
// preserve precision when going to and from strings or other representations.
pub type Time {
  Time(hour: Int, minute: Int, second: Int, nanosecond: Int, offset: Int)
  TimeMilli(hour: Int, minute: Int, second: Int, nanosecond: Int, offset: Int)
  TimeMicro(hour: Int, minute: Int, second: Int, nanosecond: Int, offset: Int)
  TimeNano(hour: Int, minute: Int, second: Int, nanosecond: Int, offset: Int)
}

// Second precision is defined as different variants to have a way to 
// preserve precision when going to and from strings or other representations.
pub type NaiveTime {
  NaiveTime(hour: Int, minute: Int, second: Int, nanosecond: Int)
  NaiveTimeMilli(hour: Int, minute: Int, second: Int, nanosecond: Int)
  NaiveTimeMicro(hour: Int, minute: Int, second: Int, nanosecond: Int)
  NaiveTimeNano(hour: Int, minute: Int, second: Int, nanosecond: Int)
}

pub type Month {
  Jan
  Feb
  Mar
  Apr
  May
  Jun
  Jul
  Aug
  Sep
  Oct
  Nov
  Dec
}

pub type DayOfWeek {
  Sun
  Mon
  Tue
  Wed
  Thu
  Fri
  Sat
}

@external(erlang, "tempo_ffi", "now")
@external(javascript, "./tempo_ffi.mjs", "now")
@internal
pub fn now_utc() -> Int

@external(erlang, "tempo_ffi", "local_offset")
@external(javascript, "./tempo_ffi.mjs", "local_offset")
@internal
pub fn local_offset_minutes() -> Int

@internal
pub fn local_offset_nano() -> Int {
  local_offset_minutes() * 60_000_000_000
}

pub fn local_offset_str() -> String {
  let local_offset_minutes = local_offset_minutes()

  let #(is_negative, hours) = case local_offset_minutes / 60 {
    h if h < 0 -> #(True, -h)
    h -> #(False, h)
  }

  let mins = case local_offset_minutes % 60 {
    m if m < 0 -> -m
    m -> m
  }

  case is_negative, hours, mins {
    _, 0, m -> "-00:" <> int.to_string(m) |> string.pad_left(2, with: "0")

    True, h, m ->
      "-"
      <> int.to_string(h) |> string.pad_left(2, with: "0")
      <> ":"
      <> int.to_string(m) |> string.pad_left(2, with: "0")

    False, h, m ->
      "+"
      <> int.to_string(h) |> string.pad_left(2, with: "0")
      <> ":"
      <> int.to_string(m) |> string.pad_left(2, with: "0")
  }
}
