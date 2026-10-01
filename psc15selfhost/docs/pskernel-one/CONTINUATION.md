# pskernel-one continuation

Work branch: `psc2/pskernel-one`. Compiler baseline:
`90d02086146fce06df6d0a720e50f340adcbf52a`. The implementation snapshot verified
before the final runtime gate is `5e3ddf9b4d4247fb334c3f0e136b1a191b51ba10`.
Use `git rev-parse HEAD` for the exact final record/test commit, which contains
this file. `EVIDENCE.json` records subsequent exact-head CI results when available.

## RESEARCH VERIFIED

Lean 4.34.0 pin verified against upstream tag and project metadata. Level source
matches the pinned upstream bytes. All initial advertised branch tips fetched;
303 tips in the retained documentation inventory, including the newly created
work branch. A first capability matrix and trust statement are present. Detailed
full-surface source audit is incomplete, so M0 is an initial checkpoint.

## COMMITTED

- `712d7cc7`: isolated Name/Level port and failing semantic regression.
- `37a85650`: bidirectional max-leaf comparison and canonical source gate.
- `89dce790`: separate constant-motive, first-order Nat.rec compiler prerequisite.
- `bc19bbd7`, `564e072d`: runtime, boundary, mutation and tamper harnesses.
- `5e3ddf9b`: name width/Unicode cases, smaller closure, emission diagnostics.

Subsequent test/record commit adds the real full-closure tsc/runtime gate,
canonical-PS Nat fixture parity, minimized function-result blocker and these
research artifacts. No protected branch merge, force-push, release, npm publish,
default cutover or provider replacement was performed. Connector commits were
used because local git had no push credential; staged and remote tree identities
were compared before advancing the branch, with remote-head checks.

## NATIVE / CI VERIFIED

RED: run `36923917657`, job `110576413455`, head `712d7cc7`:
`LEVEL_PARITY: max-reassociation: one=false, lean=true` after the actual native
test compiled. This is the intended semantic failure, not an unavailable tool.

GREEN scoped implementation: run `36926591540`, job `110585326710`, at full SHA
`5e3ddf9b4d4247fb334c3f0e136b1a191b51ba10` completed successfully:

- `lake exe pskernel_one_level_tests`: 13 focused + 144 ordered pairs against C++.
- `node scripts/pskernel-one-mutations.mjs`: two semantic mutants killed;
  restored source retested green.
- `node scripts/pskernel-one-tamper.mjs`: altered source, undeclared import,
  symlink escape and corrupt manifest rejected.
- `lake build psc1`: current compiler built from that checkout.
- `lake exe pskernel_one_nat_boundary_tests`: valid primitive plus four negative
  boundary tests, direct nested recursor emitted.
- `node scripts/pskernel-one-nat-runtime.mjs`: actual TypeScript 5.8.3 and JS,
  134 expected results, including large bigint inputs and depth 10,000.
- `lake exe psc1_backend_ts_tests`, `lake exe psc2_minimal_selfhost_tests`,
  `lake build PsBackendRust PsBackendWasm`: passed.
- `node scripts/pskernel-one-profile.mjs --emit`: handwritten and generated PS
  frontend checks, and actual TypeScript emission, passed.

That green run did **not** yet run full-foundation tsc: the new required gate
exposes the blocker below. Earlier intermediate CI failures (npm workspace
installation, host-fixture layout and anonymous test callback names) are retained
in history and not relabeled as semantic failures or successes.

Local gates also passed: `check-workspace.mjs`, `check-bootstrap-closure.mjs`
(54 compiler-only modules; 14 source-isolation cases use labeled compiler/tsc
doubles), `check-ir-neutrality.mjs`, source/tamper checks, and `git diff --check`.
Local official Lean/Lake could not start (`failed to locate application`), so
native compilation claims are CI claims. A verified CI-built seed was downloaded
for local PSC/tsc reproduction; no native build is inferred from that download.

Seed artifact `11194650381` from run `36926591540`:

- ZIP SHA-256: `6279c34400e14837db401db38b443c87753387becfd188335d4d1db461f38bb6`.
- Executable SHA-256: `f5f5a1a66af9fa42ec7467684e0f349b308503d15dffb09a3eea8be98fb89356`.
- Full diagnostic artifact `11193549174` ZIP SHA-256:
  `ace14cd748aa9c66b8d1c81ea650b724072bd0fc398f110c8d0fea28b8878a8a`.

## GENERATED KERNEL VERIFIED

**Not verified.** The generated Nat primitive regression executes, but that is
not a generated declaration checker. The complete four-module foundation emits
TypeScript, then `tsc --strict --noEmitOnError` rejects it. No runnable full
foundation artifact is admitted despite the emitter succeeding.

Exact minimized blocker: `packages/pskernel-one/test/FunctionResultBlocker.lean`.
With the CI seed at 5e3ddf9b:

```sh
psc1 check packages/pskernel-one/test/FunctionResultBlocker.lean
psc1 typescript packages/pskernel-one/test/FunctionResultBlocker.lean > dist/function-result-blocker.ts
tsc dist/function-result-blocker.ts --target ES2022 --module ES2022 --strict --noEmitOnError
```

The frontend passes six declarations. The emitted `oneTreeEqual(left)` returns a
function, but `oneTreeUse` calls `oneTreeEqual(left, right)`, yielding TS2322 and
TS2554. The full closure has the same mismatch at NameEq, LevelEq and MaxSubset.
Explicit portable wrappers were attempted locally: partial-application erasure
eta-expands them back to the same overapplication. Those ineffective source
changes were removed. Do not change emitted files or suppress tsc errors.

Next step: a separate RED→GREEN compiler change preserving actual runtime arity
and function-return boundaries, with direct/partial/overapplied/returned/nested
function tests and lexical shadowing checks. Alternatively find a supported
portable encoding that preserves semantics and passes the same gate. Re-run the
generated Name/Level semantic corpus before claiming even this foundation runs.

## COMBINED FIXED-POINT VERIFIED

Not reached. No combined profile/manifest or C1/K1→C3/K3 chain is implemented.
The compiler-only baseline independently records 8 of 54 modules parser-blocked
and a tuple construction failure. Those are historical baseline evidence, not a
fresh successful fixed-point run. Generated sources must never fall back to Lean.

## FULL LEAN PROFILE COVERAGE

Incomplete. Four foundation modules: 13,734 source bytes, 381 nonblank
non-line-comment lines. `CAPABILITIES.json` lists missing expression, substitution,
typing, full conversion, inductive/recursor, quotient, literal, admission,
transport, outcome/budget, prelude and integrity work. Complete level comparison
also remains open. M1 through M6 are not complete.

Additional concrete risks: large decimal literals overflowed the earlier
c8b1d9e2 seed during the admission/source check; the Nat runtime width test passes
large values as input and does not close that frontend issue. Anonymous callback
binders exposed duplicate emitted identifiers in a raw host fixture; named test
binders avoid that known compiler hygiene issue. No full replay, memory budget,
resumability or universal semantic proof is claimed. Generated output retains an
inherited 'pskernel-admitted' header; that text is not evidence of kernel admission.

## DEFAULT CUTOVER STATUS

Unchanged. `@proofscript/pskernel-one` is private, `bootstrap:false`, and has no
public admission provider. Original Lean native/Wasm remain external alternatives
and references. Only full required evidence can authorize a future cutover.

At handoff, inspect `git status --short`: tracked implementation, tests and this
ledger are committed. Ignored `dist/pskernel-one/` contains reproducible local
diagnostics; it is not an accepted generation or source of truth. No unattended
work is running or promised.
