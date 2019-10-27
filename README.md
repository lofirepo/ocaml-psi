[![Build Status](https://travis-ci.org/p2pcollab/ocaml-psi.svg?branch=master)](https://travis-ci.org/p2pcollab/ocaml-psi)

# Private Set Intersection protocols

PSI is a collection of Private Set Intersection protocols.

The following PSI protocols are implemented:

- Naive Hash based PSI
- Bloom Filter based PSI as described in the paper
  [Do I know you? -- Efficient and Privacy-Preserving Common Friend-Finder Protocols and Applications](https://eprint.iacr.org/2013/620)

PSI is distributed under the AGPL-3.0-only license.

## Installation

``psi`` can be installed via `opam`:

    opam install psi

## Building

To build from source, generate documentation, and run tests, use `dune`:

    dune build
    dune build @doc
    dune runtest -f

In addition, the following `Makefile` targets are available
 as a shorthand for the above:

    make
    make build
    make doc
    make test

## Documentation

The documentation and API reference is generated from the source interfaces.
It can be consulted [online][doc] or via `odig`:

    odig doc psi

[doc]: https://p2pcollab.net/doc/ocaml/psi/
