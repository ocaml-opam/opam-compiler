val option_or_fail : string -> 'a option -> 'a

val option_pair : 'a option -> 'b option -> ('a * 'b) option

val re_group_get_opt : Re.Group.t -> int -> string option
