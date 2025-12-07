# og_image

Generate Open Graph images from Lustre elements.

[![Package Version](https://img.shields.io/hexpm/v/og_image)](https://hex.pm/packages/og_image)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/og_image/)

## Installation

```sh
gleam add og_image
```

Precompiled binaries are included for:
- macOS (Apple Silicon and Intel)
- Linux (x86_64 and arm64)

## Usage

```gleam
import lustre/element
import lustre/attribute
import og_image

pub fn generate_og_image() {
  let el = element.element(
    "div",
    [attribute.styles([
      #("display", "flex"),
      #("flex-direction", "column"),
      #("justify-content", "center"),
      #("align-items", "center"),
      #("width", "100%"),
      #("height", "100%"),
      #("background-color", "#1a1a2e"),
    ])],
    [
      element.element(
        "h1",
        [attribute.styles([#("color", "white"), #("font-size", "48px")])],
        [element.text("My Blog Post")],
      ),
    ],
  )

  case og_image.render(el, og_image.defaults()) {
    Ok(png_bytes) -> {
      // Save or serve the PNG bytes
      png_bytes
    }
    Error(err) -> {
      // Handle error
      panic
    }
  }
}
```

## Configuration

The default configuration produces 1200x630 PNG images (standard OG image dimensions):

```gleam
og_image.defaults()
// => Config(width: 1200, height: 630, format: Png, fonts: [])
```

Customize dimensions and format:

```gleam
import og_image.{Config, Jpeg, WebP, Font, Normal, Italic}

// JPEG with 80% quality
let config = Config(..og_image.defaults(), format: Jpeg(80))

// WebP with custom dimensions
let config = Config(
  width: 1200,
  height: 630,
  format: WebP(80),
  fonts: [],
)

// With custom fonts
let config = Config(
  width: 1200,
  height: 630,
  format: Png,
  fonts: [
    Font("Inter", "/path/to/Inter.ttf", 400, Normal),
    Font("Inter", "/path/to/Inter-Italic.ttf", 400, Italic),
  ],
)
```

## Supported Elements

| HTML Element | Takumi Type | Notes |
|--------------|-------------|-------|
| div, section, header, footer, nav, main, aside, article | Container | Flexbox layout |
| p, span, h1-h6, strong, em, a, label, code, pre | Text | Text rendering |
| img | Image | Supports URLs and data URIs |
| svg | Image | Inline SVG elements are auto-converted to images |

## Supported Styles

All CSS flexbox properties are supported, along with:

- `background-color`, `background` (gradients)
- `color`, `font-size`, `font-family`, `font-weight`
- `padding`, `margin`, `border`, `border-radius`
- `width`, `height`, `min-width`, `max-width`, `min-height`, `max-height`
- `gap`, `row-gap`, `column-gap`
- `box-shadow`, `opacity`

## Bundled Fonts

The library includes [Geist](https://vercel.com/font) fonts (Sans and Mono) which are used by default. These fonts are licensed under the [SIL Open Font License](priv/fonts/OFL.txt).

## Requirements

- Erlang/OTP 26+
- Gleam 1.0+

For building from source (optional):
- Rust

## Development

```sh
# Build NIF from source (requires Rust)
make build

# Run tests
make test

# Clean build artifacts
make clean
```

## License

Apache-2.0
