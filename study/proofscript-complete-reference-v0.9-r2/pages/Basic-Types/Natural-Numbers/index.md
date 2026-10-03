<a id="Nat"></a>

# ProofScript — 20.1. Natural Numbers

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Natural-Numbers/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Natural-Numbers/index.html). Source Git blob: `478b65968d44f99ea8a16ba6adfd90370600cc2e`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.1. Natural Numbers

The 
<a id="--tech-term-natural-numbers"></a>
natural numbers are nonnegative integers. Logically, they are the numbers 0, 1, 2, 3, …, generated from the constructors `Nat.zero` and `Nat.succ`. Lean imposes no upper bound on the representation of natural numbers other than physical constraints imposed by the available memory of the computer.

Because the natural numbers are fundamental to both mathematical reasoning and programming, they are specially supported by Lean's implementation. The logical model of the natural numbers is as an [inductive type](../../The-Type-System/Inductive-Types/index.md#--tech-term-Inductive-types), and arithmetic operations are specified using this model. In Lean's kernel, the interpreter, and compiled code, closed natural numbers are represented as efficient arbitrary-precision integers. Sufficiently small numbers are values that don't require indirection through a pointer. Arithmetic operations are implemented by primitives that take advantage of the efficient representations.

<a id="nat-model"></a>
### 20.1.1. Logical Model

<a id="Nat___zero"></a>

**inductive type**

```text
Nat : Type
```

The natural numbers, starting at zero.

