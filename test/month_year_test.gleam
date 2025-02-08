import gleam/time/calendar
import gleeunit/should
import tempo
import tempo/month_year

pub fn get_next_test() {
  month_year.next(tempo.MonthYear(calendar.January, 2024))
  |> should.equal(tempo.MonthYear(calendar.February, 2024))

  month_year.next(tempo.MonthYear(calendar.December, 2024))
  |> should.equal(tempo.MonthYear(calendar.January, 2025))
}

pub fn get_prior_test() {
  month_year.prior(tempo.MonthYear(calendar.January, 2024))
  |> should.equal(tempo.MonthYear(calendar.December, 2023))

  month_year.prior(tempo.MonthYear(calendar.February, 2024))
  |> should.equal(tempo.MonthYear(calendar.January, 2024))
}

pub fn month_year_to_int_test() {
  tempo.month_year_to_int(tempo.MonthYear(calendar.January, 2024))
  |> should.equal(202_401)

  tempo.month_year_to_int(tempo.MonthYear(calendar.December, 2023))
  |> should.equal(202_312)
}
