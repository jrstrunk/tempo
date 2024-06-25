import gleam/order
import gleeunit
import gleeunit/should
import tempo
import tempo/duration
import tempo/time

pub fn main() {
  gleeunit.main()
}

pub fn time_now_test() {
  time.now_local()
  |> time.is_later_or_equal(to: time.literal("00:00:00"))
  |> should.be_true

  time.now_utc()
  |> time.is_later_or_equal(to: time.literal("00:00:00"))
  |> should.be_true
}

pub fn new_time_test() {
  time.new(0, 0, 0)
  |> should.equal(Ok(tempo.Time(0, 0, 0, 0)))

  time.new(23, 59, 59)
  |> should.equal(Ok(tempo.Time(23, 59, 59, 0)))

  time.new(23, 59, 60)
  |> should.equal(Ok(tempo.Time(23, 59, 60, 0)))

  time.new(23, 60, 0)
  |> should.be_error

  time.new(11, 25, 40)
  |> should.equal(Ok(tempo.Time(11, 25, 40, 0)))

  time.new(110, 25, 40)
  |> should.be_error

  time.new(11, 205, 40)
  |> should.be_error

  time.new(11, 25, 400)
  |> should.be_error
}

pub fn new_milli_test() {
  time.new_milli(0, 0, 0, 0)
  |> should.equal(Ok(tempo.TimeMilli(0, 0, 0, 0)))

  time.new_milli(23, 59, 60, 0)
  |> should.equal(Ok(tempo.TimeMilli(23, 59, 60, 0)))

  time.new_milli(23, 59, 59, 1)
  |> should.equal(Ok(tempo.TimeMilli(23, 59, 59, 1_000_000)))

  time.new_milli(23, 59, 59, 533)
  |> should.equal(Ok(tempo.TimeMilli(23, 59, 59, 533_000_000)))

  time.new_milli(11, 25, 40, 32)
  |> should.equal(Ok(tempo.TimeMilli(11, 25, 40, 32_000_000)))

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
  |> should.equal(Ok(tempo.TimeMicro(0, 0, 0, 0)))

  time.new_micro(23, 59, 60, 0)
  |> should.equal(Ok(tempo.TimeMicro(23, 59, 60, 0)))

  time.new_micro(23, 59, 59, 1)
  |> should.equal(Ok(tempo.TimeMicro(23, 59, 59, 1000)))

  time.new_micro(23, 59, 59, 533)
  |> should.equal(Ok(tempo.TimeMicro(23, 59, 59, 533_000)))

  time.new_micro(11, 25, 40, 32)
  |> should.equal(Ok(tempo.TimeMicro(11, 25, 40, 32_000)))
  time.new_micro(11, 25, 40, 1532)
  |> should.equal(Ok(tempo.TimeMicro(11, 25, 40, 1_532_000)))

  time.new_micro(11, 25, 40, 320_532)
  |> should.equal(Ok(tempo.TimeMicro(11, 25, 40, 320_532_000)))

  time.new_micro(11, 25, 40, 3_205_322)
  |> should.be_error

  time.new_micro(23, 60, 0, 0)
  |> should.be_error

  time.new_micro(110, 25, 40, 32)
  |> should.be_error

  time.new_micro(11, 205, 40, 533)
  |> should.be_error
}

pub fn new_nano_test() {
  time.new_nano(0, 0, 0, 0)
  |> should.equal(Ok(tempo.TimeNano(0, 0, 0, 0)))

  time.new_nano(23, 59, 60, 0)
  |> should.equal(Ok(tempo.TimeNano(23, 59, 60, 0)))

  time.new_nano(23, 59, 59, 1)
  |> should.equal(Ok(tempo.TimeNano(23, 59, 59, 1)))

  time.new_nano(23, 59, 59, 533)
  |> should.equal(Ok(tempo.TimeNano(23, 59, 59, 533)))

  time.new_nano(11, 25, 40, 32)
  |> should.equal(Ok(tempo.TimeNano(11, 25, 40, 32)))

  time.new_nano(23, 60, 0, 0)
  |> should.be_error

  time.new_nano(11, 25, 40, 1532)
  |> should.equal(Ok(tempo.TimeNano(11, 25, 40, 1532)))

  time.new_nano(11, 25, 40, 109_513_532)
  |> should.equal(Ok(tempo.TimeNano(11, 25, 40, 109_513_532)))

  time.new_nano(11, 25, 40, 1_095_135_322)
  |> should.be_error

  time.new_nano(110, 25, 40, 32)
  |> should.be_error

  time.new_nano(11, 205, 40, 533)
  |> should.be_error
}

