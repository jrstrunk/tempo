import gleam/order
import gleeunit/should
import tempo
import tempo/duration
import tempo/time

fn assert_ok(res) {
  let assert Ok(v) = res
  v
}

pub fn new_time_test() {
  time.new(0, 0, 0)
  |> should.equal(Ok(time.literal("00:00:00")))

  time.new(23, 59, 59)
  |> should.equal(Ok(time.literal("23:59:59")))

  time.new(23, 59, 60)
  |> should.equal(Ok(time.literal("23:59:60")))

  time.new(23, 60, 0)
  |> should.be_error

  time.new(11, 25, 40)
  |> should.equal(Ok(time.literal("11:25:40")))

  time.new(110, 25, 40)
  |> should.be_error

  time.new(11, 205, 40)
  |> should.be_error

  time.new(11, 25, 400)
  |> should.be_error
}

pub fn new_milli_test() {
  time.new_milli(0, 0, 0, 0)
  |> should.equal(Ok(time.literal("00:00:00.0")))

  time.new_milli(23, 59, 60, 0)
  |> should.equal(Ok(time.literal("23:59:60.0")))

  time.new_milli(23, 59, 59, 1)
  |> assert_ok
  |> time.get_microsecond
  |> should.equal(1000)

  time.new_milli(23, 59, 59, 533)
  |> assert_ok
  |> time.get_microsecond
  |> should.equal(533_000)

  time.new_milli(11, 25, 40, 32)
  |> assert_ok
  |> time.get_microsecond
  |> should.equal(32_000)

  time.new_milli(23, 60, 0, 0)
  |> should.be_error

  time.new_milli(11, 25, 40, 1532)
  |> should.be_error

  time.new_milli(11, 25, 40, 20_532)
  |> should.be_error

  time.new_milli(110, 25, 40, 32)
  |> should.be_error

  time.new_milli(11, 205, 40, 533)
  |> should.be_error

  time.new_milli(11, 25, 400, 34)
  |> should.be_error
}

pub fn new_micro_test() {
  time.new_micro(0, 0, 0, 0)
  |> should.equal(Ok(time.literal("00:00:00.000000")))

  time.new_micro(23, 59, 60, 0)
  |> should.equal(Ok(time.literal("23:59:60.000000")))

  time.new_micro(23, 59, 59, 533)
  |> assert_ok
  |> time.get_microsecond
  |> should.equal(533)

  time.new_micro(11, 25, 40, 32)
  |> assert_ok
  |> time.get_microsecond
  |> should.equal(32)

  time.new_micro(11, 25, 40, 1532)
  |> assert_ok
  |> time.get_microsecond
  |> should.equal(1532)

  time.new_micro(11, 25, 40, 320_532)
  |> assert_ok
  |> time.get_microsecond
  |> should.equal(320_532)

  time.new_micro(11, 25, 40, 3_205_322)
  |> should.be_error

  time.new_micro(23, 60, 0, 0)
  |> should.be_error

  time.new_micro(110, 25, 40, 32)
  |> should.be_error

  time.new_micro(11, 205, 40, 533)
  |> should.be_error
}

pub fn new_micro_1_test() {
  time.new_micro(23, 59, 59, 1)
  |> assert_ok
  |> time.get_microsecond
  |> should.equal(1)
}

pub fn to_string_test() {
  tempo.time(4, 0, 0, 0)
  |> time.to_string
  |> should.equal("04:00:00.000000")

  tempo.time(12, 13, 25, 0)
  |> time.to_string
  |> should.equal("12:13:25.000000")

  tempo.time(12, 13, 25, 123_000)
  |> time.to_string
  |> should.equal("12:13:25.123000")

  tempo.time(8, 7, 25, 1000)
  |> time.to_string
  |> should.equal("08:07:25.001000")

  tempo.time(12, 13, 25, 12_345)
  |> time.to_string
  |> should.equal("12:13:25.012345")

  tempo.time(12, 13, 25, 124)
  |> time.to_string
  |> should.equal("12:13:25.000124")
}

pub fn from_string_test() {
  "04:00:00"
  |> time.from_string
  |> should.equal(Ok(tempo.time(4, 0, 0, 0)))

  "04:00:01"
  |> time.from_string
  |> should.equal(Ok(tempo.time(4, 0, 1, 0)))

  "4:0:1"
  |> time.from_string
  |> should.equal(Ok(tempo.time(4, 0, 1, 0)))

  "04:00"
  |> time.from_string
  |> should.be_ok
  |> should.equal(time.literal("04:00:00"))

  "16:05:23"
  |> time.from_string
  |> should.equal(Ok(tempo.time(16, 5, 23, 0)))

  "16:55:23"
  |> time.from_string
  |> should.equal(Ok(tempo.time(16, 55, 23, 0)))
}

