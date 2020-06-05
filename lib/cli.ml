let main () =
  print_endline "compiler";
  Printf.printf "args:\n";
  Array.iteri (fun i arg -> Printf.printf "  - [%d]: %S\n" i arg) Sys.argv
