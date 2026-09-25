# 2. Program Structure

PSC1 programs are built from declarations and expressions.

The first core deliberately avoids requiring a large imperative statement
language.

## Definitions

```proofscript
def answer: Nat := 42;
```

`def` is the canonical general declaration.

Two ergonomic aliases share the same semantics:

```proofscript
const otherAnswer: Nat := 42;

function add(x: Nat, y: Nat): Nat :=
  x + y;
```

## Local bindings

```proofscript
function score(x: Nat): Nat :=
  let doubled: Nat := x * 2;
  let adjusted: Nat := doubled + 1;
  adjusted;
```

A local `let` introduces a lexical value.

It is not a mutable JavaScript `let`.

## Conditional computation

PSC1 owns a braced expression form:

```proofscript
function choose(flag: Bool, yes: Nat, no: Nat): Nat :=
  if (flag) {
    yes
  } else {
    no
  };
```

The branches are expressions.

## Dispatching on data

For algebraic alternatives, use `match`:

```proofscript
function optionOrZero(value: PsOption(Nat)): Nat :=
  match value with {
    | .none => 0;
    | .some x => x;
  };
```

This is the PSC1 analogue of a value-directed control construct.

## Repetition

JavaScript introductory material often reaches for `while` and `for`.

PSC1's first freeze does not need loops as a foundational requirement.

Use structural recursion when the data itself provides the iteration shape:

```proofscript
function listLength {α: Type}(xs: PsList(α)): Nat :=
  match xs with {
    | .nil => 0;
    | .cons head tail => 1 + listLength(tail);
  };
```

Loop/mutation syntax is optional/deferred unless real compiler source makes it
necessary.

## Comments and formatting

Formatting does not define type semantics.

Canonical native PSC1 uses:

```text
name: Type
```

rather than the Lean printer's:

```text
name : Type
```

## Order of declarations

A module is checked in an explicit environment.

Do not rely on JavaScript-style hoisting.

The exact visibility rules are part of module/environment elaboration, not a
host runtime accident.

## Exercises

1. Implement `absoluteLike(flag, x, y)` as an `if` expression choosing
   between two Nat values.
2. Define an inductive with two constructors and a function that dispatches on
   it with `match`.
3. Implement a recursive count over `PsList(Nat)`.
4. Rewrite a small algorithm that you would normally express with a mutable loop
   as structural recursion.
