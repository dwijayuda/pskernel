# PSC2 KernelCore Phase 11 Recursive Inductives Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a PSC1-self-hostable, fail-closed admission path for strictly-positive single-family recursive inductives, including direct and positive functional recursive fields, without adding recursive recursor/IH semantics.

**Architecture:** Keep accepted Phase 8 non-recursive admission unchanged and add a sibling trusted module `Ps.KernelCore.RecursiveInductive`. The new module reuses the existing closed inductive/constructor metadata, performs bounded WHNF-based recursive-field classification, derives final `isRec` / `isReflexive`, and transactionally returns a replacement environment only after every constructor passes. Detailed recursive-field shape stays transient/re-derivable from admitted closed constructor types; only the existing canonical recursion flags are persisted.

**Tech Stack:** Lean 4.34.0, PSC1-subset `.lean`, Lake, Node/npm assurance scripts, GitHub Actions, mature `PSC1Kernel` as bounded differential oracle.

**Spec:** `psc15selfhost/docs/superpowers/specs/2026-09-29-psc2-kernel-core-phase11-recursive-inductive-design.md`

## Global Constraints

- Trusted KernelCore source remains PSC1-subset `.lean` and must pass the actual flattened `psc1 check` path.
- Do not add trusted `partial`, `unsafe`, `extern`, `implemented_by`, `IO`, Lean/Std implementation dependencies, custom macros/elaborators, `mutual`, or host semantic caches/sessions/replay state.
- Keep the family profile single-family only: `all = [base.name]`, `numNested = 0`, input `isRec = false`, input `isReflexive = false`.
- Support direct recursive fields and functional recursive fields whose function-domain binders are non-recursive and whose final codomain is the same family.
- Support multiple independently valid recursive fields in one constructor.
- Require exact recursive universe arguments, uniform parameters, correct index arity, and recursive indices free of the target family.
- Reject negative, nested, nonuniform, wrong-universe, recursive-index, malformed, mutual, and nested-family recursion fail-closed.
- Derive final `isRec` and `isReflexive`; never trust caller-provided true flags.
- Do not add recursive recursor generation, IH generation/validation, recursive iota, mutual/nested inductives, general positivity, K, projections, literal conversion, or compiler `CheckedCore` cutover.
- Preserve all permanent Phase 1–10 gates and the full existing PSC2 regression suite.

## Review Focus

1. **Target hidden behind reduction:** a field whose WHNF becomes a valid recursive family application must be classified consistently with the mature bounded oracle, without accepting arbitrary nested recursion. Covered in Task 1 reduction-shape tests.
2. **Negative occurrence inside a functional field:** any recursive occurrence in a function-domain binder must reject even when the final codomain is recursive. Covered in Task 3 rejection tests.
3. **Uniform parameters under binder depth:** recursive uses must reference the original family parameters in canonical de Bruijn order after constructor/function binders are introduced. Covered in Tasks 1 and 3.
4. **Coordinated forged recursion flags:** callers supplying `isRec = true` or `isReflexive = true` must be rejected rather than treated as evidence. Covered in Task 3.
5. **Transactional failure after earlier constructors passed:** rejection of a later constructor must not expose the provisional family or earlier constructors through a returned environment. Covered in Task 3.

---

## File Structure

**Create**
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/RecursiveInductive.lean` — transient recursive-field classifier, constructor summary, and recursive-family admission API.
- `psc15selfhost/test/KernelCoreRecursiveInductiveShapeTests.lean` — direct/functional/multiple/indexed recursive-field shape tests.
- `psc15selfhost/test/KernelCoreRecursiveInductiveAdmissionParityTests.lean` — accepted declaration + resulting metadata parity against bounded `PSC1Kernel` behavior.
- `psc15selfhost/test/KernelCoreRecursiveInductiveRejectionTests.lean` — strict-positivity, uniformity, forged-flag, and transactional rejection matrix.
- `.github/workflows/psc2-kernel-core-phase11-work.yml` — focused work-branch gate.
- `psc15selfhost/docs/continuity/PHASE11_ACCEPTANCE.md` — only after exact green acceptance evidence exists.

**Modify**
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean` — export `Ps.KernelCore.RecursiveInductive` after `Inductive` and before later consumers.
- `psc15selfhost/package.json` — add `assurance:kernel-core:phase11` without weakening Phase 1–10 scripts.
- `.github/workflows/psc2-minimal-kernel.yml` — add Phase-11 branches, three permanent Phase-11 tests, and Phase-11 aggregate assurance.

