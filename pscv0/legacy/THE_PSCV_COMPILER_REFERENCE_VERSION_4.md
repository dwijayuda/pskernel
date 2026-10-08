# THE PSCV Compiler Reference — Version 4

**Status:** proposed architecture simplification and extensibility redesign; does not yet supersede Version 3 implementation status  
**Repository:** `dwijayuda/pskernel`  
**Branch:** `pscv/v3-execution`  
**Primary subtree:** `psc15selfhost/`  
**Normative language authority:** `PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md`  
**Inherited base edition:** `ps-0.9-r3`  
**Verified profile target:** `pscv-v1`  
**Verification semantics:** `PSCV-VERIFY-v1`  
**Certificate policy:** `PSCV-CERT-v1`  
**Normative Lean semantic pin:** Lean 4.35.0-rc3, commit `470d5ce1400764999581fd26d5d72b00d990b0f4`  
**Current compiler implementation milestone:** `psc2-compiler-v1`  
**Current implementation architecture:** Version 3  
**Research/design date:** 2026-10-07

> Version 4 is intentionally **smaller than Version 3**. Its purpose is not to add more architecture. Its purpose is to separate the essential PSCV compiler from assurance, development/SAVEF, release, and research systems while preserving the strongest boundaries already discovered and implemented by Version 3.

---

# 1. Executive decision

Version 3 discovered many valuable boundaries, but it accumulated too many concerns under one "compiler architecture":

- kernel compatibility and metatheory;
- provider security and checker diversity;
- compiler IRs and pass evidence;
- resource theory;
- executable and logical interoperability;
- bootstrap and DDC;
- archives and portable verification;
- SAVEF knowledge semantics;
- AI reuse and negative knowledge;
- FactoryBench;
- release trust manifests;
- repository layout and historical indexing;
- design-scoring methodology.

Version 4 keeps the useful mechanisms but changes the ownership model.

The core decision is:

> **PSCV V4 is a small semantic compiler spine with explicit, versioned, capability-scoped extension points. Assurance, SAVEF/AI development, release/archive, and research systems consume compiler artifacts and evidence but are not part of the compiler's semantic core.**

The target shape is:

~~~text
                         ProofScript source
                               |
                               v
                    parse / resolve / elaborate
                               |
                               v
                              Core
                               |
                        KernelContract
                               |
                               v
                       Checked<Core>
                               |
                    PSCV verification policy
                               |
                               v
                 Certified<Checked<Core>>
                               |
                            erasure
                               |
                               v
                           RuntimeIR
                               |
                    validate / certify shape
                               |
                               v
                  Validated<RuntimeIR>
                               |
                         specialization
                               |
                               v
                        SpecializedIR
                          /          \
                         /            \
                       JsIR          WasmIR
                        |              |
                    validate         validate
                        |              |
                        v              v
                        JS            Wasm
~~~

The compiler has four neighboring systems:

~~~text
ASSURANCE
  kernel evidence, pass preservation, validators, comparator

DEVELOPMENT
  CompilerService, QueryGraph, semantic retrieval, SAVEF, AI

INTEROPERABILITY
  InterfaceIR, WIT/.d.ts/Rust bindings, target adapters

RELEASE
  TrustManifest, provenance, archive, offline replay, DDC
~~~

The compiler remains usable if all four neighboring systems are removed.

---

# 2. Why Version 4 exists

Version 4 is motivated by both implementation experience and external evidence.

## 2.1 Lessons from Version 3 implementation

Version 3 was valuable because it forced explicit treatment of:

- real CheckedCore authority instead of AdmissionReady;
- VerifiedIR invariants;
- specialization as an explicit stage;
- exact JsIR and WasmIR artifacts;
- target validators;
- pass identities and evidence;
- structural and behavioral module interfaces;
- semantic cache boundaries;
- explicit self-host and bootstrap evidence classes;
- SAVEF ValidUnder rules;
- portable verifier and archive concepts.

However, current implementation experience also exposed three costs.

First, architectural ownership became difficult to reason about because compiler, assurance, SAVEF, release, interoperability, and research mechanisms all appeared as peers in one document.

Second, some terms describe genuine representations while others describe evidence states. Treating both as equally fundamental IR stages increases implementation and proof burden.

Third, the architecture continued to grow while the compiler still had concrete backend/self-host stabilization work. This is evidence that architecture expansion was beginning to outpace implementation closure.

## 2.2 CompCert lesson: keep genuine semantic stages explicit

CompCert structures its verified compiler as a sequence of real intermediate languages and pass-specific semantic-preservation proofs. Its intermediate languages exist because they bridge real representation/semantic gaps, not merely because more evidence became available.

