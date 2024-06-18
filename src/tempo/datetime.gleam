import gleam/result
import gleam/string
import tempo
import tempo/date
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
  datetime
  |> add(offset.to_duration(datetime.offset))
  |> drop_offset
}

pub fn to_utc(datetime: tempo.DateTime) -> tempo.DateTime {
  datetime
  |> add(offset.to_duration(datetime.offset))
  |> drop_offset
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

/// Do not use this function in conjuction with `to_current_local_date` to 
/// convert an arbitrary datetime to a local date! This will not account for
/// timezones with variable offsets (daylight savings time) and could
/// be incorrect for any date other than the current! Use `to_current_local`
/// to convert a datetime to a local datetime safely (when it is on the same
/// day as the current local time).
pub fn to_current_local_time(datetime: tempo.DateTime) -> tempo.Time {
  datetime
  |> to_offset(offset.local())
  |> get_time
}

/// Do not use this function in conjuction with `to_current_local_date` to 
/// convert an arbitrary datetime to a local date! This will not account for
/// timezones with variable offsets (daylight savings time) and could
/// be incorrect for any date other than the current! Use `to_current_local`
/// to convert a datetime to a local datetime safely (when it is on the same
/// day as the current local time).
pub fn to_current_local_date(datetime: tempo.DateTime) -> tempo.Date {
  datetime
  |> to_offset(offset.local())
  |> get_date
}

pub fn add(
  datetime: tempo.DateTime,
  duration duration_to_add: tempo.Duration,
) -> tempo.DateTime {
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

pub fn compare(a: tempo.DateTime, to b: tempo.DateTime) {
  apply_offset(a) |> naive_datetime.compare(to: apply_offset(b))
}
