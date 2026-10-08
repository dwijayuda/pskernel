# THE PSCV Compiler Reference

**Status:** canonical target architecture and repository-structure reference for `psc15selfhost/`.
**Repository baseline audited:** `addcd4b7dcb783a493d1842a4b3df50b8945748d` on `psc2/selfhost-lean-kernel`.
**Location:** `psc15selfhost/THE_PSCV_COMPILER_REFERENCE.md`.

> This file adopts the strongest material from `PSCV_COMPILER_REFERENCE_VERSION_2.md`, reconciles it with the actual `psc15selfhost/` code at the baseline above, and adds a stricter current-vs-target score. It is a target architecture document, not a claim that planned proof, SAVEF, or authority work is already implemented.

## Canonical synthesis update — 2026-10-06

The current code already implements more than the older diagrams imply in one area and less in another:

- `PsErasedIrModule -> psValidateErasedIrModule -> PsValidatedIrModule` is a real implemented post-erasure validation boundary. `psc-verified-ir/1` is therefore not merely aspirational.
- The current validator is intentionally incomplete: it does not yet establish every name/scope/call/type/intrinsic/field/match/module-link invariant required by the final VerifiedIR meaning.
- `Ps.Compiler.Api` still permits `PsCompilerAdmissionReadyModule -> erasure -> validated IR` without requiring a provider-owned checked capability. This is the highest-priority production authority gap.
- `proofscript-kernel-contract/1` is frozen and already gives PSCV the right provider-neutral seam. The production compiler should consume a `CheckedCoreCapability` created only after that contract accepts the exact canonical admissions bundle.
- `pskernel-core` has a strong explicit execution architecture, machine-readable TCB, declared Lean-4.34 compatibility/conformance closure, bounded performance/resource evidence, and an M4 dual-provider readiness plan; provider promotion and whole-compiler metatheory remain separate claims.
- Direct JavaScript, direct WebAssembly, TypeScript, and Rust are valuable independent implementation/evidence lanes. They must refine one portable runtime meaning rather than create four meanings.
- Historical kernel trees and generated/provider source copies are valuable provenance but should be excluded or demoted in default SAVEF/AI semantic retrieval so they do not contaminate architecture reasoning.

### Canonical authority chain

```text
Source
  -> ProfileConformance
  -> Parse / Resolve / Elaborate / Meta
  -> CandidateCore
  -> CanonicalAdmissionBundle
  -> KernelContract
  -> CheckedCoreCapability
  -> PSCV-CERT / CertifiedSource
  -> Erasure
  -> RuntimeIR
  -> ValidateRuntimeIR
  -> VerifiedIR
  -> Specialize
  -> SpecializedIR
  -> JsIR | WasmIR | TS/Rust adapters
  -> target validation / encoding
  -> ExecutableArtifact
  -> EvidenceEnvelope
```

The architectural rule is structural: production emission must not be reachable from `AdmissionReady` without checked authority. Unchecked/bootstrap/test paths may exist only when explicitly named and fenced from production drivers.

### Trust classes

Do not use one undifferentiated TCB label. Track separately:

1. **Theory base** — PSCV/Lean-compatible logical rules, runtime semantic contracts, target observation models, permitted axioms/assumptions.
2. **Logical acceptance TCB** — selected kernel implementation, trusted primitive/native reductions, checked-session integration, semantic decoders able to affect acceptance.
3. **Executable validation TCB** — RuntimeIR/VerifiedIR and target validators until proved/refined.
4. **Transformation correctness TCB** — erasure, specialization, lowering and encoding until each is removed from trust by proof or translation validation.
5. **External execution assumptions** — JS/Wasm engine, OS, hardware, native toolchains, FFI implementations.
6. **Supply-chain TCB** — source revision, CI/builder, dependency retrieval, signing and registry/provenance verifiers.

A future machine-readable `TrustManifest` should bind these classes to exact source/import closures, provider lineage, contract identities, toolchain identities and generated hashes.

### Comparison with other systems

| System / idea | What is stronger or especially useful | PSCV architectural lesson |
| --- | --- | --- |
| Lean 4 | small kernel authority behind a much larger elaborator/compiler; staged bootstrap | keep smart frontend/tooling untrusted and preserve exact semantic profiles |
| Lean4Lean | Lean-specific external checker and formalized Lean theory | maintain an independent checker/metatheory relation and record derivation lineage |
| Rocq / MetaRocq | mechanized kernel theory, checker soundness/completeness work, certified erasure | separate declarative theory from executable checker and prove erasure |
| CompCert | pass-by-pass semantic preservation | give every mandatory pass a relation plus proof or small validator |
| CakeML | verified compiler plus verified/bootstrapped artifact chain | distinguish compiler correctness from bootstrap/fixed-point provenance |
| Isabelle / HOL tradition | LCF-style primitive authority and replayable proof objects | support replayable evidence through a smaller checker |
| F* / Dafny | practical effects/contracts/VC automation | make specs/effects ergonomic, but keep solver/automation outside acceptance authority |
| DeepSpec / Iris / Aneris | deep interfaces and compositional state/concurrency reasoning | make behavioral interfaces the composition boundary; add dedicated logics above the kernel |
| Proof-Carrying Code / OpenTheory / Alethe | portable producer/checker evidence patterns | distinguish local receipts, replayable Core, portable certificates and cross-foundation evidence |
| WIT / Wasm Component Model | portable interfaces/worlds/capability-shaped composition | use WIT as an InterfaceIR adapter, not PSCV's semantic type theory |
| SLSA / in-toto / DDC | provenance and trusting-trust defenses | keep semantic proof, provenance, reproducibility and source-binary correspondence as separate evidence classes |

### Stronger recommended logical repository shape

The physical tree should evolve only when a real semantic, proof, query, resource, or target boundary exists:

```text
psc15selfhost/
  contracts/
  profiles/
  packages/
    foundation/ syntax/ core/ environment/ meta/ elab/ bridge/
    kernel-contract/ checked-core/
    pscv-theory/ pscv-spec/ pscv-obligation/ pscv-cert/
    compiler-contract/ compiler/ erasure/
    runtime-ir/ verified-ir/ specialized-ir/ compiler-pass-specialize/
    module-interface/ interface-ir/ capability-contract/ evidence-core/
    project/ build-graph/ artifact-codec/ artifact-store/
    semantic-lock/ package-manifest/ compiler-service/ diagnostics/
    backend-js/ backend-wasm/ backend-ts/ backend-rust/
    driver-js/ driver-wasm/ driver-ts/ driver-rust/
    pskernel-core/ pskernel-lean/ pskernel-lean-wasm/
    savef-format/ savef-index/ factory-bench/
    bootstrap/ cli/
  host/
  tools/
  test/
  evidence/
  factory/
  docs/
  archive/
```

Near term, avoid package explosion. First establish ownership inside existing packages, especially:

- `compiler/`: `Frontend`, `Prepare`, `Candidate`, `Checked`, `Internal`, `Service`;
- `compiler-ir/`: `Runtime`, `Verified`, `Specialized`, `Pass/Specialize`;
- `erasure/`: split only by theorem/invariant ownership;
- `backend-wasm/`: split the lowering monolith only along semantic/validator/resource boundaries;
- `scripts/`: migrate toward purpose-owned `tools/` groups.

### SAVEF refinement

SAVEF should treat compiler work as typed reusable knowledge, not as a pile of proof files. First-class knowledge objects should include:

- declarative theory rules and theorem interfaces;
- compiler pass contracts and preservation/validator evidence;
- CertifiedModuleInterface artifacts;
- exact assumption/effect closures;
- migration evidence;
- counterexamples and scoped failure knowledge;
- resource claims and deployment observations;
- implementation witnesses and distribution bindings.

A SAVEF/SPKF index is derived and rebuildable. It never grants theorem authority. AI can retrieve and propose from it but must pass the same deterministic authorities as any other producer.

### Proof portability levels

Use explicit levels instead of calling every receipt a proof:

- **P0 local receipt** — process/provider observation only;
- **P1 replayable canonical Core bundle** — portable across implementations of the same semantic profile;
- **P2 portable certificate/proof object** — independently specified checker can replay it;
- **P3 cross-foundation translation evidence** — translation plus preservation theorem/assumptions.

### Current implementation/evidence score

| Criterion | Current / 10 | Main reason it is not higher |
| --- | ---: | --- |
| Soundness/fidelity | 7.7 | strong kernel/provider discipline, but common pure compiler path can still erase AdmissionReady |
| TCB transparency | 8.7 | kernel TCB is explicit; compiler-wide TrustManifest is not yet unified/enforced |
| Formal/metatheoretic verification | 5.7 | checker refinement, erasure/pass/backend and whole-compiler proofs remain incomplete |
| Adversarial robustness | 7.5 | strong fail-closed provider work; compiler/SAVEF-wide bounded replay and poisoning defenses are incomplete |
| Compatibility completeness | 7.8 | strong kernel matrix; broader source/certification/IR/backend/interop matrix is incomplete |
| Architecture | 8.8 | already well layered; checked authority and phase-capability ownership still need closure |
| Independent evidence | 8.0 | multiple providers/backends exist; independence lineage and more independent checker evidence remain open |
| Performance | 7.8 | bounded kernel evidence is strong; compiler-wide semantic incrementalism/CAS remains incomplete |
| Resource behavior | 7.3 | kernel resources are first-class; compiler-wide resource contracts are not |
| Portability | 8.9 | portable self-host profiles and four backend lanes are a major strength |
| Longevity | 8.1 | frozen contracts are strong; semantic migrations/SAVEF validity lifecycle are not operational |
| Interoperability | 7.4 | multi-backend support exists; InterfaceIR/WIT/capability contracts are not complete |
| Self-host/bootstrap | 9.0 | excellent discipline; verified bootstrap and canonical direct-JS/Wasm closure are separate unfinished claims |
| Auditability | 8.8 | hashes/rule maps/receipts are strong; duplicated historical/generated trees and no single registry reduce clarity |
| Novelty | 8.9 | distinctive verified-compiler + portable-evidence + self-amplifying knowledge combination |
| SAVEF | 6.4 | advanced design, but operational typed graph/reuse ledger/causal FactoryBench evidence are incomplete |
| **Equal-weight average** | **7.93** | planned work is not counted as implemented evidence |