**Intentionally unchanged**
- `Ps.KernelCore.Declaration` — no new persistent recursive-field schema in Phase 11.
- `Ps.KernelCore.Recursor` / `Reduce` — recursive IH/recursor/iota semantics remain Phase 12+.
- mature `PSC1Kernel` reference semantics.

---

### Task 1: Trusted recursive-field classifier

**Files:**
- Create: `psc15selfhost/test/KernelCoreRecursiveInductiveShapeTests.lean`
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/RecursiveInductive.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`

**Interfaces:**
- Consumes:
  - `psKernelCoreWhnfWithResources : Nat -> PsKernelCoreResourceConfig -> PsKernelCoreEnvironment -> PsKernelCoreLocalContext -> PsKernelCoreExpr -> PsKernelCoreResult String PsKernelCoreExpr`
  - Phase-8 helpers `psKernelCoreExprContainsConstName`, `psKernelCoreExprAppHead`, `psKernelCoreExprAppArgs`, `psKernelCoreInductiveResultMatches`, and existing KernelCore local list/option/result carriers.
- Produces:
  - `structure PsKernelCoreRecursiveFieldShape where argCount : Nat; indices : PsKernelCoreList PsKernelCoreExpr`
  - `structure PsKernelCoreRecursiveConstructorSummary where isRec : Bool; isReflexive : Bool`
  - `psKernelCoreRecursiveFieldShapeWithResources (budget : Nat) (resources : PsKernelCoreResourceConfig) (env : PsKernelCoreEnvironment) (target : PsKernelCoreName) (levels : PsKernelCoreList PsKernelCoreLevel) (numParams : Nat) (numIndices : Nat) (binderDepth : Nat) (fieldType : PsKernelCoreExpr) : PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreRecursiveFieldShape)`
  - `psKernelCoreAnalyzeRecursiveConstructorWithResources (budget : Nat) (resources : PsKernelCoreResourceConfig) (env : PsKernelCoreEnvironment) (info : PsKernelCoreInductiveInfo) (levels : PsKernelCoreList PsKernelCoreLevel) (ctor : PsKernelCoreConstructorInfo) : PsKernelCoreResult String PsKernelCoreRecursiveConstructorSummary`

- [ ] **Step 1: Write the failing recursive-shape tests**

Pin these cases in `KernelCoreRecursiveInductiveShapeTests.lean` before the production module exists:

- direct recursive field `T params indices` -> `some { argCount := 0, ... }`;
- two valid direct recursive fields in the same constructor -> constructor summary `isRec = true`, `isReflexive = false`;
- functional field `(x : A) -> T params indices` with target-free `A` -> `argCount = 1` and `isReflexive = true`;
- two functional binders -> `argCount = 2`;
- non-recursive field -> `none`;
- indexed direct recursion preserves the expected target-free indices;
- a transparent definition whose WHNF is a valid direct/functional recursive field is classified the same as the reduced shape;
- uniform parameter matching is checked at the correct binder depth.

- [ ] **Step 2: Run the fixture and verify RED**

Run:

```bash
cd psc15selfhost
lake env lean --run test/KernelCoreRecursiveInductiveShapeTests.lean
```

Expected: FAIL because `Ps.KernelCore.RecursiveInductive` / classifier interfaces do not exist.

- [ ] **Step 3: Implement the minimal classifier**

Create `RecursiveInductive.lean` importing only KernelCore modules, using these rules:

- WHNF the field type through `psKernelCoreWhnfWithResources` and the existing explicit budget/resources;
- if the reduced shape is exactly the target family with exact levels/uniform params/index arity and target-free indices, return a direct shape;
- if the reduced shape is `forallE`, require the binder domain to be target-free, then recurse into the codomain and increment `argCount` only when that codomain ultimately classifies recursive;
- if original or reduced type contains the target but is neither valid direct nor valid functional recursion, return a dedicated error (nested/unsupported recursive occurrence);
- otherwise return `PsKernelCoreOption.none`;
- constructor traversal skips the declared constructor parameter binders, classifies each remaining field, and ORs summaries across all fields.

Do not use `partial`; shape recursive helpers so the structural expression/telescope argument is the decreasing argument and changing depth/count values are curried/captured according to established PSC1 patterns.

- [ ] **Step 4: Export the module**

Add:

```lean
import Ps.KernelCore.RecursiveInductive
```

to `Ps/KernelCore.lean` immediately after `Ps.KernelCore.Inductive`.

- [ ] **Step 5: Verify GREEN + PSC1 source acceptance**

Run:

```bash
cd psc15selfhost
lake env lean --run test/KernelCoreRecursiveInductiveShapeTests.lean
node scripts/check-kernel-core-source.mjs
```

Expected: shape fixture PASS and `KERNEL_CORE_SOURCE_PROFILE: PASS` with the module count increased by one.

- [ ] **Step 6: Commit**

```bash
git add psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/RecursiveInductive.lean \
        psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean \
        psc15selfhost/test/KernelCoreRecursiveInductiveShapeTests.lean
