type t = string

let to_string s = s

let escape_string = String.map (function '/' | ':' -> '-' | c -> c)

let of_string_exn s =
  assert (not (String.contains s '/'));
  assert (not (String.contains s ':'));
  s
