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

val get_variable :
  Runner.t ->
  Switch_name.t option ->
  variable:string ->
  (string option, error) result

val set_variable :
  Runner.t ->
  Switch_name.t ->
  variable:string ->
  value:string ->
  (unit, error) result
