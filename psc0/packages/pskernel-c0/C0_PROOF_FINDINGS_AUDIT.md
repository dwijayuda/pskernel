# PSKernel-C0: proof-discovered defect audit (2026-10-12)

## Current correction addendum — 17 October 2026 (historical text below retained)

This document's 2026-10-12 body is a historical audit, **not** a statement of the current Lean pin or checker implementation. C0 now pins stable Lean **4.35.0**. The then-reported absence of `psKernelCheckerStateExitLocalScope` has been corrected in `Checker/State.lean`, and `Runtime/Acceleration/CachePolicy.lean` forbids expression-only semantic cache lookup/insertion for any syntax containing local FVars; binder-local semantic caches are restored upon scope exit. The corresponding full-source-refinement proof families and metatheory scope regression are compiled in [native CI 38951397701](https://github.com/dwijayuda/pskernel/actions/runs/38951397701) (**SUCCESS** on `008a51c7`).

Further proof-guided inspections identified and corrected implicit coupling of decreasing syntax/constructor-list traversal fuel with actual semantic checker fuel across ordinary/mutual fields, recursive-argument Pi-spines, constructor parameters, indices and elimination checks. The ordinary constructor-list loop now preserves its independently supplied checker fuel while retaining a finite list traversal. Explicit native regressions enforce semantic rejection vs resource exhaustion, resource zero-fuel failures and raw constructor Pi-spine behavior. A delta-expanded verified alias also has finite analysis traversal based on both original syntax nodes and checker budget.

**Still unresolved, not to be described as bugs without a reproduction:** complete semantic annotation-coherence theorem, checked lambda codomain proof-guided divergence, corpus-wide Lean equivalence, whole-kernel consistency/soundness proof, and real Init/Std/Mathlib acceptance. The broader formal relation's proof-irrelevance premises are defective in the historical metatheory branch but do **not** establish an executable false acceptance in C0. The current native scope regression and full workflow establish tested corrections, not a universal soundness theorem.

## Latest adversarial verification and pinned Lean 4.35 lambda audit

