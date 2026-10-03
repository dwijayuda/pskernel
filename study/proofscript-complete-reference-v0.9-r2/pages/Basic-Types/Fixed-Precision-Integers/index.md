<a id="fixed-ints"></a>

# ProofScript — 20.4. Fixed-Precision Integers

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Fixed-Precision-Integers/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Fixed-Precision-Integers/index.html). Source Git blob: `c5abee0398e194113f8d3cfa144ca2e40fcf073b`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.4. Fixed-Precision Integers

Lean's standard library includes the usual assortment of fixed-width integer types. From the perspective of formalization and proofs, these types are wrappers around bitvectors of the appropriate size; the wrappers ensure that the correct implementations of e.g. arithmetic operations are applied. In compiled code, they are represented efficiently: the compiler has special support for them, as it does for other fundamental types.

<a id="The-Lean-Language-Reference--Basic-Types--Fixed-Precision-Integers--Logical-Model"></a>
### 20.4.1. Logical Model

Fixed-width integers may be unsigned or signed. Furthermore, they are available in five sizes: 8, 16, 32, and 64 bits, along with the current architecture's word size. In their logical models, the unsigned integers are structures that wrap a `BitVec` of the appropriate width. Signed integers wrap the corresponding unsigned integers, and use a twos-complement representation.

<a id="The-Lean-Language-Reference--Basic-Types--Fixed-Precision-Integers--Logical-Model--Unsigned"></a>
#### 20.4.1.1. Unsigned

<a id="USize___ofBitVec"></a>

**structure**

```text
USize : Type
```

Unsigned integers that are the size of a word on the platform's architecture.

On a 32-bit architecture, `USize` is equivalent to `UInt32`. On a 64-bit machine, it is equivalent to `UInt64`.

**Constructor**

```text
USize.ofBitVec
```

Creates a `USize` from a `BitVec System.Platform.numBits`. This function is overridden with a native implementation.

**Fields**

```text
toBitVec : BitVec System.Platform.numBits
```

Unpacks a `USize` into a `BitVec System.Platform.numBits`. This function is overridden with a native implementation.

<a id="UInt8___ofBitVec"></a>

**structure**

```text
UInt8 : Type
```

Unsigned 8-bit integers.

This type has special support in the compiler so it can be represented by an unboxed 8-bit value rather than wrapping a `BitVec 8`.

**Constructor**

```text
UInt8.ofBitVec
```

Creates a `UInt8` from a `BitVec 8`. This function is overridden with a native implementation.

**Fields**

```text
toBitVec : BitVec 8
```

Unpacks a `UInt8` into a `BitVec 8`. This function is overridden with a native implementation.

<a id="UInt16___ofBitVec"></a>

**structure**

```text
UInt16 : Type
```

Unsigned 16-bit integers.

This type has special support in the compiler so it can be represented by an unboxed 16-bit value rather than wrapping a `BitVec 16`.

**Constructor**

```text
UInt16.ofBitVec
```

Creates a `UInt16` from a `BitVec 16`. This function is overridden with a native implementation.

**Fields**

```text
toBitVec : BitVec 16
```

Unpacks a `UInt16` into a `BitVec 16`. This function is overridden with a native implementation.

<a id="UInt32___ofBitVec"></a>

**structure**

```text
UInt32 : Type
```

Unsigned 32-bit integers.

This type has special support in the compiler so it can be represented by an unboxed 32-bit value rather than wrapping a `BitVec 32`.

**Constructor**

```text
UInt32.ofBitVec
```

Creates a `UInt32` from a `BitVec 32`. This function is overridden with a native implementation.

**Fields**

```text
toBitVec : BitVec 32
```

Unpacks a `UInt32` into a `BitVec 32`. This function is overridden with a native implementation.

<a id="UInt64___ofBitVec"></a>

**structure**

```text
UInt64 : Type
```

Unsigned 64-bit integers.

This type has special support in the compiler so it can be represented by an unboxed 64-bit value rather than wrapping a `BitVec 64`.

**Constructor**

```text
UInt64.ofBitVec
```

Creates a `UInt64` from a `BitVec 64`. This function is overridden with a native implementation.

**Fields**

```text
toBitVec : BitVec 64
```

Unpacks a `UInt64` into a `BitVec 64`. This function is overridden with a native implementation.

<a id="The-Lean-Language-Reference--Basic-Types--Fixed-Precision-Integers--Logical-Model--Signed"></a>
#### 20.4.1.2. Signed

<a id="ISize___ofUSize"></a>

**structure**

```text
ISize : Type
```

Signed integers that are the size of a word on the platform's architecture.

On a 32-bit architecture, `ISize` is equivalent to `Int32`. On a 64-bit machine, it is equivalent to `Int64`. This type has special support in the compiler so it can be represented by an unboxed value.

**Constructor**

```text
ISize.ofUSize
```

**Fields**

```text
toUSize : USize
```

Converts a word-sized signed integer into the word-sized unsigned integer that is its two's complement encoding.

<a id="Int8___ofUInt8"></a>

**structure**

```text
Int8 : Type
```

Signed 8-bit integers.

This type has special support in the compiler so it can be represented by an unboxed 8-bit value.

**Constructor**

```text
Int8.ofUInt8
```

**Fields**

```text
toUInt8 : UInt8
```

Converts an 8-bit signed integer into the 8-bit unsigned integer that is its two's complement encoding.

<a id="Int16___ofUInt16"></a>

**structure**

```text
Int16 : Type
```

Signed 16-bit integers.

This type has special support in the compiler so it can be represented by an unboxed 16-bit value.

**Constructor**

```text
Int16.ofUInt16
```

**Fields**

```text
toUInt16 : UInt16
```

Converts an 16-bit signed integer into the 16-bit unsigned integer that is its two's complement encoding.

<a id="Int32___ofUInt32"></a>

**structure**

```text
Int32 : Type
```

Signed 32-bit integers.

This type has special support in the compiler so it can be represented by an unboxed 32-bit value.

**Constructor**

```text
Int32.ofUInt32
```

**Fields**

```text
toUInt32 : UInt32
```

Converts an 32-bit signed integer into the 32-bit unsigned integer that is its two's complement encoding.

<a id="Int64___ofUInt64"></a>

**structure**

```text
Int64 : Type
```

Signed 64-bit integers.

This type has special support in the compiler so it can be represented by an unboxed 64-bit value.

**Constructor**

```text
Int64.ofUInt64
```

**Fields**

```text
toUInt64 : UInt64
```

Converts an 64-bit signed integer into the 64-bit unsigned integer that is its two's complement encoding.

<a id="fixed-int-runtime"></a>
### 20.4.2. Run-Time Representation

