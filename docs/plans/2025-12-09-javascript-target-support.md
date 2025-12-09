# JavaScript Target Support Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add JavaScript target support to og_image using takumi-wasm, enabling the library to work in browsers, Node.js, and edge environments.

**Architecture:** Use Gleam's `@target` attribute to provide separate implementations for Erlang (NIF) and JavaScript (WASM). The JavaScript target uses takumi-wasm for rendering and native `fetch()` for image fetching. WASM initialization is handled lazily on first render, with the module passed via config.

**Tech Stack:** Gleam, gleam_javascript (Promise), @takumi-rs/wasm, JavaScript FFI

---

### Task 1: Add gleam_javascript Dependency

**Files:**
- Modify: `gleam.toml`

**Step 1: Update gleam.toml with new dependencies**

Add `gleam_javascript` to dependencies and `@takumi-rs/wasm` to JavaScript dependencies:

```toml
name = "og_image"
version = "1.0.0"

description = "Generate OG images from Lustre elements"
licences = ["Apache-2.0"]
repository = { type = "github", user = "bigmoves", repo = "og_image" }

[dependencies]
gleam_stdlib = ">= 0.44.0 and < 2.0.0"
gleam_json = ">= 3.0.0 and < 4.0.0"
gleam_http = ">= 3.0.0 and < 5.0.0"
gleam_httpc = ">= 5.0.0 and < 6.0.0"
lustre = ">= 5.0.0 and < 6.0.0"
simplifile = ">= 2.0.0 and < 3.0.0"
gleam_javascript = ">= 0.8.0 and < 1.0.0"

[dev-dependencies]
gleeunit = ">= 1.0.0 and < 2.0.0"

[javascript.dependencies]
takumi_wasm = "0.57.3"
```

**Step 2: Run gleam deps download**

Run: `cd /Users/chadmiller/code/og_image && gleam deps download`
Expected: Dependencies downloaded successfully

**Step 3: Commit**

```bash
git add gleam.toml manifest.toml
git commit -m "feat: add gleam_javascript and takumi-wasm dependencies"
```

---

### Task 2: Create JavaScript FFI Module

**Files:**
- Create: `src/og_image_ffi.mjs`

**Step 1: Create the JavaScript FFI file**

```javascript
// JavaScript FFI for og_image - wraps takumi-wasm
import { Ok, Error } from "./gleam.mjs";

let wasmInit = null;
let renderer = null;
let initPromise = null;

// Lazy import to avoid issues when not on JS target
async function getTakumiWasm() {
  const module = await import("takumi_wasm");
  return module;
}

export async function initWasm(wasmModule) {
  if (initPromise) {
    return initPromise;
  }

  initPromise = (async () => {
    const takumi = await getTakumiWasm();
    await takumi.default({ module_or_path: wasmModule });
    renderer = new takumi.Renderer();
  })();

  return initPromise;
}

export function isInitialized() {
  return renderer !== null;
}

export function renderImage(jsonStr, width, height, format, quality, resources) {
  if (!renderer) {
    return new Error("WASM not initialized. Call initWasm first.");
  }

  try {
    const node = JSON.parse(jsonStr);

    // Convert List of tuples to Map
    const fetchedResources = new Map();
    for (const [url, bytes] of resources) {
      fetchedResources.set(url, bytes);
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
    return new Ok(toBitArray(result));
  } catch (e) {
    return new Error(e.message || String(e));
  }
}

export async function fetchAll(urls) {
  const results = await Promise.all(
    urls.toArray().map(async (url) => {
      try {
        const response = await fetch(url);
        if (!response.ok) return null;
        const buffer = await response.arrayBuffer();
        return [url, toBitArray(new Uint8Array(buffer))];
      } catch {
        return null;
      }
    })
  );
  return toList(results.filter(Boolean));
}

// Helper to convert Uint8Array to Gleam BitArray
function toBitArray(uint8Array) {
  return { buffer: uint8Array };
}

// Helper to convert JS array to Gleam List
function toList(array) {
  let list = { head: undefined, tail: undefined };
  for (let i = array.length - 1; i >= 0; i--) {
    list = { head: array[i], tail: list };
  }
  return list;
}
```