V4 adopts the same discipline:

> **Create a new IR only when the representation or operational meaning genuinely changes. Evidence state alone is represented by a capability wrapper.**

References:

- https://compcert.org/doc/
- https://compcert.org/man/manual001.html
- https://compcert.org/doc/html/compcert.driver.Compiler.html

## 2.3 CakeML lesson: separate compiler correctness from bootstrap claims

CakeML treats verified compilation and bootstrapping as related but distinct claims. A compiler compiling itself does not by itself prove compiler correctness.

V4 preserves this separation.

References:

- https://cakeml.org/
- https://cakeml.org/download.html

## 2.4 Dafny lesson: behavioral interfaces enable modular reasoning

Dafny verifies methods modularly using specifications of other methods. V4 therefore keeps BehavioralModuleInterface as a first-class composition boundary but does not make it another compiler IR.

References:

- https://dafny.org/dafny/DafnyRef/DafnyRef
- https://dafny.org/dafny/QuickReference

## 2.5 Lean lesson: extensible surface, small checked core

Lean demonstrates that syntax, macros, elaborators, tactics, and environment extensions can be very expressive while the kernel remains small. Lean also supports scoped/local extensions rather than requiring every extension to be ambient.

V4 adopts the useful part of this model while making closed PSCV profiles stricter and more reproducible.

References:

- https://lean-lang.org/doc/reference/latest/Notations-and-Macros/
- https://lean-lang.org/doc/reference/latest/Notations-and-Macros/Elaborators/
- https://lean-lang.org/doc/reference/latest/Notations-and-Macros/Macros/
- https://lean-lang.org/doc/reference/latest/

## 2.6 WIT lesson: stable interfaces decouple implementations

WIT defines versionable interfaces and worlds without defining component behavior. This is the right model for target/runtime/plugin ABI boundaries: describe interfaces precisely while keeping behavior and proof obligations separate.

References:

- https://component-model.bytecodealliance.org/design/wit.html
- https://github.com/WebAssembly/component-model/blob/main/design/mvp/WIT.md

## 2.7 Translation-validation lesson: keep complex transforms replaceable

Alive2 demonstrates the usefulness of validating individual transformation results rather than requiring the entire optimizer implementation to be in the trusted base.

V4 treats translation validation as an assurance attachment to a compiler pass.

References:

- https://github.com/AliveToolkit/alive2
- https://web.tecnico.ulisboa.pt/nuno.lopes/pubs.php?id=alive2-pldi21

## 2.8 AI/compiler-interface lesson

Pantograph demonstrates the value of a machine-oriented theorem-prover interface, and generative compilation demonstrates the benefit of compiler feedback on partial programs.

V4 therefore makes CompilerService an explicit external interface over the compiler rather than expanding the compiler semantic core for AI-specific concerns.

References:

- https://link.springer.com/chapter/10.1007/978-3-031-90643-5_6
- https://arxiv.org/abs/2607.13921

---

# 3. V4 design laws

Version 4 has twelve primary laws.

1. **Small semantic spine.** The compiler architecture explains only how a PSCV source program becomes an executable artifact.
2. **Closed semantics, open tooling.** Extensions may add syntax, automation, passes, backends, adapters, and tooling without silently redefining canonical Core.
3. **Evidence is not an IR.** If bytes/structure/operational meaning are unchanged, stronger evidence should usually wrap a value rather than create a new language representation.
4. **Real IRs require real semantic gaps.** New IRs require a documented representation purpose and transformation contract.
5. **One explicit pass model.** Erasure, specialization, optimization, lowering, and future transforms use the same pass abstraction.
6. **Extensions are explicit and versioned.** No ordinary dependency silently mutates a closed profile.
7. **Only semantic-profile revisions may change foundational Core meaning.**
8. **Backends are plugins over stable IR contracts.** Adding a backend must not require frontend/kernel redesign.
9. **Target-specific semantics stay target-specific unless promoted to a general language concept.**
10. **Verification authority remains deterministic.** AI, tactics, solvers, optimizers, plugins, and caches may propose; configured checkers accept.
11. **Self-hosting is evidence, not semantic authority.**
12. **Companion systems are optional consumers.** SAVEF, archive, release, DDC, and FactoryBench cannot be prerequisites for ordinary compilation.

---

# 4. Scope and non-goals

## 4.1 V4 compiler owns

V4 owns:

- source profile selection;
- parsing, name resolution, elaboration;
- canonical Core production;
- KernelContract invocation;
- Checked capability creation;
- PSCV source certification gate;
- erasure;
- RuntimeIR;
- runtime-IR validation;
- specialization;
- target lowering;
- target-IR validation boundary;
- deterministic target emission;
- compiler pass registration;
- structural/behavioral module interface production;
- compiler-service hooks;
- extension registration and identity;
- backend registration;
- self-host/bootstrap compiler closure definition.

