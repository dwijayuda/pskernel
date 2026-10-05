# ProofScript Programming Language — Identity and Plans

**Status:** strategic identity and planning document — research revision v2; not a language specification and not implementation-conformance evidence.

**Repository role:** this document explains what ProofScript is trying to become, why it may deserve to exist, what product/adoption hypotheses are being explored, what must remain invariant, what remains undecided, and how the project should be evaluated.

**Current language context:** ProofScript language edition `ps-0.9-r3`; current compiler milestone PSC2 / `psc2-compiler-v1`; Lean-compatible checked semantics remain the foundation.

**Interpretation rule:** Identity, trust principles, and semantic boundaries describe the intended direction. Product names, frameworks, roadmap sequencing, adoption strategy, assurance levels, AI ecosystem-generation ideas, and target markets are research hypotheses that must change when evidence contradicts them.

**Exploration rule:** `ProofScript Forge`, `ProofScript App`, `ProofScript Bridge`, the assurance-level model, and the “verified ecosystem factory” concept are provisional research names/models. They are not adopted architecture or release commitments.

## Executive feasibility verdict

### Research conclusion

The **Verified Software Factory** idea is technically plausible **when defined as a staged, bounded system**, but the fully autonomous general-purpose version is not achievable with sufficient reliability today.

The strongest feasible near-term interpretation is:

> **An untrusted AI/orchestration layer that helps humans turn machine-readable specifications and selected existing software interfaces into ProofScript implementations, contracts, tests, proof obligations, checked proof artifacts, deployable packages, and explicit audit/provenance evidence—while PSC, Lean-assisted proof services, and PSKernel independently reject invalid candidates.**

This should be built **on top of the existing ProofScript semantic pipeline**, not as a second compiler or trusted subsystem.

The repo already contains important pieces of this architecture:

~~~text
source
→ ProofScript parser / Meta / Elab
→ pskernel admission
→ CheckedCore
→ erasure
→ VerifiedIR
→ backend
~~~

It also already has:

- replayable checked-admission module artifacts rather than “trust serialized proof” semantics;
- hash/dependency integrity metadata;
- a runtime-assurance report that explicitly marks runtime externals as assumptions and `proofEvidence:false`;
- a target-neutral `CheckedCore → Erasure → VerifiedIR` backend boundary;
- current/planned TypeScript, Rust, and WebAssembly backend lanes.

Therefore the highest-value next architecture is **evidence orchestration around these existing boundaries**, not replacement of them.

### Important claim boundary

Several distinct questions must never be collapsed into one “verified” badge:

~~~text
1. Is the specification the right specification?
2. Does the source implementation satisfy that specification?
3. Is the proof artifact sound?
4. Does compilation preserve the checked source meaning?
5. Do foreign dependencies satisfy their modeled contracts?
6. Was the final artifact built from the claimed source/tools?
~~~

ProofScript can make strong progress on all six, but they require different evidence.

### Feasibility by scope

| Scope | Current feasibility | Potential | Interpretation |
|---|---:|---:|---|
| Kernel-checked ProofScript packages | 9/10 | 9.5/10 | Core architecture is already aligned with this goal. |
| AI-assisted proof construction with independent checking | 7.5/10 | 9/10 | Demonstrated broadly in Lean research, but difficult proofs still need search/domain knowledge. |
| AI-assisted code + specification + proof co-generation | 6.5/10 | 9/10 | Active 2026 research shows strong progress; specification alignment remains hard. |
| Verified factory for parsers/codecs/protocol formats | 9/10 | 9.5/10 | Closest proven precedent; EverParse already demonstrates this class of factory. |
| Verified factory for deterministic pure libraries/state machines | 8/10 | 9/10 | Good fit for ProofScript's current semantics. |
| JS/npm incremental migration bridge | 7/10 | 8.5/10 | Architecturally plausible; boundary truth and debugging/tooling remain substantial work. |
| Audit/provenance/evidence bundles | 9/10 | 9.5/10 | Mature standards such as SLSA/in-toto can be reused. |
| End-to-end verified runtime artifact on every backend | 5/10 | 8.5/10 | Requires translation validation or semantic-preservation proofs below VerifiedIR. |
| General cross-platform application framework | 5.5/10 | 8/10 | Possible, but effect/runtime/interop breadth makes it a poor first factory target. |
| Autonomous repository-scale Verified Software Factory | 4.5/10 | 8/10 | Research systems solve meaningful subsets, but current agents still fail hard repositories. |
| “Exponential” autonomous ecosystem creation | 4/10 | 8/10 | Compounding reuse is plausible; exponential growth is unproven and should not be claimed. |

### Overall score

For the **bounded, human-supervised Verified Software Factory** described in this revision:

~~~text
Technical feasibility:        8.3 / 10
Architecture fit with repo:   9.0 / 10
Practicality of first MVP:    8.0 / 10
Auditability potential:       9.0 / 10
AI automation potential:      7.2 / 10
Adoption potential:           7.2 / 10
Implementation-scope ease:    5.8 / 10
Evidence maturity:            2.7 / 5
Overall research verdict:     PROMISING / BUILD BOUNDED EXPERIMENTS
~~~

For a **fully autonomous, general-purpose factory that generates and verifies arbitrary application ecosystems**:

~~~text
Current feasibility:          4.8 / 10
Potential long-term:          8.0 / 10
Current evidence maturity:    2.0 / 5
Verdict:                      RESEARCH VISION, NOT PRODUCT CLAIM
~~~

The project should deliberately preserve this distinction.


---

## Executive identity

### One-sentence identity

> **ProofScript is a Lean-grounded, gradually verified programming language and software-assurance platform intended to make ordinary programming, precise specification, machine-checked proof, and AI-assisted software construction parts of one coherent semantic system.**

### Short product thesis

> **AI may write the code. ProofScript should define what we are justified in trusting.**

### Mastery thesis

ProofScript began from a personal question:

> If someone were going to deeply master only one or two programming languages for the next decades, which languages would deserve that investment?

The project is an attempt to build one semantic system worth mastering deeply because programming, mathematical reasoning, specification, proof, and software assurance reinforce rather than fragment one another.

### Practical thesis

ProofScript should support a continuum:

~~~text
ordinary program
      ↓
strongly typed program
      ↓
specified program
      ↓
verified program
      ↓
checked deployable artifact
~~~

This is **gradual verification**, not gradual typing. Ordinary code should remain practical; stronger assurance should be added where its value justifies its cost.

---

# Part I — Why ProofScript may deserve to exist

## 1. Origin

Lean 4 demonstrates that programs, types, propositions, mathematics, and proofs can live in one rigorous semantic system. Dependent types can express relationships unavailable to conventional application type systems. Proof terms can be checked by a comparatively small trusted kernel. Powerful automation can construct proof candidates without itself becoming final proof authority.

The motivating question is:

> **What would a language grounded in those ideas look like if ordinary software development, interoperability, cross-platform deployment, auditability, and AI-assisted implementation were primary product concerns?**

ProofScript is an attempt to answer that question.

## 2. Problems being investigated

ProofScript exists to investigate several connected problems.

### 2.1 Programming and proof are fragmented

Mainstream development commonly separates:

