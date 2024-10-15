//// The main module of this package. Contains most types and only a couple 
//// general purpose functions. Look in specific modules for more functionality!

import gleam/bool
import gleam/int
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

/// A datetime value with a timezone offset associated with it. It has the 
/// most amount of information about a point in time, and can be compared to 
/// all other types in this package.
pub opaque type DateTime {
  DateTime(naive: NaiveDateTime, offset: Offset)
}

@internal
pub fn datetime(naive naive, offset offset) {
  DateTime(naive, offset)
}

@internal
pub fn datetime_get_naive(datetime: DateTime) {
  datetime.naive
}

@internal
pub fn datetime_get_offset(datetime: DateTime) {
  datetime.offset
}

/// A datetime value that does not have a timezone offset associated with it. 
/// It cannot be compared to datetimes with a timezone offset accurately, but
/// can be compared to dates, times, and other naive datetimes.
pub opaque type NaiveDateTime {
  NaiveDateTime(date: Date, time: Time)
}

@internal
pub fn naive_datetime(date date: Date, time time: Time) -> NaiveDateTime {
  NaiveDateTime(date: date, time: time)
}

@internal
pub fn naive_datetime_get_date(naive_datetime: NaiveDateTime) -> Date {
  naive_datetime.date
}

@internal
pub fn naive_datetime_get_time(naive_datetime: NaiveDateTime) -> Time {
  naive_datetime.time
}

/// A timezone offset value. It represents the difference between UTC and the
/// datetime value it is associated with.
pub opaque type Offset {
  Offset(minutes: Int)
}

@internal
pub fn offset(minutes minutes) {
  Offset(minutes)
}

@internal
pub fn offset_get_minutes(offset: Offset) {
  offset.minutes
}

/// The Tempo representation of the UTC offset.
pub const utc = Offset(0)

@internal
pub fn new_offset(offset_minutes minutes: Int) -> Result(Offset, Error) {
  Offset(minutes) |> validate_offset
}

@internal
pub fn offset_from_string(offset: String) -> Result(Offset, Error) {
  case offset {
    // Parse Z format
    "Z" -> Ok(Offset(0))
    "z" -> Ok(Offset(0))

    // Parse +-hh:mm format
    _ -> {
      use #(sign, hour, minute): #(String, String, String) <- result.try(case
        string.split(offset, ":")
      {
        [hour, minute] ->
          case string.length(hour), string.length(minute) {
            3, 2 ->
              Ok(#(
                string.slice(hour, at_index: 0, length: 1),
                string.slice(hour, at_index: 1, length: 2),
                minute,
              ))
            _, _ -> Error(OffsetInvalidFormat)
          }
        _ ->
          // Parse +-hhmm format, +-hh format, or +-h format
          case string.length(offset) {
            5 ->
              Ok(#(
                string.slice(offset, at_index: 0, length: 1),
                string.slice(offset, at_index: 1, length: 2),
                string.slice(offset, at_index: 3, length: 2),
              ))
            3 ->
              Ok(#(
                string.slice(offset, at_index: 0, length: 1),
                string.slice(offset, at_index: 1, length: 2),
                "0",
              ))
            2 ->
              Ok(#(
                string.slice(offset, at_index: 0, length: 1),
                string.slice(offset, at_index: 1, length: 1),
                "0",
              ))
            _ -> Error(OffsetInvalidFormat)
          }
      })

      case sign, int.parse(hour), int.parse(minute) {
        _, Ok(0), Ok(0) -> Ok(Offset(0))
        "-", Ok(hour), Ok(minute) if hour <= 24 && minute <= 60 ->
          Ok(Offset(-{ hour * 60 + minute }))
        "+", Ok(hour), Ok(minute) if hour <= 24 && minute <= 60 ->
          Ok(Offset(hour * 60 + minute))
        _, _, _ -> Error(OffsetInvalidFormat)
      }
    }
  }
  |> result.try(validate_offset)
}

@internal
pub fn validate_offset(offset: Offset) -> Result(Offset, Error) {
  // Valid time offsets are between -12:00 and +14:00
  case offset.minutes >= -720 && offset.minutes <= 840 {
    True -> Ok(offset)
    False -> Error(OffsetOutOfBounds)
  }
}

