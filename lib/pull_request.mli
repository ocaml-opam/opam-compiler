type t = { user : string; repo : string; number : int }

val parse : string -> t option

val target : t -> string * string
