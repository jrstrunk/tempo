pub type Error {
  TimeInvalidFormat
  TimeOutOfBounds
  DateInvalidFormat
  DateOutOfBounds
  MonthInvalidFormat
  MonthOutOfBounds
  OffsetInvalidFormat
  OffsetOutOfBounds
  NaiveDateTimeInvalidFormat
  NaiveDateTimeOutOfBounds
  DateTimeInvalidFormat
  DateTimeOutOfBounds
}

pub type NaiveDateTime {
  NaiveDateTime(date: Date, time: Time)
}

pub type DateTime {
  DateTime(naive: NaiveDateTime, offset: Offset)
}

pub type Offset {
  Offset(minutes: Int)
}

pub type Date {
  Date(year: Int, month: Month, day: Int)
}

pub type Period {
  Period(start: NaiveDateTime, end: NaiveDateTime)
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

pub type UncertainConversion(a) {
  Precise(a)
  Imprecise(a)
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

pub const months = [Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec]

pub fn accept_imprecision(conv: UncertainConversion(a)) -> a {
  case conv {
    Precise(a) -> a
    Imprecise(a) -> a
  }
}

pub fn error_on_imprecision(conv: UncertainConversion(a)) -> Result(a, Nil) {
  case conv {
    Precise(a) -> Ok(a)
    Imprecise(_) -> Error(Nil)
  }
}

@external(erlang, "tempo_ffi", "now")
@external(javascript, "./tempo_ffi.mjs", "now")
@internal
pub fn now_utc() -> Int
