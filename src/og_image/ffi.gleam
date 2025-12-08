/// Render an image from JSON with pre-fetched resources
/// Resources is a list of (url, bytes) tuples
/// Quality: 0-100 for JPEG/WebP, -1 for default
@external(erlang, "og_image_native", "render_image")
pub fn render_image(
  json_str: String,
  width: Int,
  height: Int,
  format: String,
  quality: Int,
  resources: List(#(String, BitArray)),
) -> Result(BitArray, String)
