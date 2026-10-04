# RuntimeSemantics-v1

**Status:** frozen portable runtime-semantics contract for the current PSC2 production-hardening phase.

Machine identity:

```text
psc-runtime-semantics/1
```

SHA-256 of the canonical identity text:

```text
d610e1a1936dd1b090a44a8293a68436bc9300ad5c82872e8faf4e1e6b97ae03
```

The executable identity is defined by `scripts/runtime-semantics-contract.mjs`.

## 1. Purpose

This contract defines **portable observable runtime meaning** below CheckedCore/VerifiedIR and above target-specific representation.

It is not a JavaScript ABI, Rust ABI, Wasm layout, Lean runtime ABI, or package format.

```text
VerifiedIR
    |
    | RuntimeSemantics-v1
    v
target lowering
    |
    +-- TypeScript/JavaScript representation
    +-- Rust representation
    +-- WebAssembly representation
    +-- future direct JsIR representation
```

A backend may support only a subset of current VerifiedIR operations. If it supports an operation covered by this contract, its observable behavior must refine this contract. Unsupported operations reject; a backend must not silently substitute different semantics.

## 2. Canonical identity text

The contract hash is over exactly:

```text
psc-runtime-semantics/1
nat=unbounded-nonnegative;sub=saturating-zero;div0=zero;mod0=lhs
int=unbounded-signed;ofNat=embedding;negSucc=-(n+1)
machine-int=fixed-width-twos-complement;binary=mod-2^width;compare=signedness;word-size=target-profile
float=f64-ieee754;float32=f32-ieee754;float32-binary=round-f32
bool=two-valued
char=unicode-scalar;ofNat-invalid=U+0000;toNat=code-point
string=unicode-scalar-sequence;length=scalar-count;position=utf8-byte-offset;index-domain=utf8-boundaries;append=concat;eq=sequence
array=persistent-sequence;size=nat;push=append-one;get=in-bounds;getD=oob-fallback;set=in-bounds;setIfInBounds=oob-identity;map=ordered;foldl=[start,min(stop,size))
record=immutable-named-fields;projection=field-value
adt=constructor-tagged;match=constructor-dispatch;bindings=declared-fields
closure=lexical-capture;call=call-by-value;argument-order=left-to-right
unsupported=reject-no-fallback
```

Changing one of these semantic commitments requires an explicit contract/version decision.

## 3. Natural numbers

`Nat` denotes unbounded non-negative integers.

Portable operations:

| Operation | Meaning |
| --- | --- |
| `natAdd(a,b)` | mathematical `a + b` |
| `natSub(a,b)` | `max(a-b, 0)` |
| `natMul(a,b)` | mathematical `a * b` |
| `natDiv(a,0)` | `0` |
| `natDiv(a,b)`, `b>0` | natural/integer quotient |
| `natMod(a,0)` | `a` |
| `natMod(a,b)`, `b>0` | natural remainder |
| equality/order | mathematical natural-number comparison |

A target may use BigInt, arbitrary-precision objects, or another representation. Representation is not observable PSC semantics.

## 4. Integers

`Int` denotes unbounded signed mathematical integers.

Portable commitments:

- `intOfNat(n)` is the non-negative embedding of `n`;
- `intNegSucc(n)` denotes `-(n + 1)`;
- negation/addition/subtraction/multiplication have mathematical integer meaning;
- equality/order have mathematical signed-integer meaning;
- decimal representation is the ordinary signed base-10 representation used by the current `intRepr` intrinsic.

Physical representation is target-private.

## 5. Machine integers

The fixed machine types are:

```text
UInt8 UInt16 UInt32 UInt64
Int8  Int16  Int32  Int64
USize ISize
```

Semantics:

- fixed-width values use two's-complement bit interpretation;
- arithmetic and bitwise results normalize modulo `2^width`;
- unsigned ordering uses unsigned interpretation;
- signed ordering uses signed two's-complement interpretation;
- `USize`/`ISize` width is a **target-profile property**, not a source-language constant.

A backend that has not selected a concrete word-size profile must reject `USize`/`ISize` operations rather than guessing.

Literal-range/canonicalization validation remains a VerifiedIR validation concern; this contract specifies runtime value/operation meaning.

## 6. Floating point

`Float` has IEEE-754 binary64 semantics.

`Float32` has IEEE-754 binary32 semantics.

For `Float32`, every primitive binary arithmetic result is rounded to binary32 before becoming the result value. This is required even on hosts whose ordinary numeric expression evaluation uses wider precision.

Portable binary operations:

```text
add sub mul div
```

Comparisons follow IEEE ordered comparison behavior, including ordinary NaN behavior of equality/inequality/ordering.

This contract does not currently require a canonical NaN payload or target-independent textual rendering of arbitrary floats.

## 7. Bool and Unit

`Bool` is the two-value domain `false | true`.

`not`, conjunction, disjunction, equality, and inequality have ordinary Boolean meaning.

`Unit` is a singleton runtime value. Its physical representation may be elided by a backend.

## 8. Char

`Char` denotes a Unicode scalar value.

- `charToNat(c)` returns the Unicode code point;
- `charOfNat(n)` returns the scalar value at code point `n` when valid;
- an invalid Unicode scalar input to `charOfNat` produces U+0000.

Backends must not expose UTF-16 surrogate values as valid PSC `Char` values.

## 9. String

A PSC string is a sequence of Unicode scalar values.

Portable operations:

- `stringPush(s,c)` appends one scalar;
- `stringSingleton(c)` returns the one-character string;
- `stringLength(s)` counts Unicode scalar values, not UTF-8 bytes and not UTF-16 code units;
- `stringAppend(a,b)` concatenates scalar sequences;
- `stringUtf8ByteSize(s)` is the byte length of canonical UTF-8 encoding;
- `stringEq(a,b)` is exact sequence equality.

