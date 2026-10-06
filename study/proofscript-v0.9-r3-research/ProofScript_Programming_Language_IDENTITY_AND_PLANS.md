# ProofScript Programming Language — Identity and Plans

**Status:** strategic identity and planning document — research revision v4; not a language specification and not implementation-conformance evidence.

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

### Iterative design result — VEF-Core

A subsequent architecture search deliberately redesigned the factory rather than inflating the existing score.

The strongest current scoped design is **Verified Ecosystem Factory Core (VEF-Core)**:

> **A library/package factory that grows ecosystem coverage through multiple assurance lanes—bind, characterize, port, verified replacement, or verified-by-construction generation—while using locked specifications, role-separated AI workcells, kernel-checked evidence, and explicit provenance.**

For this exact bounded scope:

~~~text
Current technical feasibility:  9.23 / 10
Evidence confidence:            ~7.3 / 10
Scope:                           library/package ecosystem,
                                 deterministic or explicitly bounded effects,
                                 first-class JS/npm + Wasm publication,
                                 no claim of arbitrary autonomous app synthesis
~~~

The >9 score applies only to this constrained product architecture. It does **not** raise the score of the unrestricted autonomous factory vision.


### Mainstream JS/TS adoption iteration

A further architecture loop optimized for **ordinary JS/TS/web developers**, including users who do not want AI or formal proof as their primary workflow.

The highest-scoring current vision is:

> **Keep JavaScript/TypeScript for the application stack you already have; use ProofScript for the modules and packages you want to trust more.**

VEF-Core remains the ecosystem accelerator underneath this experience.

The optional AI layer becomes model-agnostic and local-first: ProofScript exposes deterministic compiler/checker/spec/audit tools to existing open-source coding agents rather than requiring a proprietary or cloud model.

For this exact target:

~~~text
Product-vision score:           9.35 / 10
Architecture feasibility:       9.18 / 10
Combined vision/feasibility:    9.27 / 10
Architecture evidence:          ~7.8 / 10
Current ProofScript product evidence:
                                 ~4.2 / 10
~~~

The score applies primarily to the JS/TS/web ecosystem adoption strategy, not yet to “most programmers in every ecosystem”.


For a **fully autonomous, general-purpose factory that generates and verifies arbitrary application ecosystems**:

~~~text
Current feasibility:          ≈5.0 / 10
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


### Feasibility snapshot — 2026-10-05

The current research verdict is deliberately asymmetric:

> **A bounded Verified Software Factory is achievable. A general autonomous factory that can take arbitrary software intent and reliably produce correct, fully verified, production-ready software is not currently achievable and must not be claimed.**

The most credible near-term interpretation is an **evidence-producing software factory**:

~~~text
specification / interface / existing artifact
                  ↓
      deterministic normalization
                  ↓
     AI-generated candidate work
   implementation / tests / proofs
                  ↓
       explicit proof obligations
                  ↓
       deterministic checkers
                  ↓
     evidence graph + assumptions
                  ↓
  deployable package + provenance
~~~

Three complementary lanes should be researched:

1. **native ProofScript verification** — software is written in ProofScript and selected properties are proved against its source semantics;
2. **verified-by-construction generation** — constrained specifications generate ProofScript implementations by composing already-proved libraries/combinators;
3. **foreign verification bridges** — foreign code is translated/modelled and proved against an explicit specification, with translation/model assumptions visible.

The first two are materially more tractable than general verification of arbitrary JavaScript/TypeScript software.

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
Full general Factory current feasibility:  ≈5.0 / 10
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


# Part XV — Verified Software Factory feasibility study

**Status:** research evaluation, not an adopted architecture.  
**Snapshot date:** 2026-10-05.

## 69. Feasibility verdict

### 69.1 Can a Verified Software Factory be built?

**Yes, in bounded and progressively expanding forms.**

The idea is technically credible because most of its underlying mechanisms have already been demonstrated independently:

- Lean keeps sophisticated elaboration/tactics outside a small kernel that checks accepted terms.
- LeanDojo provides end-to-end infrastructure for AI-assisted theorem proving in Lean.
- Microsoft SymCrypt now uses Rust, Aeneas, Lean, and AI agents to verify production cryptographic implementations. Agents write proofs; Lean checks them. Human effort concentrates on specifications, trusted models, major properties, and toolchain design.
- EverParse automatically generates verified parsers and serializers from constrained data-format specifications using untrusted frontends plus verified F*/Low* combinators.
- Dafny integrates specifications, automated verification, developer tooling, and compilation to several mainstream languages.
- Verus documents LLM-assisted proof workflows and explicitly recommends preventing agents from changing specifications or using proof-cheating shortcuts.
- Aeneas translates a substantial safe-Rust subset into Lean/F*/Coq/HOL4 models for extrinsic verification.
- CompCert and CakeML show that realistic verified compilation and verified self-hosting are possible, although costly.
- SLSA and in-toto already provide strong outer provenance/attestation models.
- WIT provides a practical model for language-neutral interface contracts and packages.

Primary references:

- https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/
- https://leandojo.org/leandojo.html
- https://www.microsoft.com/en-us/research/blog/verifying-rust-cryptography-in-symcrypt-from-standards-to-code/
- https://arxiv.org/abs/2609.15648
- https://project-everest.github.io/everparse/
- https://project-everest.github.io/
- https://dafny.org/latest/
- https://verus-lang.github.io/verus/guide/llmforverusproof.html
- https://github.com/AeneasVerif/aeneas
- https://compcert.org/
- https://cakeml.org/
- https://component-model.bytecodealliance.org/design/wit.html
- https://slsa.dev/spec/v1.2/
- https://in-toto.io/

### 69.2 What this evidence does not prove

It does **not** show that current technology can reliably:

- infer the intended specification of arbitrary software from prose;
- generate arbitrary production software and prove all properties users care about;
- verify arbitrary JavaScript/npm behavior involving proxies, reflection, dynamic mutation, host APIs, and side effects;
- eliminate expert review of trusted specifications, foreign models, intrinsics, and security properties;
- prove a general multi-backend toolchain end-to-end at low cost;
- create an exponentially growing correct ecosystem without new bottlenecks.

Those remain open research hypotheses.

### 69.3 Correct product claim

The credible factory claim is not:

> AI writes software, therefore the software is correct.

It is:

> **AI proposes software and evidence; deterministic tools check what can be checked; ProofScript records exactly which claims are proved, tested, model-dependent, assumed, or merely typed, and binds those claims to exact artifacts.**

That is achievable.

---

## 70. Why the current pskernel architecture is unusually compatible with this idea

The repository already contains most of the right conceptual seams:

~~~text
source
  ↓
frontend / elaboration
  ↓
CandidateCore / admission-ready form
  ↓
kernel-provider boundary
  ↓
CheckedCore
  ↓
erasure
  ↓
ErasedIR / RuntimeIR
  ↓
validation
  ↓
VerifiedIR
  ↓
target-specific lowering
~~~

The production architecture also already plans:

- a provider-neutral kernel contract;
- Lean-backed checked providers;
- eventual owned pskernel-core authority;
- an ErasedIR → VerifiedIR validation split;
- InterfaceIR;
- canonical semantic artifacts and hashes;
- semantic package manifests;
- compiler-service APIs;
- direct JavaScript and WebAssembly backends;
- hermetic/reproducible builds;
- SLSA/in-toto-style provenance.

Therefore the factory should **compose the existing pipeline**, not create a second semantic checker.

### Implementation-state caution

Current repository evidence is meaningful but not yet production completeness:

- the active self-host closure remains compiler-focused;
- Lean 4.34-backed checking is the practical default kernel route;
- the owned pskernel-core remains experimental;
- full language/compiler conformance is not yet complete;
- backend semantic-preservation proofs are future work;
- production architecture documents are explicitly forward-looking.

Forge prototypes can begin before every production gate closes, but their assurance claims must remain experimental until they traverse the real checked pipeline.

---

## 71. Division of responsibilities: Lean 4, PSC, PSKernel, and Forge

### 71.1 Lean 4

Use Lean as:

- the pinned semantic/reference system;
- a mature proof-development environment;
- a source of theorem/tactic libraries;
- a reference kernel provider during early production;
- an environment for AI-assisted proof search;
- a target for extrinsic verification models such as Rust/Aeneas;
- an independent oracle against the owned kernel.

Lean tactics and AI agents remain proof producers, not proof authority.

### 71.2 ProofScript / PSC

Use ProofScript as:

- the application-facing programming language;
- the language for portable libraries;
- the native place for contracts/propositions;
- the source generated by Forge when Forge creates native packages;
- the stable developer-facing gradual-verification experience.

PSC must not become merely a text generator for Lean.

### 71.3 PSKernel

Use the kernel/provider contract as:

- admission authority for CandidateCore;
- checker for declarations/proof terms;
- producer/guardian of checked identity/receipts;
- replay boundary for independent verification.

Initially a Lean-backed provider may fulfill this role. The owned kernel should replace it only after independent readiness gates close.

Forge never receives a privileged admission path.

### 71.4 CheckedCore / VerifiedIR pipeline

Keep two different questions separate:

~~~text
Is the source/logical claim valid?
             ≠
Was the executable target produced correctly?
~~~

Preferred production path:

~~~text
PSC source
  → CandidateCore
  → kernel provider
  → CheckedCore
  → erasure
  → ErasedIR
  → validateRuntimeIr
  → VerifiedIR
  → target lowering
~~~

A theorem checked over source semantics is not automatically a theorem about emitted JavaScript or machine code. Backend evidence must be reported separately.

### 71.5 InterfaceIR

InterfaceIR is for foreign/API contracts only:

~~~text
.d.ts / WIT / OpenAPI / native metadata
              ↓
          InterfaceIR
              ↓
PSC facade + host adapter + explicit assumptions
~~~

Foreign type systems must not redefine Core.

### 71.6 Forge

Forge should be an **untrusted orchestrator**.

It may:

- ingest authoritative interface metadata;
- propose APIs/contracts;
- generate PSC implementations;
- generate tests/fuzz harnesses;
- invoke proof agents;
- invoke kernel checking;
- construct audit dashboards;
- package artifacts.

It may not:

- manufacture CheckedCore;
- weaken approved specifications silently;
- turn failed proof obligations into success;
- hide new axioms/assumptions;
- invent authoritative foreign signatures when authoritative metadata exists.

---

## 72. Three factory lanes

### Lane A — native ProofScript verification

~~~text
PSC source + contract
       ↓
proof obligation
       ↓
tactics / AI
       ↓
kernel-checked evidence
~~~

**Feasibility:** high for bounded/pure/structured properties.

**Strategic value:** highest because program and proof share one semantic foundation.

### Lane B — verified-by-construction generation

~~~text
restricted specification / DSL
       ↓
untrusted generator
       ↓
verified library/combinator composition
       ↓
ordinary checking
       ↓
implementation + theorem
~~~

EverParse is strong evidence for this pattern.

**Feasibility:** very high in domains with compositional semantics.

**Recommended first Forge lane.**

### Lane C — foreign implementation verification

~~~text
foreign source / IR
       ↓
extractor / translator
       ↓
Lean or PSC model
       ↓
specification theorem
       ↓
checked proof
~~~

Aeneas provides strong evidence for safe Rust.

