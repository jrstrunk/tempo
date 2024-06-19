import gleam/bool
import gleam/order
import gleam/result
import gleam/string
import tempo
import tempo/date
import tempo/duration
import tempo/internal/unit
import tempo/offset
import tempo/time

pub fn new(date: tempo.Date, time: tempo.Time) -> tempo.NaiveDateTime {
  tempo.NaiveDateTime(date, time)
}

pub fn literal(naive_datetime: String) -> tempo.NaiveDateTime {
  case from_string(naive_datetime) {
    Ok(naive_datetime) -> naive_datetime
    Error(Nil) -> panic as "Invalid naive datetime literal"
  }
}

/// Accepts naive datetimes in the formats `YYYY-MM-DDThh:mm:ss.s`,
/// `YYYY-MM-DD hh:mm:ss.s`, `YYYY-MM-DD`, `YYYY-M-D`, `YYYY/MM/DD`, 
/// `YYYY/M/D`, `YYYY.MM.DD`, `YYYY.M.D`, `YYYY_MM_DD`, `YYYY_M_D`, 
/// `YYYY MM DD`, `YYYY M D`, or `YYYYMMDD`.
pub fn from_string(datetime: String) -> Result(tempo.NaiveDateTime, Nil) {
  use _ <- result.try_recover(case string.split(datetime, "T") {
    [date, time] -> {
      use date: tempo.Date <- result.try(date.from_string(date))
      use time: tempo.Time <- result.map(time.from_string(time))
      tempo.NaiveDateTime(date, time)
    }
    [date] -> {
      use date: tempo.Date <- result.map(date.from_string(date))
      tempo.NaiveDateTime(date, tempo.Time(0, 0, 0, 0))
    }
    _ -> Error(Nil)
  })

  case string.split(datetime, " ") {
    [date, time] -> {
      use date: tempo.Date <- result.try(date.from_string(date))
      use time: tempo.Time <- result.map(time.from_string(time))
      tempo.NaiveDateTime(date, time)
    }
    [date] -> {
      use date: tempo.Date <- result.map(date.from_string(date))
      tempo.NaiveDateTime(date, tempo.Time(0, 0, 0, 0))
    }
    _ -> Error(Nil)
  }
}

pub fn to_string(datetime: tempo.NaiveDateTime) -> String {
  datetime.date
  |> date.to_string
  <> "T"
  <> datetime.time
  |> time.to_string
}

pub fn to_utc(datetime: tempo.NaiveDateTime) -> tempo.DateTime {
  set_offset(datetime, offset.utc)
}

pub fn get_date(datetime: tempo.NaiveDateTime) -> tempo.Date {
  datetime.date
}

pub fn get_time(datetime: tempo.NaiveDateTime) -> tempo.Time {
  datetime.time
}

pub fn drop_time(datetime: tempo.NaiveDateTime) -> tempo.NaiveDateTime {
  tempo.NaiveDateTime(datetime.date, tempo.Time(0, 0, 0, 0))
}

pub fn set_offset(
  datetime: tempo.NaiveDateTime,
  offset: tempo.Offset,
) -> tempo.DateTime {
  tempo.DateTime(naive: datetime, offset: offset)
}

pub fn set_time(datetime: tempo.NaiveDateTime, time: tempo.Time) -> tempo.NaiveDateTime {
  tempo.NaiveDateTime(datetime.date, time)
}

pub fn compare(a: tempo.NaiveDateTime, to b: tempo.NaiveDateTime) {
  case date.compare(a.date, b.date) {
    order.Eq -> time.compare(a.time, b.time)
    od -> od
  }
}

pub fn is_earlier(a: tempo.NaiveDateTime, than b: tempo.NaiveDateTime) -> Bool {
  compare(a, b) == order.Lt
}

pub fn is_earlier_or_equal(
  a: tempo.NaiveDateTime,
  to b: tempo.NaiveDateTime,
) -> Bool {
  compare(a, b) == order.Lt || compare(a, b) == order.Eq
}

pub fn is_equal(a: tempo.NaiveDateTime, to b: tempo.NaiveDateTime) -> Bool {
  compare(a, b) == order.Eq
}

pub fn is_later(a: tempo.NaiveDateTime, than b: tempo.NaiveDateTime) -> Bool {
  compare(a, b) == order.Gt
}

pub fn is_later_or_equal(
  a: tempo.NaiveDateTime,
  to b: tempo.NaiveDateTime,
) -> Bool {
  compare(a, b) == order.Gt || compare(a, b) == order.Eq
}

