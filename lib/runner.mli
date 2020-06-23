type t = {
  run_command : Bos.Cmd.t -> (int, [ `Unknown ]) result;
  run_out : Bos.Cmd.t -> (string, [ `Unknown ]) result;
}

val real : t

val run_command : t -> Bos.Cmd.t -> (int, [ `Unknown ]) result

val run : t -> Bos.Cmd.t -> (unit, [ `Unknown ]) result

val run_out : t -> Bos.Cmd.t -> (string, [ `Unknown ]) result
