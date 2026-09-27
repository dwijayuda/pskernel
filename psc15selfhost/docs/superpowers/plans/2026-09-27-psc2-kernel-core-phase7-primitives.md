# PSC2 KernelCore Phase 7 Primitive/Resource Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add PSC1-self-hostable Nat resource policy and the mandatory Phase-7 Nat primitive reductions, then thread the same explicit resource configuration through WHNF, Infer, DefEq, Check, and ordinary Admission without breaking accepted Phase-1 through Phase-6 APIs.

**Architecture:** Add two trusted modules, `Ps.KernelCore.Resource` and `Ps.KernelCore.Primitive`. `Resource` owns only Nat-size/count policy; `Primitive` owns pure recognition and arithmetic result semantics. Existing semantic layers gain `WithResources` entry points with `(budget, resources, ...)` ordering, while their existing entry points become default-resource wrappers. `Reduce` alone owns recursive operand normalization so `Primitive` never depends on `Reduce` and no mutual recursion/module cycle is introduced.

**Tech Stack:** Lean 4.34.0, PSC1 trusted `.lean` subset, Lake, Node 22, npm workspaces, GitHub Actions, mature `PSC1Kernel` differential oracle.

**Spec:** `psc15selfhost/docs/superpowers/specs/2026-09-27-psc2-kernel-core-phase7-primitives-design.md`

## Global Constraints

- Start execution from reviewed branch `psc2/kernel-core-phase7-primitives` and create isolated branch `psc2/kernel-core-phase7-primitives-work`.
- Trusted implementation remains PSC1-subset `.lean`; do not weaken `scripts/check-kernel-core-source.mjs`.
- No `partial`, `unsafe`, `extern`, `implemented_by`, host IO, `Lean.*`, `Std.*`, macros, custom elaborators, termination machinery, host semantic `List`/`Option`, caches, or native callbacks in trusted KernelCore.
- The mature `PSC1Kernel` remains the direct semantic oracle.
- Existing Phase-1 through Phase-6 tests, aggregate assurance scripts, error contracts, and public API signatures remain available and green.
- Existing explicit `Nat` budgets remain KernelCore's termination/resource-depth boundary; do not claim exact Lean `maxRecDepth`/heartbeat parity.
- Default Nat resource limit is exactly `128 * 1024 * 1024` bytes.
- Mandatory Phase-7 primitives are exactly `Nat.succ`, `Nat.add`, `Nat.sub`, `Nat.mul`, `Nat.pow`, `Nat.gcd`, `Nat.mod`, `Nat.div`, `Nat.beq`, and `Nat.ble` plus `Nat.zero`/literal recognition.
- Phase 7B (`land`, `lor`, `xor`, `shiftLeft`, `shiftRight`) is not implemented by this plan and does not gate Phase-7 acceptance. Give it a separate follow-on cycle after Phase 7.
- No native reduction, `Lean.reduceNat`, `Lean.reduceBool`, `eagerReduce`, Quot, inductive/constructor/recursor, iota, projection computation, structure eta, string-constructor expansion, compiler cutover, or K7/K8 corpus claims enter this plan.
- Production semantics are written only after the corresponding intended RED failure is observed.
- If concurrent changes appear on the execution branch, stop and reconcile them against this plan instead of overwriting them.

## File Structure

**Create trusted source:**
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Resource.lean` — resource config, Nat-size model, count checks.
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Primitive.lean` — primitive names, literal recognition, pure unary/binary Nat operation results.