### Target architecture score

| Criterion | Target / 10 |
| --- | ---: |
| Soundness/fidelity | 9.85 |
| TCB transparency | 9.85 |
| Formal/metatheoretic verification | 9.60 |
| Adversarial robustness | 9.75 |
| Compatibility completeness | 9.65 |
| Architecture | 9.90 |
| Independent evidence | 9.75 |
| Performance | 9.30 |
| Resource behavior | 9.55 |
| Portability | 9.75 |
| Longevity | 9.85 |
| Interoperability | 9.70 |
| Self-host/bootstrap | 9.85 |
| Auditability | 9.90 |
| Novelty | 9.70 |
| SAVEF | 9.95 |
| **Equal-weight average** | **9.74** |

No criterion is scored 10. Real hostile-input experience, independent replication, long-lived ecosystem operation, and formal closure can still invalidate assumptions.

### Priority migration

1. **Close the checked-authority bypass**: production erasure/emission requires `CheckedCoreCapability`.
2. **Create/enforce TrustManifest** over compiler + kernel acceptance closure.
3. **Finish the VerifiedIR invariant gap matrix** and strengthen/version the validator monotonically.
4. **Make SpecializedIR explicit** and share target-neutral specialization.
5. **Unify PassDefinition, BuildAction, SemanticFingerprint and EvidenceEnvelope**.
6. **Seed declarative Core metatheory** with stable rule IDs aligned to current pskernel rule ownership.
7. **Prove checker refinement slices**, then erasure and specialization preservation.
8. **Implement ModuleInterface-v1** and drive QueryGraph semantic invalidation from it.
9. **Use direct Wasm as the first strongest portable target-preservation/translation-validation lane**.
10. **Implement minimal SPKF only after identities/benchmarks are frozen**, then run causal FactoryBench before claiming self-amplification.

### Immediate acceptance gate

The next architecture milestone is complete only when the normal production driver cannot reach erasure from AdmissionReady, a checked capability binds exact admissions/profile/contract/provider identity, and CI proves that dependency/import topology.

---

## Adopted detailed reference

The remainder of this file is the detailed Version 2 research reference adopted into this canonical location, with the synthesis above taking precedence where it is more specific or reflects the newer branch audit.


**Status:** proposed canonical target architecture and migration reference.  
**Repository:** dwijayuda/pskernel  
**Architecture branch reviewed:** psc2/selfhost-lean-kernel  
**Repository head reviewed:** a704d06f4105245935a4d301f2ef97165a0084a1  
**Compiler code baseline under the documentation-only head:** 304706da6d3775a716561870110b7e7f5b46ac03  
**Previous reference:** PSCV_COMPILER_REFERENCE.md  
**Research date:** 2026-10-06  
**Design score on the 16-criterion rubric in this document:** **9.61 / 10**  
**Minimum criterion score:** **9.2 / 10**  
**Implementation status:** this score evaluates the target architecture, not current implementation completeness.

---

# 1. Executive decision

The previous PSCV compiler reference got the central architectural direction right:

> strengthen and enforce the semantic spine already present in the repository rather than creating a parallel compiler architecture.

After comparing that reference and the current codebase with:

- Lean 4 architecture and type theory;
- Lean's staged bootstrap and current LCNF compiler;
- Lean's comparator / external-checker security model;
- MetaRocq;
- CompCert;
- CakeML;
- Rocq / the de Bruijn criterion;
- Agda safe mode;
- F* / Low* / KaRaMeL;
- Why3;
- Proof-Carrying Code and Foundational PCC;
- translation validation;
- Salsa-style red/green incremental computation;
- build-system theory;
- WebAssembly and the Component Model;
- retrieval-augmented theorem proving;

the architecture should be strengthened in six major ways.

1. **Add an explicit declarative semantic specification layer.**  
   The executable kernel/checker must refine a separately stated theory rather than serving as its own only specification.

2. **Make semantic preservation the organizing theorem of the compiler.**  
   RuntimeIR validation, erasure, specialization, and every certified backend pass need explicit refinement/preservation relations, following the compositional pattern demonstrated by CompCert and CakeML.

3. **Separate Lean compatibility from the strongest metatheoretic profile.**  
   Lean compatibility must preserve Lean's actual behavior, including theory properties that are intentionally unusual. A stricter certified PSCV profile may target stronger metatheory, but only through an explicit profile relation rather than pretending full Lean has properties it does not have.

4. **Add a comparator-style high-assurance verification lane.**  
   A process-local checked handle is a strong normal-production capability but is not sufficient protection against malicious same-process compiler/meta code. High-risk verification must isolate untrusted generation, export canonical semantic material, and replay it in independently controlled checkers.

5. **Turn resource behavior into a semantic engineering contract.**  
   Resource exhaustion, unsupported input, semantic rejection, infrastructure failure, and acceptance must remain distinguishable. Compiler passes need declared budgets and measured complexity; caches and fixed-point workflows need resource-aware incremental execution.

6. **Make SAVEF a typed evidence-and-knowledge graph, not merely a retrieval index.**  
   SAVEF knowledge must carry semantic scope, assumptions, evidence class, checker policy, validity range, dependencies, supersession/refinement, negative knowledge, and actual reuse edges. Retrieval remains untrusted; acceptance remains checker-controlled.

The resulting target architecture has all 16 requested criteria at or above 9/10.

---

# 2. What this document is and is not

This document is the proposed architectural successor to PSCV_COMPILER_REFERENCE.md.

It defines:

- semantic and trust boundaries;
- formal-verification targets;
- compiler phase ownership;
- evidence requirements;
- self-host/bootstrap meaning;
- incremental-build semantics;
- SAVEF integration;
- target package/file structure;
- migration order;
- acceptance criteria.

It does **not** claim that every described component already exists.

Every statement in this reference should be understood as one of:

- **CURRENT** — directly implemented in the reviewed repository;
- **TESTED** — supported by repository tests or CI, but not a formal proof;
- **TARGET** — recommended architecture to implement;
- **PROOF TARGET** — theorem or formal result that should eventually be machine checked;
- **RESEARCH TARGET** — worthwhile but not yet required for the next production milestone;
- **HISTORICAL** — retained only for provenance or regression comparison.

---

# 3. Authority hierarchy

When sources disagree, use this order.

1. Frozen machine-readable language, kernel, runtime, ABI, artifact, and evidence contracts.
2. Formal declarative semantic specifications for the selected profile.
3. Machine-checked theorems over those specifications.
4. Current executable checker/kernel behavior for the selected compatibility identity.
5. This reference.
6. Current production architecture documents and accepted ADRs.
7. Implementation roadmaps.
8. SAVEF research plans.
9. Historical experiments, archived branches, and old status files.

No prose reference may silently override a frozen machine identity.

No current implementation bug becomes semantics merely because it exists.

No planned theorem is treated as proved.

---

# 4. Research conclusions from Lean 4

## 4.1 Lean's strongest architectural lesson: small checking authority

Lean follows the proof-producing architecture in which a large frontend, elaborator, tactic system, macro system, compiler, and metaprogramming environment ultimately propose core terms that are checked by a much smaller kernel.

PSCV should preserve this principle.

~~~text
large / smart / replaceable
    parser
    elaborator
    tactics
    AI
    optimizers
    build system
    package manager
          |
          v
small / explicit authority
    kernel checker
    checked capability
~~~

The compiler does not become trusted merely because it was written in Lean or PSCV.

---

## 4.2 Lean's type theory must be copied faithfully, not idealized

The selected Lean compatibility lane includes a rich dependent type theory with:

- dependent functions;
- predicative universes for data;
- impredicative Prop;
- definitional proof irrelevance;
- inductive types and recursors;
- quotients with computation;
- propositional extensionality;
- universe polymorphism;
- definitional eta behavior.

Current Lean documentation also explicitly states that its type theory does not have several textbook metatheoretic properties:

- subject reduction in full generality;
- necessarily transitive definitional equality;
- guaranteed type-checker termination.

These facts are not reasons to reject Lean.

They are reasons PSCV must distinguish:

~~~text
compatibility with Lean's real theory
from
a stricter profile chosen for stronger metatheory
~~~

A PSCV reference that simply demands subject reduction for all Lean-compatible terms would be specifying a different theory while claiming fidelity.

---

# 5. Semantic profile architecture

## 5.1 Compatibility profile

**TARGET**

Define a versioned semantic profile whose purpose is exact compatibility with a pinned Lean behavior set.

Conceptually:

~~~text
PscvCompatibilityProfile {
    sourceLanguageIdentity
    LeanVersion
    LeanCommit
    CoreContract
    kernelContract
    standardEnvironment
    transparencyPolicy
    quotientPolicy
    recursionPolicy
    primitivePolicy
}
~~~

Its purpose is fidelity.

It may inherit metatheoretic limitations of the pinned Lean semantics.

No stronger theorem is assumed merely because it would be convenient.

---

## 5.2 Certified profile

**TARGET**

Define a selected subset/profile for which PSCV intentionally closes a stronger theorem inventory.

Illustrative goals include:

- declarative typing;
- checker soundness;
- checker completeness for the supported fragment where feasible;
- progress/canonicity for runtime-relevant closed terms;
- type preservation for the selected operational semantics where the theory supports it;
- deterministic or explicitly nondeterministic observable semantics;
- erasure preservation;
- proof irrelevance / ghost noninterference;
- absence of unresolved runtime types;
- total or explicitly fuel-bounded checker behavior;
- closed-world standard environment.

The final profile identity must be frozen only after its actual semantics are machine specified.

Do not freeze the illustrative name in this document as a language identity.

---

## 5.3 Compatibility embedding

**PROOF TARGET**

The relationship between the stronger certified profile and the Lean-compatible profile must be explicit.

At minimum:

~~~text
CertifiedWellFormed(program)
    ->
CompatibilityAccepts(program)
~~~

and, for executable observations:

~~~text
CertifiedObservation(program)
    refines
CompatibilityObservation(program)
~~~

This creates a safe place to obtain stronger metatheory without falsifying Lean fidelity.

---

# 6. Declarative theory layer

The current PSCV compiler and kernel implementations are useful executable specifications, but a high-assurance compiler needs a declarative semantics that is not identical to implementation code.

**TARGET logical structure:**

~~~text
Theory/
  Syntax
  Universes
  Typing
  DefinitionalEquality
  Declarations
  Inductives
  Recursors
  Quotients
  Transparency
  Assumptions
  RuntimeObservations
~~~

The physical directory may be introduced incrementally.

The key requirement is conceptual separation.

---

## 6.1 Declarative typing judgment

**PROOF TARGET**

Define an implementation-independent relation analogous to:

~~~text
Gamma ; Env |- term : type
~~~

The executable checker should be related to this relation.

Target theorem:

~~~text
CheckerAccepts(env, term, type)
    ->
DeclarativeTyping(env, term, type)
~~~

Completeness should be proved for the certified fragment where feasible:

~~~text
DeclarativeTyping(env, term, type)
    ->
CheckerEventuallyAccepts(env, term, type)
or
explicitly documented completeness preconditions
~~~

Resource exhaustion must not be confused with semantic rejection.

---

## 6.2 Definitional equality specification

The declarative specification must state the exact conversion relation of the selected profile.

For the Lean compatibility lane, this must follow pinned Lean behavior rather than silently replacing it with an ideal equivalence relation.

For a stricter certified profile, PSCV may use a better-behaved declarative relation if and only if the profile difference is explicit and the embedding into the compatibility lane is justified.

---

# 7. Observable runtime semantics

The previous reference says passes should preserve semantics but does not make the observable semantic object strong enough.

Version 2 requires a first-class runtime observation contract.

**TARGET:**

~~~text
Observation =
    termination
  | divergence
  | explicit runtime error
  | capability event trace
  | exported result
  | externally visible state event
~~~

Exact forms are profile-specific.

Execution time and memory consumption normally belong to resource contracts rather than functional observable semantics, unless a capability/API explicitly exposes them.

---

## 7.1 Refinement rather than naive equality

Following verified-compiler practice, compilation correctness should normally be stated as refinement.

Conceptually:

~~~text
TargetBehaviors(compiled)
    subset/refine
SourceBehaviors(source)
~~~

For deterministic, safe PSCV fragments, this may collapse to observational equivalence.

For nondeterministic capability worlds or target runtimes, refinement is the safer general relation.

---

# 8. Current repository architecture audit

## 8.1 Bounded semantic compiler spine — CURRENT

At the reviewed compiler baseline:

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

This remains an excellent bounded self-application and formalization corpus.

It is not the full target-specific self-host closure.

---

## 8.2 Current target packages — CURRENT

At the reviewed baseline:

~~~text
backend-ts      3 Lean modules
driver-ts       1

backend-js      3 Lean modules
driver-js       1

backend-wasm   12 Lean modules
driver-wasm     1

backend-rust    6 Lean modules
driver-rust     1
~~~

The current physical decomposition is uneven.

Notable large ownership units include:

- BackendWasm/Lower.lean — approximately 262 KB and over six thousand lines;
- Syntax/ParseLean.lean — approximately 103 KB;
- Elab/Term.lean — approximately 99 KB;
- Erasure/Expr.lean — approximately 85 KB;
- CompilerIr/Specialize.lean — approximately 71 KB.

Large files are not automatically wrong.

They become architecture problems when:

- multiple semantic responsibilities are mixed;
- proof ownership becomes unclear;
- incremental recompilation is unnecessarily broad;
- AI/context retrieval must repeatedly load unrelated logic;
- review boundaries no longer correspond to pass boundaries.

---

## 8.3 Current top-level workspace shape — CURRENT

The active psc15selfhost workspace contains approximately:

~~~text
packages/      active compiler, backends, kernel implementations/providers
host/          host-only orchestration
docs/          extensive architecture and continuity material
scripts/       hundreds of checks, self-host workflows and support tools
test/          integration and semantic corpora
stdlib/        portable library surface
lean-checked/  Lean provider integration
profiles/configuration JSON files
~~~

This separation is directionally good.

The main structural risks are:

1. scripts has become a large mixed-responsibility area;
2. architecture documentation is extensive enough to risk status/authority drift;
3. archived pskernel-core.old2 / old3 packages remain in the active packages namespace;
4. compiler-ir physically combines construction IR, validation support, and specialization;
5. backend-wasm lowering is too monolithic for long-term proof and maintenance ownership.

---

# 9. Current authority gap

**CURRENT**

The pure compiler can still proceed approximately as:

~~~text
PsCompilerAdmissionReadyModule
    ->
environment reconstruction
    ->
erasure
    ->
PsErasedIrModule
    ->
psValidateErasedIrModule
    ->
PsValidatedIrModule
    ->
backend
~~~

without a KernelContract-issued checked capability.

The current pure Check aliases remain preparation aliases rather than kernel admission.

This is the highest-priority soundness architecture gap.

---

# 10. Normal checked authority path

The existing host checked-session mechanism is a strong basis and should be generalized rather than replaced.

**TARGET:**

~~~text
source
  |
  v
untrusted frontend
  |
  v
CandidateCore / PreparedCandidate
  |
  v
canonical bounded export
  |
  v
KernelContract
  |
  v
selected provider
  |
  v
CheckedCoreCapability
  |
  +--------------------+
  |                    |
  v                    v
ModuleInterface       Erase
                       |
                       v
                    RuntimeIR
~~~

The kernel implementation remains outside the small compiler bootstrap closure.

The capability is the production gate.

---

# 11. Three assurance modes

One architecture should support different operational assurance budgets without changing semantic meaning.

## 11.1 Development mode

Purpose:

- fast feedback;
- source/profile checks;
- local type/elaboration checks;
- affected query slice;
- cached interfaces;
- local tests.

It must never mint release-level evidence.

---

## 11.2 Checked production mode

Purpose:

- normal trusted builds.

Requires:

- exact semantic/profile identities;
- KernelContract checking;
- checked capability;
- mandatory IR validators;
- target validators required by the target contract;
- fail-closed unsupported semantics;
- content verification for cache reuse.

---

## 11.3 Paranoid / adversarial verification mode

Purpose:

- hostile input;
- high-value proofs;
- proof marketplaces;
- untrusted AI-generated projects;
- release authorities;
- checker-diversity campaigns.

Required architecture:

~~~text
untrusted source/build
    |
sandbox / isolated process
    |
canonical semantic export
    |
trusted bounded decoder
    |
statement + environment + assumption matching
    |
multiple checker implementations
    |
evidence manifest
~~~

No untrusted project module/object format is loaded directly into the trusted checker address space when an export format can be used instead.

This follows the strongest lesson of Lean's modern comparator pipeline.

---

# 12. Trust model and TCB manifest

The previous reference says the TCB should remain small.

Version 2 requires the TCB to be machine inventoryable.

**TARGET artifact:**

~~~text
TrustManifest {
    schemaVersion

    logicalTCB
    acceptanceTCB
    executionTCB
    securityTCB
    supplyChainTCB
    benchmarkTCB

    checkerImplementations
    commonModeLineage
    explicitAxioms
    trustedCapabilities
    trustedDecoders
    trustedRuntimeAssumptions
}
~~~

---

## 12.1 Logical TCB

Includes only components whose unsoundness can admit a false theorem or invalid semantic claim.

Examples may include:

- selected core theory;
- checker/kernel;
- explicit logical axioms;
- verified checker theorem assumptions.

---

## 12.2 Acceptance TCB

Components that bind an untrusted proposal to logical acceptance:

- canonical bounded decoder;
- KernelContract host adapter;
- process-local capability store;
- provider-identity validation.

---

## 12.3 Execution TCB

Components required to claim a compiled artifact implements source semantics:

- target runtime semantics;
- proved lowering passes;
- accepted translation validators;
- Wasm validation/runtime assumptions;
- JS restricted-subset execution assumptions;
- foreign capability implementations.

---

## 12.4 Security TCB

Components required against a malicious producer:

- process isolation;
- sandbox policy;
- resource limits;
- byte-level decoder safety;
- filesystem/network capability policy.

A security failure need not imply a logical-rule failure, but it can invalidate the checking ceremony.

---

## 12.5 Supply-chain TCB

Includes:

- artifact digest algorithm;
- signature/transparency mechanisms where used;
- toolchain pinning;
- release identity verification.

Supply-chain evidence does not itself prove semantics.

---

# 13. Independent checker policy

Independence is not binary.

Two providers compiled from the same source and runtime have less bug independence than separately implemented kernels.

**TARGET:**

Every checker/provider identity records a lineage such as:

~~~text
implementation language
source lineage
runtime lineage
compiler lineage
algorithm lineage
formal proof lineage
platform/runtime lineage
~~~

An IndependenceEvidence object can then state what failure modes are genuinely diverse.

---

## 13.1 Current examples

