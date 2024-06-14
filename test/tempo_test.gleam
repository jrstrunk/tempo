import gleeunit
import gleeunit/should
import tempo

pub fn main() {
  gleeunit.main()
}

pub fn date_test() {
  tempo.Date(2024, tempo.Jun, 13)
  |> should.equal(tempo.Date(2024, tempo.Jun, 13))
}
