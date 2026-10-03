<a id="the-simplifier"></a>

# ProofScript — 15. The Simplifier

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

simp uses selected rewrite theorems and congruence reasoning to construct checked evidence. simp only restricts the simplification set; simp at changes a hypothesis or location. The normal forms chosen by a library affect proof maintenance and automation. A simplifier is not a privileged evaluator permitted to replace an unproved goal with success.

## ProofScript way of writing it


```proofscript
function plusZero(n: Nat): Nat := n + 0

theorem plusZeroIdentity(n: Nat): plusZero(n) = n := by
  simp [plusZero]
```

**Compiler and coverage boundary.** Track the exact simp set, local hypotheses and configuration. A changed tactic script is not necessarily a changed theorem, but a cached proof must still match its dependency identity.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The-Simplifier/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The-Simplifier/index.html). Source Git blob: `c071a77e58f9507aaaee036b6f61b13797c7ce07`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 15. The Simplifier

The simplifier is one of the most-used features of Lean. It performs inside-out rewriting of terms based on a database of simplification rules. The simplifier is highly configurable, and a number of tactics use it in different ways.

1. [15.1. Invoking the Simplifier](Invoking-the-Simplifier/index.md#simp-tactic-naming)
2. [15.2. Rewrite Rules](Rewrite-Rules/index.md#simp-rewrites)
3. [15.3. Simp sets](Simp-sets/index.md#simp-sets)
4. [15.4. Simp Normal Forms](Simp-Normal-Forms/index.md#simp-normal-forms)
5. [15.5. Terminal vs Non-Terminal Positions](Terminal-vs-Non-Terminal-Positions/index.md#terminal-simp)
6. [15.6. Configuring Simplification](Configuring-Simplification/index.md#simp-config)
7. [15.7. Simplification vs Rewriting](Simplification-vs-Rewriting/index.md#simp-vs-rw)
