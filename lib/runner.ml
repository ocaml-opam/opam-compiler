open! Import

type t = {
  run_command :
    ?extra_env:(string * string) list -> Bos.Cmd.t -> (int, [ `Unknown ]) result;
  run_out : Bos.Cmd.t -> (string, [ `Unknown ]) result;
}

module Real = struct
  let get_env () =
    Bos.OS.Env.current () |> Rresult.R.reword_error (fun _ -> `Unknown)

  let run_raw env cmd =
    Bos.OS.Cmd.in_null |> Bos.OS.Cmd.run_io ?env cmd |> Bos.OS.Cmd.out_stdout
    |> Rresult.R.reword_error (fun _ -> `Unknown)

  let run_command ?extra_env cmd =
    let open Let_syntax.Result in
    let* env =
      match extra_env with
      | None -> Ok None
      | Some l ->
          let+ cur = get_env () in
          let seq = List.to_seq l in
          Some (Astring.String.Map.add_seq seq cur)
    in
    let* (), ((_ : Bos.OS.Cmd.run_info), status) = run_raw env cmd in
    match status with `Exited n -> Ok n | `Signaled _ -> Error `Unknown

  let run_out cmd =
    Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.to_string
    |> Rresult.R.reword_error (fun _ -> `Unknown)
end

let real =
  let open Real in
  { run_command; run_out }

let run_command t = t.run_command

let run_out t = t.run_out

let run ?extra_env t cmd =
  let open Let_syntax.Result in
  let* res = t.run_command ?extra_env cmd in
  match res with 0 -> Ok () | _ -> Error `Unknown
