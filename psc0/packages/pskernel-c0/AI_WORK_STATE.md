# AI_WORK_STATE — PSKernel-C0 Lean performance architecture

**Updated:** 2026-10-12, approximately 08:45 Asia/Jakarta (WIB)
**Repository:** https://github.com/dwijayuda/pskernel
**Working branch:** perf/pskernel-c0-v7-rust-20261012
**Working directory:** psc0/packages/pskernel-c0/
**Source branch:** psc0/pscv0-v7-native-lean-v1
**Original source commit:** a8fbc17f1ad2d24efbde14a7cbe993a4400d4c01
**Latest branch commit inspected before this handoff:** a8f93b70f0985bd2b28bf7b0ba1b6818eff73bb4
**Latest completed native Lean CI for actual implementation:** [38192040598](https://github.com/dwijayuda/pskernel/actions/runs/38192040598), success at commit 06532eac5b8f9cfa2df8b810887ab3f42ba809cb.
**Status:** Active performance development. Native Lean implementations and focused checks work, but the *full* indexed architecture is **not** integrated into all accepting kernel operations. Do not report the kernel redesign as complete.

## 1. User intent and operating rules (important)

The user wants a **major architectural redesign for maximum performance of PSKernel-C0 in native .lean source**. Performance, maintainable code, and semantic correctness have priority. **Do not run self-hosting tests for now**; the eventual ability to compile .lean/.ps through the PSC0 Rust backend is a future goal, not a current acceptance gate. **Metatheory and consistency proofs are deferred**; do not spend this performance iteration trying to complete them. Continue substantial architecture work autonomously rather than asking for repeated confirmations or optimizing isolated tests without understanding the subsystem.

- Work only on perf/pskernel-c0-v7-rust-20261012 unless the user changes direction.
- Concentrate on psc0/packages/pskernel-c0/src/Ps/KernelCore/**/*.lean. The separate experimental Rust crate is background evidence, **not the primary implementation**.
- Preserve the existing psc0/packages/pskernel-core and psc0/packages/backend-rust packages; do not modify them or the compiler without a separately justified integration decision.
- Use **GitHub-first/cloud workflow**. Avoid Desktop Commander and local Windows dependencies.
- Commit/push valuable incremental checkpoints; do not force-update, delete branches, or rewrite history.
- **Run focused native Lean builds, differential/negative conformance tests, and microbenchmarks. These are NOT self-hosting tests.**
- Never weaken kernel acceptance, resource exhaustion, cache scoping, universe checking, or false-rejection/false-acceptance safeguards for speed.
- Prefer a systemic root-cause/whole-subsystem redesign, with measured comparisons rather than speculative speedup claims.

## 2. Actual package structure and semantic pin

The standalone C0 Lean package uses **leanprover/lean4:v4.34.0** in psc0/packages/pskernel-c0/lean-toolchain. Its native package and target are named pskernelC0 / PsKernelC0 in lakefile.lean. It has its own .lean modules under src/Ps/KernelCore and an independent native workflow. Do **not** conflate this with other PSC0/PSCV branches or a Lean 4.35 migration unless explicitly planned.

The public checked API and full inference/DefEq/admission remain built around recursive **PsKernelExpr** terms. The canonical term-ID representation provides shared immutable nodes, cached child hashes and depths, and an exact recursive-expression round-trip bridge, but is **not** the universal accepting-engine representation.

**Key files** (relative to psc0/packages/pskernel-c0/):

| File | Role / current state |
| --- | --- |
| src/Ps/KernelCore/Core/Expr.lean | Recursive expression representation; hybrid structural comparator; application arity without temporary argument lists |
| src/Ps/KernelCore/Core/IndexedExpr.lean | Canonical indexed term store; collision-checked hash-consing, cached hashes/depth; recursive expression encode/decode |
| src/Ps/KernelCore/Core/IndexedReduction.lean | Indexed lifting, single-binder substitution; memoized DAG rewrite keyed by term-ID and binder depth; recursive reference path |
| src/Ps/KernelCore/Checker/Reduction/IndexedWhnf.lean | **Experimental context-free** indexed beta/zeta/metadata and application spine WHNF; unchanged stuck spines retain original handle |
| src/Ps/KernelCore/Checker/Reduction/WhnfCore.lean | Accepting Lean checker uses demand-driven application-head probe; only materializes full argument list when necessary |
| src/Ps/KernelCore/Core/Substitution/{Beta,Instantiate,Lift}.lean | Single-argument beta specialization, general substitution retained, direct lifting, cheap beta-spine plan |
| src/Ps/KernelCore/Checker/DefEq/{Quick,LazyDelta,FullShape}.lean | Quick shape checks, lazy unfolding, full shape semantics; pre-guarded quick helper |
| src/Ps/KernelCore/Checker/Knot.lean | Owns recursive checker orchestration; once global equality/success-cache miss is established, uses quick-after-common without duplicated scans |
| src/Ps/KernelCore/Core/LocalContext.lean | Small list first, persistent radix index beyond threshold, shadowing-safe persistent snapshots |
| src/Ps/KernelCore/Runtime/Acceleration/{Cache,EnvironmentIndex}.lean | Persistent shared radix-16 tries, Unicode hash folding, exact collision comparisons |
| src/Ps/KernelCore/Checker/{Context,State,Session}.lean | Resource policy, local/global contexts, checker state, session interface; potential owner for persistent term-store integration |
| test/C0ProofIrrelevanceRegression.lean | Native negative semantic checks and structural/differential tests; no self-hosting |
| test/C0PerfMicrobench.lean | Varied-input microbenchmarks of Lean hot paths; no self-hosting |
| experimental/arena-engine/ | Separate Rust proof of concept; **not an accepting kernel** |

## 3. Implemented native Lean performance changes

1. Replaced duplicated multi-level binary cache structures with generic persistent **four-level radix-16** indexes for expression/declaration/local-context lookups, retaining structural comparisons in collision buckets.
2. Added exact indexed expression DAG representation and encode/decode bridge, preserving binder names/info, universes, metadata, let flags, literals, and rejecting invalid handles.
3. Added indexed beta/zeta reduction and memoized capture-avoiding substitution across repeated DAG nodes and binder scopes. The original recursive indexed worker remains a differential oracle.
4. Added context-free indexed WHNF that walks a spine using canonical handles and skips needless reconstruction when a stuck spine is unchanged.
5. Improved **accepting** recursive-expression WHNF through demand-driven head inspection: do not eagerly allocate a full argument list for a stuck application.
6. Specialized one-argument beta substitution; preserved general multiargument behavior, verified with differential regressions.
7. Removed repeated whole-tree node-count/loose-variable prepasses from hot substitution/lifting and repeated argument-list counting.
8. Optimized deep local variable lookup with persistent indexed shadowing; preserved old context snapshots and collision/replacement behavior.
9. Added native Unicode string hashing without whole UTF-8 length/fuel prepass, with differential oracle.
10. Retained hybrid expression equality when the fully paired comparator regressed a workload, rather than sacrificing performance for elegance.
11. Removed duplicate structural-equality and success-cache checks in the **accepting DefEq path** by introducing psKernelDefEqQuickAfterCommon, called only when those common guards have already failed. Independent callers retain the general psKernelDefEqQuick API.

## 4. Verified CI and measured evidence

The **most recent verified source run** is [PSKernel-C0 native Lean architecture #38192040598](https://github.com/dwijayuda/pskernel/actions/runs/38192040598), source commit 06532eac5b8f9cfa2df8b810887ab3f42ba809cb. Its logs show:

- **Native Lean library build:** successful, **84 Lake jobs**.
- **Negative and differential suite:** successful, including Sort 0 vs Sort 1 non-equality, unbound variable rejection, guarded DefEq equivalence, beta-spine, substitution, lifting, structural equality, radix interning, declaration replacement, local shadowing, Unicode hash, exact indexed round-trip, indexed beta/zeta WHNF, and unchanged stuck-spine identity.
- **Benchmark suite:** successful, no self-hosting or fixed-point build.

Selected same-run **microbenchmarks**, single GitHub-hosted CI runner:

| Workload | Baseline or removed work | C0 | Interpretation |
| --- | ---: | ---: | --- |
| Structural equality, 30k comparisons | 1,825 ms | 1,818 ms | Near parity |
| de Bruijn lift, 30k | 9,168 ms | 6,796 ms | ~26% shorter |
| Single substitution, 30k | 16,646 ms | 9,738 ms | ~42% shorter |
| Deep local lookup, 20k in 512 locals | 1,766 ms | 55 ms | ~32× on this deep-local microcase |
| Stuck-application head probe, 30k | 3,020 ms eager | 352 ms head-only | ~8.6× on head probe, not complete WHNF |
| Indexed shared-DAG substitution, 70, depth 11 | 909 ms recursive | 11 ms memoized | ~83× on engineered shared DAG |
| Indexed stuck spine, 600 × 256 args | 601 ms reassembly-only | 73 ms unchanged-handle indexed WHNF | **Not matched full checker workloads** |
| General vs already-guarded DefEq quick helper, 12k × depth 512 | 516 ms general | 6 ms guard-already-done | **Helper-only**, not 86× whole DefEq |
| Cold accepting WHNF, 400 checks, 128 args | N/A | 20 ms | Baseline only; no matched old-kernel number |

These figures are **not** multiple-run medians, production throughput, full WHNF/DefEq speedups, or memory improvement. Do not extrapolate exact speedups to full Lean libraries.

Other relevant CI links:
- [38189942349](https://github.com/dwijayuda/pskernel/actions/runs/38189942349): indexed DAG/beta and source-optimized head work, passed.
- [38191368025](https://github.com/dwijayuda/pskernel/actions/runs/38191368025): indexed stuck-spine identity + cold WHNF, passed.
- [38191752791](https://github.com/dwijayuda/pskernel/actions/runs/38191752791): guarded quick DefEq, passed.
- [38180969202](https://github.com/dwijayuda/pskernel/actions/runs/38180969202): separate Rust prototype, 21 tests/Clippy/microbenchmark passed, **not** a Lean kernel implementation result.

**Important:** The latest branch commit a8f93b70... is a documentation checkpoint; latest source validation is identified above. Refresh branch head and CI runs before reporting current status.

## 5. Native development and validation commands

From repository root:

~~~sh
cd psc0/packages/pskernel-c0
lake build PsKernelC0
lake env lean --run test/C0ProofIrrelevanceRegression.lean
lake env lean --run test/C0PerfMicrobench.lean
~~~

CI workflow: [.github/workflows/pskernel-c0-lean.yml](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/.github/workflows/pskernel-c0-lean.yml). It runs exactly those native checks with the package's pinned toolchain. Documentation-only commits do not normally trigger this path-filtered workflow; never claim new CI evidence just because docs were committed.

Do **not** run PSC0 compiler/kernel self-hosting or bootstrap fixed-point jobs. The user has explicitly postponed those tests.

## 6. Architectural gaps and next work (priority order)

### P0 — Profile the complete accepting checker, not just helpers

Establish repeated same-run native measurements for *complete* cold/warm inference, WHNF, DefEq, recursive/nested recursor checks, and declaration admission against unchanged pskernel-core on identical inputs, hardware, and resource limits. Capture peak memory and allocation signals where practical. Include failed/negative cases. Diagnose whether encoding, hashing, cache publication, reduction, or binder operations dominate.

### P1 — Session-owned indexed term representation

Avoid repeated recursive↔indexed encode/decode per operation. Introduce a single owned canonical term store for a checking session with explicit identity/generation and context/environment provenance. Design immutable handle ownership and scope-safe caches. Keep external acceptance API stable. Do **not** allow bare term IDs from another store to compare equal or share memo results.

### P2 — Native indexed WHNF/DefEq in the checked path

Extend indexed head reduction in justified families: delta unfolding, projections, recursor/iota, primitives, quotient and universe comparison, retaining original observable reduction priority, resource exhaustion, and checked inference semantics. Use differential tests against the reference checker and negative controls at each stage. Introduce indexed execution into acceptance only with clear correctness boundaries. Do not turn unknown or exhausted work into success.

### P3 — Optimize admission and memory

Profile and improve inductive/mutual/nested admission and recursor-rule checking; favor structural sharing, indexed lookups, no wasted reconstruction, and lifetime-local memo tables. Keep atomic admission and complete restored rule checks; do not replace checked rules with infer-only shortcuts without a sound invariant.

### P4 — Qualify and document

Measure representative entire-module/library checking, cold/warm throughput, peak RSS, allocation and resource behavior. Repeat samples, compare baseline and new implementation on matched runs, document regressions and tradeoffs, and keep CI green. Metatheory and consistency proofs remain deferred; do not imply their completion. Self-hosting tests remain out of scope.

## 7. Handoff warnings

- Avoid “test-fix-patch” loops; inspect subsystem and invariant before changing code.
- The **indexed WHNF is only a context-free fragment**. Production checked kernel still uses recursive expressions for environment-dependent decisions.
- Experimental Rust source does not prove that the Lean C0 kernel compiles to Rust or self-hosts. Do not confuse backend presence with a verified C0→Rust compilation path.
- Existing old docs under C0 (e.g. README.md) were copied from core and refer to the historical core package; prefer this handoff and current C0 source/CI.
- Existing psc0/AI_WORK_STATE.md is the broader compiler state; do not overwrite it for C0-only work.
- Keep historical C0_WORK_STATE.md and C0_BENCHMARKS.md; append new verified checkpoints and metrics, do not silently replace evidence.
- If GitHub branch advances concurrently, refresh and incorporate new commits rather than overwriting/reforcing. Always cite the commit and CI run for claimed results.

## 8. Immediate next action for the next chat

1. Fetch the **current** branch head, this AI_WORK_STATE.md, AI_CONTINUATION_PROMPT.md, C0_WORK_STATE.md, C0_BENCHMARKS.md, native Lean workflow, test sources, and checker hot paths.
2. Compare latest code and CI against the baseline documented here; identify work already done since this handoff.
3. Design and implement the next systemic **.lean** performance change around persistent session-owned indexed representations or measured checker bottlenecks; preserve soundness and original kernel.
4. Run **only** native Lean build, negative/differential conformance, and performance measurements.
5. Commit/push with precise benchmark records; update this file and C0_BENCHMARKS.md.
6. Continue independently through the plan without stopping for routine “continue” prompts.

**Final acceptance criterion:** a measurably faster, correct Lean-native C0 checking pipeline for representative entire declarations/libraries, with realistic memory/resource behavior and no acceptance regressions. This criterion has **not** yet been met.



## 9. Continuation: production-spine integration and whole-checker measurement (2026-10-12)

Source changes on the **same** C0 branch:
- `717dfeb89da66253ab9f42d5b5b0951d7dacd545`: delay argument-list materialization in real Lean-native delta unfolding and constructor projection until their matching environment decisions have passed. Neither uses indexed handles to decide acceptance.
- `b290a8dde0482ab195ffc59bd4eabf74f745a50b`: native historical-oracle differential checks for matched/missing delta and projections. [CI 38194277302](https://github.com/dwijayuda/pskernel/actions/runs/38194277302) passed 84 Lake jobs, negative/differential checks and native microbenchmarks.
- `cf0e3da4ee8ccf1870232316210110a9d02499f0`: native benchmark suite expanded with complete cold/warm inference, checked positive/negative declaration admission, and Linux process RSS reporting. [CI 38194545945](https://github.com/dwijayuda/pskernel/actions/runs/38194545945) passed build, checks, benchmark.
- `7cf4c49748f87fb171339da61c6a80804a5b7eb6` and `e6e005541e78b38d70ec4ecc8f9d7177c50d2267`: added source-native direct application argument selection and wired constructor projection to it, avoiding allocation of a full application-argument list when choosing a single field.
- `641b57aaf696da4da61b8aebddcff809d7a99be1` and `a96a4f1fd76432ddaeafcc64e035b6b426223f86`: added argument-selection differential tests across various arities and indices and paired 512-deep selector benchmarks.

**Observed native CI evidence:** the initial eager/lazy delta case ran 193 ms vs 192 ms over 12,000 deep misses in [38194277302](https://github.com/dwijayuda/pskernel/actions/runs/38194277302). In [38194545945](https://github.com/dwijayuda/pskernel/actions/runs/38194545945), it ran 193 vs 183 ms on another hosted runner observation; do **not** claim a reliable improvement from this noise. Native inference (180 × lambda depth 24) measured 2 ms cold/7 ms warm; valid admission (120 declarations) 2 ms; invalid admissions (120) below timer resolution; cold WHNF (400 stuck terms) 26 ms. Peak Linux process VmHWM was 612868 kB (whole benchmark process, not per-kernel allocated bytes). These fixtures are too small and the observations too noisy for broader throughput, memory or warm-cache claims.

**Critical outstanding gates:** obtain final native selector benchmark result; profile meaningful whole declarations and representative modules against unchanged original PSKernel-Core, with matched hardware and resource policy; integrate persistent indexed representation into session owned checking with provenance-safe cache keys, then extend the exact checked WHNF/DefEq/inference semantics. Do not treat the existing indexed fragment as an accepting kernel. No self-host or metatheory tests were run.



### Decision gate: direct projection selector rejected (same date)

Final native selector qualification [CI 38194880437](https://github.com/dwijayuda/pskernel/actions/runs/38194880437), source `a96a4f1fd76432ddaeafcc64e035b6b426223f86`, **passed** all 84 Lake build jobs, the direct argument-select semantic differential test across 0–128 arguments (including out-of-range access), and all native benchmarks. **The direct two-pass selector lost on the same-run measured microcase:** existing list-backed selection **560 ms**, proposed direct selection **1298 ms**, both 18,000 queries on the same 512-deep application spine (approximately 2.32× slower). The representation allocates less intermediate structure but walks the expression twice; avoid assuming fewer allocations equals faster performance.

Commit `5de4773f8fdbbfcc2e4acc0377524c1a92231683` **reverts the production projection call to the measured faster list-based selector**, while retaining the indexed-position helper, its exhaustive differential regression, and the benchmark for future experiments. The earlier lazy delta / projection lookup guards remain in place. This is a deliberately rejected optimization, NOT a claimed speedup. Verify native CI for this final revision before claiming it green.

Next choose **measured full-checker bottlenecks**, likely repeated recursive reductions/inference/DefEq inside realistic environments, before any more broad representation changes. Single-run simple admission samples are too small to rank architecture choices.



### Final post-rollback native validation (2026-10-12)

[PSKernel-C0 native Lean CI 38195084646](https://github.com/dwijayuda/pskernel/actions/runs/38195084646) at source commit `5de4773f8fdbbfcc2e4acc0377524c1a92231683` **passed all three gates**: 84-job full native Lean build; negative and differential semantic checker regression; native Lean performance benchmark suite. The production constructor-projection path again uses list-backed application-field selection. The direct selector remains an experimental helper, never a checked shortcut. Its paired same-run reference-vs-direct result still regressed: 396 ms list / 911 ms direct over 18,000 depth-512 queries (~2.30× slower). Delta eager/lazy miss results 112/111 ms are near parity, not a reliable checker speedup. Native Linux entire benchmark process VmHWM 633996 kB. This validation includes **no self-host/bootstrap or metatheory tests**. Representative entire-library baseline and session-indexed acceptance work remain open.
