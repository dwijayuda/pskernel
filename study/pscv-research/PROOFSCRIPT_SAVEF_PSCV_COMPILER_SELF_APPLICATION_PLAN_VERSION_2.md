# ProofScript SAVEF PSCV Compiler Self-Application Plan — Version 2

**Status:** research, architecture, implementation, and experimental plan; non-normative.

**Working identity:** SAVEF-COMPILER-SELFAPP-v2.

**Research snapshot:** 2026-10-06.

**Target architecture/plan score:** **9.59 / 10**

**Current repository readiness for the complete experiment:** **approximately 5.72 / 10**

**Repository:** dwijayuda/pskernel

**Primary PSCV implementation baseline:** branch psc2/pscv-direct-backends, directory psc15selfhost/

**Supporting branches:**

- pscv/prove-pskernel-core-v1
- pscv/selfhost-poc-v1

**Critical assumption for this plan:**

> Do not wait for the current self-host PSCV compiler to implement every PSCV language feature. Treat the pinned Lean compiler as the immediate reference/bootstrap compiler for the PSCV Lean subset. Assume the PSCV language surface required by the experiment is available through Lean and can be compiled to native executables now.

This assumption changes the implementation strategy substantially.

SAVEF infrastructure, proof sidecars, compiler passes, FactoryBench tooling, semantic interfaces, and new compiler architecture may be written in the PSCV-compatible Lean subset and compiled by Lean immediately. The current self-host compiler becomes one implementation lane that later converges on the same semantic contracts.

---

# 1. Executive decision

The strongest way to prove SAVEF works is:

> Use SAVEF to improve, specify, prove, rebuild, and then evolve the PSCV compiler itself, while measuring whether the compiler becomes cheaper to improve as accepted compiler knowledge accumulates.

The experiment has two separate goals.

## Goal A — verified compiler architecture

Transform the compiler into a system where every important semantic stage has:

- an explicit input artifact;
- an explicit output artifact;
- a versioned pass identity;
- a machine-checkable invariant;
- an explicit preservation/refinement relation;
- proof or validation evidence;
- a deterministic content identity;
- a stable public semantic interface;
- incremental invalidation rules.

## Goal B — prove SAVEF's compounding hypothesis

Show experimentally that:

~~~text
same model
same tool policy
same compiler-task distribution
same assurance gates
same resource budget

larger accepted compiler knowledge graph
    =>
higher accepted-task success
or
lower model tokens
or
lower human intervention
or
lower proof repair cost
or
lower duplicated code/proof effort
~~~

without reducing assurance.

The compiler is both the system being built and the knowledge factory used to build its next version.

---

# 2. The most important revision from Version 1

Version 1 treated the present 55-module self-host compiler as the primary implementation subject and tried to preserve that closure while adding proof knowledge around it.

Version 2 keeps that useful experiment but removes an unnecessary dependency:

> SAVEF does not need to wait for the self-host compiler feature frontier.

Because PSCV is intentionally a subset/profile of Lean semantics, and because the experiment assumes the required PSCV subset already compiles through Lean, the architecture should use Lean as a reference bootstrap/compiler lane immediately.

The new architecture has three compiler lanes.

~~~text
                    PSCV SOURCE / COMPILER SOURCE
                              |
              +---------------+---------------+
              |               |               |
              v               v               v
      Lean Reference      PSCV Semantic    Self-host/Direct
          Lane               Lane              Lane
              |               |               |
      Lean elaborator      owned parser/    JS / Wasm /
      + kernel + LCNF      elab/Core/IR      future native
      + native codegen         |               |
              |               |               |
              +---------------+---------------+
                              |
                              v
                   shared semantic contracts
                              |
                              v
                         SAVEF knowledge
~~~

The lanes may produce different executables.

They must converge on shared semantic identities and evidence relations.

---

# 3. Why Lean is the correct bootstrap lane

Lean's processing pipeline separates parsing, macro expansion, elaboration, kernel checking, and compilation.

The trusted kernel checks elaborated core declarations independently from the compiler.

The compiler then transforms computational content into executable code. The compiler and kernel are deliberately distinct subsystems.

This is exactly the separation PSCV needs.

Research source:
https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/

---

# 4. Lean's recursion split is especially relevant

Lean elaborates a recursive function to a pre-definition.

The compiler receives a computational form retaining programmer-oriented recursion needed for predictable execution.

The kernel receives a logically justified form where recursion has been transformed into primitive recursors, well-founded recursion, or another accepted logical construction.

Architectural principle:

> The representation best suited to logical checking does not have to be the representation best suited to compilation.

PSCV should preserve this distinction.

SAVEF knowledge should explicitly state which semantic relation connects logical checked source and runtime-oriented compiler representation rather than requiring them to be physically identical.

---

# 5. Lean compiler architecture lessons

The modern Lean compiler uses Lean Compiler Normal Form, LCNF, as its primary compiler IR.

Lean 4.30 completed end-to-end C code generation through the new LCNF backend.

LCNF is based on A-normal form and has explicit phase distinctions and a pass manager.

Research sources:

- https://lean-lang.org/doc/reference/latest/releases/v4.30.0/
- https://lean-lang.org/doc/api/Lean/Compiler/LCNF/Basic.html
- https://lean-lang.org/doc/api/Lean/Compiler/LCNF/PassManager.html
- https://lean-lang.org/doc/api/Lean/Compiler/LCNF/Passes.html

The architectural lessons are more important than copying LCNF syntax.

---

# 6. Lean lesson: explicit semantic phases

LCNF distinguishes states where different compiler transformations are legal.

Its IR carries purity information, separating pure code from generally impure code. Lean's pass structure records the input phase, output phase, and a monotonic phase-transition invariant.

Applied lesson:

> PSCV should stop treating all executable IR values as one undifferentiated representation.

The current distinction between PsErasedIrModule and PsValidatedIrModule is a good start.

Version 2 extends that idea to every major transformation.

---

# 7. Lean lesson: pass-oriented compiler architecture

Lean's LCNF pipeline exposes named compiler passes such as:

- simplification;
- common-subexpression elimination;
- specialization;
- monomorphization;
- lambda lifting;
- closure analysis;
- borrow inference;
- explicit boxing;
- explicit reference counting;
- reset/reuse expansion;
- dead-code/branch elimination;
- visibility analysis;
- topological sorting.

Each transformation is a named compiler operation rather than hidden behavior inside a backend.

Applied lesson:

> A SAVEF compiler pass should be a first-class semantic object.

Every PSCV pass should be able to answer:

~~~text
what phase do I accept?
what phase do I produce?
what invariants do I require?
what invariants do I establish?
what observable semantics do I preserve?
what validator/proof supports that claim?
what resources may I consume?
what implementation produced this artifact?
~~~

---

# 8. Lean lesson: compiler artifacts are split by purpose

Lean/Lake distinguishes module facets such as:

~~~text
.olean
    elaboration/import semantic data

.ilean
    editor/LSP metadata

.ir / .ir.sig / .c
    compilation artifacts

.o / shared library
    executable artifacts
~~~

This is a useful architectural pattern.

Applied PSCV design:

~~~text
CertifiedModuleInterface
    semantic public interface

EditorIndex
    IDE/navigation data, non-authoritative

CompilerPhaseArtifact
    internal compiler-pass state

SPKF KnowledgeRoot
    reusable semantic knowledge

ExecutableArtifact
    JS / Wasm / native

EvidenceEnvelope
    relations/proofs/provenance
~~~

Do not use one cache object as all of:

- public semantic interface;
- IDE index;
- compiler IR;
- executable;
- proof certificate.

---

# 9. Lean lesson: bootstrapping must be staged

Lean uses stage0 bootstrap material, then rebuilds later stages until compiler effects have propagated and a stable stage is reached.

The Lean development documentation explains that later stages are needed when compiler/meta changes must influence compilation of the compiler itself, with an additional stage acting as a sanity/fixed-point check.

Research source:
https://github.com/leanprover/lean4/blob/master/doc/dev/bootstrap.md

Applied PSCV/SAVEF model:

~~~text
R0
Lean reference compiler

R1
SAVEF/PSCV compiler source compiled by Lean

R2
owned PSCV compiler compiles the same semantic compiler source

R3
self-host compiler reproduces semantic artifacts

R4
SAVEF-assisted compiler evolution creates new accepted knowledge

R5
later compiler generation reuses R4 knowledge
~~~

Each stage proves a different property.

---

# 10. Lean lesson: implementation can change without changing semantics

Lean's frontend and compiler are themselves bootstrapped programs.

The semantics of Lean are not defined by one particular native binary.

Applied PSCV rule:

~~~text
PSCV semantic profile
    stable

compiler implementation
    replaceable

compiler executable identity
    provenance/evidence
~~~

This permits several implementations:

- Lean-hosted reference compiler;
- current self-host PSC compiler;
- direct JavaScript compiler;
- direct Wasm compiler;
- future native PSCV compiler.

All should implement the same semantic contracts.

---

# 11. Lean lesson: caches need complete semantic inputs

Lean's 2026 incremental/cache work demonstrates both the value and danger of aggressive reuse.

Lean 4.32 introduced experimental incremental state snapshots.

Lean 4.33 made Lake module archives content-stable so identical outputs can deduplicate across revisions.

Lake's artifact cache is also explicitly toolchain-sensitive.

Applied rule:

> SAVEF and compiler caches must key every semantic/tool input that can change output meaning.

Relevant inputs include:

~~~text
source identity
dependency semantic interfaces
semantic profile
kernel contract
compiler/pass identities
target profile
toolchain identity
capability world
resource-relevant options
~~~

A cache miss or corrupt entry means recomputation.

It never means semantic fallback.

Research sources:

- https://lean-lang.org/doc/reference/latest/releases/v4.32.0/
- https://lean-lang.org/doc/reference/latest/releases/v4.33.0/
- https://lean-lang.org/doc/reference/latest/Build-Tools-and-Distribution/Lake/

---

# 12. Lean lesson: independent checking still matters

Recent Lean releases have fixed kernel/runtime defects relevant to high-assurance proof checking.

The Lean ecosystem increasingly emphasizes independent checking and replay.

Applied rule:

> Neither Lean bootstrap success nor PSCV self-host success is enough to establish logical authority.

High-assurance compiler knowledge should remain replayable through an explicit checker policy.

---

# 13. Current PSCV compiler structure

The current direct-backend branch has a small semantic compiler spine:

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
~~~

with backends and drivers outside the semantic core:

~~~text
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

This decomposition is fundamentally sound.

Version 2 recommends refinement rather than a wholesale rewrite.

---

# 14. Current 55-module semantic compiler closure

The minimal compiler closure is exactly 55 modules and approximately 27.8k source lines.

| Package | Modules | Approx. lines |
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

This remains an excellent bounded SAVEF self-application corpus.

However Version 2 no longer treats completion of this implementation as a prerequisite for SAVEF infrastructure.

---

# 15. Current direct backend surface

Current direct backends add approximately:

~~~text
backend-js
    3 modules
    about 3.3k lines

backend-wasm
    12 modules
    about 10.1k lines

JS/Wasm drivers
    2 modules
    about 0.4k lines
~~~

The direct-Wasm branch already generates and instantiates real Wasm compiler binaries and contains fixed-point machinery.

The high-assurance gap is now semantic preservation evidence, not basic backend existence.

---

# 16. Current strongest compiler-IR architecture issue

The current compiler-ir package combines:

~~~text
Model.lean
Specialize.lean
~~~

and specialization is exposed inconsistently across backend paths.

The JavaScript driver exposes specialization as an explicit operation:

~~~text
PsValidatedIrModule
    ->
psIrSpecializeModule
    ->
specialized PsVerifiedIrModule
    ->
JS lowering
~~~

The Wasm backend calls psIrSpecializeModule internally inside psWasmLowerModule.

This is undesirable for SAVEF.

The same target-neutral semantic transformation should not be driver-owned for one backend and backend-internal for another.

Version 2 rule:

> Move target-neutral specialization into one explicit shared compiler phase with one artifact identity and one preservation theorem/validator.

Both backends then consume the same specialized artifact.

---

# 17. Proposed executable phase chain

Replace the current conceptual ambiguity with:

~~~text
CertifiedSource
    |
    v
RuntimeIR
    construction-oriented executable IR
    may contain generic forms
    |
    | validateRuntimeIr
    v
VerifiedIR
    target-neutral executable invariants
    |
    | specialize
    v
SpecializedIR
    ground target-neutral executable IR
    |
    +------------------+
    |                  |
    v                  v
JsIR                WasmIR
    |                  |
    v                  v
.js                .wasm
~~~

SpecializedIR should have a distinct wrapper/type and canonical identity.

A backend should not silently invoke target-neutral specialization internally in the certified lane.

---

# 18. Why SpecializedIR matters to SAVEF

Specialization is a reusable compiler theorem boundary.

Without a distinct artifact:

~~~text
JavaScript backend
    relies on specialization through one path

Wasm backend
    relies on specialization through another path
~~~

and evidence becomes fragmented.

With SpecializedIR:

~~~text
VerifiedIR
    |
    | one specialization theorem/validator
    v
SpecializedIR
      /     \
     v       v
   JsIR    WasmIR
~~~

One preservation result serves every backend.

This is exactly the compounding behavior SAVEF should prefer.

---

# 19. Proposed compiler pass contract

Introduce a first-class pass description.

Conceptually:

~~~text
CompilerPassContract {
    id
    inputPhase
    outputPhase

    inputSchema
    outputSchema

    requiredInvariants
    establishedInvariants

    semanticRelation

    deterministicPolicy
    resourceBudget

    validatorIdentity
    proofEvidenceIdentity

    implementationIdentity
}
~~~

The runtime implementation does not need to carry proof terms at every invocation.

The pass contract binds the implementation identity to reusable evidence.

---

# 20. Pass evidence becomes SAVEF knowledge

For every pass P:

~~~text
input artifact A
    |
    | P
    v
output artifact B
~~~

SAVEF may publish:

~~~text
PassTheorem(P):
    semantics(B)
    refines or preserves
    semantics(A)
~~~

or a translation-validation theorem:

~~~text
ValidateP(A, B)
    ->
PreservesP(A, B)
~~~

The theorem or validator is reusable across every compiler invocation.

This is the compiler equivalent of proving a mathematical lemma once.

---

# 21. Proposed compiler architecture packages

Do not immediately move all current files.

Use compatibility façades first.

Target package architecture:

~~~text
compiler-contract/
    pass identities
    compiler phase identities
    invariant vocabulary
    assurance classifications

runtime-ir/
    construction executable IR

verified-ir/
    validated target-neutral executable IR

specialized-ir/
    ground/specialized target-neutral IR

compiler-pass-specialize/
    target-neutral specialization

module-interface/
    CertifiedModuleInterface

evidence-core/
    pass evidence
    compiler evidence
    assurance vectors

compiler-service/
    one semantic API for tools and AI

lean-reference/
    Lean-hosted compile/check/oracle lane

savef-format/
    SPKF objects

factory-bench/
    compiler self-application benchmark
~~~

Existing packages migrate incrementally.

---

# 22. Preserve the target-neutral boundary

