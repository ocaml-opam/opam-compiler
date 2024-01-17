By default, the switch name is inferred from the branch:

  $ opam-compiler create --dry-run USER/REPO:BRANCH
  Run: OPAMCLI=2.0 opam switch create USER-REPO-BRANCH --empty --description "[opam-compiler] USER/REPO:BRANCH"
  Run: OPAMCLI=2.0 opam pin add --switch USER-REPO-BRANCH --yes ocaml-variants git+https://github.com/USER/REPO#BRANCH
  Run: OPAMCLI=2.0 opam switch set-base --switch USER-REPO-BRANCH ocaml-variants

It can also be set explicitly:

  $ opam-compiler create --dry-run USER/REPO:BRANCH --switch SWITCH-NAME
  Run: OPAMCLI=2.0 opam switch create SWITCH-NAME --empty --description "[opam-compiler] USER/REPO:BRANCH"
  Run: OPAMCLI=2.0 opam pin add --switch SWITCH-NAME --yes ocaml-variants git+https://github.com/USER/REPO#BRANCH
  Run: OPAMCLI=2.0 opam switch set-base --switch SWITCH-NAME ocaml-variants

Github PR numbers are also accepted:

  $ opam-compiler create --dry-run '#1234'
  Run: OPAMCLI=2.0 opam switch create ocaml-ocaml-1234 --empty --description "[opam-compiler] ocaml/ocaml#1234 - Title of ocaml-ocaml-1234"
  Run: OPAMCLI=2.0 opam pin add --switch ocaml-ocaml-1234 --yes ocaml-variants git+https://github.com/user-ocaml-ocaml-1234/repo-ocaml-ocaml-1234#branch-ocaml-ocaml-1234
  Run: OPAMCLI=2.0 opam switch set-base --switch ocaml-ocaml-1234 ocaml-variants

An explicit configure step can be passed:

  $ opam-compiler create --dry-run USER/REPO:BRANCH --configure-command "./configure --enable-x"
  Run: OPAMCLI=2.0 opam switch create USER-REPO-BRANCH --empty --description "[opam-compiler] USER/REPO:BRANCH"
  Run: OPAMEDITOR=sed -i -e 's#"./configure"#"./configure" "--enable-x"#g' OPAMCLI=2.0 opam pin add --switch USER-REPO-BRANCH --yes ocaml-variants git+https://github.com/USER/REPO#BRANCH --edit
  Run: OPAMCLI=2.0 opam switch set-base --switch USER-REPO-BRANCH ocaml-variants

Known variants can be supported using --with:

  $ opam-compiler create --dry-run USER/REPO:BRANCH --with afl
  Run: OPAMCLI=2.0 opam switch create USER-REPO-BRANCH --empty --description "[opam-compiler] USER/REPO:BRANCH"
  Run: OPAMEDITOR=sed -i -e 's#"./configure"#"./configure" "--with-afl"#g' OPAMCLI=2.0 opam pin add --switch USER-REPO-BRANCH --yes ocaml-variants git+https://github.com/USER/REPO#BRANCH --edit
  Run: OPAMCLI=2.0 opam switch set-base --switch USER-REPO-BRANCH ocaml-variants

Several of them can be specified:

  $ opam-compiler create --dry-run USER/REPO:BRANCH --with flambda,nnp
  Run: OPAMCLI=2.0 opam switch create USER-REPO-BRANCH --empty --description "[opam-compiler] USER/REPO:BRANCH"
  Run: OPAMEDITOR=sed -i -e 's#"./configure"#"./configure" "--enable-flambda" "--disable-naked-pointers"#g' OPAMCLI=2.0 opam pin add --switch USER-REPO-BRANCH --yes ocaml-variants git+https://github.com/USER/REPO#BRANCH --edit
  Run: OPAMCLI=2.0 opam switch set-base --switch USER-REPO-BRANCH ocaml-variants

A proper error message is displayed if a variant is not recognized:

  $ opam-compiler create --dry-run USER/REPO:BRANCH --with something
  opam-compiler: option '--with': invalid element in list ('something'):
                 Unknown variant.
  Usage: opam-compiler create [OPTION]… SOURCE
  Try 'opam-compiler create --help' or 'opam-compiler --help' for more information.
  [124]

It is not possible to mix --configure-command and --with:

  $ opam-compiler create --dry-run USER/REPO:BRANCH --configure-command "./configure --enable-x" --with afl
  opam-compiler: --configure-command and --with cannot be passed together.
  [124]
