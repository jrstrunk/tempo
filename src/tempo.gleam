//// The types defined here will become opaque in a later version once the 
//// package is more mature and if Gleam allows for types to be opaque only to 
//// the public interface. Try not to construct these types directly. If you
//// find the need to, consider contributing to the package so your needs can
//// be met and handled properly by the package itself. 

import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/regex
import gleam/result
import gleam/string

pub type Error {
  TimeInvalidFormat
  TimeOutOfBounds
  DateInvalidFormat
  DateOutOfBounds
  MonthInvalidFormat
  MonthOutOfBounds
  OffsetInvalidFormat
  OffsetOutOfBounds
  NaiveDateTimeInvalidFormat
  DateTimeInvalidFormat
  InvalidInputShape
  UnableToParseDirective(String)
  ParseMissingDate
  ParseMissingTime
  ParseMissingOffset
}

/// A datetime value that does not have a timezone offset associated with it. 
/// It cannot be compared to datetimes with a timezone offset accurately, but
/// can be compared to dates, times, and other naive datetimes.
pub type NaiveDateTime {
  NaiveDateTime(date: Date, time: Time)
}

/// A datetime value with a timezone offset associated with it. It has the 
/// most amount of information about a point in time, and can be compared to 
/// all other types in this package.
pub type DateTime {
  DateTime(naive: NaiveDateTime, offset: Offset)
}

/// A timezone offset value. It represents the difference between UTC and the
/// datetime value it is associated with.
pub type Offset {
  Offset(minutes: Int)
}

pub fn new_offset(offset_minutes minutes: Int) -> Result(Offset, Error) {
  Offset(minutes) |> validate_offset
}

pub fn validate_offset(offset: Offset) -> Result(Offset, Error) {
  // Valid time offsets are between -12:00 and +14:00
  case offset.minutes >= -720 && offset.minutes <= 840 {
    True -> Ok(offset)
    False -> Error(OffsetOutOfBounds)
  }
}

/// A date value. It represents a specific day on the civil calendar with no
/// time of day associated with it.
pub type Date {
  Date(year: Int, month: Month, day: Int)
}

