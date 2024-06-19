import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import tempo
import tempo/date
import tempo/internal/unit
import tempo/month
import tempo/naive_datetime
import tempo/offset
import tempo/time

pub type DateTimeError {
  UncertainConversion(String)
}

pub fn new(
  date date: tempo.Date,
  time time: tempo.Time,
  offset offset: tempo.Offset,
) -> tempo.DateTime {
  tempo.DateTime(naive_datetime.new(date, time), offset: offset)
}

pub fn now_utc() -> tempo.DateTime {
  new(date.current_utc(), time.now_utc(), offset.utc)
}

pub fn now_local() -> tempo.DateTime {
  new(date.current_local(), time.now_local(), offset.local())
}

pub fn literal(datetime: String) -> tempo.DateTime {
  case from_string(datetime) {
    Ok(datetime) -> datetime
    Error(Nil) -> panic as "Invalid datetime literal"
  }
}

/// Accepts datetimes in the formats `YYYY-MM-DDThh:mm:ss.sTZD`,
/// `YYYYMMDDThhmmss.sTZD`, `YYYY-MM-DD`, or `YYYYMMDD`.
pub fn from_string(datetime: String) -> Result(tempo.DateTime, Nil) {
  case string.split(datetime, "T") {
    [date, time] -> {
      use date: tempo.Date <- result.try(date.from_string(date))

      use #(time, offset): #(String, String) <- result.try(
        split_time_and_offset(time),
      )

      use time: tempo.Time <- result.try(time.from_string(time))
      use offset: tempo.Offset <- result.map(offset.from_string(offset))

      new(date, time, offset)
    }

    [date] ->
      date.from_string(date)
      |> result.map(new(_, tempo.Time(0, 0, 0, 0), offset.utc))

    _ -> Error(Nil)
  }
}

pub fn from_unix_utc(unix_ts: Int) -> tempo.DateTime {
  new(date.from_unix_utc(unix_ts), time.from_unix_utc(unix_ts), offset.utc)
}

pub fn from_unix_milli_utc(unix_ts: Int) -> tempo.DateTime {
  new(
    date.from_unix_milli_utc(unix_ts),
    time.from_unix_milli_utc(unix_ts),
    offset.utc,
  )
}

fn split_time_and_offset(
  time_with_offset: String,
) -> Result(#(String, String), Nil) {
  case string.slice(time_with_offset, at_index: -1, length: 1) {
    "Z" -> #(string.drop_right(time_with_offset, 1), "Z") |> Ok
    "z" -> #(string.drop_right(time_with_offset, 1), "Z") |> Ok
    _ ->
      case string.split(time_with_offset, "-") {
        [time, offset] -> #(time, "-" <> offset) |> Ok
        _ ->
          case string.split(time_with_offset, "+") {
            [time, offset] -> #(time, "+" <> offset) |> Ok
            _ -> Error(Nil)
          }
      }
  }
}

pub fn to_string(datetime: tempo.DateTime) -> String {
  datetime.naive |> naive_datetime.to_string
  <> case datetime.offset.minutes {
    0 -> "Z"
    _ -> datetime.offset |> offset.to_string
  }
}

pub fn get_date(datetime: tempo.DateTime) -> tempo.Date {
  datetime.naive.date
}

pub fn get_time(datetime: tempo.DateTime) -> tempo.Time {
  datetime.naive.time
}

pub fn get_offset(datetime: tempo.DateTime) -> tempo.Offset {
  datetime.offset
}

pub fn drop_offset(datetime: tempo.DateTime) -> tempo.NaiveDateTime {
  datetime.naive
}

pub fn drop_time(datetime: tempo.DateTime) -> tempo.DateTime {
  tempo.DateTime(
    naive_datetime.drop_time(datetime.naive),
    offset: datetime.offset,
  )
}

pub fn apply_offset(datetime: tempo.DateTime) -> tempo.NaiveDateTime {
  case datetime.offset == offset.utc {
    // Leave the naive datetime as is to preserve the potential leapsecond
    True -> datetime.naive
    False ->
      datetime
      |> add(offset.to_duration(datetime.offset))
      |> drop_offset
  }
}