Lean native and Lean Wasm are valuable independent deployment paths but share major semantic/source lineage.

PSKernel Core is more implementation-diverse.

Future independently implemented checkers, including a Rust or another formally refined checker, can provide stronger common-mode-failure resistance.

---

## 13.2 High-assurance replay

A release/high-value proof may require a policy such as:

~~~text
default kernel acceptance
+
owned PSKernel replay
+
one implementation-diverse external checker
+
canonical assumption audit
~~~

The exact policy is versioned.

No fixed number of checkers is inherently sound; diversity and assumptions matter.

---

# 14. Resource outcome model

Compilers and checkers can fail because resources are finite.

That is not a semantic counterexample.

**TARGET orchestration outcome:**

~~~text
Accepted(value)

Rejected(semanticReason)

Inconclusive(
    resourceExhausted
  | unsupportedFeature
  | checkerUnavailable
)

InfrastructureFailure(reason)
~~~

KernelContract-v1 remains frozen unless its wire semantics are intentionally versioned.

This richer outcome may live in the compiler-service/build orchestration layer.

Rule:

> Only Accepted grants authority.

No Inconclusive result may fall back into acceptance.

---

# 15. Resource contracts

Every expensive authority-bearing pass should declare budgets.

Conceptually:

~~~text
ResourceContract {
    maxInputBytes
    maxDeclarations
    maxDepth
    maxFuel
    maxWallTime
    maxMemory
    maxGeneratedNodes
    maxOutputBytes
}
~~~

Not every field applies to every pass.

Budgets belong in BuildAction identity whenever they can affect success/failure or emitted output.

---

## 15.1 Three budget tiers

### Edit-time

Small affected slice, cached interfaces, low latency.

### Checkpoint

Affected proof/build closure, pass validators, module interfaces.

### Release/paranoid

Clean replay, multiple checkers, full evidence closure, fixed-point/reproducibility where required.

This avoids making maximal assurance the latency of every keystroke.

---

# 16. Compiler phase semantics

Every certified compiler phase must answer five questions.

1. What artifact type does it accept?
2. What artifact type does it produce?
3. What invariant is required?
4. What invariant is established?
5. What semantic relation connects input and output?

A sixth question is mandatory for production engineering:

6. What resource contract and failure outcomes apply?

---

# 17. PassDefinition and BuildAction

The previous reference correctly avoided a disconnected CompilerPassContract universe.

Keep that decision.

**TARGET:**

~~~text
PassDefinition {
    passId

    inputArtifactKind
    outputArtifactKind

    requiredInvariantIds
    establishedInvariantIds

    semanticRelationId

    proofOrValidatorPolicyId
    resourceContractId
    determinismPolicy
}
~~~

A concrete invocation remains an existing-style BuildAction.

~~~text
BuildAction {
    PassDefinition identity

    compilerIdentity
    semanticProfile
    contractVersions

    inputArtifactIds
    dependencyInterfaceIds

    options
    targetProfile
    runtimeAbi
    toolchainIdentity
    capabilityWorld
    declaredEnvironment
    resourcePolicy
}
~~~

---

# 18. Artifact identity: semantic fingerprint versus build identity

Do not overload one hash with two meanings.

## 18.1 ArtifactId

Cryptographically strong, domain-separated identity of canonical bytes.

Example conceptual domain:

~~~text
H(
  "proofscript-artifact" ||
  artifactKind ||
  schemaVersion ||
  canonicalBytes
)
~~~

Remote or adversarial cache reuse must use a cryptographically strong content identity.

---

## 18.2 SemanticFingerprint

Identity of the downstream-observable semantics of an artifact.

Examples:

- ModuleInterface semantic identity;
- public theorem/specification closure;
- target-neutral RuntimeIR observation identity where canonical;
- pass contract semantic identity.

Two different byte artifacts may intentionally have the same SemanticFingerprint if the architecture proves that downstream consumers cannot observe their difference.

---

## 18.3 ActionId

Identity of the complete declared build action.

It includes all meaning-relevant inputs.

Do not use ambient host state as an undeclared semantic input in hermetic/release mode.

---

# 19. QueryGraph: stage-specific red/green model

Current QueryGraph already demonstrates the correct core property:

~~~text
input changed
    ->
recompute node

result semantic fingerprint unchanged
    ->
stop downstream invalidation
~~~

This resembles the red/green and backdating model used by modern incremental systems.

Version 2 retains that design.

---

## 19.1 Do not use a mega-record

Rejected:

~~~text
ModuleRecord {
    source
    parsed
    elaborated
    checked
    erased
    verified
    specialized
    all target outputs
    all proof outputs
    ...
}
~~~

Preferred:

~~~text
SourceQuery
ParseQuery
ResolveQuery
ElaborateQuery
KernelCheckQuery
ModuleInterfaceQuery
EraseQuery
ValidateRuntimeIrQuery
SpecializeQuery
TargetLowerQuery
ProofQuery
KnowledgeQuery
~~~

Each query is a typed BuildAction node.

---

## 19.2 Query reuse theorem target

**PROOF TARGET**

For each reuse class:

~~~text
GreenReuse(node, previousResult)
    ->
EquivalentForDeclaredConsumers(
        previousResult,
        authoritativeRecompute(node)
    )
~~~

A general proof may be decomposed by artifact kind.

Cache corruption or missing evidence causes recomputation, not semantic fallback.

---

# 20. ModuleInterface-v1

The current canonical-admission interface key is conservative and useful.

The target interface must make observability explicit.

**TARGET fields include:**

- module identity;
- exported declaration signatures;
- transparency classification;
- required transparent bodies;
- opaque public specifications;
- public theorem identities;
- assumption closure;
- instance/ordering metadata;
- effect/capability requirements;
- dependency interface IDs;
- semantic profile identity;
- relevant contract versions.

---

## 20.1 Transparent versus opaque dependencies

If a downstream proof relies on definitional reduction through a body, that body is semantic interface.

If a declaration is opaque to clients, an implementation change preserving its public specification should not invalidate clients solely because bytes changed.

This distinction is essential for scalable proof maintenance.

---

## 20.2 ModuleInterface theorem targets

**PROOF TARGET**

~~~text
SameModuleInterface(A, B)
    ->
same downstream resolution/type-check observations
for clients within the declared interface discipline
~~~

and:

~~~text
InterfaceChange
    ->
all semantically dependent nodes are red
~~~

The theorem must account for dependent types, transparency, instances, and assumption closure.

---

# 21. RuntimeIR and VerifiedIR

## 21.1 Current implementation

The current raw PsVerifiedIr node family still contains construction states such as unknown and typeParameter.

The repository already has:

~~~text
PsErasedIrModule
PsValidatedIrModule
psValidateErasedIrModule
~~~

This is a strong migration base.

---

## 21.2 Target meaning

~~~text
RuntimeIR
    construction/runtime-oriented target-neutral IR
    may contain explicitly permitted pre-validation forms

VerifiedIR
    target-neutral executable IR
    validated against a frozen invariant contract
~~~

A physical AST rename is not required before the authority boundary is correct.

---

## 21.3 VerifiedIrWellFormed

**PROOF TARGET**

The validator should eventually satisfy:

~~~text
validateRuntimeIr(runtime) = Accepted(verified)
    ->
VerifiedIrWellFormed(verified)
~~~

Decompose the theorem into individually reusable facts if that is easier:

- type resolution;
- reference closure;
- constructor/field validity;
- call/intrinsic arity;
- literal representation bounds;
- match structural validity;
- external import validity;
- runtime representation support.

---

# 22. Erasure

MetaRocq demonstrates that verified erasure can be treated as a first-class theorem boundary.

PSCV should do the same.

**TARGET theorem family:**

~~~text
CheckedCore
    ->
RuntimeIR
~~~

Required claims include:

- proofs/ghost values cannot influence permitted runtime observations;
- runtime binders/references are preserved;
- structure/constructor representation mapping is correct;
- generated names are deterministic or alpha-equivalent by a stated relation;
- runtime type representations satisfy the RuntimeIR contract.

---

## 22.1 Erasure should not trust AdmissionReady

Production erasure requires CheckedCoreCapability.

Unchecked erasure remains an explicitly named bootstrap/testing operation only.

---

# 23. Specialization

The repository already has one shared target-neutral specialization algorithm.

That is the right algorithmic ownership.

The missing element is the phase authority.

**TARGET:**

~~~text
PsValidatedIrModule
    ->
Specialize/1
    ->
PsSpecializedIrModule
~~~

---

## 23.1 Specialization invariants

At minimum:

- reachable executable type variables are resolved according to the pass contract;
- specialization requests are closed or rejected;
- generated names are deterministic;
- references stay closed;
- type argument arities are correct;
- specialization does not introduce target representation policy.

---

## 23.2 Preservation theorem

**PROOF TARGET**

~~~text
SpecializationPreservesObservation(
    verified,
    specialized
)
~~~

This is a high-leverage SAVEF object because every backend consuming SpecializedIR can reuse it.

---

# 24. Target backends

## 24.1 General rule

A target backend declares:

- accepted input phase;
- target IR contract;
- representation/ABI profile;
- semantic refinement relation;
- required target validator;
- preservation evidence policy;
- resource contract.

Not every backend must consume the same phase if its semantics legitimately differ.

---

## 24.2 Direct WebAssembly

Preferred strongest portable executable assurance lane.

Target:

~~~text
SpecializedIR
    ->
WasmIR
    ->
validateWasmIr
    ->
canonical encoder
    ->
Wasm binary
    ->
external/spec validator
~~~

Research/proof target:

~~~text
WasmExecution(binary)
    refines
SpecializedIRObservation(program)
~~~

The W3C validation/type system and independent Wasm validators should be leveraged rather than reimplemented unnecessarily.

