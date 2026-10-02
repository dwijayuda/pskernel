# PSC3 Backends, Runtime Semantics and Preservation

Status: **backend architecture draft**

PSC3 favors two strategic owned targets:

~~~text
direct JavaScript
direct WebAssembly
~~~

The goal is not ownership for its own sake.

The goal is a small number of explicit target semantics with a credible compiler-preservation path.

## 1. Pipeline

~~~text
.ps / supported .lean / .psx
              |
              v
          CheckedCore
              |
              v
        verified/validated erasure
              |
              v
           RuntimeIR
           /      \
          v        v
        JsIR     WasmIR
          |        |
          v        v
       ESM JS   Wasm module/component
       + .d.ts  + WIT where applicable
~~~

The exact internal IR names are implementation choices.

The semantic roles are not.

## 2. Primary target: direct JavaScript

Direct JS is the default application distribution backend.

Reasons:
- JavaScript ecosystem reach;
- browser/server/runtime portability;
- no TypeScript compiler needed merely to execute PSC output;
- easy npm integration;
- readable debugging output;
- smaller backend-preservation chain.

Generated .d.ts provides TypeScript consumer ergonomics.

## 3. JavaScript target profile

The certified JS subset should begin deliberately small:
- ESM imports/exports;
- functions/closures;
- lexical let/const;
- structured if/switch/loops;
- arrays/objects as representations only;
- BigInt for exact integer runtime where appropriate;
- explicit runtime helper calls;
- async only after Task mapping is specified.

Avoid emitted use of:
- eval/new Function;
- prototype mutation;
- implicit truthiness where PSC semantics differs;
- target coercions as semantic shortcuts;
- observable property-order assumptions unless modeled;
- ambient globals outside declared capability adapters.

## 4. .d.ts generation

The backend emits TypeScript declarations describing the runtime API.

The .d.ts:
- omits erased proof parameters;
- represents validated runtime input domains honestly;
- uses nominal/branded or wrapper strategies where ordinary TypeScript would otherwise over-accept;
- cannot itself enforce runtime invariants.

For untrusted JS/TS callers, generate runtime-safe boundary functions where required.

## 5. Second target: direct WebAssembly

Direct Wasm is the portable/high-assurance secondary target.

Initial certified subset should focus on:
- pure computation;
- explicit data representation;
- deterministic arithmetic;
- functions/calls;
- algebraic data;
- bounded memory/runtime model.

Then expand toward:
- Component Model interfaces;
- WIT generation;
- WASI capabilities;
- async/component capabilities as stable target semantics permit.

## 6. Component Model

PSC package interfaces map naturally to typed component interfaces where representable.

WIT is a target interface format, not PSC source semantics.

Generated component adapters must preserve:
- Option/Result;
- variants;
- records;
- resources;
- strings/bytes;
- async/future/stream behavior for the selected WASI/component profile.

## 7. Runtime representation

RuntimeIR expresses PSC runtime meaning independent of target representation.

Examples:

~~~text
PSC Nat
  -> JS BigInt/runtime exact Nat
  -> Wasm big-integer runtime/representation

PSC structure
  -> JS object/array/tag representation
  -> Wasm GC/linear-memory representation
~~~

Representation relations are part of backend correctness.

## 8. Exact integers

Nat and Int remain exact.

Backend operations must implement:
- nonnegative Nat;
- mathematical Int;
- Lean/PSC-compatible subtraction/division semantics;
- exact conversions.

Fixed-width optimization requires range evidence or a checked condition preserving behavior.

## 9. Fixed-width scalars

UInt*/Int* mappings may use native target integers where the PSC operation contract matches.

Where target behavior differs:
- insert explicit operations;
- use runtime helpers;
- prove/validate the mapping.

Backend optimization flags must not silently redefine overflow or floating behavior.

## 10. Strings and characters

JS strings, Wasm strings/memory encodings and PSC String are not assumed identical.

PSC3 must freeze:
- character abstraction;
- string length/index meaning;
- UTF behavior;
- byte/text conversions.

Backend runtime proves/tests the representation mapping.

## 11. Collections and ADTs

Array/List/Map/Set are semantic library types.

Target representations are replaceable.

Equality/order/iteration behavior comes from PSC declarations/contracts, not JS object identity or Wasm addresses.

## 12. Closures

Closure conversion is a compiler-preservation boundary.

The target representation may store code pointer + environment, JS function object, Wasm closure record, or another scheme.

The proof/validation relates observable invocation behavior, not identity/layout.

## 13. Effects

