open Opam_compiler

let cache_tests =
  let pr = { Pull_request.user = "USER"; repo = "REPO"; number = 1 } in
  let pr_info =
    {
      Github_client.title = "TITLE";
      source_branch =
        { user = "PR_USER"; repo = "PR_REPO"; branch = "PR_BRANCH" };
    }
  in
  let test name make_client ~expectations =
    ( name,
      `Quick,
      fun () ->
        let pr_info, check =
          Mock.create (module Pull_request) __LOC__ expectations
        in
        let mock_client = { Github_client.pr_info } in
        let client = make_client mock_client in
        for _ = 1 to 3 do
          let _ = Github_client.pr_info client pr in
          ()
        done;
        check () )
  in
  [
    test "cache is not used"
      (fun client -> client)
      ~expectations:
        [
          Mock.expect pr ~and_return:(Ok pr_info);
          Mock.expect pr ~and_return:(Ok pr_info);
          Mock.expect pr ~and_return:(Ok pr_info);
        ];
    test "cache is used" Github_client.cached
      ~expectations:[ Mock.expect pr ~and_return:(Ok pr_info) ];
    test "only success is cached" Github_client.cached
      ~expectations:
        [
          Mock.expect pr ~and_return:(Error `Unknown);
          Mock.expect pr ~and_return:(Ok pr_info);
        ];
  ]

let tests = [ ("Cache", cache_tests) ]
