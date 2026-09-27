# PSC2 Next Bootstrap

Status: forward design / continuity document for the bootstrap generation **after** the current TypeScript-based PSC2 fixed point.

This document records the intended next bootstrap direction so future work does not drift back toward making TypeScript or any other host compiler part of the semantic trust story.

It is deliberately **not** a claim that the work below is already implemented or formally proved.

## 1. Purpose

The current `psc15selfhost` bootstrap closes the first practical self-host loop through:

```text
PSC1-compatible .lean compiler source
        -> canonical generated .ps
        -> VerifiedIR
        -> TypeScript
        -> tsc
        -> JavaScript compiler
```

That path is valuable for reaching the first fixed point quickly, but `tsc` remains an additional compiler transformation between ProofScript semantics and the executable JavaScript artifact.

The next bootstrap should strengthen the assurance story by making ProofScript own the executable lowering path:

```text
.ps / supported PSC-subset .lean
        |
        v
frontend + elaboration
        |
        v
Canonical Core
        |
        v
kernel admission
        |
        v
CheckedCore
        |
        v
erasure
        |
        v
VerifiedIR
      /      \
     v        v
   JsIR     WasmIR
     |        |
     v        v
    .js      .wasm
     |
     +-> .d.ts
     +-> .js.map
```

The central goal is not merely "skip TypeScript". The goal is to make the trusted compilation story a sequence of small, explicit, testable, and eventually mechanized semantic-preservation steps.

## 2. Decision summary

### D1. Finish the current fixed point first

Do **not** destabilize the current bootstrap merely to adopt direct JavaScript early.

The existing TypeScript-based fixed point remains the shortest path to freezing the first self-hosted PSC2 bootstrap generation.

After that fixed point is green and frozen, start the next-bootstrap work from a known-good compiler.

### D2. Direct JavaScript becomes the canonical self-host runtime backend

Add a dedicated `backend-js` that consumes `VerifiedIR` directly.

Long-term bootstrap path:

```text
VerifiedIR -> JsIR -> deterministic ESM .js
```

`backend-ts` remains useful, but becomes an optional compatibility, inspection, ecosystem, and differential-testing backend rather than a mandatory part of the self-host trust chain.

### D3. Preserve `VerifiedIR` as the shared semantic backend boundary

Never replace the current architecture with:

```text
Core -> JavaScript
Core -> Wasm
```

Keep:

```text
CheckedCore
   -> erasure
   -> VerifiedIR
        +-> JsIR
        +-> WasmIR
        +-> Rust/private target IR
        +-> future target IRs
```

`VerifiedIR` remains target-neutral. JavaScript, Wasm, Rust, Node, npm, ABI, object-layout, calling-convention, and runtime-representation details stay below this boundary.

### D4. WebAssembly remains a first-class independent executable backend

The Wasm backend should continue consuming the same `VerifiedIR`, lowering through its own target representation and encoder.

Direct JS and direct Wasm should be independently justified against `VerifiedIR`; they must not be defined in terms of each other.

### D5. `.d.ts` and source maps are generated side artifacts, not runtime semantics

For JavaScript package output, the desired distribution is roughly:

```text
dist/
  Module.js
  Module.d.ts
  Module.js.map
```

`.d.ts` describes the exported typed interface for TypeScript consumers.

`.js.map` describes source provenance for debugging.

Neither artifact belongs in the runtime semantic-equivalence theorem.

### D6. Prove adjacent transformations, not every pair of representations

Do not attempt a quadratic proof matrix such as:

```text
Lean = PS
Lean = JS
Lean = Wasm
PS = JS
PS = Wasm
JS = Wasm
```

Instead establish compositional preservation:

```text
supported Lean subset --\
                         -> Canonical Core
.ps --------------------/

Canonical Core
   -> CheckedCore
   -> VerifiedIR
   -> JsIR
   -> JavaScript

VerifiedIR
   -> WasmIR
   -> WebAssembly
```

Then derive useful end-to-end statements by composition.

## 3. Target assurance model

The desired claim is **semantic preservation / observational equivalence**, not literal source equality.

Conceptually:

```text
if evalPSC(program) = value
then evalVerifiedIR(erase(check(program))) ~= represent(value)
```

and:

```text
if evalVerifiedIR(ir) = value
then evalJS(compileJS(ir)) ~= represent(value)
```

and independently:

```text
if evalVerifiedIR(ir) = value
then evalWasm(compileWasm(ir)) ~= represent(value)
```

The exact relation `~=` must be defined by the semantic model. It may account for representation differences while requiring the same observable PSC behavior.

This should ultimately support a chain like:

```text
PSC semantics
    ~= CheckedCore
    ~= VerifiedIR
    ~= JavaScript execution
```

