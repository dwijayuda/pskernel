# PSC2 KernelCore Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the accepted Phase 1 `pskernel-core` with the smallest PSC1-self-hostable declaration, environment, and local-context substrate required before reduction and type checking.

**Architecture:** Add three trusted semantic modules in dependency order: `Declaration`, `Environment`, then `LocalContext`. Keep the trusted representation deliberately simple: kernel-local list/option/result carriers, structural lookup, no hashing/index/cache layer, and differential parity against the mature `PSC1Kernel` reference at every slice.

**Tech Stack:** Lean 4.34.0, PSC1-compatible `.lean`, Lake, Node 22/npm gates, GitHub Actions.

**Spec:** `psc15selfhost/docs/superpowers/specs/2026-09-27-psc2-kernel-core-phase2-design.md`

## Global Constraints

- Work only on branch `psc2/kernel-core-phase2`.
- Phase 1 accepted baseline is `27e12a3979ed0acf23d2ba70d5daf58658b892ac` and must remain semantically green.
- Trusted KernelCore source must remain PSC1-compatible `.lean` and pass the actual `psc1 check` path through `scripts/check-kernel-core-source.mjs`.
- Trusted source must not use `partial`, host `List`/`Option` as semantic storage, `IO`, `Lean.*`, `Std.*`, `unsafe`, `extern`, `implemented_by`, custom syntax/macros/elaborators, namespace convenience, or performance-only caches/indexes.
- Environment semantics use newest-first structural lookup over `PsKernelCoreList`; no `Array`, bucket hash, string hash, or derived lookup index is trusted.
- Initial Phase 2 declaration variants are only axiom, definition, theorem, and opaque. Inductive/constructor/recursor/Quot metadata remains deferred.
- Existing compiler admission remains `AdmissionReadyModule`; this phase does not claim `CheckedCore` integration.
- Do not weaken any existing regression or self-host gate.
- Do not claim full Lean 4 equivalence, complete kernel compatibility, inductive correctness, Quot correctness, reduction correctness, or defeq correctness.

## Review Focus

- Duplicate universe parameters: `Environment.add` must reject non-adjacent duplicates, not only adjacent duplicates.
- Newest-first replacement/lookup: replacing one declaration must not reorder or accidentally duplicate unrelated declarations.
- Reducibility ordering: `abbrevHint`, `regular(height)`, and `opaqueHint` must match reference ordering exactly, including equal regular heights.
- Local-context shadowing: lookup must return the newest matching local declaration when the same internal name appears more than once.
- PSC1 portability: every new recursive helper must use a recursion shape accepted by the current PSC1 admission checker, not merely by Lean.

---

## File Structure

### Trusted production modules

- Create `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Declaration.lean` — initial global declaration metadata and semantic accessors.
- Create `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Environment.lean` — linear semantic global environment.
- Create `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/LocalContext.lean` — local declaration/context substrate.
- Modify `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Data.lean` — add only a tiny kernel-local result carrier when Environment implementation begins.
- Modify `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean` — export Phase 2 modules.

### Differential tests

- Create `psc15selfhost/test/KernelCoreDeclarationParityTests.lean`.
- Create `psc15selfhost/test/KernelCoreEnvironmentParityTests.lean`.
- Create `psc15selfhost/test/KernelCoreLocalContextParityTests.lean`.

### Build / assurance wiring

- Modify `psc15selfhost/lakefile.lean` — expose reference `PSC1Kernel.Declaration`, `Environment`, `LocalContext` and add three Phase-2 test executables.
- Modify `psc15selfhost/package.json` — add Phase-2 aggregate assurance command; keep Phase-1 assurance unchanged.
- Modify `.github/workflows/psc2-minimal-kernel.yml` — add `psc2/kernel-core-phase2` trigger and Phase-2 parity/aggregate steps.
- `psc15selfhost/scripts/check-kernel-core-source.mjs` should require no logic change because it auto-discovers all KernelCore `.lean` files; modify it only if a real Phase-2 portability bug demonstrates a missing gate.
- `psc15selfhost/scripts/report-kernel-core-size.mjs` should automatically include the new trusted files; change only if the report does not discover them.
- Create `psc15selfhost/docs/continuity/PHASE2_ACCEPTANCE.md` only after all gates are green.

