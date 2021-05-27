open Opam_compiler
open Import

let msg = Alcotest.testable Rresult.R.pp_msg ( = )

let run_mock loc expectations =
  let testable =
    Alcotest.(pair (module Bos.Cmd) (option (list (pair string string))))
  in
  let run_mock, check = Mock.create testable loc expectations in
  let run ?extra_env cmd = run_mock (cmd, extra_env) in
  (run, check)

let opam_cli_env = Some [ ("OPAMCLI", "2.0") ]

let create_tests =
  let test name ?switch_name ?configure_command expectations ~expected =
    ( name,
      `Quick,
      fun () ->
        let run, check = run_mock __LOC__ expectations in
        let runner = { Helpers.runner_fail_all with run } in
        let github_client = Helpers.github_client_fail_all in
        let source =
          Source.Github_branch
            { user = "USER"; repo = "REPO"; branch = "BRANCH" }
        in
        let got =
          Op.create runner github_client source switch_name ~configure_command
        in
        Alcotest.check Alcotest.(result unit msg) __LOC__ expected got;
        check () )
  in
  let create_cmd =
    Bos.Cmd.(
      v "opam" % "switch" % "create" % "USER-REPO-BRANCH" % "--empty"
      % "--description" % "[opam-compiler] USER/REPO:BRANCH")
  in
  let create_call = (create_cmd, opam_cli_env) in
  [
    test "create: create fails with unknown error"
      [ Mock.expect create_call ~and_return:(Error `Unknown) ]
      ~expected:(Error (`Msg "Cannot create switch"));
    test "create: when opam command fails"
      [
        Mock.expect create_call ~and_return:(Error (`Command_failed create_cmd));
        Mock.expect
          ( Bos.Cmd.(v "opam" % "switch" % "remove" % "USER-REPO-BRANCH"),
            opam_cli_env )
          ~and_return:(Ok ());
      ]
      ~expected:(Ok ());
  ]

let reinstall_tests =
  let test name mode configure_command expectations ~expected =
    ( name,
      `Quick,
      fun () ->
        let run, check = run_mock __LOC__ expectations in
        let run_out ?extra_env cmd =
          Format.kasprintf Rresult.R.ok "$(%a%a)" pp_env extra_env pp_cmd cmd
        in
        let runner = { Runner.run; run_out } in
        let got = Op.reinstall runner mode ~configure_command in
        Alcotest.check Alcotest.(result unit msg) __LOC__ expected got;
        check () )
  in
  [
    test "reinstall (quick)" Quick None
      Bos.Cmd.
        [
          Mock.expect
            ( v "./configure" % "--prefix"
              % "$(OPAMCLI=2.0 opam config var prefix)",
              None )
            ~and_return:(Ok ());
          Mock.expect (v "make", None) ~and_return:(Ok ());
          Mock.expect (v "make" % "install", None) ~and_return:(Ok ());
        ]
      ~expected:(Ok ());
    test "reinstall (full)" Full None
      Bos.Cmd.
        [
          Mock.expect
            ( v "./configure" % "--prefix"
              % "$(OPAMCLI=2.0 opam config var prefix)",
              None )
            ~and_return:(Ok ());
          Mock.expect (v "make", None) ~and_return:(Ok ());
          Mock.expect (v "make" % "install", None) ~and_return:(Ok ());
          Mock.expect
            ( v "opam" % "reinstall" % "--assume-built" % "--working-dir"
              % "ocaml-variants",
              opam_cli_env )
            ~and_return:(Ok ());
        ]
      ~expected:(Ok ());
    test "reinstall (different configure command)" Quick
      (Some Bos.Cmd.(v "./configure" % "--enable-something"))
      Bos.Cmd.
        [
          Mock.expect
            ( v "./configure" % "--enable-something" % "--prefix"
              % "$(OPAMCLI=2.0 opam config var prefix)",
              None )
            ~and_return:(Ok ());
          Mock.expect (v "make", None) ~and_return:(Ok ());
          Mock.expect (v "make" % "install", None) ~and_return:(Ok ());
        ]
      ~expected:(Ok ());
  ]

let tests = [ ("Op create", create_tests); ("Op reinstall", reinstall_tests) ]
