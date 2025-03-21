//// Functions to use with the `Period` type in Tempo. Periods represent a 
//// positive range of dates or datetimes.
//// 
//// ## Example
//// 
//// ```gleam
//// import tempo/period
//// import tempo/date
//// 
//// pub fn get_days_between(datetime1, datetime2) {
////   period.from_datetimes(start: datetime1, end: datetime2)
////   |> period.as_days
////   // -> 11
//// }
//// ```
//// 
//// ```gleam
//// import tempo/period
//// import tempo/date
//// 
//// pub fn get_every_friday_between(date1, date2) {
////   period.from_days(date1, date2)
////   |> period.comprising_dates
////   |> list.filter(fn(date) { 
////     date.to_day_of_week(date) == date.Fri
////   })
////   // -> ["2024-06-21", "2024-06-28", "2024-07-05"]
//// }
//// ```

import gleam/int
import gleam/time/calendar
import gleam/time/duration
import gtempo/internal as unit
import tempo
import tempo/date
import tempo/duration as tempo_duration
import tempo/month
import tempo/time

@deprecated("Use `period.from_datetimes` instead")
pub fn new(start start, end end) {
  from_datetimes(start:, end:)
}

@deprecated("Use `period.from_naive_datetimes` instead")
pub fn new_naive(start start, end end) {
  from_naive_datetimes(start:, end:)
}

/// Creates a new period from the start and end datetimes.
/// 
/// ## Examples
/// 
/// ```gleam
/// period.from_datetimes(
///   start: datetime.literal("2024-06-13T15:47:00+06:00"),
///   end: datetime.literal("2024-06-21T07:16:12+06:00"),
/// )
/// |> period.as_days
/// // -> 7
/// ```
pub fn from_datetimes(
  start start: tempo.DateTime,
  end end: tempo.DateTime,
) -> tempo.Period {
  tempo.period_new(start:, end:)
}

/// Creates a new period from the start and end dates.
/// 
/// ## Examples
/// 
/// ```gleam
/// period.from_dates(
///   start: date.literal("2024-06-13"),
///   end: date.literal("2024-06-21"),
/// )
/// |> period.as_days
/// // -> 7
/// ```
pub fn from_dates(start start: tempo.Date, end end: tempo.Date) -> tempo.Period {
  tempo.period_new_naive(
    start: tempo.NaiveDateTime(start, time.start_of_day),
    end: tempo.NaiveDateTime(end, time.end_of_day),
  )
}

/// Creates a new period from the start and end naive datetimes.
/// 
/// ## Examples
/// 
/// ```gleam
/// period.from_naive_datetimes(
///   start: naive_datetime.literal("2024-06-13T15:47:00"),
///   end: naive_datetime.literal("2024-06-21T07:16:12"),
/// )
/// |> period.as_days
/// // -> 7
/// ```
pub fn from_naive_datetimes(
  start start: tempo.NaiveDateTime,
  end end: tempo.NaiveDateTime,
) -> tempo.Period {
  tempo.period_new_naive(start:, end:)
}

// The period API is very similar to the duration API, mostly just with a 
// focus on calendar dates, different adding / subtracting rules, and being 
// only positive.

pub type Unit {
  Year
  Month
  Week
  Day
  Hour
  Minute
  Second
  Millisecond
  Microsecond
}

/// Returns the number of seconds in the period.
/// 
/// Does **not** account for leap seconds like the rest of the package.
/// 
/// ## Examples
/// 
/// ```gleam
/// period.new(
///   start: naive_datetime.literal("2024-06-13T07:16:32"),
///   end: naive_datetime.literal("2024-06-13T07:16:12"),
/// )
/// |> period.as_seconds
/// // -> 20
/// ```
pub fn as_seconds(period: tempo.Period) -> Int {
  as_duration(period)
  |> tempo_duration.as_seconds
}

