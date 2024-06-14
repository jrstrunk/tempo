import tempo
import tempo/year

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

pub fn get_days(month: tempo.Month, year: Int) -> Int {
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

pub fn get_next(month: tempo.Month) -> tempo.Month {
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

pub fn get_prior(month: tempo.Month) -> tempo.Month {
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
