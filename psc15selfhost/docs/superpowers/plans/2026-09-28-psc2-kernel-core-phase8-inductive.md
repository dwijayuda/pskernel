# PSC2 KernelCore Phase 8 Minimal Non-Recursive Inductive Admission Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the smallest PSC1-self-hostable genuine inductive/constructor metadata and admission path required to admit non-recursive indexed `Eq` / `Eq.refl` without adding recursive inductives, recursors, positivity, iota, projection computation, or Quot itself.

**Architecture:** Extend `PsKernelCoreConstantInfo` with bounded inductive/constructor metadata, then add a pure `Ps.KernelCore.Inductive` module. Admission validates one non-recursive family, validates the header before creating a temporary work environment, validates constructors against that work environment, rejects every recursive occurrence outside the constructor result head, and returns a new environment only after all constructors pass. Differential tests use `PSC1Kernel.Kernel.addSimpleInductive` as the bounded oracle while ignoring the oracle's generated recursor because recursors are outside Phase 8.

**Tech Stack:** Lean 4.34.0, PSC1-compatible `.lean`, Lake, npm workspace assurance scripts, GitHub Actions.

**Spec:** `psc15selfhost/docs/superpowers/specs/2026-09-28-psc2-kernel-core-phase8-inductive-design.md`

## Global Constraints

- Execute from an isolated work branch based on `psc2/kernel-core-phase8-inductive`, e.g. `psc2/kernel-core-phase8-inductive-work`.
- Trusted Phase-8 source must remain PSC1-compatible `.lean` and pass the actual flattened `psc1 check` gate.
- No `partial`, trusted `unsafe`, `extern`, `implemented_by`, `IO`, `Lean.*`, `Std.*`, custom syntax/macros/elaborators, `namespace`, `mutual`, termination annotations, semantic host `List`/`Option` storage, or hash/index/cache/session machinery in trusted KernelCore source.
- Preserve all accepted Phase-1 through Phase-7 APIs and aggregate assurance commands.
- `PsKernelCoreInductiveInfo.all` must be exactly `[base.name]`.
- `numNested = 0`, `isRec = false`, and `isReflexive = false` are mandatory Phase-8 invariants.
- Constructor indices are zero-based and must match constructor order.
- The inductive header telescope must expose exactly `numParams + numIndices` binders before its final sort result.
- Recursive occurrences of the new inductive are forbidden in constructor domains/fields, function domains/codomains, result parameters/indices, metadata/projection traversal, or any result argument; the only allowed occurrence is the constructor result head itself.
- No strict positivity, recursive/mutual/nested inductives, recursor metadata/generation, iota, projection computation, structure eta, Quot, Phase-7B bitwise/shifts, native reduction, compiler CheckedCore cutover, or full-Lean-equivalence claim is part of Phase 8.
- Phase-8 production logic must remain name-agnostic: do not special-case `Eq` or `Eq.refl`. Exact Quot-bootstrap recognition of canonical `Eq`/`Eq.refl` belongs to Phase 9.
- `pskernel-core` remains outside the active PSC2 compiler bootstrap admission closure.

## Review Focus

1. **Header metadata count drift:** `numParams + numIndices` must match the inductive header telescope exactly.
2. **Hidden recursive occurrence:** a constructor that hides the inductive inside a field/domain or result argument must be rejected.
3. **Correct head, wrong parameter prefix/universe application:** reject rather than relying on type checking alone.
4. **Failure after provisional header insertion:** caller environment must remain observably unchanged.
5. **Metadata shape escape:** `all != [name]`, nested/recursive/reflexive flags, safety mismatch, wrong constructor index, or wrong field count must fail closed.

---

## File Structure

### Trusted production files
- Modify `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Declaration.lean` — metadata variants/accessors.
- Create `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Inductive.lean` — bounded shape analysis and admission.
- Modify `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean` — export `Ps.KernelCore.Inductive`.

### Tests
- Modify `psc15selfhost/test/KernelCoreDeclarationParityTests.lean`.
- Create `psc15selfhost/test/KernelCoreInductiveShapeTests.lean`.
- Create `psc15selfhost/test/KernelCoreInductiveAdmissionParityTests.lean`.
- Create `psc15selfhost/test/KernelCoreEqInductiveTests.lean`.

