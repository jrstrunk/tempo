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
  Offset(minutes: Int)
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