In compiled code in contexts that require [boxed](../../Run-Time-Code/Boxing/index.md#--tech-term-Boxed) representations, fixed-width integer types that fit in one less bit than the platform's pointer size are always represented without additional allocations or indirections. This always includes `Int8`, `UInt8`, `Int16`, and `UInt16`. On 64-bit architectures, `Int32` and `UInt32` are also represented without pointers. On 32-bit architectures, `Int32` and `UInt32` require a pointer to an object on the heap. `ISize`, `USize`, `Int64` and `UInt64` may require pointers on all architectures.

Even though some fixed-with integer types require boxing in general, the compiler is able to represent them without boxing or pointer indirections in code paths that use only a specific fixed-width type rather than being polymorphic, potentially after a specialization pass. This applies in most practical situations where these types are used: their values are represented using the corresponding unsigned fixed-width C type when a constructor parameter, function parameter, function return value, or intermediate result is known to be a fixed-width integer type. The Lean run-time system includes primitives for storing fixed-width integers in constructors of [inductive types](../../The-Type-System/Inductive-Types/index.md#--tech-term-Inductive-types), and the primitive operations are defined on the corresponding C types, so boxing tends to happen at the “edges” of integer calculations rather than for each intermediate result. In contexts where other types might occur, such as the contents of polymorphic containers like `Array`, these types are boxed, even if an array is statically known to contain only a single fixed-width integer type.The monomorphic array type `ByteArray` avoids boxing for arrays of `UInt8`. Lean does not specialize the representation of inductive types or arrays. Inspecting a function's type in Lean is not sufficient to determine how fixed-width integer values will be represented, because boxed values are not eagerly unboxed—a function that projects an `Int64` from an array returns a boxed integer value.

<a id="The-Lean-Language-Reference--Basic-Types--Fixed-Precision-Integers--Syntax"></a>
### 20.4.3. Syntax

All the fixed-width integer types have `OfNat` instances, which allow numerals to be used as literals, both in expression and in pattern contexts. The signed types additionally have `Neg` instances, allowing negation to be applied.

<a id="Fixed-Width-Literals"></a>
Fixed-Width Literals 

Lean allows both decimal and hexadecimal literals to be used for types with `OfNat` instances. In this example, literal notation is used to define masks.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Permissions-_LPAR_in-Fixed-Width-Literals_RPAR_"></a>
<a id="Permissions___readable-_LPAR_in-Fixed-Width-Literals_RPAR_"></a>
<a id="Permissions___writable-_LPAR_in-Fixed-Width-Literals_RPAR_"></a>
<a id="Permissions___executable-_LPAR_in-Fixed-Width-Literals_RPAR_"></a>
<a id="Permissions___encode-_LPAR_in-Fixed-Width-Literals_RPAR_"></a>
<a id="Permissions___decode-_LPAR_in-Fixed-Width-Literals_RPAR_"></a>


```proofscript
structure Permissions where
  readable : Bool
  writable : Bool
  executable : Bool

function Permissions.encode (p : Permissions) : UInt8 :=
  let r := if p.readable then 0x01 else 0
  let w := if p.writable then 0x02 else 0
  let x := if p.executable then 0x04 else 0
  r ||| w ||| x

function Permissions.decode (i : UInt8) : Permissions :=
  ⟨i &&& 0x01 ≠ 0, i &&& 0x02 ≠ 0, i &&& 0x04 ≠ 0⟩
```

Literals that overflow their types' precision are interpreted modulus the precision. Signed types, are interpreted according to the underlying twos-complement representation.

<a id="Overflowing-Fixed-Width-Literals"></a>
Overflowing Fixed-Width Literals 

The following statements are all true:

```proofscript
example : (255 : UInt8) = 255 := by rfl
example : (256 : UInt8) = 0   := by rfl
example : (257 : UInt8) = 1   := by rfl

example : (0x7f : Int8) = 127  := by rfl
example : (0x8f : Int8) = -113 := by rfl
example : (0xff : Int8) = -1   := by rfl
```

<a id="The-Lean-Language-Reference--Basic-Types--Fixed-Precision-Integers--API-Reference"></a>
### 20.4.4. API Reference

<a id="The-Lean-Language-Reference--Basic-Types--Fixed-Precision-Integers--API-Reference--Sizes"></a>
#### 20.4.4.1. Sizes

Each fixed-width integer has a *size*, which is the number of distinct values that can be represented by the type. This is not equivalent to C's `sizeof` operator, which instead determines how many bytes the type occupies.

<a id="USize___size"></a>

**def**

```text
USize.size : Nat
```

The number of distinct values representable by `USize`, that is, `2^System.Platform.numBits`.

<a id="ISize___size"></a>

**def**

```text
ISize.size : Nat
```

The number of distinct values representable by `ISize`, that is, `2^System.Platform.numBits`.

<a id="UInt8___size"></a>

**def**

```text
UInt8.size : Nat
```

The number of distinct values representable by `UInt8`, that is, `2^8 = 256`.

<a id="Int8___size"></a>

**def**

```text
Int8.size : Nat
```

The number of distinct values representable by `Int8`, that is, `2^8 = 256`.

<a id="UInt16___size"></a>

**def**

```text
UInt16.size : Nat
```

The number of distinct values representable by `UInt16`, that is, `2^16 = 65536`.

<a id="Int16___size"></a>

**def**

```text
Int16.size : Nat
```

The number of distinct values representable by `Int16`, that is, `2^16 = 65536`.

<a id="UInt32___size"></a>

**def**

```text
UInt32.size : Nat
```

The number of distinct values representable by `UInt32`, that is, `2^32 = 4294967296`.

<a id="Int32___size"></a>

**def**

```text
Int32.size : Nat
```

The number of distinct values representable by `Int32`, that is, `2^32 = 4294967296`.

<a id="UInt64___size"></a>

**def**

```text
UInt64.size : Nat
```

The number of distinct values representable by `UInt64`, that is, `2^64 = 18446744073709551616`.

<a id="Int64___size"></a>

**def**

```text
Int64.size : Nat
```

The number of distinct values representable by `Int64`, that is, `2^64 = 18446744073709551616`.

<a id="The-Lean-Language-Reference--Basic-Types--Fixed-Precision-Integers--API-Reference--Ranges"></a>
#### 20.4.4.2. Ranges

<a id="ISize___minValue"></a>

**def**

```text
ISize.minValue : ISize
```

The smallest number that `ISize` can represent: `-2^(System.Platform.numBits - 1)`.

<a id="ISize___maxValue"></a>

**def**

```text
ISize.maxValue : ISize
```

The largest number that `ISize` can represent: `2^(System.Platform.numBits - 1) - 1`.

<a id="Int8___minValue"></a>

**def**

```text
Int8.minValue : Int8
```

The smallest number that `Int8` can represent: `-2^7 = -128`.

<a id="Int8___maxValue"></a>

**def**

```text
Int8.maxValue : Int8
```

The largest number that `Int8` can represent: `2^7 - 1 = 127`.

<a id="Int16___minValue"></a>

**def**

```text
Int16.minValue : Int16
```

The smallest number that `Int16` can represent: `-2^15 = -32768`.

<a id="Int16___maxValue"></a>

**def**

```text
Int16.maxValue : Int16
```

The largest number that `Int16` can represent: `2^15 - 1 = 32767`.

<a id="Int32___minValue"></a>

**def**

```text
Int32.minValue : Int32
```

The smallest number that `Int32` can represent: `-2^31 = -2147483648`.

<a id="Int32___maxValue"></a>

**def**

```text
Int32.maxValue : Int32
```

The largest number that `Int32` can represent: `2^31 - 1 = 2147483647`.

<a id="Int64___minValue"></a>

**def**

```text
Int64.minValue : Int64
```

The smallest number that `Int64` can represent: `-2^63 = -9223372036854775808`.

<a id="Int64___maxValue"></a>

**def**

```text
Int64.maxValue : Int64
```

The largest number that `Int64` can represent: `2^63 - 1 = 9223372036854775807`.

<a id="The-Lean-Language-Reference--Basic-Types--Fixed-Precision-Integers--API-Reference--Conversions"></a>
#### 20.4.4.3. Conversions

<a id="The-Lean-Language-Reference--Basic-Types--Fixed-Precision-Integers--API-Reference--Conversions--To-and-From--Int"></a>
##### 20.4.4.3.1. To and From Int

<a id="ISize___toInt"></a>

**def**

```text
ISize.toInt (i : ISize) : Int
```

Converts a word-sized signed integer to an arbitrary-precision integer that denotes the same number.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___toInt"></a>

**def**

```text
Int8.toInt (i : Int8) : Int
```

Converts an 8-bit signed integer to an arbitrary-precision integer that denotes the same number.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___toInt"></a>

**def**

```text
Int16.toInt (i : Int16) : Int
```

Converts a 16-bit signed integer to an arbitrary-precision integer that denotes the same number.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___toInt"></a>

**def**

```text
Int32.toInt (i : Int32) : Int
```

Converts a 32-bit signed integer to an arbitrary-precision integer that denotes the same number.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___toInt"></a>

**def**

```text
Int64.toInt (i : Int64) : Int
```

Converts a 64-bit signed integer to an arbitrary-precision integer that denotes the same number.

This function is overridden at runtime with an efficient implementation.

<a id="ISize___ofInt"></a>

**def**

```text
ISize.ofInt (i : Int) : ISize
```

Converts an arbitrary-precision integer to a word-sized signed integer, wrapping around on over- or underflow.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___ofInt"></a>

**def**

```text
Int8.ofInt (i : Int) : Int8
```

Converts an arbitrary-precision integer to an 8-bit integer, wrapping on overflow or underflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int8.ofInt 48 = 48`
- `Int8.ofInt (-115) = -115`
- `Int8.ofInt (-129) = 127`
- `Int8.ofInt (128) = -128`

<a id="Int16___ofInt"></a>

**def**

```text
Int16.ofInt (i : Int) : Int16
```

Converts an arbitrary-precision integer to a 16-bit signed integer, wrapping on overflow or underflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int16.ofInt 48 = 48`
- `Int16.ofInt (-129) = -129`
- `Int16.ofInt (128) = 128`
- `Int16.ofInt 70000 = 4464`
- `Int16.ofInt (-40000) = 25536`

<a id="Int32___ofInt"></a>

**def**

```text
Int32.ofInt (i : Int) : Int32
```

Converts an arbitrary-precision integer to a 32-bit integer, wrapping on overflow or underflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int32.ofInt 48 = 48`
- `Int32.ofInt (-129) = -129`
- `Int32.ofInt 70000 = 70000`
- `Int32.ofInt (-40000) = -40000`
- `Int32.ofInt 2147483648 = -2147483648`
- `Int32.ofInt (-2147483649) = 2147483647`

<a id="Int64___ofInt"></a>

**def**

```text
Int64.ofInt (i : Int) : Int64
```

Converts an arbitrary-precision integer to a 64-bit integer, wrapping on overflow or underflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int64.ofInt 48 = 48`
- `Int64.ofInt (-40_000) = -40_000`
- `Int64.ofInt 2_147_483_648 = 2_147_483_648`
- `Int64.ofInt (-2_147_483_649) = -2_147_483_649`
- `Int64.ofInt 9_223_372_036_854_775_808 = -9_223_372_036_854_775_808`
- `Int64.ofInt (-9_223_372_036_854_775_809) = 9_223_372_036_854_775_807`

<a id="ISize___ofIntClamp"></a>

**def**

```text
ISize.ofIntClamp (i : Int) : ISize
```

Constructs an `ISize` from an `Int`, clamping if the value is too small or too large.

<a id="Int8___ofIntClamp"></a>

**def**

```text
Int8.ofIntClamp (i : Int) : Int8
```

Constructs an `Int8` from an `Int`, clamping if the value is too small or too large.

<a id="Int16___ofIntClamp"></a>

**def**

```text
Int16.ofIntClamp (i : Int) : Int16
```

Constructs an `Int16` from an `Int`, clamping if the value is too small or too large.

<a id="Int32___ofIntClamp"></a>

**def**

```text
Int32.ofIntClamp (i : Int) : Int32
```

Constructs an `Int32` from an `Int`, clamping if the value is too small or too large.

<a id="Int64___ofIntClamp"></a>

**def**

```text
Int64.ofIntClamp (i : Int) : Int64
```

Constructs an `Int64` from an `Int`, clamping if the value is too small or too large.

<a id="ISize___ofIntLE"></a>

**def**

```text
ISize.ofIntLE (i : Int) (_hl : ISize.minValue.toInt ≤ i)
  (_hr : i ≤ ISize.maxValue.toInt) : ISize
```

Constructs an `ISize` from an `Int` that is known to be in bounds.

<a id="Int8___ofIntLE"></a>

**def**

```text
Int8.ofIntLE (i : Int) (_hl : Int8.minValue.toInt ≤ i)
  (_hr : i ≤ Int8.maxValue.toInt) : Int8
```

Constructs an `Int8` from an `Int` that is known to be in bounds.

<a id="Int16___ofIntLE"></a>

**def**

```text
Int16.ofIntLE (i : Int) (_hl : Int16.minValue.toInt ≤ i)
  (_hr : i ≤ Int16.maxValue.toInt) : Int16
```

Constructs an `Int16` from an `Int` that is known to be in bounds.

<a id="Int32___ofIntLE"></a>

**def**

```text
Int32.ofIntLE (i : Int) (_hl : Int32.minValue.toInt ≤ i)
  (_hr : i ≤ Int32.maxValue.toInt) : Int32
```

Constructs an `Int32` from an `Int` that is known to be in bounds.

<a id="Int64___ofIntLE"></a>

**def**

```text
Int64.ofIntLE (i : Int) (_hl : Int64.minValue.toInt ≤ i)
  (_hr : i ≤ Int64.maxValue.toInt) : Int64
```

Constructs an `Int64` from an `Int` that is known to be in bounds.

<a id="The-Lean-Language-Reference--Basic-Types--Fixed-Precision-Integers--API-Reference--Conversions--To-and-From--Nat"></a>
##### 20.4.4.3.2. To and From Nat

<a id="USize___ofNat"></a>

**def**

```text
USize.ofNat (n : Nat) : USize
```

Converts an arbitrary-precision natural number to an unsigned word-sized integer, wrapping around on overflow.

This function is overridden at runtime with an efficient implementation.

<a id="ISize___ofNat"></a>

**def**

```text
ISize.ofNat (n : Nat) : ISize
```

Converts an arbitrary-precision natural number to a word-sized signed integer, wrapping around on overflow.

This function is overridden at runtime with an efficient implementation.

<a id="UInt8___ofNat"></a>

**def**

```text
UInt8.ofNat (n : Nat) : UInt8
```

Converts a natural number to an 8-bit unsigned integer, wrapping on overflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `UInt8.ofNat 5 = 5`
- `UInt8.ofNat 255 = 255`
- `UInt8.ofNat 256 = 0`
- `UInt8.ofNat 259 = 3`
- `UInt8.ofNat 32770 = 2`

<a id="Int8___ofNat"></a>

**def**

```text
Int8.ofNat (n : Nat) : Int8
```

Converts a natural number to an 8-bit signed integer, wrapping around on overflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int8.ofNat 53 = 53`
- `Int8.ofNat 127 = 127`
- `Int8.ofNat 128 = -128`
- `Int8.ofNat 255 = -1`

<a id="UInt16___ofNat"></a>

**def**

```text
UInt16.ofNat (n : Nat) : UInt16
```

Converts a natural number to a 16-bit unsigned integer, wrapping on overflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `UInt16.ofNat 5 = 5`
- `UInt16.ofNat 255 = 255`
- `UInt16.ofNat 32770 = 32770`
- `UInt16.ofNat 65537 = 1`

<a id="Int16___ofNat"></a>

**def**

```text
Int16.ofNat (n : Nat) : Int16
```

Converts a natural number to a 16-bit signed integer, wrapping around on overflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int16.ofNat 127 = 127`
- `Int16.ofNat 32767 = 32767`
- `Int16.ofNat 32768 = -32768`
- `Int16.ofNat 32770 = -32766`

<a id="UInt32___ofNat"></a>

**def**

```text
UInt32.ofNat (n : Nat) : UInt32
```

Converts a natural number to a 32-bit unsigned integer, wrapping on overflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `UInt32.ofNat 5 = 5`
- `UInt32.ofNat 65539 = 65539`
- `UInt32.ofNat 4_294_967_299 = 3`

<a id="Int32___ofNat"></a>

**def**

```text
Int32.ofNat (n : Nat) : Int32
```

Converts a natural number to a 32-bit signed integer, wrapping around on overflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int32.ofNat 127 = 127`
- `Int32.ofNat 32770 = 32770`
- `Int32.ofNat 2_147_483_647 = 2_147_483_647`
- `Int32.ofNat 2_147_483_648 = -2_147_483_648`

<a id="UInt64___ofNat"></a>

**def**

```text
UInt64.ofNat (n : Nat) : UInt64
```

Converts a natural number to a 64-bit unsigned integer, wrapping on overflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `UInt64.ofNat 5 = 5`
- `UInt64.ofNat 65539 = 65539`
- `UInt64.ofNat 4_294_967_299 = 4_294_967_299`
- `UInt64.ofNat 18_446_744_073_709_551_620 = 4`

<a id="Int64___ofNat"></a>

**def**

```text
Int64.ofNat (n : Nat) : Int64
```

Converts a natural number to a 64-bit signed integer, wrapping around to negative numbers on overflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int64.ofNat 127 = 127`
- `Int64.ofNat 2_147_483_648 = 2_147_483_648`
- `Int64.ofNat 9_223_372_036_854_775_807 = 9_223_372_036_854_775_807`
- `Int64.ofNat 9_223_372_036_854_775_808 = -9_223_372_036_854_775_808`
- `Int64.ofNat 18_446_744_073_709_551_618 = 0`

<a id="USize___ofNat32"></a>

**def**

```text
USize.ofNat32 (n : Nat) (h : n < 4294967296) : USize
```

Converts a natural number to a `USize`. Overflow is impossible on any supported platform because `USize.size` is either `2^32` or `2^64`.

This function is overridden at runtime with an efficient implementation.

<a id="USize___ofNatLT"></a>

**def**

```text
USize.ofNatLT (n : Nat) (h : n < USize.size) : USize
```

Converts a natural number to a `USize`. Requires a proof that the number is small enough to be representable without overflow.

This function is overridden at runtime with an efficient implementation.

<a id="UInt8___ofNatLT"></a>

**def**

```text
UInt8.ofNatLT (n : Nat) (h : n < UInt8.size) : UInt8
```

Converts a natural number to an 8-bit unsigned integer. Requires a proof that the number is small enough to be representable without overflow; it must be smaller than `2^8`.

This function is overridden at runtime with an efficient implementation.

<a id="UInt16___ofNatLT"></a>

**def**

```text
UInt16.ofNatLT (n : Nat) (h : n < UInt16.size) : UInt16
```

Converts a natural number to a 16-bit unsigned integer. Requires a proof that the number is small enough to be representable without overflow; it must be smaller than `2^16`.

This function is overridden at runtime with an efficient implementation.

<a id="UInt32___ofNatLT"></a>

**def**

```text
UInt32.ofNatLT (n : Nat) (h : n < UInt32.size) : UInt32
```

Converts a natural number to a 32-bit unsigned integer. Requires a proof that the number is small enough to be representable without overflow; it must be smaller than `2^32`.

This function is overridden at runtime with an efficient implementation.

<a id="UInt64___ofNatLT"></a>

**def**

```text
UInt64.ofNatLT (n : Nat) (h : n < UInt64.size) : UInt64
```

Converts a natural number to a 64-bit unsigned integer. Requires a proof that the number is small enough to be representable without overflow; it must be smaller than `2^64`.

This function is overridden at runtime with an efficient implementation.

<a id="USize___ofNatClamp"></a>

**def**

```text
USize.ofNatClamp (n : Nat) : USize
```

Converts a natural number to `USize`, returning the largest representable value if the number is too large.

Returns `USize.size - 1`, which is `2^64 - 1` or `2^32 - 1` depending on the platform, for natural numbers greater than or equal to `USize.size`.

<a id="UInt8___ofNatClamp"></a>

**def**

```text
UInt8.ofNatClamp (n : Nat) : UInt8
```

Converts a natural number to an 8-bit unsigned integer, returning the largest representable value if the number is too large.

Returns `2^8 - 1` for natural numbers greater than or equal to `2^8`.

<a id="UInt16___ofNatClamp"></a>

**def**

```text
UInt16.ofNatClamp (n : Nat) : UInt16
```

Converts a natural number to a 16-bit unsigned integer, returning the largest representable value if the number is too large.

Returns `2^16 - 1` for natural numbers greater than or equal to `2^16`.

<a id="UInt32___ofNatClamp"></a>

**def**

```text
UInt32.ofNatClamp (n : Nat) : UInt32
```

Converts a natural number to a 32-bit unsigned integer, returning the largest representable value if the number is too large.

Returns `2^32 - 1` for natural numbers greater than or equal to `2^32`.

<a id="UInt64___ofNatClamp"></a>

**def**

```text
UInt64.ofNatClamp (n : Nat) : UInt64
```

Converts a natural number to a 64-bit unsigned integer, returning the largest representable value if the number is too large.

Returns `2^64 - 1` for natural numbers greater than or equal to `2^64`.

<a id="USize___toNat"></a>

**def**

```text
USize.toNat (n : USize) : Nat
```

Converts a word-sized unsigned integer to an arbitrary-precision natural number.

This function is overridden at runtime with an efficient implementation.

<a id="ISize___toNatClampNeg"></a>

**def**

```text
ISize.toNatClampNeg (i : ISize) : Nat
```

Converts a word-sized signed integer to a natural number, mapping all negative numbers to `0`.

Use `ISize.toBitVec` to obtain the two's complement representation.

<a id="UInt8___toNat"></a>

**def**

```text
UInt8.toNat (n : UInt8) : Nat
```

Converts an 8-bit unsigned integer to an arbitrary-precision natural number.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___toNatClampNeg"></a>

**def**

```text
Int8.toNatClampNeg (i : Int8) : Nat
```

Converts an 8-bit signed integer to a natural number, mapping all negative numbers to `0`.

Use `Int8.toBitVec` to obtain the two's complement representation.

<a id="UInt16___toNat"></a>

**def**

```text
UInt16.toNat (n : UInt16) : Nat
```

Converts a 16-bit unsigned integer to an arbitrary-precision natural number.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___toNatClampNeg"></a>

**def**

```text
Int16.toNatClampNeg (i : Int16) : Nat
```

Converts a 16-bit signed integer to a natural number, mapping all negative numbers to `0`.

Use `Int16.toBitVec` to obtain the two's complement representation.

<a id="UInt32___toNat"></a>

**def**

```text
UInt32.toNat (n : UInt32) : Nat
```

Converts a 32-bit unsigned integer to an arbitrary-precision natural number.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___toNatClampNeg"></a>

**def**

```text
Int32.toNatClampNeg (i : Int32) : Nat
```

Converts a 32-bit signed integer to a natural number, mapping all negative numbers to `0`.

Use `Int32.toBitVec` to obtain the two's complement representation.

<a id="UInt64___toNat"></a>

**def**

```text
UInt64.toNat (n : UInt64) : Nat
```

Converts a 64-bit unsigned integer to an arbitrary-precision natural number.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___toNatClampNeg"></a>

**def**

```text
Int64.toNatClampNeg (i : Int64) : Nat
```

Converts a 64-bit signed integer to a natural number, mapping all negative numbers to `0`.

Use `Int64.toBitVec` to obtain the two's complement representation.

<a id="The-Lean-Language-Reference--Basic-Types--Fixed-Precision-Integers--API-Reference--Conversions--To-Other-Fixed-Width-Integers"></a>
##### 20.4.4.3.3. To Other Fixed-Width Integers

<a id="USize___toUInt8"></a>

**def**

```text
USize.toUInt8 (a : USize) : UInt8
```

Converts word-sized unsigned integers to 8-bit unsigned integers. Wraps around on overflow.

This function is overridden at runtime with an efficient implementation.

<a id="USize___toUInt16"></a>

**def**

```text
USize.toUInt16 (a : USize) : UInt16
```

Converts word-sized unsigned integers to 16-bit unsigned integers. Wraps around on overflow.

This function is overridden at runtime with an efficient implementation.

<a id="USize___toUInt32"></a>

**def**

```text
USize.toUInt32 (a : USize) : UInt32
```

Converts word-sized unsigned integers to 32-bit unsigned integers. Wraps around on overflow, which might occur on 64-bit architectures.

This function is overridden at runtime with an efficient implementation.

<a id="USize___toUInt64"></a>

**def**

```text
USize.toUInt64 (a : USize) : UInt64
```

Converts word-sized unsigned integers to 32-bit unsigned integers. This cannot overflow because `USize.size` is either `2^32` or `2^64`.

This function is overridden at runtime with an efficient implementation.

<a id="USize___toISize"></a>

**def**

```text
USize.toISize (i : USize) : ISize
```

Obtains the `ISize` that is 2's complement equivalent to the `USize`.

<a id="UInt8___toInt8"></a>

**def**

```text
UInt8.toInt8 (i : UInt8) : Int8
```

Obtains the `Int8` that is 2's complement equivalent to the `UInt8`.

<a id="UInt8___toUInt16"></a>

**def**

```text
UInt8.toUInt16 (a : UInt8) : UInt16
```

Converts 8-bit unsigned integers to 16-bit unsigned integers.

This function is overridden at runtime with an efficient implementation.

<a id="UInt8___toUInt32"></a>

**def**

```text
UInt8.toUInt32 (a : UInt8) : UInt32
```

Converts 8-bit unsigned integers to 32-bit unsigned integers.

This function is overridden at runtime with an efficient implementation.

<a id="UInt8___toUInt64"></a>

**def**

```text
UInt8.toUInt64 (a : UInt8) : UInt64
```

Converts 8-bit unsigned integers to 64-bit unsigned integers.

This function is overridden at runtime with an efficient implementation.

<a id="UInt8___toUSize"></a>

**def**

```text
UInt8.toUSize (a : UInt8) : USize
```

Converts 8-bit unsigned integers to word-sized unsigned integers.

This function is overridden at runtime with an efficient implementation.

<a id="UInt16___toUInt8"></a>

**def**

```text
UInt16.toUInt8 (a : UInt16) : UInt8
```

Converts 16-bit unsigned integers to 8-bit unsigned integers. Wraps around on overflow.

This function is overridden at runtime with an efficient implementation.

<a id="UInt16___toInt16"></a>

**def**

```text
UInt16.toInt16 (i : UInt16) : Int16
```

Obtains the `Int16` that is 2's complement equivalent to the `UInt16`.

<a id="UInt16___toUInt32"></a>

**def**

```text
UInt16.toUInt32 (a : UInt16) : UInt32
```

Converts 16-bit unsigned integers to 32-bit unsigned integers.

This function is overridden at runtime with an efficient implementation.

<a id="UInt16___toUInt64"></a>

**def**

```text
UInt16.toUInt64 (a : UInt16) : UInt64
```

Converts 16-bit unsigned integers to 64-bit unsigned integers. Wraps around on overflow.

This function is overridden at runtime with an efficient implementation.

<a id="UInt16___toUSize"></a>

**def**

```text
UInt16.toUSize (a : UInt16) : USize
```

Converts 16-bit unsigned integers to word-sized unsigned integers.

This function is overridden at runtime with an efficient implementation.

<a id="UInt32___toUInt8"></a>

**def**

```text
UInt32.toUInt8 (a : UInt32) : UInt8
```

Converts a 32-bit unsigned integer to an 8-bit unsigned integer, wrapping on overflow.

This function is overridden at runtime with an efficient implementation.

<a id="UInt32___toUInt16"></a>

**def**

```text
UInt32.toUInt16 (a : UInt32) : UInt16
```

Converts 32-bit unsigned integers to 16-bit unsigned integers. Wraps around on overflow.

This function is overridden at runtime with an efficient implementation.

<a id="UInt32___toInt32"></a>

**def**

```text
UInt32.toInt32 (i : UInt32) : Int32
```

Obtains the `Int32` that is 2's complement equivalent to the `UInt32`.

<a id="UInt32___toUInt64"></a>

**def**

```text
UInt32.toUInt64 (a : UInt32) : UInt64
```

Converts 32-bit unsigned integers to 64-bit unsigned integers. Wraps around on overflow.

This function is overridden at runtime with an efficient implementation.

<a id="UInt32___toUSize"></a>

**def**

```text
UInt32.toUSize (a : UInt32) : USize
```

Converts 32-bit unsigned integers to word-sized unsigned integers.

This function is overridden at runtime with an efficient implementation.

<a id="UInt64___toUInt8"></a>

**def**

```text
UInt64.toUInt8 (a : UInt64) : UInt8
```

Converts 64-bit unsigned integers to 8-bit unsigned integers. Wraps around on overflow.

This function is overridden at runtime with an efficient implementation.

<a id="UInt64___toUInt16"></a>

**def**

```text
UInt64.toUInt16 (a : UInt64) : UInt16
```

Converts 64-bit unsigned integers to 16-bit unsigned integers. Wraps around on overflow.

This function is overridden at runtime with an efficient implementation.

<a id="UInt64___toUInt32"></a>

**def**

```text
UInt64.toUInt32 (a : UInt64) : UInt32
```

Converts 64-bit unsigned integers to 32-bit unsigned integers. Wraps around on overflow.

This function is overridden at runtime with an efficient implementation.

<a id="UInt64___toInt64"></a>

**def**

```text
UInt64.toInt64 (i : UInt64) : Int64
```

Obtains the `Int64` that is 2's complement equivalent to the `UInt64`.

<a id="UInt64___toUSize"></a>

**def**

```text
UInt64.toUSize (a : UInt64) : USize
```

Converts 64-bit unsigned integers to word-sized unsigned integers. On 32-bit machines, this may overflow, which results in the value wrapping around (that is, it is reduced modulo `USize.size`).

This function is overridden at runtime with an efficient implementation.

<a id="ISize___toInt8"></a>

**def**

```text
ISize.toInt8 (a : ISize) : Int8
```

Converts a word-sized signed integer to an 8-bit signed integer by truncating its bitvector representation.

This function is overridden at runtime with an efficient implementation.

<a id="ISize___toInt16"></a>

**def**

```text
ISize.toInt16 (a : ISize) : Int16
```

Converts a word-sized integer to a 16-bit integer by truncating its bitvector representation.

This function is overridden at runtime with an efficient implementation.

<a id="ISize___toInt32"></a>

**def**

```text
ISize.toInt32 (a : ISize) : Int32
```

Converts a word-sized signed integer to a 32-bit signed integer.

On 32-bit platforms, this conversion is lossless. On 64-bit platforms, the integer's bitvector representation is truncated to 32 bits. This function is overridden at runtime with an efficient implementation.

This function is overridden at runtime with an efficient implementation.

<a id="ISize___toInt64"></a>

**def**

```text
ISize.toInt64 (a : ISize) : Int64
```

Converts word-sized signed integers to 64-bit signed integers that denote the same number. This conversion is lossless, because `ISize` is either `Int32` or `Int64`.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___toInt16"></a>

**def**

```text
Int8.toInt16 (a : Int8) : Int16
```

Converts 8-bit signed integers to 16-bit signed integers that denote the same number.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___toInt32"></a>

**def**

```text
Int8.toInt32 (a : Int8) : Int32
```

Converts 8-bit signed integers to 32-bit signed integers that denote the same number.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___toInt64"></a>

**def**

```text
Int8.toInt64 (a : Int8) : Int64
```

Converts 8-bit signed integers to 64-bit signed integers that denote the same number.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___toISize"></a>

**def**

```text
Int8.toISize (a : Int8) : ISize
```

Converts 8-bit signed integers to word-sized signed integers that denote the same number. This conversion is lossless, because `ISize` is either `Int32` or `Int64`.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___toInt8"></a>

**def**

```text
Int16.toInt8 (a : Int16) : Int8
```

Converts 16-bit signed integers to 8-bit signed integers by truncating their bitvector representation.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___toInt32"></a>

**def**

```text
Int16.toInt32 (a : Int16) : Int32
```

Converts 8-bit signed integers to 32-bit signed integers that denote the same number.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___toInt64"></a>

**def**

```text
Int16.toInt64 (a : Int16) : Int64
```

Converts 16-bit signed integers to 64-bit signed integers that denote the same number.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___toISize"></a>

**def**

```text
Int16.toISize (a : Int16) : ISize
```

Converts 16-bit signed integers to word-sized signed integers that denote the same number. This conversion is lossless, because `ISize` is either `Int32` or `Int64`.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___toInt8"></a>

**def**

```text
Int32.toInt8 (a : Int32) : Int8
```

Converts a 32-bit signed integer to an 8-bit signed integer by truncating its bitvector representation.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___toInt16"></a>

**def**

```text
Int32.toInt16 (a : Int32) : Int16
```

Converts a 32-bit signed integer to an 16-bit signed integer by truncating its bitvector representation.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___toInt64"></a>

**def**

```text
Int32.toInt64 (a : Int32) : Int64
```

Converts 32-bit signed integers to 64-bit signed integers that denote the same number.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___toISize"></a>

**def**

```text
Int32.toISize (a : Int32) : ISize
```

Converts 32-bit signed integers to word-sized signed integers that denote the same number. This conversion is lossless, because `ISize` is either `Int32` or `Int64`.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___toInt8"></a>

**def**

```text
Int64.toInt8 (a : Int64) : Int8
```

Converts a 64-bit signed integer to an 8-bit signed integer by truncating its bitvector representation.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___toInt16"></a>

**def**

```text
Int64.toInt16 (a : Int64) : Int16
```

Converts a 64-bit signed integer to a 16-bit signed integer by truncating its bitvector representation.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___toInt32"></a>

**def**

```text
Int64.toInt32 (a : Int64) : Int32
```

Converts a 64-bit signed integer to a 32-bit signed integer by truncating its bitvector representation.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___toISize"></a>

**def**

```text
Int64.toISize (a : Int64) : ISize
```

Converts 64-bit signed integers to word-sized signed integers, truncating the bitvector representation on 32-bit platforms. This conversion is lossless on 64-bit platforms.

This function is overridden at runtime with an efficient implementation.

<a id="The-Lean-Language-Reference--Basic-Types--Fixed-Precision-Integers--API-Reference--Conversions--To-Floating-Point-Numbers"></a>
##### 20.4.4.3.4. To Floating-Point Numbers

<a id="ISize___toFloat"></a>

**def**

```text
ISize.toFloat (n : ISize) : Float
```

Obtains a `Float` whose value is near the given `ISize`.

It will be exactly the value of the given `ISize` if such a `Float` exists. If no such `Float` exists, the returned value will either be the smallest `Float` that is larger than the given value, or the largest `Float` that is smaller than the given value.

This function has a logical model in terms of `Float.Model`, but is overridden at runtime with an efficient implementation.

<a id="ISize___toFloat32"></a>

**def**

```text
ISize.toFloat32 (n : ISize) : Float32
```

Obtains a `Float32` whose value is near the given `ISize`.

It will be exactly the value of the given `ISize` if such a `Float32` exists. If no such `Float32` exists, the returned value will either be the smallest `Float32` that is larger than the given value, or the largest `Float32` that is smaller than the given value.

This function has a logical model in terms of `Float32.Model`, but is overridden at runtime with an efficient implementation.

<a id="Int8___toFloat"></a>

**def**

```text
Int8.toFloat (n : Int8) : Float
```

Obtains the `Float` whose value is the same as the given `Int8`.

<a id="Int8___toFloat32"></a>

**def**

```text
Int8.toFloat32 (n : Int8) : Float32
```

Obtains the `Float32` whose value is the same as the given `Int8`.

<a id="Int16___toFloat"></a>

**def**

```text
Int16.toFloat (n : Int16) : Float
```

Obtains the `Float` whose value is the same as the given `Int16`.

<a id="Int16___toFloat32"></a>

**def**

```text
Int16.toFloat32 (n : Int16) : Float32
```

Obtains the `Float32` whose value is the same as the given `Int16`.

<a id="Int32___toFloat"></a>

**def**

```text
Int32.toFloat (n : Int32) : Float
```

Obtains the `Float` whose value is the same as the given `Int32`.

<a id="Int32___toFloat32"></a>

**def**

```text
Int32.toFloat32 (n : Int32) : Float32
```

Obtains a `Float32` whose value is near the given `Int32`.

It will be exactly the value of the given `Int32` if such a `Float32` exists. If no such `Float32` exists, the returned value will either be the smallest `Float32` that is larger than the given value, or the largest `Float32` that is smaller than the given value.

This function has a logical model in terms of `Float32.Model`, but is overridden at runtime with an efficient implementation.

<a id="Int64___toFloat"></a>

**def**

```text
Int64.toFloat (n : Int64) : Float
```

Obtains a `Float` whose value is near the given `Int64`.

It will be exactly the value of the given `Int64` if such a `Float` exists. If no such `Float` exists, the returned value will either be the smallest `Float` that is larger than the given value, or the largest `Float` that is smaller than the given value.

This function has a logical model in terms of `Float.Model`, but is overridden at runtime with an efficient implementation.

<a id="Int64___toFloat32"></a>

**def**

```text
Int64.toFloat32 (n : Int64) : Float32
```

Obtains a `Float32` whose value is near the given `Int64`.

It will be exactly the value of the given `Int64` if such a `Float32` exists. If no such `Float32` exists, the returned value will either be the smallest `Float32` that is larger than the given value, or the largest `Float32` that is smaller than the given value.

This function has a logical model in terms of `Float32.Model`, but is overridden at runtime with an efficient implementation.

<a id="USize___toFloat"></a>

**def**

```text
USize.toFloat (n : USize) : Float
```

Obtains a `Float` whose value is near the given `USize`.

It will be exactly the value of the given `USize` if such a `Float` exists. If no such `Float` exists, the returned value will either be the smallest `Float` that is larger than the given value, or the largest `Float` that is smaller than the given value.

This function has a logical model in terms of `Float.Model`, but is overridden at runtime with an efficient implementation.

<a id="USize___toFloat32"></a>

**def**

```text
USize.toFloat32 (n : USize) : Float32
```

Obtains a `Float32` whose value is near the given `USize`.

It will be exactly the value of the given `USize` if such a `Float32` exists. If no such `Float32` exists, the returned value will either be the smallest `Float32` that is larger than the given value, or the largest `Float32` that is smaller than the given value.

This function has a logical model in terms of `Float32.Model`, but is overridden at runtime with an efficient implementation.

<a id="UInt8___toFloat"></a>

**def**

```text
UInt8.toFloat (n : UInt8) : Float
```

Obtains the `Float` whose value is the same as the given `UInt8`.

<a id="UInt8___toFloat32"></a>

**def**

```text
UInt8.toFloat32 (n : UInt8) : Float32
```

Obtains the `Float32` whose value is the same as the given `UInt8`.

<a id="UInt16___toFloat"></a>

**def**

```text
UInt16.toFloat (n : UInt16) : Float
```

Obtains the `Float` whose value is the same as the given `UInt16`.

<a id="UInt16___toFloat32"></a>

**def**

```text
UInt16.toFloat32 (n : UInt16) : Float32
```

Obtains the `Float32` whose value is the same as the given `UInt16`.

<a id="UInt32___toFloat"></a>

**def**

```text
UInt32.toFloat (n : UInt32) : Float
```

Obtains the `Float` whose value is the same as the given `UInt32`.

<a id="UInt32___toFloat32"></a>

**def**

```text
UInt32.toFloat32 (n : UInt32) : Float32
```

Obtains a `Float32` whose value is near the given `UInt32`.

It will be exactly the value of the given `UInt32` if such a `Float32` exists. If no such `Float32` exists, the returned value will either be the smallest `Float32` that is larger than the given value, or the largest `Float32` that is smaller than the given value.

This function has a logical model in terms of `Float32.Model`, but is overridden at runtime with an efficient implementation.

<a id="UInt64___toFloat"></a>

**def**

```text
UInt64.toFloat (n : UInt64) : Float
```

Obtains a `Float` whose value is near the given `UInt64`.

It will be exactly the value of the given `UInt64` if such a `Float` exists. If no such `Float` exists, the returned value will either be the smallest `Float` that is larger than the given value, or the largest `Float` that is smaller than the given value.

This function has a logical model in terms of `Float.Model`, but is overridden at runtime with an efficient implementation.

<a id="UInt64___toFloat32"></a>

**def**

```text
UInt64.toFloat32 (n : UInt64) : Float32
```

Obtains a `Float32` whose value is near the given `UInt64`.

It will be exactly the value of the given `UInt64` if such a `Float32` exists. If no such `Float32` exists, the returned value will either be the smallest `Float32` that is larger than the given value, or the largest `Float32` that is smaller than the given value.

This function has a logical model in terms of `Float32.Model`, but is overridden at runtime with an efficient implementation.

<a id="The-Lean-Language-Reference--Basic-Types--Fixed-Precision-Integers--API-Reference--Conversions--To-and-From-Bitvectors"></a>
##### 20.4.4.3.5. To and From Bitvectors

<a id="ISize___toBitVec"></a>

**def**

```text
ISize.toBitVec (x : ISize) : BitVec System.Platform.numBits
```

Obtain the `BitVec` that contains the 2's complement representation of the `ISize`.

<a id="ISize___ofBitVec"></a>

**def**

```text
ISize.ofBitVec (b : BitVec System.Platform.numBits) : ISize
```

Obtains the `ISize` whose 2's complement representation is the given `BitVec`.

<a id="Int8___toBitVec"></a>

**def**

```text
Int8.toBitVec (x : Int8) : BitVec 8
```

Obtain the `BitVec` that contains the 2's complement representation of the `Int8`.

<a id="Int8___ofBitVec"></a>

**def**

```text
Int8.ofBitVec (b : BitVec 8) : Int8
```

Obtains the `Int8` whose 2's complement representation is the given `BitVec 8`.

<a id="Int16___toBitVec"></a>

**def**

```text
Int16.toBitVec (x : Int16) : BitVec 16
```

Obtain the `BitVec` that contains the 2's complement representation of the `Int16`.

<a id="Int16___ofBitVec"></a>

**def**

```text
Int16.ofBitVec (b : BitVec 16) : Int16
```

Obtains the `Int16` whose 2's complement representation is the given `BitVec 16`.

<a id="Int32___toBitVec"></a>

**def**

```text
Int32.toBitVec (x : Int32) : BitVec 32
```

Obtain the `BitVec` that contains the 2's complement representation of the `Int32`.

<a id="Int32___ofBitVec"></a>

**def**

```text
Int32.ofBitVec (b : BitVec 32) : Int32
```

Obtains the `Int32` whose 2's complement representation is the given `BitVec 32`.

<a id="Int64___toBitVec"></a>

**def**

```text
Int64.toBitVec (x : Int64) : BitVec 64
```

Obtain the `BitVec` that contains the 2's complement representation of the `Int64`.

<a id="Int64___ofBitVec"></a>

**def**

```text
Int64.ofBitVec (b : BitVec 64) : Int64
```

Obtains the `Int64` whose 2's complement representation is the given `BitVec 64`.

<a id="The-Lean-Language-Reference--Basic-Types--Fixed-Precision-Integers--API-Reference--Conversions--To-and-From-Finite-Numbers"></a>
##### 20.4.4.3.6. To and From Finite Numbers

<a id="USize___toFin"></a>

**def**

```text
USize.toFin (x : USize) : Fin USize.size
```

Converts a `USize` into the corresponding `Fin USize.size`.

<a id="UInt8___toFin"></a>

**def**

```text
UInt8.toFin (x : UInt8) : Fin UInt8.size
```

Converts a `UInt8` into the corresponding `Fin UInt8.size`.

<a id="UInt16___toFin"></a>

**def**

```text
UInt16.toFin (x : UInt16) : Fin UInt16.size
```

Converts a `UInt16` into the corresponding `Fin UInt16.size`.

<a id="UInt32___toFin"></a>

**def**

```text
UInt32.toFin (x : UInt32) : Fin UInt32.size
```

Converts a `UInt32` into the corresponding `Fin UInt32.size`.

<a id="UInt64___toFin"></a>

**def**

```text
UInt64.toFin (x : UInt64) : Fin UInt64.size
```

Converts a `UInt64` into the corresponding `Fin UInt64.size`.

<a id="USize___ofFin"></a>

**def**

```text
USize.ofFin (a : Fin USize.size) : USize
```

Converts a `Fin USize.size` into the corresponding `USize`.

<a id="UInt8___ofFin"></a>

**def**

```text
UInt8.ofFin (a : Fin UInt8.size) : UInt8
```

Converts a `Fin UInt8.size` into the corresponding `UInt8`.

<a id="UInt16___ofFin"></a>

**def**

```text
UInt16.ofFin (a : Fin UInt16.size) : UInt16
```

Converts a `Fin UInt16.size` into the corresponding `UInt16`.

<a id="UInt32___ofFin"></a>

**def**

```text
UInt32.ofFin (a : Fin UInt32.size) : UInt32
```

Converts a `Fin UInt32.size` into the corresponding `UInt32`.

<a id="UInt64___ofFin"></a>

**def**

```text
UInt64.ofFin (a : Fin UInt64.size) : UInt64
```

Converts a `Fin UInt64.size` into the corresponding `UInt64`.

<a id="USize___repr"></a>

**def**

```text
USize.repr (n : USize) : String
```

Converts a word-sized unsigned integer into a decimal string.

This function is overridden at runtime with an efficient implementation.

Examples:

- `USize.repr 0 = "0"`
- `USize.repr 28 = "28"`
- `USize.repr 307 = "307"`

<a id="The-Lean-Language-Reference--Basic-Types--Fixed-Precision-Integers--API-Reference--Conversions--To-Characters"></a>
##### 20.4.4.3.7. To Characters

The `Char` type is a wrapper around `UInt32` that requires a proof that the wrapped integer represents a Unicode code point. This predicate is part of the `UInt32` API.

<a id="UInt32___isValidChar"></a>

**def**

```text
UInt32.isValidChar (n : UInt32) : Prop
```

A `UInt32` denotes a valid Unicode code point if it is less than `0x110000` and it is also not a surrogate code point (the range `0xd800` to `0xdfff` inclusive).

<a id="fixed-int-comparisons"></a>
#### 20.4.4.4. Comparisons

The operators in this section are rarely invoked by name. Typically, comparisons operations on fixed-width integers should use the decidability of the corresponding relations, which consist of the equality type `Eq` and those implemented in instances of `LE` and `LT`.

<a id="USize___le"></a>

**def**

```text
USize.le (a b : USize) : Prop
```

Non-strict inequality of word-sized unsigned integers, defined as inequality of the corresponding natural numbers. Usually accessed via the `≤` operator.

<a id="ISize___le"></a>

**def**

```text
ISize.le (a b : ISize) : Prop
```

Non-strict inequality of word-sized signed integers, defined as inequality of the corresponding integers. Usually accessed via the `≤` operator.

<a id="UInt8___le"></a>

**def**

```text
UInt8.le (a b : UInt8) : Prop
```

Non-strict inequality of 8-bit unsigned integers, defined as inequality of the corresponding natural numbers. Usually accessed via the `≤` operator.

<a id="Int8___le"></a>

**def**

```text
Int8.le (a b : Int8) : Prop
```

Non-strict inequality of 8-bit signed integers, defined as inequality of the corresponding integers. Usually accessed via the `≤` operator.

<a id="UInt16___le"></a>

**def**

```text
UInt16.le (a b : UInt16) : Prop
```

Non-strict inequality of 16-bit unsigned integers, defined as inequality of the corresponding natural numbers. Usually accessed via the `≤` operator.

<a id="Int16___le"></a>

**def**

```text
Int16.le (a b : Int16) : Prop
```

Non-strict inequality of 16-bit signed integers, defined as inequality of the corresponding integers. Usually accessed via the `≤` operator.

<a id="UInt32___le"></a>

**def**

```text
UInt32.le (a b : UInt32) : Prop
```

Non-strict inequality of 32-bit unsigned integers, defined as inequality of the corresponding natural numbers. Usually accessed via the `≤` operator.

<a id="Int32___le"></a>

**def**

```text
Int32.le (a b : Int32) : Prop
```

Non-strict inequality of 32-bit signed integers, defined as inequality of the corresponding integers. Usually accessed via the `≤` operator.

<a id="UInt64___le"></a>

**def**

```text
UInt64.le (a b : UInt64) : Prop
```

Non-strict inequality of 64-bit unsigned integers, defined as inequality of the corresponding natural numbers. Usually accessed via the `≤` operator.

<a id="Int64___le"></a>

**def**

```text
Int64.le (a b : Int64) : Prop
```

Non-strict inequality of 64-bit signed integers, defined as inequality of the corresponding integers. Usually accessed via the `≤` operator.

<a id="USize___lt"></a>

**def**

```text
USize.lt (a b : USize) : Prop
```

Strict inequality of word-sized unsigned integers, defined as inequality of the corresponding natural numbers. Usually accessed via the `<` operator.

<a id="ISize___lt"></a>

**def**

```text
ISize.lt (a b : ISize) : Prop
```

Strict inequality of word-sized signed integers, defined as inequality of the corresponding integers. Usually accessed via the `<` operator.

<a id="UInt8___lt"></a>

**def**

```text
UInt8.lt (a b : UInt8) : Prop
```

Strict inequality of 8-bit unsigned integers, defined as inequality of the corresponding natural numbers. Usually accessed via the `<` operator.

<a id="Int8___lt"></a>

**def**

```text
Int8.lt (a b : Int8) : Prop
```

Strict inequality of 8-bit signed integers, defined as inequality of the corresponding integers. Usually accessed via the `<` operator.

<a id="UInt16___lt"></a>

**def**

```text
UInt16.lt (a b : UInt16) : Prop
```

Strict inequality of 16-bit unsigned integers, defined as inequality of the corresponding natural numbers. Usually accessed via the `<` operator.

<a id="Int16___lt"></a>

**def**

```text
Int16.lt (a b : Int16) : Prop
```

Strict inequality of 16-bit signed integers, defined as inequality of the corresponding integers. Usually accessed via the `<` operator.

<a id="UInt32___lt"></a>

**def**

```text
UInt32.lt (a b : UInt32) : Prop
```

Strict inequality of 32-bit unsigned integers, defined as inequality of the corresponding natural numbers. Usually accessed via the `<` operator.

<a id="Int32___lt"></a>

**def**

```text
Int32.lt (a b : Int32) : Prop
```

Strict inequality of 32-bit signed integers, defined as inequality of the corresponding integers. Usually accessed via the `<` operator.

<a id="UInt64___lt"></a>

**def**

```text
UInt64.lt (a b : UInt64) : Prop
```

Strict inequality of 64-bit unsigned integers, defined as inequality of the corresponding natural numbers. Usually accessed via the `<` operator.

<a id="Int64___lt"></a>

**def**

```text
Int64.lt (a b : Int64) : Prop
```

Strict inequality of 64-bit signed integers, defined as inequality of the corresponding integers. Usually accessed via the `<` operator.

<a id="USize___decEq"></a>

**def**

```text
USize.decEq (a b : USize) : Decidable (a = b)
```

Decides whether two word-sized unsigned integers are equal. Usually accessed via the `DecidableEq USize` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `USize.decEq 123 123 = .isTrue rfl`
- `(if (6 : USize) = 7 then "yes" else "no") = "no"`
- `show (7 : USize) = 7 by decide`

<a id="ISize___decEq"></a>

**def**

```text
ISize.decEq (a b : ISize) : Decidable (a = b)
```

Decides whether two word-sized signed integers are equal. Usually accessed via the `DecidableEq ISize` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `ISize.decEq 123 123 = .isTrue rfl`
- `(if ((-7) : ISize) = 7 then "yes" else "no") = "no"`
- `show (7 : ISize) = 7 by decide`

<a id="UInt8___decEq"></a>

**def**

```text
UInt8.decEq (a b : UInt8) : Decidable (a = b)
```

Decides whether two 8-bit unsigned integers are equal. Usually accessed via the `DecidableEq UInt8` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `UInt8.decEq 123 123 = .isTrue rfl`
- `(if (6 : UInt8) = 7 then "yes" else "no") = "no"`
- `show (7 : UInt8) = 7 by decide`

<a id="Int8___decEq"></a>

**def**

```text
Int8.decEq (a b : Int8) : Decidable (a = b)
```

Decides whether two 8-bit signed integers are equal. Usually accessed via the `DecidableEq Int8` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int8.decEq 123 123 = .isTrue rfl`
- `(if ((-7) : Int8) = 7 then "yes" else "no") = "no"`
- `show (7 : Int8) = 7 by decide`

<a id="UInt16___decEq"></a>

**def**

```text
UInt16.decEq (a b : UInt16) : Decidable (a = b)
```

Decides whether two 16-bit unsigned integers are equal. Usually accessed via the `DecidableEq UInt16` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `UInt16.decEq 123 123 = .isTrue rfl`
- `(if (6 : UInt16) = 7 then "yes" else "no") = "no"`
- `show (7 : UInt16) = 7 by decide`

<a id="Int16___decEq"></a>

**def**

```text
Int16.decEq (a b : Int16) : Decidable (a = b)
```

Decides whether two 16-bit signed integers are equal. Usually accessed via the `DecidableEq Int16` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int16.decEq 123 123 = .isTrue rfl`
- `(if ((-7) : Int16) = 7 then "yes" else "no") = "no"`
- `show (7 : Int16) = 7 by decide`

<a id="UInt32___decEq"></a>

**def**

```text
UInt32.decEq (a b : UInt32) : Decidable (a = b)
```

Decides whether two 32-bit unsigned integers are equal. Usually accessed via the `DecidableEq UInt32` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `UInt32.decEq 123 123 = .isTrue rfl`
- `(if (6 : UInt32) = 7 then "yes" else "no") = "no"`
- `show (7 : UInt32) = 7 by decide`

<a id="Int32___decEq"></a>

**def**

```text
Int32.decEq (a b : Int32) : Decidable (a = b)
```

Decides whether two 32-bit signed integers are equal. Usually accessed via the `DecidableEq Int32` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int32.decEq 123 123 = .isTrue rfl`
- `(if ((-7) : Int32) = 7 then "yes" else "no") = "no"`
- `show (7 : Int32) = 7 by decide`

<a id="UInt64___decEq"></a>

**def**

```text
UInt64.decEq (a b : UInt64) : Decidable (a = b)
```

Decides whether two 64-bit unsigned integers are equal. Usually accessed via the `DecidableEq UInt64` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `UInt64.decEq 123 123 = .isTrue rfl`
- `(if (6 : UInt64) = 7 then "yes" else "no") = "no"`
- `show (7 : UInt64) = 7 by decide`

<a id="Int64___decEq"></a>

**def**

```text
Int64.decEq (a b : Int64) : Decidable (a = b)
```

Decides whether two 64-bit signed integers are equal. Usually accessed via the `DecidableEq Int64` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int64.decEq 123 123 = .isTrue rfl`
- `(if ((-7) : Int64) = 7 then "yes" else "no") = "no"`
- `show (7 : Int64) = 7 by decide`

<a id="USize___decLe"></a>

**def**

```text
USize.decLe (a b : USize) : Decidable (a ≤ b)
```

Decides whether one word-sized unsigned integer is less than or equal to another. Usually accessed via the `DecidableLE USize` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if (15 : USize) ≤ 15 then "yes" else "no") = "yes"`
- `(if (15 : USize) ≤ 5 then "yes" else "no") = "no"`
- `(if (5 : USize) ≤ 15 then "yes" else "no") = "yes"`
- `show (7 : USize) ≤ 7 by decide`

<a id="ISize___decLe"></a>

**def**

```text
ISize.decLe (a b : ISize) : Decidable (a ≤ b)
```

Decides whether one word-sized signed integer is less than or equal to another. Usually accessed via the `DecidableLE ISize` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if ((-7) : ISize) ≤ 7 then "yes" else "no") = "yes"`
- `(if (15 : ISize) ≤ 15 then "yes" else "no") = "yes"`
- `(if (15 : ISize) ≤ 5 then "yes" else "no") = "no"`
- `show (7 : ISize) ≤ 7 by decide`

<a id="UInt8___decLe"></a>

**def**

```text
UInt8.decLe (a b : UInt8) : Decidable (a ≤ b)
```

Decides whether one 8-bit unsigned integer is less than or equal to another. Usually accessed via the `DecidableLE UInt8` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if (15 : UInt8) ≤ 15 then "yes" else "no") = "yes"`
- `(if (15 : UInt8) ≤ 5 then "yes" else "no") = "no"`
- `(if (5 : UInt8) ≤ 15 then "yes" else "no") = "yes"`
- `show (7 : UInt8) ≤ 7 by decide`

<a id="Int8___decLe"></a>

**def**

```text
Int8.decLe (a b : Int8) : Decidable (a ≤ b)
```

Decides whether one 8-bit signed integer is less than or equal to another. Usually accessed via the `DecidableLE Int8` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if ((-7) : Int8) ≤ 7 then "yes" else "no") = "yes"`
- `(if (15 : Int8) ≤ 15 then "yes" else "no") = "yes"`
- `(if (15 : Int8) ≤ 5 then "yes" else "no") = "no"`
- `show (7 : Int8) ≤ 7 by decide`

