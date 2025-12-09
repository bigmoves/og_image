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
