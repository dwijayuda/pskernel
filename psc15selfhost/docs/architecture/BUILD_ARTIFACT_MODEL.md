# ProofScript build and artifact model

**Status:** forward build-system and artifact-identity design. It extends the current deterministic self-host/cache work without changing PSC semantics.

## 1. Design principle

Separate two layers:

```text
PURE / SEMANTIC
--------------------------------
parse
resolve
elaborate
kernel admission
erasure
IR validation
semantic lowering
target lowering

same explicit inputs -> same canonical outputs


HOST / BUILD
--------------------------------
filesystem
package resolution
incremental query graph
content-addressed store
remote cache
parallel scheduler
toolchain processes
network registry
signing/publishing
LSP worker
```

The host may become sophisticated and highly optimized without becoming semantic authority.

## 2. Canonical artifact classes

Production compilation should materialize explicit artifact classes.

| Artifact | Purpose |
| --- | --- |
| SourceArtifact | canonical source/module identity |
| CandidateCoreArtifact | elaborated kernel-facing semantics |
| CheckedCoreArtifact | kernel-admitted semantic artifact |
| ErasedIrArtifact | executable construction/runtime IR |
| VerifiedIrArtifact | validated target-neutral executable IR |
| ModuleInterfaceArtifact | exported semantic interface |
| InterfaceIrArtifact | foreign/API interface contract |
| JsIrArtifact | restricted JS target program |
| WasmIrArtifact | Wasm target program |
| ExecutableArtifact | emitted JS/Wasm/native-adapter output |
| EvidenceManifest | provenance and assurance binding |

Each class has an explicit schema/contract version.

## 3. Domain-separated identities

Do not use a naked digest as an untyped identity.

Conceptually:

```text
ArtifactId =
  SHA256(
    "proofscript:" +
    artifactKind + ":" +
    schemaVersion + "\0" +
    canonicalBytes
  )
```

Examples:

```text
proofscript:checked-core:v1
proofscript:verified-ir:v1
proofscript:module-interface:v1
proofscript:js-ir:v1
proofscript:wasm-ir:v1
proofscript:build-action:v1
```

Hash algorithms may evolve only through explicit artifact/profile versioning.

## 4. Canonical serialization

Persistent semantic identities require canonical bytes.

Requirements:

- exactly one canonical field/order representation;
- schema version in the domain/encoding;
- bounded decoder;
- deterministic number/string encoding;
- stable name/path normalization;
- no host pointer/object identity;
- no locale/timezone/current-directory dependence;
- no map iteration-order dependence;
- explicit rejection of duplicate or non-canonical encodings where relevant.

JSON may remain a human/debug form. A compact canonical binary representation can be introduced later for performance.

Resident generated-compiler objects remain in-memory only; do not persist runtime symbol-tag object graphs as semantic artifacts.

## 5. Incremental query graph

Generalize the current resident red/green self-host cache into a reusable build engine.

Conceptual nodes:

```text
SourceBytes
   |
   v
Parse
   |
   v
Resolve
   |
   v
Elaborate
   |
   v
CandidateCore
   |
   v
KernelCheck
   |
   v
CheckedCore
   |
   v
Erase
   |
   v
ValidateRuntimeIr
   |
   v
VerifiedIR
   |
   +--> Specialize --> JsIR --> JS
   |
   +--> Specialize --> WasmIR --> Wasm
```

Each query records:

```text
QueryKey
input artifact IDs
dependency query IDs
semantic options/profile
result artifact ID
result semantic fingerprint
timing/resource metrics
```

If a changed input recomputes to the same semantic artifact/fingerprint, downstream nodes stay green.

## 6. Content-addressed store

Use a local CAS first; remote cache later.

Concept:

```text
CAS/
  objects/<algorithm>/<digest>
  metadata/<artifact-id>
```

Rules:

- immutable objects;
- verify content digest when reading untrusted storage;
- atomic writes;
- duplicate-safe;
- corruption = cache miss/recompute, never semantic fallback;
- garbage collection is separate from correctness.

The action cache maps a deterministic action identity to output artifact IDs. The CAS stores bytes.

## 7. Build actions

A build action must include every input that can affect its output.

Conceptual model:

```text
BuildAction {
  actionKind
  compilerIdentity
  languageEdition
  semanticContractVersions
  inputArtifactIds
  dependencyInterfaceIds
  options
  targetProfile
  runtimeAbi
  toolchainIdentity
  capabilityWorld
  declaredEnvironment
}
```

