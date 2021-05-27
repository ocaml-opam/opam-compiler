val create :
  Runner.t ->
  name:Switch_name.t ->
  description:string ->
  (unit, [ `Command_failed of Bos.Cmd.t | `Unknown ]) result

val pin_add :
  Runner.t ->
  name:Switch_name.t ->
  string ->
  configure_command:Bos.Cmd.t option ->
  (unit, [ `Command_failed of Bos.Cmd.t | `Unknown ]) result

val set_base :
  Runner.t ->
  name:Switch_name.t ->
  (unit, [ `Command_failed of Bos.Cmd.t | `Unknown ]) result

val update :
  Runner.t ->
  name:Switch_name.t ->
  (unit, [ `Command_failed of Bos.Cmd.t | `Unknown ]) result

val reinstall_compiler :
  Runner.t ->
  configure_command:Bos.Cmd.t option ->
  (unit, [ `Command_failed of Bos.Cmd.t | `Unknown ]) result

val reinstall_packages :
  Runner.t -> (unit, [ `Command_failed of Bos.Cmd.t | `Unknown ]) result

val remove_switch :
  Runner.t ->
  name:Switch_name.t ->
  (unit, [ `Command_failed of Bos.Cmd.t | `Unknown ]) result
