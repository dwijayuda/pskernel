# PSC1 Semantics, Runtime, and Effects

Status: **normative semantic/runtime companion**

This document concentrates the cross-backend semantics that must remain stable
when PSC1 is emitted to TypeScript/JavaScript, Rust, or WebAssembly.

## 1. Semantic layering

PSC1 uses one semantic path:

```text
Source AST
  -> Lean-compatible Meta / Elab
  -> pskernel
  -> CheckedCore
  -> Erasure
  -> VerifiedIR
  -> target lowering
```

No backend is allowed to become an alternate source type checker.

The logical language and executable language are related but not identical:
proof-irrelevant content may erase, while executable content must retain its
observable PSC1 meaning.

## 2. Foundational scalar contract

Frozen type names:

```text
Nat Int
UInt8 UInt16 UInt32 UInt64 USize
Int8 Int16 Int32 Int64 ISize
Float Float32
Bool Char String Unit
```

### 2.1 Exact integers

`Nat` and `Int` are exact mathematical types. Their meaning does not depend
on JavaScript's safe-integer range, a Rust target word size, or a Wasm machine
integer.

Backends may choose arbitrary precision or another representation that
preserves the language semantics.

A compiler optimization may specialize to a fixed-width representation only
when the required range fact is justified and the observable result remains
PSC1-equivalent.

### 2.2 Fixed-width integers

`UInt8`, `UInt16`, `UInt32`, `UInt64`, `Int8`, `Int16`, `Int32`,
and `Int64` are semantically fixed-width.

The source semantics must determine overflow, narrowing, signedness, shift,
division/remainder, bitwise, and conversion behavior. A target's debug/release
overflow mode or implicit cast behavior is never the language definition.

### 2.3 Target-word integers

`USize` and `ISize` have target-profile word width.

A build/profile must make the effective width inspectable and deterministic.
Code whose result depends on word width is correspondingly target-profile
dependent; a backend must not pretend such code is bit-identical across
wasm32, wasm64, 32-bit native, and 64-bit native profiles.

### 2.4 Floating point

`Float` and `Float32` are distinct semantic types following the pinned
PSC1/Lean-compatible model for supported operations.

Backends must preserve required rounding/comparison/bit behavior for every
operation in the frozen scalar matrix.

A deterministic or verified profile MUST NOT silently enable fast-math,
reassociation, relaxed SIMD behavior, or another transform that changes
observable semantics.

### 2.5 Bool, Char, String, Unit

These retain their language semantics independent of representation.

A backend may encode `Bool` compactly, represent `String` with target
runtime structures, or erase/unit-optimize `Unit` where valid, but target
representation cannot become source-visible identity.

## 3. Scalar operation/conversion matrix: OPEN FREEZE OBLIGATION

The repository baseline requires a single normative table before SH7 freeze.
The table must cover every operation/conversion the frozen source accepts.

At minimum:

| Area | PSC1 must freeze |
| --- | --- |
| fixed-width `+ - *` | overflow/wrap semantics |
| division/remainder | zero-divisor and signed quotient/remainder rules |
| shifts/rotates | width/range/masking and sign behavior |
| bitwise | width and sign interpretation |
| widening | exact value-preserving cases |
| narrowing | truncation/wrap/rejection |
| signed <-> unsigned | exact bit/value meaning |
| `Nat`/`Int` <-> machine ints | checked/modulo/other explicit rule |
| integer <-> floating | rounding and out-of-range rules |
| `Float32` <-> `Float` | widening/narrowing rule |
| float comparison | NaN and signed-zero behavior |
| float bit conversions | payload/canonicalization where exposed |
| `USize`/`ISize` | profile width and cross-target behavior |

When an operation is inherited from pinned Lean 4.34 semantics, that is the
preferred source of truth.

When PSC1 introduces a portable operation not directly inherited, it must be
specified once at the language level before any backend implementation is
accepted.

The TypeScript, Rust, and Wasm lanes must consume one shared conformance corpus.

## 4. Data semantics

### 4.1 Structures

A structure is a nominal checked data declaration with projections and
constructor semantics.

Backend representation may be an object, struct, GC record, packed aggregate,
or another layout. None of those representations is the source meaning.

### 4.2 Inductives

An inductive is a checked algebraic family with constructors and elimination
rules.

Runtime representation must preserve constructor identity and fields for the
executable subset.

Backend tag numbers are representation detail.

### 4.3 Option and error values

Absence is explicit through `Option`-style data, not host
`null`/`undefined`.

