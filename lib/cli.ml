let option_pair ao bo =
  match (ao, bo) with
  | Some a, Some b -> Some (a, b)
  | None, Some _ -> None
  | Some _, None -> None
  | None, None -> None

let option_get ~default = function Some x -> x | None -> default

let re_group_get_opt group num =
  match Re.Group.get group num with s -> Some s | exception Not_found -> None

module PR = struct
  type t = { user : string; repo : string; number : int }

  let target { user; repo; number } =
    let descr = Format.asprintf "%s/%s#%d" user repo number in
    let source_user = Format.asprintf "src_user_%s" descr in
    let source_repo = Format.asprintf "src_repo_%s" descr in
    (source_user, source_repo)

  let parse s =
    let word = Re.rep1 Re.wordc in
    let re_pr =
      Re.compile
        (Re.seq
           [
             Re.opt (Re.seq [ Re.group word; Re.char '/'; Re.group word ]);
             Re.char '#';
             Re.group (Re.rep1 Re.digit);
           ])
    in
    Re.exec_opt re_pr s
    |> Option.map (fun g ->
           let user, repo =
             option_pair (re_group_get_opt g 1) (re_group_get_opt g 2)
             |> option_get ~default:("ocaml", "ocaml")
           in
           let number = int_of_string (Re.Group.get g 3) in
           { user; repo; number })
end

module Stable_source = struct
  type t = Github_commit of { user : string; repo : string; hash : unit }

  let pp ppf = function
    | Github_commit { user; repo; hash = () } ->
        Format.fprintf ppf "Github_commit { user = %S; repo = %S; hash = ? }"
          user repo
end

module Source = struct
  type source =
    | Github_branch of { user : string; repo : string; branch : string }
    | Github_PR of PR.t

  let parse s =
    let word = Re.rep1 Re.wordc in
    let re_branch =
      Re.compile
        (Re.seq
           [
             Re.group word;
             Re.opt (Re.seq [ Re.char '/'; Re.group word ]);
             Re.char ':';
             Re.group word;
           ])
    in
    match Re.exec_opt re_branch s with
    | Some g ->
        let user = Re.Group.get g 1 in
        let repo = re_group_get_opt g 2 |> option_get ~default:"ocaml" in
        let branch = Re.Group.get g 3 in
        Github_branch { user; repo; branch }
    | None -> (
        match PR.parse s with Some pr -> Github_PR pr | None -> assert false )

  let pp ppf = function
    | Github_branch { user; repo; branch } ->
        Format.fprintf ppf "Github_branch { user = %S; repo = %S; branch = %S }"
          user repo branch
    | Github_PR { user; repo; number } ->
        Format.fprintf ppf "Github_PR { user = %S; repo = %S; number = %d }"
          user repo number

  let resolve source =
    let open Stable_source in
    match source with
    | Github_branch { user; repo; branch = _ } ->
        let hash = () in
        Github_commit { user; repo; hash }
    | Github_PR pr ->
        let source_user, source_repo = PR.target pr in
        let hash = () in
        Github_commit { user = source_user; repo = source_repo; hash }
end

let info arg =
  let source = Source.parse arg in
  Format.printf "source: %a\n" Source.pp source

let create_opam_switch ~name stable_source =
  Format.printf "Creating opam switch named %S based in %a" name
    Stable_source.pp stable_source

let update_opam_switch ~name stable_source =
  Format.printf "Updating opam switch named %S based in %a" name
    Stable_source.pp stable_source

let create arg =
  Format.printf "Creating switch: %S\n" arg;
  let source = Source.parse arg in
  let stable_source = Source.resolve source in
  Format.printf "Resolving to %a\n" Stable_source.pp stable_source;
  create_opam_switch ~name:arg stable_source

let update arg =
  Format.printf "Updating switch: %S\n" arg;
  let source = Source.parse arg in
  let stable_source = Source.resolve source in
  Format.printf "Resolving to %a\n" Stable_source.pp stable_source;
  update_opam_switch ~name:arg stable_source

let main () =
  match Sys.argv with
  | [| _; "info"; arg |] -> info arg
  | [| _; "create"; arg |] -> create arg
  | [| _; "update"; arg |] -> update arg
  | _ -> assert false
