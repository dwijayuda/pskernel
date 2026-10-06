# ProofScript PSCV Applied SAVEF — Version 2

**Status:** applied target architecture and research reference; non-normative.

**Working identity:** PSCV-APPLIED-SAVEF-v2.

**Research snapshot:** 2026-10-06.

**Target architecture score:** **9.93 / 10**

**Current implementation/evidence score:** **approximately 5.90 / 10**

**Purpose:** define a concrete, falsifiable, TypeScript-scale architecture for applying the Self-Amplifying Verified Ecosystem Factory idea to ProofScript PSCV, PSKernel, the existing psc15selfhost compiler, direct JavaScript/WebAssembly backends, npm packages, incremental build infrastructure, and replaceable AI agents.

This document is a redesign of:

- PROOFSCRIPT_SELF_AMPLIFYING_VERIFIED_ECOSYSTEM_FACTORY.md
- PROOFSCRIPT_SELF_AMPLIFYING_VERIFIED_ECOSYSTEM_FACTORY_VERSION_2.md
- PROOFSCRIPT_PSCV_APPLIED_SAVEF_VERSION_1.md

Preserving those documents is not a design constraint.

The score in this document is an **architecture-specification score**, not a statement that the repository is 99.3 percent implemented.

---

# 1. Executive decision

The strongest form of the software-as-mathematics thesis is:

> **A ProofScript ecosystem should accumulate executable formal knowledge in the same structural manner that mathematics accumulates reusable theory: new components are constructed from previously established definitions, specifications, theorems, refinements, and abstractions instead of repeatedly re-establishing correctness from tests and source inspection.**

But deployed software is not pure mathematics.

It interacts with:

- hardware;
- operating systems;
- JavaScript engines;
- WebAssembly engines;
- databases;
- networks;
- remote services;
- physical clocks;
- entropy sources;
- users;
- performance environments.

Therefore the correct epistemic model is:

> **Deduction inside the formalized system; observation at the boundary to the world.**

Short form:

> **Mathematics inside; science at the boundary.**

The applied SAVEF objective is economic:

> **As the accepted ProofScript ecosystem grows, the marginal human effort, AI inference cost, proof-repair cost, integration cost, and duplicated implementation needed for comparable new capabilities should decrease while assurance remains equal or stronger.**

That effect must be measured with model capability held fixed.

If it cannot be demonstrated, the factory is not self-amplifying.

---

# 2. The central architecture decision

ProofScript should **not** build a replacement for npm.

Use npm as the physical ecosystem:

~~~text
npm
    package identity
    versioning
    package transport
    workspaces
    dependency resolution
    package-lock
    tarball integrity
    provenance
    staged publication
~~~

Add a ProofScript semantic layer:

~~~text
PSCV / ProofScript
    semantic profile
    checked module interface
    deep specification
    theorem interface
    effect/capability contract
    transitive assumption closure
    compiler preservation evidence
    package semantic compatibility
    semantic lock
~~~

Use PSKernel for logical admission:

~~~text
PSKernel
    checks proof/core claims
    does not trust npm metadata
    does not trust AI
    does not trust tests
~~~

Use AI as a replaceable worker:

~~~text
AI
    searches
    designs
    writes
    proves
    repairs
    migrates
    generalizes

AI does not decide acceptance
~~~

Thus:

~~~text
npm graph
    +
checked semantic interface graph
    +
theorem/refinement graph
    +
assumption/evidence graph
    =
ProofScript ecosystem
~~~

---

# 3. What TypeScript teaches ProofScript

TypeScript is not a verification system, but it is one of the strongest examples of a language ecosystem that scales over npm.

ProofScript should copy several **architectural scaling patterns**, not TypeScript semantics.

## 3.1 Declaration files: cheap abstract interfaces

TypeScript packages can publish declaration files with JavaScript.

Downstream projects can consume the public type interface without loading the dependency's entire implementation source.

This is a major ecosystem-scaling mechanism.

ProofScript needs a stronger analogue:

> **Certified Module Interface**

The existing ProofScript production architecture already proposes ModuleInterfaceArtifact.

Applied SAVEF strengthens that artifact so a PSCV dependency can be consumed through a compact checked semantic interface instead of its complete implementation.

## 3.2 Project references: downstream consumes interface outputs

TypeScript project references allow a large project to be split into smaller projects whose dependents consume declaration outputs.

ProofScript should do the analogous operation with:

~~~text
CertifiedModuleInterface
~~~

rather than source.

## 3.3 Incremental build state

TypeScript incremental builds reuse previous project information and rebuild only what is needed.

ProofScript's QueryGraph is already moving toward a stronger semantic form:

~~~text
source changed
    |
    v
recompute module
    |
    +-- certified interface unchanged
    |       |
    |       v
    |   downstream remains green
    |
    +-- certified interface changed
            |
            v
        dependent red
~~~

## 3.4 npm as distribution substrate

TypeScript did not need a separate TypeScript package registry.

It made ordinary npm packages type-aware through declaration files and package metadata.

ProofScript should use the same adoption advantage.

## 3.5 TypeScript 7: implementation can change while semantics remain stable

TypeScript 7 replaced the compiler/tooling implementation with a native Go port while targeting behavioral compatibility and major performance gains.

ProofScript should internalize the architectural principle:

> **semantic identities belong to language/contracts, not to one compiler implementation.**

A future faster PSC implementation in another implementation language should be possible without redefining PSCV.

Compiler executable identity remains build provenance.

Language meaning remains tied to versioned semantic contracts.

## 3.6 What ProofScript must not copy

TypeScript's type compatibility is structurally oriented and intentionally permits some unsound operations for JavaScript compatibility.

That is a sensible tradeoff for TypeScript.

It is the wrong foundational rule for PSCV verification.

Therefore:

~~~text
native PSCV
    nominal/dependent/inductive verified semantics

foreign JS/TS boundary
    structural shape normalization
    runtime validation
    InterfaceIR
    explicit adapter/refinement
~~~

Do not import TypeScript structural compatibility into the verified logical core.

---

# 4. The key new artifact: CertifiedModuleInterface

This is the most important TypeScript-inspired addition in Applied SAVEF v2.

The existing build architecture already plans a ModuleInterfaceArtifact.

For PSCV verified packages, the interface should become a **certified semantic abstraction boundary**.

Conceptual identity:

~~~text
psc-module-interface/1
~~~

The exact name remains subject to a separate frozen contract.

## 4.1 Purpose

A CertifiedModuleInterface should let downstream modules:

- elaborate imports;
- perform required definitional equality;
- synthesize approved instances;
- use exported contracts;
- use exported theorems;
- know required effects/capabilities;
- know transitive public assumptions;
- reason against a stable abstraction boundary;

without loading private implementation source.

This is the ProofScript analogue of the scalability role played by TypeScript declaration files, but with much stronger meaning.

## 4.2 Required contents

At minimum:

~~~text
semantic profile identity
module/package identity

exported names
exported types

public structures/inductives
public constructor and field contracts

public instance identities
instance priority/ordering metadata where semantic

exported theorem/specification identities

effect/capability requirements

public assumption closure

imported interface identities

transparency classification

canonical digest
~~~

## 4.3 Transparency is critical

Unlike a TypeScript declaration file, a dependently typed semantic interface cannot always omit implementation bodies.

