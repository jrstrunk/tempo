import gleam/bool
import gleam/int
import gleam/list
import gtempo/internal as unit
import tempo
import tempo/date
import tempo/datetime
import tempo/duration
import tempo/month
import tempo/naive_datetime
import tempo/time
import tempo/year

/// Creates a new period from the start and end datetimes.
/// 
/// ## Examples
/// 
/// ```gleam
/// period.new(
///   start: datetime.literal("2024-06-13T15:47:00+06:00"),
///   end: datetime.literal("2024-06-21T07:16:12+06:00"),
/// )
/// |> period.as_days
/// // -> 7
/// ```
pub fn new(start start: tempo.DateTime, end end: tempo.DateTime) -> tempo.Period {
  tempo.Period(start: start, end: end)
}

/// Creates a new period from the start and end naive datetimes.
/// 
/// ## Examples
/// 
/// ```gleam
/// period.new_naive(
///   start: naive_datetime.literal("2024-06-13T15:47:00"),
///   end: naive_datetime.literal("2024-06-21T07:16:12"),
/// )
/// |> period.as_days
/// // -> 7
/// ```
pub fn new_naive(
  start start: tempo.NaiveDateTime,
  end end: tempo.NaiveDateTime,
) -> tempo.Period {
  tempo.NaivePeriod(start: start, end: end)
}

// The period API is very similar to the duration API, mostly just with a 
// focus on calendar dates and different adding / subtracting rules.

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
  Nanosecond
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
  let #(start_date, end_date, start_time, end_time) =
    get_start_and_end_date_and_time(period)

  days_apart(start_date, end_date)
  |> duration.days
  |> duration.decrease(by: start_time |> time.to_duration)
  |> duration.increase(by: end_time |> time.to_duration)
  |> duration.as_seconds
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
    get_start_and_end_date_and_time(period)

  days_apart(start_date, end_date)
  // If a full day has not elapsed since the start time (based on the time), 
  // then 1 needs to be taken off the days count.
  + case start_time |> time.is_later(than: end_time) {
    True -> -1
    False -> 0
  }
  // If a full day is in the period as designated by the end time being
  // the last moment of the day and the start time being the first second
  // of the day, then 1 needs to be atted to the days count.
  + case
    start_time |> time.is_equal(to: tempo.Time(0, 0, 0, 0))
    && end_time
    |> time.is_equal(to: tempo.Time(24, 0, 0, 0))
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
  let #(_, _, start_time, end_time) = get_start_and_end_date_and_time(period)

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
        |> duration.as_nanoseconds,
      )
      /. int.to_float(unit.imprecise_day_nanoseconds)
      +. int.to_float(
        end_time
        |> time.to_duration
        |> duration.as_nanoseconds,
      )
      /. int.to_float(unit.imprecise_day_nanoseconds)

    // The time between the start and end times divided by the total number 
    // of seconds in the end day.
    False ->
      // The as_days functions alread accounted for the time between the
      // start and end dates when the end is at the last moment of the day,
      // so we do not need to account for it here as well.
      case time.is_equal(end_time, to: tempo.Time(24, 0, 0, 0)) {
        True -> 0.0
        False ->
          int.to_float(
            time.difference(end_time, start_time)
            |> duration.as_nanoseconds,
          )
          /. int.to_float(unit.imprecise_day_nanoseconds)
      }
  }
}

fn get_start_and_end_date_and_time(
  period,
) -> #(tempo.Date, tempo.Date, tempo.Time, tempo.Time) {
  case period {
    tempo.NaivePeriod(start, end) -> #(
      start.date,
      end.date,
      start.time,
      end.time,
    )
    tempo.Period(start, end) -> #(
      start.naive.date,
      end.naive.date,
      start.naive.time,
      end.naive.time,
    )
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
pub fn as_duration(period: tempo.Period) -> tempo.Duration {
  period |> as_seconds |> duration.seconds
}

