# PSKernel-C0: proof-discovered defect audit (2026-10-12)

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
