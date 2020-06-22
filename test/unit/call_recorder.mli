type 'a t

val create : unit -> 'a t

val record : 'a t -> 'a -> unit

val check : 'a t -> 'a Alcotest.testable -> string -> 'a list -> unit
