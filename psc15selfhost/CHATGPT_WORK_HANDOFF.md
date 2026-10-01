# ChatGPT Work Handoff

Updated: 2026-10-01 (Asia/Jakarta). Continuation of the Work session started
from `Pasted text(20260930-195252).txt`.

## Scope and shared branch

- Repository: `dwijayuda/pskernel`.
- Branch: `psc2/minimal-selfhost-psc15`. Do not merge to main.
- Write only `psc15selfhost/`. Do not change `psc2selfhost/` or `.github/`.
- PSC1-compatible `.lean`, official Lean 4.34.0 bootstrap, TS/JS generation 1.
- Keep target-neutral semantic/IR boundaries and AdmissionReadyModule distinct
  from kernel-backed CheckedCore. Rust/Wasm and kernel-provider integration are
  outside the first fixed-point closure.
- Never weaken structural-recursion safety or expand the bootstrap language.
- Another session writes this branch. Refresh before every ref update, inspect
  intervening patches, preserve concurrent guards, and never force-push.

## Current snapshot and first blocker

Base head for this repair: `fe412138f64c4e5a1ab65e4a7fa95ba1586715ee`.
Canonical run `36888982066`, job `110459459656`, passed source gates,
the official Lean elaborator build, and emitted:

```text
PSC2_FIXED_POINT_RUNTIME_REGRESSIONS: PASS
```

The two string appends in `psErasureAddUniqueString` now parse. The new first
failure is the next declaration's local-match separator:

```text
PSC1_PROJECT_PARSE_FAILED: packages/erasure/src/Ps/Erasure/Definition.lean: 42:7: expected ';', got 'match'
```

This repair normalizes only `psBuildErasureDeclarationNames`: an explicit
list-recursive worker returns the naming-state function, with a thin wrapper
preserving the existing argument order. Its local name match has an explicit
`Option PsName` type, qualified constructors, and semicolon separators. State
updates use `PsErasureNameState.mk`, `List.cons`, and `Prod.mk`.

The focused declaration-names guard was observed RED on the old source and GREEN
on the repair. It is directly imported by the aggregate source gate. Aggregate
source and local bootstrap-closure checks pass. A native regression was added to
MinimalSelfHostTests for collisions, skipped axioms, all included declaration
variants, output order, existing state, and empty input. Its CI result and the
fresh canonical fixed-point replay are still pending.

All concurrent Declaration repairs and their guards remain intact. The earlier
local recursor-minor draft was set aside because `4dcf65ff` already supplied the
equivalent worker and wrapper.

## Confirmed Declaration progress

| Repair | Landed commit | Subsequent compiler evidence |
| --- | --- | --- |
| Term elaborator fuel-only recursion returning a callback | Concurrent `e3ae2d21` | Run `36813544281` advanced beyond Term.lean |
| Typed-binder reverse in structural-recursion discovery | `eb75a18d` | Run `36813972553` advanced to constructor-name selection |
| Explicit PsName type for constructor-name local match | `4eea0276` | Run `36814537484` advanced to binder arguments |
| Explicit binder-to-expression mapping after typed reversal | Concurrent `3065721e` | Later runs advanced beyond binder arguments |
| Implicit-binder closing structural worker | `cb459577` | Later runs advanced beyond it |
| Expression-list alpha equality structural worker | `6459642f` | Later runs advanced beyond it |
| Project list length for direct-recursive-field checks | `ba03754d` | Later runs advanced beyond it |
| Typed field reversal and parameter/field counts in inductive constructors | `ec91470f` | Run `36845211567` advanced to constructor-list traversal |
| Structural constructor traversal with ordered accumulator reversal | `954eefd2` | Run `36846157136` advanced to recursive-hypothesis wrapping |
| Explicit recursive-hypothesis index matching | `565c0561` | Run `36846906468` advanced to recursor minor binders |
| Recursor minor binder declaration-list worker/wrapper | `4dcf65ff` | Run `36885530518` advanced into erasure |
| Recursor metadata counts and explicit inductive matches/results | Through `d969f0a2` | Run `36885530518` advanced into erasure |
| Structure, partial, batch, and declaration-list source normalization | Through `ff5e3a3b` | Run `36885530518` advanced into erasure |

Earlier record-selection, syntax-local-ID, Nat lookup, structural-call validation,
and related Option/recursion repairs remain present. Do not repeat them.

## Runtime regression evidence

The closure probe runs `lake exe psc2_minimal_selfhost_tests` before fixed-point
compilation and emits `PSC2_FIXED_POINT_RUNTIME_REGRESSIONS: PASS` on success.
That marker was observed in canonical runs `36846906468`, `36885530518`,
and `36888982066`.
It includes the constructor-traversal regression covering output order,
nonzero constructor indices, an existing reversed accumulator, empty input,
and error propagation. This repair still needs its own fresh canonical replay.

## Exact next action

1. Refresh the branch; another session may have advanced it.
2. Read the newest `PSC2 minimal kernel` run tied to the current head.
3. Require source gates and official Lean to pass; inspect both parse and
   elaboration failures in the full fixed-point tail.
4. Work on the new first declaration/error only. Observe a focused RED guard
   before the smallest PSC1-safe semantics-preserving rewrite.
5. Do not claim Compiler2/Compiler3/Compiler4 parity or fixed-point success until
   the canonical evidence reports it explicitly.

## Commands and environment

```sh
cd psc15selfhost
node scripts/check-erasure-declaration-names-selfhost-source-syntax.mjs
npm run check:selfhost-source-syntax
node scripts/check-bootstrap-closure.mjs
lake build Ps.Elab.Declaration
lake exe psc2_minimal_selfhost_tests
npm run fixed-point
```

The branch is the durable source of truth. This local environment does not have a
usable Lean/Lake executable, so official Lean and fixed-point evidence comes from
CI. Do not label a local environment failure as compiler RED.
