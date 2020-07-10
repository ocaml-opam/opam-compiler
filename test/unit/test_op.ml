open Opam_compiler

let msg = Alcotest.testable Rresult.R.pp_msg ( = )

let run_command_mock d expectations =
  let testable =
    Alcotest.(pair (module Bos.Cmd) (option (list (pair string string))))
  in
  let run_command_mock = Mock.create d testable __LOC__ expectations in
  let run_command ?extra_env cmd = run_command_mock (cmd, extra_env) in
  run_command

let create_tests =
  let test name ?switch_name ?configure_command expectations ~expected =
    Deferred.test_case
      ( name,
        `Quick,
        fun d ->
          let run_command = run_command_mock d expectations in
          let runner = { Helpers.runner_fail_all with run_command } in
          let github_client = Helpers.github_client_fail_all in
          let source =
            Source.Github_branch
              { user = "USER"; repo = "REPO"; branch = "BRANCH" }
          in
          let got =
            Op.create runner github_client source switch_name ~configure_command
          in
          Alcotest.check Alcotest.(result unit msg) __LOC__ expected got )
  in
  let create_call =
    ( Bos.Cmd.(
        v "opam" % "switch" % "create" % "USER-REPO-BRANCH" % "--empty"
        % "--description" % "[opam-compiler] USER/REPO:BRANCH"),
      None )
  in
  let remove_call =
    ( Bos.Cmd.(v "opam" % "switch" % "remove" % "USER-REPO-BRANCH" % "--yes"),
      None )
  in
  let pin_add_cmd =
    Bos.Cmd.(
      v "opam" % "pin" % "add" % "--switch" % "USER-REPO-BRANCH" % "--yes"
      % "ocaml-variants" % "git+https://github.com/USER/REPO#BRANCH")
  in
  let pin_add_call = (pin_add_cmd, None) in
  [
    test "create: everything ok, default switch"
      [
        Mock.expect create_call ~and_return:(Ok 0);
        Mock.expect pin_add_call ~and_return:(Ok 0);
      ]
      ~expected:(Ok ());
    test "create: everything ok, explicit switch"
      ~switch_name:(Switch_name.of_string_exn "SWITCH-NAME")
      [
        Mock.expect
          ( Bos.Cmd.(
              v "opam" % "switch" % "create" % "SWITCH-NAME" % "--empty"
              % "--description" % "[opam-compiler] USER/REPO:BRANCH"),
            None )
          ~and_return:(Ok 0);
        Mock.expect
          ( Bos.Cmd.(
              v "opam" % "pin" % "add" % "--switch" % "SWITCH-NAME" % "--yes"
              % "ocaml-variants" % "git+https://github.com/USER/REPO#BRANCH"),
            None )
          ~and_return:(Ok 0);
      ]
      ~expected:(Ok ());
    test "create: first create fails"
      [ Mock.expect create_call ~and_return:(Error `Unknown) ]
      ~expected:(Error (`Msg "Cannot create switch"));
    test "create: switch exists, rest ok"
      [
        Mock.expect create_call ~and_return:(Ok 2);
        Mock.expect remove_call ~and_return:(Ok 0);
        Mock.expect create_call ~and_return:(Ok 0);
        Mock.expect pin_add_call ~and_return:(Ok 0);
      ]
      ~expected:(Ok ());
    test "create: switch exists, remove fails"
      [
        Mock.expect create_call ~and_return:(Ok 2);
        Mock.expect remove_call ~and_return:(Error `Unknown);
      ]
      ~expected:(Error (`Msg "Cannot create switch"));
    test "create: switch exists, remove ok, create fails"
      [
        Mock.expect create_call ~and_return:(Ok 2);
        Mock.expect remove_call ~and_return:(Ok 0);
        Mock.expect create_call ~and_return:(Error `Unknown);
      ]
      ~expected:(Error (`Msg "Cannot create switch"));
    test "create: switch exists, remove ok, switch still exists"
      [
        Mock.expect create_call ~and_return:(Ok 2);
        Mock.expect remove_call ~and_return:(Ok 0);
        Mock.expect create_call ~and_return:(Ok 2);
      ]
      ~expected:(Error (`Msg "Cannot create switch"));
    test "create: explicit configure"
      ~configure_command:Bos.Cmd.(v "./configure" % "--enable-x")
      [
        Mock.expect create_call ~and_return:(Ok 0);
        Mock.expect
          ( Bos.Cmd.(pin_add_cmd % "--edit"),
            Some
              [
                ( "OPAMEDITOR",
                  {|sed -i -e 's#"./configure"#"./configure" "--enable-x"#g'|}
                );
              ] )
          ~and_return:(Ok 0);
      ]
      ~expected:(Ok ());
  ]

let reinstall_tests =
  let test name mode configure_command expectations ~expected =
    Deferred.test_case
      ( name,
        `Quick,
        fun d ->
          let run_command = run_command_mock d expectations in
          let run_out cmd = Ok ("$(" ^ Bos.Cmd.to_string cmd ^ ")") in
          let runner = { Runner.run_command; run_out } in
          let got = Op.reinstall runner mode ~configure_command in
          Alcotest.check Alcotest.(result unit msg) __LOC__ expected got )
  in
  [
    test "reinstall (quick)" Quick None
      Bos.Cmd.
        [
          Mock.expect
            ( v "./configure" % "--prefix" % "$('opam' 'config' 'var' 'prefix')",
              None )
            ~and_return:(Ok 0);
          Mock.expect (v "make", None) ~and_return:(Ok 0);
          Mock.expect (v "make" % "install", None) ~and_return:(Ok 0);
        ]
      ~expected:(Ok ());
    test "reinstall (full)" Full None
      Bos.Cmd.
        [
          Mock.expect
            ( v "./configure" % "--prefix" % "$('opam' 'config' 'var' 'prefix')",
              None )
            ~and_return:(Ok 0);
          Mock.expect (v "make", None) ~and_return:(Ok 0);
          Mock.expect (v "make" % "install", None) ~and_return:(Ok 0);
          Mock.expect
            ( v "opam" % "reinstall" % "--assume-built" % "--working-dir"
              % "ocaml-variants",
              None )
            ~and_return:(Ok 0);
        ]
      ~expected:(Ok ());
    test "reinstall (different configure command)" Quick
      (Some Bos.Cmd.(v "./configure" % "--enable-something"))
      Bos.Cmd.
        [
          Mock.expect
            ( v "./configure" % "--enable-something" % "--prefix"
              % "$('opam' 'config' 'var' 'prefix')",
              None )
            ~and_return:(Ok 0);
          Mock.expect (v "make", None) ~and_return:(Ok 0);
          Mock.expect (v "make" % "install", None) ~and_return:(Ok 0);
        ]
      ~expected:(Ok ());
  ]

let tests = [ ("Op create", create_tests); ("Op reinstall", reinstall_tests) ]
