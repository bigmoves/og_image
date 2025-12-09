// JavaScript FFI for og_image - wraps takumi-wasm
import * as takumi from "@takumi-rs/wasm";
import { Ok, Error, toList, BitArray } from "./gleam.mjs";

let renderer = null;
let initPromise = null;

export async function initWasm(wasmModule) {
  if (initPromise) {
    return initPromise;
  }

  initPromise = (async () => {
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

export async function fetchAll(urls) {
  const results = await Promise.all(
    urls.toArray().map(async (url) => {
      try {
        const response = await fetch(url);
        if (!response.ok) return null;
        const buffer = await response.arrayBuffer();
        return [url, new BitArray(new Uint8Array(buffer))];
      } catch {
        return null;
      }
    })
  );

  return toList(results.filter(Boolean));
}
