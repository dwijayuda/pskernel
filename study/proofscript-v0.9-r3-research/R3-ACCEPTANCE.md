# ProofScript v0.9 r3 Design Acceptance

Date: 3 October 2026  
Status: **accepted language/design baseline; documentation/specification scope**

## Decision

The completed documentation research recommendations are accepted into ProofScript v0.9 r3.

This acceptance changes the r3 design baseline. It does **not** claim that the production PSC compiler, kernel, runtimes, npm bindings, contracts, or backends already implement the design.

The Lean semantic pin remains:

~~~text
Lean 4.34.0
293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
~~~

Native `.lean` syntax remains unchanged.

## Accepted r3 results

1. Parenthesized calls in `.ps` are insensitive to ordinary trivia between the callable head and `(`; one tuple argument requires explicit extra grouping.
2. ProofScript-owned braces are genuinely structural at their outer sequence level. Structure/class fields use commas **between fields only** and do **not** use a trailing field comma.
3. `function f()` is accepted as explicit Unit-function sugar.
4. `const` is retained for r3 as a top-level/namespace parameterless-definition alias. It remains eligible for reconsideration before stable/1.0 if usability evidence shows harmful false familiarity.
5. r3 defines `ps-standard` and `ps-lean-extensible` over the same Lean-compatible logical foundation.
6. Contracts/specifications become a stable PSC-owned semantic layer whose accepted evidence ultimately refers to the actual implementation and kernel-checkable logic.
7. r3 adopts one application-semantics direction around explicit typed exits, capabilities, structured concurrency, resources, and streams; target Promise/WASI machinery is adapter behavior, not source semantics.
8. npm/`.d.ts` integration uses a versioned InterfaceIR with raw, safe-adapter, and optional specification layers; unsupported type machinery fails closed rather than degrading to `any`.
9. The first formal overlay/backend preservation slices are accepted as future proof obligations, not completed evidence.
10. The TypeScript-developer usability study protocol is accepted as a pre-stable/1.0 evidence gate; the r3 design itself is now recorded before that study is run.

## Accepted exclusions

r3 does not add:

- JavaScript automatic semicolon insertion;
- a universal JavaScript statement-block language;
- TypeScript arrow lambdas as base syntax;
- native `any`;
- JavaScript truthiness;
- implicit null/undefined;
- Promise as the semantics of PSC async;
- `.d.ts` as proof or runtime validation;
- arbitrary syntax mutation in `ps-standard`;
- proof claims derived from tests/self-hosting/hashes alone.

## Evidence boundary

Accepted design means:

~~~text
researched
reviewed
selected for r3 specification
~~~

It does not mean:

~~~text
production implemented
parser/lowerer proved
backend preserved
full-app tested
human studied
1.0 frozen
~~~

Those remain independently tracked in `MANIFEST.json`, the conformance plan, formal-proof plans, reference-application plan, and usability-study protocol.

## Versioning

The accepted grammar/design identity is:

~~~text
ps-0.9-r3
~~~

This is a breaking source revision relative to r2 because `f (x, y)` in native `.ps` no longer means the r2 native tuple-neighbor form. Edition-aware migration must preserve old tuple intent as `f((x, y))`.

r2 and earlier references remain historical artifacts and are not rewritten.

## Specification-completion addendum

The follow-up completion pass resolves the previously identified lingering specification gaps without changing the Lean semantic pin or claiming implementation evidence.

Accepted additions:

- r3 is formally a complete delta over the exact vendored r2 baseline and 89-section inheritance/override matrix;
- parenthesized-call ownership uses a horizontal CallGap; a physical newline breaks ownership;
- native field-dot adjacency remains unchanged;
- `f()` is a complete empty invocation with native default/auto insertion, one possible Unit synthesis, and rejection of unsatisfied required non-Unit parameters;
- r2 `f()` migrates to r3 `f(())` to preserve the old explicit Unit meaning;
- the exact overlay grammar/feature registry is frozen;
- `ps-standard-0.9-r3` has a fixed registry and Semantic Bundle v1 import boundary;
- the normative base contract core is total-pure `requires`/`ensures`, with semantic frame/effect data and a higher-order CallableSpec model;
- App/Fiber/Exit/RuntimeFault/Resource/Stream semantics, cancellation shielding, capability visibility and native IO relationship are fixed;
- InterfaceIR v1 has normative prose and JSON Schema plus exact module-resolution identity.

The remaining gates are implementation and evidence work, not undefined base-r3 semantics.
