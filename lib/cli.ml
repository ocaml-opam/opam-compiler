open! Import

type t =
  | Create of {
      source : Source.t;
      switch_name : Switch_name.t option;
      configure_command : Bos.Cmd.t option;
    }
  | Reinstall of {
      mode : Op.reinstall_mode;
      configure_command : Bos.Cmd.t option;
    }

let eval runner github_client = function
  | Create { source; switch_name; configure_command } ->
      Op.create runner github_client source switch_name ~configure_command
  | Reinstall { mode; configure_command } ->
      Op.reinstall runner mode ~configure_command

let configure_command =
  let open Cmdliner.Arg in
  let conv = conv (Bos.Cmd.of_string, Bos.Cmd.pp) in
  value
    (opt (some conv) None
       (info ~doc:"Use this instead of \"./configure\"." ~docv:"COMMAND"
          [ "configure-command" ]))

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
    let open Let_syntax.Cmdliner in
    let+ source = source
    and+ switch_name = switch_name
    and+ configure_command = configure_command in
    Create { source = Source.parse source; switch_name; configure_command }

  let info =
    Cmdliner.Term.info ~man ~doc:"Create a switch from a compiler source"
      "create"

  let command = (term, info)
end

module Reinstall = struct
  let reinstall_mode =
    let open Cmdliner.Arg in
    value
      (vflag Op.Full
         [
           ( Full,
             info ~doc:"Perform a full reinstallation (default)." [ "full" ] );
           ( Quick,
             info ~doc:"Perform a quick reinstallation (unsafe)" [ "quick" ] );
         ])

  let term =
    let open Let_syntax.Cmdliner in
    let+ mode = reinstall_mode and+ configure_command = configure_command in
    Reinstall { mode; configure_command }

  let man =
    [
      `P "Reinstall the compiler will propagate the changes done to its source.";
      `P "There are two ways to reinstall:";
      `I
        ( "Full (default)",
          "Reinstall the compiler and all the packages in the switch. This can \
           be slow but is always safe." );
      `I
        ( "Quick (unsafe)",
          "Only reinstall the compiler. This is fast, but will break the \
           switch if the way it compiles is modified for example." );
    ]

  let info =
    let open Cmdliner.Term in
    info ~man ~doc:"Reinstall the compiler" "reinstall"

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
