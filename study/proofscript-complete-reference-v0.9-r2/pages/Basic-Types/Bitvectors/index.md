<a id="BitVec"></a>

# ProofScript — 20.5. Bitvectors

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Bitvectors/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Bitvectors/index.html). Source Git blob: `2ec6c093fdd13994fb3e2e8aeeb7683d8639fd03`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

> **Stable-pin correction:** this inherited page mentions `Lean.ofReduceBool`. These pre-final kernel mechanisms are not part of the selected Lean 4.34.0 stable semantics. Their historical descriptions remain for source coverage, not as authorization to implement those reductions. Native proof tactics require separate assumption/evidence accounting.

---

## 20.5. Bitvectors

Bitvectors are fixed-width sequences of binary digits. They are frequently used in software verification, because they closely model efficient data structures and operations that are similar to hardware. A bitvector can be understood from two perspectives: as a sequence of bits, or as a number encoded by a sequence of bits. When a bitvector represents a number, it can do so as either a signed or an unsigned number. Signed numbers are represented in two's complement form.

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--Logical-Model"></a>
### 20.5.1. Logical Model

Bitvectors are represented as a wrapper around a `Fin` with a suitable bound. Because `Fin` itself is a wrapper around a `Nat`, bitvectors are able to use the kernel's special support for efficient computation with natural numbers.

<a id="BitVec___ofFin"></a>

**structure**

```text
BitVec (w : Nat) : Type
```

A bitvector of the specified width.

This is represented as the underlying `Nat` number in both the runtime and the kernel, inheriting all the special support for `Nat`.

**Constructor**

```text
BitVec.ofFin
```

Construct a `BitVec w` from a number less than `2^w`. O(1), because we use `Fin` as the internal representation of a bitvector.

**Fields**

```text
toFin : Fin (2 ^ w)
```

Interpret a bitvector as a number less than `2^w`. O(1), because we use `Fin` as the internal representation of a bitvector.

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--Runtime-Representation"></a>
### 20.5.2. Runtime Representation

