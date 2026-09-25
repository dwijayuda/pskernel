# 11. Runtime Code, FFI, and Portability

Runtime execution begins only after checked semantics and erasure.

## Target-neutral boundary

```text
CheckedCore
-> Erasure
-> VerifiedIR
```

VerifiedIR is shared across backends.

## TypeScript backend

```text
VerifiedIR
-> TypeScript
-> pinned tsc
-> JavaScript
```

Generated TypeScript is not proof authority.

## Rust backend

Rust consumes the same target-neutral meaning.

Ownership, borrowing, lifetimes, traits, and unsafe are backend/runtime design
details, not PSC1 source semantics.

## Wasm backend

Direct Wasm lowering uses a private target IR/encoder.

Wasm opcodes, GC layout, SIMD, WIT/WASI, and memory models do not belong in
shared PSC1 semantics merely because they are available.

## Foreign functions

Current bounded named ESM form:

```proofscript
extern function hostShout(value: String): String
  from "host-lib"
  import shout;
```

The host binding is runtime metadata.

It is not proof evidence.

## Runtime dependency policy

`psconfig.json` records exact npm package-root versions.

Source externs may use bounded safe package subpaths while configuration remains
root-keyed.

## Pure vs effectful host capabilities

A foreign capability must not masquerade as a pure deterministic function if it
reads/writes observable host state.

Filesystem, network, time, randomness, process state, and similar services need
an explicit effect boundary.

## Translation limits

Canonical `.ps -> .lean` translation must fail if target source cannot
faithfully retain runtime binding metadata.

Dropping FFI information is not semantic equivalence.

## Portable packages

Pure code using portable PSC APIs can target TS/JS, Rust, and Wasm from the same
VerifiedIR.

Target-specific FFI narrows the package's supported target set.

## Conformance

Cross-backend testing compares observable results from one checked
source/VerifiedIR meaning.

Performance and representation need not match.