~~~text
programming language
specification/documentation
tests
static analyzers
formal verifier/theorem prover
build/deployment
~~~

ProofScript asks whether ordinary programming, specification, and formal proof can share a practical language and artifact system without turning all programming into interactive theorem proving.

### 2.2 AI increases code production faster than trust

AI can reduce the cost of generating source code, tests, bindings, refactors, and proof attempts. It does not automatically reduce the cost of trusting them.

ProofScript's intended response is not “trust AI more.” It is:

~~~text
human intent/specification
        ↓
AI-generated candidates
        ↓
deterministic elaboration/checking
        ↓
explicit assumptions + checked evidence
        ↓
accepted artifact
~~~

AI should remain productive but outside the trusted correctness boundary.

### 2.3 Correctness-critical software lacks a mainstream gradual-verification path

There remains a large gap between ordinary static typing and full formal verification.

ProofScript's proposed bridge is:

~~~text
typed
→ specified
→ obligations
→ automation / AI proof attempts
→ checked verification
~~~

### 2.4 Deep mastery is fragmented

Developers often need different languages for application work, systems work, mathematics/proofs, scripting/data, plus framework-specific DSLs.

ProofScript does **not** try to merge every feature from those languages. It investigates whether one deep semantic foundation can support broad work through libraries, platforms, adapters, and carefully justified extensions.

## 3. Language-necessity test

ProofScript should continue as an independent language only if its value cannot be achieved just as effectively with Lean plus libraries/tooling, or with a verifier layered over an existing mainstream language.

Candidate reasons a distinct language may be justified:

1. one dependent semantic foundation for programs and propositions;
2. explicit checked proof artifacts;
3. gradual movement from programming to specification to verification;
4. application-oriented syntax and deterministic elaboration;
5. a closed/reproducible Standard environment;
6. explicit TCB and assumption boundaries;
7. portable semantics independent of host/backends;
8. an AI-oriented workflow where generated candidates can be checked rather than trusted.

If these advantages do not survive real implementation and user testing, ProofScript must be willing to narrow, pivot, or reconsider its independent-language identity.

---

# Part II — What ProofScript is and is not

## 4. What ProofScript is intended to be

ProofScript is intended to be:

- a practical programming language;
- a specification language;
- a proof-capable language;
- a gradually verified language;
- an AI-era software-assurance language;
- a cross-platform semantic language;
- potentially, later, a language for expressing/checking claims about foreign software artifacts.

## 5. What ProofScript is not intended to be

ProofScript is not intended to be:

- a union of Python + TypeScript + Rust + Go + Lean + C++;
- TypeScript with proof syntax bolted on;
- Lean with different punctuation only;
- full Lean source compatibility;
- a requirement to prove every function;
- a new VM + OS + browser + package universe all at once;
- a system where AI output is trusted because it is AI output;
- a system where backends redefine source semantics;
- a project where specification completeness substitutes for real implementation evidence.

## 6. The mastery promise

A language worth mastering should emphasize concepts with long half-lives:

- functions and compositional abstraction;
- algebraic/dependent data;
- type theory;
- propositions and proofs;
- contracts and invariants;
- explicit assumptions and trust;
- effects/resources;
- state models;
- modular software architecture;
- interoperability boundaries;
- machine-checked correctness.

This argues for **fewer, deeper mechanisms**, not endless feature accumulation.

---

# Part III — Core theses and falsification

## 7. Programming and proof should not require separate semantic worlds

ProofScript should make programs, propositions, specifications, and proofs coexist in one environment.

**Falsification:** if representative programs routinely need duplicated models or a separate proof language solely to verify ordinary ProofScript code, this thesis fails.

## 8. Verification should be gradual

ProofScript should support:

~~~text
typed → specified → verified
~~~

without requiring different languages, package systems, or deployment paths.

**Falsification:** if adding specifications/proofs routinely requires major rewrites, gradual verification has failed.

## 9. AI should increase verification leverage, not TCB size

AI may generate implementation, tests, contracts, migrations, and proof attempts. Final correctness should depend on explicit checking and assumptions rather than model confidence.

**Falsification:** if meaningful assurance routinely depends on opaque AI judgments that cannot be reduced to checked evidence, this thesis fails.

## 10. One semantic foundation should target multiple platforms

Candidate architecture:

~~~text
ProofScript source
       ↓
checked semantic representation
       ↓
executable lowering
       ↓
JS / WASM / native / other
~~~

A backend must implement ProofScript meaning rather than define it.

**Falsification:** if backend exceptions become so numerous that ProofScript means different languages per target, this thesis fails.

## 11. Interoperability should beat ecosystem reinvention

Existing ecosystems are assets. ProofScript should reuse mature libraries, protocols, runtimes, and deployment paths where this does not compromise semantics/trust.

**Falsification:** if useful adoption requires rebuilding a large ecosystem before users can build real software, this strategy fails.

## 12. Rich tooling can coexist with a small trusted boundary

Intended trust shape:

~~~text
large productive/untrusted layer
────────────────────────────────
AI
proof automation
frontend
IDE
optimizers
generators
foreign adapters
backend compilers where possible
────────────────────────────────
small explicit trust boundary
────────────────────────────────
checked terms/artifacts
kernel/checker
explicit axioms/assumptions
~~~

---

# Part IV — Design philosophy

## 13. Semantic economy

Prefer:

~~~text
small semantic vocabulary
× high compositional power
× strong libraries
× excellent interoperability
~~~

over special-purpose syntax for every domain.

## 14. Feature ownership order

Prefer:

~~~text
ordinary library
    before
new core syntax

proof-producing prover/library
    before
kernel growth

stable semantic model
    before
convenience syntax

controlled extension
    before
open Standard grammar

platform adapter/generated binding
    before
importing foreign semantics into ProofScript
~~~

## 15. Feature-change test

Every major language feature should answer:

1. what important recurring problem does it solve?
2. who has that problem?
3. what are current workarounds?
4. why is a library/tool/extension insufficient?
5. what permanent complexity does it add?
6. what prior art exists?
7. how does it affect tooling and compatibility?
8. how will it be exercised in real programs?
9. what experiment could falsify the proposal?

## 16. Fail closed

Unsupported syntax, elaboration, proof state, foreign type, backend capability, or assurance claim must reject explicitly rather than silently acquiring host semantics.

## 17. Real programs outrank speculative elegance

After semantic coherence is established, future changes should be driven primarily by representative applications and measured friction.

---

# Part V — Product architecture

## 18. Product stack

ProofScript should be treated as a product stack, not only a parser/compiler.

### Layer 1 — semantic foundation

- core terms/types;
- propositions/proofs;
- definitional equality;
- inductives/recursors;
- explicit assumptions;
- small trusted checking boundary.

### Layer 2 — Standard language

- application-oriented syntax;
- deterministic elaboration;
- module/name model;
- structures/functions/classes/instances/patterns;
- gradual-verification surface;
- stable Standard environment.

### Layer 3 — verification/proof services

- contracts and obligations;
- automated proof search;
- AI-assisted proof construction;
- safe/certificate-backed external automation where appropriate;
- proof diagnostics;
- verification-state reporting.

### Layer 4 — executable IR/backend boundary

- preserve checked semantics;
- distinguish proof-relevant/executable material;
- representation-independent lowering contracts;
- explicit backend assumptions.