<a id="UInt16___decLe"></a>

**def**

```text
UInt16.decLe (a b : UInt16) : Decidable (a ≤ b)
```

Decides whether one 16-bit unsigned integer is less than or equal to another. Usually accessed via the `DecidableLE UInt16` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if (15 : UInt16) ≤ 15 then "yes" else "no") = "yes"`
- `(if (15 : UInt16) ≤ 5 then "yes" else "no") = "no"`
- `(if (5 : UInt16) ≤ 15 then "yes" else "no") = "yes"`
- `show (7 : UInt16) ≤ 7 by decide`

<a id="Int16___decLe"></a>

**def**

```text
Int16.decLe (a b : Int16) : Decidable (a ≤ b)
```

Decides whether one 16-bit signed integer is less than or equal to another. Usually accessed via the `DecidableLE Int16` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if ((-7) : Int16) ≤ 7 then "yes" else "no") = "yes"`
- `(if (15 : Int16) ≤ 15 then "yes" else "no") = "yes"`
- `(if (15 : Int16) ≤ 5 then "yes" else "no") = "no"`
- `show (7 : Int16) ≤ 7 by decide`

<a id="UInt32___decLe"></a>

**def**

```text
UInt32.decLe (a b : UInt32) : Decidable (a ≤ b)
```

