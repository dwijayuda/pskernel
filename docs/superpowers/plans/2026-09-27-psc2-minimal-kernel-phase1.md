# PSC2 Minimal Kernel Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce `psc15selfhost/packages/pskernel-core` as a materially smaller, portable semantic-kernel package and prove foundational parity for `Name`, `Level`, `Expr`, and substitution/instantiation against the mature `PSC1Kernel` reference without changing the active PSC2 bootstrap path.

**Architecture:** Keep `psc15selfhost/packages/pskernel` unchanged as the Lean-4.34 compatibility oracle. Build a sibling `pskernel-core` package containing only the first foundational semantic slice, then add test-only differential adapters so both implementations are exercised on the same normalized cases. The new package stays `bootstrap: false` until later parity milestones.

**Tech Stack:** Lean 4.34.0, Lake, PSC1-compatible `.lean`, npm workspace metadata, existing `psc15selfhost` test/gate scripts.

**Spec:** `docs/superpowers/specs/2026-09-27-psc2-minimal-kernel-design.md`

## Global Constraints

- Preserve `psc15selfhost/packages/pskernel/PSC1Kernel` as the mature reference/oracle; do not delete or weaken it.
- Keep the pinned final Lean 4.34 behavior as semantic authority for compatibility work.
- `pskernel-core` starts with `bootstrap: false` and `portable: true`.
- No replay, NDJSON, filesystem/process, compiler backend, or host-runtime dependency may enter `pskernel-core`.
- Prefer simple/pure semantic implementations over cache/session optimization in this phase.
- Do not weaken existing adversarial or K2-K8 regressions to make the new core pass.
- No claim of full Lean 4.34 equivalence follows from this phase.
- Existing PSC2 bootstrap closure remains unchanged in this phase.

## Review Focus

- Universe-level normalization/equality cases involving `max`/`imax` must agree with the reference rather than merely compare constructors structurally.
- Bound-variable lifting/instantiation across nested binders must avoid capture and preserve exact de Bruijn behavior.
- Expression equality/hash helpers, if introduced, must not accidentally treat binder annotations or metadata as semantically significant where the reference does not.
- Invalid index/underflow-style substitution inputs must fail or remain unchanged exactly as the selected reference operation defines; no silent widening of semantics.
- Package metadata and imports must keep `pskernel-core` outside the PSC2 bootstrap import closure while still allowing dedicated Lake tests to compile it.

---

### Task 1: Scaffold the isolated `pskernel-core` package and gate its dependency boundary

**Files:**
- Create: `psc15selfhost/packages/pskernel-core/package.json`
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Name.lean`
- Create: `psc15selfhost/test/KernelCoreBoundaryTests.lean`
- Modify: `psc15selfhost/lakefile.lean`
- Modify: `psc15selfhost/package.json`
- Modify: `psc15selfhost/scripts/check-bootstrap-closure.mjs`

**Interfaces:**
- Consumes: existing npm workspace discovery and Lake project structure.
- Produces: Lean library `PsKernelCore`, test executable `psc2_kernel_core_boundary_tests`, and package metadata with role `minimal-trusted-kernel`.

- [ ] **Step 1: Write the failing boundary test**

Create `KernelCoreBoundaryTests.lean` importing `Ps.KernelCore` and asserting a tiny exported value or constructor from `Ps.KernelCore.Name` is available. The test must fail initially because the library/package does not exist.

- [ ] **Step 2: Run the targeted test to verify failure**

Run from `psc15selfhost`:

```bash
lake exe psc2_kernel_core_boundary_tests
```

Expected: failure because `PsKernelCore` / `Ps.KernelCore` is not yet defined.

- [ ] **Step 3: Add package metadata and Lake library**

Create `psc15selfhost/packages/pskernel-core/package.json` with:

```json
{
  "name": "@proofscript/pskernel-core",
  "version": "0.0.0-dev",
  "private": true,
  "type": "module",
  "proofscript": {
    "bootstrap": false,
    "portable": true,
    "sourceRoots": ["src"],
    "testRoots": ["test"],
    "outDir": "dist",
    "role": "minimal-trusted-kernel"
  }
}
```

Add `lean_lib PsKernelCore` rooted at `Ps.KernelCore` and `lean_exe psc2_kernel_core_boundary_tests` to `psc15selfhost/lakefile.lean`.

- [ ] **Step 4: Add the minimal aggregate and `Name` placeholder API**

Create:

```lean
-- Ps/KernelCore/Name.lean
namespace Ps.KernelCore
inductive Name where
  | anonymous
  | str (prefix : Name) (value : String)
  | num (prefix : Name) (value : Nat)