pub fn set_hour_test() {
  tempo.Time(4, 0, 0, 0)
  |> time.set_hour(0)
  |> should.equal(Ok(tempo.Time(0, 0, 0, 0)))

  tempo.Time(13, 0, 0, 0)
  |> time.set_hour(23)
  |> should.equal(Ok(tempo.Time(23, 0, 0, 0)))

  time.literal("00:00:00")
  |> time.set_hour(24)
  |> should.be_ok
  |> should.equal(time.literal("24:00"))

  tempo.Time(11, 31, 4, 0)
  |> time.set_hour(35)
  |> should.be_error
}

pub fn set_minute_test() {
  tempo.Time(0, 0, 0, 0)
  |> time.set_minute(53)
  |> should.equal(Ok(tempo.Time(0, 53, 0, 0)))

  tempo.Time(14, 57, 3, 0)
  |> time.set_minute(5)
  |> should.equal(Ok(tempo.Time(14, 5, 3, 0)))

  tempo.Time(14, 57, 3, 0)
  |> time.set_minute(60)
  |> should.be_error
}

pub fn set_second_test() {
  tempo.Time(0, 0, 0, 0)
  |> time.set_second(53)
  |> should.equal(Ok(tempo.Time(0, 0, 53, 0)))

  tempo.Time(14, 57, 3, 0)
  |> time.set_second(5)
  |> should.equal(Ok(tempo.Time(14, 57, 5, 0)))

  tempo.Time(14, 57, 3, 0)
  |> time.set_second(60)
  |> should.be_error
}

pub fn set_leap_second_test() {
  tempo.Time(23, 59, 15, 0)
  |> time.set_second(60)
  |> should.equal(Ok(tempo.Time(23, 59, 60, 0)))
}

pub fn set_milli_test() {
  tempo.Time(11, 54, 4, 0)
  |> time.set_milli(123)
  |> should.equal(Ok(tempo.TimeMilli(11, 54, 4, 123_000_000)))

  tempo.TimeMilli(11, 54, 4, 123_000_000)
  |> time.set_milli(456)
  |> should.equal(Ok(tempo.TimeMilli(11, 54, 4, 456_000_000)))

  tempo.TimeMicro(11, 54, 4, 123_000)
  |> time.set_milli(789)
  |> should.equal(Ok(tempo.TimeMilli(11, 54, 4, 789_000_000)))

  tempo.TimeNano(11, 54, 4, 123)
  |> time.set_milli(11)
  |> should.equal(Ok(tempo.TimeMilli(11, 54, 4, 11_000_000)))

  tempo.Time(11, 54, 4, 0)
  |> time.set_milli(5123)
  |> should.be_error
}

pub fn set_micro_test() {
  tempo.Time(11, 54, 4, 0)
  |> time.set_micro(123)
  |> should.equal(Ok(tempo.TimeMicro(11, 54, 4, 123_000)))

  tempo.TimeMilli(11, 54, 4, 123_000_000)
  |> time.set_micro(45)
  |> should.equal(Ok(tempo.TimeMicro(11, 54, 4, 45_000)))

  tempo.TimeMicro(11, 54, 4, 123_000)
  |> time.set_micro(456)
  |> should.equal(Ok(tempo.TimeMicro(11, 54, 4, 456_000)))

  tempo.TimeNano(11, 54, 4, 123)
  |> time.set_micro(789)
  |> should.equal(Ok(tempo.TimeMicro(11, 54, 4, 789_000)))

  tempo.Time(11, 54, 4, 0)
  |> time.set_micro(512_325)
  |> should.equal(Ok(tempo.TimeMicro(11, 54, 4, 512_325_000)))

  tempo.Time(11, 54, 4, 0)
  |> time.set_micro(5_123_252)
  |> should.be_error
}

