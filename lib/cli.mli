val main : unit -> unit

type op = Create of Source.t | Update of Source.t | Info of Source.t

val eval :
  op -> Switch_manager.t -> Github_client.t -> (unit, [ `Msg of string ]) result
