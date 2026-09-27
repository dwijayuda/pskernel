# PSC2 KernelCore Phase 7 Primitive/Resource Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add PSC1-self-hostable Nat resource policy and the mandatory Phase-7 Nat primitive reductions, then propagate one explicit resource configuration through WHNF, Infer, DefEq, Check, and ordinary Admission without breaking accepted Phase-1 through Phase-6 APIs.

**Architecture:** Add trusted `Ps.KernelCore.Resource` and `Ps.KernelCore.Primitive`. Resource owns Nat-size/count policy; Primitive owns pure names, recognition, and arithmetic results and never imports Reduce. Existing semantic layers gain `(budget, resources, ...)` `WithResources` entry points; existing public entry points become default-resource wrappers. Every configured path must call configured children only—never an old default wrapper internally—or custom resource policy would be lost.

**Tech Stack:** Lean 4.34.0, PSC1 trusted `.lean` subset, Lake, Node 22, npm workspaces, GitHub Actions, mature `PSC1Kernel` differential oracle.

**Spec:** `psc15selfhost/docs/superpowers/specs/2026-09-27-psc2-kernel-core-phase7-primitives-design.md`

## Global Constraints

- Execute on isolated branch `psc2/kernel-core-phase7-primitives-work` created from the reviewed plan head.
- Trusted source remains accepted by the unchanged `scripts/check-kernel-core-source.mjs`; never weaken restrictions or timeout.
- No `partial`, `unsafe`, `extern`, `implemented_by`, host IO, `Lean.*`, `Std.*`, macros, custom elaborators, termination annotations, caches, or native callbacks in trusted KernelCore.
- Preserve every accepted Phase-1 through Phase-6 public API, error contract, direct gate, aggregate command, and full regression.
- Existing `Nat` budgets remain the trusted termination/depth boundary; no exact Lean `maxRecDepth`/heartbeat claim.
- Default `maxNatSize` is exactly `128 * 1024 * 1024` bytes.
- Mandatory Phase-7 primitives are exactly `Nat.succ`, `Nat.add`, `Nat.sub`, `Nat.mul`, `Nat.pow`, `Nat.gcd`, `Nat.mod`, `Nat.div`, `Nat.beq`, `Nat.ble`, plus `Nat.zero`/literal recognition.
- Phase 7B bitwise/shift primitives are **not** implemented by this plan and do not gate Phase-7 acceptance.
- No native reduction, eagerReduce, Quot, inductive/constructor/recursor, iota, projection, structure eta, string-constructor expansion, compiler cutover, or corpus claim enters this plan.
- Observe RED before each semantic GREEN change.
- Reconcile concurrent branch changes instead of overwriting them.

## File Map

Create trusted:
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Resource.lean`
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Primitive.lean`

