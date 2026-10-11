# Continue PSKernel-Fast — G4.4b/P1k green

Repository: `dwijayuda/pskernel`. Only development branch: `research/pskernel-fast-clean-v3-20261011`.

This is the user's public open-source compiler/kernel correctness and formal-methods project. Work autonomously using GitHub + cloud Actions ONLY; no Desktop Commander, local repository files/builds/tests. Preserve every other branch and PR #89. Refresh live HEAD and affected blob SHAs before writes; use non-force expected-HEAD updates. Never overwrite concurrent work.

## Read first

Read live `pskernel-fast/AI_WORK_STATE.md`, `G44B_P1K_EVIDENCE.md`, `G44B_P1K_EVIDENCE.json`, `ARCHITECTURE_POLICY.json`, then these exact sources:

- `src/PSKernelFast/TypedNormalization.lean`
- `src/PSKernelFast/TypedNormalizationSmoke.lean`
- `src/PSKernelFast/Spec/UniverseImageClosure.lean`
- `src/PSKernelFast/Spec/DependentGraphSpace.lean`

Target is pinned official Lean **4.35.0-rc4**, source `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.

Last fully qualified CODE checkpoint at authoring: **`4e6a06e1180e504d359b9637d6273d4bb9f8a853`**, [Actions 38140633920](https://github.com/dwijayuda/pskernel/actions/runs/38140633920), job `114473607797`, SUCCESS. Architecture fence55 Lean files; old157 + disjoint17 = **174 exact theorem receipts**; new native kernel differential15 supported equalities,2 rejection controls,1 documented equality gap. Focused24-job build and old109-job build both passed, but overlap and must NOT be added. Documentation/policy may follow; live HEAD/CI is always authoritative.

## What is now established

G4.4b executes multi-step beta/restricted-zeta and function-spine reduction. Every intermediate term is independently checked by the unchanged G4.3b checker at the SAME exact syntactic type. Equal carries two paths to a common syntactic head. The paths/bounds are in Prop and erased; the accumulator loop is tail recursive, not a runtime list of historical terms. Fuel is per side, includes terminal inspection, and DOES NOT bound memory/substitution/checker/spine work. It is incomplete positive-only conversion, not full Lean DefEq or proof admission.

P1k derives separation, image closure and SAME-universe graph membership by diagonalization and the EXISTING Tarski size alternative. Union closure follows from image closure plus regularity. Dependent-sum and function-graph-space carriers are defined, have exact membership laws, and stay in the same universe as their domain/fibre sets. No set-theory fields/global axioms were added. This is stronger than P1j's successor-only graph result.

All three source commits in this continuation passed their first exact cloud run. `SetTheoryBasis V` remains an explicitly supplied mathematical premise; no model instance or complete consistency proof exists. The unchanged original audit157 and extension audit17 each fail closed using the same allowlist (`propext`, `Classical.choice`, `Quot.sound`), rejecting `sorryAx`, missing/extra/duplicate receipts. Update the appropriate exact manifest when adding qualified theorems.

## Next dependency, not another isolated carrier theorem

Prove exact Kuratowski pair injectivity and graph functional uniqueness; define application on validated graph values and prove graph beta/eta. Connect the now universe-closed graph-space carrier to typed source Pi/lambda/app and the tagged proof-point Prop representation, including correct universe/imax and semantic context/substitution laws.

The operational `TypedSteps.denotation_preserved` theorem assumes a one-step `stepSound` hypothesis. **That semantic premise is still OPEN for the full source model**; do not call the composition lemma a completed set-denotational soundness proof. Generalize its `A : Type` universe when integrating a universe-polymorphic model.

After this bridge: richer typed conversion (congruence, symbolic levels, eta/proof irrelevance, transparency/env identity), typed quotients and inductives/primitives, immutable FullyChecked declaration-model extension and relative no-False. Keep no global quotient-freshness claim: P1f proved unrestricted images can equal the proof point.

Performance/correctness outrank old proof shapes. Use one accepting authority with separately justified optimizations. No public admission, no external plugin proof authority, no new axioms to close a proof. Current old G4.4a microbench timings are NOT timings for G4.4b; no matched official speed/RSS/allocation result yet. Design real tests and invariants first; avoid test-fix hunting and tiny irrelevant theorem count inflation.

The complete earlier work state/handoff are preserved byte-for-byte in `pskernel-fast/history/*THROUGH_G44A.md`; current state is intentionally shorter so the next chat need not ingest stale repeated checkpoints.
