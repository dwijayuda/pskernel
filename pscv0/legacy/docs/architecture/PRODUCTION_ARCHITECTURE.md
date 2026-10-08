# ProofScript production architecture

**Status:** target architecture and engineering guide. This document is forward-looking; it must not be read as an implementation or proof claim.

## 1. Design objective

ProofScript should become production-grade without sacrificing the properties that make the current architecture valuable:

- a small Lean-faithful semantic core;
- an independent kernel authority;
- explicit erasure;
- a target-neutral executable IR;
- independently owned JavaScript and WebAssembly paths;
- optional Lean, Rust, and TypeScript adapters;
- a small bootstrap closure;
- fail-closed handling of unsupported semantics;
- self-host and fixed-point evidence that remain independent from semantic-correctness claims.

The principal architectural task is therefore **enforcement**, not conceptual replacement.

## 2. Current provider versus target authority

During the current hardening phase, use the pinned `@proofscript/pskernel-lean-wasm` provider (`lean434-wasm`) as the default checked provider. It is external to the compiler bootstrap closure and checks canonical admissions through the same provider-neutral host boundary used by other checkers.

Long term, `pskernel-core` remains the intended owned authority once its declared readiness gates close. Native Lean remains an explicit reference/oracle route. No rejection, timeout, unsupported result, or provider failure may silently select a different kernel.

The compiler architecture must therefore depend on a **kernel provider contract**, not on a concrete provider implementation.

## 3. Target semantic pipeline

```text
.ps / supported Lean subset
        |
        v
+-------------------------------+
| smart, untrusted frontend     |
| parser / resolver / Meta      |
| elaborator / tactics/plugins  |
+---------------+---------------+
                |
           CandidateCore
                |
                v
+-------------------------------+
| pskernel-core                 |
| designated admission authority|
+---------------+---------------+
                |
            CheckedCore
                |
                v
             Erasure
                |
                v
          ErasedIR/RuntimeIR
                |
         verifyRuntimeIr
                |
                v
           VerifiedIR
       +--------+--------+------------------+
       |                 |                  |
       v                 v                  v
     JsIR              WasmIR            adapters
       |                 |             Lean / Rust / TS
       v                 v
      .js               .wasm
```

No executable backend may consume arbitrary elaborated declarations or raw candidate Core.

## 3. Current implementation and required evolution

### 3.1 Admission-ready versus genuinely checked

The current compiler correctly uses the honest staging type `PsCompilerAdmissionReadyModule`. Today it proves codec/persistence readiness and reconstructs an environment before erasure; it does not claim real kernel admission.

Production target:

```text
PsElabModuleResult
      |
      v
CandidateCore
      |
      | kernelProvider.checkModule
      v
CheckedModule
      |
      v
eraseCheckedModule
```

`CheckedModule` must be construction-restricted so only the selected kernel provider can create it. If source-language/module privacy cannot enforce this strongly in generated JavaScript, use a provider-owned checked handle containing a session identity, opaque handle, checked-core hash, and kernel-contract identity.

### 3.2 Construction IR versus VerifiedIR

The current `PsVerifiedIrType` contains `unknown`, and erasure can produce it. That is useful while constructing runtime IR but weakens the long-term meaning of “VerifiedIR”.

Split the stages:

```text
CheckedCore
   -> ErasedIR / RuntimeIR       # may contain unresolved construction forms
   -> validateRuntimeIr
   -> VerifiedIR                # executable well-formedness established
```

The validator must establish at least:

- no unresolved executable `unknown`;
- all names resolve;
- calls have valid arity and function types;
- structure/constructor fields exist;
- intrinsic argument/result types agree;
- match alternatives are structurally valid;
- runtime types have supported representations;
- module/external references are valid;
- required runtime primitives are declared.

If the runtime truly has a representation-irrelevant type, give it a precise semantic constructor rather than using an ambiguous `unknown`.

### 3.3 Backend dependencies must enforce authority

Backend core packages depend only on validated IR and target-neutral support metadata; they do not import the semantic compiler.

