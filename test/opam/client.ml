open Opam_compiler
open! Import

let pp_option pp ppf = function
  | None -> Format.fprintf ppf "None"
  | Some x -> Format.fprintf ppf "Some %a" pp x

let pp_string ppf s = Format.fprintf ppf "%S" s

let () =
  let open Let_syntax.Result in
  let runner = Runner.real in
  match Sys.argv with
  | [| _ |] -> ()
  | [| _; "create"; name; description |] ->
      (let* name = Switch_name.parse name in
       translate_error "create" (Opam.create runner name ~description))
      |> Rresult.R.failwith_error_msg
  | [| _; "remove"; name |] ->
      (let* name = Switch_name.parse name in
       translate_error "remove" (Opam.remove_switch runner name))
      |> Rresult.R.failwith_error_msg
  | [| _; "get-var"; name; variable |] ->
      (let* name = Switch_name.parse name in
       let+ r =
         translate_error "get-var"
           (Opam.get_variable runner (Some name) ~variable)
       in
       Format.printf "get-var: %a\n" (pp_option pp_string) r)
      |> Rresult.R.failwith_error_msg
  | [| _; "set-var"; name; variable; value |] ->
      (let* name = Switch_name.parse name in
       translate_error "set-var"
         (Opam.set_variable runner name ~variable ~value))
      |> Rresult.R.failwith_error_msg
  | [| _; "reinstall-compiler"; compiler_sources_s |] ->
      (let* compiler_sources = Fpath.of_string compiler_sources_s in
       translate_error "reinstall-compiler"
         (Opam.reinstall_compiler runner ~compiler_sources
            ~configure_command:None))
      |> Rresult.R.failwith_error_msg
  | _ -> assert false