```text
ActionId = H(canonical BuildAction)
```

Ambient host state is not an implicit input in hermetic mode.

## 8. Hermetic versus developer modes

### Developer mode

May discover convenient local tools:

- PATH;
- node_modules;
- local editor/runtime configuration.

It must report discovered identities and must not claim release reproducibility.

### Hermetic mode

```text
psc build --locked --hermetic
```

Requirements:

- pinned toolchain manifest;
- locked dependencies;
- declared environment only;
- canonical locale/timezone where host tools need them;
- stable paths or path remapping;
- no undeclared network;
- no undeclared process/tool;
- deterministic input ordering.

### Offline release verification

```text
psc build --locked --hermetic --offline
```

should be a supported release/verification workflow.

## 9. Toolchain manifest

External tools remain explicit inputs.

Concept:

```text
ToolchainManifest {
  lean: {
    version/commit
    artifactHash
  }
  node: {
    version
    artifactHash/platform
  }
  typescript?: {
    version
    launcherHash
    compilerHash
  }
  rust?: {
    version
    target
    rustcHash
  }
  wasmValidator?: {
    version
    artifactHash
  }
}
```

Current PATH/tool discovery is acceptable bootstrap/dev behavior, not the final release contract.

## 10. Module interfaces and separate compilation

Every checked module should eventually produce two identities:

```text
implementationHash
interfaceHash
```

A `ModuleInterface` includes downstream-relevant semantics:

- exported names and types;
- public inductive/structure layout contract where observable;
- instances that affect downstream synthesis;
- relevant theorem/declaration identities;
- required capabilities;
- runtime ABI requirements;
- imported interface identities.

If implementation changes but interface identity stays stable, downstream elaboration need not invalidate.

## 11. Project graph

The current list-based portable graph is a good bootstrap implementation.

Production build planning should add host-side indexes:

```text
moduleByName
importsByModule
reverseDependencies
inDegree
deterministicReadyQueue
```

The planner should be approximately `O(V + E)` and support parallel execution, while maintaining a canonical ready-order tie break so scheduling does not affect semantic/build identities.

## 12. Semantic lockfile

`psc.lock` should pin more than versions.

Per dependency:

```text
packageId
version
source
sourceHash
semanticManifestHash
moduleInterfaceHash
language/profile requirements
Core/kernel/IR contract requirements
capability requirements
toolchain requirement when relevant
```

Rules:

- locked build never upgrades silently;
- source digest mismatch rejects;
- semantic-manifest mismatch rejects;
- incompatible contract versions reject;
- offline locked builds do not contact the registry.

## 13. Semantic package manifest

Package metadata should record:

```text
package ID/version
language edition/profile
Core contract
kernel contract
CheckedCore contract
VerifiedIR contract
InterfaceIR/plugin contracts if used
supported targets
required capabilities
exported module interface identities
runtime ABI requirements
proof/evidence references
```

Use one authoritative schema. `package.json` may embed a `proofscript` reference, but semantic identity should not depend on arbitrary npm metadata ordering.

## 14. Release evidence

A release/build evidence manifest should bind the actual pipeline:

```text
sourceHash
dependencyLockHash
compilerSourceHash
compilerExecutableHash
candidateCoreHash
checkedCoreHash
verifiedIrHash
backendIdentity
targetIrHash
outputHash
kernelIdentity
runtimeSemanticVersion
toolchainManifestHash
validator/proof identities
external assumptions
```

This is not itself a semantic theorem. It binds actual artifacts to the theorem/validator identities and assumptions used.

## 15. Provenance and signing

Recommended outer wrappers:

- in-toto/SLSA-style provenance for source/build statements;
- SBOM for dependencies/toolchain components;
- public signature/transparency system for releases;
- role-separated registry/update metadata for compromise recovery.

Keep PSC's semantic evidence manifest small and domain-specific; use standard supply-chain envelopes for the outer ecosystem.

## 16. Remote cache security

A remote cache is untrusted storage.

For every hit:

1. identify expected `ActionId`;
2. receive output artifact IDs;
3. fetch CAS objects;
4. recompute content digest;
5. reject mismatch;
6. validate schema where applicable;
7. use only verified bytes.

