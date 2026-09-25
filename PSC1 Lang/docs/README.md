# ProofScript PSC1 Documentation

This directory is the **learning-oriented documentation** for PSC1.

It is intentionally separate from the normative language reference. The
language reference answers exact semantic and conformance questions; these
pages answer the more practical question:

> How do I learn, write, check, build, and reason about ordinary PSC1 code?

The organization follows a useful pattern found in the TypeScript documentation
corpus under `study/www.typescriptlang.org/docs/`: a landing page, short
audience-specific introductions, a progressive handbook, and separate reference
material. The content itself is PSC1-native and does not copy TypeScript's type
system or JavaScript assumptions.

## Choose a starting point

If you are completely new to ProofScript, start with:

- [ProofScript PSC1 from Scratch](./get-started/psc1-from-scratch.md)

If you already write TypeScript or JavaScript, start with:

- [PSC1 for TypeScript/JavaScript Programmers](./get-started/psc1-for-typescript-programmers.md)

If you already know Lean:

- [PSC1 for Lean Programmers](./get-started/psc1-for-lean-programmers.md)

If you only want the shortest useful tour:

- [PSC1 in 5 Minutes](./get-started/psc1-in-5-minutes.md)

For the compiler, project file, and normal workflow:

- [Tooling and Projects](./tooling-and-projects.md)

Then read the [PSC1 Handbook](../handbook/README.md) from top to bottom.

If you learn best from examples, exercises, and larger projects, use
[Eloquent ProofScript PSC1](../eloquent-proofscript/README.md). It progresses
from values and functions through a route-planning project, errors, parsing,
modules, effects, a tiny programming language, dependent types, and a tiny
compiler pipeline.

For a programming-first path modeled on the strongest ideas from Functional
Programming in Lean, use [Programming in ProofScript PSC1](../programming-in-proofscript/README.md).

For systematic proof development, use
[Theorem Proving in ProofScript PSC1](../theorem-proving-in-proofscript/README.md).

For detailed lookup by language category, use the
[PSC1 Language Manual](../language-manual/README.md).

## What these docs assume

PSC1 is a small dependently typed programming and verification language with:

- a TypeScript-friendly surface where that improves ordinary programming;
- Lean-compatible semantics where dependent types, propositions, proofs,
  recursion, typeclasses, and kernel acceptance matter;
- a single checked compiler path through pskernel;
- target-neutral executable semantics before TypeScript, Rust, or Wasm lowering.

PSC1 is not TypeScript with a theorem keyword added, and it is not merely a
different spelling of full Lean.

## Documentation map

### Getting started

Short introductions are optimized for different backgrounds. They explain the
same language from different starting assumptions instead of forcing every
reader through the same conceptual route.

### Handbook

The handbook is the comprehensive learning guide. It starts with ordinary
functions and data, then moves into generic and dependent programming, proofs,
recursion, effects, modules, FFI, and multi-backend portability.

The handbook is **not** the formal specification. It deliberately favors
explanations and representative examples over exhaustive parser rules.

### Reference

Use [../reference/README.md](../reference/README.md) when you already know what
you want and need exact command/configuration/surface information.

### Normative language reference

Use these when exact semantics or conformance boundaries matter:

- [../PSC1_LANGUAGE_REFERENCE.md](../PSC1_LANGUAGE_REFERENCE.md)
- [../SYNTAX_AND_GRAMMAR.md](../SYNTAX_AND_GRAMMAR.md)
- [../SEMANTICS_RUNTIME_AND_EFFECTS.md](../SEMANTICS_RUNTIME_AND_EFFECTS.md)
- [../CONFORMANCE_PORTABILITY_AND_STATUS.md](../CONFORMANCE_PORTABILITY_AND_STATUS.md)

## Reading status notes

Some PSC1 language capabilities are part of the first frozen language profile
but are still being closed by the self-host implementation. Advanced pages say
so explicitly.

A page may therefore distinguish:

- **language rule** — what PSC1 means;
- **current implementation** — what the repository currently executes;
- **open freeze work** — what still needs executable evidence before the first
  PSC1 freeze claim.

That distinction is deliberate. Documentation should not teach an accidental
backend behavior as language semantics merely because one implementation can
currently execute it.

## Suggested learning path

A practical progression is:

1. PSC1 in 5 Minutes
2. The Basics
3. Everyday Types
4. Functions
5. Data and Pattern Matching
6. Generics and Dependent Types
7. Propositions and Proofs
8. Recursion and Totality
9. Effects and `do`
10. Modules and Projects
11. Interop and FFI
12. Portability and Backends
13. Dual-source Lean Interop

At that point the normative reference should be comfortable rather than
intimidating.
