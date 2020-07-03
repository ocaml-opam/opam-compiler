open! Import

type t =
  | Create of { source : Source.t; switch_name : Switch_name.t option }
  | Reinstall

let eval runner github_client = function
  | Create { source; switch_name } ->
      Op.create runner github_client source switch_name
  | Reinstall -> Op.reinstall runner

let source =
  let open Cmdliner.Arg in
  required (pos 0 (some string) None (info []))

let switch_name =
  let open Cmdliner.Arg in
  let conv = conv (Switch_name.parse, Switch_name.pp) in
  value (opt (some conv) None (info [ "switch" ]))

module Let_syntax = struct
  open Cmdliner.Term

  let ( let+ ) t f = const f $ t

  let ( and+ ) a b = const (fun x y -> (x, y)) $ a $ b
end

let create =
  let open Let_syntax in
  let+ source = source and+ switch_name = switch_name in
  Create { source = Source.parse source; switch_name }

let reinstall =
  let open Cmdliner.Term in
  const Reinstall

let default =
  let open Cmdliner.Term in
  (ret (pure (`Help (`Auto, None))), info "opam-compiler")

let main () =
  let result =
    let open Cmdliner.Term in
    eval_choice default
      [ (create, info "create"); (reinstall, info "reinstall") ]
  in
  ( match result with
  | `Ok op ->
      eval Runner.real Github_client.real op |> Rresult.R.failwith_error_msg
  | `Version -> ()
  | `Help -> ()
  | `Error _ -> () );
  Cmdliner.Term.exit result
