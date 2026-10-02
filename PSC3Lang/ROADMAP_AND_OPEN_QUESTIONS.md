# PSC3 Roadmap and Open Questions

Status: **prioritized research/implementation plan**

PSC3 should not attempt to implement the entire draft simultaneously.

The roadmap closes semantic foundations first, then validates them on full applications.

## 1. Phase 0 — establish governance

Deliver:
- PSC3 branch/folder;
- language constitution;
- decision-record template;
- feature proposal template;
- representative program corpus plan;
- compatibility matrix;
- claim vocabulary.

No language freeze yet.

## 2. Phase 1 — freeze ordinary native programming core

Priority decisions:
- lexical grammar;
- call syntax;
- declaration/body syntax;
- modules/import/export;
- structures/inductives/enums;
- patterns/exhaustiveness;
- function/named/default arguments;
- scalar operation matrix;
- Option/Result;
- local mutation lowering;
- total versus partial declarations.

Acceptance applications:
- CLI;
- data-processing library;
- small npm library.

## 3. Phase 2 — packages and JavaScript application platform

Deliver:
- project manifest/lock;
- direct ESM JS backend;
- .d.ts generation;
- source maps;
- npm package consumption;
- .d.ts binding generator;
- JSON/runtime codecs;
- Node/browser platform adapters;
- formatter/LSP baseline.

Acceptance:
- PSC-generated npm package consumed by TypeScript;
- Node/Bun/Deno application where supported;
- browser application built through an existing bundler.

## 4. Phase 3 — theorem-prover usability

Deliver:
- structured proof terms;
- robust rw;
- mature simp;
- dependent cases/induction;
- typeclass/coercion explanation;
- universes;
- classical/noncomputable profile;
- theorem docs/goals.

Acceptance:
- nontrivial theorem library;
- imported/reused Lean subset examples;
- negative malformed/unsound tactic tests.

## 5. Phase 4 — first-class verification

Deliver:
- requires/ensures;
- final program-spec theorem binding;
- assert;
- loop invariants;
- decreasing;
- specification registry;
- assumption reporting;
- runtime-check separation;
- spec dependency graph.

Acceptance:
- verified data structure;
- verified codec/parser;
- deliberate weak/false contract tests;
- AI repair/tampering benchmark.

## 6. Phase 5 — effects/resources/application maturity

Research/freeze:
- application effect model;
- Resource;
- typed errors;
- partial correctness;
- host capability interface.

Acceptance:
- file/network application;
- transaction/resource cleanup tests;
- capability-denial tests.

## 7. Phase 6 — Task/structured concurrency

Freeze:
- child scope;
- cancellation;
- failure;
- race;
- timeout;
- detached tasks;
- resource cleanup interaction.

Acceptance:
- HTTP server;
- concurrent worker application;
- cancellation stress suite;
- JS/Wasm profile behavior.

Do not standardize async syntax independently of these semantics.

## 8. Phase 7 — .psx

Deliver:
- markup parser;
- typed props;
- children;
- events;
- source maps;
- formatter/LSP;
- React adapter;
- framework-neutral/SSR or DOM adapter.

Acceptance:
- nontrivial browser application;
- npm UI library;
- async data/state example.

## 9. Phase 8 — direct WebAssembly

Deliver:
- bounded RuntimeIR subset;
- direct Wasm lowering;
- exact scalar/ADT runtime;
- WIT/component exports;
- WASI capability adapters;
- differential test suite.

Acceptance:
- pure computation module;
- Wasm component;
- host integration;
- resource/error cases.

## 10. Phase 9 — compiler-preservation assurance

Progressively establish:
- source/Core relation;
- erasure correctness;
- RuntimeIR semantics;
- JS lowering preservation;
- Wasm lowering preservation;
- serializer/artifact binding;
- runtime helper correctness or explicit assumptions.

Use proof-producing passes and translation validators where appropriate.

This is incremental. PSC3 need not delay all application use until every theorem is complete, but claims must remain scoped.

## 11. Phase 10 — self-hosting and ecosystem scale