**Modify trusted source:**
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean` — export Resource and Primitive.
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Reduce.lean` — configured WHNF and primitive operand normalization/integration.
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Infer.lean` — configured ensure/infer entry points and shared literal typing.
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/DefEq.lean` — configured DefEq path using configured Infer/WHNF.
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Check.lean` — configured checked path using configured Infer/WHNF/DefEq.
- `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Admission.lean` — configured ordinary admission path.

**Create tests:**
- `psc15selfhost/test/KernelCoreResourceParityTests.lean`
- `psc15selfhost/test/KernelCorePrimitiveParityTests.lean`
- `psc15selfhost/test/KernelCoreResourceIntegrationTests.lean`

**Modify assurance/build:**
- `psc15selfhost/lakefile.lean`
- `psc15selfhost/package.json`
- `.github/workflows/psc2-minimal-kernel.yml`
- `psc15selfhost/docs/continuity/PHASE7_ACCEPTANCE.md` only after exact-head success.

## Review Focus

1. **Primitive-vs-delta exposure:** a user definition whose value exposes a mandatory primitive must reduce to the same selected result as mature `PSC1Kernel`; malformed primitive shapes must remain residual rather than being mistaken for builtins. Pin in Task 5.
2. **Resource error vs budget error:** a tiny `maxNatSize` must yield the Nat resource error, while budget `0` must still yield the existing layer-specific budget error. Pin in Tasks 1 and 5.
3. **`Nat.pow` ordering:** exponent `> UInt32` is rejected before attempting the result, including bases `0` and `1`; growth rejection for an in-range exponent uses the distinct mature pow overflow message. Pin in Task 3.
4. **Boundary result growth:** `Nat.succ`, add, and mul must accept a result exactly at the configured size boundary and reject the first result beyond it. Pin in Tasks 3 and 5.
5. **Compatibility wrappers:** every accepted old entry point must produce the same result as its `WithResources` counterpart under `psKernelCoreResourceConfigDefault`, including errors. Pin in Task 5.

---

### Task 1: Resource RED gate

**Files:**
- Create: `psc15selfhost/test/KernelCoreResourceParityTests.lean`
- Modify: `psc15selfhost/lakefile.lean`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`

**Interfaces:**
- Consumes mature oracle helpers from `PSC1Kernel.TypeChecker`: `leanNatMaxSizeDefault`, `leanUInt32Max`, `leanMaxSmallNat`, `natSizeInBytes`, `checkNatSize`, `checkCountArg`.
- Produces a failing executable contract for the trusted `Ps.KernelCore.Resource` APIs that Task 2 implements.

- [ ] **Step 1: Create the execution branch before touching tests**

Create `psc2/kernel-core-phase7-primitives-work` from the reviewed plan head. Verify it is 0 commits behind that head before writing any implementation/test commit.

- [ ] **Step 2: Write the Resource parity fixture that imports the missing module**

Create `KernelCoreResourceParityTests.lean` importing `Ps.KernelCore.Resource` and the mature TypeChecker reference. Test these exact contracts:

```text
psKernelCoreLeanNatMaxSizeDefault = PSC1Kernel.leanNatMaxSizeDefault
psKernelCoreLeanUInt32Max = PSC1Kernel.leanUInt32Max
psKernelCoreLeanMaxSmallNat = PSC1Kernel.leanMaxSmallNat
```

Pin `psKernelCoreNatSizeInBytes` against `PSC1Kernel.natSizeInBytes` at least for:

```text
0
1
leanMaxSmallNat
leanMaxSmallNat + 1
2^64 - 1
2^64
2^128 - 1
2^128
```

Use ordinary Nat construction available to the test oracle; tests may use Lean/reference conveniences because tests are not trusted KernelCore source.

Pin `psKernelCoreCheckNatSize` with small custom configs so no enormous numeral allocation is required:

- exact-at-limit succeeds;
- just-over-limit returns exactly `"the kernel refused a Nat numeral because its size exceeds the maximum"`.

Pin `psKernelCoreCheckCountArg` at `leanUInt32Max` and `leanUInt32Max + 1`; the rejected operation name must be interpolated into the mature-compatible message.

Also pin that resource failure is not any existing `"... budget exhausted"` string.

- [ ] **Step 3: Wire only the Resource RED executable and Phase-7 branch triggers**

Add to `lakefile.lean`:

```text
psc2_kernel_core_resource_parity_tests -> KernelCoreResourceParityTests
```

Add workflow push branches:

```text
psc2/kernel-core-phase7-primitives
psc2/kernel-core-phase7-primitives-work
```

Insert `Resource parity test` after Local Context parity and before Basic reduction parity. Do not add Phase-7 aggregate assurance yet.

- [ ] **Step 4: Run RED and require the intended missing-module/API failure**

Run:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_resource_parity_tests
```

Expected: FAIL because `Ps.KernelCore.Resource` / its required APIs do not exist. In GitHub CI, every earlier direct gate before the new Resource step must remain green. A fixture syntax/type failure is not valid RED.

- [ ] **Step 5: Commit the RED gate**

```bash
git add psc15selfhost/test/KernelCoreResourceParityTests.lean psc15selfhost/lakefile.lean .github/workflows/psc2-minimal-kernel.yml
git commit -m "test(pskernel-core): add Phase 7 resource red gate"
```

---

### Task 2: GREEN trusted Resource semantics

**Files:**
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Resource.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`
- Test: `psc15selfhost/test/KernelCoreResourceParityTests.lean`

