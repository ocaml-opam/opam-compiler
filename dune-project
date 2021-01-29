(lang dune 2.5)

(name opam-compiler)

(generate_opam_files true)

(source
 (github ocaml-opam/opam-compiler))

(license ISC)

(authors "Etienne Millon <me@emillon.org>")

(maintainers "Etienne Millon <me@emillon.org>")

(package
 (name opam-compiler)
 (synopsis "Plugin to create switches using custom compilers")
 (description
   "This plugin can manage switches using various sources for compilers, such as git branches, github PRs, etc")
 (depends
  (ocaml
   (>= 4.08.0))
  bos
  cmdliner
  curly
  github
  re
  (alcotest
   (and
    (>= 1.2.0)
    :with-test))))
