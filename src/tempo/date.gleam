//// Functions to use with the `Date` type in Tempo.
////
//// ## Example
////
//// ```gleam
//// import tempo/date
////
//// pub fn main() {
////   date.literal("2024-06-21")
////   |> date.to_string
////   // -> "2024-06-21"
////
////   date.parse("06/21/2024", tempo.CustomDate("MM/DD/YYYY"))
////   |> date.to_string
////   // -> "2024-06-21"
////
////   date.current_local()
////   |> date.to_string
////   // -> "2024-10-09"
//// }
//// ```
////
//// ```gleam
//// import tempo/date
////
//// pub fn is_older_than_a_week(date_str: String) {
////   let date = date.from_string(date_str)
////
////   date
////   |> date.is_earlier(
////      than: date |> date.subtract(days: 7)
////   )
//// }
//// ```

import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/regexp
import gleam/result
import gleam/string
import gleam/time/calendar
import tempo
import tempo/error as tempo_error
import tempo/month

/// A named day of the week.
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
///
/// ## Examples
///
/// ```gleam
/// date.new(2024, 6, 13)
/// // -> Ok(date.literal("2024-06-13"))
/// ```
///
/// ```gleam
/// date.new(2024, 6, 31)
/// // -> Error(tempo_error.DateOutOfBounds)
/// ```
pub fn new(
  year year: Int,
  month month: Int,
  day day: Int,
) -> Result(tempo.Date, tempo_error.DateOutOfBoundsError) {
  tempo.new_date(year, month, day)
}

/// Creates a new date value from a string literal, but will panic if
/// the string is invalid. Accepted formats are `YYYY-MM-DD`, `YYYY-M-D`,
/// `YYYY/MM/DD`, `YYYY/M/D`, `YYYY.MM.DD`, `YYYY.M.D`, `YYYY_MM_DD`,
/// `YYYY_M_D`, `YYYY MM DD`, `YYYY M D`, or `YYYYMMDD`.
///
/// Useful for declaring date literals that you know are valid within your
/// program.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-13")
/// |> date.to_string
/// // -> "2024-06-13"
/// ```
///
/// ```gleam
/// date.literal("20240613")
/// |> date.to_string
/// // -> "2024-06-13"
/// ```
///
/// ```gleam
/// date.literal("2409")
/// // -> panic
/// ```
pub fn literal(date: String) -> tempo.Date {
  case from_string(date) {
    Ok(date) -> date
    Error(tempo_error.DateInvalidFormat(_)) ->
      panic as "Invalid date literal format"
    Error(tempo_error.DateOutOfBounds(_, tempo_error.DateDayOutOfBounds(..))) ->
      panic as "Invalid date literal day value"
    Error(tempo_error.DateOutOfBounds(_, tempo_error.DateMonthOutOfBounds(..))) ->
      panic as "Invalid date literal month value"
    Error(tempo_error.DateOutOfBounds(_, tempo_error.DateYearOutOfBounds(..))) ->
      panic as "Invalid date literal year value"
  }
}

/// Gets the current local date of the host.
///
/// ## Examples
///
/// ```gleam
/// date.current_local()
/// |> date.to_string
/// // -> "2024-06-13"
/// ```
pub fn current_local() {
  { tempo.now_utc_ffi() + tempo.offset_local_micro() } |> from_unix_micro
}

/// Gets the current UTC date of the host.
///
/// ## Examples
///
/// ```gleam
/// date.current_utc()
/// |> date.to_string
/// // -> "2024-06-14"
/// ```
pub fn current_utc() {
  tempo.now_utc_ffi() |> from_unix_micro
}

/// Gets the year value of a date.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-13")
/// |> date.get_year
/// // -> 2024
/// ```
pub fn get_year(date: tempo.Date) -> Int {
  date |> tempo.date_get_year
}

/// Gets the month value of a date.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-13")
/// |> date.get_month
/// // -> tempo.Jun
/// ```
pub fn get_month(date: tempo.Date) -> calendar.Month {
  date |> tempo.date_get_month
}

