# ProofScript AI-Accelerated Verified Development and SAVEF Compounding Direction

**Status:** strategic research and engineering direction; non-normative until incorporated into the relevant ProofScript, PSCV, PSKernel, and SAVEF references.

**Repository:** `dwijayuda/pskernel`

**Research snapshot:** 2026-10-07

**Primary empirical workloads:**

1. PSKernel Core implementation, Lean-compatibility, Arena/corpus validation, and metatheory/refinement work.
2. PSCV compiler implementation, self-hosting, VerifiedIR/SpecializedIR, JS/Wasm/Rust backends, preservation/translation-validation work, and SAVEF/FactoryBench integration.

---

# 1. Executive decision

ProofScript should treat AI-assisted verified development as a first-class systems problem rather than primarily a prompt-engineering problem.

The central hypothesis is:

> A verified-development environment can become materially faster, cheaper, and more reliable when the compiler/proof assistant exposes machine-oriented semantic feedback, the agent retrieves only the relevant semantic slice, successful checked work is stored as reusable typed knowledge, and later tasks consume that accepted knowledge under explicit validity rules.

The target loop is:

~~~text
exact task / claim
        |
        v
semantic context slice
        |
        v
AI proposes implementation / proof / compiler change
        |
        v
low-latency compiler / kernel / proof checker
        |
   +----+----+
   |         |
 reject     accept
   |         |
structured   v
feedback   checked result
   |         |
   +----> repair
             |
             v
      reusable SAVEF knowledge
             |
             v
          next task
~~~

This direction applies to both major ProofScript work classes:

~~~text
PSKernel lane
    executable kernel
        ->
    semantic/refinement judgments
        ->
    machine-checked implementation soundness

PSCV compiler lane
    source/compiler implementation
        ->
    CheckedCore / RuntimeIR / VerifiedIR / SpecializedIR
        ->
    target lowering / validation / self-hosting
        ->
    preservation and executable evidence
~~~

The recommended order is:

1. build persistent, low-latency machine interfaces to Lean/PSCV/PSKernel checking;
2. expose structured goals, contexts, compiler diagnostics, dependencies, semantic owners, and stage identities;
3. construct semantic context slicing and premise/code retrieval;
4. extract actual proof dependencies and compiler-pass dependencies from accepted work;
5. build reusable proof/refinement/compiler frameworks for recurring task families;
6. store accepted results and scoped failure experience as SAVEF knowledge;
7. compute dependency-aware work frontiers and parallelize only independent tasks;
8. measure whether accumulated accepted knowledge reduces the cost of later accepted work;
9. only after those gains are demonstrated, consider fine-tuning, self-play, or specialized smaller prover/compiler-agent models.

The purpose of SAVEF in this program is therefore falsifiable:

> SAVEF succeeds as a compounding knowledge system only if accumulated accepted knowledge measurably improves later accepted software/proof work without weakening assurance.

---

# 2. Why PSKernel and PSCV are the right real-world experiments

These are not toy theorem benchmarks.

## 2.1 PSKernel workload

PSKernel combines:

- a nontrivial Lean-compatible executable kernel;
- a portable/self-host-oriented implementation discipline;
- complex mutually recursive checker functions;
- definitional equality, reduction, inference, admission, inductives, recursors, quotients, caches, and resource policy;
- an Assurance Plane relating executable behavior to independently stated semantic judgments;
- differential checking against Lean;
- Arena and large-corpus validation;
- real implementation defects exposed by proof or cross-checking.

By 2026-10-07 the active metatheory branch had reached a large checked corpus and had already exposed semantic defects including:

- free-variable state escaping through caches;
- universe normalization mismatch;
- conflated structural/checker fuel;
- constructor checking that incorrectly manufactured Pi binders through WHNF.

That is exactly the kind of environment where proof reuse, semantic retrieval, structured diagnostics, and checked repair histories can be evaluated honestly.

## 2.2 PSCV compiler workload

The PSCV compiler provides a complementary workload:

- frontend and elaboration work;
- explicit authority boundaries;
- CheckedCore capability flow;
- RuntimeIR -> VerifiedIR -> SpecializedIR;
- specialization and erasure;
- target-specific JS/Wasm/Rust lowering;
- translation validation;
- direct self-host fixed points;
- interface/ABI validation;
- semantic QueryGraph reuse;
- comparator and provider orchestration;
- SAVEF knowledge publication and retrieval;
- offline verification;
- FactoryBench.

This workload is especially useful because many costs are not theorem proving at all. They include:

- locating the right implementation owner;
- understanding pipeline phase contracts;
- diagnosing generated-code failures;
- identifying whether a failure is semantic, representation, performance, or toolchain related;
- reproducing backend divergence;
- preserving exact fixed-point criteria;
- separating implementation success from assurance claims;
- keeping branch/contract state synchronized.

If SAVEF only helps theorem proving but not compiler engineering, its ecosystem value is narrower than intended.

Therefore the research program must evaluate both.

---

# 3. The bottleneck model

For AI-assisted verified development, total accepted-work cost can be approximated as:

~~~text
total accepted-work cost
=
context discovery
+ model reasoning
+ candidate generation
+ verifier/compiler latency
+ failure interpretation
+ repair iterations
+ duplicated implementation/proof effort
+ integration/revalidation
~~~

The most expensive term is not always "reasoning."

Observed PSKernel and PSCV work repeatedly show expensive loops caused by:

- delayed CI feedback;
- overly broad build/proof closures;
- source/proof equation misalignment;
- missing semantic context;
- repeated rediscovery of nearby lemmas and invariants;
- repeated diagnosis of known backend ownership/fixed-point patterns;
- human-oriented rather than agent-oriented diagnostics;
- branch divergence and stale architectural assumptions.

This suggests the likely leverage order:

| Improvement | Expected leverage |
| --- | --- |
| Persistent low-latency Lean/PSCV/PSKernel service | Very high |
| Exact semantic/premise/code retrieval | Very high |
| Actual dependency extraction from accepted work | Very high |
| Reusable proof/refinement/compiler frameworks | Very high |
| Structured task/subgoal decomposition | High |
| Machine-readable diagnostics | High |
| Dependency-aware parallel work frontier | High |
| SAVEF failure/repair knowledge | Medium-high |
| Smaller-model routing for routine tasks | Medium-high cost benefit |
| Prompt wording refinement | Medium |
| New syntax alone | Low initially; possibly negative without tooling |
| Training a new foundation model immediately | Poor near-term return |

These are hypotheses to benchmark, not guaranteed speedups.

---

# 4. External research basis

## 4.1 LeanDojo: premise selection matters

LeanDojo introduced fine-grained programmatic Lean interaction and premise annotations and identified premise selection as a major bottleneck in theorem proving.

Reference:

https://arxiv.org/abs/2306.15626

Project:

https://github.com/lean-dojo/ReProver

Direction:

> SAVEF retrieval should be evaluated as semantic premise selection under exact accessibility and validity constraints, not generic text search.

## 4.2 LeanSearch v2: retrieval can strongly affect proof success

LeanSearch v2 targets global premise retrieval for entire theorem proofs. In its controlled downstream evaluation, the paper reports 20% proof success with its best retrieval mode versus 4% without retrieval under the fixed prover loop.

Reference:

https://arxiv.org/abs/2605.13137

Direction:

> Retrieval quality can be a major multiplier even when the outer prover stays fixed.

## 4.3 Pantograph: machine-oriented prover interfaces matter

Pantograph provides machine-to-machine Lean interaction designed for automated proof search rather than relying on presentation-oriented IDE state.

References:

https://github.com/leanprover/Pantograph

https://link.springer.com/chapter/10.1007/978-3-031-90643-5_6

Direction:

> ProofScript should expose a stable agent/search API rather than forcing agents to scrape human compiler output.

## 4.4 Kimina Lean Server: persistent verification is useful

Kimina Lean Server provides pooled Lean REPL processes, concurrency, and context reuse. Its repository reports lower verification latency under REPL caching while preserving the same checked outcome rate in its benchmark.

Reference:

https://github.com/project-numina/kimina-lean-server

Direction:

> Reuse loaded proof/compiler context safely when exact semantic identities match.

## 4.5 DeepSeek-Prover-V2: decomposition helps hard formal reasoning

DeepSeek-Prover-V2 uses recursive subgoal decomposition as a central theorem-proving technique.

Reference:

https://arxiv.org/abs/2504.21801

Direction:

> Represent difficult PSKernel/PSCV obligations as explicit dependency DAGs of smaller claims where possible.

## 4.6 Compiler feedback improves code generation

CoCoGen uses compiler/static-analysis feedback to retrieve project context and repair generated code iteratively.

Reference:

https://aclanthology.org/2024.findings-acl.138/

Direction:

> Compiler errors should trigger semantic retrieval and localized repair, not whole-solution regeneration.

## 4.7 Static type constraints can reduce invalid generation

Type-Constrained Code Generation with Language Models reports large reductions in compilation failures and improved correctness by integrating typing constraints into generation.

Reference:

https://doi.org/10.1145/3729274

Direction:

> Strong static semantics are an AI advantage only when exposed early and cheaply.

## 4.8 Generative compilation: feed compiler semantics back during generation

Generative Compilation feeds static semantic information back while partial programs are being generated and reports improved repository-level Rust results.

Reference:

https://arxiv.org/abs/2607.13921

Direction:

> Partial program/proof checking should be a first-class ProofScript capability.

## 4.9 Typed holes improve semantic localization

Statically Contextualizing Large Language Models with Typed Holes demonstrates the value of type/context-guided localization for code completion and repair.

Reference:

https://doi.org/10.1145/3689728

Direction:

> Typed holes, proof holes, and partial elaboration are machine-efficiency features, not just editor conveniences.

## 4.10 Self-play comes later

STP demonstrates that formally checked self-generated proof data can improve later theorem proving, but at very large token-generation cost.

Reference:

https://proceedings.mlr.press/v267/dong25h.html

Direction:

> Exploit cheap compounding through retrieval/reuse first. Do not begin with a costly ProofScript-specific self-play program.

---

# 5. Programming language choice: important, but secondary to the semantic interface

Programming language choice matters through:

- surface regularity;
- static typing strength;
- amount of implicit behavior;
- quality of partial checking;
- determinism;
- stable semantic IDs;
- error quality;
- library maturity;
- available training/examples;
- interoperability with existing proof automation.

However, the AI does not interact with syntax alone. It interacts with the compiler/prover.

A strict language with:

- low-latency partial elaboration;
- exact typed holes;
- structured goal states;
- precise machine diagnostics;
- semantic retrieval;
- deterministic checker acceptance;

can be easier for AI than a simpler language with weak or slow feedback.

Therefore ProofScript should optimize for:

> invalid semantic directions are cheap to detect; valid semantic directions are cheap to continue.

It should not primarily optimize for:

> the source text is easy for a language model to autocomplete.

---

# 6. Recommended source/proof split

The current separation between portable execution source and richer proof source is strategically useful.

~~~text
EXECUTABLE / SELF-HOST SOURCE

PSC1-selfhost-stable / PSC1-portable-selfhost style
    |
    +-- small surface
    +-- explicit control
    +-- portable/self-hostable
    +-- stable implementation subset
    +-- predictable backend lowering


PROOF / ASSURANCE SOURCE

PSCV / Lean proof layer
    |
    +-- propositions
    +-- theorem abstractions
    +-- tactics
    +-- proof automation
    +-- richer proof-only syntax
    +-- mature Lean libraries
~~~

Do not force proof code to obey implementation-source restrictions that exist only for bootstrap portability.

A complex tactic is acceptable outside the TCB when it emits a proof term checked by the trusted kernel.

---

# 7. Do not make native PSCV proof syntax a prerequisite for productivity

A new proof syntax starts as a low-resource language for existing models.

Lean already provides:

- large public proof corpora;
- tactics;
- theorem search;
- proof-agent interfaces;
- benchmarks;
- trained formal models.

The recommended transitional architecture is:

~~~text
ProofScript / PSCV proof presentation
                |
                v
canonical Lean proof representation
                |
        +-------+-------+
        |               |
        v               v
