opam-compiler
=============

A WIP opam plugin to manage compiler installations.

It can be used to create switches from various sources such as the main
repository, ocaml-multicore, or a local directories. It can use tag names,
branch names, or PR numbers to specify what to install.

Once installed, these are normal opam switches, and one can install packages in
them. To iterate on a compiler feature and try opam packages at the same time,
it supports to ways to reinstall the compiler: either a safe and slow technique
that will reinstall all packages, or a quick way that will just overwrite the
compiler in place.
