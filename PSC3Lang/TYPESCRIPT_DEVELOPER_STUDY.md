# PSC3 Study: TypeScript and JavaScript Developer Needs

Status: **research-derived design input**

This document separates TypeScript/JavaScript habits worth preserving from semantics PSC3 should deliberately reject.

The goal is adoption, not source-level imitation.

## 1. Research conclusions

Modern TypeScript application development is characterized by:
- ESM modules and package exports;
- npm-compatible dependencies;
- IDE/LSP-first workflows;
- structural object/data APIs;
- generics and inference;
- discriminated unions and control-flow narrowing;
- async/await;
- JSON/HTTP/browser/server work;
- JSX/TSX for a large portion of UI development;
- build/bundler pipelines;
- strong expectation of fast incremental feedback.

TypeScript has also accumulated advanced type-level computation and unsound/dynamic compatibility mechanisms because it must model JavaScript.

PSC3 does not share that historical constraint.

## 2. Features PSC3 should make comfortable

### Functions and local inference — ACCEPT

TypeScript developers expect concise functions and strong local inference.

PSC3 .ps should support:

~~~proofscript
function add(x: Nat, y: Nat): Nat {
  x + y
}
~~~

Exact final body syntax remains subject to grammar validation, but ordinary functions must be visually familiar and require little ceremony.

Generic/dependent information should be inferred when deterministic.

### Familiar calls — ACCEPT

~~~proofscript
connect(host, timeout: 5000)
users.map(renderUser)
~~~

PSC3 native call syntax is structural and whitespace-insensitive.

Lean-style juxtaposition remains a .lean concern.

### Structures/records — ACCEPT WITH NOMINAL SEMANTICS

TypeScript developers constantly use object-shaped data.

PSC3 should make nominal structures lightweight:

~~~proofscript
structure User {
  id: UserId
  name: String
  email: Option String
}
~~~

Construction and immutable update should be concise.

The language should not make arbitrary equal-shaped records automatically interchangeable.

### Discriminated unions — ACCEPT AS INDUCTIVES

TypeScript's discriminated unions map naturally to algebraic/inductive data.

~~~proofscript
inductive LoadState(A: Type) {
  | idle
  | loading
  | ready(value: A)
  | failed(error: Error)
}
~~~

Pattern matching should be exhaustive and type-refining.

A payload-free enum can be ergonomic sugar over an inductive, provided it adds no separate semantic model.

### Narrowing — ACCEPT, STRENGTHEN

TypeScript control-flow narrowing is one of its most useful everyday features.

PSC3 should offer a principled version through:
- pattern matching;
- Option/Result branching;
- constructor discrimination;
- equality/condition evidence where sound;
- proposition-aware refinement in verified contexts.

The native design should avoid a sprawling set of ad-hoc narrowing rules.

### Optional data — ACCEPT AS OPTION, WITH SAFE SUGAR

TypeScript optional properties and nullish operators are ergonomic but depend on null/undefined semantics.

PSC3 should use Option as the meaning.

Candidates:

~~~proofscript
structure User {
  nickname?: String
}

const label = user.nickname ?? user.name
const upper = user.nickname?.toUpper()
~~~

Proposed lowering:

~~~text
field?: T     -> field: Option T
x ?? y        -> Option.getOr x y
x?.f()        -> Option.map / bind according to the expression shape
~~~

This is a **CANDIDATE** until evaluation order, chaining and typing are specified precisely.

There is no implicit null or undefined in portable .ps.

### Errors — ACCEPT TYPED ERRORS, REJECT HOST-EXCEPTION SEMANTICS

Recoverable errors should use Result/Except-style values/effects.

Convenient syntax may include a familiar try/recovery form, but it must lower to typed PSC semantics.

Unexpected process/runtime failure is a separate concept.

### Async/await — ACCEPT OVER PSC TASK

TypeScript developers expect async/await.

PSC3 should support it as syntax over a specified Task abstraction.

The source semantics must define:
- completion;
- typed failure;
- cancellation;
- child-task lifetime;
- timeout/race behavior;
- cleanup ordering.

JavaScript Promise/event-loop behavior is one backend mapping, not the language definition.

### Destructuring and patterns — ACCEPT THROUGH ONE PATTERN LANGUAGE

Object/array destructuring should not become a second feature family.

Use the same pattern compiler for:
- match;
- let binding;
- parameter destructuring where useful;
- Result/Option;
- component props where appropriate.

### Named/default arguments — ACCEPT WITH BOUNDED RULES

Default parameters are common and valuable.

PSC3 should keep deterministic named/default arguments.

Defaults:
- elaborate in declaration context;
- have specified runtime evaluation timing if computational;
- cannot create hidden overloading;
- must be visible through tooling.

