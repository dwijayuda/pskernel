# PSCV Compiler Reference

**Status:** canonical compiler architecture reference for the current ProofScript / PSCV implementation line.

**Repository:** dwijayuda/pskernel  
**Canonical implementation branch at adoption:** psc2/selfhost-lean-kernel  
**Adoption baseline:** 304706da6d3775a716561870110b7e7f5b46ac03  
**Document role:** architecture reference, authority-boundary reference, implementation guide, and anti-drift contract.  
**Language semantics:** defined elsewhere by the applicable PSCV / ProofScript language and semantic-profile contracts.  
**Kernel semantics:** defined by the applicable kernel contracts and provider-specific semantic authority.  
**SAVEF role:** SAVEF extends and indexes the compiler architecture described here; it does not create a parallel compiler architecture.

---

# 1. Purpose

This document defines the canonical architecture of the PSCV compiler and its relationship to:

- the ProofScript source language;
- the owned PSCV frontend;
- CandidateCore and kernel admission;
- KernelContract-v1;
- process-local checked authority;
- erasure and executable IR validation;
- target-neutral specialization;
- TypeScript, JavaScript, WebAssembly, and Rust backends;
- self-host and fixed-point workflows;
- the project QueryGraph and artifact model;
- Lean as a pinned reference/bootstrap compiler;
- PSKernel as the long-term owned kernel authority;
- SAVEF knowledge extraction and self-application.

The principal rule is:

> **Evolve the current semantic spine by enforcing its intended authority and pass boundaries. Do not build a second compiler architecture beside it.**

The repository already contains most major production concepts. The highest-value work is to make those concepts impossible or difficult to bypass, expose reusable semantic passes explicitly, and attach evidence and SAVEF knowledge to existing artifact and contract boundaries.

---

# 2. Authority and document hierarchy

When architecture documents, old research plans, implementation comments, tests, and live code disagree, interpret them in this order.

1. **Frozen machine-readable contracts and normative language/kernel profiles**
2. **Current implementation behavior at the selected repository revision**
3. **This PSCV Compiler Reference**
4. **Current production architecture documents under psc15selfhost/docs/architecture**
5. **Implementation roadmaps and ADRs**
6. **SAVEF research plans and study documents**
7. **Historical branch notes, experiments, and prior conversation summaries**

This document may prescribe a stronger target than current code, but it must clearly distinguish:

- **IMPLEMENTED**
- **IMPLEMENTED BUT NOT FULLY ENFORCED**
- **TESTED EVIDENCE**
- **PLANNED**
- **RESEARCH**
- **DEPRECATED / HISTORICAL**

A planned architecture diagram is not implementation evidence.

A test passing is not a proof.

A self-host fixed point is not compiler correctness.

A provider-parity corpus is not universal semantic equivalence.

A hash, Git commit, npm package, OCI object, or provenance record is not semantic truth.

---

# 3. Core architectural principles

## 3.1 Small semantic authority

Large components may propose semantic objects.

Small authorities decide what is accepted.

The intended chain is:

~~~text
untrusted source / tools / AI
        |
        v
frontend proposal
        |
        v
CandidateCore
        |
        v
KernelContract
        |
        v
checked authority
        |
        v
erasure / validated compiler passes
        |
        v
target artifact
~~~

No parser, elaborator, tactic, AI agent, optimizer, backend, package manager, cache, registry, or build system receives theorem-admission authority merely because it is useful.

---

## 3.2 Bootstrap closure and authority are different concerns

The minimal self-host compiler closure should remain small.

The kernel implementation does **not** need to be inside that compiler closure.

The correct separation is:

~~~text
generated self-host compiler
    proposes prepared / candidate semantic material

host composition
    invokes a selected kernel provider

checked capability
    authorizes certified downstream production steps
~~~

This preserves bootstrap practicality while still requiring real kernel admission in production assurance paths.

---

## 3.3 Fail closed

Unsupported semantics must reject.

Forbidden behavior:

~~~text
unsupported case
    ->
silent weaker translation
or
automatic fallback provider
or
different semantic interpretation
~~~

Required behavior:

~~~text
unsupported case
    ->
explicit rejection
~~~

Resource exhaustion is failure, not semantic success.

A failed provider does not automatically select another provider.

---

## 3.4 Target-neutral semantics before target policy

Portable compiler phases must not absorb:

- JavaScript object-layout policy;
- TypeScript emitter conveniences;
- Rust ownership or Rc representation details;
- WebAssembly opcodes or memory layout;
- WIT/WASI ABI details;
- npm behavior;
- operating-system capabilities.

Target-specific representation begins only at the appropriate target pass.

---

## 3.5 Explicit semantic passes

A transformation with reusable semantic meaning should be an explicit compiler pass.

Examples:

~~~text
KernelCheck
Erase
ValidateRuntimeIr
Specialize
JsLower
WasmLower
RustLower-or-Emit
TsLower-or-Emit
~~~

