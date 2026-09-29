# PSC2 KernelCore Phase 12 Recursive Recursor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Validate bounded single-family recursive recursors, their induction-hypothesis obligations and canonical recursive computation rules, then prove recursive iota on the Phase-11 admitted surface.

**Architecture:** Preserve the accepted Phase-10 ordinary recursor path and add a focused `RecursiveRecursor.lean` validator that consumes the Phase-11 recursive-field classifier. Recursive metadata is reconstructed from admitted constructor types; no persistent recursive-field metadata or kernel-side recursor declaration generation is added. `Reduce.lean` changes only if a RED recursive-iota fixture proves the existing rule reducer is insufficient.

**Tech Stack:** Lean 4.34.0, PSC1-subset `.lean`, Lake, npm assurance scripts, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-30-psc2-kernel-core-phase12-recursive-recursor-design.md`

## Global Constraints

- Trusted KernelCore source must remain PSC1-self-host-checkable.
- No `partial`, `unsafe`, IO, Lean/Std implementation APIs, custom elaborators, host `List` or host `Option` in trusted KernelCore source.
- Reuse `psKernelCoreRecursiveFieldShapeWithResources` / Phase-11 classifier semantics; do not add a second positivity algorithm.
- Do not trust `InductiveInfo.isRec` or `isReflexive` without re-deriving the constructor summary.
- Keep existing `PsKernelCoreRecursorInfo` / `PsKernelCoreRecursorRule` schema unchanged.
- Recursive rule syntax must contain exactly the classifier-derived self calls; type preservation alone is insufficient.
- Failed admission must return without mutating/replacing the caller environment.
- Mutual/nested inductives, arbitrary higher-order positivity, K expansion, structure/projection expansion and compiler-provider cutover remain out of scope.
- Every trusted-code change follows RED → observed failure → minimal GREEN → observed pass.

## Review Focus

- A family whose stored recursion flags disagree with constructor-derived recursion must be rejected, even if the recursor/minors are otherwise well typed. Task 2 pins this.
- A type-correct recursive rule that calls the wrong recursor or recursive field must be rejected. Task 2 pins this.
- Multiple recursive fields must produce one IH/self-call each in constructor-recursive-field order. Task 4 pins this.
- Functional recursive fields must preserve their argument telescope in both IH type and recursive-call lambda. Task 5 pins this.
- Indexed recursive fields must use classifier-derived recursive indices rather than constructor result indices or supplied guesses. Task 6 pins this.

---

### Task 1: Direct Recursive Recursor Admission Slice

**Files:**
- Create: `psc15selfhost/test/KernelCoreRecursiveRecursorAdmissionTests.lean`
- Create: `.github/workflows/psc2-kernel-core-phase12-work.yml`
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/RecursiveRecursor.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Recursor.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`

**Interfaces:**
- Consumes: `psKernelCoreRecursiveFieldShapeWithResources`, `psKernelCoreAnalyzeRecursiveConstructorWithResources`, existing recursor canonical helpers and `psKernelCoreAddRecursorWithResources`.
- Produces: `psKernelCoreValidateRecursiveRecursorWithResources (budget : Nat) (resources : PsKernelCoreResourceConfig) (env : PsKernelCoreEnvironment) (info : PsKernelCoreRecursorInfo) : PsKernelCoreResult String Unit` and a dispatch from the existing recursor admission path for recursive target families.

- [ ] **Step 1: Write the failing direct-recursion test**

Create a List-like family with zero parameters/indices, constructors `nil : List` and `cons : List -> List`, admit it with `psKernelCoreAddRecursiveInductive`, then supply a recursor whose `cons` minor is `forall tail, motive tail -> motive (cons tail)` and whose rule body applies `minorCons tail (List.rec motive minorNil minorCons tail)`.

Assertion: `psKernelCoreAddRecursor` succeeds and stores the recursor.

- [ ] **Step 2: Wire a focused Phase-12 workflow and verify RED**

Run in CI:

```text
cd psc15selfhost
lake env lean --run test/KernelCoreRecursiveRecursorAdmissionTests.lean
```

Expected: FAIL because the accepted Phase-10 recursor target predicate rejects recursive families / recursive minor shape.

- [ ] **Step 3: Implement the minimal direct-recursion validator**

