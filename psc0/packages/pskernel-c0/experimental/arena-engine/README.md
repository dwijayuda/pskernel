# C0 indexed execution engine — experimental

This is an initial **architectural implementation**, not a drop-in replacement for the Lean-compatible kernel.

## Implemented
- Independent term/universe/name tables, u32 handles, structural hash-consing.
- Equality of interned IDs in constant time, scoped to a single arena.
- Zero-allocation application-spine traversal.
- Capture-avoiding de Bruijn instantiate1 and lifting; memoized per traversal.
- Fragment-only beta, zeta, and metadata WHNF with explicit fuel; unit tests.

## Not implemented / safety boundaries
- Lean's full definitional equality, delta/primitive/recursor/quotient reductions, environment and universe operations, and checked admission.
- Lossless decoding of full Lean hierarchical names, native primitive literals and all source constructs.
- Integrated PSC0 build or performance benchmarking.
- Separate arena generations or cross-arena handle safety; IDs must never leave their arena.
- Formal refinement, executable semantic-equivalence evidence, and full negative conformance qualification.

This implementation must **not** issue kernel acceptance verdicts. The original C0 Lean checker remains authoritative until full differential qualification.

## Validation

Run `cargo test --manifest-path psc0/packages/pskernel-c0/experimental/arena-engine/Cargo.toml` on a Rust-enabled environment. These tests were written but not executed here because Rust tooling is unavailable in this environment.

## Follow-up
Integrate an arena-bound typed representation bridge, implement iterative WHNF with proper fuel propagation, make term storage generation-aware, and benchmark cold/warm throughput and memory against the original kernel. Do not merge this execution engine into the accepting path before the semantic gaps close.
