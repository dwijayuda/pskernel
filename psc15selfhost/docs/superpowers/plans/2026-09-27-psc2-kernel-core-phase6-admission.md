# PSC2 KernelCore Phase 6 — Checked Inference and Non-Inductive Admission Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add PSC1-self-hostable checked-expression inference and ordinary axiom/definition/theorem/opaque admission on top of the accepted Phase-5 DefEq layer.

**Architecture:** Preserve the accepted infer-only layer unchanged. Add `Ps.KernelCore.Check` as a separate total checked-inference layer, then add `Ps.KernelCore.Admission` as a pure functional declaration gate that owns closure/universe validation and calls `Check`/`DefEq`. Keep inductive, Quot, primitive/native, mutual-definition, and compiler-cutover semantics out of Phase 6.

**Tech Stack:** Lean 4.34.0, PSC1-compatible trusted `.lean`, Lake, Node.js 22/npm, GitHub Actions.

**Spec:** `psc15selfhost/docs/superpowers/specs/2026-09-27-psc2-kernel-core-phase6-admission-design.md`

## Global Constraints

- Work only from the reviewed Phase-6 line `psc2/kernel-core-phase6-admission`; Native execution uses isolated branch `psc2/kernel-core-phase6-admission-work`.
- Base integrated Phase-5 merge is `5b2b0879e57aaad95f947c911d55197b871316a8`.
- Do not modify the semantics of accepted `Ps.KernelCore.Infer` during Phase 6.
- Trusted additions are `Ps.KernelCore.Check` and `Ps.KernelCore.Admission` unless an actual PSC1 portability blocker proves one extra narrowly scoped trusted helper module necessary.
- Every trusted KernelCore module must pass the hardened actual PSC1 flattened-closure source check; do not weaken lexical restrictions, timeout behavior, or fail-closed process handling.
- Trusted source must not use `partial`, implementation `unsafe`, `extern`, `implemented_by`, IO, `Lean.*`, `Std.*`, macros/custom elaborators, host `List`/`Option` semantic storage, caches/sessions, namespaces/sections outside the accepted profile, or trusted mutual declarations.
- Prefer small first-order helpers and PSC1-safe decreasing-budget currying. Phase 5 proved that large/higher-order trusted bodies can be semantically correct but pathological for PSC1 elaboration.
- Preserve all Phase-1 through Phase-5 aggregate commands unchanged.
- Do not add inductive/constructor/recursor, positivity, iota, projection computation, Quot, mutual-definition, native evaluator, primitive Nat/String expansion, exact Lean resource accounting, K7/K8 corpus, or compiler `CheckedCore` integration in Phase 6.
- Rejections are functional: the original immutable environment remains the caller's environment; no host-side mutation enters the trusted core.
- Do not claim full Lean 4.34 equivalence or complete kernel admission.

## File Structure

Trusted source:

- Create `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Check.lean` — checked expression inference and safety restrictions.
- Create `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Admission.lean` — closure/universe validation and ordinary declaration admission.
- Modify `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean` — export `Check`, then `Admission`.

Differential tests:

- Create `psc15selfhost/test/KernelCoreCheckParityTests.lean` — Phase-6 checked-expression oracle adapter and RED/GREEN matrix.
- Create `psc15selfhost/test/KernelCoreAdmissionParityTests.lean` — ordinary declaration admission oracle adapter and RED/GREEN matrix.

Build/assurance:

- Modify `psc15selfhost/lakefile.lean` — add reference `PSC1Kernel.Kernel` root for admission tests and add the two Phase-6 test executables.
- Modify `psc15selfhost/package.json` — add only `assurance:kernel-core:phase6`; keep Phase-1–5 commands byte-for-byte unchanged.
- Modify `.github/workflows/psc2-minimal-kernel.yml` — Phase-6 reviewed/work branch triggers, direct Phase-6 test steps, Phase-6 aggregate step.
- Do not modify `psc15selfhost/scripts/check-kernel-core-source.mjs` unless execution reveals a demonstrated harness defect unrelated to semantic acceptance; any such change must remain fail-closed and get its own regression evidence.
- `psc15selfhost/scripts/report-kernel-core-size.mjs` should discover new trusted modules automatically; change it only if a demonstrated reporter defect requires it.

Acceptance:

- Create `psc15selfhost/docs/continuity/PHASE6_ACCEPTANCE.md` only after an exact implementation/assurance SHA has fresh green CI and full regression evidence.

