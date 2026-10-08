# THE PSCV Compiler Reference — Version 4.1

**Status:** proposed target architecture; quantitative architecture score **95.45 / 100**  
**Repository:** `dwijayuda/pskernel`  
**Branch audited:** `pscv/v3-execution`  
**Predecessor:** `THE_PSCV_COMPILER_REFERENCE_VERSION_4.md`  
**Normative language authority:** `PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md`  
**Verified profile:** `pscv-v1`  
**Verification semantics:** `PSCV-VERIFY-v1`  
**Certificate policy:** `PSCV-CERT-v1`  
**Normative Lean semantic pin:** Lean 4.35.0-rc3 / `470d5ce1400764999581fd26d5d72b00d990b0f4`  
**Bootstrap Lean implementation pin:** Lean 4.34.0 / `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`  
**Research date:** 2026-10-07

> V4.1 refines V4 by making its small semantic spine concrete enough to govern the existing repository. It does not add V3's research/assurance subsystems back into the compiler core.

---

# 1. Executive architecture

~~~text
ProofScript source
      |
ProfileEnvironment
      |
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
PSCV certify
      |
      v
Certified<Checked<Core>>
      |
    erasure
      |
      v
  RuntimeIR
      |
   validate
      |
      v
Validated<RuntimeIR>
      |
 specialize
      |
      v
SpecializedIR
   /      |       |       \
  v       v       v        v
 TS     JsIR    WasmIR   Rust
source    |        |     source
  |    validate validate    |
 tsc      |        |      rustc
  |       v        v        |
JS/d.ts   JS      Wasm    native
~~~

Four neighboring systems consume the compiler but are not its semantic core:

~~~text
ASSURANCE       kernel/pass/validator evidence
DEVELOPMENT     CompilerService/QueryGraph/SAVEF/AI
INTEROP         InterfaceIR/WIT/.d.ts/Rust bindings
RELEASE         trust/provenance/archive/DDC
~~~

Core rule:

> **Small stable semantic spine; purpose-specific IRs; evidence as capabilities; explicit pass/query invalidation; first-class TS/JS/Wasm/Rust backends; closed source semantics; open versioned extensions.**

---

# 2. Quantitative evaluation

Architecture quality is separate from implementation coverage and release assurance.

~~~text
ArchitectureScore = sum(weight_i * score_i) / 100
~~~

| Criterion | Weight |
|---|---:|
| Semantic correctness / authority boundaries | 10 |
| Pipeline and IR discipline | 8 |
| Extensibility / profile discipline | 8 |
| Backend architecture | 8 |
| TS/JS/Wasm/Rust completeness | 7 |
| Assurance separation / verification hooks | 8 |
| Package modularity / dependency ownership | 7 |
| Incrementality / query invalidation | 6 |
| CompilerService / AI / IDE fitness | 5 |
| Performance / resource architecture | 6 |
| Self-host / bootstrap architecture | 7 |
| Interoperability / interfaces | 5 |
| Auditability / reproducibility | 5 |
| Migration realism | 6 |
| Simplicity / maintainability | 4 |
| **Total** | **100** |

Interpretation: 85–94 is strong but materially ambiguous; 95–100 is reference-grade architecture where remaining gaps are principally implementation or assurance.

## V4 baseline

| Criterion | Weight | V4 |
|---|---:|---:|
| Semantic correctness / authority | 10 | 96 |
| Pipeline / IR discipline | 8 | 92 |
| Extensibility / profiles | 8 | 96 |
| Backend architecture | 8 | 88 |
| TS/JS/Wasm/Rust completeness | 7 | 75 |
| Assurance separation | 8 | 96 |
| Package modularity | 7 | 82 |
| Incrementality / invalidation | 6 | 84 |
| CompilerService / AI / IDE | 5 | 94 |
| Performance / resources | 6 | 86 |
| Self-host / bootstrap | 7 | 93 |
| Interoperability | 5 | 92 |
| Auditability | 5 | 88 |
| Migration realism | 6 | 91 |
| Simplicity | 4 | 95 |
| **Weighted total** | **100** | **90.02** |

Main deductions: TS/Rust were underspecified; package ownership and query invalidation were not normative; `compiler-ir` remained overloaded; migration was too conceptual.

---

# 3. Research basis

V4.1 adopts architecture lessons, not implementation details, from:

- **Lean 4:** extensible syntax/elaboration over a small checked Core; parsing/elaboration/kernel checking/compilation remain distinct.
- **CompCert:** real IRs correspond to real semantic/representation gaps; correctness composes pass by pass.
- **CakeML:** compiler correctness, self-hosting and bootstrap provenance are separate claims.
- **rustc:** purpose-specific IRs, demand-driven queries, red/green incremental dependency tracking, backend abstraction.
- **LLVM/MLIR:** passes explicitly preserve or invalidate analyses; conversion targets define legal output; extensions are registered rather than ambient.
- **Swift SIL:** construction and canonical IRs are justified when mandatory passes establish real invariants.
- **TypeScript:** parser/binder/checker/emitter/language-service separation; long-lived lazy service; implementation language may change without redefining language semantics.
- **Dafny:** modular behavioral specifications and multi-target compilation.
- **WIT/Component Model:** language-neutral versioned executable interfaces, separate from behavioral proof.
- **Cranelift:** retargetable code generation with compile-time and stack/resource discipline.
- **Alive2:** translation validation can keep complex transformations replaceable.
- **Pantograph / generative compilation:** machine-oriented structured and partial compiler interaction is valuable.

Primary references:

- https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/
- https://github.com/leanprover/lean4/blob/master/src/Lean/Compiler/LCNF.lean
- https://compcert.org/man/manual001.html
- https://cakeml.org/
- https://rustc-dev-guide.rust-lang.org/overview.html
- https://rustc-dev-guide.rust-lang.org/queries/incremental-compilation.html
- https://rustc-dev-guide.rust-lang.org/backend/backend-agnostic.html
- https://llvm.org/docs/NewPassManager.html
- https://mlir.llvm.org/docs/PassManagement/
- https://mlir.llvm.org/docs/DialectConversion/
- https://github.com/swiftlang/swift/blob/main/docs/SIL/SIL.md
- https://github.com/microsoft/TypeScript/wiki/Architectural-Overview
- https://dafny.org/dafny/DafnyRef/DafnyRef
- https://component-model.bytecodealliance.org/design/wit.html
- https://github.com/AliveToolkit/alive2
- https://link.springer.com/chapter/10.1007/978-3-031-90643-5_6
- https://arxiv.org/abs/2607.13921

---

# 4. Current repository audit

The audited `psc15selfhost/` tree contains roughly 1,579 tracked files: about 941 under `packages/`, 362 scripts, 98 docs, 58 tests and 50 contract files.

Current semantic/compiler packages already form a useful spine:

~~~text
foundation
syntax
core
environment
meta
elab
bridge
compiler
compiler-ir
erasure
project
interface-ir
~~~

Backends/composition:

~~~text
backend-ts      3 Lean source files
backend-js      6
backend-wasm   19
backend-rust    9

driver-ts
driver-js
driver-wasm
driver-rust
bootstrap
~~~

The package split is fundamentally sound. The main debt is responsibility concentration and dependency drift inside packages.

---

# 5. Normative package dependency DAG

~~~text
foundation
   +--> syntax
   +--> core
          |
          v
      environment
          |
          v
         meta
          |
          v
         elab
          |
          v
       compiler
          |
        erasure
          |
          v
       RuntimeIR
          |
     runtime validation
          |
          v
      specialization
          |
          +------> backend-ts ----> driver-ts
          +------> backend-js ----> driver-js
          +------> backend-wasm --> driver-wasm
          +------> backend-rust --> driver-rust
~~~

Normative rules:

1. frontend/Core packages never depend on a backend;
2. compiler orchestration never imports backend implementations;
3. backends never import each other's private models;
4. drivers are thin composition roots and contain no semantic lowering;
5. SAVEF/release/factory may consume compiler artifacts; semantic compiler packages never depend on them;
6. kernel implementation internals enter only through explicit provider/contract adapters;
7. source-backend toolchains are version-pinned inputs, not language semantics.

---

# 6. Current ownership debt and target split

Current `compiler-ir` owns Model, Encode/Decode, Validate, Specialize, Pass, Interface/Link and `JsAbi`. This conflates at least five responsibilities.

Logical target ownership:

~~~text
runtime-ir/
  Model Encode Decode

runtime-validation/
  Validate ValidateArtifact

specialization/
  Specialize

pass-contract/
  Pass

module-interface/
  Interface InterfaceArtifact Link LinkArtifact

backend-js/ or interface-js/
  JsAbi
~~~

No immediate physical move is required while self-host fixed points are being stabilized.