Lean goal state     Lean automation
        |
        v
kernel checking
~~~

The agent may see both the ProofScript-facing semantic identity and the canonical Lean goal/context.

Accepted PSCV proofs can gradually become a native ProofScript corpus.

---

# 8. Build one ProofScript machine service

Create a stable service used by agents, CLI, IDE/LSP, compiler tools, FactoryBench, and SAVEF.

Illustrative operations:

~~~text
goal
context
premises
tryCandidate
holes
typeOf
semanticDiff
affectedArtifacts
affectedProofs
compilerStage
passContract
artifactIdentity
failureClass
explainDiagnostic
~~~

Example proof-goal response:

~~~json
{
  "goalId": "...",
  "claimId": "...",
  "statementFingerprint": "...",
  "target": "...",
  "localContext": [],
  "semanticProfile": "...",
  "implementationSubject": "...",
  "semanticOwner": "...",
  "accessiblePremises": [],
  "directDependencies": [],
  "assumptions": [],
  "proofStatus": "open"
}
~~~

Example compiler failure response:

~~~json
{
  "status": "rejected",
  "code": "PSC-VERIFIEDIR-CALL-ARITY",
  "stage": "RuntimeIR->VerifiedIR",
  "subjectId": "...",
  "sourceSpan": {},
  "expected": {"arity": 2},
  "actual": {"arity": 3},
  "semanticOwner": "Ps.CompilerIr.Validate",
  "relatedContracts": ["psc-verified-ir/1"],
  "repairClass": "local-shape"
}
~~~

The goal is to remove large amounts of model reasoning currently spent only interpreting logs.

---

# 9. Persistent workers keyed by exact identity

A reusable worker must be tied to an exact context.

Suggested identity bundle:

- Git commit;
- semantic profile;
- Lean/toolchain identity;
- imported module/interface hashes;
- PSKernel provider identity;
- compiler contract versions;
- relevant proof environment identity.

A cache hit or persistent session may improve speed.

It may never mint semantic authority.

If the identity changes incompatibly, reload or recompute.

---

# 10. Semantic retrieval, not generic RAG

SAVEF should retrieve a small semantic slice.

For a PSKernel proof task, that slice might contain:

- executable implementation owner;
- independent semantic judgment;
- checker-state invariant;
- context/weakening lemmas;
- cache invariant;
- analogous proof family;
- known failure patterns;
- actual premises used by neighboring accepted proofs.

For a PSCV compiler task, it might contain:

- pipeline stage and contract;
- implementation owner;
- exact input/output IR type;
- validator;
- pass definition;
- current preservation status;
- backends consuming the stage;
- fixed-point dependencies;
- prior similar compiler repair;
- relevant target/runtime assumptions.

The ranking should combine:

~~~text
semantic similarity
+
symbol/type compatibility
+
actual dependency history
+
stage/contract compatibility
+
validity under current semantic context
~~~

Search exposure is not semantic reuse.

Every retrieved object must pass its SAVEF `ValidUnder(context)` check before authority-bearing use.

---

# 11. Extract actual dependencies automatically

After an accepted proof:

- inspect its checked proof term/declaration dependencies;
- record which theorems were actually used;
- record semantic profile and assumptions;
- record proof/checker identity;
- record task/claim identity.

After an accepted compiler change:

- record changed implementation subjects;
- pass/stage contracts exercised;
- validators invoked;
- dependent interfaces;
- backend targets affected;
- evidence produced;
- fixed-point/incremental impact.

This creates high-quality supervision for future retrieval.

It is more valuable than manually tagging every source file.

---

# 12. Store experience as well as authority

SAVEF should store at least two clearly separated classes.

## 12.1 Accepted authority-bearing knowledge

Examples:

- checked theorem;
- validated compiler pass result;
- proven refinement;
- accepted module interface;
- checked certificate;
- exact artifact identity.

These can participate in authority only after configured validation.

## 12.2 Advisory experience knowledge

Examples:

- failed strategy;
- compiler diagnostic pattern;
- successful decomposition;
- useful tactic sequence;
- repair path;
- performance workaround;
- known stale approach;
- recurring backend ownership issue.

