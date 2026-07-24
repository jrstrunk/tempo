//// Units to be shared by the `Period` and `Duration` APIs, and the byte level
//// scanning primitives shared by all of Tempo's parsers.

import gleam/bit_array
import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub type Unit {
  Year
  Month
  Week
  Day
  Hour
  CalculatedYear(years: Int, microseconds: Int)
  CalculatedMonth(months: Int, microseconds: Int)
  Minute
  Second
  Millisecond
  Microsecond
  Nothing
}

pub const imprecise_year_microseconds = 31_449_600_000_000

pub const imprecise_month_microseconds = 2_592_000_000_000

pub const imprecise_week_microseconds = 604_800_000_000

pub const day_microseconds = 86_400_000_000

pub const hour_microseconds = 3_600_000_000

pub const minute_microseconds = 60_000_000

pub const second_microseconds = 1_000_000

pub const millisecond_microseconds = 1000

pub fn format(microseconds: Int) {
  case microseconds {
    n if n >= imprecise_year_microseconds ->
      format_as_many(microseconds, [Year, Week, Day, Hour, Minute], decimals: 0)
    n if n >= imprecise_week_microseconds ->
      format_as_many(microseconds, [Week, Day, Hour, Minute], decimals: 0)
    n if n >= day_microseconds ->
      format_as_many(microseconds, [Day, Hour, Minute], decimals: 0)
    n if n >= hour_microseconds ->
      format_as_many(microseconds, [Hour, Minute, Second], decimals: 2)
    n if n >= minute_microseconds ->
      format_as_many(microseconds, [Minute, Second], decimals: 3)
    n if n >= second_microseconds ->
      format_as(microseconds, Second, decimals: 3)
    n if n >= millisecond_microseconds ->
      format_as(microseconds, Millisecond, decimals: 0)
    _ -> format_as(microseconds, Microsecond, decimals: 0)
  }
}

pub fn format_as(
  microseconds: Int,
  unit unit: Unit,
  decimals decimals: Int,
) -> String {
  let in_unit = as_unit_fractional(microseconds, unit)

  let decimal =
    float.truncate(in_unit)
    |> int.to_float
    |> float.subtract(in_unit, _)

  let decimal_formatted =
    decimal
    |> float.to_string
    |> string.slice(at_index: 2, length: decimals)
    |> string.pad_end(to: decimals, with: "0")

  let whole =
    float.truncate(in_unit)
    |> int.to_string

  whole
  <> case decimals > 0 {
    True -> "."
    False -> ""
  }
  <> decimal_formatted
  <> " "
  <> unit_to_string(unit)
  <> case { whole == "1" || whole == "-1" } && decimal == 0.0 {
    True -> ""
    False -> "s"
  }
}

pub fn format_as_many(
  microseconds,
  units units: List(Unit),
  decimals decimals,
) {
  list.index_fold(units, #(microseconds, ""), fn(accumulator, unit: Unit, i) {
    case list.length(units) == i + 1 {
      // Handle the last unit differently
      True -> #(
        0,
        accumulator.1
          // If there is more than 2 units, add an "and" before the last unit
          <> case list.length(units) != 1 {
          True -> "and "
          False -> ""
        }
          // Apply decimals to the last unit
          <> format_as(accumulator.0, unit, decimals),
      )

      // Handle every non-last unit the same
      False -> {
        // The duration left after the taking off the whole current unit
        let remaining_duration = microseconds % in_microseconds(unit)

        let formated_current_unit =
          accumulator.0 - remaining_duration
          |> format_as(unit, 0)

        #(
          remaining_duration,
          accumulator.1
            <> formated_current_unit
            // If there is more than 2 units, add a comma after each 
            // non-last unit
            <> case list.length(units) > 2 {
            True -> ", "
            False -> " "
          },
        )
      }
    }
  }).1
}

