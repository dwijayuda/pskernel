# ProofScript Self-Amplifying Verified Ecosystem Factory

**Status:** strategic research document; non-normative.

**Working concept:** SAVEF — Self-Amplifying Verified Ecosystem Factory.

**Research snapshot:** 2026-10-06.

**Language context:** ProofScript PSCV, or a future compatible successor, with Lean-grounded semantics and PSKernel as the final proof-admission authority.

**Relationship to existing ProofScript research:** this document extends the Verified Ecosystem Factory (VEF-Core) and Verified Spec-Driven Development (VSDD) directions. It does not add language syntax or normative semantics. Its purpose is to define a stronger long-term research target: make ecosystem growth itself reduce the cost of producing the next correct, interoperable, reusable capability.

---

# Executive thesis

ProofScript should not be evaluated only as a programming language, theorem prover, compiler, or AI coding environment.

The stronger possibility is:

> **ProofScript can become a software-production system in which executable software knowledge accumulates in a form closer to mathematics than to ordinary test-driven software ecosystems, while empirical methods remain explicit at the boundaries where claims depend on reality rather than formal models.**

Conventional software ecosystems already compound through reuse:

~~~text
language
  -> standard library
  -> packages
  -> frameworks
  -> platforms
  -> applications
~~~

But most of the knowledge encoded in those layers is implicit. It lives in source code, documentation, tests, production experience, issue histories, conventions, and human understanding.

A ProofScript ecosystem could make substantially more of that knowledge explicit and machine-composable:

~~~text
definitions
+ specifications
+ implementations
+ theorems
+ invariants
+ refinement relations
+ effect models
+ explicit assumptions
+ proof automation
+ empirical evidence at external boundaries
~~~

If these assets compose well, later software can rely on already-established results instead of rediscovering correctness primarily through repeated testing and human review.

The long-term target is therefore:

> **Make the marginal cost of producing correct, interoperable, reusable ecosystem capability decrease as the verified ecosystem grows.**

AI matters because it can search, synthesize, formalize, prove, repair, integrate, migrate, and generalize at scale.

But AI must remain an untrusted proposer.

> **AI searches; deterministic semantics and verification decide.**

The target is not:

~~~text
AI -> code -> tests -> ship
~~~

and not merely:

~~~text
AI -> code + proof -> kernel
~~~

It is closer to:

~~~text
human intent
    |
    v
formalized goals + explicit assumptions
    |
    v
existing verified theory/capability graph
    |
    v
AI planning / synthesis / proof / repair
    |
    v
deterministic compiler + proof obligations
    |
    v
proof automation / decision procedures / validators
    |
    v
PSKernel / independent checkers
    |
    v
verified or evidence-carrying capability
    |
    v
extract reusable definitions, theorems, patterns,
counterexamples, models, and automation
    |
    v
grow the ecosystem's machine-readable knowledge
    |
    v
make the next task cheaper
    +-------------------------------+
                                    |
                                    +---- repeat
~~~

That final feedback loop is what makes the factory **self-amplifying**.

---

# 1. Central research question

The key question is not merely:

> Can ProofScript formally verify software?

Formal-methods systems have already demonstrated that deep software verification is possible in important domains.

The harder and more consequential question is:

> **Can ProofScript make formalization, verification, proof reuse, proof maintenance, software composition, and AI-assisted construction cheap enough that deductive software construction scales economically better than conventional empirical software engineering for important classes of software?**

This has several subquestions:

1. Can the semantic concepts needed by real software be represented formally without bloating the trusted core?
2. Can packages expose behavioral knowledge strong enough that downstream systems reason from interfaces instead of re-reading implementations?
3. Can proof dependencies remain stable under refactoring?
4. Can AI consume semantic dependency slices instead of entire repositories?
5. Can successful software work produce reusable formal knowledge, not only source code?
6. Can external ecosystems be incorporated progressively without pretending unverified foreign software is proved?
7. Can the amount of human supervision decrease as the verified theory graph grows?
8. Can the factory improve while model capability is held approximately constant?
9. Can correctness gains coexist with acceptable runtime performance and development velocity?
10. Can failures become reusable knowledge rather than discarded trial-and-error traces?

If these cannot be demonstrated, **self-amplifying** should remain a research hypothesis rather than a product claim.

---

# 2. Definitions

## 2.1 Verified Ecosystem Factory

A **Verified Ecosystem Factory** is a software-production system in which specifications, implementations, proof obligations, checked evidence, compilation, reusable packages, and artifact production participate in one explicit trust architecture.

Its output is not limited to applications. It can produce:

- libraries;
- packages;
- APIs;
- proof libraries;
- tactics;
- compiler extensions;
- verified DSLs;
- foreign bindings;
- adapters;
- code generators;
- tooling;
- state-machine models;
- protocol models;
- benchmarks;
- conformance suites;
- documentation;
- agent skills;
- reusable proof and implementation patterns.

## 2.2 Self-Amplifying Verified Ecosystem Factory

A **Self-Amplifying Verified Ecosystem Factory** adds a stronger requirement:

> **Accepted outputs become structured inputs to future production in ways that measurably improve later productivity, correctness, reuse, or cost.**

A candidate empirical condition is:

~~~text
for comparable task distributions,
while model capability is approximately fixed:

human_effort(N + 1) <= human_effort(N)
verification_cost(N + 1) <= verification_cost(N)
success_rate(N + 1) >= success_rate(N)
reuse_rate(N + 1) >= reuse_rate(N)
~~~

where N is the amount of accepted reusable ecosystem knowledge available to the factory.

Literal exponential improvement is not assumed.

The research target is **compounding productivity**.

---

# 3. The mathematics analogy

The analogy between verified software construction and mathematics is strong, but it must be stated carefully.

C. A. R. Hoare's 1969 work on axiomatic programming explicitly framed program reasoning using axioms and inference rules. Lean's dependent type theory goes further: propositions and proofs inhabit the same foundational language as definitions and programs. Under propositions-as-types, a proposition is represented by a type and a proof by an inhabitant of that type.

For ProofScript, a useful correspondence is:

| Mathematics | ProofScript software |
| --- | --- |
| Logical foundation | Lean-grounded PSCV semantics |
| Primitive assumptions | Explicit axioms, runtime assumptions, foreign assumptions |
| Definition | Type, protocol, state model, interface, data structure |
| Proposition | Software property or specification |
| Lemma | Reusable invariant or behavioral fact |
| Theorem | Verified correctness or refinement result |
| Constructive witness | Executable implementation |
| Proof | Machine-checkable evidence |
| Mathematical library | Verified software theory library |
| Theory extension | Package or capability extension |
| Imported theorem | Dependency guarantee |
| Proof checker | PSKernel |
| Derived theory | Framework, platform, or verified subsystem |

A sufficiently formal ProofScript package should therefore be understood as more than code.

It can be a **small executable theory**.

This is particularly powerful in constructive settings because a witness to an existence claim can itself be executable.

Conceptually:

~~~text
Specification:
    exists implementation,
        implementation satisfies Protocol

