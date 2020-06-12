open! Import

let create switch_manager github_client source =
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

let update switch_manager source =
  let switch_name = Source.global_switch_name source in
  match Switch_manager.update switch_manager ~name:switch_name with
  | Error `Unknown -> failwith "couldn't update switch"
  | Ok () -> ()

let info switch_manager source =
  let switch_name = Source.global_switch_name source in
  match Switch_manager.info switch_manager ~name:switch_name with
  | Error `Unknown -> failwith "couldn't get info on switch"
  | Ok s -> print_endline s

module Op = struct
  type t = Create of Source.t | Update of Source.t | Info of Source.t

  let parse = function
    | [| _; "create"; arg |] ->
        option_map (fun s -> Create s) (Source.parse arg)
    | [| _; "update"; arg |] ->
        option_map (fun s -> Update s) (Source.parse arg)
    | [| _; "info"; arg |] -> option_map (fun s -> Info s) (Source.parse arg)
    | _ -> None

  let run op switch_manager github_client =
    match op with
    | Create s -> create switch_manager github_client s
    | Update s -> update switch_manager s
    | Info s -> info switch_manager s
end

let main () =
  match Op.parse Sys.argv with
  | Some op -> Op.run op Switch_manager.real Github_client.real
  | None -> assert false
