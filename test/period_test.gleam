import gleam/iterator
import gleeunit
import gleeunit/should
import tempo
import tempo/date
import tempo/datetime
import tempo/naive_datetime
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
  |> tempo.days_apart(from: date.literal("2024-06-13"))
  |> should.equal(0)
}

pub fn days_apart_one_day_test() {
  date.literal("2024-06-13")
  |> tempo.days_apart(from: date.literal("2024-06-12"))
  |> should.equal(1)
}

pub fn days_apart_one_same_day_test() {
  period.new_naive(
    naive_datetime.literal("2024-06-21T00:00:00"),
    naive_datetime.literal("2024-06-21T24:00:00"),
  )
  |> period.as_days
  |> should.equal(1)
}

pub fn days_apart_multiple_days_test() {
  date.literal("2024-06-24")
  |> tempo.days_apart(from: date.literal("2024-06-12"))
  |> should.equal(12)
}

pub fn days_apart_one_day_month_boundary_test() {
  date.literal("2024-07-01")
  |> tempo.days_apart(from: date.literal("2024-06-30"))
  |> should.equal(1)
}

pub fn days_apart_multiple_month_boundary_test() {
  date.literal("2024-08-04")
  |> tempo.days_apart(from: date.literal("2024-06-30"))
  |> should.equal(35)
}

pub fn days_apart_one_leap_year_test() {
  date.literal("2024-06-12")
  |> tempo.days_apart(from: date.literal("2023-06-12"))
  |> should.equal(366)
}

pub fn days_apart_one_year_test() {
  date.literal("2022-06-12")
  |> tempo.days_apart(from: date.literal("2021-06-12"))
  |> should.equal(365)
}

pub fn days_apart_almost_one_year_test() {
  date.literal("2023-05-28")
  |> tempo.days_apart(from: date.literal("2022-06-12"))
  |> should.equal(350)
}

pub fn days_apart_over_one_year_test() {
  date.literal("2024-06-13")
  |> tempo.days_apart(from: date.literal("2023-06-12"))
  |> should.equal(367)

  date.literal("2024-07-01")
  |> tempo.days_apart(from: date.literal("2023-06-30"))
  |> should.equal(367)

  date.literal("2024-08-01")
  |> tempo.days_apart(from: date.literal("2023-06-30"))
  |> should.equal(398)
}

pub fn days_apart_multiple_years_test() {
  date.literal("2024-06-12")
  |> tempo.days_apart(from: date.literal("2016-06-12"))
  |> should.equal(6 * 365 + 366 * 2)
}

pub fn days_apart_multiple_years_and_some_days_test() {
  date.literal("2024-09-12")
  |> tempo.days_apart(from: date.literal("2016-06-12"))
  |> should.equal(6 * 365 + 366 * 2 + 92)
}

pub fn date_period_to_seconds_test() {
  date.literal("2024-08-03")
  |> date.difference(from: date.literal("2024-08-16"))
  |> period.as_seconds
  |> should.equal(86_400 * 13)
}

pub fn date_difference_one_day_test() {
  date.literal("2024-06-15")
  |> date.difference(from: date.literal("2024-06-14"))
  |> period.as_days
  |> should.equal(1)
}

pub fn date_difference_multiple_days_test() {
  date.literal("2024-06-27")
  |> date.difference(from: date.literal("2024-06-10"))
  |> period.as_days
  |> should.equal(17)
}

pub fn date_difference_one_day_month_boundary_test() {
  date.literal("2024-07-01")
  |> date.difference(from: date.literal("2024-06-30"))
  |> period.as_days
  |> should.equal(1)
}

pub fn date_difference_fractional_neagative_diff_test() {
  period.new_naive(
    start: naive_datetime.literal("2024-06-13T15:47:00"),
    end: naive_datetime.literal("2024-06-21T07:16:12"),
  )
  |> period.as_days_fractional
  |> should.equal(7.645277777777778)
}

pub fn date_difference_fractional_positive_diff_test() {
  period.new_naive(
    start: naive_datetime.literal("2024-06-13T07:47:00"),
    end: naive_datetime.literal("2024-06-21T15:16:12"),
  )
  |> period.as_days_fractional
  |> should.equal(8.311944444444444)
}

pub fn date_difference_fractional_one_day_diff_test() {
  period.new_naive(
    start: naive_datetime.literal("2024-06-20T15:16:12"),
    end: naive_datetime.literal("2024-06-21T15:16:12"),
  )
  |> period.as_days_fractional
  |> should.equal(1.0)
}