Construction:
    produce implementation

Proof:
    implementation satisfies Protocol
~~~

The implementation and its correctness argument become parts of the same mathematical construction.

---

# 4. The science analogy for conventional software

Conventional software development has a useful science-like epistemic structure: much of its confidence is acquired empirically.

A common workflow is approximately:

~~~text
hypothesis:
    this implementation behaves correctly

experiment:
    unit tests

additional experiments:
    integration tests
    property tests
    fuzzing
    benchmarks
    production telemetry

result:
    accumulated confidence
~~~

Software engineering is not literally natural science; software is a human-constructed artifact. But the distinction in evidence is useful.

An empirical claim is approximately:

> This behavior has been exercised successfully across many observations.

A deductive claim is approximately:

> For every state satisfying the stated assumptions, this property follows from the formal semantics and a machine-checked derivation.

Both forms of evidence are valuable.

They answer different questions.

---

# 5. Proofs do not replace all tests

The correct ProofScript objective is **not**:

> Replace testing with theorem proving.

Formal proof establishes claims relative to a model and assumptions.

It does not by itself prove that:

- the model captures what users actually wanted;
- physical hardware behaves exactly as modeled;
- a remote service still follows a documented contract;
- a cloud provider meets a latency target;
- humans find a UI usable;
- a cryptographic hardness assumption holds in reality;
- an external vendor has not changed behavior;
- a deployment handles a particular workload within a particular time budget.

The stronger principle is:

> **Move every important claim that can economically be made mathematical into the deductive domain. Keep empirical validation at the boundary where the claim depends on reality, performance, humans, external systems, or intentionally unformalized components.**

This gives the foundational maxim:

> **Mathematics inside; science at the boundary.**

---

# 6. Four epistemic layers

A ProofScript application should make the boundary explicit:

~~~text
+--------------------------------------+
| HUMAN INTENT / REAL WORLD            |
|                                      |
| users, economics, hardware, networks |
+-------------------+------------------+
                    |
                    | empirical validation
                    v
+--------------------------------------+
| EXPLICIT ASSUMPTIONS                 |
|                                      |
| external APIs, device models, SLAs,  |
| foreign runtimes, crypto assumptions |
+-------------------+------------------+
                    |
                    | formalization
                    v
+--------------------------------------+
| SOFTWARE MATHEMATICS                 |
|                                      |
| definitions                          |
| specifications                       |
| programs                             |
| invariants                           |
| proofs                               |
| refinements                          |
+-------------------+------------------+
                    |
                    | semantics-preserving compilation
                    v
+--------------------------------------+
| EXECUTABLE ARTIFACT                  |
|                                      |
| JS / WASM / native / other targets   |
+--------------------------------------+
~~~

The factory's long-term mission is:

> **Push the Software Mathematics frontier outward as far as is economically useful, while shrinking and clarifying the remaining empirical assumption boundary.**

---

# 7. Formal claims are conditional

Suppose ProofScript establishes:

~~~text
Gamma |- Program satisfies Specification
~~~

where Gamma contains assumptions.

Suppose the compiler establishes a preservation statement equivalent in intent to:

~~~text
Program satisfies Specification
    =>
CompiledArtifact satisfies Specification
~~~

Deployment still needs confidence that the real environment satisfies the modeled assumptions:

~~~text
RealWorld satisfies Gamma
~~~

The end-to-end argument is therefore:

~~~text
Gamma |- Program satisfies S

compiler preserves S

reality satisfies Gamma
--------------------------------

deployed artifact satisfies S
~~~

A successful formal proof must never erase the assumptions under which it is valid.

---

# 8. Software Theory Capsules

A conventional package usually exposes:

~~~text
name
version
dependencies
code
types
documentation
~~~

A mature ProofScript package should be capable of exposing a richer object.

Working concept:

> **Software Theory Capsule**

Example:

~~~text
package verified.queue

Definitions:
    Queue
    QueueState
    QueueOperation

Assumptions:
    allocator conforms to AllocatorSpec

Specifications:
    fifo
    bounded
    noLoss

Implementation:
    ArrayQueue

Proofs:
    ArrayQueue satisfies fifo
    ArrayQueue satisfies bounded
    ArrayQueue satisfies noLoss

Effects:
    memory
    concurrency

Complexity:
    push = amortized O(1)
    pop  = O(1)

Refinements:
    ArrayQueue refines AbstractQueue

Targets:
    JS
    WASM
    native

Evidence:
    kernel-checked proofs
    benchmark evidence
    external conformance evidence
~~~

The exact serialized representation is future architecture work.

The important idea is that a package exports **knowledge about behavior**, not merely implementation bytes and names.

---

# 9. Deep specifications as the composition boundary

The DeepSpec project uses the term **deep specifications** for specifications that are rich, two-sided, formal, and live: rich enough to characterize behavior, useful to both implementations and clients, written in precise mathematical form, and connected by machine-checkable evidence to actual code.

This is directly relevant to ProofScript.

A scalable verified ecosystem cannot require every downstream client to inspect dependency implementations.

Instead:

~~~text
Implementation A proves SpecA

Client B assumes only SpecA
Client B proves SpecB

Client C assumes only SpecB
Client C proves SpecC
~~~

If the interfaces are strong enough, changing A's internal implementation should not invalidate B and C.

This is the verified analogue of information hiding.

---

# 10. Layered construction already has strong precedents

Several formal-methods projects demonstrate pieces of this architecture.

## 10.1 CertiKOS

CertiKOS demonstrates operating-system construction through formally specified abstraction layers and refinement relationships.

The lesson for ProofScript is:

> Large systems can be assembled through semantic layers when each layer exposes a sufficiently strong abstraction and proves the relationship to the layer below it.

## 10.2 CompCert

CompCert demonstrates semantic preservation across a realistic optimizing compiler. Correctness is composed across compiler passes.

The lesson for ProofScript is:

> A source-level proof becomes much more valuable when compilation itself preserves the relevant semantics.

## 10.3 RustBelt

RustBelt demonstrates how an ecosystem with unsafe internals can still preserve language-level guarantees by requiring each unsafe library extension to satisfy an explicit verification condition.

The lesson for ProofScript is:

> Ecosystem extension can be formalized as an obligation rather than accepted as an act of trust.

This principle can apply to:

- packages;
- unsafe primitives;
- FFI adapters;
- compiler plugins;
- backends;
- runtime primitives;
- effect handlers;
- domain-specific languages.

---

# 11. Conservative extension as an ecosystem metric

In mathematics, adding a false or unnecessary axiom can contaminate a large theory.

ProofScript should adopt a similar concern.

A high-quality verified package should preferably extend the ecosystem through:

~~~text
existing definitions + assumptions
        |
        v
new definitions
new implementations
new proved theorems
~~~

rather than:

~~~text
existing theory
    +
new unproved axiom
    +
many consequences
~~~

This motivates an important metric:

> **Conservative-extension ratio:** what fraction of ecosystem growth adds usable capability without increasing the unproved trust surface?

---

# 12. The Axiom Budget

Formal verification can create false confidence if assumptions are hidden.

