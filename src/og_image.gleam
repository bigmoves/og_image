import gleam/json
import gleam/result
import lustre/element.{type Element}
import og_image/transform

// Target-specific imports
@target(erlang)
import og_image/fetch

@target(erlang)
import og_image/ffi

@target(javascript)
import gleam/javascript/promise.{type Promise}

@target(javascript)
import gleam/option.{type Option, None, Some}

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
  WasmNotInitialized
}

// =============================================================================
// Erlang Target Types and Config
// =============================================================================

/// Configuration for rendering (Erlang target)
@target(erlang)
pub type Config {
  Config(width: Int, height: Int, format: Format, fonts: List(Font))
}

/// Default config: 1200x630 PNG, no custom fonts
@target(erlang)
pub fn defaults() -> Config {
  Config(width: 1200, height: 630, format: Png, fonts: [])
}

// =============================================================================
// JavaScript Target Types and Config
// =============================================================================

/// Opaque type for WASM module (only used on JavaScript target)
@target(javascript)
pub type WasmModule =
  ffi_js.WasmModule

/// Configuration for rendering (JavaScript target)
@target(javascript)
pub type Config {
  Config(
    width: Int,
    height: Int,
    format: Format,
    fonts: List(Font),
    /// WASM module for JavaScript target
    wasm: Option(WasmModule),
  )
}

/// Default config: 1200x630 PNG, no custom fonts, no WASM module
@target(javascript)
pub fn defaults() -> Config {
  Config(width: 1200, height: 630, format: Png, fonts: [], wasm: None)
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
/// Returns a Promise since fetching and WASM init are async
@target(javascript)
pub fn render(
  el: Element(msg),
  config: Config,
) -> Promise(Result(BitArray, RenderError)) {
  case config.wasm {
    None -> promise.resolve(Error(WasmNotInitialized))
    Some(wasm_module) -> render_with_wasm(el, config, wasm_module)
  }
}

@target(javascript)
fn render_with_wasm(
  el: Element(msg),
  config: Config,
  wasm_module: WasmModule,
) -> Promise(Result(BitArray, RenderError)) {
  // Initialize WASM (safe to call multiple times)
  use _ <- promise.await(ffi_js.init_wasm(wasm_module))

  // Collect URLs from the element tree
  let urls = transform.collect_image_urls(el)

  // Fetch all external images
  use resources <- promise.await(ffi_js.fetch_all(urls))

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

  // Call WASM renderer
  let result =
    ffi_js.render_image(
      json_str,
      config.width,
      config.height,
      format_str,
      quality,
      resources,
    )
    |> result.map_error(RenderFailed)

  promise.resolve(result)
}
