import gleeunit
import gleeunit/should
import tempo
import tempo/month

pub fn main() {
  gleeunit.main()
}

pub fn get_next_test() {
  month.next(tempo.Jan)
  |> should.equal(tempo.Feb)

  month.next(tempo.Dec)
  |> should.equal(tempo.Jan)
}

pub fn get_prior_test() {
  month.prior(tempo.Jan)
  |> should.equal(tempo.Dec)

  month.prior(tempo.Jul)
  |> should.equal(tempo.Jun)
}
