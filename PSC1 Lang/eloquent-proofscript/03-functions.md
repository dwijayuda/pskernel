# 3. Functions

Functions are the main abstraction mechanism in PSC1.

They let you name computation, pass computation around, and express both
ordinary and dependent relationships between inputs and outputs.

## A named function

```proofscript
function square(x: Nat): Nat :=
  x * x;
```

The same semantic definition can be written with `def`:

```proofscript
def square2(x: Nat): Nat :=
  x * x;
```

`function` is an ergonomic alias, not a separate runtime function kind.

## Multiple parameters

```proofscript
function add(x: Nat, y: Nat): Nat :=
  x + y;
```

Source D-CALL:

```proofscript
add(20, 22)
```

normalizes to ordinary curried application.

## Function values

```proofscript
const increment: Nat -> Nat :=
  fun x => x + 1;
```

Functions can be passed to other functions.

## Lexical scope

A lambda or local definition can use values from its surrounding checked
context.

That is lexical closure behavior at the language level.

The target backend may represent closures differently.

Portable PSC1 code cannot observe the allocation identity of that closure.

## Polymorphic functions

```proofscript
function identity {α: Type}(x: α): α :=
  x;
```

The type argument is implicit and may be inferred.

## Dependent functions

A later parameter type may mention an earlier value:

```proofscript
(x: Nat) -> Fin x -> Nat
```

This is a dependent Pi type.

It is a direct extension of the ordinary function idea, not a separate
"theorem-only" mechanism.

## Pure functions and side effects

Ordinary portable PSC1 functions are expected to be referentially transparent.

A function that reads a file, network, clock, random source, or mutable host
state crosses an explicit effect/capability boundary.

This makes optimization and proof rewriting safer.

## Recursion

```proofscript
function listLength {α: Type}(xs: PsList(α)): Nat :=
  match xs with {
    | .nil => 0;
    | .cons head tail => 1 + listLength(tail);
  };
```

Structural recursion is the preferred first-freeze recursion mechanism.

## Controlled partiality

Some executable compiler algorithms may require the explicit `partial def`
boundary.

Partial executable code is not permission to prove arbitrary propositions.

## Exercises

1. Define a function-valued `const`.
2. Define a polymorphic identity function.
3. Define `applyTwice(f, x)` for `Nat -> Nat`.
4. Define a structurally recursive sum over a Nat list.
5. Explain why a backend closure address cannot be part of portable function
   equality.
