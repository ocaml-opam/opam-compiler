open! Import

let create switch_manager github_client source =
  let switch_name = Source.global_switch_name source in
  let description = Source.switch_description source in
  let open Rresult.R in
  Switch_manager.create_from_scratch switch_manager ~name:switch_name
    ~description
  >>= (fun () ->
        Source.switch_target source github_client >>| fun url ->
        Switch_manager.pin_add switch_manager ~name:switch_name url)
  |> reword_error (fun `Unknown -> msgf "Cannot create switch")

let update switch_manager source =
  let open Rresult.R in
  let switch_name = Source.global_switch_name source in
  Switch_manager.update switch_manager ~name:switch_name
  |> reword_error (fun `Unknown -> msgf "Cannot update switch")

let info switch_manager source =
  let open Rresult.R in
  let switch_name = Source.global_switch_name source in
  Switch_manager.info switch_manager ~name:switch_name
  |> reword_error (fun `Unknown -> msgf "Could not get info about switch")
  |> map print_endline

type op =
  | Create of Source.t
  | Update of Source.t
  | Info of Source.t
  | Reinstall

let parse = function
  | [| _; "create"; arg |] -> Some (Create (Source.parse arg))
  | [| _; "update"; arg |] -> Some (Update (Source.parse arg))
  | [| _; "info"; arg |] -> Some (Info (Source.parse arg))
  | [| _; "reinstall" |] -> Some Reinstall
  | _ -> None

let reinstall switch_manager =
  let open Rresult.R in
  Switch_manager.reinstall switch_manager
  |> reword_error (fun `Unknown -> msgf "Could not reinstall")

let eval op switch_manager github_client =
  match op with
  | Create s -> create switch_manager github_client s
  | Update s -> update switch_manager s
  | Info s -> info switch_manager s
  | Reinstall -> reinstall switch_manager

let run op switch_manager github_client =
  eval op switch_manager github_client |> Rresult.R.failwith_error_msg

let main () =
  match parse Sys.argv with
  | Some op -> run op Switch_manager.real Github_client.real
  | None -> assert false
