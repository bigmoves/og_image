import gleam/json.{type Json}
import gleam/list
import gleam/string

/// Convert kebab-case CSS property to camelCase
pub fn kebab_to_camel(property: String) -> String {
  property
  |> string.split("-")
  |> list.index_map(fn(part, index) {
    case index {
      0 -> part
      _ -> capitalize(part)
    }
  })
  |> string.concat
}

fn capitalize(s: String) -> String {
  case string.pop_grapheme(s) {
    Ok(#(first, rest)) -> string.uppercase(first) <> rest
    Error(_) -> s
  }
}

/// Convert a list of CSS style tuples to a JSON object
pub fn to_json(styles: List(#(String, String))) -> Json {
  styles
  |> list.map(fn(pair) {
    let #(property, value) = pair
    #(kebab_to_camel(property), json.string(value))
  })
  |> json.object
}
