# PSC2 KernelCore Phase 10 Recursor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add PSC1-self-hostable canonical recursor metadata admission plus bounded direct-constructor iota reduction for the already-accepted Phase-8 single-family non-recursive inductive profile.

**Architecture:** Keep recursor generation outside the trusted kernel. Extend trusted declaration metadata with `recInfo`, validate supplied canonical recursor metadata in a focused `Recursor.lean` module using the existing resource-aware checker/DefEq stack, and integrate only direct-constructor iota into `Reduce.lean`. Do not widen inductive admission, synthesize K/structure constructors, or add recursive-IH semantics.

**Tech Stack:** Lean 4.34.0, PSC1-subset `.lean`, KernelCore local carriers, Lake executables, npm assurance scripts, GitHub Actions.

**Spec:** `psc15selfhost/docs/superpowers/specs/2026-09-28-psc2-kernel-core-phase10-recursor-design.md`

## Global Constraints

- All trusted Phase-10 source must pass the existing actual flattened PSC1 source/self-host gate unchanged.
- No `partial`, trusted `unsafe`, `extern`, `implemented_by`, `IO`, `Lean.*`, `Std.*`, custom syntax/macros/elaborators, `mutual`, or host semantic `List`/`Option` storage in KernelCore.
- Keep mature `PSC1Kernel` unchanged as the differential oracle.
- Keep `pskernel-core` outside the active compiler bootstrap closure.
- Recursor generation remains outside KernelCore; the trusted core validates supplied canonical metadata only.
- Target inductives are exactly the Phase-8 bounded profile: single-family, non-recursive, non-nested, non-reflexive.
- Phase 10 accepts exactly one motive and requires `k = false`.
- No recursive induction hypotheses, recursive/mutual/nested inductives, positivity, K conversion, structure eta/synthesis, literal-to-constructor recursor conversion, projections, native/eager reduction, or compiler provider cutover.
- Every semantic task follows RED -> observed intended failure -> minimal GREEN -> observed pass before the next semantic task.
- All explicitly configured reduction/admission paths must preserve the existing Phase-7 resource configuration and Phase-3 budget; no fallback to default-resource wrappers from inside a configured path.

## Review Focus

- A constructor from another admitted family must never trigger a recursor rule merely because an application shape is otherwise compatible; Task 4 pins this as residual behavior.
- A constructor application with fewer arguments than `rule.nFields` must remain residual, while parameterized constructors must pass only their final fields to the rule; Task 4 pins both.
- A recursor whose family metadata is bounded but whose constructor metadata order/index has been replaced inconsistently must fail admission rather than trusting the name list alone; Task 3 pins this.
- Zero-constructor bounded families, if already admissible by Phase 8, must not crash recursor admission or reduction; Task 2 pins either valid zero-minor admission or an explicit fail-closed error according to the existing family checker result.
- A failed recursor admission after expensive rule/type validation must leave the caller-visible input environment observably unchanged; Task 3 checks constants, size, and unrelated declarations, not only the returned error.

---

## File Structure

Create:

- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Recursor.lean` — bounded recursor metadata validation/admission and pure recursor metadata helpers; no reduction recursion.
- `psc15selfhost/test/KernelCoreRecursorMetadataTests.lean` — metadata/accessor differential fixture.
- `psc15selfhost/test/KernelCoreRecursorAdmissionParityTests.lean` — positive bounded recursor admission differential fixture.
- `psc15selfhost/test/KernelCoreRecursorRejectionTests.lean` — fail-closed admission/rejection matrix.
- `psc15selfhost/test/KernelCoreRecursorReductionParityTests.lean` — bounded direct-constructor iota differential fixture.
- `psc15selfhost/test/KernelCoreEqRecursorCompatibilityTests.lean` — genuine `Eq`/`Eq.refl` direct-iota compatibility fixture.

Modify:

- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Declaration.lean` — `RecursorRule`, `RecursorInfo`, `.recInfo`, exhaustive accessors/classification.
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean` — aggregate export of `Recursor`.
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Reduce.lean` — bounded recursor/iota hook only.
- `psc15selfhost/lakefile.lean` — Phase-10 test executables.
- `psc15selfhost/package.json` — Phase-10 aggregate assurance command.
- `.github/workflows/psc2-minimal-kernel.yml` — permanent Phase-10 gates/branch triggers after GREEN.
- optionally `.github/workflows/psc2-kernel-core-phase10-work.yml` — work-branch RED/GREEN execution while Phase 10 is in progress.
- `psc15selfhost/docs/continuity/PHASE10_ACCEPTANCE.md` — create only after exact-head permanent CI is green; acceptance commit must be documentation-only.

