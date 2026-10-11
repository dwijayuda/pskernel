# PSKernel-C0 — performance redesign state

- Base: `psc0/pscv0-v7-native-lean-v1` at `a8fbc17f1ad2d24efbde14a7cbe993a4400d4c01`.
- New experimental branch: `perf/pskernel-c0-v7-rust-20261012`.
- Original `psc0/packages/pskernel-core` and PSC0 Rust backend remain unchanged.

## Implemented, isolated Rust arena engine

`experimental/arena-engine` contains:
- Interned immutable expression, name and universe nodes, represented by compact 32-bit arena-local handles.
- Explicit-stack application-spine beta/zeta/metadata weak-head evaluator for a **restricted fragment**, with one global node-visit fuel bound and no recursion for following application heads.
- Capture-avoiding de Bruijn substitution with per-operation memoization.
- Structural interning tests, binder metadata test opportunities, reduction/resource regressions and a standalone microbenchmark.

The initial recursive head-WHNF implementation incorrectly refreshed its fuel for nested heads. It was replaced by the explicit stack design. No completed Rust toolchain execution or benchmark result has been confirmed in this chat.

## Critical unfinished work

The Rust engine is **not an accepting kernel**. It lacks the full Lean 4.35 reduction/conversion/type-inference rules, environment admission, lossless term bridge and differential validation. It has no claimed speedup against `pskernel-core`. Its IDs must remain arena-local; cross-arena identity would be unsound.

## Next implementation order

1. Execute `cargo test --manifest-path psc0/packages/pskernel-c0/experimental/arena-engine/Cargo.toml` and `cargo clippy`; address all failures. Run the microbenchmark.
2. Implement a lossless full-fidelity representation bridge and a separate structural round-trip suite.
3. Add a differential WHNF suite for the exact supported beta/zeta fragment, including huge/deep terms and malformed inputs.
4. Extend WHNF and DefEq in families (delta, recursors, quotient, primitives, universes), enforcing the original semantics, resource policy, and negative conformance.
5. Introduce checked declaration admission, then benchmark complete real workloads against the unchanged source kernel.
6. Switch any acceptance path only after semantic agreement and measured gains.

Metatheory/consistency proofs are deferred; preventing false acceptance is not.

## Latest checkpoint (2026-10-12)

- Added `ConversionHint` (`Equal`/`Unknown`) and `conversion_hint` over the experimental indexed WHNF fragment. This is positive-only: it is not a full defeq procedure, cannot issue negative decisions or certify a declaration, and is not integrated with PSKernel's accepting checker.
- Expanded CI to build and execute the release microbenchmark example, alongside tests and Clippy.
- Rust compilation, CI results, and absolute performance numbers have **not** been independently confirmed in this chat. No performance gain or Lean compatibility beyond the restricted fragment is claimed.
- Next: obtain verified green CI, compare results to the original Lean checker, implement a lossless expression/environment bridge and full conversion rules before touching acceptance.