The translator/model remains part of the trust story unless independently verified.

**Feasibility:** medium-high for constrained languages; low for arbitrary dynamic JavaScript.

---

## 73. Replace a single assurance ladder with an assurance vector

The provisional PS-A0…PS-A6 ladder is useful for brainstorming but risks conflating unrelated guarantees.

A safer long-term model is a vector.

### Semantic assurance

~~~text
typed
specified
proved-selected-properties
proved-public-specification
~~~

### Boundary assurance

~~~text
opaque foreign assumption
modeled
conformance-tested
differentially-tested
formally-related-to-model
~~~

### Translation assurance

~~~text
ordinary compiler path
differentially-tested
translation-validated
proved transformation
end-to-end preservation proof
~~~

### Build/supply-chain assurance

Use standard vocabulary where possible:

~~~text
SLSA Build L1/L2/L3
signed provenance
SBOM
independent reproduction
~~~

### Trust identity

Every assurance report records:

~~~text
language/profile
kernel contract/provider
proof checker
compiler/IR contracts
foreign assumptions
backend identity
toolchain/provenance identity
~~~

A UI may summarize this vector but must not hide it behind one undifferentiated green `Verified` badge.

---

## 74. Evidence graph: the central Forge artifact

The core factory output should be an **evidence graph**.

Conceptually:

~~~text
Claim {
  subjectArtifact
  specification
  property
  evidence
  checker
  assumptions
  dependencies
  environment
  status
}
~~~

Example:

~~~text
claim = parser-roundtrip-v1
subject = VerifiedIR:<hash>
specification = Codec.decode_encode
evidence = CheckedProof:<hash>
checker = KernelContract-v1 / provider lean434
assumptions = [...]
target = JS:<hash>
translationAssurance = differential-tested
buildProvenance = SLSA/in-toto:<id>
~~~

This is crucial because a true theorem over CheckedCore does not automatically prove that an unchecked backend emitted equivalent machine behavior.

### Artifact classes

Reuse/extend the current artifact architecture:

~~~text
SourceArtifact
SpecificationArtifact
InterfaceIrArtifact
CandidateCoreArtifact
CheckedCoreArtifact
ProofObligationArtifact
CheckedProofArtifact
ErasedIrArtifact
VerifiedIrArtifact
TargetIrArtifact
ExecutableArtifact
EvidenceManifest
Attestation
~~~

Persistent artifact identities should be versioned and domain-separated.

---

## 75. Specification integrity is likely the main bottleneck

Current AI/proof experience suggests agents work best when:

- theorem statements are fixed;
- libraries/tactics are available;
- verifier errors are in the loop;
- agents cannot change the specification to make proofs easier.

Forge should separate roles.

### Specification agent

May draft contracts/specifications. Output is review-required.

### Implementation agent

May implement against an approved specification.

### Proof agent

By default may edit only proof/evidence files.

It must not silently weaken:

- preconditions/postconditions;
- invariants;
- public theorem statements;
- trusted foreign models.

### Assumption-delta gate

Every verification run should report:

~~~text
new axioms
new opaque/trusted models
new foreign assumptions
new proof holes
weakened contracts
removed invariants
changed public theorem statements
~~~

Any increase requires explicit review.

### Human review focus

Humans should focus on:

- source-of-truth specifications;
- security properties;
- public theorem statements;
- intrinsics/foreign models;
- effect/capability contracts;
- trust-boundary changes.

This closely matches the most convincing current SymCrypt workflow.

---

## 76. Recommended first technical vertical — Verified Codec/Parser Factory

This is the strongest first experiment.

### Why

- specifications can be precise;
- proofs compose well;
- prior art is strong;
- outputs are useful across platforms;
- properties are understandable;
- async/UI/state complexity is low.

### Initial scope

Use a deliberately small format/schema language.

Progression:

~~~text
fixed records/enums
→ bounded variable-length fields
→ tagged variants
→ canonical encodings
→ CBOR/protocol subsets
→ richer schemas
~~~

### Generated artifacts

~~~text
PSC data types
parser
serializer
validator
round-trip theorem
bounds/safety theorems
canonicality/injectivity theorem where meaningful
property tests
fuzz harness
JS/Wasm package
EvidenceManifest
~~~

First key law:

~~~text
decode(encode(x)) = ok x
~~~

plus explicit validation/rejection properties.

### Success test

The generated package must be:

- useful outside ProofScript;
- easier to audit than handwritten equivalent code;
- acceptably performant;
- reproducible;
- tied to exact specifications/evidence;
- maintainable after schema changes.

---

## 77. Second vertical — OpenAPI / SDK Factory

This is probably a stronger adoption demonstration.

~~~text
OpenAPI
  ↓
InterfaceIR
  ↓
PSC request/response model
  ↓
codec/validation
  ↓
client/server facade
  ↓
contracts/tests/proofs
  ↓
npm package + .d.ts + evidence
~~~

Potentially prove:

- schema/codec correspondence;
- parameter/path construction;
- required-field handling;
- response decoding;
- native business/state invariants.

Do **not** claim that this proves:

- the remote service obeys OpenAPI;
- authentication infrastructure behaves as modeled;
- network delivery is reliable;
- third-party business logic is correct.

Those are environmental/foreign claims.

---

## 78. Third vertical — Verified state machines

A small declarative state-machine model can generate:

- state/transition types;
- illegal-transition rejection;
- invariant proofs;
- model/property tests;
- event serialization;
- host adapters.

Candidate uses:

- auth/session workflows;
- payment states;
- protocol phases;
- package/update workflows;
- local distributed-control state.

---

## 79. Foreign verification — Rust before arbitrary JavaScript

If ProofScript integrates foreign-code verification, safe Rust is the best early research target.

~~~text
Rust
  ↓
Charon/Aeneas
  ↓
Lean model
  ↓
Lean theorem/proof
  ↓
ProofScript EvidenceManifest references result
~~~

Initially integrate this evidence rather than reimplement Aeneas in PSC.

Arbitrary JS/TS verification should come much later because proxies, reflection, prototype mutation, event loops, dynamic property shapes, and host APIs complicate faithful modeling.

---

## 80. Audit/provenance architecture

ProofScript should own a **small semantic evidence manifest** and reuse standards outside it.

ProofScript-owned evidence records:

~~~text
source/spec identity
language/profile
kernel/checker identity
CheckedCore identity
proof obligations/evidence
VerifiedIR identity
backend/target identity
foreign assumptions
test/fuzz/conformance evidence
~~~

Outer provenance uses:

- in-toto;
- SLSA v1.2 build provenance;
- SBOM standards;
- signatures/transparency;
- independent reproduction where required.

SLSA proves/builds provenance facts; it does not prove program semantics. ProofScript evidence covers semantic claims. Keep them separate.

---

## 81. Candidate developer workflow

Exploratory commands:

~~~text
psc forge import <source>
psc forge plan
psc forge generate
psc verify
psc audit
psc explain-trust
psc replay-evidence
psc package
~~~

### forge plan

Before generation, emit a human-reviewable plan:

~~~text
authoritative inputs
generated artifacts
proposed public API
proposed contracts
properties to prove
foreign assumptions
test/fuzz strategy
targets
expected assurance dimensions
~~~

### psc audit

It should answer:

- exactly what is proved?
- what is only typed?
- what is tested?
- which assumptions are foreign?
- which checker accepted the proof?
- which executable artifacts are bound to evidence?
- what backend-assurance level exists?
- how was the artifact built?
- did the trusted specification weaken?

This may become one of ProofScript's strongest product surfaces.

---

## 82. Implementation plan using the current ProofScript architecture

### F0 — close foundational authority gates

Before strong Forge claims:

1. complete mechanical conformance for the claimed source/profile;
2. make real kernel admission mandatory before production CheckedCore;
3. complete ErasedIR → VerifiedIR validation;
4. structurally enforce backend authority boundaries;
5. stabilize versioned semantic artifacts.

Forge can prototype earlier but must remain experimental.

### F1 — EvidenceManifest-v1

Implement evidence identity before broad AI generation.

Minimum model:

~~~text
subject
claim kind
spec/property identity
evidence
checker/provider
assumptions
dependency claims
translation relation
build/provenance references
status
~~~

### F2 — ProofObligationGraph-v1

Contracts/library laws need stable obligation identities and incremental dependencies:

~~~text
declaration
  → obligations
  → prerequisite theorem IDs
  → proof candidate
  → checked proof receipt
~~~

### F3 — Lean proof-service adapter

Exploit Lean rather than rebuilding automation immediately.

~~~text
goal
environment snapshot
allowed theorem set
budget
  ↓
Lean tactics / Meta / AI
  ↓
candidate proof term
  ↓
kernel-provider check
~~~

Long term, if pskernel-core accepts the same canonical proof artifacts, Lean can become construction/reference infrastructure rather than sole trust authority.

### F4 — agent sandbox + anti-cheat

Implement:

- per-agent write scopes;
- spec/proof role separation;
- assumption-delta checks;
- rejection/flagging of sorry/admit/unauthorized axioms;
- deterministic replay;
- model/provider provenance;
- explicit budgets.

### F5 — Verified Codec Factory

Build the first end-to-end vertical.

Do not begin with arbitrary npm package reimplementation.

### F6 — assurance dashboard

Show developer-facing:

- source function/component;
- specification/theorem;
- verification state;
- assumptions;
- proof/checker;
- target binding;
- change history.

### F7 — InterfaceIR adapters

Recommended order:

1. WIT;
2. OpenAPI / JSON Schema;
3. bounded .d.ts subset;
4. broader JS/TS only when evidence supports it.

Machine-readable authoritative metadata outranks AI-invented signatures.

### F8 — npm publication bridge

Publish runtime artifacts plus .d.ts and optional assurance bundle.

Ordinary consumers should not require ProofScript just to run the package.

### F9 — cross-backend evidence

For a portable corpus:

~~~text
same CheckedCore / VerifiedIR
     ↓
JS
Wasm
optional native adapter
~~~

Start with differential/conformance evidence. Formal preservation can grow over small stable backend subsets.

### F10 — compounding experiment

After reusable packages/theorems exist, measure whether package N genuinely requires less human review/effort than package 1.

If not, the ecosystem-factory flywheel is false or incomplete.

---

## 83. Proof / test / assumption allocation

### Good proof targets

- pure algorithms;
- codec/parser laws;
- algebraic invariants;
- state-machine invariants;
- bounds/index properties;
- data-structure invariants;
- deterministic transformations;
- small stable IR validators.

### Better initially as tests/differential/fuzz evidence

- backend runtime equivalence before proofs exist;
- foreign runtime adapters;
- network/API conformance;
- browser/Node host behavior;
- third-party serialization behavior;
- performance equivalence.

### Explicit assumptions

- OS/hardware behavior not modeled;
- JS/Wasm engine correctness unless separately justified;
- external service behavior;
- unverified foreign libraries;
- backend compiler correctness without preservation evidence;
- imported cryptographic primitives when opaque.

Trying to prove everything immediately would make the factory impractical.

---

## 84. Verified Software Factory feasibility score

Scale:

~~~text
0 = contradictory/impossible
1 = speculative
2 = research-prototype plausible
3 = practical in bounded niche
4 = strongly feasible with engineering
5 = demonstrated/category-leading
~~~

