# Everyday Types

PSC1's everyday type system is deliberately smaller and more explicit than
JavaScript/TypeScript's.

The central rule is:

> A backend representation is not the source type.

## Natural numbers: `Nat`

`Nat` represents exact natural numbers.

```proofscript
const count: Nat := 42;
```

At the language level `Nat` is not JavaScript `number`.

A JavaScript backend therefore cannot silently make the largest exactly
representable JS integer the semantic limit of `Nat`.

## Integers: `Int`

`Int` represents exact mathematical integers.

Its runtime representation may differ from `Nat`, but the same principle
applies: target machine width is not the language meaning.

## Fixed-width unsigned integers

PSC1 freezes these names:

```text
UInt8
UInt16
UInt32
UInt64
```

They represent fixed-width unsigned machine values.

Their width is semantic.

## Fixed-width signed integers

PSC1 also freezes:

```text
Int8
Int16
Int32
Int64
```

They are distinct from unbounded `Int`.

## Target-sized integers

```text
USize
ISize
```

are target-word-sized.

This is one of the few places where the selected target profile intentionally
affects width.

A wasm32 build and a 64-bit native build may therefore use different widths,
but that variation must be explicit in the target profile.

## Floating point

PSC1 freezes two floating types:

```text
Float
Float32
```

Their supported operations must preserve the frozen PSC1/Lean-compatible
semantics.

A backend is not allowed to silently turn on fast-math and call the changed
results "PSC1 semantics".

### Current freeze note

The scalar **type vocabulary** is frozen.

The complete operation/conversion matrix for every fixed-width and floating
operation is still an explicit SH7 freeze obligation in the current baseline.

Until that closes, do not infer language semantics from one backend's native
operator behavior.

## `Bool`

```proofscript
const yes: Bool := true;
const no: Bool := false;
```

Bool-valued computation is distinct from propositions in `Prop`.

This function returns a runtime Bool:

```proofscript
function sameNat(x: Nat, y: Nat): Bool :=
  x == y;
```

This theorem states a proposition:

```proofscript
theorem selfEq(x: Nat): x = x := by rfl;
```

## `Char`

`Char` represents characters according to the pinned semantic model.

It is particularly important to the self-host compiler because lexing and
source positions must work on real text rather than byte-by-byte ASCII
assumptions.

## `String`

`String` is a semantic string value.

It is not defined as a JavaScript String object, Rust `String`, or Wasm memory
slice.

The compiler/runtime may use those representations internally when semantics
are preserved.

## `Unit`

`Unit` is the type with the ordinary unit role.

It is useful when a computation has no interesting result value.

Backends may optimize its representation.

## Function types

```proofscript
Nat -> Nat
```

is the type of a function taking a `Nat` and returning a `Nat`.

Functions can be passed as ordinary values.

## Generic types

Type constructors can take type parameters.

The current ProofScript stdlib dogfoods forms such as:

```proofscript
PsOption(Nat)
PsList(String)
Array(Nat)
PsResult(Nat, String)
```

These are ordinary typed applications, not TypeScript angle-bracket generics.

## `Option`-style absence

PSC1 does not use implicit `null`/`undefined` as the fundamental absence
model.

The current self-hosted stdlib uses:

```proofscript
inductive PsOption(α: Type) where {
  | none;
  | some(value: α);
};
```

A generic function can consume it:

```proofscript
function optionGetOrElse {α: Type}
(value: PsOption(α), fallback: α): α :=
  match value with {
    | .none => fallback;
    | .some x => x;
  };
```

## Result/error values

The stdlib similarly dogfoods:

```proofscript
inductive PsResult(α: Type, ε: Type) where {
  | ok(value: α);
  | error(error: ε);
};
```

This makes recoverable failure explicit in data.

## Lists

The current ProofScript-owned list is recursive:

```proofscript
inductive PsList(α: Type) where {
  | nil;
  | cons(head: α, tail: PsList(α));
};
```

This lets the language and theorem prover dogfood recursive algebraic data.

## Arrays

`Array(α)` is part of the compiler-required collection foundation.

The stdlib wraps bounded operations such as:

- empty-with-capacity;
- size;
- push;
- checked/defaulted access;
- set-if-in-bounds;
- map;
- fold;
- find/any/all.

The exact library surface is not itself a language syntax requirement.

## Products

`Prod(A, B)` is used for pair-like values.

PSC1 does not require tuple destructuring sugar for its first freeze; ordinary
constructor/projection helpers are enough for self-hosting.

## Ordered maps and sets

The bootstrap profile requires ordered Map/Set capabilities.

The current ProofScript stdlib dogfoods explicit comparison functions rather
than relying on target object hashing/identity.

That design is portable across backends.

## Structures and inductives are different tools

Use a structure when a value has a fixed collection of named fields.

Use an inductive when a value has alternative constructors.

Both are nominal checked declarations.

## What PSC1 does not have as an everyday escape hatch

There is no ordinary PSC1 equivalent of TypeScript's:

- `any`;
- implicit `null`;
- implicit `undefined`;
- unchecked cast-as-proof;
- structural object identity.

Host interop can introduce assumptions, but those assumptions stay explicit.

## Next

Continue to [Functions](./03-functions.md).
