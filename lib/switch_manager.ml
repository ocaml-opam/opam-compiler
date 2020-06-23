type t = {
  create :
    name:Switch_name.t ->
    description:string ->
    (unit, [ `Unknown | `Switch_exists ]) result;
  update : name:Switch_name.t -> (unit, [ `Unknown ]) result;
  info : name:Switch_name.t -> (string, [ `Unknown ]) result;
  reinstall : unit -> (unit, [ `Unknown ]) result;
  run_command : Bos.Cmd.t -> (unit, [ `Unknown ]) result;
}

let opam = Bos.Cmd.v "opam"

let ocaml_variants = "ocaml-variants"

module Opam = struct
  let create ~name ~description =
    let create_cmd =
      let open Bos.Cmd in
      opam % "switch" % "create" % Switch_name.to_string name % "--empty"
      % "--description" % description
    in
    Bos.OS.Cmd.run_status create_cmd |> Rresult.R.failwith_error_msg |> function
    | `Exited 0 -> Ok ()
    | `Exited 2 -> Error `Switch_exists
    | _ -> Error `Unknown

  let update ~name =
    (let open Bos.Cmd in
    opam % "update" % "--switch" % Switch_name.to_string name % ocaml_variants)
    |> Bos.OS.Cmd.run
    |> Rresult.R.reword_error (fun _ -> `Unknown)

  let info ~name =
    (let open Bos.Cmd in
    opam % "show" % ocaml_variants % "--switch" % Switch_name.to_string name
    % "-fsource-hash")
    |> Bos.OS.Cmd.run_out |> Bos.OS.Cmd.to_string
    |> Rresult.R.reword_error (fun _ -> `Unknown)

  let reinstall () =
    (let open Rresult.R in
    let prefix_cmd = Bos.Cmd.(opam % "config" % "var" % "prefix") in
    Bos.OS.Cmd.run_out prefix_cmd |> Bos.OS.Cmd.to_string >>= fun prefix ->
    let configure = Bos.Cmd.(v "./configure" % "--prefix" % prefix) in
    let make = Bos.Cmd.(v "make") in
    let make_install = Bos.Cmd.(v "make" % "install") in
    Bos.OS.Cmd.run configure >>= fun () ->
    Bos.OS.Cmd.run make >>= fun () -> Bos.OS.Cmd.run make_install)
    |> Rresult.R.reword_error (fun _ -> `Unknown)

  let run_command cmd =
    Bos.OS.Cmd.run cmd |> Rresult.R.reword_error (fun _ -> `Unknown)
end

let real =
  let open Opam in
  { create; update; info; reinstall; run_command }

let create t = t.create

let remove t ~name =
  t.run_command
    (let open Bos.Cmd in
    opam % "switch" % "remove" % Switch_name.to_string name)

let pin_add t ~name url =
  t.run_command
    Bos.Cmd.(
      opam % "pin" % "add" % "--switch" % Switch_name.to_string name % "--yes"
      % ocaml_variants % url)

let update t = t.update

let info t = t.info

let reinstall t = t.reinstall ()

let create_from_scratch switch_manager ~name ~description =
  match create switch_manager ~name ~description with
  | Ok () -> Ok ()
  | Error `Switch_exists ->
      Rresult.R.bind (remove switch_manager ~name) (fun () ->
          create switch_manager ~name ~description
          |> Rresult.R.reword_error (fun _ -> `Unknown))
  | Error `Unknown as e -> e
