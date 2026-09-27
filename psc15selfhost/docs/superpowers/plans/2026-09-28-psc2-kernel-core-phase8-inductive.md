# PSC2 KernelCore Phase 8 Minimal Non-Recursive Inductive Admission Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the smallest PSC1-self-hostable genuine inductive/constructor metadata and admission path required to admit and recognize non-recursive indexed `Eq` / `Eq.refl` without adding recursive inductives, recursors, positivity, iota, projection computation, or Quot itself.

**Architecture:** Extend the existing `PsKernelCoreConstantInfo` representation with bounded inductive/constructor variants, then add a separate pure `Ps.KernelCore.Inductive` admission module. Admission validates a single non-recursive inductive family, adds the checked inductive header to a temporary work environment so constructor types can reference it, validates constructor metadata and result shape, rejects every recursive occurrence outside the constructor result head, and returns a new environment only after the whole declaration succeeds. Differential tests use the mature `PSC1Kernel.Kernel.addSimpleInductive` path as the bounded oracle while deliberately ignoring the oracle's generated recursor because recursors are outside Phase 8.

**Tech Stack:** Lean 4.34.0, PSC1-compatible `.lean`, Lake, npm workspace assurance scripts, GitHub Actions.

**Spec:** `psc15selfhost/docs/superpowers/specs/2026-09-28-psc2-kernel-core-phase8-inductive-design.md`

## Global Constraints

- Base execution from the accepted Phase-7 reviewed line represented by `psc2/kernel-core-phase8-inductive`; create an isolated execution branch such as `psc2/kernel-core-phase8-inductive-work` before implementation.
- Trusted Phase-8 source must remain PSC1-compatible `.lean` and pass the actual flattened `psc1 check` source gate.
- No `partial`, trusted `unsafe`, `extern`, `implemented_by`, `IO`, `Lean.*`, `Std.*`, custom macros/elaborators, `namespace`, `mutual`, termination annotations, host hash/index/cache/session machinery, or semantic host `List`/`Option` storage in trusted KernelCore source.
- Preserve all accepted Phase-1 through Phase-7 semantic APIs and aggregate assurance commands.
- `PsKernelCoreInductiveInfo.all` is exactly `[base.name]` for this single-family phase.
- `numNested = 0`, `isRec = false`, and `isReflexive = false` are mandatory Phase-8 metadata invariants.
- Constructor indices are zero-based and must match constructor order exactly.
- Recursive occurrences of the new inductive are forbidden in constructor domains/fields, function domains/codomains, parameter/index expressions, metadata/projection payload traversal, and result arguments; the only allowed occurrence is the constructor result head itself.
- No strict positivity, recursive/mutual/nested inductives, recursor metadata/generation, iota, projection computation, structure eta, Quot, Phase-7B bitwise/shifts, native reduction, compiler CheckedCore cutover, or full-Lean-equivalence claim is part of Phase 8.
- `pskernel-core` remains outside the active PSC2 compiler bootstrap admission closure.

## Review Focus

1. **A constructor hides the new inductive inside an index/result argument.** The admission test must reject it even though the outer result head is the correct inductive.
2. **A constructor has the right result head but the wrong parameter prefix or universe-level application.** The result-shape fixture must reject it rather than relying on type checking alone.
3. **Failure after the provisional inductive is added to the work environment.** The caller's original environment must remain observably unchanged.
4. **Unsafe metadata diverges between inductive and constructors.** Admission must reject the mismatch rather than silently changing safety classification.
5. **Single-family metadata pretends to be mutual/reflexive/nested.** `all != [name]`, `numNested != 0`, `isRec = true`, or `isReflexive = true` must fail closed.

---

## File Structure

### Trusted production files

- Modify `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Declaration.lean` — add inductive/constructor metadata variants and extend shared constant accessors/classification.
- Create `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Inductive.lean` — all bounded Phase-8 shape analysis and non-recursive admission semantics.
- Modify `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean` — export `Ps.KernelCore.Inductive` after the existing admission/resource stack.

### Tests

