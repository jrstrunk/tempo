import gleam/io
import gleeunit/should
import tempo
import tempo/date
import tempo/datetime
import tempo/duration
import tempo/instant
import tempo/mock

pub fn main() {
  mock.set_time(datetime.literal("2024-06-21T00:10:00.000Z"))

  tempo.format_local(tempo.ISO8601Milli) |> io.debug
  tempo.sleep(duration.seconds(10))
  tempo.format_local(tempo.ISO8601Milli) |> io.debug

  mock.unset_time()
}

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
  mock.set_time(datetime.literal("2024-06-21T00:10:00Z"))

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

pub fn sleep_warp_test() {
  mock.enable_sleep_warp()
  let timer = instant.now()

  tempo.sleep(duration.seconds(10))

  let mock_elapsed = instant.since(timer) |> duration.as_milliseconds

  mock.reset_warp_time()
  let real_elapsed = instant.since(timer) |> duration.as_milliseconds

  { real_elapsed < mock_elapsed }
  |> should.be_true

  { real_elapsed < 1000 }
  |> should.be_true

  { mock_elapsed >= 10_000 }
  |> should.be_true
}