end Ps.KernelCore
```

Create `Ps/KernelCore.lean` importing `Ps.KernelCore.Name`.

- [ ] **Step 5: Explicitly keep `pskernel-core` outside bootstrap closure**

Update `check-bootstrap-closure.mjs` so `pskernel-core` is forbidden as a bootstrap dependency during this phase, analogous to the existing `pskernel` reference package.

- [ ] **Step 6: Run boundary and bootstrap-closure gates**

Run:

```bash
lake exe psc2_kernel_core_boundary_tests
node scripts/check-bootstrap-closure.mjs
```

Expected: both PASS; closure output must not list `pskernel-core`.

- [ ] **Step 7: Commit**

```bash
git add psc15selfhost/packages/pskernel-core psc15selfhost/test/KernelCoreBoundaryTests.lean psc15selfhost/lakefile.lean psc15selfhost/package.json psc15selfhost/scripts/check-bootstrap-closure.mjs
git commit -m "feat(psc2): scaffold minimal kernel core"
```

---

### Task 2: Implement `KernelCore.Name` with direct reference parity

**Files:**
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Name.lean`
- Create: `psc15selfhost/test/KernelCoreNameParityTests.lean`
- Modify: `psc15selfhost/lakefile.lean`

**Interfaces:**
- Consumes: `Ps.KernelCore.Name` scaffold and `PSC1Kernel.Name` reference.
- Produces: `Ps.KernelCore.Name.eq : Name -> Name -> Bool`, `Name.hasDuplicates : List Name -> Bool`, and any minimal constructors/helpers required by later foundational modules.

- [ ] **Step 1: Write failing parity tests**

Cover at minimum:

```text
anonymous == anonymous
str nesting equality and inequality
num nesting equality and inequality
str vs num mismatch
hasDuplicates false for unique names
hasDuplicates true for duplicate structural names
```

For each normalized test vector, compute both PSC1Kernel and KernelCore results and assert equality.

- [ ] **Step 2: Run parity test to verify failure**

Run:

```bash
lake exe psc2_kernel_core_name_parity_tests
```

Expected: failure for missing `KernelCore.Name.eq` / `hasDuplicates`.

- [ ] **Step 3: Implement the minimal Name operations**

Implement only operations used by the current foundational slice. Do not add string rendering, hashing, replay codecs, or host conveniences unless a parity test requires them.

- [ ] **Step 4: Run parity and source-profile checks**

Run:

```bash
lake exe psc2_kernel_core_name_parity_tests
node check-psc1-source.mjs
```

Expected: PASS. If `check-psc1-source.mjs` does not yet scan `pskernel-core` because `bootstrap:false`, add a dedicated portable-kernel source-profile script/test in Task 5 rather than changing bootstrap semantics here.

- [ ] **Step 5: Commit**

```bash
git add psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Name.lean psc15selfhost/test/KernelCoreNameParityTests.lean psc15selfhost/lakefile.lean
git commit -m "feat(pskernel-core): add name parity"
```

---

### Task 3: Implement universe `Level` semantics with differential parity

**Files:**
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Level.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`
- Create: `psc15selfhost/test/KernelCoreLevelParityTests.lean`
- Modify: `psc15selfhost/lakefile.lean`

**Interfaces:**
- Consumes: `Ps.KernelCore.Name`.
- Produces: core universe representation and the exact foundational operations later required by expressions/checking, using names/signatures aligned with the reference where practical.

Required public surface for this task:

```lean
inductive Ps.KernelCore.Level
  | zero
  | succ (level : Level)
  | max (left right : Level)
  | imax (left right : Level)
  | param (name : Name)
  | mvar (id : Nat)

