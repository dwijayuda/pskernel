# PSC2 KernelCore Phase 5 Minimal Definitional Equality Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a PSC1-self-hostable minimal definitional-equality substrate to `pskernel-core`, with direct differential evidence against `PSC1Kernel.isDefEq` for the accepted Phase-5 overlap and without importing deferred inductive, Quot, native, primitive, or checker-cache semantics.

**Architecture:** First add the trusted `Expr.eqv`-compatible structural equality needed by the DefEq fast path. Then add one total, budgeted `Ps.KernelCore.DefEq` module that uses the accepted Phase-3 WHNF and Phase-4 infer-only layers, followed by a Phase-5 aggregate assurance gate and exact-head acceptance evidence.

**Tech Stack:** Lean 4.34.0, PSC1-compatible `.lean`, Lake, Node 22/npm assurance gates, GitHub Actions.

**Spec:** `psc15selfhost/docs/superpowers/specs/2026-09-27-psc2-kernel-core-phase5-defeq-design.md`

## Global Constraints

- Start from reviewed branch `psc2/kernel-core-phase5-defeq`, based on verified Phase-4 merge `c195a366657ef5775f608f1689fba218ed01855c`.
- At execution time create isolated branch `psc2/kernel-core-phase5-defeq-work`; do not rewrite or force-push the reviewed spec/plan branch.
- Trusted KernelCore source remains PSC1-compatible `.lean` and must pass the real `psc1 check` path through `scripts/check-kernel-core-source.mjs`.
- Trusted source must not use `partial`, `unsafe`, `extern`, `implemented_by`, IO, `Lean.*`, `Std.*`, namespace/section conveniences, custom syntax/macros/elaborators, host collection semantic storage, or performance caches/session state.
- Use KernelCore-local `PsKernelCoreList`, `PsKernelCoreOption`, and `PsKernelCoreResult` for semantic carriers.
- Preserve every Phase-1/2/3/4 parity, bootstrap-isolation, source-profile, size, and repository regression gate unchanged.
- Phase 5 does not implement exact lazy-delta scheduling, structure eta, projection computation, recursor/iota, Quot, native evaluation, String-constructor expansion, unit-like structure equality, checked inference, declaration admission, or compiler `CheckedCore` integration.
- Residual non-identical projections that require deferred inductive metadata must fail closed with exactly `projection definitional equality unavailable before inductive metadata`.
- DefEq budget `0` must return exactly `defeq budget exhausted` before structural equality is considered.
- For `psKernelCoreIsDefEq (Nat.succ remaining)`, recursive DefEq calls and required lower-layer WHNF/inference work receive exactly `remaining`.
- Do not claim full Lean 4.34 DefEq or formal equivalence from this phase.

## Review Focus

- **Alpha-equivalent structural fast path:** lambda/forall display names and binder annotations are ignored by `Expr.eqv`-compatible structural equality, while metadata payloads and `letE.nondep` remain structural.
- **Proof irrelevance error discipline:** lower-layer inference/WHNF errors required to establish proof irrelevance propagate; they are never reinterpreted as `false` or `true`.
- **Function eta symmetry:** both `fun x => f x ≡ f` and `f ≡ fun x => f x` must work when `f` has a function type, while a successfully inferred non-function does not become equal by eta.
- **Deferred projection safety:** identical projections may pass the structural fast path, but any residual non-identical projection comparison fails closed instead of trusting unvalidated metadata.
- **Budget determinism:** budget `0` fails even for reflexive terms, while the exact same reflexive term succeeds at budget `1`; recursive and lower-layer work use only the documented `remaining` budget.

---

## File Structure

### Trusted production changes

- Modify `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Expr.lean` — add structural list/literal/expression equality matching mature `PSC1Kernel.Expr.eq`.
- Create `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/DefEq.lean` — total budgeted Phase-5 DefEq semantics.
- Modify `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean` — export `Ps.KernelCore.DefEq` only after the DefEq RED gate exists.

### Differential tests

- Modify `psc15selfhost/test/KernelCoreExprParityTests.lean` — pin the new structural-equality helper directly against `PSC1Kernel.Expr.eq`.
- Create `psc15selfhost/test/KernelCoreDefEqParityTests.lean` — paired environment/local-context fixtures and direct DefEq comparison with `PSC1Kernel.isDefEq`, plus KernelCore-only budget/projection boundary cases.

