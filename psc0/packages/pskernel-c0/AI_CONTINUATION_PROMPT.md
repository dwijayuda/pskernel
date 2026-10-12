# New chat — continue PSKernel-C0 native Lean performance redesign

Continue autonomously on **my public open-source ProofScript PSKernel-C0 kernel/compiler correctness project**.

**GitHub repository:** https://github.com/dwijayuda/pskernel  
**Working branch:** `perf/pskernel-c0-v7-rust-20261012`  
**Working directory:** `psc0/packages/pskernel-c0/`  
**Pinned toolchain:** Lean 4.34.0; native `.lean` implementation.

## Read and verify first

1. **Read the NEW authoritative top handoff** in [AI_WORK_STATE.md](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0/AI_WORK_STATE.md); older "latest checkpoint" sections below it are historical.
2. Read the top of [C0_WORK_STATE.md](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0/C0_WORK_STATE.md), plus [C0_BENCHMARKS.md](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0/C0_BENCHMARKS.md), [C0_LEAN_ARCHITECTURE.md](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0/C0_LEAN_ARCHITECTURE.md) and [PERFORMANCE_REDESIGN.md](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0/PERFORMANCE_REDESIGN.md).
3. Refresh **live branch HEAD and latest CI**, since this prompt and its benchmark SHA can become stale. Native CI definition: `.github/workflows/pskernel-c0-lean.yml`. Inspect checker source, dependency graph, reduction/DefEq/inference and admission boundaries **before modifying code**.

## Most recent verified source, as of October 13, 2026

- Checked-`let` accepted source inference with exact range+hash metadata: [source a90b22ed](https://github.com/dwijayuda/pskernel/commit/a90b22ed59e9a61eaf344ddf058c3b73a17d289f), [tests b951023d](https://github.com/dwijayuda/pskernel/commit/b951023d4f8c37bb7396c5f814b93fa9673dfa29), [fully green CI 38284834874](https://github.com/dwijayuda/pskernel/actions/runs/38284834874). Direct full checked-inference ablation: 60 calls of depth64 old C0 **265 ms** vs new **62 ms**; depth128 20 calls old **318** vs new **40 ms**. Matched *complete* admission: 40 safely checked depth64 let definitions C0 **45/44/45 ms** vs unchanged original **184/187/185 ms**, about **4.1× for this fixture**.
- Shared exact lambda/forall binder body ranges in the **same accepted source inference core**: [source 4e07bde0](https://github.com/dwijayuda/pskernel/commit/4e07bde098f4a9b58fdc36080b6c17feaf6bc160), [tests 21bf7176](https://github.com/dwijayuda/pskernel/commit/21bf71762a08801267c5ea6ccccac19b2b91531e), [fully green CI 38285916402](https://github.com/dwijayuda/pskernel/actions/runs/38285916402). Checked 64-binder lambda admission (24 defs): C0 **43/42/41 ms** vs original **51/50/51**; ~15–20% on this family. Negative/low-fuel/exact errors/fresh state and the original checker all passed.
- Earlier qualified source optimizations include wide/dependent Pi checked app inference, deep binder DefEq linearization (synthetic depth256 DefEq **~5–6 ms** vs original **~155–162 ms**), and exact-prehashed let/zeta WHNF (synthetic depth192 WHNF **47–49 ms** vs original **~1,037–1,068 ms**). All narrow work-family findings—not overall kernel gains.
- **Memory reduction is not established:** CI 38285916402 whole-process peak VmHWM C0 1,169,940 kB vs original 1,157,732 kB. Ordinary chains and inductive admission are near parity. No qualified p95 or representative large-library throughput.

## Autonomy and architectural instructions

**Do not preserve obsolete internal architecture just for compatibility.** First understand Lean 4.34 kernel correctness requirements, accepted resource/fuel/error policy, environment/local/universe provenance, WHNF/DefEq/inference/admission dependency graph and measured bottlenecks. Design coherent, clean, simple, high-performance reusable subsystems; implement related functionality together and test at architectural boundaries rather than patching isolated failures. Do not weaken specifications, kernel soundness, negative acceptance, error/fuel behavior, source-to-native semantics or original-checker comparisons for performance.

**Immediate next major target:** build an **actually accepting, session-owned canonical indexed term representation** that persists across WHNF, DefEq, inference and declaration admission *without encoding/decoding around every individual check*. Existing `Core/IndexedExpr.lean`, `Core/IndexedReduction.lean`, `Checker/Reduction/IndexedWhnf.lean`, and `Checker/IndexedSession.lean` are staged/opt-in and **not a trusted full indexed kernel**. Integrate only coherent, independently qualified families; cover exact Lean 4.34 environment-sensitive delta/iota, recursors, quotient, projection, native primitive reduction, universe levels, DefEq caching, local context/environment provenance and fuel/resource/error precedence before accepting indexed verdicts. Never treat structural hash equality or source range metadata as proof. Retain the original recursive worker as a negative/differential oracle until a better independently sound reference replaces it.

Include realistic checked declaration/module/library corpora, controlled C0-to-C0 ablations, repeated runs, p50/p95, per-operation allocations and RSS. Measure genuine complete accepting checker operations; report limitations and workload-specific effects rather than extrapolating synthetic wins.

**Current exclusions:** do not run self-hosting, bootstrap, fixed-point, generated Rust backend or metatheory/consistency-proof tests. Do not modify the original `pskernel-core`, PSC0 compiler, Rust backend, other branches or history. Work only on the C0 native Lean source, dedicated tests/CI and documentation. Use GitHub as canonical; **do not use Desktop Commander**. Use branch head checks and `expected_sha` when pushing, preserving others' commits.

Work autonomously through useful coherent implementation phases; push tested source and update the authoritative top handoffs in both work-state files, architecture and benchmark documents with exact commit/CI links and honest remaining gaps. Do not request repeated "continue" or stop for progress reports unless genuinely blocked. **Do not claim the full performance/indexed redesign complete until its acceptance gates are actually satisfied.**