### Task 1: Recursor declaration metadata

**Interfaces:**
- Consumes: `PsKernelCoreConstantBase`, `PsKernelCoreConstantInfo`, `PsKernelCoreList`, existing accessor/classification functions from `Declaration.lean`.
- Produces:

```text
PsKernelCoreRecursorRule {
  ctor : PsKernelCoreName
  nFields : Nat
  rhs : PsKernelCoreExpr
}

PsKernelCoreRecursorInfo {
  base : PsKernelCoreConstantBase
  all : PsKernelCoreList PsKernelCoreName
  numParams : Nat
  numIndices : Nat
  numMotives : Nat
  numMinors : Nat
  rules : PsKernelCoreList PsKernelCoreRecursorRule
  k : Bool
  isUnsafe : Bool
}

PsKernelCoreConstantInfo.recInfo
```

- [ ] **Step 1: Write the failing metadata differential fixture**

Create `KernelCoreRecursorMetadataTests.lean`, importing `Ps.KernelCore.Declaration` and `PSC1Kernel.Declaration`. Construct equivalent rule/recursor records in both models and assert:

- rule constructor name, `nFields`, RHS shape;
- base/name/type/level-parameter accessors;
- `isUnsafe` mirrors stored recursor safety;
- `isPartial=false`, `isDefinition=false`;
- `deltaValue?=none`, `hints?=none`, `definition?=none`.

- [ ] **Step 2: Wire/run the fixture to prove RED**

Add a Lake executable and temporary work-branch workflow step only; do not change `Declaration.lean` yet.

Expected: FAIL specifically because `PsKernelCoreRecursorRule`, `PsKernelCoreRecursorInfo`, or `.recInfo` does not exist. Fix any harness/test defect until the remaining RED is semantic absence only.

- [ ] **Step 3: Implement minimal metadata**

Modify `Declaration.lean` with the exact structures/variant above and exhaustive cases in:

```text
psKernelCoreConstantInfoBase
psKernelCoreConstantInfoDeltaValue?
psKernelCoreConstantInfoHints?
psKernelCoreConstantInfoIsUnsafe
psKernelCoreConstantInfoIsPartial
psKernelCoreConstantInfoIsDefinition
psKernelCoreConstantInfoDefinition?
```

`name`, `levelParams`, and `type` continue through `base`.

- [ ] **Step 4: Run new + existing declaration fixtures**

Expected: new recursor metadata fixture PASS and all existing declaration/Phase-9 metadata parity PASS.

- [ ] **Step 5: Run actual KernelCore PSC1 source profile**

Expected: PASS before Task 2 begins.

### Task 2: Positive bounded recursor admission

**Interfaces:**
- Consumes: Task-1 metadata; Phase-8 `PsKernelCoreInductiveInfo`/`PsKernelCoreConstructorInfo`; `psKernelCoreAdmissionCheckBaseWithResources`; existing `psKernelCoreCheckWithResources`, `psKernelCoreEnsureSortWithResources`, `psKernelCoreIsDefEqWithResources`; local environment/list/expr helpers.
- Produces:

```text
psKernelCoreRecursorMajorIndex
    (info : PsKernelCoreRecursorInfo) : Nat

psKernelCoreFindRecursorRule?
    (ctor : PsKernelCoreName)
    (rules : PsKernelCoreList PsKernelCoreRecursorRule) :
    PsKernelCoreOption PsKernelCoreRecursorRule

psKernelCoreValidateRecursorWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreRecursorInfo) :
    PsKernelCoreResult String Unit

psKernelCoreAddRecursorWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig) :
    PsKernelCoreEnvironment ->
    PsKernelCoreRecursorInfo ->
    PsKernelCoreResult String PsKernelCoreEnvironment

psKernelCoreAddRecursor
    (budget : Nat)
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreRecursorInfo) :
    PsKernelCoreResult String PsKernelCoreEnvironment
```

