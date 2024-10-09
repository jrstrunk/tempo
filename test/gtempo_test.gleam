import gleeunit
import gleeunit/should
import tempo

pub fn main() {
  gleeunit.main()
}

pub fn date_test() {
  tempo.date(2024, tempo.Jun, 13)
  |> should.equal(tempo.date(2024, tempo.Jun, 13))
}
