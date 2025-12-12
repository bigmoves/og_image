// JavaScript FFI for og_image - wraps takumi-wasm (synchronous)
import { readFileSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { Ok, Error, toList, BitArray } from "./gleam.mjs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Find a priv subdirectory by walking up from current location
function findPrivDir(startDir, subdir, checkFile) {
  let dir = startDir;
  for (let i = 0; i < 10; i++) {
    const candidate = join(dir, "priv", subdir);
    try {
      readFileSync(join(candidate, checkFile));
      return candidate;
    } catch {
      dir = dirname(dir);
    }
  }
  throw new globalThis.Error(`Could not find og_image priv/${subdir} directory`);
}

// Load vendored modules from priv/vendor at module load time
const vendorDir = findPrivDir(__dirname, "vendor", "takumi_wasm_bg.wasm");
const { initSync, Renderer } = await import(join(vendorDir, "takumi_wasm.js"));

let renderer = null;

// Auto-discover and initialize WASM + fonts on first use
function ensureInitialized() {
  if (renderer) return;

  // Load WASM bytes from priv/vendor
  const wasmPath = join(vendorDir, "takumi_wasm_bg.wasm");
  const wasmBytes = readFileSync(wasmPath);

  // Initialize WASM synchronously
  initSync({ module: wasmBytes });
  renderer = new Renderer();

  // Load fonts from priv/fonts
  const fontsDir = findPrivDir(__dirname, "fonts", "Geist[wght].woff2");
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

// Synchronous fetch using Node subprocess with native fetch
function fetchSync(url) {
  const workerPath = join(vendorDir, "fetch-worker.mjs");
  try {
    const result = execFileSync(process.execPath, [workerPath], {
      input: url,
      maxBuffer: 50 * 1024 * 1024,
      timeout: 30000,
    });
    const { data, error } = JSON.parse(result.toString());
    if (error) return null;
    return Buffer.from(data, 'base64');
  } catch {
    return null;
  }
}

export function fetchAllSync(urls) {
  const results = [];

  for (const url of urls.toArray()) {
    const buffer = fetchSync(url);
    if (buffer) {
      results.push([url, new BitArray(new Uint8Array(buffer))]);
    }
  }

  return toList(results);
}