Assumptions must therefore become first-class, transitive, inspectable objects.

A future ProofScript tool should be able to compute something conceptually like:

~~~text
TransitiveAssumptions(MyApplication)
~~~

and report:

~~~text
Mathematical assumptions:
    selected classical principles

Foreign-runtime assumptions:
    JS host obeys selected runtime model

OS assumptions:
    Linux write conforms to modeled syscall contract

Database assumptions:
    PostgreSQL transaction boundary conforms to adapter model

Cryptographic assumptions:
    selected hardness assumptions

Empirical claims:
    p99 database latency < 20 ms

Unchecked dependencies:
    legacy image decoder
~~~

A verified claim should therefore be interpreted as:

> proved under this exact transitive assumption set.

The factory should make assumption growth visible and reviewable.

---

# 13. Evidence classes

Not every property should use the same evidence mechanism.

A mature factory should distinguish evidence classes such as:

| Evidence class | Typical use |
| --- | --- |
| Kernel proof | mathematical functional and safety claims |
| Certified decision procedure | decidable logical fragments |
| Translation validation | compiler/transformation correctness |
| Model checking | finite-state protocols and state machines |
| Conformance testing | interoperability with external implementations |
| Property testing | empirical search for counterexamples |
| Differential testing | agreement with reference implementations |
| Benchmark | latency, throughput, memory, energy claims |
| Runtime monitoring | environmental assumptions over time |
| Human review | subjective product and usability claims |
| External assumption | claim intentionally outside current formal model |

This prevents two opposite mistakes:

1. pretending tests are proofs;
2. demanding enormous formal proofs for claims better established empirically.

The factory should choose the strongest economically practical evidence mechanism for each claim class.

---

# 14. Software-domain formalization coverage

The fundamental language question is not:

> Does PSCV contain every feature of TypeScript, Rust, Python, or C++?

The stronger question is:

> **Can PSCV efficiently represent the semantic concepts required to formalize software in those ecosystems?**

A preliminary coverage map:

| Domain | Formal machinery likely required |
| --- | --- |
| Pure algorithms | inductive types, equations, dependent/refinement types |
| Data structures | invariants, algebraic laws |
| Mutable state | Hoare-style reasoning, effects |
| Heap and memory | separation/resource logic |
| Ownership | linear/resource reasoning |
| Errors and partiality | explicit effects, result types, preconditions |
| I/O | trace semantics and effect specifications |
| Async | effect/state-machine semantics |
| Concurrency | separation logic, linearizability, rely/guarantee styles |
| Distributed systems | state machines, temporal logic, refinement, failure models |
| Protocols | session/state-machine semantics |
| Filesystems | abstract state + refinement |
| OS interfaces | syscall models |
| Security | information flow, noninterference, capabilities |
| Cryptography | functional correctness + explicit hardness assumptions |
| Randomized algorithms | probabilistic semantics |
| Resource use | cost semantics, amortized bounds |
| Runtime / GC | semantic refinement |
| Compiler | semantic preservation / translation validation |
| FFI | explicit boundary contracts |
| Network | protocol model + environment assumptions |
| Hardware | ISA and memory model |
| Performance | formal complexity + empirical measurement |

Research systems such as Iris and Aneris demonstrate that sophisticated concurrent and distributed reasoning can be built as reusable logical frameworks rather than language-kernel special cases.

The ProofScript research problem is therefore not to invent all verification theory from scratch.

It is to integrate suitable theories into a coherent, practical, compositional, AI-friendly programming environment.

---

# 15. Keep the trusted core small

The wrong architecture would place every domain logic in PSCV or PSKernel.

Do not bake into the trusted core:

- HTTP logic;
- database logic;
- filesystem logic;
- concurrency logic;
- distributed-system logic;
- SQL logic;
- UI logic.

The preferred architecture is:

~~~text
small stable PSCV / Lean-grounded foundation
        +
small PSKernel proof authority
        +
extensible formal libraries
        +
domain logics
        +
verified DSLs
        +
proof automation
        +
untrusted AI synthesis
~~~

Mathematical logic does not need primitive kernel rules for groups, rings, topology, or measure theory.

Likewise ProofScript should enable software theories to be defined **inside** a stable foundation.

---

# 16. Conceptual division of responsibility

~~~text
PSKernel
    = final proof-admission authority

PSCV
    = executable formal programming language

ProofScript foundational libraries
    = reusable software mathematics

ProofScript packages
    = executable theories and refinements

Compiler
    = checked semantic transformation pipeline

Package/capability graph
    = indexed body of reusable software knowledge

AI agents
    = untrusted search, synthesis, proof, repair, and generalization

Verified Ecosystem Factory
    = orchestration that turns goals into accepted reusable capabilities
~~~

This is a more ambitious identity than "verified programming language."

---

# 17. Verified Theory Graph

A conventional package registry primarily records dependencies.

A ProofScript ecosystem should eventually support a richer graph.

Working concept:

> **Verified Theory Graph**

Possible node kinds:

- definition;
- type;
- interface;
- specification;
- implementation;
- theorem;
- invariant;
- effect model;
- capability;
- runtime model;
- benchmark;
- assumption;
- counterexample;
- tactic;
- proof pattern.

Possible edge kinds:

~~~text
defines
implements
proves
refines
requires
assumes
preserves
specializes
generalizes
compatible-with
adapts
validated-by
benchmarked-by
replaces
~~~

Example:

~~~text
Definition Queue
    |
    +--specified-by--> QueueSpec
    |
    +--implemented-by--> ArrayQueue
                           |
                           +--proven-by--> fifo_theorem
                           +--proven-by--> bound_theorem
                           +--refines----> AbstractQueue
~~~

AI should query this graph directly instead of reconstructing these relationships from source text and prose.

---

# 18. Package resolution can become partial theorem search

Today's package managers ask questions such as:

> Does version 3.2 satisfy the requested version range?

A ProofScript package resolver could eventually also ask:

- Does dependency A provide capability X?
- Does implementation A refine interface B?
- Are effect requirements compatible?
- Are required assumptions available?
- Does the selected backend preserve the required semantic class?
- Does version N+1 prove compatibility with version N?
- Does composition preserve invariant I?

Dependency resolution would not become pure theorem proving, but it could incorporate formal refinement and capability reasoning.

---

# 19. Formal semantic compatibility

Conventional semantic versioning is mainly a social convention.

A verified ecosystem can eventually support stronger compatibility evidence.

For example:

~~~text
NewAPI refines OldAPI
~~~

or, under an explicit client model:

~~~text
for all clients satisfying assumptions A,
behavior(NewVersion) observationally refines behavior(OldVersion)
~~~

This could make AI-assisted migration substantially safer.

Changelogs remain useful.

They are no longer the only source of semantic truth.

---

# 20. Proof maintenance is a first-class economic problem

The existence of a proof is not sufficient.

If every implementation change creates large downstream proof breakage, the factory loses its economic advantage.

Therefore the language and ecosystem must optimize for:

- proof abstraction;
- stable interfaces;
- localized dependencies;
- incremental checking;
- theorem discoverability;
- semantic change analysis;
- proof repair;
- automated obligation regeneration.

For every proposed ProofScript feature, ask:

~~~text
Can it express the desired property?

Can the proof compose?

Can clients depend only on abstract guarantees?

Can implementation refactoring preserve downstream proofs?

Can the compiler determine which proofs are actually invalidated?

Can AI retrieve the minimal relevant dependency slice?
~~~

Proof maintenance cost should be measured as carefully as compile time.

---

# 21. Why this matters for AI

Most coding agents operate through an empirical repair loop:

~~~text
generate
  -> run
  -> test fails
  -> patch
  -> run
  -> repeat
~~~

A ProofScript agent can operate against explicit semantic state:

~~~text
goal
  -> retrieve relevant definitions
  -> retrieve relevant theorems
  -> synthesize implementation
  -> synthesize proof/evidence
  -> deterministic checker accepts or rejects
~~~

The agent does not need to be trusted to evaluate itself.

This changes the economics of AI supervision.

The goal should not merely be:

> AI writes more code.

The stronger target is:

> **Machine supervision becomes cheaper than human supervision for an increasing fraction of software claims.**

---

# 22. Current AI evidence and what it implies

This section is a point-in-time research snapshot. Model names and frontier performance will change; the architectural lessons should survive model turnover.

## 22.1 Verification-language design changes AI difficulty

AlgoVeri evaluates the same 77 algorithmic tasks in Dafny, Verus, and Lean. Its 2026 results show materially higher verified-code-generation success in Dafny than Lean, with the paper attributing much of the gap to higher-level abstractions, automation, and the burden of explicit proof construction.

The important lesson is:

> **A rigorous foundation does not require exposing AI to the lowest-level proof workflow.**

PSCV should preserve Lean-grade foundations while offering software-oriented specification forms, obligation generation, tactics, decision procedures, and possibly certificate-producing external automation.

## 22.2 Repository-scale verification remains hard

Vero evaluates joint implementation-and-proof generation across multi-module Lean repositories.

The benchmark demonstrates that individual proof competence does not automatically scale to coherent repository construction.

The lesson is:

> **Repository architecture, modular specifications, dependency management, and proof-context retrieval are core AI infrastructure, not secondary tooling.**

## 22.3 Relevant semantic context matters

VeriSoftBench reports that success decreases as proof tasks depend on larger transitive repository closures, and that curated dependency context performs better than exposing the entire repository.

The lesson is:

> **Context-window size is not a substitute for semantic slicing.**

ProofScript should expose exact dependency closures and relevant theorem slices directly from compiler and proof metadata.

## 22.4 Program and proof should be planned together

P³ studies joint program-and-proof planning and reports better solve rates and lower cost than workflows that construct an implementation first and attempt proof afterward.

The lesson is:

> **Proofability should influence architecture and implementation synthesis from the beginning.**

The factory should jointly optimize:

- correctness;
- proof simplicity;
- API quality;
- composability;
- runtime performance;
- target portability;
- future reuse.

## 22.5 AI-generated code can pass functional checks while remaining insecure

SUSVIBES reports a large gap between functional correctness and security correctness for coding-agent outputs.

The lesson is:

> **"Tests pass" is an insufficient authority boundary for autonomous software production.**

Security properties should be represented as explicit obligations whenever practical, supplemented by independent analysis and adversarial testing where full proof is not economical.

## 22.6 Agents can optimize the checker rather than the intended goal

2026 reward-hacking benchmarks show that tool-using agents can skip verification, tamper with evaluation-relevant state, exploit metadata, or otherwise optimize a proxy instead of the intended task.

The lesson is architectural:

> **The system generating a candidate must not own the authority that decides whether the candidate is accepted.**

ProofScript should separate:

~~~text
candidate producer
    from
specification authority
    from
proof checker / validator
    from
release decision
~~~

---

# 23. AI-native, not AI-dependent

PSCV should never require a particular LLM for correctness.

Instead it should expose deterministic interfaces that make any current or future model more effective.

A future ProofScript Agent ABI could support queries conceptually like:

~~~text
getGoal(goalId)

getRelevantDefinitions(goalId)

getProofDependencySlice(goalId)

getCallGraph(symbol)

getEffectGraph(symbol)

getInvariantDependencies(symbol)

getSemanticDiff(base, head)

getAffectedProofs(change)

getCandidateLemmas(goal)

getCounterexample(obligation)

getCapabilityCandidates(requirements)

getTransitiveAssumptions(symbol)

getRefinementPath(from, to)
~~~

The exact API is future design work.

The stable principle is:

> **Give agents structured semantics, not only source text.**

---

# 24. Structured diagnostics

Compiler and verifier failures should have machine-readable forms.

Example conceptual structure:

~~~text
Obligation {
    id
    sourceRange
    proposition
    assumptions
    relevantSymbols
    dependencySlice
    effectContext
    failedRule
    candidateLemmas
    counterexample
    proofStatus
}
~~~

Human-readable diagnostics can be a rendering of the same underlying structure.

This gives AI a semantic repair problem rather than a prose-parsing problem.

---

# 25. Joint program-and-proof planning

A common failure pattern is:

~~~text
write implementation
    ->
attempt proof
    ->
discover architecture is difficult to prove
    ->
rewrite implementation
    ->
rewrite proof
~~~

A better factory plans simultaneously for:

- semantic correctness;
- proof simplicity;
- API usability;
- composition;
- performance;
- backend portability;
- future reuse.

Implementation architecture should therefore be selected partly for **proofability**.

This is not proof-oriented code golf.

It is engineering for stable, machine-checkable abstraction boundaries.

---

# 26. Specification integrity

Formal verification proves that an implementation satisfies a formal specification.

It does **not** automatically prove that the formal specification is the correct interpretation of human intent.

This creates a dangerous failure mode for AI systems:

~~~text
AI writes spec
AI writes implementation
AI weakens spec
AI writes proof
AI says verified
~~~

A high-assurance factory should separate these roles.

Preferred flow:

~~~text
human requirement
      |
      v
candidate formalization
      |
      v
specification audit
  - ambiguity checks
  - counterexamples
  - mutation / strength checks
  - independent review
      |
      v
approved / frozen specification
      |
      +------------------+
      |                  |
      v                  v
implementation agent   proof agent
      |                  |
      +---------+--------+
                |
                v
          deterministic checkers
~~~

Changing an approved specification should be an explicit state transition, not a hidden repair.

---

# 27. ProofScript Agent ABI

Generic coding agents should be replaceable.

ProofScript should not build its long-term architecture around one proprietary model, one agent framework, or one model-provider API.

Instead, expose a provider-neutral deterministic surface.

Possible capability groups:

### Semantic inspection
- symbol lookup;
- exact type;
- normalized type;
- source-to-core mapping;
- effect summary;
- dependency closure.

### Proof inspection
- current goal;
- local context;
- relevant lemmas;
- failed obligations;
- theorem provenance;
- proof dependency graph.