Modify trusted:
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Reduce.lean`
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Infer.lean`
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/DefEq.lean`
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Check.lean`
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Admission.lean`

Create tests:
- `psc15selfhost/test/KernelCoreResourceParityTests.lean`
- `psc15selfhost/test/KernelCorePrimitiveParityTests.lean`
- `psc15selfhost/test/KernelCoreResourceIntegrationTests.lean`

Modify build/assurance:
- `psc15selfhost/lakefile.lean`
- `psc15selfhost/package.json`
- `.github/workflows/psc2-minimal-kernel.yml`
- `psc15selfhost/docs/continuity/PHASE7_ACCEPTANCE.md` only after exact-head success.

## Review Focus

1. **Primitive-vs-delta exposure:** aliases/operands exposed by ordinary delta must reach the same selected primitive result as mature `PSC1Kernel`; malformed primitive shapes stay residual. Task 5 owns this.
2. **Resource-vs-budget errors:** tiny `maxNatSize` must yield the Nat resource error while budget `0` keeps the existing layer budget error. Tasks 1 and 5 own this.
3. **`Nat.pow` ordering:** exponent `> UInt32` rejects before result computation even for base `0`/`1`; an in-range growth rejection uses the distinct mature pow message. Task 3 owns this.
4. **Boundary result growth:** succ/add/mul exact-at-size-limit succeeds and first-over-limit rejects. Task 3 owns this.
5. **Resource propagation and wrappers:** deeply nested configured DefEq/Check/Admission must keep the custom config, while old APIs must equal configured APIs under the default config. Task 5 owns both sides.

---

### Task 1: Resource RED gate

**Files:** create `test/KernelCoreResourceParityTests.lean`; modify `lakefile.lean` and workflow.

**Interfaces:** future Resource APIs:

```text
PsKernelCoreResourceConfig { maxNatSize : Nat }
psKernelCoreLeanNatMaxSizeDefault : Nat
psKernelCoreResourceConfigDefault : PsKernelCoreResourceConfig
psKernelCoreLeanUInt32Max : Nat
psKernelCoreLeanMaxSmallNat : Nat
psKernelCoreNatHeapWordCount : Nat -> Nat
psKernelCoreNatSizeInBytes : Nat -> Nat
psKernelCoreCheckNatSize : PsKernelCoreResourceConfig -> Nat -> PsKernelCoreResult String Unit
psKernelCoreCheckCountArg : String -> Nat -> PsKernelCoreResult String Unit
```

- [ ] Create `psc2/kernel-core-phase7-primitives-work` from the reviewed plan head and verify 0-behind.
- [ ] Write `KernelCoreResourceParityTests.lean` importing missing `Ps.KernelCore.Resource` and `PSC1Kernel.TypeChecker`.
- [ ] Pin constants against `leanNatMaxSizeDefault`, `leanUInt32Max`, `leanMaxSmallNat`.
- [ ] Pin `natSizeInBytes` parity at `0`, `1`, max-small, max-small+1, `2^64-1`, `2^64`, `2^128-1`, `2^128`.
- [ ] With tiny configs, pin exact-at-limit success and just-over-limit exact error `the kernel refused a Nat numeral because its size exceeds the maximum`.
- [ ] Pin count helper at UInt32 max and max+1 with exact operation interpolation; assert resource error is not a budget error.
- [ ] Add Lake executable `psc2_kernel_core_resource_parity_tests` and workflow branches `psc2/kernel-core-phase7-primitives` / `...-work`; put `Resource parity test` after Local Context and before Basic reduction. Do not add Phase-7 aggregate yet.
- [ ] Run `lake exe psc2_kernel_core_resource_parity_tests`; require RED because module/APIs are missing, with earlier direct gates green.
- [ ] Commit `test(pskernel-core): add Phase 7 resource red gate`.

---

### Task 2: GREEN Resource semantics

**Files:** create `Resource.lean`; export from `Ps.KernelCore.lean`.

**Interfaces:** exactly the Task-1 signatures.

- [ ] Define exact constants: default `128 * 1024 * 1024`, UInt32 max `4294967295`, max-small `9223372036854775807`, 64-bit limb divisor `18446744073709551616`.
- [ ] Implement PSC1-total `psKernelCoreNatHeapWordCountFuel (fuel : Nat) : Nat -> Nat`. Structural recursion is on `fuel`; initialize with input `n`; each live step divides current by `2^64`, decrements fuel, and returns early at current `0`. No `partial`/termination annotations.
- [ ] Define `psKernelCoreNatHeapWordCount n` via the fuel helper and `psKernelCoreNatSizeInBytes n`: `8` when `n <= maxSmall`, otherwise `8 * heapWordCount n`.
- [ ] If PSC1 rejects only the spelling of foundational Nat division, switch to the already-supported equivalent syntax/API; do not alter semantics or source policy.
- [ ] Implement exact Nat-size and count errors.
- [ ] Run `lake exe psc2_kernel_core_resource_parity_tests`; require `PSC2_KERNEL_CORE_RESOURCE_PARITY: PASS`.
- [ ] Immediately run `node scripts/check-kernel-core-source.mjs`; rewrite trusted code if PSC1 rejects it—never the gate.
- [ ] Run `npm run assurance:kernel-core:phase6` and `npm run check`; require PASS.
- [ ] Commit `feat(pskernel-core): add explicit Nat resource policy`.

---

### Task 3: Mandatory primitive RED gate

**Files:** create `test/KernelCorePrimitiveParityTests.lean`; modify Lake/workflow.

**Interfaces:** future Primitive APIs:

```text
psKernelCorePrimitiveNatName
psKernelCorePrimitiveBoolName
psKernelCorePrimitiveBoolTrueName
psKernelCorePrimitiveBoolFalseName
psKernelCorePrimitiveNatZeroName
psKernelCorePrimitiveNatSuccName
psKernelCorePrimitiveNatAddName
psKernelCorePrimitiveNatSubName
psKernelCorePrimitiveNatMulName
psKernelCorePrimitiveNatPowName
psKernelCorePrimitiveNatGcdName
psKernelCorePrimitiveNatModName
psKernelCorePrimitiveNatDivName
psKernelCorePrimitiveNatBeqName
psKernelCorePrimitiveNatBleName

