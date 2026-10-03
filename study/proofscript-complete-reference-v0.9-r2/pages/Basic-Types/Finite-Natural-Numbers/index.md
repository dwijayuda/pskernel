<a id="Fin"></a>

# ProofScript — 20.3. Finite Natural Numbers

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Finite-Natural-Numbers/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Finite-Natural-Numbers/index.html). Source Git blob: `834fd49f7fdc3dc06d87a835aa161aba81a12ea7`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.3. Finite Natural Numbers

For any [natural number](../Natural-Numbers/index.md#--tech-term-natural-numbers) `n`, the `Fin n` is a type that contains all the natural numbers that are strictly less than `n`. In other words, `Fin n` has exactly `n` elements. It can be used to represent the valid indices into a list or array, or it can serve as a canonical `n`-element type.

<a id="Fin___mk"></a>

**structure**

```text
Fin (n : Nat) : Type
```

Natural numbers less than some upper bound.

In particular, a `Fin n` is a natural number `i` with the constraint that `i < n`. It is the canonical type with `n` elements.

**Constructor**

```text
Fin.mk
```

Creates a `Fin n` from `i : Nat` and a proof that `i < n`.

**Fields**

```text
val : Nat
```

The number that is strictly less than `n`.

`Fin.val` is a coercion, so any `Fin n` can be used in a position where a `Nat` is expected.

```text
isLt : ↑self < n
```

The number `val` is strictly less than the bound `n`.

`Fin` is closely related to `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `USize`, which also represent finite non-negative integral types. However, these types are backed by bitvectors rather than by natural numbers, and they have fixed bounds. `Fin` is comparatively more flexible, but also less convenient for low-level reasoning. In particular, using bitvectors rather than proofs that a number is less than some power of two avoids needing to take care to avoid evaluating the concrete bound.

<a id="The-Lean-Language-Reference--Basic-Types--Finite-Natural-Numbers--Run-Time-Characteristics"></a>
### 20.3.1. Run-Time Characteristics

Because `Fin n` is a structure in which only a single field is not a proof, it is a [trivial wrapper](../../The-Type-System/Inductive-Types/index.md#inductive-types-trivial-wrappers). This means that it is represented identically to the underlying natural number in compiled code.

<a id="The-Lean-Language-Reference--Basic-Types--Finite-Natural-Numbers--Coercions-and-Literals"></a>
### 20.3.2. Coercions and Literals

There is a [coercion](../../Coercions/index.md#--tech-term-coercion) from `Fin n` to `Nat` that discards the proof that the number is less than the bound. In particular, this coercion is precisely the projection `Fin.val`. One consequence of this is that uses of `Fin.val` are displayed as coercions rather than explicit projections in proof states.

<a id="Coercing-from--Fin--to--Nat"></a>
Coercing from `Fin` to `Nat` 

A `Fin n` can be used where a `Nat` is expected:

```proofscript
#eval let one : Fin 3 := ⟨1, by omega⟩; (one : Nat)
```

```lean
1
```

Uses of `Fin.val` show up as coercions in proof states:

Natural number literals may be used for `Fin` types, implemented as usual via an `OfNat` instance. The `OfNat` instance for `Fin n` requires that the upper bound `n` is not zero, but does not check that the literal is less than `n`. If the literal is larger than the type can represent, the remainder when dividing it by `n` is used.

<a id="Numeric-Literals-for--Fin"></a>
Numeric Literals for `Fin` 

If `n > 0`, then natural number literals can be used for `Fin n`:

```proofscript
example : Fin 5 := 3
example : Fin 20 := 19
```

When the literal is greater than or equal to `n`, the remainder when dividing by `n` is used:

```proofscript
#eval (5 : Fin 3)
```

```lean
2
```

```proofscript
#eval ([0, 1, 2, 3, 4, 5, 6] : List (Fin 3))
```

```lean
[0, 1, 2, 0, 1, 2, 0]
```

If Lean can't synthesize an instance of `NeZero n`, then there is no `OfNat (Fin n)` instance:

```proofscript
example : Fin 0 := 0
```

```lean
failed to synthesize instance of type class
  OfNat (Fin 0) 0
numerals are polymorphic in Lean, but the numeral `0` cannot be used in a context where the expected type is
  Fin 0
due to the absence of the instance above

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

```proofscript
example (k : Nat) : Fin k := 0
```

```lean
failed to synthesize instance of type class
  OfNat (Fin k) 0
numerals are polymorphic in Lean, but the numeral `0` cannot be used in a context where the expected type is
  Fin k
due to the absence of the instance above

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

<a id="The-Lean-Language-Reference--Basic-Types--Finite-Natural-Numbers--API-Reference"></a>
### 20.3.3. API Reference

<a id="The-Lean-Language-Reference--Basic-Types--Finite-Natural-Numbers--API-Reference--Construction"></a>
#### 20.3.3.1. Construction

<a id="Fin___last"></a>

**def**

```text
Fin.last (n : Nat) : Fin (n + 1)
```

The greatest value of `Fin (n+1)`, namely `n`.

Examples:

- `Fin.last 4 = (4 : Fin 5)`
- `(Fin.last 0).val = (0 : Nat)`

<a id="Fin___succ"></a>

**def**

```text
Fin.succ {n : Nat} : Fin n → Fin (n + 1)
```

The successor, with an increased bound.

This differs from adding `1`, which instead wraps around.

Examples:

- `(2 : Fin 3).succ = (3 : Fin 4)`
- `(2 : Fin 3) + 1 = (0 : Fin 3)`

<a id="Fin___pred"></a>

**def**

```text
Fin.pred {n : Nat} (i : Fin (n + 1)) (h : i ≠ 0) : Fin n
```

The predecessor of a non-zero element of `Fin (n+1)`, with the bound decreased.

Examples:

- `(4 : Fin 8).pred (by decide) = (3 : Fin 7)`
- `(1 : Fin 2).pred (by decide) = (0 : Fin 1)`

<a id="The-Lean-Language-Reference--Basic-Types--Finite-Natural-Numbers--API-Reference--Arithmetic"></a>
#### 20.3.3.2. Arithmetic

Typically, arithmetic operations on `Fin` should be accessed using Lean's overloaded arithmetic notation, particularly via the instances `Add (Fin n)`, `Sub (Fin n)`, `Mul (Fin n)`, `Div (Fin n)`, and `Mod (Fin n)`. Heterogeneous operators such as `Fin.natAdd` do not have corresponding heterogeneous instances (e.g. `HAdd`) to avoid confusing type inference behavior.

<a id="Fin___add"></a>

**def**

```text
Fin.add {n : Nat} : Fin n → Fin n → Fin n
```

Addition modulo `n`, usually invoked via the `+` operator.

Examples:

- `(2 : Fin 8) + (2 : Fin 8) = (4 : Fin 8)`
- `(2 : Fin 3) + (2 : Fin 3) = (1 : Fin 3)`

<a id="Fin___natAdd"></a>

**def**

```text
Fin.natAdd {m : Nat} (n : Nat) (i : Fin m) : Fin (n + m)
```

Adds a natural number to a `Fin`, increasing the bound.

This is a generalization of `Fin.succ`.

`Fin.addNat` is a version of this function that takes its `Nat` parameter second.

Examples:

- `Fin.natAdd 3 (5 : Fin 8) = (8 : Fin 11)`
- `Fin.natAdd 1 (0 : Fin 8) = (1 : Fin 9)`
- `Fin.natAdd 1 (2 : Fin 8) = (3 : Fin 9)`

<a id="Fin___addNat"></a>

**def**

```text
Fin.addNat {n : Nat} (i : Fin n) (m : Nat) : Fin (n + m)
```

Adds a natural number to a `Fin`, increasing the bound.

This is a generalization of `Fin.succ`.

`Fin.natAdd` is a version of this function that takes its `Nat` parameter first.

Examples:

- `Fin.addNat (5 : Fin 8) 3 = (8 : Fin 11)`
- `Fin.addNat (0 : Fin 8) 1 = (1 : Fin 9)`
- `Fin.addNat (1 : Fin 8) 2 = (3 : Fin 10)`

<a id="Fin___mul"></a>

**def**

```text
Fin.mul {n : Nat} : Fin n → Fin n → Fin n
```

Multiplication modulo `n`, usually invoked via the `*` operator.

Examples:

- `(2 : Fin 10) * (2 : Fin 10) = (4 : Fin 10)`
- `(2 : Fin 10) * (7 : Fin 10) = (4 : Fin 10)`
- `(3 : Fin 10) * (7 : Fin 10) = (1 : Fin 10)`

<a id="Fin___sub"></a>

**def**

```text
Fin.sub {n : Nat} : Fin n → Fin n → Fin n
```

Subtraction modulo `n`, usually invoked via the `-` operator.

Examples:

- `(5 : Fin 11) - (3 : Fin 11) = (2 : Fin 11)`
- `(3 : Fin 11) - (5 : Fin 11) = (9 : Fin 11)`

<a id="Fin___subNat"></a>

**def**

```text
Fin.subNat {n : Nat} (m : Nat) (i : Fin (n + m)) (h : m ≤ ↑i) : Fin n
```

Subtraction of a natural number from a `Fin`, with the bound narrowed.

This is a generalization of `Fin.pred`. It is guaranteed to not underflow or wrap around.

Examples:

- `(5 : Fin 9).subNat 2 (by decide) = (3 : Fin 7)`
- `(5 : Fin 9).subNat 0 (by decide) = (5 : Fin 9)`
- `(3 : Fin 9).subNat 3 (by decide) = (0 : Fin 6)`

<a id="Fin___div"></a>

**def**

```text
Fin.div {n : Nat} : Fin n → Fin n → Fin n
```

Division of bounded numbers, usually invoked via the `/` operator.

The resulting value is that computed by the `/` operator on `Nat`. In particular, the result of division by `0` is `0`.

Examples:

- `(5 : Fin 10) / (2 : Fin 10) = (2 : Fin 10)`
- `(5 : Fin 10) / (0 : Fin 10) = (0 : Fin 10)`
- `(5 : Fin 10) / (7 : Fin 10) = (0 : Fin 10)`

<a id="Fin___mod"></a>

**def**

```text
Fin.mod {n : Nat} : Fin n → Fin n → Fin n
```

Modulus of bounded numbers, usually invoked via the `%` operator.

The resulting value is that computed by the `%` operator on `Nat`.

<a id="Fin___modn"></a>

**def**

```text
Fin.modn {n : Nat} : Fin n → Nat → Fin n
```

Modulus of bounded numbers with respect to a `Nat`.

The resulting value is that computed by the `%` operator on `Nat`.

<a id="Fin___log2"></a>

**def**

```text
Fin.log2 {m : Nat} (n : Fin m) : Fin m
```

Logarithm base 2 for bounded numbers.

The resulting value is the same as that computed by `Nat.log2`. In particular, the result for `0` is `0`.

Examples:

- `(8 : Fin 10).log2 = (3 : Fin 10)`
- `(7 : Fin 10).log2 = (2 : Fin 10)`
- `(4 : Fin 10).log2 = (2 : Fin 10)`
- `(3 : Fin 10).log2 = (1 : Fin 10)`
- `(1 : Fin 10).log2 = (0 : Fin 10)`
- `(0 : Fin 10).log2 = (0 : Fin 10)`

<a id="The-Lean-Language-Reference--Basic-Types--Finite-Natural-Numbers--API-Reference--Bitwise-Operations"></a>
#### 20.3.3.3. Bitwise Operations

<a id="Fin___shiftLeft"></a>

**def**

```text
Fin.shiftLeft {n : Nat} : Fin n → Fin n → Fin n
```

Bitwise left shift of bounded numbers, with wraparound on overflow.

Examples:

- `(1 : Fin 10) <<< (1 : Fin 10) = (2 : Fin 10)`
- `(1 : Fin 10) <<< (3 : Fin 10) = (8 : Fin 10)`
- `(1 : Fin 10) <<< (4 : Fin 10) = (6 : Fin 10)`

<a id="Fin___shiftRight"></a>

**def**

```text
Fin.shiftRight {n : Nat} : Fin n → Fin n → Fin n
```

Bitwise right shift of bounded numbers.

This operator corresponds to logical rather than arithmetic bit shifting. The new bits are always `0`.

Examples:

- `(15 : Fin 16) >>> (1 : Fin 16) = (7 : Fin 16)`
- `(15 : Fin 16) >>> (2 : Fin 16) = (3 : Fin 16)`
- `(15 : Fin 17) >>> (2 : Fin 17) = (3 : Fin 17)`

<a id="Fin___land"></a>

**def**

```text
Fin.land {n : Nat} : Fin n → Fin n → Fin n
```

Bitwise and.

<a id="Fin___lor"></a>

**def**

```text
Fin.lor {n : Nat} : Fin n → Fin n → Fin n
```

Bitwise or.

<a id="Fin___xor"></a>

**def**

```text
Fin.xor {n : Nat} : Fin n → Fin n → Fin n
```

Bitwise xor (“exclusive or”).

<a id="The-Lean-Language-Reference--Basic-Types--Finite-Natural-Numbers--API-Reference--Conversions"></a>
#### 20.3.3.4. Conversions

<a id="Fin___toNat"></a>

**def**

```text
Fin.toNat {n : Nat} (i : Fin n) : Nat
```

Extracts the underlying `Nat` value.

This function is a synonym for `Fin.val`, which is the simp normal form. `Fin.val` is also a coercion, so values of type `Fin n` are automatically converted to `Nat`s as needed.

<a id="Fin___ofNat"></a>

**def**

```text
Fin.ofNat (n : Nat) [NeZero n] (a : Nat) : Fin n
```

Returns `a` modulo `n` as a `Fin n`.

The assumption `NeZero n` ensures that `Fin n` is nonempty.

<a id="Fin___cast"></a>

**def**

```text
Fin.cast {n m : Nat} (eq : n = m) (i : Fin n) : Fin m
```

Uses a proof that two bounds are equal to allow a value bounded by one to be used with the other.

In other words, when `eq : n = m`, `Fin.cast eq i` converts `i : Fin n` into a `Fin m`.

<a id="Fin___castLT"></a>

**def**

```text
Fin.castLT {n m : Nat} (i : Fin m) (h : ↑i < n) : Fin n
```

Replaces the bound with another that is suitable for the value.

The proof embedded in `i` can be used to cast to a larger bound even if the concrete value is not known.

Examples:

```proofscript
example : Fin 12 := (7 : Fin 10).castLT (by decide : 7 < 12)
```

```proofscript
example (i : Fin 10) : Fin 12 :=
  i.castLT <| by
    cases i; simp; omega
```

<a id="Fin___castLE"></a>

**def**

```text
Fin.castLE {n m : Nat} (h : n ≤ m) (i : Fin n) : Fin m
```

Coarsens a bound to one at least as large.

See also `Fin.castAdd` for a version that represents the larger bound with addition rather than an explicit inequality proof.

<a id="Fin___castAdd"></a>

**def**

```text
Fin.castAdd {n : Nat} (m : Nat) : Fin n → Fin (n + m)
```

Coarsens a bound to one at least as large.

See also `Fin.natAdd` and `Fin.addNat` for addition functions that increase the bound, and `Fin.castLE` for a version that uses an explicit inequality proof.

<a id="Fin___castSucc"></a>

**def**

```text
Fin.castSucc {n : Nat} : Fin n → Fin (n + 1)
```

Coarsens a bound by one.

<a id="Fin___rev"></a>

**def**

```text
Fin.rev {n : Nat} (i : Fin n) : Fin n
```

Replaces a value with its difference from the largest value in the type.

Considering the values of `Fin n` as a sequence `0`, `1`, …, `n-2`, `n-1`, `Fin.rev` finds the corresponding element of the reversed sequence. In other words, it maps `0` to `n-1`, `1` to `n-2`, ..., and `n-1` to `0`.

Examples:

- `(5 : Fin 6).rev = (0 : Fin 6)`
- `(0 : Fin 6).rev = (5 : Fin 6)`
- `(2 : Fin 5).rev = (2 : Fin 5)`

<a id="Fin___elim0"></a>

**def**

```text
Fin.elim0.{u} {α : Sort u} : Fin 0 → α
```

The type `Fin 0` is uninhabited, so it can be used to derive any result whatsoever.

This is similar to `Empty.elim`. It can be thought of as a compiler-checked assertion that a code path is unreachable, or a logical contradiction from which `False` and thus anything else could be derived.

<a id="The-Lean-Language-Reference--Basic-Types--Finite-Natural-Numbers--API-Reference--Iteration"></a>
#### 20.3.3.5. Iteration

<a id="Fin___foldr"></a>

**def**

```text
Fin.foldr.{u_1} {α : Sort u_1} (n : Nat) (f : Fin n → α → α)
  (init : α) : α
```

Combine all the values that can be represented by `Fin n` with an initial value, starting at `n - 1` and nesting to the right.

Example:

- `Fin.foldr 3 (·.val + ·) (0 : Nat) = (0 : Fin 3).val + ((1 : Fin 3).val + ((2 : Fin 3).val + 0))`

<a id="Fin___foldrM"></a>

**def**

```text
Fin.foldrM.{u_1, u_2} {m : Type u_1 → Type u_2} {α : Type u_1} [Monad m]
  (n : Nat) (f : Fin n → α → m α) (init : α) : m α
```

Folds a monadic function over `Fin n` from right to left, starting with `n-1`.

It is the sequence of steps:

```text
Fin.foldrM n f xₙ = do
  let xₙ₋₁ ← f (n-1) xₙ
  let xₙ₋₂ ← f (n-2) xₙ₋₁
  ...
  let x₀ ← f 0 x₁
  pure x₀
```

<a id="Fin___foldl"></a>

**def**

```text
Fin.foldl.{u_1} {α : Sort u_1} (n : Nat) (f : α → Fin n → α)
  (init : α) : α
```

Combine all the values that can be represented by `Fin n` with an initial value, starting at `0` and nesting to the left.

Example:

- `Fin.foldl 3 (· + ·.val) (0 : Nat) = ((0 + (0 : Fin 3).val) + (1 : Fin 3).val) + (2 : Fin 3).val`

<a id="Fin___foldlM"></a>

**def**

```text
Fin.foldlM.{u_1, u_2} {m : Type u_1 → Type u_2} {α : Type u_1} [Monad m]
  (n : Nat) (f : α → Fin n → m α) (init : α) : m α
```

Folds a monadic function over all the values in `Fin n` from left to right, starting with `0`.

It is the sequence of steps:

```text
Fin.foldlM n f x₀ = do
  let x₁ ← f x₀ 0
  let x₂ ← f x₁ 1
  ...
  let xₙ ← f xₙ₋₁ (n-1)
  pure xₙ
```

<a id="Fin___hIterate"></a>

**def**

```text
Fin.hIterate.{u_1} (P : Nat → Sort u_1) {n : Nat} (init : P 0)
  (f : (i : Fin n) → P ↑i → P (↑i + 1)) : P n
```

Applies an index-dependent function to all the values less than the given bound `n`, starting at `0` with an accumulator.

Concretely, `Fin.hIterate P init f` is equal to

```text
  init |> f 0 |> f 1 |> ... |> f (n-1)
```

Theorems about `Fin.hIterate` can be proven using the general theorem `Fin.hIterate_elim` or other more specialized theorems.

`Fin.hIterateFrom` is a variant that takes a custom starting value instead of `0`.

<a id="Fin___hIterateFrom"></a>

**def**

```text
Fin.hIterateFrom.{u_1} (P : Nat → Sort u_1) {n : Nat}
  (f : (i : Fin n) → P ↑i → P (↑i + 1)) (i : Nat) (ubnd : i ≤ n)
  (a : P i) : P n
```

Applies an index-dependent function `f` to all of the values in `[i:n]`, starting at `i` with an initial accumulator `a`.

Concretely, `Fin.hIterateFrom P f i a` is equal to

```text
  a |> f i |> f (i + 1) |> ... |> f (n - 1)
```

Theorems about `Fin.hIterateFrom` can be proven using the general theorem `Fin.hIterateFrom_elim` or other more specialized theorems.

`Fin.hIterate` is a variant that always starts at `0`.

<a id="The-Lean-Language-Reference--Basic-Types--Finite-Natural-Numbers--API-Reference--Reasoning"></a>
#### 20.3.3.6. Reasoning

<a id="Fin___induction"></a>

**def**

```text
Fin.induction.{u_1} {n : Nat} {motive : Fin (n + 1) → Sort u_1}
  (zero : motive 0)
  (succ : (i : Fin n) → motive i.castSucc → motive i.succ)
  (i : Fin (n + 1)) : motive i
```

Proves a statement by induction on the underlying `Nat` value in a `Fin (n + 1)`.

For the induction:

- `zero` is the base case, demonstrating `motive 0`.
- `succ` is the inductive step, assuming the motive for `i : Fin n` (lifted to `Fin (n + 1)` with `Fin.castSucc`) and demonstrating it for `i.succ`.

`Fin.inductionOn` is a version of this induction principle that takes the `Fin` as its first parameter, `Fin.cases` is the corresponding case analysis operator, and `Fin.reverseInduction` is a version that starts at the greatest value instead of `0`.

<a id="Fin___inductionOn"></a>

**def**

```text
Fin.inductionOn.{u_1} {n : Nat} (i : Fin (n + 1))
  {motive : Fin (n + 1) → Sort u_1} (zero : motive 0)
  (succ : (i : Fin n) → motive i.castSucc → motive i.succ) : motive i
```

Proves a statement by induction on the underlying `Nat` value in a `Fin (n + 1)`.

For the induction:

- `zero` is the base case, demonstrating `motive 0`.
- `succ` is the inductive step, assuming the motive for `i : Fin n` (lifted to `Fin (n + 1)` with `Fin.castSucc`) and demonstrating it for `i.succ`.

`Fin.induction` is a version of this induction principle that takes the `Fin` as its last parameter.

<a id="Fin___reverseInduction"></a>

**def**

```text
Fin.reverseInduction.{u_1} {n : Nat} {motive : Fin (n + 1) → Sort u_1}
  (last : motive (Fin.last n))
  (cast : (i : Fin n) → motive i.succ → motive i.castSucc)
  (i : Fin (n + 1)) : motive i
```

Proves a statement by reverse induction on the underlying `Nat` value in a `Fin (n + 1)`.

For the induction:

- `last` is the base case, demonstrating `motive (Fin.last n)`.
- `cast` is the inductive step, assuming the motive for `(j : Fin n).succ` and demonstrating it for the predecessor `j.castSucc`.

`Fin.induction` is the non-reverse induction principle.

<a id="Fin___cases"></a>

**def**

```text
Fin.cases.{u_1} {n : Nat} {motive : Fin (n + 1) → Sort u_1}
  (zero : motive 0) (succ : (i : Fin n) → motive i.succ)
  (i : Fin (n + 1)) : motive i
```

Proves a statement by cases on the underlying `Nat` value in a `Fin (n + 1)`.

The two cases are:

- `zero`, used when the value is of the form `(0 : Fin (n + 1))`
- `succ`, used when the value is of the form `(j : Fin n).succ`

The corresponding induction principle is `Fin.induction`.

<a id="Fin___lastCases"></a>

**def**

```text
Fin.lastCases.{u_1} {n : Nat} {motive : Fin (n + 1) → Sort u_1}
  (last : motive (Fin.last n)) (cast : (i : Fin n) → motive i.castSucc)
  (i : Fin (n + 1)) : motive i
```

Proves a statement by cases on the underlying `Nat` value in a `Fin (n + 1)`, checking whether the value is the greatest representable or a predecessor of some other.

The two cases are:

- `last`, used when the value is `Fin.last n`
- `cast`, used when the value is of the form `(j : Fin n).succ`

The corresponding induction principle is `Fin.reverseInduction`.

<a id="Fin___addCases"></a>

**def**

```text
Fin.addCases.{u} {m n : Nat} {motive : Fin (m + n) → Sort u}
  (left : (i : Fin m) → motive (Fin.castAdd n i))
  (right : (i : Fin n) → motive (Fin.natAdd m i)) (i : Fin (m + n)) :
  motive i
```

A case analysis operator for `i : Fin (m + n)` that separately handles the cases where `i < m` and where `m ≤ i < m + n`.

The first case, where `i < m`, is handled by `left`. In this case, `i` can be represented as `Fin.castAdd n (j : Fin m)`.

The second case, where `m ≤ i < m + n`, is handled by `right`. In this case, `i` can be represented as `Fin.natAdd m (j : Fin n)`.

<a id="Fin___succRec"></a>

**def**

```text
Fin.succRec.{u_1} {motive : (n : Nat) → Fin n → Sort u_1}
  (zero : (n : Nat) → motive n.succ 0)
  (succ : (n : Nat) → (i : Fin n) → motive n i → motive n.succ i.succ)
  {n : Nat} (i : Fin n) : motive n i
```

An induction principle for `Fin` that considers a given `i : Fin n` as given by a sequence of `i` applications of `Fin.succ`.

The cases in the induction are:

- `zero` demonstrates the motive for `(0 : Fin (n + 1))` for all bounds `n`
- `succ` demonstrates the motive for `Fin.succ` applied to an arbitrary `Fin` for an arbitrary bound `n`

Unlike `Fin.induction`, the motive quantifies over the bound, and the bound varies at each inductive step. `Fin.succRecOn` is a version of this induction principle that takes the `Fin` argument first.

<a id="Fin___succRecOn"></a>

**def**

```text
Fin.succRecOn.{u_1} {n : Nat} (i : Fin n)
  {motive : (n : Nat) → Fin n → Sort u_1}
  (zero : (n : Nat) → motive (n + 1) 0)
  (succ : (n : Nat) → (i : Fin n) → motive n i → motive n.succ i.succ) :
  motive n i
```

An induction principle for `Fin` that considers a given `i : Fin n` as given by a sequence of `i` applications of `Fin.succ`.

The cases in the induction are:

- `zero` demonstrates the motive for `(0 : Fin (n + 1))` for all bounds `n`
- `succ` demonstrates the motive for `Fin.succ` applied to an arbitrary `Fin` for an arbitrary bound `n`

Unlike `Fin.induction`, the motive quantifies over the bound, and the bound varies at each inductive step. `Fin.succRec` is a version of this induction principle that takes the `Fin` argument last.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
1
```


### Display 2


```text
2
```


### Display 3


```text
[0, 1, 2, 0, 1, 2, 0]
```


### Display 4


```text
failed to synthesize instance of type class
  OfNat (Fin 0) 0
numerals are polymorphic in Lean, but the numeral `0` cannot be used in a context where the expected type is
  Fin 0
due to the absence of the instance above

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 5


```text
failed to synthesize instance of type class
  OfNat (Fin k) 0
numerals are polymorphic in Lean, but the numeral `0` cannot be used in a context where the expected type is
  Fin k
due to the absence of the instance above

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
n:Nat⊢ 1 < 3
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
n:Nati:Fin n⊢ ↑i < n
```


### Display 4


```text
⊢ 7 < 12
```


### Display 5


```text
i:Fin 10⊢ ↑i < 12
```


### Display 6


```text
mkval✝:NatisLt✝:val✝ < 10⊢ ↑⟨val✝, isLt✝⟩ < 12
```


### Display 7


```text
mkval✝:NatisLt✝:val✝ < 10⊢ val✝ < 12
```

