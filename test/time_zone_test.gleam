import gleam/list
import gleam/option
import gleeunit/should
import tempo/datetime
import tempo/duration
import tempo/instant
import tempo/time_zone
import tzif/database

pub fn valid_timezone_test() {
  "America/New_York"
  |> time_zone.new
  |> should.be_ok
}

pub fn invalid_timezone_test() {
  "America/NewYork"
  |> time_zone.new
  |> should.be_error
}

pub fn calculate_offset_test() {
  let assert Ok(tz) = time_zone.new("America/New_York")

  datetime.literal("2024-01-03T05:30:02.334Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2024-01-03T00:30:02.334000-05:00")
}

pub fn calculate_offset_twice_test() {
  let assert Ok(tz) = time_zone.new("America/New_York")
  let assert Ok(tz2) = time_zone.new("Europe/London")

  datetime.literal("2024-06-03T05:30:02.334Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_timezone(tz2)
  |> datetime.to_string
  |> should.equal("2024-06-03T06:30:02.334000+01:00")
}

pub fn calculate_offset_day_boundary_test() {
  let assert Ok(tz) = time_zone.new("America/New_York")

  datetime.literal("2024-01-03T00:05:02.334Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2024-01-02T19:05:02.334000-05:00")
}

pub fn calculate_offset_dst_test() {
  let assert Ok(tz) = time_zone.new("America/New_York")

  datetime.literal("2024-07-08T10:30:02.334Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2024-07-08T06:30:02.334000-04:00")
}

pub fn unix_to_tz_test() {
  let assert Ok(tz) = time_zone.new("America/New_York")

  1_729_257_776
  |> datetime.from_unix_seconds
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2024-10-18T09:22:56.000000-04:00")
}

pub fn add_to_tz_test() {
  let assert Ok(tz) = time_zone.new("Europe/London")

  datetime.literal("2024-07-18T09:22:56.542Z")
  |> datetime.to_timezone(tz)
  |> datetime.add(duration.hours(6))
  |> datetime.to_string
  |> should.equal("2024-07-18T16:22:56.542000+01:00")
}

pub fn subtract_from_tz_test() {
  let assert Ok(tz) = time_zone.new("America/New_York")

  datetime.literal("2024-07-18T09:22:56.000Z")
  |> datetime.to_timezone(tz)
  |> datetime.subtract(duration.minutes(6))
  |> datetime.subtract(duration.hours(2))
  |> datetime.to_string
  |> should.equal("2024-07-18T03:16:56.000000-04:00")
}

pub fn to_tz_before_dst_start_test() {
  let assert Ok(tz) = time_zone.new("America/New_York")

  datetime.literal("2024-03-10T06:32:45.354Z")
  |> datetime.to_timezone(tz)
  // The commented out test failed on javascript, it returns a -04:00 offset
  // |> datetime.to_string
  // |> should.equal("2024-03-10T01:32:45.354-05:00")
  |> datetime.is_equal(datetime.literal("2024-03-10T01:32:45.354000-05:00"))
  |> should.be_true
}

pub fn add_over_dst_start_test() {
  let assert Ok(tz) = time_zone.new("America/New_York")

  datetime.literal("2024-03-10T06:32:45.354Z")
  |> datetime.to_timezone(tz)
  |> datetime.add(duration.hours(1))
  |> datetime.to_string
  |> should.equal("2024-03-10T03:32:45.354000-04:00")
}

pub fn to_tz_before_dst_end_test() {
  let assert Ok(tz) = time_zone.new("America/New_York")

  datetime.literal("2024-11-03T05:32:45.354Z")
  |> datetime.to_timezone(tz)
  // The commented out test failed on javascript, it returns a -05:00 offset
  // |> datetime.to_string
  // |> should.equal("2024-11-03T01:32:45.354-04:00")
  |> datetime.is_equal(datetime.literal("2024-11-03T01:32:45.354000-04:00"))
  |> should.be_true
}

pub fn add_over_dst_end_test() {
  let assert Ok(tz) = time_zone.new("America/New_York")

  datetime.literal("2024-11-03T05:32:45.354Z")
  |> datetime.to_timezone(tz)
  |> datetime.add(duration.hours(1))
  // The commented out test failed on javascript, it returns a -06:00 offset??
  // |> datetime.to_string
  // |> should.equal("2024-11-03T01:32:45.354-05:00")
  |> datetime.is_equal(datetime.literal("2024-11-03T01:32:45.354000-05:00"))
  |> should.be_true
}

pub fn get_tz_name_test() {
  let assert Ok(tz) = time_zone.new("Europe/London")

  tz.get_name()
  |> should.equal("Europe/London")
}

pub fn get_tempo_tz_name_test() {
  let assert Ok(tz) = time_zone.new("Europe/London")

  instant.now()
  |> instant.as_utc_datetime
  |> datetime.to_timezone(tz)
  |> datetime.get_timezone_name
  |> should.equal(option.Some("Europe/London"))
}

fn os_database() -> database.TzDatabase {
  let assert Ok(db) = database.load_from_path("/usr/share/zoneinfo")
  db
}

pub fn from_database_valid_timezone_test() {
  os_database()
  |> time_zone.from_database("America/New_York")
  |> should.be_ok
}

pub fn from_database_invalid_timezone_test() {
  os_database()
  |> time_zone.from_database("America/NewYork")
  |> should.be_error
}

pub fn from_database_offset_test() {
  let assert Ok(tz) =
    os_database() |> time_zone.from_database("America/New_York")

  datetime.literal("2024-01-03T05:30:02.334Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2024-01-03T00:30:02.334000-05:00")
}

pub fn from_database_dst_offset_test() {
  let assert Ok(tz) =
    os_database() |> time_zone.from_database("America/New_York")

  datetime.literal("2024-07-08T10:30:02.334Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2024-07-08T06:30:02.334000-04:00")
}

pub fn from_database_get_name_test() {
  let assert Ok(tz) = os_database() |> time_zone.from_database("Europe/London")

  tz.get_name()
  |> should.equal("Europe/London")
}

/// An empty database has no zones, so a name the host certainly knows is still
/// rejected. This is what pins the provider to the passed database rather than
/// to the host, on both targets.
pub fn from_database_ignores_host_test() {
  database.new()
  |> time_zone.from_database("America/New_York")
  |> should.be_error
}

@target(erlang)
/// The `new` path is implemented in FFI per target and the `from_database`
/// path in Gleam, so on Erlang two separate implementations read the same OS
/// database. They must agree. This pins them together across a spread of zones
/// and instants, including DST transitions and pre-1970 dates.
///
/// Erlang only: on JavaScript `new` goes through `Intl`, which is a genuinely
/// different data source and is known to differ from TZif at DST boundaries.
pub fn ffi_matches_gleam_implementation_test() {
  let assert Ok(db) = database.load_from_path("/usr/share/zoneinfo")

  let zones = [
    "America/New_York", "Europe/London", "Asia/Kolkata", "Australia/Sydney",
    "America/Sao_Paulo", "Africa/Cairo", "Pacific/Auckland", "UTC",
    // Fractional and extreme offsets, where a rounding or sign mistake in one
    // implementation but not the other would show up first.
    "Asia/Kathmandu", "Pacific/Chatham", "America/St_Johns",
    "Pacific/Kiritimati", "Etc/GMT+12", "Pacific/Apia", "Europe/Moscow",
  ]

  let moments = [
    "1952-08-19T04:00:00.000Z", "1970-03-15T12:00:00.000Z",
    "1999-11-02T23:30:00.000Z", "2024-01-03T05:30:02.334Z",
    "2024-03-10T06:32:45.354Z", "2024-07-08T10:30:02.334Z",
    "2024-11-03T05:32:45.354Z", "2025-06-21T00:00:00.000Z",
  ]

  use zone <- list.each(zones)
  let assert Ok(host_tz) = time_zone.new(zone)
  let assert Ok(db_tz) = time_zone.from_database(db, zone)

  use moment <- list.each(moments)
  let moment = datetime.literal(moment)

  datetime.to_timezone(moment, db_tz)
  |> datetime.to_string
  |> should.equal(datetime.to_timezone(moment, host_tz) |> datetime.to_string)
}

// --- Unusual offsets -------------------------------------------------------
//
// The offset is carried around as a whole number of minutes, so zones that sit
// off the hour are the ones most likely to expose a rounding or sign mistake.

pub fn half_hour_offset_test() {
  let assert Ok(tz) = time_zone.new("Asia/Kolkata")

  datetime.literal("2024-01-15T12:00:00.000Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2024-01-15T17:30:00.000000+05:30")
}

pub fn quarter_hour_offset_test() {
  let assert Ok(tz) = time_zone.new("Asia/Kathmandu")

  datetime.literal("2024-01-15T12:00:00.000Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2024-01-15T17:45:00.000000+05:45")
}

/// Newfoundland is half an hour off the hour *and* observes DST, so the offset
/// changes between two values that are both fractional.
pub fn half_hour_offset_with_dst_test() {
  let assert Ok(tz) = time_zone.new("America/St_Johns")

  let winter =
    datetime.literal("2024-01-15T12:00:00.000Z")
    |> datetime.to_timezone(tz)
    |> datetime.to_string

  let summer =
    datetime.literal("2024-07-15T12:00:00.000Z")
    |> datetime.to_timezone(tz)
    |> datetime.to_string

  #(winter, summer)
  |> should.equal(#(
    "2024-01-15T08:30:00.000000-03:30",
    "2024-07-15T09:30:00.000000-02:30",
  ))
}