Pass ownership is determined by semantic scope:

~~~text
target-neutral transformation
    -> shared compiler pass

target-specific representation transformation
    -> target backend pass
~~~

The same target-neutral transformation must not be independently hidden inside multiple target backends in the certified path.

---

# 4. Canonical current compiler spine

At adoption baseline 304706da..., the bounded semantic compiler spine remains:

| Package | Lean modules | Approx. source lines |
| --- | ---: | ---: |
| foundation | 4 | 203 |
| syntax | 12 | 8,207 |
| core | 8 | 910 |
| environment | 7 | 2,091 |
| meta | 6 | 1,976 |
| elab | 4 | 4,792 |
| bridge | 4 | 2,643 |
| compiler-ir | 2 | 2,915 |
| erasure | 6 | 3,747 |
| compiler | 2 | 294 |
| **Total** | **55** | **27,778** |

The 55-module number refers to this bounded semantic compiler spine.

It must not be used as the module count for every direct self-host target closure.

For example, the direct JavaScript whole-compiler workflow at this baseline reports a 56-source generated closure because it additionally includes direct-backend, driver, and composition-root material.

---

# 5. Current implementation truth

## 5.1 Pure compiler path — IMPLEMENTED

The live pure compiler currently behaves approximately as follows:

~~~text
source
  |
  v
Ps.Compiler.Api
  |
  +--> parse Lean / ProofScript
  |
  v
PsSyntaxModule
  |
  v
owned elaborator
  |
  v
PsElabModuleResult
  |
  v
psCompilerPrepareElaborated
  |
  | canonical CheckedAdmissions encoding succeeds
  v
PsCompilerAdmissionReadyModule
  |
  v
environment reconstruction
  |
  v
erasure
  |
  v
PsErasedIrModule
  |
  v
psValidateErasedIrModule
  |
  v
PsValidatedIrModule
  |
  +--> backend-ts
  +--> backend-js
  +--> backend-wasm
  +--> backend-rust
~~~

This path is useful and self-hostable.

It is **not yet a fully enforced checked production authority path**.

---

## 5.2 AdmissionReady meaning — IMPLEMENTED

PsCompilerAdmissionReadyModule means, approximately:

~~~text
elaborated declaration batch
+
canonical admissions codec successfully encodable
~~~

It does **not** mean:

~~~text
kernel admitted
~~~

The type name is honest.

Any API or documentation that treats AdmissionReady as CheckedCore is wrong.

---

## 5.3 Misleading Check aliases — IMPLEMENTED, SHOULD BE CORRECTED

The pure compiler currently has aliases equivalent to:

~~~text
psCompilerCheckElaborated
=
psCompilerPrepareElaborated

psCompilerCheckSource
=
psCompilerPrepareSource
~~~

These names must not be interpreted as kernel checking.

Long-term options:

1. deprecate or rename them to preparation terminology; or
2. redefine Check to mean real KernelContract-mediated acceptance.

Until that change is complete, architecture and tooling must treat them as preparation APIs.

---

# 6. Kernel authority

## 6.1 KernelContract-v1 — IMPLEMENTED AND FROZEN

Current machine identity:

~~~text
proofscript-kernel-contract/1
~~~

The contract separates:

- canonical admissions protocol;
- provider selection;
- acceptance decision semantics;
- fail-closed behavior;
- checked-session capability semantics;

from the concrete provider implementation.

The compiler must depend on this provider-neutral contract rather than on one concrete kernel binary.

---

## 6.2 Provider policy at adoption

Current production-hardening policy:

~~~text
default:
    lean434-wasm
    @proofscript/pskernel-lean-wasm

explicit reference:
    lean434 native

explicit owned candidate:
    pskernel-core

historical / archived:
    pskernel-core.old3
    pskernel-core.old2
~~~

The default must not silently change because an alternative provider becomes available.

Provider promotion requires a separate explicit architecture/release decision and evidence appropriate to the intended workload.

---

## 6.3 Host checked session — IMPLEMENTED

The host checked-session path already provides a strong process-local authority discipline.

Canonical behavior:

1. prepare source once;
2. freeze the prepared object graph;
3. derive canonical admissions;
4. validate the KernelContract-v1 envelope;
5. invoke exactly one selected provider;
6. validate provider identity and decision;
7. create a non-transferable process-local checked handle;
8. permit emission only through that handle;
9. rederive admissions from the same prepared value before emission;
10. reject if the payload changed.

This is the repository's current concrete basis for a CheckedCore-style capability.

---

## 6.4 CheckedCore has three distinct meanings

Do not conflate:

### A. CheckedCore semantic concept

A kernel-admitted semantic program/module.

### B. CheckedCore authority capability

A process-local capability proving that the host accepted a specific prepared semantic object through the configured KernelContract.

### C. CheckedCore audit artifact / receipt

A serializable record of what was checked, by whom, under which identities.

Only B grants runtime authority in the current host design.

