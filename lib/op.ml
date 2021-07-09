open! Import

let try_ r ~if_command_failed =
  match r with
  | Ok x -> Ok x
  | Error (`Command_failed _) as e ->
      let open Let_syntax.Result in
      let* () = if_command_failed () in
      e
  | Error _ as e -> e

let create runner github_client source switch_name ~configure_command =
  let switch_name =
    match switch_name with
    | Some s -> s
    | None -> Source.global_switch_name source
  in
  let description = Source.switch_description source github_client in
  let open Let_syntax.Result in
  (let* () = Opam.create runner ~name:switch_name ~description in
   let* url = Source.switch_target source github_client in
   let* () =
     try_ (Opam.pin_add runner ~name:switch_name url ~configure_command)
       ~if_command_failed:(fun () ->
         Opam.remove_switch runner ~name:switch_name)
   in
   Opam.set_base runner ~name:switch_name)
  |> translate_error "Cannot create switch"

type reinstall_mode = Quick | Full

let reinstall_packages_if_needed runner = function
  | Quick -> Ok ()
  | Full -> Opam.reinstall_packages runner

let reinstall runner mode ~configure_command =
  let open Let_syntax.Result in
  (let* () = Opam.reinstall_compiler runner ~configure_command in
   reinstall_packages_if_needed runner mode)
  |> translate_error "Could not reinstall"
