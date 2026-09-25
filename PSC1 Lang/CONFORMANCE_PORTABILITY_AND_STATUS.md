# PSC1 Conformance, Portability, and Status

Status: **implementation/assurance companion**

Baseline: `main@165468c7f195c60906075e774543c1e65b3518f1`.

This document separates language requirements from current implementation
evidence. It intentionally avoids invented completion percentages.

## 1. Conformance dimensions

PSC1 conformance is multi-dimensional. A feature may be implemented in one
layer and still be incomplete as a language capability.

Use these dimensions:

| Dimension | Question |
| --- | --- |
| Source | Is the syntax accepted/rejected deterministically? |
| AST | Is the construct represented without backend text tricks? |
| Canonicalization | Can it be printed/lowered canonically where promised? |
| Elaboration | Does it receive Lean-compatible typing/elaboration? |
| Kernel | Does pskernel re-admit the resulting declarations/proofs? |
| CheckedCore | Is there one semantic handoff? |
| Erasure | Is runtime/proof relevance handled correctly? |
| VerifiedIR | Is executable meaning target-neutral? |
| Backend | Is target code emitted without semantic shortcuts? |
| Execution | Does the result behave correctly? |
| Negative gate | Do unsupported forms fail closed? |
| Assurance | What exact claim level/evidence exists? |

A parser-only implementation does not close a runtime feature.

A backend-only implementation does not create a language feature.

## 2. Repository claim levels

The v0.7 study reference uses a useful claim ladder:

| Level | Meaning |
| --- | --- |
| S1 | specified |
| S2 | reference-proved |
| S3 | production-refined/certification-compared |
| S4 | connected to pinned formal model |
| S5 | correspondence with exact pinned official implementation |

PSC1 documentation should retain the discipline even where current repository
gates use different names.

Do not collapse empirical differential evidence, pskernel admission, and formal
equivalence into one claim.

## 3. Source feature registry

### 3.1 Core v0.7/v0.6.1 owned forms retained by PSC1

| ID | Class | Surface | Canonical meaning | PSC1 status |
| --- | --- | --- | --- | --- |
| D-CALL | D | `f(x, y)` | curried application | retained |
| D-EXPLICIT-PARAMS | D | `(x : A, y : B)` in owned headers | ordered binders | retained |
| D-DECL-SEMI | D | declaration `;` | owned declaration boundary | retained |
| D-CONST-ALIAS | D | `const x : T := e;` | parameterless `def` | REQUIRED |
| D-FUNCTION-ALIAS | D | `function f(x : A) ...` | parameterized `def` | REQUIRED |
| E-IF-BRACE | E | `if (c) {t} else {e}` | ordinary conditional | retained |
| E-STRUCT-BODY | E | braced structure body | structure declaration | REQUIRED data capability |
| E-CLASS-BODY | E | braced class body | typeclass declaration | bounded required capability |
| E-INDUCTIVE-BODY | E | braced constructor body | inductive declaration | REQUIRED data capability |
| E-MATCH-BODY | E | braced alternatives | ordinary match | REQUIRED |
| E-WHERE-BODY | E | braced local declarations | local declarations | retained; recursion conveniences can be optional |

### 3.2 Current repository extension

| ID | Class | Surface | Meaning | Status |
| --- | --- | --- | --- | --- |
| D-EXTERN-FFI | repository D extension | `extern function ... from "pkg" import name;` | checked runtime assumption + ESM binding metadata | bounded host-boundary extension |

D-EXTERN-FFI is intentionally identified as post-v0.7 repository evolution.
It must not be described as though it came from the old v0.7 registry.

## 4. Declaration alias conformance gate

Before SH7 freeze, all of the following must be executable facts:

1. equivalent `def f(...)` and `function f(...)` produce equal checked-core
   fingerprints;
2. equivalent parameterless `def x` and `const x` produce equal
   checked-core fingerprints;
3. their executable forms produce equal VerifiedIR fingerprints;
4. `const` with declaration parameters is rejected;
5. `function` without an explicit parameter group is rejected;
6. canonical Lean lowering emits `def`;
7. alias spelling does not change runtime behavior or proof authority.

The aliases therefore add ergonomics, not semantic surface area.

## 5. Required PSC1 freeze matrix

The controlling self-host plan defines the following as required capability
families.