pub fn to_utc(datetime: tempo.DateTime) -> tempo.DateTime {
  datetime
  |> apply_offset
  |> naive_datetime.set_offset(offset.utc)
}

pub fn to_offset(
  datetime: tempo.DateTime,
  offset: tempo.Offset,
) -> tempo.DateTime {
  datetime
  |> to_utc
  |> subtract(offset.to_duration(offset))
  |> drop_offset
  |> naive_datetime.set_offset(offset)
}

/// Do not use this function in conjuction with `to_current_local_date` to 
/// convert an arbitrary datetime to a local date! This will not account for
/// timezones with variable offsets (daylight savings time) and could
/// be incorrect for any date other than the current! Use `to_current_local`
/// to convert a datetime to a local datetime safely (when it is on the same
/// day as the current local time).
pub fn to_current_local(
  datetime: tempo.DateTime,
) -> Result(tempo.DateTime, DateTimeError) {
  let local_dt = datetime |> to_offset(offset.local())

  case local_dt.naive.date == date.current_local() {
    True -> Ok(local_dt)
    False ->
      Error(UncertainConversion(
        "Converting a datetime to the local system time with a date "
        <> "other than the current system date can be incorrect for other "
        <> "dates in this timezone. The system knows the the timezone (and "
        <> "can set the offset for the current date correctly), but this "
        <> "package does not and is unable confidently use the correct offset "
        <> "for any other date.",
      ))
  }
}

pub fn compare(a: tempo.DateTime, to b: tempo.DateTime) {
  apply_offset(a) |> naive_datetime.compare(to: apply_offset(b))
}

pub fn is_earlier(a: tempo.DateTime, than b: tempo.DateTime) -> Bool {
  compare(a, b) == order.Lt
}

pub fn is_earlier_or_equal(a: tempo.DateTime, to b: tempo.DateTime) -> Bool {
  compare(a, b) == order.Lt || compare(a, b) == order.Eq
}

pub fn is_equal(a: tempo.DateTime, to b: tempo.DateTime) -> Bool {
  compare(a, b) == order.Eq
}

pub fn is_later(a: tempo.DateTime, than b: tempo.DateTime) -> Bool {
  compare(a, b) == order.Gt
}

pub fn is_later_or_equal(a: tempo.DateTime, to b: tempo.DateTime) -> Bool {
  compare(a, b) == order.Gt || compare(a, b) == order.Eq
}

pub fn difference(from a: tempo.DateTime, to b: tempo.DateTime) -> tempo.Period {
  apply_offset(a) |> naive_datetime.difference(to: apply_offset(b))
}

pub fn to_period(
  start start: tempo.DateTime,
  end end: tempo.DateTime,
) -> tempo.Period {
  apply_offset(start) |> naive_datetime.to_period(end: apply_offset(end))
}

pub fn add(
  datetime: tempo.DateTime,
  duration duration_to_add: tempo.Duration,
) -> tempo.DateTime {
  // todo as "if this hour has a leap second, then it will have to be added"
  datetime
  |> drop_offset
  |> naive_datetime.add(duration: duration_to_add)
  |> naive_datetime.set_offset(datetime.offset)
}

pub fn subtract(
  datetime: tempo.DateTime,
  duration duration_to_subtract: tempo.Duration,
) -> tempo.DateTime {
  datetime
  |> drop_offset
  |> naive_datetime.subtract(duration: duration_to_subtract)
  |> naive_datetime.set_offset(datetime.offset)
}