/// Gets the day value of a date.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-13")
/// |> date.get_day
/// // -> 13
/// ```
pub fn get_day(date: tempo.Date) -> Int {
  date |> tempo.date_get_day
}

/// Gets the month value of a date.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-13")
/// |> date.get_month_year
/// // -> calendar.MonthYear(tempo.Jun, 2024)
/// ```
pub fn get_month_year(date: tempo.Date) -> tempo.MonthYear {
  date |> tempo.date_get_month_year
}

/// Parses a date string in the format `YYYY-MM-DD`, `YYYY-M-D`, `YYYY/MM/DD`,
/// `YYYY/M/D`, `YYYY.MM.DD`, `YYYY.M.D`, `YYYY_MM_DD`, `YYYY_M_D`, `YYYY MM DD`,
/// `YYYY M D`, or `YYYYMMDD`.
///
/// ## Examples
///
/// ```gleam
/// date.from_string("2024-06-13")
/// // -> Ok(date.literal("2024-06-13"))
/// ```
///
/// ```gleam
/// date.from_string("20240613")
/// // -> Ok(date.literal("2024-06-13"))
/// ```
///
/// ```gleam
/// date.from_string("2409")
/// // -> Error(tempo_error.DateInvalidFormat)
/// ```
pub fn from_string(
  date: String,
) -> Result(tempo.Date, tempo_error.DateParseError) {
  use parts <- result.try({
    split_int_tuple(date, "-")
    |> result.try_recover(fn(_) { split_int_tuple(date, on: "/") })
    |> result.try_recover(fn(_) { split_int_tuple(date, on: ".") })
    |> result.try_recover(fn(_) { split_int_tuple(date, on: "_") })
    |> result.try_recover(fn(_) { split_int_tuple(date, on: " ") })
    |> result.try_recover(fn(_) {
      let year = string.slice(date, at_index: 0, length: 4) |> int.parse
      let month = string.slice(date, at_index: 4, length: 2) |> int.parse
      let day = string.slice(date, at_index: 6, length: 2) |> int.parse

      case year, month, day {
        Ok(year), Ok(month), Ok(day) -> Ok(#(year, month, day))
        _, _, _ -> Error(tempo_error.DateInvalidFormat(date))
      }
    })
  })

  from_tuple(parts)
  |> result.map_error(tempo_error.DateOutOfBounds(date, _))
}

fn split_int_tuple(
  date: String,
  on delim: String,
) -> Result(#(Int, Int, Int), tempo_error.DateParseError) {
  string.split(date, delim)
  |> list.map(int.parse)
  |> result.all()
  |> result.try(fn(date: List(Int)) {
    case date {
      [year, month, day] -> Ok(#(year, month, day))
      _ -> Error(Nil)
    }
  })
  |> result.replace_error(tempo_error.DateInvalidFormat(date))
}

/// Returns a string representation of a date value in the format `YYYY-MM-DD`.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-13")
/// |> date.to_string
/// // -> "2024-06-13"
/// ```
pub fn to_string(date: tempo.Date) -> String {
  tempo.date_to_string(date)
}

/// Parses a date string in the provided format. Always prefer using
/// this over `parse_any`. All parsed formats must have all parts of a date.
///
/// Values can be escaped by putting brackets around them, like "[Hello!] YYYY".
///
/// Available directives: YY (two-digit year), YYYY (four-digit year), M (month),
/// MM (two-digit month), MMM (short month name), MMMM (full month name),
/// D (day of the month), DD (two-digit day of the month),
///
/// ## Example
///
/// ```gleam
/// date.parse("2024/06/08, 13:42:11", "YYYY/MM/DD")
/// // -> Ok(date.literal("2024-06-08"))
/// ```
///
/// ```gleam
/// date.parse("January 13, 2024", "MMMM DD, YYYY")
/// // -> Ok(date.literal("2024-01-13"))
/// ```
///
/// ```gleam
/// date.parse("Hi! 2024 11 13", "[Hi!] YYYY M D")
/// // -> Ok(date.literal("2024-11-13"))
/// ```
pub fn parse(
  str: String,
  in format: tempo.DateFormat,
) -> Result(tempo.Date, tempo_error.DateParseError) {
  let format_str = tempo.get_date_format_str(format)

  use #(parts, _) <- result.try(
    tempo.consume_format(str, in: format_str)
    |> result.map_error(tempo_error.DateInvalidFormat),
  )

  tempo.find_date(in: parts)
}

/// Tries to parse a given date string without a known format. It will not
/// parse two digit years and will assume the month always comes before the
/// day in a date. Will leave out any time or offset values present.
///
/// ## Example
///
/// ```gleam
/// date.parse_any("2024.06.21 01:32 PM -04:00")
/// // -> Ok(date.literal("2024-06-21"))
/// ```
///
/// ```gleam
/// date.parse_any("2024.06.21")
/// // -> Ok(date.literal("2024-06-21"))
/// ```
pub fn parse_any(str: String) -> Result(tempo.Date, tempo_error.DateParseError) {
  case tempo.parse_any(str) {
    #(Some(date), _, _) -> Ok(date)
    #(None, _, _) ->
      Error(tempo_error.DateInvalidFormat("Unable to find date in " <> str))
  }
}

/// Converts a date parse error to a human readable error message.
///
/// ## Example
///
/// ```gleam
/// date.parse_any("01:32 PM")
/// |> snag.map_error(with: date.describe_parse_error)
/// // -> snag.error("Invalid date format: 01:32 PM")
/// ```
pub fn describe_parse_error(error: tempo_error.DateParseError) -> String {
  tempo_error.describe_date_parse_error(error)
}

/// Formats a date value into a string using the provided date format.
///
/// ## Example
///
/// ```gleam
/// datetime.literal("2024-12-26T13:02:01-04:00")
/// |> datetime.format(tempo.ISO8601Date)
/// // -> "2024-12-26"
/// ```
///
/// ```gleam
/// datetime.literal("2024-06-21T13:42:11.314-04:00")
/// |> datetime.format(tempo.CustomDate("ddd @ h:mm A (z)"))
/// // -> "Fri @ 1:42 PM (-04)"
/// ```
///
/// ```gleam
/// datetime.literal("2024-06-03T09:02:01-04:00")
/// |> datetime.format(tempo.CustomDate("YY YYYY M MM MMM MMMM D DD d dd ddd"))
/// // -------------------------------> "24 2024 6 06 Jun June 3 03 1 Mo Mon"
/// ```
///
/// ```gleam
/// datetime.literal("2024-06-03T09:02:01.014920202-00:00")
/// |> datetime.format(tempo.CustomDate("dddd SSS SSSS SSSSS Z ZZ z"))
/// // -> "Monday 014 014920 014920202 -00:00 -0000 Z"
/// ```
///
/// ```gleam
/// datetime.literal("2024-06-03T13:02:01-04:00")
/// |> datetime.format(tempo.CustomDate(("H HH h hh m mm s ss a A [An ant]"))
/// // -------------------------------> "13 13 1 01 2 02 1 01 pm PM An ant"
/// ```
pub fn format(date: tempo.Date, in format: tempo.DateFormat) -> String {
  let format_str = tempo.get_date_format_str(format)

  let assert Ok(re) = regexp.from_string(tempo.format_regex)

  regexp.scan(re, format_str)
  |> list.reverse
  |> list.fold(from: [], with: fn(acc, match) {
    case match {
      regexp.Match(content, []) -> [
        tempo.date_replace_format(content, date),
        ..acc
      ]

      // If there is a non-empty subpattern, then the escape
      // character "[ ... ]" matched, so we should not change anything here.
      regexp.Match(_, [Some(sub)]) -> [sub, ..acc]

      // This case is not expected, not really sure what to do with it
      // so just prepend whatever was found
      regexp.Match(content, _) -> [content, ..acc]
    }
  })
  |> string.join("")
}

/// Returns a date value from a tuple of ints if the values represent the
/// years, month, and day of a valid date. The year must be greater than 1000.
///
/// Years less than 1000 are technically valid years, but are not common
/// and usually indicate that either a non-year value was passed as the year
/// or a two digit year was passed (which are too abiguous to be confidently
/// accepted).
///
/// ## Examples
///
/// ```gleam
/// date.from_tuple(#(2024, 6, 13))
/// // -> Ok(date.literal("2024-06-13"))
/// ```
///
/// ```gleam
/// date.from_tuple(#(98, 6, 13))
/// // -> Error(tempo_error.DateOutOfBounds)
/// ```
pub fn from_tuple(
  date: #(Int, Int, Int),
) -> Result(tempo.Date, tempo_error.DateOutOfBoundsError) {
  tempo.date_from_tuple(date)
}

/// Converts a date out of bounds error to a human readable error message.
///
/// ## Example
///
/// ```gleam
/// date.from_tuple(#(98, 6, 13))
/// |> snag.map_error(with: date.describe_out_of_bounds_error)
/// // -> snag.error("Year out of bounds in date: 98")
/// ```
pub fn describe_out_of_bounds_error(error: tempo_error.DateOutOfBoundsError) {
  tempo_error.describe_date_out_of_bounds_error(error)
}

/// Returns a tuple of ints from a date value that represent the year, month,
/// and day of the date.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-14")
/// |> date.to_tuple
/// // -> #(2024, 6, 14)
/// ```
pub fn to_tuple(date: tempo.Date) -> #(Int, Int, Int) {
  #(
    date |> tempo.date_get_year,
    month.to_int(date |> tempo.date_get_month),
    date |> tempo.date_get_day,
  )
}

