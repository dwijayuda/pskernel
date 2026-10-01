# The ProofScript PSC1 Handbook

The PSC1 Handbook is the main learning guide for everyday ProofScript
programmers.

It is designed to be read in order, but each chapter can also stand alone once
you know the basics.

## What this handbook is

This handbook aims to explain all major PSC1 language ideas in a way that is
practical for programmers.

By the end, you should be able to:

- read ordinary PSC1 source;
- write typed functions and data;
- understand generic and dependent function types;
- read and write simple theorems;
- understand how tactics relate to proof terms;
- reason about recursion and executable partiality;
- use explicit effects without importing host semantics;
- structure multi-module projects;
- understand npm/host interoperability boundaries;
- understand why the same source can target JavaScript, Rust, and Wasm;
- understand the relationship between `.ps` and supported `.lean`.

## What this handbook is not

It is not:

- the formal language specification;
- an exhaustive Lean reference;
- a promise that every described advanced capability has identical
  implementation maturity today;
- a replacement for the conformance/status documents.

For exact semantics use:

- [../PSC1_LANGUAGE_REFERENCE.md](../PSC1_LANGUAGE_REFERENCE.md)
- [../SYNTAX_AND_GRAMMAR.md](../SYNTAX_AND_GRAMMAR.md)
- [../SEMANTICS_RUNTIME_AND_EFFECTS.md](../SEMANTICS_RUNTIME_AND_EFFECTS.md)

## Structure

### Core programming

1. [The Basics](./01-the-basics.md)
2. [Everyday Types](./02-everyday-types.md)
3. [Functions](./03-functions.md)
4. [Data and Pattern Matching](./04-data-and-pattern-matching.md)

### Type system and verification

5. [Generics and Dependent Types](./05-generics-and-dependent-types.md)
6. [Propositions and Proofs](./06-propositions-and-proofs.md)
7. [Typeclasses and Instances](./07-typeclasses-and-instances.md)
8. [Recursion and Totality](./08-recursion-and-totality.md)

### Effects, projects, and ecosystem

9. [Effects and `do`](./09-effects-and-do.md)
10. [Modules and Projects](./10-modules-and-projects.md)
11. [Interop and FFI](./11-interop-and-ffi.md)

### Portability and source interoperability

12. [Portability and Backends](./12-portability-and-backends.md)
13. [Dual-source Lean Interop](./13-dual-source-lean-interop.md)

## A note about examples

Examples are chosen from the frozen PSC1 design and from syntax already
dogfooded by the repository where practical.

Some advanced examples explain a language capability whose self-host
implementation is still being closed. Those chapters call that out.

When current executable coverage is narrower than the language rule, the
narrower implementation status wins for claims about what works **today**.

## A note about Lean

Lean 4.34 is the semantic reference for the supported dependent/proof core.

That does not mean:

```text
valid Lean source == valid PSC1 source
```

PSC1 is deliberately smaller and fail-closed.

## A note about TypeScript

TypeScript strongly influences PSC1's developer-experience goals and JavaScript
ecosystem integration, but TypeScript is not the proof-semantic authority.

Generated TypeScript is downstream of checked semantics.

## A note about notation

Three symbols deserve immediate attention:

```text
:=   defines/binds
=    proposition equality
==   Bool equality
```

Confusing them is one of the easiest ways to import the wrong mental model.