Decides whether one 32-bit signed integer is less than or equal to another. Usually accessed via the `DecidableLE UInt32` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if (15 : UInt32) ≤ 15 then "yes" else "no") = "yes"`
- `(if (15 : UInt32) ≤ 5 then "yes" else "no") = "no"`
- `(if (5 : UInt32) ≤ 15 then "yes" else "no") = "yes"`
- `show (7 : UInt32) ≤ 7 by decide`

<a id="Int32___decLe"></a>

**def**

```text
Int32.decLe (a b : Int32) : Decidable (a ≤ b)
```

Decides whether one 32-bit signed integer is less than or equal to another. Usually accessed via the `DecidableLE Int32` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if ((-7) : Int32) ≤ 7 then "yes" else "no") = "yes"`
- `(if (15 : Int32) ≤ 15 then "yes" else "no") = "yes"`
- `(if (15 : Int32) ≤ 5 then "yes" else "no") = "no"`
- `show (7 : Int32) ≤ 7 by decide`

<a id="UInt64___decLe"></a>

**def**

```text
UInt64.decLe (a b : UInt64) : Decidable (a ≤ b)
```

Decides whether one 64-bit unsigned integer is less than or equal to another. Usually accessed via the `DecidableLE UInt64` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if (15 : UInt64) ≤ 15 then "yes" else "no") = "yes"`
- `(if (15 : UInt64) ≤ 5 then "yes" else "no") = "no"`
- `(if (5 : UInt64) ≤ 15 then "yes" else "no") = "yes"`
- `show (7 : UInt64) ≤ 7 by decide`

<a id="Int64___decLe"></a>

**def**

```text
Int64.decLe (a b : Int64) : Decidable (a ≤ b)
```

Decides whether one 8-bit signed integer is less than or equal to another. Usually accessed via the `DecidableLE Int64` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if ((-7) : Int64) ≤ 7 then "yes" else "no") = "yes"`
- `(if (15 : Int64) ≤ 15 then "yes" else "no") = "yes"`
- `(if (15 : Int64) ≤ 5 then "yes" else "no") = "no"`
- `show (7 : Int64) ≤ 7 by decide`

