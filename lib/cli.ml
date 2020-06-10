open! Import

let info arg =
  let source = Source.parse_exn arg in
  Format.printf "source: %a\n" Source.pp source

let update_opam_switch ~name stable_source =
  Format.printf "Updating opam switch named %S based in %a" name
    Stable_source.pp stable_source

let update arg =
  Format.printf "Updating switch: %S\n" arg;
  let source = Source.parse_exn arg in
  let stable_source = Source.resolve source in
  Format.printf "Resolving to %a\n" Stable_source.pp stable_source;
  update_opam_switch ~name:arg stable_source

let create switch_manager arg =
  let source = Source.parse_exn arg in
  let switch_name = Source.global_switch_name source in
  assert (not (String.contains switch_name '/'));
  assert (not (String.contains switch_name ':'));
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
  | [| _; "info"; arg |] -> info arg
  | [| _; "update"; arg |] -> update arg
  | [| _; "create"; arg |] -> create Switch_manager.real arg
  | _ -> assert false