pub fn unit_to_string(unit: Unit) -> String {
  case unit {
    Year -> "~year"
    CalculatedYear(_, _) -> "year"
    Month -> "~month"
    CalculatedMonth(_, _) -> "month"
    Week -> "week"
    Day -> "day"
    Hour -> "hour"
    Minute -> "minute"
    Second -> "second"
    Millisecond -> "millisecond"
    Microsecond -> "microsecond"
    Nothing -> "no time"
  }
}

pub fn in_microseconds(unit) {
  case unit {
    Year -> imprecise_year_microseconds
    Month -> imprecise_month_microseconds
    Week -> imprecise_week_microseconds
    Day -> day_microseconds
    CalculatedYear(_, microseconds: microseconds) -> microseconds
    CalculatedMonth(_, microseconds: microseconds) -> microseconds
    Hour -> hour_microseconds
    Minute -> minute_microseconds
    Second -> second_microseconds
    Millisecond -> millisecond_microseconds
    Microsecond -> 1
    Nothing -> 0
  }
}

pub fn as_unit(microseconds: Int, unit: Unit) {
  case unit {
    Year -> as_years_imprecise(microseconds)
    CalculatedYear(_, years: years) -> years
    Month -> as_months_imprecise(microseconds)
    CalculatedMonth(_, months: months) -> months
    Week -> as_weeks_imprecise(microseconds)
    Day -> as_days_imprecise(microseconds)
    Hour -> as_hours(microseconds)
    Minute -> as_minutes(microseconds)
    Second -> as_seconds(microseconds)
    Millisecond -> as_milliseconds(microseconds)
    Microsecond -> as_microseconds(microseconds)
    Nothing -> 0
  }
}

pub fn as_unit_fractional(microseconds: Int, unit: Unit) {
  case unit {
    Year -> as_years_imprecise_fractional(microseconds)
    CalculatedYear(_, years: years) -> years |> int.to_float
    Month -> as_months_imprecise_fractional(microseconds)
    CalculatedMonth(_, months: months) -> months |> int.to_float
    Week -> as_weeks_imprecise_fractional(microseconds)
    Day -> as_days_fractional(microseconds)
    Hour -> as_hours_fractional(microseconds)
    Minute -> as_minutes_fractional(microseconds)
    Second -> as_seconds_fractional(microseconds)
    Millisecond -> as_milliseconds_fractional(microseconds)
    Microsecond -> as_microseconds_fractional(microseconds)
    Nothing -> 0.0
  }
}

pub fn imprecise_years(years: Int) -> Int {
  years * imprecise_year_microseconds
}

pub fn imprecise_months(months: Int) -> Int {
  months * imprecise_month_microseconds
}

pub fn imprecise_weeks(weeks: Int) -> Int {
  weeks * imprecise_week_microseconds
}

pub fn imprecise_days(days: Int) -> Int {
  days * day_microseconds
}

pub fn hours(hours: Int) -> Int {
  hours * hour_microseconds
}

pub fn minutes(minutes: Int) -> Int {
  minutes * minute_microseconds
}

pub fn seconds(seconds: Int) -> Int {
  seconds * second_microseconds
}

pub fn milliseconds(milliseconds: Int) {
  milliseconds * millisecond_microseconds
}

pub fn microseconds(microseconds: Int) {
  microseconds
}

pub fn as_years_imprecise(microseconds: Int) {
  microseconds / imprecise_year_microseconds
}

pub fn as_years_imprecise_fractional(microseconds: Int) {
  int.to_float(microseconds) /. int.to_float(imprecise_year_microseconds)
}

pub fn as_months_imprecise(microseconds: Int) {
  microseconds / imprecise_month_microseconds
}

pub fn as_months_imprecise_fractional(microseconds: Int) {
  int.to_float(microseconds) /. int.to_float(imprecise_month_microseconds)
}

pub fn as_weeks_imprecise(microseconds: Int) -> Int {
  microseconds / imprecise_week_microseconds
}

pub fn as_weeks_imprecise_fractional(microseconds: Int) -> Float {
  int.to_float(microseconds) /. int.to_float(imprecise_week_microseconds)
}

pub fn as_days_imprecise(microseconds: Int) -> Int {
  microseconds / day_microseconds
}