## Review Focus

1. **Safety matrix:** safe rejects unsafe and partial; partial permits partial but rejects unsafe; unsafe permits both. Pin all four boundaries in `KernelCoreCheckParityTests.lean`.
2. **Nested universe metavariables/undefined params:** declaration validation must detect them inside every recursive expression child, not only top-level sorts/constants. Pin nested lambda/let/application cases in `KernelCoreAdmissionParityTests.lean`.
3. **Non-adjacent duplicate universe parameters:** `[u, v, u]` must reject with `duplicate universe parameter`, not just adjacent duplicates. Pin directly in admission parity.
4. **Rejected-environment preservation:** with pre-existing declarations and `quotInitialized = true`, every rejected ordinary admission must leave the original environment size/membership/flag unchanged. Pin one representative rejection per declaration family plus one shared flag case.
5. **Unsafe self-reference boundary:** a bounded unsafe single definition may see itself only through the temporary work environment; malformed unsafe self-reference must reject without leaking the declaration into the original environment. Pin both cases directly.

---

### Task 1: Checked-expression RED differential gate

**Files:**
- Create: `psc15selfhost/test/KernelCoreCheckParityTests.lean`
- Modify: `psc15selfhost/lakefile.lean`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`

**Interfaces:**
- Consumes mature oracle `PSC1Kernel.check : CheckerContext -> Expr -> Except String Expr` and accepted KernelCore Environment/LocalContext/DefinitionSafety representation.
- Produces executable `psc2_kernel_core_check_parity_tests` and a fixture that will later call `psKernelCoreCheck`.

- [ ] **Step 1: Add the Phase-6 execution branches to CI trigger scope**

Add:

```text
psc2/kernel-core-phase6-admission
psc2/kernel-core-phase6-admission-work
```

Do not remove or reorder existing Phase-1–5 branch triggers.

- [ ] **Step 2: Add the Lake executable for the checked-expression fixture**

Add:

```lean
lean_exe psc2_kernel_core_check_parity_tests where
  srcDir := "test"
  root := `KernelCoreCheckParityTests
```

No production `Check.lean` exists yet.

- [ ] **Step 3: Write the checked-expression RED fixture**

`KernelCoreCheckParityTests.lean` must import the not-yet-existing:

```lean
import Ps.KernelCore.Check
import PSC1Kernel.TypeChecker
```

Adapter contract:

```text
kernel:    psKernelCoreCheck budget kenv klctx ksafety kexpr
reference: PSC1Kernel.check { CheckerContext.empty renv with lctx := rlctx, safety := rsafety } rexpr
```

For ordinary overlap cases compare acceptance/rejection and successful result types. Pin exact small-core messages only where the spec makes them stable.

Required matrix from the spec:

- positive: sort; local variable; monomorphic constant; polymorphic constant; small Nat literal; String literal; metadata; valid application; dependent application; valid lambda; dependent lambda; valid forall; valid let; dependent let; unsafe constant from unsafe context; partial constant from partial context; partial constant from unsafe context;
- safety focus: partial context rejects unsafe constant; safe rejects unsafe; safe rejects partial;
- negative: loose bvar; expression mvar; unknown fvar; unknown constant; bad universe arity; application mismatch; malformed lambda domain; malformed forall domain; malformed forall codomain; let type not a type; let value mismatch; non-function application; projection deferred;
- budget/error: zero budget; one pinned threshold; DefEq error propagation; reachable WHNF error propagation.

Expected final marker:

```text
PSC2_KERNEL_CORE_CHECK_PARITY: PASS
```

- [ ] **Step 4: Add the direct CI step**

Insert after `Minimal DefEq parity test`:

```text
Checked inference parity test
```

running:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_check_parity_tests
```

Do not add the Phase-6 aggregate yet.

- [ ] **Step 5: Run RED and prove the failure reason**

Run through the branch CI or local checkout:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_check_parity_tests
```

Expected: FAIL because `Ps.KernelCore.Check` / `psKernelCoreCheck` does not exist. Earlier direct parity gates must remain green. Do not implement trusted code until this exact RED is observed.

- [ ] **Step 6: Commit RED fixture**

```text
test(pskernel-core): add checked inference parity red gate
```

---

### Task 2: Checked-expression GREEN trusted layer

