type t

val pp : Format.formatter -> t -> unit

val equal : t -> t -> bool

val to_string : t -> string

val escape_string : string -> t

val of_string_exn : string -> t
