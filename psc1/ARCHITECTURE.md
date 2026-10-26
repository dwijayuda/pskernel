# PSC1 architecture

This document describes responsibilities. Exact source identities and passing
runs belong to the qualification receipts linked from [the documentation index](../docs/README.md).
The previous architecture snapshot is [preserved](../docs/history/ARCHITECTURE_BEFORE_READABILITY_2026-10-25.md).

## Follow one compilation

1. Capture dependency-ordered exact source bytes and module identities.
   The native path uses `Ps.Host.SourceSnapshot`; the installed API receives a
   captured source list, and its CLI accepts a single file or a closed project JSON.
2. Parse either grammar into shared syntax, resolve names and elaborate canonical Core.
3. Prepare the exact canonical admission graph. Ordinary-checked mode pairs opaque
   logical declarations with separately typed executable bodies and checks their identity.
4. Erase proofs/types and construct executable IR. Strict validation applies to the
   original IR and again after target transformations.
5. Apply the existing target plan and emitter to produce a **candidate**.
6. The host requires actual independent official Lean 4.35.0 acceptance of the exact
   admission graph, validates response/source/tool identities and runs target/API checks.
7. For publication, seal a complete immutable generation and commit its current pointer
   through the existing transaction. Precommit failures preserve the previous generation;
   the installed generated publisher reports committed uncertainty explicitly.
   The native legacy publisher can throw after its pointer commit while flushing;
   its callers must inspect committed state rather than assume rollback.

This is a dependency description. Generated execution can produce the candidate
before the external checker runs; candidate production never grants publication authority.

## Responsibility and dependency map

| Layer | Implementation | May depend on |
| --- | --- | --- |
| Positions, names, collections and diagnostics | `packages/foundation` | Portable foundation |
| Shared AST, lexer, both parsers/printers | `packages/syntax` | Foundation |
| Logical terms and declarations | `packages/core` | Foundation/model dependencies |
| Environment, inference and elaboration | `packages/environment`, `meta`, `elab` | Syntax/Core; no target printers |
| Admission encoding and compiler orchestration | `packages/bridge`, `compiler` | Semantic layers and erasure/IR |
| Erasure, executable IR and strict validation | `packages/erasure`, `compiler-ir` | Semantic models; no target publication |
| Closed target planning | `packages/backend-common` | Checked IR |
| Target representations, runtime helpers and emission | `packages/backend-*` | IR and shared plan |
| Four-engine composition root | `packages/compiler-unified` | JS/TS/Rust/Wasm compiler services |
| Native project/CLI composition | `host/src`, `packages/cli` | Semantic compiler, selected backends and host facilities |
| Installed sessions, resources and publication | `host-tools`, `npm-cli` | Explicit pinned tools and packages |
| Official independent checking | `packages/pskernel-lean/provider`, `pskernel-lean-wasm` | Official pinned Lean kernel |

The import graph and the build are authoritative for exact dependencies. This
table is a guide, not permission to introduce cycles or bypass the semantic compiler.
Existing semantic-boundary guards remain in force.

## Three independent selections

- **Execution engine:** the generated compiler runs as JS, TS, Rust or compiler-Wasm.
- **Output target:** JS, TS, Rust, core Wasm, component Wasm, Python or PHP.
- **Independent checker:** official Lean 4.35.0 via linear-memory Wasm by default,
  optionally native or explicit comparison of both.

One source/compiler pipeline supplies the engines. They are not four handwritten compilers.
The qualified slim host supports seven checked output selections through four G3 engines.
Python/PHP remain explicit optional providers; component output has the bounded Bool ABI.
The candidate-only API retains four targets and grants no admission/publication authority.
See [current capability and evidence scope](../docs/PSC1_CAPABILITIES.md).
Never infer installed capability from a backend enum or an available source file.

## Authority and trust

`PsVerifiedIrModule` and `PsValidatedIrModule` are constructible data wrappers.
Their names are not proof certificates. Backend entries must revalidate input.
Generated response fields, package metadata and copied receipts cannot select a
checker, tool path, plugin, output directory or publication policy.

The generated host's private session state ties together captured sources,
actual compiler execution, strict response validation, actual independent checker
acceptance, staged target bytes and the publication transaction. See
[`host-tools/generated-compiler-session.mjs`](../host-tools/generated-compiler-session.mjs)
and [host guide](../host-tools/README.md).

Independent admission establishes logical acceptance under the pinned Lean rules.
Typed IR is not a proof of source-to-target preservation. Cross-backend tests and
self-host fixed points do not replace such a proof. The current receipts explicitly
retain these assurance boundaries.

## Runtime, control and resource invariants

A logical prelude declaration is checked source. A target runtime helper implements
a target representation and belongs to its backend. Selected helpers are bundled
with target output; there is no implicit general-purpose npm runtime authority.

The executable IR remains expression-oriented. Checked continuations carry lexical
state. Selected ordinary loops use checked private helpers; temporary elaborator
markers are removed before admission. No unchecked loop opcode, host mutable cell
or source-selected foreign authority is introduced.

Explicit workers, accumulator order, source fuel and refusal priority are intentional
parts of the self-hostable implementation. A readability refactor must preserve
these before considering a different algorithm.

Compiler-Wasm retains PSC1's existing GC architecture. The independent Wasm kernel
is the official C++ kernel compiled with Emscripten to linear memory; it is not Wasm GC.
Kernel research under PSKernel-Core remains an independent workstream.

## Distribution and reproducibility

The slim root packages frozen qualified G3 JS/TS executors, the mandatory Wasm
checker and readable host code. Optional compiler executors and native checking
require exact package/version/manifest/resource identities. Missing or corrupt
resources refuse without download or fallback.

Linux publication retains locks, before/after identity checks, immutable generations,
file/directory fsync and an atomic current-pointer commit. Other OS publication
is refused pending equivalent implementation and release tests.

Frozen compiler qualification remains attached to its original source closure.
A native-source refactor does not retroactively requalify generated frozen payloads;
changed compiler sources need their own source/closure/release evidence.
See [current roadmap](../docs/PSC1_DEVELOPMENT_ROADMAP.md), [contracts and receipts](../docs/README.md).

[Follow one tiny program](../docs/guides/compilation-walkthrough.md) through actual source
owners. [Pass contracts](../docs/reference/pass-contracts.md) record invariants, refusal and
resource behavior. [Maintainer exercise](../docs/development/maintainer-exercise.md) distinguishes
an executable CI rehearsal from a pending independent human trial.