<a id="USize___decLt"></a>

**def**

```text
USize.decLt (a b : USize) : Decidable (a < b)
```

Decides whether one word-sized unsigned integer is strictly less than another. Usually accessed via the `DecidableLT USize` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if (6 : USize) < 7 then "yes" else "no") = "yes"`
- `(if (5 : USize) < 5 then "yes" else "no") = "no"`
- `show ¬((7 : USize) < 7) by decide`

<a id="ISize___decLt"></a>

**def**

```text
ISize.decLt (a b : ISize) : Decidable (a < b)
```

Decides whether one word-sized signed integer is strictly less than another. Usually accessed via the `DecidableLT ISize` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if ((-7) : ISize) < 7 then "yes" else "no") = "yes"`
- `(if (5 : ISize) < 5 then "yes" else "no") = "no"`
- `show ¬((7 : ISize) < 7) by decide`

<a id="UInt8___decLt"></a>

**def**

```text
UInt8.decLt (a b : UInt8) : Decidable (a < b)
```

Decides whether one 8-bit unsigned integer is strictly less than another. Usually accessed via the `DecidableLT UInt8` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if (6 : UInt8) < 7 then "yes" else "no") = "yes"`
- `(if (5 : UInt8) < 5 then "yes" else "no") = "no"`
- `show ¬((7 : UInt8) < 7) by decide`

<a id="Int8___decLt"></a>

**def**

```text
Int8.decLt (a b : Int8) : Decidable (a < b)
```

Decides whether one 8-bit signed integer is strictly less than another. Usually accessed via the `DecidableLT Int8` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if ((-7) : Int8) < 7 then "yes" else "no") = "yes"`
- `(if (5 : Int8) < 5 then "yes" else "no") = "no"`
- `show ¬((7 : Int8) < 7) by decide`

<a id="UInt16___decLt"></a>

**def**

```text
UInt16.decLt (a b : UInt16) : Decidable (a < b)
```

Decides whether one 16-bit unsigned integer is strictly less than another. Usually accessed via the `DecidableLT UInt16` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if (6 : UInt16) < 7 then "yes" else "no") = "yes"`
- `(if (5 : UInt16) < 5 then "yes" else "no") = "no"`
- `show ¬((7 : UInt16) < 7) by decide`

<a id="Int16___decLt"></a>

**def**

```text
Int16.decLt (a b : Int16) : Decidable (a < b)
```

Decides whether one 16-bit signed integer is strictly less than another. Usually accessed via the `DecidableLT Int16` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if ((-7) : Int16) < 7 then "yes" else "no") = "yes"`
- `(if (5 : Int16) < 5 then "yes" else "no") = "no"`
- `show ¬((7 : Int16) < 7) by decide`

<a id="UInt32___decLt"></a>

**def**

```text
UInt32.decLt (a b : UInt32) : Decidable (a < b)
```