| Capability | Current feasibility | Potential | Evidence confidence |
|---|---:|---:|---:|
| kernel-checked ProofScript evidence | 4 | 5 | 3 |
| AI-generated proof attempts | 4 | 5 | 4 |
| AI-generated correct specifications | 2 | 4 | 2 |
| native PSC gradual verification | 3 | 5 | 2 |
| verified-by-construction generators | 4 | 5 | 5 |
| parser/codec factory | 4 | 5 | 5 |
| OpenAPI/SDK factory | 3 | 5 | 3 |
| state-machine factory | 4 | 5 | 3 |
| Rust foreign verification | 4 | 5 | 5 |
| arbitrary JS/npm implementation verification | 1 | 3 | 2 |
| InterfaceIR / migration bridge | 3 | 5 | 3 |
| multi-backend generation | 3 | 4 | 3 |
| end-to-end verified compilation | 2 | 5 | 5 |
| audit/provenance system | 4 | 5 | 5 |
| autonomous general software factory | 1 | 3 | 1 |
| ecosystem-compounding effect | 2 | 5 | 1 |

### Overall feasibility verdict

~~~text
Bounded Verified Software Factory:
  about 4/5 feasible as a serious engineering/research program

General autonomous “build anything correctly” factory:
  about 1–2/5 feasible today

Recommended posture:
  grow a bounded evidence-producing factory monotonically
  instead of promising general autonomous correctness
~~~

---

## 85. ProofScript project score snapshot

Using the document's existing weighted 100-point framework and scoring **current evidence rather than aspiration**:

| Criterion | Weight | Current 0–5 | Potential 0–5 | Evidence 0–5 |
|---|---:|---:|---:|---:|
| Problem–solution fit | 13 | 3 | 4 | 2 |
| Differentiated wedge / language necessity | 7 | 4 | 5 | 1 |
| Semantic architecture | 10 | 4 | 5 | 2 |
| Practical usefulness / ergonomics | 9 | 2 | 4 | 1 |
| Performance / resource economics | 6 | 2 | 4 | 1 |
| Safety / correctness / TCB | 7 | 4 | 5 | 2 |
| Implementation feasibility | 6 | 3 | 4 | 2 |
| Developer product / tooling | 9 | 2 | 4 | 1 |
| Adoption / migration / interoperability | 12 | 2 | 4 | 1 |
| Ecosystem / distribution | 7 | 1 | 4 | 0 |
| Compatibility / evolution | 5 | 3 | 4 | 1 |
| Governance / sustainability | 3 | 1 | 4 | 1 |
| Future relevance | 4 | 5 | 5 | 2 |
| Novelty / defensibility | 2 | 4 | 5 | 2 |

Weighted snapshot:

~~~text
Current quality:       ≈ 56 / 100
Potential quality:     ≈ 86 / 100
Evidence confidence:   ≈ 1.35 / 5 weighted
~~~

Interpretation:

- The architecture/idea is considerably stronger than the current product/ecosystem maturity.
- The potential score is conditional, not earned.
- The low evidence-confidence score is currently more important than the potential score.
- Real verticals, migration evidence, verification economics, and user adoption should now move the scores—not more speculative specification polish.

---

## 86. First-vertical ranking

| Candidate | Technical feasibility | Product value | Verification leverage | Priority |
|---|---:|---:|---:|---:|
| verified parser/codec generator | 5/5 | 4/5 | 5/5 | **1** |
| OpenAPI/SDK factory | 4/5 | 5/5 | 3/5 | **2** |
| declarative state-machine factory | 4/5 | 4/5 | 5/5 | **3** |
| pure algorithm/financial library | 4/5 | 3/5 | 5/5 | 4 |
| Rust/Aeneas evidence integration | 4/5 | 3/5 | 5/5 | 5 / parallel research |
| general HTTP/network framework | 3/5 | 5/5 | 2/5 | later |
| arbitrary npm migration | 2/5 | 5/5 | 1/5 | later |
| Flutter-like UI framework | 2/5 | 4/5 | 1/5 | not first |
| autonomous general app factory | 1/5 | 5/5 | 1/5 | research only |

---

## 87. Forge go/no-go gates

### F-A — checker integrity

Generated evidence cannot be accepted without the selected kernel/provider.

### F-B — specification integrity

Proof agents cannot silently mutate approved public specifications.

### F-C — assumption transparency

Every new axiom/model/foreign assumption appears in evidence and release diffs.

### F-D — artifact binding

Evidence binds exact source/spec/CheckedCore/VerifiedIR/target identities.

### F-E — reproducibility

Proof/check/build evidence can be replayed from pinned inputs.

### F-F — real product advantage

At least one package is easier to create/review/maintain than an incumbent workflow while providing materially stronger assurance.

### F-G — maintenance economics

Evidence-repair cost after meaningful refactors stays acceptable.

### F-H — compounding evidence

Later packages reuse checked components/theorems and demonstrate lower marginal human effort.

If F-F through F-H fail, Forge should remain a specialized verification tool rather than the central platform thesis.

---

## 88. Recommended next research decision

Do **not** commit to a general Verified Software Factory.

Commit only to this falsifiable experiment:

> **Build the smallest evidence-producing Forge vertical that uses the real PSC → kernel-provider → CheckedCore → VerifiedIR pipeline, keeps AI outside the trust boundary, emits a human-auditable evidence graph, and publishes an ordinary consumable artifact.**

Recommended experiment:

~~~text
small declarative format/schema
        ↓
Forge prototype
        ↓
PSC codec/parser
        ↓
round-trip + safety obligations
        ↓
Lean/PSC automation + AI proof attempts
        ↓
kernel-checked proof evidence
        ↓
VerifiedIR
        ↓
JS + Wasm
        ↓
npm package
        ↓
audit dashboard + SLSA/in-toto provenance
~~~

If this works convincingly, advance to OpenAPI/SDK generation and state-machine packages.

If it fails, improve specification/proof/product economics before attempting framework-scale ecosystem generation.


# Part XVI — Iterated design result: Verified Ecosystem Factory Core

**Status:** highest-feasibility research design found after iterative red-team redesign.  
**Provisional name:** Verified Ecosystem Factory Core / `VEF-Core`.  
**Feasibility score:** **9.23 / 10** for the exact bounded scope below.  
**Evidence confidence:** approximately **7.3 / 10**.  
**Important:** this score does not apply to arbitrary autonomous application generation.

## 89. Architecture-search iterations

The design was iterated instead of forcing a high score.

| Iteration | Architecture | Feasibility | Main remaining problem |
|---|---|---:|---|
| 0 | General autonomous Verified Software Factory | ~5.0/10 | specification truth, repository-scale autonomy, foreign/runtime correctness |
| 1 | Human-supervised bounded Forge | ~8.5/10 | still assumes too much native rewriting and manual specification work |
| 2 | Evidence-centric domain factory | ~8.9/10 | excellent for one vertical but weak ecosystem-coverage strategy |
| 3 | **Verified Ecosystem Factory Core** | **9.23/10** | bounded package scope; expanded application/platform vision remains later work |

The score increased because the architecture changed:

- ecosystem coverage no longer requires native reimplementation;
- proof effort is allocated by ROI instead of applied uniformly;
- declarative package families use verified generators instead of repeated ports;
- approved specifications become immutable versioned inputs to implementation/proof agents;
- assurance is represented as an evidence graph rather than one badge;
- existing ecosystems remain usable from day one;
- current Lean/PSC/PSKernel infrastructure is reused instead of replaced.

## 90. Exact VEF-Core scope

VEF-Core v1 targets:

- reusable libraries/packages;
- pure or mostly deterministic algorithms;
- codecs/parsers/validators;
- schema-generated models;
- state machines;
- SDK/API clients with explicit foreign boundaries;
- portable data/collection/text libraries;
- selected platform wrappers;
- bounded native replacements for high-value dependencies.

Initial publication targets:

- JavaScript/npm;
- WebAssembly;
- ProofScript-native package artifacts.

Not V1 goals:

- arbitrary UI/application generation;
- arbitrary dynamic JavaScript formal verification;
- whole operating systems;
- unrestricted FFI verification;
- fully proved optimizing compiler stack;
- autonomous correctness from natural-language intent.

This bounded scope is what makes >9/10 feasibility credible.

## 91. Five ecosystem lanes

For every desired capability, VEF-Core chooses the cheapest assurance strategy that satisfies the product requirement.

### Lane 0 — Bind

Use an existing foreign implementation through InterfaceIR/FFI.

~~~text
foreign package
   ↓
machine-readable interface
   ↓
ProofScript binding
   ↓
explicit foreign assumption
~~~

This provides immediate ecosystem breadth.

### Lane 1 — Characterize

Keep the foreign implementation and add typed interfaces, behavioral models, property tests, fuzzing, differential tests, and EvidenceGraph claims.

Use for platform APIs, drivers, runtime adapters, and packages where native replacement has low ROI.

### Lane 2 — Port

AI-assisted source port into ProofScript, preserving provenance and license obligations.

~~~text
suitably licensed OSS source
       ↓
AI port
       ↓
PSC implementation
       ↓
differential oracle against upstream
       ↓
contracts / selected proofs
       ↓
native ProofScript package
~~~

Engineering policy:

> Translating/adapting open-source source code may remain a derivative work. AI rewriting does not automatically erase upstream license/copyright obligations.

The package recipe records source repository/commit, license, notices, and generated-file provenance.

### Lane 3 — Verified replacement

Implement independently against an approved specification.

~~~text
approved SpecCapsule
      ↓
PSC implementation
      ↓
proof obligations
      ↓
checked proofs
      ↓
native verified package
~~~

Use when assurance value and long-term ownership justify the cost.

### Lane 4 — Generate by construction

The highest-leverage lane.

~~~text
declarative specification
      ↓
verified generator / verified combinators
      ↓
many implementations
      ↓
shared theorem schema
~~~

Candidate families:

- codecs from schemas;
- SDKs from OpenAPI;
- WIT adapters;
- validators from data models;
- state machines from transition descriptions;
- CLI parsers from command schemas;
- serialization/deriving from reflected types.

## 92. Portfolio algorithm

The Factory should not decide “rewrite everything”.

~~~text
for each required capability:
    if a mature foreign package is adequate:
        bind it
    if confidence is insufficient:
        characterize it
    if portability/native semantics justify ownership:
        port it
    if high assurance has strong ROI:
        build a verified replacement
    if many packages share one declarative structure:
        create one verified generator instead
~~~

Candidate priority:

~~~text
Priority
≈
downstream reuse
× ecosystem importance
× semantic tractability
× assurance value
× upstream stability
× license suitability
────────────────────────────────────────
implementation cost
× foreign complexity
× maintenance risk
~~~

## 93. PSpec / SpecCapsule

The most important new subsystem is a versioned, approved specification artifact.

Provisional structure:

~~~text
SpecCapsule {
  identity
  version

  interface
  semanticLaws
  requires
  ensures
  invariants

  effects
  capabilities
  errorModel
  resourceModel
  determinism

  foreignAssumptions
  environmentalAssumptions

  examples
  propertyOracles
  interoperabilityVectors

  securityProperties

  compatibilityPolicy
  deprecationPolicy

  performanceBudgets

  provenance
  sourceReferences
  licensePolicy

  requiredEvidence
  allowedTrust
}
~~~

