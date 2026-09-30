# PSC2 KernelCore Phase 13 CheckedCore Shadow Provider Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a non-authoritative compiler-side KernelCore shadow checker for the bounded ordinary-definition/theorem bootstrap surface while leaving the existing PsEnvironment → erasure → VerifiedIR path unchanged.

**Architecture:** Add `Ps.Compiler.KernelShadow` outside the KernelCore TCB. It structurally transports closed compiler Core names/levels/expressions, projects the current bootstrap prelude as explicit opaque assumptions, and asks existing KernelCore admission to validate supported module-local definitions/theorems. `Ps.Compiler.Api` wraps this lower-level checker after the existing prepared-artifact integrity check; no existing compile API calls the shadow path implicitly.

**Tech Stack:** Lean 4.34.0, PSC1-subset/self-hostable KernelCore, existing `PsCompiler`/`PsEnvironment`/`PsKernelCore` Lean libraries, Node 22/npm assurance scripts, GitHub Actions.

**Spec:** `psc15selfhost/docs/superpowers/specs/2026-09-30-psc2-kernel-core-phase13-checkedcore-shadow-design.md`

## Global Constraints

- Base execution from accepted Phase-12 documentation head `b33e63ed6df2ad10a4a350b19af504fca45655f2` through the reviewed Phase-13 plan lineage.
- Phase 13 is shadow-only. KernelCore must not become the authoritative compiler provider in this phase.
- `Ps.Compiler.KernelShadow` is outside the KernelCore TCB; do not add compiler/elaborator transport logic under `packages/pskernel-core`.
- The bootstrap prelude is an explicit opaque assumption boundary, not a KernelCore-certification claim.
- Module-local `definitionDecl` and `theoremDecl` are the only supported shadow declaration kinds in Phase 13.
- `axiomDecl`, `partialDecl`, `opaqueDecl`, `inductiveDecl`, `constructorDecl`, and `recursorDecl` fail closed in the shadow checker.
- Do not fabricate recursor rules or weaken Phase-12 recursor validation to make compiler integration easier.
- `psCompilerEnvironmentFromPrepared`, `psCompilerVerifiedIrFromPrepared`, erasure, and backend compilation semantics remain unchanged.
- The existing `canonicalAdmissions` integrity check runs before any prepared-module shadow result is returned.
- KernelCore trusted source should remain 23 PSC1-subset/self-host-checkable modules unless a separately justified semantic defect is discovered.
- Any unexpected required change under `packages/pskernel-core` is a scope escalation: stop, document the semantic defect, and review it independently before proceeding.
- Lean toolchain remains `leanprover/lean4:v4.34.0`; CI Node remains 22.
- Do not merge Phase 13 automatically; finish with acceptance evidence and an integration PR/handoff.

## Review Focus

1. **Prelude projection contains a closedness defect** — if a projected prelude type contains an expression/universe metavariable or free variable, transport must fail with the shadow transport error instead of inserting a malformed assumption.
2. **Projection expressions need missing semantic metadata** — transport may succeed structurally, but KernelCore rejection must remain visible as `kernelRejected`; normal compiler/VerifiedIR output must still succeed because the shadow path is non-authoritative.
3. **Duplicate prelude headers** — assumption projection must reject duplicate names rather than silently replace them.
4. **Forged prepared artifact** — `canonicalAdmissions` mismatch must return the compiler-layer prepared-integrity error before transport/prelude/kernel checking starts.
5. **Cross-declaration dependency** — two source-order definitions where the second references the first must both pass and report `checkedDeclarations = 2`; the same reference without the first declaration must fail as an unknown KernelCore constant.

---

## Execution Branch

At implementation start, create an isolated execution branch:

```text
psc2/kernel-core-phase13-checkedcore-shadow-work
```

from the final reviewed Phase-13 plan commit. Do not write production code on the planning branch.

## File Structure

### Create

