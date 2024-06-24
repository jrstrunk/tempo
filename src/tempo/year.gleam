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
  case year % 4 == 0 {
    True ->
      case year % 100 == 0 {
        True ->
          case year % 400 == 0 {
            True -> True
            False -> False
          }
        False -> True
      }
    False -> False
  }
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
  case is_leap_year(year) {
    True -> 366
    False -> 365
  }
}