Spec lifecycle:

~~~text
Draft
  ↓
AI critique / counterexamples / test-oracle analysis
  ↓
human or authorized-policy approval
  ↓
LOCKED SpecCapsule identity
  ↓
implementation/proof work
~~~

Any semantic change creates a new identity.

Automatic weakening detection flags:

- removed postconditions;
- stronger preconditions;
- removed invariants;
- broader exceptions;
- new unchecked foreign calls;
- new axioms;
- reduced target coverage;
- weakened resource/error guarantees.

## 94. Role-separated AI Workcell

Do not use one omnipotent agent.

Candidate roles:

1. Research/Source Agent;
2. Interface Agent;
3. Specification Agent;
4. Specification Adversary;
5. Implementation/Port Agent;
6. Proof Agent;
7. Test/Fuzz/Differential Agent;
8. Performance Agent;
9. Security/Trust Agent;
10. License/Provenance Agent;
11. Upstream Sync Agent;
12. Release/Audit Agent;
13. Orchestrator.

Default authority rules:

| Role | implementation | locked spec | new assumptions | proof acceptance |
|---|---:|---:|---:|---:|
| Spec Agent | no | proposal only | proposal only | no |
| Implementation Agent | yes | **no** | no | no |
| Proof Agent | proof/evidence only | **no** | **no** | no |
| Test Agent | tests | no | no | no |
| Orchestrator | delegated patches | no silent change | no silent change | no |
| PSKernel/checker | no | no | no | **check/accept only** |
| Human/policy approver | authorized | new revision | explicit approval | release decision |

The Proof Agent should follow the successful verifier-in-the-loop pattern now documented by Verus: give the agent the verifier and libraries, prohibit spec/executable weakening during proof work, prohibit assume/admit, and run a cheat/assumption gate.

## 95. EvidenceGraph-v1

EvidenceGraph is the common assurance language.

Candidate claim types:

~~~text
TypeClaim
SpecificationClaim
ProofClaim
BoundaryClaim
TranslationClaim
TestClaim
FuzzClaim
DifferentialClaim
PerformanceClaim
ProvenanceClaim
LicenseClaim
ReproducibilityClaim
CompatibilityClaim
~~~

Each claim records:

~~~text
claimId
subjectArtifact
property
evidenceArtifact
checkerOrOracle
assumptions
dependencyClaims
environmentIdentity
status
creationPolicy
~~~

No transitive overclaiming is allowed.

Example:

~~~text
ProofClaim:
  CheckedCore satisfies theorem T

TranslationClaim:
  JS artifact is differential-tested against VerifiedIR

BoundaryClaim:
  Node crypto API is assumed to satisfy model M
~~~

The UI cannot summarize this as “JS artifact formally verified” unless the evidence graph really supports that claim.

## 96. PackageRecipe-v1

Every factory package has a machine-readable recipe.

~~~text
PackageRecipe {
  packageId
  capability

  acquisitionMode:
    bind | characterize | port | replace | generate

  origin
  upstreamVersion
  upstreamCommit

  licensePolicy
  provenance

  specCapsule

  targetAssurance
  targets

  testPlan
  proofPlan
  performancePlan

  upstreamSyncPolicy
}
~~~

This makes initial generation maintainable over time.

## 97. Ecosystem bootstrap strategy

Grow bottom-up by reuse leverage.

### E0 — semantic foundation

Lean-compatible semantics, PSC compiler, kernel/provider, CheckedCore/VerifiedIR.

### E1 — portable foundation/stdlib

Prioritize data structures, strings/bytes, numeric helpers, comparisons, folds/iterators, parser combinators, codecs, testing/property libraries.

### E2 — generated data ecosystem

Build generators for JSON/schema codecs, validators, WIT, OpenAPI, command schemas, state systems.

This is the primary compounding layer.

### E3 — protocol/API ecosystem

HTTP models, URI/URL, headers, MIME, auth formats, generated SDKs.

### E4 — effects/platform libraries

Only after effect contracts stabilize: filesystem, networking, Task, Stream, Resource, clock/random, database interfaces.

### E5 — frameworks

Frameworks should emerge after the reusable library graph proves the application model.

### E6 — applications

Applications then consume the accumulated ecosystem.

## 98. Open-source migration policy

### Do not rewrite the world

Preferred progression:

~~~text
foreign coverage first
→ characterization
→ selective native ownership
→ selective verification
→ generator-driven replacement where high leverage
~~~

### Source-derived ports

When AI consumes source code for translation/porting:

- treat the result as source-derived;
- preserve applicable license/notices;
- record exact upstream commit;
- retain provenance;
- never call it “clean-room” merely because an LLM changed syntax.

The U.S. Copyright Office describes translations/adaptations as derivative-work examples while distinguishing copyrightable program expression from ideas/processes/logic. This document gives engineering policy, not legal advice.

### Independent/spec-driven replacement

Where strategically useful:

- use standards/public APIs/specifications as authoritative input;
- separate source-derived implementation material where policy requires;
- use behavioral test vectors/oracles only as permitted;
- document the process;
- obtain legal review for significant compatibility work.

Early research should favor clearly permissive licenses and simple provenance.

## 99. Generator-first ecosystem multiplication

The highest leverage is not “AI ports N libraries”.

It is:

> **Build one generator when one declarative model can produce N packages.**

Examples:

~~~text
OpenAPI generator → many SDKs
schema/codec generator → many serializers/validators
WIT generator → many component bindings
state-machine generator → many workflows
reflection deriving → many Eq/Ord/JSON/etc. implementations
~~~

This is the most credible mechanism for superlinear ecosystem growth.

Use the word **compounding**, not “exponential”, until measurements justify stronger claims.

## 100. ProofScript Verified Knowledge Base

Factory output should feed a provenance-tagged knowledge layer containing:

- checked theorem identities;
- locked SpecCapsules;
- verified combinators;
- package interfaces;
- EvidenceGraph claims;
- counterexamples;
- proof patterns;
- migration recipes;
- benchmark results.

AI retrieval should prefer checked/provenance-known knowledge over free-form generated historical text.

## 101. VEF-Core release workflow

~~~text
1. choose capability / PackageRecipe
2. acquire authoritative inputs
3. build InterfaceIR if foreign
4. draft SpecCapsule
5. adversarial spec review
6. approve/lock SpecCapsule
7. implementation/port/generator step
8. compile/typecheck
9. construct proof obligations
10. proof-agent loop
11. kernel replay/check
12. property/fuzz/differential tests
13. performance checks
14. assumption/trust delta
15. backend build
16. translation/conformance checks
17. EvidenceGraph assembly
18. SLSA/in-toto provenance
19. human/policy release gate
20. publish normal package + assurance bundle
~~~

Unresolved obligations remain visible; they do not silently disappear.

## 102. Feasibility scoring

The exact bounded VEF-Core design scores:

| Dimension | Weight | Score /10 |
|---|---:|---:|
| technical feasibility | 12 | 9.4 |
| formal soundness / TCB design | 10 | 9.6 |
| fit with current pskernel architecture | 8 | 9.5 |
| implementation-scope practicality | 8 | 8.8 |
| specification integrity architecture | 8 | 9.2 |
| AI automation practicality | 7 | 9.0 |
| ecosystem acceleration | 10 | 9.2 |
| interoperability / migration | 9 | 9.3 |
| auditability | 8 | 9.7 |
| backend correctness strategy | 5 | 8.8 |
| performance practicality | 4 | 8.7 |
| developer-product UX | 5 | 9.0 |
| maintainability / upstream sync | 4 | 9.1 |
| license/provenance manageability | 2 | 9.0 |
| **Weighted feasibility** | **100** | **9.23 / 10** |

Why >9 is defensible:

- no speculative breakthrough is required for the scoped product;
- kernel checking is mature;
- verifier-driven AI proof repair is demonstrated;
- verified generators have strong prior art;
- interface/package generators are routine engineering;
- property/fuzz/differential testing is mature;
- WIT/OpenAPI/schema normalizations have established patterns;
- EvidenceGraph/artifact hashing are deterministic data engineering;
- SLSA/in-toto already supply provenance standards;
- PSC already has or plans CheckedCore/VerifiedIR/InterfaceIR seams;
- the package scope avoids arbitrary UI/event-loop/dynamic-language semantics.

What remains below 9:

~~~text
general application framework                      ~6–8/10
arbitrary npm formal verification                  ~3/10
fully verified general backend chain               ~5–8/10
autonomous repository-scale general synthesis       ~5/10
automatic correctness of AI-generated specs         ~5/10
rewrite-all-software vision                         ~5–7/10
~~~

## 103. Evidence confidence

Architecture-class evidence confidence is approximately:

~~~text
7.3 / 10
~~~

because the difficult techniques already exist independently.

ProofScript-specific product evidence is much lower.

The next objective is to turn architecture confidence into repository-specific evidence.

## 104. Experiment 1 — Verified Codec Factory v0

~~~text
small declarative schema
→ SpecCapsule
→ generated PSC types
→ encode/decode
→ round-trip theorem
→ boundary/property tests
→ PSKernel check
→ VerifiedIR
→ JS + Wasm
→ npm package
→ EvidenceGraph
→ provenance
~~~

Success goals:

- after schema approval, low human review time for a small generated package;
- every proof obligation checked or explicitly unresolved;
- no hidden assumption increase;
- ordinary npm consumption;
- deterministic evidence replay;
- JS/Wasm agreement on reference corpus;
- schema changes invalidate only dependent evidence/artifacts;
- repeated schemas require materially less human work due to generator reuse.

## 105. Experiment 2 — OSS Port Workcell

Choose one small permissively licensed pure library.

Compare:

### Source-assisted port

~~~text
upstream source
→ AI PSC port
→ license/provenance carry-forward
→ differential tests
→ contracts/proofs
~~~

### Spec-driven replacement

~~~text
public API/spec
→ locked SpecCapsule
→ independent PSC implementation
→ public test vectors
→ selected proofs
~~~

Compare engineering time, proof effort, performance, maintenance, legal/provenance complexity, semantic fidelity, and upstream-update cost.

This experiment determines whether OSS rewriting is broadly scalable or only selectively valuable.

## 106. Experiment 3 — OpenAPI package multiplication

Build one generator and generate multiple SDK packages.

Measure:

~~~text
human effort SDK #1
human effort SDK #5
human effort SDK #20
~~~

along with spec review, assurance coverage, generated-code acceptance, package quality, and upstream spec-update cost.

This is the first real test of ecosystem compounding.

## 107. Research references added by this iteration

- Microsoft SymCrypt / Rust / Aeneas / Lean / AI: https://www.microsoft.com/en-us/research/blog/verifying-rust-cryptography-in-symcrypt-from-standards-to-code/
- Technical report: https://arxiv.org/abs/2609.15648
- Verus LLM proof workflow: https://verus-lang.github.io/verus/guide/llmforverusproof.html
- LeanDojo: https://leandojo.org/leandojo.html
- BRIDGE: https://leandojo.org/bridge.html
- P³: https://arxiv.org/abs/2608.09277
- Vero: https://arxiv.org/abs/2608.13522
- AI formal-spec generation: https://arxiv.org/abs/2601.12845
- EverParse: https://project-everest.github.io/everparse/
- Project Everest/HACL*: https://project-everest.github.io/
- Aeneas: https://github.com/AeneasVerif/aeneas
- Dafny: https://dafny.org/latest/
- CompCert: https://compcert.org/
- CakeML: https://cakeml.org/
- WIT: https://component-model.bytecodealliance.org/design/wit.html
- SLSA v1.2: https://slsa.dev/spec/v1.2/
- in-toto: https://in-toto.io/
- U.S. Copyright Office computer-program guidance: https://www.copyright.gov/register/tx-programs.html
- U.S. Copyright Office derivative-work guidance: https://www.copyright.gov/eco/help-limitation.html

