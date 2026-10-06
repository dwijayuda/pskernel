# ProofScript SAVEF Self-Application Plan for the PSCV Compiler

**Status:** research, implementation, and experimental plan; non-normative.

**Working identity:** SAVEF-COMPILER-SELFAPP-v1.

**Research snapshot:** 2026-10-06.

**Target plan/architecture score:** **9.39 / 10**

**Current repository readiness for the complete experiment:** **approximately 5.60 / 10**

**Repository:** dwijayuda/pskernel

**Primary implementation subject:** branch psc2/pscv-direct-backends, directory psc15selfhost/

**Supporting evidence branches:**

- pscv/prove-pskernel-core-v1
- pscv/selfhost-poc-v1

**Purpose:** revise SAVEF where necessary and define a detailed, falsifiable plan for applying SAVEF to the PSCV compiler itself. The compiler becomes SAVEF's first serious self-application subject. The experiment succeeds only if accepted knowledge produced while specifying, proving, repairing, and building earlier compiler slices measurably reduces the cost of producing later compiler slices under a fixed model/tool/evaluation policy.

---

# 1. Executive decision

The strongest way to test SAVEF is not to begin with a large external application.

Use the compiler itself.

The PSCV compiler has properties that make it an unusually good SAVEF experiment:

- it is a real nontrivial software system;
- its minimal semantic closure is finite and machine-enforced;
- it already self-hosts through a fixed source profile;
- it already has canonical translation/admission/emission contracts;
- it already has direct JavaScript and WebAssembly compiler paths;
- it already has an incremental QueryGraph;
- it already has a kernel-provider boundary;
- independent PSKernel metatheory/proof work is progressing rapidly;
- a previous compiler proof experiment provides useful proof-sidecar patterns;
- compiler correctness naturally requires reusable semantic lemmas rather than isolated tests.

The experiment should therefore answer two independent questions.

## Question A — Can the compiler become an accumulating body of software mathematics?

That means compiler modules acquire:

- approved specifications;
- checked theorem interfaces;
- semantic dependency identities;
- transitive assumptions;
- proof/refinement evidence;
- reusable proof strategies and counterexamples;
- CertifiedModuleInterfaces when the production boundary exists.

## Question B — Does that accumulated knowledge make later compiler work cheaper?

That requires controlled measurement.

It is not enough to say:

~~~text
we proved more compiler modules
~~~

The SAVEF claim is stronger:

~~~text
same model
same tool policy
same assurance gates
comparable compiler tasks

larger accepted compiler knowledge graph
    =>
higher success
or
lower tokens
or
lower repair cost
or
lower human intervention
or
less duplicated proof/code
~~~

without assurance regression.

That is the actual self-amplification hypothesis.

---

# 2. The key SAVEF revision

Earlier SAVEF descriptions can be read as if the verified source itself must immediately carry all contracts/proofs.

For the self-host compiler, that is too expensive and risks destabilizing an already valuable invariant.

The current compiler closure uses the machine-enforced implementation discipline:

~~~text
PSC1-selfhost-stable/1
~~~

It deliberately excludes many Lean conveniences and proof syntax so the compiler can keep translating, regenerating, and compiling itself.

Therefore the first self-application rule is:

> **Do not rewrite the 55-module compiler closure merely to insert SAVEF proof syntax. Keep implementation source stable and attach formal knowledge as semantic sidecars keyed to canonical compiler artifacts.**

Conceptually:

~~~text
existing compiler implementation
    |
    +--> canonical source identity
    +--> semantic/admission identity
    |
    v
SAVEF sidecars
    specifications
    proof modules
    theorem interface
    assumptions
    proof recipes
    SPKF objects
~~~

Later, when PSCV verified-source syntax itself is fully self-hostable, selected contracts may move into source where that improves usability.

The first experiment should not wait for that.

---

# 3. Why this is a better scientific experiment

If we first refactor the compiler into a new verification-friendly programming style, any productivity improvement could be caused by:

- different code;
- different architecture;
- a newer AI model;
- better tools;
- easier tasks.

Keeping the current implementation discipline largely fixed creates a cleaner experiment.

We can ask:

> What changes when the same compiler codebase acquires an accumulating accepted semantic knowledge layer?

That is much closer to testing SAVEF itself.

---

# 4. Research precedents

## CompCert

CompCert's defining compiler-correctness result is semantic preservation: when compilation succeeds, observable target behavior is related to allowed source behavior.

Applied lesson:

> Compiler correctness is a chain of semantic relations, not a successful test suite or self-host fixed point.

Source:
https://compcert.org/man/manual.pdf

## CakeML

CakeML combines formal language semantics, verified compiler passes, and bootstrapping of a compiler that can compile itself.

Applied lesson:

> ProofScript should keep fixed-point evidence, semantic correctness, and executable-artifact preservation as separate claims, then compose them.

Source:
https://cakeml.org/

## Lean4Lean

Lean4Lean separates an abstract metatheory/specification from an executable Lean kernel implementation and proves implementation properties against that theory.

Applied lesson:

> PSKernel and compiler semantic algorithms should be related to independent judgments, not merely proved to reproduce themselves.

Source:
https://github.com/digama0/lean4lean

## VeriSoftBench

Repository-scale Lean verification research reports that proof success decreases as transitive dependency closure grows and that curated dependency context improves results relative to dumping the full repository.

Applied lesson:

> SAVEF's semantic dependency slices and QueryGraph-derived proof context should be treated as measurable productivity infrastructure.

Source:
https://arxiv.org/abs/2602.18307

## P3

Joint program-and-proof planning improves verified-code-generation success and can lower cost relative to implementation-first workflows.

Applied lesson:

> New compiler work should be planned together with its specification/proof shape, not implemented first and formalized only afterward.

Source:
https://arxiv.org/abs/2608.09277

---

# 5. Current compiler subject: bounded and measurable

The minimal compiler semantic closure on psc2/pscv-direct-backends consists of exactly 55 source modules.

The closure is:

| Package | Modules | Approximate source lines |
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
| **Total** | **55** | **approximately 27,778** |

This is an ideal SAVEF test subject:

~~~text
large enough to be meaningful
small enough to inventory completely
dependency-ordered
already self-host constrained
~~~

---

# 6. Direct backend subject

The direct-backend branch adds a substantial post-core surface:

| Area | Modules | Approximate lines |
| --- | ---: | ---: |
| backend-js | 3 | 3,293 |
| backend-wasm | 12 | 10,142 |
| driver-js + driver-wasm | 2 | 380 |
| **Total** | **17** | **approximately 13,815** |

These are important for final artifact preservation.