/// A date value. It represents a specific day on the civil calendar with no
/// time of day associated with it.
pub opaque type Date {
  Date(year: Int, month: Month, day: Int)
}

@internal
pub fn date(year year, month month, day day) {
  Date(year: year, month: month, day: day)
}

@internal
pub fn date_get_year(date: Date) {
  date.year
}

@internal
pub fn date_get_month(date: Date) {
  date.month
}

@internal
pub fn date_get_day(date: Date) {
  date.day
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

@internal
pub fn days_apart(from start_date: Date, to end_date: Date) {
  // Caclulate the number of days in the years that are between (exclusive)
  // the start and end dates.
  let days_in_the_years_between = case
    calendar_years_apart(end_date, start_date)
  {
    years_apart if years_apart >= 2 ->
      list.range(1, years_apart - 1)
      |> list.map(fn(i) { date_get_year(end_date) + i |> year_days })
      |> int.sum
    _ -> 0
  }

  // Now that we have the number of days in the years between, we can ignore 
  // the fact that the start and end dates (may) be in different years and 
  // calculate the number of days in the months between (exclusive).
  let days_in_the_months_between =
    exclusive_months_between_days(start_date, end_date)

  // Now that we have the number of days in both the years and months between
  // the start and end dates, we can calculate the difference between the two 
  // dates and can ignore the fact that they may be in different years or 
  // months.
  let days_apart = case
    date_get_year(end_date) == date_get_year(start_date)
    && {
      date_get_month(end_date) |> month_to_int
      <= date_get_month(start_date) |> month_to_int
    }
  {
    True -> date_get_day(end_date) - date_get_day(start_date)
    False ->
      date_get_day(end_date)
      + {
        days_of_month(date_get_month(start_date), date_get_year(start_date))
        - date_get_day(start_date)
      }
  }

  // Now add the days from each section back up together.
  days_in_the_years_between + days_in_the_months_between + days_apart
}

fn exclusive_months_between_days(from: Date, to: Date) {
  use <- bool.guard(
    when: to |> date_get_year == from |> date_get_year
      && {
      to |> date_get_month |> month_prior |> month_to_int
      < from |> date_get_month |> month_next |> month_to_int
    },
    return: 0,
  )

  case to |> date_get_year == from |> date_get_year {
    True ->
      list.range(
        month_to_int(from |> date_get_month |> month_next),
        month_to_int(to |> date_get_month |> month_prior),
      )
      |> list.map(fn(m) {
        let assert Ok(m) = month_from_int(m)
        m
      })
    False -> {
      case to |> date_get_month == Jan {
        True -> []
        False ->
          list.range(1, month_to_int(to |> date_get_month |> month_prior))
      }
      |> list.map(fn(m) {
        let assert Ok(m) = month_from_int(m)
        m
      })
      |> list.append(
        case from |> date_get_month == Dec {
          True -> []
          False ->
            list.range(month_to_int(from |> date_get_month |> month_next), 12)
        }
        |> list.map(fn(m) {
          let assert Ok(m) = month_from_int(m)
          m
        }),
      )
    }
  }
  |> list.map(fn(m) { days_of_month(m, in: to |> date_get_year) })
  |> int.sum
}

fn calendar_years_apart(later: Date, from earlier: Date) -> Int {
  later.year - earlier.year
}

@internal
pub type TimePrecision {
  Sec
  Milli
  Micro
  Nano
}

/// A time of day value. It represents a specific time on an unspecified date.
/// It cannot be greater than 24 hours or less than 0 hours. It can have 
/// different precisions between second and nanosecond, depending on what 
/// your application needs.
/// 
/// Do not use the `==` operator to check for time equality (it will not
/// handle time precision correctly)! Use the compare functions instead.
pub opaque type Time {
  Time(
    hour: Int,
    minute: Int,
    second: Int,
    nanosecond: Int,
    precision: TimePrecision,
    monotonic: option.Option(MonotonicTime),
  )
}

pub type MonotonicTime {
  MonotonicTime(nanoseconds: Int, unique: Int)
}

@internal
pub fn time(
  hour hour,
  minute minute,
  second second,
  nano nanosecond,
  prec precision,
  mono monotonic,
) {
  Time(hour:, minute:, second:, nanosecond:, precision:, monotonic:)
}

@internal
pub fn time_get_hour(time: Time) {
  time.hour
}

@internal
pub fn time_get_minute(time: Time) {
  time.minute
}

@internal
pub fn time_get_second(time: Time) {
  time.second
}

@internal
pub fn time_get_nano(time: Time) {
  time.nanosecond
}

@internal
pub fn time_get_prec(time: Time) {
  time.precision
}

@internal
pub fn time_get_mono(time: Time) {
  time.monotonic
}

@internal
pub fn time_set_mono(time: Time, monotonic) {
  Time(
    time.hour,
    time.minute,
    time.second,
    time.nanosecond,
    time.precision,
    monotonic: Some(monotonic),
  )
}

@internal
pub fn new_time(hour: Int, minute: Int, second: Int) -> Result(Time, Error) {
  Time(hour, minute, second, 0, Sec, None) |> validate_time
}

@internal
pub fn new_time_milli(
  hour: Int,
  minute: Int,
  second: Int,
  millisecond: Int,
) -> Result(Time, Error) {
  Time(hour, minute, second, millisecond * 1_000_000, Milli, None)
  |> validate_time
}

@internal
pub fn new_time_micro(
  hour: Int,
  minute: Int,
  second: Int,
  microsecond: Int,
) -> Result(Time, Error) {
  Time(hour, minute, second, microsecond * 1000, Micro, None) |> validate_time
}

@internal
pub fn new_time_nano(
  hour: Int,
  minute: Int,
  second: Int,
  nanosecond: Int,
) -> Result(Time, Error) {
  Time(hour, minute, second, nanosecond, Nano, None) |> validate_time
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
        Time(_, _, _, _, Sec, _) -> Ok(time)
        Time(_, _, _, millis, Milli, _) if millis <= 999_000_000 -> Ok(time)
        Time(_, _, _, micros, Micro, _) if micros <= 999_999_000 -> Ok(time)
        Time(_, _, _, nanos, Nano, _) if nanos <= 999_999_999 -> Ok(time)
        _ -> Error(TimeOutOfBounds)
      }
    False -> Error(TimeOutOfBounds)
  }
}