**Files:**
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Check.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`
- Test: `psc15selfhost/test/KernelCoreCheckParityTests.lean`

**Interfaces:**
- Consumes:
  - `psKernelCoreEnsureSort`
  - `psKernelCoreEnsureForall`
  - `psKernelCoreInferFreshName`
  - local-context add/find operations
  - `psKernelCoreExprInstantiate1`
  - `psKernelCoreExprAbstractFVar`
  - `psKernelCoreExprHasFVarName`
  - `psKernelCoreIsDefEq`
- Produces:

```text
psKernelCoreCheck :
  Nat ->
  PsKernelCoreEnvironment ->
  PsKernelCoreLocalContext ->
  PsKernelCoreDefinitionSafety ->
  PsKernelCoreExpr ->
  PsKernelCoreResult String PsKernelCoreExpr
```

- [ ] **Step 1: Create `Check.lean` with PSC1-safe decreasing-budget shape**

Required recursion shape:

```text
psKernelCoreCheck budget : Env -> LocalContext -> DefinitionSafety -> Expr -> Result String Expr
```

Only `budget` decreases recursively. In the `Nat.succ remaining` branch bind `smaller := psKernelCoreCheck remaining`, then apply it to changing env/context/safety/expression arguments. Avoid recursive helpers that change multiple explicit structural arguments.

Stable Phase-6-specific errors:

```text
check budget exhausted
safe declaration uses unsafe constant
safe declaration uses partial constant
application type mismatch
let value type mismatch
projection checking unavailable before inductive metadata
```

Preserve accepted lower-layer errors by propagation.

- [ ] **Step 2: Implement the checked constructor surface**

Pin exactly these rules:

- bvar/mvar/fvar/sort/const/literal/mdata follow the spec;
- const safety matrix:
  - unsafe ref allowed only when current safety is `.unsafeDef`;
  - partial ref rejected only when current safety is `.safe`;
- application checks `fn`, exposes forall via accepted WHNF, checks `arg`, then calls `psKernelCoreIsDefEq remaining ... argType domain`;
- lambda checks domain and requires sort before opening body;
- forall checks both domain/codomain sorts;
- let checks declared type sort, value, DefEq, then body and closes the inferred type using the accepted Phase-4 dead-let behavior;
- projection fails closed with the exact deferred error.

Do not add eager-reduce, native, primitive, recursor, Quot, or projection metadata logic.

- [ ] **Step 3: Export `Check` from aggregate**

Append after DefEq:

```lean
import Ps.KernelCore.Check
```

Do not export `Admission` yet.

- [ ] **Step 4: Run direct parity**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_check_parity_tests
```

Expected:

```text
PSC2_KERNEL_CORE_CHECK_PARITY: PASS
```

If a reference mismatch appears, diagnose the oracle behavior first; change the spec if the mature oracle disproves a preliminary expectation instead of weakening the fixture.

- [ ] **Step 5: Run the actual PSC1 trusted-source gate**

```bash
cd psc15selfhost
npm run check:kernel-core-source
```

Expected: PASS with the trusted module count increased by one from Phase 5. `Check.lean` and aggregate closure must finish under the existing fail-closed 120-second per-entry bound.

If Lean-valid source is rejected by PSC1, rewrite trusted source into smaller first-order / curried forms. Do not relax the checker or extend the timeout merely for convenience.

- [ ] **Step 6: Re-run preserved lower-layer assurances and full regression**

```bash
cd psc15selfhost
npm run assurance:kernel-core:phase5
npm run check
```

Expected: both PASS unchanged.

- [ ] **Step 7: Commit checked layer**

```text
feat(pskernel-core): add checked inference semantics
```

---

### Task 3: Ordinary declaration-admission RED gate

**Files:**
- Create: `psc15selfhost/test/KernelCoreAdmissionParityTests.lean`
- Modify: `psc15selfhost/lakefile.lean`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`

**Interfaces:**
- Consumes mature oracles:
  - `PSC1Kernel.Kernel.addAxiom`
  - `PSC1Kernel.Kernel.addDefinition`
  - `PSC1Kernel.Kernel.addTheorem`
  - `PSC1Kernel.Kernel.addOpaque`
- Produces executable `psc2_kernel_core_admission_parity_tests` and future calls to KernelCore `psKernelCoreAdd*` APIs.

- [ ] **Step 1: Expose mature Kernel root to test library**

In `PSC1KernelReferenceFoundations.roots`, add:

```lean
`PSC1Kernel.Kernel
```