and:

```text
PSC semantics
    ~= CheckedCore
    ~= VerifiedIR
    ~= WebAssembly execution
```

Do not claim full Lean 4 equivalence merely because these chains pass for the supported PSC subset. Full Lean compatibility remains a separate claim requiring separate evidence.

## 4. Proposed next-bootstrap packages

The exact package names can evolve, but preserve the boundaries.

### `packages/backend-js`

Responsibilities:

- consume only `VerifiedIR` plus explicitly approved target-neutral metadata;
- define a small private JavaScript target IR / AST;
- lower `VerifiedIR -> JsIR`;
- emit deterministic ECMAScript modules;
- contain JavaScript-specific runtime representation choices;
- reject unsupported semantics rather than silently changing meaning.

It must not redefine PSC semantics.

### JavaScript target IR

Keep `JsIR` substantially smaller than ECMAScript.

Only represent constructs actually needed by compiled ProofScript, for example:

```text
module/import/export
constant/function declaration
function/lambda
call
let/const
if
switch/tag dispatch
object/array construction where justified
property access
primitive operators selected by explicit PSC lowering
BigInt operations where selected by the runtime representation
```

Avoid exposing arbitrary JavaScript syntax merely because it exists.

The smaller the emitted JavaScript subset, the smaller the semantic model and proof burden.

### Interface declaration emitter

Generate `.d.ts` from exported PSC interface information or a future target-neutral `InterfaceIR`.

Do not derive `.d.ts` by parsing emitted JavaScript.

Desired conceptual path:

```text
checked exported PSC types
        -> interface model
        -> .d.ts
```

### Source-map emitter

Carry source/provenance information through compilation sufficiently to map generated JavaScript locations back to `.ps` source.

Desired conceptual path:

```text
.ps span
  -> frontend/core provenance
  -> VerifiedIR provenance
  -> JsIR provenance
  -> generated JS span
  -> .js.map
```

Source maps are debugging evidence, not proof evidence.

### Existing `packages/backend-wasm`

Keep its independent structure:

```text
VerifiedIR -> Wasm target model -> binary encoder -> .wasm
```

Do not route Wasm through JavaScript or TypeScript.

## 5. Runtime semantic decisions that must be explicit

A direct JS backend only strengthens the proof story if the representation policy is specified rather than inherited accidentally from JavaScript.

The following require deliberate contracts before strong equivalence claims:

### `Nat` and `Int`

PSC/Lean `Nat` and `Int` are mathematically unbounded.

Do not silently compile them to JavaScript `Number`.

Candidate representations may include JavaScript `BigInt` or a ProofScript runtime representation. Whichever is selected must preserve the defined PSC semantics.

### Machine integers

For:

```text
UInt8 UInt16 UInt32 UInt64 USize
Int8 Int16 Int32 Int64 ISize
```

wrapping, range, signedness, comparison, and platform-width rules must come from PSC semantics, not JavaScript behavior.

The backend must use the machine-integer type retained by `VerifiedIR`.

### `Float` and `Float32`

Define the relationship to IEEE-754 behavior precisely.

`Float32` must not accidentally acquire unrestricted f64 intermediate semantics where PSC requires f32 rounding/behavior.

### `Char`

Specify Unicode scalar-value semantics explicitly.

Do not equate PSC `Char` with an arbitrary JavaScript UTF-16 code unit.

### `String`

Specify the PSC string model and operations first, then implement them in JS.

Do not define PSC string semantics as "whatever JavaScript String does" unless that equivalence has actually been established for the required operations.

### Structures and inductives

Define deterministic tagged/object representations after semantics are fixed.

Representation is backend-private and must not leak into `VerifiedIR`.

### Equality

Never inherit JavaScript coercive equality.

Each PSC equality operation must map to an implementation justified by its PSC semantics.

### Arrays

Specify value/mutation behavior at the PSC semantic layer. JavaScript `Array` is only an implementation choice.

## 6. Bootstrap evolution

### Generation A — current bootstrap

Close and freeze:

```text
PSC compiler source
  -> VerifiedIR
  -> TypeScript
  -> tsc
  -> compiler.js
```

Required current evidence remains the existing source/compiler fixed-point gates.

### Generation B — direct-JS differential bootstrap

Introduce:

```text
VerifiedIR -> JsIR -> .js
```

while keeping the old path available:

```text
VerifiedIR -> TypeScript -> tsc -> .js
```

Use both for differential testing over the supported compiler and library corpus.

Do not switch bootstrap authority until direct JS has sufficient conformance evidence.

### Generation C — direct-JS fixed point

Switch the bootstrap compiler generation to:

```text
compiler.ps
   -> PSC compiler
   -> VerifiedIR
   -> backend-js
   -> compiler.js (generation N)

compiler.js (generation N)
   -> compiler.ps
   -> compiler.js (generation N+1)
```

Required fixed-point evidence should include deterministic executable parity according to the chosen normalization policy.

The ideal case is byte-for-byte deterministic `.js`; if metadata prevents this, define and freeze an explicit canonical normalization rather than weakening the comparison informally.

### Generation D — kernel-backed direct-JS bootstrap

Once `pskernel-core` is ready and explicitly integrated:

```text
source
 -> elaboration
 -> AdmissionReadyModule
 -> pskernel-core
 -> CheckedCore
 -> erasure
 -> VerifiedIR
 -> JsIR
 -> .js
```

At this point erasure must accept the genuine checked artifact rather than codec validation renamed as checking.

### Generation E — dual high-assurance executable backends

Establish supported semantic-preservation evidence independently for:

```text
VerifiedIR -> JS
VerifiedIR -> Wasm
```

and use shared conformance programs to demonstrate cross-backend observational agreement.

## 7. Proof and assurance layers

Use multiple evidence layers. Do not pretend tests alone are formal proof, and do not require expensive formalization before inexpensive regressions are available.

### Layer 1 — structural contracts

Examples:

- target-neutrality guard for `VerifiedIR`;
- bootstrap closure guard;
- backend dependency guards;
- no `tsc` dependency in direct-JS bootstrap closure;
- no JS/Wasm representation leakage into Core/VerifiedIR.

### Layer 2 — deterministic golden tests

For each VerifiedIR construct, maintain small expected JS and Wasm outputs where stable output is useful.

### Layer 3 — differential execution

For a shared corpus:

```text
PSC reference / current backend result
backend-ts -> tsc -> JS result
backend-js -> JS result
backend-wasm -> Wasm result
```

compare observable PSC values and errors according to the defined semantics.

### Layer 4 — adversarial semantic regressions

Prioritize edge cases:

- Nat/Int boundaries and large values;
- signed/unsigned machine integer overflow;
- 64-bit integer behavior;
- Float32 rounding;
- Unicode/Char/String behavior;
- nested inductives and matches;
- closures/captured values;
- recursion;
- arrays;
- malformed or unsupported backend inputs.

Backends must fail closed on unsupported cases.

### Layer 5 — mechanized semantic-preservation proofs

Preferred theorem granularity:

```text
CheckedCore -> erasure -> VerifiedIR
VerifiedIR -> JsIR
JsIR -> emitted JS subset
VerifiedIR -> WasmIR
WasmIR -> encoded Wasm
```

Use the cheapest sound proof decomposition that composes into the desired end-to-end claim.

Formalization should target the **restricted generated JS subset**, not all of ECMAScript.

## 8. Relationship between `.lean` and `.ps`

During bootstrap, `.lean` remains an implementation/bootstrap representation for the supported PSC1-compatible subset.

Long term, the stronger statement is not source-text equality but frontend semantic agreement:

```text
elaborateSupportedLean(source)
        ~=
elaboratePS(translate(source))
```

with both producing the same canonical semantic Core up to the explicitly allowed equivalence relation, such as alpha-renaming or canonical normalization.

Once canonical `.ps` has passed the required source, semantic, and self-host parity gates, it becomes the authoritative self-host source according to the bootstrap policy.

## 9. What this next bootstrap should be able to build

The direct-JS compiler must remain a general compiler, not a special self-reproducer.

Within its accepted source profile it should compile:

- its own portable compiler sources;
- portable stdlib modules;
- pure ProofScript libraries;
- algorithms and data structures;
- proof-oriented libraries after kernel/proof support is available;
- compiler semantic libraries;
- backend implementations that are expressible within the accepted profile;
- ordinary applications that only require supported portable/runtime capabilities.

Later extension APIs can add syntax, deriving, tactics, contracts, FFI, Node/browser bindings, and other ecosystem functionality without enlarging the trusted kernel.

## 10. Explicit exclusions from the next-bootstrap trusted closure

Do not make the next fixed point depend on unrelated ecosystem work.

Unless genuinely required by the compiler generation, keep these outside the trusted bootstrap closure:

- React or browser frameworks;
- Node-specific application APIs;
- database drivers;
- large package ecosystems;
- LSP/editor implementation;
- arbitrary external compiler plugins;
- Rust backend;
- project tooling beyond what bootstrap actually requires;
- full mathlib compatibility;
- full Lean 4 syntax compatibility;
- claims of complete Lean 4 semantic equivalence.

Rust/Wasm/project/LSP/etc. can continue to be developed and regression-tested without becoming bootstrap prerequisites.

## 11. Recommended implementation order

