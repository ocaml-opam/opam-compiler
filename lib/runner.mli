type t = {
  run :
    ?extra_env:(string * string) list ->
    ?chdir:Fpath.t ->
    Bos.Cmd.t ->
    (unit, [ `Command_failed of Bos.Cmd.t | `Unknown ]) result;
  run_out :
    ?extra_env:(string * string) list ->
    Bos.Cmd.t ->
    (string, [ `Command_failed of Bos.Cmd.t | `Unknown ]) result;
}

val real : t

val dry_run : t

val run :
  t ->
  ?extra_env:(string * string) list ->
  ?chdir:Fpath.t ->
  Bos.Cmd.t ->
  (unit, [> `Command_failed of Bos.Cmd.t | `Unknown ]) result

val run_out :
  t ->
  ?extra_env:(string * string) list ->
  Bos.Cmd.t ->
  (string, [> `Command_failed of Bos.Cmd.t | `Unknown ]) result