The current VerifiedIR contract is correct in forbidding:

- JavaScript representation policy;
- Rust lifetimes/ownership;
- Wasm opcodes/layout;
- WIT/WASI;
- npm resolution;
- target calling conventions.

Preserve this rule.

SpecializedIR is also target-neutral.

Target-specific representation begins after SpecializedIR.

---

# 23. Lean reference lane

Create a deliberate Lean-hosted reference compiler service.

Conceptual package:

~~~text
lean-reference/
~~~

Responsibilities:

- compile PSCV-compatible Lean source with the pinned Lean toolchain;
- export canonical elaborated/core declarations;
- build native executable compiler tools;
- produce reference module-interface data;
- run reference semantic tests;
- serve as a differential oracle against the owned PSCV compiler;
- provide bootstrap executables for SAVEF tooling.

It is not the permanent semantic authority.

It is a bootstrap/reference implementation.

---

# 24. Why the Lean lane removes unnecessary blocking

Under this plan's assumption:

~~~text
PSCV source subset
    is representable in Lean
~~~

therefore:

~~~text
SAVEF infrastructure written in PSCV subset
    ->
Lean compiler
    ->
native executable
~~~

can work before today's PSCV self-host compiler catches up.

Development can begin immediately on:

- SPKF;
- CertifiedModuleInterface;
- compiler-pass contracts;
- FactoryBench;
- theory index;
- QueryGraph extensions;
- compiler-service APIs;
- preservation sidecars.

The owned PSCV compiler later becomes another implementation of the same contracts.

---

# 25. Native execution is first-class from the beginning

Earlier plans emphasized direct JS/Wasm because those backends were active self-host targets.

Version 2 adds a first-class native lane immediately through Lean:

~~~text
PSCV-compatible Lean source
    ->
Lean LCNF compiler
    ->
C
    ->
native executable
~~~

This lets SAVEF itself run as a native tool immediately.

Native speed is useful for:

- semantic indexing;
- proof dependency analysis;
- FactoryBench;
- knowledge extraction;
- proof replay orchestration;
- large compiler analysis.

Direct JS/Wasm remain strategic portability/self-host lanes.

---

# 26. Four-plane compiler architecture

Version 2 organizes the compiler into four planes.

## Semantic plane

Owns language meaning and checked semantic artifacts.

~~~text
syntax
core
environment
meta
elab
kernel-contract
CheckedCore
PSCV-CERT
CertifiedSource
~~~

## Compiler plane

Owns executable semantic transformations.

~~~text
RuntimeIR
validateRuntimeIr
VerifiedIR
specialization
SpecializedIR
JsIR/WasmIR/native adapter IR
~~~

## Build plane

Owns impure orchestration and performance.

~~~text
filesystem
module graph
QueryGraph
CAS
remote cache
toolchain invocation
parallel scheduling
package resolution
publishing
~~~

## Knowledge plane

Owns reusable SAVEF knowledge.

~~~text
CertifiedModuleInterface
specification sets
theorem interfaces
assumption closures
pass theorems
proof recipes
failure knowledge
SPKF roots
FactoryBench metrics
~~~

The knowledge plane is derived from semantic authority.

It does not become a second semantic authority.

---

# 27. Why this four-plane split matters

Without this split, SAVEF risks mixing:

~~~text
compiler cache hit
with
proof truth

AI retrieval metadata
with
semantic specification

package manifest
with
compiler authority

target artifact
with
source correctness
~~~

The four-plane architecture allows aggressive optimization and AI tooling without enlarging the logical trusted base.

---

# 28. Current package-to-target mapping

Current package:

~~~text
foundation/
~~~

Target role:

~~~text
semantic primitives + reusable base theorems
~~~

Current:

~~~text
syntax/
~~~

Target role:

~~~text
owned source grammar, AST, canonical parser/printer/translation
~~~

Current:

~~~text
core/
~~~

Target role:

~~~text
kernel-facing language/core structures and compiler semantic algebra
~~~

Current:

~~~text
environment/
meta/
elab/
~~~

Target role:

~~~text
frontend semantic machinery
~~~

Current:

~~~text
bridge/
~~~

Target role should be narrowed to:

~~~text
canonical protocol/codec boundaries
~~~

It should not become the long-term owner of semantic authority.

Current:

~~~text
compiler-ir/
~~~

Target role should be split into:

~~~text
runtime-ir/
verified-ir/
specialized-ir/
compiler-pass-specialize/
~~~

Current:

~~~text
erasure/
~~~

Target role:

~~~text
CertifiedSource -> RuntimeIR semantic transform
~~~

Current:

~~~text
compiler/
~~~

Target role:

~~~text
pipeline composition/service façade
~~~

It should not itself own the semantic implementation of every stage.

---

# 29. Proposed source tree evolution

Target structure:

~~~text
psc15selfhost/packages/

foundation/
syntax/
core/
environment/
meta/
elab/

kernel-contract/
checked-core/
pscv-spec/
pscv-obligation/
pscv-cert/

compiler-contract/
runtime-ir/
verified-ir/
specialized-ir/

compiler-pass-specialize/
erasure/

module-interface/
interface-ir/
evidence-core/

