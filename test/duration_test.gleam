import gleeunit/should
import tempo
import tempo/duration

pub fn monotonic_time_start_stop_test() {
  duration.start_monotonic()
  |> duration.stop_monotonic
  |> fn(d: tempo.Duration) { d |> tempo.duration_get_ns >= 0 }
  |> should.be_true
}

pub fn format_single_test() {
  duration.minutes(1)
  |> duration.format_as(duration.Minute, decimals: 1)
  |> should.equal("1.0 minute")
}

pub fn format_negative_test() {
  duration.minutes(-1)
  |> duration.format_as(duration.Minute, decimals: 1)
  |> should.equal("-1.0 minute")
}

pub fn format_more_than_1_test() {
  duration.hours(3)
  |> duration.format_as(duration.Hour, decimals: 2)
  |> should.equal("3.00 hours")
}

pub fn format_no_decimals_test() {
  duration.seconds(100)
  |> duration.format_as(duration.Second, decimals: 0)
  |> should.equal("100 seconds")
}

pub fn format_different_unit_test() {
  duration.hours(3)
  |> duration.format_as(duration.Minute, decimals: 0)
  |> should.equal("180 minutes")
}

pub fn format_different_unit_decimal_test() {
  duration.milliseconds(34)
  |> duration.format_as(duration.Second, decimals: 6)
  |> should.equal("0.034000 seconds")
}

pub fn format_different_unit_whole_and_decimal_test() {
  duration.seconds(338)
  |> duration.format_as(duration.Minute, decimals: 2)
  |> should.equal("5.63 minutes")
}

pub fn format_two_units_test() {
  duration.milliseconds(100_303)
  |> duration.format_as_many([duration.Minute, duration.Second], decimals: 2)
  |> should.equal("1 minute and 40.30 seconds")
}

pub fn format_three_units_small_test() {
  duration.milliseconds(4)
  |> duration.format_as_many(
    [duration.Minute, duration.Second, duration.Millisecond],
    decimals: 0,
  )
  |> should.equal("0 minutes, 0 seconds, and 4 milliseconds")
}

pub fn format_three_units_large_test() {
  duration.milliseconds(301_671)
  |> duration.format_as_many(
    [duration.Minute, duration.Second, duration.Millisecond],
    decimals: 0,
  )
  |> should.equal("5 minutes, 1 second, and 671 milliseconds")
}

pub fn format_years_test() {
  duration.nanoseconds(93_691_332_000_000_000)
  |> duration.format
  |> should.equal("2 ~years, 50 weeks, 6 days, 9 hours, and 22 minutes")
}

pub fn format_weeks_test() {
  duration.nanoseconds(691_332_000_000_000)
  |> duration.format
  |> should.equal("1 week, 1 day, 0 hours, and 2 minutes")
}

pub fn format_days_test() {
  duration.nanoseconds(172_980_000_000_000)
  |> duration.format
  |> should.equal("2 days, 0 hours, and 3 minutes")
}

pub fn format_hours_test() {
  duration.nanoseconds(49_676_829_182_912)
  |> duration.format
  |> should.equal("13 hours, 47 minutes, and 56.82 seconds")
}

pub fn format_minutes_test() {
  duration.nanoseconds(676_829_182_912)
  |> duration.format
  |> should.equal("11 minutes and 16.829 seconds")
}

pub fn format_seconds_test() {
  duration.nanoseconds(46_829_182_912)
  |> duration.format
  |> should.equal("46.829 seconds")
}

pub fn format_milliseconds_test() {
  duration.nanoseconds(829_182_912)
  |> duration.format
  |> should.equal("829 milliseconds")
}

pub fn format_microseconds_test() {
  duration.nanoseconds(182_912)
  |> duration.format
  |> should.equal("182 microseconds")
}

pub fn format_nanoseconds_test() {
  duration.nanoseconds(912)
  |> duration.format
  |> should.equal("912 nanoseconds")
}

pub fn duration_roundtrip_test() {
  duration.days(3)
  |> duration.as_days
  |> should.equal(3)

  duration.hours(5)
  |> duration.as_hours
  |> should.equal(5)

  duration.minutes(7)
  |> duration.as_minutes
  |> should.equal(7)

  duration.seconds(9)
  |> duration.as_seconds
  |> should.equal(9)

  duration.milliseconds(11)
  |> duration.as_milliseconds
  |> should.equal(11)

  duration.microseconds(13)
  |> duration.as_microseconds
  |> should.equal(13)

  duration.nanoseconds(15)
  |> duration.as_nanoseconds
  |> should.equal(15)
}

pub fn absolute_test() {
  duration.days(3)
  |> duration.absolute
  |> should.equal(duration.days(3))

  duration.hours(-5)
  |> duration.absolute
  |> should.equal(duration.hours(5))

  duration.minutes(-7000)
  |> duration.absolute
  |> should.equal(duration.minutes(7000))
}

pub fn inverse_test() {
  duration.days(3)
  |> duration.inverse
  |> duration.format_as(duration.Day, 0)
  |> should.equal("-3 days")

  duration.hours(-5)
  |> duration.inverse
  |> should.equal(duration.hours(5))

  duration.minutes(-7000)
  |> duration.inverse
  |> duration.format_as(duration.Minute, 0)
  |> should.equal("7000 minutes")
}

pub fn is_negative_test() {
  duration.days(1)
  |> duration.is_negative
  |> should.be_false()

  duration.hours(-13)
  |> duration.is_negative
  |> should.be_true()
}
