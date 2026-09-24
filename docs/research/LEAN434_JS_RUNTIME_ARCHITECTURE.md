# Lean 4.34 source-on-JavaScript runtime architecture

Status: experimental research/implementation branch  
Branch: `runtime/lean434-js-runtime`  
Pinned upstream snapshot: `study/lean4-4.34.0`

## Goal

Make as much of Lean 4.34's Lean-written implementation as practical execute in the
JavaScript ecosystem while using the TypeScript `pskernel` implementation as
the trusted kernel boundary.

The target is **not** a transliteration of Lean's C++ runtime or C backend into
TypeScript. The target is a source-compatible execution platform:

```text
upstream/adapted Lean .lean source
        |
        v
Lean-compatible syntax / module frontend
        |
        v
Lean-written Parser / Meta / Elab code (reused where practical)
        |
        v
pskernel declaration admission
        |
        v
CheckedCoreModule
        |
        v
erasure / compiler IR
        |
        v
TypeScript
        |
        v
JavaScript (Node first, browser-capable host boundary)
```

The key engineering question is therefore not "can we port Lean's native
runtime?" It is:

> What compatibility surface is sufficient for the Lean-written source tree to
> keep running when the native kernel/runtime/host are replaced by pskernel and
> JavaScript services?

## Why the source tree supports this approach

The pinned source clearly separates large Lean-written layers from native
implementation layers.

The source inventory already studied in this repository is approximately:

| subtree | files | implementation character |
| --- | ---: | --- |
| `src/Init/` | 648 | overwhelmingly Lean |
| `src/Lean/Parser/` | 17 | Lean |
| `src/Lean/Meta/` | 478 | Lean |
| `src/Lean/Elab/` | 316 | Lean |
| `src/Lean/Compiler/` | 117 | Lean |
| `src/kernel/` | 37 | native C/C++ kernel |
| `src/runtime/` | 79 | native C/C++ runtime/host |
| `src/library/` | 45 | mostly native library bridge |

Lean's own `doc/dev/bootstrap.md` confirms the frontend and compiler are
Lean-written and bootstrapped in stages. The existing native build lowers to C
and links the C++ kernel/runtime. This branch keeps the staged bootstrap idea
but changes the lower platform:

```text
Lean bootstrap:
  .lean -> Lean IR -> generated C -> C/C++ runtime+kernel -> native

This branch:
  .lean -> checked core -> verified executable IR -> TypeScript -> JavaScript
                        \
                         -> pskernel independently checks declarations
```

## Source evidence that determines the runtime design

### 1. `Init/System/ST.lean`

Lean defines the logical shape of `ST` and `EST` in Lean itself. Mutable
reference operations are the native boundary:

- `lean_st_mk_ref`
- `lean_st_ref_get`
- `lean_st_ref_set`
- `lean_st_ref_swap`
- `lean_st_ref_take`
- `lean_st_ref_ptr_eq`

This is ideal for a JS compatibility runtime. The monadic/source-level
definitions can remain Lean code; the primitive reference cell operations can
be replaced with JS objects.

### 2. `Init/System/IO.lean`

`BaseIO` is defined in terms of `ST IO.RealWorld`, while `EIO` is defined
in terms of `EST`. The file then introduces native operations for actual host
effects (tasks, clocks, filesystem/process operations through imported modules,
profiling, initialization, and so on).

This gives a natural split:

- keep the Lean definitions of `BaseIO`, `EIO`, exception plumbing and
  ordinary combinators;
- implement only the actual host primitives in JS;
- keep Node/browser capabilities behind typed adapters.

### 3. `Init/Prelude.lean`

Core executable data structures already expose a compact native primitive
surface. Examples include:

- Nat: `lean_nat_add`, `lean_nat_mul`, `lean_nat_sub`,
  `lean_nat_div`, `lean_nat_mod`, comparisons;
- machine integers: `lean_uint8_*`, `lean_uint16_*`,
  `lean_uint32_*`, `lean_uint64_*`, `lean_usize_*`;
- Array: `lean_mk_empty_array_with_capacity`,
  `lean_array_get_size`, `lean_array_fget`, `lean_array_push`;
