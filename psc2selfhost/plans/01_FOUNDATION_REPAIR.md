# PSC2 foundation repair implementation plan

> **For agentic workers:** use `superpowers:executing-plans` to implement this
> plan task by task when implementation is authorized. This document does not
> start execution or authorize unrelated kernel/PSC2 language work.

**Goal:** make this workspace's build graph and source-coverage reporting honest
and reproducible, then produce the evidence needed for the admission design.

**Architecture:** retain existing package roots. Register the embedded kernel
without mislabeling its current implementation profile; resolve package paths
consistently across Lean and generated hosts. Keep provider migration separate
from mechanical build repair.

**Tech stack:** existing Lean 4.34.0/Lake, Node scripts, npm workspaces,
TypeScript 5.8.3 and existing backend packages.

**Spec:** [architecture](../ARCHITECTURE.md), [governance](../GOVERNANCE.md),
[bootstrap](../BOOTSTRAP.md), [gate contract](../ACCEPTANCE_GATES.md).

## Global constraints

- No compiler/kernel semantic rewrite; no weakened source or admission gates.
- Keep current package roots and target-neutral IR.
- No handwritten `.ps` mirror or hand-edited generated outputs.
- Adding a manifest must not certify kernel portability that has not been tested.
- Missing kernel provider must fail explicitly; do not silently restore a TS
  fallback or claim codec success as admission.
- Each task must preserve existing supported TS/Rust/Wasm behavior.
- Commands below execute from `psc2selfhost/` unless explicitly stated.
  New test files/commands are proposals and do not exist at the baseline.

## Review focus

1. New semantic directories without metadata must fail discovery, not disappear.
2. Shared `Ps.Compiler` paths resolve identically from nested and project roots.
3. A declared kernel source profile mismatch is BLOCKED, never a false PASS.
4. An obsolete host-root fix must not change checking authority accidentally.
5. CI must exercise this directory, preserve exit codes and retain failure logs.

## Task 1: complete package discovery and source census

**Files:** create `packages/pskernel/package.json` and
`test/workspace-governance.test.mjs`; modify `scripts/check-workspace.mjs`,
`check-psc1-source.mjs`, `package.json`, and applicable Lake configuration.
Inspect nested `packages/pskernel/lakefile.toml` before wiring it.

**Interfaces:** consume existing `proofscript.sourceRoots`, `testRoots`,
`portable`, `outDir` metadata. Extend metadata with an explicit implementation
profile/classification if necessary, documenting it before acceptance. Produce
a complete inventory separating portable semantic, Lean-hosted semantic, host
and test roots. No implicit “manifest absent means host” classification.

- [ ] Add Node tests named `missingSemanticManifestFails`,
  `unclassifiedSemanticRootFails`, and `kernelIsIncludedInCensus`. Their assertions
  require nonzero failure for missing/unclassified metadata and visible kernel
  source/test coverage even before portable eligibility is achieved.
- [ ] Run `node --test test/workspace-governance.test.mjs`; establish the failing
  behavior before changing discovery.
- [ ] Register the kernel with honest metadata; enumerate all required modules
  and classify the current namespace/abbrev/partial/runtime constructs. Keep
  portable compiler guard strict. Report nonportable semantic closure separately
  as blocked rather than labeling it host IO to skip checking.
- [ ] Run workspace/source guards and the new test. Expected: package shape
  passes; source results state exactly which profile/closure passes or remains
  blocked. Do not require a misleading all-portable green for this task.
- [ ] Commit the discovery/census change and update STATUS with actual output.

## Task 2: consistent import-to-package resolution

**Files:** modify `scripts/bootstrap-project.mjs`,
`scripts/compile-with-generated.mjs`, `scripts/emit-project-with-generated.mjs`,
`host/src/Ps/Host/ProjectCompiler.lean`; create
`test/module-resolution.test.mjs`; extend `test/BootstrapTests.lean` and Lake
test roots only where needed. Inspect all other hardcoded package maps first.

**Interfaces:** preserve logical names and current package source roots. Every
host must map `Ps.BackendRust.*` and `Ps.BackendWasm.*` to their actual packages,
along with the existing sections. Kernel imports require the explicit separate
root/profile decided in Task 1; do not guess that `PSC1Kernel` is a `Ps` section.

