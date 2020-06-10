type t = Github_commit of { user : string; repo : string; hash : unit }

val pp : Format.formatter -> t -> unit