Add `RecursiveRecursor.lean` importing `RecursorCanonical` and `RecursiveInductive`. For the first slice, support the direct zero-parameter/zero-index recursive-field case by re-deriving family recursion evidence and requiring each recursive constructor field to contribute exactly one additional IH binder after ordinary fields. Validate the IH domain as `motive field` and validate the final minor result against the existing constructor-branch result.

Do not weaken `psKernelCoreInductiveSingleFamilyMetadataValid`; dispatch recursive families into the new validator instead.

- [ ] **Step 4: Run focused test to verify GREEN**

Expected: `PSC2_KERNEL_CORE_PHASE12_RECURSIVE_RECURSOR_ADMISSION: PASS`.

- [ ] **Step 5: Run Phase-10/11 guards**

Run focused workflow steps for:

```text
KernelCoreRecursorAdmissionParityTests.lean
KernelCoreRecursorForgedMinorRejectionTests.lean
KernelCoreRecursiveInductiveAdmissionParityTests.lean
KernelCoreRecursiveInductiveRejectionTests.lean
check-kernel-core-source.mjs
```

Expected: all PASS.

- [ ] **Step 6: Commit**

Commit test + focused workflow + minimal trusted implementation only after the CI evidence above is green.

### Task 2: Forged IH / Recursive-Call / Family-Flag Rejection

**Files:**
- Create: `psc15selfhost/test/KernelCoreRecursiveRecursorRejectionTests.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/RecursiveRecursor.lean`

**Interfaces:**
- Consumes: Task-1 recursive-family dispatcher and direct-recursion validator.
- Produces: canonical direct recursive-rule structure validation and constructor-derived recursion-flag revalidation.

- [ ] **Step 1: Add RED rejection cases**

Cases must include: missing IH, extra IH on non-recursive constructor, wrong IH motive, IH for wrong field, stored `isRec` mismatch, wrong self-recursion constant, missing recursive call, extra recursive call, and failed-admission environment unchanged.

- [ ] **Step 2: Verify RED**

Expected: at least the structurally forged but type-correct rule/metadata cases are accepted by Task-1 code and therefore fail the rejection fixture.

- [ ] **Step 3: Implement canonical rule-structure validation**

Add helpers that open the fixed rule prefix and constructor fields, reconstruct the expected selected-minor application, and structurally require one canonical self-call per classifier-recursive field. Re-derive aggregate recursive flags from constructors and require equality with stored family metadata.

- [ ] **Step 4: Verify GREEN plus Task-1 and Phase-10 forged-minor guards**

Expected: all PASS.

- [ ] **Step 5: Commit**

### Task 3: Recursive Iota Through Existing Rule Representation

**Files:**
- Create: `psc15selfhost/test/KernelCoreRecursiveRecursorReductionTests.lean`
- Modify conditionally: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Reduce.lean`

**Interfaces:**
- Consumes: validated recursive recursor from Tasks 1–2.
- Produces: evidence that recursive constructor reduction executes the embedded canonical self-call.

- [ ] **Step 1: Add RED recursive computation fixture**

Use a nested direct-recursive value at least two constructors deep. Define minors so the outer result depends on the recursive result, proving the self-call is actually evaluated.

- [ ] **Step 2: Run the fixture before touching `Reduce.lean`**

Expected: if it PASSes, record the ruling that existing reduction is already sufficient and leave `Reduce.lean` unchanged. If it FAILs because the reducer omits a semantic step, proceed to Step 3.

- [ ] **Step 3: Conditional minimal reducer fix**

Only if RED evidence requires it, modify the existing recursor reduction path without introducing runtime IH metadata or a second recursion mechanism.

- [ ] **Step 4: Verify GREEN and existing Phase-10 direct iota**

Expected: both recursive and Phase-10 ordinary iota fixtures PASS.

- [ ] **Step 5: Commit**

### Task 4: Multiple Direct Recursive Fields

**Files:**
- Modify: `psc15selfhost/test/KernelCoreRecursiveRecursorAdmissionTests.lean`
- Modify: `psc15selfhost/test/KernelCoreRecursiveRecursorRejectionTests.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/RecursiveRecursor.lean`

**Interfaces:**
- Consumes: direct recursive-field/IH representation from Tasks 1–2.
- Produces: ordered mapping from all direct recursive constructor fields to IHs and self-calls.

- [ ] **Step 1: Add RED binary-tree fixture and swapped/missing-IH rejection cases**
- [ ] **Step 2: Verify RED**
- [ ] **Step 3: Generalize direct recursive-field traversal to preserve recursive-field order**
- [ ] **Step 4: Verify GREEN plus Tasks 1–3**
- [ ] **Step 5: Commit**

### Task 5: Functional Recursive Fields

**Files:**
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/RecursiveInductive.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/RecursiveRecursor.lean`
- Modify: `psc15selfhost/test/KernelCoreRecursiveRecursorAdmissionTests.lean`
- Modify: `psc15selfhost/test/KernelCoreRecursiveRecursorRejectionTests.lean`
- Modify: `psc15selfhost/test/KernelCoreRecursiveRecursorReductionTests.lean`

