type t = Create of Source.t | Update of Source.t | Reinstall

let create runner github_client source =
  let switch_name = Source.global_switch_name source in
  let description = Source.switch_description source in
  let open Rresult.R in
  Opam.create_from_scratch runner ~name:switch_name ~description
  >>= (fun () ->
        Source.switch_target source github_client >>= fun url ->
        Opam.pin_add runner ~name:switch_name url)
  |> reword_error (fun `Unknown -> msgf "Cannot create switch")

let update runner source =
  let open Rresult.R in
  let switch_name = Source.global_switch_name source in
  Opam.update runner ~name:switch_name
  |> reword_error (fun `Unknown -> msgf "Cannot update switch")

let reinstall runner =
  let open Rresult.R in
  Opam.reinstall runner
  |> reword_error (fun `Unknown -> msgf "Could not reinstall")

let eval op runner github_client =
  match op with
  | Create s -> create runner github_client s
  | Update s -> update runner s
  | Reinstall -> reinstall runner