## 4.2 V4 compiler does not own

The following are companion systems, not core compiler architecture:

- PSKernel implementation/metatheory;
- independent checker diversity policy;
- comparator sandbox policy;
- semantic-model consistency research;
- full SAVEF knowledge semantics;
- FactoryBench;
- universal logical TheoryBridge research;
- release archive format;
- SLSA/in-toto provenance;
- DDC campaign policy;
- long-term package registry design;
- model training/self-play;
- repository scoring methodology;
- research-iteration history.

The compiler exposes enough identity/evidence hooks for those systems to operate.

---

# 5. The V4 semantic pipeline

The canonical V4 pipeline is:

~~~text
SourceArtifact
    |
    v
ProfileEnvironment
    |
    v
ParsedModule
    |
    v
ElaboratedCore
    |
    v
KernelContract.check
    |
    v
Checked<Core>
    |
    v
PSCVPolicy.certify
    |
    v
Certified<Checked<Core>>
    |
    v
Erase
    |
    v
RuntimeIR
    |
    v
ValidateRuntimeIR
    |
    v
Validated<RuntimeIR, RuntimeIRContract>
    |
    v
Specialize
    |
    v
SpecializedIR
    |
    +----------------------------+
    |                            |
    v                            v
Backend<JS>                  Backend<Wasm>
    |                            |
    v                            v
JsIR                         WasmIR
    |                            |
    v                            v
ValidateJsIR                 ValidateWasmIR
    |                            |
    v                            v
Validated<JsIR>              Validated<WasmIR>
    |                            |
    v                            v
EmitJS                       EncodeWasm
    |                            |
    v                            v
ExecutableArtifact           ExecutableArtifact
~~~

Additional backends plug into the same target-lowering interface.

---

# 6. Representations versus capabilities

This is the main simplification from V3.

## 6.1 Representation

A representation is a language/data model with meaning distinct enough to deserve its own contract.

Current V4 representations are:

~~~text
Source
Parsed syntax
Core
RuntimeIR
SpecializedIR
TargetIR family
ExecutableArtifact
~~~

TargetIR is open:

~~~text
JsIR
WasmIR
RustIR?
CIR?
LLVMIR?
JVMIR?
future targets
~~~

A target may skip a dedicated target IR only when its backend contract explicitly justifies direct emission and the assurance profile permits it.

## 6.2 Capability/evidence wrapper

A capability says that a representation has passed a named authority or validator boundary.

Conceptually:

~~~text
Checked<T>
Validated<T, Contract>
Certified<T, Policy>
~~~

These wrappers bind:

- exact subject ArtifactId;
- contract/policy identity;
- checker/validator identity;
- semantic/profile context;
- assumption closure where applicable;
- resource policy;
- session/live-authority identity where required;
- evidence/receipt identity.

A serialized receipt is evidence of an event. It does not recreate a live capability.

## 6.3 Mapping existing V3 concepts

Conceptually:

~~~text
CheckedCoreCapability
    -> Checked<Core>

CertifiedSource
    -> Certified<Checked<Core>, PSCVPolicy>

VerifiedIR
    -> Validated<RuntimeIR, RuntimeIRContract>
       unless the current implementation proves that VerifiedIR is
       genuinely a distinct representation

SpecializedIR
    -> remains a representation if specialization changes declarations,
       types, calling conventions, or executable structure
~~~

V4 does not require immediate physical type renaming. This is initially a specification/ownership simplification.

---

# 7. IR admission rule

Before adding a new IR, answer all of the following.

1. What representation difference exists?
2. What semantic or operational gap does it bridge?
3. What transformation produces it?
4. What invariant becomes expressible only or more naturally in this representation?
5. What downstream consumer requires it?
6. Can the same purpose be represented by `Validated<T>`, `Certified<T>`, an interface, or metadata instead?

If question 6 is yes, do not add a new IR.

This rule exists to prevent evidence-state proliferation.

---

# 8. Generic compiler pass model

Every semantic transformation implements one generic model.

~~~text
PassDefinition<I, O> {
  passId
  version
  inputContract
  outputContract
  semanticRelationId
  implementationId
  determinismClass
  supportedProfile
  validatorId?
  theoremIds[]
  assumptionIds[]
}

PassRun<I, O> {
  passDefinitionId
  inputArtifactId
  outputArtifactId
  semanticContextId
  validatorEvidence?
  proofEvidence[]
  diagnostics
  resourceObservation?
}
~~~

