val create_from_scratch :
  Runner.t ->
  name:Switch_name.t ->
  description:string ->
  (unit, [ `Unknown ]) result

val pin_add :
  Runner.t -> name:Switch_name.t -> string -> (unit, [ `Unknown ]) result

val update : Runner.t -> name:Switch_name.t -> (unit, [ `Unknown ]) result

val reinstall : Runner.t -> (unit, [ `Unknown ]) result