**Interfaces:**
- Consumes only foundational Nat/String/Unit plus KernelCore `Data` result type.
- Produces:

```text
structure PsKernelCoreResourceConfig where
  maxNatSize : Nat

psKernelCoreLeanNatMaxSizeDefault : Nat
psKernelCoreResourceConfigDefault : PsKernelCoreResourceConfig
psKernelCoreLeanUInt32Max : Nat
psKernelCoreLeanMaxSmallNat : Nat
psKernelCoreNatHeapWordCount : Nat -> Nat
psKernelCoreNatSizeInBytes : Nat -> Nat
psKernelCoreCheckNatSize : PsKernelCoreResourceConfig -> Nat -> PsKernelCoreResult String Unit
psKernelCoreCheckCountArg : String -> Nat -> PsKernelCoreResult String Unit
```

- [ ] **Step 1: Implement the minimal resource constants/config**

Use exact values:

```text
maxNatSize default = 128 * 1024 * 1024
UInt32 max = 4294967295
max small Nat = 9223372036854775807
64-bit limb divisor = 18446744073709551616
```

Keep `Resource.lean` independent of `Expr`, `Environment`, and checker modules.

- [ ] **Step 2: Implement the PSC1-total Nat size model**

Use a structurally decreasing fuel helper, not `partial`/termination annotations. Pin this algorithmic shape:

```text
psKernelCoreNatHeapWordCountFuel (fuel : Nat) : Nat -> Nat
```

The recursive argument is `fuel`; initialize it from the input Nat. Each live iteration divides the current value by `2^64` and decrements fuel, but returns immediately when the current value is `0`. This makes recursion structurally admissible while performing only one step per 64-bit limb in normal execution.

`psKernelCoreNatHeapWordCount n` delegates to the fuel helper. `psKernelCoreNatSizeInBytes` returns `8` for `n <= psKernelCoreLeanMaxSmallNat`; otherwise `8 * psKernelCoreNatHeapWordCount n`.

If PSC1 rejects only the spelling of the foundational Nat division operation, change syntax to the already-supported equivalent; do not weaken the source gate or change the algorithm/resource semantics.

- [ ] **Step 3: Implement resource/count errors exactly**

`psKernelCoreCheckNatSize resources n` returns the exact Nat-size error when `psKernelCoreNatSizeInBytes n > resources.maxNatSize`.

`psKernelCoreCheckCountArg op count` returns the exact mature message when `count > psKernelCoreLeanUInt32Max`:

```text
the kernel refused to evaluate <op> because its second argument does not fit in a 32-bit unsigned integer
```

- [ ] **Step 4: Export `Resource` from `Ps.KernelCore` and run direct GREEN**

Run:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_resource_parity_tests
```

Expected: `PSC2_KERNEL_CORE_RESOURCE_PARITY: PASS` (use this stable fixture marker).

- [ ] **Step 5: Run the actual trusted-source gate immediately**

Run:

```bash
node scripts/check-kernel-core-source.mjs
```

Expected: PASS with the new Resource module discovered automatically. If PSC1 rejects recursion or source syntax, rewrite the trusted implementation; do not modify the checker restrictions/timeouts.

- [ ] **Step 6: Run preserved lower assurance**

Run at minimum:

```bash
npm run assurance:kernel-core:phase6
npm run check
```

Expected: both PASS.

- [ ] **Step 7: Commit Resource GREEN**

```bash
git add psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Resource.lean psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean
git commit -m "feat(pskernel-core): add explicit Nat resource policy"
```

---

### Task 3: Mandatory primitive RED gate

**Files:**
- Create: `psc15selfhost/test/KernelCorePrimitiveParityTests.lean`
- Modify: `psc15selfhost/lakefile.lean`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`

**Interfaces:**
- Consumes Task-2 Resource APIs and mature `PSC1Kernel.reduceNatBinary`/Nat helper behavior.
- Produces the failing contract for Task-4 `Ps.KernelCore.Primitive`.

- [ ] **Step 1: Write direct primitive parity tests importing the missing module**

Create `KernelCorePrimitiveParityTests.lean` importing `Ps.KernelCore.Primitive` plus the mature TypeChecker oracle.

Require these names/helpers from the future module:

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

- [ ] **Step 2: Pin the mandatory unary/binary result matrix**

Use small operands and compare normalized result expressions/errors with mature `PSC1Kernel` behavior for:

```text
succ
add
sub including underflow to 0
mul
pow
gcd
mod including divisor 0 -> left operand
div including divisor 0 -> 0
beq true/false
ble true/false
```

Unknown operation names must return `none`, not error.

Pin literal/zero recognition and predecessor behavior for literal `0`, positive literals, `Nat.zero`, `Nat.succ x`, and unrelated expressions.

- [ ] **Step 3: Pin the Review-Focus resource/order cases**

Tests must include:

- `Nat.pow` exponent exactly UInt32 max is accepted by the count check path when the result is otherwise safe/practical to evaluate; use base `0` or `1` to avoid giant output.
- exponent UInt32 max + 1 rejects **even for base `0` and base `1`** with the count error.
- an in-range exponent/base pair whose mature conservative size precheck exceeds a tiny configured `maxNatSize` returns the distinct mature pow growth message.
- `succ`, add, and mul exact-at-size-limit success and first-over-limit rejection under tiny configs.

Do not allocate a 128 MiB numeral merely to exercise the default constant.

- [ ] **Step 4: Wire the primitive RED executable**

Add:

```text
psc2_kernel_core_primitive_parity_tests -> KernelCorePrimitiveParityTests
```

Insert workflow step `Mandatory Nat primitive parity test` immediately after Resource parity and before Basic reduction parity.

- [ ] **Step 5: Run RED**

Run:

```bash
lake exe psc2_kernel_core_primitive_parity_tests
```

Expected: FAIL because `Ps.KernelCore.Primitive` / APIs do not exist. Resource parity must stay GREEN.

- [ ] **Step 6: Commit RED**

```bash
git add psc15selfhost/test/KernelCorePrimitiveParityTests.lean psc15selfhost/lakefile.lean .github/workflows/psc2-minimal-kernel.yml
git commit -m "test(pskernel-core): add mandatory Nat primitive red gate"
```

---

### Task 4: GREEN pure mandatory primitive semantics

**Files:**
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Primitive.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`
- Test: `psc15selfhost/test/KernelCorePrimitiveParityTests.lean`

**Interfaces:**
- Consumes Task-2 `PsKernelCoreResourceConfig`, Nat-size/count helpers, and existing KernelCore Name/Expr/Data types.
- Produces all direct helper APIs declared by Task 3. It does **not** import `Reduce` or call WHNF.

- [ ] **Step 1: Implement exact primitive names and literal helpers**

Build names using `PsKernelCoreName.str`/`anonymous` only. Preserve zero-level recognition: primitive reduction only recognizes these builtins with zero universe levels when expression shape is checked later by Reduce.

`psKernelCoreNatLiteralValue?` recognizes:

- `.lit (.nat n)` as `some n`;
- `Nat.zero` with no levels as `some 0`;
- otherwise `none`.

`psKernelCoreBoolExpr` returns `Bool.true` / `Bool.false` constants with no levels.

- [ ] **Step 2: Implement total helper algorithms for gcd and pow**

Do not use `partial` or termination annotations.

For gcd, use a structurally decreasing fuel function:

```text
psKernelCoreNatGcdFuel (fuel : Nat) : Nat -> Nat -> Nat
```

Initialize fuel to `b + 1`; stop when divisor is zero; otherwise recurse with `(b, a % b)` and decremented fuel. The early divisor-zero test makes execution follow Euclidean depth, while fuel proves totality to PSC1.

For pow, use a structurally decreasing fuel/exponent implementation that is practical for large exponents with base `0`/`1`. Prefer exponentiation by squaring with the recursive fuel argument decreasing each step and the live exponent halving; do not implement a linear loop that would make the UInt32 boundary fixture unusable.

- [ ] **Step 3: Implement unary primitive semantics**

`psKernelCoreReduceNatUnary resources op value` handles only `Nat.succ`. Check the resulting Nat size before returning `.lit (.nat (value + 1))`; unknown `op` returns `ok none`.

- [ ] **Step 4: Implement binary primitive semantics in mature order**

`psKernelCoreReduceNatBinary resources op a b` handles exactly:

```text
add sub mul pow gcd mod div beq ble
```

Use these pinned rules:

- add/sub/mul Nat result -> check Nat size before success;
- pow -> call `psKernelCoreCheckCountArg "Nat.pow" b` first, then conservative growth precheck, then compute and check result;
- gcd -> literal gcd result;
- mod by 0 -> `a`;
- div by 0 -> `0`;
- beq/ble -> Bool constants and no Nat-result size check;
- unknown op -> `ok none`.

Use the mature pow pre-result error text from the spec exactly.

- [ ] **Step 5: Run direct primitive GREEN and PSC1 source gate**

Run:

```bash
lake exe psc2_kernel_core_resource_parity_tests
lake exe psc2_kernel_core_primitive_parity_tests
node scripts/check-kernel-core-source.mjs
```

Expected: resource and primitive PASS; actual PSC1 source profile PASS with both new trusted modules.

- [ ] **Step 6: Run preserved Phase-6 assurance/full regression**

Run:

```bash
npm run assurance:kernel-core:phase6
npm run check
```

Expected: PASS.

- [ ] **Step 7: Commit primitive GREEN**

```bash
git add psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Primitive.lean psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean
git commit -m "feat(pskernel-core): add mandatory Nat primitive semantics"
```

---

### Task 5: Configured integration RED gate

**Files:**
- Create: `psc15selfhost/test/KernelCoreResourceIntegrationTests.lean`
- Modify: `psc15selfhost/lakefile.lean`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`

