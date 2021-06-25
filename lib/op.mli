val create :
  Runner.t ->
  Github_client.t ->
  Source.t ->
  Switch_name.t option ->
  configure_command:Bos.Cmd.t option ->
  (unit, [> Rresult.R.msg ]) result

type reinstall_mode = Quick | Full

val reinstall :
  Runner.t ->
  reinstall_mode ->
  name:Switch_name.t option ->
  (unit, [> Rresult.R.msg ]) result
