# PSC2 KernelCore Phase 3 Basic Reduction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a small PSC1-self-hostable basic WHNF substrate to `pskernel-core` covering metadata stripping, local-let unfolding, zeta, beta, and ordinary definition delta unfolding with universe-parameter instantiation.

**Architecture:** Add one trusted semantic module, `Ps.KernelCore.Reduce`, on top of the accepted Phase-2 `Environment` and `LocalContext`. The reducer is pure and structurally total through an explicit `Nat` budget; it uses the already accepted substitution semantics for beta/zeta and a small PSC1-native level-parameter traversal for delta bodies. Full recursor/projection/Quot/primitive/infer/defeq behavior remains outside this phase.

**Tech Stack:** Lean 4.34.0, PSC1-compatible `.lean`, Lake, Node 22/npm assurance gates, GitHub Actions.

**Spec:** `psc15selfhost/docs/superpowers/specs/2026-09-27-psc2-kernel-core-phase3-reduction-design.md`

## Global Constraints

- Work only on branch `psc2/kernel-core-phase3-reduce` until an intentional execution branch is created from it.
- Phase-3 branch base is accepted Phase-2 work head `81f8e33f60361418d2fa651cc27be90ff00e8525`.
- Phase-2 PR `#46` remains independently reviewable; do not rewrite or force-push its history.
- Trusted KernelCore source must remain PSC1-compatible `.lean` and pass the actual `psc1 check` path through `scripts/check-kernel-core-source.mjs`.
- Trusted source must not use `partial`, `unsafe`, `extern`, `implemented_by`, `IO`, `Lean.*`, `Std.*`, namespace/section conveniences, custom syntax/macros/elaborators, or performance caches/session state.
- Use kernel-local `PsKernelCoreList`, `PsKernelCoreOption`, and `PsKernelCoreResult` for trusted semantic carriers.
- Do not weaken the KernelCore source checker or any Phase-1/Phase-2 parity/regression gate.
- Basic WHNF may reduce only metadata, local let declarations, `letE`, lambda application, and ordinary `defnInfo` delta bodies.
- Axiom/theorem/opaque declarations remain residual in this phase.
- Recursor/iota, constructor projection, Quot, Nat/String/native reduction, inference/checking, defeq, proof irrelevance, eta, lazy-delta ordering, caches, and compiler `CheckedCore` integration are deferred.
- `pskernel-core` remains outside the active PSC2 bootstrap closure.
- Do not claim full Lean 4.34 WHNF parity or full Lean equivalence.

## Review Focus

- **PSC1 recursion shape:** `psKernelCoreWhnf` must structurally recurse only on `budget`; changing environment/local-context/expression arguments must be passed through a pre-bound smaller function so PSC1 does not reject varying non-recursive explicit arguments.
- **Argument laziness:** reducing an application head must not normalize the argument unless beta substitution later makes that argument the new head expression.
- **Universe arity mismatch:** delta unfolding with mismatched `levelParams` / supplied universe levels must fail closed by leaving the original constant residual; it must not partially substitute levels.
- **Deep universe substitution:** a delta body containing levels under lambdas/foralls/lets/apps/mdata/projections and constant level lists must receive the same substitution as the reference traversal.
- **Budget determinism:** budget `0` must always return exactly `reduction budget exhausted`, while sufficient-budget differential fixtures must not compare budget accounting to Lean/PSC1Kernel because the explicit budget is KernelCore-specific.

---

## File Structure

### Trusted production module

- Create `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Reduce.lean` — Phase-3 universe-instantiation helpers plus total budgeted basic WHNF.
- Modify `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean` — export `Ps.KernelCore.Reduce` only after the RED fixture exists.

### Differential test

- Create `psc15selfhost/test/KernelCoreReductionParityTests.lean` — cross-representation differential fixtures against `PSC1Kernel.TypeChecker.whnf` plus KernelCore-only budget tests.

### Build / assurance wiring