- `psc15selfhost/packages/compiler/src/Ps/Compiler/KernelShadow.lean` — compiler-side transport, prelude assumption projection, supported declaration admission, pure shadow error/report types.
- `psc15selfhost/test/CompilerKernelShadowTests.lean` — source-level positive matrix and sequential-declaration behavior.
- `psc15selfhost/test/CompilerKernelShadowRejectionTests.lean` — transport, unsupported declaration, duplicate, unknown constant, kernel mismatch, and prepared-integrity rejection matrix.
- `psc15selfhost/test/CompilerKernelShadowNoninterferenceTests.lean` — shadow-only/noninterference and backend-output regression.
- `.github/workflows/psc2-kernel-core-phase13-work.yml` — focused Phase-13 TDD/regression workflow.
- `.github/workflows/psc2-kernel-core-phase13-acceptance.yml` — exact-head permanent assurance/full-regression/fixed-point gate.
- `psc15selfhost/docs/continuity/PHASE13_ACCEPTANCE.md` — created only after all executable acceptance gates are green.

### Modify

- `psc15selfhost/packages/compiler/src/Ps/Compiler/Api.lean` — import `KernelShadow`, define API-layer error wrapper, expose additive prepared/elaborated/source shadow entry points.
- `psc15selfhost/package.json` — add `assurance:kernel-core:phase13` without changing Phase 1–12 scripts.

### Explicitly do not modify unless a genuine semantic defect is independently proven

- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/**`
- `psc15selfhost/packages/erasure/**`
- backend implementation packages
- compiler existing authoritative `VerifiedIR` functions

---

### Task 1: Establish the Phase-13 RED source-level boundary

**Files:**
- Create: `psc15selfhost/test/CompilerKernelShadowTests.lean`
- Create: `.github/workflows/psc2-kernel-core-phase13-work.yml`

**Interfaces:**
- Consumes existing `Ps.Compiler.Api` source preparation APIs.
- Produces a RED contract requiring `psCompilerKernelShadowCheckSource` and `PsCompilerKernelShadowReport.checkedDeclarations`.

- [ ] **Step 1: Write the failing minimal source test**

In `CompilerKernelShadowTests.lean`, import `Ps.Compiler.Api` and add a helper that calls the not-yet-existing API on:

```lean
def answer : Nat := 42
```

Required assertion:

```text
PsCompilerSourceKind.lean
-> shadow success
-> checkedDeclarations == 1
```

`main` must print exactly:

```text
PSC2_KERNEL_CORE_PHASE13_SHADOW_MINIMAL: PASS
```

when the contract is satisfied.

- [ ] **Step 2: Add the focused work workflow as test infrastructure only**

The workflow must trigger on `psc2/kernel-core-phase13-checkedcore-shadow-work`, install Lean 4.34.0 + Node 22, build `PsKernelCore PsCompiler`, then run:

```bash
cd psc15selfhost
lake env lean --run test/CompilerKernelShadowTests.lean
```

No production Phase-13 module exists yet.

- [ ] **Step 3: Run/observe RED**

Expected: dependencies build, then the fixture fails because `psCompilerKernelShadowCheckSource` / its shadow result types do not exist. Reject any RED caused by missing build dependencies, malformed source syntax, or unrelated imports.

- [ ] **Step 4: Commit the valid RED fixture/harness**

Suggested commit:

```text
test(pskernel-core): add Phase 13 shadow-provider RED fixture
```

---

### Task 2: Implement structural transport, prelude assumptions, and the minimal source GREEN

**Files:**
- Create: `psc15selfhost/packages/compiler/src/Ps/Compiler/KernelShadow.lean`
- Modify: `psc15selfhost/packages/compiler/src/Ps/Compiler/Api.lean`
- Test: `psc15selfhost/test/CompilerKernelShadowTests.lean`

**Interfaces:**
- Consumes: `PsName`, `PsLevel`, `PsExpr`, `PsDeclaration`, `psBootstrapPreludeEnvironment`, existing KernelCore declaration/environment/admission APIs.
- Produces:

```lean
inductive PsCompilerKernelShadowError where
  | universeMetavariable
  | freeVariable
  | expressionMetavariable
  | unsupportedDeclaration
  | duplicatePreludeAssumption
  | kernelRejected (message : String)

structure PsCompilerKernelShadowReport where
  checkedDeclarations : Nat

inductive PsCompilerKernelShadowApiError where
  | compiler (error : PsCompilerError)
  | shadow (error : PsCompilerKernelShadowError)
```

Lower-level adapter/checker functions in `Ps.Compiler.KernelShadow`:

```lean
def psCompilerKernelShadowName
    (name : PsName) : PsKernelCoreName

def psCompilerKernelShadowLevel
    (level : PsLevel) :
    Except PsCompilerKernelShadowError PsKernelCoreLevel

def psCompilerKernelShadowExpr
    (expr : PsExpr) :
    Except PsCompilerKernelShadowError PsKernelCoreExpr

def psCompilerKernelShadowAssumptionEnvironment
    (declarations : List PsDeclaration) :
    Except PsCompilerKernelShadowError PsKernelCoreEnvironment

def psCompilerKernelShadowPreludeEnvironment :
    Except PsCompilerKernelShadowError PsKernelCoreEnvironment

def psCompilerKernelShadowCheckDeclarations
    (declarations : List PsDeclaration) :
    Except PsCompilerKernelShadowError PsCompilerKernelShadowReport
```

API-layer functions in `Ps.Compiler.Api`:

```lean
def psCompilerKernelShadowCheckPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerKernelShadowApiError PsCompilerKernelShadowReport

def psCompilerKernelShadowCheckElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerKernelShadowApiError PsCompilerKernelShadowReport

def psCompilerKernelShadowCheckSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerKernelShadowApiError PsCompilerKernelShadowReport
```

- [ ] **Step 1: Implement deterministic structural transport**

Pin the following mappings exactly:

```text
PsName anonymous/str/num -> KernelCore anonymous/str/num
PsLevel zero/succ/max/imax/param -> matching KernelCore level
PsLevel.mvar -> universeMetavariable
PsBinderInfo explicit/implicit/strictImplicit/instanceImplicit
  -> default/implicit/strictImplicit/instImplicit
PsExpr bvar/sortE/constE/app/lam/forallE/letE/lit/proj
  -> matching KernelCore expression
PsExpr.fvar -> freeVariable
PsExpr.mvar -> expressionMetavariable
compiler letE -> KernelCore letE with nondep := false
```

Use structural list conversion preserving order. Do not use JSON as the transport.

- [ ] **Step 2: Implement the prelude assumption projector**

`psCompilerKernelShadowAssumptionEnvironment` must convert only each declaration header (`name`, `levelParams`, `type`) into `PsKernelCoreConstantInfo.axiomInfo` with `isUnsafe := false` and add it with duplicate detection.

`psCompilerKernelShadowPreludeEnvironment` calls that helper on `psBootstrapPreludeEnvironment.declarations`.

Do not run full admission on the prelude assumptions; this is the explicit Phase-13 imported-assumption boundary.

- [ ] **Step 3: Implement supported declaration checking**

Use a fixed Phase-13 admission budget of `4096` and KernelCore default resources.

For `.definitionDecl`, construct:

```text
PsKernelCoreDefinitionInfo
  base = converted name/levels/type
  value = converted value
  hints = regular 0
  safety = safe
```

and call `psKernelCoreAddDefinition 4096`.

For `.theoremDecl`, construct `PsKernelCoreTheoremInfo` and call `psKernelCoreAddTheorem 4096`.

All other declaration variants return `unsupportedDeclaration`.

On any trusted KernelCore error, return `kernelRejected message` unchanged. Thread the returned environment in source order and increment `checkedDeclarations` only after successful admission.

- [ ] **Step 4: Implement API integrity ordering**

`psCompilerKernelShadowCheckPrepared` must call `psCompilerValidatePrepared` first. Map validation failure to `.compiler error`; only on success call `psCompilerKernelShadowCheckDeclarations`, mapping failures to `.shadow error`.

`psCompilerKernelShadowCheckElaborated` must prepare using the existing compiler function, then use the prepared wrapper.

`psCompilerKernelShadowCheckSource` must prepare source using the existing compiler function, then use the prepared wrapper.

Do not modify any existing compile/VerifiedIR function to call these APIs.

- [ ] **Step 5: Run the unchanged Task-1 fixture**

Run:

```bash
cd psc15selfhost
lake build PsKernelCore PsCompiler
lake env lean --run test/CompilerKernelShadowTests.lean
```

Expected:

```text
PSC2_KERNEL_CORE_PHASE13_SHADOW_MINIMAL: PASS
```

- [ ] **Step 6: Verify the trusted KernelCore source count did not change**

Run:

```bash
cd psc15selfhost
node scripts/check-kernel-core-source.mjs
```

Expected marker remains:

```text
KERNEL_CORE_SOURCE_PROFILE: PASS (23 PSC1-subset, self-host-checkable modules)
```

- [ ] **Step 7: Commit the minimal GREEN slice**

Suggested commit:

```text
feat(compiler): add KernelCore shadow checker
```

---

### Task 3: Expand the supported positive matrix and environment threading

**Files:**
- Modify: `psc15selfhost/test/CompilerKernelShadowTests.lean`
- Production files only if a test exposes a real adapter/API defect.

**Interfaces:**
- Consumes the Task-2 source API.
- Produces evidence that source-frontends and sequential ordinary declarations are handled by one threaded KernelCore shadow environment.

- [ ] **Step 1: Add Lean and ProofScript literal-definition cases**

Require success/count `1` for:

```text
Lean:        def answer : Nat := 42
ProofScript: def answer: Nat := 42;
```

- [ ] **Step 2: Add an ordinary function case**

Require source-level shadow success/count `1` for:

```lean
def idNat (x : Nat) : Nat := x
```

- [ ] **Step 3: Add a polymorphic/dependent ordinary definition case**

Use the current minimal frontend fixture:

```lean
def identity (α : Type) (x : α) : α := x
```

The test must first demonstrate that the existing `psCompilerPrepareSource` accepts this fixture; if the frontend itself rejects it, record that as a current frontend limitation and replace only this case with an equivalent already-elaborated `PsDeclaration.definitionDecl` transport test. Do not widen the frontend as part of Phase 13.

- [ ] **Step 4: Add a theorem case**

Prefer the source-level fixture already documented by the language surface:

```proofscript
theorem selfEq(x: Nat): x = x := by rfl;
```

Require shadow success/count `1`. If the current psc15 frontend cannot yet elaborate that exact surface, use the equivalent current accepted theorem syntax or an already-elaborated theorem declaration; do not add theorem syntax/tactic features in Phase 13.

- [ ] **Step 5: Add cross-declaration dependency coverage**

Use one source module containing:

```lean
def first : Nat := 41
def second : Nat := first
```

Require success and:

```text
checkedDeclarations == 2
```

This pins source-order environment threading.

- [ ] **Step 6: Run the positive matrix**

Expected final marker:

```text
PSC2_KERNEL_CORE_PHASE13_SHADOW_POSITIVE: PASS
```

The original minimal marker may remain as a separate print if useful.

- [ ] **Step 7: Commit**

Suggested commit:

```text
test(compiler): cover Phase 13 shadow positive matrix
```

---

### Task 4: Pin fail-closed transport, kernel rejection, and prepared-integrity ordering

**Files:**
- Create: `psc15selfhost/test/CompilerKernelShadowRejectionTests.lean`
- Modify production only if a RED case demonstrates an actual defect.

**Interfaces:**
- Consumes `psCompilerKernelShadowAssumptionEnvironment`, `psCompilerKernelShadowCheckDeclarations`, and the API-level prepared checker.
- Produces explicit evidence separating transport errors, compiler prepared-integrity errors, unsupported declarations, and trusted KernelCore rejection.

- [ ] **Step 1: Add prepared-artifact integrity ordering test**

Prepare `def answer : Nat := 42`, replace only `canonicalAdmissions` with `"forged"`, then call `psCompilerKernelShadowCheckPrepared`.

Required result:

```text
Except.error (.compiler PsCompilerError.preparedAdmissionMismatch)
```

This must occur before any shadow success is possible.

- [ ] **Step 2: Add transport-boundary rejection cases**

Construct direct module declarations and require:

```text
PsExpr.fvar _  -> freeVariable
PsExpr.mvar _  -> expressionMetavariable
PsLevel.mvar _ -> universeMetavariable
```

Exercise both declaration type and value positions where meaningful; one representative case per error constructor is sufficient.

- [ ] **Step 3: Add duplicate-prelude-assumption coverage**

Call `psCompilerKernelShadowAssumptionEnvironment` with two declaration headers using the same name. Require:

```text
duplicatePreludeAssumption
```

Do not silently replace the earlier header.

- [ ] **Step 4: Add unsupported-declaration matrix**

Require `unsupportedDeclaration` for direct shadow input containing each of:

```text
axiomDecl
partialDecl
opaqueDecl
inductiveDecl
constructorDecl
recursorDecl
```

Constructor/recursor inputs must not bypass the unsupported inductive boundary.

- [ ] **Step 5: Add trusted KernelCore semantic rejection cases**

At minimum pin:

1. declared `Nat` definition whose body is a `String` literal -> `.kernelRejected "definition type mismatch"` (or the exact current KernelCore message if inference rejects earlier);
2. definition body referencing an unprojected/unknown constant -> `.kernelRejected "unknown constant"`;
3. duplicate module definition name -> `.kernelRejected "already declared"`;
4. projection expression that transports successfully but lacks the Phase-13 prelude semantic metadata -> `.kernelRejected ...`, while the transport itself must not misclassify it as unsupported syntax.

Tests should match stable error constructors first; match exact message only where the KernelCore message is already a stable acceptance contract.

- [ ] **Step 6: Add the Review-Focus cross-declaration negative**

A module containing only:

```lean
def second : Nat := first
```

without `first` must reach KernelCore and reject `first` as unknown.

- [ ] **Step 7: Run the rejection fixture**

Expected marker:

```text
PSC2_KERNEL_CORE_PHASE13_SHADOW_REJECTION: PASS
```

- [ ] **Step 8: Commit**

Suggested commit:

```text
test(compiler): harden Phase 13 shadow boundary
```

---

### Task 5: Prove shadow noninterference with the authoritative compiler path

**Files:**
- Create: `psc15selfhost/test/CompilerKernelShadowNoninterferenceTests.lean`
- Production files only if the test proves an unintended coupling.

**Interfaces:**
- Consumes existing `Ps.Compiler.Api`, `Ps.BackendTs.Compiler`, and the new shadow source API.
- Produces evidence that explicit shadow checking does not mutate or replace existing compile/VerifiedIR/backend behavior.

- [ ] **Step 1: Add TypeScript-output noninterference test**

For:

```lean
def answer : Nat := 42
```

compute the authoritative TypeScript output, call the shadow checker, then compute the authoritative TypeScript output again.

Require:

```text
before == after
```

and both normal compilation calls must succeed.

- [ ] **Step 2: Add unsupported-shadow/non-authoritative test**

Use a source accepted by the existing pipeline that contains a Phase-13-unsupported declaration (prefer a minimal inductive fixture already accepted by the compiler). Require:

```text
normal VerifiedIR/backend path succeeds
explicit shadow call returns unsupportedDeclaration
normal VerifiedIR/backend path still succeeds afterward
```

This is the key proof that Phase 13 does not silently make shadow checking authoritative.

- [ ] **Step 3: Add prepared-object purity test**

Create one valid `PsCompilerAdmissionReadyModule`, call `psCompilerVerifiedIrFromPrepared`, then shadow-check that same value, then call `psCompilerVerifiedIrFromPrepared` again. Assert both authoritative calls succeed and the prepared object's `canonicalAdmissions` string is unchanged.

- [ ] **Step 4: Run noninterference fixture**

Expected marker:

```text
PSC2_KERNEL_CORE_PHASE13_SHADOW_NONINTERFERENCE: PASS
```

- [ ] **Step 5: Rerun existing minimal self-host tests**

Run:

```bash
cd psc15selfhost
lake exe psc2_minimal_selfhost_tests
```

All existing `PSC2_MINIMAL_SELFHOST_PASS` markers must remain green.

- [ ] **Step 6: Commit**

Suggested commit:

```text
test(compiler): prove Phase 13 shadow noninterference
```

---

### Task 6: Add Phase-13 aggregate assurance and permanent CI

**Files:**
- Modify: `psc15selfhost/package.json`
- Update/create: `.github/workflows/psc2-kernel-core-phase13-work.yml`
- Create: `.github/workflows/psc2-kernel-core-phase13-acceptance.yml`

**Interfaces:**
- Consumes all Tasks 1–5 fixtures plus the complete Phase-12 assurance command.
- Produces one deterministic `assurance:kernel-core:phase13` command and one exact-head permanent acceptance job.

- [ ] **Step 1: Add the Phase-13 npm assurance script without editing Phase 1–12 scripts**

Add:

```text
assurance:kernel-core:phase13
```

with this semantic order:

```text
npm run assurance:kernel-core:phase12
lake env lean --run test/CompilerKernelShadowTests.lean
lake env lean --run test/CompilerKernelShadowRejectionTests.lean
lake env lean --run test/CompilerKernelShadowNoninterferenceTests.lean
lake exe psc2_minimal_selfhost_tests
npm run check:kernel-core-source
node scripts/report-kernel-core-size.mjs
```

Do not add shadow checking to `npm run check` itself; the normal compiler gate remains authoritative/non-shadow by design.

- [ ] **Step 2: Finish the focused work workflow**

Build:

```bash
lake build PsKernelCore PsCompiler PsBackendTs PSC1KernelReferenceFoundations
```

Then run the three Phase-13 fixtures, the Phase-12 aggregate, the minimal self-host test, and the KernelCore source profile. Keep the workflow scoped to the Phase-13 work branch and relevant compiler/test/script paths.

- [ ] **Step 3: Add the permanent Phase-13 acceptance workflow**

Trigger only on its own acceptance-workflow path plus `workflow_dispatch`, matching the Phase-12 permanent-gate pattern. On one exact SHA run:

```bash
cd psc15selfhost
lake build PsKernelCore PsCompiler PsBackendTs PSC1KernelReferenceFoundations
npm run assurance:kernel-core:phase13
npm run check
npm run fixed-point
```

`npm run fixed-point` is an explicit Phase-13 requirement because this phase changes compiler integration code even though the shadow path is additive; do not assume `npm run check` proves compiler-generation fixed point.

- [ ] **Step 4: Run focused CI and fix only actual defects**

Required evidence before the permanent run:

```text
all three Phase-13 markers PASS
Phase-12 aggregate PASS
PSC2 minimal self-host markers PASS
KERNEL_CORE_SOURCE_PROFILE remains 23 modules
```

- [ ] **Step 5: Trigger and wait for the exact permanent acceptance run**

Do not write acceptance documentation until all three permanent stages are green on one SHA:

1. Phase-13 aggregate assurance;
2. independent `npm run check`;
3. `npm run fixed-point`.

- [ ] **Step 6: Commit assurance/CI wiring**

Suggested commit sequence:

```text
ci(pskernel-core): add Phase 13 shadow assurance
ci(pskernel-core): add Phase 13 acceptance gate
```

---

### Task 7: Freeze Phase-13 acceptance evidence and hand off integration

**Files:**
- Create: `psc15selfhost/docs/continuity/PHASE13_ACCEPTANCE.md`
- No semantic source changes after the accepted permanent SHA.

**Interfaces:**
- Consumes the exact green focused/permanent CI SHAs and run/job IDs.
- Produces the durable accepted/non-claim boundary and an integration-ready branch/PR.

- [ ] **Step 1: Record exact evidence**

The acceptance document must record:

- execution branch;
- accepted permanent SHA;
- focused Phase-13 run/job/SHA;
- permanent run/job/SHA;
- Lean version;
- `assurance:kernel-core:phase13` result;
- `npm run check` result;
- `npm run fixed-point` result;
- KernelCore source-profile count;
- trusted size/LOC reporter output;
- Phase-12 accepted baseline.

- [ ] **Step 2: State allowed claims precisely**

Allowed after Phase 13 only if evidence is green:

```text
compiler ordinary definitions/theorems can be transported to KernelCore
bootstrap dependencies are represented as explicit opaque assumptions
supported module-local declarations are independently KernelCore-admitted
sequential module declarations thread through a KernelCore environment
prepared-artifact integrity is checked before shadow admission
normal VerifiedIR/backends remain unchanged and authoritative
```

- [ ] **Step 3: State explicit non-claims**

Must include:

```text
prelude is not independently KernelCore-certified
inductive/constructor/recursor compiler metadata is not yet reconstructed/checked by the shadow provider
KernelCore is not authoritative
CheckedCore is not yet the sole erasure input
old PsEnvironment provider is not removed
no mutual/nested expansion
no full Lean replay/equivalence claim
```

- [ ] **Step 4: Verify the acceptance commit is documentation-only**

Compare the permanent accepted SHA against the acceptance-doc commit. Expected changed semantic files: none; only `PHASE13_ACCEPTANCE.md` may differ.

- [ ] **Step 5: Review whole-branch scope**

Compare accepted Phase 12 against Phase 13 and verify production changes are limited to compiler-side adapter/API plus test/assurance wiring. Any trusted KernelCore change must have its own documented justification/evidence.

- [ ] **Step 6: Open an integration PR/handoff without merging**

Summarize shadow-only status, exact evidence, deferred Phase-14 inductive/recursor reconstruction, and the fact that authoritative cutover is still deferred to Phase 15.

Suggested acceptance-doc commit:

```text
docs(pskernel-core): record Phase 13 acceptance
```

---

## Final Acceptance Checklist

Phase 13 is complete only when all are true:

- [ ] Phase-13 spec and this implementation plan are approved.
- [ ] `Ps.Compiler.KernelShadow` remains outside the KernelCore TCB.
- [ ] No existing authoritative compiler/erasure/backend API implicitly invokes shadow checking.
- [ ] Lean + ProofScript minimal ordinary definitions shadow-check successfully.
- [ ] ordinary function/polymorphic/theorem cases have positive evidence within current frontend capabilities.
- [ ] sequential definitions prove KernelCore environment threading.
- [ ] transport mvar/fvar/universe-mvar cases fail closed.
- [ ] duplicate prelude assumptions fail closed.
- [ ] unsupported declaration variants fail closed.
- [ ] KernelCore catches type mismatch, unknown constant, and duplicate declaration cases.
- [ ] forged `canonicalAdmissions` fails before shadow checking.
- [ ] explicit shadow invocation does not alter VerifiedIR or TypeScript output.
- [ ] existing minimal-selfhost tests remain green.
- [ ] `assurance:kernel-core:phase12` remains green.
- [ ] `KERNEL_CORE_SOURCE_PROFILE` remains at 23 trusted PSC1-self-host-checkable modules unless separately justified.
- [ ] `assurance:kernel-core:phase13` is green.
- [ ] independent `npm run check` is green on the same accepted SHA.
- [ ] `npm run fixed-point` is green on the same accepted SHA.
- [ ] acceptance documentation is committed only after executable evidence is complete.
- [ ] no merge is performed automatically.
