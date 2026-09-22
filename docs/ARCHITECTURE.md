
## Kernel cache identity

Kernel memoization is keyed by immutable expression-object identity through compact IDs allocated by `KernelState`, not by recursively serialized AST strings. Identity-keyed memoization is semantics-preserving: a missed identity hit can only lose an optimization, while a hit always refers to the exact immutable expression previously checked. Definitional-equality success/failure caches remain symmetric **pair-local** sets over compact expression IDs and are never transitively closed.

This design mirrors the object/hash-oriented shape of Lean's kernel more closely and avoids quadratic string allocation on large export replays. It also keeps the inference-check cache split (`infer` vs checked inference) explicit so a prior infer-only result cannot bypass checking-side obligations.

## Export replay index tables

Lean4export 3.1.0 assigns interned Name, Level, and Expr indices densely in emission order. The replay boundary stores these indices in dense arrays rather than `Map<number, ...>` tables. This both reduces large-corpus memory overhead and fails closed on sparse/out-of-order indices, preventing an untrusted export stream from creating an oversized sparse index space. This optimization is importer-only; kernel expression semantics and environment lookup are unchanged.
