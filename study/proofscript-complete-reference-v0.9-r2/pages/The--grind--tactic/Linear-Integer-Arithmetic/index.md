<a id="cutsat"></a>

# ProofScript — 16.9. Linear Integer Arithmetic

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

grind combines reasoning such as congruence closure, propagation, case analysis, E-matching and algebraic/arithmetic procedures. Its selected lemmas, annotations and solver parameters determine the search problem. Keep these as native proof-producing facilities, not as a replacement for the kernel. The mirrored subchapters and examples retain their individual scopes and failure cases.

**Compiler and coverage boundary.** Lean 4.34 stable parameter-list changes for lia/grobner are inherited only under the selected tactic capability. A timeout must remain an incomplete-search result.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--grind--tactic/Linear-Integer-Arithmetic/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--grind--tactic/Linear-Integer-Arithmetic/index.html). Source Git blob: `48479f0bafaa536aa9850e51cea3e90205fa9b80`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next"></a>

---

## 16.9. Linear Integer Arithmetic

The linear integer arithmetic solver implements a model-based decision procedure for linear integer arithmetic. The solver can process four categories of linear polynomial constraints (where `p` is a [linear polynomial](https://en.wikipedia.org/wiki/Degree_of_a_polynomial)):

  Equality

`p = 0`

  Divisibility

`d ∣ p`

  Inequality

`p ≤ 0`

  Disequality

`p ≠ 0`

It is complete for linear integer arithmetic, and natural numbers are supported by converting them to integers with `Int.ofNat`. Support for additional types that can be embedded into `Int` can be added via instances of `Lean.Grind.ToInt`. Nonlinear terms (e.g. `x * x`) are allowed, and are represented as variables. The solver is additionally capable of propagating information back to the metaphorical `grind` whiteboard, which can trigger further progress from the other subsystems. By default, it is enabled; it can be disabled using the flag `-lia`

<a id="Examples-of-Linear-Integer-Arithmetic"></a>
Examples of Linear Integer Arithmetic 

All of these statements can be proved using the linear integer arithmetic solver. In the first example, the left-hand side must be a multiple of 2, and thus cannot be 5:

```proofscript
example {x y : Int} : 2 * x + 4 * y ≠ 5 := by
  grind
```

The solver supports mixing equalities and inequalities:

```proofscript
example {x y : Int} :
    2 * x + 3 * y = 0 →
    1 ≤ x →
    y < 1 := by
  grind
```

It also supports linear divisibility constraints:

```proofscript
example (a b : Int) :
    2 ∣ a + 1 →
    2 ∣ b + a →
    ¬ 2 ∣ b + 2 * a := by
  grind
```

Without `lia`, `grind` cannot prove the statement:

```proofscript
example (a b : Int) :
    2 ∣ a + 1 →
    2 ∣ b + a →
    ¬ 2 ∣ b + 2 * a := by
  grind -lia
```
<a id="--verso-unique-1593"></a>


```lean
`grind` failed
grinda b:Inth:2 ∣ a + 1h_1:2 ∣ a + bh_2:2 ∣ 2 * a + b⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] 2 ∣ a + 1[prop] 2 ∣ a + b[prop] 2 ∣ 2 * a + b[eqc] True propositions[prop] 2 ∣ a + b[prop] 2 ∣ a + 1[prop] 2 ∣ 2 * a + b[ematch] E-matching patterns[thm] Nat.dvd_mul_left_of_dvd: [@Dvd.dvd `[Nat] `[Nat.instDvd] #3 #2, @HMul.hMul `[Nat] `[Nat] `[Nat] `[instHMul] #0 #2][thm] Nat.dvd_mul_right_of_dvd: [@Dvd.dvd `[Nat] `[Nat.instDvd] #3 #2, @HMul.hMul `[Nat] `[Nat] `[Nat] `[instHMul] #2 #0][linarith] Linarith assignment for `Int`[assign] a := 0[assign] b := 0
```

<a id="cutsat-qlia"></a>
### 16.9.1. Rational Solutions

The solver is complete for linear integer arithmetic. However, the search can become vast with very few constraints, but the solver was not designed to perform massive case-analysis. The `qlia` option to `grind` reduces the search space by instructing the solver to accept rational solutions. With this option, the solver is likely to be faster, but it is incomplete.

<a id="Rational-Solutions"></a>
Rational Solutions 

The following example has a rational solution, but does not have integer solutions:

```proofscript
example {x y : Int} :
    27 ≤ 13 * x + 11 * y →
    13 * x + 11 * y ≤ 30 →
    -10 ≤ 9 * x - 7 * y →
    9 * x - 7 * y > 4 := by
  grind
```

Because it uses the rational solution, `grind` fails to refute the negation of the goal when `+qlia` is specified:

```proofscript
example {x y : Int} :
    27 ≤ 13 * x + 11 * y →
    13 * x + 11 * y ≤ 30 →
    -10 ≤ 9 * x - 7 * y →
    9 * x - 7 * y > 4 := by
  grind +qlia
```
<a id="--verso-unique-1601"></a>


```lean
`grind` failed
grindx y:Inth:-13 * x + -11 * y + 27 ≤ 0h_1:13 * x + 11 * y + -30 ≤ 0h_2:-9 * x + 7 * y + -10 ≤ 0h_3:9 * x + -7 * y + -4 ≤ 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] -13 * x + -11 * y + 27 ≤ 0[prop] 13 * x + 11 * y + -30 ≤ 0[prop] -9 * x + 7 * y + -10 ≤ 0[prop] 9 * x + -7 * y + -4 ≤ 0[eqc] True propositions[prop] -9 * x + 7 * y + -10 ≤ 0[prop] -13 * x + -11 * y + 27 ≤ 0[prop] 9 * x + -7 * y + -4 ≤ 0[prop] 13 * x + 11 * y + -30 ≤ 0[cutsat] Assignment satisfying linear constraints[assign] x := 62/117[assign] y := 2
```

The rational model constructed by the solver is in the section `Assignment satisfying linear constraints` in the goal diagnostics.

<a id="The-Lean-Language-Reference--The--grind--tactic--Linear-Integer-Arithmetic--Nonlinear-Constraints"></a>
### 16.9.2. Nonlinear Constraints

The solver currently does support nonlinear constraints, and treats nonlinear terms such as `x * x` as variables.

<a id="Nonlinear-Terms"></a>
Nonlinear Terms 

The linear integer arithmetic solver fails to prove this theorem:

```proofscript
example (x : Int) : x * x ≥ 0 := by
  grind
```
<a id="--verso-unique-1606"></a>

<a id="--verso-unique-1611"></a>


```lean
`grind` failed
grindx:Inth:x * x + 1 ≤ 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] x * x + 1 ≤ 0[eqc] True propositions[prop] x * x + 1 ≤ 0[ematch] E-matching patterns[thm] Nat.pow_pos: [@HPow.hPow `[Nat] `[Nat] `[Nat] `[instHPow] #2 #1][thm] Nat.div_pow_of_pos: [@HPow.hPow `[Nat] `[Nat] `[Nat] `[instHPow] #2 #1][cutsat] Assignment satisfying linear constraints[assign] x := 0[assign] 「x ^ 2」 := -1
```

From the perspective of the linear integer arithmetic solver, it is equivalent to:

```proofscript
example {y : Int} (x : Int) : y ≥ 0 := by
  grind
```

```lean
`grind` failed
grindx:Inth:x * x + 1 ≤ 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] x * x + 1 ≤ 0[eqc] True propositions[prop] x * x + 1 ≤ 0[ematch] E-matching patterns[thm] Nat.pow_pos: [@HPow.hPow `[Nat] `[Nat] `[Nat] `[instHPow] #2 #1][thm] Nat.div_pow_of_pos: [@HPow.hPow `[Nat] `[Nat] `[Nat] `[instHPow] #2 #1][cutsat] Assignment satisfying linear constraints[assign] x := 0[assign] 「x ^ 2」 := -1
```

This can be seen by setting the option `trace.grind.lia.assert` to `true`, which traces all constraints processed by the solver.

```proofscript
example (x : Int) : x*x ≥ 0 := by
  set_option trace.grind.lia.assert true in
  grind
```

```lean
[grind.lia.assert] -1*「x ^ 2 + 1」 + 「x ^ 2」 + 1 = 0[grind.lia.assert] 「x ^ 2」 + 1 ≤ 0
```

The term `x ^ 2` is “quoted” in `「x ^ 2」 + 1 ≤ 0` to indicate that `x ^ 2` is treated as a variable.

<a id="The-Lean-Language-Reference--The--grind--tactic--Linear-Integer-Arithmetic--Division-and-Modulus"></a>
### 16.9.3. Division and Modulus

The solver supports linear division and modulo operations.

<a id="Linear-Division-and-Modulo"></a>
Linear Division and Modulo 

```proofscript
example (x y : Int) :
    x = y / 2 →
    y % 2 = 0 →
    y - 2 * x = 0 := by
  grind
```

<a id="The-Lean-Language-Reference--The--grind--tactic--Linear-Integer-Arithmetic--Algebraic-Processing"></a>
### 16.9.4. Algebraic Processing

The solver normalizes commutative (semi)ring expressions.

<a id="Commutative-_LPAR_Semi_RPAR_ring-Normalization"></a>
Commutative (Semi)ring Normalization 

Commutative ring normalization allows this goal to be solved:

```proofscript
example (a b : Nat)
    (h₁ : a + 1 ≠ a * b * a)
    (h₂ : a * a * b ≤ a + 1) :
    b * a ^ 2 < a + 1 := by
  grind
```

<a id="cutsat-mbtc"></a>
### 16.9.5. Propagating Information

The solver also implements 
<a id="--tech-term-model-based-theory-combination"></a>
*model-based theory combination*, which is a mechanism for propagating equalities back to the metaphorical shared whiteboard. These additional equalities may in turn trigger new congruences. Model-based theory combination increases the size of the search space; it can be disabled using the option `grind -mbtc`.

<a id="Propagating-Equalities"></a>
Propagating Equalities 

In the example above, the linear inequalities and disequalities imply `y = 0`:

```proofscript
example (f : Int → Int) (x y : Int) :
    f x = 0 →
    0 ≤ y → y ≤ 1 → y ≠ 1 →
    f (x + y) = 0 := by
  grind
```

Consequently `x = x + y`, so `f x = f (x + y)` by [congruence](../Congruence-Closure/index.md#--tech-term-Congruence-closure). Without model-based theory combination, the proof gets stuck:

```proofscript
example (f : Int → Int) (x y : Int) :
    f x = 0 →
    0 ≤ y → y ≤ 1 → y ≠ 1 →
    f (x + y) = 0 := by
  grind -mbtc
```
<a id="--verso-unique-1629"></a>


```lean
`grind` failed
grindf:Int → Intx y:Inth:f x = 0h_1:-1 * y ≤ 0h_2:y + -1 ≤ 0h_3:¬y = 1h_4:¬f (x + y) = 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] f x = 0[prop] -1 * y ≤ 0[prop] y + -1 ≤ 0[prop] ¬y = 1[prop] ¬f (x + y) = 0[eqc] True propositions[prop] y + -1 ≤ 0[prop] -1 * y ≤ 0[eqc] False propositions[prop] y = 1[prop] f (x + y) = 0[eqc] Equivalence classes[eqc] {f x, 0}[cutsat] Assignment satisfying linear constraints[assign] x := 0[assign] y := 0[assign] f x := 0[assign] f (x + y) := 4[ring] Ring `Int`[diseqs] Disequalities[_] ¬y + -1 = 0
```

<a id="cutsat-ToInt"></a>
### 16.9.6. Other Types

The LIA solver can also process linear constraints that contain natural numbers. It converts them into integer constraints using `Int.ofNat`.

<a id="Natural-Numbers-as-Linear-Integer-Arithmetic"></a>
Natural Numbers as Linear Integer Arithmetic 

```proofscript
example (x y z : Nat) :
    x < y + z →
    y + 1 < z →
    z + x < 3 * z := by
  grind
```

There is an extensible mechanism via the `Lean.Grind.ToInt` type class to tell the solver that a type embeds in the integers. Using this, we can solve goals such as:

```proofscript
example (a b c : Fin 11) : a ≤ 2 → b ≤ 3 → c = a + b → c ≤ 5 := by
  grind

example (a : Fin 2) : a ≠ 0 → a ≠ 1 → False := by
  grind

example (a b c : UInt64) : a ≤ 2 → b ≤ 3 → c - a - b = 0 → c ≤ 5 := by
  grind
```

<a id="Lean___Grind___ToInt___mk"></a>

**type class**

```text
Lean.Grind.ToInt.{u} (α : Type u)
  (range : outParam Lean.Grind.IntInterval) : Type u
```

`ToInt α I` asserts that `α` can be embedded faithfully into an interval `I` in the integers.

**Instance Constructor**

```text
Lean.Grind.ToInt.mk.{u}
```

**Methods**

```text
toInt : α → Int
```

The embedding function.

```text
toInt_inj : ∀ (x y : α), ↑x = ↑y → x = y
```

The embedding function is injective.

```text
toInt_mem : ∀ (x : α), ↑x ∈ range
```

The embedding function lands in the interval.

<a id="Lean___Grind___IntInterval___co"></a>

**inductive type**

```text
Lean.Grind.IntInterval : Type
```

An interval in the integers (either finite, half-infinite, or infinite).

**Constructors**

```text
Lean.Grind.IntInterval.co (lo hi : Int) :
  Lean.Grind.IntInterval
```

The finite interval `[lo, hi)`.

```text
Lean.Grind.IntInterval.ci (lo : Int) :
  Lean.Grind.IntInterval
```

The half-infinite interval `[lo, ∞)`.

```text
Lean.Grind.IntInterval.io (hi : Int) :
  Lean.Grind.IntInterval
```

The half-infinite interval `(-∞, hi)`.

```text
Lean.Grind.IntInterval.ii : Lean.Grind.IntInterval
```

The infinite interval `(-∞, ∞)`.

<a id="The-Lean-Language-Reference--The--grind--tactic--Linear-Integer-Arithmetic--Implementation-Notes"></a>
### 16.9.7. Implementation Notes

The implementation of the linear integer arithmetic solver is inspired by Section 4 of Jovanović and de Moura (2023)Dejan Jovanović and Leonardo de Moura, 2023. [“Cutting to the Chase: Solving Linear Integer Arithmetic”](https://link.springer.com/chapter/10.1007/978-3-642-22438-6_26). In *Automated Deduction: CADE '23.* (LNCS 6803). Compared to the paper, it includes several enhancements and modifications such as:

- extended constraint support (equality and disequality),
- an optimized encoding of the `Cooper-Left` rule using a “big”-disjunction instead of fresh variables, and
- decision variable tracking for case splits (disequalities, `Cooper-Left`, `Cooper-Right`).

The solver procedure builds a model (that is, an assignment of the variables in the term) incrementally, resolving conflicts through constraint generation. For example, given a partial model `{x := 1}` and constraint `3 ∣ 3 * y + x + 1`:

- The solver cannot extend the model to `y` because `3 ∣ 3 * y + 2` is unsatisfiable.
- Thus, it resolves the conflict by generating the implied constraint `3 ∣ x + 1`.
- The new constraint forces the solver to find a new assignment for `x`.

When assigning a variable `y`, the solver considers:

- The best upper and lower bounds (inequalities).
- A divisibility constraint.
- All disequality constraints where `y` is the maximal variable.

The `Cooper-Left` and `Cooper-Right` rules handle the combination of inequalities and divisibility. For unsatisfiable disequalities `p ≠ 0`, the solver generates the case split: `p + 1 ≤ 0 ∨ -p + 1 ≤ 0`.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`grind` failed
grinda b:Inth:2 ∣ a + 1h_1:2 ∣ a + bh_2:2 ∣ 2 * a + b⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] 2 ∣ a + 1[prop] 2 ∣ a + b[prop] 2 ∣ 2 * a + b[eqc] True propositions[prop] 2 ∣ a + b[prop] 2 ∣ a + 1[prop] 2 ∣ 2 * a + b[ematch] E-matching patterns[thm] Nat.dvd_mul_left_of_dvd: [@Dvd.dvd `[Nat] `[Nat.instDvd] #3 #2, @HMul.hMul `[Nat] `[Nat] `[Nat] `[instHMul] #0 #2][thm] Nat.dvd_mul_right_of_dvd: [@Dvd.dvd `[Nat] `[Nat.instDvd] #3 #2, @HMul.hMul `[Nat] `[Nat] `[Nat] `[instHMul] #2 #0][linarith] Linarith assignment for `Int`[assign] a := 0[assign] b := 0
```


### Display 2


```text
`grind` failed
grindx y:Inth:-13 * x + -11 * y + 27 ≤ 0h_1:13 * x + 11 * y + -30 ≤ 0h_2:-9 * x + 7 * y + -10 ≤ 0h_3:9 * x + -7 * y + -4 ≤ 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] -13 * x + -11 * y + 27 ≤ 0[prop] 13 * x + 11 * y + -30 ≤ 0[prop] -9 * x + 7 * y + -10 ≤ 0[prop] 9 * x + -7 * y + -4 ≤ 0[eqc] True propositions[prop] -9 * x + 7 * y + -10 ≤ 0[prop] -13 * x + -11 * y + 27 ≤ 0[prop] 9 * x + -7 * y + -4 ≤ 0[prop] 13 * x + 11 * y + -30 ≤ 0[cutsat] Assignment satisfying linear constraints[assign] x := 62/117[assign] y := 2
```


### Display 3


```text
`grind` failed
grindx:Inth:x * x + 1 ≤ 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] x * x + 1 ≤ 0[eqc] True propositions[prop] x * x + 1 ≤ 0[ematch] E-matching patterns[thm] Nat.pow_pos: [@HPow.hPow `[Nat] `[Nat] `[Nat] `[instHPow] #2 #1][thm] Nat.div_pow_of_pos: [@HPow.hPow `[Nat] `[Nat] `[Nat] `[instHPow] #2 #1][cutsat] Assignment satisfying linear constraints[assign] x := 0[assign] 「x ^ 2」 := -1
```


### Display 4


```text
`grind` failed
grindy x:Inth:y + 1 ≤ 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] y + 1 ≤ 0[eqc] True propositions[prop] y + 1 ≤ 0[cutsat] Assignment satisfying linear constraints[assign] y := -1[assign] x := 2
```


### Display 5


```text
[grind.lia.assert] -1*「x ^ 2 + 1」 + 「x ^ 2」 + 1 = 0[grind.lia.assert] 「x ^ 2」 + 1 ≤ 0`grind` failed
grindx:Inth:x * x + 1 ≤ 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] x * x + 1 ≤ 0[eqc] True propositions[prop] x * x + 1 ≤ 0[ematch] E-matching patterns[thm] Nat.pow_pos: [@HPow.hPow `[Nat] `[Nat] `[Nat] `[instHPow] #2 #1][thm] Nat.div_pow_of_pos: [@HPow.hPow `[Nat] `[Nat] `[Nat] `[instHPow] #2 #1][cutsat] Assignment satisfying linear constraints[assign] x := 0[assign] 「x ^ 2」 := -1
```


### Display 6


```text
`grind` failed
grindf:Int → Intx y:Inth:f x = 0h_1:-1 * y ≤ 0h_2:y + -1 ≤ 0h_3:¬y = 1h_4:¬f (x + y) = 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] f x = 0[prop] -1 * y ≤ 0[prop] y + -1 ≤ 0[prop] ¬y = 1[prop] ¬f (x + y) = 0[eqc] True propositions[prop] y + -1 ≤ 0[prop] -1 * y ≤ 0[eqc] False propositions[prop] y = 1[prop] f (x + y) = 0[eqc] Equivalence classes[eqc] {f x, 0}[cutsat] Assignment satisfying linear constraints[assign] x := 0[assign] y := 0[assign] f x := 0[assign] f (x + y) := 4[ring] Ring `Int`[diseqs] Disequalities[_] ¬y + -1 = 0
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
x:Inty:Int⊢ 2 * x + 4 * y ≠ 5
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
x:Inty:Int⊢ 2 * x + 3 * y = 0 → 1 ≤ x → y < 1
```


### Display 4


```text
a:Intb:Int⊢ 2 ∣ a + 1 → 2 ∣ b + a → ¬2 ∣ b + 2 * a
```


### Display 5


```text
x:Inty:Int⊢ 27 ≤ 13 * x + 11 * y → 13 * x + 11 * y ≤ 30 → -10 ≤ 9 * x - 7 * y → 9 * x - 7 * y > 4
```


### Display 6


```text
x:Int⊢ x * x ≥ 0
```


### Display 7


```text
y:Intx:Int⊢ y ≥ 0
```


### Display 8


```text
x:Inty:Int⊢ x = y / 2 → y % 2 = 0 → y - 2 * x = 0
```


### Display 9


```text
a:Natb:Nath₁:a + 1 ≠ a * b * ah₂:a * a * b ≤ a + 1⊢ b * a ^ 2 < a + 1
```


### Display 10


```text
f:Int → Intx:Inty:Int⊢ f x = 0 → 0 ≤ y → y ≤ 1 → y ≠ 1 → f (x + y) = 0
```


### Display 11


```text
x:Naty:Natz:Nat⊢ x < y + z → y + 1 < z → z + x < 3 * z
```


### Display 12


```text
a:Fin 11b:Fin 11c:Fin 11⊢ a ≤ 2 → b ≤ 3 → c = a + b → c ≤ 5
```


### Display 13


```text
a:Fin 2⊢ a ≠ 0 → a ≠ 1 → False
```


### Display 14


```text
a:UInt64b:UInt64c:UInt64⊢ a ≤ 2 → b ≤ 3 → c - a - b = 0 → c ≤ 5
```