pub fn from_string_milli_test() {
  "04:00:00.1"
  |> time.from_string
  |> should.equal(Ok(tempo.time(4, 0, 0, 100_000)))

  "14:50:04.945"
  |> time.from_string
  |> should.equal(Ok(tempo.time(14, 50, 4, 945_000)))
}

pub fn from_string_micro_test() {
  "04:00:00.0000"
  |> time.from_string
  |> should.equal(Ok(tempo.time(4, 0, 0, 0)))

  "04:00:00.0100"
  |> time.from_string
  |> should.equal(Ok(tempo.time(4, 0, 0, 10_000)))

  "04:00:00.000007"
  |> time.from_string
  |> should.equal(Ok(tempo.time(4, 0, 0, 7)))
}

pub fn from_string_nano_test() {
  "15:18:50.0000003"
  |> time.from_string
  |> should.be_error
}

pub fn from_condensed_string_test() {
  "134211.314"
  |> time.from_string
  |> should.be_ok
  |> should.equal(time.literal("13:42:11.314"))
}

pub fn from_condensed_hm_string_test() {
  "1342"
  |> time.from_string
  |> should.be_ok
  |> should.equal(time.literal("13:42:00"))
}

pub fn from_string_invalid_test() {
  "19"
  |> time.from_string
  |> should.be_error

  "0.00.00"
  |> time.from_string
  |> should.be_error

  "15:18:50.0000000000"
  |> time.from_string
  |> should.be_error

  "50:18:50.000000000"
  |> time.from_string
  |> should.be_error
}

pub fn compare_equal_test() {
  time.literal("13:42:11")
  |> time.compare(to: time.literal("13:42:11"))
  |> should.equal(order.Eq)

  time.test_literal_milli(13, 42, 11, 2)
  |> time.compare(to: time.test_literal_milli(13, 42, 11, 2))
  |> should.equal(order.Eq)

  time.test_literal_micro(13, 42, 10, 300)
  |> time.compare(to: time.test_literal_micro(13, 42, 10, 300))
  |> should.equal(order.Eq)
}

pub fn compare_hours_test() {
  time.test_literal(10, 42, 11)
  |> time.compare(to: time.literal("13:42:11"))
  |> should.equal(order.Lt)

  time.literal("15:32:01")
  |> time.compare(to: time.literal("13:42:11"))
  |> should.equal(order.Gt)
}

pub fn compare_minutes_test() {
  time.literal("13:10:11")
  |> time.compare(to: time.literal("13:42:11"))
  |> should.equal(order.Lt)

  time.test_literal(13, 15, 11)
  |> time.compare(to: time.test_literal(13, 10, 11))
  |> should.equal(order.Gt)
}

pub fn compare_seconds_test() {
  time.test_literal(13, 42, 10)
  |> time.compare(to: time.literal("13:42:11"))
  |> should.equal(order.Lt)

  time.test_literal(13, 42, 15)
  |> time.compare(to: time.test_literal(13, 42, 10))
  |> should.equal(order.Gt)
}

pub fn compare_millis_test() {
  time.test_literal_milli(13, 42, 11, 300)
  |> time.compare(to: time.test_literal_milli(13, 42, 11, 2))
  |> should.equal(order.Gt)

  time.test_literal_milli(13, 42, 10, 300)
  |> time.compare(to: time.test_literal_milli(13, 42, 10, 544))
  |> should.equal(order.Lt)

  time.test_literal_milli(13, 42, 10, 300)
  |> time.compare(to: time.test_literal_micro(13, 42, 10, 300))
  |> should.equal(order.Gt)

  time.test_literal_milli(13, 42, 10, 300)
  |> time.compare(to: time.test_literal_micro(13, 42, 10, 300_000))
  |> should.equal(order.Eq)
}

pub fn compare_micros_test() {
  time.test_literal_micro(13, 42, 11, 300)
  |> time.compare(to: time.test_literal_micro(13, 42, 11, 2))
  |> should.equal(order.Gt)

  time.test_literal_micro(13, 42, 10, 300)
  |> time.compare(to: time.test_literal_milli(13, 42, 10, 544))
  |> should.equal(order.Lt)

  time.test_literal_micro(13, 42, 10, 300)
  |> time.compare(to: time.test_literal_micro(13, 42, 10, 300))
  |> should.equal(order.Eq)
}

