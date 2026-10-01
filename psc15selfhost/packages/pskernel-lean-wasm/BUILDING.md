# Building the PSC2 Lean WASM provider

`@proofscript/pskernel-lean-wasm` is pinned to Lean 4.34.0 commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b` and Emscripten 6.0.9. Do not substitute another Lean or Emscripten revision when producing the assurance artifact.

## Architecture

The build configures Lean from its top-level staged CMake project. The installed x86_64 Lean 4.34.0 toolchain is used for exact pin checks only; it must not emit provider C intended for wasm32. A freshly built, runnable native i386 stage0 is the host Lean C emitter. Stage1 uses Emscripten to rebuild the runtime, kernel and standard libraries from Lean 4.34.0's current `src/` tree. No native host object or library is linked into the WebAssembly artifact.

Stage0 is a C-only bootstrap and is not an installed `.olean` sysroot. Following Lean's `src/lean.mk.in`, the build creates empty `Init/`, `Std/` and `Lean/` output directories in the future stage1 sysroot so dependency enumeration can resolve package roots before any `.olean` files exist. No placeholder or host `.olean` files are installed. With `LEAN_PATH` restricted to that target sysroot, the build first requires `stage0/bin/lean --deps src/Lean.lean` to succeed, then builds stage1's `make_stdlib`, `leanrt`, and `leancpp_1` targets. Provider imports resolve against the wasm32-compatible stage1 `.olean` sysroot; native i386 stage0 emits their C, and stage1's `leanc.sh` compiles it to WebAssembly. The final kernel-only link excludes the stock global initializer and preserves the provider's generated import initialization graph.

This split is intentional. The frozen stage0 generated-C snapshot contains bootstrap ABI assumptions that are tolerated by native builds but conflict with WebAssembly's typed function signatures. Linking current provider-generated C against that frozen stage0 closure is therefore forbidden.

The npm package carries the exact ProofScript semantic source closure used by the provider under `source/proofscript/`. It also carries the exact upstream Lean `src/kernel/` snapshot under `kernel/` for audit, together with `LEAN_LICENSE` and `KERNEL_SOURCE_MANIFEST.json`. A complete Lean source checkout is larger and is fetched only when an explicit rebuild needs it.

## Prerequisites

The build expects:

- exact Lean 4.34.0 / commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b` on `PATH`;
- Emscripten 6.0.9 (`emcc`, `em++`, and `emar`);
- Clang (`clang`, `clang++`), Git, CMake, Make, Node.js, and standard Unix build tools;
- an x86_64 Linux host capable of building and running i386 executables, with `gcc-multilib`, `g++-multilib`, `libuv1-dev:i386`, `libssl-dev:i386`, and `pkgconf:i386`;
- `/usr/bin/i386-linux-gnu-pkg-config`; `objcopy` is also required by the scalar-literal regression.

CI installs these prerequisites before invoking the package build. Native stage0 uses Lean's `STAGE0_LEAN_EXTRA_CXX_FLAGS` and `STAGE0_LEANC_OPTS` with `-m32 -msse2 -mfpmath=sse`. Do not replace that plumbing with global `STAGE0_CMAKE_C_FLAGS` or `STAGE0_CMAKE_CXX_FLAGS`.

## Build in the pskernel checkout

From `psc15selfhost/` run:

```bash
PSC_LEAN_WASM_SOURCE_COMMIT="$(git rev-parse HEAD)" \
  npm --prefix packages/pskernel-lean-wasm run build:kernel
npm --prefix packages/pskernel-lean-wasm run verify:prebuilt
```

`build:kernel` is the package-uniform alias for `build:wasm`. Both execute the same pinned build and manifest generation.

The `build:wasm` command runs `scripts/build-wasm.sh` and then `scripts/write-prebuilt-manifest.mjs`. The build uses the live sibling PSC semantic sources and the checked-in `study/lean4-4.34.0` tree. Calling the shell script directly does not generate the manifest; generate and verify it before invoking the default Node API or packing the package.

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
PREBUILT_WASM_MANIFEST.json
```

relative to the package root, including `packages/pskernel-lean-wasm/` in the monorepo. The manifest records the launcher/module sizes and SHA-256 digests, exact toolchain identities, and source identifier. `PSC_LEAN_WASM_SOURCE_COMMIT` overrides the source identifier; CI otherwise uses `GITHUB_SHA`, and a standalone rebuild defaults to `package-local-source`. This metadata is an integrity/traceability record, not a signed provenance attestation.

### Typed-WASM ABI normalization

Lean 4.34 contains several native-runtime signatures whose dummy `IO.RealWorld` or `Unit` arguments do not exactly match the generated C call shape. Native ABIs tolerate these historical mismatches, but WebAssembly function types do not. `scripts/apply-wasm-abi.mjs` therefore performs exact, fail-closed runtime-signature rewrites guarded by `LEAN_EMSCRIPTEN`.

The same script corrects `LEAN_SCALAR_PTR_LITERAL` in both runtime headers to select its layout by `UINTPTR_MAX == UINT32_MAX`. Native i386 stage0, like wasm32, must store all eight scalar bytes in two pointer-sized slots. Testing only `LEAN_EMSCRIPTEN` truncated compact Name hashes in native i386 bootstrap initialization. This width correction does not define Emscripten runtime behavior for native stage0.

For runtime translation units that do not import Lean's C++ convenience aliases, ignored object arguments must use the public C ABI type `lean_obj_arg` from `lean/lean.h`. In particular, the Emscripten variants of `lean_internal_get_default_max_memory` and `lean_internal_get_default_max_heartbeat` use `lean_obj_arg`; using the shorter `obj_arg` alias is invalid in those files and is rejected by the real cross-build.

## Verification

Verify the source-carrying npm contract without rebuilding Lean:

```text
npm run verify:source
```

Verify bundled artifact integrity after building:

```text
npm run verify:prebuilt
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

The host adapter and CI are fail-closed: a missing launcher, malformed output, identity mismatch, startup exception, or unexpected admission result fails the gate. Completion also requires native/WASM differential parity and a fresh npm install of the packed tarball, including health, acceptance, and an actual kernel rejection. Host-mock tests and a successful link are not substitutes for those runtime gates.

## Bootstrap isolation

This package is an external assurance provider. It must not be added to PSC2's minimal self-host dependency closure, and the PSC2 fixed-point build must continue to work without Lean, Emscripten, or this package installed.


## Checked-in prebuilt

The package distribution carries `wasm/pskernel-lean.cjs`, `wasm/pskernel-lean.wasm`, and `PREBUILT_WASM_MANIFEST.json`. The committed prebuilt is promoted only from a successful full WASM workflow whose runtime acceptance, genuine kernel rejection, native/WASM differential parity, manifest verification, and fresh packed npm consumer have all passed.

`PROOFSCRIPT_SOURCE_MANIFEST.json` independently identifies the exact `source/proofscript/` Git tree used for package-local source rebuilds.
