var speedup = 1;
var referenceTime = 0;
var referenceOffsetMinutes = 0;
var referenceStart = 0;
var referenceMonotonicStart = 0;
var mockTime = false;
var freezeTime = false;
var warpTime = 0;
var doSleepWarp = false;

function warped_now() {
  return Date.now() * 1000 + warpTime;
}

function warped_now_monotonic() {
  return Math.trunc(performance.now() * 1000) + warpTime;
}

export function now() {
  if (freezeTime) {
    return referenceTime + warpTime;
  } else if (mockTime) {
    let realElaposed = warped_now() - referenceStart;
    let spedupElapsed = Math.trunc(realElaposed * speedup);
    return referenceTime + spedupElapsed;
  }

  return warped_now();
}

export function freeze_time(microseconds, offset_minutes) {
  referenceTime = microseconds;
  referenceOffsetMinutes = offset_minutes;
  freezeTime = true;
}

export function unfreeze_time() {
  freezeTime = false;
  referenceTime = 0;
  referenceOffsetMinutes = 0;
}

export function set_reference_time(microseconds, speedupFactor) {
  speedup = speedupFactor;
  referenceTime = microseconds;
  referenceStart = warped_now();
  referenceMonotonicStart = warped_now_monotonic();
  mockTime = true;
}

export function unset_reference_time() {
  mockTime = false;
  speedup = 1;
  referenceTime = 0;
  referenceStart = 0;
  referenceOffsetMinutes = 0;
  referenceMonotonicStart = 0;
}

export function local_offset() {
  if (freezeTime || mockTime) {
    return referenceOffsetMinutes;
  }
  return -new Date().getTimezoneOffset();
}

export function current_year() {
  new Date().getFullYear();
}

export function now_monotonic() {
  if (freezeTime) {
    return referenceTime + warpTime;
  } else if (mockTime) {
    let realElapsed = warped_now_monotonic() - referenceMonotonicStart;
    let spedupElapsed = Math.trunc(realElapsed * speedup);
    return referenceTime + spedupElapsed;
  }

  return warped_now_monotonic();
}

var unique = 1;

export function now_unique() {
  return unique++;
}

export function add_warp_time(microseconds) {
  warpTime += microseconds;
}

export function reset_warp_time() {
  warpTime = 0;
}

export function set_sleep_warp(do_warp) {
  doSleepWarp = do_warp;
}

// Sadly a promise / async based sleep would not work in all circumstances so
// a busy wait is used instead.
const sleep_busy = (ms) => {
  const start = Date.now();
  while (Date.now() - start <= ms) {
    // Busy wait
  }
};

export function sleep(milliseconds) {
  if (doSleepWarp) {
    add_warp_time(milliseconds * 1000);
  } else {
    sleep_busy(milliseconds);
  }
}
