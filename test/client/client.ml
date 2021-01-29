open Opam_compiler

let () =
  match Sys.argv with
  | [| _ |] -> ()
  | [| _; user; repo; number_s |] -> (
      let number = int_of_string number_s in
      let pr = { Pull_request.user; repo; number } in
      let client = Github_client.real in
      match Github_client.pr_info client pr with
      | Ok { source_branch; title } ->
          Format.printf "title: %s\nbranch: %a\n" title Branch.pp source_branch
      | Error _ -> print_endline "error")
  | _ -> assert false
