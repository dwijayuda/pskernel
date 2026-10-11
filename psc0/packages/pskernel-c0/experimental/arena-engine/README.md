# PSKernel-C0 indexed execution engine (experimental)

This **independent Rust execution substrate** is not wired to the accepting PSKernel checker.

## Implemented

- Structural hash-consing for term, universe and exact hierarchical name nodes.
- Compact 32-bit arena-local IDs and zero-allocation spine traversal.
- Cached term depth; fast recursive substitution on shallow terms and iterative DAG-memoized substitution on deep terms.
- Iterative beta/zeta/metadata reduction for a restricted context-free WHNF fragment.
- Fuel-accounted WHNF result caching, including low-budget cache-hit regressions.
- Conservative `Equal/Unknown` conversion hint with no false-rejection result.
- Unit and differential tests plus a Rust release microbenchmark.

## Verified

[GitHub Actions 38180969202](https://github.com/dwijayuda/pskernel/actions/runs/38180969202) passed 21 unit tests, Clippy, release build and microbenchmark smoke. See [C0_BENCHMARKS.md](../../C0_BENCHMARKS.md) for exact numbers and caveats.

Commands from repository root:
```sh
cargo test --manifest-path psc0/packages/pskernel-c0/experimental/arena-engine/Cargo.toml
cargo clippy --manifest-path psc0/packages/pskernel-c0/experimental/arena-engine/Cargo.toml --all-targets -- -D warnings
cargo run --release --manifest-path psc0/packages/pskernel-c0/experimental/arena-engine/Cargo.toml --example microbench
```

## Critical boundaries

- No complete Lean-compatible WHNF, DefEq, typing, declaration admission, environment or universe semantics.
- No lossless source-term bridge, typed arena generation checks across sessions, full differential qualification, or comparison with production PSKernel-Core.
- C0's current cache is valid only for its *context-free experimental fragment*. Do not share it across different environments or reuse for unrestricted delta conversion.
- Every handle belongs to its creator arena; passing an ID between arenas is invalid.
- Full metatheory is deferred, but the engine must not issue kernel acceptance verdicts before compatibility validation.

Do not use this crate as a proof checker or production semantic oracle.
