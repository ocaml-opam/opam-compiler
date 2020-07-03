open Opam_compiler

let msg = Alcotest.testable Rresult.R.pp_msg ( = )

let create_tests =
  let test name source expectations ~expected =
    Deferred.test_case
      ( name,
        `Quick,
        fun d ->
          let run_command =
            Mock.create d (module Bos.Cmd) __LOC__ expectations
          in
          let runner = { Helpers.runner_fail_all with run_command } in
          let github_client = Helpers.github_client_fail_all in
          let got = Op.create runner github_client source in
          Alcotest.check Alcotest.(result unit msg) __LOC__ expected got )
  in
  let source =
    Source.Github_branch
      { Branch.user = "USER"; repo = "REPO"; branch = "BRANCH" }
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
    test "create: everything ok" source
      [
        Mock.expect create_call ~and_return:(Ok 0);
        Mock.expect pin_add_call ~and_return:(Ok 0);
      ]
      ~expected:(Ok ());
    test "create: first create fails" source
      [ Mock.expect create_call ~and_return:(Error `Unknown) ]
      ~expected:(Error (`Msg "Cannot create switch"));
    test "create: switch exists, rest ok" source
      [
        Mock.expect create_call ~and_return:(Ok 2);
        Mock.expect remove_call ~and_return:(Ok 0);
        Mock.expect create_call ~and_return:(Ok 0);
        Mock.expect pin_add_call ~and_return:(Ok 0);
      ]
      ~expected:(Ok ());
    test "create: switch exists, remove fails" source
      [
        Mock.expect create_call ~and_return:(Ok 2);
        Mock.expect remove_call ~and_return:(Error `Unknown);
      ]
      ~expected:(Error (`Msg "Cannot create switch"));
    test "create: switch exists, remove ok, create fails" source
      [
        Mock.expect create_call ~and_return:(Ok 2);
        Mock.expect remove_call ~and_return:(Ok 0);
        Mock.expect create_call ~and_return:(Error `Unknown);
      ]
      ~expected:(Error (`Msg "Cannot create switch"));
    test "create: switch exists, remove ok, switch still exists" source
      [
        Mock.expect create_call ~and_return:(Ok 2);
        Mock.expect remove_call ~and_return:(Ok 0);
        Mock.expect create_call ~and_return:(Ok 2);
      ]
      ~expected:(Error (`Msg "Cannot create switch"));
  ]

let update_tests =
  let test name source expectations ~expected =
    Deferred.test_case
      ( name,
        `Quick,
        fun d ->
          let run_command =
            Mock.create d (module Bos.Cmd) __LOC__ expectations
          in
          let runner = { Helpers.runner_fail_all with run_command } in
          let got = Op.update runner source in
          Alcotest.check Alcotest.(result unit msg) __LOC__ expected got )
  in
  [
    test "update"
      (Github_branch { Branch.user = "USER"; repo = "REPO"; branch = "BRANCH" })
      [
        Mock.expect
          Bos.Cmd.(
            v "opam" % "update" % "--switch" % "USER-REPO-BRANCH"
            % "ocaml-variants")
          ~and_return:(Ok 0);
      ]
      ~expected:(Ok ());
  ]

let reinstall_tests =
  let test name expectations ~expected =
    Deferred.test_case
      ( name,
        `Quick,
        fun d ->
          let run_command =
            Mock.create d (module Bos.Cmd) __LOC__ expectations
          in
          let run_out cmd = Ok ("$(" ^ Bos.Cmd.to_string cmd ^ ")") in
          let runner = { Runner.run_command; run_out } in
          let got = Op.reinstall runner in
          Alcotest.check Alcotest.(result unit msg) __LOC__ expected got )
  in
  [
    test "reinstall"
      Bos.Cmd.
        [
          Mock.expect
            (v "./configure" % "--prefix" % "$('opam' 'config' 'var' 'prefix')")
            ~and_return:(Ok 0);
          Mock.expect (v "make") ~and_return:(Ok 0);
          Mock.expect (v "make" % "install") ~and_return:(Ok 0);
        ]
      ~expected:(Ok ());
  ]

let tests =
  [
    ("Op create", create_tests);
    ("Op update", update_tests);
    ("Op reinstall", reinstall_tests);
  ]
