open! Import

let create switch_manager arg =
  let source = Source.parse_exn arg in
  let switch_name = Source.global_switch_name source in
  let description = Source.switch_description source in
  match
    Switch_manager.create_from_scratch switch_manager ~name:switch_name
      ~description
  with
  | Error `Unknown -> failwith "couldn't create switch"
  | Ok () ->
      Switch_manager.pin_add switch_manager ~name:switch_name
        (Source.git_url source)

let main () =
  match Sys.argv with
  | [| _; "create"; arg |] -> create Switch_manager.real arg
  | _ -> assert false