pub fn compare_different_precision_test() {
  time.literal("13:42:10.020000")
  |> time.compare(to: time.literal("13:42:10.02"))
  |> should.equal(order.Eq)

  time.literal("13:42:11.000")
  |> time.compare(to: time.literal("13:42:11"))
  |> should.equal(order.Eq)

  time.literal("13:42")
  |> time.compare(to: time.literal("13:42:00"))
  |> should.equal(order.Eq)
}

pub fn format_test() {
  time.literal("13:42:11")
  |> time.format(tempo.CustomTime("hh:mm:ss a"))
  |> should.equal("01:42:11 pm")
}

pub fn to_duration_test() {
  time.literal("0:0:0.000300")
  |> time.to_duration
  |> duration.as_microseconds
  |> should.equal(300)

  time.literal("0:0:6")
  |> time.to_duration
  |> duration.as_milliseconds
  |> should.equal(6000)
}

pub fn from_duration_test() {
  duration.minutes(17)
  |> time.from_duration
  |> time.to_string
  |> should.equal("00:17:00.000000")
}

pub fn from_duration_negative_test() {
  duration.microseconds(-3_000_000)
  |> time.from_duration
  |> time.to_string
  |> should.equal("23:59:57.000000")
}

pub fn from_big_duration_test() {
  duration.hours(25)
  |> time.from_duration
  |> time.to_string
  |> should.equal("01:00:00.000000")
}

pub fn add_time_test() {
  time.literal("13:42:11")
  |> time.add(duration: duration.minutes(3))
  |> time.add(duration: duration.seconds(1))
  |> should.equal(time.test_literal(13, 45, 12))

  time.test_literal(13, 42, 2)
  |> time.add(duration: duration.hours(1))
  |> should.equal(time.test_literal(14, 42, 2))

  time.test_literal(13, 42, 2)
  |> time.add(duration: duration.hours(11))
  |> should.equal(time.test_literal(0, 42, 2))

  time.test_literal(13, 4, 12)
  |> time.add(duration: duration.hours(64))
  |> should.equal(time.test_literal(5, 4, 12))

  time.test_literal(13, 42, 2)
  |> time.add(duration: duration.seconds(60 * 60 * 3))
  |> should.equal(time.test_literal(16, 42, 2))
}

pub fn add_time_milli_test() {
  time.test_literal_milli(13, 45, 12, 2)
  |> time.add(duration: duration.milliseconds(3))
  |> should.equal(time.test_literal_milli(13, 45, 12, 5))

  time.test_literal_milli(13, 42, 2, 0)
  |> time.add(duration: duration.milliseconds(1311))
  |> should.equal(time.test_literal_milli(13, 42, 3, 311))
}

pub fn add_time_micro_test() {
  time.test_literal_micro(13, 45, 12, 2)
  |> time.add(duration: duration.microseconds(3))
  |> should.equal(time.test_literal_micro(13, 45, 12, 5))

  time.test_literal_micro(13, 42, 2, 0)
  |> time.add(duration: duration.microseconds(1311))
  |> should.equal(time.test_literal_micro(13, 42, 2, 1311))
}

pub fn subtract_time_test() {
  time.literal("13:42:11")
  |> time.subtract(duration: duration.minutes(3))
  |> time.subtract(duration: duration.seconds(1))
  |> should.equal(time.test_literal(13, 39, 10))

  time.literal("13:42:02")
  |> time.subtract(duration: duration.hours(1))
  |> should.equal(time.literal("12:42:02"))

  time.test_literal(13, 42, 2)
  |> time.subtract(duration: duration.hours(11))
  |> should.equal(time.test_literal(2, 42, 2))

  time.test_literal(13, 4, 12)
  |> time.subtract(duration: duration.hours(64))
  |> should.equal(time.test_literal(21, 4, 12))

  time.test_literal(13, 31, 2)
  |> time.subtract(duration: duration.seconds(60 * 60 * 3))
  |> should.equal(time.test_literal(10, 31, 2))
}

pub fn subtract_time_milli_test() {
  time.test_literal_milli(13, 45, 12, 2)
  |> time.subtract(duration: duration.milliseconds(3))
  |> should.equal(time.test_literal_milli(13, 45, 11, 999))

  time.test_literal_milli(13, 42, 2, 354)
  |> time.subtract(duration: duration.milliseconds(11))
  |> should.equal(time.test_literal_milli(13, 42, 2, 343))
}

