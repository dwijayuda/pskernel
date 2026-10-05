# ProofScript Verified Spec-Driven Development

**Status:** strategic architecture and research plan; non-normative.

**Working identity:** VSDD-v1 — Verified Spec-Driven Development for ProofScript.

**Language context:** ProofScript ps-0.9-r3; PSC2 / psc2-compiler-v1; Lean-compatible checked semantics.

**Relationship to the language reference:** this document does not add syntax, kernel rules, or language semantics. The sole normative source-language authority for r3 remains [ProofScript_Language_Reference_v0.9.0_r3.md](./ProofScript_Language_Reference_v0.9.0_r3.md). Where this document proposes future verification syntax or tooling, it is explicitly marked as proposed.

**Strategic relationship:** this document specializes the Verified Software Factory / VEF-Core direction described in [ProofScript_Programming_Language_IDENTITY_AND_PLANS.md](./ProofScript_Programming_Language_IDENTITY_AND_PLANS.md) into an end-to-end development workflow.

---

## Executive decision

ProofScript should not compete primarily by making AI generate more code.

The stronger opportunity is:

> **ProofScript should make AI-generated software cheaper to specify, cheaper to challenge, cheaper to reject when unsupported, and independently checkable when accepted.**

The target workflow is not:

~~~text
prompt
-> AI
-> code
-> AI says done
~~~

and not merely:

~~~text
requirements.md
-> design.md
-> tasks.md
-> AI implementation
-> tests
~~~

The target is:

~~~text
human intent / documents / models
        |
        v
structured requirements
        |
        v
formalization + ambiguity analysis
        |
        v
locked SpecCapsule
        |
        v
joint program + proof plan
        |
        v
AI-generated implementation + proofs
        |
        v
verification conditions
        |
        v
PSC / proof services
        |
        v
PSKernel admission and independent replay
        |
        v
CheckedCore
        |
        v
proof/spec erasure
        |
        v
VerifiedIR
        |
        v
translation validation / backend evidence
        |
        v
deployable artifact
        |
        v
runtime / foreign-boundary evidence
~~~

The strongest justified claim is therefore:

> **The implementation satisfies the approved formalized specification under the explicitly recorded assumptions and assurance boundaries.**

ProofScript must not turn this into the stronger and generally unjustified claim:

> “The original prompt, prose document, UML diagram, or human intention was complete and perfectly formalized.”

Specification fidelity remains a first-class engineering problem.

---

# 1. Why this matters now

## 1.1 AI code generation has created a verification bottleneck

Modern AI coding systems have made generation cheap. The bottleneck is increasingly trust.

DORA's 2026 analysis describes a “verification tax”: time saved generating code is frequently re-spent auditing, reviewing, testing, and correcting AI output. It also reports that increased AI adoption can raise both throughput and instability.

The strategic implication for ProofScript is:

> **Do not optimize mainly for tokens generated per hour. Optimize for human minutes required per trusted capability.**

That metric better matches a world where source code is cheap but verification capacity remains scarce.

## 1.2 Mainstream agentic development is becoming specification-driven

GitHub Spec Kit currently structures agentic software development around persistent artifacts and phases such as:

~~~text
constitution
-> specify
-> clarify
-> plan
-> checklist
-> tasks
-> analyze
-> implement
-> converge
~~~

Kiro similarly uses requirements, design, and tasks; its requirements-first workflow structures natural-language requirements using EARS-style statements before generating architecture and implementation tasks.

These workflows are substantially better than one-shot prompting because intent persists outside the chat transcript.

However, their main artifacts remain human-readable documents and agent-managed consistency checks. They improve context and process discipline, but they do not by themselves produce mathematical evidence that an implementation satisfies the intended behavior.

ProofScript should preserve the good parts of current Spec-Driven Development while adding a stronger layer:

~~~text
Spec-Driven Development
        +
formalization
        +
machine-checkable obligations
        +
small independent proof authority
        =
Verified Spec-Driven Development
~~~

## 1.3 Formal AI software development is becoming practical, but not autonomous

Recent evidence supports a bounded version of this direction.

Vero evaluates AI agents on multi-module Lean repositories requiring both implementations and proofs. Its 2026 benchmark contains 43 repositories, 743 APIs, and 2,705 formal specifications. The strongest reported configuration fully solves 27 of 43 code-and-proof repositories, but ten instances remain unsolved by every tested configuration.

P³ reports that jointly planning a program and its proof is more effective than generating the implementation first and proving it afterward.

SpecSyn shows that generated specifications must be challenged for semantic strength; provability alone is not enough.

The P language's PeasyAI already demonstrates a related design-document-to-formal-model workflow for distributed state machines, generating state machines, specifications, and test drivers and repairing them against P's checker.

The conclusion is not that autonomous verified software generation is solved.

The conclusion is:

> **Generation, formalization, proof search, and repair are now capable enough that a deterministic checking and evidence architecture is strategically valuable.**

---

# 2. Definitions

## 2.1 Prompt-driven development

The primary artifact is a conversational instruction.

Example:

~~~text
Build an order service with payment and cancellation.
~~~

The AI fills in unspecified architecture, semantics, error handling, and invariants.

Strength:
- very low friction.

Weakness:
- hidden assumptions;
- intent is ephemeral;
- regeneration may reinterpret requirements;
- correctness is mostly judged by behavior observed in examples/tests.

## 2.2 AI-assisted development

Humans retain primary ownership of source and architecture while AI assists with:

- completion;
- refactoring;
- code review;
- tests;
- debugging;
- documentation;
- research.

This is the lowest-risk adoption mode, but correctness still depends on ordinary engineering controls.

## 2.3 Agentic / AI-driven development

An agent receives a goal and can:

- inspect the repository;
- plan;
- edit multiple files;
- run tools;
- test;
- iterate;
- open or update pull requests.

The agent operates over a longer horizon and owns more implementation choices.

The main new risk is that the same system can become both generator and evaluator.

## 2.4 Spec-driven development

A persistent specification is created before implementation and feeds later planning and implementation phases.

Typical artifacts:

- requirements.md;
- design.md;
- tasks.md;
- user stories;
- acceptance criteria;
- diagrams;
- architecture decisions.

This reduces ambiguity but does not automatically make those artifacts formal or complete.

## 2.5 Verified Spec-Driven Development

VSDD adds machine-checkable semantic obligations to SDD.

A requirement may be classified as:

~~~text
informal-only
formalized
proved
tested
runtime-monitored
assumed
unsupported
unknown
~~~

A project therefore carries evidence about what is known rather than a single “verified” Boolean.

---

# 3. Central design law: specification and solution are separate authorities

A high-assurance AI workflow must separate:

~~~text
trusted challenge / specification
~~~

from:

~~~text
untrusted candidate solution
~~~

This follows the same basic principle used by strong proof-validation workflows: the candidate should not be able to silently alter what it is being judged against.

## 3.1 SpecCapsule-v1

Proposed identity:

~~~text
SpecCapsule-v1
~~~

A SpecCapsule is an immutable or explicitly versioned description of the claims the generated solution is expected to satisfy.

Candidate fields:

~~~text
specCapsuleVersion
projectIdentity
sourceProfiles
requirements
formalClaims
publicAPI
stateModels
allowedAssumptions
foreignModels
environmentIdentity
standardRegistryIdentity
requirementLinks
reviewStatus
approvalMetadata
contentDigest
~~~

The exact serialized format remains implementation work.

Core rules:

1. The implementation/proof agent MUST NOT silently modify a locked SpecCapsule.
2. Any weakening, deletion, or reinterpretation of a formal claim creates a new SpecCapsule revision.
3. Verification results MUST name the exact SpecCapsule digest they satisfy.
4. AI-generated specifications MUST be distinguishable from human-approved specifications.
5. A valid proof of a weak specification MUST NOT be presented as evidence that the original human intent was fully captured.

## 3.2 Solution-v1

A candidate solution may contain:

~~~text
ProofScript source
helper lemmas
proof scripts
generated tests
generated models
runtime adapters
backend artifacts
~~~

Everything in the solution is untrusted until checked by the appropriate layer.

---

# 4. RequirementIR-v1

Natural-language documents are too unconstrained to be the only durable semantic interface.

ProofScript should introduce a tool-level intermediate representation:

~~~text
RequirementIR-v1
~~~

This is not a new language type theory. It is a structured requirements and traceability format.

## 4.1 Candidate requirement fields

~~~text
requirement_id
title
source_locator
original_text
normalized_statement
kind
criticality
scope
actors
inputs
outputs
preconditions
postconditions
invariants
error_cases
examples
counterexamples
assumptions
formalization_status
formal_claim_ids
test_ids
runtime_monitor_ids
dependency_requirements
review_status
provenance
~~~

## 4.2 Requirement kinds

At minimum:

~~~text
functional
safety
security
data-invariant
state-transition
liveness
authorization
resource
error-handling
compatibility
performance
availability
privacy
usability
operational
build/provenance
~~~

Not every kind should become a theorem.

For example:

- a pure functional property may become a Prop;
- latency may require benchmark/SLO evidence;
- external SaaS behavior may remain an assumption plus conformance tests;
- UI preference may remain human-reviewed acceptance criteria.

This prevents “formal verification” from pretending to cover properties it does not model.

---

# 5. Input adapters

VSDD should accept multiple specification sources while preserving the difference between syntax import and semantic trust.

## 5.1 Natural language and Markdown

Examples:

- product requirements;
- ADRs;
- design documents;
- README contracts;
- user stories;
- EARS requirements;
- acceptance criteria;
- issue descriptions.

Pipeline:

~~~text
prose
-> extraction
-> RequirementIR
-> ambiguity / contradiction analysis
-> candidate formalization
-> review
-> SpecCapsule
~~~

The AI extractor is untrusted.

The original text must remain linked to every normalized requirement.

## 5.2 EARS-style requirements

EARS-style requirements are useful because they constrain prose into predictable forms.

Example:

~~~text
WHEN a paid order is cancelled
THE SYSTEM SHALL prevent subsequent shipment.
~~~

This can become a candidate transition invariant.

EARS is not itself a proof language. It is a better bridge from prose to formalization.

## 5.3 OpenAPI

OpenAPI is a strong VSDD input because it already contains machine-readable:

- endpoints;
- schemas;
- parameters;
- result classes;
- some constraints.

Candidate mapping:

~~~text
OpenAPI
-> InterfaceIR
-> ProofScript types
-> codec obligations
-> handler contracts
-> client/server binding obligations
~~~

What it does not prove:

- remote service behavior;
- authorization semantics not specified in the document;
- database correctness;
- business invariants absent from the schema.

## 5.4 JSON Schema and schema languages

Useful for:

- data validity;
- codecs;
- parser safety;
- canonicalization;
- round-trip properties.

Strong first target:

~~~text
decode(encode(x)) = x
successful decode -> schema-valid value
invalid bytes cannot construct admitted value
~~~

## 5.5 UML

Traditional UML should be treated as a modeling input, not as a complete executable specification.

Candidate mapping:

| UML artifact | ProofScript interpretation | Typical assurance |
| --- | --- | --- |
| Class diagram | structures, ADTs, relations, multiplicities | structural |
| State machine | transition relation, legal states, invariants | high |
| Sequence diagram | required/example traces | partial behavioral |
| Activity diagram | workflow/state model | medium |
| Use cases | RequirementIR entries | informal |
| Deployment diagram | environment/assumption model | boundary evidence |

UML includes semantic variation points and often omits executable detail. Therefore “generated from UML” MUST NOT imply “proved to match every stakeholder intention.”

## 5.6 OCL

OCL is much more directly useful for VSDD because it expresses constraints over models.

Candidate mapping:

~~~text
UML structure
+
OCL invariants/pre/postconditions
        |
        v
ProofScript structures
+
Prop-valued predicates/contracts
~~~

An OCL importer must define a precise supported subset and reject unsupported constructs rather than approximate them.

## 5.7 SysML v2

SysML v2 is a particularly promising future input because the OMG standard includes machine-readable abstract syntax artifacts, JSON schema material, textual notation, and requirement-oriented modeling.

