open! Import

type t =
  | Create of {
      source : Source.t;
      switch_name : Switch_name.t option;
      configure_command : Bos.Cmd.t option;
      runner : Runner.t;
      github_client : Github_client.t;
    }

let eval = function
  | Create { source; switch_name; configure_command; runner; github_client } ->
      Op.create runner github_client source switch_name ~configure_command

let configure_command_explicit =
  let open Cmdliner.Arg in
  let conv = conv (Bos.Cmd.of_string, Bos.Cmd.pp) in
  let info =
    info ~doc:"Use this instead of \"./configure\"." ~docv:"COMMAND"
      [ "configure-command" ]
  in
  value (opt (some conv) None info)

let with_ =
  let open Cmdliner.Arg in
  let parse s =
    match Ocaml_version.Configure_options.of_string s with
    | Some opt -> Ok opt
    | None -> Rresult.R.error_msg "Unknown variant."
  in
  let pp ppf opt =
    Format.fprintf ppf "%s" (Ocaml_version.Configure_options.to_string opt)
  in
  let conv = conv (parse, pp) in
  let info =
    info
      ~doc:
        "Create a switch with this set of features. For example --with \
         flambda,nnp will create a switch with the flambda and \
         no-naked-pointers features enabled."
      ~docv:"FEATURES" [ "with" ]
  in
  value (opt (some (list conv)) None info)

let configure_command =
  let open Let_syntax.Cmdliner in
  let use_command cmd = `Ok (Some cmd) in
  let default = `Ok None in
  let error m = `Error (false, m) in
  let ret_term =
    let+ explicit = configure_command_explicit and+ with_ = with_ in
    match (explicit, with_) with
    | Some e, None -> use_command e
    | None, None -> default
    | None, Some opts ->
        let ocaml_version = Ocaml_version.Releases.latest in
        let add_opt cmd opt =
          Bos.Cmd.add_arg cmd
            (Ocaml_version.Configure_options.to_configure_flag ocaml_version opt)
        in
        let configure = Bos.Cmd.v "./configure" in
        use_command (List.fold_left add_opt configure opts)
    | Some _, Some _ ->
        error "--configure-command and --with cannot be passed together."
  in
  Cmdliner.Term.ret ret_term

module Create = struct
  module Source_with_original = struct
    type t = { source : Source.t; original : string }

    let of_string s =
      match Source.parse s with
      | Ok source -> Ok { source; original = s }
      | Error `Unknown -> Rresult.R.error_msgf "Invalid source: %S" s

    let pp ppf { original; _ } = Format.pp_print_string ppf original
    let conv = Cmdliner.Arg.conv (of_string, pp)
  end

  let source =
    let open Cmdliner.Arg in
    required
      (pos 0
         (some Source_with_original.conv)
         None
         (info ~doc:"Where to fetch the compiler." ~docv:"SOURCE" []))

  let switch_name =
    let open Cmdliner.Arg in
    let conv = conv (Switch_name.parse, Switch_name.pp) in
    value
      (opt (some conv) None
         (info ~docv:"SWITCH_NAME"
            ~doc:
              "Use this name for the switch. If omitted, a name is inferred \
               from the source. This name is used as is by opam, so passing \
               \".\" will create a local switch in the current directory."
            [ "switch" ]))

  let dry_run =
    let open Cmdliner.Arg in
    let info =
      info
        ~doc:
          "Do not perform external commands. Print them and continue as if \
           they worked."
        [ "dry-run" ]
    in
    value (flag info)

  let clients =
    let open Let_syntax.Cmdliner in
    let+ dry_run = dry_run in
    let runner = if dry_run then Runner.dry_run else Runner.real in
    let github_client =
      if dry_run then Github_client.dry_run else Github_client.real
    in
    (runner, github_client)

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
      `I ("Github url", "https://github.com/user/repo/pull/1");
    ]

  let term =
    let open Let_syntax.Cmdliner in
    let+ { Source_with_original.source; _ } = source
    and+ switch_name = switch_name
    and+ configure_command = configure_command
    and+ runner, github_client = clients in
    let op =
      Create { source; switch_name; configure_command; runner; github_client }
    in
    eval op |> Rresult.R.failwith_error_msg

  let info =
    Cmdliner.Cmd.info ~man ~doc:"Create a switch from a compiler source"
      "create"

  let command = Cmdliner.Cmd.v info term
end

let info = Cmdliner.Cmd.info "opam-compiler"
let group = Cmdliner.Cmd.group info [ Create.command ]
let main () = Cmdliner.Cmd.eval group |> Stdlib.exit