**Interfaces:**
- Consumes: Phase-11 functional positivity classifier.
- Produces: classifier-derived functional argument telescope usable by recursive minor and recursive-call validation.

- [ ] **Step 1: Add RED functional-recursion admission and missing/wrong telescope rejection cases**
- [ ] **Step 2: Verify RED**
- [ ] **Step 3: Extend the internal Phase-11 field-shape summary with the minimum binder information needed to reconstruct the accepted functional telescope; retain existing `argCount` behavior for current Phase-11 tests**
- [ ] **Step 4: Validate functional IH as the same telescope ending in `motive indices (field args)` and rule self-call as the same telescope ending in the recursive recursor call**
- [ ] **Step 5: Verify GREEN including Phase-11 shape/admission/rejection gates**
- [ ] **Step 6: Commit**

### Task 6: Indexed Recursive Fields

**Files:**
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/RecursiveRecursor.lean`
- Modify: `psc15selfhost/test/KernelCoreRecursiveRecursorAdmissionTests.lean`
- Modify: `psc15selfhost/test/KernelCoreRecursiveRecursorRejectionTests.lean`
- Modify: `psc15selfhost/test/KernelCoreRecursiveRecursorReductionTests.lean`

**Interfaces:**
- Consumes: classifier-derived `PsKernelCoreRecursiveFieldShape.indices` and functional telescope support.
- Produces: recursive IH/self-call validation using each field's own recursive indices.

- [ ] **Step 1: Add RED indexed-recursion fixture and wrong-index IH/self-call rejections**
- [ ] **Step 2: Verify RED**
- [ ] **Step 3: Instantiate/align classifier-derived field indices with the opened constructor-field context and use them in both IH and self-call reconstruction**
- [ ] **Step 4: Verify GREEN plus all Phase-12 focused tests**
- [ ] **Step 5: Commit**

### Task 7: Differential Reference Coverage and Permanent Assurance

**Files:**
- Modify: `psc15selfhost/test/KernelCoreRecursiveRecursorAdmissionTests.lean`
- Modify: `psc15selfhost/test/KernelCoreRecursiveRecursorReductionTests.lean`
- Modify: `psc15selfhost/package.json`
- Modify: `.github/workflows/psc2-kernel-core-phase12-work.yml`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`
- Create after green: `psc15selfhost/docs/continuity/PHASE12_ACCEPTANCE.md`

**Interfaces:**
- Consumes: complete bounded Phase-12 semantics from Tasks 1–6.
- Produces: `assurance:kernel-core:phase12`, permanent workflow evidence and exact acceptance record.

- [ ] **Step 1: Add PSC1Kernel differential assertions for overlapping direct, multi-field, functional and indexed recursors/reduction**
- [ ] **Step 2: Add `assurance:kernel-core:phase12` combining Phase-11 assurance, all Phase-12 fixtures, source profile and size report**
- [ ] **Step 3: Add Phase-12 branch/path wiring and permanent workflow steps**
- [ ] **Step 4: Run focused Phase-12 assurance**
- [ ] **Step 5: Run permanent Phase-1 through Phase-12 assurance and full `npm run check`**
- [ ] **Step 6: Run verification-before-completion review of exact CI run/job/head and trusted-source diff**
- [ ] **Step 7: Create `PHASE12_ACCEPTANCE.md` only after exact green evidence exists**
- [ ] **Step 8: Commit acceptance documentation**