Candidate architecture:

~~~text
SysML v2
-> SysML Adapter
-> RequirementIR + ModelIR
-> formalization
-> SpecCapsule
~~~

This should be preferred over “AI reads a screenshot of a system diagram” when machine-readable SysML is available.

## 5.8 Existing code and foreign interfaces

Foreign code may be characterized rather than immediately rewritten.

Assurance lanes:

~~~text
bind
characterize
port
verified replacement
verified-by-construction generation
~~~

A foreign interface must preserve uncertainty:

~~~text
native-representable
adapter-required
runtime-validated
assumed
opaque
unsupported
~~~

No silent any-like fallback.

---

# 6. Formalization pipeline

## 6.1 Formalization is a separate phase

Do not go directly from:

~~~text
“Build a secure order service”
~~~

to implementation.

The first output should be candidate meaning.

Example:

~~~text
REQ-ORDER-001
A cancelled order must never reach Shipped.

REQ-ORDER-002
A payment callback with the same provider transaction ID is idempotent.

REQ-ORDER-003
An order may reach Shipped only after a successful payment.

REQ-ORDER-004
Order total equals the sum of accepted line totals.

REQ-ORDER-005
No transition may reduce the recorded audit sequence.
~~~

The human can review five semantic statements much more effectively than thousands of generated implementation lines.

## 6.2 Formalization classes

A requirement may lower to one or more of:

~~~text
type constraint
pure function contract
data invariant
state invariant
transition relation
refinement relation
temporal / trace property
resource invariant
runtime validator
test oracle
benchmark/SLO
foreign assumption
~~~

## 6.3 Current r3 contract anchor

ps-0.9-r3 already has a stable pure-contract surface:

~~~proofscript
function debit(balance: Nat, amount: Nat): Nat
  requires amount <= balance
  ensures result => result + amount = balance
:=
  balance - amount
~~~

Its conceptual obligation is:

~~~text
forall inputs,
  Pre(inputs) ->
  Post(inputs, implementation(inputs))
~~~

This is the correct semantic anchor for VSDD.

Current r3 does not yet standardize dedicated syntax for:

- verified assert;
- loop invariant;
- old/pre-state;
- ghost state;
- stateful/effectful postconditions;
- async/trace contracts.

VSDD MUST therefore treat those as proposed future verification surfaces or library/program-logic facilities, not current language syntax.

---

# 7. Specification quality is a first-class verification problem

A proof only establishes the theorem that was actually stated.

Bad specifications may be:

- vacuous;
- inconsistent;
- incomplete;
- too weak;
- over-constrained;
- disconnected from the original requirement;
- dependent on hidden assumptions.

## 7.1 SpecAudit-v1

Proposed service:

~~~text
SpecAudit-v1
~~~

Checks should include:

### Satisfiability
Can the preconditions hold?

### Non-vacuity
Is the postcondition meaningful?

### Reachability
Can specified states/transitions actually occur?

### Mutation strength
Do clearly incorrect program mutations still satisfy the spec?

### Input relevance
Can required inputs be ignored without violating the contract?

### Failure coverage
Are important error cases unconstrained?

### Cross-requirement consistency
Can all required properties hold simultaneously?

### Refinement consistency
Does the formalization actually strengthen or faithfully capture its parent requirement?

## 7.2 Semantic mutation

Following the motivation demonstrated by SpecSyn, ProofScript should deliberately challenge specification strength.

Examples:

~~~text
replace implementation with constant
ignore authorization token
drop state update
swap success/error branch
remove conservation update
accept malformed input
replay duplicate event twice
~~~

If these mutants still satisfy the formalized requirement, the specification may be too weak.

Mutation testing does not prove that a specification is complete, but it provides useful negative evidence.

## 7.3 Formal challenges

For high-value specs, support challenge obligations such as:

~~~text
prove precondition is satisfiable
prove two requirements are jointly consistent
find a counterexample to candidate formalization
prove reference behavior violates the current contract
prove a stronger expected property is not implied
~~~

A failed proof may expose a broken specification rather than a broken implementation.

Vero's benchmark audit mechanism is strong precedent for accepting machine-checked negative evidence against the benchmark/spec itself.

---

# 8. Program-and-proof planning

The implementation agent should plan for provability before choosing algorithms.

Bad workflow:

~~~text
generate implementation
-> attempt proof
-> patch code
-> patch proof
-> repeat
~~~

Preferred workflow:

~~~text
SpecCapsule
-> decompose claims
-> select representations
-> identify invariants
-> identify reusable lemmas
-> choose proof-friendly algorithms
-> create implementation scaffold
-> create proof scaffold
-> elaborate both together
~~~

This follows the evidence from P³: joint program-and-proof planning can outperform implementation-first workflows.

## 8.1 Plan artifact

Proposed fields:

~~~text
plan_id
spec_capsule_digest
modules
data_representation
public_api_mapping
obligation_groups
invariants
helper_lemmas
algorithm_choices
effect_models
foreign_boundaries
verification_strategy
expected_automation
manual/high-risk goals
backend_requirements
~~~

The plan is untrusted guidance.

The SpecCapsule remains the authority.

---

# 9. AI roles and separation of duties

A single model may implement multiple roles in low-assurance workflows, but the architecture should define roles separately.

## 9.1 Requirement Agent

Responsibilities:

- extract requirements;
- preserve source links;
- detect ambiguity;
- propose missing cases.

Authority:
- none.

## 9.2 Formalization Agent

Responsibilities:

- propose predicates/contracts/models;
- connect requirements to formal claims.

Authority:
- none.

## 9.3 Spec Auditor

Responsibilities:

- find vacuity;
- find contradictions;
- generate mutants/challenges;
- compare prose with formalization.

Prefer role/model separation from the formalization agent when practical.

## 9.4 Program-Proof Planner

Responsibilities:

- choose proof-friendly representation and decomposition;
- identify reusable lemmas/invariants.

## 9.5 Implementation Agent

Responsibilities:

- write executable ProofScript.

## 9.6 Proof Agent

