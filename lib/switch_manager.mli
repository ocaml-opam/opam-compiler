type t = {
  create :
    name:string ->
    description:string ->
    (unit, [ `Unknown | `Switch_exists ]) result;
  remove : name:string -> (unit, [ `Unknown ]) result;
  pin_add : name:string -> string -> unit;
}

val create_from_scratch :
  t -> name:string -> description:string -> (unit, [ `Unknown ]) result

val real : t

val pin_add : t -> name:string -> string -> unit