Never treat “remote cache says this hash is X” as sufficient evidence.

## 17. Build reproducibility classes

Distinguish:

### Semantic reproducibility

Same explicit semantic input -> same canonical Core/IR/target IR.

### Artifact reproducibility

Same frozen host/toolchain inputs -> identical emitted artifact according to target policy.

### Self-host fixed point

Generation N and N+1 reproduce the canonical compiler artifact.

### Diverse bootstrap evidence

An independent trusted route provides provenance evidence against trusting-trust attacks.

Do not collapse these into one “reproducible” Boolean.

## 18. Performance metrics

Track per-query/action:

```text
wall time
CPU time where available
peak memory
input bytes
output bytes
cache state: cold/miss/hit/green
dependency count
artifact IDs
```

Performance regressions become observable without changing semantic code.

## 19. Anti-drift rules

1. Cache keys include all semantic/tool inputs.
2. mtime is never semantic identity.
3. corrupted caches recompute; they never fall back semantically.
4. scheduling order cannot affect canonical outputs.
5. production release builds have no ambient undeclared tool discovery.
6. module interface identity, not implementation timestamp, drives downstream invalidation.
7. persistent artifact formats are canonical and versioned.
8. resident runtime-object caches are optimization only and remain disposable.

## 20. Observed Rust source route

The checked builder accepts `--backend rust --products source --out module.rs`
(or `metadata`) with a generated compiler exposing
`psCompilerRustStagesFromPrepared` or an explicitly selected native seed supporting
`psc-checked-seed-products/3`. One prepared source supplies the actual
erasure, strict validation and source-emission snapshots. The existing Rust
source backend preserves generic RuntimeIR; moving to SpecializedIR is an
explicit migration obligation, not an invented pass in this graph.

The source product uses `rust-source / psc-rust-source/2021`. Its descriptor,
bundle, action/query identities, archive and evidence envelope follow the common
publication path. The inherited bundle group `executableArtifacts` includes
the `target-source` role, so its name does not mean that Rust was compiled.
Only source bytes are published; compiler acceptance, native binary output,
hermeticity and global preservation are not established. The native Rust protocol binds the same source-product contract, requires exactly
two bounded frames and pins its version/profile in every response. Existing bootstrap Cargo tests remain
separate observations.

