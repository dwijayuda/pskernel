# Building the PSC2 Lean WASM provider

`@proofscript/pskernel-lean-wasm` is pinned to Lean 4.34.0 commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b` and Emscripten 6.0.9. Do not substitute another Lean or Emscripten revision when producing the assurance artifact.

## Architecture

The target runtime and kernel must be built from Lean 4.34.0's current `src/` tree with Emscripten as a `STAGE=1` build. The exact native Lean 4.34.0 installation is the previous-stage compiler (`PREV_STAGE`) and is used as the host Lean C emitter for current Lean and provider modules; its native object files are never linked into the WebAssembly artifact.

This split is intentional. The frozen stage0 generated-C snapshot contains bootstrap ABI assumptions that are tolerated by native builds but conflict with WebAssembly's typed function signatures. Linking current provider-generated C against that frozen stage0 closure is therefore forbidden.

The npm package carries the exact ProofScript semantic source closure used by the provider under `source/proofscript/`. It also carries the exact upstream Lean `src/kernel/` snapshot under `kernel/` for audit, together with `LEAN_LICENSE` and `KERNEL_SOURCE_MANIFEST.json`. A complete Lean source checkout is larger and is fetched only when an explicit rebuild needs it.

## Prerequisites

The build expects:

- exact Lean 4.34.0 / commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b` on `PATH`;
- Emscripten 6.0.9 (`emcc`, `em++`, and `emar`);
- Git, CMake, Make, Node.js, and standard Unix build tools.

CI installs these exact versions before invoking the package build.

## Build in the pskernel checkout

From `psc15selfhost/` run:

```text
packages/pskernel-lean-wasm/scripts/build-wasm.sh
```

The script uses the live sibling PSC semantic sources and the checked-in `study/lean4-4.34.0` tree.

## Build from the npm package

Normal npm consumers do **not** need Lean or Emscripten: the package uses the prebuilt `wasm/pskernel-lean.wasm` and `wasm/pskernel-lean.cjs` by default.

To explicitly rebuild from the source distributed in the package:

```text
npm run build:wasm
```

In package mode the build script uses `source/proofscript/` for the ProofScript/provider sources. It fetches the complete Lean repository into `.source-cache/lean4-4.34.0`, checks out exactly `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`, verifies the commit, applies the pinned Emscripten compatibility and typed-WASM ABI corrections, and then rebuilds the WASM provider.

Optional advanced overrides:

```text
PSC_LEAN_WASM_LEAN_SOURCE=/absolute/path/to/exact/lean4-source npm run build:wasm
PSC_LEAN_WASM_BUILD_ROOT=/absolute/path/to/build-dir npm run build:wasm
```

A custom Lean source directory is still reset/verified against the exact pinned commit. There is deliberately no branch-tip or `latest` fallback.

There is no `install`, `postinstall`, or `prepare` hook that compiles the provider. Rebuilding is always explicit.

Expected generated files are:

```text
wasm/pskernel-lean.cjs
wasm/pskernel-lean.wasm
```

inside the installed package, or under `packages/pskernel-lean-wasm/wasm/` in the monorepo.

### Typed-WASM ABI normalization

Lean 4.34 contains several native-runtime signatures whose dummy `IO.RealWorld` or `Unit` arguments do not exactly match the generated C call shape. Native ABIs tolerate these historical mismatches, but WebAssembly function types do not. `scripts/apply-wasm-abi.mjs` therefore performs exact, fail-closed rewrites only for the Emscripten build.

For runtime translation units that do not import Lean's C++ convenience aliases, ignored object arguments must use the public C ABI type `lean_obj_arg` from `lean/lean.h`. In particular, the Emscripten variants of `lean_internal_get_default_max_memory` and `lean_internal_get_default_max_heartbeat` use `lean_obj_arg`; using the shorter `obj_arg` alias is invalid in those files and is rejected by the real cross-build.

## Verification

Verify the source-carrying npm contract without rebuilding Lean:

```text
npm run verify:source
```

Runtime identity:

```text
node wasm/pskernel-lean.cjs --health
```

Kernel admission:

```text
printf '%s' "$REQUEST_JSON" | node wasm/pskernel-lean.cjs --check
```

The build is not considered successful from compilation alone. `--health` must identify protocol `pskernel-lean/1`, provider `lean4-cpp`, Lean 4.34.0 and the exact commit. The build script must also execute one accepted canonical admission and one deliberately ill-typed admission that returns `accepted: false` with `kernel-rejection`.

The host adapter and CI are fail-closed: a missing launcher, malformed output, identity mismatch, startup exception, or unexpected admission result fails the gate.

## Bootstrap isolation

This package is an external assurance provider. It must not be added to PSC2's minimal self-host dependency closure, and the PSC2 fixed-point build must continue to work without Lean, Emscripten, or this package installed.
