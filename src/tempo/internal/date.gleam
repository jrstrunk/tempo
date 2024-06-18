//// For date functions that are used by many modules. This has to be separate
//// from the public date module to aviod circular dependencies.

import gleam/bool
import gleam/int
import gleam/order
import tempo
import tempo/month
import tempo/year

pub fn compare(a: tempo.Date, to b: tempo.Date) -> order.Order {
  case a.year == b.year {
    True ->
      case a.month == b.month {
        True ->
          case a.day == b.day {
            True -> order.Eq
            False -> int.compare(a.day, b.day)
          }
        False -> int.compare(month.to_int(a.month), month.to_int(b.month))
      }
    False -> int.compare(a.year, b.year)
  }
}

pub fn is_earlier(a: tempo.Date, than b: tempo.Date) -> Bool {
  compare(a, b) == order.Lt
}

pub fn is_earlier_or_equal(a: tempo.Date, to b: tempo.Date) -> Bool {
  compare(a, b) == order.Lt || compare(a, b) == order.Eq
}

pub fn is_equal(a: tempo.Date, to b: tempo.Date) -> Bool {
  compare(a, b) == order.Eq
}

pub fn is_later(a: tempo.Date, than b: tempo.Date) -> Bool {
  compare(a, b) == order.Gt
}

pub fn is_later_or_equal(a: tempo.Date, to b: tempo.Date) -> Bool {
  compare(a, b) == order.Gt || compare(a, b) == order.Eq
}

pub fn to_unix_utc(date: tempo.Date) -> Int {
  let full_years_since_epoch = date.year - 1970
  // Offset the year by one to cacluate the number of leap years since the
  // epoch since 1972 is the first leap year after epoch. 1972 is a leap year,
  // so when the date is 1972, the elpased leap years (1972 has not elapsed
  // yet) is equal to (2 + 1) / 4, which is 0. When the date is 1973, the
  // elapsed leap years is equal to (3 + 1) / 4, which is 1, because one leap
  // year, 1972, has fully elapsed.
  let full_elapsed_leap_years_since_epoch = { full_years_since_epoch + 1 } / 4
  let full_elapsed_non_leap_years_since_epoch =
    full_years_since_epoch - full_elapsed_leap_years_since_epoch

  let year_milli =
    { full_elapsed_non_leap_years_since_epoch * 31_536_000 }
    + { full_elapsed_leap_years_since_epoch * 31_622_400 }

  let feb_milli = case year.is_leap_year(date.year) {
    True -> 2_505_600
    False -> 2_419_200
  }

  let month_milli = case date.month {
    tempo.Jan -> 0
    tempo.Feb -> 2_678_400
    tempo.Mar -> 2_678_400 + feb_milli
    tempo.Apr -> 5_356_800 + feb_milli
    tempo.May -> 7_948_800 + feb_milli
    tempo.Jun -> 10_627_200 + feb_milli
    tempo.Jul -> 13_219_200 + feb_milli
    tempo.Aug -> 15_897_600 + feb_milli
    tempo.Sep -> 18_576_000 + feb_milli
    tempo.Oct -> 21_168_000 + feb_milli
    tempo.Nov -> 23_846_400 + feb_milli
    tempo.Dec -> 26_438_400 + feb_milli
  }

  let day_milli = { date.day - 1 } * 86_400

  year_milli + month_milli + day_milli
}

pub fn to_unix_milli_utc(date: tempo.Date) -> Int {
  to_unix_utc(date) * 1000
}

// From https://howardhinnant.github.io/date_algorithms.html#civil_from_days
/// If unix timestamp to local date is needed, use `from_unix_utc` from the
/// `datetime` module, then use `to_current_local` and `get_date` on the
/// result. The API is designed this way to prevent misuse and resulting bugs.
pub fn from_unix_utc(unix_ts: Int) {
  let z = unix_ts / 86_400 + 719_468
  let era =
    case z >= 0 {
      True -> z
      False -> z - 146_096
    }
    / 146_097
  let doe = z - era * 146_097
  let yoe = { doe - doe / 1460 + doe / 36_524 - doe / 146_096 } / 365
  let y = yoe + era * 400
  let doy = doe - { 365 * yoe + yoe / 4 - yoe / 100 }
  let mp = { 5 * doy + 2 } / 153
  let d = doy - { 153 * mp + 2 } / 5 + 1
  let m =
    mp
    + case mp < 10 {
      True -> 3
      False -> -9
    }
  let y = y + bool.to_int(m <= 2)

  let assert Ok(month) = month.from_int(m)

  tempo.Date(y, month, d)
}

pub fn from_unix_milli_utc(unix_ts: Int) {
  from_unix_utc(unix_ts / 1000)
}
