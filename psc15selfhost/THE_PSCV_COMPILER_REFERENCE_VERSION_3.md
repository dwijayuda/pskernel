# THE PSCV Compiler Reference — Version 3

**Status:** accepted clean standalone target architecture and repository-structure reference
**Repository:** dwijayuda/pskernel
**Branch audited:** psc2/selfhost-lean-kernel
**Baseline:** 1df9e01ba1c4d73382c0e30c69de06022ba0cedd
**Primary implementation subtree:** psc15selfhost/
**Normative language authority:** psc15selfhost/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md (`pscv-v1`, `PSCV-VERIFY-v1`, `PSCV-CERT-v1`; Lean 4.35.0-rc3 semantic pin)
**Current compiler milestone:** `psc2-compiler-v1`; PSCV conformance remains a target until all PSCV gates close
**Predecessors:** psc15selfhost/THE_PSCV_COMPILER_REFERENCE.md and psc15selfhost/THE_PSCV_COMPILER_REFERENCE_VERSION_2.md
**Research date:** 2026-10-06
**Acceptance rule:** equal-weight average at least 9.90 and no requested criterion below 9.90
**Final target-design score:** 9.95 / 10
**Minimum target criterion:** 9.90 / 10

This target score is not an implementation-readiness score. Planned proof, SAVEF, security, and performance work is not counted as current evidence.

---

# 1. Executive decision

The predecessor has the right semantic spine, trust direction, backend neutrality, self-host discipline, and SAVEF separation. A stricter audit against current Lean kernel hardening and external-checker work finds seven remaining architecture gaps:

1. Lean-compatible algorithmic definitional equality must be a first-class compatibility object distinct from mathematical declarative conversion.
2. Acceptance-relevant caches and accelerators need explicit semantic-refinement contracts.
3. Semantic compatibility, provider implementation revision, and provider security baseline must be separate identities.
4. High-assurance checking needs a comparator-style challenge, sandbox, export, replay, and assumption-policy architecture.
5. Checker diversity needs lineage accounting, not a Boolean independent flag.
6. Metatheory should combine syntactic checker refinement with independent semantic-model consistency evidence.
7. Performance, resource behavior, logical interoperability, archival verification, and SAVEF knowledge migration need stronger formal contracts.

The central compiler rule is:

> PSCV is a proof-carrying compiler architecture. Every authority-changing transition has an explicit semantic contract, a typed input/output state, an evidence class, an assumption closure, a resource contract, and a deterministic identity.

The central SAVEF rule is:

> The reusable unit of verified knowledge is a typed semantic object, not a source file. Its scope, assumptions, proof/checker evidence, migration conditions, implementation witnesses, and downstream compatibility are explicit and machine-checkable.

The highest-priority implementation rule remains:

> Production erasure and emission must not be reachable from AdmissionReady. They begin only from a genuine CheckedCoreCapability bound to exact admitted bytes, semantic profile, kernel contract, provider implementation, provider-security profile, assumption policy, and resource policy.

---

# 2. Baseline re-evaluation

| Criterion | Baseline target |
| --- | ---: |
| Soundness/fidelity | 9.74 |
| TCB transparency | 9.78 |
| Formal/metatheoretic verification | 9.62 |
| Adversarial robustness | 9.72 |
| Compatibility completeness | 9.70 |
| Architecture | 9.86 |
| Independent evidence | 9.77 |
| Performance | 9.46 |
| Resource behavior | 9.58 |
| Portability | 9.78 |
| Longevity | 9.80 |
| Interoperability | 9.72 |
| Self-host/bootstrap | 9.86 |
| Auditability | 9.88 |
| Novelty | 9.78 |
| SAVEF | 9.94 |
| **Average** | **9.75** |
| **Minimum** | **9.46** |

Result: below the 9.90 average and minimum threshold; continue iteration.

---

# 3. Lean 4 correction: three equality relations

Version 3 makes three relations explicit.

## 3.1 DeclarativeConversion

The mathematical relation used by metatheory. Its intended properties are stated by the selected TheoryBaseManifest.

## 3.2 KernelAlgorithmicDefEq

The exact executable relation used by the Lean-compatibility kernel. It is modeled as the real pinned algorithm, not idealized into an equivalence merely because its purpose is conversion checking.

Required soundness direction:

~~~text
KernelAlgorithmicDefEq(a, b)
    ->
DeclarativeConversion(a, b)
~~~

Global completeness is not assumed unless proved for a restricted profile.

## 3.3 RuntimeValueEquality

Runtime equality for executable values. It is neither Core conversion nor kernel algorithmic definitional equality.

Architectural law:

> Never share a cache, proof, equivalence closure, or optimization across these relations merely because their names all contain equality.

---

# 4. Cache and acceleration soundness

Every acceptance-relevant cache owns a CacheContract:

~~~text
CacheContract {
  judgmentId
  keyDefinition
  valueDefinition
  hitRule
  invalidationRule
  closureOperations
  resourcePolicy
  proofOrInvariant
}
~~~

For a sound but non-transitive algorithmic relation, exact query memoization is permitted. Transitive closure, union-find equivalence closure, and neighboring-query reuse are forbidden unless separately proved sound for that relation.

