# PSCKernel Core Level Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans and superpowers:test-driven-development task-by-task. Use systematic debugging for any unexpected gate failure.

**Goal:** Fresh-port `src/core/level.ts` into independent PSC1-compatible Lean as `Ps.PSCKernel.Core.Level`, preserving Lean 4.34 final universe-level semantics while keeping the TypeScript API recognizable and independently differentially testable.

**Architecture:** `PsCKernelLevel` is owned by `@proofscript/psckernel` and may depend only on the already-independent `Ps.PSCKernel.Core.Name` representation plus Lean/Init primitives accepted by the PSC1 source audit. The port follows the six Lean level constructors literally. TypeScript `WeakMap` caches, object identity, and iterative implementation details are not semantic requirements: use pure structural recursion/list helpers and explicit change information where needed. Lean 4.34 `src/kernel/level.cpp` is authoritative for smart constructors, normalization, equivalence, and `is_geq`; `src/core/level.ts` is the structural/API/behavioral port target.

**Primary sources:**

- `src/core/level.ts`
- `test/all.test.ts` level-focused cases
- `study/lean4-4.34.0/src/kernel/level.cpp`
- `study/lean4-4.34.0/src/kernel/level.h`
- `study/lean4-4.34.0/src/Lean/Level.lean` where representation/runtime metadata clarification is useful
- approved design: `docs/superpowers/specs/2026-09-26-psckernel-fresh-port-design.md`

**Starting checkpoint:** `Core/Name` is green through commit `fce2e2f5defa65ffad9e756a7a38e9701bc9a681`; parity ledger commit `6eae16511fb11efb454c4a49c610b6eee5cb53b4` records it as 1/29 structural mirror files.

## Non-negotiable constraints

- Stay on `selfhost/psckernel-fresh-port`; never modify `main`.
- Do not copy implementation source from existing `psc1-kernel` branches.
- Do not import `Ps.Core.Level`, `Ps.Foundation.Name`, `@proofscript/core`, `@proofscript/environment`, meta/elab/compiler/backends, or the TypeScript kernel at runtime.
- `Core/Level.lean` imports only `Ps.PSCKernel.Core.Name` from PSCKernel and otherwise remains PSC1 portable.
- Preserve raw `max`/`imax` constructors separately from smart `mkMax`/`mkIMax`.
- Do not make JavaScript object identity part of PSCKernel semantics. Structural/source-level behavior is the contract.
- Caches may be absent initially because they are performance-only.
- Do not replace Lean 4.34’s intentionally incomplete `is_geq`/equivalence with a stronger complete universe solver.
- Production authority remains `lean-ts-kernel`; this slice is differential assurance only.
- New TS ↔ PSCKernel semantic differences require a pinned Lean 4.34 oracle regression and explicit documentation before being accepted.

## Public Level surface

The completed file should expose recognizable prefixed equivalents of the TypeScript API:

```text
inductive PsCKernelLevel
  | zero
  | succ (of : PsCKernelLevel)
  | max (left : PsCKernelLevel) (right : PsCKernelLevel)
  | imax (left : PsCKernelLevel) (right : PsCKernelLevel)
  | param (name : PsCKernelName)
  | mvar (name : PsCKernelName)

psCKernelLevelZero
psCKernelLevelSucc
psCKernelLevelParam
psCKernelLevelMVar
psCKernelLevelMaxRaw
psCKernelLevelIMaxRaw
psCKernelLevelEqStructural
psCKernelLevelHasMVar
psCKernelLevelParamNames
psCKernelLevelIsZero
psCKernelLevelIsNotZero
psCKernelLevelNormalizesToZero
psCKernelLevelMkMax
psCKernelLevelMkIMax
psCKernelLevelToOffset
psCKernelLevelAddOffset
psCKernelInstantiateLevel
psCKernelNormalizeLevel
psCKernelLevelLe
psCKernelLevelEquivalent
psCKernelLevelToString
```

Use a small structure such as `PsCKernelLevelOffset` for `(base, offset)` if that is clearer than an anonymous product. Offsets are `Nat` in PSC1 Lean; TypeScript `bigint` is only a host representation choice.

---

## Task 1: RED basic Level contract

