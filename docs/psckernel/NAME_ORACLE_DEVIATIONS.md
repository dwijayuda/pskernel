# PSCKernel `Core/Name` Lean 4.34 Oracle Deviations

This file records intentional differences between the independently authored PSCKernel `Core/Name` port and the current handwritten TypeScript `lean-ts-kernel` helper layer.

During the fresh-port phase, production authority remains `lean-ts-kernel`. These entries are differential evidence only; they do not authorize a production cutover or a silent semantic fallback.

## Authority rule

For PSCKernel semantics, pinned Lean 4.34 final is authoritative. The TypeScript implementation remains the structural/API/algorithmic port target, but a difference is retained when the pinned Lean source establishes different behavior. Any additional, unclassified TS ↔ PSCKernel difference is a test failure.

## 1. Nonmatching `Name.replacePrefix`

**TypeScript behavior:** `src/core/name.ts` returns `null` when the requested prefix is not an ancestor of the input name.

**Lean 4.34 behavior:** `Name.replacePrefix` in `study/lean4-4.34.0/src/Init/Meta/Defs.lean` recursively rebuilds the name. If the queried prefix is never encountered, the recursion reaches `anonymous` and reconstructs the original string/numeral suffix, leaving the input name unchanged.

**PSCKernel decision:** `psCKernelNameReplacePrefix name query replacement` follows Lean 4.34 and returns the unchanged structural name for a nonmatch.

**Regression:** the `Core/Name` unit test checks that replacing `Z` inside `A.B.3` with `X` returns `A.B.3`. The external differential harness separately requires the TypeScript side to return `null` and the PSCKernel side to retain the original key.

**Classification:** semantic API difference.

## 2. Anonymous `Name` display

**TypeScript behavior:** `src/core/name.ts` renders the anonymous name as `_`.

**Lean 4.34 behavior:** the core name display implementation in `study/lean4-4.34.0/src/util/name.cpp` renders the anonymous name as `[anonymous]`.

**PSCKernel decision:** `psCKernelNameToString psCKernelAnonymous` returns `[anonymous]`.

**Regression:** the `Core/Name` unit test pins `[anonymous]`, and the external differential harness requires the TypeScript result `_` and PSCKernel result `[anonymous]`.

**Classification:** display behavior difference; it does not change structural equality or keys.

## Differential gate

`scripts/psckernel-name-differential.mjs` compares the PSCKernel Lean fixture with `dist/src/core/name.js`. It accepts exactly the two deviations above. Unknown fixture fields, missing fields, parity mismatches, or drift in either classified deviation fail the gate.
