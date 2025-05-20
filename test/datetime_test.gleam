import gleam/dynamic
import gleam/dynamic/decode
import gleam/io
import gleam/order
import gleam/time/duration as dur
import gleam/time/timestamp
import gleeunit/should
import tempo
import tempo/date
import tempo/datetime
import tempo/duration
import tempo/error as tempo_error
import tempo/instant
import tempo/naive_datetime
import tempo/offset
import tempo/time

pub fn main() {
  instant.now()
  |> instant.as_utc_datetime
  |> datetime.to_timestamp
  |> timestamp.to_rfc3339(dur.seconds(0))
  |> io.debug
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
  |> should.equal(
    Error(tempo_error.DateTimeInvalidFormat("2024-06-13T13:42:11")),
  )
}

pub fn from_date_out_of_bounds_string_test() {
  datetime.from_string("2024-06-54T13:42:11-04:00")
  |> should.equal(
    Error(tempo_error.DateTimeDateParseError(
      "2024-06-54T13:42:11-04:00",
      tempo_error.DateOutOfBounds(
        "2024-06-54",
        tempo_error.DateDayOutOfBounds("Jun 54"),
      ),
    )),
  )
}

pub fn from_time_out_of_bounds_string_test() {
  datetime.from_string("2024-06-21T13:99:11-04:00")
  |> should.equal(
    Error(tempo_error.DateTimeTimeParseError(
      "2024-06-21T13:99:11-04:00",
      tempo_error.TimeOutOfBounds(
        "13:99:11",
        tempo_error.TimeMinuteOutOfBounds("13:99:11.000000"),
      ),
    )),
  )
}

pub fn parse_isoish_test() {
  datetime.parse(
    "2024/06/08, 13:42:11, -04:00",
    tempo.Custom("YYYY/MM/DD, HH:mm:ss, Z"),
  )
  |> should.equal(Ok(datetime.literal("2024-06-08T13:42:11-04")))
}

pub fn parse_long_name_test() {
  datetime.parse(
    "January 13, 2024. 3:42:11Z",
    tempo.Custom("MMMM DD, YYYY. H:mm:ssz"),
  )
  |> should.equal(Ok(datetime.literal("2024-01-13T03:42:11Z")))
}

pub fn parse_short_name_test() {
  datetime.parse(
    "Jan 3, 1998. -04:00 13:42:11",
    tempo.Custom("MMM D, YYYY. Z HH:mm:ss"),
  )
  |> should.equal(Ok(datetime.literal("1998-01-03T13:42:11-04")))
}

pub fn parse_early_am_test() {
  datetime.parse("2024 11 13 12 2 am Z", tempo.Custom("YYYY M D h m a z"))
  |> should.equal(Ok(datetime.literal("2024-11-13T00:02:00Z")))
}

pub fn parse_late_am_test() {
  datetime.parse(
    "2024 11 13 02:42:12 AM -0400",
    tempo.Custom("YYYY M D hh:mm:ss A ZZ"),
  )
  |> should.equal(Ok(datetime.literal("2024-11-13T02:42:12-04")))
}

pub fn parse_early_pm_test() {
  datetime.parse("2024 11 13 12:42:4 PM Z", tempo.Custom("YYYY M D h:mm:s A z"))
  |> should.equal(Ok(datetime.literal("2024-11-13T12:42:04Z")))
}

pub fn parse_late_pm_test() {
  datetime.parse("2024 11 13 2 42 pm -04", tempo.Custom("YYYY M D h m a z"))
  |> should.equal(Ok(datetime.literal("2024-11-13T14:42:00-04")))
}

pub fn parse_escape_test() {
  datetime.parse(
    "Hello! It is: 2024/06/08, 13:42:11, -04:00",
    tempo.Custom("[Hello! It is:] YYYY/MM/DD, HH:mm:ss, Z"),
  )
  |> should.equal(Ok(datetime.literal("2024-06-08T13:42:11-04")))
}

pub fn to_string_test() {
  datetime.literal("20240613T134211.314-04")
  |> datetime.to_string
  |> should.equal("2024-06-13T13:42:11.314000-04:00")
}

pub fn date_to_string_test() {
  datetime.literal("20240613T00:00:00Z")
  |> datetime.to_string
  |> should.equal("2024-06-13T00:00:00.000000Z")
}