git commit -m "feat(pskernel-core): classify recursive inductive fields"
```

---

### Task 2: Recursive-family admission and derived metadata

**Files:**
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/RecursiveInductive.lean`
- Create: `psc15selfhost/test/KernelCoreRecursiveInductiveAdmissionParityTests.lean`

**Interfaces:**
- Consumes Task-1 classifiers and existing Phase-8 metadata/header/result helpers.
- Produces:
  - `psKernelCoreAddRecursiveInductiveWithResources (budget : Nat) (resources : PsKernelCoreResourceConfig) (env : PsKernelCoreEnvironment) (info : PsKernelCoreInductiveInfo) (constructors : PsKernelCoreList PsKernelCoreConstructorInfo) : PsKernelCoreResult String PsKernelCoreEnvironment`
  - `psKernelCoreAddRecursiveInductive (budget : Nat) (env : PsKernelCoreEnvironment) (info : PsKernelCoreInductiveInfo) (constructors : PsKernelCoreList PsKernelCoreConstructorInfo) : PsKernelCoreResult String PsKernelCoreEnvironment`

- [ ] **Step 1: Write the failing positive admission parity fixture**

Compare only bounded observable admission semantics against `PSC1Kernel.Kernel.addSimpleInductive`; do **not** compare the mature oracle's generated recursor because recursive recursor generation is out of Phase-11 scope.

Pin:

- list-style direct recursion accepted;
- one constructor with two direct recursive fields accepted;
- positive functional recursive field accepted;
- indexed recursive family with target-free indices accepted;
- family/constructor names present in returned KernelCore environment;
- final family `isRec = true` when any recursive field exists;
- final family `isReflexive = true` iff at least one accepted recursive field has one or more functional arguments;
- non-recursive Phase-8 shape through the new API remains `false/false` if the API is intentionally allowed to cover it; otherwise keep that case on the existing Phase-8 API and assert Phase-8 regression separately.

- [ ] **Step 2: Verify RED**

Run:

```bash
cd psc15selfhost
lake env lean --run test/KernelCoreRecursiveInductiveAdmissionParityTests.lean
```

Expected: FAIL because the recursive admission API does not exist.

- [ ] **Step 3: Implement transactional recursive admission**

The implementation must:

1. require the same single-family/header/list/name/safety/universe constraints as Phase 8;
2. require caller input `isRec = false` and `isReflexive = false` through the existing canonical metadata check;
3. add a provisional family entry only to a local immutable work environment;
4. for each constructor, preserve Phase-8 ownership/order/parameter/safety/universe/field-count/final-result checks and ordinary type checking;
5. call Task-1 recursive analysis for constructor fields instead of the Phase-8 blanket recursive-occurrence rejection;
6. aggregate `isRec` / `isReflexive` across constructors;
7. after every constructor succeeds, replace the provisional family entry with a final `PsKernelCoreInductiveInfo` carrying the derived flags via `psKernelCoreEnvironmentReplaceUnchecked`;
8. return only the final environment; errors return no partially built environment.

