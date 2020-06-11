let exec cmd = Bos.OS.Cmd.run cmd |> Rresult.R.failwith_error_msg

type t = {
  create :
    name:Switch_name.t ->
    description:string ->
    (unit, [ `Unknown | `Switch_exists ]) result;
  remove : name:Switch_name.t -> (unit, [ `Unknown ]) result;
  pin_add : name:Switch_name.t -> string -> unit;
}

let real =
  let create ~name ~description =
    let create_cmd =
      let open Bos.Cmd in
      v "opam" % "switch" % "create" % Switch_name.to_string name % "--empty"
      % "--description" % description
    in
    Bos.OS.Cmd.run_status create_cmd |> Rresult.R.failwith_error_msg |> function
    | `Exited 0 -> Ok ()
    | `Exited 2 -> Error `Switch_exists
    | _ -> Error `Unknown
  in
  let remove ~name =
    Bos.OS.Cmd.run
      (let open Bos.Cmd in
      v "opam" % "switch" % "remove" % Switch_name.to_string name)
    |> function
    | Ok () -> Ok ()
    | Error _ -> Error `Unknown
  in
  let pin_add ~name url =
    exec
      (let open Bos.Cmd in
      v "opam" % "pin" % "add" % "--switch" % Switch_name.to_string name
      % "--yes" % "ocaml-variants" % url)
  in
  { create; remove; pin_add }

let create t = t.create

let remove t = t.remove

let pin_add t = t.pin_add

let create_from_scratch switch_manager ~name ~description =
  match create switch_manager ~name ~description with
  | Ok () -> Ok ()
  | Error `Switch_exists ->
      Rresult.R.bind (remove switch_manager ~name) (fun () ->
          create switch_manager ~name ~description
          |> Rresult.R.reword_error (fun _ -> `Unknown))
  | Error `Unknown as e -> e