Responsibilities:

- construct terms/tactics;
- invoke deterministic automation;
- create helper lemmas.

## 9.7 Build/Integration Agent

Responsibilities:

- wiring;
- backend integration;
- tests;
- package artifacts.

## 9.8 Audit Agent

Responsibilities:

- summarize checker outputs;
- inspect assumption/evidence graph;
- report gaps.

The Audit Agent MUST NOT create proof authority by declaration.

---

# 10. AgentProtocol-v1

Text files and terminal logs are a poor primary API for proof agents.

ProofScript should expose a structured, model-agnostic protocol.

Proposed operations:

~~~text
openProject
getProjectIdentity

listRequirements
getRequirement
listFormalClaims
getFormalClaim
getSpecCapsule

listOpenObligations
getGoal
getContext
getExpectedType

searchDeclarations
searchSpecifications
searchLemmas
getDependencyGraph

tryTerm
tryTactic
tryRewrite
tryAutomation
checkCandidate

getCounterexample
getFailureExplanation
getAssumptions

replayAdmission
auditProject
getEvidenceGraph
~~~

## 10.1 Structured status

Every declaration/obligation should report a state such as:

~~~text
unparsed
parsed
elaborated
specified
obligation-open
candidate-proof
kernel-rejected
kernel-verified
unsupported
assumed
runtime-only
~~~

Do not use ambiguous “green” UI states that merge parsing, tests, and proof.

## 10.2 Current architecture fit

The existing ProofScript language service already separates parsing from kernel verification and labels only PSKernel-admitted declarations as verified.

Its theorem proof-state path is also designed not to fabricate tactic goals.

That is the correct foundation for AgentProtocol-v1.

---

# 11. Verification architecture

## 11.1 Proposed verify-core

Candidate package:

~~~text
@proofscript/verify-core
~~~

Responsibilities:

- contract representation;
- program-logic/WP interfaces;
- VC construction;
- obligation identity;
- dependency tracking;
- proof result attachment.

It remains outside the logical TCB.

## 11.2 Standard specification library

Candidate package:

~~~text
@proofscript/specs-std
~~~

The Standard ecosystem should ship not merely implementations, but reusable verified specifications for common operations.

Initial targets:

~~~text
Nat
Int
Bool
Option
Except
List
Array
Map
Set
String
ByteArray
Result-like combinators
parser/codec combinators
~~~

Verification should compose through specification lemmas instead of repeatedly unfolding implementation details.

## 11.3 Verification automation

Candidate package:

~~~text
@proofscript/verify-auto
~~~

Suggested staged pipeline:

~~~text
normalize
-> simplification
-> registered specification lemmas
-> deterministic arithmetic / decision procedures
-> structured case analysis
-> domain tactics
-> optional SMT/reconstruction
-> AI proof search
-> human-visible remaining goals
~~~

Every successful path must eventually produce ordinary proof evidence acceptable to the selected checking policy.

No AI/SMT “success” flag is itself proof authority.

---

# 12. Effects and state

Pure contracts are only the first layer.

Recommended progression:

~~~text
pure
-> State
-> Except/Result
-> Reader
-> resource ownership
-> Task/async
-> streams
-> state machines
-> distributed traces
~~~

## 12.1 State

Stateful specifications need explicit pre/post state.

Conceptual shape:

~~~text
Pre : S -> Prop
Post : Result -> S -> Prop
~~~

## 12.2 Errors

Error-capable operations should specify success and failure behavior rather than treating failures as invisible host exceptions.

## 12.3 Resources

Resource verification may include:

- acquisition/release;
- no-use-after-release;
- exactly-once cleanup;
- capability ownership.

## 12.4 Async

Async specifications require explicit semantics for:

- completion;
- failure;
- cancellation;
- ordering;
- resource cleanup.

Do not define proof semantics by JavaScript Promise implementation details.

## 12.5 Distributed/state-machine properties

For protocol-like systems:

~~~text
safety
+
liveness where required
+
trace conformance
~~~

A system that never progresses may satisfy many safety invariants, so liveness must be modeled separately when it matters.

P is strong prior art here.

---

# 13. Requirement-to-evidence traceability

Every high-value requirement should be traceable through the implementation and assurance stack.

Proposed graph:

~~~text
Requirement
   |
   v
FormalClaim
   |
   v
Implementation symbols
   |
   v
Proof obligations
   |
   v
Proof/admission identities
   |
   v
CheckedCore identities
   |
   v
VerifiedIR identities
   |
   v
backend evidence
   |
   v
runtime/foreign evidence
~~~

## 13.1 EvidenceGraph-v1

Candidate node kinds:

~~~text
requirement
formal-claim
type
contract
state-model
implementation
proof-obligation
kernel-proof
kernel-admission
assumption
foreign-model
test
property-test
fuzz-campaign
runtime-monitor
translation-validation
backend-artifact
build-provenance
dependency-integrity
human-approval
~~~

Candidate edge kinds:

~~~text
formalizes
refines
implements
depends-on
proves
checks
tests
assumes
validates
lowers-to
compiled-from
observes
approved-by
supersedes
~~~

## 13.2 Evidence status

Use explicit status:

~~~text
proved
independently-replayed
translation-validated
tested
monitored
assumed
unknown
unsupported
failed
~~~

Do not collapse the graph into one “verified” badge internally.

---

# 14. Assurance vector

A user-facing summary may look like:

~~~text
specification: human-approved
logic: proved
proof replay: independent
compilation: translation-validated
boundary: tested + 2 explicit assumptions
provenance: reproducible
runtime protocol: monitored
~~~

This makes the scope of the claim inspectable.

## 14.1 Source correctness is not compiler correctness

A source theorem can be valid while a buggy backend emits incorrect JavaScript.

Therefore:

~~~text
source proof
!=
backend semantic preservation
~~~

ProofScript should strengthen compiler assurance incrementally:

~~~text
C0 checked source
C1 cross-backend tests/conformance
C2 per-build translation validation
C3 proved selected passes
C4 end-to-end verified backend path
~~~

VSDD-v1 should not wait for C4.

