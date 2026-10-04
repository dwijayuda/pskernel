# ProofScript production architecture implementation roadmap

**Status:** staged engineering plan. It is intentionally ordered to preserve the current self-host fixed point while strengthening authority, safety, extensibility, performance, and release maturity.

## 1. Starting point

Current baseline characteristics to preserve:

- PSC2 r3 source direction;
- stable TypeScript/JavaScript self-host fixed point;
- predictive current-source fixed point;
- resident content-addressed and red/green cache;
- backend-neutral semantic compiler;
- target-neutral compiler IR;
- optional Rust/Wasm backends outside the minimal fixed-point closure;
- experimental owned kernel kept off-bootstrap until its provider boundary is ready;
- no fallback for unsupported semantics/check failures.

Do not destabilize this baseline merely to make architecture diagrams look final.

## 2. Sequencing principles

1. Freeze boundaries before adding ecosystem breadth.
2. Make authority impossible to bypass before optimizing around it.
3. Separate semantic changes from representation/performance refactors.
4. Add generic validators/contracts instead of one-off repair guards.
5. Keep expensive release gates separate from fast edit-time feedback.
6. Preserve Lean/TS/Rust routes as independent oracles during direct-JS/Wasm maturation.
7. Grow formal assurance one closed semantic slice at a time.

## 3. Phase A — production documentation and contract registry

### Goals

- establish this architecture documentation set;
- define current versus planned versus normative status;
- create a machine-readable contract-version registry later;
- add ADR discipline for authority-bearing decisions.

### Deliverables

```text
docs/architecture/*
contract registry design
security/trust model
build/artifact model
roadmap
ADR index
```

### Gate

No code semantics change required.

## 4. Phase B — genuine CheckedCore authority

### Goals

Replace “codec-valid admission ready” as the executable staging boundary with genuine kernel admission while keeping the provider replaceable.

### Interim provider policy

Use `lean434-wasm` / `@proofscript/pskernel-lean-wasm` as the default checked provider for this phase. Keep native Lean as an explicit reference route and `pskernel-core` as an explicit experimental route. Do not make either alternative a fallback.

### Work

- freeze `KernelContract-v1`;
- define `CandidateCore`;
- define opaque/restricted `CheckedModule` / checked-session capability;
- bind the current checked path to the pinned Lean 4.34 Wasm provider identity;
- keep the provider contract independent of that concrete implementation;
- make erasure production entry points require the checked capability;
- preserve the exact prepared value across external checking;
- record checked-core/admissions hash and provider receipt;
- later adapt `pskernel-core` to the same contract and switch only after its readiness gates close.

### Gates

- kernel provider boundary tests;
- candidate rejected by kernel never reaches erasure;
- accepted module produces stable receipt/hash;
- Lean/reference parity corpus;
- no backend/frontend import can construct CheckedCore directly.

### Exit criterion

Every production executable path passes through real kernel admission.

## 5. Phase C — ErasedIR/VerifiedIR split

### Goals

Make “VerifiedIR” a true validated executable contract.

### Work

- rename/current IR construction layer to ErasedIR/RuntimeIR where appropriate;
- retain temporary `unknown` only in construction stage;
- define `validateRuntimeIr`;
- introduce validated module/type wrappers;
- require backends to consume validated IR;
- canonical VerifiedIR encoder/hash;
- add negative validator corpus.

### Gates

Validator rejects:

- executable unknowns;
- unresolved names;
- bad arity;
- bad fields/constructors;
- invalid intrinsics;
- malformed match alternatives;
- unsupported runtime representation.

### Exit criterion

A backend receiving `VerifiedModule` can rely on frozen target-neutral well-formedness invariants.

## 6. Phase D — backend dependency cleanup and runtime contracts

### Goals

Make backend isolation structural.

### Work

- move thin source/compiler adapters out of backend-ts/backend-rust;
- make backend cores depend only on validated IR plus approved target-neutral metadata;
- remove unused cross-backend dependencies;
- freeze `RuntimeSemantics-v1`;
- define JS/Wasm/Lean/Rust ABI profile identities;
- add cross-backend primitive corpus.

### Exit criterion

Dependency graph prevents a backend from reaching frontend/kernel authority.

## 7. Phase E — direct JavaScript bootstrap

Follow the continuity design in `docs/continuity/PSC2_NEXT_BOOTSTRAP.md`.

### Work

1. define minimal JsIR;
2. implement VerifiedIR -> JsIR;
3. implement JsIR validator;
4. deterministic ESM emitter;
5. keep backend-ts -> tsc as oracle;
6. differential runtime corpus;
7. generate `.d.ts` from interface information;
8. propagate source provenance for `.js.map`;
9. compile compiler corpus through direct JS;
10. switch fixed-point authority only after differential gates close.

### Gates

```text
check:backend-js-dependencies
test:backend-js-unit
test:backend-js-differential
test:backend-js-runtime-edge-cases
test:dts-interface
test:source-map-provenance
fixed-point:direct-js
```

### Exit criterion

Subsequent self-host generations no longer require TypeScript/tsc in the canonical path.

## 8. Phase F — Wasm self-host and strongest executable assurance

### Work

- normalize backend-wasm source to the proven self-host implementation discipline;
- remove unnecessary `Lower -> Binary` dependency;
- split lowering monolith only after source normalization;
- add external pinned Wasm validator;
- define WasmIR validation;
- build cross-backend JS/Wasm semantic corpus;
- start `VerifiedIR -> WasmIR` preservation work;
- later prove/validate WasmIR encoder.

### Exit criterion

Direct Wasm is independently self-hostable, externally validatable, and covered by the same runtime semantic corpus as JS.

