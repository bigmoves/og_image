# Wisp 2 + Mist 5 OG Image Server Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a web server example that serves the 01-basic OG image from a `/og.png` HTTP endpoint.

**Architecture:** Single-file Wisp application with one route handler. Renders the same Lustre element as 01-basic on each request and returns PNG bytes with appropriate content-type header.

**Tech Stack:** Gleam, Wisp 2, Mist 5, og_image, Lustre

---

### Task 1: Update gleam.toml Dependencies

**Files:**
- Modify: `example/02-wisp/gleam.toml`

**Step 1: Update dependencies**

Replace the entire file with:

```toml
name = "wisp_example"
version = "1.0.0"

[dependencies]
gleam_stdlib = ">= 0.44.0 and < 2.0.0"
gleam_erlang = ">= 1.0.0 and < 2.0.0"
wisp = ">= 2.0.0 and < 3.0.0"
mist = ">= 5.0.0 and < 6.0.0"
og_image = { path = "../.." }
lustre = ">= 5.0.0 and < 6.0.0"

[dev-dependencies]
gleeunit = ">= 1.0.0 and < 2.0.0"
```

**Step 2: Fetch dependencies**

Run: `cd example/02-wisp && gleam deps download`
Expected: Dependencies downloaded successfully

**Step 3: Verify build**

Run: `cd example/02-wisp && gleam build`
Expected: Build succeeds (may have unused import warning)

**Step 4: Commit**

```bash
git add example/02-wisp/gleam.toml example/02-wisp/manifest.toml
git commit -m "feat(02-wisp): add wisp, mist, og_image dependencies"
```

---

### Task 2: Implement the OG Element Builder

**Files:**
- Modify: `example/02-wisp/src/wisp_example.gleam`

**Step 1: Add the og_element function**

Replace the entire file with:

```gleam
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// Build the OG image element (same as 01-basic)
fn og_element() -> Element(Nil) {
  html.div(
    [
      attribute.styles([
        #("display", "flex"),
        #("flex-direction", "column"),
        #("justify-content", "center"),
        #("align-items", "center"),
        #("width", "100%"),
        #("height", "100%"),
        #("background", "linear-gradient(135deg, #667eea 0%, #764ba2 100%)"),
        #("padding", "40px"),
      ]),
    ],
    [
      html.h1(
        [
          attribute.styles([
            #("color", "white"),
            #("font-size", "72px"),
            #("font-weight", "700"),
            #("margin", "0"),
            #("text-align", "center"),
          ]),
        ],
        [html.text("Hello from Gleam!")],
      ),
      html.p(
        [
          attribute.styles([
            #("color", "rgba(255, 255, 255, 0.9)"),
            #("font-size", "32px"),
            #("margin-top", "20px"),
            #("text-align", "center"),
          ]),
        ],
        [html.text("OG images powered by Lustre + Takumi")],
      ),
      html.div(
        [
          attribute.styles([
            #("display", "flex"),
            #("align-items", "center"),
            #("gap", "12px"),
            #("margin-top", "60px"),
            #("padding", "16px 32px"),
            #("background-color", "rgba(255, 255, 255, 0.15)"),
            #("border-radius", "50px"),
          ]),
        ],
        [
          html.span(
            [
              attribute.styles([
                #("color", "white"),
                #("font-size", "24px"),
              ]),
            ],
            [html.text("Built with og_image")],
          ),
        ],
      ),
    ],
  )
}

pub fn main() {
  Nil
}
```

**Step 2: Verify build**

Run: `cd example/02-wisp && gleam build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add example/02-wisp/src/wisp_example.gleam
git commit -m "feat(02-wisp): add og_element builder function"
```

---

### Task 3: Implement the Request Handler

**Files:**
- Modify: `example/02-wisp/src/wisp_example.gleam`

**Step 1: Add imports and handler**

Update the imports at the top of the file to:

```gleam
import gleam/http
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import og_image
import wisp.{type Request, type Response}
```

**Step 2: Add the handle_request function**

Add this function after `og_element()` and before `main()`:

```gleam
/// Handle incoming HTTP requests
pub fn handle_request(req: Request) -> Response {
  case req.method, wisp.path_segments(req) {
    http.Get, ["og.png"] -> {
      case og_image.render(og_element(), og_image.defaults()) {
        Ok(png_bytes) ->
          wisp.response(200)
          |> wisp.set_header("content-type", "image/png")
          |> wisp.set_body(wisp.Bytes(png_bytes))
        Error(_) ->
          wisp.response(500)
          |> wisp.string_body("Render failed")
      }
    }
    _, _ -> wisp.not_found()
  }
}
```

**Step 3: Verify build**

