type 'a t = 'a list ref

let create () = ref []

let record r c = r := c :: !r

let check calls testable loc expected_calls =
  Alcotest.check (Alcotest.list testable) loc expected_calls (List.rev !calls)
