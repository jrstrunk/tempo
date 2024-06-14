import gleam/order
import gleeunit
import gleeunit/should
import tempo
import tempo/naive_time

pub fn main() {
  gleeunit.main()
}

pub fn time_now_test() {
  naive_time.now_local()
  |> naive_time.is_later_or_equal(than: naive_time.literal("00:00:00"))
  |> should.be_true

  naive_time.now_utc()
  |> naive_time.is_later_or_equal(than: naive_time.literal("00:00:00"))
  |> should.be_true
}

pub fn new_time_test() {
  naive_time.new(0, 0, 0)
  |> should.equal(Ok(tempo.NaiveTime(0, 0, 0, 0)))

  naive_time.new(23, 59, 59)
  |> should.equal(Ok(tempo.NaiveTime(23, 59, 59, 0)))

  naive_time.new(23, 59, 60)
  |> should.equal(Ok(tempo.NaiveTime(23, 59, 60, 0)))

  naive_time.new(23, 60, 0)
  |> should.be_error

  naive_time.new(11, 25, 40)
  |> should.equal(Ok(tempo.NaiveTime(11, 25, 40, 0)))

  naive_time.new(110, 25, 40)
  |> should.be_error

  naive_time.new(11, 205, 40)
  |> should.be_error

  naive_time.new(11, 25, 400)
  |> should.be_error
}

pub fn new_milli_test() {
  naive_time.new_milli(0, 0, 0, 0)
  |> should.equal(Ok(tempo.NaiveTimeMilli(0, 0, 0, 0)))

  naive_time.new_milli(23, 59, 59, 1)
  |> should.equal(Ok(tempo.NaiveTimeMilli(23, 59, 59, 1_000_000)))

  naive_time.new_milli(23, 59, 60, 533)
  |> should.equal(Ok(tempo.NaiveTimeMilli(23, 59, 60, 533_000_000)))

  naive_time.new_milli(11, 25, 40, 32)
  |> should.equal(Ok(tempo.NaiveTimeMilli(11, 25, 40, 32_000_000)))

  naive_time.new_milli(23, 60, 0, 0)
  |> should.be_error

  naive_time.new_milli(11, 25, 40, 1532)
  |> should.be_error

  naive_time.new_milli(11, 25, 40, 20_532)
  |> should.be_error

  naive_time.new_milli(110, 25, 40, 32)
  |> should.be_error

  naive_time.new_milli(11, 205, 40, 533)
  |> should.be_error

  naive_time.new_milli(11, 25, 400, 34)
  |> should.be_error
}

pub fn new_micro_test() {
  naive_time.new_micro(0, 0, 0, 0)
  |> should.equal(Ok(tempo.NaiveTimeMicro(0, 0, 0, 0)))

  naive_time.new_micro(23, 59, 59, 1)
  |> should.equal(Ok(tempo.NaiveTimeMicro(23, 59, 59, 1000)))

  naive_time.new_micro(23, 59, 60, 533)
  |> should.equal(Ok(tempo.NaiveTimeMicro(23, 59, 60, 533_000)))

  naive_time.new_micro(11, 25, 40, 32)
  |> should.equal(Ok(tempo.NaiveTimeMicro(11, 25, 40, 32_000)))
  naive_time.new_micro(11, 25, 40, 1532)
  |> should.equal(Ok(tempo.NaiveTimeMicro(11, 25, 40, 1_532_000)))

  naive_time.new_micro(11, 25, 40, 320_532)
  |> should.equal(Ok(tempo.NaiveTimeMicro(11, 25, 40, 320_532_000)))

  naive_time.new_micro(11, 25, 40, 3_205_322)
  |> should.be_error

  naive_time.new_micro(23, 60, 0, 0)
  |> should.be_error

  naive_time.new_micro(110, 25, 40, 32)
  |> should.be_error

  naive_time.new_micro(11, 205, 40, 533)
  |> should.be_error
}

