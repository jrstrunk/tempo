import gleam/bool
import gleam/int
import gleam/result
import gleam/string
import tempo

pub fn local() -> tempo.Offset {
  local_minutes() |> tempo.Offset
}

pub const utc = tempo.Offset(0)

pub fn new(offset_minutes minutes: Int) -> Result(tempo.Offset, Nil) {
  tempo.Offset(minutes) |> validate
}

/// Useful for declaring offset literals that you know are valid within your 
/// program. Will crash if an invalid offset is provided.
pub fn literal(offset: String) -> tempo.Offset {
  let assert Ok(offset) = from_string(offset)
  offset
}

fn validate(offset: tempo.Offset) -> Result(tempo.Offset, Nil) {
  // Valid time offsets are between -12:00 and +14:00
  case offset.minutes >= -720 && offset.minutes <= 840 {
    True -> Ok(offset)
    False -> Error(Nil)
  }
}

pub fn to_string(offset: tempo.Offset) -> String {
  let #(is_negative, hours) = case offset.minutes / 60 {
    h if h <= 0 -> #(True, -h)
    h -> #(False, h)
  }

  let mins = case offset.minutes % 60 {
    m if m < 0 -> -m
    m -> m
  }

  case is_negative, hours, mins {
    _, 0, m -> "-00:" <> int.to_string(m) |> string.pad_left(2, with: "0")

    True, h, m ->
      "-"
      <> int.to_string(h) |> string.pad_left(2, with: "0")
      <> ":"
      <> int.to_string(m) |> string.pad_left(2, with: "0")

    False, h, m ->
      "+"
      <> int.to_string(h) |> string.pad_left(2, with: "0")
      <> ":"
      <> int.to_string(m) |> string.pad_left(2, with: "0")
  }
}

pub fn from_string(offset: String) -> Result(tempo.Offset, Nil) {
  case string.split(offset, ":") {
    [hour, minute] -> {
      use <- bool.guard(
        when: string.length(hour) != 3 || string.length(minute) != 2,
        return: Error(Nil),
      )

      case
        string.slice(hour, at_index: 0, length: 1),
        string.slice(hour, at_index: 1, length: 2)
        |> int.parse,
        int.parse(minute)
      {
        _, Ok(0), Ok(0) -> Ok(tempo.Offset(0))
        "-", Ok(hour), Ok(minute) if hour <= 24 && minute <= 60 ->
          Ok(tempo.Offset(-{ hour * 60 + minute }))
        "+", Ok(hour), Ok(minute) if hour <= 24 && minute <= 60 ->
          Ok(tempo.Offset(hour * 60 + minute))
        _, _, _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
  |> result.try(validate)
}

pub fn to_duration(offset: tempo.Offset) -> tempo.Duration {
  -offset.minutes * 60_000_000_000 |> tempo.Duration
}

@external(erlang, "tempo_ffi", "local_offset")
@external(javascript, "./tempo_ffi.mjs", "local_offset")
@internal
pub fn local_minutes() -> Int

@internal
pub fn local_nano() -> Int {
  local_minutes() * 60_000_000_000
}