/// Creates a period of the specified month, starting at 00:00:00 on the
/// first day of the month and ending at 24:00:00 on the last day of the month.
/// 
/// 
/// ## Examples
/// 
/// ```gleam
/// period.from_month(tempo.Feb, 2024)
/// |> period.contains_date(date.literal("2024-06-21"))
/// // -> False
/// ```
pub fn from_month(month: tempo.Month, year: Int) -> tempo.Period {
  let start =
    tempo.NaiveDateTime(tempo.Date(year, month, 1), tempo.Time(0, 0, 0, 0))

  let end =
    tempo.NaiveDateTime(
      tempo.Date(year, month, month.days(of: month, in: year)),
      tempo.Time(24, 0, 0, 0),
    )

  new_naive(start, end)
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
  let #(start_date, end_date, _, _) = get_start_and_end_date_and_time(period)

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
  let #(start_date, end_date, start_time, end_time) =
    get_start_and_end_date_and_time(period)

  naive_datetime
  |> naive_datetime.is_later_or_equal(tempo.NaiveDateTime(
    start_date,
    start_time,
  ))
  && naive_datetime
  |> naive_datetime.is_earlier_or_equal(tempo.NaiveDateTime(end_date, end_time))
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
  case period {
    tempo.Period(start, end) ->
      datetime
      |> datetime.is_later_or_equal(to: start)
      && datetime
      |> datetime.is_earlier_or_equal(to: end)

    _ -> contains_naive_datetime(period, datetime.naive)
  }
}

@internal
pub fn days_apart(from start_date: tempo.Date, to end_date: tempo.Date) {
  // Caclulate the number of days in the years that are between (exclusive)
  // the start and end dates.
  let days_in_the_years_between = case
    calendar_years_apart(end_date, start_date)
  {
    years_apart if years_apart >= 2 ->
      list.range(1, years_apart - 1)
      |> list.map(fn(i) { end_date.year + i |> year.days })
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
    end_date.year == start_date.year
    && { end_date.month |> month.to_int <= start_date.month |> month.to_int }
  {
    True -> end_date.day - start_date.day
    False ->
      end_date.day
      + { month.days(start_date.month, start_date.year) - start_date.day }
  }

  // Now add the days from each section back up together.
  days_in_the_years_between + days_in_the_months_between + days_apart
}

fn exclusive_months_between_days(from: tempo.Date, to: tempo.Date) {
  use <- bool.guard(
    when: to.year == from.year
      && {
      to.month |> month.prior |> month.to_int
      < from.month |> month.next |> month.to_int
    },
    return: 0,
  )

  case to.year == from.year {
    True ->
      list.range(
        month.to_int(from.month |> month.next),
        month.to_int(to.month |> month.prior),
      )
      |> list.map(fn(m) {
        let assert Ok(m) = month.from_int(m)
        m
      })
    False -> {
      case to.month == tempo.Jan {
        True -> []
        False -> list.range(1, month.to_int(to.month |> month.prior))
      }
      |> list.map(fn(m) {
        let assert Ok(m) = month.from_int(m)
        m
      })
      |> list.append(
        case from.month == tempo.Dec {
          True -> []
          False -> list.range(month.to_int(from.month |> month.next), 12)
        }
        |> list.map(fn(m) {
          let assert Ok(m) = month.from_int(m)
          m
        }),
      )
    }
  }
  |> list.map(fn(m) { month.days(of: m, in: to.year) })
  |> int.sum
}

fn calendar_years_apart(later: tempo.Date, from earlier: tempo.Date) -> Int {
  later.year - earlier.year
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
  + month.to_int(later.month)
  - month.to_int(earlier.month)
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
  later.year
  - earlier.year
  + case month.to_int(later.month) >= month.to_int(earlier.month) {
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
  + month.to_int(later.month)
  - month.to_int(earlier.month)
  + case later.day >= earlier.day {
    True -> 0
    False -> -1
  }
}
