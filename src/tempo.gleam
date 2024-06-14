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