**Files:**
- Create: `selfhost/packages/psckernel/test/LevelBasicTests.lean`
- Modify: `selfhost/lakefile.lean`
- Modify: `.github/workflows/psckernel-fresh-port.yml`

- [ ] **Step 1: Register `Core/Level` as a PSCKernel root before implementation exists**

Change `PsPSCKernel` roots to include both:

```text
`Ps.PSCKernel.Core.Name
`Ps.PSCKernel.Core.Level
```

- [ ] **Step 2: Add `psckernel_level_basic_tests` executable**

Register `LevelBasicTests.lean` in Lake and add a workflow step after `Name` tests.

- [ ] **Step 3: Write failing basic tests**

The test file imports `Ps.PSCKernel.Core.Level` and covers at least:

1. six constructor kinds build independently;
2. structural equality for freshly built equal trees;
3. `param u` and `mvar u` remain different kinds;
4. raw `max 0 0` and raw `imax 0 0` remain raw rather than smart-simplifying;
5. `levelHasMVar` finds nested metavariables and ignores parameters;
6. `levelParamNames` returns unique names in deterministic left-to-right traversal order;
7. `isZero`, `isNotZero`, and `normalizesToZero` reproduce Lean rules, including `imax u 0` normalizing to zero and `imax u (succ 0)` being definitely nonzero;
8. `mkMax 0 u = u`, `mkMax u 0 = u`, equal arguments collapse, same-base offsets keep the larger offset, and direct nested-max absorption matches Lean;
9. `mkIMax u 0 = 0`, `mkIMax 0 u = u`, `mkIMax 1 u = u`, known-nonzero RHS delegates to `mkMax`, equal arguments collapse;
10. `toOffset`/`addOffset` round-trip representative levels;
11. empty/unmatched instantiation preserves raw max/imax **shape** without relying on pointer identity;
12. matched parameter substitution occurs under succ/max/imax and smart constructors apply only on changed branches;
13. `levelToString` matches the existing TypeScript helper format for representative zero/succ/max/imax/param/mvar terms.

- [ ] **Step 4: Push RED and record the exact boundary**

Expected failure: workspace/source/Name gates pass; `lake build PsPSCKernel` fails specifically because `Ps.PSCKernel.Core.Level` does not exist. Fix scaffolding-only errors until that is the observed RED boundary.

- [ ] **Step 5: Commit**

```text
test(psckernel): add red Core Level basic contract
```

---

## Task 2: GREEN Level representation, smart constructors, and instantiation

**Files:**
- Create: `selfhost/packages/psckernel/src/Ps/PSCKernel/Core/Level.lean`
- Test: `selfhost/packages/psckernel/test/LevelBasicTests.lean`

- [ ] **Step 1: Implement the six-constructor independent representation**

Import only `Ps.PSCKernel.Core.Name`. Do not alias or wrap `Ps.Core.Level`.

- [ ] **Step 2: Implement structural equality/traversal predicates**

Implement `EqStructural`, `HasMVar`, unique `ParamNames`, `IsZero`, `IsNotZero`, and `NormalizesToZero` directly from the TS/Lean cases. Use explicit recursive/list helpers instead of mutable host collections.

- [ ] **Step 3: Implement raw and smart constructors**

Keep `MaxRaw`/`IMaxRaw` literal. Implement `MkMax` from Lean 4.34 `mk_max` behavior:

- both explicit levels choose the greater offset;
- structurally equal levels collapse;
- zero identities;
- direct nested-max absorption shortcuts;
- same-base successor chains choose the higher offset;
- otherwise produce a raw max.

Implement `MkIMax` from Lean 4.34:

- definitely-nonzero RHS -> `MkMax`;
- zero RHS -> zero;
- zero/one LHS -> RHS;
- equal args -> arg;
- otherwise raw imax.

- [ ] **Step 4: Implement offsets and instantiation without object-identity semantics**

`ToOffset` removes leading succs. `AddOffset` reconstructs them.

For instantiation, recursively substitute matching parameter names. Preserve raw max/imax structure when no substitution occurs below that node; when a child truly changes, rebuild using `MkMax`/`MkIMax` as Lean update helpers do. Return an internal `(level, changed)` result if necessary so unchanged shape does not depend on pointer identity.

