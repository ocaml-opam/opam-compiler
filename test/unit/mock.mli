type ('a, 'b) expectation

val expect : 'a -> and_return:'b -> ('a, 'b) expectation

val create :
  Deferred.t ->
  'a Alcotest.testable ->
  string ->
  ('a, 'b) expectation list ->
  'a ->
  'b
(** A mock is a way of turning a list of input / output pairs into a function.
    At the end of its "lifetime", there is a check that all expectations have
    happened. This is done by registering a check function into the
    [Deferred.t].
 *)
