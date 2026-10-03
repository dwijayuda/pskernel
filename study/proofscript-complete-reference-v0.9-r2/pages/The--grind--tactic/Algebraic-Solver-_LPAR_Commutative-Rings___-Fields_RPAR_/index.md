<a id="grind-ring"></a>

# ProofScript — 16.10. Algebraic Solver (Commutative Rings, Fields)

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

grind combines reasoning such as congruence closure, propagation, case analysis, E-matching and algebraic/arithmetic procedures. Its selected lemmas, annotations and solver parameters determine the search problem. Keep these as native proof-producing facilities, not as a replacement for the kernel. The mirrored subchapters and examples retain their individual scopes and failure cases.

**Compiler and coverage boundary.** Lean 4.34 stable parameter-list changes for lia/grobner are inherited only under the selected tactic capability. A timeout must remain an incomplete-search result.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--grind--tactic/Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--grind--tactic/Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_/index.html). Source Git blob: `fe6aceb18e5bc92838995ed277b6036164bb6f0f`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 16.10. Algebraic Solver (Commutative Rings, Fields)

The `ring` solver in `grind` is inspired by Gröbner basis computation procedures and term rewriting completion. It views multivariate polynomials as rewriting rules. For example, the polynomial equality `x * y + x - 2 = 0` is treated as a rewriting rule `x * y ↦ -x + 2`. It uses superposition to ensure the rewriting system is confluent.

The following examples demonstrate goals that can be decided by the `ring` solver. In these examples, the `Lean` and `Lean.Grind` namespaces are open:

```proofscript
open Lean Grind
```

<a id="Commutative-Rings"></a>
Commutative Rings 

```proofscript
example [CommRing α] (x : α) : (x + 1) * (x - 1) = x ^ 2 - 1 := by
  grind
```

<a id="Ring-Characteristics"></a>
Ring Characteristics 

