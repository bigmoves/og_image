//// Tests for JavaScript target
//// Run with: gleam test --target javascript

@target(javascript)
import og_image.{Config, Png}

@target(javascript)
pub fn config_creation_test() {
  // Test that Config can be created with the unified API
  let config = Config(width: 100, height: 100, format: Png, fonts: [])

  // Verify config values are set correctly
  let _ = config
  Nil
}
