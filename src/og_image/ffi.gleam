@external(erlang, "og_image_native", "hello")
pub fn hello() -> String

/// Render an image from JSON, returns Ok(bytes) or Error(reason)
/// Quality: 0-100 for JPEG, -1 for default
@external(erlang, "og_image_native", "render_image")
pub fn render_image(
  json_str: String,
  width: Int,
  height: Int,
  format: String,
  quality: Int,
) -> Result(BitArray, String)
