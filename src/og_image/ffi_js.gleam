//// JavaScript FFI bindings for takumi-wasm (synchronous)
//// Only compiled on JavaScript target

@target(javascript)
/// Render an image from JSON (synchronous)
/// Automatically initializes WASM and loads fonts on first call
/// Resources is a list of (url, bytes) tuples for pre-fetched images
@external(javascript, "../og_image_ffi.mjs", "renderImage")
pub fn render_image(
  json_str: String,
  width: Int,
  height: Int,
  format: String,
  quality: Int,
  resources: List(#(String, BitArray)),
) -> Result(BitArray, String)

@target(javascript)
/// Fetch all URLs synchronously and return list of (url, bytes) tuples
/// Failed fetches are silently skipped
@external(javascript, "../og_image_ffi.mjs", "fetchAllSync")
pub fn fetch_all_sync(urls: List(String)) -> List(#(String, BitArray))
