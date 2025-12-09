# Unified Synchronous API Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `og_image.render()` return `Result(BitArray, RenderError)` on both Erlang and JavaScript targets, enabling 100% shared example code.

**Architecture:** JavaScript FFI uses `initSync` and `fs.readFileSync` to initialize takumi-wasm synchronously. WASM and fonts are auto-discovered from node_modules and the og_image package directory. Lazy initialization on first render.

**Tech Stack:** Gleam, takumi-wasm (with `initSync`), Node.js `fs` and `module` APIs.

---

### Task 1: Remove gleam_javascript dependency

Since we're going fully synchronous, we no longer need `gleam/javascript/promise`.

**Files:**
- Modify: `gleam.toml`

**Step 1: Remove gleam_javascript from gleam.toml**

Edit `gleam.toml` and remove this line from `[dependencies]`:
```
gleam_javascript = ">= 0.8.0 and < 1.0.0"
```

**Step 2: Verify the change**

```bash
cd /Users/chadmiller/code/og_image && grep gleam_javascript gleam.toml
```

Expected: No output (line removed).

**Step 3: Commit**

```bash
git add gleam.toml
git commit -m "chore: remove gleam_javascript dependency (going fully sync)"
```

---

### Task 2: Copy Twemoji font to priv/fonts

**Files:**
- Copy: `native/og_image_nif/assets/fonts/TwemojiMozilla-colr.woff2` → `priv/fonts/TwemojiMozilla-colr.woff2`

**Step 1: Copy the font file**

```bash
cp /Users/chadmiller/code/og_image/native/og_image_nif/assets/fonts/TwemojiMozilla-colr.woff2 /Users/chadmiller/code/og_image/priv/fonts/
```

**Step 2: Verify the file exists**

```bash
ls -la /Users/chadmiller/code/og_image/priv/fonts/
```

Expected: See `TwemojiMozilla-colr.woff2` in the list.

**Step 3: Commit**

```bash
git add priv/fonts/TwemojiMozilla-colr.woff2
git commit -m "chore: add Twemoji font to priv/fonts for JS target"
```

---

### Task 3: Rewrite og_image_ffi.mjs to be fully synchronous

**Files:**
- Modify: `src/og_image_ffi.mjs`

**Step 1: Replace the entire file with synchronous implementation**

```javascript
// JavaScript FFI for og_image - wraps takumi-wasm (synchronous)
import { readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { initSync, Renderer } from "@takumi-rs/wasm";
import { Ok, Error, toList, BitArray } from "./gleam.mjs";

const require = createRequire(import.meta.url);

let renderer = null;

// Auto-discover and initialize WASM + fonts on first use
function ensureInitialized() {
  if (renderer) return;

  // Resolve WASM file from node_modules
  const wasmPath = require.resolve("@takumi-rs/wasm/takumi_wasm_bg.wasm");
  const wasmBytes = readFileSync(wasmPath);

  // Initialize WASM synchronously
  initSync({ module: wasmBytes });
  renderer = new Renderer();

  // Resolve fonts from og_image package priv/fonts directory
  const __filename = fileURLToPath(import.meta.url);
  const __dirname = dirname(__filename);
  // From build/dev/javascript/og_image/ -> priv/fonts/
  // We need to find the package root - go up to find priv/
  const fontsDir = findFontsDir(__dirname);

  const fontFiles = [
    "Geist[wght].woff2",
    "GeistMono[wght].woff2",
    "TwemojiMozilla-colr.woff2",
  ];

  for (const file of fontFiles) {
    try {
      const fontPath = join(fontsDir, file);
      const fontData = readFileSync(fontPath);
      renderer.loadFont(fontData);
    } catch (e) {
      throw new globalThis.Error(`Failed to load bundled font ${file}: ${e.message}`);
    }
  }
}

// Find priv/fonts directory by walking up from current location
function findFontsDir(startDir) {
  let dir = startDir;
  for (let i = 0; i < 10; i++) {
    const candidate = join(dir, "priv", "fonts");
    try {
      readFileSync(join(candidate, "Geist[wght].woff2"));
      return candidate;
    } catch {
      dir = dirname(dir);
    }
  }
  throw new globalThis.Error("Could not find og_image priv/fonts directory");
}

export function renderImage(jsonStr, width, height, format, quality, resources) {
  try {
    ensureInitialized();
  } catch (e) {
    return new Error(e.message || String(e));
  }

  try {
    const node = JSON.parse(jsonStr);

    // Convert Gleam List of tuples to Map
    const fetchedResources = new Map();
    for (const [url, bytes] of resources) {
      fetchedResources.set(url, bytes.rawBuffer);
    }

    const options = {
      width,
      height,
      format,
      fetchedResources,
    };

    // Only set quality for jpeg/webp
    if (quality >= 0 && (format === "jpeg" || format === "webp")) {
      options.quality = quality;
    }

    const result = renderer.render(node, options);

    return new Ok(new BitArray(new Uint8Array(result)));
  } catch (e) {
    return new Error(e.message || String(e));
  }
}

// Synchronous fetch for Node.js - fetches URLs and returns resources
export function fetchAllSync(urls) {
  // For now, we'll use synchronous HTTP requests via child_process
  // This is a limitation - external images require sync fetch
  const results = [];

  for (const url of urls.toArray()) {
    try {
      // Use dynamic import workaround for sync fetch in Node
      // Note: This uses execSync which blocks but works
      const { execSync } = await import("node:child_process");
      const buffer = execSync(`curl -s "${url}"`, { encoding: "buffer", maxBuffer: 50 * 1024 * 1024 });
      results.push([url, new BitArray(new Uint8Array(buffer))]);
    } catch {
      // Skip failed fetches silently
    }
  }

  return toList(results);
}
```

