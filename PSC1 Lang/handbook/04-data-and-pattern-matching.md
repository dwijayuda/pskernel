# Data and Pattern Matching

PSC1 uses two main user-defined data mechanisms:

- structures for fixed named fields;
- inductives for alternative constructors.

Pattern matching is the ordinary way to eliminate inductive alternatives.

## Structures

A structure groups fields.

```proofscript
structure Point where {
  x : Nat;
  y : Nat;
}
```

A structure is a nominal checked declaration.

It is not merely a JavaScript object shape.

## Constructing records

The supported record-value family uses Lean-style assignment punctuation:

```proofscript
const origin : Point := {
  x := 0,
  y := 0
};
```

The exact canonical formatting may differ.

## Projections

A checked structure generates field projection semantics.

Backend object/property layout is not the source-level definition of those
projections.

## Inductive types

An inductive lists constructors.

```proofscript
inductive PsOption(α : Type) where {
  | none;
  | some(value : α);
};
```

A value of `PsOption(Nat)` is built by one of the declared constructors.

## Multiple payload channels

A result type can distinguish success and error payloads:

```proofscript
inductive PsResult(α : Type, ε : Type) where {
  | ok(value : α);
  | error(error : ε);
};
```

The alternatives are explicit in the type.

## Match

```proofscript
function resultIsOk {α : Type}{ε : Type}
(value : PsResult(α, ε)) : Bool :=
  match value with {
    | .ok x => true;
    | .error err => false;
  };
```

The braced body is a PSC1-owned surface form.

Patterns remain bounded Lean-compatible patterns.

## Pattern matching is not TypeScript narrowing

In TypeScript, control-flow analysis often narrows a value from a broad union or
structural type.

PSC1's central mechanism is algebraic elimination:

1. the inductive declaration lists constructors;
2. the match scrutinizes a value;
3. each branch corresponds to a constructor case;
4. elaboration checks branch types;
5. the kernel checks the resulting declaration.

Dependent types can make branch result types even more precise.

## Recursive data

```proofscript
inductive PsList(α : Type) where {
  | nil;
  | cons(head : α, tail : PsList(α));
};
```

The type refers to itself in a positive recursive position.

The kernel-facing semantics are responsible for validating inductive
well-formedness.

## Recursive functions by matching

```proofscript
function listLength {α : Type}(xs : PsList(α)) : Nat :=
  match xs with {
    | .nil => 0;
    | .cons head tail => 1 + listLength(tail);
  };
```

The recursive call uses the structurally smaller tail.

This is the preferred recursion story for the first PSC1 profile.

## Nested matching

The current stdlib uses nested matches for maps and result/option logic.

Example shape:

```proofscript
match outer with {
  | .left x =>
    match x with {
      | .a => ...
      | .b y => ...
    };
  | .right z => ...
}
```

PSC1 does not need multi-scrutinee or elaborate destructuring syntax to express
the underlying semantics.

Richer pattern sugar can remain optional.

## Exhaustiveness

A correct match over an inductive should account for the constructors required
by the admitted semantic profile.

The frontend may provide diagnostics, but final elaborated terms must still be
well-typed.

## Classes are not ordinary data alternatives

A PSC1 `class` is a typeclass declaration, not an OO class and not a
discriminated union.

Use structures/inductives for ordinary data modeling.

## Runtime representation

A backend may represent an inductive with tags and fields.

That representation is downstream.

The source does not expose "constructor tag 0" or a JavaScript property layout
as semantic identity.

## JSON boundaries

At CLI/host boundaries, supported ADTs can use a strict JSON representation
such as:

```json
{"$ctor":"some","value":"42"}
```

That is an external encoding derived from checked metadata, not the language's
internal definition of the inductive.

## Choosing between structure and inductive

Use a structure for:

> this value has all of these fields.

Use an inductive for:

> this value is one of these constructor cases.

Use a function to transform/eliminate values.

Use a typeclass when behavior/evidence should be selected by type.

## Next

Continue to [Generics and Dependent Types](./05-generics-and-dependent-types.md).