A serialized receipt is evidence, not a transferable checked capability.

---

# 7. Highest-priority authority gap

## 7.1 Current bypass — IMPLEMENTED BUT ARCHITECTURALLY WRONG FOR PRODUCTION

Today the pure compiler can perform:

~~~text
PsCompilerAdmissionReadyModule
    ->
psCompilerErasedIrFromPrepared
    ->
PsErasedIrModule
    ->
psValidateErasedIrModule
    ->
PsValidatedIrModule
    ->
backend
~~~

without a kernel-issued checked capability.

All four current target driver families can reach compilation through prepared state.

Therefore the authority problem is common to the compiler/driver architecture, not limited to TypeScript.

---

## 7.2 Required target

Production composition must become:

~~~text
source
  |
  v
frontend / elaboration
  |
  v
CandidatePrepared
  |
  v
KernelContract-v1
  |
  v
CheckedPreparedCapability
  |
  +----------------------+
  |                      |
  v                      v
ModuleInterface      Erase
                         |
                         v
                     RuntimeIR
~~~

The kernel implementation remains outside the small compiler bootstrap closure.

The checked capability is the gate.

---

## 7.3 Internal and bootstrap paths

Unchecked preparation and erasure may remain available where explicitly required for:

- bootstrap construction;
- differential tests;
- internal compiler testing;
- research;
- controlled diagnostics.

Such APIs must be named and documented as unchecked/internal.

They must not be the default production compiler service route.

---

# 8. Executable IR architecture

## 8.1 Current raw model

The current raw node family is named PsVerifiedIr*.

Historically this name predates the current wrapper staging.

The raw type family still contains construction-level forms such as:

~~~text
unknown
typeParameter
~~~

Therefore the raw node family itself must not be treated as proof that values are validated.

---

## 8.2 Current wrappers — IMPLEMENTED

The current useful staging wrappers are:

~~~text
PsErasedIrModule
PsValidatedIrModule
~~~

Current validation:

~~~text
PsErasedIrModule
    |
    v
psValidateErasedIrModule
    |
    v
PsValidatedIrModule
~~~

The validator already checks important properties including:

- resolved runtime types;
- structural references;
- known structures;
- known inductives;
- known constructors;
- field existence;
- type-argument arities;
- machine-integer literal validity;
- other runtime/reference constraints implemented by the current validator.

This wrapper architecture should be strengthened before any expensive physical rewrite of the raw IR node family.

---

## 8.3 Canonical target phase naming

Conceptually:

~~~text
CheckedCoreCapability
    |
    v
Erase
    |
    v
RuntimeIR
    |
    v
ValidateRuntimeIr
    |
    v
VerifiedIR
    |
    v
Specialize
    |
    v
SpecializedIR
~~~

Initial implementation mapping:

~~~text
RuntimeIR
    ~= PsErasedIrModule

VerifiedIR
    ~= PsValidatedIrModule

SpecializedIR
    = new explicit wrapper/capability
~~~

A full renaming of all PsVerifiedIr* raw AST types is **not** an early requirement.

---

# 9. SpecializedIR

## 9.1 Current specialization implementation — IMPLEMENTED

The repository already has a shared target-neutral specialization implementation in:

~~~text
psc15selfhost/packages/compiler-ir/src/Ps/CompilerIr/Specialize.lean
~~~

Current public shape is approximately:

~~~text
psIrSpecializeModule :
    PsVerifiedIrModule ->
    Except PsIrSpecializeError PsVerifiedIrModule
~~~

The algorithm exists.

The missing architecture is the typed phase boundary.

---

## 9.2 Required target

Introduce:

~~~text
PsSpecializedIrModule
~~~

and an authoritative API:

~~~text
PsValidatedIrModule
    ->
specialize
    ->
PsSpecializedIrModule
~~~

The specialized wrapper establishes at least:

- reachable executable types are ground where required;
- specialization requests are resolved or rejected;
- generated specialization names are deterministic;
- references remain closed under the pass;
- no unresolved generic obligation silently reaches target lowering.

Exact invariants must be versioned and machine-checkable.

---

# 10. Backend phase ownership

## 10.1 Rule

A backend declares the earliest compiler phase it consumes.

Do not force every backend through SpecializedIR if the backend intentionally supports generic/runtime forms directly.

Uniformity is not a substitute for semantic necessity.

---

## 10.2 Direct JavaScript

Current surface at adoption:

~~~text
backend-js
    3 Lean modules
    ~3,293 lines

driver-js
    1 Lean module
    ~199 lines
~~~

Current JS lowering can invoke shared specialization internally.

The direct JS self-host driver also exposes an explicit specialization step.

Target certified path:

~~~text
VerifiedIR
    ->
Specialize/1
    ->
SpecializedIR
    ->
JsLower
    ->
JsIR
    ->
ValidateJsIR
    ->
canonical JS emitter
~~~

Specialization must not remain hidden inside certified backend lowering.

---