compiler/
compiler-service/
project/
build-graph/
artifact-codec/
artifact-store/

lean-reference/

backend-js/
backend-wasm/
backend-ts/
backend-rust/

driver-js/
driver-wasm/
driver-ts/
driver-rust/

savef-format/
savef-index/
factory-bench/

bootstrap/
cli/
~~~

This is a target shape, not an instruction to create all packages immediately.

Every new package must correspond to an independent semantic or operational contract.

---

# 30. Proof/specification sidecar structure

The current self-host compiler source should not be rewritten merely to insert proof syntax.

Use sidecar directories first:

~~~text
packages/core/
    src/
    spec/
    proof/

packages/environment/
    src/
    spec/
    proof/

packages/meta/
    src/
    spec/
    proof/

packages/compiler-pass-specialize/
    src/
    spec/
    proof/
~~~

Sidecars are keyed to semantic artifact identities rather than source path alone.

This permits:

- Lean-based proof authoring now;
- PSCV-source self-host implementation stability;
- later migration of selected contracts into PSCV surface syntax;
- stable theorem identity across source refactors.

---

# 31. CompilerModuleKnowledge

Each public compiler module should eventually produce a knowledge bundle.

Conceptually:

~~~text
CompilerModuleKnowledge {
    semanticProfile

    sourceArtifactId
    checkedCoreId
    certifiedSourceId

    certifiedModuleInterfaceId

    approvedSpecSetId
    theoremInterfaceId
    assumptionClosureId

    proofDependencyIds
    implementationDependencyIds

    passEvidenceIds

    advisoryRecipeIds
    failureKnowledgeIds

    provenanceReferences
}
~~~

This is not one giant authority object.

It is a typed graph of independently hashable artifacts.

---

# 32. CertifiedModuleInterface becomes the compiler's declaration file

TypeScript scales through compact public declaration interfaces.

Lean scales imports through compiled module semantic artifacts.

SAVEF needs the stronger compiler equivalent:

~~~text
CertifiedModuleInterface
~~~

It should include all downstream-observable semantic information:

- exported declarations and types;
- transparent bodies required for downstream reduction;
- opaque declarations represented through public specification;
- instances and ordering metadata where relevant;
- public theorems/specifications;
- effects/capabilities;
- public assumption closure;
- imported interface identities;
- compiler/pass contract requirements.

Private implementation should be absent unless semantic transparency requires it.

---

# 33. Transparent versus opaque compiler exports

This distinction is crucial in dependent languages.

## Opaque-to-clients

Clients reason using:

- declared type;
- specification;
- exported theorems.

The implementation is not downstream semantic input.

A body rewrite preserving the specification can keep dependent modules green.

## Transparent-to-clients

Clients rely on definitional reduction of the body.

Its canonical body is part of the CertifiedModuleInterface identity.

Changing it invalidates downstream proof caches as required.

This gives QueryGraph the information needed to distinguish semantic from private changes.

---

# 34. QueryGraph v2

Current QueryGraph already tracks sourceKey, interfaceKey, and dependency interfaces.

SAVEF extension:

~~~text
SemanticQueryRecord {
    moduleId

    sourceKey
    parsedKey
    elaboratedKey

    checkedCoreKey
    certifiedSourceKey

    moduleInterfaceKey
    specSetKey
    theoremInterfaceKey
    assumptionClosureKey

    runtimeIrKey
    verifiedIrKey
    specializedIrKey

    targetEvidenceKeys

    dependencyInterfaceKeys
}
~~~

Not every module needs every field.

The graph remains incremental and stage-specific.

---

# 35. Semantic red/green rule

Current source-only invalidation is not enough for SAVEF.

Target behavior:

~~~text
private implementation change
    + same CertifiedModuleInterface
    =>
downstream proof/build may stay green
~~~

but:

~~~text
public specification change
or
transparent body change
or
public theorem change
or
assumption closure change
    =>
affected downstream nodes become red
~~~

This rule is central to proof-maintenance scalability.

---

# 36. QueryGraph must remain fail-closed

A green decision is an optimization.

It is never proof authority.

Long-term validation target:

~~~text
GreenReuse(query, cache)
    ->
Equivalent(
    cachedResult,
    recompute(authoritativeInputs)
    )
~~~

Missing, corrupt, or mismatched artifacts cause:

~~~text
red
recompute
~~~

never semantic fallback.

---

# 37. Compiler service is the only semantic API

Create one compiler service used by:

- CLI;
- IDE/LSP;
- docs;
- build planner;
- SAVEF indexer;
- AI agents;
- package tooling.

Candidate operations:

~~~text
parse
resolve
elaborate
typeOf

goalState
obligations
specificationCoverage

candidateCore
admissionPayload
checkedCore
certifiedSource

moduleInterface
theoremInterface
assumptionClosure

runtimeIr
verifiedIr
specializedIr

semanticDiff
affectedModules
affectedProofs

capabilitySearch
passEvidence
buildPlan
~~~

No AI integration gets an independently implemented type checker.

---

# 38. Lean reference service interface

The Lean reference lane should expose a matching subset of compiler-service operations.

Conceptually:

~~~text
LeanReferenceService {
    elaborate
    kernelCheck
    exportCore
    compileNative
    moduleInterfaceOracle
    runReference
}
~~~

This enables differential comparison between the Lean reference lane and owned PSCV compiler lane without coupling the owned compiler to Lean internals.

---

# 39. Differential oracle policy

Lean reference output can provide evidence for:

- source acceptance agreement;
- elaborated declaration agreement;
- public semantic interface agreement;
- runtime behavior comparison on bounded examples;
- compiler artifact comparison where meaningful.

Differential agreement is not a proof of correctness.

It is independent evidence.

A PSCV artifact must not gain kernel-verified status merely because Lean and PSCV agree.

---

# 40. Real CheckedCore remains necessary

Even under the assumption that Lean can compile all PSCV language features, the owned PSCV semantic pipeline still needs an honest authority boundary.

Current:

~~~text
AdmissionReady
    ->
erasure
~~~

Target:

~~~text
AdmissionReady
    |
    | KernelContract
    v
CheckedCore
    |
    | PSCV-CERT
    v
CertifiedSource
    |
    v
erasure
~~~

Lean can be one provider/reference implementation.

PSKernel remains the intended owned authority when its readiness gates close.

---

# 41. Compiler pass manifest

Every pass in the certified lane should emit a deterministic pass manifest.

Concept:

~~~text
PassExecution {
    passContractId

    inputArtifactId
    outputArtifactId

    semanticProfileId
    implementationId

    options
    resourceBudget

    validationEvidenceId
    preservationEvidenceId

    timing/resourceMetrics
}
~~~

The manifest is evidence binding.

It does not substitute for the preservation theorem or validator.

---

# 42. Pass-level SAVEF is more powerful than module-only SAVEF

Module theorems help prove source/compiler algorithms.

Pass theorems help every compiled program.

Example:

~~~text
SpecializationPreservesSemantics
~~~

may be reused for:

- compiler self-host build;
- JSON package;
- HTTP package;
- future user applications;
- JS backend;
- Wasm backend;
- future native backend.

That is much greater knowledge leverage than a theorem specific to one compiler call site.

SAVEF should prioritize high-fanout pass theorems.

---

# 43. Knowledge leverage scoring

Every candidate theorem/pass proof should receive an engineering leverage estimate.

Possible factors:

~~~text
number of downstream modules
number of compiler passes using it
number of backends benefiting
number of package domains benefiting
proof invalidation reduction
frequency of matching obligations
~~~

This estimate affects work prioritization.

It does not affect theorem truth.

---

# 44. Priority theorem classes

Highest SAVEF leverage for the compiler likely comes from:

1. substitution/lifting/abstraction laws;
2. environment lookup/index refinement;
3. typing/inference soundness;
4. unification solution soundness;
5. instance synthesis correctness/order;
6. RuntimeIR validator soundness;
7. specialization preservation;
8. erasure noninterference/preservation;
9. parser/printer canonical roundtrip;
10. elaboration soundness;
11. target lowering preservation.

This is the recommended proof-investment order.

---

# 45. Why not start with the parser

Syntax is approximately 8.2k lines and elaboration approximately 4.8k lines.

Foundation/Core is only about 1.1k lines.

Starting at the parser maximizes proof context before reusable theory exists.

SAVEF should intentionally do the opposite:

~~~text
small high-leverage semantic base
    ->
reusable theorem graph
    ->
state/meta invariants
    ->
erasure/IR
    ->
large frontend
~~~

The large frontend then becomes the experiment that tests whether accumulated knowledge pays off.

---

# 46. SAVEF self-application model

Applying SAVEF to the compiler means more than proving compiler functions.

Every accepted compiler slice should produce reusable knowledge.

The loop is:

~~~text
compiler requirement/change
    |
    v
approved compiler specification
    |
    v
implementation
    |
    v
checked proof / validator
    |
    v
CertifiedModuleInterface or PassEvidence
    |
    v
SPKF knowledge
    |
    v
QueryGraph/theory index
    |
    v
next compiler change retrieves prior knowledge
    |
    v
new accepted compiler result
    |
    +----------------------> repeat
~~~

The compiler becomes a producer and consumer of its own accepted software mathematics.

---

# 47. Compiler knowledge generations

Define explicit knowledge generations.

## K0 — seed knowledge

Hand-built or retrofitted theorem interfaces from Foundation/Core and selected compiler contracts.

## K1 — first reused knowledge

Environment/IR proofs that explicitly import and reuse K0.

## K2 — meta/specialization knowledge

Inference, unification, reduction, and specialization results built using K0/K1.

## K3 — erasure/frontend knowledge

Proofs use accumulated lower-layer theorems.

## K4 — whole compiler knowledge

Compiler API and semantic pipeline composition.

## K5 — artifact preservation knowledge

JavaScript/Wasm/native backend evidence.

SAVEF's core hypothesis is that marginal production cost should decline as K grows.

---

# 48. Lean-seeded implementation generations

Separate implementation generations from knowledge generations.

~~~text
I0
Lean-hosted native compiler/tooling

I1
current PSCV-owned semantic compiler

I2
SAVEF-aware owned compiler
    pass contracts
    interfaces
    knowledge extraction