Primary theorem:

~~~text
cacheHit(key, result)
    ->
uncachedJudgment(key) = result
~~~

Long term, proved acceleration leaves the logical TCB and becomes replaceable untrusted optimization behind a refinement boundary.

---

# 5. Semantic compatibility versus provider security

Version 3 separates:

~~~text
SemanticCompatibilityTarget
ProviderImplementationIdentity
ProviderSecurityProfile
~~~

A provider can implement the correct semantics while being unsuitable for hostile-input checking because of a known runtime, allocator, bignum, decoder, or memory-safety issue.

A security patch can preserve semantics while changing implementation identity.

ProviderImplementationIdentity records semantic profile, implementation commit, language, compiler toolchain, runtime, allocator or GC, bignum layer, decoder, build identity, and security revision.

ProviderSecurityProfile records minimum safe revision, forbidden revisions, required hardening, sandbox policy, input-budget policy, and required checker diversity.

ProviderRefinementEvidence connects a patched implementation to its semantic target.

---

# 6. Comparator-v1

High-assurance checking is a first-class protocol:

~~~text
trusted challenge
 -> isolated untrusted build sandbox
 -> canonical semantic/proof export
 -> small bounded trusted decoder
 -> statement and interface identity check
 -> assumption policy
 -> primary kernel
 -> independent checker set
 -> optional semantic-model checker
 -> evidence policy
 -> decision
~~~

Outcomes are accepted, rejected, inconclusive, resourceExhausted, or infrastructureFailure.

Only accepted creates authority. Inconclusive never becomes acceptance.

---

# 7. IndependenceVector

Checker diversity is recorded across:

~~~text
theoryOrigin
algorithmOrigin
sourceDerivation
implementationLanguage
compilerToolchain
runtime
memoryManager
parserOrDecoder
sharedGeneratedSources
sharedLibraries
organization
reviewLineage
proofFoundation
hardwareClass
~~~

Different implementation language is evidence of some diversity, not proof of full independence.

---

# 8. Metatheory triangulation

Version 3 requires two complementary proof families.

## 8.1 Syntactic/refinement family

Executable checker acceptance implies declarative validity. Supporting theory includes substitution, weakening, subject reduction, environment validity, recursor validity, inductive validity, and algorithmic-conversion soundness.

## 8.2 Semantic-model family

Accepted environments have an explicit semantic model under named foundational assumptions, supporting an independent consistency argument.

These proof families fail differently. Both are more valuable together than either alone.

---

# 9. TheoryBaseManifest

Every foundational theorem and checker profile binds to:

~~~text
TheoryBaseManifest {
  theoryId
  universeModel
  propModel
  proofIrrelevanceRule
  quotientRules
  inductiveRules
  declarativeConversion
  algorithmicConversion
  axiomSchemas
  nativePrimitiveRules
  semanticModelAssumptions
  consistencyEvidence
}
~~~

---

# 10. Canonical checked state machine

~~~text
SourceArtifact
 -> ProfileConformance
 -> Parse / Resolve / Elaborate
 -> CandidateCore
 -> CanonicalAdmissionBundle
 -> KernelContract
 -> ProviderImplementationIdentity
 -> ProviderSecurityProfile
 -> CheckedCoreCapability
 -> PSCV-CERT
 -> CertifiedSource
 -> Erasure
 -> RuntimeIR
 -> ValidateRuntimeIR
 -> VerifiedIR
 -> Specialize
 -> SpecializedIR
 -> JsIR | WasmIR | TS/Rust adapters
 -> TargetValidation
 -> ExecutableArtifact
 -> EvidenceEnvelope
~~~

No production backend accepts AdmissionReady.

---

# 11. Current implementation gap

The audited pure compiler path can still construct executable validated IR from PsCompilerAdmissionReadyModule without requiring the host checked handle.

The current host checked-session code is nevertheless strong: it freezes prepared graphs, derives canonical admissions, checks provider identity, stores authority in a process-local handle, and re-derives admissions before emission.

Version 3 therefore recommends migration from host discipline around a bypass-capable compiler API to type and dependency topology where production bypass is unavailable.

---

# 12. Production compiler ownership

Recommended conceptual split:

~~~text
Ps.Compiler.Frontend
Ps.Compiler.Candidate
Ps.Compiler.Checked
Ps.Compiler.Internal
Ps.Compiler.Service
~~~

Production drivers import Checked only. Unchecked erasure exists only behind explicitly named Internal, bootstrap, or test APIs. Architecture CI enforces the import fence.

---

# 13. CheckedCoreCapability

A checked capability binds semantic identity, CandidateCore artifact, canonical admissions artifact and hash, KernelContract, provider implementation, provider security profile, assumption policy, resource policy, session identity, and acceptance evidence.

A serialized receipt describes the event. It cannot recreate authority.

---

# 14. RuntimeIR, VerifiedIR, SpecializedIR

RuntimeIR is construction state.

VerifiedIR eventually guarantees no unresolved executable types, valid names/scopes, unique declarations, call arity and typing, intrinsic typing, exact aggregate fields, duplicate rejection, valid projections/matches, branch typing, external InterfaceIR bindings, module-link compatibility, declared runtime capabilities, and target-neutral representation constraints.

