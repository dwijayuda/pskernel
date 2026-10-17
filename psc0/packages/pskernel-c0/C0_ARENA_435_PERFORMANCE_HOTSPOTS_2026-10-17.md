# PSKernel-C0 — Lean 4.35 Arena proof-engine bottleneck samples

**Evidence date:** 17 October 2026 · **Exact native C0 base:** `a7746475d5a0e58cbf0f2c8bd59e548f14930f17` · **Official Lean:** v4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

[GitHub CI 39026004526](https://github.com/dwijayuda/pskernel/actions/runs/39026004526) passed **four bounded diagnostic jobs**. It verifies the immutable [September 2026 Arena archive](https://github.com/leanprover/lean-kernel-arena/releases/tag/round-2026-09) SHA-256 `98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d`. For each selected source the harness changes **ONLY** the first-line Lean version/githash metadata in a disposable copy. It preserves the full body suffix byte-for-byte, records its SHA-256, and independently requires official Lean **4.35 acceptance of exactly the same adapted bytes**. These are **not** original raw 4.29.1 verdicts or genuine 4.35 source-generated exports.

## Reproduced kernel outcomes and native active-worker stacks

| Archived source | Independent official 4.35 | C0 at source fuel 4096 (90s max) | Sample evidence (12 × 2s intent) |
| --- | --- | --- | --- |
| `perf/app-lam`, 28,573 records | accepted | **unqualified host timeout** | **11/11** stack samples contain `psKernelExprHasMVar` |
| `perf/let-ladder`, 10,398 records | accepted | **resource exhausted**, record 10,398 | `psKernelC0InstOneMemoGo` in **8/11**, memo lookup 4/11, checked let inference 3/11 |
| `perf/shared-subterm`, 1,252 records | accepted | **unqualified host timeout** | **11/11** contain `psKernelExprHasFVar`, `psKernelSemanticCacheEligible`, `psKernelWhnfCoreWithFuelRanges` |
| `perf/beta-ladder`, 10,377 records | accepted | **resource exhausted**, record 10,377 | Checker exits before the requested target can be sampled; **0 stacks**; do not infer a CPU hotspot |

The sampler uses `C0NativeProofSampler.c` on the **actual Lean runtime checker worker thread**, via a disposable SIGUSR1/LD_PRELOAD handler. This does not change the checker, admit any proof, or allow a sampler to return a positive verdict. **Inclusive stack frequencies are not exclusive CPU-time shares**. The beta-ladder case's zero samples are correct early resource-classification evidence, not a sampler success.

One separate 90s C0 strict run followed each bounded sample. Successful official Lean 4.35 checking does **not** imply C0 passed; no case above is described as accepted by C0.

## Root-cause investigation and engineering sequence

### 1. `app-lam` — high-priority exact DAG metavariable screening

Source `Admission/Declaration/Validation.lean::psKernelExprHasMVar` recursively traverses `app`, lambda, Pi and let syntax to rule out expression and universe metavariables. The specific upstream [`app-lam` source](https://github.com/leanprover/lean-kernel-arena/blob/5d7ca987618f1136aaa296057b50a2c10c4ce77a/tests/perf/app-lam.lean) shares the exact same lambda argument twice at each of 4,000 layers. Its expanded tree would have exponentially many occurrences without DAG-aware traversal. A pure **per-call proof-carrying hash-trie memo** can avoid repeated checking of identical source syntax.

The memo must preserve both `.mvar` and `PsKernelLevel.mvar` in sorts/constants, short-circuit at positive branches, prove all-input equivalence with the **unchanged** source predicate, and use exact pointer/structural equality on a hash bucket hit. No semantic checker type/DefEq/admission cache or context reuse. Any native `@[csimp]` replacement should require Lean-compiled proof, exact native adversarial tests and same-runner A/B of this exact case before promotion. See draft [PR #119](https://github.com/dwijayuda/pskernel/pull/119).

### 2. `shared-subterm` — exact FVar eligibility in WHNF

The true source `Checker/Reduction/WhnfCore.lean` repeatedly calls `psKernelSemanticCacheEligible`, whose source checks `!psKernelExprHasFVar`. The existing `Runtime/Acceleration/CachePolicy.lean` has a source-proved FVar DAG memo, but this sample still spends active worker stacks under the old source predicate. Verify *actual compiler substitution* and per-case memo selection; do not assume `@[csimp]` automatically optimized this call site. A suitable next candidate is a separately source-proved replacement of the **semantic-cache eligibility function itself**, rather than weakening local FVar identity restrictions.

### 3. `let-ladder` — high memo management cost AND source budget

This synthetic 2,000-layer let-plus-`Nat.add` [test](https://github.com/leanprover/lean-kernel-arena/blob/5d7ca987618f1136aaa296057b50a2c10c4ce77a/tests/perf/let-ladder.lean) enters the existing certified single-substitution memo, but spends sampled stacks in memo insertion/lookup and name/shape hashing, followed by an explicit **resourceExhausted** verdict at unchanged fuel. Use a same-input/fuel benchmark comparing direct substitution versus verified trie memo; a non-successful faster result does **not** count as semantic acceptance. Larger fixes likely need lazy binder substitutions and proof-preserving continuation/closure representation rather than deep hash-trie tuning.

### 4. `beta-ladder` — do not misreport an early budget failure

The 2,000 beta steps in [the archived source](https://github.com/leanprover/lean-kernel-arena/blob/5d7ca987618f1136aaa296057b50a2c10c4ce77a/tests/perf/beta-ladder.lean) are not sampled because the original C0 checker returns **resourceExhausted** at the target before a sample window. Raising source fuel or converting a timeout to a rejection would be incompatible with current qualification. Characterize precisely whether resource use comes from recursive checker calls versus WHNF evaluation before selecting an architecture change.

## Qualification and nonclaims

The diagnostic workflow is not a new acceptance engine. It **does not** establish full Lean Kernel Arena compatibility, mathematical soundness, numerical benchmark parity, a self-hostable PSC0 v7.2 compiler, or that an elapsed-time reduction at exhausted budget is a valid proof. Keep `test/arena_435_known_gaps.json` authoritative until independent real matching verdicts have been obtained, and require strict whole-operation/whole-corpus CI for every new performance implementation.