### Layer 5 — platform profiles

Candidates include:

- JavaScript/npm / Node/Web;
- WebAssembly;
- native/server;
- scientific/HPC;
- later systems/embedded if justified.

### Layer 6 — developer product

Eventually:

- toolchain installation;
- build/run/test/check;
- packages/dependencies;
- formatter;
- LSP;
- debugger/source maps;
- profiler path;
- docs;
- publication;
- reproducible artifacts.

### Layer 7 — AI development experience

- machine-readable specification data;
- structured diagnostics;
- synthesis hooks;
- proof-obligation extraction;
- repair loops;
- provenance of assumptions/evidence.

The AI provider must remain replaceable.

### Layer 8 — foreign verification

Longer term:

~~~text
foreign artifact
    ↓
explicit model/translation
    ↓
ProofScript proposition
    ↓
proof/certificate
    ↓
checker
~~~

This should not block the first production language.

---

# Part VI — Verified Software Factory feasibility and architecture

## 19. Why a factory is plausible

A Verified Software Factory is not one invention. It composes mechanisms that already exist independently:

1. **proof-oriented programming and small checked kernels** — Lean and other proof assistants;
2. **verification-condition generation** — Dafny/Boogie and increasingly Lean's own `vcgen` work;
3. **verified domain generators** — EverParse generates verified parsers/formatters from format specifications;
4. **verified libraries** — Project Everest/HACL* demonstrates verified cryptographic/protocol software compiled to mainstream targets;
5. **verified compilation** — CompCert and CakeML demonstrate semantic-preservation proofs and verified/self-hosted compiler pipelines;
6. **AI theorem proving** — LeanDojo, DeepSeek-Prover and related systems show increasingly strong machine-generated Lean proofs;
7. **joint code/spec/proof generation** — BRIDGE, P³, Vero, and related 2026 work show that verified-code generation is becoming a real research discipline;
8. **software provenance** — SLSA and in-toto already provide mature models for inspectable build provenance and attestations.

The ProofScript opportunity is to integrate these ideas into one application-programming product around PSC + PSKernel, with AI outside the TCB and with foreign/runtime assumptions explicitly represented.

## 20. What research says is achievable

### 20.1 Bounded verified generators are already practical

EverParse is the strongest direct precedent for the “factory” concept. It generates verified parsers and formatters from structured format specifications, including mainstream-target outputs.

This strongly suggests the first ProofScript factory should target domains with:

- machine-readable input specifications;
- clear mathematical semantics;
- local/pure transformations;
- natural round-trip/safety properties;
- high reuse value;
- limited ambient effects.

Best first candidates:

1. binary/text parsers and codecs;
2. schema validators and serializers;
3. protocol-message formats;
4. deterministic state machines;
5. bounded financial/accounting logic.

### 20.2 AI proof generation is useful but incomplete

LeanDojo provides an end-to-end environment for agents to inspect proof states, retrieve premises, submit tactics, and learn from Lean repositories. DeepSeek-Prover-V2 reports strong formal-theorem benchmark performance.

This makes AI proof attempts a credible product component.

It does **not** justify trusting the model. Every accepted proof must still be checked.

### 20.3 Joint code/spec/proof generation is now credible research

BRIDGE explicitly studies keeping Code, Specification, and Theorem/Proof artifacts aligned. P³ reports that joint program-and-proof planning improves verified-code generation relative to sequential implementation-then-proof workflows.

This directly supports a Forge architecture where code and proof are planned together rather than treating proof as post-hoc repair.

### 20.4 Repository-scale autonomous synthesis is not solved

Vero's 2026 repository-level benchmark shows meaningful multi-module progress but also demonstrates that the hardest repositories remain unsolved.

Therefore ProofScript must not plan around “AI autonomously builds arbitrary verified packages” as a current capability.

### 20.5 Specification generation is the likely bottleneck

Recent specification-generation research finds that writing/evaluating correct formal specifications remains difficult. A machine-checkable proof can still establish a weak or wrong claim.

Therefore the human role in the first Factory should center on:

- accepting/rejecting proposed specifications;
- confirming threat models;
- reviewing foreign assumptions;
- defining observable behavior;
- selecting properties worth proving.

The optimization target is not “zero humans.” It is **less human effort per trustworthy capability**.

## 21. Recommended architecture

### 21.1 Forge is outside the TCB

~~~text
                 Human intent / imported artifact
                              │
                              ▼
                    Forge planner / agents
                         (untrusted)
                              │
             ┌────────────────┼────────────────┐
             ▼                ▼                ▼
          code model      specifications     tests/oracles
             │                │                │
             └────────────────┼────────────────┘
                              ▼
                      ProofScript source
                              │
                              ▼
                    PSC parser / Meta / Elab
                         (untrusted)
                              │
                              ▼
                      pskernel admission
                              │
                              ▼
                         CheckedCore
                       /             \
                      /               \
          proof/spec evidence          erasure
                    │                    │
                    ▼                    ▼
               PSKernel replay        VerifiedIR
                    │                    │
                    ▼                    ▼
              Evidence Graph           backend
                                         │
                                         ▼
                                  runtime artifact
~~~

Nothing generated by Forge becomes trusted merely because Forge generated it.

### 21.2 Lean 4 as prover/oracle service, not final product TCB

ProofScript should exploit Lean's proof ecosystem without making the whole Lean frontend/runtime the final ProofScript trust boundary.

Two lanes are plausible.

#### Lane A — ProofScript-native

~~~text
ProofScript theorem/contract
→ PSC tactic/elaboration
→ kernel term/admission
→ PSKernel replay
~~~

#### Lane B — Lean-assisted bootstrap/research

~~~text
ProofScript obligation
→ canonical Lean-compatible theorem
→ Lean tactics / vcgen / AI prover
→ exported checked term/admission
→ PSKernel replay
~~~

This lets ProofScript benefit from Lean automation and AI research immediately.

Lean 4.35's intrinsic `requires`/`ensures`/loop-invariant/`vcgen` work is relevant prior art, but ProofScript is currently pinned to Lean 4.34.0. No later Lean feature should silently enter ProofScript semantics.

### 21.3 PSC remains the source/product compiler

PSC should own:

- ProofScript syntax;
- deterministic elaboration;
- contract/obligation extraction;
- source/profile identities;
- checked-admission production;
- project/module integration;
- erasure;
- target-neutral executable IR;
- backend orchestration.

Forge should call PSC rather than reimplementing these semantics.

### 21.4 PSKernel remains final logical admission authority

PSKernel should remain narrow:

- validate declarations/proofs;
- reject unresolved/malformed kernel state;
- replay serialized checked admissions;
- expose deterministic evidence identities;
- remain independent of AI, IDE, package generators, and backend code generation.

For hostile/high-value AI-generated submissions, study Lean's comparator/external-checker threat model: generation and final checking should be separated whenever practical.

### 21.5 Reuse CheckedCore and replayable module artifacts

The repo already uses CheckedCore as the post-admission semantic handoff and module artifacts whose declarations are replayed rather than trusted.

A Factory package can therefore contain:

~~~text
source/
checked modules/
contracts/
proof artifacts/
tests/
runtime outputs/
evidence manifest/
provenance attestations/
SBOM/
~~~