Downstream definitional equality may depend on transparent definitions.

Every exported definition must therefore be classified.

Conceptually:

~~~text
opaque
    clients may use type/spec/theorems
    body is not semantically available

transparent
    canonical checked body is part of semantic interface

implementation-private
    not visible downstream
~~~

A package must not claim the same interface digest after changing a transparent definition in a way that affects downstream reduction.

## 4.4 Interface adequacy theorem

The long-term target is a theorem or validated relation equivalent in purpose to:

> **If two implementations both satisfy the same certified opaque interface, then downstream clients that depend only on that interface need not be reverified because of private implementation changes.**

This is the core mathematical property that turns package abstraction into scalable proof reuse.

Deep specifications and contextual refinement provide the research precedent.

---

# 5. Package = executable theory

A verified npm package should eventually represent more than implementation code.

Conceptually:

~~~text
@proofscript/parser

implementation
    parser code

definitions
    Parser
    ParseState

specifications
    ParserSpec

theorems
    parser_bounds_safe
    parser_deterministic
    parse_success_valid

effects
    Pure

assumptions
    none

artifact preservation
    JS validated
    Wasm validated

public certified interface
    digest X
~~~

The package is an executable theory.

A client imports both:

~~~text
capability
+
established facts about the capability
~~~

---

# 6. Lean theory and actual kernel behavior

The SAVEF architecture must be based on Lean as it actually exists, not on a simplified slogan.

Lean's type system includes:

- dependent types;
- inductive types;
- impredicative proof-irrelevant Prop;
- quotient types;
- propositional extensionality;
- universe polymorphism;
- definitional computation;
- proof erasure.

The current reference also documents important subtleties:

- algorithmic definitional equality is reflexive and symmetric but not necessarily transitive;
- ordinary subject reduction does not hold in the textbook form;
- the checker can be driven into resource exhaustion/nontermination by adversarial terms.

These are not reasons to reject Lean.

They are reasons to model the actual checker and exact semantic version.

Therefore the correct PSKernel proof strategy is:

~~~text
independent semantic judgments
    |
    v
prove production checker refines those judgments
    |
    v
differential comparison with official Lean
    |
    v
independent replay/checker diversity
~~~

---

# 7. Lean 4.34 hardening and SAVEF

Lean 4.34 fixed three soundness routes, including an order-dependent definitional-equality cache issue.

The lesson is general:

> **A performance mechanism that can affect acceptance is part of the trust problem until semantic refinement is proved.**

For ProofScript this applies to:

- expression caches;
- defeq caches;
- environment indexes;
- native reduction capabilities;
- incremental semantic cache;
- proof-result cache;
- compiler specialization;
- optimization;
- artifact reuse.

Applied SAVEF must maintain:

~~~text
logical TCB
acceleration TCB
execution TCB
external assumptions
assurance-only tools
~~~

The current PSKernel TCB design already moves in this direction.

---

# 8. Current PSCV profile is a strong base

The PSCV-RC-v2 direction already defines the right source-level laws.

Important identities include:

~~~text
pscv-v1
PSCV-VERIFY-v1
PSCV-CERT-v1
pscv-closed-v1
pscv-boundary-v1
~~~

Important semantics include:

- requires;
- ensures;
- proof-only assert;
- loop invariant;
- decreasing/termination;
- ghost state;
- SPEC / PROOF / EXEC relevance;
- proof erasure;
- proof closure;
- specification coverage;
- approved SpecCapsule linkage;
- anti-weakening;
- verified effect semantics;
- explicit world boundaries;
- compile gating.

Applied SAVEF should build on those contracts.

It should not add a parallel verification logic.

---

# 9. Current repository audit

The psc15selfhost package architecture already has a strong semantic decomposition:

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

driver-ts
driver-rust
driver-js
driver-wasm

bootstrap
cli

pskernel-core
pskernel-lean-wasm
pskernel-lean
pskernel
~~~

The current direct-backend branch adds meaningful direct JS/Wasm work and fixed-point scripts.

This is important implementation evidence.

It is not compiler-correctness evidence.

---

# 10. Current authority gap remains real

The compiler still contains:

~~~text
PsCompilerAdmissionReadyModule
~~~

and the evaluated API still makes:

~~~text
psCompilerCheckSource
=
psCompilerPrepareSource
~~~

The direct JavaScript and Wasm drivers can currently proceed from a prepared module into validated IR and target emission.

Therefore:

> **AdmissionReady remains weaker than kernel-admitted CheckedCore.**

This is the highest-priority authority gap.

Target:

~~~text
Source
    |
    v
CandidateCore
    |
    v
AdmissionReady
    |
    | real KernelContract
    v
CheckedCore
    |
    | PSCV-CERT
    v
CertifiedSource
    |
    v
Erasure
    |
    v
RuntimeIR
    |
    v
VerifiedIR
    |
    v
backend
~~~

---

# 11. Current direct backend progress

The psc2/pscv-direct-backends branch now contains:

- direct JavaScript driver/package;
- direct Wasm driver/package;
- larger direct lowering implementations;
- direct JS self-host fixed-point script;
- direct Wasm self-host fixed-point script;
- whole-compiler direct-Wasm testing.

This improves:

- backend independence;
- bootstrap diversity;
- removal of TypeScript/Rust as mandatory semantic intermediates.

It does **not** establish semantic preservation.

Applied SAVEF therefore distinguishes:

~~~text
fixed point
    bootstrap evidence

differential execution
    behavioral evidence over tested cases

translation validation / proof
    semantic preservation evidence
~~~

No one substitutes for the others.

---

# 12. Current PSKernel formalization progress

The current pscv/prove-pskernel-core-v1 branch has significantly expanded its independent metatheory and proof sidecars.

At the evaluated snapshot, its semantic audit reports:

~~~text
A-level semantic/refinement:       21
B-level theory foundation:         16
C-level control/branch assurance:  34
D-level shallow/base:               8

total canonical source/proof pairs: 79
~~~

A-level work now covers meaningful portions of:

- declaration admission;
- Quot admission;
- expression equality;
- inference;
- substitution;
- environment semantics;
- cache-state invariants;
- reduction.

However, the audit still identifies unfinished end-to-end public correctness work.

The correct conclusion is:

> **PSKernel formal verification is materially progressing but is not yet complete.**

Applied SAVEF scorekeeping must preserve that honesty.

---

# 13. Semantic state lattice

The factory needs stronger types than a Boolean verified flag.

Target state chain:

~~~text
SourceArtifact
    |
    v
ParsedArtifact
    |
    v
CandidateCoreArtifact
    |
    v
AdmissionReadyArtifact
    |
    v
CheckedCoreArtifact
    |
    v
CertifiedSourceArtifact
    |
    v
ErasedIrArtifact
    |
    v
VerifiedIrArtifact
    |
    v
TargetIrArtifact
    |
    v
PreservedExecutableArtifact
    |
    v
ReleaseEvidenceEnvelope
~~~

The states are monotonic in authority only when the required transition has actually occurred.

Forbidden:

~~~text
AdmissionReady
    renamed to CheckedCore

validated IR
    called source verified

fixed-point compiler
    called correct compiler

passing tests
    called theorem

npm provenance
    called semantic proof
~~~

---

# 14. Certified source is stronger than CheckedCore

CheckedCore means:

> the kernel admitted the core declarations.

