//// Functions to use with the `Month` type in Tempo.

import gleam/result
import gleam/time/calendar
import tempo

/// An ordered list of all months in the year.
/// -> [Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec]
pub const months = tempo.months

/// Returns a month's short name.
/// 
/// ## Example
/// 
/// ```gleam
/// date.literal("2024-06-13")
/// |> date.get_month
/// |> month.to_short_string
/// // -> "Jun"
/// ```
pub fn to_short_string(month: tempo.Month) -> String {
  tempo.month_to_short_string(month)
}

/// Returns a month's long name.
/// 
/// ## Example
/// 
/// ```gleam
/// date.literal("2024-06-13")
/// |> date.get_month
/// |> month.to_short_string
/// // -> "June"
/// ```
pub fn to_long_string(month: tempo.Month) -> String {
  tempo.month_to_long_string(month)
}

/// Gets a month from a month string.
/// 
/// ## Example
/// 
/// ```gleam
/// month.from_string("Jun")
/// // -> Ok(tempo.Jun)
/// ```
/// 
/// ```gleam
/// month.from_string("June")
/// // -> Ok(tempo.Jun)
/// ```
/// 
/// ```gleam
/// month.from_string("Hello")
/// // -> Error(Nil)
/// ```
pub fn from_string(month: String) -> Result(tempo.Month, Nil) {
  from_short_string(month)
  |> result.try_recover(fn(_) { from_long_string(month) })
}

/// Gets a month from a short month string.
/// 
/// ## Example
/// 
/// ```gleam
/// month.from_short_string("Jun")
/// // -> Ok(tempo.Jun)
/// ```
/// 
/// ```gleam
/// month.from_short_string("June")
/// // -> Error(Nil)
/// ```
pub fn from_short_string(month: String) -> Result(tempo.Month, Nil) {
  tempo.month_from_short_string(month)
}

/// Gets a month from a long month string.
/// 
/// ## Example
/// 
/// ```gleam
/// month.from_long_string("June")
/// // -> Ok(tempo.Jun)
/// ```
/// 
/// ```gleam
/// month.from_long_string("Jun")
/// // -> Error(Nil)
/// ```
pub fn from_long_string(month: String) -> Result(tempo.Month, Nil) {
  tempo.month_from_long_string(month)
}

/// Returns a month's number on the civil calendar.
/// 
/// ## Example
/// 
/// ```gleam
/// date.literal("2024-06-13")
/// |> date.get_month
/// |> month.to_int
/// // -> 6
/// ```
pub fn to_int(month: tempo.Month) -> Int {
  tempo.month_to_int(month)
}

/// Gets a month from an integer representing the order of the month on the 
/// civil calendar.
/// 
/// ## Example
/// 
/// ```gleam
/// month.from_int(6)
/// // -> Ok(tempo.Jun)
/// ```
/// 
/// ```gleam
/// month.from_int(13)
/// // -> Error(Nil)
/// ```
pub fn from_int(month: Int) -> Result(tempo.Month, Nil) {
  tempo.month_from_int(month)
}

/// Returns the number of days in a month.
/// 
/// ## Example
/// 
/// ```gleam
/// date.literal("2024-06-13")
/// |> date.get_month
/// |> month.days
/// // -> 30
/// ```
/// 
/// ```gleam
/// date.literal("2024-12-03")
/// |> date.get_month
/// |> month.days
/// // -> 31
/// ```
pub fn days(of month: tempo.Month, in year: Int) -> Int {
  tempo.month_days_of(month, in: year)
}

/// Converts a tempo month to a month type in the core gleam time package.
pub fn to_calendar_month(month: tempo.Month) -> calendar.Month {
  case month {
    tempo.Jan -> calendar.January
    tempo.Feb -> calendar.February
    tempo.Mar -> calendar.March
    tempo.Apr -> calendar.April
    tempo.May -> calendar.May
    tempo.Jun -> calendar.June
    tempo.Jul -> calendar.July
    tempo.Aug -> calendar.August
    tempo.Sep -> calendar.September
    tempo.Oct -> calendar.October
    tempo.Nov -> calendar.November
    tempo.Dec -> calendar.December
  }
}

/// Converts a core gleam time month to a tempo month.
pub fn from_calendar_month(month: calendar.Month) -> tempo.Month {
  case month {
    calendar.January -> tempo.Jan
    calendar.February -> tempo.Feb
    calendar.March -> tempo.Mar
    calendar.April -> tempo.Apr
    calendar.May -> tempo.May
    calendar.June -> tempo.Jun
    calendar.July -> tempo.Jul
    calendar.August -> tempo.Aug
    calendar.September -> tempo.Sep
    calendar.October -> tempo.Oct
    calendar.November -> tempo.Nov
    calendar.December -> tempo.Dec
  }
}
