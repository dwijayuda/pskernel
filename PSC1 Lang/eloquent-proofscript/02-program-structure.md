# 2. Program Structure

Values become useful when they are arranged into definitions and expressions
that describe a larger computation.

PSC1 deliberately keeps this structure smaller than JavaScript's statement
language.

## Definitions

```proofscript
def base: Nat := 10;
const bonus: Nat := 5;
```

`def` is canonical.

`const` is the parameterless alias.

## Function declarations

```proofscript
function total(x: Nat): Nat :=
  x + base + bonus;
```

`function` is a parameterized alias of the same definition mechanism.

## Local bindings

```proofscript
function invoice(subtotal: Nat): Nat :=
  let fee: Nat := 3;
  let adjusted: Nat := subtotal + fee;
  adjusted;
```

A `let` is lexical.

It does not imply mutable JavaScript-style assignment.

## Conditional expressions

```proofscript
function maxNat(x: Nat, y: Nat): Nat :=
  if (x >= y) {
    x
  } else {
    y
  };
```

The branches are expressions.

The braces are registered PSC1 syntax, not generic statement blocks.

## Pattern-based control

For algebraic alternatives, use `match` rather than a switch over untyped
tags.

```proofscript
function optionDefault {α: Type}
(value: PsOption(α), fallback: α): α :=
  match value with {
    | .none => fallback;
    | .some x => x;
  };
```

## Sequencing

Pure code usually expresses sequence through data dependencies and nested/local
bindings.

Effectful sequencing belongs in an explicit effect and `do` notation.

## Why loops are not central to PSC1

A small functional language can express iteration through:

- structural recursion;
- `map`;
- `fold`;
- reusable traversal functions.

Imperative loops may be useful future syntax, but they are not required to
make PSC1 computationally useful or self-hosting.

## Comments and formatting

Formatting is intentionally conventional:

```proofscript
function add(x: Nat, y: Nat): Nat :=
  x + y;
```

Spacing around `:` is not semantic.

The canonical `.ps` style is `x: Type`.

## Exercise: Fizz-like classification

Write:

```proofscript
function classify(n: Nat): String := ...
```

that returns one of a few fixed strings based on divisibility tests.

Prefer nested `if` expressions over inventing mutable state.

## Exercises

1. Rewrite a three-step arithmetic computation using two local `let`
   bindings.
2. Write `absDiff(x, y): Nat` using an `if`.
3. Define your own two-constructor status inductive and write a `match`
   function over it.
4. Explain why a PSC1 branch block is not equivalent to an arbitrary JS block.