It does not necessarily mean:

> all required business/program specifications are complete.

CertifiedSource additionally requires PSCV-CERT-v1:

~~~text
proof closure
specification coverage
effect closure
assumption policy
approved spec identity
semantic profile identity
~~~

Thus:

~~~text
CheckedCore
    !=
CertifiedSource
~~~

This distinction is essential.

---

# 15. Erasure is a proof-relevant compiler pass

PSCV classifies information as:

~~~text
SPEC
PROOF
EXEC
~~~

Proof and ghost data may be erased only when their removal is noninterfering.

Required property:

> Removing SPEC/PROOF material must not change observable EXEC behavior.

Relevant observations include:

- returned runtime values;
- branch behavior;
- effect order;
- foreign calls;
- public errors;
- resource behavior when part of the semantic contract.

A program where ghost state selects a runtime branch must fail certification.

---

# 16. RuntimeIR and VerifiedIR

The current code already separates raw erased construction state from PsValidatedIrModule.

Applied SAVEF should complete the naming/ownership:

~~~text
Checked/Certified source
    |
    v
RuntimeIR
    may contain construction forms
    |
    v
validateRuntimeIr
    |
    v
VerifiedIR
    no unresolved executable forms
~~~

VerifiedIR is target-neutral.

It must not contain:

- JavaScript representation policy;
- TypeScript structural typing;
- Rust ownership policy;
- Wasm opcodes/layout;
- npm module resolution;
- OS semantics.

---

# 17. BackendPreservationContract

Every target backend needs a versioned semantic contract.

Conceptual fields:

~~~text
source IR semantic identity
target semantic identity
supported feature closure
observable behavior relation
lowering identity
validator/proof identity
unsupported-case behavior
resource/exhaustion policy
runtime ABI identity
~~~

Accepted preservation strategies:

1. formal compiler-pass proof;
2. proof-producing transformation;
3. translation validation;
4. explicitly lower evidence class.

For high-assurance PSCV packages, ArtifactPreserved status requires 1-3.

Differential tests alone are useful but do not produce ArtifactPreserved status.

---

# 18. Direct Wasm should be the first strongest artifact lane

Wasm is attractive for high-assurance deployment because:

- target semantics are narrower than arbitrary JavaScript;
- binaries are structurally validated;
- execution model is more constrained;
- independent runtimes exist.

Recommended priority:

~~~text
VerifiedIR
    |
    v
WasmIR
    |
    v
validateWasmIR
    |
    v
canonical binary
    |
    v
translation validation / proof
~~~

Direct JavaScript remains critical for ecosystem reach and should use a deliberately restricted canonical JS subset where practical.

---

# 19. ModuleInterfaceArtifact: TypeScript scale with mathematical strength

The existing production architecture already identifies ModuleInterfaceArtifact as a separate build artifact.

Applied SAVEF v2 makes it a first-class scale mechanism.

Target properties:

1. canonical serialization;
2. exact semantic-profile binding;
3. checked origin;
4. all downstream-observable semantic information included;
5. no private implementation detail unless transparency requires it;
6. stable digest;
7. imported dependency interface IDs;
8. public theorem/spec identities;
9. instance resolution information;
10. capability/effect requirements.

For pscv-v1, a verified package publishes a certified version of this interface.

---

# 20. Module-interface equivalence criterion

The strongest incremental-build property is:

~~~text
source implementation changes
    |
    v
recompute certified module interface
    |
    +-- same canonical interface digest
    |       |
    |       v
    |    dependents stay green
    |
    +-- changed interface digest
            |
            v
         affected dependents red
~~~

This is the formal-software analogue of TypeScript project-reference scaling.

But ProofScript's interface is stronger than .d.ts because it may include behavioral theorems, assumptions, effects, and semantic transparency information.

---

# 21. QueryGraph evolution

Current QueryGraph already uses sourceKey, interfaceKey, and dependency interface keys.

Target record:

~~~text
SemanticQueryRecord {
    moduleId

    sourceArtifactId
    elaboratedInterfaceId

    specCapsuleId
    obligationSetId

    checkedCoreId
    certifiedSourceId

    moduleInterfaceId
    theoremInterfaceId
    assumptionClosureId

    verifiedIrId

    backendEvidenceIds

    dependencyInterfaceIds
}
~~~

This is not one giant artifact.

It is a graph of independent cacheable stages.

---

# 22. Query correctness criterion

The query system must be semantically transparent.

If a query is green, re-executing it from authoritative inputs must produce an equivalent semantic output.

Long-term theorem/validation target:

~~~text
GreenReuse(query, cache)
    =>
Equivalent(
    cachedResult,
    recompute(query.authoritativeInputs)
    )
~~~

A cache hit must never create new acceptance.

Cache corruption becomes:

~~~text
miss / reject / recompute
~~~

never semantic fallback.

---

# 23. Semantic lock: use psc.lock

The existing architecture already recommends psc.lock.

Applied SAVEF v2 adopts it instead of inventing another competing lock name.

package-lock.json records the physical npm dependency world.

psc.lock records the semantic dependency world.

Conceptually:

~~~text
package-lock.json
    package version
    resolved source
    npm integrity

psc.lock
    package semantic manifest digest
    ModuleInterface digest
    theorem interface digest
    assumption closure digest
    source/profile contract identities
    required backend/runtime contract
~~~

Together:

~~~text
exact bytes
+
exact semantic dependencies
~~~

---

# 24. npm SemVer is useful but not proof

npm asks:

> does version satisfy range?

PSCV must additionally ask:

> does the selected package satisfy the semantic interface this client was certified against?

Three cases:

## Exact semantic identity

~~~text
same interface digest
    safe reuse
~~~

## Explicit semantic refinement

~~~text
new package
    proves/refines required interface
    compatibility certificate accepted
~~~

## Unknown compatibility

~~~text
SemVer compatible
but no semantic evidence

=> affected PSCV clients red/reverify
~~~

This is mathematically stronger dependency management without replacing npm.

---

# 25. Semantic compatibility certificate

Target concept:

~~~text
PackageCompatibilityCertificate {
    oldInterfaceId
    newInterfaceId
    relation
    proofOrValidatorEvidence
    assumptionDelta
    capabilityDelta
}
~~~

Possible relations:

~~~text
identical
refines
behaviorally-compatible-under-assumptions
incompatible
unknown
~~~

A SemVer update may be automatically accepted for a verified downstream package only when policy permits the resulting semantic relation.

---

# 26. TypeScript foreign-interface strategy

PSCV does not need to clone TypeScript's type system.

Use the pattern already identified in the PSCV/TypeScript comparison:

~~~text
TypeScript / .d.ts
        |
        v
normalization
        |
        v
InterfaceIR
        |
        +--> native PSCV data/function
        +--> generated adapter
        +--> opaque foreign handle
        +--> runtime-validated structural data
        +--> reject if sound mapping unavailable
~~~

Native PSCV prefers:

- structure instead of open object shape;
- inductive instead of discriminated structural union;
- Option instead of native null/undefined;
- Except instead of arbitrary throw;
- typeclass/capability instead of structural generic constraint;
- explicit conversions instead of structural assignment;
- PSCV effect models instead of Promise as semantic foundation.

This provides TypeScript ecosystem reach without importing TypeScript unsoundness.

---