They should not block the first SAVEF self-amplification experiment.

The first target is the 55-module semantic compiler.

Backends become the second experiment lane.

---

# 7. Current self-host discipline is an asset

PSC1-selfhost-stable/1 already encodes a proof-friendly engineering discipline even though it was originally designed for reliable self-hosting.

It favors:

- explicit structural recursion;
- explicit fuel workers;
- simple pattern matching;
- explicit constructors;
- canonical recursive data construction;
- small dependency surface;
- no arbitrary Lean syntax macros;
- no unsafe/noncomputable closure;
- no hidden host/kernel/backend dependency in the 55-module compiler.

The generic self-host contract already checks:

1. Lean-compatible source closure;
2. Lean to canonical ProofScript translation;
3. canonical ProofScript idempotence;
4. generated ProofScript closure checking;
5. Lean-source versus PSC canonical admissions parity;
6. Lean-source versus PSC TypeScript emission parity.

The fixed-point gate then checks compiler regeneration.

SAVEF should reuse these as existing executable invariants.

They are not compiler-correctness proofs.

---

# 8. Dual representation is useful to SAVEF

The compiler already has two source representations:

~~~text
authoritative Lean-compatible implementation
        |
        v
canonical ProofScript source
~~~

The repository checks strong equivalence evidence between the two representations through canonical admissions and emission parity.

This enables a transitional SAVEF strategy:

- write semantic proof sidecars using mature Lean tooling;
- attach them to canonical semantic/compiler identities;
- keep the generated ProofScript implementation as the self-host witness;
- avoid tying theorem identity to source spelling.

Long-term PSCV proof source may itself become self-hosted.

The first SAVEF compiler experiment does not need to wait for that transition.

---

# 9. Current compiler proof experiment: useful but not merge-ready

The older pscv/selfhost-poc-v1 branch contains compiler proof sidecars for:

- frontend orchestration;
- admission/preparation orchestration;
- lowering orchestration.

The proof files are unusually honest.

They explicitly state that:

- frontend wrapper theorems do not prove parser/elaborator correctness;
- admission proofs preserve AdmissionReady meaning and do not claim kernel admission;
- lowering proofs prove wrapper fail-closed behavior and do not prove erasure semantic preservation or VerifiedIR validator soundness.

That architecture should be retained.

However the branch has diverged heavily from the current direct-backend compiler.

At the current snapshot, psc2/pscv-direct-backends is more than one thousand commits ahead of that old experiment while the old branch also contains its own divergent commits.

Therefore:

> **Mine theorem patterns and proof architecture from pscv/selfhost-poc-v1; do not merge it wholesale into the current compiler.**

---

# 10. Current PSKernel evidence is strong enough to support the experiment

The live pscv/prove-pskernel-core-v1 semantic audit currently reports:

~~~text
A semantic/refinement      33
B reusable theory          14
C control/branch           24
D shallow/base              8
                           --
total canonical pairs      79
~~~

This is a major improvement from earlier SAVEF snapshots.

It still does not mean the kernel is fully proved.

Important unfinished areas remain:

- general substitution laws;
- full cache/index refinement;
- full reduction relation;
- full definitional-equality soundness;
- complete declaration/environment extension;
- inductive positivity and recursor correctness;
- end-to-end KernelContract success implying semantic judgments.

The compiler experiment should consume PSKernel evidence as an independently evolving foundation rather than block all compiler work until every kernel theorem is complete.

---

# 11. Current critical authority gap

The compiler currently defines:

~~~text
PsCompilerAdmissionReadyModule
~~~

and its functions named check are still aliases of preparation.

The current source path can therefore reach erasure/IR validation without a genuine kernel-owned CheckedCore state.

This is the highest-priority semantic gap for the strong self-application claim.

Target:

~~~text
Elaborated CandidateCore
        |
        v
AdmissionReady
        |
        | designated KernelContract provider
        v
CheckedCore
        |
        | PSCV-CERT
        v
CertifiedSource
        |
        v
Erasure
~~~

SAVEF may begin collecting non-authoritative/specification knowledge before this is complete.

But no experiment may call AdmissionReady compiler modules kernel-certified.

---

# 12. What it means to apply SAVEF to the compiler

SAVEF self-application is NOT merely:

~~~text
write compiler proofs
~~~

It is:

~~~text
1. specify a compiler slice
2. prove/check the slice
3. extract reusable semantic knowledge
4. index that knowledge
5. use it to build/prove a later compiler slice
6. measure the reuse benefit
7. publish the new accepted knowledge
8. repeat
~~~

The compiler becomes both the product being built and the knowledge factory used to build itself.

---

# 13. Compiler Knowledge Unit

Do not invent a new authority format.

Represent each compiler knowledge unit as a composition of existing/future SAVEF/SPKF objects.

Conceptually every module or abstraction has:

~~~text
CompilerKnowledgeUnit
    subject identity
    SemanticProfile identity

    ApprovedSpec
    Module/CertifiedModuleInterface

    theorem set
    assumption closure

    proof dependencies
    implementation dependencies

    checked evidence

    advisory proof recipes
    counterexamples
    failed strategies

    cost/reuse metrics
~~~

Authority-bearing fields and advisory fields remain separate.

---

# 14. Compiler semantic graph

The current import graph becomes the seed of a richer graph.

~~~text
source module
    |
    +--> imports
    +--> public semantic interface
    +--> specification
    +--> theorems
    +--> assumptions
    +--> proof dependencies
    +--> runtime/IR artifacts
~~~

QueryGraph should remain the incremental engine.

Do not create a disconnected SAVEF dependency database that must independently guess compiler semantics.

---

# 15. Compiler knowledge graph versus compiler build graph

There should be two related graphs.

## Build graph

Answers:

~~~text
what must be rebuilt/rechecked?
~~~

Owned by QueryGraph/build system.

## Knowledge graph

Answers:

~~~text
what facts/capabilities/proof strategies are reusable?
~~~

Derived from checked artifacts and SPKF objects.

The knowledge graph can be deleted and rebuilt.

The build/semantic authorities cannot.

---

# 16. The self-application generations

Define explicit generations.

## Generation G0 — baseline compiler

Current frozen compiler implementation and current assurance tools.

No SAVEF knowledge retrieval beyond ordinary repository access.

## Knowledge K0

Accepted specifications/theorems/interfaces extracted from the first proved slices.

## Generation G1 work

Same model/tool policy receives K0 semantic retrieval while working on the next compiler slice.

Accepted G1 work creates K1.

## Generation G2 work

Use K1 on later matched compiler tasks.

The claim of self-amplification is about:

~~~text
K0 -> K1 -> K2
~~~

