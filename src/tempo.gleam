//// The main module of this package. Contains most types and only a couple 
//// general purpose functions. Look in specific modules for more functionality!

import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/regexp
import gleam/result
import gleam/string
import gleam/string_tree
import gleam/yielder
import gtempo/internal as unit

// This is a big file. The contents are generally ordered by:
// - Tempo now functions
// - Moment logic (functions starting with `_moment`)
// - DateTime logic (funcctions starting with `datetime_`)
// - NaiveDateTime logic (functions starting with `naive_datetime_`)
// - Offset logic (functions starting with `offset_`)
// - Date logic (functions starting with `date_`)
// - Month logic (functions starting with `month_`)
// - Year logic (functions starting with `year_`)
// - Time logic (functions starting with `time_`)
// - Duration logic (functions starting with `dur_`)
// - Period logic (functions starting with `period_`)
// - Tempo module other logic 
// - FFI logic

// -------------------------------------------------------------------------- //
//                              Now Logic                                     //
// -------------------------------------------------------------------------- //

pub fn now_local() -> Moment {
  let monotonic_ns = now_monotonic_ffi()

  Moment(
    timestamp_ns: now_utc_ffi(),
    offset_ns: offset_local_nano(),
    monotonic_ns:,
    unique: now_unique_ffi(),
  )
}

pub fn now_utc() -> Moment {
  let monotonic_ns = now_monotonic_ffi()

  Moment(
    timestamp_ns: now_utc_ffi(),
    offset_ns: 0,
    monotonic_ns:,
    unique: now_unique_ffi(),
  )
}

pub fn now_utc_adjusted(by duration: Duration) -> DateTime {
  let new_ts = now_utc().timestamp_ns + duration.nanoseconds

  DateTime(
    NaiveDateTime(
      date_from_unix_utc(new_ts / 1_000_000_000),
      time_from_unix_nano_utc(new_ts),
    ),
    offset: utc,
  )
}

pub fn now_formatted(in format: String) -> String {
  now_utc() |> moment_as_datetime |> datetime_format(format)
}

// -------------------------------------------------------------------------- //
//                             Moment Logic                                   //
// -------------------------------------------------------------------------- //

pub opaque type Moment {
  Moment(timestamp_ns: Int, offset_ns: Int, monotonic_ns: Int, unique: Int)
}

@internal
pub fn moment_as_datetime(moment: Moment) -> DateTime {
  DateTime(
    naive: NaiveDateTime(
      date: moment_as_date(moment),
      time: moment_as_time(moment),
    ),
    offset: Offset(moment.offset_ns / 60_000_000_000),
  )
}

@internal
pub fn moment_as_unix_utc(moment: Moment) -> Int {
  moment.timestamp_ns / 1_000_000_000
}

@internal
pub fn moment_as_unix_milli_utc(moment: Moment) -> Int {
  moment.timestamp_ns / 1_000_000
}

@internal
pub fn moment_serialize_as_datetime(moment: Moment) -> String {
  moment |> moment_as_datetime |> datetime_serialize
}

@internal
pub fn moment_as_date(moment: Moment) -> Date {
  date_from_unix_utc({ moment.timestamp_ns + moment.offset_ns } / 1_000_000_000)
}

@internal
pub fn moment_as_time(moment: Moment) -> Time {
  time_from_unix_nano_utc(moment.timestamp_ns + moment.offset_ns)
}

pub fn is_earlier(than datetime: DateTime) -> Bool {
  datetime_is_earlier(now_utc() |> moment_as_datetime, than: datetime)
}

pub fn is_earlier_or_equal(to datetime: DateTime) -> Bool {
  datetime_is_earlier_or_equal(now_utc() |> moment_as_datetime, to: datetime)
}

pub fn is_equal(to datetime: DateTime) -> Bool {
  datetime_is_equal(now_utc() |> moment_as_datetime, to: datetime)
}

pub fn is_later(than datetime: DateTime) -> Bool {
  datetime_is_later(now_utc() |> moment_as_datetime, than: datetime)
}

pub fn is_later_or_equal(to datetime: DateTime) -> Bool {
  datetime_is_later_or_equal(now_utc() |> moment_as_datetime, to: datetime)
}

pub fn is_date_earlier(than date: Date) -> Bool {
  date_is_earlier(now_utc() |> moment_as_date, than: date)
}

pub fn is_date_earlier_or_equal(to date: Date) -> Bool {
  date_is_earlier_or_equal(now_utc() |> moment_as_date, to: date)
}

pub fn is_date_equal(to date: Date) -> Bool {
  date_is_equal(now_utc() |> moment_as_date, to: date)
}

pub fn is_date_later(than date: Date) -> Bool {
  date_is_later(now_utc() |> moment_as_date, than: date)
}

pub fn is_date_later_or_equal(to date: Date) -> Bool {
  date_is_later_or_equal(now_utc() |> moment_as_date, to: date)
}

pub fn is_time_earlier(than time: Time) -> Bool {
  time_is_earlier(now_utc() |> moment_as_time, than: time)
}

pub fn is_time_earlier_or_equal(to time: Time) -> Bool {
  time_is_earlier_or_equal(now_utc() |> moment_as_time, to: time)
}

pub fn is_time_equal(to time: Time) -> Bool {
  time_is_equal(now_utc() |> moment_as_time, to: time)
}

pub fn is_time_later(than time: Time) -> Bool {
  time_is_later(now_utc() |> moment_as_time, than: time)
}

pub fn is_time_later_or_equal(to time: Time) -> Bool {
  time_is_later_or_equal(now_utc() |> moment_as_time, to: time)
}

pub fn difference(from start: DateTime) -> Duration {
  now_utc() |> moment_as_datetime |> datetime_difference(from: start)
}

pub fn since(start start: DateTime) -> Duration {
  case difference(from: start) {
    Duration(diff) if diff > 0 -> Duration(diff)
    _ -> Duration(0)
  }
}

pub fn until(end end: DateTime) -> Duration {
  case now_utc() |> moment_as_datetime |> datetime_difference(to: end) {
    Duration(diff) if diff > 0 -> Duration(diff)
    _ -> Duration(0)
  }
}

pub fn difference_time(from start: Time) -> Duration {
  now_utc() |> moment_as_time |> time_difference(from: start)
}

pub fn since_time(start start: Time) -> Duration {
  case difference_time(from: start) {
    Duration(diff) if diff > 0 -> Duration(diff)
    _ -> Duration(0)
  }
}

pub fn until_time(end end: Time) -> Duration {
  case now_utc() |> moment_as_time |> time_difference(to: end) {
    Duration(diff) if diff > 0 -> Duration(diff)
    _ -> Duration(0)
  }
}

@internal
pub fn moment_compare(a: Moment, b: Moment) -> order.Order {
  int.compare(a.unique, b.unique)
}

@internal
pub fn moment_is_earlier(a: Moment, than b: Moment) {
  moment_compare(a, b) == order.Lt
}

@internal
pub fn moment_is_earlier_or_equal(a: Moment, to b: Moment) {
  moment_compare(a, b) == order.Lt || moment_compare(a, b) == order.Eq
}

@internal
pub fn moment_is_equal(a: Moment, to b: Moment) {
  moment_compare(a, b) == order.Eq
}

@internal
pub fn moment_is_later(a: Moment, than b: Moment) {
  moment_compare(a, b) == order.Gt
}

@internal
pub fn moment_is_later_or_equal(a: Moment, to b: Moment) {
  moment_compare(a, b) == order.Gt || moment_compare(a, b) == order.Eq
}

@internal
pub fn moment_difference(from a: Moment, to b: Moment) -> Duration {
  { b.monotonic_ns } - { a.monotonic_ns }
  |> Duration
}

@internal
pub fn moment_since(to moment: Moment, since start: Moment) -> String {
  let dur = moment |> moment_difference(from: start)

  int.absolute_value(dur.nanoseconds)
  |> unit.format
}

// -------------------------------------------------------------------------- //
//                            DateTime Logic                                  //
// -------------------------------------------------------------------------- //

/// A datetime value with a timezone offset associated with it. It has the 
/// most amount of information about a point in time, and can be compared to 
/// all other types in this package by getting its lesser parts.
pub opaque type DateTime {
  DateTime(naive: NaiveDateTime, offset: Offset)
  LocalDateTime(naive: NaiveDateTime, offset: Offset, tz: TimeZoneProvider)
}

/// A type for external packages to provide so that datetimes can be converted
/// between timezones. The package `gtz` was created to provide this and must
/// be installed separately.
pub type TimeZoneProvider {
  TimeZoneProvider(
    get_name: fn() -> String,
    calculate_offset: fn(NaiveDateTime) -> Offset,
  )
}

@internal
pub fn datetime(naive naive, offset offset) {
  DateTime(naive, offset)
}

@internal
pub fn datetime_get_naive(datetime: DateTime) {
  datetime.naive
}

@internal
pub fn datetime_get_offset(datetime: DateTime) {
  datetime.offset
}

@internal
pub fn datetime_to_utc(datetime: DateTime) -> DateTime {
  datetime
  |> datetime_apply_offset
  |> naive_datetime_set_offset(utc)
}

@internal
pub fn datetime_to_offset(datetime: DateTime, offset: Offset) -> DateTime {
  datetime
  |> datetime_to_utc
  |> datetime_subtract(offset_to_duration(offset))
  |> datetime_drop_offset
  |> naive_datetime_set_offset(offset)
}

@internal
pub fn datetime_to_tz(datetime: DateTime, tz: TimeZoneProvider) {
  let utc_dt = datetime_apply_offset(datetime)

  let offset = tz.calculate_offset(utc_dt)

  let naive =
    datetime_to_offset(utc_dt |> naive_datetime_set_offset(utc), offset)
    |> datetime_drop_offset

  LocalDateTime(naive:, offset:, tz:)
}

@internal
pub fn datetime_get_tz(datetime: DateTime) -> option.Option(String) {
  case datetime {
    DateTime(_, _) -> None
    LocalDateTime(_, _, tz:) -> Some(tz.get_name())
  }
}

