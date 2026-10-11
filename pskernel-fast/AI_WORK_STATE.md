# PSKernel-Fast V3 — current work state

Updated 11 October 2026. **Qualified P1n semantic substitution and P1o six-form SOURCE-CERTIFIED model typing, source-derived beta, and fragment-relative no-inhabitant theorem.** The runtime G4.3b/G4.4b checker and admission boundary are unchanged.

## Authority and operating rules

Repository `dwijayuda/pskernel`; ONLY development branch `research/pskernel-fast-clean-v3-20261011`. Target official Lean **4.35.0-rc4**, upstream `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. This is the user's public open-source compiler/kernel correctness, Lean semantics and formal-methods project.

GitHub connector and cloud Actions ONLY: no Desktop Commander, local repository checkout/files/builds/tests. Before writes refresh live HEAD and affected blobs; use serial non-force expected-HEAD updates, preserving concurrent work and all other branches/PR #89. One small production semantic authority remains the goal. Performance/correctness outrank preserving transitional proof syntax. No new global model axioms, `sorryAx`, unchecked native proof evaluation, name-based proof admission or universal quotient-freshness assumptions.

**Public proof admission remains disabled; admitted declarations = 0.** Official Lean is a test oracle, not an acceptance vote. No new runtime speed, memory or size result is claimed here.

## Exact verified SOURCE checkpoint

**`84c27f8c953e3c3aed8ae7fc047a37437ce06d19`**, [Actions **38152604792**](https://github.com/dwijayuda/pskernel/actions/runs/38152604792), job `114508960699`, completed **SUCCESS**. The complete job log was inspected and the workflow completion metadata checked.

- Exact pinned Lean version/upstream commit confirmed.
- Architecture fence: **62 independent Lean source files**.
- Five strict disjoint assumption gates: **157 + 17 + 28 + 18 + 12 = 232 exact theorem receipts**.
- Allowed global axioms unchanged: `propext`, `Classical.choice`, `Quot.sound`; no qualified `sorryAx` dependency. Explicit `[SetTheoryBasis V]` remains a substantial quantified mathematical premise, not a constructed instance.
- New focused closure: **46-job** Lake invocation; old closure: **109-job** invocation. They share outputs and MUST NOT be added as unique build jobs.
- Every existing regression passed, including native C++ kernel differential15 equalities,2 rejection controls,1 documented incompleteness case. New beta/let and Prop/Type identity source execution equations are kernel-checked `rfl`, not `native_decide`.

Docs/policy commits may follow this code checkpoint. Always read live HEAD and matching CI before claiming the whole branch is green or writing. [Human evidence](P1N_P1O_SOURCE_MODEL_EVIDENCE.md) / [JSON evidence](P1N_P1O_SOURCE_MODEL_EVIDENCE.json).

## P1n — actual substitution and general dependent semantic contexts

`Spec/AnnotatedSubstitution.lean` has a six-constructor proof-side annotated syntax with codomain ranks only on Pi/lambda. Lifting and substitution preserve those annotations. The interpretation reuses the existing point/graph `modelPi`, `modelLam`, and uniform `modelApp` rather than inventing another model.

Semantic lifting and substitution hold at **arbitrary de Bruijn depth**, through lambdas, Pis and lets, under arbitrary model environments. `forget_lift`/`forget_instantiate` commute with the ALREADY source-matched erased operations. `Proof/SourceSubstitutionModel.lean` then composes those results with the real `eraseExpr_instantiate` theorem for `KExpr.instantiateBVar`. It proves exact actual source-substitution erasure together with the semantic equation. A P1m-to-new-annotation embedding preserves both erasure and interpretation.

`AnnotatedContextValid` interprets stored binder domain A at index i in `dropModelEnv(i+1) env`, the environment OUTSIDE that binder and all newer binders. Its extension and source lookup theorem agree with the runtime's actual lifted-domain inference. This removes the old Sort-only variable guard; a dependent proof variable x:P is handled as a value of P, not mislabeled as P:Prop.

P1n source beta initially has explicit semantic fibre/body/argument premises, while zeta follows directly from substitution. Actual closed polymorphic identity lambdas at Prop and Type are checked and modeled, not merely their Pi types. These18 receipts are now green, including the repaired zero-depth/lookup proofs.

## P1o — source-only certificates derive six-form semantic typing

`Proof/SourceModelTyping.lean` defines `SourceModelTyping params valuation sourceCtx annotatedCtx sourceTerm sourceType annTerm annType`. It is an inductive **proof-side** relation for Sort, dependent variables, Pi, lambda, application and restricted let. Its constructors contain source syntax/typing/rank/erasure constraints, not V, model values, semantic fibre assumptions or an assumed `stepSound` theorem.

Lambda requires a certificate for the sort of the body TYPE, fixing its Prop/Type representation. App requires matching annotated Pi-domain and argument type; let substitutes the actual value into the result type annotation. This is stronger than an arbitrary raw `GeneralPiRule` derivation: completeness/certificate synthesis is NOT yet established.

The general induction derives term membership in its interpreted type under a valid dependent model context, including ALL Pi fibres, lambda body membership, app elimination and let substitution. Separate theorems reconstruct the unchanged `GeneralPiRule` and prove both source TERM and TYPE erasures. A new exact-type-uniqueness theorem for the existing six-rule judgment identifies the actual runtime inferred type. `sourceModelTyping_executed` combines real `inferClosedGeneralPi` success WITH the source certificate to obtain the exact result, erasures and semantic membership.

`sourceModelTyping_beta` derives P1n's semantic fibre/body/argument premises FROM these source certificates and context validity, then proves the actual source beta step, corresponding erasures and interpretation equality. This is more than the previous model-only beta equation, but not arbitrary G4.4b reduction soundness.

## Precisely scoped conditional no-inhabitant theorem

`sourceModelTyping_no_false` proves: under supplied `[SetTheoryBasis V]`, there is no closed `SourceModelTyping` certificate for a source term of the literal proposition `forall P:Prop, P`, with the canonical annotation `.pi 0 (.sort 0) (.bvar 0)`. The soundness induction would place its value in the empty model set, a contradiction.

**This is a fragment-relative conditional result, NOT the full executable kernel consistency capstone, NOT a constructed model, and NOT a theorem about the native constant `False` plus arbitrary declarations.** It quantifies over source certificates; general synthesis/coherence for all accepted programs, typed substitution closure, unrestricted reductions and the declaration/axiom policy remain open. Global full-source-soundness/consistency/admission flags stay false.

The certificate relation is demonstrably inhabited: `polyIdentity_sourceModelTyping` constructs the generic polymorphic identity certificate at any well-formed level, including proof variables at rank zero.

## Actual execution-to-model qualification

`Proof/SourceModelExecution.lean` constructs certificates for `(fun x : Sort 1 => x) (Sort 0)` and `let x : Sort 1 := Sort 0; x`. The lambda's codomain annotation is TWO, because its body TYPE `Sort 1` has type `Sort 2`; the fixtures do not guess rank1 from the returned value.

Proved by kernel-checked `rfl`: both actual inferences return `Sort 1`, and actual G4.4b `compareTypedWH` joins the beta and let sources at fuel2. Erasures and modeled inferred-type membership follow from the GENERAL P1o theorem. Both interpreted terms equal `taggedSortSet V 0`; beta uses the source-derived semantic theorem. Actual Prop/Type polymorphic identity executions now also use the same general six-form theorem, not separate hand-written model membership assumptions.

P1o audit has12 receipts:8 general typing/source results plus4 actual execution/example results. Existing157/17/28/18 gates remain enabled and unchanged.

## Concurrent work, failures and repairs retained honestly

- Prior documented P1l/P1m qualified checkpoint: `08726939c2ca8016e76d15f43b3c7e24de3253cf`,202 receipts.
- Concurrent P1n `6be10d34f5c84b8090250c3c76a24080fc4cdad2`: run38146184136 failed zero-depth `dropModelEnv` rewriting.
- Concurrent `b1637bcb213c186932011c6d1407584a3c09b3cd` already repaired that equation and added the source bridge; run38146857844 failed a dependent-match source lookup proof. This continuation preserved that work instead of overwriting it.
- `bc72301a49b6734f41d8ce825615d8dbab9b7b84`: explicit dependent-match cases repair lookup, same statement; run38151366924 SUCCESS. P1n220 total receipts.
- `d9d41ad0fdf422819b5245f4d3c6327c481d86fe`: new P1o typing candidate; run38151851502 failed on reserved identifier `at` and a normalized erasure equality proof.
- `17d9f3a15ed0695734fc3bda88cbd2931bf1ebca`: rename binders to `aTy` and close normalized equality with reflexivity; same theorem/assumptions; run38152288366 SUCCESS,228 receipts.
- `84c27f8c953e3c3aed8ae7fc047a37437ce06d19`: execution qualification; run38152604792 SUCCESS first run,232 receipts.

Do not describe this as an all-first-run-green continuation. No theorem statement/model assumption/regression expectation was weakened. Existing source warnings remain. Runtime `GeneralPiFormation`, `Substitution`, `TypedNormalization`, native differential fixtures and `SetTheoryBasis` are unchanged. Old G4.4a microbenchmarks are NOT evidence about new model work or G4.4b performance.

## Next exact dependency

Prove weakening and substitution CLOSURE of `SourceModelTyping` certificates, annotation coherence, and certificate construction from the actual checker evidence where possible. General semantic substitution is ALREADY proved; the missing theorem is typed/certified substitution and coverage, not another unrelated toy substitution.

Use these results to derive a coherent source-to-annotation interpretation for arbitrary accepted reductions, including function-spine congruence. Only then discharge the full model `stepSound` premise in `TypedSteps.denotation_preserved`; generalize its current universe0 `A : Type` when integrating universe-polymorphic V. Current head-beta source-certified theorem and the specific executed examples do not prove arbitrary two-sided G4.4b common-reduct soundness.

Later obligations: complete typed conversion (congruence, symbolic levels, proof irrelevance/eta, environment/transparency identity), typed quotient/inductive/primitive semantics, immutable FullyChecked declaration-model extension, explicit modeled-axiom policy, model-existence premise/capstone, broad official compatibility and representative CPU/RSS/allocation benchmarks. No blanket quotient freshness: unrestricted images may equal the proof point.

## Preserved history

The previous active work state/handoff are preserved byte-for-byte through existing Git blobs at `history/AI_WORK_STATE_THROUGH_P1M.md` (`a6770a979d65f8cc3f483d0d8ed0fe9f911f1f3e`) and `history/AI_HANDOFF_THROUGH_P1M.md` (`25f070e4238a8786e5389441a8046af72309512d`). Earlier histories/evidence remain intact. Stage-prefixed old policy booleans describe those original stages; current P1n/P1o groups and live qualification govern continuation.