**Step 2: Run gleam build to verify syntax**

```bash
cd /Users/chadmiller/code/og_image && gleam build --target javascript
```

Expected: Build succeeds.

---

### Task 4: Update ffi_js.gleam to remove async functions

**Files:**
- Modify: `src/og_image/ffi_js.gleam`

**Step 1: Replace the file with synchronous bindings**

```gleam
//// JavaScript FFI bindings for takumi-wasm (synchronous)
//// Only compiled on JavaScript target

/// Render an image from JSON (synchronous)
/// Automatically initializes WASM and loads fonts on first call
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

/// Fetch all URLs synchronously and return list of (url, bytes) tuples
/// Failed fetches are silently skipped
@target(javascript)
@external(javascript, "../og_image_ffi.mjs", "fetchAllSync")
pub fn fetch_all_sync(urls: List(String)) -> List(#(String, BitArray))
```

**Step 2: Run gleam build**

```bash
cd /Users/chadmiller/code/og_image && gleam build --target javascript
```

Expected: Build succeeds.

---

### Task 5: Simplify og_image.gleam to unified Config and render

**Files:**
- Modify: `src/og_image.gleam`

**Step 1: Replace the file with unified implementation**

```gleam
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
```

**Step 2: Run gleam build for both targets**

```bash
cd /Users/chadmiller/code/og_image && gleam build --target erlang && gleam build --target javascript
```

Expected: Both builds succeed.

**Step 3: Commit**

```bash
git add src/og_image.gleam src/og_image/ffi_js.gleam src/og_image_ffi.mjs
git commit -m "feat: unified synchronous API for both targets"
```

---

### Task 6: Fix fetchAllSync to be truly synchronous

**Files:**
- Modify: `src/og_image_ffi.mjs`

The previous `fetchAllSync` had an issue (used `await`). Replace with proper sync implementation using `execSync`:

**Step 1: Update fetchAllSync function**

Replace the `fetchAllSync` function in `src/og_image_ffi.mjs`:

```javascript
// Synchronous fetch for Node.js using curl
export function fetchAllSync(urls) {
  const { execSync } = require("node:child_process");
  const results = [];

  for (const url of urls.toArray()) {
    try {
      const buffer = execSync(`curl -sL "${url}"`, {
        encoding: "buffer",
        maxBuffer: 50 * 1024 * 1024,
        timeout: 30000,
      });
      results.push([url, new BitArray(new Uint8Array(buffer))]);
    } catch {
      // Skip failed fetches silently
    }
  }

  return toList(results);
}
```

**Step 2: Update the require import at top of file**

Add to the imports section:

```javascript
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
```

**Step 3: Verify build**

```bash
cd /Users/chadmiller/code/og_image && gleam build --target javascript
```

---

### Task 7: Create unified example.gleam

**Files:**
- Modify: `examples/01-basic/src/example.gleam`
- Delete: `examples/01-basic/src/example_js.gleam`

**Step 1: Replace example.gleam with unified version**

