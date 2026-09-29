# PSC2 Lean WASM Kernel Provider Design

## Status

Approved architecture for `@proofscript/pskernel-lean-wasm@4.34.0` on branch `psc2/pskernel-lean-wasm`.

## Goal

Provide a WebAssembly execution variant of the existing Lean 4.34 assurance provider that consumes the same canonical checked-admissions v2 payload and returns the same provider identity plus accept/reject semantics as `@proofscript/pskernel-lean@4.34.0`.

The WASM package is an optional host assurance provider. It is not part of the first PSC2 fixed-point compiler closure and does not become compiler authority merely by existing.

## Identity and pins

The package name is:

```text
@proofscript/pskernel-lean-wasm
```

The package version carries the Lean semantic version:

```text
4.34.0
```

Provider semantic identity remains pinned to:

```text
protocol:    pskernel-lean/1
provider:    lean4-cpp
leanVersion: 4.34.0
leanCommit:  293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
profile:     lean4.34-core
```

The first Emscripten build pin is `6.0.10`. This pin is provisional until the first real Lean-4.34 WASM build succeeds. The build itself is the compatibility authority; if Lean 4.34 is incompatible with that SDK, replace the pin with the nearest verified working version and record the reason in the package docs and pin file.

## Semantic reuse

The WASM provider must reuse the existing native provider semantic modules:

```text
PsKernelLean.Error
PsKernelLean.Convert
PsKernelLean.Prelude
PsKernelLean.Protocol
PsKernelLean.Admission
```

It must not fork or duplicate declaration conversion, prelude construction, canonical admission decoding, or Lean kernel admission rules.

Only transport/runtime integration differs.

Native:

```text
stdin JSON -> admitCanonicalAdmissions -> stdout JSON
```

WASM:

```text
UTF-8 bytes -> exported WASM check function -> result UTF-8 bytes
```

The public JavaScript API must remain equivalent at the semantic level:

```text
checkCanonicalAdmissions(source: string) -> provider result
```

## Initial implementation route

The first implementation uses the existing Lean provider source and Lean/Emscripten support rather than attempting to compile only the copied `kernel/`, `runtime/`, and `util/` directories directly.

The copied C++ trees are not standalone and remain reserved for a later small-C-ABI/standalone-kernel milestone.

The build should follow Lean 4.34's Emscripten-supported runtime path. The repository's pinned Lean source documents an Emscripten build using `emconfigure cmake` and the `lean_js_wasm` target. The provider-specific build may reuse that runtime/toolchain closure while linking only the PSC provider entry closure needed for admission.

## Package layout

```text
psc15selfhost/packages/pskernel-lean-wasm/
├── package.json
├── index.mjs
├── LEAN_SOURCE_PIN.json
├── EMSCRIPTEN_PIN.json
├── README.md
├── BUILDING.md
├── provider/
│   └── PsKernelLeanWasm/
│       └── Api.lean
├── host/
│   ├── loader.mjs
│   └── loader.test.mjs
├── scripts/
│   ├── build-wasm.mjs
│   ├── verify-wasm.mjs
│   └── differential.test.mjs
└── wasm/
    ├── pskernel-lean.mjs
    └── pskernel-lean.wasm
```

The exact generated glue filenames may vary with the verified Emscripten link mode, but the npm exports must not expose raw build-tree paths.

## Public API

The package root exports a Node-first asynchronous constructor/check API:

```js
createKernel(options?) -> Promise<Kernel>
checkCanonicalAdmissions(source, options?) -> Promise<KernelResult>
```

`Kernel` exposes:

```js
checkCanonicalAdmissions(source: string) -> Promise<KernelResult>
metadata() -> provider identity
```

The top-level convenience `checkCanonicalAdmissions` may instantiate/cache the default module internally.

The result shape must match the native provider's semantic JSON result:

Accepted:

```json
{
  "protocol": "pskernel-lean/1",
  "provider": "lean4-cpp",
  "leanVersion": "4.34.0",
  "leanCommit": "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b",
  "profile": "lean4.34-core",
  "accepted": true
}
```

Rejected responses preserve stable `errorKind`, optional `declarationIndex`, and `message`.

## WASM boundary