- String/ByteArray primitives.

ProofScript already lowers Nat/Bool/Char/String/Array operations to checked
verified-IR intrinsics, so this work extends an existing semantic path rather
than inventing another one.

### 4. `Init/Data/String/Basic.lean`

Lean's public string APIs provide Lean reference implementations while runtime
attributes select efficient native implementations such as:

- `lean_string_utf8_get`
- `lean_string_utf8_next`
- `lean_string_utf8_at_end`
- `lean_string_utf8_extract`
- `lean_string_utf8_get_fast`
- `lean_string_utf8_next_fast`

The source documents the important semantic detail: `String.Pos.Raw` is a
UTF-8 **byte** position, not a JavaScript UTF-16 index. The existing ProofScript
TypeScript emitter already implements UTF-8-byte-position behavior. That code
is a useful oracle for the reusable runtime functions.

### 5. `Lean/Meta/Basic.lean`

Lean describes the Meta layer around four mutually dependent services:

1. weak-head normalization with metavariables/transparency,
2. definitional equality / unification,
3. type inference,
4. type-class resolution.

Those are frontend/meta services, not kernel authority. Reused/adapted Meta code
may be complex and even buggy; every accepted declaration still has to be
rechecked by pskernel.

### 6. `Lean/Elab/Frontend.lean`

The front-end loop is largely ordinary Lean code and has the shape:

`ReaderT Context (StateRefT State IO)`.

Parsing/elaboration state is therefore reusable once the runtime provides
arrays, strings, names, syntax objects, references, state/error effects and the
environment APIs.

Later portions of this file also contain native/server concerns such as
compacted regions, incremental snapshot persistence and parallel loading.
Those are host/storage mechanisms and should be replaced rather than copied.

### 7. `Lean/Environment.lean`

This is the most important compatibility boundary.

The source-level Environment combines:

- kernel-checked constant declarations,
- module/import metadata,
- environment extensions,
- IR/interpreter state,
- compacted native memory regions,
- asynchronous/import infrastructure.

ProofScript must **split these responsibilities**:

```text
Lean-compatible Environment facade
  |
  +-- checked constants ----------> pskernel Environment / Kernel
  |
  +-- parser/meta extensions -----> untrusted persistent JS/PS data
  |
  +-- module metadata ------------> ProofScript module/artifact layer
  |
  +-- compacted native regions ---> NOT PORTED
  |
  +-- native IR interpreter ------> NOT proof authority
```

The facade can preserve the source API closely without reproducing Lean's
native storage representation.

### 8. `Lean/Compiler/ExternAttr.lean`

Lean already models an extern as a backend-selectable attribute. This suggests a
clean compatibility mechanism.

A source declaration such as an upstream `@[extern "lean_st_mk_ref"]` should
remain source-compatible. During elaboration/lowering, the symbol is resolved
through a pinned JavaScript runtime manifest instead of a C linker.

No arbitrary C symbol is silently accepted. Unknown externs fail closed.

## Central design decision: preserve source APIs, replace implementation boundaries

There are five reuse classes.

### A. DIRECT

Pure Lean definitions that only use supported language/library facilities.

Target: compile with no semantic edit.

Typical candidates:

- pure collection algorithms;
- parser combinators;
- traversal utilities;
- many syntax/name helper functions;
- ordinary data declarations;
- substantial portions of Meta/Elab algorithms after their dependencies exist.

### B. COMPATIBILITY-SHIM

Lean source remains unchanged, but a runtime/kernel primitive is mapped to a JS
or pskernel implementation.

Examples:

- `@[extern "lean_array_push"]` -> JS persistent-array implementation;
- `@[extern "lean_st_ref_get"]` -> JS reference cell;
- kernel declaration admission -> pskernel;
- platform information -> JS host adapter.

This is the highest-value category because it maximizes source reuse.

### C. STRUCTURAL-ADAPTATION

The algorithm is reusable but the surrounding subsystem is native-specific.

Examples:

- Environment import/module plumbing;
- persistent environment extensions;
- source snapshots;
- initializer execution;
- interpreter hooks.

