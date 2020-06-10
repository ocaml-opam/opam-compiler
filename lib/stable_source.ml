type t = Github_commit of { user : string; repo : string; hash : unit }

let pp ppf = function
  | Github_commit { user; repo; hash = () } ->
      Format.fprintf ppf "Github_commit { user = %S; repo = %S; hash = ? }" user
        repo
