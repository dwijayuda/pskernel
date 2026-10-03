<a id="grind-errors"></a>

# ProofScript — 16.1. Error Messages

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

grind combines reasoning such as congruence closure, propagation, case analysis, E-matching and algebraic/arithmetic procedures. Its selected lemmas, annotations and solver parameters determine the search problem. Keep these as native proof-producing facilities, not as a replacement for the kernel. The mirrored subchapters and examples retain their individual scopes and failure cases.

**Compiler and coverage boundary.** Lean 4.34 stable parameter-list changes for lia/grobner are inherited only under the selected tactic capability. A timeout must remain an incomplete-search result.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--grind--tactic/Error-Messages/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--grind--tactic/Error-Messages/index.html). Source Git blob: `4a337ed20d0b9752f9b3a6f2a4ccbd6fae9a2faa`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 16.1. Error Messages

When `grind` fails, it prints the remaining subgoal followed by all the information returned by its subsystems—the contents of the “shared whiteboard.” In particular, it presents equivalence classes of terms that it has determined to be equal. The two largest classes are shown as `True propositions` and `False propositions`, listing every literal currently known to be provable or refutable. Inspect these lists to spot missing facts or contradictory assumptions.