pub fn datetime_period_to_seconds_adding_test() {
  naive_datetime.literal("2024-08-03T11:30:00")
  |> naive_datetime.as_period(end: naive_datetime.literal("2024-08-16T11:30:02"))
  |> period.as_seconds
  |> should.equal({ 86_400 * 13 } + 2)
}

pub fn datetime_period_to_seconds_subtracting_test() {
  naive_datetime.literal("2024-08-03T11:30:00")
  |> naive_datetime.as_period(end: naive_datetime.literal("2024-08-16T11:29:58"))
  |> period.as_seconds
  |> should.equal({ 86_400 * 13 } - 2)
}

pub fn period_datetime_as_days_zero_days_test() {
  datetime.literal("2024-06-12T00:00:00Z")
  |> datetime.as_period(start: datetime.literal("2024-06-12T00:00:00Z"))
  |> period.as_days
  |> should.equal(0)
}

pub fn period_datetime_as_days_one_day_test() {
  datetime.literal("2024-06-12T00:00:00Z")
  |> datetime.as_period(start: datetime.literal("2024-06-13T00:00:00Z"))
  |> period.as_days
  |> should.equal(1)
}

pub fn period_datetime_as_days_negative_one_day_test() {
  datetime.literal("2024-06-14T00:00:00Z")
  |> datetime.as_period(start: datetime.literal("2024-06-13T00:00:00Z"))
  |> period.as_days
  |> should.equal(1)
}

pub fn period_as_days_multiple_days_test() {
  datetime.literal("2024-06-13T00:00:00Z")
  |> datetime.as_period(start: datetime.literal("2024-06-26T00:00:00Z"))
  |> period.as_days
  |> should.equal(13)
}

pub fn period_as_days_one_day_month_boundary_test() {
  datetime.literal("2024-07-01T00:00:00Z")
  |> datetime.as_period(start: datetime.literal("2024-06-30T00:00:00Z"))
  |> period.as_days
  |> should.equal(1)
}

pub fn period_as_days_multiple_month_test() {
  datetime.literal("2024-03-04T00:00:00Z")
  |> datetime.as_period(start: datetime.literal("2024-06-30T00:00:00Z"))
  |> period.as_days
  |> should.equal(118)
}

pub fn period_as_days_multiple_month_leap_year_test() {
  datetime.literal("2024-01-04T00:00:00Z")
  |> datetime.as_period(start: datetime.literal("2024-06-30T00:00:00Z"))
  |> period.as_days
  |> should.equal(178)
}

pub fn period_as_days_one_year_test() {
  datetime.literal("2024-06-13T00:00:00Z")
  |> datetime.as_period(start: datetime.literal("2025-06-13T00:00:00Z"))
  |> period.as_days
  |> should.equal(365)
}

pub fn period_as_days_more_than_one_year_test() {
  datetime.literal("2024-06-13T00:00:00Z")
  |> datetime.as_period(start: datetime.literal("2025-07-01T00:00:00Z"))
  |> period.as_days
  |> should.equal(383)
}

pub fn period_as_days_partial_test() {
  datetime.literal("2024-06-13T00:00:00Z")
  |> datetime.as_period(start: datetime.literal("2024-06-13T13:00:00Z"))
  |> period.as_days
  |> should.equal(0)
}

pub fn period_as_days_multiple_partial_test() {
  datetime.literal("2024-06-13T13:00:00Z")
  |> datetime.as_period(start: datetime.literal("2024-06-17T23:05:00Z"))
  |> period.as_days
  |> should.equal(4)
}

pub fn period_from_month_june_test() {
  period.from_month(tempo.Jun, 2024)
  |> period.as_days
  |> should.equal(30)
}

pub fn period_from_month_feb_leap_test() {
  period.from_month(tempo.Feb, 2024)
  |> period.as_days
  |> should.equal(29)
}

pub fn period_from_month_june_fractional_test() {
  period.from_month(tempo.Jun, 2024)
  |> period.as_days_fractional
  |> should.equal(30.0)
}

pub fn month_period_contains_date_test() {
  period.from_month(tempo.Jun, 2024)
  |> period.contains_date(date.literal("2024-06-21"))
  |> should.be_true
}

pub fn month_period_contains_date_inclusive_test() {
  period.from_month(tempo.Jun, 2024)
  |> period.contains_date(date.literal("2024-06-30"))
  |> should.be_true

  period.from_month(tempo.Jun, 2024)
  |> period.contains_date(date.literal("2024-06-01"))
  |> should.be_true
}