- Modify `psc15selfhost/test/KernelCoreDeclarationParityTests.lean` — representation/accessor parity for `inductInfo` and `ctorInfo`.
- Create `psc15selfhost/test/KernelCoreInductiveShapeTests.lean` — trusted helper behavior, result-head/arity/parameter-prefix analysis, and recursive-occurrence rejection.
- Create `psc15selfhost/test/KernelCoreInductiveAdmissionParityTests.lean` — positive/negative bounded admission differential cases against `PSC1Kernel.Kernel.addSimpleInductive`.
- Create `psc15selfhost/test/KernelCoreEqInductiveTests.lean` — indexed `Eq` / `Eq.refl` admission and compatibility evidence for the later Quot phase.

### Build / assurance / continuity

- Modify `psc15selfhost/lakefile.lean` — add three Phase-8 test executables and include `PSC1Kernel.Inductive` in the reference test library if the new differential fixture requires it explicitly.
- Modify `psc15selfhost/package.json` — add `assurance:kernel-core:phase8` without changing Phase-1 through Phase-7 scripts.
- Modify `.github/workflows/psc2-minimal-kernel.yml` — trigger on reviewed/work Phase-8 branches and run the new Phase-8 direct tests + aggregate assurance before the existing full regression gate.
- Create `psc15selfhost/docs/continuity/PHASE8_ACCEPTANCE.md` only after an exact implementation/assurance SHA has a completely green run.

---

### Task 1: Add Genuine Inductive and Constructor Metadata

**Files:**
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Declaration.lean`
- Modify: `psc15selfhost/test/KernelCoreDeclarationParityTests.lean`
- Modify only if required for the RED run: `psc15selfhost/.github` is not used; branch CI wiring belongs to Task 5.

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

- Existing accessors must return the new variants' `base` and safety metadata; both variants remain non-definition, non-partial, with no delta value or reducibility hints.

- [ ] **Step 1: Extend the existing declaration parity test first**

Add `inductInfo` and `ctorInfo` fixtures on both KernelCore and `PSC1Kernel` sides. Assert parity for base/name/level-params/type, `isUnsafe`, `isPartial = false`, `isDefinition = false`, `deltaValue? = none`, `hints? = none`, and `definition? = none`.

- [ ] **Step 2: Run the existing declaration parity target and observe RED**

Run:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_declaration_parity_tests
```

Expected: compile failure because `PsKernelCoreInductiveInfo`, `PsKernelCoreConstructorInfo`, `inductInfo`, and/or `ctorInfo` do not yet exist.

- [ ] **Step 3: Implement the minimal metadata and accessor cases in `Declaration.lean`**

Do not add recursor or Quot metadata. Keep every definition in the existing flat PSC1-friendly naming/style.

- [ ] **Step 4: Run direct parity and the actual PSC1 source gate**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_declaration_parity_tests
npm run check:kernel-core-source
```

Expected:

```text
PSC2_KERNEL_CORE_DECLARATION_PARITY: PASS
KERNEL_CORE_SOURCE_PROFILE: PASS (... PSC1-subset, self-host-checkable modules)
```

- [ ] **Step 5: Commit Task 1**

```bash
git add psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Declaration.lean \
        psc15selfhost/test/KernelCoreDeclarationParityTests.lean
git commit -m "feat(pskernel-core): add inductive metadata"
```

---

### Task 2: Add PSC1-Self-Hostable Bounded Inductive Shape Analysis

**Files:**
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Inductive.lean`
- Create: `psc15selfhost/test/KernelCoreInductiveShapeTests.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`
- Modify: `psc15selfhost/lakefile.lean`

**Interfaces:**
- Consumes: `PsKernelCoreExpr`, `PsKernelCoreName`, `PsKernelCoreLevel`, `PsKernelCoreList`, Phase-7 resources, ordinary admission closure/type helpers.
- Produces trusted helpers sufficient for Task 3. Exact helper names:

```text
psKernelCoreExprContainsConstName
  : PsKernelCoreName -> PsKernelCoreExpr -> Bool

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

`psKernelCoreInductiveResultMatches` recognizes a constructor result whose application head is the new inductive, whose universe levels match the declaration's parameter levels, whose total argument count is `numParams + numIndices`, and whose first `numParams` arguments are the expected de-Bruijn parameter variables for the constructor telescope. It must also reject any recursive occurrence inside the result arguments.

`psKernelCoreInductiveConstructorRecursiveOccurrence` traverses the constructor telescope and permits the target constant only as the final result head accepted by `psKernelCoreInductiveResultMatches`; any occurrence in domains or result arguments is rejected.

- [ ] **Step 1: Add the missing-module/shape RED fixture and Lake target**

`KernelCoreInductiveShapeTests.lean` must cover:

- no target occurrence;
- direct target occurrence;
- target nested in app/lambda/forall/let/metadata/projection traversal;
- correct zero-parameter result;
- correct parameterized/indexed result;
- wrong result head;
- wrong universe levels;
- wrong result arity;
- wrong parameter prefix;
- target hidden inside an index/result argument;
- target in a constructor field/domain.

- [ ] **Step 2: Run RED before creating `Inductive.lean`**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_inductive_shape_tests
```

Expected: failure because `Ps.KernelCore.Inductive` / helper definitions do not exist.

- [ ] **Step 3: Implement the helpers using total PSC1-compatible structural recursion**

Do not copy the mature kernel's `partial` functions. Use curried structurally decreasing recursion or explicit Nat fuel only where the actual PSC1 recursion checker requires it. No positivity algorithm is introduced.

- [ ] **Step 4: Export `Ps.KernelCore.Inductive` and run GREEN + source gate**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_inductive_shape_tests
npm run check:kernel-core-source
```

Expected:

```text
PSC2_KERNEL_CORE_INDUCTIVE_SHAPE: PASS
KERNEL_CORE_SOURCE_PROFILE: PASS (...)
```

- [ ] **Step 5: Commit Task 2**

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
- Consumes Task-1 metadata, Task-2 shape helpers, `psKernelCoreAdmissionCheckClosed`, `psKernelCoreAdmissionCheckLevelParams`, `psKernelCoreCheckWithResources`, `psKernelCoreEnsureSortWithResources`, `psKernelCoreEnvironmentAddUnchecked`, and Phase-7 resource configuration.
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

The default wrapper calls the resource-aware function with `psKernelCoreResourceConfigDefault`.

Admission ordering is fixed:

1. budget/resource boundary;
2. validate single-family metadata (`all = [name]`, `numNested = 0`, `isRec = false`, `isReflexive = false`);
3. validate fresh/unique inductive and constructor names;
4. validate inductive universe parameters, closure and declared type well-formedness against the original environment;
5. ensure the inductive declared type itself has a sort;
6. insert the already-validated final `inductInfo` into a temporary work environment only;
7. validate constructors in order: metadata ownership/index/safety/level params/closure/type, telescope field count, result head/levels/parameter prefix/index arity, and non-recursion;
8. add validated constructor metadata to the temporary environment;
9. return the completed temporary environment only after all constructors pass.

A failure after step 6 returns an error and never exposes the temporary environment to the caller.

- [ ] **Step 1: Write admission RED fixtures before the public function exists**

Positive differential overlap against `PSC1Kernel.Kernel.addSimpleInductive`:

- one-constructor non-indexed non-recursive family;
- two-constructor enum-like non-recursive family;
- one-parameter non-recursive family if supported by the same bounded algorithm;
- compare stored `InductiveInfo` / `ConstructorInfo` semantic fields only; ignore the reference recursor entry because Phase 8 deliberately does not generate one;
- preserve the incoming `quotInitialized` flag.

Required negative cases:

- duplicate inductive name;
- constructor collides with existing env name;
- duplicate constructor names;
- duplicate universe params;
- expression metavariable / universe metavariable / free variable / undefined level param;
- `all != [name]`;
- `numNested != 0`;
- `isRec = true`;
- `isReflexive = true`;
- constructor `induct` mismatch;
- wrong zero-based `cidx`;
- constructor `numParams` mismatch;
- constructor level-param mismatch;
- constructor safety mismatch;
- wrong `numFields`;
- wrong result head/levels/arity/parameter prefix;
- recursive occurrence in a field/domain or result argument;
- rejection after provisional insertion leaves original environment size/content/`quotInitialized` unchanged.

- [ ] **Step 2: Run RED**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_inductive_admission_parity_tests
```

