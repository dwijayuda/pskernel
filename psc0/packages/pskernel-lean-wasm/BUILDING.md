# Build the PSC0 v7.2 linear-memory Lean 4.35.0 kernel

**Source:** `leanprover/lean4` at
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc` (v4.35.0).
**Emscripten:** `6.0.9`. **Host:** x86_64 Linux with runnable i386 binaries.
**Output:** single-threaded wasm32 Emscripten C++ kernel plus Node launcher.

## Preferred GitHub Linux CI workflow

`.github/workflows/psc0-pskernel-lean-wasm-linear.yml` builds from pinned
sources, checks current PSC0 native provider, and then tests the Wasm binary
against it before staging the artifacts. Only the successful same-SHA workflow
is authorized to commit a prebuilt artifact and manifest to this feature branch.
The workflow also uploads both Wasm and launcher as a run artifact. Check that
the run is **green** before treating its bytes as qualified.

## Reproduce in a Linux GitHub runner

From the repository checkout with the exact 4.35 Lean toolchain on PATH:

```sh
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y build-essential cmake git clang pkg-config \
  gcc-multilib g++-multilib libc6-dev-i386 libstdc++-dev:i386 \
  libuv1-dev:i386 libssl-dev:i386
git clone --depth 1 https://github.com/emscripten-core/emsdk.git /tmp/emsdk
cd /tmp/emsdk
./emsdk install 6.0.9
./emsdk activate 6.0.9
source ./emsdk_env.sh
cd "$GITHUB_WORKSPACE"
cd psc0/v7-native
lake build pskernel_lean_wasm_native_ref
cd ..
node packages/pskernel-lean-wasm/scripts/test-host.mjs
PSC_LEAN_WASM_SOURCE_COMMIT="$(git rev-parse HEAD)" \
  bash packages/pskernel-lean-wasm/scripts/build-wasm.sh
node packages/pskernel-lean-wasm/scripts/check-differential.mjs \
  v7-native/.lake/build/bin/pskernel_lean_wasm_native_ref \
  packages/pskernel-lean-wasm/wasm/pskernel-lean.cjs
PSC_LEAN_WASM_SOURCE_COMMIT="$(git rev-parse HEAD)" \
  node packages/pskernel-lean-wasm/scripts/stage-prebuilt.mjs
node packages/pskernel-lean-wasm/scripts/verify-prebuilt.mjs
```

The build script explicitly sets `ELAN_TOOLCHAIN=leanprover/lean4:v4.35.0` so the repository-root 4.34 toolchain cannot leak into cross-compilation.

The script downloads only the pinned official Lean commit into
`psc0/packages/pskernel-lean-wasm/.wasm-build` (ignored); no archived
`study/lean4-4.34.0`, vendored PSC2 source, or host-architecture .olean may
enter the wasm32 closure.

It configures the official staged Lean build with a native 32-bit stage0
(`-m32`) and wasm32 stage1. Using installed x86_64 `lean --c` to emit
wasm32 provider code is **not supported**: platform constants and compact
literals must have target-width semantics. Emscripten supplies the runtime,
the complete C++ kernel, and link-time dependencies. It is not a Wasm-GC build.

The exact compatibility transformations in `scripts/apply-lean435-compat.mjs`
modify the ignored upstream source checkout only. They fail if a pinned source
pattern is missing or ambiguous; never apply old 4.34 patches blindly.

A successful result must pass:

- Lean version/hash checks and native same-source health.
- Source DAG planning using the current PSC0 packages (no vendoring).
- Full C++/runtime wasm32 link with nonempty .wasm and launcher.
- Wasm linear-memory validation and real Node execution.
- Native vs Wasm valid/invalid/error-category parity.
- Manifest hashes and bundling integrity.
- Additional Lean Arena/large-batch tests before any published release.

**Status:** No current-turn CI completion or binary availability is implied
by this document. Verify the Actions run and `PREBUILT_WASM_MANIFEST.json`
on the feature branch.

## Exact Lean 4.35.0 libuv fallback compatibility

The Linux run [#39122290519](https://github.com/dwijayuda/pskernel/actions/runs/39122290519) reached stage1 `leanrt` compilation and exposed a mismatched C++ fallback: `src/runtime/uv/system.h` declares `lean_uv_os_get_group(uint64_t gid)`, while the no-libuv implementation of `src/runtime/uv/system.cpp` previously defined it without the required argument. The patched C++ implementation retains the original unsupported-without-libuv behavior; only its parameter signature changes. This is **not** a kernel soundness or admission bypass.

The exact source patch applies only to the ignored pinned upstream checkout. The CI preflight now fetches the exact Lean commit, checks the complete set of guarded rewrites and their idempotence, and calls `scripts/verify-lean435-runtime.mjs` before the costly stage0/stage1 cross-build. The build repeats these checks after resetting and repatching the source checkout.
