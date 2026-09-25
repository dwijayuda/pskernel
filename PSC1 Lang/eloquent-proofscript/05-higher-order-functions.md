# 5. Higher-Order Functions

A higher-order function takes or returns another function.

This lets programs describe a pattern once and supply only the varying behavior.

## Mapping

The repository's ProofScript stdlib contains the higher-order shape:

```proofscript
function listMap {α: Type}{β: Type}
(f: α -> β, xs: PsList(α)): PsList(β) :=
  match xs with {
    | .nil => PsList.nil;
    | .cons head tail => PsList.cons(f(head), listMap(f, tail));
  };
```

This combines:

- polymorphism;
- function values;
- structural recursion;
- generic inductive data.

## Transforming behavior, not data representation

A higher-order function should abstract an operation because the operation is
the varying part.

Do not add a generic abstraction merely because it is possible.

PSC1's small-language philosophy applies at library level too.

## Composition

Conceptually:

```proofscript
function compose {α: Type}{β: Type}{γ: Type}
(f: β -> γ, g: α -> β, x: α): γ :=
  f(g(x));
```

Composition is ordinary function application.

No special runtime object model is needed.

## Folds

A fold summarizes recursive data by giving behavior for constructors.

That idea is closely related to the recursors generated for inductive types.

In programming, a fold is a reusable traversal.

In theorem proving, an induction principle is a proof-producing traversal over
the same shape.

## Laws

Higher-order abstractions become much more valuable when their laws are stated.

The repository already dogfoods laws such as the interaction of `listMap` and
`listAppend`.

A theorem can document an optimization- or refactoring-safe property of a
library abstraction.

## Generic code and typeclasses

Use ordinary type parameters when behavior is uniform for every type.

Use a typeclass when the function needs type-specific evidence/operations.

## Exercises

1. Implement `compose`.
2. Implement `listMap` for a custom recursive list type.
3. Write a `listLength` function and explain why its behavior does not need a
   typeclass.
4. State a theorem you would want from a reusable `map` operation, even if you
   do not prove it yet.
