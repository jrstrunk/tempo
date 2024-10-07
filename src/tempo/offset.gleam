import gleam/int
import gleam/result
import gleam/string
import tempo

@internal
pub fn local() -> tempo.Offset {
  local_minutes() |> tempo.Offset
}

/// The Tempo representation of the UTC offset.
pub const utc = tempo.Offset(0)

/// Creates a new offset from a number of minutes.
/// 
/// ## Example
/// 
/// ```gleam
/// offset.new(-65)
/// |> result.map(offset.to_string)
/// // -> Ok("-01:05")
/// ```
pub fn new(offset_minutes minutes: Int) -> Result(tempo.Offset, tempo.Error) {
  tempo.new_offset(minutes)
}

/// Creates a new offset from a string literal, but will panic if the string
/// is invalid. Accepted formats are `(+-)hh:mm`, `(+-)hhmm`, `(+-)hh`, and
/// `(+-)h`.
///  
/// Useful for declaring offset literals that you know are valid within your 
/// program.
/// 
/// ## Example
/// 
/// ```gleam
/// offset.literal("-04:00")
/// |> offset.to_string
/// // -> "-04:00"
/// ```
pub fn literal(offset: String) -> tempo.Offset {
  case from_string(offset) {
    Ok(offset) -> offset
    Error(tempo.OffsetInvalidFormat) -> panic as "Invalid offset literal format"
    Error(tempo.OffsetOutOfBounds) -> panic as "Invalid offset literal value"
    Error(_) -> panic as "Invalid offset literal"
  }
}

fn validate(offset: tempo.Offset) -> Result(tempo.Offset, tempo.Error) {
  tempo.validate_offset(offset)
}

/// Converts an offset to a string representation.
/// 
/// Will not return "Z" for a zero offset because it is probably not what
/// the user wants without the context of a full datetime. Datetime modules
/// building on this should cover formatting for Z themselves.
/// 
/// ## Example
/// 
/// ```gleam
/// offset.literal("-00")
/// |> offset.to_string
/// // -> "-00:00"
/// ```
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
    _, 0, 0 -> "-00:00"

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

/// Tries to create a new offset from a string. Accepted formats are 
/// `(+-)hh:mm`, `(+-)hhmm`, `(+-)hh`, and `(+-)h`.
/// 
/// ## Example
/// 
/// ```gleam
/// offset.from_string("-04")
/// |> result.map(offset.to_string)
/// // -> Ok("-04:00")
/// ```
pub fn from_string(offset: String) -> Result(tempo.Offset, tempo.Error) {
  case offset {
    // Parse Z format
    "Z" -> Ok(tempo.Offset(0))
    "z" -> Ok(tempo.Offset(0))

    // Parse +-hh:mm format
    _ -> {
      use #(sign, hour, minute): #(String, String, String) <- result.try(case
        string.split(offset, ":")
      {
        [hour, minute] ->
          case string.length(hour), string.length(minute) {
            3, 2 ->
              Ok(#(
                string.slice(hour, at_index: 0, length: 1),
                string.slice(hour, at_index: 1, length: 2),
                minute,
              ))
            _, _ -> Error(tempo.OffsetInvalidFormat)
          }
        _ ->
          // Parse +-hhmm format, +-hh format, or +-h format
          case string.length(offset) {
            5 ->
              Ok(#(
                string.slice(offset, at_index: 0, length: 1),
                string.slice(offset, at_index: 1, length: 2),
                string.slice(offset, at_index: 3, length: 2),
              ))
            3 ->
              Ok(#(
                string.slice(offset, at_index: 0, length: 1),
                string.slice(offset, at_index: 1, length: 2),
                "0",
              ))
            2 ->
              Ok(#(
                string.slice(offset, at_index: 0, length: 1),
                string.slice(offset, at_index: 1, length: 1),
                "0",
              ))
            _ -> Error(tempo.OffsetInvalidFormat)
          }
      })

      case sign, int.parse(hour), int.parse(minute) {
        _, Ok(0), Ok(0) -> Ok(tempo.Offset(0))
        "-", Ok(hour), Ok(minute) if hour <= 24 && minute <= 60 ->
          Ok(tempo.Offset(-{ hour * 60 + minute }))
        "+", Ok(hour), Ok(minute) if hour <= 24 && minute <= 60 ->
          Ok(tempo.Offset(hour * 60 + minute))
        _, _, _ -> Error(tempo.OffsetInvalidFormat)
      }
    }
  }
  |> result.try(validate)
}

@internal
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
