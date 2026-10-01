
## Kernel cache equality

Lean 4.34's `expr_map` keys memo tables by kernel structural expression equality, not by object identity. `KernelState` therefore uses cached structural hashes with `exprLeanEq` collision checks. A `WeakMap` identity lookup remains only as a fast path; structurally equal cloned expressions must share memo entries exactly as they do in Lean.

Definitional-equality success/failure caches are symmetric **pair-local** sets over structural expression pairs and are never transitively closed. The inference-check cache split (`infer` vs checked inference) remains explicit so a prior infer-only result cannot bypass checking-side obligations. This avoids recursively serialized AST keys while preserving the equality semantics of final Lean 4.34.

## Export replay index tables

Lean4export 3.1.0 assigns interned Name, Level, and Expr indices densely in emission order. The replay boundary stores these indices in dense arrays rather than `Map<number, ...>` tables. This both reduces large-corpus memory overhead and fails closed on sparse/out-of-order indices, preventing an untrusted export stream from creating an oversized sparse index space. This optimization is importer-only; kernel expression semantics and environment lookup are unchanged.