@internal
pub fn datetime_serialize(datetime: DateTime) -> String {
  let d = datetime.naive.date
  let t = datetime.naive.time
  let o = datetime.offset

  string_tree.from_strings([
    d.year |> int.to_string |> string.pad_start(4, with: "0"),
    d.month
      |> month_to_int
      |> int.to_string
      |> string.pad_start(2, with: "0"),
    d.day |> int.to_string |> string.pad_start(2, with: "0"),
    "T",
    t.hour |> int.to_string |> string.pad_start(2, with: "0"),
    t.minute |> int.to_string |> string.pad_start(2, with: "0"),
    t.second |> int.to_string |> string.pad_start(2, with: "0"),
    ".",
    t.nanosecond |> int.to_string |> string.pad_start(9, with: "0"),
    case o |> offset_get_minutes {
      0 -> "Z"
      _ -> {
        let str_offset = o |> offset_to_string

        case str_offset |> string.split(":") {
          [hours, "00"] -> hours
          _ -> str_offset
        }
      }
    },
  ])
  |> string_tree.to_string
}

@internal
pub fn datetime_format(datetime: DateTime, in fmt: String) -> String {
  let assert Ok(re) = regexp.from_string(format_regex)

  regexp.scan(re, fmt)
  |> list.reverse
  |> list.fold(from: [], with: fn(acc, match) {
    case match {
      regexp.Match(content, []) -> [
        content
          |> date_replace_format(datetime.naive.date)
          |> time_replace_format(datetime.naive.time)
          |> offset_replace_format(datetime.offset),
        ..acc
      ]

      // If there is a non-empty subpattern, then the escape 
      // character "[ ... ]" matched, so we should not change anything here.
      regexp.Match(_, [Some(sub)]) -> [sub, ..acc]

      // This case is not expected, not really sure what to do with it 
      // so just prepend whatever was found
      regexp.Match(content, _) -> [content, ..acc]
    }
  })
  |> string.join("")
}

@internal
pub fn datetime_compare(a: DateTime, to b: DateTime) {
  datetime_apply_offset(a)
  |> naive_datetime_compare(to: datetime_apply_offset(b))
}

@internal
pub fn datetime_is_earlier(a: DateTime, than b: DateTime) -> Bool {
  datetime_compare(a, b) == order.Lt
}

@internal
pub fn datetime_is_earlier_or_equal(a: DateTime, to b: DateTime) -> Bool {
  datetime_compare(a, b) == order.Lt || datetime_compare(a, b) == order.Eq
}

@internal
pub fn datetime_is_equal(a: DateTime, to b: DateTime) -> Bool {
  datetime_compare(a, b) == order.Eq
}

@internal
pub fn datetime_is_later_or_equal(a: DateTime, to b: DateTime) -> Bool {
  datetime_compare(a, b) == order.Gt || datetime_compare(a, b) == order.Eq
}

@internal
pub fn datetime_is_later(a: DateTime, than b: DateTime) -> Bool {
  datetime_compare(a, b) == order.Gt
}

@internal
pub fn datetime_difference(from a: DateTime, to b: DateTime) -> Duration {
  naive_datetime_difference(
    from: datetime_apply_offset(a),
    to: datetime_apply_offset(b),
  )
}

@internal
pub fn datetime_apply_offset(datetime: DateTime) -> NaiveDateTime {
  let applied =
    datetime
    |> datetime_drop_offset
    |> naive_datetime_add(offset_to_duration(datetime.offset))

  // Applying an offset does not change the abosolute time value, so we need
  // to preserve the monotonic and unique values.zzzz
  NaiveDateTime(date: applied.date, time: applied.time)
}

@internal
pub fn datetime_drop_offset(datetime: DateTime) -> NaiveDateTime {
  datetime.naive
}

@internal
pub fn datetime_add(
  datetime: DateTime,
  duration duration_to_add: Duration,
) -> DateTime {
  case datetime {
    DateTime(naive:, offset:) ->
      DateTime(
        naive: naive_datetime_add(naive, duration: duration_to_add),
        offset:,
      )
    LocalDateTime(_, _, tz:) -> {
      let utc_dt_added =
        datetime_to_utc(datetime)
        |> datetime_add(duration: duration_to_add)

      let offset = utc_dt_added |> datetime_drop_offset |> tz.calculate_offset

      let naive =
        datetime_to_offset(utc_dt_added, offset)
        |> datetime_drop_offset

      LocalDateTime(naive:, offset:, tz:)
    }
  }
}

@internal
pub fn datetime_subtract(
  datetime: DateTime,
  duration duration_to_subtract: Duration,
) -> DateTime {
  case datetime {
    DateTime(naive:, offset:) ->
      DateTime(
        naive: naive_datetime_subtract(naive, duration: duration_to_subtract),
        offset:,
      )
    LocalDateTime(_, _, tz:) -> {
      let utc_dt_sub =
        datetime_to_utc(datetime)
        |> datetime_subtract(duration: duration_to_subtract)

      let offset = utc_dt_sub |> datetime_drop_offset |> tz.calculate_offset

      let naive =
        datetime_to_offset(utc_dt_sub, offset)
        |> datetime_drop_offset

      LocalDateTime(naive:, offset:, tz:)
    }
  }
}

// -------------------------------------------------------------------------- //
//                         Naive DateTime Logic                               //
// -------------------------------------------------------------------------- //

/// A datetime value that does not have a timezone offset associated with it. 
/// It cannot be compared to datetimes with a timezone offset accurately, but
/// can be compared to dates, times, and other naive datetimes.
pub opaque type NaiveDateTime {
  NaiveDateTime(date: Date, time: Time)
}

@internal
pub fn naive_datetime(date date: Date, time time: Time) -> NaiveDateTime {
  NaiveDateTime(date: date, time: time)
}

@internal
pub fn naive_datetime_get_date(naive_datetime: NaiveDateTime) -> Date {
  naive_datetime.date
}

@internal
pub fn naive_datetime_get_time(naive_datetime: NaiveDateTime) -> Time {
  naive_datetime.time
}

@internal
pub fn naive_datetime_set_offset(
  datetime: NaiveDateTime,
  offset: Offset,
) -> DateTime {
  DateTime(naive: datetime, offset: offset)
}

@internal
pub fn naive_datetime_compare(a: NaiveDateTime, to b: NaiveDateTime) {
  case date_compare(a.date, b.date) {
    order.Eq -> time_compare(a.time, b.time)
    od -> od
  }
}

@internal
pub fn naive_datetime_is_earlier(
  a: NaiveDateTime,
  than b: NaiveDateTime,
) -> Bool {
  naive_datetime_compare(a, b) == order.Lt
}

@internal
pub fn naive_datetime_is_earlier_or_equal(
  a: NaiveDateTime,
  to b: NaiveDateTime,
) -> Bool {
  naive_datetime_compare(a, b) == order.Lt
  || naive_datetime_compare(a, b) == order.Eq
}

@internal
pub fn naive_datetime_is_later_or_equal(
  a: NaiveDateTime,
  to b: NaiveDateTime,
) -> Bool {
  naive_datetime_compare(a, b) == order.Gt
  || naive_datetime_compare(a, b) == order.Eq
}

@internal
pub fn naive_datetime_difference(
  from a: NaiveDateTime,
  to b: NaiveDateTime,
) -> Duration {
  date_days_apart(from: a.date, to: b.date)
  |> duration_days
  |> duration_increase(by: time_difference(from: a.time, to: b.time))
}

@internal
pub fn naive_datetime_add(
  datetime: NaiveDateTime,
  duration duration_to_add: Duration,
) -> NaiveDateTime {
  // Positive date overflows are only handled in this function, while negative
  // date overflows are only handled in the subtract function -- so if the 
  // duration is negative, we can just subtract the absolute value of it.
  use <- bool.lazy_guard(when: duration_to_add.nanoseconds < 0, return: fn() {
    datetime |> naive_datetime_subtract(duration_absolute(duration_to_add))
  })

  let days_to_add: Int = duration_as_days(duration_to_add)
  let time_to_add: Duration =
    duration_decrease(duration_to_add, by: duration_days(days_to_add))

  let new_time_as_ns =
    datetime.time
    |> time_to_duration
    |> duration_increase(by: time_to_add)
    |> duration_as_nanoseconds

  // If the time to add crossed a day boundary, add an extra day to the 
  // number of days to add and adjust the time to add.
  let #(new_time_as_ns, days_to_add): #(Int, Int) = case
    new_time_as_ns >= unit.imprecise_day_nanoseconds
  {
    True -> #(new_time_as_ns - unit.imprecise_day_nanoseconds, days_to_add + 1)
    False -> #(new_time_as_ns, days_to_add)
  }

  let time_to_add =
    Duration(new_time_as_ns - time_to_nanoseconds(datetime.time))

  let new_date = datetime.date |> date_add(days: days_to_add)
  let new_time = datetime.time |> time_add(duration: time_to_add)

  NaiveDateTime(date: new_date, time: new_time)
}

@internal
pub fn naive_datetime_subtract(
  datetime: NaiveDateTime,
  duration duration_to_subtract: Duration,
) -> NaiveDateTime {
  // Negative date overflows are only handled in this function, while positive
  // date overflows are only handled in the add function -- so if the 
  // duration is negative, we can just add the absolute value of it.
  use <- bool.lazy_guard(
    when: duration_to_subtract.nanoseconds < 0,
    return: fn() {
      datetime |> naive_datetime_add(duration_absolute(duration_to_subtract))
    },
  )

  let days_to_sub: Int = duration_as_days(duration_to_subtract)
  let time_to_sub: Duration =
    duration_decrease(duration_to_subtract, by: duration_days(days_to_sub))

  let new_time_as_ns =
    datetime.time
    |> time_to_duration
    |> duration_decrease(by: time_to_sub)
    |> duration_as_nanoseconds

  // If the time to subtract crossed a day boundary, add an extra day to the 
  // number of days to subtract and adjust the time to subtract.
  let #(new_time_as_ns, days_to_sub) = case new_time_as_ns < 0 {
    True -> #(new_time_as_ns + unit.imprecise_day_nanoseconds, days_to_sub + 1)
    False -> #(new_time_as_ns, days_to_sub)
  }

  let time_to_sub =
    Duration(time_to_nanoseconds(datetime.time) - new_time_as_ns)

  // Using the proper subtract functions here to modify the date and time
  // values instead of declaring a new date is important for perserving date 
  // correctness and time precision.
  let new_date =
    datetime.date
    |> date_subtract(days: days_to_sub)
  let new_time =
    datetime.time
    |> time_subtract(duration: time_to_sub)

  NaiveDateTime(date: new_date, time: new_time)
}

// -------------------------------------------------------------------------- //
//                             Offset Logic                                   //
// -------------------------------------------------------------------------- //

/// A timezone offset value. It represents the difference between UTC and the
/// datetime value it is associated with.
pub opaque type Offset {
  Offset(minutes: Int)
}

@internal
pub fn offset(minutes minutes) {
  Offset(minutes)
}

