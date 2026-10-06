# ProofScript PSCV Applied SAVEF — Version 1

**Status:** applied architecture and research plan; non-normative.

**Working identity:** PSCV-APPLIED-SAVEF-v1.

**Research snapshot:** 2026-10-06.

**Primary question**

How can the Self-Amplifying Verified Ecosystem Factory be applied concretely to the existing ProofScript PSCV compiler, kernel, npm-package, and build architecture so that ecosystem growth accumulates machine-checkable software knowledge and measurably reduces the cost of producing the next correct capability?

**Repository context evaluated**

- dwijayuda/pskernel
- branch psc2/selfhost-lean-kernel
- directory psc15selfhost/
- branch psc2/pscv-direct-backends
- branch pscv/prove-pskernel-core-v1
- branch pscv/selfhost-poc-v1
- study/pscv-research/PROOFSCRIPT_SELF_AMPLIFYING_VERIFIED_ECOSYSTEM_FACTORY.md
- study/pscv-research/PROOFSCRIPT_SELF_AMPLIFYING_VERIFIED_ECOSYSTEM_FACTORY_VERSION_2.md

**External systems studied**

- Lean 4, including Lean 4.34 and Lean 4.35.0-rc3
- dependent type theory and propositions-as-types
- DeepSpec / CertiKOS
- CompCert
- CakeML
- F*
- Dafny
- Iris / Aneris
- current verified-code-generation research
- npm package, workspace, lockfile, provenance, staged-publishing, and install-policy mechanisms

This document separates two scores:

1. **Architecture quality** — how coherent, falsifiable, and implementable the target is.
2. **Current implementation/evidence maturity** — what the repository actually demonstrates now.

A high architecture score is not an implementation-completion claim.

---

# 1. Executive verdict

The software-as-mathematics thesis survives deep review, with one necessary correction.

The useful claim is not:

> all software is mathematics.

It is:

> **ProofScript can make an increasing fraction of software engineering behave like construction inside an accumulating formal theory. Definitions, specifications, executable implementations, invariants, theorems, effect laws, refinement relations, compiler-preservation evidence, and explicit assumptions become reusable machine-checkable knowledge.**

Where claims depend on hardware, networks, external services, humans, concrete performance, or other incompletely modeled reality, empirical evidence remains necessary.

Therefore the foundational rule is:

> **Mathematics inside; science at the boundary.**

The applied SAVEF conclusion is:

> **ProofScript should keep npm as the physical package and distribution ecosystem, while PSCV and PSKernel add a semantic, theorem, assumption, and evidence layer over the exact same package graph.**

The target division of responsibility is:

~~~text
npm
    package identity
    versions
    distribution
    workspaces
    dependency resolution
    artifact integrity
    package-lock
    provenance
    staged publication

ProofScript / PSCV
    semantic identity
    formal interface
    approved specifications
    proof obligations
    theorem interface
    assumption closure
    VerifiedIR identity
    backend preservation evidence
    capability metadata

PSKernel
    logical admission authority

AI
    untrusted search
    synthesis
    formalization
    proof construction
    repair
    migration
    generalization
~~~

The strongest finding is that the current psc15selfhost architecture already contains many of the correct seams.

Applied SAVEF should strengthen and connect them rather than build a second compiler, package manager, or proof foundation.

---

# 2. Evaluation loop

The applied architecture was iterated using criteria defined later in this document.

~~~text
Current applied repository evidence:       5.35 / 10
Applied SAVEF iteration A:                 7.76 / 10
Applied SAVEF iteration B / this version:  8.76 / 10
~~~

The accepted architecture clears the requested 8.0 threshold.

All hard-gate architecture criteria score at least 8.2.

The current repository does not implement an 8.76/10 SAVEF.

Current whole-system implementation/evidence maturity remains approximately:

**5.35 / 10**

The strongest existing foundations are:

- compiler package decomposition;
- self-host/bootstrap discipline;
- explicit AdmissionReady naming;
- target-neutral IR direction;
- raw-IR to validated-IR boundary;
- direct JavaScript and Wasm work;
- QueryGraph foundation;
- kernel-provider separation;
- portable PSKernel architecture;
- rapidly improving kernel semantic proof work;
- a detailed PSCV verified-language design.

The weakest or mostly future areas are:

- genuine CheckedCore ownership in the normal compiler path;
- implemented PSCV certificate closure;
- erasure semantic preservation;
- backend semantic preservation or translation validation;
- npm semantic package format;
- semantic lockfile;
- derived theory/capability index;
- model-neutral agent semantic API;
- empirical proof that accumulated ecosystem knowledge makes later work cheaper.

---

# 3. What software as mathematics means

All mainstream programming languages can be given mathematical semantics.

The important difference is how software claims are justified and reused.

Conventional ecosystems mostly accumulate:

~~~text
code
types
tests
benchmarks
documentation
bug history
human experience
~~~

An applied ProofScript ecosystem should additionally accumulate:

~~~text
formal definitions
deep specifications
checked theorems
proof interfaces
effect laws
refinement relationships
assumption closures
semantic compatibility evidence
compiler preservation evidence
structured counterexamples
verified proof patterns
verified implementation patterns
~~~

A useful correspondence is:

| Mathematics | Applied ProofScript |
| --- | --- |
| logical foundation | Lean-grounded PSCV semantics |
| definition | type, protocol, state model, interface |
| proposition | behavioral specification |
| lemma | reusable software fact |
| theorem | checked correctness or refinement result |
| constructive witness | executable implementation |
| theory | ProofScript package |
| imported theory | npm dependency plus checked semantic interface |
| conservative extension | package adds capability without new unproved trust |
| proof checker | PSKernel |
| theorem-library search | derived theorem/capability index |

The analogy becomes economically important when a client can use a dependency's exported theorems without reopening the dependency implementation.

That is how later software becomes cheaper.

---

# 4. Why tests do not disappear

Formal proof is relative to a formal model and assumptions.

Proof may establish:

~~~text
parse(encode(x)) = x
~~~

