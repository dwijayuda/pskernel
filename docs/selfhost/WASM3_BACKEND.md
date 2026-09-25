# ProofScript owned WebAssembly 3 backend

Foundation merge: `fb44f81a`
Current large-feature branch: `backend/wasm3-gc-adts`

Status: experimental and deliberately non-blocking for the active PSC1
JavaScript self-host closure. The scalar/control-flow Wasm foundation is merged;
the current branch adds the first managed-data milestone: GC structures,
nominal inductives, `match`, and recursive ADTs.

## Goal

Own the final ProofScript -> WebAssembly lowering while keeping the common
compiler semantic IR independent of TypeScript, Rust and WebAssembly.

```text
.ps / supported .lean
        |
      Elab
        |
    pskernel
        |
   CheckedCore
        |
     Erasure
        |
   VerifiedIR
        |
 shared target-neutral optimizer
    /       |        \
   TS      Rust      Wasm lowering
                     |
                Wasm target IR
                     |
                binary encoder
                     |
                   .wasm
```

## Shared-IR rule

`PsVerifiedIr` says what an erased ProofScript program means. It does not say
how any target represents it.

Allowed in VerifiedIR:

- PSC semantic primitive types;
- functions, lambdas, calls, lets and conditionals;
- structures, inductives, constructors, projections and matches;
- semantic intrinsics;
- target-neutral capability/import identities;
- semantics-preserving optimization facts.

Forbidden in VerifiedIR:

- JS `number`/`bigint`, JS object representation, npm or Node assumptions;
- Rust integer spellings, ownership, borrowing, lifetimes, traits, Cargo or ABI
  choices;
- Wasm value types/opcodes, GC heap types, memories/tables, WIT/WASI or binary
  sections;
- target-specific layouts, calling conventions or allocation policies.

Backend-specific target IRs are downstream of VerifiedIR.

## Initial Wasm 3 representation

```text
PSC                 execution type       compact storage
UInt8 / Int8        i32                  i8 where useful
UInt16 / Int16      i32                  i16 where useful
UInt32 / Int32      i32                  i32
UInt64 / Int64      i64                  i64
USize / ISize       i32/i64 by profile   target word
Float32             f32                  f32
Float               f64                  f64
Bool                i32                  compact backend choice
Char                i32 scalar value     i32
Nat / Int           exact PSC runtime representation
String              PSC runtime reference
Unit                no runtime payload
```

`Nat` and `Int` are never silently narrowed. A proved range specialization
may choose a machine representation as an optimization.

## Runtime strategy

Use a hybrid representation:

- Wasm GC for structures, inductives, closures, lists/options/results and
  generic managed/reference data;
- linear memory and SIMD for byte buffers, packed integers, Float32 arrays,
  images, tensors, codecs and other dense computational data.

Typed function references and direct calls should be used for higher-order
functions where possible. Tail calls may implement suitable recursion without
growing the Wasm stack.

## Profiles

The first assurance profile is deterministic and semantics-preserving.
Relaxed SIMD or floating-point transformations that weaken deterministic PSC
semantics must be explicit opt-in modes and cannot silently inherit verification
claims from the deterministic profile.

`wasm32` and `wasm64` are target profiles. `USize`/`ISize` follow the
selected profile; their width is not hard-coded into shared IR.

## Portable libraries

A pure package depending only on portable PSC APIs should compile through all
three backends:

```text
library.ps -> VerifiedIR
              +-> backend-ts   -> JS/npm
              +-> backend-rust -> native/Cargo
              +-> backend-wasm -> .wasm / future component
```

Target-specific imports narrow the target set explicitly.

## Current large-feature merge boundary

The first Wasm infrastructure merge is complete. The next merge unit is
**GC structures + nominal inductives + match**, kept together because all three
share the same managed-data representation and type-index discipline.

Merge this branch only when all of these are true:

1. the branch is mergeable against the live self-host line, with no unresolved
   shared-IR/erasure conflicts;
2. portable-source and shared-IR-neutrality gates are green;
3. the complete Lean/Lake workspace builds;
4. TypeScript and erasure regression suites are green;
5. Wasm lowering/unit tests are green;
6. independent Node validation and execution cover:
   - ordinary GC structures;
   - packed signed/unsigned structure fields;
   - nominal inductive base + constructor subtypes;
   - multi-constructor `match`;
   - constructor field binding through `ref.test` / `ref.cast`;
   - a recursive ADT whose constructor contains a reference to its own base
     type;
   - a recursive function over that ADT;
7. the normal PSC1 workflow has no new failure before the already-known
   self-host source-readiness/PSC0 blockers;
8. Wasm remains non-default and does not gate JavaScript self-host closure.

Current status:

```text
[done] target-neutral projection owner identity
[done] GC struct types + struct.new/struct.get
[done] packed i8/i16 structure storage/access
[done] nominal inductive base type
[done] constructor GC subtypes
[done] ref.test / ref.cast match lowering
[done] lexical constructor-field bindings
[done] multi-constructor MaybeU32 runtime execution
[done] recursive U32List type lowering
[done] recursive listLength runtime execution
[green] dedicated Owned Wasm backend integration workflow
[next] live-base mergeability check / integration PR
[post-merge] generic monomorphization for GC ADTs
[post-merge] closures / typed function references
[post-merge] String / Array / exact Nat / Int runtime
[post-merge] SIMD / WASI / components / formal preservation proof
```

This merge still does **not** claim full Wasm language coverage. Generic ADTs
remain fail-closed until target-neutral specialization/monomorphization exists.

## Development order

1. Freeze and guard the target-neutral VerifiedIR contract.
2. Add Wasm target IR and scalar lowering.
3. Add deterministic module/type/function encoding.
4. Add integer and floating-point intrinsics.
5. Add control flow, functions and direct calls.
6. Add structures/inductives with Wasm GC.
7. Add closures/typed function references.
8. Add String, Array, Nat/Int runtime representations.
9. Add linear-memory packed arrays and SIMD.
10. Add host capability mapping and later WIT/WASI/component support.
11. Differential-test TS vs Rust vs direct Wasm.
12. Add `psc.wasm` cross-host self-hosting only after the backend is stable.
13. Formalize VerifiedIR -> Wasm target-IR preservation, then cover exact
    binary encoding/validation.

The branch must rebase regularly onto the self-host line but must not make the
current JS fixed point depend on Wasm.
