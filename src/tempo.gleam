import gleam/io

pub fn main() {
  io.println("Hello from tempo!")
  io.debug(now_utc())
}

pub type Offset {
  Offset(minutes: Int)
}

pub type Date {
  Date(year: Int, month: Month, day: Int)
}

/// Do not use the `==` operator to check for time equality! Use the compare
/// functions instead.
///
/// Second precision is defined as different variants to have a way to 
/// preserve precision when going to and from strings or other representations.
pub type Time {
  Time(hour: Int, minute: Int, second: Int, nanosecond: Int)
  TimeMilli(hour: Int, minute: Int, second: Int, nanosecond: Int)
  TimeMicro(hour: Int, minute: Int, second: Int, nanosecond: Int)
  TimeNano(hour: Int, minute: Int, second: Int, nanosecond: Int)
}

pub type Duration {
  Duration(nanoseconds: Int)
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

@external(erlang, "tempo_ffi", "now")
@external(javascript, "./tempo_ffi.mjs", "now")
@internal
pub fn now_utc() -> Int
