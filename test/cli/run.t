Sources
=======

Sources can take several forms:

  $ $EXE info user/repo:branch
  source: Github_branch { user = "user"; repo = "repo"; branch = "branch" }

Branches can have dashes:

  $ $EXE info user/repo:my-great-branch
  source: Github_branch { user = "user"; repo = "repo"; branch = "my-great-branch" }

If repo is omitted, it defaults to ocaml:

  $ $EXE info user:branch
  source: Github_branch { user = "user"; repo = "ocaml"; branch = "branch" }

It can be a PR number:

  $ $EXE info 'user/repo#1234'
  source: Github_PR { user = "user"; repo = "repo"; number = 1234 }

Or when omitted, a PR against the main repo:

  $ $EXE info '#1234'
  source: Github_PR { user = "ocaml"; repo = "ocaml"; number = 1234 }

Creating and updating a switch
==============================

References can move; in that case the switch can be updated:

  $ $EXE update 'user:branch'
  Updating switch: "user:branch"
  Resolving to Github_commit { user = "user"; repo = "ocaml"; hash = ? }
  Updating opam switch named "user:branch" based in Github_commit { user = "user"; repo = "ocaml"; hash = ? }