The solver “knows” that `16*16 = 0` because the [ring characteristic](https://en.wikipedia.org/wiki/Characteristic_%28algebra%29) (that is, the minimum number of copies of the multiplicative identity that sum to the additive identity) is `256`, which is provided by the `IsCharP` instance.

```proofscript
example [CommRing α] [IsCharP α 256] (x : α) :
    (x + 16)*(x - 16) = x^2 := by
  grind
```

<a id="Standard-Library-Types"></a>
Standard Library Types 

Types in the standard library are supported by the solver out of the box. `UInt8` is a commutative ring with characteristic `256`, and thus has instances of `CommRing UInt8` and `IsCharP UInt8 256`.

```proofscript
example (x : UInt8) : (x + 16) * (x - 16) = x ^ 2 := by
  grind
```

<a id="More-Commutative-Ring-Proofs"></a>
More Commutative Ring Proofs 

The axioms of a commutative ring are sufficient to prove these statements.

```proofscript
example [CommRing α] (a b c : α) :
    a + b + c = 3 →
    a ^ 2 + b ^ 2 + c ^ 2 = 5 →
    a ^ 3 + b ^ 3 + c ^ 3 = 7 →
    a ^ 4 + b ^ 4 = 9 - c ^ 4 := by
  grind
```

```proofscript
example [CommRing α] (x y : α) :
    x ^ 2 * y = 1 →
    x * y ^ 2 = y →
    y * x = 1 := by
  grind
```

<a id="Characteristic-Zero"></a>
Characteristic Zero 

`ring` proves that `a + 1 = 2 + a` is unsatisfiable because the characteristic is known to be 0.

```proofscript
example [CommRing α] [IsCharP α 0] (a : α) :
    a + 1 = 2 + a → False := by
  grind
```

<a id="Inferred-Characteristic"></a>
Inferred Characteristic 

Even when the characteristic is not initially known, when `grind` discovers that `n = 0` for some numeral `n`, it makes inferences about the characteristic:

```proofscript
example [CommRing α] (a b c : α)
    (h₁ : a + 6 = a) (h₂ : c = c + 9) (h : b + 3*c = 0) :
    27*a + b = 0 := by
  grind
```

<a id="grind-ring-classes"></a>
### 16.10.1. Solver Type Classes

Users can enable the `ring` solver for their own types by providing instances of the following [type classes](../../Type-Classes/index.md#--tech-term-type-class), all in the `Lean.Grind` namespace:

- `Semiring`
- `Ring`
- `CommSemiring`
- `CommRing`
- `IsCharP`
- `AddRightCancel`
- `NoNatZeroDivisors`
- `Field`

The algebraic solvers will self-configure depending on the availability of these instances, so not all need to be provided. The capabilities of the algebraic solvers will, of course, degrade when some are not available.

The Lean standard library contains the applicable instances for the types defined in the standard library. By providing these instances, other libraries can also enable `grind`'s `ring` solver. For example, the Mathlib `CommRing` type class implements `Lean.Grind.CommRing` to ensure the `ring` solver works out-of-the-box.

<a id="The-Lean-Language-Reference--The--grind--tactic--Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_--Solver-Type-Classes--Algebraic-Structures"></a>
#### 16.10.1.1. Algebraic Structures

To enable the algebraic solver, a type should have an instance of the most specific possible algebraic structure that the solver supports. In order of increasing specificity, that is `Semiring`, `Ring`, `CommSemiring`, `CommRing`, and `Field`.

<a id="Lean___Grind___Semiring___mk"></a>

**type class**

```text
Lean.Grind.Semiring.{u} (α : Type u) : Type u
```

A semiring, i.e. a type equipped with addition, multiplication, and a map from the natural numbers, satisfying appropriate compatibilities.

Use `Ring` instead if the type also has negation, `CommSemiring` if the multiplication is commutative, or `CommRing` if the type has negation and multiplication is commutative.

**Instance Constructor**

```text
Lean.Grind.Semiring.mk.{u}
```

**Extends**

- <a id="0-Add-Lean.Grind.Semiring"></a>
  `Add α`
- <a id="1-Mul-Lean.Grind.Semiring"></a>
  `Mul α`

**Methods**

```text
add : α → α → α
```

 Inherited from 

1. `Add α`
2. `Mul α`

```text
mul : α → α → α
```

 Inherited from 

1. `Add α`
2. `Mul α`

```text
natCast : NatCast α
```

In every semiring there is a canonical map from the natural numbers to the semiring, providing the values of `0` and `1`. Note that this function need not be injective.

```text
ofNat : (n : Nat) → OfNat α n
```

Natural number numerals in the semiring. The field `ofNat_eq_natCast` ensures that these are (propositionally) equal to the values of `natCast`.

```text
nsmul : SMul Nat α
```

Scalar multiplication by natural numbers.

```text
npow : HPow α Nat α
```

Exponentiation by a natural number.

```text
add_zero : ∀ (a : α), a + 0 = a
```

Zero is the right identity for addition.

```text
add_comm : ∀ (a b : α), a + b = b + a
```

Addition is commutative.

```text
add_assoc : ∀ (a b c : α), a + b + c = a + (b + c)
```

Addition is associative.

```text
mul_assoc : ∀ (a b c : α), a * b * c = a * (b * c)
```

Multiplication is associative.

```text
mul_one : ∀ (a : α), a * 1 = a
```

One is the right identity for multiplication.

```text
one_mul : ∀ (a : α), 1 * a = a
```

One is the left identity for multiplication.

```text
left_distrib : ∀ (a b c : α), a * (b + c) = a * b + a * c
```

Left distributivity of multiplication over addition.

```text
right_distrib : ∀ (a b c : α), (a + b) * c = a * c + b * c
```

Right distributivity of multiplication over addition.

```text
zero_mul : ∀ (a : α), 0 * a = 0
```

Zero is right absorbing for multiplication.

```text
mul_zero : ∀ (a : α), a * 0 = 0
```

Zero is left absorbing for multiplication.

```text
pow_zero : ∀ (a : α), a ^ 0 = 1
```

The zeroth power of any element is one.

```text
pow_succ : ∀ (a : α) (n : Nat), a ^ (n + 1) = a ^ n * a
```

The successor power law for exponentiation.

```text
ofNat_succ : ∀ (a : Nat), OfNat.ofNat (a + 1) = OfNat.ofNat a + 1
```

Numerals are consistently defined with respect to addition.

```text
ofNat_eq_natCast : ∀ (n : Nat), OfNat.ofNat n = ↑n
```

Numerals are consistently defined with respect to the canonical map from natural numbers.

```text
nsmul_eq_natCast_mul : ∀ (n : Nat) (a : α), n • a = ↑n * a
```

Multiplying by a numeral is consistently defined with respect to the canonical map from natural numbers.

<a id="Lean___Grind___CommSemiring___mk"></a>

**type class**

```text
Lean.Grind.CommSemiring.{u} (α : Type u) : Type u
```

A commutative semiring, i.e. a semiring with commutative multiplication.

Use `CommRing` if the type has negation.

**Instance Constructor**

```text
Lean.Grind.CommSemiring.mk.{u}
```

**Extends**

- <a id="0-Lean.Grind.Semiring-Lean.Grind.CommSemiring"></a>
  `Lean.Grind.Semiring α`

**Methods**

```text
add : α → α → α
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
mul : α → α → α
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
natCast : NatCast α
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
ofNat : (n : Nat) → OfNat α n
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
nsmul : SMul Nat α
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
npow : HPow α Nat α
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
add_zero : ∀ (a : α), a + 0 = a
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
add_comm : ∀ (a b : α), a + b = b + a
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
add_assoc : ∀ (a b c : α), a + b + c = a + (b + c)
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
mul_assoc : ∀ (a b c : α), a * b * c = a * (b * c)
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
mul_one : ∀ (a : α), a * 1 = a
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
one_mul : ∀ (a : α), 1 * a = a
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
left_distrib : ∀ (a b c : α), a * (b + c) = a * b + a * c
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
right_distrib : ∀ (a b c : α), (a + b) * c = a * c + b * c
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
zero_mul : ∀ (a : α), 0 * a = 0
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
mul_zero : ∀ (a : α), a * 0 = 0
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
pow_zero : ∀ (a : α), a ^ 0 = 1
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
pow_succ : ∀ (a : α) (n : Nat), a ^ (n + 1) = a ^ n * a
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
ofNat_succ : ∀ (a : Nat), OfNat.ofNat (a + 1) = OfNat.ofNat a + 1
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
ofNat_eq_natCast : ∀ (n : Nat), OfNat.ofNat n = ↑n
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
nsmul_eq_natCast_mul : ∀ (n : Nat) (a : α), n • a = ↑n * a
```

 Inherited from 

1. `Lean.Grind.Semiring α`

```text
mul_comm : ∀ (a b : α), a * b = b * a
```

Multiplication is commutative.

<a id="Lean___Grind___Ring___mk"></a>

**type class**

```text
Lean.Grind.Ring.{u} (α : Type u) : Type u
```

A ring, i.e. a type equipped with addition, negation, multiplication, and a map from the integers, satisfying appropriate compatibilities.

Use `CommRing` if the multiplication is commutative.

**Instance Constructor**

```text
Lean.Grind.Ring.mk.{u}
```

**Extends**

- <a id="0-Lean.Grind.Semiring-Lean.Grind.Ring"></a>
  `Lean.Grind.Semiring α`
- <a id="1-Neg-Lean.Grind.Ring"></a>
  `Neg α`
- <a id="2-Sub-Lean.Grind.Ring"></a>
  `Sub α`

**Methods**

```text
add : α → α → α
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
mul : α → α → α
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
natCast : NatCast α
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
ofNat : (n : Nat) → OfNat α n
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
nsmul : SMul Nat α
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
npow : HPow α Nat α
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
add_zero : ∀ (a : α), a + 0 = a
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
add_comm : ∀ (a b : α), a + b = b + a
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
add_assoc : ∀ (a b c : α), a + b + c = a + (b + c)
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
mul_assoc : ∀ (a b c : α), a * b * c = a * (b * c)
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
mul_one : ∀ (a : α), a * 1 = a
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
one_mul : ∀ (a : α), 1 * a = a
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
left_distrib : ∀ (a b c : α), a * (b + c) = a * b + a * c
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
right_distrib : ∀ (a b c : α), (a + b) * c = a * c + b * c
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
zero_mul : ∀ (a : α), 0 * a = 0
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
mul_zero : ∀ (a : α), a * 0 = 0
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
pow_zero : ∀ (a : α), a ^ 0 = 1
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
pow_succ : ∀ (a : α) (n : Nat), a ^ (n + 1) = a ^ n * a
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
ofNat_succ : ∀ (a : Nat), OfNat.ofNat (a + 1) = OfNat.ofNat a + 1
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
ofNat_eq_natCast : ∀ (n : Nat), OfNat.ofNat n = ↑n
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
nsmul_eq_natCast_mul : ∀ (n : Nat) (a : α), n • a = ↑n * a
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
neg : α → α
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
sub : α → α → α
```

 Inherited from 

1. `Lean.Grind.Semiring α`
2. `Neg α`
3. `Sub α`

```text
intCast : IntCast α
```

In every ring there is a canonical map from the integers to the ring.

```text
zsmul : SMul Int α
```

Scalar multiplication by integers.

```text
neg_add_cancel : ∀ (a : α), -a + a = 0
```

Negation is the left inverse of addition.

```text
sub_eq_add_neg : ∀ (a b : α), a - b = a + -b
```

Subtraction is addition of the negative.

```text
neg_zsmul : ∀ (i : Int) (a : α), -i • a = -(i • a)
```

Scalar multiplication by the negation of an integer is the negation of scalar multiplication by that integer.

```text
zsmul_natCast_eq_nsmul : ∀ (n : Nat) (a : α), ↑n • a = n • a
```

Scalar multiplication by natural numbers is consistent with scalar multiplication by integers.

```text
intCast_ofNat : ∀ (n : Nat), ↑(OfNat.ofNat n) = OfNat.ofNat n
```

The canonical map from the integers is consistent with the canonical map from the natural numbers.

```text
intCast_neg : ∀ (i : Int), ↑(-i) = -↑i
```

The canonical map from the integers is consistent with negation.

<a id="Lean___Grind___CommRing___mk"></a>

**type class**

```text
Lean.Grind.CommRing.{u} (α : Type u) : Type u
```

A commutative ring, i.e. a ring with commutative multiplication.

**Instance Constructor**

```text
Lean.Grind.CommRing.mk.{u}
```

**Extends**

- <a id="0-Lean.Grind.Ring-Lean.Grind.CommRing"></a>
  `Lean.Grind.Ring α`
- <a id="1-Lean.Grind.CommSemiring-Lean.Grind.CommRing"></a>
  `Lean.Grind.CommSemiring α`

**Methods**

```text
add : α → α → α
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
mul : α → α → α
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
natCast : NatCast α
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
ofNat : (n : Nat) → OfNat α n
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
nsmul : SMul Nat α
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
npow : HPow α Nat α
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
add_zero : ∀ (a : α), a + 0 = a
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
add_comm : ∀ (a b : α), a + b = b + a
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
add_assoc : ∀ (a b c : α), a + b + c = a + (b + c)
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
mul_assoc : ∀ (a b c : α), a * b * c = a * (b * c)
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
mul_one : ∀ (a : α), a * 1 = a
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
one_mul : ∀ (a : α), 1 * a = a
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
left_distrib : ∀ (a b c : α), a * (b + c) = a * b + a * c
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
right_distrib : ∀ (a b c : α), (a + b) * c = a * c + b * c
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
zero_mul : ∀ (a : α), 0 * a = 0
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
mul_zero : ∀ (a : α), a * 0 = 0
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
pow_zero : ∀ (a : α), a ^ 0 = 1
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
pow_succ : ∀ (a : α) (n : Nat), a ^ (n + 1) = a ^ n * a
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
ofNat_succ : ∀ (a : Nat), OfNat.ofNat (a + 1) = OfNat.ofNat a + 1
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
ofNat_eq_natCast : ∀ (n : Nat), OfNat.ofNat n = ↑n
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
nsmul_eq_natCast_mul : ∀ (n : Nat) (a : α), n • a = ↑n * a
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
neg : α → α
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
sub : α → α → α
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
intCast : IntCast α
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
zsmul : SMul Int α
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
neg_add_cancel : ∀ (a : α), -a + a = 0
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
sub_eq_add_neg : ∀ (a b : α), a - b = a + -b
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
neg_zsmul : ∀ (i : Int) (a : α), -i • a = -(i • a)
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
zsmul_natCast_eq_nsmul : ∀ (n : Nat) (a : α), ↑n • a = n • a
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
intCast_ofNat : ∀ (n : Nat), ↑(OfNat.ofNat n) = OfNat.ofNat n
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
intCast_neg : ∀ (i : Int), ↑(-i) = -↑i
```

 Inherited from 

1. `Lean.Grind.Ring α`
2. `Lean.Grind.CommSemiring α`

```text
mul_comm : ∀ (a b : α), a * b = b * a
```

Multiplication is commutative.

<a id="grind-ring-field"></a>
##### 16.10.1.1.1. Fields

The `ring` solver also has support for `Field`s. If a `Field` instance is available, the solver preprocesses the term `a / b` into `a * b⁻¹`. It also rewrites every disequality `p ≠ 0` as the equality `p * p⁻¹ = 1`.

<a id="Fields-and--grind"></a>
Fields and `grind` 

This example requires its `Field` instance:

```proofscript
example [Field α] (a : α) :
    a ^ 2 = 0 →
    a = 0 := by
  grind
```

<a id="Lean___Grind___Field___mk"></a>

**type class**

```text
Lean.Grind.Field.{u} (α : Type u) : Type u
```

A field is a commutative ring with inverses for all non-zero elements.

**Instance Constructor**

```text
Lean.Grind.Field.mk.{u}
```

**Extends**

- <a id="0-Lean.Grind.CommRing-Lean.Grind.Field"></a>
  `Lean.Grind.CommRing α`
- <a id="1-Inv-Lean.Grind.Field"></a>
  `Inv α`
- <a id="2-Div-Lean.Grind.Field"></a>
  `Div α`

**Methods**

```text
add : α → α → α
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
mul : α → α → α
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
natCast : NatCast α
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
ofNat : (n : Nat) → OfNat α n
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
nsmul : SMul Nat α
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
npow : HPow α Nat α
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
add_zero : ∀ (a : α), a + 0 = a
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
add_comm : ∀ (a b : α), a + b = b + a
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
add_assoc : ∀ (a b c : α), a + b + c = a + (b + c)
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
mul_assoc : ∀ (a b c : α), a * b * c = a * (b * c)
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
mul_one : ∀ (a : α), a * 1 = a
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
one_mul : ∀ (a : α), 1 * a = a
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
left_distrib : ∀ (a b c : α), a * (b + c) = a * b + a * c
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
right_distrib : ∀ (a b c : α), (a + b) * c = a * c + b * c
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
zero_mul : ∀ (a : α), 0 * a = 0
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
mul_zero : ∀ (a : α), a * 0 = 0
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
pow_zero : ∀ (a : α), a ^ 0 = 1
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
pow_succ : ∀ (a : α) (n : Nat), a ^ (n + 1) = a ^ n * a
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
ofNat_succ : ∀ (a : Nat), OfNat.ofNat (a + 1) = OfNat.ofNat a + 1
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
ofNat_eq_natCast : ∀ (n : Nat), OfNat.ofNat n = ↑n
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
nsmul_eq_natCast_mul : ∀ (n : Nat) (a : α), n • a = ↑n * a
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
neg : α → α
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
sub : α → α → α
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
intCast : IntCast α
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
zsmul : SMul Int α
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
neg_add_cancel : ∀ (a : α), -a + a = 0
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
sub_eq_add_neg : ∀ (a b : α), a - b = a + -b
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
neg_zsmul : ∀ (i : Int) (a : α), -i • a = -(i • a)
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
zsmul_natCast_eq_nsmul : ∀ (n : Nat) (a : α), ↑n • a = n • a
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
intCast_ofNat : ∀ (n : Nat), ↑(OfNat.ofNat n) = OfNat.ofNat n
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
intCast_neg : ∀ (i : Int), ↑(-i) = -↑i
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
mul_comm : ∀ (a b : α), a * b = b * a
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
inv : α → α
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
div : α → α → α
```

 Inherited from 

1. `Lean.Grind.CommRing α`
2. `Inv α`
3. `Div α`

```text
zpow : HPow α Int α
```

An exponentiation operator.

```text
div_eq_mul_inv : ∀ (a b : α), a / b = a * b⁻¹
```

Division is multiplication by the inverse.

```text
zero_ne_one : 0 ≠ 1
```

Zero is not equal to one: fields are non trivial.

```text
inv_zero : 0⁻¹ = 0
```

The inverse of zero is zero. This is a "junk value" convention.

```text
mul_inv_cancel : ∀ {a : α}, a ≠ 0 → a * a⁻¹ = 1
```

The inverse of a non-zero element is a right inverse.

```text
zpow_zero : ∀ (a : α), a ^ 0 = 1
```

The zeroth power of any element is one.

```text
zpow_succ : ∀ (a : α) (n : Nat), a ^ (↑n + 1) = a ^ ↑n * a
```

The (n+1)-st power of any element is the element multiplied by the n-th power.

```text
zpow_neg : ∀ (a : α) (n : Int), a ^ (-n) = (a ^ n)⁻¹
```

Raising to a negative power is the inverse of raising to the positive power.

<a id="The-Lean-Language-Reference--The--grind--tactic--Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_--Solver-Type-Classes--Ring-Characteristics"></a>
#### 16.10.1.2. Ring Characteristics

<a id="Lean___Grind___IsCharP___mk"></a>

**type class**

```text
Lean.Grind.IsCharP.{u} (α : Type u) [Lean.Grind.Semiring α]
  (p : outParam Nat) : Prop
```

A ring `α` has characteristic `p` if `OfNat.ofNat x = 0` iff `x % p = 0`.

Note that for `p = 0`, we have `x % p = x`, so this says that `OfNat.ofNat` is injective from `Nat` to `α`.

In the case of a semiring, we take the stronger condition that `OfNat.ofNat x = OfNat.ofNat y` iff `x % p = y % p`.

**Instance Constructor**

```text
Lean.Grind.IsCharP.mk.{u}
```

**Methods**

```text
ofNat_ext_iff : ∀ {x y : Nat}, OfNat.ofNat x = OfNat.ofNat y ↔ x % p = y % p
```

Two numerals in a semiring are equal iff they are congruent module `p` in the natural numbers.

<a id="NoNatZeroDivisors"></a>
#### 16.10.1.3. Natural Number Zero Divisors

The class `NoNatZeroDivisors` is used to control coefficient growth. For example, the polynomial `2 * x * y + 4 * z = 0` is simplified to `x * y + 2 * z = 0`. It also used when processing disequalities.

<a id="Using--NoNatZeroDivisors"></a>
Using `NoNatZeroDivisors` 

In this example, `grind` relies on the `NoNatZeroDivisors` instance to simplify the goal:

```proofscript
example [CommRing α] [NoNatZeroDivisors α] (a b : α) :
    2 * a + 2 * b = 0 →
    b ≠ -a → False := by
  grind
```

Without it, the proof fails:

```proofscript
example [CommRing α] (a b : α) :
    2 * a + 2 * b = 0 →
    b ≠ -a → False := by
  grind
```
<a id="--verso-unique-1673"></a>


```lean
`grind` failed
grindα:Type u_1inst:CommRing αa b:αh:2 * a + 2 * b = 0h_1:¬b = -a⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] 2 * a + 2 * b = 0[prop] ¬b = -a[eqc] False propositions[prop] b = -a[eqc] Equivalence classes[eqc] {0, 2 * a + 2 * b}[ring] Ring `α`[basis] Basis[_] 2 * a + 2 * b = 0[diseqs] Disequalities[_] ¬a + b = 0
```

<a id="Lean___Grind___NoNatZeroDivisors___mk"></a>

**type class**

```text
Lean.Grind.NoNatZeroDivisors.{u} (α : Type u) [Lean.Grind.NatModule α] :
  Prop
```

We say a module has no natural number zero divisors if `k ≠ 0` and `k * a = k * b` implies `a = b` (here `k` is a natural number and `a` and `b` are element of the module).

For a module over the integers this is equivalent to `k ≠ 0` and `k * a = 0` implies `a = 0`. (See the alternative constructor `NoNatZeroDivisors.mk'`, and the theorem `eq_zero_of_mul_eq_zero`.)

**Instance Constructor**

```text
Lean.Grind.NoNatZeroDivisors.mk.{u}
```

**Methods**

```text
no_nat_zero_divisors : ∀ (k : Nat) (a b : α), k ≠ 0 → k • a = k • b → a = b
```

If `k * a ≠ k * b` then `k ≠ 0` or `a ≠ b`.

<a id="Lean___Grind___NoNatZeroDivisors___mk___"></a>

**def**

```text
Lean.Grind.NoNatZeroDivisors.mk'.{u_1} {α : Type u_1}
  [Lean.Grind.IntModule α]
  (eq_zero_of_mul_eq_zero :
    ∀ (k : Nat) (a : α), k ≠ 0 → k • a = 0 → a = 0) :
  Lean.Grind.NoNatZeroDivisors α
```

Alternative constructor for `NoNatZeroDivisors` when we have an `IntModule`.

The `ring` module also performs case-analysis for terms `a⁻¹` on whether `a` is zero or not. In the following example, if `2*a` is zero, then `a` is also zero since we have `NoNatZeroDivisors α`, and all terms are zero and the equality hold. Otherwise, `ring` adds the equalities `a*a⁻¹ = 1` and `2*a*(2*a)⁻¹ = 1`, and closes the goal.

```proofscript
example [Field α] [NoNatZeroDivisors α] (a : α) :
    1 / a + 1 / (2 * a) = 3 / (2 * a) := by
  grind
```

Without `NoNatZeroDivisors`, `grind` will perform case splits on numerals being zero as needed:

```proofscript
example [Field α] (a : α) : (2 * a)⁻¹ = a⁻¹ / 2 := by grind
```

In the following example, `ring` does not need to perform any case split because the goal contains the disequalities `y ≠ 0` and `w ≠ 0`.

```proofscript
example [Field α] {x y z w : α} :
    x / y = z / w →
    y ≠ 0 → w ≠ 0 →
    x * w = z * y := by
  grind (splits := 0)
```

You can disable the `ring` solver using the option `grind -ring`.

```proofscript
example [CommRing α] (x y : α) :
    x ^ 2 * y = 1 →
    x * y ^ 2 = y →
    y * x = 1 := by
  grind -ring
```
<a id="--verso-unique-1687"></a>


```lean
`grind` failed
grindα:Type u_1inst:CommRing αx y:αh:x ^ 2 * y = 1h_1:x * y ^ 2 = yh_2:¬y * x = 1⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] x ^ 2 * y = 1[prop] x * y ^ 2 = y[prop] ¬y * x = 1[eqc] False propositions[prop] y * x = 1[eqc] Equivalence classes[eqc] {y, x * y ^ 2}[eqc] {1, x ^ 2 * y}[ematch] E-matching patterns[thm] Nat.pow_pos: [@HPow.hPow `[Nat] `[Nat] `[Nat] `[instHPow] #2 #1][thm] Nat.div_pow_of_pos: [@HPow.hPow `[Nat] `[Nat] `[Nat] `[instHPow] #2 #1][linarith] Linarith assignment for `α`[assign] x := 2[assign] y := 3[assign] 「x ^ 2」 := 4[assign] 「y ^ 2」 := 6
```

<a id="AddRightCancel"></a>
##### 16.10.1.3.1. Right-Cancellative Addition

The `ring` solver automatically embeds `CommSemiring`s into a `CommRing` envelope (using the construction `Lean.Grind.Ring.OfSemiring.Q`). However, the embedding is injective only when the `CommSemiring` implements the type class `AddRightCancel`. `Nat` is an example of a commutative semiring that implements `AddRightCancel`.

```proofscript
example (x y : Nat) :
    x ^ 2 * y = 1 →
    x * y ^ 2 = y →
    y * x = 1 := by
  grind
```

<a id="Lean___Grind___AddRightCancel___mk"></a>

**type class**

```text
Lean.Grind.AddRightCancel.{u} (M : Type u) [Add M] : Prop
```

A type where addition is right-cancellative, i.e. `a + c = b + c` implies `a = b`.

**Instance Constructor**

```text
Lean.Grind.AddRightCancel.mk.{u}
```

**Methods**

```text
add_right_cancel : ∀ (a b c : M), a + c = b + c → a = b
```

Addition is right-cancellative.

<a id="The-Lean-Language-Reference--The--grind--tactic--Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_--Resource-Limits"></a>
### 16.10.2. Resource Limits

Gröbner basis computation can be very expensive. You can limit the number of steps performed by the `ring` solver using the option `grind (ringSteps := <num>)`

<a id="Limiting--ring--Steps"></a>
Limiting `ring` Steps 

This example cannot be solved by performing at most 100 steps:

```proofscript
example [CommRing α] [IsCharP α 0] (d t c : α) (d_inv PSO3_inv : α) :
    d ^ 2 * (d + t - d * t - 2) * (d + t + d * t) = 0 →
    -d ^ 4 * (d + t - d * t - 2) *
      (2 * d + 2 * d * t - 4 * d * t ^ 2 + 2 * d * t^4 +
      2 * d^2 * t^4 - c * (d + t + d * t)) = 0 →
    d * d_inv = 1 →
    (d + t - d * t - 2) * PSO3_inv = 1 →
    t^2 = t + 1 := by
  grind (ringSteps := 100)
```
<a id="--verso-unique-1695"></a>


```lean
`grind` failed
grindα:Type u_1inst:CommRing αinst_1:IsCharP α 0d t c d_inv PSO3_inv:αh:d ^ 2 * (d + t - d * t - 2) * (d + t + d * t) = 0h_1:-d ^ 4 * (d + t - d * t - 2) *
    (2 * d + 2 * d * t - 4 * d * t ^ 2 + 2 * d * t ^ 4 + 2 * d ^ 2 * t ^ 4 - c * (d + t + d * t)) =
  0h_2:d * d_inv = 1h_3:(d + t - d * t - 2) * PSO3_inv = 1h_4:¬t ^ 2 = t + 1⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] IsCharP α 0[prop] d ^ 2 * (d + t - d * t - 2) * (d + t + d * t) = 0[prop] -d ^ 4 * (d + t - d * t - 2) *
        (2 * d + 2 * d * t - 4 * d * t ^ 2 + 2 * d * t ^ 4 + 2 * d ^ 2 * t ^ 4 - c * (d + t + d * t)) =
      0[prop] d * d_inv = 1[prop] (d + t - d * t - 2) * PSO3_inv = 1[prop] ¬t ^ 2 = t + 1[eqc] True propositions[prop] IsCharP α 0[eqc] False propositions[prop] t ^ 2 = t + 1[eqc] Equivalence classes[eqc] {0,
    -d ^ 4 * (d + t - d * t - 2) *
      (2 * d + 2 * d * t - 4 * d * t ^ 2 + 2 * d * t ^ 4 + 2 * d ^ 2 * t ^ 4 - c * (d + t + d * t)),
    d ^ 2 * (d + t - d * t - 2) * (d + t + d * t)}[eqc] {1, d * d_inv, (d + t - d * t - 2) * PSO3_inv}[ematch] E-matching patterns[thm] Nat.pow_pos: [@HPow.hPow `[Nat] `[Nat] `[Nat] `[instHPow] #2 #1][thm] Nat.div_pow_of_pos: [@HPow.hPow `[Nat] `[Nat] `[Nat] `[instHPow] #2 #1][ring] Ring `α`[basis] Basis[_] t ^ 2 * d_inv ^ 2 + -2 * (t * d_inv ^ 2) + -1 * t ^ 2 + -2 * d_inv + 1 = 0[_] d * t ^ 2 + -1 * (t ^ 2 * d_inv) + 2 * (t * d_inv) + -1 * d + 2 = 0[_] d * t * PSO3_inv + -1 * (d * PSO3_inv) + -1 * (t * PSO3_inv) + 2 * PSO3_inv + 1 = 0[_] t * d_inv * PSO3_inv + -1 * (t * PSO3_inv) + -2 * (d_inv * PSO3_inv) + -1 * d_inv + PSO3_inv = 0[_] d * d_inv + -1 = 0[diseqs] Disequalities[_] ¬t ^ 2 + -1 * t + -1 = 0[limits] Thresholds reached[limit] maximum number of ring steps has been reached, threshold: `(ringSteps := 100)`
```

The `ring` solver propagates equalities back to the `grind` core by normalizing terms using the computed Gröbner basis. In the following example, the equations `x ^ 2 * y = 1` and `x * y ^ 2 = y` imply the equalities `x = 1` and `y = 1`. Thus, the terms `x * y` and `1` are equal, and consequently `some (x * y) = some 1` by congruence.

```proofscript
example (x y : Int) :
    x ^ 2 * y = 1 →
    x * y ^ 2 = y →
    some (y * x) = some 1 := by
  grind
```

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`grind` failed
grindα:Type u_1inst:CommRing αa b:αh:2 * a + 2 * b = 0h_1:¬b = -a⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] 2 * a + 2 * b = 0[prop] ¬b = -a[eqc] False propositions[prop] b = -a[eqc] Equivalence classes[eqc] {0, 2 * a + 2 * b}[ring] Ring `α`[basis] Basis[_] 2 * a + 2 * b = 0[diseqs] Disequalities[_] ¬a + b = 0
```


### Display 2


```text
`grind` failed
grindα:Type u_1inst:CommRing αx y:αh:x ^ 2 * y = 1h_1:x * y ^ 2 = yh_2:¬y * x = 1⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] x ^ 2 * y = 1[prop] x * y ^ 2 = y[prop] ¬y * x = 1[eqc] False propositions[prop] y * x = 1[eqc] Equivalence classes[eqc] {y, x * y ^ 2}[eqc] {1, x ^ 2 * y}[ematch] E-matching patterns[thm] Nat.pow_pos: [@HPow.hPow `[Nat] `[Nat] `[Nat] `[instHPow] #2 #1][thm] Nat.div_pow_of_pos: [@HPow.hPow `[Nat] `[Nat] `[Nat] `[instHPow] #2 #1][linarith] Linarith assignment for `α`[assign] x := 2[assign] y := 3[assign] 「x ^ 2」 := 4[assign] 「y ^ 2」 := 6
```


### Display 3


```text
`grind` failed
grindα:Type u_1inst:CommRing αinst_1:IsCharP α 0d t c d_inv PSO3_inv:αh:d ^ 2 * (d + t - d * t - 2) * (d + t + d * t) = 0h_1:-d ^ 4 * (d + t - d * t - 2) *
    (2 * d + 2 * d * t - 4 * d * t ^ 2 + 2 * d * t ^ 4 + 2 * d ^ 2 * t ^ 4 - c * (d + t + d * t)) =
  0h_2:d * d_inv = 1h_3:(d + t - d * t - 2) * PSO3_inv = 1h_4:¬t ^ 2 = t + 1⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] IsCharP α 0[prop] d ^ 2 * (d + t - d * t - 2) * (d + t + d * t) = 0[prop] -d ^ 4 * (d + t - d * t - 2) *
        (2 * d + 2 * d * t - 4 * d * t ^ 2 + 2 * d * t ^ 4 + 2 * d ^ 2 * t ^ 4 - c * (d + t + d * t)) =
      0[prop] d * d_inv = 1[prop] (d + t - d * t - 2) * PSO3_inv = 1[prop] ¬t ^ 2 = t + 1[eqc] True propositions[prop] IsCharP α 0[eqc] False propositions[prop] t ^ 2 = t + 1[eqc] Equivalence classes[eqc] {0,
    -d ^ 4 * (d + t - d * t - 2) *
      (2 * d + 2 * d * t - 4 * d * t ^ 2 + 2 * d * t ^ 4 + 2 * d ^ 2 * t ^ 4 - c * (d + t + d * t)),
    d ^ 2 * (d + t - d * t - 2) * (d + t + d * t)}[eqc] {1, d * d_inv, (d + t - d * t - 2) * PSO3_inv}[ematch] E-matching patterns[thm] Nat.pow_pos: [@HPow.hPow `[Nat] `[Nat] `[Nat] `[instHPow] #2 #1][thm] Nat.div_pow_of_pos: [@HPow.hPow `[Nat] `[Nat] `[Nat] `[instHPow] #2 #1][ring] Ring `α`[basis] Basis[_] t ^ 2 * d_inv ^ 2 + -2 * (t * d_inv ^ 2) + -1 * t ^ 2 + -2 * d_inv + 1 = 0[_] d * t ^ 2 + -1 * (t ^ 2 * d_inv) + 2 * (t * d_inv) + -1 * d + 2 = 0[_] d * t * PSO3_inv + -1 * (d * PSO3_inv) + -1 * (t * PSO3_inv) + 2 * PSO3_inv + 1 = 0[_] t * d_inv * PSO3_inv + -1 * (t * PSO3_inv) + -2 * (d_inv * PSO3_inv) + -1 * d_inv + PSO3_inv = 0[_] d * d_inv + -1 = 0[diseqs] Disequalities[_] ¬t ^ 2 + -1 * t + -1 = 0[limits] Thresholds reached[limit] maximum number of ring steps has been reached, threshold: `(ringSteps := 100)`
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
α:Type u_1inst✝:CommRing αx:α⊢ (x + 1) * (x - 1) = x ^ 2 - 1
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
α:Type u_1inst✝¹:CommRing αinst✝:IsCharP α 256x:α⊢ (x + 16) * (x - 16) = x ^ 2
```


### Display 4


```text
x:UInt8⊢ (x + 16) * (x - 16) = x ^ 2
```


### Display 5


```text
α:Type u_1inst✝:CommRing αa:αb:αc:α⊢ a + b + c = 3 → a ^ 2 + b ^ 2 + c ^ 2 = 5 → a ^ 3 + b ^ 3 + c ^ 3 = 7 → a ^ 4 + b ^ 4 = 9 - c ^ 4
```


### Display 6


```text
α:Type u_1inst✝:CommRing αx:αy:α⊢ x ^ 2 * y = 1 → x * y ^ 2 = y → y * x = 1
```


### Display 7


```text
α:Type u_1inst✝¹:CommRing αinst✝:IsCharP α 0a:α⊢ a + 1 = 2 + a → False
```


### Display 8


```text
α:Type u_1inst✝:CommRing αa:αb:αc:αh₁:a + 6 = ah₂:c = c + 9h:b + 3 * c = 0⊢ 27 * a + b = 0
```


### Display 9


```text
α:Type u_1inst✝:Field αa:α⊢ a ^ 2 = 0 → a = 0
```


### Display 10


```text
α:Type u_1inst✝¹:CommRing αinst✝:NoNatZeroDivisors αa:αb:α⊢ 2 * a + 2 * b = 0 → b ≠ -a → False
```


### Display 11


```text
α:Type u_1inst✝:CommRing αa:αb:α⊢ 2 * a + 2 * b = 0 → b ≠ -a → False
```


### Display 12


```text
α:Type u_1inst✝¹:Field αinst✝:NoNatZeroDivisors αa:α⊢ 1 / a + 1 / (2 * a) = 3 / (2 * a)
```


### Display 13


```text
α:Type u_1inst✝:Field αa:α⊢ (2 * a)⁻¹ = a⁻¹ / 2
```


### Display 14


```text
α:Type u_1inst✝:Field αx:αy:αz:αw:α⊢ x / y = z / w → y ≠ 0 → w ≠ 0 → x * w = z * y
```


### Display 15


```text
x:Naty:Nat⊢ x ^ 2 * y = 1 → x * y ^ 2 = y → y * x = 1
```


### Display 16


```text
α:Type u_1inst✝¹:CommRing αinst✝:IsCharP α 0d:αt:αc:αd_inv:αPSO3_inv:α⊢ d ^ 2 * (d + t - d * t - 2) * (d + t + d * t) = 0 →
  -d ^ 4 * (d + t - d * t - 2) *
        (2 * d + 2 * d * t - 4 * d * t ^ 2 + 2 * d * t ^ 4 + 2 * d ^ 2 * t ^ 4 - c * (d + t + d * t)) =
      0 →
    d * d_inv = 1 → (d + t - d * t - 2) * PSO3_inv = 1 → t ^ 2 = t + 1
```


### Display 17


```text
x:Inty:Int⊢ x ^ 2 * y = 1 → x * y ^ 2 = y → some (y * x) = some 1
```

