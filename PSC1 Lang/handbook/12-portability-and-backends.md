# Portability and Backends

PSC1 is designed around one checked source semantics and multiple execution
backends.

The key architectural boundary is target-neutral VerifiedIR.

## One semantic pipeline

```text
.ps or supported .lean
-> source AST
-> Lean-compatible Meta/Elab
-> pskernel
-> CheckedCore
-> Erasure
-> VerifiedIR
```

Only after VerifiedIR does target lowering begin.

## Why not generate each backend directly from source?

If the TypeScript backend interpreted source one way, the Rust backend another,
and the Wasm backend a third way, ProofScript would effectively have three
languages.

PSC1 avoids that by sharing:

- elaboration;
- checked core;
- erasure;
- runtime semantic IR.

Backends are code generators, not alternate semantic checkers.

## TypeScript/JavaScript backend

The first primary runtime path is:

```text
VerifiedIR
-> backend-ts
-> TypeScript
-> pinned tsc
-> JavaScript + declarations + source maps
```

ProofScript intentionally does not maintain a separate semantic direct-JS
emitter.

## Rust backend

The planned/native path is:

```text
VerifiedIR
-> backend-rust
-> Rust
-> rustc/Cargo toolchain
-> native artifact
```

Rust features are implementation choices.

PSC1 does not gain:

- ownership types;
- borrow checking;
- lifetimes;
- Rust traits;
- `unsafe`;

as source semantics merely because one backend uses Rust.

Generated ordinary code should prefer safe Rust, with any unavoidable unsafe
runtime/FFI code isolated behind a small explicit boundary.

## WebAssembly backend

The direct Wasm path is:

```text
VerifiedIR
-> backend-wasm
-> Wasm target IR
-> owned encoder
-> .wasm
```

Potential implementation tools include:

- Wasm GC;
- typed function references;
- packed numeric storage;
- SIMD;
- memory64;
- WIT/WASI/component integration.

None of these belongs in shared VerifiedIR unless it can be described in
backend-neutral PSC1 semantics.

## Scalar mappings

Some fixed-width types map naturally to targets.

For example, Rust can often use:

```text
UInt8  -> u8
UInt16 -> u16
UInt32 -> u32
UInt64 -> u64

Int8   -> i8
Int16  -> i16
Int32  -> i32
Int64  -> i64
```

Wasm commonly executes:

```text
UInt8/Int8     in i32
UInt16/Int16   in i32
UInt32/Int32   in i32
UInt64/Int64   in i64
Float32        in f32
Float          in f64
```

These are target mappings, not source definitions.

## Exact `Nat` and `Int`

`Nat` and `Int` remain exact mathematical integers.

A JavaScript backend might need arbitrary-precision support.

A Rust backend may use a big-integer runtime.

A Wasm backend may need a custom exact-integer representation.

The language does not redefine them as machine integers for convenience.

## Target-sized integers

`USize` and `ISize` intentionally vary with the selected target word size.

Therefore portable code should avoid assuming one fixed width unless the target
profile is part of the package contract.

## Float determinism

A verified/deterministic build profile must not silently enable transformations
that change the frozen floating semantics.

Examples include:

- fast-math reassociation;
- relaxed SIMD behaviors that broaden results.

Performance options stay subordinate to the language contract.

## Managed values

Strings, structures, inductives, closures, and arrays may use:

- JavaScript objects;
- Rust heap values;
- Wasm GC objects;
- linear-memory layouts;

depending on the backend.

Portable PSC1 code cannot observe those representation identities as its
ordinary value identity.

## Backend-specific private IR

A backend may and often should have its own target IR.

For example:

```text
VerifiedIR
-> WasmTargetIR
-> binary encoder
```

is cleaner than polluting shared VerifiedIR with Wasm opcodes.

The same principle applies to Rust-specific or TypeScript-specific lowering
structures.

## Shared optimizations

An optimization can run before backend lowering when its correctness can be
stated purely in PSC1 semantics.

Examples might include:

- dead pure computation removal;
- target-neutral specialization justified by checked facts;
- semantics-preserving simplification.

Target-specific representation optimizations run later.

## Portable libraries

A pure package using only portable PSC APIs should be able to follow:

```text
library.ps
-> VerifiedIR
   -> JavaScript
   -> Rust
   -> Wasm
```

Portable means the observable language semantics are shared.

It does not mean:

- emitted files are identical;
- performance is identical;
- memory layout is identical.

## Capability-restricted packages

A package may intentionally depend on a target capability.

Examples:

- npm-only library;
- native system library;
- WASI host interface.

Such a package declares a narrower target set.

This is better than contaminating the common language with backend-specific
assumptions.

## Cross-backend conformance

For a portable feature, the strongest useful executable test shape is:

```text
same source
-> same CheckedCore meaning
-> same VerifiedIR meaning
-> independent target lowerings
-> matching observable results
```

The scalar operation/conversion corpus is especially important here.

## Current scalar freeze caveat

The scalar vocabulary is frozen.

The complete normative operation/conversion matrix is still an open SH7
obligation on the baseline used by these docs.

Therefore backend-native corner-case behavior must not be treated as the
specification until that matrix is published and gated.

## Multi-host self-hosting

After the JavaScript compiler reaches a stable fixed point, PSC1 plans an
independent Rust-hosted compiler generation.

Later, a Wasm-hosted lane can provide another implementation host.

Multiple hosts increase assurance because one compiler semantics can be
regenerated under independent runtimes.

They are not required to define the language itself.

## Next

Continue to [Dual-source Lean Interop](./13-dual-source-lean-interop.md).
