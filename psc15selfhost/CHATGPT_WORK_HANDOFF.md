# ChatGPT Work Handoff

Updated: 2026-10-01 (Asia/Jakarta). Continuation of the Work session started
from `Pasted text(20260930-195252).txt`.

## Scope and shared branch

- Repository: `dwijayuda/pskernel`.
- Target branch: `psc2/minimal-selfhost-psc15`. Do not merge to main.
- Write only `psc15selfhost/`. Do not change `psc2selfhost/` or `.github/`.
- PSC1-compatible `.lean`; official Lean 4.34.0 bootstrap; TS/JS generation 1.
- Keep the target-neutral semantic/IR boundary and the distinction between
  AdmissionReadyModule and kernel-backed CheckedCore. Rust/Wasm and kernel
  provider integration remain outside the first fixed-point closure.
- Never weaken structural-recursion safety or expand the bootstrap language.
- Another session writes this branch. Refresh before every ref update, inspect
  intervening changes, preserve concurrent guards, and never force-push.

## Confirmed term recursion repair

Verified source snapshot: `e3ae2d211af4701d9dcbf0088dde777e54ec6b5d`.
This is the source repair commit, not the commit containing this document.

Latest completed compiler evidence before this repair:
[run 36791293062](https://github.com/dwijayuda/pskernel/actions/runs/36791293062),
job `110144548718`, commit `76ebc69dc73342e39e19e9dd0c5b2ef39e9aafbe`.
Boundary/Name/Level/Expr parity, full source syntax, and the Lean elaborator
build passed. `Bootstrap closure remains isolated` ran the nested fixed-point
probe and failed with:

```text
PSC1_PROJECT_ELAB_FAILED: packages/elab/src/Ps/Elab/Term.lean: declaration=psElabTermWithFuel: structuralRecursionArity
```

Root cause: the declaration had four explicit parameters, while its recursive
callbacks supplied only `remaining`. PSC1 checks recursive calls against the
number of declared parameters. Its supported pattern recurses over fuel to
produce a function, then supplies the varying state to that result.

This repair keeps only `fuel` as the declared parameter of
`psElabTermWithFuel`. Both branches return a function of context, term, and
expected type. The successor branch binds a typed `smaller` callback from the
single recursive call, then uses it at the eight callback sites and the direct
application-head elaboration site. The public curried type, fuel exhaustion,
and term dispatch behavior are preserved. No other declaration is changed.

Concurrent commit `89164ee0` added the matching recursion guard. It was adopted
without modification; this session's duplicate guard was discarded. Concurrent
repair `e3ae2d21` then landed exactly the tested source: its Term.lean blob SHA
`566e0281c95eb7e47a35878c906ae4344f97eb0f` matches the local candidate. No duplicate
source commit was created. One-shot run `36813480889` passed, including the
Lean build, before committing the repair and removing its temporary workflow.

## Verification of this repair

- The concurrent focused guard was observed RED on the unchanged source,
  reporting the missing fuel-only declaration signature.
- The focused guard is GREEN on the repair.
- `npm run check:selfhost-source-syntax`: GREEN.
- `node scripts/check-bootstrap-closure.mjs`: GREEN locally; 54 ordered modules,
  12 allowed packages, one direct root import. A local pass does not run the
  CI-only nested fixed-point probe.
- `git diff --check`: GREEN.
- Official Lean build: GREEN in one-shot run `36813480889`.
- Full fixed-point run `36813544281`, job `110213588016`, passed all source
  guards and Lean compilation, then advanced beyond Term.lean to the new
  Declaration.lean blocker below. No Compiler2/3/4 or fingerprint success is claimed.

## Confirmed binder order repair

Completed full run `36813544281` at `e3ae2d21`, job `110213588016`, establishes:

```text
PSC1_PROJECT_ELAB_FAILED: packages/elab/src/Ps/Elab/Declaration.lean: declaration=psElabStructuralRecursionFromSource: unsupportedTerm
```

The declaration uses `bindersRev.reverse`. PSC1 treats this dotted reference as a
projection, but generic List.reverse is outside the bootstrap environment. The
existing `psElabTypedBinderListReverse` helper in Term.lean is already compatible
and preserves source-order binders.

Commit `eb75a18d7b9e61af1fc03e29337705717babed7f` replaces only that expression with
`psElabTypedBinderListReverse bindersRev`, still passed to
`psElabExplicitParameterIds`. It adds
`check-elab-structural-recursion-source-selfhost-source-syntax.mjs` and imports it
from the direct source gate so both the aggregate and closure paths run it.
The guard requires reversal before ID extraction and forbids generic reverse
in this one declaration.

- Focused source guard: RED on the prior expression, GREEN on the replacement.
- Aggregate source gate and local bootstrap closure check: GREEN.
- `git diff --check`: GREEN.
- CI run `36813972553`, job `110214900503`, passed source guards and Lean
  compilation, then advanced to the constructor-name match below.

## Current first blocker and active repair

Completed full run `36813972553` at `eb75a18d`, job `110214900503`, establishes:

```text
PSC1_PROJECT_ELAB_FAILED: packages/elab/src/Ps/Elab/Declaration.lean: declaration=psElabInductiveConstructorNames: matchExpectedType
```

The active source repair adds `: PsName` to `let currentName := match ...` in
that declaration. PSC1 needs the expected result type to elaborate this local
match. The new `check-elab-inductive-constructor-names-selfhost-source-syntax.mjs`
is imported by the direct source gate. It was RED before the annotation and
GREEN afterward.

Concurrent commits `6803b377`, `b8ba8ce1`, and `b818702b` added a second binder
reverse guard and a one-shot repair for the already resolved previous blocker.
That guard expected a new helper named `psElabReverseTypedBindersAcc`, so it
failed on the existing implementation. This session reproduced the failure and
prepared a guard alignment. Concurrent `8866690e` landed the equivalent guard
alignment first; this session discarded its duplicate. `2515d1e8` removed the
failed one-shot workflow. Preserve both commits. The helper implementation is
also guarded by the existing lambda source gate.

Base for the constructor-name annotation:
`2515d1e8d46787697d1a30858d8df516bae1dfe8`.
Focused guards, aggregate source gate, local closure check, and diff whitespace
check all pass. Official Lean/fixed-point CI for this repair is pending.

## Previously resolved blockers

The prior handoff was stale. Concurrent commits after `1c1e753a` resolved the
record-candidate semicolon, unique-candidate Option constructors, typed record
candidate selection, syntax-local-ID Option constructors, Nat-list lookup
recursion, structural-call validation recursion, structural-self-call Option
constructors, and term-with-fuel Option constructors. These are all present
in the base snapshot; do not repeat those repairs.

Earlier fixes from this Work session remain present:

- `967723ea`: apply-args callback type regression guard.
- `469e04c6`, `3a02d872`, `c2f76805`: record order/candidate Option qualifications.
- `f0e6ef6d`, `17095628`: record candidate traversal/recursion normalization.
- `3c1318bc`: removal of an accidentally duplicated transported guard.
- Concurrent `545d19b6` supplied the previously pending record-candidate
  semicolon. The old unattached semicolon blobs are obsolete.

Do not reuse unattached candidates `84b456bc` or `4b2f6bdd`. The former duplicates
an already landed repair; the latter contains incorrectly escaped guard regexes.

## Exact next action

1. Refresh the branch and inspect any changes after this document's parent.
2. Read the newest `PSC2 minimal kernel` run for the source repair commit.
3. If it fails, read the complete log tail. The workflow summary filter can omit
   `PSC1_PROJECT_PARSE_FAILED`; check both parse and elaboration failures.
4. Work on the first actual declaration/error only. Add a narrow RED regression
   guard, make the minimal compatible change, then run the focused and aggregate
   source gates, Lean build, and fixed-point probe.
5. Review the exact candidate patch and verify transported blob hashes before a
   non-forced ref update. Never replace a remote guard with a stale local file.
6. Update this handoff after meaningful changes and with actual CI results.

## Commands and execution notes

```sh
cd psc15selfhost
node scripts/check-elab-term-with-fuel-selfhost-source-syntax.mjs
npm run check:selfhost-source-syntax
node scripts/check-bootstrap-closure.mjs
lake build Ps.Elab.Term
npm run fixed-point
```

The scratch checkout was recreated at
`/workspace/scratch/e40ced7be9b3/pskernel`. It is disposable; use the branch as
the durable source of truth. Git CLI reads work; authenticated GitHub connector
blob/tree/commit APIs with non-forced `update_ref` are available for writes.

This refreshed local environment has no Lean/Lake executable. In the previous
local environment the official binary reported `failed to locate application`;
setting `LEAN_SYSROOT`/`LAKE_HOME` did not resolve it. Use CI for official-Lean and
fixed-point evidence, and do not label an environment failure as compiler RED.
