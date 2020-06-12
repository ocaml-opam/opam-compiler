type t = {
  pr_source_branch : Pull_request.t -> (Branch.t, [ `Unknown ]) result;
}

val pr_source_branch : t -> Pull_request.t -> (Branch.t, [ `Unknown ]) result

val real : t
