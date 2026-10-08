# PSC0 — preserved first PSC2 compiler-only self-host fixed point

This is the 2026-10-03 compiler-only bootstrap snapshot, copied from
`psc2/selfhost-lean-kernel` at GitHub commit
`d4298a712d1e2ea6505185d311e9af10a698b2ca`.

The first fixed-point record is in
`docs/continuity/COMPILER_FIXED_POINT_2026-10-03.md`.
The self-host source entry remains
`packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean`, and its 55-module
bootstrap closure remains within the 12 package groups listed in
`scripts/bootstrap-closure-contract.mjs`.

## Active self-host layout

- `packages/`: the 12 portable bootstrap packages, the host-side CLI,
  and the Lean 4.34 native/WASM kernel-provider integrations (NOT part of
  the portable source closure).
- `host/`, `lean-checked/`: Lean-powered bootstrap and checked-host tooling.
- `scripts/`, `test/`: bootstrap, checked-generation, fixed-point and
  compiler-regression tooling.
- `stdlib/`: supporting portable standard-library and prelude material.
- `legacy/`: exact historical optional backend/project/kernel trees,
  associated research receipts, experiments and extension tests.

The native Lean provider source remains in `packages/pskernel-lean/`
because the `lean-checked/` seed imports its admission implementation.
The WASM provider remains the default host-side checked provider.

`legacy/packages/project` is retained as a *regression-only* Lake
module import for `test/BootstrapTests.lean`. It is not imported by the
compiler fixed-point root. The experimental owned-kernel provider is
optional and is loaded through the host-side adapter when explicitly
selected; it is not a bootstrap source dependency.

## Important limits

The original October 3 compiler fixed point was measured on the original
historical tree. This reorganization does not constitute a new fixed-point
run, and it does not certify any owned-kernel or joint compiler/kernel
self-hosting. Archive sources and receipts are preserved, not silently
treated as current implementation or verification results.

When working inside this directory, use its own toolchain/commands and
consult `legacy/README.md` before attempting historical extension tests.