- [ ] Add `rustAndWasmClosureResolve`, `nestedEntryResolvesSameGraph`,
  `unknownPackageFails`, and `ambiguousLeanPsModuleFails` tests. Exercise module
  collection without invoking Lean or writing generated output, using a small
  exported collector or equivalent read-only test hook.
- [ ] Run `node --test test/module-resolution.test.mjs`; confirm the Rust import
  regression fails against the baseline implementation.
- [ ] Update all corresponding maps or factor one shared JS host registry,
  retaining a parity check against the Lean resolver. Do not move logical module
  semantics into Node-specific lookup behavior.
- [ ] Run the Node regression and the applicable Lean module-resolution fixture
  under the pinned toolchain. Verify the actual compiler import closure resolves
  before translation. If a later source feature fails, record that new frontier.
- [ ] Commit the resolver repair with focused tests and updated status.

## Task 3: establish an honest Lean build baseline

**Files:** `lakefile.lean`, `host/src/Ps/Host/KernelBridge.lean.bak`,
`test/BridgeHostTests.lean`, host/compiler manifests; potentially a new adapter
file only after the provider design is fixed.

**Interfaces:** preserve the distinction between compiler check and real kernel
admission. Build repair must not promote the obsolete bridge by accident.

- [ ] Audit every declared Lake root and test import against actual files.
  Add a root-existence regression to the Node workspace test covering the
  missing `Ps.Host.KernelBridge` case.
- [ ] Decide explicitly whether to restore a labeled external TS bootstrap
  adapter or remove obsolete roots/tests from the seed build while leaving
  admission blocked. Record the selected temporary provider and trust profile;
  retain negative admission tests as pending required gates, not deleted claims.
- [ ] Make only the corresponding build-graph change. Do not implement a new
  unchecked success path to satisfy bridge tests.
- [ ] With pinned Lean installed, run `npm run build:lake` and
  `npm run test:lean`, retaining each exit status. Run additional declared IR,
  Rust and Wasm fixtures relevant to any changed shared interface; the default
  test list is not assumed exhaustive.
- [ ] Record all compiler errors in order. Fix mechanical integration issues
  within scope; if the first real semantic/source failure appears, preserve a
  minimal regression and hand it to M1/M2 rather than broadening this task.
- [ ] Commit with a statement of what is buildable and whether admission is
  still blocked. A green Lake build cannot close P2-ADMISSION.

## Task 4: scoped CI and first reproducible evidence bundle

**Files:** create repository-root `.github/workflows/psc2-selfhost.yml` and
`psc2selfhost/scripts/check-bootstrap-layout.mjs` if the preceding tests need a
dedicated entry point; update this workspace's `package.json` and STATUS.

**Interfaces:** CI runs the same workspace/closure checks locally available.
It records the exact source revision, toolchain and gate output. Existing
`selfhost/` workflows remain intact.

- [ ] Add a workflow path regression proving changes under `psc2selfhost/**`
  trigger its checks; include shared language/semantic contracts when relevant.
- [ ] Add workspace/census, Node regressions, pinned Lean build and relevant
  test steps with correct working directories. Keep source closure/admission
  failures visible; do not use `continue-on-error` to certify a required gate.
- [ ] Retain logs/evidence even on failure and distinguish unavailable runner,
  tool setup, source errors and semantic rejection.
- [ ] Execute the local equivalent and inspect a real workflow run when
  available. No allocated runner/zero executed steps means NOT RUN.
- [ ] Commit the workflow and evidence update; close only the demonstrated gates.

## Next design: M1 provider and checked handoff

After repair, write a bounded provider implementation plan using the actual
Core/kernel representations and census. It must define conversion, transactional
admission, environment binding, malformed-reply handling, checked artifact
construction and routing of every normal check/build/emit entry point.
Its fixture must compare the same valid and invalid admissions through embedded
kernel, independent TS checker and applicable pinned Lean oracle. Bind the final
accepted declarations to erasure. Do not treat restoring `.bak` as completion.

That design should reuse proven provider/replay components from inspected donor
branches where compatible, without merging their diagnostic/runtime assumptions
wholesale. The detailed API is intentionally not invented before this audit.
