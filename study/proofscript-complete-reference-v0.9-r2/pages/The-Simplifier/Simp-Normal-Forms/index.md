<a id="simp-normal-forms"></a>

# ProofScript — 15.4. Simp Normal Forms

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

simp uses selected rewrite theorems and congruence reasoning to construct checked evidence. simp only restricts the simplification set; simp at changes a hypothesis or location. The normal forms chosen by a library affect proof maintenance and automation. A simplifier is not a privileged evaluator permitted to replace an unproved goal with success.

**Compiler and coverage boundary.** Track the exact simp set, local hypotheses and configuration. A changed tactic script is not necessarily a changed theorem, but a cached proof must still match its dependency identity.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The-Simplifier/Simp-Normal-Forms/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The-Simplifier/Simp-Normal-Forms/index.html). Source Git blob: `d240674cf7adfdeb41f10b9d3f5a080e554346f7`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 15.4. Simp Normal Forms

The default [simp set](../Simp-sets/index.md#--tech-term-simp-set) contains all the theorems and simplification procedures marked with the `simp` attribute. The 
<a id="--tech-term-simp-normal-form"></a>
*simp normal form* of an expression is the result of applying the default simp set via the `simp` tactic until no more rules can be applied. When an expression is in simp normal form, it is as reduced as possible according to the default simp set, often making it easier to work with in proofs.

The `simp` tactic **does not guarantee confluence**, which means that the simp normal form of an expression may depend on the order in which the elements of the default simp set are applied. The order in which the rules are applied can be changed by assigning priorities when setting the `simp` attribute.

When designing a Lean library, it's important to think about what the appropriate simp normal form for the various combinations of the library's operators is. This can serve as a guide when selecting which rules the library should add to the default simp set. In particular, the right-hand side of simp lemmas should be in simp normal form; this helps ensure that simplification terminates. Additionally, each concept in the library should be expressed through one simp normal form, even if there are multiple equivalent ways to state it. If a concept is stated in two different ways in different simp lemmas, then some desired simplifications may not occur because the simplifier does not connect them.

Even though simplification doesn't need to be confluent, striving for confluence is helpful because it makes the library more predictable and tends to reveal missing or poorly chosen simp lemmas. The default simp set is as much a part of a library's interface as the type signatures of the constants that it exports.

Libraries should not add rules to the default simp set that don't mention at least one constant defined in the library. Otherwise, importing a library could change the behavior of `simp` for some unrelated library. If a library relies on additional simplification rules for definitions or declarations from other libraries, please create a custom simp set and either instruct users to use it or provide a dedicated tactic.
