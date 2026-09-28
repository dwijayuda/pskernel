# PSC2 Lean Kernel Prebuilt Distribution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bundle and verify native Lean 4.34 kernel-provider executables for Linux x64/arm64, macOS x64/arm64, and Windows x64 directly inside `@proofscript/pskernel-lean@4.34.0`, with automatic package-local runtime resolution and no consumer Lean/Lake requirement.

**Architecture:** Keep the existing native provider and `checkCanonicalAdmissions()` API unchanged at the semantic boundary. Add a focused prebuilt-manifest/resolver layer, native GitHub Actions build matrix, deterministic assembly tooling, and packed-tarball platform tests. `@proofscript/pskernel-lean` stays an optional host dependency and remains forbidden from the portable PSC2 fixed-point closure.

**Tech Stack:** Lean 4.34.0 + Lake, Node.js ESM, SHA-256 via `node:crypto`, npm pack/install, GitHub Actions native hosted runners.

**Spec:** `psc15selfhost/docs/superpowers/specs/2026-09-28-pskernel-lean-prebuilt-distribution-design.md`

## Global Constraints

- Package identity is exactly `@proofscript/pskernel-lean@4.34.0`.
- Provider protocol is exactly `pskernel-lean/1`; provider identity is `lean4-cpp`; profile is `lean4.34-core`.
- Lean semantic baseline is exactly `4.34.0`, source commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`.
- Supported target keys are exactly `linux-x64`, `linux-arm64`, `darwin-x64`, `darwin-arm64`, `win32-x64`.
- Windows ARM64 is unsupported and must fail closed unless an explicit `PSC_LEAN_KERNEL_PROVIDER_BIN` override is supplied.
- No install/postinstall download, build, or network fetch is allowed for package consumers.
- Bundled artifacts live under `packages/pskernel-lean/prebuilt/<target>/`; `PREBUILT_MANIFEST.json` is the authoritative digest/index file.
- Every bundled binary must be natively built and executed on its own target runner; no architecture emulation counts as distribution evidence.
- Runtime resolution order is: explicit env override -> valid bundled prebuilt -> source-checkout Lake binary development fallback -> hard failure.
- A bundled binary must pass SHA-256 validation before spawn.
- `packages/compiler`, `packages/backend-ts`, and `packages/bootstrap` must not depend on `@proofscript/pskernel-lean`; the existing bootstrap-closure prohibition remains.
- Do not alter the copied upstream `packages/pskernel-lean/kernel`, `runtime`, or `util` trees for distribution work.
- A final merge is prohibited until this branch is synchronized with a GREEN `psc2/minimal-selfhost-psc15` revision and all merge gates are rerun after synchronization.

## Review Focus

- **Package installed outside the monorepo:** bundled path resolution must be based on `import.meta.url`, never caller CWD; Task 4 installs the actual tarball into a fresh temporary project and executes it.
- **Tampered or stale executable:** checksum mismatch must fail before `spawnSync`; Task 1 and Task 4 include corruption tests.
- **Unsupported/unknown Node tuple:** unsupported tuple must list supported targets and never silently choose another architecture; Task 1 covers `win32-arm64` and an unknown tuple.
- **Source checkout before/after prebuilts exist:** bundled artifact takes precedence, but a developer Lake binary remains a controlled fallback when the package is visibly a source checkout; Task 1 covers precedence and fallback.
- **Generated distribution commit accidentally self-loops or bypasses verification:** prebuilt refresh is `workflow_dispatch` only and the write job commits only after five artifacts, manifest, tarball, and package tests pass; Task 5 covers workflow contract checks.

---

## File Structure

### Create

- `psc15selfhost/packages/pskernel-lean/host/prebuilt.mjs` — target-key mapping, manifest loading/validation, package-local path resolution, SHA-256 verification, source-checkout detection.
- `psc15selfhost/packages/pskernel-lean/host/prebuilt.test.mjs` — resolver/manifest/digest unit contracts using temporary fixture directories.
- `psc15selfhost/packages/pskernel-lean/PREBUILT_MANIFEST.json` — generated authoritative index after five real artifacts are assembled.
- `psc15selfhost/packages/pskernel-lean/scripts/stage-native-prebuilt.mjs` — stage current native executable plus provenance metadata for one target.
- `psc15selfhost/packages/pskernel-lean/scripts/stage-native-prebuilt.test.mjs` — staging/provenance contract tests with fixture executable bytes and mocked metadata input.
- `psc15selfhost/packages/pskernel-lean/scripts/assemble-prebuilt.mjs` — validate exactly five staged target artifacts, copy binaries into package layout, compute manifest deterministically.
- `psc15selfhost/packages/pskernel-lean/scripts/assemble-prebuilt.test.mjs` — deterministic assembly tests over fixture artifacts including missing/duplicate/mismatched targets.
- `psc15selfhost/packages/pskernel-lean/scripts/packed-consumer.test.mjs` — install a supplied packed tarball into a fresh consumer and execute the package API without Lean/Lake.
- `.github/workflows/psc2-lean-kernel-prebuilt.yml` — manual native five-target matrix, artifact assembly, package verification, and distribution commit.
- `psc15selfhost/packages/pskernel-lean/PREBUILT.md` — generated-artifact policy, refresh procedure, target matrix, provenance/merge expectations.

### Modify

- `psc15selfhost/packages/pskernel-lean/host/node-provider.mjs` — use the prebuilt resolver and verify bundled digest before spawning; preserve public semantic API.
- `psc15selfhost/packages/pskernel-lean/host/node-provider.test.mjs` — package-resolver integration and explicit-path bypass tests.
- `psc15selfhost/packages/pskernel-lean/host/npm-package.test.mjs` — require prebuilt manifest/files in the package surface.
- `psc15selfhost/packages/pskernel-lean/package.json` — publish `PREBUILT_MANIFEST.json` and `prebuilt/`; export prebuilt metadata if useful to consumers.
- `psc15selfhost/scripts/pskernel-lean-package-consumer.test.mjs` — require the actual packed package to expose bundled artifacts rather than only JS metadata.
- `.github/workflows/psc2-lean-kernel-provider.yml` — verify committed prebuilts/package surface on Linux x64 while leaving workflow permissions read-only.
- `psc15selfhost/packages/pskernel-lean/README.md` — normal npm use requires no Lean/Lake; document supported targets and override behavior.
- `psc15selfhost/packages/pskernel-lean/BUILDING.md` — document local prebuilt staging and CI refresh path.
- `psc15selfhost/packages/pskernel-lean/INTEGRATION.md` — state bundled-provider resolution/trust behavior.
- `psc15selfhost/packages/pskernel-lean/NPM_PACKAGE.md` — package contents/versioning policy including future `@proofscript/pskernel-lean-wasm@4.34.0`.

### Generated binary files

The manual prebuilt workflow eventually adds exactly:

- `psc15selfhost/packages/pskernel-lean/prebuilt/linux-x64/psc2_lean_kernel_provider`
- `psc15selfhost/packages/pskernel-lean/prebuilt/linux-arm64/psc2_lean_kernel_provider`
- `psc15selfhost/packages/pskernel-lean/prebuilt/darwin-x64/psc2_lean_kernel_provider`
- `psc15selfhost/packages/pskernel-lean/prebuilt/darwin-arm64/psc2_lean_kernel_provider`
- `psc15selfhost/packages/pskernel-lean/prebuilt/win32-x64/psc2_lean_kernel_provider.exe`

---

### Task 1: Prebuilt Manifest and Runtime Resolver

**Files:**
- Create: `psc15selfhost/packages/pskernel-lean/host/prebuilt.mjs`
- Create: `psc15selfhost/packages/pskernel-lean/host/prebuilt.test.mjs`
- Modify: `psc15selfhost/packages/pskernel-lean/host/node-provider.mjs`
- Modify: `psc15selfhost/packages/pskernel-lean/host/node-provider.test.mjs`

**Interfaces:**
- Consumes: package-relative `LEAN_SOURCE_PIN.json`; later `PREBUILT_MANIFEST.json` matching the spec schema.
- Produces:
  - `supportedLeanKernelProviderTargets : readonly string[]`
  - `leanKernelProviderTargetKey({platform, arch}) -> string`
  - `loadLeanKernelPrebuiltManifest({packageRoot?}) -> object`
  - `resolveLeanKernelProviderBinary({platform?, arch?, env?, packageRoot?, allowSourceCheckoutFallback?}) -> {binaryPath, source, target?}` where `source` is `override | bundled | source-checkout`.
  - `verifyLeanKernelPrebuiltBinary({binaryPath, target, manifest}) -> void`
  - Existing `defaultLeanKernelProviderBinary(...) -> string` remains public and delegates to the resolver.
  - Existing `checkCanonicalAdmissions(source, options?)` remains public and automatically verifies a bundled digest before spawn.

- [ ] **Step 1: Write resolver RED tests**

Add assertions for all five exact target mappings, `win32-arm64` hard failure, an unknown tuple hard failure, env override precedence, package-relative bundled path, bundled-over-Lake precedence, source-checkout fallback only when its candidate exists, and SHA-256 corruption rejection.

- [ ] **Step 2: Run RED tests**

Run: `cd psc15selfhost && node packages/pskernel-lean/host/prebuilt.test.mjs`

Expected: FAIL because `host/prebuilt.mjs` does not exist.

- [ ] **Step 3: Implement `host/prebuilt.mjs`**

Use `node:crypto`, `node:fs`, `node:path`, and `import.meta.url`. Parse the package-owned manifest synchronously because `checkCanonicalAdmissions()` is synchronous. Validate exact package/protocol/provider/version/commit/profile identity before accepting a manifest entry. Reject path traversal outside package root.

- [ ] **Step 4: Wire `node-provider.mjs` to the resolver**

When `options.binaryPath` is explicitly supplied, preserve the existing intentional custom-binary behavior. Otherwise resolve through env/bundled/source-checkout policy; run digest verification only for `source === 'bundled'` before `spawnSync`.

- [ ] **Step 5: Run resolver and existing provider tests**

Run:
`cd psc15selfhost && node packages/pskernel-lean/host/prebuilt.test.mjs && node packages/pskernel-lean/host/node-provider.test.mjs`

Expected: both PASS with existing positive/negative kernel behavior unchanged.

- [ ] **Step 6: Commit**

Commit message: `feat(psc2): resolve bundled Lean kernel providers`

---

### Task 2: Native Artifact Staging and Provenance

**Files:**
- Create: `psc15selfhost/packages/pskernel-lean/scripts/stage-native-prebuilt.mjs`
- Create: `psc15selfhost/packages/pskernel-lean/scripts/stage-native-prebuilt.test.mjs`

**Interfaces:**
- Consumes: target key, provider executable path, repository source commit, actual `lean --githash`, actual provider `--health` JSON.
- Produces one deterministic staging directory containing:
  - native executable with target-correct filename;
  - `artifact.json` containing `target`, `sourceCommit`, `packageVersion`, protocol/provider/profile, Lean version/commit, executable filename, SHA-256, and byte size.

- [ ] **Step 1: Write staging RED tests**

Use temporary fixture bytes. Assert exact SHA-256/size, target-correct executable filename, exact provider identity fields, and rejection for unsupported target, wrong Lean commit, health mismatch, or missing executable.

- [ ] **Step 2: Run RED tests**

Run: `cd psc15selfhost && node packages/pskernel-lean/scripts/stage-native-prebuilt.test.mjs`

Expected: FAIL because staging script does not exist.

- [ ] **Step 3: Implement staging script**

CLI signature:
`node stage-native-prebuilt.mjs --target <key> --binary <path> --source-commit <sha> --lean-githash <sha> --health-json <json-or-file> --out <dir>`.

The command must refuse a target/filename mismatch and must copy only the executable plus `artifact.json`.

- [ ] **Step 4: Run staging tests**

Expected: PASS.

- [ ] **Step 5: Commit**

Commit message: `build(psc2): stage Lean kernel native artifacts`

---

### Task 3: Deterministic Five-Artifact Assembly

**Files:**
- Create: `psc15selfhost/packages/pskernel-lean/scripts/assemble-prebuilt.mjs`
- Create: `psc15selfhost/packages/pskernel-lean/scripts/assemble-prebuilt.test.mjs`
- Generated later: `psc15selfhost/packages/pskernel-lean/PREBUILT_MANIFEST.json`

**Interfaces:**
- Consumes: directory containing five staged target artifact directories from Task 2.
- Produces: deterministic `prebuilt/<target>/...` tree and `PREBUILT_MANIFEST.json` exactly matching the design schema.

- [ ] **Step 1: Write assembly RED tests**

Fixture tests require: exact five-target set; deterministic sorted manifest; duplicate target rejection; missing target rejection; unexpected sixth target rejection; mismatched package/Lean/provider metadata rejection; checksum mismatch rejection; safe package-relative manifest paths.

- [ ] **Step 2: Run RED tests**

Run: `cd psc15selfhost && node packages/pskernel-lean/scripts/assemble-prebuilt.test.mjs`

Expected: FAIL because assembly script does not exist.

- [ ] **Step 3: Implement assembly script**

CLI signature:
`node assemble-prebuilt.mjs --artifacts <dir> --package-root <dir>`.

Refuse to partially update the package: validate all artifacts first, prepare output in a temporary directory, then replace `prebuilt/` and `PREBUILT_MANIFEST.json` only after the full set validates.

- [ ] **Step 4: Run assembly tests**

Expected: PASS.

- [ ] **Step 5: Commit**

Commit message: `build(psc2): assemble Lean kernel prebuilt manifest`

---

### Task 4: Publishable npm Tarball Contract

**Files:**
- Modify: `psc15selfhost/packages/pskernel-lean/package.json`
- Modify: `psc15selfhost/packages/pskernel-lean/host/npm-package.test.mjs`
- Modify: `psc15selfhost/scripts/pskernel-lean-package-consumer.test.mjs`
- Create: `psc15selfhost/packages/pskernel-lean/scripts/packed-consumer.test.mjs`

**Interfaces:**
- Consumes: real assembled `PREBUILT_MANIFEST.json` and `prebuilt/` files from Task 3/Task 5.
- Produces: npm tarball containing public JS runtime files, pins/manifest, and exactly five native binaries; clean consumer execution using package-local binary with no Lean/Lake invocation.

- [ ] **Step 1: Write package-surface RED assertions**

Require `package.json.files` to contain `PREBUILT_MANIFEST.json` and `prebuilt/`. `npm pack --json` file listing must contain exactly five provider executable paths and must not contain `.lake/`, copied Lean toolchain files, `kernel/`, `runtime/`, or `util/`.

- [ ] **Step 2: Add packed consumer execution contract**

`packed-consumer.test.mjs` accepts `--tarball <path>` and on the current platform installs it into a fresh temp project, unsets `PSC_LEAN_KERNEL_PROVIDER_BIN`, imports `@proofscript/pskernel-lean`, requires resolver source `bundled`, then runs valid and kernel-invalid admissions and checks `accepted:true` / `accepted:false + kernel-rejection`.

- [ ] **Step 3: Run tests before package-file update**

Expected: RED because the current package `files` list does not publish manifest/prebuilt artifacts.

- [ ] **Step 4: Update package surface**

Add only the required manifest/prebuilt assets; preserve `private:false`, package version `4.34.0`, existing public exports, and side-effect-free installation.

- [ ] **Step 5: Run npm/package tests using a fixture assembled tree**

Run the package contract locally/CI using deterministic fixture artifacts until real matrix artifacts are committed.

- [ ] **Step 6: Commit**

Commit message: `feat(psc2): publish Lean kernel prebuilt assets`

---

### Task 5: Native Five-Target GitHub Actions Build and Assembly Workflow

**Files:**
- Create: `.github/workflows/psc2-lean-kernel-prebuilt.yml`
- Modify as needed: `.github/workflows/psc2-lean-kernel-provider.yml`

**Interfaces:**
- Consumes: Task 2 staging CLI, Task 3 assembly CLI, Task 4 packed-consumer test.
- Produces: five natively tested workflow artifacts and, after successful assembly verification, a repository commit containing the real five binaries and generated manifest.

- [ ] **Step 1: Add a workflow-contract RED test/check**

Add repository-side assertions (in an existing package test or focused script) that require the prebuilt workflow to be `workflow_dispatch`-driven, use exactly these native runner/target pairs, and reserve `contents: write` for the final assembly job:

`ubuntu-24.04 -> linux-x64`
`ubuntu-24.04-arm -> linux-arm64`
`macos-15-intel -> darwin-x64`
`macos-15 -> darwin-arm64`
`windows-2025 -> win32-x64`.

- [ ] **Step 2: Create native matrix build job**

Use `actions/checkout`, `leanprover/lean-action@v1` with `lake-package-directory: psc15selfhost` and its automatic build/test/lint disabled, then Node 22. The nested Lake directory is explicit because the repository root has no authoritative `lean-toolchain`; the action must read `psc15selfhost/lean-toolchain`. Each matrix job verifies the exact Lean githash before build, runs `lake build psc2_lean_kernel_provider` from `psc15selfhost`, directly executes `--health`, positive admission, and negative admission, stages through Task 2, inspects dynamic dependencies (`ldd`, `otool -L`, Windows equivalent/PowerShell file/runtime inspection), then uploads the staged artifact.

- [ ] **Step 3: Add standalone-runtime proof per matrix target**

Copy the staged executable to a temp directory and invoke it directly by path, not `lake exe`; remove project `.lake/build/bin` from the exercised path and ensure provider behavior remains correct. Reject a target if extra non-system shared libraries are required but not staged package-locally.

- [ ] **Step 4: Add assembly job**

Download exactly five artifacts, run Task 3 assembly, run manifest/digest tests, `npm pack`, and package-surface tests. The job may push only after all validations pass. Commit message is exactly `build(psc2): bundle pskernel-lean 4.34.0 native providers`.

- [ ] **Step 5: Prevent recursive write loops**

Keep the prebuilt workflow manual (`workflow_dispatch`) rather than push-triggered. Generated commit may trigger the read-only provider verification workflow but cannot retrigger prebuilt assembly.

- [ ] **Step 6: Run the manual workflow and inspect all five matrix results**

Expected: five build jobs PASS, assembly PASS, one generated distribution commit added to `psc2/pskernel-lean-provider`.

- [ ] **Step 7: Commit workflow source before generated binary commit**

Commit message: `ci(psc2): build Lean kernel providers on five native targets`

---

### Task 6: Verify Real Committed Prebuilts and Packed Tarballs on Every Target

**Files:**
- Modify: `.github/workflows/psc2-lean-kernel-provider.yml`
- Modify: `psc15selfhost/packages/pskernel-lean/host/npm-package.test.mjs`
- Modify if necessary: `psc15selfhost/packages/pskernel-lean/scripts/packed-consumer.test.mjs`

**Interfaces:**
- Consumes: committed binaries/manifest from Task 5.
- Produces: continuous read-only verification that repository and npm package artifacts are usable and untampered.

- [ ] **Step 1: Add manifest/repository binary contract to normal provider tests**

Recompute all five SHA-256 values and require exact agreement with `PREBUILT_MANIFEST.json`; verify no unexpected sixth target exists.

- [ ] **Step 2: Add packed-consumer five-target verification matrix**

On the same five native runner labels, `npm pack` the package, install the `.tgz` into a fresh consumer, unset provider override, and run Task 4's packed consumer test. This job must not install Lean/Lake because it is specifically proving package runtime independence.

- [ ] **Step 3: Keep Linux x64 generated-compiler integration**

Run the real generated PSC2 compiler/CLI smoke with the bundled package path. Explicitly unset `PSC_LEAN_KERNEL_PROVIDER_BIN` and assert resolver source is bundled before `psc check --kernel lean434` and `psc build --kernel lean434`.

- [ ] **Step 4: Run normal provider workflow**

Expected: provider semantics, manifest/digest, five packed consumers, Linux real generated compiler smoke, and bootstrap-isolation stages all green except any clearly identified unrelated moving-base RED gate.

- [ ] **Step 5: Commit**

Commit message: `test(psc2): verify bundled Lean kernel providers`

---

### Task 7: Distribution Documentation and Merge Readiness

**Files:**
- Create: `psc15selfhost/packages/pskernel-lean/PREBUILT.md`
- Modify: `psc15selfhost/packages/pskernel-lean/README.md`
- Modify: `psc15selfhost/packages/pskernel-lean/BUILDING.md`
- Modify: `psc15selfhost/packages/pskernel-lean/INTEGRATION.md`
- Modify: `psc15selfhost/packages/pskernel-lean/NPM_PACKAGE.md`

**Interfaces:**
- Consumes: final real package/runtime/workflow behavior from Tasks 1-6.
- Produces: exact user/developer instructions and merge criteria; no new runtime API.

- [ ] **Step 1: Document ordinary npm use**

State that supported consumers of `@proofscript/pskernel-lean@4.34.0` do not install Lean/Lake and that the package automatically chooses its bundled native provider.

- [ ] **Step 2: Document target matrix and unsupported behavior**

List the exact five targets and explicit Windows ARM64 non-support; document `PSC_LEAN_KERNEL_PROVIDER_BIN` only as an intentional override.

- [ ] **Step 3: Document reproducible refresh/provenance**

Explain manual prebuilt workflow, exact Lean pin, generated manifest/digests, distribution commit, lack of signing/notarization in this milestone, and future `@proofscript/pskernel-lean-wasm@4.34.0` separation.

- [ ] **Step 4: Synchronize with the latest GREEN base**

Do not merge an intentionally RED base experiment. Find a `psc2/minimal-selfhost-psc15` revision where its own fixed-point/self-host gates are green, merge/rebase that revision into the provider branch, resolve only real conflicts, and do not weaken either branch's tests.

- [ ] **Step 5: Run final verification after synchronization**

Required evidence:

- all five native build targets green;
- all five installed-tarball consumers green with no Lean/Lake;
- manifest SHA-256 verification green;
- provider semantic positive/negative tests green;
- `psc check --kernel lean434` through bundled package green;
- accepted gated build emits JS and map; rejected gated build emits nothing;
- bootstrap isolation green;
- real generated compiler smoke green;
- base fixed-point/self-host gates green;
- `git diff`/compare shows no distribution edits under copied `kernel/`, `runtime/`, or `util/` trees.

- [ ] **Step 6: Run `superpowers:verification-before-completion` and `superpowers:requesting-code-review`**

Do not report merge readiness until fresh evidence from the final synchronized HEAD is available.

- [ ] **Step 7: Commit docs/readiness changes**

Commit message: `docs(psc2): document Lean kernel prebuilt distribution`

---

## Merge Decision

Merge `psc2/pskernel-lean-provider` into `psc2/minimal-selfhost-psc15` immediately after Task 7's final synchronized verification and code review are green. Do **not** wait for `@proofscript/pskernel-lean-wasm`; WASM is a separate follow-up milestone. Do **not** merge merely because the five binaries exist if the current base or generated-compiler smoke remains red.