pub fn as_days_fractional(microseconds: Int) -> Float {
  int.to_float(microseconds) /. int.to_float(day_microseconds)
}

pub fn as_hours(microseconds: Int) -> Int {
  microseconds / hour_microseconds
}

pub fn as_hours_fractional(microseconds: Int) -> Float {
  int.to_float(microseconds) /. int.to_float(hour_microseconds)
}

pub fn as_minutes(microseconds: Int) -> Int {
  microseconds / minute_microseconds
}

pub fn as_minutes_fractional(microseconds: Int) -> Float {
  int.to_float(microseconds) /. int.to_float(minute_microseconds)
}

pub fn as_seconds(microseconds: Int) -> Int {
  microseconds / second_microseconds
}

pub fn as_seconds_fractional(microseconds: Int) -> Float {
  int.to_float(microseconds) /. int.to_float(second_microseconds)
}

pub fn as_milliseconds(microseconds: Int) -> Int {
  microseconds / millisecond_microseconds
}

pub fn as_milliseconds_fractional(microseconds: Int) -> Float {
  int.to_float(microseconds) /. int.to_float(millisecond_microseconds)
}

pub fn as_microseconds(microseconds: Int) -> Int {
  microseconds
}

pub fn as_microseconds_fractional(microseconds: Int) -> Float {
  int.to_float(microseconds)
}

/// This is the implementation of int.floor_divide but unwrapped with the knowledge
/// that the divisor is never zero
pub fn floor_div(dividend: Int, divisor: Int) -> Int {
  case
    { { dividend > 0 && divisor < 0 } || { dividend < 0 && divisor > 0 } }
    && dividend % divisor != 0
  {
    True -> dividend / divisor - 1
    False -> dividend / divisor
  }
}

pub fn div_with_remainder(a: Int, b: Int) -> #(Int, Int) {
  #(floor_div(a, b), modulo_unwrap(a, b))
}

/// This is the implementation of int.modulo but unwrapped with the knowledge that the
/// the divisor is never zero in our calculations
pub fn modulo_unwrap(dividend: Int, divisor: Int) -> Int {
  let remainder = dividend % divisor
  case { remainder > 0 && divisor < 0 } || { remainder < 0 && divisor > 0 } {
    True -> remainder + divisor
    False -> remainder
  }
}

// Parsing -------------------------------------------------------------------
//
// Parsers work over `BitArray` values instead of `String` values because bit
// array patterns compile down to plain byte comparisons on both the Erlang and
// the JavaScript target, and because taking a value off the front of the input
// is a slice rather than a copy. Every function here follows the same shape: it
// takes the remaining input and returns what it parsed along with the input
// that is left over, so parsers can be chained together with `use` expressions.

/// The `0` character as a byte
pub const byte_zero = 0x30

/// The `9` character as a byte
pub const byte_nine = 0x39

/// The `:` character as a byte
pub const byte_colon = 0x3A

/// Whether the given byte is an ASCII letter, of either case.
///
pub fn is_letter(byte: Int) -> Bool {
  { 0x41 <= byte && byte <= 0x5A } || { 0x61 <= byte && byte <= 0x7A }
}

/// Takes exactly `count` digits from the front of the input, returning the
/// number they spell out.
///
pub fn take_digits(
  from bytes: BitArray,
  count count: Int,
) -> Result(#(Int, BitArray), Nil) {
  do_take_digits(bytes, count, 0)
}

fn do_take_digits(
  bytes: BitArray,
  count: Int,
  acc: Int,
) -> Result(#(Int, BitArray), Nil) {
  case bytes {
    _ if count <= 0 -> Ok(#(acc, bytes))
    <<byte, rest:bytes>> if byte_zero <= byte && byte <= byte_nine ->
      do_take_digits(rest, count - 1, acc * 10 + { byte - byte_zero })
    _ -> Error(Nil)
  }
}

/// Takes a number written with either one or two digits, preferring two.
///
pub fn take_one_or_two_digits(
  from bytes: BitArray,
) -> Result(#(Int, BitArray), Nil) {
  take_digits(bytes, count: 2)
  |> result.try_recover(fn(_) { take_digits(bytes, count: 1) })
}

/// Takes up to `limit` digits from the front of the input, returning the
/// number they spell out and how many digits were taken. Taking no digits at
/// all is not an error, it returns zero of both.
///
pub fn take_digits_up_to(
  from bytes: BitArray,
  limit limit: Int,
) -> #(Int, Int, BitArray) {
  do_take_digits_up_to(bytes, limit, 0, 0)
}

