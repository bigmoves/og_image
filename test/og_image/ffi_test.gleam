import gleeunit/should
import og_image/ffi

pub fn hello_test() {
  ffi.hello()
  |> should.equal("Hello from Rust NIF!")
}
