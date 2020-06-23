open Opam_compiler

let github_client_fail_all =
  { Github_client.pr_source_branch = (fun _ -> assert false) }

let switch_manager_fail_all =
  let create ~name:_ ~description:_ = assert false in
  let info ~name:_ = assert false in
  let run_command _ = assert false in
  let run_out _ = assert false in
  { Switch_manager.create; info; run_command; run_out }
