# Introduction

Programming languages are tools for leaving unimportant detail behind.

PSC1 adds one more kind of detail that can be removed from the programmer's
head: facts that the type checker and proof checker can establish once and then
carry for the rest of the program.

A PSC1 program can be ordinary:

```proofscript
function double(x: Nat): Nat :=
  x + x;
```

or it can expose a stronger contract:

```proofscript
function safeGet {α: Type}
(xs: Array(α), index: Nat, h: index < Array.size(xs)): α :=
  Array.getInternal(xs, index, h);
```

Both are programs. The second carries evidence about a condition that would
otherwise be a runtime concern.

## Why the language matters

PSC1 is designed around a deliberate division:

```text
friendly source
    ↓
Lean-compatible elaborated meaning
    ↓
pskernel
    ↓
target-neutral executable meaning
    ↓
TypeScript / Rust / Wasm
```

This means a surface convenience is allowed to be pleasant without becoming a
new semantic system.

For example:

```proofscript
function add(x: Nat, y: Nat): Nat := x + y;
```

is friendlier to a TypeScript programmer than the corresponding Lean source,
but it does not invent JavaScript function semantics.

## Programs are expressions plus names

PSC1 is expression-oriented.

You build larger programs by:

- naming values;
- naming functions;
- composing functions;
- defining data;
- matching data;
- importing modules;
- stating invariants;
- proving the invariants that matter.

The book avoids teaching a statement-heavy mutable style first because that is
not the smallest stable PSC1 core.

## The first habit: run the checker

Create a small project:

```bash
psc init eloquent-psc1
cd eloquent-psc1
psc check
```

Then change the program and check again.

A language with a strong checker is learned partly by reading what it rejects.

## The second habit: separate language from host

A browser can draw pixels.

Node can open files.

npm can load packages.

Rust can allocate memory in ways JavaScript cannot.

Wasm has its own numeric instructions and memory models.

None of those facts should silently become the definition of a PSC1 value.

This distinction becomes increasingly important in Part II.

## The third habit: use proofs where they pay rent

Not every function needs a theorem.

Use proofs when they improve something concrete:

- a boundary check;
- a parser invariant;
- a transformation law;
- a compiler pass;
- a recursion argument;
- a public API contract.

PSC1 is meant to let ordinary programming and theorem proving meet where doing
so reduces uncertainty.

## Exercises

1. Initialize a PSC1 application and make `main` return its Nat argument plus
   one.
2. Change the result type to `Bool` without changing the body. Read the error.
3. Restore the program and emit canonical Lean. Identify the corresponding
   definition and function application.
