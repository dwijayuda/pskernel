<a id="basic-props"></a>

# ProofScript — 19. Basic Propositions

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Truth and falsity, conjunction/disjunction, implication, negation, universal/existential quantification and equality keep their native definitions. An existential proof contains logical witness evidence, but elimination restrictions determine when it can construct runtime data. Equality transports dependent values only through justified terms. Computed Boolean comparison does not automatically produce equality evidence.

## ProofScript way of writing it


```proofscript
theorem swapAnd {P: Prop}{Q: Prop}(h: P ∧ Q): Q ∧ P := by
  exact ⟨h.right, h.left⟩

theorem existsSelf(n: Nat): ∃ m: Nat, m = n := by
  exact ⟨n, rfl⟩
```

**Compiler and coverage boundary.** Preserve Prop elimination, proof irrelevance and universe rules. Erasure may remove irrelevant proofs but not the data they certify.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Propositions/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Propositions/index.html). Source Git blob: `77d424aa3d8cdf6bb042769e8c97823e3a969b85`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 19. Basic Propositions

With the exception of implication and universal quantification, logical connectives and quantifiers are implemented as [inductive types](../The-Type-System/Inductive-Types/index.md#--tech-term-Inductive-types) in the `Prop` universe. In some sense, the connectives described in this chapter are not special—they could be implemented by any user. However, these basic connectives are used pervasively in the standard library and built-in proof automation tools.

1. [19.1. Truth](Truth/index.md#true-false)
2. [19.2. Logical Connectives](Logical-Connectives/index.md#The-Lean-Language-Reference--Basic-Propositions--Logical-Connectives)
3. [19.3. Quantifiers](Quantifiers/index.md#The-Lean-Language-Reference--Basic-Propositions--Quantifiers)
4. [19.4. Propositional Equality](Propositional-Equality/index.md#propositional-equality)