## 10.3 Direct WebAssembly

Current surface:

~~~text
backend-wasm
    12 Lean modules
    ~10,142 lines

driver-wasm
    1 Lean module
    ~181 lines
~~~

Current Wasm lowering also invokes shared specialization internally.

Target certified path:

~~~text
VerifiedIR
    ->
Specialize/1
    ->
SpecializedIR
    ->
WasmLower
    ->
WasmIR
    ->
ValidateWasmIR
    ->
canonical Wasm encoder
~~~

Direct Wasm remains an independent PSC-owned backend.

It must not be defined by routing through JavaScript or Rust.

---

## 10.4 TypeScript

Current surface:

~~~text
backend-ts
    3 Lean modules
    ~1,513 lines

driver-ts
    1 Lean module
    ~39 lines
~~~

TypeScript remains a valuable bootstrap and oracle route.

Its backend includes target-specific semantic/representation transformations such as:

- eta application rewriting;
- tail-recursion / loop recognition;
- stack-safety machinery.

These are not automatically shared compiler passes.

They remain backend-local unless the transformation is proven to be target-neutral and reusable.

Backend-local semantic transforms still require clear preservation or validation obligations in high-assurance modes.

---

## 10.5 Rust

Current surface:

~~~text
backend-rust
    6 Lean modules
    ~3,450 lines

driver-rust
    1 Lean module
    ~100 lines
~~~

Current Rust lowering/emission includes:

- value-reference rewriting;
- Rc closure representation policy;
- function-result shape analysis;
- fail-closed support boundaries for function-valued results.

Rust ownership, borrowing, lifetimes, Rc, Box, and ABI representation are target policy.

They must not leak into VerifiedIR or portable PSCV semantics.

---

# 11. Direct-backend evidence status at adoption baseline

This section records evidence status, not permanent semantics.

## 11.1 TypeScript

At baseline, the cloud workflow reached:

~~~text
PSC1_BACKEND_TS_TESTS: PASS
~~~

before later job cancellation.

This is tested evidence, not a preservation proof.

---

## 11.2 Direct JavaScript

At exact baseline 304706da..., current-head cloud evidence reached:

~~~text
JS unit corpus          PASS
JS differential         PASS

generation 1 compiler
    ->
generation 2 compiler completed
    ->
gen1 == gen2 comparison passed
    ->
generation 2 imported
    ->
generation 3 started
~~~

The workflow was later cancelled during generation-3 preparation because of the long-running cloud job.

Interpretation:

- direct JS semantic evidence is strong and improving;
- first generated-compiler equality is established in that run;
- a complete current-head generation-2/generation-3 fixed-point result was not recorded;
- resource/incremental compilation cost is a material issue.

Do not report a complete direct-JS fixed point until a run proves it.

---

## 11.3 Direct WebAssembly

At pre-Rust-fix head 1c10b475..., the following were green:

~~~text
IR specialization
erasure
Wasm backend corpus
Wasm runtime corpus
~~~

Whole-compiler emission failed at:

~~~text
lower.unsupported-expression:
psLexStringToListFromWithFuel:call-target
~~~

Commit 304706da... changed only Rust backend code.

Therefore that Wasm whole-compiler gap is not known to be repaired merely by adopting 304706da....

Treat it as a specific unresolved semantic/lowering/profile issue until retested and resolved.

---

## 11.4 Direct Rust

At 1c10b475..., the Rust semantic corpus exposed:

~~~text
reject conditional function results
~~~

Commit 304706da... restored the intended semantic boundary using:

~~~text
psRustDeclarationDirectFunctionResultSupported
psRustEmitFunctionResultExpr
~~~

while retaining the newer Rc closure support.

This is an architecture-correct fail-closed repair.

Complete direct-Rust whole-compiler and fixed-point evidence still requires a current-head rerun.

---

# 12. Self-host implementation profiles

## 12.1 PSC1-selfhost-stable/1 — IMPLEMENTED

The minimal bootstrap compiler uses a deliberately constrained implementation discipline.

It favors:

- explicit structural recursion;
- explicit fuel workers;
- simple match forms;
- explicit constructors;
- canonical recursive construction;
- small dependencies.

It forbids or avoids many Lean conveniences inside the bootstrap closure.

Purpose:

> Reduce late self-host surprises by making the implementation subset predictable.

---

## 12.2 Legacy repair guard rule

The self-host profile records the existing legacy repair guards and prevents uncontrolled growth of new one-off repair scripts.

Architectural rule:

> New self-host failures should become general source/profile/semantic invariants where possible, not new file-specific repair guards.

This rule must be preserved.

---

## 12.3 PSC1-portable-selfhost/1 — IMPLEMENTED

Portable non-bootstrap compiler/kernel/backend packages can opt into a broader but still controlled implementation profile.

It extends the stable discipline with generic structural rules.

This profile is the preferred mechanism for preventing repeated backend-specific self-host repair hunting.

---

