# PSKernel-C0 — Source-exact DefEq pair guard engineering and acceptance

**18 October 2026.** Repository `dwijayuda/pskernel`, active C0 `perf/pskernel-c0-v7-rust-20261012`, Lean **4.35.0** pin `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Candidate [PR #133](https://github.com/dwijayuda/pskernel/pull/133) based on exact parent [PR #131](https://github.com/dwijayuda/pskernel/pull/131) source `6aca24f4ae6f22e8962b7b068ceb9bb80b12446b`. This is a nontrusting, source-proved performance candidate, not a completed consistency theorem or universal speedup.

## Reproducible problem

[Exact genuine Lean 4.35 native graph profile 39065149332](https://github.com/dwijayuda/pskernel/actions/runs/39065149332) located repeated `psKernelExprHasFVar` beneath `psKernelSemanticPairCacheEligible` in `psKernelDefEqQuick`. This scan occurred **before** asking whether the success pair was present. A 32-layer shared expression DAG contains exponentially many expanded occurrences. A cold success set or absent pair must not require an expensive FVar membership walk to decide there is no cached result.

## Verified source decisions (all inputs)

Old Boolean:
```lean
psKernelSemanticPairCacheEligible left right &&
  psKernelExprPairSetContains state.success left right
```

New Boolean:
```lean
psKernelExprPairSetContains state.success left right &&
  psKernelC0CertifiedSemanticPairEligible left right
```

The two Lean-checked theorems in `CachePolicy.lean` and `Quick.lean` establish:
1. `psKernelC0CertifiedSemanticPairEligible left right = psKernelSemanticPairCacheEligible left right`.
2. `psKernelC0CertifiedDefEqSuccessGuard state left right` equals the full **old** conjunction, for **any** `PsKernelCheckerState`, `left`, `right`, with no source-fuel or result assumption.

This is Boolean commutativity plus an all-input source-refined DAG-aware FVar predicate. The full actual success pair set lookup remains mandatory, and **FVar-containing syntax can never obtain a cached success**. Only the relative order of pure checks changes. A cache miss never grants a proof, and the new guard never changes source trusted DefEq, WHNF, term typing, inductive admission, cache scope, exact pair equality, safety levels, or resource budgets.

## Benchmark evidence and correctness receipts

| Run | Scope | Result |
| --- | --- | --- |
| [39065149306](https://github.com/dwijayuda/pskernel/actions/runs/39065149306) | Parent PR #131 source-certified pair DAG/FVar vs original n16/24/28/32; genuine pinned Lean source | n24 15.67s original / 3.68s candidate, both accepted; n28 original 90s timeout / candidate 37.17s accepted; n32 both timeout |
| [39066037896](https://github.com/dwijayuda/pskernel/actions/runs/39066037896) | First direct certified pair eligibility vs PR131 same runner and full source | n24 3.98s baseline / 3.49s candidate, both accepted; n28 60.48s / 51.93s both accepted; n30 and n32 both timeout |
| [39066393987](https://github.com/dwijayuda/pskernel/actions/runs/39066393987) | Reordered guard exact Lean 4.35 theorem compilation and regression | **success**, no new cache-authorized proof |
| [39066393621](https://github.com/dwijayuda/pskernel/actions/runs/39066393621) | Independent native Arena adversarial regression | **success** |
| Final PR-head A/B and full Arena differential | Exact source accept-or-decline still pending | **NOT QUALIFIED until terminal CI** |

The `Array.toList_reverse.go._unary` 123,090-record old source proof exceeds its workflow's former 540-second cutoff. It was erroneously considered a workflow *failure before testing the candidate*. It now records unqualified original/candidate outcomes separately in a **diagnostic-only** workflow. A separate genuine Lean 4.35 `Array.extract_append_extract` source export A/B requires true checked acceptances at **fuel=4096** for both variants and is an independent functional/performance regression gate.

## Required acceptance gates before merge

1. Lean 4.35 source theorem, exact 4-shard 193-case historical-body compatibility (full original body byte preservation), and actual native 4.35 adversarial rejection all green on **same** PR HEAD.
2. Exact source-generated 4.35 shared DAG depths 24/28/30/32, same runner / identical bytes / unchanged 4096 fuel, report real acceptances and resource/timeouts without interpretation as checked verdicts.
3. **At least one** complete officially-positive nontrivial `Array.extract_append_extract` proof fully accepted by both original and candidate (no silent timeout or source-fuel increases).
4. No performance regression beyond repeatable noise on accepted workloads; count stack inclusive membership as **not exclusive CPU time**.
5. Do not merge a source-proved but slower or inconclusive candidate merely because CI ran successfully. Other open PRs (#119, #122, #128, #129, #130, #131) are independent branches and must not be silently combined without requalifying the exact resultant HEAD.

If this does not remove the 32-layer bottleneck, resample the n32 worker AFTER the new reordering. Next architectural candidates include an owner-sealed, context-independent FVar membership memo with explicit source projection and Lean proofs, or a lazy binder/closure representation for beta/let stress tests. Do not substitute a hash, pointer identity, heuristic, or source fuel increase for a proved kernel judgment. Full 6,452,982-record Init, Std, Mathlib, independent consistency and PSC0 v7.2 self-hostability remain open.