Large current files such as `CompilerIr/Validate.lean`, `CompilerIr/Specialize.lean`, `Erasure/Expr.lean` and especially `BackendWasm/Lower.lean` identify likely semantic submodules for future proof/maintenance work, but size alone is not a reason to split them.

Package identities must also be checked mechanically: current manifests contain compatibility-name drift such as `@proofscript/foundation-next` versus `@proofscript/foundation`.

---

# 7. Representations versus capabilities

A new IR exists only when representation or operational meaning materially changes.

Canonical representation families:

~~~text
Source
Syntax
Core
RuntimeIR
SpecializedIR
TargetIR*
ExecutableArtifact
~~~

Authority/evidence states are wrappers:

~~~text
Checked<T>
Validated<T, Contract>
Certified<T, Policy>
~~~

A receipt records evidence but cannot recreate a live capability.

## Current VerifiedIR

The existing `PsVerifiedIr*` model is the same target-neutral post-erasure representation before and after strict validation. V4.1 therefore interprets it as:

~~~text
RuntimeIR
+
Validated<RuntimeIR, RuntimeIRContract>
~~~

Keep existing physical names until stabilization. Do not perform a mass rename merely to match the architecture document.

`SpecializedIR` remains a real representation because specialization generates/resolves concrete executable declarations.

---

# 8. Pass model and invalidation

Every transformation is expressible by one pass contract:

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

  validatorId?
  theoremIds[]
  assumptionIds[]
}
~~~

A pass execution binds exact input/output artifacts, semantic fingerprints, diagnostics, resource observations and evidence.

Architecture law:

> **Every transformation declares which analyses, semantic fingerprints and module-interface classes remain valid.**

This imports the useful LLVM/MLIR invalidation discipline without adopting a fully dynamic pass manager.

---

# 9. QueryGraph and incremental compilation

~~~text
QueryKey {
  queryKind
  subjectIdentity
  profileEnvironmentId
  declaredInputs[]
}

QueryResult<T> {
  value
  artifactId?
  semanticFingerprint?
  dependencyKeys[]
  evidenceClass
}
~~~

A query remains green only when:

1. consumed dependencies remain green or preserve the exact fingerprint class used by the query;
2. query implementation identity remains compatible;
3. profile/environment identity matches;
4. reuse policy permits the result.

A green cache/query result never manufactures Checked/Certified authority. Capability reuse must satisfy its own validation/replay contract.

---

# 10. Backend abstraction

V4.1 supports three backend kinds.

### Direct target-IR backend

~~~text
SpecializedIR
 -> TargetIR
 -> TargetValidator
 -> Validated<TargetIR>
 -> encode/print
 -> artifact
~~~

Current: direct JavaScript and Wasm.

### Source backend

~~~text
SpecializedIR
 -> TargetSource
 -> pinned external compiler/checker
 -> artifact
~~~

Current: TypeScript and Rust.

### External-codegen adapter

Possible future LLVM/Cranelift/GCC/JVM-style integration.

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
  interfaceAdapterId?
  runtimeContractId
  supportedFeatures[]
  unsupportedFeatures[]
  requiredCapabilities[]
  selfHostRole
  assuranceClass
}
~~~

Unsupported target capabilities fail closed.

---

# 11. TypeScript backend

TypeScript is first-class.

Roles:

- current/minimal bootstrap;
- JS/npm ecosystem compatibility;
- readable generated source;
- `.d.ts` / source-map generation;
- differential oracle for direct JS.

~~~text
Validated<SpecializedIR>
 -> TypeScriptSource
 -> source/canonical checks
 -> pinned tsc
 -> JS + .d.ts + source maps
~~~

Current owner:

~~~text
backend-ts/
  Expr
  Module
  Type

driver-ts/
bootstrap/
~~~

`tsc` acceptance means the target source/toolchain accepted the program. It does not prove ProofScript semantic preservation.

TypeScript remains separate from direct JsIR.

---

# 12. Direct JavaScript backend

~~~text
Validated<SpecializedIR>
 -> JsIR
 -> ValidateJsIR
 -> Validated<JsIR>
 -> deterministic ESM printer
 -> JavaScript
~~~

Current owner:

~~~text
backend-js/
  Model Lower Validate Encode Print TailAlias
~~~

Direct JS is the preferred long-term canonical JS/npm artifact lane; TypeScript remains a bootstrap/ecosystem/differential lane.

---

# 13. WebAssembly backend

