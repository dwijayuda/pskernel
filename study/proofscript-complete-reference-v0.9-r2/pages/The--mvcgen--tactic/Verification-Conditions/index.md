<a id="The-Lean-Language-Reference--The--mvcgen--tactic--Verification-Conditions"></a>

# ProofScript — 17.3. Verification Conditions

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Verification-condition generation connects a computation to a program-logic specification. Predicate transformers, state/error behavior, supported monads and loop interfaces are part of that connection. The final proof must establish the approved property of the actual computation, not merely prove unrelated obligations emitted by a buggy generator. Intrinsic contracts are experimental at the selected pin.

**Compiler and coverage boundary.** Keep the native requires/ensures grammar, generated theorem identities, residual proof sections and assumption reports. The inherited example uses native spelling intentionally; it is already an L-class ProofScript form.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--mvcgen--tactic/Verification-Conditions/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--mvcgen--tactic/Verification-Conditions/index.html). Source Git blob: `f9d352a392b83af744cde375d87d684a2f21549e`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 17.3. Verification Conditions

The `mvcgen` tactic converts a goal that's expressed in terms of `SPred` and weakest preconditions to a set of invariants and verification conditions that, together, suffice to prove the original goal. In particular, [Hoare triples](../Predicate-Transformers/index.md#--tech-term-Hoare-triple) are defined in terms of weakest preconditions, so `mvcgen` can be used to prove them.

The verification conditions for a goal are generated as follows:

1. A number of simplifications and rewrites are applied.
2. The goal should now be of the form `P ⊢ₛ wp⟦e⟧ Q` (that is, an entailment from some set of stateful assumptions to the weakest precondition that implies a desired postcondition).
3. [Reducible](../../Definitions/Recursive-Definitions/index.md#--tech-term-Reducible) constants and definitions marked `@[spec]` in the expression `e` are unfolded.
4. If the expression is an application of an [auxiliary matching function](../../Elaboration-and-Compilation/index.md#--tech-term-auxiliary-matching-functions) or a conditional (`ite` or `dite`), then it is first simplified. The [discriminant](../../Terms/Pattern-Matching/index.md#--tech-term-match-discriminants) of each matcher is simplified, and the entire term is reduced in an attempt to eliminate the matcher or conditional. If this fails, then a new goal is generated for each branch.
5. If the expression is an application of a constant, then the applicable lemmas marked `@[spec]` are attempted in priority order. Lean includes specification lemmas for constants such as `bind`, `pure`, and `ForIn.forIn` that result from desugaring [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-notation. Instantiating the lemma will sometimes discharge its premises, in particular schematic variables due to definitional equalities with the goal. Assumptions of type `Invariant` are never instantiated this way, however. If the spec lemma's precondition or postcondition do not exactly match those of the goal, then new metavariables are created that prove the necessary entailments. If these cannot be immediately discharged using simple automation that attempts to use local assumptions and decomposes conjunctions in postconditions, then they remain as verification conditions.
6. Each remaining goal created by this process is recursively processed for verification conditions if it has the form `P ⊢ₛ wp⟦e⟧ Q`. If not, it is added to the set of invariants or verification conditions.
7. The resulting subgoals for invariants and verification conditions are assigned suitable names in the proof state.
8. Depending on the tactic's configuration parameters, `mvcgen_trivial` and `mleave` are attempted in each verification condition.

Verification condition generation can be improved by defining appropriate [specification lemmas](../Predicate-Transformers/index.md#--tech-term-Specification-lemmas) for a library. The presence of good specification lemmas results in fewer generated verification conditions. Additionally, ensuring that the [simp normal form](../../The-Simplifier/Simp-Normal-Forms/index.md#--tech-term-simp-normal-form) of terms is suitable for pattern matching, and that there are sufficient lemmas in the default simp set to reduce every possible term to that normal form, can lead to more conditionals and pattern matches being eliminated.