---

### Task 1: Phase 2A RED gate — Declaration parity fixture

**Files:**
- Modify: `psc15selfhost/lakefile.lean`
- Create: `psc15selfhost/test/KernelCoreDeclarationParityTests.lean`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`

**Interfaces:**
- Consumes: Phase-1 `PsKernelCoreName`, `PsKernelCoreLevel`, `PsKernelCoreExpr`, `PsKernelCoreList`, `PsKernelCoreOption`.
- Produces: a failing differential fixture that names the exact Phase-2A public API before production code exists.

- [ ] **Step 1: Add reference/build wiring without adding production Declaration code**

Extend `PSC1KernelReferenceFoundations` roots with:

```text
PSC1Kernel.Declaration
PSC1Kernel.Environment
PSC1Kernel.LocalContext
```

Add executable:

```text
psc2_kernel_core_declaration_parity_tests -> KernelCoreDeclarationParityTests
```

Add `psc2/kernel-core-phase2` to the workflow branch trigger and watch `KernelCoreDeclarationParityTests.lean`.

- [ ] **Step 2: Write the failing Declaration parity test**

The fixture must import `Ps.KernelCore.Declaration` and compare the planned trusted API to `PSC1Kernel.Declaration` for:

```text
DefinitionSafety: unsafeDef / safe / partialDef
ReducibilityHints: opaqueHint / abbrevHint / regular(height)
ConstantBase
AxiomInfo
DefinitionInfo
TheoremInfo
OpaqueInfo
ConstantInfo: axiomInfo / defnInfo / thmInfo / opaqueInfo
```

Pin these accessors/classifiers:

```text
psKernelCoreDefinitionSafetyIsUnsafe
psKernelCoreDefinitionSafetyIsSafe
psKernelCoreReducibilityHintsLt
psKernelCoreReducibilityHintsIsRegular
psKernelCoreConstantInfoBase
psKernelCoreConstantInfoName
psKernelCoreConstantInfoLevelParams
psKernelCoreConstantInfoType
psKernelCoreConstantInfoDeltaValue?
psKernelCoreConstantInfoHints?
psKernelCoreConstantInfoIsUnsafe
psKernelCoreConstantInfoIsPartial
psKernelCoreConstantInfoIsDefinition
psKernelCoreConstantInfoDefinition?
```

Review-focus assertions must include:

- `abbrevHint < regular` = true;
- `regular 3 < regular 2` = true because the reference orders regular hints by greater height;
- `regular 2 < regular 2` = false;
- `regular _ < opaqueHint` = true;
- theorem/opaque/axiom have no delta value;
- only definitions return `definition?`.

- [ ] **Step 3: Run the new test and verify RED**

Run:

```bash
cd psc15selfhost
lake exe psc2_kernel_core_declaration_parity_tests
```

Expected: FAIL because `Ps.KernelCore.Declaration` does not exist.

- [ ] **Step 4: Commit the RED fixture**

```text
test(pskernel-core): add declaration parity red gate
```

---

### Task 2: Phase 2A GREEN — Minimal Declaration model

**Files:**
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Declaration.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`

**Interfaces:**
- Consumes: `PsKernelCoreName`, `PsKernelCoreExpr`, `PsKernelCoreList`, `PsKernelCoreOption`.
- Produces:

```text
inductive PsKernelCoreDefinitionSafety
  unsafeDef | safe | partialDef

psKernelCoreDefinitionSafetyIsUnsafe : PsKernelCoreDefinitionSafety -> Bool
psKernelCoreDefinitionSafetyIsSafe : PsKernelCoreDefinitionSafety -> Bool

inductive PsKernelCoreReducibilityHints
  opaqueHint | abbrevHint | regular (height : Nat)

psKernelCoreReducibilityHintsLt : PsKernelCoreReducibilityHints -> PsKernelCoreReducibilityHints -> Bool
psKernelCoreReducibilityHintsIsRegular : PsKernelCoreReducibilityHints -> Bool

structure PsKernelCoreConstantBase
  name : PsKernelCoreName
  levelParams : PsKernelCoreList PsKernelCoreName
  type : PsKernelCoreExpr

structure PsKernelCoreAxiomInfo
  base : PsKernelCoreConstantBase
  isUnsafe : Bool

structure PsKernelCoreDefinitionInfo
  base : PsKernelCoreConstantBase
  value : PsKernelCoreExpr
  hints : PsKernelCoreReducibilityHints
  safety : PsKernelCoreDefinitionSafety

structure PsKernelCoreTheoremInfo
  base : PsKernelCoreConstantBase
  value : PsKernelCoreExpr

structure PsKernelCoreOpaqueInfo
  base : PsKernelCoreConstantBase
  value : PsKernelCoreExpr
  isUnsafe : Bool

inductive PsKernelCoreConstantInfo
  axiomInfo (value : PsKernelCoreAxiomInfo)
  defnInfo (value : PsKernelCoreDefinitionInfo)
  thmInfo (value : PsKernelCoreTheoremInfo)
  opaqueInfo (value : PsKernelCoreOpaqueInfo)

psKernelCoreConstantInfoBase : PsKernelCoreConstantInfo -> PsKernelCoreConstantBase
psKernelCoreConstantInfoName : PsKernelCoreConstantInfo -> PsKernelCoreName
psKernelCoreConstantInfoLevelParams : PsKernelCoreConstantInfo -> PsKernelCoreList PsKernelCoreName
psKernelCoreConstantInfoType : PsKernelCoreConstantInfo -> PsKernelCoreExpr
psKernelCoreConstantInfoDeltaValue? : PsKernelCoreConstantInfo -> PsKernelCoreOption PsKernelCoreExpr
psKernelCoreConstantInfoHints? : PsKernelCoreConstantInfo -> PsKernelCoreOption PsKernelCoreReducibilityHints
psKernelCoreConstantInfoIsUnsafe : PsKernelCoreConstantInfo -> Bool
psKernelCoreConstantInfoIsPartial : PsKernelCoreConstantInfo -> Bool
psKernelCoreConstantInfoIsDefinition : PsKernelCoreConstantInfo -> Bool
psKernelCoreConstantInfoDefinition? : PsKernelCoreConstantInfo -> PsKernelCoreOption PsKernelCoreDefinitionInfo
```

Do not add inductive/constructor/recursor/Quot variants.

- [ ] **Step 1: Implement only the Phase-2A declaration surface**

Use top-level prefixed declarations; no namespace block. Preserve reference semantics exactly for safety classification and reducibility ordering.

- [ ] **Step 2: Export the module from `Ps.KernelCore`**

Append:

```lean
import Ps.KernelCore.Declaration
```

- [ ] **Step 3: Verify direct parity GREEN**

```bash
cd psc15selfhost
lake exe psc2_kernel_core_declaration_parity_tests
```

Expected: `PSC2_KERNEL_CORE_DECLARATION_PARITY: PASS`.

- [ ] **Step 4: Verify actual PSC1 self-hostability**

```bash
node scripts/check-kernel-core-source.mjs
```

Expected: every KernelCore source module, including `Declaration.lean`, reports `KERNEL_CORE_SELFHOST_CHECK: PASS` and the aggregate source profile passes.

- [ ] **Step 5: Run Phase-1 assurance unchanged**

```bash
npm run assurance:kernel-core:phase1
```

Expected: PASS.

- [ ] **Step 6: Commit Phase 2A GREEN**

```text
feat(pskernel-core): add minimal declaration semantics
```

---

### Task 3: Phase 2B RED gate — Environment behavior

