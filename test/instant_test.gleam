import gleam/time/duration
import gleam/time/timestamp
import gleeunit/should
import tempo/datetime
import tempo/instant
import tempo/mock

pub fn instant_as_timestamp_test() {
  mock.freeze_time(datetime.literal("2024-06-21T13:42:11.314534Z"))

  let res =
    instant.now()
    |> instant.as_timestamp
    |> timestamp.to_rfc3339(duration.seconds(0))

  mock.unfreeze_time()

  res
  |> should.equal("2024-06-21T13:42:11.314534Z")
}
