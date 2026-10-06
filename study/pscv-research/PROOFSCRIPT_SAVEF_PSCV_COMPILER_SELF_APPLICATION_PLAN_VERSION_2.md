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