Preserve dataflow/API shape where useful but replace native storage and
scheduling mechanisms.

### D. REPLACE

Do not port implementation details whose purpose disappears in JS.

Examples:

- reference counting;
- boxed-object allocation ABI;
- C stack/closure ABI;
- `dlsym` / dynamic-library loading;
- compacted memory regions;
- C code generation;
- C compiler invocation;
- native object ownership/borrowing optimization.

JavaScript GC and module loading provide different mechanisms.

### E. DEFER

Features that are valid Lean capabilities but do not block source reuse for the
ProofScript compiler:

- arbitrary native plugins;
- unrestricted `unsafe` integration;
- every server snapshot optimization;
- full Lake compatibility;
- exact `.olean` binary compatibility;
- every tactic/macro extension;
- native precompiled-module behavior.

## Runtime representation strategy

The JavaScript runtime should preserve **observable Lean semantics**, not Lean's
native ABI representation.

### Primitive values

Initial representation:

| Lean | JavaScript |
| --- | --- |
| `Nat` | `bigint`, checked non-negative |
| `Int` | `bigint` |
| `Bool` | `boolean` |
| `UInt8/16/32` | `number` with modular normalization |
| `UInt64` | `bigint` with 64-bit masking |
| `USize` | `bigint` at semantic boundary; checked conversion for JS indexes |
| `Float` | `number` |
| `Char` | one Unicode-scalar JS string |
| `String` | JS string plus UTF-8 byte-position helpers |
| `Unit` | `undefined` |
| `Array α` | JS array with persistent/value-semantic operations |
| `ByteArray` | initially `Uint8Array` or a compatibility wrapper |

Native Lean's copy-on-write optimization is not observable Lean semantics.
Therefore the safe JS implementation may clone an array for `push/set`.
Later uniqueness analysis may optimize this without changing semantics.

### Inductives and structures

The existing verified backend already owns canonical runtime layouts for
ProofScript structures and inductives. Lean compatibility should use the same
owned layout or a checked conversion layer; it must not create a second
semantic representation that bypasses checked core.

### Names / Levels / Expr

These are special because Parser/Meta/Elab manipulate them heavily.

Preferred long-term approach:

- make the runtime representation structurally compatible with pskernel's
  `Name`, `Level`, and `Expr` model where practical;
- otherwise use a one-time checked conversion boundary rather than repeated
  ad-hoc conversions;
- preserve Lean APIs such as constructor tests, projections and expression
  traversals so upstream Meta algorithms require minimal changes.

This is a critical performance and reuse milestone.

## ST, EIO and IO

### ST references

The first executable runtime slice implements Lean-compatible reference cells.

JS can model a ref as an identity-bearing object:

```ts
{ value: T | EMPTY }
```

- `mkRef`: allocate object;
- `get`: read;
- `set`: write;
- `swap`: replace and return old;
- `take`: remove current value and return it;
- `ptrEq`: object identity.

Lean's native implementation can block when reading an empty multi-threaded ref.
The first JS bootstrap runtime is single-threaded. An empty read fails closed
instead of inventing a value. Async/task-compatible blocking semantics are a
later host-runtime milestone.

### EIO / IO

Do not immediately turn every Lean `IO` action into a JavaScript `Promise`.
That would force an unnecessary whole-program async rewrite.

For the compiler bootstrap:

1. preserve source-level `BaseIO/EIO/IO` definitions;
2. lower the world token away as an execution artifact;
3. provide deterministic synchronous Node host adapters for compiler-critical
   file/environment operations where possible;
4. introduce Promise/task scheduling only for Lean APIs that actually require
   concurrency.

Browser adapters can use an explicit asynchronous host capability layer without
changing theorem/kernel semantics.

## Extern resolution

Introduce a versioned manifest:

```text
Lean extern symbol
    -> JS export
    -> semantic category
    -> upstream source location
    -> implementation status
```

Initial categories:

- `pure-primitive`
- `persistent-value`
- `mutable-state`
- `host-io`
- `scheduler`
- `kernel-bridge`
- `unsupported`