Keep existing roots unchanged.

- [ ] **Step 2: Add the admission executable**

```lean
lean_exe psc2_kernel_core_admission_parity_tests where
  srcDir := "test"
  root := `KernelCoreAdmissionParityTests
```

- [ ] **Step 3: Write the full admission RED fixture**

Imports:

```lean
import Ps.KernelCore.Admission
import PSC1Kernel.Kernel
```

Use mirrored KernelCore/reference declaration builders for AxiomInfo, DefinitionInfo, TheoremInfo and OpaqueInfo. For reference calls use mature defaults for host resource/native arguments; compare semantic accept/reject and resulting environment membership/size, not small-core budget accounting.

Required matrix:

- positive: safe axiom; unsafe axiom; safe definition; polymorphic safe definition; theorem Prop; theorem proof with DefEq type; opaque; bounded unsafe self-reference;
- base negatives: duplicate name; adjacent duplicate universe params; non-adjacent `[u,v,u]`; expression mvar in type; universe mvar in type; free var in type; undefined universe param in type; declared type not a type;
- definition negatives: expression mvar; nested universe mvar; free var; undefined level param; type mismatch; safe uses unsafe; safe uses partial; malformed unsafe self-reference;
- theorem negatives: non-Prop type; mvar/free proof; proof mismatch; forbidden unsafe/partial dependency;
- opaque negatives: mismatch; mvar/free body; forbidden unsafe/partial dependency even when `isUnsafe = true`;
- recursive validation focus: nest universe mvar / undefined param below app, lambda or let child so traversal cannot pass with shallow checking;
- environment focus: rejected admission preserves size, existing lookup, absent rejected name and `quotInitialized = true`;
- budget: zero budget and one success threshold.

Expected final marker:

```text
PSC2_KERNEL_CORE_ADMISSION_PARITY: PASS
```

- [ ] **Step 4: Add direct admission CI step**

Insert immediately after checked-inference parity:

```text
Ordinary admission parity test
```

running:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_admission_parity_tests
```

- [ ] **Step 5: Run RED**

Expected: FAIL only because `Ps.KernelCore.Admission` / `psKernelCoreAdd*` APIs do not exist. `Check` parity and all earlier direct gates must remain green.

- [ ] **Step 6: Commit RED fixture**

```text
test(pskernel-core): add admission parity red gate
```

---

### Task 4: Ordinary declaration-admission GREEN trusted layer

