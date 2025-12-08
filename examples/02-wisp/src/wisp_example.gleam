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