### Build / assurance / continuity
- Modify `psc15selfhost/lakefile.lean`.
- Modify `psc15selfhost/package.json`.
- Modify `.github/workflows/psc2-minimal-kernel.yml`.
- Create `psc15selfhost/docs/continuity/PHASE8_ACCEPTANCE.md` only after exact-head green CI.

---

### Task 1: Add Genuine Inductive and Constructor Metadata

**Files:**
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Declaration.lean`
- Modify: `psc15selfhost/test/KernelCoreDeclarationParityTests.lean`

**Interfaces:**
- Consumes: `PsKernelCoreConstantBase`, `PsKernelCoreList`, existing `PsKernelCoreConstantInfo` accessors.
- Produces:

```text
structure PsKernelCoreInductiveInfo where
  base        : PsKernelCoreConstantBase
  numParams   : Nat
  numIndices  : Nat
  all         : PsKernelCoreList PsKernelCoreName
  ctors       : PsKernelCoreList PsKernelCoreName
  numNested   : Nat
  isRec       : Bool
  isReflexive : Bool
  isUnsafe    : Bool

structure PsKernelCoreConstructorInfo where
  base      : PsKernelCoreConstantBase
  induct    : PsKernelCoreName
  cidx      : Nat
  numParams : Nat
  numFields : Nat
  isUnsafe  : Bool

PsKernelCoreConstantInfo.inductInfo
PsKernelCoreConstantInfo.ctorInfo
```

Existing accessors must expose the new variants' base/name/levels/type/safety; both variants remain non-definition, non-partial, with no delta value or reducibility hints.

- [ ] **Step 1: Extend declaration parity first**

Add KernelCore/reference `inductInfo` and `ctorInfo` fixtures. Assert parity for base/name/levelParams/type, unsafe classification, `isPartial = false`, `isDefinition = false`, `deltaValue? = none`, `hints? = none`, and `definition? = none`.

- [ ] **Step 2: Run RED**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_declaration_parity_tests
```

Expected: compile failure because the new metadata variants do not exist.

- [ ] **Step 3: Implement metadata/accessor cases**

Keep the existing flat PSC1-friendly source style. Do not add recursor or Quot metadata.

- [ ] **Step 4: Verify GREEN + actual PSC1 source acceptance**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_declaration_parity_tests
npm run check:kernel-core-source
```

- [ ] **Step 5: Commit**

```bash
git add psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Declaration.lean \
        psc15selfhost/test/KernelCoreDeclarationParityTests.lean
git commit -m "feat(pskernel-core): add inductive metadata"
```

---

### Task 2: Add Bounded Inductive Header/Result Shape Analysis

**Files:**
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Inductive.lean`
- Create: `psc15selfhost/test/KernelCoreInductiveShapeTests.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`
- Modify: `psc15selfhost/lakefile.lean`

**Interfaces:**
- Produces:

```text
psKernelCoreExprContainsConstName
  : PsKernelCoreName -> PsKernelCoreExpr -> Bool

psKernelCoreInductiveHeaderMatches
  : Nat -> Nat -> PsKernelCoreExpr -> Bool

psKernelCoreInductiveUniformParamArgsMatch
  : Nat -> PsKernelCoreList PsKernelCoreExpr -> Nat -> Bool

psKernelCoreInductiveResultMatches
  : PsKernelCoreName
  -> PsKernelCoreList PsKernelCoreLevel
  -> Nat
  -> Nat
  -> PsKernelCoreExpr
  -> Bool

psKernelCoreInductiveConstructorRecursiveOccurrence
  : PsKernelCoreName
  -> PsKernelCoreExpr
  -> Bool
```

`psKernelCoreInductiveHeaderMatches` requires exactly `numParams + numIndices` forall binders before the final sort.

`psKernelCoreInductiveResultMatches` requires the correct result head, universe list, total arity, de-Bruijn parameter prefix, and no recursive occurrence in result arguments.

