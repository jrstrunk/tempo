import gleam/order
import gleeunit
import gleeunit/should
import tempo.{Apr, Aug, Dec, Feb, Jan, Jul, Jun, Mar, May, Nov, Oct}
import tempo/date

pub fn main() {
  gleeunit.main()
}

pub fn new_date_test() {
  date.new(2024, 6, 13)
  |> should.equal(Ok(tempo.Date(2024, Jun, 13)))

  date.new(2013, 13, 16)
  |> should.equal(Error(Nil))
}

pub fn from_string_date_dot_delim_test() {
  date.from_string("2024.06.13")
  |> should.equal(Ok(tempo.Date(2024, Jun, 13)))

  date.from_string("2024.2.29")
  |> should.equal(Ok(tempo.Date(2024, Feb, 29)))
}

pub fn from_string_date_slash_delim_test() {
  date.from_string("2024/06/13")
  |> should.equal(Ok(tempo.Date(2024, Jun, 13)))

  date.from_string("2024/6/7")
  |> should.equal(Ok(tempo.Date(2024, Jun, 7)))
}

pub fn from_string_date_underscore_delim_test() {
  date.from_string("2024_06_13")
  |> should.equal(Ok(tempo.Date(2024, Jun, 13)))

  date.from_string("2016_2_29")
  |> should.equal(Ok(tempo.Date(2016, Feb, 29)))
}

pub fn from_string_date_dash_delim_test() {
  date.from_string("2024-11-13")
  |> should.equal(Ok(tempo.Date(2024, Nov, 13)))

  date.from_string("2024-6-3")
  |> should.equal(Ok(tempo.Date(2024, Jun, 3)))
}

pub fn from_string_date_space_delim_test() {
  date.from_string("2024 06 13")
  |> should.equal(Ok(tempo.Date(2024, Jun, 13)))

  date.from_string("2024 5 6")
  |> should.equal(Ok(tempo.Date(2024, May, 6)))
}

pub fn from_string_date_no_delim_test() {
  date.from_string("20240613")
  |> should.equal(Ok(tempo.Date(2024, Jun, 13)))
}

pub fn from_string_bad_date_test() {
  date.from_string("2024-06-13a")
  |> should.equal(Error(Nil))

  date.from_string("2046")
  |> should.equal(Error(Nil))

  date.from_string("20242077")
  |> should.equal(Error(Nil))

  date.from_string("20-06-13")
  |> should.equal(Error(Nil))

  date.from_string("2024/15/13")
  |> should.equal(Error(Nil))

  date.from_string("2024.01.33")
  |> should.equal(Error(Nil))

  date.from_string("20242_02_15")
  |> should.equal(Error(Nil))

  date.from_string("2024t01t13")
  |> should.equal(Error(Nil))
}

pub fn to_string_test() {
  tempo.Date(2024, Oct, 13)
  |> date.to_string
  |> should.equal("2024-10-13")

  tempo.Date(2024, Jun, 3)
  |> date.to_string
  |> should.equal("2024-06-03")
}