pub fn format_pad_test() {
  datetime.literal("2024-06-03T09:02:01.014920-04:00")
  |> datetime.format(tempo.Custom(
    "YY YYYY M MM MMM MMMM D DD d dd ddd dddd H HH h hh a A m mm s ss SSS SSSS Z ZZ z",
  ))
  |> should.equal(
    "24 2024 6 06 Jun June 3 03 1 Mo Mon Monday 9 09 9 09 am AM 2 02 1 01 014 014920 -04:00 -0400 -04",
  )
}

pub fn format_no_pad_test() {
  datetime.literal("2001-12-25T22:52:21.914920-00:00")
  |> datetime.format(tempo.Custom(
    "YY YYYY M MM MMM MMMM D DD d dd ddd dddd H HH h hh a A m mm s ss SSS SSSS Z ZZ z",
  ))
  |> should.equal(
    "01 2001 12 12 Dec December 25 25 2 Tu Tue Tuesday 22 22 10 10 pm PM 52 52 21 21 914 914920 +00:00 +0000 Z",
  )
}

pub fn format_parenthesis_test() {
  datetime.literal("2024-06-21T13:42:11.314-04:00")
  |> datetime.format(tempo.Custom("ddd @ h:mm A (z)"))
  |> should.equal("Fri @ 1:42 PM (-04)")
}

pub fn format_pm_test() {
  datetime.literal("2024-06-21T12:42:11.314-04:00")
  |> datetime.format(tempo.Custom("h:mm a"))
  |> should.equal("12:42 pm")
}

pub fn format_padded_pm_test() {
  datetime.literal("2024-06-21T15:47:00.000-04:00")
  |> datetime.format(tempo.Custom("hh:mm:ss a"))
  |> should.equal("03:47:00 pm")
}

pub fn format_am_test() {
  datetime.literal("2024-06-21T00:42:11.314-04:00")
  |> datetime.format(tempo.Custom("h:mm a"))
  |> should.equal("12:42 am")
}

pub fn format_padded_am_test() {
  datetime.literal("2024-06-21T06:42:11.314-04:00")
  |> datetime.format(tempo.Custom("hh:mm:ss a"))
  |> should.equal("06:42:11 am")
}

pub fn format_escape_test() {
  datetime.literal("2024-06-13T13:42:11.314-04:00")
  |> datetime.format(tempo.Custom("[Hi Mom! It is:] YYYY-MM-DD"))
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
  |> should.equal("2024-06-13T03:42:05.000000+10:00")
}

pub fn add_time_day_boundary_test() {
  datetime.literal("2024-06-13T23:50:10Z")
  |> datetime.add(duration.minutes(13))
  |> datetime.to_string
  |> should.equal("2024-06-14T00:03:10.000000Z")
}

pub fn add_time_multiple_day_boundary_test() {
  datetime.literal("2024-06-13T03:50:10Z")
  |> datetime.add(duration.days(3))
  |> datetime.add(duration.minutes(13))
  |> datetime.to_string
  |> should.equal("2024-06-16T04:03:10.000000Z")
}

pub fn add_negative_time_test() {
  datetime.literal("2024-06-13T03:42:05+10:00")
  |> datetime.add(duration.seconds(-4))
  |> datetime.to_string
  |> should.equal("2024-06-13T03:42:01.000000+10:00")
}

pub fn add_negative_time_day_boundary_test() {
  datetime.literal("2024-06-13T00:03:10Z")
  |> datetime.add(duration.minutes(-13))
  |> datetime.to_string
  |> should.equal("2024-06-12T23:50:10.000000Z")
}

pub fn subtract_time_test() {
  datetime.literal("2024-06-13T03:42:05+10:00")
  |> datetime.subtract(duration.seconds(4))
  |> datetime.to_string
  |> should.equal("2024-06-13T03:42:01.000000+10:00")
}

pub fn subtract_time_day_boundary_test() {
  datetime.literal("2024-06-13T00:03:00Z")
  |> datetime.subtract(duration.minutes(13))
  |> datetime.to_string
  |> should.equal("2024-06-12T23:50:00.000000Z")
}

pub fn subtract_time_multiple_day_boundary_test() {
  datetime.literal("2024-06-13T03:50:00Z")
  |> datetime.subtract(duration.days(3))
  |> datetime.subtract(duration.minutes(13))
  |> datetime.to_string
  |> should.equal("2024-06-10T03:37:00.000000Z")
}

pub fn subtract_negative_time_test() {
  datetime.literal("2024-06-13T03:42:05Z")
  |> datetime.subtract(duration.seconds(-4))
  |> datetime.to_string
  |> should.equal("2024-06-13T03:42:09.000000Z")
}

