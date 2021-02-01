open! Import

type t = {
  run :
    ?extra_env:(string * string) list ->
    Bos.Cmd.t ->
    (unit, [ `Unknown ]) result;
  run_out : Bos.Cmd.t -> (string, [ `Unknown ]) result;
}

module Real = struct
  let get_env () =
    Bos.OS.Env.current () |> Rresult.R.reword_error (fun _ -> `Unknown)

  let run ?extra_env cmd =
    let open Let_syntax.Result in
    let* env =
      match extra_env with
      | None -> Ok None
      | Some l ->
          let+ cur = get_env () in
          let seq = List.to_seq l in
          Some (Astring.String.Map.add_seq seq cur)
    in
    Bos.OS.Cmd.in_null |> Bos.OS.Cmd.run_in ?env cmd
    |> Rresult.R.reword_error (fun _ -> `Unknown)

  let run_out cmd =
    Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.to_string
    |> Rresult.R.reword_error (fun _ -> `Unknown)
end

let real =
  let open Real in
  { run; run_out }

module Dry_run = struct
  let pp_env ppf = function
    | None -> ()
    | Some kvs -> List.iter (fun (k, v) -> Format.fprintf ppf "%s=%S " k v) kvs

  let needs_quoting s = Astring.String.exists Astring.Char.Ascii.is_white s

  let quote s = Printf.sprintf {|"%s"|} s

  let quote_if_needed s = if needs_quoting s then quote s else s

  let pp_cmd ppf cmd =
    Bos.Cmd.to_list cmd |> List.map quote_if_needed |> String.concat " "
    |> Format.fprintf ppf "%s\n"

  let run ?extra_env cmd =
    Format.printf "Run: %a%a" pp_env extra_env pp_cmd cmd;
    Ok ()

  let run_out cmd =
    Format.printf "Run_out: %a" pp_cmd cmd;
    Ok "output"
end

let dry_run =
  let open Dry_run in
  { run; run_out }

let run_out t = t.run_out

let run t = t.run