Do not start this sequence until the current TypeScript-based fixed point is frozen unless a current blocker proves the existing route is untenable.

Recommended order:

1. Freeze the current PSC2 bootstrap fixed point.
2. Freeze the relevant `VerifiedIR` semantic contract for the direct-JS slice.
3. Add `backend-js` package boundary.
4. Define the minimal `JsIR` needed by the current compiler corpus.
5. Implement deterministic JS emission for the smallest VerifiedIR slice.
6. Add RED differential fixtures against `backend-ts -> tsc`.
7. Grow direct JS construct-by-construct until the compiler corpus is covered.
8. Add explicit runtime representation contracts for Nat/Int/machine ints/Float/Float32/Char/String/arrays/ADTs.
9. Add `.d.ts` generation from checked interface information.
10. Add provenance propagation and `.js.map` generation.
11. Run the compiler through the direct-JS path without making it authoritative yet.
12. Close direct-JS source/runtime/compiler differential gates.
13. Switch the bootstrap fixed point from TS+`tsc` to direct JS.
14. Keep TS as an optional backend and differential oracle.
15. Finish/integrate the small kernel and move erasure behind genuine `CheckedCore`.
16. Strengthen the existing Wasm path against the same VerifiedIR semantic corpus.
17. Mechanize semantic-preservation proofs in adjacent layers.
18. Freeze the first kernel-backed direct-JS/Wasm assurance baseline.

## 12. Acceptance gates for the direct-JS bootstrap

Exact command names should be added only when implementation begins, but the semantic gates should cover at least:

```text
check:verified-ir-neutrality
check:backend-js-dependencies
check:bootstrap-direct-js-closure

test:backend-js-unit
test:backend-js-differential
test:backend-js-runtime-edge-cases

test:dts-interface
test:source-map-provenance

selfhost:js-generation
verify:selfhost-js-source
verify:selfhost-js-compiler
fixed-point:js
```

When Wasm assurance is included:

```text
test:backend-wasm-semantic-corpus
test:js-wasm-observational-parity
```

When kernel-backed admission is included:

```text
check:kernel-provider-boundary
test:checked-core-admission
fixed-point:kernel-js
```

Never mark a gate green by weakening the semantic contract merely to accommodate a backend mismatch.

## 13. Anti-drift rules

Future agents/chats should preserve these rules unless an explicit design decision supersedes them:

1. The current TS fixed point closes before replacing its bootstrap path.
2. `VerifiedIR` remains target-neutral and shared.
3. Direct JS gets a private target IR; JavaScript details do not enter `VerifiedIR`.
4. Wasm remains an independent direct `VerifiedIR` consumer.
5. `.d.ts` and `.js.map` are side artifacts, not runtime semantic authorities.
6. `tsc` should eventually leave the canonical trusted self-host path, but `backend-ts` may remain useful indefinitely.
7. Proof obligations are compositional and adjacent, not all-pairs.
8. Generated JavaScript should use the smallest practical ECMAScript subset.
9. JavaScript runtime behavior never silently defines PSC semantics.
10. Unsupported semantics fail closed.
11. Kernel admission and compiler lowering remain separate boundaries.
12. Do not call `AdmissionReadyModule` `CheckedCore` without a real kernel provider.
13. Do not claim full Lean 4 equivalence unless separately demonstrated.
14. Keep capabilities moving upward: library > elaboration/plugin > Core/kernel whenever possible.
15. Keep the kernel and bootstrap closure small even as the ecosystem grows.

## 14. Success definition

The next-bootstrap milestone is complete when a supported canonical PSC2 compiler source can reproduce its executable compiler without Lean or TypeScript being required in subsequent generations:

```text
compiler.ps
   |
   | PSC2 compiler generation N
   v
CheckedCore
   v
VerifiedIR
   v
JsIR
   v
compiler.js generation N+1
   |
   | compile the same canonical compiler.ps
   v
compiler.js generation N+2
```

and the required source/runtime/compiler fixed-point gates pass under the frozen semantic contracts.

The stronger kernel-backed milestone additionally requires:

```text
AdmissionReadyModule
   -> real pskernel-core admission
   -> CheckedCore
   -> erasure
```

The stronger multi-backend assurance milestone additionally requires independently justified JS and Wasm lowering from the same `VerifiedIR` and cross-backend observational agreement over the supported semantic corpus.

## 15. Immediate instruction to future work

If this document is opened before the current TypeScript-based fixed point is green:

**finish that fixed point first.**

Do not rewrite the compiler around direct JS prematurely.

If the current fixed point is already frozen, begin with the smallest `backend-js` RED differential slice while preserving all existing bootstrap, kernel, IR-neutrality, Rust, and Wasm gates.
