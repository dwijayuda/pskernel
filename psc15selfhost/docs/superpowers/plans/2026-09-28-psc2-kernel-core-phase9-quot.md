# PSC2 KernelCore Phase 9 Quot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a PSC1-self-hostable Quot declaration/bootstrap island plus the bounded `Quot.lift`/`Quot.ind` computation rule, without widening Phase-8 inductive trust.

**Architecture:** Add quotient declaration metadata to `Declaration.lean`, isolate bootstrap/shape validation in a new `Quot.lean`, then integrate one bounded Quot computation helper into `Reduce.lean`. Keep the environment linear and pure; no recursor framework, cache, replay, host `List`/`Option`, IO, unsafe implementation, or compiler cutover enters the trusted core.

**Tech Stack:** Lean 4.34.0, PSC1-subset `.lean`, KernelCore local carriers, Lake executables, npm assurance scripts, GitHub Actions.

**Spec:** `psc15selfhost/docs/superpowers/specs/2026-09-28-psc2-kernel-core-phase9-quot-design.md`

## Global Constraints

- All trusted Phase-9 source must pass the existing actual flattened PSC1 source/self-host gate unchanged.
- No `partial`, `unsafe`, `extern`, `implemented_by`, `IO`, `Lean.*`, `Std.*`, custom syntax/macros/elaborators, `mutual`, or host semantic `List`/`Option` storage in KernelCore.
- Keep the mature `PSC1Kernel` as differential oracle; do not replace or modify it for Phase 9.
- Keep `pskernel-core` outside the active compiler bootstrap closure.
- Do not implement general recursors, ordinary iota, recursive/mutual/nested inductives, positivity, projections, structure eta, or compiler cutover in this phase.
- Every semantic task follows RED -> observed failure -> minimal GREEN -> observed pass before the next semantic task.

## Review Focus

- A look-alike ordinary `Eq` constant must not satisfy the Quot prerequisite; only genuine `inductInfo`/`ctorInfo` does.
- Any one of the four reserved Quot names already declared must make first initialization fail without changing the caller environment.
- `quotInitialized = true` must make initialization idempotent rather than duplicate declarations or revalidate malformed later state.
- Quot reduction must remain residual for malformed/underapplied shapes and must not consume a wrong argument position.
- Explicit resource/budget paths must not fall back to default-resource wrappers during major-argument WHNF.

---

## File Structure

Create:

- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Quot.lean` — equality prerequisite validation, quotient declaration construction and initialization, bounded quotient-reduction shape helper if needed.
- `psc15selfhost/test/KernelCoreQuotMetadataTests.lean` — declaration metadata differential fixture.
- `psc15selfhost/test/KernelCoreQuotAdmissionParityTests.lean` — positive bootstrap parity fixture.
- `psc15selfhost/test/KernelCoreQuotRejectionTests.lean` — fail-closed prerequisite/collision matrix.
- `psc15selfhost/test/KernelCoreQuotReductionParityTests.lean` — bounded computation differential fixture.

Modify:

- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Declaration.lean` — Quot metadata and accessors.
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean` — aggregate export.
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Reduce.lean` — Quot computation integration only.
- `psc15selfhost/lakefile.lean` — Phase-9 test executables.
- `psc15selfhost/package.json` — Phase-9 aggregate assurance command.
- `.github/workflows/psc2-minimal-kernel.yml` — permanent Phase-9 gates/branch triggers after GREEN.
- optionally `.github/workflows/psc2-kernel-core-phase9-work.yml` — work-branch RED/GREEN execution while Phase 9 is in progress.

### Task 1: Quot declaration metadata

**Interfaces:**
- Consumes: `PsKernelCoreConstantBase`, `PsKernelCoreConstantInfo`, existing accessor functions from `Declaration.lean`.
- Produces: `PsKernelCoreQuotKind`, `PsKernelCoreQuotInfo`, `PsKernelCoreConstantInfo.quotInfo`, accessor/classification support.

- [ ] **Step 1: Write the failing metadata differential test**

Create `KernelCoreQuotMetadataTests.lean` importing `Ps.KernelCore.Declaration` and `PSC1Kernel.Declaration`. Construct all four reference/kernel quotient kinds and assert name/type/level accessors plus `isUnsafe=false`, `isPartial=false`, `isDefinition=false`, `deltaValue?=none`, `hints?=none`, `definition?=none`.

- [ ] **Step 2: Wire and run the test to verify RED**

Add a Lake executable `psc2_kernel_core_quot_metadata_tests` and work-branch workflow step. Push test/wiring only.

Expected: CI fails because `PsKernelCoreQuotKind`, `PsKernelCoreQuotInfo`, or `.quotInfo` does not exist. The failure must be semantic absence, not a typo or workflow error.

- [ ] **Step 3: Implement minimal Quot metadata**

In `Declaration.lean`, add the exact metadata and exhaustive accessor cases required by the spec. Do not add bootstrap logic yet.

- [ ] **Step 4: Run metadata fixture and existing declaration parity**

Expected: new metadata test PASS and existing declaration parity PASS.

- [ ] **Step 5: Run actual KernelCore PSC1 source profile**

Expected: PASS with the trusted module count increased only when a trusted source file is actually added.

### Task 2: Quot prerequisite validation and bootstrap

