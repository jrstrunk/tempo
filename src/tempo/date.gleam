import gleam/int
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import gleam/string_builder
import tempo
import tempo/internal/date
import tempo/month
import tempo/offset
import tempo/period
import tempo/year

pub type DayOfWeek {
  Sun
  Mon
  Tue
  Wed
  Thu
  Fri
  Sat
}

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
  case from_string(date) {
    Ok(date) -> date
    Error(Nil) -> panic as "Invalid date literal"
  }
}

pub fn current_local() {
  { tempo.now_utc() + offset.local_nano() } / 1_000_000_000
  |> from_unix_utc
}

pub fn current_utc() {
  tempo.now_utc() / 1_000_000_000
  |> from_unix_utc
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
      case day >= 1 && day <= month.days(of: month, in: year) {
        True -> Ok(tempo.Date(year, month, day))
        False -> Error(Nil)
      }
    False -> Error(Nil)
  }
}

pub fn to_unix_utc(date: tempo.Date) -> Int {
  date.to_unix_utc(date)
}

pub fn to_unix_milli_utc(date: tempo.Date) -> Int {
  date.to_unix_utc(date)
}

// From https://howardhinnant.github.io/date_algorithms.html#civil_from_days
/// If unix timestamp to local date is needed, use `from_unix_utc` from the
/// `datetime` module, then use `to_current_local` and `get_date` on the
/// result. The API is designed this way to prevent misuse and resulting bugs.
pub fn from_unix_utc(unix_ts: Int) {
  date.from_unix_utc(unix_ts)
}

pub fn from_unix_milli_utc(unix_ts: Int) {
  date.from_unix_milli_utc(unix_ts)
}

pub fn to_tuple(date: tempo.Date) -> #(Int, Int, Int) {
  #(date.year, month.to_int(date.month), date.day)
}

pub fn compare(a: tempo.Date, to b: tempo.Date) -> order.Order {
  date.compare(a, to: b)
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

pub fn as_period(start: tempo.Date, end: tempo.Date) -> tempo.Period {
  period.new(
    tempo.NaiveDateTime(start, tempo.Time(0, 0, 0, 0)),
    tempo.NaiveDateTime(end, tempo.Time(0, 0, 0, 0)),
  )
}

pub fn difference(of a: tempo.Date, from b: tempo.Date) -> tempo.Period {
  period.new(
    tempo.NaiveDateTime(a, tempo.Time(0, 0, 0, 0)),
    tempo.NaiveDateTime(b, tempo.Time(0, 0, 0, 0)),
  )
}

pub fn add(date: tempo.Date, days days: Int) -> tempo.Date {
  let days_left_this_month =
    month.days(of: date.month, in: date.year) - date.day
  case days < days_left_this_month {
    True -> tempo.Date(date.year, date.month, date.day + days)
    False -> {
      let next_month = month.next(date.month)
      let year = case next_month == tempo.Jan {
        True -> date.year + 1
        False -> date.year
      }

      add(tempo.Date(year, next_month, 1), days - days_left_this_month - 1)
    }
  }
}

pub fn subtract(date: tempo.Date, days days: Int) -> tempo.Date {
  case days < date.day {
    True -> tempo.Date(date.year, date.month, date.day - days)
    False -> {
      let prior_month = month.prior(date.month)
      let year = case prior_month == tempo.Dec {
        True -> date.year - 1
        False -> date.year
      }

      subtract(
        tempo.Date(year, prior_month, month.days(of: prior_month, in: year)),
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
    0 -> Sun
    1 -> Mon
    2 -> Tue
    3 -> Wed
    4 -> Thu
    5 -> Fri
    6 -> Sat
    _ -> panic as "Invalid day of week found after modulo by 7"
  }
}

pub fn is_weekend(date: tempo.Date) -> Bool {
  case to_weekday(date) {
    Sat | Sun -> True
    _ -> False
  }
}