## 14.2 Foreign boundaries

An FFI declaration, OpenAPI schema, .d.ts file, or database model is not proof that the external system behaves accordingly.

Foreign evidence should be classified as:

~~~text
verified adapter
runtime-validated
conformance-tested
assumed
unknown
unsupported
~~~

---

# 15. Independent checking for AI-generated work

AI-generated source/proofs should be treated as potentially hostile in high-assurance workflows.

Lean's current proof-validation guidance explicitly distinguishes ordinary honest proof attempts from malicious or unreviewed AI-generated submissions and recommends sandboxed challenge/solution comparison plus independent checking for high-risk settings.

ProofScript should adopt the same architecture.

## 15.1 Clean verification

High-assurance flow:

~~~text
agent workspace
-> extract allowed outputs
-> reconstruct clean project
-> load locked SpecCapsule
-> use pinned environment
-> rebuild/elaborate
-> PSKernel check
-> allowed-assumption check
-> optional secondary checker
-> evidence graph
~~~

## 15.2 Axiom/assumption allowlist

The checker must reject proof success that depends on undeclared assumptions.

A package may intentionally declare assumptions, but they must appear in the assurance result.

## 15.3 Dual checking

During PSKernel maturation:

~~~text
candidate checked terms
      |               |
      v               v
  PSKernel      Lean/reference lane
      |               |
      +-------+-------+
              |
              v
       agreement required
~~~

Longer term, independently implemented checkers may be added for selected assurance levels.

---

# 16. Runtime conformance

Not all requirements can be discharged statically.

Runtime evidence is useful for:

- external APIs;
- databases;
- distributed services;
- platform behavior;
- performance;
- production traces.

Proposed package:

~~~text
@proofscript/runtime-monitor
~~~

Capabilities:

- check event traces against state-machine monitors;
- check selected executable boundary predicates;
- attach monitor evidence to EvidenceGraph;
- distinguish observed conformance from universal proof.

PObserve is useful prior art for checking production logs against formal P monitors.

---

# 17. Proposed package architecture

These are proposals, not current package claims.

| Package | Responsibility | Trust class | Priority |
| --- | --- | --- | --- |
| @proofscript/requirements | RequirementIR and traceability | untrusted support | P0 |
| @proofscript/spec-capsule | locked/versioned formal requirement package | untrusted serialization + checked references | P0 |
| @proofscript/verify-core | contract/WP/VC machinery | untrusted proof producer | P0 |
| @proofscript/specs-std | verified Standard specifications | library evidence | P0 |
| @proofscript/spec-audit | vacuity/consistency/mutation analysis | untrusted analysis | P0 |
| @proofscript/audit | assumption/trust/evidence reporting | untrusted reporter over checked data | P0 |
| @proofscript/agent-protocol | machine-oriented project/proof API | untrusted tooling | P0 |
| @proofscript/evidence | EvidenceGraph-v1 | untrusted orchestration, checked refs | P0 |
| @proofscript/verify-effects | State/Except/effect verification | untrusted proof producer + verified lemmas | P1 |
| @proofscript/verify-behavior | state/trace properties | untrusted proof producer | P1 |
| @proofscript/spec-openapi | OpenAPI adapter | untrusted importer | P1 |
| @proofscript/spec-jsonschema | schema adapter | untrusted importer | P1 |
| @proofscript/spec-ocl | bounded OCL adapter | untrusted importer | P1 |
| @proofscript/spec-sysml | bounded SysML v2 adapter | untrusted importer | P1 |
| @proofscript/runtime-monitor | runtime trace/boundary evidence | runtime evidence only | P1 |
| @proofscript/translation-validate | per-build compiler validation | assurance subsystem | P1/P2 |
| @proofscript/forge | AI orchestration/workcells | untrusted | P1/P2 |

No package above gains logical authority merely because it is “official.”

---

# 18. CLI / user workflow

Provisional commands:

~~~text
psc spec import <source>
psc spec clarify
psc spec formalize
psc spec audit
psc spec lock

psc plan --proof-aware

psc verify
psc verify --requirement REQ-17
psc verify --json

psc audit
psc evidence
psc replay

psc build --assurance <profile>
~~~

A future Forge layer may provide conversational UX over these deterministic primitives.

## 18.1 Example verification output

~~~text
Project: order-service
SpecCapsule: sha256:...

Requirements:          31
Formalized:            24
Kernel-proved:         24 / 24
Test-only:              4
Runtime-monitored:      1
Foreign-assumed:        2
Unknown:                0

Proof replay:          PASS
Axiom policy:          PASS
CheckedCore:           PASS
Translation validation: PASS

Deployable artifact:   produced
Overall claim:         MIXED ASSURANCE -- inspect EvidenceGraph
~~~

---

# 19. Example end-to-end: order service

## 19.1 Prompt

~~~text
Build an order service.

Orders may ship only after payment.
Cancelled orders must never ship.
Duplicate payment callbacks must be idempotent.
Here is the OpenAPI file and SysML model.
~~~

## 19.2 Requirement extraction

Candidate RequirementIR:

~~~text
REQ-001 Payment is required before shipment.
REQ-002 Cancelled is terminal with respect to shipment.
REQ-003 Duplicate provider transaction IDs do not apply payment twice.
REQ-004 API request/response bodies satisfy OpenAPI schemas.
REQ-005 Every accepted transition appends an audit record.
~~~

## 19.3 Ambiguity gate

Questions:

~~~text
Can a shipped order later be cancelled?
Can partial payment permit shipment?
Does cancellation refund?
What identifies duplicate callbacks?
Are retries expected to return the first result?
~~~

Implementation should not begin until high-impact ambiguities are resolved or explicitly classified as assumptions.

## 19.4 Formal model

Candidate state:

~~~text
Created
PendingPayment
Paid
Cancelled
Shipped
~~~

Candidate invariants:

~~~text
state = Shipped -> paymentStatus = Paid
state = Cancelled -> nextState != Shipped
processed(txId) -> applying txId again preserves payment total
auditLength never decreases
~~~

## 19.5 Spec audit

Mutants:

~~~text
ship directly from Created
apply payment callback twice
delete audit append
allow Cancelled -> Shipped
ignore transaction ID
~~~

The formal spec should reject all of these if the corresponding requirement is meant to forbid them.

## 19.6 Joint plan

Choose data representation and helper lemmas so that:

- state transitions are explicit;
- duplicate transaction IDs are represented in checked state;
- shipment transition requires payment evidence;
- state-machine invariants compose.

## 19.7 Generation and checking

~~~text
AI implementation
+ helper lemmas
+ proof candidates
        |
        v
VCs
        |
        v
proof automation
        |
        v
AI proof repair
        |
        v
PSKernel
~~~

## 19.8 Deployment evidence

Possible final assurance:

~~~text
REQ-001 proved
REQ-002 proved
REQ-003 proved
REQ-004 codec/schema validation proved for native model
REQ-005 proved for source state machine

PostgreSQL transactional semantics: assumed + integration-tested
payment provider delivery semantics: assumed
HTTP server adapter: conformance-tested
backend: translation-validated
~~~

That is a meaningful and honest correctness report.

---

# 20. Development methodology

Recommended engineering rule:

> **Functional verified core, explicit effect shell.**

Architecture:

~~~text
application
    |
    +-- verified domain core
    |      pure logic
    |      ADTs
    |      parsers/codecs
    |      state machines
    |      business invariants
    |
    +-- explicit effect/adaptor shell
           filesystem
           network
           database
           clock
           randomness
           OS
           cloud services
~~~

This maximizes proof value without requiring a verified operating system before ordinary applications become useful.

Boundaries can move inward over time as verified adapters become available.

---

# 21. First verticals

Do not begin by promising arbitrary whole-application verification.

Recommended order:

## 21.1 Parser / codec / schema factory

Properties:

- round-trip;
- bounds safety;
- canonical encoding;
- valid-value construction;
- malformed-input rejection.

## 21.2 Deterministic business/state-machine logic

Properties:

- transition safety;
- conservation;
- authorization;
- idempotency;
- terminal states.

## 21.3 OpenAPI / SDK generation

Use schema-first InterfaceIR and explicit service assumptions.

## 21.4 Authorization / policy engines

Good fit for declarative policies and machine-checkable decisions.

## 21.5 Numeric / financial deterministic core

Useful if numeric representation, rounding, and overflow semantics are explicitly modeled.

Later:

- async/resources;
- distributed protocols;
- broader foreign libraries;
- UI frameworks.

---

# 22. Acceptance gates

VSDD should not be considered implemented because a demo prompt produces compiling code.

## V0 — requirement traceability

- stable RequirementIR identity;
- source locators preserved;
- ambiguity status explicit;
- no requirement silently dropped.

## V1 — SpecCapsule

- canonical serialization;
- digest identity;
- approval state;
- immutable locked mode;
- allowed assumptions explicit.

## V2 — pure contract verification

- r3 requires/ensures lower to durable obligations;
- false contract rejects;
- changed implementation invalidates stale proof identity;
- obligation-to-requirement links preserved.

## V3 — independent replay

- candidate artifacts can be rebuilt in a clean environment;
- proof admissions replay through PSKernel;
- disallowed assumptions reject.

## V4 — specification audit

- satisfiability checks;
- vacuity checks;
- semantic mutants;
- inconsistent requirement demonstration;
- formal challenge workflow.

## V5 — agent protocol

- structured goals/context;
- candidate proof trial;
- deterministic status;
- no fabricated “verified” result;
- model/provider independent.

## V6 — state/effect verification

- explicit State and error semantics;
- state invariants;
- state transition proofs;
- unsupported effects fail closed.

## V7 — imported model bridge

At least two of:

- OpenAPI;
- JSON Schema;
- OCL;
- SysML v2.

Each adapter must have a bounded support matrix and explicit rejection behavior.

## V8 — evidence graph

- requirement -> claim -> proof -> artifact links;
- assumptions surfaced;
- exact tool/profile identities;
- machine-readable export.

## V9 — translation validation

- at least one useful CheckedCore/VerifiedIR/backend slice validated per build;
- validator failure blocks high-assurance build.

## V10 — non-toy benchmark

At least ten real packages/components with:

- locked specs;
- generated or migrated implementations;
- kernel-checked properties;
- independent replay;
- measured human review cost.

---

# 23. Metrics

Do not optimize for:

~~~text
lines of AI code
tokens consumed
number of generated proofs
percentage of files touched
~~~

Measure:

~~~text
human minutes per trusted capability
requirements formalized / total important requirements
proof discharge rate
independent replay rate
assumption count and severity
spec mutation kill rate
counterexamples found before implementation
reusable lemma/spec reuse rate
verification time
agent repair iterations
post-merge defect rate
maintenance cost after requirement change
translation-validation coverage
foreign-boundary coverage
~~~

## 23.1 Proof coverage is not requirement coverage

A project with 100% proof success on 20 trivial properties may be less assured than a project with 80% proof success on 100 meaningful requirements.

Therefore always report both:

~~~text
formal property closure
AND
requirement coverage
~~~

---

# 24. Failure modes and defenses

## 24.1 AI weakens the specification

Defense:
- locked SpecCapsule;
- diff approval;
- mutation testing.

## 24.2 AI proves a vacuous theorem

Defense:
- satisfiability/non-vacuity checks;
- spec audit.

## 24.3 AI edits trusted definitions

Defense:
- challenge/solution separation;
- clean reconstruction.

## 24.4 AI introduces axioms

Defense:
- axiom allowlist;
- assumption graph.

## 24.5 Tests pass but proof fails

Interpretation:
- implementation may violate the formal claim;
- tests are insufficient evidence.

## 24.6 Proof passes but runtime misbehaves

Possible causes:
- compiler/backend bug;
- foreign boundary mismatch;
- spec incomplete.

Defense:
- translation validation;
- runtime conformance;
- explicit assurance vector.

## 24.7 Imported model is wrong

Defense:
- preserve provenance;
- review formalization;
- runtime conformance tests;
- never label importer output human-approved automatically.

