open! Import

let opam = Bos.Cmd.v "opam"

let ocaml_variants = "ocaml-variants"

let create runner ~name ~description =
  let create_cmd =
    let open Bos.Cmd in
    opam % "switch" % "create" % Switch_name.to_string name % "--empty"
    % "--description" % description
  in
  match Runner.run_command runner create_cmd with
  | Ok 0 -> Ok ()
  | Ok 2 -> Error `Switch_exists
  | _ -> Error `Unknown

let remove runner ~name =
  Runner.run runner
    (let open Bos.Cmd in
    opam % "switch" % "remove" % Switch_name.to_string name)

let pin_add runner ~name url =
  Runner.run runner
    Bos.Cmd.(
      opam % "pin" % "add" % "--switch" % Switch_name.to_string name % "--yes"
      % ocaml_variants % url)

let update runner ~name =
  Runner.run runner
    (let open Bos.Cmd in
    opam % "update" % "--switch" % Switch_name.to_string name % ocaml_variants)

let reinstall_compiler runner =
  let open Let_syntax.Result in
  let prefix_cmd = Bos.Cmd.(opam % "config" % "var" % "prefix") in
  let* prefix = Runner.run_out runner prefix_cmd in
  let configure = Bos.Cmd.(v "./configure" % "--prefix" % prefix) in
  let make = Bos.Cmd.(v "make") in
  let make_install = Bos.Cmd.(v "make" % "install") in
  let* () = Runner.run runner configure in
  let* () = Runner.run runner make in
  Runner.run runner make_install

let reinstall_packages runner =
  Runner.run runner
    Bos.Cmd.(
      v "opam" % "reinstall" % "--assume-built" % "--working-dir"
      % "ocaml-variants")

let create_from_scratch runner ~name ~description =
  match create runner ~name ~description with
  | Ok () -> Ok ()
  | Error `Switch_exists ->
      let open Let_syntax.Result in
      let* () = remove runner ~name in
      create runner ~name ~description
      |> Rresult.R.reword_error (fun _ -> `Unknown)
  | Error `Unknown as e -> e
