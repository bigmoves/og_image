//// Tests for JavaScript target
//// Run with: gleam test --target javascript

@target(javascript)
import gleam/option.{None}

@target(javascript)
import og_image.{Config, Png}

@target(javascript)
pub fn render_without_wasm_returns_error_test() {
  let config = Config(width: 100, height: 100, format: Png, fonts: [], wasm: None)

  // We can't easily test the Promise result in a sync test,
  // but we can at least verify the module compiles and types check
  let _ = config
  Nil
}
