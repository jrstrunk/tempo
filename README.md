# Tempo

A lightweight and Gleamy datetime library!

Only run a task past a certain time of day, only accept submissions since a certain date, calculate the difference beteen times and dates, time long running tasks, parse and stringify datetimes, and more! Over 375 unit tests, contributions welcome!

Written in almost pure Gleam, Tempo tries to optimize for the same thing the Gleam language does: explicitness over terseness and simplicity over convenience. My hope is to make Tempo feel like the Gleam language and to make it as difficult to write time related bugs as possible.

## Installation

```sh
gleam add gtempo
```

[![Package Version](https://img.shields.io/hexpm/v/tempo)](https://hex.pm/packages/gtempo)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gtempo/)

#### Parsing and Formatting Example

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

#### Iterating Over a Date Range Example

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

#### Time-Based Logical Branching and Logging Example

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

  case time.now_local() |> time.is_later(than: target_time) {
    True -> {
      io.println(
        "Oh no! We are late by "
        <> time.now_local()
        |> time.difference(from: target_time)
        |> duration.as_minutes
        |> int.to_string
        <> " minutes! This should take until "
        <> time.now_utc()
        |> time.add(duration.minutes(16))
        |> time.to_milli_precision
        |> time.to_string
        <> " UTC",
      )

      run_rushed_task(for: date.current_local())
    }

    False -> {
      io.println(
        "No rush :) This should take until "
        <> time.now_local()
        |> time.add(duration.hours(3))
        |> time.to_second_precision
        |> time.to_string,
      )

      run_long_task(for: date.current_local())
    }
  }

  io.println("Phew, that only took " <> duration.since(timer))
}

// -> 2024-06-21 08:06:54.279 booting up!
// -> Oh no! We are late by 16 minutes! This should take until 12:22:54.301 UTC
// -> Phew, that only took 978 microseconds
```

#### Waiting Until a Specific Time Example

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

This package purposefully **ignores leap seconds** and **will not convert between time zones**. Try to design your application so time zones do not have to be converted between and leap seconds are trivial. More below.

Both time zones and leap seconds require maintaining a manually updated database of location offsets and leap seconds. This burdens any application that uses them to keep their dependencies up to date and burdens the package by invalidating all previous versions when an update needs to be made.

If at all possible, try to design your application so that time zones do not have to be converted between. Client machines should have information about their time zone offset that can be polled and used for current time time zone conversions. This package will allow you to convert between local time and UTC time on the same date as the system date.

Since this package ignores leap seconds, historical leap seconds are ignored when doing comparisons and durations. Please keep this in mind when designing your applications. Leap seconds can still be parsed from ISO 8601 strings and will be compared correctly to other times, but will not be preserved when converting to any other time representation (including changing the offset).

When getting the system time, leap second accounting depends on the host's time implementation.

If you must, to convert between time zones with this package, use a separate time zone provider package to get the offset of the target time zone for a given date, then apply the offset to a `datetime` value (this time zone package is fictional):

```gleam
import tempo/datetime
import timezone

pub fn main() {
  let convertee = datetime.literal("2024-06-12T10:47:00.000Z")

  convertee
  |> datetime.to_offset(timezone.offset(
    for: "America/New_York",
    on: convertee,
  ))
  |> datetime.to_string
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
