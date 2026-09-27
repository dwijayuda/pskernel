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

## 16. Compiler-verification north star

The strongest feasible PSC2 assurance target is not merely "the language is kernel checked" and not merely "the compiler is self-hosted".

The long-term target is:

> A small independent kernel validates the semantic input to compilation; every mandatory semantics-changing compiler transformation is justified by a machine-checked preservation theorem or a small verified validator; the compiler implementation itself refines a formal compiler specification; the self-hosted executable is produced through that verified pipeline; reproducible fixed-point and diverse-bootstrap evidence bind the executable back to the visible compiler source.

This is an architectural north star. It is **not** a claim that PSC2 currently has these proofs.

The preferred high-level architecture is:

```text
                         FORMAL SPECIFICATION
                 +-----------------------------+
                 | PSC Core semantics          |
                 | typing/admission rules      |
                 | erasure semantics           |
                 | VerifiedIR semantics        |
                 | runtime primitive semantics |
                 +--------------+--------------+
                                |
                                | machine-checked theorems
                                v
source              SMART BUT UNTRUSTED FRONTEND
.ps -------------> parser / resolver / Meta / elaborator
.lean subset ----> translation / frontend / plugins / tactics
                                |
                                v
                         candidate Core
                                |
                                v
                      +-------------------+
                      | tiny pskernel-core|
                      | trusted admission |
                      +---------+---------+
                                |
                           CheckedCore
                                |
                        proved erasure
                                |
                                v
                           VerifiedIR
                  +-------------+-------------+
                  |                           |
                  v                           v
                JsIR                        WasmIR
                  |                           |
              proved lowering            proved lowering
                  |                           |
                  v                           v
                 .js                         .wasm
```

Compiler convenience must never be allowed to weaken this layering.

## 17. Distinguish four different correctness claims

Do not collapse all assurance into one word such as "verified". PSC2 should keep at least these four claims separate:

### A. Logical/kernel soundness

Claim:

```text
if pskernel-core admits a declaration/module,
then it satisfies the formal PSC Core typing/admission rules
within the stated kernel model and assumptions.
```

This protects theorem/proof soundness.

### B. Frontend correctness

Claim:

```text
source text -> parser/resolver/elaborator -> CheckedCore
```

preserves the defined source-language meaning.

This is stronger than kernel soundness. A sound kernel can reject invalid Core, but it does not by itself prove that a buggy parser interpreted the user's source text as intended.

Frontend correctness can be staged later because it is not required to keep false proofs out of the kernel. For early milestones, kernel rechecking is the critical soundness boundary.

### C. Compiler semantic preservation

Claim:

```text
CheckedCore -> executable artifact
```

preserves the observable runtime semantics of the checked program.

This is the central compiler-correctness theorem family.

### D. Bootstrap/source provenance

Claim:

```text
visible compiler source -> distributed compiler executable
```

is the build relationship actually represented by the repository and release artifacts.

Self-host fixed point, reproducibility, and diverse bootstrap/DDC-style evidence belong here. They do not replace semantic-preservation proofs.

## 18. Keep the frontend outside the trusted computing base where possible

Parser, resolver, type inference, elaborator, tactics, macros, `simp`, deriving, optimization heuristics, and external plugins may become large.

They should not gain theorem-admission authority merely because they are useful.

Preferred boundary:

```text
source
  -> possibly buggy smart frontend
  -> candidate Core
  -> pskernel-core
  -> CheckedCore
```

If elaboration produces an invalid term, the kernel rejects it.

No path may allow:

```text
candidate Core -------> erasure
plugin output --------> VerifiedIR
elaborated declarations -> executable backend
```

without passing through the required checked boundary.

The API should make the valid route explicit:

```text
CandidateCore
   -> kernel admission
   -> CheckedCore
   -> compiler pipeline
```

For the strongest source-level theorem, frontend correctness can later be proved separately. It is not necessary to put the entire frontend into the foundational TCB.

## 19. Make `CheckedCore` a real capability type

The current `AdmissionReadyModule` boundary is a useful bootstrap staging artifact but must not become the permanent trusted boundary by renaming.

Long-term API direction:

```text
AdmissionReadyModule
   -> pskernel-core.checkModule
   -> CheckedModule / CheckedCore
```

Only `CheckedCore` should be accepted by semantic erasure.

This should be enforced both architecturally and, where practical, by types/module visibility so ordinary compiler code cannot construct a checked artifact without kernel admission.

