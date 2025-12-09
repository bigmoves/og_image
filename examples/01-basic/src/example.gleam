//// Unified example - works on both Erlang and JavaScript targets
//// Run with: gleam run --target erlang
//// Or:       gleam run --target javascript

import gleam/io
import lustre/attribute
import lustre/element/html
import og_image
import simplifile

pub fn main() {
  let og_element =
    html.div(
      [
        attribute.styles([
          #("display", "flex"),
          #("flex-direction", "column"),
          #("justify-content", "center"),
          #("align-items", "center"),
          #("width", "100%"),
          #("height", "100%"),
          #("background-color", "#292d3e"),
          #("padding", "40px"),
        ]),
      ],
      [
        // Lucy image
        html.img([
          attribute.src("https://gleam.run/images/lucy/lucy.svg"),
          attribute.styles([
            #("width", "200px"),
            #("height", "auto"),
          ]),
        ]),
        // Title
        html.h1(
          [
            attribute.styles([
              #("color", "white"),
              #("font-size", "72px"),
              #("font-weight", "700"),
              #("margin", "0"),
              #("margin-top", "40px"),
              #("text-align", "center"),
            ]),
          ],
          [html.text("Hello from Gleam!")],
        ),
      ],
    )

  // Render as PNG with default config (1200x630)
  io.println("Rendering OG image...")

  case og_image.render(og_element, og_image.defaults()) {
    Ok(png_bytes) -> {
      io.println("Render successful!")
      case simplifile.write_bits("output.png", png_bytes) {
        Ok(_) -> io.println("Saved to output.png")
        Error(e) -> io.println("Failed to save: " <> simplifile.describe_error(e))
      }
    }
    Error(e) -> {
      io.println("Render failed:")
      case e {
        og_image.InvalidElement(reason) ->
          io.println("  Invalid element: " <> reason)
        og_image.FontLoadError(path) ->
          io.println("  Font load error: " <> path)
        og_image.ImageLoadError(src) ->
          io.println("  Image load error: " <> src)
        og_image.RenderFailed(reason) ->
          io.println("  Render failed: " <> reason)
      }
    }
  }

  io.println("Done!")
}
