open! Import

type t = {
  run_command : Bos.Cmd.t -> (int, [ `Unknown ]) result;
  run_out : Bos.Cmd.t -> (string, [ `Unknown ]) result;
}

module Real = struct
  let run_command cmd =
    match Bos.OS.Cmd.run_status cmd with
    | Ok (`Exited n) -> Ok n
    | Ok (`Signaled _) -> Error `Unknown
    | Error _ -> Error `Unknown

  let run_out cmd =
    Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.to_string
    |> Rresult.R.reword_error (fun _ -> `Unknown)
end

let real =
  let open Real in
  { run_command; run_out }

let run_command t = t.run_command

let run_out t = t.run_out

let run t cmd =
  let open Let_syntax.Result in
  let* res = t.run_command cmd in
  match res with 0 -> Ok () | _ -> Error `Unknown