@internal
pub fn offset_get_minutes(offset: Offset) {
  offset.minutes
}

/// The Tempo representation of the UTC offset.
pub const utc = Offset(0)

@internal
pub fn new_offset(offset_minutes minutes: Int) -> Result(Offset, Nil) {
  Offset(minutes) |> validate_offset
}

@internal
pub fn offset_from_string(offset: String) -> Result(Offset, OffsetParseError) {
  use offset <- result.try(case offset {
    // Parse Z format
    "Z" -> Ok(utc)
    "z" -> Ok(utc)

    // Parse +-hh:mm format
    _ -> {
      use #(sign, hour, minute): #(String, String, String) <- result.try(case
        string.split(offset, ":")
      {
        [hour, minute] ->
          case string.length(hour), string.length(minute) {
            3, 2 ->
              Ok(#(
                string.slice(hour, at_index: 0, length: 1),
                string.slice(hour, at_index: 1, length: 2),
                minute,
              ))
            _, _ -> Error(OffsetInvalidFormat("Invalid hour or minute length"))
          }
        _ ->
          // Parse +-hhmm format, +-hh format, or +-h format
          case string.length(offset) {
            5 ->
              Ok(#(
                string.slice(offset, at_index: 0, length: 1),
                string.slice(offset, at_index: 1, length: 2),
                string.slice(offset, at_index: 3, length: 2),
              ))
            3 ->
              Ok(#(
                string.slice(offset, at_index: 0, length: 1),
                string.slice(offset, at_index: 1, length: 2),
                "0",
              ))
            2 ->
              Ok(#(
                string.slice(offset, at_index: 0, length: 1),
                string.slice(offset, at_index: 1, length: 1),
                "0",
              ))
            _ -> Error(OffsetInvalidFormat("Invalid offset length"))
          }
      })

      case sign, int.parse(hour), int.parse(minute) {
        _, Ok(0), Ok(0) -> Ok(utc)
        "-", Ok(hour), Ok(minute) if hour <= 24 && minute <= 60 ->
          Ok(Offset(-{ hour * 60 + minute }))
        "+", Ok(hour), Ok(minute) if hour <= 24 && minute <= 60 ->
          Ok(Offset(hour * 60 + minute))
        _, _, _ ->
          Error(OffsetInvalidFormat("Invalid sign or non-integer value"))
      }
    }
  })
  validate_offset(offset) |> result.replace_error(OffsetOutOfBounds)
}

@internal
pub fn offset_to_string(offset: Offset) -> String {
  let #(is_negative, hours) = case offset_get_minutes(offset) / 60 {
    h if h <= 0 -> #(True, -h)
    h -> #(False, h)
  }

  let mins = case offset_get_minutes(offset) % 60 {
    m if m < 0 -> -m
    m -> m
  }

  case is_negative, hours, mins {
    _, 0, 0 -> "-00:00"

    _, 0, m -> "-00:" <> int.to_string(m) |> string.pad_start(2, with: "0")

    True, h, m ->
      "-"
      <> int.to_string(h) |> string.pad_start(2, with: "0")
      <> ":"
      <> int.to_string(m) |> string.pad_start(2, with: "0")

    False, h, m ->
      "+"
      <> int.to_string(h) |> string.pad_start(2, with: "0")
      <> ":"
      <> int.to_string(m) |> string.pad_start(2, with: "0")
  }
}

@internal
pub fn validate_offset(offset: Offset) -> Result(Offset, Nil) {
  // Valid time offsets are between -12:00 and +14:00
  case offset.minutes >= -720 && offset.minutes <= 840 {
    True -> Ok(offset)
    False -> Error(Nil)
  }
}

@internal
pub fn offset_to_duration(offset: Offset) -> Duration {
  -offset.minutes * 60_000_000_000 |> Duration
}

// -------------------------------------------------------------------------- //
//                              Date Logic                                    //
// -------------------------------------------------------------------------- //

/// A date value. It represents a specific day on the civil calendar with no
/// time of day associated with it.
pub opaque type Date {
  Date(year: Int, month: Month, day: Int)
}

@internal
pub fn date(year year, month month, day day) {
  Date(year: year, month: month, day: day)
}

@internal
pub fn date_get_year(date: Date) {
  date.year
}

@internal
pub fn date_get_month(date: Date) {
  date.month
}

@internal
pub fn date_get_day(date: Date) {
  date.day
}

