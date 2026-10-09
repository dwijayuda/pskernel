# PSC0 compiler and self-host implementation

## Installable platform preview

Preview1 is qualified on Linux and Windows x64 with Node22.23.3/npm10.9.9 and Node26.7.0/npm12.0.2. On Windows PowerShell, the tested command is `psc.cmd`. Download the new `proofscript-0.1.0-preview.1.tgz` from the [candidate artifact](https://github.com/dwijayuda/pskernel/actions/runs/37993872945/artifacts/11646426537); preview0 was Linux-only. The compiler bootstrap toolchain and selected seed are unchanged.

The protected `proofscript` npm preview exposes `psc check`, `psc build`,
version information and extension disclosure. Its public launcher is
`bin/psc.mjs`; the repository-only bootstrap CLI remains in
`packages/cli/bin/psc.mjs`.

See [PLATFORM_IMPLEMENTATION.md](PLATFORM_IMPLEMENTATION.md) for the exact cloud
qualification, tarball workflow, existing-TypeScript-project example and
remaining work. [PSC0_ARCHITECTURE_PLAN.md](PSC0_ARCHITECTURE_PLAN.md) is the
accepted architectural plan. This preview is not yet published to npm.

`psc check` checks canonical declarations through the pinned native PSKernel
Core provider. `psc build` additionally checks RuntimeIR, validates generated
TypeScript with TS7.0.2, and publishes owned output with a completion receipt.
Unsupported PSCV/contract profiles and external extensions are refused.

## Compiler lineage

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
The protected checked host now defaults to the exact native PSKernel Core
provider pinned at source `963030dc2d154008fccc82e7c8ed29331f138799`, using
Lean 4.34.0 and the canonical compiler-admission protocol. Explicit development
Lean native/WASM alternatives retain their own descriptors. The public npm
launcher has no provider-selection override.

`legacy/packages/project` is retained as a *regression-only* Lake
module import for `test/BootstrapTests.lean`. It is not imported by the
compiler fixed-point root. The experimental owned-kernel provider is
retained for historical/development comparison; it is not the protected
`pskernel-core` selector, a public npm choice, or a bootstrap source dependency.

## Important limits

The original October 3 compiler fixed point was measured on the original
historical tree. This reorganization does not constitute a new fixed-point
run, and it does not certify any owned-kernel or joint compiler/kernel
self-hosting. Archive sources and receipts are preserved, not silently
treated as current implementation or verification results.

When working inside this directory, use its own toolchain/commands and
consult `legacy/README.md` before attempting historical extension tests.