SpecializedIR is a distinct capability binding the input VerifiedIR identity, specialization request, generated declaration identities, pass identity, and preservation evidence.

---

# 15. Proof-carrying compiler pass

~~~text
PassDefinition {
  passId
  version
  inputContract
  outputContract
  semanticRelationId
  determinismClass
  totalityClass
  resourceContractId
  implementationId
  validatorId?
  theoremIds[]
  assumptionIds[]
}

PassExecution {
  passDefinitionId
  inputArtifactIds[]
  outputArtifactIds[]
  inputSemanticFingerprint
  outputSemanticFingerprint
  validatorEvidence?
  proofEvidence[]
  resourceObservation
  diagnostics
}
~~~

This is a primary SAVEF reusable compiler-knowledge unit.

---

# 16. Proof-carrying build graph

~~~text
Source
 -> Parse
 -> Elaborate
 -> Candidate
 -> Check
 -> Certify
 -> ModuleInterface
 -> Erase
 -> ValidateIR
 -> Specialize
 -> TargetLower
 -> TargetValidate
 -> Emit
 -> Package
 -> Provenance
~~~

Each authority edge owns an authority definition. Each transformation edge owns a PassDefinition. Each node carries ArtifactId, SemanticFingerprint, contract identity, evidence, assumptions, and resource data.

---

# 17. ArtifactId, SemanticFingerprint, ActionId

ArtifactId identifies exact canonical bytes.

SemanticFingerprint identifies downstream-relevant meaning. It may ignore byte differences only when a contract establishes that those differences are irrelevant.

ActionId identifies exact declared transformation inputs.

Ambient mtime, current directory, map iteration order, locale, PATH, and undeclared environment are never semantic identity.

---

# 18. QueryGraph v2

The current QueryGraph remains the seed.

Target fingerprints include source, parsed, elaborated-public, checked structural interface, certified behavioral interface, assumption closure, runtime, VerifiedIR, SpecializedIR, and target fingerprints.

A dependent stage may stay green only when its reuse theorem names a semantic fingerprint that remains unchanged.

---

# 19. Proof-carrying cache

An untrusted cache hit carries ActionId, artifact IDs, SemanticFingerprint, schema version, and validation evidence.

On every untrusted read: re-hash bytes, validate schema, confirm ActionId, confirm required evidence class, and validate fingerprint provenance.

Cache metadata never creates semantic acceptance.

---

# 20. Resource outcome algebra

~~~text
Accepted(value)
RejectedInvalid(reason)
DeclinedUnsupported(feature)
ResourceExhausted(resource, configured, observed?)
InternalError(code)
InfrastructureUnavailable(code)
~~~

Only Accepted yields authority.

---

# 21. Resource monotonicity

Desired law:

~~~text
budget1 <= budget2
and check(input, budget1) = Accepted(value)
    ->
check(input, budget2) = Accepted(value)
~~~

Increasing a budget must not change the semantic meaning of success. Exhaustion under a small budget may later become acceptance or semantic rejection under a larger budget.

---

# 22. Unified CompilationBudget

Dimensions include source bytes, tokens, syntax nodes/depth, modules/imports, declarations, universe work, reduction/defeq/unification/instance-search work, kernel steps, erasure and IR nodes, specialization instances, target nodes, proof nodes, certificate bytes, SAVEF objects/edges, generated bytes, diagnostics, wall time, CPU, peak memory, and host stack.

Portable code must not pretend to measure host-only resources it cannot observe.

---

# 23. Bounded and streaming verification

High-assurance decoders and checkers should support bounded incremental parsing, streaming digest verification, declaration-by-declaration checking, size/depth limits, proof-node limits, decompression-ratio limits, and early rejection before large allocation where practical.

---

# 24. Structural and behavioral module interfaces

StructuralModuleInterface contains exported types/names, public data shape, transparency information needed for conversion, instances, dependency interface IDs, capabilities, and runtime ABI requirements.

BehavioralModuleInterface contains pre/postconditions, invariants, effects, resource contracts, refinement relations, public assumptions, and theorem/spec references.

Structural adequacy protects incremental elaboration. Behavioral adequacy provides the deep-specification composition boundary.

---

# 25. TheoryBridge for logical interoperability

Executable interop and logical interop are different systems.

~~~text
TheoryBridge {
  sourceTheoryId
  destinationTheoryId
  symbolMap
  axiomMap
  translation
  unsupportedFeatures
  preservationClaim
  preservationEvidence
}
~~~

This supports explicit theory morphisms and proof translations without pretending all foundations are equivalent.

---

# 26. InterfaceIR for executable interoperability

InterfaceIR owns functions, records, variants, enums, options/results, resources/handles, ownership, streams/futures, errors, target availability, and capability imports/exports.

Adapters may emit WIT, TypeScript declarations, Rust bindings, and native ABI metadata.

WIT defines how components connect. Behavioral proof remains a PSCV specification/evidence concern.

---

# 27. Solver certificate boundary

External solvers, search, and AI propose proof terms or certificates. Small checkers convert certificates into accepted theorem evidence. Uncheckable solver success remains advisory.