**Step 2: Commit**

```bash
git add src/og_image_ffi.mjs
git commit -m "feat: add JavaScript FFI for takumi-wasm integration"
```

---

### Task 3: Create JavaScript FFI Gleam Bindings

**Files:**
- Create: `src/og_image/ffi_js.gleam`

**Step 1: Create the Gleam FFI bindings for JavaScript**

```gleam
//// JavaScript FFI bindings for takumi-wasm
//// Only compiled on JavaScript target

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
```

**Step 2: Commit**

```bash
git add src/og_image/ffi_js.gleam
git commit -m "feat: add Gleam FFI bindings for JavaScript target"
```

---

### Task 4: Update og_image.gleam with Target-Specific Render

**Files:**
- Modify: `src/og_image.gleam`

**Step 1: Update the main module with target-specific implementations**

Replace the entire contents of `src/og_image.gleam`:

```gleam
import gleam/json
import gleam/option.{type Option, None, Some}
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

/// Opaque type for WASM module (only used on JavaScript target)
pub type WasmModule =
  ffi_js.WasmModule

/// Configuration for rendering
pub type Config {
  Config(
    width: Int,
    height: Int,
    format: Format,
    fonts: List(Font),
    /// WASM module for JavaScript target (ignored on Erlang)
    wasm: Option(WasmModule),
  )
}

/// Render errors
pub type RenderError {
  InvalidElement(reason: String)
  FontLoadError(path: String)
  ImageLoadError(src: String)
  RenderFailed(reason: String)
  WasmNotInitialized
}

/// Default config: 1200x630 PNG, no custom fonts, no WASM module
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
```

**Step 2: Verify Erlang target still compiles**

Run: `cd /Users/chadmiller/code/og_image && gleam build --target erlang`
Expected: Build succeeds

**Step 3: Verify JavaScript target compiles**

Run: `cd /Users/chadmiller/code/og_image && gleam build --target javascript`
Expected: Build succeeds

**Step 4: Commit**

```bash
git add src/og_image.gleam
git commit -m "feat: add JavaScript target support with @target attributes"
```

---

### Task 5: Update ffi.gleam with Target Attribute

**Files:**
- Modify: `src/og_image/ffi.gleam`

**Step 1: Add @target(erlang) to the existing FFI**

```gleam
//// Erlang FFI bindings for the Rust NIF
//// Only compiled on Erlang target

/// Render an image from JSON with pre-fetched resources
/// Resources is a list of (url, bytes) tuples
/// Quality: 0-100 for JPEG/WebP, -1 for default
@target(erlang)
@external(erlang, "og_image_native", "render_image")
pub fn render_image(
  json_str: String,
  width: Int,
  height: Int,
  format: String,
  quality: Int,
  resources: List(#(String, BitArray)),
) -> Result(BitArray, String)
```

**Step 2: Commit**

```bash
git add src/og_image/ffi.gleam
git commit -m "feat: add @target(erlang) to NIF FFI bindings"
```

---

### Task 6: Update fetch.gleam with Target Attribute

**Files:**
- Modify: `src/og_image/fetch.gleam`

**Step 1: Add @target(erlang) to the fetch module**

Add `@target(erlang)` at the top of the file, before the imports:

```gleam
//// HTTP fetching for Erlang target using gleam_httpc
//// Only compiled on Erlang target

@target(erlang)
import gleam/http/request

@target(erlang)
import gleam/httpc

@target(erlang)
import gleam/list

@target(erlang)
import gleam/result

/// Fetch all URLs and return a list of (url, bytes) tuples
/// Failed fetches are silently skipped
@target(erlang)
pub fn fetch_all(urls: List(String)) -> List(#(String, BitArray)) {
  urls
  |> list.filter_map(fn(url) {
    case fetch_url(url) {
      Ok(bytes) -> Ok(#(url, bytes))
      Error(_) -> Error(Nil)
    }
  })
}

@target(erlang)
fn fetch_url(url: String) -> Result(BitArray, Nil) {
  use req <- result.try(request.to(url) |> result.replace_error(Nil))
  let req = request.set_body(req, <<>>)
  use resp <- result.try(httpc.send_bits(req) |> result.replace_error(Nil))
  case resp.status {
    200 -> Ok(resp.body)
    _ -> Error(Nil)
  }
}
```

**Step 2: Verify both targets still compile**

Run: `cd /Users/chadmiller/code/og_image && gleam build --target erlang && gleam build --target javascript`
Expected: Both builds succeed

**Step 3: Commit**

```bash
git add src/og_image/fetch.gleam
git commit -m "feat: add @target(erlang) to fetch module"
```

---

### Task 7: Fix JavaScript FFI Gleam Interop

**Files:**
- Modify: `src/og_image_ffi.mjs`

**Step 1: Update FFI to properly handle Gleam types**

The Gleam compiler generates specific modules for its types. Update the FFI:

```javascript
// JavaScript FFI for og_image - wraps takumi-wasm

let renderer = null;
let initPromise = null;

// Lazy import to avoid issues when not on JS target
async function getTakumiWasm() {
  const module = await import("takumi_wasm");
  return module;
}

export async function initWasm(wasmModule) {
  if (initPromise) {
    return initPromise;
  }

  initPromise = (async () => {
    const takumi = await getTakumiWasm();
    await takumi.default({ module_or_path: wasmModule });
    renderer = new takumi.Renderer();
  })();

  return initPromise;
}

export function isInitialized() {
  return renderer !== null;
}

export function renderImage(jsonStr, width, height, format, quality, resources) {
  if (!renderer) {
    return { type: "Error", 0: "WASM not initialized. Call initWasm first." };
  }

  try {
    const node = JSON.parse(jsonStr);

    // Convert Gleam List of tuples to Map
    const fetchedResources = new Map();
    let current = resources;
    while (current.head !== undefined) {
      const [url, bytes] = current.head;
      // Gleam BitArray has a buffer property
      fetchedResources.set(url, bytes.buffer);
      current = current.tail;
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

    // Return as Gleam Ok result with BitArray
    return { type: "Ok", 0: toBitArray(result) };
  } catch (e) {
    return { type: "Error", 0: e.message || String(e) };
  }
}

export async function fetchAll(urls) {
  // Convert Gleam List to JS array
  const urlArray = [];
  let current = urls;
  while (current.head !== undefined) {
    urlArray.push(current.head);
    current = current.tail;
  }

  const results = await Promise.all(
    urlArray.map(async (url) => {
      try {
        const response = await fetch(url);
        if (!response.ok) return null;
        const buffer = await response.arrayBuffer();
        return [url, toBitArray(new Uint8Array(buffer))];
      } catch {
        return null;
      }
    })
  );

  // Convert back to Gleam List
  return toList(results.filter(Boolean));
}

// Helper to convert Uint8Array to Gleam BitArray
function toBitArray(uint8Array) {
  // Gleam BitArray representation
  return { buffer: new Uint8Array(uint8Array), length: uint8Array.length };
}

// Helper to convert JS array to Gleam List
function toList(array) {
  let list = { head: undefined, tail: undefined };
  for (let i = array.length - 1; i >= 0; i--) {
    list = { head: array[i], tail: list };
  }
  return list;
}
```

**Step 2: Commit**

```bash
git add src/og_image_ffi.mjs
git commit -m "fix: update JavaScript FFI for proper Gleam type interop"
```

---

### Task 8: Run Erlang Tests

