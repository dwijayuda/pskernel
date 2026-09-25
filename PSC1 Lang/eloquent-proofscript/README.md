# Eloquent ProofScript PSC1

This book is a practical, code-first introduction to ProofScript PSC1.

Its **teaching architecture** is inspired by the strengths studied in
*Eloquent JavaScript* and cross-checked against the repository's Lean,
TypeScript, ProofScript, self-hosting, and theorem-prover study material.

It is not a translation of *Eloquent JavaScript*. JavaScript's dynamic object
model, mutation, exceptions, promises, browser APIs, and Node runtime are not
PSC1 semantics.

Instead, this book asks the analogous question:

> What is the shortest path from "I can read a PSC1 expression" to "I can build,
> reason about, verify, package, and run a real PSC1 program"?

## The three parts

### Part I — The language

1. [Values, Types, and Operators](./01-values-types-and-operators.md)
2. [Program Structure](./02-program-structure.md)
3. [Functions](./03-functions.md)
4. [Data Structures](./04-data-structures.md)
5. [Higher-Order Functions](./05-higher-order-functions.md)
6. [Abstraction with Structures, Inductives, and Typeclasses](./06-abstraction.md)
7. [Project: A Delivery Planner](./07-project-delivery-planner.md)
8. [Bugs, Errors, and Proof Failures](./08-bugs-errors-and-proof-failures.md)
9. [Text, Unicode, and Parsing](./09-text-unicode-and-parsing.md)
10. [Modules and Packages](./10-modules-and-packages.md)
11. [Effects, Waiting, and Host Capabilities](./11-effects-and-host-capabilities.md)
12. [Project: A Tiny Typed Language](./12-project-tiny-typed-language.md)

### Part II — Programs at the host boundary

13. [JavaScript, the Web, and FFI](./13-javascript-web-and-ffi.md)
14. [JSON and External Data](./14-json-and-external-data.md)
15. [Project: A Checked Host Adapter](./15-project-checked-host-adapter.md)
16. [Node, npm, and Command-Line Programs](./16-node-npm-and-cli.md)

### Part III — Building the language with the language

17. [Project: A Small Compiler Slice](./17-project-compiler-slice.md)

Then use [Exercise Hints](./EXERCISE_HINTS.md) only after trying the exercises.

## How to read this book

Type the examples.

Run:

```bash
psc check
psc build
psc run
```

Use:

```bash
psc translate input.ps --to lean
psc emit-lean input.ps
```

when you want to inspect the supported semantic translation.

Do not merely read a solution and decide that you "would have written that."
The point of the exercises is to make the type checker, elaborator, and runtime
give you feedback.

## What this book treats as PSC1

The book follows the active PSC1 profile:

- `def`, `const`, `function`;
- lambdas, application, `let`;
- `if` and single-scrutinee `match`;
- structures and inductives;
- the frozen scalar vocabulary;
- List/Option/Result/Prod/Array/ordered Map/Set capabilities;
- dependent functions and `Prop`;
- bounded class/instance behavior;
- structural recursion;
- bounded theorem tactics;
- modules/imports;
- explicit compiler effects;
- target-neutral CheckedCore -> Erasure -> VerifiedIR execution.

It does **not** teach optional/deferred constructs as though they were already
required PSC1.

## Example style

Native PSC1 examples use canonical formatting:

```proofscript
function add(x: Nat, y: Nat): Nat :=
  x + y;
```

Canonical Lean examples use normal Lean spacing:

```lean
def add (x : Nat) (y : Nat) : Nat :=
  x + y
```

## Status labels

Some sections use these labels:

- **Current PSC1** — supported by current repository evidence.
- **Profile requirement** — required by the first self-host language plan but
  may still be closing end-to-end gates.
- **Host boundary** — a runtime capability, not proof semantics.
- **Deferred** — deliberately outside the first PSC1 freeze.
