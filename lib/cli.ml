open! Import

type t = Create of Source.t | Update of Source.t | Reinstall

let eval runner github_client = function
  | Create s -> Op.create runner github_client s
  | Update s -> Op.update runner s
  | Reinstall -> Op.reinstall runner

let source =
  let open Cmdliner.Arg in
  required (pos 0 (some string) None (info []))

let create s = Create (Source.parse s)

let update s = Update (Source.parse s)

let create =
  let open Cmdliner.Term in
  (const create $ source, info "create")

let update =
  let open Cmdliner.Term in
  (const update $ source, info "update")

let reinstall =
  let open Cmdliner.Term in
  (const Reinstall, info "reinstall")

let default =
  let open Cmdliner.Term in
  (ret (pure (`Help (`Auto, None))), info "opam-compiler")

let main () =
  let result =
    Cmdliner.Term.eval_choice default [ create; update; reinstall ]
  in
  ( match result with
  | `Ok op ->
      eval Runner.real Github_client.real op |> Rresult.R.failwith_error_msg
  | `Version -> ()
  | `Help -> ()
  | `Error _ -> () );
  Cmdliner.Term.exit result