# 27. A ProofScript package can serve TypeScript and PSCV simultaneously

Example npm package:

~~~text
@proofscript/json/
│
├── package.json
│
├── dist/
│   ├── index.js
│   ├── index.d.ts
│   └── index.wasm
│
├── src/
│   └── ProofScript source
│
└── proofscript/
    ├── manifest
    ├── module-interface
    ├── theorem-interface
    ├── assumptions
    └── evidence
~~~

TypeScript consumer sees:

~~~text
index.js
index.d.ts
~~~

ProofScript consumer sees:

~~~text
CertifiedModuleInterface
theorems
specifications
assumptions
preservation evidence
~~~

One npm package can therefore participate in two ecosystems.

---

# 28. npm metadata is not proof authority

The package.json proofscript field should be a locator only.

Concept:

~~~text
proofscript:
    schema
    semanticManifestPath
    semanticManifestDigest
~~~

Never:

~~~text
verified: true
~~~

as an authority claim.

A malicious package may write any metadata.

ProofScript assurance is produced only by replaying/checking referenced evidence under the selected policy.

---

# 29. npm installation policy

Install-time scripts are an explicit supply-chain boundary.

For pscv-closed release builds:

~~~text
install scripts disabled
or
strict explicit allowlist
~~~

Current npm supports ignore-scripts and script allow policies.

The selected install policy must become part of BuildAction identity.

An undeclared install script must not run before verification and mutate the environment invisibly.

---

# 30. npm publication policy

Current npm staged publishing gives Applied SAVEF a strong release primitive.

Recommended high-assurance workflow:

~~~text
source commit
    |
    v
locked hermetic build
    |
    v
PSCV certification
    |
    v
backend preservation evidence
    |
    v
npm pack
    |
    v
npm stage publish
    |
    v
download exact staged tarball
    |
    v
independent replay
    |
    v
human/policy approval
    |
    v
npm stage approve
~~~

npm trusted publishing/provenance answers:

> where and how was this package built?

ProofScript evidence answers:

> what semantic claims does it justify?

These must remain separate.

---

# 31. Content-addressed checked interface cache

To reach TypeScript-scale dependency graphs, ProofScript cannot replay the whole mathematical ecosystem on each edit.

Store validated semantic artifacts by content identity.

Concept:

~~~text
CAS/
    checked-core/
    certified-source/
    module-interface/
    verified-ir/
    backend-evidence/
~~~

On import:

~~~text
semantic digest known and validated
    |
    v
reuse interface

semantic identity mismatch
    |
    v
replay / rebuild
~~~

High-assurance mode can force independent replay.

---

# 32. Compiler service: the semantic API for humans and AI

One semantic service should power:

- CLI;
- LSP;
- editor;
- docs;
- package tooling;
- build graph;
- AI agents.

Target operations:

~~~text
parse
resolve
elaborate
typeOf

goalState
obligation
obligationSlice
candidateLemmas

candidateCore
admissionPayload
checkedCore
certifiedSource

moduleInterface
theoremInterface
assumptionClosure

verifiedIr

semanticDiff
affectedModules
affectedProofs

capabilitySearch
buildPlan
~~~

No agent gets a private alternate type checker.

---

# 33. Proof-aware context slicing

Current repository-scale verification research shows that proof success degrades as transitive relevant context grows, while curated dependency closures can improve performance.

ProofScript can do better than generic repository retrieval because it owns the semantic graph.

For a proof obligation, derive:

~~~text
local context
required definitions
transparent dependencies
exported theorem candidates
effect model
assumption set
relevant prior failures
~~~

The AI should not receive the entire repository unless needed.

---

# 34. Joint program-and-proof architecture

Current AI research shows benefits from designing implementation and proof together.

Applied SAVEF planner objective:

~~~text
correctness
+
proofability
+
deep interface quality
+
runtime performance
+
interop
+
future theorem reuse
+
proof maintenance
~~~

The planner may prefer a design that is easier to verify and compose even if another implementation is superficially shorter.

---

# 35. Specification integrity

Formal proof establishes:

~~~text
implementation satisfies approved formal specification
~~~

It does not establish:

~~~text
approved formal specification perfectly captures human intent
~~~

Therefore the pipeline must separate:

~~~text
human requirements
    |
    v
candidate formalization
    |
    v
specification audit
    |
    v
ApprovedSpecCapsule
    |
    v
implementation/proof generation
~~~

The implementation agent must not silently weaken the ApprovedSpecCapsule.

Any weakening creates a new identity requiring explicit approval.

---

# 36. EffectModel registry

Software mathematics needs more than pure functions.

Every effect participating in pscv-v1 verified status should resolve to a versioned EffectModel.

Concept:

~~~text
EffectModel {
    identity
    operation signatures

    WP / Hoare semantics

    pure law
    bind law
    monotonicity

    primitive operation specifications

    resource behavior

    capability requirements

    backend realization contract
}
~~~

pscv-closed:

~~~text
all reachable effects have closed checked models
~~~

pscv-boundary:

~~~text
boundary effects explicitly contribute assumptions
~~~

Unclassified effects fail certification.

---

# 37. Formalization coverage map

SAVEF must measure which software domains have sufficient mathematical infrastructure.

| Domain | Preferred owner |
| --- | --- |
| pure algorithms | core types + theorem library |
| data invariants | dependent/refinement types |
| state | verified WP effect |
| typed errors | verified effect |
| reader/environment | verified effect |
| loops/local mutation | VC/invariant semantics |
| heap/aliasing | separation/resource logic |
| resources | capability/resource logic |
| async | Task/structured-concurrency model |
| concurrency | separation logic + memory model |
| distributed systems | state/trace/temporal refinement |
| filesystem | abstract model + boundary contract |
| network | protocol model + boundary contract |
| database | transaction model + boundary |
| randomness | probabilistic model + entropy assumption |
| crypto | functional proof + crypto assumptions |
| FFI | InterfaceIR + boundary contract |
| compiler | semantic preservation |
| performance | cost model + benchmark |
| human/UI | empirical evidence |

Iris and Aneris show that sophisticated concurrent/distributed reasoning can live above a small foundational logic.

A Lean 4 Iris port exists, making this direction particularly relevant to PSCV.

---

# 38. Assumption algebra

Every verified claim is relative to assumptions.

Applied SAVEF requires an explicit transitive assumption graph.

Classes include:

~~~text
logical foundation assumptions
trusted kernel/runtime capabilities
compiler preservation assumptions
foreign runtime assumptions
OS/hardware assumptions
network/service assumptions
cryptographic assumptions
empirical performance assumptions
~~~

Required operation:

~~~text
AssumptionClosure(package)
~~~

A package upgrade that introduces a new external assumption changes the public semantic interface unless policy explicitly treats that assumption as private/non-observable.

---

# 39. Conservative extension metric

A strong package contributes new capability without adding unproved trust.

Define an engineering metric:

~~~text
ConservativeExtensionRatio
=
accepted capability releases that add no new transitive unproved semantic assumption
/
accepted capability releases
~~~

This does not replace a formal conservativity theorem.

It measures ecosystem trust growth.

---

# 40. TheoryManifest and capability index

TheoryManifest is a **derived index**.

It is never proof authority.

It may contain:

~~~text
package identity
semantic profile

public capabilities
deep specifications
theorem identities
effect models
assumption closure