Targets:
- PSC3 compiler written in stable PSC subset;
- actual generated compiler execution;
- fixed-point evidence;
- packed toolchain;
- large project benchmarks;
- package registry/ecosystem strategy.

Self-hosting is not a substitute for the previous semantic/preservation work.

# Open questions

## Q1. Native function body syntax

Candidates:
- expression after =;
- braced expression body;
- both under simple rules.

Need usability/parser/formatter study.

## Q2. Semicolon policy

Avoid JavaScript ASI complexity.

Determine whether separators are:
- newline/structural grammar;
- formatter-inserted explicit separators;
- a simpler terminator rule.

## Q3. Canonical declaration vocabulary

Should native application style prefer:
- function/const;
- def/let;
- one unified declaration?

Retaining migration aliases is separate from selecting the teaching/default style.

## Q4. Optional field/chaining sugar

Need precise Option-only semantics and chaining/evaluation rules.

## Q5. Error propagation syntax

Compare:
- try expression;
- postfix ?;
- do-binding sugar;
- pattern-based explicit handling.

Optimize for readability and error messages rather than language-fashion alignment.

## Q6. Partial-program logic

What is the standard verified claim for nonterminating/long-running/effectful applications?

Candidates:
- partial correctness;
- trace/safety semantics;
- effect-specific logics.

## Q7. Application effect

Do full apps use one conventional App effect, explicit capability records, an effect row, or a combination?

Avoid hiding capabilities.

## Q8. Resource syntax

Freeze cleanup behavior before spelling.

## Q9. Structured concurrency

Specify cancellation/failure/lifetime before async becomes stable.

## Q10. Dependent structure update

Define legal retained/replaced fields and diagnostics.

## Q11. Native instance search

How close to Lean should .ps remain versus a stricter deterministic ambiguity policy?

## Q12. Coercion limits

Freeze chain depth, search scope and ambiguity rules.

## Q13. Controlled notation

How much notation is necessary for theorem/math readability without reintroducing a highly dynamic parser?

## Q14. Plugin capability model

Need:
- API versions;
- permissions;
- deterministic build requirements;
- cache/provenance;
- proof authority prohibition.

## Q15. JS object interop

How should generated bindings represent large structural APIs without making native PSC structurally typed?

## Q16. Function/callback foreign lifetimes

Need a safe model for retained/reentrant JS callbacks.

## Q17. Wasm memory model

Select initial:
- linear memory;
- GC;
- mixed;
- Component Model resource strategy.

## Q18. String semantics

Freeze Char/String indexing/iteration and Unicode relationship.

## Q19. Float semantics

Freeze NaN/signed-zero/conversion/optimization behavior.

## Q20. Package manifest names/format

Validate proofscript.json/lock versus a more concise name and whether a textual DSL is justified.

## Q21. Build profiles

How many standard profiles are needed without recreating tsconfig complexity?

## Q22. Lean upgrade cadence

Stable-version policy and compatibility testing cost.

## Q23. .psx component abstraction

What minimal generic interface permits React and non-React targets without lowest-common-denominator design?

## Q24. UI effects/state

How much belongs in framework libraries versus PSC platform conventions?

## Q25. Compiler preservation target

Define exact first theorem:
- pure terminating subset;
- source->RuntimeIR;
- RuntimeIR->JS;
- exact emitted artifact.

Pick a tractable vertical slice rather than a universal theorem.

# Release criteria for a PSC3 freeze candidate

A freeze candidate should require:

- all foundational scalar/evaluation rules closed;
- native grammar executable and formatter-stable;
- module/package semantics closed;
- error/effect/resource model closed for the Standard profile;
- no unresolved meaning behind common syntax;
- representative application corpus passes;
- theorem corpus passes;
- verification corpus passes;
- .lean compatibility matrix measured against pinned stable Lean;
- JS full-app route production-tested;
- Wasm status explicitly scoped;
- assumptions/claim UI implemented;
- migration path from PSC2 tested;
- every remaining open question explicitly deferred to a later profile/edition.

"Large specification written" is not a freeze criterion.

"Compiler self-hosts" is not by itself a freeze criterion.

The language freezes when its important interactions are understood.