`psKernelCoreInductiveConstructorRecursiveOccurrence` permits the target only as the final accepted result head; any occurrence in domains or result arguments is rejected.

- [ ] **Step 1: Add the missing-module RED fixture and Lake target**

Cover:
- correct zero-parameter header count;
- correct parameter/index header count;
- header count mismatch;
- target occurrence traversal through app/lambda/forall/let/metadata/projection;
- correct zero-parameter result;
- correct parameterized/indexed result;
- wrong head, levels, arity, or parameter prefix;
- target hidden inside an index/result argument;
- target inside a field/domain.

- [ ] **Step 2: Run RED before creating production code**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_inductive_shape_tests
```

- [ ] **Step 3: Implement total PSC1-compatible helpers**

Do not copy mature `partial` recursion. Use structurally decreasing recursion or explicit Nat fuel only where PSC1 requires it. No positivity algorithm.

- [ ] **Step 4: Verify GREEN + source gate**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_inductive_shape_tests
npm run check:kernel-core-source
```

Expected direct marker:

```text
PSC2_KERNEL_CORE_INDUCTIVE_SHAPE: PASS
```

- [ ] **Step 5: Commit**

```bash
git add psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Inductive.lean \
        psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean \
        psc15selfhost/test/KernelCoreInductiveShapeTests.lean \
        psc15selfhost/lakefile.lean
git commit -m "feat(pskernel-core): add bounded inductive shape analysis"
```

---

### Task 3: Implement Pure Non-Recursive Inductive Admission

**Files:**
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Inductive.lean`
- Create: `psc15selfhost/test/KernelCoreInductiveAdmissionParityTests.lean`
- Modify: `psc15selfhost/lakefile.lean`

**Interfaces:**
- Consumes Task-1 metadata, Task-2 shape helpers, existing admission/check/resource APIs, and the linear immutable environment.
- Produces:

```text
psKernelCoreAddNonRecursiveInductiveWithResources
  : Nat
  -> PsKernelCoreResourceConfig
  -> PsKernelCoreEnvironment
  -> PsKernelCoreInductiveInfo
  -> PsKernelCoreList PsKernelCoreConstructorInfo
  -> PsKernelCoreResult String PsKernelCoreEnvironment

psKernelCoreAddNonRecursiveInductive
  : Nat
  -> PsKernelCoreEnvironment
  -> PsKernelCoreInductiveInfo
  -> PsKernelCoreList PsKernelCoreConstructorInfo
  -> PsKernelCoreResult String PsKernelCoreEnvironment
```

The default wrapper uses `psKernelCoreResourceConfigDefault`.

**Admission ordering:**
1. budget/resource boundary;
2. validate `all = [name]`, `numNested = 0`, `isRec = false`, `isReflexive = false`;
3. validate fresh/unique inductive + constructor names;
4. validate inductive universe parameters, closure, declared type well-formedness;
5. ensure the inductive type is a sort and the exposed header telescope count is exactly `numParams + numIndices`;
6. insert the already-validated final `inductInfo` into a temporary work environment only;
7. validate each constructor in order: ownership, zero-based cidx, safety equality, level params, closure/type, field count, result head/levels/parameter prefix/index arity, and non-recursion;
8. add each validated constructor to the temporary environment;
9. return the temporary environment only after all constructors pass.

- [ ] **Step 1: Write admission RED fixtures first**

Positive bounded overlap against `PSC1Kernel.Kernel.addSimpleInductive`:
- one-constructor non-indexed family;
- two-constructor enum-like family;
- one-parameter family;
- compare stored inductive/constructor semantic fields only; ignore the reference-generated recursor;
- preserve incoming `quotInitialized`.

Negative cases:
- duplicate inductive/constructor/existing names;
- duplicate universe params;
- mvar/fvar/undefined level param;
- `all != [name]`;
- `numNested != 0`, `isRec = true`, `isReflexive = true`;
- header `numParams + numIndices` mismatch;
- wrong constructor owner/cidx/numParams/levelParams/safety/numFields;
- wrong result head/levels/arity/parameter prefix;
- recursive occurrence in field/domain or result argument;
- late constructor failure leaves original environment size/content/`quotInitialized` unchanged.

- [ ] **Step 2: Run RED**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_inductive_admission_parity_tests
```

