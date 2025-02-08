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
  mock.enable_sleep_warp()

  tempo.format_local(tempo.ISO8601Milli) |> io.debug
  tempo.sleep(duration.seconds(10))
  tempo.format_local(tempo.ISO8601Milli) |> io.debug

  mock.unset_time()
  mock.disable_sleep_warp()
}

pub fn freeze_time_test() {
  let target = datetime.literal("2024-06-21T13:42:11.314Z")
  mock.freeze_time(target)

  let frozen_now =
    tempo.now()
    |> instant.as_utc_datetime

  mock.unfreeze_time()

  frozen_now |> should.equal(target)

  tempo.now()
  |> instant.as_utc_datetime
  |> should.not_equal(target)
}

pub fn monotonic_freeze_time_test() {
  let target = datetime.literal("2024-06-21T13:42:11.314Z")
  mock.freeze_time(target)

  let start = instant.now()

  tempo.sleep(duration.milliseconds(10))

  let elap = instant.since(start) |> duration.as_milliseconds

  mock.unfreeze_time()

  elap |> should.equal(0)
}

pub fn frozen_sleep_test() {
  let target = datetime.literal("2024-06-21T13:42:11.314Z")
  mock.freeze_time(target)
  mock.enable_sleep_warp()

  let start = instant.now()

  tempo.sleep(duration.seconds(10))

  let elap = instant.since(start) |> duration.as_milliseconds

  mock.unfreeze_time()
  mock.disable_sleep_warp()
  mock.reset_warp_time()

  elap |> should.equal(10_000)
}

pub fn exact_frozen_warp_test() {
  let target = datetime.literal("2024-06-21T13:42:11.314092Z")
  mock.freeze_time(target)

  mock.warp_time(by: duration.seconds(10))

  let res = tempo.format_utc(tempo.ISO8601Micro)

  mock.unfreeze_time()
  mock.reset_warp_time()

  res |> should.equal("2024-06-21T13:42:21.314092Z")
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

pub fn sleep_warp_disable_test() {
  mock.enable_sleep_warp()
  mock.disable_sleep_warp()

  let timer = instant.now()
  tempo.sleep(duration.milliseconds(10))
  mock.reset_warp_time()

  let real_elapsed = instant.since(timer) |> duration.as_milliseconds

  io.debug(real_elapsed)
  { real_elapsed >= 10 }
  |> should.be_true
}

pub fn add_warp_time_test() {
  let timer = instant.now()

  mock.warp_time(duration.seconds(10))
  let mock_elapsed = instant.since(timer) |> duration.as_milliseconds

  { mock_elapsed >= 10_000 }
  |> should.be_true

  mock.reset_warp_time()
  let real_elapsed = instant.since(timer) |> duration.as_milliseconds

  { real_elapsed < mock_elapsed }
  |> should.be_true

  { real_elapsed < 1000 }
  |> should.be_true
}
