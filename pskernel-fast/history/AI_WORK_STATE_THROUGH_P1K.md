# PSKernel-Fast V3 — current work state

Updated 11 October 2026. **Current qualified scope: G4.4b typed multistep weak-head joins + P1k same-universe dependent graph spaces.**

## Authority and operating rules

Repository `dwijayuda/pskernel`; only development branch `research/pskernel-fast-clean-v3-20261011`. Target official Lean **4.35.0-rc4**, upstream commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. This is the user's public open-source compiler/kernel correctness, semantic compatibility and formal-methods project.

Use GitHub and cloud Actions only: no Desktop Commander, local repository checkout, local builds or tests. Before every write refresh branch HEAD and affected blob SHAs; use serial non-force updates with an expected-HEAD lease. Preserve concurrent changes, other branches and PR #89. Performance, correctness and a small trusted authority take precedence over preserving old implementation/proof shapes. Do not use proof-name whitelists, new global model axioms, `sorryAx`, unreviewed `native_decide` or blanket quotient-freshness assumptions.

One production semantic authority remains the goal. No public proof admission is implemented: **admitted declarations = 0**. Old checkers and official Lean are independent test oracles, not authority supplied by a plugin or majority vote.

## Exact verified checkpoint

**Code/proof source:** `4e6a06e1180e504d359b9637d6273d4bb9f8a853`.
**Completed SUCCESS:** [Actions 38140633920](https://github.com/dwijayuda/pskernel/actions/runs/38140633920), job `114473607797`.

The full job log was inspected: exact pinned Lean, **55 independent Lean source files** in the architecture fence, original **157** exact axiom receipts plus **17** disjoint additional receipts = **174** reviewed theorems. The allowed globals remain `propext`, `Classical.choice`, `Quot.sound`; no `sorryAx`. The focused new closure built in a 24-job Lake invocation and the existing closure in a 109-job invocation. **These counts overlap and must NOT be added into a claimed distinct build count.** All old regressions and both new validation stages passed.

Native official-kernel differential: **15 supported equality fixtures, 2 rejection controls, 1 intended completeness gap**, all passed. Documentation/policy commits may follow this code checkpoint; always inspect live HEAD and its matching CI before further writes or status claims.

[Detailed evidence](G44B_P1K_EVIDENCE.md) / [machine-readable evidence](G44B_P1K_EVIDENCE.json).

## G4.4b — executing typed reduction with erased paths

`src/PSKernelFast/TypedNormalization.lean` contains the actual new reducer. `WeakHeadStep` and `TypedSteps` are in **Prop**, so historical proof paths are not retained as Type-valued runtime traces. A tail-recursive accumulator keeps the current term/count; its path and bound evidence are propositions.

`stepWeakHead` performs immediate beta, let-zeta with `nondep=false`, and reduction along the function side of an application. `normalizeTyped` rechecks EVERY intermediate term through the unchanged G4.3b `ctx.infer`, requiring the same EXACT source type. `compareTypedWH` normalizes BOTH sides and returns equal only with two typed paths to a common syntactic result. It now handles reverse and two-sided joins, not just the directional one-step G4.4a cases.

The six new operational receipts prove typed path endpoints, composition of a GIVEN single-step denotation law, existence of bounded common-reduct paths for positive executions, zero-fuel nonacceptance, and a total contraction-count bound. **The composition lemma assumes `stepSound`; it is NOT a proof of beta/zeta preservation in the set model.**

Fuel is PER SIDE and counts head inspections INCLUDING the final terminal inspection: n contractions require at least n+1 fuel. It bounds recognized contractions, not source size, application-spine recursion depth, substitution allocation, rechecking cost, CPU or RSS. Different stable heads are `unresolved`, not a proof of inequality. No reduction under binders/neutral arguments, delta/iota, full universe equivalence, eta, proof irrelevance, constants or declaration transactions have been added.

`TypedNormalizationSmoke.lean` includes a TEST-ONLY KExpr-to-Lean mapping. It calls the native `Lean.Kernel.check` on an application requiring an `Eq.refl` witness to inhabit `Eq ty lhs rhs`. The production reducer never invokes the oracle. Generated mixed beta/let chains, two-sided joins, beta and let application-spines, fuel boundaries, scope precedence, capture avoidance in a checked dependent context, and neutral-head non-evaluation are checked. The deliberate under-lambda equality gap is equal in official Lean but unresolved here.

## P1k — a stronger model foundation without new assumptions

`Spec/UniverseImageClosure.lean` constructs separation from image, singleton, empty and union. A diagonal subset rules out a surjection from A in U onto U. The supplied Tarski size alternative then forces every U-bounded image of A to belong to U. Consequently the actual Kuratowski graph belongs to **the SAME universe**, closing P1j's successor-stage limitation.

`Spec/DependentGraphSpace.lean` derives union closure from image closure, the size alternative and regularity: a supposed surjection from union(A) onto U produces a forbidden membership two-cycle. It defines the dependent pair set `modelDependentSum A B` and the function-space carrier `modelGraphPi A B`, exactly the graphs of functions whose values inhabit the corresponding fibres. Both carriers stay in the same U when A and every B(x) are members of U. Eleven new model receipts cover the construction and precise membership/closure laws.

**This is a universe-closed mathematical carrier, NOT a complete Lean Pi interpretation.** Graph application/uniqueness and beta/eta, proof-valued versus Type-valued representation, source level/`imax` alignment and typing-to-model induction remain to be done. The substantial `[SetTheoryBasis V]` premise is unchanged, and no instance/model-existence or consistency capstone is constructed.

## Verification history for this continuation

- `fc90e0b365dff0cc6b6d610eb7d617a055582f78`: G4.4b source + tests, [run 38139817827](https://github.com/dwijayuda/pskernel/actions/runs/38139817827), job `114471180304`, SUCCESS on first attempt; base157 + new6.
- `719b62894761f196915caab3c0cc215870c87e76`: separation/diagonal/image/same-stage graph closure, [run 38140320151](https://github.com/dwijayuda/pskernel/actions/runs/38140320151), job `114472687102`, SUCCESS on first attempt; base157 + new11.
- `4e6a06e1180e504d359b9637d6273d4bb9f8a853`: union and dependent graph-space closure, [run 38140633920](https://github.com/dwijayuda/pskernel/actions/runs/38140633920), job `114473607797`, SUCCESS on first attempt; base157 + new17.

No test-fix iterations or weakened statements were needed for these three source commits. Existing source warnings remain; do not relabel the whole tree warning-free. G4.4a microbenchmarks still execute but measure the OLD one-head comparator, NOT the new multistep implementation. No new speedup, matched official-kernel timing, peak RSS or allocation claim is made. `kernelBenchmarkRun` stays false.

## Next exact work — join the two proof paths

First prove injectivity/functional uniqueness for the ACTUAL Kuratowski pair and graph encoding, define model application on well-typed graph values, and prove graph beta/eta. Use the derived same-stage `universe_image_closed`, `universe_union_closed`, `modelDependentSum_member_univ` and `modelGraphPi_member_univ`; do not rebuild these or add their conclusions as assumptions.

Then connect the graph-valued Type-Pi semantics and tagged proof-valued Prop semantics to source-certified binders and the actual beta/let substitution implementation. Supply a real semantic single-step theorem before applying `TypedSteps.denotation_preserved` to the kernel model. Generalize that composition lemma's carrier universe if needed; it currently uses `A : Type`.

Keep exact G4.3b type agreement as a conservative fallback until a sound broader conversion judgment is ready. Later conversion must include binder/argument congruence, exact symbolic levels, typed proof irrelevance, eta, transparency and protected immutable environment identity, followed by quotient/inductive/primitive rules and model-preserving declaration folds. Full source soundness, conditional no-derived-False, broad Init/Std/Mathlib compatibility and representative kernel benchmarks remain OPEN.

## Preserved history

The previous long work state was archived **byte-for-byte using its existing Git blob**, without deleting history: [history/AI_WORK_STATE_THROUGH_G44A.md](history/AI_WORK_STATE_THROUGH_G44A.md), blob `99085dfab9d7788f414c69700cec2b07f0086247`. The previous handoff is also preserved at [history/AI_HANDOFF_THROUGH_G44A.md](history/AI_HANDOFF_THROUGH_G44A.md), blob `475100f3de7c9ab03693c06be86d72ce2af2332f`. Historical stage flags/documents describe their original checkpoint; this current state and live evidence govern continuation.