Recoverable failure is explicit through a typed `Result`/`Except`-style
value/effect channel rather than an implicit host exception.

### 4.4 Collections

PSC1 self-hosting requires the useful compiler subset of:

- List;
- Array;
- ordered Map;
- ordered Set;
- Prod/tuple values;
- Option;
- typed error values.

Algorithms and traversal helpers SHOULD live in libraries instead of creating
new language constructs.

## 5. Equality, ordering, and identity

Portable PSC1 equality and ordering come from the language's declared
semantics/typeclass machinery.

They do not come from:

- JavaScript `===` object identity;
- Rust pointer/address identity;
- Wasm reference identity;
- memory offsets;
- GC addresses.

This matters for optimization and proof rewriting: a semantically pure value
may be copied, shared, reallocated, boxed, or unboxed without changing its
meaning.

## 6. Pure computation

Ordinary portable PSC1 functions are referentially transparent with respect to
the portable language semantics.

A host binding may be classified as pure only if its capability manifest says
that it is a trusted deterministic runtime assumption compatible with the
declared signature.

Even then, host execution is never proof evidence.

Pure optimizations may duplicate, remove, or reorder pure computations only
when the relevant PSC1 semantics permits that transformation.

## 7. Effect boundary

Operations that observe or mutate the external world are effectful.

Examples:

- filesystem;
- process invocation;
- network;
- clock;
- randomness;
- mutable host-global state;
- host APIs whose normal failure is reported by exceptions/rejections.

Such operations must cross an explicit capability/effect boundary.

They MUST NOT masquerade as ordinary pure functions merely because a target
language makes them easy to call.

## 8. Compiler effect

The first self-host compiler requires a concrete context/state/error effect,
conceptually:

```text
CompilerM α
  = Reader Context
  + State CompilerState
  + typed Error
  + deterministic sequencing
```

The exact internal representation is an implementation choice.

Required behavior includes:

- reading immutable context/config;
- explicit state updates;
- typed errors;
- `pure`;
- `bind`;
- `do` notation;
- recovery/alternative behavior used by parser/elaborator code;
- transactional rollback for speculative operations where specified.

Speculative parser/elaborator trials must not leak failed state changes.

## 9. Host exception translation

When a recoverable host API signals failure with an exception/rejection, the
adapter should catch it and translate it into the declared PSC1 error/effect
channel.

An unrecoverable abort may be modeled separately, but it must be explicit.

Backend-native exception semantics are not implicitly PSC1 semantics.

## 10. Recursion

Structural recursion is the preferred verified/executable recursive mechanism.

The first language profile also permits a controlled executable `partial def`
boundary where required for the compiler.

The partial boundary is executable capability, not logical proof authority.
It may not bypass pskernel or make nontermination into a theorem.

## 11. Proof erasure

Proof and irrelevant content may be erased where the checked semantics permits.

Erasure is a compiler-correctness boundary, not a kernel-acceptance boundary.
A proof being kernel-valid does not automatically prove the emitted program is
a correct compilation of that proof-bearing source.

The erasure layer must preserve all runtime-relevant dependent information that
affects executable behavior.

## 12. VerifiedIR contract

`VerifiedIR` is the one shared post-erasure semantic IR.

Allowed concepts include:

- PSC semantic primitive types;
- runtime functions/lambdas/calls;
- lexical bindings;
- structures/inductives;
- constructors;
- projections;
- match/control semantics;
- semantic intrinsics;
- target-neutral capability identities;
- proven target-neutral optimization facts.

Forbidden concepts include target representation such as:

```text
JavaScript:
  number, bigint, JS object layout, npm/Node resolution

Rust:
  u32 as semantic type, Vec as PSC Array definition,
  ownership, borrowing, lifetimes, traits, Cargo ABI

Wasm:
  i32/i64/f32/f64 as PSC source meaning,
  opcodes, memories, tables, GC heap types,
  WIT/WASI, sections, binary layout
```

Backend-specific IRs are expected after this boundary.

## 13. TypeScript/JavaScript lowering

Initial target mapping may use target-native representations only when they
preserve PSC1 semantics.

The compiler emits TypeScript, then the pinned repository TypeScript compiler
produces JavaScript, declarations, and source maps.

There is no separate semantic direct-JavaScript emitter.

Any TypeScript runtime helper used to preserve exact `Nat`/`Int`, integer
width, string/ADT, or other semantics is part of the untrusted executable
runtime, not the proof checker.

