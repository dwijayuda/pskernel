# Programming in ProofScript PSC1

This book is the PSC1 counterpart to the programming-oriented material studied
under `study/functional_programming_in_lean/`.

It teaches ProofScript primarily as a **programming language**, introducing
proofs exactly where they make programs safer, more precise, or easier to
optimize.

It is intentionally not a translation of *Functional Programming in Lean*.
PSC1 has a smaller source language, a different project/tooling story, an
explicit multi-backend architecture, and a deliberately bounded proof/tactic
surface.

## Reading order

1. [Getting to Know PSC1](./01-getting-to-know-psc1.md)
2. [Projects and Programs](./02-projects-and-programs.md)
3. [Propositions, Proofs, and Safe Indexing](./03-propositions-proofs-and-indexing.md)
4. [Overloading and Typeclasses](./04-overloading-and-typeclasses.md)
5. [Effects and `do`](./05-effects-and-do.md)
6. [Programming with Dependent Types](./06-programming-with-dependent-types.md)
7. [Programming, Proving, and Performance](./07-programming-proving-and-performance.md)
8. [Next Steps](./08-next-steps.md)

## The central PSC1 programming model

Ordinary PSC1 code is expected to look small and direct:

```proofscript
function double(x: Nat): Nat :=
  x + x;
```

But it is checked through a stronger semantic pipeline:

```text
source
-> parser
-> Meta/Elab
-> pskernel
-> CheckedCore
-> Erasure
-> VerifiedIR
-> backend
```

This gives PSC1 two useful faces:

- a general-purpose typed programming language;
- a proof-capable language whose types can express program invariants.

## How this differs from Lean's programming book

The Lean material devotes substantial space to general monads, applicative
functors, transformer stacks, IO, coercions, indexing notation, and a broad
standard library.

PSC1 learns from those mechanisms but keeps the first language freeze smaller:

- one concrete compiler reader/state/error effect is sufficient for self-hosting;
- generic transformer stacks are library/future work, not language blockers;
- host IO is an explicit capability boundary;
- syntax extension is closed rather than arbitrary;
- TypeScript, Rust, and Wasm are downstream targets of the same VerifiedIR;
- only the bounded language/theorem features claimed by PSC1 are taught as
  current PSC1.

## Examples and implementation status

Examples prefer source shapes already used in the repository's PSC1 stdlib and
self-host compiler plans.

Where the semantic idea is part of PSC1 but source/stdlib closure is still
under active self-host work, the chapter says so explicitly.

For exact conformance use:

- [../PSC1_LANGUAGE_REFERENCE.md](../PSC1_LANGUAGE_REFERENCE.md)
- [../CONFORMANCE_PORTABILITY_AND_STATUS.md](../CONFORMANCE_PORTABILITY_AND_STATUS.md)
