# AI_WORK_STATE — PSKernel-C0 Lean performance architecture

**Updated:** 2026-10-12, approximately 14:10 Asia/Jakarta (WIB)
**Repository:** https://github.com/dwijayuda/pskernel
**Working branch:** perf/pskernel-c0-v7-rust-20261012
**Working directory:** psc0/packages/pskernel-c0/
**Source branch:** psc0/pscv0-v7-native-lean-v1
**Original source commit:** a8fbc17f1ad2d24efbde14a7cbe993a4400d4c01
**Latest source checkpoint verified:** 30ba64034dc52e3a6a18344a2f5d220a9a5eb9ba
**Latest completed native Lean CI for actual implementation:** [38215639174](https://github.com/dwijayuda/pskernel/actions/runs/38215639174), success at source commit 30ba64034dc52e3a6a18344a2f5d220a9a5eb9ba, including native original-core matched baseline.
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



## October 12 continuation — native matched baseline and indexed session staging

**Start head:** `e0ceb97e93266832c83aa3588955bbb2c8671d56`; work stays on `perf/pskernel-c0-v7-rust-20261012`. User's restrictions unchanged: original core and Rust backend untouched, native Lean 4.34 only, no self-host/bootstrap or metatheory testing.

**Meaningful source changes:**
- `33b88834d376f69778a294444a6e42a7454703d7`: native CI now builds the **unchanged** `pskernel-core/src` in a temporary standalone Lean package with the same pinned toolchain and executes `test/C0CheckerComparison.lean` against both implementations. C0-only indexed roots are omitted from that temporary baseline package; no baseline tracked files are edited.
- `f52a421367e8b2151d258d5486429f5df4f128ae`–`82c4bb2242480576a279a80c78bbcec74b3ad5fe`: added an opt-in `Checker/IndexedSession.lean`, preserving the authoritative original checker while retaining exact indexed syntax in a session-owned immutable store. Raw term IDs do not cross the API; a small-first root memo promotes after 8 entries to a persistent radix trie. Root equality includes binder names/metadata; semantic acceptance, failure, fuel and environment contexts remain delegated to the checked engine. Tests cover 40 roots, repeated retention, independent snapshots, beta WHNF, negative DefEq and rejection of unbound variables.
- `bdf9d9357e254d6fe9bea3d80ec6a5f269b9fff8`: improved canonical term hash distribution for the **entire family of binders** by including lambda/forall names and binder info plus let names; exact node equality remains the only interning identity test. Differential binder identity and collision tests were added.
- `9c3abe9e7720b937d8124ae68704660a8e0e6ead`: production infer-only application-spine worker now takes precomputed argument count rather than recomputing list length in every recursive step; exported legacy-signature entry remains. The worker's environment, WHNF callback, fuel decrement, substitutions and failure semantics were not relaxed. Benchmark includes an independent copy of the old implementation; negative/fuel differential tests added in `796d3637b2bb18b3e6221942f201407cf30a1be5`.
- `dd901d589a6162ee7c55370c982f99692f2fa315`: matched original-vs-C0 benchmark was expanded to an admitted typed 48-argument function, checking public infer-only and fully checked APIs, not only helper operations.

**Verified CI:**
- [38213558411](https://github.com/dwijayuda/pskernel/actions/runs/38213558411) passed native C0 build, negative regressions, C0 microbenchmarks, and independently built original-core matched workload. Original vs C0 cold full WHNF across three rounds of 1,600 calls: original 109/107/104 ms vs C0 112/102/103 ms, essentially parity.
- [38213859123](https://github.com/dwijayuda/pskernel/actions/runs/38213859123) passed 85-job native C0 build and checks. Opt-in session-owned indexed WHNF retention: plain 26 ms vs indexed 54 ms over 1,200 repeated calls; **negative result, not a production speedup**.
- [38214198674](https://github.com/dwijayuda/pskernel/actions/runs/38214198674) passed 40-root radix-promotion regressions. Opt-in retention remains slower (plain 27 vs indexed 53 ms).
- [38214477987](https://github.com/dwijayuda/pskernel/actions/runs/38214477987) passed 85-job build, negative/differential suite, microbenchmarks and matched original-core run. Canonical binder intern collision stress: historical 60 ms vs full binder-identity hash 8 ms (8 × 160 nodes), isolated ~7.5× improvement, not whole checking.
- [38214789693](https://github.com/dwijayuda/pskernel/actions/runs/38214789693) passed all native gates. Infer-only application-spine helper legacy 5 ms vs counted 1 ms (192 args × 350 runs), too short for broad speedup claims; the typed entire-application comparison is a subsequent CI gate.

**Next gates:** confirm `dd901d58` typed application benchmark and `796d3637` source validation; record repeated matched whole-operation data and memory. Continue integrating a **provenanced indexed representation into actual checked WHNF/DefEq** only after eliminating opt-in encode/cache overhead and completing fuel/environment-sensitive reduction families. Current opt-in arena is **not** an accepting indexed checker and must not be promoted based on isolated binder benchmarks. Metatheory and self-host tests remain deferred.



### Final validated checkpoint — typed applications and substitution diagnosis (October 12)

- [Native CI 38215126574](https://github.com/dwijayuda/pskernel/actions/runs/38215126574) at `796d3637b2bb18b3e6221942f201407cf30a1be5` passed C0 library build, native negative/differential suite (including infer-only spine fuel/error categories), C0 performance microbenchmarks and original-core matched tests.
- [Native CI 38214964079](https://github.com/dwijayuda/pskernel/actions/runs/38214964079) at `dd901d589a6162ee7c55370c982f99692f2fa315` passed native full build/checks and **matched complete typed application checking**: C0 vs unchanged original, *infer-only* 200 calls per round: C0 16/19/15 ms vs original 66/65/65 ms. *Fully checked* 80 calls per round: C0 50/50/50 ms vs original 31/31/30 ms. This is a serious observed checked-path regression, not an overall kernel win. The checked application implementation in `Checker/Inference/Core.lean` is byte-for-byte identical in C0 and original. Investigate cost in dependencies/caching/reduction rather than rewriting soundness rules speculatively. Process-level peak RSS in this same matched run: C0 563564 kB vs original 562540 kB, not a demonstrated memory improvement.
- [Native CI 38215639174](https://github.com/dwijayuda/pskernel/actions/runs/38215639174), source commit `30ba64034dc52e3a6a18344a2f5d220a9a5eb9ba`, **success**: 85-job C0 native library, negative/differential suite, C0 benchmarks, and original-core native matched benchmark. Synthetic 48-binder closed instantiation, 9000 calls: original-style loose-variable precheck 186 ms vs C0 specialized worker 2 ms. Open instantiation, 4000 calls: 71 ms vs 1 ms. These isolate source operations and **do not explain** the checked-application regression; do not revert the specialized instantiator on conjecture alone. The original-core temporary package is unchanged and rebuilt independently as 81 jobs.

**Remaining major priority:** profile complete checked-applications and record direct costs across recursive inference, cache lookup/insertion, WHNF, DefEq and substitution. Consider a checked application-spine execution design that preserves *per-frame resource/fuel* consumption, argument type comparison, safety checks, eager-reduction semantics and exact error outcomes. Qualify full positive/negative/differential operations and matched baseline **before** routing acceptance to a rewritten spine or indexed engine. Maintain session-owned root-store as opt-in: its current warm wrapper overhead remains a regression. Indexed delta/recursor/primitive/quotient/projection conversion and checked admission are not integrated. Nothing in this checkpoint establishes full Lean-kernel speedup, improved memory, metatheory, or self-hosting.



## Root-cause correction: checked application slowdown — 2026-10-12

**Controlled experiment:** A reproducible temporary C0 package was built with only the original `psKernelExprInstantiate1` restored from untouched PSKernel-Core (via `test/C0Ablation.py`); the entire public checker benchmark ran on the same runner and Lean 4.34.0 pin. [CI 38222241004](https://github.com/dwijayuda/pskernel/actions/runs/38222241004), source `95bf1d6514e3e89616ca34840a23a21a100b5697`, passed 85-job C0 native build, negative/differential checks, microbenchmarks, original-core matched benchmark and the private ablation. Its checked 48-application case (80 calls × 3 rounds) measured current C0 **65/65/66 ms**, untouched original core **40/39/39 ms**, and isolated C0-original-instantiation **40/40/40 ms**. The substitution implementation, not a speculative cache or checker-rule change, was causally implicated. Earlier fixed-input substitution microbenchmarks did not predict this full-checker cost.

**Architecture decision:** `0068cf45b1f1d0abd8513bc4e61b795eb517f736` changes only the C0 Lean source-owned `psKernelExprInstantiate1` dispatch. Binder-headed lambda/forall/let terms receive a lightweight exact loose-variable precheck and retain the original term when closed; for open binder terms the existing capture-avoiding one-pass specialized worker is used. Application-headed and other terms retain specialized one-pass traversal without an extra global prepass. This is a shape/family-level cost model, not a new equality or type checking rule. The generic simultaneous-substitution implementation remains unchanged. `09e68c27822eb45e93e071dc124b81e373383c4d` adds generic-oracle differential regressions across open/closed binder families.

**Validated resolution:** [CI 38222841665](https://github.com/dwijayuda/pskernel/actions/runs/38222841665), source `09e68c27822eb45e93e071dc124b81e373383c4d`, **passed** the full 85-job C0 Lean build, all native negative/differential tests, the full native microbenchmark suite, matched unchanged original-core build and benchmark (81 jobs), and private original-instantiation C0 ablation (85 jobs). Its 48-application *infer-only* matched run (200 calls × 3 rounds): C0 hybrid **19/19/19 ms**, original **82/81/82 ms**. Fully checked (80 calls × 3 rounds): C0 hybrid **39/40/39 ms**, original **38/39/39 ms**, C0-original-instantiation ablation **40/39/39 ms**. The previously observed ~1.6× checked regression was removed **for this workload**, while the infer-only improvement remained. Process peak memory for separate matched benchmark runs: C0 hybrid 562464 kB, original 562452 kB, ablation 563132 kB; **not a proved memory improvement**.

The original `pskernel-core` and existing Rust backend have not been modified. No self-hosting/bootstrap/fixed-point or metatheory testing was performed. The optional ablation workflow step is retained for manual `workflow_dispatch` diagnosis instead of running on every push (`bc5a47b83e96be72bf2a57a8c4692638448e4fb3`).

**Still open:** representative whole-library throughput, controlled memory/allocation data, soundness under broader Lean conformance and full environment-sensitive accepting indexed WHNF/DefEq/inference/admission with per-session identity and resource-safe provenance. The opt-in indexed wrapper remains slower on repeat WHNF, so do not route production acceptance through it until its internal executor can eliminate representation overhead.

## 2026-10-12, latest native comparison and handoff refresh

**Source head before handoff update:** `688315d51870dd34a2b602771061136a136f2eda` (ablation script correction), based on `b60c1719e29268f3b9b537587816fad5150561eb`. Refresh GitHub head before every write. Toolchain remains **Lean 4.34.0**. Do not run self-host/bootstrap/fixed-point or metatheory jobs.

**New workload families since the earlier handoff:** A matched original-vs-C0 native checker benchmark now includes independently admitted nested safe definitions, rejected invalid declarations, a growing 160-declaration library chain, and 16 varied 48-application inputs. These are useful end-to-end API samples, not full Init/Std/Mathlib qualifications. Native C0, unchanged original core, and private source-family ablations are built separately on the same CI runner.

**Last fully green pre-diagnostic run:** [CI 38225028395](https://github.com/dwijayuda/pskernel/actions/runs/38225028395), source `727a278440c9`, passed C0 Lean compilation, native negative/differential conformance, microbenchmarks, matched original core, and a private original-environment-index ablation. Representative three-round results:

| Full public API workload | C0 (ms) | Original core (ms) | C0 with original environment index (ms) |
| --- | --- | --- | --- |
| Cold WHNF, 1,600 calls | 109 / 110 / 109 | 109 / 111 / 111 | 108 / 109 / 109 |
| Infer-only application, 200 calls | 20 / 19 / 20 | 83 / 82 / 82 | 20 / 19 / 20 |
| Fully checked application, 80 calls | 39 / 40 / 39 | 39 / 39 / 39 | 39 / 40 / 39 |
| Varied infer-only application, 160 calls / 16 variants | 16 / 16 / 16 | 66 / 66 / 66 | 16 / 16 / 16 |
| Varied fully checked application, 160 calls / 16 variants | 82 / 83 / 82 | 82 / 82 / 82 | 82 / 83 / 82 |
| Growing safe library, 160 declarations | 49–50 | see full run logs | 62–65 |

The source-family ablation supports **no clear advantage from C0's environment index** on those workloads. CPU scheduler effects, run ordering and differing process setup make fine-grained cross-run differences unreliable. Complete-library claim and memory improvement remain unproven. The C0 infer-only improvement is substantial on these *specific* inputs; checked mode is near parity.

**Latest failed diagnostic:** [CI 38225068179](https://github.com/dwijayuda/pskernel/actions/runs/38225068179) at `b60c1719e29268f3b9b537587816fad5150561eb`. Native Lean build, conformance suite, microbenchmark and matched original checker steps **passed**; only the private `local_index_disabled` ablation step failed before compilation. Root cause: `test/C0Ablation.py` used escaped literal `\\n` strings in region delimiters and raised `RuntimeError: ablation region delimiters are not unique`. This was corrected in commit `688315d51870dd34a2b602771061136a136f2eda`; verify [native CI 38230646350](https://github.com/dwijayuda/pskernel/actions/runs/38230646350) for the subsequent ablation result before making any performance claims. The correction does **not** change checked Lean source.

**Next action:** Read the outcome of the local-index-disabled private ablation. Determine whether repeated local radix construction for many binders is material in full checked inference and admission; do not assume. If material, redesign the **real native Lean** local-context/checked-inference cost model (batch/memo ownership and persistent sharing) without changing checked behavior. Retain native negative/fuel/structural differential tests, paired original-core benchmarking, and no self-host tests. Investigate memory and representative library checking next.

**Handoff pointers:** `C0_LEAN_ARCHITECTURE.md`, `C0_BENCHMARKS.md`, `test/C0CheckerComparison.lean`, `test/C0Ablation.py`, `.github/workflows/pskernel-c0-lean.yml`, the native WHNF/DefEq/inference sources and optional `Checker/IndexedSession.lean`. The Rust arena remains experimental; **the accepting kernel remains written in Lean** and the unmodified original remains available as an independent baseline.



## October 12, 2026 — measured local-context write/read crossover and batched index

The last handoff at `cbcf6478` identified a diagnostic pending. [Native CI 38230646350](https://github.com/dwijayuda/pskernel/actions/runs/38230646350) at `688315d5` **passed** build, native negative/differential regressions, native microbenchmarks, matched original-core checking and private `local_index_disabled` ablation. On the same runner, growing a 160-definition library (16-binder bodies) took **61/62/61 ms** with eager radix at the ninth binder, **47/47/47 ms** with local indexing disabled, and **49/49/49 ms** in unchanged original PSKernel-Core. This was a production-checker bottleneck caused by paying persistent-index maintenance costs before enough deep lookups accrue.

First [native CI 38232026730](https://github.com/dwijayuda/pskernel/actions/runs/38232026730) qualified deferring eager promotion from binder 9 to 33: C0 admission **49/48/47 ms**, original **49/49/49 ms**, with local-index-disabled C0 **47/47/48 ms**. Native conformance, shadowing and persistent-snapshot regressions passed. However [CI 38232378403](https://github.com/dwijayuda/pskernel/actions/runs/38232378403) added a **48-binder** real checked admission workload and exposed the same cost at the new cutoff: C0 **75/77/76 ms** vs original **62/62/62 ms**, and local-index-disabled C0 **61/61/61 ms**. Raising the threshold in isolation simply relocates the cost.

**Architecture implemented in `.lean`:** `Core/LocalContext.lean` now uses a bounded **64-entry shallow list** and, for deep contexts, a persistent radix-16 **base snapshot with at most 15 pending local declarations** (most recent first). The 16th pending extension commits them in oldest-first order into a new immutable radix index. Every lookup scans pending entries before the radix bucket to preserve shadowing; the authoritative declaration list, fresh-name counters and earlier persistent snapshots remain unchanged. The two explicit continuation constructors in `Admission/Inductive/{Ordinary/Constructor,Mutual/Analysis}.lean` now preserve the matching pending overlay and count with their original index. [Commit 912156b1](https://github.com/dwijayuda/pskernel/commit/912156b109a735ae3214f388349108c4918aee8c) and dependent source/check commits are on this branch.

The native build, regressions (including lookup equivalence across promotion, shadowing and 16-entry batch commit) and regular matched checker benchmark **passed** on [CI 38233477973](https://github.com/dwijayuda/pskernel/actions/runs/38233477973), but the overall run was **red only in the optional ablation**: the diagnostic script still expected an `Option` return rather than new `PsKernelC0LocalIndexUpdate`. Do not conflate this tooling mismatch with an accepting checker regression. Fixed the diagnostic in `fd622395`; the already-resolved local-index ablation is now `workflow_dispatch` only (`593f83df`). Check the final regular CI run before claiming its overall status.

**Same-run measured performance at production source `7a0470d0` (CI 38233477973, normal gates passed):** 160× constructing 64-local contexts: list **3 ms**, adaptive index **4 ms**; 15× constructing 512-local contexts: list **2 ms**, adaptive **24 ms**; 20k lookups on 512 locals: linear **1279 ms**, indexed with pending overlay **76 ms**. In the matched original-core full checker: 160 checked declarations with depth 16: C0 **28/28/27 ms** vs original **28/28/27 ms**; 64 declarations with depth 48: C0 **45/44/45 ms** vs original **44/44/43 ms**. These are *bounded* same-run cases, not general library throughput or a measured memory saving. Extra index construction is justified by repeated deep lookups, not by the mere number of binders.

**Remaining priorities:** qualify the final CI after optional diagnostic is disabled, profile real full-library declaration/recursor workloads and allocation peaks, and only then extend indexed WHNF/DefEq into acceptance with exact environment/provenance/fuel semantics. Keep the opt-in session-owned indexed syntax layer separate from positive acceptance judgments until it proves lower full-checker cost. Never run self-host/bootstrap/fixed-point or metatheory tests in this iteration.



### Native CI closure: batched local index qualification

[CI 38233818758](https://github.com/dwijayuda/pskernel/actions/runs/38233818758), source `fd622395f03e1af40e7e4d18865fd1171aba6de2`, finished **successfully** with complete C0 Lean build (85 jobs), negative/differential tests (including batched shadowing), native microbenchmarks, matched independently built original core (81 jobs), and the corrected optional no-local-index private diagnostic (85 jobs). Same-run full checker declaration admission in that run: depth-16 chain C0 24/27/25 ms vs original 25/25/27 ms; depth-48 chain C0 41/42/41 ms vs original 41/40/43 ms; local-index-disabled C0 24/24/24 ms depth16 and 40/40/40 ms depth48. The net advantage of local indexed storage is lookup-dependent, **not** demonstrated across all declaration workloads.

[CI 38233883497](https://github.com/dwijayuda/pskernel/actions/runs/38233883497) at source/workflow commit `593f83df4d75a72ec17202e8cd04476a068e08a8` also **completed successfully**, with ordinary native Lean build, negative conformance/differential tests, native microbenchmarks and original-core matched checker. The private `local_index_disabled` ablation is available only on manual workflow_dispatch because its performance and the structural impact have already been isolated. All mandatory production checks are green; there were no self-hosting, bootstrap/fixed-point, Rust-generated, or metatheory tests.

**Current trustworthy baseline:** local-context short-list threshold 64, 16-local staged radix updates, immutable snapshots, separate original-core matched checking. Deep index construction still costs more than raw lists; 512-local repeated lookups are measurably faster. Avoid promoting opt-in indexed expression WHNF/DefEq to accepting verification before environment-dependent semantics, exact fuel and safe cache ownership are qualified. This project is not complete; representative large-library whole-checker speed/memory and indexed accepting-engine coverage remain open.



## Further native Lean redesign: demand-driven local index snapshots — October 12, 2026

The previous adaptive 64-binder + 16-element overlay design recovered performance for 16/48-binder admission, but [native CI 38234300832](https://github.com/dwijayuda/pskernel/actions/runs/38234300832) showed **96-binder** local-reference checking remained slower (~178–182 ms per 20 declarations) than unchanged original core (~162–165 ms). Deferring eager promotion to 129 locals [`45f4474f`](https://github.com/dwijayuda/pskernel/commit/45f4474fcd6f0ff9022ada08f15a9842dbfc19b3) recovered near-parity at depth 96 ([CI 38234744764](https://github.com/dwijayuda/pskernel/actions/runs/38234744764)), but source checks with 192 binders still showed ~186–190 vs ~175–178 ms.

**Design response:** `Core/LocalContext.lean` now holds its radix snapshot as an immutable, memoized Lean `Thunk`, with pending overlay and exact list retained. Source [`8d72f7fb`](https://github.com/dwijayuda/pskernel/commit/8d72f7fb116c9eb9d4d2b9da71cce1aa34c92116) changes indexing so binder extension *does not eagerly allocate radix nodes*. The index becomes available after 128 bindings but is **not forced** for lookup until the deep lookup policy (256). Pending overlay is checked newest-first before forcing the snapshot. A persistent context's thunk is pure/deterministic from its own immutable declarations; no cross-environment equality or type-acceptance cache is introduced. The checker still makes every typing/DefEq/admission decision on recursive `PsKernelExpr` and enforces the same fuel/resource rules. [`078ea101`](https://github.com/dwijayuda/pskernel/commit/078ea1013bc18d2a750ba49dd68ba08a3edba798) added memoized deep-local lookup, shadowing and snapshot differential regressions.

[CI 38235717690](https://github.com/dwijayuda/pskernel/actions/runs/38235717690), source `62fb1d34f4a8835b18d61b67621cc9f94e082643`, **passed the production native Lean build, negative/differential suite, native microbenchmarks and matched unchanged original-core full checker**. It failed only in an opt-in private `local_index_disabled` diagnostic because the source implementation had moved its lookup policy definition; the private script had stale delimiters. The workflow was corrected and this already-answered diagnostic is manual workflow_dispatch only as of `cc4f620a` and `1f5d783e`. Check the latest workflow for a fully green aggregate result before citing one.

Three-round *complete checked declaration* timings from that run: 20 checked declarations at depth 96 were ~163–168 ms in C0 vs ~161–165 ms original depending on reference position; six checked declarations at depth 192 were ~177–181 ms in C0 vs ~177–180 ms original; three checked declarations at depth 320 were ~237–247 ms C0 vs ~236–240 ms original. This is **near parity**, not evidence of generalized faster full-library checking. The 512-local lookup microcase still favors indexed access (139 ms vs linear 2054 ms for 20k lookups); it is slower than the formerly eagerly materialized radix on some matched microcases because of policy/overlay costs. Process memory attribution remains unresolved.

A separate binary-trie vs radix-16 diagnostic in native Lean (CI [38235530285](https://github.com/dwijayuda/pskernel/actions/runs/38235530285), all mandatory native steps passed, only optional diagnostic red) measured binary path-copy **77 ms** vs radix **35 ms** for constructing 25×512 locals, and binary **75 ms** vs radix **35 ms** for 20k lookups; no reason to replace the radix. The rejected binary diagnostic was removed from the benchmark source at `4cab1974`.

**Remaining main objective:** full environment-dependent indexed WHNF, DefEq, inference and admission in the trusted checking pipeline, with session-owned provenance, exact reduction priority/fuel, negative conformance, real representative library throughput, peak memory and repeated matched baseline checks. Opt-in indexed session still incurs overhead and should not be promoted on helper timings alone. Keep original `pskernel-core` and PSC0 Rust backend unchanged. No self-host, bootstrap, fixed-point or metatheory tests.