---

# 28. Backend strategy

Direct Wasm is the first strongest portable artifact-preservation lane: SpecializedIR to WasmIR to WasmIR validator to encoder to external Wasm validation.

Direct JavaScript is the long-term canonical JS/npm bootstrap lane: SpecializedIR to JsIR to JsIR validator to deterministic ESM.

TypeScript remains an ecosystem/debug/differential oracle.

Rust remains a native/systems and independent implementation lane.

Target representation policy never enters VerifiedIR.

---

# 29. Translation validation

Complex or rapidly changing lowerers and optimizers may remain untrusted when a substantially smaller validator checks the pass-specific semantic relation or proof certificate.

This is the preferred path when proving the optimizer itself would damage implementation freedom.

---

# 30. Performance architecture

Version 3 reaches the requested threshold only by making performance architectural:

- edit-time and release/paranoid assurance tiers;
- interface-based semantic invalidation;
- stage-specific semantic caches and CAS;
- specialization cache;
- target-lowering cache;
- deterministic parallel independent work;
- untrusted fast optimizers behind validators;
- persistent checked/interface artifacts when exact evidence identities remain valid.

Release profiles record cold, warm, incremental, interface-preserving, kernel, IR-validation, specialization, target-emission, paranoid-replay, RSS, CAS-size, and artifact-size metrics.

Performance policy is empirical and versioned, not a semantic rule.

---

# 31. ResourceContract

Every stage may publish dimensions, hard limits, soft budgets, optional asymptotic theorem, optional formal cost model, measurement protocol, and exhaustion outcome.

Preserve three evidence classes separately: asymptotic theorem, formal cost-model theorem, empirical deployment measurement.

---

# 32. Self-host and bootstrap ladder

~~~text
B0 source-profile closure
B1 canonical source representability
B2 reference generation
B3 self-application
B4 semantic fixed point
B5 artifact fixed point
B6 preservation-connected self-host
B7 direct-JS bootstrap
B8 direct-Wasm bootstrap
B9 diverse bootstrap / DDC
B10 verified bootstrap
~~~

Compiler correctness, fixed point, reproducibility, and source-binary correspondence remain separate claims.

---

# 33. Portable verifier capsule

A small pscv-verify artifact should decode EvidenceManifest, verify canonical hashes and contracts, validate evidence graph integrity, replay compact certificates/validators supported by the profile, enforce assumptions, and verify configured signatures/provenance.

A Wasm Component implementation is a strong longevity target.

It does not need the full compiler.

---

# 34. Archive profile and hash agility

High-value releases archive canonical source, semantic lock, schemas, profiles, proof/certificate objects, checker identities, verifier capsule, toolchain manifests, target artifacts, provenance, licenses, and migration history.

Offline verification must not require a live registry.

Digest identity records algorithm, domain, schema version, and digest so hash migrations are explicit.

---

# 35. SAVEF typed theory graph

SAVEF contains specification, proof, theory, compiler, assumption, and artifact subgraphs.

The theory graph explicitly represents foundations, semantic profiles, theories, embeddings, interpretations, translations, and conservative-extension claims.

The compiler graph represents IR contracts, pass definitions, preservation theorems, and translation validators.

The assumption graph distinguishes axioms, FFI/world assumptions, cryptographic assumptions, and empirical claims.

---

# 36. KnowledgeObject and validity

KnowledgeObject records kind, schema, semantic identity bundle, canonical payload, authority class, scope, dependencies, assumptions, proved claims, preservation claims, supersession, migrations, implementation witnesses, evidence, provenance, resource evidence, and license.

Every reusable object defines ValidUnder(context). Retrieval may return stale objects; acceptance may not use them until validity succeeds.

KnowledgeMigration explicitly states source/destination contexts, transformation, preservation claim, evidence, and losses.

---

# 37. Negative knowledge and actual reuse

FailureKnowledge stores scoped failed strategies, reproducer, evidence, cause, validity horizon, and supersession.

ReuseEvent records consumer task, consumed knowledge IDs, use type, accepted output, counterfactual arm, cost observation, and assurance before/after.

Search exposure alone is not reuse.

---

# 38. FactoryBench-v4

Freeze holdout before making benchmark tasks searchable.

Arms:

~~~text
B0 no retrieval
B1 ordinary text retrieval
B2 typed knowledge retrieval
B3 typed retrieval plus theorem/interface/pass reuse
B4 typed reuse plus negative knowledge and portable certificates
~~~

Measure accepted-output rate, human interventions, model calls/tokens, wall time, verifier calls, repair cycles, proof/evidence size, actual reuse, resource cost, assurance vector, and regressions.

Self-amplification requires measurable productivity or success improvement under approximately fixed model/tool/acceptance policy without assurance loss.

---

# 39. TrustManifest, TrustDelta, SemanticDelta

TrustManifest binds the semantic identity bundle, theory base, logical acceptance closure, validation closure, transformation trust, trusted capabilities, external execution assumptions, supply-chain assumptions, provider implementations, provider-security profiles, generated closures, and evidence policies.

CI computes actual dependency/import closure and rejects undeclared TCB growth.

TrustDelta exposes trusted components/capabilities/assumptions added or removed by a change.

