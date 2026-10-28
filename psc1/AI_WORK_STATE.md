# PSC1 AI work state

Updated 2026-10-28 Asia/Jakarta. Documentation branch `docs/psc1-executable-modularity-20261028`,
based on qualified PR #198 HEAD `ee9220e20e6b9fa202693c8226815a780cc5bbc0`.
GitHub/Linux CI only; expected-HEAD/non-force history. No merge or npm publication.

## Current user decision: production executable-modularity plan

[New plan](docs/architecture/executable-package-modularity.md) defines the target:
proofscript remains the installation umbrella; psc remains its thin CLI command;
executable packages gradually follow existing source responsibilities.

Further experimental pilot development/expansion is deferred. Existing qualified
pilot evidence/regressions remain intact; experimental namespaces and small
fixture/profile limits are not the production architecture. No tests are disabled.

This change is documentation only. It does not restart implementation, change
compiler/kernel/host bodies, replace a package artifact, or qualify a modular
compiler. Source-only interfaces remain labeled until actual implementations exist.

The dependency-ordered production stages are M0 ownership/API/contract, M1 real
lower-level modules, M2 complete compiler graph, M3 checked compiler execution,
M4 umbrella/thin-CLI integration, and M5 reproduction/final generation qualification.
The [roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) remains the overall queue authority.

## Dependency and trust decisions

Preserve all existing npm names/directories and one compiler source/pipeline.
Fix package return edges by moving only misplaced shared contracts to appropriate
existing lower owners, preserving bodies/logical names first. Do not hide cycles
with undeclared imports, upward package searches or a global compiler singleton.
Keep checked convenience APIs at the umbrella/host layer; explicitly version
direct low-level API transitions. Real generated module bodies and imports are
required; wrappers over a hidden complete compiler do not complete the target.

Retain official Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc admission,
strict original/transformed IR, source/body identities, semantic fuel, existing
memory/stack/tool policies, 240-second compiler requests and 120-second checking.
Default kernel Wasm remains genuine C++/Emscripten linear memory. Python/PHP and
existing optional native/compiler engines/SDKs stay optional with fail-closed
selection. Owned code stays Apache-2.0 and retains upstream notices.

## Preserved qualified baseline

PR #198's .13 remains the usable reference, not a full modular runtime:
20 core packages install automatically, with whole-compiler JS/TS executors.
[Exact receipt](docs/PSC1_NPM_UMBRELLA_QUALIFICATION_2026-10-27.json).
At ee9220e2, package40546073325 passes53 cases/125 exports and documentation
gate40546073429 passes. Full source40509034008 at892e1895 passes16 selected jobs,
37/37 Core criteria and scoped seven-backend execution. The separate .11 CLI
compatibility run40507924067 passes; it is not the .13 artifact.

Frozen G3 source identity remains122 modules/4742 members and closure
073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9.
Development source navigation recorded125 modules. Neither a source count nor
old bundled fixed points qualifies a new modular graph or changed source closure.

## Deferred implementation preserved

Draft PR #203: branch feat/psc1-real-modular-compiler-20261028,
HEAD1ba3173646c0fde2b15ef796192ca4be850ba5a7 at inspection.
Stopped build prototype: feat/psc1-real-modular-build-20261028,
HEAD10b1dea50217036171654b46076183b7257d13f0 at inspection.
The earlier partition branch b9461a3c is also retained.
These are preserved experimental mechanisms, not a promoted production compiler
or verified final modular ZIP. No branch was reset, merged or force-updated.

## Remaining scope

Next implementation should start from the production plan's M0 inventory and
finite contract, not resume a pilot-driven loop automatically. Reuse reviewed
mechanisms where useful, without treating the experiment as a release dependency.
Non-Linux consumers/durability, permanent qualified-input retention, the arranged
human maintainer trial and authorized release publication remain separate tasks.
CI on this change verifies documentation/static contracts only; it does not
establish the planned architecture or new compiler correctness.