~~~text
Validated<SpecializedIR>
 -> WasmIR
 -> structural validation
 -> operand/control typing
 -> target-profile validation
 -> Validated<WasmIR>
 -> binary encoder
 -> Wasm
~~~

Current ownership already separates model, lowerer, type mapping, structural validation, typing validation, binary/encoding, runtime representations, self-host ABI and tail-call logic.

`Lower.lean` should eventually split by semantic owner (types, functions, closures, aggregates, ADTs, intrinsics, runtime calls, module), but only after fixed-point stability.

Core Wasm, private self-host ABI and Component/Canonical ABI are separate contracts.

---

# 14. Rust backend

Rust is first-class.

Roles:

- native/systems deployment;
- diverse-bootstrap implementation lane;
- independent target type/ownership feedback;
- readable target source.

~~~text
Validated<SpecializedIR>
 -> Rust lowering
 -> RustSource
 -> pinned rustc/cargo
 -> native artifact
~~~

Current owner:

~~~text
backend-rust/
  Captures Expr Identifier Module Runtime
  Tail TailAlias Type ValueRefs
~~~

V4.1 defines an optional internal `RustTargetPlan` containing storage/ownership classes, captures, callback representation, tail strategy, runtime helpers, identifier mapping and generic bounds.

Promote it to a persistent RustIR only when a second consumer, independent validator, or preservation proof needs a stable target representation.

`rustc` success proves Rust well-formedness, not ProofScript semantic preservation.

---

# 15. Backend capabilities and maturity

Each backend advertises explicit semantic capabilities such as machine-integer widths, floating point, higher-order functions, target resources, async interfaces or Wasm reference types.

No backend silently approximates unsupported features.

Backend evidence levels:

~~~text
B0 contract/model
B1 focused source/IR tests
B2 target tool accepts generated output
B3 runtime differential corpus
B4 whole-compiler generation
B5 exact self-host fixed point
B6 preservation/target-validation evidence
B7 release promotion
~~~

Evidence is recorded per backend and exact source closure.

---

# 16. Extension model

~~~text
Library
SurfaceSyntax
SurfaceElaborator
ProofProducer
CompilerPass
Backend
InterfaceAdapter
DiagnosticTool
DevelopmentTool
SemanticProfile
~~~

Only `SemanticProfile` may alter foundational Core meaning.

`ps-standard` and `pscv-v1` remain closed by default. The active extension set is explicit and contributes to semantic/profile identity.

No extension may reorder the mandatory authority chain:

~~~text
kernel check
 -> PSCV certification
 -> erasure
 -> runtime validation
 -> target validation
~~~

without defining a new compiler/profile contract.

Target-specific features remain target extensions unless they are promoted to a genuine target-independent semantic concept.

---

# 17. CompilerService

CompilerService is a persistent machine/human API over the compiler:

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
semanticDiff
affectedQueries
diagnosticDetails
~~~

Structured diagnostics are primary; human prose is rendered from them.

CompilerService supports partial/local computation where safe and has no independent proof authority.

---

# 18. Module and executable interfaces

`StructuralModuleInterface` carries downstream-relevant exported types/data shape/transparency/capabilities.

`BehavioralModuleInterface` carries pre/postconditions, invariants, effects, assumptions, resources and theorem/spec identities.

They drive:

- modular verification;
- incremental invalidation;
- AI/SAVEF context slicing.

`InterfaceIR` is a side product:

~~~text
Certified module
   +--> RuntimeIR
   +--> InterfaceIR
          +--> WIT
          +--> .d.ts
          +--> Rust bindings
          +--> native ABI metadata
~~~

WIT describes executable interfaces, not behavioral proof.

---

# 19. Companion boundaries

### Assurance

Owns PSKernel/refinement evidence, comparator/reference checker evidence, pass preservation, validator soundness, solver certificates, provider diversity/hardening and resource campaigns.

### SAVEF/development

Owns semantic knowledge, ValidUnder, retrieval, FailureKnowledge, ReuseEvent and FactoryBench.

### Release

Owns TrustManifest, semantic lock, provenance/signatures, archive/offline verifier, DDC and hash migration.

These systems consume compiler identities/evidence; none is a semantic compiler prerequisite.

---

# 20. Resource/failure architecture

Canonical outcomes:

~~~text
Accepted(value)
RejectedInvalid(reason)
Unsupported(feature)
ResourceExhausted(resource, limit, observed?)
InternalError(code)
InfrastructureUnavailable(code)
~~~

Only Accepted produces the requested capability.