- [ ] **Step 3: Implement the minimal admission path**

Reuse `psKernelCoreAdmissionCheckClosed`, `psKernelCoreAdmissionCheckLevelParams`, `psKernelCoreCheckWithResources`, `psKernelCoreEnsureSortWithResources`, `psKernelCoreEnvironmentAddUnchecked`, and Phase-7 resource configuration. Do not add caches, recursors, or a second environment representation.

- [ ] **Step 4: Verify parity, source profile, and all Phase-7 assurance**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_inductive_admission_parity_tests
npm run check:kernel-core-source
npm run assurance:kernel-core:phase7
```

Expected marker:

```text
PSC2_KERNEL_CORE_INDUCTIVE_ADMISSION_PARITY: PASS
```

- [ ] **Step 5: Commit**

```bash
git add psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Inductive.lean \
        psc15selfhost/test/KernelCoreInductiveAdmissionParityTests.lean \
        psc15selfhost/lakefile.lean
git commit -m "feat(pskernel-core): admit bounded non-recursive inductives"
```

---

### Task 4: Pin `Eq` / `Eq.refl` as the Phase-9 Quot Dependency Fixture

**Files:**
- Create: `psc15selfhost/test/KernelCoreEqInductiveTests.lean`
- Modify: `psc15selfhost/lakefile.lean`
- Modify production code only if the RED fixture exposes a missing generic Phase-8 requirement already present in the spec.

**Interfaces:**
- Consumes `psKernelCoreAddNonRecursiveInductiveWithResources` and environment/accessor APIs.
- Produces no Quot-specific production helper.

- [ ] **Step 1: Build canonical KernelCore `Eq`**

Pin:

```text
Eq.{u} : {α : Sort u} -> α -> α -> Prop
Eq.refl : {α : Sort u} -> (a : α) -> Eq a a

Eq.numParams = 1
Eq.numIndices = 2
Eq.all = [Eq]
Eq.ctors = [Eq.refl]
Eq.numNested = 0
Eq.isRec = false
Eq.isReflexive = false
Eq.refl.induct = Eq
Eq.refl.cidx = 0
Eq.refl.numParams = 1
Eq.refl.numFields = 1
```

Use `PSC1Kernel.Kernel.addSimpleInductive` as the metadata/type oracle. Phase-8 production code remains name-agnostic: `Eq` is admitted only because it satisfies the generic bounded rules.

- [ ] **Step 2: Add Eq compatibility checks for the future Quot phase**

The test must verify the stored KernelCore environment exposes genuine `inductInfo` for `Eq` and genuine `ctorInfo` for `Eq.refl`, with the expected types/metadata.

A test-side canonical-Eq compatibility predicate may reject separately constructed malformed environments, but **generic Phase-8 admission must not special-case `Eq`/`Eq.refl` names**. Exact trusted `checkEqForQuot` behavior belongs to Phase 9.

Also pin the generic Phase-8 rejection of hidden recursive `Eq` occurrences in result arguments, wrong universe application, wrong parameter prefix, and forbidden nested/recursive/reflexive metadata.

- [ ] **Step 3: Run the fixture**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_eq_inductive_tests
```

Expected:

```text
PSC2_KERNEL_CORE_EQ_INDUCTIVE: PASS
```

- [ ] **Step 4: Verify existing Infer/Check/Reduce behavior**

References to admitted `Eq` and `Eq.refl` must use their stored types/safety as ordinary non-delta constants. Basic reduction must not delta-unfold them. Do not add recursor/projection behavior.

- [ ] **Step 5: Commit**

```bash
git add psc15selfhost/test/KernelCoreEqInductiveTests.lean \
        psc15selfhost/lakefile.lean
git commit -m "test(pskernel-core): pin Eq inductive compatibility"
```

If a production fix was required, include only that smallest spec-consistent change.

---

### Task 5: Add Phase-8 Aggregate Assurance and Branch CI