Rules:

1. unknown extern => compile failure;
2. host extern => explicit capability/import;
3. extern execution does not become proof evidence;
4. pskernel never trusts the JS return value while checking a proof;
5. runtime assumptions remain visible in assurance metadata.

## `implemented_by`

Lean's `@[implemented_by impl]` is fundamentally different from a theorem.

Policy:

- keep the reference definition as logical meaning;
- initially ignore `implemented_by` when the reference implementation is
  executable enough;
- optionally select the optimized implementation at runtime;
- record that selection as an executable assumption/optimization;
- never use arbitrary JS implementation results to establish kernel
  definitional equality.

The existing pskernel `NativeEvaluator` extension remains unset by default.
A future certified native evaluator is a separate assurance project.

## Unsafe code

Lean allows unsafe/meta executable definitions. pskernel already tracks
definition safety.

Policy:

- unsafe code may execute in JS;
- unsafe code cannot manufacture trusted declarations;
- declaration admission still passes through pskernel;
- any compatibility path that cannot preserve Lean's safety restriction fails
  closed.

## Parser / macros / syntax reuse

Maximum source reuse eventually requires more than the current bounded
ProofScript Lean-subset parser. This branch should grow a Lean-compat frontend,
but it must converge on the same semantic path.

Recommended staging:

1. bootstrap syntax required by `Init` and the selected Parser/Meta/Elab files;
2. attributes needed for runtime linkage: `extern`, `implemented_by`,
   `inline`, `expose`, selected initialization attributes;
3. module/import syntax;
4. quotation/macro support only when upstream reused code actually requires it;
5. custom syntax categories and arbitrary user extensions later.

Unsupported constructs must fail closed.

## Kernel bridge

The source-facing kernel API should be Lean-shaped but pskernel-backed.

Conceptually:

```text
Lean source calls addDecl / environment operation
                  |
                  v
      compatibility Environment facade
                  |
                  v
          declaration conversion
                  |
                  v
               pskernel
                  |
          accepted / rejected
```

Important invariant:

> Parser, Meta, Elab, macros, runtime and host code are untrusted producers of
> candidate declarations. Only pskernel admission makes a declaration trusted.

## Module artifacts

Exact `.olean` compatibility is not required for the first successful
JavaScript-hosted Lean source bootstrap.

Preferred first artifact path:

```text
.lean source
  -> checked admissions
  -> @proofscript/module artifact
  -> JS compiler artifact
```

Later, an `.olean` reader can be added for ecosystem interoperability if its
cost is justified. It must still replay declarations through pskernel.

## Compiler reuse

There are two different goals that should not be conflated.

### Frontend/compiler implementation reuse

We want to reuse Lean-written Parser/Meta/Elab/compiler-support algorithms as
source material. This is immediately valuable.

### Reusing the full Lean native compiler pipeline

Lean's current compiler ultimately targets its native runtime model and C/native
backends. Directly adopting all of LCNF/codegen would initially duplicate the
existing ProofScript checked compiler path.

Therefore:

- reuse compiler-support algorithms needed for self-hosting;
- keep checked core -> erasure -> verified ProofScript IR -> TS as the first JS
  execution path;
- after the JS-hosted frontend works, evaluate Lean LCNF passes individually;
- optimization passes such as CSE, specialization, lambda lifting and closure
  conversion may be adapted if they can be replay/gated as semantics-preserving
  compiler transformations;
- do not make LCNF a second semantic checker.

## Bootstrap strategy

### Stage J0 — current TypeScript bootstrap

Current TypeScript Parser/Meta/Elab + pskernel compiles the bounded Lean subset
and ProofScript to JS.

### Stage J1 — JS runtime compatibility foundation

Implement the runtime primitives and extern manifest required by selected
upstream `Init` modules.

Acceptance:

- runtime unit tests;
- exact semantic edge cases for Nat, Array, String and ST refs;
- no kernel dependency on runtime.

### Stage J2 — Lean object-model compatibility

Make `Name`, `Level`, `Expr`, Syntax/source positions and environment
operations usable by reused Lean code.