The core compiler requires only enough evidence to satisfy the active build profile.

Examples:

~~~text
Core -> RuntimeIR
RuntimeIR -> SpecializedIR
SpecializedIR -> JsIR
SpecializedIR -> WasmIR
JsIR -> JsIR optimization
WasmIR -> WasmIR optimization
~~~

An implementation may change freely if its PassDefinition contract and output validation remain satisfied.

---

# 9. Extension architecture

V4 is explicitly extensible.

The extension taxonomy is:

~~~text
ExtensionKind =
    Library
  | SurfaceSyntax
  | SurfaceElaborator
  | ProofProducer
  | CompilerPass
  | Backend
  | InterfaceAdapter
  | DiagnosticTool
  | DevelopmentTool
  | SemanticProfile
~~~

Fundamental law:

> **Only SemanticProfile may change the foundational interpretation of canonical Core.**

All other extension classes either:

- lower source into existing Core;
- generate proof/evidence candidates;
- transform already checked/validated compiler representations;
- produce interfaces/adapters;
- provide diagnostics or development tooling.

---

# 10. Closed profiles and extension identity

## 10.1 Closed default profiles

`ps-standard-0.9-r3` and `pscv-v1` remain closed by default.

Ordinary dependencies may not silently add or replace:

- grammar;
- macros;
- elaborators;
- coercions;
- instance-resolution rules relevant to source meaning;
- VC rules;
- trusted proof rules;
- compiler passes;
- backend semantics.

## 10.2 Explicit extension set

A build using extensions records them explicitly.

Illustrative manifest:

~~~json
{
  "languageEdition": "ps-0.9-r3",
  "profile": "pscv-v1",
  "extensions": [
    {
      "id": "proofscript.regex-syntax/1",
      "kind": "SurfaceElaborator",
      "artifactId": "..."
    }
  ]
}
~~~

The active source-language identity includes the ordered/canonical extension set and semantic options.

## 10.3 Scoped and local extensions

Where practical, extensions may be:

- project-global;
- module-scoped;
- namespace/scoped;
- local.

This takes inspiration from Lean's scoped/local syntax and macro mechanisms while preserving a reproducible profile identity.

---

# 11. Extension manifest

Every non-library extension publishes a machine-readable manifest.

~~~text
ExtensionManifest {
  extensionId
  version
  kind
  implementationArtifactId
  compilerApiVersion
  inputContracts[]
  outputContracts[]
  requiredCapabilities[]
  providedCapabilities[]
  semanticEffect
  deterministic?
  portabilityProfile?
  trustClass
}
~~~

`semanticEffect` is one of:

~~~text
none
surface-only
proof-producing
representation-transform
target-specific
foundation-change
~~~

Only `SemanticProfile` may declare `foundation-change`.

---

# 12. Trust classes for extensions

V4 has three extension trust classes.

## Class A — tooling/surface

Examples:

- formatter;
- linter;
- code action;
- syntax sugar that lowers deterministically;
- documentation generator.

No proof/compilation authority.

## Class B — untrusted producer with checked output

Examples:

- tactic;
- AI proof producer;
- VC generator;
- optimizer;
- compiler pass;
- backend;
- external solver;
- binding generator.

These may be complex.

Their output becomes authority only after the configured checker/validator/preservation boundary accepts it.

## Class C — semantic foundation

Examples:

- new Core primitive;
- new reduction rule;
- new declaration kind;
- new quotient/inductive rule.

These are not ordinary plugins.

They require a new semantic profile or language/core revision, kernel support, specification, migration policy, and assurance review.

---

# 13. Language-feature extensibility

New language features follow this decision process:

~~~text
Can it be a library?
    yes -> library

Is it only syntax/desugaring?
    yes -> SurfaceSyntax

Does it need elaboration but lower to existing Core?
    yes -> SurfaceElaborator

Is it proof automation?
    yes -> ProofProducer

Is it a compiler transformation?
    yes -> CompilerPass

Is it target-specific?
    yes -> Backend or InterfaceAdapter

Does it require new foundational meaning?
    yes -> SemanticProfile revision
~~~

## 13.1 Lean-compatible features

Lean-compatible features are classified as:

### Surface-compatible

Examples:

- notation;
- `calc`;
- richer `do`;
- field/method notation;
- named arguments;
- deriving frontends.

These should normally lower into existing ProofScript/Core semantics.

### Elaborator/meta-compatible

Examples:

- macros;
- attributes;
- custom elaborators;
- tactics;
- controlled instance/coercion facilities.

These belong in an explicit Lean/extensible profile or standard extension set.

### Foundation-changing

