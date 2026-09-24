# ProofScript WebAssembly arbitrary-precision ABI

Status: **W3 design contract; implementation must remain fail-closed until the
acceptance gates in this document execute successfully.**

This document refines W3 from `06_WASM_BACKEND.md`. It defines how
ProofScript/Lean arbitrary-precision `Nat` and `Int` values can cross the
WebAssembly boundary without narrowing them to machine integers.

## 1. Non-negotiable semantic rule

ProofScript inherits Lean semantics:

```text
Nat = arbitrary precision, non-negative
Int = arbitrary precision, signed
```

Therefore the WebAssembly backend MUST NOT implement general `Nat` or `Int`
as `i32` or `i64`.

The current W2 profile remains:

```text
proofscript-wasm32-mvp-js-v1
```

W3 introduces a distinct Reference Types profile rather than silently changing
the meaning or required features of W2:

```text
proofscript-wasm32-ref-js-v1
```

W2 remains valid for Bool/Unit results and fixed-width UInt values. W3 is used
only when arbitrary-precision host references are required.

## 2. Runtime representation

W3 represents runtime `Nat` / `Int` values physically as WebAssembly
`externref` values whose JavaScript host representation is a JavaScript
`bigint`.

```text
ProofScript Nat / Int
        |
        v
Verified IR semantic primitive
        |
        v
WasmIR logical ABI: nat / int
        |
        v
physical Wasm: externref
        |
        v
JavaScript host value: bigint
```

The host adapter MUST validate:

- Nat values are `typeof value === "bigint"` and `value >= 0n`;
- Int values are `typeof value === "bigint"`;
- results returned by runtime imports satisfy the same invariant;
- no Number conversion is permitted for Nat/Int.

## 3. Internal runtime imports

Compiler/runtime imports are separate from source-level `extern function`
imports.

Use one reserved internal module namespace:

```text
proofscript.bigint.v1
```

Initial Nat imports:

```text
literal : i32 -> externref

nat_add : externref externref -> externref
nat_sub : externref externref -> externref
nat_mul : externref externref -> externref
nat_div : externref externref -> externref
nat_mod : externref externref -> externref

nat_eq  : externref externref -> i32
nat_ne  : externref externref -> i32
nat_le  : externref externref -> i32
nat_lt  : externref externref -> i32
```

These are compiler-internal runtime dependencies. They MUST NOT make
user-declared verified IR imports legal. Source FFI remains independently
fail-closed until its ABI is designed.

## 4. Literal table

Arbitrary-precision constants cannot be embedded in core Wasm numeric
instructions.

Each W3 artifact therefore carries a deterministic literal table:

```ts
interface WasmBigIntLiteral {
  readonly kind: 'nat' | 'int';
  readonly decimal: string;
}
```

A literal expression lowers to:

```text
i32.const <literal-table-index>
call proofscript.bigint.v1.literal
```

The JS host adapter owns the literal array and returns the indexed `bigint`.

Requirements:

- literals are deduplicated by `(kind, canonical decimal text)`;
- table ordering is deterministic;
- Nat literal entries MUST be non-negative;
- artifact metadata records the literal table;
- malformed/out-of-range indexes trap through a stable host diagnostic;
- no decimal parsing occurs inside Wasm.

This design avoids one imported global per literal and avoids a string ABI just
to construct big integers.

## 5. Lean-compatible Nat semantics

The W3 host implementation MUST match the existing verified TypeScript backend.

For `a,b : Nat`:

```text
add(a,b) = a + b
sub(a,b) = if a >= b then a - b else 0
mul(a,b) = a * b

div(a,0) = 0
div(a,b) = a / b for b != 0

mod(a,0) = a
mod(a,b) = a % b for b != 0

eq(a,b) = a == b
ne(a,b) = a != b
le(a,b) = a <= b
lt(a,b) = a < b
```

The host runtime MUST reject a negative value at every Nat entry boundary.
It must never normalize a negative BigInt into a Nat.

## 6. Int staging

The verified IR currently has explicit Nat and Bool runtime intrinsics, but no
general Int arithmetic intrinsic family.

W3 therefore lands in two steps:

### W3a - Nat

Implement:

- Nat parameters/results via `externref`;
- Nat literals through the deterministic literal table;
- every currently defined `nat.*` verified IR intrinsic;
- Bool results of Nat comparisons;
- direct calls/lets/ifs containing Nat values;
- CLI check/build/run through the host adapter.

### W3b - Int values

Implement Int parameters/results as `externref` immediately once the physical
representation is shared safely.

