let re_group_get_opt group num =
  match Re.Group.get group num with s -> Some s | exception Not_found -> None
