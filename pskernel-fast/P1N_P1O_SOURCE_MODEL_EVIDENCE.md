# P1n / P1o — Semantic substitution and source-certified six-form typing

Qualified 11 October 2026. This checkpoint repairs the pending substitution/source-lookup build, derives semantic typing for a six-form SOURCE-CERTIFICATE relation, and proves a narrowly scoped conditional no-inhabitant theorem. It is NOT a completed model-existence proof, all-checker-success soundness theorem, full Lean kernel or consistency capstone.

## Exact qualification

**Source:** `84c27f8c953e3c3aed8ae7fc047a37437ce06d19`.
**Completed SUCCESS:** [Actions38152604792](https://github.com/dwijayuda/pskernel/actions/runs/38152604792), job `114508960699`.

Complete cloud job log inspected; pinned official Lean **4.35.0-rc4** and upstream `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364` confirmed. Architecture fence passed **62** independent Lean sources. All five independent exact-name assumption gates passed:

| Gate | Exact receipts |
|---|---:|
| Original proof suite | 157 |
| G4.4b/P1k | 17 |
| P1l/P1m | 28 |
| P1n substitution/source bridge | 18 |
| P1o source typing/execution | 12 |
| **Distinct total** | **232** |

Compared with the last documented P1l/P1m checkpoint this adds **30** reviewed receipts and four proof-side Lean modules. Some P1n work was concurrent and was preserved/repaired, not newly authored by this continuation. No global allowlist was broadened: only `propext`, `Classical.choice`, `Quot.sound`; no qualified theorem depends on `sorryAx`. The substantial quantified `[SetTheoryBasis V]` premise does not appear as a global axiom token and is NOT a constructed set model.

Focused dependency closure built in46 Lake jobs, old closure in109 jobs with shared outputs; counts are NOT additive. All existing regression and native C++ kernel differential stages passed (15 supported equalities,2 rejection controls,1 documented equality gap). New actual infer/conversion equations are kernel-checked `rfl`, not `native_decide`. Existing warnings remain.

## 1. The pending repair is committed and qualified

The branch had concurrently advanced from failing `6be10d34...` to `b1637bcb...` before this continuation's first write. That concurrent commit already made the explicit zero-depth `dropModelEnv` rewrite and added `Proof/SourceSubstitutionModel.lean`. Its remaining error was a dependent-match simplification in `source_bound_annotated_model`.

Commit `bc72301a...` splits the actual lookup branches, derives equality of the returned source domains using the existing lookup equations, and closes the impossible None branch. It changes neither the theorem statement nor runtime inference. [CI38151366924](https://github.com/dwijayuda/pskernel/actions/runs/38151366924) passed all stages, qualifying the repaired P1n work.

## 2. Actual source substitution meets semantic substitution

[Spec/AnnotatedSubstitution.lean](src/PSKernelFast/Spec/AnnotatedSubstitution.lean) represents bvar, sort, app, lambda, Pi and let with rank annotations only where the Prop/Type representation needs them. Its mathematical interpretation reuses the existing tagged/graph algebra. Semantic lifting and instantiation are proved at arbitrary depth, through every binder, without assuming a typing or substitution-soundness law.

[Proof/SourceSubstitutionModel.lean](src/PSKernelFast/Proof/SourceSubstitutionModel.lean) composes annotation erasure with the existing source `eraseExpr_instantiate` refinement. The source operation is the ACTUAL `KExpr.instantiateBVar`, and the resulting annotation is structurally instantiated with preserved ranks. A separate embedding preserves the older P1m Pi interpretation, so this is not an unrelated model.

The dependent semantic context interprets a stored domain A at index i outside its own/newer binders:

`env(i) in interpAnnotated(dropModelEnv(i+1,env), A)`.

Its extension and source-variable lookup laws agree with the source checker's actual lifted-domain type. This handles dependent and proof-variable domains without the older syntactic-Sort-only guard.

Erasure matching alone remains insufficient to justify a rank annotation: rank-zero lambdas denote the proof point, positive-rank lambdas denote graphs. The next result supplies source-side rank constraints instead of inferring semantic validity from erasure.

## 3. Six-form source-certified semantic typing

[Proof/SourceModelTyping.lean](src/PSKernelFast/Proof/SourceModelTyping.lean) defines `SourceModelTyping` over source contexts, annotated contexts, source terms/types and their annotations. Its constructors are SOURCE-ONLY: no model V, set membership, all-fibres-valid assumption or `stepSound` premise.

Sort and dependent-variable rules model the real source judgments. Pi recursively certifies its domain/body sorts. Lambda additionally certifies the sort of its body TYPE, fixing the Prop/Type regime. App requires an annotated Pi and an argument with the same annotated domain; the result annotation substitutes the actual argument. Let similarly uses the actual value in its result type.

The general induction proves membership of a term's interpretation in its type's interpretation for every such certificate in a valid model context. Pi fibres, lambda body membership, argument membership and substituted let-result membership are DERIVED, not supplied as semantic inputs. Separate proofs reconstruct `GeneralPiRule` and both source TERM/TYPE erasures.

`generalPiRule_type_unique` proves exact syntactic type uniqueness for the unchanged raw six-rule source judgment. `sourceModelTyping_executed` therefore connects a REAL successful `inferClosedGeneralPi` run plus its source certificate to the exact inferred output, erasures and modeled inferred type.

The extra certificate is still required: this does NOT prove that every successful G4.3b run has a `SourceModelTyping` certificate. Lambda's body-type sort evidence, full certificate synthesis/coherence and typed substitution closure remain obligations.

## 4. Source-derived beta and actual runtime qualification

`sourceModelTyping_beta` derives the P1n beta theorem's fibre/body/argument membership premises from source certificates and model-context validity. It proves the actual beta operational step, redex/reduct erasures and model equality. This closes those explicit semantic premises for CERTIFIED source beta cases, not every arbitrary runtime step.

[Proof/SourceModelExecution.lean](src/PSKernelFast/Proof/SourceModelExecution.lean) constructs actual certificates for:

```lean
(fun x : Sort 1 => x) (Sort 0)
let x : Sort 1 := Sort 0; x
```

The lambda codomain annotation is2, because the body TYPE is `Sort 1 : Sort 2`. Both actual inferences return `Sort 1`; the actual G4.4b `compareTypedWH` joins them at fuel2. These runtime equations are proved by `rfl`. Their source erasures and interpreted membership follow from the GENERAL source-model theorem, and both denotations equal `taggedSortSet V 0`. The beta equality uses the SOURCE-DERIVED theorem, not an assumed model equation.

Generic polymorphic identity source certificates include `x:P` in the Prop case. Actual Prop/Type identity lambda executions now instantiate the same general six-form theorem rather than relying solely on separately worked model examples.

## 5. Narrow conditional no-inhabitant theorem

`sourceModelTyping_no_false` states that, assuming `[SetTheoryBasis V]`, no closed source term has a `SourceModelTyping` certificate at the literal proposition `forall P:Prop,P` with canonical annotation `.pi 0 (.sort 0) (.bvar 0)`. Semantic typing would place the term value in the modeled empty set, yielding contradiction.

This is a **source-certified-fragment relative result**, not a proof that the model exists, not consistency of all runtime-accepted terms, not a theorem about arbitrary declarations/native constant `False`, and not the full PSKernel-Fast consistency capstone. The source relation is nonvacuous (generic identity certificates), but its coverage and closure under arbitrary reduction are still unproved. Public proof admission remains closed with zero admitted declarations.

## 6. Verification provenance

| Commit | Exact CI | Outcome |
|---|---|---|
| `6be10d34f5c84b8090250c3c76a24080fc4cdad2` | [38146184136](https://github.com/dwijayuda/pskernel/actions/runs/38146184136) | Earlier concurrent P1n failed zero-depth rewrite |
| `b1637bcb213c186932011c6d1407584a3c09b3cd` | [38146857844](https://github.com/dwijayuda/pskernel/actions/runs/38146857844) | Concurrent rewrite repair; source lookup proof still failed |
| `bc72301a49b6734f41d8ce825615d8dbab9b7b84` | [38151366924](https://github.com/dwijayuda/pskernel/actions/runs/38151366924) | Dependent lookup repair; full P1n green |
| `d9d41ad0fdf422819b5245f4d3c6327c481d86fe` | [38151851502](https://github.com/dwijayuda/pskernel/actions/runs/38151851502) | P1o build failed reserved variable `at` and erasure equality proof |
| `17d9f3a15ed0695734fc3bda88cbd2931bf1ebca` | [38152288366](https://github.com/dwijayuda/pskernel/actions/runs/38152288366) | Rename to `aTy`, normalized equality by reflexivity; same claims green |
| `84c27f8c953e3c3aed8ae7fc047a37437ce06d19` | [38152604792](https://github.com/dwijayuda/pskernel/actions/runs/38152604792) | Actual execution qualification and all232 receipts green |

No statement, semantic assumption or regression expectation was weakened to close the failures. This continuation was not entirely first-run green. Runtime `GeneralPiFormation`, source substitution, `TypedNormalization`, native differential fixtures and `SetTheoryBasis` were not changed.

## Next proof dependency and performance boundary

Prove weakening/substitution closure of the SOURCE-CERTIFICATE relation, coherent annotations, and certificate construction for actual checker evidence. Do not reprove the already established general semantic substitution under a new toy syntax. Then prove arbitrary coherent source beta/zeta/function-spine denotation preservation and discharge the existing `TypedSteps.denotation_preserved` premise. Its current `A : Type` also needs universe generalization when used with universe-polymorphic V.

Full conversion congruence, levels, proof irrelevance/eta, protected environment/transparency, quotient/inductive/primitive semantics, model-preserving immutable declaration extension, explicit modeled-axiom policy, model existence and the full conditional no-False capstone remain open. No broad quotient freshness assumption is valid.

These are proof-side advances, not a new runtime optimization. No speedup, smaller binary, representative kernel benchmark, matched official CPU/RSS or allocation claim is made. Old G4.4a timings do not measure G4.4b or this proof work.
