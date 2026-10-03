<a id="simp-vs-rw"></a>

# ProofScript — 15.7. Simplification vs Rewriting

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

simp uses selected rewrite theorems and congruence reasoning to construct checked evidence. simp only restricts the simplification set; simp at changes a hypothesis or location. The normal forms chosen by a library affect proof maintenance and automation. A simplifier is not a privileged evaluator permitted to replace an unproved goal with success.

**Compiler and coverage boundary.** Track the exact simp set, local hypotheses and configuration. A changed tactic script is not necessarily a changed theorem, but a cached proof must still match its dependency identity.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The-Simplifier/Simplification-vs-Rewriting/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The-Simplifier/Simplification-vs-Rewriting/index.html). Source Git blob: `0bdf92397da62716346e27676548923fc00a8519`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 15.7. Simplification vs Rewriting

Both `simp` and `rw`/`rewrite` use equational lemmas to replace parts of terms with equivalent alternatives. Their intended uses and their rewriting strategies differ, however. Tactics in the `simp` family are primarily used to reformulate a problem in a standardized way, making it more amenable to both human understanding and further automation. In particular, simplification should never render an otherwise-provable goal impossible. Tactics in the `rw` family are primarily used to apply hand-selected transformations that do not always preserve provability nor place terms in standardized forms. These different emphases are reflected in the differences of behavior between the two families of tactics.

The `simp` tactics primarily rewrite from the inside out. The smallest possible expressions are simplified first so that they can unlock further simplification opportunities for the surrounding expressions. The `rw` tactics select the leftmost outermost subterm that matches the pattern, rewriting it a single time. Both tactics allow their strategy to be overridden: when adding a lemma to a simp set, the `↓` modifier causes it to be applied prior to the simplification of subterms, and the `occs` field of `rw`'s configuration parameter allows a different occurrence to be selected, either via a whitelist or a blacklist.
