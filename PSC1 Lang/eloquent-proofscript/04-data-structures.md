# 4. Data Structures

PSC1 uses nominal structures and inductive data rather than JavaScript's
prototype/object model.

## Structures

```proofscript
structure Point where {
  x: Nat;
  y: Nat;
}
```

A structure has a checked constructor and projections.

It is not merely "an object with matching properties."

## Structure values

Representative value syntax:

```proofscript
{ x := 3, y := 4 }
```

The expected structure type tells elaboration what the fields mean.

## Inductive alternatives

```proofscript
inductive PsOption(α: Type) where {
  | none;
  | some(value: α);
};
```

An inductive states all legal constructor forms.

## Result-style errors

The repository's current executable stdlib includes a transitional
ProofScript-owned result type:

```proofscript
inductive PsResult(α: Type, ε: Type) where {
  | ok(value: α);
  | error(error: ε);
};
```

This is often preferable to throwing a host exception for an expected
recoverable failure.

## Recursive lists

```proofscript
inductive PsList(α: Type) where {
  | nil;
  | cons(head: α, tail: PsList(α));
};
```

The recursive structure naturally supports structural recursion and induction.

## Arrays

Arrays are useful when random access matters.

The stdlib distinguishes interfaces such as:

```text
arrayGet     proof-carrying bounded access
arrayGet?    optional result
arrayGetD    default-returning access
```

Those contracts should not be collapsed into one unchecked indexing primitive.

## Maps and sets

PSC1's first compiler workload needs ordered Map and Set capabilities.

Ordering/comparison semantics belong to PSC1/library contracts, not JavaScript
object identity.

## JSON

The current stdlib has a ProofScript-owned JSON ADT with null, string, array,
and object-style cases.

JSON is data.

It is not a substitute for the static type system.

## Mutability

The first PSC1 language foundation prefers persistent/pure values.

Target backends may use mutation internally as an optimization if observable
semantics stay unchanged.

## Exercises

1. Define a `Rectangle` structure with width and height.
2. Define a two-case `Answer(α)` inductive.
3. Write a recursive `listMap`-style function.
4. Compare three array access contracts: proof, option, default. Give a use case
   for each.
