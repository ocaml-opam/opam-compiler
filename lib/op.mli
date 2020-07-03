val create :
  Runner.t -> Github_client.t -> Source.t -> (unit, [> Rresult.R.msg ]) result

val update : Runner.t -> Source.t -> (unit, [> Rresult.R.msg ]) result

val reinstall : Runner.t -> (unit, [> Rresult.R.msg ]) result
