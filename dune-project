(lang dune 2.7)

(name opam-compiler)

(cram enable)

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
  (cmdliner
   (>= 1.1.0))
  (cmdliner
   (and
   (>= 1.2.0)
   :with-test))
  (curly
   (>= 0.2.0))
  (either :with-test)
  github-data
  (ocaml-version
   (>= 3.0.0))
  re
  (rresult
   (>= 0.6.0))
  (alcotest
   (and
    (>= 1.2.0)
    :with-test)))
 (conflicts
  (result (< 1.5))))
