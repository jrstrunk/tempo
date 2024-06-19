import gleam/io
import gleam/order
import gleeunit
import gleeunit/should
import tempo/date
import tempo/datetime
import tempo/duration
import tempo/naive_datetime
import tempo/offset
import tempo/time

pub fn main() {
  gleeunit.main()
}

pub fn from_string_negative_offset_test() {
  datetime.from_string("2024-06-13T13:42:11.354053-04:00")
  |> should.be_ok
  |> should.equal(datetime.literal("2024-06-13T13:42:11.354053-04:00"))
}

pub fn from_string_positive_offset_test() {
  datetime.from_string("2024-06-13T03:42:01+10:00")
  |> should.be_ok
  |> should.equal(datetime.literal("2024-06-13T03:42:01+10:00"))
}

pub fn from_string_with_z_offset_test() {
  datetime.from_string("2024-06-13T03:42:01.32Z")
  |> should.be_ok
  |> should.equal(datetime.literal("2024-06-13T03:42:01.32-00:00"))
}

pub fn from_condensed_string_negative_offset_test() {
  datetime.from_string("20240613T134211.314-04:00")
  |> should.be_ok
  |> should.equal(datetime.literal("2024-06-13T13:42:11.314-04:00"))
}

pub fn from_string_condensed_offset_test() {
  datetime.from_string("20240613T134211.314-04")
  |> should.be_ok
  |> should.equal(datetime.literal("2024-06-13T13:42:11.314-04:00"))

  datetime.from_string("2024-05-23T19:16:12+0000")
  |> should.be_ok
  |> should.equal(datetime.literal("2024-05-23T19:16:12+00:00"))
}

pub fn from_naive_string_test() {
  datetime.from_string("2024-06-13T13:42:11")
  |> should.be_error
}

pub fn to_string_test() {
  datetime.literal("20240613T134211.314-04")
  |> datetime.to_string
  |> should.equal("2024-06-13T13:42:11.314-04:00")
}

pub fn date_to_string_test() {
  datetime.literal("20240613")
  |> datetime.to_string
  |> should.equal("2024-06-13T00:00:00Z")
}

pub fn get_date_test() {
  datetime.literal("20240613T134211.314+05")
  |> datetime.get_date
  |> should.equal(date.literal("2024-06-13"))
}

pub fn get_time_test() {
  datetime.literal("20240613T134211.314213-04:01")
  |> datetime.get_time
  |> should.equal(time.literal("13:42:11.314213"))
}

pub fn get_offset_test() {
  datetime.literal("20240613T134211.314-04")
  |> datetime.get_offset
  |> should.equal(offset.literal("-04:00"))
}

pub fn add_time_test() {
  datetime.literal("2024-06-13T03:42:01+10:00")
  |> datetime.add(duration.seconds(4))
  |> datetime.to_string
  |> should.equal("2024-06-13T03:42:05+10:00")
}

pub fn add_time_day_boundary_test() {
  datetime.literal("2024-06-13T23:50:10Z")
  |> datetime.add(duration.minutes(13))
  |> datetime.to_string
  |> should.equal("2024-06-14T00:03:10Z")
}

pub fn add_time_multiple_day_boundary_test() {
  datetime.literal("2024-06-13T03:50:10Z")
  |> datetime.add(duration.days(3))
  |> datetime.add(duration.minutes(13))
  |> datetime.to_string
  |> should.equal("2024-06-16T04:03:10Z")
}

pub fn add_negative_time_test() {
  datetime.literal("2024-06-13T03:42:05+10:00")
  |> datetime.add(duration.seconds(-4))
  |> datetime.to_string
  |> should.equal("2024-06-13T03:42:01+10:00")
}

pub fn add_negative_time_day_boundary_test() {
  datetime.literal("2024-06-13T00:03:10Z")
  |> datetime.add(duration.minutes(-13))
  |> datetime.to_string
  |> should.equal("2024-06-12T23:50:10Z")
}

pub fn subtract_time_test() {
  datetime.literal("2024-06-13T03:42:05+10:00")
  |> datetime.subtract(duration.seconds(4))
  |> datetime.to_string
  |> should.equal("2024-06-13T03:42:01+10:00")
}

pub fn subtract_time_day_boundary_test() {
  datetime.literal("2024-06-13T00:03:00Z")
  |> datetime.subtract(duration.minutes(13))
  |> datetime.to_string
  |> should.equal("2024-06-12T23:50:00Z")
}

pub fn subtract_time_multiple_day_boundary_test() {
  datetime.literal("2024-06-13T03:50:00Z")
  |> datetime.subtract(duration.days(3))
  |> datetime.subtract(duration.minutes(13))
  |> datetime.to_string
  |> should.equal("2024-06-10T03:37:00Z")
}

