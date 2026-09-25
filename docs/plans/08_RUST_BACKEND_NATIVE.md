# ProofScript Rust backend and native self-host plan

Branch: `backend/rust-native`

Status: **parallel, non-blocking backend lane**

This branch is intentionally allowed to develop while
`selfhost/psc1-lean-bootstrap` continues closing the first JavaScript
self-host. Rust work must not redirect or delay that branch.

## Contract with the self-host branch

The authoritative source-language and compiler semantics remain owned by the
PSC1/self-host plan. This branch must adapt to those contracts rather than fork
them.

Required shared path:

```text
.ps / supported .lean
-> canonical AST
-> Lean-compatible Meta/Elab
-> pskernel admission
-> CheckedCore
-> erasure
-> CompilerIR
-> backend-rust
-> Rust AST/source
-> rustc/Cargo
-> native artifact
```

Do not introduce a second parser, elaborator, checker, erasure model, or target
specific semantic IR merely to make Rust easier.

If the shared compiler IR changes on the self-host branch, rebase/adapt this
branch. Rust-specific convenience is not a reason to change PSC1 semantics.

## PSC1 scalar mapping

The planned frozen PSC1 scalar family is:

```text
Nat Int
UInt8 UInt16 UInt32 UInt64 USize
Int8 Int16 Int32 Int64 ISize
Float Float32
Bool Char String Unit
```

Initial Rust mappings:

```text
UInt8   -> u8
UInt16  -> u16
UInt32  -> u32
UInt64  -> u64
USize   -> usize

Int8    -> i8
Int16   -> i16
Int32   -> i32
Int64   -> i64
ISize   -> isize

Float   -> f64
Float32 -> f32
Bool    -> bool
Unit    -> ()
```

`Nat` and `Int` retain exact mathematical semantics. Do not map them
unconditionally to `usize`/`u64` or `isize`/`i64`. A machine integer
representation is allowed only when the compiler has proved the relevant range
or when an exact runtime representation preserves semantics.

## Rust-language boundary

Rust is an output language, not a source-language design template.

Do not add these to PSC1 solely for this backend:

- references or `&mut`;
- explicit lifetimes;
- Rust traits/impl syntax;
- `Box`, `Rc`, `Arc`, `Pin`;
- Rust macros;
- Cargo-specific source syntax;
- unrestricted `unsafe`.

The backend may synthesize ownership, borrowing, lifetimes, moves,
monomorphization, and runtime representation choices internally.

Generated ordinary application/compiler code should prefer safe Rust and, where
practical, compile under:

```rust
#![forbid(unsafe_code)]
```

Any required unsafe runtime/FFI code belongs behind a small explicit audited
boundary.

## Initial package shape

Target package:

```text
packages/backend-rust/
  src/
    Ps/
      BackendRust/
        Type.ps
        Expr.ps
        Module.ps
        Runtime.ps
```

During the current Lean-first bootstrap era, the Rust backend implementation
must be authored in **portable Lean constrained to the frozen/planned PSC1
subset**, following the same source-profile discipline as the self-host
compiler. Do not use TypeScript as the semantic backend implementation and do
not rely on Lean-only conveniences merely because official Lean accepts them.
Host-only Rust toolchain/process adapters may remain outside the portable
backend.

The intended transition is therefore:

```text
BackendRust/*.lean   # handwritten now, PSC1-constrained
        |
        | canonical compiler translation after SH10
        v
BackendRust/*.ps     # authoritative portable source
```

Do not hand-maintain parallel `.ps` files before that transition.

Prefer a typed Rust AST followed by deterministic pretty-printing over direct
string concatenation for nontrivial emission.

## Current implementation checkpoint

As of the current branch checkpoint:

- the backend is authored in PSC1-constrained Lean;
- shared CompilerIR lowering produces deterministic safe Rust;
- exact `Nat`/`Int`, `Bool`, `Char`, `String`, structures,
  inductives, match, generic functions, top-level values, and persistent
  `Array` paths compile and execute under Rust CI;
- the frozen PSC1 scalar type family is synchronized from
  `selfhost/psc1-lean-bootstrap` into the shared IR and maps directly to
  Rust machine scalar types;
