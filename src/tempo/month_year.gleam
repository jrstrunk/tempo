import gleam/int
import gleam/order
import tempo

/// Returns the next month in the civil calendar.
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

/// Returns the previous month in the civil calendar.
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

pub fn days_of(my: tempo.MonthYear) -> Int {
  tempo.month_year_days_of(my)
}

pub fn to_int(my: tempo.MonthYear) -> Int {
  tempo.month_year_to_int(my)
}

pub fn compare(a: tempo.MonthYear, to b: tempo.MonthYear) -> order.Order {
  int.compare(a |> to_int, b |> to_int)
}
