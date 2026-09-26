# Introduction

Programming is the work of expressing a process precisely enough that a
machine can execute it.

ProofScript adds another question:

> Can we express enough of the *reason* the program is correct that a small
> checker can verify it?

That does not mean every line must be a theorem.

Most PSC1 code is ordinary programming.

```proofscript
function square(x: Nat): Nat :=
  x * x;
```

But when an invariant matters, the same language can state it.

```proofscript
theorem squareSelf(x: Nat):
square(x) = x * x := by rfl;
```

## Why language design matters

Low-level representations expose details.

Higher-level abstractions let us name the concept we actually care about.

For example, a hand-written recursive traversal may be correct, but once a
general `listMap` exists, a transformation is clearer when written as a map.

```proofscript
function incrementAll(xs: PsList(Nat)): PsList(Nat) :=
  listMap(fun x => x + 1, xs);
```

The language and library should help us say *what* the program means without
hiding important correctness assumptions.

## PSC1 in one paragraph

PSC1 is a small general-purpose language with:

- TypeScript-friendly surface conventions;
- Lean-compatible dependent/proof semantics for the supported core;
- a pskernel-checked logical boundary;
- a target-neutral executable IR;
- TypeScript/JavaScript, Rust, and WebAssembly backend goals.

It is neither JavaScript with proof keywords nor full Lean with different
punctuation.

## Running code

A normal project starts with:

```bash
psc init hello
cd hello
psc check
psc build
psc run -- 5
```

The generated project contains a `psconfig.json` and a `.ps` entry source.

## Checking and running are different claims

`psc check` establishes that the supported source elaborates and passes
pskernel admission.

`psc build` then erases proof-only information and lowers executable meaning.

`psc run` invokes the generated program.

This distinction matters throughout the book.

## Read code actively

The best way to use this book is to:

1. type the examples;
2. change them;
3. deliberately break them;
4. read the diagnostics;
5. solve the exercises;
6. inspect canonical Lean or generated target code when useful.

PSC1 is easiest to understand when its programming and proof feedback are seen
together.

## The route through the book

The first six chapters build a programming vocabulary.

Chapter 7 combines it into a persistent route-planning project.

Chapters 8–11 focus on reliability, text, modules, and effects.

Chapter 12 builds a tiny programming language—an especially useful exercise for
understanding PSC1 because ProofScript itself must eventually compile itself.

The final part introduces the dependent/proof/portability ideas that distinguish
PSC1 from ordinary typed languages.
