type ('a, 'b) expectation = 'a * 'b

let expect expected ~and_return:return_value = (expected, return_value)

type ('a, 'b) t = {
  testable : 'a Alcotest.testable;
  loc : string;
  mutable expectations : ('a, 'b) expectation list;
}

let call t got =
  match t.expectations with
  | [] ->
      Alcotest.failf "Got call at %s but no more expectations: %a" t.loc
        (Alcotest.pp t.testable) got
  | (expected, rv) :: other_expectations ->
      t.expectations <- other_expectations;
      Alcotest.check t.testable t.loc expected got;
      rv

let check_empty t =
  match t.expectations with
  | [] -> ()
  | (remaining, _) :: _ ->
      Alcotest.check (Alcotest.option t.testable) t.loc None (Some remaining)

let create testable loc expectations =
  let t = { testable; loc; expectations } in
  (call t, fun () -> check_empty t)

let list_partition_map l ~f =
  let open Either in
  let rec go acc_l acc_r = function
    | [] -> (List.rev acc_l, List.rev acc_r)
    | x :: xs -> (
        match f x with
        | Left yl -> go (yl :: acc_l) acc_r xs
        | Right yr -> go acc_l (yr :: acc_r) xs)
  in
  go [] [] l

let create2 testable1 testable2 loc expectations =
  let open Either in
  let numbered_expectations = List.mapi (fun i e -> (i, e)) expectations in
  let expectations1, expectations2 =
    list_partition_map numbered_expectations ~f:(function
      | i, Left (arg_l, ret_l) -> Left ((i, arg_l), ret_l)
      | i, Right (arg_r, ret_r) -> Right ((i, arg_r), ret_r))
  in
  let call1, check1 =
    create (Alcotest.pair Alcotest.int testable1) loc expectations1
  in
  let call2, check2 =
    create (Alcotest.pair Alcotest.int testable2) loc expectations2
  in
  let count = ref (-1) in
  let f1 x =
    incr count;
    call1 (!count, x)
  in
  let f2 x =
    incr count;
    call2 (!count, x)
  in
  let check () =
    check1 ();
    check2 ()
  in
  (f1, f2, check)
