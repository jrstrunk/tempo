//// Functions to use with the `Month` type in Tempo.
//// 
//// ## Example
//// 
//// ```gleam
//// import tempo/month
//// import tempo/date
//// 
//// pub fn get_next_month_name() {
////   date.now_local()
////   |> date.get_month
////   |> month.next
////   |> month.to_long_string
////   // -> "November"
//// }
//// ```

import gleam/result
import tempo

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
  case month {
    tempo.Jan -> "Jan"
    tempo.Feb -> "Feb"
    tempo.Mar -> "Mar"
    tempo.Apr -> "Apr"
    tempo.May -> "May"
    tempo.Jun -> "Jun"
    tempo.Jul -> "Jul"
    tempo.Aug -> "Aug"
    tempo.Sep -> "Sep"
    tempo.Oct -> "Oct"
    tempo.Nov -> "Nov"
    tempo.Dec -> "Dec"
  }
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
  case month {
    tempo.Jan -> "January"
    tempo.Feb -> "February"
    tempo.Mar -> "March"
    tempo.Apr -> "April"
    tempo.May -> "May"
    tempo.Jun -> "June"
    tempo.Jul -> "July"
    tempo.Aug -> "August"
    tempo.Sep -> "September"
    tempo.Oct -> "October"
    tempo.Nov -> "November"
    tempo.Dec -> "December"
  }
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
pub fn from_string(month: String) -> Result(tempo.Month, tempo.Error) {
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
pub fn from_short_string(month: String) -> Result(tempo.Month, tempo.Error) {
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
pub fn from_long_string(month: String) -> Result(tempo.Month, tempo.Error) {
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
pub fn from_int(month: Int) -> Result(tempo.Month, tempo.Error) {
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
  tempo.days_of_month(month, in: year)
}

/// Returns the next month in the civil calendar.
/// 
/// ## Example
/// 
/// ```gleam
/// date.literal("2024-06-13")
/// |> date.get_month
/// |> month.next
/// // -> tempo.Jul
/// ```
/// 
/// ```gleam
/// date.literal("2024-12-03")
/// |> date.get_month
/// |> month.next
/// // -> tempo.Jan
/// ```
pub fn next(month: tempo.Month) -> tempo.Month {
  tempo.month_next(month)
}

/// Returns the previous month in the civil calendar.
/// 
/// ## Example
/// 
/// ```gleam
/// date.literal("2024-06-13")
/// |> date.get_month
/// |> month.prior
/// // -> tempo.May
/// ```
/// 
/// ```gleam
/// date.literal("2024-01-03")
/// |> date.get_month
/// |> month.prior
/// // -> tempo.Dec
/// ```
pub fn prior(month: tempo.Month) -> tempo.Month {
  tempo.month_prior(month)
}
