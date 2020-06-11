open! Import

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
           Re.bos;
           Re.opt (Re.seq [ Re.group word; Re.char '/'; Re.group word ]);
           Re.char '#';
           Re.group (Re.rep1 Re.digit);
           Re.eos;
         ])
  in
  Re.exec_opt re_pr s
  |> option_map (fun g ->
         let user, repo =
           option_pair (re_group_get_opt g 1) (re_group_get_opt g 2)
           |> option_get ~default:("ocaml", "ocaml")
         in
         let number = int_of_string (Re.Group.get g 3) in
         { user; repo; number })