## 108. Revised recommendation

Do **not** build a monolithic autonomous Verified Software Factory.

Build **VEF-Core as an evidence-centric ecosystem accelerator** whose first job is to make trustworthy packages cheap to:

~~~text
bind
characterize
port
replace/verify
generate by construction
~~~

Then expand only when package families prove the next layer worthwhile.

This retains the ambitious long-term vision while producing a first product whose feasibility exceeds 9/10 using techniques available today.



# Part XVII — Mainstream adoption vision: ProofScript as the JS/TS Trust Layer

**Status:** highest-scoring current mainstream-product hypothesis after another architecture-search loop.  
**Scope:** JS/TS/npm/Node/Web developers first; broader ecosystems remain later expansion.  
**Vision score:** **9.35 / 10**.  
**Architecture feasibility:** **9.18 / 10**.  
**Combined vision/feasibility:** **9.27 / 10**.  
**Current ProofScript-specific product evidence:** still materially lower than the architecture score.

## 109. Why VEF-Core alone was not enough

VEF-Core scores highly as a way to manufacture trustworthy package ecosystems, but by itself it is primarily a package-author/platform story.

Most web developers need a simpler answer:

> Why would I use ProofScript in my React, Next, Vite, Node, Express, Fastify, or ordinary TypeScript project tomorrow?

A full ProofScript application framework would answer that question only by asking the developer to switch too much infrastructure.

A full TypeScript replacement would create the same adoption problem from another direction.

The better answer is incremental:

> **Keep your framework. Keep npm. Keep TypeScript where it works. Add ProofScript exactly where stronger trust is valuable.**

---

## 110. Iteration history

| Iteration | Vision | Vision quality | Feasibility | Why it did/did not win |
|---|---|---:|---:|---|
| A | autonomous general verified factory | 8.5 | ~5.0 | too much depends on unsolved specification/autonomy problems |
| B | VEF-Core package factory | 9.0 | 9.23 | excellent ecosystem engine; less direct daily value for ordinary web developers |
| C | ProofScript-owned full web/app framework | 9.0 | ~8.0 | too much framework/runtime/UI scope and incumbent competition |
| D | ProofScript as TypeScript replacement | 8.8 | ~7.5 | migration/ecosystem cost too high |
| E | verified modules inside existing JS/TS apps | 9.25 | 9.12 | strong incremental wedge |
| F | **JS/TS Trust Layer + VEF-Core + optional local agent interface** | **9.35** | **9.18** | best balance of usefulness, switching cost, ecosystem leverage, assurance, and buildability |

The winning design changes the adoption question from:

~~~text
Should I rewrite my application in ProofScript?
~~~

to:

~~~text
Which parts of this application are valuable enough
to make more trustworthy?
~~~

---

## 111. Product sentence

> **ProofScript is the trust layer for JavaScript/TypeScript software: keep the web stack you already use, move selected domain logic into ProofScript when stronger guarantees are valuable, and consume the result as ordinary JS/TS packages.**

Long term, ProofScript may be used for entire applications.

It should not require that outcome to be useful.

---

## 112. The mainstream developer value ladder

A JS/TS developer should be able to receive increasing ProofScript value without making one giant commitment.

### Level 0 — consume a ProofScript package

The developer does not learn ProofScript.

~~~typescript
import { verifyToken } from "@proofscript-auth/token";
~~~

They receive ordinary:

- JavaScript/ESM;
- `.d.ts` declarations;
- source maps;
- package metadata;
- optional audit/evidence URL/artifact.

This is the lowest-friction adoption point.

### Level 1 — one local ProofScript package

Keep the application in JavaScript/TypeScript.

Example workspace:

~~~text
web-app/
  app/ or src/                 # React / Next / Vite / Node / TS
  packages/
    trusted-domain/
      src/
        pricing.ps
        policy.ps
      package.json
~~~

`psc watch` builds the package to ordinary JS + declarations.

The surrounding app imports it normally.

### Level 2 — specified module

Add contracts to selected functions.

~~~text
typed
→ specified
~~~

No theorem-proving expertise is required merely to state intent.

### Level 3 — verified properties

Prove only the properties whose value exceeds their proof cost.

~~~text
specified
→ selected checked properties
~~~

### Level 4 — ProofScript-heavy application

Only if the project receives enough value should more modules migrate.

This gives ProofScript a Kotlin-like incremental adoption path rather than a rewrite mandate.

---

## 113. Best first web-developer use cases

ProofScript should target logic where:

- bugs have business/security consequences;
- behavior is deterministic enough to specify;
- boundaries with UI/framework code are narrow.

High-value candidates:

- pricing, money, discounts, billing rules;
- authorization and permission policies;
- authentication/session state;
- form/schema validation;
- reducers and application state machines;
- parsers/serializers;
- data transformations;
- URL/protocol logic;
- feature eligibility/routing policy;
- API request/response codecs;
- SDK core logic;
- cryptographic/protocol wrapper logic;
- package/security policy.

Lower first priority:

- DOM manipulation;
- animation;
- framework-specific rendering;
- arbitrary browser plugin behavior;
- highly dynamic UI glue.

The first web story is therefore **verified domain logic**, not “ProofScript replaces React”.

---

## 114. Ordinary npm artifact contract

The primary adoption artifact should be a normal package.

Candidate build output:

~~~text
dist/
  index.js
  index.d.ts
  index.js.map
  proofscript.evidence.json
  proofscript.manifest.json
package.json
~~~

The package should use ordinary JS module/package conventions.

TypeScript already supports npm packages that bundle their generated declaration files. Node and modern bundlers consume standard ECMAScript modules.

This makes ProofScript output framework-independent.

### Consequence

ProofScript should not require a Vite/Next-specific compiler plugin for basic interoperability.

A plugin may later improve:

- direct `.ps` imports;
- hot reload;
- diagnostics overlay;
- IDE integration.

But the foundational integration route is:

> **compile to an ordinary package first.**

That is more portable and lowers product risk.

---

## 115. No-AI mode is mandatory

ProofScript must remain a good programming language when AI is completely disabled.

Core workflow:

~~~text
psc check
psc build
psc test
psc verify
psc audit
psc package
~~~

A developer can:

- write `.ps` manually;
- write contracts manually;
- write proofs manually or use deterministic tactics;
- create foreign bindings through deterministic InterfaceIR tooling;
- consume/publish packages;
- inspect evidence.

This is a hard product principle:

> **AI is an accelerator, never a usability prerequisite.**

If ProofScript is unpleasant without AI, the language/product is too complicated.

---

## 116. Optional local/open-source AI mode

The AI integration should not start by building another coding agent.

Existing open-source coding agents already provide:

- repository editing;
- terminal/tool invocation;
- Git workflows;
- IDE integration;
- local-model support.

Current examples include:

- Qwen Code;
- Continue;
- Aider;
- OpenHands;
- other OpenAI-compatible local-agent frontends.

Qwen Code can connect to local OpenAI-compatible endpoints such as Ollama, vLLM, and LM Studio. Continue documents a fully offline configuration with local models. Aider supports local models through Ollama and LM Studio. OpenHands supports local LLM servers, although its documentation warns that capable local agentic models generally require substantial hardware.

Therefore ProofScript should provide the **deterministic agent tools**, not own the model/runtime.

---

## 117. ProofScript Agent Interface

**Provisional name:** ProofScript Agent Interface / Agent Kit.

Candidate architecture:

~~~text
Qwen Code / Continue / Aider / OpenHands / other
                  │
          local or remote model
                  │
          agent tool protocol
                  │
       ┌──────────┼──────────┐
       ▼          ▼          ▼
   psc check   psc goal   psc audit
       │          │          │
       └──────────┼──────────┘
                  ▼
        deterministic PSC tools
                  │
             PSKernel
~~~

The agent adapter may be:

- MCP;
- stdio JSON RPC;
- CLI JSON;
- generated agent skill/rule files.

The protocol should remain model/provider neutral.

### Candidate tools

~~~text
proofscript.check
proofscript.build
proofscript.test
proofscript.goal
proofscript.typeOf
proofscript.explainDiagnostic
proofscript.spec.createDraft
proofscript.spec.diff
proofscript.spec.lockStatus
proofscript.assumptionDelta
proofscript.bridge.inspect
proofscript.bridge.generate
proofscript.verify
proofscript.audit
proofscript.replayEvidence
proofscript.package
~~~

These tools narrow agent tasks and provide structured feedback, reducing how much semantic reasoning must live inside the model.

---

## 118. Local AI usability tiers

Offline AI should be a **supported mode**, not an unrealistic promise that every laptop can run a frontier coding model.

### Tier A — AI off

Hardware:

- ordinary developer machine.

Capability:

- full deterministic ProofScript workflow.

Feasibility:

- very high.

### Tier B — lightweight local assist

Use a smaller local model for:

- explanation;
- boilerplate;
- one-file translation;
- test generation;
- simple proof repair;
- documentation.

Deterministic tools catch invalid output.

Capability depends strongly on model quality.

### Tier C — capable local coding agent

Use an open-weight coding model through Ollama/LM Studio/vLLM.

Current agent documentation commonly recommends substantial memory for strong local software-engineering agents. OpenHands currently recommends a model class requiring roughly 24 GB GPU memory for a strong local setup; Mistral's offline-agent guidance similarly recommends a 24 GB GPU for useful quantized long-context local models.

This is feasible for workstations, not every commodity laptop.

### Tier D — optional remote model

Users may choose a strong hosted model.

The trust architecture remains identical:

~~~text
model quality changes productivity
but
model provider never changes proof authority
~~~

This prevents the ProofScript product from being tied to one AI vendor.

---

## 119. Local-first privacy use case

ProofScript can have a particularly strong local/offline story for:

- security-sensitive code;
- proprietary business logic;
- regulated environments;
- air-gapped build networks;
- education/research without recurring API cost.

Candidate setup:

~~~text
local git repository
      +
local psc / PSKernel
      +
local package/cache mirror
      +
open-source agent
      +
local OpenAI-compatible model server
      ↓
no source-code prompts leave the machine
~~~

Build/proof replay should already support locked/offline inputs as part of the broader reproducibility architecture.

This is a useful feature, not the only supported AI architecture.

---

## 120. AI migration workflow for a TypeScript module

A candidate supervised workflow:

~~~text
existing src/domain/pricing.ts
          ↓
Interface Agent extracts public API
          ↓
tests/examples become characterization evidence
          ↓
Spec Agent drafts SpecCapsule
          ↓
human/adversary review
          ↓
LOCK SpecCapsule
          ↓
Implementation Agent writes pricing.ps
          ↓
differential tests vs existing TS
          ↓