**Files:**
- Create: `psc15selfhost/test/KernelCoreEnvironmentParityTests.lean`
- Modify: `psc15selfhost/lakefile.lean`

**Interfaces:**
- Consumes: Task 2 declaration API and Phase-1 Name/List/Option.
- Produces: a failing fixture for the planned Environment API. Production `Data.lean` remains unchanged until RED is confirmed.

- [ ] **Step 1: Add the Environment parity executable**

```text
psc2_kernel_core_environment_parity_tests -> KernelCoreEnvironmentParityTests
```

- [ ] **Step 2: Write the failing Environment parity test**

Import `Ps.KernelCore.Environment` and pin:

```text
PsKernelCoreEnvironment
  constants : PsKernelCoreList PsKernelCoreConstantInfo
  quotInitialized : Bool

psKernelCoreEnvironmentEmpty
psKernelCoreEnvironmentFind?
psKernelCoreEnvironmentContains
psKernelCoreEnvironmentSize
psKernelCoreEnvironmentAddUnchecked
psKernelCoreEnvironmentReplaceUnchecked
psKernelCoreEnvironmentAdd
psKernelCoreEnvironmentMarkQuotInitialized
```

Test cases:

- empty lookup = none;
- adding a unique declaration makes it findable;
- newest-first lookup returns the latest same-name item under `addUnchecked`;
- `add` rejects duplicate constant name with error string `already declared`;
- `add` rejects duplicate universe parameter names with error string `duplicate universe parameter`;
- duplicate universe test uses a non-adjacent sequence `[u, v, u]`;
- replace changes only the first/newest matching declaration and preserves unrelated declarations/order;
- size matches reference observable size;
- `markQuotInitialized` is false -> true and idempotent on true.

Compare outcomes through test-only adapters because the trusted representation intentionally differs from the indexed reference representation.

- [ ] **Step 3: Run and verify RED**

```bash
lake exe psc2_kernel_core_environment_parity_tests
```

Expected: FAIL because `Ps.KernelCore.Environment` does not exist.

- [ ] **Step 4: Commit the RED fixture**

```text
test(pskernel-core): add environment parity red gate
```

---

### Task 4: Phase 2B GREEN — Linear semantic Environment

**Files:**
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Data.lean`
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Environment.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`

**Interfaces:**
- Consumes: `PsKernelCoreList`, `PsKernelCoreOption`, `PsKernelCoreName`, `PsKernelCoreConstantInfo` and declaration accessors.
- Produces:

```text
inductive PsKernelCoreResult (errorType : Type) (okType : Type)
  error (value : errorType)
  ok (value : okType)

structure PsKernelCoreEnvironment
  constants : PsKernelCoreList PsKernelCoreConstantInfo
  quotInitialized : Bool

psKernelCoreEnvironmentEmpty : PsKernelCoreEnvironment
psKernelCoreEnvironmentFind? : PsKernelCoreEnvironment -> PsKernelCoreName -> PsKernelCoreOption PsKernelCoreConstantInfo
psKernelCoreEnvironmentContains : PsKernelCoreEnvironment -> PsKernelCoreName -> Bool
psKernelCoreEnvironmentSize : PsKernelCoreEnvironment -> Nat
psKernelCoreEnvironmentAddUnchecked : PsKernelCoreEnvironment -> PsKernelCoreConstantInfo -> PsKernelCoreEnvironment
psKernelCoreEnvironmentReplaceUnchecked : PsKernelCoreEnvironment -> PsKernelCoreConstantInfo -> PsKernelCoreEnvironment
psKernelCoreEnvironmentAdd : PsKernelCoreEnvironment -> PsKernelCoreConstantInfo -> PsKernelCoreResult String PsKernelCoreEnvironment
psKernelCoreEnvironmentMarkQuotInitialized : PsKernelCoreEnvironment -> PsKernelCoreEnvironment
```

- [ ] **Step 1: Add the minimal trusted `PsKernelCoreResult` carrier to `Data.lean`**

No helpers beyond the two constructors.

