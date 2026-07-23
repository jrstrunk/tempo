import glychee/benchmark
import glychee/configuration
import tempo/date
import tempo/naive_datetime
import tempo/offset
import tempo/time

/// Quick sanity benchmark for the shared `gtempo/fast_parse` primitives'
/// speed after removing `use <- result.try(...)` chains in favor of nested
/// `case` matching.
///
/// Run with:
///   gleam run -m bench_from_string_all
fn discard(_result: a) -> Nil {
  Nil
}

pub fn main() {
  configuration.initialize()
  configuration.set_pair(configuration.Warmup, 1)
  configuration.set_pair(configuration.Time, 2)
  configuration.set_pair(configuration.Parallel, 1)

  benchmark.run(
    [
      benchmark.Function(label: "date.from_string", callable: fn(_) {
        fn() { date.from_string("2024-06-13") |> discard }
      }),
    ],
    [benchmark.Data(label: "date", data: Nil)],
  )

  benchmark.run(
    [
      benchmark.Function(label: "time.from_string", callable: fn(_) {
        fn() { time.from_string("13:42:11.354053") |> discard }
      }),
    ],
    [benchmark.Data(label: "time", data: Nil)],
  )

  benchmark.run(
    [
      benchmark.Function(label: "offset.from_string", callable: fn(_) {
        fn() { offset.from_string("-04:00") |> discard }
      }),
    ],
    [benchmark.Data(label: "offset", data: Nil)],
  )

  benchmark.run(
    [
      benchmark.Function(label: "naive_datetime.from_string", callable: fn(_) {
        fn() {
          naive_datetime.from_string("2024-06-13T13:42:11.354053")
          |> discard
        }
      }),
    ],
    [benchmark.Data(label: "naive_datetime", data: Nil)],
  )
}