inside PSCV semantics.

It does not automatically prove:

- a remote service still follows its public API;
- a CPU is defect-free;
- a network satisfies a latency target;
- a user finds a UI understandable;
- an entropy source is strong;
- a cloud provider meets an availability target.

Applied SAVEF therefore distinguishes evidence classes.

| Claim class | Typical strongest evidence |
| --- | --- |
| pure functional property | proof |
| invariant | proof |
| termination | proof |
| finite protocol safety | proof/model checking |
| compiler preservation | proof/translation validation |
| foreign interoperability | conformance/differential evidence |
| throughput/latency | benchmark |
| external-service behavior | contract + tests/monitoring |
| human usability | human evaluation |

The goal is not proof instead of tests.

The goal is:

> **use deductive evidence where the system has precise mathematical semantics, and empirical evidence where it does not.**

---

# 5. Lean 4 lessons that constrain Applied SAVEF

## 5.1 Lean is not an idealized textbook calculus

Lean provides dependent types, inductives, impredicative proof-irrelevant Prop, quotient computation, propositional extensionality, universes, and proof erasure.

The current Lean reference also explicitly notes:

- ordinary subject reduction does not hold;
- algorithmic definitional equality is reflexive and symmetric but not necessarily transitive;
- adversarial inputs can force type-checker nontermination.

These properties do not imply unsoundness.

They do imply that ProofScript cannot prove PSKernel correct merely against an oversimplified textbook calculus.

The robust architecture is:

~~~text
abstract semantic judgments
        +
exact version-pinned Lean-compatible behavior
        +
implementation refinement proofs
        +
differential checking
        +
independent checking at high assurance
~~~

## 5.2 Lean 4.34 soundness lesson

Lean 4.34 closed three routes to a proof of False, including an order-dependent definitional-equality caching bug.

The architectural lesson is:

> **An optimization belongs to the trust analysis whenever a bug in that optimization can change acceptance.**

This applies directly to:

- defeq caches;
- environment indexes;
- native reduction;
- incremental semantic caches;
- compiler optimization;
- proof-search memoization.

## 5.3 Independent proof checking

Lean documents replay using lean4checker for stronger validation.

Applied SAVEF should preserve the same principle:

~~~text
producer
    !=
checker
~~~

For release-critical packages, one designated kernel implementation should eventually be supplemented by an independent checker/replay path.

---

# 6. PSCV already contains the right language concepts

The PSCV reference on psc2/pscv-direct-backends already defines the correct language-level architecture.

Important identities include:

~~~text
pscv-v1
PSCV-VERIFY-v1
PSCV-CERT-v1
pscv-closed-v1
pscv-boundary-v1
~~~

Important semantics already include:

- requires and ensures;
- proof-only assertions;
- loop invariants;
- termination/decreasing obligations;
- ghost state;
- SPEC / PROOF / EXEC relevance;
- proof erasure;
- proof closure;
- specification coverage;
- approved specification identity;
- SpecCapsule linkage;
- anti-weakening rules;
- verified effects through weakest-precondition / Hoare semantics;
- explicit world boundaries;
- verified executable compile gating.

Applied SAVEF should use these concepts instead of inventing a second proof language.

---

# 7. Current psc15selfhost structure

The repository already has the right semantic layers:

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
driver-ts
driver-rust

pskernel-core
pskernel-lean-wasm
pskernel-lean
pskernel
~~~

This architecture should be evolved, not replaced.

AI orchestration, theory indexing, package search, and factory memory must remain outside the minimal semantic/bootstrap closure.

---

# 8. The first critical gap: AdmissionReady is not CheckedCore

The evaluated compiler defines:

~~~text
PsCompilerAdmissionReadyModule
~~~

and currently:

~~~text
psCompilerCheckElaborated
=
psCompilerPrepareElaborated

psCompilerCheckSource
=
psCompilerPrepareSource
~~~

Preparation establishes canonical admission-encoding readiness.

It does not mean a designated kernel accepted the declarations.

The current compiler can continue from prepared declarations into erasure and validated IR.

Therefore the first Applied SAVEF hard law is:

> **No artifact may claim PSCV verified status while the production path is still only AdmissionReady.**

Target:

~~~text
Elaborated CandidateCore
        |
        v
AdmissionReady
        |
        | KernelContract provider
        v
CheckedCore
        |
        | PSCV-CERT-v1
        v
CertifiedSourceModule
        |
        v
Erasure
~~~

The current honest AdmissionReady name is a strength.

The next step is to make the stronger state real.

---

# 9. RuntimeIR and VerifiedIR

The current compiler IR historically contains raw types named PsVerifiedIr, including an unknown type constructor.

The architecture already introduces a better staging concept:

~~~text
PsErasedIrModule
        |
        | psValidateErasedIrModule
        v
PsValidatedIrModule
~~~

Applied SAVEF should complete the physical distinction:

~~~text
RuntimeIR / ErasedIR
        |
        | validateRuntimeIr
        v
VerifiedIR
~~~

Only validated IR may be consumed by verified backend paths.

A raw construction representation must never be called verified solely because of an old type name.

---

# 10. QueryGraph is the seed of the incremental theorem engine

The existing QueryGraph tracks:

~~~text
sourceKey
interfaceKey
dependencyInterfaces
~~~

and can turn modules green/red based on source and dependency-interface changes.

Applied SAVEF should extend this exact mechanism.

Future keys should include equivalents of:

~~~text
sourceKey
elaboratedInterfaceKey
approvedSpecKey
obligationSetKey
checkedCoreKey
theoremInterfaceKey
assumptionClosureKey
verifiedIrKey
backendEvidenceKey[target]
capabilityManifestKey
~~~

Desired behavior:

~~~text
private implementation changed
public theorem/spec interface unchanged

=> downstream remains green
~~~

but:

~~~text
exported theorem weakened
public specification changed
assumption closure changed

=> affected downstream becomes red
~~~

This is one of the most important mechanisms for making formal software economically scalable.

