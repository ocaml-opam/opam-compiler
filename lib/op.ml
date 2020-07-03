let create runner github_client source switch_name =
  let switch_name =
    match switch_name with
    | Some s -> s
    | None -> Source.global_switch_name source
  in
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
