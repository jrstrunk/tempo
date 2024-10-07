import gleam/dynamic
import gleam/order
import gleeunit
import gleeunit/should
import tempo
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

pub fn from_string_char_offset_test() {
  datetime.from_string("2024-06-13T13:42:11.354053-4")
  |> should.be_ok
  |> should.equal(datetime.literal("2024-06-13T13:42:11.354053-04:00"))
}

pub fn from_string_space_delim_test() {
  datetime.from_string("2024-06-13 13:42:11.354053-04:00")
  |> should.be_ok
  |> should.equal(datetime.literal("2024-06-13T13:42:11.354053-04:00"))
}

pub fn from_naive_string_test() {
  datetime.from_string("2024-06-13T13:42:11")
  |> should.equal(Error(tempo.DateTimeInvalidFormat))
}

pub fn from_date_out_of_bounds_string_test() {
  datetime.from_string("2024-06-54T13:42:11-04:00")
  |> should.equal(Error(tempo.DateOutOfBounds))
}

pub fn from_time_out_of_bounds_string_test() {
  datetime.from_string("2024-06-21T13:99:11-04:00")
  |> should.equal(Error(tempo.TimeOutOfBounds))
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

pub fn format_am_pad_test() {
  datetime.literal("2024-06-03T09:02:01.014920202-04:00")
  |> datetime.format(
    "YY YYYY M MM MMM MMMM D DD d dd ddd dddd H HH h hh a A m mm s ss SSS SSSS SSSSS Z ZZ",
  )
  |> should.equal(
    "24 2024 6 06 Jun June 3 03 1 Mo Mon Monday 9 09 9 09 am AM 2 02 1 01 014 014920 014920202 -04:00 -0400",
  )
}

pub fn format_am_no_pad_test() {
  datetime.literal("2001-12-25T22:52:21.914920202-04:00")
  |> datetime.format(
    "YY YYYY M MM MMM MMMM D DD d dd ddd dddd H HH h hh a A m mm s ss SSS SSSS SSSSS Z ZZ",
  )
  |> should.equal(
    "01 2001 12 12 Dec December 25 25 2 Tu Tue Tuesday 22 22 10 10 pm PM 52 52 21 21 914 914920 914920202 -04:00 -0400",
  )
}

pub fn format_escape_test() {
  datetime.literal("2024-06-13T13:42:11.314-04:00")
  |> datetime.format("[Hi Mom! It is:] YYYY-MM-DD")
  |> should.equal("Hi Mom! It is: 2024-06-13")
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
  datetime.literal("2024-06-21T03:47:00.000Z")
  |> datetime.to_string
  |> should.equal("2024-06-21T03:47:00.000Z")
}

pub fn to_utc_negative_offset_test() {
  datetime.literal("2024-06-21T03:47:00.000-04:00")
  |> datetime.to_utc
  |> datetime.to_string
  |> should.equal("2024-06-21T07:47:00.000Z")
}

pub fn to_utc_positive_offset_test() {
  datetime.literal("2024-06-21T08:52:00.000+05:05")
  |> datetime.to_utc
  |> datetime.to_string
  |> should.equal("2024-06-21T03:47:00.000Z")
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
  datetime.literal("2024-06-21T03:47:00.000Z")
  |> datetime.to_local_time
  // Just should not crash or anything, not really muct to validate
}

pub fn to_offset_test() {
  datetime.literal("2024-06-21T03:47:00.000-04:00")
  |> datetime.to_offset(offset.literal("-01:00"))
  |> datetime.to_string
  |> should.equal("2024-06-21T06:47:00.000-01:00")
}

pub fn to_offset_different_sign_test() {
  datetime.literal("2024-06-21T12:47:00.000+05:00")
  |> datetime.to_offset(offset.literal("-01:00"))
  |> datetime.to_string
  |> should.equal("2024-06-21T06:47:00.000-01:00")
}

pub fn to_offset_large_different_sign_test() {
  datetime.literal("2024-06-21T05:36:11.195-04:00")
  |> datetime.to_offset(offset.literal("+10:00"))
  |> datetime.to_string
  |> should.equal("2024-06-21T19:36:11.195+10:00")
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
  datetime.literal("2024-06-21T23:47:00+09:05")
  |> datetime.compare(to: datetime.literal("2024-06-21T23:47:00+09:05"))
  |> should.equal(order.Eq)
}

pub fn compare_eq_different_offset_test() {
  datetime.literal("2024-06-21T14:47:00+01:00")
  |> datetime.compare(to: datetime.literal("2024-06-21T12:47:00-01:00"))
  |> should.equal(order.Eq)
}

pub fn compare_lt_date_test() {
  datetime.literal("2024-06-11T23:47:00Z")
  |> datetime.compare(to: datetime.literal("2024-06-12T23:47:00Z"))
  |> should.equal(order.Lt)
}

pub fn compare_lt_time_test() {
  datetime.literal("2024-06-21T23:47:00.003Z")
  |> datetime.compare(to: datetime.literal("2024-06-21T23:47:00.400Z"))
  |> should.equal(order.Lt)
}

pub fn compare_lt_date_different_offset_test() {
  datetime.literal("2024-05-11T23:47:00-04:00")
  |> datetime.compare(to: datetime.literal("2024-06-12T23:47:00+10:00"))
  |> should.equal(order.Lt)
}

pub fn compare_lt_time_different_offset_test() {
  datetime.literal("2024-06-21T03:47:00.003+10:00")
  |> datetime.compare(to: datetime.literal("2024-06-21T23:47:00.400+08:50"))
  |> should.equal(order.Lt)
}

pub fn compare_gt_date_test() {
  datetime.literal("2025-06-11T23:47:00Z")
  |> datetime.compare(to: datetime.literal("2024-06-12T23:47:00Z"))
  |> should.equal(order.Gt)
}

pub fn compare_gt_time_test() {
  datetime.literal("2024-06-21T23:47:00.003Z")
  |> datetime.compare(to: datetime.literal("2024-06-21T13:47:00.400Z"))
  |> should.equal(order.Gt)
}

pub fn compare_gt_date_different_offset_test() {
  datetime.literal("2025-06-21T23:47:00Z")
  |> datetime.compare(to: datetime.literal("2024-06-12T23:47:00-08:55"))
  |> should.equal(order.Gt)
}

pub fn compare_gt_time_different_offset_test() {
  datetime.literal("2024-06-21T23:47:00.003-02:00")
  |> datetime.compare(to: datetime.literal("2024-06-21T23:47:00.400Z"))
  |> should.equal(order.Gt)
}

pub fn from_unix_epoch_utc_test() {
  datetime.from_unix_utc(0)
  |> datetime.to_string
  |> should.equal("1970-01-01T00:00:00Z")
}

pub fn to_unix_epoch_utc_test() {
  datetime.literal("1970-01-01T00:00:00Z")
  |> datetime.to_unix_utc
  |> should.equal(0)
}

pub fn from_unix_utc_time_test() {
  datetime.from_unix_utc(1_718_629_191)
  |> datetime.to_string
  |> should.equal("2024-06-17T12:59:51Z")
}

pub fn to_unix_utc_time_test() {
  datetime.literal("2024-06-17T12:59:51Z")
  |> datetime.to_unix_utc
  |> should.equal(1_718_629_191)
}

pub fn from_unix_utc_time_milli_test() {
  datetime.from_unix_milli_utc(1_718_629_314_334)
  |> datetime.to_string
  |> should.equal("2024-06-17T13:01:54.334Z")
}

pub fn to_unix_utc_time_milli_test() {
  datetime.literal("2024-06-17T13:01:54.334Z")
  |> datetime.to_unix_milli_utc
  |> should.equal(1_718_629_314_334)
}

pub fn from_unix_utc_time_micro_test() {
  datetime.from_unix_micro_utc(1_718_629_314_334_734)
  |> datetime.to_string
  |> should.equal("2024-06-17T13:01:54.334734Z")
}

pub fn to_unix_utc_time_micro_test() {
  datetime.literal("2024-06-17T13:01:54.334734Z")
  |> datetime.to_unix_micro_utc
  |> should.equal(1_718_629_314_334_734)
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

pub fn now_test() {
  datetime.now_local()
  datetime.now_utc()
  datetime.now_text()
  // Just should not crash or anything, not really muct to validate
}

pub fn to_second_precision_test() {
  datetime.literal("2024-06-13T13:42:11.195423Z")
  |> datetime.to_second_precision
  |> datetime.to_string
  |> should.equal("2024-06-13T13:42:11Z")
}

pub fn to_milli_precision_test() {
  datetime.literal("2024-06-13T13:42:11.195423Z")
  |> datetime.to_milli_precision
  |> datetime.to_string
  |> should.equal("2024-06-13T13:42:11.195Z")
}

pub fn to_micro_precision_test() {
  datetime.literal("2024-06-13T13:42:11.195423534Z")
  |> datetime.to_micro_precision
  |> datetime.to_string
  |> should.equal("2024-06-13T13:42:11.195423Z")
}

pub fn to_nano_precision_test() {
  datetime.literal("2024-06-13T13:42:11.195Z")
  |> datetime.to_nano_precision
  |> datetime.to_string
  |> should.equal("2024-06-13T13:42:11.195000000Z")
}

pub fn from_dynamic_string_test() {
  dynamic.from("2024-06-13T13:42:11.195Z")
  |> datetime.from_dynamic_string
  |> should.be_ok
  |> should.equal(datetime.literal("2024-06-13T13:42:11.195Z"))
}

pub fn from_dynamic_string_int_test() {
  dynamic.from("153")
  |> datetime.from_dynamic_string
  |> should.equal(
    Error([
      dynamic.DecodeError(
        expected: "tempo.DateTime",
        found: "Invalid format: 153",
        path: [],
      ),
    ]),
  )
}

pub fn from_dynamic_string_bad_format_test() {
  dynamic.from("24-06-13,13:42:11.195")
  |> datetime.from_dynamic_string
  |> should.equal(
    Error([
      dynamic.DecodeError(
        expected: "tempo.DateTime",
        found: "Invalid format: 24-06-13,13:42:11.195",
        path: [],
      ),
    ]),
  )
}

pub fn from_dynamic_string_bad_values_test() {
  dynamic.from("2024-06-21T13:99:11.195Z")
  |> datetime.from_dynamic_string
  |> should.equal(
    Error([
      dynamic.DecodeError(
        expected: "tempo.DateTime",
        found: "Time out of bounds: 2024-06-21T13:99:11.195Z",
        path: [],
      ),
    ]),
  )
}

pub fn from_dynamic_unix_utc_test() {
  dynamic.from(1_718_629_314)
  |> datetime.from_dynamic_unix_utc
  |> should.be_ok
  |> should.equal(datetime.literal("2024-06-17T13:01:54Z"))
}

pub fn from_dynamic_unix_utc_error_test() {
  dynamic.from("hello")
  |> datetime.from_dynamic_unix_utc
  |> should.be_error
}

pub fn from_dynamic_unix_milli_utc_test() {
  dynamic.from(1_718_629_314_334)
  |> datetime.from_dynamic_unix_milli_utc
  |> should.be_ok
  |> should.equal(datetime.literal("2024-06-17T13:01:54.334Z"))
}

pub fn from_dynamic_unix_milli_utc_error_test() {
  dynamic.from("hello")
  |> datetime.from_dynamic_unix_milli_utc
  |> should.be_error
}

pub fn from_dynamic_unix_micro_utc_test() {
  dynamic.from(1_718_629_314_334_734)
  |> datetime.from_dynamic_unix_micro_utc
  |> should.be_ok
  |> should.equal(datetime.literal("2024-06-17T13:01:54.334734Z"))
}

pub fn from_dynamic_unix_micro_utc_error_test() {
  dynamic.from("hello")
  |> datetime.from_dynamic_unix_micro_utc
  |> should.be_error
}
