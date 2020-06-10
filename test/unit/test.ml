let error =
  let pp_error ppf = function `Unknown -> Format.fprintf ppf "Unknown" in
  let equal_error = ( = ) in
  Alcotest.testable pp_error equal_error

let fail_all =
  let create ~name:_ ~description:_ = assert false in
  let remove ~name:_ = assert false in
  let pin_add ~name:_ _ = assert false in
  { Opam_compiler.Switch_manager.create; remove; pin_add }

let create_ok ~name:_ ~description:_ = Ok ()

let create_exists ~name:_ ~description:_ = Error `Switch_exists

let create_error ~name:_ ~description:_ = Error `Unknown

let remove_ok ~name:_ = Ok ()

let remove_error ~name:_ = Error `Unknown

let switch_manager_create_from_scratch_tests =
  let test name create_switch_manager expected =
    let run () =
      let switch_manager = create_switch_manager () in
      let got =
        Opam_compiler.Switch_manager.create_from_scratch switch_manager
          ~name:"NAME" ~description:"DESCRIPTION"
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

let switch_manager_tests =
  [
    ( "Switch_manager create_from_scratch",
      switch_manager_create_from_scratch_tests );
  ]

let all_tests = switch_manager_tests

let () = Alcotest.run "opam-compiler" all_tests