String positions used by the current internal position operations are UTF-8 byte offsets.

For portable v1 behavior, `stringGet`, `stringNext`, and extraction boundaries are required only for positions that are valid UTF-8 scalar boundaries (normally positions produced from zero by repeated `stringNext`). Behavior for arbitrary non-boundary internal positions is **outside the portable v1 contract** and must not be used as a cross-backend observable guarantee.

`stringAtEnd(s,p)` is true when `p` is at or beyond the UTF-8 byte size.

`stringExtract(s,b,e)` returns the scalar subsequence in the valid-boundary half-open byte interval `[b,e)`; if `b >= e`, it is empty.

## 10. Arrays

A portable PSC array is a finite **persistent value sequence**. A backend may use mutation internally only when it cannot make aliasing observable.

Semantics:

- `arrayEmptyWithCapacity(capacity)` returns an empty array; capacity is not observable;
- `arraySize(a)` returns its element count as `Nat`;
- `arrayPush(a,x)` returns `a` followed by `x`;
- `arrayGet(a,i)` has the precondition `i < size(a)`;
- `arrayGetD(a,i,d)` returns `a[i]` when in bounds and `d` otherwise;
- `arraySet(a,i,x)` has the precondition `i < size(a)` and returns a sequence differing only at `i`;
- `arraySetIfInBounds(a,i,x)` returns the updated sequence when in bounds and the original sequence when out of bounds;
- `arrayMap(f,a)` maps in increasing index order and preserves length;
- `arrayFoldl(f,init,a,start,stop)` folds left over indices `[start, min(stop,size(a)))`.

Out-of-bounds behavior for the preconditioned `arrayGet` and `arraySet` operations is not a portable v1 behavior. The verified/compiler pipeline is expected to preserve their source-level validity obligations.

## 11. Structures

Structures are immutable semantic records with declared named fields.

Construction creates a value of the named structure with the supplied field values.

Projection returns the corresponding declared field value.

Target brand symbols, Wasm GC layouts, Rust structs, object property layout, padding, and field storage are ABI details and are not RuntimeSemantics-v1.

## 12. Inductives / ADTs

An inductive value consists semantically of:

- its declared inductive type;
- exactly one constructor identity;
- the constructor's declared field values.

Pattern matching dispatches by constructor identity. Match bindings expose the corresponding declared constructor fields to the selected branch.

Target tags/discriminants/reference types are ABI details.

## 13. Functions and closures

Functions have lexical closure semantics.

A closure preserves the values required from its lexical environment.

Calls are call-by-value:

1. evaluate the function expression;
2. evaluate value arguments in source order;
3. invoke the selected function/closure with those values.

Backend stack trampolines, Rust function representations, Wasm closure structs, and direct JS functions are implementation details.

This v1 contract does not introduce effects, ambient IO, exceptions, or concurrency into portable VerifiedIR.

## 14. Unsupported operations

Unsupported target lowering is a rejection.

It is never valid to:

- change an operation's meaning to make a backend accept it;
- silently fall back to a different backend/runtime;
- substitute host-specific overflow, indexing, Unicode, or word-size semantics;
- claim full RuntimeSemantics-v1 coverage merely by declaring the contract.

A backend declaration means:

> every RuntimeSemantics-v1 operation that this backend accepts must implement the v1 meaning.

Coverage is a separate property.

## 15. Current backend coverage notes

These are implementation-status notes, not semantic definitions.

### TypeScript backend

Current implementation provides broad coverage of the v1 primitive/intrinsic set.

Notable restriction:

- `USize`/`ISize` emission rejects without an explicit target word-size profile.

### Rust backend

Current runtime uses arbitrary-precision Nat/Int and host-target fixed machine integers. It implements current string and array runtime helpers for the supported Rust subset.

Rust source/runtime representation choices are not portable semantics.

### Direct Wasm backend

Current Wasm lowering provides Nat/Int, machine integers, Float/Float32, Bool/Char/String operations and substantial array operations.

At contract freeze time, direct Wasm does **not** lower `arrayMap` or `arrayFoldl`; those operations therefore reject rather than receive alternate semantics.

The Wasm32/Wasm64 choice determines `USize`/`ISize` width.

## 16. Manifest binding

The following current packages must declare the exact RuntimeSemantics-v1 ID and hash:

```text
compiler-ir
backend-ts
backend-rust
backend-wasm
```

`compiler-ir` declares the semantics expected by its runtime intrinsics. Backend declarations bind supported lowering to the same semantics.

Driver packages do not define runtime semantics; they compose the compiler with a backend.

## 17. Compatibility

Changing physical representation does not change RuntimeSemantics-v1 when observable behavior remains equal.

Examples of ABI-only changes:

- JS BigInt helper implementation;
- Wasm GC record layout;
- Rust container type;
- closure storage layout;
- symbol/tag encoding.

Changes requiring an explicit runtime-semantics version decision include:

- Nat divide/modulo-by-zero behavior;
- machine-integer overflow interpretation;
- target word-size semantic policy;
- Float32 rounding points;
- Unicode scalar validity;
- string position model;
- observable array mutability/aliasing;
- constructor/match semantics;
- call evaluation strategy.

## 18. Conformance direction

The next assurance layer should use one backend-neutral primitive corpus evaluated through independent implementations:

```text
VerifiedIR fixture
   +-- TS -> JS
   +-- Rust -> native
   +-- direct Wasm
   +-- future direct JsIR

observable results must agree where each backend claims support
```

Unsupported coverage is reported separately from semantic disagreement.
