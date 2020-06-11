type t

val to_string : t -> string

val escape_string : string -> t

val of_string_exn : string -> t