- [`2fcb3165`](https://github.com/dwijayuda/pskernel/commit/2fcb3165f68f040472c459d1fcbc507b238fd7b2) extends `C0MetatheoryScopeRegression.lean` beyond one local: a **wrapped FVar** from a foreign scope cannot be accepted via forged checked/infer-only cache entries; reopening the same name with a different legitimate local type must return that type rather than the stale one; leaving a scope restores **all five expression caches and both DefEq pair sets**, retaining monotone fresh-name allocation. The mandatory [metatheory parity CI #38962141638](https://github.com/dwijayuda/pskernel/actions/runs/38962141638) is **SUCCESS** on that exact commit. A further adversarial [`2ddc994a`](https://github.com/dwijayuda/pskernel/commit/2ddc994acb20e89f83df41180ebc76832c913011) tests forged **positive DefEq** cache pairs of unknown distinct FVars, including nested `mdata`; the relevant parity CI must pass before this additional negative case can be called qualified.
- **Checked lambda codomain discrepancy disposition:** the pinned official Lean 4.35.0 `src/kernel/type_checker.cpp::type_checker::infer_lambda` performs `infer_type_core` on the opened body and applies `cheap_beta_reduce` to the inferred body type; it does **not** add an independent codomain-sort traversal at that point. C0 `Checker/Inference/Binder.lean::psKernelInferLambdaHead` likewise infers the opened body, applies `psKernelExprCheapBetaReduce`, abstracts the fresh FVar and assembles the Pi result. The additional `psKernelLambdaCodomainVisitWith` on the separate proof-guided branch is therefore **a stronger proposed proof/model invariant, not a confirmed omission relative to the pinned official C++ inference rule**. Its independent soundness consequences remain to be studied; do not weaken source parity or add a trusted rejection without a verified counterexample.
- **What this establishes:** repeated source-exact checker regressions plus module-level refinement proofs for the known FVar-cache and resource-family corrections. This is **not** a global kernel consistency/soundness theorem, full Init/Std/Mathlib acceptance, or proof that unknown bug families cannot exist. The real 499,130-record official-positive Init dependency remains a timeout bottleneck.

## Sources examined

- Historical dedicated proof branch `pscv/prove-pskernel-core-v1` at `85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62`, `psc15selfhost/packages/pskernel-core/metatheory/Ps/KernelCore/Metatheory/Judgments.lean`.
- Later proof-guided runtime/model branch `psc0/pskernel-core-lean435-arena-v1` at `1b517b7498a19436ec496dea0106845d30647c4d`, especially `metatheory/Ps/KernelCore/Metatheory/JudgmentAdequacy.lean`, `RESEARCH_AND_MIGRATION.md`, `Checker/Inference/Core.lean`, `Checker/State.lean`, and `Runtime/Acceleration/CachePolicy.lean`.
- Experimental C0 on `perf/pskernel-c0-v7-rust-20261012`, `psc0/packages/pskernel-c0/src/` (Lean 4.34).

## Confirmed defect: formal specification, **not** executable checker

The formal rule `PsKernelDefEqJudgment.proofIrrelevanceAlgorithmic` omits the premises tying `left`/`right` to their inferred types, and fails to connect the candidate type to the inferred proposition classification. `JudgmentAdequacy.lean` proves `legacy_defeq_is_universal` and `legacy_typing_has_every_type` for that historical judgment. This is a **real logical failure of the legacy proof relation**, but the proof explicitly does **not** show that the executable checker accepts an incorrect theorem.

**C0 conclusion:** C0 did not copy those metatheory judgments, so it does not contain that *particular formal rule*. In the executable `Checker/Knot.lean`, the proof-irrelevance branch calls inference on `leftCore`, proves its inferred type is a proposition, calls inference on `rightCore`, and compares the two inferred types. Those executable premises are absent from the broken formal constructor. `Checker/DefEq/FinalRules.lean` has the same blob SHA in C0 and the later proof-guided branch (`4c1bfb7e...`). **This specific counterexample cannot be presented as a confirmed C0 executable false acceptance.**

## Other proof-guided findings C0 must take seriously

| Finding | Evidence | C0 status | Assessment |
|---|---|---|---|
| Annotation coherence of raw binder comparison | Later proof branch `SemanticCheckedAnnotations`, `SemanticAnnotationCoherence` and `SemanticValidityScope` show that raw erasure and hereditary validity alone are insufficient to justify model-level equality. | C0 uses the raw `psKernelExprEq` structural quick path and has no validated annotated representation in the admitting API. | **Unproven semantic boundary**, not a demonstrated runtime bug. Do not assume raw structural identity proves semantic soundness in all universe regimes. |
| Local binder cache scope | Later proof branch introduces `psKernelCheckerStateExitLocalScope` and states that context-dependent semantic cache entries must not escape a binder scope. | C0 `Checker/State.lean` does not have that exit function; C0 inference passes child state back without restoring the parent semantic caches. | **Actionable compatibility/soundness risk** pending a targeted reproduction and controlled isolation changes. Correctness must take precedence over cross-context cache reuse. |
| Checked lambda codomain evidence | Later proof-guided `Checker/Inference/Core.lean` runs `psKernelLambdaCodomainVisitWith` on the actually inferred body type, with an infer-only/no-level boundary, and eliminates an opportunistic `psKernelExprCheapBetaReduce` call. | C0 still calls `psKernelExprCheapBetaReduce` and does not run the additional codomain check on that path. | **Version divergence / missing proof-guided guard**. Not independently confirmed as a C0 false acceptance; audit checked/infer-only behavior before porting. |
| Semantic cache invariants | Proof-guided branch has an explicit cache policy and reference cache-disabled specialization. Full checker soundness remains unfinished even there. | C0's own radix-16 map keeps collision resolution by structural key comparison but does not add context provenance to cached values. | Cache hash correctness is **not** proof of semantic cache validity. Prioritize cache-scope regression tests and a reference-mode comparison. |
| Unconditional consistency | Proof branch notes Lean accepts explicit user axioms, including a declaration of `False`; claims require explicit axiom-model policy. | C0 has no consistency certification, by user choice. | **Not a bug:** ordinary axiom admission must not be described as proof of unconditional consistency. |

## Versions and limits

The older dedicated proof branch targets Lean 4.34; later model work targets Lean 4.35. C0 currently pins Lean 4.34. Differences are therefore **not all fixes to backport mechanically**. The enhanced proof branch also leaves full checker soundness and model consistency unfinished. C0 performance experiments must not use its incomplete proofs as acceptance guarantees.

## Next steps for the performance work

1. Make the native C0 Lean build pass on the pinned toolchain. Do **not** run self-host tests during this sprint.
2. Add direct negative conformance cases for proof irrelevance, malformed terms, and scope crossing, and compare with the reference checker.
3. Introduce binder-local cache isolation or a context-keyed semantic cache where a targeted test demonstrates need. Do not blindly cache context-dependent defeq results.
4. Benchmark structural radix-index performance and the beta/WHNF optimizations with the original C0 baseline.
5. Keep metatheory/consistency proofs deferred while preserving the basic checker rule and no-false-acceptance invariant.

## Executable native regression receipts

- [Native Lean run 38183611788](https://github.com/dwijayuda/pskernel/actions/runs/38183611788) at `aeae35159c694b8e196c9149b4f72845785e2797`: **82 build jobs passed**, no self-host/bootstrap test run.
- `C0_PROOF_AUDIT sort0_sort1_distinct=pass`: the runnable C0 equality API rejects equality of different universe sorts in an empty environment.
- `C0_PROOF_AUDIT unbound_bvar_rejected=pass`: the executable checker rejects an unbound de Bruijn variable.
- `C0_PERF_REGRESSION beta_spine_semantics=pass`: the linear beta-spine implementation matches the old fuel-bounded implementation on short lambda spines, several argument lengths and nonzero consumed-argument prefixes.

These focused regressions **do not establish complete soundness or a consistency proof**. They are an executable check that the notorious *universal* equality theorem from the legacy formal relation is not reproduced by this ordinary C0 runtime scenario. Tests involving context/cache scope and annotated binder regimes remain future work.
