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
