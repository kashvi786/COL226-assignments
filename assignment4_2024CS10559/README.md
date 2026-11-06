# Assignment 4: Simple Stack Evaluator for Combinatory Logic

## Overview

- Lambda calculus terms (`lam`) and combinatory logic terms (`comb`) are defined in OCaml.
- `abs` translates lambda terms to combinators using `abstc` (I/K/S basis).
- `wnf` and `unstack` implement the stack-based evaluator and return a weak normal form.
- `test.ml` contains hand-built lambda terms (including Church numerals) and prints the resulting combinator term.

## Build, run, clean

- Build: `make`
- Run tests: `make run`
- Clean: `make clean`

Requires an OCaml toolchain with `ocamlc` available in `PATH`.
