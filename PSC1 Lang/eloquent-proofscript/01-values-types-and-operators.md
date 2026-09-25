# 1. Values, Types, and Operators

Programs manipulate values.

PSC1 differs from JavaScript in one important respect: the type of a value is
not an after-the-fact runtime guess. It is part of the program's checked
meaning.

## Natural numbers

```proofscript
const count: Nat := 12;
```

`Nat` represents nonnegative mathematical integers.

It is not restricted to the safe-integer range of JavaScript `number`.

## Integers

```proofscript
const delta: Int := -3;
```

`Int` is exact mathematical integer arithmetic.

## Fixed-width integers

PSC1 freezes:

```text
UInt8 UInt16 UInt32 UInt64 USize
Int8 Int16 Int32 Int64 ISize
```

These types exist because programs sometimes need machine-shaped data.

They must not inherit corner-case behavior accidentally from one backend.

### Freeze note

The names are frozen.

The complete machine-scalar operation and conversion matrix remains an open
SH7 obligation in the baseline used by this book.

Until that closes, examples should avoid pretending unspecified overflow or
conversion corners are already normative.

## Floating point

```text
Float
Float32
```

are computational floating types.

Portable semantics must remain stable across the supported backends.

## Booleans

```proofscript
const enabled: Bool := true;
```

Bool is executable data.

It is not the same thing as `Prop`.

## Characters and strings

```proofscript
const greeting: String := "hello";
```

PSC1 strings follow the semantic model needed by the pinned Lean-compatible
foundation and compiler workload.

The self-hosting work specifically cares about UTF-8 positions and text slicing,
so backend-native string indexing is not the language definition.

## Unit

```proofscript
const done: Unit := ();
```

Unit is useful when the meaningful result is "there is exactly one ordinary
value here."

## Operators

Current shared binary precedence, weak to strong:

```text
||
&&
== !=
< <= > >=
+ -
* / %
```

Application binds tighter.

## Three equal-looking symbols with different jobs

```text
:=  definition or local binding
=   propositional equality
==  Bool-valued equality
```

For example:

```proofscript
const one: Nat := 1;

function isOne(x: Nat): Bool :=
  x == one;

theorem oneEqualsItself: one = one := by rfl;
```

## No automatic JavaScript coercion

PSC1 does not define arithmetic by "try converting whatever values happen to be
present."

Conversions are explicit, typed operations whose accepted cases belong in the
language contract.

## Exercises

1. Define `const fortyThree: Nat := 43;`.
2. Write `function isZero(x: Nat): Bool` using `==`.
3. Write a theorem that `fortyThree = fortyThree`.
4. Explain why `Nat` cannot be defined as "JavaScript number restricted to
   nonnegative values" in a multi-backend language.