I3
self-host compiler consumes same SAVEF knowledge

I4
direct JS/Wasm/native implementations satisfy same contracts
~~~

No knowledge theorem is tied to one implementation generation unless its statement is implementation-specific.

---

# 49. First self-build demonstration

The first SAVEF self-build should not attempt the whole 55-module compiler.

Use a small compiler subsystem.

Recommended seed:

~~~text
Foundation.List
Foundation.Name
Core.Expr
Core.Subst
Core.Abstract
~~~

Steps:

1. compile these modules through the Lean reference lane;
2. produce semantic identities;
3. create approved specifications;
4. prove reusable laws;
5. emit theorem interfaces/SPKF objects;
6. build the next subsystem using those facts;
7. measure retrieval/reuse.

A successful Environment proof that imports Foundation/Core theorem knowledge is already a real self-application step.

---

# 50. Second self-build demonstration

Target:

~~~text
Environment.Basic
Environment.LocalContext
Environment.Resolve
~~~

Expected reused knowledge:

- name equality correctness;
- list membership/append facts;
- substitution/name invariants where relevant.

Produce:

~~~text
EnvironmentLookupSound
EnvironmentAddPreserves
EnvironmentIndexRefines
~~~

These become knowledge for Meta and Elab.

---

# 51. Third self-build demonstration

Target:

~~~text
Meta.Reduce
Meta.Infer
Meta.Unify
Meta.SynthInstance
~~~

Expected reused knowledge:

- substitution/lifting;
- environment lookup;
- expression equality;
- local-context facts.

Produce:

~~~text
ReductionSound
InferenceSound
UnificationSound
InstanceSynthesisSound
~~~

These are high-leverage frontend theorems.

---

# 52. Fourth self-build demonstration

Target:

~~~text
CompilerIr.Model
CompilerPass.Specialize
Erasure
~~~

Expected outputs:

~~~text
RuntimeIrWellFormed
VerifiedIrWellFormed
SpecializedIrWellFormed
SpecializationPreserves
ErasurePreserves
GhostErasureNoninterference
~~~

This is where SAVEF moves from frontend correctness into compiler-pass correctness.

---

# 53. Fifth self-build demonstration

Target the large frontend:

~~~text
Syntax
Elab
~~~

By this point the SAVEF graph should already contain:

- list/name laws;
- substitution;
- environment;
- inference;
- unification;
- reduction;
- IR invariants.

This is the best layer for measuring whether accumulated knowledge actually reduces proof-search context and repair cost.

---

# 54. Final compiler composition demonstration

The compiler API is small compared with the lower layers.

Once lower relations exist, prove composition.

Target theorem shape:

~~~text
compileCertified(source) = success artifact
    ->
SourceSpec(source)
and
TargetArtifactRefinesSource(artifact, source)
~~~

The exact final theorem may be split by target/backend.

The important property is compositional evidence.

---

# 55. Compiler source policy under the Lean bootstrap assumption

New SAVEF/compiler architecture code should satisfy two properties where practical:

1. valid Lean source under the pinned reference toolchain;
2. inside the intended PSCV subset/profile.

This permits immediate native compilation while preserving future self-hostability.

Do not wait for the current compiler to accept a feature if Lean already provides the agreed PSCV semantics.

Instead:

~~~text
write PSCV-compatible Lean now
    ->
compile with Lean
    ->
record required PSCV feature
    ->
later require owned compiler conformance
~~~

This converts today's compiler feature gap from a blocking dependency into a conformance backlog.

---

# 56. PSCV conformance backlog

For every construct used by the Lean-hosted SAVEF/compiler source, record:

~~~text
PscvFeatureRequirement {
    featureId
    semanticProfile
    exampleSource
    expectedCoreBehavior
    expectedExecutableBehavior
    currentOwnedCompilerStatus
}
~~~

The owned compiler becomes complete by closing this backlog.

SAVEF work does not stop while the backlog is open.

---

# 57. Reference/native-first build mode

Add a build mode conceptually equivalent to:

~~~text
psc build --compiler lean-reference
~~~

or an internal equivalent.

This mode:

1. checks PSCV subset/profile;
2. invokes pinned Lean;
3. kernel-checks through reference policy;
4. compiles to native executable;
5. records SemanticProfile;
6. records Lean/toolchain identity;
7. emits SAVEF build/evidence metadata.

It provides a practical bootstrap lane before owned self-host compilation is complete.

---

# 58. Owned compiler conformance mode

Concept:

~~~text
psc compare-compiler
~~~

For selected modules compare:

~~~text
Lean reference lane
    vs
owned PSCV compiler lane
~~~

Compare:

- source acceptance;
- elaborated declarations;
- canonical admissions;
- CertifiedModuleInterface;
- RuntimeIR/VerifiedIR where defined;
- observable execution tests.

Differences fail closed until explained by an explicit compatibility rule.

---

# 59. Do not require binary equality across compiler lanes

Lean native output, JavaScript output, Wasm output, and a future native PSCV backend will not be byte-identical.

The conformance target is semantic.

Use:

~~~text
same certified public semantics
+
accepted preservation relation
~~~

not executable byte identity.