pub fn new_nano_test() {
  naive_time.new_nano(0, 0, 0, 0)
  |> should.equal(Ok(tempo.NaiveTimeNano(0, 0, 0, 0)))

  naive_time.new_nano(23, 59, 59, 1)
  |> should.equal(Ok(tempo.NaiveTimeNano(23, 59, 59, 1)))

  naive_time.new_nano(23, 59, 60, 533)
  |> should.equal(Ok(tempo.NaiveTimeNano(23, 59, 60, 533)))

  naive_time.new_nano(11, 25, 40, 32)
  |> should.equal(Ok(tempo.NaiveTimeNano(11, 25, 40, 32)))

  naive_time.new_nano(23, 60, 0, 0)
  |> should.be_error

  naive_time.new_nano(11, 25, 40, 1532)
  |> should.equal(Ok(tempo.NaiveTimeNano(11, 25, 40, 1532)))

  naive_time.new_nano(11, 25, 40, 109_513_532)
  |> should.equal(Ok(tempo.NaiveTimeNano(11, 25, 40, 109_513_532)))

  naive_time.new_nano(11, 25, 40, 1_095_135_322)
  |> should.be_error

  naive_time.new_nano(110, 25, 40, 32)
  |> should.be_error

  naive_time.new_nano(11, 205, 40, 533)
  |> should.be_error
}

pub fn set_hour_test() {
  tempo.NaiveTime(4, 0, 0, 0)
  |> naive_time.set_hour(0)
  |> should.equal(Ok(tempo.NaiveTime(0, 0, 0, 0)))

  tempo.NaiveTime(13, 0, 0, 0)
  |> naive_time.set_hour(23)
  |> should.equal(Ok(tempo.NaiveTime(23, 0, 0, 0)))

  tempo.NaiveTime(0, 0, 0, 0)
  |> naive_time.set_hour(24)
  |> should.equal(Ok(tempo.NaiveTime(24, 0, 0, 0)))

  tempo.NaiveTime(11, 31, 4, 0)
  |> naive_time.set_hour(35)
  |> should.be_error
}

pub fn set_minute_test() {
  tempo.NaiveTime(0, 0, 0, 0)
  |> naive_time.set_minute(53)
  |> should.equal(Ok(tempo.NaiveTime(0, 53, 0, 0)))

  tempo.NaiveTime(14, 57, 3, 0)
  |> naive_time.set_minute(5)
  |> should.equal(Ok(tempo.NaiveTime(14, 5, 3, 0)))

  tempo.NaiveTime(14, 57, 3, 0)
  |> naive_time.set_minute(60)
  |> should.be_error
}

pub fn set_second_test() {
  tempo.NaiveTime(0, 0, 0, 0)
  |> naive_time.set_second(53)
  |> should.equal(Ok(tempo.NaiveTime(0, 0, 53, 0)))

  tempo.NaiveTime(14, 57, 3, 0)
  |> naive_time.set_second(5)
  |> should.equal(Ok(tempo.NaiveTime(14, 57, 5, 0)))

  tempo.NaiveTime(14, 57, 3, 0)
  |> naive_time.set_second(60)
  |> should.be_error
}

pub fn set_leap_second_test() {
  tempo.NaiveTime(23, 59, 15, 0)
  |> naive_time.set_second(60)
  |> should.equal(Ok(tempo.NaiveTime(23, 59, 60, 0)))
}