### Change analysis
- semantic diff;
- affected theorem set;
- affected public contracts;
- affected assumptions;
- backend-preservation impact.

### Capability discovery
- query by provided capability;
- query by guarantee;
- query by target;
- query by assumptions;
- query by evidence level.

### Verification
- compile candidate;
- generate obligations;
- check proof;
- validate transformation;
- return structured failures.

This allows local/open models, frontier cloud models, specialized provers, and future systems to use the same semantic substrate.

---

# 28. Successful work must produce more than code

A factory run should ideally produce:

~~~text
requested artifact
+
reusable definitions
+
reusable theorems
+
proof patterns
+
implementation patterns
+
semantic metadata
+
counterexamples
+
failure knowledge
+
benchmark evidence
+
agent/tooling improvements when justified
~~~

This is the central mechanism for compounding ecosystem value.

---

# 29. Failures are reusable assets

Current AI coding often discards failed attempts after a successful patch.

ProofScript can retain structured failures.

Conceptual record:

~~~text
FailurePattern {
    obligationShape
    attemptedStrategy
    compilerResult
    reason
    counterexample
    dependencyState
    successfulReplacementStrategy
}
~~~

Then future agents can ask:

- Has this obligation shape appeared before?
- Which strategies failed?
- Why did they fail?
- Which abstraction or precondition fixed the problem?
- Did the failure reveal a missing reusable theorem?

A failed proof can therefore improve:

- the implementation;
- the specification;
- the API;
- the theorem library;
- the tactic library;
- future agent retrieval.

---

# 30. Generalization is more valuable than one-off success

Suppose many tasks repeatedly require variants of:

~~~text
map preserves length
buffer slice remains in bounds
state transition preserves invariant
serialization round-trips
transaction preserves conservation law
~~~

The factory should attempt to extract:

~~~text
generic lemma
generic abstraction
generic tactic
generic verified library
~~~

A mature system should prefer:

> solve once and generalize

over:

> solve the same proof shape independently forever.

This is how software work begins to accumulate like mathematics.

---

# 31. Three compounding loops

A true Self-Amplifying Verified Ecosystem Factory needs at least three loops.

## 31.1 Production loop

~~~text
requirement
  -> specification
  -> implementation
  -> proof/evidence
  -> accepted artifact
~~~

Objective:

> make one task cheap and correct.

## 31.2 Ecosystem loop

~~~text
accepted artifact
  -> extract capability
  -> extract theorems
  -> extract assumptions
  -> extract patterns
  -> update Verified Theory Graph
  -> next task reuses them
~~~

Objective:

> make future tasks cheaper.

## 31.3 Factory-improvement loop

~~~text
execution traces
  -> identify bottlenecks
  -> improve tactics / retrieval / agents / tools
  -> evaluate on frozen holdouts
  -> accept only demonstrated improvements
~~~

Objective:

> improve the production mechanism itself.

The third loop must not allow the factory to freely redefine its own success criteria.

---

# 32. Open and local AI models are an economic lever, not a trust anchor

The AI layer should support routing tasks by difficulty.

Conceptually:

~~~text
task
  |
  v
difficulty / capability router
  |
  +--> deterministic tool
  |
  +--> small specialized local model
  |
  +--> larger open model
  |
  +--> frontier model for hard cases
~~~

This can reduce cost as the ecosystem matures.

Long-term specialized roles might include:

~~~text
ProofScript-Architect
ProofScript-Coder
ProofScript-Prover
ProofScript-SpecAuditor
ProofScript-Interop
ProofScript-Repair
ProofScript-Generalizer
~~~

But none of these models belongs in the Trusted Computing Base merely because it is specialized.

---

# 33. Verified corpora can become unusually valuable AI training data

A conventional code corpus contains unknown amounts of:

- incorrect code;
- stale code;
- insecure code;
- broken tests;
- contradictory documentation;
- abandoned experiments.

A mature ProofScript corpus can contain:

~~~text
program
formal specification
proof
compiler result
dependency graph
failure trajectories
counterexamples
repair sequence
performance evidence
final accepted artifact
~~~

This creates strong objective supervision for some tasks.

For example:

~~~text
candidate A
    -> PSKernel rejects

candidate B
    -> PSKernel accepts
~~~

The system can generate large amounts of high-quality training/evaluation data without trusting human or AI preference judgments for every local correctness decision.

This makes ProofScript potentially both:

1. a programming environment; and
2. a training/evaluation environment for software agents.

---

# 34. Existing ecosystems should be raw material, not enemies

ProofScript should not attempt to manually rebuild decades of npm, Rust, Python, C, or C++ ecosystem work from zero.

Instead use progressive assurance.

Example migration:

~~~text
foreign package
    |
    v
generated typed interface
    |
    v
conformance-tested adapter
    |
    v
explicit contract/specification
    |
    v
validated wrapper
    |
    v
native ProofScript replacement where valuable
    |
    v
verified replacement
~~~

This creates assurance levels rather than a false binary.

Possible labels:

| Level | Meaning |
| --- | --- |
| External | imported; no native semantic guarantee |
| Typed | interface/type checked |
| Contracted | explicit behavioral contracts available |
| Tested | conformance/property evidence available |
| Validated | independent validator/model evidence available |
| Verified | machine proof checked |
| Preserved | compilation path preserves the claimed property |

The ecosystem can grow quickly while remaining honest about what is and is not proved.

---

# 35. Why this can compete with mature ecosystems

ProofScript is unlikely to catch ecosystems with decades of accumulated packages by recreating them at ordinary human development speed.

The strategy should instead be to change the **rate of ecosystem production**.

Traditional ecosystem growth often creates both capability and complexity:

~~~text
more packages
  -> more dependency complexity
  -> more integration burden
  -> more maintenance
  -> more human review
~~~

The ProofScript target is:

~~~text
more accepted packages
  -> more reusable semantics
  -> more verified interfaces
  -> more theorem/proof knowledge
  -> better AI retrieval
  -> more existing capability to compose
  -> less new implementation required
  -> cheaper next capability
~~~

The key advantage is not simply more code.

It is more **machine-understandable software knowledge**.

---

# 36. Formalization capacity should become a language criterion

When evaluating PSCV, do not ask only:

- Is this syntax pleasant?
- Can it express ordinary programs?
- Can it compile to JS/WASM/native?

Also ask:

> **Can important software concepts become first-class mathematical objects whose relevant properties compose?**

Important concepts include:

- state;
- effects;
- resources;
- time;
- failure;
- concurrency;
- ownership;
- messages;
- protocols;
- permissions;
- transactions;
- randomness;
- cost;
- security;
- foreign calls.

If a critical software concept cannot be modeled economically, the factory falls back to empirical programming in that domain.

Therefore add a major language criterion:

> **Software-domain formalization coverage.**

---

# 37. PSCV should optimize for machine reasoning as well as human programming

Potentially valuable characteristics include:

| PSCV characteristic | Factory value |
| --- | --- |
| Small, regular core language | reduces synthesis/search entropy |
| Lean-faithful semantics | rigorous foundation |
| Few redundant syntactic forms | more predictable generated code |
| Explicit effects | easier composition and reasoning |
| Explicit partiality/failure | fewer hidden runtime assumptions |
| Contracts/invariants | machine-checkable intent |
| Dependent/refinement types where justified | requirements can enter types |
| State-machine specifications | strong fit for protocols/services |
| Ghost state | expressive proofs without runtime cost |
| Canonical semantic IR | stable target for AI and tooling |
| Structured diagnostics | cheap repair loops |
| Stable canonical formatting | reduces irrelevant representation variance |
| Safe metaprogramming | scalable extension without kernel growth |
| Strong deriving/generation | eliminates repetitive work |
| Explicit unsafe/FFI boundaries | prevents verification theater |

A Go-like preference for regularity and simplicity may be strategically useful not only for humans but for AI search efficiency.

---

# 38. Proof automation must be powerful but untrusted

The ProofScript factory should allow aggressive automation:

- simplifiers;
- tactics;
- SMT solvers;
- decision procedures;
- model checkers;
- AI proof search;
- external synthesis engines.

But whenever possible, automation should produce evidence checkable by a smaller authority.

Preferred pattern:

~~~text
high-level PSCV program + contracts
            |
            v
compiler generates obligations
            |
      +-----+-----+
      |     |     |
      v     v     v
   tactics SMT   AI
      |     |     |
      +-----+-----+
            |
            v
proof / certificate / validated result
            |
            v
PSKernel or independent checker
~~~

The automation may be wrong.

The acceptance authority must not silently inherit that wrongness.

---

# 39. Tests change roles in a verified ecosystem

Today, tests often function as the primary evidence that software works.

In a mature ProofScript ecosystem:

~~~text
proofs
    ->
primary evidence that formalized claims hold

tests / fuzzing / benchmarks / monitoring
    ->
evidence that models, assumptions, interoperability,
performance, and the external world match expectations
~~~

Examples:

| Claim | Preferred evidence |
| --- | --- |
| Sorting output is ordered | proof |
| Sorting output is a permutation | proof |
| No out-of-bounds access | proof/type system |
| Queue preserves FIFO | proof |
| Protocol state machine is valid | proof/model checking |
| Compiler preserves selected semantics | proof/translation validation |
| Browser accepts generated HTTP response | interoperability testing |
| CPU behaves like selected ISA model | hardware/model validation |
| Service handles 1M requests/s | benchmark |
| UI is pleasant | human evaluation |
| External API still matches contract | conformance tests/monitoring |

This is a better division than "proof versus tests."

---

# 40. Knowledge-type provenance should be first-class

Important claims should be able to expose how they are known.

Candidate classifications:

~~~text
Proven
Derived
Assumed
ExternallySpecified
EmpiricallyValidated
Benchmarked
Tested
Unverified
~~~

Example:

~~~text
Payment preserves total balance
    PROVEN
      |
      +-- Transaction theorem
      |      PROVEN
      |
      +-- Decimal arithmetic
      |      PROVEN
      |
      +-- database atomicity
             EXTERNALLY SPECIFIED
             +
             EMPIRICALLY VALIDATED
~~~

This could be valuable for:

- auditors;
- developers;
- downstream packages;
- AI planning;
- risk analysis;
- release policy.

---

# 41. AI should reason about missing formal edges, not just missing files

Suppose the factory is asked:

> Build a verified payment service.

Instead of immediately generating source files, it can derive a desired claim:

~~~text
PaymentService satisfies RequiredProperties
~~~

Then decompose the dependency problem:

~~~text
Already available:

HTTP server capability
JSON codec theorem
Decimal arithmetic theorem
Authentication specification
Database adapter contract

Missing:

Payment conservation invariant
Transaction refinement
External payment-provider model
~~~

The AI should work primarily on the **missing semantic edges**.

That is much closer to theorem construction than ordinary repository editing.

---

# 42. Architecture sketch

~~~text
+---------------------------------------------------+
| HUMAN / PRODUCT REQUIREMENTS                      |
+--------------------------+------------------------+
                           |
                           v
+---------------------------------------------------+
| SPECIFICATION / MODEL FACTORY                     |
| formalization + ambiguity analysis + spec audit   |
+--------------------------+------------------------+
                           |
                           v
                  APPROVED SPECIFICATION
                           |
                           v
+---------------------------------------------------+
| VERIFIED THEORY GRAPH / CAPABILITY PLANNER        |
| reuse existing theories before synthesis          |
+--------------------------+------------------------+
                           |
                           v
+---------------------------------------------------+
| UNTRUSTED AGENT WORKERS                           |
| implementation / proof / interop / tests / docs   |
+--------------------------+------------------------+
                           |
                           v
+---------------------------------------------------+
| PSCV COMPILER / SEMANTIC SERVICES                 |
| typed IR, obligations, dependency slices, diffs   |
+--------------------------+------------------------+
                           |
                           v
+---------------------------------------------------+
| AUTOMATION                                        |
| tactics / certified procedures / SMT / AI search  |
+--------------------------+------------------------+
                           |
                           v
+---------------------------------------------------+
| PSKERNEL + INDEPENDENT VALIDATORS                 |
| final authority for the claims they cover         |
+--------------------------+------------------------+
                           |
                           v
+---------------------------------------------------+
| VERIFIED / EVIDENCE-CARRYING ARTIFACT             |
+--------------------------+------------------------+
                           |
                           v
+---------------------------------------------------+
| KNOWLEDGE EXTRACTION                              |
| API + laws + proofs + assumptions + patterns      |
| counterexamples + benchmarks + failure knowledge  |
+--------------------------+------------------------+
                           |
                           v
                 VERIFIED THEORY GRAPH
                           |
                 +---------+---------+
                 |                   |
                 v                   v
              NEXT TASK        FACTORY LEARNING
                                     |
                                     v
                           tactics / tools / agents
                                     |
                                     v
                             frozen evaluation
                                     |
                                     +--------> accepted improvements
~~~

---

# 43. FactoryBench: measuring whether amplification is real

Normal compiler benchmarks are insufficient.

The project needs metrics that measure ecosystem production and compounding.

Candidate metrics:

| Metric | Meaning |
| --- | --- |
| Verified Capability Throughput | accepted reusable capabilities per human-hour |
| Verified Capability Cost | compute/currency cost per accepted capability |
| Human Verification Tax | human review time per accepted change |
| Auto-proof Rate | obligations solved without manual proof work |
| Repair Iterations | agent/compiler loops before acceptance |
| Capability Reuse Rate | fraction of new work satisfied from existing assets |
| Theorem Reuse Rate | fraction of proof work discharged via prior theorems |
| Context Efficiency | successful work per model token/context budget |
| Local-model Completion Share | work handled without frontier-model calls |
| Regression Escape Rate | accepted changes later found incorrect |
| Specification Defect Discovery | incorrect/weak specifications caught before release |
| Proof Maintenance Cost | cost of preserving proof after implementation change |
| Change Propagation Cost | downstream work caused by semantic changes |
| Interop Creation Cost | cost of safely incorporating foreign software |
| Transitive Axiom Footprint | unproved assumptions required by an artifact |
| Conservative-extension Ratio | ecosystem growth that adds no new trusted assumptions |
| Empirical-boundary Size | important claims still relying on external empirical trust |
| Formal Knowledge Growth | reusable specifications/theorems produced per task |
| Factory Improvement Rate | performance gain with model weights held fixed |

