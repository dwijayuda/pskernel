# 6. Programming with Dependent Types

Dependent types let values appear inside types.

They are the main feature that makes PSC1 more expressive than an ordinary
generic type system.

## Ordinary polymorphism

```proofscript
function identity {α: Type}(x: α): α :=
  x;
```

The type varies, but the result type does not depend on the *value* of `x`.

## Dependent function types

```proofscript
(x: Nat) -> Fin x -> Nat
```

Here a later input type mentions the earlier value `x`.

This is a Pi type.

## Programs can determine types

Conceptually, a function may return values whose type depends on a flag or
index.

The full convenience syntax used by Lean is not automatically PSC1 syntax, but
the dependent core must be expressive enough for the compiler and proof layer.

## Indexed families

An indexed family is a type constructor whose result is indexed by values.

A vector-like family has the conceptual shape:

```text
Vec α n
```

where the length `n` is part of the type.

PSC1's core semantics can express indexed/dependent families, but the first
self-host freeze does not claim every Lean dependent pattern-elaboration
convenience.

## Parameters vs indices

A useful distinction from the Lean study material is:

- **parameters** stay fixed throughout constructors/recursion;
- **indices** may vary between constructors and can refine a result type.

The elaborator/recursor must preserve that distinction.

## Universes

Types themselves have universe levels.

PSC1 needs enough universe inference/polymorphism for generic compiler code and
dependent declarations.

Broad user-facing universe syntax is not a first-freeze requirement unless the
frozen source needs it.

## Evidence in APIs

Dependent APIs can move checks from runtime into types.

For array access:

```proofscript
function arrayGet {α: Type}
(xs: Array(α), index: Nat, h: index < Array.size(xs)): α :=
  Array.getInternal(xs, index, h);
```

The proof argument states the safety condition directly.

## Do not maximize dependency blindly

Dependent types can make APIs precise but also increase elaboration burden and
proof obligations.

A useful PSC1 design rule is:

> use the weakest type that expresses the invariant callers genuinely benefit
> from.

Sometimes an option/result is more ergonomic than a proof parameter.

## Erasure

Type-level indices and proof arguments can erase when they have no runtime
relevance.

The erasure pass must preserve the executable semantics that remain.

This is why type checking and compiler-correctness assurance are related but
separate claims.

## Next

Continue to
[Programming, Proving, and Performance](./07-programming-proving-and-performance.md).