| Family | Requirement |
| --- | --- |
| definitions/functions | `def`, aliases, lambdas, application, `let` |
| control | ordinary `if`, single-scrutinee `match` |
| data | structures, inductives, constructors, projections |
| scalars | complete frozen PSC1 scalar vocabulary |
| collections | List/Option/Prod/Array/ordered Map/Set + typed error ADT capability |
| dependent core | Pi, Prop, proof terms, universes, implicits, mvars, defeq |
| typeclasses | compiler-required class/instance/Decidable subset |
| recursion | structural + controlled executable partial |
| effects | concrete reader/state/error + do/pure/bind/recovery/rollback |
| project | imports/modules/qualified names/deterministic resolution |
| compiler data | names, environments, AST, tokens, spans, diagnostics |
| bridge | canonical JSON + versioned pskernel protocol |
| dual source | canonical supported Lean/ProofScript translation equivalence |
| execution | checked core -> erasure -> VerifiedIR -> target path |

Each row is a capability family. The exact frozen source syntax is the subset
actually used/gated at SH7, not every convenience Lean provides.

## 6. Current preferred-path implementation evidence

The language-completion plan records substantial executable evidence already on
the checked-core path, including:

- foundational Nat/Int/Bool/String/Unit representation;
- generic/higher-order functions;
- Nat arithmetic and bounded Nat/Bool comparison/equality;
- lambdas, lets, conditionals;
- structures and parameterized structures;
- record construction/projection;
- generic inductives, constructors, and pattern matching;
- recursive ADTs and bounded structural recursion;
- theorem proof terms;
- bounded tactics;
- classes and bounded local/global instance synthesis;
- checked-core proof/type erasure;
- VerifiedIR -> TypeScript -> JavaScript/.d.ts/source maps;
- verified CLI paths;
- mixed `.ps` / bounded `.lean` project support;
- proof-aware language service/editor foundations;
- ProofScript-authored stdlib dogfood.

This evidence does **not** mean SH7 is already frozen. The freeze has additional
composition and semantic-hardening gates.

## 7. Current theorem/tactic evidence boundary

The repository currently has bounded implementations around:

- exact;
- assumption;
- intro;
- apply;
- refine;
- constructor;
- cases;
- induction;
- Eq-focused rfl;
- Eq-focused rw;
- explicit bounded simp-only;
- bounded exact? search.

Important boundaries retained by current plans include:

- indexed/dependent cases/induction are not universally complete;
- broad implicit/instance premise search is not full Lean tactic behavior;
- rfl is not claimed as full Lean reflexivity across HEq/attribute-indexed
  relations;
- rw is bounded rather than full location/occurrence/congruence rewriting;
- simp-only is not the full Lean simplifier/database;
- exact? is not full library-search/solveByElim behavior.

These fail-closed boundaries are part of correct conformance reporting.

## 8. Dual-source conformance

The `.ps` and supported `.lean` frontends must converge before semantic
acceptance.

Required semantic checks:

```text
.ps
  -> canonical AST
  -> checked admissions
  -> VerifiedIR

.ps -> canonical Lean
  -> lean-subset parser
  -> canonical AST
  -> checked admissions
  -> VerifiedIR

supported .lean -> canonical ProofScript
  -> ProofScript parser
  -> canonical AST
  -> checked admissions
  -> VerifiedIR
```

The routes should agree on:

- canonical source identity/hash after documented normalization;
- checked declarations/admission fingerprints;
- relevant structure/inductive/class/instance metadata;
- VerifiedIR after erasure;
- generated TypeScript;
- generated JavaScript;
- declarations/source maps where part of the profile.

Textual identity is not required.

Unsupported Lean syntax must fail before checked-core admission.

## 9. Mixed-module conformance

The project graph is source-kind independent.

Example:

```text
Main.ps
  imports Data

Data.lean
  imports Logic

Logic.ps
```

All modules participate in one semantic environment.

Requirements:

- deterministic topological build order;
- only declared/imported dependency admissions enter a module's environment;
- ambiguous logical module resolution is rejected;
- source kind is metadata, not a second semantic path;
- cache keys/integrity include semantic/source compatibility information;
- cached admissions are replayed/rechecked according to the artifact policy.

## 10. FFI conformance boundary

For the current named-ESM extension, conformance requires more than parsing the
package string.

The repository policy includes:

- explicit logical signature;
- explicit named ESM binding;
- runtime dependency allowlist;
- exact package-root version;
- package-lock closure/integrity evidence in the implemented profile;
- bounded public package subpaths;
- no proof evidence from host execution;
- rejection of unsupported ABI forms.

Canonical Lean source translation fails when runtime metadata would be lost.

This is correct fail-closed behavior, not a missing pretty-printer feature.

## 11. Portable backend conformance

All backends must agree before target lowering:

```text
same source
 -> same checked semantics
 -> same erasure meaning
 -> same target-neutral VerifiedIR
```

Target outputs need not be textually or byte identical.

### 11.1 TypeScript lane

Required model:

```text
VerifiedIR -> .ts -> pinned tsc -> .js/.d.ts/.map
```

No separate direct-JS semantic emitter.

### 11.2 Rust lane

Rust consumes the same VerifiedIR and must not introduce Rust source semantics
into PSC1.

Native compiler fixed-point work is post-JavaScript self-host stabilization.

### 11.3 Wasm lane

Wasm consumes the same VerifiedIR through a private Wasm target IR and owned
encoder.

Wasm-specific GC, memory, opcode, SIMD, component, and ABI choices remain below
the shared IR.

## 12. Cross-backend scalar conformance

A single scalar corpus must be shared by TS, Rust, and Wasm.

For every frozen operation/conversion, test at least:

- ordinary values;
- type extrema;
- zero/one;
- signed negative values where applicable;
- overflow/wrap boundary cases;
- division/remainder corner cases;
- shift boundaries;
- conversion extrema;
- Float/Float32 infinities/NaN/signed zero when the operation exposes them;
- target-word cases under both supported word profiles where practical.

Expected values must come from the PSC1 semantic contract, not be copied from
one backend and treated as the oracle for all others.

This corpus remains an SH7 open obligation until the matrix is frozen.

## 13. Portable-value conformance

Tests should ensure that semantically equal values do not accidentally depend
on target identity.

Examples:

- separately allocated equal structures compare according to declared equality;
- an ADT reconstructed across a runtime boundary preserves constructor
  semantics;
- closure/backend addresses are not source-observable unless a future explicit
  capability says otherwise;
- optimization sharing/unsharing cannot change ordinary value results.

## 14. Effect/capability conformance

Every bootstrap host capability should be classified:

```text
PURE-DETERMINISTIC-RUNTIME-ASSUMPTION
or
EFFECTFUL-CAPABILITY
```

For effectful capabilities record:

- input/output types;
- sequencing model;
- failure channel;
- rollback/transaction semantics if applicable;
- target availability;
- deterministic/reproducible expectations;
- trust/assumption status.

An undocumented effect hiding behind a pure function is a conformance failure.

## 15. SELFHOST-FEATURE composition gate

SH7 requires one multi-module fixture proving that the required features compose
through the real pipeline.

The controlling plan requires representative coverage of:

- nontrivial String/Char lexer traversal;
- source positions/spans;
- List/Array/ordered Map/Set;
- canonical JSON;
- a versioned pskernel request/response codec;
- qualified Name;
- imports/modules;
- explicit environment updates;
- structures and inductives;
- constructors/projections;
- ordinary match;
- Prod/tuple-returning helpers;
- structural recursion;
- one controlled partial case;
- compiler `do` effects;
- return/failure/alternative behavior;
- transactional rollback;
- genuinely needed generic/higher-order traversal;
- required implicit/class/instance/Decidable/Meta behavior;
- diagnostics/fresh IDs;
- multi-module compilation;
- pskernel bridge lookup/query/admission.

The fixture must run end-to-end, not just parse.

## 16. First self-host conformance

The JavaScript bootstrap is conceptually:

```text
compiler.lean --PSC0--> compiler.ts --tsc--> PSC1.js
compiler.lean --PSC1--> compiler.ts --tsc--> PSC2.js
```

A first core self-host claim requires stability beyond merely executing PSC1.

Compare at least:

- checked-core fingerprints;
- VerifiedIR fingerprints;
- normalized generated TypeScript;
- generated compiler behavior.

Byte-identical JavaScript is useful when reproducible under the pinned
toolchain but is not the semantic definition.

## 17. Source transition conformance

After the Lean-authored compiler is capable of translation:

```text
compiler.lean
  -> generated compiler.ps
  -> parse/elab/check
  -> equal checked-core
  -> equal VerifiedIR
  -> equivalent targets
```

Only then should the ProofScript compiler source be promoted to authoritative
`.ps`.

Reverse translation and canonical idempotence then become required source
transition gates.

## 18. Multi-host conformance after PSC1

Rust self-hosting is a later independent-host assurance milestone:

```text
compiler.ps --psc.js--> compiler.rs --rustc--> psc-native-1
compiler.ps --psc-native-1--> compiler.rs --rustc--> psc-native-2
```

Cross-host compilation should preserve checked-core/VerifiedIR meaning.

A Wasm-hosted compiler is another later fixed-point lane.

