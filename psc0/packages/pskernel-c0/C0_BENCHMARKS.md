# PSKernel-C0 experimental performance measurements

**Scope:** Indexed Rust term-substrate microbenchmarks only, **not** Lean kernel / PSC0 compiler checking and **not** an original PSKernel-Core comparison.

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