@internal
pub fn new_date(
  year year: Int,
  month month: Int,
  day day: Int,
) -> Result(Date, DateOutOfBoundsError) {
  date_from_tuple(#(year, month, day))
}

@internal
pub fn date_replace_format(content: String, date: Date) -> String {
  case content {
    "YY" ->
      date.year
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
      |> string.slice(at_index: -2, length: 2)
    "YYYY" ->
      date.year
      |> int.to_string
      |> string.pad_start(with: "0", to: 4)
    "M" ->
      date.month
      |> month_to_int
      |> int.to_string
    "MM" ->
      date.month
      |> month_to_int
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "MMM" ->
      date.month
      |> month_to_short_string
    "MMMM" ->
      date.month
      |> month_to_long_string
    "D" ->
      date.day
      |> int.to_string
    "DD" ->
      date.day
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "d" ->
      date
      |> date_to_day_of_week_number
      |> int.to_string
    "dd" ->
      date
      |> date_to_day_of_week_short
      |> string.slice(at_index: 0, length: 2)
    "ddd" -> date |> date_to_day_of_week_short
    "dddd" -> date |> date_to_day_of_week_long
    _ -> content
  }
}

fn date_to_day_of_week_short(date: Date) -> String {
  case date_to_day_of_week_number(date) {
    0 -> "Sun"
    1 -> "Mon"
    2 -> "Tue"
    3 -> "Wed"
    4 -> "Thu"
    5 -> "Fri"
    6 -> "Sat"
    _ -> panic as "Invalid day of week found after modulo by 7"
  }
}

fn date_to_day_of_week_long(date: Date) -> String {
  case date_to_day_of_week_number(date) {
    0 -> "Sunday"
    1 -> "Monday"
    2 -> "Tuesday"
    3 -> "Wednesday"
    4 -> "Thursday"
    5 -> "Friday"
    6 -> "Saturday"
    _ -> panic as "Invalid day of week found after modulo by 7"
  }
}

@internal
pub fn date_to_day_of_week_number(date: Date) -> Int {
  let year_code =
    date.year % 100
    |> fn(short_year) { { short_year + { short_year / 4 } } % 7 }

  let month_code = case date.month {
    Jan -> 0
    Feb -> 3
    Mar -> 3
    Apr -> 6
    May -> 1
    Jun -> 4
    Jul -> 6
    Aug -> 2
    Sep -> 5
    Oct -> 0
    Nov -> 3
    Dec -> 5
  }

  let century_code = case date.year {
    year if year < 1752 -> 0
    year if year < 1800 -> 4
    year if year < 1900 -> 2
    year if year < 2000 -> 0
    year if year < 2100 -> 6
    year if year < 2200 -> 4
    year if year < 2300 -> 2
    year if year < 2400 -> 4
    _ -> 0
  }

  let leap_year_code = case is_leap_year(date.year) {
    True ->
      case date.month {
        Jan | Feb -> 1
        _ -> 0
      }
    False -> 0
  }

  { year_code + month_code + century_code + date.day - leap_year_code } % 7
}

@internal
pub fn date_from_tuple(
  date: #(Int, Int, Int),
) -> Result(Date, DateOutOfBoundsError) {
  let year = date.0
  let month = date.1
  let day = date.2

  use month <- result.try(
    month_from_int(month) |> result.replace_error(DateMonthOutOfBounds),
  )

  case year >= 1000 && year <= 9999 {
    True ->
      case day >= 1 && day <= month_days_of(month, in: year) {
        True -> Ok(Date(year, month, day))
        False -> Error(DateDayOutOfBounds)
      }
    False -> Error(DateYearOutOfBounds)
  }
}

@internal
pub fn date_from_unix_utc(unix_ts: Int) -> Date {
  let z = unix_ts / 86_400 + 719_468
  let era =
    case z >= 0 {
      True -> z
      False -> z - 146_096
    }
    / 146_097
  let doe = z - era * 146_097
  let yoe = { doe - doe / 1460 + doe / 36_524 - doe / 146_096 } / 365
  let y = yoe + era * 400
  let doy = doe - { 365 * yoe + yoe / 4 - yoe / 100 }
  let mp = { 5 * doy + 2 } / 153
  let d = doy - { 153 * mp + 2 } / 5 + 1
  let m =
    mp
    + case mp < 10 {
      True -> 3
      False -> -9
    }
  let y = y + bool.to_int(m <= 2)

  let assert Ok(month) = month_from_int(m)

  Date(y, month, d)
}

@internal
pub fn date_to_unix_utc(date: Date) -> Int {
  let full_years_since_epoch = date_get_year(date) - 1970
  // Offset the year by one to cacluate the number of leap years since the
  // epoch since 1972 is the first leap year after epoch. 1972 is a leap year,
  // so when the date is 1972, the elpased leap years (1972 has not elapsed
  // yet) is equal to (2 + 1) / 4, which is 0. When the date is 1973, the
  // elapsed leap years is equal to (3 + 1) / 4, which is 1, because one leap
  // year, 1972, has fully elapsed.
  let full_elapsed_leap_years_since_epoch = { full_years_since_epoch + 1 } / 4
  let full_elapsed_non_leap_years_since_epoch =
    full_years_since_epoch - full_elapsed_leap_years_since_epoch

  let year_sec =
    { full_elapsed_non_leap_years_since_epoch * 31_536_000 }
    + { full_elapsed_leap_years_since_epoch * 31_622_400 }

  let feb_milli = case is_leap_year(date |> date_get_year) {
    True -> 2_505_600
    False -> 2_419_200
  }

  let month_sec = case date |> date_get_month {
    Jan -> 0
    Feb -> 2_678_400
    Mar -> 2_678_400 + feb_milli
    Apr -> 5_356_800 + feb_milli
    May -> 7_948_800 + feb_milli
    Jun -> 10_627_200 + feb_milli
    Jul -> 13_219_200 + feb_milli
    Aug -> 15_897_600 + feb_milli
    Sep -> 18_576_000 + feb_milli
    Oct -> 21_168_000 + feb_milli
    Nov -> 23_846_400 + feb_milli
    Dec -> 26_438_400 + feb_milli
  }

  let day_sec = { date_get_day(date) - 1 } * 86_400

  year_sec + month_sec + day_sec
}

@internal
pub fn date_from_unix_micro_utc(unix_ts: Int) -> Date {
  date_from_unix_utc(unix_ts / 1_000_000)
}

@internal
pub fn date_to_unix_micro_utc(date: Date) -> Int {
  date_to_unix_utc(date) * 1_000_000
}

@internal
pub fn date_add(date: Date, days days: Int) -> Date {
  let days_left_this_month = month_days_of(date.month, in: date.year) - date.day

  case days <= days_left_this_month {
    True -> Date(date.year, date.month, { date.day } + days)
    False -> {
      let next_month = month_next(date.month)
      let year = case next_month == Jan {
        True -> { date.year } + 1
        False -> date.year
      }

      date_add(Date(year, next_month, 1), days - days_left_this_month - 1)
    }
  }
}

@internal
pub fn date_subtract(date: Date, days days: Int) -> Date {
  case days < date.day {
    True -> Date(date.year, date.month, { date.day } - days)
    False -> {
      let prior_month = month_prior(date.month)
      let year = case prior_month == Dec {
        True -> { date.year } - 1
        False -> date.year
      }

      date_subtract(
        Date(year, prior_month, month_days_of(prior_month, in: year)),
        days - date_get_day(date),
      )
    }
  }
}

@internal
pub fn date_days_apart(from start_date: Date, to end_date: Date) {
  case start_date |> date_is_earlier_or_equal(to: end_date) {
    True -> date_days_apart_positive(start_date, end_date)
    False -> -date_days_apart_positive(end_date, start_date)
  }
}

/// Returns the difference between two dates, assuming the start date
/// is sooner than the end_date
fn date_days_apart_positive(from start_date: Date, to end_date: Date) {
  // Caclulate the number of days in the years that are between (exclusive)
  // the start and end dates.
  let days_in_the_years_between = case
    calendar_years_apart(end_date, start_date)
  {
    years_apart if years_apart >= 2 ->
      list.range(1, years_apart - 1)
      |> list.map(fn(i) { date_get_year(end_date) + i |> year_days })
      |> int.sum
    _ -> 0
  }

  // Now that we have the number of days in the years between, we can ignore 
  // the fact that the start and end dates (may) be in different years and 
  // calculate the number of days in the months between (exclusive).
  let days_in_the_months_between =
    exclusive_months_between_days(start_date, end_date)

  // Now that we have the number of days in both the years and months between
  // the start and end dates, we can calculate the difference between the two 
  // dates and can ignore the fact that they may be in different years or 
  // months.
  let days_apart = case
    date_get_year(end_date) == date_get_year(start_date)
    && {
      date_get_month(end_date) |> month_to_int
      <= date_get_month(start_date) |> month_to_int
    }
  {
    True -> date_get_day(end_date) - date_get_day(start_date)
    False ->
      date_get_day(end_date)
      + {
        month_days_of(date_get_month(start_date), date_get_year(start_date))
        - date_get_day(start_date)
      }
  }

  // Now add the days from each section back up together.
  days_in_the_years_between + days_in_the_months_between + days_apart
}

fn exclusive_months_between_days(from: Date, to: Date) {
  use <- bool.guard(
    when: to |> date_get_year == from |> date_get_year
      && {
      to |> date_get_month |> month_prior |> month_to_int
      < from |> date_get_month |> month_next |> month_to_int
    },
    return: 0,
  )

  case to |> date_get_year == from |> date_get_year {
    True ->
      list.range(
        month_to_int(from |> date_get_month |> month_next),
        month_to_int(to |> date_get_month |> month_prior),
      )
      |> list.map(fn(m) {
        let assert Ok(m) = month_from_int(m)
        m
      })
    False -> {
      case to |> date_get_month == Jan {
        True -> []
        False ->
          list.range(1, month_to_int(to |> date_get_month |> month_prior))
      }
      |> list.map(fn(m) {
        let assert Ok(m) = month_from_int(m)
        m
      })
      |> list.append(
        case from |> date_get_month == Dec {
          True -> []
          False ->
            list.range(month_to_int(from |> date_get_month |> month_next), 12)
        }
        |> list.map(fn(m) {
          let assert Ok(m) = month_from_int(m)
          m
        }),
      )
    }
  }
  |> list.map(fn(m) { month_days_of(m, in: to |> date_get_year) })
  |> int.sum
}

fn calendar_years_apart(later: Date, from earlier: Date) -> Int {
  later.year - earlier.year
}

@internal
pub fn date_compare(a: Date, to b: Date) -> order.Order {
  case a.year == b.year {
    True ->
      case a.month == b.month {
        True ->
          case a.day == b.day {
            True -> order.Eq
            False -> int.compare(a.day, b.day)
          }
        False ->
          int.compare(
            month_to_int(a |> date_get_month),
            month_to_int(b |> date_get_month),
          )
      }
    False -> int.compare(a.year, b.year)
  }
}

@internal
pub fn date_is_earlier(a: Date, than b: Date) -> Bool {
  date_compare(a, b) == order.Lt
}

@internal
pub fn date_is_earlier_or_equal(a: Date, to b: Date) -> Bool {
  date_compare(a, b) == order.Lt || date_compare(a, b) == order.Eq
}

@internal
pub fn date_is_equal(a: Date, to b: Date) -> Bool {
  date_compare(a, b) == order.Eq
}

@internal
pub fn date_is_later(a: Date, than b: Date) -> Bool {
  date_compare(a, b) == order.Gt
}

@internal
pub fn date_is_later_or_equal(a: Date, to b: Date) -> Bool {
  date_compare(a, b) == order.Gt || date_compare(a, b) == order.Eq
}

// -------------------------------------------------------------------------- //
//                              Month Logic                                   //
// -------------------------------------------------------------------------- //

/// A month in a specific year.
pub type MonthYear {
  MonthYear(month: Month, year: Int)
}

/// A specific month on the civil calendar. 
pub type Month {
  Jan
  Feb
  Mar
  Apr
  May
  Jun
  Jul
  Aug
  Sep
  Oct
  Nov
  Dec
}

/// An ordered list of all months in the year.
pub const months = [Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec]

@internal
pub fn month_from_int(month: Int) -> Result(Month, Nil) {
  case month {
    1 -> Ok(Jan)
    2 -> Ok(Feb)
    3 -> Ok(Mar)
    4 -> Ok(Apr)
    5 -> Ok(May)
    6 -> Ok(Jun)
    7 -> Ok(Jul)
    8 -> Ok(Aug)
    9 -> Ok(Sep)
    10 -> Ok(Oct)
    11 -> Ok(Nov)
    12 -> Ok(Dec)
    _ -> Error(Nil)
  }
}

@internal
pub fn month_from_short_string(month: String) -> Result(Month, Nil) {
  case month {
    "Jan" -> Ok(Jan)
    "Feb" -> Ok(Feb)
    "Mar" -> Ok(Mar)
    "Apr" -> Ok(Apr)
    "May" -> Ok(May)
    "Jun" -> Ok(Jun)
    "Jul" -> Ok(Jul)
    "Aug" -> Ok(Aug)
    "Sep" -> Ok(Sep)
    "Oct" -> Ok(Oct)
    "Nov" -> Ok(Nov)
    "Dec" -> Ok(Dec)
    _ -> Error(Nil)
  }
}

@internal
pub fn month_from_long_string(month: String) {
  case month {
    "January" -> Ok(Jan)
    "February" -> Ok(Feb)
    "March" -> Ok(Mar)
    "April" -> Ok(Apr)
    "May" -> Ok(May)
    "June" -> Ok(Jun)
    "July" -> Ok(Jul)
    "August" -> Ok(Aug)
    "September" -> Ok(Sep)
    "October" -> Ok(Oct)
    "November" -> Ok(Nov)
    "December" -> Ok(Dec)
    _ -> Error(Nil)
  }
}

@internal
pub fn month_to_int(month: Month) -> Int {
  case month {
    Jan -> 1
    Feb -> 2
    Mar -> 3
    Apr -> 4
    May -> 5
    Jun -> 6
    Jul -> 7
    Aug -> 8
    Sep -> 9
    Oct -> 10
    Nov -> 11
    Dec -> 12
  }
}

@internal
pub fn month_to_short_string(month: Month) -> String {
  case month {
    Jan -> "Jan"
    Feb -> "Feb"
    Mar -> "Mar"
    Apr -> "Apr"
    May -> "May"
    Jun -> "Jun"
    Jul -> "Jul"
    Aug -> "Aug"
    Sep -> "Sep"
    Oct -> "Oct"
    Nov -> "Nov"
    Dec -> "Dec"
  }
}

@internal
pub fn month_to_long_string(month: Month) -> String {
  case month {
    Jan -> "January"
    Feb -> "February"
    Mar -> "March"
    Apr -> "April"
    May -> "May"
    Jun -> "June"
    Jul -> "July"
    Aug -> "August"
    Sep -> "September"
    Oct -> "October"
    Nov -> "November"
    Dec -> "December"
  }
}

@internal
pub fn month_days_of(month: Month, in year: Int) -> Int {
  case month {
    Jan -> 31
    Mar -> 31
    May -> 31
    Jul -> 31
    Aug -> 31
    Oct -> 31
    Dec -> 31
    _ ->
      case month {
        Apr -> 30
        Jun -> 30
        Sep -> 30
        Nov -> 30
        _ ->
          case is_leap_year(year) {
            True -> 29
            False -> 28
          }
      }
  }
}

@internal
pub fn month_next(month: Month) -> Month {
  case month {
    Jan -> Feb
    Feb -> Mar
    Mar -> Apr
    Apr -> May
    May -> Jun
    Jun -> Jul
    Jul -> Aug
    Aug -> Sep
    Sep -> Oct
    Oct -> Nov
    Nov -> Dec
    Dec -> Jan
  }
}

@internal
pub fn month_prior(month: Month) -> Month {
  case month {
    Jan -> Dec
    Feb -> Jan
    Mar -> Feb
    Apr -> Mar
    May -> Apr
    Jun -> May
    Jul -> Jun
    Aug -> Jul
    Sep -> Aug
    Oct -> Sep
    Nov -> Oct
    Dec -> Nov
  }
}

// -------------------------------------------------------------------------- //
//                              Year Logic                                    //
// -------------------------------------------------------------------------- //

@internal
pub fn is_leap_year(year: Int) -> Bool {
  case year % 4 == 0 {
    True ->
      case year % 100 == 0 {
        True ->
          case year % 400 == 0 {
            True -> True
            False -> False
          }
        False -> True
      }
    False -> False
  }
}

@internal
pub fn year_days(of year: Int) -> Int {
  case is_leap_year(year) {
    True -> 366
    False -> 365
  }
}

// -------------------------------------------------------------------------- //
//                              Time Logic                                    //
// -------------------------------------------------------------------------- //

/// A time of day value. It represents a specific time on an unspecified date.
/// It cannot be greater than 24 hours or less than 0 hours. It can have 
/// different precisions between second and nanosecond, depending on what 
/// your application needs.
pub opaque type Time {
  Time(hour: Int, minute: Int, second: Int, nanosecond: Int)
}

@internal
pub fn time(hour hour, minute minute, second second, nano nanosecond) {
  Time(hour:, minute:, second:, nanosecond:)
}

@internal
pub fn time_get_hour(time: Time) {
  time.hour
}

@internal
pub fn time_get_minute(time: Time) {
  time.minute
}

@internal
pub fn time_get_second(time: Time) {
  time.second
}

@internal
pub fn time_get_nano(time: Time) {
  time.nanosecond
}

@internal
pub fn time_set_mono(time: Time) {
  Time(time.hour, time.minute, time.second, time.nanosecond)
}

@internal
pub fn new_time(
  hour: Int,
  minute: Int,
  second: Int,
) -> Result(Time, TimeOutOfBoundsError) {
  Time(hour, minute, second, 0) |> validate_time
}

@internal
pub fn new_time_milli(
  hour: Int,
  minute: Int,
  second: Int,
  millisecond: Int,
) -> Result(Time, TimeOutOfBoundsError) {
  Time(hour, minute, second, millisecond * 1_000_000)
  |> validate_time
}

@internal
pub fn new_time_micro(
  hour: Int,
  minute: Int,
  second: Int,
  microsecond: Int,
) -> Result(Time, TimeOutOfBoundsError) {
  Time(hour, minute, second, microsecond * 1000)
  |> validate_time
}

@internal
pub fn new_time_nano(
  hour: Int,
  minute: Int,
  second: Int,
  nanosecond: Int,
) -> Result(Time, TimeOutOfBoundsError) {
  Time(hour, minute, second, nanosecond) |> validate_time
}

@internal
pub fn validate_time(time: Time) -> Result(Time, TimeOutOfBoundsError) {
  case
    {
      time.hour >= 0
      && time.hour <= 23
      && time.minute >= 0
      && time.minute <= 59
      && time.second >= 0
      && time.second <= 59
    }
    // For end of day time https://en.wikipedia.org/wiki/ISO_8601
    || {
      time.hour == 24
      && time.minute == 0
      && time.second == 0
      && time.nanosecond == 0
    }
    // For leap seconds https://en.wikipedia.org/wiki/Leap_second. Leap seconds
    // are not fully supported by this package, but can be parsed from ISO 8601
    // dates.
    || { time.minute == 59 && time.second == 60 && time.nanosecond == 0 }
  {
    True ->
      case time.nanosecond <= 999_999_999 {
        True -> Ok(time)
        False -> Error(TimeNanoSecondOutOfBounds)
      }
    False ->
      case time.hour, time.minute, time.second {
        _, _, s if s > 59 || s < 0 -> Error(TimeSecondOutOfBounds)
        _, m, _ if m > 59 || m < 0 -> Error(TimeMinuteOutOfBounds)
        _, _, _ -> Error(TimeHourOutOfBounds)
      }
  }
}

@internal
pub fn time_replace_format(content: String, time: Time) -> String {
  case content {
    "H" -> time.hour |> int.to_string
    "HH" ->
      time.hour
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "h" ->
      case time.hour {
        hour if hour == 0 -> 12
        hour if hour > 12 -> hour - 12
        hour -> hour
      }
      |> int.to_string
    "hh" ->
      case time.hour {
        hour if hour == 0 -> 12
        hour if hour > 12 -> hour - 12
        hour -> hour
      }
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "a" ->
      case time.hour >= 12 {
        True -> "pm"
        False -> "am"
      }
    "A" ->
      case time.hour >= 12 {
        True -> "PM"
        False -> "AM"
      }
    "m" -> time.minute |> int.to_string
    "mm" ->
      time.minute
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "s" -> time.second |> int.to_string
    "ss" ->
      time.second
      |> int.to_string
      |> string.pad_start(with: "0", to: 2)
    "SSS" ->
      time.nanosecond
      |> fn(nano) { nano / 1_000_000 }
      |> int.to_string
      |> string.pad_start(with: "0", to: 3)
    "SSSS" ->
      time.nanosecond
      |> fn(nano) { nano / 1000 }
      |> int.to_string
      |> string.pad_start(with: "0", to: 6)
    "SSSSS" ->
      time.nanosecond
      |> int.to_string
      |> string.pad_start(with: "0", to: 9)
    _ -> content
  }
}

@internal
pub fn adjust_12_hour_to_24_hour(hour, am am) {
  case am, hour {
    True, _ if hour == 12 -> 0
    True, _ -> hour
    False, _ if hour == 12 -> hour
    False, _ -> hour + 12
  }
}

@internal
pub fn time_difference(from a: Time, to b: Time) -> Duration {
  time_to_nanoseconds(b) - time_to_nanoseconds(a) |> Duration
}

@internal
pub fn time_from_unix_nano_utc(unix_ts: Int) -> Time {
  // Subtract the nanoseconds that are responsible for the date.
  {
    unix_ts
    - { date_to_unix_micro_utc(date_from_unix_micro_utc(unix_ts / 1000)) }
    * 1000
  }
  |> time_from_nanoseconds
}

@internal
pub fn time_to_nanoseconds(time: Time) -> Int {
  { time.hour * unit.hour_nanoseconds }
  + { time.minute * unit.minute_nanoseconds }
  + { time.second * unit.second_nanoseconds }
  + time.nanosecond
}

@internal
pub fn time_from_nanoseconds(nanoseconds: Int) -> Time {
  let in_range_ns = nanoseconds % unit.imprecise_day_nanoseconds

  let adj_ns = case in_range_ns < 0 {
    True -> in_range_ns + unit.imprecise_day_nanoseconds
    False -> in_range_ns
  }

  let hours = adj_ns / 3_600_000_000_000

  let minutes = { adj_ns - hours * 3_600_000_000_000 } / 60_000_000_000

  let seconds =
    { adj_ns - hours * 3_600_000_000_000 - minutes * 60_000_000_000 }
    / 1_000_000_000

  let nanoseconds =
    adj_ns
    - hours
    * 3_600_000_000_000
    - minutes
    * 60_000_000_000
    - seconds
    * 1_000_000_000

  Time(hours, minutes, seconds, nanoseconds)
}

@internal
pub fn time_to_duration(time: Time) -> Duration {
  time_to_nanoseconds(time) |> Duration
}

@internal
pub fn time_compare(a: Time, to b: Time) -> order.Order {
  case a.hour == b.hour {
    True ->
      case a.minute == b.minute {
        True ->
          case a.second == b.second {
            True ->
              case a.nanosecond == b.nanosecond {
                True -> order.Eq
                False ->
                  case a.nanosecond < b.nanosecond {
                    True -> order.Lt
                    False -> order.Gt
                  }
              }
            False ->
              case a.second < b.second {
                True -> order.Lt
                False -> order.Gt
              }
          }
        False ->
          case a.minute < b.minute {
            True -> order.Lt
            False -> order.Gt
          }
      }
    False ->
      case a.hour < b.hour {
        True -> order.Lt
        False -> order.Gt
      }
  }
}

@internal
pub fn time_is_earlier(a: Time, than b: Time) -> Bool {
  time_compare(a, b) == order.Lt
}

@internal
pub fn time_is_earlier_or_equal(a: Time, to b: Time) -> Bool {
  time_compare(a, b) == order.Lt || time_compare(a, b) == order.Eq
}

@internal
pub fn time_is_equal(a: Time, to b: Time) -> Bool {
  time_compare(a, b) == order.Eq
}

@internal
pub fn time_is_later(a: Time, than b: Time) -> Bool {
  time_compare(a, b) == order.Gt
}

@internal
pub fn time_is_later_or_equal(a: Time, to b: Time) -> Bool {
  time_compare(a, b) == order.Gt || time_compare(a, b) == order.Eq
}

@internal
pub fn time_add(a: Time, duration b: Duration) -> Time {
  time_to_nanoseconds(a) + b.nanoseconds |> time_from_nanoseconds
}

@internal
pub fn time_subtract(a: Time, duration b: Duration) -> Time {
  time_to_nanoseconds(a) - b.nanoseconds |> time_from_nanoseconds
}

// -------------------------------------------------------------------------- //
//                            Duration Logic                                  //
// -------------------------------------------------------------------------- //

/// A duration between two times. It represents a range of time values and
/// can be span more than a day. It can be used to calculate the number of
/// days, weeks, hours, minutes, or seconds between two times, but cannot
/// accurately be used to calculate the number of years or months between.
/// 
/// It is also used as the basis for specifying how to increase or decrease
/// a datetime or time value.
pub opaque type Duration {
  Duration(nanoseconds: Int)
}

@internal
pub fn duration(nanoseconds nanoseconds) {
  Duration(nanoseconds)
}

@internal
pub fn duration_get_ns(duration: Duration) {
  duration.nanoseconds
}

@internal
pub fn duration_days(days: Int) -> Duration {
  days |> unit.imprecise_days |> duration
}

@internal
pub fn duration_increase(a: Duration, by b: Duration) -> Duration {
  Duration(a.nanoseconds + b.nanoseconds)
}

@internal
pub fn duration_decrease(a: Duration, by b: Duration) -> Duration {
  Duration(a.nanoseconds - b.nanoseconds)
}

@internal
pub fn duration_absolute(duration: Duration) -> Duration {
  case duration.nanoseconds < 0 {
    True -> -{ duration.nanoseconds } |> Duration
    False -> duration
  }
}

@internal
pub fn duration_as_days(duration: Duration) -> Int {
  duration.nanoseconds |> unit.as_days_imprecise
}

@internal
pub fn duration_as_nanoseconds(duration: Duration) -> Int {
  duration.nanoseconds
}

// -------------------------------------------------------------------------- //
//                             Period Logic                                   //
// -------------------------------------------------------------------------- //

/// A period between two calendar datetimes. It represents a range of
/// datetimes and can be used to calculate the number of days, weeks, months, 
/// or years between two dates. It can also be interated over and datetime 
/// values can be checked for inclusion in the period.
pub opaque type Period {
  DateTimePeriod(start: DateTime, end: DateTime)
  NaiveDateTimePeriod(start: NaiveDateTime, end: NaiveDateTime)
  DatePeriod(start: Date, end: Date)
}

@internal
pub fn period_new(start start, end end) {
  let #(start, end) = case start |> datetime_is_earlier_or_equal(to: end) {
    True -> #(start, end)
    False -> #(end, start)
  }

  DateTimePeriod(start:, end:)
}