## 24.8 AI overfits checker quirks

Defense:
- small TCB;
- independent replay;
- secondary checker for high-assurance profiles;
- clean grading environment.

## 24.9 Formalization cost dominates development

Defense:
- reusable spec libraries;
- vertical specialization;
- verify high-value modules first;
- gradual verification.

---

# 25. What belongs in the language versus libraries/tools

VSDD should resist adding syntax when libraries or tooling suffice.

## Current language

- dependent types / Prop foundation;
- theorem/proof terms;
- pure requires;
- pure ensures;
- existing r3 proof surface.

## Likely future language ergonomics

After semantics are stable:

- verified assert;
- loop invariant;
- decreasing;
- selected state/effect contract sugar.

## Libraries / program logic

Prefer libraries for:

- State/Except specifications;
- parser/codec laws;
- collections specs;
- state machines;
- temporal logic;
- resources;
- async/task models.

## Tooling

Keep outside the language:

- RequirementIR;
- SpecCapsule;
- UML/SysML/OpenAPI importers;
- AI workflows;
- spec mutation;
- evidence graph;
- provenance;
- agent protocol;
- review UI.

## Kernel

No new kernel mechanism should be added merely to support VSDD unless a genuine logical foundation requirement is demonstrated.

---

# 26. Relationship to existing ProofScript architecture

VSDD fits the current pipeline:

~~~text
RequirementIR / SpecCapsule
        |
        v
ProofScript source + formal claims
        |
        v
parser / Meta / Elab
        |
        v
candidate proof terms
        |
        v
PSKernel
        |
        v
CheckedCore
        |
        v
erasure
        |
        v
VerifiedIR
        |
        v
backend
~~~

Important existing strengths:

- fail-closed behavior;
- replayable checked-admission artifacts;
- explicit runtime extern assumptions;
- source/profile identities;
- CheckedCore boundary;
- target-neutral VerifiedIR;
- language-service distinction between parse success and kernel verification;
- fixed Standard registration discipline.

VSDD should build around these rather than introduce a second compiler or verifier stack.

---

# 27. Why ProofScript may be particularly suitable for AI-driven development

The advantage is not that AI understands ProofScript better today than TypeScript or Python.

It almost certainly has less training exposure today.

The architectural advantages are different.

## 27.1 Reduced semantic freedom

A closed Standard grammar and fixed registrations reduce dependency-driven interpretation changes.

For agents this means a smaller search space and stronger reproducibility.

## 27.2 Canonical checked identities

Canonical source/core/artifact identities support:

- caching;
- retrieval;
- proof reuse;
- exact diffs;
- evidence graphs;
- reproducible agent evaluation.

## 27.3 Rich semantic feedback

Instead of only:

~~~text
test failed
type mismatch
runtime exception
~~~

an agent can receive:

~~~text
Goal:
amount <= balance ->
balance - amount + amount = balance

Context:
amount : Nat
balance : Nat
h : amount <= balance
~~~

This is a high-information repair signal.

## 27.4 Generator/checker separation

AI is naturally strong at proposing candidates.

ProofScript can make acceptance deterministic:

~~~text
probabilistic generator
-> deterministic checker
~~~

That is a better safety architecture than attempting to make the generator itself trustworthy.

## 27.5 Proof knowledge compounds

Agent-generated helper lemmas and verified Standard specifications can become reusable assets.

Vero's results suggest repository-level success depends heavily on reusable helper theorem structure.

## 27.6 Multiple assurance layers are explicit

CheckedCore and VerifiedIR provide a natural place to separate:

- logical proof;
- executable semantics;
- backend correctness.

This is valuable for both agents and auditors.

---

# 28. Comparison with adjacent approaches

## 28.1 Versus ordinary SDD

Ordinary SDD:
- stronger intent persistence;
- mostly document/test based;
- agent often evaluates its own convergence.

VSDD:
- adds formal claims;
- locks critical meaning;
- produces kernel-checkable evidence;
- distinguishes proved/tested/assumed.

## 28.2 Versus Dafny

Dafny:
- mature contracts and automatic VC/SMT experience;
- strong practical verifier.

ProofScript target differentiation:
- Lean-grounded explicit proof evidence;
- portable replay;
- small independent PSKernel path;
- gradual integration with JS/npm;
- evidence graph and AI-spec workflow as first-class product goals.

ProofScript should learn heavily from Dafny rather than replicate it poorly.

## 28.3 Versus Lean

Lean:
- vastly richer theorem ecosystem;
- powerful extensibility;
- mature automation.

ProofScript target differentiation:
- constrained Standard source;
- ordinary application-programming ergonomics;
- explicit FFI/runtime assurance model;
- VSDD workflow and JS/platform integration.

ProofScript need not outperform Lean as a general theorem prover.

## 28.4 Versus F* / Verus

These systems provide strong precedents for effect-aware and systems verification.

ProofScript should reuse the architectural lessons:
- effect-specific reasoning;
- ghost/proof erasure;
- executable/spec separation;
- reusable verified libraries.

## 28.5 Versus P

P is exceptionally strong for distributed state-machine modeling and verification.

ProofScript should not replace P's specialization prematurely.

Instead:
- study P's modeling discipline;
- borrow design-document-to-formal-model agent workflow ideas;
- add broader functional/dependent proof integration where ProofScript is stronger.

---

# 29. Roadmap

## Phase A — VSDD foundation

Build:

~~~text
RequirementIR-v1
SpecCapsule-v1
EvidenceGraph-v1
pure contract obligation identity
psc spec / verify / audit skeleton
~~~

Exit:
a human-authored pure ProofScript package can trace requirement -> contract -> proof -> replayed evidence.

## Phase B — AI proof worker

Build:

~~~text
AgentProtocol-v1
structured goal API
lemma/spec retrieval
candidate proof API
clean independent replay
~~~

Exit:
an AI can solve proof obligations without controlling final proof status.

## Phase C — specification auditing

Build:

~~~text
satisfiability checks
vacuity checks
semantic mutation
formal challenges
cross-requirement consistency
~~~

Exit:
a proved-but-obviously-weak specification is discoverable by automated audit in curated benchmark cases.