pub fn subtract_negative_time_day_boundary_test() {
  datetime.literal("2024-06-12T23:47:00.000Z")
  |> datetime.subtract(duration.minutes(-13))
  |> datetime.to_string
  |> should.equal("2024-06-13T00:00:00.000000Z")
}

pub fn to_utc_from_utc_test() {
  datetime.literal("2024-06-21T03:47:00.000000Z")
  |> datetime.to_string
  |> should.equal("2024-06-21T03:47:00.000000Z")
}

pub fn to_utc_negative_offset_test() {
  datetime.literal("2024-06-21T03:47:00.000-04:00")
  |> datetime.to_utc
  |> datetime.to_string
  |> should.equal("2024-06-21T07:47:00.000000Z")
}

pub fn to_utc_positive_offset_test() {
  datetime.literal("2024-06-21T08:52:00.000+05:05")
  |> datetime.to_utc
  |> datetime.to_string
  |> should.equal("2024-06-21T03:47:00.000000Z")
}

pub fn to_utc_negative_day_boundary_test() {
  datetime.literal("2024-06-15T23:03:00.000-04:00")
  |> datetime.to_utc
  |> datetime.to_string
  |> should.equal("2024-06-16T03:03:00.000000Z")
}

pub fn to_utc_positive_day_boundary_test() {
  datetime.literal("2024-06-16T01:03:00.000+03:00")
  |> datetime.to_utc
  |> datetime.to_string
  |> should.equal("2024-06-15T22:03:00.000000Z")
}

pub fn to_offset_test() {
  datetime.literal("2024-06-21T03:47:00.000-04:00")
  |> datetime.to_offset(offset.literal("-01:00"))
  |> datetime.to_string
  |> should.equal("2024-06-21T06:47:00.000000-01:00")
}

pub fn to_offset_different_sign_test() {
  datetime.literal("2024-06-21T12:47:00.000+05:00")
  |> datetime.to_offset(offset.literal("-01:00"))
  |> datetime.to_string
  |> should.equal("2024-06-21T06:47:00.000000-01:00")
}

pub fn to_offset_large_different_sign_test() {
  datetime.literal("2024-06-21T05:36:11.195-04:00")
  |> datetime.to_offset(offset.literal("+10:00"))
  |> datetime.to_string
  |> should.equal("2024-06-21T19:36:11.195000+10:00")
}

pub fn to_offset_negative_upper_day_boundary_test() {
  datetime.literal("2024-06-15T23:03:00.000-04:00")
  |> datetime.to_offset(offset.literal("-01:00"))
  |> datetime.to_string
  |> should.equal("2024-06-16T02:03:00.000000-01:00")
}

pub fn to_offset_negative_lower_day_boundary_test() {
  datetime.literal("2024-06-15T01:03:00.000-04:00")
  |> datetime.to_offset(offset.literal("-08:00"))
  |> datetime.to_string
  |> should.equal("2024-06-14T21:03:00.000000-08:00")
}

pub fn to_offset_positive_lower_day_boundary_test() {
  datetime.literal("2024-06-16T01:03:00.000+05:00")
  |> datetime.to_offset(offset.literal("+01:00"))
  |> datetime.to_string
  |> should.equal("2024-06-15T21:03:00.000000+01:00")
}

pub fn to_offset_positive_upper_day_boundary_test() {
  datetime.literal("2024-06-16T22:03:00.000+01:00")
  |> datetime.to_offset(offset.literal("+08:00"))
  |> datetime.to_string
  |> should.equal("2024-06-17T05:03:00.000000+08:00")
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
  datetime.from_unix_seconds(0)
  |> datetime.to_string
  |> should.equal("1970-01-01T00:00:00.000000Z")
}

pub fn to_unix_epoch_utc_test() {
  datetime.literal("1970-01-01T00:00:00.000000Z")
  |> datetime.to_unix_seconds
  |> should.equal(0)
}

pub fn from_unix_seconds_time_test() {
  datetime.from_unix_seconds(1_718_629_191)
  |> datetime.to_string
  |> should.equal("2024-06-17T12:59:51.000000Z")
}

pub fn to_unix_seconds_time_test() {
  datetime.literal("2024-06-17T12:59:51.000000Z")
  |> datetime.to_unix_seconds
  |> should.equal(1_718_629_191)
}

pub fn from_unix_seconds_time_milli_test() {
  datetime.from_unix_milli(1_718_629_314_334)
  |> datetime.to_string
  |> should.equal("2024-06-17T13:01:54.334000Z")
}

pub fn to_unix_seconds_time_milli_test() {
  datetime.literal("2024-06-17T13:01:54.334Z")
  |> datetime.to_unix_milli
  |> should.equal(1_718_629_314_334)
}