### Build / assurance wiring

- Modify `psc15selfhost/lakefile.lean` — add executable `psc2_kernel_core_defeq_parity_tests` rooted at `KernelCoreDefEqParityTests`. `PSC1Kernel.TypeChecker` is already a reference-library root and exposes the mature oracle.
- Modify `.github/workflows/psc2-minimal-kernel.yml` — trigger Phase-5 reviewed/work branches, add DefEq parity after inference parity, and later add Phase-5 aggregate assurance.
- Modify `psc15selfhost/package.json` — add `assurance:kernel-core:phase5` without changing Phase-1/2/3/4 commands.
- `scripts/check-kernel-core-source.mjs` and `scripts/report-kernel-core-size.mjs` require no planned code change; both recursively discover trusted KernelCore source.
- Create `psc15selfhost/docs/continuity/PHASE5_ACCEPTANCE.md` only after the exact implementation/assurance head is fully green.

---

### Task 1: RED — Trusted expression structural equality

**Files:**
- Modify: `psc15selfhost/test/KernelCoreExprParityTests.lean`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`

**Interfaces:**
- Consumes: accepted `PsKernelCoreExpr`, `PsKernelCoreLevel`, `PsKernelCoreName` representations and mature `PSC1Kernel.Expr.eq`.
- Produces: a failing direct-parity gate for the not-yet-existing `psKernelCoreExprEq` helper.

- [ ] **Step 1: Add Phase-5 execution branch triggers**

Add push branches:

```text
psc2/kernel-core-phase5-defeq
psc2/kernel-core-phase5-defeq-work
```

Do not add the DefEq executable or Phase-5 aggregate yet.

- [ ] **Step 2: Extend the existing expression parity fixture with the missing helper**

Call the exact not-yet-existing interface:

```text
psKernelCoreExprEq
  (left : PsKernelCoreExpr) : PsKernelCoreExpr -> Bool
```

Compare its result with `PSC1Kernel.Expr.eq` through existing test adapters.

Pin at least these cases:

1. each leaf constructor, including unequal leaves;
2. structurally equal and unequal level lists on constants;
3. nested applications;
4. lambda/forall with different display names but equal type/body -> `true`;
5. lambda/forall with different binder info but equal type/body -> `true`;
6. lambda/forall body/type difference -> `false`;
7. `letE` display name difference is ignored;
8. `letE.nondep` difference -> `false`;
9. equal/different Nat and UTF-8 String literals;
10. `mdata` metadata difference -> `false` even with equal child;
11. projection type-name/index/child differences -> `false`;
12. structurally different but universe-equivalent levels remain structurally unequal here.

- [ ] **Step 3: Verify RED**

Run:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_expr_parity_tests
```

Expected: FAIL because `psKernelCoreExprEq` does not exist. Existing earlier parity executables remain independently buildable.

- [ ] **Step 4: Commit the RED fixture**

```text
test(pskernel-core): add expr structural equality red gate
```

---

### Task 2: GREEN — `Expr.eqv`-compatible structural equality

**Files:**
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Expr.lean`
- Test: `psc15selfhost/test/KernelCoreExprParityTests.lean`

**Interfaces:**
- Consumes: `psKernelCoreNameEq`, `psKernelCoreStringEq`, `psKernelCoreLevelEq`, KernelCore local lists.
- Produces:

```text
psKernelCoreBoolEq
  (left : Bool) : Bool -> Bool

psKernelCoreLiteralEq
  (left : PsKernelCoreLiteral) : PsKernelCoreLiteral -> Bool

psKernelCoreLevelListEq
  (left : PsKernelCoreList PsKernelCoreLevel) :
  PsKernelCoreList PsKernelCoreLevel -> Bool

psKernelCoreExprEq
  (left : PsKernelCoreExpr) : PsKernelCoreExpr -> Bool
```

`psKernelCoreExprEq` uses the left expression as the structural recursive argument and curries the right expression, matching the established PSC1 recursion pattern.

- [ ] **Step 1: Implement the four helpers minimally**

Match mature `PSC1Kernel.Expr.eq` exactly on the accepted representation:

- lambda/forall: compare only type and body; ignore display name and binder info;
- let: compare type/value/body and `nondep`; ignore display name;
- metadata payload remains structural;
- projection type name/index/child remain structural;
- constant level lists use structural `psKernelCoreLevelEq`, not universe equivalence.

- [ ] **Step 2: Run direct expression parity GREEN**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_expr_parity_tests
```