pub fn month_period_contains_datetime_inclusive_test() {
  period.from_month(tempo.Jun, 2024)
  |> period.contains_datetime(datetime.literal("2024-06-30T24:00:00-07:00"))
  |> should.be_true

  period.from_month(tempo.Jun, 2024)
  |> period.contains_datetime(datetime.literal("2024-06-01T00:00:00+07:00"))
  |> should.be_true
}

pub fn month_period_contains_invalid_date_test() {
  period.from_month(tempo.Jun, 2024)
  |> period.contains_date(date.literal("2024-07-22"))
  |> should.be_false
}

pub fn month_period_contains_datetime_utc_test() {
  period.from_month(tempo.Jun, 2024)
  |> period.contains_datetime(datetime.literal("2024-06-30T24:00:00Z"))
  |> should.be_true
}

pub fn month_period_contains_datetime_offset_test() {
  period.from_month(tempo.Jun, 2024)
  |> period.contains_datetime(datetime.literal("2024-06-30T24:00:00-07:00"))
  |> should.be_true
}

pub fn month_period_contains_invalid_datetime_test() {
  period.from_month(tempo.Jun, 2024)
  |> period.contains_datetime(datetime.literal("2024-07-22T24:00:00Z"))
  |> should.be_false
}

pub fn month_period_contains_naive_datetime_test() {
  period.from_month(tempo.Jun, 2024)
  |> period.contains_naive_datetime(naive_datetime.literal(
    "2024-06-30T24:00:00",
  ))
  |> should.be_true
}

pub fn month_period_contains_invalid_naive_datetime_test() {
  period.from_month(tempo.Jun, 2024)
  |> period.contains_naive_datetime(naive_datetime.literal(
    "2024-09-22T24:00:00",
  ))
  |> should.be_false
}

pub fn month_period_contains_date_different_year_test() {
  period.from_month(tempo.Jun, 2024)
  |> period.contains_date(date.literal("2022-06-21"))
  |> should.be_false
}

pub fn diff_period_contains_date_test() {
  date.literal("2024-06-13")
  |> date.difference(from: date.literal("2024-06-21"))
  |> period.contains_date(date.literal("2024-06-21"))
  |> should.be_true
}

pub fn diff_period_contains_out_of_bounds_date_test() {
  date.literal("2024-06-13")
  |> date.difference(from: date.literal("2024-06-21"))
  |> period.contains_date(date.literal("2022-06-21"))
  |> should.be_false
}

pub fn diff_period_contains_naive_datetime_test() {
  date.literal("2024-06-13")
  |> date.difference(from: date.literal("2024-06-21"))
  |> period.contains_naive_datetime(naive_datetime.literal(
    "2024-06-13T15:50:00",
  ))
  |> should.be_true
}

pub fn diff_period_contains_out_of_bounds_naive_datetime_test() {
  date.literal("2024-06-13")
  |> date.difference(from: date.literal("2024-06-21"))
  |> period.contains_naive_datetime(naive_datetime.literal(
    "2024-06-21T13:50:00",
  ))
  |> should.be_false

  naive_datetime.literal("2024-06-13T13:50:00")
  |> naive_datetime.as_period(end: naive_datetime.literal("2024-06-21T14:50:00"))
  |> period.contains_naive_datetime(naive_datetime.literal(
    "2024-06-21T15:50:00",
  ))
  |> should.be_false
}

pub fn diff_period_contains_datetime_test() {
  date.literal("2024-06-13")
  |> date.difference(from: date.literal("2024-06-21"))
  |> period.contains_datetime(datetime.literal("2024-06-13T15:50:00Z"))
  |> should.be_true
}

pub fn diff_period_contains_out_of_bounds_datetime_test() {
  datetime.literal("2024-06-20T13:50:00Z")
  |> datetime.as_period(start: datetime.literal("2024-06-21T13:50:00Z"))
  |> period.contains_datetime(datetime.literal("2024-06-21T13:50:00-04:00"))
  |> should.be_false

  datetime.literal("2024-06-13T13:50:00Z")
  |> datetime.as_period(start: datetime.literal("2024-06-21T14:50:00Z"))
  |> period.contains_datetime(datetime.literal("2022-06-21T05:50:00-04:00"))
  |> should.be_false
}

pub fn datetime_period_contains_date_test() {
  datetime.as_period(
    start: datetime.literal("2024-06-13T15:47:00+06:00"),
    end: datetime.literal("2024-06-21T07:16:12+06:00"),
  )
  |> period.contains_datetime(datetime.literal("2024-06-20T07:16:12+06:00"))
  |> should.be_true
}

