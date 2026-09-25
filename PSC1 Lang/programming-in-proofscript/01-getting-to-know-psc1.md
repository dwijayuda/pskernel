# 1. Getting to Know PSC1

The best first model of PSC1 is **typed expressions plus named definitions**.

Unlike a traditional REPL-centered language, PSC1's normal workflow is built
around editor diagnostics and `psc check/build/run`.

## Values and types

```proofscript
const answer: Nat := 42;
const enabled: Bool := true;
const greeting: String := "hello";
```

The annotation after `:` states the type.

Canonical PSC1 formatting uses `name: Type`; whitespace before the colon is
still accepted where grammar permits it.

## Definitions and functions

```proofscript
def one: Nat := 1;

function add(x: Nat, y: Nat): Nat :=
  x + y;
```

`def`, `const`, and `function` share one definition semantics:

- `def` is canonical and general;
- `const` is a parameterless alias;
- `function` requires explicit declaration parameters.

There is no JavaScript hoisting or implicit `this`.

## Local computation

```proofscript
function calculate(x: Nat): Nat :=
  let y: Nat := x + 1;
  let z: Nat := y * 2;
  z;
```

A `let` is a lexical binding, not a mutable JS variable.

## Functions are values

```proofscript
const increment: Nat -> Nat :=
  fun x => x + 1;

function applyTwice(f: Nat -> Nat, x: Nat): Nat :=
  f(f(x));
```

Function application is semantically curried even though PSC1's adjacent
D-CALL form makes ordinary calls concise.

## Structures

Use structures for data with a fixed collection of fields.

```proofscript
structure Point where {
  x: Nat;
  y: Nat;
}
```

Structures are nominal checked declarations. Their meaning is not "whatever JS
object happens to have these properties."

## Inductive data

Use inductives for alternatives.

```proofscript
inductive PsOption(α: Type) where {
  | none;
  | some(value: α);
};
```

Consume them with `match`:

```proofscript
function getOrElse {α: Type}
(value: PsOption(α), fallback: α): α :=
  match value with {
    | .none => fallback;
    | .some x => x;
  };
```

## Polymorphism

```proofscript
function identity {α: Type}(x: α): α :=
  x;
```

The implicit type parameter is inferred by elaboration where possible.

Unlike TypeScript generics, PSC1's binder system extends directly to dependent
function types.

## Strings and characters

`String` and `Char` are semantic PSC1/Lean-compatible types, not aliases for
host object representations.

This distinction matters to a self-hosted compiler because Unicode text,
positions, and slicing must behave consistently across JavaScript, Rust, and
Wasm.

## Evaluation and running

For complete projects, use:

```bash
psc check
psc build
psc run -- 42
```

The compiler does not use JavaScript execution as proof evidence.

## A small but important distinction

```text
:=   definition/binding
=    propositional equality
==   Bool-valued equality
```

Keeping these roles distinct prevents JavaScript assignment/equality intuition
from leaking into the proof language.

## Next

Continue to [Projects and Programs](./02-projects-and-programs.md).
