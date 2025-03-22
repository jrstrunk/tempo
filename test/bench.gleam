import glychee/benchmark
import glychee/configuration
import tempo/datetime

pub fn main() {
  // Configuration is optional
  configuration.initialize()
  configuration.set_pair(configuration.Warmup, 2)
  configuration.set_pair(configuration.Parallel, 2)

  // Run the benchmarks
  benchmark.run(
    [
      benchmark.Function(
        label: "datetime.from_string()",
        callable: fn(test_data) { fn() { datetime.from_string(test_data) } },
      ),
      benchmark.Function(
        label: "datetime.from_string_fast()",
        callable: fn(test_data) {
          fn() { datetime.from_string_fast(test_data) }
        },
      ),
    ],
    [
      benchmark.Data(label: "utc dates", data: "2024-06-21T23:17:00Z"),
      benchmark.Data(label: "local dates", data: "2024-06-21T23:17:00-04:00"),
    ],
  )
}
