# Lean 4.33 → 4.34 trusted-kernel delta

Status: release-pinned audit for `kernel/lean434-study-hardening`.

## Scope

The target is the exact Lean `v4.34.0` tag:

- tag commit: `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`
- previous release tag: `v4.33.0` at `d8b18978322de05a8f3dba51ef03cf5461676c17`

Only commits in the ancestry of the final v4.34.0 tag count as target
semantics. Master-branch commits from the same calendar window are not
automatically part of 4.34.

The tag ancestry contains six `src/kernel` changes after v4.33.0.

## Exact release delta

| Release commit | Change | pskernel mapping |
| --- | --- | --- |
| `a068033d324c6eec8e5d4ace6ac137986160b3e9` | Uniform occurrences of inductives must use the declaration parameters and universe levels before WHNF/nested preprocessing | `checkUniformInductiveOccurrences`; direct regressions for erased occurrences, nested dropped parameters, universe mismatch, and defeq parameter binders |
| `a221d8246f8d953fa6bd9b170762ab81d53445c3` | Replace transitive defeq union-find with plain pair caches so algorithmic `is_def_eq` is history/order independent | pair-local structural success/failure caches; direct non-transitivity, original-pair success caching, cache-boundary regressions; official exploit files retained as oracle stress tests |
| `4576c1cf62ed2b4a4fc1cd2e19e53f1a4a97113e` | `is_prop` must call `ensure_sort(infer_type(...))`, rejecting stuck non-sort types instead of returning false | `TypeChecker.isProp`; compact reducible-sort/projection regression plus non-sort rejection; both large transported-history exploits remain oracle stress tests |
| `408d2ade265cd18dc73ff763c0ce12c784cafdc4` | Re-check generated recursor types and prove each computation rule type-preserving through real reduction | synthesis-side expected-rule checks plus `validateInstalledRecursorsByReduction`; direct corrupted-`nFields` and well-typed under-applied-minor regressions |
| `c740e4df1984194a84edf4b715bb49daa08a9c14` | Structure eta during recursor reduction must use the fixed `is_prop` predicate | recursor reducer receives `isProp`; direct imax-normalized proof-structure regression prevents data projection during eta |
| `bf8db3df0fb28cb6a24625796bc32ab4a01e9458` | Bound trusted Nat literals/results; preflight `pow`/shift; enforce 32-bit exponent/shift counts | `reduction/nat.ts` resource guards; direct literal/count test and growth-checkpoint test for succ/add/sub/mul/pow/shiftLeft |

## Important non-delta

The master commit

`2a7175c74ba17b160299accd7e6ea6984d7ea86f`

removes deprecated in-kernel native reduction, but it is **not** an ancestor of
the final v4.34.0 tag. The v4.34 target therefore retains the native-reduction
hooks. This branch must not import that master-only removal.

## Result of this audit

For the v4.33 → v4.34 trusted-core delta, no new semantic subsystem is missing
from pskernel. The useful remaining work is:

1. keep the exact six changes regression-locked;
2. execute the current TypeScript suite again on a real runner;
3. run the canonical one-pass Full Std environment replay;
4. diagnose the first real mismatch, if any;
5. only then proceed to Full Lean and formal equivalence.

This checklist does **not** claim Full Std, Full Lean, native-provider
independence, or formal equivalence.

Research checkpoint: 2026-09-24.
