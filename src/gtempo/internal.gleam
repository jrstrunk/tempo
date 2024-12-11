//// Units to be shared by the `Period` and `Duration` APIs.

import gleam/float
import gleam/int
import gleam/list
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

pub const imprecise_day_microseconds = 86_400_000_000

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
    n if n >= imprecise_day_microseconds ->
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

pub fn format_as_many(microseconds, units units: List(Unit), decimals decimals) {
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
    Day -> imprecise_day_microseconds
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
  days * imprecise_day_microseconds
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
  microseconds / imprecise_day_microseconds
}

pub fn as_days_fractional(microseconds: Int) -> Float {
  int.to_float(microseconds) /. int.to_float(imprecise_day_microseconds)
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
