let all_tests = Test_op.tests @ Test_source.tests @ Test_switch_name.tests

let () = Alcotest.run "opam-compiler" all_tests
