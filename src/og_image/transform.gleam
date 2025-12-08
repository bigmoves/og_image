import gleam/json.{type Json}
import gleam/list
import gleam/result
import gleam/string
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/vdom/vattr
import lustre/vdom/vnode
import og_image/style

/// Takumi node type classification
pub type NodeType {
  Container
  Text
  Image
  Unsupported(tag: String)
}

/// Map HTML tag to Takumi node type
pub fn node_type(tag: String) -> NodeType {
  case tag {
    // Container elements
    "div"
    | "section"
    | "header"
    | "footer"
    | "nav"
    | "main"
    | "aside"
    | "article" -> Container

    // Text elements
    "span"
    | "p"
    | "h1"
    | "h2"
    | "h3"
    | "h4"
    | "h5"
    | "h6"
    | "strong"
    | "em"
    | "a"
    | "label"
    | "code"
    | "pre" -> Text

    // Image element
    "img" -> Image

    // Unsupported
    other -> Unsupported(other)
  }
}

/// Extract style tuples from a list of attributes
pub fn extract_styles(attrs: List(Attribute(msg))) -> List(#(String, String)) {
  attrs
  |> list.filter_map(fn(attr) {
    case attr {
      vattr.Attribute(name: "style", value: style_str, ..) ->
        Ok(parse_style_string(style_str))
      _ -> Error(Nil)
    }
  })
  |> list.flatten
}