## 9. Phase G — incremental query engine and CAS

### Goals

Generalize the current resident self-host cache into the project compiler/build engine.

### Work

- query keys and dependency graph;
- semantic result fingerprints;
- module interface hashes;
- local CAS/action cache;
- deterministic scheduler;
- metrics/trace format;
- parallel builds;
- cache corruption tests;
- later optional remote cache.

### Preserve

- semantic compiler purity;
- cold/oracle path;
- exact deterministic identities;
- fail-closed cache behavior.

### Exit criterion

Large projects rebuild only semantically invalidated work while cold builds remain canonical oracles.

## 10. Phase H — project/separate compilation contracts

### Work

- indexed module graph and reverse dependencies;
- canonical topological order;
- ModuleInterface-v1;
- interface versus implementation hashes;
- separate compilation artifacts;
- deterministic linker/composer;
- import/export/interface compatibility validation.

### Exit criterion

Implementation-only dependency changes can remain green downstream when interface identity is unchanged.

## 11. Phase I — hermetic toolchains, lockfile, package manifests

### Work

- `ToolchainManifest-v1`;
- `psc.lock`;
- semantic package manifest;
- `--locked`;
- `--offline`;
- `--hermetic`;
- declared environment inputs;
- deterministic path/locale/time policy;
- toolchain digests.

### Exit criterion

A release build has no undeclared PATH/environment/network dependency.

## 12. Phase J — InterfaceIR, capabilities, and safe extensibility

### Work

- InterfaceIR-v1;
- capability vocabulary;
- WIT adapter;
- `.d.ts` adapter;
- Rust/native interface adapters;
- plugin manifest;
- isolated plugin RPC;
- Wasm Component/WASI sandbox path;
- safe reflection/Meta APIs.

### Rule

Implement capabilities before arbitrary third-party semantic plugin execution.

### Exit criterion

Third-party extension code cannot obtain undeclared host authority or kernel admission authority.

## 13. Phase K — production CLI, diagnostics, and service API

### Work

- structured Diagnostic-v1;
- stable compiler service;
- production `psc check/build/run/test/package/publish/verify/doctor`;
- LSP on compiler service;
- machine JSON protocol;
- telemetry only if explicit/opt-in and outside semantic behavior.

### Exit criterion

Tooling does not reimplement semantic truth.

## 14. Phase L — release provenance and registry security

### Work

- EvidenceManifest-v1;
- reproducible release matrix;
- SBOM;
- SLSA/in-toto provenance;
- public signatures/transparency;
- TUF-style registry/update metadata;
- independent rebuild verification;
- Lean/reference diverse-bootstrap route.

### Exit criterion

Users can verify not only “this package has a hash” but its declared source/build/toolchain/kernel/backend provenance.

## 15. Phase M — formal assurance growth

Use the existing P0-P16 vocabulary.

Recommended order:

1. real kernel admission;
2. executable semantics for a small CheckedCore/VerifiedIR slice;
3. erasure preservation;
4. mandatory IR-pass preservation/validators;
5. Wasm lowering;
6. Wasm encoder;
7. JS lowering;
8. JS emitter;
9. runtime primitive refinements;
10. whole-pipeline composition;
11. compiler implementation refinement;
12. verified self-compilation;
13. reproducible fixed point;
14. DDC/diverse bootstrap;
15. separate compilation/linking;
16. compact proof/build evidence verification.

Prefer a small proved profile that grows monotonically over a huge unsupported proof plan.

## 16. Performance work order

Do performance work where it preserves architecture.

### Early

- query graph;
- content-addressed source/IR/backend artifacts;
- interface-based invalidation;
- deterministic parallel scheduling;
- environment/instance indexes;
- reverse-accumulator/builders for large emitters;
- memory/timing metrics.

### Later

- specialization caching;
- target peepholes;
- aggressive inlining/fusion;
- profile-guided optimization.

Complex optimizers should be untrusted and accepted through a smaller validator where feasible.

## 17. Security work order

Before public ecosystem growth:

1. CompilationBudget;
2. bounded bridge decoders;
3. semantic lockfile;
4. package digests;
5. capability vocabulary;
6. plugin isolation;
7. hermetic release builds;
8. provenance/signing;
9. registry compromise-recovery.

## 18. Backend strategy

Target roles:

| Backend | Role |
| --- | --- |
| direct JS | canonical npm/JS runtime + bootstrap |
| direct Wasm | canonical portable/high-assurance backend |
| Lean | reference/native/provenance adapter |
| Rust | production systems/native adapter |
| TypeScript | ecosystem/debug/differential oracle |
| Rust->Wasm | alternative Wasm implementation |

Do not make all backends bootstrap dependencies.

## 19. Immediate next architecture implementation candidates

The highest-value code changes after documentation are:

1. define the real CheckedCore/provider API shape without switching authority prematurely;
2. design ErasedIR -> VerifiedIR validator and inventory every current `unknown`;
3. move backend-ts/backend-rust compiler adapters out of backend core packages;
4. write RuntimeSemantics-v1 for the currently implemented primitive set;
5. start the smallest direct-JS IR differential slice;
6. normalize backend-wasm source using the same generic self-host profile approach;
7. prototype ModuleInterface hashes on the existing project graph;
8. extend resident red/green caching to a general query-key model.

## 20. Change discipline

For each phase:

```text
design/contract
    ->
small implementation slice
    ->
focused RED/GREEN tests
    ->
generic invariant gate
    ->
cold/differential oracle
    ->
full relevant fixed point/release gate
    ->
commit/push checkpoint
```

Do not return to feature-by-feature repair hunting.