pub fn set_milli_test() {
  tempo.NaiveTime(11, 54, 4, 0)
  |> naive_time.set_milli(123)
  |> should.equal(Ok(tempo.NaiveTimeMilli(11, 54, 4, 123_000_000)))

  tempo.NaiveTimeMilli(11, 54, 4, 123_000_000)
  |> naive_time.set_milli(456)
  |> should.equal(Ok(tempo.NaiveTimeMilli(11, 54, 4, 456_000_000)))

  tempo.NaiveTimeMicro(11, 54, 4, 123_000)
  |> naive_time.set_milli(789)
  |> should.equal(Ok(tempo.NaiveTimeMilli(11, 54, 4, 789_000_000)))

  tempo.NaiveTimeNano(11, 54, 4, 123)
  |> naive_time.set_milli(11)
  |> should.equal(Ok(tempo.NaiveTimeMilli(11, 54, 4, 11_000_000)))

  tempo.NaiveTime(11, 54, 4, 0)
  |> naive_time.set_milli(5123)
  |> should.be_error
}

pub fn set_micro_test() {
  tempo.NaiveTime(11, 54, 4, 0)
  |> naive_time.set_micro(123)
  |> should.equal(Ok(tempo.NaiveTimeMicro(11, 54, 4, 123_000)))

  tempo.NaiveTimeMilli(11, 54, 4, 123_000_000)
  |> naive_time.set_micro(45)
  |> should.equal(Ok(tempo.NaiveTimeMicro(11, 54, 4, 45_000)))

  tempo.NaiveTimeMicro(11, 54, 4, 123_000)
  |> naive_time.set_micro(456)
  |> should.equal(Ok(tempo.NaiveTimeMicro(11, 54, 4, 456_000)))

  tempo.NaiveTimeNano(11, 54, 4, 123)
  |> naive_time.set_micro(789)
  |> should.equal(Ok(tempo.NaiveTimeMicro(11, 54, 4, 789_000)))

  tempo.NaiveTime(11, 54, 4, 0)
  |> naive_time.set_micro(512_325)
  |> should.equal(Ok(tempo.NaiveTimeMicro(11, 54, 4, 512_325_000)))

  tempo.NaiveTime(11, 54, 4, 0)
  |> naive_time.set_micro(5_123_252)
  |> should.be_error
}

pub fn set_nano_test() {
  tempo.NaiveTime(11, 54, 4, 0)
  |> naive_time.set_nano(123)
  |> should.equal(Ok(tempo.NaiveTimeNano(11, 54, 4, 123)))

  tempo.NaiveTimeMilli(11, 54, 4, 123_000_000)
  |> naive_time.set_nano(45)
  |> should.equal(Ok(tempo.NaiveTimeNano(11, 54, 4, 45)))

  tempo.NaiveTimeMicro(11, 54, 4, 123_000)
  |> naive_time.set_nano(456)
  |> should.equal(Ok(tempo.NaiveTimeNano(11, 54, 4, 456)))

  tempo.NaiveTimeNano(11, 54, 4, 123)
  |> naive_time.set_nano(789)
  |> should.equal(Ok(tempo.NaiveTimeNano(11, 54, 4, 789)))

  tempo.NaiveTime(11, 54, 4, 0)
  |> naive_time.set_nano(512_305_530)
  |> should.equal(Ok(tempo.NaiveTimeNano(11, 54, 4, 512_305_530)))

  tempo.NaiveTime(11, 54, 4, 0)
  |> naive_time.set_nano(5_123_055_300)
  |> should.be_error
}

pub fn to_string_test() {
  tempo.NaiveTime(4, 0, 0, 0)
  |> naive_time.to_string
  |> should.equal("04:00:00")

  tempo.NaiveTime(12, 13, 25, 0)
  |> naive_time.to_string
  |> should.equal("12:13:25")

  tempo.NaiveTimeMilli(12, 13, 25, 123_000_000)
  |> naive_time.to_string
  |> should.equal("12:13:25.123")

  tempo.NaiveTimeMilli(8, 7, 25, 1_000_000)
  |> naive_time.to_string
  |> should.equal("08:07:25.001")

  tempo.NaiveTimeMicro(12, 13, 25, 12_345_000)
  |> naive_time.to_string
  |> should.equal("12:13:25.012345")

  tempo.NaiveTimeNano(12, 13, 25, 124_567)
  |> naive_time.to_string
  |> should.equal("12:13:25.000124567")
}

