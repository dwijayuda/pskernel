# ProofScript WebAssembly backend plan

Status: **W2 closed on a fully green executable closure matrix; W3 Nat/Int BigInt work remains next**

This plan adds WebAssembly as an execution backend for pskernel-admitted
ProofScript programs. It does not change ProofScript logical semantics and does
not add WebAssembly code generation to the trusted kernel.

## 0. Current implementation checkpoint

Implemented on `feature/wasm-backend`:

- ProofScript-owned typed WasmIR package;
- fail-closed verified IR -> WasmIR lowering;
- Binaryen 132.0.0 emitter with explicit MVP feature profile;
- Bool/Unit first-order functions, calls, let, if, and Bool intrinsics;
- UInt8/UInt16/UInt32/UInt64 runtime values with physical i32/i64 lowering;
- semantic Bool and narrow-UInt normalization before raw Wasm use;
- logical Wasm export ABI metadata plus a JS host adapter that restores unsigned UInt32/UInt64 values;
- canonical and optimized Binaryen validation tests;
- verified source JS/Wasm differential gate, including noncanonical host i32 Bool inputs;
- `@proofscript/compiler` checked-core -> Wasm orchestration;
- `psc check/build/run --verified --target wasm`;
- `.wasm` and `.wat` build artifacts plus Binaryen/profile/export-ABI manifest metadata;
- full npm workspace lock repair and a workspace-lock anti-drift gate.

Still intentionally unsupported:

- runtime Nat/Int until arbitrary-precision semantics are preserved;
- String/Char ABI;
- structures and inductive ADTs;
- generic runtime values and closures;
- external imports/FFI;
- fixed-width UInt arithmetic/comparison intrinsics until they exist explicitly in verified IR;
- structures/ADTs, function values, and recursive runtime data until their Wasm representations land.

W2 closure is frozen at commit
`f1f59a3b9e7018089743df3111f3ad21bc23c380`, validated by GitHub Actions
workflow run `35978437272` on 2026-09-24. The executable closure matrix passed:

- exact dependency install;
- full package-graph build;
- elaboration;
- erasure;
- package integration;
- TypeScript backend;
- WebAssembly backend;
- root test suite;
- workspace-lock anti-drift;
- source-shape anti-drift;
- architecture anti-drift.

This checkpoint is the pre-`main`-integration W2 baseline. Any integration or
W3 work must preserve the same gates before W2 is considered stable on the new
HEAD.

## 1. Goals

The backend MUST preserve the repository's canonical trust split:

```text
.ps / supported .lean
        |
        v
syntax / Meta / elaboration
        |
        v
pskernel admission
        |
        v
checked-core
        |
        v
verified erasure
        |
        v
VerifiedIrModule
        |
        +-------------------+
        |                   |
        v                   v
   backend-ts          wasm-lowering
        |                   |
        v                   v
 TypeScript / JS          WasmIR
                            |
                            v
                       backend-wasm
                            |
                            v
                     Binaryen 132.0.0
                            |
                            v
                       .wasm / .wat
```

The WebAssembly backend is **untrusted compiler infrastructure**. Logical
authority remains pskernel declaration admission.

Goals:

- compile a documented subset of the existing verified runtime IR to WebAssembly;
- preserve Lean/ProofScript runtime semantics rather than choosing convenient
  machine representations that silently change meaning;
- keep target capability checking explicit and fail closed;
- keep a ProofScript-owned typed Wasm IR between verified IR and Binaryen;
- support deterministic binary/text emission and differential JS/Wasm tests;
- allow the backend to grow toward browser, Node, and standalone Wasm runtimes;
- leave room for future compiler-refinement/equivalence proofs.

Non-goals for the initial backend:

- putting code generation or Binaryen in `src/kernel`;
- claiming Binaryen is a verified compiler;
- compiling arbitrary Lean 4;
- mapping arbitrary-precision `Nat` or `Int` to machine `i64`;
- accepting unsupported runtime features by approximation;
- making WebAssembly representation details source-language types.

## 2. Trust boundary

The dependency direction is one-way:

```text
kernel <- checked-core <- erasure <- compiler-ir
                                  |
                                  v
                             wasm-lowering
                                  |
                                  v
                               wasm-ir
                                  |
                                  v
                             backend-wasm
                                  |
                                  v
                               Binaryen
```

Forbidden dependencies:

- kernel -> wasm-ir / wasm-lowering / backend-wasm / Binaryen;
- checked-core -> wasm packages / Binaryen;
- erasure -> wasm packages / Binaryen;
- compiler-ir -> Binaryen.

Binaryen validates and emits WebAssembly. It does not establish logical truth or
ProofScript theorem correctness.

## 3. Versioned target profile

The first target profile is:

```text
proofscript-wasm32-mvp-js-v1
```

It is JavaScript-hosted, 32-bit-memory WebAssembly with an explicitly pinned
feature set. Do not use a floating "all features" setting.

Initial intended feature set:

- WebAssembly MVP numeric/control instructions;
- reference types / typed function references when needed;
- GC only when ADT/structure lowering lands;
- bulk memory only when the runtime requires it;
- no threads;
- no SIMD requirement;
- no exception-handling requirement.

Binaryen is pinned to **132.0.0** for the first implementation checkpoint.
Changing Binaryen is a deliberate compatibility update with regenerated
backend evidence.

## 4. Source types versus backend representations

WebAssembly machine types MUST NOT leak into ordinary ProofScript source.
Do not add `WasmI32`, `WasmI64`, pointers, or Wasm references as ordinary
verified-core language primitives.

ProofScript retains its foundational names:

```text
Nat Int UInt8 UInt16 UInt32 UInt64 USize Float Bool Char String Unit
```

The backend owns their runtime representation.

Planned representation matrix:

| ProofScript type | Wasm representation | Initial policy |
|---|---|---|
| Bool | i32 0/1 | W1 |
| Unit | no value | W1 |
| UInt8 | i32 with 8-bit invariant | after verified-IR support |
| UInt16 | i32 with 16-bit invariant | after verified-IR support |
| UInt32 | i32 | after verified-IR support |
| UInt64 | i64 | after verified-IR support |
| Char | i32 with Unicode-scalar invariant | later |
| Float | f64, only after Lean/runtime differential evidence | later |
| Nat | arbitrary-precision runtime value | MUST NOT narrow to i64 |
| Int | arbitrary-precision runtime value | MUST NOT narrow to i64 |
| String | runtime/reference representation | later |
| USize | target-platform dependent | fail closed initially |
| structures / ADTs | Wasm GC or explicit runtime layout | later |
| function values | funcref + closure environment | later |

## 5. Nat and Int semantic rule

Lean/ProofScript `Nat` and `Int` are arbitrary precision.

The backend MUST NOT implement:

```text
Nat -> i64
Int -> i64
```

as a general representation.

The first executable Nat/Int strategy should be a JS-hosted arbitrary-precision
runtime using JavaScript `BigInt` behind explicit Wasm imports/references.
A later standalone runtime may replace this with a native big-integer
representation without changing source semantics.

Boundary regressions MUST include at least:

```text
0
1
255
256
2^32
2^64 - 1
2^64
2^100
```

and negative values for `Int`.

## 6. USize rule

`USize` depends on target platform width. The first wasm32 profile MUST reject
runtime `USize` until target-relative semantics are explicitly modeled and
tested. It must not silently reuse the host Lean oracle's machine width.

Required diagnostic class:

```text
PS_WASM_UNSUPPORTED_USIZE
```

## 7. Dependent types and proofs

WebAssembly not having dependent types is not a reason to reject dependent
ProofScript programs.

The decision point is after pskernel admission and verified erasure:

```text
dependent source
    -> pskernel
    -> erase proofs/type-only indices
    -> runtime IR
    -> Wasm
```

A dependent program is WebAssembly-compatible when its erased runtime
representation is supported. Proofs and `Prop` values do not become runtime
Wasm values.

## 8. Capability policy

Backend unsupportedness is target-specific, not a change to language meaning.

A source can pass:

```text
psc check app.ps
```

while:

```text
psc build app.ps --target wasm
```

fails with a specific backend capability diagnostic.

Initial capability policy:

| Feature | Initial Wasm status |
|---|---|
| Prop/proofs | supported by erasure |
| dependent types | supported when runtime erasure is representable |
| Bool | W1 supported |
| Unit | W1 supported |
| fixed-width UInt values/calls | W2 supported with JS ABI normalization |
| fixed-width UInt addition | W2 supported with Lean-faithful modular wrapping |
| remaining fixed-width UInt arithmetic/comparisons | blocked until explicit verified-IR intrinsics land |
| Nat / Int | blocked until arbitrary-precision runtime lands |
| String | blocked until runtime ABI lands |
| structures | blocked until WasmGC/layout checkpoint |
| inductive ADTs | blocked until WasmGC/layout checkpoint |
| direct first-order calls | W1 |
| direct recursion | blocked at source-Wasm boundary until recursive runtime representations are supported |
| noncapturing lambdas | blocked until function-reference lowering lands |
| capturing lambdas | blocked until closure conversion |
| generic runtime values | blocked until monomorphization/uniform representation |
| USize | blocked initially |
| JS/npm FFI | explicit imports only, later |
| async/Promise | blocked initially |
| unsafe runtime features | blocked in verified-Wasm profile |

Unsupported constructs MUST fail before Binaryen emission.

## 9. WasmIR

`@proofscript/wasm-ir` owns the target-neutral representation choices used by
the Wasm backend. Binaryen objects must not be stored in this IR.

Initial model:

```ts
type WasmValueType = 'i32' | 'i64' | 'f32' | 'f64';

interface WasmFunction {
  name: string;
  parameters: readonly WasmValueType[];
  result: WasmValueType | null;
  locals: readonly WasmValueType[];
  body: WasmExpr;
}
```

The IR will grow deliberately for references, GC structures, tables, memories,
imports, and closure representations.

Every WasmIR module must pass a ProofScript-owned structural validator before it
is handed to Binaryen.

## 10. Package boundaries

Add:

```text
packages/wasm-ir
packages/wasm-lowering
packages/backend-wasm
```

Responsibilities:

- `wasm-ir`: typed Wasm-oriented IR + structural validation;
- `wasm-lowering`: `VerifiedIrModule -> WasmIrModule`, capability checks,
  representation selection, closure/ADT lowering later;
- `backend-wasm`: Binaryen adapter, feature configuration, Binaryen validation,
  .wasm/.wat emission and optimizer policy.

No package above may grant proof authority.

## 11. Binaryen policy

Use the npm `binaryen` package pinned to an exact stable version.

For each emitted module:

1. build Binaryen IR from validated WasmIR;
2. enable only the target profile's explicit feature set;
3. require Binaryen module validation;
4. emit deterministic text/binary artifacts;
5. optionally optimize only after an unoptimized artifact is available.

Two artifact modes are planned:

```text
certified/canonical:
  deterministic, minimal lowering/encoding transformations

release:
  canonical Wasm -> Binaryen optimization -> optimized Wasm
```

"Certified" does not initially mean formally proven compiler correctness. It
means the canonical artifact is the stable target for future refinement proofs
and translation validation.

## 12. Acceptance gates

Every supported executable feature needs all applicable gates:

1. source -> pskernel -> checked-core acceptance;
2. checked-core -> verified IR;
3. verified IR -> WasmIR;
4. WasmIR structural validation;
5. Binaryen validation;
6. `WebAssembly.validate` where the host provides it;
7. instantiate and execute;
8. compare the result against the existing verified TypeScript/JavaScript
   backend for the same checked IR;
9. compare optimized and unoptimized Wasm behavior;
10. deterministic emission regression.

No semantic support is marked landed from a Binaryen validation pass alone.

## 13. Implementation milestones

### W0 - architecture and fail-closed foundation

- add this plan;
- add `wasm-ir`, `wasm-lowering`, and `backend-wasm` package boundaries;
- add architecture dependency rules;
- define capability diagnostics;
- no claim of executable Wasm support yet.

