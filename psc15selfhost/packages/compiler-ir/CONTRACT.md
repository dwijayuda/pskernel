# VerifiedIR target-neutrality contract

`PsVerifiedIr` is the single post-erasure semantic IR shared by every
ProofScript execution backend.

## Rule

A node belongs in VerifiedIR only when its meaning can be stated entirely in
ProofScript semantics without referring to TypeScript/JavaScript, Rust, Wasm,
or a target ABI.

Backend representation belongs after this boundary.

## Allowed

- PSC primitive semantic types;
- source-independent function/ADT/runtime semantics;
- structures, inductives, constructors, projections and matches;
- semantic operations on PSC values;
- target-neutral external capability identities;
- target-neutral optimization facts justified by PSC semantics.

## Forbidden

- TypeScript/JavaScript runtime types, object layouts, npm/Node resolution;
- Rust ownership/borrowing/lifetimes/traits/container choices/Cargo ABI;
- WebAssembly value types, opcodes, GC layout, memories, tables, WIT/WASI or
  binary encoding;
- target-specific object layout, calling convention or allocation policy.

Runtime `let` bindings retain their erased PSC semantic type in VerifiedIR.
This is required for target-independent checking/lowering of locals and does
not prescribe stack slots, registers, JS closures, Rust storage, or Wasm locals.

Runtime lambdas retain their erased PSC parameter and result types in
VerifiedIR. The result type is semantic function information required by any
typed backend; it does not prescribe closure conversion, environment layout,
function references, calling convention, or allocation strategy.

Machine integer literals carry their PSC machine-integer type in VerifiedIR.
The literal value must already denote the PSC semantic value produced by
elaboration/erasure; backend code must not infer its width from surrounding
TypeScript, Rust or Wasm representation.

## Backend structure

```text
VerifiedIR
  +-> backend-ts   -> TS target lowering/emission
  +-> backend-rust -> Rust target lowering/emission
  +-> backend-wasm -> Wasm target IR -> encoder
```

A backend may define a private target IR. Shared optimizations should operate on
VerifiedIR or a target-neutral OptimizedIR and preserve PSC semantics.

The automated neutrality guard catches obvious lexical leakage. Architectural
review remains authoritative because a target-shaped design can exist without
using a forbidden target name.
