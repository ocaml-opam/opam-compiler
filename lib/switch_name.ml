type t = string

let pp ppf s = Format.fprintf ppf "%S" s

let equal (x : t) y = x = y

let to_string s = s

let invalid_chars = [ '/'; ':'; '#' ]

let count_leading_dashes s =
  let exception Done in
  let r = ref 0 in
  (try String.iter (function '-' -> incr r | _ -> raise Done) s
   with Done -> ());
  !r

let strip_leading_dashes s =
  let n = count_leading_dashes s in
  let s_len = String.length s in
  String.sub s n (s_len - n)

let escape_string s =
  s
  |> String.map (fun c -> if List.mem c invalid_chars then '-' else c)
  |> strip_leading_dashes

let parse s =
  if List.exists (fun c -> String.contains s c) invalid_chars then
    Rresult.R.error_msg "String contains an invalid character"
  else Ok s

let of_string_exn s = parse s |> Rresult.R.failwith_error_msg