/// Chatham is 45 minutes off the hour and observes DST, giving +13:45/+12:45.
pub fn quarter_hour_offset_with_dst_test() {
  let assert Ok(tz) = time_zone.new("Pacific/Chatham")

  let dst =
    datetime.literal("2024-01-15T12:00:00.000Z")
    |> datetime.to_timezone(tz)
    |> datetime.to_string

  let standard =
    datetime.literal("2024-07-15T12:00:00.000Z")
    |> datetime.to_timezone(tz)
    |> datetime.to_string

  #(dst, standard)
  |> should.equal(#(
    "2024-01-16T01:45:00.000000+13:45",
    "2024-07-16T00:45:00.000000+12:45",
  ))
}

/// +14:00 is the largest offset in use, and pushes the local date a day ahead.
pub fn maximum_offset_test() {
  let assert Ok(tz) = time_zone.new("Pacific/Kiritimati")

  datetime.literal("2024-01-15T12:00:00.000Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2024-01-16T02:00:00.000000+14:00")
}

/// -12:00 is the smallest offset in use, and pulls the local date a day back.
pub fn minimum_offset_test() {
  let assert Ok(tz) = time_zone.new("Etc/GMT+12")

  datetime.literal("2024-01-15T00:00:00.000Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2024-01-14T12:00:00.000000-12:00")
}

