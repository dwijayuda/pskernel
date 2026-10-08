# PSC2 Minimal Self-Host Implementation Plan

**Date:** 2026-09-27

**Branch:** `psc2/minimal-selfhost-psc15`

**Spec / authority:** `psc15selfhost/ARCHITECTURE.md`, `psc15selfhost/WORKSTREAM_COORDINATION.md`, and the Post-PSC1 platform rules summarized there.

## Goal

Close the smallest stable PSC2 self-host fixed point inside `psc15selfhost/` while keeping the handwritten portable implementation in the PSC1-compatible `.lean` subset and using official Lean 4 + Lake as the bootstrap host.

The first self-host uses TypeScript/JavaScript only. Rust, direct Wasm, the project extension package, the mature kernel reference, and `pskernel-core` remain outside the fixed-point dependency closure. Keep those extension/reference packages in the workspace unless concrete evidence shows they are redundant; minimality is measured by the bootstrap import/dependency closure, not by deleting useful non-bootstrap packages.

## Non-negotiable invariants

- Modify only `psc15selfhost/**` on this branch.
- Do not develop `packages/pskernel-core/**` in this workstream.
- `.lean` is the only handwritten portable compiler source during bootstrap; generated `.ps` is a parity/self-host artifact.
- Portable bootstrap modules remain inside the PSC1 source-profile gate.
- `packages/compiler` is backend-neutral and must not import `Ps.Backend*`.
- `packages/bootstrap` is the tiny composition root that selects the TypeScript bootstrap backend.
- Rust/Wasm/project/kernel packages must not enter the bootstrap closure transitively through imports or package dependencies.
- Do not call an admission-ready artifact `CheckedCore`. Real `CheckedCore` begins only after a real kernel provider admits it.
- Erasure/VerifiedIR must remain behind the strongest admission boundary actually available. When a real kernel provider is integrated later, only that provider may create the checked artifact consumed by erasure.
- Do not weaken tests or soundness gates to obtain a fixed point.

## Current baseline already implemented

The branch already has:

- `implementationProfile = PSC1` and `acceptedLanguageProfile = PSC2-bootstrap` in `psconfig.json`;
- backend-neutral `packages/compiler`;
- `packages/backend-ts/src/Ps/BackendTs/Compiler.lean` as the bootstrap backend adapter;
- `packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean` as the self-host composition root;
- `PsCompilerAdmissionReadyModule`, canonical-admission validation, and VerifiedIR production behind that boundary;
- an import-closure-driven bootstrap generator (`scripts/bootstrap-project.mjs`), so the generated self-host workspace is not a copy of the whole repository;
- `check:source:bootstrap`, layout, bootstrap-closure, IR-neutrality, bootstrap tests, self-host source comparison, and exact generated-TypeScript fixed-point comparison;
- explicit workstream separation keeping `pskernel-core` development on `psc2/pskernel-core`.

Do not redo those changes. The remaining work is to make the fixed-point claim mechanically precise, reduce accidental closure, and obtain reproducible evidence.

---

## Task 1 — Freeze a machine-readable bootstrap closure contract

**Purpose:** Make "smallest self-host" measurable and prevent future optional packages from entering the fixed point silently.

**Files:**
- Modify: `psc15selfhost/scripts/check-bootstrap-closure.mjs`
- Create: `psc15selfhost/scripts/bootstrap-closure-contract.mjs`
- Create: `psc15selfhost/scripts/bootstrap-closure-contract-tests.mjs`
- Modify: `psc15selfhost/package.json`

**RED:**
1. Add tests that feed synthetic module/package dependency graphs to the closure checker and require rejection of `project`, `backend-rust`, `backend-wasm`, `pskernel`, and `pskernel-core`.
2. Add a test requiring the canonical allowed bootstrap package set to be exactly the intended set, not merely a superset check.
3. Run the contract test and confirm it fails before the shared contract module exists.

**GREEN:**
1. Extract the allowed/forbidden bootstrap package policy into one reusable module.
2. Make `check-bootstrap-closure.mjs` consume that policy instead of duplicating it.
3. Add `test:bootstrap-closure` and include it in `test:bootstrap` or `bootstrap:lean` before Lake build.

