# Tempo

A lightweight and Gleamy datetime library!

Only run a task past a certain time of day, only accept submissions since a certain date, calculate the difference beteen times and dates, time long running tasks, parse and stringify datetimes, and more! Over 400 unit tests, contributions welcome!

Written in almost pure Gleam, Tempo tries to optimize for the same thing the Gleam language does: explicitness over terseness and simplicity over convenience. My hope is to make Tempo feel like the Gleam language and to make it as difficult to write time related bugs as possible.

Supports both the Erlang and JavaScript targets.

## Installation

```sh
gleam add gtempo
```

Supports timezones only through the `gtz` package. Add it with:

```sh
gleam add gtz
```

[![Package Version](https://img.shields.io/hexpm/v/tempo)](https://hex.pm/packages/gtempo)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gtempo/)

#### Parsing and Formatting

```gleam
import tempo
import tempo/datetime

pub fn main() {
  tempo.parse_any("Dec 25, 2024 at 1:00 PM")
  // -> Ok(#(Some(date), Some(time), None))

  datetime.literal("2024-12-25T06:00:00Z")
  |> datetime.format("ddd @ h:mm A")
  // -> "Fri @ 6:00 AM"

  date.parse("03/02/1998", "DD/MM/YYYY")
  // -> Ok(date.literal("1998-02-03"))
}
```

#### Serializing DateTimes

If you need to send a datetime value outside of Gleam, then need to parse it back into a datetime value later, prefer using the `datetime.serialize` function.

```gleam
import tempo/datetime
import tempo/moment
import tempo
import dynamic

pub fn main() {
  // The `moment.as_datetime` call drops monotonic and unique time
  let my_dt: DateTime = tempo.now_local() |> moment.as_datetime

  let assert Ok(external_dt) =
    datetime.serialize(my_dt)
    // send somewhere external, then retrieve it
    |> dynamic.from
    |> datetime.from_dynamic_string

  my_dt == external_dt
  // -> True

  let assert Ok(faulty_external_dt) =
    datetime.to_text(my_dt)
    // send somewhere external, then retrieve it
    |> dynamic.from
    |> datetime.from_dynamic_string

  my_dt == faulty_external_dt
  // -> False, because sub-millisecond precision was lost
}
```

#### Time Zone Conversion

```gleam
import gtz
import tempo/datetime

pub fn main() {
  let assert Ok(local_tz) = gtz.local_name() |> gtz.timezone

  datetime.from_unix_utc(1_729_257_776)
  |> datetime.to_timezone(local_tz)
  |> datetime.to_text
  |> io.println

  let assert Ok(tz) = gtz.timezone("America/New_York")

  datetime.literal("2024-01-03T05:30:02.334Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_text
  |> io.println
}
// -> "2024-10-18T14:22:56.000+01:00"
// -> "2024-01-03T00:30:02.334-05:00"
```

#### Time-Based Logical Branching and Logging

```gleam
import gleam/int
import gleam/io
import tempo
import tempo/date
import tempo/datetime
import tempo/duration
import tempo/time

pub fn main() {
  io.println(datetime.now_text() <> " booting up!")

  let target_time = time.literal("07:50:00")

  // This is monotonic time
  let timer = duration.start_monotonic()

  case tempo.is_time_later(than: target_time) {
    True -> {
      io.println(
        "We are late by "
        <> tempo.time_since(target_time)
        |> duration.as_minutes
        |> int.to_string
        <> " minutes! This should take until "
        <> tempo.now_utc_adjusted(by: duration.minutes(16))
        |> datetime.format("h:mm a"),
        <> " UTC",
      )

      run_rushed_task(for: date.current_local())
    }

    False -> {
      io.println(
        "No rush :) This should take until "
        <> tempo.now_utc_adjusted(by: duration.hours(3))
        |> datetime.format("h:mm a"),
      )

      run_long_task(for: date.current_local())
    }
  }

  io.println("Phew, that only took " <> duration.since(timer))
}

// -> 2024-06-21 08:06:54.279 booting up!
// -> We are late by 16 minutes! This should take until 9:30 PM
// -> Phew, that only took 978 microseconds
```

#### Iterating Over a Date Range

```gleam
import gleam/iterator
import tempo/date
import tempo/period

pub fn main() {
  date.literal("2024-06-21")
  |> date.difference(from: date.literal("2024-06-24"))
  |> period.comprising_dates
  |> iterator.to_list
  // -> [2024-06-21, 2024-06-22, 2024-06-23, 2024-06-24]

  date.literal("2024-06-21")
  |> date.difference(from: date.literal("2024-07-08"))
  |> period.comprising_months
  |> iterator.to_list
  // -> [tempo.Jun, tempo.Jul]
}
```

#### Waiting Until a Specific Time

```gleam
import gleam/erlang/process
import tempo/duration
import tempo/time

pub fn main() {
  // Sleep until 8:25 if we start before then.
  time.now_local()
  |> time.until(time.literal("08:25:00"))
  |> duration.as_milliseconds
  |> process.sleep

  // Now that it is 8:25, do what we need to do.
  "Hello, world!"
}
```

Further documentation can be found at <https://hexdocs.pm/gtempo>.

## Time Zone and Leap Second Considerations

This package purposefully **ignores leap seconds** and **will not convert between time zones unless given a timezone provider**. Try to design your application so time zones do not have to be converted between and leap seconds are trivial. More below.

Both time zones and leap seconds require maintaining a manually updated database of location offsets and leap seconds. This burdens any application that uses them to keep their dependencies up to date and burdens the package by either invalidating all previous versions when an update needs to be made or providing hot timezone data updates.

If at all possible, try to design your application so that time zones do not have to be converted between. Client machines should have information about their time zone offset that can be polled and used for current time time zone conversions. This package will allow you to convert between local time and UTC time on the same date as the system date natively.

Since this package ignores leap seconds, historical leap seconds are ignored when doing comparisons and durations. Please keep this in mind when designing your applications. Leap seconds can still be parsed from ISO 8601 strings and will be compared correctly to other times, but will not be preserved when converting to any other time representation (including changing the offset).

When getting the system time, leap second accounting depends on the host's time implementation.

If you must, to convert between time zones with this package, use a separate time zone provider package like `gtz`:

```gleam
import tempo/datetime
import gtz

pub fn main() {
  let convertee = datetime.literal("2024-06-12T10:47:00.000Z")

  datetime.literal("2024-01-03T05:30:02.334Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_text
  // -> "2024-06-12T06:47:00.000-04:00"
}
```

To account for leap seconds with this package, use a separate leap seconds provider package to compare dates (this leap second provider is fictional):

```gleam
import tempo/datetime
import leap_second

pub fn main() {
  datetime.literal("1972-06-30T23:59:59Z")
  |> leap_second.difference(from: datetime.literal("1972-07-01T00:00:00Z"))
  // -> "00:00:02"
}
```

## Development

```sh
gleam test  # Run the tests
```
