var speedup = 1;
var referenceTime = 0;
var realStart = 0;
var realMonotonicStart = 0;
var mockTime = false;
var freezeTime = false;

function real_now() {
  return Date.now() * 1000;
}

function real_now_monotonic() {
  return Math.trunc(performance.now() * 1000);
}

export function now() {
  if (freezeTime) {
    return referenceTime;
  } else if (mockTime) {
    let realElaposed = real_now() - realStart;
    let spedupElapsed = Math.trunc(realElaposed * speedup);
    return referenceTime + spedupElapsed;
  }

  return real_now();
}

export function freeze_time(microseconds) {
  referenceTime = microseconds;
  freezeTime = true;
}

export function unfreeze_time() {
  freezeTime = false;
}

export function set_reference_time(microseconds, speedupFactor) {
  speedup = speedupFactor;
  referenceTime = microseconds;
  realStart = real_now();
  realMonotonicStart = real_now_monotonic();
  mockTime = true;
}

export function unset_reference_time() {
  mockTime = false;
}

export function local_offset() {
  return -new Date().getTimezoneOffset();
}

export function current_year() {
  new Date().getFullYear();
}

export function now_monotonic() {
  if (mockTime) {
    let realElapsed = real_now_monotonic() - realMonotonicStart;
    let spedupElapsed = Math.trunc(realElapsed * speedup);
    return referenceTime + spedupElapsed;
  }

  return real_now_monotonic();
}

var unique = 1;

export function now_unique() {
  return unique++;
}