Run: `cd example/02-wisp && gleam build`
Expected: Build succeeds (main still returns Nil, unused)

**Step 4: Commit**

```bash
git add example/02-wisp/src/wisp_example.gleam
git commit -m "feat(02-wisp): add request handler for /og.png"
```

---

### Task 4: Implement main() to Start the Server

**Files:**
- Modify: `example/02-wisp/src/wisp_example.gleam`

**Step 1: Update imports**

Update the imports to:

```gleam
import gleam/erlang/process
import gleam/http
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import mist
import og_image
import wisp.{type Request, type Response}
import wisp/wisp_mist
```

**Step 2: Replace the main function**

Replace `pub fn main() { Nil }` with:

```gleam
pub fn main() {
  wisp.configure_logger()

  let secret_key_base = wisp.random_string(64)

  let assert Ok(_) =
    wisp_mist.handler(handle_request, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}
```

**Step 3: Verify build**

Run: `cd example/02-wisp && gleam build`
Expected: Build succeeds with no warnings

**Step 4: Commit**

```bash
git add example/02-wisp/src/wisp_example.gleam
git commit -m "feat(02-wisp): add main() to start wisp/mist server"
```

---

### Task 5: Test the Server Manually

**Step 1: Start the server**

Run: `cd example/02-wisp && gleam run`
Expected: Server starts, logs show it's listening

**Step 2: Test the endpoint**

In another terminal:
Run: `curl -I http://localhost:8000/og.png`
Expected: `HTTP/1.1 200 OK` with `content-type: image/png`

**Step 3: Download the image**

Run: `curl -o /tmp/test-og.png http://localhost:8000/og.png && file /tmp/test-og.png`
Expected: `PNG image data, 1200 x 630`

**Step 4: Test 404**

Run: `curl -I http://localhost:8000/other`
Expected: `HTTP/1.1 404 Not Found`

**Step 5: Stop server and commit**

Stop the server (Ctrl+C), then:

```bash
git add -A
git commit -m "feat(02-wisp): complete wisp OG image server example"
```

---

## Final File

After all tasks, `example/02-wisp/src/wisp_example.gleam` should contain:

```gleam
import gleam/erlang/process
import gleam/http
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import mist
import og_image
import wisp.{type Request, type Response}
import wisp/wisp_mist

/// Build the OG image element (same as 01-basic)
fn og_element() -> Element(Nil) {
  html.div(
    [
      attribute.styles([
        #("display", "flex"),
        #("flex-direction", "column"),
        #("justify-content", "center"),
        #("align-items", "center"),
        #("width", "100%"),
        #("height", "100%"),
        #("background", "linear-gradient(135deg, #667eea 0%, #764ba2 100%)"),
        #("padding", "40px"),
      ]),
    ],
    [
      html.h1(
        [
          attribute.styles([
            #("color", "white"),
            #("font-size", "72px"),
            #("font-weight", "700"),
            #("margin", "0"),
            #("text-align", "center"),
          ]),
        ],
        [html.text("Hello from Gleam!")],
      ),
      html.p(
        [
          attribute.styles([
            #("color", "rgba(255, 255, 255, 0.9)"),
            #("font-size", "32px"),
            #("margin-top", "20px"),
            #("text-align", "center"),
          ]),
        ],
        [html.text("OG images powered by Lustre + Takumi")],
      ),
      html.div(
        [
          attribute.styles([
            #("display", "flex"),
            #("align-items", "center"),
            #("gap", "12px"),
            #("margin-top", "60px"),
            #("padding", "16px 32px"),
            #("background-color", "rgba(255, 255, 255, 0.15)"),
            #("border-radius", "50px"),
          ]),
        ],
        [
          html.span(
            [
              attribute.styles([
                #("color", "white"),
                #("font-size", "24px"),
              ]),
            ],
            [html.text("Built with og_image")],
          ),
        ],
      ),
    ],
  )
}

/// Handle incoming HTTP requests
pub fn handle_request(req: Request) -> Response {
  case req.method, wisp.path_segments(req) {
    http.Get, ["og.png"] -> {
      case og_image.render(og_element(), og_image.defaults()) {
        Ok(png_bytes) ->
          wisp.response(200)
          |> wisp.set_header("content-type", "image/png")
          |> wisp.set_body(wisp.Bytes(png_bytes))
        Error(_) ->
          wisp.response(500)
          |> wisp.string_body("Render failed")
      }
    }
    _, _ -> wisp.not_found()
  }
}

pub fn main() {
  wisp.configure_logger()

  let secret_key_base = wisp.random_string(64)

  let assert Ok(_) =
    wisp_mist.handler(handle_request, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}
```
