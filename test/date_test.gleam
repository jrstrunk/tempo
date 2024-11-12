import gleam/dynamic
import gleam/order
import gleam/string
import gleeunit/should
import tempo/date

pub fn date_current_test() {
  date.current_utc()
  |> date.to_string
  |> string.length
  |> should.equal(10)

  date.current_local()
  |> date.to_string
  |> string.length
  |> should.equal(10)
}

pub fn new_date_test() {
  date.new(2024, 6, 13)
  |> should.be_ok
  |> should.equal(date.literal("2024-06-13"))

  date.new(2013, 13, 16)
  |> should.be_error
}

pub fn from_string_date_dot_delim_test() {
  date.from_string("2024.06.13")
  |> should.be_ok
  |> should.equal(date.literal("2024-06-13"))

  date.from_string("2024.2.29")
  |> should.be_ok
  |> should.equal(date.literal("2024-02-29"))
}

pub fn from_string_date_slash_delim_test() {
  date.from_string("2024/06/13")
  |> should.be_ok
  |> should.equal(date.literal("2024-06-13"))

  date.from_string("2024/6/7")
  |> should.be_ok
  |> should.equal(date.literal("2024-06-07"))
}

pub fn from_string_date_underscore_delim_test() {
  date.from_string("2024_06_13")
  |> should.be_ok
  |> should.equal(date.literal("2024-06-13"))

  date.from_string("2016_2_29")
  |> should.be_ok
  |> should.equal(date.literal("2016-02-29"))
}

pub fn from_string_date_dash_delim_test() {
  date.from_string("2024-11-13")
  |> should.be_ok
  |> should.equal(date.literal("2024-11-13"))

  date.from_string("2024-6-3")
  |> should.be_ok
  |> should.equal(date.literal("2024-06-03"))
}

pub fn from_string_date_space_delim_test() {
  date.from_string("2024 06 13")
  |> should.be_ok
  |> should.equal(date.literal("2024-06-13"))

  date.from_string("2024 5 6")
  |> should.be_ok
  |> should.equal(date.literal("2024-05-06"))
}

pub fn from_string_date_no_delim_test() {
  date.from_string("20240613")
  |> should.be_ok
  |> should.equal(date.literal("2024-06-13"))
}

pub fn from_string_bad_date_test() {
  date.from_string("2024-06-13a")
  |> should.be_error

  date.from_string("2046")
  |> should.be_error

  date.from_string("20242077")
  |> should.be_error

  date.from_string("20-06-13")
  |> should.be_error

  date.from_string("2024/15/13")
  |> should.be_error

  date.from_string("2024.01.33")
  |> should.be_error

  date.from_string("20242_02_15")
  |> should.be_error

  date.from_string("2024t01t13")
  |> should.be_error
}

pub fn to_string_test() {
  date.literal("2024-10-13")
  |> date.to_string
  |> should.equal("2024-10-13")

  date.literal("2024-06-03")
  |> date.to_string
  |> should.equal("2024-06-03")
}

pub fn format_test() {
  date.literal("2024-06-13")
  |> date.format("MMMM 'YY")
  |> should.equal("June '24")
}

