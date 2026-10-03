# r3 Conformance Plan

Status: **accepted r3 conformance plan; execution pending.**

## Parser and lowering

Cover parenthesized calls with spaces/comments/newlines, tuple grouping, callable heads, named/default arguments, zero-argument Unit sugar, structural brace separators, nested delimiters, native do/tactic categories, committed errors, and Standard versus Extensible syntax environments.

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
