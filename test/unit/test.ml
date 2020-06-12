open Opam_compiler

let error =
  let pp_error ppf = function `Unknown -> Format.fprintf ppf "Unknown" in
  let equal_error = ( = ) in
  Alcotest.testable pp_error equal_error

let msg = Alcotest.testable Rresult.R.pp_msg ( = )

let github_client_fail_all =
  { Github_client.pr_source_branch = (fun _ -> assert false) }

let fail_all =
  let create ~name:_ ~description:_ = assert false in
  let remove ~name:_ = assert false in
  let pin_add ~name:_ _ = assert false in
  let update ~name:_ = assert false in
  let info ~name:_ = assert false in
  { Switch_manager.create; remove; pin_add; update; info }

type call =
  | Create of { name : Switch_name.t; description : string }
  | Remove of { name : Switch_name.t }
  | Pin_add of { name : Switch_name.t; url : string }

let pp_call ppf = function
  | Create { name; description } ->
      Format.fprintf ppf "Create { name = %a; description = %S }" Switch_name.pp
        name description
  | Remove { name } ->
      Format.fprintf ppf "Remove { name = %a }" Switch_name.pp name
  | Pin_add { name; url } ->
      Format.fprintf ppf "Pin_add { name = %a; url = %S }" Switch_name.pp name
        url

let call = Alcotest.testable pp_call ( = )

let cli_eval_tests =
  let branch = { Branch.user = "USER"; repo = "REPO"; branch = "BRANCH" } in
  let source = Source.Github_branch branch in
  let test name ~create_rvs ~remove_rv ~expected ~expected_calls =
    ( name,
      `Quick,
      fun () ->
        let create_rvs = ref create_rvs in
        let calls = ref [] in
        let create ~name ~description =
          calls := Create { name; description } :: !calls;
          match !create_rvs with
          | [] -> assert false
          | h :: t ->
              create_rvs := t;
              h
        in
        let remove ~name =
          calls := Remove { name } :: !calls;
          remove_rv
        in
        let pin_add ~name url = calls := Pin_add { name; url } :: !calls in
        let switch_manager = { fail_all with create; remove; pin_add } in
        let github_client = github_client_fail_all in
        let got = Cli.eval (Create source) switch_manager github_client in
        Alcotest.check Alcotest.(result unit msg) __LOC__ expected got;
        Alcotest.check
          Alcotest.(list call)
          __LOC__ expected_calls (List.rev !calls) )
  in
  let switch_name = Switch_name.of_string_exn "USER-REPO-BRANCH" in
  let create_call =
    Create
      { name = switch_name; description = Source.switch_description source }
  in
  let remove_call = Remove { name = switch_name } in
  let pin_add_call =
    Pin_add { name = switch_name; url = Branch.git_url branch }
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

let source = Alcotest.testable Source.pp Source.equal

let source_parse_tests =
  let test name s expected =
    ( name,
      `Quick,
      fun () ->
        let got = Source.parse s in
        Alcotest.check (Alcotest.option source) __LOC__ expected got )
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

let pull_request = Alcotest.testable Pull_request.pp Pull_request.equal

let source_git_url_tests =
  let test_branch =
    ( "branch",
      `Quick,
      fun () ->
        let github_client = github_client_fail_all in
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
        Alcotest.check (Alcotest.list pull_request) __LOC__ [ pr ] !calls )
  in
  [
    test_pr "PR error" (Error `Unknown) (Error `Unknown);
    test_pr "PR ok"
      (Ok { Branch.user = "SRC_USER"; repo = "SRC_REPO"; branch = "SRC_BRANCH" })
      (Ok "git+https://github.com/SRC_USER/SRC_REPO#SRC_BRANCH");
    test_branch;
  ]

let switch_manager_tests =
  [
    ("Cli eval", cli_eval_tests);
    ("Source parse", source_parse_tests);
    ("Source git_url", source_git_url_tests);
  ]

let all_tests = switch_manager_tests

let () = Alcotest.run "opam-compiler" all_tests
