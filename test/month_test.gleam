import gleam/time/calendar
import gleeunit/should
import tempo
import tempo/month

pub fn from_string_test() {
  month.from_string("Jan")
  |> should.equal(Ok(calendar.January))

  month.from_string("January")
  |> should.equal(Ok(calendar.January))

  month.from_string("Feby")
  |> should.be_error
}

pub fn month_year_to_int_test() {
  tempo.month_year_to_int(tempo.MonthYear(calendar.January, 2024))
  |> should.equal(202_401)

  tempo.month_year_to_int(tempo.MonthYear(calendar.December, 2024))
  |> should.equal(202_412)
}

pub fn month_year_prior_test() {
  tempo.month_year_prior(tempo.MonthYear(calendar.January, 2024))
  |> tempo.month_year_to_int
  |> should.equal(202_312)

  tempo.month_year_prior(tempo.MonthYear(calendar.December, 2024))
  |> tempo.month_year_to_int
  |> should.equal(202_411)
}

pub fn month_year_next_test() {
  tempo.month_year_next(tempo.MonthYear(calendar.January, 2024))
  |> tempo.month_year_to_int
  |> should.equal(202_402)

  tempo.month_year_next(tempo.MonthYear(calendar.December, 2024))
  |> tempo.month_year_to_int
  |> should.equal(202_501)
}
