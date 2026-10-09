# Enabled TS/JS runtime contract

## Status and scope

This is the candidate contract for the currently enabled PSC0 TS/JS runtime on
`psc0/strict-sh1-v1`, prepared against immutable baseline
`ed5d00aca0743bde583b45fe7756dd494ac3960f`. The implementation and case files are
prepared for qualification; this document does not record an executed pass.

The machine-readable authority is
[enabled-runtime-contract.json](enabled-runtime-contract.json). It contains six
primitive representations, the arity-one Array type, all 45 enabled intrinsic
operations, 186 finite native-reference cases and two source-position families.
The operation list is checked against the exact baseline
`Ps.CompilerIr.CheckTypes.psIrCheckIntrinsicSignature` list. Four optional
machine-integer/floating operation families remain refused by the existing IR
checker. No optional scalar, external ABI, new source grammar or new source
built-in is enabled here.

The toolchain remains Lean 4.34.0 (commit
`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`), Node 22.23.3 and TypeScript 7.0.2. The selected
authoring seed remains R. The 61 handwritten `.lean` modules remain authoritative;
the active `.ps` grammar remains the bounded new-only `ps-0.9-r3` edition.
Provider, kernel, metatheory, source grammar and the UTF-8 cache algorithm are
outside this change.

## Representations

| Type | Canonical runtime value |
|---|---|
| Nat | A primitive, nonnegative JavaScript bigint. |
| Int | A primitive JavaScript bigint, with no machine-width restriction. |
| Bool | A primitive JavaScript boolean. |
| Char | Exactly one Unicode scalar, encoded by one non-surrogate UTF-16 code unit or one valid surrogate pair. |
| String | Well-formed UTF-16 encoding a finite sequence of Unicode scalars. No normalization or replacement. |
| Unit | JavaScript `undefined`. |
| Array A | A dense array whose elements satisfy A's representation relation. Pointer identity is not a source-language observation. |

The original-IR carrier already checks natural/integer/boolean payload types and
own-compiler model brands. The new string check rejects lone high surrogates, lone
low surrogates and malformed pairs before portable code receives them. It does
not repair input. This matters because an unchecked surrogate literal could
otherwise produce an invalid Char through the existing string-get operation.

A TypeScript annotation is not an arbitrary-host-input validator. These relations
describe well-typed language values and validated IR carriers. Host-supplied
negative naturals, malformed arrays or arbitrary strings passed as Char do not
become source values because a JavaScript caller bypasses the type boundary.

### Work bounds

`inspectOriginalIrCarrier` retains the existing model-node budget and adds an
explicit per-string validation ceiling using the same `maxNodes` value. It
checks UTF-16 length in constant time before scanning. A string longer than that
ceiling returns `ir-carrier-resource-limit`, with incomplete traversal, rather
than doing an unbounded validation scan. A malformed string within the ceiling
returns `invalid-ir-scalar-carrier`.

Model-node visit counts do not include UTF-16 units. The per-string ceiling is
not a combined allocation or whole-run time budget. Portable preflight still
has its independent UTF-8-byte and model-work bounds; type checking retains its
separate type-work bound. In particular, increasing portable `maxSteps` does
not bypass the host carrier ceiling. Ordinary host allocation failure is not
advertised as a normal source value or as a proof of total execution.

## Complete operation domains

All operands below satisfy their canonical representation relation. Detailed
signatures, source-name mappings and named cases are in the JSON ledger.

| Family | Operations and value laws |
|---|---|
| Nat (9) | `natAdd`, `natMul`: exact arithmetic; `natSub`: truncated at zero; `natDiv`: quotient with a/0 = 0; `natMod`: remainder with a%0 = a; `natEq`, `natNe`, `natLe`, `natLt`: equality/order. |
| Int (10) | `intOfNat`: representation-preserving inclusion; `intRepr`: signed decimal text; `intNegSucc`: -(n+1); `intNeg`, `intAdd`, `intSub`, `intMul`: exact integer operations; `intEq`, `intLe`, `intLt`: equality/order. |
| Bool (5) | `boolNot`, `boolAnd`, `boolOr`, `boolEq`, `boolNe`: ordinary Boolean laws. Source and/or have short-circuit demand semantics; this gate's truth tables alone do not qualify lowering of that demand behavior. |
| Char (2) | `charOfNat`: scalar n for n<0xd800 or 0xdfff<n<0x110000, otherwise NUL; `charToNat`: scalar value. No UInt32 wrapping. |
| String (10) | `stringPush`, `stringSingleton`, `stringAppend`: sequence construction; `stringLength`: scalar count; `stringUtf8ByteSize`: UTF-8 size; `stringNext`, `stringGet`, `stringAtEnd`, `stringExtract`: raw-byte-position rules below; `stringEq`: exact equality without normalization. |
| Array (9) | `arrayEmptyWithCapacity`, `arraySize`, `arrayPush`; proof-required `arrayGet`, `arraySet`; total `arrayGetD`, `arraySetIfInBounds`; ordered `arrayMap`, `arrayFoldl`. |

The checked-IR list is broader than the installed source prelude. For example,
`natNe`, the three Int comparisons and Bool equality/inequality have no direct
source-name mapping in the current erasure mapper. The prelude does not install
proof-required `Array.getInternal` or `Array.set`, although the mapper recognizes
their checked Core calls and the IR checker admits their operations. This
contract does not widen source exposure.

## Array bounds and proof provenance

Lean's `Array.getInternal` and `Array.set` require an actual proof of
`index < size`. The current erasure mapper drops that proof. The baseline
backend then indexed or updated JavaScript directly: invalid directly
constructed IR could return `undefined` at a non-Unit type or create holes.