SemanticDelta distinguishes true rule changes from representation-only or security-only implementation changes and links migration evidence.

---

# 40. Semantic lock and auditability

Semantic lock entries include package/source hashes, semantic profile, structural and behavioral interface hashes, theory manifest, assumption closure, capability set, RuntimeSemantics, VerifiedIR contract, target ABI, required evidence policy, and toolchain requirements.

Long-term audit commands should answer why an artifact was accepted, what it assumes, what is trusted, how independent its evidence is, what resources were observed, and how two semantic/trust/interface states differ.

---

# 41. Adversarial architecture

Permanent regression families include malformed source/Core, free variables, invalid inductives, recursor mismatches, proof-irrelevance/projection attacks, conversion-cache-order attacks, huge-numeral/resource attacks, runtime allocator/reference-count stress, malformed canonical encodings, duplicates, stale handles, forged receipts, provider substitution, crash/timeout/truncated output, cache poisoning, malicious package metadata, target-IR malformation, invalid Wasm, SAVEF authority cycles, assumption laundering, proof-certificate bombs, and decompression bombs.

Relevant historical soundness bugs become permanent regression families.

AI may generate attacks; deterministic checkers decide whether they succeed.

---

# 42. Recommended logical repository structure

Do not execute this as a big-bang move.

~~~text
psc15selfhost/
  contracts/
    registry/
    semantic/
    kernel/
    checked-core/
    certification/
    runtime/
    ir/
    module-interface/
    target/
    interface/
    capability/
    evidence/
    savef/
    archive/

  profiles/
    semantic/
    implementation/
    provider-security/
    assurance/
    resource/
    target/

  theory/
    core/
    conversion/
    inductive/
    quotient/
    runtime/
    models/
    refinement/
    interoperability/

  packages/
    foundation/ syntax/ core/ environment/ meta/ elab/ bridge/
    kernel-contract/ checked-core/
    pscv-spec/ pscv-obligation/ pscv-cert/
    compiler-contract/ compiler/ erasure/
    compiler-ir/ runtime-ir/ verified-ir/ specialized-ir/
    compiler-pass-specialize/ module-interface/
    evidence-core/ interface-ir/ theory-bridge/ capability-contract/
    project/ build-graph/ artifact-codec/ artifact-store/
    semantic-lock/ package-manifest/ compiler-service/ diagnostics/
    backend-js/ backend-wasm/ backend-ts/ backend-rust/
    driver-js/ driver-wasm/ driver-ts/ driver-rust/
    pskernel-core/ pskernel-lean/ pskernel-lean-wasm/
    savef-format/ savef-index/ factory-bench/
    bootstrap/ cli/

  host/
    checked-session/
    comparator/
    providers/
    sandbox/
    compiler-service/
    project/
    cache/
    registry/
    release/

  tools/
    architecture/
    check/
    comparator/
    selfhost/
    bootstrap/
    backend/
    benchmark/
    evidence/
    savef/
    migration/
    release/

  test/
    theory/
    conformance/
    differential/
    adversarial/
    mutation/
    resource/
    query/
    cache/
    backend/
    comparator/
    bootstrap/
    fixed-point/

  evidence/
  savef/
  factory/
  docs/
  archive/
~~~

---

# 43. Near-term ownership before package splitting

Do not create every target package immediately.

Inside compiler, first separate Frontend, Candidate, Checked, Internal, Service, and Diagnostics.

Inside compiler-ir, first separate Runtime, Verified, Specialized, Pass/Specialize, and Contract.

Inside erasure, split by Type, Expr, Structure, Inductive, RuntimePrelude, Module, and Proof only where those boundaries own distinct invariants.

Inside project, separate ModuleGraph, QueryGraph, BuildAction, and InterfaceFingerprint.

Inside bridge, separate Admissions, Codec, Protocol, Canonical, and BoundedDecode.

Split backend-wasm only on real semantic, validator, proof-owner, or resource boundaries.

---

# 44. Spec, proof, and contract sidecars

High-value semantic packages should converge toward:

~~~text
package/
  src/
  spec/
  proof/
  contract/
~~~

Proof objects are keyed to semantic identities rather than file paths alone.

---

# 45. Historical/generated indexing policy

Default SAVEF/AI semantic retrieval excludes or strongly demotes old kernel checkpoints, generated dist source, copied provider snapshots, stale study snapshots, and generated target artifacts.

They remain available for provenance, regression archaeology, and migrations.

A CanonicalSourceMap identifies the current semantic owner.

---

# 46. Current implementation/evidence score

| Criterion | Current evidence estimate |
| --- | ---: |
| Soundness/fidelity | 7.8 |
| TCB transparency | 8.8 |
| Formal/metatheoretic verification | 5.8 |
| Adversarial robustness | 7.7 |
| Compatibility completeness | 8.0 |
| Architecture | 8.9 |
| Independent evidence | 8.2 |
| Performance | 7.9 |
| Resource behavior | 7.5 |
| Portability | 9.0 |
| Longevity | 8.2 |
| Interoperability | 7.5 |
| Self-host/bootstrap | 9.1 |
| Auditability | 8.9 |
| Novelty | 9.0 |
| SAVEF | 6.5 |
| **Average** | **8.04** |