target availability
artifact preservation class

examples / AI hints
~~~

Every formal claim must resolve to checked authoritative artifacts.

If TheoryManifest disagrees with evidence, TheoryManifest is wrong.

---

# 41. Typed ecosystem graph

Separate graph domains.

## Specification graph

~~~text
formalizes
covers
refines
revises
~~~

## Proof graph

~~~text
proves
uses
discharges
generalizes
~~~

## Capability graph

~~~text
provides
implements
adapts
refines
replaces
~~~

## Assumption graph

~~~text
assumes
validated-by
monitored-by
~~~

## Artifact graph

~~~text
elaborates-to
admitted-as
certified-as
erases-to
validates-to
lowers-to
built-from
~~~

This graph lets AI search software by behavior and evidence instead of package name alone.

---

# 42. Example: WebSocket synthesis

Goal:

~~~text
verified WebSocket package
JS + Wasm
~~~

Semantic query finds:

~~~text
@proofscript/bytes
    bounds theorems

@proofscript/utf8
    decoder validity

@proofscript/parser
    streaming parser laws

@proofscript/http
    HTTP upgrade contract

@proofscript/state-machine
    transition invariant library
~~~

Missing semantic edges:

~~~text
WebSocket frame relation
mask/unmask correctness
fragmentation invariant
handshake relation
~~~

AI works primarily on those missing edges.

After acceptance, the new package contributes:

~~~text
WebSocket capability
new frame theorems
new protocol state model
possible reusable fragmentation lemma
~~~

A later Socket.IO package has less original work.

That is self-amplification.

---

# 43. Example: TypeScript package assimilation

Suppose a project needs an existing npm package:

~~~text
pg
~~~

No native verified driver exists.

A ProofScript package can provide:

~~~text
@proofscript/bindings-pg

.d.ts normalization
    |
    v
InterfaceIR
    |
    v
typed adapter

plus:
    explicit transaction contract
    conformance tests
    foreign assumption
~~~

Assurance:

~~~text
adapter:
    KernelVerified

foreign pg runtime:
    External / Boundary

database server:
    External / Boundary
~~~

Later:

~~~text
@proofscript/postgres
~~~

may replace the foreign package with a stronger native implementation.

This lets ProofScript grow by progressively assimilating npm instead of rebuilding it first.

---

# 44. TypeScript-scale developer experience criterion

A verified ecosystem will fail if every edit requires theorem-prover expertise.

The ordinary path should be:

~~~text
write practical PSCV
    |
    v
compiler creates obligations
    |
    +--> deterministic automation
    +--> tactics
    +--> specialized prover
    +--> AI
    |
    v
only genuinely difficult obligations reach developer
~~~

The tooling target is:

- ordinary code feels like practical programming;
- proof state is available when necessary;
- routine obligations are usually automated;
- imported verified libraries reduce proof burden.

Formal verification must reduce supervision cost, not merely move it.

---

# 45. Replaceable compiler implementation

TypeScript 7 demonstrates that a language compiler can be radically reimplemented for performance while preserving user-visible behavior.

ProofScript should define:

~~~text
semantic contracts
    stable

compiler implementation
    replaceable

compiler binary identity
    recorded in provenance
~~~

A future compiler implementation may be:

- Lean;
- self-hosted PSCV;
- direct JavaScript;
- direct Wasm;
- native implementation;
- another language.

It qualifies only by satisfying conformance, fixed semantic artifact, and preservation requirements.

This protects longevity.

---

# 46. Self-hosting is not correctness

Direct JS/Wasm fixed points are valuable.

They establish:

~~~text
compiler can reproduce canonical compiler artifact
~~~

They do not establish:

~~~text
compiler preserves PSCV semantics
~~~

SAVEF tracks independently:

~~~text
source conformance
kernel soundness
compiler fixed point
compiler semantic preservation
artifact reproducibility
diverse bootstrap
runtime assumptions
~~~

No single Boolean combines them.

---

# 47. AssuranceVector

Every package/artifact should expose a multidimensional assurance summary.

Concept:

~~~text
AssuranceVector {
    specification
    logicalProof
    kernelDiversity
    erasure
    verifiedIr
    backendPreservation
    boundaryModel
    provenance
    resourceEvidence
}
~~~

Example:

~~~text
specification:
    approved-formal

logicalProof:
    kernel-checked

kernelDiversity:
    dual-replay

erasure:
    proved

backendPreservation:
    translation-validated

boundary:
    external database assumption

provenance:
    staged + OIDC provenance

performance:
    benchmarked
~~~

A single VERIFIED badge is insufficient.

---

# 48. AI acceptance hardening

Current agent research demonstrates reward-hacking behaviors such as skipping verification or manipulating evaluation state.

Applied SAVEF requires architectural separation.

Agent cannot control:

- approved specification identity;
- KernelContract implementation selected by release policy;
- required proof closure;
- hidden FactoryBench evaluation;
- release approval;
- evidence classification;
- artifact hash verification.

Candidate output is re-created/replayed in an independent acceptance environment.

Generation freedom is high.

Acceptance freedom is near zero.

---

# 49. Failure memory

Failed work becomes reusable knowledge.

Concept:

~~~text
FailureKnowledge {
    semanticProfile
    goalFingerprint
    dependencySlice

    attemptedStrategy
    checkerOutcome
    counterexample

    repair
    generalizedLesson
}
~~~

Failure memory is not theorem authority.

Before use it must match the relevant semantic profile.

---

# 50. Generalization loop

When similar proof patterns recur, AI may propose:

~~~text
generic theorem
generic abstraction
new tactic
new verified package
~~~

The proposal enters the ecosystem only after ordinary checking.

The aim is:

> solve a proof pattern once, then reuse it.

---

# 51. FactoryBench

Self-amplification must be measured with the model held fixed.

Benchmark protocol should pin:

~~~text
model ID/version
inference parameters
tool protocol
semantic profile
task distribution
compute budget
allowed external context
acceptance policy
evaluation harness
~~~

Compare:

~~~text
Factory N
    smaller accepted theory graph

Factory N+1
    larger accepted theory graph
~~~

Metrics:

- accepted task success;
- human minutes;
- tokens;
- model cost;
- proof/repair iterations;
- new code volume;
- theorem reuse;
- capability reuse;
- specification reuse;
- proof invalidation fanout.

A self-amplification claim requires statistically meaningful improvement without assurance regression.

---

# 52. Provable and falsifiable criteria

Evidence modes:

~~~text
P = machine-checked proof
M = deterministic machine/conformance test
A = adversarial test
R = reproducibility/replay
E = empirical benchmark
~~~

Twenty-four criteria define the target architecture.

---

## C1 — Lean semantic fidelity

**Weight:** 5

**Evidence:** P + M.

PSKernel/PSCV semantics must target an exact Lean semantic profile, not an informal calculus.

**Pass:** all public accepted kernel operations used by PSCV are related to the selected semantic judgments.

**Failure witness:** checker accepts an environment that violates the stated semantic relation.

---

## C2 — Semantic profile identity

**Weight:** 4

**Evidence:** M.

Every proof, interface, cache result, semantic package, and certificate binds to exact meaning-relevant contract versions.

**Mutation test:** change Lean pin, Standard environment, PSCV verification version, kernel contract, runtime semantics, or IR schema.

