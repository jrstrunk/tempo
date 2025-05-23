import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import tempo
import tempo/date
import tempo/offset
import tempo/time

pub fn main() {
  date.current_local() |> echo
  date.current_utc() |> echo
}

pub fn parse_any_all_test() {
  tempo.parse_any("2024/06/22 at 13:42:11.314 in +05:00")
  |> should.equal(#(
    Some(date.literal("2024-06-22")),
    Some(time.literal("13:42:11.314")),
    Some(offset.literal("+05:00")),
  ))
}

pub fn parse_any_american_test() {
  tempo.parse_any("06/22/2024 at 1:42:11 PM in -04:00")
  |> should.equal(#(
    Some(date.literal("2024-06-22")),
    Some(time.literal("13:42:11")),
    Some(offset.literal("-04:00")),
  ))
}

pub fn parse_any_z_upper_offset_test() {
  tempo.parse_any("12-10-2024T00:00:00Z")
  |> should.equal(#(
    Some(date.literal("2024-12-10")),
    Some(time.literal("00:00:00")),
    Some(offset.literal("+00:00")),
  ))
}

pub fn parse_any_z_lower_offset_test() {
  tempo.parse_any("12/10/2024 00:00:00 z")
  |> should.equal(#(
    Some(date.literal("2024-12-10")),
    Some(time.literal("00:00:00")),
    Some(offset.literal("+00:00")),
  ))
}

pub fn parse_any_zeros_test() {
  tempo.parse_any("12-10-2024T00:00:00+00:00")
  |> should.equal(#(
    Some(date.literal("2024-12-10")),
    Some(time.literal("00:00:00")),
    Some(offset.literal("+00:00")),
  ))
}

pub fn parse_any_date_test() {
  tempo.parse_any("2024/06/22")
  |> should.equal(#(Some(date.literal("2024-06-22")), None, None))
}

pub fn parse_any_date_single_digit_test() {
  tempo.parse_any("2024/6/2")
  |> should.equal(#(Some(date.literal("2024-06-02")), None, None))
}

pub fn parse_any_date_single_digit_us_test() {
  tempo.parse_any("7/8/2024")
  |> should.equal(#(Some(date.literal("2024-07-08")), None, None))
}

pub fn parse_any_date_ordinal_test() {
  tempo.parse_any("June 21st, 2024")
  |> should.equal(#(Some(date.literal("2024-06-21")), None, None))
}

pub fn parse_any_date_single_digit_ordinal_test() {
  tempo.parse_any("July 8th, 2024")
  |> should.equal(#(Some(date.literal("2024-07-08")), None, None))
}

pub fn parse_any_time_test() {
  tempo.parse_any("13:42:11")
  |> should.equal(#(None, Some(time.literal("13:42:11")), None))
}

pub fn parse_any_time_am_test() {
  tempo.parse_any("1:42:11 AM")
  |> should.equal(#(None, Some(time.literal("01:42:11")), None))
}

pub fn parse_any_time_pm_test() {
  tempo.parse_any("1:42:11 PM")
  |> should.equal(#(None, Some(time.literal("13:42:11")), None))
}

pub fn parse_any_time_hour_min_test() {
  tempo.parse_any("01:42 PM")
  |> should.equal(#(None, Some(time.literal("13:42:00")), None))
}

pub fn parse_any_offset_test() {
  tempo.parse_any("+05:00")
  |> should.equal(#(None, None, Some(offset.literal("+05:00"))))
}

pub fn parse_any_bad_test() {
  tempo.parse_any("20240422012333")
  |> should.equal(#(None, None, None))
}

pub fn parse_any_squished_test() {
  tempo.parse_any("20240622_134211")
  |> should.equal(#(
    Some(date.literal("2024-06-22")),
    Some(time.literal("13:42:11")),
    None,
  ))
}

pub fn parse_any_squished_american_test() {
  tempo.parse_any("06222024_134211")
  |> should.equal(#(
    Some(date.literal("2024-06-22")),
    Some(time.literal("13:42:11")),
    None,
  ))
}

pub fn parse_any_dots_test() {
  tempo.parse_any("2024.06.22")
  |> should.equal(#(Some(date.literal("2024.06.22")), None, None))
}

pub fn parse_any_written_date_test() {
  tempo.parse_any("June 21, 2024")
  |> should.equal(#(Some(date.literal("2024-06-21")), None, None))
}

pub fn parse_any_written_short_date_test() {
  tempo.parse_any("Dec 25, 2024 at 6:00 AM")
  |> should.equal(#(
    Some(date.literal("2024-12-25")),
    Some(time.literal("06:00:00")),
    None,
  ))
}

pub fn parse_any_nanosecond_test() {
  tempo.parse_any("2025-02-11T06:00:00.123456789Z")
  |> should.equal(#(
    Some(date.literal("2025-02-11")),
    Some(time.literal("06:00:00.123456")),
    Some(offset.literal("Z")),
  ))
}

pub fn parse_any_offset_condensed_test() {
  tempo.parse_any("2025-02-11T06:00:00-05")
  |> should.equal(#(
    Some(date.literal("2025-02-11")),
    Some(time.literal("06:00:00")),
    Some(offset.literal("-05:00")),
  ))
}

pub fn format_utc_iso8601seconds_test() {
  tempo.format_utc(tempo.ISO8601Seconds)
  |> string.to_graphemes
  |> list.reverse
  |> list.take(1)
  |> should.equal(["Z"])
}

pub fn format_utc_iso8601millis_test() {
  tempo.format_utc(tempo.ISO8601Milli)
  |> string.to_graphemes
  |> list.reverse
  |> list.take(1)
  |> should.equal(["Z"])
}

pub fn format_utc_iso8601micros_test() {
  tempo.format_utc(tempo.ISO8601Micro)
  |> string.to_graphemes
  |> list.reverse
  |> list.take(1)
  |> should.equal(["Z"])
}
