# Tempo

A datetime-centric, mockable time library for Gleam!

Only run a task past a certain time of day, calculate the difference between times and dates, time long running tasks, parse and format datetimes, and more! Over 600 unit tests, contributions welcome!

Written in almost pure Gleam, Tempo tries to optimize for the same things the Gleam language does: explicitness over terseness and simplicity over convenience. My hope is to make Tempo feel like the Gleam language and to make it as difficult to write time-related bugs as possible!

Supports both the Erlang and JavaScript targets.

## Installation

```sh
gleam add gtempo
```

Supports time zones through the built-in `tempo/time_zone` module, which reads time zone data from the host system: `/usr/share/zoneinfo` on Erlang (macOS and other Unix systems), and the native `Intl` API on JavaScript.

Supports the core gleam time package via conversion functions. Add it with:

```sh
gleam add gleam_time
```

[![Package Version](https://img.shields.io/hexpm/v/tempo)](https://hex.pm/packages/gtempo)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gtempo/)

#### Parsing and Formatting

This should not be used to format dates and times to users of an international audience. For that, a package like `g18n` or `intldate` should be used for locale-sensitive formatting.new mo

```gleam
import tempo
import tempo/datetime

pub fn main() {
  // Parses any format of date, time, and/or time zone
  tempo.parse_any("Dec 25, 2024 at 1:00 PM")
  // -> Ok(#(Some(date), Some(time), None))

  // Formats the current local system time
  tempo.format_local(tempo.ISO8601Milli)
  // -> "2024-12-25T06:04:20.534-04:00"

  datetime.literal("2024-12-25T06:00:00Z")
  |> datetime.format(tempo.Custom("ddd @ h:mm A"))
  // -> "Fri @ 6:00 AM"

  date.parse("03/02/1998", tempo.CustomDate("DD/MM/YYYY"))
  // -> Ok(date.literal("1998-02-03"))
}
```

#### Handling Current System Time

To avoid common pitfalls, the current system time is only returned as an `Instant` type. This monotonic type represents a unique point in time on the host system and is the most complete representation of system time. It can be converted to all other time types if needed, but it should be used as-is when possible.

The current system time can also be dealt with by using the `tempo` module functions, as shown below.

```gleam
import gleam/io
import tempo
import tempo/duration
import tempo/time
import tempo/instant

pub fn main() {
  // Timing tasks
  let timer = instant.now()
  long_running_task()
  instant.since(timer)
  // -> duration.minutes(42)

  // Formatting the current system time
  tempo.format_utc(tempo.ISO8601Seconds)
  // -> "2024-12-26T15:04:20Z"

  // Comparing the system time to other times
  let target = datetime.literal("2024-12-26T03:10:00Z")

  case tempo.is_later(than: target) {
    True ->
      io.println(
        "We are late by "
        <> tempo.difference(from: target)
        |> duration.format
      )
    False -> io.println("We are on time!")
  }
  // -> We are late by 54 minutes
}
```

#### Mocking Current System Time

The system time can mocked and controlled in precise ways. Look in the `tempo/mock` module for more detailed information!

```gleam
import tempo
import tempo/mock
import gleam/time/duration

pub fn main() {
  // Set the current system time to a specific time and stop it from progressing
  mock.freeze_time(datetime.literal("2024-06-21T13:42:11.314Z"))
  mock.enable_sleep_warp()

  // Processes instantly, but appears to the program that it slept for 10 seconds
  tempo.sleep(for: duration.seconds(10))

  tempo.format_utc(tempo.ISO8601Seconds)
  // -> "2024-06-21T13:42:11Z"

  mock.unfreeze_time()
  mock.disable_sleep_warp()
  mock.reset_warp_time()

  tempo.format_utc(tempo.ISO8601Seconds)
  // -> "2025-02-02T08:42:11Z"

}
```

#### Time Zone Conversion

Time zone conversion is supported by the `tempo/time_zone` module, which provides time zone information from the host system. On the Erlang target (macOS and other Unix systems) it reads the operating system's TZif database from `/usr/share/zoneinfo`, parsing it once and caching the result. On the JavaScript target it uses the runtime's native `Intl` API instead, so no filesystem access is needed.

```gleam
import tempo/datetime
import tempo/time_zone

pub fn main() {
  let assert Ok(local_tz) = time_zone.local_name() |> time_zone.new

  datetime.from_unix_seconds(1_729_257_776)
  |> datetime.to_timezone(local_tz)
  |> datetime.to_string
  // -> "2024-10-18T14:22:56.000+01:00"

  let assert Ok(tz) = time_zone.new("America/New_York")

  datetime.literal("2024-01-03T05:30:02.334Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  // -> "2024-01-03T00:30:02.334-05:00"
}
```

#### Iterating Over a Date Range

```gleam
import tempo/date
import tempo/period

pub fn main() {
  date.literal("2024-06-21")
  |> date.as_period(end: date.literal("2024-06-24"))
  |> period.comprising_dates
  // -> [2024-06-21, 2024-06-22, 2024-06-23, 2024-06-24]

  date.literal("2024-06-21")
  |> date.as_period(end: date.literal("2024-07-08"))
  |> period.comprising_months
  // -> [tempo.Jun, tempo.Jul]
}
```

#### Waiting Until a Specific Time of Day

```gleam
import gleam/erlang/process
import tempo/duration
import tempo/time
import tempo/instant

pub fn main() {
  // Sleep until 8:25 if we start before then.
  instant.now()
  |> instant.as_local_time
  |> time.until(time.literal("08:25:00"))
  |> duration.as_milliseconds
  |> process.sleep

  // Now that it is 8:25, do what we need to do.
  "Hello, world!"
}
```

Further documentation can be found at <https://hexdocs.pm/gtempo>.

## Calendar and Date Range

Every date in this package is a [proleptic Gregorian calendar](https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar) date, using Gregorian month lengths and the Gregorian leap year rule (divisible by 4, except century years, which must be divisible by 400). "Proleptic" means those rules are applied to dates before the calendar was adopted in 1582 too, so early dates will not line up with what was recorded historically on the Julian calendar. No other calendar system is supported, and month and day names are the English Gregorian ones.

Constructing a date from calendar parts is limited to **years 1000 through 9999**, so that a year is always four digits. Years below 1000 are usually a mistyped or two-digit year rather than a real one, and are rejected for that reason. Date arithmetic is not range checked, so `add`, `subtract` and `from_rata_die` can carry a date outside that range, where it still compares correctly but no longer formats as valid ISO 8601.

Times run from `00:00:00.000000` through `23:59:59.999999`, with `24:00:00` and the leap second `23:59:60` additionally accepted. Offsets run from `-12:00` through `+14:00`. Durations are a fixed number of microseconds with no calendar context at all, so their `Week` is always 7 days and their `YearImprecise` is always 364 days, neither of which tracks the calendar.

## Time Zone and Leap Second Considerations

This package purposefully **ignores leap seconds** and does not have a zoned datetime type. Try to design your application so time zones do not have to be converted between, relying instead on UTC time for time logic.

Since this package ignores leap seconds, historical leap seconds are ignored when comparing and calculating durations. Please keep this in mind when designing your applications. Leap seconds can still be parsed from ISO 8601 strings and will be compared correctly to other times but will not be preserved when converting to any other time representation (including changing the offset).

## Development

```sh
gleam test  # Run the tests
```
