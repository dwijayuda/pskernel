# r3 Research Prototypes

These files exercise isolated architecture decisions. They are not production compiler/runtime components.

## application-model.js

A small executable trace model for Resource cleanup and a race scope.

Observed Node result:

~~~json
{"status":"passed","resourceCases":7,"raceCases":1}
~~~

This tests the proposed information-preserving cleanup policy and a simple structured-race trace. It does not implement fibers, actual cancellation, timers, networking, or target runtime integration.

## interface-ir-prototype.js

A deliberately restricted d.ts shape prototype.

It accepts a tiny subset:
- interfaces;
- readonly fields;
- optional fields with explicit missing-or-undefined metadata;
- string/boolean/number/bigint;
- arrays;
- Promise;
- named types;
- declared functions.

It rejects the tested conditional-type example rather than falling back to any.

This is not a TypeScript parser and must never be used as the production importer.

## npm-codec

A hand-authored package-shape experiment.

The real workflow executed:

~~~text
npm pack
install tarball in a clean consumer
tsc --noEmit with strict settings
Node runtime integration
~~~

All steps passed under the toolchain recorded in npm-codec/EVIDENCE.json.

The package is not emitted by PSC; it only validates a proposed ESM plus d.ts consumer shape.

## reference-apps/Inventory.lean

This lives outside prototypes because it is a checked canonical Lean domain model.

It establishes a small inventory reservation invariant and failure behavior under the pinned Lean oracle. It is domain-proof evidence, not a complete PSC service.