pub fn from_string_test() {
  "04:00:00"
  |> naive_time.from_string
  |> should.equal(Ok(tempo.NaiveTime(4, 0, 0, 0)))

  "04:00:01"
  |> naive_time.from_string
  |> should.equal(Ok(tempo.NaiveTime(4, 0, 1, 0)))

  "4:0:1"
  |> naive_time.from_string
  |> should.equal(Ok(tempo.NaiveTime(4, 0, 1, 0)))

  "16:05:23"
  |> naive_time.from_string
  |> should.equal(Ok(tempo.NaiveTime(16, 5, 23, 0)))

  "16:55:23"
  |> naive_time.from_string
  |> should.equal(Ok(tempo.NaiveTime(16, 55, 23, 0)))
}

pub fn from_string_milli_test() {
  "04:00:00.1"
  |> naive_time.from_string
  |> should.equal(Ok(tempo.NaiveTimeMilli(4, 0, 0, 100_000_000)))

  "14:50:04.945"
  |> naive_time.from_string
  |> should.equal(Ok(tempo.NaiveTimeMilli(14, 50, 4, 945_000_000)))
}

pub fn from_string_micro_test() {
  "04:00:00.0000"
  |> naive_time.from_string
  |> should.equal(Ok(tempo.NaiveTimeMicro(4, 0, 0, 0)))

  "04:00:00.0100"
  |> naive_time.from_string
  |> should.equal(Ok(tempo.NaiveTimeMicro(4, 0, 0, 10_000_000)))

  "04:00:00.000007"
  |> naive_time.from_string
  |> should.equal(Ok(tempo.NaiveTimeMicro(4, 0, 0, 7000)))
}

pub fn from_string_nano_test() {
  "15:18:50.0000003"
  |> naive_time.from_string
  |> should.equal(Ok(tempo.NaiveTimeNano(15, 18, 50, 300)))

  "15:18:50.000000001"
  |> naive_time.from_string
  |> should.equal(Ok(tempo.NaiveTimeNano(15, 18, 50, 1)))

  "15:18:50.000000000"
  |> naive_time.from_string
  |> should.equal(Ok(tempo.NaiveTimeNano(15, 18, 50, 0)))
}

pub fn from_string_invalid_test() {
  "0:00"
  |> naive_time.from_string
  |> should.be_error

  "0.00.00"
  |> naive_time.from_string
  |> should.be_error

  "15:18:50.0000000000"
  |> naive_time.from_string
  |> should.be_error

  "50:18:50.000000000"
  |> naive_time.from_string
  |> should.be_error
}

pub fn compare_equal_test() {
  naive_time.literal("13:42:11")
  |> naive_time.compare(to: naive_time.literal("13:42:11"))
  |> should.equal(order.Eq)

  naive_time.test_literal_milli(13, 42, 11, 2)
  |> naive_time.compare(to: naive_time.test_literal_milli(13, 42, 11, 2))
  |> should.equal(order.Eq)

  naive_time.test_literal_micro(13, 42, 10, 300)
  |> naive_time.compare(to: naive_time.test_literal_micro(13, 42, 10, 300))
  |> should.equal(order.Eq)
}

pub fn compare_hours_test() {
  naive_time.test_literal(10, 42, 11)
  |> naive_time.compare(to: naive_time.literal("13:42:11"))
  |> should.equal(order.Lt)

  naive_time.test_literal(15, 42, 11)
  |> naive_time.compare(to: naive_time.literal("13:42:11"))
  |> should.equal(order.Gt)
}

pub fn compare_minutes_test() {
  naive_time.test_literal(13, 10, 11)
  |> naive_time.compare(to: naive_time.literal("13:42:11"))
  |> should.equal(order.Lt)

  naive_time.test_literal(13, 15, 11)
  |> naive_time.compare(to: naive_time.test_literal(13, 10, 11))
  |> should.equal(order.Gt)
}

