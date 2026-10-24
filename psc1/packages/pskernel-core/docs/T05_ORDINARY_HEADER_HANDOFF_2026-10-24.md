# T05 ordinary DAG header — first executable candidate

## Current source and qualification boundary

T01F/scoped A were qualified at
`0d9f062846d109c362210d441df5fd407ca2cdd7` by generated run `40061694631` and
canonical run `40061694623`, both attempt 1, and integrated by an expected-SHA
non-force fast-forward. The documentation/trigger checkpoint is
`1e1fa35d19bc5180eebc3fd19e8638919ec6e06f`. The current T05 candidate is based
on that checkpoint and has not yet passed Actions. Do not inherit T01F passes
as evidence for newly changed source. B OPEN, C FAIL and D OPEN are independent
findings; T05 remains OPEN.

Read the newest work-state and continuation entries first. Fetch both live
work/integration HEADs before writes. Preserve concurrent history and use
expected-SHA, non-force updates. All five full qualification work-branch push
triggers remain paused. The new T05 narrow push workflow is the sole candidate
run; do not manually dispatch a second copy.

## Implemented scope

All production paths here are relative to `src/Ps/KernelCore/`.

| Module | Responsibility |
| --- | --- |
| `API/DagOrdinaryHeaderTypes.lean` | ID binders, complete parameter/index results, and the constructor context/state fork |
| `API/DagOrdinaryOccurrence.lean` | Full application-spine uniform-occurrence guards, offset-sensitive traversal, and ordered constructor scans |
| `API/DagOrdinaryAnnotations.lean` | Exact annotation names and arities, consuming the original domain in its returned owner |
| `API/DagOrdinaryParameters.lean` | Parameter/index opening through complete checker state, mandatory public WHNF, and original fuel boundaries |
| `API/DagOrdinaryHeader.lean` | Original ordinary guard order followed by Check, EnsureSort, parameter opening, index opening and final sort inspection |
| `Checker/ExprV2/AdmissionHelpers.lean` | The two existing EnsureSort declarations moved unchanged from `API/DagAdmission.lean` |

`SelfHost.lean` imports the header module so both authentic complete routes
include the actual worker. `DagAdmission.lean` changes only its shared-helper
import and the removal of those identical moved declarations. No public
ordinary dispatch, fallback, constructor admission, recursor installation or
publication timing changes in this slice.

### Required semantics

The ordinary guards run in the original order: duplicate universe parameters;
duplicate inductive/recursor/constructor names; freshness; uniform occurrences
in constructor types; header metavariable/free-variable guards; undefined
universe parameters. Do not substitute a generic header helper with a different
order. Check and mandatory public EnsureSort precede opening the original header
ID, using the complete returned owner.

Uniform traversal revisits shared IDs at each binder offset. It checks complete
application spines, preserves short circuit order and exact diagnostics, and
uses canonical structural depth independently of checker fuel. Annotation
consumption recognizes only the original four exact names and arities; it does
not strip metadata or silently normalize the original domain.

Parameters retain original fuel, including terminal WHNF. Index traversal
checks zero fuel before lookup/callbacks and supplies predecessor fuel at each
step. `psKernelExprV2CheckOpenBinder` returns its post-opening owner in a field
named `parent`; thread that owner, including every semantic cache, declaration
reference and freshness field.

Indices start from the complete parameter owner. Later constructor analysis
uses parameter context/state and only takes the appended arena from the index
owner. `CheckStateExitLocalScope` is not an equivalent replacement for this
intentional fork because it takes maximum freshness. Do not leak index locals
or caches into constructor checking.

## Proof and test gates

`psc1/test/PsKernelOrdinaryOccurrenceProofs.lean` contains 15 audited theorem
reports. They relate the actual ID-native workers to the retained V1 operations,
including arbitrary structural fuel, full spine/argument correspondence and
depth-budget adequacy. Their explicit `ArenaModel` assumes exact node decoding,
valid children and sound depth metadata. It does not assume an occurrence or
annotation result. **The theorem establishing this model from successful
whole-arena replay validation is still missing.** Do not describe these scripts
as whole-boundary soundness proofs.

