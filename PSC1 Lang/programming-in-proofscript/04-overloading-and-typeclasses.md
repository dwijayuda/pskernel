# 4. Overloading and Typeclasses

PSC1 uses typeclasses for bounded ad-hoc polymorphism.

This mechanism is inherited semantically from Lean's evidence-passing model,
but PSC1 does not require the full Lean class ecosystem for its first freeze.

## The dictionary idea

Imagine a class that supplies one operation:

```proofscript
class Sized(α: Type) where {
  size: α -> Nat;
}
```

A value of `Sized(α)` is evidence that the operation exists for `α`.

A function can request such evidence through an instance parameter.

## Why instance synthesis exists

Passing dictionaries manually is precise but noisy.

Typeclass synthesis lets elaboration find the evidence from registered local or
global instances.

The important semantic point is:

> instance search constructs an ordinary argument that the checked term needs.

It is not dynamic JavaScript property lookup.

## Bounded PSC1 scope

The first self-host profile needs enough class/instance machinery for:

- compiler code already depending on it;
- `Decidable` behavior;
- bounded polymorphic operations;
- imported instance metadata and deterministic search.

PSC1 does not need every Lean feature such as arbitrary deriving machinery,
deep coercion systems, or all output-parameter behavior before the first
language freeze.

## Operators

An operator that appears polymorphic may elaborate through typeclass evidence.

The source glyph alone does not define semantics.

For example, fixed-width integer addition must ultimately obey the frozen
scalar contract even if a target backend has a convenient native operator.

## Instance search must fail closed

If required evidence cannot be synthesized, elaboration fails.

PSC1 must not:

- guess based on runtime object shape;
- fall back to a JavaScript implementation;
- silently introduce an axiom;
- choose an unrelated instance because a backend can execute it.

## Local and global evidence

Compiler code needs both local assumptions and a bounded global environment.

The exact lookup/cache/index strategy is implementation detail, provided the
observable resolution semantics stay compatible with the frozen PSC1 subset.

## Typeclasses vs structures

A structure is ordinary data.

A class is a structure-like declaration whose values participate in instance
synthesis.

Use a normal structure when callers should pass/select the value explicitly.

Use a class when type-directed evidence selection is the intended abstraction.

## Typeclasses vs OOP

PSC1 classes do not imply:

- inheritance;
- virtual dispatch;
- constructors;
- object identity;
- `this`;
- private mutable state.

They are closer to explicit evidence dictionaries selected by elaboration.

## Next

Continue to [Effects and `do`](./05-effects-and-do.md).
