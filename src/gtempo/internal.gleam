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
  CalculatedYear(years: Int, nanoseconds: Int)
  CalculatedMonth(months: Int, nanoseconds: Int)
  Minute
  Second
  Millisecond
  Microsecond
  Nanosecond
  Nothing
}

pub const imprecise_year_nanoseconds = 31_449_600_000_000_000

pub const imprecise_month_nanoseconds = 2_592_000_000_000_000

pub const imprecise_week_nanoseconds = 604_800_000_000_000

pub const imprecise_day_nanoseconds = 86_400_000_000_000

pub const hour_nanoseconds = 3_600_000_000_000

pub const minute_nanoseconds = 60_000_000_000

pub const second_nanoseconds = 1_000_000_000

pub const millisecond_nanoseconds = 1_000_000

pub const microsecond_nanoseconds = 1000

pub fn format_as(
  nanoseconds: Int,
  unit unit: Unit,
  decimals decimals: Int,
) -> String {
  let in_unit = as_unit_fractional(nanoseconds, unit)

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

pub fn format_as_many(nanoseconds, units units: List(Unit), decimals decimals) {
  list.index_fold(units, #(nanoseconds, ""), fn(accumulator, unit: Unit, i) {
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
        let remaining_duration = nanoseconds % in_nanoseconds(unit)

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
    Nanosecond -> "nanosecond"
    Nothing -> "no time"
  }
}

pub fn in_nanoseconds(unit) {
  case unit {
    Year -> imprecise_year_nanoseconds
    Month -> imprecise_month_nanoseconds
    Week -> imprecise_week_nanoseconds
    Day -> imprecise_day_nanoseconds
    CalculatedYear(_, nanoseconds: nanoseconds) -> nanoseconds
    CalculatedMonth(_, nanoseconds: nanoseconds) -> nanoseconds
    Hour -> hour_nanoseconds
    Minute -> minute_nanoseconds
    Second -> second_nanoseconds
    Millisecond -> millisecond_nanoseconds
    Microsecond -> microsecond_nanoseconds
    Nanosecond -> 1
    Nothing -> 0
  }
}

pub fn as_unit(nanoseconds: Int, unit: Unit) {
  case unit {
    Year -> as_years_imprecise(nanoseconds)
    CalculatedYear(_, years: years) -> years
    Month -> as_months_imprecise(nanoseconds)
    CalculatedMonth(_, months: months) -> months
    Week -> as_weeks_imprecise(nanoseconds)
    Day -> as_days_imprecise(nanoseconds)
    Hour -> as_hours(nanoseconds)
    Minute -> as_minutes(nanoseconds)
    Second -> as_seconds(nanoseconds)
    Millisecond -> as_milliseconds(nanoseconds)
    Microsecond -> as_microseconds(nanoseconds)
    Nanosecond -> as_nanoseconds(nanoseconds)
    Nothing -> 0
  }
}

pub fn as_unit_fractional(nanoseconds: Int, unit: Unit) {
  case unit {
    Year -> as_years_imprecise_fractional(nanoseconds)
    CalculatedYear(_, years: years) -> years |> int.to_float
    Month -> as_months_imprecise_fractional(nanoseconds)
    CalculatedMonth(_, months: months) -> months |> int.to_float
    Week -> as_weeks_imprecise_fractional(nanoseconds)
    Day -> as_days_fractional(nanoseconds)
    Hour -> as_hours_fractional(nanoseconds)
    Minute -> as_minutes_fractional(nanoseconds)
    Second -> as_seconds_fractional(nanoseconds)
    Millisecond -> as_milliseconds_fractional(nanoseconds)
    Microsecond -> as_microseconds_fractional(nanoseconds)
    Nanosecond -> as_nanoseconds(nanoseconds) |> int.to_float
    Nothing -> 0.0
  }
}

pub fn imprecise_years(years: Int) -> Int {
  years * imprecise_year_nanoseconds
}

pub fn imprecise_months(months: Int) -> Int {
  months * imprecise_month_nanoseconds
}

pub fn imprecise_weeks(weeks: Int) -> Int {
  weeks * imprecise_week_nanoseconds
}

pub fn imprecise_days(days: Int) -> Int {
  days * imprecise_day_nanoseconds
}

pub fn hours(hours: Int) -> Int {
  hours * hour_nanoseconds
}

pub fn minutes(minutes: Int) -> Int {
  minutes * minute_nanoseconds
}

pub fn seconds(seconds: Int) -> Int {
  seconds * second_nanoseconds
}

pub fn milliseconds(milliseconds: Int) {
  milliseconds * millisecond_nanoseconds
}

pub fn microseconds(microseconds: Int) {
  microseconds * microsecond_nanoseconds
}

pub fn nanoseconds(nanoseconds: Int) {
  nanoseconds
}

pub fn as_years_imprecise(nanoseconds: Int) {
  nanoseconds / imprecise_year_nanoseconds
}

pub fn as_years_imprecise_fractional(nanoseconds: Int) {
  int.to_float(nanoseconds) /. int.to_float(imprecise_year_nanoseconds)
}

pub fn as_months_imprecise(nanoseconds: Int) {
  nanoseconds / imprecise_month_nanoseconds
}

pub fn as_months_imprecise_fractional(nanoseconds: Int) {
  int.to_float(nanoseconds) /. int.to_float(imprecise_month_nanoseconds)
}

pub fn as_weeks_imprecise(nanoseconds: Int) -> Int {
  nanoseconds / imprecise_week_nanoseconds
}

pub fn as_weeks_imprecise_fractional(nanoseconds: Int) -> Float {
  int.to_float(nanoseconds) /. int.to_float(imprecise_week_nanoseconds)
}

pub fn as_days_imprecise(nanoseconds: Int) -> Int {
  nanoseconds / imprecise_day_nanoseconds
}

pub fn as_days_fractional(nanoseconds: Int) -> Float {
  int.to_float(nanoseconds) /. int.to_float(imprecise_day_nanoseconds)
}

pub fn as_hours(nanoseconds: Int) -> Int {
  nanoseconds / hour_nanoseconds
}

pub fn as_hours_fractional(nanoseconds: Int) -> Float {
  int.to_float(nanoseconds) /. int.to_float(hour_nanoseconds)
}

pub fn as_minutes(nanoseconds: Int) -> Int {
  nanoseconds / minute_nanoseconds
}

pub fn as_minutes_fractional(nanoseconds: Int) -> Float {
  int.to_float(nanoseconds) /. int.to_float(minute_nanoseconds)
}

pub fn as_seconds(nanoseconds: Int) -> Int {
  nanoseconds / second_nanoseconds
}

pub fn as_seconds_fractional(nanoseconds: Int) -> Float {
  int.to_float(nanoseconds) /. int.to_float(second_nanoseconds)
}

pub fn as_milliseconds(nanoseconds: Int) -> Int {
  nanoseconds / millisecond_nanoseconds
}

pub fn as_milliseconds_fractional(nanoseconds: Int) -> Float {
  int.to_float(nanoseconds) /. int.to_float(millisecond_nanoseconds)
}

pub fn as_microseconds(nanoseconds: Int) -> Int {
  nanoseconds / microsecond_nanoseconds
}

pub fn as_microseconds_fractional(nanoseconds: Int) -> Float {
  int.to_float(nanoseconds) /. int.to_float(microsecond_nanoseconds)
}

pub fn as_nanoseconds(nanoseconds: Int) -> Int {
  nanoseconds
}
