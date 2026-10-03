<a id="congruence-closure"></a>

# ProofScript — 16.4. Congruence Closure

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

grind combines reasoning such as congruence closure, propagation, case analysis, E-matching and algebraic/arithmetic procedures. Its selected lemmas, annotations and solver parameters determine the search problem. Keep these as native proof-producing facilities, not as a replacement for the kernel. The mirrored subchapters and examples retain their individual scopes and failure cases.

**Compiler and coverage boundary.** Lean 4.34 stable parameter-list changes for lia/grobner are inherited only under the selected tactic capability. A timeout must remain an incomplete-search result.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--grind--tactic/Congruence-Closure/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--grind--tactic/Congruence-Closure/index.html). Source Git blob: `57860055e32909db4c33b041dae47c97ef2d9d59`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 16.4. Congruence Closure

<a id="--tech-term-Congruence-closure"></a>
*Congruence closure* maintains equivalence classes of terms under the reflexive, symmetric, and transitive closure of “is equal to” *and* the rule that equal arguments yield equal function results. Formally, if `a = a'` and `b = b'`, then `f a b = f a' b'` is added. The algorithm merges equivalence classes until a fixed point is reached. If a contradiction is discovered, then the goal can be closed immediately.

Using the analogy of the shared whiteboard:

1. Every hypothesis `h : t₁ = t₂` writes a line connecting `t₁` and `t₂`.
2. Whenever two terms are connected by one or more lines, they're considered to be equal. Soon, whole constellations (`f a`, `g (f a)`, …) are connected.
3. If two different constructors of the same inductive type are connected by one or more lines, then a contradiction is discovered and the goal is closed. For example, equating `True` and `False` or `none` and `some 1` would be a contradiction.

<a id="Congruence-Closure-next"></a>
Congruence Closure 

This theorem is proved using congruence closure:

```proofscript
example {α} (f g : α → α) (x y : α)
    (h₁ : x = y) (h₂ : f y = g y) :
    f x = g x := by
  grind
```

Initially, `f y`, `g y`, `x`, and `y` are in separate equivalence classes. The congruence closure engine uses `h₁` to merge `x` and `y`, after which the equivalence classes are `{x, y}`, `f y`, and `g y`. Next, `h₂` is used to merge `f y` and `g y`, after which the classes are `{x, y}` and `{f y, g y}`. This is sufficient to prove that `f x = g x`, because `y` and `x` are in the same class.

Similar reasoning is used for constructors:

```proofscript
example (a b c : Nat) (h : a = b) : (a, c) = (b, c) := by
  grind
```

Because the pair constructor `Prod.mk` obeys congruence, the tuples become equal as soon as `a` and `b` are placed in the same class.

<a id="The-Lean-Language-Reference--The--grind--tactic--Congruence-Closure--Congruence-Closure-vs___-Simplification"></a>
### 16.4.1. Congruence Closure vs. Simplification

Congruence closure is a fundamentally different operation from simplification:

- `simp` *rewrites* a goal, replacing occurrences of `t₁` with `t₂` as soon as it sees `h : t₁ = t₂`. The rewrite is directional and destructive.
- `grind` *accumulates* equalities bidirectionally. No term is rewritten; instead, both representatives live in the same class. All other engines ([E‑matching](../E___matching/index.md#--tech-term-E-matching), theory solvers, [propagation](../Constraint-Propagation/index.md#--tech-term-Constraint-propagation)) can query these classes and add new facts, then the closure updates incrementally.

This makes congruence closure especially robust in the presence of symmetrical reasoning, mutual recursion, and large nestings of constructors where rewriting would duplicate work.

## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
α:Sort u_1f:α → αg:α → αx:αy:αh₁:x = yh₂:f y = g y⊢ f x = g x
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
a:Natb:Natc:Nath:a = b⊢ (a, c) = (b, c)
```