Expected marker remains:

```text
PSC2_KERNEL_CORE_EXPR_PARITY: PASS
```

- [ ] **Step 3: Run actual PSC1 source acceptance immediately**

```bash
cd psc15selfhost
node scripts/check-kernel-core-source.mjs
```

Expected final marker:

```text
KERNEL_CORE_SOURCE_PROFILE: PASS
```

If Lean accepts a recursive form PSC1 rejects, rewrite the recursion; do not weaken the source gate.

- [ ] **Step 4: Re-run accepted lower-layer assurance**

```bash
cd psc15selfhost
npm run assurance:kernel-core:phase4
npm run check
```

Expected: both commands succeed.

- [ ] **Step 5: Commit**

```text
feat(pskernel-core): add expr structural equality
```

---

### Task 3: RED — Minimal DefEq differential matrix

**Files:**
- Create: `psc15selfhost/test/KernelCoreDefEqParityTests.lean`
- Modify: `psc15selfhost/lakefile.lean`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`

**Interfaces:**
- Consumes: accepted KernelCore Environment/LocalContext/Reduce/Infer semantics, completed Task-2 `psKernelCoreExprEq`, and mature `PSC1Kernel.isDefEq : CheckerContext -> Expr -> Expr -> Except String Bool`.
- Produces: a failing Phase-5 executable before `Ps.KernelCore.DefEq` exists.

- [ ] **Step 1: Wire the executable**

Add:

```text
psc2_kernel_core_defeq_parity_tests -> KernelCoreDefEqParityTests
```

Add workflow step immediately after `Minimal inference parity test`:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_defeq_parity_tests
```

Do not add Phase-5 aggregate assurance yet.

- [ ] **Step 2: Build paired test-only contexts**

The test file imports:

```text
Ps.KernelCore.DefEq
PSC1Kernel.TypeChecker
```

Build matched KernelCore/reference environments and local contexts using unchecked insertion so the fixture isolates DefEq rather than declaration admission.

The common fixture environment must contain enough typing declarations that mature proof-irrelevance checks do not fail accidentally:

- `A : Sort 1` and `B : Sort 1` as ordinary type constants;
- `P : Sort 0` and `Q : Sort 0` as proposition constants;
- `Nat : Sort 1` and `String : Sort 1` for literal cases;
- an ordinary reducible definition whose body exposes a Phase-3 delta-equality case;
- an alias proposition definition for a proof-type-after-reduction case;
- two distinct opaque constants with ordinary non-Prop types;
- locals for proof terms `p : P`, `q : Q`, and function `f : forall x : A, A` as needed by cases.

Reference calls use `PSC1Kernel.isDefEq (PSC1Kernel.CheckerContext.empty env |>.with matched lctx)` or the equivalent record construction already used by repository tests. KernelCore calls use budget `64` unless testing budget behavior.

- [ ] **Step 3: Add positive direct-differential cases**

Compare `PsKernelCoreResult.ok bool` with `Except.ok bool` for:

1. reflexivity;
2. metadata transparency, including wrapper-vs-body;
3. structurally different but equivalent sort levels;
4. residual constants with same name and equivalent universe levels;
5. same free variable;
6. equal Nat literals;
7. equal String literals;
8. beta equality;
9. zeta equality;
10. local-let unfolding equality;
11. ordinary definition delta equality;
12. nested application equality;
13. lambda equality;
14. lambda display-name difference;
15. lambda binder-info difference accepted by the oracle;
16. forall equality;
17. forall display-name difference;
18. forall binder-info difference accepted by the oracle;
19. nested/dependent lambda equality;
20. nested/dependent forall equality;
21. proof irrelevance for distinct `p1 p2 : P` bodies/locals;
22. proof irrelevance where the two proposition types become DefEq only after accepted ordinary delta reduction;
23. function eta `(fun x => f x) ≡ f`;
24. reverse function eta `f ≡ (fun x => f x)`.

- [ ] **Step 4: Add negative direct-differential cases**

