<a id="Int"></a>

# ProofScript — 20.2. Integers

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Integers/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Integers/index.html). Source Git blob: `2aa9b92e254f17ea12c30d737a943a040d658459`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.2. Integers

The integers are whole numbers, both positive and negative. Integers are arbitrary-precision, limited only by the capability of the hardware on which Lean is running; for fixed-width integers that are used in programming and computer science, please see the [section on fixed-precision integers](https://lean-lang.org/doc/reference/latest/Basic-Types/Fixed-Precision-Integers/#fixed-ints).

Integers are specially supported by Lean's implementation. The logical model of the integers is based on the natural numbers: each integer is modeled as either a natural number or the negative successor of a natural number. Operations on the integers are specified using this model, which is used in the kernel and in interpreted code. In these contexts, integer code inherits the performance benefits of the natural numbers' special support. In compiled code, integers are represented as efficient arbitrary-precision integers, and sufficiently small numbers are stored as values that don't require indirection through a pointer. Arithmetic operations are implemented by primitives that take advantage of the efficient representations.

<a id="int-model"></a>
### 20.2.1. Logical Model

Integers are represented either as a natural number or as the negation of the successor of a natural number.

<a id="Int___ofNat"></a>

**inductive type**

```text
Int : Type
```

The integers.

This type is special-cased by the compiler and overridden with an efficient implementation. The runtime has a special representation for `Int` that stores “small” signed numbers directly, while larger numbers use a fast arbitrary-precision arithmetic library (usually [GMP](https://gmplib.org/)). A “small number” is an integer that can be encoded with one fewer bits than the platform's pointer size (i.e. 63 bits on 64-bit architectures and 31 bits on 32-bit architectures).

**Constructors**

```text
Int.ofNat : Nat → Int
```

A natural number is an integer.

This constructor covers the non-negative integers (from `0` to `∞`).

```text
Int.negSucc : Nat → Int
```

The negation of the successor of a natural number is an integer.

This constructor covers the negative integers (from `-1` to `-∞`).

This representation of the integers has a number of useful properties. It is relatively simple to use and to understand. Unlike a pair of a sign and a `Nat`, there is a unique representation for $0$, which simplifies reasoning about equality. Integers can also be represented as a pair of natural numbers in which one is subtracted from the other, but this requires a [quotient type](https://lean-lang.org/doc/reference/latest/The-Type-System/Quotients/#quotients) to be well-behaved, and quotient types can be laborious to work with due to the need to prove that functions respect the equivalence relation.

<a id="int-runtime"></a>
### 20.2.2. Run-Time Representation

Like [natural numbers](https://lean-lang.org/doc/reference/latest/Basic-Types/Natural-Numbers/#nat-runtime), sufficiently-small integers are represented without pointers: the lowest-order bit in an object pointer is used to indicate that the value is not, in fact, a pointer. If an integer is too large to fit in the remaining bits, it is instead allocated as an ordinary Lean object that consists of an object header and an arbitrary-precision integer.

<a id="int-syntax"></a>
### 20.2.3. Syntax

The `OfNat Int` instance allows numerals to be used as literals, both in expression and in pattern contexts. `(OfNat.ofNat n : Int)` reduces to the constructor application `Int.ofNat n`. The `Neg Int` instance allows negation to be used as well.

On top of these instances, there is special syntax for the constructor `Int.negSucc` that is available when the `Int` namespace is opened. The notation `-[ n +1]` is suggestive of $-(n + 1)$, which is the meaning of `Int.negSucc n`.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Negative Successor**

`-[ n +1]` is notation for `Int.negSucc n`.

<a id="Int____FLQQ_term-_LSQ_____1_RSQ__FLQQ_"></a>

```ebnf
term ::= ...
    | -[ term +1]
```

<a id="The-Lean-Language-Reference--Basic-Types--Integers--API-Reference"></a>
### 20.2.4. API Reference

<a id="The-Lean-Language-Reference--Basic-Types--Integers--API-Reference--Properties"></a>
#### 20.2.4.1. Properties

<a id="Int___sign"></a>

**def**

```text
Int.sign : Int → Int
```

Returns the “sign” of the integer as another integer:

- `1` for positive numbers,
- `-1` for negative numbers, and
- `0` for `0`.

Examples:

- `Int.sign 34 = 1`
- `Int.sign 2 = 1`
- `Int.sign 0 = 0`
- `Int.sign -1 = -1`
- `Int.sign -362 = -1`

<a id="The-Lean-Language-Reference--Basic-Types--Integers--API-Reference--Conversions"></a>
#### 20.2.4.2. Conversions

<a id="Int___natAbs"></a>

**def**

```text
Int.natAbs (m : Int) : Nat
```

The absolute value of an integer is its distance from `0`.

This function is overridden by the compiler with an efficient implementation. This definition is the logical model.

Examples:

- `(7 : Int).natAbs = 7`
- `(0 : Int).natAbs = 0`
- `(-11 : Int).natAbs = 11`

<a id="Int___toNat"></a>

**def**

```text
Int.toNat : Int → Nat
```

Converts an integer into a natural number. Negative numbers are converted to `0`.

Examples:

- `(7 : Int).toNat = 7`
- `(0 : Int).toNat = 0`
- `(-7 : Int).toNat = 0`

<a id="Int___toNat___"></a>

**def**

```text
Int.toNat? : Int → Option Nat
```

Converts an integer into a natural number. Returns `none` for negative numbers.

Examples:

- `(7 : Int).toNat? = some 7`
- `(0 : Int).toNat? = some 0`
- `(-7 : Int).toNat? = none`

<a id="Int___toISize"></a>

**def**

```text
Int.toISize (i : Int) : ISize
```

Converts an arbitrary-precision integer to a word-sized signed integer, wrapping around on over- or underflow.

This function is overridden at runtime with an efficient implementation.

<a id="Int___toInt8"></a>

**def**

```text
Int.toInt8 (i : Int) : Int8
```

Converts an arbitrary-precision integer to an 8-bit integer, wrapping on overflow or underflow.

Examples:

- `Int.toInt8 48 = 48`
- `Int.toInt8 (-115) = -115`
- `Int.toInt8 (-129) = 127`
- `Int.toInt8 (128) = -128`

<a id="Int___toInt16"></a>

**def**

```text
Int.toInt16 (i : Int) : Int16
```

Converts an arbitrary-precision integer to a 16-bit integer, wrapping on overflow or underflow.

Examples:

- `Int.toInt16 48 = 48`
- `Int.toInt16 (-129) = -129`
- `Int.toInt16 (128) = 128`
- `Int.toInt16 70000 = 4464`
- `Int.toInt16 (-40000) = 25536`

<a id="Int___toInt32"></a>

**def**

```text
Int.toInt32 (i : Int) : Int32
```

Converts an arbitrary-precision integer to a 32-bit integer, wrapping on overflow or underflow.

Examples:

- `Int.toInt32 48 = 48`
- `Int.toInt32 (-129) = -129`
- `Int.toInt32 70000 = 70000`
- `Int.toInt32 (-40000) = -40000`
- `Int.toInt32 2147483648 = -2147483648`
- `Int.toInt32 (-2147483649) = 2147483647`

<a id="Int___toInt64"></a>

**def**

```text
Int.toInt64 (i : Int) : Int64
```

Converts an arbitrary-precision integer to a 64-bit integer, wrapping on overflow or underflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Int.toInt64 48 = 48`
- `Int.toInt64 (-40_000) = -40_000`
- `Int.toInt64 2_147_483_648 = 2_147_483_648`
- `Int.toInt64 (-2_147_483_649) = -2_147_483_649`
- `Int.toInt64 9_223_372_036_854_775_808 = -9_223_372_036_854_775_808`
- `Int.toInt64 (-9_223_372_036_854_775_809) = 9_223_372_036_854_775_807`

<a id="Int___repr"></a>

**def**

```text
Int.repr : Int → String
```

Returns the decimal string representation of an integer.

<a id="The-Lean-Language-Reference--Basic-Types--Integers--API-Reference--Arithmetic"></a>
#### 20.2.4.3. Arithmetic

Typically, arithmetic operations on integers are accessed using Lean's overloaded arithmetic notation. In particular, the instances of `Add Int`, `Neg Int`, `Sub Int`, and `Mul Int` allow ordinary infix operators to be used. [Division](https://lean-lang.org/doc/reference/latest/Basic-Types/Integers/#int-div) is somewhat more intricate, because there are multiple sensible notions of division on integers.

<a id="Int___add"></a>

**def**

```text
Int.add (m n : Int) : Int
```

Addition of integers, usually accessed via the `+` operator.

This function is overridden by the compiler with an efficient implementation. This definition is the logical model.

Examples:

- `(7 : Int) + (6 : Int) = 13`
- `(6 : Int) + (-6 : Int) = 0`

<a id="Int___sub"></a>

**def**

```text
Int.sub (m n : Int) : Int
```

Subtraction of integers, usually accessed via the `-` operator.

This function is overridden by the compiler with an efficient implementation. This definition is the logical model.

Examples:

- `(63 : Int) - (6 : Int) = 57`
- `(7 : Int) - (0 : Int) = 7`
- `(0 : Int) - (7 : Int) = -7`

<a id="Int___subNatNat"></a>

**def**

```text
Int.subNatNat (m n : Nat) : Int
```

Non-truncating subtraction of two natural numbers.

Examples:

- `Int.subNatNat 5 2 = 3`
- `Int.subNatNat 2 5 = -3`
- `Int.subNatNat 0 13 = -13`

<a id="Int___neg"></a>

**def**

```text
Int.neg (n : Int) : Int
```

Negation of integers, usually accessed via the `-` prefix operator.

This function is overridden by the compiler with an efficient implementation. This definition is the logical model.

Examples:

- `-(6 : Int) = -6`
- `-(-6 : Int) = 6`
- `(12 : Int).neg = -12`

<a id="Int___negOfNat"></a>

**def**

```text
Int.negOfNat : Nat → Int
```

Negation of natural numbers.

Examples:

- `Int.negOfNat 6 = -6`
- `Int.negOfNat 0 = 0`

<a id="Int___mul"></a>

**def**

```text
Int.mul (m n : Int) : Int
```

Multiplication of integers, usually accessed via the `*` operator.

This function is overridden by the compiler with an efficient implementation. This definition is the logical model.

Examples:

- `(63 : Int) * (6 : Int) = 378`
- `(6 : Int) * (-6 : Int) = -36`
- `(7 : Int) * (0 : Int) = 0`

<a id="Int___pow"></a>

**def**

```text
Int.pow : Int → Nat → Int
```

Power of an integer to a natural number, usually accessed via the `^` operator.

Examples:

- `(2 : Int) ^ 4 = 16`
- `(10 : Int) ^ 0 = 1`
- `(0 : Int) ^ 10 = 0`
- `(-7 : Int) ^ 3 = -343`

<a id="Int___gcd"></a>

**def**

```text
Int.gcd (m n : Int) : Nat
```

Computes the greatest common divisor of two integers as a natural number. The GCD of two integers is the largest natural number that evenly divides both. However, the GCD of a number and `0` is the number's absolute value.

This implementation uses `Nat.gcd`, which is overridden in both the kernel and the compiler to efficiently evaluate using arbitrary-precision arithmetic.

Examples:

- `Int.gcd 10 15 = 5`
- `Int.gcd 10 (-15) = 5`
- `Int.gcd (-6) (-9) = 3`
- `Int.gcd 0 5 = 5`
- `Int.gcd (-7) 0 = 7`

<a id="Int___lcm"></a>

**def**

```text
Int.lcm (m n : Int) : Nat
```

Computes the least common multiple of two integers as a natural number. The LCM of two integers is the smallest natural number that's evenly divisible by the absolute values of both.

Examples:

- `Int.lcm 9 6 = 18`
- `Int.lcm 9 (-6) = 18`
- `Int.lcm 9 3 = 9`
- `Int.lcm 9 (-3) = 9`
- `Int.lcm 0 3 = 0`
- `Int.lcm (-3) 0 = 0`

<a id="int-div"></a>
##### 20.2.4.3.1. Division

The `Div Int` and `Mod Int` instances implement Euclidean division, described in the reference for `Int.ediv`. This is not, however, the only sensible convention for rounding and remainders in division. Four pairs of division and modulus functions are available, implementing various conventions.

<a id="Division-by-0"></a>
Division by 0 

In all integer division conventions, division by `0` is defined to be `0`:

```proofscript
#eval Int.ediv 5 0
#eval Int.ediv 0 0
#eval Int.ediv (-5) 0
#eval Int.bdiv 5 0
#eval Int.bdiv 0 0
#eval Int.bdiv (-5) 0
#eval Int.fdiv 5 0
#eval Int.fdiv 0 0
#eval Int.fdiv (-5) 0
#eval Int.tdiv 5 0
#eval Int.tdiv 0 0
#eval Int.tdiv (-5) 0
```

All evaluate to 0.

```lean
0
```

<a id="Int___ediv"></a>

**def**

```text
Int.ediv : Int → Int → Int
```

Integer division that uses the E-rounding convention. Usually accessed via the `/` operator. Division by zero is defined to be zero, rather than an error.

In the E-rounding convention (Euclidean division), `Int.emod x y` satisfies `0 ≤ Int.emod x y < Int.natAbs y` for `y ≠ 0` and `Int.ediv` is the unique function satisfying `Int.emod x y + (Int.ediv x y) * y = x` for `y ≠ 0`.

This means that `Int.ediv x y` is `⌊x / y⌋` when `y > 0` and `⌈x / y⌉` when `y < 0`.

This function is overridden by the compiler with an efficient implementation. This definition is the logical model.

Examples:

- `(7 : Int) / (0 : Int) = 0`
- `(0 : Int) / (7 : Int) = 0`
- `(12 : Int) / (6 : Int) = 2`
- `(12 : Int) / (-6 : Int) = -2`
- `(-12 : Int) / (6 : Int) = -2`
- `(-12 : Int) / (-6 : Int) = 2`
- `(12 : Int) / (7 : Int) = 1`
- `(12 : Int) / (-7 : Int) = -1`
- `(-12 : Int) / (7 : Int) = -2`
- `(-12 : Int) / (-7 : Int) = 2`

<a id="Int___emod"></a>

**def**

```text
Int.emod : Int → Int → Int
```

Integer modulus that uses the E-rounding convention. Usually accessed via the `%` operator.

In the E-rounding convention (Euclidean division), `Int.emod x y` satisfies `0 ≤ Int.emod x y < Int.natAbs y` for `y ≠ 0` and `Int.ediv` is the unique function satisfying `Int.emod x y + (Int.ediv x y) * y = x` for `y ≠ 0`.

This function is overridden by the compiler with an efficient implementation. This definition is the logical model.

Examples:

- `(7 : Int) % (0 : Int) = 7`
- `(0 : Int) % (7 : Int) = 0`
- `(12 : Int) % (6 : Int) = 0`
- `(12 : Int) % (-6 : Int) = 0`
- `(-12 : Int) % (6 : Int) = 0`
- `(-12 : Int) % (-6 : Int) = 0`
- `(12 : Int) % (7 : Int) = 5`
- `(12 : Int) % (-7 : Int) = 5`
- `(-12 : Int) % (7 : Int) = 2`
- `(-12 : Int) % (-7 : Int) = 2`

<a id="Int___tdiv"></a>

**def**

```text
Int.tdiv : Int → Int → Int
```

Integer division using the T-rounding convention.

In [the T-rounding convention](https://dl.acm.org/doi/pdf/10.1145/128861.128862) (division with truncation), all rounding is towards zero. Division by 0 is defined to be 0. In this convention, `Int.tmod a b + b * (Int.tdiv a b) = a`.

This function is overridden by the compiler with an efficient implementation. This definition is the logical model.

Examples:

- `(7 : Int).tdiv (0 : Int) = 0`
- `(0 : Int).tdiv (7 : Int) = 0`
- `(12 : Int).tdiv (6 : Int) = 2`
- `(12 : Int).tdiv (-6 : Int) = -2`
- `(-12 : Int).tdiv (6 : Int) = -2`
- `(-12 : Int).tdiv (-6 : Int) = 2`
- `(12 : Int).tdiv (7 : Int) = 1`
- `(12 : Int).tdiv (-7 : Int) = -1`
- `(-12 : Int).tdiv (7 : Int) = -1`
- `(-12 : Int).tdiv (-7 : Int) = 1`

<a id="Int___tmod"></a>

**def**

```text
Int.tmod : Int → Int → Int
```

Integer modulo using the T-rounding convention.

In [the T-rounding convention](https://dl.acm.org/doi/pdf/10.1145/128861.128862) (division with truncation), all rounding is towards zero. Division by 0 is defined to be 0 and `Int.tmod a 0 = a`.

In this convention, `Int.tmod a b + b * (Int.tdiv a b) = a`. Additionally, `Int.natAbs (Int.tmod a b) = Int.natAbs a % Int.natAbs b`, and when `b` does not divide `a`, `Int.tmod a b` has the same sign as `a`.

This function is overridden by the compiler with an efficient implementation. This definition is the logical model.

Examples:

- `(7 : Int).tmod (0 : Int) = 7`
- `(0 : Int).tmod (7 : Int) = 0`
- `(12 : Int).tmod (6 : Int) = 0`
- `(12 : Int).tmod (-6 : Int) = 0`
- `(-12 : Int).tmod (6 : Int) = 0`
- `(-12 : Int).tmod (-6 : Int) = 0`
- `(12 : Int).tmod (7 : Int) = 5`
- `(12 : Int).tmod (-7 : Int) = 5`
- `(-12 : Int).tmod (7 : Int) = -5`
- `(-12 : Int).tmod (-7 : Int) = -5`

<a id="Int___bdiv"></a>

**def**

```text
Int.bdiv (x : Int) (m : Nat) : Int
```

Balanced division.

This returns the unique integer so that `b * (Int.bdiv a b) + Int.bmod a b = a`.

Examples:

- `(7 : Int).bdiv 0 = 0`
- `(0 : Int).bdiv 7 = 0`
- `(12 : Int).bdiv 6 = 2`
- `(12 : Int).bdiv 7 = 2`
- `(12 : Int).bdiv 8 = 2`
- `(12 : Int).bdiv 9 = 1`
- `(-12 : Int).bdiv 6 = -2`
- `(-12 : Int).bdiv 7 = -2`
- `(-12 : Int).bdiv 8 = -1`
- `(-12 : Int).bdiv 9 = -1`

<a id="Int___bmod"></a>

**def**

```text
Int.bmod (x : Int) (m : Nat) : Int
```

Balanced modulus.

This version of integer modulus uses the balanced rounding convention, which guarantees that `-m / 2 ≤ Int.bmod x m < m/2` for `m ≠ 0` and `Int.bmod x m` is congruent to `x` modulo `m`.

If `m = 0`, then `Int.bmod x m = x`.

Examples:

- `(7 : Int).bmod 0 = 7`
- `(0 : Int).bmod 7 = 0`
- `(12 : Int).bmod 6 = 0`
- `(12 : Int).bmod 7 = -2`
- `(12 : Int).bmod 8 = -4`
- `(12 : Int).bmod 9 = 3`
- `(-12 : Int).bmod 6 = 0`
- `(-12 : Int).bmod 7 = 2`
- `(-12 : Int).bmod 8 = -4`
- `(-12 : Int).bmod 9 = -3`

<a id="Int___fdiv"></a>

**def**

```text
Int.fdiv : Int → Int → Int
```

Integer division using the F-rounding convention.

In the F-rounding convention (flooring division), `Int.fdiv x y` satisfies `Int.fdiv x y = ⌊x / y⌋` and `Int.fmod` is the unique function satisfying `Int.fmod x y + (Int.fdiv x y) * y = x`.

Examples:

- `(7 : Int).fdiv (0 : Int) = 0`
- `(0 : Int).fdiv (7 : Int) = 0`
- `(12 : Int).fdiv (6 : Int) = 2`
- `(12 : Int).fdiv (-6 : Int) = -2`
- `(-12 : Int).fdiv (6 : Int) = -2`
- `(-12 : Int).fdiv (-6 : Int) = 2`
- `(12 : Int).fdiv (7 : Int) = 1`
- `(12 : Int).fdiv (-7 : Int) = -2`
- `(-12 : Int).fdiv (7 : Int) = -2`
- `(-12 : Int).fdiv (-7 : Int) = 1`

<a id="Int___fmod"></a>

**def**

```text
Int.fmod : Int → Int → Int
```

Integer modulus using the F-rounding convention.

In the F-rounding convention (flooring division), `Int.fdiv x y` satisfies `Int.fdiv x y = ⌊x / y⌋` and `Int.fmod` is the unique function satisfying `Int.fmod x y + (Int.fdiv x y) * y = x`.

Examples:

- `(7 : Int).fmod (0 : Int) = 7`
- `(0 : Int).fmod (7 : Int) = 0`
- `(12 : Int).fmod (6 : Int) = 0`
- `(12 : Int).fmod (-6 : Int) = 0`
- `(-12 : Int).fmod (6 : Int) = 0`
- `(-12 : Int).fmod (-6 : Int) = 0`
- `(12 : Int).fmod (7 : Int) = 5`
- `(12 : Int).fmod (-7 : Int) = -2`
- `(-12 : Int).fmod (7 : Int) = 2`
- `(-12 : Int).fmod (-7 : Int) = -5`

<a id="The-Lean-Language-Reference--Basic-Types--Integers--API-Reference--Bitwise-Operators"></a>
#### 20.2.4.4. Bitwise Operators

Bitwise operators on `Int` can be understood as bitwise operators on an infinite stream of bits that are the twos-complement representation of integers.

<a id="Int___not"></a>

**def**

```text
Int.not : Int → Int
```

Bitwise not, usually accessed via the `~~~` prefix operator.

Interprets the integer as an infinite sequence of bits in two's complement and complements each bit.

Examples:

- `~~~(0 : Int) = -1`
- `~~~(1 : Int) = -2`
- `~~~(-1 : Int) = 0`

<a id="Int___shiftRight"></a>

**def**

```text
Int.shiftRight : Int → Nat → Int
```

Bitwise right shift, usually accessed via the `>>>` operator.

Interprets the integer as an infinite sequence of bits in two's complement and shifts the value to the right.

Examples:

- `( 0b0111 : Int) >>> 1 =  0b0011`
- `( 0b1000 : Int) >>> 1 =  0b0100`
- `(-0b1000 : Int) >>> 1 = -0b0100`
- `(-0b0111 : Int) >>> 1 = -0b0100`

<a id="The-Lean-Language-Reference--Basic-Types--Integers--API-Reference--Comparisons"></a>
#### 20.2.4.5. Comparisons

Equality and inequality tests on `Int` are typically performed using the decidability of its equality and ordering relations or using the `BEq Int` and `Ord Int` instances.

<a id="Int___le"></a>

**def**

```text
Int.le (a b : Int) : Prop
```

Non-strict inequality of integers, usually accessed via the `≤` operator.

`a ≤ b` is defined as `b - a ≥ 0`, using `Int.NonNeg`.

<a id="Int___lt"></a>

**def**

```text
Int.lt (a b : Int) : Prop
```

Strict inequality of integers, usually accessed via the `<` operator.

`a < b` when `a + 1 ≤ b`.

<a id="Int___decEq"></a>

**def**

```text
Int.decEq (a b : Int) : Decidable (a = b)
```

Decides whether two integers are equal. Usually accessed via the `DecidableEq Int` instance.

This function is overridden by the compiler with an efficient implementation. This definition is the logical model.

Examples:

- `show (7 : Int) = (3 : Int) + (4 : Int) by decide`
- `if (6 : Int) = (3 : Int) * (2 : Int) then "yes" else "no" = "yes"`
- `(¬ (6 : Int) = (3 : Int)) = true`

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
-[n+1] is suggestive notation for negSucc n, which is the second constructor of
Int for making strictly negative numbers by mapping n : Nat to -(n + 1).
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
0
```

