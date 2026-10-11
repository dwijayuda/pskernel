# PSKernel-Fast V3 — current work state

Updated 11 October 2026. **Latest qualified scope: P1l uniform Prop/Type Pi algebra with graph beta/eta + P1m guarded source Pi-to-model bridge.** G4.4b runtime is retained unchanged.

## Authority and operating rules

Repository `dwijayuda/pskernel`; ONLY development branch `research/pskernel-fast-clean-v3-20261011`. Target official Lean **4.35.0-rc4**, upstream `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. This is the user's public open-source compiler/kernel correctness, Lean compatibility and formal-methods project.

GitHub connector and cloud Actions ONLY: no Desktop Commander, local repository checkout/files/builds/tests. Refresh live HEAD and affected blob SHAs before writes; use serial non-force expected-HEAD updates. Preserve other branches, concurrent work and PR #89. Small runtime authority, performance and correctness outrank preserving old implementation/proof shapes. No new global model axioms, `sorryAx`, unreviewed native proofs, proof-name admission whitelists or unrestricted quotient-freshness assumptions.

One production semantic authority is the goal. Official Lean and other checkers are test oracles, not an accepting vote or plugin-supplied proof authority. **No public proof admission; admitted declarations = 0.**

## Exact verified code checkpoint

Source **`e95c0b5e381e4ee5a0d47001fad6c69494261683`**; [Actions 38143764809](https://github.com/dwijayuda/pskernel/actions/runs/38143764809), job `114482754713`, completed SUCCESS. The full job log confirms pinned Lean, **58** independent Lean source files, **157 + 17 + 28 = 202** distinct enumerated theorem receipts, and all regressions. The 28 new receipts are 9 concrete graph laws, 10 uniform Pi laws and 9 source bridge laws.

Allowed globals remain `propext`, `Classical.choice`, `Quot.sound`; `SetTheoryBasis V` remains an explicitly supplied mathematical premise, not an established model instance. The 42-job focused build and 109-job existing build share outputs and must NOT be added. Native differential remains 15 supported equalities, 2 rejection controls and 1 documented completeness gap; all passed.

Documentation/policy commits may follow this qualified CODE checkpoint. Re-fetch live HEAD and matching CI before reporting current status or writing. [Evidence](P1L_P1M_PI_MODEL_EVIDENCE.md) / [JSON](P1L_P1M_PI_MODEL_EVIDENCE.json).

## New P1l model algebra

`Spec/GraphApplication.lean` proves actual Kuratowski pair injectivity, exact pair membership in function graphs, graph functionality and on-domain extensionality. `modelGraphApp graph x` is presentation-independent, proof-only noncomputable lookup. Its default empty-set branch is NOT a typed application or acceptance path. Beta, carrier introduction/elimination, eta and extensionality are proved for the EXISTING P1k dependent graph space.

`Spec/TaggedDependentPi.lean` unifies Prop-valued and Type-valued Pis. `modelPi` chooses the tagged truth carrier at codomain rank zero and the graph carrier at positive rank; `modelLam` chooses point or graph. A single `modelApp V f x` distinguishes the point from graphs using the existing noncollision theorem, without caller-supplied sort/domain/type witnesses.

Exact numeric `imax` formation is proved without a new Pi universe successor. The adopted `taggedSortSet` already uses `U_(n+1)` for positive sort rank n; retain that convention. Mathematical universe inclusion and model extensionality are not new source cumulativity or kernel DefEq rules. Both regimes have intro/elim/beta/eta and on-domain Pi/lambda congruence. Beta's fibre/body membership premises are explicit, not hidden source-soundness axioms.

## New P1m guarded source bridge

`Proof/SourcePiModelBridge.lean` defines `PiModelTerm`, its source erasure, `interpPiModel`, and source-only `SourcePiAnnotation`. Unlike P1i, codomains may have ANY source universe rank. No semantic fibre premises appear in the annotation relation: source induction and a sort-binder environment-extension proof derive all fibre memberships.

Proved: annotations reconstruct actual `GeneralPiRule`; preserve source erasure; imply model membership in every environment satisfying the source sort-binder invariant; and identify the exact syntactic inferred Sort. `sourcePiAnnotation_executed_model` connects a real `inferClosedGeneralPi` success to those erasures and the modeled inferred type.

The shared symbolic source family is `forall (A : Sort u), A -> A`. Actual Prop and Type Pi-formation executions are proved by `rfl`, not `native_decide`. `sourcePiIdentityType_exec_model` applies the general bridge to the Type case and obtains denotation membership in `taggedSortSet V 2`. These check the type/proposition itself; they are NOT admission of a proof or identity-function implementation.

Guard: a used variable must have an actual syntactic Sort as its source binder domain. A proof variable `x:P` is NOT treated as a proposition `P:Prop`. Full dependent contexts and source lambda/app/let semantics are still outside this bridge. The annotations are proof-side syntax, not a second accepting kernel or a requirement on optimized runtime representation.

## Retained G4.4b / P1k foundation

`TypedNormalization.lean` remains unchanged: multiple beta/restricted-zeta/function-spine steps, each reduct rechecked at the SAME exact syntactic type through G4.3b. Equal requires two paths to a common syntactic head. Paths and bounds are in Prop and erased; the accumulator is tail recursive. Fuel is per-side head inspections including terminal inspection, NOT CPU/RSS/allocation/spine-depth bounds. Unsupported equality is unresolved, never a proved negative result.

P1k derived separation, same-universe image/graph/union closure, dependent sums and dependent graph-space closure from the unchanged set basis. P1l now uses those constructions rather than assuming replacement graph laws. The older `TypedSteps.denotation_preserved` composition theorem still assumes `stepSound`: model beta is not yet the source substitution/denotation theorem needed to discharge it.

## This continuation's provenance

- `fa0bfc38499b314bd2ec1c6e10526138be7bcd0a`: graph laws; run `38142533048`, SUCCESS.
- `ddc32de7b784e6a02591549e43cdd6397048e702`: unified algebra; run `38142864676`, correctly FAILED on one Prop-Pi congruence simplification.
- `8421bc44580808f795788be4be2d6eba4bc5eef9`: replaced that simplification with direct composition of established truth equations; run `38143138914`, SUCCESS. No theorem or assumption weakened.
- `e95c0b5e381e4ee5a0d47001fad6c69494261683`: guarded source bridge; run `38143764809`, SUCCESS first run.

Only three proof-side Lean modules, a new audit manifest/script and its CI hook were added to source. `SetTheoryBasis`, the runtime checker, G4.4b reducer and native differential fixtures are unchanged. Base157 and prior17 audits are unchanged. New source modules total 680 lines including comments/proofs, not additional runtime checker lines. Source warnings remain; do not claim the tree warning-free or all commits first-run green.

## Next exact dependency

Extend or replace the proof-only annotation syntax to represent source lambda/app/let and general typed variable lookup under dependent contexts. Establish semantic weakening and substitution against the ACTUAL capture-avoiding source `KExpr.instantiateBVar`, using the existing source-to-erased substitution correspondence rather than another unrelated toy substitution. Track annotation/rank preservation and context validity without assuming the intended typing theorem.

Then use `modelPi_beta` plus the source substitution law to prove actual source beta/zeta denotation preservation. Generalize `TypedSteps.denotation_preserved` from `A : Type` to a universe-polymorphic carrier when connecting it to V. Only this real one-step theorem may discharge `stepSound`. Do not relabel mathematical graph beta, guarded Pi formation or a hypothesis-parameterized chain lemma as all-source soundness.

Subsequent obligations remain broader typed conversion (binder/argument congruence, exact symbolic levels, typed proof irrelevance/eta, environment/transparency identity), quotients/inductives/primitives, immutable FullyChecked declaration-model extension, conditional no-derived-False, representative compatibility and performance. P1f proved arbitrary images CAN equal the proof point, so no blanket quotient freshness assumption is valid.

No new runtime speedup, binary-size, allocation, peak-RSS or official-kernel benchmark result was produced here. Old G4.4a timings are NOT G4.4b or full-kernel timings. Keep `kernelBenchmarkRun=false`, full source soundness=false and consistency=false until the corresponding evidence exists.

## Preserved history

Previous active work state/handoff are archived byte-for-byte by existing blobs in `history/AI_WORK_STATE_THROUGH_P1K.md` (`89e18c43a490ec5aee6f004b9bb3a617745fd348`) and `history/AI_HANDOFF_THROUGH_P1K.md` (`8ff093cecaa6c5a12e56a0cb61788c3aaff37216`). Earlier G4.4a history and G44B_P1K evidence remain intact. Stage-prefixed historical policy flags describe those stages; current P1l/P1m groups and live evidence govern continuation.