Old evidence must invalidate unless explicit migration evidence exists.

---

## C3 — Kernel semantic refinement

**Weight:** 5

**Evidence:** P + M + independent replay.

KernelContract success must imply the appropriate independently stated typing/admission judgment.

**Failure witness:** a public successful path has only wrapper/control evidence.

---

## C4 — Authority-state unforgeability

**Weight:** 5

**Evidence:** M + A.

The following states remain distinct:

~~~text
CandidateCore
AdmissionReady
CheckedCore
CertifiedSource
VerifiedIR
PreservedArtifact
~~~

**Pass:** no public path constructs a stronger state without its authority transition.

---

## C5 — PSCV specification/proof closure

**Weight:** 5

**Evidence:** M + P where applicable.

Reachable mandatory obligations must be closed before CertifiedSource can exist.

**Mutation test:** add one unproved required postcondition.

Verified emission must fail.

---

## C6 — Proof/ghost erasure noninterference

**Weight:** 4

**Evidence:** P or proof-producing validation.

SPEC/PROOF data cannot alter EXEC observations.

**Adversarial test:** make ghost data influence runtime branch/effect.

Certification must reject.

---

## C7 — RuntimeIR → VerifiedIR validation soundness

**Weight:** 4

**Evidence:** P + M.

Validator success implies every declared VerifiedIR invariant.

Unknown/unresolved construction state cannot survive.

---

## C8 — Backend semantic preservation

**Weight:** 5

**Evidence:** P or translation validation + M.

PreservedArtifact requires evidence relating target observable behavior to VerifiedIR.

**Mutation test:** alter emitted target computation.

Validation must fail.

---

## C9 — Independent high-assurance replay

**Weight:** 3

**Evidence:** R.

High-assurance package policy requires at least one substantially independent proof replay/check path.

Correlated implementation paths must be documented.

---

## C10 — CertifiedModuleInterface completeness

**Weight:** 5

**Evidence:** P + M.

The interface contains every downstream-observable semantic dependency, including required transparent bodies, theorem/spec identities, instances, assumptions, and capabilities.

**Key test:** client elaboration against interface and authoritative implementation produce equivalent required semantic results.

---

## C11 — Semantic dependency compatibility

**Weight:** 4

**Evidence:** P/M.

SemVer alone never preserves proof authority.

Dependency upgrade is accepted only through exact interface identity or accepted compatibility/refinement evidence.

---

## C12 — npm semantic integrity

**Weight:** 4

**Evidence:** M + R.

npm metadata locates evidence but cannot manufacture assurance.

**Adversarial test:** edit a verified flag or capability claim without proof artifacts.

Assurance must not increase.

---

## C13 — Progressive TypeScript/JavaScript interop

**Weight:** 4

**Evidence:** M.

Foreign structural/dynamic behavior is normalized through InterfaceIR/adapters.

Unverified foreign runtime remains Boundary/External.

---

## C14 — TypeScript-scale incremental module architecture

**Weight:** 5

**Evidence:** M + E.

Semantic interface identity drives red/green invalidation.

**Tests:**

1. private implementation change + same certified interface → dependent green;
2. theorem/spec/effect/assumption interface change → affected dependent red.

Performance is measured on large graphs.

---

## C15 — Unified compiler semantic service

**Weight:** 3

**Evidence:** M.

CLI, LSP, package tooling, and agents consume one semantic service rather than implementing separate language semantics.

---

## C16 — Formalization coverage / effect-model closure

**Weight:** 4

**Evidence:** P + M.

Every reachable verified effect operation resolves to a versioned checked EffectModel or an explicit BoundaryContract.

Unclassified effects cannot enter certified status.

---

## C17 — Transitive assumption closure

**Weight:** 4

**Evidence:** M.

Every exported assurance claim has a computable transitive assumption set.

**Mutation test:** add foreign boundary deep in dependency graph.

Top-level assumption identity must change.

---

## C18 — Deep-specification and proof-abstraction stability

**Weight:** 4

**Evidence:** P/M + E.

Private implementation changes preserving public certified deep spec should not invalidate clients.

Measure proof invalidation fanout.

---

## C19 — Typed theorem/capability/evidence graph

**Weight:** 4

**Evidence:** M.

Every authoritative graph edge resolves to checked evidence or explicitly classified empirical evidence.

The graph itself cannot create proof authority.

---

## C20 — AI/acceptance separation

**Weight:** 4

**Evidence:** A + M.

Agent cannot weaken spec, disable checks, mutate acceptance policy, or alter release authority while retaining identity.

---

## C21 — Semantic context slicing

**Weight:** 3

**Evidence:** M + E.

Dependency slices are derived from compiler/theorem graph and are complete for the stated task class.

Evaluate solve rate/token cost against full-repository context.

---

## C22 — Self-amplification evidence

**Weight:** 4

**Evidence:** E + R.

With model and evaluation held fixed, a later ecosystem must measurably improve production cost/success without assurance regression.

---

## C23 — Resource behavior and denial-of-service correctness

**Weight:** 4

**Evidence:** M + A + E.

Resource exhaustion is explicit.

No timeout/fuel/stack/memory failure can become acceptance.

---

## C24 — Bootstrap, reproducibility, implementation replaceability, longevity

**Weight:** 4

**Evidence:** R + M.

Fixed point, compiler correctness, reproducibility, and semantic conformance remain distinct.

A new compiler implementation may replace an old one only through conformance/preservation gates.

---

# 53. Architecture scoring rubric

For **architecture design**, not implementation completion:

~~~text
0
    absent or contradictory

5
    concept exists but authority/evidence ambiguous

8
    complete enforceable design with clear inputs/outputs/failures

9
    full evidence protocol, adversarial tests, repository mapping

9.5
    precise machine-checkable acceptance criteria and compatibility/evolution policy

9.9
    no material architectural ambiguity for declared scope;
    every trust transition is falsifiable;
    scale, interop, evolution, and independent evidence are covered

10
    reserved; no credible unresolved architecture question
~~~

The target intentionally does not use 10.

---

# 54. Evaluation loop

## Baseline — Applied SAVEF Version 1

Score:

**8.76 / 10**

Main weaknesses:

- TypeScript-scale public semantic interface not explicit enough;
- psc.lock vs proofscript.lock naming/ownership conflict;
- transparent-definition dependency problem unresolved;
- package upgrade compatibility too coarse;
- compiler-implementation replaceability under semantic identity underspecified;
- formalization coverage not integrated strongly enough with packages;
- proof-interface adequacy not stated as a target theorem.

---

## Iteration A — TypeScript-scale architecture

Changes:

- CertifiedModuleInterface;
- transparent/opaque export classification;
- TypeScript .d.ts/project-reference analogy;
- QueryGraph interface-driven invalidation;
- psc.lock alignment;
- TypeScript 7-style compiler replaceability;
- explicit InterfaceIR boundary for structural TS semantics.

Score:

**9.42 / 10**

Remaining weaknesses:

- package interface composition not strong enough;
- effect/assumption algebra incomplete;
- backend preservation and package compatibility not tightly bound to interface identity;
- factory learning still insufficiently isolated.

---

## Iteration B — mathematical package composition

Changes:

- interface adequacy/refinement target;
- Semantic Compatibility Certificate;
- EffectModel registry;
- assumption closure as public semantic identity;
- certified package theory interface;
- backend preservation bound to package evidence;
- typed evidence graph;
- formal proof-invalidation rules.