---

## 24.3 Direct JavaScript

Target:

~~~text
SpecializedIR
    ->
restricted JsIR
    ->
validateJsIr
    ->
canonical ESM subset
~~~

Keep the generated subset deliberately small.

High-assurance evidence may combine:

- lowering proof/translation validation;
- JsIR validation;
- cross-engine differential execution;
- RuntimeSemantics conformance corpus.

General JavaScript semantics are too large to casually place inside the PSCV TCB.

---

## 24.4 TypeScript adapter

TypeScript remains:

- bootstrap backend;
- useful oracle;
- ecosystem adapter.

Backend-local transformations such as eta rewriting and stack/tail-loop transformations require named pass ownership.

Do not hide semantic rewrites inside printing functions if they become assurance-bearing.

---

## 24.5 Rust adapter/native lane

Rust-specific concerns stay target-specific:

- Rc / Box;
- ownership;
- borrowing;
- lifetimes;
- native ABI;
- Cargo/rustc behavior.

The current Rust backend's fail-closed function-result shape boundary is the correct architectural style.

A future Aeneas-style refinement proof or target translation validator could add independent executable evidence without polluting VerifiedIR with Rust semantics.

---

# 25. Target semantics and translation validation

A full proof of every backend implementation is not required before useful high assurance.

Use two accepted strategies.

## Strategy A — verified pass

~~~text
general theorem:
forall input,
  pass(input) = output
  ->
  output refines input
~~~

## Strategy B — translation validation

~~~text
for this input/output pair:
ValidateTranslation(input, output)
    ->
output refines input
~~~

The validator must be smaller/easier to trust than the transformation it checks.

SAVEF records which strategy supports each accepted artifact.

---

# 26. Whole-compiler semantic theorem

**LONG-TERM PROOF TARGET**

For a certified source program S and produced target artifact T:

~~~text
Compile(S) = Accepted(T)
    ->
TargetObservations(T)
    refine
SourceObservations(S)
~~~

This theorem is composed from:

- source/profile conformance;
- kernel checking;
- erasure preservation;
- RuntimeIR validator soundness;
- specialization preservation where used;
- target lowering preservation/translation validation;
- target encoder/validator correctness;
- runtime/ABI assumptions.

This is stronger than merely proving each unit test.

---

# 27. Frontend correctness

The frontend is not initially part of logical authority because the kernel rechecks the proposed core object.

However, frontend correctness matters for:

- user intent fidelity;
- compiler correctness;
- useful diagnostics;
- source-level proof transport.

Recommended progression:

1. canonical lexer/parser invariants;
2. parser progress/bounds;
3. parse/print or translation canonicality;
4. elaboration soundness against declarative source typing;
5. source-to-CandidateCore refinement;
6. completeness for selected syntax fragments where useful.

CakeML shows that proved parser/type-inferencer soundness and completeness is achievable; PSCV can treat this as a long-term target rather than a prerequisite for the first checked compiler.

---

# 28. Self-host/bootstrap evidence ladder

Do not collapse all bootstrap claims into fixed-point equality.

Define separate claims.

## B0 — source profile closure

Compiler source lies inside the declared implementation profile.

## B1 — source representability

Canonical ProofScript form parses/checks under the selected frontend/profile.

## B2 — compiler generation

A trusted/reference compiler produces an executable compiler.

## B3 — semantic compiler self-application

The generated compiler can compile the compiler source according to the same semantic contracts.

## B4 — semantic fixed point

Relevant semantic artifacts/interfaces stabilize across generations.

## B5 — artifact fixed point

Generated compiler artifact bytes stabilize where deterministic reproducibility is required.

## B6 — verified bootstrap

A theorem/refinement argument establishes that the bootstrapped executable implements the compiler semantics.

CakeML demonstrates why B6 is a distinct and stronger claim than B5.

---

# 29. Lean reference bootstrap lane

Lean remains the immediate practical bootstrap/reference implementation.

Correct interpretation:

~~~text
source
    first satisfies PSCV profile
then
    pinned Lean compiles/checks it
~~~

Incorrect interpretation:

~~~text
Lean accepted it
therefore
it is PSCV
~~~

The profile checker is part of the contract.

---

## 29.1 Lean toolchain migration

The repository currently pins Lean 4.34.0.

Current stable Lean has moved beyond that patch level, and recent Lean point releases demonstrate that runtime/kernel implementation bugs can matter under adversarial inputs.

Therefore a toolchain upgrade is an explicit migration event.

Required:

- new exact toolchain identity;
- compatibility matrix replay;
- provider parity replay;
- independent checker replay at release assurance;
- source/profile replay;
- migration EvidenceObject.

Do not silently reinterpret existing evidence under a new Lean binary.

---

# 30. Formal metatheory program

The formalization program should be layered so that each stage produces reusable SAVEF knowledge.

## M0 — syntax and binding

- well-scopedness;
- substitution/lifting;
- abstraction/instantiation;
- name/identifier laws.

## M1 — declarative static semantics

- typing;
- conversion;
- environments;
- declaration validity.

## M2 — executable checker relation

- checker soundness;
- completeness for selected fragment;
- explicit resource/inconclusive relation.

## M3 — runtime semantic model

- values;
- observations;
- errors;
- capabilities.

## M4 — erasure

- ghost/proof noninterference;
- erasure preservation.

## M5 — VerifiedIR

- validator implies invariants.

## M6 — specialization

- semantic preservation.

## M7 — target lowering

- Wasm first;
- JS next;
- adapters as useful.

## M8 — whole compiler

- compositional end-to-end theorem.

## M9 — verified bootstrap

- executable compiler refines compiler semantics.

This ordering maximizes theorem reuse.

---

# 31. Proof checker diversity for metatheory

Proofs about PSCV may initially be written in the pinned Lean reference environment.

For high-assurance releases, proof artifacts should be replayable through independent Lean checker implementations where possible.

Longer term, selected foundational theorems may also be formalized independently in another proof assistant such as Rocq or HOL.

This is a diversity strategy, not a requirement to duplicate every proof.

---

# 32. Interoperability architecture

## 32.1 InterfaceIR

Keep external API shape separate from executable semantics.

~~~text
VerifiedIR
    executable program semantics

InterfaceIR
    foreign/API contract shape
~~~

InterfaceIR may represent:

- primitives;
- lists/tuples;
- records;
- variants;
- option/result;
- functions;
- modules/interfaces;
- resources;
- owned/borrowed handles;
- futures/streams;
- errors;
- capability requirements;
- target/ABI identities.

---

## 32.2 WIT / Component Model

WIT describes interface/world shape and import/export requirements.

It does not define the behavioral semantics of an interface.

Therefore:

~~~text
InterfaceIR
    ->
WIT
~~~

is appropriate for interoperability.

Behavioral contracts remain in:

~~~text
specification / theorem / SPKF knowledge
~~~

Do not treat WIT as a proof specification language.

---

## 32.3 Capability worlds

Foreign/host authority is explicit.

Examples:

~~~text
FileSystem
Network
Clock
Random
Process
Environment
Console
SecretStore
~~~

A target cannot obtain a capability merely because the host has one.

This aligns well with Component Model worlds while remaining independent of WIT as the PSCV semantic authority.

---

# 33. File and folder architecture

The repository should migrate toward semantic ownership that mirrors proof/pass boundaries.

Large path moves are not an early prerequisite.

## 33.1 Current strengths

Keep:

- small bounded compiler packages;
- host separated from portable semantics;
- target backends separated;
- pskernel-core's hierarchical semantic organization;
- bootstrap composition roots;
- implementation-profile enforcement.

---

## 33.2 Current structural debt

Address gradually:

1. compiler-ir has too many phase responsibilities for two files;
2. BackendWasm/Lower.lean is a large semantic monolith;
3. scripts is a large mixed-purpose namespace;
4. architecture documents need an explicit machine-readable status/index;
5. old kernel checkpoints pollute active navigation and AI retrieval;
6. generated/provider source copies need explicit provenance/index exclusion rules;
7. lakefile registration is sufficiently large that generated consistency checks are preferable to manual trust.

---

# 34. Recommended logical source tree

This is a logical target. Physical migration should occur only when it improves ownership without breaking bootstrap stability.

~~~text
psc15selfhost/

  contracts/
    registry/
    source-language/
    kernel/
    runtime/
    artifact/
    evidence/
    abi/

  profiles/
    semantic/
    implementation/
    assurance/

  packages/

    foundation/
    syntax/
    core/
    environment/
    meta/
    elab/
    bridge/

    compiler/
      src/Ps/Compiler/
        Frontend/
        Prepare/
        Candidate/
        Service/

    compiler-ir/
      src/Ps/CompilerIr/
        Runtime/
          Model.lean
          Validate.lean

        Verified/
          Model.lean
          Invariants.lean

        Specialized/
          Model.lean
          Validate.lean

        Pass/
          Specialize/
            Request.lean
            Type.lean
            Expr.lean
            Module.lean

    erasure/
      src/Ps/Erasure/
        Types/
        Expr/
        Structure/
        Inductive/
        Module/

    module-interface/
      src/Ps/ModuleInterface/
        Model.lean
        Extract.lean
        Compare.lean
        Assumptions.lean

    project/
      src/Ps/Project/
        ModuleGraph.lean
        QueryGraph/
        BuildAction/

    evidence-core/
      src/Ps/Evidence/
        Model.lean
        Assurance.lean
        Verify.lean

    savef-format/
      src/Ps/Savef/
        Model.lean
        Canonical.lean
        Validate.lean

    backend-ts/
    backend-js/
    backend-wasm/
    backend-rust/

    driver-ts/
    driver-js/
    driver-wasm/
    driver-rust/

    bootstrap/

    pskernel-core/

  host/
    checked-session/
    provider/
    sandbox/
    project/
    cache/
    compiler-service/

  tools/
    check/
    bootstrap/
    selfhost/
    backend/
    benchmark/
    evidence/
    migration/
    release/

  test/
    semantic/
    differential/
    adversarial/
    query/
    backend/
    bootstrap/
    fixed-point/

  evidence/
    generated-manifests/

  docs/
    architecture/
    theory/
    research/

  archive/
    optional historical checkpoints
