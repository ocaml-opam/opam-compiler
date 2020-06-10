(lang dune 2.5)
(name opam-compiler)
(generate_opam_files true)
(source
 (github emillon/opam-compiler))
(authors "Etienne Millon <me@emillon.org>")
(maintainers "Etienne Millon <me@emillon.org>")
(package
 (name opam-compiler)
 (tags (flags:plugin))
 (depends
  bos
  (alcotest :with-test)
  (mdx :with-test)))
