import gleam/bool
import gleam/int
import gleam/list
import tempo
import tempo/duration
import tempo/internal/date
import tempo/month
import tempo/time
import tempo/year

pub fn new(start: tempo.NaiveDateTime, end: tempo.NaiveDateTime) -> tempo.Period {
  tempo.Period(start, end)
}

pub fn difference(
  a: tempo.NaiveDateTime,
  from b: tempo.NaiveDateTime,
) -> tempo.Period {
  new(a, b)
}

// The period API is very similar to the duration API, mostly just with a 
// focus on calendar dates and different adding / subtracting rules.

pub type Unit {
  CalculatedYear(nanoseconds: Int, years: Int)
  CalculatedMonth(nanoseconds: Int, months: Int)
  CalculatedWeek(nanoseconds: Int, weeks: Int)
  CalculatedDay(nanoseconds: Int, days: Int)
  Hour
  Minute
  Second
  Millisecond
  Microsecond
  Nanosecond
}

// pub fn format_as()

pub fn as_seconds(period: tempo.Period) -> Int {
  days_apart(period.start.date, period.end.date)
  |> duration.days
  |> duration.decrease(by: period.start.time |> time.to_duration)
  |> duration.increase(by: period.end.time |> time.to_duration)
  |> duration.increase(
    by: total_leap_seconds(period.start.date, period.end.date)
    |> duration.seconds,
  )
  |> duration.as_seconds
}

@internal
pub fn total_leap_seconds(period_start: tempo.Date, period_end: tempo.Date) -> Int {
  list.range(period_start.year, period_end.year)
  |> list.map(fn(year) {
    list.filter_map(month.months, fn(month) {
      // Leap seconds have only been added to the last day of the month. 
      let last_day_of_month =
        tempo.Date(year, month, month.days(of: month, in: year))

      case
        last_day_of_month
        |> date.is_earlier(than: period_start)
      {
        True -> Error(Nil)
        False ->
          case
            last_day_of_month
            |> date.is_later_or_equal(to: period_end)
          {
            True -> Error(Nil)
            False -> Ok(last_day_of_month)
          }
      }
    })
  })
  |> list.flatten
  |> list.map(fn(date) { month.leap_seconds(of: date.month, in: date.year) })
  |> int.sum
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

// idk if the functions below here will ever see the light of day

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