### 21.6 VerifiedIR is not automatically runtime proof

The name `VerifiedIR` must not be interpreted as “every emitted backend artifact is formally proved semantics-preserving.”

Recommended compiler-assurance progression:

#### C0 — checked source only
Theorems about source semantics are kernel checked. Runtime output is not included in the theorem claim.

#### C1 — checked source + backend conformance evidence
Reference execution, property tests, differential testing, cross-backend checks.

#### C2 — per-build translation validation
A validator establishes a relation between a specific VerifiedIR input and emitted target artifact.

#### C3 — proved transformation passes
Prove selected erasure/optimization/lowering passes semantics-preserving.

#### C4 — end-to-end verified target path
CompCert/CakeML-style theorem connecting checked source semantics to executable target semantics.

Forge MVP should **not** wait for C4.

### 21.7 Prefer an Evidence Graph over a single assurance level

The provisional `PS-A0 ... PS-A6` model is intuitive but can hide orthogonal trust dimensions.

Internally use a typed Evidence Graph.

Each claim records:

~~~text
claim_id
statement/digest
subject artifact
evidence kind
producer/tool identity
tool/version/profile
input hashes
dependencies
assumptions
status
replay/verification command
~~~

Evidence kinds can include:

~~~text
kernel-proof
kernel-admission
translation-validation
property-test
differential-test
fuzz-campaign
foreign-assumption
runtime-conformance
build-provenance
dependency-integrity
SBOM
human-spec-approval
~~~

A future user-facing assurance badge may summarize the graph, but the graph remains inspectable.

### 21.8 Reuse SLSA/in-toto/SPDX

Do not invent the entire supply-chain evidence model.

Candidate package layout:

~~~text
package/
  runtime artifacts
  .d.ts / foreign interfaces
  .psmodule checked artifacts
  proofscript-evidence.json
  provenance.intoto.jsonl
  sbom.spdx.json
~~~

A ProofScript-specific attestation predicate can connect source/profile/compiler/kernel/evidence identities while SLSA/in-toto handle general build provenance.

## 22. Recommended first Factory vertical

### 22.1 First choice: parser / codec / schema factory

This is the highest-feasibility killer-product experiment.

~~~text
schema / protocol description
        ↓
Forge
        ↓
ProofScript model/parser/serializer
+ contracts
+ round-trip theorem
+ bounds/safety properties
+ fuzz/differential tests
        ↓
PSC + Lean-assisted proofs
        ↓
PSKernel checked evidence
        ↓
JS/WASM package + .d.ts + audit bundle
~~~

Why:

- strong precedent in EverParse;
- meaningful specifications are comparatively clear;
- natural reusable theorem libraries;
- small effect surface;
- security relevance;
- package-friendly;
- cross-platform;
- AI can generate repetitive code/proof scaffolding;
- runtime differential testing is tractable.

Candidate properties:

~~~text
decode(encode(x)) = x
accepted bytes imply valid AST/schema
serializer emits canonical representation
bounds/index safety
length invariants
deterministic parsing
malformed encoding rejection
~~~

### 22.2 Second choice: OpenAPI / SDK factory

Generate:

- native ProofScript model;
- adapters;
- serializers/validators;
- typed errors;
- JS/TS API;
- contracts for deterministic local behavior;
- explicit assumptions for remote-server behavior.

Excellent Bridge research, but weaker end-to-end proof because server behavior is external.

### 22.3 Third choice: deterministic state machines / financial logic

Strong candidate properties:

- valid transitions;
- conservation equations;
- invariant preservation;
- authorization rules;
- impossible-state elimination.

### 22.4 Do not start with a full UI/application framework

A Flutter-like framework places effects/platform/UI breadth before ProofScript demonstrates its unique assurance advantage.

`ProofScript App` should remain later research after Forge/Bridge/library evidence.

## 23. AI workflow

### 23.1 Generate program and proof together

Prefer:

~~~text
formalize intent
→ joint code/proof plan
→ implementation + proof scaffold
→ checker feedback
→ repair
~~~

over:

~~~text
generate implementation
→ later attempt proof
~~~

### 23.2 Human approval boundary

The first practical Factory should require human confirmation of:

- public API;
- high-level specification;
- threat model;
- environmental assumptions;
- important invariants;
- assurance target.

AI may propose these, but proposal is not approval.

### 23.3 Agent loop

~~~text
1. ingest artifact/spec
2. construct normalized interface/model
3. propose specifications
4. human/policy approval gate
5. jointly plan implementation + proof
6. generate ProofScript source
7. PSC parse/elaborate
8. generate verification conditions/theorems
9. run ProofScript/Lean automation
10. PSKernel replay
11. run tests/fuzz/differential checks
12. classify unresolved assumptions/obligations
13. repair
14. package runtime + evidence + provenance
~~~

### 23.4 AI provider independence

AI models are interchangeable optimization components, never semantic dependencies.

## 24. Bridge architecture

Do not translate arbitrary foreign semantics into ProofScript as if they were proved.

Classify imports:

~~~text
native-representable
validated wrapper
runtime adapter
opaque handle
explicit assumption
unsupported
~~~

For JS/TS:

~~~text
npm/.d.ts
→ InterfaceIR-like normalization
→ generated ProofScript facade
→ explicit foreign assumptions
→ runtime conformance/differential tests
~~~

Migration:

~~~text
existing app
→ one high-value ProofScript component
→ ordinary published runtime artifact
→ expand only if value is demonstrated
~~~

## 25. Candidate ProofScript App framework

Keep as research.

A possible application layer may expose:

~~~text
App caps err result
Fiber caps err result
Exit err result
RuntimeFault
Resource caps err value
Stream caps err item
~~~

but the verification/ecosystem-factory thesis should be demonstrated before a large framework becomes a major investment.

## 26. Product sequencing

| Hypothesis | First product | Feasibility | Main risk |
|---|---|---:|---|
| **Verified-library-first** | parser/codec packages | **9/10** | may appear narrow |
| **Forge + parser vertical** | bounded factory | **8.5/10** | spec/proof UX |
| **Bridge-first** | TS/npm migration | **7.5/10** | weaker differentiation |
| **Hybrid Forge + Bridge + one vertical** | factory + npm output | **8/10** | coordination complexity |
| **Framework-first** | ProofScript App | **5.5/10** | scope explosion |
| **General autonomous factory** | arbitrary packages/apps | **4.5/10** | current AI/spec limits |

### Recommended experiment order

~~~text
verified parser/codec libraries
        ↓
small Forge around that vertical
        ↓
publish through JS/npm Bridge
        ↓
measure human trust cost and reuse
        ↓
generalize Forge only if evidence supports it
        ↓
research App/framework after platform pain is understood
~~~

This is an experimental recommendation, not permanent architecture.

# Part VII — Adoption architecture

## 27. Primary adoption hypothesis

ProofScript should avoid ecosystem cold start.

Candidate architecture:

> **unique assurance capability + incremental component adoption + strong interoperability with an incumbent ecosystem.**

JavaScript/npm remains a leading first bridge hypothesis because a verified ProofScript component could potentially be published for ordinary consumers without requiring an entire application rewrite.

This remains unproven.

## 28. Target-user candidates