---

# 11. Current PSKernel evidence

The current pscv/prove-pskernel-core-v1 semantic audit intentionally distinguishes semantic strength.

At the evaluated snapshot:

~~~text
A — semantic/refinement:       21
B — reusable theory:           16
C — control/branch assurance:  34
D — shallow/base:               8

Total canonical pairs:         79
~~~

A-level progress now includes important pieces of:

- declaration admission;
- Quot admission;
- expression equality;
- typing/inference;
- reduction;
- checker-state invariants;
- substitution;
- lifting and instantiation;
- semantic environment lookup and mutation.

The audit still lists major missing work such as:

- broader typing refinement;
- reduction closure;
- full definitional-equality soundness;
- full admission/environment extension;
- inductive positivity and recursor correctness;
- end-to-end public KernelContract success implying semantic judgments.

Therefore:

> proof-file presence is not counted as proof completeness.

That policy should remain permanent.

---

# 12. npm should remain the physical ecosystem

ProofScript already uses npm workspaces and npm package manifests.

Existing package manifests include a custom proofscript metadata block with fields such as:

- role;
- bootstrap;
- portable;
- source roots;
- test roots;
- runtime semantic identity.

This is exactly the right direction.

Applied SAVEF should use npm for:

- names;
- versions;
- scoped namespaces;
- distribution;
- workspaces;
- dependency resolution;
- package-lock;
- artifact integrity;
- npm ci;
- provenance;
- trusted publishing;
- staged publishing.

ProofScript adds semantics.

Central rule:

> **npm tells us which bytes we installed; ProofScript tells us what semantic claims those bytes justify.**

---

# 13. One npm package, two ecosystems

Conceptual package:

~~~text
@proofscript/json/
│
├── package.json
├── dist/
│   ├── index.js
│   ├── index.d.ts
│   └── index.wasm
├── src/
│   └── ...
└── proofscript/
    ├── manifest.json
    ├── interface.json
    ├── specifications.json
    ├── assumptions.json
    ├── capabilities.json
    └── evidence/
        └── ...
~~~

JavaScript/TypeScript view:

~~~text
ordinary npm package
~~~

PSCV view:

~~~text
implementation
+ semantic identity
+ formal interface
+ approved specification
+ checked theorem interface
+ assumption closure
+ target evidence
+ capability metadata
~~~

This is a major adoption advantage because JS/TS users do not have to abandon npm.

---

# 14. package.json is a locator, not proof authority

Proposed package entry:

~~~json
{
  "name": "@proofscript/json",
  "version": "3.2.0",
  "proofscript": {
    "schema": "proofscript-package/1",
    "manifest": "./proofscript/manifest.json",
    "manifestIntegrity": "sha256-..."
  }
}
~~~

Forbidden architecture:

~~~json
{
  "proofscript": {
    "verified": true
  }
}
~~~

A package cannot self-declare theorem authority.

Required flow:

~~~text
package.json
    |
    v
semantic manifest
    |
    v
evidence references
    |
    v
independent PSC / PSKernel verification
~~~

---

# 15. Proposed semantic package manifest

Conceptual form:

~~~json
{
  "schema": "proofscript-semantic-package/1",

  "package": {
    "name": "@proofscript/json",
    "version": "3.2.0"
  },

  "semanticProfile": {
    "language": "ps-0.9-r3",
    "profile": "pscv-v1",
    "verification": "PSCV-VERIFY-v1",
    "certificate": "PSCV-CERT-v1",
    "leanVersion": "4.35.0-rc3",
    "leanCommit": "470d5ce1400764999581fd26d5d72b00d990b0f4"
  },

  "publicInterfaceDigest": "sha256-...",
  "specificationDigest": "sha256-...",
  "theoremInterfaceDigest": "sha256-...",
  "assumptionClosureDigest": "sha256-...",
  "verifiedIrDigest": "sha256-...",

  "capabilities": [
    "json.parse",
    "json.encode"
  ]
}
~~~

This is a design example, not a frozen schema.

---

# 16. Semantic identity and npm transport identity must be separate

Do not put the final npm tarball hash inside the tarball it hashes.

Use:

~~~text
SemanticPackageDigest
=
hash(
    semantic profile
    public formal interface
    approved specification
    theorem interface
    assumption closure
    PSCV certificate
    relevant compiler evidence
)
~~~

and separately:

~~~text
NpmArtifactIntegrity
=
integrity hash of published tarball
~~~

A release binds both.

They answer different questions:

~~~text
semantic digest:
    what meaning/evidence is this package claiming?

npm integrity:
    are these the exact package bytes?
~~~

---

# 17. package-lock plus proofscript.lock

Do not modify npm's lockfile semantics.

Use:

~~~text
package-lock.json
    =
exact physical npm dependency tree
+ artifact integrity

proofscript.lock
    =
exact semantic dependency/evidence identities
~~~

Conceptual semantic lock entry:

~~~json
{
  "schema": "proofscript-lock/1",
  "packages": {
    "@proofscript/json@3.2.0": {
      "npmIntegrity": "sha512-...",
      "semanticManifest": "sha256-...",
      "publicInterface": "sha256-...",
      "theoremInterface": "sha256-...",
      "assumptionClosure": "sha256-...",
      "profile": "pscv-v1"
    }
  }
}
~~~

Together:

~~~text
reproducible bytes
+
reproducible semantics
~~~

---

# 18. SemVer must not become a proof rule

Suppose npm declares:

~~~json
"@proofscript/parser": "^2.4.0"
~~~

A proof was established against parser 2.4.3.

Later npm resolves parser 2.9.0.

SemVer says the version is intended to be compatible.

That does not prove semantic compatibility.

Applied SAVEF needs:

~~~text
npm compatibility
    +
ProofScript semantic compatibility
~~~

Early high-assurance mode can pin exact semantic dependencies.

Mature mode can allow a newer implementation if it proves or validates:

~~~text
Parser-2.9.0
    refines
ParserSpec-v3
~~~

