open! Import

val create :
  Runner.t -> name:Switch_name.t -> description:string -> (unit, error) result

val pin_add :
  Runner.t ->
  name:Switch_name.t ->
  string ->
  configure_command:Bos.Cmd.t option ->
  (unit, error) result

val set_base : Runner.t -> name:Switch_name.t -> (unit, error) result

val update : Runner.t -> name:Switch_name.t -> (unit, error) result

val reinstall_compiler :
  Runner.t -> configure_command:Bos.Cmd.t option -> (unit, error) result

val reinstall_packages : Runner.t -> (unit, error) result

val remove_switch : Runner.t -> name:Switch_name.t -> (unit, error) result

val get_compiler_sources :
  Runner.t -> name:Switch_name.t -> (Fpath.t option, error) result

val set_compiler_sources :
  Runner.t -> name:Switch_name.t -> Fpath.t -> (unit, error) result
