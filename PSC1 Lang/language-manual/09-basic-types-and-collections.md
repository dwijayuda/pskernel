# 9. Basic Types and Collections

PSC1 freezes a compact foundational type vocabulary.

## Unbounded integers

```text
Nat
Int
```

These are exact mathematical naturals/integers.

They are not defined by JavaScript's numeric precision or a native machine word.

## Fixed-width unsigned integers

```text
UInt8
UInt16
UInt32
UInt64
```

## Fixed-width signed integers

```text
Int8
Int16
Int32
Int64
```

## Target-sized integers

```text
USize
ISize
```

Their width is determined by the selected target profile.

Portable code must not assume a fixed width unless the target is constrained.

## Floating point

```text
Float
Float32
```

Target lowering must preserve the frozen floating contract.

Fast-math/relaxed behavior is not automatically PSC1 semantics.

## Logical/text/unit types

```text
Bool
Char
String
Unit
```

## Scalar freeze status

The names above are frozen.

The complete operation/conversion matrix is still an open SH7 freeze obligation
on the baseline used by this manual.

Implementations must not fill gaps by silently copying host behavior.

## Core collection/data capabilities

The self-host foundation requires the capabilities represented by:

- List / current `PsList`;
- Option / current `PsOption`;
- Result/Except-style error data / current `PsResult`;
- `Prod`;
- `Array`;
- ordered Map;
- ordered Set.

Exact stdlib naming can evolve without changing the underlying language
mechanisms.

## Arrays

Array operations include bounded access, push, map/fold, and related compiler
needs.

Proof-carrying bounds APIs and Option/default-returning APIs have distinct
contracts.

## Maps and sets

The current bootstrap libraries use explicit ordering/comparison behavior rather
than target object identity/hashing as source semantics.

## Backend representation

A target may use specialized machine/storage representations.

Portable source cannot observe backend addresses or object identity as ordinary
PSC1 value identity.