Then downstream proof reuse is justified by the semantic interface, not by version-number convention.

---

# 19. Deep specifications are the real package API

A scalable verified ecosystem cannot make every client unfold every dependency.

Packages need rich formal public interfaces.

A package should be able to export:

- public types;
- operations;
- preconditions;
- postconditions;
- effect contracts;
- theorem/law identities;
- assumption requirements;
- resource contracts where useful;
- refinement relationships;
- target support.

Clients prove against the abstract interface.

Implementations prove they satisfy it.

This is the SAVEF version of information hiding.

DeepSpec's idea of specifications being rich, two-sided, formal, and live is directly relevant.

---

# 20. Example: bytes to WebSocket

First:

~~~text
@proofscript/bytes
~~~

exports:

~~~text
ByteArray
slice
concat
get

theorem slice_bounds
theorem concat_length
theorem get_valid
~~~

Then:

~~~text
@proofscript/parser
~~~

uses Bytes and exports:

~~~text
StreamingParser

theorem parser_does_not_read_outside_input
theorem parser_deterministic
theorem successful_parse_consumes_valid_prefix
~~~

Then:

~~~text
@proofscript/json
@proofscript/http
~~~

reuse parser and byte theorems.

Now an AI receives:

> Build a WebSocket package.

The semantic query may return:

~~~text
already available:
    HTTP upgrade
    byte bounds
    streaming parser
    UTF-8
    Base64
    state-machine library

missing:
    WebSocket frame relation
    masking law
    fragmentation invariant
    handshake relation
~~~

The factory works on the missing semantic edges rather than regenerating the whole software stack.

That is practical self-amplification.

---

# 21. Example: foreign PostgreSQL package

Suppose there is no native verified PostgreSQL package.

Use ordinary npm:

~~~json
{
  "dependencies": {
    "pg": "^9.0.0"
  }
}
~~~

Create:

~~~text
@proofscript/bindings-pg
~~~

with:

~~~text
InterfaceIR
typed adapter
transaction model
conformance tests
explicit assumptions
~~~

Possible Assurance Vector:

~~~text
adapter implementation:
    kernel-verified

adapter specification:
    kernel-checked

database model:
    formally defined

foreign pg implementation:
    external

runtime compatibility:
    conformance-tested / monitored
~~~

Later the factory may replace the foreign dependency with:

~~~text
@proofscript/postgres
~~~

and strengthen the assurance.

This is a realistic migration path because ProofScript does not need to rebuild npm before becoming useful.

---

# 22. Progressive assurance

Recommended claim levels:

| Level | Meaning |
| --- | --- |
| External | foreign code; explicit boundary |
| Typed | interface checked |
| Characterized | tests/differential behavior recorded |
| Contracted | formal behavioral contract |
| Validated | independent validation/model evidence |
| KernelVerified | formal claim admitted by kernel |
| ArtifactPreserved | backend relation to executable artifact established |
| BoundaryAssured | external assumptions also monitored/validated |

Different claims within one npm package may have different levels.

---

# 23. Install scripts are a trust boundary

npm dependencies may execute lifecycle scripts.

A high-assurance build cannot silently run arbitrary install code and then claim a pristine verification environment.

Preferred pscv-closed policy:

~~~text
npm ci --ignore-scripts
~~~

or an equivalent explicit allowlist.

For pscv-boundary:

~~~text
install script
=
declared host/supply-chain capability
~~~

The install policy becomes part of release evidence.

---

# 24. Publishing architecture

npm staged publishing is unusually compatible with SAVEF.

Target:

~~~text
Git commit
    |
    v
frozen npm install
    |
    v
PSC compile
    |
    v
PSKernel replay
    |
    v
PSCV certificate
    |
    v
erasure / IR validation
    |
    v
backend preservation validation
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
independent ProofScript verification
    |
    v
human/policy approval
    |
    v
npm stage approve
    |
    v
published package + provenance
~~~

This separates candidate production from release authority.

---

# 25. Future psc publish

User-facing command:

~~~text
psc publish
~~~

may orchestrate:

~~~text
psc check
psc certify
psc build
psc verify-backend
psc package-evidence
npm pack
npm stage publish
psc verify-staged
npm stage approve
~~~

The workflow can be simple without collapsing the underlying assurance stages.

---

# 26. Content-addressed checked-package cache

At npm scale, replaying every proof on every build is too expensive.

Use semantic-content keys:

~~~text
~/.proofscript/store/<semantic-digest>/
    checked-interface
    theorem-interface
    assumption-closure
    validated-evidence
~~~

If exact semantic content was already checked:

~~~text
reuse result
~~~

For high assurance:

~~~text
psc verify --replay-all
~~~

The cache is an optimization.

It never creates theorem authority.

---

# 27. Compiler semantic service

All human and AI tooling should use one compiler semantic service.

Candidate operations:

~~~text
parse
elaborate
typeOf
goalState
obligations
specificationCoverage
assumptionClosure
candidateCore
admissionPayload
checkedCore
certifiedSource
verifiedIr
semanticDiff
dependencySlice
affectedProofs
capabilitySearch
buildPlan
~~~

LSP, CLI, package tooling, IDEs, and AI agents should not independently reproduce language semantics.

---

# 28. AI position in the architecture

AI may:

- propose specifications;
- generate code;
- generate proof terms;
- query theorem/capability indexes;
- repair rejected candidates;
- generate adapters;
- propose migrations;
- propose generalized lemmas/tactics.

AI may not:

- construct CheckedCore;
- mint a proof certificate;
- weaken an approved specification while retaining identity;
- disable required checks;
- change acceptance policy;
- decide its own benchmark success.

The desired rule is:

> **maximum generation freedom, minimum acceptance freedom.**

---

# 29. Why current AI research supports this design

## Verification-language ergonomics

Current verified-code-generation benchmarks show that language abstraction and automation materially affect success.

Applied implication:

> PSCV needs high-level contracts, VC generation, proof libraries, and proof-producing automation rather than requiring every agent to manually construct low-level Lean proof terms.