pub fn difference(
  from a: tempo.NaiveDateTime,
  to b: tempo.NaiveDateTime,
) -> tempo.Period {
  to_period(a, b)
}

pub fn to_period(
  start start: tempo.NaiveDateTime,
  end end: tempo.NaiveDateTime,
) -> tempo.Period {
  let #(start, end) = case start |> is_earlier_or_equal(to: end) {
    True -> #(start, end)
    False -> #(end, start)
  }

  tempo.Period(start, end)
}

/// Will not account for leap seconds, TODO needs to be addded
pub fn add(
  datetime: tempo.NaiveDateTime,
  duration duration_to_add: tempo.Duration,
) -> tempo.NaiveDateTime {
  // Positive date overflows are only handled in this function, while negative
  // date overflows are only handled in the subtract function -- so if the 
  // duration is negative, we can just subtract the absolute value of it.
  use <- bool.lazy_guard(when: duration_to_add.nanoseconds < 0, return: fn() {
    datetime |> subtract(duration.absolute(duration_to_add))
  })

  let days_to_add: Int = duration.as_days(duration_to_add)
  let time_to_add: tempo.Duration =
    duration.decrease(duration_to_add, by: duration.days(days_to_add))

  let new_time_as_ns =
    datetime.time
    |> time.to_duration
    |> duration.increase(by: time_to_add)
    |> duration.as_nanoseconds

  // If the time to add crossed a day boundary, add an extra day to the 
  // number of days to add and adjust the time to add.
  let #(new_time_as_ns, days_to_add): #(Int, Int) = case
    new_time_as_ns
    >= unit.imprecise_day_nanoseconds
  {
    True -> #(new_time_as_ns - unit.imprecise_day_nanoseconds, days_to_add + 1)
    False -> #(new_time_as_ns, days_to_add)
  }

  let time_to_add =
    duration.nanoseconds(new_time_as_ns - time.to_nanoseconds(datetime.time))

  let new_date = datetime.date |> date.add(days: days_to_add)
  let new_time = datetime.time |> time.add(duration: time_to_add)

  tempo.NaiveDateTime(new_date, new_time)
}

/// Will not account for leap seconds, TODO needs to be addded
pub fn subtract(
  datetime: tempo.NaiveDateTime,
  duration duration_to_subtract: tempo.Duration,
) -> tempo.NaiveDateTime {
  // Negative date overflows are only handled in this function, while positive
  // date overflows are only handled in the add function -- so if the 
  // duration is negative, we can just add the absolute value of it.
  use <- bool.lazy_guard(
    when: duration_to_subtract.nanoseconds < 0,
    return: fn() { datetime |> add(duration.absolute(duration_to_subtract)) },
  )

  let days_to_sub: Int = duration.as_days(duration_to_subtract)
  let time_to_sub: tempo.Duration =
    duration.decrease(duration_to_subtract, by: duration.days(days_to_sub))

  let new_time_as_ns =
    datetime.time
    |> time.to_duration
    |> duration.decrease(by: time_to_sub)
    |> duration.as_nanoseconds

  // If the time to subtract crossed a day boundary, add an extra day to the 
  // number of days to subtract and adjust the time to subtract.
  let #(new_time_as_ns, days_to_sub) = case new_time_as_ns < 0 {
    True -> #(new_time_as_ns + unit.imprecise_day_nanoseconds, days_to_sub + 1)
    False -> #(new_time_as_ns, days_to_sub)
  }

  let time_to_sub =
    duration.nanoseconds(time.to_nanoseconds(datetime.time) - new_time_as_ns)

  // Using the proper subtract functions here to modify the date and time
  // values instead of declaring a new date is important for perserving date 
  // correctness and time precision.
  let new_date = datetime.date |> date.subtract(days: days_to_sub)
  let new_time = datetime.time |> time.subtract(duration: time_to_sub)

  tempo.NaiveDateTime(new_date, new_time)
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
/// // -> time.literal("00:00:57")
/// ```
/// 
/// ```gleam
/// naive_datetime.literal("2024-06-18T08:05:20")
/// |> naive_datetime.left_in_day_imprecise
/// // -> time.literal("15:54:40")
/// ```
pub fn left_in_day_imprecise(naive_datetime: tempo.NaiveDateTime) -> tempo.Time {
  naive_datetime.time |> time.left_in_day_imprecise
}