A future Lean feature that changes kernel primitives, reduction, declaration semantics, or Core theory requires a new ProofScript semantic profile. It is not accepted merely because upstream Lean implements it.

---

# 14. Target-specific language features

Target-specific functionality must not automatically enter portable ProofScript semantics.

Examples:

~~~text
Rust repr(C)
Rust Pin
Rust trait-object ABI
Cargo feature behavior
JS prototype identity
Node-specific modules
Wasm core opcode availability
WASI capability imports
C calling convention attributes
~~~

These belong in:

- backend configuration;
- target profiles;
- InterfaceIR annotations;
- foreign-interface adapters;
- explicit target-only source extensions.

A target-specific concept may be promoted into the language only if it is reformulated as a useful target-independent semantic concept.

Example:

~~~text
Rust-specific borrowing syntax      -> usually target-only

general linear/unique capability
with independent semantics           -> possible language feature
~~~

---

# 15. Backend plugin contract

A backend consumes a stable compiler representation.

Conceptually:

~~~text
Backend<I, T> {
  backendId
  targetProfile
  inputContract
  lower(input: Validated<I>) -> T
  targetValidator
  emitter
}
~~~

For current direct targets:

~~~text
Backend<SpecializedIR, JsIR>
Backend<SpecializedIR, WasmIR>
~~~

A new backend must not require changes to:

- parser;
- Core;
- kernel;
- PSCV verification policy;
- erasure;

unless it exposes a genuine missing target-independent semantic requirement.

Backend-specific helper IRs are allowed behind the backend boundary.

---

# 16. Target validation and translation assurance

The compiler architecture exposes a target-validation seam but does not require one assurance technique.

Allowed strategies include:

- formally proved pass;
- independently checked certificate;
- translation validation;
- differential validation;
- combinations of the above.

The release profile decides which is sufficient.

The target compiler path is:

~~~text
Validated<SpecializedIR>
        |
        v
      lower
        |
        v
     TargetIR
        |
        v
TargetValidator
        |
        v
Validated<TargetIR>
        |
        v
       emit
~~~

The validator never grants source/kernel authority. It grants only the target contract it actually checks.

---

# 17. Module interfaces and separate reasoning

V4 keeps two module-interface layers.

## StructuralModuleInterface

Contains downstream-relevant public structure:

- exported names/types;
- transparent definitions required for conversion;
- public data shape;
- instances/coercions required by the active profile;
- capabilities;
- dependency interface IDs;
- target ABI requirements where relevant.

## BehavioralModuleInterface

Contains:

- requires/ensures;
- invariants;
- effects/capabilities;
- resource claims;
- public assumptions;
- public theorem/spec identities;
- refinement relations.

These interfaces are not compiler IRs.

They are compact semantic boundaries used for:

- modular verification;
- incremental invalidation;
- AI context slicing;
- package compatibility;
- SAVEF reuse.

A module can be recompiled internally without invalidating dependents when the reuse contract proves that the relevant interface identity is unchanged.

---

# 18. InterfaceIR and executable interoperability

InterfaceIR remains a separate interoperability subsystem.

It may describe:

- functions;
- records;
- variants;
- enums;
- options/results;
- resources/handles;
- ownership/lifetime classes;
- streams/futures;
- errors;
- target availability;
- capabilities.

Adapters may produce:

- WIT;
- TypeScript declarations;
- Rust bindings;
- C/native ABI metadata.

WIT is treated as an interface description, not a behavioral proof language.

InterfaceIR may eventually use WIT/Component Model as a physical portable plugin/adapter ABI, but V4 does not require a universal plugin ABI now.

---

# 19. CompilerService: machine and human interaction

CompilerService is an API over the semantic compiler, not another semantic layer.

It should expose operations such as:

~~~text
parse
elaborate
typeOf
goal
holes
tryCandidate
compileStage
validateStage
dependencies
moduleInterface
semanticDiff
affectedArtifacts
diagnosticDetails
~~~

Responses are structured and identity-bearing.

For AI and IDE use, partial programs and proof holes should remain analyzable whenever safe.

Illustrative diagnostic:

~~~json
{
  "code": "PSCV-E-TYPE-APPLICATION",
  "stage": "elaboration",
  "subjectId": "...",
  "expected": "Nat",
  "actual": "Int",
  "sourceSpan": {},
  "semanticOwner": "Ps.Elab.Apply",
  "relatedDeclarations": []
}
~~~

This interface is inspired by machine-oriented theorem-prover work and partial-program compiler feedback, but it has no authority beyond the underlying compiler/checkers.

---

# 20. Incrementality and caches

Incrementality belongs to CompilerService/development architecture.