fn do_take_digits_up_to(
  bytes: BitArray,
  limit: Int,
  acc: Int,
  taken: Int,
) -> #(Int, Int, BitArray) {
  case bytes {
    <<byte, rest:bytes>>
      if taken < limit && byte_zero <= byte && byte <= byte_nine
    ->
      do_take_digits_up_to(
        rest,
        limit,
        acc * 10 + { byte - byte_zero },
        taken + 1,
      )
    _ -> #(acc, taken, bytes)
  }
}

/// Skips past `count` bytes, failing if there are not that many left.
///
pub fn skip(from bytes: BitArray, count count: Int) -> Result(BitArray, Nil) {
  case count <= 0 {
    True -> Ok(bytes)
    False ->
      case bytes {
        <<_, rest:bytes>> -> skip(rest, count - 1)
        _ -> Error(Nil)
      }
  }
}

/// Takes the given number of bytes off the front of the input as a string.
///
pub fn take_string(
  from bytes: BitArray,
  count count: Int,
) -> Result(#(String, BitArray), Nil) {
  case bit_array.slice(bytes, 0, count) {
    Ok(taken) ->
      case bit_array.to_string(taken), skip(bytes, count) {
        Ok(taken), Ok(rest) -> Ok(#(taken, rest))
        _, _ -> Error(Nil)
      }
    Error(Nil) -> Error(Nil)
  }
}

/// Takes a single character off the front of the input. Characters outside of
/// ASCII are made of more than one byte, so this is not the same as taking a
/// single byte.
///
pub fn take_character(
  from bytes: BitArray,
) -> Result(#(String, BitArray), Nil) {
  // How many bytes a character takes up is encoded in its leading byte.
  let length = case bytes {
    <<byte, _:bytes>> if byte < 0x80 -> 1
    <<byte, _:bytes>> if byte < 0xE0 -> 2
    <<byte, _:bytes>> if byte < 0xF0 -> 3
    _ -> 4
  }

  take_string(bytes, length)
}

/// Takes up to `count` characters off the front of the input, stopping early
/// when the input runs out rather than failing.
///
pub fn take_string_up_to(
  from bytes: BitArray,
  count count: Int,
) -> #(String, BitArray) {
  do_take_string_up_to(bytes, count, [])
}

fn do_take_string_up_to(
  bytes: BitArray,
  count: Int,
  acc: List(String),
) -> #(String, BitArray) {
  case count <= 0, take_character(bytes) {
    False, Ok(#(character, rest)) ->
      do_take_string_up_to(rest, count - 1, [character, ..acc])
    _, _ -> #(acc |> list.reverse |> string.concat, bytes)
  }
}

/// Runs `matcher` over the input and, when it succeeds, returns the text that
/// it consumed alongside the input that is left. Useful when a value has to be
/// validated as it is parsed but is wanted as text.
///
pub fn take_matched(
  from bytes: BitArray,
  with matcher: fn(BitArray) -> Result(BitArray, Nil),
) -> Result(#(String, BitArray), Nil) {
  use rest <- result.try(matcher(bytes))
  use #(matched, _) <- result.map(take_string(bytes, taken_length(bytes, rest)))
  #(matched, rest)
}

