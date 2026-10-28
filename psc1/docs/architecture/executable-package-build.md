# Production executable package build

Status: production candidate implementation in PR #205. The default .13
distribution remains the qualified reference. This guide does not qualify
modular self-hosting or promote the candidate public package API.

The [production plan](executable-package-modularity.md) defines M0–M5.
The [contract](../../EXECUTABLE_PACKAGE_CONTRACT.json) binds the finite tests and
bounds. [AI_WORK_STATE.md](../../AI_WORK_STATE.md) records live commits/results.

## What executes where

| Code | Responsibility |
| --- | --- |
| [Compiler.Service](../../packages/compiler/src/Ps/Compiler/Service.lean) and [CompilerUnified.Service](../../packages/compiler-unified/src/Ps/CompilerUnified/Service.lean) | Existing frontend/pipeline orchestration and four-target dispatch. |
| [BackendCommon.ServiceError](../../packages/backend-common/src/Ps/BackendCommon/ServiceError.lean) | Unchanged lower-level error data, retaining logical names. |
| BackendJs/BackendTs/BackendRust/BackendWasm.Emit | Exact existing target emitter bodies; no compiler-driver import. Legacy CompilerService files retain single-backend entry points. |
| [ModuleModel](../../packages/backend-common/src/Ps/BackendCommon/ModuleModel.lean), BackendJs/BackendTs.ModuleFiles | Shared existing structured module records, reference/provenance traversal and printers. The old bounded pilot wrappers retain their policies. |
| [SourceModules](../../host/src/Ps/Host/SourceModules.lean) | Original value ownership from the production elaborator's captured tagged Core names and exact erasure names. |
| [ExecutablePlan](../../host/src/Ps/Host/ExecutablePlan.lean) | Host build-time dependency and initialization planning over strictly checked transformed IR. |
| [ExecutablePackagesMain](../../scripts/ExecutablePackagesMain.lean) | Native capture/transform and candidate emission adapter; no second frontend or publication authority. |
| [executable/build.mjs](../../host-tools/executable/build.mjs) | Trusted build-session capture, independent admission and resource/tool binding. |
| [executable/package.mjs](../../host-tools/executable/package.mjs) | Existing package assignment, exact SDK checks, strict TS, AST import/export/runtime audits and byte inventory. |
| [executable/verify.mjs](../../host-tools/executable/verify.mjs) | Complete candidate inventory and metadata checks before dynamic import. |
| [executable/qualify.mjs](../../host-tools/executable/qualify.mjs) | Reference comparisons, independent application admission, target consumers and offline npm installation. |

The native build adapter composes existing compiler operations. It is not a
handwritten replacement for parsing, elaboration, erasure or target emission.
Its native planner is not yet a portable graph-emission API callable by the
generated compiler. That distinction is an explicit M5 blocker.

## Source identity and checking

The compiler is captured once through the existing elaborator, with source
ownership from that same execution. The builder uses the established
ordinary-checked compiler profile, preserving canonical logical admission,
logical/runtime body pairing and strict IR. Its partial declarations are listed
in the capture/manifest/receipt. This does not prove termination or claim that a
partial executable body is admitted as a total Lean definition.

Application fixtures use checked preparation. Both compiler and application
canonical payloads go through the existing independent official Lean 4.35.0
checker at eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Canonical Core admission is distinct from source-to-Core or backend-preservation
proofs; the receipts retain that boundary.

The builder strictly checks original, specialized and worker-fused IR, carrying
producer-generated ownership through both transforms. It rejects missing,
duplicate and unknown owners. New source moves obtain a new closure digest.
Frozen G3 closure073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9
retains only its original evidence.

## Module and package layout

A candidate contains the existing package names, not a package per source file:

```text
node_modules/@proofscript/elab/
  dist/js/generated/Ps.Elab.Term.mjs
  dist/js/generated/Ps.Elab.Term.d.mts
  src/ts/generated/Ps.Elab.Term.mts
  dist/ts/generated/Ps.Elab.Term.mjs
  dist/ts/generated/Ps.Elab.Term.d.mts
  sources/Ps.Elab.Term.lean
  PROVENANCE.json
  package.json
```