**Acceptance:**
- Synthetic forbidden dependency/import fixtures fail closed.
- Current real bootstrap closure passes.
- There is one authoritative bootstrap package policy.

## Task 2 — Make bootstrap manifests self-describing and tamper-evident

**Purpose:** Ensure a successful fixed point proves the exact source closure being reproduced, not merely equality of whatever files happened to be listed.

**Files:**
- Modify: `psc15selfhost/scripts/bootstrap-project.mjs`
- Modify: `psc15selfhost/scripts/reemit-project-with-generated.mjs`
- Modify: `psc15selfhost/scripts/compare-source-workspaces.mjs`
- Create: `psc15selfhost/scripts/bootstrap-manifest-tests.mjs`
- Modify: `psc15selfhost/package.json`

**RED:**
1. Add fixture tests requiring manifest validation to reject duplicate paths, unsorted/noncanonical path sets, mismatched `sourceCount`, paths outside the workspace, non-`.ps` source entries, and closure-fingerprint mismatch.
2. Confirm tests fail with the current permissive manifest handling.

**GREEN:**
1. Canonicalize the generated file list.
2. Record a deterministic `closureSha256` over entry + ordered relative paths + source bytes.
3. Recompute and verify that fingerprint before self-host re-emission/comparison.
4. Preserve the fingerprint in the next-generation manifest only after successful canonical re-emission.

**Acceptance:**
- Manifest corruption cannot yield a false fixed-point PASS.
- Bootstrap and next-generation workspaces identify the same exact closure by fingerprint.

## Task 3 — Tighten the semantic ownership gate around admission, erasure, and backend emission

**Purpose:** Prevent later refactors from reintroducing a direct elaborated-Core → erasure/backend path outside the semantic compiler boundary.

**Files:**
- Create: `psc15selfhost/scripts/check-semantic-boundaries.mjs`
- Create: `psc15selfhost/scripts/check-semantic-boundaries-tests.mjs`
- Modify as needed: `psc15selfhost/packages/compiler/src/Ps/Compiler/Api.lean`
- Modify as needed: `psc15selfhost/packages/backend-ts/src/Ps/BackendTs/Compiler.lean`
- Modify: `psc15selfhost/package.json`

**RED:**
1. Synthetic fixture: a backend directly calling `psEraseCoreModule` must be rejected.
2. Synthetic fixture: semantic compiler importing `Ps.BackendTs`/`Ps.BackendRust`/`Ps.BackendWasm` must be rejected.
3. Synthetic fixture: a non-erasure/non-compiler owner directly invoking low-level erasure on arbitrary elaborated declarations must be rejected.

**GREEN:**
1. Encode ownership rules in the boundary checker.
2. Keep `PsCompilerAdmissionReadyModule` naming until a real kernel provider exists.
3. If production code still exposes an avoidable direct-erasure route, remove/narrow it while preserving source → prepare → validated admission-ready → VerifiedIR → backend composition.
4. Do **not** introduce a fake `CheckedCore` or identity kernel provider merely to satisfy naming.

**Acceptance:**
- Backend packages consume VerifiedIR/semantic compiler services, not raw elaborated declarations via low-level erasure.
- Compiler remains backend-neutral.
- Current boundary remains honest about not yet being real kernel admission.

## Task 4 — Reduce the active fixed-point command surface

**Purpose:** Make the shortest authoritative self-host path obvious and separate it from optional regression/extension assurance.

**Files:**
- Modify: `psc15selfhost/package.json`
- Modify: `psc15selfhost/packages/cli/bin/psc.mjs`
- Modify as needed: `psc15selfhost/scripts/selfhost-generation.mjs`
- Modify: `psc15selfhost/STATUS.md`

**RED:**
1. Add a small script-level test that asserts the authoritative fixed-point command depends only on bootstrap gates, TS/JS generation, source comparison, and compiler comparison.
2. Require extension suites (Rust/Wasm/kernel-core) not to be part of `fixed-point`.

**GREEN:**
1. Keep one canonical command (`npm run fixed-point`) for minimum PSC2 closure.
2. Keep broader `npm run check` as release/regression assurance, not a self-host prerequisite.
3. Remove redundant script aliases only when no documentation or CLI surface relies on them; otherwise mark them compatibility aliases.

