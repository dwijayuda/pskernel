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
