open Opam_compiler
open Import

let error =
  let pp_error ppf = function `Unknown -> Format.fprintf ppf "Unknown" in
  let equal_error = ( = ) in
  Alcotest.testable pp_error equal_error

let parse_tests =
  let test name s expected =
    ( name,
      `Quick,
      fun () ->
        let got = Source.parse s in
        Alcotest.check (module Source) __LOC__ expected got )
  in
  [
    test "full branch syntax" "user/repo:branch"
      (Github_branch { user = "user"; repo = "repo"; branch = "branch" });
    test "branches can have dashes" "user/repo:my-great-branch"
      (Github_branch
         { user = "user"; repo = "repo"; branch = "my-great-branch" });
    test "repo can be omitted and defaults to ocaml" "user:branch"
      (Github_branch { user = "user"; repo = "ocaml"; branch = "branch" });
    test "repo with PR number" "user/repo#1234"
      (Github_PR { user = "user"; repo = "repo"; number = 1234 });
    test "defaults to main repo" "#1234"
      (Github_PR { user = "ocaml"; repo = "ocaml"; number = 1234 });
    test "directory name" "." (Local_source_dir ".");
  ]

let switch_target_tests =
  let test name source ~github_response ~expected
      ~expected_pr_source_branch_calls =
    ( name,
      `Quick,
      fun () ->
        let recorder = Call_recorder.create () in
        let pr_source_branch pr =
          Call_recorder.record recorder pr;
          option_or_fail "No github response configured" github_response
        in
        let github_client = { Github_client.pr_source_branch } in
        let got = Source.switch_target source github_client in
        Alcotest.check Alcotest.(result string error) __LOC__ expected got;
        Call_recorder.check recorder
          (module Pull_request)
          __LOC__ expected_pr_source_branch_calls )
  in
  let test_pr name github_response expected =
    let pr = { Pull_request.user = "USER"; repo = "REPO"; number = 1234 } in
    test name (Source.Github_PR pr) ~github_response:(Some github_response)
      ~expected ~expected_pr_source_branch_calls:[ pr ]
  in
  [
    test_pr "PR error" (Error `Unknown) (Error `Unknown);
    test_pr "PR ok"
      (Ok { Branch.user = "SRC_USER"; repo = "SRC_REPO"; branch = "SRC_BRANCH" })
      (Ok "git+https://github.com/SRC_USER/SRC_REPO#SRC_BRANCH");
    test "branch"
      (Source.Github_branch { user = "USER"; repo = "REPO"; branch = "BRANCH" })
      ~github_response:None
      ~expected:(Ok "git+https://github.com/USER/REPO#BRANCH")
      ~expected_pr_source_branch_calls:[];
    test "local source dir" (Source.Local_source_dir "PATH")
      ~github_response:None ~expected:(Ok "PATH")
      ~expected_pr_source_branch_calls:[];
  ]

let tests =
  [ ("Source parse", parse_tests); ("Source git_url", switch_target_tests) ]