@internal
pub fn new_date(
  year year: Int,
  month month: Int,
  day day: Int,
) -> Result(Date, Error) {
  date_from_tuple(#(year, month, day))
}

@internal
pub fn date_from_tuple(date: #(Int, Int, Int)) -> Result(Date, Error) {
  let year = date.0
  let month = date.1
  let day = date.2

  use month <- result.try(month_from_int(month))

  case year >= 1000 && year <= 9999 {
    True ->
      case day >= 1 && day <= days_of_month(month, in: year) {
        True -> Ok(Date(year, month, day))
        False -> Error(DateOutOfBounds)
      }
    False -> Error(DateOutOfBounds)
  }
}

/// A period between two calendar datetimes. It represents a range of
/// datetimes and can be used to calculate the number of days, weeks, months, 
/// or years between two dates. It can also be interated over and datetime 
/// values can be checked for inclusion in the period.
pub type Period {
  NaivePeriod(start: NaiveDateTime, end: NaiveDateTime)
  Period(start: DateTime, end: DateTime)
}

/// A time of day value. It represents a specific time on an unspecified date.
/// It cannot be greater than 24 hours or less than 0 hours. It can have 
/// different precisions between second and nanosecond, depending on what 
/// your application needs.
/// 
/// Do not use the `==` operator to check for time equality (it will not
/// handle time precision correctly)! Use the compare functions instead.
pub type Time {
  Time(hour: Int, minute: Int, second: Int, nanosecond: Int)
  TimeMilli(hour: Int, minute: Int, second: Int, nanosecond: Int)
  TimeMicro(hour: Int, minute: Int, second: Int, nanosecond: Int)
  TimeNano(hour: Int, minute: Int, second: Int, nanosecond: Int)
}

@internal
pub fn new_time(hour: Int, minute: Int, second: Int) -> Result(Time, Error) {
  Time(hour, minute, second, 0) |> validate_time
}

@internal
pub fn new_time_milli(
  hour: Int,
  minute: Int,
  second: Int,
  millisecond: Int,
) -> Result(Time, Error) {
  TimeMilli(hour, minute, second, millisecond * 1_000_000)
  |> validate_time
}

@internal
pub fn new_micro(
  hour: Int,
  minute: Int,
  second: Int,
  microsecond: Int,
) -> Result(Time, Error) {
  TimeMicro(hour, minute, second, microsecond * 1000) |> validate_time
}

@internal
pub fn new_nano(
  hour: Int,
  minute: Int,
  second: Int,
  nanosecond: Int,
) -> Result(Time, Error) {
  TimeNano(hour, minute, second, nanosecond) |> validate_time
}

@internal
pub fn validate_time(time: Time) -> Result(Time, Error) {
  case
    {
      time.hour >= 0
      && time.hour <= 23
      && time.minute >= 0
      && time.minute <= 59
      && time.second >= 0
      && time.second <= 59
    }
    // For end of day time https://en.wikipedia.org/wiki/ISO_8601
    || {
      time.hour == 24
      && time.minute == 0
      && time.second == 0
      && time.nanosecond == 0
    }
    // For leap seconds https://en.wikipedia.org/wiki/Leap_second. Leap seconds
    // are not fully supported by this package, but can be parsed from ISO 8601
    // dates.
    || { time.minute == 59 && time.second == 60 && time.nanosecond == 0 }
  {
    True ->
      case time {
        Time(_, _, _, _) -> Ok(time)
        TimeMilli(_, _, _, millis) if millis <= 999_000_000 -> Ok(time)
        TimeMicro(_, _, _, micros) if micros <= 999_999_000 -> Ok(time)
        TimeNano(_, _, _, nanos) if nanos <= 999_999_999 -> Ok(time)
        _ -> Error(TimeOutOfBounds)
      }
    False -> Error(TimeOutOfBounds)
  }
}

/// A duration between two times. It represents a range of time values and
/// can be span more than a day. It can be used to calculate the number of
/// days, weeks, hours, minutes, or seconds between two times, but cannot
/// accurately be used to calculate the number of years or months between.
/// 
/// It is also used as the basis for specifying how to increase or decrease
/// a datetime or time value.
pub type Duration {
  Duration(nanoseconds: Int)
}

/// A month in a specific year.
pub type MonthYear {
  MonthYear(month: Month, year: Int)
}

/// A specific month on the civil calendar. 
pub type Month {
  Jan
  Feb
  Mar
  Apr
  May
  Jun
  Jul
  Aug
  Sep
  Oct
  Nov
  Dec
}

/// An ordered list of all months in the year.
pub const months = [Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec]

@internal
pub fn month_from_int(month: Int) -> Result(Month, Error) {
  case month {
    1 -> Ok(Jan)
    2 -> Ok(Feb)
    3 -> Ok(Mar)
    4 -> Ok(Apr)
    5 -> Ok(May)
    6 -> Ok(Jun)
    7 -> Ok(Jul)
    8 -> Ok(Aug)
    9 -> Ok(Sep)
    10 -> Ok(Oct)
    11 -> Ok(Nov)
    12 -> Ok(Dec)
    _ -> Error(MonthOutOfBounds)
  }
}

@internal
pub fn days_of_month(month: Month, in year: Int) -> Int {
  case month {
    Jan -> 31
    Mar -> 31
    May -> 31
    Jul -> 31
    Aug -> 31
    Oct -> 31
    Dec -> 31
    _ ->
      case month {
        Apr -> 30
        Jun -> 30
        Sep -> 30
        Nov -> 30
        _ ->
          case is_leap_year(year) {
            True -> 29
            False -> 28
          }
      }
  }
}

@internal
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

/// The result of an uncertain conversion. Since this package does not track
/// timezone offsets, it uses the host system's offset to convert to local
/// time. If the datetime being converted to local time is of a different
/// day than the current one, the offset value provided by the host may
/// not be accurate (and could be accurate by up to the amount the offset 
/// changes throughout the year). To account for this, when converting to 
/// local time, a precise value is returned when the datetime being converted
/// is in th current date, while an imprecise value is returned when it is
/// on any other date. This allows the application logic to handle the 
/// two cases differently: some applications may only need to convert to 
/// local time on the current date or may only need generic time 
/// representations, while other applications may need precise conversions 
/// for arbitrary dates. More notes on how to plug time zones into this
/// package to aviod uncertain conversions can be found in the README.
pub type UncertainConversion(a) {
  Precise(a)
  Imprecise(a)
}

/// Accepts either a precise or imprecise value of an uncertain conversion.
/// Useful for pipelines.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-21T23:17:00Z")
/// |> datetime.to_local
/// |> tempo.accept_imprecision
/// |> datetime.to_string
/// // -> "2024-06-21T19:17:00-04:00"
/// ```
pub fn accept_imprecision(conv: UncertainConversion(a)) -> a {
  case conv {
    Precise(a) -> a
    Imprecise(a) -> a
  }
}

/// Either returns a precise value or an error from an uncertain conversion.
/// Useful for pipelines. 
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-21T23:17:00Z")
/// |> datetime.to_local
/// |> tempo.error_on_imprecision
/// |> result.try(do_important_precise_task)
/// ```
pub fn error_on_imprecision(conv: UncertainConversion(a)) -> Result(a, Nil) {
  case conv {
    Precise(a) -> Ok(a)
    Imprecise(_) -> Error(Nil)
  }
}

@external(erlang, "tempo_ffi", "now")
@external(javascript, "./tempo_ffi.mjs", "now")
@internal
pub fn now_utc() -> Int

@internal
pub type DatetimePart {
  Year(Int)
  Month(Int)
  Day(Int)
  Hour(Int)
  Minute(Int)
  Second(Int)
  Millisecond(Int)
  Microsecond(Int)
  Nanosecond(Int)
  OffsetStr(String)
  TwelveHour(Int)
  AMPeriod
  PMPeriod
  Passthrough
}

@internal
pub fn consume_format(str: String, in fmt: String) {
  let assert Ok(re) =
    regex.from_string(
      "\\[([^\\]]+)]|Y{1,4}|M{1,4}|D{1,2}|d{1,4}|H{1,2}|h{1,2}|a|A|m{1,2}|s{1,2}|Z{1,2}|SSS{3,5}|.",
    )

  regex.scan(re, fmt)
  |> list.fold(from: Ok(#([], str)), with: fn(acc, match) {
    case acc {
      Ok(acc) -> {
        let #(consumed, input) = acc

        let res = case match {
          regex.Match(content, []) -> consume_part(content, input)

          // If there is a non-empty subpattern, then the escape 
          // character "[ ... ]" matched, so we should not change anything here.
          regex.Match(_, [Some(sub)]) ->
            Ok(#(Passthrough, string.drop_left(input, string.length(sub))))

          // This case is not expected, not really sure what to do with it 
          // so just pass through whatever was found
          regex.Match(content, _) ->
            Ok(#(Passthrough, string.drop_left(input, string.length(content))))
        }

        case res {
          Ok(#(part, not_consumed)) -> Ok(#([part, ..consumed], not_consumed))
          Error(err) -> Error(err)
        }
      }
      Error(err) -> Error(err)
    }
  })
}

fn consume_part(fmt, from str) {
  case fmt {
    "YY" -> {
      use val <- result.map(
        string.slice(str, at_index: 0, length: 2) |> int.parse,
      )

      let current_year = current_year()

      let current_century = { current_year / 100 } * 100
      let current_two_year_date = current_year % 100

      case val > current_two_year_date {
        True -> #(
          Year({ current_century - 100 } + val),
          string.drop_left(str, 2),
        )
        False -> #(Year(current_century + val), string.drop_left(str, 2))
      }
    }
    "YYYY" -> {
      use year <- result.map(
        string.slice(str, at_index: 0, length: 4) |> int.parse,
      )

      #(Year(year), string.drop_left(str, 4))
    }
    "M" -> consume_one_or_two_digits(str, Month)
    "MM" -> consume_two_digits(str, Month)
    "MMM" -> {
      case str {
        "Jan" <> rest -> Ok(#(Month(1), rest))
        "Feb" <> rest -> Ok(#(Month(2), rest))
        "Mar" <> rest -> Ok(#(Month(3), rest))
        "Apr" <> rest -> Ok(#(Month(4), rest))
        "May" <> rest -> Ok(#(Month(5), rest))
        "Jun" <> rest -> Ok(#(Month(6), rest))
        "Jul" <> rest -> Ok(#(Month(7), rest))
        "Aug" <> rest -> Ok(#(Month(8), rest))
        "Sep" <> rest -> Ok(#(Month(9), rest))
        "Oct" <> rest -> Ok(#(Month(10), rest))
        "Nov" <> rest -> Ok(#(Month(11), rest))
        "Dec" <> rest -> Ok(#(Month(12), rest))
        _ -> Error(Nil)
      }
    }
    "MMMM" -> {
      case str {
        "January" <> rest -> Ok(#(Month(1), rest))
        "February" <> rest -> Ok(#(Month(2), rest))
        "March" <> rest -> Ok(#(Month(3), rest))
        "April" <> rest -> Ok(#(Month(4), rest))
        "May" <> rest -> Ok(#(Month(5), rest))
        "June" <> rest -> Ok(#(Month(6), rest))
        "July" <> rest -> Ok(#(Month(7), rest))
        "August" <> rest -> Ok(#(Month(8), rest))
        "September" <> rest -> Ok(#(Month(9), rest))
        "October" <> rest -> Ok(#(Month(10), rest))
        "November" <> rest -> Ok(#(Month(11), rest))
        "December" <> rest -> Ok(#(Month(12), rest))
        _ -> Error(Nil)
      }
    }
    "D" -> consume_one_or_two_digits(str, Day)
    "DD" -> consume_two_digits(str, Day)
    "H" -> consume_one_or_two_digits(str, Hour)
    "HH" -> consume_two_digits(str, Hour)
    "h" -> consume_one_or_two_digits(str, TwelveHour)
    "hh" -> consume_two_digits(str, TwelveHour)
    "a" -> {
      case str {
        "am" <> rest -> Ok(#(AMPeriod, rest))
        "pm" <> rest -> Ok(#(PMPeriod, rest))
        _ -> Error(Nil)
      }
    }
    "A" -> {
      case str {
        "AM" <> rest -> Ok(#(AMPeriod, rest))
        "PM" <> rest -> Ok(#(PMPeriod, rest))
        _ -> Error(Nil)
      }
    }
    "m" -> consume_one_or_two_digits(str, Minute)
    "mm" -> consume_two_digits(str, Minute)
    "s" -> consume_one_or_two_digits(str, Second)
    "ss" -> consume_two_digits(str, Second)
    "SSS" -> {
      use milli <- result.map(
        string.slice(str, at_index: 0, length: 3) |> int.parse,
      )

      #(Millisecond(milli), string.drop_left(str, 3))
    }
    "SSSS" -> {
      use micro <- result.map(
        string.slice(str, at_index: 0, length: 6) |> int.parse,
      )

      #(Microsecond(micro), string.drop_left(str, 6))
    }
    "SSSSS" -> {
      use nano <- result.map(
        string.slice(str, at_index: 0, length: 9) |> int.parse,
      )

      #(Nanosecond(nano), string.drop_left(str, 9))
    }
    "z" -> {
      // Offsets can be 1, 3, 5, or 6 characters long. Try parsing from
      // largest to smallest because a small pattern may incorrectly match
      // a subset of a larger value.
      use _ <- result.try_recover(
        string.slice(str, at_index: 0, length: 6)
        |> fn(offset) {
          use re <- result.try(
            regex.from_string("[-+]\\d\\d:\\d\\d") |> result.nil_error,
          )

          case regex.check(re, offset) {
            True -> Ok(offset)
            False -> Error(Nil)
          }
        }
        |> result.map(fn(offset) {
          #(OffsetStr(offset), string.drop_left(str, 6))
        }),
      )
      use _ <- result.try_recover(
        string.slice(str, at_index: 0, length: 5)
        |> fn(offset) {
          use re <- result.try(
            regex.from_string("[-+]\\d\\d\\d\\d") |> result.nil_error,
          )

          case regex.check(re, offset) {
            True -> Ok(offset)
            False -> Error(Nil)
          }
        }
        |> result.map(fn(offset) {
          #(OffsetStr(offset), string.drop_left(str, 5))
        }),
      )
      use _ <- result.try_recover(
        string.slice(str, at_index: 0, length: 3)
        |> fn(offset) {
          use re <- result.try(
            regex.from_string("[-+]\\d\\d") |> result.nil_error,
          )

          case regex.check(re, offset) {
            True -> Ok(offset)
            False -> Error(Nil)
          }
        }
        |> result.map(fn(offset) {
          #(OffsetStr(offset), string.drop_left(str, 3))
        }),
      )
      use _ <- result.try_recover(
        string.slice(str, at_index: 0, length: 1)
        |> fn(offset) {
          case offset == "Z" || offset == "z" {
            True -> Ok(offset)
            False -> Error(Nil)
          }
        }
        |> result.map(fn(offset) {
          #(OffsetStr(offset), string.drop_left(str, 1))
        }),
      )
      Error(Nil)
    }
    "Z" -> {
      Ok(#(
        OffsetStr(string.slice(str, at_index: 0, length: 6)),
        string.drop_left(str, 6),
      ))
    }
    "ZZ" -> {
      Ok(#(
        OffsetStr(string.slice(str, at_index: 0, length: 5)),
        string.drop_left(str, 5),
      ))
    }
    passthrough -> {
      let fmt_length = string.length(passthrough)
      let str_slice = string.slice(str, at_index: 0, length: fmt_length)

      case str_slice == passthrough {
        True -> Ok(#(Passthrough, string.drop_left(str, fmt_length)))
        False -> Error(Nil)
      }
    }
  }
  |> result.replace_error(UnableToParseDirective(fmt))
}

fn consume_one_or_two_digits(str, constructor) {
  case string.slice(str, at_index: 0, length: 2) |> int.parse {
    Ok(val) -> Ok(#(constructor(val), string.drop_left(str, 2)))
    Error(_) ->
      case string.slice(str, at_index: 0, length: 1) |> int.parse {
        Ok(val) -> Ok(#(constructor(val), string.drop_left(str, 1)))
        Error(_) -> Error(Nil)
      }
  }
}

fn consume_two_digits(str, constructor) {
  use val <- result.map(string.slice(str, at_index: 0, length: 2) |> int.parse)

  #(constructor(val), string.drop_left(str, 2))
}

@external(erlang, "ffi", "current_year")
@external(javascript, "./ffi.mjs", "current_year")
fn current_year() -> Int
