type t = {
  run_command :
    ?extra_env:(string * string) list -> Bos.Cmd.t -> (int, [ `Unknown ]) result;
  run_out : Bos.Cmd.t -> (string, [ `Unknown ]) result;
}

val real : t

val run :
  ?extra_env:(string * string) list ->
  t ->
  Bos.Cmd.t ->
  (unit, [ `Unknown ]) result

val run_out : t -> Bos.Cmd.t -> (string, [ `Unknown ]) result