Desired invariant:

```text
CheckedCore means "admitted by the designated kernel provider",
not "serialized successfully",
not "frontend claims it typechecks",
and not "a Boolean flag was set".
```

## 20. Define formal semantics before proving implementation details

Compiler proofs need stable mathematical/executable semantic models.

Define, as small as practical:

```text
SemPSCSource        # later/optional source-level semantics
SemCore             # canonical dependent core
SemCheckedCore      # same semantics plus admission invariant
SemErased           # proof/type erasure semantics
SemVerifiedIR       # target-neutral runtime semantics
SemJsIR             # restricted generated JS subset
SemWasmIR           # Wasm target model used by the backend
```

Runtime primitives also need formal contracts for at least the supported operations on:

```text
Nat Int
UInt8 UInt16 UInt32 UInt64 USize
Int8 Int16 Int32 Int64 ISize
Float Float32
Bool Char String Unit
arrays
structures
inductives
```

Do not try to prove compiler implementation code against only prose descriptions.

## 21. Prove adjacent compiler transformations and compose them

The whole compiler theorem should be assembled from small preservation theorems.

Conceptually:

```text
CheckedCore
   | erasure_correct
   v
Erased/Core runtime form
   | lowering_correct
   v
VerifiedIR
   | backend_js_correct
   +---------------------> JsIR
   |
   | backend_wasm_correct
   +---------------------> WasmIR
```

For any mandatory semantics-changing pass `P`, prefer a theorem shape such as:

```text
pass_correct :
  P(input) = output
  ->
  Sem(output) ~= Sem(input)
```

or an equivalent forward-simulation/refinement theorem suited to the semantics.

Possible future passes include:

```text
erasure
specialization
closure conversion
monomorphization
simplification
representation lowering
backend lowering
```

A new mandatory pass must not be inserted into the trusted compilation path without an explicit assurance classification: proved, validated, purely representational, or temporarily evidence-only.

## 22. Prove erasure as a first-class theorem

ProofScript's dependent/proof layer makes erasure especially important.

The desired result is not merely that erasure tests pass, but eventually something like:

```text
if CheckedCore evaluates to runtime value v,
then erased/VerifiedIR evaluation produces the corresponding runtime representation of v.
```

The theorem must justify removal of runtime-irrelevant material such as supported:

```text
Prop proofs
proof terms
ghost/type-only information
erased type parameters
```

without changing observable runtime behavior.

Erasure must fail closed when the compiler cannot justify a representation.

## 23. Use verified translation validation for expensive optimizations

Do not require every sophisticated optimizer implementation itself to be fully verified.

For difficult or rapidly changing optimizations, prefer:

```text
original IR
    |
    | untrusted optimizer
    v
optimized IR
    |
    | small verified equivalence/refinement checker
    v
accepted optimized IR
```

If the validator cannot establish the required relation, reject the optimized result or use the unoptimized form.

This strategy is preferred for optimizations whose implementation complexity would otherwise dominate the formal proof burden, for example:

- aggressive inlining;
- specialization heuristics;
- common-subexpression or fusion transforms;
- target-specific peepholes;
- backend optimization passes.

The validator belongs closer to the TCB than the optimizer.

## 24. Direct JavaScript proof boundary

Do not formalize all of ECMAScript merely to justify PSC output.

Define a deliberately restricted generated language, informally `PSC-JS`, represented by `JsIR`.

Only include constructs that the backend actually emits, for example:

```text
ES module import/export
function and constant declaration
function/lambda/call
let/const
if
switch/tag dispatch
selected object/array forms
selected property access
BigInt operations
explicit primitive operations
```

Preferred proof decomposition:

```text
VerifiedIR
   -> JsIR           # semantic-preservation theorem
   -> emitted text   # emitter/serialization theorem or validated round-trip
```

For the final text boundary, one feasible strategy is to define a small parser for the emitted subset and prove/check:

```text
parse(emit(jsIR)) ~= jsIR
```

under a canonical printer contract.

This keeps the proof burden proportional to the JavaScript subset PSC actually owns.

## 25. WebAssembly should be the strongest executable assurance target

Keep JS as the primary ecosystem/backend target, but prioritize Wasm for the strongest executable semantic theorem because its target semantics are narrower and more explicit.

Preferred proof decomposition:

```text
VerifiedIR
   -> WasmIR           # semantic-preservation theorem
   -> wasm bytes       # encoder theorem / validated encoding
```