/// The text that was consumed from `bytes` in order to get to `rest`. Meant for
/// error values, where the part of the input that a parser was looking at needs
/// to be reported back.
///
pub fn taken_string(from bytes: BitArray, to rest: BitArray) -> String {
  case take_string(bytes, taken_length(bytes, rest)) {
    Ok(#(taken, _)) -> taken
    Error(Nil) -> ""
  }
}

/// The whole of the remaining input as a string.
///
pub fn remaining_string(bytes: BitArray) -> String {
  bit_array.to_string(bytes) |> result.unwrap("")
}

fn taken_length(bytes: BitArray, rest: BitArray) -> Int {
  bit_array.byte_size(bytes) - bit_array.byte_size(rest)
}

/// Moves past the given byte if it is at the front of the input.
///
pub fn accept_byte(
  from bytes: BitArray,
  value value: Int,
) -> Result(BitArray, Nil) {
  case bytes {
    <<byte, rest:bytes>> if byte == value -> Ok(rest)
    _ -> Error(Nil)
  }
}

/// Succeeds only when there is no input left to parse.
///
pub fn accept_empty(bytes: BitArray) -> Result(Nil, Nil) {
  case bytes {
    <<>> -> Ok(Nil)
    _ -> Error(Nil)
  }
}

/// Runs `body` with each option in turn and returns the first success. This
/// gives a parser the same backtracking behaviour that a greedy regular
/// expression has: the first option is preferred, but a later part of the
/// parser failing makes it fall back to the next one.
///
pub fn backtrack(
  over options: List(a),
  with body: fn(a) -> Result(b, Nil),
) -> Result(b, Nil) {
  case options {
    [] -> Error(Nil)
    [option, ..options] ->
      case body(option) {
        Ok(value) -> Ok(value)
        Error(Nil) -> backtrack(options, body)
      }
  }
}

/// Finds the leftmost position at which `matcher` succeeds, returning what it
/// matched along with the input that is left once the matched region has been
/// cut out of it.
///
/// This is the equivalent of scanning a string for the first match of a
/// regular expression and then deleting that match from the string.
///
pub fn scan(
  in bytes: BitArray,
  with matcher: fn(BitArray) -> Result(#(a, BitArray), Nil),
) -> Result(#(a, BitArray), Nil) {
  do_scan(bytes, matcher, 0, bit_array.byte_size(bytes))
}

fn do_scan(
  bytes: BitArray,
  matcher: fn(BitArray) -> Result(#(a, BitArray), Nil),
  offset: Int,
  size: Int,
) -> Result(#(a, BitArray), Nil) {
  case offset > size {
    True -> Error(Nil)
    False -> {
      let assert Ok(tail) = bit_array.slice(bytes, offset, size - offset)

      case matcher(tail) {
        Error(Nil) -> do_scan(bytes, matcher, offset + 1, size)
        Ok(#(value, rest)) -> {
          let assert Ok(head) = bit_array.slice(bytes, 0, offset)
          Ok(#(value, <<head:bits, rest:bits>>))
        }
      }
    }
  }
}

/// Whether the input contains a run of `count` or more digits in a row.
///
pub fn has_digit_run(in bytes: BitArray, of count: Int) -> Bool {
  do_has_digit_run(bytes, count, 0)
}

fn do_has_digit_run(bytes: BitArray, count: Int, run: Int) -> Bool {
  case bytes {
    _ if run >= count -> True
    <<byte, rest:bytes>> if byte_zero <= byte && byte <= byte_nine ->
      do_has_digit_run(rest, count, run + 1)
    <<_, rest:bytes>> -> do_has_digit_run(rest, count, 0)
    _ -> False
  }
}

// Date, time, and offset parsers ---------------------------------------------
//
// These take one part of a datetime off the front of the input and leave the
// rest of it alone, so that they can be used both on their own and as a step of
// a larger parser like the one for a whole datetime.

/// Takes a date off the front of the input, returning the year, month, and day
/// it spells out. Any of the formats `YYYY-MM-DD`, `YYYY-M-D`, or `YYYYMMDD`
/// are accepted, with `/`, `.`, `_`, or a space also allowed as the delimiter.
///
pub fn take_date_parts(
  from input: BitArray,
) -> Result(#(#(Int, Int, Int), BitArray), Nil) {
  take_delimited_date(input)
  |> result.try_recover(fn(_) { take_condensed_date(input) })
}

/// Takes `YYYY-MM-DD`, and the same with `/`, `.`, `_`, or a space used as the
/// delimiter instead. The month and the day may each be written with or without
/// a leading zero.
fn take_delimited_date(
  input: BitArray,
) -> Result(#(#(Int, Int, Int), BitArray), Nil) {
  let #(year, year_digits, input) = take_digits_up_to(input, limit: 10)
  use <- bool.guard(when: year_digits == 0, return: Error(Nil))

  use #(delimiter, input) <- result.try(take_date_delimiter(input))
  use #(month, input) <- result.try(take_one_or_two_digits(input))
  use input <- result.try(accept_byte(input, value: delimiter))
  use #(day, input) <- result.map(take_one_or_two_digits(input))

  #(#(year, month, day), input)
}

/// Takes `YYYYMMDD`, where every part has to be written out in full as there is
/// nothing to tell them apart otherwise.
fn take_condensed_date(
  input: BitArray,
) -> Result(#(#(Int, Int, Int), BitArray), Nil) {
  use #(year, input) <- result.try(take_digits(input, count: 4))
  use #(month, input) <- result.try(take_digits(input, count: 2))
  use #(day, input) <- result.map(take_digits(input, count: 2))

  #(#(year, month, day), input)
}

fn take_date_delimiter(input: BitArray) -> Result(#(Int, BitArray), Nil) {
  case input {
    <<delimiter, input:bytes>>
      if delimiter == 0x2D
      || delimiter == 0x2F
      || delimiter == 0x2E
      || delimiter == 0x5F
      || delimiter == 0x20
    -> Ok(#(delimiter, input))
    _ -> Error(Nil)
  }
}

/// Moves past the delimiter that separates the date of a datetime from its
/// time, which may be a `T`, a `t`, an underscore, or a space.
///
pub fn accept_datetime_delimiter(input: BitArray) -> Result(BitArray, Nil) {
  case input {
    <<delimiter, input:bytes>>
      if delimiter == 0x54
      || delimiter == 0x74
      || delimiter == 0x5F
      || delimiter == 0x20
    -> Ok(input)
    _ -> Error(Nil)
  }
}

/// Takes a time off the front of the input, returning the hour, minute, second,
/// and microsecond it spells out. Any of the formats `hh:mm:ss.s`, `hh:mm:ss`,
/// `hh:mm`, `hhmmss.s`, `hhmmss`, or `hhmm` are accepted.
///
pub fn take_time_parts(
  from input: BitArray,
) -> Result(#(#(Int, Int, Int, Int), BitArray), Nil) {
  take_delimited_time(input)
  |> result.try_recover(fn(_) { take_condensed_time(input) })
}

/// Takes `hh:mm:ss.s`, `hh:mm:ss`, and `hh:mm`, where each part may be written
/// with or without a leading zero.
fn take_delimited_time(
  input: BitArray,
) -> Result(#(#(Int, Int, Int, Int), BitArray), Nil) {
  use #(hour, input) <- result.try(take_one_or_two_digits(input))
  use input <- result.try(accept_byte(input, value: byte_colon))
  use #(minute, input) <- result.map(take_one_or_two_digits(input))

  // The second is optional, as in "04:00".
  case take_delimited_second(input) {
    Ok(#(second, microsecond, input)) -> #(
      #(hour, minute, second, microsecond),
      input,
    )
    Error(Nil) -> #(#(hour, minute, 0, 0), input)
  }
}

fn take_delimited_second(
  input: BitArray,
) -> Result(#(Int, Int, BitArray), Nil) {
  use input <- result.try(accept_byte(input, value: byte_colon))
  use #(second, input) <- result.try(take_one_or_two_digits(input))
  use #(microsecond, input) <- result.map(take_second_fraction(input))

  #(second, microsecond, input)
}

/// Takes `hhmmss.s`, `hhmmss`, and `hhmm`, where every part has to be written
/// out in full as there is nothing to tell them apart otherwise.
fn take_condensed_time(
  input: BitArray,
) -> Result(#(#(Int, Int, Int, Int), BitArray), Nil) {
  use #(hour, input) <- result.try(take_digits(input, count: 2))
  use #(minute, input) <- result.map(take_digits(input, count: 2))

  case take_condensed_second(input) {
    Ok(#(second, microsecond, input)) -> #(
      #(hour, minute, second, microsecond),
      input,
    )
    Error(Nil) -> #(#(hour, minute, 0, 0), input)
  }
}

fn take_condensed_second(
  input: BitArray,
) -> Result(#(Int, Int, BitArray), Nil) {
  use #(second, input) <- result.try(take_digits(input, count: 2))
  use #(microsecond, input) <- result.map(take_second_fraction(input))

  #(second, microsecond, input)
}

/// Takes the `.945` of `14:50:04.945` as microseconds. Up to six digits of
/// precision can be kept, any more than that cannot be represented.
fn take_second_fraction(input: BitArray) -> Result(#(Int, BitArray), Nil) {
  case input {
    <<".", input:bytes>> -> {
      let #(fraction, digits, input) = take_digits_up_to(input, limit: 6)

      // A seventh digit would be precision that cannot be kept, so the whole
      // fraction is rejected rather than silently rounded.
      case input {
        <<byte, _:bytes>> if byte_zero <= byte && byte <= byte_nine ->
          Error(Nil)
        _ ->
          Ok(#(
            case digits {
              0 -> 0
              1 -> fraction * 100_000
              2 -> fraction * 10_000
              3 -> fraction * 1000
              4 -> fraction * 100
              5 -> fraction * 10
              _ -> fraction
            },
            input,
          ))
      }
    }
    _ -> Ok(#(0, input))
  }
}

/// Takes a UTC offset off the front of the input, returning the number of
/// minutes it is offset by. Any of the formats `Z`, `+hh:mm`, `+hhmm`, `+hh`,
/// or `+h` are accepted, as well as the same with a `-`.
///
pub fn take_offset_minutes(
  from input: BitArray,
) -> Result(#(Int, BitArray), Nil) {
  case input {
    <<"Z", input:bytes>> | <<"z", input:bytes>> -> Ok(#(0, input))
    _ -> take_numeric_offset_minutes(input)
  }
}

fn take_numeric_offset_minutes(
  input: BitArray,
) -> Result(#(Int, BitArray), Nil) {
  use #(is_negative, input) <- result.try(take_offset_direction(input))

  use #(hours, minutes, input) <- result.try(
    take_hour_colon_minute_offset(input)
    |> result.try_recover(fn(_) { take_hour_minute_offset(input) })
    |> result.try_recover(fn(_) { take_hour_offset(input) }),
  )

  case hours <= 24 && minutes <= 60 {
    False -> Error(Nil)
    True ->
      case is_negative {
        True -> Ok(#(-{ hours * 60 + minutes }, input))
        False -> Ok(#(hours * 60 + minutes, input))
      }
  }
}

fn take_offset_direction(input: BitArray) -> Result(#(Bool, BitArray), Nil) {
  case input {
    <<"-", input:bytes>> -> Ok(#(True, input))
    <<"+", input:bytes>> -> Ok(#(False, input))
    _ -> Error(Nil)
  }
}

fn take_hour_colon_minute_offset(
  input: BitArray,
) -> Result(#(Int, Int, BitArray), Nil) {
  use #(hours, input) <- result.try(take_digits(input, count: 2))
  use input <- result.try(accept_byte(input, value: byte_colon))
  use #(minutes, input) <- result.map(take_digits(input, count: 2))

  #(hours, minutes, input)
}

fn take_hour_minute_offset(
  input: BitArray,
) -> Result(#(Int, Int, BitArray), Nil) {
  use #(hours, input) <- result.try(take_digits(input, count: 2))
  use #(minutes, input) <- result.map(take_digits(input, count: 2))

  #(hours, minutes, input)
}

fn take_hour_offset(input: BitArray) -> Result(#(Int, Int, BitArray), Nil) {
  use #(hours, input) <- result.map(take_one_or_two_digits(input))

  #(hours, 0, input)
}
