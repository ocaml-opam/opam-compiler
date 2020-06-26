type t
(** A way to run computations later. *)

val run : t -> (unit -> unit) -> unit
(** Attach this function to run later. *)

val test_case : t Alcotest.test_case -> unit Alcotest.test_case
(** Add a [t] argument to a test case. The deferred function run at the end of
    the test case. *)