This type is special-cased by both the kernel and the compiler, and overridden with an efficient implementation. Both use a fast arbitrary-precision arithmetic library (usually [GMP](https://gmplib.org/)); at runtime, `Nat` values that are sufficiently small are unboxed.

**Constructors**

```text
Nat.zero : Nat
```

Zero, the smallest natural number.

Using `Nat.zero` explicitly should usually be avoided in favor of the literal `0`, which is the [simp normal form](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=simp-normal-forms).

```text
Nat.succ (n : Nat) : Nat
```

The successor of a natural number `n`.

Using `Nat.succ n` should usually be avoided in favor of `n + 1`, which is the [simp normal form](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=simp-normal-forms).

<a id="Proofs-by-Induction"></a>
Proofs by Induction 

The natural numbers are an [inductive type](../../The-Type-System/Inductive-Types/index.md#--tech-term-Inductive-types), so the `induction` tactic can be used to prove universally-quantified statements. A proof by induction requires a base case and an induction step. The base case is a proof that the statement is true for `0`. The induction step is a proof that the truth of the statement for some arbitrary number `i` implies its truth for `i + 1`.

This proof uses the lemma `Nat.succ_lt_succ` in its induction step.

```proofscript
example (n : Nat) : n < n + 1 := by
  induction n with
  | zero =>
    show 0 < 1
    decide
  | succ i ih => -- ih : i < i + 1
    show i + 1 < i + 1 + 1
    exact Nat.succ_lt_succ ih
```

<a id="peano-axioms"></a>
#### 20.1.1.1. Peano Axioms

The Peano axioms are a consequence of this definition. The induction principle generated for `Nat` is the one demanded by the axiom of induction:

```proofscript
Nat.rec.{u} {motive : Nat → Sort u}
  (zero : motive zero)
  (succ : (n : Nat) → motive n → motive n.succ)
  (t : Nat) :
  motive t
```

This induction principle also implements primitive recursion. The injectivity of `Nat.succ` and the disjointness of `Nat.succ` and `Nat.zero` are consequences of the induction principle, using a construction typically called “no confusion”:
<a id="NoConfusion"></a>
<a id="noConfusionDiagonal"></a>
<a id="noConfusion"></a>
<a id="succ_injective"></a>
<a id="succ_not_zero"></a>


```proofscript
def NoConfusion : Nat → Nat → Prop
  | 0, 0 => True
  | 0, _ + 1 | _ + 1, 0 => False
  | n + 1, k + 1 => n = k

theorem noConfusionDiagonal (n : Nat) :
    NoConfusion n n :=
  Nat.rec True.intro (fun _ _ => rfl) n

theorem noConfusion (n k : Nat) (eq : n = k) :
    NoConfusion n k :=
  eq ▸ noConfusionDiagonal n

theorem succ_injective : n + 1 = k + 1 → n = k :=
  noConfusion (n + 1) (k + 1)

theorem succ_not_zero : ¬n + 1 = 0 :=
  noConfusion (n + 1) 0
```

<a id="nat-runtime"></a>
### 20.1.2. Run-Time Representation

The representation suggested by the declaration of `Nat` would be horrendously inefficient, as it's essentially a linked list. The length of the list would be the number. With this representation, addition would take time linear in the size of one of the addends, and numbers would take at least as many machine words as their magnitude in memory. Thus, natural numbers have special support in both the kernel and the compiler that avoids this overhead.

In the kernel, there are special `Nat` literal values that use a widely-trusted, efficient arbitrary-precision integer library (usually [GMP](https://gmplib.org/)). Basic functions such as addition are overridden by primitives that use this representation. Because they are part of the kernel, if these primitives did not correspond to their definitions as Lean functions, it could undermine soundness.

In compiled code, sufficiently-small natural numbers are represented without pointer indirections: the lowest-order bit in an object pointer is used to indicate that the value is not, in fact, a pointer, and the remaining bits are used to store the number. 31 bits are available on 32-bits architectures for pointer-free `Nat`s, while 63 bits are available on 64-bit architectures. In other words, natural numbers smaller than 2^{31} = 2,147,483,648 or 2^{63} = 9,223,372,036,854,775,808 do not require allocations. If an natural number is too large for this representation, it is instead allocated as an ordinary Lean object that consists of an object header and an arbitrary-precision integer value.

<a id="nat-performance"></a>
#### 20.1.2.1. Performance Notes

Using Lean's built-in arithmetic operators, rather than redefining them, is essential. The logical model of `Nat` is essentially a linked list, so addition would take time linear in the size of one argument. Still worse, multiplication takes quadratic time in this model. While defining arithmetic from scratch can be a useful learning exercise, these redefined operations will not be nearly as fast.

<a id="nat-syntax"></a>
### 20.1.3. Syntax

Natural number literals are overridden using the `OfNat` type class, which is described in the [section on literal syntax](../../Terms/Numeric-Literals/index.md#nat-literals).

<a id="nat-api"></a>
### 20.1.4. API Reference

<a id="nat-api-arithmetic"></a>
#### 20.1.4.1. Arithmetic

<a id="Nat___pred"></a>

**def**

```text
Nat.pred : Nat → Nat
```

The predecessor of a natural number is one less than it. The predecessor of `0` is defined to be `0`.

This definition is overridden in the compiler with an efficient implementation. This definition is the logical model.

<a id="Nat___add"></a>

**def**

```text
Nat.add : Nat → Nat → Nat
```

Addition of natural numbers, typically used via the `+` operator.

This function is overridden in both the kernel and the compiler to efficiently evaluate using the arbitrary-precision arithmetic library. The definition provided here is the logical model.

<a id="Nat___sub"></a>

**def**

```text
Nat.sub : Nat → Nat → Nat
```

Subtraction of natural numbers, truncated at `0`. Usually used via the `-` operator.

If a result would be less than zero, then the result is zero.

This definition is overridden in both the kernel and the compiler to efficiently evaluate using the arbitrary-precision arithmetic library. The definition provided here is the logical model.

Examples:

- `5 - 3 = 2`
- `8 - 2 = 6`
- `8 - 8 = 0`
- `8 - 20 = 0`

<a id="Nat___mul"></a>

**def**

```text
Nat.mul : Nat → Nat → Nat
```

Multiplication of natural numbers, usually accessed via the `*` operator.

This function is overridden in both the kernel and the compiler to efficiently evaluate using the arbitrary-precision arithmetic library. The definition provided here is the logical model.

<a id="Nat___div"></a>

**def**

```text
Nat.div (x y : Nat) : Nat
```

Division of natural numbers, discarding the remainder. Division by `0` returns `0`. Usually accessed via the `/` operator.

This operation is sometimes called “floor division.”

This function is overridden at runtime with an efficient implementation. This definition is the logical model.

Examples:

- `21 / 3 = 7`
- `21 / 5 = 4`
- `0 / 22 = 0`
- `5 / 0 = 0`

<a id="Nat___mod"></a>

**def**

```text
Nat.mod : Nat → Nat → Nat
```

The modulo operator, which computes the remainder when dividing one natural number by another. Usually accessed via the `%` operator. When the divisor is `0`, the result is the dividend rather than an error.

`Nat.mod` is a wrapper around `Nat.modCore` that special-cases two situations, giving better definitional reductions:

- `Nat.mod 0 m` should reduce to `0`, for all terms `m : Nat`.
- `Nat.mod n (m + n + 1)` should reduce to `n` for concrete `Nat` literals `n`.

These reductions help `Fin n` literals work well, because the `OfNat` instance for `Fin` uses `Nat.mod`. In particular, `(0 : Fin (n + 1)).val` should reduce definitionally to `0`. `Nat.modCore` can handle all numbers, but its definitional reductions are not as convenient.

This function is overridden at runtime with an efficient implementation. This definition is the logical model.

Examples:

- `7 % 2 = 1`
- `9 % 3 = 0`
- `5 % 7 = 5`
- `5 % 0 = 5`
- `show ∀ (n : Nat), 0 % n = 0 from fun _ => rfl`
- `show ∀ (m : Nat), 5 % (m + 6) = 5 from fun _ => rfl`

<a id="Nat___modCore"></a>

**def**

```text
Nat.modCore (x y : Nat) : Nat
```

The modulo operator, which computes the remainder when dividing one natural number by another. Usually accessed via the `%` operator. When the divisor is `0`, the result is the dividend rather than an error.

This is the core implementation of `Nat.mod`. It computes the correct result for any two closed natural numbers, but it does not have some convenient [definitional reductions](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=type-system) when the `Nat`s contain free variables. The wrapper `Nat.mod` handles those cases specially and then calls `Nat.modCore`.

This function is overridden at runtime with an efficient implementation. This definition is the logical model.

<a id="Nat___pow"></a>

**def**

```text
Nat.pow (m : Nat) : Nat → Nat
```

The power operation on natural numbers, usually accessed via the `^` operator.

This function is overridden in both the kernel and the compiler to efficiently evaluate using the arbitrary-precision arithmetic library. The definition provided here is the logical model.

<a id="Nat___log2"></a>

**def**

```text
Nat.log2 (n : Nat) : Nat
```

Base-two logarithm of natural numbers. Returns `⌊max 0 (log₂ n)⌋`.

This function is overridden at runtime with an efficient implementation. This definition is the logical model.

Examples:

- `Nat.log2 0 = 0`
- `Nat.log2 1 = 0`
- `Nat.log2 2 = 1`
- `Nat.log2 4 = 2`
- `Nat.log2 7 = 2`
- `Nat.log2 8 = 3`

<a id="nat-api-bitwise"></a>
##### 20.1.4.1.1. Bitwise Operations

<a id="Nat___shiftLeft"></a>

**def**

```text
Nat.shiftLeft : Nat → Nat → Nat
```

Shifts the binary representation of a value left by the specified number of bits. Usually accessed via the `<<<` operator.

Examples:

- `1 <<< 2 = 4`
- `1 <<< 3 = 8`
- `0 <<< 3 = 0`
- `0xf1 <<< 4 = 0xf10`

<a id="Nat___shiftRight"></a>

**def**

```text
Nat.shiftRight : Nat → Nat → Nat
```

Shifts the binary representation of a value right by the specified number of bits. Usually accessed via the `>>>` operator.

Examples:

- `4 >>> 2 = 1`
- `8 >>> 2 = 2`
- `8 >>> 3 = 1`
- `0 >>> 3 = 0`
- `0xf13a >>> 8 = 0xf1`

<a id="Nat___xor"></a>

**def**

```text
Nat.xor : Nat → Nat → Nat
```

Bitwise exclusive or. Usually accessed via the `^^^` operator.

Each bit of the resulting value is set if the corresponding bit is set in exactly one of the inputs.

<a id="Nat___lor"></a>

**def**

```text
Nat.lor : Nat → Nat → Nat
```

Bitwise or. Usually accessed via the `|||` operator.

Each bit of the resulting value is set if the corresponding bit is set in at least one of the inputs.

<a id="Nat___land"></a>

**def**

```text
Nat.land : Nat → Nat → Nat
```

Bitwise and. Usually accessed via the `&&&` operator.

Each bit of the resulting value is set if the corresponding bit is set in both of the inputs.

<a id="Nat___bitwise"></a>

**def**

```text
Nat.bitwise (f : Bool → Bool → Bool) (n m : Nat) : Nat
```

A helper for implementing bitwise operators on `Nat`.

Each bit of the resulting `Nat` is the result of applying `f` to the corresponding bits of the input `Nat`s, up to the position of the highest set bit in either input.

<a id="Nat___testBit"></a>

**def**

```text
Nat.testBit (m n : Nat) : Bool
```

Returns `true` if the `(n+1)`th least significant bit is `1`, or `false` if it is `0`.

<a id="nat-api-minmax"></a>
#### 20.1.4.2. Minimum and Maximum

<a id="Nat___min"></a>

**def**

```text
Nat.min (n m : Nat) : Nat
```

Returns the lesser of two natural numbers. Usually accessed via `Min.min`.

Returns `n` if `n ≤ m`, or `m` if `m ≤ n`.

Examples:

- `min 0 5 = 0`
- `min 4 5 = 4`
- `min 4 3 = 3`
- `min 8 8 = 8`

<a id="Nat___max"></a>

**def**

```text
Nat.max (n m : Nat) : Nat
```

Returns the greater of two natural numbers. Usually accessed via `Max.max`.

Returns `m` if `n ≤ m`, or `n` if `m ≤ n`.

Examples:

- `max 0 5 = 5`
- `max 4 5 = 5`
- `max 4 3 = 4`
- `max 8 8 = 8`

<a id="nat-api-gcd-lcm"></a>
#### 20.1.4.3. GCD and LCM

<a id="Nat___gcd"></a>

**def**

```text
Nat.gcd (m n : Nat) : Nat
```

Computes the greatest common divisor of two natural numbers. The GCD of two natural numbers is the largest natural number that evenly divides both.

In particular, the GCD of a number and `0` is the number itself.

This reference implementation via the Euclidean algorithm is overridden in both the kernel and the compiler to efficiently evaluate using arbitrary-precision arithmetic. The definition provided here is the logical model.

Examples:

- `Nat.gcd 10 15 = 5`
- `Nat.gcd 0 5 = 5`
- `Nat.gcd 7 0 = 7`

<a id="Nat___lcm"></a>

**def**

```text
Nat.lcm (m n : Nat) : Nat
```

The least common multiple of `m` and `n` is the smallest natural number that's evenly divisible by both `m` and `n`. Returns `0` if either `m` or `n` is `0`.

Examples:

- `Nat.lcm 9 6 = 18`
- `Nat.lcm 9 3 = 9`
- `Nat.lcm 0 3 = 0`
- `Nat.lcm 3 0 = 0`

<a id="nat-api-pow2"></a>
#### 20.1.4.4. Powers of Two

<a id="Nat___isPowerOfTwo"></a>

**def**

```text
Nat.isPowerOfTwo (n : Nat) : Prop
```

A natural number `n` is a power of two if there exists some `k : Nat` such that `n = 2 ^ k`.

<a id="Nat___nextPowerOfTwo"></a>

**def**

```text
Nat.nextPowerOfTwo (n : Nat) : Nat
```

Returns the least power of two that's greater than or equal to `n`.

Examples:

- `Nat.nextPowerOfTwo 0 = 1`
- `Nat.nextPowerOfTwo 1 = 1`
- `Nat.nextPowerOfTwo 2 = 2`
- `Nat.nextPowerOfTwo 3 = 4`
- `Nat.nextPowerOfTwo 5 = 8`

<a id="nat-api-comparison"></a>
#### 20.1.4.5. Comparisons

<a id="nat-api-comparison-bool"></a>
##### 20.1.4.5.1. Boolean Comparisons

<a id="Nat___beq"></a>

**def**

```text
Nat.beq : Nat → Nat → Bool
```

Boolean equality of natural numbers, usually accessed via the `==` operator.

This function is overridden in both the kernel and the compiler to efficiently evaluate using the arbitrary-precision arithmetic library. The definition provided here is the logical model.

<a id="Nat___ble"></a>

**def**

```text
Nat.ble : Nat → Nat → Bool
```

The Boolean less-than-or-equal-to comparison on natural numbers.

This function is overridden in both the kernel and the compiler to efficiently evaluate using the arbitrary-precision arithmetic library. The definition provided here is the logical model.

Examples:

- `Nat.ble 2 5 = true`
- `Nat.ble 5 2 = false`
- `Nat.ble 5 5 = true`

<a id="Nat___blt"></a>

**def**

```text
Nat.blt (a b : Nat) : Bool
```

The Boolean less-than comparison on natural numbers.

This function is overridden in both the kernel and the compiler to efficiently evaluate using the arbitrary-precision arithmetic library. The definition provided here is the logical model.

Examples:

- `Nat.blt 2 5 = true`
- `Nat.blt 5 2 = false`
- `Nat.blt 5 5 = false`

<a id="nat-api-deceq"></a>
##### 20.1.4.5.2. Decidable Equality

<a id="Nat___decEq"></a>

**def**

```text
Nat.decEq (n m : Nat) : Decidable (n = m)
```

A decision procedure for equality of natural numbers, usually accessed via the `DecidableEq Nat` instance.

This function is overridden in both the kernel and the compiler to efficiently evaluate using the arbitrary-precision arithmetic library. The definition provided here is the logical model.

Examples:

- `Nat.decEq 5 5 = isTrue rfl`
- `(if 3 = 4 then "yes" else "no") = "no"`
- `show 12 = 12 by decide`

<a id="Nat___decLe"></a>

**def**

```text
Nat.decLe (n m : Nat) : Decidable (n ≤ m)
```

A decision procedure for non-strict inequality of natural numbers, usually accessed via the `DecidableLE Nat` instance.

Examples:

- `(if 3 ≤ 4 then "yes" else "no") = "yes"`
- `(if 6 ≤ 4 then "yes" else "no") = "no"`
- `show 12 ≤ 12 by decide`
- `show 5 ≤ 12 by decide`

<a id="Nat___decLt"></a>

**def**

```text
Nat.decLt (n m : Nat) : Decidable (n < m)
```

A decision procedure for strict inequality of natural numbers, usually accessed via the `DecidableLT Nat` instance.

Examples:

- `(if 3 < 4 then "yes" else "no") = "yes"`
- `(if 4 < 4 then "yes" else "no") = "no"`
- `(if 6 < 4 then "yes" else "no") = "no"`
- `show 5 < 12 by decide`

<a id="nat-api-predicates"></a>
##### 20.1.4.5.3. Predicates

<a id="Nat___le___refl"></a>

**inductive predicate**

```text
Nat.le (n : Nat) : Nat → Prop
```

Non-strict, or weak, inequality of natural numbers, usually accessed via the `≤` operator.

**Constructors**

```text
Nat.le.refl {n : Nat} : n.le n
```

Non-strict inequality is reflexive: `n ≤ n`

```text
Nat.le.step {n m : Nat} : n.le m → n.le m.succ
```

If `n ≤ m`, then `n ≤ m + 1`.

<a id="Nat___lt"></a>

**def**

```text
Nat.lt (n m : Nat) : Prop
```

Strict inequality of natural numbers, usually accessed via the `<` operator.

It is defined as `n < m = n + 1 ≤ m`.

<a id="nat-api-iteration"></a>
#### 20.1.4.6. Iteration

Many iteration operators come in two versions: a structurally recursive version and a tail-recursive version. The structurally recursive version is typically easier to use in contexts where definitional equality is important, as it will compute when only some prefix of a natural number is known.

<a id="Nat___repeat"></a>

**def**

```text
Nat.repeat.{u} {α : Type u} (f : α → α) (n : Nat) (a : α) : α
```

Applies a function to a starting value the specified number of times.

In other words, `f` is iterated `n` times on `a`.

Examples:

- `Nat.repeat f 3 a = f <| f <| f <| a`
- `Nat.repeat (· ++ "!") 4 "Hello" = "Hello!!!!"`

<a id="Nat___repeatTR"></a>

**def**

```text
Nat.repeatTR.{u} {α : Type u} (f : α → α) (n : Nat) (a : α) : α
```

Applies a function to a starting value the specified number of times.

In other words, `f` is iterated `n` times on `a`.

This is a tail-recursive version of `Nat.repeat` that's used at runtime.

Examples:

- `Nat.repeatTR f 3 a = f <| f <| f <| a`
- `Nat.repeatTR (· ++ "!") 4 "Hello" = "Hello!!!!"`

<a id="Nat___fold"></a>

**def**

```text
Nat.fold.{u} {α : Type u} (n : Nat) (f : (i : Nat) → i < n → α → α)
  (init : α) : α
```

Iterates the application of a function `f` to a starting value `init`, `n` times. At each step, `f` is applied to the current value and to the next natural number less than `n`, in increasing order.

Examples:

- `Nat.fold 3 f init = (init |> f 0 (by simp) |> f 1 (by simp) |> f 2 (by simp))`
- `Nat.fold 4 (fun i _ xs => xs.push i) #[] = #[0, 1, 2, 3]`
- `Nat.fold 0 (fun i _ xs => xs.push i) #[] = #[]`

<a id="Nat___foldTR"></a>

**def**

```text
Nat.foldTR.{u} {α : Type u} (n : Nat) (f : (i : Nat) → i < n → α → α)
  (init : α) : α
```

Iterates the application of a function `f` to a starting value `init`, `n` times. At each step, `f` is applied to the current value and to the next natural number less than `n`, in increasing order.

This is a tail-recursive version of `Nat.fold` that's used at runtime.

Examples:

- `Nat.foldTR 3 f init = (init |> f 0 (by simp) |> f 1 (by simp) |> f 2 (by simp))`
- `Nat.foldTR 4 (fun i _ xs => xs.push i) #[] = #[0, 1, 2, 3]`
- `Nat.foldTR 0 (fun i _ xs => xs.push i) #[] = #[]`

<a id="Nat___foldM"></a>

**def**

```text
Nat.foldM.{u, v} {α : Type u} {m : Type u → Type v} [Monad m] (n : Nat)
  (f : (i : Nat) → i < n → α → m α) (init : α) : m α
```

Iterates the application of a monadic function `f` to a starting value `init`, `n` times. At each step, `f` is applied to the current value and to the next natural number less than `n`, in increasing order.

<a id="Nat___foldRev"></a>

**def**

```text
Nat.foldRev.{u} {α : Type u} (n : Nat) (f : (i : Nat) → i < n → α → α)
  (init : α) : α
```

Iterates the application of a function `f` to a starting value `init`, `n` times. At each step, `f` is applied to the current value and to the next natural number less than `n`, in decreasing order.

Examples:

- `Nat.foldRev 3 f init = (f 0 (by simp) <| f 1 (by simp) <| f 2 (by simp) init)`
- `Nat.foldRev 4 (fun i _ xs => xs.push i) #[] = #[3, 2, 1, 0]`
- `Nat.foldRev 0 (fun i _ xs => xs.push i) #[] = #[]`

<a id="Nat___foldRevM"></a>

**def**

```text
Nat.foldRevM.{u, v} {α : Type u} {m : Type u → Type v} [Monad m]
  (n : Nat) (f : (i : Nat) → i < n → α → m α) (init : α) : m α
```

Iterates the application of a monadic function `f` to a starting value `init`, `n` times. At each step, `f` is applied to the current value and to the next natural number less than `n`, in decreasing order.

<a id="Nat___forM"></a>

**def**

```text
Nat.forM.{u_1} {m : Type → Type u_1} [Monad m] (n : Nat)
  (f : (i : Nat) → i < n → m Unit) : m Unit
```

Executes a monadic action on all the numbers less than some bound, in increasing order.

Example:

```proofscript
#eval Nat.forM 5 fun i _ => IO.println i
```

```proofscript
0
1
2
3
4
```

<a id="Nat___forRevM"></a>

**def**

```text
Nat.forRevM.{u_1} {m : Type → Type u_1} [Monad m] (n : Nat)
  (f : (i : Nat) → i < n → m Unit) : m Unit
```

Executes a monadic action on all the numbers less than some bound, in decreasing order.

Example:

```proofscript
#eval Nat.forRevM 5 fun i _ => IO.println i
```

```proofscript
4
3
2
1
0
```

<a id="Nat___all"></a>

**def**

```text
Nat.all (n : Nat) (f : (i : Nat) → i < n → Bool) : Bool
```

Checks whether `f` returns `true` for every number strictly less than a bound.

Examples:

- `Nat.all 4 (fun i _ => i < 5) = true`
- `Nat.all 7 (fun i _ => i < 5) = false`
- `Nat.all 7 (fun i _ => i % 2 = 0) = false`
- `Nat.all 1 (fun i _ => i % 2 = 0) = true`

<a id="Nat___allTR"></a>

**def**

```text
Nat.allTR (n : Nat) (f : (i : Nat) → i < n → Bool) : Bool
```

Checks whether `f` returns `true` for every number strictly less than a bound.

This is a tail-recursive equivalent of `Nat.all` that's used at runtime.

Examples:

- `Nat.allTR 4 (fun i _ => i < 5) = true`
- `Nat.allTR 7 (fun i _ => i < 5) = false`
- `Nat.allTR 7 (fun i _ => i % 2 = 0) = false`
- `Nat.allTR 1 (fun i _ => i % 2 = 0) = true`

<a id="Nat___any"></a>

**def**

```text
Nat.any (n : Nat) (f : (i : Nat) → i < n → Bool) : Bool
```

Checks whether there is some number less that the given bound for which `f` returns `true`.

Examples:

- `Nat.any 4 (fun i _ => i < 5) = true`
- `Nat.any 7 (fun i _ => i < 5) = true`
- `Nat.any 7 (fun i _ => i % 2 = 0) = true`
- `Nat.any 1 (fun i _ => i % 2 = 1) = false`

<a id="Nat___anyTR"></a>

**def**

```text
Nat.anyTR (n : Nat) (f : (i : Nat) → i < n → Bool) : Bool
```

Checks whether there is some number less that the given bound for which `f` returns `true`.

This is a tail-recursive equivalent of `Nat.any` that's used at runtime.

Examples:

- `Nat.anyTR 4 (fun i _ => i < 5) = true`
- `Nat.anyTR 7 (fun i _ => i < 5) = true`
- `Nat.anyTR 7 (fun i _ => i % 2 = 0) = true`
- `Nat.anyTR 1 (fun i _ => i % 2 = 1) = false`

<a id="Nat___allM"></a>

**def**

```text
Nat.allM.{u_1} {m : Type → Type u_1} [Monad m] (n : Nat)
  (p : (i : Nat) → i < n → m Bool) : m Bool
```

Checks whether the monadic predicate `p` returns `true` for all numbers less that the given bound. Numbers are checked in increasing order until `p` returns false, after which no further are checked.

<a id="Nat___anyM"></a>

**def**

```text
Nat.anyM.{u_1} {m : Type → Type u_1} [Monad m] (n : Nat)
  (p : (i : Nat) → i < n → m Bool) : m Bool
```

Checks whether there is some number less that the given bound for which the monadic predicate `p` returns `true`. Numbers are checked in increasing order until `p` returns true, after which no further are checked.

<a id="nat-api-conversion"></a>
#### 20.1.4.7. Conversion

<a id="Nat___toUInt8"></a>

**def**

```text
Nat.toUInt8 (n : Nat) : UInt8
```

Converts a natural number to an 8-bit unsigned integer, wrapping on overflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Nat.toUInt8 5 = 5`
- `Nat.toUInt8 255 = 255`
- `Nat.toUInt8 256 = 0`
- `Nat.toUInt8 259 = 3`
- `Nat.toUInt8 32770 = 2`

<a id="Nat___toUInt16"></a>

**def**

```text
Nat.toUInt16 (n : Nat) : UInt16
```

Converts a natural number to a 16-bit unsigned integer, wrapping on overflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Nat.toUInt16 5 = 5`
- `Nat.toUInt16 255 = 255`
- `Nat.toUInt16 32770 = 32770`
- `Nat.toUInt16 65537 = 1`

<a id="Nat___toUInt32"></a>

**def**

```text
Nat.toUInt32 (n : Nat) : UInt32
```

Converts a natural number to a 32-bit unsigned integer, wrapping on overflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Nat.toUInt32 5 = 5`
- `Nat.toUInt32 65_539 = 65_539`
- `Nat.toUInt32 4_294_967_299 = 3`

<a id="Nat___toUInt64"></a>

**def**

```text
Nat.toUInt64 (n : Nat) : UInt64
```

Converts a natural number to a 64-bit unsigned integer, wrapping on overflow.

This function is overridden at runtime with an efficient implementation.

Examples:

- `Nat.toUInt64 5 = 5`
- `Nat.toUInt64 65539 = 65539`
- `Nat.toUInt64 4_294_967_299 = 4_294_967_299`
- `Nat.toUInt64 18_446_744_073_709_551_620 = 4`

<a id="Nat___toUSize"></a>

**def**

```text
Nat.toUSize (n : Nat) : USize
```

Converts an arbitrary-precision natural number to an unsigned word-sized integer, wrapping around on overflow.

This function is overridden at runtime with an efficient implementation.

<a id="Nat___toInt8"></a>

**def**

```text
Nat.toInt8 (n : Nat) : Int8
```

Converts a natural number to an 8-bit signed integer, wrapping around to negative numbers on overflow.

Examples:

- `Nat.toInt8 53 = 53`
- `Nat.toInt8 127 = 127`
- `Nat.toInt8 128 = -128`
- `Nat.toInt8 255 = -1`

<a id="Nat___toInt16"></a>

**def**

```text
Nat.toInt16 (n : Nat) : Int16
```

Converts a natural number to a 16-bit signed integer, wrapping around to negative numbers on overflow.

Examples:

- `Nat.toInt16 127 = 127`
- `Nat.toInt16 32767 = 32767`
- `Nat.toInt16 32768 = -32768`
- `Nat.toInt16 32770 = -32766`

<a id="Nat___toInt32"></a>

**def**

```text
Nat.toInt32 (n : Nat) : Int32
```

Converts a natural number to a 32-bit signed integer, wrapping around to negative numbers on overflow.

Examples:

- `Nat.toInt32 127 = 127`
- `Nat.toInt32 32770 = 32770`
- `Nat.toInt32 2_147_483_647 = 2_147_483_647`
- `Nat.toInt32 2_147_483_648 = -2_147_483_648`

<a id="Nat___toInt64"></a>

**def**

```text
Nat.toInt64 (n : Nat) : Int64
```

Converts a natural number to a 64-bit signed integer, wrapping around to negative numbers on overflow.

Examples:

- `Nat.toInt64 127 = 127`
- `Nat.toInt64 2_147_483_648 = 2_147_483_648`
- `Nat.toInt64 9_223_372_036_854_775_807 = 9_223_372_036_854_775_807`
- `Nat.toInt64 9_223_372_036_854_775_808 = -9_223_372_036_854_775_808`
- `Nat.toInt64 18_446_744_073_709_551_618 = 0`

<a id="Nat___toISize"></a>

**def**

```text
Nat.toISize (n : Nat) : ISize
```

Converts an arbitrary-precision natural number to a word-sized signed integer, wrapping around on overflow.

This function is overridden at runtime with an efficient implementation.

<a id="Nat___toFloat"></a>

**def**

```text
Nat.toFloat (n : Nat) : Float
```

Converts a natural number into the closest-possible 64-bit floating-point number, or an infinite floating-point value if the range of `Float` is exceeded.

<a id="Nat___toFloat32"></a>

**def**

```text
Nat.toFloat32 (n : Nat) : Float32
```

Converts a natural number into the closest-possible 32-bit floating-point number, or an infinite floating-point value if the range of `Float32` is exceeded.

<a id="Nat___isValidChar"></a>

**def**

```text
Nat.isValidChar (n : Nat) : Prop
```

A `Nat` denotes a valid Unicode code point if it is less than `0x110000` and it is also not a surrogate code point (the range `0xd800` to `0xdfff` inclusive).

<a id="Nat___repr"></a>

**def**

```text
Nat.repr (n : Nat) : String
```

Converts a natural number to its decimal string representation.

<a id="Nat___toDigits"></a>

**def**

```text
Nat.toDigits (base n : Nat) : List Char
```

Returns the decimal representation of a natural number as a list of digit characters in the given base. If the base is greater than `16` then `'*'` is returned for digits greater than `0xf`.

Examples:

- `Nat.toDigits 10 0xff = ['2', '5', '5']`
- `Nat.toDigits 8 0xc = ['1', '4']`
- `Nat.toDigits 16 0xcafe = ['c', 'a', 'f', 'e']`
- `Nat.toDigits 80 200 = ['2', '*']`

<a id="Nat___digitChar"></a>

**def**

```text
Nat.digitChar (n : Nat) : Char
```

Returns a single digit representation of `n`, which is assumed to be in a base less than or equal to `16`. Returns `'*'` if `n > 15`.

Examples:

- `Nat.digitChar 5 = '5'`
- `Nat.digitChar 12 = 'c'`
- `Nat.digitChar 15 = 'f'`
- `Nat.digitChar 16 = '*'`
- `Nat.digitChar 85 = '*'`

<a id="Nat___toSubscriptString"></a>

**def**

```text
Nat.toSubscriptString (n : Nat) : String
```

Converts a natural number to a string that contains the its decimal representation as Unicode subscript digit characters.

Examples:

- `Nat.toSubscriptString 0 = "₀"`
- `Nat.toSubscriptString 35 = "₃₅"`

<a id="Nat___toSuperscriptString"></a>

**def**

```text
Nat.toSuperscriptString (n : Nat) : String
```

Converts a natural number to a string that contains the its decimal representation as Unicode superscript digit characters.

Examples:

- `Nat.toSuperscriptString 0 = "⁰"`
- `Nat.toSuperscriptString 35 = "³⁵"`

<a id="Nat___toSuperDigits"></a>

**def**

```text
Nat.toSuperDigits (n : Nat) : List Char
```

Converts a natural number to the list of Unicode superscript digit characters that corresponds to its decimal representation.

Examples:

- `Nat.toSuperDigits 0 = ['⁰']`
- `Nat.toSuperDigits 35 = ['³', '⁵']`

<a id="Nat___toSubDigits"></a>

**def**

```text
Nat.toSubDigits (n : Nat) : List Char
```

Converts a natural number to the list of Unicode subscript digit characters that corresponds to its decimal representation.

Examples:

- `Nat.toSubDigits 0 = ['₀']`
- `Nat.toSubDigits 35 = ['₃', '₅']`

<a id="Nat___subDigitChar"></a>

**def**

```text
Nat.subDigitChar (n : Nat) : Char
```

Converts a natural number less than `10` to the corresponding Unicode subscript digit character. Returns `'*'` for other numbers.

Examples:

- `Nat.subDigitChar 3 = '₃'`
- `Nat.subDigitChar 7 = '₇'`
- `Nat.subDigitChar 10 = '*'`

<a id="Nat___superDigitChar"></a>

**def**

```text
Nat.superDigitChar (n : Nat) : Char
```

Converts a natural number less than `10` to the corresponding Unicode superscript digit character. Returns `'*'` for other numbers.

Examples:

- `Nat.superDigitChar 3 = '³'`
- `Nat.superDigitChar 7 = '⁷'`
- `Nat.superDigitChar 10 = '*'`

<a id="nat-api-elim"></a>
#### 20.1.4.8. Elimination

The recursion principle that is automatically generated for `Nat` results in proof goals that are phrased in terms of `Nat.zero` and `Nat.succ`. This is not particularly user-friendly, so an alternative logically-equivalent recursion principle is provided that results in goals that are phrased in terms of `0` and `n + 1`. [Custom eliminators](../../Tactic-Proofs/Tactic-Reference/index.md#--tech-term-Custom-eliminators) for the `induction` and `cases` tactics can be supplied using the `induction_eliminator` and `cases_eliminator` attributes.

<a id="Nat___recAux"></a>

**def**

```text
Nat.recAux.{u} {motive : Nat → Sort u} (zero : motive 0)
  (succ : (n : Nat) → motive n → motive (n + 1)) (t : Nat) : motive t
```

A recursor for `Nat` that uses the notations `0` for `Nat.zero` and `n + 1` for `Nat.succ`.

It is otherwise identical to the default recursor `Nat.rec`. It is used by the `induction` tactic by default for `Nat`.

<a id="Nat___casesAuxOn"></a>

**def**

```text
Nat.casesAuxOn.{u} {motive : Nat → Sort u} (t : Nat) (zero : motive 0)
  (succ : (n : Nat) → motive (n + 1)) : motive t
```

A case analysis principle for `Nat` that uses the notations `0` for `Nat.zero` and `n + 1` for `Nat.succ`.

It is otherwise identical to the default recursor `Nat.casesOn`. It is used as the default `Nat` case analysis principle for `Nat` by the `cases` tactic.

<a id="nat-api-induction"></a>
##### 20.1.4.8.1. Alternative Induction Principles

<a id="Nat___strongRecOn"></a>

**def**

```text
Nat.strongRecOn.{u} {motive : Nat → Sort u} (n : Nat)
  (ind : (n : Nat) → ((m : Nat) → m < n → motive m) → motive n) :
  motive n
```

Strong induction on the natural numbers.

The induction hypothesis is that all numbers less than a given number satisfy the motive, which should be demonstrated for the given number.

<a id="Nat___caseStrongRecOn"></a>

**def**

```text
Nat.caseStrongRecOn.{u} {motive : Nat → Sort u} (a : Nat)
  (zero : motive 0)
  (ind : (n : Nat) → ((m : Nat) → m ≤ n → motive m) → motive n.succ) :
  motive a
```

Case analysis based on strong induction for the natural numbers.

<a id="Nat___div___inductionOn"></a>

**def**

```text
Nat.div.inductionOn.{u} {motive : Nat → Nat → Sort u} (x y : Nat)
  (ind : (x y : Nat) → 0 < y ∧ y ≤ x → motive (x - y) y → motive x y)
  (base : (x y : Nat) → ¬(0 < y ∧ y ≤ x) → motive x y) : motive x y
```

An induction principle customized for reasoning about the recursion pattern of natural number division by iterated subtraction.

<a id="Nat___div2Induction"></a>

**def**

```text
Nat.div2Induction.{u} {motive : Nat → Sort u} (n : Nat)
  (ind : (n : Nat) → (n > 0 → motive (n / 2)) → motive n) : motive n
```

An induction principle for the natural numbers with two cases:

- `n = 0`, and the motive is satisfied for `0`
- `n > 0`, and the motive should be satisfied for `n` on the assumption that it is satisfied for `n / 2`.

<a id="Nat___mod___inductionOn"></a>

**def**

```text
Nat.mod.inductionOn.{u} {motive : Nat → Nat → Sort u} (x y : Nat)
  (ind : (x y : Nat) → 0 < y ∧ y ≤ x → motive (x - y) y → motive x y)
  (base : (x y : Nat) → ¬(0 < y ∧ y ≤ x) → motive x y) : motive x y
```

An induction principle customized for reasoning about the recursion pattern of `Nat.mod`.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
0
1
2
3
4
```


### Display 2


```text
4
3
2
1
0
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
i:Natn:Nat⊢ n < n + 1
```


### Display 2


```text
zeroi:Nat⊢ 0 < 0 + 1
```


### Display 3


```text
zeroi:Nat⊢ 0 < 1
```


### Display 4


```text
All goals completed! 🐙
```


### Display 5


```text
succi✝:Nati:Natih:i < i + 1⊢ i + 1 < i + 1 + 1
```

