import gleeunit
import gleeunit/should
import og_image.{Png}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn defaults_returns_standard_og_dimensions_test() {
  let config = og_image.defaults()
  should.equal(config.width, 1200)
  should.equal(config.height, 630)
}

pub fn defaults_returns_png_format_test() {
  let config = og_image.defaults()
  should.equal(config.format, Png)
}

pub fn defaults_returns_empty_fonts_test() {
  let config = og_image.defaults()
  should.equal(config.fonts, [])
}
