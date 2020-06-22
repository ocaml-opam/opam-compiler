open Opam_compiler

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
        Alcotest.check (Alcotest.option (module Source)) __LOC__ expected got )
  in
  [
    test "full branch syntax" "user/repo:branch"
      (Some (Github_branch { user = "user"; repo = "repo"; branch = "branch" }));
    test "branches can have dashes" "user/repo:my-great-branch"
      (Some
         (Github_branch
            { user = "user"; repo = "repo"; branch = "my-great-branch" }));
    test "repo can be omitted and defaults to ocaml" "user:branch"
      (Some (Github_branch { user = "user"; repo = "ocaml"; branch = "branch" }));
    test "repo with PR number" "user/repo#1234"
      (Some (Github_PR { user = "user"; repo = "repo"; number = 1234 }));
    test "defaults to main repo" "#1234"
      (Some (Github_PR { user = "ocaml"; repo = "ocaml"; number = 1234 }));
  ]

let git_url_tests =
  let test_branch =
    ( "branch",
      `Quick,
      fun () ->
        let github_client = Helpers.github_client_fail_all in
        let user = "USER" in
        let repo = "REPO" in
        let branch = "BRANCH" in
        let expected = Ok "git+https://github.com/USER/REPO#BRANCH" in
        let source = Source.Github_branch { user; repo; branch } in
        let got = Source.git_url source github_client in
        Alcotest.check Alcotest.(result string error) __LOC__ expected got )
  in
  let test_pr name github_response expected =
    ( name,
      `Quick,
      fun () ->
        let calls = ref [] in
        let pr_source_branch pr =
          calls := pr :: !calls;
          github_response
        in
        let github_client = { Github_client.pr_source_branch } in
        let user = "USER" in
        let repo = "REPO" in
        let number = 1234 in
        let pr = { Pull_request.user; repo; number } in
        let source = Source.Github_PR pr in
        let got = Source.git_url source github_client in
        Alcotest.check Alcotest.(result string error) __LOC__ expected got;
        Alcotest.check
          (Alcotest.list (module Pull_request))
          __LOC__ [ pr ] !calls )
  in
  [
    test_pr "PR error" (Error `Unknown) (Error `Unknown);
    test_pr "PR ok"
      (Ok { Branch.user = "SRC_USER"; repo = "SRC_REPO"; branch = "SRC_BRANCH" })
      (Ok "git+https://github.com/SRC_USER/SRC_REPO#SRC_BRANCH");
    test_branch;
  ]

let tests = [ ("Source parse", parse_tests); ("Source git_url", git_url_tests) ]