**Interfaces:**
- Consumes Tasks 2/4 pure Resource/Primitive APIs and existing Phase-3–6 public APIs.
- Produces the failing contract for configured APIs and wrapper compatibility that Task 6 implements.

- [ ] **Step 1: Write the configured integration fixture using missing `WithResources` APIs**

Require these exact public signatures/argument order:

```text
psKernelCoreWhnfWithResources
  (budget : Nat)
  (resources : PsKernelCoreResourceConfig) :
  PsKernelCoreEnvironment -> PsKernelCoreLocalContext -> PsKernelCoreExpr ->
  PsKernelCoreResult String PsKernelCoreExpr

psKernelCoreEnsureSortWithResources
  (budget : Nat) (resources : PsKernelCoreResourceConfig)
  (env : PsKernelCoreEnvironment) (lctx : PsKernelCoreLocalContext)
  (expr : PsKernelCoreExpr) : PsKernelCoreResult String PsKernelCoreLevel

psKernelCoreEnsureForallWithResources
  (budget : Nat) (resources : PsKernelCoreResourceConfig)
  (env : PsKernelCoreEnvironment) (lctx : PsKernelCoreLocalContext)
  (expr : PsKernelCoreExpr) : PsKernelCoreResult String PsKernelCoreExpr

psKernelCoreInferWithResources
  (budget : Nat) (resources : PsKernelCoreResourceConfig) :
  PsKernelCoreEnvironment -> PsKernelCoreLocalContext -> PsKernelCoreExpr ->
  PsKernelCoreResult String PsKernelCoreExpr

psKernelCoreIsDefEqWithResources
  (budget : Nat) (resources : PsKernelCoreResourceConfig) :
  PsKernelCoreEnvironment -> PsKernelCoreLocalContext ->
  PsKernelCoreExpr -> PsKernelCoreExpr -> PsKernelCoreResult String Bool

psKernelCoreCheckWithResources
  (budget : Nat) (resources : PsKernelCoreResourceConfig) :
  PsKernelCoreEnvironment -> PsKernelCoreLocalContext ->
  PsKernelCoreDefinitionSafety -> PsKernelCoreExpr ->
  PsKernelCoreResult String PsKernelCoreExpr

psKernelCoreAddAxiomWithResources
psKernelCoreAddDefinitionWithResources
psKernelCoreAddTheoremWithResources
psKernelCoreAddOpaqueWithResources
```

The four admission functions use `(budget, resources)` then their existing `Environment -> Info -> Result Environment` tail.

- [ ] **Step 2: Pin configured WHNF primitive behavior**

Build the same small reference environments used by prior reduction/DefEq tests and pin:

- direct `Nat.succ`, add/sub/mul/pow/gcd/mod/div/beq/ble;
- primitive operands exposed by beta and let/zeta;
- primitive head exposed by an ordinary delta definition alias;
- operand exposed by an ordinary delta definition;
- malformed primitive arity stays residual;
- primitive constant with nonempty universe levels stays residual;
- nonliteral/unreducible operands stay residual;
- tiny-resource overflow returns resource error;
- budget `0` still returns exactly `"reduction budget exhausted"` rather than a resource error.

Compare the selected overlap directly with mature `PSC1Kernel.whnf` configured with matching `maxNatSize`.

- [ ] **Step 3: Pin configured Infer/DefEq/Check behavior**

Require:

- `InferWithResources` accepts an in-limit Nat literal and rejects an over-limit one;
- configured DefEq proves at least `Nat.add 2 3 ≡ 5`, `Nat.mul 3 4 ≡ 12`, and `Nat.beq 2 2 ≡ Bool.true`;
- configured Check propagates the same literal resource rejection;
- Check/DefEq preserve their existing explicit budget errors at budget `0`;
- primitive normalization changes compatibility in at least one checked application/let case rather than being tested only in isolation.

- [ ] **Step 4: Pin configured Admission behavior and functional rejection**

Use a definition/theorem/opaque fixture containing an oversized Nat literal under a tiny config. Require admission to reject with the resource error and verify the original environment remains unchanged (`size`, old membership, rejected name absence, `quotInitialized`).

Also include at least one successful ordinary definition whose body/type compatibility depends on mandatory primitive normalization.

- [ ] **Step 5: Pin old-API/default-resource wrapper equivalence**

For representative success and error cases in each layer, assert:

```text
old API result = WithResources default-config result
```

Cover WHNF, Infer, DefEq, Check, and all four ordinary admission entry points. Include at least one error case, not only success.

- [ ] **Step 6: Wire the integration RED executable**

Add:

```text
psc2_kernel_core_resource_integration_tests -> KernelCoreResourceIntegrationTests
```

Insert workflow step `Configured primitive/resource integration test` after mandatory primitive parity and before the preserved Basic reduction parity step.

- [ ] **Step 7: Run RED**

Run:

```bash
lake exe psc2_kernel_core_resource_integration_tests
```

Expected: FAIL on absent `WithResources` APIs. Direct Resource and Primitive fixtures must remain GREEN.

- [ ] **Step 8: Commit integration RED**

```bash
git add psc15selfhost/test/KernelCoreResourceIntegrationTests.lean psc15selfhost/lakefile.lean .github/workflows/psc2-minimal-kernel.yml
git commit -m "test(pskernel-core): add configured resource integration red gate"
```

---

### Task 6: GREEN resource threading through Reduce → Admission

**Files:**
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Reduce.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Infer.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/DefEq.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Check.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Admission.lean`
- Test: `psc15selfhost/test/KernelCoreResourceIntegrationTests.lean`

**Interfaces:**
- Consumes Task-2 Resource and Task-4 Primitive APIs.
- Produces all `WithResources` APIs from Task 5 while preserving every existing accepted API as a default-config wrapper.

- [ ] **Step 1: Convert `Reduce` to configured recursion without changing the old public signature**

Create the recursive implementation:

```text
psKernelCoreWhnfWithResources
  (budget : Nat)
  (resources : PsKernelCoreResourceConfig) : Env -> LCtx -> Expr -> Result Expr
```

Keep `budget` as the first structurally decreasing parameter and `resources` invariant across recursive calls. Replace the old `psKernelCoreWhnf` body with a simple call to `psKernelCoreWhnfWithResources budget psKernelCoreResourceConfigDefault ...`.

Within the configured `.app` path, preserve existing beta/function-head behavior and add mandatory primitive recognition before treating a direct primitive application as ordinary residual/delta work:

- recognize exact unary `Nat.succ` and binary mandatory heads with zero universe levels;
- normalize primitive operands using the smaller configured WHNF with the same resources;
- call pure Task-4 unary/binary reducers only after operands expose recognized Nat values;
- if no primitive reduction applies, preserve/reconstruct the ordinary app and continue existing beta/delta behavior;
- a non-primitive definition alias may delta-expose a primitive on a subsequent bounded recursive step;
- do not introduce mutual recursion or a `Primitive -> Reduce` dependency.

All previously accepted Phase-3 budget thresholds/outputs remain authoritative; if an internal rewrite shifts them, fix the implementation rather than weakening old reduction tests.

- [ ] **Step 2: Add configured ensure/infer APIs and shared literal typing**

In `Infer.lean`, add:

```text
psKernelCoreInferLiteralWithResources
  (resources : PsKernelCoreResourceConfig)
  (literal : PsKernelCoreLiteral) : PsKernelCoreResult String PsKernelCoreExpr