Early candidates:

1. security-sensitive library authors;
2. parser/protocol/serialization authors;
3. financial/authorization logic developers;
4. compiler/tooling/package-security developers;
5. SDK authors;
6. scientific developers with meaningful invariants;
7. teams using AI generation in correctness-sensitive modules.

Lower initial priority:

- ordinary UI/CRUD where assurance value is low;
- framework-heavy domains requiring extensive unsupported host-specific behavior.

## 29. Minimum compelling program

A strong first benchmark remains:

> **A non-trivial correctness-sensitive package written primarily in ProofScript, with specified/verified core behavior, published as an ordinary consumable runtime package and foreign-language interface, requiring no ProofScript tooling for ordinary consumption.**

Candidate verticals:

- binary codec/parser;
- protocol parser;
- authorization evaluator;
- deterministic financial/state machine;
- schema validator;
- OpenAPI/SDK generation;
- package/security component.

## 30. Migration-to-verification hypothesis

Desired adoption shape:

~~~text
existing project
      ↓
one correctness-sensitive ProofScript module
      ↓
ordinary runtime artifact + foreign interface
      ↓
more modules only if value is demonstrated
~~~

For JS/TS experiments, candidate outputs include:

~~~text
JS/WASM runtime artifact
.d.ts interface
proof/certificate artifacts
audit/provenance manifest
~~~

Research questions:

- can one module migrate without changing the rest of deployment?
- can JS/TS consumers use outputs naturally?
- can foreign assumptions remain bounded/visible?
- can debugging across the boundary remain practical?
- is audit evidence useful to human reviewers?

---

# Part VIII — Evidence-gated plan

## 31. Planning rule

Plans should be **evidence-gated**, not date-gated.

## 32. Stage 0 — identity/specification coherence

Required evidence:

- authoritative language reference;
- explicit language vs compiler milestone identity;
- trust/TCB boundary;
- profile/environment identity;
- conformance obligations;
- explicit exclusions;
- Identity/Plans reviewed against actual specification.

## 33. Stage 1 — mechanical conformance

Required evidence:

- parser conformance;
- elaboration conformance;
- typeclass/coercion conformance;
- tactic/proof conformance;
- checked-artifact replay;
- environment reproducibility;
- adversarial negative tests;
- no silent semantic fallback.

Do not expand yet into many backends/frameworks.

## 34. Stage 2 — minimum compelling developer product

Required:

- one-command install;
- create/build/run/test/check;
- useful diagnostics;
- formatter;
- basic LSP;
- package workflow;
- reproducibility;
- debugging path;
- documentation;
- one **exploratory adoption-product prototype** selected to falsify Forge-first, Bridge-first, framework-first, verified-library-first, or hybrid hypotheses.

Required workloads:

- library;
- CLI;
- multi-module project;
- parser/codec or similar correctness-sensitive component.

## 35. Stage 3 — gradual-verification product proof

For multiple representative components measure:

- implementation LOC;
- specification LOC;
- proof/evidence LOC;
- automatic discharge rate;
- verification latency;
- proof maintenance after refactors;
- bugs/invalid states found;
- unresolved assumptions;
- non-expert human time;
- effect of AI assistance.

Also run a bounded Forge-like experiment where AI proposes:

- specification;
- implementation;
- tests;
- proof attempts.

Measure where human effort actually concentrates.

A Forge-like architecture should advance only if it reduces trust/review cost, not merely generated LOC.

## 36. Stage 4 — first ecosystem bridge

Test the provisional Bridge hypothesis.

For JS/npm:

- consume representative npm packages;
- generate/consume TypeScript declarations;
- publish a ProofScript-authored package;
- consume from ordinary JS/TS;
- preserve source maps/debugging;
- handle callbacks/errors/async/resources/foreign objects;
- make `null`/`undefined`/structural objects/overloads/dynamic values explicit;
- no silent `any` fallback.

## 37. Stage 5 — AI-assisted assurance and ecosystem-generation research

Compare:

- human-only vs AI-assisted implementation;
- human-authored vs AI-proposed specifications;
- proof generation and repair;
- refactoring;
- foreign binding generation;
- building a package before and after reusable checked libraries/theorems exist;
- native package creation vs foreign migration.

This stage should accept, revise, or reject the Forge hypothesis.

## 38. Stage 6 — cross-platform expansion

Only after one platform path is excellent should additional backends expand deliberately.

Every backend must preserve the same source semantics.

## 39. Stage 7 — foreign software verification

Research only after ProofScript's own programming/verification loop is stable.

## 40. Stage 8 — ecosystem/institutional durability

Required eventually:

- proposal process;
- compatibility policy;
- release cadence;
- security process;
- multiple maintainers;
- reproducible builds;
- package stewardship;
- independent checker/replay path where practical.

---

# Part IX — Major risks

## 41. ProofScript may be only “Lean with different syntax”

Countermeasure: demonstrate application ergonomics, gradual verification, deployment, and AI workflow that are materially distinct.

Pivot if the benefits can be delivered more cheaply as Lean libraries/tooling.

## 42. Custom elaboration may become an expensive semantic fork

Countermeasure: minimize divergence from Lean where reproducibility/product goals do not require it; test parity relentlessly.

## 43. Verification may cost too much

If routine useful properties require expert theorem proving, narrow the target wedge or improve automation before broad claims.

## 44. Ecosystem bootstrap may overwhelm the project

Prioritize interoperability, generated bindings, and a small number of high-value native packages.

## 45. Multi-platform ambition may fragment semantics

One excellent platform path before broad backend expansion.

## 46. Specification may advance faster than evidence

Freeze speculative semantic redesign and let real programs drive future changes.

## 47. TCB may expand silently

Maintain a formal TCB inventory. Every feature proposal must state TCB impact.

## 48. AI-generated ecosystem may create false confidence

A foundry could generate huge amounts of typed/verified code while relying on wrong specifications, hidden assumptions, or invalid foreign models.

Countermeasures:

- first-class spec/assumption review;
- logical proof separated from environmental validation;
- machine-readable trust inventory;
- property/differential/fuzz testing at boundaries;
- measure human trust cost rather than generated LOC;
- maintainability/refactoring studies;
- no generic “verified” label hiding mixed assurance.

**Pivot:** if generation increases code volume but does not reduce human review/maintenance cost or defect risk, narrow/reject the ecosystem-factory hypothesis.

## 49. Founder/project sustainability

Move from single-owner knowledge toward documented architecture, reproducibility, proposal records, independent tests, modular maintainership, and external review.

---

# Part X — Success metrics

## 50. Developer-product metrics

Track:

- install time;
- clean/incremental build latency;
- IDE latency;
- diagnostic usefulness;
- package add/update time;
- debugging/source-map usability;
- reproducible-build success;
- onboarding time.

## 51. Verification metrics

Track:

- ordinary vs specified vs verified code share;
- specification/implementation ratio;
- proof/evidence/implementation ratio;
- automatic discharge rate;
- median/p95 verification latency;
- proof breakage after refactors;
- bugs/invariants caught;
- explicit assumption count;
- trusted dependency count.

## 52. Interoperability metrics

Track:

- representative packages usable without handwritten bindings;
- binding generation success;
- unsupported foreign-shape rate;
- adapter overhead;
- generated API quality;
- source-map fidelity;
- publish/consume round-trip success.

