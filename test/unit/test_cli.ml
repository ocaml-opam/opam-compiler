open Opam_compiler

let msg = Alcotest.testable Rresult.R.pp_msg ( = )

let eval_create_tests =
  let branch = { Branch.user = "USER"; repo = "REPO"; branch = "BRANCH" } in
  let source = Source.Github_branch branch in
  let test name ~create_rvs ~remove_rv ~expected ~expected_calls =
    ( name,
      `Quick,
      fun () ->
        let create_rvs = ref create_rvs in
        let calls = Call_recorder.create () in
        let run_command cmd =
          Call_recorder.record calls cmd;
          let parts = Bos.Cmd.to_list cmd in
          if List.mem "remove" parts then remove_rv
          else if List.mem "create" parts then (
            match !create_rvs with
            | [] -> assert false
            | h :: t ->
                create_rvs := t;
                h )
          else Ok 0
        in
        let switch_manager =
          { Helpers.switch_manager_fail_all with run_command }
        in
        let github_client = Helpers.github_client_fail_all in
        let got = Cli.eval (Create source) switch_manager github_client in
        Alcotest.check Alcotest.(result unit msg) __LOC__ expected got;
        Call_recorder.check calls (module Bos.Cmd) __LOC__ expected_calls )
  in
  let create_call =
    Bos.Cmd.(
      v "opam" % "switch" % "create" % "USER-REPO-BRANCH" % "--empty"
      % "--description" % "[opam-compiler] USER/REPO:BRANCH")
  in
  let remove_call =
    Bos.Cmd.(v "opam" % "switch" % "remove" % "USER-REPO-BRANCH")
  in
  let pin_add_call =
    Bos.Cmd.(
      v "opam" % "pin" % "add" % "--switch" % "USER-REPO-BRANCH" % "--yes"
      % "ocaml-variants" % "git+https://github.com/USER/REPO#BRANCH")
  in
  [
    test "everything ok" ~create_rvs:[ Ok 0 ] ~remove_rv:(Ok 0)
      ~expected:(Ok ())
      ~expected_calls:[ create_call; pin_add_call ];
    test "first create fails"
      ~create_rvs:[ Error `Unknown ]
      ~remove_rv:(Ok 0)
      ~expected:(Error (`Msg "Cannot create switch"))
      ~expected_calls:[ create_call ];
    test "switch exists, rest ok" ~create_rvs:[ Ok 2; Ok 0 ] ~remove_rv:(Ok 0)
      ~expected:(Ok ())
      ~expected_calls:[ create_call; remove_call; create_call; pin_add_call ];
    test "switch exists, remove fails" ~create_rvs:[ Ok 2; Ok 0 ]
      ~remove_rv:(Error `Unknown)
      ~expected:(Error (`Msg "Cannot create switch"))
      ~expected_calls:[ create_call; remove_call ];
    test "switch exists, remove ok, create fails"
      ~create_rvs:[ Ok 2; Error `Unknown ]
      ~remove_rv:(Error `Unknown)
      ~expected:(Error (`Msg "Cannot create switch"))
      ~expected_calls:[ create_call; remove_call ];
    test "switch exists, remove ok, switch still exists"
      ~create_rvs:[ Ok 2; Ok 2 ]
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
          Call_recorder.record recorder cmd;
          Ok 0
        in
        let run_out cmd = Ok ("$(" ^ Bos.Cmd.to_string cmd ^ ")") in
        let switch_manager = { Switch_manager.run_command; run_out } in
        let github_client = Helpers.github_client_fail_all in
        let expected = Ok () in
        let got = Cli.eval Reinstall switch_manager github_client in
        Alcotest.check Alcotest.(result unit msg) __LOC__ expected got;
        Call_recorder.check recorder
          (module Bos.Cmd)
          __LOC__
          Bos.Cmd.
            [
              v "./configure" % "--prefix" % "$('opam' 'config' 'var' 'prefix')";
              v "make";
              v "make" % "install";
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
          Call_recorder.record recorder cmd;
          Ok 0
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
          (module Bos.Cmd)
          __LOC__
          [
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