Use well-typed fixtures so failures represent equality, not accidental typing errors:

1. different ordinary residual constants whose types are not propositions;
2. same constant name with non-equivalent universe levels;
3. different ordinary free variables;
4. unequal Nat literals;
5. Nat literal versus String literal;
6. applications with unequal ordinary arguments;
7. lambdas with non-DefEq domains;
8. foralls with non-DefEq domains;
9. proof terms with non-DefEq proposition types (`P` versus `Q`);
10. lambda-vs-successfully-inferred non-function term does not become equal by eta;
11. two distinct opaque constants remain unequal.

- [ ] **Step 5: Pin error-propagation and KernelCore-only boundaries**

Add exact KernelCore assertions for:

```text
budget 0 -> PsKernelCoreResult.error "defeq budget exhausted"
```

and the same reflexive term at budget `1` -> `ok true`.

Add:

- a proof-irrelevance path whose required inference fails and pin the lower-layer inference error;
- an eta path whose required inference fails and pin the lower-layer inference error;
- structurally identical projection -> `ok true` through Task-2 structural equality;
- residual non-identical projection -> exact `projection definitional equality unavailable before inductive metadata`.

Where the mature oracle supports the two error-propagation cases, compare exact errors; projection/budget behavior are KernelCore boundary contracts and do not imply full-oracle parity.

- [ ] **Step 6: Verify RED**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_defeq_parity_tests
```

Expected: FAIL because `Ps.KernelCore.DefEq` does not exist.

- [ ] **Step 7: Commit**

```text
test(pskernel-core): add minimal defeq red gate
```

---

### Task 4: GREEN — Total minimal DefEq semantics

**Files:**
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/DefEq.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`
- Test: `psc15selfhost/test/KernelCoreDefEqParityTests.lean`

**Interfaces:**
- Consumes:

```text
psKernelCoreExprEq
psKernelCoreLevelEquivalent
psKernelCoreLevelNormalizesToZero
psKernelCoreWhnf
psKernelCoreInfer
psKernelCoreInferFreshName
psKernelCoreLocalContextAddLocal
psKernelCoreExprInstantiate1
```

- Produces:

```text
psKernelCoreLevelListEquivalent
  (left : PsKernelCoreList PsKernelCoreLevel) :
  PsKernelCoreList PsKernelCoreLevel -> Bool

psKernelCoreDefEqIsProp
  (budget : Nat)
  (env : PsKernelCoreEnvironment)
  (lctx : PsKernelCoreLocalContext)
  (typeExpr : PsKernelCoreExpr) :
  PsKernelCoreResult String Bool

psKernelCoreIsDefEq
  (budget : Nat) :
  PsKernelCoreEnvironment ->
  PsKernelCoreLocalContext ->
  PsKernelCoreExpr ->
  PsKernelCoreExpr ->
  PsKernelCoreResult String Bool
```

`psKernelCoreIsDefEq` must recurse only through decreasing `budget`; environment, local context, and both terms are curried after the budget. In the `Nat.succ remaining` branch bind `smaller := psKernelCoreIsDefEq remaining` before handling expressions.

- [ ] **Step 1: Implement structural/universe helpers and budget boundary**

`psKernelCoreLevelListEquivalent` compares equal-length local lists pairwise with `psKernelCoreLevelEquivalent` using the left list as structural recursion.

`psKernelCoreIsDefEq Nat.zero` returns exactly `defeq budget exhausted` for all terms, including reflexive ones.

`Nat.succ remaining` first checks `psKernelCoreExprEq`; on `true`, return `ok true` without lower-layer work.

- [ ] **Step 2: Implement accepted basic normalization and residual cheap cases**

For non-structurally-equal terms, call accepted `psKernelCoreWhnf remaining` on left then right and propagate errors.

After reduction:

1. rerun `psKernelCoreExprEq`;
2. sorts -> `psKernelCoreLevelEquivalent`;
3. literals -> `psKernelCoreLiteralEq`;
4. residual constants with same name + pairwise-equivalent levels -> `ok true`;
5. same residual free variable -> `ok true`;
6. lambda/lambda and forall/forall go to binder comparison in Step 3;
7. if either residual side is a projection and structural equality did not already succeed, return exact projection-deferred error;
8. otherwise continue to proof irrelevance / application / eta.

