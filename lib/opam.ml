open! Import

type spec = A of string | L of spec list | Set_env of string * string

let add_env env kv = Some (kv :: Option.value env ~default:[])

let rec add_spec (cmd, env) = function
  | A s -> (Bos.Cmd.(cmd % s), env)
  | L l -> add_spec_list (cmd, env) l
  | Set_env (k, v) -> (cmd, add_env env (k, v))

and add_spec_list cmd l = List.fold_left add_spec cmd l

let opam_cmd l = add_spec_list (Bos.Cmd.v "opam", Some [ ("OPAMCLI", "2.0") ]) l

let run_opam runner args =
  let cmd, extra_env = opam_cmd args in
  Runner.run ?extra_env runner cmd

let run_out_opam runner args =
  let cmd, extra_env = opam_cmd args in
  Runner.run_out ?extra_env runner cmd

let ocaml_variants = A "ocaml-variants"

let create runner name ~description =
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

let pin_add runner name url ~configure_command =
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

let set_base runner name =
  run_opam runner [ A "switch"; A "set-base"; switch name; ocaml_variants ]

let update runner name =
  run_opam runner [ A "update"; switch name; ocaml_variants ]

let reinstall_configure runner ~configure_command ~compiler_sources =
  let open Let_syntax.Result in
  let* prefix = run_out_opam runner [ A "config"; A "var"; A "prefix" ] in
  let base_command =
    Option.value configure_command ~default:Bos.Cmd.(v "./configure")
  in
  let command = Bos.Cmd.(base_command % "--prefix" % prefix) in
  Runner.run ~chdir:compiler_sources runner command

let reinstall_compiler runner ~compiler_sources ~configure_command =
  let open Let_syntax.Result in
  let make = Bos.Cmd.(v "make") in
  let make_install = Bos.Cmd.(v "make" % "install") in
  let* () = reinstall_configure runner ~compiler_sources ~configure_command in
  let* () = Runner.run ~chdir:compiler_sources runner make in
  Runner.run ~chdir:compiler_sources runner make_install

let reinstall_packages runner =
  run_opam runner
    [ A "reinstall"; A "--assume-built"; A "--working-dir"; ocaml_variants ]

let remove_switch runner name =
  run_opam runner
    [ A "switch"; A "remove"; A "--yes"; A (Switch_name.to_string name) ]

module Var = struct
  let prefix = "compiler-"

  let to_string var = prefix ^ var

  let get runner name ~variable =
    let open Let_syntax.Result in
    let pattern = Format.sprintf "%%{%s}%%" (to_string variable) in
    let switch =
      match name with Some name -> L [ switch name ] | None -> L []
    in
    let+ output =
      run_out_opam runner [ A "config"; switch; A "expand"; A pattern ]
    in
    if String.equal output "" then None else Some output

  let set runner name ~variable ~value =
    run_opam runner
      [ A "config"; switch name; A "set"; A (to_string variable); A value ]
end

let get_variable = Var.get

let set_variable = Var.set