- [ ] **Step 1: Write the positive admission differential fixture**

Create `KernelCoreRecursorAdmissionParityTests.lean`. Build a representative Phase-8 bounded family with parameters, indices, at least two constructors, and constructor fields; admit the family in both KernelCore and mature `PSC1Kernel`; construct canonical non-K recursor metadata; assert successful KernelCore recursor admission and equivalent stored semantic fields.

Assertions must include:

- `.recInfo` stored under the requested recursor name;
- `all=[family]`;
- parameter/index counts match family metadata;
- exactly one motive;
- one minor and one rule per constructor;
- rule order and `nFields` match constructor metadata;
- unrelated declarations and environment flag state remain preserved.

Also exercise the existing Phase-8 behavior for a zero-constructor family if it is accepted: either admit a zero-minor/zero-rule recursor or assert the family itself fails before Phase-10 logic. Do not invent a new Phase-10 family rule merely for this case.

- [ ] **Step 2: Run to prove RED**

Wire/run the new fixture before `Recursor.lean` exists.

Expected: FAIL because the recursor admission API/module is missing.

- [ ] **Step 3: Implement family/metadata structural validation**

Create `Recursor.lean`. Validate before any environment insertion:

- recursor name freshness;
- `all` exactly one target family;
- target resolves to `.inductInfo`;
- target remains single-family, `numNested=0`, `isRec=false`, `isReflexive=false`;
- parameter/index counts equal the family;
- `numMotives=1`;
- `numMinors=ctor count`;
- rule count equals ctor count;
- `k=false`;
- safety matches family;
- recursor level parameter names are unique;
- every rule is paired with the constructor at the same position; constructor metadata exists, belongs to the target, has the expected cidx, and `rule.nFields=ctor.numFields`.

Use total PSC1-compatible recursion over local carriers. Do not add recursor generation.

- [ ] **Step 4: Implement trusted type-preservation validation**

Use existing resource-aware admission/check/DefEq machinery to validate:

- recursor base type closed/no fvars or mvars;
- recursor base levels covered by its declared level params;
- recursor base type checks and has a sort type;
- every rule RHS is closed and level-covered by the same recursor level params;
- every rule RHS type is definitionally equal to the expected branch result for the paired constructor under canonical binder ordering `params ++ motive ++ minors ++ fields` and the constructor result indices.

Since Phase-8 families are non-recursive, expected branch construction has no induction-hypothesis binders and no recursive calls.

If a helper is needed to recover the constructor telescope/result, keep it private to `Recursor.lean` and reuse the same app/telescope conventions already used by `Inductive.lean`; do not widen `Inductive.lean` unless a truly generic existing helper must be exported.

- [ ] **Step 5: Add only after full validation succeeds**

`psKernelCoreAddRecursorWithResources` must add `.recInfo info` only after `psKernelCoreValidateRecursorWithResources` returns OK. The input environment is immutable; on error return only the error.

The default wrapper must call `psKernelCoreAddRecursorWithResources budget psKernelCoreResourceConfigDefault`.

- [ ] **Step 6: Export module and run positive parity + PSC1 source profile**

Expected: positive fixture PASS, actual flattened PSC1 source profile PASS, all Phase-8/9 aggregates still PASS.

### Task 3: Recursor rejection matrix and functional failure semantics

**Interfaces:**
- Consumes: Task-2 validation/admission APIs.
- Produces: fail-closed evidence for malformed canonical metadata.

- [ ] **Step 1: Write the rejection fixture before hardening**

Create `KernelCoreRecursorRejectionTests.lean` covering at minimum:

- duplicate/freshness collision;
- missing target family;
- target name bound to non-`.inductInfo`;
- `all` empty, wrong family, or multiple families;
- target metadata recursive, nested, or reflexive;
- wrong parameter count;
- wrong index count;
- `numMotives=0` and `numMotives>1`;
- wrong minor count;
- wrong rule count;
- duplicate rule / wrong rule order;
- missing constructor metadata;
- constructor name bound to non-`.ctorInfo`;
- constructor belongs to another family;
- inconsistent constructor `cidx`/order after environment replacement;
- wrong `rule.nFields`;
- `k=true`;
- safety mismatch;
- duplicate recursor universe parameter;
- uncovered universe parameter in base type or rule RHS;
- mvar/fvar leakage in base type or rule RHS;
- malformed/non-sort recursor base type;
- ill-typed rule RHS / branch-result mismatch.

