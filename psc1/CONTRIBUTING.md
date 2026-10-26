# Contributing to PSC1

Read [the architecture](ARCHITECTURE.md), then follow the source for one small
program through parsing, elaboration, canonical admission, erasure, strict IR,
target emission and host checking/publication.

## Find the right owner

Language syntax belongs in `packages/syntax`; shared meaning belongs in
`environment`, `meta` and `elab`. Runtime IR belongs in `compiler-ir`; proof
erasure belongs in `erasure`. Target code belongs in `backend-*`.
Host filesystem/process/package authority belongs in `host` or `host-tools`.
Installed commands and APIs begin in `npm-cli/universal-cli.mjs` and `universal.mjs`.

Do not implement a language feature separately in each backend. Define shared
semantics, cover both grammars, then qualify relevant mappings and explicit ABI refusals.
A source library is source input; its metadata cannot grant host/kernel/FFI authority.

## How to make a reviewable change

1. Fetch the live branch HEAD and inspect relevant completed CI.
2. State the concrete behavior or invariant being changed and the owning module.
3. Keep formatting, movement, renaming and behavioral edits separate.
4. Retain public names and algorithm bodies for a module-extraction pilot.
5. Run focused checks first, then all selected source/package/final gates.
6. Record exact commits, runs and remaining limitations in the existing receipt/work state.

For this workstream use connected GitHub tools and Linux GitHub Actions only.
Use single-parent expected-HEAD non-force updates. Preserve concurrent work.
Do not merge or publish npm packages without authorization.

## Readable source

Use the existing portable source subset. Some explicit recursion and workers avoid
generated stack growth; shortening them can change performance, refusal order or
fuel behavior. Explain the invariant before changing the form.

Module comments should explain responsibility, inputs/outputs, traversal/effect
order, failure and resource behavior. Link relevant tests or proofs. Avoid comments
that merely repeat a function name.

For handwritten JS/MJS host files use the pinned host-tools Prettier version and
the scoped formatting/AST comparison in `scripts/readability-host-check.mjs`.
Generated payloads, embedded runtime strings, frozen qualified executables and
vendored kernel sources are outside this formatting scope.
Formatting is not an optimization or a formal equivalence proof.

## Test and evidence map

| Change | Existing evidence to preserve |
| --- | --- |
| Shared language semantics | Both grammars, focused regressions, closure/G1 and finite Practical Core qualification |
| Backend/IR/runtime | Strict original/transformed IR, negative/ABI cases, target consumers and seven-backend coverage |
| Installed host | Actual offline local/global package execution, checker parity, identity/tamper and publication-failure cases |
| Module extraction | Exact retained-body correspondence, Lean build, affected source closure and normal full gates |
| Frozen compiler payload | Exact source/IR/admission/executable identities and the required manual self-host/release chain |

Source-shape assertions still protect historical portability constraints. Do not
delete them to make a refactor pass. Move toward structural/behavioral checks only
with equivalent protection and explicit review.

`test/*Reference.lean` files explain or preserve algorithms for correspondence tests.
For example `test/CodecSpineProof.lean` proves exact codec-worker correspondence.
Reference modules are not alternative production compilers.

## Generated files and historical projects

Change the producer of a generated artifact, regenerate through CI and record
the new identity. Never hand-edit a qualified generated executable.
The root TypeScript kernel, PSC0, PSCV and PSKernel-Core research have separate
scope/pins. Their green CI does not qualify PSC1 changes.

Use [the docs index](docs/README.md) for current contracts versus dated receipts.
The [source-refactoring design](docs/PSC1_SOURCE_REFACTOR_ARCHITECTURE.md) describes
qualified bounded capture/ownership/conversion/rename candidates and their deliberate
refusals. General parse/print translation alone does not preserve trivia or grant
semantic editing authority.

## A first change without AI assistance

Start with the [compilation walkthrough](docs/PSC1_COMPILATION_WALKTHROUGH.md), then
complete the [maintainer exercise](docs/PSC1_MAINTAINER_EXERCISE.md). Record source
owners, evidence, elapsed time, confusing instructions and help used. CI checks the
commands and a reference small change; it cannot qualify human comprehension.
For pass changes consult [the contracts](docs/PSC1_PASS_CONTRACTS.md). Keep exact
body movement separate from naming or algorithm changes.
