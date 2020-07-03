type t = Create of Source.t | Update of Source.t | Reinstall

val eval : t -> Runner.t -> Github_client.t -> (unit, [ `Msg of string ]) result