Do not model the WASM package as stdin/stdout.

The runtime boundary is bytes-in/bytes-out. The generated JS adapter owns UTF-8 conversion and WASM memory management.

The exported low-level ABI must be minimal and versioned. A practical shape is:

```text
psc_kernel_alloc(len) -> ptr
psc_kernel_check(ptr, len) -> result handle/packed pointer+length
psc_kernel_result_ptr(handle) -> ptr
psc_kernel_result_len(handle) -> len
psc_kernel_free(ptr)
psc_kernel_result_free(handle)
```

If Lean/Emscripten integration makes a different equivalent ABI substantially safer, it may be used, but the public npm API and semantic result contract must remain unchanged.

## Node-first milestone

The first release target is Node.js.

Acceptance does not initially require browser execution. Node-first allows direct differential checking against `@proofscript/pskernel-lean@4.34.0` with identical fixtures.

The Node WASM package must not require a Lean installation, Lake, C/C++ compiler, or Emscripten at consumption time. Build-time dependencies are allowed only in the distribution workflow.

## Browser milestone

Browser support is a second milestone after Node differential parity.

The desired browser profile is:

```text
single-threaded
no Node-specific API
no filesystem requirement
no network requirement
no install-time fetch
```

Do not claim browser support until a real browser smoke test instantiates the distributed `.wasm` and performs both a valid acceptance and a kernel rejection.

Avoid requiring `SharedArrayBuffer`/cross-origin isolation if a single-threaded Lean/Emscripten build can be made reliable. If pthreads are unavoidable, document that as an explicit profile constraint rather than hiding it.

## Differential assurance

For every canonical fixture used by the WASM provider tests:

```text
nativeResult = @proofscript/pskernel-lean
wasmResult   = @proofscript/pskernel-lean-wasm
```

The provider identity and semantic acceptance/rejection fields must match. Diagnostic message text may only differ if the difference is intentionally normalized and covered by tests; the preferred behavior is exact equality.

At minimum differential tests cover:

- valid definition acceptance;
- declaration type mismatch rejection;
- malformed canonical JSON rejection;
- unsupported/missing constant rejection;
- canonical protocol/version mismatch;
- inductive admission fixture.

## Trust and bootstrap boundary

`@proofscript/pskernel-lean-wasm` must be marked:

```json
{
  "proofscript": {
    "bootstrap": false,
    "portable": false,
    "role": "external-lean-kernel-provider-wasm"
  }
}
```

The first PSC2 compiler fixed-point closure must explicitly forbid both:

```text
pskernel-lean
pskernel-lean-wasm
```

The CLI/host may select either provider. Portable semantic compiler packages must not import either implementation.

## Distribution

`npm pack` must contain the `.wasm` and JavaScript loader/glue required for runtime use.

A clean temporary Node consumer must be able to:

```text
npm install <packed tarball>
import @proofscript/pskernel-lean-wasm
check canonical admissions
```

without Lean/Lake/Emscripten present.

No runtime network fetch is allowed for the default package path.

## CI gates

The Node WASM milestone is complete only when all are green:

1. exact Lean source pin check;
2. exact Emscripten SDK pin check;
3. WASM provider build;
4. metadata/health identity test;
5. valid PSC declaration acceptance;
6. invalid PSC declaration reaches Lean kernel and is rejected;
7. native-vs-WASM differential suite;
8. `npm pack` contains the required WASM/glue files;
9. clean Node consumer executes the packed package with no toolchain installed;
10. bootstrap closure still excludes both Lean providers.

The browser milestone is separate and requires a real browser smoke.

## Non-goals for the first WASM milestone

- rewriting the Lean kernel;
- directly compiling only the copied C++ kernel/runtime/util snapshot;
- making WASM the default PSC kernel authority;
- adding `CheckedCore`/`CheckedModule` inside the compiler;
- browser pthread optimization;
- minimizing binary size before semantic parity;
- replacing the native provider.

## Merge policy

The WASM branch may be developed independently of the moving PSC2 self-host branch. It should merge back into the native provider branch only after the Node WASM gates are green. The combined provider work should merge into `psc2/minimal-selfhost-psc15` only from a GREEN synchronization point with fresh bootstrap and generated-compiler verification.