## Phase D — joint generation

Build:

~~~text
program-proof plan artifact
implementation/proof scaffolding
checker-feedback repair loop
~~~

Benchmark against implementation-first generation.

## Phase E — first verified factory vertical

Parser/codec/schema.

Exit:
at least ten useful generated/migrated packages.

## Phase F — state machines / business logic

Build explicit state/effect verification and transition models.

## Phase G — model import

Prioritize:

~~~text
OpenAPI
JSON Schema
SysML v2
bounded OCL
~~~

## Phase H — compiler/runtime assurance

Translation validation and runtime conformance evidence.

## Phase I — Forge product layer

Only after deterministic primitives exist should Forge become a broad conversational product.

---

# 30. Product principle

The user experience should eventually support:

~~~text
User:
“Build X.”

ProofScript:
“Here are the requirements I inferred.
Here are ambiguities.
Here are the properties I can formalize.
Here are properties that remain test-only or assumed.
Approve the specification?”

User:
approves

AI:
generates implementation + proof candidates

ProofScript:
“These 24 properties are kernel-proved.
These 4 are tested.
These 2 depend on explicit foreign assumptions.
Compilation is translation-validated for this backend slice.
Here is the replayable evidence.”
~~~

This is a better contract with the user than pretending that a natural-language prompt is a complete specification.

---

# 31. Non-goals

VSDD-v1 does not promise:

- arbitrary prompt -> fully correct software;
- autonomous acceptance of AI-generated specifications;
- proof of UI aesthetics;
- proof of every performance property;
- full verification of every npm dependency;
- verified operating systems/cloud providers;
- complete UML/SysML semantic coverage;
- automatic temporal verification for every application;
- zero-human-review high-stakes development;
- a single “100% verified” score;
- replacement of Lean, Dafny, F*, Verus, P, TLA+, or existing modeling tools in domains where they are stronger.

---

# 32. Research questions

Measure rather than assume:

1. Does human review shift from generated code toward smaller semantic specifications?
2. Does that reduce total verification time?
3. Do reusable spec/lemma libraries lower marginal cost over successive packages?
4. Which requirement formats formalize reliably?
5. Does SysML v2 provide useful structure beyond direct RequirementIR authoring?
6. Does semantic mutation predict real specification defects?
7. Does joint program-proof planning outperform program-first generation in ProofScript?
8. Does the closed Standard profile measurably improve agent reliability?
9. Does independent replay catch realistic agent/repository failures?
10. Can CheckedCore/VerifiedIR translation validation provide practical end-to-end assurance without a fully verified compiler?
11. At what project scale do foreign assumptions dominate?
12. Which classes of software yield the best human-minutes-per-trusted-capability ratio?

---

# 33. Recommended near-term decision

Adopt this architecture as the research target for AI/spec-driven development, but keep the following boundary explicit:

> **VSDD is a toolchain and assurance architecture layered on ProofScript. It is not a new r3 source-language specification.**

Immediate design work should therefore prioritize:

~~~text
1. RequirementIR-v1
2. SpecCapsule-v1
3. EvidenceGraph-v1
4. pure-contract obligation identity
5. structured agent protocol
6. spec-audit semantics
7. independent replay policy
~~~

before adding broad new verification syntax.

---

# 34. Final thesis

The core problem in AI-driven software development is changing.

It used to be:

> How do we write enough code?

It is increasingly:

> How do we know what generated code means, whether it satisfies what we asked for, and what assumptions remain?

ProofScript can make a strong contribution if it treats AI as an untrusted but highly productive synthesis engine and makes specification, checking, replay, and evidence first-class.

The target is:

~~~text
prompt/docs/models
        |
        v
RequirementIR
        |
        v
reviewed formal meaning
        |
        v
SpecCapsule
        |
        v
AI program + proof generation
        |
        v
kernel-checked evidence
        |
        v
explicit compiler/boundary evidence
        |
        v
deployable software with auditable claims
~~~

The product promise should be:

> **AI may write the software. ProofScript should make precise what we are justified in trusting.**

---

# 35. References and prior art

## ProofScript repository

- [ProofScript Language Reference v0.9.0 r3](./ProofScript_Language_Reference_v0.9.0_r3.md)
- [ProofScript Programming Language — Identity and Plans](./ProofScript_Programming_Language_IDENTITY_AND_PLANS.md)
- [Post-PSC2 Language Roadmap](./POST_PSC2_LANGUAGE_ROADMAP.md)

## Current AI / Spec-Driven Development

- GitHub Spec Kit: https://github.github.com/spec-kit/
- GitHub Spec Kit Agentic SDD: https://github.github.com/spec-kit/reference/agentic-sdd.html
- GitHub Spec Kit Quickstart: https://github.github.com/spec-kit/quickstart.html
- Kiro Requirements-First Specs: https://kiro.dev/docs/specs/feature-specs/requirements-first/
- DORA, “Balancing AI tensions”: https://dora.dev/insights/balancing-ai-tensions/

## Formal verification and AI

- Vero: https://rdi.berkeley.edu/blog/vero/
- P³: Joint Program-and-Proof Planning: https://arxiv.org/abs/2608.09277
- SpecSyn: https://arxiv.org/abs/2604.21570
- Lean proof validation: https://lean-lang.org/doc/reference/latest/ValidatingProofs/
- Dafny reference and audit: https://dafny.org/dafny/DafnyRef/DafnyRef
- Dafny verification optimization: https://dafny.org/latest/VerificationOptimization/VerificationOptimization
- F*: https://fstar-lang.org/
- Verus: https://verus-lang.github.io/verus/guide/
- P language: https://p-org.github.io/P/

## Modeling standards

- OMG SysML 2.0: https://www.omg.org/spec/SysML/2.0/
- OMG OCL: https://www.omg.org/spec/OCL/
- OMG UML: https://www.omg.org/spec/UML/

---

**Research status:** recommended architecture for implementation experiments. Claims about productivity, AI reliability, spec-import quality, or ecosystem compounding remain hypotheses until measured on non-toy ProofScript projects.