**Interfaces:**
- Consumes: Task-1 quotient metadata, Phase-8 genuine `inductInfo`/`ctorInfo`, `PsKernelCoreEnvironment`, local list/name/level/expr carriers.
- Produces: reserved Quot names, expected Eq/refl shape validation, quotient type constructors, `psKernelCoreAddQuot` (or `...WithResources` only if needed by existing conventions).

- [ ] **Step 1: Write positive admission parity fixture first**

Create `KernelCoreQuotAdmissionParityTests.lean`. Build/admit genuine Eq/Eq.refl through KernelCore Phase-8 APIs, initialize mature `PSC1Kernel` and KernelCore Quot environments, then compare the four stored declaration names, universe counts, types/kinds, environment size delta and `quotInitialized=true`. Include second-call idempotence and preservation of an unrelated declaration.

- [ ] **Step 2: Verify RED**

Wire/run only the new test before `Quot.lean` exists.

Expected: FAIL because Quot bootstrap API/module is missing.

- [ ] **Step 3: Implement `Ps.KernelCore.Quot` minimally**

Required public semantic functions/types:

```text
psKernelCoreQuotName
psKernelCoreQuotMkName
psKernelCoreQuotLiftName
psKernelCoreQuotIndName
psKernelCoreCheckEqForQuot
psKernelCoreAddQuot
```

Use direct closed de-Bruijn construction or a small PSC1-safe binder-closing helper; choose the smaller trusted implementation. Require genuine Phase-8 metadata. Add all four declarations only after prerequisite/collision checks succeed, then mark the returned environment initialized.

- [ ] **Step 4: Export Quot module and run positive parity**

Expected: PASS.

- [ ] **Step 5: Run source profile, Phase-8 aggregate, and full existing check**

Expected: PASS; no earlier behavior regresses.

### Task 3: Quot rejection/idempotence matrix

**Interfaces:**
- Consumes: Task-2 `psKernelCoreCheckEqForQuot` / `psKernelCoreAddQuot`.
- Produces: fail-closed evidence for all prerequisite/collision classes.

- [ ] **Step 1: Write failing rejection cases before any hardening change they require**

Create `KernelCoreQuotRejectionTests.lean` covering: missing Eq; ordinary axiom named Eq; wrong Eq universe arity; wrong ctor list; missing ctor; ctor wrong kind/parent; malformed Eq type; malformed refl type; collision at each reserved name; original environment size/flag/constants unchanged on every failure; idempotent return when already initialized.

- [ ] **Step 2: Run and classify RED cases**

Expected: any uncovered validation case fails specifically. Cases already correctly rejected may pass; each failing case must identify a missing contract, not test setup error.

- [ ] **Step 3: Add only missing fail-closed checks**

Keep all validation inside Quot bootstrap; do not broaden ordinary admission or Phase-8 inductive APIs.

- [ ] **Step 4: Run positive + negative Quot fixtures and source profile**

Expected: PASS.

### Task 4: Bounded Quot computation

**Interfaces:**
- Consumes: Task-2 reserved names/bootstrap, `psKernelCoreWhnfWithResources`, app-head/app-arg helpers, Phase-7 resource config.
- Produces: Quot reduction helper integrated into WHNF without general recursor machinery.

- [ ] **Step 1: Write the reduction differential fixture**

Create `KernelCoreQuotReductionParityTests.lean` covering lift, ind, WHNF of the major argument, residual uninitialized/underapplied/wrong-major cases, trailing argument reapplication, and a tiny-budget/configured-path regression.

- [ ] **Step 2: Verify RED**

Expected: initialized Quot eliminator application remains unreduced in KernelCore while mature `PSC1Kernel` reduces it.

- [ ] **Step 3: Implement minimal Quot reduction**

Add a small helper in `Reduce.lean` (or `Quot.lean` if it avoids cyclic imports) that:

```text
checks env.quotInitialized
recognizes lift/ind app head
uses mature argument positions (lift major=5, ind major=4, function/proof=3)
WHNFs the major with the same remaining budget/resources
requires Quot.mk with exactly 3 arguments
extracts representative arg 2
returns function/proof applied to representative
reapplies trailing args
```

Integrate before ordinary residual-app return, without implementing recursors/iota.

- [ ] **Step 4: Run reduction fixture plus Phase-3/5/7/8 aggregates**

Expected: PASS.

### Task 5: Permanent assurance and acceptance preparation

**Interfaces:**
- Consumes: all Phase-9 tests and implementation.
- Produces: permanent CI/aggregate gate and exact evidence head for later acceptance.

- [ ] **Step 1: Add `assurance:kernel-core:phase9`**

It must run the unchanged source profile; all Phase-9 fixtures; all semantic parity dependencies needed by Phase 9; and `report-kernel-core-size.mjs`.

- [ ] **Step 2: Add permanent Phase-9 workflow steps/branch triggers**

Do not delete or weaken earlier steps.

- [ ] **Step 3: Run exact-head permanent CI**

Expected: Phase-1 through Phase-9 aggregates, source profile, bootstrap isolation and `npm run check` all succeed on the same SHA.

- [ ] **Step 4: Scope review**

Compare the Phase-8 acceptance commit to the exact Phase-9 candidate head. Expected changed semantic surface: Quot metadata/module, bounded Reduce integration, Phase-9 fixtures and assurance wiring only.

- [ ] **Step 5: Prepare `PHASE9_ACCEPTANCE.md` only after exact green evidence exists**

Pin exact implementation SHA/run/job, allowed/non-claims, source module count and size reporter evidence. The acceptance commit itself must be documentation-only relative to the tested head.
