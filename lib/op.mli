val create :
  Runner.t ->
  Github_client.t ->
  Source.t ->
  Switch_name.t option ->
  (unit, [> Rresult.R.msg ]) result

val reinstall : Runner.t -> (unit, [> Rresult.R.msg ]) result
