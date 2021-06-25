  $ opam-compiler reinstall --dry-run
  Run_out: OPAMCLI=2.0 opam config expand %{compiler-sources}%
  Run_out: OPAMCLI=2.0 opam config expand %{compiler-configure-command}%
  Run_out: OPAMCLI=2.0 opam config var prefix
  Run: cd $(OPAMCLI=2.0 opam config expand %{compiler-sources}%) && $(OPAMCLI=2.0 opam config expand %{compiler-configure-command}%) --prefix "$(OPAMCLI=2.0 opam config var prefix)"
  Run: cd $(OPAMCLI=2.0 opam config expand %{compiler-sources}%) && make
  Run: cd $(OPAMCLI=2.0 opam config expand %{compiler-sources}%) && make install
  Run: OPAMCLI=2.0 opam reinstall --assume-built --working-dir ocaml-variants

Quick can be passed:

  $ opam-compiler reinstall --dry-run --quick
  Run_out: OPAMCLI=2.0 opam config expand %{compiler-sources}%
  Run_out: OPAMCLI=2.0 opam config expand %{compiler-configure-command}%
  Run_out: OPAMCLI=2.0 opam config var prefix
  Run: cd $(OPAMCLI=2.0 opam config expand %{compiler-sources}%) && $(OPAMCLI=2.0 opam config expand %{compiler-configure-command}%) --prefix "$(OPAMCLI=2.0 opam config var prefix)"
  Run: cd $(OPAMCLI=2.0 opam config expand %{compiler-sources}%) && make
  Run: cd $(OPAMCLI=2.0 opam config expand %{compiler-sources}%) && make install

Full will reinstall opam packages (and is the default):

  $ opam-compiler reinstall --dry-run --full
  Run_out: OPAMCLI=2.0 opam config expand %{compiler-sources}%
  Run_out: OPAMCLI=2.0 opam config expand %{compiler-configure-command}%
  Run_out: OPAMCLI=2.0 opam config var prefix
  Run: cd $(OPAMCLI=2.0 opam config expand %{compiler-sources}%) && $(OPAMCLI=2.0 opam config expand %{compiler-configure-command}%) --prefix "$(OPAMCLI=2.0 opam config var prefix)"
  Run: cd $(OPAMCLI=2.0 opam config expand %{compiler-sources}%) && make
  Run: cd $(OPAMCLI=2.0 opam config expand %{compiler-sources}%) && make install
  Run: OPAMCLI=2.0 opam reinstall --assume-built --working-dir ocaml-variants

Switch name can be passed explicitly:

  $ opam-compiler reinstall --dry-run --switch NAME
  Run_out: OPAMCLI=2.0 opam config --switch NAME expand %{compiler-sources}%
  Run_out: OPAMCLI=2.0 opam config --switch NAME expand %{compiler-configure-command}%
  Run_out: OPAMCLI=2.0 opam config var prefix
  Run: cd $(OPAMCLI=2.0 opam config --switch NAME expand %{compiler-sources}%) && $(OPAMCLI=2.0 opam config --switch NAME expand %{compiler-configure-command}%) --prefix "$(OPAMCLI=2.0 opam config var prefix)"
  Run: cd $(OPAMCLI=2.0 opam config --switch NAME expand %{compiler-sources}%) && make
  Run: cd $(OPAMCLI=2.0 opam config --switch NAME expand %{compiler-sources}%) && make install
  Run: OPAMCLI=2.0 opam reinstall --assume-built --working-dir ocaml-variants