The semantic compiler exposes stable identities:

~~~text
ArtifactId
SemanticFingerprint
PassDefinitionId
ModuleInterfaceId
ProfileEnvironmentId
~~~

A cache may reuse results only when its declared reuse contract matches the current context.

Cache metadata is never acceptance authority.

V4 intentionally does not require one universal cache implementation or CAS.

---

# 21. Resource and failure model

V4 keeps only the minimal resource model required for deterministic behavior.

Canonical outcomes:

~~~text
Accepted(value)
RejectedInvalid(reason)
Unsupported(feature)
ResourceExhausted(resource, limit, observed?)
InternalError(code)
InfrastructureUnavailable(code)
~~~

Only `Accepted` produces the requested capability.

Every externally reachable stage may have explicit hard bounds.

General resource-monotonicity theorems and formal cost models belong in assurance research, not the core compiler architecture unless a specific stage requires them.

---

# 22. Assurance boundary

V4 exposes evidence attachment points but moves assurance architecture to a companion reference.

Suggested companion:

`PSCV_ASSURANCE_REFERENCE.md`

It owns:

- PSKernel evidence;
- Lean/reference checker evidence;
- algorithmic-defeq refinement;
- cache soundness proofs;
- pass preservation;
- validator soundness;
- comparator protocol;
- IndependenceVector;
- provider-security profile;
- solver-certificate checking;
- resource-assurance campaigns;
- semantic-model consistency work.

V4 compiler only needs stable references to the resulting evidence identities.

---

# 23. SAVEF and AI-development boundary

SAVEF is a consumer of compiler semantics, not a compiler prerequisite.

Suggested companion:

`PROOFSCRIPT_SAVEF_REFERENCE.md`

It owns:

- KnowledgeObject;
- ValidUnder;
- ClaimObject;
- TaskObject;
- TheoremKnowledge;
- CompilerPassKnowledge;
- ModuleInterfaceKnowledge;
- FailureKnowledge;
- ReuseEvent;
- migrations/supersession;
- semantic retrieval;
- AI orchestration;
- FactoryBench.

The dependency direction is:

~~~text
compiler
   |
   v
artifacts / interfaces / evidence
   |
   v
SAVEF indexes and reuses them
~~~

The compiler must never depend on SAVEF for semantic correctness.

---

# 24. Release/archive boundary

Release and archival concerns move to a companion profile.

Suggested companion:

`PSCV_RELEASE_ASSURANCE_PROFILE.md`

It owns:

- TrustManifest;
- SemanticDelta/TrustDelta;
- semantic lock;
- provenance;
- package signatures;
- archive format;
- offline verifier distribution;
- hash agility;
- DDC/diverse bootstrap campaigns;
- paranoid checker policies.

An ordinary compiler invocation does not need to understand the long-term archive format.

---

# 25. Self-host and bootstrap

V4 keeps self-hosting simple.

The portable bootstrap compiler consists of:

~~~text
foundation
syntax
core
environment
meta/elab
compiler semantic spine
one bootstrap backend
required portable libraries
~~~

Optional extensions/backends remain outside the smallest fixed-point closure until the compiler genuinely requires them.

Claims remain separate:

~~~text
source representability
self-application
source fixed point
artifact fixed point
backend fixed point
reproducibility
diverse bootstrap
verified bootstrap
compiler correctness
~~~

One does not imply another.

---

# 26. Physical plugin ABI

V4 specifies semantic plugin contracts, not one mandatory physical ABI.

Initial implementations may use:

- statically linked self-host modules;
- generated registration tables;
- host JavaScript/Node adapters;
- Lean-side bootstrap registration.

A future portable ABI may use WebAssembly Component Model/WIT for suitable extension classes.

This is especially attractive for:

- backends;
- analyzers;
- formatters;
- interface adapters;
- standalone validators.

Proof tactics and deeply integrated elaborators may remain in-process where performance or rich compiler access requires it.

No physical ABI choice changes the semantic extension taxonomy.

---

# 27. Repository ownership model

Recommended long-term organization:

~~~text
psc15selfhost/
  PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md
  THE_PSCV_COMPILER_REFERENCE_VERSION_4.md

  packages/
    syntax/
    core/
    meta/
    elab/
    compiler/
    compiler-ir/
    erasure/
    specialization/

    backend-js/
    backend-wasm/
    backend-rust/

    interface-ir/
    compiler-service/

    extensions/
      standard/
      lean-compat/

  contracts/
    compiler/
    passes/
    interfaces/
    targets/

  assurance/
    # companion evidence and adapters, not semantic compiler ownership

  savef/
    # development knowledge system

  release/
    # release/archive/provenance