@internal
pub fn period_new_naive(start start, end end) {
  let #(start, end) = case
    start |> naive_datetime_is_earlier_or_equal(to: end)
  {
    True -> #(start, end)
    False -> #(end, start)
  }

  NaiveDateTimePeriod(start:, end:)
}

@internal
pub fn period_new_date(start start, end end) {
  let #(start, end) = case start |> date_is_earlier_or_equal(to: end) {
    True -> #(start, end)
    False -> #(end, start)
  }

  DatePeriod(start:, end:)
}

@internal
pub fn period_as_duration(period: Period) -> Duration {
  let #(start_date, end_date, start_time, end_time) =
    period_get_start_and_end_date_and_time(period)

  date_days_apart(start_date, end_date)
  |> duration_days
  |> duration_increase(by: time_difference(end_time, from: start_time))
}

@internal
pub fn period_get_start_and_end_date_and_time(
  period,
) -> #(Date, Date, Time, Time) {
  case period {
    DatePeriod(start, end) -> #(start, end, Time(0, 0, 0, 0), Time(24, 0, 0, 0))
    NaiveDateTimePeriod(start, end) -> #(
      start.date,
      end.date,
      start.time,
      end.time,
    )
    DateTimePeriod(start, end) -> #(
      start.naive.date,
      end.naive.date,
      start.naive.time,
      end.naive.time,
    )
  }
}