For representative early and late failures, snapshot and assert the original environment's size, relevant constants, `quotInitialized`, and unrelated declaration lookup are unchanged.

- [ ] **Step 2: Run and classify RED cases**

Cases already rejected may pass. Every failing case must identify a missing validation contract; test/harness errors are repaired before production changes.

- [ ] **Step 3: Add only missing fail-closed checks in `Recursor.lean`**

Do not broaden Phase-8 inductive admission or general checker semantics to satisfy a malformed recursor fixture.

- [ ] **Step 4: Run positive + rejection fixtures, source profile, Phase-9 aggregate**

Expected: PASS.

### Task 4: Bounded direct-constructor iota reduction

**Interfaces:**
- Consumes: Task-1 `.recInfo`; Task-2 `psKernelCoreRecursorMajorIndex` / `psKernelCoreFindRecursorRule?`; existing `psKernelCoreWhnfWithResources`, app-view/list helpers and level instantiation helpers in `Reduce.lean`.
- Produces bounded direct-constructor recursor computation integrated into WHNF.

- [ ] **Step 1: Write the differential reduction fixture**

Create `KernelCoreRecursorReductionParityTests.lean` covering:

- direct admitted constructor major selects the matching rule;
- major is WHNF-reduced before constructor matching;
- `majorIdx = numParams + numMotives + numMinors + numIndices`;
- fixed args passed to rule are exactly `params ++ motives ++ minors`;
- constructor parameters are not mistaken for fields; the final `rule.nFields` constructor args are applied as fields;
- indices are not separately applied to the rule RHS;
- recursor universe arguments instantiate rule RHS level parameters;
- trailing recursor application arguments after major are reapplied;
- underapplied recursor remains residual;
- major with wrong/non-constructor head remains residual;
- constructor from another admitted family remains residual;
- missing rule remains residual;
- constructor application with fewer than `rule.nFields` args remains residual;
- recursor universe-arity mismatch remains residual;
- explicitly configured resource/budget behavior propagates and never calls the default wrapper.

- [ ] **Step 2: Run to prove RED**

Expected: valid recursor applications remain residual in KernelCore while mature `PSC1Kernel` performs direct-constructor reduction.

- [ ] **Step 3: Implement bounded recursor helper in `Reduce.lean`**

Use a focused helper with this semantic interface (exact internal curried form may be adjusted only for PSC1 parser/termination constraints):

```text
psKernelCoreReduceRecursorWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (expr : PsKernelCoreExpr) :
    PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreExpr)
```

Required algorithm:

```text
collect app head/args
require head const -> env .recInfo
require recursor level arity matches
compute majorIdx
require major exists
WHNF major with same reduced budget/resources
require constructor head
find matching stored rule
require constructor metadata exists and belongs to recursor target family
require enough constructor args for nFields
instantiate rule RHS with recursor levels
apply fixed args = params+motive+minors
apply final nFields constructor args
reapply args after major
return some candidate
```

Unsupported/malformed iota shapes return `ok none`, not an unrelated error. Actual WHNF/resource errors from recursively reducing the major/result propagate as errors.

- [ ] **Step 4: Integrate into the existing app-WHNF path**

Invoke the recursor helper at the bounded application point without disrupting the existing beta/Nat/Quot ordering. If it returns `some candidate`, continue through the same smaller-budget configured WHNF path. If `none`, preserve the prior ordinary/Quot residual behavior.

Do not implement K conversion, structure synthesis, literal conversion, recursive calls, or projection computation.

- [ ] **Step 5: Run reduction fixture + Phase-3/5/7/8/9 aggregates + source profile**

Expected: PASS.

### Task 5: Genuine Eq/Eq.refl direct-iota compatibility