`psc1/test/PsKernelOrdinaryHeaderStateProofs.lean` contains 49 audited theorem
reports. They quantify over arbitrary callbacks, owners and IDs and cover
state propagation, declines/errors, mandatory WHNF, fuel, allocation, the
constructor fork, original guards and fresh-owner initialization. No new axiom,
`sorry`, `admit`, `native_decide`, compiler trust or reduced-Boolean trust is
permitted. All 64 reported theorems and their helper lemmas require actual Lean kernel checking in Actions.

`psc1/test/PsKernelOrdinaryHeaderRegression.lean` runs the native direct-worker
differential, state/order sentinels and four accepted/two rejected official
Lean controls. Its frozen header oracle follows the V1 prefix at exact 0d9,
stopping before provisional metadata. Relevant native markers are strict and
must all appear; a header PASS explicitly says `fullAdmission=false`.

`psc1/scripts/pskernel-ordinary-header-smoke.mjs` requires exactly 1,992
assertions on each independently produced complete route:

| Section | Assertions |
| --- | ---: |
| Constructor-tag harness control | 1 |
| Header differential and positive direct analysis | 444 |
| Uniform occurrences | 1,378 |
| Annotation consumption | 94 |
| Complete state, fuel and fork | 47 |
| Header phases | 20 |
| Top-level callbacks and guards | 8 |
| Total per route | 1,992 |

The oracle uses retained V1 helpers, not the new DAG workers. Successful rows
must return the direct worker's `some (ok ...)`; public fallback cannot satisfy
them. Tests compare binder names/info/types, decoded results, levels, freshness
and exact errors. They include shared IDs at different offsets, missing/excess
levels, reversed parameters, cross-fault guard order, callback changes to all
state fields and appended IDs, original annotated domains, metadata retention,
and late callback failure/decline.

The native-first workflow must reject failures before expensive complete builds.
Retain the existing 1,884 cache assertions and strict bounded generated-body
checks. Build both the integration compiler route and the independently
reconstructed canonical `.ps` route at one source. Record exact source, run,
attempt, native reports, runtime counts and artifact hashes; inspect the actual
logs and bytes, not just green workflow badges.

All project builds, Lean/compiler/JavaScript/kernel execution and tests run only
on GitHub Actions Linux. Preserve Lean 4.35.0 commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, TypeScript 7.0.2, Node 22, fuel 4096,
old-space 2048 MiB and detached runtime execution with empty PATH. Old-space is
not a hard RSS limit. Retained final mixed/shard caps stay 25 minutes and final
route parallelism stays 2.

## After the header slice

Fix actual narrow failures in coherent new candidates. Do not rerun a failed
source merely to obtain green results, edit original controls away, combine
different source/attempt receipts, or activate all five expensive final routes
for every infrastructure iteration.

After a complete narrow pass, continue the ordinary constructor path:
parameter equality, strict positivity, recursive-argument and index checks,
field universe bounds and exact owner/scope handling. Then port elimination/K
policy and construct motive/minor/IH/recursor types and rules over owned IDs.
Validate generated type/rules before private atomic publication. Preserve
independent closed constructor owners and original rule-session sharing.

The current environment-only direct admission result cannot return the private
generated arena and references. Complete T05 therefore needs an owned result
and the corresponding internal command-state propagation. External commands
must still refer only to the original input arena; appended IDs remain private.
A late constructor/rule/import failure must publish no partial declaration,
reference, session or reply. Keep public fallback until the complete replacement
has qualified. Mutual/nested migration and global fallback removal are later
completion-plan work.

Final T05 acceptance requires the actual complete direct ordinary path, native
official controls, both authentic generated routes, original negatives/provider/
owner gates and all retained qualification gates at one exact source/attempt.
Do not promote this header-only candidate as full ordinary admission.
