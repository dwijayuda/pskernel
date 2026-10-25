# T08 deferred transform workers — prepared draft, 2026-10-25

## Status

This is an unqualified implementation draft based on `10144e2f9e8d223b5dcde275bd1f48d25df113b3`. The baseline's complete T05 generated qualification and archive audit were still running when this draft was prepared. No performance improvement, Arena compatibility result, or new qualified source is claimed.

## Native preflight correction

Initial run [40144960417](https://github.com/dwijayuda/pskernel/actions/runs/40144960417), attempt 1, at `705ec57230ae631aa6779072d0522c9d3815645e` passed the frozen-body authentication, exact three-binding-change guard, portable source/syntax checks, and native production build (186 jobs). The three successor proof cases simplified to matching expressions but lacked the final definitional-equality closure used by the retained `PsKernelKnotFuelProofs` pattern.

The repair appends `<;> rfl` to each of the three existing simplification steps. The universal theorem statements, frozen definitions, and production files are unchanged. The failed run supplies no proof qualification; a fresh exact-source native preflight is required.

## Focused production change

Move only the existing predecessor-function binding under every existing result lambda in:

- `Core/ExprV2/Transform.lean`: `psKernelExprV2TransformWithFuel`.
- `Core/ExprV2/TransformSupport.lean`: `psKernelExprV2TransformCountWithFuel`.
- `Core/ExprV2/Lift.lean`: `psKernelExprV2PagedLiftWithFuel`.

The explicit declaration arities, fuel clauses, helper calls, memo keys, state, errors, and output IDs remain the same. This addresses eager recursive function construction in generated code. TransformSpine already defers its predecessor and is unchanged.

## Gates

`PsKernelDeferredTransformProofs.lean` freezes the three original worker bodies and states universal function equalities for every fuel and arbitrary state/input, with no valid-arena or valid-memo premises. The native preflight authenticates the original Git blobs, frozen bodies, and the exact binding-only edits across all three complete source files. It requires exactly three ordered proof reports using only the standard allowed axioms.

The new generated harness has 23 assertions covering all 11 returned-function stages across three exports, raw zero/successor fuel precedence, malformed internal roots/memos, state identity, shared-child memo threading, and appended IDs. These raw equations do not establish validity for untrusted input. The retained checked-wrapper and broad transformation controls remain required.

Native preflight and JavaScript syntax checks precede expensive complete generated or performance work. The preflight is diagnostic only. Before adoption, require fresh exact-source complete native/generated/canonical qualification and archive verification, plus a bounded same-runner A/B measurement preserving Node22, Lean4.35, fuel4096, and existing limits.

## Remaining performance obligations

Historical Church tracing already locates a fuel4096 type-DefEq exhaustion. This exact-semantics change must preserve that result; it is not a claim that Church is accepted. The Init.Prelude timeout and full Arena compatibility must be measured on the new exact source. A remains qualified on its recorded source; B is OPEN, C is FAIL, D is OPEN. The replay/ArenaModel and external decoder/layout proof bridges remain open.