pub fn compare_seconds_test() {
  naive_time.test_literal(13, 42, 10)
  |> naive_time.compare(to: naive_time.literal("13:42:11"))
  |> should.equal(order.Lt)

  naive_time.test_literal(13, 42, 15)
  |> naive_time.compare(to: naive_time.test_literal(13, 42, 10))
  |> should.equal(order.Gt)
}

pub fn compare_millis_test() {
  naive_time.test_literal_milli(13, 42, 11, 300)
  |> naive_time.compare(to: naive_time.test_literal_milli(13, 42, 11, 2))
  |> should.equal(order.Gt)

  naive_time.test_literal_milli(13, 42, 10, 300)
  |> naive_time.compare(to: naive_time.test_literal_milli(13, 42, 10, 544))
  |> should.equal(order.Lt)

  naive_time.test_literal_milli(13, 42, 10, 300)
  |> naive_time.compare(to: naive_time.test_literal_micro(13, 42, 10, 300))
  |> should.equal(order.Gt)

  naive_time.test_literal_milli(13, 42, 10, 300)
  |> naive_time.compare(to: naive_time.test_literal_micro(13, 42, 10, 300_000))
  |> should.equal(order.Eq)

  naive_time.test_literal_milli(13, 42, 10, 300)
  |> naive_time.compare(to: naive_time.test_literal_nano(13, 42, 10, 300))
  |> should.equal(order.Gt)
}

pub fn compare_micros_test() {
  naive_time.test_literal_micro(13, 42, 11, 300)
  |> naive_time.compare(to: naive_time.test_literal_micro(13, 42, 11, 2))
  |> should.equal(order.Gt)

  naive_time.test_literal_micro(13, 42, 10, 300)
  |> naive_time.compare(to: naive_time.test_literal_milli(13, 42, 10, 544))
  |> should.equal(order.Lt)

  naive_time.test_literal_micro(13, 42, 10, 300)
  |> naive_time.compare(to: naive_time.test_literal_nano(13, 42, 10, 300_000))
  |> should.equal(order.Eq)

  naive_time.test_literal_micro(13, 42, 10, 1)
  |> naive_time.compare(to: naive_time.test_literal_nano(13, 42, 10, 300))
  |> should.equal(order.Gt)
}

pub fn compare_nanos_test() {
  naive_time.test_literal_nano(13, 42, 11, 300)
  |> naive_time.compare(to: naive_time.test_literal_nano(13, 42, 11, 2))
  |> should.equal(order.Gt)

  naive_time.test_literal_nano(13, 42, 10, 300)
  |> naive_time.compare(to: naive_time.test_literal_nano(13, 42, 10, 544))
  |> should.equal(order.Lt)

  naive_time.test_literal_nano(13, 42, 10, 200_000_000)
  |> naive_time.compare(to: naive_time.test_literal_milli(13, 42, 10, 200))
  |> should.equal(order.Eq)
}

pub fn nanoseconds_roundtrip_test() {
  naive_time.literal("13:42:11")
  |> naive_time.time_to_nanoseconds
  |> naive_time.nanoseconds_to_time
  |> should.equal(naive_time.test_literal_nano(13, 42, 11, 0))

  naive_time.test_literal_milli(13, 42, 11, 2)
  |> naive_time.time_to_nanoseconds
  |> naive_time.nanoseconds_to_time
  |> should.equal(naive_time.test_literal_nano(13, 42, 11, 2_000_000))

  naive_time.test_literal_micro(13, 42, 10, 300)
  |> naive_time.time_to_nanoseconds
  |> naive_time.nanoseconds_to_time
  |> should.equal(naive_time.test_literal_nano(13, 42, 10, 300_000))

  naive_time.test_literal_nano(13, 42, 10, 300)
  |> naive_time.time_to_nanoseconds
  |> naive_time.nanoseconds_to_time
  |> should.equal(naive_time.test_literal_nano(13, 42, 10, 300))

  naive_time.test_literal_nano(0, 0, 0, 300)
  |> naive_time.time_to_nanoseconds
  |> should.equal(300)

  naive_time.test_literal(0, 0, 6)
  |> naive_time.time_to_nanoseconds
  |> should.equal(6_000_000_000)

  naive_time.nanoseconds_to_time(-3_000_000_000)
  |> should.equal(naive_time.test_literal_nano(23, 59, 57, 0))
}

