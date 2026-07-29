//// Functions to use with years in Tempo. Years are pretty simple thankfully.
////
//// All functions in this module interpret years as
//// [proleptic Gregorian calendar](https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar)
//// years, meaning the Gregorian rules are applied to every year including
//// those before the calendar's 1582 adoption. They accept any year value, not
//// just the 1000 to 9999 range that the `tempo/date` constructors are limited
//// to.

import tempo

/// Checks if a year is a leap year, according to the proleptic Gregorian
/// calendar: a year is a leap year when it is divisible by 4, except for
/// century years, which must be divisible by 400.
///
/// Any year value is accepted, including years before the Gregorian calendar
/// was adopted in 1582, for which the Gregorian rules are applied anyway.
/// This is not a historical claim about the Julian calendar those years were
/// actually recorded in, where every fourth year was a leap year with no
/// century exception.
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
///
/// ```gleam
/// // A century year not divisible by 400 is not a leap year
/// year.is_leap_year(1900)
/// // -> False
/// ```
pub fn is_leap_year(year: Int) -> Bool {
  tempo.is_leap_year(year)
}

/// Get the number of days in a proleptic Gregorian calendar year, so always
/// 365 or 366. Accounts for leap years using the Gregorian rules described in
/// `is_leap_year`.
///
/// Any year value is accepted, not just the 1000 to 9999 range that the
/// `tempo/date` constructors are limited to.
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
