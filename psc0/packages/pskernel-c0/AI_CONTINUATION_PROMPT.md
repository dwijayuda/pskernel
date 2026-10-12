# AI CONTINUATION PROMPT — PSKernel-C0 high-performance Lean architecture

Continue my **PSKernel-C0** project autonomously from the latest development state.

**My public open-source repository:** https://github.com/dwijayuda/pskernel  
**Branch:** perf/pskernel-c0-v7-rust-20261012  
**Work only in:** psc0/packages/pskernel-c0/  
**Primary implementation:** src/Ps/KernelCore/**/*.lean

**Read these files completely before changes (from the current branch, not main):**

1. [AI_WORK_STATE.md](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0/AI_WORK_STATE.md) — authoritative C0 handoff.
2. [C0_WORK_STATE.md](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0/C0_WORK_STATE.md) — detailed chronological work.
3. [C0_BENCHMARKS.md](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0/C0_BENCHMARKS.md) — measured evidence and limitations.
4. [PERFORMANCE_REDESIGN.md](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0/PERFORMANCE_REDESIGN.md) — architecture and integration direction.
5. [.github/workflows/pskernel-c0-lean.yml](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/.github/workflows/pskernel-c0-lean.yml) and the native regression/benchmark sources.

**Refresh the branch head, recent commits, and actual CI runs** before assuming the handoff commit is still current. At handoff, branch head was a8f93b70f0985bd2b28bf7b0ba1b6818eff73bb4; native Lean CI [38192040598](https://github.com/dwijayuda/pskernel/actions/runs/38192040598) had passed the full C0 build (84 Lake jobs), native negative/differential regressions, and performance microbenchmarks for source commit 06532eac5b8f9cfa2df8b810887ab3f42ba809cb.

## My priorities

- **Make PSKernel-C0 as fast as possible through a major, systematic architectural redesign IN LEAN (.lean).** Focus on the actual checked kernel, not merely the standalone Rust prototype.
- Prioritize performance **and correct Lean-compatible acceptance**, readability, simple architecture, memory efficiency and portability.
- **DO NOT run self-hosting, bootstrap, fixed-point or generated Rust self-host tests for now.** Eventually self-hosting may matter, but not in this stage.
- **DO NOT prioritize metatheory or a consistency proof now.** Preserve known semantic constraints and focused soundness-sensitive negative tests; never bypass checks for speed.
- Preserve the original psc0/packages/pskernel-core, the existing psc0/packages/backend-rust, the active PSC0 compiler and all other branches. Make C0 changes only on this C0 branch unless I explicitly authorize integration.
- Work GitHub-first/cloud-only; **do not use Desktop Commander**. Commit and push meaningful checkpoints. Do not rewrite or delete branch history.
- Think systemically: study complete architecture, dependencies, checker semantics, bottlenecks and benchmark methodology before editing. Avoid one-test-at-a-time patches and one-off cache hacks.
- After each architectural change, perform **native Lean library build**, **negative/differential checker regressions**, and **native performance benchmarks** only. Measure the whole checker where possible. Do not weaken acceptance conditions.
- Be realistic about benchmarking: single-run helper microbenchmark speedups are **not** whole-kernel performance, proof of consistency or a validated C0-to-Rust compiler path.

## Work already completed

The C0 Lean source implements persistent radix-16 indexes for caches/declarations/local contexts; indexed expression DAG with exact recursive-expression bridge; memoized indexed beta substitution; fragmentary indexed beta/zeta/metadata WHNF; demand-driven application-head checks in the accepting recursive WHNF; specialized one-argument beta; faster lifting and native Unicode hashing; and a guarded quick-DefEq helper that removes duplicate common checks in the accepting checker.

Strong measured results include microbenchmark reductions for lifting and single substitution, ~30× deep local-context lookups, ~8.6× head-only spine probing versus eager argument collection, and large memoized-DAG rewrite gains. **These are specific microbenchmarks, not end-to-end kernel speedup claims.**

## What to do next — actually implement

1. Inspect the real accepting WHNF, DefEq, inference and admission dependency graph, together with the existing indexed store and native benchmark harness.
2. Identify the largest remaining costs in *complete checking* and design a session-owned canonical indexed expression representation with explicit lifetime/arena identity and context-safe cache keys. Minimize repeat encoding/decoding between recursive and indexed terms.
3. Extend the fast **Lean-native** evaluator systematically to cover full environment-sensitive reductions (delta, iota, projections, recursors, quotient, primitives, universes), preserving exact reduction order, resource budgets and fallback correctness.
4. Optimize the true accepting pipeline, not only experimental helpers; retain an independent reference path and native positive/negative/differential checks.
5. Benchmark complete cold/warm WHNF, DefEq, inference and declaration admission against unchanged pskernel-core with representative inputs, memory measurements and repeated matched runs. Keep only measured worthwhile optimizations.
6. Update C0_BENCHMARKS.md and AI_WORK_STATE.md with exact source commits, CI runs, what passed, what remains, and the next autonomous step. Commit/push safely. Continue through the plan.

**Commands from the C0 package root (native Lean; no self-host):**

~~~sh
lake build PsKernelC0
lake env lean --run test/C0ProofIrrelevanceRegression.lean
lake env lean --run test/C0PerfMicrobench.lean
~~~

Use the existing C0 Lean 4.34.0 pin unless a deliberate compatibility migration is justified.

**Do not stop after drafting a plan or producing a progress report. Implement, validate, measure, commit, and continue.** When the effort cannot reach full completion in one chat, leave a precise checked state and next executable task. Do not claim full completion until end-to-end speed and compatibility are established.



## Latest October 12 validated checkpoint (supersedes old handoff SHA above)

**Current source checkpoint before subsequent documentation updates:** `30ba64034dc52e3a6a18344a2f5d220a9a5eb9ba`.
**Green native CI:** [38215639174](https://github.com/dwijayuda/pskernel/actions/runs/38215639174) includes 85-job C0 Lean build, negative/fuel/differential regressions, native microbenchmarks, and an independently built **unchanged original-core matched baseline** (81 jobs). It runs no self-host/bootstrap tests.

New `Checker/IndexedSession.lean` is opt-in and syntax-only, with persistent canonical nodes, exact name/metadata identity, small-to-radix root cache, no bare IDs exposed, and no acceptance shortcut. It is currently slower for repeated checked WHNF than the plain session; **do not enable as default** until full indexed execution eliminates its overhead. Indexed term hashing now includes all binder identity fields; measured collision-heavy binder intern 60 ms old vs 8 ms new, only an indexed-substrate microbenchmark.

Production `Checker/Inference/Helpers.lean` now counts infer-only application arguments once per spine (legacy worker ~5 ms vs 1 ms counted in isolated 192-argument microbench). An independently admitted 48-argument benchmark against unchanged original core revealed a **mixed and critical result**: C0 infer-only ~16–19 ms vs core ~65–66 ms per 200 cold calls, but C0 **fully checked** ~50 ms vs original ~30–31 ms per 80 cold calls, three rounds, same runner. Do not claim overall performance superiority. Checked inference source `Checker/Inference/Core.lean` is byte-for-byte the same; follow the actual dependency costs and preserve semantic/fuel classification before rewriting. On synthetic closed and open forall terms, specialized C0 instantiate1 is much faster than an old loose-variable-precheck approach; do not blame/revert substitution without evidence.

**Next actual work:** measure and resolve the full checked-application regression, then implement session-owned indexed delta/WHNF/DefEq/inference and declaration admission with provenance-safe caches and matched tests. Preserve the original core/Rust backend, no self-host or metatheory work, commit and push checkpoints, and update `AI_WORK_STATE.md` and `C0_BENCHMARKS.md` with exact source runs and honest limitations. The architecture is not complete.
