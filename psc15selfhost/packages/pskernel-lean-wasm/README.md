# `@proofscript/pskernel-lean-wasm`

WebAssembly execution package for ProofScript PSC2's Lean-backed assurance kernel.

Current package identity:

```text
@proofscript/pskernel-lean-wasm@4.34.0
```

The provider is pinned to the same semantic baseline as the native Lean provider:

```text
Lean 4.34.0
Lean tag:           v4.34.0
Lean commit:        293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
protocol:           pskernel-lean/1
provider identity:  lean4-cpp
profile:            lean4.34-core
Emscripten:         6.0.9
```

`LEAN_SOURCE_PIN.json` and `EMSCRIPTEN_PIN.json` are the machine-readable identities. Do not silently substitute another Lean or Emscripten release.

## Purpose

This package provides an **external WASM assurance path** for PSC2. It receives PSC canonical admissions and executes the same Lean 4.34 semantic provider logic against the Lean runtime/kernel compiled to WebAssembly.

```text
PSC source
  -> PSC2 compiler
  -> canonical admissions
  -> @proofscript/pskernel-lean-wasm
  -> Node/CommonJS Emscripten launcher
  -> Lean 4.34 runtime + kernel in WebAssembly
  -> accept / reject
```

The package is deliberately **not part of the PSC2 bootstrap or fixed-point closure**. It is an optional external checker. Building or running the minimal self-host compiler must not require this package, Lean, or Emscripten.

## Current transport boundary

The first production seam intentionally uses the generated Emscripten command-line launcher:

```text
wasm/pskernel-lean.cjs
wasm/pskernel-lean.wasm
```

`pskernel-lean.cjs` is CommonJS because Emscripten's Node launcher uses `require(...)`; the npm package itself remains ESM.

The Node API starts that launcher with the current Node executable. This keeps the initial WASM provider aligned with the already-proven native-provider subprocess contract. A future in-process memory ABI may replace this transport without changing PSC canonical admissions or kernel admission semantics.

## Public Node API

```js
import {
  createKernel,
  checkCanonicalAdmissions,
  leanKernelProviderCommit,
  leanKernelProviderName,
  leanKernelProviderProtocol,
  leanKernelProviderVersion,
} from '@proofscript/pskernel-lean-wasm';
```

Create and health-check a provider once:

```js
const kernel = await createKernel();
const result = await kernel.checkCanonicalAdmissions(canonicalAdmissionsJson);

if (!result.accepted) {
  // The provider rejected the declaration set.
}
```

Or make a direct check:

```js
const result = await checkCanonicalAdmissions(canonicalAdmissionsJson);
```

For development or tests, `createKernel` and `checkCanonicalAdmissions` accept an explicit `launcherPath` option. Production default resolution points to the bundled `wasm/pskernel-lean.cjs` beside the package entry point.

The host adapter fails closed when the launcher cannot start, exits nonzero, returns malformed JSON, reports the wrong protocol/provider/Lean identity, fails health, or omits the boolean `accepted` result.

## Kernel semantics

This package does not generate Lean source text for Lean's parser/elaborator to reinterpret. The semantic provider code is shared with `@proofscript/pskernel-lean` and converts PSC Core values directly to Lean values/declarations before calling the Lean kernel admission path.

The WASM build stages only the semantic closure required by the provider. Parser, elaborator, compiler CLI, backends, and other PSC2 bootstrap packages are not linked into the kernel artifact.

The pinned host Lean 4.34 executable is used only as a C emitter for matching Lean source modules. The shipped runtime/kernel is built from the repository's frozen Lean 4.34 stage0 sources with pinned Emscripten 6.0.9.

## CLI probes

After building, inspect identity and runtime initialization:

```text
node wasm/pskernel-lean.cjs --health
```

Check a request on stdin:

```text
printf '%s' "$REQUEST_JSON" | node wasm/pskernel-lean.cjs --check
```

A successful response identifies the exact provider and Lean revision. A semantic rejection returns `accepted: false` with an error kind such as `kernel-rejection` rather than bypassing the kernel.

## Build and verification

See [`BUILDING.md`](./BUILDING.md) for the exact source build, pinned toolchain requirements, generated artifacts, and verification commands.

The CI gate validates all of the following before this package should be treated as usable:

- package and bootstrap-isolation contracts;
- native Lean API parity tests for the shared semantic provider;
- exact Emscripten 6.0.9 selection;
- Lean 4.34 stage0 WebAssembly runtime/kernel build;
- final C++ link through `em++` with Lean's required static library closure;
- `--health` execution of the generated artifact;
- one accepted declaration and one deliberately ill-typed kernel rejection through `--check`;
- artifact upload of the `.cjs`, `.wasm`, and any generated worker files.

Warnings emitted by the frozen Lean stage0 build are not accepted as proof of correctness by themselves; the runtime admission smoke is the required behavioral gate.
