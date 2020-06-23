type t = {
  create :
    name:Switch_name.t ->
    description:string ->
    (unit, [ `Unknown | `Switch_exists ]) result;
  info : name:Switch_name.t -> (string, [ `Unknown ]) result;
  run_command : Bos.Cmd.t -> (unit, [ `Unknown ]) result;
  run_out : Bos.Cmd.t -> (string, [ `Unknown ]) result;
}

val create_from_scratch :
  t -> name:Switch_name.t -> description:string -> (unit, [ `Unknown ]) result

val real : t

val pin_add : t -> name:Switch_name.t -> string -> (unit, [ `Unknown ]) result

val update : t -> name:Switch_name.t -> (unit, [ `Unknown ]) result

val info : t -> name:Switch_name.t -> (string, [ `Unknown ]) result

val reinstall : t -> (unit, [ `Unknown ]) result
