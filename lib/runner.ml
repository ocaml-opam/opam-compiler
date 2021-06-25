open! Import

type run_error = [ `Command_failed of Bos.Cmd.t | `Unknown ]

type t = {
  run :
    ?extra_env:(string * string) list ->
    ?chdir:Fpath.t ->
    Bos.Cmd.t ->
    (unit, run_error) result;
  run_out :
    ?extra_env:(string * string) list -> Bos.Cmd.t -> (string, run_error) result;
}

module Real = struct
  let get_env () =
    Bos.OS.Env.current () |> Rresult.R.reword_error (fun _ -> `Unknown)

  let explicit_env extra_env =
    let open Let_syntax.Result in
    match extra_env with
    | None -> Ok None
    | Some l ->
        let+ cur = get_env () in
        let seq = List.to_seq l in
        Some (Astring.String.Map.add_seq seq cur)

  let with_chdir ~f = function
    | None -> f ()
    | Some dir ->
        let open Let_syntax.Result in
        let* r = Bos.OS.Dir.with_current dir f () in
        r

  let run ?extra_env ?chdir cmd =
    let open Let_syntax.Result in
    let* env = explicit_env extra_env in
    with_chdir chdir ~f:(fun () ->
        Bos.OS.Cmd.in_null |> Bos.OS.Cmd.run_in ?env cmd)
    |> Rresult.R.reword_error (fun _ -> `Command_failed cmd)

  let run_out ?extra_env cmd =
    let open Let_syntax.Result in
    let* env = explicit_env extra_env in
    Bos.OS.Cmd.run_out ?env cmd
    |> Bos.OS.Cmd.to_string
    |> Rresult.R.reword_error (fun _ -> `Command_failed cmd)
end

let real =
  let open Real in
  { run; run_out }

module Dry_run = struct
  let pp_chdir ppf = function
    | None -> ()
    | Some p -> Format.fprintf ppf "cd %a && " Fpath.pp p

  let run ?extra_env ?chdir cmd =
    Format.printf "Run: %a%a%a\n" pp_env extra_env pp_chdir chdir pp_cmd cmd;
    Ok ()

  let run_out ?extra_env cmd =
    Format.printf "Run_out: %a%a\n" pp_env extra_env pp_cmd cmd;
    Format.kasprintf Rresult.R.ok "$(%a%a)" pp_env extra_env pp_cmd cmd
end

let dry_run =
  let open Dry_run in
  { run; run_out }

let run_out t ?extra_env cmd =
  (t.run_out ?extra_env cmd
    : (_, run_error) result
    :> (_, [> run_error ]) result)

let run t ?extra_env ?chdir cmd =
  (t.run ?extra_env ?chdir cmd
    : (_, run_error) result
    :> (_, [> run_error ]) result)