pub fn to_tuple_test() {
  tempo.Date(2024, Jun, 13)
  |> date.to_tuple
  |> should.equal(#(2024, 6, 13))

  tempo.Date(2016, Feb, 29)
  |> date.to_tuple
  |> should.equal(#(2016, 2, 29))
}

pub fn compare_eq_date_test() {
  tempo.Date(2024, Jun, 13)
  |> date.compare(tempo.Date(2024, Jun, 13))
  |> should.equal(order.Eq)
}

pub fn compare_lt_date_test() {
  tempo.Date(2024, Jun, 13)
  |> date.compare(tempo.Date(2024, Jun, 14))
  |> should.equal(order.Lt)
}

pub fn compare_gt_date_test() {
  tempo.Date(2024, Jun, 13)
  |> date.compare(tempo.Date(2024, Jun, 12))
  |> should.equal(order.Gt)
}

pub fn compare_eq_month_test() {
  tempo.Date(2024, May, 10)
  |> date.compare(tempo.Date(2024, May, 10))
  |> should.equal(order.Eq)
}

pub fn compare_lt_month_test() {
  tempo.Date(2024, May, 10)
  |> date.compare(tempo.Date(2024, May, 11))
  |> should.equal(order.Lt)
}

pub fn compare_gt_month_test() {
  tempo.Date(2024, May, 10)
  |> date.compare(tempo.Date(2024, May, 9))
  |> should.equal(order.Gt)
}

pub fn compare_eq_year_test() {
  tempo.Date(2021, Dec, 31)
  |> date.compare(tempo.Date(2021, Dec, 31))
  |> should.equal(order.Eq)
}

pub fn compare_lt_year_test() {
  tempo.Date(2021, Dec, 31)
  |> date.compare(tempo.Date(2022, Dec, 31))
  |> should.equal(order.Lt)
}

pub fn compare_gt_year_test() {
  tempo.Date(2021, Dec, 31)
  |> date.compare(tempo.Date(2020, Dec, 31))
  |> should.equal(order.Gt)
}

pub fn is_earlier_test() {
  tempo.Date(2024, Jun, 13)
  |> date.is_earlier(than: tempo.Date(2024, Jun, 14))
  |> should.be_true()

  tempo.Date(2024, Jun, 13)
  |> date.is_earlier(than: tempo.Date(2024, Jun, 12))
  |> should.be_false()
}

pub fn is_earlier_or_equal_test() {
  tempo.Date(2024, Jun, 13)
  |> date.is_earlier_or_equal(than: tempo.Date(2024, Jun, 14))
  |> should.be_true()

  tempo.Date(2024, Jun, 14)
  |> date.is_earlier_or_equal(than: tempo.Date(2024, Jun, 14))
  |> should.be_true()

  tempo.Date(2024, Jun, 15)
  |> date.is_earlier_or_equal(than: tempo.Date(2024, Jun, 14))
  |> should.be_false()

  tempo.Date(2024, Jun, 15)
  |> date.is_earlier_or_equal(than: tempo.Date(2024, Jun, 14))
  |> should.be_false()
}

pub fn is_equal_test() {
  tempo.Date(2024, Jun, 13)
  |> date.is_equal(to: tempo.Date(2024, Jun, 13))
  |> should.be_true()

  tempo.Date(2024, Jun, 13)
  |> date.is_equal(to: tempo.Date(2024, Jun, 14))
  |> should.be_false()
}

pub fn is_later_test() {
  tempo.Date(2024, Jun, 14)
  |> date.is_later(than: tempo.Date(2024, Jun, 13))
  |> should.be_true()

  tempo.Date(2024, Jun, 12)
  |> date.is_later(than: tempo.Date(2024, Jun, 13))
  |> should.be_false()
}

pub fn is_later_or_equal_test() {
  tempo.Date(2024, Jun, 14)
  |> date.is_later_or_equal(than: tempo.Date(2024, Jun, 13))
  |> should.be_true()

  tempo.Date(2024, Jun, 13)
  |> date.is_later_or_equal(than: tempo.Date(2024, Jun, 13))
  |> should.be_true()

  tempo.Date(2024, Jun, 12)
  |> date.is_later_or_equal(than: tempo.Date(2024, Jun, 13))
  |> should.be_false()

  tempo.Date(2024, Jun, 12)
  |> date.is_later_or_equal(than: tempo.Date(2024, Jun, 13))
  |> should.be_false()
}

pub fn date_to_unix_test() {
  tempo.Date(1970, Jan, 1)
  |> date.to_unix_utc
  |> should.equal(0)

  tempo.Date(1970, Jan, 14)
  |> date.to_unix_utc
  |> should.equal(1_123_200)

  tempo.Date(1970, Mar, 14)
  |> date.to_unix_utc
  |> should.equal(6_220_800)

  tempo.Date(1970, Apr, 11)
  |> date.to_unix_utc
  |> should.equal(8_640_000)

  tempo.Date(1970, Apr, 20)
  |> date.to_unix_utc
  |> should.equal(9_417_600)

  tempo.Date(1970, Apr, 16)
  |> date.to_unix_utc
  |> should.equal(9_072_000)

  tempo.Date(1970, Apr, 14)
  |> date.to_unix_utc
  |> should.equal(8_899_200)

  tempo.Date(1970, Apr, 25)
  |> date.to_unix_utc
  |> should.equal(9_849_600)

  tempo.Date(1970, Apr, 26)
  |> date.to_unix_utc
  |> should.equal(9_936_000)

  tempo.Date(1970, Apr, 27)
  |> date.to_unix_utc
  |> should.equal(10_022_400)

  tempo.Date(1978, Jun, 28)
  |> date.to_unix_utc
  |> should.equal(267_840_000)

  tempo.Date(1978, Jan, 1)
  |> date.to_unix_utc
  |> should.equal(252_460_800)

  tempo.Date(1979, Jan, 1)
  |> date.to_unix_utc
  |> should.equal(283_996_800)

  tempo.Date(1980, Jan, 1)
  |> date.to_unix_utc
  |> should.equal(315_532_800)

  tempo.Date(2000, Jan, 1)
  |> date.to_unix_utc
  |> should.equal(946_684_800)

  tempo.Date(2024, Jun, 12)
  |> date.to_unix_utc
  |> should.equal(1_718_150_400)

  tempo.Date(2024, Dec, 5)
  |> date.to_unix_utc
  |> should.equal(1_733_356_800)
}

pub fn from_unix_utc_test() {
  date.from_unix_utc(0)
  |> should.equal(tempo.Date(1970, Jan, 1))

  date.from_unix_utc(267_840_000)
  |> should.equal(tempo.Date(1978, Jun, 28))

  date.from_unix_utc_milli(267_840_000_000)
  |> should.equal(tempo.Date(1978, Jun, 28))

  date.from_unix_utc_milli(267_839_999_999)
  |> should.equal(tempo.Date(1978, Jun, 27))
}

pub fn add_day_test() {
  tempo.Date(2024, Jun, 13)
  |> date.add_days(1)
  |> should.equal(tempo.Date(2024, Jun, 14))
}

pub fn add_days_test() {
  tempo.Date(2024, Jun, 13)
  |> date.add_days(2)
  |> should.equal(tempo.Date(2024, Jun, 15))
}

pub fn add_days_month_boundary_test() {
  tempo.Date(2024, Jun, 13)
  |> date.add_days(45)
  |> should.equal(tempo.Date(2024, Jul, 28))
}

pub fn add_days_two_month_boundary_test() {
  tempo.Date(2024, Jun, 13)
  |> date.add_days(75)
  |> should.equal(tempo.Date(2024, Aug, 27))
}

pub fn add_days_year_boundary_test() {
  tempo.Date(2021, Jun, 13)
  |> date.add_days(365)
  |> should.equal(tempo.Date(2022, Jun, 13))
}

pub fn add_days_two_year_boundary_test() {
  tempo.Date(2021, Jun, 13)
  |> date.add_days(733)
  |> should.equal(tempo.Date(2023, Jun, 16))
}

pub fn add_days_leap_year_boundary_test() {
  tempo.Date(2023, Jun, 13)
  |> date.add_days(365)
  |> should.equal(tempo.Date(2024, Jun, 12))
}

pub fn subtract_day_test() {
  tempo.Date(2024, Jun, 13)
  |> date.subtract_days(1)
  |> should.equal(tempo.Date(2024, Jun, 12))
}

pub fn subtract_days_test() {
  tempo.Date(2024, Jun, 13)
  |> date.subtract_days(2)
  |> should.equal(tempo.Date(2024, Jun, 11))
}

pub fn subtract_day_month_boundary_test() {
  tempo.Date(2024, Jun, 1)
  |> date.subtract_days(2)
  |> should.equal(tempo.Date(2024, May, 30))
}

pub fn subtract_days_month_boundary_test() {
  tempo.Date(2024, Jun, 13)
  |> date.subtract_days(45)
  |> should.equal(tempo.Date(2024, Apr, 29))
}

pub fn subtract_days_two_month_boundary_test() {
  tempo.Date(2024, Jun, 13)
  |> date.subtract_days(75)
  |> should.equal(tempo.Date(2024, Mar, 30))
}

pub fn subtract_days_year_boundary_test() {
  tempo.Date(2022, Jun, 13)
  |> date.subtract_days(365)
  |> should.equal(tempo.Date(2021, Jun, 13))
}

pub fn subtract_days_two_year_boundary_test() {
  tempo.Date(2024, Jan, 13)
  |> date.subtract_days(733)
  |> should.equal(tempo.Date(2022, Jan, 10))
}

pub fn subtract_days_leap_year_boundary_test() {
  tempo.Date(2024, Jun, 13)
  |> date.subtract_days(365)
  |> should.equal(tempo.Date(2023, Jun, 14))
}

pub fn to_weekday_jan_not_leap_year_test() {
  tempo.Date(2023, Jan, 4)
  |> date.to_weekday
  |> should.equal(tempo.Wed)
}

pub fn to_weekday_jan_leap_year_test() {
  tempo.Date(2024, Jan, 9)
  |> date.to_weekday
  |> should.equal(tempo.Tue)
}

pub fn to_weekday_test() {
  tempo.Date(2024, Jun, 13)
  |> date.to_weekday
  |> should.equal(tempo.Thu)

  tempo.Date(2024, Jun, 14)
  |> date.to_weekday
  |> should.equal(tempo.Fri)

  tempo.Date(2024, Jun, 15)
  |> date.to_weekday
  |> should.equal(tempo.Sat)

  tempo.Date(2024, Jun, 16)
  |> date.to_weekday
  |> should.equal(tempo.Sun)

  tempo.Date(2024, Jun, 17)
  |> date.to_weekday
  |> should.equal(tempo.Mon)
}
