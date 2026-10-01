# 1. Values, Types, and Operators

Programs compute with values.

PSC1 also tracks the types of those values before runtime.

## Natural numbers

```proofscript
const answer: Nat := 42;
```

`Nat` is an exact natural-number type.

It is not defined as JavaScript `number`.

## Integers

```proofscript
const offset: Int := -3;
```

`Int` is an exact integer type.

## Fixed-width integers

PSC1 freezes these names:

```text
UInt8 UInt16 UInt32 UInt64 USize
Int8  Int16  Int32  Int64  ISize
```

A fixed width is part of the type's contract.

### Freeze note

The complete scalar operation/conversion matrix is still an explicit PSC1
freeze obligation in the current repository baseline. Do not infer missing
overflow/conversion rules from JavaScript, Rust, or Wasm behavior.

## Floating point

```text
Float
Float32
```

represent the frozen floating types.

Backend fast-math is not source semantics.

## Booleans

```proofscript
const enabled: Bool := true;
```

Boolean operators include the supported:

```text
!   &&   ||
```

## Strings and characters

```proofscript
const greeting: String := "hello";
```

`String` and `Char` are semantic language values.

Their backend representation is private to the runtime/backend.

## Unit

`Unit` represents a result with no interesting information.

It is useful in effectful APIs.

## Operators

For the current shared grammar, ordinary binary precedence is:

```text
||
&&
== !=
< <= > >=
+ -
* / %
```

Application binds more tightly.

## Three different-looking equalities

These must not be confused:

```text
:=   defines or binds
=    creates a proposition of equality
==   computes Bool equality where supported
```

Example:

```proofscript
const one: Nat := 1;

function isOne(x: Nat): Bool :=
  x == 1;

theorem oneIsOne: one = one := by rfl;
```

## No automatic coercion philosophy

PSC1 should not silently reproduce JavaScript-style conversions such as
"number plus string becomes string" or truthiness conversion.

Conversions must be explicit or come from a specifically defined elaboration
rule.

Failing to type-check is preferable to guessing a runtime interpretation.

## Expressions compose

```proofscript
function score(x: Nat, bonus: Nat): Nat :=
  (x * 2) + bonus;
```

The same principle scales to user-defined functions and data.

## Exercises

1. Define `triple(x: Nat): Nat`.
2. Define `between(x, low, high): Bool` using comparisons and `&&`.
3. Write one Bool-valued equality function and one theorem using
   propositional equality. Explain the difference.
4. List which numeric types in PSC1 have a target-independent fixed width and
   which do not.