Do not add TS-style `WeakMap` caching in trusted source.

- [ ] **Step 5: Implement the TS-facing diagnostic string helper**

`psCKernelLevelToString` should mirror `src/core/level.ts`, e.g. succ as `(<child>+1)`, max/imax as prefix text, param via `PsCKernelName`, mvar with `?`. This helper is API/debug behavior, not Lean C++ pretty-printer equivalence.

- [ ] **Step 6: Verify GREEN**

Require fresh workflow evidence for:

```text
workspace shape PASS
PSC1 source profile PASS
lake build PsPSCKernel PASS
psckernel_name_tests PASS
psckernel_level_basic_tests PASS
```

- [ ] **Step 7: Commit**

```text
feat(psckernel): port Core Level basic semantics
```

---

## Task 3: RED kernel normalization/equivalence contract

**Files:**
- Create: `selfhost/packages/psckernel/test/LevelKernelTests.lean`
- Modify: `selfhost/lakefile.lean`
- Modify: `.github/workflows/psckernel-fresh-port.yml`

- [ ] **Step 1: Add a separate `psckernel_level_kernel_tests` target**

Do not hide advanced failures inside the basic test target. Add the new workflow step after basic tests.

- [ ] **Step 2: Write advanced failing tests before implementing advanced behavior**

Cover at minimum:

1. normalize returns zero/param/mvar plus outer succ offsets unchanged structurally;
2. nested max nodes flatten and canonicalize independent of association/order;
3. duplicate same-base terms retain only the greatest successor offset;
4. explicit levels are retained or subsumed according to Lean 4.34 normalization rules;
5. normalized imax recursively normalizes both children, applies `MkIMax`, then reapplies the outer offset **without a second normalization pass**;
6. `levelEquivalent (max u v) (max v u)` succeeds after normalization;
7. distinct params, distinct mvars, and param-vs-mvar with the same `Name` remain non-equivalent;
8. `levelLe` covers zero, equal terms, same-base offsets, max on either side, and imax on either side;
9. regression for the existing TS adversarial case where max-geq must fall through before decomposing an imax target:
   `levelLe (mkIMax u v) (levelMaxRaw u v)` is true;
10. do **not** substitute a stronger complete universe decision procedure for Lean 4.34’s intentionally incomplete result set.

Where existing `test/all.test.ts` has stronger adversarial level cases, port those fixtures literally when they fit this isolated layer.

- [ ] **Step 3: Push RED**

Expected boundary: basic gates remain green; advanced test compilation fails only because `psCKernelNormalizeLevel`, `psCKernelLevelLe`, and/or `psCKernelLevelEquivalent` are not yet implemented.

- [ ] **Step 4: Commit**

```text
test(psckernel): add red Level kernel semantics
```

---

## Task 4: GREEN Lean 4.34 normalization, equivalence, and `is_geq`

**Files:**
- Modify: `selfhost/packages/psckernel/src/Ps/PSCKernel/Core/Level.lean`
- Test: `selfhost/packages/psckernel/test/LevelKernelTests.lean`

- [ ] **Step 1: Implement Lean 4.34 normalization ordering**

Port the semantics of `is_norm_lt` from pinned `src/kernel/level.cpp`:

- strip succ offsets first;
- compare base constructor rank using Lean order `Zero < Succ < Max < IMax < Param < MVar` (Succ is absent after stripping);
- params/mvars use `PsCKernelName` ordering;
- max/imax compare left then right recursively;
- same base compares offsets.

Use a pure list sort (e.g. insertion sort) if needed; the algorithmic container is not semantic.

- [ ] **Step 2: Implement exact normalizer shape**

Mirror Lean 4.34 `normalize`:

- zero/param/mvar bases return with existing outer offset;
- imax normalizes children, applies smart `MkIMax`, then reapplies the stripped outer succ count and stops;
- max flattens only syntactic max nodes, recursively normalizes leaves, flattens any max results, sorts by normalization order, performs explicit-universe subsumption, deduplicates same-base offsets keeping the largest, reapplies the outer offset to every retained arg, then rebuilds right-associated smart max.

Do not add a second normalize pass to the imax result.

- [ ] **Step 3: Implement structural-or-normalized equivalence**

