<a id="grind-tactic"></a>
<a id="grind"></a>

# ProofScript — 16. The grind tactic

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

grind combines reasoning such as congruence closure, propagation, case analysis, E-matching and algebraic/arithmetic procedures. Its selected lemmas, annotations and solver parameters determine the search problem. Keep these as native proof-producing facilities, not as a replacement for the kernel. The mirrored subchapters and examples retain their individual scopes and failure cases.

## ProofScript way of writing it


```proofscript
theorem equalityChain {α: Type}(a: α, b: α, c: α)
    (hab: a = b)(hbc: b = c): a = c := by
  grind
```

**Compiler and coverage boundary.** Lean 4.34 stable parameter-list changes for lia/grobner are inherited only under the selected tactic capability. A timeout must remain an incomplete-search result.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--grind--tactic/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--grind--tactic/index.html). Source Git blob: `9d28eeee3d1d24db04cb9a9d7617f708b8d62a8d`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 16. The grind tactic

## Tutorials

- [Using `grind` for Ordered Maps](https://lean-lang.org/doc/tutorials/4.34.0-rc2//#grind-index-map)

The `grind` tactic uses techniques inspired by modern SMT solvers to automatically construct proofs. It produces proofs by incrementally collecting sets of facts, deriving new facts from the existing ones using a set of cooperating techniques. Behind the scenes, all proofs are by contradiction, so there is no operational distinction between the expected conclusion and the premises; `grind` always attempts to derive a contradiction.

Picture a virtual whiteboard. Every time `grind` discovers a new equality, inequality, or Boolean literal it writes that fact on the board, merges equivalent terms into buckets, and invites each engine to read from—and add back to—the shared whiteboard. In particular, because all true propositions are equal to `True` and all false propositions are equal to `False`, `grind` tracks a set of known facts as part of tracking equivalence classes.

The cooperating engines are:

- [congruence closure](Congruence-Closure/index.md#--tech-term-Congruence-closure),
- [constraint propagation](Constraint-Propagation/index.md#--tech-term-Constraint-propagation),
- [E‑matching](E___matching/index.md#--tech-term-E-matching),
- guided [case analysis](Case-Analysis/index.md#grind-split), and
- a suite of satellite theory solvers, including both [linear integer arithmetic](Linear-Integer-Arithmetic/index.md#cutsat) and [commutative rings](Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_/index.md#grind-ring).

Like other tactics, `grind` produces ordinary Lean proof terms for every fact it adds. Lean’s standard library is already annotated with `@[grind]` attributes, so common lemmas are discovered automatically.

`grind` is **not** designed for goals whose search space explodes combinatorially—think large‑`n` pigeonhole instances, graph‑coloring reductions, high‑order N‑queens boards, or a 200‑variable Sudoku encoded as Boolean constraints. Such encodings require thousands (or millions) of case‑splits that overwhelm `grind`’s branching search. For bit‑level or pure Boolean combinatorial problems, use `bv_decide`. The `bv_decide` tactic calls a state‑of‑the‑art SAT solver (e.g. CaDiCaL or Kissat) and then returns a compact, machine‑checkable certificate. All heavy search happens outside Lean; the certificate is replayed and verified inside Lean, so trust is preserved (verification time scales with certificate size).

<a id="Congruence-Closure"></a>
Congruence Closure 

This proof succeeds instantly using [congruence closure](Congruence-Closure/index.md#--tech-term-Congruence-closure), which discovers sets of equal terms.

```proofscript
example (a b c : Nat) (h₁ : a = b) (h₂ : b = c) :
    a = c := by
  grind
```

<a id="Algebraic-Reasoning"></a>
Algebraic Reasoning 

This proof uses `grind`'s commutative ring solver.

```proofscript
example [CommRing α] [NoNatZeroDivisors α] (a b c : α) :
    a + b + c = 3 →
    a ^ 2 + b ^ 2 + c ^ 2 = 5 →
    a ^ 3 + b ^ 3 + c ^ 3 = 7 →
    a ^ 4 + b ^ 4 = 9 - c ^ 4 := by
  grind
```

<a id="Finite-Field-Reasoning"></a>
Finite-Field Reasoning 

Arithmetic operations on `Fin` overflow, wrapping around to `0` when the result would be outside the bound. `grind` can use this fact to prove theorems such as this:

```proofscript
example (x y : Fin 11) :
    x ^ 2 * y = 1 →
    x * y ^ 2 = y →
    y * x = 1 := by
  grind
```

<a id="Linear-Integer-Arithmetic-with-Case-Analysis"></a>
Linear Integer Arithmetic with Case Analysis 

```proofscript
example (x y : Int) :
    27 ≤ 11 * x + 13 * y →
    11 * x + 13 * y ≤ 45 →
    -10 ≤ 7 * x - 9 * y →
    7 * x - 9 * y ≤ 4 →
    False := by
  grind
```

1. [16.1. Error Messages](Error-Messages/index.md#grind-errors)
2. [16.2. Minimizing `grind` calls](Minimizing--grind--calls/index.md#The-Lean-Language-Reference--The--grind--tactic--Minimizing--grind--calls)
3. [16.3. Local Definitions](Local-Definitions/index.md#The-Lean-Language-Reference--The--grind--tactic--Local-Definitions)
4. [16.4. Congruence Closure](Congruence-Closure/index.md#congruence-closure)
5. [16.5. Constraint Propagation](Constraint-Propagation/index.md#grind-propagation)
6. [16.6. Case Analysis](Case-Analysis/index.md#grind-split)
7. [16.7. E‑matching](E___matching/index.md#e-matching)
8. [16.8. Associativity and Commutativity](Associativity-and-Commutativity/index.md#grind-ac)
9. [16.9. Linear Integer Arithmetic](Linear-Integer-Arithmetic/index.md#cutsat)
10. [16.10. Algebraic Solver (Commutative Rings, Fields)](Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_/index.md#grind-ring)
11. [16.11. Linear Arithmetic Solver](Linear-Arithmetic-Solver/index.md#grind-linarith)
12. [16.12. Annotating Libraries for `grind`](Annotating-Libraries-for--grind/index.md#grind-annotation)
13. [16.13. Reducibility](Reducibility/index.md#The-Lean-Language-Reference--The--grind--tactic--Reducibility)
14. [16.14. Bigger Examples](Bigger-Examples/index.md#grind-bigger-examples)

## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
a:Natb:Natc:Nath₁:a = bh₂:b = c⊢ a = c
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
α:Type u_1inst✝¹:CommRing αinst✝:NoNatZeroDivisors αa:αb:αc:α⊢ a + b + c = 3 → a ^ 2 + b ^ 2 + c ^ 2 = 5 → a ^ 3 + b ^ 3 + c ^ 3 = 7 → a ^ 4 + b ^ 4 = 9 - c ^ 4
```


### Display 4


```text
x:Fin 11y:Fin 11⊢ x ^ 2 * y = 1 → x * y ^ 2 = y → y * x = 1
```


### Display 5


```text
x:Inty:Int⊢ 27 ≤ 11 * x + 13 * y → 11 * x + 13 * y ≤ 45 → -10 ≤ 7 * x - 9 * y → 7 * x - 9 * y ≤ 4 → False
```