Bitvectors are represented as a `Fin` with the corresponding range. Because `BitVec` is a [trivial wrapper](../../The-Type-System/Inductive-Types/index.md#inductive-types-trivial-wrappers) around `Fin` and `Fin` is a trivial wrapper around `Nat`, bitvectors use the same runtime representation as `Nat` in compiled code.

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--Syntax"></a>
### 20.5.3. Syntax

There is an `OfNat (BitVec w) n` instance for all widths `w` and natural numbers `n`. Natural number literals, including those that use hexadecimal or binary notation, may be used to represent bitvectors in contexts where the expected type is known. When the expected type is not known, a dedicated syntax allows the width of the bitvector to be specified along with its value.

<a id="Numeric-Literals-for-Bitvectors"></a>
Numeric Literals for Bitvectors 

The following literals are all equivalent:

```proofscript
example : BitVec 8 := 0xff
example : BitVec 8 := 255
example : BitVec 8 := 0b1111_1111
```

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Fixed-Width Bitvector Literals**

<a id="BitVec____FLQQ_term________FLQQ_"></a>

```ebnf
term ::= ...
    | num#term
```

This notation pairs a numeric literal with a term that denotes its width. Spaces are forbidden around the `#`. Literals that overflow the width of the bitvector are truncated.

<a id="Fixed-Width-Bitvector-Literals"></a>
Fixed-Width Bitvector Literals 

Bitvectors may be represented by natural number literals, so `(5 : BitVec 8)` is a valid bitvector. Additionally, a width may be specified directly in the literal:

```proofscript
5#8
```

Spaces are not allowed on either side of the `#`:

```lean
5 #8
```

```lean
<example>:1:2-1:3: expected end of input
```

```lean
5# 8
```

```lean
<example>:1:3-1:4: expected no space before
```

A numeric literal is required to the left of the `#`:

```lean
(3 + 2)#8
```

```lean
<example>:1:7-1:8: expected end of input
```

However, a term is allowed to the right of the `#`:

```proofscript
5#(4 + 4)
```

If the literal is too large to fit in the specified number of bits, then it is truncated:

```proofscript
#eval 7#2
```

```lean
3#2
```

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Bounded Bitvector Literals**

<a id="BitVec____FLQQ_term___________FLQQ_"></a>

```ebnf
term ::= ...
    | num#'term
```

This notation is available only when the `BitVec` namespace has been opened. Rather than an explicit width, it expects a proof that the literal value is representable by a bitvector of the corresponding width.

<a id="Bounded-Bitvector-Literals"></a>
Bounded Bitvector Literals 

The bounded bitvector literal notation ensures that literals do not overflow the specified number of bits. The notation is only available when the `BitVec` namespace has been opened.

```proofscript
open BitVec
```

Literals that are in bounds require a proof to that effect:

```proofscript
example : BitVec 8 := 1#'(by decide)
```

Literals that are not in bounds are not allowed:

```proofscript
example : BitVec 8 := 256#'(by decide)
```

```lean
Tactic `decide` proved that the proposition
  256 < 2 ^ 8
is false
```

<a id="BitVec-automation"></a>
### 20.5.4. Automation

In addition to the full suite of automation and tools provided by Lean for every type, the `bv_decide` tactic can solve many bitvector-related problems. This tactic invokes an external automated theorem prover (`cadical`) and reconstructs the proof that it provides in Lean's own logic. The resulting proofs rely only on the axiom `Lean.ofReduceBool`; the external prover is not part of the trusted code base.

<a id="Popcount"></a>
Popcount 

The function `popcount` returns the number of set bits in a bitvector. It can be implemented as a 32-iteration loop that tests each bit, incrementing a counter if the bit is set:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="popcount_spec-_LPAR_in-Popcount_RPAR_"></a>


```proofscript
function popcount_spec (x : BitVec 32) : BitVec 32 :=
  (32 : Nat).fold (init := 0) fun i _ pop =>
    pop + ((x >>> i) &&& 1)
```

An alternative implementation of `popcount` is described in *Hacker's Delight, Second Edition*, by Henry S. Warren, Jr. in Figure 5-2 on p. 82. It uses low-level bitwise operations to compute the same value with far fewer operations:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="popcount-_LPAR_in-Popcount_RPAR_"></a>


```proofscript
function popcount (x : BitVec 32) : BitVec 32 :=
  let x := x - ((x >>> 1) &&& 0x55555555)
  let x := (x &&& 0x33333333) + ((x >>> 2) &&& 0x33333333)
  let x := (x + (x >>> 4)) &&& 0x0F0F0F0F
  let x := x + (x >>> 8)
  let x := x + (x >>> 16)
  let x := x &&& 0x0000003F
  x
```

These two implementations can be proven equivalent using `bv_decide`:
<a id="popcount_correct-_LPAR_in-Popcount_RPAR_"></a>


```proofscript
theorem popcount_correct : popcount = popcount_spec := by
  funext x
  simp [popcount, popcount_spec]
  bv_decide
```

<a id="BitVec-api"></a>
### 20.5.5. API Reference

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--API-Reference--Bounds"></a>
#### 20.5.5.1. Bounds

<a id="BitVec___intMax"></a>

**def**

```text
BitVec.intMax (w : Nat) : BitVec w
```

The bitvector of width `w` that has the largest value when interpreted as an integer.

<a id="BitVec___intMin"></a>

**def**

```text
BitVec.intMin (w : Nat) : BitVec w
```

The bitvector of width `w` that has the smallest value when interpreted as an integer.

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--API-Reference--Construction"></a>
#### 20.5.5.2. Construction

<a id="BitVec___fill"></a>

**def**

```text
BitVec.fill (w : Nat) (b : Bool) : BitVec w
```

Fills a bitvector with `w` copies of the bit `b`.

<a id="BitVec___zero"></a>

**def**

```text
BitVec.zero (n : Nat) : BitVec n
```

Returns a bitvector of size `n` where all bits are `0`.

<a id="BitVec___allOnes"></a>

**def**

```text
BitVec.allOnes (n : Nat) : BitVec n
```

Returns a bitvector of size `n` where all bits are `1`.

<a id="BitVec___twoPow"></a>

**def**

```text
BitVec.twoPow (w i : Nat) : BitVec w
```

`twoPow w i` is the bitvector `2^i` if `i < w`, and `0` otherwise. In other words, it is 2 to the power `i`.

From the bitwise point of view, it has the `i`th bit as `1` and all other bits as `0`.

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--API-Reference--Conversion"></a>
#### 20.5.5.3. Conversion

<a id="BitVec___toHex"></a>

**def**

```text
BitVec.toHex {n : Nat} (x : BitVec n) : String
```

Converts a bitvector into a fixed-width hexadecimal number with enough digits to represent it.

If `n` is `0`, then one digit is returned. Otherwise, `⌊(n + 3) / 4⌋` digits are returned.

<a id="BitVec___toInt"></a>

**def**

```text
BitVec.toInt {n : Nat} (x : BitVec n) : Int
```

Interprets the bitvector as an integer stored in two's complement form.

<a id="BitVec___toNat"></a>

**def**

```text
BitVec.toNat {w : Nat} (x : BitVec w) : Nat
```

Return the underlying `Nat` that represents a bitvector.

This is O(1) because `BitVec` is a (zero-cost) wrapper around a `Nat`.

<a id="BitVec___ofBool"></a>

**def**

```text
BitVec.ofBool (b : Bool) : BitVec 1
```

Turns a `Bool` into a bitvector of length `1`.

<a id="BitVec___ofBoolListBE"></a>

**def**

```text
BitVec.ofBoolListBE (bs : List Bool) : BitVec bs.length
```

Converts a list of `Bool`s into a big-endian `BitVec`.

<a id="BitVec___ofBoolListLE"></a>

**def**

```text
BitVec.ofBoolListLE (bs : List Bool) : BitVec bs.length
```

Converts a list of `Bool`s into a little-endian `BitVec`.

<a id="BitVec___ofInt"></a>

**def**

```text
BitVec.ofInt (n : Nat) (i : Int) : BitVec n
```

Converts an integer to its two's complement representation as a bitvector of the given width `n`, over- and underflowing as needed.

The underlying `Nat` is `(2^n + (i mod 2^n)) mod 2^n`. Converting the bitvector back to an `Int` with `BitVec.toInt` results in the value `i.bmod (2^n)`.

<a id="BitVec___ofNat"></a>

**def**

```text
BitVec.ofNat (n i : Nat) : BitVec n
```

The bitvector with value `i mod 2^n`.

Conventions for notations in identifiers:

- The recommended spelling of `0#n` in identifiers is `zero` (not `ofNat_zero`).
- The recommended spelling of `1#n` in identifiers is `one` (not `ofNat_one`).

<a id="BitVec___ofNatLT"></a>

**def**

```text
BitVec.ofNatLT {w : Nat} (i : Nat) (p : i < 2 ^ w) : BitVec w
```

The `BitVec` with value `i`, given a proof that `i < 2^w`.

<a id="BitVec___cast"></a>

**def**

```text
BitVec.cast {n m : Nat} (eq : n = m) (x : BitVec n) : BitVec m
```

If two natural numbers `n` and `m` are equal, then a bitvector of width `n` is also a bitvector of width `m`.

Using `x.cast eq` should be preferred over `eq ▸ x` because there are special-purpose `simp` lemmas that can more consistently simplify `BitVec.cast` away.

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--API-Reference--Comparisons"></a>
#### 20.5.5.4. Comparisons

<a id="BitVec___ule"></a>

**def**

```text
BitVec.ule {n : Nat} (x y : BitVec n) : Bool
```

Unsigned less-than-or-equal-to for bitvectors.

SMT-LIB name: `bvule`.

<a id="BitVec___sle"></a>

**def**

```text
BitVec.sle {n : Nat} (x y : BitVec n) : Bool
```

Signed less-than-or-equal-to for bitvectors.

SMT-LIB name: `bvsle`.

<a id="BitVec___ult"></a>

**def**

```text
BitVec.ult {n : Nat} (x y : BitVec n) : Bool
```

Unsigned less-than for bitvectors.

SMT-LIB name: `bvult`.

<a id="BitVec___slt"></a>

**def**

```text
BitVec.slt {n : Nat} (x y : BitVec n) : Bool
```

Signed less-than for bitvectors.

SMT-LIB name: `bvslt`.

Examples:

- `BitVec.slt 6#4 7 = true`
- `BitVec.slt 7#4 8 = false`

<a id="BitVec___decEq"></a>

**def**

```text
BitVec.decEq {w : Nat} (x y : BitVec w) : Decidable (x = y)
```

Bitvectors have decidable equality.

This should be used via the instance `DecidableEq (BitVec w)`.

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--API-Reference--Hashing"></a>
#### 20.5.5.5. Hashing

<a id="BitVec___hash"></a>

**def**

```text
BitVec.hash {n : Nat} (bv : BitVec n) : UInt64
```

Computes a hash of a bitvector, combining 64-bit words using `mixHash`.

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--API-Reference--Sequence-Operations"></a>
#### 20.5.5.6. Sequence Operations

These operations treat bitvectors as sequences of bits, rather than as encodings of numbers.

<a id="BitVec___nil"></a>

**def**

```text
BitVec.nil : BitVec 0
```

The empty bitvector.

<a id="BitVec___cons"></a>

**def**

```text
BitVec.cons {n : Nat} (msb : Bool) (lsbs : BitVec n) : BitVec (n + 1)
```

Prepends a single bit to the front of a bitvector, using big-endian order (see `append`).

The new bit is the most significant bit.

<a id="BitVec___concat"></a>

**def**

```text
BitVec.concat {n : Nat} (msbs : BitVec n) (lsb : Bool) : BitVec (n + 1)
```

Append a single bit to the end of a bitvector, using big endian order (see `append`). That is, the new bit is the least significant bit.

<a id="BitVec___shiftConcat"></a>

**def**

```text
BitVec.shiftConcat {n : Nat} (x : BitVec n) (b : Bool) : BitVec n
```

Shifts all bits of `x` to the left by `1` and sets the least significant bit to `b`.

This is a non-dependent version of `BitVec.concat` that does not change the total bitwidth.

<a id="BitVec___truncate"></a>

**def**

```text
BitVec.truncate {w : Nat} (v : Nat) (x : BitVec w) : BitVec v
```

Transforms a bitvector of length `w` into a bitvector of length `v`, padding with `0` as needed.

The specific behavior depends on the relationship between the starting width `w` and the final width `v`:

- If `v > w`, it is zero-extended; the high bits are padded with zeroes until the bitvector has `v` bits.
- If `v = w`, the bitvector is returned unchanged.
- If `v < w`, the high bits are truncated.

`BitVec.setWidth`, `BitVec.zeroExtend`, and `BitVec.truncate` are aliases for this operation.

SMT-LIB name: `zero_extend`.

<a id="BitVec___setWidth"></a>

**def**

```text
BitVec.setWidth {w : Nat} (v : Nat) (x : BitVec w) : BitVec v
```

Transforms a bitvector of length `w` into a bitvector of length `v`, padding with `0` as needed.

The specific behavior depends on the relationship between the starting width `w` and the final width `v`:

- If `v > w`, it is zero-extended; the high bits are padded with zeroes until the bitvector has `v` bits.
- If `v = w`, the bitvector is returned unchanged.
- If `v < w`, the high bits are truncated.

`BitVec.setWidth`, `BitVec.zeroExtend`, and `BitVec.truncate` are aliases for this operation.

SMT-LIB name: `zero_extend`.

<a id="BitVec___setWidth___"></a>

**def**

```text
BitVec.setWidth' {n w : Nat} (le : n ≤ w) (x : BitVec n) : BitVec w
```

Increases the width of a bitvector to one that is at least as large by zero-extending it.

This is a constant-time operation because the underlying `Nat` is unmodified; because the new width is at least as large as the old one, no overflow is possible.

<a id="BitVec___append"></a>

**def**

```text
BitVec.append {n m : Nat} (msbs : BitVec n) (lsbs : BitVec m) :
  BitVec (n + m)
```

Concatenates two bitvectors using the “big-endian” convention that the more significant input is on the left. Usually accessed via the `++` operator.

SMT-LIB name: `concat`.

Example:

- `0xAB#8 ++ 0xCD#8 = 0xABCD#16`.

<a id="BitVec___replicate"></a>

**def**

```text
BitVec.replicate {w : Nat} (i : Nat) : BitVec w → BitVec (w * i)
```

Concatenates `i` copies of `x` into a new vector of length `w * i`.

<a id="BitVec___reverse"></a>

**def**

```text
BitVec.reverse {w : Nat} : BitVec w → BitVec w
```

Reverses the bits in a bitvector.

<a id="BitVec___rotateLeft"></a>

**def**

```text
BitVec.rotateLeft {w : Nat} (x : BitVec w) (n : Nat) : BitVec w
```

Rotates the bits in a bitvector to the left.

All the bits of `x` are shifted to higher positions, with the top `n` bits wrapping around to fill the vacated low bits.

SMT-LIB name: `rotate_left`, except this operator uses a `Nat` shift amount.

Example:

- `(0b0011#4).rotateLeft 3 = 0b1001`

<a id="BitVec___rotateRight"></a>

**def**

```text
BitVec.rotateRight {w : Nat} (x : BitVec w) (n : Nat) : BitVec w
```

Rotates the bits in a bitvector to the right.

All the bits of `x` are shifted to lower positions, with the bottom `n` bits wrapping around to fill the vacated high bits.

SMT-LIB name: `rotate_right`, except this operator uses a `Nat` shift amount.

Example:

- `rotateRight 0b01001#5 1 = 0b10100`

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--API-Reference--Sequence-Operations--Bit-Extraction"></a>
##### 20.5.5.6.1. Bit Extraction

<a id="BitVec___msb"></a>

**def**

```text
BitVec.msb {n : Nat} (x : BitVec n) : Bool
```

Returns the most significant bit in a bitvector.

<a id="BitVec___getMsbD"></a>

**def**

```text
BitVec.getMsbD {w : Nat} (x : BitVec w) (i : Nat) : Bool
```

Returns the `i`th most significant bit, or `false` if `i ≥ w`.

<a id="BitVec___getMsb"></a>

**def**

```text
BitVec.getMsb {w : Nat} (x : BitVec w) (i : Fin w) : Bool
```

Returns the `i`th most significant bit.

<a id="BitVec___getMsb___"></a>

**def**

```text
BitVec.getMsb? {w : Nat} (x : BitVec w) (i : Nat) : Option Bool
```

Returns the `i`th most significant bit or `none` if `i ≥ w`.

<a id="BitVec___getLsbD"></a>

**def**

```text
BitVec.getLsbD {w : Nat} (x : BitVec w) (i : Nat) : Bool
```

Returns the `i`th least significant bit or `false` if `i ≥ w`.

<a id="BitVec___getLsb"></a>

**def**

```text
BitVec.getLsb {w : Nat} (x : BitVec w) (i : Fin w) : Bool
```

Returns the `i`th least significant bit.

<a id="BitVec___getLsb___"></a>

**def**

```text
BitVec.getLsb? {w : Nat} (x : BitVec w) (i : Nat) : Option Bool
```

Returns the `i`th least significant bit, or `none` if `i ≥ w`.

<a id="BitVec___extractLsb"></a>

**def**

```text
BitVec.extractLsb {n : Nat} (hi lo : Nat) (x : BitVec n) :
  BitVec (hi - lo + 1)
```

Extracts the bits from `hi` down to `lo` (both inclusive) from a bitvector, which is implicitly zero-extended if necessary.

The resulting bitvector has size `hi - lo + 1`.

SMT-LIB name: `extract`.

<a id="BitVec___extractLsb___"></a>

**def**

```text
BitVec.extractLsb' {n : Nat} (start len : Nat) (x : BitVec n) :
  BitVec len
```

Extracts the bits `start` to `start + len - 1` from a bitvector of size `n` to yield a new bitvector of size `len`. If `start + len > n`, then the bitvector is zero-extended.

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--API-Reference--Bitwise-Operators"></a>
#### 20.5.5.7. Bitwise Operators

These operators modify the individual bits of one or more bitvectors.

<a id="BitVec___and"></a>

**def**

```text
BitVec.and {n : Nat} (x y : BitVec n) : BitVec n
```

Bitwise and for bitvectors. Usually accessed via the `&&&` operator.

SMT-LIB name: `bvand`.

Example:

- `0b1010#4 &&& 0b0110#4 = 0b0010#4`

<a id="BitVec___or"></a>

**def**

```text
BitVec.or {n : Nat} (x y : BitVec n) : BitVec n
```

Bitwise or for bitvectors. Usually accessed via the `|||` operator.

SMT-LIB name: `bvor`.

Example:

- `0b1010#4 ||| 0b0110#4 = 0b1110#4`

<a id="BitVec___not"></a>

**def**

```text
BitVec.not {n : Nat} (x : BitVec n) : BitVec n
```

Bitwise complement for bitvectors. Usually accessed via the `~~~` prefix operator.

SMT-LIB name: `bvnot`.

Example:

- `~~~(0b0101#4) == 0b1010`

<a id="BitVec___xor"></a>

**def**

```text
BitVec.xor {n : Nat} (x y : BitVec n) : BitVec n
```

Bitwise xor for bitvectors. Usually accessed via the `^^^` operator.

SMT-LIB name: `bvxor`.

Example:

- `0b1010#4 ^^^ 0b0110#4 = 0b1100#4`

<a id="BitVec___zeroExtend"></a>

**def**

```text
BitVec.zeroExtend {w : Nat} (v : Nat) (x : BitVec w) : BitVec v
```

Transforms a bitvector of length `w` into a bitvector of length `v`, padding with `0` as needed.

The specific behavior depends on the relationship between the starting width `w` and the final width `v`:

- If `v > w`, it is zero-extended; the high bits are padded with zeroes until the bitvector has `v` bits.
- If `v = w`, the bitvector is returned unchanged.
- If `v < w`, the high bits are truncated.

`BitVec.setWidth`, `BitVec.zeroExtend`, and `BitVec.truncate` are aliases for this operation.

SMT-LIB name: `zero_extend`.

<a id="BitVec___signExtend"></a>

**def**

```text
BitVec.signExtend {w : Nat} (v : Nat) (x : BitVec w) : BitVec v
```

Transforms a bitvector of length `w` into a bitvector of length `v`, padding as needed with the most significant bit's value.

If `x` is an empty bitvector, then the sign is treated as zero.

SMT-LIB name: `sign_extend`.

<a id="BitVec___ushiftRight"></a>

**def**

```text
BitVec.ushiftRight {n : Nat} (x : BitVec n) (s : Nat) : BitVec n
```

Shifts a bitvector to the right. This is a logical right shift - the high bits are filled with zeros.

As a numeric operation, this is equivalent to `x / 2^s`, rounding down.

SMT-LIB name: `bvlshr` except this operator uses a `Nat` shift value.

<a id="BitVec___sshiftRight"></a>

**def**

```text
BitVec.sshiftRight {n : Nat} (x : BitVec n) (s : Nat) : BitVec n
```

Shifts a bitvector to the right. This is an arithmetic right shift - the high bits are filled with most significant bit's value.

As a numeric operation, this is equivalent to `x.toInt >>> s`.

SMT-LIB name: `bvashr` except this operator uses a `Nat` shift value.

<a id="BitVec___sshiftRight___"></a>

**def**

```text
BitVec.sshiftRight' {n m : Nat} (a : BitVec n) (s : BitVec m) : BitVec n
```

Shifts a bitvector to the right. This is an arithmetic right shift - the high bits are filled with most significant bit's value.

As a numeric operation, this is equivalent to `a.toInt >>> s.toNat`.

SMT-LIB name: `bvashr`.

<a id="BitVec___shiftLeft"></a>

**def**

```text
BitVec.shiftLeft {n : Nat} (x : BitVec n) (s : Nat) : BitVec n
```

Shifts a bitvector to the left. The low bits are filled with zeros. As a numeric operation, this is equivalent to `x * 2^s`, modulo `2^n`.

SMT-LIB name: `bvshl` except this operator uses a `Nat` shift value.

<a id="BitVec___shiftLeftZeroExtend"></a>

**def**

```text
BitVec.shiftLeftZeroExtend {w : Nat} (msbs : BitVec w) (m : Nat) :
  BitVec (w + m)
```

Returns `zeroExtend (w+n) x <<< n` without needing to compute `x % 2^(2+n)`.

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--API-Reference--Arithmetic"></a>
#### 20.5.5.8. Arithmetic

These operators treat bitvectors as numbers. Some operations are signed, while others are unsigned. Because bitvectors are understood as two's complement numbers, addition, subtraction and multiplication coincide for the signed and unsigned interpretations.

<a id="BitVec___add"></a>

**def**

```text
BitVec.add {n : Nat} (x y : BitVec n) : BitVec n
```

Adds two bitvectors. This can be interpreted as either signed or unsigned addition modulo `2^n`. Usually accessed via the `+` operator.

SMT-LIB name: `bvadd`.

<a id="BitVec___sub"></a>

**def**

```text
BitVec.sub {n : Nat} (x y : BitVec n) : BitVec n
```

Subtracts one bitvector from another. This can be interpreted as either signed or unsigned subtraction modulo `2^n`. Usually accessed via the `-` operator.

<a id="BitVec___mul"></a>

**def**

```text
BitVec.mul {n : Nat} (x y : BitVec n) : BitVec n
```

Multiplies two bitvectors. This can be interpreted as either signed or unsigned multiplication modulo `2^n`. Usually accessed via the `*` operator.

SMT-LIB name: `bvmul`.

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--API-Reference--Arithmetic--Unsigned-Operations"></a>
##### 20.5.5.8.1. Unsigned Operations

<a id="BitVec___udiv"></a>

**def**

```text
BitVec.udiv {n : Nat} (x y : BitVec n) : BitVec n
```

Unsigned division of bitvectors using the Lean convention where division by zero returns zero. Usually accessed via the `/` operator.

<a id="BitVec___smtUDiv"></a>

**def**

```text
BitVec.smtUDiv {n : Nat} (x y : BitVec n) : BitVec n
```

Unsigned division of bitvectors using the [SMT-LIB convention](http://smtlib.cs.uiowa.edu/theories-FixedSizeBitVectors.shtml), where division by zero returns `BitVector.allOnes n`.

SMT-LIB name: `bvudiv`.

<a id="BitVec___umod"></a>

**def**

```text
BitVec.umod {n : Nat} (x y : BitVec n) : BitVec n
```

Unsigned modulo for bitvectors. Usually accessed via the `%` operator.

SMT-LIB name: `bvurem`.

<a id="BitVec___uaddOverflow"></a>

**def**

```text
BitVec.uaddOverflow {w : Nat} (x y : BitVec w) : Bool
```

Checks whether addition of `x` and `y` results in *unsigned* overflow.

SMT-LIB name: `bvuaddo`.

<a id="BitVec___usubOverflow"></a>

**def**

```text
BitVec.usubOverflow {w : Nat} (x y : BitVec w) : Bool
```

Checks whether subtraction of `x` and `y` results in *unsigned* overflow.

SMT-Lib name: `bvusubo`.

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--API-Reference--Arithmetic--Signed-Operations"></a>
##### 20.5.5.8.2. Signed Operations

<a id="BitVec___abs"></a>

**def**

```text
BitVec.abs {n : Nat} (x : BitVec n) : BitVec n
```

Returns the absolute value of a signed bitvector.

<a id="BitVec___neg"></a>

**def**

```text
BitVec.neg {n : Nat} (x : BitVec n) : BitVec n
```

Negation of bitvectors. This can be interpreted as either signed or unsigned negation modulo `2^n`. Usually accessed via the `-` prefix operator.

SMT-LIB name: `bvneg`.

<a id="BitVec___sdiv"></a>

**def**

```text
BitVec.sdiv {n : Nat} (x y : BitVec n) : BitVec n
```

Signed T-division (using the truncating rounding convention) for bitvectors. This function obeys the Lean convention that division by zero returns zero.

Examples:

- `(7#4).sdiv 2 = 3#4`
- `(-8#4).sdiv 2 = -4#4`
- `(5#4).sdiv -2 = -2#4`
- `(-7#4).sdiv (-2) = 3#4`

<a id="BitVec___smtSDiv"></a>

**def**

```text
BitVec.smtSDiv {n : Nat} (x y : BitVec n) : BitVec n
```

Signed division for bitvectors using the SMT-LIB using the [SMT-LIB convention](http://smtlib.cs.uiowa.edu/theories-FixedSizeBitVectors.shtml), where division by zero returns `BitVector.allOnes n`.

Specifically, `x.smtSDiv 0 = if x >= 0 then -1 else 1`

SMT-LIB name: `bvsdiv`.

<a id="BitVec___smod"></a>

**def**

```text
BitVec.smod {m : Nat} (x y : BitVec m) : BitVec m
```

Remainder for signed division rounded to negative infinity.

SMT-LIB name: `bvsmod`.

<a id="BitVec___srem"></a>

**def**

```text
BitVec.srem {n : Nat} (x y : BitVec n) : BitVec n
```

Remainder for signed division rounding to zero.

SMT-LIB name: `bvsrem`.

<a id="BitVec___saddOverflow"></a>

**def**

```text
BitVec.saddOverflow {w : Nat} (x y : BitVec w) : Bool
```

Checks whether addition of `x` and `y` results in *signed* overflow, treating `x` and `y` as 2's complement signed bitvectors.

SMT-LIB name: `bvsaddo`.

<a id="BitVec___ssubOverflow"></a>

**def**

```text
BitVec.ssubOverflow {w : Nat} (x y : BitVec w) : Bool
```

Checks whether the subtraction of `x` and `y` results in *signed* overflow, treating `x` and `y` as 2's complement signed bitvectors.

SMT-Lib name: `bvssubo`.

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--API-Reference--Iteration"></a>
#### 20.5.5.9. Iteration

<a id="BitVec___iunfoldr"></a>

**def**

```text
BitVec.iunfoldr.{u_1} {w : Nat} {α : Type u_1}
  (f : Fin w → α → α × Bool) (s : α) : α × BitVec w
```

Constructs a bitvector by iteratively computing a state for each bit using the function `f`, starting with the initial state `s`. At each step, the prior state and the current bit index are passed to `f`, and it produces a bit along with the next state value. These bits are assembled into the final bitvector.

It produces a sequence of state values `[s_0, s_1 .. s_w]` and a bitvector `v` where `f i s_i = (s_{i+1}, b_i)` and `b_i` is bit `i`th least-significant bit in `v` (e.g., `getLsb v i = b_i`).

The theorem `iunfoldr_replace` allows uses of `BitVec.iunfoldr` to be replaced with declarative specifications that are easier to reason about.

<a id="BitVec___iunfoldr_replace"></a>

**theorem**

```text
BitVec.iunfoldr_replace.{u_1} {w : Nat} {α : Type u_1}
  {f : Fin w → α → α × Bool} (state : Nat → α) (value : BitVec w)
  (a : α) (init : state 0 = a)
  (step : ∀ (i : Fin w), f i (state ↑i) = (state (↑i + 1), value[↑i])) :
  BitVec.iunfoldr f a = (state w, value)
```

Given a function `state` that provides the correct state for every potential iteration count and a function that computes these states from the correct initial state, the result of applying `BitVec.iunfoldr f` to the initial state is the state corresponding to the bitvector's width paired with the bitvector that consists of each computed bit.

This theorem can be used to prove properties of functions that are defined using `BitVec.iunfoldr`.

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--API-Reference--Proof-Automation"></a>
#### 20.5.5.10. Proof Automation

<a id="The-Lean-Language-Reference--Basic-Types--Bitvectors--API-Reference--Proof-Automation--Bit-Blasting"></a>
##### 20.5.5.10.1. Bit Blasting

The standard library contains a number of helper implementations that are useful to implement bit blasting, which is the technique used by `bv_decide` to encode propositions as Boolean satisfiability problems for external solvers.

<a id="BitVec___adc"></a>

**def**

```text
BitVec.adc {w : Nat} (x y : BitVec w) : Bool → Bool × BitVec w
```

Bitwise addition implemented via a ripple carry adder.

<a id="BitVec___adcb"></a>

**def**

```text
BitVec.adcb (x y c : Bool) : Bool × Bool
```

Carry function for bitwise addition.

<a id="BitVec___carry"></a>

**def**

```text
BitVec.carry {w : Nat} (i : Nat) (x y : BitVec w) (c : Bool) : Bool
```

carry i x y c returns true if the `i` carry bit is true when computing `x + y + c`.

<a id="BitVec___mulRec"></a>

**def**

```text
BitVec.mulRec {w : Nat} (x y : BitVec w) (s : Nat) : BitVec w
```

A recurrence that describes multiplication as repeated addition.

This function is useful for bit blasting multiplication.

<a id="BitVec___divRec"></a>

**def**

```text
BitVec.divRec {w : Nat} (m : Nat) (args : BitVec.DivModArgs w)
  (qr : BitVec.DivModState w) : BitVec.DivModState w
```

A recursive definition of division for bit blasting, in terms of a shift-subtraction circuit.

<a id="BitVec___divSubtractShift"></a>

**def**

```text
BitVec.divSubtractShift {w : Nat} (args : BitVec.DivModArgs w)
  (qr : BitVec.DivModState w) : BitVec.DivModState w
```

One round of the division algorithm. It tries to perform a subtract shift.

This should only be called when `r.msb = false`, so it will not overflow.

<a id="BitVec___shiftLeftRec"></a>

**def**

```text
BitVec.shiftLeftRec {w₁ w₂ : Nat} (x : BitVec w₁) (y : BitVec w₂)
  (n : Nat) : BitVec w₁
```

Shifts `x` to the left by the first `n` bits of `y`.

The theorem `BitVec.shiftLeft_eq_shiftLeftRec` proves the equivalence of `(x <<< y)` and `BitVec.shiftLeftRec x y`.

Together with equations `BitVec.shiftLeftRec_zero` and `BitVec.shiftLeftRec_succ`, this allows `BitVec.shiftLeft` to be unfolded into a circuit for bit blasting.

<a id="BitVec___sshiftRightRec"></a>

**def**

```text
BitVec.sshiftRightRec {w₁ w₂ : Nat} (x : BitVec w₁) (y : BitVec w₂)
  (n : Nat) : BitVec w₁
```

Shifts `x` arithmetically (signed) to the right by the first `n` bits of `y`.

The theorem `BitVec.sshiftRight_eq_sshiftRightRec` proves the equivalence of `(x.sshiftRight y)` and `BitVec.sshiftRightRec x y`. Together with equations `BitVec.sshiftRightRec_zero`, and `BitVec.sshiftRightRec_succ`, this allows `BitVec.sshiftRight` to be unfolded into a circuit for bit blasting.

<a id="BitVec___ushiftRightRec"></a>

**def**

```text
BitVec.ushiftRightRec {w₁ w₂ : Nat} (x : BitVec w₁) (y : BitVec w₂)
  (n : Nat) : BitVec w₁
```

Shifts `x` logically to the right by the first `n` bits of `y`.

The theorem `BitVec.shiftRight_eq_ushiftRightRec` proves the equivalence of `(x >>> y)` and `BitVec.ushiftRightRec`.

Together with equations `BitVec.ushiftRightRec_zero` and `BitVec.ushiftRightRec_succ`, this allows `BitVec.ushiftRight` to be unfolded into a circuit for bit blasting.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Notation for bitvector literals. `i#n` is a shorthand for `BitVec.ofNat n i`. 

Conventions for notations in identifiers:

 * The recommended spelling of `0#n` in identifiers is `zero` (not `ofNat_zero`).

 * The recommended spelling of `1#n` in identifiers is `one` (not `ofNat_one`).
```


### Display 2


```text
Notation for bitvector literals without truncation. `i#'lt` is a shorthand for `BitVec.ofNatLT i lt`.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
3#2
```


### Display 2


```text
Tactic `decide` proved that the proposition
  256 < 2 ^ 8
is false
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
⊢ 1 < 2 ^ 8
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
⊢ 256 < 2 ^ 8
```


### Display 4


```text
⊢ popcount = popcount_spec
```


### Display 5


```text
x:BitVec 32⊢ popcount x = popcount_spec x
```


### Display 6


```text
x:BitVec 32⊢ ((x - (x >>> 1 &&& 1431655765#32) &&& 858993459#32) + ((x - (x >>> 1 &&& 1431655765#32)) >>> 2 &&& 858993459#32) +
            ((x - (x >>> 1 &&& 1431655765#32) &&& 858993459#32) +
                ((x - (x >>> 1 &&& 1431655765#32)) >>> 2 &&& 858993459#32)) >>>
              4 &&&
          252645135#32) +
        ((x - (x >>> 1 &&& 1431655765#32) &&& 858993459#32) +
                ((x - (x >>> 1 &&& 1431655765#32)) >>> 2 &&& 858993459#32) +
              ((x - (x >>> 1 &&& 1431655765#32) &&& 858993459#32) +
                  ((x - (x >>> 1 &&& 1431655765#32)) >>> 2 &&& 858993459#32)) >>>
                4 &&&
            252645135#32) >>>
          8 +
      (((x - (x >>> 1 &&& 1431655765#32) &&& 858993459#32) +
                ((x - (x >>> 1 &&& 1431655765#32)) >>> 2 &&& 858993459#32) +
              ((x - (x >>> 1 &&& 1431655765#32) &&& 858993459#32) +
                  ((x - (x >>> 1 &&& 1431655765#32)) >>> 2 &&& 858993459#32)) >>>
                4 &&&
            252645135#32) +
          ((x - (x >>> 1 &&& 1431655765#32) &&& 858993459#32) +
                  ((x - (x >>> 1 &&& 1431655765#32)) >>> 2 &&& 858993459#32) +
                ((x - (x >>> 1 &&& 1431655765#32) &&& 858993459#32) +
                    ((x - (x >>> 1 &&& 1431655765#32)) >>> 2 &&& 858993459#32)) >>>
                  4 &&&
              252645135#32) >>>
            8) >>>
        16 &&&
    63#32 =
  (x &&& 1#32) + (x >>> 1 &&& 1#32) + (x >>> 2 &&& 1#32) + (x >>> 3 &&& 1#32) + (x >>> 4 &&& 1#32) +
                                                        (x >>> 5 &&& 1#32) +
                                                      (x >>> 6 &&& 1#32) +
                                                    (x >>> 7 &&& 1#32) +
                                                  (x >>> 8 &&& 1#32) +
                                                (x >>> 9 &&& 1#32) +
                                              (x >>> 10 &&& 1#32) +
                                            (x >>> 11 &&& 1#32) +
                                          (x >>> 12 &&& 1#32) +
                                        (x >>> 13 &&& 1#32) +
                                      (x >>> 14 &&& 1#32) +
                                    (x >>> 15 &&& 1#32) +
                                  (x >>> 16 &&& 1#32) +
                                (x >>> 17 &&& 1#32) +
                              (x >>> 18 &&& 1#32) +
                            (x >>> 19 &&& 1#32) +
                          (x >>> 20 &&& 1#32) +
                        (x >>> 21 &&& 1#32) +
                      (x >>> 22 &&& 1#32) +
                    (x >>> 23 &&& 1#32) +
                  (x >>> 24 &&& 1#32) +
                (x >>> 25 &&& 1#32) +
              (x >>> 26 &&& 1#32) +
            (x >>> 27 &&& 1#32) +
          (x >>> 28 &&& 1#32) +
        (x >>> 29 &&& 1#32) +
      (x >>> 30 &&& 1#32) +
    (x >>> 31 &&& 1#32)
```

