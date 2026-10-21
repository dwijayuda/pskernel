# PSKernel-Core Expression V2 integration work state

Date: 2026-10-21 (Asia/Jakarta; Actions timestamps use UTC)
Status: **IN PROGRESS — independent developer kernel; complete V2 and Arena gates remain open**
Integration branch: `integration/psc1-pskernel-expr-v2-lean435-20261021`
Lean: `leanprover/lean4:v4.35.0`, exact commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`
Generated path: authentic PSC1 → TypeScript `7.0.2` → Node `22`. Full-kernel DirectJS is unsupported.
Default kernel fuel: **4096**, unchanged. No new runtime axiom or trusted reduction path.




## 2026-10-21 12:27 UTC — exact theorem mismatch and independent native failure evidence

At staged `641ad59c3b1bbf701b0c28d4da92386096e5e65f`, native integration
[job119217022513](https://github.com/dwijayuda/pskernel/actions/runs/39598591779/job/119217022513)
passes the repaired mixed-constructor comparisons and the preceding native,
official, admission and mutual280 gates, then fails
`theorem-selected-path-unsupported-proof-comparison`. This is the remaining old
decline fixture found by source review: distinct admitted propositions now reach
the terminal false decision, so direct theorem admission must return the exact
`theorem proof type mismatch` rejection. Both runtimes now require direct decisions
for this case in all14 existing fuel/depth rows, compare exact V1 results, and
retain the full224-case theorem matrix, same-batch/error/environment checks.

The native integration workflow now gives its compile step an explicit ID and
runs each independent test/proof/provider/performance gate when that build
succeeded and the run was not cancelled. A failed step still fails the job.
There is no `continue-on-error`, assertion removal or resource-limit change.
This exposes focused-suite failures in the same run instead of hiding all later
gates behind the first obsolete main-suite assertion. Build failure or cancellation
still prevents those gates; the generated job and artifact handling are unchanged.

Integration `88924063a5d9761f52a130c6a581cac6901ad407` has terminal PASS for both
native119205679872 and generated119205679479 in
[39595204321](https://github.com/dwijayuda/pskernel/actions/runs/39595204321), all six
research jobs39595203930, and native correctness119205678982. Canonical job119205679172
was still completing at inspection; full Arena39595203857 was running all193 cases.
Generated artifact12344847028 ZIP SHA256
`cbf433ace671102ee86226243818dd79f35f21fc6addd2aef48219b1676520e0`.
Native artifact12343257329 ZIP SHA256
`a4db9ab6bae642fb8ae217ba2be17e0781683d8c68ff29846ba993dd4b837151`.
No new V2 replacement or Arena completion claim is implied.

The full carrier candidate is preserved, unrun and unpromoted, at
`136ee37d82d2896e278f3e2a8856b2dcb0b2d449`; merge it only with these newer
theorem-fixture and native feedback changes retained. All semantic qualification
must identify the exact executed source revision.

## 2026-10-21 12:20 UTC — require completed terminal DefEq results in existing fixtures

Exact staged source `44bdbea5c4db451ee2ee4aafba963eea5f50d7a7` built all 365 native
tasks, then job [119212233502](https://github.com/dwijayuda/pskernel/actions/runs/39597167334/job/119212233502)
failed `quick-defeq-prefix-selected-path-mixed-constructors`. The newly integrated
terminal unit-like rule returns `some (ok false)` for Sort 0 versus Nat literal 0;
the old selected-path fixture expected outer `none`. Source review of V1 and DAG
confirms the left inferred sort short-circuits the unit-like rule before right
inference. Unequal binder-spine lengths have the same obsolete decline assertion.
This is a fixture expectation repair, not a production semantic change.

Native and generated existing suites now require the exact false result for these
cases, retain the exact unknown-constant result, and add 49 raw V1 comparisons per
runtime across the existing fuel/depth matrix (21 mixed-constructor, 28 binder).
All public/adversarial/official assertions are retained. Actual parity remains
unqualified until the new exact-source runs finish. The 44bdbea native correctness
job119212232752 passed; its generated/canonical jobs were still running at review.

Complete CheckState carrier source and 42/56/540 + 38/44 native/generated regression
matrices are preserved separately at review commit `43ac7506b5fe9442a3baa7b21e2cd733938caffe`.
Ten local carrier lemmas are included there. These are NOT RUN and unpromoted;
they must be overlaid on the fresh staged source, preserving all intervening fixes.
The attempted review-tree creation with a mistyped tree ID returned HTTP422 and
made no change; the corrected reviewed tree/commit succeeded. No local execution.

## 2026-10-21 12:07 UTC — complete the Quot fixture reserved-name repair

At0a69caf03e1ce0510349bdff2a0bf4a5eb771fbb native correctness119209641500
passes, while native integration119209641151 finds the next fixture parser error:
QuotRegression.lean:205 uses reserved `public` as a let-bound result. The two
code occurrences become `publicResult`. An additional source-text audit found
no remaining let binders in the tested reserved-name set across the prepared
FinalRules, Quot, recursor, guard and owned-state native tests. This audit is
not a substitute for their compilation. Production source and every comparison
or assertion remain unchanged. All fresh generated/canonical gates remain required.

## 2026-10-21 12:01 UTC — Quot native fixture identifier correction

Staged369bee5801bd5e4476837684fad3f7e1ca8c422c native correctness119207666740
is terminal PASS. Native integration119207666292 fails while compiling the Quot
regression: `let universe` uses a Lean reserved keyword. Four code occurrences
are renamed `universeName`; no test assertion, expression, matrix count or
production implementation changes. FinalRules, guard and recursor regression
targets compiled, but aggregate build failure prevented their execution.
Complete portable and generated/canonical gates remain unqualified at inspection.

The previous staged-recursion and FinalRules reserved-name corrections remain.
This fixture correction needs fresh exact-source native and generated gates.
Full-state carrier drafts3b1db65 and their tests remain separate unpromoted work.

## 2026-10-21 11:57 UTC — preserve staged recursion arity in DAG guard source

Generated integration119204677598 at staged236766f86a2693faffebd3632b42ef5dabe96f36
failed authentic PSC1 with `structuralRecursionArity` in
`psKernelExprV2AdmissionSeenBucket`. This is a portable-source calling-shape
defect before generated checking. Its one declared fuel argument returns the
remaining curried parameters; recursive source calls must respect that stage.

This correction binds the recursive fuel stage first in SeenBucket and SeenSet,
then applies the returned worker to the same remaining arguments. ScanWithFuel
uses the same fuel-stage alias and an explicitly typed child callback. The
recursive bounds, validated metadata, exact-ID collision checks, cache insertion
order, universe/error precedence and runtime policy are unchanged. All18 local
proof statements and the420/12/672/8 guard matrices are retained verbatim.
The preceding a2b5ff4 reserved-name correction remains present. Fresh native,
complete portable, canonical and generated gates are required.

## 2026-10-21 11:53 UTC — reserved-name syntax correction before staged runtime qualification

Exact staged source236766f86a2693faffebd3632b42ef5dabe96f36 failed native
integration119204677954 and native correctness119204677634 in
DefEq/FinalRules.lean:152:33, `unexpected token '=>'; expected term`.
The binding name `matches` conflicts with Lean syntax. This correction names it
`isStringOfList` and also gives the local constructor result the unambiguous
name `builtConstructor`. Evaluation order, callbacks, decisions and all test
assertions are unchanged. Portable/generated jobs have not qualified this source.

The canonical job at integration5544 completed the whole .ps source check but
hit its40-minute job wall ceiling during JS generation (119150176408 CANCELLED).
This staged correction adopts the same75-minute build-only ceiling as integration
successor88924063a5d9761f52a130c6a581cac6901ad407. No kernel fuel/depth,
Arena60-second/2GiB limit, assertion or compiler/toolchain pin changes.

Integration8892406 carries only the workflow correction and receipt; its fresh
four workflows39595204321/39595204029/39595203930/39595203857 are IN PROGRESS.
5544 has terminal native/.lean-generated integration PASS and all six research
jobs PASS, but remains unqualified for canonical execution. Its full Arena
39578569599 is terminal FAIL qualification:193=170 matching outcomes+2 separate
safety agreements+20 host timeouts+1 unsupported. Exact per-case classifications
are unchanged from480; FullShape has no demonstrated full-corpus outcome gain.

This correction requires its own fresh native, portable, canonical and generated
results. The integration branch does not acquire this staged architectural draft.
A is still qualified only for the last complete scoped developer source480;
B/C and the four whole-operation fallback sites remain open.

## 2026-10-21 09:56 UTC — isolated qualification of the remaining prepared DAG slices

This source is on `research/psc1-pskernel-v2-staged-20261021`, separately from the
active integration branch at `5544bf8feffd8b6cb2aa9b9be7fe27002d8ea8a8`.
The integration ref is not advanced by this staging run. At inspection,5544
native integration119150176593 and native correctness119150175889 are terminal
PASS, as are all six research jobs in39578569496. Complete authentic .lean
source checking passed in generated integration119150176854; its runtime and
canonical portability119150176408 remain IN PROGRESS. Full Arena39578569599
has a passing official job and an IN PROGRESS generated comparison.

The staged source is the reviewed combined draft2f804ec66bea21d969832c34aa093a2a1f7347f0,
which descends from5544. It contains four prepared slices and their full native,
official, detached generated-.lean and canonical-.ps regression gates:

- Terminal DefEq: matching projections with their own node-count budget and
  fixed owning callback; structure eta, string expansion and unit-like rules,
  preserving ordered refusal/error behavior and original success-pair publication.
  Gates:648 owner,216 final-rule,175 projection,144 string-build and32 string-stage
  comparisons;21 official valid,5 invalid,8 string and1 resource fixtures.
- DAG admission guards: validated-arena traversal with exact scope membership,
  unchanged MVar/universe-before-FVar-before-undefined precedence and zero-before-memo
  guards. Gates:420 static,12 shared-depth hostile,672 public and8 official
  comparisons, plus18 local/conditional proof statements.
- Quot: original public/core/reducer fuel ownership, initialized-environment guard,
  exact constructor shape and callback placement. Gates:240 public,480 core,
  720 owner,60 reducer comparisons,10 official valid and5 invalid fixtures.
- Non-K ordinary recursors: only already-checked inductive metadata supplies
  recursor types/rules. Private appended nodes cannot legalize original invalid
  command IDs; atomic publication and original-root decoding are retained.
  Gates:252 public,504 core,720 owner,72 reducer comparisons,9 private-ID
  sentinels,12 official valid,4 invalid,3 checked-addDecl fixtures and14 local proofs.

The workflows add this isolated branch to the existing native/generated,
correctness/canonical, research and complete193-case Arena triggers. No test,
assertion, toolchain pin, fuel/depth policy or host limit is removed or relaxed.

| Exact source | Native | Portable .lean | Canonical .ps | Generated JS | Local proofs | Benchmark | Arena | Provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 480d875d5be7a9e656e7ccd1fa76cc7409a81c90 | PASS | PASS | PASS | PASS | PASS | PASS selected | FAIL qualification | PASS scoped |
| 5544bf8feffd8b6cb2aa9b9be7fe27002d8ea8a8 | PASS | PASS complete check | IN PROGRESS | IN PROGRESS | PASS native | PASS native / JS pending | IN PROGRESS | PASS native / JS pending |
| This isolated staged source | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

A remains qualified only at the last fully tested scoped developer source480.
B/C are not achieved. Four whole-operation fallback sites remain, with V1 still
the public provider/default. General K/structure-major/String-projection and
unsupported inductive ownership still decline. Original validated input decoding,
checked V1 inductive admission and recursive import of checked generated metadata
remain acknowledged transitional paths. No global soundness proof is claimed.
The latest completed Arena remains480:193=170 matching outcomes (103accepted,
59kernel rejections,1metadata rejection,7transport rejections)+2 separate safety
agreements+20host timeouts+1 unsupported nested-recursion case. No totals are
inherited by this staged source.

Separate full-CheckState carrier drafte04a33a138baee694360a2b115fe25403ba4b920
contains only three central modules and is intentionally incomplete. It is NOT
part of this staging source or any qualification claim. It requires the owned
dependencies, old-ABI compatibility adapters, consumer wiring and state-preservation
tests before execution.

Next executable action: inspect all four exact-source staging workflows, fix
concrete failures without weakening assertions, and keep integration at5544
until its current generated/canonical gates and the proposed successor gates
are terminal. Any later integration promotion must use a fresh expected-SHA
non-force update and record exact tested source identities.

## 2026-10-21 09:38 UTC — native FullShape green; portable Bool negation correction

Exact source `b0792ba778e92cd2067379e28c4fb72b7d0105d3` passes native integration
[39577239482/119145700283](https://github.com/dwijayuda/pskernel/actions/runs/39577239482/job/119145700283)
and native correctness
[39577239516/119145700438](https://github.com/dwijayuda/pskernel/actions/runs/39577239516/job/119145700438).
The full-shape342-stage/108-owner matrix and six official positive/one invalid
fixtures pass. Restored mutual, prior DefEq/inference, proof, benchmark and native
provider gates pass in the same terminal native job. Native provider24 detached
empty-PATH cases and the five official provider fixtures pass.
Native artifact12335355462 ZIP SHA-256:
`7ed58be095b3aeda82d6ed2129c56d85fd912651cbe40259358e861b698357a1`.

Generated integration
[119145700873](https://github.com/dwijayuda/pskernel/actions/runs/39577239482/job/119145700873)
and canonical portability
[119145700871](https://github.com/dwijayuda/pskernel/actions/runs/39577239516/job/119145700871)
both fail authentic PSC1 with `unsupportedTerm` in
`psKernelExprV2DefEqResidualAfterFullWhnfWith`. Five research jobs pass;
generated research119145701079 fails the same source gate. This is a
source-language portability defect, not a completed JS qualification.

PSC1's portable prelude defines Bool and its constructors, but not the qualified
`Bool.not` constant used here. Its reference resolver treats the absent qualified
name as a projection from Bool; the type is a Sort, producing `unsupportedTerm`.
The correction expands this one negation into an explicit Bool conditional.
The existing afterChanged callback, arities, evaluation order, skipped right-side
equality check, recursive budgets and failure precedence are unchanged.

| Exact source | Native | Portable .lean | Canonical .ps | Generated JS | Local proofs | Benchmark | Arena | Provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `b0792ba778e92cd2067379e28c4fb72b7d0105d3` | PASS | FAIL | NOT RUN after source failure | NOT RUN after source failure | PASS native | PASS native / JS NOT RUN | IN PROGRESS | PASS native / JS NOT RUN |
| This Bool conditional correction | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

The last fully qualified scoped developer source remains480, with its previously
recorded193-case failure totals (170 matches,2 safety agreements,20 timeouts,
1 unsupported). No successor has inherited480 qualification. B/C remain open;
four public whole-operation fallback sites remain. Prepared terminal DefEq,
static guards, Quot and non-K recursor drafts are not promoted in this change.

Independent diagnostic harness
`bd827814c02daf1d0ea27a8486bb87b77edd03e2` builds pinned480 in
[39578237566](https://github.com/dwijayuda/pskernel/actions/runs/39578237566).
It records first observed V2 declines and actual V1 fallback separately, with
strict source/ABI/control checks and unchanged resources; this run is IN PROGRESS
and is diagnostic only. Its work-state heading09:42 was a transcription time
error; the harness was committed before this entry. Source identities and GitHub
timestamps are authoritative.

Next executable action: inspect fresh native, complete portable-source,
canonical-.ps and both generated-runtime gates to terminal status. Promote the
reviewed terminal-rule slice only after this corrected checkpoint is green.


## 2026-10-21 09:30 UTC — FullShape trace fixture ownership correction

Exact source `6ebcb77c2a3d7cd66ddda23f045c8c7e648534e1` failed native integration
[39575984078/119141497670](https://github.com/dwijayuda/pskernel/actions/runs/39575984078/job/119141497670)
at `app-left-to-right-and-no-extra-depth`. The preceding342 stage comparisons,
108 owner comparisons and prior proof-irrelevance/Nat/lazy-delta matrices had
completed before this sentinel. Native correctness
[39575984298/119141498521](https://github.com/dwijayuda/pskernel/actions/runs/39575984298/job/119141498521)
passed. Five of six research jobs passed when inspected; generated integration,
canonical portability, generated research, diagnostics and full Arena were
still IN PROGRESS. These are partial results, not a qualified successor.

The failing native fixture recursively imported the application, then separately
imported its head and arguments. The append-only builder gives these structurally
equal expressions different IDs. Its callback incorrectly expected the second
imports' IDs inside the first application. This commit constructs that application
with two smart-constructor calls from the exact retained head/argument IDs.
The identity, left-to-right order, no-extra-depth and nextFresh assertions remain
unchanged. The generated fixture already constructed this shared shape and needs
no correction. No checker source, fuel policy, callback or assertion was weakened.

| Exact source | Native integration | Native correctness | Portable source / canonical / JS | Proof / benchmark / provider | Arena |
| --- | --- | --- | --- | --- | --- |
| `6ebcb77c2a3d7cd66ddda23f045c8c7e648534e1` | FAIL fixture | PASS | IN PROGRESS at inspection | NOT fully run | IN PROGRESS |
| This fixture correction | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |
| `480d875d5be7a9e656e7ccd1fa76cc7409a81c90` | PASS | PASS | PASS | PASS within recorded scope | FAIL qualification |

The480 scoped developer provider remains the last fully qualified checkpoint.
B/C remain open: four public whole-operation fallbacks;20 host timeouts and one
unsupported nested-recursion case in the latest completed193-case corpus.
Terminal DefEq, DAG static guards, Quot and bounded ordinary-recursor ownership
drafts are separately preserved for review; they are not included or qualified
by this fixture-only correction. Next: inspect fresh native and both generated
routes to terminal status before promoting any further architectural slice.

## 2026-10-21 09:18 UTC — qualified lazy delta; full-shape successor pending

Last fully qualified developer source: **`480d875d5be7a9e656e7ccd1fa76cc7409a81c90`**.
Native [119129224910](https://github.com/dwijayuda/pskernel/actions/runs/39572301149/job/119129224910)
and generated [119129224648](https://github.com/dwijayuda/pskernel/actions/runs/39572301149/job/119129224648)
integration are terminal PASS. Native correctness
[119129225529](https://github.com/dwijayuda/pskernel/actions/runs/39572301275/job/119129225529)
and complete canonical-source portability/execution
[119129225160](https://github.com/dwijayuda/pskernel/actions/runs/39572301275/job/119129225160)
are terminal PASS. All six research jobs in
[39572301201](https://github.com/dwijayuda/pskernel/actions/runs/39572301201) passed.

| Exact source | Native | Portable .lean | Canonical .ps | Generated JS | Local proofs | Benchmark | Arena | Provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `480d875d5be7a9e656e7ccd1fa76cc7409a81c90` | PASS | PASS | PASS | PASS | PASS | PASS selected workloads | FAIL qualification | PASS |
| This full-shape successor | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

The480 gates retain the mutual280-case/eight-official matrix, fresh-member budget
owners, batch atomicity, binder/theorem/unsafe controls, ordered prefix and
scanner equivalence. Added owner/stage counts passed in native and both real JS
routes: proof irrelevance1350; Nat1350/192; lazy delta1800/1024/128, with18
official positive and4 invalid fixtures. No resource/callback policy changed.
Native and each JS provider passed24 detached protocol cases; each JS API
passed8 additional cases, and the official provider check passed5 fixtures,
including the real4-declaration batch. JS runs used empty PATH. Readable JS/TS,
declarations/maps, and the complete canonical source were packaged. Full-kernel
DirectJS remains explicitly UNSUPPORTED.

Source-bound artifact ZIP SHA-256 receipts:
- [native12332333450](https://github.com/dwijayuda/pskernel/actions/runs/39572301149/artifacts/12332333450):
  `d668ab906463a82e3b84d2668f9e1bfe6742d672b451bee92d0cdd50cbd129e9`.
- [generated12333042410](https://github.com/dwijayuda/pskernel/actions/runs/39572301149/artifacts/12333042410):
  `31caafea53b99207509b9adbb1a6e797bee7627f8345facbad32cc76f74d1b6b`.
- [canonical12334201691](https://github.com/dwijayuda/pskernel/actions/runs/39572301275/artifacts/12334201691):
  `9a50cffda08e9821dff6ad414f68647e6150f5a967d180b6f697f3462a779c6b`.

Each includes a per-file/source-SHA manifest. Native provider executable:
`e11ae0d9ec43eb75f4302997e66decccafb0e785cc57e42daa07d73c1e208c3c`.
Lean-generated JS:
`b8b4d773d6d8e971b4005eacf29592f6dcdcd46591e44e63ea9debfaa8f8e4b6`.
Canonical-generated JS:
`a0160a756da3331690b80b00a360be32c2f4b90db9b50fa9aa1e69b4d0a5e02c`.
Both routes have identical TypeScript/declaration digests.

### Full193-case480 result — terminal, not inherited

[39572301156/119130181779](https://github.com/dwijayuda/pskernel/actions/runs/39572301156/job/119130181779)
is terminal FAIL qualification:193=170 matching outcomes (103 accepted,
59 kernel rejections,1 metadata rejection,7 transport rejections)+2 separate
unsafe/partial agreements+20 host timeouts+1 explicit unsupported nested-recursion
case. The official job passed. All193 records are present; no timeout or
unsupported result is a parity pass. Remaining timeout IDs are24,73,79–88,
91–97,99; unsupported case17. Artifact12334097511 ZIP SHA-256:
`b283ce8a72818ae11ea726797efbe3e3d30e92937123a060378cfc73e48f631e`.
The complete-check/admission performance receipt is updated in
[PERFORMANCE_2026-10-21.md](PERFORMANCE_2026-10-21.md), including regressions.

### This successor

The single DAG DefEq owner now has full-shape application/head comparison,
left-to-right argument comparison, function eta, binder/sort/literal rules,
residual core WHNF and changed-root continuation. Outer unsupported versus
inner undecided results stay distinct; callback budgets, failure ordering and
original-pair publication are preserved. New gates require342 direct-stage and
108 owner comparisons, six official fixtures and one invalid case in native and
both generated routes. Matching projection and structure/string/unit terminal
rules still decline; their drafts are not part of this qualification.

Corrected logical collection
[39569335308/119119294437](https://github.com/dwijayuda/pskernel/actions/runs/39569335308/job/119119294437)
at217013c is terminal PASS collection, using **earlier e015 runtime**.
Repeated-subproblem still times out (578/588 nearest samples at HasFVar under
V1 cache eligibility); church still times out (357/574 at argument comparison,
119 at equality); Init still times out; stuck-prop correctly rejects. Timeout
verdict comparison is explicitly unassessed. Artifact12331869594 ZIP:
`3c668e57ccb615845f02bfcfbd66fb7ad882c156c741b7a7095736703131b0bc`.
Instrumentation is attribution only, never a latency or conformance claim.

A is achieved for the documented scoped V1 developer provider at480. B/C remain
open; four public whole-operation fallback sites remain. No global soundness
proof is claimed. This successor needs all fresh gates before promotion of the
prepared terminal DefEq, static-guard and Quot slices. Next executable action:
inspect all push-triggered jobs for this exact commit and fix any native,
portable-source or generated blocker without weakening assertions.

## 2026-10-21 08:50 UTC — recursive-call portability fix; authentic caller attribution

At exact source `dbb86c93c15bc84c82c530d9bebdf9a76c15e339`, native integration
[119125965066](https://github.com/dwijayuda/pskernel/actions/runs/39571330765/job/119125965066)
and native correctness
[119125963590](https://github.com/dwijayuda/pskernel/actions/runs/39571330406/job/119125963590)
are terminal PASS, as are the five native/portable-subset research jobs.
Authentic PSC1 now parses and elaborates the corrected DeltaStep module.
It then rejects `psKernelExprV2DefEqLazyDeltaContinueWithFuel` with
`structuralRecursionArity` in LazyDelta.lean. Generated integration
[119125964646](https://github.com/dwijayuda/pskernel/actions/runs/39571330765/job/119125964646)
and generated research
[119125963933](https://github.com/dwijayuda/pskernel/actions/runs/39571330549/job/119125963933)
are terminal FAIL before runtime qualification.

This function has a flat nine-argument entry. Its recursive alias supplied only
the fuel argument, which authentic PSC1's structural checker does not admit for
that entry shape. The correction calls the recursive function with all nine
arguments inside the same callback lambda. The flat generated ABI, predecessor
fuel, fixed callbacks, evaluation point, native semantics and assertions remain
unchanged. This fixes the source class rather than changing the compiler or gate.
The containing corrected source still requires its own complete CI receipts.

### Original-body logical trace (diagnostic branch only)

Diagnostic [39568817340 /119117586645](https://github.com/dwijayuda/pskernel/actions/runs/39568817340/job/119117586645)
at `868a1ee518a963ec141bc1129910aaf093261031` is terminal PASS **collection**.
Its runtime source is qualified e015; changes are solely the isolated tracing
harness/workflow. The separate copy passed the existing detached controls and
strict compiler-runtime identity check. All four original body digests and host
limits were retained. No timed-out case became a checking verdict.

- `perf/repeated-subproblem.ndjson`:587 logical samples;579 nearest samples
  are `psKernelExprHasFVar`. The observed caller chain is semantic cache
  eligibility → core WHNF → lazy-delta step → full-shape/application DefEq →
  theorem admission, after the public DAG operation restarts V1. Static
  declaration validation is not the observed dominant caller.
- `perf/church-numerals.ndjson`:575 samples;378 nearest at expression-list
  DefEq comparison,107 at recursive expression equality. It still times out.
- `init-prelude.ndjson`:543 samples, mixed name/cache work and recursive
  instantiation/inductive analysis across DAG attempts and V1 restarts; still
  times out. Its authenticated graph has54,535nodes.
- `bugs/proj-of-stuck-prop.ndjson`:unprofiled and diagnostic copies correctly
  reject;288 logical samples cover mixed checking/transform/cache work.

The diagnostic ZIP
[12332855748](https://github.com/dwijayuda/pskernel/actions/runs/39568817340/artifacts/12332855748)
has SHA-256 `9604ac00e098ec1d68fd405b28ffb8d83e5bce8d1c0ef9206a1621ab0394a670`.
Sampling/stack instrumentation changes performance; these are caller-attribution
receipts, not latency speedups or conformance results. The217 successor records
timeout verdict comparison as unassessed rather than Boolean agreement; that run
remains IN PROGRESS.

Next: qualify lazy delta, then the prepared full-shape and final DefEq stages.
The observed fallback caller makes this migration relevant to the measured
bottleneck. Static DAG admission guards remain useful P1 work but are not claimed
to fix these timeouts. A separately staged quotient reduction draft now preserves
fixed recursor/public/core fuel ownership; it is uncompiled, not integrated and
requires its native/generated/official matrices before promotion.
Last complete scoped provider gateA remains e015; B/C remain open.

## 2026-10-21 08:42 UTC — explicit control-flow types for authentic PSC1

The two conditional-root aliases in `b438e9508a6df7b2f895f3c96456bf42851443d5`
passed parsing. Its native integration
[119122744843](https://github.com/dwijayuda/pskernel/actions/runs/39570376611/job/119122744843)
and native correctness
[119122743486](https://github.com/dwijayuda/pskernel/actions/runs/39570376548/job/119122743486)
are again terminal PASS. All five native/portable-subset research jobs passed.
Authentic complete-source elaboration then reported
`psKernelExprV2DeltaDefinition: matchExpectedType` in DeltaStep.lean:
the new match-valued `hasArgs` local had no explicit result type.
[Generated integration 119122744269](https://github.com/dwijayuda/pskernel/actions/runs/39570376611/job/119122744269),
[canonical correctness 119122743328](https://github.com/dwijayuda/pskernel/actions/runs/39570376548/job/119122743328),
and [generated research119122744304](https://github.com/dwijayuda/pskernel/actions/runs/39570376577/job/119122744304)
are terminal FAIL before generated execution.

This successor annotates every new match/conditional constructor-valued local
in DeltaStep (Bool, Nat, optional node, state, step, cache/argument/failure result)
and names the nested Bool conditional. These are portable-source elaboration
corrections; the algorithm, callback ownership, cache admission, errors,
test matrices and kernel4096 policy are unchanged. The staged FullShape/FinalRules
and admission-guard drafts are being checked for the same source class before
promotion. Exact successor gates are NOT RUN until their terminal receipts arrive.

The source matrix for b438 is the same as4105 below: native/proof/native benchmark/
native provider PASS; complete portable FAIL elaboration; canonical/runtime/generated
provider NOT RUN. It is not qualified by native success alone. Last full scoped
provider checkpoint remains e015; full Arena remains170matches +2safety +20timeouts
+1unsupported. No full V2 or full Lean compatibility claim is made.

## 2026-10-21 08:34 UTC — lazy-delta native qualified; conditional-argument portability correction

Exact source `4105e93bac9cecabd4afdbc3dd35b1fc8536cbac` has terminal **PASS**
[native integration 119118769285](https://github.com/dwijayuda/pskernel/actions/runs/39569175573/job/119118769285)
and [native correctness 119118768825](https://github.com/dwijayuda/pskernel/actions/runs/39569175456/job/119118768825).
Native integration passed the new **1,800 owner / 1,024 loop / 128 step** lazy-delta
comparisons and **18 official fixtures / four invalid fixtures**, the restored
280-case mutual-admission controls, all prior regressions, local metadata/cache/fuel
proofs, selected native benchmarks and the detached native provider (24 CLI cases,
five official cases, including a real four-declaration batch). Its artifact is
[12330674782](https://github.com/dwijayuda/pskernel/actions/runs/39569175573/artifacts/12330674782),
uploaded ZIP SHA-256 `b52f92cbf8abe5e88390f567c75798fba4227ede7a973edf41f7daa80189cdc4`.

The complete source is **not yet qualified**: generated integration
[119118769377](https://github.com/dwijayuda/pskernel/actions/runs/39569175573/job/119118769377),
canonical correctness
[119118768539](https://github.com/dwijayuda/pskernel/actions/runs/39569175456/job/119118768539)
and generated research
[119118769898](https://github.com/dwijayuda/pskernel/actions/runs/39569175665/job/119118769898)
are terminal FAIL at authentic PSC1 parsing, DeltaStep.lean:174:
`expected ')', got 'then'`. PSC1 does not accept the parenthesized conditional
used as a function argument there. The same source class occurs at line198.
This successor binds both selected roots to local names before the calls.
There is no branch, resource, callback, state, test expectation or assertion change.
The native/generated/canonical full gates must run on this corrected source.

| Exact source | Native | Portable source | Canonical .ps | Generated JS | Proof | Benchmark | Arena | Provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `4105e93bac9cecabd4afdbc3dd35b1fc8536cbac` | PASS | FAIL PSC1 parser | NOT RUN after parse failure | NOT RUN after parse failure | PASS native | PASS native selected; JS NOT RUN | FAIL source reconstruction; corpus NOT RUN | PASS native; JS NOT RUN |
| `e015839e0cdf29b1e4f2d4a750fed8956c0afe17` | PASS | PASS | PASS source/runtime | PASS both routes | PASS local | PASS measured controls, with recorded regressions | FAIL 20 timeouts + one unsupported | PASS native/both JS |
| Containing conditional-argument correction | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

### Exact e015 Arena receipt supersedes its historical pending entries

The full generated comparison
[39565480377 / 119107493976](https://github.com/dwijayuda/pskernel/actions/runs/39565480377/job/119107493976)
is terminal **FAIL qualification**. All193 authenticated cases are recorded:
**170 matches** (103 acceptances,59 kernel rejections,one metadata rejection,seven
transport rejections), **two unsafe/partial contract agreements**, **20 host
timeouts**, **one unsupported nested-recursion case**. The official-reference job
passed; unsupported is not a negative kernel verdict. This independently confirms
the earlier f483 totals at the exact fully green developer-provider source.
Artifact [12331396341](https://github.com/dwijayuda/pskernel/actions/runs/39565480377/artifacts/12331396341)
has ZIP SHA-256 `5cae6148480d69b2d87aa33931b5c9abb6fa73c7025d1d220fbe70c1fb5dd28d`.
The named timeout set and classification below remain unchanged.

The separate logical diagnostic branch is now
`217013c32eae791b3e40a420202ad6cfdb43fe65`,
[run39569335308](https://github.com/dwijayuda/pskernel/actions/runs/39569335308).
It distinguishes unassessed timeout outcome comparisons from successful verdict
agreement and removes stale source-map metadata only from its diagnostic copy.
Its runtime semantic source remains e015. It is IN PROGRESS, not a kernel release gate.

Next: finish exact-source lazy-delta portable/generated qualification before
promoting the prepared full-shape/final-rule stages. Independently review the
DAG static admission guard and its exact-ID scan proof/negative tests; use the
logical trace to attribute the remaining free-variable-scan cost. GateA remains
achieved only at the scoped e015 checkpoint; B/C remain open. Four public
whole-operation fallback sites remain, and the final default remains V1.

## 2026-10-21 — lazy-delta syntax correction and first full allocation corpus result

The ordered lazy-delta source at `a256edb117ace146d1798f3d32cdeb488a45db84`
is **not qualified**. Integration [39567818080](https://github.com/dwijayuda/pskernel/actions/runs/39567818080)
is terminal FAIL in both jobs:
[native 119114273453](https://github.com/dwijayuda/pskernel/actions/runs/39567818080/job/119114273453)
compiled the portable kernel but could not compile the new test because
`let by` used Lean's reserved `by` keyword as a local identifier.
[Generated 119114273662](https://github.com/dwijayuda/pskernel/actions/runs/39567818080/job/119114273662)
built authentic PSC1, then its parser rejected `(Prod.fst unfolded).whnf`
at DeltaStep.lean:102. Native correctness
[119114273797](https://github.com/dwijayuda/pskernel/actions/runs/39567818151/job/119114273797)
passed; canonical-source checking and the generated research bridge failed at
the same portable-source parse defect. These are a **fixture syntax defect**
and a **source-language portability defect**, respectively. The new semantic
matrix, proof, detached generated and provider gates did not run in those jobs.

This correction renames the fixture local to `decodedRight` and binds the
projected state to an explicit local before accessing its field. No fuel,
callback, branch, assertion, expected verdict or environment publication changes.
The same unsupported syntactic pattern is being removed from the separately
staged FullShape/FinalRules drafts before their eventual qualification.

The last fully green scoped provider checkpoint remains **e015839** with the
terminal native, portable, canonical, generated, proof and provider receipts below.
The containing correction needs its own exact-source test results; no success
is inferred from the previous native kernel compilation.

### Terminal full Arena result at f483

[39564831733 / generated job 119105347671](https://github.com/dwijayuda/pskernel/actions/runs/39564831733/job/119105347671)
is terminal **FAIL qualification**, with all **193** records:
**170 matching outcomes** = 103 acceptances + 59 kernel rejections + one metadata
rejection + seven transport rejections; **two** separately classified unsafe/partial
safety agreements; **20 host timeouts**; and **one explicit unsupported case**.
There are no newly observed false acceptances or false rejections in these records.
The official-reference job passed.

Compared with the previous 24-timeout result, three bad cases now complete with
the correct kernel rejection: `bugs/proj-of-stuck-prop.ndjson`,
`bugs/proj-of-subst-prop.ndjson`, and `bugs/rec-of-subst-prop.ndjson`.
`bugs/rec-missing-ih.ndjson` now terminates as **unsupported**, with
`simple inductive admission does not yet support nested recursive occurrences`.
Official Lean rejects that case; unsupported is neither a rejection nor a parity pass.

Remaining timeout case numbers are 24, 73, 79–88, 91–97 and 99 (one-based corpus
numbering). The exact named per-case records are in artifact
[12329788354](https://github.com/dwijayuda/pskernel/actions/runs/39564831733/artifacts/12329788354),
ZIP SHA-256 `b66dd329573eee116890d0d9bac5e55d55db5ac1ec055be757808716944dc6a1`.
Default fuel4096, body authentication and60s/2GiB bounds were unchanged.
The e015 full comparison was still running when this correction was prepared;
f483's result is not relabeled as an e015 source receipt.

### Parallel diagnostic continuation

The logical-call tracer is committed on isolated branch
`research/psc1-arena-logical-20261021` at
`868a1ee518a963ec141bc1129910aaf093261031`, based on qualified runtime e015.
Only its harness, workflow and state record differ. It retains the original
unprofiled/V8 diagnostics, then runs a separately instrumented copy with strict
runtime-identity checks, existing detached positive/adversarial controls and the
same four authenticated bodies. It is source-reviewed, **not yet executed**.
This separate branch does not advance or mutate the integration source. Diagnostic
collection is never a conformance result or a numeric speedup.

Next: re-run the complete corrected lazy-delta checkpoint to terminal status;
fix any semantic/ABI/proof defect without weakening the 1,800/1,024/128 matrix.
Use the logical trace to distinguish declaration guards, cache eligibility and
other free-variable-scan callers before the next P2 source change. Preserve the
known e015 provider while completing projection/final rules, recursor/iota and
admission migration. Four public whole-operation fallback sites remain.

## 2026-10-21 08:12 UTC — exact provider checkpoint green; ordered DAG lazy delta enters qualification

**Last fully qualified native/portable/generated developer checkpoint:**
`e015839e0cdf29b1e4f2d4a750fed8956c0afe17`.
Both jobs in [integration 39565480601](https://github.com/dwijayuda/pskernel/actions/runs/39565480601),
both jobs in [correctness 39565480292](https://github.com/dwijayuda/pskernel/actions/runs/39565480292),
and all six jobs in [research 39565480417](https://github.com/dwijayuda/pskernel/actions/runs/39565480417)
are terminal **PASS**. This supersedes the pending allocation-proof entries below.
The branch is now advancing through the ordered lazy-delta implementation
`6cc04d1583d512603428d2796824d7794156412e` and this evidence update;
that successor must earn its own exact-SHA qualification.

| Exact source | Native | Portable source | Canonical .ps | Generated JS | Proof | Benchmark | Arena | Provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `e015839e0cdf29b1e4f2d4a750fed8956c0afe17` | PASS | PASS | PASS source + runtime | PASS both routes | PASS | PASS selected workloads; regressions below | IN PROGRESS | PASS native + both JS routes |
| `f483e310efdda9dfcca47d42a731540dfe478aba` | FAIL new equality proof script | PASS research closure | PASS source + runtime | PASS | FAIL elaboration; corrected at e015 | Native skipped after proof failure | IN PROGRESS | Native skipped after proof failure |
| Containing ordered lazy-delta successor | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

### What actually passed at e015

Native [job 119106602099](https://github.com/dwijayuda/pskernel/actions/runs/39565480601/job/119106602099)
checked all four expression-equality equivalence theorems and all fifteen
fuel-worker equivalences. The frozen predecessor definitions and theorem statements
were unchanged by the proof correction. The dependency audit stayed within the
existing permitted `propext`, `Classical.choice`, and `Quot.sound` set; these
are local proof-file dependencies, not new portable runtime axioms. The native
800-comparison equality regression and 21 hostile depth-64 shared-expression
controls passed. Both generated routes passed the corresponding hostile controls.

All prior mandatory controls also passed: the 280-case mutual-definition matrix
and eight official mutual fixtures, fresh-member owner and batch atomicity checks,
binder/prefix/error-order checks, 1,008 inference comparisons, 1,350 proof-irrelevance
comparisons, 1,350 Nat comparisons plus 192 direct-stage comparisons and 14 official
Nat decisions with one invalid primitive. Native provider checks passed five
official fixtures and 24 detached CLI cases. The
[generated job 119106602375](https://github.com/dwijayuda/pskernel/actions/runs/39565480601/job/119106602375)
and [canonical job 119106601595](https://github.com/dwijayuda/pskernel/actions/runs/39565480292/job/119106601595)
each passed 24 CLI and eight private-byte-buffer API cases with PATH empty.
The entire canonical source closure was reconstructed, independently checked and
compiled. Later packaging and DirectJS-capability-report steps also finished;
full-kernel DirectJS remains unsupported.

**Gate A is achieved for the documented scoped developer provider at e015.**
The provider remains V1-based, starts from a fresh empty checked environment and
supports the canonical-admissions-v2 contract in [PROVIDER.md](PROVIDER.md).
This does not establish full Lean compatibility or a complete DAG-native V2.
Gates **B and C remain open**. The new successor is not qualified by inheritance.

### Reproducible e015 artifacts

| Artifact | Download | Uploaded ZIP SHA-256 |
| --- | --- | --- |
| Native Linux provider and manifest | [12329830825](https://github.com/dwijayuda/pskernel/actions/runs/39565480601/artifacts/12329830825) | `56cd991ad2f5d9572cab9ec9ca614d106e9157cbd2b3bd1006d8c91f1c7af2c6` |
| Lean-derived JS, TS, declarations, map and provider | [12330606437](https://github.com/dwijayuda/pskernel/actions/runs/39565480601/artifacts/12330606437) | `aec4002f33b6b6427d9ffd85cc864265d68561a1ed3f29788aa43522e5bb29fb` |
| Canonical source closure and generated provider | [12330486620](https://github.com/dwijayuda/pskernel/actions/runs/39565480292/artifacts/12330486620) | `092d7860660c5727b75df64477a1edbd53e63bfd83721075e1465030555e588d` |

Native executable SHA-256:
`e11ae0d9ec43eb75f4302997e66decccafb0e785cc57e42daa07d73c1e208c3c`;
executable-preserving tar:
`c971bb2cbdcde62e3afe675a44abfb039b3f25cfaf262c23cfe1582bfd3298c8`.
Lean-derived JS:
`76c9fbf040b5df1f5a838a3f5637bd3c5b06b76bd0890399590020d089070f17`;
canonical-derived JS:
`1f11b5e27de7cb5b468422acda3f16444de4ba5ee22754a459e84178980f2462`;
canonical source tar:
`54c7a94b604e38a6ddaf7d7ad0cb0c6f60bceeb76e1fd04fc2abd6d08cccc8f9`.
Both generated routes have identical TS
`757a7e606516182ae32d327d808128442b2cdca8e7fcf583a88342469166533b`
and declarations
`155b391e4b1b9070e2450e4b76c43c22b24c0f0d86eef6440b4ecd4969c01af2`.
Their maps are respectively
`16c9321f257e238bb01b42c592c81797f180d9c552f35cf0099f19145180bb0d`
and `bf3c3ad2f076a37754cfe65e10288a8a0bdd2fcf50ac2c3cb1e7b233216eeac8`.
All manifests bind e015, Lean 4.35.0, TypeScript 7.0.2 and Node 22.23.3.
Artifacts retain the existing 30-day policy.

### Ordered lazy-delta implementation now submitted

The new `DefEq/Args.lean`, `DeltaStep.lean`, and `LazyDelta.lean` integrate into
the one DefEq owner after the Nat prefix. Definition selection honors the admitted
body index, exact universe arity, reducibility hints, one-sided projection priority,
right-to-left same-definition argument comparison, and left-before-right unfolding.
A missing selected owning reference declines the whole operation; an unsuccessful
shortcut is never a negative kernel judgment. The lazy loop spends only its own
predecessor fuel and keeps the owner's DefEq/WHNF callbacks fixed.

`CheckState.lean` adds operation-owned unfold and failed-argument-shortcut caches.
Every state setter preserves them and local-scope exit restores the parent caches.
Failed pairs only skip an already failed shortcut; they do not authorize equality,
inequality or transitive closure. New local proof obligations cover scope/cache
preservation and zero-fuel precedence.

The mandatory native/generated/canonical matrices are 1,800 owner comparisons,
1,024 lazy-loop comparisons and 128 individual-step comparisons, plus 18 official
positive and four official invalid fixtures. They also test collision checking,
fresh/closed cache eligibility, original-pair publication, low-budget callback
ownership, failure order, missing selected body references and atomic bad-body
refusal. These are required outputs, **not observed passes** at this update.

The four public whole-operation fallback sites and boundary decoding remain.
The source-reviewed full-WHNF/full-shape follow-up is stored separately at
`403e5bb121085cef3579718f58625f4d5eb84e8c`, not promoted or tested.
It must be applied only after the lazy-delta checkpoint qualifies.

### Performance and corpus status

At e015 all 114 native observations and 128 generated public-operation observations
were correct. Same-source V1/DAG warm ratios were **0.523–6.737x native** and
**0.677–6.102x generated**. Generated projection-field WHNF and several complete
admission workloads regress. The six safe-admission warm ratios now range
**0.556–2.061x**; historical 8–16x ratios do not apply to this source. The allocation
fix improves helpers shared by V1 and DAG, so old-versus-new timing must not be
conflated with same-source V1/DAG comparisons. Full cold, construction, RSS and
retained-heap receipts are appended to [PERFORMANCE_2026-10-21.md](PERFORMANCE_2026-10-21.md).

The e015 full [Arena run 39565480377](https://github.com/dwijayuda/pskernel/actions/runs/39565480377)
and runtime-equivalent f483 [run 39564831733](https://github.com/dwijayuda/pskernel/actions/runs/39564831733)
remain in progress. The f483 authentic profile
[39564831855](https://github.com/dwijayuda/pskernel/actions/runs/39564831855/job/119104504017)
is terminal **PASS collection**. Of its four authentic diagnostic cases,
`bugs/proj-of-stuck-prop.ndjson` now completes with the official rejection in
both unprofiled and profiled runs, under unchanged limits. Repeated-subproblem,
church-numerals and init-prelude still time out in both runs. This establishes one
previously timed-out whole-checker rejection at f483, not a full-corpus pass or an
e015 result by inheritance. Repeated-subproblem's V8 profile identifies
`psKernelExprHasFVar` as a major hot function. Diagnostic artifact
[12330238456](https://github.com/dwijayuda/pskernel/actions/runs/39564831855/artifacts/12330238456),
ZIP SHA-256 `d72ec722055e6f52ef5e8d6af1b53ab5b18c7355d1384536124033bd7f128322`.
No full-corpus timeout total is claimed before the comparison jobs terminate. The last terminal
full-corpus result is still 854bdb9: 193 records = 167 matching outcomes, two
safety-contract agreements and 24 host timeouts. Its matching outcomes include
103 acceptances, 56 kernel rejections, one metadata rejection and seven transport
rejections. Default fuel 4096 and the 60-second / 2-GiB host bounds are unchanged.

**Next critical path:** finish exact-source lazy-delta native, authentic PSC1,
canonical and generated gates; diagnose actual failures without weakening tests.
Then promote the reviewed full-shape stage, implement remaining projection/final
rules and recursor/iota dependencies, and retire each fallback only after parity.
Inspect the pending authentic Arena results before choosing another performance
change. A diagnostic trace of logical trampoline calls is being prepared separately;
it cannot qualify a kernel decision or supply uninstrumented performance timings.

Tool limitation: an interrupted analysis worker could not be resumed because
`collaboration.followup_task` returned `agent thread limit reached`. Its
untransferred diagnostic draft is not a committed deliverable or a test result.
The root continues repository work through connected GitHub tools and Linux
Actions; no local checkout or local kernel execution was substituted.

## 2026-10-21 07:56 UTC — allocation proof normalization correction

At candidate `f483e310efdda9dfcca47d42a731540dfe478aba`,
[integration 39564831824 / native job 119104503980](https://github.com/dwijayuda/pskernel/actions/runs/39564831824/job/119104503980)
is terminal **FAIL** in the new equality proof file. Complete checker compilation
and all preceding semantic, mutual, owner, inference, proof-irrelevance, Nat and
transformation regressions passed. The new 800-comparison / 21-hostile native
equality regression also passed. The universal theorems did not elaborate:
the simplifier left equivalent right-expression matcher auxiliaries unresolved.
This is a **proof-script defect**; no kernel decision mismatch was observed.
The later fifteen-worker proof command and native provider/benchmark steps
were **NOT RUN** in that failed job.

The correction explicitly cases the right expression in each equality proof
and finishes remaining definitional matcher equalities with reflexivity in the
fuel proofs. Frozen predecessor definitions, theorem statements, production
functions, required assertions and all CI gates are unchanged. Failed
elaboration's printed `sorryAx` dependencies are failure diagnostics, never
accepted proof receipts; the Lean process exited nonzero and blocked the job.
No admitted proof or new trusted runtime path is introduced.

Native correctness at f483e31 passed; other source/generated/canonical/research
and corpus jobs were still running when this correction was prepared. The
containing correction requires its own exact-SHA qualification. The last fully
green developer/provider checkpoint remains 854bdb9 above; f483e31 is not
qualified by the successful executable regression alone.

## 2026-10-21 07:38 UTC — qualified provider checkpoint; structural allocation candidate

**Last fully qualified native/portable/generated developer checkpoint:**
`854bdb9e0febf4e01fb5ce4b2cc8ea91f61287e4`, on the integration branch above.
Both jobs in [integration 39560050702](https://github.com/dwijayuda/pskernel/actions/runs/39560050702)
and both jobs in [correctness 39560050819](https://github.com/dwijayuda/pskernel/actions/runs/39560050819)
are terminal **PASS**. All six jobs in
[research 39560050764](https://github.com/dwijayuda/pskernel/actions/runs/39560050764)
are terminal **PASS**. This supersedes earlier pending entries for the corrected
Nat fixture, canonical execution and byte-input provider API.

| Exact source | Native | Portable source | Canonical .ps | Generated JS | Proof | Benchmark | Arena | Provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `854bdb9e0febf4e01fb5ce4b2cc8ea91f61287e4` | PASS | PASS | PASS source + runtime | PASS both routes | PASS existing gates | PASS selected workloads | FAIL: 24 host timeouts | PASS native + both JS routes |
| Containing allocation candidate | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

The source-bound native job is
[119088851480](https://github.com/dwijayuda/pskernel/actions/runs/39560050702/job/119088851480);
the generated job is
[119088850976](https://github.com/dwijayuda/pskernel/actions/runs/39560050702/job/119088850976);
the canonical job is
[119088851453](https://github.com/dwijayuda/pskernel/actions/runs/39560050819/job/119088851453).
Required executions include the 280-case mutual-definition matrix, eight
official mutual fixtures and fresh-member budget sentinels; 1,008 inference-only
comparisons; 1,350 proof-irrelevance comparisons; 1,350 Nat comparisons and
192 direct Nat-stage comparisons, with 14 official decisions and one invalid
primitive; metadata, scanner, cache-scope and Nat-fuel proof gates; existing
binder/prefix/admission/failure-order controls; the five official provider
fixtures; and 24 detached provider CLI cases on native and both generated routes.
Each generated route additionally passed all eight private-byte-buffer API cases.
The generated Nat harness reports 2,429 assertions. Neither provider execution
delegates checker decisions to Lean; the generated processes run with PATH empty.

### Exact checkpoint artifacts

All manifests name source `854bdb9e0febf4e01fb5ce4b2cc8ea91f61287e4`.
A checksum is an integrity receipt, not a proof of a verdict.

| Artifact | Download | Uploaded ZIP SHA-256 |
| --- | --- | --- |
| Linux native executable and manifest | [12327502114](https://github.com/dwijayuda/pskernel/actions/runs/39560050702/artifacts/12327502114) | `5763471acc85b564deac16046611cb43c646359a7838fd7bb3ca3008969ccdf6` |
| Complete .lean-generated JS provider, TS, declarations and map | [12328068763](https://github.com/dwijayuda/pskernel/actions/runs/39560050702/artifacts/12328068763) | `4e23b676ed5edc6eb0cc1122037237d0dbafd05dc1269d2d95fc24b5401733c6` |
| Complete canonical source and generated provider | [12328716432](https://github.com/dwijayuda/pskernel/actions/runs/39560050819/artifacts/12328716432) | `d92c13f9bdaa0bf3ff04f7e991aee9f912f0ffd6c5c5047395a9c0cd333b831a` |

Native executable SHA-256:
`562d95ba7b56f9b905b124453f61295902f3d418831322a83c9af2738594cc4d`.
Executable-preserving tar:
`2ad0ed91a03feb9fa46d1485b10cd016b60227b32ce41eb26ea11455912d558c`.
Lean-derived JS:
`3ea6e3b59470fdef9363de2c0f0ea7256a13a1fe65fa9dfe4a068cb8f45476e2`.
Canonical-derived JS:
`d55b36f01cf7581d8eea49d4b5d87583207ff79e084d2f1ee1ae1126107d97f0`.
Canonical source tar:
`3939859c26b5d9ab8fd63845e0c24b02cd420afe75d2fe87b94cb377064fadee`.
Both routes produce the same TS source and declarations:
`2073ab6638edee59e8b658d5404a9f93d37a638ba73bbb9234195bc167411fa0`
and `155b391e4b1b9070e2450e4b76c43c22b24c0f0d86eef6440b4ecd4969c01af2`.
Map hashes are preserved in the manifests. Artifacts have the workflow's
30-day retention; reproducible source and recipes remain committed.

### Corpus result and changed diagnosis

[Full Arena 39560050730 / job 119089611991](https://github.com/dwijayuda/pskernel/actions/runs/39560050730/job/119089611991)
is terminal **FAIL qualification** at the same source: all 193 cases evaluated,
167 matching outcomes (103 acceptances, 56 kernel rejections, one metadata and
seven transport rejections), two separately classified unsafe/partial safety
agreements, and 24 host timeouts. The official reference job
[119088851272](https://github.com/dwijayuda/pskernel/actions/runs/39560050730/job/119088851272)
passed. No timeout is a kernel rejection. Result artifact
[12329155162](https://github.com/dwijayuda/pskernel/actions/runs/39560050730/artifacts/12329155162),
zip SHA-256 `7a49839c167de33bfb80a715c93212333d328aa02234fed32e41670f0d713248`.

The preceding `54ea3d428d85ba2936a037a5d9decdcab1593990` and
`753b30cab254f8b85fa3da4815121c32c484f5e7` full comparisons also ended with the
same 24 host timeouts. The cache-eligibility reorder did not resolve a single
full case. The authentic four-case profile at 54ea3d4 also timed out in all
unprofiled/profiled pairs; its collection success does not qualify the cases.
The source-bound profile and sampled RSS receipts are appended to
[PERFORMANCE_2026-10-21.md](PERFORMANCE_2026-10-21.md).

The containing commit changes only the placement of recursive aliases inside
existing argument lambdas in both structural equality workers and all fifteen
identified eager fuel workers. This prevents partial application from eagerly
constructing recursive function chains or the equality worker for an entire
shared subtree before its other input is examined. No fuel value, recursive
argument, callback placement, error branch, primitive truncation behavior or
public/staged type is changed. Frozen definitions from 854bdb9 and universal
local function-equivalence statements are added in
`test/PsKernelExprEqualityProofs.lean` and `test/PsKernelKnotFuelProofs.lean`.
They require actual Lean checking and the existing axiom audit. These are
replacement theorems using common imported helpers, not global soundness or
allocation-bound proofs.

Native tests add 800 frozen equality comparisons and 21 hostile early mismatches
against a 65-node shared expression. Both generated routes require the same
21 hostile controls plus two staged-ABI controls. The frozen eager oracle is
never evaluated on the exponential unfolded tree. All previous gates remain.
The modified helpers serve V1 as well as DAG users: new same-revision V1/DAG
numbers cannot be advertised as before/after speedups against original 854bdb9.

### Remaining critical path

1. Qualify the containing allocation candidate at its exact SHA: all 15 fuel
   theorems, four expression-equality theorems, native/portable/canonical/generated
   execution, provider controls, whole-operation benchmarks and all 193 cases.
   No allocation or corpus speedup is claimed before those runs finish.
2. Diagnose any remaining authentic timeouts from actual call behavior. Keep
   fuel 4096 and Arena host 60 seconds / 2 GiB; recursive free-variable/node-count
   scans remain. Preserve historical artifacts for a same-run before/after
   comparison if a timed-out whole check begins to finish.
3. The next DAG stage is the ordered general lazy-delta loop, with independent
   unfolding/failure caches, exact hints/universe selection, rightmost-first
   same-definition arguments and fixed callback budgets. It is being prepared
   with direct-stage and official regressions; it is not in this source yet.
4. Four RunDag whole-operation fallback sites remain. Residual DefEq, general
   recursor/iota, broader inference/WHNF and inductive admission still require
   migration. V1 remains the default/reference and provider selection.
   No full V2, global soundness or full Lean Arena claim is made.

The usable developer provider scope at 854bdb9 is qualified as documented in
[PROVIDER.md](PROVIDER.md); unsupported wire features are explicit refusals.
The full V2 architecture and full-corpus gates remain open. No merge or package
publication has occurred. Work is performed only through connected GitHub and
Linux Actions. Agent-side Git object creation did not return a receipt and was
stopped after 610 seconds; no successful mutation was inferred from that call.
All branch updates continue through one writer with a fresh expected SHA.

## 2026-10-21 07:08 UTC — generated predecessor harness ABI correction

Source `753b30cab254f8b85fa3da4815121c32c484f5e7` has terminal **PASS**
in native integration
[39558404780 / job 119083557519](https://github.com/dwijayuda/pskernel/actions/runs/39558404780/job/119083557519),
native correctness, and all six research jobs. Native integration includes the
1,350 Nat comparisons, 192 direct-stage comparisons, 14 official decisions and
one invalid primitive, the preserved mutual-definition/owner controls, local
proofs, official provider fixtures and 24 detached native provider cases.

Its generated integration job
[119083557294](https://github.com/dwijayuda/pskernel/actions/runs/39558404780/job/119083557294)
is terminal **FAIL**, at `exact-syntactic-predecessor` in the new Nat smoke.
The corrected warm-cache tests passed; the failure is a separate **harness ABI
mismatch**: `psKernelExprEqual` is exported as a staged function, and this
single assertion called `psKernelExprEqual(left, right)` instead of
`psKernelExprEqual(left)(right)`. The established DAG smoke already uses the
staged call. Native equality for these same predecessor expressions passed.

This correction changes only that invocation and this receipt. It preserves
the exact syntactic equality assertion, all fixture/count/owner checks and
all production code. Generated provider/API and benchmark steps after the
failed Nat step were **NOT RUN**. The canonical source graph has passed its
independent check; canonical generated execution and full Arena were still
in progress at this receipt. Fresh terminal CI is required for the containing
revision; no earlier native or source pass substitutes for it.

| Exact source | Native | Portable source | Canonical .ps | Generated JS | Proof | Benchmark | Arena | Provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `753b30cab254f8b85fa3da4815121c32c484f5e7` | PASS | PASS | PASS source | FAIL .lean-generated; canonical runtime IN PROGRESS | PASS | NOT RUN | IN PROGRESS | PASS native; generated NOT RUN |
| Containing ABI-fixture revision | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

The preceding `e1b4deb214c3088e64a18f8b15148c7a15be2924` full Arena run
[39554691941 / job 119072275837](https://github.com/dwijayuda/pskernel/actions/runs/39554691941/job/119072275837)
is now terminal **FAIL qualification**: all 193 cases evaluated, 167 matching
outcomes (103 acceptances, 56 kernel rejections, one metadata rejection and
seven transport rejections), two separately classified unsafe/partial safety
agreements, and the same 24 host timeouts. Its artifact is
[12327340227](https://github.com/dwijayuda/pskernel/actions/runs/39554691941/artifacts/12327340227),
zip SHA-256 `3d584f7d918155b1d7eae63573e7398f0ad594688af5ba836f8f69f1a0434f33`.
Earlier “IN PROGRESS” entries for that run below are superseded. The candidate
cache-predicate optimization still needs its own completed Arena/profile results.

## 2026-10-21 06:54 UTC — Nat cache fixture correction

At source `54ea3d428d85ba2936a037a5d9decdcab1593990`, native integration
[39557631971 / job 119081025510](https://github.com/dwijayuda/pskernel/actions/runs/39557631971/job/119081025510)
compiled the new source and ran the existing regressions successfully. The Nat
test reached `nonprop-inference-state-survives-nat-continuation` after its
1,350-case and 192-case loop count checks, then **FAILED** that assertion.
The remaining native proof/provider/benchmark steps were not run in that job.

Classification: **fixture error**, not a demonstrated kernel decision mismatch.
The fixture asked literal operands to populate public WHNF caches, but both
`Checker/Reduction/Whnf.lean` and `Checker/ExprV2/Whnf.lean` deliberately return
literal operands immediately without cache publication. The corrected native and
JS warm fixture uses `Nat.add (Nat.add 1 0) (Nat.add 2 0)` so both immediate
operands exercise actual nonterminal public WHNF publication. The original
simple-add expression remains unchanged for the exact discarded-predecessor
arena-size sentinel. V1 warm-state inputs are changed to the same nested term.

All 1,350 differential fixtures, 192 direct-stage fixtures, official fixtures,
warm guard checks, original-pair assertions and both operand-cache assertions
remain required. No production function, budget, proof statement or acceptance
condition changes in this correction. The containing fixture revision requires
fresh terminal CI; the failed parent is not a qualified milestone. Its native
correctness and official Arena reference passed, while generated/canonical and
full comparison jobs were still running at this receipt.

## 2026-10-21 06:46 UTC — canonical parent PASS; ordered DAG Nat candidate

The immediately preceding complete source `e1b4deb214c3088e64a18f8b15148c7a15be2924`
now has terminal **PASS** in both integration jobs, both correctness jobs and all
six research jobs. Canonical job 119071611610 in
[39554691912](https://github.com/dwijayuda/pskernel/actions/runs/39554691912)
completed independent source-graph reconstruction/checking, generated runtime,
all original DAG regressions, 1,008 inference-only comparisons, 1,350
proof-irrelevance comparisons / 2,000 assertions, large-numeral controls and
the 24 detached provider cases. Complete-kernel DirectJS remains explicitly
UNSUPPORTED. Canonical artifact
[12325868919](https://github.com/dwijayuda/pskernel/actions/runs/39554691912/artifacts/12325868919)
zip SHA-256 is `5123ace515ac90fee4f5482519ff51e7d5b53b8193c84167b4243fdaa7ad2fed`;
canonical JS is `180b441eb8067136fb3037a0940fa93233c99b22b8d9364dcf14cd8c259031b4`;
complete source tar is `7d2a9c8495d7c5f552ed833d5d6cc46e4b43bede4d1d9ab50941e1b4ccdb8e6c`.
The earlier 06:38 “IN PROGRESS” canonical row below is historical and superseded.

| Exact source | Native | Portable .lean | Canonical .ps | Generated JS | Proof | Benchmark | Arena | Provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `e1b4deb214c3088e64a18f8b15148c7a15be2924` | PASS | PASS | PASS | PASS both source routes | PASS | PASS selected controls | IN PROGRESS | PASS native and both JS routes, CLI 24 each |
| `9dfcbeff351157ae41572c7a891bc89c543777e1` | NOT RUN separately | NOT RUN separately | NOT RUN separately | NOT RUN separately | NOT RUN separately | NOT RUN separately | NOT RUN separately | NOT RUN separately |
| Containing Nat/documentation revision | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

The bounded cache-policy/provider-byte ownership changes are retained in
`9dfcbeff351157ae41572c7a891bc89c543777e1`; they will be tested together with this
child revision, not represented as separately tested. This child adds:

- `Checker/ExprV2/DefEq/LazyNat.lean`: exact lazy-entry fuel guard, syntactic
  zero/predecessor handling, original eager/open-expression decision and ordered
  left/right primitive reduction, using the existing owning Nat/WHNF machinery.
  General definition selection still returns outer `none`.
- A non-proposition continuation in the one proof-irrelevance stage, preserving
  its old standalone API. The single DefEq owner supplies fixed predecessor-fuel
  callbacks and publishes only the original requested success pair. Both existing
  compatibility/local-context guards remain unchanged.
- Native and generated 1,350-case DefEq matrices plus 192 direct lazy-stage
  comparisons, 14 official positive/negative decision fixtures and one invalid
  primitive argument. Cold/warm entry guards, typed open locals, numeral/resource
  errors, same-batch checked Nat admission and original-pair/cache state are
  mandatory. An unmatched predecessor candidate does not escape in the arena.
- Local Nat fuel-entry and unmatched-owner lemmas in the retained native proof
  gate. No theorem, old assertion or failure precedence is weakened.
- Updated 4.35 architecture/ownership documentation, a four-site fallback
  inventory, artifact invocation instructions and the source-specific performance
  report `PERFORMANCE_2026-10-21.md`.

The containing revision has not yet executed. Required Actions must reach their
terminal status, including the existing controls and new Nat/API cases. A runtime
ABI or fixture failure blocks qualification and must be repaired without lowering
the assertions. Full V2 remains incomplete: general lazy delta/projection/final
DefEq rules, recursor/iota/Quot and inductive admission still need migration;
boundary decoding and four whole-operation fallback sites remain. All 193 Arena
records must still be evaluated with the exact unchanged resource policy.

## 2026-10-21 06:38 UTC — qualified parent and next source checkpoint

The branch reached **same-source native and generated integration PASS** at
`e1b4deb214c3088e64a18f8b15148c7a15be2924` before the following changes were layered.
Integration [39554691928](https://github.com/dwijayuda/pskernel/actions/runs/39554691928)
finished both jobs successfully: native 119071612176 and generated 119071611694.
The native job checked the retained metadata/cache/fuel proofs, the 280-case mutual
admission matrix and its official fixtures, the new 1,350-case proof-irrelevance
matrix, and the official provider batch (five cases, four accepted declarations,
`doCheck=true`). Native and generated providers each passed all 24 detached CLI
cases with PATH empty. Generated proof irrelevance passed 2,000 assertions.

| Exact source | Native | Portable .lean | Canonical .ps runtime | Generated .lean JS | Proof | Benchmark | Arena | Provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `e1b4deb214c3088e64a18f8b15148c7a15be2924` | PASS | PASS | IN PROGRESS | PASS | PASS | PASS | IN PROGRESS | PASS native/Lean-generated; canonical IN PROGRESS |
| Containing revision after cache/provider changes | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

Correctness run [39554691912](https://github.com/dwijayuda/pskernel/actions/runs/39554691912)
has native PASS; job 119071611610 passed the complete independent canonical-source
check and compilation and is still executing its generated regression steps at
this receipt. Research run [39554691860](https://github.com/dwijayuda/pskernel/actions/runs/39554691860)
finished all six jobs PASS. Full Arena [39554691941](https://github.com/dwijayuda/pskernel/actions/runs/39554691941)
and authentic diagnostics [39554691896](https://github.com/dwijayuda/pskernel/actions/runs/39554691896)
are still running. These are observed statuses, not inherited qualification of
this containing revision; inspect terminal jobs before promoting it.

New bounded changes awaiting their own CI:

- Inference cache eligibility rejects literals and checked application/binder
  kinds before traversing their subtrees. It returns the exact old Boolean policy;
  a frozen proof-only reference and universal equivalence/extensionality theorems
  are added to the existing cache-scope gate. No fuel, depth, cache lookup or
  publication rule changes. V1 remains a separately selectable semantic reference.
- The generated provider snapshots a bounded caller-owned byte view before UTF-8
  validation and decoding, so concurrent writes through shared backing storage
  cannot change the validated input afterward. Eight detached direct API tests
  cover ordinary/shared buffers, offset views, invalid UTF-8, invalid Unicode
  strings/escapes and fresh sessions. The 24 CLI cases remain mandatory.

Qualified parent artifact receipts:

- Native artifact [12325206307](https://github.com/dwijayuda/pskernel/actions/runs/39554691928/artifacts/12325206307),
  zip SHA-256 `cafece4a3513a5aa8b67dee9af2be7fbce641afff98b0d6bdad54704e9a3d86e`;
  executable `ff48ffb0dbf2ac0d523220d270a48417a77909e9ee800c8199b17f3d08a56be2`;
  native tar `df64a133f1ed0200c75664bb6571b3068c624bb25841c9bc41ece4ff736a02b1`.
- Generated artifact [12325479399](https://github.com/dwijayuda/pskernel/actions/runs/39554691928/artifacts/12325479399),
  zip SHA-256 `4b088c19a837a3ce38cc1980c579d60f166b0ae6ef3c0ab6fcf564d87e5dcee3`;
  `kernel.js` (5,942,214 bytes) SHA-256
  `13fac713ab3db66dd34f707d47e74bf445055adf1303fc5371782c690228ee28`.
  Its manifest also binds readable TypeScript, declarations, map source files,
  provider/codec dependencies and README. Integrity receipts are not proof terms.

The complete earlier-source Arena run [39552920736](https://github.com/dwijayuda/pskernel/actions/runs/39552920736)
at `e2226eafee06d872f536667e449883d0eafbef5f` finished **FAIL qualification**:
193 evaluated, 167 matching outcomes (103 admissions, 56 kernel refusals, one
metadata refusal, seven transport refusals), two explicitly classified
unsafe/partial safety-contract agreements and the same 24 host timeouts.
No timeout was resolved or newly introduced relative to the previous recorded
24-case set. Its official reference passed 122 acceptances / 71 rejections /
zero timeouts. Comparison artifact 12325647052 has zip SHA-256
`07f3603ffef2a5df008307bcba291f89c26ed92e47cc6164e6cbdcf38d14d6b5`.

Authentic diagnostic run [39552920831](https://github.com/dwijayuda/pskernel/actions/runs/39552920831)
at that same older source collected four original cases, all still timeout both
unprofiled and profiled under 60 seconds / 2 GiB / fuel 4096. Kernel entry occurred
after 192 ms (repeated-subproblem), 179 ms (Church), 1,915 ms (Init) and 341 ms
(stuck-Prop projection). Named V1 HasFVar frames dominate the repeated-subproblem
profile; V1 recursor/WHNF/DefEq and runtime generator/WeakMap traffic dominate the
other profiles. The profile does not distinguish the HasFVar logical callers.
Removing redundant inference eligibility scans is therefore one measured-mechanism
candidate, not a claimed timeout solution. Profiled VmHWM samples are lower bounds:
343,456 / 529,800 / 1,048,248 / 513,056 KiB in that order. No heap-exhaustion
conclusion follows. Diagnostic artifact 12324932888 zip SHA-256:
`a148d87d408981df3ce0f16f717feef8d3386e363a9941ee4cd7420929a836ba`.

Next executable gate: run the containing source through native/generated
integration, canonical .ps correctness, six research jobs, full 193 Arena and the
four authentic profile cases. Compare complete outcomes before making performance
claims. If timeouts remain, attribute the remaining V1 recursor/WHNF scans rather
than repeatedly tuning this same cache predicate. Full V2 and full Arena gates
remain open; four whole-operation fallback sites and boundary decoding remain.

## Evidence identity and history

This file is the current summary. [The complete earlier work-state](history/AI_WORK_STATE_2026-10-21_BEFORE_PROVIDER.md) is retained verbatim; its historical “pending” sections do not override the receipts below. A manifest or an earlier green source does not qualify a later commit. Final qualification must use terminal Actions results for the exact source SHA.

## Implementation checkpoint being qualified

This revision adds the default-fuel native/generated canonical-admissions provider and deployable artifacts, advances the one DAG DefEq owner through proof irrelevance, threads same-batch declaration IDs into public DAG DefEq, and introduces authentic Arena timeout profiling. The unchanged original checker remains selectable and remains the provider's declared checked algorithm. The new DAG slice does not make V2 the default.

The retained implementation commits are `2df356a48e92a1fa46e59306f913985a83db0f92` (authentic Arena profiles), `ce7a92d8f7206fd05dba33a89930afa4ddb51fef` (DAG proof irrelevance with 1,350 native/generated comparisons), and the containing provider/integration commit. These commits are source identities, not test receipts.

The foundation commit is `0987be5a059fc6698541a5d376cf98c814b6fd80`: exact extraction of the existing wire constructors into a dependency without prelude loading or resource mutation; complete legacy package dependency/integrity maintenance; and source-bound SHA-256 manifests including source-map source files. Native executables are packaged in a tarball to preserve execute permissions. Canonical artifacts include the complete generated .ps workspace.

The provider is implemented in `host/kernel-provider/KernelProviderMain.lean` and `scripts/pskernel-canonical-provider.mjs`, documented in `PROVIDER.md`, and tested by `scripts/pskernel-provider-smoke.mjs`. It starts from an empty checked session and returns no partial environment. The 24 process cases copy the executable/runtime closure into a fresh detached directory and run with PATH empty; process failure or timeout is never a semantic rejection. `test/PsKernelProviderOfficial.lean` checks the exact valid four-declaration batch and four semantic negatives through official Lean with `doCheck=true`. Unknown transport fields (including unsafe/recursor/environment metadata) are declined; missing required fields and invalid numeric encodings are malformed. The transport scope is safe regular definitions, theorems and checked inductive groups.

**New-source qualification is pending terminal CI for the containing integration SHA.** Older PASS rows below are source-specific. The new native and generated proof-irrelevance matrices, strict provider negative tests, canonical full-closure checks, local proof gates, original regressions, full comparison and authentic diagnostic profiles must execute before their respective readiness claims are promoted.

The new profiling workflow is diagnostic only: it preserves original authenticated bodies, default fuel 4096 and the generated host limit of 60 seconds / 2 GiB. Producing a profile or a diagnostic artifact never qualifies an Arena case.

### Execution-tool interruption and recovery

Child-agent GitHub tree writes twice failed to return receipts after approximately 1,013 and 733 seconds. No branch update was attempted by those calls. The calls were interrupted, the complete source was transferred to the parent, and parent-owned GitHub writes returned tree/commit receipts. All repository work remains GitHub-only; no local checkout, build or test was substituted. Future writes use the parent tool path and fresh non-force expected-SHA updates.

## Guard and transport correction after 8f09068

At exact `8f09068526b843edcf0966db1c1c1211eddae31c`, [native integration job 119068266604](https://github.com/dwijayuda/pskernel/actions/runs/39553651256/job/119068266604) compiled all targets and passed the original DAG matrices, inference-only regressions, transformations, and the new **1,350 proof-irrelevance comparisons plus eight official positive pairs and one invalid-input control**. It then **FAILED** the retained theorem `dag_quick_defeq_depth_error_precedes_syntax` in PsKernelCacheScopeProofs.lean:197.

The theorem exposed an actual compatibility-wrapper ordering defect: the new unsupported external-local branch could hide an already-exhausted scalar depth guard. The containing revision restores that guard before the compatibility fallback. The original theorem is retained unchanged, with additional native/generated external-local depth sentinels. The guard computes no published context; the existing owning worker still enters depth exactly once.

The Unicode transport audit found two lossy decoding behaviors: Node's ordinary UTF-8 string decoding replaces invalid byte sequences, while the pinned Lean JSON parser replaces unpaired Unicode escape surrogates. Both providers now reject malformed UTF-8 and unpaired surrogate escapes before conversion. A linear lexical guard preserves valid surrogate pairs, literal backslash-u text and actual U+FFFD. Six new process controls exercise three malformed and three valid forms, bringing the detached provider suite to 24 cases. This changes host transport validation, not kernel semantics or resource policy.

Native correctness [119068267673](https://github.com/dwijayuda/pskernel/actions/runs/39553651416/job/119068267673) passed at 8f09068. Its official Arena reference [119068266675](https://github.com/dwijayuda/pskernel/actions/runs/39553651194/job/119068266675) passed all 193 cases (122 accepted, 71 rejected, zero timeouts). Generated/full Arena and canonical integration were still running at this update. The old e222 generated integration API reported the proof-irrelevance and 16-case provider steps successful; that older protocol lacks the new strict-binder/Unicode controls and is not promoted.

The in-progress generated job log exposed an early 2.12-MB prefix after later steps had advanced. Successful per-assertion `PSC1_DAG_PASS` console lines are now filtered after `tee`; the complete assertion output remains in the uploaded log, all tests and required markers still execute, and errors plus aggregate receipts remain visible. No test omission or pass inference is introduced.

## First integrated execution receipt: e2226ea

At exact `e2226eafee06d872f536667e449883d0eafbef5f`, [native correctness job 119065961654](https://github.com/dwijayuda/pskernel/actions/runs/39552920733/job/119065961654) passed. The production DAG modules, including the new CheckCore and proof-irrelevance continuation, compiled. Authentic PSC1 source checking in integration job 119065962179 also passed before generated compilation began.

[Native integration job 119065961963](https://github.com/dwijayuda/pskernel/actions/runs/39552920804/job/119065961963) **FAILED compilation** on two layout defects: multiline host return-constructor arguments at KernelProviderMain.lean:106 and a multiline official-axiom fixture record at PsKernelExprV2ProofIrrelevanceRegression.lean:143. The containing revision fixes the layout without changing semantic assertions. Provider review also found inherited-property binder tags in the shared wire decoder; explicit own-property membership and native/generated refusal cases for `constructor` and `__proto__` now close that transport hole.

[Research WHNF job 119065962045](https://github.com/dwijayuda/pskernel/actions/runs/39552920726/job/119065962045) failed before source compilation because the pinned Lean archive download reported TLS error 35. GitHub refused a targeted retry while the containing workflow was running (403: workflow already running). The containing revision installs the same pinned toolchain with three bounded download/install attempts, verifies its exact commit, and still runs every original gate. No test or toolchain pin was relaxed.

[Official Arena job 119065961893](https://github.com/dwijayuda/pskernel/actions/runs/39552920736/job/119065961893) passed all 193 cases: 122 accepted, 71 rejected, zero timeouts; generated comparison and authentic diagnostics were still in progress at this source update. This is an official reference result, not independent generated parity.

## Verified starting checkpoint

The branch was fetched at `49a5df0820216db35c3cbf562172b754b82a03b1`, three commits after the earlier green `38dfe75658a1d723b993904a8d510fb449e6bba0`. The material changes were the ordered DAG DefEq prefix, unsafe/partial mutual admission with fresh per-member owners, and a native test record-layout correction. No newer valid work was reverted.

At `56559c794a93e828cb89ded1b0ed535f93570b69`, [generated integration 39539663203](https://github.com/dwijayuda/pskernel/actions/runs/39539663203/job/119024254755), [both correctness jobs 39539663174](https://github.com/dwijayuda/pskernel/actions/runs/39539663174), and [all six research jobs 39539663281](https://github.com/dwijayuda/pskernel/actions/runs/39539663281) passed. The native integration job failed to parse a test fixture at line 4227; this was a fixture syntax defect, not a passing native qualification. The canonical gate reconstructed **120 modules**, audited **163 portable modules across two roots**, independently checked and compiled the complete .ps closure, and executed its real checker with PATH empty.

At `49a5df0820216db35c3cbf562172b754b82a03b1`, [native integration job 119045258568](https://github.com/dwijayuda/pskernel/actions/runs/39546338992/job/119045258568) passed the full native matrix, including all 280 mutual cases, eight checked official mutual fixtures, fresh-member sentinels, binder/prefix/unsafe/theorem rules, local proofs and benchmarks. The corrected native fixture is the only source difference from 56559c7.

Both jobs in [integration run 39546338992](https://github.com/dwijayuda/pskernel/actions/runs/39546338992) are now **terminal PASS at the same 49a5df0 SHA**. Generated execution passed all semantic markers, 1,008 inference-only comparisons, 128 guarded operation observations, 24 admission observations, strict whole-executable checks and all six profiles. The compiler emitted 5,921,796 bytes of JavaScript plus declarations and maps. Native and generated mutual-definition qualification is no longer pending.

| Exact SHA | Native integration | Authentic portable .lean | Canonical .ps | Generated JS | Local proofs | Full integration benchmarks | Full Arena | New provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `56559c794a93e828cb89ded1b0ed535f93570b69` | FAIL (fixture syntax) | PASS | PASS | PASS | NOT RUN (blocked native job) | NOT RUN (native); PASS (JS) | FAIL (24 timeouts) | NOT RUN |
| `49a5df0820216db35c3cbf562172b754b82a03b1` | PASS | PASS | NOT RUN | PASS | PASS | PASS | NOT RUN | NOT RUN |

The 49a5df0 fixture-only commit did not trigger canonical, correctness, research or Arena workflows. Their earlier green results are recorded for their own SHAs, not inherited. The next implementation push explicitly re-runs every required gate.


## Full Arena remains incomplete

[Latest completed full comparison 39539663267](https://github.com/dwijayuda/pskernel/actions/runs/39539663267) at `56559c7` evaluated all **193** cases:

| Recorded outcome | Cases |
| --- | ---: |
| Matched kernel acceptance | 103 |
| Matched kernel rejection | 56 |
| Matched metadata rejection | 1 |
| Matched transport rejection | 7 |
| Explicit unsafe/partial safety-contract agreement | 2 |
| Host timeout (60 seconds, 2 GiB) | 24 |
| Total | 193 |

The timeout set contains **19 official acceptances and five official rejections**. All 24 timeouts reached the public RunDag kernel-admission boundary; snapshots do not distinguish validation, decoding and admission internals. Official Lean's corresponding reference job passed **122 accepted / 71 rejected / zero timeouts**. Body bytes remain authenticated with the historical header adapted to the 4.35 pin. The independent gate correctly failed. Neither the 167 matching outcomes nor the two contract agreements mean 169 independently admitted proofs.

The recorded timeout set is preserved by case number and exact archive entry:

| Case | Archive entry | Official outcome |
| ---: | --- | --- |
| 14 | `bugs/proj-of-stuck-prop.ndjson` | rejected |
| 15 | `bugs/proj-of-subst-prop.ndjson` | rejected |
| 17 | `bugs/rec-missing-ih.ndjson` | rejected |
| 18 | `bugs/rec-of-subst-prop.ndjson` | rejected |
| 24 | `perf/refute-cheap-last.ndjson` | rejected |
| 73 | `init-prelude.ndjson` | accepted |
| 79 | `perf/app-lam.ndjson` | accepted |
| 80 | `perf/args-before-unfold.ndjson` | accepted |
| 81 | `perf/beta-ladder.ndjson` | accepted |
| 82 | `perf/church-numerals.ndjson` | accepted |
| 83 | `perf/discarded-argument-match.ndjson` | accepted |
| 84 | `perf/discarded-argument.ndjson` | accepted |
| 85 | `perf/folded-constant-first.ndjson` | accepted |
| 86 | `perf/folded-constant-last.ndjson` | accepted |
| 87 | `perf/fueled-chain.ndjson` | accepted |
| 88 | `perf/grind-ring-5.ndjson` | accepted |
| 91 | `perf/let-ladder.ndjson` | accepted |
| 92 | `perf/magma-list-deep-n21.ndjson` | accepted |
| 93 | `perf/magma-list-deep-n36.ndjson` | accepted |
| 94 | `perf/magma-list-pair-n21.ndjson` | accepted |
| 95 | `perf/magma-list-pair-n7.ndjson` | accepted |
| 96 | `perf/repeated-subproblem.ndjson` | accepted |
| 97 | `perf/shared-subterm.ndjson` | accepted |
| 99 | `perf/unroll-versus-evaluate.ndjson` | accepted |

## Deployment and architecture gates

- **A — usable developer kernel:** current source/provider changes must pass native, full portable closure, canonical .ps, generated JS and independent provider CI at the same final SHA before this is marked achieved.
- **B — complete DAG replacement:** **NOT ACHIEVED**. Legacy decoding, external-session declaration types, general DefEq continuations, recursor/iota and inductive admission still require work. V1 remains separately available and the default/reference contract.
- **C — complete Arena compatibility:** **NOT ACHIEVED**, with 24 unresolved host timeouts in the latest completed complete comparison.

The native and generated providers must own their sessions, check every supplied declaration, and publish a batch result only after complete checking. Resource exhaustion, unsupported transport and internal errors are distinct from semantic rejection. The old npm-runtime prelude entry that raises fuel to 131072 is not the new provider entry point.

## Performance interpretation

The complete 56559c7 generated integration recorded all **128** guarded operation observations, **24** admission observations and six diagnostic profiles. On the same runner, unique-function WHNF128 was **1375.926–1387.380 ms V1 / 603.417–625.091 ms DAG**, and collision WHNF128 was **3746.170–3763.454 / 2608.680–2626.384 ms**. These supersede the earlier timing regressions for these fixtures only. They do not isolate the scanner refactor's causal effect.

Construction remains more expensive: the five-input unique pool cost **2.393–2.422 ms V1 / 77.926–78.772 ms DAG**; retained heap is mixed. Complete safe-admission warm mean ratios on six selected fixtures range **8.77×–17.58×** in this run. These are workload-specific observations, not a whole-kernel or Arena speedup claim. Preserve the raw run logs and artifact receipts when comparing later changes.

## Remaining whole-operation fallback inventory

There are **four explicit V1 whole-operation fallback sites**, counted as public operation families (not as every internal `Option.none` rule):

| Operation | Owning file and fallback |
| --- | --- |
| Checked expression inference | `API/Dag.lean`: `psKernelDagCheckTerminalOrOriginal` calls `psKernelV1CheckExpression` |
| WHNF | `API/Dag.lean`: `psKernelDagWhnfExpression` calls `psKernelSessionWhnf` |
| DefEq | `API/Dag.lean`: `psKernelDagIsDefEq` calls `psKernelSessionIsDefEq` |
| Declaration admission | `API/DagAdmission.lean`: `psKernelDagAdmitDeclaration` calls `psKernelV1AdmitDeclaration` |

The entry boundary still validates then decodes the complete arena into physically shared recursive expressions; checked inference and WHNF decode new result nodes; declaration requests are decoded before their direct admission attempt. Moving proof irrelevance into the DAG owner removes one unsupported rule family, not these four fallback sites. General lazy delta/full-shape/eta rules, recursor/iota, externally owned environment types and direct inductive admission remain incomplete.

## Formal status and remaining work

Local metadata, scope/cache guard, numeral recurrence and scanner equivalence lemmas pass at the native checkpoint above using the previously approved proof-file dependencies `propext`, `Classical.choice`, and `Quot.sound`. They do not introduce kernel runtime axioms and do not prove global soundness, validated-arena correspondence, full substitution refinement, DefEq or admission.

Continue through the real highest-priority failing gate. Keep complete V1 fallback until each replacement is qualified; preserve exact recursive fuel/depth/callback placement, cache owner scope, failure order and atomic publication. Do not merge, publish npm, increase policy limits or count a timeout as rejection.
