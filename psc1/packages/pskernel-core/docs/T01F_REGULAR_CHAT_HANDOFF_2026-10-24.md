## 2026-10-24 final native Knot proof failure; universal-lemma bridge in narrow preflight

Final source `ce5747574230e009705372f36da80978060a78ad`, integration
[run 40032581038](https://github.com/dwijayuda/pskernel/actions/runs/40032581038),
attempt 1, FAILED its native job `120684188035`. Four existing proofs in
`test/PsKernelKnotFuelProofs.lean` no longer closed by definitional equality:
`WhnfWithFuel_delayed_recursion_preserves`,
`WhnfCoreWithFuel_delayed_recursion_preserves`,
`WhnfCoreWithFuel_full_mode_preserves_historical`, and
`InferCoreWithFuel_delayed_recursion_preserves`.
The log reports 12 standard-only Knot proofs and four failed proofs with
`sorryAx`; the gate rejected them. The later seven new cache-analysis and
eleven scalar-hash proof invocations were NOT reached in this final job.
Do not inherit their a069 narrow PASS as a final-source native PASS.

All 39 native artifact files were independently inspected. Artifact
`12536115592`: 33,288,730 bytes, SHA-256
`8e8a530cb2c26eed28dcf55cd32f9be69104d2fc00721fc80d87375b751e49b5`.
Full failing goals, proof reports, source/run/attempt and upload bindings:
`docs/evidence/2026-10-24-t01f-final-knot-proof-failure.json`.
The same job's native String 294-admission / 377-metadata / six-sample controls
passed, but this does not qualify the failed job. Canonical native job
`120684187642` in run `40032580944` passed its separate 62 cases.
Other ce574 jobs/results remain bound to that source and attempt; no final
acceptance or integration follows from them.

The containing correction changes only four proof scripts, adding rewrites
by the already proved `semantic_map_get_eq` or `infer_map_get_eq`.
All 16 original theorem statements, printed axiom names, and the entire
102,675-byte frozen reference-worker region remain byte-for-byte unchanged.
The native-only proof module is built explicitly before the Knot test imports
it; it does not enter the portable kernel closure. Production Lean, seven
new universal statements, eleven scalar-hash proofs, fixtures, generated
matrices, String harness and resource limits are unchanged.
Independent static preservation review:
`docs/evidence/2026-10-24-t01f-knot-bridge-independent-review.json`.
This is a proposed proof repair, not a claimed Lean PASS.

All five full work-branch push triggers are PAUSED again. One native-first
narrow push is active and now checks the 16 retained Knot reports as well as
the original 92 reports: exactly 108 total, with forbidden axioms rejected.
Only after this prerequisite succeeds may its bounded 1,884 matrix, strict
body checks, complete producer, controls and exact 1,400-assertion mixed
runtime proceed. Follow that one new coherent candidate; do not rerun the
failed ce574 attempt or mix its receipts with a successor.

Retain the stricter final six-shard gate: 1,400 assertions per sample and
8,400 executed assertions per route, explicitly including repeated prefixes.
After a complete corrected narrow pass, activate one new exact final source
for both routes and all retained gates. T01F/current A/B/D remain OPEN; C FAIL.
No T05 or integration advancement is claimed. Integration remains last observed
at `123c41197950b6761be965fd21c57142ee2b0d1c`; fresh-read both refs before writes.

---

## 2026-10-24 complete closed-cache narrow PASS; exact final qualification activated

Exact source `a069080c35df3d5a19b06e133f9fa33ffabbb35b` completed
[run 40000313458](https://github.com/dwijayuda/pskernel/actions/runs/40000313458),
attempt 1, SUCCESS. All four jobs and all 51 files across their four artifacts
were independently checked against terminal logs, source/run/attempt bindings,
ZIP digests, copied repository inputs, and producer provenance.

- Native `120574391043` PASS: 92 proof reports (60 scope + 14 session +
  11 unchanged scalar-hash + seven new universal cache-analysis equivalences),
  permitted standard axioms only; frozen scalar controls, 294 ordered
  independent admissions, 377 metadata comparisons, all six native String
  samples/singletons, and retained DAG/session/owner controls.
- Producer `120575437160` PASS: bounded authentic PSC1 -> TypeScript 7.0.2
  -> JavaScript, exact 20-expression/two-state/1,884-assertion matrix, frozen
  2,730 cases / 8,190 stages / 13,665 assertions / three long cases and
  19-case / 38-assertion short controls. Strict generated-body gates executed
  before complete SelfHost source checking and complete kernel production.
  The new bounded worker has one export, 11 recursive scheduler sites, no
  old ExprHash/HasFVar calls, recurry or result wrapper. Independent static
  inspection also verified the full-kernel worker; this is not a claim that
  its separate full-body workflow guard executed.
- Retained controls `120585878049` PASS: full-kernel 1,884 matrix, frozen
  scalar checks, DAG/minimal String, generated-prefix and session-owner
  controls. DAG 136.86 s / 559,496 KiB peak RSS; prefix 31.35 s /
  405,572 KiB. These are observations, not a general speedup qualification.
- Mixed `120585878070` PASS: the complete `Aé€😀` sample, exactly 1,400
  executed assertions, 440/440 ordered matching calls, 294 independent
  admissions, 377 metadata comparisons, singleton and all original negatives.
  Timed process 1,470.54 s / 1,105,892 KiB peak RSS / exit 0. Whole job
  1,498 s, only two seconds inside the unchanged 25-minute cap. Preserve
  this narrow margin; do not claim robust performance qualification.

Complete kernel: 9,986,116 bytes, SHA-256
`7e71b0dbbd62405744454aab66413ccbcd5e797996a9cd68f80a2219c5ebe528`.
Fixture: 2,791,525 bytes, SHA-256
`563d6ef138271a13039764257407ee8b66190bca02c8057489d3b1c45f51e71d`.
The String harness and fixture producer remain unchanged. Lean 4.35.0 commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, TypeScript 7.0.2,
Node 22, fuel 4096, old-space 2048 MiB and empty PATH are preserved.
Old-space is not a hard RSS limit.

Durable evidence:
- `docs/evidence/2026-10-23-t01f-closed-cache-analysis-option-native-gates.json`
- `docs/evidence/2026-10-24-t01f-closed-cache-analysis-generated.json`
- `docs/evidence/2026-10-24-t01f-closed-cache-analysis-controls.json`
- `docs/evidence/2026-10-24-t01f-closed-cache-analysis-mixed.json`
- `docs/evidence/2026-10-24-t01f-closed-cache-analysis-narrow.json`

This containing commit activates ONE new exact final source: restore the work
branch push on the integration, correctness, research, full-193 Arena, and
Arena-profile workflows; make the narrow workflow manual-only. Other diagnostics
remain manual-only. Fresh-read all five workflows and both branch heads before
this activation. The saved integration draft is synchronized. The shard gate
now requires exactly 1,400 assertions per selected sample and 8,400 executed
assertions per route, explicitly including repeated prefixes.

Follow this containing commit's five runs, attempt-bound; do not dispatch
duplicates or transfer a069's narrow results to the new final source. Require
BOTH strict six-shard `PSC1_T01F_FULL_STRING_SHARDED_JS: PASS` aggregates,
complete independent admission/metadata/original negatives, 24 CLI + eight API
provider controls per route, frozen 32-worker/384-call owner controls, and all
retained native/official/proof/research/measurement/Arena/profile results.
Keep C and D outcomes separate. T01F/current A/B/D remain OPEN; C remains FAIL
while final qualification is pending. No integration or T05 advance is claimed.

After exact scoped qualification, fresh-read integration and preserve concurrent
history with a non-force expected-SHA update to the exact qualified source,
not an untested documentation child. Then continue T05 ordinary DAG inductive
admission. Integration was last verified at
`123c41197950b6761be965fd21c57142ee2b0d1c`; fetch it again before writing.

---

## 2026-10-24 correct generated Option representation in the 1,884-assertion matrix

Exact source `cfed23ce187f170b10b0f0e9822b231da5dfe7b8`, run
`39999069751`, attempt 1: native job `120570117704` PASS. All 92 proof
reports, frozen scalar controls, 294 ordered independent admissions,
377 metadata comparisons, six native String samples and retained controls
passed. Native artifact `12520948002`: 107,781 bytes, SHA-256
`4aca6b162f9d3f3c46414ed8c56bef1980272f29cedf76eb75cfb764f3ac235d`.
All eight files and source/run/attempt/upload bindings were independently
verified: `docs/evidence/2026-10-23-t01f-closed-cache-analysis-typed-native-gates.json`.

Generated job `120571100205` compiled the bounded CacheAnalysis module
through authentic PSC1 -> TypeScript 7.0.2 -> JavaScript. The frozen
2,730-case / 8,190-stage / 13,665-assertion matrix, three long cases and
19-case / 38-assertion short matrix PASS. The new matrix then FAILED at
`small map representation`. Bounded artifact `12521596518`: 69,884 bytes,
SHA-256 `5cddfa7cf931495162a120ee68c489a3b05d1e2b04a6bbdc881ddccd84eee15e`.
All six artifact files were independently verified. Failure evidence:
`docs/evidence/2026-10-23-t01f-closed-cache-analysis-option-matrix-failure.json`.

The actual emitted generic constructor is
`"none": () => ({ [__ps$tag$1]: "none" })`; each call allocates a fresh object.
The unchanged old cache produces this exact constructor when staying small
or returning a miss. Comparing two such allocations with `===` is an invalid
oracle. This containing harness-only correction uses the existing
`Reflect.ownKeys` structural comparator, retaining the actual private tag
Symbol's identity and exact fields. Indexed representation checks explicitly
require the authentic `Option.some` shape. Pair insertion also checks
`inserted.value === set` when the old operation returns the original set.
There are still exactly 20 expressions, two states and 1,884 assertions.
Production Lean, all proof statements/scripts, original tests and limits
are unchanged by this correction.

Independent static inspection of the complete bounded worker found one export,
11 recursive scheduler sites, no old ExprHash/HasFVar calls and no recurry or
result wrapper. Evidence:
`docs/evidence/2026-10-23-t01f-closed-cache-analysis-body-static-inspection.json`.
The workflow body guard itself did NOT execute after the matrix failure;
neither did the complete producer or runtime. Do not treat this inspection
as a workflow PASS or claim full T01F qualification.

Follow ONE new exact narrow source through every prerequisite and full mixed
runtime (exactly 1,400 assertions, unchanged 25-minute cap). All five final
qualification triggers remain PAUSED; diagnostics remain manual-only.
T01F/current A/B/D remain OPEN; C remains FAIL. No integration or T05 advance.

---

### Validated portable source forms for the saved recipe

The implementation is now committed and its seven universal statements have
passed natively. Retain the explicit native module root in
`psc1/kernel-lakefile.lean`, the local `flag` binding in the worker's letE
case, typed `nextCache : PsKernelExprMap` and
`nextSet : PsKernelExprPairSet` record bindings, and
`afterFailure : PsKernelCheckerState` in DeltaStep. PSC1 requires these source
forms; previous parse/elaboration failures are recorded separately.

Where the historical recipe below says to preserve `Option.none` identity,
preserve the authentic constructor's private Symbol identity and exact
structure. The actual generic constructor allocates fresh objects, so do
not restore a reference-equality assertion between separate None allocations.
Existing checker state and retained set objects must still preserve their
original reference identity. Do not modify the emitter or kernel to make an
invalid harness assumption true.

---

# T01F handoff — 2026-10-24 Asia/Jakarta

This is an implementation handoff for the authorized public repository
dwijayuda/pskernel. Continue engineering, not another broad architecture audit.
The user requested a new regular-chat prompt before the drafted candidate was
committed. All candidate source/proof/JS/workflow edits from transient buffers
are UNCOMMITTED and UNTESTED. Do not assume any such files exist in HEAD.
This documentation checkpoint changes no production executable.

## Exact current state

Work branch: work/psc1-pskernel-t01f-string-20261022.
Previous HEAD: 7f81d40f3e29a0e4a60d7042d4a926ec7d640e6c
(tree 7d1a8b6b6461268acbae71cf0e55702493808fbb), a diagnostic/docs child.
Current production implementation: b0d560cfbbfd976a9d8338dbd2bd26a4d5614418
(tree e77103a138b818e286ffe7da00b9c12a58bbc63a).
Integration branch: integration/psc1-pskernel-expr-v2-lean435-20261021.
Fresh integration HEAD at this handoff: 123c41197950b6761be965fd21c57142ee2b0d1c.
Fetch both live refs before writes. Never overwrite concurrent changes.

T01F/current A/B/D OPEN; C FAIL. Historical scoped A
9c87f631758862285273ddb0ea0a3987c671022e remains qualified.
No T05 or integration yet. Default V1; full-kernel DirectJS UNSUPPORTED.
Correctness-scoped A may integrate after its own gates, while separate C/D
failures remain honestly recorded; do not require pretending C/D pass.

All FIVE full work-branch qualification pushes remain PAUSED. Narrow hash
workflow push stays active for future implementation changes. This handoff
restores the V1 profile workflow to manual-only. No new runtime is launched.

## Most recent measured results

Run39972883672 at b0:
- Native120479881827 PASS: 85 proof reports, including 11 hash reports,
  only propext/Classical.choice/Quot.sound; frozen2730/native long3,
  all294 independent admissions/377metadata/six genuine native String samples.
- Producer120481013892 PASS: authentic complete PSC1 check and PSC1 to TS7.0.2
  to JS. Frozen2730cases/8190stages/13665assertions/long3 and separate
  19case/38assertion short-entry matrix PASS. Strict scalar helper shapes PASS.
- Controls120488960287 PASS: DAG/minimal String and prefix/session controls.
  DAG107.96s/694292KiB; prefix23.63s/483284KiB. Times lower than previous0fe,
  but peakRSS HIGHER135408KiB/86480KiB. Preserve these regressions.
- Mixed120488960255 CANCELLED at unchanged25minute cap:
  418begins/417ends, interrupted id418 / validity-right / Aé€😀 /
  psKernelV1RunDag, same call as0fe. All294admissions/377metadata and singleton
  pass, but NO complete mixed1400assertion receipt. mixed.memory empty:
  completed wholewalltime/peakRSS UNKNOWN. No T01F acceptance.

Full kernel9966120bytes SHA256
a9c8ff256b1a0e2cd342eee96f4a50f25603ba5e3d648269068fec9f16b4d944.
Fixture2791525bytes SHA256
563d6ef138271a13039764257407ee8b66190bca02c8057489d3b1c45f51e71d.
Frozen fixture producer39734bytes SHA256
63577d336c41727d82d746d49b0144ae212ae7501953e20c3b6df57be73bb663.
String harness27140bytes SHA256
d3672e6105a0ddf04b52774cb841df6f26e755d66915f6cf764929faaddf69a2.

Evidence already durable under docs/evidence/2026-10-23-t01f-:
primitive-short-pairs-native-gates.json
primitive-short-pairs-generated-preflight.json
primitive-short-pairs-mixed-terminal.json

NEW phase diagnostic completed successfully, diagnostic only:
harness7f81d40f/run39979815911/job120503844633, authentic b0 producer reused.
294 independent admissions/377 metadata comparisons, then actual asserted-true
V1 DefEq(Array0(ByteArray0(String0(literal Aé€😀))), genuine UInt8 byte list).
Operation67393.613841ms; whole diagnostic131.84s/677164KiB.
Fixed180second operation deadline, fuel4096/oldspace2048MiB/emptyPATH.
57198 phase-exclusive 1ms CPU samples. All24artifactfiles and copied inputs
independently rehashed, source/run/attempt/provenance and derived17182byte
prefix verified. Artifact12513526454 ZIP5114622bytes SHA256
ea64b3f384422ab106f71a20dbc03a42fa6b04c1d5d36c09084be951c043a0b1.
Full inspection is saved in:
docs/evidence/2026-10-23-t01f-primitive-short-pairs-defeq-phase-profile.json.

Attribute BOTH named and anonymous kernel frames by generated source line to
their enclosing top-level export/implementation, stripping __ps$impl$.
Self samples: ExprHash7442(13.01%), HasFVar6318(11.05%), combined24.0568%;
GC8295(14.50%), NameHash6016(10.52%), scheduler5523(9.66%),
LevelList4894+worker643(9.68%), fullStringHash3478, ShortPairs1008,
genericPairs844: all StringHash5330(9.32%). This supports the NEXT HYPOTHESIS,
not a whole-kernel speedup/qualification claim.

## Immediate next implementation: share closed-cache analysis

Create Runtime/Acceleration/CacheAnalysis.lean importing unchanged Cache and
CachePolicy. Keep old Cache.lean, CachePolicy.lean, Core/Expr.lean,
ScalarHash.lean and all eleven hash proofs byte-for-byte unchanged.

Add psKernelExprClosedCacheAnalysis(expr:PsKernelExpr):Prod Nat Bool.
Universal specification:
  worker expr =
    if psKernelExprHasFVar expr then Prod.mk 0 true
    else Prod.mk (psKernelExprHash expr) false.
Open-expression hash0 is UNUSED; flagtrue excludes the cache.
Preserve HasFVar traversal order and stop at the first free variable:
- bvar index: (mix21index,false).
- fvar: (0,true), without name hash.
- mvar: (mix23(NameHashname),false).
- sort: (mix24(LevelHashlevel),false).
- const: (mix(mix25(NameHashname))(LevelListHashlevels),false).
- app: scan fn then arg; stoptrue; otherwise mix(mix26fnHash)argHash.
- lam: type then body, seed27; ignore displayname/binderinfo exactly asoldhash.
- forallE: type then body, seed28.
- letE: type then value then body, stoptrue; exact old nesting
  mix(mix(mix(mix29typeHash)valueHash)bodyHash)(if nondep then1else0).
- lit: mix30(LiteralHashliteral).
- mdata: body first, stoptrue, then mix(mix31metadata)bodyHash.
- proj: body first, stoptrue, then
  mix(mix(mix32(NameHashtypeName))index)bodyHash.
Use explicit arguments and DATA result, no function-result motive. Worker has
ELEVEN static structural recursive sites (2+2+2+3+1+1), no old ExprHash/
HasFVar calls, no __ps$wrap or compiler _$psc0SH recurry. Scalar hash/name/
level calls and generator scheduling may remain; do not claim a pure loop.

Add four semantic cache helpers:
1. psKernelSemanticExprMapGet(cache,expr):OptionExpr.
   indexNone: old eligibility then old GetIn(expr,small), elseNone.
   indexSome: worker; ifopenNone, else old GetIn and IndexBucket16(index,hash).
2. psKernelSemanticExprMapInsert(cache,expr,value):OptionMap.
   indexNone: oldeligibility then Some(oldMapInsert), elseNone.
   indexSome: worker; ifopenNone; else same bucket/InsertIn/IndexSet16 and
   record small=nil,index=SomeupdatedIndex.
   None means INELIGIBLE; callers return ORIGINAL state object.
3. psKernelSemanticExprPairSetContains(set,left,right):Bool.
   indexNone oldpair eligibility and oldContainsIn; indexSome analyzeleft,
   stopifopen, analyzeright, stopifopen; symmetric pairhash is
   Nat.mod(Nat.add leftHash rightHash)psKernelCacheHashModulus;
   use old Bucket16/ContainsIn exact collision comparison.
4. psKernelSemanticExprPairSetInsert(set,left,right):OptionSet.
   small branch oldeligibility then Some(oldInsert)/None.
   indexed branch same analysis/hash; if bucket already contains pair,
   Some ORIGINAL set; otherwise exact old IndexSet16 of pair cons bucket.
Keep small-list promotion and pair symmetry exactly unchanged.
Lean record fields on separate lines, no commas (portable parser).

Add psKernelInferCacheMapGet(cache,inferOnly,expr) and
psKernelInferCacheMapInsert(cache,inferOnly,expr,value).
Keep old early kind gate: lit alwaysNone; app/lam/forall only ifinferOnly;
allother kinds call corresponding semantic helper.

## Seven universal proofs and generated matrix

New psc1/test/PsKernelClosedCacheAnalysisRegression.lean:
import Lean and CacheAnalysis, namespace PsKernelClosedCacheAnalysisRegression.
Seven theorems, seven #print axioms:
analysis_eq; semantic_map_get_eq; semantic_map_insert_eq;
semantic_pair_contains_eq; semantic_pair_insert_eq;
infer_map_get_eq; infer_map_insert_eq.
For eachhelper show equality to old eligibility guarded old public operation.
Insert expected Some(oldoperation) orNone, including already-present pairs.
analysis_eq inductionexpr; split each child's HasFVar Bool and simp usingIHs.
Map/set proofs cases record, cases index, cases HasFVar flags, simp using
analysis_eq and old operation/policy defs. If Some(if...) versus if(...Some...)
survives simplification, use apply_ite or explicit Bool split, not sorry.
Inference proofs casesexpr/casesinferOnly and semantic helper equalities.
No original theorem weakening; forbidden sorryAx/Lean.ofReduceBool/
Lean.trustCompiler; only previously allowed standard axioms.
Narrow native total expected92=60scope+14session+11hash+7new, if no other
proof reports are added.

New psc1/scripts/pskernel-closed-cache-analysis-smoke.mjs:
real generated constructors/exported empty caches/Option/List, not fake JS
records. Twenty expressions cover all12constructors, closed/open branches,
Unicode names/literals, const levels0/2, let nondep flags, nestedopen.
Two checks perexpr: worker.snd==oldHasFVar; fst==0ifopenelseoldHash.
Build small and indexed map/set using old publicops; seed raw ineligible fvar
entries so semanticguards must exclude even existing entries.
Promote by actual exported psKernelCacheSmallLimit+2 distinct bvar keys.
Four representation assertions (small indexNone, indexed indexSome).
For20expr×2mapstates compare semantic get/insert with old guarded operations;
for bothinferOnlyflags compare infer get/insert with oldinfereligibility.
For20×20pairs×2setstates compare contains/insert with old guarded operations.
Structural comparisons include Reflect.ownKeys (symbol brands/tags), BigInt,
lists/records; preserve Option.none identity.
Expected1884assertions:40analysis+80map+160infer+1600pair+4representation.
Counts expressions20,states2,mapQueries40,pairQueries800,inferQueries80.
Exact marker:
PSC1_CLOSED_CACHE_ANALYSIS_JS: PASS {"expressions":20,"states":2,"mapQueries":40,"pairQueries":800,"inferQueries":80,"assertions":1884,"smallAndIndexed":true,"openEntriesSeeded":true}
Old frozen2730/8190/13665/long3 and separate short19/38 scripts unchanged.

## Checker call sites to recreate

All paths below relative src/Ps/KernelCore/; import new CacheAnalysis.
Preserve all public signatures/fuel/depth/error/owner/scope/publication order.
- Checker/Reduction/WhnfCore.lean:
  WhnfCoreFinish cheapProj returns old state; otherwise match newsemantic
  mapInsert(state.whnfCore,original,result); None retains originalstate,
  Some uses existing StateWithWhnfCore. WhnfFinish analogous state.whnf.
  Replace ONE eligibility-guarded whnfCore get with newsemanticMapGet.
- Checker/Reduction/Whnf.lean: replace TWO guarded state.whnf gets.
- Checker/Inference/Core.lean: replace cached eligibility+get with
  psKernelInferCacheMapGet(cache,inferOnly,expr), preserving depth checks.
- Checker/Inference/Helpers.lean, CacheInferResult: choose inferOnly vs
  checkedInfer cache; newinferInsert; None originalstate, Some existing
  StateWithInferOnly or StateWithCheckedInfer.
- Checker/DefEq/BinderSpines.lean, DefEqFinish: ifvalue then newsemantic
  pairInsert(success,left,right); None (true,originalstate); Some existing
  StateWithSuccess; false retains (false,originalstate).
- Checker/DefEq/Quick.lean: keep entryChecked gate; replace inner guarded
  successpair Contains with semanticPairContains.
- Checker/DefEq/DeltaStep.lean: ONLY failurepair portions.
  IfsameShortcut argsResult: newsemanticPairContains(state.failure,left,right)
  then oldfalse/state else existing DefEqArgs; no shortcut oldfalse/state.
  afterFailure: ifsameShortcut match newsemanticPairInsert(comparedState.failure,
  left,right); None comparedState; Some existing StateWithFailure.
  DO NOT change its unfold-cache eligibility-variable reuse.
DO NOT change unconditional PairSetContains in Checker/Knot.lean: replacement
needs an extra closed-set invariant, not universal pointwise equality.
DO NOT change LazyDelta eager HasFVar checks in this candidate.

## Workflow work and narrow run

.github/workflows/psc1-pskernel-t01f-hash.yml:
- Keep active workbranch push; add newproof/newJS pathfilters.
- Native first: seven-proof count, execute newprooffile, save log,
  reject forbidden axioms. Preserve all old85 reports/nativecontrols.
- Bounded build root CacheAnalysis.lean, output still
  dist/expr-v2/scalar-hash/kernel.js. Frozen scalar/shortchecks unchanged.
- Run new1884 matrix and exactmarker.
- Strict newworker guard: exactoneexport, no _$psc0SH recurry or __ps$wrap,
  no old ExprHash/HasFVar in complete body, exactlyELEVEN self scheduler sites.
  Print whole generatedbody and marker. Do not assume generator-free.
- Existing scalar strict shape guards unchanged.
- Complete genuine SelfHost check/build TS7.0.2, retainedcontrols and full
  mixed follow only after prerequisite gates pass.
- Tighten narrow mixed receipt from positivecount to exactly1400 assertions.
  Limits unchanged. Do not preemptively rerun oldb0.

Update actual full integration + canonical workflows (pushes stillPAUSED):
add newJS detachedcopy/run/exactmarker/artifactlog to both routes; newproof
seven-print/execution/forbidden gate/native artifactlog onintegration.
Sync saved integration draft toactual workflow plus its workbranchline.
Keep original hashguard11 and original tests/owner/provider controls.
V1 profile workflow remains manual-only.
Commit ONE coherent implementation/harness revision via fresh expectedSHA and
nonforce. Follow its ONE new Linux native-first narrowrun; do not duplicate.
Persist actual failed obligations/codegen shapes if any; fix without weakening.
Only after complete native/bounded/fullproducer/controls/mixed PASS proceed.

## Final qualification and integration

After complete narrowPASS, fresh-read allFIVE fullworkflows; restore workbranch
pushes forintegration,correctness,research,arena435,arena435-profile, and make
narrowhash manual-only. Keepotherdiagnostics manual-only.
Strengthen psc1/scripts/pskernel-t01f-shards.mjs:
selected result.assertions===1400; six receipts executedAssertions===8400;
includesRepeatedPrefix:true. 8400 is executed assertions, NOTunique assertions.

Qualify ONE exact newfinalsource with BOTH strict6shard aggregates:
PSC1_T01F_FULL_STRING_SHARDED_JS: PASS.
Eachroute compileonce; runtimeonly6unique samples,1400each,294independent
admissions/377metadataeach, source/run/attempt/route/kernel/fixture/harness/
provider bindings, receipt/log/memory rehash, allsuccess, failfastfalse,
maxparallel2,25minutes/shard. No source/attempt receipt mixing.
Also retain allnative/official/proofs/provider24CLI+8API perroute/research/
wholemeasurements/frozenowner32workers384calls/full193Arena/profile at exact
finalsource. Record separate C/D outcomes honestly. No generalperformance,
backendpreservation or wholekernel soundness claims from these tests.

Frozen owner driverSource4ebfd97b4588f8651e8b7a81bc00b2a05cfe1e3c,
SHA2567c8a82758b90958d973623d26e4c4dfbd900126cd737c190adffb76cb1563221,
marker PSC1_V2_INITIAL_OWNER_BENCH: PASS workers=32 calls=384 sizes=32,128 queries=4.

Only then fresh integrationref/ancestry, preserveconcurrenthistory, nonforce
expectedSHA correctness-only integrate exactqualifiedsource (notdocschild).
Then T05 ordinary DAG inductive admission, later T06/T07/T04a; T04b separate.

## Nonnegotiable operating rules

GitHub Actions Linux ONLY for Lean/compiler/JS/kernel builds/execution/tests.
Local Python ONLY static metadata/ZIP/hash/generatedbody inspection; no local
kernel/test execution. Connected GitHub tools for reads/writes.
Lean4.35.0 exact eb6cafb7290e8bd5f2937522d8d804f58f02bafc;
TypeScript7.0.2, Node22; fuel4096; oldspace2048MiB (NOT hardRSS cap);
emptyPATH; mixed job25min. No mainmerge, forcepush, npmpublication.
Preserve all originalfixtures/assertions/negatives/privateIDs/owners/public
repeatedcalls. Do not transfer narrow/older-source passes to a newfinalsource.
Work autonomously; update AI_WORK_STATE/progress/continuation docs.
If tools unavailable, report preciseblocker and savehandoff; do not fabricate
writes/results or claim continued background work.
