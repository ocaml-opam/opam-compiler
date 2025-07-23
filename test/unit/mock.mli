type ('a, 'b) expectation

val expect : 'a -> and_return:'b -> ('a, 'b) expectation

val create :
  'a Alcotest.testable ->
  string ->
  ('a, 'b) expectation list ->
  ('a -> 'b) * (unit -> unit)
(** A mock is a way of turning a list of input / output pairs into a function. A
    check function is returned that should be run at the end of its lifetime. It
    is possible to use [(let$)] to run it at the end of a binding, e.g.
    [let$ f = create ... in ...]. *)

val create2 :
  'a1 Alcotest.testable ->
  'a2 Alcotest.testable ->
  string ->
  (('a1, 'b1) expectation, ('a2, 'b2) expectation) Either.t list ->
  ('a1 -> 'b1) * ('a2 -> 'b2) * (unit -> unit)