**Files:**
- Modify: `psc15selfhost/package.json`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`

**Interfaces:**
- Produces `assurance:kernel-core:phase8`.

The Phase-8 aggregate must retain all Phase-7 commands and add:

```text
lake exe psc2_kernel_core_inductive_shape_tests
lake exe psc2_kernel_core_inductive_admission_parity_tests
lake exe psc2_kernel_core_eq_inductive_tests
```

plus the existing size reporter. Do not alter Phase-1 through Phase-7 scripts.

- [ ] **Step 1: Add CI branch triggers**

```text
psc2/kernel-core-phase8-inductive
psc2/kernel-core-phase8-inductive-work
```

- [ ] **Step 2: Add three direct Phase-8 workflow steps**

Place them after existing Phase-7 direct semantic gates and before bootstrap/source/aggregate checks.

- [ ] **Step 3: Add Phase-8 aggregate assurance**

```bash
npm run assurance:kernel-core:phase8
```

Run it before the unchanged final `npm run check` regression gate.

- [ ] **Step 4: Verify exact-head CI**

Required markers:

```text
all Phase-1..7 direct/aggregate gates PASS
PSC2_KERNEL_CORE_INDUCTIVE_SHAPE: PASS
PSC2_KERNEL_CORE_INDUCTIVE_ADMISSION_PARITY: PASS
PSC2_KERNEL_CORE_EQ_INDUCTIVE: PASS
KERNEL_CORE_SOURCE_PROFILE: PASS
Phase 8 aggregate assurance: success
Existing PSC2 regression gate (`npm run check`): success
KERNEL_CORE_SIZE_REPORT: PASS
```

- [ ] **Step 5: Commit assurance wiring**

```bash
git add psc15selfhost/package.json .github/workflows/psc2-minimal-kernel.yml
git commit -m "ci(pskernel-core): add phase8 inductive assurance"
```

---

### Task 6: Acceptance Evidence and Integration Handoff

**Files:**
- Create: `psc15selfhost/docs/continuity/PHASE8_ACCEPTANCE.md`

**Interfaces:**
- Consumes exact green implementation/assurance SHA + workflow run/job IDs.
- Produces the durable Phase-8 accepted claims/non-claims used by Phase 9.

- [ ] **Step 1: Freeze exact evidence only after complete green CI**

Record tested SHA, workflow run/job IDs, Lean 4.34.0, trusted module count, size bytes/LOC/ratios, and all green gates.

- [ ] **Step 2: Write acceptance record**

Document accepted bounded non-recursive single-family admission, canonical `Eq`/`Eq.refl` fixture, actual PSC1 self-host evidence, preserved lower gates, and explicit non-claims. Do not claim recursive/general inductives, recursors, Quot, or full Lean compatibility.

- [ ] **Step 3: Verify post-test delta is documentation-only**

Compare tested SHA to acceptance commit; expected semantic/code delta after the tested SHA is zero.

- [ ] **Step 4: Whole-branch scope review**

Confirm no Quot, recursor, positivity, projection, native, compiler/backend, or unrelated application code entered Phase 8.

- [ ] **Step 5: Open PR**

Open `psc2/kernel-core-phase8-inductive-work` -> `psc2/kernel-core-phase8-inductive`. Include exact tested SHA, CI IDs, source count, size evidence, and deferred semantics. Do not merge automatically without a separate user request.

---

## Phase-8 Completion Definition

One exact implementation/assurance SHA must have all of:

```text
Declaration metadata parity                  PASS
Bounded inductive shape tests                PASS
Non-recursive inductive admission parity     PASS
Eq / Eq.refl compatibility                   PASS
All Phase-1..7 direct semantic gates         PASS
Bootstrap closure isolation                  PASS
Actual PSC1 KernelCore source profile        PASS
Phase-1..8 aggregate assurance               PASS
Full existing npm run check                  PASS
Size report                                  PASS
```

The next architectural phase is **Phase 9 — Quot**, which may then rely on Phase 8's trusted fact that `Eq` / `Eq.refl` can exist as genuine validated inductive/constructor metadata.