import gleam/list
import gleam/result
import tempo
import tempo/year

pub const months = [
  tempo.Jan, tempo.Feb, tempo.Mar, tempo.Apr, tempo.May, tempo.Jun, tempo.Jul,
  tempo.Aug, tempo.Sep, tempo.Oct, tempo.Nov, tempo.Dec,
]

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

pub fn from_short_string(month: String) -> Result(tempo.Month, Nil) {
  case month {
    "Jan" -> Ok(tempo.Jan)
    "Feb" -> Ok(tempo.Feb)
    "Mar" -> Ok(tempo.Mar)
    "Apr" -> Ok(tempo.Apr)
    "May" -> Ok(tempo.May)
    "Jun" -> Ok(tempo.Jun)
    "Jul" -> Ok(tempo.Jul)
    "Aug" -> Ok(tempo.Aug)
    "Sep" -> Ok(tempo.Sep)
    "Oct" -> Ok(tempo.Oct)
    "Nov" -> Ok(tempo.Nov)
    "Dec" -> Ok(tempo.Dec)
    _ -> Error(Nil)
  }
}

pub fn from_long_string(month: String) -> Result(tempo.Month, Nil) {
  case month {
    "January" -> Ok(tempo.Jan)
    "February" -> Ok(tempo.Feb)
    "March" -> Ok(tempo.Mar)
    "April" -> Ok(tempo.Apr)
    "May" -> Ok(tempo.May)
    "June" -> Ok(tempo.Jun)
    "July" -> Ok(tempo.Jul)
    "August" -> Ok(tempo.Aug)
    "September" -> Ok(tempo.Sep)
    "October" -> Ok(tempo.Oct)
    "November" -> Ok(tempo.Nov)
    "December" -> Ok(tempo.Dec)
    _ -> Error(Nil)
  }
}

pub fn to_int(month: tempo.Month) -> Int {
  case month {
    tempo.Jan -> 1
    tempo.Feb -> 2
    tempo.Mar -> 3
    tempo.Apr -> 4
    tempo.May -> 5
    tempo.Jun -> 6
    tempo.Jul -> 7
    tempo.Aug -> 8
    tempo.Sep -> 9
    tempo.Oct -> 10
    tempo.Nov -> 11
    tempo.Dec -> 12
  }
}

pub fn from_int(month: Int) -> Result(tempo.Month, Nil) {
  case month {
    1 -> Ok(tempo.Jan)
    2 -> Ok(tempo.Feb)
    3 -> Ok(tempo.Mar)
    4 -> Ok(tempo.Apr)
    5 -> Ok(tempo.May)
    6 -> Ok(tempo.Jun)
    7 -> Ok(tempo.Jul)
    8 -> Ok(tempo.Aug)
    9 -> Ok(tempo.Sep)
    10 -> Ok(tempo.Oct)
    11 -> Ok(tempo.Nov)
    12 -> Ok(tempo.Dec)
    _ -> Error(Nil)
  }
}

pub fn days(of month: tempo.Month, in year: Int) -> Int {
  case month {
    tempo.Jan -> 31
    tempo.Mar -> 31
    tempo.May -> 31
    tempo.Jul -> 31
    tempo.Aug -> 31
    tempo.Oct -> 31
    tempo.Dec -> 31
    _ ->
      case month {
        tempo.Apr -> 30
        tempo.Jun -> 30
        tempo.Sep -> 30
        tempo.Nov -> 30
        _ ->
          case year.is_leap_year(year) {
            True -> 29
            False -> 28
          }
      }
  }
}

pub fn next(month: tempo.Month) -> tempo.Month {
  case month {
    tempo.Jan -> tempo.Feb
    tempo.Feb -> tempo.Mar
    tempo.Mar -> tempo.Apr
    tempo.Apr -> tempo.May
    tempo.May -> tempo.Jun
    tempo.Jun -> tempo.Jul
    tempo.Jul -> tempo.Aug
    tempo.Aug -> tempo.Sep
    tempo.Sep -> tempo.Oct
    tempo.Oct -> tempo.Nov
    tempo.Nov -> tempo.Dec
    tempo.Dec -> tempo.Jan
  }
}

pub fn prior(month: tempo.Month) -> tempo.Month {
  case month {
    tempo.Jan -> tempo.Dec
    tempo.Feb -> tempo.Jan
    tempo.Mar -> tempo.Feb
    tempo.Apr -> tempo.Mar
    tempo.May -> tempo.Apr
    tempo.Jun -> tempo.May
    tempo.Jul -> tempo.Jun
    tempo.Aug -> tempo.Jul
    tempo.Sep -> tempo.Aug
    tempo.Oct -> tempo.Sep
    tempo.Nov -> tempo.Oct
    tempo.Dec -> tempo.Nov
  }
}

type LeapSecond {
  LeapSecond(month: tempo.Month, year: Int, seconds: Int)
}

const announced_leap_seconds = [
  LeapSecond(tempo.Jun, 1972, seconds: 1),
  LeapSecond(tempo.Dec, 1972, seconds: 1),
  LeapSecond(tempo.Dec, 1973, seconds: 1),
  LeapSecond(tempo.Dec, 1974, seconds: 1),
  LeapSecond(tempo.Dec, 1975, seconds: 1),
  LeapSecond(tempo.Dec, 1976, seconds: 1),
  LeapSecond(tempo.Dec, 1977, seconds: 1),
  LeapSecond(tempo.Dec, 1978, seconds: 1),
  LeapSecond(tempo.Dec, 1979, seconds: 1),
  LeapSecond(tempo.Jun, 1981, seconds: 1),
  LeapSecond(tempo.Jun, 1982, seconds: 1),
  LeapSecond(tempo.Jun, 1983, seconds: 1),
  LeapSecond(tempo.Jun, 1985, seconds: 1),
  LeapSecond(tempo.Dec, 1987, seconds: 1),
  LeapSecond(tempo.Dec, 1989, seconds: 1),
  LeapSecond(tempo.Dec, 1990, seconds: 1),
  LeapSecond(tempo.Jun, 1992, seconds: 1),
  LeapSecond(tempo.Jun, 1993, seconds: 1),
  LeapSecond(tempo.Jun, 1994, seconds: 1),
  LeapSecond(tempo.Dec, 1995, seconds: 1),
  LeapSecond(tempo.Jun, 1997, seconds: 1),
  LeapSecond(tempo.Dec, 1998, seconds: 1),
  LeapSecond(tempo.Dec, 2005, seconds: 1),
  LeapSecond(tempo.Dec, 2008, seconds: 1),
  LeapSecond(tempo.Jun, 2012, seconds: 1),
  LeapSecond(tempo.Jun, 2015, seconds: 1),
  LeapSecond(tempo.Dec, 2016, seconds: 1),
]

// See https://en.wikipedia.org/wiki/Leap_second
pub fn leap_seconds(of month: tempo.Month, in year: Int) {
  list.find(announced_leap_seconds, fn(leap_second) {
    leap_second.month == month && leap_second.year == year
  })
  |> result.map(fn(leap_second) { leap_second.seconds })
  |> result.unwrap(0)
}