/// Returns the number of days in the period.
/// 
/// ## Examples
/// 
/// ```gleam
/// period.new(
///   start: naive_datetime.literal("2024-06-13T15:47:00"),
///   end: naive_datetime.literal("2024-06-21T07:16:12"),
/// )
/// |> period.as_days
/// // -> 7
/// ```
pub fn as_days(period: tempo.Period) -> Int {
  let #(start_date, end_date, start_time, end_time) =
    tempo.period_get_start_and_end_date_and_time(period)

  tempo.date_days_apart(start_date, end_date)
  // If a full day has not elapsed since the start time (based on the time), 
  // then 1 needs to be taken off the days count.
  + case start_time |> time.is_later(than: end_time) {
    True -> -1
    False -> 0
  }
  // If a full day is in the period as designated by the end time being
  // the last instant of the day and the start time being the first second
  // of the day, then 1 needs to be added to the days count.
  + case
    start_time
    |> time.is_equal(to: tempo.time_start_of_day)
    && end_time
    |> time.is_equal(to: tempo.time_end_of_day)
  {
    True -> 1
    False -> 0
  }
}

/// Returns the number of days in the period.
/// 
/// Does **not** account for leap seconds like the rest of the package.
/// 
/// ## Examples
/// 
/// ```gleam
/// period.new(
///   start: naive_datetime.literal("2024-06-13T15:47:00"),
///   end: naive_datetime.literal("2024-06-21T07:16:12"),
/// )
/// |> period.as_days_fractional
/// // -> 7.645277777777778
/// ```
pub fn as_days_fractional(period: tempo.Period) -> Float {
  let #(_, _, start_time, end_time) =
    tempo.period_get_start_and_end_date_and_time(period)

  { as_days(period) |> int.to_float }
  +. case start_time |> time.is_later(than: end_time) {
    // The time until the end of the start date divided by the total number
    // of seconds in the start day plus the time since the beginning of the
    // end date divided by the total number of seconds in the end day.
    True ->
      int.to_float(
        start_time
        |> time.left_in_day
        |> time.to_duration
        |> tempo_duration.as_microseconds,
      )
      /. int.to_float(unit.day_microseconds)
      +. int.to_float(
        end_time
        |> time.to_duration
        |> tempo_duration.as_microseconds,
      )
      /. int.to_float(unit.day_microseconds)

    // The time between the start and end times divided by the total number 
    // of seconds in the end day.
    False ->
      // The as_days functions alread accounted for the time between the
      // start and end dates when the end is at the last instant of the day,
      // so we do not need to account for it here as well.
      case time.is_equal(end_time, to: tempo.time_end_of_day) {
        True -> 0.0
        False ->
          int.to_float(
            time.difference(from: start_time, to: end_time)
            |> tempo_duration.as_microseconds,
          )
          /. int.to_float(unit.day_microseconds)
      }
  }
}

/// Returns a period as a duration, losing the context of the start and end 
/// datetimes.
/// 
/// ## Example
/// 
/// ```gleam
/// period.new(
///   start: naive_datetime.literal("2024-06-13T15:47:00"),
///   end: naive_datetime.literal("2024-06-21T07:16:12"),
/// )
/// |> period.as_duration
/// |> duration.as_weeks
/// // -> 1
/// ```
pub fn as_duration(period: tempo.Period) -> duration.Duration {
  tempo.period_as_duration(period)
}

/// Creates a period of the specified month year, starting at 00:00:00 on the
/// first day of the month and ending at 24:00:00 on the last day of the month.
/// 
/// 
/// ## Examples
/// 
/// ```gleam
/// period.from_month(tempo.MonthYear(tempo.Feb, 2024))
/// |> period.contains_date(date.literal("2024-06-21"))
/// // -> False
/// ```
pub fn from_month(my: tempo.MonthYear) -> tempo.Period {
  let start =
    tempo.naive_datetime(
      tempo.date_from_calendar_date(calendar.Date(my.year, my.month, 1)),
      tempo.time_start_of_day,
    )

  let end =
    tempo.naive_datetime(
      tempo.date_from_calendar_date(calendar.Date(
        my.year,
        my.month,
        month.days(of: my.month, in: my.year),
      )),
      tempo.time_end_of_day,
    )

  from_naive_datetimes(start, end)
}