@internal
pub fn adjust_12_hour_to_24_hour(hour, am am) {
  case am, hour {
    True, _ if hour == 12 -> 0
    True, _ -> hour
    False, _ if hour == 12 -> hour
    False, _ -> hour + 12
  }
}

/// A duration between two times. It represents a range of time values and
/// can be span more than a day. It can be used to calculate the number of
/// days, weeks, hours, minutes, or seconds between two times, but cannot
/// accurately be used to calculate the number of years or months between.
/// 
/// It is also used as the basis for specifying how to increase or decrease
/// a datetime or time value.
pub opaque type Duration {
  Duration(nanoseconds: Int)
}

@internal
pub fn duration(nanoseconds nanoseconds) {
  Duration(nanoseconds)
}

@internal
pub fn duration_get_ns(duration: Duration) {
  duration.nanoseconds
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
pub fn month_from_short_string(month: String) -> Result(Month, Error) {
  case month {
    "Jan" -> Ok(Jan)
    "Feb" -> Ok(Feb)
    "Mar" -> Ok(Mar)
    "Apr" -> Ok(Apr)
    "May" -> Ok(May)
    "Jun" -> Ok(Jun)
    "Jul" -> Ok(Jul)
    "Aug" -> Ok(Aug)
    "Sep" -> Ok(Sep)
    "Oct" -> Ok(Oct)
    "Nov" -> Ok(Nov)
    "Dec" -> Ok(Dec)
    _ -> Error(MonthInvalidFormat)
  }
}

@internal
pub fn month_from_long_string(month: String) -> Result(Month, Error) {
  case month {
    "January" -> Ok(Jan)
    "February" -> Ok(Feb)
    "March" -> Ok(Mar)
    "April" -> Ok(Apr)
    "May" -> Ok(May)
    "June" -> Ok(Jun)
    "July" -> Ok(Jul)
    "August" -> Ok(Aug)
    "September" -> Ok(Sep)
    "October" -> Ok(Oct)
    "November" -> Ok(Nov)
    "December" -> Ok(Dec)
    _ -> Error(MonthInvalidFormat)
  }
}

@internal
pub fn month_to_int(month: Month) -> Int {
  case month {
    Jan -> 1
    Feb -> 2
    Mar -> 3
    Apr -> 4
    May -> 5
    Jun -> 6
    Jul -> 7
    Aug -> 8
    Sep -> 9
    Oct -> 10
    Nov -> 11
    Dec -> 12
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
pub fn month_next(month: Month) -> Month {
  case month {
    Jan -> Feb
    Feb -> Mar
    Mar -> Apr
    Apr -> May
    May -> Jun
    Jun -> Jul
    Jul -> Aug
    Aug -> Sep
    Sep -> Oct
    Oct -> Nov
    Nov -> Dec
    Dec -> Jan
  }
}

@internal
pub fn month_prior(month: Month) -> Month {
  case month {
    Jan -> Dec
    Feb -> Jan
    Mar -> Feb
    Apr -> Mar
    May -> Apr
    Jun -> May
    Jul -> Jun
    Aug -> Jul
    Sep -> Aug
    Oct -> Sep
    Nov -> Oct
    Dec -> Nov
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

@internal
pub fn year_days(of year: Int) -> Int {
  case is_leap_year(year) {
    True -> 366
    False -> 365
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

/// Tries to parse a given date string without a known format. It will not 
/// parse two digit years and will assume the month always comes before the 
/// day in a date. Always prefer to use a module's specific `parse` function
/// when possible.
/// 
/// Using pattern matching, you can explicitly specify what to with the 
/// missing values from the input. Many libaries will assume a missing time
/// value means 00:00:00 or a missing offset means UTC. This design
/// lets the user decide how fallbacks are handled. 
/// 
/// ## Example
/// 
/// ```gleam
/// case tempo.parse_any("06/21/2024 at 01:42:11 PM") {
///   Ok(#(Some(date), Some(time), Some(offset))) ->
///     datetime.new(date, time, offset)
/// 
///   Ok(#(Some(date), Some(time), None)) ->
///     datetime.new(date, time, offset.local())
/// 
///   _ -> datetime.now_local()
/// }
/// // -> datetime.literal("2024-06-21T13:42:11-04:00")
/// ```
/// 
/// ```gleam
/// tempo.parse_any("2024.06.21 11:32 AM -0400")
/// // -> Ok(#(
/// //  Some(date.literal("2024-06-21")), 
/// //  Some(time.literal("11:32:00")),
/// //  Some(offset.literal("-04:00"))
/// // ))
/// ```
/// 
/// ```gleam
/// tempo.parse_any("Dec 25, 2024 at 6:00 AM")
/// // -> Ok(#(
/// //  Some(date.literal("2024-12-25")), 
/// //  Some(time.literal("06:00:00")),
/// //  None
/// // ))
/// ```
pub fn parse_any(
  str: String,
) -> Result(
  #(option.Option(Date), option.Option(Time), option.Option(Offset)),
  Error,
) {
  use serial_re <- result.try(
    regex.from_string("\\d{9,}") |> result.replace_error(InvalidInputShape),
  )

  use <- bool.guard(
    when: regex.check(serial_re, str),
    return: Error(InvalidInputShape),
  )

  use date_re <- result.try(
    regex.from_string(
      "(\\d{4})[-_/\\.\\s,]{0,2}(\\d{2})[-_/\\.\\s,]{0,2}(\\d{2})",
    )
    |> result.replace_error(InvalidInputShape),
  )

  use date_human_re <- result.try(
    regex.from_string(
      "(\\d{2}|January|Jan|january|jan|February|Feb|february|feb|March|Mar|march|mar|April|Apr|april|apr|May|may|June|Jun|june|jun|July|Jul|july|jul|August|Aug|august|aug|September|Sep|september|sep|October|Oct|october|oct|November|Nov|november|nov|December|Dec|december|dec)[-_/\\.\\s,]{0,2}(\\d{2})[-_/\\.\\s,]{0,2}(\\d{4})",
    )
    |> result.replace_error(InvalidInputShape),
  )

  use time_re <- result.try(
    regex.from_string(
      "(\\d{1,2})[:_\\.\\s]{0,1}(\\d{1,2})[:_\\.\\s]{0,1}(\\d{0,2})[\\.]{0,1}(\\d{0,9})\\s*(AM|PM|am|pm)?",
    )
    |> result.replace_error(InvalidInputShape),
  )

  use offset_re <- result.try(
    regex.from_string("([-+]\\d{2}):{0,1}(\\d{1,2})?")
    |> result.replace_error(InvalidInputShape),
  )

  use offset_char_re <- result.try(
    regex.from_string("(?<![a-zA-Z])[Zz](?![a-zA-Z])")
    |> result.replace_error(InvalidInputShape),
  )

  let unconsumed = str

  let #(date, unconsumed): #(option.Option(Date), String) = {
    case regex.scan(date_re, unconsumed) {
      [regex.Match(content, [Some(year), Some(month), Some(day)]), ..] ->
        case int.parse(year), int.parse(month), int.parse(day) {
          Ok(year), Ok(month), Ok(day) ->
            case new_date(year, month, day) {
              Ok(date) -> #(Some(date), string.replace(unconsumed, content, ""))

              _ -> #(None, unconsumed)
            }

          _, _, _ -> #(None, unconsumed)
        }

      _ -> #(None, unconsumed)
    }
  }

  let #(date, unconsumed): #(option.Option(Date), String) = {
    case date {
      Some(d) -> #(Some(d), unconsumed)
      None ->
        case regex.scan(date_human_re, unconsumed) {
          [regex.Match(content, [Some(month), Some(day), Some(year)]), ..] ->
            case
              int.parse(year),
              // Parse an int month or a written month
              int.parse(month)
              |> result.replace_error(MonthInvalidFormat)
              |> result.try(month_from_int)
              |> result.try_recover(fn(_) {
                month_from_short_string(month)
                |> result.try_recover(fn(_) { month_from_long_string(month) })
              }),
              int.parse(day)
            {
              Ok(year), Ok(month), Ok(day) ->
                case new_date(year, month_to_int(month), day) {
                  Ok(date) -> #(
                    Some(date),
                    string.replace(unconsumed, content, ""),
                  )

                  _ -> #(None, unconsumed)
                }

              _, _, _ -> #(None, unconsumed)
            }

          _ -> #(None, unconsumed)
        }
    }
  }

  let #(offset, unconsumed): #(option.Option(Offset), String) = {
    case regex.scan(offset_re, unconsumed) {
      [regex.Match(content, [Some(hours), Some(minutes)]), ..] ->
        case int.parse(hours), int.parse(minutes) {
          Ok(hour), Ok(minute) ->
            case new_offset(hour * 60 + minute) {
              Ok(offset) -> #(
                Some(offset),
                string.replace(unconsumed, content, ""),
              )

              _ -> #(None, unconsumed)
            }

          _, _ -> #(None, unconsumed)
        }

      _ -> #(None, unconsumed)
    }
  }

  let #(offset, unconsumed): #(option.Option(Offset), String) = {
    case offset {
      Some(o) -> #(Some(o), unconsumed)
      None ->
        case regex.scan(offset_char_re, unconsumed) {
          [regex.Match(content, _), ..] -> #(
            Some(utc),
            string.replace(unconsumed, content, ""),
          )

          _ -> #(None, unconsumed)
        }
    }
  }

  let #(time, _): #(option.Option(Time), String) = {
    let scan_results = regex.scan(time_re, unconsumed)

    let adj_hour = case scan_results {
      [regex.Match(_, [_, _, _, _, Some("PM")]), ..] -> adjust_12_hour_to_24_hour(
        _,
        am: False,
      )
      [regex.Match(_, [_, _, _, _, Some("pm")]), ..] -> adjust_12_hour_to_24_hour(
        _,
        am: False,
      )
      [regex.Match(_, [_, _, _, _, Some("AM")]), ..] -> adjust_12_hour_to_24_hour(
        _,
        am: True,
      )
      [regex.Match(_, [_, _, _, _, Some("am")]), ..] -> adjust_12_hour_to_24_hour(
        _,
        am: True,
      )
      _ -> fn(hour) { hour }
    }

    case scan_results {
      [regex.Match(content, [Some(h), Some(m), Some(s), Some(d), ..]), ..] ->
        case int.parse(h), int.parse(m), int.parse(s) {
          Ok(hour), Ok(minute), Ok(second) ->
            case string.length(d), int.parse(d) {
              3, Ok(milli) ->
                case adj_hour(hour) |> new_time_milli(minute, second, milli) {
                  Ok(date) -> #(
                    Some(date),
                    string.replace(unconsumed, content, ""),
                  )

                  _ -> #(None, unconsumed)
                }
              6, Ok(micro) ->
                case adj_hour(hour) |> new_time_micro(minute, second, micro) {
                  Ok(date) -> #(
                    Some(date),
                    string.replace(unconsumed, content, ""),
                  )

                  _ -> #(None, unconsumed)
                }

              9, Ok(nano) ->
                case adj_hour(hour) |> new_time_nano(minute, second, nano) {
                  Ok(date) -> #(
                    Some(date),
                    string.replace(unconsumed, content, ""),
                  )

                  _ -> #(None, unconsumed)
                }

              _, _ -> #(None, unconsumed)
            }

          _, _, _ -> #(None, unconsumed)
        }

      [regex.Match(content, [Some(h), Some(m), Some(s), ..]), ..] ->
        case int.parse(h), int.parse(m), int.parse(s) {
          Ok(hour), Ok(minute), Ok(second) ->
            case adj_hour(hour) |> new_time(minute, second) {
              Ok(date) -> #(Some(date), string.replace(unconsumed, content, ""))

              _ -> #(None, unconsumed)
            }

          _, _, _ -> #(None, unconsumed)
        }

      [regex.Match(content, [Some(h), Some(m), ..]), ..] ->
        case int.parse(h), int.parse(m) {
          Ok(hour), Ok(minute) ->
            case adj_hour(hour) |> new_time(minute, 0) {
              Ok(date) -> #(Some(date), string.replace(unconsumed, content, ""))

              _ -> #(None, unconsumed)
            }

          _, _ -> #(None, unconsumed)
        }

      _ -> #(None, unconsumed)
    }
  }

  Ok(#(date, time, offset))
}

