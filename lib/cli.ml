open! Import

let source =
  let open Cmdliner.Arg in
  required (pos 0 (some string) None (info []))

let op_create s = Op.Create (Source.parse s)

let op_update s = Op.Update (Source.parse s)

let create =
  let open Cmdliner.Term in
  (const op_create $ source, info "create")

let update =
  let open Cmdliner.Term in
  (const op_update $ source, info "update")

let reinstall =
  let open Cmdliner.Term in
  (const Op.Reinstall, info "reinstall")

let default =
  let open Cmdliner.Term in
  (ret (pure (`Help (`Auto, None))), info "opam-compiler")

let main () =
  let result =
    Cmdliner.Term.eval_choice default [ create; update; reinstall ]
  in
  ( match result with
  | `Ok op ->
      Op.eval op Runner.real Github_client.real |> Rresult.R.failwith_error_msg
  | `Version -> ()
  | `Help -> ()
  | `Error _ -> () );
  Cmdliner.Term.exit result