psKernelCoreEnsureSortWithResources
psKernelCoreEnsureForallWithResources
psKernelCoreInferWithResources
```

`InferLiteralWithResources` is the single owner of Nat literal size checking for Infer/Check: Nat -> `psKernelCoreCheckNatSize` then Nat type; String -> existing String type.

`InferWithResources` keeps the current inference algorithm and budget semantics but calls configured Ensure/WHNF recursively. Make existing `psKernelCoreEnsureSort`, `psKernelCoreEnsureForall`, and `psKernelCoreInfer` default-config wrappers.

- [ ] **Step 3: Thread resources through DefEq without changing DefEq rules**

Add configured variants for internal DefEq helpers that call Infer/WHNF, including `psKernelCoreDefEqIsPropWithResources`, eta/fallback/reduced planning as necessary, then:

```text
psKernelCoreIsDefEqWithResources
```

The configured main function must call configured WHNF and Infer using the same resources. Existing `psKernelCoreIsDefEq` becomes a default-config wrapper. Do not add new Nat-offset/lazy-delta rules in this task; Phase-5 DefEq behavior plus primitive normalization is the scope.

Keep the first-order plan representation that was required for PSC1 source-check performance in Phase 5.

- [ ] **Step 4: Thread resources through Check and reuse shared literal typing**

Add:

```text
psKernelCoreCheckWithResources
```

Keep existing safety/order semantics unchanged. Use configured Ensure/DefEq/recursive Check. For `.lit`, call `psKernelCoreInferLiteralWithResources` instead of duplicating Nat resource logic. Existing `psKernelCoreCheck` becomes the default-config wrapper.

The Phase-6 universe-arity-before-safety regression must remain GREEN.

- [ ] **Step 5: Thread resources through Admission helpers and public entry points**

Create configured internal admission helpers wherever Check/DefEq/WHNF is used:

```text
psKernelCoreAdmissionCheckBaseWithResources
psKernelCoreAdmissionCheckDefinitionBodyWithResources
psKernelCoreAdmissionIsPropWithResources
```

and public:

```text
psKernelCoreAddAxiomWithResources
psKernelCoreAddDefinitionWithResources
psKernelCoreAddTheoremWithResources
psKernelCoreAddOpaqueWithResources
```

Preserve Phase-6 validation order, safety behavior, unsafe temporary-environment self-reference, and functional rejection semantics. Existing four `psKernelCoreAdd*` APIs become default-config wrappers.

- [ ] **Step 6: Run configured integration GREEN first**

Run:

```bash
lake exe psc2_kernel_core_resource_parity_tests
lake exe psc2_kernel_core_primitive_parity_tests
lake exe psc2_kernel_core_resource_integration_tests
```

Expected stable markers:

```text
PSC2_KERNEL_CORE_RESOURCE_PARITY: PASS
PSC2_KERNEL_CORE_PRIMITIVE_PARITY: PASS
PSC2_KERNEL_CORE_RESOURCE_INTEGRATION: PASS
```

- [ ] **Step 7: Run all preserved direct semantic gates**

Run in the established order:

```bash
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
lake exe psc2_kernel_core_defeq_parity_tests
lake exe psc2_kernel_core_check_parity_tests
lake env lean --run test/KernelCoreCheckOrderingTests.lean
lake exe psc2_kernel_core_admission_parity_tests
```

Expected: all PASS with no test relaxation.

- [ ] **Step 8: Run bootstrap isolation and actual PSC1 trusted-source gate**

Run:

```bash
node scripts/check-bootstrap-closure.mjs
node scripts/check-kernel-core-source.mjs
```

Expected: PASS. Resource/Primitive plus every modified configured semantic module must be accepted by the actual PSC1 compiler. Do not raise the source timeout or relax forbidden syntax/dependencies to make this pass.

- [ ] **Step 9: Run preserved aggregate/full regression before Phase-7 assurance wiring**

Run:

```bash
npm run assurance:kernel-core:phase1
npm run assurance:kernel-core:phase2
npm run assurance:kernel-core:phase3
npm run assurance:kernel-core:phase4
npm run assurance:kernel-core:phase5
npm run assurance:kernel-core:phase6
npm run check
```

Expected: all PASS.

- [ ] **Step 10: Commit configured GREEN**

```bash
git add psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Reduce.lean psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Infer.lean psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/DefEq.lean psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Check.lean psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Admission.lean
git commit -m "feat(pskernel-core): thread primitive resource semantics"
```

---

### Task 7: Phase-7 aggregate assurance, exact-head acceptance, and integration

**Files:**
- Modify: `psc15selfhost/package.json`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`
- Create after exact-head success: `psc15selfhost/docs/continuity/PHASE7_ACCEPTANCE.md`

**Interfaces:**
- Consumes all Phase-7 direct fixtures and trusted source from Tasks 1–6.
- Produces one exact implementation/assurance SHA, acceptance evidence, and merge-ready reviewed branch integration.

