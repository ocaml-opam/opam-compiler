open! Import

type pr_info = { source_branch : Branch.t; title : string }
type t = { pr_info : Pull_request.t -> (pr_info, [ `Unknown ]) result }

let pr_info t pr =
  (t.pr_info pr : (_, [ `Unknown ]) result :> (_, [> `Unknown ]) result)

module Curly = struct
  let pull_source_user branch =
    match branch.Github_t.branch_user with
    | Some user -> Ok user.user_login
    | None -> Error `Unknown

  let pull_source_repo branch =
    match branch.Github_t.branch_repo with
    | Some repo -> Ok repo.repository_name
    | None -> Error `Unknown

  let info_of_pull pull =
    let open Let_syntax.Result in
    let { Github_t.pull_head; pull_title = title; _ } = pull in
    let* user = pull_source_user pull_head in
    let+ repo = pull_source_repo pull_head in
    let branch = pull_head.branch_ref in
    let source_branch = { Branch.user; repo; branch } in
    { source_branch; title }

  let check_code code = if code = 200 then Ok () else Error `Unknown

  let parse_pull body =
    match Github_j.pull_of_string body with
    | pull -> Ok pull
    | exception Yojson.Json_error _ -> Error `Unknown

  let pull_url { Pull_request.user; repo; number } =
    let root = "https://api.github.com" in
    Printf.sprintf "%s/repos/%s/%s/pulls/%d" root user repo number

  let get url =
    Curly.get url
    |> Rresult.R.reword_error (fun (_ : Curly.Error.t) -> `Unknown)

  let pr_info pr =
    let open Let_syntax.Result in
    let url = pull_url pr in
    let* response = get url in
    let* () = check_code response.code in
    let* pull = parse_pull response.body in
    info_of_pull pull
end

let curly =
  let open Curly in
  { pr_info }

module Dry_run = struct
  let pr_info { Pull_request.user; repo; number } =
    let slug = Printf.sprintf "%s-%s-%d" user repo number in
    let source_branch =
      {
        Branch.user = Printf.sprintf "user-%s" slug;
        repo = Printf.sprintf "repo-%s" slug;
        branch = Printf.sprintf "branch-%s" slug;
      }
    in
    let title = Printf.sprintf "Title of %s" slug in
    Ok { source_branch; title }
end

let dry_run =
  let open Dry_run in
  { pr_info }

let cached c =
  let table = Hashtbl.create 0 in
  let pr_info pr =
    match Hashtbl.find_opt table pr with
    | Some hit -> Ok hit
    | None ->
        let result = c.pr_info pr in
        Result.iter (fun info -> Hashtbl.add table pr info) result;
        result
  in
  { pr_info }

let real = cached curly