## 53. Adoption metrics

Track:

- time to first useful program;
- users reaching first deployed component;
- retention;
- independent projects;
- external contributors;
- package reuse;
- migration/escape cost;
- projects using ProofScript for one component without a rewrite.

## 54. AI/foundry metrics

Track:

- AI implementation acceptance rate;
- AI proof acceptance rate;
- repair iterations;
- invalid proposals caught;
- human review time;
- provider/model dependence;
- reproducibility;
- **human minutes per trusted capability**;
- human minutes per reviewed specification;
- generated assurance claims requiring correction;
- marginal human effort for package N vs earlier packages;
- reuse rate of verified theorems/contracts/components;
- meaningful checked properties per human engineering hour;
- percentage of behavior depending on foreign/unverified assumptions.

**Generated LOC is not a success metric by itself.**

---

# Part XI — Independent evaluation framework

## 55. Scoring rule

Score every criterion with:

- **Current quality:** 0–5;
- **Potential quality:** 0–5;
- **Evidence confidence:** 0–5.

Evidence confidence:

| Score | Evidence |
|---:|---|
| 0 | aspiration only |
| 1 | specification/design |
| 2 | working prototype |
| 3 | representative real applications |
| 4 | production deployments |
| 5 | multi-year/multi-organization evidence |

Do not allow potential to masquerade as current quality.

## 56. Weighted 100-point score

| Criterion | Weight |
|---|---:|
| Problem–solution fit | 13 |
| Differentiated wedge / language necessity | 7 |
| Semantic architecture | 10 |
| Practical usefulness / ergonomics | 9 |
| Performance / resource economics | 6 |
| Safety / correctness / TCB | 7 |
| Implementation feasibility | 6 |
| Developer product / tooling | 9 |
| Adoption / migration / interoperability | 12 |
| Ecosystem / distribution | 7 |
| Compatibility / evolution | 5 |
| Governance / sustainability | 3 |
| Future relevance | 4 |
| Novelty / defensibility | 2 |
| **Total** | **100** |

## 57. Hard gates

Weighted scores cannot hide failures in:

- **G0 Language necessity** — should this really be a new language?
- **G1 Trust/soundness** — are correctness claims and TCB credible?
- **G2 Implementability** — can the architecture be maintained?
- **G3 Minimum compelling workload** — is there a real workload where ProofScript clearly wins?
- **G4 Incremental adoption** — can users get value without rewriting everything?
- **G5 Verification economics** — is gradual verification usable?
- **G6 Developer product** — does the whole workflow work?
- **G7 Institutional durability** — can the project survive beyond one founder?

## 58. Overall interpretation

A high specification score with low evidence confidence is still a research project.

A high semantic score with poor migration/tooling/ecosystem is not an adoption-ready language.

A killer product hypothesis should be evaluated on switching value, not enthusiasm.

---

# Part XII — Research basis

## 59. TypeScript

Published TypeScript design goals emphasize preserving JavaScript runtime behavior, emitting recognizable JavaScript, cross-platform development, composability, and avoiding substantial breaking changes.

**Lesson:** minimize what users must abandon to obtain the new benefit. Migration/adoption architecture may be as important as the intrinsic type system.

References:

- https://github.com/microsoft/TypeScript-wiki/blob/main/TypeScript-Design-Goals.md
- https://github.com/microsoft/typescript/wiki/writing-good-design-proposals

## 60. Kotlin

Kotlin explicitly emphasizes bidirectional Java interoperability and gradual introduction into existing projects.

**Lesson:** interoperability is adoption architecture, not merely a compiler feature.

References:

- https://kotlinlang.org/docs/java-interop.html
- https://kotlinlang.org/docs/mixing-java-kotlin-intellij.html
- https://kotlinlang.org/docs/faq.html

## 61. Dart/Flutter

Dart's current multiplatform application story is strongly associated with Flutter, which offers one codebase across multiple deployment platforms.

**Lesson:** a language may need a concrete product/framework that makes choosing the language obviously worthwhile. ProofScript should research a flagship product, but should not assume the answer is a UI framework.

References:

- https://dart.dev/multiplatform-apps
- https://docs.flutter.dev/platform-integration

## 62. Lean

Lean's strongest architectural lesson is a small trusted proof-checking foundation beneath powerful elaboration and automation.

**Lesson:** rich automation can remain productive without automatically becoming proof authority.

Reference:

- https://lean-lang.org/doc/reference/latest/

## 63. Adoption research

Empirical programming-language adoption research has found that libraries, existing code, and developer experience strongly influence language choice, while intrinsic language properties alone are insufficient.

**Lesson:** ecosystem leverage, existing-code reuse, migration cost, and product quality must be weighted alongside semantic sophistication.

Reference:

- https://doi.org/10.1145/2544173.2509515

---

# Part XIII — Strategic decisions

## 64. Currently favored

1. ProofScript is the language; PSC2 is an implementation milestone.
2. Lean-compatible checked semantics are the foundation.
3. Gradual verification + explicit trust are stronger differentiators than TypeScript feature parity.
4. AI produces candidates; it is not proof authority.
5. Initial adoption should be component-level and interoperable.
6. One excellent platform path should precede broad backend expansion.
7. Libraries/adapters/extensions should absorb most breadth before core language growth.
8. TCB must remain inventoried/auditable.
9. Real applications should dominate future evolution.
10. ProofScript may remain a valuable niche language if evidence points there.
11. A killer adoption product should be researched, but no Forge/App/Bridge architecture is adopted yet.
12. AI ecosystem scale must be judged by trust/review/maintenance/reuse economics, not generated code volume.

13. Forge/Factory work should reuse PSC → PSKernel → CheckedCore rather than create a second semantic compiler.
14. Lean should initially be exploited as a proof/oracle/VC-generation ecosystem while PSKernel remains the independent ProofScript admission authority.
15. The first Factory vertical should favor parser/codec/schema-style deterministic software rather than a full application/UI framework.
16. Runtime assurance must distinguish source proof validity from backend semantic preservation and foreign-environment truth.
17. An inspectable Evidence Graph is preferred internally over a single linear “verified” level.
18. Provenance should reuse SLSA/in-toto/SPDX-compatible formats rather than invent an isolated ProofScript-only supply-chain system.
19. `VerifiedIR` is a critical target-neutral boundary, but its name alone must not be treated as proof that every backend output is semantics-preserving.
20. General autonomous repository-scale verified synthesis remains a research objective, not an adoption claim.

## 65. Intentionally open

- permanent primary platform;
- exact degree of custom elaboration divergence from Lean;
- application effect/concurrency model;
- imperative-looking syntax;
- SMT-backed verification role;
- public executable IR;
- foreign-language verification breadth;
- systems ownership/resource model;
- governance;
- whether Forge should exist;
- whether ProofScript App is necessary;
- whether Bridge should be the first product;
- whether assurance levels are useful enough to standardize;
- whether AI ecosystem creation produces real compounding leverage;
- which first vertical best demonstrates switching value.

---

# Part XIV — Research program for the killer-product hypothesis

## 66. Candidate experiments

