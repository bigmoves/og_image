// JavaScript FFI for og_image - wraps takumi-wasm
import { Ok, Error } from "./gleam.mjs";

let renderer = null;
let initPromise = null;

// Lazy import to avoid issues when not on JS target
async function getTakumiWasm() {
  const module = await import("@takumi-rs/wasm");
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
