import gleam/json
import gleam/string
import gleeunit/should
import og_image/style

pub fn kebab_to_camel_single_word_test() {
  style.kebab_to_camel("display")
  |> should.equal("display")
}

pub fn kebab_to_camel_two_words_test() {
  style.kebab_to_camel("flex-direction")
  |> should.equal("flexDirection")
}

pub fn kebab_to_camel_three_words_test() {
  style.kebab_to_camel("border-top-width")
  |> should.equal("borderTopWidth")
}

pub fn styles_to_json_empty_test() {
  style.to_json([])
  |> json.to_string
  |> should.equal("{}")
}

pub fn styles_to_json_single_property_test() {
  style.to_json([#("display", "flex")])
  |> json.to_string
  |> should.equal("{\"display\":\"flex\"}")
}

pub fn styles_to_json_converts_property_names_test() {
  style.to_json([#("flex-direction", "column")])
  |> json.to_string
  |> should.equal("{\"flexDirection\":\"column\"}")
}

pub fn styles_to_json_multiple_properties_test() {
  let result =
    style.to_json([#("display", "flex"), #("justify-content", "center")])
    |> json.to_string

  // Check both properties present (order may vary)
  should.be_true(string.contains(result, "\"display\":\"flex\""))
  should.be_true(string.contains(result, "\"justifyContent\":\"center\""))
}