/// Converts a tempo date to a calendar date.
pub fn to_calendar_date(date: tempo.Date) -> calendar.Date {
  tempo.date_to_calendar_date(date)
}

/// Converts a calendar date to a tempo date.
pub fn from_calendar_date(
  date: calendar.Date,
) -> Result(tempo.Date, tempo_error.DateOutOfBoundsError) {
  let calendar.Date(year, month, day) = date
  from_tuple(#(year, month |> month.to_int, day))
}

/// Checks if a dynamic value is a valid date string, and returns the
/// date if it is.
///
/// ## Examples
///
/// ```gleam
/// dynamic.string("2024-06-21")
/// |> date.from_dynamic_string
/// // -> Ok(date.literal("2024-06-21"))
/// ```
///
/// ```gleam
/// dynamic.string("153")
/// |> datetime.from_dynamic_string
/// // -> Error([
/// //   decode.DecodeError(
/// //     expected: "tempo.Date",
/// //     found: "Invalid format: 153",
/// //     path: [],
/// //   ),
/// // ])
/// ```
pub fn from_dynamic_string(
  dynamic_string: dynamic.Dynamic,
) -> Result(tempo.Date, List(decode.DecodeError)) {
  use date: String <- result.try(
    // Uses the decode.string function but maintains the decode.DecodeError
    // return type to maintain API compatibility.
    decode.run(dynamic_string, decode.string)
    |> result.map_error(fn(errs) {
      list.map(errs, fn(err) {
        decode.DecodeError(err.expected, err.found, err.path)
      })
    }),
  )

  case from_string(date) {
    Ok(date) -> Ok(date)
    Error(tempo_error) ->
      Error([
        decode.DecodeError(
          expected: "tempo.Date",
          found: case tempo_error {
            tempo_error.DateInvalidFormat(msg) -> msg
            tempo_error.DateOutOfBounds(msg, _) -> msg
          },
          path: [],
        ),
      ])
  }
}

/// Returns the date of a unix timestamp.
///
/// From https://howardhinnant.github.io/date_algorithms.html#civil_from_days
///
/// ## Examples
///
/// ```gleam
/// date.from_unix_seconds(267_840_000)
/// // -> date.literal("1978-06-28")
/// ```
///
/// I am making this internal because it is created but I am not sure if it
/// should be part of the public API. I think it is too easy to use incorrectly.
/// Users should probably use the 'datetime' module's 'from_unix_seconds' function
/// instead and get the date from there if they need it.
@internal
pub fn from_unix_seconds(unix_ts: Int) -> tempo.Date {
  tempo.date_from_unix_seconds(unix_ts)
}

/// Returns the UTC unix timestamp of a date, assuming the time on that date
/// is 00:00:00.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.to_unix_seconds
/// // -> 1_718_150_400
/// ```
///
/// I am making this internal because it is created but I am not sure if it
/// should be part of the public API. I think it is too easy to use incorrectly.
/// Users should probably use the 'datetime' module's 'from_unix_seconds' function
/// instead and get the date from there if they need it.
@internal
pub fn to_unix_seconds(date: tempo.Date) -> Int {
  tempo.date_to_unix_seconds(date)
}

/// Returns the UTC date of a unix timestamp in milliseconds.
///
/// From https://howardhinnant.github.io/date_algorithms.html#civil_from_days
///
/// ## Examples
///
/// ```gleam
/// date.from_unix_milli(267_840_000)
/// // -> date.literal("1978-06-28")
/// ```
///
/// I am making this internal because it is created but I am not sure if it
/// should be part of the public API. I think it is too easy to use incorrectly.
/// Users should probably use the 'datetime' module's 'from_unix_seconds' function
/// instead and get the date from there if they need it.
@internal
pub fn from_unix_milli(unix_ts: Int) -> tempo.Date {
  from_unix_seconds(unix_ts / 1000)
}

/// Returns the UTC unix timestamp in milliseconds of a date, assuming the
/// time on that date is 00:00:00.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.to_unix_milli
/// // -> 1_718_150_400_000
/// ```
///
/// I am making this internal because it is created but I am not sure if it
/// should be part of the public API. I think it is too easy to use incorrectly.
/// Users should probably use the 'datetime' module's 'from_unix_seconds' function
/// instead and get the date from there if they need it.
@internal
pub fn to_unix_milli(date: tempo.Date) -> Int {
  to_unix_seconds(date) * 1000
}

/// Returns the UTC date of a unix timestamp in microseconds.
///
/// From https://howardhinnant.github.io/date_algorithms.html#civil_from_days
///
/// ## Examples
///
/// ```gleam
/// date.from_unix_milli(267_840_000_000)
/// // -> date.literal("1978-06-28")
/// ```
///
/// I am making this internal because it is created but I am not sure if it
/// should be part of the public API. I think it is too easy to use incorrectly.
/// Users should probably use the 'datetime' module's 'from_unix_seconds' function
/// instead and get the date from there if they need it.
@internal
pub fn from_unix_micro(unix_ts: Int) -> tempo.Date {
  tempo.date_from_unix_micro(unix_ts)
}

/// Returns the UTC unix timestamp in microseconds of a date, assuming the
/// time on that date is 00:00:00.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.to_unix_micro
/// // -> 1_718_150_400_000_000
/// ```
///
/// I am making this internal because it is created but I am not sure if it
/// should be part of the public API. I think it is too easy to use incorrectly.
/// Users should probably use the 'datetime' module's 'from_unix_seconds' function
/// instead and get the date from there if they need it.
@internal
pub fn to_unix_micro(date: tempo.Date) -> Int {
  tempo.date_to_unix_micro(date)
}

/// Creates a date from a Rata Die value.
/// Adapted from the very nice Rada Gleam library!
///
/// ## Example
///
/// ```gleam
/// date.from_rata_die(739_050)
/// // -> date.literal("2024-06-13")
/// ```
pub fn from_rata_die(rata_die: Int) -> tempo.Date {
  tempo.date_from_rata_die(rata_die)
}

/// Returns the Rata Die value of the date as an Int.
/// Adapted from the very nice Rada Gleam library!
///
/// ## Example
///
/// ```gleam
/// date.literal("2024-06-13")
/// |> date.to_rata_die
/// // -> 739_050
/// ```
pub fn to_rata_die(date: tempo.Date) -> Int {
  tempo.date_to_rata_die(date)
}

/// Compares two dates.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.compare(to: date.literal("2024-06-12"))
/// // -> order.Eq
/// ```
///
/// ```gleam
/// date.literal("2024-05-12")
/// |> date.compare(to: date.literal("2024-06-13"))
/// // -> order.Lt
/// ```
///
/// ```gleam
/// date.literal("2034-06-12")
/// |> date.compare(to: date.literal("2024-06-11"))
/// // -> order.Gt
/// ```
pub fn compare(a: tempo.Date, to b: tempo.Date) -> order.Order {
  tempo.date_compare(a, b)
}

/// Checks of the first date is earlier than the second date.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.is_earlier(than: date.literal("2024-06-13"))
/// // -> True
/// ```
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.is_earlier(than: date.literal("2024-06-12"))
/// // -> False
/// ```
pub fn is_earlier(a: tempo.Date, than b: tempo.Date) -> Bool {
  tempo.date_is_earlier(a, than: b)
}

/// Checks if the first date is earlier than or equal to the second date.
///
/// ## Examples
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.is_earlier_or_equal(to: date.literal("2024-06-12"))
/// // -> True
/// ```
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.is_earlier_or_equal(to: date.literal("2024-06-11"))
/// // -> False
/// ```
pub fn is_earlier_or_equal(a: tempo.Date, to b: tempo.Date) -> Bool {
  tempo.date_is_earlier_or_equal(a, b)
}

/// Checks if two dates are equal.
///
/// ## Example
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.is_equal(to: date.literal("2024-06-12"))
/// // -> True
/// ```
pub fn is_equal(a: tempo.Date, to b: tempo.Date) -> Bool {
  tempo.date_is_equal(a, to: b)
}

/// Checks if the first date is later than the second date.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-14")
/// |> date.is_later(than: date.literal("2024-06-13"))
/// // -> True
/// ```
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.is_later(than: date.literal("2024-06-12"))
/// // -> False
/// ```
pub fn is_later(a: tempo.Date, than b: tempo.Date) -> Bool {
  tempo.date_is_later(a, than: b)
}

/// Checks if the first date is later than or equal to the second date.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.is_later_or_equal(to: date.literal("2024-06-12"))
/// // -> True
/// ```
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.is_later_or_equal(to: date.literal("2024-06-13"))
/// // -> False
/// ```
pub fn is_later_or_equal(a: tempo.Date, to b: tempo.Date) -> Bool {
  tempo.date_is_later_or_equal(a, to: b)
}

/// Gets the difference between two dates.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.difference(from: date.literal("2024-06-23"))
/// // -> 11
/// ```
///
/// ```gleam
/// date.literal("2024-06-03")
/// |> date.difference(from: date.literal("2024-06-11"))
/// // -> -9
/// ```
pub fn difference(from a: tempo.Date, to b: tempo.Date) -> Int {
  tempo.date_days_apart(from: a, to: b)
}

/// Creates a period between the first date at 00:00:00 and the second date at
/// 24:00:00. Periods only represent positive datetime differences.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.as_period(end: date.literal("2024-06-23"))
/// |> period.as_days
/// // -> 11
/// ```
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.as_period(start: date.literal("2024-06-09"))
/// |> period.comprising_dates
/// // -> ["2024-06-09", "2024-06-10", "2024-06-11", "2024-06-12"]
/// ```
pub fn as_period(start start: tempo.Date, end end: tempo.Date) -> tempo.Period {
  tempo.period_new_date(start:, end:)
}

/// Adds a number of days to a date.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.add(days: 1)
/// // -> date.literal("2024-06-13")
/// ```
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.add(days: 12)
/// // -> date.literal("2024-06-24")
/// ```
pub fn add(date: tempo.Date, days days: Int) -> tempo.Date {
  tempo.date_add(date, days: days)
}

/// Subtracts a number of days from a date.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.subtract(days: 1)
/// // -> date.literal("2024-06-11")
/// ```
///
/// ```gleam
/// date.literal("2024-06-12")
/// |> date.subtract(days: 12)
/// // -> date.literal("2024-05-31")
/// ```
pub fn subtract(date: tempo.Date, days days: Int) -> tempo.Date {
  tempo.date_subtract(date, days: days)
}

/// Returns the number of the day of week a date falls on.
/// Will be incorrect for dates before 1752 and dates after 2300.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-21")
/// |> date.to_day_of_week_number
/// // -> 5
/// ```
pub fn to_day_of_week_number(date: tempo.Date) -> Int {
  tempo.date_to_day_of_week_number(date)
}

/// Returns the day of week a date falls on.
/// Will be incorrect for dates before 1752 and dates after 2300.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-20")
/// |> date.to_day_of_week
/// // -> Thur
/// ```
pub fn to_day_of_week(date: tempo.Date) -> DayOfWeek {
  case to_day_of_week_number(date) {
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

/// Returns the short string representation of a day of the week.
///
/// ## Examples
///
/// ```gleam
/// date|> tempo.date_get_day_of_week_to_short_string(date.Mon)
/// // -> "Mon"
/// ```
pub fn day_of_week_to_short_string(day_of_week: DayOfWeek) -> String {
  case day_of_week {
    Sun -> "Sun"
    Mon -> "Mon"
    Tue -> "Tue"
    Wed -> "Wed"
    Thu -> "Thu"
    Fri -> "Fri"
    Sat -> "Sat"
  }
}

/// Returns the long string representation of a day of the week.
///
/// ## Examples
///
/// ```gleam
/// date|> tempo.date_get_day_of_week_to_long_string(date.Fri)
/// // -> "Friday"
/// ```
pub fn day_of_week_to_long_string(day_of_week: DayOfWeek) -> String {
  case day_of_week {
    Sun -> "Sunday"
    Mon -> "Monday"
    Tue -> "Tuesday"
    Wed -> "Wednesday"
    Thu -> "Thursday"
    Fri -> "Friday"
    Sat -> "Saturday"
  }
}

/// Gets the date of the next specified day of the week, exclusive of
/// the passed date.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-21")
/// |> date.next_day_of_week(date.Mon)
/// // -> date.literal("2024-06-24")
/// ```
///
/// ```gleam
/// date.literal("2024-06-21")
/// |> date.next_day_of_week(date.Fri)
/// // -> date.literal("2024-06-28")
/// ```
pub fn next_day_of_week(
  date date: tempo.Date,
  day_of_week dow: DayOfWeek,
) -> tempo.Date {
  let next = date |> add(days: 1)

  case next |> to_day_of_week == dow {
    True -> next
    False -> next_day_of_week(next, dow)
  }
}

/// Gets the date of the prior specified day of the week, exclusive of
/// the passed date.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-21")
/// |> date.prior_day_of_week(date.Mon)
/// // -> date.literal("2024-06-17")
/// ```
///
/// ```gleam
/// date.literal("2024-06-21")
/// |> date.prior_day_of_week(date.Fri)
/// // -> date.literal("2024-06-14")
/// ```
pub fn prior_day_of_week(
  date date: tempo.Date,
  day_of_week dow: DayOfWeek,
) -> tempo.Date {
  let prior = date |> subtract(days: 1)

  case prior |> to_day_of_week == dow {
    True -> prior
    False -> prior_day_of_week(prior, dow)
  }
}

/// Checks if a date falls in a weekend.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-22")
/// |> date.is_weekend
/// // -> True
/// ```
pub fn is_weekend(date: tempo.Date) -> Bool {
  case to_day_of_week(date) {
    Sat | Sun -> True
    _ -> False
  }
}

/// Gets the first date of the month a date occurs in.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-06-21")
/// |> date.first_of_month
/// // -> date.literal("2024-06-01")
/// ```
pub fn first_of_month(for date: tempo.Date) -> tempo.Date {
  let calendar_date = tempo.date_to_calendar_date(date)
  calendar.Date(calendar_date.year, calendar_date.month, 1)
  |> tempo.date_from_calendar_date
}

/// Gets the last date of the month a date occurs in.
///
/// ## Examples
///
/// ```gleam
/// date.literal("2024-02-13")
/// |> date.last_of_month
/// // -> date.literal("2024-02-29")
/// ```
pub fn last_of_month(for date: tempo.Date) -> tempo.Date {
  let calendar_date = tempo.date_to_calendar_date(date)
  calendar.Date(
    calendar_date.year,
    calendar_date.month,
    month.days(of: calendar_date.month, in: calendar_date.year),
  )
  |> tempo.date_from_calendar_date
}