/// Gets the time left in the day.
/// Cannot account for leap seconds in a day because the leap second is 
/// applied to a specific UTC time and a naive datetime does not know what
/// it is in equivalent UTC time. If you want the time left in a specific 
/// date (including leap seconds), use the `datetime` module instead.
/// 
/// ## Example
///
/// ```gleam
/// naive_datetime.literal("2024-06-30T23:59:03") 
/// |> naive_datetime.left_in_day_imprecise
/// // -> time.literal("00:00:57")
/// ```
///
/// ```gleam
/// naive_datetime.literal("2015-06-30T23:59:03") 
/// |> naive_datetime.left_in_day_imprecise
/// // -> time.literal("00:00:58")
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-18T08:05:20")
/// |> naive_datetime.left_in_day_imprecise
/// // -> time.literal("15:54:40")
/// ```
pub fn time_left_in_day(datetime: tempo.DateTime) -> tempo.Time {
  let new_time =
    unit.imprecise_day_nanoseconds
    + leap_seconds_in_utc_day(datetime.naive.date)
    - { datetime.naive.time |> time.to_nanoseconds }
    |> time.from_nanoseconds

  // Restore original time precision
  case datetime.naive.time {
    tempo.Time(_, _, _, _) -> time.to_second_precision(new_time)
    tempo.TimeMilli(_, _, _, _) -> time.to_milli_precision(new_time)
    tempo.TimeMicro(_, _, _, _) -> time.to_micro_precision(new_time)
    tempo.TimeNano(_, _, _, _) -> time.to_nano_precision(new_time)
  }
}

@internal
pub fn total_ns_in_day(datetime: tempo.DateTime) -> Int {
  todo
  unit.imprecise_day_nanoseconds
  + { datetime |> to_utc |> get_date |> leap_seconds_in_utc_day }
}

@internal
pub fn leap_seconds_in_utc_day(utc_date utc_date: tempo.Date) -> Int {
  // Leap seconds have only been added to the last day of the month.
  case utc_date.day == month.days(of: utc_date.month, in: utc_date.year) {
    True -> month.leap_seconds(of: utc_date.month, in: utc_date.year)
    False -> 0
  }
}

fn get_announced_leap_seconds() -> List(tempo.DateTime) {
  [
    literal("1972-06-30T23:59:60Z"),
    literal("1972-12-31T23:59:60Z"),
    literal("1973-12-31T23:59:60Z"),
    literal("1974-12-31T23:59:60Z"),
    literal("1975-12-31T23:59:60Z"),
    literal("1976-12-31T23:59:60Z"),
    literal("1977-12-31T23:59:60Z"),
    literal("1978-12-31T23:59:60Z"),
    literal("1979-12-31T23:59:60Z"),
    literal("1981-06-30T23:59:60Z"),
    literal("1982-06-30T23:59:60Z"),
    literal("1983-06-30T23:59:60Z"),
    literal("1985-06-30T23:59:60Z"),
    literal("1987-12-31T23:59:60Z"),
    literal("1989-12-31T23:59:60Z"),
    literal("1990-12-31T23:59:60Z"),
    literal("1992-06-30T23:59:60Z"),
    literal("1993-06-30T23:59:60Z"),
    literal("1994-06-30T23:59:60Z"),
    literal("1995-12-31T23:59:60Z"),
    literal("1997-06-30T23:59:60Z"),
    literal("1998-12-31T23:59:60Z"),
    literal("2005-12-31T23:59:60Z"),
    literal("2008-12-31T23:59:60Z"),
    literal("2012-06-30T23:59:60Z"),
    literal("2015-06-30T23:59:60Z"),
    literal("2016-12-31T23:59:60Z"),
  ]
}

@internal
pub fn hour_contains_leap_second(datetime: tempo.DateTime) -> Bool {
  let utc_dt = datetime |> to_utc

  let applicable_leap_second =
    list.find(get_announced_leap_seconds(), fn(leap_second) {
      let lower_hour_bound =
        tempo.Time(leap_second.naive.time.hour, 0, 0, 0)
        |> tempo.NaiveDateTime(leap_second.naive.date, _)
        |> tempo.DateTime(leap_second.offset)

      io.debug(lower_hour_bound |> to_string)
      io.debug(utc_dt |> to_string)
      io.debug(leap_second |> to_string)
      io.debug(utc_dt |> is_later_or_equal(to: lower_hour_bound))
      io.debug(utc_dt |> is_earlier_or_equal(to: leap_second))

      utc_dt |> is_later_or_equal(to: lower_hour_bound)
      && utc_dt |> is_earlier_or_equal(to: leap_second)
    })

  case applicable_leap_second {
    Ok(_) -> True
    Error(_) -> False
  }
}

pub fn get_leap_second(datetime: tempo.DateTime) -> tempo.DateTime {
  todo
}