Decides whether one 8-bit unsigned integer is strictly less than another. Usually accessed via the `DecidableLT UInt32` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if (6 : UInt32) < 7 then "yes" else "no") = "yes"`
- `(if (5 : UInt32) < 5 then "yes" else "no") = "no"`
- `show ¬((7 : UInt32) < 7) by decide`

<a id="Int32___decLt"></a>

**def**

```text
Int32.decLt (a b : Int32) : Decidable (a < b)
```

Decides whether one 32-bit signed integer is strictly less than another. Usually accessed via the `DecidableLT Int32` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if ((-7) : Int32) < 7 then "yes" else "no") = "yes"`
- `(if (5 : Int32) < 5 then "yes" else "no") = "no"`
- `show ¬((7 : Int32) < 7) by decide`

<a id="UInt64___decLt"></a>

**def**

```text
UInt64.decLt (a b : UInt64) : Decidable (a < b)
```

Decides whether one 64-bit unsigned integer is strictly less than another. Usually accessed via the `DecidableLT UInt64` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if (6 : UInt64) < 7 then "yes" else "no") = "yes"`
- `(if (5 : UInt64) < 5 then "yes" else "no") = "no"`
- `show ¬((7 : UInt64) < 7) by decide`

<a id="Int64___decLt"></a>

**def**

```text
Int64.decLt (a b : Int64) : Decidable (a < b)
```

Decides whether one 8-bit signed integer is strictly less than another. Usually accessed via the `DecidableLT Int64` instance.

This function is overridden at runtime with an efficient implementation.

Examples:

- `(if ((-7) : Int64) < 7 then "yes" else "no") = "yes"`
- `(if (5 : Int64) < 5 then "yes" else "no") = "no"`
- `show ¬((7 : Int64) < 7) by decide`

<a id="fixed-int-arithmetic"></a>
#### 20.4.4.5. Arithmetic

Typically, arithmetic operations on fixed-width integers should be accessed using Lean's overloaded arithmetic notation, particularly their instances of `Add`, `Sub`, `Mul`, `Div`, and `Mod`, as well as `Neg` for signed types.

<a id="ISize___neg"></a>

**def**

```text
ISize.neg (i : ISize) : ISize
```

Negates word-sized signed integers. Usually accessed via the `-` prefix operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___neg"></a>

**def**

```text
Int8.neg (i : Int8) : Int8
```

Negates 8-bit signed integers. Usually accessed via the `-` prefix operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___neg"></a>

**def**

```text
Int16.neg (i : Int16) : Int16
```

Negates 16-bit signed integers. Usually accessed via the `-` prefix operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___neg"></a>

**def**

```text
Int32.neg (i : Int32) : Int32
```

Negates 32-bit signed integers. Usually accessed via the `-` prefix operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___neg"></a>

**def**

```text
Int64.neg (i : Int64) : Int64
```

Negates 64-bit signed integers. Usually accessed via the `-` prefix operator.

This function is overridden at runtime with an efficient implementation.

<a id="USize___neg"></a>

**def**

```text
USize.neg (a : USize) : USize
```

Negation of word-sized unsigned integers, computed modulo `USize.size`.

This function is overridden at runtime with an efficient implementation.

<a id="UInt8___neg"></a>

**def**

```text
UInt8.neg (a : UInt8) : UInt8
```

Negation of 8-bit unsigned integers, computed modulo `UInt8.size`.

`UInt8.neg a` is equivalent to `255 - a + 1`.

This function is overridden at runtime with an efficient implementation.

<a id="UInt16___neg"></a>

**def**

```text
UInt16.neg (a : UInt16) : UInt16
```

Negation of 16-bit unsigned integers, computed modulo `UInt16.size`.

`UInt16.neg a` is equivalent to `65_535 - a + 1`.

This function is overridden at runtime with an efficient implementation.

<a id="UInt32___neg"></a>

**def**

```text
UInt32.neg (a : UInt32) : UInt32
```

Negation of 32-bit unsigned integers, computed modulo `UInt32.size`.

`UInt32.neg a` is equivalent to `429_4967_295 - a + 1`.

This function is overridden at runtime with an efficient implementation.

<a id="UInt64___neg"></a>

**def**

```text
UInt64.neg (a : UInt64) : UInt64
```

Negation of 64-bit unsigned integers, computed modulo `UInt64.size`.

`UInt64.neg a` is equivalent to `18_446_744_073_709_551_615 - a + 1`.

This function is overridden at runtime with an efficient implementation.

<a id="USize___add"></a>

**def**

```text
USize.add (a b : USize) : USize
```

Adds two word-sized unsigned integers, wrapping around on overflow. Usually accessed via the `+` operator.

This function is overridden at runtime with an efficient implementation.

<a id="ISize___add"></a>

**def**

```text
ISize.add (a b : ISize) : ISize
```

Adds two word-sized signed integers, wrapping around on over- or underflow. Usually accessed via the `+` operator.

This function is overridden at runtime with an efficient implementation.

<a id="UInt8___add"></a>

**def**

```text
UInt8.add (a b : UInt8) : UInt8
```

Adds two 8-bit unsigned integers, wrapping around on overflow. Usually accessed via the `+` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___add"></a>

**def**

```text
Int8.add (a b : Int8) : Int8
```

Adds two 8-bit signed integers, wrapping around on over- or underflow. Usually accessed via the `+` operator.

This function is overridden at runtime with an efficient implementation.

<a id="UInt16___add"></a>

**def**

```text
UInt16.add (a b : UInt16) : UInt16
```

Adds two 16-bit unsigned integers, wrapping around on overflow. Usually accessed via the `+` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___add"></a>

**def**

```text
Int16.add (a b : Int16) : Int16
```

Adds two 16-bit signed integers, wrapping around on over- or underflow. Usually accessed via the `+` operator.

This function is overridden at runtime with an efficient implementation.

<a id="UInt32___add"></a>

**def**

```text
UInt32.add (a b : UInt32) : UInt32
```

Adds two 32-bit unsigned integers, wrapping around on overflow. Usually accessed via the `+` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___add"></a>

**def**

```text
Int32.add (a b : Int32) : Int32
```

Adds two 32-bit signed integers, wrapping around on over- or underflow. Usually accessed via the `+` operator.

This function is overridden at runtime with an efficient implementation.

<a id="UInt64___add"></a>

**def**

```text
UInt64.add (a b : UInt64) : UInt64
```

Adds two 64-bit unsigned integers, wrapping around on overflow. Usually accessed via the `+` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___add"></a>

**def**

```text
Int64.add (a b : Int64) : Int64
```

Adds two 64-bit signed integers, wrapping around on over- or underflow. Usually accessed via the `+` operator.

This function is overridden at runtime with an efficient implementation.

<a id="USize___sub"></a>

**def**

```text
USize.sub (a b : USize) : USize
```

Subtracts one word-sized-bit unsigned integer from another, wrapping around on underflow. Usually accessed via the `-` operator.

This function is overridden at runtime with an efficient implementation.

<a id="ISize___sub"></a>

**def**

```text
ISize.sub (a b : ISize) : ISize
```

Subtracts one word-sized signed integer from another, wrapping around on over- or underflow. Usually accessed via the `-` operator.

This function is overridden at runtime with an efficient implementation.

<a id="UInt8___sub"></a>

**def**

```text
UInt8.sub (a b : UInt8) : UInt8
```

Subtracts one 8-bit unsigned integer from another, wrapping around on underflow. Usually accessed via the `-` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___sub"></a>

**def**

```text
Int8.sub (a b : Int8) : Int8
```

Subtracts one 8-bit signed integer from another, wrapping around on over- or underflow. Usually accessed via the `-` operator.

This function is overridden at runtime with an efficient implementation.

<a id="UInt16___sub"></a>

**def**

```text
UInt16.sub (a b : UInt16) : UInt16
```

Subtracts one 16-bit unsigned integer from another, wrapping around on underflow. Usually accessed via the `-` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___sub"></a>

**def**

```text
Int16.sub (a b : Int16) : Int16
```

Subtracts one 16-bit signed integer from another, wrapping around on over- or underflow. Usually accessed via the `-` operator.

This function is overridden at runtime with an efficient implementation.

<a id="UInt32___sub"></a>

**def**

```text
UInt32.sub (a b : UInt32) : UInt32
```

Subtracts one 32-bit unsigned integer from another, wrapping around on underflow. Usually accessed via the `-` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___sub"></a>

**def**

```text
Int32.sub (a b : Int32) : Int32
```

Subtracts one 32-bit signed integer from another, wrapping around on over- or underflow. Usually accessed via the `-` operator.

This function is overridden at runtime with an efficient implementation.

<a id="UInt64___sub"></a>

**def**

```text
UInt64.sub (a b : UInt64) : UInt64
```

Subtracts one 64-bit unsigned integer from another, wrapping around on underflow. Usually accessed via the `-` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___sub"></a>

**def**

```text
Int64.sub (a b : Int64) : Int64
```

Subtracts one 64-bit signed integer from another, wrapping around on over- or underflow. Usually accessed via the `-` operator.

This function is overridden at runtime with an efficient implementation.

<a id="USize___mul"></a>

**def**

```text
USize.mul (a b : USize) : USize
```

Multiplies two word-sized unsigned integers, wrapping around on overflow. Usually accessed via the `*` operator.

This function is overridden at runtime with an efficient implementation.

<a id="ISize___mul"></a>

**def**

```text
ISize.mul (a b : ISize) : ISize
```

Multiplies two word-sized signed integers, wrapping around on over- or underflow. Usually accessed via the `*` operator.

This function is overridden at runtime with an efficient implementation.

<a id="UInt8___mul"></a>

**def**

```text
UInt8.mul (a b : UInt8) : UInt8
```

Multiplies two 8-bit unsigned integers, wrapping around on overflow. Usually accessed via the `*` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___mul"></a>

**def**

```text
Int8.mul (a b : Int8) : Int8
```

Multiplies two 8-bit signed integers, wrapping around on over- or underflow. Usually accessed via the `*` operator.

This function is overridden at runtime with an efficient implementation.

<a id="UInt16___mul"></a>

**def**

```text
UInt16.mul (a b : UInt16) : UInt16
```

Multiplies two 16-bit unsigned integers, wrapping around on overflow. Usually accessed via the `*` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___mul"></a>

**def**

```text
Int16.mul (a b : Int16) : Int16
```

Multiplies two 16-bit signed integers, wrapping around on over- or underflow. Usually accessed via the `*` operator.

This function is overridden at runtime with an efficient implementation.

<a id="UInt32___mul"></a>

**def**

```text
UInt32.mul (a b : UInt32) : UInt32
```

Multiplies two 32-bit unsigned integers, wrapping around on overflow. Usually accessed via the `*` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___mul"></a>

**def**

```text
Int32.mul (a b : Int32) : Int32
```

Multiplies two 32-bit signed integers, wrapping around on over- or underflow. Usually accessed via the `*` operator.

This function is overridden at runtime with an efficient implementation.

<a id="UInt64___mul"></a>

**def**

```text
UInt64.mul (a b : UInt64) : UInt64
```

Multiplies two 64-bit unsigned integers, wrapping around on overflow. Usually accessed via the `*` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___mul"></a>

**def**

```text
Int64.mul (a b : Int64) : Int64
```

Multiplies two 64-bit signed integers, wrapping around on over- or underflow. Usually accessed via the `*` operator.

This function is overridden at runtime with an efficient implementation.

<a id="USize___div"></a>

**def**

```text
USize.div (a b : USize) : USize
```

Unsigned division for word-sized unsigned integers, discarding the remainder. Usually accessed via the `/` operator.

This operation is sometimes called “floor division.” Division by zero is defined to be zero.

This function is overridden at runtime with an efficient implementation.

<a id="ISize___div"></a>

**def**

```text
ISize.div (a b : ISize) : ISize
```

Truncating division for word-sized signed integers, rounding towards zero. Usually accessed via the `/` operator.

Division by zero is defined to be zero.

This function is overridden at runtime with an efficient implementation.

Examples:

- `ISize.div 10 3 = 3`
- `ISize.div 10 (-3) = (-3)`
- `ISize.div (-10) (-3) = 3`
- `ISize.div (-10) 3 = (-3)`
- `ISize.div 10 0 = 0`

<a id="UInt8___div"></a>

**def**

```text
UInt8.div (a b : UInt8) : UInt8
```

Unsigned division for 8-bit unsigned integers, discarding the remainder. Usually accessed via the `/` operator.

This operation is sometimes called “floor division.” Division by zero is defined to be zero.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___div"></a>

**def**

```text
Int8.div (a b : Int8) : Int8
```

Truncating division for 8-bit signed integers, rounding towards zero. Usually accessed via the `/` operator.

Division by zero is defined to be zero.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int8.div 10 3 = 3`
- `Int8.div 10 (-3) = (-3)`
- `Int8.div (-10) (-3) = 3`
- `Int8.div (-10) 3 = (-3)`
- `Int8.div 10 0 = 0`

<a id="UInt16___div"></a>

**def**

```text
UInt16.div (a b : UInt16) : UInt16
```

Unsigned division for 16-bit unsigned integers, discarding the remainder. Usually accessed via the `/` operator.

This operation is sometimes called “floor division.” Division by zero is defined to be zero.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___div"></a>

**def**

```text
Int16.div (a b : Int16) : Int16
```

Truncating division for 16-bit signed integers, rounding towards zero. Usually accessed via the `/` operator.

Division by zero is defined to be zero.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int16.div 10 3 = 3`
- `Int16.div 10 (-3) = (-3)`
- `Int16.div (-10) (-3) = 3`
- `Int16.div (-10) 3 = (-3)`
- `Int16.div 10 0 = 0`

<a id="UInt32___div"></a>

**def**

```text
UInt32.div (a b : UInt32) : UInt32
```

Unsigned division for 32-bit unsigned integers, discarding the remainder. Usually accessed via the `/` operator.

This operation is sometimes called “floor division.” Division by zero is defined to be zero.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___div"></a>

**def**

```text
Int32.div (a b : Int32) : Int32
```

Truncating division for 32-bit signed integers, rounding towards zero. Usually accessed via the `/` operator.

Division by zero is defined to be zero.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int32.div 10 3 = 3`
- `Int32.div 10 (-3) = (-3)`
- `Int32.div (-10) (-3) = 3`
- `Int32.div (-10) 3 = (-3)`
- `Int32.div 10 0 = 0`

<a id="UInt64___div"></a>

**def**

```text
UInt64.div (a b : UInt64) : UInt64
```

