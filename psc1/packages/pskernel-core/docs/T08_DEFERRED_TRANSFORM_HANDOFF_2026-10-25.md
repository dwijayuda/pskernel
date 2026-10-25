## Bounded A/B driver prepared

`psc1/scripts/pskernel-transform-delay-abba.py` is prepared for four authentic Arena cases in fresh-process A-B-B-A order: repeated subproblem, Church numerals, Init.Prelude, and the rejected projection-of-stuck-Prop control. It pins the existing archive and case-body digests, uses the existing replay driver with fuel4096, empty PATH, 2,048MiB old-space and a 60-second per-case host bound, and compares complete semantic result fields whenever both variants finish.

The producer contract distinguishes the experiment SHA, the clean baseline/candidate kernel source SHA, and the single shared compiler source SHA. A separate compiler receipt binds the immutable native proof receipt to the compiler binary. All producer files and retained runtime controls must authenticate before measurement. Timeouts remain censored observations. This four-case diagnostic is neither the 193-case Arena qualification nor performance qualification. Producer workflow wiring and execution are still pending at this checkpoint.

## Native equality checkpoint — passed, generated/performance pending

Exact draft `d7d7b8905d6f7bb6e0044a2fcae4a33fe1424ed5` passed the native-only preflight in [40145171697](https://github.com/dwijayuda/pskernel/actions/runs/40145171697), attempt 1, job `121024847987`. The actual log contains all three ordered universal equality reports with only `propext`, `Classical.choice`, and `Quot.sound` as applicable. Source authentication confirms the three frozen bodies and exact full-file binding moves; all 186 native build jobs passed.

The proof log SHA256 is `d4149b5e52dd64256bfc68acb407fe110a436dbcfccd4faa72d26d0aa170cc4c`; the source-audit SHA256 is `6e37efc791958cf18ef5d4c4b640f73994cebe7cc4d2911ad73ddaea9c09a9fd`. The API-reported archive is `12580094440`, 4,525 bytes, SHA256 `04f193a1c779d458ef82a921be9a560e5eb5ce86dbf8b962b79ea095d9b6e4d4`; this checkpoint has not independently audited that ZIP. Exact terminal receipts and scope are recorded in `docs/qualification/T08_DEFERRED_TRANSFORM_NATIVE_d7d7b890.json`.

This is a scoped native equality result. Generated23, complete source qualification, and bounded A/B observations remain pending. Production integration still requires the complete source qualification.

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