### Modules — ACCEPT ESM-LIKE EXPLICITNESS

Native .ps should feel familiar to JS/TS users:

~~~proofscript
import { decodeUser } from "./codec"
import * as Http from "@proofscript/http"

export function handler(...) ...
~~~

Exact package resolution is PSC-defined and deterministic.

The emitted JS uses modern ESM.

### JSX/TSX workflow — ACCEPT AS .psx PROFILE

UI markup is important enough to deserve a first-class profile.

It should not force React semantics into the language.

See PSX_UI_PROFILE.md.

## 3. Features PSC3 should not copy

### any — REJECT

PSC3 should have no universal unchecked type escape in verified/portable code.

Dynamic values cross explicit boundaries through a Dynamic/Json/foreign representation and require validation/refinement.

### implicit null/undefined — REJECT

Use Option and explicit JS boundary conversion.

### prototype inheritance and this semantics — REJECT

Use structures, modules, functions, typeclasses/interfaces, and method notation.

### structural assignability as core typing — REJECT

It is excellent for modeling arbitrary JS, but poor as the logical identity of verified data.

Interop tools can translate structural .d.ts shapes into generated bindings/codecs.

### truthiness — REJECT

Conditions have explicit Boolean/proposition meaning.

No implicit string/number/object truthiness in portable source.

### host exceptions as ordinary errors — REJECT

Foreign adapters translate host failure into declared error channels.

### enum runtime quirks — REJECT

If PSC3 provides enum syntax, it is only a concise algebraic-data form.

### declaration merging/ambient mutation — REJECT FROM NATIVE CORE

FFI declaration packages are explicit artifacts. They should not mutate global type meaning by import accident.

## 4. Advanced TypeScript type features

TypeScript supports powerful compile-time machinery:
- keyof;
- indexed access types;
- mapped types;
- conditional types;
- template-literal types;
- utility types;
- structural intersections.

PSC3 should not copy this system wholesale.

Where the programming problem is genuine:
- generics use polymorphism/dependent functions;
- shape transformation can use typed compile-time functions/deriving;
- string/domain constraints can use refined/dependent data;
- JS declaration compatibility belongs in the binding generator.

The .d.ts importer may need to interpret much more TypeScript type machinery than native PSC exposes.

That is an interop capability, not a reason to make PSC's native type language resemble the TypeScript checker.

## 5. Ecosystem pain PSC3 can improve

### Error handling

PSC3 can make explicit typed errors normal while providing concise propagation syntax.

### Dates/time

A serious standard library should provide a coherent time/date model rather than inherit JavaScript Date behavior as language semantics.

### ESM/CJS/package ambiguity

PSC3 native packages should have one canonical module model.

CJS should be handled at foreign boundaries.

### Configuration complexity

The PSC toolchain should avoid a large matrix of compiler flags analogous to years of tsconfig evolution.

Use small named profiles and explicit package capabilities.

### Runtime schema mismatch

TypeScript types vanish at runtime.

PSC3 should make codecs/validators/schema derivation a standard capability, especially for JSON, API and FFI boundaries.

### Soundness visibility

TypeScript deliberately allows unsound behavior for JavaScript ergonomics.

PSC3 can instead tell users exactly which boundary is:
- statically typed;
- runtime validated;
- contract verified;
- trusted external;
- unverified.

## 6. TypeScript adoption ladder

PSC3 should support gradual **project adoption**, not unsound gradual typing.

Suggested path:

~~~text
existing TS/JS app
   |
generated PSC binding for npm APIs
   |
one PSC library compiled to ESM + .d.ts
   |
more modules moved to .ps
   |
critical modules gain contracts
   |
selected guarantees gain proofs
   |
optional direct Wasm components
~~~

A project can mix PSC and JS/TS modules without weakening PSC's internal type system.

## 7. Developer-experience requirements

To compete seriously with TypeScript, PSC3 needs:
- sub-second incremental feedback on ordinary edits where practical;
- high-quality LSP completion/navigation/refactors;
- source maps;
- canonical formatting;
- straightforward npm use;
- readable generated JS;
- generated .d.ts;
- test runner;
- package scripts/tasks;
- diagnostics that explain inference and proof obligations;
- build caching and deterministic dependency graphs.

Compiler speed and editor latency are language-product requirements, not secondary implementation details.

## 8. Acceptance benchmark

PSC3 should not claim TypeScript-developer friendliness until representative developers can:
- build a small CLI;
- consume a popular npm library through bindings;
- create an HTTP service;
- build a browser UI;
- model JSON/API data;
- use async code;
- debug type errors;
- export an npm package consumed from TypeScript;
- add one meaningful contract;

without repeatedly dropping into untyped JS escape hatches.
