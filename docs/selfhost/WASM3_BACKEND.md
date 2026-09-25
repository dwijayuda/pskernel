# ProofScript owned WebAssembly 3 backend

Development branch: `backend/wasm3-owned`
Integration candidate: `integrate/wasm3-owned`

Status: experimental and deliberately non-blocking for the active PSC1
JavaScript self-host closure.

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

## Merge boundary

Do not wait for the complete Wasm runtime before integrating this branch. A
very long-lived backend branch would increase shared-IR drift and make the
eventual merge riskier.

The first merge into the active self-host line is allowed when all of these are
true:

1. the branch is synchronized with the current self-host source and has no
   unresolved overlap in shared compiler files;
2. the shared-IR neutrality gate is green;
3. the full Lean/Lake build is green;
4. existing TypeScript backend tests affected by shared-IR changes are green;
5. direct Wasm lowering tests are green;
6. an independently validated runtime smoke covers:
   - fixed-width integer arithmetic;
   - `Float32` arithmetic;
   - direct cross-function calls;
   - structured conditional control flow;
   - basic local/`let` lowering;
7. the only remaining CI failures are demonstrably inherited from the base
   self-host branch;
8. `backend-wasm` remains non-default and cannot block the JS self-host path.

The dedicated merge signal is the **Owned Wasm backend integration** workflow.
It must be green at the candidate HEAD after the latest self-host content sync.

This is the **Wasm infrastructure merge**, not a claim that the backend is
feature-complete. After that merge, GC ADTs, closures, String/Array, exact
Nat/Int, SIMD, WASI/components, self-hosting and formal preservation proofs can
continue in small follow-up branches.

Current status:

```text
[done] target-neutral VerifiedIR contract + regression guard
[done] Wasm target IR
[done] scalar type lowering
[done] fixed-width integer operations/comparisons
[done] Float/Float32 operations/comparisons
[done] owned core module/function/export/code encoder
[done] signed/unsigned integer immediate encoding
[done] independent WebAssembly.validate/runtime smoke
[done] direct call lowering
[done] structured if/control flow
[done] typed let bindings -> lexical Wasm locals
[done] independent Wasm integration workflow
[post-merge] GC structures/inductives
[post-merge] closures/typed function references
[post-merge] String/Array/Nat/Int runtime
[post-merge] SIMD/WASI/components/formal proof
```

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
