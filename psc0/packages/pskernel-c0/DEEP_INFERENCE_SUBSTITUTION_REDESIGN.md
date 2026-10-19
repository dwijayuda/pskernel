# PSKernel-C0: deep inference and substitution redesign

Status: **experimental, not accepting, not production-qualified**  
Baseline: `perf/pskernel-c0-v7-rust-20261012` at `41322875539de66acf9eb9b01ddf73df82a61bf2`  
Lean: **4.35.0**, githash `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`

## Measured motivation

The historical Arena `app-lam` export is accepted by official Lean 4.35, but C0 reaches `C0ExportVerdict.resourceExhausted` at exactly 4096 source fuel while checking `dag_app_binder` (`body/full_check`). A separate diagnostic at fuel8192 also exhausts the inference budget. The genuine external compiler closure (575,682 exported records from the Full-importing wrapper's 458 roots) is accepted by official Lean but C0 times out at 900s; eight fixed 57/58-root shards each time out at 600s. These are resource/performance qualification failures; **they do not establish a false proof admission**.

Existing source-certified DAG scans, memo hashes, immutable flags and small substitution selectors have repeatedly failed to make the complete `app-lam` proof finish. Several inflated RSS by ~10–14×. The critical path is a different representation of pending inference and substitution work, not another hash tweak.

## Slice 1 — implemented in this research branch

`src/Ps/KernelCore/Architecture/DeepInferenceFrames.lean` implements a non-admitting checked-app continuation machine:

1. Use the existing source fuel/depth-aware app-frame collector. Each frame retains its **original remaining inference fuel** and **original recursion depth**. No collective fuel rebate, changed bound or global state is permitted.
2. Infer the application head using existing checked inference with precisely the collected residual fuel/context.
3. Traverse explicit frames in source order using `List.foldlM` over `(current type, checker state, optional exact Pi syntax ranges)`, rather than recursively retaining a suspended application checking continuation for every frame.
4. For each frame, call exactly the existing WHNF-to-Pi check, *checked* argument inference, exact equality/DefEq (including the source eager-reduction context), and capture-avoiding `psKernelExprInstantiate1`.
5. An existing immutable Pi-body-range summary may skip **only a syntactically proven unchanged codomain**; any dependent, unknown or WHNF-exposed Pi returns to original substitution. No summary, hash, pointer or cache can decide typing or a proof.
6. No changes to `psKernelCheckWithFuel`, declaration admission, axioms, safety provenance, exported checker, kernel session state or PSC0 compiler. A new native-root import and pinned Linux CI compile and check fuel-zero guards.

**This is an implementation substrate, not a performance claim or a soundness proof.** The zero-fuel theorem is deliberately much narrower than complete checker-source equivalence.

## Slice 2 — mandatory proof before any routing

Prove for **all** reachable frame sequences, base contexts, starting states and callbacks that the explicit fold equals the historical `psKernelC0CheckAppFrames` result, including complete state, exact error string, argument-check/eagerReduce order and fuel/recursion errors. First establish one-step source equality; then induct on ordered frames with no new axioms. Prove the collector/head source relation to `psKernelCheckWithFuel` separately. Do not infer proof from passing examples.

## Slice 3 — genuine lazy dependent substitution

Replace repeated materialization of large Pi codomain DAGs with an operation-local expression closure carrying a pending capture-avoiding substitution environment. Prove the closure's `materialize` result is the source instantiator result at **each** binder offset; demand a Pi view/domain only after that equality has been established. Bind offsets, freshness and sharing ownership to the operation; never reuse an unchecked closure across local contexts, source declarations or checker sessions. No `@[implemented_by]` or pointer-equality optimization is a trusted type judgment.

This slice is **not implemented yet**. In particular, delaying substitution must not delay an error, change DefEq evaluation order, or silently exceed the published fuel.

## Required promotion gates

- Lean 4.35 exact source theorem and native proof compilation, with no `sorry`, `axiom`, `unsafe`, or new trusted primitive.
- Exact positive/negative and contextual/eagerReduce cases; complete comparison of *result + state + error*, no infer-only shortcut for checked arguments.
- Original 193-case historical-source differential (with disclosed header-only adaptation) and independent pinned official kernel oracle; no classification of timeouts as rejections.
- Genuine SHA-pinned `app-lam` proof: full `accepted` at source fuel4096, bounded RSS, same-runner baseline/candidate A/B. Then Array proof and actual selected PSC0 Core dependency closure.
- Stage0 remains official Lean until C0 independently accepts the complete compiler closure; complete Init/Std/Mathlib and Stage1–3 self-host require separate gates.

**Stop rule:** stop promotion upon any wrong verdict, unproved state transition, new axiom, modified fuel policy, unbounded RSS regression, unsupported accepted input, or failure to obtain an authentic full-proof win. Preserve unmerged research evidence instead of changing admission policy to hide a performance problem.