reducing marginal production cost under controlled conditions.

---

# 17. Avoiding circular trust

The compiler under study MUST NOT be its sole proof authority.

Seed verification should use:

- pinned Lean;
- designated KernelContract provider;
- PSKernel where applicable;
- independent replay for high-assurance milestones.

The self-host compiler may generate proof candidates.

It may not certify itself by assertion.

Conceptually:

~~~text
compiler G1
    generates candidate evidence
        |
        v
independent checker/provider
        |
        v
accepted knowledge K1
~~~

This avoids a circular SAVEF demonstration.

---

# 18. Fixed point is separate evidence

Current fixed-point evidence is valuable:

~~~text
compiler generation N
    ==
compiler generation N+1
~~~

But SAVEF must keep separate:

~~~text
self-host fixed point
semantic correctness
proof closure
backend preservation
artifact reproducibility
knowledge reuse benefit
~~~

CakeML provides a useful precedent for composing verified compilation and bootstrapping without conflating the claims.

---

# 19. A second fixed point: knowledge reproducibility

SAVEF self-application should introduce a new reproducibility check.

For unchanged compiler semantics:

~~~text
extract SAVEF/SPKF knowledge graph
    ->
re-extract from same authoritative artifacts
    ->
same canonical knowledge roots
~~~

Call this:

~~~text
knowledge reproducibility
~~~

It is not theorem correctness.

It proves that the knowledge-extraction pipeline is deterministic and cacheable.

---

# 20. Success levels

Do not use a single DONE flag.

## Level S0 — identity

Compiler semantic/spec/theorem objects have stable content identities.

## Level S1 — checked module knowledge

Selected modules have accepted specifications/theorems and reproducible knowledge objects.

## Level S2 — modular reuse

Later compiler proofs actually import/use earlier accepted knowledge.

## Level S3 — measurable factory benefit

A controlled experiment shows lower cost or higher success from SAVEF knowledge.

## Level S4 — closed self-application loop

An accepted compiler change produced with SAVEF creates knowledge that is reused in a later accepted compiler change.

## Level S5 — compiler semantic certification

The declared compiler properties themselves are closed through CheckedCore/CertifiedSource-level evidence.

## Level S6 — preserved executable compiler

Direct JS/Wasm executable artifacts have accepted preservation evidence.

The first genuine proof that SAVEF works as a factory is S3 plus S4.

S5 and S6 strengthen assurance but are not required to demonstrate the economic self-amplification hypothesis.


---

# 21. Proof-leverage ordering

Do not prove modules in alphabetical order.

Prioritize modules that create reusable lemmas for many downstream algorithms.

Recommended strata:

~~~text
L0
foundation + core

L1
environment + CompilerIr.Model

L2
meta + CompilerIr.Specialize

L3
erasure

L4
syntax / translation

L5
elaboration

L6
compiler API / whole semantic compiler

L7
direct JS/Wasm backends
~~~

This ordering deliberately postpones the largest frontend modules until the theory graph is richer.

---

# 22. L0 — foundation and core

Subject size:

~~~text
12 modules
approximately 1,113 lines
~~~

This is the best knowledge seed.

## Foundation/List

Candidate reusable theorems:

- psListLength agrees with List.length;
- length of psListAppend;
- reverse preserves length;
- reverse of reverse;
- map preserves length;
- map composition;
- take length bound;
- zip length bound;
- psListMapExcept success implies pointwise conversion success.

These are highly reusable across syntax, environment, meta, erasure, and IR specialization.

## Foundation/Name

Candidate theorems:

- psStringEq correctness;
- psNameEq correctness;
- depth behavior under append;
- append/string rendering compatibility;
- last-component properties;
- hash/equality compatibility where later required.

## Core/Equality

Candidate semantic relation:

~~~text
PsExprAlphaEqSound
~~~

with supporting level/literal/binder equality results.

## Core/Subst and Core/Abstract

Candidate theorems:

- lift reference semantics;
- instantiate reference semantics;
- lift composition;
- instantiate/lift interaction;
- closed-term identity;
- abstraction/instantiation roundtrip;
- capture-avoidance conditions.

These are among the highest-leverage compiler theorems because meta inference, reduction, elaboration, and erasure all depend on substitution behavior.

## L0 output

For every accepted theorem:

- checked proof artifact;
- theorem identity;
- dependency slice;
- reusable proof recipe if useful;
- SPKF theory extension or theorem-set update.

## L0 gate

L0 is complete when:

1. every selected public helper law has checked evidence;
2. exported theorem interfaces are canonical;
3. at least one L0 theorem is reused by an L1 proof;
4. knowledge extraction is deterministic.

---

# 23. L1 — environment and CompilerIr.Model

Subject size:

~~~text
environment
    7 modules
    approximately 2,091 lines

CompilerIr.Model
    approximately 1,095 lines
~~~

This layer creates state/index/validation invariants used throughout later compiler work.

## Environment candidate contracts

Important abstractions:

~~~text
EnvironmentSemanticView
EnvironmentIndexRefines
UniqueDeclarationNames
LookupSound
AddPreservesWellFormedness
~~~

Candidate theorems:

- indexed lookup equals authoritative list lookup under refinement invariant;
- successful lookup returns declaration with matching name;
- adding fresh declaration preserves unrelated lookup;
- permitted axiom replacement obeys exact policy;
- environment-add success establishes declared uniqueness/well-formedness conditions;
- instance collection/order is deterministic under the selected profile.

The PSKernel proof branch already contains similar environment-index refinement ideas.

SAVEF should reuse the pattern while proving the compiler environment's own semantics.

## CompilerIr.Model candidate contracts

Define an explicit predicate:

~~~text
VerifiedIrWellFormed(module)
~~~

covering at least:

- all executable types resolved;
- no unresolved unknown in accepted executable positions;
- names resolve;
- calls have valid arity;
- record/constructor fields exist;
- match alternatives are valid;
- intrinsic forms are accepted;
- external references are declared;
- runtime representations are supported.

Target theorem:

~~~text
psValidateErasedIrModule raw = ok validated
    ->
VerifiedIrWellFormed(validated)
~~~

This is one of the highest-value compiler theorems.

## L1 gate

L1 is complete when downstream proofs can consume abstract environment and VerifiedIR invariants rather than reopen their implementations.

---

# 24. First CertifiedModuleInterface prototype

L1 should produce the first compiler-specific CertifiedModuleInterface prototype.

Start with a small module such as Foundation.List or Core.Subst.

The prototype should contain:

~~~text
module identity
semantic profile identity
exported declarations/types
opaque versus transparent export classification
approved specifications
theorem interface
assumption closure
dependency interface IDs
~~~