- Modify `psc15selfhost/lakefile.lean` — expose `PSC1Kernel.TypeChecker` to the reference test library and add `psc2_kernel_core_reduction_parity_tests`.
- Modify `psc15selfhost/package.json` — add `assurance:kernel-core:phase3` without changing Phase-1 or Phase-2 commands.
- Modify `.github/workflows/psc2-minimal-kernel.yml` — trigger the Phase-3 branch, run reduction parity, and run Phase-3 aggregate assurance.
- `psc15selfhost/scripts/check-kernel-core-source.mjs` should require no code change because it discovers every trusted `.lean` file recursively and runs the actual PSC1 checker on each flattened closure.
- `psc15selfhost/scripts/report-kernel-core-size.mjs` should require no code change because it discovers KernelCore source automatically.
- Create `psc15selfhost/docs/continuity/PHASE3_ACCEPTANCE.md` only after the exact implementation head passes all gates.

---

### Task 1: RED gate — Basic reduction differential fixture

**Files:**
- Create: `psc15selfhost/test/KernelCoreReductionParityTests.lean`
- Modify: `psc15selfhost/lakefile.lean`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`

**Interfaces:**
- Consumes: accepted Phase-1/2 KernelCore `Expr`, `Subst`, `Declaration`, `Environment`, `LocalContext`; reference `PSC1Kernel.TypeChecker`.
- Produces: a failing fixture that pins the complete Phase-3 public behavior before `Ps.KernelCore.Reduce` exists.

- [ ] **Step 1: Extend test-only reference/build wiring**

Add `PSC1Kernel.TypeChecker` to `PSC1KernelReferenceFoundations` roots.

Add executable:

```text
psc2_kernel_core_reduction_parity_tests -> KernelCoreReductionParityTests
```

Add `psc2/kernel-core-phase3-reduce` to the workflow push branches and add a `Basic reduction parity test` step invoking the new executable. Do not add Phase-3 aggregate assurance yet.

- [ ] **Step 2: Write cross-representation test adapters**

The test file may use ordinary Lean/reference conveniences because it is outside the TCB. Define test-only structural comparators sufficient to compare KernelCore and reference results:

```text
psKernelCoreNameMatchesReference : PsKernelCoreName -> PSC1Kernel.Name -> Bool
psKernelCoreLevelMatchesReference : PsKernelCoreLevel -> PSC1Kernel.Level -> Bool
psKernelCoreExprMatchesReference : PsKernelCoreExpr -> PSC1Kernel.Expr -> Bool
```

`psKernelCoreExprMatchesReference` may be `partial` in the test file; trusted source restrictions do not apply to test/oracle code. It must compare every expression constructor structurally, including binder modes, literals, metadata, projection type/index, and constant universe lists.

Add result adapter behavior:

```text
PsKernelCoreResult.error message  <->  Except.error message
PsKernelCoreResult.ok expr        <->  Except.ok expr
```

For parity fixtures, call KernelCore with a documented sufficient budget such as `64`; call the reference with `PSC1Kernel.whnf` using a matching `PSC1Kernel.CheckerContext`.

- [ ] **Step 3: Add matched fixture builders**

Provide test-only paired builders for:

- anonymous/string names;
- empty and populated environments;
- ordinary definitions;
- theorem/opaque/axiom declarations;
- local declarations and local let declarations;
- corresponding KernelCore/reference levels and expressions.

Use `addUnchecked` in both environments so the fixture is testing reduction, not declaration admission.

- [ ] **Step 4: Pin all required differential cases**

The fixture must compare KernelCore to `PSC1Kernel.whnf` for at least:

1. easy WHNF value unchanged;
2. metadata stripping;
3. zeta reduction of `letE`;
4. simple beta reduction;
5. nested beta reduction;
6. capture-safe beta under an inner binder, e.g. `(fun x => fun y => x) a` becomes `fun y => a`;
7. application argument remains syntactically unreduced when an irreducible head stays residual;
8. local `letDecl` fvar unfolds;
9. ordinary local fvar remains residual;
10. direct delta unfolding of a definition;
11. delta unfolding in function position enables beta;
12. delta universe substitution in a direct body;
13. universe substitution reaches nested binder children and constant universe argument lists;
14. universe arity mismatch leaves the original constant residual;
15. theorem remains residual;
16. opaque remains residual;
17. axiom remains residual;
18. missing constant remains residual;
19. projection over a non-constructor/residual child remains residual.

The argument-laziness case must place a visibly reducible term such as `mdata` or `letE` in the argument and assert that it remains there when the head is irreducible.

- [ ] **Step 5: Pin KernelCore-only budget behavior**

Add a separate assertion, not a reference-comparison assertion:

```text
psKernelCoreWhnf 0 ... expr
  == error "reduction budget exhausted"
