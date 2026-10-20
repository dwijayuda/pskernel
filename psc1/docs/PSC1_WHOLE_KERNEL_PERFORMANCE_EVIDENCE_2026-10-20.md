# PSC1 PSKernel-Core: matched complete-kernel performance evaluation

**Date:** 2026-10-20
**Baseline (corrected, before four C0 optimizations):** `0a53836489c4e88f46df8f5b8b0c19cc41bafbbb`
**Optimized semantic kernel:** `d329a70fc07a9ac042ccfdac242f380d77878da1`
**Identical-source native benchmark workflow:** [run 39346925724](https://github.com/dwijayuda/pskernel/actions/runs/39346925724), **SUCCESS**
**Detailed machine-readable results:** [GitHub Actions artifacts on that run](https://github.com/dwijayuda/pskernel/actions/runs/39346925724)
**Compiler/runtime:** Lean 4.34.0, GitHub Actions Ubuntu x64, independent native builds in one runner

## Objective and controls

Quantify **complete checked operation** performance after C0-inspired PSC1 ports, without mistaking faster individual substitution helpers for a faster kernel. The same `test/PsKernelWholeComparison.lean` source (derived from C0's original-versus-C0 checked comparison) is compiled unchanged against two exact Git trees. It exercises actual accepting/rejecting kernel entry points and fails if a supposed successful admission fails, if a wrong type is accepted, or if a required outcome differs.

The corpus covers cold and warm inference, full WHNF, beta, zeta, DefEq, dependent applications, 16/24/32/48/192-argument checked applications, ordinary and mutual inductive admissions and rejection, real checked definition batches, nested application/declaration batches, and deep binder/local-reference chains. It is **synthetic**, not full Mathlib/Lean Arena, and is not itself a formal semantics proof.

The benchmark emits three fixed-order rounds for complete operations; medians are summarized by full fixture identity (including depth, arity, and bvar index). Measurements below 5 ms are excluded from speedup ratios because `IO.monoMsNow` resolution and runner noise dominate at that scale.

## Results: no general whole-kernel speedup demonstrated

Representative qualified **same-run native three-round medians**:

| Complete operation | Original | Optimized | Interpretation |
|---|---:|---:|---|
| Cold WHNF, 1,600 operations | 3 ms | 3 ms | Resolution-limited |
| Full checked application, 80 | 3 ms | 3 ms | Resolution-limited |
| Checked application with 192 arguments, 12 | 7 ms | 7 ms | Near parity |
| Infer application with 192 arguments, 48 | 6 ms | 5 ms | Candidate local win, replicate |
| Checked application, 16 variants, 160 | 7 ms | 8 ms | Possible regression, replicate |
| WHNF with zeta spine, depth 96 | 20 ms | 21 ms | Possible small regression |
| WHNF with zeta spine, depth 192 | 29 ms | 32 ms | Possible regression |
| DefEq binder spine, depth 256 | 8 ms | 8 ms | Near parity |
| Admit checked library, 192-argument function, 32 definitions | 18 ms | 19 ms | Possible small regression |
| Admit dependent checked application, 48 definitions | 3 ms | 3 ms | Resolution-limited |
| Admit local-reference definitions, depth 512, index 0 | 19 ms | 19 ms | Near parity |
| Admit local-reference definitions, depth 512, index 256 | 18 ms | 19 ms | Possible small regression |

**Executable peak RSS:** original **10,072 KiB** (9.84 MiB); optimized **10,096 KiB** (9.86 MiB), a negligible **24 KiB** higher in this observed run. The [earlier paired run 39346131125](https://github.com/dwijayuda/pskernel/actions/runs/39346131125) measured the Lake launcher rather than only the benchmark process, giving much larger and non-comparable absolute RSS observations; the executable-only run supersedes those numbers.

The optimized kernel has four scoped C0-inspired changes: linear lambda-spine consumption, one-pass beta planning, single/multi-variable substitution, and binder-aware lifting. Their original-vs-C0 **helper microbenchmarks** showed some improvements, but these complete-checker results do not establish broad throughput or memory wins. Some complete paths trend slightly worse. None of these differences should be generalized beyond identical workloads, run order, and runner.

## Correctness and reproducibility boundaries

The source is on isolated branch `fix/psc1-pskernel-core-cross-branch-20261020`. Independent native and PSC1 generated-source qualification was previously completed, including [run 39343105786](https://github.com/dwijayuda/pskernel/actions/runs/39343105786). Do not confuse benchmark success with a fresh full Lean Arena or generated compiler/kernel fixed-point proof.

The native matched benchmark script lives at `test/PsKernelWholeComparison.lean`; the pinned-commit worktree workflow is `.github/workflows/psc1-pskernel-whole-benchmark.yml`; the validator is `scripts/pskernel-whole-report.mjs`; reports, raw logs, refs, and RSS evidence are downloadable as GitHub Actions artifacts. The reporter refuses missing or mismatched operation/round sets and never changes correctness rules or automatically increases budgets.

The generated-JavaScript comparison is separately qualified via `.github/workflows/psc1-pskernel-whole-js-benchmark.yml` and must be reported independently. Each generated artifact uses the historical compiler of its snapshot, so any JS difference is **not** a pure controlled kernel-source ablation.

## Next performance work

Focus on the **measured whole-checker paths**, not speculative broad cache redesign. Repeat native runs with reversed baseline/candidate order and finer timing before treating the zeta-spine or checked-app differences as regressions. Profile inclusive runtime for recursion, binder context changes, DefEq and cache eligibility; measure allocations and heap independently from launch overhead. For generated JavaScript, measure complete operations and RSS, then optimize backend-specific runtime overhead only with source- and checker-preserving validation.

No indexed DAG engine, unchecked cache reuse, changed fuel policy, new axiom or reduction bypass is authorized by this benchmark.


## Generated JavaScript matched benchmark results

**Workflow:** [GitHub Actions run 39346721193](https://github.com/dwijayuda/pskernel/actions/runs/39346721193), **SUCCESS**. Benchmark source and generated-runtime checker: `scripts/pskernel-whole-js-bench.mjs`; validation/reporting: `scripts/pskernel-whole-js-report.mjs`; run logs and JSON/Markdown report are attached as [GitHub Actions artifacts](https://github.com/dwijayuda/pskernel/actions/runs/39346721193).

The historical corrected kernel at `0a53836489c4e88f46df8f5b8b0c19cc41bafbbb` and the optimized kernel at `62bc7b77912dd2e1733250c895275edeb6eee813` were each compiled independently to JS using their corresponding pinned Lean 4.34 / ProofScript compiler snapshot, Node 22, and TypeScript 7.0.2. The same Node benchmark script ran in fresh processes on one GitHub Linux runner. All 11 benchmark families ran three rounds, and every success/rejection had a semantic guard. **There were no unexpectedly accepted or rejected cases.**

The table reports three-round medians, in milliseconds:

| Complete generated-JS operation | Calls per round | Corrected original | Optimized | Ratio |
|---|---:|---:|---:|---:|
| Beta WHNF | 30 | 1617.641 | 1589.675 | 1.02x |
| Positive DefEq | 24 | 1560.043 | 1527.784 | 1.02x |
| Negative DefEq | 24 | 316.367 | 290.630 | 1.09x |
| Infer Sort | 32 | 816.110 | 777.334 | 1.05x |
| Warm inference | 32 | 849.539 | 804.015 | 1.06x |
| Full checked application, 16 arguments | 12 | 403.559 | 381.745 | 1.06x |
| Infer application, 16 arguments | 12 | 322.131 | 308.058 | 1.05x |
| Admit checked definitions | 8 | 954.345 | 944.296 | 1.01x |
| Reject wrong-typed definition | 3 | 328.947 | 320.590 | 1.03x |
| Admit ordinary inductive | 2 | 816.232 | 752.592 | 1.08x |
| Admit mutual inductive | 1 | 764.956 | 755.382 | 1.01x |

**Observed Node process memory:**
- Corrected original peak RSS: **283,288 KiB (approximately 276.6 MiB)**.
- Optimized peak RSS: **355,076 KiB (approximately 346.8 MiB)**.
- Observed increase: **71,788 KiB (approximately 70.1 MiB), about 25%**.
- Module import time was **62.643 ms vs 64.122 ms**, so import was effectively similar on this single run.

### Interpretation and limitations

These generated-JS checks demonstrate correct behavior on a finite complete-operation corpus and a directional **1–9% latency improvement** for its measured workloads. They **also expose an approximately 25% peak-RSS increase in this run**. Do not omit this memory observation, claim a net production win, or turn the single CI comparison into a statistical speed claim.

**Important confounder:** the historical original and optimized source snapshots also use different versions of PSC1's compiler and runtime prelude, in addition to the four kernel optimizations. The benchmark is a snapshot-to-snapshot generated-artifact comparison, **not a controlled same-compiler kernel-only ablation**. It does not prove that the C0 ports caused the memory increase. Small runtime differences, Node GC scheduling, runner noise and module size can also affect observations.

To resolve this, repeat with reversed process order and independent CI reruns, use a single pinned current PSC1 compiler to generate both source variants, capture JS module bytes and V8 heap/GC instrumentation, and compare operation-isolated max RSS with retained-heap measurements. Any backend-specific performance fix must still pass the entire portable source/Lean checker/JS semantic gate.

The native evidence above remains the stronger attribution-controlled check: its original and optimized kernel sources use the identical native toolchain and the same source fixtures, with mostly unchanged complete-operation timings and near-identical ~10 MiB executable RSS. The JS observation must not be conflated with native memory.

## Native A–B–B–A execution-order control

**Success:** [GitHub Actions run 39350046319](https://github.com/dwijayuda/pskernel/actions/runs/39350046319), comparing corrected baseline `0a53836489c4e88f46df8f5b8b0c19cc41bafbbb` with optimized SHA `8b91fbf44f5d25d93ea9e36ec99c7e35058b1b17`. The exact same Lean 4.34 source fixture was compiled and run in A–B–B–A order on one GitHub Linux runner, three rounds per phase, six samples per variant per operation; all expected checker successes and rejections passed. The [run artifacts](https://github.com/dwijayuda/pskernel/actions/runs/39350046319) include raw logs and `native-abba-report.json` with first-versus-reversed-order measurements and full fixture identities.

| Whole-kernel operation | Original six-sample median | Optimized six-sample median |
|---|---:|---:|
| Cold zeta-WHNF, depth 96 | 17 ms | 17 ms |
| Cold zeta-WHNF, depth 192 | 25 ms | 26 ms |
| Admit wide checked library, 192-argument function | 9 ms | 9 ms |
| Check application, 192 arguments | 3 ms | 3 ms (resolution-limited) |
| Varied checked applications, 160 checks | 4.5 ms | 5 ms (resolution-limited) |

Process maximum RSS in the four corresponding independently executed phases was original 10,152 / 10,152 KiB and optimized 10,100 / 10,180 KiB. The small zeta-192 difference is not a reproducible established regression on this evidence. Native checked paths remain *close to performance parity*, and memory remains ~10 MiB. Ratios below 5 ms are suppressed because of timer granularity and small workload size.

## Controlled same-compiler JavaScript memory-ablation protocol

To distinguish the ~25% JavaScript RSS increase observed in [run 39346721193](https://github.com/dwijayuda/pskernel/actions/runs/39346721193) from compiler-version drift, this branch now contains `.github/workflows/psc1-pskernel-controlled-js-memory.yml`, `scripts/pskernel-js-memory-probe.mjs`, and `scripts/pskernel-js-controlled-report.mjs`. The test uses the **same current PSC1 compiler source and TypeScript 7.0.2 version** on original and optimized kernel source overlays, executes each full guarded JS corpus in fresh processes in **A–B–B–A** order, then runs WHNF, positive DefEq, checked application, ordinary inductive admission and mutual inductive admission in separate processes. It records JS bundle bytes, module-import cost, peak process RSS, post-forced-GC retained V8 heap, and garbage-collection event counts/durations.

This protocol is **not a passed result until its GitHub CI concludes successfully**. In particular, historical generated artifacts from separately versioned compiler snapshots remain only observational evidence; do not attribute the old ~25% memory difference to the kernel optimizations until this controlled compiler-source ablation completes and is replicated.

## Same-compiler canonical `.ps` generated-JS memory results

**Passed**: [GitHub Actions run 39349867322](https://github.com/dwijayuda/pskernel/actions/runs/39349867322), compiler/source snapshot `b47e8031ec7324380f499774d12c87366cba4ce2`, original corrected kernel `0a53836489c4e88f46df8f5b8b0c19cc41bafbbb`. Both source variants were compiled using the *same* current PSC1 compiler and its canonical `.lean → .ps → JS` path, with Node 22 / TypeScript 7.0.2 on one runner. All guarded operations passed. [Raw logs and structured report](https://github.com/dwijayuda/pskernel/actions/runs/39349867322/artifacts/12232918930) include A–B–B–A trials, V8 memory after forced GC, and individually isolated checked operations.

**Execution-order variation is large**: full-suite maximum RSS for original was **363.3, 284.5 MiB** in its two separate processes; optimized was **272.0, 516.4 MiB** in the intervening two processes. A single old-versus-new process pair therefore cannot establish a general 25% RSS penalty.

**More informative isolated probes** (one guarded workload in fresh processes; one sample per variant in this run):

| Kernel operation | Original peak RSS | Optimized peak RSS | Original post-GC V8 heap | Optimized post-GC V8 heap |
| --- | ---: | ---: | ---: | ---: |
| Beta WHNF | 237.2 MiB | 232.6 MiB | 20.6 MiB | 20.6 MiB |
| Full checked 16-argument application | 210.8 MiB | 210.2 MiB | 20.7 MiB | 20.9 MiB |
| Positive DefEq | 226.7 MiB | 324.1 MiB | 20.7 MiB | 25.2 MiB |
| Ordinary inductive admission | 227.7 MiB | 252.5 MiB | 22.7 MiB | 27.3 MiB |
| Mutual inductive admission | 229.1 MiB | 488.4 MiB | 23.4 MiB | 36.9 MiB |

With the compiler version now controlled, these observations point to **operation-dependent** allocation or retention effects rather than a uniform larger module import. However, an individual process peak may still include V8 heap capacity and transient GC timing; the isolated experiments have not been independently replicated or causally traced. `PerformanceObserver` reported zero GC events in this run, so do not infer a measured collection-count improvement or regression from those event counts.

**Complete operation latency was mixed**: beta WHNF was 1,176 vs 1,119 ms, positive DefEq 1,132 vs 1,096 ms, and full checked application 256 vs 276 ms (original vs optimized medians). All 11 operation families ran three rounds in each of two fresh processes per kernel. The result supports selective gains and regressions, not a uniform throughput improvement.

### Next attribution step

The source-level memory ablation is implemented as `.github/workflows/psc1-pskernel-js-ablation.yml`. It uses **one immutable current compiler executable**, comparing original, all-optimized, no-lift-port, no-single/multi-substitution-ports, and no-beta-spine-ports, each through the same checked source-to-JS path. It measures the five individual operations above in fresh processes, twice per variant. Source variants must pass PSC1 checks and the emitted JS must execute guarded kernel operations; no relaxation is allowed.

**Do not claim an individual optimization caused the memory increase until this ablation successfully completes and its effects are replicated.** If no single port explains the memory, investigate interaction effects and V8 allocation/retention profiling rather than broadly rolling back correct kernel improvements.

## Same-compiler direct `.lean → JS` replication

The direct-source, same-compiler replication also **passed**: [GitHub Actions run 39350548040](https://github.com/dwijayuda/pskernel/actions/runs/39350548040), compiler snapshot `c50c43cb0da9dd2c1ac80856d4ce1598cb552218`, original corrected kernel source `0a53836489c4e88f46df8f5b8b0c19cc41bafbbb`. It uses the same PSC1 compiler source for both variants, but takes the direct `.lean → JS` path instead of the canonical `.lean → .ps → JS` path. All guarded checks passed. [Raw logs and structured report](https://github.com/dwijayuda/pskernel/actions/runs/39350548040/artifacts/12234240173).

The single-workload fresh-process observations were:

| Checked operation | Original peak RSS | Optimized peak RSS | Original post-GC heap | Optimized post-GC heap |
| --- | ---: | ---: | ---: | ---: |
| Beta WHNF | 228.4 MiB | 233.3 MiB | 20.6 MiB | 20.6 MiB |
| Positive DefEq | 228.9 MiB | **791.9 MiB** | 20.7 MiB | **54.4 MiB** |
| Checked application, 16 arguments | 209.8 MiB | 203.4 MiB | 20.7 MiB | 20.9 MiB |
| Ordinary inductive admission | 236.1 MiB | 250.8 MiB | 23.4 MiB | 27.3 MiB |
| Mutual inductive admission | 229.3 MiB | 275.2 MiB | 23.4 MiB | 24.9 MiB |

The direction of the positive DefEq peak and post-GC heap anomaly repeats across the canonical `.ps` and direct `.lean` paths, but the magnitude varies substantially. **Do not treat the 792 MiB peak as a deterministic memory requirement or claim every workload regresses.** This motivates a source ablation with current compiler bytes fixed.

Latency for the complete suite in this direct-source run was largely at parity or improved by only a few percent, while memory remained workload-specific and highly variable. The controlling experiment must distinguish direct beta-spine, substitution and lifting changes under an otherwise identical compiler/runtime. A finite passing checker corpus is not a formal soundness proof or a full compiler/kernel fixed point.

## Five-variant same-compiler substitution ablation — 2026-10-20

**Successful ablation:** [run 39352328822](https://github.com/dwijayuda/pskernel/actions/runs/39352328822), source snapshot 4bb42d87951d24b89d98db4aa44eb4bdcf5b050e; baseline 0a53836489c4e88f46df8f5b8b0c19cc41bafbbb; [report artifact 12235161877](https://github.com/dwijayuda/pskernel/actions/runs/39352328822/artifacts/12235161877). An identical PSC1 compiler binary (SHA256 958900cce8d73fd31bc2f406ebdc7d0d47921df2fd1fde715dcc0c224b608689), Lean 4.34.0, TypeScript 7.0.2, and Node 22 checked and emitted all five source overlays on GitHub Actions Linux. Every tested checked operation passed semantic guards.

| JS operation | Original RSS MiB | All ports RSS MiB | No substitution ports RSS MiB | Original post-GC heap MiB | All ports post-GC heap MiB | No substitution ports post-GC heap MiB |
|---|---:|---:|---:|---:|---:|---:|
| Positive DefEq | 230.0 | **805.5** | **229.4** | 20.7 | **54.4** | **20.6** |
| Mutual inductive admission | 234.4 | **344.1** | **229.1** | 23.7 | **28.9** | **23.3** |
| Ordinary inductive admission | 230.2 | 233.5 | 229.1 | 22.7 | 23.0 | 22.7 |
| Beta WHNF | 242.2 | 233.0 | 266.9 | 22.9 | 20.6 | 25.2 |
| Checked 16-argument application | 206.8 | 206.5 | 208.6 | 20.7 | 20.9 | 20.7 |

Each entry is a median of two fresh Node processes per operation/variant, each executing three guarded rounds. Variant order is fixed. V8 heap growth and garbage collection introduce noise, so this is not a statistically robust memory bound.

**Interpretation:** The substitution-port *family* is the dominant observed source of severe positive-DefEq and mutual-inductive memory regression: restoring original substitution while retaining beta and lifting restores near-baseline RSS and post-GC heap. This ablation does not separately identify single-variable versus multi-variable effects, nor the lower-level V8 allocation mechanism. From individual checked-round logs, the two process medians for positive DefEq averaged about 1,389 ms with all ports, 1,190 ms with the original and 1,193 ms without substitution ports. These few samples are not a general performance guarantee.

**Mitigation committed:** [e411801a72389467b79a07c732b8600e20674f2f](https://github.com/dwijayuda/pskernel/commit/e411801a72389467b79a07c732b8600e20674f2f) restores the original bounded capture-avoiding production substitution entry points, retaining the C0 structural workers for native differential research only. Updated focused tests independently exercise both paths. No checking rule, trust boundary, universe normalization, scoped cache eligibility, or original kernel admission fuel was weakened.

Native CI passed all 61 focused cases at [run 39359421956](https://github.com/dwijayuda/pskernel/actions/runs/39359421956). **The complete generated ProofScript portability job and [same-compiler JS memory run 39359421889](https://github.com/dwijayuda/pskernel/actions/runs/39359421889) still require their own final green result** before integration review. Do not infer full Lean Arena conformance, repeated self-host fixed point, formal soundness, or backend equivalence from these measurements.
