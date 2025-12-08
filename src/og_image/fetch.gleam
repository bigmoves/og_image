import gleam/http/request
import gleam/httpc
import gleam/list
import gleam/result

/// Fetch all URLs and return a list of (url, bytes) tuples
/// Failed fetches are silently skipped
pub fn fetch_all(urls: List(String)) -> List(#(String, BitArray)) {
  urls
  |> list.filter_map(fn(url) {
    case fetch_url(url) {
      Ok(bytes) -> Ok(#(url, bytes))
      Error(_) -> Error(Nil)
    }
  })
}

fn fetch_url(url: String) -> Result(BitArray, Nil) {
  use req <- result.try(request.to(url) |> result.replace_error(Nil))
  let req = request.set_body(req, <<>>)
  use resp <- result.try(httpc.send_bits(req) |> result.replace_error(Nil))
  case resp.status {
    200 -> Ok(resp.body)
    _ -> Error(Nil)
  }
}