Unsigned division for 64-bit unsigned integers, discarding the remainder. Usually accessed via the `/` operator.

This operation is sometimes called “floor division.” Division by zero is defined to be zero.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___div"></a>

**def**

```text
Int64.div (a b : Int64) : Int64
```

Truncating division for 64-bit signed integers, rounding towards zero. Usually accessed via the `/` operator.

Division by zero is defined to be zero.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int64.div 10 3 = 3`
- `Int64.div 10 (-3) = (-3)`
- `Int64.div (-10) (-3) = 3`
- `Int64.div (-10) 3 = (-3)`
- `Int64.div 10 0 = 0`

<a id="USize___mod"></a>

**def**

```text
USize.mod (a b : USize) : USize
```

The modulo operator for word-sized unsigned integers, which computes the remainder when dividing one integer by another. Usually accessed via the `%` operator.

When the divisor is `0`, the result is the dividend rather than an error.

This function is overridden at runtime with an efficient implementation.

Examples:

- `USize.mod 5 2 = 1`
- `USize.mod 4 2 = 0`
- `USize.mod 4 0 = 4`

<a id="ISize___mod"></a>

**def**

```text
ISize.mod (a b : ISize) : ISize
```

The modulo operator for word-sized signed integers, which computes the remainder when dividing one integer by another with the T-rounding convention used by `ISize.div`. Usually accessed via the `%` operator.

When the divisor is `0`, the result is the dividend rather than an error.

This function is overridden at runtime with an efficient implementation.

Examples:

- `ISize.mod 5 2 = 1`
- `ISize.mod 5 (-2) = 1`
- `ISize.mod (-5) 2 = (-1)`
- `ISize.mod (-5) (-2) = (-1)`
- `ISize.mod 4 2 = 0`
- `ISize.mod 4 (-2) = 0`
- `ISize.mod 4 0 = 4`
- `ISize.mod (-4) 0 = (-4)`

<a id="UInt8___mod"></a>

**def**

```text
UInt8.mod (a b : UInt8) : UInt8
```

The modulo operator for 8-bit unsigned integers, which computes the remainder when dividing one integer by another. Usually accessed via the `%` operator.

When the divisor is `0`, the result is the dividend rather than an error.

This function is overridden at runtime with an efficient implementation.

Examples:

- `UInt8.mod 5 2 = 1`
- `UInt8.mod 4 2 = 0`
- `UInt8.mod 4 0 = 4`

<a id="Int8___mod"></a>

**def**

```text
Int8.mod (a b : Int8) : Int8
```

The modulo operator for 8-bit signed integers, which computes the remainder when dividing one integer by another with the T-rounding convention used by `Int8.div`. Usually accessed via the `%` operator.

When the divisor is `0`, the result is the dividend rather than an error.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int8.mod 5 2 = 1`
- `Int8.mod 5 (-2) = 1`
- `Int8.mod (-5) 2 = (-1)`
- `Int8.mod (-5) (-2) = (-1)`
- `Int8.mod 4 2 = 0`
- `Int8.mod 4 (-2) = 0`
- `Int8.mod 4 0 = 4`
- `Int8.mod (-4) 0 = (-4)`

<a id="UInt16___mod"></a>

**def**

```text
UInt16.mod (a b : UInt16) : UInt16
```

The modulo operator for 16-bit unsigned integers, which computes the remainder when dividing one integer by another. Usually accessed via the `%` operator.

When the divisor is `0`, the result is the dividend rather than an error.

This function is overridden at runtime with an efficient implementation.

Examples:

- `UInt16.mod 5 2 = 1`
- `UInt16.mod 4 2 = 0`
- `UInt16.mod 4 0 = 4`

<a id="Int16___mod"></a>

**def**

```text
Int16.mod (a b : Int16) : Int16
```

The modulo operator for 16-bit signed integers, which computes the remainder when dividing one integer by another with the T-rounding convention used by `Int16.div`. Usually accessed via the `%` operator.

When the divisor is `0`, the result is the dividend rather than an error.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int16.mod 5 2 = 1`
- `Int16.mod 5 (-2) = 1`
- `Int16.mod (-5) 2 = (-1)`
- `Int16.mod (-5) (-2) = (-1)`
- `Int16.mod 4 2 = 0`
- `Int16.mod 4 (-2) = 0`
- `Int16.mod 4 0 = 4`
- `Int16.mod (-4) 0 = (-4)`

<a id="UInt32___mod"></a>

**def**

```text
UInt32.mod (a b : UInt32) : UInt32
```

The modulo operator for 32-bit unsigned integers, which computes the remainder when dividing one integer by another. Usually accessed via the `%` operator.

When the divisor is `0`, the result is the dividend rather than an error.

This function is overridden at runtime with an efficient implementation.

Examples:

- `UInt32.mod 5 2 = 1`
- `UInt32.mod 4 2 = 0`
- `UInt32.mod 4 0 = 4`

<a id="Int32___mod"></a>

**def**

```text
Int32.mod (a b : Int32) : Int32
```

The modulo operator for 32-bit signed integers, which computes the remainder when dividing one integer by another with the T-rounding convention used by `Int32.div`. Usually accessed via the `%` operator.

When the divisor is `0`, the result is the dividend rather than an error.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int32.mod 5 2 = 1`
- `Int32.mod 5 (-2) = 1`
- `Int32.mod (-5) 2 = (-1)`
- `Int32.mod (-5) (-2) = (-1)`
- `Int32.mod 4 2 = 0`
- `Int32.mod 4 (-2) = 0`
- `Int32.mod 4 0 = 4`
- `Int32.mod (-4) 0 = (-4)`

<a id="UInt64___mod"></a>

**def**

```text
UInt64.mod (a b : UInt64) : UInt64
```

The modulo operator for 64-bit unsigned integers, which computes the remainder when dividing one integer by another. Usually accessed via the `%` operator.

When the divisor is `0`, the result is the dividend rather than an error.

This function is overridden at runtime with an efficient implementation.

Examples:

- `UInt64.mod 5 2 = 1`
- `UInt64.mod 4 2 = 0`
- `UInt64.mod 4 0 = 4`

<a id="Int64___mod"></a>

**def**

```text
Int64.mod (a b : Int64) : Int64
```

The modulo operator for 64-bit signed integers, which computes the remainder when dividing one integer by another with the T-rounding convention used by `Int64.div`. Usually accessed via the `%` operator.

