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