The two emitted operations now guard the index before converting it to a Number
or reading/copying/updating the array. Invalid bounds throw a non-value fault:

- `{ code: "PSC0_ARRAY_GET_BOUNDS" }`
- `{ code: "PSC0_ARRAY_SET_BOUNDS" }`

The small thrown record avoids adding a new capturable Error/RangeError global.
The existing immediately invoked function argument list remains in place:
array, index and—for set—new value are each evaluated once in their original
left-to-right order before the guard executes. Consequently, a failure while
evaluating the new value still occurs before an invalid-index guard. Valid
operations preserve result values and original-array values. A valid Unit
element may be `undefined`; bounds are checked independently of the element.

The total operations retain their separate meaning. `arrayGetD` returns its
supplied fallback outside bounds; `arraySetIfInBounds` preserves the array
outside bounds. Map visits elements left to right. Fold visits the half-open
range `[start, min(stop, size))`, using the initial accumulator without invoking
the callback if that range is empty. Conditional on successful allocation,
capacity does not affect the observable empty-array value. The native reference
uses only capacity hints 0 and 17; native and JavaScript allocation behavior,
memory use and exhaustion are not claimed identical.

**Defensive refusal does not reconstruct an erased proof.** Source preservation
still needs the source bounds premise and erasure correspondence. A raw-IR strict
admission policy cannot conclude that every access is total merely because an
IR type check and these defensive runtime checks exist.

## Unicode and text positions

The existing backend string algorithm is retained. On canonical strings:

- Get returns the scalar at a UTF-8 scalar-start offset before end, otherwise 'A'.
- Next adds the current scalar's UTF-8 width at such a start, otherwise one.
- At-end compares the Nat offset with the UTF-8 byte size.
- Extract returns empty for start>=stop or a start that is not a scalar start
  before end. Otherwise it copies to the matching stop boundary, or to the end
  when no matching boundary occurs.

These are raw Nat offsets; they are not proof-carrying valid positions. Pinned
Lean 4.34.0's pure reference and C runtime agree with the current backend,
including mid-byte extraction behavior. Lean's documentation calls that
extraction region unspecified, so the ledger pins the concrete implementation
instead of making a future-version guarantee.

Source positions use original UTF-8 byte offsets and one-based lines/columns.
A column counts Unicode scalars, not UTF-16 units or graphemes. CRLF consumes two
bytes and one newline. The initial .ps BOM consumes three bytes without moving
the initial column. The added finite position families include supplementary
characters, a carriage-return/newline pair and the .ps BOM boundary.

## Reference and gate

[StrictRuntimeReference.lean](../../../test/StrictRuntimeReference.lean) imports
Lean, not PSC0. Its 186 observations execute the pinned native Lean operations.
Its valid array-get/set observations carry actual in-bounds proofs. It does not
manufacture a Lean value for a defensive JavaScript bounds failure.

[sh1-strict-runtime-conformance.mjs](../../../scripts/sh1-strict-runtime-conformance.mjs)
exposes two entry points for the existing qualification driver:

1. `runNativeStrictRuntimeReference({ root, outDir })` runs the pinned Lean
   version check and `lake env lean --run test/StrictRuntimeReference.lean` once.
   It retains the actual stdout/stderr, commands, source/contract hashes,
   Lean identity and complete native observations.
2. `runStrictRuntimeConformance({ compiler, compilerSha256, root, outDir,
   tsc, reference })` constructs one fixture module with that executing
   compiler's own IR factories, checks its original IR and emits/compiles it once
   with TS7. It compares every value with the independent reference.

The second entry also exercises eight invalid-bounds refusals, nine
single-evaluation/order observations, five invalid-text carrier refusals,
a string-validation limit boundary and two text-position families. Negative
host-index and callback probes are explicitly host observations, not newly
admitted source or an FFI capability. Unit and large integers use unambiguous
JSON-safe encodings.

The receipt retains the complete observations, operation coverage, original-IR
report, exact generated artifact hashes and native-reference identity. No
qualifier, workflow or package script is modified by these files; the root
driver integrates them into a finite coherent qualification.

Both entry points keep `strictSh1Qualified: false`. This gate supplies bounded
executable correspondence and defensive-boundary evidence. General source/Core/
IR/backend preservation, demand behavior, erased proof provenance, provider
acceptance and strict-profile activation remain distinct obligations.

## Pinned source evidence

- Baseline IR signatures: [CheckTypes.lean](https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/packages/compiler-ir/src/Ps/CompilerIr/CheckTypes.lean).
- Baseline proof erasure and source mappings: [Erasure/Expr.lean](https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/packages/erasure/src/Ps/Erasure/Expr.lean).
- Pinned Char and proof-required get: [Lean Prelude](https://github.com/leanprover/lean4/blob/v4.34.0/src/Init/Prelude.lean).
- Pinned set/setIfInBounds: [Array/Set.lean](https://github.com/leanprover/lean4/blob/v4.34.0/src/Init/Data/Array/Set.lean).
- Pinned map/fold reference: [Array/Basic.lean](https://github.com/leanprover/lean4/blob/v4.34.0/src/Init/Data/Array/Basic.lean).
- Pinned raw positions: [String/Basic.lean](https://github.com/leanprover/lean4/blob/v4.34.0/src/Init/Data/String/Basic.lean)
  and [runtime/object.cpp](https://github.com/leanprover/lean4/blob/v4.34.0/src/runtime/object.cpp).
