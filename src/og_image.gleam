import gleam/json
import gleam/result
import lustre/element.{type Element}
import og_image/transform

// Target-specific imports for fetching
@target(erlang)
import og_image/fetch

@target(erlang)
import og_image/ffi

@target(javascript)
import og_image/ffi_js

/// Output format for rendered images
pub type Format {
  Png
  Jpeg(quality: Int)
  WebP(quality: Int)
}

/// Font style
pub type FontStyle {
  Normal
  Italic
}

/// Custom font definition
pub type Font {
  Font(name: String, path: String, weight: Int, style: FontStyle)
}

/// Render errors
pub type RenderError {
  InvalidElement(reason: String)
  FontLoadError(path: String)
  ImageLoadError(src: String)
  RenderFailed(reason: String)
}

/// Configuration for rendering (same on both targets)
pub type Config {
  Config(width: Int, height: Int, format: Format, fonts: List(Font))
}

/// Default config: 1200x630 PNG, no custom fonts
pub fn defaults() -> Config {
  Config(width: 1200, height: 630, format: Png, fonts: [])
}

// =============================================================================
// Erlang Target Implementation
// =============================================================================

/// Render a Lustre element to an image (Erlang target)
@target(erlang)
pub fn render(
  el: Element(msg),
  config: Config,
) -> Result(BitArray, RenderError) {
  // Collect URLs from the element tree
  let urls = transform.collect_image_urls(el)

  // Fetch all external images
  let resources = fetch.fetch_all(urls)

  // Transform element to Takumi JSON, wrapped in a root container
  let json_str =
    el
    |> transform.to_takumi_json_with_root
    |> json.to_string

  // Get format string and quality
  let #(format_str, quality) = case config.format {
    Png -> #("png", -1)
    Jpeg(q) -> #("jpeg", q)
    WebP(q) -> #("webp", q)
  }

  // Call the NIF with pre-fetched resources
  ffi.render_image(
    json_str,
    config.width,
    config.height,
    format_str,
    quality,
    resources,
  )
  |> result.map_error(RenderFailed)
}

// =============================================================================
// JavaScript Target Implementation
// =============================================================================

/// Render a Lustre element to an image (JavaScript target)
/// Synchronous - auto-initializes WASM and fonts on first call
@target(javascript)
pub fn render(
  el: Element(msg),
  config: Config,
) -> Result(BitArray, RenderError) {
  // Collect URLs from the element tree
  let urls = transform.collect_image_urls(el)

  // Fetch all external images synchronously
  let resources = ffi_js.fetch_all_sync(urls)

  // Transform element to Takumi JSON, wrapped in a root container
  let json_str =
    el
    |> transform.to_takumi_json_with_root
    |> json.to_string

  // Get format string and quality
  let #(format_str, quality) = case config.format {
    Png -> #("png", -1)
    Jpeg(q) -> #("jpeg", q)
    WebP(q) -> #("webp", q)
  }

  // Call WASM renderer (auto-initializes on first call)
  ffi_js.render_image(
    json_str,
    config.width,
    config.height,
    format_str,
    quality,
    resources,
  )
  |> result.map_error(RenderFailed)
}