/// Checks if a date is contained within a period, inclusive of the start and
/// end datetimes.
/// 
/// ## Examples
/// 
/// ```gleam
/// period.from_month(tempo.Jun, 2024)
/// |> period.contains_date(date.literal("2024-06-30"))
/// // -> True
/// ```
/// 
/// ```gleam
/// period.from_month(tempo.Jun, 2024)
/// |> period.contains_date(date.literal("2024-07-22"))
/// // -> False
/// ```
/// 
/// ```gleam
/// date.literal("2024-06-13")
/// |> date.difference(from: date.literal("2024-06-21"))
/// |> period.contains_date(date.literal("2024-06-21"))
/// // -> True
/// ```
/// 
/// ```gleam
/// date.literal("2024-06-13")
/// |> date.difference(from: date.literal("2024-06-21"))
/// |> period.contains_date(date.literal("2024-06-27"))
/// // -> False
/// ```
pub fn contains_date(period: tempo.Period, date: tempo.Date) -> Bool {
  let #(start_date, end_date, _, _) =
    tempo.period_get_start_and_end_date_and_time(period)

  date |> date.is_later_or_equal(to: start_date)
  && date
  |> date.is_earlier_or_equal(to: end_date)
}

/// Checks if a naive datetime is contained within a period, inclusive of the
/// start and end datetimes.
/// 
/// ## Examples
/// 
/// ```gleam
/// period.from_month(tempo.Jun, 2024)
/// |> period.contains_naive_datetime(
///   naive_datetime.literal("2024-06-30T24:00:00"),
/// )
/// // -> True
/// ```
/// 
/// ```gleam
/// period.from_month(tempo.Jun, 2024)
/// |> period.contains_naive_datetime(
///   naive_datetime.literal("2024-07-22T24:00:00"),
/// )
/// // -> False
/// ```
/// 
/// ```gleam
/// date.literal("2024-06-13")
/// |> date.difference(from: date.literal("2024-06-21"))
/// |> period.contains_naive_datetime(
///   naive_datetime.literal("2024-06-21T13:50:00"),
/// )
/// // -> False
/// ```
/// 
/// ```gleam
/// date.as_period(
///   start: date.literal("2024-06-13"),
///   end: date.literal("2024-06-21"),
/// )
/// |> period.contains_naive_datetime(
///   naive_datetime.literal("2024-06-21T13:50:00"),
/// )
/// // -> True
/// ```
pub fn contains_naive_datetime(
  period: tempo.Period,
  naive_datetime: tempo.NaiveDateTime,
) -> Bool {
  tempo.period_contains_naive_datetime(period, naive_datetime)
}

/// Checks if a datetime is contained within a period, inclusive of the
/// start and end datetimes.
/// 
/// ## Examples
/// 
/// ```gleam
/// period.from_month(tempo.Jun, 2024)
/// |> period.contains_datetime(
///   datetime.literal("2024-06-30T24:00:00-07:00"),
/// )
/// // -> True
/// ```
/// 
/// ```gleam
/// datetime.as_period(
///   start: datetime.literal("2024-06-13T15:47:00+06:00"),
///   end: datetime.literal("2024-06-21T07:16:12+06:00"),
/// )
/// |> period.contains_datetime(
///   datetime.literal("2024-06-20T07:16:12+06:00"),
/// )
/// // -> True
/// ```
pub fn contains_datetime(period: tempo.Period, datetime: tempo.DateTime) -> Bool {
  tempo.period_contains_datetime(period, datetime)
}

