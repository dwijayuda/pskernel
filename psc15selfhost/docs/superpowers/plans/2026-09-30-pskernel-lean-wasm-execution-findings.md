# Lean WASM Kernel Provider — Execution Findings

Date: 2026-09-30

This note records implementation evidence discovered while executing
`2026-09-29-pskernel-lean-wasm.md`. It overrides build-path assumptions in that
plan where the assumptions have been disproven by CI.

## Stable semantic boundary

The WASM package remains a transport/execution sibling of
`@proofscript/pskernel-lean`, not a new kernel implementation. It reuses the
same `PsKernelLean` conversion, prelude, protocol, admission, and response
modules and accepts the same canonical admissions v2 payload.

Package identity remains:

- `@proofscript/pskernel-lean-wasm@4.34.0`
- Lean `4.34.0`
- Lean commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`
- protocol `pskernel-lean/1`
- provider `lean4-cpp`
- Emscripten `6.0.9`

## Disproven build path 1: runnable native i386 stage0

Lean's upstream full-WASM recipe uses a native 32-bit stage0 to keep generated
`.olean` platform assumptions aligned with wasm32. We implemented that shape,
but the resulting i386 stage0 executable was not semantically usable in this
repository/toolchain environment: even a trivial source definition aborted
with `unknown parser category 'level'`.

This was reproduced before any ProofScript provider source was involved.
Therefore the i386 stage0 executable is not used by the Node kernel-provider
milestone.

This does **not** claim that Lean's upstream 32-bit bootstrap architecture is
wrong in general; only that the concrete i386 executable produced in this
pipeline cannot be used as the provider front-end.

## Disproven build path 2: current provider C + frozen stage0 libraries

A second route used the exact Lean 4.34 host compiler only to emit provider C,
then linked that C against Lean's frozen stage0 libraries cross-compiled by
Emscripten. This route produced `.wasm` and Node glue, but runtime execution
failed.

The linker exposed direct ABI mismatches between frozen stage0 definitions and
current 4.34 generated C, including differing arities for functions such as:

- `lean_io_create_tempfile`
- `lean_io_create_tempdir`
- `lean_internal_get_default_max_memory`
- `lean_internal_get_default_max_heartbeat`
- compacted-region helpers

Typed WebAssembly makes these mismatches explicit. Mixing current-generated C
with the frozen bootstrap library ABI is therefore forbidden.

## Current Node-milestone build path

The current implementation configures Lean 4.34's **current `src/` tree** as
`STAGE=1` under the pinned Emscripten toolchain:

```text
exact native Lean 4.34 frontend
        |
        | PREV_STAGE / elaboration + C emission only
        v
current Lean 4.34 source
        |
        | Emscripten 6.0.9
        v
current wasm32 runtime/kernel/Init/Std/Lean libraries
        |
        +--- exact same host Lean emits PSC provider C
        |
        v
provider C compiled by current-source wasm32 leanc
        |
        v
Node WASM provider
```

The important invariant is ABI consistency: provider generated C and all
runtime/kernel/library objects come from the same Lean 4.34 source semantics,
rather than combining current generated C with frozen stage0 libraries.

The exact native host Lean contributes no host object or host runtime library
to the shipped artifact.

## Scope of the x86_64 previous-stage assumption

Using the exact x86_64 Lean 4.34 installation as the frontend is accepted only
for the **Node kernel-provider milestone**, and only after the following gates
are green:

1. real current-source wasm build;
2. `--health` execution;
3. accepted canonical admission through the real WASM artifact;
4. real Lean-kernel rejection through the real WASM artifact;
5. native-vs-WASM differential parity on shared fixtures;
6. packed npm consumer without Lean/Lake/Emscripten available at runtime.

This is not a claim that the resulting build is a general target-correct Lean
wasm32 compiler/toolchain. The provider's semantic conversion layer does not
model machine-width primitives, and differential checking against the exact
native Lean 4.34 provider is the required evidence for this narrower kernel
use case.

If target-width-dependent kernel/provider behavior is introduced later, this
assumption must be revisited.

## Emscripten compatibility fixes

The pinned Lean 4.34 source requires narrow Emscripten compatibility patches
for libuv fallback ABI declarations. The pipeline patches both current and
frozen source snapshots for reproducibility, although the production Node
provider build now uses current `src/` only.

Confirmed fixes include:

- `lean_uv_event_loop_alive` returns `uint8_t`;
- `lean_uv_os_get_group` accepts its `uint64_t gid` argument.

`MULTI_THREAD=OFF` is intentionally **not** part of the Node milestone. Lean
4.34 has separate single-thread build issues (including the `std::adopt_lock_t`
header issue and unconditional Emscripten pthread flags). Those belong to the
later browser/non-shared-memory milestone.

## Final link findings

Lean's build-only `leanc.sh` contributes compiler/platform flags and the Lean
library search path but not the full static library closure. The provider link
therefore mirrors Lean 4.34's Emscripten static closure:

```text
-lleancpp -lInit -lStd -lLean -lnodefs.js -lleanrt -lstdc++
```

The final link is driven through `em++`, because the Lean kernel/runtime closure
contains C++ symbols. Generated provider C compilation remains through
`leanc.sh`.

The generated Node launcher is `.cjs`, not `.js`, because the npm package is
ESM (`"type": "module"`) while Emscripten's current Node launcher uses
CommonJS.

## Canonical smoke fixture correction

The actual native/WASM decoder consumes canonical admissions v2 in this shape:

```json
{
  "format": "proofscript-checked-admissions",
  "version": 2,
  "admissions": []
}
```

The obsolete experimental shape using `ps-canonical-admissions-v2` and
`declarations` is forbidden from runtime smoke tests.

Current build smoke uses the same compact declaration codec as the native
provider tests: one valid `Nat := 1` definition and one `Nat := Sort 0`
definition that must reach the Lean kernel and be rejected as
`kernel-rejection`.

## Remaining Node-WASM gates

Do not call the package distribution-ready until all of these are green on one
fresh branch head:

- current-source real WASM build;
- health execution;
- accepted admission smoke;
- kernel-rejection smoke;
- native-vs-WASM differential suite;
- `npm pack` contents check;
- clean tarball consumer using the bundled `.cjs`/`.wasm` only;
- bootstrap-closure exclusion unchanged;
- public README updated to describe the current-source build rather than the
  abandoned frozen-stage0 route.

Browser support remains a separate later milestone.
