# PSC0 compiler and self-host implementation

Initial F application: [`9ee0b1fd38dd1456a187d4675f9027440a989f2d`](https://github.com/dwijayuda/pskernel/commit/9ee0b1fd38dd1456a187d4675f9027440a989f2d). This is the initial attempt identity; any qualifying revision and its evidence are recorded separately below.

This directory began as the preserved 2026-10-03 compiler-only bootstrap snapshot, copied from
`psc2/selfhost-lean-kernel` at GitHub commit
`d4298a712d1e2ea6505185d311e9af10a698b2ca`.

The first fixed-point record is in
`docs/continuity/COMPILER_FIXED_POINT_2026-10-03.md`.
The self-host source entry remains
`packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean`. The preserved October 3
closure contained 55 modules in 12 package groups; later qualified checkpoints
record their own exact closure manifests rather than changing that historical
receipt.

## Current compiler authoring and `.ps` grammar

The current compiler uses the bounded PSC authoring capabilities described in
[the current authoring guide](docs/selfhost-language/CURRENT.md). Handwritten
`.lean` remains authoritative. The qualified, cold-recovered R compiler is the
explicitly selected authoring seed, recorded by [selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6).
Current compiler emission and selected-R cache-miss recovery use TypeScript
7.0.2. TypeScript 5.8.3 remains in archived S0/A producer metadata and recipes;
current tooling does not execute those recovery paths.

This branch installs the **new-only `ps-0.9-r3` bounded self-host subset** for
current `.ps` input and canonical output. Source
`fe2560aba0f347b1caf8d000d371464642d44f23` passed full compiler qualification and
independent provider acceptance in
[run 37925722635](https://github.com/dwijayuda/pskernel/actions/runs/37925722635).
[Cold successor recovery](docs/selfhost-language/grammar-migration-cold-recovery.json)
is verified, with receipt SHA-256 `2aa93517b848da1493386ab9be50527275fe1a7a1c7e12f422d8d8431d8d9f1d`, and R is explicitly
selected. The lexer, parser, printer, active fixtures and source provenance
migrate together. F at `fcd875c8f38db4b0524090bd10c7c2fd5024053d` separately completed the
chosen practical-v1 source migration and its compiler/provider qualification in
[F run 37947341800](https://github.com/dwijayuda/pskernel/actions/runs/37947341800). R remains the selected authoring seed.
[PS_GRAMMAR_ADOPTION.md](docs/selfhost-language/PS_GRAMMAR_ADOPTION.md) records the
pinned reference, enabled forms, explicit exclusions and qualification gates.
Current `.ps` does not have a legacy grammar mode. Immutable historical source
and artifacts keep their original recovery rules.

The edition change does not activate full Standard/PSCV or strict SH/1 or migrate
the Lean 4.34 provider. Seed selection has separate authenticated recovery and
provider evidence requirements. Completed results and pending work are recorded in
[IMPLEMENTATION.md](docs/selfhost-language/IMPLEMENTATION.md).

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
