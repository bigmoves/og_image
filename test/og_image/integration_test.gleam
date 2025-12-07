import gleam/bit_array
import gleeunit/should
import lustre/attribute
import lustre/element
import og_image

pub fn render_simple_element_returns_png_bytes_test() {
  let el =
    element.element(
      "div",
      [
        attribute.styles([
          #("display", "flex"),
          #("align-items", "center"),
          #("justify-content", "center"),
          #("width", "100%"),
          #("height", "100%"),
          #("background-color", "#3b82f6"),
        ]),
      ],
      [
        element.element(
          "p",
          [
            attribute.styles([
              #("color", "white"),
              #("font-size", "48px"),
            ]),
          ],
          [element.text("Hello, OG Image!")],
        ),
      ],
    )

  let config = og_image.defaults()

  let result = og_image.render(el, config)

  // Should return Ok with PNG bytes
  should.be_ok(result)

  // Check PNG magic bytes
  let assert Ok(bytes) = result
  let assert Ok(magic) = bit_array.slice(bytes, 0, 8)

  // PNG signature: 89 50 4E 47 0D 0A 1A 0A
  should.equal(
    magic,
    <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A>>,
  )
}

pub fn render_with_jpeg_format_test() {
  let el =
    element.element(
      "div",
      [attribute.styles([#("background-color", "red")])],
      [],
    )

  let config = og_image.Config(..og_image.defaults(), format: og_image.Jpeg(80))

  let result = og_image.render(el, config)

  should.be_ok(result)

  // Check JPEG magic bytes (FFD8FF)
  let assert Ok(bytes) = result
  let assert Ok(magic) = bit_array.slice(bytes, 0, 3)
  should.equal(magic, <<0xFF, 0xD8, 0xFF>>)
}

pub fn render_with_webp_format_test() {
  let el =
    element.element(
      "div",
      [attribute.styles([#("background-color", "green")])],
      [],
    )

  let config = og_image.Config(..og_image.defaults(), format: og_image.WebP(80))

  let result = og_image.render(el, config)

  should.be_ok(result)

  // Check WebP magic bytes (RIFF....WEBP)
  let assert Ok(bytes) = result
  let assert Ok(riff) = bit_array.slice(bytes, 0, 4)
  let assert Ok(webp) = bit_array.slice(bytes, 8, 4)
  should.equal(riff, <<"RIFF":utf8>>)
  should.equal(webp, <<"WEBP":utf8>>)
}

pub fn render_with_custom_dimensions_test() {
  let el =
    element.element(
      "div",
      [attribute.styles([#("background-color", "blue")])],
      [],
    )

  let config = og_image.Config(..og_image.defaults(), width: 800, height: 400)

  let result = og_image.render(el, config)

  should.be_ok(result)

  // Just verify we get valid PNG bytes
  let assert Ok(bytes) = result
  let assert Ok(magic) = bit_array.slice(bytes, 0, 8)
  should.equal(
    magic,
    <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A>>,
  )
}