# 13. Build and artifact model

SAVEF must reuse the existing build/artifact architecture.

## 13.1 Artifact identity

Existing production architecture already models artifacts such as:

~~~text
SourceArtifact
CandidateCoreArtifact
CheckedCoreArtifact
ErasedIrArtifact
VerifiedIrArtifact
ModuleInterfaceArtifact
InterfaceIrArtifact
JsIrArtifact
WasmIrArtifact
ExecutableArtifact
EvidenceManifest
~~~

New SAVEF-specific concepts must extend this system instead of introducing another content-identity universe.

---

## 13.2 BuildAction

Existing BuildAction already contains the right class of semantic inputs:

~~~text
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
~~~

SAVEF pass execution should build on this abstraction.

---

# 14. Compiler pass model

## 14.1 PassDefinition — TARGET

A static pass definition should describe:

~~~text
PassDefinition {
    passId
    inputPhase
    outputPhase

    requiredInvariantIds
    establishedInvariantIds

    semanticRelationId

    determinismPolicy
    resourcePolicy

    validatorIds
    evidenceRequirements
}
~~~

The exact syntax may differ.

The concept must not duplicate BuildAction.

---

## 14.2 Pass execution

A pass invocation is a BuildAction.

Conceptually:

~~~text
PassDefinition
    +
input ArtifactIds
    +
semantic/toolchain/profile identities
    +
options/resources
    =
BuildAction
    ->
result ArtifactId
~~~

Evidence attaches to either the static pass definition, the individual build action, or both.

---

## 14.3 EvidenceEnvelope

Evidence may include:

- proof theorem identity;
- translation validator identity;
- validation result;
- assumption closure;
- differential evidence;
- mutation-test result;
- provider/kernel identity;
- implementation identity;
- resource measurements.

Evidence does not replace semantic authority.

---

# 15. QueryGraph

## 15.1 Current QueryGraph — IMPLEMENTED

Current pure QueryGraph records approximately:

~~~text
name
sourceKey
interfaceKey
dependencyInterfaces
~~~

It can invalidate on:

~~~text
missingPrevious
sourceChanged
importsChanged
dependencyUnavailable
dependencyInterfaceChanged
~~~

Important current behavior:

~~~text
source changes
+
rebuilt interface remains equal
=
invalidation propagation may stop
~~~

This is a strong foundation.

---

## 15.2 Current interface key is conservative

Current host QueryGraph derives a module's interface key from canonical admission serialization of the module's own declaration batch.

This is intentionally conservative.

False-red rebuilds are acceptable.

False-green semantic reuse is not.

---

## 15.3 Do not build one giant QueryGraph-v2 record

Rejected target:

~~~text
one record containing optional:
    parsedKey
    elaboratedKey
    checkedCoreKey
    moduleInterfaceKey
    runtimeIrKey
    verifiedIrKey
    specializedIrKey
    target keys
    proof keys
    ...
~~~

Preferred target:

~~~text
ParseQuery
ElaborateQuery
KernelCheckQuery
ModuleInterfaceQuery
EraseQuery
ValidateRuntimeIrQuery
SpecializeQuery
JsLowerQuery
WasmLowerQuery
ProofQuery
KnowledgeQuery
~~~

Each node consumes typed ArtifactIds and dependency query identities.

This aligns QueryGraph with BuildAction and CAS.

---

# 16. ModuleInterface-v1

## 16.1 Reuse existing ModuleInterface architecture

SAVEF must not create an unrelated CertifiedModuleInterface universe.

First define a real ModuleInterface-v1 artifact.

It should capture downstream-observable semantics such as:

- exported declaration identities and types;
- transparency policy;
- canonical transparent bodies where downstream reduction requires them;
- opaque public specifications;
- public theorem/specification IDs;
- public assumption closure;
- relevant instance/order metadata;
- dependency interface IDs;
- source/semantic profile identities;
- required compiler/kernel contracts.

---

## 16.2 Certification is evidence

Conceptually:

~~~text
ModuleInterfaceArtifact
    +
AssuranceEnvelope
    =
certified/checked module-interface view
~~~

The same underlying semantic interface may have different evidence levels.

Certification metadata must not silently change the semantic identity being claimed.

---

# 17. Compiler service

Long-term tools must consume one semantic service rather than reimplementing type checking or resolution.

Candidate operations include:

~~~text
parse
resolve
elaborate
typeOf
goalState
candidateCore
admissionPayload
checkedCore
runtimeIr
verifiedIr
specializedIr
moduleInterface
assumptionClosure
semanticDiff
affectedModules
affectedProofs
passEvidence
buildPlan
~~~

The compiler service is a composition boundary.

It does not mean the entire implementation must live in one package or process.

AI tooling is a client of this service, never a replacement for it.

---

# 18. Lean reference/bootstrap lane

## 18.1 Role

Lean is an immediate pinned implementation/bootstrap lane for source that is first shown to belong to the selected PSCV-compatible source profile.