**Files:**
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Admission.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`
- Test: `psc15selfhost/test/KernelCoreAdmissionParityTests.lean`

**Interfaces:**
- Consumes:
  - `psKernelCoreCheck`
  - `psKernelCoreIsDefEq`
  - `psKernelCoreWhnf`
  - declaration/environment accessors and `psKernelCoreEnvironmentAdd`/`AddUnchecked`
  - KernelCore-local list/option/result carriers
- Produces:

```text
psKernelCoreAddAxiom : Nat -> Environment -> AxiomInfo -> Result String Environment
psKernelCoreAddDefinition : Nat -> Environment -> DefinitionInfo -> Result String Environment
psKernelCoreAddTheorem : Nat -> Environment -> TheoremInfo -> Result String Environment
psKernelCoreAddOpaque : Nat -> Environment -> OpaqueInfo -> Result String Environment
```

and Admission-local pure validation helpers.

- [ ] **Step 1: Implement small first-order structural validation helpers**

`Admission.lean` owns helpers for:

```text
name membership over PsKernelCoreList
find undefined level parameter
find undefined expression level parameter
expression/levels contain metavariable
expression contains free variable
check closed expression
check level parameters
```

Traversal must cover all recursive expression children, including metadata/projection payload expressions, lambda/forall domain+body, let type+value+body, application fn+arg, sort levels and constant level lists.

Do not add these admission-only helpers to foundational `Expr.lean` or `Level.lean` unless execution proves a strong reusable semantic need.

- [ ] **Step 2: Implement shared constant-base validation**

Required validation order:

```text
already declared
duplicate universe parameter
declaration has metavariables
declaration has free variables
invalid reference to undefined universe level parameter
checked type inference
ensure inferred type is a sort
```

Use the declaration-specific safety context passed by the caller. Do not rely solely on `Environment.add`, because base type well-formedness must be checked before mutation.

- [ ] **Step 3: Implement body validation helper**

For definition/opaque/theorem values:

1. closure/metavariable/level-param validation;
2. `psKernelCoreCheck` under the required safety context;
3. `psKernelCoreIsDefEq` against the declared type;
4. return the caller-specific stable mismatch error when equality is `ok false`;
5. propagate lower-layer errors.

Keep helpers first-order; avoid callback-heavy designs that could reproduce Phase-5 PSC1 elaboration pathology.

- [ ] **Step 4: Implement `psKernelCoreAddAxiom`**

Safety is `.unsafeDef` when `isUnsafe = true`, otherwise `.safe`. Validate base then call trusted environment add semantics.

Budget `0` for every public admission API returns exactly:

```text
admission budget exhausted
```

Positive-budget lower-layer budget errors propagate unchanged.

- [ ] **Step 5: Implement `psKernelCoreAddDefinition`**

Pin each safety case:

- `.safe`: header safe; body safe against original env; then add;
- `.partialDef`: header/body checked under `.safe` exactly as mature ordinary single-definition admission; then add;
- `.unsafeDef`: header under unsafe; create temporary `work := psKernelCoreEnvironmentAddUnchecked env (.defnInfo value)` only after header success; check body under unsafe against `work`; on success return `work`; on error return error and no environment value.

Stable mismatch:

```text
definition type mismatch
```

- [ ] **Step 6: Implement theorem proposition test and `psKernelCoreAddTheorem`**

The proposition helper must checked-infer the theorem type and use accepted WHNF/level-zero semantics to decide Prop. Stable errors:

```text
theorem type is not a proposition
theorem proof type mismatch
```

The theorem base and proof are checked under `.safe`.

- [ ] **Step 7: Implement `psKernelCoreAddOpaque`**

Header and value are checked under `.safe` even when `OpaqueInfo.isUnsafe = true`. Stable mismatch:

```text
opaque value type mismatch
```

Retain `isUnsafe` only as admitted declaration metadata.

- [ ] **Step 8: Export Admission from aggregate**

Append:

```lean
import Ps.KernelCore.Admission
```

Expected trusted closure after GREEN: 14 modules including the aggregate, unless a documented portability split was required.

- [ ] **Step 9: Run admission differential parity**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_admission_parity_tests
```

Expected:

```text
PSC2_KERNEL_CORE_ADMISSION_PARITY: PASS
```

If the mature oracle contradicts a preliminary unsafe/partial expectation, stop and correct the spec/fixture before changing trusted semantics.

- [ ] **Step 10: Run actual PSC1 source acceptance**

```bash
cd psc15selfhost
npm run check:kernel-core-source
```

Expected: all trusted closures PASS under existing timeout. If Admission is pathological, split large first-order helpers before considering any harness change; never hide a timeout by increasing it without proving the harness is defective.

- [ ] **Step 11: Run direct Check parity, Phase-5 assurance and full regression**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_check_parity_tests
npm run assurance:kernel-core:phase5
npm run check
```

Expected: all PASS.

- [ ] **Step 12: Commit admission layer**

```text
feat(pskernel-core): add ordinary declaration admission
```

---

### Task 5: Phase-6 aggregate assurance and CI closure

**Files:**
- Modify: `psc15selfhost/package.json`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`

**Interfaces:**
- Consumes the accepted direct Check and Admission parity executables.
- Produces `npm run assurance:kernel-core:phase6` and exact-head CI coverage.

- [ ] **Step 1: Add `assurance:kernel-core:phase6` only**

