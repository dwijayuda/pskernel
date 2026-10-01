# 15. Interop and Portability

ProofScript is meant to live in real software ecosystems.

That requires an explicit boundary between portable PSC1 semantics and host
capabilities.

## npm FFI

The current bounded source form is:

```proofscript
extern function hostShout(value: String): String
  from "host-lib"
  import shout;
```

The declaration records:

- a PSC1 signature;
- a package source;
- an imported runtime name.

## What the FFI does not prove

The declaration does not prove the JavaScript implementation correct.

The host function is a runtime assumption.

pskernel does not run npm code to establish theorems.

## Runtime dependencies

`psconfig.json` records exact package-root versions.

That improves reproducibility and makes the host dependency graph explicit.

## Portable code

Pure PSC1 code depending only on portable APIs can conceptually follow:

```text
source
-> CheckedCore
-> Erasure
-> VerifiedIR
   -> TypeScript/JavaScript
   -> Rust
   -> WebAssembly
```

The source meaning is shared.

## Target-specific code

An npm-only FFI narrows the target set.

A native system-library call narrows it differently.

A WASI capability may target Wasm hosts.

These should be explicit package capabilities rather than hidden assumptions.

## Representation independence

`Nat` is not JavaScript `number`.

`String` is not JavaScript's object representation.

A structure is not defined by a Rust memory layout.

An inductive is not defined by a Wasm tag encoding.

Backends choose representations under the language contract.

## JavaScript backend

The primary runtime path emits TypeScript, then uses pinned `tsc`.

The TypeScript is an implementation artifact, not the source semantic
authority.

## Rust backend

Rust can provide native output and independent-host assurance.

Rust ownership/lifetimes do not become PSC1 language features.

## Wasm backend

Direct Wasm should lower through a private target IR.

Wasm opcodes, GC layouts, SIMD, WIT/WASI, and memory choices remain backend
details unless PSC1 explicitly exposes a capability.

## Cross-backend tests

Portable code should be tested with:

```text
same source
-> same checked meaning
-> same VerifiedIR meaning
-> independent target builds
-> matching defined observable behavior
```

## Exercises

1. Classify five APIs as portable or target-specific.
2. Explain why npm package integrity is different from proof validity.
3. Pick one PSC1 scalar type and describe possible JS/Rust/Wasm
   representations without changing its source meaning.
4. Design a portable clock capability interface and explain why it is
   effectful.