Correct model:

~~~text
PSCV-profile-conforming Lean source
    ->
pinned Lean toolchain
    ->
native/reference tooling
~~~

Incorrect model:

~~~text
arbitrary Lean source
    ->
therefore PSCV
~~~

Profile conformance is a semantic input.

---

## 18.2 Lean is not permanent PSCV authority

Lean may provide:

- reference elaboration;
- reference kernel checking;
- native compilation;
- differential behavior;
- bootstrap executables;
- proof checking for sidecars.

But PSCV authority remains defined by PSCV contracts and selected checker policy.

Agreement between Lean and an owned compiler is evidence, not proof-by-agreement.

---

## 18.3 Toolchain migration policy

The repository currently pins exact Lean identity.

Any Lean patch/minor migration must be explicit:

~~~text
new toolchain identity
    ->
compatibility/conformance replay
    ->
kernel/provider replay
    ->
compiler differential replay
    ->
migration evidence
~~~

Do not silently reinterpret old evidence under a new Lean build.

KernelContract-v1 changes only if its protocol/decision/capability semantics change, not merely because a provider implementation is rebuilt.

---

# 19. PSKernel Core

## 19.1 Current maturity

At adoption, the canonical pskernel-core package contains a 79-module portable semantic kernel and records:

- complete declared Lean-4.34 compatibility matrix for its current scope;
- rule-to-conformance mappings;
- completed canonical source architecture migration;
- bounded performance acceptance;
- native provider adapter;
- provider-parity workflow.

At 304706da..., the M4 provider-parity workflow passed.

---

## 19.2 Promotion rule

Provider readiness does not imply default promotion.

The default remains lean434-wasm until a separate explicit provider-promotion decision closes the required deployment/release evidence.

SAVEF work must not weaken this rule.

---

# 20. SAVEF integration

## 20.1 SAVEF thesis

For compiler development:

> Every correctly completed compiler task should create machine-checkable reusable knowledge that makes comparable future compiler work cheaper without weakening assurance.

Compiler work becomes:

~~~text
task
  ->
specification
  ->
implementation
  ->
proof / validation / accepted evidence
  ->
semantic interface / pass evidence
  ->
SPKF knowledge
  ->
semantic retrieval
  ->
later task
~~~

---

## 20.2 SAVEF is the knowledge plane, not a second compiler plane

SAVEF should index and reuse:

- existing semantic contracts;
- pass definitions;
- ArtifactIds;
- BuildActions;
- ModuleInterfaces;
- theorem/specification identities;
- assumption closures;
- validation results;
- structured failure knowledge;
- proof recipes;
- migration/refinement evidence.

It must not create duplicate semantic truth.

---

## 20.3 Minimal SPKF target

The first SPKF object format should remain small.

Recommended minimum:

~~~text
object identity
object kind
semantic contract identities
input/dependency identities
claims
assumptions
checker/evidence identities
provenance
~~~

A central registry is not required for the first experiment.

A deterministic content-addressed local store is enough.

---

## 20.4 AI role

AI is an untrusted proposer.

AI may:

- search SAVEF knowledge;
- propose code;
- propose proofs;
- propose pass changes;
- propose specifications;
- propose refactors.

AI may not:

- grant CheckedCore authority;
- weaken acceptance gates while preserving identity;
- silently rewrite benchmark criteria;
- declare unsupported semantics accepted;
- mint proof status without the configured checker.

---

# 21. FactoryBench and causal SAVEF evaluation

## 21.1 Freeze evaluation before searchable knowledge grows

This must happen before task-correlated SAVEF knowledge can leak into the benchmark.

Freeze:

- held-out task set or immutable task-generation policy;
- baseline repository revision;
- model identity/policy;
- tool policy;
- acceptance gates;
- metric schema;
- knowledge exclusion policy;
- benchmark snapshot identity.

Where practical, execute the B0 baseline before building the searchable SAVEF corpus used by B1.

---

## 21.2 Experimental arms

~~~text
B0
same model
same tools
same compiler commit
same tasks
same acceptance gates
raw repository access
NO SAVEF semantic retrieval
~~~

~~~text
B1
same everything
+
SAVEF semantic retrieval
~~~

Optional:

~~~text
B2
B1
+
structured proof recipes / failure knowledge
~~~

---

## 21.3 Initial success threshold

Do not claim self-amplification unless:

1. every accepted SAVEF result passes the same or stronger assurance gates;
2. at least 30% of accepted assisted tasks genuinely consume earlier accepted knowledge; and
3. at least one primary productivity improvement is observed, such as:
   - about 20% lower median model tokens;
   - about 20% lower median wall time;
   - about 20% lower human intervention; or
   - at least 10 percentage points higher accepted solve rate; and
4. at least one SAVEF-assisted compiler change creates accepted knowledge reused by a later accepted compiler change.

Negative results must be preserved.

---

# 22. Assurance evidence ladder