- [ ] **Step 2: Implement structural list helpers locally in `Environment.lean`**

Required behavior only:

```text
constant lookup by structural name equality
list length
name-list membership / duplicate detection
replace first matching constant
```

Do not add generic collection APIs unless another trusted module already needs them.

- [ ] **Step 3: Implement the Environment API with newest-first linear semantics**

No arrays, hashes, buckets, caches, indexes, or fallback index synchronization logic.

`add` rejection priority must match reference behavior:

```text
1. duplicate constant name -> "already declared"
2. duplicate universe parameter -> "duplicate universe parameter"
3. otherwise ok(addUnchecked ...)
```

- [ ] **Step 4: Export `Environment` from `Ps.KernelCore`**

- [ ] **Step 5: Verify environment parity**

```bash
lake exe psc2_kernel_core_environment_parity_tests
```

Expected: `PSC2_KERNEL_CORE_ENVIRONMENT_PARITY: PASS`.

- [ ] **Step 6: Verify PSC1 source/self-host gate**

```bash
node scripts/check-kernel-core-source.mjs
```

Expected: PASS for every trusted module including Environment.

If PSC1 rejects a Lean-valid recursion shape, rewrite the trusted helper into a structurally recursive single-changing-argument form; do not weaken the compiler gate.

- [ ] **Step 7: Run prior parity gates**

Run all Phase-1 tests plus declaration parity. Expected: PASS.

- [ ] **Step 8: Commit Phase 2B GREEN**

```text
feat(pskernel-core): add linear semantic environment
```

---

### Task 5: Phase 2C RED/GREEN — LocalContext

**Files:**
- Create: `psc15selfhost/test/KernelCoreLocalContextParityTests.lean`
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/LocalContext.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`
- Modify: `psc15selfhost/lakefile.lean`

**Interfaces:**
- Consumes: `PsKernelCoreName`, `PsKernelCoreExpr`, `PsKernelCoreBinderInfo`, `PsKernelCoreList`, `PsKernelCoreOption`.
- Produces:

```text
inductive PsKernelCoreLocalDecl
  localDecl(index, name, userName, type, binderInfo)
  letDecl(index, name, userName, type, value)

psKernelCoreLocalDeclName : PsKernelCoreLocalDecl -> PsKernelCoreName
psKernelCoreLocalDeclUserName : PsKernelCoreLocalDecl -> PsKernelCoreName
psKernelCoreLocalDeclType : PsKernelCoreLocalDecl -> PsKernelCoreExpr
psKernelCoreLocalDeclValue? : PsKernelCoreLocalDecl -> PsKernelCoreOption PsKernelCoreExpr
psKernelCoreLocalDeclBinderInfo : PsKernelCoreLocalDecl -> PsKernelCoreBinderInfo

structure PsKernelCoreLocalContext
  decls : PsKernelCoreList PsKernelCoreLocalDecl
  nextIndex : Nat

