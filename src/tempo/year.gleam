//// Functions to use with the `Year` type in Tempo. Years are pretty simple
//// thankfully.

import tempo

/// Checks if a year is a leap year.
/// 
/// ## Examples
/// 
/// ```gleam
/// year.is_leap_year(2024)
/// // -> True
/// ```
/// 
/// ```gleam
/// year.is_leap_year(2025)
/// // -> False
/// ```
pub fn is_leap_year(year: Int) -> Bool {
  tempo.is_leap_year(year)
}

/// Get the number of days in a year. Accounts for leap years.
/// 
/// ## Examples
/// 
/// ```gleam
/// year.days(2024)
/// // -> 366
/// ```
/// 
/// ```gleam
/// year.days(2025)
/// // -> 365
/// ```
pub fn days(of year: Int) -> Int {
  tempo.year_days(of: year)
}
