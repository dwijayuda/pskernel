# PSKernel-C0 performance architecture (implementation checkpoint)

Source: active PSC0 v7 Rust backend branch. C0 retains an untouched copy of the original Lean checker.

## Measurement and architecture findings

The copied Lean kernel represents expressions as recursive `PsKernelExpr` values. Substitution recursively rebuilds changed branches; expression caches compute hashes by recurring over entire terms and use a custom binary-bucket index. These patterns motivate a data-oriented arena design, but profiling is needed to establish their actual costs.

## First implemented experiment

`experimental/arena-engine` contains a Rust compact-term store, structural interning and a restricted evaluation engine, independently namespaced from the Lean checker. This is a proof of implementation direction, not a validated faster kernel.

## Integration gates

1. Develop lossless AST encode/decode including hierarchical names, universe levels and arbitrary-precision literals.
2. Establish differential equivalence of beta/zeta with source Lean checker and fix resource accounting.
3. Complete WHNF, DefEq and inference with Lean-compatible reduction order and resource policy.
4. Establish declaration admission and environment isolation; only then switch the checker path.
5. Benchmark large real workloads; adopt only if measured speed and semantic qualification justify it.

Metatheory is deferred; semantic correctness and no false acceptance remain mandatory.

## Lean-native acceleration stage (active)

The earlier Rust crate remains a separate experiment. The primary implementation now modifies `src/Ps/KernelCore/**.lean` directly: shared four-level radix indexes for term/declaration/local-context storage; beta/zeta-specific one-variable substitution; direct structural lifting; Unicode hashing over scalar values; and optimized expression equality dispatch. The trusted public checker continues to operate on its original expression API while these hot paths are replaced incrementally.

**Performance selection rule:** retain an optimization only with executable semantic equivalence and repeated workload measurements; e.g., the first paired-expression-equality implementation was slower on a deep case, so C0 changed to a hybrid instead of claiming improvement.

The next architectural milestone is to make indexed expression storage an internal representation for inference, WHNF and conversion with explicit lossless conversion at the public boundary. That is **not yet implemented**. The original package and PSC0 Rust backend remain unchanged. Self-hosting tests and metatheory are not part of this performance iteration.


## Current native Lean execution redesign

The primary performance work now lives in `src/Ps/KernelCore/`, with a two-tier architecture:

1. **Accepted recursive-expression core:** demand-driven WHNF application spines, specialized one-binder beta substitution, indexed local/global caches and the original checker semantics. No acceptance rules were relaxed.
2. **Experimental internal indexed engine:** exact expression bridge, collision-checked interned nodes with cached hashes/depth, memoized capture-avoiding indexed rewrites and context-free indexed WHNF. Its term handles cannot cross store boundaries and do not by themselves imply definitional equality.

The indexed engine is deliberately not integrated into the accepting DefEq/inference path: it does not yet implement environment-specific reductions and full resource classification. Native Lean benchmarks show compelling speedups on shared-DAG and stuck-head microcases, but end-to-end checker speedups are not established.

Next architectural work is to retain a canonical indexed arena across a *whole checking session* rather than converting expressions independently for each operation. An immutable public-to-internal bridge, explicit environment identity, and cache provenance must precede any trusted use.



## Checked-path substitution family correction — 2026-10-12

A three-way **full checked-application** same-run comparison was used rather than relying on isolated helper timings. The benchmark built unchanged PSKernel-Core, C0, and a diagnostic private C0 copy restoring the original single-variable instantiation. Before correction, the original helper in C0 erased a reproducible full checked-path slowdown, establishing root cause. See `C0_BENCHMARKS.md`, [CI 38222241004](https://github.com/dwijayuda/pskernel/actions/runs/38222241004).

The adopted Lean design recognizes **two substitution workload families** without changing semantics:

- For *binder-rooted* lambda, forall and let terms, perform a fast loose-variable existence probe. If there are no loose variables, preserve the original immutable term. Otherwise invoke the specialized capture-avoiding changed-flag worker.
- For application-rooted and other non-binder terms, use the specialized one-pass worker directly to avoid repeating a whole-expression prepass on beta-heavy workloads.

A matched native original-core comparison and negative/differential regressions validated the correction in [CI 38222841665](https://github.com/dwijayuda/pskernel/actions/runs/38222841665): checked C0 39/40/39 ms vs original 38/39/39 ms across three rounds of 80 typed 48-argument applications; infer-only C0 19 ms vs original ~81–82 ms across three rounds of 200. This **does not** complete the indexed acceptance architecture or prove an overall kernel speedup. The opt-in indexed session remains non-authoritative and slower on repeated small WHNF workloads. Research and integration must continue with measured complete checking and context/fuel-safe indexed reduction.


## Verified production wide-application checking path

Source commit [23e088a6](https://github.com/dwijayuda/pskernel/commit/23e088a645599ab4930a6ae42c491c842e101c00) changes only `psc0/packages/pskernel-c0`: wide (at least 64 arguments) fully checked **root applications** now traverse explicit frames with original fuel/recursion contexts, source-side bounded exact Pi-body loose-variable ranges and historical checked inference/DefEq/substitution fallbacks. CI [38246930574](https://github.com/dwijayuda/pskernel/actions/runs/38246930574) green; 12 typed 192-arg checked applications C0 9/7/7 ms vs unchanged original 33/34/34 ms. Other app shapes and smaller root expressions stay on original recursive checker. This is a measured *family-specific* complete-operation improvement, not complete indexed acceptance. No unsafe pointer equality; rejected `ptrEq` candidate reverted.

Next tasks: benchmark significant nontrivial source module/admission/recursor scenarios and memory, resolve slight regressions on 48-arg checked and checked depth48 declarations, expand the proven safe range metadata where profitable without rebuilding syntax/indexes, and progress to session-owned indexed evaluation only with exact environment/context/fuel/native/quotient/iota semantics and differential negative controls. No self-host, bootstrap, fixed point, generated Rust or metatheory tests now.
