import gleam/io
import gleam/order
import gleam/string
import gleeunit
import gleeunit/should
import tempo
import tempo/date
import tempo/datetime
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
  |> should.equal(86_400 * 13)
}

pub fn date_leap_second_period_to_seconds_test() {
  date.literal("2016-12-31")
  |> date.difference(from: date.literal("2017-01-01"))
  |> period.as_seconds
  |> should.equal(86_401)
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

pub fn period_as_days_zero_days_test() {
  datetime.literal("2024-06-12T00:00:00Z")
  |> datetime.difference(from: datetime.literal("2024-06-12T00:00:00Z"))
  |> period.as_days
  |> should.equal(0)
}

pub fn period_as_days_one_day_test() {
  datetime.literal("2024-06-12T00:00:00Z")
  |> datetime.difference(from: datetime.literal("2024-06-13T00:00:00Z"))
  |> period.as_days
  |> should.equal(1)
}

pub fn period_as_days_negative_one_day_test() {
  datetime.literal("2024-06-14T00:00:00Z")
  |> datetime.difference(from: datetime.literal("2024-06-13T00:00:00Z"))
  |> period.as_days
  |> should.equal(1)
}

pub fn period_as_days_multiple_days_test() {
  datetime.literal("2024-06-13T00:00:00Z")
  |> datetime.difference(from: datetime.literal("2024-06-26T00:00:00Z"))
  |> period.as_days
  |> should.equal(13)
}

pub fn period_as_days_one_day_month_boundary_test() {
  datetime.literal("2024-07-01T00:00:00Z")
  |> datetime.difference(from: datetime.literal("2024-06-30T00:00:00Z"))
  |> period.as_days
  |> should.equal(1)
}

pub fn period_as_days_multiple_month_test() {
  datetime.literal("2024-03-04T00:00:00Z")
  |> datetime.difference(from: datetime.literal("2024-06-30T00:00:00Z"))
  |> period.as_days
  |> should.equal(118)
}

pub fn period_as_days_multiple_month_leap_year_test() {
  datetime.literal("2024-01-04T00:00:00Z")
  |> datetime.difference(from: datetime.literal("2024-06-30T00:00:00Z"))
  |> period.as_days
  |> should.equal(178)
}

pub fn period_as_days_one_year_test() {
  datetime.literal("2024-06-13T00:00:00Z")
  |> datetime.difference(from: datetime.literal("2025-06-13T00:00:00Z"))
  |> period.as_days
  |> should.equal(365)
}

pub fn period_as_days_more_than_one_year_test() {
  datetime.literal("2024-06-13T00:00:00Z")
  |> datetime.difference(from: datetime.literal("2025-07-01T00:00:00Z"))
  |> period.as_days
  |> should.equal(383)
}

pub fn period_as_days_partial_test() {
  datetime.literal("2024-06-13T00:00:00Z")
  |> datetime.difference(from: datetime.literal("2024-06-13T13:00:00Z"))
  |> period.as_days
  |> should.equal(0)
}

pub fn period_as_days_multiple_partial_test() {
  datetime.literal("2024-06-13T13:00:00Z")
  |> datetime.difference(from: datetime.literal("2024-06-17T23:05:00Z"))
  |> period.as_days
  |> should.equal(4)
}
