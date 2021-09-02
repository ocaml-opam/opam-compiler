  $ opam-compiler install --dry-run
  Run: grep -q -e prefix=.*_opam -e prefix=.*\.opam Makefile.config
  Run: make install

"install" checks for a Makefile.config file.
If it does not exist, it prints an error:

  $ cat > Makefile <<EOF
  > .PHONY: install
  > install:
  > 	@echo installed
  > EOF

  $ opam-compiler install
  grep: Makefile.config: No such file or directory
  Fatal error: exception Failure("Could not install - configure step is required")
  [2]

If it exists, it is inspected. The prefix is expected to point at an opam
switch.

Global switches are recognized:

  $ echo 'prefix=/home/me/.opam/name' > Makefile.config
  $ opam-compiler install
  installed

Local switches are recognized:

  $ echo 'prefix=/home/me/src/project/_opam' > Makefile.config
  $ opam-compiler install
  installed

If prefix is something else, an error message is displayed:

  $ echo 'prefix=/usr/local/lib' > Makefile.config
  $ opam-compiler install
  Fatal error: exception Failure("Could not install - configure step is required")
  [2]