`LevelEquivalent a b` is true exactly when structurally equal or their Lean-4.34 normal forms are structurally equal. Do not call a stronger theorem-prover/solver.

- [ ] **Step 4: Implement Lean 4.34 `is_geq` and expose `LevelLe`**

Follow pinned `is_geq_core` literally after normalizing arguments:

- equal or RHS zero -> true;
- RHS max -> both branches;
- LHS max -> positive shortcut if either branch dominates, otherwise **fall through**;
- RHS imax -> both branches;
- LHS imax -> compare its RHS;
- compare stripped offsets if same base or RHS base zero;
- if equal positive offsets, recurse on bases;
- otherwise false.

`LevelLe a b := is_geq b a`.

A recursive implementation is acceptable; TS’s explicit frame stack is an implementation detail used for JS stack safety.

- [ ] **Step 5: Verify both Level suites GREEN**

Record fresh output, including the max-geq fallthrough regression.

- [ ] **Step 6: Commit**

```text
feat(psckernel): port Lean 4.34 Level kernel semantics
```

---

## Task 5: TS differential + Lean oracle evidence

**Files:**
- Create: `selfhost/packages/psckernel/test/LevelFixture.lean`
- Create: `scripts/psckernel-level-differential.mjs`
- Create: `docs/psckernel/LEVEL_ORACLE_DEVIATIONS.md`
- Modify: `selfhost/lakefile.lean`
- Modify: `.github/workflows/psckernel-fresh-port.yml`
- Modify: `docs/psckernel/PROGRESS.md`

- [ ] **Step 1: Add deterministic Level fixture executable**

Print tab-separated records for representative basic and advanced results. Prefer structural encodings/`levelToString`, booleans, names, and offsets; do not compare object identity.

- [ ] **Step 2: Build an external TypeScript differential harness**

Import only the built `dist/src/core/level.js` and `dist/src/core/name.js`; invoke the Lean fixture externally. Compare at least:

- constructor/string forms;
- structural equality and param/mvar distinction;
- mvar/param traversal;
- `isZero`/`isNotZero`/`normalizesToZero`;
- smart max/imax results;
- offset round trips;
- matched/unmatched instantiation by **structure**;
- normalization canonical forms;
- equivalence;
- `levelLe`, including max/imax fallthrough regression.

Unknown or missing fixture keys are failures.

- [ ] **Step 3: Oracle-classify every discrepancy**

Start from an expectation of zero semantic deviations because the TS Level code claims final Lean 4.34 parity. If a difference appears:

1. inspect pinned `study/lean4-4.34.0/src/kernel/level.cpp`/`.h`;
2. add a focused regression;
3. fix whichever implementation disagrees with Lean 4.34 if within this branch’s scope;
4. only retain a deviation when it is intentional API/debug behavior or another justified non-semantic difference;
5. document it in `LEVEL_ORACLE_DEVIATIONS.md`.

Do not silently whitelist mismatches.

- [ ] **Step 4: Extend branch workflow**

After root TS build, run both Name and Level differential scripts. Preserve all existing gates.

- [ ] **Step 5: Update progressive parity ledger**

On green completion:

- structural files ported -> 2/29;
- compiling files -> 2/29;
- record separate Level unit case counts;
- record Level TS differential count/deviation count;
- keep real corpus, `.lean -> .ps`, generated TS/JS, cutover, self-hosting, and fixed point unchanged unless separately proven.

- [ ] **Step 6: Fresh final verification for this slice**

Require:

```text
Lean 4.34 githash pin PASS
workspace shape PASS
PSC1 source profile PASS
PsPSCKernel build PASS
Name unit tests PASS
Level basic unit tests PASS
Level kernel unit tests PASS
root TypeScript build PASS
Name differential PASS
Level differential PASS
```

- [ ] **Step 7: Commit**

```text
test(psckernel): add Level differential and oracle gates
```

## Review checkpoint

After Task 5, compare the branch diff against the approved design and this plan. The preferred Superpowers workflow requests an independent reviewer subagent, but if no subagent-dispatch capability exists in the active harness, record that limitation and perform a requirements/diff audit without misrepresenting it as independent review.

Only after this slice is green should the next plan begin `Core/Expr`.
