import gleam/json
import gleam/string
import gleeunit/should
import lustre/attribute
import lustre/element
import og_image/transform.{Container, Image, Text, Unsupported}

pub fn div_is_container_test() {
  transform.node_type("div")
  |> should.equal(Container)
}

pub fn section_is_container_test() {
  transform.node_type("section")
  |> should.equal(Container)
}

pub fn p_is_text_test() {
  transform.node_type("p")
  |> should.equal(Text)
}

pub fn h1_is_text_test() {
  transform.node_type("h1")
  |> should.equal(Text)
}

pub fn img_is_image_test() {
  transform.node_type("img")
  |> should.equal(Image)
}

pub fn button_is_unsupported_test() {
  transform.node_type("button")
  |> should.equal(Unsupported("button"))
}

pub fn extract_styles_from_style_attribute_test() {
  let attrs = [attribute.styles([#("display", "flex"), #("color", "red")])]

  transform.extract_styles(attrs)
  |> should.equal([#("display", "flex"), #("color", "red")])
}

pub fn extract_styles_empty_when_no_style_test() {
  let attrs = [attribute.class("foo"), attribute.id("bar")]

  transform.extract_styles(attrs)
  |> should.equal([])
}

pub fn text_node_to_takumi_json_test() {
  let el = element.text("Hello")

  let result = transform.to_takumi_json(el) |> json.to_string

  should.be_true(string.contains(result, "\"type\":\"text\""))
  should.be_true(string.contains(result, "\"text\":\"Hello\""))
}

pub fn div_with_style_to_takumi_json_test() {
  let el =
    element.element(
      "div",
      [attribute.styles([#("display", "flex")])],
      [element.text("Hello")],
    )

  let result = transform.to_takumi_json(el) |> json.to_string

  // div maps to container type in Takumi
  should.be_true(string.contains(result, "\"type\":\"container\""))
  should.be_true(string.contains(result, "\"display\":\"flex\""))
  should.be_true(string.contains(result, "\"children\""))
}

pub fn img_to_takumi_json_test() {
  let el =
    element.element(
      "img",
      [attribute.src("https://example.com/image.png")],
      [],
    )

  let result = transform.to_takumi_json(el) |> json.to_string

  should.be_true(string.contains(result, "\"type\":\"image\""))
  should.be_true(string.contains(result, "\"src\":\"https://example.com/image.png\""))
}

pub fn p_element_becomes_container_with_inline_children_test() {
  let el =
    element.element(
      "p",
      [attribute.styles([#("font-size", "24px")])],
      [element.text("Hello "), element.text("World")],
    )

  let result = transform.to_takumi_json(el) |> json.to_string

  // p becomes a container with display: block and fontSize
  should.be_true(string.contains(result, "\"type\":\"container\""))
  should.be_true(string.contains(result, "\"display\":\"block\""))
  should.be_true(string.contains(result, "\"fontSize\":\"24px\""))
  // Children are inline text nodes
  should.be_true(string.contains(result, "\"type\":\"text\""))
  should.be_true(string.contains(result, "\"text\":\"Hello \""))
  should.be_true(string.contains(result, "\"text\":\"World\""))
  should.be_true(string.contains(result, "\"display\":\"inline\""))
}
