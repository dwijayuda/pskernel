<a id="Float"></a>

# ProofScript — 20.6. Floating-Point Numbers

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Floating-Point-Numbers/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Floating-Point-Numbers/index.html). Source Git blob: `dde2704d989fa0565095cd7a9fb91861c717aa7a`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

> **Stable-pin correction:** this inherited page mentions `Lean.ofReduceBool`. These pre-final kernel mechanisms are not part of the selected Lean 4.34.0 stable semantics. Their historical descriptions remain for source coverage, not as authorization to implement those reductions. Native proof tactics require separate assumption/evidence accounting.

---

## 20.6. Floating-Point Numbers

Floating-point numbers are a an approximation of the real numbers that are efficiently implemented in computer hardware. Computations that use floating-point numbers are very efficient; however, the nature of the way that they approximate the real numbers is complex, with many corner cases. The IEEE 754 standard, which defines the floating-point format that is used on modern computers, allows hardware designers and programming language implementations to make certain choices, and real systems differ in these small details. Any given combination of hardware, operating system, C compiler, library versions, and even compilation flags can result in different behavior. For example, there are many distinct bit representations of `NaN`, the indicator that a result is undefined, and some platforms differ with respect to *which* `NaN` is returned from adding two `NaN`s.

To enable reasoning about floating-point numbers, Lean exposes a logical model of `Float` that is used in proofs. In particular, `Float` and `Float32` are implemented as wrappers around the logical model. In compiled code, this logical model is replaced by efficient native code. Differences between platforms are resolved by choosing specific representations (for example, all `NaN` values are replaced by a single canonical `NaN` when any operation requests a bit representation) and by modeling only the subset of floating-point operations that are implemented identically on all supported platforms. Other operations, such as trigonometric functions, are represented as opaque functions in Lean's logic.

The logical model is extensively empirically tested against the floating-point operations on all supported platforms. As long as FFI code does not modify the floating-point environment, Lean's runtime floating-point primitives match the model's specification.

<a id="Float___ofModel"></a>

**structure**

```text
Float : Type
```

64-bit floating-point numbers.

`Float` corresponds to the IEEE 754 *binary64* format (`double` in C or `f64` in Rust). Floating-point numbers are a finite representation of a subset of the real numbers, extended with extra “sentinel” values that represent undefined and infinite results as well as separate positive and negative zeroes. Arithmetic on floating-point numbers approximates the corresponding operations on the real numbers by rounding the results to numbers that are representable, propagating error and infinite values.