### W1 - scalar control MVP

Support the semantically direct subset:

- Bool;
- Unit;
- direct first-order functions;
- variables;
- let;
- if;
- Bool intrinsics.

Produce a real Binaryen module and execute differential JS/Wasm tests.

### W2 - fixed-width numeric values and direct recursion

Current W2 checkpoint supports runtime values and direct calls for:

- UInt8 -> i32 with 8-bit normalization;
- UInt16 -> i32 with 16-bit normalization;
- UInt32 -> i32 bit representation;
- UInt64 -> i64 bit representation;
- logical ABI metadata retained separately from physical Wasm types;
- JS-host normalization so UInt32/UInt64 high-bit results remain unsigned.

Fixed-width UInt addition is implemented with Lean-faithful modular wrapping:
UInt8/UInt16 normalize after addition, UInt32 uses i32 wrapping, and UInt64 uses
i64 wrapping with unsigned host-ABI restoration. Other arithmetic/comparison
intrinsics remain blocked until they exist explicitly in verified IR. Direct
recursion and noncapturing function references remain later work rather than
being silently approximated.

Do not introduce Wasm-specific source types.

### W3 - arbitrary-precision Nat / Int

Land a JS-hosted BigInt ABI first. Required properties:

- exact arbitrary-precision behavior;
- Lean-compatible saturating Nat subtraction;
- Lean-compatible zero-divisor behavior for Nat div/mod;
- explicit host-import contract;
- large-value differential corpus.

A standalone Wasm bigint runtime is a later optimization/portability milestone.

### W4 - structures and inductive ADTs

Use the pinned WebAssembly GC/reference profile when practical.

Implement:

- structures;
- constructors;
- projections;
- pattern matching;
- recursive ADTs.

The lowering must preserve the existing checked IR tag/field meaning.

### W5 - closure conversion and polymorphism

Implement:

- captured-environment analysis;
- closure conversion;
- typed function references/tables as required;
- generic representation policy or monomorphization.

Do not rely on JavaScript closure semantics in the Wasm backend.

### W6 - String / Char / FFI / component boundary

Add:

- Char invariant;
- String runtime representation;
- explicit JavaScript imports/exports;
- browser/Node ABI;
- evaluate the WebAssembly Component Model for external typed interfaces.

### W7 - assurance

Add:

- property/fuzz testing over VerifiedIR -> JS/Wasm;
- translation-validation experiments;
- a formal semantics for the supported WasmIR subset;
- refinement obligations from verified runtime IR to WasmIR;
- reproducible Binaryen/version fingerprints.

## 14. Anti-drift rules

1. Never weaken pskernel or elaboration to make Wasm compilation pass.
2. Never silently narrow `Nat` or `Int`.
3. Never infer target support from successful Binaryen emission alone.
4. Never add a Wasm-only source-language primitive merely to simplify codegen.
5. Unsupported runtime types/features fail closed with stable diagnostics.
6. Keep Binaryen outside the TCB.
7. Keep Wasm representation choices in `wasm-lowering` / `wasm-ir`, not in
   source syntax or checked-core.
8. Every semantic lowering must have JS/Wasm differential evidence.
9. Optimization happens after canonical emission and has its own equivalence
   tests.
10. Version-pin the Wasm feature profile and Binaryen dependency.

## 15. Immediate execution queue

1. Integrate the current `main` branch into `feature/wasm-backend` through a
   controlled merge and rerun the complete W2 closure matrix.
2. Start W3a from `07_WASM_BIGINT_ABI.md`: implement the arbitrary-precision
   Nat JS-host BigInt ABI without narrowing Nat to i64.
3. Keep Int values represented safely, but keep Int arithmetic/literals
   fail-closed until explicit verified-IR Int operations exist.
4. Extend verified-IR fixed-width arithmetic/comparison intrinsics only with
   explicit Lean-faithful semantics and differential evidence.
5. Design WasmGC/layout lowering for structures and inductive ADTs.
6. Add translation-validation/refinement evidence for VerifiedIR -> WasmIR.
