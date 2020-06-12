open! Import

let create switch_manager github_client arg =
  let source = Source.parse_exn arg in
  let switch_name = Source.global_switch_name source in
  let description = Source.switch_description source in
  let open Rresult.R in
  let r =
    Switch_manager.create_from_scratch switch_manager ~name:switch_name
      ~description
    >>= fun () ->
    Source.git_url source github_client >>| fun url ->
    Switch_manager.pin_add switch_manager ~name:switch_name url
  in
  match r with
  | Error `Unknown -> failwith "couldn't create switch"
  | Ok () -> ()

let update switch_manager arg =
  let source = Source.parse_exn arg in
  let switch_name = Source.global_switch_name source in
  match Switch_manager.update switch_manager ~name:switch_name with
  | Error `Unknown -> failwith "couldn't update switch"
  | Ok () -> ()

let info switch_manager arg =
  let source = Source.parse_exn arg in
  let switch_name = Source.global_switch_name source in
  match Switch_manager.info switch_manager ~name:switch_name with
  | Error `Unknown -> failwith "couldn't get info on switch"
  | Ok s -> print_endline s

let main () =
  match Sys.argv with
  | [| _; "create"; arg |] -> create Switch_manager.real Github_client.real arg
  | [| _; "update"; arg |] -> update Switch_manager.real arg
  | [| _; "info"; arg |] -> info Switch_manager.real arg
  | _ -> assert false