Proof Agent discharges selected obligations
          ↓
PSKernel check
          ↓
psc package
          ↓
ordinary JS + .d.ts + evidence
          ↓
replace TS import
~~~

The old implementation may remain as a differential oracle until confidence is sufficient.

This is much more achievable than “AI rewrites my whole web app”.

---

## 121. Human-first migration workflow

The same migration must work without AI.

~~~text
1. identify one TS module
2. record public interface + expected behavior
3. write equivalent .ps module
4. use existing tests as black-box regression
5. add contracts if useful
6. prove selected properties
7. compile package
8. switch import
~~~

AI merely accelerates steps.

This makes the product resilient to model quality, cost, availability, policy, and hardware.

---

## 122. VEF-Core underneath mainstream adoption

The user-facing Trust Layer and VEF-Core reinforce one another.

~~~text
                 JS/TS application
                       │
              ProofScript module
                       │
                 package imports
                       │
               ProofScript ecosystem
                       ▲
                       │
                    VEF-Core
          ┌────────────┼────────────┐
          │            │            │
       foreign       native      generated
       bindings      ports       families
~~~

Ordinary users benefit from VEF-Core even when they never run Forge themselves.

This resembles TypeScript's strongest ecosystem strategy:

> consume the ecosystem immediately rather than requiring it to be recreated first.

---

## 123. Why not build ProofScript's own web framework first?

A new framework creates simultaneous competition against:

- React;
- Next;
- Vue;
- Svelte;
- Angular;
- Vite/build infrastructure;
- mature component ecosystems.

That does not exploit ProofScript's strongest differentiation.

The Trust Layer instead makes those frameworks **distribution channels** for ProofScript packages.

A ProofScript-native application framework remains a later possibility after:

- Task/Stream/Resource semantics stabilize;
- platform libraries mature;
- native package reuse is strong;
- users demonstrate demand.

---

## 124. Why this is more useful than a pure verification language

The product gives several user types value:

### User 1 — ordinary JS developer

Consumes a ProofScript-produced package from npm.

No proof knowledge required.

### User 2 — TypeScript application developer

Moves one error-prone business/domain module to ProofScript.

### User 3 — package author

Publishes JS + `.d.ts` + optional evidence.

### User 4 — security/fintech developer

Uses contracts/proofs aggressively.

### User 5 — AI-heavy developer

Uses a cloud/local coding agent with ProofScript checker feedback.

### User 6 — privacy-sensitive developer

Runs a local open-source agent and model entirely offline.

### User 7 — formal methods expert

Builds theorem libraries, tactics, generators, and high-assurance packages.

One architecture serves these users at different assurance depths.

---

## 125. Product commands

A coherent eventual surface might be:

~~~text
psc init
psc check
psc build
psc watch
psc test

psc spec
psc verify
psc audit

psc bridge
psc package
psc publish

psc agent serve
psc agent init
~~~

Do not make every command mandatory.

The ordinary web developer may use only:

~~~text
psc watch
psc test
~~~

while a verification-heavy package may use the whole stack.

---

## 126. Web developer reference application

A reference application should use an incumbent framework.

Recommended:

~~~text
React/Vite or Next frontend
+
Node API/server
+
ordinary npm dependencies
+
one ProofScript domain package
~~~

ProofScript package owns something meaningful such as:

- cart/pricing rules;
- permissions;
- validation/state transitions.

Demonstrate:

1. application runs with ordinary JS tooling;
2. ProofScript package exports accurate `.d.ts`;
3. source maps/debugging work;
4. ordinary TS tests call the package;
5. selected properties have checked proofs;
6. local agent can modify the module while checker/tests remain authoritative;
7. app works equally with AI disabled.

This is a much stronger adoption demo than a standalone ProofScript toy app.

---

## 127. Ecosystem bridge order for web use

Recommended order:

### B0 — native package output

ProofScript → standard ESM + `.d.ts`.

### B1 — manually declared foreign bindings

Enough for first experiments.

### B2 — deterministic WIT/OpenAPI/JSON Schema adapters

More structured than arbitrary TS.

### B3 — bounded `.d.ts` importer

Support common:

- functions;
- primitives;
- records;
- arrays;
- option-like shapes;
- callbacks;
- Promise adapters;
- enums/unions where modeled safely.

Reject unsupported dynamic patterns.

### B4 — package characterization tools

Generate tests/differential harnesses for foreign packages.

### B5 — deeper npm coverage

Add advanced forms only from real package demand.

Do not make arbitrary TypeScript type-system parity a prerequisite.

---

## 128. Performance policy for web adoption

For most domain/business logic, the first requirement is:

> generated code must be fast enough not to create a visible regression.

Do not require C/Rust performance.

Track:

- bundle size;
- startup cost;
- hot-path runtime;
- allocation behavior;
- bridge overhead;
- compile/watch latency.

ProofScript verification should not require a heavyweight runtime in the deployed JS package merely to preserve proof artifacts.

Proof-only information should erase where semantically valid.

---

## 129. Mainstream-product feasibility score

Target: JS/TS/web developers using existing frameworks.

| Dimension | Weight | Score /10 |
|---|---:|---:|
| target-user value | 12 | 9.4 |
| problem/solution fit | 10 | 9.3 |
| incremental adoption / switching cost | 12 | 9.7 |
| npm/JS ecosystem leverage | 10 | 9.7 |
| usefulness without AI | 8 | 9.2 |
| optional local/open AI practicality | 7 | 8.8 |
| assurance differentiation | 10 | 9.5 |
| architecture fit with pskernel/VEF-Core | 10 | 9.5 |
| implementation-scope feasibility | 8 | 8.9 |
| web developer UX potential | 5 | 9.0 |
| performance practicality | 4 | 9.0 |
| long-term durability | 4 | 9.2 |
| **Weighted combined score** | **100** | **9.27 / 10** |

### Separate headline scores

~~~text
Vision / desirability:          9.35 / 10
Architecture feasibility:       9.18 / 10
Combined:                       9.27 / 10
Architecture evidence:          ~7.8 / 10
Current ProofScript-specific
product evidence:               ~4.2 / 10
~~~

The last number matters.

The product is still to be built.

---

## 130. Why >9 is defensible for this vision

The vision deliberately reuses mature infrastructure:

- npm/package distribution;
- standard ESM;
- TypeScript declaration files;
- incumbent web frameworks;
- existing JS runtimes;
- existing open-source AI agents;
- local model servers using OpenAI-compatible APIs;
- Lean proof infrastructure;
- PSC/PSKernel/CheckedCore/VerifiedIR;
- VEF-Core package-generation architecture.

The first product does **not** require:

- a new UI framework;
- a new browser runtime;
- a new package registry;
- a frontier proprietary model;
- general autonomous software synthesis;
- complete npm formal verification;
- a fully formally verified backend.

This drastically lowers risk.

---

## 131. Research evidence for local/open agent integration

Current agent ecosystems already demonstrate the integration style ProofScript needs:

### Qwen Code

- open-source coding agent;
- terminal workflow;
- custom OpenAI-compatible providers;
- supports local servers including Ollama, vLLM, and LM Studio;
- project-level instruction files and agent configuration.

Reference:

- https://qwenlm.github.io/qwen-code-docs/en/users/configuration/model-providers/

### Continue

- open-source IDE/CLI coding-agent tooling;
- documents offline use with local models;
- model/rule/tool configuration is externalized.

References:

- https://docs.continue.dev/
- https://docs.continue.dev/guides/running-continue-without-internet

### Aider

- git-oriented open-source coding workflow;
- supports local models through Ollama and LM Studio;
- emphasizes repository maps, diffs, tests, and commits.

References:

- https://aider.chat/docs/
- https://aider.chat/docs/llms/ollama.html

### OpenHands

- open-source agent platform;
- supports locally hosted models;
- its documentation demonstrates that capable local agentic coding currently benefits from high-memory hardware.

Reference:

- https://github.com/OpenHands/docs/blob/main/openhands/usage/llms/local-llms.mdx

### Mistral local coding models

Mistral documents offline coding-agent use with locally served open models and OpenAI-compatible endpoints, while also showing the current hardware tradeoff.

Reference:

- https://docs.mistral.ai/vibe/code/cli/offline-models

### Design consequence

ProofScript should integrate through standardized deterministic tools and local APIs rather than lock the product to one of these agents.

---

## 132. Research evidence for JS/TS adoption mechanics

TypeScript explicitly prioritizes preserving JavaScript runtime behavior, recognizable JS output, cross-platform use, and ecosystem compatibility rather than replacing the runtime ecosystem.

TypeScript declaration files are designed to ship alongside ordinary npm packages.

Kotlin demonstrates the value of module-by-module migration while retaining Java/JVM infrastructure.

Flutter demonstrates the opposite adoption pattern: a language can gain pull from a compelling framework, but ProofScript currently gains more leverage by using existing web frameworks as distribution.

References:

- https://github.com/Microsoft/TypeScript/wiki/TypeScript-Design-Goals
- https://www.typescriptlang.org/docs/handbook/declaration-files/publishing.html
- https://kotlinlang.org/docs/mixing-java-kotlin-intellij.html
- https://kotlinlang.org/docs/java-interop.html
- https://dart.dev/multiplatform-apps
- https://vite.dev/guide/api-plugin.html

---

## 133. New recommended product sequence

### W0 — ordinary package contract

Prove PSC can reliably emit a consumable JS package with accurate declarations/source maps.

### W1 — local workspace adoption

Add one ProofScript package to an existing TypeScript web project.

No AI.

### W2 — verification UX

Make contracts, proof status, assumptions, and audit output understandable to ordinary developers.

### W3 — Bridge subset

Import enough npm/TS APIs for the reference project.

### W4 — agent interface

Expose deterministic compiler/spec/proof/audit tools through CLI JSON/MCP/stdio.

Integrate at least two existing open-source agents.

### W5 — fully local workflow

Demonstrate one agent with a local model server and no source/prompt network egress.

### W6 — VEF-Core packages

Consume/generated verified packages in the same reference web app.

### W7 — migration experiment

Move an existing TS domain module manually and with AI; compare effort and maintainability.

### W8 — broader web ecosystem

Only after evidence, deepen bundler/framework integrations.

---

## 134. Falsification gates

This vision should be downgraded if:

### T1 — package friction

Consuming a ProofScript module from TS is materially harder than an ordinary workspace/npm package.

### T2 — source-map/debugging failure

Developers cannot debug generated JS back to meaningful ProofScript source.

### T3 — bridge burden

Common npm dependencies require excessive handwritten binding work.

### T4 — verification burden

Meaningful contracts/proofs cost more than the target audience will tolerate.

### T5 — no-AI usability failure

Manual ProofScript development is unpleasant enough that AI becomes mandatory.

### T6 — local-agent mismatch

Offline agents are too weak for useful bounded tasks even with strong checker feedback.

This would not invalidate ProofScript; it would remove the local-agent product claim.

### T7 — performance/bundle regression

ProofScript modules cause unacceptable runtime/bundle costs for typical domain logic.

### T8 — evidence irrelevance

Developers do not understand or value the assurance information enough to affect adoption.

---

## 135. Revised mainstream vision

The strongest current adoption strategy is:

~~~text
              existing JS/TS ecosystem
                       │
                       │ keep
                       ▼
          React / Next / Vite / Node / npm
                       │
                ordinary imports
                       │
                       ▼
              ProofScript packages
                       │
            typed → specified → verified
                       │
           PSKernel / evidence graph
                       │
          ┌────────────┴────────────┐
          ▼                         ▼
      VEF-Core                  Agent Interface
 ecosystem acceleration     optional local/cloud AI
~~~

The immediate product does not ask developers to abandon JavaScript.

It gives them a new place to put the code where stronger guarantees matter.

This is currently the best >9/10 vision/feasibility combination found for making ProofScript useful to mainstream web developers with technology available today.


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


---

# Part XV — Verified Software Factory Feasibility Audit

## 69. Feasibility verdict

The **Verified Software Factory** idea is technically plausible, but only if the project separates several guarantees that are easy to conflate.

> **A scoped Verified Package Factory is achievable with current formal-methods technology and current-generation AI as an untrusted synthesis assistant. A general autonomous factory that generates, verifies, deploys, and maintains arbitrary real-world applications end-to-end is not yet demonstrated and should not be treated as an implementation commitment.**

Important pieces already exist independently:

- Lean demonstrates a small independently checkable logical kernel beneath rich elaboration and automation.
- Dafny demonstrates a verification-aware language with integrated specifications, automated verification, IDE tooling, and mainstream compilation targets.
- F*/Project Everest demonstrates verified libraries and generated parsers deployed in production systems.
- CompCert and CakeML demonstrate semantic-preserving and verified/self-hosted compilation.
- seL4 demonstrates production-scale functional correctness and, on selected targets, binary correctness.
- recent AI theorem-proving and verified-code-generation research demonstrates useful formal proof/code generation while still requiring machine checking and careful specification control.

The central uncertainty is therefore not whether the ingredients can exist. It is whether ProofScript can integrate them into a product whose **human trust cost per useful capability** is lower than incumbent workflows.

### 69.1 Feasibility by scope

| Scope | Feasibility now | Research judgment |
|---|---:|---|
| Verified pure/mostly-pure library package factory | **8.5/10** | strong first target |
| Verified parser/codec/protocol generator | **9.0/10** | strongest first vertical |
| AI-assisted program + proof generation for bounded modules | **7.0/10** | feasible with checker-in-the-loop |
| Schema/OpenAPI/WIT → typed package + tests + contracts | **8.0/10** | practical |
| Arbitrary npm/TypeScript package migration with meaningful assurance | **6.0/10** | feasible only with explicit foreign assumptions |
| Cross-platform application framework with gradual verification | **6.0/10** | plausible, large scope |
| Source-level proof carried soundly to deployed JS/native artifacts | **4.5/10 now; 8/10 long-term** | requires verified compilation or translation validation |
| End-to-end high-assurance Wasm package path | **6.5/10 now; 8.5/10 potential** | promising tighter execution target |
| Fully autonomous ecosystem generation | **4.5/10** | interesting hypothesis, weak evidence |
| General verified arbitrary-application factory | **4.0/10** | long-term research only |

### 69.2 Research decision

**Continue. Do not canonize the full factory.**

Recommended near-term interpretation:

> **ProofScript Forge is a candidate orchestration/product layer around PSC + Lean/PSKernel + checked artifacts + tests + provenance. Its first goal should be verified packages, not whole applications.**

---

## 70. Fit with the existing ProofScript architecture

The repository already describes:

~~~text
source
  -> elaboration
  -> pskernel
  -> CheckedCore
  -> erasure
  -> VerifiedIR
  -> target lowering
~~~

and a target-neutral VerifiedIR shared by TypeScript/JavaScript, Rust, and WebAssembly backends.

That is unusually compatible with the Factory idea because the Factory does **not** need to enter the semantic compiler or TCB.

Recommended architecture:

~~~text
                     UNTRUSTED PRODUCT LAYER

specifications / packages / schemas / docs / tests
                         |
                         v
                  Forge orchestration
                 /       |        \
             AI plan   AI code   AI proof
                 \       |        /
                         v
                    candidate .ps
                         |
────────────────── semantic boundary ──────────────────
                         |
                        PSC
               parse / resolve / elaborate
                         |
                         v
                 Lean-compatible core
                         |
              +----------+----------+
              |                     |
              v                     v
       Lean reference check      PSKernel
              |                     |
              +----------+----------+
                         |
                         v
                    CheckedCore
                         |
                       erasure
                         |
                         v
                    VerifiedIR
                         |
──────────────── executable boundary ──────────────────
              /          |           \
             v           v            v
            JS          Wasm         native
              \          |            /
               +--- validation/tests-+
                         |
                         v
              deployable package/artifact
                         |
                         v
               assurance/provenance manifest
~~~

Core rule:

> **Forge is not proof authority. PSC is not automatically proof authority. Backend emission is not automatically proof authority. Each assurance claim must identify the checker and assumptions that justify it.**

---

## 71. Assurance must be multidimensional

A single label such as “verified package” is too coarse.

### 71.1 Logical assurance

Question:

> Does a checked term prove the claimed proposition relative to explicit definitions and axioms?

Candidate mechanisms:

- Lean reference/kernel checking;
- PSKernel;
- independently replayed/exported proof artifacts;
- axiom/assumption inventory.

For important AI-generated proofs, separate the trusted theorem/specification from the untrusted solution and replay evidence independently.

### 71.2 Compilation assurance

Question:

> Does the deployed executable preserve the semantics of the checked program?

Kernel acceptance of source-level proof does **not** answer this.

Possible progression:

~~~text
ordinary backend + tests
→ translation validation
→ proved selected compiler passes
→ verified backend
~~~

CompCert and CakeML demonstrate that strong semantic-preservation guarantees are achievable, but they also show that this is a major engineering/research effort.

### 71.3 Boundary/environment assurance

Question:

> Do foreign libraries, OS APIs, databases, services, JavaScript objects, hardware, and other external systems actually satisfy the model used by the proof?

A `.d.ts` file, OpenAPI file, C header, or AI-generated model is not proof of runtime behavior.

Boundary evidence may include:

- explicit assumptions;
- runtime validators;
- conformance tests;
- differential tests;
- fuzz/property tests;
- protocol/schema validation;
- audited adapters;
- verified implementations where available.

### 71.4 Prefer an assurance vector over one ladder

The earlier `PS-A0` … `PS-A6` concept risks implying one-dimensional confidence.

A better research model is:

~~~text
logic:        unchecked | typed | specified | proved | independently-rechecked
compilation:  unvalidated | tested | translation-validated | proved
boundary:     opaque | assumed | tested | model-validated | verified
provenance:   unknown | recorded | reproducible | independently-replayed
~~~

Example:

~~~text
logic        = proved
compilation  = translation-validated
boundary     = tested
provenance   = reproducible
~~~

The exact vocabulary remains research work.

---

## 72. Roles of Lean 4, PSC, and PSKernel

### 72.1 Lean 4

Initial roles:

1. semantic reference for the pinned type theory;
2. bootstrap/reference implementation;
3. proof automation ecosystem;
4. cross-checker for ProofScript/PSKernel acceptance;
5. export/replay path for high-assurance proof validation.

Lean does not need to remain the normal user-facing ProofScript compiler forever.

### 72.2 PSC

PSC should remain the language/product compiler:

- parse/resolve/elaborate;
- generate proof obligations;
- call proof services;
- construct kernel-checkable declarations;
- produce CheckedCore;
- erase proof-only content;
- produce VerifiedIR;
- invoke backends/validators;
- produce audit/provenance metadata.

For proof soundness, PSC should be treated as an **untrusted producer of candidate core terms** whenever practical.

However, a buggy elaborator may still misinterpret the *statement* the user intended. High-assurance workflows therefore need a protected specification surface.

### 72.3 PSKernel

PSKernel should be the ProofScript-owned independent checking boundary.

During maturation, prefer dual checking:

~~~text
candidate core
   |       \
   |        +-> Lean/reference checker
   |
   +----------> PSKernel
~~~

Disagreement is failure.

Longer term, a small portable PSKernel can support package verification, CI, registries, browsers, and independent replay.

### 72.4 Trusted specification capsule

For high-assurance generated components, separate the specification from generated implementation/proof:

~~~text
SpecCapsule
  canonical contracts/propositions
  permitted axioms/assumptions
  expected public API
  environment/profile identity
  hashes of trusted models

Solution
  generated implementation
  generated proof
  generated tests
~~~

The generated solution cannot modify the trusted capsule.

---

## 73. AI should plan program and proof together

A naïve sequence:

~~~text
generate program
→ attempt proof
→ patch program
→ patch proof
→ repeat
~~~

can create implementations that are unnecessarily hard to verify.

Recent work on joint program-and-proof planning reports higher verified-code solve rates and lower cost/time than implementation-first planning on multiple benchmarks.

Forge should therefore research:

~~~text
specification
     ↓
joint program + proof plan
     ↓
implementation scaffold + proof scaffold
     ↓
checker feedback
     ↓
repair
~~~

Candidate AI jobs:

- model/API proposal;
- implementation;
- invariant/contract proposal;
- proof planning;
- proof/tactic generation;
- counterexample/checker-driven repair;
- property/test generation;
- migration/adaptation;
- provenance summaries.

AI outputs remain untrusted.

### 73.1 Specification generation is likely the central bottleneck

The Factory must not equate “AI-generated contract” with “correct intent.”

Recommended defenses:

- human review of high-level intent;
- trusted spec capsule;
- mutation-based specification-strength checks;
- property/fuzz tests;
- independent examples/oracles;
- trace/protocol conformance;
- explicit `AI-proposed, not human-approved` status.

The intended human role shifts toward reviewing **meaning**, not generated implementation lines.

---

## 74. Recommended first product: Verified Package Factory

The first release should deliberately exclude whole-application autonomy.

Target:

> **Given a bounded API/specification, generate or migrate one package, generate meaningful correctness obligations, discharge as many as possible, independently check accepted evidence, produce ordinary runtime artifacts, and emit a complete assurance manifest.**

### 74.1 Strongest first vertical: parsers/codecs/protocol data

Why:

- concrete reusable properties;
- round-trip and rejection laws are understandable;
- bounded state space relative to arbitrary applications;
- generated code can be benchmarked;
- F*/EverParse provides production precedent;
- resulting packages are useful to non-ProofScript users.

Candidate inputs:

- declarative schemas;
- JSON Schema;
- Protocol Buffers subset;
- CBOR/MessagePack-like format descriptions;
- protocol message grammars.

Candidate guarantees:

- `decode(encode(x)) = x` for admitted values;
- successful decode satisfies schema;
- malformed input cannot forge a valid value;
- length/bounds invariants;
- deterministic encoding;
- admitted model has no uncaught parser failure.

### 74.2 Second vertical: OpenAPI/SDK generation

~~~text
OpenAPI/schema
→ InterfaceIR
→ ProofScript models
→ validated codecs
→ client/server wrappers
→ contracts/tests
→ JS/npm package
~~~

The remote service remains a boundary assumption unless separately validated.

### 74.3 Later verticals

- authorization/state machines;
- deterministic financial logic;
- package/security logic;
- verified-primitive wrappers;
- compiler/serialization infrastructure.

---

## 75. Bridge strategy: schema-first before arbitrary TypeScript