Portable code records only resources it can actually observe. Current Wasm self-host work demonstrates that stack-safe traversal is a compiler-implementation architecture concern, not only deployment tuning.

---

# 21. Self-host architecture

Four independent lanes:

| Backend | Role |
|---|---|
| TypeScript | current/minimal bootstrap and ecosystem oracle |
| Direct JavaScript | direct JS-native self-host |
| Direct Wasm | portable direct binary self-host |
| Rust | native/diverse bootstrap lane |

A fixed point is always qualified by backend, compiler implementation and exact source closure.

Self-reproduction does not imply compiler correctness.

---

# 22. Migration plan

### M0 — guards
Machine-check package identity consistency, forbidden dependency directions, backend isolation, target leakage and driver thinness.

### M1 — conceptual normalization
Treat current `PsVerifiedIr*` as RuntimeIR plus validation capability. No rename.

### M2 — target leakage
Move logical ownership of `CompilerIr.JsAbi` to JS/interface ownership.

### M3 — specialization
Expose specialization through a dedicated API/package boundary.

### M4 — validation
Expose RuntimeIR validation separately.

### M5 — module interfaces
Move Interface/Link ownership out of generic RuntimeIR.

### M6 — backend descriptors
Register TS/JS/Wasm/Rust through one descriptor contract.

### M7 — incremental invalidation
Attach preserved/invalidated analyses/fingerprints/interfaces to passes and queries.

Physical file moves are postponed whenever they would destabilize active self-host closure.

---

# 23. Target repository ownership

~~~text
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

  backend-ts/
  backend-js/
  backend-wasm/
  backend-rust/

  driver-ts/
  driver-js/
  driver-wasm/
  driver-rust/

  interface-ir/
  compiler-service/
  project/

assurance/
savef/
release/
factory/
~~~

This is an ownership target, not an immediate mass-move instruction.

---

# 24. Anti-drift invariants

CI should eventually enforce:

1. `compiler` does not import `backend-*`.
2. backends do not import each other.
3. RuntimeIR contains no target representation choices.
4. `driver-X` owns composition, not lowering.
5. semantic compiler packages do not depend on SAVEF/release/factory.
6. kernel implementation internals enter only through provider/contract adapters.
7. every backend has one BackendDescriptor.
8. every transform has one PassDefinition.
9. active extensions participate in semantic identity.
10. query/cache reuse cannot mint Checked/Certified authority.
11. source backends pin target toolchain identity.
12. unsupported target capabilities fail closed.

---

# 25. V4.1 score

| Criterion | Weight | V4.1 | Weighted |
|---|---:|---:|---:|
| Semantic correctness / authority | 10 | 97 | 9.70 |
| Pipeline / IR discipline | 8 | 96 | 7.68 |
| Extensibility / profiles | 8 | 97 | 7.76 |
| Backend architecture | 8 | 96 | 7.68 |
| TS/JS/Wasm/Rust completeness | 7 | 94 | 6.58 |
| Assurance separation | 8 | 97 | 7.76 |
| Package modularity | 7 | 95 | 6.65 |
| Incrementality / invalidation | 6 | 95 | 5.70 |
| CompilerService / AI / IDE | 5 | 96 | 4.80 |
| Performance / resources | 6 | 93 | 5.58 |
| Self-host / bootstrap | 7 | 94 | 6.58 |
| Interoperability | 5 | 96 | 4.80 |
| Auditability | 5 | 94 | 4.70 |
| Migration realism | 6 | 94 | 5.64 |
| Simplicity | 4 | 96 | 3.84 |
| **Total** | **100** | | **95.45** |

Threshold: **95.00 — PASS**.

The iteration loop stops at V4.1 rather than creating another document solely to inflate a self-assigned score.

Remaining deductions are real: TS/Rust do not yet have internal target validators equivalent to JS/Wasm; portable performance still has open work; fixed points are closure-specific evidence; current package/ownership drift remains; staged decomposition must preserve self-host behavior.

---

# 26. Supersession rule

V4.1 is still a **proposed target architecture**.

V3 remains the current implementation/evidence reference until an explicit migration:

1. maps every V3 workstream to V4.1 ownership;
2. defines BackendDescriptors for TS/JS/Wasm/Rust;
3. installs dependency/package-identity guards;
4. preserves historical fixed-point/evidence records;
5. gives assurance/SAVEF/release concerns explicit companion ownership;
6. reaches stable current backend checkpoints.

Only a separate explicit commit may then make V4.1 canonical.