@internal
pub fn period_contains_datetime(period: Period, datetime: DateTime) -> Bool {
  case period {
    DateTimePeriod(start, end) ->
      datetime
      |> datetime_is_later_or_equal(to: start)
      && datetime
      |> datetime_is_earlier_or_equal(to: end)

    _ -> period_contains_naive_datetime(period, datetime.naive)
  }
}

@internal
pub fn period_contains_naive_datetime(
  period: Period,
  naive_datetime: NaiveDateTime,
) -> Bool {
  let #(start_date, end_date, start_time, end_time) =
    period_get_start_and_end_date_and_time(period)

  naive_datetime
  |> naive_datetime_is_later_or_equal(NaiveDateTime(start_date, start_time))
  && naive_datetime
  |> naive_datetime_is_earlier_or_equal(NaiveDateTime(end_date, end_time))
}

@internal
pub fn period_comprising_dates(period: Period) -> yielder.Yielder(Date) {
  let #(start_date, end_date): #(Date, Date) = case period {
    DatePeriod(start, end) -> #(start, end)
    NaiveDateTimePeriod(start, end) -> #(start.date, end.date)
    DateTimePeriod(start, end) -> #(start.naive.date, end.naive.date)
  }

  yielder.unfold(from: start_date, with: fn(date) {
    case date |> date_is_earlier_or_equal(to: end_date) {
      True -> yielder.Next(date, date |> date_add(days: 1))
      False -> yielder.Done
    }
  })
}

@internal
pub fn period_comprising_months(period: Period) -> yielder.Yielder(MonthYear) {
  let #(start_date, end_date) = case period {
    DatePeriod(start, end) -> #(start, end)
    NaiveDateTimePeriod(start, end) -> #(
      start |> naive_datetime_get_date,
      end |> naive_datetime_get_date,
    )
    DateTimePeriod(start, end) -> #(
      start |> datetime_get_naive |> naive_datetime_get_date,
      end |> datetime_get_naive |> naive_datetime_get_date,
    )
  }

  yielder.unfold(
    from: MonthYear(start_date.month, start_date.year),
    with: fn(miy: MonthYear) {
      case
        date(miy.year, miy.month, 1)
        |> date_is_earlier_or_equal(to: end_date)
      {
        True ->
          yielder.Next(
            miy,
            MonthYear(miy.month |> month_next, case miy.month == Dec {
              True -> miy.year + 1
              False -> miy.year
            }),
          )
        False -> yielder.Done
      }
    },
  )
}

/// Error values that can be returned from functions in this package.
pub type OffsetParseError {
  OffsetInvalidFormat(msg: String)
  OffsetOutOfBounds
}

pub type TimeParseError {
  TimeInvalidFormat(msg: String)
  TimeOutOfBounds(TimeOutOfBoundsError)
}

pub type TimeOutOfBoundsError {
  TimeHourOutOfBounds
  TimeMinuteOutOfBounds
  TimeSecondOutOfBounds
  TimeNanoSecondOutOfBounds
}

pub type DateParseError {
  DateInvalidFormat(msg: String)
  DateOutOfBounds(DateOutOfBoundsError)
}

pub type DateOutOfBoundsError {
  DateDayOutOfBounds
  DateMonthOutOfBounds
  DateYearOutOfBounds
}

pub type DateTimeOutOfBoundsError {
  DateTimeDateOutOfBounds(DateOutOfBoundsError)
  DateTimeTimeOutOfBounds(TimeOutOfBoundsError)
  DateTimeOffsetOutOfBounds
}

pub type DateTimeParseError {
  DateTimeInvalidFormat
  DateTimeTimeParseError(TimeParseError)
  DateTimeDateParseError(DateParseError)
  DateTimeOffsetParseError(OffsetParseError)
}

pub type NaiveDateTimeOutOfBoundsError {
  NaiveDateTimeDateOutOfBounds(DateOutOfBoundsError)
  NaiveDateTimeTimeOutOfBounds(TimeOutOfBoundsError)
}

pub type NaiveDateTimeParseError {
  NaiveDateTimeInvalidFormat
  NaiveDateTimeTimeParseError(TimeParseError)
  NaiveDateTimeDateParseError(DateParseError)
}

pub type NaiveDateTimeParseAnyError {
  NaiveDateTimeMissingDate
  NaiveDateTimeMissingTime
}

pub type DateTimeParseAnyError {
  DateTimeMissingDate
  DateTimeMissingTime
  DateTimeMissingOffset
}

// -------------------------------------------------------------------------- //
//                          Tempo Module Logic                                //
// -------------------------------------------------------------------------- //

fn offset_replace_format(content: String, offset: Offset) -> String {
  case content {
    "z" ->
      case offset.minutes {
        0 -> "Z"
        _ -> {
          let str_offset = offset |> offset_to_string

          case str_offset |> string.split(":") {
            [hours, "00"] -> hours
            _ -> str_offset
          }
        }
      }
    "Z" -> offset |> offset_to_string
    "ZZ" ->
      offset
      |> offset_to_string
      |> string.replace(":", "")
    _ -> content
  }
}

/// The result of an uncertain conversion. Since this package does not track
/// timezone offsets, it uses the host system's offset to convert to local
/// time. If the datetime being converted to local time is of a different
/// day than the current one, the offset value provided by the host may
/// not be accurate (and could be accurate by up to the amount the offset 
/// changes throughout the year). To account for this, when converting to 
/// local time, a precise value is returned when the datetime being converted
/// is in th current date, while an imprecise value is returned when it is
/// on any other date. This allows the application logic to handle the 
/// two cases differently: some applications may only need to convert to 
/// local time on the current date or may only need generic time 
/// representations, while other applications may need precise conversions 
/// for arbitrary dates. More notes on how to plug time zones into this
/// package to aviod uncertain conversions can be found in the README.
pub type UncertainConversion(a) {
  Precise(a)
  Imprecise(a)
}

/// Accepts either a precise or imprecise value of an uncertain conversion.
/// Useful for pipelines.
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-21T23:17:00Z")
/// |> datetime.to_local
/// |> tempo.accept_imprecision
/// |> datetime.to_text
/// // -> "2024-06-21T19:17:00-04:00"
/// ```
pub fn accept_imprecision(conv: UncertainConversion(a)) -> a {
  case conv {
    Precise(a) -> a
    Imprecise(a) -> a
  }
}

/// Either returns a precise value or an error from an uncertain conversion.
/// Useful for pipelines. 
/// 
/// ## Examples
/// 
/// ```gleam
/// datetime.literal("2024-06-21T23:17:00Z")
/// |> datetime.to_local
/// |> tempo.error_on_imprecision
/// |> result.try(do_important_precise_task)
/// ```
pub fn error_on_imprecision(conv: UncertainConversion(a)) -> Result(a, Nil) {
  case conv {
    Precise(a) -> Ok(a)
    Imprecise(_) -> Error(Nil)
  }
}

@internal
pub const format_regex = "\\[([^\\]]+)\\]|Y{1,4}|M{1,4}|D{1,2}|d{1,4}|H{1,2}|h{1,2}|a|A|m{1,2}|s{1,2}|Z{1,2}|z|SSSSS|SSSS|SSS|."

