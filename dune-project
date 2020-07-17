(lang dune 2.5)

(name opam-compiler)

(generate_opam_files true)

(source
 (github ocaml-opam/opam-compiler))

(authors "Etienne Millon <me@emillon.org>")

(maintainers "Etienne Millon <me@emillon.org>")

(package
 (name opam-compiler)
 (synopsis "Plugin to create switches using custom compilers")
 (tags (flags:plugin))
 (depends
  (ocaml
   (>= 4.08.0))
  bos
  cmdliner
  github-unix
  lwt_ssl
  re
  (alcotest
   (and
    (>= 1.2.0)
    :with-test))))