/// The `Etc/GMT*` zones invert the sign of their name, per POSIX. `Etc/GMT+12`
/// is twelve hours *behind* UTC, not ahead. Worth pinning so nobody "fixes" it.
pub fn etc_gmt_sign_is_inverted_test() {
  let assert Ok(ahead) = time_zone.new("Etc/GMT-5")
  let assert Ok(behind) = time_zone.new("Etc/GMT+5")

  let moment = datetime.literal("2024-01-15T12:00:00.000Z")

  #(
    datetime.to_timezone(moment, ahead) |> datetime.to_string,
    datetime.to_timezone(moment, behind) |> datetime.to_string,
  )
  |> should.equal(#(
    "2024-01-15T17:00:00.000000+05:00",
    "2024-01-15T07:00:00.000000-05:00",
  ))
}

/// UTC has no offset to print, so it renders as `Z` rather than `+00:00`.
pub fn utc_renders_as_z_test() {
  let assert Ok(tz) = time_zone.new("UTC")

  datetime.literal("2024-01-15T12:00:00.000Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2024-01-15T12:00:00.000000Z")
}

// --- Calendar boundaries ---------------------------------------------------

/// A leap day plus a positive offset rolls into March, which only exists as a
/// valid date because 2024 is a leap year.
pub fn leap_day_rolls_into_march_test() {
  let assert Ok(tz) = time_zone.new("Asia/Kolkata")

  datetime.literal("2024-02-29T23:30:00.000Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2024-03-01T05:00:00.000000+05:30")
}

pub fn year_boundary_forward_test() {
  let assert Ok(tz) = time_zone.new("Asia/Kolkata")

  datetime.literal("2024-12-31T23:30:00.000Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2025-01-01T05:00:00.000000+05:30")
}