Byte fixed points remain useful inside a specific reproducible implementation lane.

---

# 60. Compiler pass tests should become theorem-guided

Current compiler development has many behavior tests.

Keep them.

For every semantic pass classify tests as:

~~~text
conformance examples
negative/rejection cases
differential tests
property tests
adversarial cases
~~~

Then map them to:

~~~text
pass invariant
preservation theorem
or
explicit empirical evidence
~~~

Tests help discover counterexamples and regression bugs.

They do not replace pass theorems.

---

# 61. Proof sidecars should follow the implementation dependency graph

Recommended proof directory pattern:

~~~text
proof/
    Foundation/
    Core/
    Environment/
    Meta/
    RuntimeIr/
    VerifiedIr/
    Specialize/
    Erasure/
    Syntax/
    Elab/
    Compiler/
~~~

Proof imports should prefer theorem interfaces over implementation modules once interfaces exist.

This is essential for measuring abstraction benefit.

---

# 62. Knowledge extraction pipeline

After a successful proof/check:

~~~text
Lean/PSKernel proof environment
    |
    v
extract checked theorem identities
    |
    v
construct theorem interface
    |
    v
construct assumption closure
    |
    v
bind CertifiedModuleInterface
    |
    v
emit SPKF KnowledgeRoot / TheoryExtension
    |
    v
index for semantic retrieval
~~~

Re-running the extractor against unchanged authority artifacts must reproduce the same knowledge identities.

---

# 63. Knowledge reproducibility

Define a new build invariant:

~~~text
authoritative compiler artifacts
    ->
SAVEF extraction
    ->
KnowledgeRoot K

same authoritative artifacts
    ->
SAVEF extraction
    ->
KnowledgeRoot K
~~~

This is analogous to a fixed point for knowledge packaging.

It proves deterministic extraction, not theorem correctness.

---

# 64. SAVEF index architecture

The index should store/search:

- capabilities;
- definitions;
- theorem statements;
- theorem dependency graph;
- specifications;
- assumptions;
- compiler pass contracts;
- implementation witnesses;
- proof recipes;
- structured failures;
- benchmark metrics.

The index is rebuildable from SPKF/authority objects.

Deleting it must not delete semantic truth.

---

# 65. Semantic retrieval API for compiler agents

Agent query examples:

~~~text
find theorems about:
    substitution under binders

find invariants required by:
    psValidateErasedIrModule

find compiler passes preserving:
    observable return value

find prior failures matching:
    environment lookup after replacement

find compatible module interfaces for:
    Ps.Meta.Infer
~~~

The result should include exact SPKF/theorem identities.

---

# 66. Context slicing policy

For every compiler obligation, calculate:

~~~text
local goal
local context

transparent dependency closure
public theorem interface closure
assumption closure

candidate reusable theorems
relevant pass contracts

optional proof recipes/failure knowledge
~~~

The agent receives this slice by default.

Full-repository access remains available when needed.

This makes semantic context size a measurable variable.

---

# 67. FactoryBench-v2 for compiler self-application

Create CompilerFactoryBench-v2 before completing the knowledge graph.

It should contain held-out tasks in these classes:

1. theorem completion;
2. proof repair;
3. invariant strengthening;
4. implementation-preserving refactor;
5. semantic bug repair;
6. new compiler pass/property;
7. new frontend feature;
8. backend preservation task;
9. QueryGraph invalidation task;
10. interface-stability task.

Tasks should span multiple dependency depths.

---

# 68. Baseline versus SAVEF experiment

Baseline B0:

~~~text
pinned model
pinned tools
pinned compiler commit
raw repository access
no SAVEF semantic retrieval
same acceptance gates
~~~

SAVEF B1:

~~~text
same model
same tools
same compiler commit
same tasks
same acceptance gates
+
SAVEF semantic retrieval
~~~

Optional B2:

~~~text
SAVEF retrieval
+
proof recipes/failure knowledge
~~~

This separates semantic theorem reuse from advisory agent-memory benefit.

---

# 69. Metrics

Record at least:

~~~text
accepted solve rate
wall time
model tokens
tool calls
proof attempts
test/rebuild cycles
human interventions
files read
raw context bytes
semantic context bytes
new implementation lines
new proof lines
~~~

Reuse metrics:

~~~text
theorem reuse count
specification reuse count
module-interface reuse count
pass-theorem reuse count
proof-recipe reuse count
~~~

Maintenance metrics:

~~~text
proof invalidation fanout
repair time
interface stability rate
cache hit ratio
~~~

---

# 70. Self-amplification pass threshold

Initial research threshold:

## Assurance non-regression

Every accepted SAVEF-assisted result must pass the same or stronger gates as baseline.

## Real reuse

At least 30 percent of accepted B1 tasks must consume prior accepted knowledge objects.

## Productivity

At least one of:

~~~text
20 percent lower median token use
20 percent lower median wall time
20 percent lower median human intervention

or

10 percentage-point higher accepted solve rate
~~~

without a material regression in other primary metrics.

## Closed loop

At least one SAVEF-assisted compiler change must create accepted knowledge used by a later accepted compiler change.

Only then claim compiler self-amplification.

