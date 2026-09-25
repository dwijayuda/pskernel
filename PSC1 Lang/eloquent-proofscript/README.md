# Eloquent ProofScript PSC1

This book is a programming-first introduction to ProofScript PSC1.

Its pedagogical structure is inspired by the strongest ideas in *Eloquent
JavaScript, 4th edition*: begin with values and expressions, build functions
and data structures, introduce abstraction through higher-order functions,
interrupt the conceptual chapters with substantial projects, then confront
errors, modules, effects, and language implementation.

The content itself is PSC1-native.

It does **not** import JavaScript semantics such as:

- implicit coercion;
- mutable object identity as the default data model;
- prototypes or `this`;
- exceptions as the portable error model;
- promises/event-loop scheduling as source semantics;
- unrestricted loops and mutation;
- browser DOM APIs.

## How to read this book

The chapters are meant to be read in order and typed into a real PSC1 project.

Each chapter contains:

- a small set of language ideas;
- compact examples;
- a practical design lesson;
- exercises.

Project chapters combine several earlier ideas into a larger program.

## Contents

### Part I — The Language

1. [Values, Types, and Operators](./01-values-types-and-operators.md)
2. [Program Structure](./02-program-structure.md)
3. [Functions](./03-functions.md)
4. [Data Structures](./04-data-structures.md)
5. [Higher-Order Functions](./05-higher-order-functions.md)
6. [Abstraction with Data and Typeclasses](./06-abstraction.md)
7. [Project: A Delivery Planner](./07-project-delivery-planner.md)

### Part II — Building Reliable Programs

8. [Bugs, Errors, and Proof Failures](./08-bugs-errors-and-proof-failures.md)
9. [Text, Unicode, and Parsing](./09-text-unicode-and-parsing.md)
10. [Modules and Packages](./10-modules-and-packages.md)
11. [Effects and Host Capabilities](./11-effects-and-host-capabilities.md)
12. [Project: A Tiny Typed Language](./12-project-tiny-typed-language.md)

### Part III — What Makes PSC1 Different

13. [Propositions and Proofs](./13-propositions-and-proofs.md)
14. [Dependent Types](./14-dependent-types.md)
15. [Interop and Portability](./15-interop-and-portability.md)
16. [Project: A Tiny Compiler Pipeline](./16-project-tiny-compiler.md)

Then use:

- [Exercise Hints](./EXERCISE_HINTS.md)
- [PSC1 Handbook](../handbook/README.md)
- [Theorem Proving in ProofScript](../theorem-proving-in-proofscript/README.md)
- [PSC1 Language Manual](../language-manual/README.md)

## A note on examples

The examples use the canonical PSC1 formatting style:

```proofscript
function add(x: Nat, y: Nat): Nat :=
  x + y;
```

The repository still contains older source written with Lean-style spacing
(`x : Nat`). Both are semantically equivalent; the canonical `.ps`
formatter style is `x: Nat`.

Some later chapters discuss capabilities that are required by the PSC1
self-host profile but whose complete library/API freeze is still in progress.
Those sections are labeled rather than pretending the implementation is more
complete than it is.

## The main design idea

A good PSC1 program should read at the level of the problem.

Instead of encoding everything as low-level control flow, prefer:

- descriptive functions;
- algebraic data;
- higher-order combinators;
- explicit error/effect types;
- dependent types when they genuinely improve an API;
- proofs where they eliminate a meaningful class of mistakes.

The goal is not to maximize proof syntax.

The goal is to make correct programs easier to state, understand, reuse, and
compile across multiple backends.
