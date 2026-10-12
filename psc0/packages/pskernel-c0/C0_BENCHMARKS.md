# PSKernel-C0 experimental performance measurements

**Scope:** Historical Rust substrate measurements (first section), Lean-native C0 microbenchmarks, and newer same-run original PSKernel-Core versus C0 complete-checker comparisons. The latest sections supersede the original Rust-only scope statement.

## Sources and reproduction

- [CI 38180969202](https://github.com/dwijayuda/pskernel/actions/runs/38180969202), commit `cf0ef867c008b0920444f70369a988552f937549`, success: 21 unit tests, Clippy and release benchmark smoke.
- Toolchain: rustc 1.99.0 (GitHub Actions Ubuntu runner).
- Run: `cargo run --release --manifest-path psc0/packages/pskernel-c0/experimental/arena-engine/Cargo.toml --example microbench`.

| Same-run case | Iterations | Total time |
|---|---:|---:|
| Follow stuck 1,024-application spine | 1,000 | 2.169 ms |
| WHNF with cache cleared before every request | 1,000 | 32.905 ms |
| WHNF repeated cache hits on same term | 1,000 | 0.014668 ms |
| Recursive substitution reference, 128-node spine | 300 | 4.824 ms |
| Hybrid depth-directed substitution, same spine | 300 | 4.623 ms |

All values are single sampled wall times on a hosted CI runner; frequency scaling, contention, sampling noise, workload composition and compiler version may affect results. The enormous repeated-cache-hit improvement is specific to identical context-free queries with preserved cache state. It cannot be generalized to cold checking or full Lean conversions.

## Architectural conclusions

- A fixed shallow/deep algorithm rule was adopted after [CI 38180720840](https://github.com/dwijayuda/pskernel/actions/runs/38180720840) measured recursive substitution at 4.861 ms and unconditional iterative substitution at 6.649 ms for 300 shallow iterations. The iterative engine remains for deep-term stack safety.
- Incremental WHNF caching uses stored required node visits and rejects insufficient-fuel calls on hits. Separate cold/warm benchmarks are required.
- Continue measuring memory consumption, end-to-end declaration checking, library throughput, parallelism and soundness-sensitive negative cases before production adoption.

## Native Lean C0 kernel-subsystem benchmarks (separate from Rust prototype)

[Native Lean CI run 38185426527](https://github.com/dwijayuda/pskernel/actions/runs/38185426527), successful, measured varied-input `lean --run test/C0PerfMicrobench.lean` workloads at 30,000 iterations with a 512-application term:

| Lean runtime operation | Original implementation | C0 implementation | Interpretation |
|---|---:|---:|---|
| de Bruijn lift (with old node-count prepass vs direct traversal) | 10,558 ms | 7,717 ms | Approximately 27% less elapsed time on this case |
| single-variable beta substitution (general list vs specialized) | 19,841 ms | 11,244 ms | Approximately 43% less elapsed time on this case |
| recursive equality vs fully paired equality | 2,458 ms | 2,646 ms | About 8% *slower*; prompted a revised hybrid head-dispatch comparator |

The equality implementation was subsequently revised; do not apply the paired-equality slowdown numbers directly to the latest hybrid. The added 512-local-declaration lookup benchmark will separately compare sequential list scanning with the persistent indexed local context. One CI runner and one measurement per case are not statistically reliable. No whole-kernel throughput or memory reduction has been quantified yet.

### Deep local-variable lookup result

[Native CI 38185618064](https://github.com/dwijayuda/pskernel/actions/runs/38185618064) passed full source compilation, native negative semantics and the new local-context shadowing tests. For 20,000 lookups among names 0–15 in a 512-local-declaration context, **linear lookup measured 2,048 ms** and **the C0 persistent radix index measured 66 ms** (approximately 31× faster for this narrow, repeated deep-context workload). This does not measure index construction, typical short contexts, memory or full kernel workloads. Old semantic and Unicode regressions also passed.

### Latest hybrid C0 Lean benchmark checkpoint

[Native CI 38185687752](https://github.com/dwijayuda/pskernel/actions/runs/38185687752), source commit `699ec13a3e3ec785d5e94b85211a29da06a8b84e`, passed the full Lean library build, native negative checks, structural differential suite and varied-input benchmarks. One run:

| C0 hot path | Legacy | C0 | Observed workload-specific change |
|---|---:|---:|---|
| Expression equality (30,000 × 512-level) | 2,078 ms | 2,055 ms | Near parity; not a reliable speedup claim |
| Lift (30,000 × 512-level) | 8,948 ms | 6,640 ms | ~26% elapsed-time reduction |
| Single substitution (30,000 × 512-level) | 16,694 ms | 9,358 ms | ~44% elapsed-time reduction |
| Local name lookup (20,000 lookups, 512 locals) | 1,691 ms | 54 ms | ~31× faster on deep-local lookup |

All times are single-run CI runner values and exclude representative end-to-end Lean module checking workloads and memory costs. They should be treated as microbenchmark evidence, not general speedup factors.


## Lean-native indexed execution checkpoint (2026-10-12)

[GitHub Actions 38189942349](https://github.com/dwijayuda/pskernel/actions/runs/38189942349) completed successfully with complete native Lean build, negative regressions and subsystem benchmarks. One hosted runner, one sample:

| Workload | Baseline | C0 design | Meaning |
|---|---:|---:|---|
| 30,000 stuck-application spine probes | 3,152 ms eager decomposition | 368 ms head-only | ~8.6× faster head-probe suboperation; no argument-list allocation on the stuck path |
| 70 substitutions on a depth-11 maximally shared indexed DAG | 903 ms recursive indexed | 11 ms memoized indexed | ~82× on a deliberately reuse-heavy DAG |
| 30,000 lifting traversals | 9,059 ms old | 6,709 ms direct | ~26% faster |
| 30,000 single-variable substitutions | 16,824 ms generic | 9,331 ms specialized | ~45% faster |
| 20,000 local lookups in 512-entry environment | 1,691 ms linear | 55 ms indexed | ~31× faster |

The new indexed-execution engine stores canonical subterms and memoizes rewrites by term ID and binder depth. Unlike the **accepting** WHNF demand-driven spine change, indexed WHNF remains experimental and limited to context-free beta/zeta/metadata. It must not issue kernel acceptance judgments.

These are **subsystem measurements**, neither complete kernel throughput nor PSC0 Rust backend compilation or self-hosting results. The Rust prototype measurements earlier in this file are separate. Preserve both cold and warm performance comparisons on identical workloads before adopting more indexed internals.


## Native Lean indexed WHNF unchanged-spine checkpoint — 2026-10-12

[CI 38191368025](https://github.com/dwijayuda/pskernel/actions/runs/38191368025) at `d9c78cd2b05bfb7c3f4750f004d27dab9399c058` passed the full native Lean library build, negative regression checks (including stuck indexed handle identity and metadata-head rewriting), and native microbenchmarks. **No self-host tests.**

| Microbenchmark, single hosted CI run | Total elapsed |
|---|---:|
| Reassemble only: intern a precomputed 256-argument spine, 600 repetitions | 750 ms |
| Optimized indexed WHNF: walk that same stuck spine and retain its exact original handle, 600 repetitions | 86 ms |
| Actual native checker cold WHNF: 400 checks of 128-argument stuck spines, each with a fresh state | 25 ms |
| Demand-driven raw head probe: 30,000 iterations | 447 ms |
| Eager raw head and full argument-list collection, 30,000 iterations | 4,014 ms |

The 750-ms reconstruction-only comparison is an isolated cost of the *removed work*: unlike a full original indexed WHNF run it omits the head traversal, and therefore the two first rows are **not** matched full-kernel throughput measurements. All 600 calls retained identical term IDs and node-store sizes. The cold actual-checker sample is a baseline and was not paired with the prior original-kernel implementation. Do not generalize these timings to full declaration admission, WHNF with environment unfolding, DefEq, or memory efficiency.

Other same-run subsystem measurements: native expression equality near parity (2,615 vs 2,624 ms), direct lifting 11,439 to 8,393 ms, specialized single substitution 20,882 to 11,965 ms, and indexed deep-local lookup 2,052 to 68 ms. These are workload-specific single-run measurements.


## Guarded DefEq and indexed WHNF performance checkpoint — October 12, 2026

[GitHub Actions 38192040598](https://github.com/dwijayuda/pskernel/actions/runs/38192040598), source commit `06532eac5b8f9cfa2df8b810887ab3f42ba809cb`, passed the native Lean library build, native negative/regression suite and benchmark suite. The workflow deliberately excludes self-hosting tests.

| Native Lean isolated operation | Same-run elapsed | Input |
|---|---:|---|
| General quick DefEq after a structural mismatch | 516 ms | 12,000 calls, 512-deep application pairs |
| Shape-specific quick DefEq after common guards already failed | 6 ms | Same terms, same calls |
| Reassemble an unchanged indexed application spine | 601 ms | 600 × 256 applications |
| Indexed WHNF preserving the original stuck-spine handle | 73 ms | Same indexed term, 600 calls |
| Cold native checker WHNF | 20 ms | 400 fresh-state checks, 128 applications |
| Indexed shared-DAG recursive rewrite | 909 ms | 70 rewrites, depth 11 |
| Indexed shared-DAG memoized rewrite | 11 ms | Same DAG, 70 rewrites |

**Interpretation:**
- The ~86× difference between general and already-guarded quick DefEq is a *microbenchmark of the second-stage helper*, not an 86× improvement of whole DefEq. The accepting checker in `Checker/Knot.lean` still executes the required first structural equality and success-cache check; the optimization removes their repetition before shape-specific quick rules.
- The indexed stuck-spine measurement compares work avoided by short-circuiting with the new head-walking WHNF path, not matched complete kernel checking.
- Absolute times are a single hosted Linux CI observation, not medians, p95s, memory measurements, or representative Lean library throughput.
- The syntax representation is still recursive at the full public checker boundary; the indexed WHNF engine covers a context-free subset, not environment-dependent delta/recursor/quotient/native reductions or checked admission. Do not infer full kernel speedup from these subsystem numbers.

The guarded quick path has an explicit differential regression and the full accepting checker retains its external quick API semantics. No metatheory/self-hosting testing was requested in this performance iteration.



## Continued Lean-native actual-checker measurements — October 12, 2026

Native source commit `b290a8dde0482ab195ffc59bd4eabf74f745a50b`, [CI 38194277302](https://github.com/dwijayuda/pskernel/actions/runs/38194277302) **passed** 84-job Lean build, soundness-sensitive negative/differential suite and matched microbenchmarks. The previously eager and newly deferred delta-miss helper both returned no reduction on 12,000 depth-512 stuck applications: **193 ms eager / 192 ms lazy**. No reliable speedup is established. Delta and constructor projections were differentially tested against exact previous helper implementations; the acceptance path remains recursive-source based.

Native source commit `cf0e3da4ee8ccf1870232316210110a9d02499f0`, [CI 38194545945](https://github.com/dwijayuda/pskernel/actions/runs/38194545945) **passed** all three native steps. Results:

| Same-run C0 workload | Observation | Important limitation |
| --- | --- | --- |
| Eager/lazy delta miss, 12k depth-512 calls | 193 / 183 ms | One run; timing noise, not whole WHNF |
| Cold/warm full session inference, 180 depth-24 lambdas | 2 / 7 ms | Too short to resolve reliably; no old-core baseline |
| Checked definition admission, 120 valid / 120 invalid | 2 / 0 ms | Under resolution, trivial small declaration |
| Cold complete WHNF, 400 depth-128 stuck apps | 26 ms | C0-only, unpaired across implementations |
| Process peak VmHWM | 612868 kB | Includes Lean process and all benchmarks, not checker-only RSS |
| Process current VmRSS | 605788 kB | End-of-process memory, not a per-case delta |

Source commits `7cf4c49748f87fb171339da61c6a80804a5b7eb6` and `e6e005541e78b38d70ec4ecc8f9d7177c50d2267` added direct indexed-position argument selection on the **real projection checker helper**; follow-up `a96a4f1fd76432ddaeafcc64e035b6b426223f86` added a paired 18,000-query depth-512 selector benchmark with matching outcomes and native differential tests. This is distinct from indexed expression DAG term IDs. Record final run measurements only once its CI has completed; benchmark timing has not yet been certified at this written checkpoint.

All CI jobs in this workstream exclude self-hosting/bootstrap tests. **Still missing:** matched original PSKernel-Core whole-library time, multiple-run medians/p95, isolated allocations, peak memory and actual indexed acceptance-engine qualification.



### Two-pass direct selection rejected by paired native measurement

[CI 38194880437](https://github.com/dwijayuda/pskernel/actions/runs/38194880437), commit `a96a4f1fd76432ddaeafcc64e035b6b426223f86`: native Lean library (84 jobs), negative/differential regression, and performance microbenchmarks **all succeeded**. The test included application spines with arities 0, 1, 2, 3, 32, 128 and every in-bounds/out-of-bounds index; the direct result matched historical list-backed selection.

| Same-run 512-application, 18,000 varied-index queries | Elapsed |
| --- | ---: |
| List-backed one-pass GetAppArgs + ListGet | **560 ms** |
| No-intermediate-list direct two-pass ArgAt | **1298 ms** |

The no-list selector is **~2.32× slower** on this workload. It is therefore **not** the production projection implementation: `5de4773f8fdbbfcc2e4acc0377524c1a92231683` restores the list-backed lookup after confirming constructor matching. The direct API and comparison benchmark are retained as negative performance evidence, not an acceleration claim. Complete-module throughput and per-operation memory were not measured. Other observed same-run values: eager/lazy delta miss 150/150 ms (parity), cold WHNF 20 ms for 400, full cold/warm 180× inference 1/6 ms, process peak VmHWM 632960 kB (entire benchmark process). These are not meaningful whole-library gains.



### Final post-rollback native validation (2026-10-12)

[PSKernel-C0 native Lean CI 38195084646](https://github.com/dwijayuda/pskernel/actions/runs/38195084646) at source commit `5de4773f8fdbbfcc2e4acc0377524c1a92231683` **passed all three gates**: 84-job full native Lean build; negative and differential semantic checker regression; native Lean performance benchmark suite. The production constructor-projection path again uses list-backed application-field selection. The direct selector remains an experimental helper, never a checked shortcut. Its paired same-run reference-vs-direct result still regressed: 396 ms list / 911 ms direct over 18,000 depth-512 queries (~2.30× slower). Delta eager/lazy miss results 112/111 ms are near parity, not a reliable checker speedup. Native Linux entire benchmark process VmHWM 633996 kB. This validation includes **no self-host/bootstrap or metatheory tests**. Representative entire-library baseline and session-indexed acceptance work remain open.



## October 12: same-run original-versus-C0 native checker qualification

Exact same `test/C0CheckerComparison.lean`, 4.34.0 toolchain, original repository `pskernel-core/src` staged into an isolated temporary Lake package (source unchanged). Initial successful [CI 38213558411](https://github.com/dwijayuda/pskernel/actions/runs/38213558411):

| Full cold WHNF 1,600 calls/round | Original core | C0 |
| --- | ---: | ---: |
| Round 0 | 109 ms | 112 ms |
| Round 1 | 107 ms | 102 ms |
| Round 2 | 104 ms | 103 ms |

These observations show **near-parity**, not a reliable full-checker win. Other matched simple DefEq/inference/admission cases were mostly sub-10-ms samples and cannot support performance rankings. The later test also exercises a genuinely admitted typed 48-application function; record those results separately once its CI run completes.

[CI 38213859123](https://github.com/dwijayuda/pskernel/actions/runs/38213859123): ordinary checker **26 ms** vs opt-in indexed-session retention **54 ms**, over 1,200 repeated stuck WHNF checks; 50 canonical nodes retained, 1 root. No benefit, do not enable on production default. [CI 38214198674](https://github.com/dwijayuda/pskernel/actions/runs/38214198674) with 40-root radix-promotion tests similarly measured 27 ms ordinary vs 53 ms retained indexed session. The indexed store is only staging.

[CI 38214477987](https://github.com/dwijayuda/pskernel/actions/runs/38214477987) **passed** the full native build/test/benchmark plus original-core comparison. On a cold canonical binder interning stress of eight stores, each with 160 distinct binder names, the pre-change missing-binder-identity hash measured **60 ms**, new full-identity hash **8 ms** (~7.5× reduction in this isolated term-store operation). The new hash covers lambda/forall names and binder info, plus let names. Exact interning remains collision-checked. This is not the accepting checked pipeline.

[CI 38214789693](https://github.com/dwijayuda/pskernel/actions/runs/38214789693) **passed** all native gates. Original infer-only spine worker with repeated list-count scans: **5 ms**, new once-per-spine count worker: **1 ms**, 192 args × 350 calls. Values are too small to support a stable 5× overall throughput assertion; benchmark is isolated and does not include full expression inference or checked admission. No self-host or bootstrap tests run.

C0 peak benchmark process VmHWM includes Lean interpreter, all tests and temporary allocations; treat it as process-level only. Representative complete library throughput, p95, per-operation allocations and proof/semantic correctness evidence beyond differential tests remain open.



### Matched public inference results and checked-application regression

[CI 38214964079](https://github.com/dwijayuda/pskernel/actions/runs/38214964079), with a 48-argument function admitted through the regular checked axiom API; identical source, same Linux CI runner, original core and C0 compiled under Lean 4.34.0:

| Complete public checker API, three rounds | C0 | Original |
| --- | --- | --- |
| Infer-only: 200 cold calls per round | 16, 19, 15 ms | 66, 65, 65 ms |
| Fully checked: 80 cold calls per round | 50, 50, 50 ms | 31, 31, 30 ms |
| Whole benchmark-process peak VmHWM | 563564 kB | 562540 kB |

C0's full infer-only path wins on this fixture, while checked inference is **~1.6× slower**. These are three hosted-runner observations, not a population statistic, general Lean library workload or isolated-checker allocation measurement. Record the regression explicitly; do not present the infer-only improvement as an overall kernel speedup. The checked-inference branch in `Checker/Inference/Core.lean` is unchanged from original, so seek the bottleneck in called helpers/caches.

[CI 38215530916](https://github.com/dwijayuda/pskernel/actions/runs/38215530916), source `e3c407617b858987a4081c678934ffbdf4a03b00`, passed native build/regression/benchmarks plus matched baseline. Its closed 48-forall instantiation stress (9000 repeated calls) measured old loose-variable precheck 117 ms vs source-specialized C0 2 ms.

[CI 38215639174](https://github.com/dwijayuda/pskernel/actions/runs/38215639174), source `30ba64034dc52e3a6a18344a2f5d220a9a5eb9ba`, **passed every native gate**. A second observed *closed* stress measured old precheck 186 ms vs C0 2 ms (9000 calls). A genuinely *open* 48-binder stress measured old precheck/general instantiation 71 ms vs C0 1 ms (4000 calls). These are separate microbenchmarks with fixed input under repeated loops, not entire checker benchmarks. They **contradict the hypothesis** that source-specialized substitution itself is slowing the checked application; no evidence-based reason to revert it.

The opt-in indexed-session wrapper is still slower (ordinary 26–27 ms vs wrapper 53–54 ms over 1,200 warm WHNF calls); it is not production default. Indexed binder-hash interning improvement and infer-only count optimization remain separately measured, not whole-kernel qualification. No self-hosting or fixed-point runs.



### Controlled original-instantiation ablation and production hybrid qualification — October 12

[Native CI 38222241004](https://github.com/dwijayuda/pskernel/actions/runs/38222241004) restored **only** the original `instantiate1` implementation in a private copy of C0, retaining all other C0 Lean source and identical checked benchmark inputs:

| Same runner, public 48-argument application, 80 fully checked calls/round | Round 0 | Round 1 | Round 2 |
| --- | ---: | ---: | ---: |
| C0 before hybrid | 65 ms | 65 ms | 66 ms |
| Original unmodified kernel | 40 ms | 39 ms | 39 ms |
| C0 with original instantiate1 (private ablation) | 40 ms | 40 ms | 40 ms |

This establishes a causally relevant subsystem bottleneck that fixed-input isolated instantiation microbenchmarks masked.

[Native CI 38222841665](https://github.com/dwijayuda/pskernel/actions/runs/38222841665) validates the **production Lean-native two-strategy instantiation**. All three native gates and matched original-core and optional ablation comparisons passed.

| Same-run complete public checking | Hybrid C0 | Unmodified original | C0/original-instantiate1 ablation |
| --- | --- | --- | --- |
| Infer-only, 200 calls/round, 3 rounds | 19 / 19 / 19 ms | 82 / 81 / 82 ms | 19 / 19 / 19 ms |
| Fully checked, 80 calls/round, 3 rounds | 39 / 40 / 39 ms | 38 / 39 / 39 ms | 40 / 39 / 39 ms |
| Independent-process peak VmHWM | 562464 kB | 562452 kB | 563132 kB |

**Interpretation:** the checked-application slowdown is eliminated **on the tested fixture** without reverting one-pass specialization for application-headed terms. Peak RSS is indistinguishable at this resolution and is process-wide. These are limited fixtures and single-run triplicates, not full real-library qualification. The new hybrid keeps mandatory resource/checker judgments unchanged. Benchmark workloads still need broad distribution and p95 measurements. The original core remains unmodified.