~~~

Physical movement is optional during migration. Ownership rules matter before folder layout.

---

# 28. V3-to-V4 concept map

| Version 3 concept | V4 disposition |
|---|---|
| CandidateCore | Core before Checked capability |
| CheckedCoreCapability | `Checked<Core>` capability |
| PSCV-CERT / CertifiedSource | `Certified<Checked<Core>, PSCVPolicy>` |
| RuntimeIR | keep as real representation |
| VerifiedIR | preferably `Validated<RuntimeIR>`; preserve physical type until migration proves equivalence |
| SpecializedIR | keep if representation genuinely changes |
| JsIR / WasmIR | keep |
| PassDefinition / PassExecution | simplify into generic pass model |
| QueryGraph | development/incrementality subsystem |
| proof-carrying cache | development/assurance subsystem |
| StructuralModuleInterface | keep |
| BehavioralModuleInterface | keep |
| InterfaceIR | interoperability subsystem |
| TheoryBridge | research/interop companion, not compiler core |
| Comparator | assurance companion |
| IndependenceVector | assurance companion |
| TheoryBaseManifest | kernel/assurance companion |
| resource monotonicity | assurance research |
| unified CompilationBudget | simplify to stage ResourcePolicy |
| portable verifier capsule | release/assurance companion |
| archive profile | release companion |
| SAVEF theory graph | SAVEF companion |
| FailureKnowledge / ReuseEvent | SAVEF companion |
| FactoryBench | research/development companion |
| TrustManifest / SemanticDelta | release/assurance companion |
| semantic lock | release companion |
| DDC/bootstrap diversity | release/assurance companion |
| architecture scores | remove from canonical compiler reference |

---

# 29. Migration policy: no rewrite

Version 4 must not trigger a broad code rewrite.

Migration sequence:

## Phase 1 — conceptual normalization

- accept V4 terminology;
- keep current physical V3 types/APIs;
- document which types are representations versus capabilities;
- stop adding new compiler-core concerns that belong in companion systems.

## Phase 2 — ownership boundaries

- separate compiler, assurance, SAVEF, release, and interoperability imports;
- add architecture guards;
- keep compatibility facades.

## Phase 3 — extension contracts

- define ExtensionManifest;
- define explicit backend registration;
- define explicit pass registration;
- define profile extension identity.

## Phase 4 — capability normalization

Where low-risk, replace duplicate evidence-only state types with generic capability wrappers or common interfaces.

## Phase 5 — companion references

Extract V3 assurance, SAVEF, and release material into their own references.

## Phase 6 — conformance

Only after implementation aligns with V4 may Version 4 supersede Version 3 as the canonical implementation architecture.

---

# 30. Backward compatibility

V4 does not redefine existing accepted `ps-0.9-r3` or `pscv-v1` source semantics.

V4 is primarily a compiler-architecture ownership change.

Existing V3 artifacts remain interpretable under their recorded contracts.

Migration must preserve exact semantic identities or record explicit SemanticDelta.

Existing backend and pass IDs remain valid until individually versioned or retired.

---

# 31. What V4 deliberately refuses to do

V4 does not:

- create a universal plugin language;
- allow arbitrary ambient grammar mutation in closed PSCV builds;
- let plugins add kernel axioms;
- force Rust ownership semantics into portable ProofScript;
- force JavaScript dynamic semantics into Core;
- make every Lean feature automatically a ProofScript feature;
- require WIT as the internal compiler ABI;
- require SAVEF to compile;
- require archive/provenance systems during edit-time development;
- make a fixed point evidence of compiler correctness;
- create a new IR merely to represent stronger assurance;
- require every compiler pass to be formally proved when an accepted independent validator can satisfy the selected assurance profile.

---

# 32. V4 acceptance criteria

Version 4 architecture is ready to supersede Version 3 only when all of the following are true.

1. **One-screen semantic spine**  
   The full semantic compilation path can be described without SAVEF, release, archive, DDC, FactoryBench, or checker-diversity machinery.

2. **Representation discipline**  
   Every named IR has a documented representation purpose. Evidence-only states are identified as capabilities.

3. **Extension discipline**  
   Every extension kind has a stable typed contract. Closed profiles cannot be mutated implicitly.

4. **Backend independence**  
   A new backend can be added without changing parser/Core/kernel/PSCV certification except for genuine target-independent gaps.

5. **Foundation protection**  
   Only SemanticProfile revisions can change canonical Core meaning.

6. **Authority discipline**  
   Plugins, AI, solvers, optimizers, caches, and backends cannot manufacture Checked/Certified authority.

7. **Modular verification**  
   BehavioralModuleInterface provides the contract boundary for dependent reasoning.

