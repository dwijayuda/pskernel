# PSC2 KernelCore Phase 4 Minimal Inference Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a PSC1-self-hostable infer-only type-inference substrate to `pskernel-core`, using the accepted Phase-3 WHNF and preserving the mature `PSC1Kernel.infer` overlap semantics without introducing DefEq or checked declaration admission.

**Architecture:** First add the two capture-safe binder helpers inference needs, then add one trusted `Ps.KernelCore.Infer` module with explicit `Nat` depth budget and no checker state/cache object. Differential tests compare the supported surface directly with `PSC1Kernel.infer`; projection remains deliberately fail-closed until trusted inductive metadata exists.

**Tech Stack:** Lean 4.34.0, PSC1-compatible `.lean`, Lake, Node 22/npm assurance gates, GitHub Actions.

**Spec:** `psc15selfhost/docs/superpowers/specs/2026-09-27-psc2-kernel-core-phase4-inference-design.md`

## Global Constraints

- Start from reviewed branch `psc2/kernel-core-phase4-infer`, whose base is the accepted Phase-3 merge `8f3a808adb279b1c48d04dfe075b8babd8259b4d`.
- At execution time create an isolated branch `psc2/kernel-core-phase4-infer-work`; do not force-push or rewrite the reviewed spec/plan branch.
- Trusted KernelCore source must remain PSC1-compatible `.lean` and pass the actual `psc1 check` path through `scripts/check-kernel-core-source.mjs`.
- Trusted source must not use `partial`, `unsafe`, `extern`, `implemented_by`, `IO`, `Lean.*`, `Std.*`, namespace/section conveniences, custom syntax/macros/elaborators, or performance caches/session state.
- Use kernel-local `PsKernelCoreList`, `PsKernelCoreOption`, and `PsKernelCoreResult` for trusted semantic carriers.
- Do not weaken or remove any Phase-1/2/3 parity, bootstrap-isolation, source-profile, size, or repository regression gate.
- Phase 4 implements only the public `PSC1Kernel.infer` / `inferCore ... true` overlap boundary. It MUST NOT add `isDefEq`, checked application arguments, lambda-domain validation, let-value/type validation, unsafe/partial-use restrictions, or declaration admission.
- Projection inference MUST fail closed with `projection inference unavailable before inductive metadata`; do not add unchecked inductive/constructor metadata merely to widen Phase-4 fixtures.
- `pskernel-core` remains outside the active PSC2 bootstrap/compiler admission path.
- Do not claim full Lean 4.34 inference parity, full type checking, full kernel equivalence, compiler cutover, or self-host fixed point from this phase.

## Review Focus

- **Capture-safe abstraction:** abstracting a free variable under existing binders must shift pre-existing bound variables at/above the insertion depth and must satisfy the direct abstract→instantiate round-trip fixtures.
- **Infer-only trust boundary:** a non-inferable application argument, invalid lambda domain, invalid let declared type/value, and unsafe/partial constants must remain accepted when the mature infer-only oracle accepts them; Phase 4 must not silently become checked inference.
- **Dependent substitution:** nested lambdas, dependent lets, dependent multi-application, and a hidden forall exposed by Phase-3 delta reduction must produce the same resulting type shape as `PSC1Kernel.infer`.
- **Universe/sort formation:** polymorphic constant level substitution and `forall` `imax` formation must preserve universe structure, while a forall domain whose inferred type is not a sort must fail with `expected sort`.
- **Deterministic resource/deferred-feature behavior:** inference budget `0` must return exactly `inference budget exhausted`, a pinned one-level term must succeed at budget `1`, and projection must fail with the stable Phase-4-specific deferred error.

---

## File Structure

### Trusted production changes

- Modify `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Subst.lean` — add only free-variable detection and capture-safe single-free-variable abstraction.
- Create `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Infer.lean` — infer-only semantics, `ensureSort`, and `ensureForall` with explicit total budget.
- Modify `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean` — export `Ps.KernelCore.Infer` only after the inference RED fixture exists.

### Differential test