Level.instantiateParams : Level -> List (Name × Level) -> Level
Level.hasMVar : Level -> Bool
Level.eqv : Level -> Level -> Bool
```

If the reference uses a different exact substitution carrier, preserve behavior while choosing the smallest PSC1-portable representation; document the adapter in the test.

- [ ] **Step 1: Write failing direct parity tests**

Include:

```text
zero/succ equivalence
max normalization cases
imax Prop-sensitive cases already represented by PSC1Kernel tests
parameter substitution present/missing
nested substitution through max/imax/succ
mvar detection
```

The test must compare normalized observable results to `PSC1Kernel.Level` rather than only self-asserting KernelCore output.

- [ ] **Step 2: Run targeted tests to verify failure**

```bash
lake exe psc2_kernel_core_level_parity_tests
```

Expected: FAIL for missing `Ps.KernelCore.Level` API.

- [ ] **Step 3: Implement minimal Level semantics**

Port only the pure semantic algorithms needed by the tests and later `Expr`/checker work. Do not port oracle/replay support or runtime caches.

- [ ] **Step 4: Run parity tests plus existing PSC1Kernel foundational oracle**

Run:

```bash
lake exe psc2_kernel_core_level_parity_tests
# Also run the smallest existing PSC1Kernel oracle target that covers Level semantics, as exposed by its package/lakefile.
```

Expected: PASS for both. Record the exact reference-oracle command in the test README/comment if the nested package requires a separate `lake` invocation.

- [ ] **Step 5: Commit**

```bash
git add psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Level.lean psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean psc15selfhost/test/KernelCoreLevelParityTests.lean psc15selfhost/lakefile.lean
git commit -m "feat(pskernel-core): add universe level parity"
```

---

### Task 4: Implement core `Expr` representation without importing checker/runtime machinery

**Files:**
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Expr.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`
- Create: `psc15selfhost/test/KernelCoreExprParityTests.lean`
- Modify: `psc15selfhost/lakefile.lean`

**Interfaces:**
- Consumes: `KernelCore.Name`, `KernelCore.Level`.
- Produces: core `Expr` constructors sufficient to represent the current reference kernel term language and small structural helpers needed by substitution.

Required constructor coverage:

```text
bvar
fvar
mvar
sort
const
app
lam
forallE
letE
lit
mdata
proj
```

Binder-info/literal/metadata representations must be the smallest forms that preserve the semantics needed by the existing reference operations; avoid source-language syntax structures.

- [ ] **Step 1: Write failing representation/parity tests**

Build equivalent representative terms in PSC1Kernel and KernelCore covering every constructor. Test structural observation helpers required by substitution, including free-variable/metavariable detection only if they are needed by Task 5.

- [ ] **Step 2: Run test to verify failure**

```bash
lake exe psc2_kernel_core_expr_parity_tests
```

Expected: FAIL because `KernelCore.Expr` is missing.

- [ ] **Step 3: Implement the minimal Expr data model and adapters used only by tests**

Keep conversion helpers in the test/assurance side where possible. `pskernel-core` itself must not import `PSC1Kernel`.

- [ ] **Step 4: Run Expr parity + package boundary tests**

```bash
lake exe psc2_kernel_core_expr_parity_tests
lake exe psc2_kernel_core_boundary_tests
node scripts/check-bootstrap-closure.mjs
```

Expected: PASS, with no new bootstrap dependency.

- [ ] **Step 5: Commit**

```bash
git add psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Expr.lean psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean psc15selfhost/test/KernelCoreExprParityTests.lean psc15selfhost/lakefile.lean
git commit -m "feat(pskernel-core): add core expression model"
```

---

### Task 5: Implement capture-safe lifting and instantiation parity

