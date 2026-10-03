# r3 Conformance Plan

Status: **accepted r3 conformance plan; execution pending.**

## Parser and lowering

Cover parenthesized calls with inherited spaces/comments (and rejection of tab-as-new-whitespace), explicit rejection of head-to-parenthesis line breaks as one r3 call, multiline arguments after `(`, tuple grouping, callable heads, native-dot adjacency, named/default arguments, empty-call lowering to native `f ..`, optional/default/automatic insertion, ordinary-required-explicit empty-call rejection, explicit `f(())`, zero-source-argument declaration lowering to optional Unit default, structural brace separators, valid empty structure/class/inductive/instance bodies where native semantics permits them, **required commas between multiple structure/class fields and rejection of a trailing field comma**, nested delimiters, native do/tactic categories, committed errors, and Standard versus Extensible syntax environments. Keep call/header trailing-comma tests separate because those lists retain their own accepted rule.

For every accepted source, compare the intended canonical native syntax/AST and preserve application grouping needed for Lean elaboration.

## Native oracle

Use exactly Lean 4.34.0 commit 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b. Record source hash, expected result, observed result, stdout/stderr, assumptions, and test scope.

Oracle acceptance is bounded evidence rather than a frontend theorem.

## Profiles

ps-standard must have a closed/versioned grammar, deterministic formatter/LSP category set, and rejection of undeclared syntax/meta extensions.

ps-lean-extensible must record extension identity/order/options and invalidate caches when that environment changes.

## Contracts

Test implementation identity, valid and false postconditions, contradictory preconditions, success/error outcomes, changed predicate dependencies, axiom-policy failures, incomplete proof search, and runtime-validation boundaries.

## Application model

Trace tests cover success, typed failure, panic, cancellation, child scope, detach, timeout, race, cleanup on all exits, cleanup failure, callback disposal, and stream backpressure.

Run equivalent tests on direct JS and direct Wasm when both exist.

## npm and d.ts

Cover primitives, presence states, arrays/tuples, discriminated unions, Promise, callbacks, classes/receivers, overloads, generics, advanced type operators, DOM handles, and at least one required unsupported case that fails closed.

## Evidence labels

Keep separate:

specified
prototype-tested
oracle-tested
formally-modeled
formally-proved-fragment
production-implemented
production-refined
translation-validated
backend-preserved-fragment
human-studied
full-app-tested

Do not collapse them into one verified flag.


## Schema/registry conformance

Validate representative positive/negative documents against:
- `FEATURE-REGISTRY-r3.json`;
- `PS-STANDARD-REGISTRY-r3.json`;
- `SEMANTIC-BUNDLE-v1.schema.json`;
- `INTERFACEIR-v1.schema.json`.

Standard-profile tests must reject dependency-provided syntax/meta registrations and any semantic bundle with nonempty `syntaxMetaExports` or `hostBuildEffects`, and must bind the materialized Standard registration-closure digest.

InterfaceIR resolution tests must vary install identity, export subpath, condition ordering, TypeScript resolver mode/version, custom conditions, runtime entry/hash and type entry/hash so a mismatched runtime/type branch cannot share one binding identity.


## Stable/1.0 evidence gate

The consolidated release-evidence checklist is `23-PRE-STABLE-EVIDENCE-GATES.md`.

This conformance document defines what to test; it does not claim those tests have run.
