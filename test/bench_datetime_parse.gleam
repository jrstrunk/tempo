import gleam/time/timestamp
import glychee/benchmark
import glychee/configuration
import tempo
import tempo/datetime

/// Benchmarks the regex-driven parsing paths (custom-format `parse` and
/// heuristic `parse_any`) against the fast, delegated-to-`gleam_time`
/// `from_string_fast`, and `from_string` (the default byte parser).
///
/// Also times the raw `timestamp.parse_rfc3339` call on its own (no
/// conversion back to a tempo `DateTime`) to see how much of
/// `from_string_fast`'s cost is the parse itself vs. the extra
/// Timestamp-to-calendar round trip on top of it, and whether `from_string`
/// is winning by out-parsing `gleam_time` or just by skipping that round
/// trip.
///
/// Run with:
///   gleam run -m bench_datetime_parse
fn discard(_result: a) -> Nil {
  Nil
}

pub fn main() {
  configuration.initialize()
  configuration.set_pair(configuration.Warmup, 2)
  configuration.set_pair(configuration.Time, 5)
  configuration.set_pair(configuration.Parallel, 1)

  benchmark.run(
    [
      benchmark.Function(
        label: "parse (regex, custom format)",
        callable: fn(test_data) {
          fn() {
            datetime.parse(
              test_data,
              in: tempo.Custom("YYYY-MM-DDTHH:mm:ss.SSSZ"),
            )
            |> discard
          }
        },
      ),
      benchmark.Function(
        label: "parse_any (regex, heuristic scan)",
        callable: fn(test_data) {
          fn() { datetime.parse_any(test_data) |> discard }
        },
      ),
      benchmark.Function(
        label: "from_string_fast (delegates to gleam_time)",
        callable: fn(test_data) {
          fn() { datetime.from_string_fast(test_data) |> discard }
        },
      ),
      benchmark.Function(
        label: "from_string (new default: direct byte parse, no gleam_time)",
        callable: fn(test_data) {
          fn() { datetime.from_string(test_data) |> discard }
        },
      ),
      benchmark.Function(
        label: "timestamp.parse_rfc3339 (raw gleam_time call, no conversion back)",
        callable: fn(test_data) {
          fn() { timestamp.parse_rfc3339(test_data) |> discard }
        },
      ),
    ],
    [
      benchmark.Data(
        label: "ISO datetime with millisecond offset",
        data: "2024-06-13T23:04:00.009+10:00",
      ),
    ],
  )
}