pub fn subtract_time_micro_test() {
  time.test_literal_micro(13, 45, 12, 2)
  |> time.subtract(duration: duration.microseconds(3))
  |> should.equal(time.test_literal_micro(13, 45, 11, 999_999))

  time.literal("13:42:2.000354")
  |> time.subtract(duration: duration.microseconds(11))
  |> should.equal(time.literal("13:42:2.000343"))
}

pub fn get_difference_test() {
  time.literal("13:42:12")
  |> time.difference(from: time.literal("13:42:11"))
  |> duration.as_seconds
  |> should.equal(1)

  time.literal("08:42:13")
  |> time.difference(from: time.literal("08:42:11"))
  |> duration.as_milliseconds
  |> should.equal(2000)

  time.literal("15:42:11")
  |> time.difference(from: time.literal("13:42:11"))
  |> duration.as_hours
  |> should.equal(2)

  time.literal("15:42:12")
  |> time.difference(from: time.literal("13:00:11"))
  |> duration.as_hours_fractional
  |> should.equal(2.700277777777778)

  time.literal("13:30:11")
  |> time.difference(from: time.literal("13:55:13"))
  |> duration.as_minutes
  |> should.equal(-25)
}

pub fn from_unix_seconds_epoch_test() {
  time.from_unix_seconds(0)
  |> time.to_string
  |> should.equal("00:00:00.000000")
}

pub fn from_unix_milli_zero_test() {
  time.from_unix_milli(0)
  |> time.to_string
  |> should.equal("00:00:00.000000")
}

pub fn from_unix_no_date_test() {
  time.from_unix_seconds(373)
  |> time.to_string
  |> should.equal("00:06:13.000000")
}

pub fn from_unix_milli_no_date_test() {
  time.from_unix_milli(373_351)
  |> time.to_string
  |> should.equal("00:06:13.351000")
}

pub fn from_unix_seconds_test() {
  time.from_unix_seconds(327_132)
  |> time.to_string
  |> should.equal("18:52:12.000000")
}

pub fn from_unix_milli_test() {
  time.from_unix_milli(327_132_050)
  |> time.to_string
  |> should.equal("18:52:12.050000")
}

pub fn from_unix_seconds_large_test() {
  time.from_unix_seconds(1_718_829_395)
  |> time.to_string
  |> should.equal("20:36:35.000000")
}

pub fn from_unix_milli_large_test() {
  time.from_unix_milli(1_718_829_586_791)
  |> time.to_string
  |> should.equal("20:39:46.791000")
}

pub fn from_unix_micro_large_test() {
  time.from_unix_micro(1_718_829_586_791_832)
  |> time.to_string
  |> should.equal("20:39:46.791832")
}

pub fn small_time_left_in_day_test() {
  time.literal("23:59:03")
  |> time.left_in_day
  |> should.equal(time.literal("00:00:57"))
}

pub fn large_time_left_in_day_test() {
  time.literal("08:05:20")
  |> time.left_in_day
  |> should.equal(time.literal("15:54:40"))
}

pub fn is_between_test() {
  time.literal("05:00:00")
  |> time.is_between(
    time.Boundary(time.literal("05:00:00"), inclusive: True),
    and: time.Boundary(time.literal("15:00:00"), inclusive: False),
  )
  |> should.be_true()
}

pub fn is_between_exclusive_test() {
  time.literal("15:00:00")
  |> time.is_between(
    time.Boundary(time.literal("05:00:00"), inclusive: True),
    and: time.Boundary(time.literal("15:00:00"), inclusive: False),
  )
  |> should.be_false()
}

pub fn is_between_negative_test() {
  time.literal("13:42:11")
  |> time.is_between(
    time.Boundary(time.literal("14:00:00"), inclusive: True),
    and: time.Boundary(time.literal("15:00:00"), inclusive: False),
  )
  |> should.be_false()
}

pub fn is_outside_test() {
  time.literal("13:42:11")
  |> time.is_outside(
    time.Boundary(time.literal("05:00:00"), inclusive: True),
    and: time.Boundary(time.literal("13:42:11"), inclusive: False),
  )
  |> should.be_false()
}

pub fn is_outside_negative_test() {
  time.literal("13:42:11")
  |> time.is_outside(
    time.Boundary(time.literal("14:00:00"), inclusive: True),
    and: time.Boundary(time.literal("15:00:00"), inclusive: False),
  )
  |> should.be_true()
}