- Create `psc15selfhost/test/KernelCoreInferParityTests.lean` — binder-helper contracts, direct differential inference fixtures against `PSC1Kernel.infer`, and KernelCore-only budget/projection cases.

### Build / assurance wiring

- Modify `psc15selfhost/lakefile.lean` — add executable `psc2_kernel_core_infer_parity_tests` rooted at `KernelCoreInferParityTests`.
- Modify `.github/workflows/psc2-minimal-kernel.yml` — trigger both Phase-4 reviewed/work branches, run inference parity after reduction parity, and later add Phase-4 aggregate assurance.
- Modify `psc15selfhost/package.json` — add `assurance:kernel-core:phase4` without changing Phase-1/2/3 commands.
- `psc15selfhost/scripts/check-kernel-core-source.mjs` requires no code change: it recursively discovers every trusted `.lean` file and invokes the real PSC1 checker on each flattened closure.
- `psc15selfhost/scripts/report-kernel-core-size.mjs` requires no code change: it discovers the trusted source automatically.
- Create `psc15selfhost/docs/continuity/PHASE4_ACCEPTANCE.md` only after the exact implementation/assurance head passes every required gate.

---

### Task 1: RED gate — Binder-closing contracts

**Files:**
- Create: `psc15selfhost/test/KernelCoreInferParityTests.lean`
- Modify: `psc15selfhost/lakefile.lean`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`

**Interfaces:**
- Consumes: accepted Phase-1 `Ps.KernelCore.Subst`, `PsKernelCoreExpr`, `PsKernelCoreName`.
- Produces: a failing executable that pins the exact binder-helper behavior before either helper exists.

- [ ] **Step 1: Wire the Phase-4 test executable and execution branches**

Add to `lakefile.lean`:

```text
psc2_kernel_core_infer_parity_tests -> KernelCoreInferParityTests
```

Add these workflow push branches:

```text
psc2/kernel-core-phase4-infer
psc2/kernel-core-phase4-infer-work
```

Add a `Minimal inference parity test` step immediately after `Basic reduction parity test`:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_infer_parity_tests
```

Do not add Phase-4 aggregate assurance yet.

- [ ] **Step 2: Create the initial binder-helper test file**

Initially import only the already-existing trusted substitution surface plus whatever test/reference modules are needed for ordinary assertions. Call the exact not-yet-existing interfaces:

```text
psKernelCoreExprHasFVarName
  : PsKernelCoreExpr -> PsKernelCoreName -> Bool

psKernelCoreExprAbstractFVar
  : PsKernelCoreExpr -> PsKernelCoreName -> PsKernelCoreExpr
```

- [ ] **Step 3: Pin free-variable detection through the full recursive expression surface**

Assert detection and absence behavior through:

- `app` function and argument;
- lambda type and body;
- forall type and body;
- let type, value, and body;
- `mdata` child;
- `proj` child;
- direct `fvar` match and non-match;
- leaves (`bvar`, `sort`, `const`, literal, unrelated fvar/mvar) remain false when appropriate.

- [ ] **Step 4: Pin abstraction and capture behavior**

Add direct assertions for:

1. `fvar x` abstracts to `bvar 0`;
2. unrelated free variables remain unchanged;
3. abstraction under lambda/forall/let bodies uses the increased binder depth;
4. lambda/forall/let type/value positions use the current depth, not the body depth;
5. pre-existing `bvar i` with `i >= depth` shifts to `bvar (i + 1)`;
6. pre-existing `bvar i` with `i < depth` remains unchanged;
7. metadata/projection/name/level/literal/binder metadata survive unchanged;
8. for multiple well-scoped fixtures, `psKernelCoreExprInstantiate1 (psKernelCoreExprAbstractFVar e x) (PsKernelCoreExpr.fvar x)` reconstructs `e` structurally.

- [ ] **Step 5: Run and verify RED**

Run:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_infer_parity_tests
```

Expected: FAIL because `psKernelCoreExprHasFVarName` and/or `psKernelCoreExprAbstractFVar` do not exist.

Existing Phase-1/2/3 parity executables must remain independently buildable.

- [ ] **Step 6: Commit the RED binder fixture**

Commit message:

```text
test(pskernel-core): add inference binder red gate
```

---

### Task 2: GREEN — Capture-safe single-free-variable abstraction

**Files:**
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Subst.lean`
- Test: `psc15selfhost/test/KernelCoreInferParityTests.lean`