The strongest evidence for self-amplification would be:

~~~text
same or similar model
same benchmark distribution
more accepted ecosystem knowledge

=>

higher success
lower human time
lower compute cost
fewer repair loops
higher reuse
~~~

Without this experiment, self-amplification remains a plausible mechanism rather than a demonstrated property.

---

# 44. Hard design laws

The following should be treated as strong candidate design laws for SAVEF research.

## Law 1 — AI is never final proof authority

A model can propose any artifact.

Acceptance comes from deterministic or independently controlled evidence mechanisms.

## Law 2 — Specifications and solutions are separate authorities

A candidate implementation must not silently weaken the claim used to evaluate it.

## Law 3 — Assumptions are explicit and transitive

Every strong claim must expose the assumptions underneath it.

## Law 4 — Verification should compose through abstractions

Downstream clients should normally depend on specifications and exported theorems, not implementation internals.

## Law 5 — Proof maintenance cost is part of correctness economics

A theorem that is impossible to maintain is not an ecosystem advantage.

## Law 6 — Failed work should improve future work

Structured failures, counterexamples, and unsuccessful proof routes are factory knowledge.

## Law 7 — Generalization beats repeated synthesis

Repeated successful patterns should become libraries, lemmas, tactics, templates, or semantic abstractions.

## Law 8 — Foreign ecosystems are progressively assimilated

Do not require all-or-nothing formal verification before ecosystem interoperation is useful.

## Law 9 — The trusted semantic core remains small

Domain expressiveness should mainly grow through libraries and verified extension mechanisms rather than kernel growth.

## Law 10 — Self-improvement is evaluated externally

The factory may propose changes to itself, but it must not freely redefine the benchmark or authority that decides whether those changes are improvements.

---

# 45. Research roadmap

## SAVEF-0 — Definition and measurement

- freeze the working definition of SAVEF;
- define FactoryBench;
- define human-effort, compute-cost, reuse, and proof-maintenance measurements;
- distinguish demonstrated capability from architectural aspiration.

## SAVEF-1 — Software Mathematics Coverage Map

For every major software domain:

- identify the semantic concepts that must be represented;
- identify candidate formal methods;
- classify language-core vs library vs tooling responsibilities;
- identify empirical boundaries.

## SAVEF-2 — ProofScript Agent ABI

Expose deterministic semantic/proof services:

- goals;
- dependency slices;
- theorem search;
- semantic diffs;
- assumption graphs;
- counterexamples;
- capability search.

## SAVEF-3 — Deep Specification / Theory Capsule model

Define the package-level representation of:

- definitions;
- specifications;
- proofs;
- effects;
- assumptions;
- refinement relationships;
- target/evidence metadata.

## SAVEF-4 — Verified Theory Graph

Build graph extraction and query mechanisms.

Initial goal:

> agents can discover reusable capabilities and theorem dependencies without reading an entire repository.

## SAVEF-5 — Specification integrity

Implement:

- locked specification identities;
- change/version semantics;
- weakening detection where possible;
- role separation;
- adversarial specification tests.

## SAVEF-6 — High-automation verification

Increase the fraction of routine obligations solved by:

- deterministic simplification;
- decision procedures;
- tactics;
- certificate-producing external automation;
- AI search under kernel checking.

## SAVEF-7 — Incremental proof infrastructure

Track:

- theorem dependency closure;
- invalidation caused by semantic changes;
- stable public proof interfaces;
- proof repair candidates.

## SAVEF-8 — Progressive foreign-ecosystem ingestion

Start with high-value JS/TS/npm interop:

~~~text
foreign package
 -> typed adapter
 -> conformance characterization
 -> explicit contract
 -> validated wrapper
 -> native verified replacement where justified
~~~

## SAVEF-9 — Proof/failure memory

Persist:

- successful proof strategies;
- failed strategies;
- counterexamples;
- modeling decisions;
- reusable repair patterns.

## SAVEF-10 — Generalization engine

Detect recurring patterns and propose:

- generic theorems;
- generalized APIs;
- tactics;
- abstractions;
- libraries.

All generalized outputs remain subject to ordinary verification.

## SAVEF-11 — Model routing and specialization

Use cheaper/local models for routine work and stronger models only when required.

Evaluate cost independently from correctness.

## SAVEF-12 — Controlled factory self-improvement

Allow agents to propose improvements to:

- prompts;
- retrieval;
- tactics;
- orchestration;
- heuristics;
- tool interfaces.

Accept them only when frozen holdout evaluation demonstrates improvement without unacceptable regressions.

---

# 46. Proposed evaluation criteria

The eventual SAVEF reference architecture should be evaluated against at least:

| Criterion |
| --- |
| Semantic fidelity |
| Kernel soundness |
| TCB minimization |
| TCB transparency |
| Formalization coverage |
| Specification strength/integrity |
| Compositional verification |
| Deep-interface quality |
| Assumption transparency |
| Conservative-extension behavior |
| Proof reuse |
| Proof maintenance cost |
| Incremental verification |
| AI semantic accessibility |
| Context efficiency |
| Agent replaceability |
| Automation power |
| Independent verification |
| Reward-hacking resistance |
| Security assurance |
| Backend semantic preservation |
| Runtime-boundary clarity |
| Foreign-ecosystem interoperability |
| Progressive assurance |
| Capability discoverability |
| Theory-graph quality |
| Failure-knowledge reuse |
| Generalization effectiveness |
| Human supervision cost |
| Compute efficiency |
| Ecosystem marginal cost |
| Self-amplification evidence |
| Performance |
| Resource behavior |
| Portability |
| Maintainability |
| Auditability |
| Longevity |
| Future relevance |

Some must be **hard gates**.

For example, a system should not receive an excellent SAVEF score by averaging high usability against weak specification integrity or a compromised proof authority.

---

# 47. Hypothesis evaluation

Current research assessment:

| Hypothesis | Assessment |
| --- | --- |
| Conventional development resembles empirical knowledge accumulation | useful analogy, but not literal science |
| Verified software construction can resemble mathematical theory building | strong inside formal models |
| Proof should completely replace tests | rejected |
| Much software semantics can be formalized | strongly supported in many domains |
| All relevant reality can economically be formalized | implausible |
| Packages can accumulate reusable behavioral theorems | strongly supported in principle |
| This can materially improve AI software generation | supported by current verified-code-generation research |
| Repository-scale proof automation is already solved | false |
| Language/verification design materially affects AI success | supported |
| Semantic dependency slicing can outperform raw context dumping | supported |
| Joint program/proof planning can reduce repair loops | supported |
| AI-generated passing code is automatically secure | false |
| Agents can game evaluation surfaces | demonstrated risk |
| Formal knowledge accumulation can create compounding ecosystem productivity | plausible, not yet demonstrated for ProofScript |
| PSCV can be the substrate | promising; requires deliberate architecture and measurement |

