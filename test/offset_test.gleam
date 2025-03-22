import gleam/time/calendar
import gleeunit/should
import tempo
import tempo/duration
import tempo/offset

pub fn from_duration_offset_test() {
  offset.from_duration(duration.minutes(0))
  |> should.equal(Ok(tempo.offset(0)))

  offset.from_duration(duration.minutes(-720))
  |> should.equal(Ok(tempo.offset(-720)))

  offset.from_duration(duration.minutes(840))
  |> should.equal(Ok(tempo.offset(840)))

  offset.from_duration(duration.minutes(1000))
  |> should.be_error

  offset.from_duration(duration.minutes(-1000))
  |> should.be_error
}

pub fn to_string_zero_test() {
  offset.to_string(tempo.offset(0))
  |> should.equal("+00:00")
}

pub fn to_string_test() {
  offset.to_string(tempo.offset(-5))
  |> should.equal("-00:05")

  offset.to_string(tempo.offset(-720))
  |> should.equal("-12:00")

  offset.to_string(tempo.offset(70))
  |> should.equal("+01:10")

  offset.to_string(tempo.offset(840))
  |> should.equal("+14:00")
}

pub fn from_string_test() {
  offset.from_string("-00:00")
  |> should.equal(Ok(tempo.offset(0)))

  offset.from_string("+00:00")
  |> should.equal(Ok(tempo.offset(0)))

  offset.from_string("-00:05")
  |> should.equal(Ok(tempo.offset(-5)))

  offset.from_string("-12:00")
  |> should.equal(Ok(tempo.offset(-720)))

  offset.from_string("+01:10")
  |> should.equal(Ok(tempo.offset(70)))

  offset.from_string("+14:00")
  |> should.equal(Ok(tempo.offset(840)))

  offset.from_string("-00:70")
  |> should.be_error

  offset.from_string("-00:007")
  |> should.be_error

  offset.from_string("-005:7")
  |> should.be_error

  offset.from_string("+14:10")
  |> should.be_error

  offset.from_string("14:00")
  |> should.be_error

  offset.from_string(":")
  |> should.be_error
}

pub fn from_string_single_num_test() {
  offset.from_string("+1")
  |> should.be_ok
  |> offset.to_string
  |> should.equal("+01:00")
}

pub fn from_string_single_num_zero_test() {
  offset.from_string("-0")
  |> should.be_ok
  |> offset.to_string
  |> should.equal("+00:00")
}

pub fn from_string_z_test() {
  offset.from_string("Z")
  |> should.equal(Ok(tempo.offset(0)))

  offset.from_string("z")
  |> should.equal(Ok(tempo.offset(0)))
}

pub fn from_condensed_negative_string_test() {
  offset.from_string("-0451")
  |> should.equal(Ok(offset.literal("-04:51")))
}

pub fn from_condensed_posative_string_test() {
  offset.from_string("+1005")
  |> should.equal(Ok(offset.literal("+10:05")))
}

pub fn from_hour_negative_string_test() {
  offset.from_string("-09")
  |> should.equal(Ok(offset.literal("-09:00")))
}

pub fn from_hour_posative_string_test() {
  offset.from_string("+11")
  |> should.equal(Ok(offset.literal("+11:00")))
}

pub fn to_duration_test() {
  tempo.offset_to_duration(tempo.offset(0))
  |> should.equal(tempo.duration_microseconds(0))

  tempo.offset_to_duration(tempo.offset(5))
  |> should.equal(duration.minutes(5))

  tempo.offset_to_duration(tempo.offset(-720))
  |> should.equal(duration.minutes(-720))

  tempo.offset_to_duration(tempo.offset(70))
  |> should.equal(duration.minutes(70))

  tempo.offset_to_duration(tempo.offset(840))
  |> should.equal(duration.minutes(840))
}

pub fn to_duration_negative_test() {
  offset.literal("-04:00")
  |> offset.to_duration
  |> should.equal(duration.hours(-4))
}

pub fn local_parity_test() {
  calendar.local_offset() |> should.equal(offset.local() |> offset.to_duration)
}

pub fn offset_round_trip_test() {
  let ref = offset.literal("-04:00")

  offset.to_duration(ref)
  |> offset.from_duration
  |> should.equal(Ok(ref))
}
