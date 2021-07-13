open Opam_compiler
open! Import

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
  | _ -> assert false