Current TypeScript/Rust split:

```text
compiler frontend
      |
      +--> driver-ts   --> backend-ts
      |
      +--> driver-rust --> backend-rust

backend-ts   -X-> compiler
backend-rust -X-> compiler
```

The concrete composition modules are:

```text
Ps.DriverTs.Compiler
Ps.DriverRust.Compiler
```

They own source/prepared-module convenience APIs and may call the semantic compiler. Backend core modules own only target lowering/emission from validated IR.

Long-term target remains:

```text
backend-js   -> compiler-ir/verified
backend-ts   -> compiler-ir/verified
backend-rust -> compiler-ir/verified
backend-wasm -> compiler-ir/verified
```

Bridge/formatting utility cleanup can proceed independently; the critical authority edge is that backend core cannot import `Ps.Compiler` or construct/erase semantic compiler state.

This makes a kernel/erasure bypass unavailable by dependency construction rather than only prohibited by convention.

## 4. Proposed package layers

The exact names may change, but preserve the dependency direction.

### 4.1 Foundational semantic packages

```text
foundation
syntax
core
environment
meta
elab
kernel-contract
pskernel-core
checked-core
erasure
runtime-ir
verified-ir
```

Rules:

- lower layers never import target backends;
- the kernel never imports host/project/plugin/backend code;
- `checked-core` exposes checked values/receipts but does not implement smart frontend behavior;
- `verified-ir` owns validation and canonical executable IR.

### 4.2 Target packages

```text
backend-js
backend-wasm
backend-ts
backend-rust
backend-lean
```

All consume validated IR. Direct JS and direct Wasm are the canonical PSC-owned executable backends. TS/Rust/Lean remain useful adapters and independent differential/provenance routes.

### 4.3 Platform packages

```text
interface-ir
capability-contract
project
build-graph
artifact-codec
artifact-store
package-manifest
compiler-service
diagnostics
plugin-contract
```

These may grow rapidly while Core/kernel contracts evolve slowly.

### 4.4 Host packages

```text
host-node
host-native
host-wasm
cli
lsp
registry-client
release-tools
```

Filesystem, network, process execution, clock, randomness, tool discovery, signing, registry access, and remote cache access live here or behind explicit capability interfaces.

## 5. Runtime semantic architecture

The target-neutral runtime contract is now frozen as:

```text
psc-runtime-semantics/1
SHA-256 d610e1a1936dd1b090a44a8293a68436bc9300ad5c82872e8faf4e1e6b97ae03
```

Its normative definition is `docs/architecture/contracts/RUNTIME_SEMANTICS_V1.md`.

Target-specific ABI profiles remain separate contracts and are **not** frozen merely by the runtime-semantics contract:

```text
RuntimeSemantics-v1
    |
    +-- future JsRuntimeABI-v1
    +-- future WasmRuntimeABI-v1
    +-- future LeanRuntimeABI-v1
    +-- future RustRuntimeABI-v1
```

The target-neutral contract covers observable behavior for:

- `Nat`, `Int`;
- signed/unsigned machine integers and word-size rules;
- `Float` and `Float32`;
- `Bool`, `Char`, `String`, `Unit`;
- arrays;
- structures and inductives;
- closures/calls;
- errors;
- future resource/capability handles.

Physical representations remain backend-private.

## 6. Direct JavaScript architecture

Do not make direct JS a string-printer bolted onto VerifiedIR.

The first experimental slice now exists as `psc-js-ir/0-experimental`; see `docs/architecture/contracts/JS_IR_EXPERIMENTAL_V0.md`. It is deliberately non-bootstrap and covers only a small primitive/function subset for differential validation.

Target architecture:

```text
VerifiedIR
   -> representation selection
   -> JsIR
   -> validateJsIr
   -> canonical ESM emitter
   -> .js
```

Side artifacts:

```text
checked exported interface -> InterfaceIR -> .d.ts
source provenance chain    -> source-map emitter -> .js.map
```

`.d.ts` and source maps are not runtime semantic authorities.

