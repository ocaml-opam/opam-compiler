type t = {
  create :
    name:Switch_name.t ->
    description:string ->
    (unit, [ `Unknown | `Switch_exists ]) result;
  remove : name:Switch_name.t -> (unit, [ `Unknown ]) result;
  pin_add : name:Switch_name.t -> string -> unit;
  update : name:Switch_name.t -> (unit, [ `Unknown ]) result;
}

val create_from_scratch :
  t -> name:Switch_name.t -> description:string -> (unit, [ `Unknown ]) result

val real : t

val pin_add : t -> name:Switch_name.t -> string -> unit

val update : t -> name:Switch_name.t -> (unit, [ `Unknown ]) result