- compiler API support exposes source-neutral `.lean`/`.ps` -> Rust
  generation over the same elaboration/erasure/CompilerIR path;
- target-neutral fixed-width integer and floating-point CompilerIR operations
  are consumed directly: fixed-width integer add/sub/mul use Rust wrapping
  operations, comparisons preserve the shared IR relation, `Float32` remains
  `f32`, and `Float` remains `f64`;
- the TS <-> Rust differential gate compares both backends against explicit
  expected output for UInt8 wraparound, Int16 overflow, UInt32 comparison,
  Float32 arithmetic, Float arithmetic, captured closures used as local or
  higher-order argument values, arrays, ADTs, and structure-qualified
  projection;
- generic zero-parameter declarations are rejected consistently with backend-ts
  rather than being silently reinterpreted as generic Rust functions;
- function-valued declaration results are currently fail-closed because a Rust
  `fn(...)` pointer cannot represent a capturing returned closure. Supporting
  returned/stored capturing closures requires an explicit ownership/runtime
  representation and is not approximated by the backend;
- the reusable R3 compiler-IR coverage census is wired into CI and is
  fail-closed: it reports an explicit unsupported set and the real-compiler
  gate requires `PSC1_RUST_COVERAGE_UNSUPPORTED_COUNT: 0` before Rust
  emission;
- unsupported external imports, unknown runtime types, and traversal fuel
  exhaustion are census blockers rather than informational-only features;
- the decisive real compiler -> Rust -> Cargo check remains gated by PSC1
  self-host source closure rather than by a known Rust semantic fork.

## Development milestones

### R0 — contract and fixtures

- freeze the compiler-IR subset consumed by the first backend slice;
- add differential fixtures shared with backend-ts;
- pin a Rust toolchain for CI;
- define normalized Rust-source comparison.

### R1 — scalar/function subset

Emit and execute:

- scalar literals and primitive operations;
- local bindings;
- ordinary functions/calls;
- conditionals;
- basic single-scrutinee match;
- structures and simple inductives.

Gate against backend-ts behavior for the same checked/compiler IR.

### R2 — runtime data

Add:

- String;
- Array;
- Option;
- Result/Except;
- List or its erased runtime representation;
- closures;
- recursion;
- exact Nat/Int runtime representation.

### R3 — complete compiler IR coverage

Every runtime construct required to compile the ProofScript compiler must lower
through backend-rust. Unsupported constructs must fail explicitly rather than
silently using different semantics.

The census currently treats external imports, unknown runtime types, traversal
fuel exhaustion, generic top-level values, and function-valued declaration
results as explicit blockers. If the real compiler census reaches one of these,
the next step is either a target-neutral/shared semantic change or a deliberate
Rust representation that preserves the existing CompilerIR meaning—not a
backend-specific semantic shortcut.

### R4 — native compiler bootstrap

After the JavaScript self-host fixed point and `.ps` source transition are
stable:

```text
compiler.ps --psc.js--> compiler.rs --rustc--> psc-native-1
compiler.ps --psc-native-1--> compiler.rs --rustc--> psc-native-2
```

### R5 — cross-host fixed point

Require:

```text
psc.js     -> compiler.ps -> TS   -> psc.js
psc.js     -> compiler.ps -> Rust -> psc-native
psc-native -> compiler.ps -> TS   -> psc.js
psc-native -> compiler.ps -> Rust -> psc-native
```

Compare normalized checked-core and CompilerIR fingerprints. Compare normalized
target source when appropriate. Do not require native executable byte identity.

## Merge/integration rule

Work may be implemented and tested on this branch now. It is deliberately
non-blocking for the active PSC1 source-closure campaign.

Integrate into the authoritative self-host line only when:

1. the shared compiler-IR contract used by the backend is current;
2. no Rust-specific semantic fork is introduced;
3. existing SH1-SH10 gates remain at least as strong;
4. the backend has regression/differential tests for its claimed subset.

The target integration milestone is SH10R in
`docs/plans/07_SELF_HOSTING_FOUNDATION.md`.