pub fn add_time_test() {
  naive_time.literal("13:42:11")
  |> naive_time.add_duration(naive_time.new_duration(0, 3, 1))
  |> should.equal(naive_time.test_literal(13, 45, 12))

  naive_time.test_literal(13, 42, 2)
  |> naive_time.add_duration(naive_time.new_duration_hours(1))
  |> should.equal(naive_time.test_literal(14, 42, 2))

  naive_time.test_literal(13, 42, 2)
  |> naive_time.add_duration(naive_time.new_duration_hours(11))
  |> should.equal(naive_time.test_literal(0, 42, 2))

  naive_time.test_literal(13, 4, 12)
  |> naive_time.add_duration(naive_time.new_duration_hours(64))
  |> should.equal(naive_time.test_literal(5, 4, 12))

  naive_time.test_literal(13, 42, 2)
  |> naive_time.add_duration(naive_time.new_duration_seconds(60 * 60 * 3))
  |> should.equal(naive_time.test_literal(16, 42, 2))
}

pub fn add_time_milli_test() {
  naive_time.test_literal_milli(13, 45, 12, 2)
  |> naive_time.add_duration(naive_time.new_duration_milli(3))
  |> should.equal(naive_time.test_literal_milli(13, 45, 12, 5))

  naive_time.test_literal_milli(13, 42, 2, 0)
  |> naive_time.add_duration(naive_time.new_duration_milli(1311))
  |> should.equal(naive_time.test_literal_milli(13, 42, 3, 311))
}

pub fn add_time_micro_test() {
  naive_time.test_literal_micro(13, 45, 12, 2)
  |> naive_time.add_duration(naive_time.new_duration_micro(3))
  |> should.equal(naive_time.test_literal_micro(13, 45, 12, 5))

  naive_time.test_literal_micro(13, 42, 2, 0)
  |> naive_time.add_duration(naive_time.new_duration_micro(1311))
  |> should.equal(naive_time.test_literal_micro(13, 42, 2, 1311))
}

pub fn add_time_nano_test() {
  naive_time.test_literal_nano(13, 45, 12, 2)
  |> naive_time.add_duration(naive_time.new_duration_nano(3))
  |> should.equal(naive_time.test_literal_nano(13, 45, 12, 5))

  naive_time.test_literal_nano(13, 42, 2, 0)
  |> naive_time.add_duration(naive_time.new_duration_nano(471_313_131))
  |> should.equal(naive_time.test_literal_nano(13, 42, 2, 471_313_131))
}

pub fn substract_time_test() {
  naive_time.literal("13:42:11")
  |> naive_time.substract_duration(naive_time.new_duration(0, 3, 1))
  |> should.equal(naive_time.test_literal(13, 39, 10))

  naive_time.test_literal(13, 42, 2)
  |> naive_time.substract_duration(naive_time.new_duration_hours(1))
  |> should.equal(naive_time.test_literal(12, 42, 2))

  naive_time.test_literal(13, 42, 2)
  |> naive_time.substract_duration(naive_time.new_duration_hours(11))
  |> should.equal(naive_time.test_literal(2, 42, 2))

  naive_time.test_literal(13, 4, 12)
  |> naive_time.substract_duration(naive_time.new_duration_hours(64))
  |> should.equal(naive_time.test_literal(21, 4, 12))

  naive_time.test_literal(13, 31, 2)
  |> naive_time.substract_duration(naive_time.new_duration_seconds(60 * 60 * 3))
  |> should.equal(naive_time.test_literal(10, 31, 2))
}