```

Also choose one reducible expression whose insufficient positive budget deterministically reaches the same exact error. Do not claim the budget value matches Lean semantics.

- [ ] **Step 6: Run and verify RED**

Run:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_reduction_parity_tests
```

Expected: FAIL because `Ps.KernelCore.Reduce` does not exist.

All previously existing KernelCore tests should still compile independently.

- [ ] **Step 7: Commit the RED fixture**

```text
test(pskernel-core): add basic reduction parity red gate
```

---

### Task 2: GREEN — Total PSC1-native universe substitution and basic WHNF

**Files:**
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Reduce.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`

**Interfaces:**
- Consumes:

```text
psKernelCoreExprInstantiate1 : PsKernelCoreExpr -> PsKernelCoreExpr -> PsKernelCoreExpr
psKernelCoreLevelInstantiateParams : PsKernelCoreLevel -> PsKernelCoreLevelSubst -> PsKernelCoreLevel
psKernelCoreEnvironmentFind? : PsKernelCoreEnvironment -> PsKernelCoreName -> PsKernelCoreOption PsKernelCoreConstantInfo
psKernelCoreConstantInfoLevelParams : PsKernelCoreConstantInfo -> PsKernelCoreList PsKernelCoreName
psKernelCoreConstantInfoDeltaValue? : PsKernelCoreConstantInfo -> PsKernelCoreOption PsKernelCoreExpr
psKernelCoreLocalContextFind? : PsKernelCoreLocalContext -> PsKernelCoreName -> PsKernelCoreOption PsKernelCoreLocalDecl
psKernelCoreLocalDeclValue? : PsKernelCoreLocalDecl -> PsKernelCoreOption PsKernelCoreExpr
```

- Produces the following Phase-3 functions. Helper names are fixed for implementation/test stability, but only `psKernelCoreWhnf` is the documented semantic entry point for later checker phases:

```text
psKernelCoreLevelSubstFromLists
  : PsKernelCoreList PsKernelCoreName
  -> PsKernelCoreList PsKernelCoreLevel
  -> PsKernelCoreOption PsKernelCoreLevelSubst

psKernelCoreLevelListInstantiateParams
  : PsKernelCoreList PsKernelCoreLevel
  -> PsKernelCoreLevelSubst
  -> PsKernelCoreList PsKernelCoreLevel

psKernelCoreExprInstantiateLevelSubst
  : PsKernelCoreExpr
  -> PsKernelCoreLevelSubst
  -> PsKernelCoreExpr

psKernelCoreExprInstantiateLevelParams
  : PsKernelCoreExpr
  -> PsKernelCoreList PsKernelCoreName
  -> PsKernelCoreList PsKernelCoreLevel
  -> PsKernelCoreOption PsKernelCoreExpr

psKernelCoreWhnf
  : Nat
  -> PsKernelCoreEnvironment
  -> PsKernelCoreLocalContext
  -> PsKernelCoreExpr
  -> PsKernelCoreResult String PsKernelCoreExpr
```

- [ ] **Step 1: Implement exact-arity level-substitution construction**

`psKernelCoreLevelSubstFromLists` must return `some` only when parameter/value list lengths match exactly. Recurse structurally on the parameter list and curry the varying level-value list behind the smaller recursive function. Preserve parameter order in the resulting lookup spine so each parameter maps to its paired supplied level.

Review-focus tests owned here: empty/empty succeeds; one side empty while the other is non-empty returns `none`; non-empty equal-length lists map every parameter to the corresponding level.

- [ ] **Step 2: Implement level-list and expression traversal**

`psKernelCoreLevelListInstantiateParams` structurally maps `psKernelCoreLevelInstantiateParams` over kernel-local level lists.

`psKernelCoreExprInstantiateLevelSubst` must traverse all expression constructors:

- `sort`: instantiate its level;
- `const`: instantiate every supplied universe level;
- `app`, `lam`, `forallE`, `letE`, `mdata`, `proj`: recurse through expression children;
- `bvar`, `fvar`, `mvar`, literals: unchanged except their enclosing expression reconstruction when needed;
- binder names/info, free/meta names, literal values, metadata numbers, projection type names/indices, and `nondep` are unchanged.

Use structural recursion on the expression as the recursion-driving argument; curry the invariant substitution where needed for PSC1 acceptance.

`psKernelCoreExprInstantiateLevelParams` first calls `psKernelCoreLevelSubstFromLists`; on arity mismatch return `PsKernelCoreOption.none`, otherwise return the fully traversed expression.

- [ ] **Step 3: Implement total budgeted `psKernelCoreWhnf`**

The recursion shape is non-negotiable:

```text
psKernelCoreWhnf budget :=
  match budget with
  | 0 => function returning error "reduction budget exhausted"
  | succ remaining =>
      let smaller := psKernelCoreWhnf remaining
      function over env -> lctx -> expr using `smaller` for every recursive descent
