By default, the switch name is inferred from the branch:

  $ opam-compiler create --dry-run USER/REPO:BRANCH
  Run: OPAMCLI=2.0 opam switch create USER-REPO-BRANCH --empty --description "[opam-compiler] USER/REPO:BRANCH"
  Run: OPAMCLI=2.0 opam pin add --switch USER-REPO-BRANCH --yes ocaml-variants git+https://github.com/USER/REPO#BRANCH

It can also be set explicitly:

  $ opam-compiler create --dry-run USER/REPO:BRANCH --switch SWITCH-NAME
  Run: OPAMCLI=2.0 opam switch create SWITCH-NAME --empty --description "[opam-compiler] USER/REPO:BRANCH"
  Run: OPAMCLI=2.0 opam pin add --switch SWITCH-NAME --yes ocaml-variants git+https://github.com/USER/REPO#BRANCH

Github PR numbers are also accepted:

  $ opam-compiler create --dry-run '#1234'
  Run: OPAMCLI=2.0 opam switch create ocaml-ocaml-1234 --empty --description "[opam-compiler] ocaml/ocaml#1234 - Title of ocaml-ocaml-1234"
  Run: OPAMCLI=2.0 opam pin add --switch ocaml-ocaml-1234 --yes ocaml-variants git+https://github.com/user-ocaml-ocaml-1234/repo-ocaml-ocaml-1234#branch-ocaml-ocaml-1234

An explicit configure step can be passed:

  $ opam-compiler create --dry-run USER/REPO:BRANCH --configure-command "./configure --enable-x"
  Run: OPAMCLI=2.0 opam switch create USER-REPO-BRANCH --empty --description "[opam-compiler] USER/REPO:BRANCH"
  Run: OPAMEDITOR=sed -i -e 's#"./configure"#"./configure" "--enable-x"#g' OPAMCLI=2.0 opam pin add --switch USER-REPO-BRANCH --yes ocaml-variants git+https://github.com/USER/REPO#BRANCH --edit
