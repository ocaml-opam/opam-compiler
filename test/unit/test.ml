let all_tests = Test_cli.tests @ Test_source.tests

let () = Alcotest.run "opam-compiler" all_tests