**Interfaces:**
- Consumes: `psKernelCoreNameEq`, existing `PsKernelCoreExpr` constructors, and existing bound-variable substitution/lifting semantics.
- Produces:

```text
psKernelCoreExprHasFVarName
  : PsKernelCoreExpr -> PsKernelCoreName -> Bool

psKernelCoreExprAbstractFVar
  : PsKernelCoreExpr -> PsKernelCoreName -> PsKernelCoreExpr
```

The implementation may expose one trusted worker with fixed signature:

```text
psKernelCoreExprAbstractFVarWorker
  : PsKernelCoreExpr -> PsKernelCoreName -> Nat -> PsKernelCoreExpr
```

For PSC1 recursion acceptance, implement recursive traversals with the expression as the structurally decreasing argument and curry target/depth after that argument whenever the parser/checker requires invariant non-recursive explicit arguments.

- [ ] **Step 1: Implement `psKernelCoreExprHasFVarName` minimally**

Traverse every recursive expression child. Compare only `fvar` names with `psKernelCoreNameEq`; no set/map allocation and no metadata interpretation.

- [ ] **Step 2: Implement capture-safe abstraction worker**

The worker's fixed rules are:

```text
fvar target          -> bvar depth
other fvar           -> unchanged
bvar i, depth <= i   -> bvar (i + 1)
bvar i, i < depth    -> unchanged
```

For `lam` / `forallE`:

- recurse into the binder type at `depth`;
- recurse into the body at `depth + 1`.

For `letE`:

- recurse into declared type and value at `depth`;
- recurse into body at `depth + 1`.

For `app`, recurse into both children at the same depth. For `mdata`/`proj`, recurse into the child and preserve metadata. Preserve all leaf constructors otherwise.

`psKernelCoreExprAbstractFVar expr target` calls the worker at depth `0`.

- [ ] **Step 3: Run binder fixture GREEN**

