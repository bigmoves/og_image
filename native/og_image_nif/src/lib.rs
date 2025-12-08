use rustler::{Binary, Env, OwnedBinary};
use std::io::Cursor;
use takumi::parley::GenericFamily;
use takumi::{
    layout::{node::NodeKind, Viewport},
    rendering::{render, write_image, ImageOutputFormat, RenderOptionsBuilder},
    GlobalContext,
};

// Embed fonts at compile time
static GEIST_FONT: &[u8] = include_bytes!("../assets/fonts/Geist[wght].woff2");
static GEIST_MONO_FONT: &[u8] = include_bytes!("../assets/fonts/GeistMono[wght].woff2");
static TWEMOJI_FONT: &[u8] = include_bytes!("../assets/fonts/TwemojiMozilla-colr.woff2");

rustler::init!("og_image_native");

#[rustler::nif]
fn hello() -> String {
    "Hello from Rust NIF!".to_string()
}

/// Create a GlobalContext with bundled fonts loaded
fn create_context_with_fonts() -> Result<GlobalContext, String> {
    let mut context = GlobalContext::default();

    // Load Geist Sans
    context
        .font_context
        .load_and_store(GEIST_FONT, None, Some(GenericFamily::SansSerif))
        .map_err(|e| format!("Failed to load Geist font: {:?}", e))?;

    // Load Geist Mono
    context
        .font_context
        .load_and_store(GEIST_MONO_FONT, None, Some(GenericFamily::Monospace))
        .map_err(|e| format!("Failed to load Geist Mono font: {:?}", e))?;

    // Load Twemoji for emoji support
    context
        .font_context
        .load_and_store(TWEMOJI_FONT, None, Some(GenericFamily::Emoji))
        .map_err(|e| format!("Failed to load Twemoji font: {:?}", e))?;

    Ok(context)
}

#[rustler::nif]
fn render_image<'a>(
    env: Env<'a>,
    json_str: String,
    width: i32,
    height: i32,
    format: String,
    quality: i32,
) -> Result<Binary<'a>, String> {
    // Parse JSON into NodeKind
    let node: NodeKind =
        serde_json::from_str(&json_str).map_err(|e| format!("Failed to parse JSON: {}", e))?;

    // Create global context with bundled fonts
    let context = create_context_with_fonts()?;

    // Build render options
    let viewport = Viewport::new(Some(width.max(1) as u32), Some(height.max(1) as u32));
    let options = RenderOptionsBuilder::default()
        .viewport(viewport)
        .node(node)
        .global(&context)
        .build()
        .map_err(|e| format!("Failed to build render options: {}", e))?;

    // Render the image
    let image = render(options).map_err(|e| format!("Render failed: {}", e))?;

    // Determine output format
    let output_format = match format.to_lowercase().as_str() {
        "png" => ImageOutputFormat::Png,
        "jpeg" | "jpg" => ImageOutputFormat::Jpeg,
        "webp" => ImageOutputFormat::WebP,
        _ => return Err(format!("Unsupported format: {}", format)),
    };

    // Quality: negative means use default
    let quality_opt = if quality >= 0 && quality <= 100 {
        Some(quality as u8)
    } else {
        None
    };

    // Write to bytes
    let mut buffer = Cursor::new(Vec::new());
    write_image(&image, &mut buffer, output_format, quality_opt)
        .map_err(|e| format!("Failed to write image: {}", e))?;

    let bytes = buffer.into_inner();

    // Create Erlang binary
    let mut owned_binary =
        OwnedBinary::new(bytes.len()).ok_or_else(|| "Failed to allocate binary".to_string())?;
    owned_binary.as_mut_slice().copy_from_slice(&bytes);

    Ok(owned_binary.release(env))
}