The subsequent native-toolchain step must bind source, Cargo manifest and lock,
exact toolchain/target, dependencies, flags and observed environment. Cargo's
[`--locked`, `--offline`, and `--frozen`](https://doc.rust-lang.org/cargo/commands/cargo-build.html)
have distinct meanings: a lock prevents resolution changes; offline prohibits
network but can change available resolution; frozen combines both. None alone
proves a complete isolated input closure. A pinned version or successful
[`rustc` invocation](https://doc.rust-lang.org/rustc/command-line-arguments.html)
does not prove ProofScript semantic preservation.

## 21. Wasm Unit value and result boundaries

The private Wasm representation uses an `i32` token for source Unit values in
parameters, locals, captures, aggregate fields and arrays. Existing Unit
function results, including Canonical scalar exports, retain zero Wasm results.
An expression is a value producer even when its source type is Unit.

Lowering therefore bridges these representations explicitly: source calls with
a Unit result reify a zero token after the call; source function/lambda bodies
produce a token and discard it at the ABI return. Direct calls use the declared
parameter types, matching closure calls. The generated array-map/fold callbacks
apply the same result bridge. No callback, argument or discarded let value may
be skipped: it can diverge or trap.

The return bridge distributes the final discard through tail conditional arms,
retaining preceding work and dropping exactly the arm's final token. A final
constant token can be removed directly. This leaves void calls in tail position
for the existing tail-call pass; it does not promote a value-producing call
whose result is still dropped. The exact emitted WasmIR and engine validation
remain required. Canonical Unit parameters remain unsupported in the scalar
interop profile, independently of this private representation.

This follows the [Core 3.0 instruction stack rules](https://webassembly.github.io/spec/core/valid/instructions.html)
and [execution rules](https://webassembly.github.io/spec/core/exec/instructions.html)
reviewed on 2026-10-08. Focused execution covers Unit calls, control flow,
storage, closures, array callbacks, trap retention and deep tail recursion.
These observations do not establish global lowering preservation or validator
soundness.

## 22. Independent claim policies at artifact consumption

The bundle, observed-context and archive verification APIs accept the same
optional `claimVerification` selection and `claimPolicy` artifact.
`claimVerification` contains only consumer-selected checker functions keyed by
exact implementation identity and the allowed claim assumptions. A policy
requires explicit verification configuration and is a bounded canonical
`psc-claim-policy/1` nonempty conjunction. It matches exact subjects, profile
environment, resource policy, evidence class and checker identities.

A shared capture function snapshots checker choices, assumption lists and policy
bytes before the first resolver or checker callback. Archive pass assumptions
are captured separately, so claim callbacks cannot expand the independently
selected pass policy. Archived data cannot supply executable checker code or
select a more permissive policy. All claim references are resolved and rehashed;
each selected checker must return acceptance for the exact expected assertion.
A missing checker, denied assumption, mismatched response or unsatisfied policy
rejects consumption. A legacy archive without V5 context also rejects a request
for claim verification instead of silently ignoring it.

Results retain exact verified-claim counts and the selected policy decision
inside the bundle result (`buildContext.artifactBundle` for archives). These are
audit records, not live compiler/release capabilities. A scoped claim decision
does not change the archive's global semantic, preservation, hermeticity or
release fields. Without a claim request, historical integrity-only behavior is
preserved. Production builders continue to emit an empty ClaimSet until actual
evidence adapters exist; an empty set cannot satisfy a nonempty policy.

Focused fixtures exercise the complete archive-to-checker path, identity and
assumption mismatches, callback mutation and legacy behavior. Their checkers are
explicit test doubles. Production checker adapters, command-line selection of
a trusted checker registry, real evidence production and an assured-release
policy remain implementation obligations; no preservation theorem is asserted.

## 23. Direct JavaScript declaration maps

The JavaScript builder's `--products declaration-map` and `all` selections
publish a standalone `.d.ts.map` plus declaration-position and replay-recipe
artifacts. They require the same source declarations already compared with the
portable writer and a complete captured source-origin table. Missing required
products reject the build. The native protocol stays unchanged: its existing
metadata/declaration selection carries the required source evidence.

The source-signature writer records its actual declaration/export chunk
positions. The map composer reconstructs source signatures, export bindings
and OriginGraph, then composes optional original-source preparation. JavaScript
and declaration maps share UTF-16 conversion, original-source reconstruction
and unmapped line-boundary handling. Original declaration, executable and
historical map identities are preserved by this extraction.

[TypeScript's declaration-map option](https://www.typescriptlang.org/tsconfig/declarationMap.html)
supports navigation back to original source. Its
[pinned declaration emitter](https://raw.githubusercontent.com/microsoft/TypeScript/v5.9.3/src/compiler/emitter.ts)
uses a distinct declaration printer and a shared map-writing path. PSC follows
that separation while retaining source PublicApiIR as the signature owner.
[ECMA-426](https://tc39.es/ecma426/) supplies the map encoding and coordinate
conventions. These references were reviewed on 2026-10-08.

The current map is deliberately coarse: declaration and export lines map to
their source declaration anchor; terminators, synthetic output and absent
origins remain unmapped. It does not claim token/type-expression correspondence.
Maps embed the captured original text when preparation evidence is supplied.
URL annotation is a separate packaging obligation, so existing declaration
bytes remain unchanged and automatic editor discovery is not claimed.

New products use registry snapshot V2 and uniform derivation/4. V1 snapshots
and earlier derivations remain readable with their original derivation rules.
The common graph records the map pass, bundles identify all three products,
and archive readers reconstruct them against independently pinned parents.
Successful map replay remains debug metadata, not semantic preservation.

## Opt-in direct-JS source-map linking (V5.1)

`--backend javascript --products linked` selects the existing source/declaration
map closure, then an explicit packaging pass. Both standalone ECMA-426 maps
retain their original unlinked printer/declaration positions. Original `.js`
and `.d.ts` bytes are archived without modification; linked outputs have
separate ArtifactIds and trailing unmapped `//# sourceMappingURL=` directives.
The graph publishes linked output files and retains map/recipe evidence;
the independent archive consumer recomputes both linked identities from four
original products and refuses mismatched filenames or changed bytes.
Existing modes and V1/V2 registries retain historical output identities.
Only V3 and uniform derivation/5 select linking. A link is developer metadata,
not a proof of target preservation, IDE navigation, reproducibility or DDC.
