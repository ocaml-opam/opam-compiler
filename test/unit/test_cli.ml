open Opam_compiler

let msg = Alcotest.testable Rresult.R.pp_msg ( = )

module Call = struct
  type t =
    | Create of { name : Switch_name.t; description : string }
    | Run of Bos.Cmd.t

  let pp ppf = function
    | Create { name; description } ->
        Format.fprintf ppf "Create { name = %a; description = %S }"
          Switch_name.pp name description
    | Run cmd -> Format.fprintf ppf "Run %a" Bos.Cmd.pp cmd

  let equal = ( = )
end

let eval_create_tests =
  let branch = { Branch.user = "USER"; repo = "REPO"; branch = "BRANCH" } in
  let source = Source.Github_branch branch in
  let test name ~create_rvs ~remove_rv ~expected ~expected_calls =
    ( name,
      `Quick,
      fun () ->
        let create_rvs = ref create_rvs in
        let calls = Call_recorder.create () in
        let create ~name ~description =
          Call_recorder.record calls (Call.Create { name; description });
          match !create_rvs with
          | [] -> assert false
          | h :: t ->
              create_rvs := t;
              h
        in
        let run_command cmd =
          Call_recorder.record calls (Run cmd);
          if List.mem "remove" (Bos.Cmd.to_list cmd) then remove_rv else Ok ()
        in
        let switch_manager =
          { Helpers.switch_manager_fail_all with create; run_command }
        in
        let github_client = Helpers.github_client_fail_all in
        let got = Cli.eval (Create source) switch_manager github_client in
        Alcotest.check Alcotest.(result unit msg) __LOC__ expected got;
        Call_recorder.check calls (module Call) __LOC__ expected_calls )
  in
  let switch_name = Switch_name.of_string_exn "USER-REPO-BRANCH" in
  let create_call =
    Call.Create
      { name = switch_name; description = Source.switch_description source }
  in
  let remove_call =
    Call.Run Bos.Cmd.(v "opam" % "switch" % "remove" % "USER-REPO-BRANCH")
  in
  let pin_add_call =
    Call.Run
      Bos.Cmd.(
        v "opam" % "pin" % "add" % "--switch" % "USER-REPO-BRANCH" % "--yes"
        % "ocaml-variants" % "git+https://github.com/USER/REPO#BRANCH")
  in
  [
    test "everything ok" ~create_rvs:[ Ok () ] ~remove_rv:(Ok ())
      ~expected:(Ok ())
      ~expected_calls:[ create_call; pin_add_call ];
    test "first create fails"
      ~create_rvs:[ Error `Unknown ]
      ~remove_rv:(Ok ())
      ~expected:(Error (`Msg "Cannot create switch"))
      ~expected_calls:[ create_call ];
    test "switch exists, rest ok"
      ~create_rvs:[ Error `Switch_exists; Ok () ]
      ~remove_rv:(Ok ()) ~expected:(Ok ())
      ~expected_calls:[ create_call; remove_call; create_call; pin_add_call ];
    test "switch exists, remove fails"
      ~create_rvs:[ Error `Switch_exists; Ok () ]
      ~remove_rv:(Error `Unknown)
      ~expected:(Error (`Msg "Cannot create switch"))
      ~expected_calls:[ create_call; remove_call ];
    test "switch exists, remove ok, create fails"
      ~create_rvs:[ Error `Switch_exists; Error `Unknown ]
      ~remove_rv:(Error `Unknown)
      ~expected:(Error (`Msg "Cannot create switch"))
      ~expected_calls:[ create_call; remove_call ];
    test "switch exists, remove ok, switch still exists"
      ~create_rvs:[ Error `Switch_exists; Error `Switch_exists ]
      ~remove_rv:(Error `Unknown)
      ~expected:(Error (`Msg "Cannot create switch"))
      ~expected_calls:[ create_call; remove_call ];
  ]

let eval_reinstall_tests =
  [
    ( "reinstall",
      `Quick,
      fun () ->
        let recorder = Call_recorder.create () in
        let run_command cmd =
          Call_recorder.record recorder (Call.Run cmd);
          Ok ()
        in
        let run_out cmd = Ok ("$(" ^ Bos.Cmd.to_string cmd ^ ")") in
        let switch_manager =
          { Helpers.switch_manager_fail_all with run_command; run_out }
        in
        let github_client = Helpers.github_client_fail_all in
        let expected = Ok () in
        let got = Cli.eval Reinstall switch_manager github_client in
        Alcotest.check Alcotest.(result unit msg) __LOC__ expected got;
        Call_recorder.check recorder
          (module Call)
          __LOC__
          Bos.Cmd.
            [
              Run
                ( v "./configure" % "--prefix"
                % "$('opam' 'config' 'var' 'prefix')" );
              Run (v "make");
              Run (v "make" % "install");
            ] );
  ]

let eval_update_tests =
  [
    ( "update",
      `Quick,
      fun () ->
        let recorder = Call_recorder.create () in
        let github_client = Helpers.github_client_fail_all in
        let run_command cmd =
          Call_recorder.record recorder (Call.Run cmd);
          Ok ()
        in
        let switch_manager =
          { Helpers.switch_manager_fail_all with run_command }
        in
        let branch =
          { Branch.user = "USER"; repo = "REPO"; branch = "BRANCH" }
        in
        let source = Source.Github_branch branch in
        let got = Cli.eval (Update source) switch_manager github_client in
        let expected = Ok () in
        Alcotest.check Alcotest.(result unit msg) __LOC__ expected got;
        Call_recorder.check recorder
          (module Call)
          __LOC__
          [
            Run
              Bos.Cmd.(
                v "opam" % "update" % "--switch" % "USER-REPO-BRANCH"
                % "ocaml-variants");
          ] );
  ]

let tests =
  [
    ("Cli eval create", eval_create_tests);
    ("Cli eval reinstall", eval_reinstall_tests);
    ("Cli eval update", eval_update_tests);
  ]
