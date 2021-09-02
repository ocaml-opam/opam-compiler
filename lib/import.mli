val re_group_get_opt : Re.Group.t -> int -> string option

module Let_syntax : sig
  module Cmdliner : sig
    val ( let+ ) : 'a Cmdliner.Term.t -> ('a -> 'b) -> 'b Cmdliner.Term.t

    val ( and+ ) :
      'a Cmdliner.Term.t -> 'b Cmdliner.Term.t -> ('a * 'b) Cmdliner.Term.t
  end

  module Option : sig
    val ( let+ ) : 'a option -> ('a -> 'b) -> 'b option

    val ( and+ ) : 'a option -> 'b option -> ('a * 'b) option

    val ( let* ) : 'a option -> ('a -> 'b option) -> 'b option
  end

  module Result : sig
    val ( let+ ) : ('a, 'e) result -> ('a -> 'b) -> ('b, 'e) result

    val ( let* ) : ('a, 'e) result -> ('a -> ('b, 'e) result) -> ('b, 'e) result
  end
end

val pp_env : Format.formatter -> (string * string) list option -> unit

val pp_cmd : Format.formatter -> Bos.Cmd.t -> unit

type error = [ `Command_failed of Bos.Cmd.t | `Configure_needed | `Unknown ]

val translate_error :
  string -> ('a, [< error ]) result -> ('a, [> Rresult.R.msg ]) result