8. **Machine interface**  
   CompilerService can expose partial checking and structured diagnostics without becoming a semantic authority.

9. **Self-host preservation**  
   The portable compiler closure remains small and extension/backends remain opt-in outside the minimal bootstrap.

10. **No implementation rewrite requirement**  
    Existing V3 implementation can migrate incrementally behind compatibility facades.

11. **Companion-system independence**  
    Compiler operation remains possible with SAVEF, archive/release, FactoryBench, and TheoryBridge removed.

12. **Current pipeline stabilization**  
    Existing JS/Wasm/Rust/self-host behavior is not weakened to satisfy the architecture.

---

# 33. Immediate implementation sequence

Version 4 recommends:

1. Freeze further Version 3 architectural expansion.
2. Stabilize the current V3 implementation/backends and preserve current fixed-point evidence.
3. Treat this V4 document as target architecture, not current conformance.
4. Add explicit ownership annotations/guards for:
   - compiler;
   - assurance;
   - interoperability;
   - SAVEF/development;
   - release.
5. Introduce ExtensionManifest and Backend contract with no behavior change.
6. Classify current types as:
   - representation;
   - capability;
   - evidence;
   - interface;
   - development metadata.
7. Keep existing `PsValidatedIrModule` / CertifiedSource-style physical types until low-risk refactoring is justified.
8. Extract assurance and SAVEF architecture into companion documents before beginning the expensive global proof phase.
9. Re-evaluate whether `VerifiedIR` remains a real IR or becomes a validated RuntimeIR capability in implementation.
10. Begin V4 formal assurance only after ownership and representation boundaries are stable.

---

# 34. Research conclusions

The research reviewed for Version 4 supports the following design conclusions.

## Strongly supported

- real semantic compiler stages should be explicit and separately reasoned about;
- modular behavioral specifications improve compositional reasoning;
- syntax/elaboration can be highly extensible while keeping a small trusted kernel;
- scoped/versioned extension mechanisms are preferable to uncontrolled ambient mutation;
- target interfaces benefit from language-neutral versioned contracts;
- translation validation can keep complex transforms replaceable;
- machine-oriented compiler/prover interfaces are valuable for AI and tooling;
- self-host/fixed-point evidence is separate from compiler correctness.

## Recommended engineering prior

> **Make the semantic core smaller than the ecosystem around it.**

The compiler should become more extensible by exposing stable contracts, not by absorbing every extension into the core architecture.

---

# 35. Final architecture

The final V4 picture is:

~~~text
                    ProofScript / PSCV source
                              |
                       ProfileEnvironment
                              |
                    parse / elaborate
                              |
                              v
                             Core
                              |
                       KernelContract
                              |
                              v
                        Checked<Core>
                              |
                         PSCV policy
                              |
                              v
                  Certified<Checked<Core>>
                              |
                           erasure
                              |
                              v
                          RuntimeIR
                              |
                         validation
                              |
                              v
                  Validated<RuntimeIR>
                              |
                        specialization
                              |
                              v
                       SpecializedIR
                     /       |        \
                    /        |         \
                 JsIR      WasmIR     TargetIR...
                  |          |            |
              validate    validate     validate
                  |          |            |
                  v          v            v
                  JS        Wasm       Artifact
~~~

Extension points:

~~~text
SurfaceSyntax / SurfaceElaborator
          |
          v
         Core

ProofProducer
          |
          v
checked proof/certificate boundary

CompilerPass
          |
          v
existing representation -> existing/new justified representation

Backend
          |
          v
SpecializedIR -> TargetIR

InterfaceAdapter
          |
          v
InterfaceIR -> target binding/ABI

SemanticProfile
          |
          v
the only extension class permitted to change foundational Core meaning
~~~

Neighbor systems:

~~~text
             +---------------------+
             |   PSCV ASSURANCE    |
             +---------------------+
                      ^
                      |
+----------------+  COMPILER  +----------------+
| SAVEF / AI DEV | <--------> | INTEROPERABILITY|
+----------------+             +----------------+
                      |
                      v
             +---------------------+
             | RELEASE / ARCHIVE   |
             +---------------------+
~~~

This is the intended Version 4 architecture.

---

# 36. Supersession rule

Version 4 is initially a **proposed target architecture** beside Version 3.

Version 3 remains the implementation/evidence reference until:

- V4 acceptance criteria are reviewed;
- current implementation is classified against V4 boundaries;
- required companion references exist;
- architecture guards reflect V4 ownership;
- no current implementation/evidence claim is lost.

At that point a separate explicit change may mark Version 4 canonical.

No document title, score, or migration note alone creates that status.