Each surviving value appears in its actual source owner's generated unit.
The unnamed compiler-unified source directory belongs to @proofscript/compiler.
The common runtime and nominal carriers live once in the existing foundation
package per selected JS/TS graph. Runtime helper names remain internal contracts.
JS structural tags and TS symbols retain their distinct representations.
Erased/type-only sources have no invented value implementations.

A package's dependencies come from the actual generated imports, including
type-only imports. Package cycles refuse. No lower-level package imports the
umbrella or CLI. Existing .13 checked aliases are not copied into the candidate:
the versioned direct-API compatibility transition belongs to M4, while checked
convenience entry points remain at the umbrella/host layer.

Candidate generated subpaths select JS or TS implementations. They return
candidates and provide no independent checking capability. They are not the
normal end-user API and have not replaced proofscript's checked root API.

## Initialization

Source units are ordered by the actual global-reference graph. Cross-source
cycles fail closed. Within a unit, function and static-value initialization
precedes computed values. A computed initializer waits for same-unit computed
values reachable through referenced function/closure bodies. The traversal is
conservative: it may refuse a harmless cycle but does not waive individual names
such as psCodecQuotedA.

The retained pilot still permits only its original bounded static initializers.
The production planner has separate finite bounds and negative tests; production
growth does not relax or expand pilot profiles.

## Run the Linux qualification

Use the [focused workflow](../../../.github/workflows/psc1-executable-packages.yml)
on the current implementation/build branch. It provisions the pinned Lean,
Node22.23.3, TS7.0.2 and locked Rust1.90.0 consumer resources. User Node policy
remains a minimum; exact versions here identify the qualification environment.

After the workflow's locked SDK/baseline setup, its relevant commands are:

```sh
node scripts/executable-package-ownership.mjs
lake build psc1_emitter_boundary_tests psc1_unified_service_tests \
  psc1_executable_plan_tests psc1_executable_packages \
  psc1_modular_pilot psc1_independent_checker
lake exe psc1_emitter_boundary_tests
lake exe psc1_unified_service_tests
lake exe psc1_executable_plan_tests
node scripts/executable-emitter-consumers.mjs
node host-tools/executable/build.mjs
node host-tools/executable/qualify.mjs
```

Run in a fresh CI workspace. The builder refuses an existing compiler output
directory instead of replacing a prior candidate. Native capture and emission
are separate supervised build stages, each240s. Normal compiler/tool requests
stay240s; the existing independent checker stays120s. Native stages retain4GiB
address-space/8MiB stack limits. Node keeps4096MiB V8 heap/8MiB stack settings,
rather than an address-space cap incompatible with V8 virtual reservations.
Semantic fuels and the old self-host correctness/performance profiles are unchanged.

The contract separately caps each file at32MiB, each native stage's aggregate
writes at128MiB, and the candidate graph at128MiB/8192 files. The Linux job has a
finite30-minute envelope. Resource receipts contain elapsed time, sampled CPU and
peak child/tree RSS; sampled RSS can count shared pages more than once.

## Evidence and limits

Artifacts under dist/executable-packages contain the ownership audit, strict-IR
emitter consumers, source/request snapshots, canonical admissions, original and
transformed IR, capture metadata, complete module plan, byte manifest, resource
logs, candidate package files/tarballs and qualification receipts.

The qualifier compares complete modular JS/TS compiler responses byte-for-byte
with the unsplit same-IR reference. It independently admits positive application
Core before executing generated outputs. Negative tests cover typing, optional
targets, owner/path/inventory/cohort corruption and initializer hazards. The
candidate tarballs undergo offline multi-package installation and exact byte
comparison. This is distinct from root-only proofscript installation.

A trusted build manifest and stable-file/bootstrap assumptions are required.
Hashes, npm exports and AST inspection are not a sandbox or a semantics proof.
The candidate does not yet provide transactional whole-graph publication,
root-only checked CLI/watch promotion, a complete retained application/backend
qualification corpus, portable modular reproduction or new modular G1/G2/G3 and
fixed points. Those remain explicit ordered gates. Other-platform qualification
and registry publication are not inferred from Linux evidence.