pub fn difference_round_trip_test() {
  let a = time.literal("17:34:07")
  let b = time.literal("13:42:11")

  a
  |> time.difference(from: b)
  |> time.add(b, duration: _)
  |> should.equal(a)
}

pub fn until_positive_test() {
  time.literal("23:54:00")
  |> time.until(time.literal("23:59:04"))
  |> duration.as_seconds
  |> should.equal(304)
}

pub fn until_negative_test() {
  time.literal("23:59:03")
  |> time.until(time.literal("22:00:00"))
  |> duration.as_milliseconds
  |> should.equal(0)
}

pub fn since_positive_test() {
  time.literal("23:54:00")
  |> time.since(time.literal("13:30:04"))
  |> duration.as_hours
  |> should.equal(10)
}

pub fn since_negative_test() {
  time.literal("12:30:54")
  |> time.since(time.literal("22:00:00"))
  |> duration.as_milliseconds
  |> should.equal(0)
}
// pub fn monotonic_difference_override_test() {
//   let start = tempo.time(9, 30, 12, 300, Some(600), Some(0))
//   let warped = tempo.time(8, 30, 12, 600, Some(1000), Some(0))

//   time.difference(warped, from: start)
//   |> duration.as_microseconds
//   |> should.equal(400)
// }

// pub fn monotonic_difference_no_override_test() {
//   let start = tempo.time(9, 30, 12, 300, Some(600), Some(0))
//   let warped = tempo.time(8, 30, 12, 600)

//   time.difference(warped, from: start)
//   |> duration.as_microseconds
//   |> should.not_equal(400)
// }

// pub fn monotonic_abs_difference_override_test() {
//   let start = tempo.time(9, 30, 12, 300, Some(600), Some(0))
//   let warped = tempo.time(8, 30, 12, 600, Some(1000), Some(0))

//   time.difference_abs(start, from: warped)
//   |> duration.as_microseconds
//   |> should.equal(400)
// }

// pub fn monotonic_survives_add_test() {
//   let start = tempo.time(9, 30, 12, 300, Some(600), Some(0))
//   let warped = tempo.time(8, 30, 12, 600, Some(1000), Some(0))

//   time.add(start, duration: duration.microseconds(500))
//   |> time.difference(from: warped)
//   |> duration.as_microseconds
//   |> should.equal(100)
// }

// pub fn monotonic_survives_subtract_test() {
//   let start = tempo.time(9, 30, 12, 300, Some(600), Some(0))
//   let warped = tempo.time(8, 30, 12, 600, Some(1000), Some(0))

//   time.subtract(warped, duration: duration.microseconds(200))
//   |> time.difference(from: start)
//   |> duration.as_microseconds
//   |> should.equal(200)
// }

// pub fn unique_compare_override_test() {
//   let start = tempo.time(9, 30, 12, 300, Some(10_000), Some(1))
//   let warped = tempo.time(8, 30, 12, 600, Some(1000), Some(2))

//   time.compare(start, to: warped)
//   |> should.equal(order.Lt)
// }

// pub fn unique_compare_no_override_test() {
//   let start = tempo.time(9, 30, 12, 300, Some(10_000), Some(1))
//   let warped = tempo.time(8, 30, 12, 600)

//   time.compare(start, to: warped)
//   |> should.equal(order.Gt)
// }

// pub fn monotonic_compare_override_test() {
//   let start = tempo.time(9, 30, 12, 300, Some(100), None)
//   let warped = tempo.time(8, 30, 12, 600, Some(1000), None)

//   time.compare(start, to: warped)
//   |> should.equal(order.Lt)
// }

// pub fn unique_compare_does_not_survive_add_test() {
//   let start = tempo.time(9, 30, 12, 300, Some(10_000), Some(1))
//   let warped = tempo.time(8, 30, 12, 600, Some(1000), Some(2))

//   time.add(warped, duration: duration.microseconds(500))
//   |> time.compare(to: start)
//   |> should.equal(order.Lt)
// }

// pub fn unique_compare_does_not_survive_subtract_test() {
//   let start = tempo.time(9, 30, 12, 300, Some(10_000), Some(1))
//   let warped = tempo.time(8, 30, 12, 600, Some(1000), Some(2))

//   time.subtract(warped, duration: duration.microseconds(500))
//   |> time.compare(to: start)
//   |> should.equal(order.Lt)
// }
