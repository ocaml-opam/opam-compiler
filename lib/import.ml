let re_group_get_opt group num =
  match Re.Group.get group num with s -> Some s | exception Not_found -> None

module Let_syntax = struct
  module Cmdliner = struct
    open Cmdliner.Term

    let ( let+ ) t f = const f $ t

    let ( and+ ) a b = const (fun x y -> (x, y)) $ a $ b
  end

  module Option = struct
    let ( let+ ) x f = Option.map f x

    let ( let* ) = Option.bind

    let ( and+ ) xo yo =
      let* x = xo in
      let+ y = yo in
      (x, y)
  end

  module Result = struct
    let ( let+ ) x f = Result.map f x

    let ( let* ) = Result.bind
  end
end

let pp_env ppf = function
  | None -> ()
  | Some kvs -> List.iter (fun (k, v) -> Format.fprintf ppf "%s=%s " k v) kvs

let needs_quoting s = Astring.String.exists Astring.Char.Ascii.is_white s

let quote s = Printf.sprintf {|"%s"|} s

let quote_if_needed s = if needs_quoting s then quote s else s

let pp_cmd ppf cmd =
  Bos.Cmd.to_list cmd |> List.map quote_if_needed |> String.concat " "
  |> Format.pp_print_string ppf

type error = [ `Command_failed of Bos.Cmd.t | `Configure_needed | `Unknown ]

let translate_error s =
  let open Rresult.R in
  reword_error (function
    | `Unknown -> msgf "%s" s
    | `Command_failed cmd -> msgf "%s - command failed: %a" s pp_cmd cmd
    | `Configure_needed -> msgf "%s - configure step is required" s)
