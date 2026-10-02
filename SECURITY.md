<!-- the primary audience of this file are human reviewers of security issues, although this file could also be processed by automated tools -->
# Towards a threat model for the OCaml toolchain

Status: very early experiment

## Security goals

* the core compiler library will only interact with its environment as documented in the OCaml manual

* the functions and modules in the OCaml standard library behave only as documented in the OCaml manual. Unless documented to be unsafe, they are memory safe, and only raise documented exceptions.

## Desirable goals

(failures, to be evaluated on a case-by-case basis, updating these criteria as needed)

OCaml source code that does not contain any documented unsafe modules or functions, compiles to executable code that does not contain reachable memory safety issues at runtime.

## Assumptions

* the tools are invoked from a hygienic build environment: all build artifacts in compiler search paths have been produced by the same version of the compiler
* bytecode for the ocamlrun bytecode runtime is assumed to have been produced by a matching compiler version
* C stubs in the standard library are only invoked from OCaml code

## Components

* compiler tools: process supplied source code, trusted build artifacts and produce build artifacts
* OCaml language runtime
* OCaml standard library
* testsuites

## Out of scope

* the type system is not a security boundary

## Rationale

* Why the compiler library instead of the toolchain CLI(s)?

The compiler toolchain gets invoked from a build system, which enables arbitrary code execution by design if you control the source code (new rules can be added, the test suite can be modified). Therefore bugs that would allow arbitrary code execution when compiling a file are not considered security vulnerabilities in the CLI tools, they are regular bugs that should be reported as such.
However the compiler library is also used by Merlin/OCaml-LSP, and it'd be unexpected that by reading/inspecting source code you'd get arbitrary side-effects on the system.

* Hygienic build is the responsibility of the build system that invokes the toolchain. The compiler uses the marshal module to load build artifacts, so allowing these to be read from a source repository is unsafe.
This doesn't exclude chained attacks, where compiling source A produces some corrupted build artifact B, which is then used to perform an attack during the compilation of source C: this attack is reproducible with an entirely empty build directory and all you'd process is source code.

* Environment interaction

This assumes that it only reads and writes files as specified in the manual.
There are no assertions about the correctness of the output here. i.e. if the compiler produces code that behaves differently than the manual says, then that is a regular bug, not a security bug.

* the type system is meant to catch bugs, but it is not designed for handling malicious source code, and it is not meant as an absolute guarantee for verifying automatically generated code.
This is a hard theoretical problem to solve, and see https://counterexamples.org/ for previous bugs in OCaml and other language type systems.

* are compiler memory safety issues security bugs?

It depends. If the compiler always crashes, then that is equivalent to rejecting the input, which is safe. It is a bug that should be reported and fixed as usual.
If it only crashes sometimes, then it could form part of a targeted attack: pass cleanly on the CI, pass human review of the source code, and trigger the security bug only when executed by the target (with payload delivered separately).

