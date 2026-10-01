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

Current production repair commit: `4dcf65ffd6ea12eaf0a4597287256b42c7bbf4f1`.
It normalizes `psBuildRecursorMinorBinders` into a declaration-list-recursive
worker plus a thin public wrapper.

The last canonical fixed-point run before this repair was run `36846906468`, job
`110319106925`. It passed source gates, official Lean compilation, and emitted:

```text
PSC2_FIXED_POINT_RUNTIME_REGRESSIONS: PASS
```

Its first compiler failure was:

```text
PSC1_PROJECT_ELAB_FAILED: packages/elab/src/Ps/Elab/Declaration.lean: declaration=psBuildRecursorMinorBinders: matchConstructorUnknown:PsElabContext.context
```

A focused guard was added in `336d714a` and wired into the aggregate source gate
in `8270bea3`. Canonical run `36857558503`, job `110353588071`, provided the RED
proof by failing specifically because `psBuildRecursorMinorBindersWorker` and its
wrapper did not yet exist.

The repair at `4dcf65ff` makes only the declarations list structurally recursive.
`context`, `index`, and `bindersRev` are applied after the recursive closure. The
base case uses `PsElabRecursorMinorsResult.mk context bindersRev`. The public
`psBuildRecursorMinorBinders` argument order and behavior are preserved.

The one-shot repair workflow verified the focused guard, aggregate source gates,
and `lake build Ps.Elab.Declaration` before committing the source rewrite. Because
the repair was pushed by `github-actions[bot]`, it did not itself launch a new
canonical fixed-point run. This handoff update is intended to trigger that
canonical replay. Do not claim the repair is fixed-point proven until that run
advances past `psBuildRecursorMinorBinders`.

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
| Recursor minor binder declaration-list worker/wrapper | `4dcf65ff` | Canonical fixed-point replay pending |

Earlier record-selection, syntax-local-ID, Nat lookup, structural-call validation,
and related Option/recursion repairs remain present. Do not repeat them.

## Runtime regression evidence

The closure probe runs `lake exe psc2_minimal_selfhost_tests` before fixed-point
compilation and emits `PSC2_FIXED_POINT_RUNTIME_REGRESSIONS: PASS` on success.
That marker was observed in canonical run `36846906468` before the current
recursor-minor-binder blocker. The current repair still requires a fresh canonical
run before its runtime/fixed-point status can be claimed.

## Exact next action

1. Refresh the branch; another session may have advanced it.
2. Read the newest `PSC2 minimal kernel` run tied to the current head.
3. Require source gates and official Lean to pass, then inspect the full
   fixed-point failure tail for both parse and elaboration errors.
4. If replay advances past `psBuildRecursorMinorBinders`, treat that blocker as
   closed and work only on the new first declaration/error.
5. For the new blocker, observe a focused RED guard first, then make the smallest
   PSC1-safe semantics-preserving rewrite. Do not guess or mass-rewrite later code.
6. Do not claim Compiler2/Compiler3/Compiler4 parity or fixed-point success until
   the canonical evidence reports it explicitly.

## Commands and environment

```sh
cd psc15selfhost
node scripts/check-elab-recursor-minor-binders-selfhost-source-syntax.mjs
npm run check:selfhost-source-syntax
node scripts/check-bootstrap-closure.mjs
lake build Ps.Elab.Declaration
lake exe psc2_minimal_selfhost_tests
npm run fixed-point
```

The branch is the durable source of truth. This local environment does not have a
usable Lean/Lake executable, so official Lean and fixed-point evidence comes from
CI. Do not label a local environment failure as compiler RED.
