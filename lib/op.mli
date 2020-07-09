val create :
  Runner.t ->
  Github_client.t ->
  Source.t ->
  Switch_name.t option ->
  (unit, [> Rresult.R.msg ]) result

type reinstall_mode = Quick | Full

val reinstall : Runner.t -> reinstall_mode -> (unit, [> Rresult.R.msg ]) result