/// Tries to parse a given date string without a known format. It will not 
/// parse two digit years and will assume the month always comes before the 
/// day in a date. Always prefer to use a module's specific `parse` function
/// when possible.
/// 
/// Using pattern matching, you can explicitly specify what to with the 
/// missing values from the input. Many libaries will assume a missing time
/// value means 00:00:00 or a missing offset means UTC. This design
/// lets the user decide how fallbacks are handled. 
/// 
/// ## Example
/// 
/// ```gleam
/// case tempo.parse_any("06/21/2024 at 01:42:11 PM") {
///   #(Some(date), Some(time), Some(offset)) ->
///     datetime.new(date, time, offset)
/// 
///   #(Some(date), Some(time), None) ->
///     datetime.new(date, time, offset.local())
/// 
///   _ -> datetime.now_local()
/// }
/// // -> datetime.literal("2024-06-21T13:42:11-04:00")
/// ```
/// 
/// ```gleam
/// tempo.parse_any("2024.06.21 11:32 AM -0400")
/// // -> #(
/// //  Some(date.literal("2024-06-21")), 
/// //  Some(time.literal("11:32:00")),
/// //  Some(offset.literal("-04:00"))
/// // )
/// ```
/// 
/// ```gleam
/// tempo.parse_any("Dec 25, 2024 at 6:00 AM")
/// // -> #(
/// //  Some(date.literal("2024-12-25")), 
/// //  Some(time.literal("06:00:00")),
/// //  None
/// // )
/// ```
pub fn parse_any(
  str: String,
) -> #(option.Option(Date), option.Option(Time), option.Option(Offset)) {
  let empty_result = #(None, None, None)

  use serial_re <- result_guard(
    when_error: regexp.from_string("\\d{9,}"),
    return: empty_result,
  )

  use <- bool.guard(when: regexp.check(serial_re, str), return: empty_result)

  use date_re <- result_guard(
    when_error: regexp.from_string(
      "(\\d{4})[-_/\\.\\s,]{0,2}(\\d{1,2})[-_/\\.\\s,]{0,2}(\\d{1,2})",
    ),
    return: empty_result,
  )

  use date_human_re <- result_guard(
    when_error: regexp.from_string(
      "(\\d{1,2}|January|Jan|january|jan|February|Feb|february|feb|March|Mar|march|mar|April|Apr|april|apr|May|may|June|Jun|june|jun|July|Jul|july|jul|August|Aug|august|aug|September|Sep|september|sep|October|Oct|october|oct|November|Nov|november|nov|December|Dec|december|dec)[-_/\\.\\s,]{0,2}(\\d{1,2})(?:st|nd|rd|th)?[-_/\\.\\s,]{0,2}(\\d{4})",
    ),
    return: empty_result,
  )

  use time_re <- result_guard(
    when_error: regexp.from_string(
      "(\\d{1,2})[:_\\.\\s]{0,1}(\\d{1,2})[:_\\.\\s]{0,1}(\\d{0,2})[\\.]{0,1}(\\d{0,9})\\s*(AM|PM|am|pm)?",
    ),
    return: empty_result,
  )

  use offset_re <- result_guard(
    when_error: regexp.from_string("([-+]\\d{2}):{0,1}(\\d{1,2})?"),
    return: empty_result,
  )

  use offset_char_re <- result_guard(
    when_error: regexp.from_string("(?<![a-zA-Z])[Zz](?![a-zA-Z])"),
    return: empty_result,
  )

  let unconsumed = str

  let #(date, unconsumed): #(option.Option(Date), String) = {
    case regexp.scan(date_re, unconsumed) {
      [regexp.Match(content, [Some(year), Some(month), Some(day)]), ..] ->
        case int.parse(year), int.parse(month), int.parse(day) {
          Ok(year), Ok(month), Ok(day) ->
            case new_date(year, month, day) {
              Ok(date) -> #(Some(date), string.replace(unconsumed, content, ""))

              _ -> #(None, unconsumed)
            }

          _, _, _ -> #(None, unconsumed)
        }

      _ -> #(None, unconsumed)
    }
  }

  let #(date, unconsumed): #(option.Option(Date), String) = {
    case date {
      Some(d) -> #(Some(d), unconsumed)
      None ->
        case regexp.scan(date_human_re, unconsumed) {
          [regexp.Match(content, [Some(month), Some(day), Some(year)]), ..] ->
            case
              int.parse(year),
              // Parse an int month or a written month
              int.parse(month)
              |> result.try(month_from_int)
              |> result.try_recover(fn(_) {
                month_from_short_string(month)
                |> result.try_recover(fn(_) { month_from_long_string(month) })
              }),
              int.parse(day)
            {
              Ok(year), Ok(month), Ok(day) ->
                case new_date(year, month_to_int(month), day) {
                  Ok(date) -> #(
                    Some(date),
                    string.replace(unconsumed, content, ""),
                  )

                  _ -> #(None, unconsumed)
                }

              _, _, _ -> #(None, unconsumed)
            }

          _ -> #(None, unconsumed)
        }
    }
  }

  let #(offset, unconsumed): #(option.Option(Offset), String) = {
    case regexp.scan(offset_re, unconsumed) {
      [regexp.Match(content, [Some(hours), Some(minutes)]), ..] ->
        case int.parse(hours), int.parse(minutes) {
          Ok(hour), Ok(minute) ->
            case new_offset(hour * 60 + minute) {
              Ok(offset) -> #(
                Some(offset),
                string.replace(unconsumed, content, ""),
              )

              _ -> #(None, unconsumed)
            }

          _, _ -> #(None, unconsumed)
        }

      _ -> #(None, unconsumed)
    }
  }

  let #(offset, unconsumed): #(option.Option(Offset), String) = {
    case offset {
      Some(o) -> #(Some(o), unconsumed)
      None ->
        case regexp.scan(offset_char_re, unconsumed) {
          [regexp.Match(content, _), ..] -> #(
            Some(utc),
            string.replace(unconsumed, content, ""),
          )

          _ -> #(None, unconsumed)
        }
    }
  }

  let #(time, _): #(option.Option(Time), String) = {
    let scan_results = regexp.scan(time_re, unconsumed)

    let adj_hour = case scan_results {
      [regexp.Match(_, [_, _, _, _, Some("PM")]), ..] -> adjust_12_hour_to_24_hour(
        _,
        am: False,
      )
      [regexp.Match(_, [_, _, _, _, Some("pm")]), ..] -> adjust_12_hour_to_24_hour(
        _,
        am: False,
      )
      [regexp.Match(_, [_, _, _, _, Some("AM")]), ..] -> adjust_12_hour_to_24_hour(
        _,
        am: True,
      )
      [regexp.Match(_, [_, _, _, _, Some("am")]), ..] -> adjust_12_hour_to_24_hour(
        _,
        am: True,
      )
      _ -> fn(hour) { hour }
    }

    case scan_results {
      [regexp.Match(content, [Some(h), Some(m), Some(s), Some(d), ..]), ..] ->
        case int.parse(h), int.parse(m), int.parse(s) {
          Ok(hour), Ok(minute), Ok(second) ->
            case string.length(d), int.parse(d) {
              3, Ok(milli) ->
                case adj_hour(hour) |> new_time_milli(minute, second, milli) {
                  Ok(date) -> #(
                    Some(date),
                    string.replace(unconsumed, content, ""),
                  )

                  _ -> #(None, unconsumed)
                }
              6, Ok(micro) ->
                case adj_hour(hour) |> new_time_micro(minute, second, micro) {
                  Ok(date) -> #(
                    Some(date),
                    string.replace(unconsumed, content, ""),
                  )

                  _ -> #(None, unconsumed)
                }

              9, Ok(nano) ->
                case adj_hour(hour) |> new_time_nano(minute, second, nano) {
                  Ok(date) -> #(
                    Some(date),
                    string.replace(unconsumed, content, ""),
                  )

                  _ -> #(None, unconsumed)
                }

              _, _ -> #(None, unconsumed)
            }

          _, _, _ -> #(None, unconsumed)
        }

      [regexp.Match(content, [Some(h), Some(m), Some(s), ..]), ..] ->
        case int.parse(h), int.parse(m), int.parse(s) {
          Ok(hour), Ok(minute), Ok(second) ->
            case adj_hour(hour) |> new_time(minute, second) {
              Ok(date) -> #(Some(date), string.replace(unconsumed, content, ""))

              _ -> #(None, unconsumed)
            }

          _, _, _ -> #(None, unconsumed)
        }

      [regexp.Match(content, [Some(h), Some(m), ..]), ..] ->
        case int.parse(h), int.parse(m) {
          Ok(hour), Ok(minute) ->
            case adj_hour(hour) |> new_time(minute, 0) {
              Ok(date) -> #(Some(date), string.replace(unconsumed, content, ""))

              _ -> #(None, unconsumed)
            }

          _, _ -> #(None, unconsumed)
        }

      _ -> #(None, unconsumed)
    }
  }

  #(date, time, offset)
}

@internal
pub type DatetimePart {
  Year(Int)
  Month(Int)
  Day(Int)
  Hour(Int)
  Minute(Int)
  Second(Int)
  Millisecond(Int)
  Microsecond(Int)
  Nanosecond(Int)
  OffsetStr(String)
  TwelveHour(Int)
  AMPeriod
  PMPeriod
  Passthrough
}