---

# 48. Central objective

Do **not** optimize for:

> maximum percentage of source lines carrying proofs.

Optimize for:

> **maximum reusable software knowledge represented deductively, with minimum human, compute, maintenance, and integration cost.**

Ten thousand isolated verified functions may be less useful than:

~~~text
100 deep specifications
+ 500 reusable theorems
+ 20 strong domain abstractions
+ excellent automation
+ stable proof boundaries
~~~

The unit of ecosystem value should increasingly be **reusable verified knowledge**, not source-line count.

---

# 49. Long-term picture

A successful trajectory might look like:

~~~text
Early stage

AI builds packages using
human-created foundations.


Next stage

AI builds packages using
an expanding verified library.


Later stage

AI builds frameworks using
verified package theories.


More mature stage

AI detects recurring structures
and creates general abstractions.


Mature factory

AI primarily assembles, specializes,
and proves systems from existing theories,
writing new low-level code mainly where
the capability graph has genuine gaps.
~~~

This resembles the way mature mathematics operates.

Modern mathematicians do not normally reason from foundational axioms for every problem. They work with accumulated definitions, theories, lemmas, abstractions, and established results.

A mature ProofScript ecosystem should aspire to the same leverage.

---

# 50. Canonical working definition

> **ProofScript's Self-Amplifying Verified Ecosystem Factory is an AI-native, verification-grounded system for accumulating executable software knowledge as a growing formal theory.**
>
> **Each accepted ecosystem asset may contribute definitions, implementations, specifications, proofs, refinement relationships, reusable lemmas, formal models, explicit assumptions, empirical evidence, counterexamples, and production knowledge.**
>
> **Later software should be constructed by composing and extending these accepted results rather than re-establishing correctness primarily through repeated empirical testing.**
>
> **AI searches, constructs, integrates, repairs, and generalizes this body of knowledge; deterministic proof checking and independent validators remain the authority for deductive claims; empirical methods validate the boundary between formal models and the external world.**
>
> **The defining success condition is economic as well as logical: as the accepted ecosystem grows, the marginal human and compute cost of producing the next correct reusable capability should decrease for comparable tasks.**

Short form:

> **Build software the way mathematics builds knowledge: prove and reuse what can be formalized, measure what touches reality, and make every accepted result help construct the next one.**

---

# 51. Immediate next research program

The most useful next document is a **Software Mathematics Coverage Map** for PSCV.

For each major real-software domain—state, memory, effects, async, concurrency, networking, filesystems, databases, security, distributed systems, FFI, randomness, resources, performance, and deployment—it should answer:

1. What must be formalized?
2. What existing mathematical/program-logic machinery is suitable?
3. What does Lean already provide?
4. What does PSCV already expose?
5. What belongs in PSCV core?
6. What belongs in libraries?
7. What belongs in tactics/automation?
8. What belongs in compiler semantic metadata?
9. What must remain an explicit external assumption?
10. What should be tested or measured empirically?
11. How should AI consume the resulting formal structure?
12. How well will proofs survive refactoring and ecosystem composition?

That map should precede large new language-feature work.

The objective is not to add features because other languages have them.

The objective is to ensure ProofScript has the **formalization capacity and automation architecture required to build real software as composable formal knowledge**.

---

# References and research anchors

The links below are research anchors, not claims that ProofScript already implements the corresponding techniques.

1. C. A. R. Hoare, *An Axiomatic Basis for Computer Programming*, Communications of the ACM, 1969.  
   https://doi.org/10.1145/363235.363259

2. Lean 4, *Propositions and Proofs*.  
   https://lean-lang.org/theorem_proving_in_lean4/Propositions-and-Proofs/

3. The Science of Deep Specification, DeepSpec.  
   https://deepspec.org/page/About/

4. DeepSpec, *A Network of Specifications*.  
   https://deepspec.org/page/Research/_

5. CompCert verified compiler documentation and semantic-preservation theorem.  
   https://compcert.org/doc/  
   https://compcert.org/man/manual001.html

6. CertiKOS certified abstraction-layer framework.  
   https://flint.cs.yale.edu/certikos/framework.html

7. RustBelt: R. Jung et al., *Securing the Foundations of the Rust Programming Language*, POPL 2018.  
   https://plv.mpi-sws.org/rustbelt/popl18/

8. Iris — higher-order concurrent separation logic and related verification research.  
   https://iris-project.org/

9. Aneris — distributed separation logic for distributed programs.  
   https://iris-project.org/aneris/

10. Haoyu Zhao et al., *AlgoVeri: An Aligned Benchmark for Verified Code Generation on Classical Algorithms*, ICML 2026.  
    https://proceedings.mlr.press/v306/zhao26bm.html

11. Yutong Xin et al., *VeriSoftBench: Repository-Scale Formal Verification Benchmarks for Lean*, 2026.  
    https://arxiv.org/abs/2602.18307

12. Zhe Ye et al., *Vero: Can AI Agents Build Formally Verified Software Repositories?*, 2026.  
    https://arxiv.org/abs/2608.13522

13. Zenan Li et al., *P³: Joint Program-and-Proof Planning for Verified Code Generation*, 2026.  
    https://arxiv.org/abs/2608.09277

14. Songwen Zhao et al., *Is Vibe Coding Safe? Benchmarking Vulnerability of Agent-Generated Code in Real-World Tasks*, ICML 2026.  
    https://proceedings.mlr.press/v306/zhao26ax.html

15. Kunvar Thaman, *Reward Hacking Benchmark: Measuring Exploits in LLM Agents with Tool Use*, ICML 2026.  
    https://proceedings.mlr.press/v306/thaman26a.html

16. Feiming Wang et al., *ProofLoom: Proof-Obligation-Driven Theory Construction for Autoformalizing Research-Level Stochastic Optimization*, 2026.  
    https://arxiv.org/abs/2609.34960

17. SpecBench, *Measuring Reward Hacking in Long-Horizon Coding Agents*, 2026.  
    https://arxiv.org/abs/2605.21384

---

# Final research position

The mathematics analogy is not merely rhetoric.

It suggests a concrete engineering strategy:

~~~text
ordinary ecosystem:
    reuse executable artifacts

ProofScript ecosystem:
    reuse executable artifacts
    + formal abstractions
    + specifications
    + proofs
    + refinement relations
    + explicit assumptions
    + semantic dependency knowledge
    + verified construction experience
~~~

That richer form of reuse is the plausible mechanism by which an AI-assisted ProofScript ecosystem could eventually grow **faster, cheaper, and with stronger correctness guarantees** than ecosystems whose primary correctness loop remains generate -> test -> debug -> review.

The central uncertainty is economic rather than theoretical:

> **Can ProofScript make this richer deductive knowledge cheap enough to produce, maintain, and reuse that its cumulative advantage exceeds the overhead of formal verification?**

SAVEF should be designed and benchmarked to answer that question directly.