## Repository context

Repository-scale proof benchmarks show that larger relevant dependency closures make verification harder, while curated context helps.

Applied implication:

> QueryGraph dependency slices and theorem-interface retrieval are strategic infrastructure.

## Joint program/proof planning

Current research finds value in planning implementation and proof together.

Applied implication:

> proofability should influence API and algorithm design before code generation is complete.

## Repository-scale synthesis is still difficult

Current multi-module verified-code benchmarks are not solved reliably.

Applied implication:

> SAVEF should be designed as an evidence-driven production system, not marketed as solved autonomous general software engineering.

---

# 30. Effects and real software

Pure functions alone cannot support a full ecosystem.

PSCV's direction toward:

~~~text
pure
state
reader
typed error
~~~

through weakest-precondition / Hoare semantics is appropriate.

Future semantics for:

- resources;
- heap ownership;
- aliasing;
- async;
- concurrency;
- distributed protocols;
- randomness;
- security

should usually live in versioned libraries/program logics.

F* demonstrates extensible effect reasoning and weakest-precondition verification.

Iris demonstrates powerful concurrent resource reasoning as a library logic rather than a kernel feature.

Aneris provides relevant distributed reasoning precedent.

---

# 31. Compilation is part of the theorem chain

A theorem about PSCV source is not automatically a theorem about JavaScript or Wasm.

The complete high-assurance argument resembles:

~~~text
Source satisfies P
    AND
Erasure preserves required behavior
    AND
RuntimeIR validation is sound
    AND
Backend lowering preserves semantics
    AND
Target/runtime assumptions hold
-----------------------------------------
Artifact satisfies P
~~~

CompCert demonstrates composition of semantic-preservation proofs across compiler passes.

CakeML demonstrates that formal semantics, verified compilation, and bootstrapping can coexist.

Applied SAVEF may use different mechanisms per transformation:

- formal proof;
- proof-producing transformation;
- translation validator;
- explicitly lower assurance evidence.

What is forbidden is silently claiming a stronger assurance level than the pass has established.

---

# 32. BackendPreservationContract

Every backend should eventually have a versioned contract equivalent in purpose to:

~~~text
BackendPreservationContract {
    sourceIrSemantics
    targetSemantics
    supportedFeatureClosure
    observableBehaviorRelation
    proofOrValidatorIdentity
    unsupportedCasePolicy
    resourcePolicy
}
~~~

Direct Wasm is an attractive high-assurance target.

Direct JavaScript should prefer a small canonical output subset when possible.

TypeScript and Rust remain valuable adapter/differential paths.

---

# 33. TheoryManifest is derived, not authoritative

A TheoryManifest can expose:

~~~text
capabilities
public specs
theorem identities
assumption closure
target support
refinement relationships
evidence links
~~~

But it must be rebuildable from actual checked artifacts.

If the index disagrees with the evidence, the index loses.

This prevents the semantic package registry from becoming a second trusted proof system.

---

# 34. Typed Ecosystem Knowledge Graph

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
replaces
compatible-with
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

The graph index itself is not part of logical authority.

---

# 35. Successful work must create reusable knowledge

A factory result should ideally be:

~~~text
requested package
+
reusable formal knowledge
~~~

Reusable outputs may include:

- theorem;
- invariant;
- deep specification;
- effect law;
- generic refinement;
- proof tactic;
- implementation pattern;
- counterexample;
- failed proof strategy;
- adapter;
- benchmark model.

This is the mechanism by which ecosystem growth can make the next task cheaper.

---

# 36. Failure memory

A failed proof can become:

~~~text
FailureKnowledge {
    semanticProfile
    obligationShape
    dependencySlice
    attemptedStrategy
    checkerOutcome
    counterexample
    successfulRepair
}
~~~

Example:

~~~text
Known:
    amount <= balance
    fee >= 0

Need:
    balance - amount - fee >= 0
~~~

The failure may reveal the stronger required precondition:

~~~text
amount + fee <= balance
~~~

Then the factory can produce:

- a better contract;
- a reusable theorem;
- a future repair pattern.

Failures become knowledge instead of disappearing into agent logs.

---

# 37. Self-amplification must be falsifiable

Self-amplification is not demonstrated by a better model.

The correct benchmark holds model capability approximately fixed:

~~~text
same model
same settings
same compute budget
same task distribution
same acceptance policy

Factory N
vs
Factory N+1 with more accepted reusable knowledge
~~~

Evidence for amplification:

- higher accepted-task success;
- fewer tokens;
- fewer repair iterations;
- fewer human interventions;
- less original low-level code;
- greater theorem/spec/capability reuse;
- equal or stronger assurance.

If these effects do not appear, the factory is not self-amplifying.

---

# 38. Provable / disprovable criteria

These criteria are intended to be machine-checkable or experimentally falsifiable.

## C1 — Semantic identity closure

**Claim**

Every authoritative proof, certificate, and semantic cache result is bound to an exact semantic profile.

**Evidence**

Canonical SemanticProfileIdentity and digest.

**Pass test**

Change one meaning-relevant field such as Lean pin, PSCV verification identity, Standard environment, kernel contract, runtime semantics, or IR schema.

Previous evidence becomes invalid unless explicit compatibility evidence exists.

**Failure witness**

Old evidence remains authoritative across a meaning change.

**Weight:** 8.

---

## C2 — Authority-state separation

Required order:

~~~text
CandidateCore
<
AdmissionReady
<
CheckedCore
<
CertifiedSource
<
VerifiedIR
<
PreservedTargetArtifact
~~~

**Pass test**

Attempt verified code emission from AdmissionReady.

The build must fail.

**Failure witness**

Any public backend path accepts pre-kernel state as verified input.

**Weight:** 8.

---

## C3 — Kernel semantic refinement

**Claim**

Successful PSKernel public operations refine independently stated semantic judgments.

**Evidence**

Metatheory, refinement theorems, audit, differential checking, and high-assurance independent replay.

**Pass target**

