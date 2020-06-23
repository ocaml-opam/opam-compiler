type t = {
  run_command : Bos.Cmd.t -> (int, [ `Unknown ]) result;
  run_out : Bos.Cmd.t -> (string, [ `Unknown ]) result;
}

val create_from_scratch :
  t -> name:Switch_name.t -> description:string -> (unit, [ `Unknown ]) result

val real : t

val pin_add : t -> name:Switch_name.t -> string -> (unit, [ `Unknown ]) result

val update : t -> name:Switch_name.t -> (unit, [ `Unknown ]) result

val reinstall : t -> (unit, [ `Unknown ]) result