Neither is necessary to define PSC1 source semantics.

## 19. REQUIRED / OPTIONAL / DEFERRED audit rule

Every feature found in Lean/compiler study should be classified as one of:

- **REQUIRED**
- **USEFUL/CHEAP / OPTIONAL-PSC1**
- **DEFERRED/EXPENSIVE**
- **HOST-BOUNDARY**

Being present in Lean is not sufficient to classify something as REQUIRED.

Being already implemented does not automatically make it a freeze blocker.

Being optional does not authorize removal of an already-supported feature.

## 20. High-value optional conveniences

The current controlling plan explicitly leaves these non-blocking until real
compiler code requires them:

- generic transformer stacks;
- automatic MonadLift;
- HKT encodings;
- Sum;
- collection literals;
- tuple destructuring;
- generic GetElem;
- mutual inductives;
- mutual/local recursion syntax;
- full well-founded recursion;
- mutation and loops;
- rich patterns;
- method notation;
- structure-update sugar;
- named/default args;
- field defaults;
- abbrev/opaque source conveniences;
- interpolation;
- Inhabited/default convenience;
- explicit universe commands;
- broad namespace/section/open-scoped syntax.

These should not delay the first self-host merely for language completeness
aesthetics.

## 21. Default deferred subsystem families

Absent concrete compiler need, PSC1 defers:

- arbitrary user grammar extension;
- macro/quotation systems;
- custom parser categories;
- custom elaborators;
- generalized environment extensions;
- broad attribute machinery;
- unrestricted compile-time execution;
- implemented-by substitution;
- unsafe escape hatches.

A later ProofScript version may add some of these without invalidating PSC1.

## 22. Current baseline blocker

At the repository baseline used by this reference, the self-host architecture
and package layout are in place, and the active blocker is **portable source
closure of the compiler implementation**, currently progressing through the
Lean-subset parser/compiler source.

The correct response to a source-closure failure is:

1. identify the first real unsupported construct;
2. decide whether it is REQUIRED, optional-but-adopted, or avoidable;
3. implement the smallest faithful semantic support or refactor the compiler
   source to the already-frozen mechanism;
4. add regression gates;
5. do not weaken semantics or bypass checked core.

## 23. Open gates before saying "PSC1 frozen"

Do not claim the PSC1 freeze until all of these are true:

- exact REQUIRED source/capability census is frozen;
- scalar operation/conversion semantics are normative;
- scalar corpus passes active backend lanes;
- host capabilities used by bootstrap are purity/effect classified;
- no target object identity leaks into portable semantics;
- declaration aliases pass semantic identity/rejection gates;
- SELFHOST-FEATURE composition gate passes;
- each frozen construct passes the required Lean-source/AST/check/IR/TS/JS
  path;
- unsupported constructs remain fail-closed.

## 24. Open gates before saying "self-hosted"

Do not claim the first robust core self-host solely because one generated
compiler executes.

Require the planned subsequent generation/fixed-point comparison and stable
semantic fingerprints.

Full current-language self-hosting may additionally require the applicable
self-hosted theorem/tactic frontend milestone.

## 25. Open gates before stronger verification claims

Self-hosting is not compiler correctness.

Stronger claims require separate evidence for:

- erasure preservation;
- VerifiedIR transformation preservation;
- primitive/ADT/recursion lowering;
- backend semantic preservation;
- exact runtime assumptions;
- eventually formal connection to the pinned Lean model/implementation for the
  scope claimed.

## 26. Anti-drift rules

Future PSC1 work should preserve these rules:

1. repository HEAD is source of truth;
2. one checked-core semantic lane only;
3. no backend syntax special case that bypasses elaboration;
4. no weakened kernel/Meta checks to make target compilation succeed;
5. executable features need end-to-end source gates;
6. proof features need kernel-admission regression;
7. Lean-sensitive changes should be checked against pinned Lean 4.34 evidence;
8. unsupported cases fail closed;
9. trusted/untrusted boundaries remain explicit;
10. source modules stay focused by semantic responsibility;
11. new syntax requires ownership and semantic definition;
12. no "100% Lean" or formal-equivalence claim without exact gates;
13. CI only counts when real steps execute;
14. transitional duplicate semantic lanes should be deleted, not maintained.

## 27. Status-reporting format

A useful implementation report should state:

- current branch and HEAD;
- commits made;
- exact feature/gate added;
- semantic authority relied upon;
- tests actually executed;
- tests not executed and why;
- unsupported cases intentionally kept fail-closed;
- next smallest milestone.

Avoid invented completion percentages.
