# PSKernel-C0 experimental performance measurements

## Online official-export and atomic bound-root checkpoint — CI 38332583934

Full [native CI 38332583934](https://github.com/dwijayuda/pskernel/actions/runs/38332583934) **SUCCESS** at `7035d682` with 22 original-byte official Lean 4.35 fixtures, online/batch outcome cross-check, negative resource tests, atomic canonical store transfer and matched unchanged original checker.

| Same-run synthetic complete checked workload | C0 | Original PSKernel-Core |
| --- | ---: | ---: |
| 24 × 12 declaration batch median latency | **24 ms** | **46 ms** |
| p95 batch latency | **25 ms** | **47 ms** |
| Small-allocation events per batch (not bytes) | **36,184** | **34,971** |
| Whole checker benchmark VmHWM | **1,147,396 kB** | **1,151,148 kB** |

No isolation of the new *test adapter* or non-accepting source-store API as a kernel throughput improvement; accepting kernel source remains unchanged. Different CI runs vary. No real Init/Std/Mathlib performance or con-ron/con-leche/official Lean C++ benchmark exists on an identical accepted corpus.

## Phase B/C follow-up source benchmark — CI 38323005998

[Native CI 38323005998](https://github.com/dwijayuda/pskernel/actions/runs/38323005998) **SUCCESS** at `64ae30cf`: 22 official same-byte Lean 4.35 positive/negative cases, C0 source replay, bounded indexed root transfer, native regressions, microbenchmarks and unchanged original comparison. Matched **fully checked synthetic** 24 × 12 declaration batches, 288 admissions per checker: C0 p50/p95 **26/26 ms**, original **49/50 ms**. Small allocations C0 **36,184**, original **34,971**; process VmHWM C0 **1,148,736 kB**, original **1,146,344 kB**. No memory improvement or real-library competitive result is established; comparison is against a project-local shared-lineage original.

## Latest complete native v4.35.0 C0 measurements — CI 38316694316

**Source commit:** [`51f32f59`](https://github.com/dwijayuda/pskernel/commit/51f32f5982f29919ac290c726cac36a5da750836). [Native workflow 38316694316](https://github.com/dwijayuda/pskernel/actions/runs/38316694316) **SUCCESS** including 14 matched official Lean 4.35 NDJSON cases, two 128-definition streams, negative conformance, index/scratch validation, microbenchmarks, and unchanged original checker.

| Same-run measurement | C0 | Baseline | Scope |
| --- | ---: | ---: | --- |
| Fully accepted 24 × 12 synthetic mixed declaration batches, p50 / p95 | **14 / 15 ms** | **28 / 29 ms** unchanged original | Whole checked **synthetic fixture** |
| Thread-local small-allocation events per batch | **36,184** | **34,971** original | C0 worse, not bytes |
| Whole benchmark-process VmHWM | **1,154,848 kB** | **1,150,888 kB** original | C0 more, no memory win |
| 24 selected depth-11 shared-DAG transfers, syntax-only | **38 ms** indexed selective promotion | **260 ms** source decode/reencode | 76 staged nodes / 12 promoted; not checked program performance |

Previous [CI 38315455947](https://github.com/dwijayuda/pskernel/actions/runs/38315455947) measured **79 vs 525 ms** on the same synthetic scratch/source transfer and **26/26 versus 49/50 ms** checked mixed admissions; substantial between-run machine variation makes single-digit millisecond ratios tentative. No qualified Mathlib/Init checking or con-ron/con-leche/official C++ benchmark on identical corpora exists.

## New 4.35 native benchmark qualification — 2026-10-13

**Source and toolchain:** stable Lean 4.35.0, successful native source CI [38315455947](https://github.com/dwijayuda/pskernel/actions/runs/38315455947), before the latest official-NDJSON parser extension. No source-level metatheory, Rust or selfhost qualification.

| Measured same-run workload | C0 | Baseline | Interpretation |
| --- | --- | --- | --- |
| 24 × 12 accepted mixed safe-declaration batches, wall time p50/p95 | **26 / 26 ms** | **49 / 50 ms** unchanged original `pskernel-core` | Synthetic **complete checked** workload, not external C++ or real library |
| Same batch, thread-local small-allocation event proxy | **36,184** | **34,971** | C0 has **more** allocation events; not allocated bytes |
| Whole benchmark-process VmHWM | **1,151,824 kB** | **1,145,152 kB** | No memory win |
| 24 selected depth-11 shared-DAG transfers | **79 ms indexed scratch promotion** | **525 ms source decode+reencode** | Experimental syntax transfer only; 76 temporary nodes/12 committed |

The indexed scratch implementation [CI 38315348542](https://github.com/dwijayuda/pskernel/actions/runs/38315348542) passed canonical sharing, removal of unselected scratch nodes, immutable snapshots and negative/malformed-node tests. The full-trie replay validator [CI 38314757371](https://github.com/dwijayuda/pskernel/actions/runs/38314757371) passed; this is not a formal `StoreWF` proof or an accepting kernel operation. Source-side `leanchecker` v4.35 same-byte NDJSON tests currently involve a **tiny, selected** exported declaration subset only; no Mathlib/Init conformance or independent whole-library throughput exists. Compare con-ron and con-leche against C0 only after matching exact corpus/version/policy/worker count and resource metrics.

## Research-qualified baseline and measurement gaps — 2026-10-13

Reference study: [C0_LEAN4_KERNEL_COMPARATIVE_SOURCE_RESEARCH_2026-10-13.md](C0_LEAN4_KERNEL_COMPARATIVE_SOURCE_RESEARCH_2026-10-13.md). Native accepting **C0 source HEAD** [`497df6a`](https://github.com/dwijayuda/pskernel/commit/497df6a39947aa3532b2d1a6ffe84342125fd2fc); full native [CI 38305932773](https://github.com/dwijayuda/pskernel/actions/runs/38305932773) succeeded. Research commits are documentation-only, not tests of new source behavior.

| Same-run actual checked synthetic workload | Native C0 | Project-local unchanged original |
| --- | ---: | ---: |
| 24 batches × 12 fully admitted definitions, batch p50 | **25 ms** | **47 ms** |
| Same, batch p95 | **25 ms** | **47 ms** |
| Thread-local small-allocation event count, batch p50/p95 | **36,206** | **34,971** |
| Whole benchmark process VmHWM | **1,165,716 kB** | **1,165,844 kB** |

**Within C0 source only:** 120 sequential checked definitions **16 ms direct**, **17 ms lazy indexed session**, **24 ms old eager root retention**; 1,200 fully checked WHNF requests **26/27/43 ms direct/lazy/eager**. No proved speedup from simply retaining indexed syntax.

The expensive indexed shared-DAG synthetic *universe instantiation*, *lifting* and *decoding* microbenchmarks are distinct from these **complete authoritative** checker operations and cannot be extrapolated. The Arena September 2026 Mathlib numbers in the full research report are **another different benchmark experiment** with different checkers, toolchains, threads and configurations. PSKernel-C0 has no valid Arena or whole-Mathlib result. Record exact corpus, version, options, number of workers, cold/warm state, attribution, latency distributions, actual allocated bytes and RSS when adding external comparisons. Small-allocation heartbeat counts are **not** allocated bytes.

## Newest native qualification — 13 October 2026

The native Lean C0 indexed substrate gained operation-local memoized lifting [`e8ec74a9`](https://github.com/dwijayuda/pskernel/commit/e8ec74a9c6a20da299153a38a830c8c5cbfbe5b8), exact-vs-source-cache-compatible dual node hashes [`4089835f`](https://github.com/dwijayuda/pskernel/commit/4089835f74a5f7ae3130890bacedbffcdd9c10a3) (historical benchmark constructor corrected [`1f57a8fb`](https://github.com/dwijayuda/pskernel/commit/1f57a8fb6efec1c78a4e6469eda05528eb4e855f)), and session root-index publication from the cached checker-compatible hash [`aae8f5f3`](https://github.com/dwijayuda/pskernel/commit/aae8f5f3385347eeade9880a306086d2dd96150c). All necessary native stages, including unchanged-original checked comparison, passed at [CI 38294019928](https://github.com/dwijayuda/pskernel/actions/runs/38294019928). The indexed engine remains **experimental and not an accepting checker**.

**Indexed lift microbenchmark**, same native indexed store, 30 repeated shifts of a maximally shared depth-11 open DAG:

| CI | Original recursive indexed lift | New memoized indexed lift |
| --- | ---: | ---: |
| [38292583191](https://github.com/dwijayuda/pskernel/actions/runs/38292583191) | 659 ms | 7 ms |
| [38293885978](https://github.com/dwijayuda/pskernel/actions/runs/38293885978) | 639 ms | 6 ms |
| [38294019928](https://github.com/dwijayuda/pskernel/actions/runs/38294019928) | 776 ms | 8 ms |

This is a **deliberately DAG-sharing-heavy helper workload**, not source WHNF/DefEq/inference/admission throughput. Per-operation memos do not cross term stores or amounts. Distinct exact syntax fingerprints and source checker cache fingerprints are not interchangeable; all cached candidates still undergo the appropriate complete structural-equality comparison.

**Complete checked declaration batch**, same compiled `test/C0CheckerComparison.lean` source independently run in C0 and the original unmodified `pskernel-core` with Lean 4.34: each batch sequentially admits **12 safe mixed lambda/local-reference/zeta definitions** into an initially empty environment; **24 batches**, **288 declarations admitted** per checker. The 24 duration/allocation samples are reported as p50/p95 for the **whole 12-declaration batch**, not for individual declarations.

| Metric | [CI 38293885978](https://github.com/dwijayuda/pskernel/actions/runs/38293885978) C0 / original | [CI 38294019928](https://github.com/dwijayuda/pskernel/actions/runs/38294019928) C0 / original |
| --- | --- | --- |
| p50 batch latency | **20 / 38 ms** | **25 / 47 ms** |
| p95 batch latency | **20 / 38 ms** | **26 / 48 ms** |
| p50 small-allocation counter | **36,206 / 34,971** | **36,206 / 34,971** |
| p95 small-allocation counter | **36,206 / 34,971** | **36,206 / 34,971** |
| Whole benchmark-process VmHWM | **1,163,168 / 1,161,176 kB** | **1,167,820 / 1,161,116 kB** |

Interpretation: C0 has roughly **1.9x** better latency on this engineered mixed checker family, with **~3.5% more** small-allocation events and no reliable peak-memory advantage. Lean `IO.getNumHeartbeats` counts current-thread small allocations, **not allocation bytes, all threads, total process allocations or RSS**. These are two different CI runs (each with paired C0/original checker in the same runner), not full Init/Std/Mathlib proof-library throughput or a statistical population of independent hosts. The new indexed substrate is **not responsible for an isolated proven fraction** of this source-path C0 advantage. Short ordinary and inductive workloads remain near parity in earlier checked results. Do not suppress this negative memory evidence.

**Required next measurements:** realistic admitted multi-module libraries and recursor/quotient/native families; cold/warm, independent reruns, quantiles with finer timing than whole milliseconds where useful, per-operation allocations/bytes with instrumentation, peak memory; C0-with-index/without-index controlled ablations at the same complete accepting entry points. No self-hosting or metatheory tests in this phase.

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

## Native full-checker three-way source-family comparison — October 12, 2026

[Green CI 38225028395](https://github.com/dwijayuda/pskernel/actions/runs/38225028395) at source `727a278440c9` built C0, unchanged original core, and an isolated C0 variant replacing just `Runtime/Acceleration/EnvironmentIndex.lean` with the original source.

| Complete checked/infer API (same runner, 3 rounds) | C0 (ms) | Original (ms) | Environment-index ablation (ms) |
| --- | --- | --- | --- |
| Cold 48-application infer-only, 200 calls | 20/19/20 | 83/82/82 | 20/19/20 |
| Cold 48-application fully checked, 80 calls | 39/40/39 | 39/39/39 | 39/40/39 |
| Varied infer-only, 160 calls across 16 terms | 16/16/16 | 66/66/66 | 16/16/16 |
| Varied fully checked, 160 calls across 16 terms | 82/83/82 | 82/82/82 | 82/83/82 |
| Cold WHNF, 1,600 calls | 109/110/109 | 109/111/111 | 108/109/109 |

The environment-index change has negligible apparent effect on these *particular full public API* workloads. It is not the cause of the substantial infer-only gain. Fully checked application performance is near parity, not a broad speedup. A growing 160-declaration library-chain and nested safe/invalid admissions are now part of the matched suite but remain too small to qualify full Lean library checking.

At [run 38225068179](https://github.com/dwijayuda/pskernel/actions/runs/38225068179), all standard Lean-native stages passed, but a **private local-index-disabled ablation** failed due to a Python delimiter error *before* producing comparison timings. Commit `688315d51870dd34a2b602771061136a136f2eda` fixes the delimiters; see [run 38230646350](https://github.com/dwijayuda/pskernel/actions/runs/38230646350) for qualification. Never interpret the failed diagnostic as a Lean kernel regression. All of these workflows exclude self-hosting.



## Local-context promotion and batched index: measured architecture tradeoff (2026-10-12)

[CI 38230646350](https://github.com/dwijayuda/pskernel/actions/runs/38230646350), same-run complete 160-definition checked library with 16-binder bodies: eager index after 8 locals **61/62/61 ms**, C0 no-local-index diagnostic **47/47/47 ms**, unchanged original **49/49/49 ms**. The first delayed 32-local policy passed [CI 38232026730](https://github.com/dwijayuda/pskernel/actions/runs/38232026730) with C0 **49/48/47 ms**, original **49/49/49 ms** on that workload. However [CI 38232378403](https://github.com/dwijayuda/pskernel/actions/runs/38232378403) found a remaining deeper-case regression: depth-48 checked library C0 **75/77/76 ms**, original **62/62/62 ms**, disabled index **61/61/61 ms**.

The subsequent native Lean `Core/LocalContext.lean` redesign retains shallow contexts as lists through 64 binders, then stores a structurally shared radix-index snapshot plus a **bounded pending overlay**. Deep index commits occur once per 16 new binders. `Checker/Context` and ordinary/mutual admission keep exact snapshot, shadowing, fresh-name, lookup semantics. [Native run 38233477973](https://github.com/dwijayuda/pskernel/actions/runs/38233477973) passed production C0 build, native negative/differential suite, C0 microbenchmarks and original-core matched full checker. Its only failing step was an *obsolete optional ablation generator* for the changed return type; not an accepting Lean source failure.

| Normal native same-run measurement at `7a0470d0` | List/reference | Adaptive index |
| --- | ---: | ---: |
| Build 160 contexts, 64 locals each | 3 ms | 4 ms |
| Build 15 contexts, 512 locals each | 2 ms | 24 ms |
| 20,000 lookups among 512 locals | 1,279 ms linear | 76 ms indexed |

| Checked declarations, 3 rounds, same runner | C0 batched | Original PSKernel-Core |
| --- | --- | --- |
| 160 declarations, nested body every 8, depth 16 | 28 / 28 / 27 ms | 28 / 28 / 27 ms |
| 64 declarations, nested body every 4, depth 48 | 45 / 44 / 45 ms | 44 / 44 / 43 ms |

The index increases construction cost at very deep scopes but substantially reduces repeated lookup cost. The improvements are **workload-dependent** and the entire checked pipeline has not yet been qualified against representative large Lean library exports or per-operation allocations. A corrected local-index-disabled diagnostic is retained as a manual `workflow_dispatch` option. No self-host, fixed-point or metatheory jobs were run.



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



## 12 October: direct equality rejected; canonical indexed loose range accepted as substrate

[Native CI 38238445255](https://github.com/dwijayuda/pskernel/actions/runs/38238445255), successful: tried direct recursive expression equality in native Lean, with unchanged legacy curried comparators as semantic reference.

| Benchmark | Historical | Candidate |
| --- | ---: | ---: |
| 30,000 structural pairs | 2,135 ms | 2,236 ms |
| 15,000 exact syntax pairs | 753 ms | 805 ms |

The candidate was 4–7% slower on these cases. Production equality was **restored** in source commit `bdec38c4e57bc60f0156393368b66e76737085b9`. No equality speedup claimed.

[Native CI 38239387122](https://github.com/dwijayuda/pskernel/actions/runs/38239387122), source `c8d63e109247fd28b9608cb045562e5699583870`, successful all native gates (including negative/differential and unchanged original-core comparison). New per-node exact loose de Bruijn range metadata permits constant-time unchanged-subtree pruning in indexed substitution and lifting.

| Same-run source-owned indexed operation | Historical indexed reference | Cached range with memo |
| --- | ---: | ---: |
| Closed shared DAG, 11 levels, 100 instantiations | 885 ms | 1 ms |
| General shared DAG, 11 levels, 70 rewrites | 1,134 ms | 15 ms |

The first comparison includes both metadata pruning and existing memoization; it does **not** isolate metadata alone. The fast path returns the identical unchanged handle for closed terms; full decoded-result and range-predicate differential tests passed. The runner reports integer millisecond timing, and this is one run only.

Selected **complete original-vs-C0 native checker** results in the same successful run:

| Public checked workload | C0 | Original |
| --- | --- | --- |
| Varied fully checked 48-argument applications, 160 per round | 76/78/78 ms | 75/77/77 ms |
| Growing safe library, 160 declarations | 46/47/46 ms | 47/47/47 ms |
| Ordinary inductive admission, 2,000 calls | 46/46/46 ms | 46/46/46 ms |

These are effectively near-parity. No causal end-to-end gain is attributable to indexed metadata because the accepting checker does not execute the indexed engine. No evidence yet for reduced process memory, real representative libraries or indexed resource exhaustion parity. Original package, Rust backend and self-hosting targets unchanged.


## Exact local declaration count and controlled list-length ablation — 12 October 2026

Source [e8952b95](https://github.com/dwijayuda/pskernel/commit/e8952b95a279f5bf82aa7b2c664d17430308bbd7); [successful native CI 38240821497](https://github.com/dwijayuda/pskernel/actions/runs/38240821497). The cached count eliminates a linked-list length traversal during each pre-promotion local extension, with regression coverage for fresh-name counters not equal to live declaration depth. It adds one Nat field per persistent local-context node; exact allocation and memory benefit have **not** been isolated.

| Native same-run matched complete checking (round 0) | C0 | Unchanged original |
| --- | ---: | ---: |
| Varied infer-only applications, 160 | 14 ms | 58 ms |
| Varied fully checked applications, 160 | 73 ms | 72 ms |
| Growing checked library, 160 declarations | 41 ms | 43 ms |
| Checked depth-48 library, 64 declarations | 70 ms | 67 ms |
| Local-reference admission at depth 192 (three indices) | 151–154 ms | 149–153 ms |
| Local-reference admission at depth 320 (three indices) | 201–204 ms | 204–210 ms |
| Local-reference admission at depth 512 (three indices) | 339–348 ms | 332–350 ms |

Native source-owned construction of 160 independent contexts with 128 locals took **9 ms list-only / 14 ms adaptive**. These compare different index policies, **not** cached count versus historical list-length scan. Full matched checker process VmHWM C0 **724508 kB** / original **727748 kB**, process-wide and not a per-operation allocation measurement. Other runs and source changes prevent causal before/after conclusions. No complete library-wide throughput or memory winner is established.

To isolate the counter alone, [commit e2fea7fe](https://github.com/dwijayuda/pskernel/commit/e2fea7feac956c0197cb71edfed1770841f3c161) adds an opt-in tagged temporary-package diagnostic: restore only the prior `context.decls.length` promotion predicate in a private C0 copy and run the same full checker fixture. [Run 38241386784](https://github.com/dwijayuda/pskernel/actions/runs/38241386784) is the target run. This neither edits original `pskernel-core` nor runs self-hosting. Record negative or negligible results without turning micro timing into a full-checker claim.


### Same-run cached count versus historical full-checker ablation (completed)

[CI 38241386784](https://github.com/dwijayuda/pskernel/actions/runs/38241386784) **passed** all mandatory native gates and the tagged isolated diagnostic. The third checker run was a **temporary C0 copy** with only the radix-promotion predicate changed back from cached `context.declCount` to historical `context.decls.length`. Original PSKernel-Core was independently and identically benchmarked in the same workflow; it was never modified.

| Three rounds of full public C0 checker (ms) | C0 cached count | C0 private length-scan | Unchanged original core |
| --- | --- | --- | --- |
| Varied fully checked applications, 160 | 68 / 66 / 66 | 65 / 66 / 66 | 64 / 65 / 66 |
| Growing checked library, 160 declarations | 37 / 38 / 38 | 37 / 38 / 38 | 38 / 38 / 39 |
| Checked depth-48 chain, 64 declarations | 61 / 78 / 62 | 62 / 62 / 63 | 61 / 61 / 62 |
| Local references depth 96, bvar 0, 20 declarations | 127 / 130 / 132 | 129 / 129 / 130 | 127 / 127 / 128 |
| Local references depth 192, bvar 0, 6 declarations | 138 / 138 / 140 | 139 / 139 / 140 | 137 / 138 / 138 |
| Local references depth 320, bvar 0, 3 declarations | 185 / 184 / 185 | 185 / 189 / 186 | 183 / 183 / 184 |
| Local references depth 512, bvar 0, 2 declarations | 306 / 305 / 306 | 306 / 306 / 306 | 306 / 304 / 305 |

Whole-process `VmHWM`: **727164 kB** cached C0, **723916 kB** length-scan C0, **725344 kB** original. These are process-wide snapshots affected by runtime, compilation/benchmark fixture and garbage collection, not per-operation memory attribution. The 128-declaration isolated build comparison (9 ms list / 14 ms indexed) does not isolate the counter, and the controlled full-checker ablation **does not demonstrate material gain** from caching length. Retain the result as an important *negative qualification*: do not confuse improved asymptotic expression for a measured whole-kernel winner. No self-hosting or metatheory tests were run.


## Large accepting checked application performance — new qualified source-family win

[Production promotion 23e088a6](https://github.com/dwijayuda/pskernel/commit/23e088a645599ab4930a6ae42c491c842e101c00) and [explicit recursive benchmark-oracle 501cd77c](https://github.com/dwijayuda/pskernel/commit/501cd77ce5d600115c7e82b3efa30b3a2e75657a). [All-green native Lean CI 38246930574](https://github.com/dwijayuda/pskernel/actions/runs/38246930574). C0 new checked route collects original-fuel/context application frames and uses a single bounded exact loose-variable Pi-body summary. Pi bodies with range 0 return unchanged, while every dependent/unsupported case continues ordinary checked substitution. Root spines shorter than 64 and all other roots use original recursive `psKernelInferCoreWithFuel`. The native C0 build and negative tests (including fuel/depth and exact loose-variable oracle) passed, as did unchanged original-core comparison.

| Same-run complete public checker (three rounds, ms) | C0 accepting | Unchanged original |
| --- | --- | --- |
| Typed 192-arg fully checked applications (12 calls) | **9 / 7 / 7** | **33 / 34 / 34** |
| Typed 192-arg infer-only applications (48 calls) | **7 / 8 / 8** | **127 / 128 / 127** |
| Varied 48-arg fully checked applications (160 calls) | 52 / 50 / 50 | 48 / 48 / 48 |
| 160 checked declaration chain | 32 / 28 / 29 | 29 / 29 / 29 |
| 64 checked depth-48 declarations | 51 / 47 / 46 | 46 / 46 / 45 |

An isolated **whole checked operation, not a helper** in C0 with 60 repeated 192-argument admitted axiom applications measured **158 ms** explicit recursive worker / **31 ms** framed metadata route. These same-run numbers show a ~4–5× speedup only on large non-dependent Pi-spine checked application workloads. They are not whole-kernel/library or memory claims. Full comparison VmHWM: C0 844060 kB, original 841284 kB; per-check allocations, p95 and library RSS remain unknown. Preserve slight regressions in short checked paths and declaration chains; avoid overclaiming from high-arity fixtures. Prior unsafe `ptrEq` comparator was rejected by Lean and reverted, as documented. No self-host or metatheory tests.


## Compact checked-frame / real wide admission qualification (CI 38248015655)

[All-green native CI 38248015655](https://github.com/dwijayuda/pskernel/actions/runs/38248015655), source [0859097f](https://github.com/dwijayuda/pskernel/commit/0859097f6c1f8bdd6b869d477db829575bc2823c). Original PSKernel-Core was built unchanged in an independently staged Lean 4.34.0 source package on the same runner; the C0 source now stores only argument/fuel/recursion-depth in immutable checked application frames, with full checker context shared. Regression directly compares against the original recursive **C0 inference worker** for wide source terms, exact errors and resource bounds.

| Three matched complete checker rounds, milliseconds | C0 production | Unchanged original |
| --- | --- | --- |
| 32 fully checked admitted definitions applying 192-argument function | **32 / 32 / 32** | **130 / 131 / 132** |
| 12 fully checked 192-argument function calls | **11 / 11 / 11** | **48 / 47 / 48** |
| 48 infer-only 192-argument calls | **10 / 11 / 11** | **189 / 188 / 189** |
| 160 varied fully checked 48-argument applications | 69 / 70 / 70 | 67 / 68 / 68 |
| 160 growing depth-16 checked declarations | 40 / 40 / 40 | 40 / 41 / 41 |
| 64 growing depth-48 checked declarations | 64 / 64 / 64 | 64 / 64 / 64 |

Within C0 itself, full 60-call typed 192-argument check: explicit recursive oracle **230 ms** versus framed route **44 ms**. The library fixture includes environment extension and completed declaration admission, not only a subroutine. These one-run three-round observations establish about **4.1× speedup on that specific engineered library**, not arbitrary library/whole kernel speedup. The source does **not** separately ablate compact frame context versus the earlier full-context frames; crediting frame compaction for the entire gain would be incorrect. Entire benchmark-process peak VmHWM **862312 kB C0** vs **857292 kB original**; no attributable memory saving. Preserve slightly slower short checked cases. Full Init/Std/Mathlib checking and p95/memory distribution unqualified. Do not run excluded bootstrap/self-hosting or metatheory gates.


## Fuel-indexed checked Pi-suffix recursion in production — native CI 38252783408

Source [5c8a1e83](https://github.com/dwijayuda/pskernel/commit/5c8a1e83e22debd4fd6c365ba9666e834e8c5d66) on existing perf branch; [CI 38252783408](https://github.com/dwijayuda/pskernel/actions/runs/38252783408), successful full C0 Lean 4.34 native build, negative/differential, native full-operation microbench and matched unchanged original-core benchmark. Root checked applications of 16 or more args now use the structurally fuel-indexed metadata-carrying recursive worker, without allocating explicit frames. Original checked inference remains for narrower/non-app roots. Prior frame runner remains executable as a separate diagnostic; it is not the production default.

| Whole accepting checker (three rounds, ms) | C0 | Unchanged original |
| --- | --- | --- |
| 200 fully checked 16-arg applications | **18 / 17 / 17** | **20 / 20 / 20** |
| 200 fully checked 24-arg applications | **24 / 25 / 25** | **32 / 33 / 33** |
| 160 fully checked 32-arg applications | **25 / 25 / 25** | **36 / 37 / 37** |
| 160 varied fully checked 48-arg applications | **39 / 41 / 41** | **65 / 67 / 74** |
| 32 admitted wide 192-arg definitions | **31 / 32 / 32** | **123 / 124 / 124** |
| 64 safe admitted 16-arg definitions | **10 / 10 / 10** | **11 / 11 / 11** |
| 64 safe admitted 24-arg definitions | **13 / 12 / 12** | **16 / 15 / 15** |
| 64 safe admitted 32-arg definitions | **15 / 15 / 14** | **20 / 20 / 19** |
| 64 safe admitted 48-arg definitions | **20 / 19 / 20** | **31 / 31 / 31** |

Full benchmark-process high-water RSS: C0 **844628 kB**, original **843588 kB** (entire process, unrelated allocations not isolated). Ordinary short checked library and inductive cases remained near parity. These are repeated matched fixture rounds on **one** hosted runner, not independent-run medians, p95, realistic whole-library throughput or proof of memory improvement.

Same-run three-way candidate evaluation [CI 38251853231](https://github.com/dwijayuda/pskernel/actions/runs/38251853231):

| Full checked C0 operation | Old recursive | Frame route | Fuel-indexed metadata recursion |
| --- | ---: | ---: | ---: |
| 200 calls, 16 args | 23 ms | 24 ms | 19 ms |
| 200 calls, 24 args | 36 ms | 36 ms | 26 ms |
| 200 calls, 32 args | 52 ms | 34 ms | 33 ms |
| 200 calls, 48 args | 91 ms | 49 ms | 48 ms |
| 60 calls, 64 args | 42 ms | 20 ms | 18 ms |
| 60 calls, 192 args | 270 ms | 55 ms | 53 ms |

This justifies replacing frame storage on the measured checked families without changing acceptance semantics. The measured gain is for the **combined source metadata and routing**, not for pointer-based term arena conversion. Negative checks include exact error precedence for malformed heads/args, fuel/context limits, source Pi loose-range oracle and full public-vs-original acceptance around threshold boundaries. The indexed DAG remains non-accepting and the general software/kernel performance redesign is **not complete**.


## Nested fully checked expression routing and application-argument admission

Both new native workflows passed: [CI 38264313583](https://github.com/dwijayuda/pskernel/actions/runs/38264313583), source [10974c2d](https://github.com/dwijayuda/pskernel/commit/10974c2d0cc31c8a79ec5bd93de9e91e14f1ed12), and [CI 38265144787](https://github.com/dwijayuda/pskernel/actions/runs/38265144787), source [7d2c6708](https://github.com/dwijayuda/pskernel/commit/7d2c6708982fa1c1629976d7d6272c5cc78cfe15). Entire native Lean 4.34 source build, negative/exact fuel/error/differential suite, C0 microbenchmarks and unchanged original-core matched full checker passed. The new optional checked-app callback in the **same inference core** accelerates nested lambda/let/Pi/metadata checking; default hook-free inference remains the independent oracle. Further recursive routing covers wide checked applications used as arguments, with the original budget preserved.

| Matched complete checked admission, 3 rounds (ms) | C0 | Unchanged original |
| --- | --- | --- |
| 64 checked metadata-wrapped 48-arg definitions (CI 38264313583) | **15/14/16** | **23/22/26** |
| 64 checked lambda-wrapped 48-arg definitions (CI 38264313583) | **17/17/17** | **24/24/26** |
| 48 checked definitions: one inner 24-arg app used as outer 48-arg argument (CI 38265144787) | **51/51/50** | **63/62/62** |
| 32 wide 192-arg definitions (CI 38265144787) | **40/40/40** | **156/152/157** |
| 64 medium 48-arg definitions (CI 38265144787) | **25/25/25** | **39/38/39** |

These are **same-run constructed workload families**, not proof of arbitrary module checking superiority. The inner-app new branch was **not separately ablated** against earlier C0 and its specific causal improvement cannot be claimed from C0-original comparison alone. RSS C0 883760 kB / original 877660 kB in CI 38265144787, process-wide benchmark peaks only; no memory improvement. Short/deep/inductive checked workloads remain near parity. No kernel correctness criteria were relaxed, no self-host or metatheory jobs were run.


## Dependent Pi suffix re-analysis (successful native CI 38267860486)

The source [b5e0472b](https://github.com/dwijayuda/pskernel/commit/b5e0472b1ec4cd6f62229a239f30179f576317f7) promotes exact, bounded suffix reanalysis after checked dependent substitution, after [three-way candidate CI 38267242015](https://github.com/dwijayuda/pskernel/actions/runs/38267242015). Native [production CI 38267860486](https://github.com/dwijayuda/pskernel/actions/runs/38267860486) **success** with full C0 Lean 4.34 build, negative/differential, native microbenchmarks and unchanged original-core checker. The prior accepting invalidation-only mode stays callable. The new source metadata may be reused only after an exact dependent substitution has yielded a new immutable Pi type with >=12 syntactic binders remaining, and only if bounded analysis succeeds. No environment-dependent conversion result is cached and no acceptance criterion changes.

| Same-run three rounds, complete public checked workload (ms) | Native C0 | Unchanged original core |
| --- | --- | --- |
| 80 fully checked dependent Pi applications, 64 independent trailing binders | **30 / 31 / 32** | **52 / 52 / 51** |
| 48 sequentially admitted safe dependent Pi definitions, tail64 | **23 / 23 / 23** | **37 / 37 / 36** |
| 160 varied fully checked 48-argument applications | 40 / 39 / 39 | 62 / 62 / 63 |
| 160 ordinary checked library declarations | 36 / 38 / 37 | 39 / 37 / 35 |
| 64 deep checked library declarations | 60 / 59 / 60 | 59 / 57 / 57 |
| Ordinary inductive admission | 35 / 33 / 33 | 35 / 33 / 35 |

| Full checked operation in one C0 process | Prior C0 invalidation-only | New C0 bounded rebuild |
| --- | ---: | ---: |
| 80 calls, dependent first binder then 24 independent Pi binders | 16 ms | 13 ms |
| 80 calls, dependent first binder then 64 independent Pi binders | 51 ms | 26 ms |
| 30 calls, dependent first binder then 192 independent Pi binders | 114 ms | 27 ms |

Internal full-operation pairs isolate a source-family benefit (about 2× at tail64 and 4.2× at tail192 on these tests), **not** complete library/whole-kernel performance. Three repeated original-vs-C0 public checks in one CI workflow are not independent runner replicates. C0/unchanged original full benchmark process peak VmHWM **1,031,668/1,034,684 kB**; no reliable per-operation memory reduction, p95 or general library improvement established. Prior shorter/ordinary checking negative findings stay recorded; no self-host or metatheory gates.


## Binder DefEq stack and range redesign — completed native CI 38270573104

Files: `Core/Expr.lean` (`psKernelC0BinderBodyRangesWithFuel`, `psKernelC0HasBinderPrefix`), `Checker/DefEq/BinderSpines.lean` (both lambda and forall workers), `test/C0ProofIrrelevanceRegression.lean` (independent range and outer-dependent-substitution oracles) and `test/C0CheckerComparison.lean` (matched full public DefEq operations). See [source 3b082900](https://github.com/dwijayuda/pskernel/commit/3b082900184d47109895c4e4e78eae1f6fce8ce8), [tests b6205d34](https://github.com/dwijayuda/pskernel/commit/b6205d34b6d4b3f44477d0bae725a1a424db1296), [dependent cases 4007d03c](https://github.com/dwijayuda/pskernel/commit/4007d03ce4a63e9ea10d51c9052fc95a348beb72). [Native CI 38270573104](https://github.com/dwijayuda/pskernel/actions/runs/38270573104) **success** for pinned Lean 4.34 full build, negative/differential suite, microbenchmarks and same-run unmodified original-core matched checking.

| Matched three full-checker rounds (ms) | C0 forall | Original forall | C0 lambda | Original lambda | Calls / round |
| --- | --- | --- | --- | --- | --- |
| Depth 16 | 1/1/1 | 3/2/2 | 1/1/1 | 2/2/2 | 12 |
| Depth 64 | **4/3/3** | **22/22/22** | **3/3/3** | **22/22/22** | 12 |
| Depth 128 | **5/6/6** | **82/81/81** | **5/6/6** | **81/81/80** | 12 |
| Depth 256 | **6/6/5** | **158/156/156** | **6/5/5** | **157/155/155** | 6 |

The whole-expression terms differ by transparent terminal metadata, ensuring DefEq is actually invoked and binder recursion is exercised instead of trivial syntactic equality. The test also checks an outer-binder-referencing inner dependent domain (de Bruijn index 1), whose exact metadata-wrapped equivalent is accepted by both original and C0 on all rounds. This is **strong binder-family evidence**, not whole-kernel performance superiority; ordinary checked chains and inductives remain near parity, and C0/original high-water process RSS **1,064,112 / 1,060,948 kB** is not a per-check memory measure. No selfhost/bootstrap/fixed-point/metatheory tests.


## Spine-only DefEq fuel bounds: same-run complete checker qualification

[Native CI 38278625946](https://github.com/dwijayuda/pskernel/actions/runs/38278625946) **all stages passed**, source [10e7066a](https://github.com/dwijayuda/pskernel/commit/10e7066a9f276ddad8ada147a54d06cd5e9cf737), expanded matching tests [1e4100a1](https://github.com/dwijayuda/pskernel/commit/1e4100a1eca4e526dc96b59b100ed8853350802b) corrected [634e1076](https://github.com/dwijayuda/pskernel/commit/634e10762df6411373b3084c4aebf07db1854e50). Deep binder and application workers are fuel-indexed by *the shape actually visited*, not the full AST node count of binder domains, terminal bodies or arguments. No new accepted judgments or environment-sensitive cache is introduced. The regression directly compares sufficiently high old whole-tree and new spine-only worker budgets before allowing the faster route.

| Whole public DefEq on a one-binder term with a large wrapped domain (ms) | C0, 3 rounds | Unchanged original, 3 rounds | Calls/round |
| --- | --- | --- | --- |
| Domain depth64 | **1 / 1 / 1** | **2 / 2 / 2** | 20 |
| Domain depth256 | **2 / 3 / 3** | **6 / 6 / 6** | 20 |
| Domain depth512 | **2 / 2 / 2** | **4 / 5 / 4** | 8 |

The already-qualified full DefEq depth256 *multi*-binder fixture stays at C0 forall **6/5/5** ms vs unchanged original **162/162/162**, lambda **5/5/6** ms vs original **162/162/163** over six calls. Ordinary short/deep library and inductive admission remained near parity. Full benchmark VmHWM was C0 **1,092,300 kB** / unchanged original **1,087,788 kB**, not evidence of a memory reduction. All figures are on a single hosted runner with three within-run rounds, not statistical p95 or full-library throughput. Do not extrapolate to arbitrary proof developments.


## Native source zeta suffix qualification — CI 38280619138

[Latest native CI 38280619138](https://github.com/dwijayuda/pskernel/actions/runs/38280619138) **passed** after [source 33748911](https://github.com/dwijayuda/pskernel/commit/33748911328f92207b8db5869c6061955b2e9d67), [range test 47f59c31](https://github.com/dwijayuda/pskernel/commit/47f59c317d6b7d97115fe6ea0d66c6b91ff19f30), [matched source 5c0db911](https://github.com/dwijayuda/pskernel/commit/5c0db9118d607ed8874973f86df473182671cc07) and [dependent 2e7df3b4](https://github.com/dwijayuda/pskernel/commit/2e7df3b4d76a62ef617d9f653eef24c01aca091f). Public WHNF and accepted checked declarations exercised the *identical prepared source* in a separately rebuilt unchanged original C0 package and current C0 source, three rounds on one runner.

| Complete native operation | C0, three rounds (ms) | Unchanged original, three rounds (ms) |
| --- | --- | --- |
| 60 public WHNF calls on 24-let spine | **54 / 51 / 53** | **62 / 63 / 64** |
| 60 public WHNF calls on 96-let spine | **632 / 605 / 625** | **709 / 717 / 728** |
| 24 public WHNF calls on 192-let spine | **970 / 937 / 956** | **1072 / 1076 / 1092** |
| 40 sequentially admitted checked depth64 let definitions | **254 / 247 / 252** | **255 / 255 / 262** |

These show only **modest** 10–20% C0-over-original WHNF gains on closed zeta workloads and near parity on checked admission. Other preexisting C0 improvements contribute to these differences; no isolated incremental zeta optimization effect is proven. Process-wide high-water memory **1,149,436 kB C0 / 1,149,176 kB original**, not a memory gain. The exact range metadata is read-only and validated against independent de Bruijn predicates; genuine outer-let-dependent examples must and do use original substitution. Full indexed accepting WHNF/DefEq/inference/admission, realistic whole-library throughput, p95, allocation/resource use and independent multi-run variability remain unqualified. No selfhost/bootstrap/fixed-point/metatheory tests.


## Checked let admission accelerated by shared source fingerprints — CI 38284834874

[Full native CI 38284834874](https://github.com/dwijayuda/pskernel/actions/runs/38284834874) succeeded for [source a90b22ed](https://github.com/dwijayuda/pskernel/commit/a90b22ed59e9a61eaf344ddf058c3b73a17d289f) and [negative/performance tests b951023d](https://github.com/dwijayuda/pskernel/commit/b951023d4f8c37bb7396c5f814b93fa9673dfa29). Same-run C0 checker internal oracle (complete checked operations): 60 depth16 calls historical 30ms / optimized 20ms; 60 depth64 historical 265ms / optimized 62ms; 20 depth128 historical 318ms / optimized 40ms. Complete accepted declaration admission, 40 sequential checked definitions of closed depth64 let expressions, 3 rounds: C0 **45/44/45 ms** vs unchanged original **184/187/185 ms**. Source-only runner [38284714639](https://github.com/dwijayuda/pskernel/actions/runs/38284714639) independently reproduced C0 50/50/51 vs original 203/206/210. Other ordinary/deep checked chains and inductive admissions around parity. C0/original peak VmHWM 1,154,848/1,153,080 kB: no memory winner. All tests pinned native Lean 4.34, no self-host or metatheory. Avoid general whole-kernel speed claims.


## Checked binder inference using shared exact source ranges — CI 38285916402

[Source 4e07bde0](https://github.com/dwijayuda/pskernel/commit/4e07bde098f4a9b58fdc36080b6c17feaf6bc160) and [tests 21bf7176](https://github.com/dwijayuda/pskernel/commit/21bf71762a08801267c5ea6ccccac19b2b91531e) passed complete [CI 38285916402](https://github.com/dwijayuda/pskernel/actions/runs/38285916402). Native C0 old-vs-new *complete checked lambda* inference: depth16 36 calls 5ms/5ms, depth64 36 calls 56ms/48ms, depth128 12 calls 70ms/59ms. Matched original standalone admission (three rounds): 24 checked definitions with depth32 lambdas C0 **15/15/14ms** vs unchanged original **16/16/17ms**; depth64 C0 **43/42/41** vs original **51/50/51ms**. Source-only build/negative fuel/error and fresh-name differential, native microbenchmarks and all original checker benchmarks passed. 40 checked depth64 let definitions in the same run C0 **33/33/33ms** vs original **143/150/147ms**. Other ordinary/deep declaration and inductive admission remained near parity. Process-wide VmHWM C0 1,169,940kB vs original 1,157,732kB, not a memory gain. The binder-family benefit is modest and does not imply general library speed. No self-host/metatheory gates.