Example:

~~~text
FailureKnowledge

goal family:
    recursor refinement

attempt:
    treat K conversion as ordinary reduction

failure:
    independent reduction relation cannot justify the step

resolution:
    carry explicit DefEq major-conversion evidence
~~~

Negative knowledge must remain advisory.

A previously failed approach may become valid after semantics or context changes.

---

# 13. Build reusable proof and compiler frameworks

The highest-value work is often not a theorem specific to one call site.

It is a reusable framework that removes entire future proof families.

For PSKernel, high-leverage candidates include:

1. executable Boolean <-> proposition reflection;
2. generic checker-state/configuration preservation combinators;
3. optional-reduction refinement framework;
4. fuel/structural recursion induction framework;
5. context weakening/freshness transport;
6. generic cache refinement;
7. environment-index refinement;
8. declaration-extension/admission composition;
9. exact success-result to independent semantic judgment adapters.

For PSCV compiler work, high-leverage candidates include:

1. generic pass-contract/execution framework;
2. generic RuntimeIR/VerifiedIR validator law framework;
3. semantic-interface fingerprint framework;
4. target-lowering translation-validation framework;
5. ABI/interface validation framework;
6. exact fixed-point comparison tooling;
7. backend-independent specialization contracts;
8. reusable resource/budget outcome model;
9. semantic-delta/trust-delta calculation;
10. generic certificate-boundary adapters.

SAVEF should assign engineering priority to high-fanout reusable knowledge.

Truth does not depend on leverage score.

Work prioritization may.

---

# 14. Freeze claims before proof search

AI must not be allowed to solve a task by silently weakening it.

Before a proof/verification task starts, freeze:

~~~text
ClaimId
SubjectId
StatementFingerprint
SemanticProfile
AssumptionClosure
AcceptancePolicy
~~~

The agent may modify:

- proof body;
- helper lemmas;
- implementation where authorized;
- local decomposition.

The agent may not silently modify:

- theorem statement;
- semantic relation;
- assumptions;
- validator policy;
- acceptance threshold.

A change to those produces an explicit SemanticDelta and normally a new claim identity.

This is essential for trustworthy autonomous work.

---

# 15. Decompose tasks into explicit DAGs

Large objectives should become dependency graphs.

Example PSKernel:

~~~text
final checker soundness
    |
    +-- inference soundness
    +-- WHNF refinement
    +-- DefEq soundness
    +-- recursor reduction
    +-- cache/state preservation
    +-- admission refinement
            |
            +-- ordinary inductive
            +-- mutual inductive
            +-- nested inductive
~~~

Example PSCV compiler:

~~~text
verified executable artifact
    |
    +-- CheckedCore authority
    +-- erasure relation
    +-- VerifiedIR invariants
    +-- specialization relation
    +-- target lowering
    +-- target validator
    +-- ABI/interface validity
    +-- artifact provenance
~~~

At any time compute the proof/implementation frontier:

> all unresolved nodes whose prerequisites are accepted.

Only those nodes should be parallelized.

This avoids several agents rereading the entire repository or editing the same semantic owner concurrently.

---

# 16. Prompt engineering should shrink over time

Long architecture-first prompts are useful today because project policy is not fully machine-addressable.

The long-term goal is:

~~~text
stable repository policy
    -> AGENTS.md / normative architecture docs

current progress
    -> AI_WORK_STATE.md / machine status

exact task
    -> SAVEF TaskObject / ClaimObject
~~~

Then a future instruction can be short:

> Continue claim `pskernel.defeq.finalrules.sound/v1`.

or:

> Continue compiler task `pscv.backend-wasm.fixedpoint/v1`.

The object already defines:

- branch/base commit;
- subject;
- dependencies;
- allowed files;
- forbidden semantic changes;
- acceptance criteria;
- current blocker;
- relevant knowledge;
- exact checker/compiler profile.

This reduces token cost and prompt drift.

---

# 17. Route different work to different model/tool levels

Correctness should come from deterministic checkers, not from always using the most expensive model.

Potential routing:

~~~text
mechanical import/syntax repair
simple generated lemmas
boilerplate pass metadata
    -> deterministic tool / small model

localized compiler bug
medium theorem
proof repair
    -> normal reasoning model

new semantic invariant
architecture
hard proof decomposition
cross-system diagnosis
    -> strongest reasoning model
~~~

Every authority-bearing output is still checked.

This can reduce cost without reducing assurance.

---

# 18. Make partial code and proof holes first-class

The system should support useful semantic feedback before a whole file/module is complete.

For proofs:

~~~text
theorem T ... := by
  ...
  have h : ... := by
    ?
  ...
~~~

The machine service should return the exact hole goal, context, accessible premises, and semantic identity.

For compiler/source code, partially complete modules should still expose:

- expected type;
- unresolved names;
- required capabilities;
- stage contract;
- missing fields/branches;
- invalid IR fragments;
- downstream affected interfaces.

This enables generative-compilation-style feedback loops.

---

# 19. Treat PSKernel and PSCV as separate but connected learning domains

Do not flatten all accepted work into one undifferentiated knowledge store.

Use typed domains:

~~~text
kernel semantics
kernel implementation refinement
compiler frontend
compiler IR
compiler preservation
backend JS
backend Wasm
backend Rust
self-host/bootstrap
interface/ABI
resource behavior
SAVEF/indexing
tooling
~~~

Cross-domain reuse must be explicit.

Examples:

- a substitution theorem may support kernel and compiler proofs;
- a VerifiedIR invariant may support JS and Wasm;
- a Wasm tail-call repair should not automatically become a JS optimization rule;
- a kernel Arena regression is assurance knowledge, not a compiler-preservation theorem.

Typed separation prevents knowledge contamination.

---

# 20. Proposed FactoryBench expansion

FactoryBench should include both theorem-proving and compiler-engineering tasks.

## 20.1 PSKernel MetatheoryBench

Task families:

- missing local refinement theorem;
- checker-state preservation;
- reduction/DefEq bridge;
- recursor semantics;
- cache refinement;
- context weakening;
- admission/inductive refinement;
- proof repair after implementation changes.

## 20.2 PSCV CompilerBench

Task families:

- VerifiedIR validator gap;
- specialization bug;
- backend lowering bug;
- ABI/interface mismatch;
- direct JS/Wasm/Rust fixed-point failure;
- semantic QueryGraph invalidation;
- pass-evidence wiring;
- preservation/translation-validation obligation;
- performance regression with semantic constraints.

---

# 21. Experimental arms

Use staged ablation so improvements are attributable.

## B0 — current baseline

~~~text
repository
+ normal search
+ current agent workflow
+ GitHub/cloud validation
~~~

## B1 — persistent checker/compiler service

Add only low-latency reused environments.

Measure latency reduction independently.

## B2 — semantic slicing

Add exact task-context construction.

No SAVEF experience retrieval yet.

## B3 — accepted semantic retrieval

Add checked theorem/interface/pass knowledge.

## B4 — dependency-aware reuse

Add actual proof/compiler dependency histories and analogous accepted tasks.

## B5 — experience knowledge

Add scoped failure knowledge, repair histories, decomposition patterns, and proof recipes.

## B6 — specialized automation/model routing

Add smaller specialized models or deterministic automation only after B1-B5 establish a strong baseline.

---

# 22. Metrics

Do not measure only "task completed."

Track:

~~~text
accepted tasks
wall-clock time

model input tokens
model output tokens
model calls

checker/compiler calls
full CI runs

failed attempts
repair cycles

human interventions

retrieved objects
actually consumed objects
reused accepted dependencies

new reusable knowledge produced

semantic bugs discovered
regressions introduced

proof churn after implementation change
compiler churn after interface-preserving change

edit-time latency
checkpoint latency
release latency
~~~

Primary economics metric:

> cost per accepted theorem / accepted compiler task.

Primary compounding metric:

> marginal cost of accepted tasks as valid reusable knowledge accumulates.

---

# 23. What would count as compounding?

The strong SAVEF hypothesis is not merely:

> retrieval is useful.

It is:

~~~text
generation N accepted knowledge
        |
        v