Keep the generated JavaScript subset deliberately small so that semantic modeling, differential testing, and eventual proof remain tractable.

## 7. WebAssembly architecture

Preserve the current independent model:

```text
VerifiedIR
   -> WasmIR
   -> validateWasmIr
   -> canonical encoder
   -> .wasm
```

Do not define Wasm through JS/TS or Rust. Rust-to-Wasm can remain an alternative implementation/differential route.

The strongest executable assurance target should be direct Wasm because its target semantics and binary validity are narrower than arbitrary JavaScript execution.

## 8. Lean and Rust native adapters

### Lean native

Use for:

- reference native builds;
- compiler/tooling executables;
- independent provenance route;
- differential semantics;
- native application support where Lean runtime/FFI assumptions are acceptable.

Conceptual path:

```text
.ps -> checked PSC pipeline -> canonical Lean adapter -> Lean compiler -> native
```

### Rust native

Use for:

- production systems integration;
- broad native FFI;
- optimized machine-code path;
- alternative Wasm path.

Rust ownership/borrowing/lifetimes remain target implementation details and never enter VerifiedIR.

## 9. InterfaceIR and capabilities

Keep foreign interfaces distinct from executable semantics:

```text
VerifiedIR  = executable checked PSC program semantics
InterfaceIR = foreign/API contract semantics
```

InterfaceIR should be able to represent:

- primitive/list/tuple/record/variant/enum/option/result forms;
- functions and constants;
- modules/interfaces;
- resources/handles with owned and borrowed forms;
- errors;
- sync/async/future/stream behavior;
- target availability and ABI profile;
- effect/capability requirements.

Adapters may consume/produce WIT, `.d.ts`, rustdoc metadata, and future native IDLs.

## 10. Compiler service boundary

All tools use one semantic service.

Candidate operations:

```text
parse
check
typeOf
hover
definition
references
rename
completionCandidates
goalState
candidateCore
checkedCore
verifiedIr
buildPlan
```

LSP, IDE, docs, package tooling, AI agents, and build orchestration must not create independent semantic implementations.

## 11. Production diagnostics

Replace host-only error strings with a stable structured model:

```text
Diagnostic {
  code
  severity
  primarySpan
  message
  notes
  relatedSpans
  phase
}
```

Example stable code families:

```text
PS-PARSE-xxxx
PS-RESOLVE-xxxx
PS-ELAB-xxxx
PS-KERNEL-xxxx
PS-IR-xxxx
PS-JS-xxxx
PS-WASM-xxxx
PS-PACKAGE-xxxx
```

The CLI may render these as text, but the compiler service returns structured diagnostics.

## 12. Production CLI

The current Node CLI is bootstrap orchestration and should remain useful during transition.

Long-term public surface:

```text
psc check
psc build
psc run
psc test
psc package
psc publish
psc verify
psc doctor
```

Repository bootstrap commands remain internal development workflows rather than long-term public semantics.

## 13. Performance rule

Keep the semantic compiler as pure/deterministic as practical.

Move:

- filesystem;
- package resolution;
- incremental graph;
- CAS;
- remote cache;
- process/tool invocation;
- network;
- signing/publishing;
- LSP scheduling

into the host/build layer.

This allows aggressive production performance work without enlarging the semantic trusted path.

## 14. Anti-drift rules

1. `CheckedCore` means kernel-admitted, not codec-valid.
2. “VerifiedIR” means validated executable IR; construction placeholders belong earlier.
3. Backends do not import frontend/kernel authority.
4. Core/VerifiedIR never absorb JS, Rust, Wasm, WIT, npm, or OS representation policy.
5. JS and Wasm remain independent direct backends.
6. Lean/Rust/TS remain valuable adapters and oracles.
7. Plugins cannot construct checked artifacts or bypass validated lowering.
8. Host impurity is explicit and outside the semantic compiler.
9. Unsupported semantics reject; no fallback changes meaning.
10. Performance improvements may change indexes/storage but never specified resolution/admission ordering.
