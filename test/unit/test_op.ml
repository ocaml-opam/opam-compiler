open Opam_compiler
open Import

let msg = Alcotest.testable Rresult.R.pp_msg ( = )

let cmd = Alcotest.testable pp_cmd Bos.Cmd.equal

type call_run = {
  command : Bos.Cmd.t;
  extra_env : (string * string) list option;
}

let alcotest_contramap (type a) ~f t =
  let module M = (val t : Alcotest.TESTABLE with type t = a) in
  let pp ppf x = M.pp ppf (f x) in
  let equal a b = M.equal (f a) (f b) in
  Alcotest.testable pp equal

let mock_runner loc expectations =
  let call_run_testable =
    alcotest_contramap
      Alcotest.(pair cmd (option (list (pair string string))))
      ~f:(fun { command; extra_env } -> (command, extra_env))
  in
  let call_run_out_testable =
    alcotest_contramap
      Alcotest.(pair (module Bos.Cmd) (option (list (pair string string))))
      ~f:(fun { command; extra_env } -> (command, extra_env))
  in
  let call_run, call_run_out, check =
    Mock.create2 call_run_testable call_run_out_testable loc expectations
  in
  let run ?extra_env command = call_run { command; extra_env } in
  let run_out ?extra_env command = call_run_out { command; extra_env } in
  let runner = { Runner.run; run_out } in
  (runner, check)

let opam_cli_env = Some [ ("OPAMCLI", "2.0") ]

let create_tests =
  let test name ?switch_name ?configure_command expectations ~expected =
    ( name,
      `Quick,
      fun () ->
        let runner, check =
          mock_runner __LOC__ (List.map Either.left expectations)
        in
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
  let create_call = { command = create_cmd; extra_env = opam_cli_env } in
  let pin_add_cmd =
    Bos.Cmd.(
      v "opam" % "pin" % "add" % "--switch" % "USER-REPO-BRANCH" % "--yes"
      % "ocaml-variants" % "git+https://github.com/USER/REPO#BRANCH")
  in
  let pin_add_call = { command = pin_add_cmd; extra_env = opam_cli_env } in
  [
    test "create: create fails with unknown error"
      [ Mock.expect create_call ~and_return:(Error `Unknown) ]
      ~expected:(Error (`Msg "Cannot create switch"));
    test "create: when pin command fails"
      [
        Mock.expect create_call ~and_return:(Ok ());
        Mock.expect pin_add_call
          ~and_return:(Error (`Command_failed pin_add_cmd));
        Mock.expect
          {
            command =
              Bos.Cmd.(
                v "opam" % "switch" % "remove" % "--yes" % "USER-REPO-BRANCH");
            extra_env = opam_cli_env;
          }
          ~and_return:(Ok ());
      ]
      ~expected:
        (Rresult.R.error_msg
           "Cannot create switch - command failed: opam pin add --switch \
            USER-REPO-BRANCH --yes ocaml-variants \
            git+https://github.com/USER/REPO#BRANCH");
  ]

let reinstall_tests =
  let test name mode configure_command expectations ~expected =
    ( name,
      `Quick,
      fun () ->
        let runner, check = mock_runner __LOC__ expectations in
        let got = Op.reinstall runner mode ~configure_command in
        Alcotest.check Alcotest.(result unit msg) __LOC__ expected got;
        check () )
  in
  let expect_run ~command ~extra_env ~and_return =
    Either.Left (Mock.expect { command; extra_env } ~and_return)
  in
  let expect_run_out ~command ~extra_env ~and_return =
    Either.Right (Mock.expect { command; extra_env } ~and_return)
  in
  [
    test "reinstall (quick)" Quick None
      [
        expect_run_out
          ~command:Bos.Cmd.(v "opam" % "config" % "var" % "prefix")
          ~extra_env:opam_cli_env ~and_return:(Ok "PREFIX");
        expect_run
          ~command:Bos.Cmd.(v "./configure" % "--prefix" % "PREFIX")
          ~extra_env:None ~and_return:(Ok ());
        expect_run
          ~command:Bos.Cmd.(v "make")
          ~extra_env:None ~and_return:(Ok ());
        expect_run
          ~command:Bos.Cmd.(v "make" % "install")
          ~extra_env:None ~and_return:(Ok ());
      ]
      ~expected:(Ok ());
    test "reinstall (full)" Full None
      [
        expect_run_out
          ~command:Bos.Cmd.(v "opam" % "config" % "var" % "prefix")
          ~extra_env:opam_cli_env ~and_return:(Ok "PREFIX");
        expect_run
          ~command:Bos.Cmd.(v "./configure" % "--prefix" % "PREFIX")
          ~extra_env:None ~and_return:(Ok ());
        expect_run
          ~command:Bos.Cmd.(v "make")
          ~extra_env:None ~and_return:(Ok ());
        expect_run
          ~command:Bos.Cmd.(v "make" % "install")
          ~extra_env:None ~and_return:(Ok ());
        expect_run
          ~command:
            Bos.Cmd.(
              v "opam" % "reinstall" % "--assume-built" % "--working-dir"
              % "ocaml-variants")
          ~extra_env:opam_cli_env ~and_return:(Ok ());
      ]
      ~expected:(Ok ());
    test "reinstall (different configure command)" Quick
      (Some Bos.Cmd.(v "./configure" % "--enable-something"))
      [
        expect_run_out
          ~command:Bos.Cmd.(v "opam" % "config" % "var" % "prefix")
          ~extra_env:opam_cli_env ~and_return:(Ok "PREFIX");
        expect_run
          ~command:
            Bos.Cmd.(
              v "./configure" % "--enable-something" % "--prefix" % "PREFIX")
          ~extra_env:None ~and_return:(Ok ());
        expect_run
          ~command:Bos.Cmd.(v "make")
          ~extra_env:None ~and_return:(Ok ());
        expect_run
          ~command:Bos.Cmd.(v "make" % "install")
          ~extra_env:None ~and_return:(Ok ());
      ]
      ~expected:(Ok ());
  ]

let tests = [ ("Op create", create_tests); ("Op reinstall", reinstall_tests) ]