psKernelCoreNatLiteralValue? : PsKernelCoreExpr -> PsKernelCoreOption Nat
psKernelCoreBoolExpr : Bool -> PsKernelCoreExpr
psKernelCoreIsNatZeroExpr : PsKernelCoreExpr -> Bool
psKernelCoreNatPredExpr? : PsKernelCoreExpr -> PsKernelCoreOption PsKernelCoreExpr
psKernelCoreReduceNatUnary : PsKernelCoreResourceConfig -> PsKernelCoreName -> Nat -> PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreExpr)
psKernelCoreReduceNatBinary : PsKernelCoreResourceConfig -> PsKernelCoreName -> Nat -> Nat -> PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreExpr)
```

- [ ] Write direct parity against mature Nat helpers/reduction for zero/pred recognition, succ, add/sub/mul, pow/gcd/mod/div, beq/ble, unknown op -> none.
- [ ] Pin `mod a 0 = a`, `div a 0 = 0`, Bool true/false results.
- [ ] Pin exponent UInt32 max acceptance on base `0` or `1`, and max+1 rejection on **both** bases before result computation.
- [ ] Pin in-range pow growth rejection under a tiny config with the distinct mature pow overflow message.
- [ ] Pin succ/add/mul exact resource boundary success and first-over-boundary rejection.
- [ ] Add Lake executable `psc2_kernel_core_primitive_parity_tests`; workflow step `Mandatory Nat primitive parity test` after Resource parity.
- [ ] Run direct test and require RED because `Primitive` is missing; Resource parity remains GREEN.
- [ ] Commit `test(pskernel-core): add mandatory Nat primitive red gate`.

---

### Task 4: GREEN pure mandatory Primitive semantics

**Files:** create `Primitive.lean`; export from `Ps.KernelCore.lean`.

**Interfaces:** implement all Task-3 APIs; `Primitive` imports Resource plus foundational Name/Expr/Data only, never Reduce.

- [ ] Build exact names with `PsKernelCoreName.str`/`anonymous`; helpers recognize literal Nat and zero-level `Nat.zero` only.
- [ ] `psKernelCoreBoolExpr` returns zero-level `Bool.true`/`Bool.false` constants.
- [ ] Implement total Euclidean gcd with `psKernelCoreNatGcdFuel (fuel : Nat) : Nat -> Nat -> Nat`, initialized at `b + 1`, recursing on fuel and `(b, a % b)` until divisor zero.
- [ ] Implement practical total pow using structurally decreasing fuel plus exponentiation by squaring; live exponent halves so the UInt32-max/base-0-or-1 test is not linear-time.
- [ ] `ReduceNatUnary` handles only succ, checks result size, unknown op -> `ok none`.
- [ ] `ReduceNatBinary` handles exactly add/sub/mul/pow/gcd/mod/div/beq/ble in mature order. Pow checks UInt32 first, then conservative growth, then computes/checks result. Add/sub/mul check result size. Mod/div zero behavior is pinned. beq/ble return Bool. Unknown -> `ok none`.
- [ ] Run Resource + Primitive tests; require markers `PSC2_KERNEL_CORE_RESOURCE_PARITY: PASS` and `PSC2_KERNEL_CORE_PRIMITIVE_PARITY: PASS`.
- [ ] Run actual PSC1 source profile, Phase-6 assurance, and `npm run check`; all must PASS.
- [ ] Commit `feat(pskernel-core): add mandatory Nat primitive semantics`.

---

### Task 5: Configured integration RED gate

**Files:** create `test/KernelCoreResourceIntegrationTests.lean`; modify Lake/workflow.

**Interfaces:** future configured APIs, with exact parameter order:

```text
psKernelCoreWhnfWithResources
  (budget : Nat) (resources : PsKernelCoreResourceConfig) :
  PsKernelCoreEnvironment -> PsKernelCoreLocalContext -> PsKernelCoreExpr -> PsKernelCoreResult String PsKernelCoreExpr

psKernelCoreEnsureSortWithResources
  (budget : Nat) (resources : PsKernelCoreResourceConfig)
  (env : PsKernelCoreEnvironment) (lctx : PsKernelCoreLocalContext)
  (expr : PsKernelCoreExpr) : PsKernelCoreResult String PsKernelCoreLevel