pub fn substract_time_milli_test() {
  naive_time.test_literal_milli(13, 45, 12, 2)
  |> naive_time.substract_duration(naive_time.new_duration_milli(3))
  |> should.equal(naive_time.test_literal_milli(13, 45, 11, 999))

  naive_time.test_literal_milli(13, 42, 2, 354)
  |> naive_time.substract_duration(naive_time.new_duration_milli(11))
  |> should.equal(naive_time.test_literal_milli(13, 42, 2, 343))
}

pub fn substract_time_micro_test() {
  naive_time.test_literal_micro(13, 45, 12, 2)
  |> naive_time.substract_duration(naive_time.new_duration_micro(3))
  |> should.equal(naive_time.test_literal_micro(13, 45, 11, 999_999))

  naive_time.literal("13:42:2.000354")
  |> naive_time.substract_duration(naive_time.new_duration_micro(11))
  |> should.equal(naive_time.literal("13:42:2.000343"))
}

pub fn substract_time_nano_test() {
  naive_time.test_literal_nano(13, 45, 12, 2)
  |> naive_time.substract_duration(naive_time.new_duration_nano(4))
  |> should.equal(naive_time.literal("13:45:11.999999998"))

  naive_time.test_literal_nano(13, 42, 2, 354)
  |> naive_time.substract_duration(naive_time.new_duration_nano(13))
  |> should.equal(naive_time.test_literal_nano(13, 42, 2, 341))
}

pub fn get_difference_test() {
  naive_time.literal("13:42:11")
  |> naive_time.difference(from: naive_time.literal("13:42:12"))
  |> should.equal(naive_time.new_duration(0, 0, 1))

  naive_time.literal("13:42:11")
  |> naive_time.difference(from: naive_time.literal("13:42:12"))
  |> naive_time.as_seconds
  |> should.equal(1)

  naive_time.literal("08:42:11")
  |> naive_time.difference(from: naive_time.literal("08:42:13"))
  |> naive_time.as_milliseconds
  |> should.equal(2000)

  naive_time.literal("13:42:11")
  |> naive_time.difference(from: naive_time.literal("15:42:12"))
  |> naive_time.as_hours
  |> should.equal(2)

  naive_time.test_literal(13, 0, 11)
  |> naive_time.difference(from: naive_time.literal("15:42:12"))
  |> naive_time.as_hours_fractional
  |> should.equal(2.700277777777778)

  naive_time.test_literal(13, 55, 11)
  |> naive_time.difference(from: naive_time.literal("13:30:11"))
  |> naive_time.as_minutes
  |> should.equal(-25)
}

pub fn to_second_precision_test() {
  naive_time.literal("13:42:11.195423")
  |> naive_time.to_second_precision
  |> should.equal(naive_time.literal("13:42:11"))
}

pub fn to_milli_precision_test() {
  naive_time.literal("13:42:11.195423")
  |> naive_time.to_milli_precision
  |> should.equal(naive_time.literal("13:42:11.195"))

  naive_time.literal("13:42:11")
  |> naive_time.to_milli_precision
  |> should.equal(naive_time.literal("13:42:11.000"))
}

pub fn to_micro_precision_test() {
  naive_time.literal("13:42:11.1954237")
  |> naive_time.to_micro_precision
  |> should.equal(naive_time.literal("13:42:11.195423"))

  naive_time.literal("13:42:11")
  |> naive_time.to_micro_precision
  |> should.equal(naive_time.literal("13:42:11.000000"))
}

pub fn to_nano_precision_test() {
  naive_time.literal("13:42:11.1954237")
  |> naive_time.to_nano_precision
  |> should.equal(naive_time.literal("13:42:11.195423700"))
}