**Files:**
- Create: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Subst.lean`
- Modify: `psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean`
- Create: `psc15selfhost/test/KernelCoreSubstParityTests.lean`
- Create: `psc15selfhost/scripts/check-kernel-core-source.mjs`
- Modify: `psc15selfhost/package.json`
- Modify: `psc15selfhost/lakefile.lean`

**Interfaces:**
- Consumes: `KernelCore.Expr`, `KernelCore.Level`.
- Produces foundational de Bruijn operations aligned with `PSC1Kernel.Instantiate`/Expr lifting semantics.

Required public operations, adjusted only if the reference signatures demand a more exact name:

```lean
Expr.liftBVars : Expr -> Nat -> Nat -> Expr
Expr.instantiate1 : Expr -> Expr -> Expr
Expr.instantiateRev : Expr -> List Expr -> Expr
```

- [ ] **Step 1: Write failing differential tests**

Must include:

```text
lift bvar below cutoff unchanged
lift bvar at/above cutoff
nested lambda/forall cutoff increment
let type/value/body handling
projection/mdata recursion
instantiate top-level bvar
instantiate under one binder without capture
instantiate multiple reversed arguments
terms with no matching bvars unchanged
```

Every case compares to the equivalent PSC1Kernel operation.

- [ ] **Step 2: Run tests to verify failure**

```bash
lake exe psc2_kernel_core_subst_parity_tests
```

Expected: FAIL for missing substitution operations.

- [ ] **Step 3: Implement minimal pure substitution algorithms**

Port the semantic algorithm, not state/caching infrastructure. Keep recursion explicit and PSC1-compatible.

- [ ] **Step 4: Add a dedicated source-profile gate for KernelCore**

Create `scripts/check-kernel-core-source.mjs` that scans only `packages/pskernel-core/src/**/*.lean` and rejects at least the same non-portable constructs forbidden for portable compiler modules:

```text
Lean/Std implementation imports
unsafe
implemented_by
extern
custom macros/syntax/elaborators
run_tac
IO
Lean.* / Std.* implementation APIs
```

Do not reject ordinary namespace/module organization if KernelCore requires it unless the PSC1 language profile itself forbids it; prefer the strictest subset that the current compiler can actually compile.

Add npm script:

```json
"check:kernel-core-source": "node scripts/check-kernel-core-source.mjs"
```

- [ ] **Step 5: Run substitution and source-discipline gates**

```bash
lake exe psc2_kernel_core_subst_parity_tests
npm run check:kernel-core-source
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Subst.lean psc15selfhost/packages/pskernel-core/src/Ps/KernelCore.lean psc15selfhost/test/KernelCoreSubstParityTests.lean psc15selfhost/scripts/check-kernel-core-source.mjs psc15selfhost/package.json psc15selfhost/lakefile.lean
git commit -m "feat(pskernel-core): add substitution parity"
```

---

### Task 6: Add a single Phase-1 acceptance gate and size report

**Files:**
- Create: `psc15selfhost/scripts/report-kernel-core-size.mjs`
- Create: `psc15selfhost/packages/pskernel-core/PHASE1_ACCEPTANCE.md`
- Modify: `psc15selfhost/package.json`

**Interfaces:**
- Consumes: all Task 1-5 tests/gates.
- Produces: `npm run assurance:kernel-core:phase1` and a reproducible TCB-size report comparing the new core with the reference semantic tree without counting tests/oracle fixtures as trusted code.

- [ ] **Step 1: Add a failing aggregate npm gate**

Add:

```json
"assurance:kernel-core:phase1": "npm run check:kernel-core-source && lake exe psc2_kernel_core_boundary_tests && lake exe psc2_kernel_core_name_parity_tests && lake exe psc2_kernel_core_level_parity_tests && lake exe psc2_kernel_core_expr_parity_tests && lake exe psc2_kernel_core_subst_parity_tests && node scripts/report-kernel-core-size.mjs"
```

Run it before the size reporter exists and verify it fails at the final step.

- [ ] **Step 2: Implement the size reporter**

`report-kernel-core-size.mjs` must print at least:

```text
KernelCore trusted .lean file count
KernelCore trusted source bytes
KernelCore trusted nonblank/noncomment LOC (simple deterministic counting rule documented in script)
PSC1Kernel comparable semantic-source bytes for the selected baseline
ratio KernelCore/reference
```

Exclude `PSC1Kernel/Test`, replay fixtures, generated artifacts and docs from the trusted-size comparison. Do not declare success based on a hard-coded percentage; the purpose is transparent measurement.

- [ ] **Step 3: Run the aggregate gate**

```bash
npm run assurance:kernel-core:phase1
```

Expected: PASS and print a materially smaller KernelCore trusted surface than the current reference semantic tree.

- [ ] **Step 4: Record acceptance evidence**

Create `PHASE1_ACCEPTANCE.md` recording:

```text
branch/commit
Lean version
commands run
module list
size report
parity cases covered
explicit non-claims: no infer/WHNF/defeq/Quot/inductive parity yet
next milestone: declaration/environment + infer/reduction
```

- [ ] **Step 5: Run existing PSC2 bootstrap regression gate**

Run:

```bash
npm run check
```

Expected: PASS. This proves the isolated KernelCore work did not disturb the current minimal self-host compiler path.

- [ ] **Step 6: Commit**

```bash
git add psc15selfhost/scripts/report-kernel-core-size.mjs psc15selfhost/packages/pskernel-core/PHASE1_ACCEPTANCE.md psc15selfhost/package.json
git commit -m "test(pskernel-core): close foundational parity phase"
```

## Phase-1 Completion Criteria

Phase 1 is complete only when:

```text
pskernel-core exists as a separate portable package
PSC1Kernel reference remains unchanged semantically
Name parity passes
Level parity passes
Expr representation coverage passes
lifting/instantiation parity passes
dedicated portable-source gate passes
new kernel remains outside bootstrap closure
aggregate Phase-1 assurance gate passes
existing psc15selfhost npm run check passes
size report demonstrates a materially smaller trusted slice
```

No inference, WHNF, definitional equality, Quot, primitive-inductive, or compiler-admission integration claim is permitted yet. Those belong to the next plan after this slice is reviewed and green.
