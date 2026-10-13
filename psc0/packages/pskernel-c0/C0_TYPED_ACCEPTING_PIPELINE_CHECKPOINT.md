# PSKernel-C0 — Source-Checked Typed Elimination and Admission Checkpoint

**Date:** 2026-10-14 (Asia/Jakarta)  
**Branch:** `perf/pskernel-c0-v7-rust-20261012`  
**Scope:** `psc0/packages/pskernel-c0/` native Lean 4.35 only  
**Status:** Implemented source-checked admission and typed reduction integration; independent optimized accepting kernel **NOT COMPLETE**.

## 1. Implemented source-checked declaration boundary

`Architecture/Work.lean` now recognizes all supported source declaration families:

- Ordinary axioms, definitions, opaques and theorems.
- Ordinary, mutual and nested inductives.
- Source Eq-dependent quotient initialization.

Every successful request delegates to the existing source kernel validator, advances the environment atomically, constructs a fresh checked session to invalidate old WHNF/DefEq/inference caches, and preserves the explicit `eagerReduce` setting. Failed declarations return an error without publishing a partial environment. Staged scratch syntax remains syntax-only; malformed/foreign roots are rejected by replay validation.

`WhnfWork`, `InferWork`, `DefEqWork`, `IsPropWork`, and `CheckWork` share one validated source-owned session. **Only full `CheckWork` certifies that an arbitrary input term is well-typed**; WHNF, inference, isProp and DefEq on their own are not a declaration-admission or whole-expression validation verdict. This distinction was explicitly regression-tested with malformed `Quot.lift` arguments.

## 2. Real checked typed elimination

The mandatory `test/C0TypedEliminationRegression.lean` now uses **source-admitted**, not synthetic recursor metadata:

- A singleton proposition with no fields produces source-recognized K: a neutral locally typed proof reduces to its unique checked constructor, while an unbound proof cannot be manufactured.
- A nonrecursive data-valued structure with two fields produces source-justified eta: a neutral, locally typed structure is rebuilt with its two typed projections; source `infer` and source `DefEq` confirm the result.
- A Prop-valued constructor-with-fields is **not** eligible for data structure-eta.
- Genuine mutually recursive checked inductive families do **not** qualify as nonrecursive structures; attempting eta on a neutral recursive major remains stuck.
- Source-exact `Eq` / `Eq.refl` declarations are independently checked before `Quot.mk`, `Quot.lift`, `Quot.ind` are initialized. Quot initialization is idempotent.
- Real indexed K handles `Eq.{1} Prop P P` by synthesizing source-checked `Eq.refl` only after type inference and definitional equality; `Eq Prop P (P → P)` cannot be rewritten by the K rule.
- A fully source-checked `Quot.lift` example is tested for full term checking, WHNF computation and DefEq, while mistyped relation-preservation witnesses and universe levels must fail **full source checking**, not merely type synthesis.

**Scope caveat:** the positive nested-dispatch fixture exercises source-admitted singleton routing; it does not establish acceptance of arbitrary genuinely nested inductive families. Synthetic K/eta metadata still cannot be treated as trusted declarations.

## 3. Experimental typed-major demand integration

`Architecture/Typed.lean` can construct a **candidate input** by substituting an exact source-justified K/structure-eta major into a recursor application. It never guesses a constructor from a family name or field count. The source `psKernelSessionWhnf` runs FIRST, and the existing CDE demand evaluator then independently produces an optional candidate result. The pre-normalized candidate wrapper spends resource quota and the demand evaluator receives only the **remaining** allowance.

A real checked `Box.rec` with a neutral structure major must agree with source WHNF after typed eta/iota; an underfunded candidate must leave source WHNF and the checked session unchanged. No candidate result is used for theorem/declaration admission.

This is a qualified observational integration slice, **not an independent typed K/eta implementation**: the typed premise still uses source infer/WHNF/DefEq. Complete native acceptance, proof/refinement, full resource/error parity, and competitive whole-workload evidence remain open.

## Recent source qualification and acceptance-contract clarification

The positive real checked `Eq`/`Quot` bootstrap, indexed K side-condition,
source-justified metered structure recursor, and source-delegated checked
WHNF/Infer/DefEq/IsProp work APIs have passed native CI in their bounded
slices, including [38464230358](https://github.com/dwijayuda/pskernel/actions/runs/38464230358),
[38464486308](https://github.com/dwijayuda/pskernel/actions/runs/38464486308) and
[38464668623](https://github.com/dwijayuda/pskernel/actions/runs/38464668623).

A deliberately ill-typed `Quot.lift` argument was found to be **inferable**
without being **checkable**, as required by the source kernel's two distinct
operations: `InferWithFuel` uses inference-only mode, while
`CheckWithFuel` uses full checking mode. The strengthened negative regression
requires `ArchitectureCheckWork` to reject the invalid relation proof and
universe instantiation. [Native CI 38465192514](https://github.com/dwijayuda/pskernel/actions/runs/38465192514)
passed this full-check negative test.

The latest work additionally preserves an explicitly selected source
`eagerReduce` policy across successful admission while rebuilding all
checking caches. Native [CI 38465553974](https://github.com/dwijayuda/pskernel/actions/runs/38465553974)
is the qualification gate for that follow-up and the corrected documentation
syntax. No latest full CI success is asserted until that run completes.

**Latest full source qualification:** [`e49e14e8`](https://github.com/dwijayuda/pskernel/commit/e49e14e8820ecf77a861e97ddba239778dd432a5) — **full [native CI 38465553974](https://github.com/dwijayuda/pskernel/actions/runs/38465553974) SUCCESS**. This includes all new typed regression and checked work interface tests. Source `infer` remains inference-only; full `check` validates the two deliberately mistyped Quot.lift applications. The executable passes architecture regressions and the project CI suite, not an independent proof of kernel equivalence.

## 4. Qualification evidence and remaining gates

Earlier full native CI [38462459034](https://github.com/dwijayuda/pskernel/actions/runs/38462459034) verifies the initial checked singleton proposition and structure tests; [38464230358](https://github.com/dwijayuda/pskernel/actions/runs/38464230358) verifies metered source-justified typed-demand integration. [38464486308](https://github.com/dwijayuda/pskernel/actions/runs/38464486308) has also passed the combined positive checked proposition and unified source-judgment API.

The latest source includes the full typed Quot examples, strict full-check negative cases, and explicit reduction-policy preservation. **Do not mark the latest code fully qualified until the corresponding latest native CI completes successfully.** The CI must execute compilation, official positive/negative export fixtures, typed regression, checked-work regression, resource tests, negative conformance, microbenchmarks and independent original checker comparison.

Remaining major gates:

1. **Phase C:** auditable store ownership/invariants with selected implementation whole-workload evidence.
2. **Phase D:** complete independent typed K/eta and dependent WHNF semantics, with strict resource classifications.
3. **Phase E:** one independently qualified accepting optimized WHNF/DefEq/inference/admission kernel, beyond this source-delegated transaction boundary.
4. **Phase B:** complete Lean 4.35 Init, Std and Mathlib same-byte acceptance, including the preserved first mismatch at record 86,383; no false acceptance.
5. **Phases F and G:** matched fully checked competitive benchmarks; formal refinement/soundness/representation assurance.

**Authority is unchanged:** only the original checked kernel controls successful judgments and environment publication. No original `pskernel-core`, compiler, Rust/Wasm or self-host edits.