The first goal is not ecosystem packaging.

The goal is to establish the compiler-scale abstraction rule:

~~~text
private implementation changes
    while
CertifiedModuleInterface remains equivalent
    ->
dependent proof context need not reopen private implementation
~~~

---

# 25. L2 — meta and specialization

Subject size:

~~~text
meta
    6 modules
    approximately 1,976 lines

CompilerIr.Specialize
    approximately 1,820 lines
~~~

This is where SAVEF should begin showing significant proof reuse.

## Meta/Reduce

Define an independent reduction relation for the compiler meta layer.

Candidate properties:

- successful WHNF is reachable by that relation;
- reduction preserves relevant typing assumptions where required;
- read-only defeq does not mutate semantic environment;
- fuel exhaustion is never success.

## Meta/Infer

Target relation:

~~~text
CompilerTypingJudgment
~~~

Candidate theorem:

~~~text
psInferType succeeds
    ->
CompilerTypingJudgment environment context expr inferredType
~~~

Soundness is the first requirement. Completeness is not required initially.

## Meta/Unify

Candidate relation:

~~~text
UnificationSolutionSound
~~~

Successful assignments must satisfy the equations they claim to solve under explicit meta-context assumptions.

## Meta/SynthInstance

Candidate properties:

- returned instance has the requested class type;
- ordering/priority follows deterministic policy;
- unsupported ambiguity fails closed;
- synthesis does not silently widen assumptions.

## CompilerIr.Specialize

Candidate theorem family:

~~~text
specialization preserves observable VerifiedIR semantics
~~~

Initial sub-results:

- generated specializations are ground;
- type substitution is correct;
- specialized names/keys are deterministic;
- seen/pending structures obey invariants;
- successful final output has no unresolved type parameters;
- reference closure is preserved.

---

# 26. L3 — erasure

Subject size:

~~~text
6 modules
approximately 3,747 lines
~~~

Erasure is central to PSCV because proof/specification material must disappear without changing runtime behavior.

Target relation:

~~~text
ErasureRefines
    certified source
    RuntimeIR
~~~

Candidate results:

- erased proof/ghost binders do not influence runtime observations;
- runtime-relevant binders preserve order/reference mapping;
- constructor/structure layout mapping is consistent;
- generated names are deterministic and collision-safe under explicit assumptions;
- erased expression references resolve;
- primitive/runtime type mapping preserves selected representation contracts.

Long-term theorem shape:

~~~text
sourceExecSemantics(source)
    ~
runtimeIrSemantics(erase(source))
~~~

The first implementation can prove local transformation lemmas before composing the whole relation.

---

# 27. L4 — syntax and translation

Subject size:

~~~text
12 modules
approximately 8,207 lines
~~~

This is the largest single package group and is deliberately postponed.

First targets:

- token-span monotonicity and bounds;
- lexer progress under fuel;
- parser cursor bounds;
- canonical printer determinism;
- parse-print roundtrip on supported canonical AST forms;
- ProofScript print-parse canonical roundtrip;
- translation preserves the selected syntax-level semantic representation;
- translation error paths are fail-closed.

The repository already requires canonical ProofScript reprint idempotence.

SAVEF should convert useful parts of that executable invariant into reusable semantic specifications.

Long-term target:

~~~text
parse(print(ast)) = ast
~~~

modulo explicitly defined canonical equivalence.

---

# 28. L5 — elaboration

Subject size:

~~~text
4 modules
approximately 4,792 lines
~~~

This is likely the hardest semantic compiler slice.

It is also where SAVEF should provide the clearest productivity evidence.

Target theorem shape:

~~~text
psElabTerm succeeds
    ->
ElaborationJudgment
        environment
        localContext
        syntax
        coreExpr
        type
~~~

and:

~~~text
psElabDeclaration succeeds
    ->
CandidateDeclarationWellTyped
~~~

under explicit assumptions about meta operations.

Elaboration proofs should reuse:

- name/equality laws;
- substitution laws;
- environment lookup laws;
- inference soundness;
- unification soundness;
- instance-synthesis laws;
- parser AST invariants.

This layer is a natural test of whether accumulated theorem interfaces reduce context and proof construction cost.

---

# 29. L6 — compiler API composition

Subject size:

~~~text
2 modules
approximately 294 lines
~~~

The compiler API itself is small.

The old proof experiment already shows that wrapper/control-flow proofs are cheap.

Do not mistake them for compiler correctness.

Once lower layers exist, the API can compose their results into stronger end-to-end claims.

Target pipeline:

~~~text
source
    ->
parsed module
    ->
elaborated CandidateCore
    ->
AdmissionReady
    ->
CheckedCore
    ->
CertifiedSource
    ->
VerifiedIR
~~~

Target theorem families:

~~~text
compile-check success
    ->
source accepted under selected semantic profile

certified source
    ->
all required specs/proofs/effects/assumptions closed

verified IR success
    ->
VerifiedIrWellFormed
~~~

---

# 30. Real CheckedCore milestone

This milestone should happen early enough to prevent SAVEF from building authority on the wrong state.

Required implementation:

~~~text
AdmissionReady
    |
    | KernelContract
    v
CheckedCore
~~~

Construction of CheckedCore must be restricted to the designated provider result.

If generated JavaScript cannot enforce opaque construction through source privacy, use a provider-owned checked handle containing:

- session identity;
- checked-core digest;
- kernel-contract identity;
- semantic-profile identity.

After this milestone, authoritative compiler logical claims should key to CheckedCore or stronger identities rather than AdmissionReady serialization.


---

# 31. PSCV-CERT compiler milestone

Once real CheckedCore exists, introduce compiler-level certification.

For every compiler module in the selected SAVEF experiment, record:

~~~text
proof closure
specification coverage
effect closure
dependency certification
assumption closure
ghost/proof erasure safety
~~~

Private helpers do not each require redundant public theorems.

Coverage may be discharged transitively through module-level specifications and checked refinement evidence.

---

# 32. L7 — direct JavaScript backend

Current direct-JS source is approximately 3.3k lines.

Do not begin with a full handwritten proof of the complete emitter.

Use a staged preservation strategy.

## JS-0

Freeze the canonical JavaScript target subset.

## JS-1

Define JsIR semantics for that subset.

## JS-2

Prove or validate VerifiedIR to JsIR lowering invariants.

## JS-3

Use translation validation for emitted JavaScript where practical.

## JS-4

Differentially execute against reference lanes as additional assurance.

Only proof or accepted translation-validation evidence creates PreservedTargetArtifact.

Differential testing alone remains lower assurance.

---

