# Lean Kernel Source Distribution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ship auditable Lean 4.34 kernel source and its upstream license inside both `@proofscript/pskernel-lean` and `@proofscript/pskernel-lean-wasm`, and make the WASM npm tarball carry the source/build inputs needed for an explicit rebuild.

**Architecture:** Treat pinned Lean `src/kernel/` as an immutable audit snapshot, identified by its upstream Git tree SHA and Lean commit. Publish provider source separately from the upstream kernel so licensing remains clear. Normal consumers use prebuilts; explicit rebuilds may fetch the full Lean source at the exact pinned commit.

**Tech Stack:** npm packages, Lean 4.34.0, Node.js, Bash, Emscripten 6.0.9, GitHub Actions.

**Spec:** `psc15selfhost/docs/superpowers/specs/2026-09-28-pskernel-lean-provider-design.md`

## Global Constraints

- Lean version is exactly `4.34.0`.
- Lean commit is exactly `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`.
- Upstream kernel source is exactly Lean `src/kernel/`, tree `636837af92156cf17226e56106f08eb553bfb961`.
- Upstream Lean license is Apache-2.0 and must be copied verbatim from the pinned source snapshot.
- `pskernel-lean` and `pskernel-lean-wasm` remain `bootstrap:false` and `portable:false`.
- No install hook may compile Lean or WASM.

## Review Focus

- npm tarballs must actually include provider source, kernel source, license, and source manifest.
- The kernel audit snapshot must remain byte-identical to the pinned upstream Git tree.
- Package-level licensing must not incorrectly imply all ProofScript package code is Apache-2.0.
- Standalone WASM rebuild must fail closed on the wrong Lean/Emscripten version.
- Prebuilt execution remains the default; source rebuild is explicit only.

---

### Task 1: Kernel source + license snapshot

**Files:**
- Add to both packages: `kernel/`, `LEAN_LICENSE`, `KERNEL_SOURCE_MANIFEST.json`
- Modify package manifests/tests.

- [ ] Add a RED package contract requiring the three audit artifacts and exact Lean/kernel identities.
- [ ] Reuse the exact upstream `src/kernel/` Git tree in both package directories.
- [ ] Copy the exact upstream Lean Apache-2.0 license and add a machine-readable source manifest.
- [ ] Publish `provider/`, `kernel/`, `LEAN_LICENSE`, and `KERNEL_SOURCE_MANIFEST.json` from both npm packages.
- [ ] Run package contract tests.

### Task 2: WASM source/build distribution

**Files:**
- Modify: `packages/pskernel-lean-wasm/package.json`
- Modify: `packages/pskernel-lean-wasm/scripts/build-wasm.sh`
- Add: package-local ProofScript source snapshot under `source/proofscript/`
- Modify: `README.md`, `BUILDING.md`, packed-consumer tests.

- [ ] Publish `provider/`, `scripts/`, `patches/`, `source/`, and the audit artifacts.
- [ ] Make `build-wasm.sh` prefer monorepo sources when available and otherwise consume package-local ProofScript source.
- [ ] When the monorepo Lean study snapshot is absent, fetch the exact Lean commit into a package-local build cache before compiling.
- [ ] Add `npm run build:wasm`; do not add install/postinstall compilation.
- [ ] Extend `npm pack` consumer checks to assert the source/license/build files are present.

### Task 3: Distribution verification

- [ ] Verify native npm package contract.
- [ ] Verify WASM package contract and packed-consumer contract.
- [ ] Verify bootstrap closure still forbids both external kernel providers.
- [ ] Verify the current real WASM build/parity workflow independently; do not claim runtime green without CI evidence.
