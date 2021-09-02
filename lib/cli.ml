open! Import

type t =
  | Create of {
      source : Source.t;
      switch_name : Switch_name.t option;
      configure_command : Bos.Cmd.t option;
      runner : Runner.t;
      github_client : Github_client.t;
    }
  | Configure of { runner : Runner.t; args : string list }
  | Install of { runner : Runner.t }

let eval = function
  | Create { source; switch_name; configure_command; runner; github_client } ->
      Op.create runner github_client source switch_name ~configure_command
  | Configure { runner; args } -> Op.configure runner args
  | Install { runner } -> Op.install runner

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

let feature_args_opt =
  let open Let_syntax.Cmdliner in
  let+ with_ = with_ in
  let ocaml_version = Ocaml_version.Releases.latest in
  Option.map
    (List.map (Ocaml_version.Configure_options.to_configure_flag ocaml_version))
    with_

let configure_command =
  let open Let_syntax.Cmdliner in
  let use_command cmd = `Ok (Some cmd) in
  let default = `Ok None in
  let error m = `Error (false, m) in
  let ret_term =
    let+ explicit = configure_command_explicit
    and+ feature_args_opt = feature_args_opt in
    match (explicit, feature_args_opt) with
    | Some e, None -> use_command e
    | None, None -> default
    | None, Some opts -> use_command Bos.Cmd.(v "./configure" %% of_list opts)
    | Some _, Some _ ->
        error "--configure-command and --with cannot be passed together."
  in
  Cmdliner.Term.ret ret_term

let dry_run =
  let open Cmdliner.Arg in
  let info =
    info
      ~doc:
        "Do not perform external commands. Print them and continue as if they \
         worked."
      [ "dry-run" ]
  in
  value (flag info)

let runner =
  let open Let_syntax.Cmdliner in
  let+ dry_run = dry_run in
  if dry_run then Runner.dry_run else Runner.real

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

  let github_client =
    let open Let_syntax.Cmdliner in
    let+ dry_run = dry_run in
    if dry_run then Github_client.dry_run else Github_client.real

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
    ]

  let term =
    let open Let_syntax.Cmdliner in
    let+ { Source_with_original.source; _ } = source
    and+ switch_name = switch_name
    and+ configure_command = configure_command
    and+ runner = runner
    and+ github_client = github_client in
    Create { source; switch_name; configure_command; runner; github_client }

  let info =
    Cmdliner.Term.info ~man ~doc:"Create a switch from a compiler source"
      "create"

  let command = (term, info)
end

module Configure = struct
  let configure_args =
    let open Cmdliner.Arg in
    value & pos_all string []
    & info ~docv:"CONFIGURE_ARGUMENT"
        ~doc:"Positional arguments are passed verbatim to ./configure." []

  let args =
    let open Let_syntax.Cmdliner in
    let+ configure_args = configure_args
    and+ feature_args_opt = feature_args_opt in
    let feature_args = Option.value feature_args_opt ~default:[] in
    feature_args @ configure_args

  let term =
    let open Let_syntax.Cmdliner in
    let+ runner = runner and+ args = args in
    Configure { runner; args }

  let info = Cmdliner.Term.info ~doc:"Run ./configure command" "configure"

  let command = (term, info)
end

module Install = struct
  let term =
    let open Let_syntax.Cmdliner in
    let+ runner = runner in
    Install { runner }

  let info = Cmdliner.Term.info ~doc:"Run make install" "install"

  let command = (term, info)
end

let default =
  let open Cmdliner.Term in
  (ret (pure (`Help (`Auto, None))), info "opam-compiler")

let map_result f = function
  | `Ok x -> `Ok (f x)
  | (`Version | `Help | `Error _) as r -> r

let interpret_result =
  map_result (fun op ->
      match eval op with
      | Ok () -> 0
      | Error (`Msg msg) ->
          print_endline msg;
          2)

let main () =
  let result =
    Cmdliner.Term.eval_choice default
      [ Create.command; Configure.command; Install.command ]
  in
  result |> interpret_result |> Cmdliner.Term.exit_status