pub fn set_nano_test() {
  tempo.Time(11, 54, 4, 0)
  |> time.set_nano(123)
  |> should.equal(Ok(tempo.TimeNano(11, 54, 4, 123)))

  tempo.TimeMilli(11, 54, 4, 123_000_000)
  |> time.set_nano(45)
  |> should.equal(Ok(tempo.TimeNano(11, 54, 4, 45)))

  tempo.TimeMicro(11, 54, 4, 123_000)
  |> time.set_nano(456)
  |> should.equal(Ok(tempo.TimeNano(11, 54, 4, 456)))

  tempo.TimeNano(11, 54, 4, 123)
  |> time.set_nano(789)
  |> should.equal(Ok(tempo.TimeNano(11, 54, 4, 789)))

  tempo.Time(11, 54, 4, 0)
  |> time.set_nano(512_305_530)
  |> should.equal(Ok(tempo.TimeNano(11, 54, 4, 512_305_530)))

  tempo.Time(11, 54, 4, 0)
  |> time.set_nano(5_123_055_300)
  |> should.be_error
}

pub fn to_string_test() {
  tempo.Time(4, 0, 0, 0)
  |> time.to_string
  |> should.equal("04:00:00")

  tempo.Time(12, 13, 25, 0)
  |> time.to_string
  |> should.equal("12:13:25")

  tempo.TimeMilli(12, 13, 25, 123_000_000)
  |> time.to_string
  |> should.equal("12:13:25.123")

  tempo.TimeMilli(8, 7, 25, 1_000_000)
  |> time.to_string
  |> should.equal("08:07:25.001")

  tempo.TimeMicro(12, 13, 25, 12_345_000)
  |> time.to_string
  |> should.equal("12:13:25.012345")

  tempo.TimeNano(12, 13, 25, 124_567)
  |> time.to_string
  |> should.equal("12:13:25.000124567")
}

pub fn from_string_test() {
  "04:00:00"
  |> time.from_string
  |> should.equal(Ok(tempo.Time(4, 0, 0, 0)))

  "04:00:01"
  |> time.from_string
  |> should.equal(Ok(tempo.Time(4, 0, 1, 0)))

  "4:0:1"
  |> time.from_string
  |> should.equal(Ok(tempo.Time(4, 0, 1, 0)))

  "04:00"
  |> time.from_string
  |> should.be_ok
  |> should.equal(time.literal("04:00:00"))

  "16:05:23"
  |> time.from_string
  |> should.equal(Ok(tempo.Time(16, 5, 23, 0)))

  "16:55:23"
  |> time.from_string
  |> should.equal(Ok(tempo.Time(16, 55, 23, 0)))
}

pub fn from_string_milli_test() {
  "04:00:00.1"
  |> time.from_string
  |> should.equal(Ok(tempo.TimeMilli(4, 0, 0, 100_000_000)))

  "14:50:04.945"
  |> time.from_string
  |> should.equal(Ok(tempo.TimeMilli(14, 50, 4, 945_000_000)))
}

pub fn from_string_micro_test() {
  "04:00:00.0000"
  |> time.from_string
  |> should.equal(Ok(tempo.TimeMicro(4, 0, 0, 0)))

  "04:00:00.0100"
  |> time.from_string
  |> should.equal(Ok(tempo.TimeMicro(4, 0, 0, 10_000_000)))

  "04:00:00.000007"
  |> time.from_string
  |> should.equal(Ok(tempo.TimeMicro(4, 0, 0, 7000)))
}