Not every pass needs a full proof on day one.

Preferred progression:

~~~text
explicit invariant
    ->
executable validator
    ->
adversarial/mutation corpus
    ->
local proof lemmas
    ->
translation validation
    ->
whole-pass preservation theorem
~~~

Higher assurance replaces weaker evidence only when the stronger result actually covers the same claim.

Tests and proofs remain separately labeled.

---

# 23. Recommended implementation order

This is the canonical order for the first SAVEF-aware compiler evolution.

## P0 — freeze the SAVEF experiment

Deliver:

- FactoryBench policy;
- held-out snapshot/policy;
- baseline commit;
- model/tool policy;
- acceptance gates;
- metrics;
- leakage/exclusion policy.

No compiler semantic changes required.

---

## P1 — close the common authority bypass

Generalize the existing checked-session mechanism into a backend-neutral checked prepared/candidate capability.

Target:

~~~text
prepared candidate
    ->
KernelContract-v1
    ->
CheckedPreparedCapability
    ->
production erasure / emission
~~~

Keep unchecked bootstrap/testing APIs explicit and separate.

This is the highest-priority soundness architecture task.

---

## P2 — unify pass identity with BuildAction

Extend the existing contract/artifact model with:

- PassDefinition;
- phase IDs;
- required invariant IDs;
- established invariant IDs;
- semantic relation IDs;
- validator/evidence IDs.

Do not create a disconnected CompilerPassContract subsystem.

---

## P3 — add PsSpecializedIrModule

Route:

~~~text
PsValidatedIrModule
    ->
shared specialization
    ->
PsSpecializedIrModule
~~~

No wholesale IR rewrite.

---

## P4 — remove hidden certified-path specialization from JS and Wasm

Certified JS/Wasm lowering consumes PsSpecializedIrModule.

Compatibility façades may preserve temporary callers.

---

## P5 — formalize VerifiedIrWellFormed

Connect the existing runtime IR validator to explicit invariant claims.

Prefer small invariant theorems if a single monolithic theorem is impractical.

---

## P6 — stage-specific QueryGraph / BuildAction nodes

Generalize the existing red/green engine around typed artifact dependencies.

Do not build the mega-record design.

---

## P7 — implement ModuleInterface-v1

Start from the conservative current declaration/admission interface key.

Refine toward explicit downstream semantic visibility.

Then attach assurance evidence.

---

## P8 — implement minimal SPKF

Deterministic, content-addressed, local-first.

No central registry.

---

## P9 — first theorem/reuse seed

Recommended sequence:

~~~text
Foundation.List
Foundation.Name
Core.Subst
Core.Abstract
Environment
Meta
~~~

Require actual dependency reuse, not merely proof-file growth.

---

## P10 — FactoryBench B1/B2

Evaluate whether the SAVEF mechanism produces measurable benefit.

If not, revise the knowledge format/retrieval model before expanding proof scope.

---

# 24. Work that should not block the first SAVEF experiment

Do not make these prerequisites:

- complete direct JS fixed point;
- complete direct Wasm fixed point;
- complete direct Rust fixed point;
- every PSCV language feature in the owned compiler;
- full parser proof;
- full elaborator proof;
- full compiler verification;
- full JS preservation theorem;
- full Wasm preservation theorem;
- formal Rust backend verification;
- pskernel-core default promotion;
- WIT/Component implementation;
- central SAVEF registry;
- large package-tree reorganization;
- whole-IR AST rename;
- Lean major/minor migration;
- proving every backend simultaneously.

These may proceed independently when useful.

---

# 25. Explicit anti-goals

Do not:

1. put the kernel implementation into the 55-module bootstrap compiler merely to make a diagram look pure;
2. treat AdmissionReady as CheckedCore;
3. let a backend consume arbitrary elaborated Core in the production checked path;
4. allow cache/query reuse to create semantic authority;
5. use a serialized receipt as a transferable checked capability;
6. create a parallel SAVEF ArtifactId or pass identity system;
7. add target-specific representation to VerifiedIR;
8. hide target-neutral specialization independently inside multiple certified backends;
9. promote pskernel-core automatically after a bounded parity pass;
10. add new one-off self-host repair guards when a general profile invariant can solve the class;
11. merge historical Rust branches wholesale into the consolidated backend;
12. declare fixed-point equality to be compiler correctness;
13. declare differential agreement to be proof;
14. interpret npm/Git/OCI provenance as semantic truth;
15. let AI weaken a semantic or benchmark contract while retaining the same identity.

---

# 26. Current readiness assessment at adoption

This score measures readiness for the full SAVEF compiler self-amplification experiment, not general compiler quality.