```gleam
//// Unified example - works on both Erlang and JavaScript targets
//// Run with: gleam run --target erlang
//// Or:       gleam run --target javascript

import gleam/io
import lustre/attribute
import lustre/element/html
import og_image

// Target-specific file writing
@target(erlang)
import simplifile

@target(javascript)
@external(javascript, "./file_writer.mjs", "writeFileSync")
fn write_file_sync(path: String, bytes: BitArray) -> Result(Nil, String)

pub fn main() {
  let og_element =
    html.div(
      [
        attribute.styles([
          #("display", "flex"),
          #("flex-direction", "column"),
          #("justify-content", "center"),
          #("align-items", "center"),
          #("width", "100%"),
          #("height", "100%"),
          #("background-color", "#292d3e"),
          #("padding", "40px"),
        ]),
      ],
      [
        // Lucy image
        html.img([
          attribute.src("https://gleam.run/images/lucy/lucy.svg"),
          attribute.styles([
            #("width", "200px"),
            #("height", "auto"),
          ]),
        ]),
        // Title
        html.h1(
          [
            attribute.styles([
              #("color", "white"),
              #("font-size", "72px"),
              #("font-weight", "700"),
              #("margin", "0"),
              #("margin-top", "40px"),
              #("text-align", "center"),
            ]),
          ],
          [html.text("Hello from Gleam!")],
        ),
      ],
    )

  // Render as PNG with default config (1200x630)
  io.println("Rendering OG image...")

  case og_image.render(og_element, og_image.defaults()) {
    Ok(png_bytes) -> {
      io.println("Render successful!")
      save_file("output.png", png_bytes)
    }
    Error(e) -> {
      io.println("Render failed:")
      case e {
        og_image.InvalidElement(reason) ->
          io.println("  Invalid element: " <> reason)
        og_image.FontLoadError(path) ->
          io.println("  Font load error: " <> path)
        og_image.ImageLoadError(src) ->
          io.println("  Image load error: " <> src)
        og_image.RenderFailed(reason) ->
          io.println("  Render failed: " <> reason)
      }
    }
  }

  io.println("Done!")
}

// Target-specific file saving
@target(erlang)
fn save_file(path: String, bytes: BitArray) {
  case simplifile.write_bits(path, bytes) {
    Ok(_) -> io.println("Saved to " <> path)
    Error(e) -> io.println("Failed to save: " <> simplifile.describe_error(e))
  }
}

@target(javascript)
fn save_file(path: String, bytes: BitArray) {
  case write_file_sync(path, bytes) {
    Ok(_) -> io.println("Saved to " <> path)
    Error(e) -> io.println("Failed to save: " <> e)
  }
}
```

**Step 2: Update file_writer.mjs to be synchronous**

Replace `examples/01-basic/src/file_writer.mjs`:

```javascript
import { writeFileSync } from "node:fs";
import { Ok, Error } from "../og_image/gleam.mjs";

export function writeFileSync(path, bytes) {
  try {
    writeFileSync(path, Buffer.from(bytes.rawBuffer));
    return new Ok(undefined);
  } catch (e) {
    return new Error(e.message || String(e));
  }
}
```

**Step 3: Delete old files**

```bash
rm /Users/chadmiller/code/og_image/examples/01-basic/src/example_js.gleam
rm /Users/chadmiller/code/og_image/examples/01-basic/src/wasm_loader.mjs
rm /Users/chadmiller/code/og_image/examples/01-basic/run_js.mjs
```

**Step 4: Build and test Erlang**

```bash
cd /Users/chadmiller/code/og_image/examples/01-basic && gleam run --target erlang
```

Expected: "Saved to output.png"

**Step 5: Build and test JavaScript**

```bash
cd /Users/chadmiller/code/og_image/examples/01-basic && gleam run --target javascript
```

Expected: "Saved to output.png"

**Step 6: Verify both outputs are valid images**

Manually inspect `output.png` - should show Lucy star and "Hello from Gleam!" text.

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: unified example works on both Erlang and JavaScript targets"
```

---

### Task 8: Run tests on both targets

**Files:**
- Test: `test/og_image_test.gleam`

**Step 1: Run Erlang tests**

```bash
cd /Users/chadmiller/code/og_image && gleam test --target erlang
```

Expected: All tests pass.

**Step 2: Run JavaScript tests (if any)**

```bash
cd /Users/chadmiller/code/og_image && gleam test --target javascript
```

Expected: Tests pass or skip gracefully.

**Step 3: Commit if any test fixes needed**

---

### Task 9: Clean up unused code

**Files:**
- Review and remove any unused imports/functions

**Step 1: Remove WasmNotInitialized from RenderError**

Since WASM auto-initializes, this error is no longer possible. Remove from `src/og_image.gleam`:

In the `RenderError` type, remove `WasmNotInitialized`.

**Step 2: Remove unused imports from og_image.gleam**

Remove these if no longer needed:
- `gleam/javascript/promise`
- `gleam/option`

**Step 3: Build both targets**

```bash
gleam build --target erlang && gleam build --target javascript
```

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: remove unused WasmNotInitialized and async code"
```

---

## Summary

After completing all tasks:

1. `og_image.render()` returns `Result(BitArray, RenderError)` on **both** targets
2. `og_image.Config` is identical on both targets (no `wasm` or `font_data` fields)
3. Example code is ~95% shared (only file-writing differs)
4. JavaScript auto-discovers WASM from `node_modules/@takumi-rs/wasm`
5. JavaScript auto-discovers fonts from `priv/fonts/`
6. First render initializes everything synchronously
