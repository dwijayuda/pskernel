# ProofScript Self-Amplifying Verified Ecosystem Factory — Version 2

**Status:** strategic architecture and research reference; non-normative.

**Working identity:** SAVEF-v2 — Self-Amplifying Verified Ecosystem Factory.

**Research snapshot:** 2026-10-06.

**Repository context evaluated:**
- baseline compiler/kernel architecture: branch **psc2/selfhost-lean-kernel**, directory **psc15selfhost/**;
- PSCV verified-language direction: branch **psc2/pscv-direct-backends**, **ProofScript Language Reference — PSCV Verified Profile / PSCV-RC-v2**;
- kernel-proof direction: branch **pscv/prove-pskernel-core-v1**;
- compiler-proof experiment: branch **pscv/selfhost-poc-v1**;
- prior SAVEF research: **study/pscv-research/PROOFSCRIPT_SELF_AMPLIFYING_VERIFIED_ECOSYSTEM_FACTORY.md** on main.

**Purpose:** replace the first SAVEF research architecture with a more rigorous design that is explicitly grounded in the existing ProofScript compiler/kernel seams, PSCV verification semantics, Lean's actual type theory and kernel architecture, and current evidence about AI-assisted verified software construction.

This document does **not** claim that SAVEF-v2 is implemented. Architecture quality and implementation maturity are scored separately.

---

# Executive decision

The central thesis survives deep review, but it needs a stricter formulation.

The useful idea is not:

> Software is literally mathematics.

Nor:

> Proofs should replace tests.

The stronger and more accurate thesis is:

> **A ProofScript ecosystem can make an increasing fraction of software engineering behave like the accumulation of a formal mathematical theory: definitions, specifications, implementations, lemmas, refinement relations, effect laws, and proofs become reusable machine-checkable knowledge. Claims that cross into hardware, networks, external services, users, performance, or incompletely modeled environments remain explicitly empirical or assumed.**

The desired epistemic structure is therefore:

> **deduction where the world has been formalized; measurement and observation at the boundary where it has not.**

Short form:

> **Mathematics inside; science at the boundary.**

The deeper SAVEF goal is economic as well as logical:

> **As the accepted ProofScript ecosystem grows, comparable new software capabilities should require less human supervision, less repeated reasoning, fewer model tokens, fewer repair iterations, and less duplicated implementation, while preserving or increasing correctness assurance.**

The route to that goal is not a giant autonomous AI subsystem inside the compiler.

It is a stable semantic substrate in which:

1. specifications are immutable and identity-bound;
2. proof obligations are explicit and machine-readable;
3. kernel-admitted source states are distinct from merely elaborated/prepared states;
4. erasure and backend compilation have their own preservation evidence;
5. assumptions are first-class and transitive;
6. package interfaces export deep behavioral specifications;
7. the compiler exposes exact semantic dependency slices;
8. AI remains an untrusted search and synthesis layer;
9. accepted results are converted into reusable formal knowledge;
10. the knowledge index is derived from authoritative checked artifacts rather than becoming a new source of truth.

The existing ProofScript architecture is already unusually compatible with this direction. The main task is **integration and authority discipline**, not replacement.

---

# 1. Evaluation result and iteration loop

## 1.1 Scoring interpretation

Scores below evaluate **architecture quality**, not implementation completion.

A 9.5 architecture score means:

- the design is internally coherent;
- its trust boundaries are explicit;
- it maps onto the existing repository;
- it has credible formal-methods precedents;
- it can be implemented incrementally;
- it has measurable success/failure conditions;
- known hard problems are represented honestly rather than hidden behind the word verified.

It does **not** mean 95 percent of the system exists.

Implementation maturity is reported separately.

## 1.2 Weighted criteria

The architecture is scored against twenty dimensions totaling 100 weight points.

| Criterion | Weight |
| --- | ---: |
| Epistemic thesis precision | 6 |
| Lean/type-theory fidelity | 5 |
| PSCV semantic integration | 7 |
| Trust/TCB architecture | 6 |
| Typed semantic/evidence states | 6 |
| Deep specifications/composition | 5 |
| Effects/world/concurrency | 5 |
| Compiler/artifact preservation | 7 |
| Assumption/evidence modeling | 5 |
| Incremental/query architecture | 5 |
| AI semantic interface | 5 |
| Specification/reward-hacking resistance | 5 |
| Ecosystem knowledge graph | 5 |
| Self-amplification measurement | 5 |
| Interop/progressive assurance | 4 |
| Bootstrap/provenance | 4 |
| Performance/resource behavior | 4 |
| Repository implementability | 4 |
| Independent evidence/metatheory | 3 |
| Longevity/versioning | 4 |

Hard gates are not allowed to be averaged away. In the final design, every hard gate must score at least 9.5.

Hard gates:

- Lean/type-theory fidelity;
- PSCV semantic integration;
- trust/TCB architecture;
- typed semantic/evidence states;
- compiler/artifact preservation;
- specification integrity;
- assumption transparency;
- semantic version identity.

## 1.3 Baseline: original SAVEF document

Weighted architecture score:

**7.88 / 10**

Strengths:

- strong software-as-mathematics framing;
- correctly preserves an empirical boundary;
- treats AI as proposer rather than proof authority;
- introduces assumption tracking and reusable theory/capability knowledge;
- recognizes proof maintenance and compounding reuse;
- defines useful FactoryBench-style economic metrics.

Main deficiencies:

1. it is not tightly bound to the actual PSCV semantic state machine;
2. it can be read as if a Verified Theory Graph itself carries authority;
3. it does not sufficiently distinguish current AdmissionReady state from genuine CheckedCore;
4. it does not distinguish source verification from erasure/backend semantic preservation strongly enough;
5. it does not incorporate PSCV-RC-v2's existing PSCV-VERIFY-v1, PSCV-CERT-v1, SPEC/PROOF/EXEC relevance, SpecCapsule identity, proof closure, and specification coverage;
6. it does not handle the Lean 4.34 current implementation versus Lean 4.35.0-rc3 PSCV semantic-pin transition explicitly;
7. its recommended repository structure is too abstract relative to psc15selfhost;
8. it does not integrate the existing QueryGraph as the basis of incremental verification;
9. it under-specifies independent-checker requirements despite recent Lean kernel soundness failures;
10. its factory self-improvement loop needs stronger anti-reward-hacking isolation.

The baseline fails multiple hard gates.

## 1.4 Iteration A

Major changes:

- bind every verified claim to exact PSCV semantic identities;
- introduce explicit source/IR/backend assurance stages;
- make theory manifests derived indexes rather than authorities;
- extend existing QueryGraph rather than inventing a parallel build graph;
- adopt PSCV proof-closure/specification-coverage semantics;
- make the compiler service the sole semantic API for agents;
- separate logical, compiler, boundary, and provenance evidence.

Weighted architecture score:

**9.39 / 10**

This does not clear the target. Remaining weak areas are:

- concurrency/resource/world-effect formalization strategy;
- bootstrap trust and compiler-execution assurance;
- resource/performance treatment;
- exact version migration and evidence portability.

## 1.5 Iteration B — accepted SAVEF-v2 architecture

Final additions:

- explicit formalization coverage architecture for pure/state/resource/concurrent/distributed domains;
- separate logical TCB, acceleration TCB, execution TCB, boundary assumptions, and release-policy authority;
- exact SemanticProfileIdentity;
- BackendPreservationContract;
- explicit high-assurance independent checker tier;
- content-addressed Typed Ecosystem Knowledge Graph derived from authoritative evidence;
- proof-maintenance and semantic-interface invalidation integrated into QueryGraph;
- factory self-improvement evaluated with pinned models, frozen holdouts, immutable policy, and replayable evidence;
- implementation plan that begins with current psc15selfhost gaps rather than AI tooling.

Weighted architecture score:

**9.66 / 10**

Minimum hard-gate score:

**9.5 / 10**

This meets the requested architecture threshold.

Current implementation/evidence maturity is much lower:

**approximately 5.4 / 10 for the complete SAVEF-v2 vision**

That separation is intentional. The compiler/kernel foundation is substantial; the PSCV verified profile and kernel metatheory are actively progressing; the ecosystem factory layer is mostly architecture/research work.

---

# 2. What the software-as-mathematics thesis actually means

## 2.1 Conventional software already has semantics

Programs in C, C++, Python, TypeScript, Rust, Lean, or ProofScript are not non-mathematical objects.

They can all be given mathematical semantics.

The difference is mostly epistemic and operational:

- which properties are written down precisely;
- which properties are mechanically checked;
- how evidence composes;
- whether assumptions are explicit;
- whether later software can reuse earlier correctness arguments.

Ordinary software ecosystems usually encode most behavioral knowledge informally in:

- implementations;
- types;
- tests;
- documentation;
- bug history;
- benchmarks;
- production experience;
- conventions;
- human expertise.

SAVEF attempts to convert a much larger fraction of that knowledge into explicit, composable formal objects.

## 2.2 The mathematical analogy

A useful correspondence is:

| Formal mathematics | SAVEF software |
| --- | --- |
| logical foundation | Lean-grounded PSCV semantics |
| definitions | types, state models, protocols, interfaces |
| proposition | behavior/specification |
| lemma | reusable invariant or API law |
| theorem | checked correctness/refinement result |
| constructive witness | executable implementation |
| theory/library | verified package |
| imported theorem | dependency guarantee |
| conservative extension | package adding capability without new unproved trust |
| axiom | explicit logical or external assumption |
| proof checker | designated PSKernel provider |
| mathematical library search | semantic/theorem/capability retrieval |
| theorem dependency graph | proof/spec/capability dependency graph |

The analogy is strongest where:

- execution is total or has a formal effect semantics;
- interfaces expose deep specifications;
- refinements compose;
- proofs depend on abstract interfaces rather than implementation details;
- the compiler preserves the proved semantics.

It becomes weaker where requirements depend on subjective intent or an uncontrolled external world.

## 2.3 The crucial difference from pure mathematics

Software is executed in an environment.

Therefore SAVEF must reason about at least two categories:

~~~text
deductive claims
    +
world correspondence claims
~~~

For example:

~~~text
kernel-checked:
    parser(encode(x)) = x

empirically / externally justified:
    deployed network stack delivers bytes according to the modeled contract
~~~

A complete deployed assurance argument is conditional.

Conceptually:

~~~text
Gamma |- Program satisfies Specification

CompilerPreserves(Program, Artifact)

Environment satisfies Gamma
--------------------------------------

Deployed Artifact satisfies Specification
~~~

The first two lines may be deductive.

The third may contain empirical evidence and assumptions.

SAVEF must never hide that distinction.

---

# 3. Lean 4 is a powerful foundation, but not an idealized textbook calculus

The ProofScript architecture must be faithful to **actual Lean semantics**, not a simplified slogan such as dependent type theory guarantees correctness.

## 3.1 Actual Lean kernel theory

The current Lean reference describes a version of the Calculus of Constructions with:

- full dependent types;
- mutual and nested inductive types;
- impredicative, definitionally proof-irrelevant, extensional Prop;
- predicative non-cumulative data universes;
- quotient types with definitional computation;
- propositional function extensionality;
- definitional eta for functions and products;
- universe polymorphism.

Lean's trusted kernel is intentionally much smaller than the elaborator and tactic system.

The frontend can be expressive because candidate proof terms are checked by the kernel.

This is exactly the architectural pattern ProofScript should preserve.

## 3.2 Important non-textbook properties

The current Lean reference explicitly notes that:

- the type theory does not have subject reduction in the usual sense;
- algorithmic definitional equality is reflexive and symmetric but not necessarily transitive;
- the type checker can be forced into nontermination on adversarial inputs;
- none of these facts by itself destroys logical soundness.

This matters greatly for ProofScript.

SAVEF must not assume that a generic textbook metatheory for CIC automatically proves equivalence with the actual Lean checker algorithm.

The correct approach is:

~~~text
abstract semantic judgments
        +
version-pinned executable checker semantics
        +
refinement/soundness theorems between them
        +
differential and independent checking
~~~

## 3.3 Lean 4.34 hardening lesson

Lean 4.34 fixed three routes to a proof of False, including one caused by treating an intentionally incomplete non-transitive definitional-equality relation as though successful queries could safely be unioned transitively.

This demonstrates a central SAVEF principle:

> **A data structure described as an optimization can still be in the logical TCB when a bug in it changes acceptance.**

Therefore ProofScript must separate:

- logical TCB;
- acceleration TCB;
- execution TCB;
- assurance-only tools.

The existing PSKERNEL_TCB.json already points in the correct direction.

## 3.4 Independent checking is not optional at the highest assurance tier

Lean explicitly values independent kernel implementations.

ProofScript should adopt a graded policy:

~~~text
standard assurance:
    designated PSKernel provider

high assurance:
    designated provider
    + independent checker/replay implementation

release-critical assurance:
    independent checker diversity
    + reproducible evidence
    + artifact preservation evidence
~~~

This is especially important for AI-generated hostile or unusual proof terms, because the same AI that discovers software bugs can also discover checker edge cases.

---

# 4. Semantic pinning: current PSC2 and PSCV must not be conflated

A major current architecture fact is that two legitimate semantic snapshots coexist.

## 4.1 Current psc15selfhost baseline

The evaluated psc15selfhost branch currently targets Lean 4.34 behavior and uses the pinned Lean provider as the default checked provider.

Its bootstrap/compiler architecture is therefore a **Lean-4.34-oriented implementation snapshot**.

## 4.2 PSCV-RC-v2 direction

The PSCV verified-profile reference on the direct-backend branch is independently repinned to:

~~~text
Lean 4.35.0-rc3
commit 470d5ce1400764999581fd26d5d72b00d990b0f4
PSCV verification semantics: PSCV-VERIFY-v1
certificate policy: PSCV-CERT-v1
profile: pscv-v1
~~~

This is a valid forward design, but evidence produced under Lean 4.34 must not silently be treated as evidence under Lean 4.35-RC3.

## 4.3 SemanticProfileIdentity

Every SAVEF authoritative artifact should bind to an identity equivalent in purpose to:

~~~text
SemanticProfileIdentity {
    proofScriptEdition
    sourceProfile
    pscvProfile
    pscvVerificationSemantics
    pscvCertificatePolicy
    leanSemanticVersion
    leanCommit
    standardEnvironmentDigest
    kernelContractIdentity
    runtimeSemanticsIdentity
    compilerIrSchemaIdentity
}
~~~

Any change that can affect meaning creates a new semantic identity.

Proofs, capability manifests, cached results, agent memories, and compatibility claims are reusable across profiles only through an explicit migration/refinement proof or revalidation.

---

# 5. Current psc15selfhost architecture audit

## 5.1 Existing package decomposition

The current repository already contains a strong compiler decomposition:

~~~text
foundation
syntax
core
environment
meta
elab
bridge
compiler-ir
erasure
compiler
project

backend-ts
backend-js
backend-wasm
backend-rust

bootstrap
cli
drivers

pskernel-core
pskernel-lean-wasm
pskernel-lean
pskernel
~~~

This is preferable to introducing a second factory-specific compiler.

SAVEF should extend these seams.

## 5.2 Current minimal self-host closure

The current minimal compiler fixed-point closure intentionally contains approximately:

~~~text
bootstrap
foundation
syntax
core
environment
meta
elab
bridge
compiler-ir
erasure
compiler
backend-ts
portable stdlib
~~~

Kernel code is deliberately outside the smallest compiler-only bootstrap closure.

That is a sound bootstrap engineering choice.

The SAVEF architecture must **not** pull AI, package indexes, proof search, registries, or factory orchestration into this closure.

## 5.3 Current semantic path is honestly named

The current compiler uses:

~~~text
source
  -> parse / resolve / elaborate
  -> PsCompilerAdmissionReadyModule
  -> environment reconstruction
  -> erasure
  -> PsErasedIrModule
  -> psValidateErasedIrModule
  -> PsValidatedIrModule
~~~

The name **AdmissionReady** is important.

The current preparation step proves that declarations can be canonically encoded for the admission protocol.

It does **not** prove that a designated kernel admitted the module.

In fact, current functions named psCompilerCheckElaborated and psCompilerCheckSource are aliases of preparation in the evaluated branch.

Therefore SAVEF-v2 adopts a hard rule:

> **No factory claim, type, manifest, AI tool, or UI may label AdmissionReady as CheckedCore.**

## 5.4 Current IR boundary is already moving in the right direction

The raw compiler IR family historically uses names containing VerifiedIr, but the current architecture explicitly treats raw values as construction state.

The real staged distinction is:

~~~text
raw erased/construction IR
    ->
validator
    ->
PsValidatedIrModule
~~~

The validator rejects unresolved runtime types and structural inconsistencies.

This is the correct pattern.

Future cleanup should make the naming physically match the authority:

~~~text
RuntimeIR / ErasedIR
    ->
validateRuntimeIr
    ->
VerifiedIR
~~~

## 5.5 QueryGraph is the seed of the factory's incremental knowledge engine

The existing project query graph tracks:

- source keys;
- interface keys;
- import relationships;
- dependency interface changes;
- green/red invalidation.

SAVEF should extend this mechanism.

Do **not** build a disconnected AI knowledge database that independently guesses semantic dependency.

The long-term query record should grow conceptually toward:

~~~text
ModuleQueryRecord {
    sourceKey
    elaboratedInterfaceKey
    approvedSpecKey
    obligationSetKey
    checkedCoreKey
    theoremInterfaceKey
    assumptionClosureKey
    verifiedIrKey
    backendEvidenceKeys
    capabilityManifestKey
    dependencyInterfaces
}
~~~

Only affected semantic slices should become red.

This is essential for proof-maintenance economics.

---

# 6. Current PSKernel audit

## 6.1 Strong current architecture

The canonical portable kernel now has a deliberate source hierarchy:

~~~text
Ps/KernelCore/
    Core/
    Environment/
    Runtime/Acceleration/
    Runtime/Capability/
    Checker/
    Admission/
    API/
    SelfHost.lean
~~~

Important strengths:

- one canonical semantic root;
- exact Lean semantic target;
- explicit fail-closed outcomes;
- no semantic fallback;
- immutable-session API;
- distinct requested / checked / admitted values;
- explicit resource outcomes;
- separate acceleration TCB;
- explicit optional native-reduction capability;
- independent Lean provider and frozen reference oracles.

This is unusually compatible with SAVEF.

## 6.2 Receipts are not proof certificates

KernelContract-v1 explicitly states that its checking receipt is:

- process-local;
- not signed;
- not a serializable admission authority;
- not a proof certificate.

SAVEF must preserve that distinction.

A future evidence envelope may **reference** a kernel admission event, but it cannot upgrade a lightweight receipt into theorem authority by metadata alone.

## 6.3 Current formal proof work is promising but incomplete

The pscv/prove-pskernel-core-v1 branch introduces broad proof sidecars and an independent metatheory.

Its semantic audit deliberately grades the 79 canonical module/proof pairs:

~~~text
A semantic/refinement:        9
B theory foundations:        25
C control/branch assurance:  37
D shallow/base:               8
~~~

This is important evidence of direction, not completion.

The audit itself correctly notes missing work in:

- general substitution properties;
- cache/index refinement;
- full typing refinement;
- reduction reachability/preservation;
- defeq soundness;
- declaration/environment admission;
- positivity and inductive correctness;
- end-to-end KernelContract success => semantic judgment.

SAVEF-v2 therefore treats formal PSKernel verification as a **progressive refinement program**, not a completed premise.

---

# 7. Current PSCV verified-profile audit

The PSCV-RC-v2 language design already contains several concepts that the first SAVEF document independently reinvented.

SAVEF-v2 should use the PSCV definitions rather than create competing concepts.

## 7.1 Existing PSCV laws to adopt directly

The PSCV profile already specifies:

- **pscv-v1** as a strict verified-programming profile;
- **PSCV-VERIFY-v1** for verification semantics;
- **PSCV-CERT-v1** for executable certification;
- proof closure;
- specification coverage;
- approved specification identity;
- SpecCapsule linkage;
- anti-weakening rules;
- closed versus explicit-boundary policies;
- SPEC / PROOF / EXEC relevance;
- proof and ghost erasure;
- total verified executable closure;
- verified effects through weakest-precondition/Hoare semantics;
- effect-law obligations;
- explicit world boundaries;
- canonical obligation identity;
- source declarations that may remain proof-open but cannot enter a verified executable.

These should be the language-facing authority of SAVEF.

## 7.2 PSCV is not another foundational logic

A central PSCV strength is:

> one logic.

Contracts, weakest preconditions, refinement types, ghost state, and domain-specific verification systems should ultimately elaborate to ordinary propositions/proof terms or explicitly checked judgments in the Lean-grounded foundation.

This allows SAVEF to support sophisticated program logics without enlarging PSKernel for every domain.

---

# 8. The canonical SAVEF-v2 semantic state machine

This is the most important change from Version 1.

A factory output is not simply either unverified or verified.

It moves through typed states.

~~~text
HumanIntent
    |
    v
RequirementIR
    |
    v
ApprovedSpecCapsule
    |
    v
SourceCandidate
    |
    v
Parsed / Elaborated CandidateCore
    |
    +--> open PSCV obligations
    |         |
    |         v
    |    proof/tactic/AI/solver candidates
    |         |
    +---------+
    |
    v
AdmissionReadyModule
    |
    | designated kernel provider
    v
CheckedCore
    |
    | PSCV-CERT-v1 policy:
    | - proof closure
    | - specification coverage
    | - effect closure
    | - assumption policy
    | - profile identity
    v
CertifiedSourceModule
    |
    | semantics-justified erasure
    v
RuntimeIR / ErasedIR
    |
    | validateRuntimeIr
    v
VerifiedIR
    |
    +------------+-------------+
    |            |             |
    v            v             v
   JsIR        WasmIR       Adapter IR
    |            |             |
    | backend proof or translation validation
    v            v             v
PreservedTargetArtifact
    |
    | boundary/provenance evidence
    v
ReleaseEvidenceEnvelope
    |
    v
Derived TheoryManifest / CapabilityManifest
~~~

Every arrow has a distinct obligation.

A later state may use guarantees of an earlier state.

It must not retroactively strengthen the earlier state's meaning.

---

# 9. Required semantic artifact types

The concrete encoding is future implementation work, but the architecture should have equivalents of the following.

## 9.1 ApprovedSpecCapsule

Binds:

- formal claims;
- requirement traceability;
- assurance policy;
- allowed assumptions;
- semantic profile identity;
- canonical digest;
- approval metadata.

Changing a formal claim creates a new identity.

## 9.2 ObligationSet

Contains:

- declaration identity;
- exact proposition/judgment;
- local assumptions;
- effect model;
- spec identity;
- source/core identity;
- dependency theorem identities;
- status.

Proof construction tools operate on this representation.

## 9.3 CheckedCore

Can be produced only through the configured KernelContract provider.

It carries or is associated with:

- exact checked core hash;
- kernel contract identity;
- semantic profile identity;
- environment identity;
- session/admission provenance.

The implementation may use an opaque provider-owned handle when generated-language privacy is insufficient.

## 9.4 CertifiedSourceModule

This is **not** identical to CheckedCore.

CheckedCore means the core declarations were accepted by the logical authority.

CertifiedSourceModule additionally means the build policy has established:

- all mandatory PSCV obligations are closed;
- specification coverage passes;
- effect policy passes;
- transitive assumption policy passes;
- the exact approved specification is bound;
- no proof-open or forbidden executable dependency remains.

This corresponds to PSCV-CERT-v1.

## 9.5 VerifiedIR

Means runtime/executable IR invariants are validated.

It must not contain unresolved construction placeholders.

This state does not automatically prove backend code generation correct.

## 9.6 PreservedTargetArtifact

Means the target artifact is connected to VerifiedIR through accepted preservation evidence.

Examples:

- formally proved lowering;
- proof-producing lowering;
- independently checked translation validation;
- a lower assurance policy explicitly recorded as such.

## 9.7 ReleaseEvidenceEnvelope

Binds without pretending to prove more than its components:

- semantic profile identity;
- approved specification;
- checked source identity;
- IR identity;
- backend evidence;
- transitive assumptions;
- boundary evidence;
- build/provenance identity;
- artifact digest;
- resource/benchmark evidence where applicable.

---

# 10. Replace a single verified bit with an Assurance Vector

The word verified becomes misleading when it collapses unrelated guarantees.

SAVEF-v2 should expose a vector such as:

~~~text
AssuranceVector {
    specification
    logicalProof
    compilerErasure
    backendPreservation
    boundaryModel
    provenance
    resourcePerformance
}
~~~

Example:

~~~text
specification:        approved-formal
logicalProof:         kernel-checked
compilerErasure:      translation-validated
backendPreservation:  differential-only
boundaryModel:        assumed+monitored
provenance:           reproducible+signed
resourcePerformance:  benchmarked
~~~

This is more informative than:

~~~text
verified = true
~~~

The highest-assurance profile can demand stronger values in every required dimension.

---

# 11. Deep specifications are the unit of ecosystem composition

A scalable verified ecosystem cannot compose by repeatedly unfolding dependency implementations.

It needs behavioral abstraction boundaries.

DeepSpec's criteria are a useful model:

- rich;
- two-sided;
- formal;
- live.

For ProofScript, a package interface should ideally provide:

~~~text
public types
public operations
preconditions
postconditions
effect behavior
laws
resource contracts where useful
refinement relationships
allowed assumptions
checked theorem identities
~~~

Clients prove against this interface.

Implementations prove they satisfy it.

If the implementation changes without changing the deep specification, downstream proof invalidation should be minimized.

This is the mathematical analogue of stable module abstraction.

---

# 12. TheoryManifest replaces handwritten Theory Capsule authority

Version 1's Software Theory Capsule is useful conceptually but dangerous if it can be authored independently and then treated as truth.

SAVEF-v2 changes the rule.

> **A TheoryManifest is a derived, rebuildable index over authoritative artifacts. It is never itself proof authority.**

A TheoryManifest may expose:

~~~text
package identity
semantic profile identity
public definitions
public capabilities
approved specifications
checked theorem identities
effect models
assumption closure
refinement relationships
target availability
artifact/evidence links
complexity/benchmark metadata
~~~

But every formal edge must resolve to actual checked evidence.

If the index is deleted, the authoritative artifacts remain sufficient to rebuild it.

If the index disagrees with them, the index loses.

---

# 13. Typed Ecosystem Knowledge Graph

A single untyped Verified Theory Graph is too ambiguous.

SAVEF-v2 uses a typed graph whose indexes are derived from authoritative artifacts.

## 13.1 Specification subgraph

Nodes:

- requirement;
- formal claim;
- SpecCapsule;
- API/deep specification.

Edges:

~~~text
formalizes
refines
covers
revises
depends-on
~~~

## 13.2 Proof subgraph

Nodes:

- obligation;
- theorem;
- proof;
- checked declaration.

Edges:

~~~text
proves
uses
generalizes
specializes
discharges
~~~

## 13.3 Capability subgraph

Nodes:

- operation;
- package;
- interface;
- effect;
- implementation;
- backend target.

Edges:

~~~text
provides
implements
adapts
refines
compatible-with
replaces
~~~

## 13.4 Assumption subgraph

Nodes:

- logical assumption;
- foreign-runtime assumption;
- environment assumption;
- cryptographic assumption;
- performance assumption.

Edges:

~~~text
assumes
validated-by
monitored-by
expires-with
~~~

## 13.5 Artifact/build subgraph

Nodes:

- source;
- CandidateCore;
- CheckedCore;
- CertifiedSourceModule;
- VerifiedIR;
- target artifact;
- provenance record.

Edges:

~~~text
elaborates-to
admitted-as
erases-to
validates-to
lowers-to
built-from
attested-by
~~~

The graph database/index is not in the logical TCB.

The evidence referenced by graph edges is.

---

# 14. Axiom and assumption accounting

The Version 1 Axiom Budget should be retained but made more precise.

Separate at least:

## 14.1 Logical foundation assumptions

Examples:

- Lean/PSCV logical principles selected by the semantic profile;
- quotients/extensionality consequences;
- explicitly permitted classical principles.

## 14.2 Trusted semantic primitives

Examples:

- designated kernel implementation;
- trusted native reduction capability when enabled.

## 14.3 Compiler/execution assumptions

Examples:

- unproved erasure transformation;
- unproved backend;
- JS engine;
- Wasm engine;
- OS;
- hardware.

## 14.4 Foreign/world assumptions

Examples:

- database transaction behavior;
- filesystem semantics;
- remote API contract;
- network model.

## 14.5 Cryptographic assumptions

Examples:

- collision resistance;
- unforgeability;
- randomness model.

## 14.6 Empirical service/performance claims

Examples:

- latency;
- availability;
- memory budget on a target machine.

Every exported claim should have a computable transitive assumption closure.

The desired ecosystem trend is:

~~~text
capability grows
while
unproved transitive assumption surface grows slowly
or shrinks
~~~

---

# 15. Conservative extension as an ecosystem quality metric

A package is especially valuable when it adds definitions and proved theorems without adding new unproved trust.

Define:

~~~text
ConservativeExtensionRatio
=
accepted ecosystem growth that introduces no new unproved semantic assumptions
/
total accepted ecosystem growth
~~~

This is not a logical theorem about the whole ecosystem unless the relevant conservativity property is itself formalized.

It is an engineering metric for trust growth.

---

# 16. Effects: the bridge between mathematics and real software

A SAVEF that only verifies pure total functions will not become a general software ecosystem.

PSCV's verified-effect architecture is therefore central.

## 16.1 PSCV v1 core

The PSCV design already targets verified semantics for:

- pure/identity computation;
- state;
- reader;
- typed errors.

It does so through weakest-precondition/Hoare-style specifications with checked laws.

This is an appropriate v1 boundary.

## 16.2 Future resource and ownership logic

Resource ownership, mutable heap, aliasing, and low-level memory should not be added as ad-hoc kernel primitives.

Preferred route:

~~~text
PSCV/Lean propositions
    +
library-encoded resource algebra / separation logic
    +
proof-producing automation
~~~

Iris is strong precedent for building sophisticated concurrency/resource reasoning as a reusable logical framework.

A Lean port of Iris exists, strengthening the feasibility of a Lean-grounded research path.

## 16.3 Concurrency

Concurrency needs explicit semantics for:

- shared state;
- atomicity;
- interference;
- linearizability;
- memory model;
- liveness where required.

Do not label thread-safe code verified merely because its sequential functions are proved.

Candidate future PSCV libraries may use:

- separation logic;
- rely/guarantee reasoning;
- atomic protocols;
- verified schedulers/state machines.

## 16.4 Distributed systems

Aneris and CertiKOS-style layered refinement demonstrate that distributed and systems reasoning can remain compositional when external events are modeled explicitly.

SAVEF should represent:

- message traces;
- failure models;
- network assumptions;
- protocol invariants;
- temporal/liveness properties;
- refinement from abstract protocol to implementation.

These belong in versioned libraries/profiles, not PSKernel.

## 16.5 Raw world effects

Filesystem, network, database, clock, randomness, devices, raw FFI, and human actions are boundary effects unless they are mediated by an accepted formal model.

A verified program using such capabilities is usually conditional:

~~~text
if BoundaryContract holds
then ProgramGuarantee holds
~~~

That conditionality must remain visible in the Assurance Vector.

---

# 17. Compiler correctness is part of the theorem chain

The mathematical analogy fails if source proofs are destroyed by compilation.

## 17.1 Source verification is not artifact verification

A PSCV theorem can establish:

~~~text
SourceProgram satisfies Property P
~~~

That does not imply:

~~~text
GeneratedJavaScript satisfies P
~~~

unless the compilation relation is justified.

## 17.2 Preservation architecture

Every semantic transformation should have one of:

1. a machine-checked semantic-preservation theorem;
2. proof-producing transformation evidence;
3. translation validation checked by a smaller trusted validator;
4. an explicitly lower assurance classification.

The architecture should prefer different methods by pass.

## 17.3 BackendPreservationContract

Each backend should expose a versioned contract conceptually containing:

~~~text
source IR semantics identity
target semantics identity
supported feature closure
observable behavior relation
validation/proof mechanism
resource/exhaustion behavior
unsupported-case behavior
evidence format/version
~~~

A backend that encounters unsupported semantics must reject.

It must not silently lower to a weaker behavior.

## 17.4 Direct Wasm and JS

Direct Wasm is an attractive high-assurance target because the target language is relatively compact and has formal semantics and independent validators.

Direct JS remains valuable for ecosystem reach but should deliberately emit a small, canonical subset to keep preservation reasoning tractable.

TypeScript/Rust adapters remain useful but carry additional external-compiler assumptions unless their path is independently validated.

---

# 18. Erasure is a semantic transformation, not a cleanup pass

PSCV uses SPEC / PROOF / EXEC relevance and erases proofs/ghost state.

This requires a theorem or accepted validation relation equivalent in purpose to:

> Removing SPEC/PROOF material cannot change the defined observable EXEC behavior.

This includes:

- return values;
- control flow;
- externally observable effect order;
- effect parameters;
- required resource semantics;
- foreign calls;
- public error behavior.

If proof or ghost state influences runtime behavior, the module cannot enter the verified executable state.

SAVEF-v2 therefore treats erasure as a major semantic preservation boundary.

---

# 19. AI architecture: search over semantics, not files

AI should surround the semantic pipeline rather than enter its trusted core.

## 19.1 Compiler service

All tools should use one compiler semantic service.

Candidate operations:

~~~text
parse
elaborate
typeOf
goalState
candidateCore
admissionPayload
checkedCore
obligations
specCoverage
assumptionClosure
verifiedIr
semanticDiff
dependencySlice
affectedProofs
capabilitySearch
buildPlan
~~~

LSP, IDE, AI agents, package tools, and factory orchestration should not reimplement language semantics independently.

## 19.2 Context slicing

Current verified-code-generation research shows repository-scale success degrades with large dependency closures, while curated dependency context performs better than dumping a full repository into the model context.

Therefore ProofScript should provide:

~~~text
goal
    ->
exact dependency slice
    ->
relevant theorem interface
    ->
relevant assumptions/effects
    ->
candidate proof/implementation
~~~

This is more important than ever-larger model context windows.

## 19.3 Joint program-and-proof planning

The factory should plan implementation and proof together.

Optimization objective:

~~~text
semantic correctness
+ proof simplicity
+ abstraction stability
+ performance
+ interoperability
+ future reuse
~~~

An implementation that is technically correct but extremely difficult to prove or compose may be inferior to a slightly different algorithm with a much simpler invariant.

---

# 20. Specification integrity is the first authority boundary

A theorem proves the formal statement it actually receives.

It does not prove that the statement accurately represents the original human intention.

Therefore:

~~~text
requirement authoring
    !=
specification approval
    !=
implementation
    !=
proof generation
    !=
proof checking
~~~

## 20.1 Frozen specification identity

Implementation agents may propose changes to the specification.

They may not silently mutate an approved SpecCapsule while retaining its identity.

Any weakening creates a new specification revision.

## 20.2 Specification challenge

Before approval, tooling should attempt:

- ambiguity detection;
- contradiction detection;
- missing-case generation;
- counterexample search;
- mutation testing of formal claims;
- comparison with prose/examples;
- requirement-coverage analysis;
- independent reviewer/agent critique.

These increase confidence in specification fidelity.

They do not mathematically prove human intent.

## 20.3 Reward-hacking resistance

Agent environments must prevent candidate workers from:

- modifying acceptance policy;
- modifying hidden evaluation data;
- disabling verification;
- rewriting evidence requirements;
- changing benchmark targets;
- altering the meaning of success.

The release/evaluation environment should reconstruct the candidate from immutable inputs and replay checks independently.

---

# 21. AI generation freedom, acceptance rigidity

The preferred SAVEF asymmetry is:

~~~text
generation:
    broad, experimental, replaceable

acceptance:
    narrow, deterministic, versioned, fail-closed
~~~

AI may:

- write code;
- write proofs;
- propose specifications;
- generate tests;
- generate adapters;
- search theorems;
- propose tactics;
- propose compiler transformations;
- propose factory improvements.

AI may not:

- construct CheckedCore directly;
- mint a proof certificate without checking;
- bypass the PSCV compile gate;
- reinterpret an unsupported case;
- silently broaden assumptions;
- decide that its own benchmark exploit counts as success.

---

# 22. Factory outputs must increase reusable knowledge

A completed task should ideally produce two products.

## Product A — requested capability

Examples:

- package;
- library;
- backend feature;
- adapter;
- application component.

## Product B — reusable production knowledge

Examples:

- deep specification;
- theorem;
- proof lemma;
- domain invariant;
- effect law;
- proof tactic;
- implementation pattern;
- counterexample;
- rejected strategy;
- semantic adapter;
- benchmark characterization.

The factory is self-amplifying only if Product B measurably helps future tasks.

---

# 23. Failure memory

Failed proof and compiler attempts should be recorded in structured form outside the logical TCB.

Example:

~~~text
FailureKnowledge {
    semanticProfile
    obligationShape
    dependencySlice
    attemptedStrategy
    checkerOutcome
    counterexample
    failureClass
    successfulReplacementStrategy
}
~~~

Before reuse, a failure pattern should be matched against semantic identity.

A strategy learned under a different Lean/PSCV profile cannot be assumed valid.

---

# 24. Generalization loop

If multiple accepted developments prove structurally similar facts, an untrusted generalizer may propose:

- a more general lemma;
- a reusable abstraction;
- a tactic;
- a library;
- a capability interface.

The generalized result only enters the accepted knowledge base after ordinary verification.

This prevents the knowledge graph from becoming a repository of AI folklore.

---

# 25. Three compounding loops

## 25.1 Production loop

~~~text
specification
 -> candidate program/proof
 -> checking
 -> preserved artifact
~~~

Goal:

> reduce the cost of one correct task.

## 25.2 Ecosystem loop

~~~text
accepted artifact
 -> extract verified interfaces/theorems/patterns
 -> index them
 -> reuse on later tasks
~~~

Goal:

> reduce future task cost through accumulated knowledge.

## 25.3 Factory-improvement loop

~~~text
factory traces
 -> identify bottleneck
 -> propose new tactic/retriever/agent/tool
 -> evaluate under frozen policy
 -> accept only if better
~~~

Goal:

> improve the production mechanism without letting it grade itself.

---

# 26. Factory self-improvement policy

Self-improvement is useful only if the measurement is resistant to contamination.

A valid experiment should pin:

- model identity/version;
- model inference settings;
- tool protocol version;
- benchmark distribution;
- holdout tasks;
- semantic profile;
- verification policy;
- compute budget;
- allowed external knowledge;
- measurement code.

Then compare factory versions.

The factory does not demonstrate self-amplification merely because a newer frontier model performs better.

The key experiment is:

~~~text
same model
same task distribution
similar compute budget
larger accepted ProofScript knowledge base

=>

higher solve rate
lower human time
lower token cost
fewer repair iterations
higher reuse
~~~

---

# 27. Progressive foreign-ecosystem assimilation

ProofScript should not rebuild mature ecosystems manually.

It should ingest them with explicit assurance levels.

Example:

~~~text
npm package
    |
    v
external capability
    |
    v
generated typed InterfaceIR
    |
    v
conformance characterization
    |
    v
explicit boundary contract
    |
    v
validated adapter
    |
    v
native ProofScript replacement where economically justified
    |
    v
verified replacement
~~~

Never relabel an external implementation as proved merely because its wrapper is typed.

---

# 28. Recommended assurance levels for capabilities

| Level | Meaning |
| --- | --- |
| External | imported behavior, explicit trust boundary |
| Typed | interface/types checked |
| Characterized | tests/differential behavior recorded |
| Contracted | explicit behavioral specification |
| Validated | independent validator/model evidence |
| Kernel-Verified | relevant formal claim checked by PSKernel |
| Artifact-Preserved | backend relation to checked source established |
| Boundary-Assured | external assumptions additionally monitored/validated under policy |

A package may expose different levels for different claims.

---

# 29. Bootstrap integrity is not semantic soundness

The current self-host fixed point is valuable evidence that the compiler can reproduce itself under its implementation profile.

It does not prove compiler correctness.

SAVEF must track separate evidence:

~~~text
bootstrap fixed point
reproducible build
diverse double compilation
source-level compiler proof
backend semantic preservation
kernel soundness
~~~

These are complementary.

The current PSC1 self-host profile remains useful as a restricted implementation discipline. It should not be confused with PSCV source semantics.

---

# 30. Resource behavior and denial-of-service

Logical soundness is not sufficient for a usable factory.

Adversarial source or proof terms can target:

- parser depth;
- elaboration;
- reduction;
- defeq;
- instance search;
- kernel recursion;
- erasure;
- specialization;
- IR growth;
- backend code size.

The existing Production Architecture already proposes an explicit CompilationBudget.

SAVEF-v2 adopts it.

Resource exhaustion must be distinguishable from:

- invalid source;
- unsupported semantics;
- internal error;
- accepted proof.

A timeout must never become acceptance.

---

# 31. Performance evidence belongs in the theory boundary, not disguised as proof

There are at least three kinds of performance claim.

## 31.1 Formal complexity

Example:

~~~text
operation performs O(log n) abstract steps
~~~

This may be formally proved under a cost semantics.

## 31.2 Resource model claim

Example:

~~~text
allocation count <= f(n)
~~~

This can sometimes be proved relative to a formal runtime model.

## 31.3 Concrete deployment performance

Example:

~~~text
p99 latency under 20 ms on host H
~~~

This is normally benchmark evidence.

SAVEF should retain all three without conflating them.

---

# 32. Recommended repository architecture

The strongest recommendation is **evolutionary**, not a large rename.

Keep the current semantic packages and add explicit authority packages around them.

## 32.1 Existing semantic spine to preserve

~~~text
psc15selfhost/packages/

foundation/
syntax/
core/
environment/
meta/
elab/
bridge/
compiler/
erasure/
compiler-ir/

pskernel-core/
pskernel-lean-wasm/
pskernel-lean/

backend-js/
backend-wasm/
backend-ts/
backend-rust/

project/
bootstrap/
cli/
~~~

## 32.2 Target foundational additions

~~~text
kernel-contract/
checked-core/
pscv-spec/
pscv-obligation/
pscv-cert/
runtime-ir/
verified-ir/
~~~

Responsibilities:

### kernel-contract

Provider-neutral checked-session protocol and identities.

### checked-core

Opaque checked-module/source-certificate handles and hashes.

No frontend convenience.

### pscv-spec

Canonical formal specification identity and coverage metadata.

### pscv-obligation

Canonical PSCV-VERIFY-v1 obligation representation and dependency links.

### pscv-cert

PSCV-CERT-v1 policy checker:

- proof closure;
- spec coverage;
- effect closure;
- assumption policy;
- semantic profile binding.

### runtime-ir

Raw post-erasure construction state.

May represent temporary unresolved construction forms if explicitly typed as such.

### verified-ir

Only validated executable IR.

No target representation policy.

## 32.3 Platform additions

~~~text
interface-ir/
capability-contract/
evidence-core/
theory-manifest/
package-manifest/
compiler-service/
diagnostics/
plugin-contract/
build-graph/
artifact-codec/
artifact-store/
~~~

### evidence-core

Typed references to:

- proof evidence;
- validator evidence;
- assumptions;
- empirical evidence;
- provenance.

It does not re-check Lean proofs itself.

### theory-manifest

Derived package behavioral/theorem/capability index.

Never proof authority.

### compiler-service

Single semantic API for:

- CLI;
- LSP;
- IDE;
- AI;
- build system;
- package tooling.

## 32.4 Factory/AI packages — outside semantic/bootstrap TCB

~~~text
agent-protocol/
theory-index/
factory-orchestrator/
factory-memory/
factory-generalizer/
factory-bench/
model-router/
~~~

These packages may be large and experimental.

They are not imported by:

- core;
- PSKernel;
- CheckedCore;
- erasure;
- VerifiedIR authority.

## 32.5 Host packages

~~~text
host-node/
host-native/
host-wasm/
registry-client/
release-tools/
factory-worker/
~~~

Network, filesystem, process execution, model invocation, package registry, signing, and remote caches remain host/platform concerns.

---

# 33. Dependency law

The target dependency direction should resemble:

~~~text
AI / IDE / CLI / package tools
            |
            v
      compiler-service
            |
            v
spec / obligations / frontend
            |
            v
       CandidateCore
            |
            v
      kernel-contract
            |
            v
        CheckedCore
            |
            v
        pscv-cert
            |
            v
          erasure
            |
            v
        runtime-ir
            |
            v
        verified-ir
       /     |      \
      v      v       v
 backend   backend  adapter
   JS       Wasm   TS/Rust
      \      |       /
       preservation evidence
              |
              v
        evidence-core
              |
              v
       theory-manifest
              |
              v
         theory-index
~~~

Forbidden authority reversals:

~~~text
backend -> frontend semantic mutation
agent -> CheckedCore construction
theory-index -> proof authority
plugin -> kernel bypass
package registry -> semantic truth
test pass -> theorem
fixed point -> soundness
receipt -> proof certificate
~~~

---

# 34. QueryGraph evolution

Extend the existing QueryGraph rather than replacing it.

A future query system should invalidate based on semantic interface changes, not merely source timestamps.

Potential keys:

~~~text
sourceKey
syntaxKey
elaboratedInterfaceKey
specKey
obligationKey
checkedCoreKey
theoremInterfaceKey
assumptionKey
runtimeIrKey
verifiedIrKey
backendKey[target]
artifactKey[target]
~~~

If implementation internals change while exported theorem/spec interfaces remain equivalent, downstream proof work should remain green where justified.

This is one of the highest-leverage mechanisms for making a verified ecosystem economically scalable.

---

# 35. Proof interface stability

For every public package, distinguish:

~~~text
implementation dependencies
    from
proof-interface dependencies
~~~

Clients should normally depend on:

- exported types;
- deep specifications;
- exported theorem identities;
- effect contracts;
- explicit assumptions.

They should not depend on:

- private implementation lemmas;
- proof search trace;
- internal normalization choices;
- private representation.

Proof interface stability should become a release metric.

---

# 36. Versioning model

At least four compatibility relations matter.

## 36.1 Source compatibility

Can existing source still elaborate?

## 36.2 Type/API compatibility

Do existing clients still typecheck?

## 36.3 Behavioral/specification compatibility

Does the new implementation refine or preserve the old public specification?

## 36.4 Evidence compatibility

Can existing checked proof/certificate identities be reused under the new semantic profile?

A major source version bump is not a substitute for formalizing these distinctions.

---

# 37. AI model strategy

The semantic architecture should be model-agnostic.

A future router may choose:

~~~text
deterministic automation
    before
small local specialized model
    before
larger open model
    before
expensive frontier model
~~~

The correct routing objective is not lowest token price.

It is:

~~~text
expected accepted capability
per unit of human + compute cost
~~~

Specialized proof, repair, specification, and interoperability models may eventually be trained on ProofScript's verified corpus.

That is a later optimization.

It is not a prerequisite for SAVEF.

---

# 38. Verified corpus as training material

A mature ProofScript ecosystem can produce unusually rich trajectories:

~~~text
requirement
specification
candidate program
obligations
proof attempts
kernel rejection/acceptance
counterexamples
semantic dependencies
repairs
final checked artifact
performance evidence
~~~

These traces can support:

- retrieval;
- fine-tuning;
- reinforcement from deterministic checker outcomes;
- tactic induction;
- proof strategy prediction;
- semantic change prediction.

Privacy/licensing/provenance rules must remain explicit when using ecosystem code as training data.

---

# 39. Independent evidence architecture

SAVEF-v2 recommends three escalating modes.

## 39.1 Single-authority checked

One designated kernel provider checks all proof-relevant declarations.

Suitable for ordinary verified development.

## 39.2 Dual independent replay

A second independently implemented checker replays the environment.

Suitable for release-critical libraries and compiler/kernel components.

## 39.3 Diverse end-to-end validation

Combine:

- independent proof checking;
- backend validation/differential execution;
- reproducible build;
- diverse compiler/bootstrap evidence where practical.

Suitable for the highest assurance tier.

Independent evidence should differ in implementation enough to reduce correlated bugs.

---

# 40. Current proof branches and how they should converge

## 40.1 pscv/prove-pskernel-core-v1

This branch is valuable because it begins separating:

~~~text
implementation
    from
independent metatheory
    from
refinement theorems
~~~

That is the right long-term direction.

Do not count proof-file presence as semantic completeness.

Continue upgrading C/D modules toward B/A evidence and then compose public KernelContract correctness theorems.

## 40.2 pscv/selfhost-poc-v1

The current compiler proof experiments correctly state their limitations:

- frontend wrappers prove orchestration/error propagation, not parser/elaborator correctness;
- preparation proofs preserve AdmissionReady honesty;
- lowering wrapper proofs do not prove erasure preservation or validator soundness.

This honesty should become permanent proof-audit policy.

Every proof module should state what semantic claim it does **not** establish.

## 40.3 psc2/pscv-direct-backends

This branch is strategically important because direct JS/Wasm lowers dependency on TS/Rust adapter semantics.

For SAVEF, direct backends should evolve toward explicit BackendPreservationContract evidence.

---

# 41. Formalization coverage map

Before adding many new PSCV features, maintain a matrix like this.

| Domain | PSCV v1 status | Preferred formalization owner | Empirical boundary |
| --- | --- | --- | --- |
| pure algorithms | strong | core types/theorems | none/minimal |
| ADTs/data invariants | strong | dependent/refinement types | none/minimal |
| state | planned strong | verified WP/effect library | host storage model if external |
| typed errors | planned strong | verified effect library | external error sources |
| reader/environment | planned strong | verified effect library | host values |
| local mutation/loops | PSCV design | VC generation + invariants | none if closed |
| heap/aliasing | future | separation/resource logic library | allocator/runtime |
| resources | future | capability/resource logic | OS handles |
| async/tasks | future | verified effect/state-machine library | scheduler/runtime |
| concurrency | future | separation logic + memory model | hardware/runtime |
| distributed protocols | future | temporal/state/refinement libraries | network/failure model |
| filesystem | boundary/future | abstract state + refinement | OS/filesystem |
| database | boundary/future | transaction model | DB server |
| networking | boundary/future | protocol model | network stack/world |
| randomness | boundary/model | probabilistic semantics | entropy source |
| cryptography | mixed | functional proof + crypto assumptions | hardness/implementation |
| FFI | boundary | InterfaceIR + contract | foreign implementation |
| compiler | active | refinement/translation validation | toolchain/runtime |
| performance | mixed | cost semantics + benchmark | hardware/workload |
| UI/human factors | empirical | requirement model only | users |

This table should be versioned and tied to actual libraries.

---

# 42. FactoryBench-v2

The original metrics remain useful, with several additions.

## 42.1 Production metrics

- accepted capability throughput;
- human minutes per accepted capability;
- compute cost per accepted capability;
- verification repair iterations;
- proof closure rate;
- specification coverage rate;
- backend preservation coverage.

## 42.2 Reuse metrics

- theorem reuse ratio;
- deep-spec reuse ratio;
- capability reuse ratio;
- proportion of new tasks requiring new low-level implementation;
- semantic context tokens per accepted task.

## 42.3 Maintenance metrics

- proof invalidation fanout;
- proof repair time;
- interface stability;
- semantic-cache hit ratio;
- amount of downstream work avoided by stable deep specifications.

## 42.4 Trust metrics

- transitive assumption footprint;
- conservative-extension ratio;
- unvalidated boundary count;
- independent-checker coverage;
- backend preservation level;
- reward-hacking escape rate.

## 42.5 Amplification metrics

Compare factory version N and N+1 while pinning model and task distribution:

- success-rate delta;
- human-time delta;
- compute-cost delta;
- reuse delta;
- low-level-code delta;
- proof-repair delta.

The factory is not self-amplifying merely because package count increases.

---

# 43. Acceptance policy for ecosystem knowledge

A capability may enter the trusted/reusable index only if:

1. semantic identity is known;
2. its specification identity is known;
3. its evidence class is known;
4. transitive assumptions are known;
5. relevant checker/validator results are available;
6. unsupported cases did not fall back;
7. resource exhaustion was not misclassified as acceptance;
8. provenance can identify the exact artifact;
9. the claim exported to clients does not exceed the evidence.

A lower-assurance capability may still enter the ecosystem.

It must be labeled accurately.

---

# 44. Security consequences of the mathematical model

The mathematical accumulation idea can make AI generation safer only when the acceptance layer is adversarially designed.

Security principles:

- immutable approved specifications;
- checker inputs reconstructed independently;
- no agent-controlled verifier configuration in release mode;
- no ambient plugin authority;
- content-addressed evidence;
- provider identity binding;
- explicit compilation budgets;
- no semantic fallback;
- independent replay for high assurance;
- capability-scoped host access;
- exact artifact/proof provenance.

The stronger the AI becomes, the more important these constraints become.

---

# 45. Why SAVEF should not become a giant theorem-proving monolith

A monolithic design would fail economically.

Avoid:

~~~text
PSCV core contains all software logics
PSKernel understands all domain effects
every package requires enormous bespoke proof
every change triggers global re-verification
AI receives the entire repository
~~~

Prefer:

~~~text
small semantic core
deep module specifications
library-encoded program logics
incremental dependency slices
proof-producing automation
stable theorem interfaces
specialized validators
explicit boundary assumptions
~~~

This mirrors both good programming-language architecture and good mathematics.

---

# 46. Recommended implementation order

This order deliberately postpones flashy AI/factory features until authority seams are real.

## Phase 0 — semantic identity cleanup

- adopt SemanticProfileIdentity;
- distinguish Lean 4.34 implementation evidence from Lean 4.35-RC3 PSCV evidence;
- pin Standard environment and runtime semantics;
- remove ambiguous checked/verified naming.

Exit gate:

> no artifact can be mistaken for a stronger semantic state than it actually has.

## Phase 1 — real CheckedCore integration

Implement:

~~~text
AdmissionReadyModule
    -> designated kernel provider
    -> opaque CheckedModule / CheckedCore
~~~

Then require erasure on the production PSCV path to accept only checked artifacts.

Exit gate:

> no executable PSCV path can bypass kernel admission.

## Phase 2 — PSCV obligation and certificate pipeline

Implement:

- canonical PSCV-VERIFY-v1 obligations;
- proof closure;
- specification coverage;
- effect closure;
- assumption policy;
- PSCV-CERT-v1 source certification.

Exit gate:

> a proof-open source module cannot be emitted as a PSCV verified executable.

## Phase 3 — physical RuntimeIR / VerifiedIR separation

Rename/split raw construction forms and validator-owned accepted forms.

Prove or validate:

- no unresolved runtime types;
- symbol closure;
- type/arity consistency;
- match validity;
- intrinsic validity;
- runtime representation support.

Exit gate:

> backend core packages accept only validated IR.

## Phase 4 — erasure and backend preservation

Prioritize:

- erasure preservation;
- direct Wasm;
- direct JS canonical subset;
- target translation validators or proofs.

Exit gate:

> high-assurance artifact status requires explicit preservation evidence.

## Phase 5 — compiler service and incremental semantic graph

Expose:

- obligations;
- goal states;
- theorem interfaces;
- semantic diffs;
- dependency slices;
- affected proofs;
- assumption closure.

Extend QueryGraph with semantic keys.

Exit gate:

> tooling and AI do not need to reconstruct dependency semantics from text.

## Phase 6 — TheoryManifest and typed ecosystem graph

Generate manifests from authoritative artifacts.

Build a rebuildable index.

Exit gate:

> capability search can answer behavioral/evidence queries without becoming proof authority.

## Phase 7 — progressive ecosystem ingestion

Build InterfaceIR and assurance lanes for JS/TS/npm first.

Exit gate:

> foreign packages can be used honestly without pretending they are formally verified.

## Phase 8 — AI factory workers

Add:

- planner;
- implementation worker;
- proof worker;
- specification critic;
- interoperability worker;
- repair worker.

All communicate through AgentProtocol and compiler service.

Exit gate:

> agent replacement does not alter semantic authority.

## Phase 9 — knowledge extraction/generalization

Store:

- successful proofs;
- failed strategies;
- counterexamples;
- reusable patterns.

Propose generalized theorems/tactics and verify them normally.

## Phase 10 — controlled factory self-improvement

Use FactoryBench with pinned models and frozen holdouts.

Accept only replayably demonstrated improvements.

---

# 47. Research questions that remain genuinely open

A 9.66 architecture score does not mean the following are solved.

1. How much real software can be economically moved from boundary assumptions into formal PSCV effect models?
2. Can proof maintenance remain cheap at million-line repository scale?
3. Which compiler passes should be fully proved versus translation-validated?
4. What minimal JS subset gives enough ecosystem compatibility while remaining formally tractable?
5. How should concurrency/resource logics be packaged ergonomically for ordinary PSCV users?
6. How much specification authoring can AI automate before specification-review cost becomes the new bottleneck?
7. Can semantic theorem retrieval outperform source retrieval enough to materially reduce inference cost?
8. Can ecosystem knowledge growth measurably improve agents with model weights held fixed?
9. How much verified knowledge can transfer across semantic-profile upgrades?
10. Can the full compiler/kernel bootstrap chain be independently reconstructed with a sufficiently small trusted seed?
11. What is the right public compatibility theorem for package upgrades?
12. What assurance profile is economically attractive for mainstream web/application development?

These are research tasks, not reasons to weaken the architecture.

---

# 48. Final architecture score

## 48.1 Criterion table

| Criterion | V1 | Iteration A | SAVEF-v2 |
| --- | ---: | ---: | ---: |
| Epistemic thesis precision | 9.1 | 9.5 | 9.7 |
| Lean/type-theory fidelity | 7.3 | 9.2 | 9.5 |
| PSCV semantic integration | 6.8 | 9.3 | 9.7 |
| Trust/TCB architecture | 8.2 | 9.4 | 9.7 |
| Typed semantic/evidence states | 7.0 | 9.5 | 9.8 |
| Deep specifications/composition | 8.6 | 9.4 | 9.6 |
| Effects/world/concurrency | 7.8 | 9.2 | 9.5 |
| Compiler/artifact preservation | 7.3 | 9.3 | 9.6 |
| Assumption/evidence modeling | 8.8 | 9.5 | 9.7 |
| Incremental/query architecture | 7.0 | 9.4 | 9.7 |
| AI semantic interface | 8.5 | 9.5 | 9.7 |
| Specification/reward-hacking resistance | 8.4 | 9.5 | 9.8 |
| Ecosystem knowledge graph | 8.5 | 9.4 | 9.7 |
| Self-amplification measurement | 8.8 | 9.6 | 9.8 |
| Interop/progressive assurance | 8.4 | 9.3 | 9.6 |
| Bootstrap/provenance | 7.8 | 9.2 | 9.5 |
| Performance/resource behavior | 7.4 | 9.2 | 9.5 |
| Repository implementability | 6.9 | 9.5 | 9.7 |
| Independent evidence/metatheory | 7.8 | 9.4 | 9.7 |
| Longevity/versioning | 7.5 | 9.4 | 9.6 |

Weighted result:

~~~text
Original SAVEF:    7.88 / 10
Iteration A:       9.39 / 10
SAVEF-v2:          9.66 / 10
~~~

SAVEF-v2 clears the 9.5 target without scoring implementation work that does not exist.

## 48.2 Current implementation/evidence estimate

Current repository evidence should be described separately.

Approximate whole-vision maturity:

~~~text
compiler semantic decomposition:       strong
self-host/bootstrap discipline:        strong
kernel provider architecture:          strong
portable kernel implementation:        substantial
kernel metatheory/refinement:          active/incomplete
PSCV verified language profile:         advanced design, implementation incomplete
PSCV certification pipeline:            partial/design
erasure preservation proof:             incomplete
backend preservation proof/validation:  incomplete
typed theory/capability graph:           design
agent semantic ABI:                     design
factory orchestration:                  mostly future
self-amplification empirical evidence:   not yet demonstrated
~~~

Overall SAVEF-v2 implementation/evidence maturity:

**approximately 5.4 / 10**

This number should rise only when repository evidence closes the corresponding gates.

---

# 49. Canonical SAVEF-v2 definition

> **ProofScript's Self-Amplifying Verified Ecosystem Factory is a verification-grounded software-production architecture in which software capabilities accumulate as executable formal knowledge: definitions, deep specifications, implementations, proofs, refinements, effect models, explicit assumptions, and preservation evidence.**
>
> **PSCV defines the verified-programming and certification semantics; PSKernel decides logical admission; compiler and backend evidence justify the transition from checked source to executable artifacts; external assumptions and empirical evidence remain explicit at the boundary to the real world.**
>
> **AI and other automation may search, synthesize, formalize, prove, repair, integrate, and generalize, but they do not possess acceptance authority.**
>
> **Accepted ecosystem knowledge is indexed in a typed, rebuildable graph derived from authoritative artifacts so that later development can reuse not only code, but specifications, theorems, proof strategies, refinement relationships, effect laws, and validated capability interfaces.**
>
> **The system is self-amplifying only when this accumulated accepted knowledge measurably lowers the marginal human or compute cost, or increases the success rate, of producing comparable future capabilities while model capability and evaluation policy are held approximately fixed.**

Short form:

> **Build software as accumulating formal knowledge: prove and compose what can be formalized, validate the world boundary explicitly, and make every accepted result reduce the cost of the next one.**

---

# 50. Architectural laws

These are the most important anti-drift rules.

1. **AdmissionReady is not CheckedCore.**
2. **CheckedCore is not PSCV source certification.**
3. **Source certification is not backend preservation.**
4. **Backend preservation is not world-assumption validation.**
5. **A kernel receipt is not automatically a proof certificate.**
6. **A fixed point is not compiler correctness.**
7. **A passing test is not a theorem.**
8. **A theorem proves the formal claim, not the original human intention.**
9. **AI may propose; deterministic authorities decide.**
10. **The theory/capability index is rebuildable and non-authoritative.**
11. **All authoritative artifacts bind to an exact SemanticProfileIdentity.**
12. **Unsupported semantics reject; they never silently fall back.**
13. **Resource exhaustion never becomes acceptance.**
14. **Proof and ghost erasure requires noninterference.**
15. **Every strong exported claim has an inspectable transitive assumption closure.**
16. **Deep specifications, not implementation internals, are the normal proof-composition boundary.**
17. **Factory self-improvement cannot edit its own acceptance criteria.**
18. **High-assurance releases should support independent replay/checker diversity.**
19. **The semantic/bootstrap core remains small; factory/AI systems remain outside it.**
20. **Architecture scores never count planned components as implemented evidence.**

---

# 51. Immediate next work

The next highest-value research/implementation documents should be produced in this order.

## 51.1 PSCV Software Mathematics Coverage Map

For every important software domain:

- semantic model;
- required program logic;
- PSCV language support;
- library support;
- proof automation;
- external assumptions;
- empirical validation;
- target/backend implications;
- AI retrieval representation.

## 51.2 PSCV Semantic Artifact State Reference

Precisely define:

~~~text
CandidateCore
AdmissionReady
CheckedCore
CertifiedSourceModule
RuntimeIR
VerifiedIR
PreservedTargetArtifact
ReleaseEvidenceEnvelope
~~~

including constructors, authority, identity, invalidation, and allowed consumers.

## 51.3 PSCV Agent Protocol / Compiler Service Reference

Define model-neutral semantic queries and structured diagnostics.

## 51.4 TheoryManifest / Typed Ecosystem Knowledge Graph schema

Define a rebuildable graph over actual evidence.

## 51.5 FactoryBench-v2

Create benchmark families covering:

- package creation;
- proof generation;
- package upgrades;
- interop;
- repair;
- proof maintenance;
- semantic reuse;
- specification defects;
- malicious/reward-hacking agent behavior.

These documents should be completed before treating the SAVEF concept as an implementation roadmap for autonomous ecosystem generation.

---

# 52. Research basis

The architecture draws on the following systems and current evidence.

## Lean 4

Lean Language Reference, current release reference:
https://lean-lang.org/doc/reference/latest/

Elaboration and compilation:
https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/

Lean 4.34.0 kernel hardening:
https://lean-lang.org/doc/reference/latest/releases/v4.34.0/

Lean 4.35.0-rc3 verification developments:
https://lean-lang.org/doc/reference/latest/releases/v4.35.0/

Key lessons:

- small kernel with rich untrusted elaboration;
- explicit proof terms enable independent checking;
- actual Lean metatheory must be modeled faithfully;
- checker implementation details and runtime can affect soundness;
- intrinsic verification tooling demonstrates increasing convergence of programming and proof.

## DeepSpec / CertiKOS

https://deepspec.org/page/About/
https://deepspec.org/page/Research/_
https://flint.cs.yale.edu/certikos/framework.html

Key lessons:

- specifications should be rich, two-sided, formal, and live;
- large systems can compose through certified abstraction/refinement layers.

## CompCert

https://compcert.org/man/manual001.html
https://compcert.org/doc/

Key lesson:

- source-level claims become artifact-level claims only through compiler semantic preservation, composed pass by pass.

## CakeML

https://cakeml.org/

Key lessons:

- language semantics, verified compilation, bootstrap, and program verification can coexist;
- bootstrapping and compiler correctness are separate but composable evidence.

## F*

https://fstar-lang.org/

Key lesson:

- refinement types and user-defined effect specifications can generate weakest-precondition obligations for practical effectful programs.

## Iris / Aneris

https://iris-project.org/
https://iris-project.org/aneris/
https://github.com/leanprover-community/iris-lean

Key lessons:

- sophisticated resource/concurrency/distributed reasoning can be built as reusable program-logics rather than kernel primitives;
- Lean-grounded reuse is increasingly plausible.

## AlgoVeri

https://proceedings.mlr.press/v306/zhao26bm.html

Key lesson:

- verified-code-generation difficulty depends strongly on verification-language abstraction and automation, not only foundation-model intelligence.

## VeriSoftBench

https://arxiv.org/abs/2602.18307

Key lesson:

- repository dependency closure strongly affects proof success;
- curated semantic context is better than raw whole-repository context.

## P3

https://arxiv.org/abs/2608.09277

Key lesson:

- program and proof planning should be joint rather than sequential.

## Vero

https://arxiv.org/abs/2608.13522

Key lesson:

- coherent repository-scale code-and-proof synthesis remains unsolved even for strong agents.

## SUSVIBES

https://proceedings.mlr.press/v306/zhao26ax.html

Key lesson:

- functional success is not a reliable proxy for secure implementation.

## Reward Hacking Benchmark

https://proceedings.mlr.press/v306/thaman26a.html

Key lesson:

- autonomous tool-using agents can optimize evaluation shortcuts;
- the acceptance environment must be hardened and independently controlled.

---

# Final research position

The original SAVEF idea was directionally correct but too easy to read as a new AI/theory layer sitting above ProofScript.

The stronger architecture is the opposite:

> **SAVEF should be a disciplined composition of ProofScript's existing semantic boundaries.**

PSCV owns what counts as verified source.

PSKernel owns proof admission.

CheckedCore is distinct from preparation.

Erasure has a preservation obligation.

VerifiedIR is distinct from construction IR.

Backends have preservation contracts.

Boundary assumptions remain explicit.

The project query graph becomes the incremental semantic dependency engine.

Theory/capability manifests are derived indexes over checked artifacts.

AI operates through a semantic service and has no acceptance authority.

Only after these pieces are aligned should ProofScript automate ecosystem production at scale.

If this architecture is implemented successfully, the distinctive advantage is not merely that ProofScript can prove programs.

It is that:

> **every accepted package can increase the amount of reusable machine-checkable software knowledge available to humans and AI, making later correct software cheaper to construct than it would be in an ecosystem where most behavioral knowledge remains implicit.**

That is the precise technical meaning of a Self-Amplifying Verified Ecosystem Factory.