Expected: compile failure because `psKernelCoreAddNonRecursiveInductive*` do not yet exist.

- [ ] **Step 3: Implement the minimal admission path in `Inductive.lean`**

Use the existing linear immutable environment. Do not add caches, hash tables, recursor records, or a second environment representation. Reuse ordinary admission/check helpers instead of duplicating closure/type validation.

- [ ] **Step 4: Run parity, source profile, and all lower semantic gates**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_inductive_admission_parity_tests
npm run check:kernel-core-source
npm run assurance:kernel-core:phase7
```

Expected direct output includes:

```text
PSC2_KERNEL_CORE_INDUCTIVE_ADMISSION_PARITY: PASS
```

and all Phase-7 assurance remains green.

- [ ] **Step 5: Commit Task 3**

```bash
git add psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Inductive.lean \
        psc15selfhost/test/KernelCoreInductiveAdmissionParityTests.lean \
        psc15selfhost/lakefile.lean
git commit -m "feat(pskernel-core): admit bounded non-recursive inductives"
```

---

### Task 4: Pin `Eq` / `Eq.refl` as the Quot Dependency Fixture

**Files:**
- Create: `psc15selfhost/test/KernelCoreEqInductiveTests.lean`
- Modify: `psc15selfhost/lakefile.lean`
- Modify production code only if this RED fixture exposes a missing bounded semantic requirement already present in the approved spec.

**Interfaces:**
- Consumes `psKernelCoreAddNonRecursiveInductiveWithResources` and the accepted metadata variants.
- Produces no new public semantic API unless required to inspect stored metadata through existing environment/accessor functions.

- [ ] **Step 1: Build a canonical KernelCore `Eq` fixture**

Pin this semantic shape:

```text
Eq.{u} : {α : Sort u} -> α -> α -> Prop
Eq.refl : {α : Sort u} -> (a : α) -> Eq a a
```

Metadata invariants for the fixture:

```text
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

Use the corresponding bounded `PSC1Kernel.Kernel.addSimpleInductive` result as the metadata/type oracle.

- [ ] **Step 2: Add negative `Eq` variants**

At minimum pin rejection of:

- wrong Eq index count;
- wrong constructor list;
- wrong refl constructor result (`Eq a b` instead of `Eq a a` where the supplied telescope metadata/indices do not match);
- hidden recursive `Eq` occurrence inside a result argument;
- wrong universe list;
- wrong parameter prefix;
- `isRec`, `isReflexive`, or nested metadata set contrary to Phase-8 invariants.

- [ ] **Step 3: Run the Eq fixture**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_eq_inductive_tests
```

Expected:

```text
PSC2_KERNEL_CORE_EQ_INDUCTIVE: PASS
```

If it fails, apply TDD: keep the failing fixture, make only the smallest spec-consistent trusted change, rerun this target, then rerun `npm run check:kernel-core-source`.

- [ ] **Step 4: Verify existing Infer/Check/Reduce behavior sees admitted metadata as ordinary non-delta constants**

The fixture must infer/check references to the admitted `Eq` and `Eq.refl` using their stored types and must demonstrate that basic reduction does not delta-unfold either declaration. No recursor/projection behavior is tested or added.

- [ ] **Step 5: Commit Task 4**

```bash
git add psc15selfhost/test/KernelCoreEqInductiveTests.lean \
        psc15selfhost/lakefile.lean \
        psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Inductive.lean
git commit -m "test(pskernel-core): pin Eq inductive compatibility"
```

If `Inductive.lean` was unchanged, omit it from the commit.

---

### Task 5: Add Phase-8 Assurance and Branch CI

**Files:**
- Modify: `psc15selfhost/package.json`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`

**Interfaces:**
- Produces npm script:

```text
assurance:kernel-core:phase8
```

The Phase-8 aggregate is Phase 7 plus, in dependency order:

```text
lake exe psc2_kernel_core_inductive_shape_tests
lake exe psc2_kernel_core_inductive_admission_parity_tests
lake exe psc2_kernel_core_eq_inductive_tests
```

and the existing size reporter. It must begin with `npm run check:kernel-core-source` and must not alter any prior aggregate script.

- [ ] **Step 1: Extend CI branch triggers before implementation-head verification**

Add:

```text
psc2/kernel-core-phase8-inductive
psc2/kernel-core-phase8-inductive-work
```

Keep the existing path filter.

- [ ] **Step 2: Add three direct Phase-8 workflow steps**

Place declaration metadata/shape/admission/Eq tests after the existing ordinary-admission/resource steps and before bootstrap/source/aggregate assurance, preserving dependency order.

- [ ] **Step 3: Add Phase-8 aggregate assurance step**

Run:

```bash
npm run assurance:kernel-core:phase8
```

before the unchanged final `npm run check` regression step.

- [ ] **Step 4: Run the aggregate locally or through exact-head CI**

Required exact-head evidence:

```text
all Phase-1 through Phase-7 parity/aggregate gates PASS
PSC2_KERNEL_CORE_INDUCTIVE_SHAPE: PASS
PSC2_KERNEL_CORE_INDUCTIVE_ADMISSION_PARITY: PASS
PSC2_KERNEL_CORE_EQ_INDUCTIVE: PASS
KERNEL_CORE_SOURCE_PROFILE: PASS
Phase 8 aggregate assurance: success
Existing PSC2 regression gate (`npm run check`): success
```

- [ ] **Step 5: Commit assurance wiring**

```bash
git add psc15selfhost/package.json .github/workflows/psc2-minimal-kernel.yml
git commit -m "ci(pskernel-core): add phase8 inductive assurance"
```

---

### Task 6: Acceptance Evidence, Size Report, and Integration Handoff

**Files:**
- Create: `psc15selfhost/docs/continuity/PHASE8_ACCEPTANCE.md`

**Interfaces:**
- Consumes the exact green implementation/assurance SHA and its GitHub Actions run/job IDs.
- Produces the durable Phase-8 acceptance/non-claim record used by Phase 9 Quot work.

- [ ] **Step 1: Freeze an exact implementation/assurance SHA only after complete green CI**

Record:

```text
implementation/assurance SHA
workflow run ID
job ID
Lean 4.34.0
conclusion: success
trusted self-host-checkable module count
size reporter bytes/LOC and reference ratios
```

Do not use the later documentation commit as the semantic evidence SHA.

- [ ] **Step 2: Write `PHASE8_ACCEPTANCE.md`**

Document accepted scope, direct fixtures, PSC1 self-host evidence, size evidence, exact lower gates preserved, and explicit non-claims. The strongest allowed summary should state only that KernelCore can admit the bounded non-recursive single-family inductive surface including `Eq` / `Eq.refl`; it must not claim recursive/general inductives, recursors, Quot, or full Lean compatibility.

- [ ] **Step 3: Verify the acceptance commit is documentation-only relative to the green semantic SHA**

Use `git diff --stat <tested-sha>..HEAD` / GitHub compare. Expected: only `PHASE8_ACCEPTANCE.md` after the tested semantic head.

- [ ] **Step 4: Perform whole-branch scope review**

Compare the reviewed Phase-8 plan head to the work-branch tip. Confirm no Quot, recursor, positivity, projection, native, compiler/backend, or unrelated application code was introduced.

- [ ] **Step 5: Open a PR from the isolated work branch to `psc2/kernel-core-phase8-inductive`**

The PR body must include the exact tested SHA, CI run/job IDs, trusted source count, size evidence, and explicit deferred semantics. Do not merge automatically unless the user separately asks for merge.

---

## Phase-8 Completion Definition

Phase 8 is complete only when all of the following are simultaneously true on one exact implementation/assurance SHA:

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

and the post-test acceptance delta is documentation-only.

The next architectural phase after acceptance is **Phase 9 — Quot**, which may rely on the trusted Phase-8 fact that `Eq` and `Eq.refl` can be represented and validated as genuine inductive/constructor metadata.