Run:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_infer_parity_tests
```

Expected: PASS for the binder-only test file.

- [ ] **Step 4: Run actual PSC1 self-host acceptance immediately**

Run:

```bash
cd psc15selfhost
node scripts/check-kernel-core-source.mjs
```

Expected: `KERNEL_CORE_SELFHOST_CHECK: PASS` for every trusted module and final `KERNEL_CORE_SOURCE_PROFILE: PASS`.

If Lean accepts the helper but PSC1 rejects its recursion or syntax, rewrite the helper; do not weaken the source gate.

- [ ] **Step 5: Re-run accepted lower-layer assurance**

Run:

```bash
cd psc15selfhost
npm run assurance:kernel-core:phase3
npm run check
```

Expected: both commands exit successfully.

- [ ] **Step 6: Commit the binder implementation**

Commit message:

```text
feat(pskernel-core): add capture-safe free-variable abstraction
```

---

### Task 3: RED gate — Infer-only differential fixture

**Files:**
- Modify: `psc15selfhost/test/KernelCoreInferParityTests.lean`

**Interfaces:**
- Consumes: completed Task-2 binder helpers; `PSC1Kernel.infer`, `PSC1Kernel.CheckerContext`, accepted KernelCore Environment/LocalContext/Reduce representations.
- Produces: a failing test suite that pins the complete Phase-4 inference overlap before `Ps.KernelCore.Infer` exists.

- [ ] **Step 1: Import the missing trusted module and add test-only representation adapters**

Add:

```text
import Ps.KernelCore.Infer
import PSC1Kernel.TypeChecker
```

Define test-only structural comparators/builders for `Name`, `Level`, binder info, literals, and every `Expr` constructor. Follow the existing `KernelCoreReductionParityTests.lean` adapter style; do not move these adapters into trusted source.

Compare:

```text
PsKernelCoreResult.ok expr    <-> Except.ok expr
PsKernelCoreResult.error msg  <-> Except.error msg
```

for the exact stable errors listed in the spec.

- [ ] **Step 2: Add paired environment/local-context fixture builders**

Provide matched KernelCore/reference fixtures for:

- empty environment/local context;
- ordinary local and let declarations;
- safe, unsafe, and partial definitions;
- monomorphic constants;
- polymorphic constants;
- constants whose type is a visible forall;
- a definition that delta-unfolds to a forall for the hidden-forall application case.

Use unchecked environment insertion on both sides so the fixture isolates inference semantics rather than declaration admission.

Reference calls use `PSC1Kernel.infer` with a `CheckerContext` carrying the matched environment/local context. KernelCore calls use a documented sufficient inference budget such as `64` unless the case is explicitly testing budget behavior.

- [ ] **Step 3: Pin positive differential inference cases**

Compare KernelCore with `PSC1Kernel.infer` for at least:

1. `sort u -> sort (succ u)`;
2. ordinary local free-variable lookup;
3. let-local lookup returns its declared type;
4. monomorphic constant type;
5. polymorphic constant type with universe substitution visible under nested expression positions;
6. bounded Nat literal -> `Nat`;
7. String literal -> `String`;
8. metadata transparency;
9. nondependent lambda;
10. nested/dependent lambda whose inferred type requires closing an outer fresh local under an inner binder;
11. simple forall universe formation via `imax`;
12. nested/dependent forall;
13. nondependent let whose type-level let is removed;
14. dependent let whose result type contains the fresh let local and therefore retains a `letE` after abstraction;
15. visible forall application;
16. dependent multi-application;
17. hidden forall exposed by Phase-3 delta reduction;
18. application with an intentionally non-inferable argument (for example an expression `mvar`) that still returns the function result type because infer-only mode does not inspect the argument;
19. lambda with a deliberately invalid/non-type domain that is still accepted in infer-only mode;
20. let with deliberately invalid declared type/value that is still accepted in infer-only mode;
21. unsafe constant accepted in infer-only mode;
22. partial constant accepted in infer-only mode.

Include a fixture with a pre-existing local context entry so nested fresh binder names prove the `.num userName nextIndex` strategy does not reuse the existing local name/index.

- [ ] **Step 4: Pin overlapping negative reference cases**

Compare exact semantic errors for:

1. loose bound variable -> `loose bound variable in type checker`;
2. expression metavariable -> `kernel type checker does not support metavariables`;
3. absent free variable -> `unknown free variable`;
4. absent constant -> `unknown constant`;
5. universe-level arity mismatch -> `incorrect number of universe levels`;
6. forall domain whose inferred type cannot be exposed as a sort -> `expected sort`;
7. application whose function type cannot be exposed as a forall -> `expected function type`.

- [ ] **Step 5: Pin KernelCore-only Phase-4 boundaries**

Assert exactly:

```text
psKernelCoreInfer 0 ... (sort zero)
  -> error "inference budget exhausted"

psKernelCoreInfer 1 ... (sort zero)
  -> ok (sort (succ zero))

psKernelCoreInfer sufficient ... (proj ...)
  -> error "projection inference unavailable before inductive metadata"
```

Also assert that a hidden-forall application with insufficient WHNF budget propagates the existing Phase-3 reduction-budget error rather than inventing a second hidden reduction path.

- [ ] **Step 6: Run and verify inference RED**

Run:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_infer_parity_tests
```

Expected: FAIL because `Ps.KernelCore.Infer` does not exist.

- [ ] **Step 7: Commit the inference RED fixture**

Commit message:

```text
test(pskernel-core): add infer-only differential red gate
```

---

### Task 4: GREEN — Total PSC1-native infer-only semantics

**Files:**
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Infer.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`
- Test: `psc15selfhost/test/KernelCoreInferParityTests.lean`

**Interfaces:**
- Consumes:

```text
psKernelCoreWhnf
  : Nat -> PsKernelCoreEnvironment -> PsKernelCoreLocalContext
  -> PsKernelCoreExpr -> PsKernelCoreResult String PsKernelCoreExpr

psKernelCoreExprInstantiate1
  : PsKernelCoreExpr -> PsKernelCoreExpr -> PsKernelCoreExpr