pub fn subtract_negative_time_test() {
  datetime.literal("2024-06-13T03:42:05Z")
  |> datetime.subtract(duration.seconds(-4))
  |> datetime.to_string
  |> should.equal("2024-06-13T03:42:09Z")
}

pub fn subtract_negative_time_day_boundary_test() {
  datetime.literal("2024-06-12T23:47:00.000Z")
  |> datetime.subtract(duration.minutes(-13))
  |> datetime.to_string
  |> should.equal("2024-06-13T00:00:00.000Z")
}

pub fn to_utc_from_utc_test() {
  datetime.literal("2024-06-12T03:47:00.000Z")
  |> datetime.to_string
  |> should.equal("2024-06-12T03:47:00.000Z")
}

pub fn to_utc_from_utc_leap_second_test() {
  datetime.literal("1972-06-30T23:59:60Z")
  |> datetime.to_utc
  |> datetime.to_string
  |> should.equal("1972-06-30T23:59:60Z")
}

pub fn to_utc_negative_offset_test() {
  datetime.literal("2024-06-12T03:47:00.000-04:00")
  |> datetime.to_utc
  |> datetime.to_string
  |> should.equal("2024-06-12T07:47:00.000Z")
}

pub fn to_utc_positive_offset_test() {
  datetime.literal("2024-06-12T08:52:00.000+05:05")
  |> datetime.to_utc
  |> datetime.to_string
  |> should.equal("2024-06-12T03:47:00.000Z")
}

pub fn to_utc_negative_day_boundary_test() {
  datetime.literal("2024-06-15T23:03:00.000-04:00")
  |> datetime.to_utc
  |> datetime.to_string
  |> should.equal("2024-06-16T03:03:00.000Z")
}

pub fn to_utc_positive_day_boundary_test() {
  datetime.literal("2024-06-16T01:03:00.000+03:00")
  |> datetime.to_utc
  |> datetime.to_string
  |> should.equal("2024-06-15T22:03:00.000Z")
}

pub fn to_local_test() {
  datetime.now_utc()
  |> datetime.to_current_local
  |> should.be_ok
}

pub fn to_local_error_test() {
  datetime.literal("2024-06-12T03:47:00.000Z")
  |> datetime.to_current_local
  |> should.be_error
}

pub fn to_offset_test() {
  datetime.literal("2024-06-12T03:47:00.000-04:00")
  |> datetime.to_offset(offset.literal("-01:00"))
  |> datetime.to_string
  |> should.equal("2024-06-12T06:47:00.000-01:00")
}

pub fn to_offset_different_sign_test() {
  datetime.literal("2024-06-12T12:47:00.000+05:00")
  |> datetime.to_offset(offset.literal("-01:00"))
  |> datetime.to_string
  |> should.equal("2024-06-12T06:47:00.000-01:00")
}

pub fn to_offset_negative_upper_day_boundary_test() {
  datetime.literal("2024-06-15T23:03:00.000-04:00")
  |> datetime.to_offset(offset.literal("-01:00"))
  |> datetime.to_string
  |> should.equal("2024-06-16T02:03:00.000-01:00")
}

pub fn to_offset_negative_lower_day_boundary_test() {
  datetime.literal("2024-06-15T01:03:00.000-04:00")
  |> datetime.to_offset(offset.literal("-08:00"))
  |> datetime.to_string
  |> should.equal("2024-06-14T21:03:00.000-08:00")
}

pub fn to_offset_positive_lower_day_boundary_test() {
  datetime.literal("2024-06-16T01:03:00.000+05:00")
  |> datetime.to_offset(offset.literal("+01:00"))
  |> datetime.to_string
  |> should.equal("2024-06-15T21:03:00.000+01:00")
}

pub fn to_offset_positive_upper_day_boundary_test() {
  datetime.literal("2024-06-16T22:03:00.000+01:00")
  |> datetime.to_offset(offset.literal("+08:00"))
  |> datetime.to_string
  |> should.equal("2024-06-17T05:03:00.000+08:00")
}

pub fn compare_eq_test() {
  datetime.literal("2024-06-12T23:47:00+09:05")
  |> datetime.compare(to: datetime.literal("2024-06-12T23:47:00+09:05"))
  |> should.equal(order.Eq)
}

pub fn compare_eq_different_offset_test() {
  datetime.literal("2024-06-12T14:47:00+01:00")
  |> datetime.compare(to: datetime.literal("2024-06-12T12:47:00-01:00"))
  |> should.equal(order.Eq)
}

pub fn compare_lt_date_test() {
  datetime.literal("2024-06-11T23:47:00Z")
  |> datetime.compare(to: datetime.literal("2024-06-12T23:47:00Z"))
  |> should.equal(order.Lt)
}