**Acceptance:**
- A reader can identify the minimal fixed-point path from `package.json` without knowing the history of PSC1.5.
- Optional backends never block the fixed point.

## Task 5 — Prove the composition root is minimal

**Purpose:** Remove only imports/files that are demonstrably not needed by the self-host compiler artifact.

**Files:**
- Test first: add/update `psc15selfhost/test/MinimalSelfHostTests.lean` and/or a script test around import closure.
- Modify only if tests prove safe: `psc15selfhost/packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean`
- Modify only if proven redundant: bootstrap-only wrapper files inside `psc15selfhost/`.

**RED / experiment:**
1. Record the exact generated import-closure package/file counts from the bootstrap manifest.
2. Add assertions that required public compiler exports remain available from the composition root.
3. For each candidate root import/wrapper, remove one at a time and require the bootstrap source-generation + TS compiler surface tests to remain green.

**GREEN:**
- Keep every import required for emitted/self-host runtime definitions.
- Delete only imports/wrappers with concrete green evidence.

**Acceptance:**
- No speculative deletion.
- Final composition root is the smallest proven root, not merely the shortest-looking file.

## Task 6 — Fixed-point evidence and truthful status

**Purpose:** Close the branch only on real reproducible evidence.

**Required command sequence:**

```text
npm run check:workspace
npm run check:source:bootstrap
npm run check:layout
npm run check:bootstrap-closure
npm run check:ir-neutrality
npm run build:lean
npm run test:bootstrap
npm run fixed-point
```

Then run broader assurance separately:

```text
npm run check
```

**Files:**
- Modify: `psc15selfhost/STATUS.md`
- Create: `psc15selfhost/FIXED_POINT_EVIDENCE.md` only after the commands genuinely run.

**Acceptance:**
- Capture compiler/source closure hashes, source count, toolchain identity, and exact command outcomes.
- Do not write `FIXED_POINT_EVIDENCE.md` claiming PASS if execution evidence is unavailable.
- If a gate fails, fix the root cause with RED → GREEN tests; do not weaken the gate.

## Task 7 — Kernel-provider cutover contract (design seam only)

**Purpose:** Prepare the next integration milestone without pulling the kernel workstream into this branch prematurely.

**Files:**
- Modify: `psc15selfhost/ARCHITECTURE.md`
- Create: `psc15selfhost/docs/KERNEL_PROVIDER_CUTOVER.md`
- Production compiler code changes only if a seam is missing and can be added without selecting a kernel implementation.

**Contract:**

```text
source
  -> parse / resolve / elaborate
  -> Core
  -> AdmissionReady
  -> KernelProvider.admit
  -> CheckedModule
  -> erasure
  -> VerifiedIR
  -> backend
```

The provider API must make it impossible for a backend to manufacture `CheckedModule`. `pskernel-core`, a mature independent kernel, or another reference provider may be integrated later, but this plan does not choose or implement that provider.

**Acceptance:**
- No false claim that AdmissionReady is CheckedCore.
- Integration criteria for `psc2/pskernel-core` are explicit and independently testable.

---

## Review focus

At final review, explicitly check:

1. Does any optional package enter the import or manifest dependency closure?
2. Can any backend call low-level erasure on arbitrary elaborated declarations?
3. Can manifest tampering or stale files produce a false source fixed point?
4. Does any handwritten portable module violate PSC1 source restrictions?
5. Has any host/Node/Lean-specific functionality leaked into the portable compiler?
6. Are Rust/Wasm/kernel-core tests clearly assurance/extensions rather than fixed-point blockers?
7. Does the branch claim only what was actually executed and verified?

## Definition of done

The minimum PSC2 self-host is done when the canonical PSC1-compatible Lean source is accepted by official Lean 4, generates the exact minimal canonical `.ps` closure, produces a JavaScript compiler, that compiler reproduces the same canonical source closure and compiler output at the next generation, all bootstrap boundary gates pass, and the status/evidence documents record the real fingerprints and command results.

Broader PSC2 features are deliberately **not** part of this definition of done. They grow afterward as libraries, frontend desugarings, Meta/tactic facilities, controlled plugins, FFI/InterfaceIR, and additional backends according to the Post-PSC1 extension ladder.
