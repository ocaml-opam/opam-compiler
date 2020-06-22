open Opam_compiler

let github_client_fail_all =
  { Github_client.pr_source_branch = (fun _ -> assert false) }

let switch_manager_fail_all =
  let create ~name:_ ~description:_ = assert false in
  let remove ~name:_ = assert false in
  let pin_add ~name:_ _ = assert false in
  let update ~name:_ = assert false in
  let info ~name:_ = assert false in
  { Switch_manager.create; remove; pin_add; update; info }
