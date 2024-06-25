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
  DateTimeInvalidFormat
}

/// A datetime value that does not have a timezone offset associated with it. 
/// It cannot be compared to datetimes with a timezone offset accurately, but
/// can be compared to dates, times, and other naive datetimes.
pub type NaiveDateTime {
  NaiveDateTime(date: Date, time: Time)
}

/// A datetime value with a timezone offset associated with it. It has the 
/// most amount of information about a point in time, and can be compared to 
/// all other types in this package.
pub type DateTime {
  DateTime(naive: NaiveDateTime, offset: Offset)
}

/// A timezone offset value. It represents the difference between UTC and the
/// datetime value it is associated with.
pub type Offset {
  Offset(minutes: Int)
}

/// A date value. It represents a specific day on the civil calendar with no
/// time of day associated with it.
pub type Date {
  Date(year: Int, month: Month, day: Int)
}

/// A period between two calendar datetimes. It represents a range of
/// datetimes and can be used to calculate the number of days, weeks, months, 
/// or years between two dates. It can also be interated over and datetime 
/// values can be checked for inclusion in the period.
pub type Period {
  NaivePeriod(start: NaiveDateTime, end: NaiveDateTime)
  Period(start: DateTime, end: DateTime)
}

/// A time of day value. It represents a specific time on an unspecified date.
/// It cannot be greater than 24 hours or less than 0 hours. It can have 
/// different precisions between second and nanosecond, depending on what 
/// your application needs.
/// 
/// Do not use the `==` operator to check for time equality (it will not
/// handle time precision correctly)! Use the compare functions instead.
pub type Time {
  Time(hour: Int, minute: Int, second: Int, nanosecond: Int)
  TimeMilli(hour: Int, minute: Int, second: Int, nanosecond: Int)
  TimeMicro(hour: Int, minute: Int, second: Int, nanosecond: Int)
  TimeNano(hour: Int, minute: Int, second: Int, nanosecond: Int)
}

/// A duration between two times. It represents a range of time values and
/// can be span more than a day. It can be used to calculate the number of
/// days, weeks, hours, minutes, or seconds between two times, but cannot
/// accurately be used to calculate the number of years or months between.
/// 
/// It is also used as the basis for specifying how to increase or decrease
/// a datetime or time value.
pub type Duration {
  Duration(nanoseconds: Int)
}

/// The result of an uncertain conversion. Since this package does not track
/// timezone offsets, it uses the host system's offset to convert to local
/// time. If the datetime being converted to local time is of a different
/// day than the current one, the offset value provided by the host may
/// not be accurate (and could be accurate by up to the amount the offset 
/// changes throughout the year). To account for this, when converting to 
/// local time, a precise value is returned when the datetime being converted
/// is in th current date, while an imprecise value is returned when it is
/// on any other date. This allows the application logic to handle the 
/// two cases differently: some applications may only need to convert to 
/// local time on the current date or may only need generic time 
/// representations, while other applications may need precise conversions 
/// for arbitrary dates. More notes on how to plug time zones into this
/// package to aviod uncertain conversions can be found in the README.
pub type UncertainConversion(a) {
  Precise(a)
  Imprecise(a)
}

/// A specific month on the civil calendar. 
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

/// An ordered list of all months in the year.
pub const months = [Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec]

/// Accepts either a precise or imprecise value of an uncertain conversion.
/// Useful for pipelines.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-21T23:17:00Z")
/// |> datetime.to_local
/// |> tempo.accept_imprecision
/// |> datetime.to_string
/// // -> "2024-06-21T19:17:00-04:00"
/// ```
pub fn accept_imprecision(conv: UncertainConversion(a)) -> a {
  case conv {
    Precise(a) -> a
    Imprecise(a) -> a
  }
}

/// Either returns a precise value or an error from an uncertain conversion.
/// Useful for pipelines. 
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-21T23:17:00Z")
/// |> datetime.to_local
/// |> tempo.error_on_imprecision
/// |> result.try(do_important_precise_task)
/// ```
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