## 14. Rust lowering

Planned direct mappings where semantically faithful:

```text
UInt8  -> u8
UInt16 -> u16
UInt32 -> u32
UInt64 -> u64

Int8   -> i8
Int16  -> i16
Int32  -> i32
Int64  -> i64

USize  -> usize   for selected native target
ISize  -> isize   for selected native target

Float32 -> f32    when contract-compatible
Float   -> f64    when contract-compatible
Bool    -> bool
Unit    -> ()
```

`Nat` and `Int` still need exact representations unless a proven
specialization narrows them.

Rust overflow behavior, ownership, layout, and `unsafe` are not inherited by
PSC1.

## 15. WebAssembly lowering

Representative target mapping:

```text
UInt8/Int8     -> i32 execution, packed 8-bit storage where useful
UInt16/Int16   -> i32 execution, packed 16-bit storage where useful
UInt32/Int32   -> i32
UInt64/Int64   -> i64
USize/ISize    -> i32 on wasm32, i64 on wasm64
Float32        -> f32
Float          -> f64
```

These are Wasm target-lowering facts, not PSC1 source-type definitions.

`Nat`, `Int`, strings, ADTs, closures, and generic reference values need
runtime/GC/linear-memory representations that preserve their PSC1 semantics.

Wasm GC and linear memory may be combined. The representation decision belongs
below VerifiedIR.

## 16. Backend-polymorphic libraries

A library is portable when its checked semantics and capabilities do not depend
on a target-specific host assumption.

```text
portable library.ps
  -> CheckedCore
  -> Erasure
  -> VerifiedIR
      -> TS
      -> Rust
      -> Wasm
```

The same library may still choose different representations or optimizations on
different backends.

Portable means semantic portability, not byte-identical target artifacts.

## 17. Target-specific capabilities

A capability may restrict targets.

Examples:

- npm named ESM import: naturally JS-oriented unless mapped elsewhere;
- native system library: Rust/native-oriented;
- WASI capability: Wasm-oriented.

Such restrictions belong in package/capability metadata. They must not mutate
the shared type theory or VerifiedIR semantics.

## 18. Current FFI safety boundary

The current named-ESM source extension creates a checked logical signature plus
runtime binding metadata.

The host function is a trusted runtime assumption.

For the first profile:

- external signatures are bounded and first-order;
- proof-valued/polymorphic external signatures are rejected;
- exact package-root/version policy is checked;
- public package subpaths may be bounded by the root policy;
- runtime resolution is delegated to the host toolchain;
- host results are not accepted as theorem proofs.

This is a capability boundary, not a foreign proof oracle.

## 19. Canonical JSON and pskernel bridge

Self-hosting uses a versioned bridge between compiler code and pskernel.

JSON is a transport encoding, not a new semantic model.

The bridge must:

- have a versioned request/response format;
- reject malformed/unknown values;
- preserve semantic distinctions needed by checked operations;
- avoid treating decoded data as proof evidence before pskernel validates it;
- use deterministic encodings for reproducibility where specified.

Runtime structured values crossing CLI/bridge boundaries should have explicit
shapes rather than implicit host object conventions.

## 20. Compiler/runtime correctness claims

Three correctness questions remain distinct:

1. **kernel/logical correctness** — is the declaration/proof accepted?
2. **compiler semantic preservation** — does erasure/lowering preserve intended
   executable meaning?
3. **runtime implementation correctness** — do target helpers/host runtimes
   implement the declared runtime contract?

Passing (1) does not prove (2) or (3).

Differential testing is useful evidence while formal compiler proofs remain
future work.

## 21. Optimization rule

An optimization may be shared before backend lowering only when its
correctness can be stated in target-neutral PSC semantics.

Backend-specific optimizations are allowed after target lowering.

Examples of illegal semantic leakage:

- changing `Nat` to JS `number` because "most values are small";
- changing a fixed-width overflow rule because Rust release mode wraps;
- using Wasm relaxed SIMD in a deterministic profile when it changes permitted
  results;
- assuming JavaScript object identity is structure equality.

## 22. Future semantic extensions

Potential post-PSC1 work identified by the repository includes:

- a small backend-neutral structured async/task model;
- deterministic resource cleanup/bracket semantics;
- broader effects/libraries;
- richer target capabilities.

These should be specified semantically before convenience syntax is chosen.

PSC1 does not need to preemptively add `async`, `await`, `defer`, `using`,
RAII, or Promise semantics merely because a target ecosystem has them.