- [ ] **Step 1: Add `assurance:kernel-core:phase7` without changing older scripts**

Append a new package script whose order is:

```text
check:kernel-core-source
boundary
name
level
expr
subst
declaration
environment
local context
resource parity
mandatory primitive parity
basic reduction parity
infer parity
defeq parity
check parity
admission parity
configured resource integration
size report
```

Do not edit Phase-1 through Phase-6 assurance commands except for unrelated formatting if absolutely required; semantic command content must remain unchanged.

- [ ] **Step 2: Add the Phase-7 aggregate CI step**

In `.github/workflows/psc2-minimal-kernel.yml`, keep direct test order established in Tasks 1/3/5. Add `Phase 7 aggregate assurance` after Phase 6 aggregate and before `Existing PSC2 regression gate`.

- [ ] **Step 3: Run/fetch fresh exact-head CI**

The candidate implementation/assurance SHA is the commit containing Task-7 package/workflow wiring and all trusted/test changes, but not acceptance documentation.

Require one clean GitHub Actions run on that exact SHA with:

```text
Resource parity: success
Mandatory primitive parity: success
Configured integration: success
all Phase-1–6 direct semantic gates: success
bootstrap isolation: success
actual PSC1 source profile: success
Phase 1 aggregate: success
Phase 2 aggregate: success
Phase 3 aggregate: success
Phase 4 aggregate: success
Phase 5 aggregate: success
Phase 6 aggregate: success
Phase 7 aggregate: success
npm run check: success
```

Record exact SHA, workflow run ID, job ID, and conclusion.

- [ ] **Step 4: Capture exact size/source evidence from the accepted run**

Record:

```text
trusted KernelCore .lean file count
trusted source bytes
trusted nonblank/noncomment LOC
reference file count/bytes/LOC
byte ratio
LOC ratio
actual self-host-checkable module count
```

Use the same reference exclusions/baseline as prior acceptance documents. Do not predict final-kernel size.

- [ ] **Step 5: Write `PHASE7_ACCEPTANCE.md` only after exact-head success**

The document must state:

- accepted implementation/assurance SHA and exact CI IDs;
- mandatory primitive list actually accepted;
- configured resource APIs and default-wrapper compatibility evidence;
- exact resource/primitive/integration markers;
- actual PSC1 self-host evidence;
- size evidence;
- preserved Phase-1–6 and full regression evidence;
- allowed claims;
- explicit non-claims including all Phase-7B bitwise operations because this plan does not implement them;
- next recommended slice: Phase 7B bitwise feasibility/implementation before Quot, unless measured dependency pressure justifies skipping directly to Quot with Phase 7B still explicitly deferred.

Commit acceptance documentation separately and verify its parent is exactly the tested implementation/assurance SHA and the acceptance commit changes documentation only.

- [ ] **Step 6: Perform whole-branch scope review against the reviewed plan head**

Expected implementation scope:

```text
Resource.lean
Primitive.lean
Reduce.lean
Infer.lean
DefEq.lean
Check.lean
Admission.lean
Ps/KernelCore.lean
three KernelCore Phase-7 test files
lakefile.lean
package.json
psc2-minimal-kernel.yml
PHASE7_ACCEPTANCE.md
```

Any unrelated compiler/backend/Quot/inductive/native file is a blocker. If this harness has no independent subagent reviewer, state that the final review is self-review; do not imply independent review occurred.

- [ ] **Step 7: Integrate through a PR with exact expected head SHA**

Open PR:

```text
psc2/kernel-core-phase7-primitives-work
  -> psc2/kernel-core-phase7-primitives
```

Require mergeable state and merge using the exact reviewed acceptance-doc head SHA. Do not force-update either branch.

- [ ] **Step 8: Require post-merge CI success before declaring Phase 7 closed**

Record merge SHA and post-merge workflow run/job. Require all direct gates, Phase-1–7 aggregate assurance, actual PSC1 source checking, and full `npm run check` to complete `success` on the merged head.

Only then report Phase 7 complete and start the next architectural design gate.

---

## Phase 7B follow-on boundary

This plan intentionally does **not** implement `Nat.land`, `Nat.lor`, `Nat.xor`, `Nat.shiftLeft`, or `Nat.shiftRight`. After Phase-7 merged-head success, treat Phase 7B as its own next slice unless the user redirects the roadmap. Preserve the same rule: no `Std`/Lean implementation imports and no trusted-source weakening merely to obtain bitwise primitives.