Acceptance:

- round-trip fixtures against the pinned Lean 4.34 source/oracle;
- pskernel can admit declarations emitted through the facade.

### Stage J3 — reusable Init slice

Compile an increasing set of actual upstream `src/Init/**/*.lean` files with
zero or minimal compatibility edits.

Measure:

- direct files;
- shim-only files;
- structurally adapted files;
- unsupported files.

This measured reuse ratio is more meaningful than a guessed percentage.

### Stage J4 — Parser

Reuse the Lean parser core. Replace only host/module integration.

Acceptance:

- parse a representative Lean module corpus;
- compare normalized Syntax trees with Lean 4.34.

### Stage J5 — Meta

Bring up the required Meta core:

- metavariable context;
- WHNF;
- type inference;
- defeq/unification;
- instance synthesis;
- local contexts;
- saved-state rollback.

Every produced declaration is independently rechecked by pskernel.

### Stage J6 — Elab

Reuse/adapt the command and term elaborator needed for the compiler source.

Acceptance:

- upstream/adapted Lean source -> pskernel checked declarations;
- differential elaboration corpus against Lean 4.34 where outputs are stable
  enough to compare.

### Stage J7 — compiler bootstrap

Compile the ProofScript/Lean-compatible compiler implementation to JS using the
reused frontend.

Then perform a fixed-point gate:

```text
bootstrap compiler.js
      -> compiler source
      -> compiler-1.js
      -> same compiler source
      -> compiler-2.js
```

Require canonical checked-core/IR equality and behavior equivalence.

### Stage J8 — broader Lean source compatibility

Only after the compiler works:

- more Init/Std;
- broader macros/quotations;
- tasks/async;
- browser host;
- optional `.olean` interoperability;
- selected Lean compiler optimizations.

## Source reuse acceptance matrix

Every upstream file considered for reuse must be recorded with:

| field | meaning |
| --- | --- |
| upstream file | exact path in `study/lean4-4.34.0` |
| classification | DIRECT / SHIM / ADAPT / REPLACE / DEFER |
| unsupported syntax | source-language blockers |
| runtime externs | C/native primitives needing JS mappings |
| kernel dependencies | APIs mapped to pskernel |
| host dependencies | Node/browser capability |
| target package | where compatibility lives |
| gate | executable/differential test |

This branch should automate as much of this inventory as practical.

## First implementation slice

The first runtime code on this branch intentionally starts below the compiler:

1. versioned Lean 4.34 JS runtime descriptor;
2. persistent Array primitives;
3. UTF-8-byte-position String primitives;
4. single-threaded ST reference primitives;
5. an extern manifest tying JS exports to Lean's native symbol names;
6. regression tests.

This does **not** claim that arbitrary Lean source compiles yet. It creates the
runtime contract that a broader Lean-compatible source frontend can target.

## Success criteria

The experiment is successful when all of the following are true:

1. substantial real files under `src/Init`, `Lean/Parser`, `Lean/Meta` and
   `Lean/Elab` execute as source-derived JS rather than TypeScript rewrites;
2. native C/C++ kernel code is not required for trust;
3. native Lean runtime object management is not required;
4. pskernel independently admits every trusted declaration;
5. runtime/extern/unsafe behavior cannot manufacture proof authority;
6. the compiler reaches a JS bootstrap fixed point;
7. source reuse is measured by reproducible file-level census rather than a
   marketing percentage.

## Non-goals for the first milestones

- byte-for-byte compatibility with Lean's native object ABI;
- full Lake implementation;
- full `.olean` binary compatibility;
- all native plugins/dynamic libraries;
- copying the C++ runtime into TypeScript;
- enabling arbitrary JS as a kernel native evaluator;
- replacing the existing single checked-core semantic pipeline.

## Bottom line

The Lean 4 source layout makes this architecture feasible.

The large reusable asset is not the native runtime. It is the Lean-written
implementation above the native boundary. The correct strategy is therefore to
make the JavaScript platform sufficiently Lean-compatible that those source
files continue to work, while replacing native primitives with explicit JS
services and replacing kernel authority with pskernel.
