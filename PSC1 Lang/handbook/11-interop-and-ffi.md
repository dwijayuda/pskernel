# Interop and FFI

ProofScript is intended to work inside real JavaScript/npm projects.

That requires foreign-function interoperability without turning host execution
into proof authority.

## The basic boundary

A foreign function has two relevant parts:

1. a PSC1 logical/runtime signature;
2. host binding metadata.

Current bounded syntax:

```proofscript
extern function hostShout(value: String): String
  from "host-lib"
  import shout;
```

This says that runtime execution may obtain `shout` from the named package
source and treat it according to the declared PSC1 signature.

## What the declaration does not prove

It does not prove:

- that the JavaScript implementation is correct;
- that it respects the logical signature in all cases;
- that the package has no side effects;
- that executing the package can establish a theorem.

The FFI declaration creates a runtime assumption.

Assumptions should remain visible in assurance output.

## Current first FFI profile

The repository deliberately keeps the initial host boundary small.

Current policy focuses on:

- named ESM imports;
- first-order supported runtime signatures;
- explicit npm package source;
- exact package-root version declarations;
- bounded public package subpaths;
- fail-closed unsupported forms.

This is enough to establish a useful interop architecture without immediately
supporting every JavaScript module pattern.

## Runtime dependencies

A project declares exact package roots in `psconfig.json`:

```json
{
  "runtimeDependencies": {
    "host-lib": "1.2.3"
  }
}
```

Current config requires exact versions rather than ranges.

A source declaration may use a bounded package subpath:

```proofscript
extern function transform(value: String): String
  from "host-lib/feature"
  import transform;
```

while the config remains keyed by the root:

```text
host-lib
```

## Why exact versions?

ProofScript distinguishes:

- logical theorem/project meaning;
- runtime dependency reproducibility.

Exact runtime versions make the latter easier to audit.

They do not convert npm code into proof evidence.

## Package-lock assurance

Current implementation work also validates the reachable npm dependency closure
through the project's lockfile for runtime externals.

The runtime lock fingerprint is assurance metadata.

It is separate from pskernel project integrity.

## Unsupported external sources

The bounded source policy rejects examples such as:

- relative import paths;
- absolute paths;
- `node:` builtins;
- traversal segments;
- direct `node_modules` traversal;
- malformed package roots.

The first profile also avoids broad default/namespace/CommonJS/dynamic-import
ABI forms.

These can be added later only with an explicit semantic/runtime contract.

## Pure vs effectful externs

An external function may look like an ordinary function at the type level.

That is safe as a portable semantic assumption only when the capability is
explicitly classified as pure/deterministic.

A function that:

- reads a file;
- changes process state;
- calls the network;
- reads time;
- uses randomness;

must cross an explicit effect boundary rather than pretend to be a pure PSC1
function.

## Why this matters to optimization

Pure PSC1 code can be transformed according to pure semantics.

If an FFI call hides effects, duplicating or removing it may change behavior.

Explicit effect classification protects:

- compiler optimization;
- proof rewriting;
- cross-backend equivalence.

## Host exceptions

A JavaScript package may signal ordinary failure by throwing or rejecting.

If the PSC1 capability models recoverable failure, the adapter should convert
that host failure into the declared typed PSC1 error/effect channel.

Host exception semantics are not automatically PSC1 semantics.

## FFI and `.lean` translation

The logical signature of an external function may have a Lean-like view.

But the npm package source/import name is extra runtime metadata.

If canonical `.ps -> .lean` translation cannot preserve that metadata, the
translator must reject the module rather than silently discard it and claim a
lossless round trip.

This is an important example of fail-closed source interoperability.

## FFI and other backends

A named npm ESM import is naturally a JavaScript-target capability.

A pure library that depends on it cannot automatically claim native/Wasm
portability.

There are two clean approaches:

1. declare the package target-specific;
2. define an abstract portable capability and provide separate backend
   implementations with the same declared PSC1 contract.

Target-specific dependency metadata must not contaminate shared VerifiedIR
semantics.

## FFI and proofs

A safe rule is:

> The kernel checks proofs. Host code can provide runtime behavior and explicit
> assumptions, but it does not become a proof oracle.

That rule should remain true even as PSC1 gains richer interoperability.

## Next

Continue to [Portability and Backends](./12-portability-and-backends.md).
