export function is_valid_timezone(timeZone) {
  try {
    Intl.DateTimeFormat(undefined, {timeZone: timeZone});
    return true;
  } catch (error) {
    return false;
  }
}

export function calculate_offset(year, month, day, hour, minute, second, timezone) {
  // Create Date objects for UTC and the target time zone
  const utcDate = new Date(Date.UTC(year, month - 1, day, hour, minute, second));

  // Format options for getting the time components
  const options = {
    timeZone: timezone,
    hour12: false,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  };

  // Format the date in the target time zone
  const formatter = new Intl.DateTimeFormat('en-US', options);
  const parts = formatter.formatToParts(utcDate);

  // For some reason the formatter was formatting times with the hour 00 as 24,
  // so if that is the case we can manually set it to 00.
  let hourValue = parts.find(p => p.type === 'hour').value
  hourValue = hourValue == '24' ? '00' : hourValue

  const targetDateStr = `${parts.find(p => p.type === 'year').value}-${parts.find(p => p.type === 'month').value}-${parts.find(p => p.type === 'day').value}T${hourValue}:${parts.find(p => p.type === 'minute').value}:${parts.find(p => p.type === 'second').value}`;
  const utcDateStr = utcDate.toISOString().slice(0, 19);

  // Calculate the difference in the unix timestamps
  const targetTime = new Date(targetDateStr).getTime();
  const utcTime = new Date(utcDateStr).getTime();

  return Math.trunc((targetTime - utcTime) / 60000);
}

export function local_timezone() {
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
}