**Interfaces:**
- Consumes: Phase-8 genuine `Eq`/`Eq.refl` admission, Phase-9 Quot-compatible equality shape, Task-2 recursor admission, Task-4 direct iota.
- Produces narrow equality-recursion compatibility evidence without K conversion.

- [ ] **Step 1: Write the Eq compatibility fixture**

Create `KernelCoreEqRecursorCompatibilityTests.lean` that:

- admits the genuine Phase-8 `Eq` / `Eq.refl` metadata;
- supplies a canonical non-K equality recursor matching the Phase-10 profile;
- admits it through `psKernelCoreAddRecursorWithResources`;
- applies it to an actual `Eq.refl` constructor major;
- compares KernelCore reduction with mature `PSC1Kernel` on the direct-constructor case.

Also include a non-constructor equality proof expression that ordinary WHNF does not turn into `Eq.refl`; assert Phase 10 leaves it residual instead of invoking K conversion.

- [ ] **Step 2: Run fixture; classify any RED**

If direct `Eq.refl` fails, determine whether the gap is in canonical metadata validation or direct-iota layout. Do not add K/synthesis behavior.

- [ ] **Step 3: Make the smallest bounded fix, if needed**

Only Phase-10 metadata/admission/iota code may change. If the fixture requires K conversion to pass, keep that case residual and document it as deferred instead of widening Phase 10.

- [ ] **Step 4: Run all Phase-10 semantic fixtures + PSC1 source profile**

Expected: PASS.

### Task 6: Permanent assurance, scope review, and acceptance preparation

**Interfaces:**
- Consumes: all Phase-10 fixtures/implementation.
- Produces: permanent aggregate CI and exact evidence head for later acceptance.

- [ ] **Step 1: Add `assurance:kernel-core:phase10`**

The command must run, in deterministic order:

```text
unchanged actual KernelCore PSC1 source/self-host profile
Phase-10 recursor metadata parity
Phase-10 recursor admission parity
Phase-10 rejection matrix
Phase-10 direct-constructor iota parity
Phase-10 Eq direct-iota compatibility
all semantic dependencies/aggregates required by Phases 1-9
report-kernel-core-size.mjs
```

Do not redefine earlier assurance commands merely to make the new aggregate pass.

- [ ] **Step 2: Add permanent workflow steps and Phase-10 branch triggers**

Modify `.github/workflows/psc2-minimal-kernel.yml` only by adding Phase-10 coverage; preserve every previous permanent gate. Remove/retire a temporary work workflow only after equivalent permanent coverage is demonstrated.

- [ ] **Step 3: Run exact-head permanent CI**

Required on one exact semantic SHA:

- Phase-1 through Phase-10 aggregate assurances PASS;
- bootstrap-closure isolation PASS;
- actual PSC1 source/self-host profile PASS;
- size reporter PASS;
- full existing `npm run check` / PSC2 regression gate PASS.

Do not claim Phase 10 complete from partial/workflow-in-progress evidence.

- [ ] **Step 4: Perform scope review against Phase-9 closeout**

Expected trusted semantic delta is limited to:

```text
Ps/KernelCore/Declaration.lean
Ps/KernelCore/Recursor.lean
Ps/KernelCore/Reduce.lean
Ps/KernelCore.lean
```

plus Phase-10 tests/assurance/docs wiring. Any recursive-inductive/IH, K, structure/literal conversion, projection, compiler/provider, mature-`PSC1Kernel`, backend, or runtime semantic change is a scope violation unless separately reviewed.

- [ ] **Step 5: Run verification-before-completion and branch review**

Inspect exact-head CI evidence and changed-file set before making success claims. If an independent reviewer is unavailable, perform an explicit requirements/diff review and say so; do not imply independent review occurred.

- [ ] **Step 6: Create `PHASE10_ACCEPTANCE.md` only after exact green evidence exists**

Record:

- exact tested semantic SHA;
- exact workflow run/job IDs;
- actual PSC1 trusted module count/source-profile result;
- size-reporter evidence;
- passed assurance commands;
- changed trusted semantic surface;
- allowed claim and explicit non-claims.

Commit the acceptance record documentation-only. Compare the acceptance commit to the tested semantic SHA and require exactly the acceptance documentation change before calling the phase formally closed.