When the divisor is `0`, the result is the dividend rather than an error.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int64.mod 5 2 = 1`
- `Int64.mod 5 (-2) = 1`
- `Int64.mod (-5) 2 = (-1)`
- `Int64.mod (-5) (-2) = (-1)`
- `Int64.mod 4 2 = 0`
- `Int64.mod 4 (-2) = 0`
- `Int64.mod 4 0 = 4`
- `Int64.mod (-4) 0 = (-4)`

<a id="USize___log2"></a>

**def**

```text
USize.log2 (a : USize) : USize
```

Base-two logarithm of word-sized unsigned integers. Returns `⌊max 0 (log₂ a)⌋`.

This function is overridden at runtime with an efficient implementation. This definition is the logical model.

Examples:

- `USize.log2 0 = 0`
- `USize.log2 1 = 0`
- `USize.log2 2 = 1`
- `USize.log2 4 = 2`
- `USize.log2 7 = 2`
- `USize.log2 8 = 3`

<a id="UInt8___log2"></a>

**def**

```text
UInt8.log2 (a : UInt8) : UInt8
```

Base-two logarithm of 8-bit unsigned integers. Returns `⌊max 0 (log₂ a)⌋`.

This function is overridden at runtime with an efficient implementation. This definition is the logical model.

Examples:

- `UInt8.log2 0 = 0`
- `UInt8.log2 1 = 0`
- `UInt8.log2 2 = 1`
- `UInt8.log2 4 = 2`
- `UInt8.log2 7 = 2`
- `UInt8.log2 8 = 3`

<a id="UInt16___log2"></a>

**def**

```text
UInt16.log2 (a : UInt16) : UInt16
```

Base-two logarithm of 16-bit unsigned integers. Returns `⌊max 0 (log₂ a)⌋`.

This function is overridden at runtime with an efficient implementation. This definition is the logical model.

Examples:

- `UInt16.log2 0 = 0`
- `UInt16.log2 1 = 0`
- `UInt16.log2 2 = 1`
- `UInt16.log2 4 = 2`
- `UInt16.log2 7 = 2`
- `UInt16.log2 8 = 3`

<a id="UInt32___log2"></a>

**def**

```text
UInt32.log2 (a : UInt32) : UInt32
```

Base-two logarithm of 32-bit unsigned integers. Returns `⌊max 0 (log₂ a)⌋`.

This function is overridden at runtime with an efficient implementation. This definition is the logical model.

Examples:

- `UInt32.log2 0 = 0`
- `UInt32.log2 1 = 0`
- `UInt32.log2 2 = 1`
- `UInt32.log2 4 = 2`
- `UInt32.log2 7 = 2`
- `UInt32.log2 8 = 3`

<a id="UInt64___log2"></a>

**def**

```text
UInt64.log2 (a : UInt64) : UInt64
```

Base-two logarithm of 64-bit unsigned integers. Returns `⌊max 0 (log₂ a)⌋`.

This function is overridden at runtime with an efficient implementation. This definition is the logical model.

Examples:

- `UInt64.log2 0 = 0`
- `UInt64.log2 1 = 0`
- `UInt64.log2 2 = 1`
- `UInt64.log2 4 = 2`
- `UInt64.log2 7 = 2`
- `UInt64.log2 8 = 3`

<a id="ISize___abs"></a>

**def**

```text
ISize.abs (a : ISize) : ISize
```

Computes the absolute value of a word-sized signed integer.

This function is equivalent to `if a < 0 then -a else a`, so in particular `ISize.minValue` will be mapped to `ISize.minValue`.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___abs"></a>

**def**

```text
Int8.abs (a : Int8) : Int8
```

Computes the absolute value of an 8-bit signed integer.

This function is equivalent to `if a < 0 then -a else a`, so in particular `Int8.minValue` will be mapped to `Int8.minValue`.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___abs"></a>

**def**

```text
Int16.abs (a : Int16) : Int16
```

Computes the absolute value of a 16-bit signed integer.

This function is equivalent to `if a < 0 then -a else a`, so in particular `Int16.minValue` will be mapped to `Int16.minValue`.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___abs"></a>

**def**

```text
Int32.abs (a : Int32) : Int32
```

Computes the absolute value of a 32-bit signed integer.

This function is equivalent to `if a < 0 then -a else a`, so in particular `Int32.minValue` will be mapped to `Int32.minValue`.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___abs"></a>

**def**

```text
Int64.abs (a : Int64) : Int64
```

Computes the absolute value of a 64-bit signed integer.

This function is equivalent to `if a < 0 then -a else a`, so in particular `Int64.minValue` will be mapped to `Int64.minValue`.

This function is overridden at runtime with an efficient implementation.

<a id="The-Lean-Language-Reference--Basic-Types--Fixed-Precision-Integers--API-Reference--Bitwise-Operations"></a>
#### 20.4.4.6. Bitwise Operations

Typically, bitwise operations on fixed-width integers should be accessed using Lean's overloaded operators, particularly their instances of `ShiftLeft`, `ShiftRight`, `AndOp`, `OrOp`, and `XorOp`.

<a id="USize___land"></a>

**def**

```text
USize.land (a b : USize) : USize
```

Bitwise and for word-sized unsigned integers. Usually accessed via the `&&&` operator.

Each bit of the resulting integer is set if the corresponding bits of both input integers are set.

This function is overridden at runtime with an efficient implementation.

<a id="ISize___land"></a>

**def**

```text
ISize.land (a b : ISize) : ISize
```

Bitwise and for word-sized signed integers. Usually accessed via the `&&&` operator.

Each bit of the resulting integer is set if the corresponding bits of both input integers are set, according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="UInt8___land"></a>

**def**

```text
UInt8.land (a b : UInt8) : UInt8
```

Bitwise and for 8-bit unsigned integers. Usually accessed via the `&&&` operator.

Each bit of the resulting integer is set if the corresponding bits of both input integers are set.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___land"></a>

**def**

```text
Int8.land (a b : Int8) : Int8
```

Bitwise and for 8-bit signed integers. Usually accessed via the `&&&` operator.

Each bit of the resulting integer is set if the corresponding bits of both input integers are set, according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="UInt16___land"></a>

**def**

```text
UInt16.land (a b : UInt16) : UInt16
```

Bitwise and for 16-bit unsigned integers. Usually accessed via the `&&&` operator.

Each bit of the resulting integer is set if the corresponding bits of both input integers are set.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___land"></a>

**def**

```text
Int16.land (a b : Int16) : Int16
```

Bitwise and for 16-bit signed integers. Usually accessed via the `&&&` operator.

Each bit of the resulting integer is set if the corresponding bits of both input integers are set, according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="UInt32___land"></a>

**def**

```text
UInt32.land (a b : UInt32) : UInt32
```

Bitwise and for 32-bit unsigned integers. Usually accessed via the `&&&` operator.

Each bit of the resulting integer is set if the corresponding bits of both input integers are set.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___land"></a>

**def**

```text
Int32.land (a b : Int32) : Int32
```

Bitwise and for 32-bit signed integers. Usually accessed via the `&&&` operator.

Each bit of the resulting integer is set if the corresponding bits of both input integers are set, according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="UInt64___land"></a>

**def**

```text
UInt64.land (a b : UInt64) : UInt64
```

Bitwise and for 64-bit unsigned integers. Usually accessed via the `&&&` operator.

Each bit of the resulting integer is set if the corresponding bits of both input integers are set.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___land"></a>

**def**

```text
Int64.land (a b : Int64) : Int64
```

Bitwise and for 64-bit signed integers. Usually accessed via the `&&&` operator.

Each bit of the resulting integer is set if the corresponding bits of both input integers are set, according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="USize___lor"></a>

**def**

```text
USize.lor (a b : USize) : USize
```

Bitwise or for word-sized unsigned integers. Usually accessed via the `|||` operator.

Each bit of the resulting integer is set if at least one of the corresponding bits of both input integers are set.

This function is overridden at runtime with an efficient implementation.

<a id="ISize___lor"></a>

**def**

```text
ISize.lor (a b : ISize) : ISize
```

Bitwise or for word-sized signed integers. Usually accessed via the `|||` operator.

Each bit of the resulting integer is set if at least one of the corresponding bits of the input integers is set, according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="UInt8___lor"></a>

**def**

```text
UInt8.lor (a b : UInt8) : UInt8
```

Bitwise or for 8-bit unsigned integers. Usually accessed via the `|||` operator.

Each bit of the resulting integer is set if at least one of the corresponding bits of both input integers are set.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___lor"></a>

**def**

```text
Int8.lor (a b : Int8) : Int8
```

Bitwise or for 8-bit signed integers. Usually accessed via the `|||` operator.

Each bit of the resulting integer is set if at least one of the corresponding bits of the input integers is set, according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="UInt16___lor"></a>

**def**

```text
UInt16.lor (a b : UInt16) : UInt16
```

Bitwise or for 16-bit unsigned integers. Usually accessed via the `|||` operator.

Each bit of the resulting integer is set if at least one of the corresponding bits of both input integers are set.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___lor"></a>

**def**

```text
Int16.lor (a b : Int16) : Int16
```

Bitwise or for 16-bit signed integers. Usually accessed via the `|||` operator.

Each bit of the resulting integer is set if at least one of the corresponding bits of the input integers is set, according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="UInt32___lor"></a>

**def**

```text
UInt32.lor (a b : UInt32) : UInt32
```

Bitwise or for 32-bit unsigned integers. Usually accessed via the `|||` operator.

Each bit of the resulting integer is set if at least one of the corresponding bits of both input integers are set.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___lor"></a>

**def**

```text
Int32.lor (a b : Int32) : Int32
```

Bitwise or for 32-bit signed integers. Usually accessed via the `|||` operator.

Each bit of the resulting integer is set if at least one of the corresponding bits of the input integers is set, according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="UInt64___lor"></a>

**def**

```text
UInt64.lor (a b : UInt64) : UInt64
```

Bitwise or for 64-bit unsigned integers. Usually accessed via the `|||` operator.

Each bit of the resulting integer is set if at least one of the corresponding bits of both input integers are set.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___lor"></a>

**def**

```text
Int64.lor (a b : Int64) : Int64
```

Bitwise or for 64-bit signed integers. Usually accessed via the `|||` operator.

Each bit of the resulting integer is set if at least one of the corresponding bits of the input integers is set, according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="USize___xor"></a>

**def**

```text
USize.xor (a b : USize) : USize
```

Bitwise exclusive or for word-sized unsigned integers. Usually accessed via the `^^^` operator.

Each bit of the resulting integer is set if exactly one of the corresponding bits of both input integers are set.

This function is overridden at runtime with an efficient implementation.

<a id="ISize___xor"></a>

**def**

```text
ISize.xor (a b : ISize) : ISize
```

Bitwise exclusive or for word-sized signed integers. Usually accessed via the `^^^` operator.

Each bit of the resulting integer is set if exactly one of the corresponding bits of the input integers is set, according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="UInt8___xor"></a>

**def**

```text
UInt8.xor (a b : UInt8) : UInt8
```

Bitwise exclusive or for 8-bit unsigned integers. Usually accessed via the `^^^` operator.

Each bit of the resulting integer is set if exactly one of the corresponding bits of both input integers are set.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___xor"></a>

**def**

```text
Int8.xor (a b : Int8) : Int8
```

Bitwise exclusive or for 8-bit signed integers. Usually accessed via the `^^^` operator.

Each bit of the resulting integer is set if exactly one of the corresponding bits of the input integers is set, according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="UInt16___xor"></a>

**def**

```text
UInt16.xor (a b : UInt16) : UInt16
```

Bitwise exclusive or for 16-bit unsigned integers. Usually accessed via the `^^^` operator.

Each bit of the resulting integer is set if exactly one of the corresponding bits of both input integers are set.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___xor"></a>

**def**

```text
Int16.xor (a b : Int16) : Int16
```

Bitwise exclusive or for 16-bit signed integers. Usually accessed via the `^^^` operator.

Each bit of the resulting integer is set if exactly one of the corresponding bits of the input integers is set, according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="UInt32___xor"></a>

**def**

```text
UInt32.xor (a b : UInt32) : UInt32
```

Bitwise exclusive or for 32-bit unsigned integers. Usually accessed via the `^^^` operator.

Each bit of the resulting integer is set if exactly one of the corresponding bits of both input integers are set.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___xor"></a>

**def**

```text
Int32.xor (a b : Int32) : Int32
```

Bitwise exclusive or for 32-bit signed integers. Usually accessed via the `^^^` operator.

Each bit of the resulting integer is set if exactly one of the corresponding bits of the input integers is set, according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="UInt64___xor"></a>

**def**

```text
UInt64.xor (a b : UInt64) : UInt64
```

Bitwise exclusive or for 64-bit unsigned integers. Usually accessed via the `^^^` operator.

Each bit of the resulting integer is set if exactly one of the corresponding bits of both input integers are set.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___xor"></a>

**def**

```text
Int64.xor (a b : Int64) : Int64
```

Bitwise exclusive or for 64-bit signed integers. Usually accessed via the `^^^` operator.

Each bit of the resulting integer is set if exactly one of the corresponding bits of the input integers is set, according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="USize___complement"></a>

**def**

```text
USize.complement (a : USize) : USize
```

Bitwise complement, also known as bitwise negation, for word-sized unsigned integers. Usually accessed via the `~~~` prefix operator.

Each bit of the resulting integer is the opposite of the corresponding bit of the input integer.

This function is overridden at runtime with an efficient implementation.

<a id="ISize___complement"></a>

**def**

```text
ISize.complement (a : ISize) : ISize
```

Bitwise complement, also known as bitwise negation, for word-sized signed integers. Usually accessed via the `~~~` prefix operator.

Each bit of the resulting integer is the opposite of the corresponding bit of the input integer. Integers use the two's complement representation, so `ISize.complement a = -(a + 1)`.

This function is overridden at runtime with an efficient implementation.

<a id="UInt8___complement"></a>

**def**

```text
UInt8.complement (a : UInt8) : UInt8
```

Bitwise complement, also known as bitwise negation, for 8-bit unsigned integers. Usually accessed via the `~~~` prefix operator.

Each bit of the resulting integer is the opposite of the corresponding bit of the input integer.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___complement"></a>

**def**

```text
Int8.complement (a : Int8) : Int8
```

Bitwise complement, also known as bitwise negation, for 8-bit signed integers. Usually accessed via the `~~~` prefix operator.

Each bit of the resulting integer is the opposite of the corresponding bit of the input integer. Integers use the two's complement representation, so `Int8.complement a = -(a + 1)`.

This function is overridden at runtime with an efficient implementation.

<a id="UInt16___complement"></a>

**def**

```text
UInt16.complement (a : UInt16) : UInt16
```

Bitwise complement, also known as bitwise negation, for 16-bit unsigned integers. Usually accessed via the `~~~` prefix operator.

Each bit of the resulting integer is the opposite of the corresponding bit of the input integer.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___complement"></a>

**def**

```text
Int16.complement (a : Int16) : Int16
```

Bitwise complement, also known as bitwise negation, for 16-bit signed integers. Usually accessed via the `~~~` prefix operator.

Each bit of the resulting integer is the opposite of the corresponding bit of the input integer. Integers use the two's complement representation, so `Int16.complement a = -(a + 1)`.

This function is overridden at runtime with an efficient implementation.

<a id="UInt32___complement"></a>

**def**

```text
UInt32.complement (a : UInt32) : UInt32
```

Bitwise complement, also known as bitwise negation, for 32-bit unsigned integers. Usually accessed via the `~~~` prefix operator.

Each bit of the resulting integer is the opposite of the corresponding bit of the input integer.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___complement"></a>

**def**

```text
Int32.complement (a : Int32) : Int32
```

Bitwise complement, also known as bitwise negation, for 32-bit signed integers. Usually accessed via the `~~~` prefix operator.

Each bit of the resulting integer is the opposite of the corresponding bit of the input integer. Integers use the two's complement representation, so `Int32.complement a = -(a + 1)`.

This function is overridden at runtime with an efficient implementation.

<a id="UInt64___complement"></a>

**def**

```text
UInt64.complement (a : UInt64) : UInt64
```

Bitwise complement, also known as bitwise negation, for 64-bit unsigned integers. Usually accessed via the `~~~` prefix operator.

Each bit of the resulting integer is the opposite of the corresponding bit of the input integer.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___complement"></a>

**def**

```text
Int64.complement (a : Int64) : Int64
```

Bitwise complement, also known as bitwise negation, for 64-bit signed integers. Usually accessed via the `~~~` prefix operator.

Each bit of the resulting integer is the opposite of the corresponding bit of the input integer. Integers use the two's complement representation, so `Int64.complement a = -(a + 1)`.

This function is overridden at runtime with an efficient implementation.

<a id="USize___shiftLeft"></a>

**def**

```text
USize.shiftLeft (a b : USize) : USize
```

Bitwise left shift for word-sized unsigned integers. Usually accessed via the `<<<` operator.

This function is overridden at runtime with an efficient implementation.

<a id="ISize___shiftLeft"></a>

**def**

```text
ISize.shiftLeft (a b : ISize) : ISize
```

Bitwise left shift for word-sized signed integers. Usually accessed via the `<<<` operator.

Signed integers are interpreted as bitvectors according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="UInt8___shiftLeft"></a>

**def**

```text
UInt8.shiftLeft (a b : UInt8) : UInt8
```

Bitwise left shift for 8-bit unsigned integers. Usually accessed via the `<<<` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___shiftLeft"></a>

**def**

```text
Int8.shiftLeft (a b : Int8) : Int8
```

Bitwise left shift for 8-bit signed integers. Usually accessed via the `<<<` operator.

Signed integers are interpreted as bitvectors according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="UInt16___shiftLeft"></a>

**def**

```text
UInt16.shiftLeft (a b : UInt16) : UInt16
```

Bitwise left shift for 16-bit unsigned integers. Usually accessed via the `<<<` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___shiftLeft"></a>

**def**

```text
Int16.shiftLeft (a b : Int16) : Int16
```

Bitwise left shift for 16-bit signed integers. Usually accessed via the `<<<` operator.

Signed integers are interpreted as bitvectors according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="UInt32___shiftLeft"></a>

**def**

```text
UInt32.shiftLeft (a b : UInt32) : UInt32
```

Bitwise left shift for 32-bit unsigned integers. Usually accessed via the `<<<` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___shiftLeft"></a>

**def**

```text
Int32.shiftLeft (a b : Int32) : Int32
```

Bitwise left shift for 32-bit signed integers. Usually accessed via the `<<<` operator.

Signed integers are interpreted as bitvectors according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="UInt64___shiftLeft"></a>

**def**

```text
UInt64.shiftLeft (a b : UInt64) : UInt64
```

Bitwise left shift for 64-bit unsigned integers. Usually accessed via the `<<<` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___shiftLeft"></a>

**def**

```text
Int64.shiftLeft (a b : Int64) : Int64
```

Bitwise left shift for 64-bit signed integers. Usually accessed via the `<<<` operator.

Signed integers are interpreted as bitvectors according to the two's complement representation.

This function is overridden at runtime with an efficient implementation.

<a id="USize___shiftRight"></a>

**def**

```text
USize.shiftRight (a b : USize) : USize
```

Bitwise right shift for word-sized unsigned integers. Usually accessed via the `>>>` operator.

This function is overridden at runtime with an efficient implementation.

<a id="ISize___shiftRight"></a>

**def**

```text
ISize.shiftRight (a b : ISize) : ISize
```

Arithmetic right shift for word-sized signed integers. Usually accessed via the `<<<` operator.

The high bits are filled with the value of the most significant bit.

This function is overridden at runtime with an efficient implementation.

<a id="UInt8___shiftRight"></a>

**def**

```text
UInt8.shiftRight (a b : UInt8) : UInt8
```

Bitwise right shift for 8-bit unsigned integers. Usually accessed via the `>>>` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int8___shiftRight"></a>

**def**

```text
Int8.shiftRight (a b : Int8) : Int8
```

Arithmetic right shift for 8-bit signed integers. Usually accessed via the `<<<` operator.

The high bits are filled with the value of the most significant bit.

This function is overridden at runtime with an efficient implementation.

<a id="UInt16___shiftRight"></a>

**def**

```text
UInt16.shiftRight (a b : UInt16) : UInt16
```

Bitwise right shift for 16-bit unsigned integers. Usually accessed via the `>>>` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int16___shiftRight"></a>

**def**

```text
Int16.shiftRight (a b : Int16) : Int16
```

Arithmetic right shift for 16-bit signed integers. Usually accessed via the `<<<` operator.

The high bits are filled with the value of the most significant bit.

This function is overridden at runtime with an efficient implementation.

<a id="UInt32___shiftRight"></a>

**def**

```text
UInt32.shiftRight (a b : UInt32) : UInt32
```

Bitwise right shift for 32-bit unsigned integers. Usually accessed via the `>>>` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int32___shiftRight"></a>

**def**

```text
Int32.shiftRight (a b : Int32) : Int32
```

Arithmetic right shift for 32-bit signed integers. Usually accessed via the `<<<` operator.

The high bits are filled with the value of the most significant bit.

This function is overridden at runtime with an efficient implementation.

<a id="UInt64___shiftRight"></a>

**def**

```text
UInt64.shiftRight (a b : UInt64) : UInt64
```

Bitwise right shift for 64-bit unsigned integers. Usually accessed via the `>>>` operator.

This function is overridden at runtime with an efficient implementation.

<a id="Int64___shiftRight"></a>

**def**

```text
Int64.shiftRight (a b : Int64) : Int64
```

Arithmetic right shift for 64-bit signed integers. Usually accessed via the `<<<` operator.

The high bits are filled with the value of the most significant bit.

This function is overridden at runtime with an efficient implementation.

## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
⊢ 255 = 255
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
⊢ 256 = 0
```


### Display 4


```text
⊢ 257 = 1
```


### Display 5


```text
⊢ 127 = 127
```


### Display 6


```text
⊢ 143 = -113
```


### Display 7


```text
⊢ 255 = -1
```