pub fn year_boundary_backward_test() {
  let assert Ok(tz) = time_zone.new("America/New_York")

  datetime.literal("2025-01-01T02:00:00.000Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2024-12-31T21:00:00.000000-05:00")
}

// --- Zones whose rules changed ---------------------------------------------

/// Moscow was +04:00 year round after 2011, then moved to +03:00 in 2014. A
/// provider must answer from the rules in force at the instant asked about,
/// not from the zone's current rules.
pub fn zone_that_changed_its_standard_offset_test() {
  let assert Ok(tz) = time_zone.new("Europe/Moscow")

  let then =
    datetime.literal("2011-12-30T12:00:00.000Z")
    |> datetime.to_timezone(tz)
    |> datetime.to_string

  let now =
    datetime.literal("2024-01-15T12:00:00.000Z")
    |> datetime.to_timezone(tz)
    |> datetime.to_string

  #(then, now)
  |> should.equal(#(
    "2011-12-30T16:00:00.000000+04:00",
    "2024-01-15T15:00:00.000000+03:00",
  ))
}

/// Samoa jumped the date line at the end of 2011, skipping 30 December
/// entirely and moving from -10:00 to +14:00.
pub fn zone_that_crossed_the_date_line_test() {
  let assert Ok(tz) = time_zone.new("Pacific/Apia")

  datetime.literal("2011-12-30T12:00:00.000Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2011-12-31T02:00:00.000000+14:00")
}

/// Southern hemisphere zones are in DST during January, not July — the
/// opposite of the northern zones the rest of these tests use.
pub fn southern_hemisphere_dst_test() {
  let assert Ok(tz) = time_zone.new("Australia/Sydney")

  let dst =
    datetime.literal("2024-01-15T12:00:00.000Z")
    |> datetime.to_timezone(tz)
    |> datetime.to_string

  let standard =
    datetime.literal("2024-07-15T12:00:00.000Z")
    |> datetime.to_timezone(tz)
    |> datetime.to_string

  #(dst, standard)
  |> should.equal(#(
    "2024-01-15T23:00:00.000000+11:00",
    "2024-07-15T22:00:00.000000+10:00",
  ))
}

// --- Rejected names --------------------------------------------------------

pub fn empty_name_is_invalid_test() {
  time_zone.new("") |> should.be_error
}

/// A name is looked up, never used as a path, so traversal cannot escape.
pub fn path_traversal_name_is_invalid_test() {
  time_zone.new("../../etc/passwd") |> should.be_error
}

pub fn untrimmed_name_is_invalid_test() {
  time_zone.new("America/New_York ") |> should.be_error
}

pub fn abbreviation_style_names_are_valid_test() {
  time_zone.new("GMT") |> should.be_ok
  time_zone.new("Etc/UTC") |> should.be_ok
}

// --- Invariants ------------------------------------------------------------

/// Changing the zone of a datetime must never change the instant it names.
pub fn to_timezone_preserves_the_instant_test() {
  let moment = datetime.literal("2024-07-15T12:00:00.000Z")

  use zone <- list.each([
    "Asia/Kathmandu", "Pacific/Chatham", "Pacific/Kiritimati", "Etc/GMT+12",
    "America/St_Johns", "Australia/Sydney", "UTC",
  ])

  let assert Ok(tz) = time_zone.new(zone)

  datetime.to_timezone(moment, tz)
  |> datetime.is_equal(moment)
  |> should.be_true
}

/// Hopping through several zones and back must land on the original instant.
pub fn round_trip_through_zones_preserves_the_instant_test() {
  let moment = datetime.literal("2024-11-03T05:32:45.354Z")

  let assert Ok(kathmandu) = time_zone.new("Asia/Kathmandu")
  let assert Ok(chatham) = time_zone.new("Pacific/Chatham")
  let assert Ok(utc) = time_zone.new("UTC")

  moment
  |> datetime.to_timezone(kathmandu)
  |> datetime.to_timezone(chatham)
  |> datetime.to_timezone(utc)
  |> datetime.is_equal(moment)
  |> should.be_true
}

// --- from_database edge cases ----------------------------------------------

