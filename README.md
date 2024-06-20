# Tempo

A gleam library for controlling the tempo of your application through helpful date and time functions! 

This package purposefully **ignores leap seconds** and **will not convert between time zones**. Try to design your application so time zones do not have to be converted between and leap seconds are trivial. More below.

[![Package Version](https://img.shields.io/hexpm/v/tempo)](https://hex.pm/packages/tempo)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/tempo/)

```sh
gleam add tempo
```
```gleam
import tempo

pub fn main() {
  // TODO: An example of the project in use
}
```

Further documentation can be found at <https://hexdocs.pm/tempo>.

## Time Zone and Leap Second Considerations
To convert between time zones with this package, use a separate time zone provider package to get the offset of the target time zone for a given date, then apply the offset to a `datetime` value (this time zone package is fictional):

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

Both time zones and leap seconds require maintaining a manually updated database of location offsets and leap seconds. This burdens any application that uses them to keep their dependencies up to date and burdens the package by invalidating all previous versions when an update needs to be made.

If at all possible, try to design your application so that time zones do not have to be converted between. Client machines should have information about their time zone offset that can be polled and used for current time time zone conversions. This package will allow you to convert between local time and UTC time on the same date as the system date.

Since this package ignores leap seconds, the same second could be repeated twice in a day when a leap second is added, but it depends on the host's time implementation. Historical leap seconds are ignored when doing comparisons and durations. Please keep this in mind when designing your applications. Leap seconds can still be parsed from ISO 8601 strings and will be compared correctly to other times, but will not be preserved when converting to any other time representation (including changing the offset).

## Development

```sh
gleam test  # Run the tests
```
