pub type DateTimeParseError {
  DateTimeInvalidFormat(input: String)
  DateTimeDateParseError(input: String, cause: DateParseError)
  DateTimeTimeParseError(input: String, cause: TimeParseError)
  DateTimeOffsetParseError(input: String, cause: OffsetParseError)
}

@internal
pub fn describe_datetime_parse_error(error: DateTimeParseError) -> String {
  case error {
    DateTimeInvalidFormat(input) ->
      "Invalid datetime format: \"" <> input <> "\""
    DateTimeDateParseError(input, DateInvalidFormat(_)) ->
      "Invalid date format in datetime: \"" <> input <> "\""
    DateTimeDateParseError(input, DateOutOfBounds(_, DateDayOutOfBounds(_))) ->
      "Day out of bounds in datetime: \"" <> input <> "\""
    DateTimeDateParseError(input, DateOutOfBounds(_, DateMonthOutOfBounds(_))) ->
      "Month out of bounds in datetime: \"" <> input <> "\""
    DateTimeDateParseError(input, DateOutOfBounds(_, DateYearOutOfBounds(_))) ->
      "Year out of bounds in datetime: \"" <> input <> "\""
    DateTimeTimeParseError(input, TimeInvalidFormat(..)) ->
      "Invalid time format in datetime: \"" <> input <> "\""
    DateTimeTimeParseError(input, TimeOutOfBounds(_, TimeHourOutOfBounds(_))) ->
      "Hour out of bounds in datetime: \"" <> input <> "\""
    DateTimeTimeParseError(input, TimeOutOfBounds(_, TimeMinuteOutOfBounds(_))) ->
      "Minute out of bounds in datetime: \"" <> input <> "\""
    DateTimeTimeParseError(input, TimeOutOfBounds(_, TimeSecondOutOfBounds(_))) ->
      "Second out of bounds in datetime: \"" <> input <> "\""
    DateTimeTimeParseError(
      input,
      TimeOutOfBounds(_, TimeMicroSecondOutOfBounds(_)),
    ) -> "Subsecond value out of bounds in datetime: \"" <> input <> "\""
    DateTimeOffsetParseError(input, OffsetInvalidFormat(_)) ->
      "Invalid offset format in datetime: \"" <> input <> "\""
    DateTimeOffsetParseError(input, OffsetOutOfBounds(_)) ->
      "Offset out of bounds in datetime: \"" <> input <> "\""
  }
}

pub type DateTimeOutOfBoundsError {
  DateTimeDateOutOfBounds(input: String, cause: DateOutOfBoundsError)
  DateTimeTimeOutOfBounds(input: String, cause: TimeOutOfBoundsError)
  DateTimeOffsetOutOfBounds(input: String)
}

@internal
pub fn describe_datetime_out_of_bounds_error(
  error: DateTimeOutOfBoundsError,
) -> String {
  case error {
    DateTimeDateOutOfBounds(input, DateDayOutOfBounds(_)) ->
      "Day out of bounds in datetime: " <> input
    DateTimeDateOutOfBounds(input, DateMonthOutOfBounds(_)) ->
      "Month out of bounds in datetime: " <> input
    DateTimeDateOutOfBounds(input, DateYearOutOfBounds(_)) ->
      "Year out of bounds in datetime: " <> input
    DateTimeTimeOutOfBounds(input, TimeHourOutOfBounds(_)) ->
      "Hour out of bounds in datetime: " <> input
    DateTimeTimeOutOfBounds(input, TimeMinuteOutOfBounds(_)) ->
      "Minute out of bounds in datetime: " <> input
    DateTimeTimeOutOfBounds(input, TimeSecondOutOfBounds(_)) ->
      "Second out of bounds in datetime: " <> input
    DateTimeTimeOutOfBounds(input, TimeMicroSecondOutOfBounds(_)) ->
      "Subsecond value out of bounds in datetime: " <> input
    DateTimeOffsetOutOfBounds(input) ->
      "Offset out of bounds in datetime: " <> input
  }
}

pub type OffsetParseError {
  OffsetInvalidFormat(input: String)
  OffsetOutOfBounds(input: String)
}

@internal
pub fn describe_offset_parse_error(error: OffsetParseError) -> String {
  case error {
    OffsetInvalidFormat(input) -> "Invalid offset format: \"" <> input <> "\""
    OffsetOutOfBounds(input) -> "Offset out of bounds: \"" <> input <> "\""
  }
}

pub type NaiveDateTimeParseError {
  NaiveDateTimeInvalidFormat(input: String)
  NaiveDateTimeDateParseError(input: String, cause: DateParseError)
  NaiveDateTimeTimeParseError(input: String, cause: TimeParseError)
}

