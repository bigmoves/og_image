//// JavaScript FFI bindings for takumi-wasm
//// Only compiled on JavaScript target

@target(javascript)
import gleam/javascript/promise.{type Promise}

/// Opaque type representing a WASM module
/// Can be a URL string, ArrayBuffer, or Response depending on the environment
pub type WasmModule

/// Initialize the WASM module
/// Must be called before render_image
/// Safe to call multiple times - will only initialize once
@target(javascript)
@external(javascript, "../og_image_ffi.mjs", "initWasm")
pub fn init_wasm(module: WasmModule) -> Promise(Nil)

/// Check if WASM has been initialized
@target(javascript)
@external(javascript, "../og_image_ffi.mjs", "isInitialized")
pub fn is_initialized() -> Bool

/// Render an image from JSON
/// Resources is a list of (url, bytes) tuples for pre-fetched images
@target(javascript)
@external(javascript, "../og_image_ffi.mjs", "renderImage")
pub fn render_image(
  json_str: String,
  width: Int,
  height: Int,
  format: String,
  quality: Int,
  resources: List(#(String, BitArray)),
) -> Result(BitArray, String)

/// Fetch all URLs and return list of (url, bytes) tuples
/// Failed fetches are silently skipped
@target(javascript)
@external(javascript, "../og_image_ffi.mjs", "fetchAll")
pub fn fetch_all(urls: List(String)) -> Promise(List(#(String, BitArray)))