Every public accepted KernelContract path used by PSCV has an end-to-end semantic theorem at the declared assurance tier.

**Failure witness**

A public accepted path is justified only by wrapper/control lemmas.

**Weight:** 8.

---

## C4 — PSCV proof/specification closure

**Claim**

No unresolved mandatory proof, specification, effect, or assumption obligation can produce a PSCV verified executable.

**Pass test**

Insert one unproved required postcondition into reachable code.

Verified emission must fail.

**Failure witness**

Artifact remains PSCV-certified.

**Weight:** 8.

---

## C5 — Erasure and IR preservation

**Claim**

SPEC/PROOF erasure and RuntimeIR validation preserve required EXEC behavior.

**Pass test**

Construct a candidate where ghost state influences runtime branching.

Certification must reject.

**Failure witness**

Proof/ghost information changes observable runtime behavior.

**Weight:** 7.

---

## C6 — Backend preservation

**Claim**

A PreservedTargetArtifact has accepted evidence connecting target behavior to VerifiedIR.

**Pass test**

Mutate backend output to change an observable result.

Preservation validation must fail.

**Failure witness**

Mutated artifact remains classified preserved.

**Weight:** 7.

---

## C7 — npm semantic package integrity

**Claim**

Package metadata alone cannot create verification authority.

**Pass test**

Edit a package manifest to claim a stronger assurance state without changing proof evidence.

No assurance level may increase.

**Failure witness**

An author-written verified flag is accepted as proof.

**Weight:** 7.

---

## C8 — Semantic dependency compatibility

**Claim**

Proof dependency compatibility is based on semantic interfaces, not npm SemVer alone.

**Pass test**

Update a dependency within its SemVer range while changing a relied-upon specification.

Dependent module must turn red.

After accepted refinement/compatibility evidence, it may become green again.

**Weight:** 6.

---

## C9 — Transitive assumption closure

**Claim**

Every top-level assurance claim exposes all relevant assumptions from dependencies.

**Pass test**

Add a foreign capability to a transitive dependency.

Top-level assumption closure must change.

**Failure witness**

The new boundary remains hidden.

**Weight:** 6.

---

## C10 — Incremental semantic invalidation

**Pass tests**

1. Private implementation change with stable theorem/spec interface -> downstream stays green.
2. Public theorem/spec change -> affected downstream turns red.

**Weight:** 6.

---

## C11 — AI and acceptance separation

**Claim**

An agent cannot redefine the criterion used to judge its own candidate.

**Pass test**

Agent attempts to weaken an approved spec, disable verification, or modify evaluation policy.

The attempt must fail or create an explicit new revision requiring independent approval.

**Weight:** 6.

---

## C12 — Self-amplification evidence

**Claim**

Accepted ecosystem knowledge improves future production with model capability held fixed.

**Required experiment**

Pinned model, settings, task distribution, compute budget, and acceptance policy.

**Pass evidence**

Statistically meaningful improvement in at least two of:

- success rate;
- human time;
- token/compute cost;
- repair count;
- reuse rate;

with no assurance regression.

**Weight:** 6.

---

## C13 — Progressive foreign interoperability

**Pass test**

Wrap an unverified npm library with verified adapter code.

Adapter may become KernelVerified.

Foreign implementation must remain External or Boundary unless separately validated.

**Weight:** 5.

---

## C14 — Reproducible release provenance

**Evidence**

- package-lock;
- semantic lock;
- npm ci;
- semantic package digest;
- npm artifact integrity;
- trusted publishing/provenance;
- staged-package independent replay for high assurance.

**Pass test**

Download exact staged tarball and independently replay all required evidence before release.

**Weight:** 5.

---

## C15 — Resource / denial-of-service correctness

**Claim**

Resource exhaustion cannot become semantic acceptance.

**Pass test**

Exceed configured kernel/reduction/source limits.

Outcome must be resource exhaustion/rejection, never accepted.

**Weight:** 4.

---

## C16 — Bootstrap claim discipline

**Claim**

Self-host fixed point, compiler correctness, kernel soundness, and reproducibility remain separate claims.

**Pass test**

A fixed-point result alone must not produce a compiler-correctness assurance label.

**Weight:** 3.

---

# 39. Criterion score scale

~~~text
0
    no architecture or contradicts criterion

2
    acknowledged only in prose

4
    partial architecture or isolated mechanism exists

6
    coherent architecture plus meaningful partial implementation/tests

8
    complete enforceable architecture
    precise evidence/gates
    representative implementation path exists

9
    broad implementation/evidence coverage
    adversarial and independent validation

10
    mature end-to-end assurance
    independent reproduction
    no known material gap inside declared scope
~~~

Hard-gate criteria:

~~~text
C1
C2
C3
C4
C5
C6
C7
~~~

The final target architecture requires all hard gates at or above 8.

---

# 40. Current repository evidence score

| Criterion | Weight | Current evidence score |
| --- | ---: | ---: |
| C1 semantic identity | 8 | 8.0 |
| C2 authority states | 8 | 5.5 |
| C3 kernel refinement | 8 | 6.5 |
| C4 PSCV closure | 8 | 4.5 |
| C5 erasure/IR preservation | 7 | 5.0 |
| C6 backend preservation | 7 | 4.5 |
| C7 npm semantic integrity | 7 | 4.0 |
| C8 semantic dependency compatibility | 6 | 5.5 |
| C9 assumption closure | 6 | 5.0 |
| C10 incremental invalidation | 6 | 7.0 |
| C11 AI separation | 6 | 3.0 |
| C12 amplification evidence | 6 | 2.0 |
| C13 foreign interop | 5 | 5.5 |
| C14 provenance | 5 | 6.5 |
| C15 resource behavior | 4 | 6.0 |
| C16 bootstrap discipline | 3 | 8.5 |

Weighted evidence score:

**5.35 / 10**

Interpretation:

> The repository has strong semantic/compiler/kernel foundations, but the SAVEF ecosystem contract is still mostly ahead of implementation.

---