~~~

The actual migration should preserve Git history and need not move old2/old3 immediately.

Before any move, exclude historical/generated duplicates from default SAVEF indexing and AI semantic retrieval.

---

# 35. File-splitting rule

Do not split files merely because they are large.

Split when a boundary creates one of:

- a separate compiler pass;
- a separate invariant;
- a separate proof owner;
- a separate incremental query;
- a separate target representation;
- a separate resource budget;
- a reusable semantic knowledge unit.

This avoids architecture-by-file-count.

---

# 36. Recommended first physical splits

After authority and pass contracts are stable:

1. split CompilerIr/Specialize by type/expression/request/module responsibilities;
2. split BackendWasm/Lower by semantic lowering domains;
3. move RuntimeIR validation into an explicit owner;
4. introduce ModuleInterface package when its contract is implemented;
5. reorganize scripts into tool-purpose groups without changing semantics.

Parser/elaborator large-file cleanup should follow proof/invariant boundaries rather than happen first.

---

# 37. SAVEF knowledge model

SAVEF must distinguish authority-bearing machine-checkable knowledge from advisory retrieval material.

## 37.1 Knowledge kinds

Recommended initial kinds:

~~~text
Specification
Theorem
Invariant
ModuleInterface
PassDefinition
PassPreservation
TranslationCertificate
AssumptionClosure
Counterexample
FailureKnowledge
ProofRecipe
BenchmarkObservation
MigrationEvidence
CompatibilityEvidence
ResourceEvidence
~~~

ProofRecipe and FailureKnowledge may be advisory.

Theorem and accepted TranslationCertificate are authority-bearing only through their checker policy.

---

# 38. SPKF object

A minimal but future-proof object:

~~~text
SPKFObject {
    schemaVersion
    knowledgeId
    kind

    semanticProfileIds
    contractIds
    subjectArtifactIds
    dependencyKnowledgeIds

    claimSchemaId
    claim

    assumptionIds

    assuranceVector
    checkerPolicyId

    producerIdentity
    originatingBuildActionId

    validityRange
    supersedes
    refines

    retrievalFeatures
}
~~~

Canonical serialization determines KnowledgeId.

---

# 39. AssuranceVector

Do not compress all evidence into one scalar confidence.

Use dimensions such as:

~~~text
logical
translation
targetValidation
independence
replay
provenance
reproducibility
resource
review
~~~

Examples:

- a unit test may be strong target evidence but no formal logical proof;
- a Lean theorem may be strong logical evidence but share checker/runtime lineage;
- a differential test may add independence without constituting proof;
- a signature may add provenance without semantic correctness.

SAVEF retrieval may rank by a policy over the vector.

The underlying evidence remains explicit.

---

# 40. Negative knowledge

SAVEF should retain machine-identified failures and counterexamples.

Examples:

- rejected compiler rewrite pattern;
- known unsupported Wasm call-target form;
- proof strategy that diverges under a given profile;
- invalid assumption generalization;
- performance regression witness;
- target-specific semantic mismatch.

A later agent should be able to retrieve:

~~~text
do not repeat this approach under these conditions
because this accepted counterexample/failure evidence exists
~~~

This is a major source of compounding efficiency.

---

# 41. Knowledge validity and migration

Knowledge is scoped.

Every object declares relevant:

- semantic profile;
- language edition;
- kernel contract;
- runtime semantics;
- pass contract;
- target ABI;
- toolchain assumptions;
- theorem assumptions.

When a contract changes:

~~~text
old knowledge
    remains historical
but
    is not silently treated as valid
~~~

Reuse across versions requires:

- compatibility rule;
- refinement theorem;
- migration evidence;
- or rechecking.

---

# 42. Knowledge poisoning defenses

SAVEF retrieval is an untrusted proposal channel.

Defenses:

1. authority-bearing objects require configured checker/evidence policy;
2. content identity is recomputed;
3. dependencies are closed and validated;
4. assumptions are surfaced;
5. semantic profile mismatch rejects automatic reuse;
6. superseded knowledge is not preferred without policy;
7. benchmark holdouts are excluded;
8. generated AI text alone cannot mint authority;
9. negative/adversarial examples remain searchable;
10. retrieval result is always revalidated in the new task context.

---

# 43. Actual reuse ledger

To claim SAVEF compounding, record actual consumption.

~~~text
ReuseEdge {
    taskId
    consumedKnowledgeId
    consumptionKind
    acceptedResultId
    counterfactualArm
}
~~~

A knowledge object merely appearing in search results does not count as reuse.

It must materially contribute to an accepted result under the measurement policy.

---

# 44. FactoryBench-v3

The benchmark must measure causality rather than repository growth.

## 44.1 Freeze before exposure

Freeze:

- task set or task generator;
- holdout boundaries;
- repository snapshot;
- model/tool policy;
- acceptance gates;
- resource limits;
- metric schema;
- knowledge snapshot;
- contamination rules.

---

## 44.2 Arms

~~~text
B0
raw repository context
no SAVEF retrieval

B1
same setup
+
accepted semantic retrieval

B2
B1
+
structured proof recipes / negative failure knowledge
~~~

---

## 44.3 Stronger experiment design

Where budget permits:

- paired tasks;
- repeated trials;
- randomized task ordering;
- frozen prompts/tool permissions;
- multiple task dependency depths;
- confidence intervals rather than only medians;
- cost normalization;
- contamination audit;
- human-intervention logging;
- independent acceptance replay.

Do not tune retrieval against the held-out answers.

---

## 44.4 Success claim

Initial strong threshold:

1. assurance non-regression;
2. at least 30% of accepted assisted tasks consume prior accepted knowledge;
3. at least one substantial productivity improvement:
   - about 20% lower median tokens;
   - about 20% lower wall time;
   - about 20% lower human intervention;
   - or at least 10 percentage points higher accepted solve rate;
4. no material degradation in another primary metric;
5. at least one SAVEF-assisted compiler change creates knowledge reused by a later accepted compiler change.

Publish negative outcomes.

---

# 45. Relationship to earlier ideas

SAVEF should not claim that its ingredients are individually unprecedented.

## 45.1 Proof-Carrying Code

Shared idea:

~~~text
producer supplies code + checkable evidence
consumer checks instead of trusting producer
~~~

SAVEF generalizes this into reusable development knowledge rather than only execution safety.

---

## 45.2 Foundational PCC

Shared idea:

> move high-level proof rules out of the TCB and reduce trust toward foundational checking.

PSCV should follow this when designing validators and evidence policies.

---

## 45.3 Translation validation

Shared idea:

~~~text
do not need to trust every compiler transform
if each concrete output can be checked against its input
~~~

This is especially useful for complex target optimizations.

---

## 45.4 MetaRocq

Shared idea:

- declarative calculus;
- machine-checked metatheory;
- verified checker;
- verified erasure.

This is the strongest model for PSCV's metatheoretic architecture.

---

## 45.5 CompCert

Shared idea:

- multiple explicit IRs;
- per-pass correctness;
- whole-compiler semantic preservation by composition.

This is the strongest model for pass-level PSCV evidence.

---

## 45.6 CakeML

Shared idea:

- formally defined language semantics;
- proved frontend properties;
- verified backend;
- bootstrapped compiler whose executable is proved to implement compiler semantics.

This is the target model for the strongest eventual PSCV bootstrap claim.

---

## 45.7 Salsa and incremental build systems

Shared idea:

- tracked pure queries;
- dependency graph;
- recompute on changed inputs;
- preserve downstream green state when semantic result did not change.

PSCV adds proof/semantic artifact authority and explicit fail-closed behavior.

---

## 45.8 Retrieval-augmented theorem proving

Systems such as LeanDojo/ReProver show that retrieving relevant formal knowledge can improve proof search.

SAVEF's stronger thesis is:

~~~text
accepted software work
    ->
machine-checkable reusable semantic knowledge
    ->
retrieval
    ->
measurably cheaper accepted future work
    ->
new reusable knowledge
~~~

The causal closed loop, evidence typing, software/compiler scope, and reuse ledger are the intended distinguishing combination.

Do not claim novelty beyond what evidence supports.

---

# 46. Performance architecture

Performance is an architectural property, not an afterthought.

## 46.1 Pass metrics

Every BuildAction may record:

- wall time;
- CPU time;
- peak memory;
- input size;
- output size;
- generated node count;
- cache status;
- dependency fanout;
- validation time;
- proof replay time.

Metrics are not semantic identity unless a contract intentionally makes them so.

---

## 46.2 Regression budgets

Maintain explicit workloads for:

- tiny interactive modules;
- representative compiler modules;
- whole semantic spine;
- direct-backend compiler closure;
- project graph;
- release replay.

Do not silently raise ceilings to pass CI.

A budget change is a reviewed contract/policy decision.

---

## 46.3 Incremental self-host

The current direct-JS whole-compiler evidence shows that repeated full frontend work is expensive.

Target optimization:

~~~text
self-host generation
    uses stage-specific QueryGraph
    +
ModuleInterface
    +
content-addressed pass artifacts
~~~

A generation should not reparse/reelaborate/revalidate semantically unchanged modules merely because the self-host driver currently performs a whole-source loop.

Fixed-point testing remains authoritative through a clean cold path at release checkpoints.

---

# 47. Resource-behavior verification

Performance and resource behavior are related but not identical.