Int literals/arithmetic MUST remain blocked until the verified IR has explicit,
Lean-faithful Int operations. Do not infer Int semantics from JavaScript
operators inside the Wasm backend.

## 7. WasmIR extensions

W3 requires the Wasm-owned IR to grow without leaking Binaryen types upstream.

Planned additions:

```ts
type WasmValueType =
  | 'i32'
  | 'i64'
  | 'f32'
  | 'f64'
  | 'externref';

type WasmAbiValueType =
  | 'bool'
  | 'uint8'
  | 'uint16'
  | 'uint32'
  | 'uint64'
  | 'nat'
  | 'int';

interface WasmIrFunctionImport {
  readonly internalName: string;
  readonly module: 'proofscript.bigint.v1';
  readonly name: string;
  readonly parameters: readonly WasmValueType[];
  readonly result: WasmValueType | null;
}

interface WasmIrModule {
  // existing fields...
  readonly profile:
    | 'proofscript-wasm32-mvp-js-v1'
    | 'proofscript-wasm32-ref-js-v1';
  readonly imports?: readonly WasmIrFunctionImport[];
  readonly bigintLiterals?: readonly WasmBigIntLiteral[];
}
```

Binaryen objects MUST NOT appear in WasmIR.

## 8. Binaryen feature policy

W2:

```text
Binaryen.Features.MVP
```

W3:

```text
Binaryen.Features.ReferenceTypes
```

plus any baseline bits Binaryen requires explicitly for the generated module.

Do not use `Features.All`.

The emitter selects features from the WasmIR profile, not by scanning generated
Binaryen expressions after the fact.

## 9. Host adapter contract

`instantiateProofScriptWasm` becomes responsible for merging internal runtime
imports with caller-provided imports.

Reserved internal imports MUST NOT be overrideable by a caller.

Conceptually:

```text
instantiateProofScriptWasm(artifact, userImports)
  -> build internal bigint runtime imports
  -> reject collisions with reserved module namespace
  -> instantiate WebAssembly.Module
  -> expose semantic host wrappers
```

The exported semantic ABI remains pleasant JavaScript:

```ts
instance.exports.addHuge(
  18446744073709551616n,
  1000000000000000000000000000000n,
)
```

No caller handles `externref` explicitly.

## 10. Trust boundary

The JS BigInt runtime is **not part of the theorem/proof TCB**.

It is, however, part of the execution-semantics trust story for W3 binaries
until compiler/runtime refinement is formally established.

The report/manifest should distinguish:

```text
proofStatus: kernel-verified
executionRuntime:
  profile: proofscript-wasm32-ref-js-v1
  bigintRuntime: proofscript.bigint.v1
  bigintRuntimeMode: js-host
```

A successful Binaryen/WebAssembly validation does not prove the BigInt host
runtime implements Lean Nat semantics.

## 11. Required W3a differential corpus

Every operation is compared against the existing TypeScript backend for at least:

```text
0
1
2
255
256
2^32 - 1
2^32
2^64 - 1
2^64
2^100
10^100
```

For two-argument operations include:

- equal values;
- smaller/larger left operand;
- zero right operand for div/mod;
- values crossing 32-bit and 64-bit boundaries;
- values much larger than machine integers.

Required special assertions:

```text
0 - 1 = 0
1 - 2 = 0
x / 0 = 0
x % 0 = x
```

## 12. Acceptance gates

W3a is not complete until all are green:

1. `@proofscript/wasm-ir` validates externref/import/literal-table invariants;
2. `@proofscript/wasm-lowering` lowers real verified Nat source without i64 narrowing;
3. `@proofscript/backend-wasm` emits a Reference Types module accepted by Binaryen;
4. host `WebAssembly.validate` succeeds;
5. host instantiation supplies the reserved BigInt imports;
6. large Nat source programs execute;
7. JS/Wasm differential corpus passes;
8. canonical emission remains deterministic;
9. optimized and unoptimized Wasm agree;
10. `psc check --verified --target wasm` accepts supported Nat programs;
11. `psc build --verified --target wasm` records W3 runtime/profile metadata;
12. `psc run --verified --target wasm` accepts/returns arbitrary BigInt values;
13. W2 fixed-width MVP modules remain byte/behavior compatible unless an
    intentional versioned change is documented.

## 13. Standalone future

The JS-host BigInt runtime is the first correct implementation, not the final
portable representation.

A later standalone profile may implement Nat/Int using Wasm linear memory or GC
arrays of limbs. That work MUST preserve the same verified IR semantics and
semantic ABI and receive its own versioned target profile.

Do not block W3 on a standalone bigint allocator.