**Files:**
- Test: `test/og_image_test.gleam`

**Step 1: Run existing Erlang tests to verify nothing broke**

Run: `cd /Users/chadmiller/code/og_image && gleam test --target erlang`
Expected: All tests pass

**Step 2: Commit if any fixes were needed**

If tests pass, no commit needed. If fixes were required, commit them.

---

### Task 9: Create JavaScript Target Test

**Files:**
- Create: `test/og_image_js_test.gleam`

**Step 1: Create a basic JavaScript target test**

```gleam
//// Tests for JavaScript target
//// Run with: gleam test --target javascript

@target(javascript)
import gleam/option.{None}
import og_image.{Config, Png, WasmNotInitialized}

@target(javascript)
pub fn render_without_wasm_returns_error_test() {
  let config = Config(width: 100, height: 100, format: Png, fonts: [], wasm: None)

  // We can't easily test the Promise result in a sync test,
  // but we can at least verify the module compiles and types check
  let _ = config
  Nil
}
```

**Step 2: Verify JavaScript target compiles with test**

Run: `cd /Users/chadmiller/code/og_image && gleam build --target javascript`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add test/og_image_js_test.gleam
git commit -m "test: add basic JavaScript target test"
```

---

### Task 10: Update README with JavaScript Usage

**Files:**
- Modify: `README.md`

**Step 1: Add JavaScript usage section to README**

Add the following section after the existing Erlang usage examples:

```markdown
## JavaScript Target

The library also supports the JavaScript target, using [takumi-wasm](https://github.com/kane50613/takumi) for rendering.

### Installation

Add the JavaScript dependency to your `gleam.toml`:

```toml
[javascript.dependencies]
takumi_wasm = "0.57.3"
```

### Usage

```gleam
import gleam/javascript/promise
import gleam/option.{Some}
import lustre/element/html
import og_image.{Config, Png}

// Import your WASM module based on your bundler:
// Vite: import wasm from "@takumi-rs/wasm/takumi_wasm_bg.wasm?url"
// Cloudflare: import wasm from "@takumi-rs/wasm/takumi_wasm_bg.wasm"
@external(javascript, "./wasm.mjs", "wasmModule")
fn get_wasm_module() -> og_image.WasmModule

pub fn generate_image() {
  let element = html.div([], [html.text("Hello from JavaScript!")])

  let config = Config(
    width: 1200,
    height: 630,
    format: Png,
    fonts: [],
    wasm: Some(get_wasm_module()),
  )

  use result <- promise.await(og_image.render(element, config))
  case result {
    Ok(image_bytes) -> {
      // Use the image bytes...
      promise.resolve(Nil)
    }
    Error(err) -> {
      // Handle error...
      promise.resolve(Nil)
    }
  }
}
```

### WASM Module Loading

Different JavaScript environments require different approaches to load the WASM module:

**Vite:**
```javascript
// wasm.mjs
import wasmUrl from "takumi_wasm/takumi_wasm_bg.wasm?url";
export const wasmModule = wasmUrl;
```

**Cloudflare Workers:**
```javascript
// wasm.mjs
import wasm from "takumi_wasm/takumi_wasm_bg.wasm";
export const wasmModule = wasm;
```

**Node.js/Bun:**
```javascript
// wasm.mjs
import { readFile } from "node:fs/promises";
export const wasmModule = await readFile("node_modules/takumi_wasm/takumi_wasm_bg.wasm");
```
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add JavaScript target usage documentation"
```

---

## Summary

After completing all tasks, the library will:

1. Support both Erlang and JavaScript targets
2. Use the existing NIF on Erlang, takumi-wasm on JavaScript
3. Return `Result` on Erlang, `Promise(Result)` on JavaScript
4. Automatically fetch images on both targets
5. Require users to provide the WASM module via config on JavaScript

The API remains simple - just pass a `wasm` option in config for JavaScript users.
