import gleam/order
import gleeunit/should
import tempo
import tempo/date
import tempo/duration
import tempo/naive_datetime
import tempo/time

pub fn from_string_test() {
  naive_datetime.from_string("2024-06-13T13:42:11")
  |> should.be_ok
  |> should.equal(naive_datetime.literal("2024-06-13T13:42:11"))
}

pub fn from_string_with_space_test() {
  naive_datetime.from_string("2024-06-13 13:42:11")
  |> should.be_ok
  |> should.equal(naive_datetime.literal("2024-06-13T13:42:11"))
}

pub fn from_date_string_only_test() {
  naive_datetime.from_string("2024-06-13")
  |> should.be_ok
  |> should.equal(naive_datetime.literal("2024-06-13T00:00:00"))
}

pub fn from_bad_string_test() {
  naive_datetime.from_string("2024-06-13|13:42:11")
  |> should.be_error

  naive_datetime.from_string("2024-06")
  |> should.be_error

  naive_datetime.from_string("13:42:11")
  |> should.be_error
}

pub fn to_string_test() {
  naive_datetime.literal("2024-06-13T13:42:11")
  |> naive_datetime.to_string
  |> should.equal("2024-06-13T13:42:11.000000")
}

pub fn to_tuple_test() {
  naive_datetime.literal("2024-06-21T23:17:07")
  |> naive_datetime.to_tuple
  |> should.equal(#(#(2024, 6, 21), #(23, 17, 7)))
}

pub fn format_test() {
  naive_datetime.literal("2024-06-21T13:42:11")
  |> naive_datetime.format(tempo.Custom("ddd @ h:mm A"))
  |> should.equal("Fri @ 1:42 PM")
}

pub fn get_date_test() {
  naive_datetime.literal("2024-06-13T13:42:11")
  |> naive_datetime.get_date
  |> should.equal(date.literal("2024-06-13"))
}

pub fn get_time_test() {
  naive_datetime.literal("2024-06-13T13:42:11")
  |> naive_datetime.get_time
  |> should.equal(time.literal("13:42:11"))
}

pub fn add_time_test() {
  naive_datetime.literal("2024-06-13T03:42:01")
  |> naive_datetime.add(duration.seconds(4))
  |> naive_datetime.to_string
  |> should.equal("2024-06-13T03:42:05.000000")
}

pub fn add_time_day_boundary_test() {
  naive_datetime.literal("2024-06-13T23:50:10")
  |> naive_datetime.add(duration.minutes(13))
  |> naive_datetime.to_string
  |> should.equal("2024-06-14T00:03:10.000000")
}

pub fn add_time_multiple_day_boundary_test() {
  naive_datetime.literal("2024-06-13T03:50:10")
  |> naive_datetime.add(duration.days(3))
  |> naive_datetime.add(duration.minutes(13))
  |> naive_datetime.to_string
  |> should.equal("2024-06-16T04:03:10.000000")
}

pub fn add_negative_time_test() {
  naive_datetime.literal("2024-06-13T03:42:05")
  |> naive_datetime.add(duration.seconds(-4))
  |> naive_datetime.to_string
  |> should.equal("2024-06-13T03:42:01.000000")
}

pub fn add_negative_time_day_boundary_test() {
  naive_datetime.literal("2024-06-13T00:03:10")
  |> naive_datetime.add(duration.minutes(-13))
  |> naive_datetime.to_string
  |> should.equal("2024-06-12T23:50:10.000000")
}

pub fn subtract_time_test() {
  naive_datetime.literal("2024-06-13T03:42:05")
  |> naive_datetime.subtract(duration.seconds(4))
  |> naive_datetime.to_string
  |> should.equal("2024-06-13T03:42:01.000000")
}

pub fn subtract_time_day_boundary_test() {
  naive_datetime.literal("2024-06-13T00:03:00")
  |> naive_datetime.subtract(duration.minutes(13))
  |> naive_datetime.to_string
  |> should.equal("2024-06-12T23:50:00.000000")
}

pub fn subtract_time_multiple_day_boundary_test() {
  naive_datetime.literal("2024-06-13T03:50:00")
  |> naive_datetime.subtract(duration.days(3))
  |> naive_datetime.subtract(duration.minutes(13))
  |> naive_datetime.to_string
  |> should.equal("2024-06-10T03:37:00.000000")
}

pub fn subtract_negative_time_test() {
  naive_datetime.literal("2024-06-13T03:42:05")
  |> naive_datetime.subtract(duration.seconds(-4))
  |> naive_datetime.to_string
  |> should.equal("2024-06-13T03:42:09.000000")
}

pub fn subtract_negative_time_day_boundary_test() {
  naive_datetime.literal("2024-06-12T23:47:00.000")
  |> naive_datetime.subtract(duration.minutes(-13))
  |> naive_datetime.to_string
  |> should.equal("2024-06-13T00:00:00.000000")
}

pub fn compare_eq_test() {
  naive_datetime.literal("2024-06-21T23:47:00")
  |> naive_datetime.compare(to: naive_datetime.literal("2024-06-21T23:47:00"))
  |> should.equal(order.Eq)
}

pub fn compare_lt_date_test() {
  naive_datetime.literal("2024-06-11T23:47:00")
  |> naive_datetime.compare(to: naive_datetime.literal("2024-06-12T23:47:00"))
  |> should.equal(order.Lt)
}

pub fn compare_lt_time_test() {
  naive_datetime.literal("2024-06-21T23:47:00.003")
  |> naive_datetime.compare(to: naive_datetime.literal(
    "2024-06-21T23:47:00.400",
  ))
  |> should.equal(order.Lt)
}

pub fn compare_gt_date_test() {
  naive_datetime.literal("2025-06-11T23:47:00")
  |> naive_datetime.compare(to: naive_datetime.literal("2024-06-12T23:47:00"))
  |> should.equal(order.Gt)
}

pub fn compare_gt_time_test() {
  naive_datetime.literal("2024-06-21T23:47:00.003")
  |> naive_datetime.compare(to: naive_datetime.literal(
    "2024-06-21T13:47:00.400",
  ))
  |> should.equal(order.Gt)
}

pub fn small_time_left_in_day_test() {
  naive_datetime.literal("2024-06-30T23:59:03")
  |> naive_datetime.time_left_in_day
  |> should.equal(time.literal("00:00:57"))
}

/// Naive datetimes cannot account for leap seconds.
pub fn small_time_left_in_day_leap_second_test() {
  naive_datetime.literal("2015-06-30T23:59:03")
  |> naive_datetime.time_left_in_day
  |> should.equal(time.literal("00:00:57"))
}

pub fn large_time_left_in_day_test() {
  naive_datetime.literal("2024-06-18T08:05:20")
  |> naive_datetime.time_left_in_day
  |> should.equal(time.literal("15:54:40"))
}
// pub fn monotonic_difference_override_test() {
//   let start =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(9, 30, 12, 300, Some(600), Some(0)),
//     )
//   let warped =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(8, 30, 12, 600, Some(1000), Some(0)),
//     )

//   naive_datetime.as_period(start:, end: warped)
//   |> period.as_duration
//   |> duration.as_microseconds
//   |> should.equal(400)
// }

// pub fn monotonic_difference_no_override_test() {
//   let start =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(9, 30, 12, 300, Some(600), Some(0)),
//     )
//   let warped =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(8, 30, 12, 600, None, None),
//     )

//   naive_datetime.as_period(end: warped, start:)
//   |> period.as_duration
//   |> duration.as_microseconds
//   |> should.not_equal(-600)
// }

// pub fn monotonic_survives_add_test() {
//   let start =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(9, 30, 12, 300, Some(600), Some(0)),
//     )
//   let warped =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(8, 30, 12, 600, Some(1000), Some(0)),
//     )

//   naive_datetime.add(start, duration: duration.microseconds(500))
//   |> naive_datetime.as_period(start: warped)
//   |> period.as_duration
//   |> duration.as_microseconds
//   |> should.equal(100)
// }

// pub fn monotonic_survives_subtract_test() {
//   let start =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(9, 30, 12, 300, Some(600), Some(0)),
//     )
//   let warped =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(8, 30, 12, 600, Some(1000), Some(0)),
//     )

//   naive_datetime.subtract(warped, duration: duration.microseconds(200))
//   |> naive_datetime.as_period(start:)
//   |> period.as_duration
//   |> duration.as_microseconds
//   |> should.equal(200)
// }

// pub fn unique_compare_override_test() {
//   let start =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(9, 30, 12, 300, Some(10_000), Some(1)),
//     )
//   let warped =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(8, 30, 12, 600, Some(1000), Some(2)),
//     )

//   naive_datetime.compare(start, to: warped)
//   |> should.equal(order.Lt)
// }

// pub fn unique_compare_no_override_test() {
//   let start =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(9, 30, 12, 300, Some(10_000), Some(1)),
//     )
//   let warped =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(8, 30, 12, 600, None, None),
//     )

//   naive_datetime.compare(start, to: warped)
//   |> should.equal(order.Gt)
// }

// pub fn monotonic_compare_override_test() {
//   let start =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(9, 30, 12, 300, Some(600), None),
//     )
//   let warped =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(8, 30, 12, 600, Some(1000), None),
//     )

//   naive_datetime.compare(start, to: warped)
//   |> should.equal(order.Lt)
// }

// pub fn unique_compare_does_not_survive_add_test() {
//   let start =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(9, 30, 12, 300, Some(10_000), Some(1)),
//     )
//   let warped =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(8, 30, 12, 600, Some(1000), Some(2)),
//     )

//   naive_datetime.add(warped, duration: duration.microseconds(500))
//   |> naive_datetime.compare(to: start)
//   |> should.equal(order.Lt)
// }

// pub fn unique_compare_does_not_survive_subtract_test() {
//   let start =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(9, 30, 12, 300, Some(10_000), Some(1)),
//     )
//   let warped =
//     tempo.naive_datetime(
//       date: date.literal("2024-06-21"),
//       time: tempo.time(8, 30, 12, 600, Some(1000), Some(2)),
//     )

//   naive_datetime.subtract(warped, duration: duration.microseconds(500))
//   |> naive_datetime.compare(to: start)
//   |> should.equal(order.Lt)
// }