Arbitrary `.d.ts` includes structural typing, overloads, dynamic objects, callbacks, optional/missing/undefined distinctions, declaration merging, and behaviors the declaration file cannot prove.

Recommended sequence:

~~~text
1. native ProofScript packages
2. explicit schemas (JSON Schema / OpenAPI)
3. WIT / protocol-oriented interfaces
4. bounded TypeScript declarations
5. broader npm shapes
~~~

`InterfaceIR` should preserve uncertainty rather than erase it.

Classify each foreign surface:

~~~text
native-representable
adapter-required
runtime-validated
opaque-handle
assumed
unsupported
~~~

No untracked `any` fallback.

---

## 76. The compilation last mile

This is the biggest gap between “source proof checked” and “software verified.”

### 76.1 Honest early claims

Early packages may claim:

~~~text
source property: machine-checked
compiler/backend: conformance-tested
foreign boundary: explicit/tested assumptions
~~~

They must not claim deployed artifact equivalence without evidence.

### 76.2 Translation validation is the recommended intermediate strategy

Instead of proving the whole compiler immediately:

1. keep CheckedCore → VerifiedIR small/deterministic;
2. define explicit VerifiedIR semantics;
3. validate transformations;
4. validate backend output where practical;
5. reject on validation failure.

### 76.3 Wasm may be the stronger assurance target while npm remains distribution

Strategic split:

- **JS/npm:** adoption/distribution ecosystem.
- **Wasm:** candidate tighter high-assurance execution target.

Possible package:

~~~text
ProofScript
   ↓
checked semantics
   ↓
validated/proved VerifiedIR → Wasm
   ↓
thin JS/npm wrapper
~~~

Compare this experimentally with direct JS emission.

### 76.4 Long-term verified backend

Only after product value is proven should ProofScript attempt CompCert/CakeML-class semantic-preservation proofs for a substantial backend.

---

## 77. Candidate Factory package artifact

Provisional package:

~~~text
package/
  src/
  dist/
  proof/
  tests/
  proofscript-assurance.json
~~~

Candidate manifest fields:

~~~text
language/profile identity
Standard environment digest
source hashes
specification capsule hash
CheckedCore hash
VerifiedIR hash
proof identities/hashes
checker identities/versions
axioms and explicit assumptions
foreign models and confidence class
compilation-assurance class
boundary-assurance class
test/fuzz/differential evidence
backend/toolchain identities
reproducibility metadata
AI/provider provenance where policy permits
unresolved obligations
known unsupported claims
~~~

Every claim should classify evidence as:

~~~text
proved
tested
assumed
unknown
unsupported
~~~

---

## 78. Implementation plan

### F0 — checker and artifact foundation

Before “AI Factory” branding:

- canonical proof/claim serialization;
- stable CheckedCore identity;
- stable VerifiedIR identity;
- PSKernel checked-session API;
- Lean ↔ PSKernel differential corpus;
- independent replay CLI;
- axiom/assumption reporting;
- package assurance manifest prototype.

**Exit:** a human-written package can produce independently replayable evidence.

### F1 — obligation service

- contract → proposition generation;
- obligation IDs;
- proof status database/cache;
- `specified` vs `verified` reporting;
- replay independent of the AI process.

**Exit:** contracts become durable obligations and checked receipts.

### F2 — AI proof worker

~~~text
goal + context
→ candidate proof/tactics
→ PSC/Lean elaboration
→ PSKernel/Lean check
→ structured error
→ retry
~~~

Start with human-written implementation and AI-generated proofs.

### F3 — joint program-and-proof worker

~~~text
trusted spec
→ joint plan
→ implementation + proof scaffold
→ checker feedback
→ repair
~~~

Benchmark against program-first generation.

### F4 — Verified Parser/Codec Factory

Inputs:

- bounded schema/format.

Outputs:

- ProofScript implementation;
- obligations;
- checked proofs;
- negative/fuzz corpus;
- JS and/or Wasm package;
- assurance manifest.

**Exit:** at least 10 non-toy generated/migrated packages with independently replayed guarantees.

### F5 — schema/OpenAPI Bridge

Add InterfaceIR import with explicit classification/assumptions.

**Exit:** generated package is consumed naturally from JS/TS while evidence remains inspectable.

### F6 — translation validation

Prioritize:

- CheckedCore → VerifiedIR erasure;
- VerifiedIR optimizations;
- Wasm lowering;
- later JS/native validation.

### F7 — ecosystem-compounding experiment

Build package N using accumulated verified libraries/theorems.

Measure:

- human specification/review time;
- discharge rate;
- reuse rate;
- maintenance/refactor cost;
- marginal human effort vs earlier packages.

### F8 — reconsider ProofScript App

Only after the package/factory evidence exists should the project decide whether a cross-platform application framework is the next highest-value investment.

---

## 79. Out of scope for Factory v1

Do not require:

- arbitrary UI generation;
- arbitrary distributed applications;
- full npm semantic verification;
- arbitrary foreign-code verification;
- whole-compiler correctness across every backend;
- verified OS/runtime;
- autonomous specification acceptance;
- automatic proof of every property;
- zero-human-review ecosystem generation.

---

## 80. Feasibility and practicality scorecard

These scores evaluate **current plan/evidence**, not a hypothetical finished system.

Scale: 0–5.

| Criterion | Weight | Current | Potential | Evidence confidence |
|---|---:|---:|---:|---:|
| Problem–solution fit | 13 | 4.2 | 4.6 | 3.0 |
| Differentiated wedge / language necessity | 7 | 4.2 | 4.6 | 2.5 |
| Semantic architecture | 10 | 4.4 | 4.8 | 3.0 |
| Practical usefulness / ergonomics | 9 | 2.3 | 4.3 | 1.5 |
| Performance / resource economics | 6 | 2.0 | 3.8 | 1.0 |
| Safety / correctness / TCB | 7 | 3.5 | 4.8 | 3.0 |
| Implementation feasibility | 6 | 3.2 | 4.1 | 2.5 |
| Developer product / tooling | 9 | 1.8 | 4.5 | 1.5 |
| Adoption / migration / interoperability | 12 | 2.0 | 4.4 | 1.5 |
| Ecosystem / distribution | 7 | 1.3 | 4.2 | 1.0 |
| Compatibility / evolution | 5 | 3.0 | 4.6 | 2.0 |
| Governance / sustainability | 3 | 1.2 | 4.0 | 1.0 |
| Future relevance | 4 | 4.5 | 4.8 | 3.5 |
| Novelty / defensibility | 2 | 4.3 | 4.6 | 3.0 |

Weighted result:

~~~text
Current evidence/readiness score: approximately 60 / 100
Potential architecture score:     approximately 89 / 100
Evidence confidence overall:       approximately 2.2 / 5
~~~

Interpretation: promising enough for serious engineering research; far from demonstrated product maturity.

### 80.1 Product-hypothesis scores

| Hypothesis | Score today | Recommendation |
|---|---:|---|
| Verified Package Factory | **8.2/10** | research/build now |
| Parser/Codec Factory | **9.0/10** | strongest first experiment |
| Forge + Bridge for schema/OpenAPI | **7.8/10** | next candidate |
| General npm migration factory | **6.0/10** | later, bounded shapes first |
| ProofScript App framework | **6.2/10** | defer until package evidence |
| High-assurance Wasm artifact path | **6.8/10** | strategically important |
| High-assurance direct JS artifact path | **5.0/10** | useful but harder last-mile story |
| Autonomous ecosystem generation | **4.5/10** | measure; do not claim |
| General arbitrary-app Verified Software Factory | **4.0/10** | long-term research only |

---

## 81. Biggest risks

### Specification fidelity
Proving the wrong specification remains the largest conceptual risk.

### Compiler semantic preservation
A buggy backend can invalidate source-level assurance.

### Effectful/foreign software
Real programs depend on systems outside the logic.

### Proof automation economics
Search may be expensive/brittle.

### AI ecosystem maintenance
Generating version 1 is easier than maintaining packages for years.

### TCB confusion
Users may assume “verified” covers more than it does.

All six risks must remain visible in scoring and assurance artifacts.

---

## 82. Research hypotheses to test

### H1 — Human trust cost decreases
Measure `human minutes per trusted capability`.

### H2 — Verified knowledge compounds
Package N should become cheaper because it reuses checked components/theorems.

### H3 — AI proof generation beats manual proof economics in target verticals
Measure human correction/review, not token count alone.

### H4 — Incremental migration is real
One package/module should deliver value without a rewrite.

### H5 — Assurance metadata is understandable
Reviewers should correctly distinguish proved/tested/assumed/unknown.

### H6 — Backend assurance can strengthen incrementally
Tested → translation-validated → proved must not require language redesign.

---

## 83. Pivot / stop conditions

Narrow or reject the Factory direction if repeated experiments show:

1. specification review dominates cost and does not improve with reusable models;
2. most useful proofs require expert intervention;
3. AI-generated packages are expensive to maintain;
4. foreign assumptions dominate useful applications;
5. backend assurance cannot improve without replacing the architecture;
6. interoperability destroys incremental-adoption economics;
7. assurance metadata creates false confidence;
8. Lean/Dafny/F*/Verus workflows achieve the same result much more cheaply;
9. ecosystem reuse does not lower marginal human effort;
10. PSKernel provides no meaningful independent/auditable advantage.

---

## 84. Feasibility conclusion

The Verified Software Factory should be treated as **credible research with a realistic scoped product path**, not a settled promise.

> **ProofScript should not try to make AI correct. It should make AI-generated software cheap to reject when unsupported, cheap to check when formally justified, and explicit about everything that remains assumed.**

A successful first Factory only needs to demonstrate:

~~~text
trusted specification
        ↓
AI-assisted package construction
        ↓
machine-checked core properties
        ↓
explicit compilation/boundary assumptions
        ↓
ordinary deployable package
        ↓
independent audit/replay
~~~

If ProofScript can do this for parser/codec packages and one second real vertical while lowering human effort, the project gains strong evidence for expanding Forge and Bridge.

---

## 85. Feasibility research sources

Key external precedent/evidence:

- Lean 4 kernel architecture and proof validation:
  - https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/
  - https://lean-lang.org/doc/reference/latest/ValidatingProofs/
  - https://lean-lang.org/faq/
- Dafny:
  - https://dafny.org/dafny/
- F* / Project Everest / HACL* / EverParse:
  - https://fstar-lang.org/
  - https://hacl-star.github.io/
- CompCert:
  - https://compcert.org/
- CakeML:
  - https://cakeml.org/
- seL4:
  - https://sel4.systems/Verification/proofs.html
- Verus:
  - https://verus-lang.github.io/verus/guide/
- Goedel-Prover:
  - https://arxiv.org/abs/2502.07640
- DeepSeek-Prover-V2:
  - https://arxiv.org/abs/2504.21801
- P3 joint program-and-proof planning:
  - https://arxiv.org/abs/2608.09277
- SpecSyn specification synthesis:
  - https://arxiv.org/abs/2604.21570
- LLM-generated Dafny verification annotations:
  - https://arxiv.org/abs/2601.12845

These sources establish that major ingredients are individually feasible. They do **not** establish that ProofScript's integrated Factory or ecosystem-compounding hypothesis will succeed; that remains the central empirical question.
