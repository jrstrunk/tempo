export function now() {
  return Date.now() * 1000000;
}

export function local_offset() {
  return -(new Date()).getTimezoneOffset();
}

export function current_year() {
  new Date().getFullYear();
}

var unique = 1;

export function now_unique() {
  return unique++;
}