pub fn from_unix_seconds_time_micro_test() {
  datetime.from_unix_micro(1_718_629_314_334_734)
  |> datetime.to_string
  |> should.equal("2024-06-17T13:01:54.334734Z")
}

pub fn to_unix_seconds_time_micro_test() {
  datetime.literal("2024-06-17T13:01:54.334734Z")
  |> datetime.to_unix_micro
  |> should.equal(1_718_629_314_334_734)
}

pub fn apply_offset_utc_test() {
  datetime.literal("2024-06-17T13:01:54.334-00:00")
  |> datetime.apply_offset
  |> naive_datetime.to_string
  |> should.equal("2024-06-17T13:01:54.334000")
}

pub fn apply_negative_offset_test() {
  datetime.literal("2024-06-17T13:01:54.334-06:20")
  |> datetime.apply_offset
  |> naive_datetime.to_string
  |> should.equal("2024-06-17T19:21:54.334000")
}

pub fn apply_positive_offset_test() {
  datetime.literal("2024-06-17T13:15:54.334+05:15")
  |> datetime.apply_offset
  |> naive_datetime.to_string
  |> should.equal("2024-06-17T08:00:54.334000")
}

pub fn from_dynamic_string_test() {
  dynamic.string("2024-06-13T13:42:11.195Z")
  |> datetime.from_dynamic_string
  |> should.be_ok
  |> should.equal(datetime.literal("2024-06-13T13:42:11.195Z"))
}

pub fn from_dynamic_string_int_test() {
  dynamic.string("153")
  |> datetime.from_dynamic_string
  |> should.equal(
    Error([
      decode.DecodeError(expected: "tempo.DateTime", found: "153", path: []),
    ]),
  )
}

pub fn from_dynamic_string_bad_format_test() {
  dynamic.string("24-06-13,13:42:11.195")
  |> datetime.from_dynamic_string
  |> should.equal(
    Error([
      decode.DecodeError(
        expected: "tempo.DateTime",
        found: "24-06-13,13:42:11.195",
        path: [],
      ),
    ]),
  )
}

pub fn from_dynamic_string_bad_values_test() {
  dynamic.string("2024-06-21T13:99:11.195Z")
  |> datetime.from_dynamic_string
  |> should.equal(
    Error([
      decode.DecodeError(
        expected: "tempo.DateTime",
        found: "2024-06-21T13:99:11.195Z",
        path: [],
      ),
    ]),
  )
}

pub fn from_dynamic_unix_utc_test() {
  dynamic.int(1_718_629_314)
  |> datetime.from_dynamic_unix_utc
  |> should.be_ok
  |> should.equal(datetime.literal("2024-06-17T13:01:54Z"))
}

pub fn from_dynamic_unix_utc_error_test() {
  dynamic.string("hello")
  |> datetime.from_dynamic_unix_utc
  |> should.be_error
}

pub fn from_dynamic_unix_milli_utc_test() {
  dynamic.int(1_718_629_314_334)
  |> datetime.from_dynamic_unix_milli_utc
  |> should.be_ok
  |> should.equal(datetime.literal("2024-06-17T13:01:54.334Z"))
}

pub fn from_dynamic_unix_milli_utc_error_test() {
  dynamic.string("hello")
  |> datetime.from_dynamic_unix_milli_utc
  |> should.be_error
}

pub fn from_dynamic_unix_micro_utc_test() {
  dynamic.int(1_718_629_314_334_734)
  |> datetime.from_dynamic_unix_micro_utc
  |> should.be_ok
  |> should.equal(datetime.literal("2024-06-17T13:01:54.334734Z"))
}

pub fn from_dynamic_unix_micro_utc_error_test() {
  dynamic.string("hello")
  |> datetime.from_dynamic_unix_micro_utc
  |> should.be_error
}

pub fn datetime_difference_no_test() {
  datetime.literal("2024-06-21T23:17:00Z")
  |> datetime.difference(from: datetime.literal("2024-06-21T23:17:00Z"))
  |> should.equal(duration.microseconds(0))
}

pub fn datetime_difference_time_test() {
  datetime.literal("2024-06-21T23:17:00Z")
  |> datetime.difference(to: datetime.literal("2024-06-21T23:18:05Z"))
  |> duration.as_seconds
  |> should.equal(65)
}

pub fn datetime_difference_offset_test() {
  datetime.literal("2024-06-21T23:17:00Z")
  |> datetime.difference(to: datetime.literal("2024-06-21T23:17:00-03:00"))
  |> duration.as_hours
  |> should.equal(3)
}