pub fn datetime_period_contains_date_inclusive_test() {
  datetime.as_period(
    start: datetime.literal("2024-06-13T15:47:00+06:00"),
    end: datetime.literal("2024-06-21T07:16:12+06:00"),
  )
  |> period.contains_datetime(datetime.literal("2024-06-21T07:16:12+06:00"))
  |> should.be_true
}

pub fn date_as_period_inclusive_test() {
  date.as_period(
    start: date.literal("2024-06-13"),
    end: date.literal("2024-06-21"),
  )
  |> period.contains_naive_datetime(naive_datetime.literal(
    "2024-06-21T13:50:00",
  ))
  |> should.be_true
}

pub fn comprising_dates_test() {
  period.new(
    start: datetime.literal("2024-06-19T23:59:59-04:00"),
    end: datetime.literal("2024-06-21T00:16:12+01:00"),
  )
  |> period.comprising_dates
  |> iterator.to_list
  |> should.equal([
    date.literal("2024-06-19"),
    date.literal("2024-06-20"),
    date.literal("2024-06-21"),
  ])
}

pub fn comprising_dates_one_day_test() {
  period.new(
    start: datetime.literal("2024-06-21T00:59:59Z"),
    end: datetime.literal("2024-06-21T02:16:12Z"),
  )
  |> period.comprising_dates
  |> iterator.to_list
  |> should.equal([date.literal("2024-06-21")])
}

pub fn comprising_dates_month_boundary_test() {
  period.new_naive(
    start: naive_datetime.literal("2024-06-21T15:47:00"),
    end: naive_datetime.literal("2024-07-04T07:16:12"),
  )
  |> period.comprising_dates
  |> iterator.to_list
  |> should.equal([
    date.literal("2024-06-21"),
    date.literal("2024-06-22"),
    date.literal("2024-06-23"),
    date.literal("2024-06-24"),
    date.literal("2024-06-25"),
    date.literal("2024-06-26"),
    date.literal("2024-06-27"),
    date.literal("2024-06-28"),
    date.literal("2024-06-29"),
    date.literal("2024-06-30"),
    date.literal("2024-07-01"),
    date.literal("2024-07-02"),
    date.literal("2024-07-03"),
    date.literal("2024-07-04"),
  ])
}

pub fn comprising_dates_year_boundary_test() {
  period.new_naive(
    start: naive_datetime.literal("2024-12-25T00:47:00"),
    end: naive_datetime.literal("2025-01-04T07:16:12"),
  )
  |> period.comprising_dates
  |> iterator.to_list
  |> should.equal([
    date.literal("2024-12-25"),
    date.literal("2024-12-26"),
    date.literal("2024-12-27"),
    date.literal("2024-12-28"),
    date.literal("2024-12-29"),
    date.literal("2024-12-30"),
    date.literal("2024-12-31"),
    date.literal("2025-01-01"),
    date.literal("2025-01-02"),
    date.literal("2025-01-03"),
    date.literal("2025-01-04"),
  ])
}

pub fn comprising_months_one_month_test() {
  period.new(
    start: datetime.literal("2024-06-19T23:59:59-04:00"),
    end: datetime.literal("2024-06-21T00:16:12+01:00"),
  )
  |> period.comprising_months
  |> iterator.to_list
  |> should.equal([tempo.MonthYear(tempo.Jun, 2024)])
}

pub fn comprising_months_multiple_months_test() {
  period.new(
    start: datetime.literal("2024-06-19T23:59:59-04:00"),
    end: datetime.literal("2024-09-21T00:16:12+01:00"),
  )
  |> period.comprising_months
  |> iterator.to_list
  |> should.equal([
    tempo.MonthYear(tempo.Jun, 2024),
    tempo.MonthYear(tempo.Jul, 2024),
    tempo.MonthYear(tempo.Aug, 2024),
    tempo.MonthYear(tempo.Sep, 2024),
  ])
}

pub fn comprising_months_year_boundary_test() {
  period.new(
    start: datetime.literal("2024-10-25T00:47:00-04:00"),
    end: datetime.literal("2025-04-30T23:59:59-04:00"),
  )
  |> period.comprising_months
  |> iterator.to_list
  |> should.equal([
    tempo.MonthYear(tempo.Oct, 2024),
    tempo.MonthYear(tempo.Nov, 2024),
    tempo.MonthYear(tempo.Dec, 2024),
    tempo.MonthYear(tempo.Jan, 2025),
    tempo.MonthYear(tempo.Feb, 2025),
    tempo.MonthYear(tempo.Mar, 2025),
    tempo.MonthYear(tempo.Apr, 2025),
  ])
}