Keep the existing `psKernelCoreAddNonRecursiveInductive*` APIs unchanged.

- [ ] **Step 4: Verify positive parity + Phase-8 preservation**

Run:

```bash
cd psc15selfhost
lake env lean --run test/KernelCoreRecursiveInductiveAdmissionParityTests.lean
lake exe psc2_kernel_core_inductive_admission_parity_tests
lake env lean --run test/KernelCoreInductiveRejectionTests.lean
lake exe psc2_kernel_core_eq_inductive_tests
node scripts/check-kernel-core-source.mjs
```

Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/RecursiveInductive.lean \
        psc15selfhost/test/KernelCoreRecursiveInductiveAdmissionParityTests.lean
git commit -m "feat(pskernel-core): admit bounded recursive inductives"
```

---

### Task 3: Strict-positivity and fail-closed rejection matrix

**Files:**
- Create: `psc15selfhost/test/KernelCoreRecursiveInductiveRejectionTests.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/RecursiveInductive.lean` only if RED cases expose a missing fail-closed condition.

**Interfaces:**
- Consumes Task-2 admission API.
- Produces no new public semantic API unless a missing predicate is required to express the reviewed rules.

- [ ] **Step 1: Write the rejection matrix before hardening changes**

Pin exact rejection for:

- target in a functional-domain binder (negative position);
- target nested under another type constructor;
- target inside recursive result indices;
- recursive use with a nonuniform parameter;
- wrong recursive universe arguments;
- wrong recursive parameter count;
- wrong recursive index arity;
- malformed functional recursive chain;
- input `isRec = true`;
- input `isReflexive = true`;
- later-constructor failure after an earlier constructor would otherwise pass;
- a failed call leaves the original immutable environment's size/lookups unchanged.

Where mature `PSC1Kernel.addSimpleInductive` covers the same shape, assert accept/reject parity. For KernelCore-specific canonical-input flag rejection, assert the Phase-11 contract directly.

- [ ] **Step 2: Run and confirm any intended RED cases**

Run:

```bash
cd psc15selfhost
lake env lean --run test/KernelCoreRecursiveInductiveRejectionTests.lean
```

Expected before any necessary hardening: at least all already-covered cases PASS; any missing guard must fail at its named assertion rather than through an unrelated parser/type error.

- [ ] **Step 3: Add only the minimal missing fail-closed guards**

Do not broaden accepted recursion. Diagnostics should distinguish at least:

- negative recursive occurrence;
- nested/unsupported recursive occurrence;
- invalid recursive result/index/parameter/universe shape;
- unsupported/forged inductive metadata.

- [ ] **Step 4: Verify the full recursive-inductive slice and permanent prior phases**

Run:

```bash
cd psc15selfhost
lake env lean --run test/KernelCoreRecursiveInductiveShapeTests.lean
lake env lean --run test/KernelCoreRecursiveInductiveAdmissionParityTests.lean
lake env lean --run test/KernelCoreRecursiveInductiveRejectionTests.lean
npm run assurance:kernel-core:phase10
node scripts/check-kernel-core-source.mjs
```

Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/RecursiveInductive.lean \
        psc15selfhost/test/KernelCoreRecursiveInductiveRejectionTests.lean
git commit -m "test(pskernel-core): harden recursive inductive positivity"
```

---

### Task 4: Permanent Phase-11 assurance and CI

**Files:**
- Modify: `psc15selfhost/package.json`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`
- Create: `.github/workflows/psc2-kernel-core-phase11-work.yml`

**Interfaces:**
- Consumes all Task 1–3 test files and existing Phase-10 assurance.
- Produces permanent command `npm run assurance:kernel-core:phase11`.

- [ ] **Step 1: Add the Phase-11 aggregate script**

Add exactly one new script without altering Phase 1–10 commands:

```text
assurance:kernel-core:phase11
  = assurance:kernel-core:phase10
  + recursive-inductive shape tests
  + recursive-inductive admission parity
  + recursive-inductive rejection matrix
  + check:kernel-core-source
  + report-kernel-core-size