/// Returns a list over all the dates in the period, inclusive of the 
/// dates of both the start and end datetimes and ignoring the offset.
///
/// ## Examples
/// 
/// ```gleam
/// period.new_naive(
///   start: naive_datetime.literal("2024-06-19T23:59:59-04:00"),
///   end: naive_datetime.literal("2024-06-21T00:16:12+01:00"),
/// )
/// |> period.comprising_dates
/// // -> [
/// //   date.literal("2024-06-19"),
/// //   date.literal("2024-06-20"),
/// //   date.literal("2024-06-21"),
/// // ]
/// ```
/// 
/// ```gleam
/// period.from_month(tempo.Feb, 2024)
/// |> period.comprising_dates
/// // -> [
/// //   date.literal("2024-02-01"),
/// //   ...
/// //   date.literal("2024-02-29"),
/// // ]
pub fn comprising_dates(period: tempo.Period) -> List(tempo.Date) {
  tempo.period_comprising_dates(period)
}

/// Returns list over all the months in the period, inclusive of the
/// months of both the start and end datetimes and ignoring the offset.
///
/// ## Examples
/// 
/// ```gleam
/// period.new(
///   start: datetime.literal("2024-10-25T00:47:00-04:00"),
///   end: datetime.literal("2025-04-30T23:59:59-04:00"),
/// )
/// |> period.comprising_months
/// // -> [
/// //   tempo.MonthYear(tempo.Oct, 2024),
/// //   tempo.MonthYear(tempo.Nov, 2024),
/// //   tempo.MonthYear(tempo.Dec, 2024),
/// //   tempo.MonthYear(tempo.Jan, 2025),
/// //   tempo.MonthYear(tempo.Feb, 2025),
/// //   tempo.MonthYear(tempo.Mar, 2025),
/// //   tempo.MonthYear(tempo.Apr, 2025),
/// // ]
/// ```
pub fn comprising_months(period: tempo.Period) -> List(tempo.MonthYear) {
  tempo.period_comprising_months(period)
}

@internal
pub fn calendar_months_apart(a: tempo.Date, from b: tempo.Date) -> Int {
  case a |> date.is_later(than: b) {
    True -> calendar_months_apart_ordered(a, b)
    False -> -calendar_months_apart_ordered(b, a)
  }
}

fn calendar_months_apart_ordered(
  later: tempo.Date,
  from earlier: tempo.Date,
) -> Int {
  { full_years_apart_ordered(later, earlier) * 12 }
  + month.to_int(later |> tempo.date_get_month)
  - month.to_int(earlier |> tempo.date_get_month)
}

@internal
pub fn full_years_apart(a: tempo.Date, from b: tempo.Date) -> Int {
  case a |> date.is_later(than: b) {
    True -> full_years_apart_ordered(a, b)
    False -> -full_years_apart_ordered(b, a)
  }
}

@internal
pub fn full_years_apart_abs(a: tempo.Date, from b: tempo.Date) -> Int {
  case a |> date.is_later(than: b) {
    True -> full_years_apart_ordered(a, b)
    False -> full_years_apart_ordered(b, a)
  }
}

fn full_years_apart_ordered(later: tempo.Date, earlier: tempo.Date) -> Int {
  tempo.date_get_year(later)
  - tempo.date_get_year(earlier)
  + case
    month.to_int(later |> tempo.date_get_month)
    >= month.to_int(earlier |> tempo.date_get_month)
  {
    True -> 0
    False -> -1
  }
}

@internal
pub fn full_months_apart(a: tempo.Date, from b: tempo.Date) -> Int {
  case a |> date.is_later(than: b) {
    True -> full_months_apart_ordered(a, b)
    False -> -full_months_apart_ordered(b, a)
  }
}

@internal
pub fn full_months_apart_abs(a: tempo.Date, from b: tempo.Date) -> Int {
  case a |> date.is_later(than: b) {
    True -> full_months_apart_ordered(a, b)
    False -> full_months_apart_ordered(b, a)
  }
}

fn full_months_apart_ordered(later: tempo.Date, earlier: tempo.Date) -> Int {
  { full_years_apart_ordered(later, earlier) * 12 }
  + month.to_int(later |> tempo.date_get_month)
  - month.to_int(earlier |> tempo.date_get_month)
  + case tempo.date_get_day(later) >= tempo.date_get_day(earlier) {
    True -> 0
    False -> -1
  }
}