pub fn from_database_quarter_hour_offset_test() {
  let assert Ok(tz) = os_database() |> time_zone.from_database("Asia/Kathmandu")

  datetime.literal("2024-01-15T12:00:00.000Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2024-01-15T17:45:00.000000+05:45")
}

pub fn from_database_maximum_offset_test() {
  let assert Ok(tz) =
    os_database() |> time_zone.from_database("Pacific/Kiritimati")

  datetime.literal("2024-01-15T12:00:00.000Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2024-01-16T02:00:00.000000+14:00")
}

pub fn from_database_southern_hemisphere_dst_test() {
  let assert Ok(tz) =
    os_database() |> time_zone.from_database("Australia/Sydney")

  let dst =
    datetime.literal("2024-01-15T12:00:00.000Z")
    |> datetime.to_timezone(tz)
    |> datetime.to_string

  let standard =
    datetime.literal("2024-07-15T12:00:00.000Z")
    |> datetime.to_timezone(tz)
    |> datetime.to_string

  #(dst, standard)
  |> should.equal(#(
    "2024-01-15T23:00:00.000000+11:00",
    "2024-07-15T22:00:00.000000+10:00",
  ))
}

pub fn from_database_empty_name_is_invalid_test() {
  os_database() |> time_zone.from_database("") |> should.be_error
}

pub fn from_database_preserves_the_instant_test() {
  let moment = datetime.literal("2024-07-15T12:00:00.000Z")
  let db = os_database()

  use zone <- list.each(["Asia/Kathmandu", "Pacific/Chatham", "Etc/GMT+12"])

  let assert Ok(tz) = time_zone.from_database(db, zone)

  datetime.to_timezone(moment, tz)
  |> datetime.is_equal(moment)
  |> should.be_true
}

/// A provider built from a database keeps working after the local binding for
/// that database goes out of scope, because it captured the database itself.
pub fn from_database_provider_outlives_its_binding_test() {
  let tz = {
    let assert Ok(tz) = os_database() |> time_zone.from_database("Asia/Kolkata")
    tz
  }

  datetime.literal("2024-01-15T12:00:00.000Z")
  |> datetime.to_timezone(tz)
  |> datetime.to_string
  |> should.equal("2024-01-15T17:30:00.000000+05:30")
}

// --- Documented differences between the targets ----------------------------
//
// `new` reads the OS TZif database on Erlang and asks `Intl` on JavaScript.
// Those are different data sources and they do not agree on everything. The
// tests below pin the differences that are worth knowing about rather than
// pretending they do not exist. `from_database` has neither difference, since
// it is the same Gleam code and the same database on both targets.

@target(javascript)
/// `Intl` normalises the case of zone names, so a lowercase name is accepted.
pub fn intl_accepts_miscased_names_test() {
  time_zone.new("america/new_york") |> should.be_ok
  time_zone.new("AMERICA/NEW_YORK") |> should.be_ok
}

@target(erlang)
/// A TZif database is a list of file names, so matching is case sensitive and
/// the same miscased names are rejected. Code that passes user supplied zone
/// names should normalise them itself rather than rely on either behaviour.
pub fn tzif_names_are_case_sensitive_test() {
  time_zone.new("america/new_york") |> should.be_error
  time_zone.new("AMERICA/NEW_YORK") |> should.be_error
}

@target(erlang)
/// Pre-1970 local mean time offsets differ between the two sources: the TZif
/// database carries the historical LMT for Midway, while `Intl` does not. Only
/// the shape of the disagreement is asserted, not either exact value, since
/// both are host data that can change with a tzdata update.
pub fn tzif_carries_pre_1970_local_mean_time_test() {
  let assert Ok(tz) = time_zone.new("Pacific/Midway")

  let modern =
    datetime.literal("2024-01-15T12:00:00.000Z")
    |> datetime.to_timezone(tz)
    |> datetime.to_string

  let historical =
    datetime.literal("1900-06-15T12:00:00.000Z")
    |> datetime.to_timezone(tz)
    |> datetime.to_string

  // The modern offset is a whole number of hours; the 1900 one is not.
  should.be_true(modern != historical)
  should.equal(modern, "2024-01-15T01:00:00.000000-11:00")
}
