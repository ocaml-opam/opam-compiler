type t =
  | Github_branch of { user : string; repo : string; branch : string }
  | Github_PR of Pull_request.t

val git_url : t -> string

val switch_description : t -> string

val global_switch_name : t -> string

val resolve : t -> Stable_source.t

val pp : Format.formatter -> t -> unit

val parse_exn : string -> t
