type t = {
  run_command : Bos.Cmd.t -> (int, [ `Unknown ]) result;
  run_out : Bos.Cmd.t -> (string, [ `Unknown ]) result;
}

let opam = Bos.Cmd.v "opam"

let ocaml_variants = "ocaml-variants"

module Opam = struct
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
  let open Opam in
  { run_command; run_out }

let create t ~name ~description =
  let create_cmd =
    let open Bos.Cmd in
    opam % "switch" % "create" % Switch_name.to_string name % "--empty"
    % "--description" % description
  in
  match t.run_command create_cmd with
  | Ok 0 -> Ok ()
  | Ok 2 -> Error `Switch_exists
  | _ -> Error `Unknown

let run t cmd =
  let open Rresult.R in
  t.run_command cmd >>= function 0 -> Ok () | _ -> Error `Unknown

let remove t ~name =
  run t
    (let open Bos.Cmd in
    opam % "switch" % "remove" % Switch_name.to_string name)

let pin_add t ~name url =
  run t
    Bos.Cmd.(
      opam % "pin" % "add" % "--switch" % Switch_name.to_string name % "--yes"
      % ocaml_variants % url)

let update t ~name =
  run t
    (let open Bos.Cmd in
    opam % "update" % "--switch" % Switch_name.to_string name % ocaml_variants)

let reinstall t =
  let open Rresult.R in
  let prefix_cmd = Bos.Cmd.(opam % "config" % "var" % "prefix") in
  t.run_out prefix_cmd >>= fun prefix ->
  let configure = Bos.Cmd.(v "./configure" % "--prefix" % prefix) in
  let make = Bos.Cmd.(v "make") in
  let make_install = Bos.Cmd.(v "make" % "install") in
  run t configure >>= fun () ->
  run t make >>= fun () -> run t make_install

let create_from_scratch switch_manager ~name ~description =
  match create switch_manager ~name ~description with
  | Ok () -> Ok ()
  | Error `Switch_exists ->
      let open Rresult.R in
      remove switch_manager ~name >>= fun () ->
      create switch_manager ~name ~description
      |> Rresult.R.reword_error (fun _ -> `Unknown)
  | Error `Unknown as e -> e
