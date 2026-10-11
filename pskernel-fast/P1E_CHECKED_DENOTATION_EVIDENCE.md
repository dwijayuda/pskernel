# PSKernel-Fast P1e — Checked-Source Proposition Denotation and Proof-Point Representation Gate

**Qualification: P1e verified RESTRICTED source-to-set cases, checked annotations and proof-point research. NO general Lean type soundness, proof irrelevance, checked declarations, Type-valued Pi graph model, model existence or consistency theorem.** The original P1d two-valued truth carrier is now **formally found insufficient** to support the intended distinguished proof point.

## Exact repository/CI identity

- Branch: [`research/pskernel-fast-clean-v3-20261011`](https://github.com/dwijayuda/pskernel/tree/research/pskernel-fast-clean-v3-20261011).
- **Latest qualified P1e source+audit commit:** [`8de790e40c0ecacea1ff80390f7b636bb9cffd63`](https://github.com/dwijayuda/pskernel/commit/8de790e40c0ecacea1ff80390f7b636bb9cffd63).
- [**Final green GitHub Actions run #38126457033**](https://github.com/dwijayuda/pskernel/actions/runs/38126457033), job `114431719831`, **completed success**.
- Toolchain: Lean `4.35.0-rc4` at official source `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- **Executed gate:** **86 successful Lake build jobs**, **38** independently authored V3 Lean files audited for import/placeholder boundaries, **84** exact theorem assumption receipts checked against `propext`, `Classical.choice`, `Quot.sound`, plus all G1–G4.3b smoke tests and prior formal proofs. New theorem receipts contain no `sorryAx`. The **bounded audit** does NOT verify the entire Lean runtime, any binary, foreign backend or correctness of the `SetTheoryBasis V` model-existence assumption.
- Source G4.3b checking engine unchanged from qualified semantic source `253afb42b477aacab22def288a2dd42d7ca9633b`; P1e adds **proof-only** interpretive mathematics, proof witnesses and CI imports. Existing proof branches/PRs are untouched.

## What P1e actually proves

### 1. Mathematical interpretation of a small, proposition-only syntax

[`Spec/PropInterp.lean`](src/PSKernelFast/Spec/PropInterp.lean) defines a separate, proof-only, PROP-valued semantic AST `PropInterpTerm` with `bvar`, `sort` and `propPi`. Its actual `interpProp V env` interpretation takes values in a caller-supplied set-theory carrier `V` using the already proved candidate `sortSet V` and semantic `propPi V A B` operators. The new `PropPiFibresValid` requires every actual semantic codomain fibre of a product to belong to the modeled `Prop` universe; this is an **explicit premise** and NOT inferred for arbitrary sources.

- `interpProp_pi_member`: given valid semantic fibres, the proposition-valued product interpretation belongs to `sortSet V 0`.
- `forallPropProp_fibres_valid`/`forallPropProp_is_false`: `∀ (P : Prop), P` has semantically valid fibres but denotes the FALSE truth value. Choose `P=False` as a real domain counterexample.
- `prop_imp_self_true`, `forallPropIdentity_fibres_valid`/`forallPropIdentity_is_true`: the **nested** formula `∀ (P : Prop), P → P` has valid proposition fibres and denotes TRUE, because an empty proposition domain vacuously implies itself, while the true proposition's fibres are true.
- Both expressions and their model values belong to the two-valued `Prop` carrier; no proof value for the tautology is constructed.

### 2. ACTUAL running checker → precise source erasure → denotation

[`Proof/PropInterpreterBridge.lean`](src/PSKernelFast/Proof/PropInterpreterBridge.lean) proves with no new admission capability:

- **Actual** `inferClosedGeneralPi []` accepts both precise dependent `Pi` expressions with the **exact symbolic** `imax` result types produced by the runtime checker.
- Both source expressions erase under **all** universe valuations into the intended independent proposition-semantic AST after forgetting its Prop-regime annotation; their inferred types erase to `Sort 0` at any valuation.
- `forallPropProp_checked_set_denotation` yields exact source success + erasure + modeled membership and false result.
- `forallPropIdentity_checked_set_denotation` yields the analogous real-source result for the nested dependent tautology, with **true** semantic result.

These are **TWO verified closed source cases**, not an induction showing every G4.3b-accepted type has the same mathematical semantics.

### 3. A reusable source-rule-backed annotation boundary

[`Proof/CheckedPropAnnotations.lean`](src/PSKernelFast/Proof/CheckedPropAnnotations.lean) introduces `CheckedPropAnnotation params ρ ctx e annotated`. Every Prop-valued Pi constructor carries **actual `GeneralPiRule` domain and codomain typing premises**, a recursively checked Prop codomain sort at the selected valuation, and recursively certified annotations of both source subterms. The proof layer cannot silently accept unchecked frontend "this codomain is Prop" hints.

- `checkedPropAnnotation_erases`: the annotation always forgets to exactly the real source's ground-universe erasure.
- `checkedPropAnnotation_typed`: it reconstructs a genuine G4.3b typing-rule derivation from the annotation.
- `checkedPropAnnotation_pi_model_member`: for an actually certified proposition-valued source Pi, **provided separately proved model-fibre validity**, its interpretation belongs to the denotation of its **actual G4.3b inferred `Sort (imax u v)`** at the selected valuation. The `imax` Prop-regime proof comes from the checked codomain level; not an untrusted assumption.
- Crucial open premise: **arbitrary semantic fibre validity still does not follow merely from `GeneralPiRule`**. Proving that implication is a genuine, major independent semantic-typing obligation.

[`Proof/CertifiedPropExamples.lean`](src/PSKernelFast/Proof/CertifiedPropExamples.lean) supplies **constructive annotation witnesses** for both real-world source examples (including nested dependent context indices). It applies the reusable theorem to independently proved model-fibre facts and pairs the witnesses with actual successful checker execution.

### 4. A necessary full-Lean proof-point representation defect FOUND

[`Spec/ProofPointCandidate.lean`](src/PSKernelFast/Spec/ProofPointCandidate.lean) confronts a real issue rather than preserving the previous P1d model for proof convenience:

- The original P1d candidate has `propTrue = powerset(empty) = {empty}`. **`old_true_forces_truth_value` proves that EVERY possible element of this `True` is ITSELF a truth value in the original `Prop` carrier.** Thus it cannot support the intended distinguished proof point lying outside `Prop`. The earlier P1d/P1e theorems remain mathematically valid *for that candidate*, but do not qualify it as the final Lean proof-irrelevant model.
- An independent **V2 candidate** introduces a separately tagged proof point, `TrueV2={proofPointV2}`, and `PropV2=power(TrueV2)`. Its proofs establish `proofPointV2 ∈ TrueV2` AND `proofPointV2 ∉ PropV2`; the new carrier has **exactly two distinct truth values**, and belongs to the first positive set universe.
- The V2 candidate **is not yet safe as the FINAL Lean representation**. Our simple point may still coincide with a writable Kuratowski pair/number/quotient encoding. Con-leche's more elaborate `ptTag` was designed to prevent such collisions. We have **not** transferred that con-leche theorem nor proved those disjointness conditions for our candidate.
- Consequently the V2 candidate is intentionally **NOT substituted into the canonical `sortSet`/runtime**. The migration requires a single representation that passes *all* proof-point, graph/eta, equality/quotient and positive-Type-universe closure obligations, then a fresh proof run for the old P1d/P1e source cases under it.

## Source/correction chronology

- `0be420bf` added the independent `PropInterp` mathematical interpreter; `74b25625` /`e19431a` added the first checked-source/model bridge. [Run #38125249272](https://github.com/dwijayuda/pskernel/actions/runs/38125249272) **PASS**: 80 jobs, 35 sources, 57 theorem receipts.
- `cf4f7314`/`99717de2` added a SECOND nested checked-source theorem with TRUE (where the first source has FALSE). [Run #38125488354](https://github.com/dwijayuda/pskernel/actions/runs/38125488354) **PASS**: 80 jobs, 35 sources, 65 theorem receipts.
- `4c7eb295` added checked Prop-binder annotation relation. Initial [run #38125744093](https://github.com/dwijayuda/pskernel/actions/runs/38125744093) FAILED due to a Lean case-pattern reference to binder names already substituted away; `2dc1fdce` fixed it *without weakening the theorem*. [Run #38125833123](https://github.com/dwijayuda/pskernel/actions/runs/38125833123) **PASS**: 82 jobs, 36 sources, 68 theorem receipts.
- `9ccb3b28` added actual source-backed annotation witnesses for both examples. [Run #38126055170](https://github.com/dwijayuda/pskernel/actions/runs/38126055170) **PASS**: 84 jobs, 37 sources, 74 theorem receipts.
- `faaa57ac` added a mathematical **no-go theorem** for the old proof point plus V2 candidate. [Run #38126383647](https://github.com/dwijayuda/pskernel/actions/runs/38126383647) initially FAILED a local membership abbreviation mismatch in the exhaustive carrier theorem. `8de790e40c0ecacea1ff80390f7b636bb9cffd63` fixes the reference; [run #38126457033](https://github.com/dwijayuda/pskernel/actions/runs/38126457033) **PASS**: 86 jobs, 38 sources and 84 theorem receipts, including the no-go result and all V2 point/carrier proofs.

## Next gated work — do NOT jump to model consistency

1. Decide the **FINAL proof-point representation** by separately verifying graph/tuple/quotient/numeral disjointness, not only proofPoint∉Prop. Compare proof-only con-leche constructions (currently Lean rc3) with our pinned rc4 semantics. Retain correct performance freedom but do not optimize before the semantic representation is sound.
2. Build an annotation-aware set interpreter covering both `Prop` and `Type` Pi, with actual binder/body type-sort witnesses and independently established `WellDenoted` fibre obligations. Then prove a general semantic typing result over the relevant supported checker rules.
3. Prove mathematical beta/let denotation preservation (distinct from the already proved *syntactic* erasure correspondence), proof irrelevance, disjoint proof-point and positive Type-valued function graph semantics.
4. Only after actual source+model soundness: add positive-sound WHNF/DefEq, checked immutable declaration environment, source-matched modeled axiom rules and model-extension proof, then conditional `model_exists`/`no_derived_False`. Real Lean kernel CPU/RSS and official Lean 4.35 differential acceptance remain unmeasured here.

**NO full Lean kernel provider, proof checker or theorem-admission API was introduced. General relative consistency remains OPEN.**
