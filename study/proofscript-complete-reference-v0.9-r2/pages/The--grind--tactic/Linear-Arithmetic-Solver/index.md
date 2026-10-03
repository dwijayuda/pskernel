<a id="grind-linarith"></a>

# ProofScript — 16.11. Linear Arithmetic Solver

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

grind combines reasoning such as congruence closure, propagation, case analysis, E-matching and algebraic/arithmetic procedures. Its selected lemmas, annotations and solver parameters determine the search problem. Keep these as native proof-producing facilities, not as a replacement for the kernel. The mirrored subchapters and examples retain their individual scopes and failure cases.

**Compiler and coverage boundary.** Lean 4.34 stable parameter-list changes for lia/grobner are inherited only under the selected tactic capability. A timeout must remain an incomplete-search result.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--grind--tactic/Linear-Arithmetic-Solver/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--grind--tactic/Linear-Arithmetic-Solver/index.html). Source Git blob: `a454f421798fe5b192bcae9c7ef2fc217c51f88c`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 16.11. Linear Arithmetic Solver

The `grind` tactic includes a linear arithmetic solver for arbitrary types, called `linarith`, that is used for types not supported by [`cutsat`](../Linear-Integer-Arithmetic/index.md#cutsat). Like the [`ring`](../Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_/index.md#grind-ring) solver, it can be used with any type that has instances of certain type classes. It self-configures depending on the availability of these type classes, so it is not necessary to provide all of them to use the solver; however, its capabilities are increased by the availability of more instances. This solver is useful for reasoning about the real numbers, ordered vector spaces, and other types that can't be embedded into `Int`.

The core functionality of `linarith` is a model-based solver for linear inequalities with integer coefficients. It can be disabled using the option `grind -linarith`.

<a id="Goals-Decided-by--linarith"></a>
Goals Decided by `linarith` 

All of these examples rely on instances of the following ordering notation and `linarith` classes:

```proofscript
variable [LE α] [LT α] [Std.LawfulOrderLT α]  [Std.IsLinearOrder α]
variable [IntModule α] [OrderedAdd α]
```

Integer modules (`IntModule`) are types with zero, addition, negation, subtraction, and scalar multiplication by integers that satisfy the expected properties of these operations. Linear orders (`Std.IsLinearOrder`) are orders in which any pair of elements is ordered, and `OrderedAdd` states that adding a constant to both sides preserves orderings.

```proofscript
example {a b : α} : 2 • a + b ≥ b + a + a := by grind

example {a b : α} (h : a ≤ b) : 3 • a + b ≤ 4 • b := by grind

example {a b c : α} :
    a = b + c →
    2 • b ≤ c →
    2 • a ≤ 3 • c := by
  grind

example {a b c d e : α} :
    2 • a + b ≥ 0 →
    b ≥ 0 → c ≥ 0 → d ≥ 0 → e ≥ 0 →
    a ≥ 3 • c → c ≥ 6 • e → d - 5 • e ≥ 0 →
    a + b + 3 • c + d + 2 • e < 0 →
    False := by
  grind
```

<a id="Commutative-Ring-Goals-Decided-by--linarith"></a>
Commutative Ring Goals Decided by `linarith` 

For types that are commmutative rings (that is, types in which the multiplication operator is commutative) with `CommRing` instances, `linarith` has more capabilities.

```proofscript
variable [LE R] [LT R] [Std.IsLinearOrder R] [Std.LawfulOrderLT R]
variable [CommRing R] [OrderedRing R]
```

The `CommRing R` instance allows `linarith` to perform basic normalization, such as identifying linear atoms `a * b` and `b * a`, and to account for scalar multiplication on both sides. The `OrderedRing R` instance allows the solver to support constants, because it has access to the fact that `(0 : R) < 1`.

```proofscript
example (a b : R) (h : a * b ≤ 1) : b * 3 • a + 1 ≤ 4 := by grind

example (a b c d e f : R) :
    2 • a + b ≥ 1 →
    b ≥ 0 → c ≥ 0 → d ≥ 0 → e • f ≥ 0 →
    a ≥ 3 • c →
    c ≥ 6 • e • f → d - f * e * 5 ≥ 0 →
    a + b + 3 • c + d + 2 • e • f < 0 →
    False := by
  grind
```

<a id="grind-linarith-classes"></a>
### 16.11.1. Supporting linarith

To add support for a new type to `linarith`, the first step is to implement `IntModule` if possible, or `NatModule` otherwise. Every `Ring` is already an `IntModule`, and every `Semiring` is already a `NatModule`, so implementing one of those instances is also sufficient. Next, one of the order classes (`Std.IsPreorder`, `Std.IsPartialOrder`, or `Std.IsLinearOrder`) should be implemented. Typically an `IsPreorder` instance is enough when the context already includes a contradiction, but an `IsLinearOrder` instance is required in order to prove linear inequality goals. Additional features are enabled by implementing `OrderedAdd`, which expresses that the additive structure in a module is compatible with the order, and `OrderedRing`, which improves support for constants.

<a id="Lean___Grind___NatModule___mk"></a>

**type class**

```text
Lean.Grind.NatModule.{u} (M : Type u) : Type u
```

A module over the natural numbers, i.e. a type with zero, addition, and scalar multiplication by natural numbers, satisfying appropriate compatibilities.

Equivalently, an additive commutative monoid.

Use `IntModule` if the type has negation.

**Instance Constructor**

```text
Lean.Grind.NatModule.mk.{u}
```

**Extends**

- <a id="0-Lean.Grind.AddCommMonoid-Lean.Grind.NatModule"></a>
  `AddCommMonoid M`

**Methods**

```text
zero : M
```

 Inherited from 

1. `AddCommMonoid M`

```text
add : M → M → M
```

 Inherited from 

1. `AddCommMonoid M`

```text
add_zero : ∀ (a : M), a + 0 = a
```

 Inherited from 

1. `AddCommMonoid M`

```text
add_comm : ∀ (a b : M), a + b = b + a
```

 Inherited from 

1. `AddCommMonoid M`

```text
add_assoc : ∀ (a b c : M), a + b + c = a + (b + c)
```

 Inherited from 

1. `AddCommMonoid M`

```text
nsmul : SMul Nat M
```

Scalar multiplication by natural numbers.

```text
zero_nsmul : ∀ (a : M), 0 • a = 0
```

Scalar multiplication by zero is zero.

```text
add_one_nsmul : ∀ (n : Nat) (a : M), (n + 1) • a = n • a + a
```

Scalar multiplication by a successor.

<a id="Lean___Grind___IntModule___mk"></a>

**type class**

```text
Lean.Grind.IntModule.{u} (M : Type u) : Type u
```

A module over the integers, i.e. a type with zero, addition, negation, subtraction, and scalar multiplication by integers, satisfying appropriate compatibilities.

Equivalently, an additive commutative group.

**Instance Constructor**

```text
Lean.Grind.IntModule.mk.{u}
```

**Extends**

- <a id="0-Lean.Grind.AddCommGroup-Lean.Grind.IntModule"></a>
  `AddCommGroup M`

**Methods**

```text
zero : M
```

 Inherited from 

1. `AddCommGroup M`

```text
add : M → M → M
```

 Inherited from 

1. `AddCommGroup M`

```text
add_zero : ∀ (a : M), a + 0 = a
```

 Inherited from 

1. `AddCommGroup M`

```text
add_comm : ∀ (a b : M), a + b = b + a
```

 Inherited from 

1. `AddCommGroup M`

```text
add_assoc : ∀ (a b c : M), a + b + c = a + (b + c)
```

 Inherited from 

1. `AddCommGroup M`

```text
neg : M → M
```

 Inherited from 

1. `AddCommGroup M`

```text
sub : M → M → M
```

 Inherited from 

1. `AddCommGroup M`

```text
neg_add_cancel : ∀ (a : M), -a + a = 0
```

 Inherited from 

1. `AddCommGroup M`

```text
sub_eq_add_neg : ∀ (a b : M), a - b = a + -b
```

 Inherited from 

1. `AddCommGroup M`

```text
nsmul : SMul Nat M
```

Scalar multiplication by natural numbers.

```text
zsmul : SMul Int M
```

Scalar multiplication by integers.

```text
zero_zsmul : ∀ (a : M), 0 • a = 0
```

Scalar multiplication by zero is zero.

```text
one_zsmul : ∀ (a : M), 1 • a = a
```

Scalar multiplication by one is the identity.

```text
add_zsmul : ∀ (n m : Int) (a : M), (n + m) • a = n • a + m • a
```

Scalar multiplication is distributive over addition in the integers.

```text
zsmul_natCast_eq_nsmul : ∀ (n : Nat) (a : M), ↑n • a = n • a
```

Scalar multiplication by natural numbers is consistent with scalar multiplication by integers.

<a id="Lean___Grind___OrderedAdd___mk"></a>

**type class**

```text
Lean.Grind.OrderedAdd.{u} (M : Type u) [HAdd M M M] [LE M]
  [Std.IsPreorder M] : Prop
```

Addition is compatible with a preorder if `a ≤ b ↔ a + c ≤ b + c`.

**Instance Constructor**

```text
Lean.Grind.OrderedAdd.mk.{u}
```

**Methods**

```text
add_le_left_iff : ∀ {a b : M} (c : M), a ≤ b ↔ a + c ≤ b + c
```

`a + c ≤ b + c` iff `a ≤ b`.

<a id="Lean___Grind___OrderedRing___mk"></a>

**type class**

```text
Lean.Grind.OrderedRing.{u} (R : Type u) [Semiring R] [LE R] [LT R]
  [Std.IsPreorder R] : Prop
```

A ring which is also equipped with a preorder is considered a strict ordered ring if addition, negation, and multiplication are compatible with the preorder, and `0 < 1`.

**Instance Constructor**

```text
Lean.Grind.OrderedRing.mk.{u}
```

**Extends**

- <a id="0-Lean.Grind.OrderedAdd-Lean.Grind.OrderedRing"></a>
  `OrderedAdd R`

**Methods**

```text
add_le_left_iff : ∀ {a b : R} (c : R), a ≤ b ↔ a + c ≤ b + c
```

 Inherited from 

1. `OrderedAdd R`

```text
zero_lt_one : 0 < 1
```

In a strict ordered semiring, we have `0 < 1`.

```text
mul_lt_mul_of_pos_left : ∀ {a b c : R}, a < b → 0 < c → c * a < c * b
```

In a strict ordered semiring, we can multiply an inequality `a < b` on the left by a positive element `0 < c` to obtain `c * a < c * b`.

```text
mul_lt_mul_of_pos_right : ∀ {a b c : R}, a < b → 0 < c → a * c < b * c
```

In a strict ordered semiring, we can multiply an inequality `a < b` on the right by a positive element `0 < c` to obtain `a * c < b * c`.

## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
α:Type u_1inst✝⁵:LE αinst✝⁴:LT αinst✝³:Std.LawfulOrderLT αinst✝²:Std.IsLinearOrder αinst✝¹:IntModule αinst✝:OrderedAdd αa:αb:α⊢ 2 • a + b ≥ b + a + a
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
α:Type u_1inst✝⁵:LE αinst✝⁴:LT αinst✝³:Std.LawfulOrderLT αinst✝²:Std.IsLinearOrder αinst✝¹:IntModule αinst✝:OrderedAdd αa:αb:αh:a ≤ b⊢ 3 • a + b ≤ 4 • b
```


### Display 4


```text
α:Type u_1inst✝⁵:LE αinst✝⁴:LT αinst✝³:Std.LawfulOrderLT αinst✝²:Std.IsLinearOrder αinst✝¹:IntModule αinst✝:OrderedAdd αa:αb:αc:α⊢ a = b + c → 2 • b ≤ c → 2 • a ≤ 3 • c
```


### Display 5


```text
α:Type u_1inst✝⁵:LE αinst✝⁴:LT αinst✝³:Std.LawfulOrderLT αinst✝²:Std.IsLinearOrder αinst✝¹:IntModule αinst✝:OrderedAdd αa:αb:αc:αd:αe:α⊢ 2 • a + b ≥ 0 →
  b ≥ 0 → c ≥ 0 → d ≥ 0 → e ≥ 0 → a ≥ 3 • c → c ≥ 6 • e → d - 5 • e ≥ 0 → a + b + 3 • c + d + 2 • e < 0 → False
```


### Display 6


```text
R:Type u_1inst✝⁵:LE Rinst✝⁴:LT Rinst✝³:Std.IsLinearOrder Rinst✝²:Std.LawfulOrderLT Rinst✝¹:CommRing Rinst✝:OrderedRing Ra:Rb:Rh:a * b ≤ 1⊢ b * 3 • a + 1 ≤ 4
```


### Display 7


```text
R:Type u_1inst✝⁵:LE Rinst✝⁴:LT Rinst✝³:Std.IsLinearOrder Rinst✝²:Std.LawfulOrderLT Rinst✝¹:CommRing Rinst✝:OrderedRing Ra:Rb:Rc:Rd:Re:Rf:R⊢ 2 • a + b ≥ 1 →
  b ≥ 0 →
    c ≥ 0 →
      d ≥ 0 → e • f ≥ 0 → a ≥ 3 • c → c ≥ 6 • e • f → d - f * e * 5 ≥ 0 → a + b + 3 • c + d + 2 • e • f < 0 → False
```

