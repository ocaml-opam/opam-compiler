type t = string

let pp ppf s = Format.fprintf ppf "%S" s

let equal (x : t) y = x = y

let to_string s = s

let invalid_chars = [ '/'; ':'; '#' ]

let strip_leading_dashes =
  let open Re in
  let re = compile (seq [ bos; rep1 (char '-') ]) in
  replace_string re ~by:""

let remove_invalid_chars =
  let open Re in
  let re = compile (alt (List.map char invalid_chars)) in
  replace_string re ~by:"-"

let escape_string s = s |> remove_invalid_chars |> strip_leading_dashes

let parse s =
  if List.exists (fun c -> String.contains s c) invalid_chars then
    Rresult.R.error_msg "String contains an invalid character"
  else Ok s

let of_string_exn s = parse s |> Rresult.R.failwith_error_msg