# 33. L7 — direct WebAssembly backend

Current direct-Wasm source is approximately 10.1k lines and already supports whole-compiler binary generation and fixed-point machinery.

Prioritize Wasm as the strongest first target lane.

Recommended structure:

~~~text
VerifiedIR
    ->
WasmIR
    ->
Wasm binary
    ->
validation
    ->
preservation evidence
~~~

Then separately:

~~~text
CertifiedModuleInterface
    ->
InterfaceIR
    ->
WIT
    ->
Wasm Component boundary
~~~

WIT defines portable API shape.

SPKF carries behavioral theory.

The Wasm backend proof is not required to start SAVEF levels S1-S4.

It is required for S6.

---

# 34. Knowledge extraction after every accepted slice

Every accepted slice should emit structured reusable knowledge.

At minimum:

~~~text
SpecificationSet
TheoremSet
AssumptionSet
ModuleInterface
ProofDependencySet
~~~

Optionally:

~~~text
TheoryExtension
FailureKnowledge
ProofRecipe
Counterexample
CompatibilityCertificate
~~~

The output is not merely proof files added.

It is a reusable knowledge increment.

---

# 35. Proof recipes are advisory

SAVEF should preserve successful proof structure without turning it into authority.

Example:

~~~text
goal class:
    list recursion preserving length

recipe:
    induction on explicit list
    simplify psListAppend
    reuse append_length

success history:
    14 of 16 related obligations
~~~

An AI may retrieve this recipe.

The resulting proof still requires ordinary checking.

---

# 36. Failure knowledge

Record failed attempts only when they reveal reusable structure.

Example:

~~~text
goal:
    environment lookup remains unchanged after add

failed assumption:
    only names differ syntactically

counterexample:
    name-equality normalization collision

repair:
    require psNameEq correctness plus explicit freshness
~~~

This becomes advisory knowledge linked to the semantic subject.

Do not publish raw noisy model traces as canonical knowledge by default.

Extract structured lessons.

---

# 37. Proof context slicing

For every obligation derive context from authoritative dependency information.

Candidate context:

~~~text
local variables
goal
transparent definitions required by reduction
direct theorem dependencies
candidate reusable theorems
relevant assumptions
effect model
canonical proof recipes
relevant failure knowledge
~~~

Avoid giving the agent the full compiler unless the dependency slice requires it.

This is both a performance feature and a SAVEF experimental variable.

---

# 38. Joint implementation-proof planning

After initial retrofitting, every new compiler feature in the experiment should begin with a joint plan:

~~~text
feature semantics
public interface impact
new obligations
expected reusable theorems
proof strategy
QueryGraph invalidation
backend implications
~~~

Only then modify implementation.

This tests whether planning for proofability reduces repair loops.

---

# 39. Proposed repository layout

Keep the 55-module source closure unchanged initially.

Add sidecar roots such as:

~~~text
psc15selfhost/savef/
    compiler-selfapp-profile.json
    factorybench-v1.json
    manifests/
    snapshots/

psc15selfhost/packages/foundation/
    spec/
    proof/

psc15selfhost/packages/core/
    spec/
    proof/

psc15selfhost/packages/environment/
    spec/
    proof/

...

psc15selfhost/packages/compiler/
    spec/
    proof/
~~~

Exact names may change.

The critical rule is:

~~~text
proof/spec support files
    must not accidentally enter
PSC1-selfhost-stable/1 compiler bootstrap closure
~~~

until an intentional profile revision makes them part of the source language.

---

# 40. Branch and workflow strategy

Recommended implementation branch:

~~~text
research/savef-compiler-selfapp-v1
~~~

or an equivalent dedicated branch.

Do not modify pskernel-core proof implementation on this branch.

Consume its evidence/status as an external dependency.

The self-application branch should:

- track psc2/pscv-direct-backends as implementation baseline;
- preserve existing self-host/fixed-point gates;
- add proof/spec sidecars modularly;
- push checkpoints after each accepted layer;
- never weaken compiler tests to make formalization easier.

---

# 41. Phase 0 — freeze the experiment

Before writing new proofs, create a reproducible baseline.

Freeze:

~~~text
compiler commit
55-module closure hash
self-host profile identity
Lean/compiler semantic identity
kernel provider policy
tool versions
model ID/version
model inference parameters
agent/tool protocol
benchmark task manifest
resource budgets
acceptance policy
~~~

Record current:

- fixed-point status;
- source/admission/emission hashes;
- test suite status;
- QueryGraph tests;
- direct backend tests;
- PSKernel semantic-audit snapshot.

Without this baseline, later productivity claims are not scientifically interpretable.

---

# 42. Phase 0 — CompilerFactoryBench-v1

Create a benchmark before publishing the knowledge that could leak answers into it.

The benchmark should contain at least 30 held-out tasks across at least five compiler packages.

Recommended task classes:

1. theorem completion;
2. invariant strengthening;
3. proof repair after implementation-preserving refactor;
4. semantic bug repair plus proof;
5. CertifiedModuleInterface-preserving refactor;
6. dependency-interface change requiring downstream repair;
7. small new compiler capability with implementation plus proof plan.

Tasks should vary in dependency-closure size.

Each task records:

~~~text
task ID
subject commit
allowed files
required acceptance gates
hidden expected semantic property
dependency closure
difficulty bucket
resource budget
~~~

The held-out solutions must not enter the searchable SAVEF graph before evaluation.

---

# 43. Baseline experiment B0

Run CompilerFactoryBench-v1 with:

~~~text
same model
same inference settings
same tool access
ordinary repository/source retrieval
no SAVEF semantic retrieval
~~~

Record per task:

- success/failure;
- wall time;
- model tokens;
- tool calls;
- proof attempts;
- compiler/test cycles;
- human interventions;
- files read;
- dependency context size;
- final assurance results.

This becomes the causal baseline.

---

# 44. Assisted experiment B1

Run the same benchmark policy with SAVEF retrieval enabled.

The model may receive:

- CertifiedModuleInterfaces;
- relevant theorem sets;
- exact assumption closure;
- semantic dependency slices;
- canonical proof recipes;
- selected structured failure knowledge.

It does not receive hidden benchmark solutions.

Compare against B0.

---

# 45. Experimental isolation

To avoid misleading results:

- pin model version;
- pin tool protocol;
- pin task order or randomization seed policy;
- pin resource limits;
- keep acceptance gates identical;
- do not change compiler source between paired runs unless the task itself changes it;
- isolate persistent agent memory between baseline and assisted runs;
- record all retrieved SPKF object IDs;
- keep benchmark holdouts outside the knowledge graph.

If a model upgrade occurs, start a new benchmark series.

