let option_pair ao bo =
  match (ao, bo) with
  | Some a, Some b -> Some (a, b)
  | None, Some _ -> None
  | Some _, None -> None
  | None, None -> None

let option_or_fail msg = function Some x -> x | None -> failwith msg

let re_group_get_opt group num =
  match Re.Group.get group num with s -> Some s | exception Not_found -> None
