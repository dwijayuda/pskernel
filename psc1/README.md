# PSC1 compiler and ProofScript toolchain

PSC1 compiles the frozen **Practical Core v1** subset from both supported
`.lean` and `.ps` grammars. One semantic compiler serves seven output targets:
JavaScript, TypeScript, Rust, core Wasm, component Wasm, Python and PHP.

The current unpublished slim npm distribution includes qualified self-hosted
JS/TS compiler executors and the official Lean 4.35.0 C++ kernel compiled by
Emscripten to **linear-memory Wasm**. Rust and compiler-Wasm executors are
explicit optional packages. Python/PHP output providers belong to the preserved
native distribution; the slim generated path does not yet expose every output.
Compiler execution engine, output target and independent checker are separate choices.

## Start here

| Reader's task | Authoritative entry |
| --- | --- |
| Install and use the current slim package | [Slim package guide](docs/PSC1_SLIM_UNIVERSAL_PACKAGE.md) |
| Understand compilation and authority | [Architecture](ARCHITECTURE.md) |
| Modify the implementation | [Contributor guide](CONTRIBUTING.md) |
| Find current documents and evidence | [Documentation index](docs/README.md) |
| Determine unfinished product work | [Development roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) |
| Continue an engineering session | [AI work state](AI_WORK_STATE.md) |
| Verify language acceptance criteria | [Practical Core contract](docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json) |
| Verify npm acceptance criteria | [Distribution contract](NPM_DISTRIBUTION_CONTRACT.json) |

## A small program

```lean
def invert (flag : Bool) : Bool := if flag then false else true
```

The supported ProofScript equivalent is:

```text
def invert(flag : Bool) : Bool := if (flag) { false } else { true }
```

For a matching qualified unpublished tarball and Node 22.23.3:

```sh
npm install ./proofscript-0.1.0-psc1.4.tgz
npx psc check Main.lean
npx psc compile Main.ps --engine ts
npx psc build Main.ps --out dist/app
```

These commands use the independently checked generated compiler workflow.
`compile` returns JSON containing checked JS and its receipt. `build` publishes
checked JS with the existing Linux transaction guarantees. Missing or corrupt
optional executors fail explicitly; there is no automatic tool download or fallback.
Use the install guide for exact optional tarballs and API examples.

## What is qualified, and what remains open

The frozen 120-module compiler closure
`07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af`
has genuine JS/TS/Rust/compiler-Wasm G1/G2/G3 and fixed-point evidence.
[Four-engine receipt](docs/PSC1_UNIFIED_FOUR_ENGINE_QUALIFICATION_2026-10-25.json).

At implementation `0a717520110c673006d3f5f5d7627e59d5853f62`,
[package CI 40166882825](https://github.com/dwijayuda/pskernel/actions/runs/40166882825)
qualifies offline local/global installation, all four executors, real checking,
candidate target mappings and refusal/publication-failure cases.
[Source CI 40166884643](https://github.com/dwijayuda/pskernel/actions/runs/40166884643)
passes 37/37 Practical Core criteria, both grammars and all seven native target mappings.
[Exact package/source receipt](docs/PSC1_SLIM_UNIVERSAL_QUALIFICATION_2026-10-25.json).

These results belong to their exact commits and artifacts. Subsequent source
changes need their own evidence. The current slim checked-output path supports JS;
checked generated non-JS publication, complete source-package/application integration,
portable transactional publication and final clean release qualification remain open.
Linux-only compiler/package testing does not qualify every release platform.

Independent Lean admission checks the canonical logical graph. IR validation
checks executable typing and structure. Runtime regressions and self-host fixed
points are additional evidence. None alone proves compiler semantic preservation.
No merge or npm publication is authorized by these documents.

## Source ownership

- `packages/*/src`: authored semantic compiler and backend source.
- `host/src`, `host-tools`: project capture, independent checker/tool invocation,
  installed resources and publication authority.
- `npm-cli`: installed API and CLI entry points.
- `test`: regressions, reference algorithms and practical applications.
- `scripts`: CI, qualification, packaging and historical source-shape checks.
- `docs`: current guides, finite contracts, immutable receipts and dated history.
- `legacy`, `npm-runtime`, `release-js`: older paths; inspect import/packaging
  ownership before modifying them. Their presence does not make them current products.
- `dist` and packed `selfhost` payloads: generated artifacts, never handwritten compiler sources.

`profile.json` is explicitly marked as a historical native snapshot.
Current language and npm scope comes from the contracts linked above.
The [previous README](docs/history/README_BEFORE_READABILITY_2026-10-25.md)
and Git history preserve earlier instructions and qualifications.