---

# 46. Primary SAVEF productivity metrics

Define:

~~~text
SolveRate
MedianTokensPerAcceptedTask
MedianWallTimePerAcceptedTask
MedianHumanInterventions
MedianRepairIterations
SemanticContextBytes
NewImplementationLines
NewProofLines
~~~

Also track:

~~~text
TheoremReuseCount
SpecificationReuseCount
CertifiedInterfaceReuseCount
FailureKnowledgeReuseCount
~~~

The goal is not minimizing proof lines by itself.

The goal is reducing total production/supervision cost while preserving assurance.

---

# 47. Self-amplification pass condition

SAVEF-COMPILER-SELFAPP-v1 may claim measurable self-amplification only if all of the following hold.

## A — assurance non-regression

Every accepted assisted result passes the exact same semantic/test/kernel/fixed-point gates required of baseline results.

## B — real knowledge reuse

At least 30 percent of accepted assisted benchmark tasks consume at least one accepted knowledge object produced by an earlier compiler slice.

## C — productivity improvement

At least one primary productivity metric improves materially, with no material regression in solve rate or assurance.

Recommended initial target:

~~~text
at least 20 percent reduction
in median tokens or median wall time

OR

at least 10 percentage-point increase
in accepted solve rate
~~~

## D — closed-loop reuse

At least one compiler change produced using SAVEF must emit new accepted knowledge that is later used by another accepted compiler task.

A stronger publication claim should use repeated runs and confidence intervals rather than one model trajectory.

---

# 48. Strong statistical evaluation

For research-quality evidence:

- use paired tasks;
- run multiple independent repetitions per task where budget permits;
- pre-register primary metrics;
- report median and distribution, not only best run;
- bootstrap confidence intervals over task-level deltas;
- report failures and exclusions;
- separate model/tool crashes from proof failures.

Do not tune retrieval against the held-out benchmark and then report the same benchmark as independent evidence.

---

# 49. Knowledge leverage metrics

SAVEF should additionally measure whether the compiler theory is becoming more reusable.

Define engineering metrics such as:

~~~text
KnowledgeReuseRate
    accepted tasks reusing prior accepted objects
    /
    accepted tasks

ProofInvalidationFanout
    downstream proof tasks invalidated by one change

InterfaceStabilityRate
    implementation changes preserving semantic interface
    /
    implementation changes

ContextCompressionRatio
    raw dependency context bytes
    /
    SAVEF selected context bytes

KnowledgeYield
    accepted reusable objects
    /
    unit of human/model cost
~~~

These are empirical engineering metrics, not logical theorems.

---

# 50. The strongest self-application demonstration

The ideal demonstration is a real compiler evolution sequence.

Example:

~~~text
G0
current compiler

Task 1
prove Foundation/Core knowledge
    ->
K0

Task 2
use K0 to prove environment invariants
    ->
K1

Task 3
use K1 to strengthen Meta/Infer or specialization
    ->
K2

Task 4
use K2 to prove an erasure property
    ->
K3

Task 5
use K3 to implement/prove a new compiler capability
    ->
compiler G1

G1 passes:
    self-host profile
    canonical source parity
    fixed point
    semantic proof gates

G1 emits:
    new K4 knowledge

Task 6
uses K4 on another real compiler change
~~~

That closes the SAVEF loop on the compiler itself.


---

# 51. Provable and falsifiable criteria

Each criterion has equal weight 5.

Total weight is 100.

Evidence classes:

~~~text
P = machine-checked proof
M = deterministic machine/conformance test
A = adversarial test
R = reproducible/independent replay
E = empirical benchmark
~~~

## C1 — bounded self-application subject

**Claim:** the compiler experiment has a complete frozen subject rather than an open-ended moving repository.

**Pass evidence:** pinned commit, exact 55-module closure, source/profile identities, and closure hash.

**Failure witness:** modules silently enter or leave the experiment without changing experiment identity.

**Target:** 9.8. **Current:** 9.5.

## C2 — reproducible baseline

**Claim:** baseline compiler behavior and experiment conditions can be replayed.

**Evidence:** fixed toolchain/model/task manifests, self-host/fixed-point hashes, repeatable baseline runs.

**Failure witness:** B0 cannot be reproduced independently.

**Target:** 9.5. **Current:** 8.5.

## C3 — semantic-state honesty

**Claim:** AdmissionReady, CheckedCore, CertifiedSource, VerifiedIR, and PreservedTargetArtifact cannot be conflated.

**Adversarial test:** attempt to publish a stronger assurance object from a weaker state.

**Target:** 9.7. **Current:** 5.0.

## C4 — compiler specification coverage

**Claim:** selected public compiler behavior is connected to approved formal specifications rather than proof-file presence.

**Pass:** specification coverage can be computed for the selected compiler closure.

**Target:** 9.2. **Current:** 3.0.

## C5 — certified semantic interfaces

**Claim:** downstream proof work can depend on compact semantic interfaces rather than private implementation.

**Pass:** implementation-preserving change leaves dependent proof obligations green where justified.

**Target:** 9.5. **Current:** 4.5.

## C6 — actual theorem/knowledge reuse

**Claim:** later compiler work imports accepted earlier knowledge.

**Pass:** proof dependency graph records real reuse across compiler strata.

**Target:** 9.4. **Current:** 3.5.

## C7 — QueryGraph integration

**Claim:** SAVEF semantic dependencies extend the real incremental compiler graph rather than a disconnected AI database.

**Pass:** spec/theorem/interface changes invalidate exactly relevant downstream nodes.

**Target:** 9.5. **Current:** 7.5.

## C8 — proof-friendly implementation discipline

**Claim:** SAVEF preserves and exploits PSC1-selfhost-stable/1 rather than destabilizing self-host source.

**Pass:** proof/spec sidecars improve assurance without breaking existing self-host/fixed-point gates.

**Target:** 9.6. **Current:** 9.0.

## C9 — independent logical authority

**Claim:** the compiler cannot certify its own claims merely because it generated them.

**Pass:** accepted proof artifacts replay through designated external/kernel authority; high-assurance milestones support independent checking.

**Target:** 9.0. **Current:** 7.5.

## C10 — erasure and IR semantic evidence

**Claim:** the transition from certified source toward VerifiedIR has explicit preservation/validation evidence.

**Pass:** validator success implies declared IR invariants and ghost/proof noninterference is covered.

**Target:** 8.9. **Current:** 5.5.

## C11 — backend preservation path

**Claim:** direct JS/Wasm executable compiler artifacts can eventually inherit source claims through proof/translation validation.

**Pass:** target mutation that changes behavior fails preservation checking.

