//// Functions to provide time zone support for datetimes.
////
//// A `tempo.TimeZoneProvider` value is constructed with these functions, and
//// then handed to functions like `datetime.to_timezone` to convert datetimes
//// between zones. Note that the datetime conversion does not store the
//// time zone data in the datetime value itself, so after converting a datetime,
//// adding or subtracting time from it may invalidate its correctness in
//// the converted time zone.
////
//// On the Erlang target running on macOS and other Unix systems, the operating
//// system's TZif database is read from `/usr/share/zoneinfo` via the `tzif`
//// package. It is parsed once on first use and then memoized in a persistent
//// term. A host with no readable database there has no valid zones, so `new` returns
//// an error for every name. In this case, use the `from_database` function
//// to supply your own `tzif.TzDatabase` database instead.
////
//// On the JavaScript target the runtime's native `Intl` API answers both which
//// zone names are valid and what offset a zone was at, so any zone the
//// JavaScript engine knows about is available with no filesystem access. You
//// can also provide your own `tzif.TzDatabase` database to `from_database`
//// to supply your own zone data to the JavaScript runtime if you would like.

import gleam/list
import gleam/result
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp
import tempo
import tempo/naive_datetime
import tzif/database as tz_database

/// Constructs a TimeZoneProvider type to be used with the rest of this package.
/// Returns an error if the time zone is not valid.
///
/// Which names are valid, and the offsets they resolve to, come from the host:
/// the operating system's TZif database in `/usr/share/zoneinfo` on Erlang
/// (macOS and other Unix systems), and the native `Intl` API on JavaScript.
///
/// ## Examples
///
/// ```gleam
/// import tempo/datetime
/// import tempo/time_zone
///
/// let assert Ok(tz) = time_zone.new("America/New_York")
///
/// datetime.literal("2024-06-21T06:30:02.334Z")
/// |> datetime.to_timezone(tz)
/// |> datetime.to_string
/// // -> "2024-01-03T02:30:02.334-04:00"
/// ```
pub fn new(name: String) -> Result(tempo.TimeZoneProvider, Nil) {
  case is_valid_timezone(name) {
    True ->
      Ok(
        provider(name, fn(year, month, day, hour, minute, second) {
          calculate_offset(year, month, day, hour, minute, second, name)
        }),
      )
    False -> Error(Nil)
  }
}

/// Constructs a TimeZoneProvider backed by a supplied TZif database. Returns
/// an error if `db` does not contain `name`.
///
/// This is useful for loading a database from a non-standard host location.
///
/// ## Examples
///
/// ```gleam
/// import tempo/datetime
/// import tempo/time_zone
/// import tzif/database
///
/// // Provided by the host at a non-standard location
/// let assert Ok(db) = database.load_from_path("/custom/path/to/zoneinfo")
/// let assert Ok(tz) = time_zone.from_database(db, "America/New_York")
///
/// datetime.literal("2024-06-21T06:30:02.334Z")
/// |> datetime.to_timezone(tz)
/// |> datetime.to_string
/// // -> "2024-06-21T02:30:02.334000-04:00"
/// ```
///
/// ```gleam
/// import tempo/datetime
/// import tempo/time_zone
/// import zones
///
/// // Self-provided tzif database from the `zones` package
/// let db = zones.database()
/// let assert Ok(tz) = time_zone.from_database(db, "America/New_York")
///
/// datetime.literal("2024-06-21T06:30:02.334Z")
/// |> datetime.to_timezone(tz)
/// |> datetime.to_string
/// // -> "2024-06-21T02:30:02.334000-04:00"
/// ```
pub fn from_database(
  db: tz_database.TzDatabase,
  name: String,
) -> Result(tempo.TimeZoneProvider, Nil) {
  case tz_database.get_available_timezones(db) |> list.contains(name) {
    True ->
      Ok(
        provider(name, fn(year, month, day, hour, minute, second) {
          // The offset in minutes that `name` was at this UTC wall-clock time,
          // according to `db`. A zone missing from `db` would yield 0, but the
          // check above means no provider is ever built for such a name.
          let offset_minutes = {
            use month <- result.try(calendar.month_from_int(month))

            let timestamp =
              timestamp.from_calendar(
                calendar.Date(year:, month:, day:),
                calendar.TimeOfDay(
                  hours: hour,
                  minutes: minute,
                  seconds: second,
                  nanoseconds: 0,
                ),
                calendar.utc_offset,
              )

            use params <- result.map(
              tz_database.get_zone_parameters(timestamp, name, db)
              |> result.replace_error(Nil),
            )

            let #(seconds, _nanoseconds) =
              duration.to_seconds_and_nanoseconds(params.offset)
            seconds / 60
          }

          result.unwrap(offset_minutes, 0)
        }),
      )
    False -> Error(Nil)
  }
}

/// Assembles a provider from a name and a function giving the offset in minutes
/// at a UTC wall-clock time. Whatever that function closes over — the host, or
/// a caller supplied database — is what the provider carries with it.
fn provider(
  name: String,
  offset_minutes: fn(Int, Int, Int, Int, Int, Int) -> Int,
) -> tempo.TimeZoneProvider {
  tempo.TimeZoneProvider(
    get_name: fn() { name },
    calculate_offset: fn(utc_naive_datetime) {
      let #(#(year, month, day), #(hour, minute, second)) =
        naive_datetime.to_tuple(utc_naive_datetime)

      offset_minutes(year, month, day, hour, minute, second)
      |> duration.minutes
      |> tempo.new_offset_unchecked
    },
  )
}

/// The offset from UTC, in minutes, that `timezone` was at the given UTC
/// wall-clock time, according to the host.
///
/// An unknown zone or a host with no readable database yields 0. Callers should
/// never observe this, because `new` checks `is_valid_timezone` first and no
/// zone passes that check without a database to have passed it.
@external(erlang, "tempo_time_zone_ffi", "calculate_offset")
@external(javascript, "../tempo_time_zone_ffi.mjs", "calculate_offset")
fn calculate_offset(
  year: Int,
  month: Int,
  day: Int,
  hour: Int,
  minute: Int,
  second: Int,
  timezone: String,
) -> Int

/// Whether the host recognises `timezone` as a zone name.
@external(erlang, "tempo_time_zone_ffi", "is_valid_timezone")
@external(javascript, "../tempo_time_zone_ffi.mjs", "is_valid_timezone")
fn is_valid_timezone(timezone: String) -> Bool

/// Returns the name of the host system's time zone.
///
/// ## Examples
///
/// ```gleam
/// time_zone.local_name()
/// // -> "Europe/London"
/// ```
///
/// On the Erlang target the zone is read from the operating system, in order:
/// the `TZ` environment variable, the symlink target of `/etc/localtime`, then
/// `/etc/timezone` or `/etc/sysconfig/clock`. If none of those yield an IANA
/// zone name, `"UTC"` is returned. On JavaScript the host's `Intl` API is used.
@external(erlang, "tempo_time_zone_ffi", "local_timezone")
@external(javascript, "../tempo_time_zone_ffi.mjs", "local_timezone")
pub fn local_name() -> String