1. **Verified codec/parser vertical** — round-trip/bounds/schema properties.
2. **OpenAPI/SDK vertical** — generate API model, adapters, contracts, tests, publishable JS/TS artifacts.
3. **Financial/state-machine vertical** — explicit invariants/transitions.
4. **Application-framework slice** — one CLI + one HTTP service using candidate application semantics.
5. **Incremental migration slice** — migrate one correctness-sensitive TS module while leaving the surrounding project intact.

## 67. Compare using

- time to first useful artifact;
- human minutes per trusted capability;
- specification-review burden;
- automatic proof-discharge rate;
- foreign assumption severity;
- incumbent ecosystem usability;
- debug/source-map friction;
- maintainability after AI refactoring;
- marginal effort as reusable ProofScript components accumulate;
- whether users would choose the product even without theorem-proving interest.

## 68. Decision rule

No single experiment establishes permanent product direction.

Prefer the smallest architecture that repeatedly demonstrates a meaningful advantage over incumbent workflows.

If no candidate produces enough switching value, keep ProofScript focused on narrower verified-library or verification-tool niches instead of expanding scope.

---

# Part XV — Feasibility research evidence and scoring

## 69. Research evidence

### 69.1 Lean and independent checking

Lean's current reference describes a minimal kernel that checks proof terms produced by richer automation. Lean's proof-validation guidance distinguishes honest from potentially malicious proof submissions and recommends sandboxing plus kernel/external-checker replay for high-risk cases.

This supports:

~~~text
large AI/prover frontend
→ exported explicit evidence
→ independent PSKernel replay
~~~

It also argues for checker diversity and adversarial conformance testing.

Sources:

- https://lean-lang.org/doc/reference/latest/
- https://lean-lang.org/doc/reference/latest/ValidatingProofs/
- https://arena.lean-lang.org/
- https://lean-lang.org/doc/reference/latest/releases/v4.34.0/

### 69.2 Lean verification-condition generation

Lean 4.34/4.35 development includes substantial `vcgen` work around specifications, weakest-precondition reasoning, `requires`, `ensures`, assertions, and loop invariants.

This is important prior art for future ProofScript contracts/effect verification.

The newer intrinsic verification syntax is experimental and newer than ProofScript's Lean 4.34 semantic pin; study it, do not silently import it.

Sources:

- https://lean-lang.org/doc/api/Init/Tactics.html
- https://lean-lang.org/doc/reference/latest/Tactic-Proofs/Tactic-Reference
- https://lean-lang.org/doc/reference/latest/releases/v4.35.0/

### 69.3 AI theorem proving

LeanDojo demonstrates repository tracing, proof-state interaction, retrieval, and AI proof search. DeepSeek-Prover-V2 reports strong benchmark performance.

Sources:

- https://leandojo.org/leandojo.html
- https://arxiv.org/abs/2306.15626
- https://arxiv.org/abs/2504.21801

### 69.4 AI verified-code generation

**BRIDGE** coordinates Code, Specification, and Theorem/Proof artifacts.

**P³** reports benefits from joint program-and-proof planning.

**Vero** evaluates repository-scale verified software generation and shows substantial progress while also showing current agents fail the hardest multi-module cases.

Recent specification-generation work reinforces that specification quality remains a major bottleneck.

Sources:

- https://leandojo.org/bridge.html
- https://arxiv.org/abs/2608.09277
- https://arxiv.org/abs/2608.13522
- https://arxiv.org/abs/2608.13077

### 69.5 AI + Lean software example

A 2026 Lean FRO presentation reports an AI conversion of zlib to Lean that passed its test suite and proved a compression/decompression theorem.

Promising evidence, not proof that arbitrary repositories can already be automatically migrated and fully verified.

Source:

- https://lean-lang.org/presentations/20260604_DFMD/

### 69.6 Bounded verified software factories

EverParse is direct evidence that domain-specific verified generation is practical. Project Everest/HACL* shows verified crypto/protocol components compiled to mainstream low-level targets.

Sources:

- https://project-everest.github.io/everparse/
- https://project-everest.github.io/
- https://fstar-lang.org/

### 69.7 Compiler assurance

CompCert proves semantic preservation across a realistic compiler. CakeML combines a formal language, verified compiler backend, self-hosting, and verified applications.

These show stronger backend guarantees are achievable but expensive, which is why they should not block Forge MVP.

Sources:

- https://compcert.org/
- https://compcert.org/research.html
- https://cakeml.org/

### 69.8 Provenance

SLSA and in-toto provide mature provenance/attestation concepts. ProofScript should extend these standards with proof/evidence identities instead of replacing them.

Sources:

- https://slsa.dev/spec/v1.2/
- https://slsa.dev/spec/v1.2/provenance
- https://in-toto.io/docs/

## 70. Fit with current pskernel architecture

Current reusable pipeline:

~~~text
.ps / bounded .lean
→ syntax
→ Meta / Elab
→ pskernel admission
→ @proofscript/checked-core
→ @proofscript/erasure
→ @proofscript/compiler-ir
→ backend
~~~

Existing useful pieces include:

- replayable checked-admission module artifacts;
- content/dependency hashes;
- explicit runtime external assumptions;
- `proofAuthority:'pskernel'` in assurance reporting;
- runtime externals explicitly marked `proofEvidence:false`;
- target-neutral compiler IR;
- TypeScript backend plus Rust/Wasm architecture lanes;
- self-host/fixed-point work.

### Required new outer components

Forge primarily needs outer layers, not a new kernel/compiler:

~~~text
@proofscript/evidence
@proofscript/spec
@proofscript/forge-core
@proofscript/forge-agent
@proofscript/bridge-interface-ir   (or existing equivalent)
@proofscript/provenance
@proofscript/translation-validate
psc forge
~~~

Names are provisional.

### Responsibility/trust split

| Component | Responsibility | Trust role |
|---|---|---|
| PSC parser/Meta/Elab | source meaning, obligation construction | untrusted; output rechecked |
| Lean prover service | tactics/vcgen experiments/AI environment | untrusted proof producer |
| AI agents | code/spec/proof candidates | untrusted |
| PSKernel | logical admission | **core TCB** |
| CheckedCore | post-admission semantic handoff | replay-gated |
| Evidence Graph | claims/evidence/assumption bookkeeping | policy-critical; evidence independently checked |
| Erasure/VerifiedIR | executable lowering | compiler trust until separately validated/proved |
| backend | target emission | runtime trust until validation/proof |
| foreign dependency | external behavior | explicit assumption/test/model boundary |
| SLSA/in-toto layer | build provenance | supply-chain evidence, not logical proof |

## 71. Detailed feasibility score

Scale:

~~~text
0 = contradiction / not credible
5 = plausible with major unresolved work
10 = demonstrated architecture with manageable remaining work
~~~