Do not return `false` merely because residual constant or fvar names differ; proof irrelevance still has an opportunity to prove distinct proof terms equal.

- [ ] **Step 3: Implement lambda and forall comparison with shared locals**

For lambda/lambda and forall/forall:

1. recursively DefEq the domains using `smaller`;
2. if domains are false, return `ok false`;
3. choose the right-hand display name and right-hand binder info for the shared local, matching the mature spine convention;
4. generate a deterministic fresh internal name with `psKernelCoreInferFreshName lctx rightName`;
5. extend the local context with the right-hand domain and binder info;
6. open both bodies with the same `fvar fresh` using `psKernelCoreExprInstantiate1`;
7. recursively compare opened bodies with `smaller`.

Binder display names and binder info are not compared directly.

- [ ] **Step 4: Implement proof-irrelevance detection and comparison**

`psKernelCoreDefEqIsProp remaining env lctx typeExpr`:

1. calls `psKernelCoreInfer remaining env lctx typeExpr`;
2. WHNFs the inferred type with `psKernelCoreWhnf remaining`;
3. requires a residual `sort level`, otherwise returns lower-layer-compatible `expected sort`;
4. returns `ok (psKernelCoreLevelNormalizesToZero level)`.

For residual terms not already decided:

1. infer the left term with budget `remaining` to get `leftType`;
2. call `psKernelCoreDefEqIsProp remaining ... leftType`;
3. propagate every error;
4. if false, continue ordinary comparison;
5. if true, infer the right term with `remaining` and return `smaller env lctx leftType rightType`.

Never reinterpret a required inference/WHNF failure as “not a proof.”

- [ ] **Step 5: Implement application and symmetric function eta**

Applications compare function first, then argument, each through `smaller`; this yields head-first recursive ordering for nested spines.

For lambda/non-lambda:

1. infer the non-lambda term with `remaining`;
2. WHNF its type with `remaining`;
3. propagate errors;
4. if residual type is `forallE name domain _ binderInfo`, construct eta expansion `lam name domain (app other (bvar 0)) binderInfo` and compare recursively with `smaller`;
5. if inference succeeds but type is not a forall, eta does not prove equality and ordinary fallback is `ok false`.

Implement both orientations symmetrically. Do not add structure eta.

- [ ] **Step 6: Finish conservative fallback**

After supported residual rules and proof/eta opportunities are exhausted, return `ok false`.

Do not add recursor, Quot, structure, native, Nat primitive, String expansion, unit-like, cache, session, or exact lazy-delta code.

- [ ] **Step 7: Export and run direct parity GREEN**

Add:

```text
import Ps.KernelCore.DefEq
```

to `Ps/KernelCore.lean`, then run:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_defeq_parity_tests
```

Expected marker:

```text
PSC2_KERNEL_CORE_DEFEQ_PARITY: PASS
```

- [ ] **Step 8: Run actual PSC1 self-host acceptance**

```bash
cd psc15selfhost
node scripts/check-kernel-core-source.mjs
```

Expected: every trusted closure, now including DefEq, passes real `lake exe psc1 check`, with final `KERNEL_CORE_SOURCE_PROFILE: PASS`.

If PSC1 rejects recursion/syntax that Lean accepts, rewrite trusted code; never weaken this gate.

- [ ] **Step 9: Re-run all accepted lower-layer assurances and full regression**

```bash
cd psc15selfhost
npm run assurance:kernel-core:phase1
npm run assurance:kernel-core:phase2
npm run assurance:kernel-core:phase3
npm run assurance:kernel-core:phase4
npm run check
```

Expected: every command succeeds unchanged.

- [ ] **Step 10: Commit**

```text
feat(pskernel-core): add minimal definitional equality
```

---

### Task 5: Phase-5 aggregate assurance and CI

**Files:**
- Modify: `psc15selfhost/package.json`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`

**Interfaces:**
- Consumes: completed Tasks 1–4.
- Produces: repeatable `assurance:kernel-core:phase5` plus exact CI ordering.

- [ ] **Step 1: Add the Phase-5 aggregate without editing older aggregates**

Add script whose order is exactly:

```text
check:kernel-core-source
boundary
name
level
expr
subst
declaration
environment
local-context
reduction
infer
defeq
size-report
```