**Target:** 8.8. **Current:** 4.5.

## C12 — bootstrap claim separation

**Claim:** fixed point, compiler semantic correctness, backend preservation, and SAVEF productivity remain distinct evidence.

**Pass:** fixed-point success alone cannot mint compiler-correctness status.

**Target:** 9.8. **Current:** 9.0.

## C13 — AI/acceptance separation

**Claim:** AI cannot weaken specifications or acceptance gates while preserving identity.

**Adversarial test:** agent attempts to alter approved specification, benchmark evaluator, or required checks.

**Target:** 9.7. **Current:** 5.0.

## C14 — causal FactoryBench design

**Claim:** SAVEF benefit is measured against a fixed baseline.

**Pass:** same model/tool policy, paired tasks, same acceptance criteria, logged retrieval identities.

**Target:** 9.4. **Current:** 2.0.

## C15 — holdout and leakage resistance

**Claim:** benchmark tasks are not solved merely because their answers entered the knowledge graph.

**Pass:** held-out solutions are excluded from search; knowledge snapshots are frozen before evaluation.

**Target:** 9.2. **Current:** 1.5.

## C16 — measurable self-amplification

**Claim:** accepted knowledge materially improves later compiler production.

**Pass:** predefined productivity threshold plus assurance non-regression plus real knowledge reuse.

**Target:** 9.4. **Current:** 2.0.

## C17 — resource practicality

**Claim:** proof checking/retrieval/incremental reuse is affordable enough for normal compiler development.

**Measure:** wall time, peak memory, context bytes, cache hit rate, proof replay time.

**Target:** 9.0. **Current:** 7.0.

## C18 — incremental adoption

**Claim:** useful SAVEF benefits appear before complete whole-compiler verification.

**Pass:** L0/L1 knowledge is reusable while L4/L5 remain incomplete.

**Target:** 9.6. **Current:** 6.0.

## C19 — falsifiability

**Claim:** failure of SAVEF can be demonstrated rather than explained away.

**Pass:** explicit rejection criteria for no productivity gain, excessive invalidation, excessive proof cost, or unstable interfaces.

**Target:** 9.5. **Current:** 4.0.

## C20 — repository implementability

**Claim:** the plan maps onto actual existing packages and workflows.

**Pass:** no mandatory compiler rewrite, new logic, or central registry is needed for the first useful slices.

**Target:** 9.3. **Current:** 7.5.

---

# 52. Target architecture score

All criteria have weight 5.

| Criterion | Target |
| --- | ---: |
| C1 bounded subject | 9.8 |
| C2 reproducible baseline | 9.5 |
| C3 semantic-state honesty | 9.7 |
| C4 specification coverage | 9.2 |
| C5 certified interfaces | 9.5 |
| C6 knowledge reuse | 9.4 |
| C7 QueryGraph integration | 9.5 |
| C8 source discipline | 9.6 |
| C9 independent authority | 9.0 |
| C10 erasure/IR evidence | 8.9 |
| C11 backend preservation | 8.8 |
| C12 bootstrap separation | 9.8 |
| C13 AI separation | 9.7 |
| C14 causal benchmark | 9.4 |
| C15 holdout isolation | 9.2 |
| C16 self-amplification measurement | 9.4 |
| C17 resource practicality | 9.0 |
| C18 incremental adoption | 9.6 |
| C19 falsifiability | 9.5 |
| C20 repository implementability | 9.3 |

Average:

**9.39 / 10**

No criterion receives 10.

---

# 53. Current repository readiness score

| Criterion | Current |
| --- | ---: |
| C1 bounded subject | 9.5 |
| C2 reproducible baseline | 8.5 |
| C3 semantic-state honesty | 5.0 |
| C4 specification coverage | 3.0 |
| C5 certified interfaces | 4.5 |
| C6 knowledge reuse | 3.5 |
| C7 QueryGraph integration | 7.5 |
| C8 source discipline | 9.0 |
| C9 independent authority | 7.5 |
| C10 erasure/IR evidence | 5.5 |
| C11 backend preservation | 4.5 |
| C12 bootstrap separation | 9.0 |
| C13 AI separation | 5.0 |
| C14 causal benchmark | 2.0 |
| C15 holdout isolation | 1.5 |
| C16 measured amplification | 2.0 |
| C17 resource practicality | 7.0 |
| C18 incremental adoption | 6.0 |
| C19 falsifiability | 4.0 |
| C20 repository implementability | 7.5 |

Average:

**5.60 / 10**

The low current score is not a criticism of the compiler.

It reflects that the self-amplification experiment itself has not yet been run.

---

# 54. Architecture iteration loop

## Iteration A — prove the compiler, then call it SAVEF

Design:

~~~text
write proofs for compiler
publish theorem graph
declare self-application
~~~

Score:

**6.72 / 10**

Rejected because it confuses verification with self-amplification and has no causal baseline.

## Iteration B — layered compiler knowledge graph

Added:

- dependency-stratified proof order;
- semantic sidecars;
- CertifiedModuleInterface;
- QueryGraph integration;
- SPKF knowledge extraction;
- failure/proof recipe knowledge;
- incremental adoption.

Score:

**7.94 / 10**

Still below target because productivity evidence is observational and benchmark leakage is insufficiently controlled.

## Iteration C — accepted self-application architecture

Added:

- CompilerFactoryBench-v1;
- frozen B0 baseline;
- assisted B1 ablation;
- holdout isolation;
- explicit productivity thresholds;
- assurance non-regression;
- closed-loop compiler generation requirement;
- knowledge reproducibility;
- independent logical authority;
- distinction between SAVEF economic proof and complete compiler verification.

Final score:

**9.39 / 10**

This clears the requested score of 8.

---

# 55. Why complete compiler verification is not required before SAVEF can be tested

Suppose Foundation/Core knowledge measurably reduces the cost of proving Environment/Meta while all results pass the same acceptance gates.

That is already evidence for the SAVEF mechanism.

We do not need to wait until all of these are complete:

~~~text
parser proof
elaborator proof
erasure proof
JavaScript preservation
Wasm preservation
~~~

before testing whether accumulated checked knowledge helps.

Waiting for complete verification would make SAVEF unnecessarily difficult to validate experimentally.

Therefore use progressive assurance:

~~~text
prove useful knowledge
measure reuse
expand coverage
increase assurance
repeat
~~~


---

# 56. What complete compiler self-application eventually means

Strong final state:

~~~text
55-module compiler closure
    |
    +--> specification coverage
    +--> checked theorem interfaces
    +--> assumption closure
    +--> CertifiedModuleInterfaces
    |
    v
real CheckedCore
    |
    v