@internal
pub fn describe_naive_datetime_parse_error(
  error: NaiveDateTimeParseError,
) -> String {
  case error {
    NaiveDateTimeInvalidFormat(input) ->
      "Invalid naive datetime format: \"" <> input <> "\""
    NaiveDateTimeDateParseError(input, DateInvalidFormat(_)) ->
      "Invalid date format in naive datetime: \"" <> input <> "\""
    NaiveDateTimeDateParseError(
      input,
      DateOutOfBounds(_, DateDayOutOfBounds(_)),
    ) -> "Day out of bounds in naive datetime: \"" <> input <> "\""
    NaiveDateTimeDateParseError(
      input,
      DateOutOfBounds(_, DateMonthOutOfBounds(_)),
    ) -> "Month out of bounds in naive datetime: \"" <> input <> "\""
    NaiveDateTimeDateParseError(
      input,
      DateOutOfBounds(_, DateYearOutOfBounds(_)),
    ) -> "Year out of bounds in naive datetime: \"" <> input <> "\""
    NaiveDateTimeTimeParseError(input, TimeInvalidFormat(_)) ->
      "Invalid time format in naive datetime: \"" <> input <> "\""
    NaiveDateTimeTimeParseError(
      input,
      TimeOutOfBounds(_, TimeHourOutOfBounds(_)),
    ) -> "Hour out of bounds in naive datetime: \"" <> input <> "\""
    NaiveDateTimeTimeParseError(
      input,
      TimeOutOfBounds(_, TimeMinuteOutOfBounds(_)),
    ) -> "Minute out of bounds in naive datetime: \"" <> input <> "\""
    NaiveDateTimeTimeParseError(
      input,
      TimeOutOfBounds(_, TimeSecondOutOfBounds(_)),
    ) -> "Second out of bounds in naive datetime: \"" <> input <> "\""
    NaiveDateTimeTimeParseError(
      input,
      TimeOutOfBounds(_, TimeMicroSecondOutOfBounds(_)),
    ) -> "Subsecond value out of bounds in naive datetime: \"" <> input <> "\""
  }
}

pub type DateParseError {
  DateInvalidFormat(input: String)
  DateOutOfBounds(input: String, cause: DateOutOfBoundsError)
}

@internal
pub fn describe_date_parse_error(error: DateParseError) -> String {
  case error {
    DateInvalidFormat(input) -> "Invalid date format: " <> input
    DateOutOfBounds(input, DateDayOutOfBounds(_)) ->
      "Day out of bounds in date: \"" <> input <> "\""
    DateOutOfBounds(input, DateMonthOutOfBounds(_)) ->
      "Month out of bounds in date: \"" <> input <> "\""
    DateOutOfBounds(input, DateYearOutOfBounds(_)) ->
      "Year out of bounds in date: \"" <> input <> "\""
  }
}

pub type DateOutOfBoundsError {
  DateDayOutOfBounds(input: String)
  DateMonthOutOfBounds(input: String)
  DateYearOutOfBounds(input: String)
}

@internal
pub fn describe_date_out_of_bounds_error(error: DateOutOfBoundsError) -> String {
  case error {
    DateDayOutOfBounds(input) -> "Day out of bounds in date: " <> input
    DateMonthOutOfBounds(input) -> "Month out of bounds in date: " <> input
    DateYearOutOfBounds(input) -> "Year out of bounds in date: " <> input
  }
}

pub type TimeParseError {
  TimeInvalidFormat(input: String)
  TimeOutOfBounds(input: String, cause: TimeOutOfBoundsError)
}

@internal
pub fn describe_time_parse_error(error: TimeParseError) -> String {
  case error {
    TimeInvalidFormat(input) -> "Invalid time format: \"" <> input <> "\""
    TimeOutOfBounds(input, TimeHourOutOfBounds(_)) ->
      "Hour out of bounds in time: \"" <> input <> "\""
    TimeOutOfBounds(input, TimeMinuteOutOfBounds(_)) ->
      "Minute out of bounds in time: \"" <> input <> "\""
    TimeOutOfBounds(input, TimeSecondOutOfBounds(_)) ->
      "Second out of bounds in time: \"" <> input <> "\""
    TimeOutOfBounds(input, TimeMicroSecondOutOfBounds(_)) ->
      "Subsecond value out of bounds in time: \"" <> input <> "\""
  }
}

pub type TimeOutOfBoundsError {
  TimeHourOutOfBounds(input: String)
  TimeMinuteOutOfBounds(input: String)
  TimeSecondOutOfBounds(input: String)
  TimeMicroSecondOutOfBounds(input: String)
}

@internal
pub fn describe_time_out_of_bounds_error(error: TimeOutOfBoundsError) -> String {
  case error {
    TimeHourOutOfBounds(input) -> "Hour out of bounds in time: " <> input
    TimeMinuteOutOfBounds(input) -> "Minute out of bounds in time: " <> input
    TimeSecondOutOfBounds(input) -> "Second out of bounds in time: " <> input
    TimeMicroSecondOutOfBounds(input) ->
      "Subsecond value out of bounds in time: " <> input
  }
}