psKernelCoreLocalContextEmpty : PsKernelCoreLocalContext
psKernelCoreLocalContextFind? : PsKernelCoreLocalContext -> PsKernelCoreName -> PsKernelCoreOption PsKernelCoreLocalDecl
psKernelCoreLocalContextAddLocal : PsKernelCoreLocalContext -> PsKernelCoreName -> PsKernelCoreName -> PsKernelCoreExpr -> PsKernelCoreBinderInfo -> PsKernelCoreLocalContext
psKernelCoreLocalContextAddLet : PsKernelCoreLocalContext -> PsKernelCoreName -> PsKernelCoreName -> PsKernelCoreExpr -> PsKernelCoreExpr -> PsKernelCoreLocalContext
```

- [ ] **Step 1: Add LocalContext parity executable and failing fixture**

Test:

- empty context and `nextIndex = 0`;
- `addLocal` assigns index 0 then increments;
- `addLet` assigns the next index then increments;
- local declaration accessors match reference;
- let declaration `value?` returns the stored expression;
- let declaration binder info is `.default`;
- local lookup finds the correct declaration;
- shadowing with the same internal name returns the newest declaration.

Run:

```bash
lake exe psc2_kernel_core_local_context_parity_tests
```

Expected: RED because `Ps.KernelCore.LocalContext` is missing.

- [ ] **Step 2: Implement minimal LocalContext semantics**

Use newest-first `PsKernelCoreList` storage and structural Name equality. No map/index/cache.

- [ ] **Step 3: Export `LocalContext` from `Ps.KernelCore`**

- [ ] **Step 4: Verify parity and self-hostability**

```bash
lake exe psc2_kernel_core_local_context_parity_tests
node scripts/check-kernel-core-source.mjs
```

Expected: PASS.

- [ ] **Step 5: Commit Phase 2C GREEN**

```text
feat(pskernel-core): add local context semantics
```

---

### Task 6: Phase 2 aggregate assurance, CI, and size evidence

**Files:**
- Modify: `psc15selfhost/package.json`
- Modify: `.github/workflows/psc2-minimal-kernel.yml`
- Verify/modify only if needed: `psc15selfhost/scripts/report-kernel-core-size.mjs`

**Interfaces:**
- Consumes: all Phase-1 and Phase-2 parity executables.
- Produces: one deterministic Phase-2 assurance command and branch-local CI evidence.

- [ ] **Step 1: Add `assurance:kernel-core:phase2`**

The command must run, in order:

```text
check:kernel-core-source
Phase-1 boundary parity
Name parity
Level parity
Expr parity
Subst parity
Declaration parity
Environment parity
LocalContext parity
size report
```

Do not modify `assurance:kernel-core:phase1`.

- [ ] **Step 2: Extend CI with Phase-2 parity and aggregate steps**

Keep the existing full `npm run check` as the final regression step.

- [ ] **Step 3: Run Phase-2 aggregate assurance**

```bash
npm run assurance:kernel-core:phase2
```

Expected: all semantic/self-host gates PASS and the size reporter includes all new trusted `.lean` files automatically.

- [ ] **Step 4: Run complete existing regression suite**

```bash
npm run check
```

Expected: PASS. Fix only real integration regressions; do not weaken or skip gates.

- [ ] **Step 5: Commit assurance wiring**

```text
ci(pskernel-core): add Phase 2 assurance gate
```

---

### Task 7: Phase 2 acceptance and continuity record

**Files:**
- Create: `psc15selfhost/docs/continuity/PHASE2_ACCEPTANCE.md`
- Update if stale: `psc15selfhost/docs/continuity/CHAT_KERNEL_CORE_PHASE1_2026-09-27.md` only by adding a pointer to the newer Phase-2 acceptance record; do not rewrite historical Phase-1 facts.

**Interfaces:**
- Consumes: exact green commit SHA, exact CI run, size report, and all gate outputs.
- Produces: durable handoff evidence for future chats/agents.

- [ ] **Step 1: Verify fresh branch head before claiming completion**

Required evidence:

```text
npm run assurance:kernel-core:phase2 -> PASS
npm run check -> PASS
GitHub Actions PSC2 minimal kernel run on exact head -> success
```

- [ ] **Step 2: Record exact acceptance evidence**

`PHASE2_ACCEPTANCE.md` must include:

- branch and accepted commit SHA;
- Lean version 4.34.0;
- trusted module list;
- parity gate list;
- PSC1 self-host source-profile result;
- size bytes/LOC and comparison ratio from the reporter;
- explicit statement that the trusted environment is linear/no-hash/no-cache;
- explicit deferred work: reduction, infer/check, defeq, Quot, inductive admission, compiler checked-core integration;
- explicit non-claim of full Lean 4 equivalence.

- [ ] **Step 3: Commit acceptance record**

```text
docs(pskernel-core): accept Phase 2 semantic substrate
```

- [ ] **Step 4: Stop before Phase 3 implementation**

Do not begin reduction/type checking/defeq in this plan. Phase 3 requires its own architectural design/spec/plan.