PSCV CertifiedSource
    |
    v
VerifiedIR
    |
    +--> preserved direct JS compiler
    |
    +--> preserved direct Wasm compiler
    |
    v
compiler self-host fixed point
    |
    v
deterministic compiler knowledge graph
    |
    v
SAVEF-assisted next compiler generation
~~~

This would combine:

- compiler correctness evidence;
- bootstrap evidence;
- artifact preservation;
- incremental proof reuse;
- measured self-amplification.

---

# 57. First six implementation PRs

The implementation should begin with small, high-information PRs.

## PR 1 — experiment baseline

Add:

- compiler-selfapp-profile;
- exact baseline commit/closure identity;
- FactoryBench schema;
- metrics schema;
- no semantic compiler changes.

## PR 2 — Foundation.List knowledge seed

Add:

- module specification;
- list theorem sidecar;
- checked proof results;
- theorem interface;
- SPKF knowledge objects.

Goal: establish the end-to-end knowledge publication path.

## PR 3 — Foundation.Name + Core substitution seed

Add high-reuse equality/substitution theorems.

Begin proof-recipe extraction.

## PR 4 — first CertifiedModuleInterface + QueryGraph key

Generate a canonical interface for one small module.

Prove/test that a stable-interface implementation change keeps a dependent green.

## PR 5 — environment proof uses L0 knowledge

Require at least one accepted environment theorem to import/reuse earlier L0 theorem knowledge.

This demonstrates real modular reuse.

## PR 6 — first controlled A/B proof task

Run the same held-out environment/meta proof task:

~~~text
without SAVEF retrieval
versus
with SAVEF retrieval
~~~

Record all metrics.

This produces the first actual evidence about the self-amplification hypothesis.

---

# 58. Next milestone sequence

After the six initial PRs:

~~~text
M1
L0 theorem library accepted

M2
L1 environment/IR knowledge accepted

M3
semantic QueryGraph + CertifiedModuleInterface operational

M4
meta/specialization assisted by prior knowledge

M5
erasure assisted by accumulated knowledge

M6
syntax/elaboration benchmark demonstrates reuse benefit

M7
real CheckedCore compiler path

M8
PSCV-CERT compiler modules

M9
direct Wasm preservation lane

M10
direct JS preservation lane

M11
whole compiler SAVEF self-application generation

M12
FactoryBench publication
~~~

---

# 59. Practicality controls

The experiment must remain usable by compiler developers.

Set budgets for:

~~~text
fast edit-time checks
module proof replay
knowledge extraction
knowledge lookup
full release replay
~~~

Principles:

- fast developer checks should remain seconds-scale where currently possible;
- module-scoped proof checks should avoid whole-repository replay;
- expensive full-closure checks belong at checkpoint/release boundaries;
- cache corruption causes recomputation, never acceptance;
- AI retrieval must cap context by semantic dependency budget;
- proofs that are not downstream-visible should not force global invalidation.

Do not allow SAVEF to turn every edit into a whole-compiler theorem replay.

---

# 60. What not to change during the first experiment

Avoid simultaneous large changes to:

- language grammar;
- self-host source profile;
- compiler package decomposition;
- kernel-provider policy;
- backend architecture;
- package manager;
- SPKF core format.

Otherwise it becomes difficult to attribute measured improvements to SAVEF.

The experiment should add knowledge and measurement around the existing compiler first.

---

# 61. What would falsify SAVEF on the compiler?

The hypothesis should be revised if repeated controlled experiments show any of these.

1. Accepted semantic knowledge does not improve solve rate, tokens, wall time, or human effort.
2. Proof-maintenance invalidation cost grows faster than theorem reuse benefit.
3. CertifiedModuleInterfaces cannot hide enough implementation detail to stabilize downstream proofs.
4. Semantic context slicing omits critical facts so often that full-repository context performs better.
5. Proof/specification authoring cost dominates all later reuse.
6. AI proof recipes cause more misleading search than useful acceleration.
7. QueryGraph semantic invalidation becomes too complex or unsafe.
8. Kernel/proof replay latency prevents practical compiler iteration.
9. The 55-module source discipline is so restrictive that proving against it costs substantially more than maintaining an alternative implementation.
10. Repeated later compiler tasks do not consume knowledge produced by earlier ones.

Publishing negative results is part of the experiment.

---

# 62. What would count as strong success?

A strong but realistic first publication claim would be:

> Under a pinned compiler commit family, fixed model/version, fixed tool protocol, and identical assurance gates, SAVEF semantic retrieval over previously accepted compiler theorem/interfaces increased accepted task success or reduced median production cost on a held-out CompilerFactoryBench task set; at least 30 percent of accepted tasks reused earlier knowledge; and at least one accepted SAVEF-assisted compiler change produced a knowledge object reused by a later accepted compiler change.

That is a much stronger statement than:

> AI helped us prove the compiler.

---

# 63. Canonical recommendation

Apply SAVEF to the PSCV compiler through **progressive semantic sidecars and measured knowledge reuse**, not through a disruptive whole-compiler rewrite.

The core loop should be:

~~~text
current compiler module
    |
    v
approved specification
    |
    v
checked theorem/interface
    |
    v
SPKF knowledge
    |
    v
QueryGraph semantic slice
    |
    v
AI/human next compiler task
    |
    v
independent checker
    |
    v
accepted compiler change
    |
    v
new SPKF knowledge
    |
    +------------------------> repeat
~~~

Existing self-host and fixed-point gates stay in place throughout.

---

# 64. Final decision

The PSCV compiler is a strong first SAVEF self-application target.

The plan is feasible because it can begin with:

- the existing 55-module bounded compiler;
- PSC1-selfhost-stable/1;
- current Lean proof tooling;
- current PSKernel proof work;
- current QueryGraph;
- current fixed-point infrastructure;
- current SPKF architecture.

It does not require:

- complete PSCV implementation;
- complete PSKernel proof;
- complete JS/Wasm backend proof;
- a new package manager;
- a new central registry;
- rewriting the compiler before measuring value.

The architectural plan scores:

**9.39 / 10**

Current readiness is:

**approximately 5.60 / 10**

The most valuable immediate action is not to attack the 8,207-line syntax package or the 4,792-line elaborator.

It is to create the experimental baseline and turn the approximately 1,113-line Foundation/Core layer into the first reusable compiler mathematics library.

Then test whether that library measurably makes Environment, Meta, Erasure, Syntax, and Elaborator work cheaper.

If it does, the PSCV compiler will not merely be built with SAVEF.

It will become the first serious evidence that SAVEF's core compounding hypothesis works on a real self-hosting software system.