| Criterion | Target | Current |
| --- | ---: | ---: |
| Lean reference bootstrap | 9.6 | 8.4 |
| authority separation | 9.9 | 6.3 |
| pass contracts | 9.7 | 4.5 |
| phase artifacts | 9.8 | 6.8 |
| shared specialization | 9.8 | 5.6 |
| ModuleInterface certification | 9.7 | 4.6 |
| semantic QueryGraph | 9.8 | 7.8 |
| proof/spec sidecars | 9.5 | 3.0 |
| specification coverage | 9.4 | 4.0 |
| independent kernel authority | 9.7 | 8.2 |
| Lean oracle differentiation | 9.4 | 8.7 |
| erasure/IR evidence | 9.5 | 6.3 |
| backend preservation | 9.4 | 5.6 |
| fixed-point claim separation | 9.9 | 9.3 |
| SPKF extraction | 9.4 | 1.0 |
| actual knowledge reuse | 9.5 | 1.5 |
| causal FactoryBench | 9.6 | 1.0 |
| holdout isolation | 9.6 | 0.5 |
| AI/acceptance separation | 9.9 | 6.5 |
| resource practicality | 9.5 | 6.2 |
| incremental implementability | 9.8 | 8.1 |
| native-first practicality | 9.7 | 8.8 |
| WIT interoperability | 9.0 | 3.0 |
| migration/longevity | 9.8 | 7.3 |
| falsifiability | 9.8 | 3.0 |
| **Average** | **9.63** | **5.44** |

These are engineering assessments, not proof claims.

They should be revised only against explicit repository evidence.

---

# 27. Canonical target architecture

~~~text
                      PSCV / PROFILE-CONFORMING LEAN SOURCE
                                      |
                                      v
                         UNTRUSTED FRONTEND DOMAIN
                                      |
                    Parse / Resolve / Elaborate / Meta
                                      |
                                      v
                                CandidateCore
                                      |
                                      v
                             KernelContract-v1
                                      |
                         selected provider exactly once
                                      |
                                      v
                         CheckedPreparedCapability
                          /                     \
                         /                       \
                        v                         v
              ModuleInterface-v1               Erase
                        |                         |
                        |                         v
                        |                      RuntimeIR
                        |                         |
                        |                 ValidateRuntimeIr
                        |                         |
                        |                         v
                        |                      VerifiedIR
                        |                         |
                        |                     Specialize/1
                        |                         |
                        |                         v
                        |                    SpecializedIR
                        |                     /        \
                        |                    v          v
                        |                 JsIR        WasmIR
                        |                  |            |
                        |                  v            v
                        |                  JS          Wasm
                        |
                        +---------------------+
                                              |
                                              v
                              BUILD / ARTIFACT / QUERY PLANE

              each semantic transition = PassDefinition + BuildAction
              each input/output = ArtifactId
              reuse = fail-closed QueryGraph / CAS optimization

                                              |
                                              v
                                     KNOWLEDGE PLANE

                          theorem/specification identities
                          assumption closures
                          pass evidence
                          validation evidence
                          structured failures
                          proof recipes
                                      |
                                      v
                                    SPKF
                                      |
                                      v
                              semantic retrieval
                                      |
                                      v
                               untrusted AI
                                      |
                                      v
                         next compiler proposal/task
~~~

TypeScript and Rust may consume an earlier phase where their architecture requires it, provided that:

- the accepted input phase is explicit;
- backend-local transformations are identified;
- high-assurance preservation/validation obligations are not hidden.

---

# 28. Success condition for the compiler architecture

The compiler architecture is considered substantially converged when all of the following are true:

1. production erasure cannot be reached from plain AdmissionReady without explicit unchecked/internal authority;
2. KernelContract-v1 checking is backend-neutral at composition level;
3. all production target routes consume an explicitly authorized compiler phase;
4. RuntimeIR and VerifiedIR have enforceable invariant boundaries;
5. target-neutral specialization has one explicit shared phase;
6. pass definitions reuse BuildAction and ArtifactId;
7. QueryGraph uses stage-specific semantic dependencies;
8. ModuleInterface-v1 supports safe interface-based invalidation;
9. SAVEF knowledge is extracted from existing contracts/artifacts rather than duplicating them;
10. FactoryBench can causally test whether knowledge reuse improves future compiler work;
11. self-host/fixed-point evidence remains distinct from compiler semantic correctness;
12. unsupported semantics continue to fail closed.

---

# 29. Final architecture rule

The PSCV compiler should evolve according to this rule:

> **Enforce the semantic authority architecture already designed, expose reusable compiler passes as explicit typed artifact transitions, reuse the existing BuildAction / ArtifactId / ModuleInterface / QueryGraph architecture, and attach SAVEF knowledge to those stable boundaries.**

The compiler is simultaneously:

~~~text
a compiler product
+
a verified/validated semantic pipeline
+
a bootstrap subject
+
a knowledge factory for its own future evolution
~~~

Those roles are related but not interchangeable.

The kernel decides acceptance.

Compiler passes transform accepted semantic artifacts.

Build/query infrastructure schedules and reuses work.

SAVEF records and retrieves accepted knowledge.

AI proposes the next change.

No layer gains authority merely because it helps another layer.
