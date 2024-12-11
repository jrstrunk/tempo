import gleam/order
import tempo
import tempo/datetime

pub fn to_string(moment: tempo.Moment) -> String {
  tempo.moment_to_string(moment)
}

pub fn as_datetime(moment: tempo.Moment) -> tempo.DateTime {
  tempo.moment_as_datetime(moment)
}

pub fn as_unix_utc(moment: tempo.Moment) -> Int {
  tempo.moment_as_unix_utc(moment)
}

pub fn as_unix_milli_utc(moment: tempo.Moment) -> Int {
  tempo.moment_as_unix_milli_utc(moment)
}

pub fn as_date(moment: tempo.Moment) -> tempo.Date {
  tempo.moment_as_date(moment)
}

pub fn as_time(moment: tempo.Moment) -> tempo.Time {
  tempo.moment_as_time(moment)
}

pub fn format(moment: tempo.Moment, in format: String) -> String {
  tempo.moment_as_datetime(moment) |> datetime.format(in: format)
}

pub fn difference(from a: tempo.Moment, to b: tempo.Moment) -> tempo.Duration {
  tempo.moment_difference(from: a, to: b)
}

pub fn compare(a: tempo.Moment, b: tempo.Moment) -> order.Order {
  tempo.moment_compare(a, b)
}

pub fn is_earlier(a: tempo.Moment, than b: tempo.Moment) -> Bool {
  tempo.moment_is_earlier(a, than: b)
}

pub fn is_earlier_or_equal(a: tempo.Moment, to b: tempo.Moment) -> Bool {
  tempo.moment_is_earlier_or_equal(a, to: b)
}

pub fn is_equal(a: tempo.Moment, to b: tempo.Moment) -> Bool {
  tempo.moment_is_equal(a, to: b)
}

pub fn is_later(a: tempo.Moment, than b: tempo.Moment) -> Bool {
  tempo.moment_is_later(a, than: b)
}

pub fn is_later_or_equal(a: tempo.Moment, to b: tempo.Moment) -> Bool {
  tempo.moment_is_later_or_equal(a, to: b)
}