pub fn compare_lt_time_test() {
  datetime.literal("2024-06-12T23:47:00.003Z")
  |> datetime.compare(to: datetime.literal("2024-06-12T23:47:00.400Z"))
  |> should.equal(order.Lt)
}

pub fn compare_lt_date_different_offset_test() {
  datetime.literal("2024-05-11T23:47:00-04:00")
  |> datetime.compare(to: datetime.literal("2024-06-12T23:47:00+10:00"))
  |> should.equal(order.Lt)
}

pub fn compare_lt_time_different_offset_test() {
  datetime.literal("2024-06-12T03:47:00.003+10:00")
  |> datetime.compare(to: datetime.literal("2024-06-12T23:47:00.400+08:50"))
  |> should.equal(order.Lt)
}

pub fn compare_gt_date_test() {
  datetime.literal("2025-06-11T23:47:00Z")
  |> datetime.compare(to: datetime.literal("2024-06-12T23:47:00Z"))
  |> should.equal(order.Gt)
}

pub fn compare_gt_time_test() {
  datetime.literal("2024-06-12T23:47:00.003Z")
  |> datetime.compare(to: datetime.literal("2024-06-12T13:47:00.400Z"))
  |> should.equal(order.Gt)
}

pub fn compare_gt_date_different_offset_test() {
  datetime.literal("2025-06-21T23:47:00Z")
  |> datetime.compare(to: datetime.literal("2024-06-12T23:47:00-08:55"))
  |> should.equal(order.Gt)
}

pub fn compare_gt_time_different_offset_test() {
  datetime.literal("2024-06-12T23:47:00.003-02:00")
  |> datetime.compare(to: datetime.literal("2024-06-12T23:47:00.400Z"))
  |> should.equal(order.Gt)
}

pub fn from_unix_epoch_utc_test() {
  datetime.from_unix_utc(0)
  |> datetime.to_string
  |> should.equal("1970-01-01T00:00:00Z")
}

pub fn from_unix_utc_time_test() {
  datetime.from_unix_utc(1_718_629_191)
  |> datetime.to_string
  |> should.equal("2024-06-17T12:59:51Z")
}

pub fn from_unix_utc_time_milli_test() {
  datetime.from_unix_milli_utc(1_718_629_314_334)
  |> datetime.to_string
  |> should.equal("2024-06-17T13:01:54.334Z")
}

pub fn apply_offset_utc_test() {
  datetime.literal("2024-06-17T13:01:54.334-00:00")
  |> datetime.apply_offset
  |> naive_datetime.to_string
  |> should.equal("2024-06-17T13:01:54.334")
}

pub fn apply_negative_offset_test() {
  datetime.literal("2024-06-17T13:01:54.334-06:20")
  |> datetime.apply_offset
  |> naive_datetime.to_string
  |> should.equal("2024-06-17T19:21:54.334")
}

pub fn apply_positive_offset_test() {
  datetime.literal("2024-06-17T13:15:54.334+05:15")
  |> datetime.apply_offset
  |> naive_datetime.to_string
  |> should.equal("2024-06-17T08:00:54.334")
}

pub fn hour_contains_leap_second_test() {
  // datetime.literal("1972-06-30T23:59:60Z")
  // |> datetime.to_string
  // |> io.debug

  datetime.literal("1972-06-30T23:59:60Z")
  |> datetime.hour_contains_leap_second
  |> should.be_true
}
// pub fn hour_contains_leap_second_early_test() {
//   datetime.literal("1972-06-30T23:00:00Z")
//   |> datetime.hour_contains_leap_second
//   |> should.be_true
// }

// pub fn hour_contains_no_leap_second_test() {
//   datetime.literal("2024-06-17T23:59:60Z")
//   |> datetime.hour_contains_leap_second
//   |> should.be_false
// }

// pub fn hour_contains_leap_second_with_negative_offset_test() {
//   datetime.literal("1972-06-30T19:59:59-04:00")
//   |> datetime.hour_contains_leap_second
//   |> should.be_true
// }

// pub fn hour_zeros_contains_leap_second_with_negative_offset_test() {
//   datetime.literal("1972-06-30T19:00:00-04:00")
//   |> datetime.hour_contains_leap_second
//   |> should.be_true
// }

// pub fn hour_contains_leap_second_with_positive__offset_test() {
//   datetime.literal("1972-07-01T01:59:59+02:00")
//   |> datetime.hour_contains_leap_second
//   |> should.be_true
// }

// pub fn hour_zeros_contains_leap_second_with_positive__offset_test() {
//   datetime.literal("1972-07-01T01:00:00+02:00")
//   |> datetime.hour_contains_leap_second
//   |> should.be_true
// }

// pub fn hour_contains_no_leap_second_with_when_utc_time_does_test() {
//   datetime.literal("1972-06-30T23:59:60-04:00")
//   |> datetime.hour_contains_leap_second
//   |> should.be_false
// }