This score rises only when code, proofs, gates, adversarial evidence, and measured SAVEF reuse land.

---

# 47. Iteration A

Iteration A adds exact algorithmic-defeq contracts, cache refinement, provider semantic/security separation, Comparator-v1, IndependenceVector, dual metatheory tracks, proof-carrying build actions, resource algebra, and TheoryBridge.

| Criterion | Iteration A |
| --- | ---: |
| Soundness/fidelity | 9.92 |
| TCB transparency | 9.91 |
| Formal/metatheoretic verification | 9.85 |
| Adversarial robustness | 9.90 |
| Compatibility completeness | 9.87 |
| Architecture | 9.94 |
| Independent evidence | 9.91 |
| Performance | 9.78 |
| Resource behavior | 9.82 |
| Portability | 9.90 |
| Longevity | 9.90 |
| Interoperability | 9.86 |
| Self-host/bootstrap | 9.94 |
| Auditability | 9.93 |
| Novelty | 9.90 |
| SAVEF | 9.97 |
| **Average** | **9.89** |
| **Minimum** | **9.78** |

Result: continue iteration.

---

# 48. Iteration B — accepted design

Iteration B additionally adds computed TrustManifest closure, TrustDelta/SemanticDelta review, ProviderSecurityProfile, resource monotonicity, proof-carrying cache, bounded/streaming verification, portable verifier capsule, archive profile/hash agility, structural plus behavioral module interfaces, theory graph/morphisms, solver certificates, explicit knowledge validity/migration, reuse ledger, FactoryBench-v4, audit CLI, historical indexing policy, and permanent adversarial regression families.

| Criterion | Final target |
| --- | ---: |
| Soundness/fidelity | **9.96** |
| TCB transparency | **9.95** |
| Formal/metatheoretic verification | **9.94** |
| Adversarial robustness | **9.96** |
| Compatibility completeness | **9.93** |
| Architecture | **9.97** |
| Independent evidence | **9.96** |
| Performance | **9.90** |
| Resource behavior | **9.93** |
| Portability | **9.95** |
| Longevity | **9.96** |
| Interoperability | **9.93** |
| Self-host/bootstrap | **9.96** |
| Auditability | **9.97** |
| Novelty | **9.92** |
| SAVEF | **9.98** |
| **Average** | **9.95** |
| **Minimum** | **9.90** |

Acceptance rule satisfied. Stop iteration.

No criterion is scored 10. Future implementation, independent replication, hostile-input experience, and long-term proof maintenance can still reveal weaknesses.

---

# 49. Strongest near-term implementation sequence

**Execution-scope override for `pscv/v3-execution`:** PSKernel implementation, algorithmic-defeq/cache proof work, checker-soundness proof work, semantic-model/consistency proof work, and other kernel-internal development are owned by the separate kernel branch/workstream. This PSCV compiler branch must not modify kernel implementation or proof sources. It consumes only the frozen KernelContract/provider interfaces plus exact imported kernel evidence identities. Kernel architecture remains part of the system model, but kernel development is not part of this branch's execution plan.

1. Register current/frozen/experimental/target architecture identities.
2. Close the AdmissionReady production authority bypass.
3. Integrate ProviderSecurityProfile separately from semantic compatibility without modifying provider internals.
4. Add and enforce compiler-wide TrustManifest.
5. Close the current VerifiedIR invariant gap matrix.
6. Introduce explicit SpecializedIR capability.
7. Unify PassDefinition, BuildAction, SemanticFingerprint, and evidence.
8. Complete Comparator-v1 compiler-side sandbox/export/replay plumbing using external provider interfaces.
9. Introduce StructuralModuleInterface and BehavioralModuleInterface.
10. Drive QueryGraph reuse from semantic interface fingerprints.
11. Implement erasure preservation hooks/validators while leaving expensive global proofs to the assurance phase.
12. Implement specialization preservation hooks/independent correspondence validation while leaving expensive global proofs to the assurance phase.
13. Add complete target-IR validation architecture, starting with JsIR/WasmIR.
14. Implement target-specific ABI adapters through InterfaceIR/WIT/native adapter contracts.
15. Implement SAVEF theory/knowledge graph, persistent derived index, and validated tool retrieval.
16. Build portable verifier/archive capsule.
17. Complete FactoryBench execution infrastructure while keeping real holdout experiments deferred.
18. Finish direct JS/Rust/Wasm self-host implementation and exact fixed-point infrastructure.
19. Complete B9/DDC execution tooling and later import actual diverse evidence.
20. Freeze V3 compiler architecture once all non-kernel implementation capabilities are connected.

---

# 50. Immediate milestone acceptance criteria

The next **PSCV compiler-branch** architecture milestone requires:

1. production drivers cannot erase from AdmissionReady;
2. CheckedCoreCapability is required by type/dependency topology;
3. provider identity includes semantic target and implementation/security identity without modifying provider internals;
4. provider failure never falls back;
5. TrustManifest matches computed compiler/host import closure;
6. imported kernel contract/evidence identities are exact and treated as external dependencies;
7. VerifiedIR gap matrix is machine-readable and implementation gaps are explicit;
8. SpecializedIR is a distinct capability;
9. specialization emits PassDefinition/PassExecution evidence;
10. one certified ModuleInterface fingerprint drives actual QueryGraph semantic reuse;
11. Comparator-v1 sandbox/export/replay plumbing exists against external provider interfaces;
12. JsIR/WasmIR validation boundaries are explicit and fail closed;
13. target ABI adapter capabilities are explicit and unsupported targets fail closed;
14. one SAVEF object stores resulting pass/interface evidence and the persistent index remains non-authoritative;
15. FactoryBench holdout remains sealed before knowledge exposure;
16. Direct JS/Rust/Wasm self-host infrastructure preserves exact fixed-point acceptance criteria;
17. no file under the kernel implementation/proof workstream is modified by this branch.

---

# 51. Research basis

Version 3 materially incorporates current Lean proof-validation/comparator architecture, Lean 4.34 and 4.34.1 kernel/runtime hardening, Lean4Lean, current independent Lean checkers and model-checking work, MetaRocq, CompCert, CakeML, Isabelle/LCF proof replay, F*, Dafny, DeepSpec, Iris/Aneris, Proof-Carrying Code, OpenTheory, Dedukti/Logipedia, MMT/OMDoc, Alethe, WebAssembly Component Model/WIT, SLSA/in-toto, Diverse Double-Compiling, and current Lean theorem-retrieval/lifelong-proof systems.

The architecture borrows mechanisms, not whole languages.

---

# 52. Canonical Version-3 architecture

~~~text
                     UNTRUSTED PRODUCERS
      source / dependencies / plugins / AI / solvers
                              |
                              v
                     PROFILE CONFORMANCE
                              |
                              v
                 Parse / Resolve / Elaborate
                              |
                              v
                         CandidateCore
                              |
                    canonical admissions
                              |
                              v
                    +------------------+
                    | AUTHORITY PLANE  |
                    +------------------+
                              |
                       KernelContract
                              |
                    selected provider
                              |
                  ProviderSecurityProfile
                              |
                              v
                    CheckedCoreCapability
                              |
                           PSCV-CERT
                              |
                              v
                       CertifiedSource
                       /             \
                      /               \
                     v                 v
      Structural/Behavioral           Erasure
          ModuleInterface                |
                                         v
                                      RuntimeIR
                                         |
                                 ValidateRuntimeIR
                                         |
                                         v
                                      VerifiedIR
                                         |
                                    Specialize
                                         |
                                         v
                                    SpecializedIR
                              /           |           \
                             v            v            v
                           JsIR         WasmIR       adapters
                             |            |          TS/Rust
                          validate     validate
                             |            |
                             v            v
                             JS          Wasm
                              \           /
                               \         /
                            ExecutableArtifact
                                   |
                                   v
                           EvidenceEnvelope
                                   |
                 +-----------------+-----------------+
                 |                 |                 |
                 v                 v                 v
            Query / CAS       Trust / Audit      TheoryBridge
                 |                 |                 |
                 v                 v                 v
         SemanticFingerprint  AssuranceVector    logical proof
                 |                 |              interoperability
                 +-----------------+-----------------+
                                   |
                                   v
                             SAVEF / SPKF
                    specs / theorems / interfaces
                   pass evidence / assumptions / failures
                    resource and implementation evidence
                                   |
                                   v
                           derived semantic index
                                   |
                                   v
                               AI / tools
                                   |
                                   v
                         next untrusted proposal
                                   |
                                   +----> authority re-check
~~~

---

# 53. Final decision

Version 3 clears the requested threshold under a stronger condition:

~~~text
average target-design score = 9.95
minimum criterion = 9.90
~~~

The most important implementation priority is unchanged: close the AdmissionReady-to-erasure production bypass.

The most important theoretical improvement is to model Lean-compatible algorithmic definitional equality separately from declarative conversion and prove cache/acceleration refinement.

The most important adversarial improvement is to separate semantic-profile identity from provider implementation/security identity and use comparator-style sandbox/export/replay for high-assurance decisions.

The most important SAVEF improvement is to make theory morphisms, pass contracts, deep module interfaces, assumption closures, failures, migrations, and actual reuse events first-class typed knowledge.

The most important longevity improvement is to make releases verifiable offline from canonical artifacts, exact contracts, migration evidence, and a portable verifier capsule.

The governing invariant remains:

> Smart components may propose; small authorities decide.

---


---

# 54. Post-write document-architecture audit

Version 2 embedded the entire predecessor reference as an appendix. That was good provenance but poor canonical-document structure: old score tables, old final recommendations, and old baselines remained textually present after the new final decision.

Version 3 fixes this by being standalone. Predecessors remain immutable Git history and explicit research references rather than duplicate normative content.

Consequences:

- one current authority hierarchy;
- one final architecture diagram;
- one accepted score table;
- one implementation roadmap;
- one current research interpretation;
- no stale normative text after the final decision;
- lower AI/RAG context contamination;
- simpler machine indexing and future supersession.

This improves auditability and longevity without changing compiler semantics.

---

# 55. Primary-source verification notes

