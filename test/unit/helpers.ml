open Opam_compiler

let github_client_fail_all =
  let pr_info _ = assert false in
  { Github_client.pr_info }
