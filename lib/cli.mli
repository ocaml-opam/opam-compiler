val main : unit -> unit

type op = Create of Source.t | Update of Source.t | Reinstall

val eval :
  op -> Runner.t -> Github_client.t -> (unit, [ `Msg of string ]) result