For the encoder, aim for one of:

```text
decode(encode(wasmIR)) = wasmIR
```

for the supported canonical subset, or a direct theorem that encoded bytes have the same semantics as the source `WasmIR`.

Do not stop the proof boundary at an internal Wasm model while leaving a large opaque assembler inside the trusted path if PSC owns the encoder.

## 26. Runtime implementations are part of compiler correctness

Backend runtime helpers are not outside the semantic story merely because they are called "runtime".

For every primitive implemented by helper code, establish a refinement relation to PSC semantics.

Examples:

```text
jsNatAdd refines PSC Nat.add
wasmNatAdd refines PSC Nat.add

jsUInt32Add refines PSC UInt32.add
wasmUInt32Add refines PSC UInt32.add

jsStringGet refines PSC String.get
wasmStringGet refines PSC String.get
```

The same principle applies to arrays, strings, machine integers, floating point, constructor tags, closure representation, and other backend runtime machinery.

A backend cannot claim semantic preservation while trusting an unmodeled runtime that implements the semantic operations.

## 27. Prove the PSC2 compiler implementation itself

The compiler should eventually have a formal functional specification distinct from its implementation.

Conceptually:

```text
CompilerSpec : CompilationInput -> Result CompilationArtifact
```

where `CompilationInput` contains explicit inputs such as:

```text
source/module contents
dependency identities and hashes
compiler options
target profile
capabilities
semantic/version identifiers
```

Then prove the portable compiler implementation refines the specification:

```text
compiler_impl_correct :
  forall input,
  compilerImplementation input
  refines
  CompilerSpec input
```

This is stronger than proving only individual user programs.

The semantic compiler should be as pure/deterministic as practical. Filesystem traversal, environment variables, current time, network access, process execution, and `tsc` invocation belong in host/build tooling rather than the semantic compiler function.

Desired property:

```text
same explicit CompilationInput
-> same canonical CompilationArtifact
```

subject only to explicitly modeled nondeterminism, ideally none in the semantic compiler.

## 28. Verified self-compilation of `compiler.ps`

Once the compiler implementation and backend pipeline are covered by the required theorems, compile the compiler through that same pipeline.

Conceptually:

```text
formal CompilerSpec
       ^
       | compiler_impl_correct
       |
 compiler.ps
       |
       | verified compilation
       v
 compiler.wasm / compiler.js
```

By composing:

1. the theorem that `compiler.ps` implements/refines `CompilerSpec`, and
2. the theorem that compilation preserves semantics,

the generated executable compiler inherits the compiler specification claim within the stated target/runtime assumptions.

This is the desired endpoint: not only a compiler source with proofs, but an executable self-hosted compiler whose behavior is connected to the formal compiler specification by the verified compilation chain.

Do not claim this merely because the executable successfully recompiles itself.

## 29. Fixed point, reproducibility, and trusting-trust defense are separate evidence

A self-host fixed point demonstrates bootstrap stability:

```text
compiler_N(compiler.ps) = compiler_N+1
```

It does **not** by itself prove that a malicious compiler executable corresponds honestly to visible source.

Therefore keep three distinct release properties:

### Reproducible build

Same frozen inputs produce the same canonical outputs.

### Self-host fixed point

Successive generations reproduce the same compiler artifact under the canonical comparison policy.

### Diverse bootstrap / DDC-style evidence

Use an independent trusted/diverse compilation route to test whether the distributed compiler executable corresponds to the visible compiler source.

A practical PSC2 progression is:

```text
visible compiler source
      |                    |
      | Lean-hosted route  | self-host route
      v                    v
compiler candidate A   compiler candidate B
      \                    /
       \                  /
        compare canonical results
```

For stronger DDC-style evidence, add as much implementation/toolchain diversity as practical rather than treating two executions of essentially the same compiler as independent.

DDC-style evidence is a provenance/integrity defense, not a replacement for compiler semantic-preservation theorems.

## 30. Proof-carrying build and minimal independent verification

Long term, a PSC release/build may emit a compact evidence manifest or certificate in addition to runtime artifacts.

Example shape:

```text
Module.js / Module.wasm
Module.d.ts
Module.js.map
Module.psc-proof.json   # or compact binary certificate
```

Potential certificate fields:

```text
sourceHash
compilerSourceHash
compilerExecutableHash
coreHash
checkedCoreHash
verifiedIrHash
backendVersion/hash
outputHash
kernelVersion
semanticsVersion
proof/validator versions
external assumptions/capabilities
```

