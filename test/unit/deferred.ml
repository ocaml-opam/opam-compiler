type t = (unit -> unit) list ref

let run r f = r := f :: !r

let with_ f =
  let r = ref [] in
  f r;
  List.iter (fun f -> f ()) !r

let test_case (name, speed, run_d) =
  let run_unit () = with_ run_d in
  (name, speed, run_unit)
