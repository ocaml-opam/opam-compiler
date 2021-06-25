open Opam_compiler

let switch_name_escape_string_tests =
  let test ~name s ~expected =
    ( name,
      `Quick,
      fun () ->
        let got = Switch_name.escape_string s in
        let expected = Switch_name.of_string_exn expected in
        Alcotest.check (module Switch_name) __LOC__ expected got )
  in
  [
    test ~name:"slash is escaped" "a/b" ~expected:"a-b";
    test ~name:"colon is escaped" "a:b" ~expected:"a-b";
    test ~name:"hash is escaped" "a#b" ~expected:"a-b";
    test ~name:"leading dashes are removed" "/home/me/ocaml"
      ~expected:"home-me-ocaml";
  ]

let tests = [ ("Switch_name escape_string", switch_name_escape_string_tests) ]
