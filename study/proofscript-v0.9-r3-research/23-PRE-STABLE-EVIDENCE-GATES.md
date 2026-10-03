# r3 Pre-Stable / 1.0 Evidence Gates

Status: **release/evidence policy only; not a ProofScript source-language authority; no gate is claimed completed by this documentation pass**

The accepted r3 design can exist before these gates run.

A stable/1.0 language-surface or stronger end-to-end assurance claim requires the relevant gates below.

## 1. Evidence labels

Keep separate:

~~~text
specified
research-reviewed
prototype-tested
oracle-tested
human-studied
formally-proved-model
production-refined
translation-validated
backend-preserved-fragment
full-app-tested
artifact-bound
external-assumption
~~~

No single verified boolean replaces these labels.

## 2. Usability gate

Use the protocol in 13-USABILITY-STUDY.md.

Minimum target cohort:

- 18 TypeScript developers: 6 junior, 6 mid, 6 senior;
- 6 Lean users with mixed theorem/application experience.

Required high-risk tasks:

- f(x) versus f (x);
- f((x,y)) versus f(x,y);
- f() with zero-source-arg function;
- f() with default-only function;
- f() rejection when required explicit parameters remain;
- call line break before parenthesis;
- structural braces and no trailing field comma;
- const semantics;
- Option versus undefined/null;
- typed failure versus runtime fault;
- contract pre/post meaning;
- source proof versus backend correctness.

### Pre-registered criteria

Before stable/1.0:

- no accepted syntax rule may show a persistent high-confidence semantic misconception rate without either redesign or explicit teaching/diagnostic mitigation;
- const remains subject to the existing comprehension threshold/review;
- the empty-call/default rule must perform materially better than the old Unit-only explanation on default-parameter tasks;
- structural braces must materially reduce member-boundary misunderstandings compared with r2 hybrid braces.

Preference alone is not a pass criterion.

Status: **pending; no participants run in this documentation pass**.

## 3. Frontend formal gate

First formal targets:

1. r3 call ownership model;
2. exact CallGap/no-bare-newline property;
3. empty-call canonical lowering to native ellipsis application;
4. acceptance predicate excluding omitted required explicit arguments;
5. zero-arg declaration lowering to optional Unit;
6. structural brace ownership/member-boundary model;
7. binding/hygiene preservation for the selected fragment;
8. production AST/refinement relation.

Required theorem classes:

~~~text
ownership determinism
lowering well-formedness
protected native-neighbor/profile behavior
binding preservation
source/canonical interpretation correspondence
production refinement for the proved fragment
~~~

Status: **planned, not executed here**.

## 4. Backend preservation gate

Start with a pure restricted RuntimeIR:

~~~text
Bool
exact Nat literals/addition/multiplication
local immutable bindings
pure function calls
small ADTs/matches
~~~

Define:

- source semantics;
- target AST/semantics;
- value relation;
- lowering;
- serializer relation;
- exact artifact relation.

Prove/validate an explicit preservation theorem before extending claims to more primitives.

Then add strings, exact Int operations, closures, recursion, and effects incrementally.

Status: **planned, not executed here**.

## 5. Primitive/runtime conformance gate

For every executable target profile, maintain a primitive matrix covering at least:

- Nat addition/multiplication/subtraction/division/remainder;
- Int signed division/remainder including negative cases;
- fixed-width integer operations;
- Bool;
- Char/String/ByteArray conversions;
- List versus Array representation/operations;
- constructor/tag representation;
- closure calling convention;
- noncomputable/partial/unsafe boundaries.

Each entry records:

~~~text
source declaration identity
target implementation
representation relation
edge-case behavior
evidence status
runtime assumptions
~~~

Unknown reachable primitive = target build rejection.

Status: **pending**.

## 6. Application semantics gate

For psc-app-v1, cross-target traces must exercise:

- cold App construction;
- run/fork start;
- Fiber join;
- typed failure;
- RuntimeFault separation;
- cancellation races;
- structured scope exit;
- detach;
- shielded cleanup;
- cleanup failure combinations;
- timeout/Clock;
- Stream demand/backpressure;
- Stream cancellation;
- Promise late completion;
- foreign callback after disposal.

Run the same semantic scenarios against direct JS and direct Wasm/WASI profiles where both advertise the capability.

Status: **pending**.

## 7. InterfaceIR/npm gate

Use real packages from several API shapes:

1. pure utility/data package;
2. schema/JSON validation package;
3. Promise-based HTTP API;
4. callback/event-emitter API;
5. receiver/class API;
6. UI/DOM-facing declarations;
7. package using conditional exports/subpaths;
8. advanced conditional/mapped/template types;
9. intentionally unsupported global/module augmentation case.

Required outcomes:

- exact runtime/type resolution identities;
- successful InterfaceIR generation for supported cases;
- explicit failure for unsupported cases;
- runtime validation where needed;
- generated PSC-exported declaration files checked by a clean TypeScript consumer;
- no hidden any fallback.

Status: **pending**.

## 8. Reference application gate

Before "full-app ready":

1. file-transform CLI;
2. HTTP/service application;
3. browser UI application using npm bindings;
4. published PSC npm library consumed by TypeScript;
5. verified domain/state-machine package.

Record:

- PSC handwritten source;
- handwritten foreign glue;
- generated code;
- assumptions;
- build/test results;
- proof results;
- target profile;
- runtime adapters;
- artifact identities.

No application is counted complete when essential logic is implemented only in handwritten JS/TS while being presented as PSC.

Status: **pending**.

## 9. Standard profile gate

Before stable Standard:

- materialize exact parser/tactic/attribute/deriving registration closure;
- publish registration-closure SHA-256;
- verify forbidden syntax/meta registrations fail closed;
- verify semantic bundles install no syntax/meta effects;
- exercise LSP/formatter across the full Standard grammar;
- verify cache invalidation on semantic/profile/environment changes.

Status: **pending**.

## 10. Contract gate

For psc-contract-core-v1:

- pure requires/ensures implementation identity;
- multiple clause conjunction;
- Except outcome property through ordinary match;
- changed predicate dependency invalidates evidence;
- axiom-policy rejection;
- higher-order callRequires/callEnsures model;
- empty effect/read/write frame for pure functions;
- effect/frame violation detected in the first effectful program-logic profile.

Status: **pending**.

## 11. Artifact/release gate

A stronger executable claim binds:

~~~text
source snapshot
canonical declaration bundle
checked module
runtime IR
target AST
serialized file
linked runtime/helper artifacts
package/export resolution
compile/link/bundle options
assumptions
~~~

to exact immutable identities.

Post-check edits, bundling, minification, framework transforms, and target compiler steps remain assumptions or receive separate evidence.

Status: **pending**.

## 12. Stable/1.0 decision

A stable/1.0 review receives:

- usability report;
- formal-proof report;
- conformance matrices;
- reference-application results;
- open-question status;
- migration assessment;
- any proposed syntax changes caused by evidence.

The review may still revise r3 surface rules before 1.0.

This document creates no presumption that an accepted r3 design must survive contradictory evidence unchanged.