pub fn datetime_differnce_same_utc_time_offset_test() {
  datetime.literal("2024-06-21T23:17:00Z")
  |> datetime.difference(from: datetime.literal("2024-06-21T20:17:00-03:00"))
  |> duration.as_hours
  |> should.equal(0)
}

pub fn datetime_difference_negative_test() {
  datetime.literal("2024-06-21T23:18:00Z")
  |> datetime.difference(to: datetime.literal("2024-06-21T23:16:00Z"))
  |> duration.as_minutes
  |> should.equal(-2)
}

pub fn to_string_lossless_equality_test() {
  let assert Ok(t) = time.new_micro(23, 17, 7, 3752)
  let dt = datetime.new(date.literal("2024-06-21"), t, offset.literal("+05:00"))

  dt
  |> datetime.to_string
  |> dynamic.string
  |> datetime.from_dynamic_string
  |> should.equal(Ok(dt))
}

pub fn difference_dec_test() {
  let test_datetime = datetime.literal("2024-12-11T08:55:32.424420Z")
  datetime.difference(test_datetime, test_datetime)
  |> duration.as_seconds
  |> should.equal(0)
}

pub fn date_period_dec_test() {
  let test_date = date.literal("2024-12-11")

  date.difference(test_date, test_date) |> should.equal(0)
}

pub fn format_http_local_test() {
  datetime.literal("2024-12-26T13:02:01-04:30")
  |> datetime.format(tempo.HTTP)
  |> should.equal("Thu, 26 Dec 2024 17:32:01 GMT")
}

pub fn format_http_utc_test() {
  datetime.literal("2025-01-05T13:02:01Z")
  |> datetime.format(tempo.HTTP)
  |> should.equal("Sun, 05 Jan 2025 13:02:01 GMT")
}

pub fn timestamp_round_trip_test() {
  let ref = datetime.literal("2024-06-21T13:42:11.195Z")

  datetime.to_timestamp(ref)
  |> datetime.from_timestamp
  |> should.equal(ref)
}

pub fn datetime_format_round_trip_test() {
  datetime.literal("2025-03-09T14:53:45Z")
  |> datetime.format(tempo.ISO8601Seconds)
  |> datetime.parse(in: tempo.ISO8601Seconds)
  |> should.equal(Ok(datetime.literal("2025-03-09T14:53:45Z")))
}

pub fn datetime_milli_format_round_trip_test() {
  datetime.literal("2025-03-09T14:53:45.534Z")
  |> datetime.format(tempo.ISO8601Milli)
  |> datetime.parse(in: tempo.ISO8601Milli)
  |> should.equal(Ok(datetime.literal("2025-03-09T14:53:45.534Z")))
}

pub fn datetime_micro_format_round_trip_test() {
  datetime.literal("2025-03-09T14:53:45.000342Z")
  |> datetime.format(tempo.ISO8601Micro)
  |> datetime.parse(in: tempo.ISO8601Micro)
  |> should.equal(Ok(datetime.literal("2025-03-09T14:53:45.000342Z")))
}

pub fn datetime_http_format_round_trip_test() {
  datetime.literal("2025-03-09T14:53:45.000Z")
  |> datetime.format(tempo.HTTP)
  |> datetime.parse(in: tempo.HTTP)
  |> should.equal(Ok(datetime.literal("2025-03-09T14:53:45.000Z")))
}

pub fn datetime_format_custom_round_trip_test() {
  datetime.literal("2025-03-09T00:00:00.000Z")
  |> datetime.format(tempo.Custom("YYYY-MM-DD[T]HH:mm:ss.SSSZ"))
  |> datetime.parse(in: tempo.Custom("YYYY-MM-DD[T]HH:mm:ss.SSSZ"))
  |> should.equal(Ok(datetime.literal("2025-03-09T00:00:00.000Z")))
}

pub fn datetime_parse_http_malformed_test() {
  datetime.parse("Thu, 26 Dec 2024 17:32:01 -02:00", in: tempo.HTTP)
  |> should.equal(
    Error(tempo_error.DateTimeInvalidFormat("Unable to parse directive GMT")),
  )
}

pub fn datetime_parse_custom_malformed_test() {
  datetime.parse(
    "2025-03-09T14:53:45Z",
    in: tempo.Custom("YYYY-MM-DDTHH:mm:ssZ[UTC]"),
  )
  |> should.equal(
    Error(tempo_error.DateTimeInvalidFormat(
      "Input does not match expected escape sequence \"UTC\"",
    )),
  )
}