psKernelCoreExprInstantiateLevelParams
  : PsKernelCoreExpr
  -> PsKernelCoreList PsKernelCoreName
  -> PsKernelCoreList PsKernelCoreLevel
  -> PsKernelCoreOption PsKernelCoreExpr

psKernelCoreExprHasFVarName
  : PsKernelCoreExpr -> PsKernelCoreName -> Bool

psKernelCoreExprAbstractFVar
  : PsKernelCoreExpr -> PsKernelCoreName -> PsKernelCoreExpr

psKernelCoreEnvironmentFind?
  : PsKernelCoreEnvironment -> PsKernelCoreName
  -> PsKernelCoreOption PsKernelCoreConstantInfo

psKernelCoreLocalContextFind?
psKernelCoreLocalContextAddLocal
psKernelCoreLocalContextAddLet
psKernelCoreConstantInfoType
psKernelCoreConstantInfoLevelParams
psKernelCoreLocalDeclType
psKernelCoreLevelMkIMax
```

- Produces the exact Phase-4 public API:

```text
psKernelCoreInfer
  : Nat
  -> PsKernelCoreEnvironment
  -> PsKernelCoreLocalContext
  -> PsKernelCoreExpr
  -> PsKernelCoreResult String PsKernelCoreExpr

psKernelCoreEnsureSort
  : Nat
  -> PsKernelCoreEnvironment
  -> PsKernelCoreLocalContext
  -> PsKernelCoreExpr
  -> PsKernelCoreResult String PsKernelCoreLevel

psKernelCoreEnsureForall
  : Nat
  -> PsKernelCoreEnvironment
  -> PsKernelCoreLocalContext
  -> PsKernelCoreExpr
  -> PsKernelCoreResult String PsKernelCoreExpr
```

- [ ] **Step 1: Implement the two WHNF exposure helpers**

`psKernelCoreEnsureSort` calls `psKernelCoreWhnf` with the supplied budget, returns the level for `sort level`, propagates WHNF errors unchanged, and otherwise returns `expected sort`.

`psKernelCoreEnsureForall` calls `psKernelCoreWhnf`, returns the reduced `forallE` expression unchanged, propagates WHNF errors unchanged, and otherwise returns `expected function type`.

Do not invoke inference or DefEq inside either helper.

- [ ] **Step 2: Implement total budget shape and leaf cases**

Use the established Phase-3 recursion pattern:

```text
budget = 0 -> error "inference budget exhausted"
budget = succ remaining -> bind smaller := psKernelCoreInfer remaining
```

Changing environment/local-context/expression arguments must be applied to the pre-bound `smaller` function so only `budget` is the structural recursive argument.

Implement:

- `bvar` exact error;
- `mvar` exact error;
- `fvar` lookup / unknown error;
- `sort u -> sort (succ u)`;
- metadata delegates to `smaller` on its child;
- `proj` exact deferred-feature error.

- [ ] **Step 3: Implement constants and literals**

For constants:

1. environment lookup;
2. absent -> `unknown constant`;
3. instantiate `psKernelCoreConstantInfoType info` using `psKernelCoreExprInstantiateLevelParams` with `psKernelCoreConstantInfoLevelParams info` and supplied levels;
4. `none` -> `incorrect number of universe levels`;
5. `some type` -> return it.

Do not inspect `isUnsafe` or `isPartial`.

Represent literal types with root names exactly equivalent to:

```text
Nat
String
```

using `PsKernelCoreName.str PsKernelCoreName.anonymous ...`, with empty universe lists.

- [ ] **Step 4: Implement lambda inference**

For `lam name domain body binderInfo`:

1. `fresh := PsKernelCoreName.num name lctx.nextIndex`;
2. `child := psKernelCoreLocalContextAddLocal lctx fresh name domain binderInfo`;
3. `openedBody := psKernelCoreExprInstantiate1 body (PsKernelCoreExpr.fvar fresh)`;
4. infer opened body with `smaller env child openedBody`;
5. abstract `fresh` from the inferred body type with `psKernelCoreExprAbstractFVar`;
6. return `forallE name domain closedBodyType binderInfo`.

Do not infer/check `domain` in this branch.

- [ ] **Step 5: Implement forall inference**

For `forallE name domain body binderInfo`:

1. infer `domain` with `smaller`;
2. expose that inferred type with `psKernelCoreEnsureSort remaining ...`;
3. open the body under a fresh local as for lambda;
4. infer opened body with `smaller`;
5. expose the inferred body type with `psKernelCoreEnsureSort remaining ...`;
6. return `sort (psKernelCoreLevelMkIMax domainLevel bodyLevel)`.

Both recursive inference branches use the same `remaining` depth because the Phase-4 budget is a depth bound, not a global consumed-step counter.

- [ ] **Step 6: Implement let inference**

For `letE name type value body nondep`:

1. create `fresh := .num name lctx.nextIndex`;
2. extend context with `psKernelCoreLocalContextAddLet lctx fresh name type value`;
3. open body with `fvar fresh`;
4. infer opened body with `smaller`;
5. if `psKernelCoreExprHasFVarName inferredType fresh` is false, return `inferredType` directly;
6. otherwise return `letE name type value (psKernelCoreExprAbstractFVar inferredType fresh) nondep`.

Do not infer/check `type` or `value` in this phase.

- [ ] **Step 7: Implement infer-only applications**

For `app fn arg`:

1. infer only `fn` with `smaller`;
2. call `psKernelCoreEnsureForall remaining env lctx fnType`;
3. pattern-match the returned `forallE _ _ body _`;
4. return `psKernelCoreExprInstantiate1 body arg`.

Never invoke inference on `arg` in Phase 4.

Use this simple per-application rule first because it is sufficient for the spec's direct fixtures. If and only if a required differential fixture fails due to the mature whole-spine delayed-substitution ordering, replace this branch with the smallest PSC1-total spine helper that makes the existing fixture pass; do not remove or weaken the fixture.

- [ ] **Step 8: Export `Ps.KernelCore.Infer`**

Add `import Ps.KernelCore.Infer` to `packages/pskernel-core/src/Ps/KernelCore.lean` only after the RED fixture from Task 3 exists.

- [ ] **Step 9: Run direct Phase-4 parity GREEN**

Run:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_infer_parity_tests
```

