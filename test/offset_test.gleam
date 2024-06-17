import gleeunit
import gleeunit/should
import tempo
import tempo/duration
import tempo/offset

pub fn main() {
  gleeunit.main()
}

pub fn new_offset_test() {
  offset.new(0)
  |> should.equal(Ok(tempo.Offset(0)))

  offset.new(-720)
  |> should.equal(Ok(tempo.Offset(-720)))

  offset.new(840)
  |> should.equal(Ok(tempo.Offset(840)))

  offset.new(1000)
  |> should.be_error

  offset.new(-1000)
  |> should.be_error
}

pub fn to_string_zero_test() {
  offset.to_string(tempo.Offset(0))
  |> should.equal("-00:00")
}

pub fn to_string_test() {
  offset.to_string(tempo.Offset(-5))
  |> should.equal("-00:05")

  offset.to_string(tempo.Offset(-720))
  |> should.equal("-12:00")

  offset.to_string(tempo.Offset(70))
  |> should.equal("+01:10")

  offset.to_string(tempo.Offset(840))
  |> should.equal("+14:00")
}

pub fn from_string_test() {
  offset.from_string("-00:00")
  |> should.equal(Ok(tempo.Offset(0)))

  offset.from_string("-00:05")
  |> should.equal(Ok(tempo.Offset(-5)))

  offset.from_string("-12:00")
  |> should.equal(Ok(tempo.Offset(-720)))

  offset.from_string("+01:10")
  |> should.equal(Ok(tempo.Offset(70)))

  offset.from_string("+14:00")
  |> should.equal(Ok(tempo.Offset(840)))

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

pub fn from_string_z_test() {
  offset.from_string("Z")
  |> should.equal(Ok(tempo.Offset(0)))

  offset.from_string("z")
  |> should.equal(Ok(tempo.Offset(0)))
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
  offset.to_duration(tempo.Offset(0))
  |> should.equal(tempo.Duration(0))

  offset.to_duration(tempo.Offset(5))
  |> should.equal(duration.minutes(-5))

  offset.to_duration(tempo.Offset(-720))
  |> should.equal(duration.minutes(720))

  offset.to_duration(tempo.Offset(70))
  |> should.equal(duration.minutes(-70))

  offset.to_duration(tempo.Offset(840))
  |> should.equal(duration.minutes(-840))
}