pub fn from_string_nano_test() {
  "15:18:50.0000003"
  |> time.from_string
  |> should.equal(Ok(tempo.TimeNano(15, 18, 50, 300)))

  "15:18:50.000000001"
  |> time.from_string
  |> should.equal(Ok(tempo.TimeNano(15, 18, 50, 1)))

  "15:18:50.000000000"
  |> time.from_string
  |> should.equal(Ok(tempo.TimeNano(15, 18, 50, 0)))
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

  time.test_literal_milli(13, 42, 10, 300)
  |> time.compare(to: time.test_literal_nano(13, 42, 10, 300))
  |> should.equal(order.Gt)
}

pub fn compare_micros_test() {
  time.test_literal_micro(13, 42, 11, 300)
  |> time.compare(to: time.test_literal_micro(13, 42, 11, 2))
  |> should.equal(order.Gt)

  time.test_literal_micro(13, 42, 10, 300)
  |> time.compare(to: time.test_literal_milli(13, 42, 10, 544))
  |> should.equal(order.Lt)

  time.test_literal_micro(13, 42, 10, 300)
  |> time.compare(to: time.test_literal_nano(13, 42, 10, 300_000))
  |> should.equal(order.Eq)

  time.test_literal_micro(13, 42, 10, 1)
  |> time.compare(to: time.test_literal_nano(13, 42, 10, 300))
  |> should.equal(order.Gt)
}

pub fn compare_nanos_test() {
  time.test_literal_nano(13, 42, 11, 300)
  |> time.compare(to: time.test_literal_nano(13, 42, 11, 2))
  |> should.equal(order.Gt)

  time.test_literal_nano(13, 42, 10, 300)
  |> time.compare(to: time.test_literal_nano(13, 42, 10, 544))
  |> should.equal(order.Lt)

  time.test_literal_nano(13, 42, 10, 200_000_000)
  |> time.compare(to: time.test_literal_milli(13, 42, 10, 200))
  |> should.equal(order.Eq)
}

pub fn compare_different_precision_test() {
  time.literal("13:42:10.020000000")
  |> time.compare(to: time.literal("13:42:10.02"))
  |> should.equal(order.Eq)

  time.literal("13:42:11.000")
  |> time.compare(to: time.literal("13:42:11"))
  |> should.equal(order.Eq)

  time.literal("13:42")
  |> time.compare(to: time.literal("13:42:00"))
  |> should.equal(order.Eq)
}

pub fn nanoseconds_round_trip_test() {
  time.literal("13:42:11")
  |> time.to_nanoseconds
  |> time.from_nanoseconds
  |> should.equal(time.test_literal_nano(13, 42, 11, 0))

  time.literal("13:42:11.002")
  |> time.to_nanoseconds
  |> time.from_nanoseconds
  |> should.equal(time.test_literal_nano(13, 42, 11, 2_000_000))

  time.literal("13:42:10.000300")
  |> time.to_nanoseconds
  |> time.from_nanoseconds
  |> should.equal(time.test_literal_nano(13, 42, 10, 300_000))

  time.literal("13:42:10.000000020")
  |> time.to_nanoseconds
  |> time.from_nanoseconds
  |> should.equal(time.test_literal_nano(13, 42, 10, 20))
}

pub fn to_duration_test() {
  time.literal("0:0:0.000000300")
  |> time.to_duration
  |> duration.as_nanoseconds
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
  |> should.equal("00:17:00.000000000")
}

pub fn from_duration_negative_test() {
  duration.nanoseconds(-3_000_000_000)
  |> time.from_duration
  |> time.to_string
  |> should.equal("23:59:57.000000000")
}

