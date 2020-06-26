open Opam_compiler

let msg = Alcotest.testable Rresult.R.pp_msg ( = )

let eval_tests =
  let test name action ~expectations ~expected =
    Deferred.test_case
      ( name,
        `Quick,
        fun d ->
          let run_command =
            Mock.create d (module Bos.Cmd) __LOC__ expectations
          in
          let run_out cmd = Ok ("$(" ^ Bos.Cmd.to_string cmd ^ ")") in
          let runner = { Runner.run_command; run_out } in
          let github_client = Helpers.github_client_fail_all in
          let got = Cli.eval action runner github_client in
          Alcotest.check Alcotest.(result unit msg) __LOC__ expected got )
  in
  let create =
    Cli.Create
      (Github_branch { Branch.user = "USER"; repo = "REPO"; branch = "BRANCH" })
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
    test "create: everything ok" create
      ~expectations:
        [
          Mock.expect create_call ~and_return:(Ok 0);
          Mock.expect pin_add_call ~and_return:(Ok 0);
        ]
      ~expected:(Ok ());
    test "create: first create fails" create
      ~expectations:[ Mock.expect create_call ~and_return:(Error `Unknown) ]
      ~expected:(Error (`Msg "Cannot create switch"));
    test "create: switch exists, rest ok" create
      ~expectations:
        [
          Mock.expect create_call ~and_return:(Ok 2);
          Mock.expect remove_call ~and_return:(Ok 0);
          Mock.expect create_call ~and_return:(Ok 0);
          Mock.expect pin_add_call ~and_return:(Ok 0);
        ]
      ~expected:(Ok ());
    test "create: switch exists, remove fails" create
      ~expectations:
        [
          Mock.expect create_call ~and_return:(Ok 2);
          Mock.expect remove_call ~and_return:(Error `Unknown);
        ]
      ~expected:(Error (`Msg "Cannot create switch"));
    test "create: switch exists, remove ok, create fails" create
      ~expectations:
        [
          Mock.expect create_call ~and_return:(Ok 2);
          Mock.expect remove_call ~and_return:(Ok 0);
          Mock.expect create_call ~and_return:(Error `Unknown);
        ]
      ~expected:(Error (`Msg "Cannot create switch"));
    test "create: switch exists, remove ok, switch still exists" create
      ~expectations:
        [
          Mock.expect create_call ~and_return:(Ok 2);
          Mock.expect remove_call ~and_return:(Ok 0);
          Mock.expect create_call ~and_return:(Ok 2);
        ]
      ~expected:(Error (`Msg "Cannot create switch"));
    test "update"
      (Update
         (Github_branch
            { Branch.user = "USER"; repo = "REPO"; branch = "BRANCH" }))
      ~expectations:
        [
          Mock.expect
            Bos.Cmd.(
              v "opam" % "update" % "--switch" % "USER-REPO-BRANCH"
              % "ocaml-variants")
            ~and_return:(Ok 0);
        ]
      ~expected:(Ok ());
    test "reinstall" Reinstall
      ~expectations:
        Bos.Cmd.
          [
            Mock.expect
              ( v "./configure" % "--prefix"
              % "$('opam' 'config' 'var' 'prefix')" )
              ~and_return:(Ok 0);
            Mock.expect (v "make") ~and_return:(Ok 0);
            Mock.expect (v "make" % "install") ~and_return:(Ok 0);
          ]
      ~expected:(Ok ());
  ]

let tests = [ ("Cli eval", eval_tests) ]