@external(erlang, "tempo_ffi", "now")
@external(javascript, "./tempo_ffi.mjs", "now")
@internal
pub fn now_utc() -> Int

@external(erlang, "tempo_ffi", "now_monotonic")
@external(javascript, "./tempo_ffi.mjs", "now")
@internal
pub fn now_monotonic() -> Int

@external(erlang, "tempo_ffi", "now_unique")
@external(javascript, "./tempo_ffi.mjs", "now_unique")
@internal
pub fn now_unique() -> Int

@internal
pub fn now_monounique() -> MonotonicTime {
  MonotonicTime(now_monotonic(), now_unique())
}

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
      "\\[([^\\]]+)\\]|Y{1,4}|M{1,4}|D{1,2}|d{1,4}|H{1,2}|h{1,2}|a|A|m{1,2}|s{1,2}|Z{1,2}|SSS{3,5}|.",
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

@internal
pub fn find_year(in parts) {
  list.find_map(parts, fn(p) {
    case p {
      Year(y) -> Ok(y)
      _ -> Error(Nil)
    }
  })
  |> result.replace_error(ParseMissingDate)
}

@internal
pub fn find_month(in parts) {
  list.find_map(parts, fn(p) {
    case p {
      Month(m) -> Ok(m)
      _ -> Error(Nil)
    }
  })
  |> result.replace_error(ParseMissingDate)
}

