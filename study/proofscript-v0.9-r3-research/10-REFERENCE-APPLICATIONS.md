# r3 Complete Reference Applications

Status: acceptance plan. These are not yet completed r3 PSC applications.

## Principle

A language cannot claim full-app readiness from syntax documents or compiler self-hosting alone. r3 therefore defines concrete applications that must build from PSC source with real package/build/test workflows.

## App 1: File Transform CLI

Read newline-delimited JSON, validate records, transform them, write output, report line-specific errors, and release resources on every supported outcome.

Exercises filesystem, bytes/text, JSON codecs, typed errors, Resource, collections, logging, CLI packaging, and tests.

Verification target: every accepted output row satisfies the normalized domain schema; malformed input preserves source location.

## App 2: Inventory HTTP Service

HTTP API for inventory and reservations.

Domain invariant:

~~~text
available >= 0
reserved >= 0
available + reserved = total
~~~

Prove the pure reservation transition preserves total and rejects requests greater than available without changing state.

Exercise App, Fiber, Resource, HTTP bindings, JSON codecs, storage adapter, typed errors, timeout, logging, and contracts.

Database isolation remains a separately stated external/storage model assumption.

## App 3: Browser Search UI

Typed browser UI that starts remote search requests, cancels superseded work, and cannot accept a stale result as current.

State:

~~~text
Idle
Loading requestId
Ready requestId data
Failed requestId error
~~~

Prove the pure reducer rejects stale response IDs.

Exercise npm UI adapter, DOM/event handles, HTTP, cancellation, state, source maps, and bundler integration.

## App 4: Published PSC npm Library

A codec/domain package compiled to ESM plus generated d.ts and consumed by a clean strict TypeScript project.

Required workflow:

~~~text
psc build
npm pack
install tarball in clean TS consumer
tsc --noEmit
run Node integration tests
~~~

No handwritten d.ts. Public wrappers validate untrusted external inputs.

Verification target: a precise encode/decode round-trip or normalization law.

## App 5: Verified State Machine

A small domain package such as inventory reservation or order lifecycle with:

- pure executable transition;
- explicit invalid-command result;
- state invariant;
- theorem tying implementation to contract;
- deliberately broken mutants that the spec rejects.

This becomes the canonical specification-driven/AI example.

## Metrics

For every app record:

- PSC source LOC;
- handwritten JS/TS glue LOC;
- generated LOC;
- dependencies;
- cold/warm build time;
- editor diagnostic latency;
- proof/check time;
- target artifact size;
- unresolved features;
- foreign trust boundaries;
- exact assumptions.

Do not publish one vague percent-verified metric.

## Current status

Not built end-to-end because this branch does not implement the r3 parser, contracts, App runtime, or InterfaceIR importer.

Creating TypeScript mocks and calling them PSC applications would be misleading.

Immediate bounded prototypes may validate individual layers, but must remain labelled prototypes.

## Full-app release gate

ProofScript should not claim r3 full-app readiness until Apps 1 through 4 build and run through supported PSC toolchains and App 5 demonstrates a useful admitted contract.

This gate is intentionally stronger than self-hosting.
