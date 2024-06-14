import gleeunit
import gleeunit/should
import tempo
import tempo/month

pub fn main() {
  gleeunit.main()
}

pub fn get_next_test() {
  month.get_next(tempo.Jan)
  |> should.equal(tempo.Feb)

  month.get_next(tempo.Dec)
  |> should.equal(tempo.Jan)
}

pub fn get_prior_test() {
  month.get_prior(tempo.Jan)
  |> should.equal(tempo.Dec)

  month.get_prior(tempo.Jul)
  |> should.equal(tempo.Jun)
}
