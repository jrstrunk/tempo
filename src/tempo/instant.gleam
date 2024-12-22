import gleam/order
import tempo
import tempo/datetime

pub fn to_utc_string(instant: tempo.Instant) -> String {
  tempo.instant_to_utc_string(instant)
}

pub fn to_local_string(instant: tempo.Instant) -> String {
  tempo.instant_to_local_string(instant)
}

pub fn as_utc_datetime(instant: tempo.Instant) -> tempo.DateTime {
  tempo.instant_as_utc_datetime(instant)
}

pub fn as_local_datetime(instant: tempo.Instant) -> tempo.DateTime {
  tempo.instant_as_local_datetime(instant)
}

pub fn as_unix_utc(instant: tempo.Instant) -> Int {
  tempo.instant_as_unix_utc(instant)
}

pub fn as_unix_milli_utc(instant: tempo.Instant) -> Int {
  tempo.instant_as_unix_milli_utc(instant)
}

pub fn as_utc_date(instant: tempo.Instant) -> tempo.Date {
  tempo.instant_as_utc_date(instant)
}

pub fn as_local_date(instant: tempo.Instant) -> tempo.Date {
  tempo.instant_as_local_date(instant)
}

pub fn as_utc_time(instant: tempo.Instant) -> tempo.Time {
  tempo.instant_as_utc_time(instant)
}

pub fn as_local_time(instant: tempo.Instant) -> tempo.Time {
  tempo.instant_as_local_time(instant)
}

pub fn format_utc(instant: tempo.Instant, in format: String) -> String {
  tempo.instant_as_utc_datetime(instant) |> datetime.format(in: format)
}

pub fn format_local(instant: tempo.Instant, in format: String) -> String {
  tempo.instant_as_local_datetime(instant) |> datetime.format(in: format)
}

pub fn difference(from a: tempo.Instant, to b: tempo.Instant) -> tempo.Duration {
  tempo.instant_difference(from: a, to: b)
}

pub fn compare(a: tempo.Instant, b: tempo.Instant) -> order.Order {
  tempo.instant_compare(a, b)
}

pub fn is_earlier(a: tempo.Instant, than b: tempo.Instant) -> Bool {
  tempo.instant_is_earlier(a, than: b)
}

pub fn is_earlier_or_equal(a: tempo.Instant, to b: tempo.Instant) -> Bool {
  tempo.instant_is_earlier_or_equal(a, to: b)
}

pub fn is_equal(a: tempo.Instant, to b: tempo.Instant) -> Bool {
  tempo.instant_is_equal(a, to: b)
}

pub fn is_later(a: tempo.Instant, than b: tempo.Instant) -> Bool {
  tempo.instant_is_later(a, than: b)
}

pub fn is_later_or_equal(a: tempo.Instant, to b: tempo.Instant) -> Bool {
  tempo.instant_is_later_or_equal(a, to: b)
}
