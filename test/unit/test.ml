let error =
  let pp_error ppf = function `Unknown -> Format.fprintf ppf "Unknown" in
  let equal_error = ( = ) in
  Alcotest.testable pp_error equal_error

let fail_all =
  let create ~name:_ ~description:_ = assert false in
  let remove ~name:_ = assert false in
  let pin_add ~name:_ _ = assert false in
  let update ~name:_ = assert false in
  let info ~name:_ = assert false in
  { Opam_compiler.Switch_manager.create; remove; pin_add; update; info }

let create_ok ~name:_ ~description:_ = Ok ()

let create_exists ~name:_ ~description:_ = Error `Switch_exists

let create_error ~name:_ ~description:_ = Error `Unknown

let remove_ok ~name:_ = Ok ()

let remove_error ~name:_ = Error `Unknown

let switch_manager_create_from_scratch_tests =
  let test name create_switch_manager expected =
    let run () =
      let switch_manager = create_switch_manager () in
      let name = Opam_compiler.Switch_name.of_string_exn "NAME" in
      let got =
        Opam_compiler.Switch_manager.create_from_scratch switch_manager ~name
          ~description:"DESCRIPTION"
      in
      Alcotest.check Alcotest.(result unit error) __LOC__ expected got
    in
    (name, `Quick, run)
  in
  [
    test "switch does not exist"
      (fun () -> { fail_all with create = create_ok })
      (Ok ());
    test "switch exists"
      (fun () ->
        let count = ref 0 in
        let create ~name:_ ~description:_ =
          incr count;
          if !count > 0 then Ok () else Error `Switch_exists
        in
        { fail_all with create; remove = remove_ok })
      (Ok ());
    test "create fails"
      (fun () -> { fail_all with create = create_error })
      (Error `Unknown);
    test "remove fails"
      (fun () ->
        { fail_all with create = create_exists; remove = remove_error })
      (Error `Unknown);
  ]

let source =
  Alcotest.testable Opam_compiler.Source.pp Opam_compiler.Source.equal

let source_parse_tests =
  let test name s expected =
    ( name,
      `Quick,
      fun () ->
        let got = Opam_compiler.Source.parse s in
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

let switch_manager_tests =
  [
    ( "Switch_manager create_from_scratch",
      switch_manager_create_from_scratch_tests );
    ("Source parse", source_parse_tests);
  ]

let all_tests = switch_manager_tests

let () = Alcotest.run "opam-compiler" all_tests