pub fn to_tuple_test() {
  date.literal("2024-06-13")
  |> date.to_tuple
  |> should.equal(#(2024, 6, 13))

  date.literal("2016-02-29")
  |> date.to_tuple
  |> should.equal(#(2016, 2, 29))
}

pub fn compare_eq_date_test() {
  date.literal("2024-06-13")
  |> date.compare(date.literal("2024-06-13"))
  |> should.equal(order.Eq)
}

pub fn compare_lt_date_test() {
  date.literal("2024-06-13")
  |> date.compare(date.literal("2024-06-14"))
  |> should.equal(order.Lt)
}

pub fn compare_gt_date_test() {
  date.literal("2024-06-13")
  |> date.compare(date.literal("2024-06-12"))
  |> should.equal(order.Gt)
}

pub fn compare_eq_month_test() {
  date.literal("2024-05-10")
  |> date.compare(date.literal("2024-05-10"))
  |> should.equal(order.Eq)
}

pub fn compare_lt_month_test() {
  date.literal("2024-05-10")
  |> date.compare(date.literal("2024-05-11"))
  |> should.equal(order.Lt)
}

pub fn compare_gt_month_test() {
  date.literal("2024-05-10")
  |> date.compare(date.literal("2024-05-09"))
  |> should.equal(order.Gt)
}

pub fn compare_eq_year_test() {
  date.literal("2021-12-31")
  |> date.compare(date.literal("2021-12-31"))
  |> should.equal(order.Eq)
}

pub fn compare_lt_year_test() {
  date.literal("2021-12-31")
  |> date.compare(date.literal("2022-12-31"))
  |> should.equal(order.Lt)
}

pub fn compare_gt_year_test() {
  date.literal("2021-12-31")
  |> date.compare(date.literal("2020-12-31"))
  |> should.equal(order.Gt)
}

pub fn is_earlier_test() {
  date.literal("2024-06-13")
  |> date.is_earlier(than: date.literal("2024-06-14"))
  |> should.be_true()

  date.literal("2024-06-13")
  |> date.is_earlier(than: date.literal("2024-06-12"))
  |> should.be_false()
}

pub fn is_earlier_or_equal_test() {
  date.literal("2024-06-13")
  |> date.is_earlier_or_equal(to: date.literal("2024-06-14"))
  |> should.be_true()

  date.literal("2024-06-14")
  |> date.is_earlier_or_equal(to: date.literal("2024-06-14"))
  |> should.be_true()

  date.literal("2024-06-15")
  |> date.is_earlier_or_equal(to: date.literal("2024-06-14"))
  |> should.be_false()

  date.literal("2024-06-15")
  |> date.is_earlier_or_equal(to: date.literal("2024-06-14"))
  |> should.be_false()
}

pub fn is_equal_test() {
  date.literal("2024-06-13")
  |> date.is_equal(to: date.literal("2024-06-13"))
  |> should.be_true()

  date.literal("2024-06-13")
  |> date.is_equal(to: date.literal("2024-06-14"))
  |> should.be_false()
}

pub fn is_later_test() {
  date.literal("2024-06-14")
  |> date.is_later(than: date.literal("2024-06-13"))
  |> should.be_true()

  date.literal("2024-06-12")
  |> date.is_later(than: date.literal("2024-06-13"))
  |> should.be_false()
}

pub fn is_later_or_equal_test() {
  date.literal("2024-06-14")
  |> date.is_later_or_equal(to: date.literal("2024-06-13"))
  |> should.be_true()

  date.literal("2024-06-13")
  |> date.is_later_or_equal(to: date.literal("2024-06-13"))
  |> should.be_true()

  date.literal("2024-06-12")
  |> date.is_later_or_equal(to: date.literal("2024-06-13"))
  |> should.be_false()

  date.literal("2024-06-12")
  |> date.is_later_or_equal(to: date.literal("2024-06-13"))
  |> should.be_false()
}

pub fn date_to_unix_test() {
  date.literal("1970-01-01")
  |> date.to_unix_utc
  |> should.equal(0)

  date.literal("1970-01-14")
  |> date.to_unix_utc
  |> should.equal(1_123_200)

  date.literal("1970-03-14")
  |> date.to_unix_utc
  |> should.equal(6_220_800)

  date.literal("1970-04-11")
  |> date.to_unix_utc
  |> should.equal(8_640_000)

  date.literal("1970-04-20")
  |> date.to_unix_utc
  |> should.equal(9_417_600)

  date.literal("1970-04-16")
  |> date.to_unix_utc
  |> should.equal(9_072_000)

  date.literal("1970-04-14")
  |> date.to_unix_utc
  |> should.equal(8_899_200)

  date.literal("1970-04-25")
  |> date.to_unix_utc
  |> should.equal(9_849_600)

  date.literal("1970-04-26")
  |> date.to_unix_utc
  |> should.equal(9_936_000)

  date.literal("1970-04-27")
  |> date.to_unix_utc
  |> should.equal(10_022_400)

  date.literal("1978-06-28")
  |> date.to_unix_utc
  |> should.equal(267_840_000)

  date.literal("1978-01-01")
  |> date.to_unix_utc
  |> should.equal(252_460_800)

  date.literal("1979-01-01")
  |> date.to_unix_utc
  |> should.equal(283_996_800)

  date.literal("1980-01-01")
  |> date.to_unix_utc
  |> should.equal(315_532_800)

  date.literal("2000-01-01")
  |> date.to_unix_utc
  |> should.equal(946_684_800)

  date.literal("2024-06-12")
  |> date.to_unix_utc
  |> should.equal(1_718_150_400)

  date.literal("2024-12-05")
  |> date.to_unix_utc
  |> should.equal(1_733_356_800)
}

pub fn from_unix_utc_test() {
  date.from_unix_utc(0)
  |> should.equal(date.literal("1970-01-01"))

  date.from_unix_utc(267_840_000)
  |> should.equal(date.literal("1978-06-28"))

  date.from_unix_milli_utc(267_840_000_000)
  |> should.equal(date.literal("1978-06-28"))

  date.from_unix_milli_utc(267_839_999_999)
  |> should.equal(date.literal("1978-06-27"))
}

pub fn add_day_test() {
  date.literal("2024-06-13")
  |> date.add(days: 1)
  |> should.equal(date.literal("2024-06-14"))
}

pub fn add_days_test() {
  date.literal("2024-06-13")
  |> date.add(days: 2)
  |> should.equal(date.literal("2024-06-15"))
}

pub fn add_days_almost_month_boundary_test() {
  date.literal("2024-06-29")
  |> date.add(days: 1)
  |> should.equal(date.literal("2024-06-30"))
}

pub fn add_days_month_boundary_one_day_test() {
  date.literal("2024-06-30")
  |> date.add(days: 1)
  |> should.equal(date.literal("2024-07-01"))
}

pub fn add_days_month_boundary_test() {
  date.literal("2024-06-13")
  |> date.add(days: 45)
  |> should.equal(date.literal("2024-07-28"))
}

pub fn add_days_two_month_boundary_test() {
  date.literal("2024-06-13")
  |> date.add(days: 75)
  |> should.equal(date.literal("2024-08-27"))
}

pub fn add_days_year_boundary_test() {
  date.literal("2021-06-13")
  |> date.add(days: 365)
  |> should.equal(date.literal("2022-06-13"))
}

pub fn add_days_two_year_boundary_test() {
  date.literal("2021-06-13")
  |> date.add(days: 733)
  |> should.equal(date.literal("2023-06-16"))
}

pub fn add_days_leap_year_boundary_test() {
  date.literal("2023-06-13")
  |> date.add(days: 365)
  |> should.equal(date.literal("2024-06-12"))
}

pub fn subtract_day_test() {
  date.literal("2024-06-13")
  |> date.subtract(days: 1)
  |> should.equal(date.literal("2024-06-12"))
}

pub fn subtract_days_test() {
  date.literal("2024-06-13")
  |> date.subtract(days: 2)
  |> should.equal(date.literal("2024-06-11"))
}

pub fn subtract_day_month_boundary_test() {
  date.literal("2024-06-01")
  |> date.subtract(days: 2)
  |> should.equal(date.literal("2024-05-30"))
}

pub fn subtract_days_month_boundary_test() {
  date.literal("2024-06-13")
  |> date.subtract(days: 45)
  |> should.equal(date.literal("2024-04-29"))
}

pub fn subtract_days_two_month_boundary_test() {
  date.literal("2024-06-13")
  |> date.subtract(days: 75)
  |> should.equal(date.literal("2024-03-30"))
}

pub fn subtract_days_year_boundary_test() {
  date.literal("2022-06-13")
  |> date.subtract(days: 365)
  |> should.equal(date.literal("2021-06-13"))
}

pub fn subtract_days_two_year_boundary_test() {
  date.literal("2024-01-13")
  |> date.subtract(days: 733)
  |> should.equal(date.literal("2022-01-10"))
}

pub fn subtract_days_leap_year_boundary_test() {
  date.literal("2024-06-13")
  |> date.subtract(days: 365)
  |> should.equal(date.literal("2023-06-14"))
}

pub fn to_weekday_jan_not_leap_year_test() {
  date.literal("2023-01-04")
  |> date.to_day_of_week
  |> should.equal(date.Wed)
}

pub fn to_weekday_jan_leap_year_test() {
  date.literal("2024-01-09")
  |> date.to_day_of_week
  |> should.equal(date.Tue)
}

pub fn to_weekday_test() {
  date.literal("2024-06-13")
  |> date.to_day_of_week
  |> should.equal(date.Thu)

  date.literal("2024-06-14")
  |> date.to_day_of_week
  |> should.equal(date.Fri)

  date.literal("2024-06-15")
  |> date.to_day_of_week
  |> should.equal(date.Sat)

  date.literal("2024-06-16")
  |> date.to_day_of_week
  |> should.equal(date.Sun)

  date.literal("2024-06-17")
  |> date.to_day_of_week
  |> should.equal(date.Mon)
}

pub fn from_dynamic_string_test() {
  dynamic.from("2024-06-21")
  |> date.from_dynamic_string
  |> should.be_ok
  |> should.equal(date.literal("2024-06-21"))
}

pub fn from_dynamic_string_int_test() {
  dynamic.from("153")
  |> date.from_dynamic_string
  |> should.equal(
    Error([
      dynamic.DecodeError(
        expected: "tempo.Date",
        found: "Invalid format: 153",
        path: [],
      ),
    ]),
  )
}

pub fn from_dynamic_string_bad_format_test() {
  dynamic.from("2024,06,13")
  |> date.from_dynamic_string
  |> should.equal(
    Error([
      dynamic.DecodeError(
        expected: "tempo.Date",
        found: "Invalid format: 2024,06,13",
        path: [],
      ),
    ]),
  )
}

pub fn from_dynamic_string_bad_values_test() {
  dynamic.from("2024-06-35")
  |> date.from_dynamic_string
  |> should.equal(
    Error([
      dynamic.DecodeError(
        expected: "tempo.Date",
        found: "Date day out of bounds: 2024-06-35",
        path: [],
      ),
    ]),
  )
}

pub fn first_of_month_test() {
  date.literal("2024-06-21")
  |> date.first_of_month
  |> should.equal(date.literal("2024-06-01"))
}

pub fn last_of_month_test() {
  date.literal("2024-02-13")
  |> date.last_of_month
  |> should.equal(date.literal("2024-02-29"))
}

pub fn next_day_of_week_test() {
  date.literal("2024-06-21")
  |> date.next_day_of_week(date.Mon)
  |> should.equal(date.literal("2024-06-24"))

  date.literal("2024-06-21")
  |> date.next_day_of_week(date.Fri)
  |> should.equal(date.literal("2024-06-28"))
}

pub fn prior_day_of_week_test() {
  date.literal("2024-06-21")
  |> date.prior_day_of_week(date.Mon)
  |> should.equal(date.literal("2024-06-17"))

  date.literal("2024-06-21")
  |> date.prior_day_of_week(date.Fri)
  |> should.equal(date.literal("2024-06-14"))
}

pub fn next_day_of_week_leap_year_test() {
  date.literal("2024-02-22")
  |> date.next_day_of_week(date.Thu)
  |> should.equal(date.literal("2024-02-29"))
}

pub fn next_day_of_week_month_boundary_test() {
  date.literal("2024-06-30")
  |> date.next_day_of_week(date.Wed)
  |> should.equal(date.literal("2024-07-03"))
}

pub fn prior_day_of_week_leap_year_test() {
  date.literal("2024-03-02")
  |> date.prior_day_of_week(date.Mon)
  |> should.equal(date.literal("2024-02-26"))
}

pub fn prior_day_of_week_month_boundary_test() {
  date.literal("2024-07-03")
  |> date.prior_day_of_week(date.Thu)
  |> should.equal(date.literal("2024-06-27"))
}

pub fn date_no_difference_test() {
  date.literal("2024-06-13")
  |> date.difference(from: date.literal("2024-06-13"))
  |> should.equal(0)
}

pub fn date_difference_test() {
  date.literal("2024-06-12")
  |> date.difference(to: date.literal("2024-06-23"))
  |> should.equal(11)
}

pub fn date_difference_over_year_test() {
  date.literal("2023-05-22")
  |> date.difference(to: date.literal("2024-06-23"))
  |> should.equal(398)
}

pub fn date_difference_negative_test() {
  date.literal("2024-06-14")
  |> date.difference(from: date.literal("2024-06-23"))
  |> should.equal(-9)
}

pub fn date_difference_over_month_test() {
  date.literal("2024-05-22")
  |> date.difference(to: date.literal("2024-06-23"))
  |> should.equal(32)
}

pub fn date_difference_negative_month_test() {
  date.literal("2024-05-23")
  |> date.difference(from: date.literal("2024-06-23"))
  |> should.equal(-31)
}

pub fn date_difference_negative_year_test() {
  date.literal("2024-06-23")
  |> date.difference(from: date.literal("2025-06-23"))
  |> should.equal(-365)
}
