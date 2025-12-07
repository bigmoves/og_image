import gleam/io
import lustre/attribute
import lustre/element
import og_image
import simplifile

pub fn render_takumi_playground_test() {
  // Outer container - w-full h-full justify-center bg-black items-center
  // with radial gradient background
  let el =
    element.element(
      "div",
      [
        attribute.styles([
          #("display", "flex"),
          #("width", "100%"),
          #("height", "100%"),
          #("justify-content", "center"),
          #("align-items", "center"),
          #("background-color", "black"),
          #(
            "background-image",
            "radial-gradient(circle at 25px 25px, lightgray 2%, transparent 0%), radial-gradient(circle at 75px 75px, lightgray 2%, transparent 0%)",
          ),
          #("background-size", "100px 100px"),
        ]),
      ],
      [
        // Inner container - justify-center items-center flex flex-col text-white
        element.element(
          "div",
          [
            attribute.styles([
              #("display", "flex"),
              #("flex-direction", "column"),
              #("justify-content", "center"),
              #("align-items", "center"),
              #("color", "white"),
            ]),
          ],
          [
            // h1 - font-semibold text-6xl block whitespace-pre mt-0
            element.element(
              "h1",
              [
                attribute.styles([
                  #("font-weight", "600"),
                  #("font-size", "60px"),
                  #("white-space", "pre"),
                  #("margin-top", "0"),
                ]),
              ],
              [
                element.text("Welcome to "),
                // span with text-[#ff3535]
                element.element(
                  "span",
                  [attribute.styles([#("color", "#ff3535")])],
                  [element.text("Takumi ")],
                ),
                element.text("Playground 👋"),
              ],
            ),
            // span - opacity-75 text-4xl font-[Geist_Mono]
            element.element(
              "span",
              [
                attribute.styles([
                  #("opacity", "0.75"),
                  #("font-size", "36px"),
                  #("font-family", "Geist Mono"),
                ]),
              ],
              [element.text("You can try out and experiment with Takumi here.")],
            ),
          ],
        ),
      ],
    )

  let config = og_image.defaults()

  case og_image.render(el, config) {
    Ok(bytes) -> {
      case simplifile.write_bits("test/takumi_playground.png", bytes) {
        Ok(_) -> io.println("Saved to takumi_playground.png")
        Error(_) -> io.println("Failed to write file")
      }
    }
    Error(_err) -> {
      io.println("Error rendering image")
      Nil
    }
  }
}