psKernelCoreEnsureForallWithResources
  (budget : Nat) (resources : PsKernelCoreResourceConfig)
  (env : PsKernelCoreEnvironment) (lctx : PsKernelCoreLocalContext)
  (expr : PsKernelCoreExpr) : PsKernelCoreResult String PsKernelCoreExpr

psKernelCoreInferWithResources
  (budget : Nat) (resources : PsKernelCoreResourceConfig) : Env -> LCtx -> Expr -> Result Expr

psKernelCoreIsDefEqWithResources
  (budget : Nat) (resources : PsKernelCoreResourceConfig) : Env -> LCtx -> Expr -> Expr -> Result Bool

psKernelCoreCheckWithResources
  (budget : Nat) (resources : PsKernelCoreResourceConfig) : Env -> LCtx -> DefinitionSafety -> Expr -> Result Expr

psKernelCoreAddAxiomWithResources
psKernelCoreAddDefinitionWithResources
psKernelCoreAddTheoremWithResources
psKernelCoreAddOpaqueWithResources
```

The four admission tails stay `Environment -> Info -> Result Environment`.

- [ ] Pin configured WHNF direct mandatory primitives, beta/zeta exposure, delta alias head exposure, delta operand exposure, malformed arity, nonempty levels, nonliteral residual, tiny-resource rejection, and budget-0 reduction error.
- [ ] Compare selected WHNF overlap with mature `PSC1Kernel.whnf` under matching `maxNatSize`.
- [ ] Pin Infer custom-config literal accept/reject.
- [ ] Pin DefEq `Nat.add 2 3 ≡ 5`, `Nat.mul 3 4 ≡ 12`, `Nat.beq 2 2 ≡ Bool.true`.
- [ ] Pin Check custom-resource rejection and at least one compatibility case that succeeds only after primitive normalization.
- [ ] Pin Admission rejection of an oversized literal with unchanged original environment (`size`, old member, rejected-name absence, `quotInitialized`), plus one success whose body/type compatibility depends on primitive normalization.
- [ ] Add a **nested resource propagation regression**: use a tiny custom config where a theorem/opaque or definition reaches DefEq/WHNF below Admission. Require the tiny-config resource error. This fails if any configured path accidentally calls an old default wrapper internally.
- [ ] For representative success **and error** cases in WHNF, Infer, DefEq, Check, and all four Add* APIs, assert `oldAPI = WithResources defaultConfig`.
- [ ] Add Lake executable `psc2_kernel_core_resource_integration_tests`; workflow step `Configured primitive/resource integration test` after Primitive parity and before preserved Basic reduction.
- [ ] Run integration test and require RED because `WithResources` APIs are absent; Resource/Primitive direct tests remain GREEN.
- [ ] Commit `test(pskernel-core): add configured resource integration red gate`.

---

### Task 6: GREEN resource threading Reduce -> Admission

**Files:** modify `Reduce.lean`, `Infer.lean`, `DefEq.lean`, `Check.lean`, `Admission.lean`.

**Interfaces:** implement all Task-5 configured APIs. Existing public APIs become simple calls with `psKernelCoreResourceConfigDefault`.

- [ ] **Reduce:** create recursive `psKernelCoreWhnfWithResources (budget) (resources) ...`; budget remains first decreasing argument and resources invariant. Existing `psKernelCoreWhnf` is only a default wrapper.
- [ ] **Reduce app path:** recognize exact mandatory primitive shapes with zero levels; normalize operands through the smaller configured WHNF using the same config; call pure unary/binary Primitive helpers; otherwise preserve existing beta/delta/residual behavior. A delta alias may expose a primitive on a later bounded step. Do not introduce mutual recursion/module cycles.
- [ ] Preserve every existing Phase-3 reduction result and budget threshold; old reduction parity is authoritative.
- [ ] **Infer:** add shared `psKernelCoreInferLiteralWithResources (resources) (literal)`; Nat calls `CheckNatSize`, String keeps current type. Add configured EnsureSort, EnsureForall, Infer; old versions become default wrappers.
- [ ] **DefEq:** add `psKernelCoreDefEqIsPropWithResources` and resource parameters to every helper that calls Infer/WHNF: eta-left, eta-right, after-proof/fallback/reduced planning as required by the current first-order plan graph. Add `psKernelCoreIsDefEqWithResources`; its entire recursive/configured path uses configured Infer/WHNF only. Keep the first-order plan representation and Phase-5 rules unchanged. Old IsDefEq is a default wrapper.
- [ ] **Check:** add `psKernelCoreCheckWithResources`; recursive Check, Ensure, and DefEq calls all stay configured. Literal branch reuses `psKernelCoreInferLiteralWithResources` rather than duplicating Nat policy. Old Check becomes default wrapper. Preserve Phase-6 arity-before-safety order.
- [ ] **Admission:** add configured `AdmissionCheckBase`, `AdmissionCheckDefinitionBody`, and `AdmissionIsProp`. Add configured four public Add* functions. Replace **all direct** Check/DefEq/WHNF calls in AddDefinition, AddTheorem, and AddOpaque with configured variants, including theorem proof and opaque value checks—not only shared helper calls. Old four Add* functions become default wrappers.
- [ ] Audit rule: inside any `...WithResources` implementation/helper, grep/review for calls to old `psKernelCoreWhnf`, `psKernelCoreInfer`, `psKernelCoreIsDefEq`, `psKernelCoreCheck`, or old `psKernelCoreAdd*`; any such call is a blocker unless it is the outer default wrapper itself.
- [ ] Run the three new direct tests; require `RESOURCE_PARITY`, `PRIMITIVE_PARITY`, and `RESOURCE_INTEGRATION` PASS markers.
- [ ] Run all preserved direct gates in established order: boundary, name, level, expr, subst, declaration, environment, local context, reduction, inference, DefEq, Check, Check ordering, Admission. No relaxation.
- [ ] Run bootstrap isolation and actual PSC1 source profile; both PASS without source-gate changes.
- [ ] Run Phase-1 through Phase-6 aggregates and `npm run check`; all PASS.
- [ ] Commit `feat(pskernel-core): thread primitive resource semantics`.

---

### Task 7: Phase-7 assurance, exact-head acceptance, and merge

**Files:** modify `package.json`, workflow; create `docs/continuity/PHASE7_ACCEPTANCE.md` only after exact-head success.

- [ ] Add `assurance:kernel-core:phase7`; do **not** change Phase-1–6 commands. Order: source gate -> boundary/name/level/expr/subst/declaration/environment/local-context -> Resource -> Primitive -> reduction -> Infer -> DefEq -> Check -> Admission -> configured integration -> size report.
- [ ] Add workflow `Phase 7 aggregate assurance` after Phase 6 aggregate and before full regression. Keep the three new direct steps before preserved semantic gates as wired by prior tasks.
- [ ] Produce a fresh candidate implementation/assurance SHA containing all trusted/test/build/CI changes but no acceptance doc.
- [ ] Require one GitHub Actions run on that exact SHA with all new direct tests, all Phase-1–6 direct gates, bootstrap isolation, actual PSC1 source profile, Phase-1–7 aggregates, and `npm run check` = success. Record SHA/run/job/conclusion.
- [ ] Record exact trusted file count, bytes, nonblank/noncomment LOC, reference counts/ratios, and actual self-host-checkable module count using the same reference exclusions as prior phases.
- [ ] Only now write `PHASE7_ACCEPTANCE.md`. State accepted mandatory primitive set, configured APIs/default-wrapper evidence, exact CI/source/size evidence, allowed claims, and explicit non-claims including **all Phase-7B bitwise/shift operations**.
- [ ] Commit acceptance documentation separately; verify its parent is exactly the tested implementation SHA and its diff is documentation-only.
- [ ] Whole-branch scope review against reviewed plan head. Expected files are Resource/Primitive, five configured semantic modules, aggregate export, three Phase-7 tests, Lake/package/workflow, and acceptance doc. Any unrelated compiler/backend/Quot/inductive/native file blocks merge. If no independent subagent review is available, explicitly record self-review rather than implying independence.
- [ ] Open PR `psc2/kernel-core-phase7-primitives-work` -> `psc2/kernel-core-phase7-primitives`; merge only when mergeable and using the exact reviewed head SHA. No force update.
- [ ] Require post-merge CI success on the merge SHA through direct gates, actual PSC1 source checking, Phase-1–7 aggregate assurance, and full `npm run check` before declaring Phase 7 closed.

---

## Phase 7B follow-on boundary

This plan intentionally excludes `Nat.land`, `Nat.lor`, `Nat.xor`, `Nat.shiftLeft`, and `Nat.shiftRight`. After merged-head Phase-7 success, treat Phase 7B as its own next slice unless the user redirects the roadmap. Its implementation may not add `Std`/Lean trusted imports or weaken PSC1 source acceptance.