import gleam/io

pub fn main() {
  io.println("Hello from tempo!")
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
  Time(hour: Int, minute: Int, second: Int, nanosecond: Int)
  TimeMilli(hour: Int, minute: Int, second: Int, nanosecond: Int)
  TimeMicro(hour: Int, minute: Int, second: Int, nanosecond: Int)
  TimeNano(hour: Int, minute: Int, second: Int, nanosecond: Int)
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
