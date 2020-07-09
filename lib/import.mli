val re_group_get_opt : Re.Group.t -> int -> string option

module Let_syntax : sig
  module Cmdliner : sig
    val ( let+ ) : 'a Cmdliner.Term.t -> ('a -> 'b) -> 'b Cmdliner.Term.t

    val ( and+ ) :
      'a Cmdliner.Term.t -> 'b Cmdliner.Term.t -> ('a * 'b) Cmdliner.Term.t
  end
end
