# PSKernel-Fast P1d — Conditional Set-Theoretic Universe and Prop-Product Foundations

**Status:** independently machine-checked *partial denotational semantics*, **not** a model of the full checker, general dependent function types, semantic theorem admission, or relative consistency.

## Exact evidence

- **Qualified source + strict audit:** [`3b70a90bdcf23dd0b6e8843132abb2916f05058a`](https://github.com/dwijayuda/pskernel/commit/3b70a90bdcf23dd0b6e8843132abb2916f05058a).
- **Independently inspected GitHub Actions:** [run 38124170798](https://github.com/dwijayuda/pskernel/actions/runs/38124170798), job `114424937667`, **completed success**.
- **Pinned toolchain:** Lean `4.35.0-rc4`, source commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- **Executed CI:** **76 successful Lake build jobs**, **33** independently authored Lean V3 sources audited, **48 exact theorem-assumption receipts** (now supports Lean's two distinct receipt formats), and all G1–G4.3b regression suites including P1d's executable symbolic `Pi`/Prop-regime fixtures passed.
- **Assumption inventory:** the individual new proofs use subsets of Lean's `propext`, `Classical.choice`, `Quot.sound`; the mathematical statements additionally take a **caller-supplied `SetTheoryBasis V` parameter**. That parameter is a set of mathematical *model assumptions*, NOT a globally constructed instance or an extra Lean axiom named in `#print axioms`. The 48-theorem scanner is bounded and does not prove compiler/runtime correctness or that such a `V` exists in Lean.

## Part A — explicit set-theory basis, without a fake global instance

[`Spec/SetTheoryBasis.lean`](src/PSKernelFast/Spec/SetTheoryBasis.lean) defines an independent ZF-style assumption interface: membership and extensionality, pairing, union, powerset, regularity, replacement images, and an omega-indexed Grothendieck universe hierarchy characterized by a Tarski-style closure/size matrix. This follows the *method*, not the source/TCB, of [con-leche](https://github.com/leanprover/con-leche). Unlike a broad theorem statement that silently assumes the answer, there is **no assumed Pi-product universe membership law**.

Proved from this basis:

- Existence of an empty set by regularity plus transitivity of a universe stage. Empty-set existence is **derived**, not an additional class field.
- Exact non-membership of every element in that derived empty set.
- Downward subset closure and powerset closure of a Grothendieck stage from its defining clauses.
- Membership of an early stage in the stage two successors ahead using transitivity.

A `SetTheoryBasis` instance itself is **not** constructed. Conditional semantic theorems cannot establish the model's own consistency without a suitable model-existence assumption.

## Part B — a candidate two-valued Prop carrier, distinguished from Type universes

[`Spec/UniverseSemantics.lean`](src/PSKernelFast/Spec/UniverseSemantics.lean) defines:

- `propTruthUniverse V = powerset (powerset (emptySet V))` as a **candidate truth-value carrier** for impredicative `Sort 0`.
- `sortSet V 0 = propTruthUniverse V`; `sortSet V (n+1) = univChain (n+2)` for positive Type universes. The offset is intentional and keeps `Prop` distinct from ordinary Grothendieck universe carriers.
- `propFalse = emptySet V` and `propTrue = powerset(emptySet V)` (definitions in `PropPi.lean`).

**Proved:** both truth values belong to the carrier, they are distinct, **they are the only two members**, and the carrier itself belongs to the first positive Type universe. The key theorem `sort_member_succ` shows for ALL symbolic universe valuations `ρ`:
`Mem (sortSet V (u.denote ρ)) (sortSet V ((succ u).denote ρ))`.

This is a **genuine conditional set-membership theorem for Sort**, *not* a proof every proposition has an interpretation, every proof is proof-irrelevant, or a declaration cannot inhabit False.

**Unresolved compatibility concern:** con-leche's complete model additionally chooses a distinguished proof point and a disjoint truth-value representation to support proof irrelevance, graph inversion and eta/recursors. Our simple two-valued carrier is a **candidate**; it may need revision when those future invariants are formalized. Do not freeze it as the final Lean `Prop` interpretation merely because Sort membership works.

## Part C — a checked, valuation-independent Pi/Prop classification

[`Proof/PiModelRegime.lean`](src/PSKernelFast/Proof/PiModelRegime.lean) connects the independent arithmetic theorem
`numericIMax u v = 0 ↔ v = 0` and bounds on positive `imax` to the ACTUAL `GeneralPiRule.pi` evidence:

- Extracts the domain-sort and **recursively checked codomain-sort** from the original typed Pi derivation; these are not caller-supplied annotations.
- Shows, for **every** universe valuation, that the inferred Pi result sort is `Prop` exactly when the checked codomain sort is `Prop`.
- Carries the same property from an actual successful **closed** `inferClosedGeneralPi` call.
- Relates actual `Sort` inference to the conditional `sort_member_succ` mathematical interpretation.

This is the source-validated basis for a future con-leche-inspired `PropWhen` binder annotation. It does **not** validate arbitrary lambda-body type annotations, synthesize a complete set denotation of open terms, or prove the Pi product has the required universe membership.

## Part D — first actual semantic operator for proposition-valued dependent Pi

[`Spec/PropPi.lean`](src/PSKernelFast/Spec/PropPi.lean) defines a mathematical `propPi V A B` from an **already interpreted domain set** `A : V` and **already interpreted family** `B : V → V`. The output is `propTrue` iff every `x ∈ A` has `B x = propTrue`, otherwise `propFalse`.

Proved, with **no new Pi-closure axiom**:

1. `propPi_member_prop`: product result is a member of `sortSet V 0`, **regardless of the domain's universe rank** (the required impredicative proposition-valued closure property at the set level).
2. `propPi_true_iff`: exact universal-quantifier truth condition over all elements of the domain.
3. `propPi_false_of_counterexample`: one false fibre at an actual domain element makes the whole product false.
4. `propPi_exact_truth_range`: the product is necessarily one of the two carrier truth values.

**Essential caveat:** `A` and `B` are already semantically interpreted sets supplied as theorem variables. No theorem yet proves `A = ⟦sourceDomain⟧`, `B x = ⟦sourceCodomain[x]⟧`, or that inferred `GeneralPiRule` source terms really denote members of their inferred types. That bridge, including proof-point behavior and Type-valued dependent products, is the next major challenge.

## Failed checkpoints and corrections (preserved, not hidden)

- Initial [run 38123034598](https://github.com/dwijayuda/pskernel/actions/runs/38123034598) compiled the model/Prop classification but the strict audit rejected two extra theorem receipts emitted by Lean as **"does not depend on any axioms"** instead of the scanner's existing "depends on axioms" pattern. `9dd8822` added both formats plus synthetic negative tests. [Run 38123176812](https://github.com/dwijayuda/pskernel/actions/runs/38123176812) then passed 74 jobs and 34 receipts.
- First correct `Prop`-carrier/tower version `9cc69e3` passed [run 38123501449](https://github.com/dwijayuda/pskernel/actions/runs/38123501449): **74 jobs, 32 files, 42 receipts**. The earliest simplistic `Sort 0 = univChain 0` scaffold was intentionally REPLACED because it was inappropriate for impredicative proof-irrelevant Prop.
- Initial exhaustive truth-carrier theorem [run 38123675429](https://github.com/dwijayuda/pskernel/actions/runs/38123675429) failed a local `Mem` abbreviation rewrite; the exact theorem was fixed without changing the carrier. [Run 38123791358](https://github.com/dwijayuda/pskernel/actions/runs/38123791358) passed **74 jobs, 32 files, 44 receipts**.
- Initial proposition-valued dependent Pi [run 38124019587](https://github.com/dwijayuda/pskernel/actions/runs/38124019587) failed over-eager simplification of a semantic predicate; explicit positive/negative branch rewrites were introduced without changing any definition/theorem statement. Final [run 38124170798](https://github.com/dwijayuda/pskernel/actions/runs/38124170798) passed **76 jobs, 33 files, 48 receipts**.

## Next proofs, in order

1. Define an annotation-bearing erased term interpreter `interp V env expr` *separate from kernel execution*, certify binder codomain sort/Prop regime from the real checker, and formalize `WellDenoted` for an arbitrary valid semantic environment. The current simple `ErasedExpr` does not carry Prop-regime metadata.
2. Prove source-to-denotation correctness for the **Sort** and a small **Prop-valued dependent Pi** rule by connecting actual validated domain/body terms to the mathematical sets `A` and `B`. The existing theorem applies only to semantic values already supplied.
3. Construct Type-valued dependent function graphs and their `imax` universe closure from actual set-theory axioms, together with a disjoint proof-point representation and proof irrelevance. Compare the proof cost with adapting compatible con-leche proof-only mathematics (its current toolchain is 4.35.0-rc3, ours is rc4).
4. Prove source-matched positive WHNF/DefEq denotational preservation and fully checked inference, then checked immutable environment/declaration model extension and relative `model_exists`/`no_derived_False`. Optimize runtime separately after actual kernel-only CPU/RSS measurements.

**No theorem admission API, full Lean 4.35 compatibility, true set-model instance, complete model soundness or consistency proof is claimed.**