Exact dependency order:

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
check
admission
size report
```

Implement using existing executable names plus:

```text
psc2_kernel_core_check_parity_tests
psc2_kernel_core_admission_parity_tests
```

Do not alter Phase-1–5 script strings.

- [ ] **Step 2: Add Phase-6 aggregate CI step**

After `Phase 5 aggregate assurance` add:

```text
Phase 6 aggregate assurance
```

running:

```bash
cd psc15selfhost
npm run assurance:kernel-core:phase6
```

Keep `Existing PSC2 regression gate` last.

- [ ] **Step 3: Run exact aggregate locally/CI**

```bash
cd psc15selfhost
npm run assurance:kernel-core:phase6
npm run check
```

Expected: both PASS.

- [ ] **Step 4: Verify lower aggregate commands remained unchanged**

Compare `package.json` with the pre-Phase-6 base and confirm only the new Phase-6 script was added in the assurance family. Any accidental earlier-script drift must be reverted before acceptance.

- [ ] **Step 5: Commit assurance wiring**

```text
ci(pskernel-core): add Phase 6 assurance gate
```

---

### Task 6: Exact-head acceptance, review and integration

**Files:**
- Create: `psc15selfhost/docs/continuity/PHASE6_ACCEPTANCE.md`

**Interfaces:**
- Consumes fresh exact-head CI evidence.
- Produces the durable Phase-6 claim boundary and integration-ready work branch.

- [ ] **Step 1: Freeze the implementation/assurance SHA**

After Task 5, make no semantic/build/CI changes while collecting evidence. Record the exact SHA.

- [ ] **Step 2: Require fresh exact-SHA CI success**

The `PSC2 minimal kernel` job on the exact implementation/assurance SHA must show success for:

```text
Boundary
Name
Level
Expr
Substitution
Declaration
Environment
Local context
Basic reduction
Minimal inference
Minimal DefEq
Checked inference
Ordinary admission
Bootstrap isolation
KernelCore PSC1 source profile
Phase 1 aggregate
Phase 2 aggregate
Phase 3 aggregate
Phase 4 aggregate
Phase 5 aggregate
Phase 6 aggregate
Existing PSC2 regression gate
```

Do not infer success from an older SHA.

- [ ] **Step 3: Capture measured source/size evidence from that run**

Record:

- trusted module count;
- source bytes;
- nonblank/noncomment LOC;
- comparable PSC1Kernel bytes/LOC;
- ratios;
- source-profile PASS count;
- workflow run ID and job ID.

Do not predict or predeclare a final percentage target.

- [ ] **Step 4: Write `PHASE6_ACCEPTANCE.md` as documentation-only follow-up**

Include:

- reviewed/work branches;
- accepted implementation/assurance SHA;
- exact run/job/conclusion;
- trusted module list;
- Check and Admission direct evidence;
- safety matrix evidence;
- unsafe self-reference behavior;
- PSC1 source-profile evidence;
- preserved Phase-1–5 evidence;
- exact size report;
- compiler isolation;
- allowed claims;
- explicit non-claims;
- recommended next phase selected from remaining primitive/resource, Quot and inductive semantic islands.

Strongest allowed summary:

> KernelCore has a PSC1-self-hostable checked-expression layer and ordinary non-inductive declaration admission with direct differential evidence for the explicitly covered Phase-6 surface; inductive, Quot, primitive/native, mutual-definition, corpus, and compiler-cutover semantics remain separately gated.

- [ ] **Step 5: Verify acceptance commit is docs-only**

Compare acceptance commit to the exact tested implementation SHA. Expected changed path:

```text
psc15selfhost/docs/continuity/PHASE6_ACCEPTANCE.md
```

only.

- [ ] **Step 6: Whole-branch scope review**

Compare the execution work branch to the reviewed Phase-6 plan head. Allowed implementation changes are limited to:

```text
packages/pskernel-core/src/Ps/KernelCore/Check.lean
packages/pskernel-core/src/Ps/KernelCore/Admission.lean
packages/pskernel-core/src/Ps/KernelCore.lean
test/KernelCoreCheckParityTests.lean
test/KernelCoreAdmissionParityTests.lean
lakefile.lean
package.json
.github/workflows/psc2-minimal-kernel.yml
PHASE6_ACCEPTANCE.md
```

plus a narrowly documented source-gate/reporter correction only if a real harness defect was demonstrated during execution.

Confirm no inductive, Quot, primitive/native, mutual-definition or compiler-provider files changed.

- [ ] **Step 7: Integrate through PR after evidence is green**

Create PR:

```text
psc2/kernel-core-phase6-admission-work
  -> psc2/kernel-core-phase6-admission
```

Include exact implementation SHA, CI run/job, acceptance commit, scope/non-scope. Merge only if GitHub reports it mergeable and the branch review is clean. Never force-push either reviewed or work branches.

- [ ] **Step 8: Verify merged-head CI before declaring the phase integrated**

Require a normal post-merge `PSC2 minimal kernel` run on the merge head. Phase 6 is integrated only after that run is green; acceptance semantics remain anchored to the pre-doc exact implementation SHA recorded above.

---

## Stop Boundary

After Phase-6 acceptance and integration, stop semantic implementation. Do not begin primitive/resource, Quot or inductive work until the next architectural phase has its own brainstorming/design approval, written spec approval, and implementation-plan approval.
