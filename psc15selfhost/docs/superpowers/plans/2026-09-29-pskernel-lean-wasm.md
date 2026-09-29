# Lean WASM Kernel Provider Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and package `@proofscript/pskernel-lean-wasm@4.34.0` as a Node-consumable WebAssembly execution variant of the existing Lean 4.34 kernel provider.

**Architecture:** Reuse the existing `PsKernelLean` semantic modules unchanged and add only a WASM transport/loader layer. Build against the pinned Lean 4.34.0 source/runtime with a pinned Emscripten SDK, expose a bytes-in/bytes-out provider API, and prove semantic parity against `@proofscript/pskernel-lean@4.34.0` before considering browser support.

**Tech Stack:** Lean 4.34.0, Emscripten/emsdk, WebAssembly, Node.js 22, npm workspaces, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-29-pskernel-lean-wasm-design.md`

## Global Constraints

- Package name: `@proofscript/pskernel-lean-wasm`.
- Package version: `4.34.0`.
- Lean source commit: `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`.
- Provider protocol: `pskernel-lean/1`.
- Provider identity/profile: `lean4-cpp` / `lean4.34-core`.
- Initial Emscripten pin: `6.0.10`; replace only if the real compatibility build proves it unusable.
- Reuse `PsKernelLean.Error`, `Convert`, `Prelude`, `Protocol`, and `Admission`; do not fork semantics.
- `bootstrap:false`, `portable:false`; explicitly excluded from the first fixed-point closure.
- Node WASM first. Browser support is a separate milestone.
- Consumption must require no Lean/Lake/Emscripten installation and no runtime network fetch.

## Review Focus

- Unsupported/malformed canonical payload must fail closed rather than crash or return acceptance.
- WASM memory ownership must not leak or reuse freed result buffers across repeated checks.
- Provider identity must exactly match the native provider, including Lean commit/profile.
- Packed npm consumption must locate `.wasm` relative to the installed package rather than the source checkout.
- Bootstrap closure must reject accidental imports/dependencies on both native and WASM Lean providers.

---

### Task 1: Package and bootstrap-boundary contract

**Files:**
- Create: `packages/pskernel-lean-wasm/package.json`
- Create: `packages/pskernel-lean-wasm/index.mjs`
- Create: `packages/pskernel-lean-wasm/LEAN_SOURCE_PIN.json`
- Create: `packages/pskernel-lean-wasm/EMSCRIPTEN_PIN.json`
- Create/Test: `packages/pskernel-lean-wasm/host/package.test.mjs`
- Modify: `scripts/bootstrap-closure-contract-tests.mjs`
- Modify: `scripts/check-workspace.mjs` only if package enumeration needs it.

**Interfaces:**
- Produces npm identity `@proofscript/pskernel-lean-wasm@4.34.0` and public async API placeholders.
- Produces exact Lean/Emscripten metadata consumed by later build/loader tasks.

- [ ] Write the package-contract test asserting package name/version, pin values, `bootstrap:false`, `portable:false`, and bootstrap-closure exclusion.
- [ ] Run it and verify RED because the package does not exist.
- [ ] Add the minimal manifest/pin/public entry files.
- [ ] Extend bootstrap-closure contract to forbid `pskernel-lean-wasm`.
- [ ] Run package/workspace/bootstrap-closure tests and verify GREEN.
- [ ] Commit.

### Task 2: WASM API source without semantic duplication

**Files:**
- Create: `packages/pskernel-lean-wasm/provider/PsKernelLeanWasm/Api.lean`
- Create/Test: `packages/pskernel-lean-wasm/provider-test/PsKernelLeanWasmTests.lean`
- Modify: `lakefile.lean`

**Interfaces:**
- Consumes `PsKernelLean.Admission.admitCanonicalAdmissions` and existing provider JSON helpers/identity.
- Produces a transport-neutral Lean function that maps canonical-admission `String` to provider-result `String`; low-level export glue is allowed to wrap this function but may not reimplement checking.

- [ ] Add failing Lean tests for accepted, kernel-rejected, malformed, protocol-mismatch, and repeated-call cases.
- [ ] Run the target and verify RED for missing WASM API module.
- [ ] Implement the minimal reusable `checkCanonicalAdmissionsJson : String -> IO String` layer and export-facing wrapper.
- [ ] Run tests and verify GREEN under native Lean before Emscripten work begins.
- [ ] Commit.

### Task 3: Emscripten compatibility/build probe

**Files:**
- Create: `packages/pskernel-lean-wasm/scripts/build-wasm.sh`
- Create: `.github/workflows/psc2-lean-kernel-wasm.yml`
- Create/Test: `packages/pskernel-lean-wasm/scripts/build-contract.test.mjs`
- Update: `EMSCRIPTEN_PIN.json` only if compatibility evidence requires a different SDK.

**Interfaces:**
- Produces deterministic `dist/pskernel-lean.wasm` plus JS glue/module needed by Task 4.
- Records exact SDK version and build flags.

- [ ] Add a static workflow/build-contract test pinning exact Lean and Emscripten versions and forbidding `latest`/`tot` SDK aliases.
- [ ] Run RED before the build script/workflow exists.
- [ ] Add an Ubuntu Node-WASM workflow that installs exact emsdk, verifies `emcc --version`, and builds the provider through Lean's Emscripten-supported runtime closure.
- [ ] Execute CI. If Emscripten `6.0.10` fails because of a Lean-4.34 runtime incompatibility, diagnose the exact incompatibility and pin the nearest verified working SDK rather than adding permissive fallbacks.
- [ ] Make the build produce a real `.wasm` and deterministic JS glue, then verify both files are non-empty and no source-checkout absolute paths are embedded in runtime lookup.
- [ ] Commit the verified pin/build plumbing.

### Task 4: Node loader and WASM memory/API boundary

**Files:**
- Create: `packages/pskernel-lean-wasm/host/loader.mjs`
- Create/Test: `packages/pskernel-lean-wasm/host/loader.test.mjs`
- Modify: `packages/pskernel-lean-wasm/index.mjs`

**Interfaces:**
- Produces `createKernel(options?) -> Promise<Kernel>`.
- Produces top-level `checkCanonicalAdmissions(source, options?) -> Promise<KernelResult>`.
- `Kernel.checkCanonicalAdmissions(source)` returns the same semantic result object as native provider.

- [ ] Write RED tests for metadata, accepted/rejected payloads, non-string input, repeated checks, missing/corrupt WASM, and package-relative WASM resolution.
- [ ] Implement UTF-8/memory management around the exported low-level ABI.
- [ ] Parse and validate provider result identity exactly like the native adapter.
- [ ] Run Node loader tests against the real built WASM and verify GREEN.
- [ ] Commit.

### Task 5: Native-vs-WASM differential gate

**Files:**
- Create/Test: `packages/pskernel-lean-wasm/scripts/differential.test.mjs`
- Modify: `.github/workflows/psc2-lean-kernel-wasm.yml`

**Interfaces:**
- Consumes native `@proofscript/pskernel-lean` public API and WASM package public API.
- Produces a CI gate proving semantic parity for the shared provider protocol.

- [ ] Add fixtures for valid definition, type mismatch, malformed canonical JSON, unknown constant, protocol mismatch, and inductive admission.
- [ ] Assert native/WASM equality of protocol/provider/Lean identity/accepted/error kind/declaration index, preferring full JSON equality when stable.
- [ ] Run the differential suite and fix transport-only mismatches without changing semantic modules.
- [ ] Commit.

### Task 6: Publishable npm tarball and clean consumer

**Files:**
- Modify: `packages/pskernel-lean-wasm/package.json`
- Create/Test: `packages/pskernel-lean-wasm/scripts/packed-consumer.test.mjs`
- Create: `packages/pskernel-lean-wasm/README.md`
- Create: `packages/pskernel-lean-wasm/BUILDING.md`

**Interfaces:**
- Produces a self-contained npm tarball containing JS glue and `.wasm`.

- [ ] Add RED tarball-content assertions requiring package root API, JS loader/glue, `.wasm`, and both pin metadata files.
- [ ] Add a clean temporary Node consumer that installs the tarball and performs valid acceptance and kernel rejection with Lean/Lake/Emscripten unavailable.
- [ ] Update package `files`/exports until the packed consumer is GREEN.
- [ ] Document source build, exact pins, package API, Node-only milestone status, and browser non-claim.
- [ ] Commit.

### Task 7: Final verification and integration status

**Files:**
- Modify: `STATUS.md`
- Modify: `packages/pskernel-lean/INTEGRATION.md` only to document the sibling WASM provider; do not change native semantics.

**Interfaces:**
- Produces merge evidence for `psc2/pskernel-lean-wasm -> psc2/pskernel-lean-provider`.

- [ ] Run package/workspace/bootstrap-closure tests.
- [ ] Run existing native provider tests unchanged.
- [ ] Run WASM build, loader, differential, and packed-consumer tests from a fresh CI run.
- [ ] Verify no changes under copied `pskernel-lean/kernel`, `runtime`, or `util` source trees.
- [ ] Update status with exact successful SDK pin, artifact size, Node milestone, and remaining browser work.
- [ ] Merge into the native-provider branch only when all Node WASM gates are GREEN; defer merging provider work into `psc2/minimal-selfhost-psc15` until that base is GREEN and a fresh post-sync bootstrap/generated-compiler gate passes.