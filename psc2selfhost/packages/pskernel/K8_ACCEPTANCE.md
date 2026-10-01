# K8 bounded semantic acceptance baseline

This document closes the **bounded semantic acceptance baseline** for the
Lean-authored PSC1 reference kernel on `kernel/psc1-lean-reference`.

It is deliberately narrower than a claim of full Lean 4.34 equivalence.
The semantic authority remains final Lean 4.34.0 behavior and the pinned source
under `study/lean4-4.34.0/`.

## Acceptance matrix

The mandatory CI workflow `.github/workflows/psc1-lean-kernel.yml` must keep
the following layers green:

| Layer | Evidence |
| --- | --- |
| Source/kernel build | `lake build` under Lean 4.34 |
| Foundational differential oracle | `PSC1Kernel/Test/Oracle.lean` against the real Lean 4.34 kernel |
| Live producer/consumer boundary | pinned `MiniExport.lean` stream replayed by `PSC1Kernel/Test/ReplayFile.lean` |
| Canonical bootstrap corpus | `lean434-init-prelude.ndjson` |
| Primitive closure | `lean434-primitive-closure.ndjson` |
| ProofScript deltas | `lean434-proofscript-text-foundation.ndjson`, `lean434-proofscript-selfhost-foundation.ndjson` |
| Bounded Std corpora | SAT/CNF, Parsec, ByteSlice |
| Bounded Lean corpora | RBMap, PersistentArray, PersistentHashMap |
| Adversarial replay boundary | duplicate JSON keys, ambiguous record kinds, sparse/out-of-order IDs, malformed metadata |
| Direct semantic hardening | structure projection soundness, Quot collisions, duplicate mutual names, Prop-elimination/projection restrictions, reserved nested names, deterministic recursion-depth parity |

The checked-in bounded corpus fixtures are:

- `oracle/fixtures/lean434-std-sat-cnf-roots.ndjson`
- `oracle/fixtures/lean434-std-parsec-roots.ndjson`
- `oracle/fixtures/lean434-std-byteslice-roots.ndjson`
- `oracle/fixtures/lean434-lean-rbmap-roots.ndjson`
- `oracle/fixtures/lean434-lean-persistentarray-roots.ndjson`
- `oracle/fixtures/lean434-lean-persistenthashmap-roots.ndjson`

These fixtures are evidence of representative real-library behavior, not
exhaustive replay of all `Std` or all `Lean.*`.

## Resource and cancellation boundary

Final Lean 4.34 installs resource controls at the host entry point:
`lean_add_decl` wraps declaration checking with `scope_max_heartbeat`,
`scope_max_rec_depth`, and `scope_cancel_tk`. The runtime
`check_system` path performs heartbeat, cancellation, stack, and memory
checks.

PSC1Kernel directly models the deterministic kernel recursion-depth rule,
including Lean 4.34's 16x kernel multiplier, because that limit is cheap,
deterministic, and already differential-tested.

Exact cumulative heartbeat accounting, cancellation-token transport, native
stack checks, and process-memory checks remain **host/runtime policy**, not
trusted term or declaration semantics. The regression matrix must therefore
continue to classify:

- `kernelInterrupt.lean` as `operational-resource`
- `kernel_maxheartbeats.lean` as `operational-resource`

A later JS/WASM host may reproduce those operational controls around the
compiled kernel without changing the semantic checker.

## What K8 closure means

K8 is closed only as a **bounded semantic baseline**. It means the canonical
bootstrap replay, representative Std/Lean bounded corpora, direct adversarial
hardening, fail-closed replay validation, and documented unsupported
operational boundaries are all reproducible.

It does **not** establish:

- full `Std` environment replay,
- full `Lean` environment replay,
- complete compiler-IR/native-reduction parity,
- formal equivalence with Lean 4.34,
- permission to claim full Lean compatibility.

Those remain separate assurance gates while K9/K10 exercise compilation and
self-host parity against this same acceptance matrix.