# 41. Applied SAVEF iteration A

Iteration A adds:

- exact semantic-profile binding;
- real CheckedCore target state;
- PSCV certificate state;
- npm semantic manifest;
- semantic lock;
- assumption closure;
- theory manifest;
- compiler semantic service;
- QueryGraph semantic keys.

Score:

**7.76 / 10**

It does not clear the target because:

- backend preservation remains too weak;
- independent kernel checking is not integrated strongly enough;
- self-amplification measurement is not sufficiently frozen;
- staged release verification is incomplete;
- agent reward-hacking controls need stricter authority separation.

---

# 42. Applied SAVEF iteration B

Iteration B adds:

1. BackendPreservationContract.
2. PreservedTargetArtifact as a separate state.
3. High-assurance independent checker tier.
4. Exact staged npm tarball replay.
5. Frozen agent-evaluation policy.
6. Fixed-model FactoryBench.
7. Theorem/spec semantic invalidation through QueryGraph.
8. Install-script capability policy.
9. Progressive foreign assurance labels.
10. Explicit resource-exhaustion outcomes.

Final architecture score:

**8.76 / 10**

Hard gates:

~~~text
C1  9.0
C2  9.0
C3  8.5
C4  9.0
C5  8.3
C6  8.2
C7  9.2
~~~

All clear 8.

---

# 43. Final architecture scores

| Criterion | Target |
| --- | ---: |
| C1 semantic identity | 9.0 |
| C2 authority states | 9.0 |
| C3 kernel refinement | 8.5 |
| C4 PSCV closure | 9.0 |
| C5 erasure/IR preservation | 8.3 |
| C6 backend preservation | 8.2 |
| C7 npm semantic integrity | 9.2 |
| C8 semantic dependency compatibility | 8.8 |
| C9 assumption closure | 9.0 |
| C10 incremental invalidation | 9.0 |
| C11 AI separation | 8.8 |
| C12 amplification measurement | 8.5 |
| C13 progressive interop | 9.0 |
| C14 release provenance | 8.5 |
| C15 resource behavior | 8.5 |
| C16 bootstrap discipline | 8.5 |

Weighted target architecture:

**8.76 / 10**

---

# 44. Recommended repository evolution

Do not reorganize everything.

Preserve:

~~~text
foundation/
syntax/
core/
environment/
meta/
elab/
bridge/
compiler-ir/
erasure/
compiler/
project/

pskernel-core/
pskernel-lean-wasm/
pskernel-lean/

backend-js/
backend-wasm/
backend-ts/
backend-rust/

bootstrap/
cli/
~~~

Add semantic authority packages only where an actual boundary requires them.

Recommended target packages:

~~~text
kernel-contract/
checked-core/
pscv-spec/
pscv-obligation/
pscv-cert/
runtime-ir/
verified-ir/
evidence-core/
~~~

Platform/ecosystem packages:

~~~text
interface-ir/
package-manifest/
theory-manifest/
semantic-lock/
compiler-service/
artifact-codec/
artifact-store/
capability-index/
~~~

AI/factory packages:

~~~text
agent-protocol/
factory-orchestrator/
factory-memory/
factory-generalizer/
factory-bench/
model-router/
~~~

The AI/factory packages must remain outside:

- PSKernel;
- CheckedCore construction;
- PSCV certificate authority;
- the IR validator authority;
- the minimal self-host bootstrap closure.

---

# 45. Target dependency direction

~~~text
AI / IDE / CLI / package tooling
              |
              v
        compiler-service
              |
              v
      frontend / PSCV spec
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
              v
            erasure
              |
              v
          runtime-ir
              |
              v
          verified-ir
          /    |    \
         v     v     v
      JS      Wasm  adapters
         \     |     /
      preservation evidence
              |
              v
         evidence-core
              |
              v
       theory-manifest
              |
              v
       capability-index
~~~

Forbidden authority edges:

~~~text
agent -> CheckedCore
package metadata -> theorem authority
backend -> frontend semantic mutation
test -> proof
SemVer -> theorem compatibility
fixed point -> compiler correctness
cache -> new theorem
registry -> proof authority
~~~

---

# 46. Implementation order

## Applied-0 — identity and state schemas

Freeze:

- SemanticProfileIdentity;
- AssuranceVector;
- criterion evidence records.

## Applied-1 — real checked-source path

Implement:

~~~text
AdmissionReady
    -> KernelContract
    -> CheckedCore
~~~

Then make PSCV erasure accept only CheckedCore or stronger.

## Applied-2 — PSCV certificate

Implement:

- obligation set;
- proof closure;
- specification coverage;
- effect closure;
- assumption policy;
- CertifiedSourceModule.

## Applied-3 — RuntimeIR / VerifiedIR separation

Physically separate construction IR from validated executable IR.

## Applied-4 — npm semantic package v1

Specify:

- package.json proofscript locator;
- semantic manifest;
- proofscript.lock;
- evidence directory;
- verification command;
- install-script policy.

## Applied-5 — semantic QueryGraph

Add specification, theorem-interface, assumption, CheckedCore, and backend evidence keys.

## Applied-6 — backend preservation

Prioritize direct Wasm and direct JavaScript.

## Applied-7 — compiler service / AgentProtocol

Expose deterministic semantic queries.

## Applied-8 — theory/capability index

Generate only from checked package artifacts.

## Applied-9 — progressive npm ecosystem ingestion

Start with high-reuse components:

- bytes;
- parser combinators;
- JSON;
- URL;
- HTTP;
- crypto boundaries;
- database adapters.

## Applied-10 — FactoryBench

Measure fixed-model ecosystem amplification.

Do not make strong self-amplification claims before this experiment exists.

---

# 47. Example future developer flow

Developer writes:

~~~text
function transfer(from, to, amount)
requires amount <= from.balance
ensures result.total = old(total)
ensures result.from.balance = old(from.balance) - amount
ensures result.to.balance = old(to.balance) + amount
{
    ...
}
~~~

The system:

1. elaborates;
2. creates exact PSCV obligations;
3. retrieves reusable arithmetic/account theorems;
4. AI/tactics propose evidence;
5. PSKernel accepts or rejects;
6. PSCV-CERT checks proof/spec/effect/assumption closure;
7. erasure produces RuntimeIR;
8. validation produces VerifiedIR;
9. direct JS/Wasm emits target code;
10. backend preservation is checked;
11. npm package is staged;
12. exact staged tarball is independently replayed;
13. release is approved.

The published package can expose:

~~~text
capability:
    Payment.transfer

theorem interface:
    transfer_total_preserved
    transfer_sender_delta
    transfer_receiver_delta

assumptions:
    DatabaseAtomicityContract

targets:
    javascript
    wasm
~~~

A later refund package can reuse these results directly.

---

# 48. What would falsify Applied SAVEF?

The hypothesis should be revised or rejected if repeated experiments show:

1. formal specification cost grows faster than reuse benefits;
2. proof maintenance costs more than the failures it prevents;
3. semantic/theorem retrieval does not improve AI success over source retrieval;
4. checked public theorem interfaces are too unstable under realistic refactoring;
5. backend-preservation work dominates application development;
6. fixed-model FactoryBench does not improve as accepted knowledge grows;
7. ordinary developers routinely need low-level theorem-prover expertise;
8. foreign ecosystem integration remains too expensive to compete with existing npm development.

A falsifiable factory thesis is stronger than an aspirational slogan.

---

# 49. Next specifications to create

Recommended sequence:

1. PROOFSCRIPT_PSCV_SEMANTIC_ARTIFACT_STATES.md
2. PROOFSCRIPT_NPM_PACKAGE_FORMAT_V1.md
3. PROOFSCRIPT_SEMANTIC_LOCK_V1.md
4. PROOFSCRIPT_PSCV_SOFTWARE_MATHEMATICS_COVERAGE_MAP.md
5. PROOFSCRIPT_BACKEND_PRESERVATION_CONTRACT_V1.md
6. PROOFSCRIPT_AGENT_PROTOCOL_V1.md
7. PROOFSCRIPT_THEORY_MANIFEST_V1.md
8. PROOFSCRIPT_FACTORYBENCH_V1.md

The highest immediate leverage is:

~~~text
Semantic Artifact States
+
npm Package Format
+
Semantic Lock
~~~

because those connect the current compiler directly to a reusable verified ecosystem.

---

# 50. Research anchors

## Lean

https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/

https://lean-lang.org/doc/reference/latest/The-Type-System/

https://lean-lang.org/doc/reference/latest/The-Type-System/Propositions/

https://lean-lang.org/doc/reference/latest/ValidatingProofs/

https://lean-lang.org/doc/reference/latest/releases/v4.34.0/

https://lean-lang.org/doc/reference/latest/releases/v4.35.0/

## Deep specifications and verified systems

https://deepspec.org/page/About/

https://flint.cs.yale.edu/certikos/framework.html

https://compcert.org/man/manual001.html

https://compcert.org/doc/

https://cakeml.org/

## Effectful verification

https://fstar-lang.org/tutorial/book/intro.html

https://fstar-lang.org/tutorial/book/part4/part4_pure.html

https://iris-project.org/

https://iris-project.org/aneris/

https://dafny.org/dafny/DafnyRef/DafnyRef

## Current AI verified-code research

https://proceedings.mlr.press/v306/zhao26bm.html

https://arxiv.org/abs/2602.18307

https://arxiv.org/abs/2608.09277

https://arxiv.org/abs/2608.13522

https://proceedings.mlr.press/v306/zhao26ax.html

https://proceedings.mlr.press/v306/thaman26a.html

## npm

https://docs.npmjs.com/files/package-lock.json/

https://docs.npmjs.com/cli/commands/npm-ci/

https://docs.npmjs.com/trusted-publishers/

https://docs.npmjs.com/staged-publishing/

https://docs.npmjs.com/cli/install/

---

# 51. Canonical Applied SAVEF definition

> **ProofScript PSCV Applied SAVEF is an architecture in which ordinary npm packages become carriers of executable code plus independently checkable semantic knowledge. PSCV defines what verified source means; PSKernel admits logical evidence; compiler and backend preservation connect checked source to executable artifacts; npm distributes exact package bytes; semantic manifests and locks bind packages to checked interfaces, theorems, assumptions, and evidence; and AI uses a derived typed knowledge graph to synthesize the semantic capabilities that are still missing.**
>
> **The system is self-amplifying only when accumulated accepted packages measurably reduce the human or compute cost of producing comparable future packages while model capability and assurance policy are held approximately fixed.**

Short form:

> **Use npm to distribute software; use PSCV and PSKernel to turn the npm dependency graph into an accumulating graph of machine-checkable software knowledge; use AI to compose that knowledge faster than it could be recreated manually.**

---

# 52. Final decision

Applied SAVEF should be an evolution of the current architecture:

~~~text
existing npm workspace
+
existing PSC compiler package decomposition
+
real AdmissionReady -> CheckedCore transition
+
PSCV certification
+
strong erasure/IR/backend preservation
+
semantic npm package metadata
+
semantic lock
+
extended QueryGraph
+
derived theorem/capability index
+
replaceable AI agents
~~~

This target scores **8.76 / 10** because it is:

- grounded in actual repository structures;
- compatible with the existing PSCV design;
- compatible with npm rather than replacing it;
- falsifiable through explicit criteria;
- incremental rather than a rewrite;
- explicit about proof versus tests versus assumptions;
- strict about source proof versus compiled-artifact assurance;
- model-agnostic and therefore resilient to rapid AI change.

Current implementation maturity remains approximately **5.35 / 10**.

The next three concrete gaps to close are:

1. real AdmissionReady to CheckedCore ownership;
2. machine-enforced PSCV certificate states;
3. ProofScript npm semantic package and semantic lock formats.

Closing those three boundaries would turn SAVEF from a research architecture into an executable ecosystem contract.