pub fn from_big_duration_test() {
  duration.hours(25)
  |> time.from_duration
  |> time.to_string
  |> should.equal("01:00:00.000000000")
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

pub fn add_time_nano_test() {
  time.test_literal_nano(13, 45, 12, 2)
  |> time.add(duration: duration.nanoseconds(3))
  |> should.equal(time.test_literal_nano(13, 45, 12, 5))

  time.test_literal_nano(13, 42, 2, 0)
  |> time.add(duration: duration.nanoseconds(471_313_131))
  |> should.equal(time.test_literal_nano(13, 42, 2, 471_313_131))
}

pub fn substract_time_test() {
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

pub fn substract_time_milli_test() {
  time.test_literal_milli(13, 45, 12, 2)
  |> time.subtract(duration: duration.milliseconds(3))
  |> should.equal(time.test_literal_milli(13, 45, 11, 999))

  time.test_literal_milli(13, 42, 2, 354)
  |> time.subtract(duration: duration.milliseconds(11))
  |> should.equal(time.test_literal_milli(13, 42, 2, 343))
}

pub fn substract_time_micro_test() {
  time.test_literal_micro(13, 45, 12, 2)
  |> time.subtract(duration: duration.microseconds(3))
  |> should.equal(time.test_literal_micro(13, 45, 11, 999_999))

  time.literal("13:42:2.000354")
  |> time.subtract(duration: duration.microseconds(11))
  |> should.equal(time.literal("13:42:2.000343"))
}

pub fn substract_time_nano_test() {
  time.test_literal_nano(13, 45, 12, 2)
  |> time.subtract(duration: duration.nanoseconds(4))
  |> should.equal(time.literal("13:45:11.999999998"))

  time.test_literal_nano(13, 42, 2, 354)
  |> time.subtract(duration: duration.nanoseconds(13))
  |> should.equal(time.test_literal_nano(13, 42, 2, 341))
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

pub fn to_second_precision_test() {
  time.literal("13:42:11.195423")
  |> time.to_second_precision
  |> should.equal(time.literal("13:42:11"))
}

pub fn to_milli_precision_test() {
  time.literal("13:42:11.195423")
  |> time.to_milli_precision
  |> should.equal(time.literal("13:42:11.195"))

  time.literal("13:42:11")
  |> time.to_milli_precision
  |> should.equal(time.literal("13:42:11.000"))
}

pub fn to_micro_precision_test() {
  time.literal("13:42:11.1954237")
  |> time.to_micro_precision
  |> should.equal(time.literal("13:42:11.195423"))

  time.literal("13:42:11")
  |> time.to_micro_precision
  |> should.equal(time.literal("13:42:11.000000"))
}

pub fn to_nano_precision_test() {
  time.literal("13:42:11.1954237")
  |> time.to_nano_precision
  |> should.equal(time.literal("13:42:11.195423700"))
}

pub fn from_unix_utc_epoch_test() {
  time.from_unix_utc(0)
  |> time.to_string
  |> should.equal("00:00:00")
}

pub fn from_unix_milli_utc_zero_test() {
  time.from_unix_milli_utc(0)
  |> time.to_string
  |> should.equal("00:00:00.000")
}

pub fn from_unix_no_date_test() {
  time.from_unix_utc(373)
  |> time.to_string
  |> should.equal("00:06:13")
}

pub fn from_unix_milli_no_date_test() {
  time.from_unix_milli_utc(373_351)
  |> time.to_string
  |> should.equal("00:06:13.351")
}

pub fn from_unix_utc_test() {
  time.from_unix_utc(327_132)
  |> time.to_string
  |> should.equal("18:52:12")
}

pub fn from_unix_milli_utc_test() {
  time.from_unix_milli_utc(327_132_050)
  |> time.to_string
  |> should.equal("18:52:12.050")
}

pub fn from_unix_utc_large_test() {
  time.from_unix_utc(1_718_829_395)
  |> time.to_string
  |> should.equal("20:36:35")
}

pub fn from_unix_milli_utc_large_test() {
  time.from_unix_milli_utc(1_718_829_586_791)
  |> time.to_string
  |> should.equal("20:39:46.791")
}

pub fn from_unix_micro_utc_large_test() {
  time.from_unix_micro_utc(1_718_829_586_791_832)
  |> time.to_string
  |> should.equal("20:39:46.791832")
}

pub fn from_unix_nano_utc_large_test() {
  time.from_unix_nano_utc(1_718_829_586_791_832_352)
  |> time.to_string
  |> should.equal("20:39:46.791832352")
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