fn parse_style_string(s: String) -> List(#(String, String)) {
  s
  |> string.split(";")
  |> list.filter_map(fn(part) {
    let trimmed = string.trim(part)
    case trimmed {
      "" -> Error(Nil)
      _ ->
        case string.split_once(trimmed, ":") {
          Ok(#(property, value)) ->
            Ok(#(string.trim(property), string.trim(value)))
          Error(_) -> Error(Nil)
        }
    }
  })
}

/// Transform a Lustre element to Takumi JSON format, wrapped in a root container
/// that fills the viewport (width: 100%, height: 100%)
pub fn to_takumi_json_with_root(el: Element(msg)) -> Json {
  json.object([
    #("type", json.string("container")),
    #(
      "style",
      json.object([
        #("width", json.string("100%")),
        #("height", json.string("100%")),
      ]),
    ),
    #("children", json.array([el], to_takumi_json)),
  ])
}

/// Transform a Lustre element to Takumi JSON format
pub fn to_takumi_json(el: Element(msg)) -> Json {
  case el {
    vnode.Text(content: content, ..) -> text_to_json(content)

    vnode.Element(tag: "img", attributes: attrs, ..) -> image_to_json(attrs)

    // SVG elements are converted to image nodes with inline SVG content
    vnode.Element(tag: "svg", attributes: attrs, ..) ->
      svg_to_image_json(el, attrs)

    vnode.Element(tag: tag, attributes: attrs, children: children, ..) ->
      element_to_json(tag, attrs, children)

    vnode.Fragment(children: children, ..) ->
      // Wrap fragment children in a container
      json.object([
        #("type", json.string("container")),
        #("style", json.object([])),
        #("children", json.array(children, to_takumi_json)),
      ])

    vnode.UnsafeInnerHtml(..) ->
      // Not supported for OG images
      json.object([#("type", json.string("text")), #("text", json.string(""))])
  }
}

fn text_to_json(content: String) -> Json {
  json.object([#("type", json.string("text")), #("text", json.string(content))])
}

fn image_to_json(attrs: List(vattr.Attribute(msg))) -> Json {
  let styles = extract_styles(attrs)
  let style_json = style.to_json(styles)
  let src = extract_src(attrs)

  json.object([
    #("type", json.string("image")),
    #("src", json.string(src)),
    #("style", style_json),
  ])
}

/// Convert an SVG element to an image node with the SVG content as src
fn svg_to_image_json(
  svg_element: Element(msg),
  attrs: List(vattr.Attribute(msg)),
) -> Json {
  // Extract styles from the SVG element (width, height, etc.)
  let styles = extract_styles(attrs)
  let style_json = style.to_json(styles)

  // Serialize the SVG element to a string
  let svg_string = element.to_string(svg_element)

  json.object([
    #("type", json.string("image")),
    #("src", json.string(svg_string)),
    #("style", style_json),
  ])
}

fn extract_src(attrs: List(vattr.Attribute(msg))) -> String {
  attrs
  |> list.find_map(fn(attr) {
    case attr {
      vattr.Attribute(name: "src", value: src, ..) -> Ok(src)
      _ -> Error(Nil)
    }
  })
  |> result.unwrap("")
}

fn element_to_json(
  tag: String,
  attrs: List(vattr.Attribute(msg)),
  children: List(Element(msg)),
) -> Json {
  let styles = extract_styles(attrs)

  // Map HTML tags to Takumi node types
  case node_type(tag) {
    // Text elements become containers with inline text children
    // This preserves styling on nested spans/elements
    Text -> {
      // Add display: inline to children, parent gets block display
      let parent_styles = [#("display", "block"), ..styles]
      let style_json = style.to_json(parent_styles)

      json.object([
        #("type", json.string("container")),
        #("style", style_json),
        #("children", json.array(children, child_to_inline_json)),
      ])
    }
    // Container and other elements stay as containers
    _ -> {
      let style_json = style.to_json(styles)
      json.object([
        #("type", json.string("container")),
        #("style", style_json),
        #("children", json.array(children, to_takumi_json)),
      ])
    }
  }
}

/// Convert a child element to inline text JSON
/// Plain text becomes inline text nodes, elements get their styles preserved
fn child_to_inline_json(el: Element(msg)) -> Json {
  case el {
    // Plain text becomes an inline text node
    vnode.Text(content: content, ..) ->
      json.object([
        #("type", json.string("text")),
        #("text", json.string(content)),
        #("style", style.to_json([#("display", "inline")])),
      ])

    // Nested text elements (span, strong, etc.) become inline text with their styles
    vnode.Element(tag: tag, attributes: attrs, children: children, ..) -> {
      case node_type(tag) {
        // Nested text elements: extract styles and flatten text content
        Text -> {
          let styles = extract_styles(attrs)
          let inline_styles = [#("display", "inline"), ..styles]
          let text_content = collect_text_content(children)
          json.object([
            #("type", json.string("text")),
            #("text", json.string(text_content)),
            #("style", style.to_json(inline_styles)),
          ])
        }
        // Non-text elements inside text (like img) - process normally
        _ -> to_takumi_json(el)
      }
    }

    // Fragments: process each child as inline
    vnode.Fragment(children: children, ..) ->
      json.object([
        #("type", json.string("container")),
        #("style", style.to_json([#("display", "inline")])),
        #("children", json.array(children, child_to_inline_json)),
      ])

    _ ->
      json.object([
        #("type", json.string("text")),
        #("text", json.string("")),
        #("style", style.to_json([#("display", "inline")])),
      ])
  }
}

fn collect_text_content(children: List(Element(msg))) -> String {
  children
  |> list.map(fn(child) {
    case child {
      vnode.Text(content: content, ..) -> content
      vnode.Element(children: nested, ..) -> collect_text_content(nested)
      vnode.Fragment(children: nested, ..) -> collect_text_content(nested)
      _ -> ""
    }
  })
  |> string.concat
}

/// Collect all image URLs from a Lustre element tree
/// Returns URLs that start with http:// or https://
pub fn collect_image_urls(el: Element(msg)) -> List(String) {
  collect_urls_recursive(el, [])
  |> list.unique
}

fn collect_urls_recursive(el: Element(msg), acc: List(String)) -> List(String) {
  case el {
    vnode.Element(tag: "img", attributes: attrs, ..) -> {
      let src = extract_src(attrs)
      case
        string.starts_with(src, "http://")
        || string.starts_with(src, "https://")
      {
        True -> [src, ..acc]
        False -> acc
      }
    }

    vnode.Element(children: children, ..) ->
      list.fold(children, acc, fn(acc, child) {
        collect_urls_recursive(child, acc)
      })

    vnode.Fragment(children: children, ..) ->
      list.fold(children, acc, fn(acc, child) {
        collect_urls_recursive(child, acc)
      })

    _ -> acc
  }
}
