import gleam/order
import gleam/string
import gleam/io
import gleeunit
import gleeunit/should
import tempo
import tempo/date
import tempo/duration
import tempo/period

pub fn main() {
  gleeunit.main()
}

pub fn full_years_apart_same_year_test() {
  date.literal("2024-08-13")
  |> period.full_years_apart(from: date.literal("2024-06-12"))
  |> should.equal(0)
}

pub fn full_years_apart_less_than_different_year_test() {
  date.literal("2025-03-13")
  |> period.full_years_apart(from: date.literal("2024-06-12"))
  |> should.equal(0)
}

pub fn full_years_apart_positive_year_test() {
  date.literal("2024-06-12")
  |> period.full_years_apart(from: date.literal("2023-06-12"))
  |> should.equal(1)
}

pub fn full_years_apart_negative_year_test() {
  date.literal("2023-06-12")
  |> period.full_years_apart(from: date.literal("2024-06-12"))
  |> should.equal(-1)
}

pub fn full_years_apart_positive_years_test() {
  date.literal("2033-06-12")
  |> period.full_years_apart(from: date.literal("2024-06-12"))
  |> should.equal(9)
}

pub fn full_years_apart_negative_years_test() {
  date.literal("2024-06-12")
  |> period.full_years_apart(from: date.literal("2033-06-12"))
  |> should.equal(-9)
}

pub fn full_months_apart_same_month_test() {
  date.literal("2024-06-13")
  |> period.full_months_apart(from: date.literal("2024-06-12"))
  |> should.equal(0)
}

pub fn full_months_apart_less_than_different_month_test() {
  date.literal("2024-07-13")
  |> period.full_months_apart(from: date.literal("2024-06-22"))
  |> should.equal(0)
}

pub fn full_months_apart_positive_month_test() {
  date.literal("2024-07-13")
  |> period.full_months_apart(from: date.literal("2024-06-12"))
  |> should.equal(1)
}

pub fn full_months_apart_negative_month_test() {
  date.literal("2024-06-05")
  |> period.full_months_apart(from: date.literal("2024-07-12"))
  |> should.equal(-1)
}

pub fn full_months_apart_positive_months_test() {
  date.literal("2024-06-12")
  |> period.full_months_apart(from: date.literal("2024-03-12"))
  |> should.equal(3)
}

pub fn full_months_apart_negative_months_test() {
  date.literal("2024-03-12")
  |> period.full_months_apart(from: date.literal("2024-12-12"))
  |> should.equal(-9)
}

pub fn calendar_months_apart_same_month_test() {
  date.literal("2024-06-13")
  |> period.calendar_months_apart(from: date.literal("2024-06-12"))
  |> should.equal(0)
}

pub fn calendar_months_apart_positive_month_test() {
  date.literal("2024-07-13")
  |> period.calendar_months_apart(from: date.literal("2024-06-12"))
  |> should.equal(1)
}

pub fn calendar_months_apart_negative_month_test() {
  date.literal("2024-06-05")
  |> period.calendar_months_apart(from: date.literal("2024-07-12"))
  |> should.equal(-1)
}

pub fn calendar_months_apart_positive_months_test() {
  date.literal("2024-06-10")
  |> period.calendar_months_apart(from: date.literal("2024-03-12"))
  |> should.equal(3)
}

pub fn calendar_months_apart_negative_months_test() {
  date.literal("2024-03-12")
  |> period.calendar_months_apart(from: date.literal("2024-12-09"))
  |> should.equal(-9)
}

pub fn days_apart_zero_test() {
  date.literal("2024-06-13")
  |> period.days_apart(from: date.literal("2024-06-13"))
  |> should.equal(0)
}

pub fn days_apart_one_day_test() {
  date.literal("2024-06-13")
  |> period.days_apart(from: date.literal("2024-06-12"))
  |> should.equal(1)
}

pub fn days_apart_multiple_days_test() {
  date.literal("2024-06-24")
  |> period.days_apart(from: date.literal("2024-06-12"))
  |> should.equal(12)
}

pub fn days_apart_one_day_month_boundary_test() {
  date.literal("2024-07-01")
  |> period.days_apart(from: date.literal("2024-06-30"))
  |> should.equal(1)
}

pub fn days_apart_multiple_month_boundary_test() {
  date.literal("2024-08-04")
  |> period.days_apart(from: date.literal("2024-06-30"))
  |> should.equal(35)
}

pub fn days_apart_one_leap_year_test() {
  date.literal("2024-06-12")
  |> period.days_apart(from: date.literal("2023-06-12"))
  |> should.equal(366)
}

pub fn days_apart_one_year_test() {
  date.literal("2022-06-12")
  |> period.days_apart(from: date.literal("2021-06-12"))
  |> should.equal(365)
}

pub fn days_apart_almost_one_year_test() {
  date.literal("2023-05-28")
  |> period.days_apart(from: date.literal("2022-06-12"))
  |> should.equal(350)
}

pub fn days_apart_over_one_year_test() {
  date.literal("2024-06-13")
  |> period.days_apart(from: date.literal("2023-06-12"))
  |> should.equal(367)

  date.literal("2024-07-01")
  |> period.days_apart(from: date.literal("2023-06-30"))
  |> should.equal(367)

  date.literal("2024-08-01")
  |> period.days_apart(from: date.literal("2023-06-30"))
  |> should.equal(398)
}

pub fn days_apart_multiple_years_test() {
  date.literal("2024-06-12")
  |> period.days_apart(from: date.literal("2016-06-12"))
  |> should.equal(6 * 365 + 366 * 2)
}

pub fn days_apart_multiple_years_and_some_days_test() {
  date.literal("2024-09-12")
  |> period.days_apart(from: date.literal("2016-06-12"))
  |> should.equal(6 * 365 + 366 * 2 + 92)
}

pub fn date_period_to_seconds_test() {
  date.literal("2024-08-03")
  |> date.difference(from: date.literal("2024-08-16"))
  |> period.as_seconds
  |> should.equal(86400 * 13)
}

pub fn date_leap_second_period_to_seconds_test() {
  date.literal("2016-12-31")
  |> date.difference(from: date.literal("2017-01-01"))
  |> period.as_seconds
  |> should.equal(86401)
}

// pub fn date_difference_one_day_test() {
//   date.literal("2024-06-15")
//   |> date.difference(from: date.literal("2024-06-14"))
//   |> duration.as_days
//   |> should.equal(1)
// }

// pub fn date_difference_multiple_days_test() {
//   date.literal("2024-06-27")
//   |> date.difference(from: date.literal("2024-06-10"))
//   |> duration.as_days
//   |> should.equal(17)
// }

// pub fn date_difference_one_day_month_boundary_test() {
//   date.literal("2024-07-01")
//   |> date.difference(from: date.literal("2024-06-30"))
//   |> duration.as_days
//   |> should.equal(1)
// }

// pub fn date_difference_one_year_test() {
//   date.literal("2024-06-14")
//   |> date.difference(from: date.literal("2023-06-14"))
//   |> duration.as_years
//   |> should.equal(1)
// }

pub fn period_total_leap_seconds_test() {
  date.literal("2015-06-12")
  |> period.total_leap_seconds(date.literal("2023-10-12"))
  |> should.equal(2)

  date.literal("1970-06-12")
  |> period.total_leap_seconds(date.literal("2023-10-12"))
  |> should.equal(27)
}