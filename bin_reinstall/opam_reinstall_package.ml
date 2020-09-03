let remove_files files =
  List.fold_left
    (fun acc file ->
      let open OpamProcess.Job.Op in
      OpamProcess.command "rm" [ file ] @@> fun _result -> acc)
    (Done ()) files

let install_job ~install_cmd () =
  let open OpamProcess.Job.Op in
  let cmd, args = install_cmd in
  OpamProcess.command cmd args @@> fun _result -> Done ()

let track ~root ~switch job =
  let open OpamProcess.Job.Op in
  let switch_prefix = OpamPath.Switch.root root switch in
  OpamDirTrack.track switch_prefix job @@| fun ((), changes) -> changes

let all =
  List.fold_left
    (fun acc xo ->
      match (acc, xo) with
      | None, _ -> None
      | Some _, None -> None
      | Some xs, Some x -> Some (x :: xs))
    (Some [])

let installed_files switch_root changes_file =
  match OpamFile.Changes.read_opt changes_file with
  | None -> None
  | Some c ->
      OpamDirTrack.check switch_root c
      |> List.map (function
           | file, `Unchanged -> Some (OpamFilename.to_string file)
           | _, `Changed -> None
           | _, `Removed -> None)
      |> all

let main { OpamStateTypes.root; _ } ~switch ~package_name ~install_cmd =
  let changes_file = OpamPath.Switch.changes root switch package_name in
  let switch_root = OpamPath.Switch.root root switch in
  let installed_files =
    match installed_files switch_root changes_file with
    | Some l -> l
    | None -> failwith "Cannot get installed files"
  in
  let changes =
    OpamProcess.Job.run
      (let open OpamProcess.Job.Op in
      remove_files installed_files @@+ fun () ->
      track ~root ~switch (install_job ~install_cmd))
  in
  OpamFile.Changes.write changes_file changes

let () =
  match Array.to_list Sys.argv with
  | _ :: switch_name :: package_name :: install_cmd :: install_cmd_args ->
      let package_name = OpamPackage.Name.of_string package_name in
      let switch = OpamSwitch.of_string switch_name in
      let install_cmd = (install_cmd, install_cmd_args) in
      OpamGlobalState.with_ `Lock_none (main ~switch ~package_name ~install_cmd)
  | _ -> assert false
