# PSC0 compiler and self-host implementation

## Installable platform preview

**Preview2 is qualified** on Linux and Windows x64 with Node22.23.3/npm10.9.9 and Node26.7.0/npm12.0.2. It adds `psc init`, project entry/output defaults, `psc examples`, and a separately installed **psdev** one-shot command extension. An independently named **@psc-demo/pshello** package uses the same confined command interface.

Download the three tarballs from the [preview2 candidate artifact](https://github.com/dwijayuda/pskernel/actions/runs/37998655835/artifacts/11648008841). Windows PowerShell qualification uses `psc.cmd`. See [PLATFORM_IMPLEMENTATION.md](PLATFORM_IMPLEMENTATION.md) for exact installation, activation, results and remaining scope, and [release/README.md](release/README.md) for the consumer guide.

The protected public launcher is `bin/psc.mjs`; the repository bootstrap CLI remains `packages/cli/bin/psc.mjs`. `psc check` performs native PSKernel Core admission. `psc build` additionally validates the same original RuntimeIR and generated TypeScript with TS7.0.2 before owned publication. A `dev --once` request goes through that same path and records its actual extension identity in the saved receipt.

The first [command extension SDK](docs/platform/command-extension-sdk.md) runs a tightly restricted no-import Wasm guest. Installation alone does not activate it. Full watch, module/export and checked ABI work, general language plugins, PSCV and LSP remain later milestones. Unsupported requests are refused explicitly.

The [accepted architecture plan](PSC0_ARCHITECTURE_PLAN.md) and [active continuation state](AI_WORK_STATE.md) record these boundaries. The 61-module compiler closure, selected seed, native-provider algorithms and bootstrap toolchain are unchanged. This candidate is not yet published to npm.

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
