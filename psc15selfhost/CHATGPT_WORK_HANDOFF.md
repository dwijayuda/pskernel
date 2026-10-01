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

Base for this repair: `954eefd2a6f31907e8529ac64c9f6977b98e1e94`.
This is the observed parent, not the commit containing this document.

Full run `36846157136`, job `110316681414`, passed source guards and Lean
compilation, and the self-compiler advanced beyond constructor-list traversal.
It then failed with:

```text
PSC1_PROJECT_ELAB_FAILED: packages/elab/src/Ps/Elab/Declaration.lean: declaration=psWrapRecursiveHypotheses: matchConstructorUnknown:PsExpr.body
```

The declaration used multi-argument equations for index list and body. PSC1
interpreted the `body` pattern as an expression constructor. This repair makes
indices and body explicit parameters, then matches only the index list. The
recursive call still passes unchanged motive ID, field arguments, and body.
No new worker or altered hypothesis ordering is needed.

A focused source guard is imported by the direct closure source gate. It was
RED before the signature/match normalization and GREEN afterward. Aggregate
source checks, local closure, JavaScript syntax check, and diff whitespace pass.

## Runtime regression evidence

`954eefd2` added a native test to `MinimalSelfHostTests.lean` for constructor
traversal: source order, starting index 7, a two-declaration accumulated prefix,
empty input, and invalid-name error propagation. The failing CI log truncates
earlier output, so this test's result was not directly visible in run
`36846157136`. Do not claim it passed from that log.

The existing CI-only closure probe now runs `lake exe psc2_minimal_selfhost_tests`
before fixed-point compilation and emits
`PSC2_FIXED_POINT_RUNTIME_REGRESSIONS: PASS` on success. That marker survives the
existing workflow's failure-summary filter. This changes only the verification
script inside psc15selfhost; the canonical fixed-point command remains unchanged.

Official Lean/runtime and fixed-point confirmation for this repair are pending.
No Compiler2/3/4 or parity/fingerprint success is claimed.

## Confirmed progress in this Work session

| Repair | Landed commit | Subsequent compiler evidence |
| --- | --- | --- |
| Term elaborator fuel-only recursion returning a callback | Concurrent `e3ae2d21` | Run `36813544281` advanced beyond Term.lean |
| Typed-binder reverse in structural-recursion discovery | `eb75a18d` | Run `36813972553` advanced to constructor-name selection |
| Explicit PsName type for constructor-name local match | `4eea0276` | Run `36814537484` advanced to binder arguments |
| Explicit binder-to-expression mapping after typed reversal | Concurrent `3065721e` | Later runs advanced beyond binder arguments |
| Typed field reversal and parameter/field counts in inductive constructors | `ec91470f` | Run `36845211567` advanced to constructor-list traversal |
| Structural constructor traversal with ordered accumulator reversal | `954eefd2` | Run `36846157136` advanced to recursive-hypothesis wrapping |

The two concurrent source repairs exactly matched this session's tested files:

- Term.lean blob `566e0281c95eb7e47a35878c906ae4344f97eb0f`.
- Declaration.lean binder-arguments blob
  `9f5950aaedc26baba7ee38184c689fd2479fadc0`.

Duplicate local patches were discarded. One-shot runs `36813480889` and
`36815057222` passed source guards and official Lean builds before those commits.

Concurrent reverse-guard repair `8866690e` and cleanup `2515d1e8` were preserved.
A stale one-shot repair had expected a new duplicate reverse helper; its guard
was aligned with the existing helper and its workflow was removed by the other
session. Do not recreate either the helper or workflow.

Since `3065721e`, concurrent commits also resolved:

- `cb459577`: implicit-binder closing with a structural worker.
- `6459642f`: expression-list alpha equality with a structural worker.
- `ba03754d`: project list-length helper for direct-recursive-field checks.
- Related guard boundary and whitespace fixes, including `86b282e` and `633fcea4`.

These are present in the current base. Do not repeat them.

## Older fixes and obsolete candidates

Earlier Work fixes remain present: `967723ea` callback type guard;
`469e04c6`, `3a02d872`, `c2f76805` record Option qualifications;
`f0e6ef6d`, `17095628` record-candidate recursion; `3c1318bc` duplicate guard
transport correction. Concurrent `545d19b6` supplied the record-candidate
semicolon, and subsequent commits resolved the remaining record selection,
syntax-local-ID, Nat lookup, and structural-call validation blockers.

Do not reuse unattached candidates `84b456bc` or `4b2f6bdd`: the former duplicates
an already-landed repair, and the latter contains incorrectly escaped regexes.
Old unattached semicolon blobs are also obsolete.

## Exact next action

1. Refresh the branch and inspect changes after the snapshot above.
2. Read the newest `PSC2 minimal kernel` run for the source repair commit.
3. Check the full log tail for both `PSC1_PROJECT_PARSE_FAILED` and
   `PSC1_PROJECT_ELAB_FAILED`; the workflow's summary filter can omit parse errors.
4. Work on the first actual declaration/error only. Observe a focused RED guard,
   normalize that declaration, then run focused/aggregate source gates, Lean,
   and the fixed-point probe. Do not guess later failures or mass-rewrite modules.
5. Verify exact transported blob hashes, review the candidate patch, refresh the
   shared ref, and only then perform a non-forced update.
6. Update this handoff with actual results after meaningful changes.

## Commands and environment

```sh
cd psc15selfhost
node scripts/check-elab-wrap-recursive-hypotheses-selfhost-source-syntax.mjs
npm run check:selfhost-source-syntax
node scripts/check-bootstrap-closure.mjs
lake build Ps.Elab.Declaration
lake exe psc2_minimal_selfhost_tests
npm run fixed-point
```

Scratch checkout: `/workspace/scratch/e40ced7be9b3/pskernel`. The branch is the
durable source of truth. Git CLI reads work; authenticated connector
blob/tree/commit APIs and non-forced `update_ref` are available for writes.

This local environment has no Lean/Lake executable. In the previous environment,
the official binary reported `failed to locate application`; explicit
`LEAN_SYSROOT`/`LAKE_HOME` did not fix it. Use CI for official-Lean/fixed-point
evidence, and do not label an environment failure as compiler RED.