```

Use `lake env lean --run` for all three new fixtures; no Lake executable target is required.

- [ ] **Step 2: Extend the permanent minimal-kernel workflow**

Add branch triggers:

```text
psc2/kernel-core-phase11-recursive-inductive
psc2/kernel-core-phase11-recursive-inductive-work
```

Add permanent steps after Phase 10 recursor/Eq compatibility and before bootstrap/source/aggregate closeout:

```text
Phase 11 recursive inductive shape
Phase 11 recursive inductive admission parity
Phase 11 recursive inductive rejection matrix
```

Add `Phase 11 aggregate assurance` after the Phase-10 aggregate.

- [ ] **Step 3: Add the focused Phase-11 work workflow**

Create `.github/workflows/psc2-kernel-core-phase11-work.yml` for `psc2/kernel-core-phase11-recursive-inductive-work` with:

- Lean 4.34.0 + Node 22 setup;
- `lake build PsKernelCore PSC1KernelReferenceFoundations`;
- three Phase-11 fixtures;
- existing Phase-8 inductive regression gates;
- Phase-10 recursor compatibility/rejection gates relevant to declaration metadata;
- actual `node scripts/check-kernel-core-source.mjs`;
- `npm run assurance:kernel-core:phase11`.

- [ ] **Step 4: Verify locally/through branch CI**

Run:

```bash
cd psc15selfhost
npm run assurance:kernel-core:phase11
npm run check
```

Expected: both exit 0.

Then require the exact implementation/assurance commit to have a successful `PSC2 minimal kernel` run before acceptance documentation is written.

- [ ] **Step 5: Commit**

```bash
git add psc15selfhost/package.json \
        .github/workflows/psc2-minimal-kernel.yml \
        .github/workflows/psc2-kernel-core-phase11-work.yml
git commit -m "ci(pskernel-core): gate Phase 11 recursive inductives"
```

---

### Task 5: Verification, acceptance record, and integration handoff

**Files:**
- Create: `psc15selfhost/docs/continuity/PHASE11_ACCEPTANCE.md`
- No semantic source changes after the accepted implementation SHA.

**Interfaces:**
- Consumes exact green CI evidence from Task 4.
- Produces the durable accepted Phase-11 checkpoint and handoff metadata.

- [ ] **Step 1: Perform final scope review**

Compare the Phase-10 accepted head against the Phase-11 implementation head and confirm semantic changes are limited to:

- new recursive-inductive trusted module + aggregate import;
- Phase-11 fixtures;
- Phase-11 assurance/CI wiring.

Confirm no recursive recursor/IH/iota, mutual/nested, compiler provider, or backend semantics entered the diff.

- [ ] **Step 2: Capture fresh verification evidence**

Record from the exact implementation SHA:

- successful permanent workflow run ID + job ID;
- successful focused Phase-11 run ID + job ID if available;
- Lean 4.34.0;
- `KERNEL_CORE_SOURCE_PROFILE: PASS` module count;
- Phase 1–11 aggregate PASS;
- full `npm run check` PASS;
- exact size reporter output if printed on the accepted run.

Do not infer or reuse stale metrics.

- [ ] **Step 3: Write `PHASE11_ACCEPTANCE.md`**

Document:

- status `accepted`;
- planning branch and execution branch;
- exact implementation/assurance SHA;
- documentation-only acceptance commit distinction;
- accepted direct + functional recursive surface;
- exact rejection matrix;
- derived recursion flags;
- self-host/source evidence;
- allowed claims;
- explicit non-claims;
- recommended Phase 12: recursive recursor/IH validation + recursive iota using the trusted Phase-11 classifier.

- [ ] **Step 4: Verify documentation-only delta**

Compare acceptance-doc commit to the tested implementation SHA and confirm only `PHASE11_ACCEPTANCE.md` changed.

- [ ] **Step 5: Commit and hand off through a PR**

```bash
git add psc15selfhost/docs/continuity/PHASE11_ACCEPTANCE.md
git commit -m "docs(pskernel-core): freeze Phase 11 acceptance"
```

Open an integration PR from `psc2/kernel-core-phase11-recursive-inductive-work` to `psc2/kernel-core-phase11-recursive-inductive`; do not merge automatically unless explicitly requested.
