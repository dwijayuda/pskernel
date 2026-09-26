# ProofScript PSC1 from Scratch

This page is for programmers who do not already know Lean, dependent types, or
ProofScript.

You do not need theorem-prover experience to begin. PSC1 is designed so that
ordinary code still looks like ordinary code: functions consume typed inputs,
produce typed outputs, data is built with structures and inductives, and
`match` handles alternatives.

The unusual part is that the same type system can also express propositions and
proofs.

## The smallest useful mental model

A PSC1 program goes through a checked semantic pipeline:

```text
source
-> parse
-> elaborate types and implicit information
-> pskernel checks declarations and proofs
-> executable parts are erased/lowered
-> target-neutral VerifiedIR
-> a backend such as TypeScript/JavaScript
```

The compiler is therefore doing two related jobs:

1. checking what your program means;
2. compiling its executable part.

Those jobs share semantics, but proof checking and code generation are not the
same claim.

## Values and types

A value has a type.

```proofscript
const answer: Nat := 42;
```

Here:

- `answer` is the name;
- `Nat` is the type of natural numbers;
- `42` is the value;
- `:=` introduces the definition.

PSC1 keeps `:=` because it is different from equality.

```proofscript
theorem answerIsAnswer: answer = answer := by rfl;
```

In the theorem, `=` means propositional equality.

## Functions

```proofscript
function add(x: Nat, y: Nat): Nat :=
  x + y;
```

Call it with adjacent parentheses:

```proofscript
add(20, 22)
```

PSC1 functions are conceptually curried. The source form `add(x, y)` is a
friendly call decoration over the same function semantics.

## Lambdas

Anonymous functions use `fun`:

```proofscript
fun x => x + 1
```

A higher-order function can accept another function as a value:

```proofscript
function applyTwice(
  f: Nat -> Nat,
  x: Nat
): Nat :=
  f(f(x));
```

## Local values

Use `let` for lexical binding:

```proofscript
function main(x: Nat): Nat :=
  let y: Nat := x + 1;
  let z: Nat := y * 2;
  z;
```

A PSC1 `let` is not automatically a mutable JavaScript variable.

## Booleans and conditionals

```proofscript
function maxNat(x: Nat, y: Nat): Nat :=
  if (x >= y) {
    x
  } else {
    y
  };
```

The braces contain expressions. They are not generic JavaScript statement
blocks.

## Data with inductive types

An inductive type lists the ways a value can be constructed.

```proofscript
inductive MaybeNat where {
  | none;
  | some(value: Nat);
};
```

Consume it with `match`:

```proofscript
function getOrElse(value: MaybeNat, fallback: Nat): Nat :=
  match value with {
    | .none => fallback;
    | .some x => x;
  };
```

This explicit data model is why PSC1 does not need implicit
`null`/`undefined` as a second absence system.

## Generic code

A type parameter can be implicit:

```proofscript
function identity {α: Type}(x: α): α :=
  x;
```

`α` means "some type". The function returns exactly the same type it receives.

## Dependent types

PSC1 can express a result type that depends on a value.

A function type such as:

```proofscript
(x: Nat) -> Fin x -> Nat
```

contains the value `x` inside a later type.

You do not need dependent types for every program. They become useful when an
API needs to state a stronger relationship than ordinary generics can express.

## Propositions and proofs

A proposition is a type in `Prop`. A proof is a value of that proposition.

```proofscript
theorem selfEq {α: Type}(x: α): x = x := by rfl;
```

The tactic `rfl` constructs a proof of reflexive equality. The tactic itself
is not trusted as an oracle; the resulting proof term still goes through
pskernel.

## Why the kernel matters

A parser accepting text does not prove the program is valid.

A TypeScript compiler accepting generated TypeScript also does not prove the
source theorem.

PSC1 keeps the logical trust boundary at pskernel declaration admission.

## What runs at runtime?

Proofs and other irrelevant content may erase before executable code reaches
VerifiedIR.

For example, a theorem can certify a property without becoming a runtime object
that JavaScript, Rust, or Wasm must carry around.

Compiler correctness is a separate concern: erasing a proof correctly is not
automatically proven merely because the proof itself is valid.

## Projects

The normal developer interface is `psc`.

Typical workflow:

```bash
psc init my-app
cd my-app
psc check
psc build
psc run -- 1
```

A generated application currently starts with a small `main` function and a
`psconfig.json`.

See [../tooling-and-projects.md](../tooling-and-projects.md) for the exact
current CLI/configuration model.

## What to learn next

Continue with the handbook:

1. [The Basics](../../handbook/01-the-basics.md)
2. [Everyday Types](../../handbook/02-everyday-types.md)
3. [Functions](../../handbook/03-functions.md)
4. [Data and Pattern Matching](../../handbook/04-data-and-pattern-matching.md)

You can postpone proof tactics until ordinary PSC1 code feels familiar.