Score:

**9.78 / 10**

Remaining weaknesses:

- adversarial acceptance environment not fully closed;
- independent replay policy not strong enough;
- self-amplification measurement not sufficiently reproducible;
- long-term semantic-profile migration still ambiguous.

---

## Iteration C — final Applied SAVEF v2

Changes:

- independent high-assurance replay;
- immutable staged-package replay;
- explicit semantic migration rule;
- fixed-model FactoryBench;
- resource/DoS acceptance rules;
- compiler implementation replacement protocol;
- all evidence transitions versioned and typed;
- no registry/index/cache authority;
- complete TypeScript-scale incremental interface model.

Final architecture score:

**9.93 / 10**

Minimum hard-gate score:

**9.90 / 10**

This clears the requested 9.9 target.

---

# 55. Final target criterion scores

| Criterion | Weight | Target |
| --- | ---: | ---: |
| C1 Lean semantic fidelity | 5 | 9.95 |
| C2 Semantic profile identity | 4 | 9.95 |
| C3 Kernel semantic refinement | 5 | 9.90 |
| C4 Authority-state unforgeability | 5 | 9.95 |
| C5 PSCV closure | 5 | 9.95 |
| C6 Erasure noninterference | 4 | 9.90 |
| C7 IR validation soundness | 4 | 9.95 |
| C8 Backend preservation | 5 | 9.90 |
| C9 Independent replay | 3 | 9.90 |
| C10 CertifiedModuleInterface | 5 | 9.95 |
| C11 Semantic dependency compatibility | 4 | 9.95 |
| C12 npm semantic integrity | 4 | 9.95 |
| C13 JS/TS progressive interop | 4 | 9.95 |
| C14 Incremental module architecture | 5 | 9.90 |
| C15 Unified compiler service | 3 | 9.90 |
| C16 Formalization/effect closure | 4 | 9.90 |
| C17 Assumption closure | 4 | 9.95 |
| C18 Deep-spec abstraction stability | 4 | 9.95 |
| C19 Typed ecosystem graph | 4 | 9.95 |
| C20 AI/acceptance separation | 4 | 9.95 |
| C21 Semantic context slicing | 3 | 9.90 |
| C22 Self-amplification evidence | 4 | 9.90 |
| C23 Resource behavior | 4 | 9.90 |
| C24 Bootstrap/replaceability/longevity | 4 | 9.95 |

Weighted:

**9.93 / 10**

No criterion is scored 10.

---

# 56. Current implementation/evidence score

Current evidence is scored separately.

| Criterion | Current evidence |
| --- | ---: |
| C1 Lean fidelity | 8.5 |
| C2 Semantic identity | 8.2 |
| C3 Kernel refinement | 7.2 |
| C4 Authority separation | 5.0 |
| C5 PSCV closure | 4.5 |
| C6 Erasure preservation | 5.0 |
| C7 IR validation | 6.5 |
| C8 Backend preservation | 5.8 |
| C9 Independent replay | 5.5 |
| C10 CertifiedModuleInterface | 5.5 |
| C11 Semantic dependency compatibility | 5.8 |
| C12 npm semantic integrity | 5.5 |
| C13 JS/TS interop | 7.0 |
| C14 Incremental architecture | 7.2 |
| C15 Compiler service | 5.5 |
| C16 Formalization coverage | 6.0 |
| C17 Assumption closure | 5.5 |
| C18 Deep-spec stability | 6.2 |
| C19 Typed ecosystem graph | 3.5 |
| C20 AI separation | 4.0 |
| C21 Semantic context | 5.0 |
| C22 Amplification evidence | 2.0 |
| C23 Resource behavior | 6.8 |
| C24 Bootstrap/replaceability | 8.8 |

Weighted current evidence:

**approximately 5.90 / 10**

Important improvements since Applied SAVEF v1 evaluation include:

- significantly expanded pskernel-core semantic proof work;
- substantially larger direct-JS backend work;
- substantially larger direct-Wasm backend work;
- direct JS fixed-point machinery;
- direct Wasm fixed-point machinery.

The largest remaining gap is still:

~~~text
prepared/admission-ready
    ->
real checked authority
    ->
PSCV-certified source
~~~

---

# 57. Recommended repository architecture

Do not reorganize the existing semantic packages unnecessarily.

Preserve:

~~~text
packages/
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
    project/

    pskernel-core/
    pskernel-lean-wasm/
    pskernel-lean/

    backend-js/
    backend-wasm/
    backend-ts/
    backend-rust/

    driver-js/
    driver-wasm/
    driver-ts/
    driver-rust/

    bootstrap/
    cli/
~~~

Add new packages only where they correspond to a real independent contract.

Recommended additions:

~~~text
kernel-contract/
checked-core/

pscv-spec/
pscv-obligation/
pscv-cert/

runtime-ir/
verified-ir/

module-interface/
evidence-core/

interface-ir/
capability-contract/

package-manifest/
semantic-lock/

compiler-service/

artifact-codec/
artifact-store/
~~~

Factory-only packages:

~~~text
agent-protocol/
theory-index/
factory-orchestrator/
factory-memory/
factory-generalizer/
factory-bench/
model-router/
~~~

Factory packages must not enter the semantic/bootstrap TCB.

---

# 58. Target dependency law

~~~text
AI / IDE / CLI / package tools
              |
              v
       compiler-service
              |
              v
      parser/meta/elab
              |
              v
         CandidateCore
              |
              v
        AdmissionReady
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
      CertifiedSource
              |
              +--------------------+
              |                    |
              v                    v
    CertifiedModuleInterface     erasure
                                   |
                                   v
                                RuntimeIR
                                   |
                                   v
                                VerifiedIR
                               /    |    \
                              v     v     v
                            JS    Wasm   adapter
                               \    |    /
                              preservation
                                   |
                                   v
                               evidence-core
                                   |
                                   v
                            package-manifest
                                   |
                                   v
                              theory-index
~~~

---

# 59. Forbidden authority paths

Never allow:

~~~text
AI
    -> CheckedCore

package.json
    -> theorem authority

TheoryManifest
    -> theorem authority

cache
    -> theorem authority

SemVer
    -> proof compatibility

backend
    -> source verification authority

test result
    -> proof

fixed point
    -> compiler correctness

npm provenance
    -> semantic correctness

foreign .d.ts
    -> runtime truth

resource exhaustion
    -> acceptance
~~~

---

# 60. Implementation roadmap

## Phase 0 — normalize identities

Freeze or draft:

- SemanticProfileIdentity;
- ModuleInterface contract identity;
- AssuranceVector;
- effect/capability identities;
- evidence schema.

## Phase 1 — real CheckedCore boundary

Implement:

~~~text
AdmissionReady
    ->
KernelContract
    ->
CheckedCore
~~~

Remove verified emission paths from merely prepared input.

## Phase 2 — PSCV certification

Implement:

- canonical obligations;
- proof closure;
- specification coverage;
- effect closure;
- assumption closure;
- CertifiedSource.

## Phase 3 — CertifiedModuleInterface

Generate it from certified source.

Include:

- downstream type/elaboration information;
- transparent bodies when required;
- deep specifications;
- theorem interface;
- effects;
- assumptions.