```

Do not recursively call `psKernelCoreWhnf remaining env lctx changedExpr` directly if PSC1 treats changing explicit arguments as violating its recursion profile; pre-bind `smaller` and then apply it to changed values.

Implement only these rules:

- `mdata _ body` -> `smaller ... body`;
- `fvar name` -> if newest local declaration is a let, `smaller ... value`, otherwise residual original fvar;
- `letE _ _ value body _` -> instantiate body with `psKernelCoreExprInstantiate1 body value`, then `smaller`;
- `app fn arg` -> reduce only `fn` with `smaller`; if result is a lambda, instantiate its body with the untouched `arg` and continue with `smaller`; otherwise rebuild `app reducedFn arg` without reducing `arg`;
- `const name levels` -> find environment declaration; only when `deltaValue?` exists and exact-arity universe instantiation succeeds, continue with `smaller` on the instantiated value; otherwise return the original constant;
- all other Phase-3-residual constructors -> return unchanged.

Do not add application-spine flattening, recursor/projection computation, Nat/String/native primitives, infer/defeq callbacks, caches, or checker state.

- [ ] **Step 4: Export `Reduce` from the aggregate module**

Append:

```lean
import Ps.KernelCore.Reduce
```

to `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`.

- [ ] **Step 5: Run differential parity GREEN**

Run:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_reduction_parity_tests
```

Expected:

```text
PSC2_KERNEL_CORE_REDUCTION_PARITY: PASS
```

The executable must separately fail with a useful message if the differential subset fails versus if the budget property fails.

- [ ] **Step 6: Verify actual PSC1 self-hostability**

Run:

```bash
npm run check:kernel-core-source
```

Expected: every KernelCore module including `Reduce.lean` reports `KERNEL_CORE_SELFHOST_CHECK: PASS`; aggregate count increases from 9 to 10 trusted `.lean` modules.

If PSC1 rejects syntax/recursion that Lean accepts, rewrite only the source shape while preserving the already-green differential behavior. Do not loosen the source checker.

- [ ] **Step 7: Re-run prior phase assurances unchanged**

Run:

```bash
npm run assurance:kernel-core:phase1
npm run assurance:kernel-core:phase2
```

Expected: both PASS with their existing semantic gates unchanged.

- [ ] **Step 8: Commit the GREEN semantic slice**

```text
feat(pskernel-core): add basic budgeted whnf
```

---

### Task 3: Phase-3 aggregate assurance and CI integration

**Files:**
- Modify: `psc15selfhost/package.json`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`

**Interfaces:**
- Consumes: Task-2 green `psc2_kernel_core_reduction_parity_tests` and all Phase-1/2 assurance commands.
- Produces: `npm run assurance:kernel-core:phase3` and an exact CI step that executes it.

- [ ] **Step 1: Add Phase-3 aggregate command without editing earlier aggregates**

Add exactly one new script:

```text
assurance:kernel-core:phase3
```

Its command order must be:

1. `npm run check:kernel-core-source`
2. boundary test
3. Name parity
4. Level parity
5. Expr parity
6. Substitution parity
7. Declaration parity
8. Environment parity
9. LocalContext parity
10. reduction parity
11. `node scripts/report-kernel-core-size.mjs`

Do not edit `assurance:kernel-core:phase1` or `assurance:kernel-core:phase2` except to repair accidental transcription drift if a diff proves it was introduced by this phase.

- [ ] **Step 2: Add Phase-3 aggregate CI step**

After the Phase-2 aggregate step, add:

```text
Phase 3 aggregate assurance
  cd psc15selfhost
  npm run assurance:kernel-core:phase3