using the existing executable names and new `psc2_kernel_core_defeq_parity_tests`.

Do not modify the command strings for Phase 1–4.

- [ ] **Step 2: Add workflow aggregate step**

Immediately after Phase-4 aggregate assurance add:

```bash
cd psc15selfhost
npm run assurance:kernel-core:phase5
```

The final `npm run check` remains after it.

- [ ] **Step 3: Run the exact aggregate and full regression**

```bash
cd psc15selfhost
npm run assurance:kernel-core:phase5
npm run check
```

Expected: both succeed.

- [ ] **Step 4: Commit**

```text
ci(pskernel-core): add Phase 5 assurance gate
```

---

### Task 6: Exact-head acceptance, review, and integration handoff

**Files:**
- Create: `psc15selfhost/docs/continuity/PHASE5_ACCEPTANCE.md`

**Interfaces:**
- Consumes: the exact implementation/assurance SHA from Task 5 and its successful GitHub Actions run.
- Produces: durable Phase-5 evidence and a merge-ready execution branch.

- [ ] **Step 1: Obtain fresh exact-head GitHub Actions evidence**

Require the `PSC2 minimal kernel` workflow on the exact Task-5 implementation/assurance SHA to complete successfully with:

```text
Boundary test
Name parity test
Level parity test
Expr parity test
Substitution parity test
Declaration parity test
Environment parity test
Local context parity test
Basic reduction parity test
Minimal inference parity test
Minimal DefEq parity test
Bootstrap closure remains isolated
KernelCore PSC1 source profile
Phase 1 aggregate assurance
Phase 2 aggregate assurance
Phase 3 aggregate assurance
Phase 4 aggregate assurance
Phase 5 aggregate assurance
Existing PSC2 regression gate
```

Record exact SHA, run ID, job ID, and conclusion.

- [ ] **Step 2: Record measured source/size evidence**

Copy from that exact job:

- trusted KernelCore file count;
- trusted bytes;
- trusted nonblank/noncomment LOC;
- reference baseline count/bytes/LOC;
- byte and LOC ratios;
- `KERNEL_CORE_SOURCE_PROFILE: PASS` module count.

Do not estimate numbers.

- [ ] **Step 3: Create `PHASE5_ACCEPTANCE.md`**

Record:

- reviewed/execution branches;
- exact implementation/assurance SHA;
- run/job/conclusion;
- accepted `Expr.eqv` structural helper semantics;
- accepted DefEq surface and parity matrix;
- budget/projection boundary behavior;
- real PSC1 source-check evidence;
- preserved Phase-1–4 evidence;
- exact size report;
- allowed claims;
- explicit non-claims from the spec;
- next dependency-ordered phase: checked inference + declaration admission.

- [ ] **Step 4: Commit acceptance documentation only**

```text
docs(pskernel-core): accept Phase 5 definitional equality
```

Then compare acceptance commit against the tested implementation SHA. Expected difference: exactly `PHASE5_ACCEPTANCE.md`.

- [ ] **Step 5: Whole-branch review**

Compare reviewed Phase-5 plan head to execution head. Confirm changed files are limited to:

```text
.github/workflows/psc2-minimal-kernel.yml
psc15selfhost/docs/continuity/PHASE5_ACCEPTANCE.md
psc15selfhost/lakefile.lean
psc15selfhost/package.json
psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean
psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Expr.lean
psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/DefEq.lean
psc15selfhost/test/KernelCoreExprParityTests.lean
psc15selfhost/test/KernelCoreDefEqParityTests.lean
```

Any extra semantic file requires explanation and renewed scope review.

- [ ] **Step 6: Integration handoff**

Use the finishing-development-branch workflow. Do not force-move the reviewed branch. If the user again requests merge, open a PR from `psc2/kernel-core-phase5-defeq-work` to `psc2/kernel-core-phase5-defeq`, verify mergeability and expected head SHA, merge through GitHub, then verify the merged-head CI before beginning Phase 6.

---

## Completion Boundary

Phase 5 stops after accepted minimal DefEq is merged and verified. Do **not** begin checked inference/declaration admission, Quot, inductive metadata, recursor/iota, compiler cutover, or fixed-point work inside this plan.

The next architectural unit gets its own written spec and implementation plan.