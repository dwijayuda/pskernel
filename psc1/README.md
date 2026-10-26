# PSC1 compiler and ProofScript toolchain

PSC1 compiles frozen Practical Core v1 from supported `.lean` and `.ps` grammars.
One semantic compiler supplies seven native backend mappings. The slim npm flavor
uses genuine self-hosted JS/TS executors with optional Rust/compiler-Wasm executors
and the official Lean 4.35.0 independent C++ kernel compiled to linear-memory Wasm.
Compiler execution, output target and checking are separate choices.

The [qualified .9 layout milestone](./docs/PSC1_LAYOUT_QUALIFICATION_2026-10-26.json)
adds explicit runtime/CLI ownership, categorized guides, package navigation and a
body-preserving TypeScript runtime extraction. The selected root is 3,823,980 bytes;
its frozen G3/compiler/kernel/provider payloads retain their original identities.

Start with the [project CLI/install guide](./docs/guides/cli.md),
[architecture](./ARCHITECTURE.md) and [contributor guide](./CONTRIBUTING.md).
Follow the [source-linked compilation walkthrough](./docs/guides/compilation-walkthrough.md)
and [maintainer exercise](./docs/development/maintainer-exercise.md).
[Current capability scope](./docs/PSC1_CAPABILITIES.md) distinguishes qualified
installed packages from later development source.
The [documentation index](./docs/README.md) links current contracts and exact receipts.
The [roadmap](./docs/PSC1_DEVELOPMENT_ROADMAP.md) owns remaining work;
[AI_WORK_STATE.md](./AI_WORK_STATE.md) records the engineering checkpoint.

The preceding .8 host CLI introduced [project initialization, source files and diagnostics](./docs/guides/cli.md).
Its [exact Linux qualification](./docs/PSC1_CLI_QUALIFICATION_2026-10-26.json) preserves the frozen G3 executables.
[TypeScript workflow research and decisions](./docs/development/typescript-workflows.md) explain the scope.

## Programs and installed use

```lean
def invert (flag : Bool) : Bool := if flag then false else true
```

The supported ProofScript spelling is:

```text
def invert(flag : Bool) : Bool := if (flag) { false } else { true }
```

With Node 22.23.3 and the qualified local unpublished tarball:

```sh
npm install --offline --ignore-scripts ./proofscript-0.1.0-psc1.9.tgz
npx --no-install psc check Main.lean
npx --no-install psc compile Main.ps --engine ts
npx --no-install psc build Main.ps --target wasm-core --publication-protocol portable-file --out dist/app
```

The default root requires no compiler SDK or install-time build. Optional output
consumers are explicit: TypeScript7.0.2 plus its pinned platform binary for TS;
the pinned Rust 1.90.0 SDK and separate consumer package for Rust. JS/Wasm output
requires neither. [Checked targets and publication](./docs/PSC1_CHECKED_PUBLICATION.md)
documents immutable artifacts, runtime loaders, source encoding, ABI bounds and
failure handling. Checked component output uses an explicit optional validator
and the bounded Bool ABI. Python/PHP are explicit optional emit-only providers
with bundled isolated runtimes. [Dispatch architecture](./docs/PSC1_CHECKED_DISPATCH.md)
describes the additional packages, checks and limitations.

## Qualification and evidence boundaries

Qualified packaged G3 source:122 modules/4742 Core members, closure
`073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9`.
All four genuine G1/G2/G3 chains and exact fixed points passed for this source:
JS/TS/Wasm 40223062370; Rust 40223086966.
[Current generated-IO receipt](./docs/PSC1_GENERATED_IO_QUALIFICATION_2026-10-26.json)
retains the source, generation and preceding installed-application evidence.
The [current dispatch receipt](./docs/PSC1_CHECKED_DISPATCH_QUALIFICATION_2026-10-26.json)
records the exact installed replay and source gate, including all 37 finite criteria.
The preceding .7 root was3,811,703 bytes; the selected .9 root is 3,823,980 bytes.
Optional native payloads remain separate. Use the exact layout receipt.
Later development refactors have distinct source inventories and qualification;
see AI_WORK_STATE.md and the maintainability receipt.

[Checked-publication receipt](./docs/PSC1_CHECKED_PUBLICATION_QUALIFICATION_2026-10-26.json)
retains the preceding four-target host/package qualification. Older frozen120-module and refactored121-module
results remain distinct in dated receipts; they are not relabeled current.

The [Practical Core contract](./docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json) defines
37 finite language criteria. The [npm distribution contract](./NPM_DISTRIBUTION_CONTRACT.json)
also requires final platform/package qualification. Linux-only compiler/package
tests do not qualify a final macOS/Windows release. Those publication commits
remain disabled until actual platform evidence exists.

Independent Lean admission checks the canonical logical graph. Strict IR
validation checks typing/structure. Runtime tests and self-host fixed points add
evidence; none alone proves compiler semantic preservation. Official checking,
resource limits, negative tests and explicit unsupported-ABI refusals are preserved.
No merge or npm publication is authorized.

## Source ownership

- `packages/*/src`: authored semantic compiler/backend source.
- `host/src`, `host-tools`: capture, pinned resources, independent tools and publication.
- `npm-cli`: installed API/CLI.
- `test`: authored regressions, reference algorithms and applications.
- `scripts`: CI, bounded consumers, packaging and qualification.
- `docs`: current guides, contracts, dated receipts and preserved history.
- `dist` and packed `selfhost`: generated artifacts, never handwritten compilers.
- `legacy`, `npm-runtime`, `release-js`: older paths; establish import/packaging ownership before changes.

Historical profile fields and older instructions remain in Git and
`docs/history/`. They do not replace the current contracts or exact evidence.
