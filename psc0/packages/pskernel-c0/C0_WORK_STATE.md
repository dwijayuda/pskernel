# PSKernel-C0 — performance architecture work state

## Branch and isolation

- Source: `psc0/pscv0-v7-native-lean-v1` at `a8fbc17f1ad2d24efbde14a7cbe993a4400d4c01`.
- Development: `perf/pskernel-c0-v7-rust-20261012`.
- Original `psc0/packages/pskernel-core` and working PSC0 Rust backend are not changed.
- C0 Lean source remains in `src/`. The independent Rust experiment lives in `experimental/arena-engine/` and does not issue kernel acceptance verdicts.

## Implemented architecture

- Expression/universe/name hash-consing and compact 32-bit arena-local term references.
- Exact hierarchical names (`anonymous`, string, arbitrary-size numeric components) rather than ambiguous dotted strings.
- Cached expression-tree depth metadata for O(1) shallow/deep algorithm dispatch.
- Iterative, DAG-memoized de Bruijn substitution for deep inputs, with recursive reference implementation used for bounded shallow terms and differential tests.
- Iterative application-spine beta/zeta/metadata WHNF for a restricted context-free fragment.
- WHNF cache storing both results and exact node-visit costs, preserving fuel exhaustion when a cached result would require more work.
- Positive-only `Equal/Unknown` conversion precheck, not a full definitional-equality checker.
- Dedicated GitHub Actions unit tests, Clippy, release build and microbenchmarks.

## Actual evidence (October 12, 2026 Jakarta time)

[GitHub Actions 38180969202](https://github.com/dwijayuda/pskernel/actions/runs/38180969202) at `cf0ef867c008b0920444f70369a988552f937549`:
- 21 unit tests passed; Clippy, release build and microbenchmark smoke passed.
- Application spine depth 1,024, 1,000 repetitions: 2.169 ms total.
- WHNF on the *same* 1,024-application stuck term, 1,000 repetitions: uncached 32.905 ms; repeated cached 0.014668 ms.
- 128-node substitution, 300 repetitions: recursive 4.824 ms, hybrid 4.623 ms.
- Rust CI runner uses rustc 1.99.0; numbers are single-run microbenchmarks with shared runner variability, not reproducible production throughput claims.
- Prior run [38180720840](https://github.com/dwijayuda/pskernel/actions/runs/38180720840) showed the fully iterative substitution was *slower* than recursive on a shallow case (6.649 vs 4.861 ms); hybrid dispatch exists because of this evidence.

## Serious remaining limitations

The Rust engine is **NOT** a complete Lean kernel. It does not implement full Lean-compatible universe comparison, delta/iota/native/quotient/recursor reductions, complete WHNF/DefEq, inference, or declaration admission. No lossless Lean-AST bridge or Arena differential qualification exists. Its 32-bit handles are only safe within their owning arena, and the source-facing API must enforce that boundary before integration. The precise semantic equivalence of the fragment has tests, not a whole-language proof. No baseline comparison to the current original PSKernel-Core on real workloads has been performed.

## Next milestone order

1. Implement an explicit, lossless or fail-closed Lean AST/level/name bridge with hierarchical names, arbitrary-size naturals, validated arena provenance and round-trip tests.
2. Build a real checker-facing API with immutable declaration environments, context-specific caches, and safe resource accounting.
3. Implement complete native kernel WHNF and conversion family by family, each with positive/negative differential tests and real library exports.
4. Implement inference and admission, then qualify end-to-end with Lean 4.35 and current PSKernel-Core.
5. Compare cold/warm time, allocated bytes, peak memory and throughput on identical hardware before deciding whether to switch PSC0 consumers.

The metatheory and consistency-proof program is deferred. False acceptance is not an acceptable performance optimization.
