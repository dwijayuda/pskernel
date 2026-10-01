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

Base for this repair: `ec91470f31e53c2ebd7c6d529853b5f3d5ea731a`.
This is the observed parent, not the commit containing this document.

Completed full run `36845211567`, job `110313599959`, passed source guards and
Lean compilation, and confirmed the prior three-call inductive-constructor
repair. Its fixed-point probe then stopped at:

```text
PSC1_PROJECT_ELAB_FAILED: packages/elab/src/Ps/Elab/Declaration.lean: declaration=psElabInductiveConstructors: matchPatternUnsupported
```

The declaration matched index, source list, and accumulated declarations in a
multi-argument equation. It also varied index/accumulator during recursion and
called generic reverse. The active normalization keeps its public curried type
and behavior, using:

- A source-list structural worker with context, parameter binders, and inductive
  name invariant. Its result accepts index and the declaration accumulator.
- A local declaration reverse helper, preserving the semantics of nonempty
  initial accumulators as well as normal empty-accumulator calls.
- A thin wrapper preserving the original argument order.
- A focused source guard imported directly by the closure source gate.
- A runtime regression in `MinimalSelfHostTests.lean` checking starting index 7,
  constructor order, a two-declaration accumulated prefix, empty input, and
  propagation of an invalid constructor-name error.

## Current repair verification

- Focused source guard observed RED before the production rewrite.
- Focused and aggregate source gates: GREEN after the rewrite.
- Local bootstrap closure: GREEN, 54 modules/12 packages/one direct root import.
- `git diff --check`: GREEN.
- Native runtime regression, official Lean build, and fixed-point CI are pending.
  Do not claim the new runtime test passed until its CI output is observed.
- No Compiler2/3/4 or parity/fingerprint success is claimed.

## Confirmed progress in this Work session

| Repair | Landed commit | Subsequent compiler evidence |
| --- | --- | --- |
| Term elaborator fuel-only recursion returning a callback | Concurrent `e3ae2d21` | Run `36813544281` advanced beyond Term.lean |
| Typed-binder reverse in structural-recursion discovery | `eb75a18d` | Run `36813972553` advanced to constructor-name selection |
| Explicit PsName type for constructor-name local match | `4eea0276` | Run `36814537484` advanced to binder arguments |
| Explicit binder-to-expression mapping after typed reversal | Concurrent `3065721e` | Later runs advanced beyond binder arguments |
| Typed field reversal and parameter/field counts in inductive constructors | `ec91470f` | Run `36845211567` advanced to constructor-list traversal |

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
node scripts/check-elab-inductive-constructors-selfhost-source-syntax.mjs
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
