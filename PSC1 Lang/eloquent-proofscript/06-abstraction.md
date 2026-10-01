# 6. Abstraction with Data and Typeclasses

Functions abstract behavior.

Structures and inductives abstract data.

Typeclasses abstract type-directed evidence and operations.

Together they provide most of the abstraction machinery PSC1 needs without an
object/prototype system.

## Abstract data with structures

A structure can expose a meaningful interface without exposing backend layout.

```proofscript
structure Counter where {
  value: Nat;
}
```

Library functions can operate on `Counter` values.

The source does not need methods or mutable object identity.

## Alternative states with inductives

```proofscript
inductive ParseState where {
  | ready;
  | failed(message: String);
};
```

A constructor makes each state explicit.

Pattern matching forces consumers to account for alternatives.

## Generic abstraction

```proofscript
function identity {α: Type}(x: α): α :=
  x;
```

Parametric polymorphism works uniformly for any `α`.

## Type-directed behavior

A typeclass can package operations:

```proofscript
class Sized(α: Type) where {
  size: α -> Nat;
}
```

Functions can request instance evidence rather than taking a concrete
implementation manually every time.

## Typeclasses are not OOP classes

PSC1 `class` does not imply:

- inheritance;
- constructors;
- `this`;
- virtual dispatch;
- object identity;
- mutable private fields.

It is an evidence-resolution mechanism.

## Encapsulation without objects

Useful encapsulation comes from:

- module boundaries;
- abstract data constructors;
- functions;
- private implementation conventions;
- checked invariants.

A language does not need prototype semantics to organize large programs.

## Invariants as data or proofs

Suppose a value must always satisfy a property.

There are several strategies:

1. use an inductive whose constructors can only build valid states;
2. use a structure containing data plus proof evidence;
3. keep the representation private and expose validated construction
   functions.

PSC1 can choose the weakest mechanism that expresses the needed invariant.

## Representation independence

Backends may represent the same source abstraction differently.

A structure might become:

- a JavaScript object;
- a Rust struct;
- a Wasm GC record;
- a custom memory layout.

Portable PSC1 code cannot observe that representation identity.

## Exercises

1. Model a traffic light as an inductive.
2. Model a coordinate as a structure.
3. Write one function that is polymorphic in its element type.
4. Sketch a typeclass for an operation you would otherwise pass manually.
5. Explain why a PSC1 structure is not equivalent to a TypeScript structural
   object type.
