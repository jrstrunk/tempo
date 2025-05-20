import gleeunit/should
import tempo
import tempo/date
import tempo/datetime
import tempo/duration
import tempo/instant
import tempo/mock
import tempo/offset

pub fn main() {
  mock.set_time(datetime.literal("2024-06-21T00:10:00.000Z"))
  mock.enable_sleep_warp()

  tempo.format_local(tempo.ISO8601Milli) |> echo
  tempo.sleep(duration.seconds(10))
  tempo.format_local(tempo.ISO8601Milli) |> echo

  mock.unset_time()
  mock.disable_sleep_warp()
}

pub fn freeze_time_utc_test() {
  let target = datetime.literal("2024-06-21T13:42:11.314Z")
  mock.freeze_time(target)

  let frozen_now =
    tempo.now()
    |> instant.as_utc_datetime

  let frozen_offset = offset.local()

  mock.unfreeze_time()

  frozen_now |> should.equal(target)

  tempo.now()
  |> instant.as_utc_datetime
  |> should.not_equal(target)

  offset.to_string(frozen_offset) |> should.equal("+00:00")
}

pub fn freeze_time_local_test() {
  let target = datetime.literal("2024-06-21T13:42:11.314-05:00")
  mock.freeze_time(target)

  let frozen_now =
    tempo.now()
    |> instant.as_local_datetime

  let frozen_offset = offset.local()

  mock.unfreeze_time()

  frozen_now |> should.equal(target)

  tempo.now()
  |> instant.as_local_datetime
  |> should.not_equal(target)

  offset.to_string(frozen_offset) |> should.equal("-05:00")
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

  date.current_local()
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

// Tests provided by @dzuk-mutant in GitHub issue #19
fn mock(datetime) {
  mock.freeze_time(datetime)

  instant.now()
  |> instant.as_local_datetime
  |> should.equal(datetime)

  mock.unfreeze_time()
}

pub fn mock_1_test() {
  datetime.literal("2000-01-01T00:00:00.000Z")
  |> mock()
}

pub fn mock_2_test() {
  datetime.literal("2000-01-02T00:00:00.000Z")
  |> mock()
}

pub fn mock_3_test() {
  datetime.literal("2000-01-03T00:00:00.000Z")
  |> mock()
}

pub fn mock_4_test() {
  datetime.literal("2000-01-04T00:00:00.000Z")
  |> mock()
}

pub fn mock_5_test() {
  datetime.literal("2000-01-05T00:00:00.000Z")
  |> mock()
}

pub fn mock_1_2_test() {
  datetime.literal("2000-01-01T00:00:00.000+01:00")
  |> mock()
}

pub fn mock_1_3_test() {
  datetime.literal("2000-01-01T00:00:00.000-08:00")
  |> mock()
}

pub fn mock_1_4_test() {
  datetime.literal("2000-01-01T00:00:00.000+04:00")
  |> mock()
}

pub fn mock_1_5_test() {
  datetime.literal("2000-01-01T00:00:00.000-10:00")
  |> mock()
}
