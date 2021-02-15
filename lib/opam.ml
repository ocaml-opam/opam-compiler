open! Import

type spec = A of string | L of spec list | Set_env of string * string

let add_env env kv = Some (kv :: Option.value env ~default:[])

let rec add_spec (cmd, env) = function
  | A s -> (Bos.Cmd.(cmd % s), env)
  | L l -> add_spec_list (cmd, env) l
  | Set_env (k, v) -> (cmd, add_env env (k, v))

and add_spec_list cmd l = List.fold_left add_spec cmd l

let opam = Bos.Cmd.v "opam"

let opam_cmd l = add_spec_list (opam, None) l

let run_opam runner args =
  let cmd, extra_env = opam_cmd args in
  Runner.run ?extra_env runner cmd

let ocaml_variants = A "ocaml-variants"

let create runner ~name ~description =
  run_opam runner
    [
      A "switch";
      A "create";
      A (Switch_name.to_string name);
      A "--empty";
      A "--description";
      A description;
    ]

let switch name = L [ A "--switch"; A (Switch_name.to_string name) ]

let pin_add runner ~name url ~configure_command =
  let cmd_base =
    [ A "pin"; A "add"; switch name; A "--yes"; ocaml_variants; A url ]
  in
  let cmd_rest =
    match configure_command with
    | None -> []
    | Some configure_command ->
        let opam_quote s = Printf.sprintf {|"%s"|} s in
        let configure_in_opam_format =
          configure_command |> Bos.Cmd.to_list |> List.map opam_quote
          |> String.concat " "
        in
        let sed_command =
          Printf.sprintf {|sed -i -e 's#"./configure"#%s#g'|}
            configure_in_opam_format
        in
        [ A "--edit"; Set_env ("OPAMEDITOR", sed_command) ]
  in
  let cmd = cmd_base @ cmd_rest in
  run_opam runner cmd

let update runner ~name =
  run_opam runner [ A "update"; switch name; ocaml_variants ]

let reinstall_configure runner ~configure_command =
  let open Let_syntax.Result in
  let prefix_cmd = Bos.Cmd.(opam % "config" % "var" % "prefix") in
  let* prefix = Runner.run_out runner prefix_cmd in
  let base_command =
    Option.value configure_command ~default:Bos.Cmd.(v "./configure")
  in
  let command = Bos.Cmd.(base_command % "--prefix" % prefix) in
  Runner.run runner command

let reinstall_compiler runner ~configure_command =
  let open Let_syntax.Result in
  let make = Bos.Cmd.(v "make") in
  let make_install = Bos.Cmd.(v "make" % "install") in
  let* () = reinstall_configure runner ~configure_command in
  let* () = Runner.run runner make in
  Runner.run runner make_install

let reinstall_packages runner =
  run_opam runner
    [ A "reinstall"; A "--assume-built"; A "--working-dir"; ocaml_variants ]