RuntimeIR contains target-neutral capability/effect operations.

Target adapters map them to:
- browser APIs;
- Node/Bun/Deno APIs;
- Wasm Component/WASI capabilities.

A target that lacks a required capability rejects the build or requires an explicit foreign adapter.

## 14. Compiler correctness layers

PSC3 separates:

### A. Logical correctness

The source theorem/program contract was kernel checked.

### B. Erasure correctness

Removing proof/spec-only content preserves relevant runtime behavior.

### C. RuntimeIR lowering

CheckedCore executable meaning is preserved by RuntimeIR.

### D. Target lowering

RuntimeIR is related to JsIR/WasmIR.

### E. Serialization

The exact emitted JS/Wasm bytes denote the target program that was proved/validated.

### F. Runtime/environment assumptions

JS engine, Wasm engine, host APIs and external libraries satisfy the declared model/assumptions.

No layer is skipped merely because the compiler is self-hosted.

## 15. Proof-producing / translation-validating compilation

PSC3 should use a hybrid strategy.

### Prove regular passes once

For simple transformations with stable definitions, prove a preservation theorem for all accepted inputs.

### Validate complex output per compilation

For complex/rapidly changing optimizations, produce a certificate and check:

~~~text
validate(sourceIR, targetIR, certificate) = accepted
    =>
target preserves source behavior
~~~

The validator must itself have a soundness argument.

This can make backend bugs produce rejected builds rather than silently miscompiled artifacts.

## 16. Exact artifact binding

Preservation evidence must identify the exact emitted artifact and relevant runtime.

A proof about an internal AST does not cover a printer bug.

Strategies:
- verified/certified printer;
- independent checked parser of canonical output;
- both.

Any post-processing that changes executable bytes may require revalidation.

## 17. Direct JS versus TypeScript emission

PSC3 prefers direct JS for the primary path.

A TypeScript source emitter can remain useful for:
- debugging;
- migration;
- human inspection;
- specialized ecosystem integration.

But .ts is not required between PSC semantics and JS execution.

This simplifies the normal preservation chain.

## 18. Direct Wasm versus Rust-to-Wasm

PSC3 prefers direct Wasm as the strategic Wasm path.

A Rust emitter/toolchain may remain an optional ecosystem/backend extension.

Direct Wasm avoids making Rust/LLVM semantics a mandatory part of PSC's own Wasm-preservation target.

This does not make direct Wasm automatically correct; PSC must prove/validate its own lowering and runtime.

## 19. Differential testing

Before formal preservation is complete, require differential tests:

~~~text
source evaluator / semantic reference
        |
        +---- direct JS
        |
        +---- direct Wasm
~~~

Compare specified observables across:
- normal cases;
- boundaries;
- random/property cases;
- deliberately mutated backends.

Differential agreement is evidence, not proof.

## 20. Wasm runtime choices

PSC3 must explicitly choose/profile:
- Wasm GC versus linear memory;
- allocator;
- exact integer representation;
- strings;
- closure representation;
- exceptions/results;
- host interface;
- component/core module packaging.

Different target profiles may coexist if their semantic contracts are explicit.

## 21. Resource behavior

Logical termination does not imply finite-memory success.

Backends may have:
- allocation failure;
- stack exhaustion;
- fuel/resource limits;
- host cancellation.

The assurance profile specifies whether these are:
- ruled out by proved bounds;
- allowed target outcomes;
- external assumptions.

## 22. Unsafe target operations

Any unsafe/raw host operation lives behind a narrow runtime/FFI interface.

It cannot gain proof authority merely because the backend needs it.

Runtime packages must report trusted/verified status.

## 23. Self-hosting

A future PSC3 compiler may compile itself through the JS backend.

Self-host fixed point is evidence of bootstrap stability.

It does not prove:
- backend correctness;
- kernel soundness;
- preservation;
- absence of seed compromise.

Those remain separate assurance questions.

## 24. Backend release levels

Suggested labels:

~~~text
experimental
conformance-tested
differential-tested
translation-validated
preservation-proved(fragment/profile)
production
~~~

Production is an engineering maturity label, not automatically a theorem.

## 25. Initial implementation priority

1. direct JS for the existing executable subset;
2. source maps and .d.ts;
3. RuntimeIR semantic tests;
4. JS differential suite;
5. direct Wasm pure subset;
6. erasure/lowering preservation models;
7. proof-producing/validated target lowering;
8. Component/WASI profile;
9. async/effect target mapping after Task semantics freezes.

Do not let a second backend delay a trustworthy first full-app JS experience.