Floating-point numbers include [subnormal numbers](https://en.wikipedia.org/wiki/Subnormal_number). Their special values are:

- `NaN`, which denotes a class of “not a number” values that result from operations such as dividing zero by zero, and
- `Inf` and `-Inf`, which represent positive and infinities that result from dividing non-zero values by zero.

Like other low-level types, `Float` is special-cased by the Lean compiler to correspond to the C `double` type. From the point of view of Lean's logic, `Float` is equivalent to `Float.Model` (via the functions `Float.toModel` and `Float.ofModel`), which is itself a subtype of `UInt64`. Some of the operations on `Float` are defined in terms of their `Float.Model` counterparts, while others are opaque to Lean's kernel.

**Constructor**

```text
Float.ofModel
```

Constructs a `Float` from a `Float.Model`.

**Fields**

```text
toModel : Float.Model
```

Converts a `Float` into a `Float.Model`.

<a id="Float32___ofModel"></a>

**structure**

```text
Float32 : Type
```

32-bit floating-point numbers.

`Float32` corresponds to the IEEE 754 *binary32* format (`float` in C or `f32` in Rust). Floating-point numbers are a finite representation of a subset of the real numbers, extended with extra “sentinel” values that represent undefined and infinite results as well as separate positive and negative zeroes. Arithmetic on floating-point numbers approximates the corresponding operations on the real numbers by rounding the results to numbers that are representable, propagating error and infinite values.

Floating-point numbers include [subnormal numbers](https://en.wikipedia.org/wiki/Subnormal_number). Their special values are:

- `NaN`, which denotes a class of “not a number” values that result from operations such as dividing zero by zero, and
- `Inf` and `-Inf`, which represent positive and infinities that result from dividing non-zero values by zero.

Like other low-level types, `Float32` is special-cased by the Lean compiler to correspond to the C `float` type. From the point of view of Lean's logic, `Float32` is equivalent to `Float32.Model` (via the functions `Float32.toModel` and `Float32.ofModel`), which is itself a subtype of `UInt32`. Some of the operations on `Float32` are defined in terms of their `Float32.Model` counterparts, while others are opaque to Lean's kernel.

**Constructor**

```text
Float32.ofModel
```

Constructs a `Float32` from a `Float32.Model`.

**Fields**

```text
toModel : Float32.Model
```

Converts a `Float32` into a `Float32.Model`.

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--Logical-Model"></a>
### 20.6.1. Logical Model

Lean provides two floating-point types: `Float` represents 64-bit floating-point values, while `Float32` represents 32-bit floating-point values. The precision of `Float` does not vary based on the platform that Lean is running on.

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--Logical-Model--Model-Details"></a>
#### 20.6.1.1. Model Details

The logical models of `Float` and `Float32` consist of unsigned integers with validity predicates. Each defined operation first interprets the integer into a `Float.Model.UnpackedFloat`, which is a higher-level model that is not specific to a bit width. Then, the defined operation is implemented in terms of `UnpackedFloat`, and the result is re-packed. These definitions constitute a *logical specification* designed for reasoning. Although they can be executed, they will run significantly slower than native code. Not all operations are defined; some are instead opaque functions whose behavior cannot be reasoned about in Lean's logic.

This model is not intended to serve as the basis for a more extensive floating-point library. It exists only to support the reasoning tools available in Lean and is not suitable for larger-scale development. Do not use this model as the basis of a more extensive floating-point library. Instead, implement a suitable model, prove the equivalence of the its operations to this model, and then transfer lemmas using the equivalence.

<a id="Float___Model___mk"></a>

**structure**

```text
Float.Model : Type
```

The logical model for the `Float` type.

This is defined as the type of `UInt64` with the additional restriction that bit patterns encoding a `NaN` must be exactly a chosen canonical `NaN`.

Most functions on `Float.Model` work by unpacking the `Float.Model` into the inductive type `UnpackedFloat`, performing the operation there, and then repacking the result into a `Float.Model`.

It is not a goal of this development to serve as the basis for a general-purpose floating-point library or to have any direct lemmas written about it at all. Rather, users interested in a library about floating-point numbers should develop such a library completely separately, and users interested in proving properties of their programs involving `Float` should prove that the operations defined here are equivalent to the operations defined in the separate library and then transfer lemmas from the library to the `Float` and `Float32` types.

**Constructor**

```text
Float.Model.mk
```

**Fields**

```text
toBits : UInt64
```

The underlying bit pattern of the `Float.Model`.

```text
valid : Float.Model.Format.binary64.Valid self.toBits.toBitVec
```

The underlying bit pattern is valid according to the IEEE `binary64` format.

<a id="Float32___Model___mk"></a>

**structure**

```text
Float32.Model : Type
```

The logical model for the `Float32` type.

This is defined as the type of `UInt32` with the additional restriction that bit patterns encoding a `NaN` must be exactly a chosen canonical `NaN`.

Most functions on `Float32.Model` work by unpacking the `Float32.Model` into the inductive type `UnpackedFloat`, performing the operation there, and then repacking the result into a `Float32.Model`.

It is not a goal of this development to serve as the basis for a general-purpose floating-point library or to have any direct lemmas written about it at all. Rather, users interested in a library about floating-point numbers should develop such a library completely separately, and users interested in proving properties of their programs involving `Float32` should prove that the operations defined here are equivalent to the operations defined in the separate library and then transfer lemmas from the library to the `Float` and `Float32` types.

**Constructor**

```text
Float32.Model.mk
```

**Fields**

```text
toBits : UInt32
```

The underlying bit pattern of the `Float32.Model`.

```text
valid : Float.Model.Format.binary32.Valid self.toBits.toBitVec
```

The underlying bit pattern is valid according to the IEEE `binary32` format.

<a id="Float___Model___pack"></a>

**def**

```text
Float.Model.pack (f : Float.Model.UnpackedFloat) : Float.Model
```

Pack an `UnpackedFloat` into the corresponding `Float.Model`. This operation only gives a meaningful result if the float is already correctly rounded for the `Format.binary64` format.

<a id="Float32___Model___pack"></a>

**def**

```text
Float32.Model.pack (f : Float.Model.UnpackedFloat) : Float32.Model
```

Pack an `UnpackedFloat` into the corresponding `Float32.Model`. This operation only gives a meaningful result if the float is already correctly rounded for the `Format.binary32` format.

<a id="Float___Model___unpack"></a>

**def**

```text
Float.Model.unpack (f : Float.Model) : Float.Model.UnpackedFloat
```

Unpack a `Float.Model` into the corresponding `UnpackedFloat`.

<a id="Float32___Model___unpack"></a>

**def**

```text
Float32.Model.unpack (f : Float32.Model) : Float.Model.UnpackedFloat
```

Unpack a `Float32.Model` into the corresponding `UnpackedFloat`.

<a id="Float___Model___UnpackedFloat___infinity"></a>

**inductive type**

```text
Float.Model.UnpackedFloat : Type
```

An inductive type representing a floating-point number with constructors for signed infinity, not-a-number without payload, signed zero, and finite floats with a sign, positive natural mantissa and integral exponent.

Finite floats do not have a unique representation in this format: multiplying the mantissa by two and decreasing the exponent by one yields a finite float that represents the same rational number.

For a given `Format`, we say that an unpacked float is in canonical form if the exponent is equal to the `targetExponent` according to that format. Some operations on `UnpackedFloat`, such as `compare`, assume that the input(s) are all in canonical form for the same format.

Note that an unpacked float in canonical form for a given format may not actually be representable in that format as the exponent is too large to fit. In this case, the `pack` function will overflow the float to infinity.

This type exists solely for the purpose of supporting `Float.Model` and `Float32.Model`. It is not a goal of this development to serve as the basis for a general-purpose floating-point library or to have any direct lemmas written about it at all. Rather, users interested in a library about floating-point numbers should develop such a library completely separately, and users interested in proving properties of their programs involving `Float` should prove that the operations defined here are equivalent to the operations defined in the separate library and then transfer lemmas from the library to the `Float` and `Float32` types.

**Constructors**

```text
Float.Model.UnpackedFloat.infinity
  (sign : Float.Model.UnpackedFloat.Sign) :
  Float.Model.UnpackedFloat
```

Signed infinity.

```text
Float.Model.UnpackedFloat.notANumber :
  Float.Model.UnpackedFloat
```

Not a number. There is no payload attached to a NaN in this format.

```text
Float.Model.UnpackedFloat.zero
  (sign : Float.Model.UnpackedFloat.Sign) :
  Float.Model.UnpackedFloat
```

Signed zero.

```text
Float.Model.UnpackedFloat.finite
  (sign : Float.Model.UnpackedFloat.Sign) (mantissa : Nat)
  (exponent : Int) (mantissa_pos : 0 < mantissa) :
  Float.Model.UnpackedFloat
```

Finite floats consisting of a sign bit, a positive natural mantissa and an exponent.

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--Logical-Model--Model-Operations"></a>
#### 20.6.1.2. Model Operations

The following operations are specified for floating-point values. Other operators are represented by opaque functions and do not reduce in the kernel.

<a id="Float___Model___UnpackedFloat___add"></a>

**def**

```text
Float.Model.UnpackedFloat.add (spec : Float.Model.Format) :
  Float.Model.UnpackedFloat →
    Float.Model.UnpackedFloat → Float.Model.UnpackedFloat
```

Computes the sum of two floating point numbers and rounds the result according to the given specification.

<a id="Float___Model___UnpackedFloat___sub"></a>

**def**

```text
Float.Model.UnpackedFloat.sub (spec : Float.Model.Format) :
  Float.Model.UnpackedFloat →
    Float.Model.UnpackedFloat → Float.Model.UnpackedFloat
```

Computes the difference of two floating point numbers and rounds the result according to the given specification.

<a id="Float___Model___UnpackedFloat___mul"></a>

**def**

```text
Float.Model.UnpackedFloat.mul (spec : Float.Model.Format) :
  Float.Model.UnpackedFloat →
    Float.Model.UnpackedFloat → Float.Model.UnpackedFloat
```

Computes the product of two floating-point numbers and rounds the result according to the given specification.

<a id="Float___Model___UnpackedFloat___div"></a>

**def**

```text
Float.Model.UnpackedFloat.div (spec : Float.Model.Format) :
  Float.Model.UnpackedFloat →
    Float.Model.UnpackedFloat → Float.Model.UnpackedFloat
```

Computes the quotient of two floating point numbers and rounds the result according to the given specification.

<a id="Float___Model___UnpackedFloat___sqrt"></a>

**def**

```text
Float.Model.UnpackedFloat.sqrt (spec : Float.Model.Format) :
  Float.Model.UnpackedFloat → Float.Model.UnpackedFloat
```

Computes the square root of a floating-point number and rounds the result according to the given specification.

<a id="Float___Model___UnpackedFloat___neg"></a>

**def**

```text
Float.Model.UnpackedFloat.neg :
  Float.Model.UnpackedFloat → Float.Model.UnpackedFloat
```

Negates the given float.

<a id="Float___Model___UnpackedFloat___abs"></a>

**def**

```text
Float.Model.UnpackedFloat.abs :
  Float.Model.UnpackedFloat → Float.Model.UnpackedFloat
```

Returns the given float with positive sign.

<a id="Float___Model___UnpackedFloat___isNaN"></a>

**def**

```text
Float.Model.UnpackedFloat.isNaN : Float.Model.UnpackedFloat → Bool
```

Returns `true` if the float is `NaN`.

<a id="Float___Model___UnpackedFloat___isInf"></a>

**def**

```text
Float.Model.UnpackedFloat.isInf : Float.Model.UnpackedFloat → Bool
```

Returns `true` if the float is positive or negative infinity.

<a id="Float___Model___UnpackedFloat___isFinite"></a>

**def**

```text
Float.Model.UnpackedFloat.isFinite : Float.Model.UnpackedFloat → Bool
```

Returns `true` if the float represents a real number, i.e., it is neither infinite nor `NaN`.

<a id="Float___Model___UnpackedFloat___compare"></a>

**def**

```text
Float.Model.UnpackedFloat.compare :
  Float.Model.UnpackedFloat →
    Float.Model.UnpackedFloat → Option Ordering
```

Computes the ordering between the two floats as specificed by IEEE. Returns an `Option Ordering` to account for the fact that `NaN` is incomparable with everything. Also, positive and negative zero are equal.

Important: this operation only works correctly if the two inputs are in canonical form for a common format (see the docstring for `UnpackedFloat` for details.)

<a id="Float___Model___UnpackedFloat___beq"></a>

**def**

```text
Float.Model.UnpackedFloat.beq (a b : Float.Model.UnpackedFloat) : Bool
```

Determines whether `a` is equal to `b` according to IEEE rules.

This is not a reflexive relation.

<a id="Float___Model___UnpackedFloat___lt"></a>

**def**

```text
Float.Model.UnpackedFloat.lt (a b : Float.Model.UnpackedFloat) : Bool
```

Determines whether `a` is less than `b` according to IEEE rules.

This is not a total ordering.

<a id="Float___Model___UnpackedFloat___le"></a>

**def**

```text
Float.Model.UnpackedFloat.le (a b : Float.Model.UnpackedFloat) : Bool
```

Determines whether `a` is less than or equal to `b` according to IEEE rules.

This is not a total ordering, and `≤` is not reflexive.

<a id="Float___Model___UnpackedFloat___ofNat"></a>

**def**

```text
Float.Model.UnpackedFloat.ofNat (spec : Float.Model.Format) (n : Nat) :
  Float.Model.UnpackedFloat
```

Converts a `Nat` to an `UnpackedFloat`, returning positive zero on zero.

<a id="Float___Model___UnpackedFloat___ofInt"></a>

**def**

```text
Float.Model.UnpackedFloat.ofInt (spec : Float.Model.Format) (n : Int) :
  Float.Model.UnpackedFloat
```

Converts an `Int` to an `UnpackedFloat`, returning positive zero on zero.

<a id="Float___Model___UnpackedFloat___ofScientific"></a>

**def**

```text
Float.Model.UnpackedFloat.ofScientific (spec : Float.Model.Format)
  (m : Nat) (e : Int) : Float.Model.UnpackedFloat
```

Computes `m * 10 ^ e`.

<a id="Float___Model___UnpackedFloat___toInt8"></a>

**def**

```text
Float.Model.UnpackedFloat.toInt8 (f : Float.Model.UnpackedFloat) : Int8
```

Converts an `UnpackedFloat` to an `Int8`, truncating after the decimal point, sending `NaN` to `0` and clamping out-of-range values and infinities.

<a id="Float___Model___UnpackedFloat___ofInt8"></a>

**def**

```text
Float.Model.UnpackedFloat.ofInt8 (spec : Float.Model.Format)
  (n : Int8) : Float.Model.UnpackedFloat
```

Converts an `Int8` to an `UnpackedFloat`, returning positive zero on zero.

<a id="Float___Model___UnpackedFloat___toInt16"></a>

**def**

```text
Float.Model.UnpackedFloat.toInt16 (f : Float.Model.UnpackedFloat) :
  Int16
```

Converts an `UnpackedFloat` to an `Int16`, truncating after the decimal point, sending `NaN` to `0` and clamping out-of-range values and infinities.

<a id="Float___Model___UnpackedFloat___ofInt16"></a>

**def**

```text
Float.Model.UnpackedFloat.ofInt16 (spec : Float.Model.Format)
  (n : Int16) : Float.Model.UnpackedFloat
```

Converts an `Int16` to an `UnpackedFloat`, returning positive zero on zero.

<a id="Float___Model___UnpackedFloat___toInt32"></a>

**def**

```text
Float.Model.UnpackedFloat.toInt32 (f : Float.Model.UnpackedFloat) :
  Int32
```

Converts an `UnpackedFloat` to an `Int32`, truncating after the decimal point, sending `NaN` to `0` and clamping out-of-range values and infinities.

<a id="Float___Model___UnpackedFloat___ofInt32"></a>

**def**

```text
Float.Model.UnpackedFloat.ofInt32 (spec : Float.Model.Format)
  (n : Int32) : Float.Model.UnpackedFloat
```

Converts an `Int32` to an `UnpackedFloat`, returning positive zero on zero.

<a id="Float___Model___UnpackedFloat___toInt64"></a>

**def**

```text
Float.Model.UnpackedFloat.toInt64 (f : Float.Model.UnpackedFloat) :
  Int64
```

Converts an `UnpackedFloat` to an `Int64`, truncating after the decimal point, sending `NaN` to `0` and clamping out-of-range values and infinities.

<a id="Float___Model___UnpackedFloat___ofInt64"></a>

**def**

```text
Float.Model.UnpackedFloat.ofInt64 (spec : Float.Model.Format)
  (n : Int64) : Float.Model.UnpackedFloat
```

Converts an `Int64` to an `UnpackedFloat`, returning positive zero on zero.

<a id="Float___Model___UnpackedFloat___toISize"></a>

**def**

```text
Float.Model.UnpackedFloat.toISize (f : Float.Model.UnpackedFloat) :
  ISize
```

Converts an `UnpackedFloat` to an `ISize`, truncating after the decimal point, sending `NaN` to `0` and clamping out-of-range values and infinities.

<a id="Float___Model___UnpackedFloat___ofISize"></a>

**def**

```text
Float.Model.UnpackedFloat.ofISize (spec : Float.Model.Format)
  (n : ISize) : Float.Model.UnpackedFloat
```

Converts an `ISize` to an `UnpackedFloat`, returning positive zero on zero.

<a id="Float___Model___UnpackedFloat___toUInt8"></a>

**def**

```text
Float.Model.UnpackedFloat.toUInt8 (f : Float.Model.UnpackedFloat) :
  UInt8
```

Converts an `UnpackedFloat` to a `UInt8`, truncating after the decimal point, sending `NaN` to `0` and clamping out-of-range values and infinities.

<a id="Float___Model___UnpackedFloat___ofUInt8"></a>

**def**

```text
Float.Model.UnpackedFloat.ofUInt8 (spec : Float.Model.Format)
  (n : UInt8) : Float.Model.UnpackedFloat
```

Converts a `UInt8` to an `UnpackedFloat`, returning positive zero on zero.

<a id="Float___Model___UnpackedFloat___toUInt16"></a>

**def**

```text
Float.Model.UnpackedFloat.toUInt16 (f : Float.Model.UnpackedFloat) :
  UInt16
```

Converts an `UnpackedFloat` to a `UInt16`, truncating after the decimal point, sending `NaN` to `0` and clamping out-of-range values and infinities.

<a id="Float___Model___UnpackedFloat___ofUInt16"></a>

**def**

```text
Float.Model.UnpackedFloat.ofUInt16 (spec : Float.Model.Format)
  (n : UInt16) : Float.Model.UnpackedFloat
```

Converts a `UInt16` to an `UnpackedFloat`, returning positive zero on zero.

<a id="Float___Model___UnpackedFloat___toUInt32"></a>

**def**

```text
Float.Model.UnpackedFloat.toUInt32 (f : Float.Model.UnpackedFloat) :
  UInt32
```

Converts an `UnpackedFloat` to a `UInt32`, truncating after the decimal point, sending `NaN` to `0` and clamping out-of-range values and infinities.

<a id="Float___Model___UnpackedFloat___ofUInt32"></a>

**def**

```text
Float.Model.UnpackedFloat.ofUInt32 (spec : Float.Model.Format)
  (n : UInt32) : Float.Model.UnpackedFloat
```

Converts a `UInt32` to an `UnpackedFloat`, returning positive zero on zero.

<a id="Float___Model___UnpackedFloat___toUInt64"></a>

**def**

```text
Float.Model.UnpackedFloat.toUInt64 (f : Float.Model.UnpackedFloat) :
  UInt64
```

Converts an `UnpackedFloat` to a `UInt64`, truncating after the decimal point, sending `NaN` to `0` and clamping out-of-range values and infinities.

<a id="Float___Model___UnpackedFloat___ofUInt64"></a>

**def**

```text
Float.Model.UnpackedFloat.ofUInt64 (spec : Float.Model.Format)
  (n : UInt64) : Float.Model.UnpackedFloat
```

Converts a `UInt64` to an `UnpackedFloat`, returning positive zero on zero.

<a id="Float___Model___UnpackedFloat___toUSize"></a>

**def**

```text
Float.Model.UnpackedFloat.toUSize (f : Float.Model.UnpackedFloat) :
  USize
```

Converts an `UnpackedFloat` to a `USize`, truncating after the decimal point, sending `NaN` to `0` and clamping out-of-range values and infinities.

<a id="Float___Model___UnpackedFloat___ofUSize"></a>

**def**

```text
Float.Model.UnpackedFloat.ofUSize (spec : Float.Model.Format)
  (n : USize) : Float.Model.UnpackedFloat
```

Converts a `USize` to an `UnpackedFloat`, returning positive zero on zero.

<a id="Kernel-Reasoning"></a>
Kernel Reasoning 

The Lean kernel can compare expressions of type `Float` for syntactic equality, so `0.0` is definitionally equal to itself.

```proofscript
example : (0.0 : Float) = (0.0 : Float) := by rfl
```

Additionally, terms that require reduction to become syntactically equal can be checked by the kernel when they use only operations that are modeled in Lean's logic:

```proofscript
example : (0.0 : Float) = (0.0 + 0.0 : Float) := by rfl
```

The kernel cannot reduce terms that use operations that are not directly modeled, such as trigonometric functions:

```proofscript
example : (0.0 : Float).sin = (0.0 : Float) := by rfl
```

```lean
Tactic `rfl` failed: The left-hand side
  Float.sin 0.0
is not definitionally equal to the right-hand side
  0.0

⊢ Float.sin 0.0 = 0.0
```

However, the `native_decide` tactic can invoke the underlying platform's floating-point primitives that are used by Lean for run-time programs:
<a id="Float___sin_zero_eq_zero-_LPAR_in-Kernel-Reasoning_RPAR_"></a>


```proofscript
theorem Float.sin_zero_eq_zero :
    ((0.0 : Float).sin == (0.0 : Float)) = true := by
  native_decide
```

This tactic executes a decision procedure as compiled native code. This requires trusting the Lean compiler, interpreter and the low-level implementations of built-in operators in addition to the kernel. To make this dependency precisely clear, the tactic creates the axiom `Float.sin_zero_eq_zero._native.native_decide.ax_1`:

```proofscript
#print axioms Float.sin_zero_eq_zero
```

```lean
'Float.sin_zero_eq_zero' depends on axioms: [propext,
 Classical.choice,
 Quot.sound,
 Float.sin_zero_eq_zero._native.native_decide.ax_1]
```

<a id="Floating-Point-Equality-Is-Not-Reflexive"></a>
Floating-Point Equality Is Not Reflexive 

Floating-point operations may produce `NaN` values that indicate an undefined result. These values are not comparable with each other; in particular, all comparisons involving `NaN` will return `false`, including equality.

```proofscript
#eval ((0.0 : Float) / 0.0) == ((0.0 : Float) / 0.0)
```

<a id="Floating-Point-Equality-Is-Not-a-Congruence"></a>
Floating-Point Equality Is Not a Congruence 

Applying a function to two equal floating-point numbers may not result in equal numbers. In particular, positive and negative zero are distinct values that are equated by floating-point equality, but division by positive or negative zero yields positive or negative infinite values.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="neg0-_LPAR_in-Floating-Point-Equality-Is-Not-a-Congruence_RPAR_"></a>
<a id="pos0-_LPAR_in-Floating-Point-Equality-Is-Not-a-Congruence_RPAR_"></a>


```proofscript
const neg0 : Float := -0.0

const pos0 : Float := 0.0

#eval (neg0 == pos0, 1.0 / neg0 == 1.0 / pos0)
```

```lean
(true, false)
```

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--Syntax"></a>
### 20.6.2. Syntax

Lean does not have dedicated floating-point literals. Instead, floating-point literals are resolved via the appropriate instances of the `OfScientific` and `Neg` type classes.

<a id="Floating-Point-Literals"></a>
Floating-Point Literals 

The term

```proofscript
(-2.2523 : Float)
```

is syntactic sugar for

```proofscript
(Neg.neg (OfScientific.ofScientific 22523 true 4) : Float)
```

and the term

```proofscript
(413.52 : Float32)
```

is syntactic sugar for

```proofscript
(OfScientific.ofScientific 41352 true 2 : Float32)
```

<a id="Float-api"></a>
### 20.6.3. API Reference

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--API-Reference--Properties"></a>
#### 20.6.3.1. Properties

Floating-point numbers fall into one of three categories:

- Finite numbers are ordinary floating-point values.
- Infinities, which may be positive or negative, result from division by zero.
- `NaN`s, which are not numbers, result from other undefined operations, such as the square root of a negative number.

<a id="Float___isInf"></a>

**def**

```text
Float.isInf : Float → Bool
```

Checks whether a floating-point number is a positive or negative infinite number, but not a finite number or `NaN`.

This function has a logical model in terms of `Float.Model`. It is compiled to the C operator `isinf`.

<a id="Float32___isInf"></a>

**def**

```text
Float32.isInf : Float32 → Bool
```

Checks whether a floating-point number is a positive or negative infinite number, but not a finite number or `NaN`.

This function has a logical model in terms of `Float32.Model`. It is compiled to the C operator `isinf`.

<a id="Float___isNaN"></a>

**def**

```text
Float.isNaN : Float → Bool
```

Checks whether a floating point number is a `NaN` (“not a number”) value.

`NaN` values result from operations that might otherwise be errors, such as dividing zero by zero.

This function returns `true` if and only if the input is propositionally equal to `Float.nan`.

This function has a logical model in terms of `Float.Model`. It is compiled to the C operator `isnan`.

<a id="Float32___isNaN"></a>

**def**

```text
Float32.isNaN : Float32 → Bool
```

Checks whether a floating point number is a `NaN` ("not a number") value.

`NaN` values result from operations that might otherwise be errors, such as dividing zero by zero.

This function returns `true` if and only if the input is propositionally equal to `Float32.nan`.

This function has a logical model in terms of `Float32.Model`. It is compiled to the C operator `isnan`.

<a id="Float___isFinite"></a>

**def**

```text
Float.isFinite : Float → Bool
```

Checks whether a floating-point number is finite, that is, whether it is normal, subnormal, or zero, but not infinite or `NaN`.

This function has a logical model in terms of `Float.Model`. It is compiled to the C operator `isfinite`.

<a id="Float32___isFinite"></a>

**def**

```text
Float32.isFinite : Float32 → Bool
```

Checks whether a floating-point number is finite, that is, whether it is normal, subnormal, or zero, but not infinite or `NaN`.

This function has a logical model in terms of `Float32.Model`. It is compiled to the C operator `isfinite`.

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--API-Reference--Conversions"></a>
#### 20.6.3.2. Conversions

<a id="Float___toBits"></a>

**def**

```text
Float.toBits : Float → UInt64
```

Bit-for-bit conversion to `UInt64`. Interprets a `Float` as a `UInt64`, ignoring the numeric value and treating the `Float`'s bit pattern as a `UInt64`.

`Float`s and `UInt64`s have the same endianness on all supported platforms. IEEE 754 very precisely specifies the bit layout of floats.

This function is distinct from `Float.toUInt64`, which attempts to preserve the numeric value rather than reinterpreting the bit pattern.

<a id="Float32___toBits"></a>

**def**

```text
Float32.toBits : Float32 → UInt32
```

Bit-for-bit conversion to `UInt32`. Interprets a `Float32` as a `UInt32`, ignoring the numeric value and treating the `Float32`'s bit pattern as a `UInt32`.

`Float32`s and `UInt32`s have the same endianness on all supported platforms. IEEE 754 very precisely specifies the bit layout of floats.

This function is distinct from `Float.toUInt32`, which attempts to preserve the numeric value rather than reinterpreting the bit pattern.

<a id="Float___ofBits"></a>

**def**

```text
Float.ofBits : UInt64 → Float
```

Bit-for-bit conversion from `UInt64`. Interprets a `UInt64` as a `Float`, ignoring the numeric value and treating the `UInt64`'s bit pattern as a `Float`.

`Float`s and `UInt64`s have the same endianness on all supported platforms. IEEE 754 very precisely specifies the bit layout of floats.

This function has a logical model in terms of `Float.Model`.

<a id="Float32___ofBits"></a>

**def**

```text
Float32.ofBits : UInt32 → Float32
```

Bit-for-bit conversion from `UInt32`. Interprets a `UInt32` as a `Float32`, ignoring the numeric value and treating the `UInt32`'s bit pattern as a `Float32`.

`Float32`s and `UInt32`s have the same endianness on all supported platforms. IEEE 754 very precisely specifies the bit layout of floats.

This function has a logical model in terms of `Float32.Model`.

<a id="Float___toFloat32"></a>

**opaque**

```text
Float.toFloat32 : Float → Float32
```

Converts a 64-bit floating-point number to a 32-bit floating-point number. This may lose precision.

This function does not reduce in the kernel.

<a id="Float32___toFloat"></a>

**opaque**

```text
Float32.toFloat : Float32 → Float
```

Converts a 32-bit floating-point number to a 64-bit floating-point number.

This function does not reduce in the kernel.

<a id="Float___toString"></a>

**opaque**

```text
Float.toString : Float → String
```

Converts a floating-point number to a string.

This function does not reduce in the kernel.

<a id="Float32___toString"></a>

**opaque**

```text
Float32.toString : Float32 → String
```

Converts a floating-point number to a string.

This function does not reduce in the kernel.

<a id="Float___toUInt8"></a>

**def**

```text
Float.toUInt8 : Float → UInt8
```

Converts a floating-point number to an 8-bit unsigned integer.

If the given `Float` is non-negative, truncates the value to a positive integer, rounding down and clamping to the range of `UInt8`. Returns `0` if the `Float` is negative or `NaN`, and returns the largest `UInt8` value (i.e. `UInt8.size - 1`) if the float is larger than it.

This function has a logical model in terms of `Float.Model`.

<a id="Float___toInt8"></a>

**def**

```text
Float.toInt8 : Float → Int8
```

Truncates a floating-point number to the nearest 8-bit signed integer, rounding towards zero.

If the `Float` is larger than the maximum value for `Int8` (including `Inf`), returns the maximum value of `Int8` (i.e. `Int8.maxValue`). If it is smaller than the minimum value for `Int8` (including `-Inf`), returns the minimum value of `Int8` (i.e. `Int8.minValue`). If it is `NaN`, returns `0`.

This function has a logical model in terms of `Float.Model`.

<a id="Float32___toUInt8"></a>

**def**

```text
Float32.toUInt8 : Float32 → UInt8
```

Converts a floating-point number to an 8-bit unsigned integer.

If the given `Float32` is non-negative, truncates the value to a positive integer, rounding down and clamping to the range of `UInt8`. Returns `0` if the `Float32` is negative or `NaN`, and returns the largest `UInt8` value (i.e. `UInt8.size - 1`) if the float is larger than it.

This function has a logical model in terms of `Float32.Model`.

<a id="Float32___toInt8"></a>

**def**

```text
Float32.toInt8 : Float32 → Int8
```

Truncates a floating-point number to the nearest 8-bit signed integer, rounding towards zero.

If the `Float` is larger than the maximum value for `Int8` (including `Inf`), returns the maximum value of `Int8` (i.e. `Int8.maxValue`). If it is smaller than the minimum value for `Int8` (including `-Inf`), returns the minimum value of `Int8` (i.e. `Int8.minValue`). If it is `NaN`, returns `0`.

This function has a logical model in terms of `Float32.Model`.

<a id="Float___toUInt16"></a>

**def**

```text
Float.toUInt16 : Float → UInt16
```

Converts a floating-point number to a 16-bit unsigned integer.

If the given `Float` is non-negative, truncates the value to a positive integer, rounding down and clamping to the range of `UInt16`. Returns `0` if the `Float` is negative or `NaN`, and returns the largest `UInt16` value (i.e. `UInt16.size - 1`) if the float is larger than it.

This function has a logical model in terms of `Float.Model`.

<a id="Float___toInt16"></a>

**def**

```text
Float.toInt16 : Float → Int16
```

Truncates a floating-point number to the nearest 16-bit signed integer, rounding towards zero.

If the `Float` is larger than the maximum value for `Int16` (including `Inf`), returns the maximum value of `Int16` (i.e. `Int16.maxValue`). If it is smaller than the minimum value for `Int16` (including `-Inf`), returns the minimum value of `Int16` (i.e. `Int16.minValue`). If it is `NaN`, returns `0`.

This function has a logical model in terms of `Float.Model`.

<a id="Float32___toUInt16"></a>

**def**

```text
Float32.toUInt16 : Float32 → UInt16
```

Converts a floating-point number to a 16-bit unsigned integer.

If the given `Float32` is non-negative, truncates the value to a positive integer, rounding down and clamping to the range of `UInt16`. Returns `0` if the `Float32` is negative or `NaN`, and returns the largest `UInt16` value (i.e. `UInt16.size - 1`) if the float is larger than it.

This function has a logical model in terms of `Float32.Model`.

<a id="Float32___toInt16"></a>

**def**

```text
Float32.toInt16 : Float32 → Int16
```

Truncates a floating-point number to the nearest 16-bit signed integer, rounding towards zero.

If the `Float` is larger than the maximum value for `Int16` (including `Inf`), returns the maximum value of `Int16` (i.e. `Int16.maxValue`). If it is smaller than the minimum value for `Int16` (including `-Inf`), returns the minimum value of `Int16` (i.e. `Int16.minValue`). If it is `NaN`, returns `0`.

This function has a logical model in terms of `Float32.Model`.

<a id="Float___toUInt32"></a>

**def**

```text
Float.toUInt32 : Float → UInt32
```

Converts a floating-point number to a 32-bit unsigned integer.

If the given `Float` is non-negative, truncates the value to a positive integer, rounding down and clamping to the range of `UInt32`. Returns `0` if the `Float` is negative or `NaN`, and returns the largest `UInt32` value (i.e. `UInt32.size - 1`) if the float is larger than it.

This function has a logical model in terms of `Float.Model`.

<a id="Float32___toUInt32"></a>

**def**

```text
Float32.toUInt32 : Float32 → UInt32
```

Converts a floating-point number to a 32-bit unsigned integer.

If the given `Float32` is non-negative, truncates the value to a positive integer, rounding down and clamping to the range of `UInt32`. Returns `0` if the `Float32` is negative or `NaN`, and returns the largest `UInt32` value (i.e. `UInt32.size - 1`) if the float is larger than it.

This function has a logical model in terms of `Float32.Model`.

<a id="Float___toInt32"></a>

**def**

```text
Float.toInt32 : Float → Int32
```

Truncates a floating-point number to the nearest 32-bit signed integer, rounding towards zero.

If the `Float` is larger than the maximum value for `Int32` (including `Inf`), returns the maximum value of `Int32` (i.e. `Int32.maxValue`). If it is smaller than the minimum value for `Int32` (including `-Inf`), returns the minimum value of `Int32` (i.e. `Int32.minValue`). If it is `NaN`, returns `0`.

This function has a logical model in terms of `Float.Model`.

<a id="Float32___toInt32"></a>

**def**

```text
Float32.toInt32 : Float32 → Int32
```

Truncates a floating-point number to the nearest 32-bit signed integer, rounding towards zero.

If the `Float` is larger than the maximum value for `Int32` (including `Inf`), returns the maximum value of `Int32` (i.e. `Int32.maxValue`). If it is smaller than the minimum value for `Int32` (including `-Inf`), returns the minimum value of `Int32` (i.e. `Int32.minValue`). If it is `NaN`, returns `0`.

This function has a logical model in terms of `Float32.Model`.

<a id="Float___toUInt64"></a>

**def**

```text
Float.toUInt64 : Float → UInt64
```

Converts a floating-point number to a 64-bit unsigned integer.

If the given `Float` is non-negative, truncates the value to a positive integer, rounding down and clamping to the range of `UInt64`. Returns `0` if the `Float` is negative or `NaN`, and returns the largest `UInt64` value (i.e. `UInt64.size - 1`) if the float is larger than it.

This function has a logical model in terms of `Float.Model`.

<a id="Float___toInt64"></a>

**def**

```text
Float.toInt64 : Float → Int64
```

Truncates a floating-point number to the nearest 64-bit signed integer, rounding towards zero.

If the `Float` is larger than the maximum value for `Int64` (including `Inf`), returns the maximum value of `Int64` (i.e. `Int64.maxValue`). If it is smaller than the minimum value for `Int64` (including `-Inf`), returns the minimum value of `Int64` (i.e. `Int64.minValue`). If it is `NaN`, returns `0`.

This function has a logical model in terms of `Float.Model`.

<a id="Float32___toUInt64"></a>

**def**

```text
Float32.toUInt64 : Float32 → UInt64
```

Converts a floating-point number to a 64-bit unsigned integer.

If the given `Float32` is non-negative, truncates the value to a positive integer, rounding down and clamping to the range of `UInt64`. Returns `0` if the `Float32` is negative or `NaN`, and returns the largest `UInt64` value (i.e. `UInt64.size - 1`) if the float is larger than it.

This function has a logical model in terms of `Float32.Model`.

<a id="Float32___toInt64"></a>

**def**

```text
Float32.toInt64 : Float32 → Int64
```

Truncates a floating-point number to the nearest 64-bit signed integer, rounding towards zero.

If the `Float` is larger than the maximum value for `Int64` (including `Inf`), returns the maximum value of `Int64` (i.e. `Int64.maxValue`). If it is smaller than the minimum value for `Int64` (including `-Inf`), returns the minimum value of `Int64` (i.e. `Int64.minValue`). If it is `NaN`, returns `0`.

This function has a logical model in terms of `Float32.Model`.

<a id="Float___toUSize"></a>

**def**

```text
Float.toUSize : Float → USize
```

Converts a floating-point number to a word-sized unsigned integer.

If the given `Float` is non-negative, truncates the value to a positive integer, rounding down and clamping to the range of `USize`. Returns `0` if the `Float` is negative or `NaN`, and returns the largest `USize` value (i.e. `USize.size - 1`) if the float is larger than it.

This function has a logical model in terms of `Float.Model`.

<a id="Float32___toUSize"></a>

**def**

```text
Float32.toUSize : Float32 → USize
```

Converts a floating-point number to a word-sized unsigned integer.

If the given `Float32` is non-negative, truncates the value to a positive integer, rounding down and clamping to the range of `USize`. Returns `0` if the `Float32` is negative or `NaN`, and returns the largest `USize` value (i.e. `USize.size - 1`) if the float is larger than it.

This function has a logical model in terms of `Float32.Model`.

<a id="Float___toISize"></a>

**def**

```text
Float.toISize : Float → ISize
```

Truncates a floating-point number to the nearest word-sized signed integer, rounding towards zero.

If the `Float` is larger than the maximum value for `ISize` (including `Inf`), returns the maximum value of `ISize` (i.e. `ISize.maxValue`). If it is smaller than the minimum value for `ISize` (including `-Inf`), returns the minimum value of `ISize` (i.e. `ISize.minValue`). If it is `NaN`, returns `0`.

This function has a logical model in terms of `Float.Model`.

<a id="Float32___toISize"></a>

**def**

```text
Float32.toISize : Float32 → ISize
```

Truncates a floating-point number to the nearest word-sized signed integer, rounding towards zero.

If the `Float` is larger than the maximum value for `ISize` (including `Inf`), returns the maximum value of `ISize` (i.e. `ISize.maxValue`). If it is smaller than the minimum value for `ISize` (including `-Inf`), returns the minimum value of `ISize` (i.e. `ISize.minValue`). If it is `NaN`, returns `0`.

This function has a logical model in terms of `Float32.Model`.

<a id="Float___ofInt"></a>

**def**

```text
Float.ofInt : Int → Float
```

Converts an integer into the closest-possible 64-bit floating-point number, or positive or negative infinite floating-point value if the range of `Float` is exceeded.

<a id="Float32___ofInt"></a>

**def**

```text
Float32.ofInt : Int → Float32
```

Converts an integer into the closest-possible 32-bit floating-point number, or positive or negative infinite floating-point value if the range of `Float32` is exceeded.

<a id="Float___ofNat"></a>

**def**

```text
Float.ofNat (n : Nat) : Float
```

Converts a natural number into the closest-possible 64-bit floating-point number, or an infinite floating-point value if the range of `Float` is exceeded.

<a id="Float32___ofNat"></a>

**def**

```text
Float32.ofNat (n : Nat) : Float32
```

Converts a natural number into the closest-possible 32-bit floating-point number, or an infinite floating-point value if the range of `Float32` is exceeded.

<a id="Float___frExp"></a>

**opaque**

```text
Float.frExp : Float → Float × Int
```

Splits the given float `x` into a significand/exponent pair `(s, i)` such that `x = s * 2^i` where `s ∈ (-1;-0.5] ∪ [0.5; 1)`. Returns an undefined value if `x` is not finite.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `frexp`.

<a id="Float32___frExp"></a>

**opaque**

```text
Float32.frExp : Float32 → Float32 × Int
```

Splits the given float `x` into a significand/exponent pair `(s, i)` such that `x = s * 2^i` where `s ∈ (-1;-0.5] ∪ [0.5; 1)`. Returns an undefined value if `x` is not finite.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `frexp`.

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--API-Reference--Comparisons"></a>
#### 20.6.3.3. Comparisons

<a id="Float___beq"></a>

**def**

```text
Float.beq (a b : Float) : Bool
```

Checks whether two floating-point numbers are equal according to IEEE 754.

Floating-point equality does not correspond with propositional equality. In particular, it is not reflexive since `NaN != NaN`, and it is not a congruence because `0.0 == -0.0`, but `1.0 / 0.0 != 1.0 / -0.0`.

This function does not reduce in the kernel. It is compiled to the C equality operator.

<a id="Float32___beq"></a>

**def**

```text
Float32.beq (a b : Float32) : Bool
```

Checks whether two floating-point numbers are equal according to IEEE 754.

Floating-point equality does not correspond with propositional equality. In particular, it is not reflexive since `NaN != NaN`, and it is not a congruence because `0.0 == -0.0`, but `1.0 / 0.0 != 1.0 / -0.0`.

This function does not reduce in the kernel. It is compiled to the C equality operator.

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--API-Reference--Comparisons--Inequalities"></a>
##### 20.6.3.3.1. Inequalities

The decision procedures for inequalities are opaque constants in the logic. They can only be used via the `Lean.ofReduceBool` axiom, e.g. via the `native_decide` tactic.

<a id="Float___le"></a>

**def**

```text
Float.le : Float → Float → Bool
```

Non-strict inequality of floating-point numbers. Typically used via the `≤` operator.

<a id="Float32___le"></a>

**def**

```text
Float32.le : Float32 → Float32 → Bool
```

Non-strict inequality of floating-point numbers. Typically used via the `≤` operator.

<a id="Float___lt"></a>

**def**

```text
Float.lt : Float → Float → Bool
```

Strict inequality of floating-point numbers. Typically used via the `<` operator.

<a id="Float32___lt"></a>

**def**

```text
Float32.lt : Float32 → Float32 → Bool
```

Strict inequality of floating-point numbers. Typically used via the `<` operator.

<a id="Float___decLe"></a>

**def**

```text
Float.decLe (a b : Float) : Decidable (a ≤ b)
```

Compares two floating point numbers for non-strict inequality.

This function does not reduce in the kernel. It is compiled to the C inequality operator.

<a id="Float32___decLe"></a>

**def**

```text
Float32.decLe (a b : Float32) : Decidable (a ≤ b)
```

Compares two floating point numbers for non-strict inequality.

This function does not reduce in the kernel. It is compiled to the C inequality operator.

<a id="Float___decLt"></a>

**def**

```text
Float.decLt (a b : Float) : Decidable (a < b)
```

Compares two floating point numbers for strict inequality.

This function does not reduce in the kernel. It is compiled to the C inequality operator.

<a id="Float32___decLt"></a>

**def**

```text
Float32.decLt (a b : Float32) : Decidable (a < b)
```

Compares two floating point numbers for strict inequality.

This function does not reduce in the kernel. It is compiled to the C inequality operator.

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--API-Reference--Arithmetic"></a>
#### 20.6.3.4. Arithmetic

Arithmetic operations on floating-point values are typically invoked via the `Add Float`, `Sub Float`, `Mul Float`, `Div Float`, and `HomogeneousPow Float` instances, along with the corresponding `Float32` instances.

<a id="Float___add"></a>

**def**

```text
Float.add : Float → Float → Float
```

Adds two 64-bit floating-point numbers according to IEEE 754. Typically used via the `+` operator.

This function has a logical model in terms of `Float.Model`. It is compiled to the C addition operator.

<a id="Float32___add"></a>

**def**

```text
Float32.add : Float32 → Float32 → Float32
```

Adds two 32-bit floating-point numbers according to IEEE 754. Typically used via the `+` operator.

This function has a logical model in terms of `Float32.Model`. It is compiled to the C addition operator.

<a id="Float___sub"></a>

**def**

```text
Float.sub : Float → Float → Float
```

Subtracts 64-bit floating-point numbers according to IEEE 754. Typically used via the `-` operator.

This function has a logical model in terms of `Float.Model`. It is compiled to the C subtraction operator.

<a id="Float32___sub"></a>

**def**

```text
Float32.sub : Float32 → Float32 → Float32
```

Subtracts 32-bit floating-point numbers according to IEEE 754. Typically used via the `-` operator.

This function has a logical model in terms of `Float32.Model`. It is compiled to the C subtraction operator.

<a id="Float___mul"></a>

**def**

```text
Float.mul : Float → Float → Float
```

Multiplies 64-bit floating-point numbers according to IEEE 754. Typically used via the `*` operator.

This function has a logical model in terms of `Float.Model`. It is compiled to the C multiplication operator.

<a id="Float32___mul"></a>

**def**

```text
Float32.mul : Float32 → Float32 → Float32
```

Multiplies 32-bit floating-point numbers according to IEEE 754. Typically used via the `*` operator.

This function has a logical model in terms of `Float32.Model`. It is compiled to the C multiplication operator.

<a id="Float___div"></a>

**def**

```text
Float.div : Float → Float → Float
```

Divides 64-bit floating-point numbers according to IEEE 754. Typically used via the `/` operator.

In Lean, division by zero typically yields zero. For `Float`, it instead yields either `Inf`, `-Inf`, or `NaN`.

This function has a logical model in terms of `Float.Model`. It is compiled to the C division operator.

<a id="Float32___div"></a>

**def**

```text
Float32.div : Float32 → Float32 → Float32
```

Divides 32-bit floating-point numbers according to IEEE 754. Typically used via the `/` operator.

In Lean, division by zero typically yields zero. For `Float32`, it instead yields either `Inf`, `-Inf`, or `NaN`.

This function has a logical model in terms of `Float32.Model`. It is compiled to the C division operator.

<a id="Float___pow"></a>

**opaque**

```text
Float.pow : Float → Float → Float
```

Raises one floating-point number to the power of another. Typically used via the `^` operator.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `pow`.

<a id="Float32___pow"></a>

**opaque**

```text
Float32.pow : Float32 → Float32 → Float32
```

Raises one floating-point number to the power of another. Typically used via the `^` operator.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `powf`.

<a id="Float___exp"></a>

**opaque**

```text
Float.exp (x : Float) : Float
```

Computes the exponential `e^x` of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `exp`.

<a id="Float32___exp"></a>

**opaque**

```text
Float32.exp : Float32 → Float32
```

Computes the exponential `e^x` of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `expf`.

<a id="Float___exp2"></a>

**opaque**

```text
Float.exp2 (x : Float) : Float
```

Computes the base-2 exponential `2^x` of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `exp2`.

<a id="Float32___exp2"></a>

**opaque**

```text
Float32.exp2 : Float32 → Float32
```

Computes the base-2 exponential `2^x` of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `exp2f`.

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--API-Reference--Arithmetic--Roots"></a>
##### 20.6.3.4.1. Roots

Computing the square root of a negative number yields `NaN`.

<a id="Float___sqrt"></a>

**def**

```text
Float.sqrt : Float → Float
```

Computes the square root of a floating-point number.

This function has a logical model in terms of `Float.Model`. It is implemented in compiled code by the C function `sqrt`.

<a id="Float32___sqrt"></a>

**def**

```text
Float32.sqrt : Float32 → Float32
```

Computes the square root of a floating-point number.

This function has a logical model in terms of `Float32.Model`. It is implemented in compiled code by the C function `sqrtf`.

<a id="Float___cbrt"></a>

**opaque**

```text
Float.cbrt : Float → Float
```

Computes the cube root of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `cbrt`.

<a id="Float32___cbrt"></a>

**opaque**

```text
Float32.cbrt : Float32 → Float32
```

Computes the cube root of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `cbrtf`.

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--API-Reference--Logarithms"></a>
#### 20.6.3.5. Logarithms

<a id="Float___log"></a>

**opaque**

```text
Float.log (x : Float) : Float
```

Computes the natural logarithm `ln x` of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `log`.

<a id="Float32___log"></a>

**opaque**

```text
Float32.log : Float32 → Float32
```

Computes the natural logarithm `ln x` of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `logf`.

<a id="Float___log10"></a>

**opaque**

```text
Float.log10 : Float → Float
```

Computes the base-10 logarithm of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `log10`.

<a id="Float32___log10"></a>

**opaque**

```text
Float32.log10 : Float32 → Float32
```

Computes the base-10 logarithm of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `log10f`.

<a id="Float___log2"></a>

**opaque**

```text
Float.log2 : Float → Float
```

Computes the base-2 logarithm of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `log2`.

<a id="Float32___log2"></a>

**opaque**

```text
Float32.log2 : Float32 → Float32
```

Computes the base-2 logarithm of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `log2f`.

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--API-Reference--Scaling"></a>
#### 20.6.3.6. Scaling

<a id="Float___scaleB"></a>

**opaque**

```text
Float.scaleB (x : Float) (i : Int) : Float
```

Efficiently computes `x * 2^i`.

This function does not reduce in the kernel.

<a id="Float32___scaleB"></a>

**opaque**

```text
Float32.scaleB (x : Float32) (i : Int) : Float32
```

Efficiently computes `x * 2^i`.

This function does not reduce in the kernel.

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--API-Reference--Rounding"></a>
#### 20.6.3.7. Rounding

<a id="Float___round"></a>

**opaque**

```text
Float.round : Float → Float
```

Rounds to the nearest integer, rounding away from zero at half-way points.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `round`.

<a id="Float32___round"></a>

**opaque**

```text
Float32.round : Float32 → Float32
```

Rounds to the nearest integer, rounding away from zero at half-way points.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `roundf`.

<a id="Float___floor"></a>

**opaque**

```text
Float.floor : Float → Float
```

Computes the floor of a floating-point number, which is the largest integer that's no larger than the given number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `floor`.

Examples:

- `Float.floor 1.5 = 1`
- `Float.floor (-1.5) = (-2)`

<a id="Float32___floor"></a>

**opaque**

```text
Float32.floor : Float32 → Float32
```

Computes the floor of a floating-point number, which is the largest integer that's no larger than the given number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `floorf`.

Examples:

- `Float32.floor 1.5 = 1`
- `Float32.floor (-1.5) = (-2)`

<a id="Float___ceil"></a>

**opaque**

```text
Float.ceil : Float → Float
```

Computes the ceiling of a floating-point number, which is the smallest integer that's no smaller than the given number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `ceil`.

Examples:

- `Float.ceil 1.5 = 2`
- `Float.ceil (-1.5) = (-1)`

<a id="Float32___ceil"></a>

**opaque**

```text
Float32.ceil : Float32 → Float32
```

Computes the ceiling of a floating-point number, which is the smallest integer that's no smaller than the given number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `ceilf`.

Examples:

- `Float32.ceil 1.5 = 2`
- `Float32.ceil (-1.5) = (-1)`

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--API-Reference--Trigonometry"></a>
#### 20.6.3.8. Trigonometry

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--API-Reference--Trigonometry--Sine"></a>
##### 20.6.3.8.1. Sine

<a id="Float___sin"></a>

**opaque**

```text
Float.sin : Float → Float
```

Computes the sine of a floating-point number in radians.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `sin`.

<a id="Float32___sin"></a>

**opaque**

```text
Float32.sin : Float32 → Float32
```

Computes the sine of a floating-point number in radians.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `sinf`.

<a id="Float___sinh"></a>

**opaque**

```text
Float.sinh : Float → Float
```

Computes the hyperbolic sine of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `sinh`.

<a id="Float32___sinh"></a>

**opaque**

```text
Float32.sinh : Float32 → Float32
```

Computes the hyperbolic sine of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `sinhf`.

<a id="Float___asin"></a>

**opaque**

```text
Float.asin : Float → Float
```

Computes the arc sine (inverse sine) of a floating-point number in radians.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `asin`.

<a id="Float32___asin"></a>

**opaque**

```text
Float32.asin : Float32 → Float32
```

Computes the arc sine (inverse sine) of a floating-point number in radians.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `asinf`.

<a id="Float___asinh"></a>

**opaque**

```text
Float.asinh : Float → Float
```

Computes the hyperbolic arc sine (inverse sine) of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `asinh`.

<a id="Float32___asinh"></a>

**opaque**

```text
Float32.asinh : Float32 → Float32
```

Computes the hyperbolic arc sine (inverse sine) of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `asinhf`.

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--API-Reference--Trigonometry--Cosine"></a>
##### 20.6.3.8.2. Cosine

<a id="Float___cos"></a>

**opaque**

```text
Float.cos : Float → Float
```

Computes the cosine of a floating-point number in radians.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `cos`.

<a id="Float32___cos"></a>

**opaque**

```text
Float32.cos : Float32 → Float32
```

Computes the cosine of a floating-point number in radians.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `cosf`.

<a id="Float___cosh"></a>

**opaque**

```text
Float.cosh : Float → Float
```

Computes the hyperbolic cosine of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `cosh`.

<a id="Float32___cosh"></a>

**opaque**

```text
Float32.cosh : Float32 → Float32
```

Computes the hyperbolic cosine of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `coshf`.

<a id="Float___acos"></a>

**opaque**

```text
Float.acos : Float → Float
```

Computes the arc cosine (inverse cosine) of a floating-point number in radians.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `acos`.

<a id="Float32___acos"></a>

**opaque**

```text
Float32.acos : Float32 → Float32
```

Computes the arc cosine (inverse cosine) of a floating-point number in radians.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `acosf`.

<a id="Float___acosh"></a>

**opaque**

```text
Float.acosh : Float → Float
```

Computes the hyperbolic arc cosine (inverse cosine) of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `acosh`.

<a id="Float32___acosh"></a>

**opaque**

```text
Float32.acosh : Float32 → Float32
```

Computes the hyperbolic arc cosine (inverse cosine) of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `acoshf`.

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--API-Reference--Trigonometry--Tangent"></a>
##### 20.6.3.8.3. Tangent

<a id="Float___tan"></a>

**opaque**

```text
Float.tan : Float → Float
```

Computes the tangent of a floating-point number in radians.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `tan`.

<a id="Float32___tan"></a>

**opaque**

```text
Float32.tan : Float32 → Float32
```

Computes the tangent of a floating-point number in radians.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `tanf`.

<a id="Float___tanh"></a>

**opaque**

```text
Float.tanh : Float → Float
```

Computes the hyperbolic tangent of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `tanh`.

<a id="Float32___tanh"></a>

**opaque**

```text
Float32.tanh : Float32 → Float32
```

Computes the hyperbolic tangent of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `tanhf`.

<a id="Float___atan"></a>

**opaque**

```text
Float.atan : Float → Float
```

Computes the arc tangent (inverse tangent) of a floating-point number in radians.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `atan`.

<a id="Float32___atan"></a>

**opaque**

```text
Float32.atan : Float32 → Float32
```

Computes the arc tangent (inverse tangent) of a floating-point number in radians.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `atanf`.

<a id="Float___atanh"></a>

**opaque**

```text
Float.atanh : Float → Float
```

Computes the hyperbolic arc tangent (inverse tangent) of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `atanh`.

<a id="Float32___atanh"></a>

**opaque**

```text
Float32.atanh : Float32 → Float32
```

Computes the hyperbolic arc tangent (inverse tangent) of a floating-point number.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `atanhf`.

<a id="Float___atan2"></a>

**opaque**

```text
Float.atan2 (y x : Float) : Float
```

Computes the arc tangent (inverse tangent) of `y / x` in radians, in the range `-π`–`π`. The signs of the arguments determine the quadrant of the result.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `atan2`.

<a id="Float32___atan2"></a>

**opaque**

```text
Float32.atan2 : Float32 → Float32 → Float32
```

Computes the arc tangent (inverse tangent) of `y / x` in radians, in the range `-π`–`π`. The signs of the arguments determine the quadrant of the result.

This function does not reduce in the kernel. It is implemented in compiled code by the C function `atan2f`.

<a id="The-Lean-Language-Reference--Basic-Types--Floating-Point-Numbers--API-Reference--Negation-and-Absolute-Value"></a>
#### 20.6.3.9. Negation and Absolute Value

<a id="Float___abs"></a>

**def**

```text
Float.abs : Float → Float
```

Computes the absolute value of a floating-point number.

This function has a logical model in terms of `Float.Model`. It is implemented in compiled code by the C function `fabs`.

<a id="Float32___abs"></a>

**def**

```text
Float32.abs : Float32 → Float32
```

Computes the absolute value of a floating-point number.

This function has a logical model in terms of `Float32.Model`. It is implemented in compiled code by the C function `fabsf`.

<a id="Float___neg"></a>

**def**

```text
Float.neg : Float → Float
```

Negates 64-bit floating-point numbers according to IEEE 754. Typically used via the `-` prefix operator.

This function has a logical model in terms of `Float.Model`. It is compiled to the C negation operator.

<a id="Float32___neg"></a>

**def**

```text
Float32.neg : Float32 → Float32
```

Negates 32-bit floating-point numbers according to IEEE 754. Typically used via the `-` prefix operator.

This function has a logical model in terms of `Float32.Model`. It is compiled to the C negation operator.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Tactic `rfl` failed: The left-hand side
  Float.sin 0.0
is not definitionally equal to the right-hand side
  0.0

⊢ Float.sin 0.0 = 0.0
```


### Display 2


```text
'Float.sin_zero_eq_zero' depends on axioms: [propext,
 Classical.choice,
 Quot.sound,
 Float.sin_zero_eq_zero._native.native_decide.ax_1]
```


### Display 3


```text
false
```


### Display 4


```text
(true, false)
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
⊢ 0.0 = 0.0
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
⊢ 0.0 = 0.0 + 0.0
```


### Display 4


```text
⊢ Float.sin 0.0 = 0.0
```


### Display 5


```text
⊢ (sin 0.0 == 0.0) = true
```