```

Keep the full existing PSC2 regression gate after all KernelCore aggregates.

- [ ] **Step 3: Verify the aggregate locally / through the current execution environment**

Run:

```bash
cd psc15selfhost
npm run assurance:kernel-core:phase3
```

Expected: every listed gate PASS and the size reporter completes successfully.

- [ ] **Step 4: Run full repository regression**

Run:

```bash
npm run check
```

Expected: PASS with no skipped or weakened existing tests.

- [ ] **Step 5: Inspect the net diff for unrelated drift**

Compare against the Task-2 semantic checkpoint. The intended net changes in this task are only:

- one new `package.json` script;
- Phase-3 workflow branch/test/aggregate wiring already planned in Tasks 1 and 3.

Repair any accidental unrelated script/workflow mutation before committing.

- [ ] **Step 6: Commit assurance wiring**

```text
ci(pskernel-core): add Phase 3 reduction assurance
```

---

### Task 4: Exact-head CI evidence and acceptance record

**Files:**
- Create: `psc15selfhost/docs/continuity/PHASE3_ACCEPTANCE.md`

**Interfaces:**
- Consumes: exact green implementation/assurance head from Tasks 1-3.
- Produces: a durable evidence record; no semantic code changes.

- [ ] **Step 1: Obtain fresh exact-head CI evidence**

Require the `PSC2 minimal kernel` workflow for the exact implementation/assurance SHA to complete successfully.

The successful job must show PASS for:

- boundary;
- Name/Level/Expr/Subst parity;
- Declaration/Environment/LocalContext parity;
- basic reduction parity;
- bootstrap closure isolation;
- actual KernelCore PSC1 source profile;
- Phase-1 aggregate;
- Phase-2 aggregate;
- Phase-3 aggregate;
- existing full `npm run check` regression gate.

Do not use an older green run from another SHA as acceptance evidence.

- [ ] **Step 2: Capture size evidence from the same tested head**

Record exactly what `report-kernel-core-size.mjs` emits, including:

- trusted `.lean` file count (expected 10 if only `Reduce.lean` is added);
- trusted source bytes;
- trusted nonblank/noncomment LOC;
- comparable `PSC1Kernel` baseline figures;
- byte and LOC ratios.

Do not convert the ratio into a claim about a completed full kernel; Phase 3 still lacks major semantic surfaces.

- [ ] **Step 3: Write `PHASE3_ACCEPTANCE.md`**

The record must include:

- phase purpose and exact scope;
- exact tested implementation/assurance commit SHA;
- exact CI run/job IDs;
- all required green gates;
- size evidence;
- the source/self-host constraint and 10-module trusted closure;
- explicit statement that `pskernel-core` remains outside active bootstrap admission;
- explicit deferred semantics: infer/check, defeq, recursor/iota, constructor projection, Quot, primitive Nat/String/native behavior, proof irrelevance/eta/lazy delta, corpus parity, compiler provider integration;
- explicit non-claim of full Lean 4.34 WHNF/equivalence.

If the acceptance document is committed after the tested implementation head, state that its commit is documentation-only relative to the tested head and verify the diff contains no code/config change.

- [ ] **Step 4: Commit the acceptance record**

```text
docs(pskernel-core): accept Phase 3 basic reduction
```

- [ ] **Step 5: Verify documentation-only delta**

Compare the acceptance commit to the tested implementation head. Expected: exactly `PHASE3_ACCEPTANCE.md` is added; no trusted code, tests, scripts, Lake config, package config, or workflow semantics differ.

---

## Completion Criteria

Phase 3 is complete only when all of the following are true on the recorded tested implementation head:

```text
KernelCore boundary                         PASS
Name parity                                 PASS
Level parity                                PASS
Expr parity                                 PASS
Substitution parity                         PASS
Declaration parity                          PASS
Environment parity                          PASS
LocalContext parity                         PASS
Basic reduction/WHNF parity                 PASS
Bootstrap closure isolation                 PASS
Actual PSC1 self-host source profile        PASS
Phase-1 aggregate assurance                 PASS
Phase-2 aggregate assurance                 PASS
Phase-3 aggregate assurance                 PASS
Full existing npm run check                 PASS
```

The valid completion claim is limited to the spec's basic reduction subset under sufficient explicit budget. Starting inference/checking is a separate phase and must not be smuggled into Phase 3 to resolve deferred reduction cases.