generation N+1 accepted work becomes cheaper/better
        |
        v
generation N+1 produces additional reusable knowledge
        |
        v
generation N+2 improves further
~~~

Evidence for compounding should show a trend such as:

- lower median tokens per accepted task;
- fewer repair iterations;
- fewer broad CI runs;
- higher accepted-task rate under equal budget;
- lower proof maintenance after refactors;
- higher reuse rate of previously accepted knowledge.

If performance remains flat while the knowledge graph grows, SAVEF may still be a useful retrieval/audit system but should not claim self-amplification.

---

# 24. Falsification criteria

Revise or shrink this direction if controlled experiments repeatedly show:

1. persistent sessions do not materially reduce end-to-end task cost;
2. semantic slicing performs no better than ordinary repository search;
3. typed SAVEF retrieval performs no better than text retrieval under equal budget;
4. dependency extraction is too unstable to improve retrieval;
5. proof/compiler recipes cause more misleading reuse than useful reuse;
6. proof maintenance cost grows faster than theorem reuse benefit;
7. semantic interfaces fail to hide enough implementation detail for stable incremental reuse;
8. agent-parallel work produces too much merge/semantic conflict;
9. knowledge validation overhead dominates task savings;
10. accepted compiler/proof work rarely consumes previous accepted knowledge;
11. low-resource PSCV syntax materially harms agents without compensating tooling gains;
12. cheaper model routing increases repair cost enough to erase inference savings.

Negative results should be preserved and published.

---

# 25. Security and assurance invariants

AI acceleration must not weaken authority.

Permanent rules:

1. AI may propose; deterministic checkers decide.
2. Retrieval never creates authority.
3. A cached result never creates authority without its configured reuse validation.
4. Negative knowledge is advisory.
5. A proof statement cannot be silently weakened.
6. A compiler pass contract cannot be silently relaxed.
7. Resource exhaustion is never semantic acceptance.
8. Timeout is never proof.
9. Differential agreement is evidence, not proof by agreement.
10. Serialized receipts cannot recreate live checked capabilities.
11. Semantic context mismatches fail closed.
12. Search/index corruption causes recomputation or rejection, never acceptance.

---

# 26. SAVEF object direction

SAVEF should store semantic knowledge, not merely files.

Useful object families include:

~~~text
ClaimObject
TaskObject
TheoremKnowledge
CompilerPassKnowledge
ModuleInterfaceKnowledge
ArtifactKnowledge
FailureKnowledge
KnowledgeMigration
ReuseEvent
SemanticDelta
TrustDelta
~~~

Each authority-bearing object should bind:

- semantic identity;
- subject identity;
- assumptions;
- dependencies;
- claims;
- evidence;
- implementation witnesses where relevant;
- exact validity rules.

Use canonical JSON for SAVEF semantic objects.

Use external native evidence formats where appropriate, such as Lean export NDJSON for Lean-compatible logical evidence.

Do not create a new universal proof language as a prerequisite for this program.

---

# 27. Recommended implementation architecture

~~~text
                         GitHub
                     source of truth
                          |
                          v
                ProofScript Agent Service
                          |
        +-----------------+-----------------+
        |                 |                 |
        v                 v                 v
 Persistent Lean     PSCV compiler       SAVEF
 / PSKernel sessions    service         semantic index
        |                 |                 |
        +-------- goals / diagnostics ------+
                          |
                          v
                         AI
                          |
                    candidate change
                          |
                          v
                  fast scoped validation
                          |
                   +------+------+
                   |             |
                rejected       accepted
                   |             |
                repair           v
                          checkpoint commit
                                |
                                v
                          GitHub full CI
                                |
                                v
                    accepted SAVEF knowledge
                                |
                                +----> later tasks
~~~

The agent service is not a new semantic authority.

It is an efficient orchestration layer around existing authorities.

---

# 28. Priority roadmap

## P0 — freeze benchmark and instrumentation

Before optimizing the workflow:

- define MetatheoryBench and CompilerBench task families;
- capture baseline token/call/CI/latency metrics;
- freeze representative held-out tasks;
- record exact model/tool/commit identities.

