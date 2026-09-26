# PSCKernel Scaffolding and Core Name Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the independent `@proofscript/psckernel` self-host package and complete the first literal port slice, `Core/Name`, with PSC1-compatible Lean, Lake tests, TS differential coverage, and Lean 4.34 oracle regressions.

**Architecture:** This is the first sub-project of the approved fresh-port design. `PsCKernelName` is authored independently inside `selfhost/packages/psckernel/`; it does not import the existing `psc1-kernel`, `@proofscript/core`, `@proofscript/environment`, or the TS kernel at runtime. The TS kernel is used only by external differential tooling, while pinned Lean 4.34 is authoritative for semantic disagreements.

**Tech Stack:** Lean 4.34.0, Lake, PSC1-compatible portable `.lean`, npm workspace metadata, Node.js 22, TypeScript 5.8.3, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-26-psckernel-fresh-port-design.md`

## Global Constraints

- Work only on `selfhost/psckernel-fresh-port`; do not modify `main`.
- Package path is exactly `selfhost/packages/psckernel/`.
- npm package name is exactly `@proofscript/psckernel` and role is exactly `trusted-kernel`.
- Primary implementation source is PSC1-compatible `.lean`.
- Lean 4.34 final kernel semantics are authoritative when TS behavior differs.
- `lean-ts-kernel` is the structural/API/algorithmic port target and remains production authority during this phase.
- Do not copy implementation source from the existing `psc1-kernel` or make PSCKernel depend on it.
- Do not reuse `@proofscript/core` or `@proofscript/environment` kernel representations.
- Do not introduce runtime dependencies on TS, Node host adapters, meta, elab, compiler, checked compiler layers, backend-ts, backend-rust, or backend-wasm.
- Portable source must pass `selfhost/check-psc1-source.mjs`; in particular no `Lean`/`Std` implementation imports, `namespace`, `unsafe`, custom syntax/elaborators, `IO`, `mutual`, or explicit termination machinery in source roots.
- Failed semantic parity with TS is acceptable only when a pinned Lean 4.34 oracle source establishes the intended behavior and a regression test records the discrepancy.
- Do not switch production kernel authority in this plan.

## File Structure

- Create `.github/workflows/psckernel-fresh-port.yml` — branch-local verification for this fresh-port effort without weakening existing workflows.
- Create `selfhost/packages/psckernel/package.json` — workspace identity and `trusted-kernel` metadata.
- Create `selfhost/packages/psckernel/src/Ps/PSCKernel/Core/Name.lean` — independent `Name` representation and operations.
- Create `selfhost/packages/psckernel/test/NameTests.lean` — Lake unit tests for `Core/Name`.
- Create `selfhost/packages/psckernel/test/NameFixture.lean` — deterministic executable output consumed by differential tooling.
- Modify `selfhost/lakefile.lean` — add `PsPSCKernel`, `psckernel_name_tests`, and `psckernel_name_fixture` targets.
- Create `scripts/psckernel-name-differential.mjs` — external TS ↔ PSCKernel differential comparison; never imported by trusted source.
- Create `docs/psckernel/NAME_ORACLE_DEVIATIONS.md` — explicit Lean-4.34-backed deviations from the TS helper behavior.

## Review Focus

1. **Nonmatching prefix replacement:** Lean 4.34 `Name.replacePrefix` leaves the name unchanged; TS currently returns `null`. Task 2 must regression-test Lean behavior and Task 3 must classify the TS difference explicitly.
2. **Anonymous display:** Lean 4.34 core display/to-string uses `[anonymous]`; TS helper returns `_`. Task 2 must pin Lean behavior and Task 3 must record the differential exception.
3. **Component ordering:** numeral components sort before string components; strings compare by UTF-8/scalar ordering, including BMP-vs-astral cases. Task 2 tests both kind and Unicode ordering.
4. **Structural suffix preservation:** append, prefix, and replace operations must preserve numeral components structurally rather than stringify/reparse them. Task 2 tests mixed string/numeral names.
5. **Key/equality independence from object identity:** equal independently-built names must compare equal and produce the same key, while ambiguous textual forms must not collide. Task 2 tests fresh structural values rather than shared references.

---

### Task 1: Workspace Scaffolding and RED Name Tests

**Files:**
- Create: `.github/workflows/psckernel-fresh-port.yml`
- Create: `selfhost/packages/psckernel/package.json`
- Create: `selfhost/packages/psckernel/test/NameTests.lean`
- Modify: `selfhost/lakefile.lean`

**Interfaces:**
- Consumes: existing self-host workspace contract (`packages/*`, `sourceRoots`, `testRoots`, `outDir`) and Lake conventions.
- Produces: Lake library `PsPSCKernel`; executable `psckernel_name_tests`; manifest `@proofscript/psckernel` with `proofscript.bootstrap = true`, `sourceRoots = ["src"]`, `testRoots = ["test"]`, `outDir = "dist"`, `role = "trusted-kernel"`.

- [ ] **Step 1: Add branch-local verification workflow without changing existing gates**

Create `.github/workflows/psckernel-fresh-port.yml` triggered on pushes to `selfhost/psckernel-fresh-port` and `workflow_dispatch`. It installs Lean `v4.34.0`, checks the pinned githash, sets up Node 22, and runs these commands as separate evidence steps:

```text
node selfhost/scripts/check-workspace.mjs
cd selfhost && node check-psc1-source.mjs
cd selfhost && lake build PsPSCKernel
cd selfhost && lake exe psckernel_name_tests
```

Later Task 3 extends the same workflow with the differential command; do not duplicate the workflow.

- [ ] **Step 2: Add the package manifest**

Create `selfhost/packages/psckernel/package.json` with exact identity:

```json
{
  "name": "@proofscript/psckernel",
  "version": "0.0.0-dev",
  "private": true,
  "type": "module",
  "proofscript": {
    "bootstrap": true,
    "sourceRoots": ["src"],
    "role": "trusted-kernel",
    "testRoots": ["test"],
    "outDir": "dist"
  }
}
```

- [ ] **Step 3: Register Lake targets before implementation**

Add to `selfhost/lakefile.lean`:

```text
lean_lib PsPSCKernel where
  srcDir := "packages/psckernel/src"
  roots := #[`Ps.PSCKernel.Core.Name]

lean_exe psckernel_name_tests where
  srcDir := "packages/psckernel/test"
  root := `NameTests
```

- [ ] **Step 4: Write the failing Name tests**

Create `selfhost/packages/psckernel/test/NameTests.lean` importing `Ps.PSCKernel.Core.Name`. Define named boolean cases and a `main : IO Unit` that exits nonzero when any case fails. The cases must assert at least:

```text
anonymous display = "[anonymous]"
fromDotted "" = anonymous
fromDotted "_" = anonymous
fromDotted "A..B" = A.B            -- TS helper behavior, not Lean string_to_name
appendAfter (A.B) "_x" = A.B_x
appendIndexAfter (A.B) 7 = A.B_7
isPrefixOf A (A.B.3) = true
append (A.2) (B.3) preserves num/string/num structure
replacePrefix (A.B.3) A X = X.B.3
replacePrefix (A.B.3) Z X = A.B.3    -- Lean 4.34 oracle divergence from TS
fresh independently-built A.B values compare equal and have equal keys
nameCmp (A.1) (A."x") < 0            -- numeral before string
nameCmp (A."\uE000") (A."\u{10000}") < 0
```

- [ ] **Step 5: Push the RED commit and verify the expected failure**

Expected branch workflow result: workspace shape passes because `test/` exists, then `lake build PsPSCKernel` or `psckernel_name_tests` fails because `Ps.PSCKernel.Core.Name` does not exist yet. Record the exact failing job/step before implementation.

- [ ] **Step 6: Commit**

Commit message:

```text
test(psckernel): scaffold fresh Name port and red tests
```

---

### Task 2: Implement Independent `Core/Name`

**Files:**
- Create: `selfhost/packages/psckernel/src/Ps/PSCKernel/Core/Name.lean`
- Test: `selfhost/packages/psckernel/test/NameTests.lean`

**Interfaces:**
- Consumes: Lean/Init primitives only; no PS semantic representation from other packages.
- Produces:

```text
inductive PsCKernelName
  | anonymous
  | str (prefix : PsCKernelName) (value : String)
  | num (prefix : PsCKernelName) (value : Nat)

psCKernelAnonymous : PsCKernelName
psCKernelStrName : PsCKernelName -> String -> PsCKernelName
psCKernelNumName : PsCKernelName -> Nat -> PsCKernelName
psCKernelNameFromDotted : String -> PsCKernelName
psCKernelNameAppendAfter : PsCKernelName -> String -> PsCKernelName
psCKernelNameAppendIndexAfter : PsCKernelName -> Nat -> PsCKernelName
psCKernelNameIsPrefixOf : PsCKernelName -> PsCKernelName -> Bool
psCKernelNameAppend : PsCKernelName -> PsCKernelName -> PsCKernelName
psCKernelNameReplacePrefix : PsCKernelName -> PsCKernelName -> PsCKernelName -> PsCKernelName
psCKernelNameEq : PsCKernelName -> PsCKernelName -> Bool
psCKernelNameKey : PsCKernelName -> String
psCKernelNameCmp : PsCKernelName -> PsCKernelName -> Int
psCKernelNameToString : PsCKernelName -> String
```

Internal helpers must also use the `psCKernel*` prefix because portable source cannot rely on `namespace`.

- [ ] **Step 1: Confirm the RED workflow failure is the missing implementation, not scaffolding**

Do not write implementation until the pushed Task-1 workflow shows the expected module/test failure. If workspace metadata or Lake syntax fails earlier, fix only scaffolding and rerun until the failure reaches the missing `Name` implementation.

- [ ] **Step 2: Implement representation, equality, and structural component traversal**

Implement `PsCKernelName`, constructors, `psCKernelNameEq`, and helper traversal/rebuild functions without pointer/object identity semantics. `Nat` is the numeral payload, matching Lean `Name.num`.

- [ ] **Step 3: Implement TS-targeted convenience parsing/key behavior**

`psCKernelNameFromDotted` follows the TS helper contract: `""` and `"_"` map to anonymous and empty dotted components are ignored. `psCKernelNameKey` must be deterministic and injective over the tested component forms; for TS key parity on Unicode strings, count UTF-16 code units rather than Lean scalar count.

- [ ] **Step 4: Implement Lean-authoritative Name operations**

Implement append/prefix/order using the pinned Lean 4.34 behavior:

- `psCKernelNameAppendAfter` modifies the last string component or adds a string component after a non-string/anonymous base.
- `psCKernelNameAppendIndexAfter` appends `_<idx>` analogously.
- `psCKernelNameAppend` structurally appends suffix components and treats anonymous as identity.
- `psCKernelNameReplacePrefix` returns the rebuilt original name when the queried prefix does not match; it never uses TS `null` behavior.
- `psCKernelNameCmp` returns only `-1`, `0`, or `1`; numeral components sort before string components, scalar/UTF-8 string order is used, and a proper prefix sorts before the longer name.
- `psCKernelNameToString` uses `[anonymous]` for anonymous and raw dot-separated components for nonanonymous names.

- [ ] **Step 5: Run source and Lake gates**

Branch workflow must pass:

```text
node selfhost/scripts/check-workspace.mjs
cd selfhost && node check-psc1-source.mjs
cd selfhost && lake build PsPSCKernel
cd selfhost && lake exe psckernel_name_tests
```

Expected: all PASS.

- [ ] **Step 6: Commit**

Commit message:

```text
feat(psckernel): port independent Core Name
```

---

### Task 3: TS Differential Fixture and Lean 4.34 Deviation Evidence

**Files:**
- Create: `selfhost/packages/psckernel/test/NameFixture.lean`
- Create: `scripts/psckernel-name-differential.mjs`
- Create: `docs/psckernel/NAME_ORACLE_DEVIATIONS.md`
- Modify: `selfhost/lakefile.lean`
- Modify: `.github/workflows/psckernel-fresh-port.yml`

**Interfaces:**
- Consumes: `PsCKernelName` API from Task 2 and built root `lean-ts-kernel` exports from `dist/src/core/name.js`.
- Produces: executable `psckernel_name_fixture`; differential script that compares non-divergent behavior and separately asserts oracle-backed deviations.

- [ ] **Step 1: Add a deterministic Lean fixture executable**

Register:

```text
lean_exe psckernel_name_fixture where
  srcDir := "packages/psckernel/test"
  root := `NameFixture
```

`NameFixture.lean` prints stable tab-separated records for named cases. Include fields sufficient for the Node harness to compare `eq`, `toString`, `key`, `cmp`, append/prefix results, and replace-prefix results.

- [ ] **Step 2: Write the differential script before changing any implementation**

Create `scripts/psckernel-name-differential.mjs` that:

1. imports the built TS functions from `dist/src/core/name.js`;
2. runs `lake exe psckernel_name_fixture` with cwd `selfhost`;
3. parses fixture records;
4. compares TS and PSCKernel for non-divergent cases;
5. explicitly requires these oracle deviations:
   - nonmatching `replacePrefix`: TS `null`, PSCKernel unchanged structural name;
   - anonymous `nameToString`: TS `_`, PSCKernel `[anonymous]`;
6. exits nonzero for any unclassified difference.

- [ ] **Step 3: Document the two known deviations with pinned source references**

`docs/psckernel/NAME_ORACLE_DEVIATIONS.md` must identify the relevant Lean 4.34 files:

```text
study/lean4-4.34.0/src/Init/Meta/Defs.lean
study/lean4-4.34.0/src/util/name.cpp
```

For each deviation record: TS behavior, Lean 4.34 behavior, PSCKernel decision, regression case, and whether the difference is semantic or display-only.

- [ ] **Step 4: Extend branch CI with differential verification**

Add after unit tests:

```text
npm ci --no-audit --no-fund
npm run build
node scripts/psckernel-name-differential.mjs
```

Do not remove or weaken the workspace/source/Lake gates.

- [ ] **Step 5: Verify full first-slice evidence**

Expected green evidence:

```text
workspace shape: PASS
PSC1 source profile: PASS
PsPSCKernel Lake build: PASS
psckernel_name_tests: PASS
TS build: PASS
psckernel Name differential: PASS with exactly two classified Lean-4.34 deviations
```

- [ ] **Step 6: Commit**

Commit message:

```text
test(psckernel): add Name differential and Lean oracle gates
```

---

## Follow-on Sub-project Plans

Do not turn this file into a transcript for the whole kernel. After this slice is green, create and execute separate detailed plans in approved port order:

1. `Core/Level`
2. `Core/Expr`
3. `Core/Instantiate` + `Core/Checks`
4. `Core/Declaration` + `Core/LocalContext` + `Core/Environment`
5. `Kernel/Names` + `Kernel/PrimitiveNames` + `Kernel/State`
6. `Kernel/Reduction/*`
7. `Kernel/Primitive/*` + `Kernel/Primitive`
8. `Kernel/Quotient` + `Kernel/TypeChecker`
9. `Kernel/Inductive/Ordinary` + `Kernel/Inductive/Nested`
10. `Kernel/Kernel`
11. `Integration/ExactJson` + `Integration/Lean4Export`
12. public `Ps/PSCKernel.lean` barrel, bounded corpus parity, `.lean -> .ps` readiness, generated TS/JS readiness, and later cutover planning.

Each follow-on plan must repeat the same test-first cycle: relevant TS tests first, failing PSC1/Lake gate, minimal implementation, TS differential, Lean 4.34 oracle regression for disagreements, then a coherent commit with fresh verification evidence.
