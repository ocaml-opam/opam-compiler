open Opam_compiler
open! Import

let pp_option pp ppf = function
  | None -> Format.fprintf ppf "None"
  | Some x -> Format.fprintf ppf "Some %a" pp x

let () =
  let open Let_syntax.Result in
  let runner = Runner.real in
  match Sys.argv with
  | [| _ |] -> ()
  | [| _; "create"; name; description |] ->
      (let* name = Switch_name.parse name in
       translate_error "create" (Opam.create runner ~name ~description))
      |> Rresult.R.failwith_error_msg
  | [| _; "remove"; name |] ->
      (let* name = Switch_name.parse name in
       translate_error "remove" (Opam.remove_switch runner ~name))
      |> Rresult.R.failwith_error_msg
  | [| _; "compiler-sources"; name |] ->
      (let* name = Switch_name.parse name in
       let+ path =
         translate_error "compiler-sources"
           (Opam.get_compiler_sources runner ~name)
       in
       Format.printf "compiler-sources: %a\n" (pp_option Fpath.pp) path)
      |> Rresult.R.failwith_error_msg
  | [| _; "set-compiler-sources"; name; value_s |] ->
      (let* name = Switch_name.parse name in
       let* value = Fpath.of_string value_s in
       translate_error "set-compiler-sources"
         (Opam.set_compiler_sources runner ~name value))
      |> Rresult.R.failwith_error_msg
  | _ -> assert false