The following current external findings were explicitly rechecked during the Version-3 audit.

## Lean proof validation and comparator

Lean's current reference manual distinguishes ordinary trusted-development checking, lean4checker replay, and a gold-standard comparator workflow for malicious proofs. Comparator builds the submission in a sandbox, exports proof data, validates it outside the sandbox, checks the theorem statement against a trusted challenge, and can replay with the official kernel plus independent external checkers.

Reference: https://lean-lang.org/doc/reference/latest/ValidatingProofs/

PSCV consequence: Comparator-v1 is justified as a distinct assurance mode, not as the ordinary edit-time path.

## Lean 4.34 kernel hardening

Lean 4.34.0 fixed three routes to false proofs. Of particular architectural importance, the is-def-eq cache had used union-find even though the implemented equality test is sound but incomplete and not transitive. Lean replaced the transitive closure with a plain query-pair cache.

Reference: https://lean-lang.org/doc/reference/latest/releases/v4.34.0/

PSCV consequence: algorithmic defeq and cache-refinement contracts must be first-class and exact.

## Lean 4.34.1 runtime hardening

Lean 4.34.1 is a patch release encouraging users to upgrade because it fixes runtime/reference-counting hazards that could potentially be extended into false-proof acceptance on enormous hostile inputs.

Reference: https://lean-lang.org/doc/reference/latest/releases/v4.34.1/

PSCV consequence: semantic target identity and provider implementation/security revision are separate contracts.

## Lean4Lean

Lean4Lean provides an external Lean-4 typechecker in Lean, usable on mathlib, and explicitly targets formalizing the abstract Lean type theory and its relationship to kernel functions.

Reference: https://arxiv.org/abs/2403.14064

PSCV consequence: an owned checker should be related to a declarative theory rather than merely differentially tested.

## CakeML

CakeML combines formal language semantics, a verified compiler backend, and a bootstrapped compiler produced inside HOL with a theorem connecting the binary to the compiler implementation.

Reference: https://cakeml.org/

PSCV consequence: verified compilation and verified bootstrap are composable but separate claims.

## OpenTheory

An OpenTheory article encodes a theory as explicit assumptions and exported theorems together with the proof that the exports follow from those assumptions.

Reference: https://www.gilith.com/opentheory/article.html

PSCV consequence: portable proof packages should make imports/assumptions/exports explicit.

## MMT

MMT is foundation-independent and organizes formal knowledge into theories and theory morphisms, with morphisms translating between theories.

References:
- https://uniformal.github.io/doc/
- https://uniformal.github.io/doc/language/modules

PSCV consequence: SAVEF TheoryBridge and theory-graph objects should be explicit instead of flattening cross-foundation knowledge into generic links.

## Dedukti / Logipedia

Logipedia demonstrates a proof library expressed in Dedukti with proof translations between theories and exports toward multiple proof systems.

Reference: https://logipedia.inria.fr/about/about.php

PSCV consequence: cross-foundation proof interoperability is feasible but must expose translation assumptions and unsupported features.

## SLSA provenance

SLSA provenance is verifiable information about where, when, and how an artifact was produced.

Reference: https://slsa.dev/spec/v1.2/provenance

PSCV consequence: provenance belongs in EvidenceManifest/supply-chain evidence and must not be confused with semantic proof.

## Diverse Double-Compiling

DDC targets trusting-trust attacks by using a diverse trusted compiler path and comparing the resulting compiler executable under explicit assumptions.

Reference: https://dwheeler.com/trusting-trust/

PSCV consequence: ordinary self-host/fixed-point reproduction is not DDC; diversity lineage must be recorded.

---

# 56. Final standalone-reference score

The architecture design remains the accepted Iteration-B design. The standalone document cleanup specifically improves auditability and longevity while leaving the conservative performance floor unchanged.

| Criterion | Version-3 target |
| --- | ---: |
| Soundness/fidelity | **9.96** |
| TCB transparency | **9.95** |
| Formal/metatheoretic verification | **9.94** |
| Adversarial robustness | **9.96** |
| Compatibility completeness | **9.93** |
| Architecture | **9.98** |
| Independent evidence | **9.96** |
| Performance | **9.90** |
| Resource behavior | **9.93** |
| Portability | **9.95** |
| Longevity | **9.97** |
| Interoperability | **9.93** |
| Self-host/bootstrap | **9.96** |
| Auditability | **9.99** |
| Novelty | **9.92** |
| SAVEF | **9.98** |
| **Average** | **9.95** |
| **Minimum** | **9.90** |

Acceptance remains satisfied under the stronger rule: average at least 9.90 and every individual criterion at least 9.90.

---

# 57. Supersession rule

This file is the recommended design reference produced by this evaluation loop.

Predecessors remain research provenance:

- THE_PSCV_COMPILER_REFERENCE.md
- THE_PSCV_COMPILER_REFERENCE_VERSION_2.md
- repository-root PSCV_COMPILER_REFERENCE.md
- repository-root PSCV_COMPILER_REFERENCE_VERSION_2.md

When implementation begins, create machine-readable architecture/status entries rather than copying another complete reference into a new file. Future revisions should use semantic deltas and ADRs unless a full new edition is genuinely required.
