# ProofScript Programming Language — Identity and Plans

**Status:** strategic identity and planning document; research-oriented; not a language specification and not implementation-conformance evidence.

**Repository role:** this document explains what ProofScript is trying to become, why it may deserve to exist, what product/adoption hypotheses are being explored, what must remain invariant, what remains undecided, and how the project should be evaluated.

**Current language context:** ProofScript language edition `ps-0.9-r3`; current compiler milestone PSC2 / `psc2-compiler-v1`; Lean-compatible checked semantics remain the foundation.

**Interpretation rule:** Identity, trust principles, and semantic boundaries describe the intended direction. Product names, frameworks, roadmap sequencing, adoption strategy, assurance levels, AI ecosystem-generation ideas, and target markets are research hypotheses that must change when evidence contradicts them.

**Exploration rule:** `ProofScript Forge`, `ProofScript App`, `ProofScript Bridge`, the assurance-level model, and the “verified ecosystem factory” concept are provisional research names/models. They are not adopted architecture or release commitments.

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

# Part VI — Exploratory killer-product research

## 19. Why ProofScript may need a killer product

Language history suggests that adoption often comes from more than intrinsic language design.

Current research lessons:

- TypeScript gained leverage by preserving JavaScript runtime behavior/ecosystem and adding static tooling.
- Kotlin makes Java interoperability and gradual migration first-class.
- Dart's strongest current product story is tightly associated with Flutter's single-codebase multiplatform application model.

ProofScript should study these **adoption mechanics**, not copy their products literally.

A current hypothesis is that ProofScript needs a daily-use product whose value is easier to understand than “a better language specification.”

This is not yet a decision.

## 20. Candidate ProofScript Forge — Verified Software Foundry

**Exploratory hypothesis only.**

A provisional `ProofScript Forge` could attempt to turn existing knowledge/artifacts into increasingly assured ProofScript packages.

Candidate inputs:

- ProofScript packages;
- TS/JS packages and `.d.ts`;
- OpenAPI / JSON Schema;
- Protocol Buffers / WebIDL / WIT;
- foreign source/headers where sound modeling exists;
- tests/examples/docs/specifications.

Possible workflow:

~~~text
existing artifact/specification
          ↓
interface normalization
          ↓
proposed native model/API
          ↓
AI-generated implementation/tests/contracts
          ↓
proof obligations
          ↓
automation / AI proof attempts
          ↓
checker / PSKernel
          ↓
checked evidence + explicit assumptions
          ↓
runtime/package outputs + audit bundle
~~~

The research claim is **not** “AI makes libraries correct.”

The research claim is:

> AI might lower the marginal human cost of producing trustworthy capabilities when generated implementation and proof attempts are checked and assumptions remain explicit.

## 21. Specification truth remains a hard problem

Formal proof only proves a proposition relative to its model and assumptions.

Therefore Forge-like workflows must distinguish:

~~~text
logical correctness against a model
≠
truth of the model about the external world
~~~

A verified wrapper can still model a foreign library incorrectly.

A proof can satisfy the wrong specification.

Foreign assumptions, specification provenance, runtime tests, and environmental claims must stay visible.

## 22. Candidate assurance levels

A provisional vocabulary worth testing:

| Candidate | Tentative meaning |
|---|---|
| `PS-A0 Foreign` | opaque foreign/assumption boundary |
| `PS-A1 Typed` | represented and typechecked |
| `PS-A2 Tested` | conformance/property/differential/fuzz evidence |
| `PS-A3 Specified` | explicit contracts/invariants |
| `PS-A4 Verified Core` | checked proof of selected core properties |
| `PS-A5 Verified Boundary` | selected boundary/model claims also validated |
| `PS-A6 Audited/Reproducible` | assurance + build/dependency/provenance reproducible |

This may be useful or may create false confidence. It must be tested before standardization.

## 23. Candidate ecosystem-compounding hypothesis

Potential flywheel:

~~~text
small checked foundation
        ↓
AI-assisted packages
        ↓
reusable code + theorems + models + contracts
        ↓
future packages reuse more trusted components
        ↓
lower marginal human effort
        ↓
more reusable verified knowledge
        ↺
~~~

Do **not** claim “exponential ecosystem growth” without evidence.

The bottleneck may simply move to:

- specification review;
- foreign-model validation;
- proof search;
- performance engineering;
- maintenance;
- API design.

The measurable research question is:

> **Does human effort per trusted capability materially decrease as reusable checked components accumulate?**

## 24. Provisional product trio

Three concepts are worth comparing:

1. **ProofScript Forge** — migration/generation/specification/testing/proof/audit workflow.
2. **ProofScript App** — candidate cross-platform application/effect framework.
3. **ProofScript Bridge** — incremental migration/interoperability with existing ecosystems.

Names and boundaries are provisional.

## 25. Candidate ProofScript App framework

ProofScript may eventually need a compelling framework, but should not prematurely build a Flutter competitor.

A candidate application model could explore library abstractions such as:

~~~text
App caps err result
Fiber caps err result
Exit err result
RuntimeFault
Resource caps err value
Stream caps err item
~~~

with HTTP, JSON, CLI, filesystem, networking, time, randomness, logging, metrics, database, serialization, resource, concurrency, and stream packages.

Research question:

> Does this produce one coherent cross-platform application model while keeping core language semantics small?

UI/`.psx` should remain later work unless evidence shows it is the strongest wedge.

## 26. Competing product-sequencing hypotheses

| Hypothesis | First product | Strength | Main risk |
|---|---|---|---|
| Forge-first | verified package foundry | directly exploits AI + TCB story | specification/proof bottleneck |
| Bridge-first | migration/interoperability | lowers adoption risk quickly | may feel like tooling only |
| Framework-first | ProofScript App | gives a concrete application reason | enormous scope |
| Verified-library-first | a few exceptional packages | narrow/measurable | may lack daily-use product pull |
| Hybrid | Forge + one vertical + Bridge | tests migration and compounding | coordination complexity |

No row is canonical.

---

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
