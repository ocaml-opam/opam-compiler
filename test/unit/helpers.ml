open Opam_compiler

let github_client_fail_all =
  { Github_client.pr_source_branch = (fun _ -> assert false) }

let runner_fail_all =
  let run_command _ = assert false in
  let run_out _ = assert false in
  { Runner.run_command; run_out }