Required tests include:

- depth bombs;
- huge declaration counts;
- huge strings/identifiers;
- adversarial recursive terms;
- specialization explosion;
- target code-size explosion;
- decoder framing attacks;
- cache amplification;
- proof replay blow-up.

Resource failures must be deterministic enough to diagnose and must never become acceptance.

---

# 48. Compatibility completeness model

Compatibility is multidimensional.

Maintain a machine-readable matrix over:

~~~text
SourceLanguage
StandardProfile
Core
KernelContract
CheckedCore schema/capability
RuntimeIR
VerifiedIR
SpecializedIR
RuntimeSemantics
ModuleInterface
PassDefinitions
TargetRuntimeABI
InterfaceIR
CapabilityContract
PackageManifest
Evidence/SPKF
SAVEF retrieval schema
Toolchain identity
~~~

Each row states:

- current version;
- compatibility rule;
- migration mechanism;
- conformance evidence;
- replay policy;
- deprecation window.

---

# 49. Semantic migrations

Changing a contract does not overwrite history.

Use explicit migration objects:

~~~text
MigrationEvidence {
    fromContract
    toContract
    relation

    compatible
  | refines
  | requiresRecheck
  | incompatible

    checkerEvidence
}
~~~

Old evidence remains inspectable.

This is central to long-term auditability.

---

# 50. Reproducibility and provenance

Keep four concepts distinct.

~~~text
semantic correctness
artifact reproducibility
supply-chain provenance
self-host fixed point
~~~

None implies all the others.

A release may legitimately have:

- semantically verified output but nondeterministic debug metadata;
- reproducible bytes without semantic proof;
- signed provenance for a buggy compiler;
- self-host byte equality for an incorrect compiler.

Evidence manifests state each claim separately.

---

# 51. Audit event model

Authority-bearing operations should be reconstructable.

Recommended append-only event classes:

~~~text
SourceAccepted
CandidateProduced
KernelChecked
ArtifactValidated
PassExecuted
EvidenceAccepted
KnowledgePublished
KnowledgeConsumed
MigrationApplied
ReleaseVerified
~~~

Events refer to content identities rather than trusting mutable paths.

An event log improves auditability but does not itself grant semantic authority.

---

# 52. Architecture/status registry

The repository has enough architecture documentation that status drift is a real risk.

Add a generated or checked registry such as:

~~~text
architecture-registry.json
~~~

with entries:

~~~text
document
contract
status
authorityLevel
machineIdentity
supersedes
implementationOwner
lastEvidenceRevision
~~~

The registry prevents old plans from appearing normative merely because they are easier for an agent to find.

---

# 53. Historical/generated source indexing policy

Default SAVEF and AI semantic search should exclude or demote:

- pskernel-core.old2;
- pskernel-core.old3;
- generated dist source;
- provider copies of canonical source;
- stale study snapshots;

unless the task explicitly asks for historical comparison.

This reduces common AI-context contamination.

Nothing must be deleted to obtain this benefit.

---

# 54. Recommended migration sequence

## P0 — freeze benchmark and identities

- FactoryBench-v3 policy;
- holdout;
- measurement schema;
- architecture registry skeleton;
- exact baseline identities.

## P1 — authority closure

- backend-neutral checked capability;
- production erasure requires it;
- unchecked APIs explicitly named/internal.

## P2 — semantic specification skeleton

- declarative Core judgments;
- runtime observation vocabulary;
- theorem IDs;
- assumption vocabulary.

## P3 — TrustManifest

- machine-readable TCB classes;
- provider lineage;
- checker policy.

## P4 — pass/artifact unification

- PassDefinition extends BuildAction;
- SemanticFingerprint separate from ArtifactId.

## P5 — SpecializedIR capability

- explicit wrapper;
- shared specialization path;
- JS/Wasm certified routes consume it.

## P6 — VerifiedIR formal invariants

- validator soundness theorem family.

## P7 — stage-specific QueryGraph

- BuildAction nodes;
- semantic backdating;
- CAS.

## P8 — ModuleInterface-v1

- transparency;
- assumptions;
- dependency semantic IDs.

## P9 — comparator-style paranoid lane

- sandbox/export;
- bounded decoder;
- checker replay;
- assumptions audit.

## P10 — first metatheory seed

- substitution;
- abstraction;
- environments;
- checker soundness slices.

## P11 — erasure preservation

- ghost noninterference;
- runtime correspondence.

## P12 — specialization preservation

- reusable pass theorem.

## P13 — minimal SPKF + reuse ledger

- accepted theorem/pass/interface knowledge;
- negative knowledge.

## P14 — FactoryBench B1/B2

- measure before expanding the knowledge graph further.

## P15 — Wasm preservation / translation validation

- target semantics and external validation.

## P16 — frontend formalization

- syntax and elaboration refinement.

## P17 — verified bootstrap campaign

- semantic executable refinement;
- independent replay;
- reproducibility as separate claim.

---

# 55. What should not be implemented first

Do not begin by:

- rewriting parser syntax;
- putting the kernel inside the bootstrap closure;
- creating another artifact-ID system for SAVEF;
- creating another QueryGraph beside the existing one;
- building a central SAVEF registry;
- formalizing all four backends simultaneously;
- moving hundreds of files before pass ownership stabilizes;
- deleting historical kernel packages;
- promoting pskernel-core automatically;
- treating fixed-point equality as correctness;
- treating Lean compilation as proof of PSCV profile membership;
- adding one-off repair guards for individual self-host failures.

---

# 56. Architecture evaluation loop

The requested evaluation uses these 16 criteria:

1. Soundness/fidelity
2. TCB transparency
3. Formal/metatheoretic verification
4. Adversarial robustness
5. Compatibility completeness
6. Architecture
7. Independent evidence
8. Performance
9. Resource behavior
10. Portability
11. Longevity
12. Interoperability
13. Self-host/bootstrap
14. Auditability
15. Novelty
16. SAVEF

The scores below evaluate **architecture design**, not current implementation completeness.

The previous reference's older 9.63 score used a different 25-criterion rubric and is not directly comparable.

---

# 57. Iteration 0 — current PSCV_COMPILER_REFERENCE.md

| Criterion | Score | Main limitation |
| --- | ---: | --- |
| Soundness/fidelity | 8.6 | strong authority chain, weak explicit source/runtime semantic relation |
| TCB transparency | 8.4 | TCB described but not machine-classified |
| Formal/metatheoretic verification | 6.4 | no separate declarative theory/checker-refinement program |
| Adversarial robustness | 7.8 | process-local handle but no comparator-style sandbox/export lane |
| Compatibility completeness | 8.3 | good versioning direction, incomplete multidimensional compatibility matrix |
| Architecture | 9.2 | strong overall phase design |
| Independent evidence | 8.2 | providers/differentials exist but independence lineage is implicit |
| Performance | 7.8 | performance recognized but not pass-contract driven |
| Resource behavior | 7.3 | resource outcomes/budgets not first-class |
| Portability | 9.1 | strong target/profile separation |
| Longevity | 8.6 | migration policy good, evidence migration not explicit enough |
| Interoperability | 8.2 | InterfaceIR/WIT direction good but behavioral contract split incomplete |
| Self-host/bootstrap | 9.4 | excellent separation of fixed-point claims |
| Auditability | 8.5 | evidence/status categories good, no canonical audit/TCB registries |
| Novelty | 8.8 | strong combination, relation to PCC/TV/RAG/build research underexplained |
| SAVEF | 8.7 | useful SPKF/FactoryBench concept, insufficient typed knowledge lifecycle |
| **Average** | **8.33** | **below target** |

Result:

~~~text
minimum = 6.4
average = 8.33
continue iteration
~~~

---

# 58. Iteration 1 — semantic-preservation architecture

Changes:

- declarative theory layer;
- compatibility/certified profile split;
- observable semantics;
- checker-soundness/completeness targets;
- erasure theorem;
- per-pass refinement;
- whole-compiler semantic preservation;
- typed SAVEF claims;
- explicit independent evidence.

Scores:

| Criterion | Score |
| --- | ---: |
| Soundness/fidelity | 9.3 |
| TCB transparency | 9.1 |
| Formal/metatheoretic verification | 8.8 |
| Adversarial robustness | 9.0 |
| Compatibility completeness | 9.0 |
| Architecture | 9.5 |
| Independent evidence | 9.2 |
| Performance | 8.9 |
| Resource behavior | 8.7 |
| Portability | 9.4 |
| Longevity | 9.3 |
| Interoperability | 9.0 |
| Self-host/bootstrap | 9.6 |
| Auditability | 9.3 |
| Novelty | 9.2 |
| SAVEF | 9.4 |
| **Average** | **9.17** |

Result:

~~~text
average > 9
but minimum = 8.7
continue iteration
~~~

---

# 59. Iteration 2 — accepted architecture in this document

Additional changes:

- TrustManifest and TCB classes;
- comparator-style high-assurance mode;
- checker lineage/independence evidence;
- first-class resource outcomes;
- resource/pass budgets;
- SemanticFingerprint versus ArtifactId;
- incremental fixed-point strategy;
- compatibility matrix and MigrationEvidence;
- audit event model and architecture registry;
- negative SAVEF knowledge;
- Knowledge validity/supersession;
- reuse ledger;
- FactoryBench-v3 anti-contamination design;
- physical module-ownership migration;
- explicit non-novel precedent analysis.

Final scores:

| Criterion | Final target |
| --- | ---: |
| Soundness/fidelity | **9.8** |
| TCB transparency | **9.7** |
| Formal/metatheoretic verification | **9.4** |
| Adversarial robustness | **9.7** |
| Compatibility completeness | **9.5** |
| Architecture | **9.8** |
| Independent evidence | **9.7** |
| Performance | **9.2** |
| Resource behavior | **9.3** |
| Portability | **9.6** |
| Longevity | **9.7** |
| Interoperability | **9.4** |
| Self-host/bootstrap | **9.8** |
| Auditability | **9.8** |
| Novelty | **9.5** |
| SAVEF | **9.9** |
| **Average** | **9.61** |

Result:

~~~text
minimum criterion = 9.2
average = 9.61

all requested criteria >= 9
architecture iteration accepted
~~~

No criterion is scored 10 because implementation evidence, formal closure, hostile-input experience, and long-term ecosystem operation can still reveal flaws in the architecture.

---

# 60. Current implementation readiness is not 9.61

The score above is a target-architecture design score.

Current implementation does **not** yet provide:

- a complete declarative PSCV metatheory;
- checker soundness/completeness proofs;
- erasure preservation proof;
- specialization preservation proof;
- whole-compiler preservation;
- backend-neutral production checked capability;
- comparator-style PSCV sandbox/replay;
- ModuleInterface-v1;
- stage-specific full QueryGraph/CAS;
- operational SPKF;
- causal FactoryBench-v3 results.

Therefore implementation readiness remains materially lower.

Do not use the architecture score as a release-quality claim.

---

# 61. Canonical target architecture

~~~text
                 SOURCE / KNOWLEDGE PRODUCERS
          source, dependencies, plugins, tactics, AI
                         UNTRUSTED
                            |
                            v
                 PROFILE CONFORMANCE
                            |
                            v
             Parse / Resolve / Elaborate / Meta
                            |
                            v
                      CandidateCore
                            |
                    canonical export
                            |
                            v
                  +------------------+
                  | AUTHORITY DOMAIN |
                  +------------------+
                            |
                    KernelContract
                            |
                one selected provider
                            |
                            v
                 CheckedCoreCapability
                    /               \
                   /                 \
                  v                   v
        ModuleInterface-v1           Erase
                  |                    |
                  |                    v
                  |                 RuntimeIR
                  |                    |
                  |             ValidateRuntimeIr
                  |                    |
                  |                    v
                  |                 VerifiedIR
                  |                    |
                  |                Specialize
                  |                    |
                  |                    v
                  |               SpecializedIR
                  |             /       |       \
                  |            v        v        v
                  |          JsIR     WasmIR   adapters
                  |            |        |       TS/Rust
                  |            v        v
                  |            JS      Wasm
                  |                     |
                  |                Component/WIT
                  |                 interface view
                  |
                  +---------------------+
                                        |
                                        v
                          BUILD / QUERY / CAS PLANE

         PassDefinition + BuildAction + ArtifactId
                       |
              SemanticFingerprint
                       |
               stage-specific queries
                       |
             fail-closed green reuse

                                        |
                                        v
                              EVIDENCE PLANE

              theorem / validator / replay / differential
                  target validation / provenance
                  resource evidence / migration evidence
                       |
                       v
                 AssuranceVector

                                        |
                                        v
                              SAVEF KNOWLEDGE PLANE

          specs / theorems / interfaces / pass evidence
          certificates / assumptions / counterexamples
          failures / recipes / benchmark observations
                       |
                       v
                      SPKF
                       |
                  semantic index
                       |
              untrusted AI retrieval
                       |
             next compiler proposal
                       |
                authority re-check
                       |
                  accepted result
                       |
                new SAVEF knowledge
~~~

---

# 62. High-assurance replay architecture

~~~text
untrusted project / AI output
        |
        v
isolated build sandbox
        |
        v
canonical CandidateCore / proof export
        |
        v
small bounded trusted decoder
        |
        +--> expected statement/interface identity check
        |
        +--> permitted assumption check
        |
        +--> pinned primary kernel
        |
        +--> PSKernel Core
        |
        +--> independent checker(s) required by policy
        |
        v
EvidenceManifest
        |
        v
release / high-value acceptance
~~~

This lane is intentionally more expensive than edit-time checking.

---

# 63. Semantic preservation composition

~~~text
Source semantics
      |
      | frontend refinement
      v
Checked Core semantics
      |
      | erasure preservation
      v
RuntimeIR semantics
      |
      | validator soundness
      v
VerifiedIR semantics
      |
      | specialization preservation
      v
SpecializedIR semantics
      |
      | target lowering refinement
      v
Target IR semantics
      |
      | encoder / runtime relation
      v
Executable observations
~~~

Every arrow has:

- a PassDefinition;
- a relation;
- proof, validator, or explicitly weaker evidence;
- assumptions;
- resource policy;
- artifact/evidence identities.

---

# 64. SAVEF success condition

SAVEF is successful for the PSCV compiler only when all of the following are observable.

1. Accepted tasks produce structured machine-checkable knowledge.
2. Later accepted tasks consume earlier accepted knowledge.
3. The consumption is recorded, not inferred from search exposure.
4. Assurance does not decrease.
5. Productivity improves under a controlled benchmark.
6. Knowledge survives implementation refactors when its semantic scope remains valid.
7. Invalidated knowledge becomes unusable automatically under changed contracts.
8. Negative knowledge prevents repeated failed approaches.
9. AI can exploit the graph without receiving authority.
10. The compiler itself becomes a beneficiary and producer of the same mechanism.

---

# 65. Final recommendation

Adopt this Version 2 architecture as the next PSCV compiler target reference.

The priority order is:

~~~text
authority
    before
optimization

declarative semantics
    before
broad proof claims

explicit pass relations
    before
backend proof proliferation

typed artifact/query identities
    before
large incremental-cache expansion

benchmark freeze
    before
SAVEF knowledge growth

small reusable proofs
    before
whole-compiler formalization

paranoid independent replay
    for high-risk acceptance
not
for every edit
~~~

Most importantly:

> PSCV should not attempt to be a cleaner-looking imitation of Lean.

It should preserve Lean compatibility where compatibility is required, while improving the architecture around it through explicit profiles, smaller authority surfaces, verified or validated compiler passes, independent replay, semantic incrementalism, portable target contracts, and a knowledge system whose benefit can be measured causally.

---

# 66. Primary research references

The following sources materially informed this revision.

## Lean

- Lean Language Reference — Elaboration and Compilation  
  https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/

- Lean Language Reference — The Type System  
  https://lean-lang.org/doc/reference/latest/The-Type-System/

- Lean Language Reference — Validating a Lean Proof  
  https://lean-lang.org/doc/reference/latest/ValidatingProofs/

- Lean Language Reference — Lake / comparator / external checkers  
  https://lean-lang.org/doc/reference/latest/Build-Tools-and-Distribution/Lake/

- Lean bootstrapping design  
  https://github.com/leanprover/lean4/blob/master/doc/dev/bootstrap.md

- Lean compiler LCNF API and pass manager  
  https://lean-lang.org/doc/api/Lean/Compiler/LCNF/Basic.html  
  https://lean-lang.org/doc/api/Lean/Compiler/LCNF/PassManager.html  
  https://lean-lang.org/doc/api/Lean/Compiler/LCNF/Passes.html

- Lean 4.34.1 release notes  
  https://lean-lang.org/doc/reference/latest/releases/v4.34.1/

- The Type Theory of Lean, Mario Carneiro  
  referenced by current Lean documentation and independent checker projects.

## Rocq / MetaRocq

- Rocq Core Language  
  https://rocq-prover.org/doc/V9.2.0/refman/language/core/index.html

- MetaRocq  
  https://metarocq.github.io/  
  https://github.com/MetaRocq/metarocq

## Verified compilers

- CompCert documentation  
  https://compcert.org/doc/  
  https://compcert.org/man/manual001.html

- CakeML  
  https://cakeml.org/  
  https://github.com/CakeML/cakeml

## Program verification systems

- Why3  
  https://why3.org/doc/

- F*  
  https://fstar-lang.org/

- Low* / KaRaMeL  
  https://fstarlang.github.io/lowstar/html/

- Agda safe-mode documentation  
  https://agda.readthedocs.io/

## Proof/evidence architectures

- Proof-Carrying Code, George C. Necula, POPL 1997  
  https://doi.org/10.1145/263699.263712

- Foundational Proof-Carrying Code, Andrew W. Appel  
  https://www.cs.princeton.edu/~appel/fpcc.html

- Translation validation literature, including Pnueli-style compiler validation and later compiler-validation work.

## Incremental/build systems

- Salsa red/green incremental algorithm  
  https://github.com/salsa-rs/salsa/blob/master/book/src/reference/algorithm.md  
  https://salsa-rs.github.io/salsa/

- Build Systems à la Carte  
  https://simon.peytonjones.org/assets/pdfs/build-systems-original.pdf

## AI/retrieval

- LeanDojo / ReProver retrieval-augmented theorem proving  
  https://leandojo.org/  
  https://github.com/lean-dojo/ReProver

## WebAssembly interoperability

- WebAssembly Component Model  
  https://component-model.bytecodealliance.org/

- WIT overview  
  https://component-model.bytecodealliance.org/design/wit.html

---

# 67. Closing architecture rule

The final rule for PSCV Compiler Version 2 is:

> **Treat semantics, authority, compilation, build reuse, evidence, and knowledge as separate but composable planes. Give each plane explicit machine identities and invariants. Prove or validate the boundaries that transfer meaning between them. Keep untrusted intelligence outside the authority boundary. Reuse accepted knowledge aggressively, but never let retrieval substitute for checking.**

This is the architecture intended to make PSCV simultaneously:

- Lean-compatible where required;
- more formally structured than its current compiler;
- independently auditable;
- robust against hostile inputs;
- portable across targets;
- incrementally buildable;
- self-hostable;
- suitable for strong compiler-verification research;
- and capable of testing SAVEF's self-amplification thesis rather than merely asserting it.