@internal
pub fn consume_format(str: String, in fmt: String) {
  let assert Ok(re) =
    regexp.from_string(
      "\\[([^\\]]+)\\]|Y{1,4}|M{1,4}|D{1,2}|d{1,4}|H{1,2}|h{1,2}|a|A|m{1,2}|s{1,2}|Z{1,2}|SSS{3,5}|.",
    )

  regexp.scan(re, fmt)
  |> list.fold(from: Ok(#([], str)), with: fn(acc, match) {
    case acc {
      Ok(acc) -> {
        let #(consumed, input) = acc

        let res = case match {
          regexp.Match(content, []) -> consume_part(content, input)

          // If there is a non-empty subpattern, then the escape 
          // character "[ ... ]" matched, so we should not change anything here.
          regexp.Match(_, [Some(sub)]) ->
            Ok(#(Passthrough, string.drop_start(input, string.length(sub))))

          // This case is not expected, not really sure what to do with it 
          // so just pass through whatever was found
          regexp.Match(content, _) ->
            Ok(#(Passthrough, string.drop_start(input, string.length(content))))
        }

        case res {
          Ok(#(part, not_consumed)) -> Ok(#([part, ..consumed], not_consumed))
          Error(err) -> Error(err)
        }
      }
      Error(err) -> Error(err)
    }
  })
}

fn consume_part(fmt, from str) {
  case fmt {
    "YY" -> {
      use val <- result.map(
        string.slice(str, at_index: 0, length: 2) |> int.parse,
      )

      let current_year = current_year()

      let current_century = { current_year / 100 } * 100
      let current_two_year_date = current_year % 100

      case val > current_two_year_date {
        True -> #(
          Year({ current_century - 100 } + val),
          string.drop_start(str, 2),
        )
        False -> #(Year(current_century + val), string.drop_start(str, 2))
      }
    }
    "YYYY" -> {
      use year <- result.map(
        string.slice(str, at_index: 0, length: 4) |> int.parse,
      )

      #(Year(year), string.drop_start(str, 4))
    }
    "M" -> consume_one_or_two_digits(str, Month)
    "MM" -> consume_two_digits(str, Month)
    "MMM" -> {
      case str {
        "Jan" <> rest -> Ok(#(Month(1), rest))
        "Feb" <> rest -> Ok(#(Month(2), rest))
        "Mar" <> rest -> Ok(#(Month(3), rest))
        "Apr" <> rest -> Ok(#(Month(4), rest))
        "May" <> rest -> Ok(#(Month(5), rest))
        "Jun" <> rest -> Ok(#(Month(6), rest))
        "Jul" <> rest -> Ok(#(Month(7), rest))
        "Aug" <> rest -> Ok(#(Month(8), rest))
        "Sep" <> rest -> Ok(#(Month(9), rest))
        "Oct" <> rest -> Ok(#(Month(10), rest))
        "Nov" <> rest -> Ok(#(Month(11), rest))
        "Dec" <> rest -> Ok(#(Month(12), rest))
        _ -> Error(Nil)
      }
    }
    "MMMM" -> {
      case str {
        "January" <> rest -> Ok(#(Month(1), rest))
        "February" <> rest -> Ok(#(Month(2), rest))
        "March" <> rest -> Ok(#(Month(3), rest))
        "April" <> rest -> Ok(#(Month(4), rest))
        "May" <> rest -> Ok(#(Month(5), rest))
        "June" <> rest -> Ok(#(Month(6), rest))
        "July" <> rest -> Ok(#(Month(7), rest))
        "August" <> rest -> Ok(#(Month(8), rest))
        "September" <> rest -> Ok(#(Month(9), rest))
        "October" <> rest -> Ok(#(Month(10), rest))
        "November" <> rest -> Ok(#(Month(11), rest))
        "December" <> rest -> Ok(#(Month(12), rest))
        _ -> Error(Nil)
      }
    }
    "D" -> consume_one_or_two_digits(str, Day)
    "DD" -> consume_two_digits(str, Day)
    "H" -> consume_one_or_two_digits(str, Hour)
    "HH" -> consume_two_digits(str, Hour)
    "h" -> consume_one_or_two_digits(str, TwelveHour)
    "hh" -> consume_two_digits(str, TwelveHour)
    "a" -> {
      case str {
        "am" <> rest -> Ok(#(AMPeriod, rest))
        "pm" <> rest -> Ok(#(PMPeriod, rest))
        _ -> Error(Nil)
      }
    }
    "A" -> {
      case str {
        "AM" <> rest -> Ok(#(AMPeriod, rest))
        "PM" <> rest -> Ok(#(PMPeriod, rest))
        _ -> Error(Nil)
      }
    }
    "m" -> consume_one_or_two_digits(str, Minute)
    "mm" -> consume_two_digits(str, Minute)
    "s" -> consume_one_or_two_digits(str, Second)
    "ss" -> consume_two_digits(str, Second)
    "SSS" -> {
      use milli <- result.map(
        string.slice(str, at_index: 0, length: 3) |> int.parse,
      )

      #(Millisecond(milli), string.drop_start(str, 3))
    }
    "SSSS" -> {
      use micro <- result.map(
        string.slice(str, at_index: 0, length: 6) |> int.parse,
      )

      #(Microsecond(micro), string.drop_start(str, 6))
    }
    "SSSSS" -> {
      use nano <- result.map(
        string.slice(str, at_index: 0, length: 9) |> int.parse,
      )

      #(Nanosecond(nano), string.drop_start(str, 9))
    }
    "z" -> {
      // Offsets can be 1, 3, 5, or 6 characters long. Try parsing from
      // largest to smallest because a small pattern may incorrectly match
      // a subset of a larger value.
      use _ <- result.try_recover(
        string.slice(str, at_index: 0, length: 6)
        |> fn(offset) {
          use re <- result.try(
            regexp.from_string("[-+]\\d\\d:\\d\\d") |> result.replace_error(Nil),
          )

          case regexp.check(re, offset) {
            True -> Ok(offset)
            False -> Error(Nil)
          }
        }
        |> result.map(fn(offset) {
          #(OffsetStr(offset), string.drop_start(str, 6))
        }),
      )

      use _ <- result.try_recover(
        string.slice(str, at_index: 0, length: 5)
        |> fn(offset) {
          use re <- result.try(
            regexp.from_string("[-+]\\d\\d\\d\\d") |> result.replace_error(Nil),
          )

          case regexp.check(re, offset) {
            True -> Ok(offset)
            False -> Error(Nil)
          }
        }
        |> result.map(fn(offset) {
          #(OffsetStr(offset), string.drop_start(str, 5))
        }),
      )

      use _ <- result.try_recover(
        string.slice(str, at_index: 0, length: 3)
        |> fn(offset) {
          use re <- result.try(
            regexp.from_string("[-+]\\d\\d") |> result.replace_error(Nil),
          )

          case regexp.check(re, offset) {
            True -> Ok(offset)
            False -> Error(Nil)
          }
        }
        |> result.map(fn(offset) {
          #(OffsetStr(offset), string.drop_start(str, 3))
        }),
      )

      use _ <- result.try_recover(
        string.slice(str, at_index: 0, length: 1)
        |> fn(offset) {
          case offset == "Z" || offset == "z" {
            True -> Ok(offset)
            False -> Error(Nil)
          }
        }
        |> result.map(fn(offset) {
          #(OffsetStr(offset), string.drop_start(str, 1))
        }),
      )

      Error(Nil)
    }
    "Z" -> {
      Ok(#(
        OffsetStr(string.slice(str, at_index: 0, length: 6)),
        string.drop_start(str, 6),
      ))
    }
    "ZZ" -> {
      Ok(#(
        OffsetStr(string.slice(str, at_index: 0, length: 5)),
        string.drop_start(str, 5),
      ))
    }
    passthrough -> {
      let fmt_length = string.length(passthrough)
      let str_slice = string.slice(str, at_index: 0, length: fmt_length)

      case str_slice == passthrough {
        True -> Ok(#(Passthrough, string.drop_start(str, fmt_length)))
        False -> Error(Nil)
      }
    }
  }
  |> result.map_error(fn(_) { "Unable to parse directive " <> fmt })
}

fn consume_one_or_two_digits(str, constructor) {
  case string.slice(str, at_index: 0, length: 2) |> int.parse {
    Ok(val) -> Ok(#(constructor(val), string.drop_start(str, 2)))
    Error(_) ->
      case string.slice(str, at_index: 0, length: 1) |> int.parse {
        Ok(val) -> Ok(#(constructor(val), string.drop_start(str, 1)))
        Error(_) -> Error(Nil)
      }
  }
}

fn consume_two_digits(str, constructor) {
  use val <- result.map(string.slice(str, at_index: 0, length: 2) |> int.parse)

  #(constructor(val), string.drop_start(str, 2))
}

@internal
pub fn find_date(in parts) {
  use year <- result.try(
    list.find_map(parts, fn(p) {
      case p {
        Year(y) -> Ok(y)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(DateInvalidFormat("Missing year")),
  )

  use month <- result.try(
    list.find_map(parts, fn(p) {
      case p {
        Month(m) -> Ok(m)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(DateInvalidFormat("Missing month")),
  )

  use day <- result.try(
    list.find_map(parts, fn(p) {
      case p {
        Day(d) -> Ok(d)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(DateInvalidFormat("Missing day")),
  )

  new_date(year, month, day)
  |> result.map_error(fn(e) { DateOutOfBounds(e) })
}

@internal
pub fn find_time(in parts) {
  use hour <- result.try({
    use _ <- result.try_recover(
      list.find_map(parts, fn(p) {
        case p {
          Hour(h) -> Ok(h)
          _ -> Error(Nil)
        }
      }),
    )

    use twelve_hour <- result.try(
      list.find_map(parts, fn(p) {
        case p {
          TwelveHour(o) -> Ok(o)
          _ -> Error(Nil)
        }
      })
      |> result.replace_error(TimeInvalidFormat("Missing hour")),
    )

    let am_period =
      list.find_map(parts, fn(p) {
        case p {
          AMPeriod -> Ok(Nil)
          _ -> Error(Nil)
        }
      })

    let pm_period =
      list.find_map(parts, fn(p) {
        case p {
          PMPeriod -> Ok(Nil)
          _ -> Error(Nil)
        }
      })

    case am_period, pm_period {
      Ok(Nil), Error(Nil) ->
        adjust_12_hour_to_24_hour(twelve_hour, am: True) |> Ok
      Error(Nil), Ok(Nil) ->
        adjust_12_hour_to_24_hour(twelve_hour, am: False) |> Ok

      _, _ -> Error(TimeInvalidFormat("Missing period in 12 hour time"))
    }
  })

  use minute <- result.try(
    list.find_map(parts, fn(p) {
      case p {
        Minute(m) -> Ok(m)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(TimeInvalidFormat("Missing minute")),
  )

  let second =
    list.find_map(parts, fn(p) {
      case p {
        Second(s) -> Ok(s)
        _ -> Error(Nil)
      }
    })
    |> result.unwrap(0)

  let millisecond =
    list.find_map(parts, fn(p) {
      case p {
        Millisecond(n) -> Ok(n)
        _ -> Error(Nil)
      }
    })

  let microsecond =
    list.find_map(parts, fn(p) {
      case p {
        Microsecond(n) -> Ok(n)
        _ -> Error(Nil)
      }
    })

  let nanosecond =
    list.find_map(parts, fn(p) {
      case p {
        Nanosecond(n) -> Ok(n)
        _ -> Error(Nil)
      }
    })

  case nanosecond, microsecond, millisecond {
    Ok(nano), _, _ -> new_time_nano(hour, minute, second, nano)
    _, Ok(micro), _ -> new_time_micro(hour, minute, second, micro)
    _, _, Ok(milli) -> new_time_milli(hour, minute, second, milli)
    _, _, _ -> new_time(hour, minute, second)
  }
  |> result.map_error(fn(e) { TimeOutOfBounds(e) })
}

@internal
pub fn find_offset(in parts) {
  use offset_str <- result.try(
    list.find_map(parts, fn(p) {
      case p {
        OffsetStr(o) -> Ok(o)
        _ -> Error(Nil)
      }
    })
    |> result.replace_error(OffsetInvalidFormat("Missing offset")),
  )

  offset_from_string(offset_str)
}

fn result_guard(when_error e, return v, or run) {
  case e {
    Error(_) -> v
    Ok(ok) -> run(ok)
  }
}

// -------------------------------------------------------------------------- //
//                              FFI Logic                                     //
// -------------------------------------------------------------------------- //

@external(erlang, "tempo_ffi", "now")
@external(javascript, "./tempo_ffi.mjs", "now")
@internal
pub fn now_utc_ffi() -> Int

@external(erlang, "tempo_ffi", "now_monotonic")
@external(javascript, "./tempo_ffi.mjs", "now_monotonic")
@internal
pub fn now_monotonic_ffi() -> Int

@external(erlang, "tempo_ffi", "now_unique")
@external(javascript, "./tempo_ffi.mjs", "now_unique")
@internal
pub fn now_unique_ffi() -> Int

@internal
pub fn offset_local_nano() -> Int {
  offset_local_minutes() * 60_000_000_000
}

@external(erlang, "tempo_ffi", "local_offset")
@external(javascript, "../tempo_ffi.mjs", "local_offset")
@internal
pub fn offset_local_minutes() -> Int

@external(erlang, "tempo_ffi", "current_year")
@external(javascript, "./tempo_ffi.mjs", "current_year")
fn current_year() -> Int
