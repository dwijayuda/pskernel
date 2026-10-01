# ProofScript PSC1 Language Manual

This manual is the lookup-oriented counterpart to the Lean Language Reference
studied under `study/lean4-language-reference/`.

It is not a tutorial. It organizes PSC1 by semantic category so implementers and
advanced users can answer questions such as:

- what stage owns this syntax?
- what does this declaration elaborate to?
- what reaches pskernel?
- what erases?
- what is portable across backends?
- what is an explicit host assumption?

For normative details, this manual delegates to the existing PSC1 reference
files when they are more exact.

## Contents

1. [Processing, Elaboration, and Trust](./01-processing-elaboration-and-trust.md)
2. [The Type System](./02-the-type-system.md)
3. [Source Files, Modules, and Names](./03-source-files-modules-and-names.md)
4. [Definitions and Declarations](./04-definitions-and-declarations.md)
5. [Terms and Expressions](./05-terms-and-expressions.md)
6. [Typeclasses and Instance Synthesis](./06-typeclasses-and-instances.md)
7. [Tactic Proofs](./07-tactic-proofs.md)
8. [Basic Propositions and Equality](./08-basic-propositions-and-equality.md)
9. [Basic Types and Collections](./09-basic-types-and-collections.md)
10. [Recursion, Partiality, and Effects](./10-recursion-partiality-and-effects.md)
11. [Runtime Code, FFI, and Portability](./11-runtime-ffi-and-portability.md)
12. [Validating Proofs and Assurance Claims](./12-validating-proofs-and-assurance.md)
13. [Language Extension Boundary](./13-language-extension-boundary.md)
14. [Build Tools and Distribution](./14-build-tools-and-distribution.md)

## Scope

The manual describes **PSC1**, not all of Lean 4.34 and not every historical
ProofScript proposal.

The active authority order remains:

1. executable repository gates/contracts;
2. current self-host/freeze plans;
3. PSC1 documents in this branch;
4. ProofScript v0.7 with v0.6.1 compatible compiler-ready baseline;
5. pinned Lean 4.34 semantics for supported dependent/proof behavior.

ProofScript v0.8 is not a normative PSC1 reference.

## Relationship to Lean's reference

The Lean Language Reference has major standalone areas for macros, custom
elaborators, IO, iterators, advanced tactics, coercions, attributes, and other
facilities.

PSC1 studies those systems but intentionally keeps many outside the first
language freeze.

This manual therefore documents the **boundary** as carefully as the supported
features.