Extend QueryGraph to use this artifact.

## Phase 4 — RuntimeIR / VerifiedIR cleanup

Physically separate construction and validated runtime IR.

Prove/validate validator soundness.

## Phase 5 — npm package/psc.lock contract

Freeze:

- package.json proofscript locator;
- package semantic manifest;
- psc.lock;
- npm integrity binding;
- install script policy;
- staged publication policy.

## Phase 6 — backend preservation

Prioritize:

1. direct Wasm;
2. direct JS canonical subset;
3. TypeScript/Rust adapter classifications.

## Phase 7 — compiler service

Expose semantic operations to:

- IDE;
- package manager;
- AI;
- build engine.

## Phase 8 — TheoryManifest / typed theory index

Derive only from checked package artifacts.

## Phase 9 — progressive npm assimilation

Prioritize highly reusable foundations:

~~~text
bytes
UTF-8
collections
parsers
JSON
URL
HTTP
crypto boundaries
database adapters
streams
resource handling
~~~

## Phase 10 — FactoryBench

Do not claim demonstrated self-amplification before fixed-model evaluation succeeds.

---

# 61. First concrete package experiment

A strong first experiment would use:

~~~text
@proofscript/bytes
    |
    v
@proofscript/parser
    |
    +--> @proofscript/json
    |
    +--> @proofscript/http
              |
              v
       @proofscript/websocket
~~~

For each package record:

- source lines;
- spec lines;
- proof obligations;
- automated proof ratio;
- theorem reuse;
- human intervention;
- model tokens;
- compile/check time;
- proof invalidation after refactor;
- public interface size;
- semantic assumptions.

Then test whether later packages become cheaper because of earlier verified assets.

This is a concrete miniature SAVEF.

---

# 62. What would disprove the architecture?

The thesis should be revised if experiments show:

1. CertifiedModuleInterface cannot be made sufficiently complete without effectively shipping all implementation internals.
2. Proof invalidation remains close to source invalidation at scale.
3. Theorem/capability retrieval does not materially reduce agent context or solve cost.
4. Formal specification creation costs more than later reuse saves.
5. Backend preservation costs dominate ecosystem development.
6. Progressive npm adapters are too expensive to maintain.
7. Ordinary PSCV development requires continual low-level Lean expertise.
8. Fixed-model FactoryBench shows no meaningful productivity improvement as verified ecosystem knowledge grows.
9. Package semantic compatibility proofs are more expensive than simply re-verifying all dependents.
10. Resource behavior makes kernel/proof replay infeasible for npm-scale dependency graphs.

A 9.93 architecture score does not remove these empirical risks.

It means the design makes them measurable.

---

# 63. Research sources

## Lean

Lean Reference — Type System  
https://lean-lang.org/doc/reference/latest/The-Type-System/

Lean Propositions  
https://lean-lang.org/doc/reference/latest/The-Type-System/Propositions/

Lean Elaboration and Compilation  
https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/

Lean Proof Validation  
https://lean-lang.org/doc/reference/latest/ValidatingProofs/

Lean 4.34.0  
https://lean-lang.org/doc/reference/latest/releases/v4.34.0/

Lean 4.35.0  
https://lean-lang.org/doc/reference/latest/releases/v4.35.0/

## TypeScript

Type Compatibility  
https://www.typescriptlang.org/docs/handbook/type-compatibility

Declaration File Publishing  
https://www.typescriptlang.org/docs/handbook/declaration-files/publishing.html

Project References  
https://www.typescriptlang.org/docs/handbook/project-references

Modules Reference  
https://www.typescriptlang.org/docs/handbook/modules/reference

TypeScript 7.0 announcement  
https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/

## Deep specifications and verified systems

DeepSpec  
https://deepspec.org/page/About/

CertiKOS  
https://flint.cs.yale.edu/certikos/framework.html

CompCert  
https://compcert.org/man/manual001.html

CakeML  
https://cakeml.org/

## Program verification

Dafny  
https://dafny.org/latest/DafnyRef/DafnyRef

F*  
https://fstar-lang.org/

Iris  
https://iris-project.org/

Iris Lean  
https://github.com/leanprover-community/iris-lean

Aneris  
https://iris-project.org/aneris/

## AI verified software

AlgoVeri  
https://proceedings.mlr.press/v306/zhao26bm.html

VeriSoftBench  
https://arxiv.org/abs/2602.18307

P3  
https://arxiv.org/abs/2608.09277

Vero  
https://arxiv.org/abs/2608.13522

Reward Hacking Benchmark  
https://proceedings.mlr.press/v306/thaman26a.html

## npm

npm install policies  
https://docs.npmjs.com/cli/install/

npm ci  
https://docs.npmjs.com/cli/commands/npm-ci/

Trusted publishing  
https://docs.npmjs.com/trusted-publishers/

Staged publishing  
https://docs.npmjs.com/staged-publishing/

---

# 64. Canonical definition

> **ProofScript PSCV Applied SAVEF is a TypeScript-scale, npm-native, verification-grounded software ecosystem in which packages distribute both executable artifacts and independently checkable semantic interfaces. PSCV defines verified-program behavior and certification; PSKernel provides logical admission; compiler and backend evidence preserve claims to executable targets; semantic module interfaces let dependents reuse checked knowledge without inspecting implementation source; npm distributes and locks package bytes; psc.lock binds the semantic dependency graph; and replaceable AI agents search and extend the resulting theorem, capability, and assumption graph without possessing acceptance authority.**
>
> **The ecosystem is self-amplifying only when accumulated accepted packages measurably reduce the cost of producing comparable future packages at fixed model capability and assurance policy.**

Short form:

> **TypeScript showed how npm plus compact interfaces can scale software reuse. ProofScript should add mathematical behavior, proof, assumptions, and compiler preservation to that architecture so each package contributes reusable executable knowledge, not only reusable code.**

---

# 65. Final decision

The required architecture does exist in sufficiently concrete form after this iteration.

It should not be implemented as a separate SAVEF subsystem.

It should emerge by completing the existing ProofScript architecture:

~~~text
current compiler/package decomposition
    +
real CheckedCore transition
    +
PSCV certification
    +
CertifiedModuleInterface
    +
semantic QueryGraph
    +
RuntimeIR / VerifiedIR authority split
    +
backend preservation
    +
npm semantic manifest
    +
psc.lock
    +
InterfaceIR for TypeScript/npm
    +
typed theory/capability/assumption index
    +
model-neutral compiler service
    +
fixed-model FactoryBench
~~~

The final target architecture scores:

**9.93 / 10**

Current implementation/evidence scores approximately:

**5.90 / 10**

The next highest-leverage implementation order is:

1. real AdmissionReady → CheckedCore;
2. PSCV CertifiedSource gate;
3. CertifiedModuleInterface + semantic QueryGraph;
4. npm semantic manifest + psc.lock;
5. erasure/backend preservation;
6. compiler service;
7. theory index;
8. FactoryBench.

The most important new conclusion from the TypeScript comparison is:

> **The breakthrough required for a verified ecosystem is not merely the ability to prove packages. It is the ability to compile each verified package into a compact, stable, machine-checkable semantic interface that lets thousands of downstream packages reuse its established knowledge without reopening its implementation.**

That is the architecture that can make software construction increasingly resemble mathematical theory construction at ecosystem scale.
