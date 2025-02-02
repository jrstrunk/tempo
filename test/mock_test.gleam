import gleeunit/should
import tempo
import tempo/date
import tempo/datetime
import tempo/duration
import tempo/instant
import tempo/mock

pub fn freeze_time_test() {
  let target = datetime.literal("2024-06-21T13:42:11.314Z")
  mock.freeze_time(target)
  |> should.equal(Nil)

  tempo.now()
  |> instant.as_utc_datetime
  |> should.equal(target)

  mock.unfreeze_time()
  |> should.equal(Nil)

  tempo.now()
  |> instant.as_utc_datetime
  |> should.not_equal(target)
}

pub fn set_reference_time_bounds_test() {
  mock.set_time(datetime.literal("2024-06-21T00:10:00Z"), 1.0)

  date.current_utc()
  |> date.to_string
  |> should.equal("2024-06-21")

  tempo.is_earlier(datetime.literal("2024-06-21T00:11:00Z"))
  |> should.be_true

  tempo.is_earlier(datetime.literal("2024-06-21T00:09:00Z"))
  |> should.be_false

  tempo.is_later(datetime.literal("2024-06-21T00:09:00Z"))
  |> should.be_true

  tempo.is_later(datetime.literal("2024-06-21T00:11:00Z"))
  |> should.be_false

  mock.unset_time()
  |> should.equal(Nil)

  date.current_utc()
  |> date.to_string
  |> should.not_equal("2024-06-21")
}

pub fn monotonic_speedup_test() {
  let real = instant.now() |> instant.since |> duration.as_microseconds

  mock.set_time(datetime.literal("2024-06-21T00:10:00Z"), 1000.0)

  let spedup = instant.now() |> instant.since |> duration.as_microseconds

  let assert True = spedup > real
}