Expected: all binder, differential inference, budget, and deferred-projection cases pass.

- [ ] **Step 10: Run actual PSC1 source/self-host gate**

Run:

```bash
cd psc15selfhost
node scripts/check-kernel-core-source.mjs
```

Expected: every trusted module, including `Infer.lean` and the expanded `Subst.lean`, passes the actual `psc1 check` path.

If PSC1 rejects recursion/syntax accepted by Lean, rewrite trusted code; never weaken the checker.

- [ ] **Step 11: Run lower-layer and repository regression gates**

Run:

```bash
cd psc15selfhost
npm run assurance:kernel-core:phase3
npm run check
```

Expected: both commands exit successfully.

- [ ] **Step 12: Commit the inference implementation**

Commit message:

```text
feat(pskernel-core): add minimal infer-only semantics
```

---

### Task 5: Phase-4 aggregate assurance, exact-head evidence, and acceptance

**Files:**
- Modify: `psc15selfhost/package.json`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`
- Create after green exact-head verification: `psc15selfhost/docs/continuity/PHASE4_ACCEPTANCE.md`

**Interfaces:**
- Consumes: all accepted Phase-1/2/3 gates plus the completed inference parity executable and automatic source/size reporters.
- Produces: one deterministic Phase-4 aggregate command, exact-head CI evidence, and a durable acceptance/non-claim record.

- [ ] **Step 1: Add `assurance:kernel-core:phase4` without modifying older commands**

The command must run, in order:

```text
npm run check:kernel-core-source
lake exe psc2_kernel_core_boundary_tests
lake exe psc2_kernel_core_name_parity_tests
lake exe psc2_kernel_core_level_parity_tests
lake exe psc2_kernel_core_expr_parity_tests
lake exe psc2_kernel_core_subst_parity_tests
lake exe psc2_kernel_core_declaration_parity_tests
lake exe psc2_kernel_core_environment_parity_tests
lake exe psc2_kernel_core_local_context_parity_tests
lake exe psc2_kernel_core_reduction_parity_tests
lake exe psc2_kernel_core_infer_parity_tests
node scripts/report-kernel-core-size.mjs
```

Do not edit the Phase-1, Phase-2, or Phase-3 assurance command bodies.

- [ ] **Step 2: Add the Phase-4 aggregate workflow step**

After `Phase 3 aggregate assurance`, add:

```bash
cd psc15selfhost
npm run assurance:kernel-core:phase4
```

Keep `Existing PSC2 regression gate` (`npm run check`) after Phase-4 assurance.

The final CI semantic order is:

```text
boundary
Name
Level
Expr
Subst
Declaration
Environment
LocalContext
basic reduction
minimal inference
bootstrap isolation
PSC1 source profile
Phase 1 aggregate
Phase 2 aggregate
Phase 3 aggregate
Phase 4 aggregate
full existing regression
```

- [ ] **Step 3: Commit assurance wiring**

Commit message:

```text
ci(pskernel-core): add Phase 4 inference assurance
```

- [ ] **Step 4: Obtain fresh exact-head verification evidence**

On the exact implementation/assurance SHA run and record:

```bash
cd psc15selfhost
npm run assurance:kernel-core:phase4
npm run check
```

In GitHub Actions confirm the exact SHA's `PSC2 minimal kernel` job completes successfully through both `Phase 4 aggregate assurance` and `Existing PSC2 regression gate`.

Record:

- exact implementation/assurance SHA;
- workflow run ID;
- job ID;
- `KERNEL_CORE_SOURCE_PROFILE` trusted-module count;
- size reporter trusted files / bytes / nonblank-noncomment LOC;
- comparable reference files / bytes / LOC and ratios.

Do not infer these figures from Phase 3; copy them from the fresh Phase-4 run.

- [ ] **Step 5: Write `PHASE4_ACCEPTANCE.md` from measured evidence**

The acceptance record must include:

- branch and tested SHA;
- workflow run/job IDs;
- exact direct parity/source/aggregate/full-regression results;
- trusted source size evidence;
- implemented infer-only surface;
- evidence that application arguments, lambda domains, let type/values, unsafe/partial restrictions are intentionally unchecked in this phase;
- stable projection fail-closed behavior;
- Phase-5 dependency handoff.

Allowed claims must stay scoped to the tested infer-only overlap.

Explicit non-claims must include at least:

- no checked inference/type checker completeness;
- no DefEq/proof irrelevance/eta;
- no projection/inductive/recursor correctness;
- no Quot correctness;
- no full Lean 4.34 inference/kernel equivalence;
- no active compiler admission provider;
- no executable/fixed-point self-host completion;
- size ratio is not a prediction of the final completed kernel.

The recommended next phase is **Phase 5 definitional equality built on accepted Phase-3 WHNF + Phase-4 inference**, with its own architectural spec and differential gates.

- [ ] **Step 6: Verify acceptance commit is documentation-only after the tested SHA**

Compare the tested implementation/assurance SHA with the acceptance-doc commit.

Expected: exactly one changed file:

```text
psc15selfhost/docs/continuity/PHASE4_ACCEPTANCE.md
```

If code/build/CI changed after the tested SHA, rerun exact-head verification instead of claiming the older run covers the delivered tree.

- [ ] **Step 7: Review branch scope and integrate through PR**

Compare the work branch against the reviewed Phase-4 plan head. The changed set should be limited to:

- `Subst.lean` binder helpers;
- new `Infer.lean`;
- KernelCore aggregate export;
- inference parity fixture;
- Lake/package/workflow assurance wiring;
- Phase-4 acceptance record.

No DefEq, Quot, inductive/recursor, compiler-provider, backend, cache/session, replay, or bootstrap-source files may appear unless a separately reviewed amendment explains why.

Open a PR from `psc2/kernel-core-phase4-infer-work` to `psc2/kernel-core-phase4-infer`. Merge only after it is mergeable and the exact-head evidence remains valid.
