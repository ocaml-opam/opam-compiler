type t = {
  pr_source_branch : Pull_request.t -> (Branch.t, [ `Unknown ]) result;
}

let pr_source_branch t = t.pr_source_branch

module Real = struct
  let pull_source_user branch =
    match branch.Github_t.branch_user with
    | Some user -> Ok user.user_login
    | None -> Error `Unknown

  let pull_source_repo branch =
    match branch.Github_t.branch_repo with
    | Some repo -> Ok repo.repository_name
    | None -> Error `Unknown

  let get_pr { Pull_request.user; repo; number } =
    let open Github.Monad in
    Github.Pull.get ~user ~repo ~num:number () >|= Github.Response.value

  let pr_source_branch pr =
    let open Rresult.R in
    get_pr pr |> Github.Monad.run |> Lwt_result.catch |> Lwt_main.run
    |> reword_error (fun (_ : exn) -> `Unknown)
    >>= fun { Github_t.pull_head; _ } ->
    pull_source_user pull_head >>= fun user ->
    pull_source_repo pull_head >>| fun repo ->
    let branch = pull_head.branch_ref in
    { Branch.user; repo; branch }
end

let real =
  let open Real in
  { pr_source_branch }
