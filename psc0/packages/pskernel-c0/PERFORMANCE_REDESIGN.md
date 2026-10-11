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
