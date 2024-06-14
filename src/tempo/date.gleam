import gleam/bool
import gleam/int
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import gleam/string_builder
import tempo
import tempo/month
import tempo/year

/// Creates a new date and validates it.
pub fn new(
  year year: Int,
  month month: Int,
  day day: Int,
) -> Result(tempo.Date, Nil) {
  from_tuple(#(year, month, day))
}

/// Useful for declaring date literals that you know are valid within your  
/// program. Will crash if an invalid date is provided. 
pub fn literal(date: String) -> tempo.Date {
  let assert Ok(date) = from_string(date)
  date
}

/// Parses a date string in the format `YYYY-MM-DD`, `YYYY-M-D`, `YYYY/MM/DD`, 
/// `YYYY/M/D`, `YYYY.MM.DD`, `YYYY.M.D`, `YYYY_MM_DD`, `YYYY_M_D`, `YYYY MM DD`,
/// `YYYY M D`, or `YYYYMMDD`.
pub fn from_string(date: String) -> Result(tempo.Date, Nil) {
  split_date_str(date, "-")
  |> result.try_recover(fn(_) { split_date_str(date, on: "/") })
  |> result.try_recover(fn(_) { split_date_str(date, on: ".") })
  |> result.try_recover(fn(_) { split_date_str(date, on: "_") })
  |> result.try_recover(fn(_) { split_date_str(date, on: " ") })
  |> result.try_recover(fn(_) {
    let year = string.slice(date, at_index: 0, length: 4) |> int.parse
    let month = string.slice(date, at_index: 4, length: 2) |> int.parse
    let day = string.slice(date, at_index: 6, length: 2) |> int.parse

    case year, month, day {
      Ok(year), Ok(month), Ok(day) -> Ok(#(year, month, day))
      _, _, _ -> Error(Nil)
    }
  })
  |> result.try(from_tuple)
}

fn split_date_str(date: String, on delim: String) {
  string.split(date, delim)
  |> list.map(int.parse)
  |> result.all()
  |> result.try(fn(date: List(Int)) {
    case date {
      [year, month, day] -> Ok(#(year, month, day))
      _ -> Error(Nil)
    }
  })
}

pub fn to_string(date: tempo.Date) -> String {
  string_builder.from_strings([
    int.to_string(date.year),
    "-",
    month.to_int(date.month) |> int.to_string |> string.pad_left(2, with: "0"),
    "-",
    int.to_string(date.day) |> string.pad_left(2, with: "0"),
  ])
  |> string_builder.to_string
}

/// Years less than 1000 are valid, but not common and usually indicate that
/// a non-year value was passed as in the year index or a two digit year was
/// passed. Two digit year values are too abiguous to be confidently accepted.
pub fn from_tuple(date: #(Int, Int, Int)) -> Result(tempo.Date, Nil) {
  let year = date.0
  let month = date.1
  let day = date.2

  use month <- result.try(month.from_int(month))

  case year >= 1000 && year <= 9999 {
    True ->
      case day >= 1 && day <= month.get_days(month, year) {
        True -> Ok(tempo.Date(year, month, day))
        False -> Error(Nil)
      }
    False -> Error(Nil)
  }
}

pub fn to_tuple(date: tempo.Date) -> #(Int, Int, Int) {
  #(date.year, month.to_int(date.month), date.day)
}

pub fn compare(a: tempo.Date, to b: tempo.Date) -> order.Order {
  case a.year == b.year {
    True ->
      case a.month == b.month {
        True ->
          case a.day == b.day {
            True -> order.Eq
            False ->
              case a.day < b.day {
                True -> order.Lt
                False -> order.Gt
              }
          }
        False ->
          case month.to_int(a.month) < month.to_int(b.month) {
            True -> order.Lt
            False -> order.Gt
          }
      }
    False ->
      case a.year < b.year {
        True -> order.Lt
        False -> order.Gt
      }
  }
}

pub fn is_earlier(a: tempo.Date, than b: tempo.Date) -> Bool {
  compare(a, b) == order.Lt
}

pub fn is_earlier_or_equal(a: tempo.Date, than b: tempo.Date) -> Bool {
  compare(a, b) == order.Lt || compare(a, b) == order.Eq
}

pub fn is_equal(a: tempo.Date, to b: tempo.Date) -> Bool {
  compare(a, b) == order.Eq
}

pub fn is_later(a: tempo.Date, than b: tempo.Date) -> Bool {
  compare(a, b) == order.Gt
}

pub fn is_later_or_equal(a: tempo.Date, than b: tempo.Date) -> Bool {
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

pub fn from_unix_utc_milli(unix_ts: Int) {
  from_unix_utc(unix_ts / 1000)
}

pub fn add_days(date: tempo.Date, days: Int) -> tempo.Date {
  let days_left_this_month = month.get_days(date.month, date.year) - date.day
  case days < days_left_this_month {
    True -> tempo.Date(date.year, date.month, date.day + days)
    False -> {
      let next_month = month.get_next(date.month)
      let year = case next_month == tempo.Jan {
        True -> date.year + 1
        False -> date.year
      }

      add_days(tempo.Date(year, next_month, 1), days - days_left_this_month - 1)
    }
  }
}

pub fn subtract_days(date: tempo.Date, days: Int) -> tempo.Date {
  case days < date.day {
    True -> tempo.Date(date.year, date.month, date.day - days)
    False -> {
      let prior_month = month.get_prior(date.month)
      let year = case prior_month == tempo.Dec {
        True -> date.year - 1
        False -> date.year
      }

      subtract_days(
        tempo.Date(year, prior_month, month.get_days(prior_month, year)),
        days - date.day,
      )
    }
  }
}

// This will be incorrect for dates before 1752 and dates after 2300.
pub fn to_weekday(date: tempo.Date) {
  let year_code =
    date.year % 100
    |> fn(short_year) { { short_year + { short_year / 4 } } % 7 }

  let month_code = case date.month {
    tempo.Jan -> 0
    tempo.Feb -> 3
    tempo.Mar -> 3
    tempo.Apr -> 6
    tempo.May -> 1
    tempo.Jun -> 4
    tempo.Jul -> 6
    tempo.Aug -> 2
    tempo.Sep -> 5
    tempo.Oct -> 0
    tempo.Nov -> 3
    tempo.Dec -> 5
  }

  let century_code = case date.year {
    year if year < 1752 -> 0
    year if year < 1800 -> 4
    year if year < 1900 -> 2
    year if year < 2000 -> 0
    year if year < 2100 -> 6
    year if year < 2200 -> 4
    year if year < 2300 -> 2
    year if year < 2400 -> 4
    _ -> 0
  }

  let leap_year_code = case year.is_leap_year(date.year) {
    True ->
      case date.month {
        tempo.Jan | tempo.Feb -> 1
        _ -> 0
      }
    False -> 0
  }

  let day_of_week: Int =
    { year_code + month_code + century_code + date.day - leap_year_code } % 7

  case day_of_week {
    0 -> tempo.Sun
    1 -> tempo.Mon
    2 -> tempo.Tue
    3 -> tempo.Wed
    4 -> tempo.Thu
    5 -> tempo.Fri
    6 -> tempo.Sat
    _ -> panic as "Invalid day of week found after modulo by 7"
  }
}

pub fn is_weekend(date: tempo.Date) -> Bool {
  case to_weekday(date) {
    tempo.Sat | tempo.Sun -> True
    _ -> False
  }
}