## P1 — persistent machine service

Implement low-latency:

- Lean proof checking;
- PSCV compiler stage checking;
- PSKernel checks where practical;
- exact loaded-context identity;
- structured diagnostics.

This should be tested before adding complex SAVEF retrieval.

## P2 — semantic task model

Introduce machine-readable:

- ClaimId;
- TaskId;
- SubjectId;
- StatementFingerprint;
- SemanticProfile;
- stage/owner;
- acceptance policy;
- dependencies;
- current status.

## P3 — dependency extraction

Automatically collect:

- proof dependencies;
- compiler/pass/interface dependencies;
- affected-module relationships;
- evidence relationships.

## P4 — semantic retrieval

Build retrieval over:

- statements/types;
- semantic owner;
- actual dependency history;
- valid context;
- analogous accepted tasks.

## P5 — reusable frameworks

Prioritize proof/compiler abstractions that eliminate repeated task families.

## P6 — experience knowledge

Add:

- failure patterns;
- repair histories;
- decomposition recipes;
- compiler diagnostic families.

Keep them advisory.

## P7 — proof/compiler frontier scheduler

Compute independent ready tasks and parallelize only conflict-safe work.

## P8 — FactoryBench B0-B5

Publish results, including negative results.

## P9 — specialized automation

Only after demonstrated gains:

- premise rankers;
- tactic selection models;
- compiler-repair classifiers;
- small specialized models;
- fine-tuning/self-play.

---

# 29. Immediate practical recommendations for current work

While the full system is not yet built, existing chats/agents should already follow these rules:

1. **Use GitHub as source of truth.**
2. **Read exact current work-state/contract files before editing.**
3. **Reason from architecture and dependency graph before test-fix loops.**
4. **Prefer a reusable theorem/helper when several failures share one shape.**
5. **Keep implementation fixes separate from proof-only fixes.**
6. **Treat semantic bugs discovered by proof as first-class regression families.**
7. **Record why a strategy failed, not only that it failed.**
8. **Keep explicit claims of what is proved versus merely tested/implemented.**
9. **Avoid rerunning maximal whole-closure checks when a smaller authoritative check can reject the current candidate faster.**
10. **Run full closure at meaningful checkpoints and release boundaries.**
11. **Keep PSKernel and PSCV branch responsibilities explicit.**
12. **Do not let a new AI prompt become the only place where critical project policy exists.**

---

# 30. Strategic implication for ProofScript

If this program works, ProofScript's value is not only:

~~~text
a verified language
~~~

It becomes:

~~~text
a verified software-development system
whose accepted implementation/proof knowledge
makes later verified development measurably cheaper
~~~

That could compound across:

- PSKernel;
- PSCV compiler;
- standard libraries;
- backend libraries;
- runtime libraries;
- application frameworks;
- verification patterns;
- ecosystem packages;
- AI-authored extensions.

The flywheel would be:

~~~text
build
  |
verify
  |
publish accepted semantic knowledge
  |
retrieve/reuse
  |
build next thing faster
  |
verify
  |
publish more knowledge
  |
repeat
~~~

This is the strongest form of the SAVEF thesis.

---

# 31. Final recommendation

Do not begin by building a custom ProofScript foundation model or another large proof language/tool stack.

Build the feedback-and-knowledge loop first.

The highest-value next research/engineering objective is:

> Create an AI-oriented persistent ProofScript/Lean/PSKernel service plus SAVEF semantic retrieval and benchmark it on unfinished PSKernel metatheory **and** real PSCV compiler tasks.

The experiment should answer, quantitatively:

- Can the same model solve more accepted tasks?
- Can it use fewer tokens?
- Can it require fewer verifier/CI iterations?
- Can it reuse previously accepted theorems, interfaces, pass evidence, and repairs?
- Does the marginal cost of accepted work fall as the knowledge base grows?
- Does assurance remain equal or stronger?

If yes, SAVEF becomes much more than an archive/index design: it becomes evidence that verified software knowledge can compound.

If no, the project should shrink or redirect SAVEF before building a large ecosystem around an unsupported self-amplification claim.
