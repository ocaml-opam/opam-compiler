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
  (let* () = Opam.create runner switch_name ~description in
   let* url = Source.switch_target source github_client in
   let* () =
     try_ (Opam.pin_add runner switch_name url ~configure_command)
       ~if_command_failed:(fun () -> Opam.remove_switch runner switch_name)
   in
   Opam.set_base runner switch_name)
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

let configure runner args =
  let open Let_syntax.Result in
  (let* prefix = Opam.get_prefix runner in
   let cmd = Bos.Cmd.(v "./configure" % "--prefix" % prefix %% of_list args) in
   Runner.run runner cmd)
  |> translate_error "Could not configure"

let file_exists runner path =
  let cmd =
    Bos.Cmd.(
      v "grep" % "-q" % "-e" % "prefix=.*_opam" % "-e" % "prefix=.*\\.opam"
      % path)
  in
  match Runner.run runner cmd with
  | Ok () -> Ok true
  | Error (`Command_failed _) -> Ok false
  | Error _ as e -> e

let install runner =
  let open Let_syntax.Result in
  (let* exists = file_exists runner "Makefile.config" in
   if not exists then Error `Configure_needed
   else
     let cmd = Bos.Cmd.(v "make" % "install") in
     Runner.run runner cmd)
  |> translate_error "Could not install"