| Dimension | Current | Potential | Evidence confidence /10 |
|---|---:|---:|---:|
| Problem–solution fit | 9.0 | 9.4 | 5 |
| Lean/PSKernel trust architecture | 9.0 | 9.6 | 8 |
| Fit with PSC/CheckedCore/VerifiedIR | 9.0 | 9.4 | 7 |
| Bounded verified generation | 8.5 | 9.4 | 8 |
| AI proof synthesis | 7.5 | 9.2 | 7 |
| AI code+proof co-design | 6.8 | 9.0 | 6 |
| AI specification synthesis | 4.8 | 8.5 | 5 |
| Repository-scale autonomy | 4.5 | 8.0 | 5 |
| JS/npm migration practicality | 7.0 | 8.7 | 4 |
| Foreign-boundary assurance | 5.5 | 8.5 | 5 |
| Audit/provenance | 9.0 | 9.6 | 8 |
| Backend semantic assurance | 5.0 | 8.8 | 5 |
| Cross-platform execution | 6.5 | 8.7 | 5 |
| Developer practicality | 5.5 | 8.5 | 3 |
| Ecosystem compounding | 5.5 | 8.8 | 3 |
| Small-team implementation feasibility | 5.8 | 7.5 | 5 |
| Adoption wedge | 7.5 | 9.0 | 4 |
| Long-term defensibility | 8.0 | 9.2 | 5 |

Summary:

~~~text
Bounded Factory MVP feasibility:           8.5 / 10
Full general Factory current feasibility:  5.2 / 10
Architecture fit with existing repo:       9.0 / 10
Practical product readiness today:         5.5 / 10
Long-term potential:                       8.8 / 10
Overall evidence confidence:               ~2.7 / 5
~~~

## 72. Weighted 100-point ProofScript evaluation

| Criterion | Weight | Current /5 | Potential /5 | Evidence /5 |
|---|---:|---:|---:|---:|
| Problem–solution fit | 13 | 4.5 | 4.7 | 2.5 |
| Differentiated wedge / language necessity | 7 | 4.5 | 4.8 | 2.0 |
| Semantic architecture | 10 | 4.3 | 4.7 | 3.5 |
| Practical usefulness / ergonomics | 9 | 2.5 | 4.2 | 1.5 |
| Performance / resource economics | 6 | 2.5 | 4.0 | 1.0 |
| Safety / correctness / TCB | 7 | 4.4 | 4.8 | 3.5 |
| Implementation feasibility | 6 | 3.2 | 4.0 | 2.5 |
| Developer product / tooling | 9 | 2.8 | 4.3 | 2.0 |
| Adoption / migration / interoperability | 12 | 3.0 | 4.3 | 1.5 |
| Ecosystem / distribution | 7 | 1.8 | 4.2 | 1.0 |
| Compatibility / evolution | 5 | 3.4 | 4.4 | 2.0 |
| Governance / sustainability | 3 | 1.8 | 3.8 | 1.0 |
| Future relevance | 4 | 4.7 | 4.9 | 3.0 |
| Novelty / defensibility | 2 | 4.5 | 4.7 | 2.5 |

Weighted result:

~~~text
Current strategic/product quality:  68.9 / 100
Potential if key hypotheses work:   88.6 / 100
Weighted evidence maturity:         42.7 / 100
Equivalent evidence confidence:     2.1 / 5
~~~

The low evidence number matters most. Much of the product/adoption thesis remains design/prototype evidence.

## 73. Recommended Factory implementation research

### F0 — Evidence model first

Build a machine-readable Evidence Graph capable of representing:

- PSKernel proof/admission identities;
- source/profile/environment hashes;
- contract-obligation identities;
- tests/fuzz/differential evidence;
- runtime externals;
- compiler/backend evidence;
- provenance/SBOM links.

Exit condition: an existing package can answer **what exactly is proved, assumed, tested, and trusted?**

### F1 — Proof-obligation service

Expose a stable machine API:

~~~text
source/CheckedCore
→ obligations
→ proof-state queries
→ candidate proof submission
→ PSKernel acceptance/rejection
~~~

Support Lean-assisted proving with PSKernel replay.

### F2 — Parser/codec Factory vertical

~~~text
schema
→ ProofScript model/parser/serializer
→ contracts
→ proof obligations
→ checked proofs
→ fuzz/differential suite
→ JS/WASM package
→ evidence/provenance
~~~

Do not generalize Forge before this works.

### F3 — JS/npm Bridge

Publish the generated package through normal JS/TS consumption.

Measure migration, debugging, interop, package UX.

### F4 — AI joint planning

Add AI after deterministic evidence APIs are stable.

Compare:

- code-first then proof;
- joint code/proof planning;
- human vs AI-proposed specifications;
- multiple AI providers.

### F5 — Translation validation

Add a per-build validator between VerifiedIR and at least one narrow backend representation.

This is a more practical next assurance step than immediately proving an entire optimizing backend.

### F6 — Reuse/compounding experiment

Build packages 2–10 in the same vertical and measure whether **human minutes per trusted capability** falls as reusable checked libraries/theorems grow.

This can validate or kill the ecosystem-compounding thesis.

### F7 — Generalize only from evidence

Potential next verticals:

- OpenAPI/SDK;
- protocol state machines;
- authorization;
- financial logic.

Only after these should a large ProofScript App framework become a major investment.

## 74. Hard stop / pivot criteria

Pause or narrow the Factory strategy if bounded experiments repeatedly show:

1. humans spend more time correcting specifications than they save on implementation/proof;
2. AI proof attempts rarely close meaningful obligations;
3. foreign assumptions dominate the behavior users care about;
4. backend/runtime trust invalidates most user-facing verification claims;
5. evidence bundles are too complex for real users/reviewers;
6. package migration/debugging friction exceeds assurance value;
7. reusable checked components do not reduce marginal package effort;
8. Forge requires a second semantic compiler or materially enlarges the TCB;
9. a simpler Lean-based tool delivers essentially the same value at much lower maintenance cost.

If these do not occur and the measured economics improve package by package, escalate the Factory hypothesis.

---

# Final identity

## Long form

ProofScript is an attempt to build a programming language whose semantics are worth mastering deeply because programming, specification, mathematical reasoning, and machine-checked correctness belong to one coherent system.

It takes its strongest foundational inspiration from Lean: expressive dependent types, explicit proof terms, and a small checking boundary that allows powerful automation without making automation the final source of truth.

It differs in product ambition. ProofScript aims to make that foundation practical for ordinary software development, gradual verification, AI-assisted construction, interoperability, and cross-platform deployment.

ProofScript should not become a giant union of existing languages. It should keep a small semantic vocabulary, put breadth into libraries/platforms, and add syntax only when real evidence justifies it.

Its near-term success does not depend on replacing TypeScript, Rust, Python, Go, Lean, or another language. It depends on demonstrating that important software components can be built with materially stronger assurance while remaining practical to integrate into existing systems.

A current exploratory direction is that the killer product may be a system that helps manufacture the ProofScript ecosystem itself—using AI for implementation/specification/proof work while explicit checking and audit artifacts prevent generated scale from requiring proportional trust. That idea remains a hypothesis to test, not a settled identity.

## Short form

> **ProofScript is a Lean-grounded, gradually verified programming language for building trustworthy software in an AI-assisted, cross-platform world. It unifies ordinary programming, specification, and proof under one semantic foundation while keeping AI and automation outside the trusted correctness boundary.**

## Evaluation question

> **Does ProofScript deliver a sufficiently large, practical, and durable improvement in software trust and programming capability to justify the permanent cost of introducing and sustaining a new programming language?**

If evidence says yes, expand deliberately.

If evidence says no, narrow or pivot.

That discipline is part of the ProofScript identity.
