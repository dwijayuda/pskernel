# 4. Data Structures

Programs become interesting when values are grouped into structures and
recursive collections.

PSC1 favors explicit algebraic data over loosely shaped objects.

## Structures

```proofscript
structure Point where {
  x: Nat;
  y: Nat;
}
```

A structure has a fixed set of named fields.

It is nominal checked data.

## Inductive types

```proofscript
inductive PsOption(α: Type) where {
  | none;
  | some(value: α);
};
```

An inductive value is one of its declared constructors.

## Lists

The current ProofScript stdlib dogfoods a recursive list:

```proofscript
inductive PsList(α: Type) where {
  | nil;
  | cons(head: α, tail: PsList(α));
};
```

A recursive function can traverse it structurally.

```proofscript
function listLength {α: Type}(xs: PsList(α)): Nat :=
  match xs with {
    | .nil => 0;
    | .cons head tail => 1 + listLength(tail);
  };
```

## Option instead of null

A possibly absent value uses an explicit constructor.

```proofscript
function listHeadOption {α: Type}
(xs: PsList(α)): PsOption(α) :=
  match xs with {
    | .nil => PsOption.none;
    | .cons head tail => PsOption.some(head);
  };
```

No implicit `null` or `undefined` state is required.

## Result instead of unchecked exceptions

The stdlib also uses:

```proofscript
inductive PsResult(α: Type, ε: Type) where {
  | ok(value: α);
  | error(error: ε);
};
```

Recoverable failure becomes ordinary typed data.

## Arrays

`Array(α)` provides an efficient indexed collection capability.

The PSC1 stdlib distinguishes:

- proof-carrying access;
- default-returning access;
- option-returning access.

That makes the error contract visible in the type.

## Ordered maps and sets

PSC1's bootstrap map/set libraries use explicit comparison functions.

They do not define map/set semantics using JavaScript object identity or hash
tables.

## Persistent data

Many PSC1 data operations return a new logical value rather than mutating a
shared object.

A backend can optimize representation while preserving this semantic model.

Persistent values are especially pleasant for reasoning because an old value
does not silently change after being passed elsewhere.

## JSON boundary

JSON is useful for host/CLI interchange.

It is not the internal semantic definition of PSC1 structures or inductives.

## Exercises

1. Define a two-field `Range` structure.
2. Define `PsEither(α, β)` with two constructors.
3. Write a recursive `listContainsNat`.
4. Compare three array lookup contracts: proof-carrying, option-returning, and
   default-returning. When would you choose each?
