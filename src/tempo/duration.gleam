import gleam/int
import gleam/order
import tempo

pub type MonotomicTime {
  MonotomicTime(nanoseconds: Int)
}

pub fn start() -> MonotomicTime {
  tempo.now_utc() |> MonotomicTime
}

pub fn stop(start: MonotomicTime) -> tempo.Duration {
  tempo.now_utc() - start.nanoseconds |> tempo.Duration
}

pub fn new(hours hr: Int, minutes min: Int, seconds sec: Int) {
  hours_to_nanoseconds(hr)
  + minutes_to_nanoseconds(min)
  + seconds_to_nanoseconds(sec)
  |> tempo.Duration
}

pub fn hours(hours: Int) -> tempo.Duration {
  hours_to_nanoseconds(hours) |> tempo.Duration
}

pub fn minutes(minutes: Int) -> tempo.Duration {
  minutes_to_nanoseconds(minutes) |> tempo.Duration
}

pub fn seconds(seconds: Int) -> tempo.Duration {
  seconds_to_nanoseconds(seconds) |> tempo.Duration
}

pub fn milliseconds(milliseconds: Int) {
  milliseconds * 1_000_000 |> tempo.Duration
}

pub fn microseconds(microseconds: Int) {
  microseconds * 1000 |> tempo.Duration
}

pub fn nenoseconds(nanoseconds: Int) {
  nanoseconds |> tempo.Duration
}

@internal
pub fn hours_to_nanoseconds(hours: Int) -> Int {
  hours * 3_600_000_000_000
}

@internal
pub fn minutes_to_nanoseconds(minutes: Int) -> Int {
  minutes * 60_000_000_000
}

@internal
pub fn seconds_to_nanoseconds(seconds: Int) -> Int {
  seconds * 1_000_000_000
}

pub fn increase(a: tempo.Duration, by b: tempo.Duration) -> tempo.Duration {
  tempo.Duration(a.nanoseconds + b.nanoseconds)
}

pub fn decrease(a: tempo.Duration, by b: tempo.Duration) -> tempo.Duration {
  tempo.Duration(a.nanoseconds - b.nanoseconds)
}

pub fn as_hours(duration: tempo.Duration) -> Int {
  duration.nanoseconds / 3_600_000_000_000
}

pub fn as_hours_fractional(duration: tempo.Duration) -> Float {
  int.to_float(duration.nanoseconds) /. 3_600_000_000_000.0
}

pub fn as_minutes(duration: tempo.Duration) -> Int {
  duration.nanoseconds / 60_000_000_000
}

pub fn as_minutes_fractional(duration: tempo.Duration) -> Float {
  int.to_float(duration.nanoseconds) /. 60_000_000_000.0
}

pub fn as_seconds(duration: tempo.Duration) -> Int {
  duration.nanoseconds / 1_000_000_000
}

pub fn as_seconds_fractional(duration: tempo.Duration) -> Float {
  int.to_float(duration.nanoseconds) /. 1_000_000_000.0
}

pub fn as_milliseconds(duration: tempo.Duration) -> Int {
  duration.nanoseconds / 1_000_000
}

pub fn as_milliseconds_fractional(duration: tempo.Duration) -> Float {
  int.to_float(duration.nanoseconds) /. 1_000_000.0
}

pub fn as_microseconds(duration: tempo.Duration) -> Int {
  duration.nanoseconds / 1000
}

pub fn as_microseconds_fractional(duration: tempo.Duration) -> Float {
  int.to_float(duration.nanoseconds) /. 1000.0
}

pub fn as_nanoseconds(duration: tempo.Duration) -> Int {
  duration.nanoseconds
}

pub fn compare(a: tempo.Duration, to b: tempo.Duration) -> order.Order {
  int.compare(a.nanoseconds, b.nanoseconds)
}

pub fn is_less(a: tempo.Duration, than b: tempo.Duration) -> Bool {
  compare(a, b) == order.Lt
}

pub fn is_less_or_equal(a: tempo.Duration, to b: tempo.Duration) -> Bool {
  compare(a, b) == order.Lt || compare(a, b) == order.Eq
}

pub fn is_equal(a: tempo.Duration, to b: tempo.Duration) -> Bool {
  compare(a, b) == order.Eq
}

pub fn is_greater(a: tempo.Duration, than b: tempo.Duration) -> Bool {
  compare(a, b) == order.Gt
}

pub fn is_greater_or_equal(a: tempo.Duration, to b: tempo.Duration) -> Bool {
  compare(a, b) == order.Gt || compare(a, b) == order.Eq
}
