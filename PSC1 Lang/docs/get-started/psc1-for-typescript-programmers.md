# PSC1 for TypeScript and JavaScript Programmers

PSC1 deliberately borrows some surface familiarity from TypeScript, but its
semantic model is much closer to a small dependently typed functional language
with an independent proof checker.

The fastest way to learn PSC1 from TypeScript is to separate **syntax that looks
familiar** from **semantics that are intentionally different**.

## Familiar-looking declarations

```proofscript
const answer: Nat := 42;

function add(x: Nat, y: Nat): Nat :=
  x + y;
```

The words `const` and `function` are source conveniences only.

Both lower to the same ordinary PSC1/Lean-compatible definition mechanism as
`def`.

That means:

- `const` is not JavaScript object immutability;
- `function` has no JavaScript hoisting;
- there is no implicit `this`;
- there are no prototypes attached to function declarations;
- unrestricted imperative `return` is not part of ordinary function bodies.

## `:=`, `=`, and `==`

This is one of the most important differences.

```text
:=   definition/binding
=    propositional equality
==   Bool-valued equality
```

Example:

```proofscript
const one: Nat := 1;

theorem oneIsOne: one = one := by rfl;

function isOne(x: Nat): Bool :=
  x == 1;
```

Do not mentally map PSC1 `=` to JavaScript assignment.

## Calls look familiar; functions are not JavaScript functions

```proofscript
add(1, 2)
```

is PSC1's D-CALL surface.

Its meaning is curried application, conceptually:

```text
(add 1) 2
```

The spaced form `f (x)` is deliberately a protected Lean-compatible neighbor
rather than the same lexical form as D-CALL.

## No `any` escape hatch

PSC1 does not have a TypeScript-style `any` that can be used to bypass proof
or type semantics.

If the frontend cannot establish a supported meaning, it must fail closed.

## No implicit `null` / `undefined` option model

Use explicit algebraic data.

The PSC1 stdlib currently dogfoods a ProofScript-owned option type:

```proofscript
inductive PsOption(α: Type) where {
  | none;
  | some(value: α);
};
```

Then eliminate it with `match`.

This makes absence visible to both the type checker and proofs.

## Nominal data, not structural object typing

PSC1 structures and inductives are checked declarations.

```proofscript
structure User where {
  age: Nat;
}
```

They should not be understood as TypeScript structural object types.

A backend may emit a JavaScript object representation, but that representation
does not define source-language equality, identity, or compatibility.

## Generics become dependent when necessary

TypeScript generics:

```typescript
function identity<T>(x: T): T
```

PSC1:

```proofscript
function identity {α: Type}(x: α): α :=
  x;
```

The PSC1 binder syntax is intentionally Lean-oriented because the same
mechanism extends to dependent types:

```proofscript
(x: Nat) -> Fin x -> Nat
```

Replacing these binders with `<T>` would hide an important semantic
distinction.

## Unions become inductive data

Instead of a TypeScript union like:

```typescript
type Result<T, E> =
  | { kind: "ok"; value: T }
  | { kind: "error"; error: E };
```

PSC1 uses an inductive:

```proofscript
inductive PsResult(α: Type, ε: Type) where {
  | ok(value: α);
  | error(error: ε);
};
```

Pattern matching is the ordinary elimination mechanism.

## Narrowing becomes pattern elimination, not structural control-flow typing

TypeScript spends substantial documentation on narrowing because values may
inhabit unions and structural shapes that control flow progressively refines.

PSC1's central story is different:

- inductive constructors state the alternatives;
- `match` eliminates them;
- dependent types may refine later types;
- proofs may carry propositions explicitly.

The relevant handbook chapter is therefore
[Data and Pattern Matching](../../handbook/04-data-and-pattern-matching.md),
not a TypeScript-style narrowing chapter.

## Classes do not mean OOP classes

PSC1 `class` means a Lean-compatible **typeclass**.

It is a mechanism for resolving evidence/operations by type. It does not imply:

- inheritance;
- instance object identity;
- constructor methods;
- prototype chains;
- `this`.

See [Typeclasses and Instances](../../handbook/07-typeclasses-and-instances.md).

## Effects are explicit

JavaScript often hides effects inside ordinary functions or Promise-returning
APIs.

PSC1's portable model keeps pure computation separate from host capabilities.
Filesystem, process, clock, randomness, network, and mutable host state belong
behind explicit effect/capability boundaries.

The first self-host compiler uses a concrete reader/state/error style effect
rather than treating Node behavior as language semantics.

## JavaScript is one backend, not the semantic authority

The current primary executable route is:

```text
PSC1
-> CheckedCore
-> Erasure
-> VerifiedIR
-> TypeScript
-> tsc
-> JavaScript
```

But VerifiedIR is intentionally target-neutral so the same pure PSC1 code can
also target Rust and direct WebAssembly.

That is why:

- `Nat` is not JavaScript `number`;
- `Int` is not defined by JS numeric precision;
- `UInt32` is not whatever a JS operator happens to do;
- structure equality is not object identity.

## npm interoperability is explicit

The current bounded FFI form is:

```proofscript
extern function hostShout(value: String): String
  from "host-lib"
  import shout;
```

The package is a trusted runtime dependency, not a proof oracle.

Projects declare exact runtime package roots/versions in `psconfig.json`.
Unsupported import styles fail closed.

## What you should read next

If you already know TypeScript well:

1. [PSC1 in 5 Minutes](./psc1-in-5-minutes.md)
2. [Everyday Types](../../handbook/02-everyday-types.md)
3. [Data and Pattern Matching](../../handbook/04-data-and-pattern-matching.md)
4. [Generics and Dependent Types](../../handbook/05-generics-and-dependent-types.md)
5. [Propositions and Proofs](../../handbook/06-propositions-and-proofs.md)
6. [Portability and Backends](../../handbook/12-portability-and-backends.md)
