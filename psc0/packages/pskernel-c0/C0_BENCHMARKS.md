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
