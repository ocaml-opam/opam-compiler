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

let track (t : _ OpamStateTypes.switch_state) job =
  let open OpamProcess.Job.Op in
  let switch_prefix = OpamPath.Switch.root t.switch_global.root t.switch in
  OpamDirTrack.track switch_prefix job @@| fun ((), changes) -> changes

let with_state ~switch f =
  OpamGlobalState.with_ `Lock_read (fun global_state ->
      OpamSwitchState.with_ `Lock_read global_state ~switch f)

let main (t : _ OpamStateTypes.switch_state) ~package_name ~install_cmd =
  let changes_f =
    OpamPath.Switch.changes t.switch_global.root t.switch package_name
  in
  let switch_root = OpamPath.Switch.root t.switch_global.root t.switch in
  let installed_files =
    match OpamFile.Changes.read_opt changes_f with
    | None -> []
    | Some c ->
        OpamDirTrack.check switch_root c
        |> List.map (fun (file, _status) -> OpamFilename.to_string file)
  in
  Printf.printf "Removing %d files\n" (List.length installed_files);
  let changes =
    OpamProcess.Job.run
      (let open OpamProcess.Job.Op in
      remove_files installed_files @@+ fun () ->
      track t (install_job ~install_cmd))
  in
  print_endline (OpamDirTrack.to_string changes);
  OpamFile.Changes.write changes_f changes

let () =
  match Array.to_list Sys.argv with
  | _ :: switch_name :: package_name :: install_cmd :: install_cmd_args ->
      let package_name = OpamPackage.Name.of_string package_name in
      let switch = OpamSwitch.of_string switch_name in
      let install_cmd = (install_cmd, install_cmd_args) in
      with_state ~switch (main ~package_name ~install_cmd)
  | _ -> assert false
