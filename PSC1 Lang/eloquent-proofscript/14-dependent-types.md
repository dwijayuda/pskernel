# 14. Dependent Types

A dependent type can mention a value.

This lets a function signature state relationships that ordinary generic types
cannot express.

## Ordinary polymorphism

```proofscript
function identity {α: Type}(x: α): α :=
  x;
```

The output type depends on the input *type*.

## Dependent function

```proofscript
(x: Nat) -> Fin x -> Nat
```

The second argument type mentions the earlier value `x`.

This is a Pi type.

## Bounds as evidence

Array access can require proof that an index is valid.

The current stdlib has a proof-carrying shape:

```proofscript
function arrayGet {α: Type}
(xs: Array(α), index: Nat, h: index < Array.size(xs)): α :=
  Array.getInternal(xs, index, h);
```

The caller supplies or elaboration discovers evidence.

## Alternative API: Option

Proof-carrying access is not always the most convenient API.

```proofscript
arrayGet?(xs, index)
```

can return `PsOption(α)`.

One API says:

> this index is valid.

The other says:

> this index may be invalid, and the result represents that possibility.

Both are useful.

## Indexed data

A vector-like family conceptually has:

```text
Vec α n
```

where the length is part of the type.

This can make illegal shape combinations impossible to construct.

## The cost of precision

More precise types can require:

- more elaboration;
- proof arguments;
- stronger recursion/elimination machinery;
- more complex error messages.

Use dependent types when the stronger contract pays for itself.

## Universes

Generic dependent programming requires a universe hierarchy.

PSC1 preserves enough universe semantics for the frozen dependent core.

It does not need all of Lean's user-facing universe commands for the first
language freeze.

## Backend independence

A dependent proof may erase before runtime.

JavaScript, Rust, and Wasm do not need identical runtime proof
representations.

They need to preserve the executable meaning of the already checked source.

## Exercises

1. Explain the difference between `α -> α` and `(x: Nat) -> Fin x -> Nat`.
2. Design a proof-carrying function that consumes a non-empty collection.
3. Design an Option-returning alternative.
4. Decide which API you would expose publicly and why.
