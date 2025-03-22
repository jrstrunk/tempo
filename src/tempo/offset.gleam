//// Functions to use with the `Offset` type in Tempo. The offset values 
//// represents the time difference between the current time and UTC time.
//// 
//// ## Example
//// 
//// ```gleam
//// import tempo/offset
//// 
//// pub fn get_system_offset() {
////   offset.local()
////   |> offset.to_string
////   // -> "+05:00"
//// }
//// ```

import gleam/time/duration
import tempo
import tempo/error as tempo_error

/// The Tempo representation of the UTC offset.
pub const utc = tempo.utc

/// Returns the local offset of the host.
///
/// ## Example
///
/// ```gleam
/// offset.local()
/// |> offset.to_string
/// // -> "+05:00"
/// ```
pub fn local() -> tempo.Offset {
  tempo.offset_local_minutes() |> tempo.offset
}

@deprecated("Use the more explicitly named `from_duration` function instead")
pub fn new(from duration: duration.Duration) -> Result(tempo.Offset, Nil) {
  tempo.new_offset(duration)
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
    Error(tempo_error.OffsetInvalidFormat(..)) ->
      panic as "Invalid offset literal format"
    Error(tempo_error.OffsetOutOfBounds(..)) ->
      panic as "Invalid offset literal value"
  }
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
  tempo.offset_to_string(offset)
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
pub fn from_string(
  offset: String,
) -> Result(tempo.Offset, tempo_error.OffsetParseError) {
  tempo.offset_from_string(offset)
}

/// Creates a new validated offset from a duration. Offsets are most commonly
/// expressed as a number of minutes or hours.
/// 
/// ## Example
/// 
/// ```gleam
/// offset.new(duration.minutes(-65))
/// |> result.map(offset.to_string)
/// // -> Ok("-01:05")
/// ```
/// 
/// ```gleam
/// offset.new(duration.hours(36))
/// // -> Error(Nil)
/// ```
pub fn from_duration(duration: duration.Duration) -> Result(tempo.Offset, Nil) {
  tempo.new_offset(duration)
}

/// Converts an offset to a duration.
///
/// ## Example
///
/// ```gleam
/// offset.literal("-04:00")
/// |> offset.to_duration
/// // -> duration.hours(4)
/// ```
pub fn to_duration(offset: tempo.Offset) -> duration.Duration {
  tempo.offset_to_duration(offset)
}

/// Converts an offset parse error to a human readable error message.
/// 
/// ## Example
/// 
/// ```gleam
/// offset.from_string("bad offset")
/// |> snag.map_error(with: offset.describe_parse_error)
/// // -> snag.error("Invalid offset format: "bad offset"")
/// ```
pub fn describe_parse_error(error: tempo_error.OffsetParseError) -> String {
  tempo_error.describe_offset_parse_error(error)
}
