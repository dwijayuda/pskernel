## 2026-10-24 Constructor helper proof gate fails; proof-body repair

Exact source `be4b47b80fd9c9dd21a28ffe8b15a691bb2c20ec`, run
[`40092935560`](https://github.com/dwijayuda/pskernel/actions/runs/40092935560),
attempt 1, is terminal **FAIL**. Native job `120869170121` passed production
imports, the prior 64 header/structural equations, the unchanged eight metadata
reports and all 17 constructor-parameter equations. The new paged-model and
constructor-result proof commands failed. All four report counts were exact;
their Lean statuses were respectively 0, 1, 0, 1.

The failures are eight paged lookup/append goals whose raw `Nat.div`/`Nat.mod`
terms were not normalized to the notation in the branch hypotheses, and four
result-check goals whose final true/false conditionals were not reduced by
restricted simplification. Lean printed `sorryAx` in ten dependent reports
after these elaboration failures; the native gate rejected the candidate.
No admitted source theorem or failed report is accepted as a proof.

The source-bound native artifact `12560085976` was independently downloaded,
CRC checked and rehashed: 220,279 bytes, SHA256
`e8c81765bda041c488d56fe1ae58f22c0114a9fc98f979417b6f00ca25866225`.
All 57 files and all 43 copied inputs agree with the authenticated Git blobs,
original source inventory and terminal log. The exact 122 attempted reports
and 12 diagnostics are retained in
`docs/evidence/2026-10-24-t05-be4b47b8-native-failure.json`.

The direct native regressions, retained post-proof gates and both complete
routes were **not executed**. GitHub records the dependent matrix as skipped
job `120869585392`; there is no generated or canonical receipt for this source.
Earlier f5 header passes remain attributed only to f5 and its own run.

This follow-up candidate changes only proof bodies in
`PsKernelExprV2PagedModelProofs.lean` and
`PsKernelOrdinaryConstructorResultProofs.lean`: definitional normalization in
the three paged lookup/append proofs and final reflexive reduction in four
result proofs. All 35 theorem statements and 33 ordered axiom-report commands
across those files are preserved. Production source tree
`07d076b38e25d408200607e3d13147ee425437b8`, workflow, fixtures, matrices and
every required count remain unchanged. These repairs are **uncompiled at
commit creation** and require one new exact-source push cohort.

The next native gate still requires all 230 reports, native parameter284 and
result432 assertions, before either full route. Each route still requires
header1992, cache1884, parameter268, result432 and all retained controls, with
actual148-module source closures and source/run/attempt-bound receipts. Keep
Lean4.35.0 commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, TypeScript7.0.2,
Node22, fuel4096, empty PATH, old-space2048MiB and the existing caps. Old-space
is not a hard RSS limit. Do not rerun or combine the rejected be4 cohort.

**T05/B/D remain OPEN; C remains FAIL.** Integration remains at the separately
qualified T01F/scoped A source `0d9f062846d109c362210d441df5fd407ca2cdd7`.
All five full work-branch qualification triggers remain paused. The separate
fields/positivity/replay and decoder drafts remain uncommitted and untested;
they are not part of this repair. Full ordinary admission, recursor checking
and atomic publication remain outstanding.

---

## 2026-10-24 T05 header narrow pass; constructor helpers next

**The ordinary-header narrow candidate passed at exact source
`f5d97bafbd48adde29101ed44f45288ae53b9c87`, run `40089243726`, attempt 1.**
Both route artifacts have been independently verified. Its source tree is `9e85b027cc0f8535efc475b490069f2012fd1435`;
the production tree is `6951c3237eaca9fcc1ec9c173028cb651a6afa0d`.

The native gate checked all **172** ordered, unique, source-named reports:
49 header/state +15 occurrence/annotation +60 scope +14 session +11 scalar
+7 closed-cache +16 Knot. All four direct proof-command statuses were zero;
only the permitted standard axioms appeared. The direct native header,
occurrence, annotation, complete-state, official Lean and retained controls
passed. All 49 native artifact files and 32 copied inputs were independently
verified at artifact `12558173561`.

Both authentic complete routes passed, each with **1,992** direct header
assertions and the retained **1,884** cache assertions, scalar/short-entry
matrices, strict generated-body checks, DAG/owner/prefix, generated smoke and
invalid-recursor controls. The generated route used job `120858822962`, artifact
`12558878274`; the canonical route used job `120858823020`, artifact
`12559537082`. All 223 generated and 226 canonical artifact files,
each route's 32 copied source inputs, actual 146-module Lean closure and archive,
and the canonical 146-module ProofScript closure/manifest were independently
rehashed and source-bound. Exact original provenance and receipt log digests
matched; no source or attempt mixing was used.

The generated header matrix took 3.93 seconds, with 295,972 KiB maximum RSS; its
whole detached runtime step was 197 seconds. The canonical header matrix took
3.29 seconds, with 306,436 KiB maximum
RSS; its whole detached runtime step was 158 seconds.
These are scoped observations, not general speedup or full-admission evidence.
The unchanged pins and limits were Lean 4.35.0 at
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, TypeScript 7.0.2, Node 22, fuel 4096,
empty PATH and 2048 MiB V8 old-space. Old-space is not a hard RSS limit. The
25-minute detached runtime cap and 75-minute route-production job cap remained.

The preceding 60fe source passed native checks but failed both complete PSC1
checks with `structuralRecursionArity`. The qualified f5 source repairs exactly
two branch-local recursive partial applications in `DagOrdinaryOccurrence.lean`
and adds small structural source prechecks before the full source check. All
proof statements and regression inventories were retained. The earlier failure
is preserved separately; no f5 success is attributed to 60fe.

This is a **header-only narrow pass**, with `fullAdmission=false` and
`publicFallbackUsed=false`. The structural equivalence proofs still assume the
explicit ArenaModel; its replay establishment and concrete decoder relation
are separate obligations. Public ordinary admission routing is unchanged.

The following coherent candidate adds private constructor-parameter alignment,
structural constructor-result/occurrence helpers, and native paged-storage
proofs. It requires 50 new reports plus 180 retained reports (**230 total**),
native parameter 284/result 432 assertions, and generated parameter 268/result 432
assertions on each complete route, in addition to the retained header 1992 and
cache 1884 gates. Read `docs/T05_CONSTRUCTOR_HELPERS_HANDOFF_2026-10-24.md` for
the exact scope and workflow. This changed candidate must pass its own one
source/run/attempt cohort; it inherits no f5 receipts.

**T05/B/D remain OPEN; C remains FAIL.** T01F/scoped A remain qualified only at
the original `0d9f062846d109c362210d441df5fd407ca2cdd7` cohort, which remains the
integration HEAD. The separate later integration-push cancellation observation
does not qualify another cohort. All five full work-branch qualification
triggers remain paused; both T01F diagnostics remain manual-only. Full ordinary
constructor/positivity, recursor validation, complete owned admission and atomic
publication still precede final T05 qualification and integration.

---

## 2026-10-24 T05 native gate passes; complete PSC1 production exposes recursion arity

Exact source `60fe91758a897d6f8936b28a257baab0057c52b3`, run
[`40087914982`](https://github.com/dwijayuda/pskernel/actions/runs/40087914982),
attempt 1, is terminal **FAIL**. Native job `120854503808` passed all 172 exact,
ordered theorem reports (64 new, 108 retained), with only permitted standard
axioms, and all six strict header runtime markers. These include the 432-row
header matrix, 10 required direct positives, 171 occurrence heads, 1,026 fuel
cases, 171 wrappers, annotation/state controls and four accepted/two rejected
official Lean controls. All 49 native artifact files and 32 copied source blobs
were independently verified against the exact source; three review records
preserve the raw-log, proof, runtime and artifact reconciliation.

Both generated job `120854945313` and canonical job `120854945372` passed the
retained bounded scalar/cache gates, including 1,884 cache assertions and six
strict generated-body markers. Their independently checked 146-module Lean
closures, 146-member source archives and 32 copied inputs match exact Git blobs;
all 194 files in each artifact were inspected. Both complete PSC1 checks then
failed at `psKernelExprV2OrdinaryUniformParamArgs` with
`structuralRecursionArity`. Canonical reconstruction, complete production and
both 1,992-assertion header runtime matrices were not reached. Executed generated
header assertions are **zero** on each route. Native success is not a complete
narrow pass, and this source is not qualified.

The focused correction introduces a partial-self-call `let` inside the original
successful branch in `UniformParamArgs` and the matching surplus-arity call in
`UniformOccurrences`. Inlining each let restores the exact previous expression.
All exported signatures, all 20 occurrence theorem statements and 15 reports,
all state proofs, runtime matrices, original errors/order/fuel and owner rules
remain unchanged. The compiler's actual `psElabRecursionChangedArguments` rule
was inspected at blob `8b1c409244b9669224fc3caff796aea69eac1401`. No compiler
or trust-base change is proposed.

The narrow workflow adds an early PSC1 check of `DagOrdinaryOccurrence.lean`
and `DagOrdinaryAnnotations.lean` after the retained bounded gates and before
the expensive complete closure check. Every previous run block, native172 gate,
generated1992 matrix, pin, resource limit and trigger is preserved. This new
source requires its own single push run; inherit no earlier passes.

Evidence: `docs/evidence/2026-10-24-t05-header-60fe-cohort-failure.json`, the
three `2026-10-24-t05-60fe-native-*.json` reviews, the terminal route observation,
the structural-arity repair record and the structural-precheck static record.
T05/B/D remain OPEN and C remains FAIL. Recorded T01F/scoped A qualification
remains pinned to integrated `0d9f062846d109c362210d441df5fd407ca2cdd7` and its
original exact cohort; later integration-push cancellation observations remain
separate. All five full qualification work triggers remain paused.

The next constructor-parameter/result and paged-model drafts are separate,
uncommitted and unexecuted: 50 new proof reports plus eight retained metadata
reports are planned alongside the current172; native parameter/result matrices
are 284/432, and generated parameter/result matrices are 268/432 per route.
They must not be activated before the current header narrow pass. Their public
ordinary admission routing is unchanged, and the replay-to-ArenaModel bridge,
constructor fields/positivity, recursors and atomic publication remain open.

---

## 2026-10-24 T05 annotation proof: final two branch corrections pending CI

Source `e3666c65701aa64231d9c4c4798f294a91ca10e1`, run
[`40087421025`](https://github.com/dwijayuda/pskernel/actions/runs/40087421025),
attempt 1, passed production compilation and all 49 state/header equations.
The earlier structural correspondence and depth diagnostics are resolved.
Two goals remain in the single `annotation_step` helper: the fallback
`semiOutParam` and `autoParam` name guards. Two of the 15 occurrence/annotation
reports consequently still depend on `sorryAx`; the native gate remains FAIL,
and native runtime, retained audit and generated routes were not reached.

This correction explicitly splits both name Booleans for the one- and
two-argument cases. Every byte outside that helper, all 20 theorem statements,
the six model/helper definitions and all 15 report names are preserved.
Production, test matrices, workflow and resource limits are unchanged.
The correction is untested until its own single push run completes.

Evidence: `docs/evidence/2026-10-24-t05-header-e366-native-failure.json` records
the actual terminal-log/source review; no complete artifact inspection is
claimed for that failed run. The body-only preservation record is
`2026-10-24-t05-e366-annotation-repair-static.json`.

Require the complete 172-report native gate and native/official controls on
the next exact source, then the retained bounded code-generation checks and
both complete routes with 1,884 cache and 1,992 header assertions each. Do not
inherit earlier proof passes. T05/B/D remain OPEN, C remains FAIL, the five
full work qualification triggers remain paused, and the recorded T01F/scoped A
qualification remains pinned to integrated 0d9 with its later follow-up
cancellation observations kept separately. Future constructor/model drafts
remain uncommitted and untested.

---

## 2026-10-24 T05 state proofs pass; structural proof corrections remain untested

Exact source `f24d5a0bf70a1e27feeeb8041f7156da2efdb1a5`, run
[`40086833892`](https://github.com/dwijayuda/pskernel/actions/runs/40086833892),
attempt 1, compiled production and **kernel-checked all 49 state/header
equations**. Independent inspection matched every report to its source and
permitted standard axioms. The workflow correctly ran both new proof modules
and recorded `stateCount=0 stateLean=0 occurrenceCount=0 occurrenceLean=1`.
The overall native gate failed; native runtime, retained audit and generated
routes remained blocked.

The occurrence module produced 35 diagnostics across six proof bodies: a
Boolean guard, reflexive recursive/list match expressions, 24 impossible
zero-fuel branches, annotation argument-list reduction and a maximum-depth
inequality. This candidate repairs those proof bodies only. All 20 theorem
statements, six model/helper definitions and 15 audited report names remain
unchanged. No production implementation, regression, workflow gate, resource
limit or model assumption changes. The repairs still require their own Actions
run; the previously failing module and its nine reports depending on `sorryAx`
are not counted as qualified proofs.

The corrected archive is complete for its stated inventory: all 40 files were
inspected and all 32 copied source files matched their exact Git blobs, including
the previously omitted copied workflow. Evidence is in
`docs/evidence/2026-10-24-t05-header-f24d-native-failure.json` and the independent
`2026-10-24-t05-f24-state-native.json`; the focused repair preservation record is
`2026-10-24-t05-f24d-occurrence-repair-static.json`.

Follow one new source-bound push run. Require all 64 new plus 108 retained
native reports, the official/native controls, strict bounded generation and
1,884 cache assertions, then exactly 1,992 direct header assertions on each
complete authentic route. Do not transfer the 49 passing reports from f24d to
the next source or weaken the structural-model boundary. All five full work
qualification triggers remain paused. T05/B/D remain OPEN and C remains FAIL;
the recorded T01F/scoped A qualification is only at integrated 0d9, with its
separate later cancellation observations preserved below. Future constructor
and paged-model drafts remain separate, uncommitted and untested.

---

## 2026-10-24 T05 first native run failed; proof-body and evidence corrections

Exact source `4439fa78fe7d04acfdc4f9b28c719bb5458daeda`, run
[`40086320399`](https://github.com/dwijayuda/pskernel/actions/runs/40086320399),
attempt 1, compiled the complete native production imports and retained DAG
executable. Native job `120849887166` then failed the new proof gate:
`header_finish_nonsort_error` had redundant tactics after its goal was solved,
and `header_after_sort_composition` left a reflexive match equality unclosed.
The latter printed a `sorryAx` dependency from its unsolved goal, so this source
is explicitly **not proof-qualified**. The occurrence proof file, native
runtime, retained audit and both generated routes were not reached.

The correction changes only those two proof bodies, preserving all 49 theorem
statements and reports. The proof step now collects both independent modules'
results before failing if either failed; native runtime and generated jobs still
require proof success. It also explicitly includes hidden copied source paths
in the two T05 artifacts. Independent inspection verified all 37 files in the
failed native archive and 31 available copied sources against their Git blobs;
the copied `.github` workflow was missing under the previous upload default.
That limitation is recorded, not treated as a complete archive.

This corrective candidate is untested until its own run completes. It changes
no production implementation, public admission routing, proof statement, test
matrix, fuel/resource limit, or retained qualification gate. Require all 64 new
and 108 retained native reports, then the existing strict bounded code-generation
checks/1,884 cache assertions and exactly 1,992 header assertions per authentic
generated route. Follow the new push run once; do not rerun the failed source
or combine attempts.

T01F/scoped A remain qualified only at integrated source
`0d9f062846d109c362210d441df5fd407ca2cdd7`. T05 and B remain OPEN, C remains
FAIL, and D remains OPEN. All five full work-branch qualification triggers
remain paused. Continue the header handoff after resolving actual narrow
failures; the separate paged-model proof draft and constructor recipe are
preparation, not tested or integrated work.

Evidence: `docs/evidence/2026-10-24-t05-header-4439-native-failure.json`.

The later automatic integration-push cohort at the same qualified 0d9 source
is separate: generated run `40067352825` and canonical run `40067352798` ended
cancelled in mixed shard 5 after 1,511 and 1,519 whole-job seconds. Generated
logged its 1,400-assertion PASS and shard receipt immediately before cancellation;
canonical did not log a complete mixed PASS. Both aggregate prerequisite gates
failed and skipped aggregation. The logs say only "The operation was canceled";
they do not establish the cause or actor. These observations do not supply any
part of the original qualifying cohort and establish no repeatability margin.
Research/profile success and Arena failure in that follow-up are API status
observations, not new independently qualified artifact results. See
`docs/evidence/2026-10-24-t01f-post-integration-0d9f0628-observation.json`.

---

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
