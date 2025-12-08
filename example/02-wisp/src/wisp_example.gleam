import gleam/bytes_tree
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
          |> wisp.set_body(wisp.Bytes(bytes_tree.from_bit_array(png_bytes)))
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
