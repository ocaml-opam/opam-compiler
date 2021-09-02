Configure calls configure with the right prefix.

  $ opam-compiler configure --dry-run
  Run_out: OPAMCLI=2.0 opam config var prefix
  Run: ./configure --prefix output

Anything after -- is passed to the configure command.

  $ opam-compiler configure --dry-run -- --xxx --yyy
  Run_out: OPAMCLI=2.0 opam config var prefix
  Run: ./configure --prefix output --xxx --yyy

Shorthand versions are supported.

  $ opam-compiler configure --dry-run --with afl
  Run_out: OPAMCLI=2.0 opam config var prefix
  Run: ./configure --prefix output --with-afl

It is possible to mix both.

  $ opam-compiler configure --dry-run --with afl -- --xxx --yyy
  Run_out: OPAMCLI=2.0 opam config var prefix
  Run: ./configure --prefix output --with-afl --xxx --yyy
