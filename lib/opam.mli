open! Import

val create :
  Runner.t -> Switch_name.t -> description:string -> (unit, error) result

val pin_add :
  Runner.t ->
  Switch_name.t ->
  string ->
  configure_command:Bos.Cmd.t option ->
  (unit, error) result

val set_base : Runner.t -> Switch_name.t -> (unit, error) result

val update : Runner.t -> Switch_name.t -> (unit, error) result

val reinstall_compiler :
  Runner.t ->
  compiler_sources:Fpath.t ->
  configure_command:Bos.Cmd.t option ->
  (unit, error) result

val reinstall_packages : Runner.t -> (unit, error) result

val remove_switch : Runner.t -> Switch_name.t -> (unit, error) result

val get_compiler_sources :
  Runner.t -> Switch_name.t option -> (Fpath.t option, error) result

val set_compiler_sources :
  Runner.t -> Switch_name.t -> Fpath.t option -> (unit, error) result

val get_configure_command :
  Runner.t -> Switch_name.t option -> (Bos.Cmd.t option, error) result

val set_configure_command :
  Runner.t -> Switch_name.t -> Bos.Cmd.t option -> (unit, error) result