@internal
pub fn find_day(in parts) {
  list.find_map(parts, fn(p) {
    case p {
      Day(d) -> Ok(d)
      _ -> Error(Nil)
    }
  })
  |> result.replace_error(ParseMissingDate)
}

@internal
pub fn find_hour(in parts) {
  use _ <- result.try_recover(
    list.find_map(parts, fn(p) {
      case p {
        Hour(h) -> Ok(h)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(ParseMissingTime),
  )

  use twelve_hour <- result.try(
    list.find_map(parts, fn(p) {
      case p {
        TwelveHour(o) -> Ok(o)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(ParseMissingTime),
  )

  let am_period =
    list.find_map(parts, fn(p) {
      case p {
        AMPeriod -> Ok(Nil)
        _ -> Error(Nil)
      }
    })

  let pm_period =
    list.find_map(parts, fn(p) {
      case p {
        PMPeriod -> Ok(Nil)
        _ -> Error(Nil)
      }
    })

  case am_period, pm_period {
    Ok(Nil), Error(Nil) ->
      adjust_12_hour_to_24_hour(twelve_hour, am: True) |> Ok
    Error(Nil), Ok(Nil) ->
      adjust_12_hour_to_24_hour(twelve_hour, am: False) |> Ok

    _, _ -> Error(ParseMissingTime)
  }
}

@internal
pub fn find_minute(in parts) {
  list.find_map(parts, fn(p) {
    case p {
      Minute(m) -> Ok(m)
      _ -> Error(Nil)
    }
  })
  |> result.replace_error(ParseMissingTime)
}

@internal
pub fn find_date(in parts) {
  use year <- result.try(
    list.find_map(parts, fn(p) {
      case p {
        Year(y) -> Ok(y)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(ParseMissingDate),
  )

  use month <- result.try(
    list.find_map(parts, fn(p) {
      case p {
        Month(m) -> Ok(m)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(ParseMissingDate),
  )

  use day <- result.try(
    list.find_map(parts, fn(p) {
      case p {
        Day(d) -> Ok(d)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(ParseMissingDate),
  )

  new_date(year, month, day)
}

@internal
pub fn find_time(in parts) {
  use hour <- result.try({
    use _ <- result.try_recover(
      list.find_map(parts, fn(p) {
        case p {
          Hour(h) -> Ok(h)
          _ -> Error(Nil)
        }
      })
      |> result.replace_error(ParseMissingTime),
    )

    use twelve_hour <- result.try(
      list.find_map(parts, fn(p) {
        case p {
          TwelveHour(o) -> Ok(o)
          _ -> Error(Nil)
        }
      })
      |> result.replace_error(ParseMissingTime),
    )

    let am_period =
      list.find_map(parts, fn(p) {
        case p {
          AMPeriod -> Ok(Nil)
          _ -> Error(Nil)
        }
      })

    let pm_period =
      list.find_map(parts, fn(p) {
        case p {
          PMPeriod -> Ok(Nil)
          _ -> Error(Nil)
        }
      })

    case am_period, pm_period {
      Ok(Nil), Error(Nil) ->
        adjust_12_hour_to_24_hour(twelve_hour, am: True) |> Ok
      Error(Nil), Ok(Nil) ->
        adjust_12_hour_to_24_hour(twelve_hour, am: False) |> Ok

      _, _ -> Error(ParseMissingTime)
    }
  })

  use minute <- result.try(
    list.find_map(parts, fn(p) {
      case p {
        Minute(m) -> Ok(m)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(ParseMissingTime),
  )

  let second =
    list.find_map(parts, fn(p) {
      case p {
        Second(s) -> Ok(s)
        _ -> Error(Nil)
      }
    })
    |> result.unwrap(0)

  let millisecond =
    list.find_map(parts, fn(p) {
      case p {
        Millisecond(n) -> Ok(n)
        _ -> Error(Nil)
      }
    })

  let microsecond =
    list.find_map(parts, fn(p) {
      case p {
        Microsecond(n) -> Ok(n)
        _ -> Error(Nil)
      }
    })

  let nanosecond =
    list.find_map(parts, fn(p) {
      case p {
        Nanosecond(n) -> Ok(n)
        _ -> Error(Nil)
      }
    })

  case nanosecond, microsecond, millisecond {
    Ok(nano), _, _ -> new_time_nano(hour, minute, second, nano)
    _, Ok(micro), _ -> new_time_micro(hour, minute, second, micro)
    _, _, Ok(milli) -> new_time_milli(hour, minute, second, milli)
    _, _, _ -> new_time(hour, minute, second)
  }
}

@internal
pub fn find_offset(in parts) {
  use offset_str <- result.try(
    list.find_map(parts, fn(p) {
      case p {
        OffsetStr(o) -> Ok(o)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(ParseMissingOffset),
  )

  offset_from_string(offset_str)
}

@external(erlang, "tempo_ffi", "current_year")
@external(javascript, "./tempo_ffi.mjs", "current_year")
fn current_year() -> Int

@internal
pub const format_regex = "\\[([^\\]]+)\\]|Y{1,4}|M{1,4}|D{1,2}|d{1,4}|H{1,2}|h{1,2}|a|A|m{1,2}|s{1,2}|Z{1,2}|z|SSSSS|SSSS|SSS|."
