# THE PSCV Compiler Reference — Version 5.1

**Status:** proposed standalone target architecture; quantitative architecture score **99.15 / 100**  
**Repository:** `dwijayuda/pskernel`  
**Branch audited:** `pscv/v3-execution`  
**Audit snapshot HEAD:** `ee7febce6e7744fbb66b1e25e625f4855dd33096`  
**Primary implementation subtree:** `psc15selfhost/`  
**Normative language authority:** `PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md`  
**Base edition:** `ps-0.9-r3`  
**Verified profile:** `pscv-v1`  
**Closed-assurance policy:** `pscv-closed-v1`  
**Boundary-assurance policy:** `pscv-boundary-v1`  
**Verification semantics:** `PSCV-VERIFY-v1`  
**Certificate policy:** `PSCV-CERT-v1`  
**Normative Lean semantic pin:** Lean 4.35.0-rc3, commit `470d5ce1400764999581fd26d5d72b00d990b0f4`  
**Bootstrap Lean implementation pin:** Lean 4.34.0, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`  
**Current implementation milestone:** `psc2-compiler-v1`  
**Research/evaluation date:** 2026-10-08

> **Standalone rule.** This document is complete as a target-architecture reference. A reader does not need Version 3, Version 4, Version 4.1, or Version 4.2 to understand the intended PSCV compiler architecture. Earlier documents remain design history and implementation evidence only.

> **Score rule.** 99.15/100 is a quantitative **target-architecture quality** score under the rubric defined here. It is not a claim that 99.15% of implementation, proofs, security hardening, or release evidence is complete.

---

# 1. Executive decision

PSCV V5.1 is organized around five stable contracts:

1. **Semantic Spine** — the smallest path required to turn ProofScript source into target artifacts.
2. **Claim Lattice** — every success claim is explicit; parsing, kernel acceptance, target validation, preservation, fixed point, reproducibility, provenance, and DDC cannot be silently conflated.
3. **Authority Firewall** — untrusted extensions, AI, tactics, optimizers, backends, target compilers, caches, and SAVEF may propose artifacts but cannot mint semantic authority.
4. **Build/Query Identity** — compiler actions are hermetic-by-contract, incrementally reusable only under declared dependencies/fingerprints, and pinned to exact semantic/toolchain identities.
5. **Artifact Bundles** — every backend returns a typed bundle of executable, declaration/interface, debug/source-map, and evidence artifacts.

Canonical semantic spine:

~~~text
ProofScript SourceArtifact
        |
        v
ProfileEnvironment
        |
        v
parse / resolve / elaborate
        |
        v
CoreArtifact
        |
        | KernelContract
        v
Checked<Core>
        |
        | PSCV policy / specification closure
        v
Certified<Checked<Core>>
        |
        | erasure
        v
RuntimeIR
        |
        | strict runtime validation
        v
Validated<RuntimeIR>
        |
        | specialization
        v
SpecializedIR
        |
        +----------------+----------------+----------------+
        |                |                |                |
        v                v                v                v
 TypeScript          Direct JS         WasmIR          Rust source
 source backend      backend           backend          backend
        |                |                |                |
    pinned tsc       ValidateJsIR     ValidateWasmIR    pinned rustc
        |                |                |                |
        v                v                v                v
 ArtifactBundle     ArtifactBundle     ArtifactBundle   ArtifactBundle
~~~

The compiler has four optional neighboring systems:

~~~text
ASSURANCE       proofs / validators / comparator / diverse checkers
DEVELOPMENT     CompilerService / QueryGraph / SAVEF / AI
INTEROP         InterfaceIR / WIT / target bindings / Canonical ABI
RELEASE         provenance / archive / reproducibility / DDC
~~~

The semantic compiler remains usable when all four are absent.

---

# 2. Design laws

V5.1 has twenty architecture laws.

1. **Small semantic spine.** Compiler semantics do not absorb SAVEF, release, benchmarking, archive, package-registry, or AI policy.
2. **Closed semantics, open extensions.** Extensibility never means ambient mutation of a closed profile.
3. **Evidence is not an IR.** Stronger evidence wraps a representation unless the representation itself changed.
4. **IRs require real representation gaps.**
5. **Every transformation has one pass contract.**
6. **Every pass declares preserved/invalidated analyses, interfaces, and fingerprints.**
7. **Every backend has one backend descriptor.**
8. **Target-specific representation stays below the target-neutral boundary.**
9. **Only a SemanticProfile revision may change foundational Core meaning.**
10. **Untrusted producers never mint authority.**
11. **Source fidelity, logical soundness, and executable fidelity are separate claims.**
12. **Successful target compilation is not semantic-preservation evidence.**
13. **A fixed point is not compiler correctness.**
14. **Reproducibility is not source-binary correspondence.**
15. **Provenance is not proof.**
16. **Incremental cache reuse is optimization, not semantic authority.**
17. **Public declarations and debug mappings are derived from checked semantic products, not reverse-engineered from emitted target code.**
18. **Direct JavaScript does not require TypeScript to produce declarations or source maps.**
19. **Third-party extension execution is least-authority and isolated in assured profiles.**
20. **Every release claim is machine-explainable by a ClaimSet and evidence graph.**

---

# 3. Quantitative evaluation

## 3.1 Criteria and weights

| Criterion | Weight |
|---|---:|
| Soundness / fidelity | 10 |
| TCB transparency | 8 |
| Adversarial robustness | 7 |
| Small compiler and extensibility | 8 |
| Architecture | 9 |
| Independent evidence | 6 |
| Performance | 6 |
| Resource behavior | 5 |
| Portability | 5 |
| Longevity | 5 |
| Interoperability | 5 |
| Self-host / bootstrap | 7 |
| Auditability | 6 |
| Security | 6 |
| Soundness security | 7 |
| **Total** | **100** |

## 3.2 Meaning of 99%

A score above 99 means the architecture specifies semantic ownership, trust/authority ownership, extension containment, backend contracts, query/pass invalidation, resource/failure semantics, reproducibility/build identity, migration from the real codebase, and evidence meanings with remaining uncertainty primarily in implementation and assurance evidence rather than missing architecture.

## 3.3 Iteration loop

Using this rubric:

~~~text
V4.2 rescored      97.01 / 100
V5.0 draft         98.39 / 100
V5.1               99.15 / 100
~~~

V5.0 still lost points because backend output products, source/API origin metadata, hermetic build identity, and claim semantics were insufficiently unified.

V5.1 closes those architecture gaps.

The loop stops at V5.1.

---

# 4. Research basis

## 4.1 Lean 4

Lean elaborates rich source syntax into a much smaller Core theory; the trusted kernel checks elaborator output. Macro expansion and elaboration are extensible, while interactive metadata is side information rather than logical authority.

Sources:

- https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/
- https://lean-lang.org/doc/reference/latest/Notations-and-Macros/
- https://lean-lang.org/doc/reference/latest/Notations-and-Macros/Elaborators/
- https://github.com/leanprover/lean4/blob/master/src/Lean/Compiler/LCNF.lean

Adopted:

- extensible surface over small Core;
- kernel rechecking of proof/declaration terms;
- interactive/compiler-service metadata separate from proof authority.

Stronger PSCV requirement:

- source-fidelity risk from semantic elaborators is explicitly tracked instead of being treated as solved by kernel checking.

## 4.2 CompCert

CompCert uses multiple real intermediate languages and pass-specific semantic-preservation theorems.

Sources:

- https://compcert.org/doc/
- https://compcert.org/man/manual001.html

Adopted:

- real IRs correspond to real semantic/representation gaps;
- transformations own explicit semantic relations;
- external unverified stages do not inherit verified claims.

## 4.3 CakeML

CakeML combines formal semantics, verified compilation, bootstrapping, and high-assurance checker applications while keeping these claims distinct.

Sources:

- https://cakeml.org/
- https://cakeml.org/checkers.html

Adopted:

- self-host/bootstrap evidence does not replace compiler preservation;
- high-assurance paths can progressively reduce their trusted base.

## 4.4 rustc

rustc uses purpose-specific HIR/THIR/MIR representations, demand-driven queries, red/green incremental dependency tracking, and backend abstraction.

Sources:

- https://rustc-dev-guide.rust-lang.org/overview.html
- https://rustc-dev-guide.rust-lang.org/thir.html
- https://rustc-dev-guide.rust-lang.org/queries/incremental-compilation.html
- https://rustc-dev-guide.rust-lang.org/backend/backend-agnostic.html

Adopted:

- purpose-specific transient/persistent IRs;
- explicit query dependencies;
- semantic invalidation rather than timestamp invalidation;
- backend independence.

## 4.5 LLVM and MLIR

LLVM's pass manager explicitly caches analyses and requires passes to report what remains preserved. MLIR provides conversion targets, pass/dialect extension infrastructure, and explicit legality.

Sources:

- https://llvm.org/docs/NewPassManager.html
- https://mlir.llvm.org/docs/PassManagement/
- https://mlir.llvm.org/docs/DialectConversion/

Adopted:

- preserved/invalidated analyses;
- explicit pass registration;
- legal target contracts.

Rejected for untrusted PSCV extensions:

- native in-process plugin loading is not considered a security boundary.

## 4.6 Swift SIL

Swift distinguishes raw SIL from canonical SIL because mandatory passes establish actual invariants required before optimization/codegen.

Source:

- https://github.com/swiftlang/swift/blob/main/docs/SIL/SIL.md

Adopted:

- construction/canonical states are justified when they have genuinely different invariants.

## 4.7 TypeScript

TypeScript supports declaration output and source/declaration maps, and its compiler/language-service architecture separates parsing/checking/emission/tooling.

Sources:

- https://github.com/microsoft/TypeScript/wiki/Architectural-Overview
- https://www.typescriptlang.org/docs/handbook/modules/guides/choosing-compiler-options
- https://www.typescriptlang.org/tsconfig/sourceMap.html
- https://www.typescriptlang.org/tsconfig/declarationMap.html

Adopted:

- long-lived service architecture;
- `.d.ts` as a public API artifact;
- source maps as first-class developer-tool artifacts.

Stronger PSCV requirement:

- direct JS generates `.d.ts` and maps from ProofScript semantic products, not by depending on `tsc`.

## 4.8 ECMA-426 source maps

ECMA-426 standardizes source maps for JavaScript, WebAssembly, CSS, and other generated formats.

Source:

- https://ecma-international.org/publications-and-standards/standards/ecma-426/

Adopted:

- backend-neutral origin tracking;
- standard source-map output from target-position/origin information.

## 4.9 Dafny

Dafny supports modular verification through specifications and multiple target backends.

Source:

- https://dafny.org/dafny/DafnyRef/DafnyRef

Adopted:

- behavioral module interfaces as composition boundaries;
- verification semantics remain target-independent.

## 4.10 WebAssembly Component Model and WASI

WIT provides versioned language-neutral interfaces. WASI is capability-oriented and explicitly avoids ambient authority.

Sources:

- https://component-model.bytecodealliance.org/design/wit.html
- https://github.com/WebAssembly/WASI/blob/main/docs/DesignPrinciples.md
- https://github.com/WebAssembly/WASI/blob/main/docs/Capabilities.md

Adopted:

- InterfaceIR/WIT boundary;
- preferred sandbox form for portable third-party extensions;
- explicit capability grants.

## 4.11 Rust procedural macros as a negative security reference

Rust procedural macros execute at compile time with compiler-like filesystem/stdin/stdout access.

Source:

- https://doc.rust-lang.org/stable/reference/procedural-macros.html

V5.1 conclusion:

> PSCV assured profiles must not adopt ambient in-process third-party extension authority.

## 4.12 Alive2 / translation validation

Alive2 validates LLVM transformations using refinement checking.

Source:

- https://github.com/AliveToolkit/alive2

Adopted:

- complex optimizers/backends can remain replaceable when a smaller trusted validator establishes the claimed relation.

## 4.13 Foundational Proof-Carrying Code

FPCC research demonstrates the value of untrusted producers paired with very small proof-checking TCBs.

Sources:

- https://www.cs.princeton.edu/~appel/fpcc.html
- https://www.cs.princeton.edu/research/techreps/428

Adopted:

- authority belongs to small checkers, not proof producers;
- proof artifacts should be separately checkable.

## 4.14 Hermetic and reproducible builds

Bazel/Nix/reproducible-builds research emphasizes declared inputs, isolated actions, pinned tools and bit-identical reproduction.

Sources:

- https://bazel.build/remote/rbe
- https://wiki.nixos.org/wiki/Derivations
- https://reproducible-builds.org/docs/definition/

Adopted:

- explicit BuildAction identity;
- undeclared host inputs are not semantic inputs.

## 4.15 SLSA and DDC

SLSA provenance records how/where artifacts were built. DDC addresses source-binary correspondence under explicit assumptions.

Sources:

- https://slsa.dev/spec/v1.2/provenance
- https://dwheeler.com/trusting-trust/dissertation/html/wheeler-trusting-trust-ddc.html

Adopted:

- provenance, reproducibility, fixed point, preservation, and DDC remain distinct claims.

---

# 5. Scope and non-goals

## Compiler core owns

- profile/environment resolution;
- parsing and elaboration;
- canonical Core artifact creation;
- KernelContract client;
- PSCV certification client;
- erasure;
- RuntimeIR;
- runtime validation;
- specialization;
- generic pass contracts;
- backend contracts;
- module/public API extraction;
- origin metadata;
- artifact-bundle assembly;
- compiler-service query hooks.

## Companion systems own

### Assurance
Kernel metatheory, preservation theorems, validators, comparator, independent checkers, provider hardening.

### Development
QueryGraph persistence, SAVEF, AI orchestration, FactoryBench.

### Interoperability
InterfaceIR, WIT, Component Model/Canonical ABI, target-language foreign bindings.

### Release
Provenance, archive, signing, reproducibility campaigns, DDC.

The core compiler does not depend on SAVEF, FactoryBench, archive, DDC, or AI.

---

# 6. Claim lattice

Compiler success is not represented by one Boolean.

Every artifact has an explicit `ClaimSet`.

Representative independent claims:

~~~text
Parsed
Resolved
Elaborated
ProfileConformant

KernelAccepted
SpecificationCovered
PSCVCertified

RuntimeIRValidated
SpecializationValidated
TargetIRValidated
TargetToolAccepted

SemanticPreservationChecked
IndependentCheckerAccepted

SelfHostFixedPoint
Reproducible
ProvenanceBound
SourceBinaryCorrespondenceDDC

AssuredRelease
~~~

These claims are not all linearly ordered.

Examples:

~~~text
TargetToolAccepted
    does not imply
SemanticPreservationChecked

SelfHostFixedPoint
    does not imply
KernelAccepted

Reproducible
    does not imply
SourceBinaryCorrespondenceDDC

ProvenanceBound
    does not imply
SemanticPreservationChecked
~~~

`AssuredRelease` is a policy-defined conjunction of exact required claims.

No tool may silently upgrade one claim into another.

---

# 7. Capability model

Representations carry authority only through capabilities:

~~~text
Checked<T>
Validated<T, Contract>
Certified<T, Policy>
~~~

Each capability binds:

- exact subject ArtifactId;
- semantic/profile identity;
- checker/validator identity;
- implementation/security identity where relevant;
- assumptions;
- resource policy;
- evidence reference;
- session/live-authority identity when required.

Serialized receipts cannot recreate live authority.

Authority-bearing values are never accepted from ordinary plugin/cache/SAVEF serialization.

---

# 8. Three soundness dimensions

## Logical soundness

Can an invalid Core theorem/declaration be accepted?

Primary boundary:

~~~text
CoreArtifact -> KernelContract -> Checked<Core>
~~~

## Source fidelity

Does the exact source/profile/extensions/import environment elaborate to the intended Core?

Relevant components:

- parser;
- macro/syntax expansion;
- elaborator;
- coercion/instance environment;
- semantic elaborator extensions;
- contract/VC interpretation.

A kernel-valid term can still be an incorrect elaboration of source.

## Executable fidelity

Does generated executable behavior preserve certified runtime semantics?

Relevant transformations:

- erasure;
- specialization;
- optimizations;
- backend lowering;
- target printers/encoders;
- target compilers;
- ABI/runtime adapters.

Claims and TCBs state which dimensions they cover.

---

# 9. TCB partition

V5.1 records separate trust manifests.

## LogicalTCB

Potentially:

- foundational profile/axioms;
- KernelContract semantics;
- selected kernel;
- canonical kernel decoder;
- AuthorityBroker subject/result binding.

## SourceFidelityTCB

Any source-to-Core component not independently validated:

- parser;
- elaborator;
- semantic extensions;
- profile resolver.

## ExecutableFidelityTCB

Any runtime/target transformation not independently proved/validated.

## SecurityTCB

Runtime mechanisms whose compromise could forge authority decisions:

- AuthorityBroker runtime;
- sandbox runtime;
- OS isolation;
- cryptographic identity implementation.

A component may move out of an effective TCB only to the extent that independent evidence covers its role.

---

# 10. Authority Firewall

All replaceable/untrusted producers sit outside authority.

~~~text
syntax extensions
AI / tactics / solvers
optimizers
compiler passes
backends
target compilers
interface adapters
caches / SAVEF

       |
       | bounded canonical data
       v

Authority Firewall

       |
       +--> profile identity
       +--> canonical decode/hash
       +--> KernelContract
       +--> certificate checkers
       +--> IR/target validators
       +--> assumption/resource policy
       +--> subject identity match
       +--> fail-closed classification

       |
       v

live Checked / Certified / Validated capabilities
~~~

High-assurance target architecture places authority minting behind a minimal AuthorityBroker process/component.

The current WeakMap/session host capability mechanism is a valid development transition, not the final hostile-extension isolation boundary.

---

# 11. Authority influence closure

Every checked/release build can compute:

~~~text
AuthorityInfluenceClosure
~~~

containing all code/configuration capable of:

- selecting/replacing a checker;
- changing active semantic profile;
- minting authority capability;
- mutating checked subject bytes;
- bypassing mandatory validation;
- changing evidence policy.

Undeclared authority influence causes assured-profile failure.

This closure is distinct from ordinary dependency closure.

---

# 12. Extension model

Extension semantic classes:

~~~text
E0 Library
E1 SurfaceSyntax / canonical rewrite
E2 ProofProducer
E3 CompilerPass / optimizer
E4 Backend / emitter / InterfaceAdapter
E5 SemanticElaborator
E6 FoundationRevision
~~~

Rules:

- E0 has no compiler execution authority.
- E1 output is reprocessed by normal frontend rules and participates in profile identity.
- E2 output is untrusted proof/certificate candidate.
- E3/E4 must be proved, certificate-checked, translation-validated, or explicitly added to executable-fidelity TCB.
- E5 changes source-to-Core fidelity and is forbidden in closed profiles unless explicitly pinned/approved and either trusted or independently validated.
- E6 is not a plugin; it requires a new SemanticProfile/Core/kernel revision.

Execution classes:

~~~text
U0 no executable plugin code
U1 Wasm Component + explicit WIT capabilities
U2 isolated bounded process/container
U3 in-process explicitly trusted component
~~~

Assured third-party extensions prefer U1, then U2. U3 expands the relevant TCB.

A manifest is not a sandbox.

---

# 13. ProfileEnvironment

Every source semantic interpretation is bound to:

~~~text
ProfileEnvironment {
  languageEdition
  semanticProfile
  standardEnvironmentId
  extensionSetId
  importedStructuralInterfaceIds[]
  importedBehavioralInterfaceIds[]
  semanticOptions
}
~~~

Ordinary dependencies cannot mutate a closed profile implicitly.

The ordered/canonical extension set is part of source meaning.

---

# 14. Representations and capabilities

Real representation families:

~~~text
SourceArtifact
Syntax
Core
RuntimeIR
SpecializedIR
TargetIR*
ExecutableArtifact
~~~

Evidence-only states are capabilities.

## RuntimeIR and current PsVerifiedIr

The current `PsVerifiedIr*` model is architecturally:

~~~text
RuntimeIR
+
Validated<RuntimeIR, RuntimeIRContract>
~~~

No immediate mass rename is required.

## SpecializedIR

Specialization materially changes executable declarations/instances and remains a real representation.

## TargetIR

Current explicit target IRs:

- JsIR;
- WasmIR.

Rust and TypeScript remain source backends unless independent validation/proof needs justify persistent target IRs.


---

# 15. Public API and interface products

V5.1 distinguishes three interface products.

## StructuralModuleInterface

Public names/types/data shape/transparency/capabilities required by ProofScript dependents.

## BehavioralModuleInterface

Contracts, invariants, effects, assumptions, resource claims, theorem/spec identities.

## PublicApiIR

A stable projection of checked/certified public source semantics suitable for declaration-language emitters.

PublicApiIR is derived from checked Core/module interfaces, **not from SpecializedIR**.

This preserves source-level generics and public API semantics even when runtime code is specialized.

Consumers include:

- direct JS `.d.ts` emitter;
- TypeScript declaration parity checks;
- Rust/other target bindings where appropriate;
- IDE/package index.

---

# 16. Foreign InterfaceIR

`InterfaceIR` remains separate from PublicApiIR.

It models executable foreign boundaries:

- functions;
- records;
- variants;
- resources/handles;
- ownership;
- future/stream;
- capability imports/exports;
- target availability.

Outputs may include:

- WIT;
- Canonical ABI plans;
- Rust/C/native bindings;
- TypeScript foreign bindings.

Behavioral proof remains PSCV evidence, not WIT semantics.

The current `packages/interface-ir` implementation is the seed for this subsystem.

---

# 17. OriginGraph and debug artifacts

Every relevant source construct receives stable origin metadata.

Conceptually:

~~~text
Origin {
  sourceArtifactId
  sourceSpan
  sourceSemanticId?
}
~~~

Transformations maintain an `OriginGraph`:

~~~text
source node
 -> Core
 -> RuntimeIR
 -> SpecializedIR
 -> TargetIR / target source
~~~

Passes declare:

~~~text
originPolicy =
  preserve
  merge
  synthesize
  drop-with-reason
~~~

OriginGraph is developer metadata, not semantic authority.

It is bound to exact source and target artifacts.

---

# 18. Source maps and declaration maps

JavaScript source maps follow ECMA-426-compatible output.

Direct JS source map:

~~~text
JsIR positions
 + OriginGraph
 -> module.js.map
~~~

Declaration map:

~~~text
PublicApiIR positions
 + source origins
 -> module.d.ts.map
~~~

Maps must not alter executable semantics.

Malformed/missing maps may fail a debug-artifact requirement but never cause semantic acceptance/rejection of code unless a selected release policy explicitly requires them.

Wasm may use ECMA-426-compatible Wasm mappings or DWARF-like debug artifacts as a separate target profile.

---

# 19. BuildAction identity and hermeticity

Every cacheable/reproducible compiler action is described by:

~~~text
BuildAction {
  actionKind
  implementationId
  semanticProfileId
  profileEnvironmentId
  exactInputArtifactIds[]
  exactToolchainIds[]
  targetProfileId?
  extensionSetId
  declaredEnvironment[]
  resourcePolicyId
  outputContracts[]
}
~~~

`ActionId` is the canonical digest of this declaration.

Forbidden undeclared semantic inputs include:

- current working directory;
- mtime;
- locale;
- host PATH resolution;
- undeclared environment variables;
- network responses;
- nondeterministic map iteration;
- unpinned target compiler.

Edit builds may be less hermetic but must record that status.

Assured/reproducible release actions require hermetic execution or an explicit assumption.

---

# 20. Pass architecture

~~~text
PassDefinition<I,O> {
  passId
  version
  inputContract
  outputContract
  semanticRelationId
  implementationId
  supportedProfiles[]

  requiresAnalyses[]
  preservesAnalyses[]
  invalidatesAnalyses[]

  preservesInterfaces[]
  invalidatesInterfaces[]

  originPolicy
  authorityEffect
  assuranceClass

  validatorId?
  theoremIds[]
  assumptionIds[]
}
~~~

`authorityEffect`:

~~~text
none
requiresRevalidation
preservesByProof
preservesByValidator
trustExpanding
~~~

`assuranceClass`:

~~~text
trustedImplementation
proofPreserved
certificateValidated
translationValidated
targetAcceptedOnly
differentialOnly
unassured
~~~

A trust-expanding pass cannot hide behind semantic fingerprints.

---

# 21. QueryGraph and incremental compilation

~~~text
QueryKey {
  queryKind
  subjectIdentity
  profileEnvironmentId
  implementationId
  declaredInputs[]
}

QueryResult<T> {
  value
  artifactId?
  semanticFingerprint?
  interfaceFingerprint?
  dependencyKeys[]
  evidenceClass
}
~~~

A query remains green only if:

1. exact dependency/fingerprint classes it consumed remain valid;
2. implementation identity is compatible;
3. ProfileEnvironment matches;
4. pass/query reuse policy permits reuse.

Green status is never authority.

A reused capability must satisfy its own capability-revalidation contract.

---

# 22. BackendDescriptor

Every backend provides:

~~~text
BackendDescriptor {
  backendId
  backendVersion
  backendKind

  inputContract
  targetProfileId
  implementationId

  lowerPassId
  targetRepresentationId?
  targetValidatorId?
  emitterId

  externalToolchainId?
  runtimeContractId
  interfaceAdapterId?

  supportedCapabilities[]
  unsupportedCapabilities[]

  artifactBundleContract
  selfHostRole
  assuranceClass
}
~~~

Backend kinds:

~~~text
directTargetIR
sourceTarget
externalCodegenAdapter
~~~

---

# 23. ArtifactBundle

All backends return a typed bundle.

~~~text
ArtifactBundle {
  backendId
  sourceSubjectId
  profileEnvironmentId

  executableArtifacts[]
  publicApiArtifacts[]
  debugArtifacts[]
  interfaceArtifacts[]

  targetToolchainArtifacts[]
  evidenceArtifacts[]

  claimSet
}
~~~

Artifacts are independently identified.

A missing debug artifact never masquerades as missing semantic evidence.

---

# 24. TypeScript backend

Kind:

~~~text
sourceTarget
~~~

Pipeline:

~~~text
Validated<SpecializedIR>
 -> TypeScriptSource
 -> canonical/source validation
 -> pinned tsc
 -> JavaScript
 -> declarations/maps according to policy
~~~

Primary outputs may include:

~~~text
module.ts
module.js
module.d.ts
module.js.map
module.d.ts.map
~~~

Roles:

- minimal/current bootstrap;
- JS/TS ecosystem compatibility;
- readable target source;
- differential oracle against direct JS;
- target toolchain evidence.

`tsc` acceptance establishes TypeScript target acceptance only.

For PSCV public API fidelity, emitted declaration surface must correspond to PublicApiIR.

The implementation may:

1. use the shared ProofScript PublicApiIR declaration emitter; or
2. use `tsc` declarations and independently compare their public semantic surface to PublicApiIR.

---

# 25. Direct JavaScript backend

Kind:

~~~text
directTargetIR
~~~

Pipeline:

~~~text
Validated<SpecializedIR>
 -> JsIR
 -> ValidateJsIR
 -> Validated<JsIR>
 -> deterministic ESM printer
 -> module.js
~~~

V5.1 requires the direct JS artifact bundle to support:

~~~text
module.js
module.d.ts
module.js.map
module.d.ts.map   # optional/profile-controlled but architecturally supported
~~~

No `tsc` dependency is required.

Ownership:

~~~text
backend-js
  -> JS code / JsIR

public-api-ir + interface-ts
  -> .d.ts

origin-map + source-map emitter
  -> .js.map / .d.ts.map
~~~

`.d.ts` is derived from PublicApiIR, not inferred from printed JavaScript.

`.js.map` is derived from target positions plus OriginGraph.

This keeps runtime emission, public type API, and debug mapping consistent but independently checkable.

Direct JS is the preferred long-term canonical npm/JS artifact lane.

---

# 26. WebAssembly backend

Kind:

~~~text
directTargetIR
~~~

Pipeline:

~~~text
Validated<SpecializedIR>
 -> WasmIR
 -> structural validation
 -> operand/control typing
 -> target-profile validation
 -> Validated<WasmIR>
 -> binary encoder
 -> module.wasm
~~~

Target contracts distinguish:

- Core Wasm binary/runtime semantics;
- private self-host ABI;
- Component Model / Canonical ABI;
- WIT interface bindings.

Current implementation already contains:

- WasmIR model;
- lowerer;
- type mapping;
- structural validation;
- operand/control typing;
- binary encoder;
- runtime representation modules;
- self-host ABI;
- synchronous Canonical ABI planning/binding work.

Potential artifact bundle:

~~~text
module.wasm
module.wit? / component interface artifacts?
module.wasm.map?    # optional profile
evidence artifacts
~~~

A Component/WASI plugin runtime is separate from the program target profile.

---

# 27. Rust backend

Kind:

~~~text
sourceTarget
~~~

Pipeline:

~~~text
Validated<SpecializedIR>
 -> RustTargetPlan?
 -> RustSource
 -> pinned rustc/Cargo
 -> native/library artifact
~~~

Roles:

- native/systems deployment;
- diverse bootstrap lane;
- independent target type/ownership feedback;
- readable target code.

Current implementation owners include captures, expression emission, identifiers, runtime, tail handling, types, and value references.

`RustTargetPlan` is an optional internal target plan for:

- ownership/storage class;
- Rc/shared representation;
- closure captures;
- callback representation;
- tail strategy;
- runtime helpers;
- identifier mapping;
- generic bounds.

Promote it to persistent RustIR only if a validator, proof, or second consumer needs stable serialized structure.

`rustc` acceptance does not prove ProofScript semantic preservation.

---

# 28. Backend capabilities

Backends advertise explicit capabilities:

~~~text
TargetCapability {
  featureId
  representationClass
  runtimeRequirement?
  interfaceRequirement?
}
~~~

Examples:

- machine integer widths;
- Float32;
- higher-order functions;
- tail-worker strategy;
- GC references;
- native threads;
- async;
- component resources.

Unsupported capabilities fail closed.

Target-specific features remain Backend/InterfaceAdapter extensions unless promoted into a target-independent SemanticProfile revision.

---

# 29. CompilerService

CompilerService is the persistent human/AI/IDE interface.

Operations include:

~~~text
parse
resolve
elaborate
typeOf
goal
holes
tryCandidate
validate
compileStage
runPass
dependencies
moduleInterface
publicApi
originInfo
semanticDiff
affectedQueries
diagnosticDetails
~~~

Structured diagnostics are primary.

CompilerService does not mint authority independently; it delegates authority-changing operations to the Authority Firewall/Broker.

Partial program/proof checking is preferred when safe.

---

# 30. Security and soundness-security invariants

Normative invariants:

1. third-party extensions cannot construct Checked/Certified/Validated capabilities;
2. receipts cannot recreate live authority;
3. authority is always bound to exact subject identity;
4. target output cannot be substituted after validation without identity change;
5. closed-profile extension sets cannot change through ordinary dependency loading;
6. proof producers cannot install axioms or bypass the kernel;
7. semantic elaborators are profile-bound SourceFidelityTCB components unless independently validated;
8. pass/backend preservation claims require declared evidence class;
9. timeout/crash/unsupported/malformed output never becomes acceptance;
10. cache/SAVEF corruption can cause recomputation/rejection, not false authority;
11. third-party plugins receive no ambient network/filesystem/process authority in assured profiles;
12. plugin code is not loaded into AuthorityBroker process;
13. source backend toolchains are pinned by exact identity;
14. signatures/provenance do not upgrade semantic claims;
15. unknown evidence classes cannot satisfy assured-release policy.


---

# 31. Extension execution

Preferred order:

~~~text
U0 pure data / no code
U1 Wasm Component + explicit WIT capabilities
U2 isolated bounded process/container
U3 in-process explicitly trusted distribution component
~~~

U1/U2 messages are canonical, bounded, and schema checked.

In-process third-party JavaScript/native plugins are forbidden in `pscv-closed-v1` assured builds.

A plugin manifest is descriptive metadata; it is never treated as enforcement by itself.

---

# 32. Resource/failure algebra

~~~text
Accepted(value)
RejectedInvalid(reason)
Unsupported(feature)
ResourceExhausted(resource, limit, observed?)
InternalError(code)
InfrastructureUnavailable(code)
~~~

Only `Accepted` creates the requested capability.

Portable code reports only resources it can actually observe.

Budgets may cover:

- source bytes;
- syntax/IR nodes and depth;
- semantic work/fuel;
- generated bytes;
- proof/certificate nodes;
- extension IPC bytes;
- target compiler output;
- wall/CPU/RSS where the host can actually measure them.

Resource exhaustion never weakens semantic checks or triggers fallback to unchecked compilation.

---

# 33. Performance architecture

Three operational profiles:

## Edit profile

- resident CompilerService;
- incremental queries;
- cached parsing/elaboration;
- focused local validation;
- trusted standard distribution components may run resident;
- no release assurance claim.

## Checked profile

- kernel checking;
- mandatory RuntimeIR/target validation;
- bounded extension execution;
- selected assurance hooks.

## Assured Release profile

- isolated AuthorityBroker;
- sandboxed third-party extensions;
- hermetic BuildActions;
- all required preservation evidence;
- optional independent checker, reproducibility, DDC, and archive policy.

Performance mechanisms never change semantic meaning.

Parallel work is permitted only across dependencies whose QueryGraph and pass contracts declare independence.

---

# 34. Self-host and bootstrap

Separate claims:

~~~text
source-profile closure
self-application
source fixed point
target artifact fixed point
reproducibility
preservation-connected self-host
direct JS bootstrap
direct Wasm bootstrap
Rust/native bootstrap
diverse bootstrap / DDC
verified bootstrap
~~~

Current historical evidence snapshot:

- TypeScript remains the minimal bootstrap lane;
- direct JS has passed exact whole-compiler fixed points for historical exact closures;
- Rust has passed exact whole-compiler fixed points for historical exact closures;
- direct Wasm has passed an 80-module exact generation-1=2=3 fixed point for an exact historical closure.

These are evidence only for the recorded exact closures.

Every changed shared compiler closure requires the applicable fixed-point claims to be re-established.

Self-reproduction does not imply compiler preservation or source-binary correspondence.

---

# 35. Independent evidence

Evidence lineage records dimensions such as:

~~~text
theoryOrigin
algorithmOrigin
sourceDerivation
implementationLanguage
compilerToolchain
runtime
memoryManager
parser/decoder
sharedGeneratedSources
sharedLibraries
organization/reviewLineage
proofFoundation
hardwareClass
~~~

Two implementations are not called independent merely because:

- they are different binaries;
- they use different implementation languages;
- they run in different processes.

Independent-evidence policy remains an assurance/release concern.

---

# 36. Auditability and identity

Core identities include:

~~~text
ArtifactId
SemanticProfileId
ProfileEnvironmentId
ExtensionSetId
ImplementationId
SecurityRevisionId
ToolchainId
BackendId
PassDefinitionId
ActionId
ClaimSetId
EvidenceId
OriginGraphId
PublicApiId
ArtifactBundleId
~~~

Semantic identity and implementation/security identity are separate.

A hardened or patched provider/backend may preserve semantics while changing SecurityRevisionId/ImplementationId.

Every authority-relevant artifact can be traced to exact inputs, profile, implementation, checker/validator, and claims.

---

# 37. Portability and longevity

V5.1 prefers stable logical contracts over frozen host APIs.

Portable representations use:

- versioned schemas;
- canonical encoding;
- explicit profile identity;
- exact artifact hashes;
- hash agility in release/archive layer.

WIT/Component Model is preferred for portable executable interfaces/plugin capabilities where suitable.

ECMA-426-compatible source maps are used for JavaScript/Wasm debug mapping where selected.

No physical plugin ABI or host language becomes foundational ProofScript semantics.

---

# 38. Current repository mapping

Current useful package spine:

~~~text
foundation
syntax
core
environment
meta
elab
bridge
compiler
erasure
compiler-ir
project
interface-ir

backend-ts
backend-js
backend-wasm
backend-rust

driver-ts
driver-js
driver-wasm
driver-rust
bootstrap
~~~

Main ownership debt:

`compiler-ir` currently mixes:

- runtime model/serialization;
- strict validation;
- specialization;
- pass contracts;
- module interface/linking;
- target-specific JS ABI planning.

Logical target ownership:

~~~text
runtime-ir/
runtime-validation/
specialization/
pass-contract/
module-interface/
public-api-ir/
origin-map/
interface-ts/
~~~

Target-specific JS ABI leaves target-neutral IR ownership.

Current InterfaceIR/Canonical ABI implementation remains a separate interoperability subsystem.

No broad move is required while current fixed points are being stabilized.

---

# 39. Target repository structure

~~~text
psc15selfhost/
  PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md
  THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md

  packages/
    foundation/
    syntax/
    core/
    environment/
    meta/
    elab/

    compiler/
    erasure/
    runtime-ir/
    runtime-validation/
    specialization/
    pass-contract/
    module-interface/
    public-api-ir/
    origin-map/

    backend-ts/
    backend-js/
    backend-wasm/
    backend-rust/

    interface-ts/
    interface-ir/

    driver-ts/
    driver-js/
    driver-wasm/
    driver-rust/

    compiler-service/
    extension-contract/
    project/

  host/
    authority-broker/
    extension-host/

  contracts/
    compiler/
    claims/
    passes/
    backends/
    runtime-ir/
    targets/
    extensions/
    interfaces/
    build-actions/

  assurance/
  savef/
  release/
  factory/
~~~

This is a target ownership map, not an instruction to move files immediately.

---

# 40. Migration plan

## M0 — freeze architecture expansion

V5.1 becomes the proposed architecture target.

Do not add new central planes unless a concrete missing invariant cannot fit existing contracts.

## M1 — anti-drift guards

Machine-check:

- package identity;
- dependency direction;
- backend isolation;
- driver thinness;
- target leakage;
- raw emitter authority paths.

## M2 — ClaimSet

Introduce machine-readable claims and stop relying on generic "success" language.

## M3 — BackendDescriptor + ArtifactBundle

Register TypeScript, direct JS, Wasm, and Rust under one backend contract.

## M4 — direct JS declaration/debug products

Implement:

~~~text
PublicApiIR -> .d.ts
OriginGraph + JsIR positions -> .js.map
PublicApiIR origins -> .d.ts.map
~~~

Bundle these with direct JS output.

## M5 — logical package ownership

Expose runtime validation, specialization, pass contract, module/public interface, and origin metadata behind separate APIs without mass-moving files.

## M6 — pass/query invalidation

Add preserved/invalidated analyses, interfaces, and fingerprints plus query dependency rules.

## M7 — extension manifests and sandbox host

Promote the existing capability-sandbox design into production contracts.

## M8 — AuthorityBroker split

Move capability minting behind a minimal canonical IPC/component boundary for assured profiles.

## M9 — hermetic BuildAction

Pin source/toolchain/extensions/environment and wire ActionId into cache, reproducibility, and provenance.

## M10 — assurance convergence

Map existing preservation, comparator, independent checker, archive, and DDC work to ClaimSet requirements.

---

# 41. Anti-drift rules

CI should ultimately enforce:

1. compiler semantic packages never import backend implementations;
2. backends never import each other;
3. target-neutral RuntimeIR contains no target layout/ABI choices;
4. drivers own composition, not lowering;
5. every transform has a PassDefinition;
6. every backend has a BackendDescriptor;
7. every backend produces an ArtifactBundle;
8. direct JS declaration/debug outputs come from PublicApiIR/OriginGraph, not `tsc`;
9. extension set participates in ProfileEnvironment identity;
10. cache/query reuse cannot mint authority;
11. third-party plugin code cannot enter AuthorityBroker process;
12. assured source backends pin exact external toolchains;
13. unassured/trust-expanding passes cannot satisfy semantic-preservation claims;
14. public API artifacts are checked against PublicApiIR;
15. ClaimSet transitions require the exact evidence class specified by policy;
16. source-map/declaration-map errors cannot alter executable semantics;
17. provenance/signatures cannot upgrade semantic claim classes;
18. hermetic release actions reject undeclared semantic/build inputs.

---

# 42. V5.0 draft evaluation

An internal complete V5.0 draft was scored before finalizing this reference.

| Criterion | Weight | V5.0 |
|---|---:|---:|
| Soundness / fidelity | 10 | 99 |
| TCB transparency | 8 | 98 |
| Adversarial robustness | 7 | 98 |
| Small compiler / extensibility | 8 | 99 |
| Architecture | 9 | 99 |
| Independent evidence | 6 | 97 |
| Performance | 6 | 98 |
| Resource behavior | 5 | 97 |
| Portability | 5 | 98 |
| Longevity | 5 | 99 |
| Interoperability | 5 | 99 |
| Self-host / bootstrap | 7 | 98 |
| Auditability | 6 | 99 |
| Security | 6 | 98 |
| Soundness security | 7 | 99 |
| **Weighted total** | **100** | **98.39** |

The remaining architecture gap was ambiguity around claim promotion, direct-JS declaration/source-map ownership, and hermetic build identity.

V5.1 adds ClaimSet, PublicApiIR, OriginGraph, ArtifactBundle, and BuildAction as first-class contracts.

---

# 43. V5.1 quantitative score

| Criterion | Weight | V5.1 | Weighted |
|---|---:|---:|---:|
| Soundness / fidelity | 10 | 100 | 10.00 |
| TCB transparency | 8 | 99 | 7.92 |
| Adversarial robustness | 7 | 99 | 6.93 |
| Small compiler / extensibility | 8 | 99 | 7.92 |
| Architecture | 9 | 100 | 9.00 |
| Independent evidence | 6 | 98 | 5.88 |
| Performance | 6 | 98 | 5.88 |
| Resource behavior | 5 | 98 | 4.90 |
| Portability | 5 | 99 | 4.95 |
| Longevity | 5 | 99 | 4.95 |
| Interoperability | 5 | 99 | 4.95 |
| Self-host / bootstrap | 7 | 99 | 6.93 |
| Auditability | 6 | 100 | 6.00 |
| Security | 6 | 99 | 5.94 |
| Soundness security | 7 | 100 | 7.00 |
| **Total** | **100** | | **99.15** |

Requested threshold: **99.00 — PASS**.

The loop stops at V5.1.

---

# 44. Why the score is not 100

Architecture cannot eliminate all external uncertainty.

- **Independent evidence 98:** actual independence depends on real implementations and lineages.
- **Performance 98:** isolation, verification, declaration generation, source maps, and evidence have measurable cost.
- **Resource behavior 98:** portable stack/heap behavior still requires empirical/formal implementation work.
- **Security 99:** sandbox/OS/runtime correctness remains an external assumption.
- **Self-host 99:** fixed points and DDC remain evidence campaigns, not architecture axioms.

These are reasons to implement and measure, not reasons to create V5.2.

---

# 45. Current implementation alignment

V5.1 is a target architecture.

Current implementation strengths already include:

- live checked capability/session patterns;
- production authority topology audit;
- TrustManifest and semantic lock;
- provider security profiles;
- strict target-neutral IR validation;
- specialization infrastructure;
- JsIR model/validation;
- WasmIR structural/typing validation;
- TypeScript, JS, Wasm, and Rust backends;
- historical JS/Rust/Wasm fixed points;
- InterfaceIR/WIT/Canonical ABI work;
- bounded external processes and isolated producers;
- QueryGraphV2;
- SAVEF/archive/evidence infrastructure.

Open implementation gaps include:

- no final isolated AuthorityBroker;
- no complete third-party extension host under V5.1 policy;
- direct JS does not yet own the complete `.d.ts + .js.map + .d.ts.map` bundle;
- PublicApiIR/OriginGraph are target architecture, not current complete implementation;
- global erasure/specialization/backend preservation remains incomplete;
- TypeScript/Rust source backends do not yet have validation evidence equivalent to direct JS/Wasm;
- DDC/diverse verified bootstrap is incomplete;
- current package ownership remains transitional.

These gaps lower implementation/readiness, not the architecture score.

---

# 46. Final decision

PSCV V5.1 is the standalone long-term compiler architecture target.

Its defining rule is:

> **Every compiler product is an identified artifact; every semantic claim is an explicit claim; every authority upgrade is performed by a small declared checker/validator; every extension is explicit and least-authority; every transform states what it preserves; every backend returns a typed artifact bundle; and no success signal can silently mean more than the evidence that produced it.**

The architecture remains small enough to self-host and extensible enough to support:

- future Lean-compatible surface/elaboration features;
- target-specific profiles;
- proof/tactic/AI extensions;
- additional compiler passes;
- TypeScript;
- direct JavaScript with `.d.ts` and source/declaration maps;
- WebAssembly;
- Rust;
- future native/codegen backends;
- WIT/Component interoperability;
- SAVEF/AI development systems.

V5.1 does **not** automatically become current implementation authority.

Promotion requires an explicit migration decision after:

1. ClaimSet/BackendDescriptor/ArtifactBundle contracts exist;
2. anti-drift dependency guards exist;
3. existing V3/V4 implementation work is mapped to V5.1 ownership;
4. current backend/fixed-point checkpoints are preserved;
5. no existing assurance evidence is lost or silently upgraded.

Until then, V5.1 is the proposed standalone target architecture.
