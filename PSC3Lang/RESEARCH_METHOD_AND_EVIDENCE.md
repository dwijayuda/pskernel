# PSC3 Research Method and Evidence

Status: **methodology draft**

PSC3 should be designed through explicit hypotheses, competing alternatives, executable examples, real-program studies and conformance evidence.

Feature popularity is useful input. It is not sufficient justification.

## 1. Evidence classes

PSC3 design work uses five evidence classes.

### A. Ecosystem evidence

Questions:
- What do TypeScript/JavaScript developers actually use?
- What causes recurring friction?
- Which toolchain assumptions are now normal?
- Which framework patterns are stable enough to inform a language?

Sources include official language/runtime documentation, ecosystem surveys and representative open-source code.

Survey data must be labeled as survey evidence rather than treated as a census.

### B. Language precedent

Study Lean, TypeScript, Go, Rust, ReScript, Gleam, F*, Verus, Koka, Dafny and other relevant systems.

The purpose is not to copy features. It is to understand:
- what problem a mechanism solves;
- what complexity it creates;
- which trust assumptions it introduces;
- how it behaves at scale.

### C. Formal model evidence

High-risk semantic decisions should have small models before production implementation where practical.

Priority areas:
- partiality and termination;
- effects and cancellation;
- dependent structure update;
- pattern/refinement semantics;
- instance/coercion resolution;
- erasure;
- RuntimeIR-to-target preservation.

### D. User/task evidence

Evaluate representative developers on tasks:
- reading code;
- writing code;
- diagnosing failures;
- refactoring;
- adding a contract;
- repairing a proof;
- integrating an npm package;
- changing a requirement.

Measure misunderstanding and friction, not only preference.

### E. Implementation evidence

A feature is not complete because its prose looks coherent.

Evidence should include:
- parser/formatter tests;
- positive and negative elaboration tests;
- kernel rejection cases;
- runtime conformance;
- cross-target differential behavior;
- representative applications;
- performance/latency measurements.

## 2. Required feature proposal template

Every significant PSC3 feature proposal should contain:

~~~text
Problem
Representative use cases
Existing-language evidence
Alternative A
Alternative B
No-new-feature alternative
Chosen design
Why alternatives were rejected
Interaction matrix
Semantic lowering
Trust impact
JS impact
Wasm impact
Tooling/diagnostic requirements
Migration impact
Conformance tests
Open questions
~~~

A proposal may be accepted as a draft before every item is implemented, but missing evidence must stay visible.

## 3. Feature scoring rubric

Use a qualitative scorecard rather than feature-count comparison.

Questions:
- Adoption value: does this remove common real friction?
- Orthogonality: is it one reusable mechanism?
- Predictability: can users infer its behavior locally?
- Semantic cost: how much new meaning is introduced?
- Proof cost: does it complicate logical reasoning?
- Runtime cost: does it complicate portable execution?
- Tooling cost: can formatter/LSP/AI tooling support it well?
- Interop value: does it improve JS/Lean ecosystem use?
- Migration cost: does it disrupt existing PSC programs?
- Long-term stability: is the concept likely to remain coherent?

A feature with high adoption value but severe compositional complexity may still be rejected or moved to a library/profile.

## 4. Representative PSC3 corpus

The language must be tested on more than its compiler.

### Corpus A — CLI application

Requirements:
- files;
- text/bytes;
- JSON;
- command-line arguments;
- typed errors;
- resources;
- tests;
- package distribution.

### Corpus B — web/API service

Requirements:
- routing;
- JSON codecs;
- async;
- cancellation;
- database/network capabilities;
- configuration;
- logging;
- validation;
- contract boundaries.

### Corpus C — browser application

Requirements:
- DOM or UI framework;
- .psx;
- events;
- async data;
- state;
- npm packages;
- bundler compatibility;
- source maps.

### Corpus D — npm library

Requirements:
- clean ESM exports;
- generated .d.ts;
- external TypeScript consumer;
- semver API change;
- tree shaking;
- runtime boundary validation.

### Corpus E — verified algorithm/data structure

Requirements:
- invariants;
- recursion;
- executable proofs/contracts;
- performance-sensitive implementation;
- deliberate bug mutations.

### Corpus F — theorem/math library

Requirements:
- universes;
- dependent abstractions;
- typeclasses;
- notation;
- simp;
- induction;
- classical/noncomputable material.

### Corpus G — compiler/tooling package

Requirements:
- large module graph;
- parser;
- state/error effects;
- Meta programming;
- performance;
- self-hosting.

A language feature that makes one corpus elegant but seriously damages several others deserves reconsideration.

## 5. Interaction testing

PSC3 should maintain a feature-interaction matrix.

Important combinations include:
- named/default arguments × dependent binders;
- record update × dependent fields;
- method notation × coercions × instances;
- local mutation × closures;
- mutation × exceptions/errors;
- cancellation × resource cleanup;
- partiality × optimization;
- proof erasure × dependent data;
- imports × scoped instances;
- npm interop × runtime validation;
- .psx components × effects;
- async × contracts.

At least one executable test should cover every accepted high-risk interaction.

## 6. Specification-as-tests

Every normative language-reference example should become:
- a positive parser/elaboration/runtime test;
- a negative test where rejection is part of the rule; or
- a proof/conformance test where semantics is claimed.

Examples must not rot independently from the compiler.

## 7. Usability research

PSC3 should run formative studies throughout design rather than one final usability test.

Suggested tasks:
- identify the type/error in a small program;
- explain which method/instance was selected;
- modify a structure with a dependent invariant;
- wrap an untrusted npm function safely;
- convert an ordinary function into a verified one;
- interpret a failed VC;
- review an AI-generated patch that weakens a contract.

Metrics:
- completion time;
- semantic mistakes;
- number of annotations;
- diagnostic usefulness;
- confidence calibration;
- proof repair cost.

## 8. AI-agent evaluation

AI performance is a separate research axis.

An agent benchmark should include:
- nonexistent API attempts;
- wrong but type-correct algorithms;
- precondition strengthening to evade hard cases;
- postcondition weakening;
- specification dependency changes;
- hidden trusted assumptions;
- FFI misuse;
- incorrect proof candidates;
- backend-specific semantic assumptions.

Report:
- incorrect acceptance rate;
- useful completion rate;
- specification-bypass rate;
- model/tool budget;
- human intervention;
- unresolved/unsupported outcomes.

An agent timeout or failure is not evidence that the program is incorrect.

## 9. Decision records

Every significant accepted/rejected design should receive a short decision record.

Required fields:

~~~text
Decision
Date
Status
Context
Alternatives
Chosen rule
Consequences
Migration impact
Evidence to revisit
~~~

This prevents repeated redesign based only on lost conversational context.

## 10. Freeze discipline

PSC3 should freeze in layers.

Suggested order:
1. lexical/native module basics;
2. scalar/data/evaluation semantics;
3. error/effect/resource model;
4. functions/patterns/refinement;
5. packages/FFI;
6. theorem/verification model;
7. async;
8. .psx;
9. extension/plugin interfaces;
10. compiler-preservation profiles.

A surface syntax should not freeze before the semantic question it represents is understood.

## 11. Research outputs, not research accumulation

Research is complete only when it produces one of:
- an accepted decision;
- an explicit rejection;
- a bounded experiment;
- a deferred question with criteria for reopening it.

PSC3 should avoid an ever-growing collection of comparison notes that never constrain the language.
