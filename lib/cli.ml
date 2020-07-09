open! Import

type t =
  | Create of { source : Source.t; switch_name : Switch_name.t option }
  | Reinstall

let eval runner github_client = function
  | Create { source; switch_name } ->
      Op.create runner github_client source switch_name
  | Reinstall -> Op.reinstall runner

module Let_syntax = struct
  open Cmdliner.Term

  let ( let+ ) t f = const f $ t

  let ( and+ ) a b = const (fun x y -> (x, y)) $ a $ b
end

module Create = struct
  let source =
    let open Cmdliner.Arg in
    required
      (pos 0 (some string) None
         (info ~doc:"Where to fetch the compiler." ~docv:"SOURCE" []))

  let switch_name =
    let open Cmdliner.Arg in
    let conv = conv (Switch_name.parse, Switch_name.pp) in
    value
      (opt (some conv) None
         (info ~docv:"SWITCH_NAME"
            ~doc:
              "Use this name for the switch. If omitted, a name is inferred \
               from the source."
            [ "switch" ]))

  let man =
    [
      `S Cmdliner.Manpage.s_description;
      `P "There are several ways to specify where to find a compiler:";
      `I ("Github branch", "user/repo:branch");
      `I
        ( "Github branch (short form)",
          "user:branch (repo defaults to \"ocaml\")" );
      `I ("Github pull request", "user/repo#number");
      `I
        ( "Github pull request (short form)",
          "#number (repo defaults to \"ocaml/ocaml\")" );
      `I ("Directory name", ".");
    ]

  let term =
    let open Let_syntax in
    let+ source = source and+ switch_name = switch_name in
    Create { source = Source.parse source; switch_name }

  let info =
    Cmdliner.Term.info ~man ~doc:"Create a switch from a compiler source"
      "create"

  let command = (term, info)
end

module Reinstall = struct
  let term =
    let open Cmdliner.Term in
    const Reinstall

  let info =
    let open Cmdliner.Term in
    info ~doc:"Reinstall the compiler" "reinstall"

  let command = (term, info)
end

let default =
  let open Cmdliner.Term in
  (ret (pure (`Help (`Auto, None))), info "opam-compiler")

let main () =
  let result =
    Cmdliner.Term.eval_choice default [ Create.command; Reinstall.command ]
  in
  ( match result with
  | `Ok op ->
      eval Runner.real Github_client.real op |> Rresult.R.failwith_error_msg
  | `Version -> ()
  | `Help -> ()
  | `Error _ -> () );
  Cmdliner.Term.exit result
