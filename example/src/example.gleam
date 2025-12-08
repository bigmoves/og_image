import gleam/io
import lustre/attribute
import lustre/element/html
import og_image
import simplifile

pub fn main() {
  // Create a styled OG image layout using Lustre elements
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
          #("background", "linear-gradient(135deg, #667eea 0%, #764ba2 100%)"),
          #("padding", "40px"),
        ]),
      ],
      [
        // Title
        html.h1(
          [
            attribute.styles([
              #("color", "white"),
              #("font-size", "72px"),
              #("font-weight", "700"),
              #("margin", "0"),
              #("text-align", "center"),
            ]),
          ],
          [html.text("Hello from Gleam!")],
        ),
        // Subtitle
        html.p(
          [
            attribute.styles([
              #("color", "rgba(255, 255, 255, 0.9)"),
              #("font-size", "32px"),
              #("margin-top", "20px"),
              #("text-align", "center"),
            ]),
          ],
          [html.text("OG images powered by Lustre + Takumi")],
        ),
        // Footer badge
        html.div(
          [
            attribute.styles([
              #("display", "flex"),
              #("align-items", "center"),
              #("gap", "12px"),
              #("margin-top", "60px"),
              #("padding", "16px 32px"),
              #("background-color", "rgba(255, 255, 255, 0.15)"),
              #("border-radius", "50px"),
            ]),
          ],
          [
            html.span(
              [
                attribute.styles([
                  #("color", "white"),
                  #("font-size", "24px"),
                ]),
              ],
              [html.text("Built with og_image")],
            ),
          ],
        ),
      ],
    )

  // Render as PNG with default config (1200x630)
  io.println("Rendering OG image...")

  case og_image.render(og_element, og_image.defaults()) {
    Ok(png_bytes) -> {
      // Save to file
      case simplifile.write_bits("output.png", png_bytes) {
        Ok(_) -> io.println("Saved to output.png")
        Error(e) ->
          io.println("Failed to save: " <> simplifile.describe_error(e))
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

  // Also render as JPEG
  io.println("Rendering JPEG version...")
  let jpeg_config =
    og_image.Config(..og_image.defaults(), format: og_image.Jpeg(90))

  case og_image.render(og_element, jpeg_config) {
    Ok(jpeg_bytes) -> {
      case simplifile.write_bits("output.jpg", jpeg_bytes) {
        Ok(_) -> io.println("Saved to output.jpg")
        Error(e) ->
          io.println("Failed to save: " <> simplifile.describe_error(e))
      }
    }
    Error(_) -> io.println("JPEG render failed")
  }

  // And WebP
  io.println("Rendering WebP version...")
  let webp_config =
    og_image.Config(..og_image.defaults(), format: og_image.WebP(80))

  case og_image.render(og_element, webp_config) {
    Ok(webp_bytes) -> {
      case simplifile.write_bits("output.webp", webp_bytes) {
        Ok(_) -> io.println("Saved to output.webp")
        Error(e) ->
          io.println("Failed to save: " <> simplifile.describe_error(e))
      }
    }
    Error(_) -> io.println("WebP render failed")
  }

  io.println("Done!")
}
