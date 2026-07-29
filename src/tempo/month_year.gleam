//// Functions to use with the `MonthYear` type in Tempo.
////
//// All functions in this module work on the proleptic Gregorian calendar: the
//// twelve Gregorian months in their Gregorian order, rolling over between
//// December and January, with Gregorian leap year rules for February.
////
//// Any year value is accepted, not just the 1000 to 9999 range that the
//// `tempo/date` constructors are limited to.

import gleam/int
import gleam/order
import tempo

/// Returns the next month on the Gregorian calendar, rolling over from
/// December to January of the following year.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.MonthYear(tempo.Jan, 2024)
/// |> month_year.next
/// // -> tempo.MonthYear(tempo.Feb, 2024)
/// ```
/// 
/// ```gleam
/// tempo.MonthYear(tempo.Dec, 2024)
/// |> month_year.next
/// // -> tempo.MonthYear(tempo.Jan, 2025)
/// ```
pub fn next(month: tempo.MonthYear) -> tempo.MonthYear {
  tempo.month_year_next(month)
}

/// Returns the previous month on the Gregorian calendar, rolling back from
/// January to December of the preceding year.
/// 
/// ## Example
/// 
/// ```gleam
/// tempo.MonthYear(tempo.Jan, 2024)
/// |> month_year.prior
/// // -> tempo.MonthYear(tempo.Dec, 2023)
/// ```
/// 
/// ```gleam
/// tempo.MonthYear(tempo.Feb, 2024)
/// |> month_year.prior
/// // -> tempo.MonthYear(tempo.Jan, 2024)
/// ```
pub fn prior(my: tempo.MonthYear) -> tempo.MonthYear {
  tempo.month_year_prior(my)
}

/// Returns the number of days in the month, on the proleptic Gregorian
/// calendar. February is 29 days in a Gregorian leap year and 28 otherwise.
///
/// ## Example
///
/// ```gleam
/// tempo.MonthYear(calendar.February, 2024)
/// |> month_year.days_of
/// // -> 29
/// ```
pub fn days_of(my: tempo.MonthYear) -> Int {
  tempo.month_year_days_of(my)
}

/// Returns the month and year as a single sortable integer, `year * 100`
/// plus the Gregorian month number.
///
/// ## Example
///
/// ```gleam
/// tempo.MonthYear(calendar.June, 2024)
/// |> month_year.to_int
/// // -> 202_406
/// ```
pub fn to_int(my: tempo.MonthYear) -> Int {
  tempo.month_year_to_int(my)
}

/// Compares two month-year values chronologically on the Gregorian calendar.
///
/// ## Example
///
/// ```gleam
/// tempo.MonthYear(calendar.June, 2024)
/// |> month_year.compare(to: tempo.MonthYear(calendar.July, 2024))
/// // -> order.Lt
/// ```
pub fn compare(a: tempo.MonthYear, to b: tempo.MonthYear) -> order.Order {
  int.compare(a |> to_int, b |> to_int)
}