Where practical, include replayable kernel-admission or translation-validation certificates.

Target user workflow:

```text
psc verify-build artifact.psc-proof
```

The verifier should be substantially smaller than the full compiler and should not need to trust parser, elaborator, optimizer, plugin system, or build orchestration merely to validate already-produced evidence.

A global compiler theorem may already justify many transformations; per-build certificates then primarily bind the actual source/intermediates/output and record assumptions rather than reproving the general theorem from scratch.

## 31. Target trusted computing base

Minimize what must be trusted rather than attempting to prove every ecosystem component.

Preferred long-term shape:

```text
NOT FOUNDATIONAL AUTHORITY
-------------------------
parser convenience layer
resolver
elaborator inference heuristics
tactics / simp / deriving
macros
optimizer implementations when validated
external plugins
LSP/editor tooling
npm ecosystem
application frameworks

SMALL TRUSTED / FORMALLY JUSTIFIED BASE
---------------------------------------
formal PSC Core rules and semantics
pskernel-core admission checker + its correctness argument
CheckedCore boundary
semantic-preservation theorems / verified validators
VerifiedIR semantics
restricted target semantic models
runtime primitive contracts
certificate verifier
cryptographic/hash assumptions used for provenance
```

There will always remain external assumptions such as the execution engine, operating system, hardware, and declared FFI behavior unless those layers are separately verified. State those assumptions instead of hiding them.

For Wasm, it should be possible to state a stronger and smaller runtime assumption than for arbitrary JS/Node execution.

## 32. FFI and external capabilities are explicit proof boundaries

Verified compilation cannot prove arbitrary external systems correct.

Model target-neutral capability identities and contracts above the backend boundary, then make external assumptions explicit.

Example:

```text
verified PSC computation
       |
       v
verified backend lowering
       |
------- FFI / capability boundary -------
       |
       v
Node/browser/OS/database/external library
```

A PSC theorem may rely on an FFI contract, but the implementation of that external capability is not automatically proved by the PSC compiler theorem.

Future capability/plugin APIs must never acquire authority to forge `CheckedCore` or bypass verified lowering.

## 33. Assurance ladder P0-P16

Use an explicit maturity ladder so documentation can state exactly what has been established.

| Level | Required claim/evidence |
| --- | --- |
| P0 | Differential/regression tests against Lean/reference semantics for the supported slice. |
| P1 | Tiny independent kernel validates every Core artifact entering trusted compilation. |
| P2 | Supported `.lean` and `.ps` frontends demonstrate/prove canonical Core agreement for the declared subset. |
| P3 | Erasure from `CheckedCore` preserves runtime semantics. |
| P4 | Every mandatory target-neutral IR transformation preserves semantics or is accepted by a verified validator. |
| P5 | `VerifiedIR -> WasmIR` semantic preservation. |
| P6 | Wasm encoder preserves the supported `WasmIR` semantics to delivered `.wasm` bytes. |
| P7 | `VerifiedIR -> JsIR` semantic preservation for the restricted PSC-JS subset. |
| P8 | JS emitter preserves/canonically serializes `JsIR` to delivered `.js`. |
| P9 | Backend runtime primitive implementations refine PSC primitive semantics. |
| P10 | Whole mandatory compiler pipeline has a composed semantic-preservation theorem for its declared profile. |
| P11 | `compiler.ps` implementation refines a formal compiler specification. |
| P12 | The verified compiler pipeline compiles `compiler.ps`; the produced executable inherits the compiler specification claim under stated assumptions. |
| P13 | Deterministic/reproducible self-host fixed point for the canonical compiler artifact. |
| P14 | Diverse bootstrap/DDC-style evidence binds distributed compiler executable to visible source under documented assumptions. |
| P15 | Separate-compilation/module/linking correctness for supported project builds. |
| P16 | Proof-carrying build/provenance certificates are checkable by a small independent verifier. |

Do not treat this ladder as a release-number mandate. It is an assurance vocabulary.

A release can honestly say, for example:

```text
kernel assurance: P1
compiler semantics: through P4
Wasm backend: through P6
JS backend: evidence-only / below P7
bootstrap provenance: P13
```

without pretending all dimensions have reached the same level.

## 34. Separate compilation and libraries must enter the proof story

PSC2 is intended to compile libraries and extensions, not only monolithic programs.

After the single-module compiler theorem is stable, formalize:

```text
module interface compatibility
import resolution assumptions
separate compilation
linking/composition
backend external symbol contracts
```

The target property is that separately compiled checked modules compose with the same semantics promised by whole-program compilation for the supported profile.

Do not postpone this forever: a compiler proof that applies only to a single closed toy program is not sufficient for the intended PSC ecosystem.

## 35. Strongest feasible end-state

The strongest realistic PSC2 proof story to target is:

```text
.ps source / supported .lean subset
        |
        | frontend agreement/correctness where established
        v
Canonical Core
        |
        | tiny kernel admission + kernel correctness
        v
CheckedCore
        |
        | proved erasure
        v
VerifiedIR
       / \
      /   \
 proved   proved
    /       \
 JsIR      WasmIR
  |           |
proved       proved
emit         encode
  |           |
 .js        .wasm
```

with the compiler itself inside the story:

```text
CompilerSpec
     ^
     | implementation-refinement proof
     |
compiler.ps
     |
     | verified PSC compilation
     v
self-hosted compiler executable
     |
     +-> reproducible fixed point
     +-> diverse bootstrap/DDC-style evidence
     +-> proof-carrying build/provenance evidence
```

This is intentionally stronger than any single one of these claims:

- "Lean-compatible";
- "written in a theorem prover";
- "kernel checked";
- "backend differential tests pass";
- "self-hosted";
- "bit-for-bit fixed point".

The objective is to compose small, auditable guarantees into an end-to-end statement whose assumptions are explicit.

## 36. Proof-work implementation order

Do not attempt P0-P16 in one phase. Preserve the current bootstrap priorities and add formal assurance incrementally.

Recommended order after the current TS fixed point is frozen:

1. Finish `pskernel-core` and make genuine `CheckedCore` the erasure authority.
2. Freeze a small executable semantics for the first `CheckedCore`/`VerifiedIR` slice.
3. Prove/check erasure preservation for that slice.
4. Add direct JS with the smallest `JsIR`; differential-test first, then mechanize its lowering theorem.
5. Strengthen Wasm against the same semantic slice; prefer Wasm as the first strongest executable theorem target.
6. Prove/validate JS emission and Wasm encoding to the delivered artifacts.
7. Expand primitive/runtime refinement proofs alongside language coverage.
8. Compose the first whole-pipeline theorem for a deliberately small PSC2 profile.
9. Grow the profile only while preservation proofs/validators remain green.
10. Specify the compiler as a pure deterministic function over explicit `CompilationInput`.
11. Prove the portable compiler implementation refines that specification.
12. Compile `compiler.ps` through the verified pipeline and establish the executable compiler specification claim.
13. Add reproducible fixed-point evidence.
14. Add diverse bootstrap/DDC-style provenance evidence.
15. Extend proofs to separate compilation/linking.
16. Add proof-carrying build manifests/certificates and a minimal verifier.

Prefer a **small proved compiler profile that grows monotonically** over an enormous compiler for which the verification architecture exists only on paper.

## 37. Additional anti-drift rules for compiler verification

Future work must preserve these unless an explicit reviewed decision supersedes them:

1. `CheckedCore` is an authority boundary, not a naming convention.
2. The parser/elaborator/tactics may be smart and large but do not get kernel authority.
3. Formalize the semantics of intermediate languages before claiming pass correctness.
4. Prove/validate adjacent passes and compose the results; do not create all-pairs proof obligations.
5. A complex optimizer may be untrusted if a small verified validator checks its result.
6. Runtime helpers implementing PSC primitives are inside the semantic compiler story.
7. Prove only the generated JS subset, not all ECMAScript.
8. Prefer Wasm for the strongest executable semantic theorem while preserving JS for ecosystem integration.
9. The compiler implementation proof and the compiler backend-preservation proof are distinct and both are required for the strongest self-host claim.
10. A fixed point is not a semantic correctness proof.
11. A fixed point is not a trusting-trust defense.
12. DDC/diverse bootstrap evidence is not a compiler semantic-preservation proof.
13. Proof-carrying build evidence records actual artifact provenance/assumptions; it does not replace global semantic theorems.
14. FFI/external capabilities expose explicit assumptions and never silently enter the trusted core.
15. Never claim a higher assurance level than the weakest unproved mandatory transformation in that claimed path.
16. Full Lean 4 equivalence remains a separate project-level claim and must not be inferred from PSC2 compiler verification.
17. Keep proof burden proportional to the supported profile; grow the profile after each assurance slice closes.
