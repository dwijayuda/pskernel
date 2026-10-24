## 2026-10-24 T05 ordinary header candidate after qualified T01F integration

**T01F/scoped A remain qualified only at `0d9f062846d109c362210d441df5fd407ca2cdd7`,
the current integration source. T05 remains OPEN; B remains OPEN, C remains FAIL,
and D remains OPEN.** The preceding work checkpoint is
`1e1fa35d19bc5180eebc3fd19e8638919ec6e06f`. This new entry supersedes older
instructions to wait for T01F qualification: that qualification and integration
are complete, as documented in `docs/T01F_QUALIFICATION_2026-10-24.md` and its
source/run/attempt-bound evidence. It does not transfer those passes to this
new executable candidate.

The first T05 implementation slice adds private ID-native ordinary-inductive
header analysis: uniform occurrences, annotation consumption, parameter and
index opening, and the exact original header guard/checking sequence. It keeps
separate complete parameter/index owners and an explicit constructor-state
accessor that retains parameter semantics/freshness with the index-appended
arena. The two admission EnsureSort helpers move byte-for-byte into a shared
checker module. Public ordinary admission still uses its existing complete
fallback; constructor validation, recursor construction and atomic publication
are not implemented by this slice.

The candidate includes 64 new audited native proof reports (15 structural correspondence
and 49 state/header equations) and a direct-worker matrix requiring exactly
1,992 assertions on each authentic generated route. The structural theorems use
an explicit node/depth/child-reference `ArenaModel`; establishing that model
from successful whole-arena replay validation remains a separate proof
obligation. Header success is not a full ordinary-admission receipt.

**At this checkpoint the T05 candidate is untested.** Its new native-first
`psc1-pskernel-t05-header.yml` workflow must check the proofs, native regression
and official controls before bounded code generation and the expensive complete
generated and canonical PSC1-to-TypeScript-to-JavaScript routes. The existing
1,884-assertion closed-cache matrix and strict generated-body checks remain
prerequisites. Follow one exact candidate run; do not dispatch a duplicate or
combine outcomes across sources or attempts. All five full work-branch
qualification triggers remain paused, and both T01F diagnostic workflows
remain manual-only.

Continue from `docs/T05_ORDINARY_HEADER_HANDOFF_2026-10-24.md`. Fix actual native,
compiler or runtime failures without weakening the assertions or trust audit.
After this bounded slice passes, continue ordinary constructor/positivity,
recursor validation and private publication. Full T05 acceptance still requires
the complete ordinary path and the retained exact-source final qualification
gates before a further integration update. Use connected GitHub operations and
GitHub Actions Linux only for project execution; preserve the pinned toolchain,
resources, history, and expected-SHA non-force updates.

---

## 2026-10-24 T01F qualified at exact 0d9f source and integrated

**T01F and scoped A are qualified at
`0d9f062846d109c362210d441df5fd407ca2cdd7`. B remains OPEN, C remains FAIL,
D remains OPEN, and T05 remains OPEN.** This is the newest status entry;
older failed, incomplete and diagnostic results below remain historical.

Both final routes completed at this exact source, attempt 1:

- [Generated integration 40061694631](https://github.com/dwijayuda/pskernel/actions/runs/40061694631):
  all ten jobs and ten artifacts independently verified. Six complete String
  samples each executed exactly 1,400 assertions; the strict aggregate is
  **8,400 executed assertions, including repeated prefixes**. Mixed whole job
  1,283 s; unchanged-cap margin 217 s; process 1,251.58 s / 1,142,340 KiB RSS.
- [Canonical correctness 40061694623](https://github.com/dwijayuda/pskernel/actions/runs/40061694623):
  all nine jobs and eight artifacts independently verified, including all 68
  archived files. Six complete samples and the strict aggregate passed exactly
  **1,400 assertions per sample / 8,400 executed assertions including repeated
  prefixes**. Mixed whole job 1,027 s; cap margin 473 s; process 1,000.24 s /
  1,194,780 KiB RSS.

Both original `PSC1_T01F_FULL_STRING_SHARDED_JS: PASS` records match their
archived receipts. Every shard independently admitted all 294 requests and
compared all 377 metadata records, with singleton and original negative
controls preserved. Each route passed the exact 1,884-assertion cache matrix
and 24 CLI + eight API provider cases. All 140 canonical reconstructed source
modules plus their manifest were independently verified from the source tar.

The final native gate passed all 232 exact proof reports across sixteen
modules, including the seven new universal cache equivalences, eleven unchanged
scalar-hash proofs and sixteen retained Knot equations. All retained native,
generated, research and frozen 32-worker/384-call owner gates were checked at
the exact final source. No earlier source or attempt supplies a missing pass.

The current-source full Arena run `40061694705` remains **C FAIL**: 173/193
strict matches, 17 timeouts, one reduction-budget exhaustion, and two separate
unsafe/partial contract-difference agreements. Profile run `40061694607`
completed diagnostic collection; Church remains resource-exhausted and
Init.Prelude reaches the fixed 60-second diagnostic timeout. **D remains OPEN**;
the finite DAG/legacy and frozen-baseline comparisons are kept distinct.

Integration branch `integration/psc1-pskernel-expr-v2-lean435-20261021` was
fast-forwarded from `123c41197950b6761be965fd21c57142ee2b0d1c` to the exact
qualified source `0d9f062846d109c362210d441df5fd407ca2cdd7` using `force: false` and
the freshly observed old head as `expected_sha`. Ancestry was ahead 79 /
behind 0 with that old head as merge base. Fresh API verification at
**2026-10-24 05:43:28 UTC** confirmed both branches at the qualified source
and tree. No untested documentation child was integrated.

The detailed record and complete evidence index are in
[T01F_QUALIFICATION_2026-10-24.md](docs/T01F_QUALIFICATION_2026-10-24.md), including independent reconciliation and
source-preservation receipts. Production changes from the requested c775
handoff are exactly the new CacheAnalysis module and seven specified checker
files. All protected cache/hash/core files and production Checker/Knot are
unchanged. No unconditional pair lookup was rewritten using an unproved
invariant.

This containing checkpoint changes documentation, evidence and five work-branch
push triggers only; it does not claim a new executable qualification. Those
five full triggers are paused for the next bounded implementation batch, with
the saved integration draft synchronized. The T01F narrow and phase diagnostic
workflows remain manual-only. Lean 4.35.0 commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, TypeScript 7.0.2, Node 22,
fuel 4096, old-space 2048 MiB, empty PATH, max-parallel two and the 25-minute
mixed/shard cap are unchanged. Old-space is not a hard RSS limit.

**Next executable task: T05 ordinary DAG inductive admission.** Start with the
ID-native ordinary uniform-occurrence/header/parameter/index analysis slice.
Preserve guard order, structural versus checker-fuel bounds, mandatory public
WHNF and complete callback-returned state. Constructor analysis must resume
the parameter owner while retaining the append-only arena required by index
IDs, without importing the index owner's semantic caches/freshness. Keep
whole-admission fallback until constructors, generated recursor types/rules
and atomic publication have qualified ID-native replacements. Do not combine
mutual/nested migration or claim T05 complete from a header-only pass.

Use Actions Linux only for all builds and project execution/tests. Fresh-read
both live branches before changes and use non-force expected-SHA updates to
preserve concurrent history. No main merge or npm publication.

---

## 2026-10-24 complete Knot-corrected narrow PASS; one new final source activated

Exact source `e136c06fb378c7882eaa795366e7a781440588f9` completed
[run 40033825281](https://github.com/dwijayuda/pskernel/actions/runs/40033825281),
attempt 1, SUCCESS. All four jobs and all 52 files across their four artifacts
were independently verified against terminal logs, upload/API ZIP digests,
fresh Git source blobs, source/run/attempt identities and actual producer bytes.

- Native `120688325037` PASS: exactly 108 reports (60 scope + 14 session +
  11 unchanged scalar-hash + seven new universal cache equivalences +
  all 16 retained Knot equations), permitted standard axioms only.
  The four previously failing Knot proofs now close using the universal
  lookup equivalences. Every original statement and the 102,675-byte frozen
  reference-worker region remains unchanged. Retained native controls,
  294 ordered independent admissions, 377 metadata comparisons and all six
  native String cases/singletons passed.
- Producer `120689204789` PASS: authentic bounded PSC1 -> TypeScript 7.0.2
  -> JavaScript; exact 20-expression/two-state/1,884-assertion matrix;
  frozen 2,730 cases / 8,190 stages / 13,665 assertions / three long cases
  and 19-case / 38-assertion short controls; all six strict code-generation
  markers before complete source checking and complete kernel compilation.
  Independent inspection also verified the complete-kernel worker body.
  The bounded workflow guard executed; the separate full-body inspection is
  not described as an executed workflow guard.
- Controls `120694671323` PASS: all 15 artifact files, exact full-kernel
  1,884 matrix, frozen scalar controls, all 43 required DAG markers,
  605 generated-prefix assertions and retained session/owner controls.
  DAG 136.91 s / 559,984 KiB peak RSS; prefix 30.51 s / 490,716 KiB.
- Mixed `120694671292` PASS: the complete `Aé€😀` sample, exactly 1,400 assertions,
  440/440 ordered matching calls, 294 independent admissions, 377 metadata
  comparisons, singleton and all original negatives. Timed process
  1,243.28 s / 1,145,236 KiB peak RSS / exit 0. Whole job 1,273 s,
  leaving 227 s before the unchanged 25-minute cap. This is an observation
  at this source/attempt, not a controlled performance or general speedup claim.

Complete generated kernel: 9,986,116 bytes, SHA-256
`7e71b0dbbd62405744454aab66413ccbcd5e797996a9cd68f80a2219c5ebe528`.
Fixture: 2,791,525 bytes, SHA-256
`563d6ef138271a13039764257407ee8b66190bca02c8057489d3b1c45f51e71d`.
The fresh producer output is byte-identical to a069's production output.
This confirms the proof/workflow-only repair; no runtime qualification
receipt is inherited from a069 or the rejected ce574 source.

Evidence:
- `docs/evidence/2026-10-24-t01f-closed-cache-knot-native-gates.json`
- `docs/evidence/2026-10-24-t01f-closed-cache-knot-generated.json`
- `docs/evidence/2026-10-24-t01f-closed-cache-knot-controls.json`
- `docs/evidence/2026-10-24-t01f-closed-cache-knot-mixed.json`
- `docs/evidence/2026-10-24-t01f-closed-cache-knot-narrow.json`
- `docs/evidence/2026-10-24-t01f-knot-final-activation-review.json`

This containing commit activates one new exact final source by restoring
exactly five work-branch push triggers and returning the narrow workflow to
manual-only. Workflow jobs, proof-library ordering, pins, assertions and
limits are unchanged from the repaired source. The saved integration draft
already matches the activated workflow byte-for-byte. Follow the five
containing-source runs, one attempt each; do not launch duplicates or
transfer the narrow receipt to final qualification.

Require all 232 exact native proof reports, both strict six-shard
`PSC1_T01F_FULL_STRING_SHARDED_JS: PASS` aggregates, exactly 1,400 executed
assertions per selected sample and 8,400 per route including repeated
prefixes, all independent admissions/metadata/original negatives, 24 CLI +
eight API provider cases per route, frozen 32-worker/384-call owner checks,
and every retained native/official/research/measurement/Arena/profile gate.
Retain max-parallel two and the 25-minute shard/mixed cap. Lean 4.35.0 commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, TypeScript 7.0.2, Node 22,
fuel 4096, old-space 2048 MiB and empty PATH remain fixed. Old-space is not a
hard RSS limit.

The rejected final source `ce5747574230e009705372f36da80978060a78ad`
remains unqualified because of its four native Knot proof failures. Its
later observations stay bound to that source and attempt 1:
research run `40032582247` completed all six jobs (four artifacts independently
inspected; the final two terminal logs/API identities checked).
Full Arena run `40032580865` FAILED C: 173/193 strict matches
(105 acceptance, 60 kernel rejection, one metadata rejection, seven transport
rejections), 17 timeouts, one reduction-budget resource exhaustion, and two
separate unsafe/partial contract-difference agreements. All 193 original
bodies and all 199 official + 586 generated artifact files were inspected.
Profile run `40032580974` completed diagnostic collection, not qualification:
repeated-subproblem accepted; Church resource-exhausted; Init.Prelude timed
out at the fixed 60-second diagnostic limit; proj-of-stuck-prop rejected.
All 58 profile files, 49 manifest entries and 88,221 V8 ticks were verified.
C remains FAIL and D OPEN; there is no whole-kernel speedup claim.
The ce574 generated/canonical shard outcomes are historical only, and its
owner comparison was skipped after native failure.

Separate durable receipts:
`docs/evidence/2026-10-24-t01f-rejected-ce574-retained-research.json`,
`docs/evidence/2026-10-24-t01f-rejected-ce574-retained-arena.json`,
`docs/evidence/2026-10-24-t01f-rejected-ce574-retained-profile.json`.

T01F/current A/B/D remain OPEN; C remains FAIL pending its separate findings.
This narrow pass is not full T01F, broad Lean compatibility, performance,
complete V2 or soundness qualification. After the exact scoped final gates
pass, fresh-read both branches and integrate the exact qualified source with
a non-force expected-SHA update preserving concurrent history, not an untested
documentation child. Then continue T05 ordinary DAG inductive admission.
Integration was last observed at
`123c41197950b6761be965fd21c57142ee2b0d1c`; fetch it again before writes.

---

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

## 2026-10-24 typed local cache records after dde99 portable elaboration failure

Exact source `dde99ecf74f78b992031d16d14c6f6986195fcf1`, run
`39998044644`, attempt 1: native job `120566605402` PASS. All 92
reports (60 scope + 14 session + 11 unchanged hash + 7 new equivalences)
use only permitted standard axioms. Frozen 2,730 scalar cases / 3 long cases,
294 ordered independent admissions, 377 metadata comparisons, all six native
String samples, and retained controls passed. Artifact `12521630084`:
107,781 bytes, SHA-256
`dea4ad3e3553a8813d4e18058c248ce3abd221a22743277b20511a52f71f2759`.
All eight files and source/run/attempt/upload bindings were independently
verified. Native-only evidence:
`docs/evidence/2026-10-23-t01f-closed-cache-analysis-portable-native-gates.json`.

Generated job `120567692122` FAILED in bounded PSC1 elaboration:
`psKernelSemanticExprMapInsert: unsupportedTerm`.
No bounded JavaScript, generated matrix/body check, complete producer, or
runtime executed. The secondary artifact-upload failure reflects the absence
of generated files. Complete log digest and terminal metadata:
`docs/evidence/2026-10-23-t01f-closed-cache-analysis-portable-elaboration-failure.json`.

The containing correction gives the two indexed insertion records explicit
local types before passing them to `Option.some`: `PsKernelExprMap` and
`PsKernelExprPairSet`. PSC1 elaborates application arguments before applying
the outer result expectation, so the previous anonymous record was ambiguous
between those two structures. It also annotates the new `DeltaStep`
`afterFailure` local as `PsKernelCheckerState`, supplying the result type
required by its nested match. These are source-form corrections; values,
hashes, guards, collision checks, identity paths, proof statements, fixtures,
counts, and resource limits remain unchanged.

Follow ONE new native-first narrow run for this new source; no earlier PASS
is inherited. All five full work-branch triggers remain PAUSED and diagnostics
remain manual-only. The 1,884 matrix, strict complete generated-body checks,
authentic complete build, retained generated controls, and exactly 1,400
mixed assertions must all pass before activating one final qualification
source. T01F/current A/B/D remain OPEN; C remains FAIL. No integration or T05
advance before the exact scoped qualification.

---

## 2026-10-24 ceee native PASS; portable flag syntax corrected after bounded parse failure

Exactceee310e488b92ae6068faf965cb9c96622976a0/run39997274611/attempt1:
native120563963863 PASS, exactly92reports=60scope+14session+11hash+7new,
all permitted standard axioms, frozen2730/long3,294sequential admissions,
377metadata, six actual String case/singleton samples and retained controls.
Artifact12521075782:107781bytes SHA256
6287f36b8d1a90724b2bb1394b9b68b31d09b2767fc19f235dc4650725ce07e2;
all8files/source/run/attempt bindings independently verified.
Native-only evidence:docs/evidence/2026-10-23-t01f-closed-cache-analysis-native-gates.json.

Generated120565061253 FAILED before bounded output: PSC1 parser rejects the
parenthesized inline conditional in CacheAnalysis letE hash flag at92:28.
No generated matrix, body guard, complete producer or mixed runtime executed.
Actual error:docs/evidence/2026-10-23-t01f-closed-cache-analysis-portable-parser-failure.json.

This containing syntax correction binds the flag with a local let, matching
unchanged Cache.lean. Hashes, eligibility, order, all seven theorem statements,
fixtures, assertion counts and resource limits stay unchanged. Native proof
and all generated gates must run at this NEW source; ceee passes are not inherited.
Follow ONE new narrow run. All five full triggers remain PAUSED; diagnostics
manual-only. T01F/current A/B/D OPEN; C FAIL. No T05 or integration yet.

---

## 2026-10-24 proof-only correction after1902 native proof rejection

Source1902eaad9e7172109955a67b17cfcea690df52f9, run39996684137 attempt1,
native120561914917 built the authentic native targets and passed all85retained
scope/session/hash reports plus frozen2730/long3. Four new universal theorems
elaborated with permitted standard axioms. Three remained incomplete:
semantic_pair_insert_eq and infer_map_get_eq/infer_map_insert_eq. Their actual
reports include sorryAx from unsolved goals; the gate FAILED correctly.
No complete String fixture, generated producer or mixed runtime executed.

Verified artifact12519779027:3778bytes, SHA256
84ccc857f61c87f3863c1f3dfafdee9c6cfd84b1159ea5df7b33eefaf9d35895.
All four contained logs independently rehashed; exact errors and reports:
docs/evidence/2026-10-23-t01f-closed-cache-analysis-native-proof-failure.json.

This containing candidate changes ONLY the three proof scripts plus evidence/
status. Pair insertion splits the actual residual conditional after hash
normalization; inference equations directly apply the universal semantic-map
equivalences after constructor/mode cases. All seven theorem statements,
production source, cache policies, fixtures, assertions and resource limits
remain unchanged. New proof elaboration and all downstream gates are PENDING.
Follow ONE new narrow run, without duplicating1902 or inheriting its results.

All five full work-branch triggers remain paused. T01F/current A/B/D OPEN;
C FAIL. No T05/integration before complete exact-source scoped qualification.
Preserve Lean4.35.0/TS7.0.2/Node22/fuel4096/2048MiB/emptyPATH/25minute cap.

---

## 2026-10-24 native module registration corrected after236a build failure

Candidate236aeb62aeadc6a457dc6c7b0e2f5eb970113600, run39996286431 attempt1,
native job120560537836 FAILED during the initial native build: the isolated
kernel-lakefile explicitly lists module roots and omitted the new CacheAnalysis
module. WhnfCore reported a missing CacheAnalysis.olean. No seven-proof or
retained proof gate, frozen native matrix, complete fixture/runtime, generated
build or mixed runtime executed; no qualification is claimed for236a.

This containing correction adds only the missing native module root and the
kernel-lakefile narrow-workflow path filter, plus this failure record. The
cache-analysis implementation, seven theorem statements/proofs and all generated
assertions remain unchanged. Follow ONE new native-first narrow run for this
corrected source; do not rerun or inherit results from236a.

All five full work-branch triggers stay paused; diagnostic workflows manual-only.
T01F/current A/B/D OPEN, C FAIL. No T05/integration. Exact same-source/attempt
qualification, all old controls and fixed Lean/TS/Node/fuel4096/2048MiB/emptyPATH/
25minute requirements remain. Fresh expected-SHA/nonforce preserves history.

---

## 2026-10-24 shared closed-cache analysis candidate — qualification pending

This containing implementation recreates the saved T01F handoff: one explicit
data-result eligibility/hash worker, four semantic cache helpers and two
inference helpers; seven universal equivalence statements; a generated
20-expression/two-representation matrix requiring exactly1,884 assertions; and
the seven specified V1 checker call-site files. This is a NEW candidate, not
a previously tested transient draft. Native proof elaboration, generated shape,
complete producer, controls and mixed runtime are not yet qualified.

Old Cache.lean, CachePolicy.lean, Core/Expr.lean, ScalarHash.lean and all eleven
scalar-hash proofs remain unchanged. The worker preserves eligibility scan
order and exact closed hashes; semantic comparisons remain authoritative.
None on ineligible insertion retains the original checker state. Small-cache
promotion, scopes, owners, fuel, depth, errors and publication order remain.
Knot's unconditional pair lookup and LazyDelta remain unchanged.

The active narrow workflow requires92native proof reports (85retained+7new),
the frozen scalar matrix and short-entry controls, exact1,884new assertions,
and strict complete-worker generated-body inspection before the authentic
full PSC1/TypeScript7.0.2 producer and unchanged mixed job. The mixed receipt
now requires exactly1,400 assertions. BOTH paused final routes include the new
detached matrix, and the saved integration draft is synchronized.

Follow this candidate's ONE native-first narrow run to terminal; do not launch
duplicates. All FIVE full work-branch triggers stay PAUSED; diagnostics remain
manual-only. Only a complete narrow PASS permits one exact new final source
through BOTH strict six-shard routes (1,400/sample;8,400executed/route, repeated
prefixes explicit) plus all retained gates. No source/attempt pass mixing.

T01F/current A/B/D remain OPEN; C remains FAIL. No T05 or integration yet.
Latest fetched integration123c41197950b6761be965fd21c57142ee2b0d1c; parent work
c775391e13506208a9c7372bd212102b7e9a49e5. The b0 mixed timeout and phase profile
remain source-bound historical evidence. Actions Linux ONLY; pinned Lean
eb6cafb7/TS7.0.2/Node22, fuel4096/oldspace2048MiB/emptyPATH/25min unchanged.
No main merge, force push or npm publication; fresh expected-SHA updates.

---

## 2026-10-24 handoff: b0 mixed FAILED; cache-analysis implementation NOT committed

The user requested continuation in a new regular chat. This containing commit
is a documentation/evidence checkpoint only, with V1profile restored manual-only.
Production remains b0d560cfbbfd976a9d8338dbd2bd26a4d5614418; no new executable
candidate, proof pass, build or runtime run is claimed. Transient drafted
CacheAnalysis/proofs/callsite/JS/workflow buffers were NOT committed.
Recreate them from the complete saved design:

docs/T01F_REGULAR_CHAT_HANDOFF_2026-10-24.md

The completed current-source phase diagnostic39979815911/job120503844633 is
DIAGNOSTIC ONLY. All24artifactfiles/provenance/copiedinputs independently
verified. 57198 phase-exclusive samples; ExprHash7442+HasFVar6318=24.0568%.
Operation67393.613841ms; whole131.84s/677164KiB. Full inspection now durable:
docs/evidence/2026-10-23-t01f-primitive-short-pairs-defeq-phase-profile.json.
Do not turn these observations into a wholemixed pass or speedup claim.

Next: implement shared closed-cache eligibility/hash traversal and sixhelpers,
seven universal proofs,20expression/1884assertion generatedmatrix, seven V1
checker callsitefiles; preserve old Cache/Policy/Expr/ScalarHash/hashproofs.
Use exact detailed recipe in the handoff, not a new broad audit.
Then ONE new native-first narrow Linux run; fix actual failures without
weakening gates. No T05/integration before full T01F acceptance.

AllFIVE full workbranch pushes PAUSED; narrowhash push ACTIVE for future
implementation. V1profile andotherdiagnostics manual-only. No new run here.
After complete narrowPASS: BOTH exactfinalsource6shardaggregates1400/sample,
8400executed/route with repeatedprefix explicit, and all retained gates.
T01F/currentA/B/DOPEN,CFAIL; historical scopedA9c87 qualified.
Integration fresh123c41197950b6761be965fd21c57142ee2b0d1c.
ActionsLinuxONLY; pinnedLean eb6cafb7/TS7.0.2/Node22; fuel4096/2048MiB/
emptyPATH/25min unchanged; no main/npm/force; fresh expectedSHA preservehistory.

---

## Primitive short-pair mixed runtime TIMED OUT; current-source phase diagnostic next

Execution source:b0d560cfbbfd976a9d8338dbd2bd26a4d5614418
(tree e77103a138b818e286ffe7da00b9c12a58bbc63a).
Run https://github.com/dwijayuda/pskernel/actions/runs/39972883672 completed
CANCELLED. Mixed120488960255 ran15:07:20–15:32:41UTC on2026-10-23 and hit
the unchanged25-minute job cap. Actual trace418begins/417ends; interrupted
id418 / validity-right / Aé€😀 / psKernelV1RunDag, the same call as prior0fe.
All294 independent admissions,377 metadata comparisons and mixedsingleton
PASS. No complete mixedcase/1,400-assertion receipt. mixed.memory empty:
completed wholewalltime and peakRSS remain UNKNOWN.

Mixedartifact12511879421 ZIP536942bytes SHA256
906d176cb44968b2ffe1ae64e8ded409364ba97fe963d5f3eb4d30e52d4c0816.
All9filehashes/source/run/attempt/kernel/fixture/harness verified. Complete
trace/partialtimings/exactmetadata:
docs/evidence/2026-10-23-t01f-primitive-short-pairs-mixed-terminal.json.

Native85/hash11 with permittedstandardaxioms, frozen2730/8190/13665/long3,
new19/38, strictpurehelper shapes, authentic complete PSC1/TS7.0.2 producer
and retainedcontrols allPASS forsourceb0, but wholemixed FAILED. Do not promote
these toT01F acceptance or combine older-source results.
Native/all5filehashes:
docs/evidence/2026-10-23-t01f-primitive-short-pairs-native-gates.json.
Producer/control actualmarkers/all15+13filehashes/SIX completehelperbodies:
docs/evidence/2026-10-23-t01f-primitive-short-pairs-generated-preflight.json.
Completekernel9,966,120bytes SHA256
a9c8ff256b1a0e2cd342eee96f4a50f25603ba5e3d648269068fec9f16b4d944.
Controls DAG107.96s/694292KiB andprefix23.63s/483284KiB: observedtimes lower
but peakRSS higher135408KiB/86480KiB vs0fe; preserve memoryregressions.
No causal/general speedup claim; DOPEN,2048MiB is not a hardRSS cap.

The primitive ShortPairs helper genuinely emits ZERO internal generators,
scheduler calls,staging,Step/Mix dispatch and8 primitive transitions. The full
entry selects one of mutually exclusive ShortLeaf/unchangedPair branches at
paircount<=4. Native bounded/entry equalities are genuine; originalgeneral
State/Scan/stagedWorker/partialABI/hashalgorithm/rawcursorsemantics and
LevelListfallback remainunchanged. This verified local optimization has NOT
made the fullmixed workload fit the unchanged resource budget.

THIS containing commit activates ONE current-source V1 UTF8 DefEq phase
diagnostic on the profile workflow's work-branch push. Authenticate sourceb0,
treee771,run39972883672,producer120481013892,artifact12509764996
ZIP1137528bytes/SHA2fafee80d664a5e9793b5baaef8f37e5dd29cd56bb0f10d526b68d029e639df9,
compilerworkflowblob2b72da1028c0e26acd99df333f44d89a3fabca15 and kernela9c8.
Independently admit ALL294 and compare377metadata, then profile the genuine
mixed UTF8-literal V1 DefEq operation under fixed180-second diagnostic
deadline/fuel4096/2048MiB/emptyPATH/Node22. This call measured65,505.647941ms
in the actual failed mixed run; its ofList counterpart63,881.177151ms.
No complete rebuild, fullmixed rerun, qualification or provider promotion.
Follow the ONE new profile run. Inspect current phase frames before choosing
another source-proved optimization; restore profilemanual-only in the next
implementation commit. Other T01F diagnostic workflows remain manual-only.

All FIVE full qualification work-branch pushes stayPAUSED. Narrowhash push
remainsACTIVE for futureimplementation source/proof/workflow changes; this
profile-only commit should trigger ONLY the phase diagnostic. Prepared full
activation buffers were NOT pushed because narrowmixedFAILED.
After a future complete narrowPASS, fetchfreshfullworkflows(hashguard11),
restoreall5,makenarrowmanual-only, enforceexact1400/shard8400executed/route
(repeatedprefixincluded) and qualifyONEnewcoherentsource throughBOTH strict
sixshardaggregates and allretainednative/official/provider24CLI+8API/research/
measurements/frozen32worker384owner/full193Arena/profile. Both full routes
include the separate19case38assertion boundary matrix. Saved integrationdraft
matches actualpausedworkflow after removingits workbranchline; guard11.

T01F/currentA/B/DOPEN,CFAIL; historicalscopedA9c87 remainsqualified.
NoT05/integration. DefaultV1/fullkernelDirectJSUNSUPPORTED.
Integrationlast123c41197950b6761be965fd21c57142ee2b0d1c.
ActionsLinux executionONLY; fresh expectedSHA/nonforce,preservehistory,
no main merge/npm publication. Currentprofileharnesschild is unqualified.

---

## Eight-transition native proof rewrite corrected; narrow check required

Candidate86d72010e4c283b0e8385e2a1df666c4bfbefd1f/run39911503673/native120275329788
FAILED final state_eq_before rewrite: explicit Nat.div/Nat.mod did not match
overloaded division/modulo notation under rw. Octet/composition/remainder/pair
lemmas elaborated, but final theorem/dependents included sorryAx and are NOT
qualified. Generated producer/runtime skipped. Failure log and actual proof
reports: docs/evidence/2026-10-23-t01f-octet-native-proof-rewrite-failure.json.

This containing executable/harness candidate changes ONLY that proof's final
step to congrArg applied to the exact count equality; production8transition
implementation and all theorem statements remain unchanged.
No native/generated proof acceptance yet. Follow this NEW candidate's one
narrow hash run; all five full work-branch triggers remain PAUSED.

Exact2c9 final mixed5 and both aggregates FAILED; ten other shardjobs PASS.
No completed mixedRSS or timing is invented. Source-specific222proof/provider/
owner/research results and C/D failures stay separate.
T01F/currentA/B/D OPEN,C FAIL,historicalscopedA9c87 qualified. NoT05/integration.
After complete narrow native/codegen/controls/mixed PASS, restore full five
triggers and qualify ONE new coherent source through BOTH six-shard aggregates
and all retained gates. No prior-source pass inheritance or duplicate runs.
ActionsLinuxONLY for builds/tests/kernel execution; expected_sha/nonforce,
preservehistory,unchangedfuel4096/2048MiB/emptyPATH/25mincap; no main/npm.

---

## Final pair-counter qualification FAILED; eight-transition candidate in narrow preflight

Exact final source 2c9bf2d2bf7e7cfa9fb5c58585a0671cbf661298 failed BOTH
strict route qualifications. In generated run39900914731 and canonical
run39900914918, samples0–4 PASS1400assertions each. Mixed5 jobs120251078421
and120253647380 cancelled at the unchanged25minute job cap; both independently
admitted294requests, compared377metadata and passed the mixed singleton.
Neither emitted a complete mixed-case marker or receipt. Memory files are
empty: terminal peakRSS/complete wall time are UNKNOWN. Tracing was disabled;
the interrupted API is UNKNOWN. Aggregates120264468016 and120266204053 FAIL
because shard result was cancelled; no full sharded qualification marker.

Failure evidence and authenticated artifact contents:
docs/evidence/2026-10-23-t01f-pair-counter-final-shards-terminal.json.
Generated failed ZIP12481850927 SHA256
1d5ec9a42ff9fad8a2809ad67db439b4038acf80d7f37527d1224eeb2f1e9253.
Canonical failed ZIP12482340395 SHA256
579e3449a12ddabb6449a737d0a1ea88b5c07f362c9b0663c8b402846dd792d1.
Canonical emoji4 passed755.71s/787700KiB,1400assertions; receiptSHA
8c1299fc76a0e021dc9fb9ceaf174b5c5225b1afca75e55851910ec7d4170240.
All prior native222proofs/providers24CLI+8API/owner32workers384calls/research
passes remain source-specific2c9 evidence, not T01F acceptance. C remains FAIL
173semanticmatches+2separateSafetyAgreements+17timeouts+1resourceExhausted;
B/D OPEN. Historical scopedA9c87 remains qualified. No T05 or integration yet.

THIS containing source is an UNQUALIFIED optimization candidate: add a data-result
octet counter with eight inlined immutable Raw.atEnd/get/next transitions and
one structural recursive descent. State divides fuel by8, then executes the
exact remainder through the unchanged pair counter and odd primitive transition.
The frozen19fb worker, modulus65521/mix31/hash semantics/public partial stages,
all existing five equivalence statements, native2730cases/long3 and JS
2730cases8190stages13665assertions/long3 remain unchanged. Three additional
lemmas (octets, iteration composition, remainder) yield eleven hash proof reports.
No generator-free loop, global backend theorem or general speedup claim.
This hypothesis follows earlier phase-exclusive hash21.84% CPU evidence.

All FIVE full work-branch push triggers PAUSED; only narrow hash push ACTIVE.
Require narrow native proofs and unchanged controls, authentic realPSC1/TS7.0.2
bounded and complete code generation, then full mixed1400assertions/294/377/
440calls under unchanged25min/fuel4096/2048MiB/emptyPATH. Bounded code guard
requires exactly one structural block per helper, eight primitive transitions
per octet descent, no staged results/Step/Mix dispatch, exact remainder routing.
Full integration and saved draft hash report count reconciled to11.
One next task: fetch this candidate's ONE narrow run and follow to terminal.
If complete mixed passes, restore FIVE full triggers, make narrow manual-only,
then qualify ONE coherent new source with BOTH strict six-shard aggregates
and all retained gates before T01F acceptance/T05. Do not rerun old final source.
ActionsLinux ONLY for builds/tests/kernel execution, fresh expected_sha/nonforce,
preserve concurrent history. Integration last123c41197950b6761be965fd21c57142ee2b0d1c;
no main merge, force push or npm publication.

---

## Exact2c9bf2d2 BOTH producers/providers/owner/research PASS; C FAIL; shards pending

Qualification source2c9bf2d2bf7e7cfa9fb5c58585a0671cbf661298,
treeea5d79f5927f61a98ad704b09b1ab495ea3701a3; allresults source-specific.
Nativeintegration120242036517 andnativecorrectness120242037072 PASS,
222proofreports/27axiomfree/eighthash/onlypermittedstandardaxioms.
Generatedproducer120242036204 in39900914731 PASS allretainedsemanticgates,
128wholechecker/24admission/36wholeprogram/6profileobservations COMPLETE,
24CLI+8APIprovider PASS. Kernel9956609bytes SHA256
546a14414bd0d97698153e75dd7c580dc8252f50a5a290389e7100ae5da03b04.
Artifact12480106667 ZIP3512034bytes SHA256
a86ac9c68ca414493b6d6246b368f9b2db3e2ab944e69b5b4816ac4779443822.
Canonicalproducer120242036927 in39900914918 PASS genuine .psreconstruction/
realPSC1check/TS7.0.2/retainedsemanticgates/24CLI+8APIprovider.
Kernel9956616bytes SHA256
ecc6854836e2c5ddd754093a67087b708e74cf6f56bcb3b11374e145042b45fe.
Artifact12479809515 ZIP2039580bytes SHA256
d0fdd3dd3abca43ba65f06405dd9ac507a6f25989b02d4a8834af183d26d389a.
FullkernelDirectJS explicitlyUNSUPPORTED by actualemitter; no alternate
fullkernelDirectJS qualification is claimed. Research39900914848 ALL6PASS.

Actualfullworkflowowner120251078372 PASS32workers/384validatedcalls using
unchangedfrozen4ebfd97 driverSHA7c8a82758b90958d973623d26e4c4dfbd900126cd737c190adffb76cb1563221,
baseline9c87/kernel f1ac31f...,candidate2c9/kernel546a144...
60seconds/worker/2048MiB/emptyPATH/allsource-artifact-run-attemptbindingstrue.
Artifact12480435019 ZIP8650641bytes SHA256
a175528f479f477018c05cf4cf269b4eafafdd58a8dcf5eff89087edab052586.
ReportSHA7f3d0de491ccfa8ad27c75606aac6d9c09a239f8392fa6691355820bc1814b7b.
Preserve actualregressions:32owner illtypedcold1.377148772x;128owner
ownedconstant peakRSS+8192KiB. All8rows includingcold/warmmeans/medians,
retainedheap and RSS are preserved; no generalcausalspeedup/threshold/RSSlimit
claim. Cold means first second-batch call AFTER checked setup/V1control,
not first kerneloperation. Prior-source regressions remain separatelyretained.

Full193Arena39900914747/independent120242716137 terminalFAIL:
173semanticmatches(105accept/60kernelreject/1metadatareject/7transportreject),
2separateunsafe-or-partialsafetyagreements,17timeouts,1resourceexhaustion,
zero unsupported. All193bodies individually verified original=adapted and
matchofficialinputdiagnostic hashes,indices0-192unique,noexclusions/reexport,
allcasesrecorded,replayedCases0,fuel4096/60secpercase/2workers/2048MiB/
emptyPATH unchanged. ReportSHA
24c2b496a7c67680845c5905794baca0bfe4c6659fead9303a686390c2bc30f0.
Artifact12480241433 ZIP1081157bytes SHA256
ec30236bcba135326b6c1cbc2807bfea00729d4533241c487b67401f0fabde65.
Authenticprofile39900914830/job120242037123 PASS COLLECTION ONLY:
repeatedsubproblemaccepted;Churchresourceexhausted;Preludetimeout;
stuckprojectionrejected in BOTH unprofiled/profiled;allkernelQualifiedfalse.
Artifact12478933687 SHA256
b298aa1ab71edd91fe787c9bf0a78e395bdf760f521e6672346e8c8b0a5c9272.
These C/D failures do not invalidate historicalscopedA or future scopedT01F.

Complete fresh receipts/measurementmarkers/all193verifiedbodyhashes/all8owner
rows/4diagnostics/provenance+artifacthashes:
evidence/2026-10-23-t01f-pair-counter-final-source-completed-gates.json.
Native222proofrows remain in final-source-native-gates.json.
ONE next task: finish BOTH existing6shardmatrices and theirstrictaggregates.
Generated39900914731:0/1/2PASS,3/4RUNNING,5QUEUED atthissnapshot.
Canonical39900914918:0/1PASS,2/3RUNNING,4/5QUEUED.
Fetch livejobs; doNOTduplicate or rerunpartialattempts.
Require BOTH PSC1_T01F_FULL_STRING_SHARDED_JS: PASS at exact2c9 before T01F/
currentA acceptance. Every selectedsample must execute full1400assertions,
294independentadmissions/377metadata/singleton/negatives and unchanged
4096/2048MiB/emptyPATH/25mincap. Sixroutejobs maxparallel2/failfastfalse.
T01F/currentA/B/DOPEN,CFAIL,historicalscopedA9c87qualified; noT05yet.
No integrationwriteyet;fresh targetintegration last123c41197950b6761be965fd21c57142ee2b0d1c.
ActionsLinuxONLY for builds/tests/kernel execution, fresh expected_sha,
nonforce history-preservingupdates,no main/npm. Docschildunqualified.

---

## Exact2c9bf2d2 native/official gates PASS; both route qualification pending

Qualification source2c9bf2d2bf7e7cfa9fb5c58585a0671cbf661298
(treeea5d79f5927f61a98ad704b09b1ab495ea3701a3).
Integration39900914731/native120242036517 PASS222proofreports,27axiomfree,
allowedunion onlypropext/Classical.choice/Quot.sound; eight scalarhash proofs,
all294/377/authentic6nativeString cases,retainednative/official/control gates,
native24CLIprovider and fullnativeperformanceobservations PASS/COMPLETE.
Artifact12478758116 ZIP33280367bytes SHA256
832e5210ff970fa383c85030b6ab38fa421894d6fc73bf3d48b7c22260e80e7f.
Correctness39900914918/native120242037072 PASS allcore/C0parity/measurements.

Research39900914848 fivejobsPASS:120242037305,120242037319,120242037323,
120242037378,120242037576. Generatedbridge120242037047 stillRUNNING.
OfficialArena39900914747/job120242036227 PASS193bodies:122accepted71rejected,
noexclusions,header-onlyadaptation,no native4.35reexport. Read-onlyaudit verified
ALL193original/adaptedbodySHA256s equal and inputdiagnosticbodyhashes agree;
indices0-192/names unique. Officialreport53d5781a823a86de790eb971995c26fab33501fcfd34c778f117562d9677f65e.
Artifact12479225020 ZIP114902bytes SHA256
dd8f74f575c3e86a8f453a7e0092ff40a1242e311ad65d4af75dc8c0018ce2d9.
This is ONLY officialoracle qualification; PSKernel C remainspending at2c9.
Independentcomparison120242716137 alreadyRUNNING; do notduplicate it.

All222proofrows/nativebenchmarkobservations/C0rows/five researchreceipts,
authenticatedZIP/filehashes and193individuallyverifiedbodyhashes:
evidence/2026-10-23-t01f-pair-counter-final-source-native-gates.json.
Nativefixtureprovenance exact2c9/run39900914731/attempt1/pinnedLeancommit,
294requests377metadata,fixture563d6ef...; Nodeoldspace is null for nativeLean
oracle,2048MiB remainsrequiredfor detachedNodeconsumers. No hardRSSclaim.

Both producers remainRUNNING: integrationgenerated120242036204 compiling fullJS;
correctnesscanonical120242036927 checking reconstructed .ps closure. Their
sixshardmatrices/strictaggregates and unchangedowner32worker384callABBA still
pending. Profile39900914830/job120242037123 RUNNING. Requireallactualresults
at2c9; no9d3fb narrowpass inheritance. Fivefullruns alreadyactive,neverduplicate.
CurrentA/T01F/B/DOPEN,CpriorFAIL/currentpending,historicalscopedA9c87qualified.
One next task: finish these exactsource finalruns and record bothsixshard
aggregates/allproviders24CLI+8API/owner/full193/profile. NoT05yet.
Integration123c41197950b6761be965fd21c57142ee2b0d1c unchanged; ActionsLinuxONLY
for builds/tests/kernelexecution,fresh expected_sha/nonforce,preservehistory,
no main/npm. This documentation child itself inherits no qualification.

---

## Exact final source2c9bf2d2 — FIVE full runs active, qualification PENDING

Qualification executableANDharness2c9bf2d2bf7e7cfa9fb5c58585a0671cbf661298;
treeea5d79f5927f61a98ad704b09b1ab495ea3701a3.
Do NOT use this containing documentation child's HEAD as qualified source.
Existing exact-source runs already started; NEVERduplicate:

- Integration39900914731: generated120242036204/native120242036517.
- Correctness39900914918: canonical120242036927/native120242037072.
- Research39900914848: sixjobs120242037047,120242037305,120242037319,
  120242037323,120242037378,120242037576.
- Full193Arena39900914747: official120242036227; independentjob follows.
- Authenticprofile39900914830:120242037123.

Allinitialjobs currentlyRUNNING,not qualified. Gen/canonical producers must
freshlycompile at2c9bf2d2 before their runtime-only sixshards/strictaggregates.
Require BOTH PSC1_T01F_FULL_STRING_SHARDED_JS: PASS atthis exactsource,
allretainednative/official/proofs/eighthashreports/eachroute24CLI+8API/
research/fullmeasurements/unchangedowner32workers384callsABBA/full193/profile.
All5workbranchfulltriggers active; narrowhash/focus/profile/owner diagnostic
pushes manual-only. Canonical9filemanifest and ownerlivejobsource/run/attempt
guard retained,alllimits/assertions unchanged. No partialrerun may inherit
producer or shard receipts from anotherattempt/source/run.

Prerequisite9d3fb/run39896509889 is ALL4 narrowjobsSUCCESS,including
complete unchangedmixed1400assertions/440calls/1423.67s/1064712KiB. That is
source-specific evidence,not a pass inherited by2c9bf2d2 or this docs child.
Current status snapshot:
evidence/2026-10-23-t01f-pair-counter-final-qualification-active.json.
Exactprerequisite/traces/artifactshashes:
evidence/2026-10-23-t01f-primitive-pair-counter-mixed-terminal.json.
Earlierfe4aa BOTH mixedtimeouts,61deda timeout,27c85 codegenfailure and
higher9dDAG/prefix timings/prefixRSS remainvisible. No generalcausalspeedup/
hardRSSclaim/globalbackendpreservation or soundness claim. DOPEN.

One next task: follow THESE FIVE existing runs toterminal,collect allsource-
bound receipts and bothsix-shardaggregates. CurrentA/T01F/B/DOPEN,CpriorFAIL;
historicalscopedA9c87 qualified. KeepC/D separatefromscopedA acceptance.
NoT05untilfullT01F. No integrationwriteyet; fresh targetintegrationhead
123c41197950b6761be965fd21c57142ee2b0d1c observedunchanged.
ActionsLinux ONLY for builds/tests/kernelexecution,fresh expected_sha,
nonforce updates,preserve concurrenthistory,no main/npm.

---

## Final qualification reactivated after exact9d3fb mixed PASS

Narrow prerequisite executableANDharness9d3fb530e67863017c50470dbd5d06aa388d6184
has terminal run39896509889 ALL4jobsSUCCESS: native120228107597 (82proofs,
eighthash),completeauthenticgeneratedproducer120228660726,retainedcontrols
120234072497,and COMPLETE mixed120234072408.
Mixed294independent admissions/377metadata,1400assertions,all440/440tracecalls,
singleton,allnegative/session/owner controls PASS underunchangedfuel4096/
2048MiB/emptyPATH/25minutejobcap. /usr/bin/time1423.67seconds/1064712KiBpeakRSS;
resulttotal1423528.100563ms,admission42493.374321ms,metadata1415.246222ms.
Mixedartifact12478622243 ZIP538409bytes SHA256
82137768fb09e3435fc40622411012a87efefbd212e103734d6d3827d8b53064.
Exactall440traces,fullreceipt,authenticatedZIP/filehashes:
evidence/2026-10-23-t01f-primitive-pair-counter-mixed-terminal.json.
Kernel9956609bytes SHA256546a14414bd0d97698153e75dd7c580dc8252f50a5a290389e7100ae5da03b04.
BoundedandCOMPLETEcodebothverifyonePairrecursiveinvoke/oneblock/twotransitions,
StateonePairinvoke/oneblock/oneoddtransition,noStage/Step/Mixdispatch.
No generator-free loop/globalbackend theorem/general causal speedup claimed.
HighercurrentDAG/prefix times and prefixRSS vs61deda stay visible; DOPEN.

THIS containing activation is a NEW qualification source and inheritsNONE of
those source9d3fb passes. Workbranchtrigger restored in allFIVE full workflows:
integration,correctness,research,full193Arena,authenticprofile. Every jobbody,
alllimits/assertions,strictsixshardaggregates,canonical9files and corrected
ownerlivejobguard are retained; nativehashproofcount8 alreadyreconciled.
Narrow hash push is nowDISABLED(manual-only); focus/profile/ownerdiagnostics
remainmanual-only. No duplicate fullpreflight builds should be launched.

One next task: fetch this activation commit's exact sourceSHA and its FIVE
already-triggered runs,record IDs,follow all toterminal. Require at ONE source
bothgeneratedandcanonical sixsamples/strictaggregates
PSC1_T01F_FULL_STRING_SHARDED_JS: PASS,allnative/official/proofs,eachprovider
24CLI+8API,research/fullmeasurements,unchanged32worker384callownerABBA,
unchanged193bodyhashes/profile. No partialrerun mayinheritdifferentattempts.
Full193C failures are distinct from scopedA/T01F; retain actualtiming/RSS and
openD obligations. Do not startT05beforefullT01Facceptance. No correctness
integration yet; targetintegration123c41197950b6761be965fd21c57142ee2b0d1c
unchanged,preserveconcurrencywithfresh expected_sha/nonforce updates,no main/npm.
HistoricalscopedA9c87 qualified,currentA/T01F/B/DOPEN,CFAILuntilnewactualgates.
ActionsLinux ONLY for builds/tests/kernel execution; no localkernelexecution.

---

## Exact9d3fb complete producer and controls PASS; mixed runtime RUNNING

ExecutableANDharness9d3fb530e67863017c50470dbd5d06aa388d6184,
tree238f75eb53995732ed2991f18bc98e17cce3f863.
Existing run https://github.com/dwijayuda/pskernel/actions/runs/39896509889:
native120228107597 PASS82proofs/eighthash/allnativeString; generatedproducer
120228660726 terminalPASS complete authenticSelfHostcheck/realPSC1/
TypeScript7.0.2/Node22.23.3/fullfixture. Kernel9956609bytes SHA256
546a14414bd0d97698153e75dd7c580dc8252f50a5a290389e7100ae5da03b04.
Authenticated artifact12478155054 ZIP1133575bytes SHA256
a616c039685fa355fda790d3e339a651ed01d8c1b27fc9ba8acead1de453886a.
Read-only inspection of COMPLETE generated kernel confirms strict pair shape:
one recursivePairinvoke/one anonymousstructuralblock/two inlined transitions;
publicStateonePairinvoke/oneblock/oneoddtransition; no staged results/Step/Mix
dispatch. Bounded2730cases8190stages13665assertions/long3 PASS.
No generator-free loop or globalbackend/speedup theorem claimed.

Retained controls120234072497 terminalPASS: unchanged scalar stagedmatrix/
long3,DAG/minimalString,prefix605assertions,sessionowners8kinds/direct7/
privateIDs5/forks2. Artifact12477857582 ZIP663962bytes SHA256
76463326951cb8245d2d9db7fecc3a9358d230bf1bd121da6bf0c910b8656f6e.
DAG145.47s/558752KiB peakRSS; prefix35.25s/590952KiB.
Prior61deda141.62s/555992KiB and32.35s/404792KiB remain visible: current
observed times and prefix peakRSS are HIGHER. Cross-run hostedCPU/GC variation
prevents a causal speedup/regression claim; D/performance remainsOPEN.
2048MiB Nodeoldspace is not a hardRSS cap. Exactprovenance,allartifactfile
hashes/fullgeneratedbodies/markers/measurements:
evidence/2026-10-23-t01f-primitive-pair-counter-generated-preflight.json.
All82proofrows/nativeartifactremain in primitive-pair-counter-native.json.

Whole unchanged mixed120234072408 is ALREADY RUNNING,started04:05:05Z,
25minutejobcap. Fuel4096/2048MiB/emptyPATH,full294requestindependent admission/
377metadata,all1400selectedcase assertions/singleton/negatives/session/
ownership/firstandsecondpubliccalls unchanged. Its terminal result is UNKNOWN.
Fetch existingrun,neverduplicate. No complete mixed/fullT01F/currentA yet.

Containing docs child is unqualified. Fullintegration/saveddraft eightproofguard
is already reconciled. All5fullworkbranchpushes remain PAUSED; profilemanual.
One next task: finish this existing mixed runtime. If PASS,restore all5full
triggers from fresh files (retain eightproofguard/canonical9file manifest/
corrected ownerlivejobguard),disable narrowhashpush,then qualify ONE NEW
coherent source through BOTH6shard strictaggregates and allrequired
native/official/proofs/provider24CLI+8API/research/measurements/unchanged
owner32workers384calls/full193/profile. Prior-source passes are not inherited.
If genuinefailure/cap,retain actual trace/artifact then fix evidencedbottleneck,
without weakeninglimits/assertions. T01F/currentA/B/D OPEN,C FAIL,
historicalscopedA9c87 qualified; noT05 yet. Integration123c41197950b6761be965fd21c57142ee2b0d1c unchanged,no main/npm.
ActionsLinux ONLY for builds/tests/kernel execution,fresh expected_sha,
nonforce updates,preserve history/concurrency.

---

## Exact9d3fb native AND bounded generated gate PASS; full producer pending

ExecutableANDharness9d3fb530e67863017c50470dbd5d06aa388d6184,
tree238f75eb53995732ed2991f18bc98e17cce3f863.
Existing run https://github.com/dwijayuda/pskernel/actions/runs/39896509889.
Native120228107597 PASS82proofreports,including EIGHT hash lemmas; five
original statements/frozen19fb worker unchanged. Permitted axiom union only
propext/Classical.choice/Quot.sound. Native2730cases,long3,294requests/
377metadata,all6authenticStringcases/singletons andretainedcontrols PASS.
Artifact12476714215 ZIP105566bytes SHA256
cd0787823347649411458a2a4a166bd2a8cd3c52b5b64159ec199f5b9de39544.
All82proofrows/authenticatedartifactfiles:
evidence/2026-10-23-t01f-primitive-pair-counter-native.json.

Generated120228660726 bounded SMALL gate PASS at this exact source:
realPSC1->TS7.0.2,2730cases8190stages13665assertions,long3.
Strict pair-counter code shape passed: onePairhelper/oneStatehelper,
zero stagedresults/Step/Mixdispatch; one recursivePairinvoke/one structural
block/two primitive transitions; StateonePairinvoke/oneblock/oneoddtransition.
This is not a generator-free loop or demonstrated performance improvement.
Actual printed bodies/artifact should be collected when producer terminates;
step success is observed now,not a fabricated full-kernel receipt.

Producer120228660726 is ALREADY checking COMPLETE authentic SelfHost source
after that gate,then fullkernelcompilation and rawfixture/provenance.
Retained controls10m and complete unchanged mixed25m are pending dependencies.
Fetch existing run; neverduplicate. Fuel4096,heap2048MiB,emptyPATH and all
1400selectedsample assertions/singleton/negatives/session/owner checks remain.
No complete mixed/fullT01F/currentA qualification exists yet.

The containing checkpoint reconciles paused fullintegration and saved draft
nativehashproofcount to8; all prior proof trust/resource gates stay intact.
Saved integrationdraft93833bytes SHA256
544183c608c2c6573d78a8834c7d1c175ee136aa41d09a6cfc88410c29a08f02;
paused active93785bytes SHA256
55828fcae22f61a3df74fe8493bcc0b933166db0c5fa88df8924fc399aa87b5f.
Saved README updated; all5fullworkbranchpushes STILL PAUSED,profilemanual.
Documentation child has separate source identity and inherits no qualification.

One next task: finish existing9d3fb complete producer then unchanged mixed/
controls. If mixedPASS,fetch fresh pausedfiles,restore all5workbranchtriggers,
keep eightproofguard/canonical9file/ownerlifecycle fix,disable narrowhashpush,
and qualify ONE NEW coherent source through BOTH6shard strictaggregates plus
allnative/official/proofs/provider24CLI+8API/research/measurements/unchanged
owner32workers384calls/full193/profile. If genuinefailure/cap,preserve
actualtrace/artifact and fix evidencedbottleneck; neverweakenlimits/assertions.
Prior61deda/fe4aa mixedtimeouts and27c85codegenrejection stay preserved below.
CurrentA/T01F/B/D OPEN,C FAIL,historicalscopedA9c87 qualified,noT05 yet.
Integration123c41197950b6761be965fd21c57142ee2b0d1c unchanged,no main/npm.
ActionsLinux only for builds/tests/kernel execution;fresh expected_sha,
nonforce updates,preserve concurrenthistory.

---

## Current: primitive pair counter after27c85 code-shape rejection

Source27c85aef9a5fd11f4074976b60c7ec482a83260f/run39895889666:
native120226130602 PASS82proofs (eighthash),2730cases,long3,294/377/all6native
Stringcases. Permitted axiom union onlypropext/Classical.choice/Quot.sound.
Generated120226787133 small authentic PSC1->TS7.0.2->JS compiled and PASS
2730cases/8190stages/13665assertions/long3,THEN code-shape gate FAILED.
Pair iterator and publicState EACH hadTWO structural generator blocks rather
than promisedONE. One recursive pair dispatch/two inlined transitions existed,
but the local cursor let in intermediate expression added a generator block.
Do not suppress this rejected criterion or call it an optimization success.
Complete SelfHostcheck/fullkernelbuild/runtime were SKIPPED.
Nativeartifact12476926971 ZIP105566bytes SHA256
6bc8b52749a714b1bf0ba907f417946a48c581af72b76ce761d512d02090755e.
Generatedsmallartifact12476862821 ZIP37804bytes SHA256
ecfe165aa5fd32f876abc26d91ab9f7e5f744cfac4ec7d1a1bc141f8f88ca0ee.
All82proofrows,authenticated ZIP/file hashes and exact generated bodies:
evidence/2026-10-23-t01f-pair-counter-codegen-rejected.json.

This NEW source inlines immutable Prod.fst cursor projections instead of the
inner cursor let. Pair-count/parity algorithm,all EIGHT theorem statements,
frozen19fb worker,finite/staged/long cases,ABI,hash31/mod65521 and allresources/
owners/sessions/cache/index/equality policies are unchanged.
Require EXACTLYONE pair helper andONEState helper,zero stagedresults/Step/Mix
dispatch,ONE recursive invoke plusTWOprimitive transitions/ONEstructuralblock
in pair iterator; ONEpair dispatch/ONEodd transition/ONEstructuralblock in
State wrapper. Gate is strengthened to explicitly check wrapperblockcount.
Print bodies and reject actual failure before fullSelfHostcheck/build.

Native-first narrow workflow at this containing source must rerun82proofs,
matrix/long/nativeString,then small realPSC1 value/shape gates,then COMPLETE
authentic source+kernel and unchanged whole mixed25m/controls10m. No inherited
passes,new-source equivalence/performance/fullT01F not yet claimed.
One next task: follow that existing run. Do not duplicate CI. All5full pushes
stay paused,profilemanual-only. If mixedPASS,reconcile BOTH final route
workflows/drafts with native hash proofcount8,restore5fulltriggers,disable
narrowpush,and requalify ONE coherent source through both6shardaggregates,
allrequirednative/official/proofs/providers24CLI+8API/research/measurements,
unchangedowner32workers384calls/full193/profile. C remainsFAIL,D/B/currentA/
T01F OPEN,historicalA9c87 scopedqualified;noT05 yet,integration123c411 unchanged.
ActionsLinux only for builds/tests/kernel execution;fresh expected_sha,
nonforce updates,preserve history/concurrency,no main/npm.

---

## Current pair-counter candidate after portable nested-recursion rejection

Source2b32b76d3dfaf2134aa1f8496a0745a03a8c9a82/run39895167983:
native120223802748 PASS81proofs (seven hash),2730cases,long3,294requests/
377metadata/all6Stringcases; onlypermittedpropext/Classical.choice/Quot.sound.
Nativeartifact12476382023 ZIP105561bytes SHA256
3de6a2cf12a3a26444ec46a700ad707bf1fe932f81ae13ceb21091e89816ad8e.
But SMALL generatedsource120224384754 failed structuralRecursionNotDecreasing.
Nested simple patterns parsed; PSC1 did not recognize the twice-nested predecessor.
No generatedmatrix/code-shape/fullsource/fullbuild/runtime executed.
All81proofrows/artifacthashes/failure:
evidence/2026-10-23-t01f-two-transition-portable-recursion-rejected.json.
The b4d6 proof elaboration and63ce parser failures remain retained separately.

This DISTINCT candidate uses a direct one-decreasing PAIR counter.
Pairs(p+1) performs two immutable primitive transitions after Pairs(p).
Public State(fuel) computes Pairs(fuel/2) then one extra transition iff fuel%2=1.
All exact bounded output/frozen19fb worker/publiccurriedABI/hash31mod65521/
rawUTF8/owner/session/cache/index/resource policies remain unchanged.
No compiler/backend/checker changes. New pairs_eq_before proves paircounter
equals the frozen one-step DATA recurrence at2*p; quotient/remainder arithmetic
then proves State(fuel) equals that recurrence atfuel. Seven existing theorem
statements remain; eight total hash proof reports are required. This source
has NOT passed them yet; native-first,2730cases,long3 and generated8190stage/
13665assertion controls rerun before expensive work.

Distinct bounded shape gate requires exactly one PAIR iterator helper and
one publicState helper,zero staged result wrappers/Step/Mix dispatch in both,
one recursive scheduler invoke/one structural anonymous block in pair iterator,
TWO inlined get/next transitions there and ONE odd transition in State with
exactly one dispatch to the pair counter. Print bodies; failbeforecomplete
SelfHostchecking/fullbuild on actual mismatch. No pureloop/speedup claim.

One next task: native proof success at this exact source,then actual bounded
PSC1 value/shape success,then complete unchanged mixed25m and controls10m.
Full5workbranchpushes remain paused,profilemanual-only; no duplicated runs.
If mixedPASS,reconcile fullnative proofcount8/drafts then activateONEnewsource
with both6shardaggregates and allnative/official/proofs/provider24CLI+8API/
research/measurements/owner32workers384calls/full193/profile gates.
T01F/currentA/B/D OPEN,C FAIL,historicalscopedA9c87 qualified; noT05.
Integration123c41197950b6761be965fd21c57142ee2b0d1c unchanged,no main/npm.
ActionsLinux only for builds/tests/kernel execution,fresh expected_sha,
nonforce updates,preserve concurrent history.

---

## Portable syntax correction after63ce native PASS / small PSC1 parse FAIL

Source63ce4521744f5f01f570b45b63f8c72f44691761/run39894656919:
native120222174006 PASS81proofs,including seven exact hash lemmas and allfive
unchanged original statements. Allowed axiom union onlypropext/Classical.choice/
Quot.sound;2730cases,three longcases,294requests377metadata,all6authentic
nativeString samples and retainednative/official/DAG/sessioncontrols PASS.
Artifact12475284802 ZIP105561bytes SHA256
572c823d2f1ff292bc501c0c3feffdadabf99d56a25c42c88f1d6ea54c08e6e8.
Full81proofrows/filehashes: evidence/2026-10-23-t01f-two-transition-native.json.

Generated120222740879 FAILED in SMALL ScalarHash source parsing:
PSC1_PROJECT_PARSE_FAILED ScalarHash.lean42:17 expected'=>',got'.'.
PSC1 cannot parse the nested constructor pattern Nat.succ Nat.zero; no small
generatedmatrix/shapegate,completeSelfHostcheck,fullbuild or runtime executed.
Do not count this as a generated semantic or performance pass.

This NEW source expresses exactly the same two-transition recurrence with
nested matches whose patterns are simple Nat.zero / Nat.succ binder.
No compiler/backend edit,no proof-statement change,no resources/assertion
change. All native proofs/finite and generated gates rerun at this source.
Keep the one-helper/one-recursive-invoke/zero-staging/zero-StepMix/
threeprimitive-transitions/atmost2structuralblocks bounded criterion.
One next task: nativefirst success,then small actual PSC1 source/value/shape
gate before fullSelfHost build,and complete unchanged mixed/controls.
All5full pushes remain paused;currentA/T01F/B/D OPEN,C FAIL,historicalA9c87;
integration123c411 unchanged,noT05 yet. Preserve both prior failures below.

---

## Native proof elaboration correction afterb4d6

Candidateb4d6b6825fb06ded08a6dffab8c74985ccf4545c/run39894299060:
native120221028037 FAIL at new state_eq_before induction elaboration
(failed to elaborate eliminator,expected type unavailable,then no goals).
Consequent sorryAx reports are FAILED elaboration artifacts and are NOT
accepted proofs. Native-first dependency correctly SKIPPED generated build
and all runtime jobs. Source checker/retained controls built,but no new
equivalence,finite-matrix or fullString qualification exists.
Artifact12475199710/405bytes/SHA256
2c31e5a0cbe905b4c1d7ffee94b53d0bef8929f2a7de4d306a60b0a478eb9698.
Evidence:2026-10-23-t01f-two-transition-native-elaboration-failure.json.

This source adds the explicit Nat.strongRecOn motive in that proof.
Production implementation,the seven theorem statements,frozen19fb worker,
all matrices/negatives/owners/sessions/resource limits and bounded-codegen
criterion are unchanged. Run the native-first narrow workflow at this exact
new source; never inheritb4d6 or61deda results. No full trigger activation.
One next task: obtain new-source native proof success,then exact bounded
generated shape/value gate,then whole mixed preflight. If a gate fails,fix it
before expensive downstream work. Allfullqualification requirements below
remain; noT05 yet,integration123c411 unchanged.

---

## Current candidate: two transitions per data-iterator descent; unqualified

Exact61deda whole mixed TIMEOUT is preserved below and in
evidence/2026-10-23-t01f-primitive-fusion-mixed-terminal.json.
The completed exact-artifact profile at harnessdca7186bd7bff21e60a32826d77064a0996f2955,
run39893421496/job120218203426 PASS diagnostic collection, shows a completed
mixed UTF8 literal V1DefEq taking92211.974ms under profiling after unchanged
294admissions/377metadata. Phase-only78608CPU samples start after term construction:
17167(21.84%) in StringHashState/its structural closure,10946(13.92%)GC;
runtime,ExprHash,HasFVar,NameHash and LevelList are also substantial.
Whole diagnostic148.69seconds,585368KiB peakRSS; no unprofiled causal speedup claim.
Artifact12474989155 ZIP5092574bytes SHA256
51064b7c091b392cebb843f0c19e3b855bcf46046aa794cf3da710920fa68107.
Operation cpuprofile839195bytes SHA256
3521ea8cb7a04b7b33844b5d683b0e4393353390157ce80aaee6f8db4bb9e3f3.
Full source/artifact/driver/phase summary evidence:
evidence/2026-10-23-t01f-primitive-fusion-defeq-phase-profile.json.
Collection success is not full T01F or release performance qualification.

This NEW source batches TWO immutable primitive transitions after each recursive
data-state descent. Fuel0/1 base cases preserve exact behavior; fuel(n+2)
computes the same two transitions after the fuel(n) state. Public Step,Scan,
curried Worker stages,fullhash,modulus65521,mix31,rawUTF8,initialaccumulator,
index/equality/cache/owner/session policies and4096resources remain unchanged.
The five original theorem STATEMENTS and exact frozen19fb worker remain.
Two new proof statements compare against a frozen one-step DATA recurrence and
derive the one-step successor equation; all seven must pass natively, then all
2730finite cases/8190JS stages/13665assertions/three long cases must pass.
No equivalence or performance result is claimed before these new-source gates.

The bounded codegen criterion is explicit and distinct: one data helper,
one recursive scheduler invoke, zero staged results/Step/Mix dispatch,
three inlined primitive transitions in the body (one single-fuel base plus two
after descent), and at most TWO structural generator blocks. Print actual
bodies and reject failed shape before COMPLETE authentic source check/build.
It does not promise a generator-free loop or remove all allocation.
Native-first workflow psc1-pskernel-t01f-hash.yml runs at this containing source.
The exact-artifact profile is back to manual-only; all5full pushes stay paused.
Never duplicate an existing source run. Follow this new source's actual native,
bounded generated and whole unchanged mixed/retained-control terminal results.

If whole mixed PASSES, reconcile added proof reports into both final route
workflows/drafts as necessary,restore all5full work-branch triggers,disable
narrow hash push,then qualify ONE NEW coherent source through both6-shard strict
aggregates plus allretained gates/providers24CLI+8API/research/measurements/
unchangedowner32workers384calls/full193/profile. No predecessor qualification.
If a gate fails,retain actual output and fix that exact failure. No acceptance
or resource weakening. T01F/currentA/B/D OPEN,C FAIL,historicalscopedA9c87
qualified; noT05 yet. Integration123c41197950b6761be965fd21c57142ee2b0d1c unchanged.
Actions Linux only for builds/tests/kernel execution;fresh expected_sha,
nonforce updates,preserve history/concurrency,no main/npm.

---

## Current:61deda whole mixed TIMEOUT; exact-artifact phase profile next

Executable/harness61deda52ef95b5e932e179663e60ba59fa9777df,
run https://github.com/dwijayuda/pskernel/actions/runs/39888872678:
native120203522175 PASS,complete authentic generated producer120204250635 PASS,
retained detached controls120209378192 PASS; whole mixed120209378115 CANCELLED
at unchanged25minute cap. 417trace begins/416ends; interrupted call417 is
psKernelV1RunDag at validity-right. All294admissions/377metadata and mixed
String.ofList singleton passed; no complete mixed case/shard receipt.
Completed V1DefEq776258.693ms,publicRunDag365100.787ms,V1WHNF180695.556ms.
Top completed UTF8-literal/UTF8-ofList DefEq calls77695.176/79278.336ms.
No assertion/heap failure observed; mixed.memory empty,completedpeakRSS UNKNOWN.
Artifact12475851172 ZIP536116bytes SHA256
9ff1dad78994822a2267da13c81c1689bc8d27d582db7355db7436c9e7a6ede5.
Exact all417begins/416ends,source/harness/kernel/fixture bindings and hashes:
evidence/2026-10-23-t01f-primitive-fusion-mixed-terminal.json.
Bounded primitive-fusion shape and finite/exact results remain valid at61deda;
the complete mixed execution did NOT pass. Do not infer performance success.

This diagnostic source updates ONLY the bounded V1 profiling workflow plus
evidence/docs. It reuses authenticated exact61deda producer artifact12474053112
(run39888872678/job120204250635/tree79711d9d637ebea88f5f09f06bdd54c1d48c3e08),
kernel e58459e63fd78a34c867b7ccbc913d2f8b38c9881067fcb45cf526ce7e7e1780.
The driver preserves complete independent294request admission and377metadata
checks then isolates V1DefEq of Array0(ByteArray0(String0(mixedliteral))) against
the genuine UInt8 byte list. A separate Inspector CPU profile starts AFTER
admission/metadata/term construction and ends immediately after that operation;
whole-process V8 sampling is retained as incomplete-outcome fallback.
Fixed180second diagnostic deadline/10minutejob,fuel4096,heap2048MiB,emptyPATH.
The derived driver is diagnosticOnly/qualificationfalse and cannot emit any
full String acceptance receipt. Generated and harness sources are separate.
Read the containing source's existing profile run and actual profile before
selecting another optimization; never launch a duplicate or weaken acceptance.

All5full work-branch pushes remain PAUSED; prepared activation is NOT applied.
Bothfe4aa final-route mixed timeouts/aggregate failures are durably retained.
Integration123c41197950b6761be965fd21c57142ee2b0d1c unchanged. T01F/currentA/B/D
OPEN,C FAIL,historicalscopedA9c87 qualified; noT05 until fullT01F. No main/npm.
One next task: inspect this exact-artifact bounded DefEq phase profile, then fix
its concrete source bottleneck and rerun native-first preflight. Full final
qualification requires both6-shard routes,allretained gates,owner32/384 and193/
profile at ONE coherent final source. Prior passes cannot qualify a new source.

---

## Current checkpoint: primitive fusion built; whole mixed preflight pending

Executable and harness `61deda52ef95b5e932e179663e60ba59fa9777df`,
run https://github.com/dwijayuda/pskernel/actions/runs/39888872678.
Native120203522175 PASS79 proof reports, five unchanged exact hash statements,
2730 finite cases/three long cases. Generated producer120204250635 PASS:
authentic complete SelfHost source check, PSC1->TS7.0.2->JS, unchanged fixture.
Kernel9955170bytes SHA256 e58459e63fd78a34c867b7ccbc913d2f8b38c9881067fcb45cf526ce7e7e1780.
Authenticated artifact12474053112 ZIP1132696bytes SHA256
36b1e3befc0a8fac6ef36a72d048988c06107f053015c08a0b89de3941d46869.
Read-only inspection of COMPLETE generated code confirms one recursive scheduler
dispatch, one structural generator block, zero separate byte-step dispatch and
zero staged result wrappers. This is primitive fusion, not a generator-free loop.

Detached controls120209378192 PASS:2730cases/8190stages/13665assertions,long3,
DAG controls, prefix605assertions, ownership kinds8/direct7/privateIDs5/forks2.
Artifact12474623171 authenticated ZIP663830bytes SHA256
2dfab63760276f8e2b7c4d0de2f32c39b300d2a52ebeefe910653110a3fc85d7.
DAG /usr/bin/time141.62seconds/555992KiB peakRSS; prefix32.35seconds/404792KiB.
Node heap2048MiB is not a hardRSS limit. No causal/general speedup claim.
Complete receipts, exact body and all artifact file hashes:
evidence/2026-10-23-t01f-primitive-fusion-generated-preflight.json.

Whole unchanged mixed Unicode job120209378115 is RUNNING (started02:38:28Z).
Fetch the existing job; do not launch a duplicate. All1400assertions,440API
trace calls,independent294request admission/377metadata,singleton,positive/
negative,owner/session/resource checks remain. Fuel4096/heap2048MiB/emptyPATH/
25minute cap unchanged. Native/codegen/controls do not qualify the full matrix.

Separate full sourcefe4aa456fb8d9e488a98dfed836cc7c991a00591 is terminal:
generated39884267668 and canonical39884267679 passed samples0-4, but BOTH
mixed sample5 jobs120198520713/120201333214 CANCELLED at unchanged25m cap.
Both had294admissions/377metadata and mixed singleton PASS; neither produced
a complete mixed case/shard receipt. Strict aggregates120211522804/
120214603476 FAIL. No assertion/heap failure observed; interrupted API unknown
because final-route tracing was disabled. Evidence:
evidence/2026-10-23-t01f-fe4aa-sharded-terminal.json.
Its other retained gates/owner32workers384calls passed,193Arena remains
173matches+2safetyagreements+17timeouts+1resourceexhaustion FAIL; full receipts
remain in evidence/2026-10-23-t01f-fe4aa-qualification-gates.json.
No predecessor/source qualification is inherited by61deda or this docs child.

One next task: finish existing61deda mixed preflight. If PASS, restore the work
branch trigger in all5paused full workflows, keep corrected owner live-job/
producer provenance guard and canonical9file manifest, disable hash narrow
push, then qualify ONE NEW source with BOTH6-shard strict aggregates and all
retained native/official/proofs/provider24CLI+8API/research/measurements/
unchanged32worker384callABBA/full193/profile gates. If timeout/failure, preserve
trace/artifact and fix the concrete bottleneck without changing assertions,
semantics or limits. No T05 before complete T01F. CurrentA/B/D OPEN,C FAIL;
historical scopedA9c87 remains qualified. Integration123c41197950b6761be965fd21c57142ee2b0d1c unchanged.
Actions Linux only for builds/tests/kernel execution. Fresh expected_sha,
nonforce updates,preserve concurrent history,no main merge/npm publication.

---

## Live primitive-fusion source61deda52: native and bounded codegen PASS

Executable AND harness `61deda52ef95b5e932e179663e60ba59fa9777df`;
tree `79711d9d637ebea88f5f09f06bdd54c1d48c3e08`.
Existing narrow run https://github.com/dwijayuda/pskernel/actions/runs/39888872678
native120203522175 PASS79proofs,5unchanged exact hash statements,2730cases,
long3,294requests377metadata,all6native String cases/singletons andretained
controls. All proof reports use only permitted propext,Classical.choice,Quot.sound.
Generated120204250635 bounded gate PASSED2730cases8190stages13665assertions,
long3 and the distinct primitive-fusion shape criterion: ONE data iterator,
ONE recursive scheduler call,ONE structural generator block,ZERO separate
byteStep/Mix dispatch and ZERO staged results. The loop hypothesis at338bb
FAILED and stays rejected; this result does not claim a generator-free loop.

Producer120204250635 is already checking COMPLETE authentic SelfHost source
after that bounded pass,then full TS7.0.2 compilation/fixture. Fetch that
existing run; never duplicate. Retained generated controls10minutes and
unchanged whole mixed25minutes remain pending. Fuel4096,2048MiB,emptyPATH
and allpositive/negative/singleton ownership assertions remain unchanged.
Exact all79 native proof rows/artifact12473897059 and gate status:
evidence/2026-10-23-t01f-primitive-fusion-native.json.
The separate fe4aa completed gates,219proofs,128whole-checker/24admission/
6profile observations,both24CLI+8API provider receipts,actual32/384 ownerABBA,
all193 individually verified body hashes and four diagnostic cases are saved in
evidence/2026-10-23-t01f-fe4aa-qualification-gates.json. Its String aggregates
remain pending; no qualification is inherited by61deda. Fe4aa narrow owner
observations include32owner trivial-sort warm1.1798x and128owner unknown-
constant peakRSS+6384KiB; retain earlier ae916 regressions separately.
This containing documentation child is unqualified; neither native equivalence
nor code shape proves full generated correctness,adequate performance or global
soundness/backend preservation.

The fullfe4aa source/runs below continue separately. Its native,generated/
canonical producers,research and actual corrected32worker384call owner PASS;
full193 C still FAIL173matches+2safetyagreements+17timeouts+1resourceexhaustion.
Its String matrices are still running. Do not inherit their passes here.
All5new work-branch full pushes remain paused; existing jobs continue.
If61deda whole mixed PASSES,restore work-branch triggers in5fullworkflows,
retain corrected owner guard,disable narrow push,and qualify one NEW source
through both6-shard aggregates,allretained required gates,measurements/owner
ABBA/full193/profile. If genuine failure/cap,retain source/receipt and fix the
concrete bottleneck. No assertion/resource weakening or cached predecessor PASS.

One next task: finish the existing61deda complete producer and mixed preflight.
T01F/currentA/B/C/D remain OPEN; scopedhistoricalA9c87. No T05 until fullT01F.
Integration123c41197950b6761be965fd21c57142ee2b0d1c unchanged.
Actions Linux ONLY for builds/tests/kernel execution. Fresh expected_sha,
non-force updates,preserve history/concurrency,no main/npm.
Earlier entries retain complete gate definitions and rejected-source evidence.

---

## Current: tail-data pure-loop hypothesis REJECTED; primitive fusion probe next

Exact338bb5a115290b43e11c4e6acf4b1f9f3c418dad,run39887910080:
native120200336990 PASS79proofs (5unchanged hash statements),2730cases,long3,
all294requests377metadata and6native String cases/singletons.
Generated120201041155 passed2730/8190/13665 values/staged ABI andlong3,
then bounded codegen gate FAILED: varying accumulator was recurried into
psKernelCacheStringHashStateWithFuel_$psc0SH_0 plus the public function.
The promised pure loop did NOT exist. No complete kernel source check,
fullkernel compilation or mixed/runtime jobs ran. Artifacts12473478282/
12473403064 and all79 proof rows are bound in
evidence/2026-10-23-t01f-tail-data-codegen-rejected.json.
Do not suppress or reinterpret this failure as an optimization success.

This NEW candidate returns to the non-tail DATA recurrence of16aac/fe4aa and
inlines the primitive transition after recursion,with no char/next bindings
inside its else branch. The five proof STATEMENTS,original proofs,frozen19fb
reference,matrix/long cases,publicStep helper and staged publicWorker are unchanged.
Its distinct code-shape hypothesis is narrower: ONE data iterator,ONE recursive
scheduler invoke,ONE structural anonymous-generator block,ZERO separate
Step/Mix dispatch and ZERO staged result wrappers. It does NOT claim to remove
all generators or be a pure loop. Require PSC1_HASH_FUSED_TRANSITION_CODEGEN:
PASS before fullsource checking/build or complete unchanged mixed replay.
Printed candidate bodies must match these exact counts; reject actual failure.
Native/generated value tests and exact proofs must rerun at this NEW source.
No compiler/frontend/backend source change is introduced.

The narrow native-first workflow remains active. The five full work-branch
pushes remain paused ONLY for this evidenced bounded optimization; job bodies,
other branches and already-running fe4aa full suite are unchanged. Fetch the
existing current-source preflight before doing anything; never duplicate CI.
After COMPLETE narrow mixed PASS,restore the work-branch trigger in all5full
workflows,retain fe4aa's corrected exact live-owner gate,disable narrow hash
push and qualify ONE new coherent final source with both6-shard aggregates,
allnative/official/proof/provider24CLI+8API/research/measurements/unchanged32/384
ownerABBA and unchanged193Arena/profile. No limits/assertions may be weakened.

Existing full sourcefe4aa456fb8d9e488a98dfed836cc7c991a00591 is distinct.
Native integration120188654676/native correctness120188654332,generated
producer120188654193,all6research and actual corrected owner120198520655
PASS32workers384calls. Canonical producer120188653998 PASSED; both full String
matrices are still running at fe4aa. Full193120189299590 FAILED with the same
173semantic matches/2separate safety-contract agreements/17timeouts/1Church
resource exhaustion/0unsupported;193unchanged bodies retained. Profile
collection120188654360 PASS is not corpus acceptance. Keep fe4aa receipts and
all finite/generic proof boundaries separate from this candidate. Never inherit.

One next task: evaluate the current primitive-fusion narrow gate; if it passes
shape+full unchanged mixed,activate exact-source fullqualification,otherwise fix
its concrete evidenced bottleneck. The tail-loop rejection stays preserved.
T01F/currentA/B/C/D OPEN; historicalscopedA9c87. Integration123c411 unchanged.
No T05 until full T01F acceptance;thenT05,T06/T07,T04a;T04b separate.
Actions Linux ONLY for builds/tests/kernel execution. Use fresh expected_sha,
non-force branch updates,preserve concurrent changes/history,no main/npm.
Earlier entries contain exact old canonical6PASS/generatedmixed25mTIMEOUT
and all resource/ownership/session/privateID policies; retain them.

---

## Current: ae916 generated mixed TIMEOUT; bounded tail-data hash candidate

Source ae916be40ec30a8a0caf5dd683eb7d1d54966849 ended with canonical
all6shards+aggregate120194717097 PASS (8400executed assertions), generated
5shards PASS but mixed120183768094 CANCELLED at unchanged25minute job cap.
Its294requests/377metadata/singleton passed; no complete case/shard receipt,
no completed peakRSS, no observed assertion/heap failure. Tracing was disabled,
so the interrupted API is unknown. Aggregate120196521995 correctly FAILED.
Exact all6 canonical measurements,source/provider/log/memory bindings,
5generated successes/timeout and static remaining scheduler dispatch:
evidence/2026-10-23-t01f-ae916-sharded-terminal.json.
This is NOT a complete T01F qualification. The earlier16aac narrow mixed
PASS1455.04s is separate and did not provide reliable final-run time margin.

Owner-auth corrected final sourcefe4aa456fb8d9e488a98dfed836cc7c991a00591
is still running its own five workflows:
integration39884267668,correctness39884267679,research39884267645,
Arena39884267651,profile39884267675. Native integration120188654676 and
native correctness120188654332 PASS; native219proofs/27axiom-free allowed3.
Continue collecting those exact existing runs; no duplicate/cancellation.
Its production hash is the same previous candidate; it remains unqualified.
The live containing HEAD is a NEW bounded optimization candidate, not fe4aa.

Concrete bottleneck hypothesis: complete generated hash StateWithFuel still
recurses through scheduler and invokes Step per fuel transition. Exact frozen
4d530ea1... kernel code was statically authenticated and inspected. A previous
same-byte traced mixed run spent726969ms V1DefEq,427855ms publicRunDag,
154108ms V1WHNF. Those outer timings are diagnostic,not phase-isolated profiles.
Current candidate moves the immutable primitive transition BEFORE the recursive
call and inlines it, preserving exact hash values,Raw semantics,modulus,fuel
outputs and all public partial stages. Result remains Prod Nat Nat.
This is an UNQUALIFIED source/code-generation hypothesis. Lean may recurry it;
the bounded gate must reject that rather than claiming an optimization.

The five theorem STATEMENTS/assumptions and frozen19fb worker are unchanged;
three proof tactics follow the new recurrence. Native/generated2730cases,
8190public stages,13665assertions,long3 and entire String harness stay unchanged.
No unchecked axiom,fixture weakening,resource increase,ownership or cache-key
authorization change. Source axioms remain forbidden. New proof gates must pass.

### Ready-to-copy continuation

Fetch live work HEAD and integration123c41197950b6761be965fd21c57142ee2b0d1c,
then fetch the already-triggered narrow hash preflight for this new source.
Do not duplicate CI or inherit parent passes. The narrow workflow runs native
proofs/fixture first,then builds real PSC1 and compiles ONLY ScalarHash's import
closure before any complete kernel check/build. It requires exactly one normal
StateWithFuel function containing a loop/continue and ZERO generator/run/invoke/
wrap/Step/Mix machinery. It also retains pure Step,unstaged full hash,2730/8190
matrix and long3 gates. Its marker is PSC1_HASH_TAIL_DATA_CODEGEN: PASS.
If generated code is recurried or not a pure loop,retain its printed body/failure
and choose the next concrete source fix. Do not suppress the falsified gate.
Only after this bounded gate passes does complete authentic SelfHost checking,
full TS7.0.2 compilation,retained controls and unchanged whole mixed replay run.
Caps remainnative25/producer25,controls10,mixed25,fuel4096,2048MiB,emptyPATH.

To avoid repeated full builds during this evidenced optimization,only the
work/psc1-pskernel-t01f-string-20261022 push branch was temporarily removed
from the FIVE full workflows. Other branch triggers and every job body remain
unchanged. Existing fe4aa runs continue. Focus/V1profile/owner diagnostics remain
manual-only; narrow hash push is active. After a COMPLETE narrow mixed PASS,
restore that work-branch line in integration/correctness/research/Arena/profile
using fresh files (retain fe4aa's corrected owner gate),disable narrow hash push,
and run ONE coherent new final source. Both six-shard aggregates and all
native/official/proof/provider24CLI+8API/research/measurements/unchanged32/384
ABBA/full193/profile must re-execute at that exact source. No partial re-run
attempt may silently reuse incompatible producer/receipt attempts.

Historical scopedA9c87 stays valid; currentA/T01F OPEN. B OPEN (ordinary/mutual/
nested V1 admission,recursive metadata,eager decode,four whole-op fallbacks).
C latestae916 FAIL173semantic matches+2separate safety agreements+17timeouts+
1Church resource exhaustion+0unsupported; all193 hashes retained. D OPEN;
keep cold/warm/heap/Name-memory regressions,including owner diagnostic32owner
ill-typed cold1.2885x and128owner trivial-sort warm1.2024x. Native equations,
code shape and finite tests do not prove global soundness/backend preservation.
Full-kernel DirectJS remains unsupported. No T05 until full T01F acceptance.
Then T05 ordinary DAG admission,T06/T07,T04a;T04b separate. Actions Linux ONLY
for builds/tests/kernel execution. Branch updates fresh expected_sha/non-force,
preserve concurrency/history;no main merge/npm publish. Integrate only after
required scoped qualification. One next task: evaluate this exact narrow
tail-data candidate and fix its first evidenced failure without weakening gates.

Earlier chronological entries below are historical.

---

## Live qualification: fe4aa456 — exact source/run checkpoint

Executable AND harness `fe4aa456fb8d9e488a98dfed836cc7c991a00591`.
Tree `2c747f3fb82ddb1c4bf799ace9064344c51b8777`.
This containing documentation child runs no CI and inherits no qualification.
Already-running current-source workflows:
- PSC1 authentic Arena timeout diagnostics: https://github.com/dwijayuda/pskernel/actions/runs/39884267675
  authentic-timeout-diagnostics:job120188654360 in_progress
- PSC1 Expression V2 production integration: https://github.com/dwijayuda/pskernel/actions/runs/39884267668
  generated-dag-integration:job120188654193 in_progress; native-dag-integration:job120188654676 in_progress
- PSC1 Lean Arena 4.35 full corpus qualification: https://github.com/dwijayuda/pskernel/actions/runs/39884267651
  official-arena-reference:job120188653802 in_progress
- PSC1 PSKernel-Core Expression V2 research: https://github.com/dwijayuda/pskernel/actions/runs/39884267645
  portable-ps-closure:job120188654185 in_progress; portable-v2-check:job120188654338 in_progress; expr-v2-differential:job120188654366 in_progress; full-checker-bridge:job120188654482 in_progress; whnf-subset-regression:job120188654483 in_progress; generated-js-full-checker-bridge:job120188654710 in_progress
- PSC1 PSKernel-Core correctness: https://github.com/dwijayuda/pskernel/actions/runs/39884267679
  psc1-portability:job120188653998 in_progress; native-kernel:job120188654332 in_progress

Require both route six-shard strict aggregates and all retained native/official/
proof/provider24CLI+8API/research/measurement gates plus unchanged owner32/384
ABBA and full193 Arena/profile at fe4aa. All are pending/running at this checkpoint.
Reuse existing runs. ae916 predecessors still have their own active String
shards; finish collecting them without transferring their qualification.
Validated runtime-only owner diagnostic39883705815 PASSED32workers384calls
at harnessac0b/generatedae916; final fe4aa still needs its own owner job.
The correction below preserves all limits/acceptance and adds exact live-job
authentication while accepting the observed active queued-run state.
T01F/currentA/B/C/D OPEN; scopedhistoricalA9c87,latestfull193Cfailedat ae916.
Integration123c411 unchanged. No T05 until T01F acceptance.
Exact inventory: evidence/2026-10-23-t01f-final-qualification-active.json.
Read the next entry for terminal predecessor receipts,remaining regressions
and ready-to-execute constraints. Next task is follow/evaluate these runs.

---

## Current: owner lifecycle gate corrected after validated exact-artifact preflight

The containing commit activates a NEW coherent final qualification source.
Production,proofs,String fixture/runner,shard helper,all acceptance assertions,
measurement driver and resource policies are unchanged. Fetch the actual source
SHA and its five already-triggered workflow IDs; never duplicate CI or inherit
ae916/ac0b predecessor qualification. Diagnostics including owner preflight are
manual-only. The Arena profile adds only a source-qualification annotation;
its job body/cases/budgets remain unchanged.

At executable/harness ae916be40ec30a8a0caf5dd683eb7d1d54966849:
- Native integration120172865344/native correctness120172865463 PASS;
  219 proof reports,27 axiom-free,only permitted3axioms; genuine native six-case fixture.
- Generated producer120172865519 and canonical producer120172865185 PASS,
  both detached24CLI+8API,2730hashcases8190stages13665assertions,long3,
  all retained DAG/ownership/proof gates. Generated measurements COMPLETE:
  128whole-checker,24admission,whole-program and6profile rows.
- All6 research39879401425 jobs PASS. Both full String matrices are still
  running at their original exact source; preserve eventual successes/failures.
- Owner job120183767998 FAILED before benchmark: GitHub reports an enclosing
  run queued while matrix jobs wait. The old gate wrongly accepted only
  in_progress/completed-success. No benchmark outcome existed at that job.

Runtime-only owner validation then PASSED at harness
ac0b0c927683671c29efe9cac62b1fdc767de307,run39883705815,job120186833027.
It authenticated exact ae916 candidate artifact12471410988 and historical
9c87 baseline12391568345,unchanged driver4ebfd97b/7c8a8275,32workers384calls,
ABBA,fuel4096,60seconds/worker,2048MiB,emptyPATH. All source/byte/report
bindings passed. It is DIAGNOSTIC ONLY with separate harness/generated SHAs.
Final workflow now accepts active queued/in_progress with null conclusion and
additionally requires its own exact in_progress job/head/run/attempt before
checking both producer successes. Artifact,source,driver/count/limit checks remain.
Full source-bound final qualification must rerun after this workflow change.

Do not claim general performance improvement. Narrow diagnostic observations
include32-owner ill-typed cold1.2885x baseline,128-owner trivial-sort warm1.2024x,
128-owner owned-constant warm1.0489x with3728KiB larger peakRSS; retained-heap
and prior Name-memory/warm/cold regressions remain visible. D OPEN.

Full193 current-source Arena39879401452 FAILED:173semantic matches
(105accepted,60kernelRejected,1metadataRejected,7transportRejected),
2separate safety-contract agreements,17timeouts,1Church resource exhaustion,
0unsupported. Official122accepted71rejected0timeouts. All193 body hashes
individually verified original=adapted with no exclusions/reexport.
Report667306bytes SHA256f28756611788377e9fca4fc1e7ef39f832804b91664b48331b271238509f5868.
Profile39879401524 collection PASS for4cases; Church still exhausts and Prelude
still times out. Collection success is not corpus qualification; C FAIL/OPEN.
FullArena is separate from scoped T01F/A; do not suppress its failures.

Exact durable receipts:
- evidence/2026-10-23-t01f-ae916-producers.json
- evidence/2026-10-23-t01f-ae916-arena-terminal.json (all193 case body hashes)
- evidence/2026-10-23-t01f-ae916-owner-diagnostic.json
- evidence/2026-10-23-t01f-final-source-native.json
- evidence/2026-10-23-t01f-pure-byte-step-mixed-terminal.json (16aac narrowPASS)

One next task: evaluate this NEW source's complete same-source T01F suite:
both six-shard strict aggregates,allnative/official/proof/provider/research/
measurement gates,unchanged32worker384call ownerABBA and unchanged193/profile.
Follow existing ae916 shard runs to terminal too; do not confuse their source.
Keep25minutes/shard,maxparallel2,failfastfalse,fuel4096,2048MiB,emptyPATH,
all294independent requests377metadata per process,allpositive/negative cases,
singleton sequencing,exactowners/sessions/privateIDs and current input digests.
Actions Linux only for builds/tests/kernel execution; no local execution.
T01F/currentA OPEN; historical scopedA9c87; B/C/D OPEN. No T05 until fullT01F
acceptance. Only integrate after required scoped qualification via fresh
expected_sha/non-force,preserving concurrent changes. Integration remains
123c41197950b6761be965fd21c57142ee2b0d1c. No main merge or npm publish.
Then follow T05 ordinary DAG inductive admission,T06/T07,T04a;T04b separate.
If unfinished,save exact sources,runs,outcomes and ready-to-copy continuation.

Older chronological checkpoints remain below.

---

## Live final qualification: ae916be4 — running, not qualified

Executable AND harness: `ae916be40ec30a8a0caf5dd683eb7d1d54966849`.
Tree: `a8db2401141bc73a00dfb169c9b3f45b6f499dae`.
The containing documentation child is not an executable qualification source.
Already-triggered current-source runs (reuse these, never duplicate):
- PSC1 PSKernel-Core Expression V2 research: https://github.com/dwijayuda/pskernel/actions/runs/39879401425
- PSC1 Expression V2 production integration: https://github.com/dwijayuda/pskernel/actions/runs/39879401423
- PSC1 authentic Arena timeout diagnostics: https://github.com/dwijayuda/pskernel/actions/runs/39879401524
- PSC1 Lean Arena 4.35 full corpus qualification: https://github.com/dwijayuda/pskernel/actions/runs/39879401452
- PSC1 PSKernel-Core correctness: https://github.com/dwijayuda/pskernel/actions/runs/39879401429

All current-source jobs are pending/running at this checkpoint. Exact initial
job IDs are saved in evidence/2026-10-23-t01f-final-qualification-active.json.
Follow all jobs,6 generated shards+aggregate,6 canonical shards+aggregate,
unchanged ABBA32workers384calls and full193 Arena/profile to terminal results.
Both complete route markers and every retained required gate must bind ae916.
Do not inherit16aac's narrow PASS or fad56's first-activation jobs. Keep all
historical caps/failures and A/B/C/D boundaries below. T01F remains OPEN;
integration123c411 unchanged; T05 blocked. No local build/test/kernel execution.

---

## Current: canonical manifest completeness corrected; new exact-source suite required

First activation `fad56ef8e983c78cb0c6209975d6e1a9f2300fdb` started:
- PSC1 PSKernel-Core correctness: https://github.com/dwijayuda/pskernel/actions/runs/39879215990
- PSC1 Expression V2 production integration: https://github.com/dwijayuda/pskernel/actions/runs/39879215977
- PSC1 authentic Arena timeout diagnostics: https://github.com/dwijayuda/pskernel/actions/runs/39879216137
- PSC1 Lean Arena 4.35 full corpus qualification: https://github.com/dwijayuda/pskernel/actions/runs/39879216083
- PSC1 PSKernel-Core Expression V2 research: https://github.com/dwijayuda/pskernel/actions/runs/39879215998

Static review of its helper and the unchanged manifest producer established a
concrete transport-gate defect before canonical replay: the producer lists
canonical-source.tar.gz as its ninth canonical provider file, while the helper
expected only the eight shared generated files. This containing correction adds
that exact canonical-only archive to the strict expected set, then authenticates
its recorded bytes/digest through the existing every-file loop. Generated still
requires exactly eight files; canonical exactly nine. No file is ignored.
The active helper and saved draft are identical. Production, native proofs,
String fixture/runner,all judgments/assertions,budgets and job bodies are unchanged.
The profile branch list is reordered only; job semantics and cases are unchanged.

The first activation is UNQUALIFIED; do not inherit its jobs at this correction.
This correction triggers a new coherent exact-source full suite. Fetch live HEAD,
record its actual SHA and the already-triggered five workflow run IDs, and follow
those existing runs without duplication. Source-bound both-route six-shard
aggregates,all retained native/official/proof/provider/research/measurement gates,
32worker384call ABBA and full193 Arena/profile remain pending. Keep first
activation results distinct even if other jobs pass. No integration change.
Historical16aac narrow full-mixed preflight is PASS and unchanged; T01F/currentA,
B,C,D remain OPEN and T05 stays blocked. Read the next chronological activation
entry for exact budgets,source/kernel digests,preflight receipts and task order.

---

## Current: complete16aac preflight PASS; final same-source qualification activated

Executable/harness `16aac21740fa7870e502fdf712eff76e5c33e1a2`,
tree `1eaa8663b61bbd95dfca42bf26e7e62ebef70f21`, completed
[run39873570107](https://github.com/dwijayuda/pskernel/actions/runs/39873570107)
SUCCESS: native120153577616, authentic producer120154391391,
retained generated controls120161280951 and complete mixed120161280846.
Mixed replay passed all1400 assertions,294 requests,377 metadata,
the complete Aé€😀 case/singleton/negatives,440/440 traced calls.
Wall1455.04s,peakRSS1165840KiB,exit0 under unchanged25minute cap;
runtime admission46780.885661ms and metadata1400.629080ms.
Only one of six generated samples was replayed here; diagnosticTracing=true.
All79 native proof reports,5 exact hash equations,2730 matrix cases,
8190 staged generated calls,13665 matrix assertions and3 long cases passed.
The byte transition is a normal pure function with no generator/staging/Mix
dispatch; immutable DATA recursion still calls that helper per byte.
FullHash avoids staging internally; exported curried worker ABI is preserved.
No controlled performance or global soundness/backend preservation claim.

Exact receipts:
- evidence/2026-10-23-t01f-pure-byte-step-native.json
- evidence/2026-10-23-t01f-pure-byte-step-generated-preflight.json
- evidence/2026-10-23-t01f-pure-byte-step-mixed-terminal.json

This activation installs the saved complete generated/canonical workflows and
same-run shard helper without production or acceptance-harness changes.
Both routes compile once then execute exactly six whole runtime-only samples,
fail-fast:false,max-parallel2,25minutes/job,emptyPATH,fuel4096,2048MiB.
Each process independently admits294 requests and compares377 metadata.
Require PSC1_T01F_FULL_STRING_SHARDED_JS: PASS from BOTH routes at this NEW
activation source, with exact source/run/attempt/route/provider/input digests.
16aac's narrow PASS does not qualify this containing activation commit.
Research, full193 Arena and timeout profile receive only the work-branch
trigger; all job bodies,case hashes,budgets and controls remain unchanged.
Focused/hash/V1-profile diagnostics are manual-only to avoid duplicate pushes.
All old native/official/proof/provider24CLI+8API/research/complete measurements
and unchanged32worker384call ABBA jobs remain required at the new source.

Fetch live work HEAD and its existing Actions runs before doing anything;
do not duplicate CI. Record the actual activation SHA and run IDs in the next
documentation-only checkpoint. Follow every current-source gate and all six
shards per route. Preserve failed/skipped/timeout results and source bindings.
Do not raise caps, weaken assertions, replace genuine declarations, or reuse
a parent's qualification. No local builds/tests/kernel execution; Actions Linux.
Only consider integration after required scoped qualification is complete,
using fresh expected_sha/non-force and preserving concurrent branch changes.
Never merge main or publish npm. Integration remains123c41197950b6761be965fd21c57142ee2b0d1c.

T01F/current-source A OPEN pending final gates. Historical scoped A remains
9c87f631758862285273ddb0ea0a3987c671022e. B OPEN (V1 inductive admission,
recursive metadata,eager decode,four whole-operation fallbacks).
Historical C FAIL:173 semantic matches (105accepted,60kernelRejected,
1metadataRejected,7transportRejected),2 separate safety-contract agreements,
17timeouts,1Church resource exhaustion,0unsupported; official122/71/0.
New-source full193 results are pending; collection success is not corpus PASS.
D OPEN: controlled performance, cold/heap/Name/warm regressions and broader
soundness/refinement/backend proofs. Full-kernel DirectJS remains unsupported.
One next task: complete and evaluate this activation source's full T01F suite.
Do not start T05 until full T01F acceptance; then T05 ordinary DAG inductive
admission precedes T06/T07 and T04a ingress removal; T04b remains separate.

Earlier chronological entries below are historical and superseded by this
current checkpoint. Preserve their rejected/failed/incomplete evidence.

---

## Exact16aac pure byte-step native PASS; generated pure-leaf gate pending

Executable `16aac21740fa7870e502fdf712eff76e5c33e1a2` passed its native
job120153577616 in
[run39873570107](https://github.com/dwijayuda/pskernel/actions/runs/39873570107).
Allfive exact equations,2730 frozen matrix cases,three long cases,294
admissions/377 metadata,all6 authentic String cases and singleton sequences,
retained native/official/DAG/session controls passed. All79 proof reports are
recorded; the newfive use only propext,Classical.choice,Quot.sound. No sorryAx
or compiler-trust axiom appears in these successful proof reports.
Artifact12467875493 and exact source/tree/proofs:
`evidence/2026-10-23-t01f-pure-byte-step-native.json`.

Generated producer120154391391 is ALREADY RUNNING at16aac. Fetch its current
run; do not duplicate it. Require complete authentic source check,TS7.0.2,
the unchanged2730/8190/13665 generated matrix and three long cases,then the
small pure-byte-step gate before full compilation. That gate refuses any
generator/run/invoke/wrap machinery in the nonrecursive byte transition.
It also rejects function-valued iterator results and staged full-hash entry.
If this code-shape hypothesis fails,stop at the gate; do not suppress it.
All generated controls/full mixed qualification remain pending.
This containing documentation child inherits no executable qualification.

The source primitive-only step uses exactly the old arithmetic; immutable
data iteration calls it; fullHash bypasses public staging internally while
the exported worker preserves every partial stage. The five theorem
statements and assumptions are unchanged. Explicit psKernelCacheMix unfolding
repaired only the proof tactic. Previouse23 native elaboration FAILED and
generated jobs were skipped; that rejection remains recorded separately.
Native equivalence does not prove TS/JS preservation,global soundness,or
complete generated String correctness.

C644 preceding mixed preflight timed out at25minutes after402/403 traced
calls,V1RunDag validity-left interrupted; singleton/294/377 passed but no
complete case or selected negatives/shard receipt. Its entire trace and all
artifact bindings remain in
`evidence/2026-10-23-t01f-fused-data-result-mixed-terminal.json`.
Retain all old timing/RSS regressions and incomplete sources. No controlled
speedup or broader performance qualification has been established.

Final workflows remain INACTIVE; drafts/README retain exact destinations and
digests. Preservefuel4096,2048MiB,emptyPATH,all assertions and job caps.
T01F/currentA/B/C/D OPEN; historical scopedA=9c87,historical full193C=FAIL.
Integration stays123c411; do not startT05. Only complete mixed PASS permits
final activation at one coherent source,with focused/hash/profile automatic
pushes disabled and every final route/native/official/proof/provider/research/
measurement/ABBA/unchanged193 Arena/profile gate re-executed at that source.

## Exact 5abf mixed preflight TIMEOUT; current-artifact bounded profile next

Executable `5abf40506564cad00ff518600ae5992dc826510e` has terminal
[run 39860528417](https://github.com/dwijayuda/pskernel/actions/runs/39860528417):
native 120109760162 PASS; producer 120110557932 PASS; controls 120118769801
PASS; mixed 120118769683 CANCELLED at the unchanged 25-minute job cap.
The mixed singleton passed, all 294 requests/377 metadata checks completed,
and 377 of 378 traced calls completed. Call 378, V1 DefEq at
`utf8-ofList-left`, was interrupted. No complete case/shard receipt, assertion
failure, heap failure, or completed peak-RSS measurement was observed.
All completed trace records and exact source/artifact bindings are retained in
`evidence/2026-10-23-t01f-data-result-mixed-terminal.json`.

Current UTF8-literal-left V1 WHNF recorded 66895.09929 ms; repeated large
V1 DefEq calls there recorded 75875–77903 ms. Different hosted runners and
incomplete capped traces do not establish a controlled causal speedup.
The exact local equations, matrix and code-shape improvements remain scoped
evidence; the full mixed sample remains unfinished. Keep all prior 19fb/834
timeouts and DAG/prefix RSS/timing observations visible. Do not raise caps,
remove assertions, replace authentic declarations, or claim T01F completion.

The updated narrow `psc1-pskernel-t01f-v1-profile.yml` reuses only the exact
authenticated 5abf producer artifact 12461534544. It performs the unchanged
full 294-request/377-metadata prefix, then the measured UTF8-literal V1 WHNF
under the existing 180-second diagnostic deadline, 10-minute job cap,
fuel4096, empty PATH and 2048MiB old-space. It records separate generated/
harness source SHAs and never emits a full String acceptance receipt.
Fetch its already-triggered current run before launching anything else.

Final sharding workflows remain INACTIVE. T01F, current-source A, B, C and D
remain open; historical scoped A is 9c87; historical full193 C remains FAIL.
Do not start T05. Integration stays 123c411. Read the terminal profile before
selecting another narrow source change; rerun appropriate source-bound gates.

## Exact 5abf generated producer and retained controls PASS; mixed replay pending

Executable source: `5abf40506564cad00ff518600ae5992dc826510e`.
[Run 39860528417](https://github.com/dwijayuda/pskernel/actions/runs/39860528417):
native `120109760162` PASS; authentic generated producer `120110557932` PASS;
generated retained controls `120118769801` PASS. Mixed String runtime
`120118769683` is ALREADY RUNNING with its unchanged 25-minute cap. Fetch that
existing job; do not duplicate it or infer its result from these subset passes.

The native five exact hash equations, 2730 cases and three long cases passed.
The generated small closure and complete kernel controls each passed the
2730-case, 8190-stage, 13665-assertion matrix and three long cases. Static reading
of the authenticated complete kernel found one data iterator helper and zero
staged function-result wrappers in that helper. This is code-shape evidence,
not a global backend-preservation theorem or a demonstrated speedup.

Complete kernel: 9954933 bytes; SHA256
`4252fe0c1100a0bda8aa9e488195902af560c27e92b3e93ad77ac9550b4bc5fe`.
Producer artifact `12461534544`: ZIP SHA256
`deffed2af9d212e3bd77a5c444c1d50f3cddfa148646a0526c40c5f4ba8186a7`.
Generated DAG: 153.98 s / 565200 KiB peak RSS; prefix/session: 37.90 s /
507868 KiB peak RSS, 605 assertions. Different hosted runners prevent a causal
speedup claim; keep historical slower runs and RSS observations visible.
Exact provenance and artifact identities:
`evidence/2026-10-23-t01f-data-result-generated-preflight.json`.

The containing documentation checkpoint runs no CI and inherits no qualification.
Final sharding workflows remain inactive. T01F, current-source A, B, C and D
remain open; historical scoped A is 9c87 and historical full193 C remains FAIL.
Do not start T05. Integration remains 123c411. After a complete mixed PASS,
activate the reconciled final workflows at one coherent source, disable narrow
push diagnostics, and run all final native/official/proof/provider24/API8,
both six-sample route aggregates, research, full measurements, unchanged
32-worker/384-call ABBA and unchanged 193-case Arena/profile gates.

## Exact5abf data-result native preflight PASS; generated pending

Executable candidate: `5abf40506564cad00ff518600ae5992dc826510e`.
Own [run39860528417](https://github.com/dwijayuda/pskernel/actions/runs/39860528417)
native120109760162 PASS: all5 hash equations,2730 raw/fuel/accumulator cases,
3 long ASCII/Unicode cases,294 requests/377 authentic metadata, all6 String
cases and singleton sequences, retained native/official/DAG/session controls.
There are79 local proof reports total; the new5 report only
propext,Classical.choice,Quot.sound. No sorryAx.
Artifact12462220608 and all proof rows are bound in
`evidence/2026-10-23-t01f-data-result-native.json`.

Generated producer120110557932 is ALREADY RUNNING at5abf. Its next new gate
compiles only the ScalarHash import closure, runs the unchanged2730-case/
8190-stage matrix plus long cases, and refuses staged function-result wrappers
inside the data iterator. Only after that gate passes does full authentic
kernel compilation proceed. Fetch the existing run, never duplicate it.

Saved final workflow drafts are reconciled to5 equations and long controls on
both generated routes, with updated README digests and raw-log upload paths.
They remain inactive. The containing documentation HEAD is separate from
5abf's native source; no generated or final-source qualification is inherited.
Historical834's mixed timeout and911's zero-job workflow rejection remain
explicitly recorded. Integration stays123c411; scoped A remains9c87.
T01F must finish before T05. B/C/D remain open.

---

## Workflow transport correction after911 — no candidate tests ran

Source911510a6d618612a4aaeb363ee517af9cdf2ba54
run39860291713 was rejected as an invalid workflow before any runner/job.
The embedded Python marker contained a JavaScript string-replacement token;
the authoring replacement incorrectly expanded workflow suffix text.
This checkpoint corrects the workflow text using literal/callback insertion.
Production code, proofs, matrices, acceptance assertions and limits are unchanged.
No native or generated qualification is inherited by this new candidate.
Run the native-first corrected workflow and inspect its own exact source.

---

## Data-result hash iteration candidate — after834 mixed timeout

Exact834 run39853314171 ended with mixed120096453413 CANCELLED at25minutes,
interrupting public RunDag call343 in utf8-literal-left. The342 completed calls
include914.757s in18 V1 DefEq and239.661s in3 V1 WHNF calls. The mixed singleton
sequence passed; the complete sample and later controls did not finish. No
assertion failure or heap exhaustion was observed. Native, complete authentic
source checking/compilation and retained generated controls passed at834 only.
Full trace/artifact facts are preserved in
`evidence/2026-10-23-t01f-hash-terminal.json`. It is NOT T01F-qualified.

The containing candidate replaces the String hash scan with an immutable
cursor/hash transition and a fuel iterator returning DATA (Prod Nat Nat).
The recursive call keeps value/initial state fixed, then applies the transition
to the returned state. A finished cursor is a fixed point. This performs up to
fuel transitions, including unchanged fixed-state transitions after end, while
preserving the exact bounded-prefix hash output and curried public API.
It targets the two remaining staged recursive-helper closures verified in834.
No cache index/equality/ownership, kernel4096 policy or acceptance assertion changes.

Two iterator lemmas plus the three frozen original-worker equations must pass
before generated work. Native/generated2730-case raw/fuel/accumulator matrices
and8190 staged ABI controls remain; three additional long ASCII/Unicode cases
exercise the data iterator's stack/allocation path. None is qualified yet.

The narrow workflow now first compiles the ScalarHash import closure, runs the
generated matrix and checks that data-result iterator implementations contain
no staged function-result wrappers. Only then does it compile the complete
authentic kernel and execute the complete unchanged mixed sample (25minutes)
and retained controls (10minutes). Inspect the exact containing source/run;
do not duplicate CI or inherit834's passes. If proofs or code generation fail,
fix that evidenced gate before another full build.

Final drafts remain inactive. Reconcile the new five-equation count and long
hash controls into both final routes before eventual activation. No T05 before
full T01F acceptance; A remains historical9c scoped only, B/C/D remain open.

---

## Exact834 generated producer and retained controls PASS; mixed pending

At exact `834d267acc246b5bf6ed2d29b19d04d8b87526c4`,
run39853314171 producer120086000612 PASS: complete authentic source check,
fresh TypeScript7.0.2/Node22 compilation and genuine fixture production.
Kernel9954719bytes, SHA256`d0d43eb8db19f77a3ba370645924f761762086bc160e7526740b9d1633926ffb`;
artifact12460485134. Controls120096453339 PASS:2730 scalar-hash cases,
8190 public partial stages,13662 assertions, retained DAG/minimal String,
605 prefix assertions and prior-session controls. Native120084924212 also PASS.

Mixed120096453413 is ALREADY RUNNING at834 under the unchanged25-minute
runtime job cap. Fetch its terminal state; do not duplicate it. No complete
mixed sample, full matrix, both-route or final-source qualification exists yet.
See `evidence/2026-10-23-t01f-hash-generated-preflight.json` for exact producer,
artifact and observed-control bindings.

Static inspection of the authenticated compiled kernel shows the portable
lowering still emits `psKernelCacheStringHashScan_$psc0SH_0` with explicit
fuel/value and TWO staged position/hash closures. The source worker does not
remove all generated per-character closure overhead. Native equivalence and
finite generated ABI/output controls pass; a speedup is not established.

Retain cross-run observations: DAG146.99s/584684KiB and prefix/session
36.40s/612100KiB, versus previous19fb115.11s/628496KiB and28.17s/422628KiB.
These different runner executions are not a controlled causal comparison.
The larger time and prefix peak-RSS observations must remain visible until
comparable measurements resolve them. D remains open; no general improvement
or release-performance qualification is claimed.

The containing checkpoint changes documentation/drafts only. Its HEAD is
separate from tested executable834. Integration remains123c411; fully qualified
scoped A remains9c87. Final drafts remain inactive, and T05 remains blocked.
If834 mixed passes, execute the reconciled exact-source full suite; if it
fails or times out, use its trace and the verified remaining staged-helper
lowering to choose a concrete next fix. Preserve all limits and assertions.

---

## Exact834 native PASS; existing generated preflight pending

Executable candidate: `834d267acc246b5bf6ed2d29b19d04d8b87526c4`.
Its [run39853314171](https://github.com/dwijayuda/pskernel/actions/runs/39853314171)
native job120084924212 PASS: three new hash equations,2730 finite cases,
all294 authentic requests/377 metadata records, all6 String cases and singleton
sequences, retained DAG/T03a/T03b/official controls and existing proof audits.
The new local equations report only propext,Classical.choice,Quot.sound;
no sorryAx. See `evidence/2026-10-23-t01f-hash-native.json`.
This is native narrow qualification at834 only.

Generated producer120086000612 is already running at834. At this update it is
building/checking the complete authentic source, before pinned TypeScript7.0.2
compilation. Wait for that existing run; never launch a duplicate. Its dependent
runtime jobs retain the full mixed sample and all negatives under25minutes,
and hash/DAG/prefix/session controls under10minutes. No generated result or
speedup has been established yet.

The saved final workflow drafts now include the new hash native proof/matrix,
both detached generated hash suites and uploaded raw hash logs. README digests
match the reconciled bytes. These drafts are still INACTIVE. The helper and
paired-owner fragment remain unchanged. This containing documentation checkpoint
does not acquire834's native result or qualify a new executable source.

If834 preflight passes completely, activate the reconciled drafts and the three
research/Arena work-branch triggers, disable narrow automatic diagnostics, and
execute final native, both six-sample route aggregates, canonical, proofs,
provider24/API8, research, full measurements/unchanged owner ABBA and193-case
Arena at one coherent final source. Keep historical C failures separate from
scoped A/T01F coverage. Integration remains123c411; fully qualified scoped A
remains9c87. No T05 yet.

---

## T01F scalar hash scan candidate — qualification pending

Bounded V1 profile at `7e29c6c795e64a488a51edcc940c6916d4a1bafd`
[run39852099370](https://github.com/dwijayuda/pskernel/actions/runs/39852099370)
ended with timeout124 after180.03s/566044KiB. The complete294-request admission
and377-record comparison finished, then the isolated UTF8 literal WHNF remained
active at the deadline. Profile processing and artifact upload passed. The
153613-tick sample spans admission and partial WHNF; it is not a completed
operation benchmark. Exact generated lines8012–8024 map the prominent scalar
hash worker closures and repeated staged dispatch. GC accounts for15.6% of
total sample ticks. Full authenticated artifact12458271030 and its digest are
recorded in `evidence/2026-10-23-t01f-v1-whnf-profile.json`.

This containing candidate adds an explicit-argument String hash scan while
retaining the original curried worker API, fuel countdown, Raw.atEnd/get/next,
character codes, mix recurrence, initial accumulator and exact hash outputs.
It changes no index representation, equality authorization or cache ownership.
The native frozen-source proof/regression file compares all inputs by three
local equations plus2730 finite raw-position/fuel/accumulator cases. Its
generated counterpart also checks all three public partial-application stages
against an independently built UTF8 boundary map. These tests/proofs have not
yet passed at this entry; no equivalence or speedup result is claimed.

The narrow preflight workflow is `.github/workflows/psc1-pskernel-t01f-hash.yml`.
It runs native proofs and all existing native String/DAG/session controls first,
then freshly checks and compiles the complete authentic kernel. Separate
runtime-only jobs run the retained controls/new hash matrix (10minutes) and the
complete unchanged mixed String sample (25minutes). It authenticates the same
source/run/attempt kernel, fixture and harness bytes. All original negative
controls and fuel4096/2048MiB/emptyPATH remain. Inspect existing runs for the
exact containing SHA before retrying; do not duplicate builds.

The final six-case workflows remain saved drafts. If this preflight passes,
reconcile the new hash proof/native/generated controls into BOTH final routes,
then activate and execute one coherent final qualification. T01F remains open;
do not start T05. Integration remains123c411 and historical complete scoped A
remains9c87. B/C/D and the historical193 failures remain open.

---

## T01F mixed diagnostic timed out — V1 conversion/reduction bottleneck

Observed 2026-10-23 WIB. Exact harness `9248c474d705ffaa4a1aba8a0aa7a4ce54e4a303`
reused authenticated generated source `19fb4b0b8f52808d6a31705185018d6e60836d8e`
in [run39848120108](https://github.com/dwijayuda/pskernel/actions/runs/39848120108).
Retained controls job120066753317 PASS: DAG115.11s/628496KiB, prefix/session
28.17s/422628KiB,605 prefix assertions and all prior-session owner markers.
Mixed job120066753711 CANCELLED at the unchanged25-minute whole-job cap.
All294 requests and377 metadata comparisons completed. The mixed singleton
sequence passed, but the complete case and later UTF8/validity/negative groups
did not finish. No assertion failure or heap exhaustion was observed; there
is no completed mixed peak-RSS result or qualification receipt.

The347 completed trace calls record913.757s in21 V1 DefEq calls and212.937s
in3 V1 WHNF calls. UTF8 literal DefEq took220.158s; its WHNF127.355s.
The interrupted call348 is V1 DefEq in utf8-literal-left. These are diagnostic
outer-API times, not a controlled speedup or internal hotspot attribution.
Both successful/unfinished artifacts and every completed trace record are
retained in `evidence/2026-10-23-t01f-focused-diagnostic.json`.

The full final-suite drafts were reviewed (old steps preserved, exact source/
run/attempt/provider identities, six unique receipts, clean runtime exit and
raw logs/memory revalidation), but remain INACTIVE because the focused mixed
case cannot finish within its cap. The old focused push trigger is disabled
to avoid an accidental duplicate25-minute run. A separate bounded180-second
V8 profile targets the measured V1 UTF8 literal WHNF after unchanged complete
fixture admission, corrupt-definition control and metadata comparison.
It derives a diagnostic driver only; the full acceptance runner is unchanged.
The new profile workflow is `.github/workflows/psc1-pskernel-t01f-v1-profile.yml`.
Its containing source and terminal result must be fetched; no profile success
or source qualification is claimed in this update.

Production remains19fb. Integration remains123c411; native singleton evidence
remainsa368 and complete scoped A remains9c87. B/C/D remain open. Do not activate
the final suite or start T05 until a genuine hotspot fix lets the complete
unchanged mixed preflight pass under the existing cap. Do not raise limits,
suppress V1 parity or replace real declarations.

---

## T01F resumed — authenticated generated preflight pending

Live integration `123c41197950b6761be965fd21c57142ee2b0d1c` and work handoff
`34f06a19a9829c52f85457658cc9a3ba28ea01ed` were rechecked before this update.
No newer T01F run or concurrent branch update was present. This checkpoint
activates the reviewed artifact-reuse workflow by a path-filtered push; its
mixed-index5 and retained-control results are pending. Production remains
`19fb4b0b8f52808d6a31705185018d6e60836d8e`; the current harness is separate.
The diagnostic authenticates the cancelled producer's successful build steps,
exact ZIP/kernel/fixture/source digests and immutable current harness bytes.
It preserves all selected-case assertions, singleton sequences, negatives,
empty runtime PATH, fuel4096 and 2048MiB old-space. A shard success is not
full-matrix or final-source qualification. Final-suite drafts stay inactive
until the focused diagnostics finish. No integration update is authorized by
this diagnostic result alone. A/B/C/D remain as recorded below.

---

## Unfinished T01F handoff — no CI on this checkpoint

This work-branch checkpoint preserves the current implementation and prepared
qualification work for GPT-6.1 Sol with High reasoning. The user requested a
continuation prompt; no further CI was launched. The containing commit uses
`[skip ci]` and is **unqualified**. Resolve its exact SHA independently.

Integration remains `123c41197950b6761be965fd21c57142ee2b0d1c`.
The latest native-tested harness is parent
`a36839347269d05f5a79d6103a7a4b0ddab1bdb1`; production Lean remains
`19fb4b0b8f52808d6a31705185018d6e60836d8e`. Historical complete scoped
checking qualification remains `9c87f631758862285273ddb0ea0a3987c671022e`.
Do not inherit any of these results for the containing commit.

The strict generated selector and authenticated19fb artifact-reuse focused
workflow are installed but unexecuted. Final sharded workflow replacements,
helper and paired-owner fragment are preserved as unexecuted drafts under
`docs/drafts/t01f-final-shards/`; they are not active workflows. Finish review
and mixed-sample/retained-control preflight before activating the final suite.
All assertions, negatives and resource limits remain required.

Read `docs/AI_CONTINUATION_PROMPT.md` and
`evidence/2026-10-22-t01f-handoff-checkpoint.json` for source/run/digest details.
T01F is not complete; both generated routes, canonical final qualification,
complete performance and the unchanged193 Arena at a final coherent source
remain pending. A/B/C/D remain separate. Older entries below are historical;
in particular, any statement that run39827244691 is still running is superseded
by its recorded terminal cancellation.

---

## T01F generated matrix isolation — focused mixed-sample preflight

The exact19fb generated preflight in run39827244691/job119993676851 built and
source-checked the fresh candidate, then reached its unchanged25-minute
whole-job limit. Setup/build consumed839 seconds and detached execution676
seconds. Empty and ASCII cases completed, including their negatives. The
third sample was interrupted in V1 WHNF; the remaining samples and retained
generated DAG/prefix stages did not complete. No assertion failure or heap
exhaustion was observed. This is an incomplete preflight, never a T01F PASS.

Source `19fb4b0b8f52808d6a31705185018d6e60836d8e` produced artifact12447224834
(`psc1-t01f-generated-preflight`,1110713 bytes), ZIP SHA-256
`f899a7704c804d9c48ac54ee2cdd608f69497397b4f1378145e235b65126522b`.
Its9953467-byte kernel has SHA-256
`cd6d03fe2da5b7e76bf40a7e3dba9e8315e2fb1a269f20f3108e29f77c49e5f5`.
The authenticated raw fixture remains
`563d6ef138271a13039764257407ee8b66190bca02c8057489d3b1c45f51e71d`.
Compiled source and fixture production steps succeeded even though the whole
producer run was cancelled. Reuse must validate those individual steps and
retain the cancellation/skipped-gate facts; never assert producer-run success.

The trace completed594 API calls. First owner derivation was4.950 seconds;
the first12 empty-sample public calls totaled69.173 seconds
(5.293–6.105 each). Historical profiled9c execution measured7.784 and101.039
seconds respectively, but the Node patch and profiler settings differ, so this
is diagnostic evidence rather than controlled performance acceptance.
The ASCII sample's53 V1 DefEq calls took144.798 seconds and8 V1 WHNF calls took
37.680 seconds. Its29 public calls took185.276 seconds. No completed peak-RSS
result survived cancellation.

Exact `a36839347269d05f5a79d6103a7a4b0ddab1bdb1` passed native singleton
preflight run39829443557/job120001370021: all six cases and singleton sequences,
294 requests/377 metadata records,74 proof reports and retained controls.
Fixture execution took8 seconds. This is that source's native result only.

This revision adds strict optional sample selection to the generated test
runner. Default invocation still runs all six original samples and every
assertion. An explicit index0–5 executes exactly that sample after full
independent declaration admission and all applicable negatives, produces a
distinct shard PASS receipt, and retains singleton session-reuse checks.
The fixture contents are never edited to select cases.

The focused workflow reuses authenticated19fb compiled bytes to test the
heaviest mixed sample and retained controls without another compilation. Its
harness source is this revision; its generated kernel source remains19fb.
Neither identity inherits final qualification. The mixed sample has its own
25-minute job limit; retained controls have a separate10-minute job. Both use
fuel4096,2048MiB old-space and empty runtime PATH.

Final qualification will compile each authentic route once at one new exact
source, run all six complete cases in separate runtime-only jobs, and require
an aggregate receipt proving all six distinct indices on each route with
matching source/run/attempt, kernel/fixture/producer/runner digests. This
allocates more total CI time to the complete new matrix while preserving
25 minutes per case job, all assertions and negatives. Compilation, existing
controls and performance measurements are not repeated per case. Matrix
max-parallel is two per route. The unchanged193-case Arena remains60 seconds
per case,2048MiB Node old-space,two workers and identical body hashes.

T01F remains incomplete until both complete generated routes and all final
native/official/canonical/proof/provider/research gates have their own terminal
source-bound evidence. No inductive-admission migration has begun. A/B/C/D
remain separate; the performance worker requires the unchanged comparable
paired benchmark before any speedup claim.

## T01F singleton public-call coverage — native-only follow-up

Updated: 2026-10-22 UTC. This revision adds a singleton check → WHNF → DefEq
sequence for each of the six authentic String.ofList samples, threading the
returned session and checking its exact environment, resource policy and
provider. Every previous matrix/negative control remains. The actual constructor,
checked type, WHNF and DefEq results are compared with V1 and the official
native oracle as applicable. The final gates require six singleton PASS markers
in native and each generated route.

Production code is unchanged from worker candidate
`19fb4b0b8f52808d6a31705185018d6e60836d8e`.
Its native job119993677370 in run39827244691 passed, including both new
lookup-equivalence theorems (only standard Lean axioms), T03a/T03b and
all294 requests/377 declarations/six original sample groups. Its fresh generated
job119993676851 is still running at this revision's preparation. Do not duplicate
that build. This follow-up runs native only; no generated qualification is
inherited, and the final coherent source still requires both generated routes
with all singleton controls and the complete acceptance suite.

---

## T01F authentic String — measured ownership bottleneck and candidate worker

Updated: 2026-10-22 UTC. Work branch:
`work/psc1-pskernel-t01f-string-20261022`.
Integration remains `123c41197950b6761be965fd21c57142ee2b0d1c`;
the historical scoped-qualified executable remains
`9c87f631758862285273ddb0ea0a3987c671022e`.
**This containing implementation candidate is not qualified.**

The actual Lean4.35 closure now independently admits294 requests into377
declarations from an empty session, compares every metadata record and checks
six empty/ASCII/UTF8 samples. Native source90917599acbc8fce257361f36a032dd86defa9da
passed run39823486422/job119980543904, including official, V1, direct DAG and
separate/reused public queries and malformed definition/expression controls.
The earlier minimal String receipt remains separate.

Historical generated replay at harness0b05e5beb04e30323bb790f7b0038e81ebb90f96
(run39821217936/job119972688309) was cancelled at the25-minute job limit:
empty, ASCII and two-byte cases including their per-sample negatives passed;
the remaining samples and whole-matrix PASS did not complete. No assertion
failure was logged. This used the authenticated9c87 bundle and does not qualify
0b05 or any newer source.

Bounded diagnostic675adacb6820aea2e5c4003a9948958877aae34f,
run39825997073/job119989324609, propagated timeout124 at180seconds.
All294 genuine admissions plus the corrupt-definition rejection completed;
metadata377 took1.345seconds. Completed trace calls include owner derivation
7.784seconds,12 public calls totalling101.039seconds (8.004–8.869each),
and14 full checked decodes totalling10.468seconds. The profile shows generated
declaration-lookup closures, name comparisons and generator/WeakMap overhead.
PeakRSS747448KiB. Artifact12446507718, ZIP SHA256
44f2b9ee71ac29e231f0322905f11f83ff9709c73b60f210c95903ab759e552f.
These are diagnostic measurements, not performance acceptance or qualification.

The candidate introduces an explicit-argument DeclarationRefFind worker while
retaining the curried exported ABI, immutable list, exact NameEq and first-match
result. The previous scan already deferred tail traversal; this change targets
per-visited-entry generated closure overhead, not eager import or a new index.
A copied exact pre-change specification and local equivalence theorems are
added to PsKernelCacheScopeProofs. No fuel, cache authorization, owner identity,
declaration admission, field semantics or fallback policy changes.

Run the focused native and fresh-source generated preflight first. The complete
unchanged authentic String matrix must pass. Both final-source generated routes,
all prior native/official/proof/provider controls, complete measurements and
unchanged full193 Arena remain pending. A speedup is not established until
comparable measurements complete. Full-kernel DirectJS remains unsupported;
A/B/C/D are not advanced by this candidate.

---

## T01F authentic String implementation — focused Linux preflight

Updated: 2026-10-22. Integration base is exact
`123c41197950b6761be965fd21c57142ee2b0d1c`; the last scoped-qualified
executable remains `9c87f631758862285273ddb0ea0a3987c671022e`.
Work branch: `work/psc1-pskernel-t01f-string-20261022`.
This containing candidate is **NOT QUALIFIED**; no previous PASS is inherited.

The new host-only fixture reads actual Lean 4.35 Init declaration payloads from
String.ofList, Char.ofNat and UInt8.ofNat, traverses their dependency closure,
and independently admits every request from an empty default PSKernel session.
It never installs official constructor/recursor metadata or trusts a receipt.
Each admission is logged so a genuine first failure identifies the next source
fix. The actual representation is String.ofByteArray with ByteArray data and
its UTF8 validity proof. String field1 is valid; field2 is invalid.

Focused checks cover V1, direct DAG attempts that cannot silently fall back,
and separate/reused public check/WHNF/DefEq calls for empty, ASCII, 2/3/4-byte
and mixed Unicode strings, actual byte-list projection, validity-proof projection
and ill-typed/invalid-field negatives. The previous bounded minimal fixture is
retained separately. This first preflight makes no production semantic change.

Run the narrow Linux workflow first and fix observed genuine failures. Complete
the authentic generated input export/replay, metadata comparison, local proof
controls and full exact-source gates before marking T01F complete. Full193 and
all prior performance regressions remain open; no parent counts qualify this
candidate. Fuel4096 and every existing host/negative/ownership limit remain.

---

## T03b terminal qualification — exact executable source and integration handoff

Updated: 2026-10-22 16:52:53 WIB (2026-10-22 09:52:53 UTC).
Exact qualified executable source:
`9c87f631758862285273ddb0ea0a3987c671022e` (tree
`5dd7e9879f28d0adb8794c8b60469eecaaa7f866`).
This containing receipt commit changes documentation/data only and is distinct
from that source. Its integration promotion preserves all six isolated T03b
commits atop the independently qualified parent
`0420aa896b04197aebd14444c1d2c4a36a41df9e`. No force update, main merge or npm
publication is part of this work.

**A PASS, scoped to9c87. B OPEN. C FAIL/open. D OPEN.**
Own terminal integration39694087886 (native119547118983/generated119547118855),
correctness39694087885 (native119547118951/canonical119547118636) and all six
research39694087856 jobs PASS. Both authentic generated routes compile and run
the actual changed kernel, retain detached provider24/API8 checks, and pass
the new session8-kind/7-direct/5-private-ID/2-fork controls. Native official
checks cover4 independently admitted declarations and7 direct cases.
All14 session,21 recursor,21 Quot-owner and8 Name equations pass their actual
axiom audit; no global soundness/refinement/backend proof is inferred.

The single final unchanged193 comparison at this source is run39694087862,
independent job119547747908: 173 matches / 2 separate safety-contract agreements / 17 timeouts / 1 Church resource exhaustion / 0 unsupported. All193 complete case records and
original/adapted body hashes are saved. Official job119547118244 independently
reports122 accepted/71 rejected with controls passing. Actual zero-based
case16 rec-missing-ih (printedcase17) is independently rejected; it is not
unsupported. Authentic profile39694087923/job119547118869 is collection-only:
repeated-subproblem accepted, Church resource_exhausted, Prelude timeout and stuck projection rejected in both unprofiled/profiled runs; all four kernel_qualified=false. Successful collection does not qualify failed kernel cases.

The unchanged0420-to9c ownership experiment is run39757971693/job119754708372, harness4ebfd97b4588f8651e8b7a81bc00b2a05cfe1e3c, artifact12415998934.
The paired run completed all32 workers/384 independently validated calls. Five pooled warm-median groups exceed10%; owned-constant cold grows68.95%/69.34% (about2.33–2.38ms extra). Peak RSS and total retained heap stay below15% growth, but incremental retained heap grows50.97%/56.52% for owned constants and17.08%/18.05% for unknown constants. A separate complete-record review supports the bounded correctness migration with this explicit tradeoff. It is NOT performance-qualified; D stays OPEN, and no general speedup is claimed. Costs remain optimization work and are not proved unavoidable.
All32 workers/384 calls and raw worker records remain; each complete public
call is independently checked after its timer against the exact genuine V1
outcome. Both source-bound generated bundles, driver identity and native
producer archives are authenticated. Full same-run128 whole-checker and24
admission ABBA records, all337 native records and outer memory measurements
are published for each source. Construction, first-batch admission/setup,
module loading, cache context, CPU, retained heap and RSS are separate fields.
No general speedup or hard RSS cap is claimed.

Implementation boundary: derive fresh private appended owners from actual
already admitted session metadata; no caller owner table or receipt is trusted.
Canonical input and newly appended types/bodies/family/rule metadata seed exact
immutable environment-index lookup. The admitted list is only a structural
bound, consumed once per unique new owner. Empty demand inspects one outer
constructor without a tail walk, environment-length prepass or eager closure.
Original external IDs remain unchanged; appended owner IDs remain private.
Post-command demand completion uses the actual next checked environment and
preserves complete state and atomic failure. This adapts checked session state,
not a second admission mechanism. Low-level forged internal sessions/owners
remain within the documented trusted integration boundary.

Retain T03a's authoritative final-environment prefix recipe, exact old-name
cutoff, actual final recursor types/rules and nested restoration, current-command
input-ref reuse and old helper ABI. Retain native and both generated24/7/6/3,
official5/6/7, all state/universe/checked-infer-only/private-ID controls, the
parameterized checked Quot-kind bridge and Name production. Session regression
controls include late import/command failure, missing/wrong/stale ownership,
two session forks,32 unrelated old declarations skipped and a closed-sort
zero-import case.

Source-bound history remains separate:
- combineddeb18 passed its own scoped gates; full193173/2/17/1/0 FAIL;
- parent0420 passed its own scoped gates; full193173/2/17/1/0 FAIL;
- T03a7b14 passed its own scoped gates; full193173/2/17/1/0 FAIL;
- original034 remains NOT A-qualified due to native fixture elaboration;
  actual rec-missing-ih was independently rejected, not unsupported;
- T03b0b413/6c105 failed native fixture/proof attempts;6fd9 native preflight
  passed;461 failed generic append elaboration and0f7 failed structural
  self-recursion recognition. Both full failed sources stopped before the
  independent193 replay. Their receipts are preserved and no assertion,
  compiler rule or resource limit was weakened.

The eager7e importer and indexed-cache384 remain held. Name's original paired
experiment remains f9e9b20f92ce2ffa4a666acaf55aa8852949f589→
34126793178021a9cd1bdb37aa6fe17c0fab41c6, harness14ee4a9323e47944e971e1d9c9a191936fb4843e,
run39645953379/job119381453525. Preserve its chain8 DAG RSS192432→195732KiB
and stuck-projection421436→449388KiB regressions, mixed retained heap and
Church/Prelude failures. Those historical measurements are not T03b results.

Read [T03b qualification](docs/T03B_SESSION_OWNERSHIP_QUALIFICATION.md),
[exact terminal receipt](evidence/2026-10-22-t03b-terminal-qualification.json),
[parent0420 receipt](evidence/2026-10-22-0420-terminal-qualification.json),
[current matrix](docs/PSKERNEL_CORE_PROGRESS_MATRIX.md) and
[completion plan](docs/PSKERNEL_CORE_COMPLETION_PLAN.md).

B still requires full actual String.ofList (T01F), V1 inductive admission,
recursive metadata import, eager decoding and four whole-operation fallbacks.
C retains original timeouts/Church exhaustion and explicit safety-contract
reconciliation. D retains broader whole-kernel performance and release gates;
global proof obligations remain open. Fuel4096,60seconds/case,2048MiB Node
old-space,2workers, Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
TypeScript7.0.2/Node22 and both authentic generated routes remain fixed.
Full-kernel DirectJS is UNSUPPORTED.

**One next executable task: T01F full actual String.ofList environment coverage**,
with independent admission and genuine reduction/projection/public checking,
then its own exact-source native/official/generated/proof/provider/benchmark
qualification and one unchanged193 comparison. Do not start a broad audit or
combine it with ordinary/mutual/nested admission migration.

Everything below is dated source-bound history. Old pending states or next-step
directions do not override this current handoff.

---

## T03b structural-recursion correction — new exact-source qualification required

Updated: 2026-10-21 23:32:00 UTC.
Exact `0f7dceeb3d6dbab2b4db584b29729aa200f48e28` is terminal **FAIL**.
Its native integration119543656506 and native correctness119543655676 passed,
including all14 session equations,21 recursor equations,21 Quot-owner equations
and8 Name equations. Session8-kind/7-direct/5-private-ID/2-fork and official4/7
controls passed. Five of six research jobs passed. The full portable source
gate advanced past the corrected append worker, then rejected the recursive
self-reference in `psKernelDagGeneratedCompleteDemands` with
`unknownName:psKernelDagGeneratedCompleteDemands`. Its recursive-list match
was nested beneath the selected-demand match.

All five runs39693047060/39693047092/39693046905/39693046919/39693047233 are
terminal. Generated119543656039, canonical119543656172, research119543655205,
Arena119544440444 and profiles119543656015 stopped during source elaboration.
The official193 reference passed; **no independent PSKernel193 replay and no
profile-case execution occurred** at this source. Parent Arena counts are not
assigned to it. See [exact0f7 failure receipt](evidence/2026-10-22-t03b-0f7-portability-failure.json).

This containing correction moves the first explicit structural-list argument's
match to the outer level, following the existing `InstallNewPrefix` worker.
All four arguments remain before the return-type colon. The nil/cons branches
still perform the exact demand lookup once; import, dependency collection and
recursive descent occur only for a selected new owner. An empty-demand exit
inspects one outer list constructor and does not traverse its tail. No
environment-size pass or recursive closure is precomputed. The authority-list
head remains unused; exact live indexed metadata supplies every owner.

All14 existing session equations and all tests remain unchanged. The no-demand,
zero-bound, import-error and successful-one-cons equations cover both layouts'
observable behavior. The explicit append-order theorem and both former failure
receipts remain. This source is **NOT YET A-qualified** and must pass its own
full required gates, one unchanged193-case comparison and unchanged paired
32-worker/384-call ownership experiment against parent0420 before promotion.
No parent or native-only PASS transfers. B/C/D remain open; no speedup is claimed.

Earlier entries below preserve their exact historical source identities.

---

## T03b portable-source correction — new exact-source qualification required

Updated: 2026-10-21 23:22:30 UTC.
The full run set for exact `461014cba7a45f15282ac9f125808cabdd17c5cb` is terminal and **FAIL**.
Native integration119539310776 and native correctness119539310521 passed, as did
five of six research jobs. Authentic PSC1 source elaboration rejected the three
`List.append` applications in `psKernelDagGeneratedInfoDemands` with
`unsupportedTerm`; generated119539310497, canonical119539310752 and research
generated119539310474 failed. Full runs39691738652/39691738558/39691738605,
Arena39691738662 and profiles39691738654 are all terminal. The official193
reference passed, but independent119540114723 stopped during source
reconstruction: **no PSKernel193-case replay occurred at this source**.
No parent classifications or diagnostic results qualify it.
See [the exact failure receipt](evidence/2026-10-22-t03b-461-portability-failure.json).

This containing source replaces all three generic append applications with an
explicit structural worker using the already-portable Core/Name list pattern.
A fourteenth local session equation proves the identical list order. The
ownership design, all semantic and negative controls, T03a/Quot helper ABIs,
external input namespace, private appended owners and atomic publication remain.
The full native gate retains all21 recursor,21 Quot-owner and14 session equations.
The optional focused workflow is now dispatch-only because the full native gate
runs every focused control and proof; the five required full workflows remain
enabled on this branch. No assertion or required qualification gate is removed.

The corrected source is **NOT YET A-qualified**. Finish its existing exact-source
native/official, both authentic generated routes, canonical, six research,
provider, benchmark, unchanged193-case Arena and diagnostic-profile runs before
another batch. Then run the unchanged32-worker/384-call ownership experiment
against independently qualified parent0420. Preserve the eager7e hold and Name
memory regressions. Fuel4096,60seconds/case,2048MiB Node old-space and2workers
remain fixed. B/C/D and global proof obligations remain open; no speedup claim.

Earlier entries below retain their exact historical source identities.

---

## T03b qualification execution — focused gates passed; full exact-source gates pending

Updated: 2026-10-21 23:10:21 UTC.
The demand-scoped implementation passed focused Linux qualification at exact
`6fd9ac6f57e34947e0b11f0176f357146798a9e1`, run39691206177/job119537547857.
Native public DAG controls, T03a24/7/6/3 plus official5/6/7, separate-session
8-kind/7-direct/5-private-ID/2-fork controls and official4-declaration/7-direct
checks all passed. All21 recursor equations,21 Quot-owner equations and13 session
equations elaborated without sorryAx or compiler-trust proof shortcuts.

Failed preflights remain in history: exact0b413781f68bfce7d451255e94e84e4415fec1bb,
run39690178207/job119534142609, exposed official fixture record layout;
exact6c1059657945c7516480c60c16e5d889642735f5,
run39690574716/job119535462633, exposed mutable input shadowing and the old late
publication theorem's missing demand-completion state. Both were test/proof
corrections; production is unchanged from0b413. The late-command theorem now
quantifies the actual completed state, and a new equation proves atomic failure
at the added post-command import boundary. No failing gate was suppressed.

Existing parent0420aa896b04197aebd14444c1d2c4a36a41df9e is independently
scoped-A qualified: integration39664059278, correctness39664059196 and all6
research39664059121 jobs passed. Its full193 Arena39664059161 is FAIL:
173 matches,2 safety-contract agreements,17 timeouts,1 resource exhaustion,
0 unsupported. Profiles39664059168 passed collection only. Both generated routes
retain T03a controls,1360 Quot-owner assertions,Name50237 assertions and24+8
provider checks. Parent PASS does not qualify this containing source.

The containing commit enables full isolated-branch qualification on
`work/psc1-pskernel-t03b-session-20261022`: native/official, authentic generated,
canonical reconstruction/checking, all6 research jobs, providers, complete
benchmarks, one unchanged193-case comparison and diagnostic profiles. Inspect
these existing exact-source runs before launching anything else. This containing
source is **NOT YET A-qualified**. The final paired experiment must reuse the
unchanged32-worker/384-call/32-and128-owner driver fromf84f344, comparing against
the authenticated immediate-parent0420 artifact12378492499. The eager7e and
indexed-cache performance holds remain.

A is exact-source scoped and pending here; B still includes T03b qualification,
T01F, V1 inductive admission, recursive metadata import, eager decoding and four
whole-operation fallbacks. C remains open for timeouts, Church exhaustion and
explicit safety-contract reconciliation. D remains open pending complete
same-run observations; no general speedup is claimed. Fuel4096 and all host
limits, independent checking, both detached generated routes, original external
IDs, exact immutable environment identity and atomic publication remain fixed.
The next executable action is to finish these gates and the unchanged paired
measurement, then integrate only the qualified result with a separate
documentation receipt.

Earlier updates below retain their named historical sources.

---

## T03b demand-scoped session ownership — isolated implementation, pending qualification

Updated: 2026-10-21 19:59:42 UTC. Integration parent is exact
`0420aa896b04197aebd14444c1d2c4a36a41df9e`; the isolated branch is
`work/psc1-pskernel-t03b-session-20261022`. This containing source is
**NOT YET A-qualified**. No parent PASS is inherited. Existing exact0420 runs
39664059278/39664059196/39664059121/39664059161/39664059168 are being inspected,
not duplicated. Exactdeb18 combined qualification is terminal and separately
recorded in [its receipt](evidence/2026-10-21-deb-terminal-qualification.json).

T03b now derives private owners from the actual admitted session before use.
Canonical input nodes seed indexed name lookup; newly imported checked types,
transparent bodies and recursor rules extend the same demand closure. Literal
translation and Nat Boolean results contribute their implicit helper names.
Actual inductive families/constructors and recursor rule constructors contribute
metadata dependencies. No unrelated declaration is eagerly imported, and there
is no environment-size prepass. A structural authority-list cursor bounds one
new owner per step without traversing the old tail or eagerly building closures.
The checked environment index supplies every declaration; the cursor head is
never metadata authority. The public entry accepts no owner table or receipt.

The original decoded input remains the external ID namespace. The append-only
arena, synchronized decoded table and private owners are staged together.
Post-command demand completion scans only newly appended metadata, using the
actual checked next session. All publication remains atomic. Immutable
environment identity accompanies owner indexes; operation caches remain fresh.
The T03a final-prefix recipe, all existing Quot ownership behavior and the old
helper ABIs remain. Low-level forged sessions keep the documented trusted
integration boundary; this adapter adds no admission mechanism.

Native/official and both authentic generated gates retain all previous controls
and add prior-session constant/recursor direct check, WHNF and DefEq, all8
declaration kinds,5 private-ID negatives,2 isolated session forks, missing/wrong
owners, late command/import errors, and demand-only import checks. Twelve local
equations address exact lookup, bounded import, error propagation and original
input identity; these are not global soundness/refinement/backend proofs.

The eager7e candidate remains held. Promotion requires the unchanged32-worker,
384-call,32/128-owner complete-call ABBA experiment against a source-bound
baseline, with construction/admission/module/cache measurements retained.
Only one final unchanged193-case comparison is planned per coherent candidate.
Fuel4096,60seconds/case,2048MiB Node old-space and2workers are unchanged.
No general speedup is claimed. A qualification is pending for this source;
B remains open (T03b qualification,T01F,V1 inductive admission,recursive metadata
import,eager decode,four whole-operation fallbacks), C remains open for
timeouts/Church/safety reconciliation, and D remains open.

Earlier execution updates below are historical and retain their exact sources.

---

# Current integration — qualified Quot ownership; hold eager initial loading

Updated: 2026-10-21 19:41:30 UTC.
Branch: `integration/psc1-pskernel-expr-v2-lean435-20261021`.
Fresh integration parent: `b656ff78a03383cc33d5c2a1c14e3c13468810d2`.
Merged qualified source: `df4d1751f4166ed8c9a28ac151d1ab77c94cbfe7`.
Containing integration commit: **NOT RUN at creation; inspect its exact terminal
Actions jobs before qualification.** The parents' PASS results are not inherited.

## What changes in this integration

Install private DAG declaration references for the four actual checked Quot
constants after successful V1 Quot admission. Exact live kind, level parameters,
decoded header and absent delta value guard idempotent owner reuse; mismatches
are rebuilt from checked metadata. The old three-argument helper and the
production previous/current-environment helper retain their interfaces. The
already-qualified T03a final-prefix scanner, constructors/recursors, nested
restored headers, Name workers and both frozen-parent defect reproducers remain.
Native/official, canonical and generated owner tests plus21 local equations are
wired into the required gates. This does not yet replace V1 Quot admission.

The diff preserves all six files of concurrent documentation commit b656ff7,
including both permanent334/T03a receipts. New exact-source terminal receipts,
all193 case classifications and complete measurement observations are appended;
historical pending/failure wording below is retained as history.

## Exact-source evidence (terminal; source identities remain separate)

| Source | Native | Portable Lean | Canonical .ps | Generated JS | Local proofs | Provider | Benchmark | Arena |
|---|---|---|---|---|---|---|---|---|
| deb18b9 | PASS | PASS | PASS | PASS | PASS | PASS | PASS collection, mixed performance | FAIL |
| df4d175 | PASS | PASS | PASS | PASS | PASS | PASS | PASS collection, no causal speedup claim | FAIL |
| 7e36b3b, separate candidate | PASS | PASS | PASS | PASS | PASS | PASS | FAIL promotion; paired collection PASS | FAIL |
| containing integration | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

Exact deb18b9 integration39651609850, correctness39651609752 and all6
research39651609561 jobs passed; profile collection39651610007 passed as a
diagnostic, not kernel qualification. Exact df4d175 integration39655284633
(native119413791099/generated119413791339), correctness39655284617
(native119413788492/canonical119413788179) and all6 research39655284622 jobs
passed. Both df4 generated routes passed1360 Quot-owner assertions and retained
24 provider CLI/8 API checks in detached Node22 with PATH empty. Its21 local
owner equations use only the permitted logical dependencies. Neither result is
a global soundness or backend-preservation proof.

Receipts:
- [deb exact terminal evidence](evidence/2026-10-21-deb-terminal-qualification.json)
- [df4 exact terminal evidence](evidence/2026-10-21-df4-terminal-qualification.json)
- [7e exact terminal evidence, held](evidence/2026-10-21-initial-owner7e-terminal-qualification.json)
- [all paired initial-owner observations](benchmarks/2026-10-21-initial-owner-paired.normalized.json)
- [initial-owner performance decision](docs/INITIAL_OWNER_PERFORMANCE_HOLD.md)

All three exact full Arena runs evaluated193 original authenticated bodies and
failed qualification with the same classifications:173 matches (105 accepted,
60 kernel rejections,1 metadata rejection,7 transport rejections),2 separate
unsafe/partial safety-contract differences,17 host timeouts and1 Church
fixed-fuel exhaustion. Official reference:122 accepted/71 rejected/0 timeouts.
Do not call all173 matches admitted proofs. Zero-based timeout IDs:
23,72,78,80,82,83,84,85,86,87,90,91,92,93,94,96,98. The kernel fuel remains4096,
per-case wall deadline60seconds and historical host limit2048MiB V8 old-space,
which is not an OS RSS cap. Historical metadata headers were adapted; bodies
were authenticated, not freshly re-exported by native4.35.

## Measured holds and actual next implementation

**Do not integrate eager initial-session importer7e.** Its complete semantics,
20 local equations,1515 generated assertions per route and provider gates are
green. Paired run[39662962284/job119440477019](https://github.com/dwijayuda/pskernel/actions/runs/39662962284/job/119440477019)
completed32 fresh ABBA workers and384 exact public calls. At128 prior owners,
trivial checking regressed1.271395→77.633987ms warm mean (61.06×), owned-constant
checking2.423566→87.061367ms (35.92×); peak RSS grew66,148/75,752KiB. All four
queries at both32 and128 owners regressed. The next owner implementation must
avoid importing unrelated declarations, keep exact live-index authority and
original/private IDs, and repeat this complete-call experiment unchanged.
The benchmark driver's exact source f84f344 is separately identified from the
unmodified producer/kernel7e; the failed predecessor444 ran no measurement.

Indexed cache384 also remains outside integration after the authenticated
paired metadata-admission regressions (~23.2%/~22.6%). The optional compiler
saturation experiment is isolated on research/psc1-ts-saturation-20261021.
Focused exact2823173 run39663471492 passed native/model controls,16 local
equations, authentic Lean and canonical .ps source compilation, actual radix
worker specialization and8400 detached JavaScript assertions per route after
the explicit fixture-type repair. Full-kernel qualification and paired performance
remain NOT RUN. Default compiler emission, kernel resource policy and runtime
trust boundary are unchanged. No speedup is claimed.

Direct DAG Quot admission and the owned batch carrier are still being implemented
on the carrier branch, with legacy API wrappers and theorem statements retained.
The exact loose-occurrence helper is a separate unqualified draft; valid closed
public bodies may already force looseRange≤1, so no reachable production fallback
retirement is claimed from its adversarial raw cases. No unfinished agent draft
is included here, and no work is claimed to continue after this chat ends.

## Release boundaries and next gates

Scoped independent developer-provider A is qualified at exact deb and df4,
with real valid/invalid batches, genuine PSC1→TypeScript7.0.2 JavaScript,
.d.ts/maps, full canonical closure and detached execution. The default provider
and separately selectable reference remain V1. B (complete V2), C (full Arena)
and D (performance/release) are open. Four whole-operation fallback families,
eager input decode, recursive metadata import and global proof obligations
remain; complete-kernel DirectJS is unsupported. No main merge or publication.

Next executable action: inspect the containing integration's native, portable,
canonical, generated, proof, provider, benchmark and all193 Arena runs to terminal.
Fix actual blockers without weakening assertions. Continue demand-scoped initial
ownership, direct DAG Quot admission and the measured backend allocation
experiment on isolated source branches; promote only qualified, measured slices.

---

## Preserved integration history (verbatim)

# Current handoff — T03a qualified; combined source qualification pending

Observed: 2026-10-21T18:48:58Z / 2026-10-22 Asia/Jakarta.

## Concurrent integration must qualify separately

Immediately before this documentation update, live executable HEAD advanced to
`deb18b9c87a5d21a406c6e5b852afb4d44785fe5`, a two-parent merge of qualified T03a source7b14
and name-worker source34126793178021a9cd1bdb37aa6fe17c0fab41c6.
Only `Core/Name.lean` changes production relative to7b14; the T03a carrier,
fixtures and21proofs are unchanged. The existing workflows add name-worker
gates while retaining all T03a and parent controls. The complete merged
work-state and source histories are preserved verbatim below.

**The combined revision is NOT YET A-qualified at this observation.** Its own
existing jobs must finish; neither parent's qualification transfers. This
documentation-only child records evidence and does not create a new qualified
executable SHA. Do not launch duplicate CI.

| Existing combined-source workflow | Observed result at 2026-10-21T18:48:12Z |
| --- | --- |
| Integration39651609850 | Native119401099653 PASS; generated119401099171 running |
| Correctness39651609752 | Native119401099174 PASS; canonical119401098776 running |
| Research39651609561 | All six jobs PASS |
| Arena39651610468 | Official119401101610 PASS; independent119402241996 running |
| Authentic profiles39651610007 | Job119401099438 running |

The immediate next task is to finish observing these exact existing combined
runs, preserving failures and source-bound artifacts. After the combined
revision passes its own required scoped gates, the next implementation task
is **T03b preexisting-session ownership**. The separate f9e9-to341 name-worker
paired measurements and memory regressions remain in their existing evidence
files; they are not measurements of7b14 or this combined source.

## Exact T03a implementation and qualification

**Exact qualified executable source: `7b14affc854e7bc99e4778ac155ae805dd273226`.**
Its own complete mandatory gates are terminal PASS. The containing documentation
commit records these observations and does not inherit that executable source's
qualification. Read live HEAD separately before the next write.

| Same-source workflow | Terminal evidence |
| --- | --- |
| [Integration39645765038](https://github.com/dwijayuda/pskernel/actions/runs/39645765038) | Native119380795456 PASS; generated119380794907 PASS |
| [Correctness39645764867](https://github.com/dwijayuda/pskernel/actions/runs/39645764867) | Native119380794896 PASS; reconstructed canonical .ps119380794398 PASS |
| [Research39645765012](https://github.com/dwijayuda/pskernel/actions/runs/39645765012) | All six PASS:119380796590,119380797133,119380797134,119380797158,119380797194,119380797443 |
| [Full Arena39645764921](https://github.com/dwijayuda/pskernel/actions/runs/39645764921) | Official119380794281 PASS; independent119387868442 FAIL; all193 retained |
| [Authentic profiles39645764955](https://github.com/dwijayuda/pskernel/actions/runs/39645764955) | Job119380795767 PASS, collection only; not kernel qualification |

Source-bound run/job conclusions, artifact sizes/digests, manifests, controls,
case-level Arena evidence and performance limits are preserved in
`evidence/2026-10-22-t03a-terminal-qualification.json`. All five original034
runs finished before this new full qualification push; none was restarted.
No predecessor or focused preflight result qualifies7b14.

## Implemented T03a boundary

The authoritative completion-plan recipe is implemented in
`API/DagGenerated.lean` and its production call in `API/Dag.lean`, with the
ownership comment updated in `Checker/ExprV2/Environment.lean`.

The bridge scans only the newly admitted prefix of the final checked environment.
It stops before the first name contained exactly in the previous environment,
using the existing indexed lookup and exact comparison. It has no size prepass,
whole-tail comparison, old-tail scan or invented auxiliary suffix convention.
Recursor types and every rule RHS come from actual final checked metadata.
Ordinary/mutual family and constructor types reuse only matching references from
the current command's input-ref list. Nested requests import their restored
final types and actual renamed auxiliaries; flattening-only families gain no
owners. Unexpected new declaration kinds return an internal invariant error.

The old three-argument helper's body/ABI is retained. The production entry
receives the actual previous and next environments, preserves original external
input IDs, and threads all private arena/built/declaration state. Generated IDs
remain private. A failed metadata import or later command returns no partial
session, owner set or replies. No fuel, safety, unsupported or resource policy
was changed. V1 admission and other migration adapters remain explicitly open.

## Exact-source controls

Native and **both** authentic generated routes pass the distinct new markers:

```text
PSC1_V2_GENERATED_PREFIX: PASS new=24 recursors=7 direct=6 privateIDs=3
PSC1_V2_GENERATED_PREFIX_JS: PASS new=24 recursors=7 direct=6 privateIDs=3
```

Both generated routes additionally pass their six-positive/seven-negative marker.
Native official controls pass five families, six positive cases and seven negative cases. The fixtures use
genuine mutual and nested admission, structured/numeric names, two universes,
53 initial padding nodes, 32 old checked declarations, final renamed auxiliary
recursors, a no-auxiliary nested fast case and two separate public batches.
They check every final owner/type/rule, original/private IDs, no duplicate or
flattening-only owners, wrong/missing owner declines, malformed universes,
old-tail stop and late import/command/kind atomic errors. The six direct cases
must return an actual internal result; an outer fallback cannot silently pass.

All 21 recursor proof equations, including seven new ownership/atomicity equations,
pass the axiom audit. Both frozen exact-3aa cache-mode and invalid-occurrence
defects are reproduced before the candidate is restored and rechecked.
All retained K/major/full-state, String projection 1296 / decline 16 / error 32,
checked/infer-only, cache, occurrence, Quot, transformation and negative gates
pass. Native correctness passes 62 safety/semantic assertions and four retained
transformation measurements.

Native detached provider 24-case and official 5-case controls pass. Each generated route
passes 24 provider plus eight API cases in a detached empty-PATH runtime. Complete portable
.lean and independently reconstructed/rechecked canonical .ps closures pass.
Generated execution uses authentic PSC1, TypeScript7.0.2 and Node22 with pinned
Lean4.35.0 commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Full-kernel DirectJS remains explicitly UNSUPPORTED.

| Artifact | ID | Archive bytes | Archive SHA-256 |
| --- | --- | ---: | --- |
| psc1-v2-dag-native | 12368370405 | 33171018 | `26acd2121aa9e7cac84a5d3169d847081ed902a060446b3e5ae2ca19e065fb9f` |
| psc1-v2-dag-generated-js | 12370435353 | 3396312 | `694d03166dcdeaa36bea445c963cea2df861e26f6d18d714013a20c6d9730a67` |
| psc1-canonical-kernel-qualification | 12369860303 | 1910801 | `fa8dd4aa3562f0a5c2813bb02b7b94b0af0dcf8a6124de9ff80ee1d4eea7bc20` |

Canonical source-closure SHA256: `7aae4c75f80c54385b8fe31a9f2a85ecf0221fbe541087ba7b5815d44981f728`.
Both generated TypeScript files share SHA256 `cad6e2933681bea732fdc13e190c0605c302a014dda2381ec71edea97d357326`.
The receipt records both emitted JS hashes, source maps, declarations, native executable and package hashes. Artifact hashes establish integrity; the terminal job gates establish the tested qualification.

## Full Arena and performance remain separate

Exact 7b14 full 193-case result: 173 matches (105 acceptance, 60 kernel rejection, one metadata rejection and seven transport rejection), two separate safety-contract agreements, 17 host timeouts, one Church resource exhaustion and zero unsupported results. Limits remain fuel 4096,
60 seconds/case, 2048 MiB Node old-space and two workers. Every original case is retained.
Timeouts are incomplete execution, fuel exhaustion is a resource outcome, and
unsafe/partial contract agreements remain separate from semantic matches.

Actual unchanged index 16 `bugs/rec-missing-ih.ndjson`: official and independent verdicts both rejected, classified matched_kernel_rejection at kernel-admission, coreInvoked=true and containsUnsafeOrPartial=false, with reason "simple inductive field has an invalid recursor-headed recursive occurrence".
Read-only saved-artifact inspection39655656481/job119415065277
authenticated source/run/ZIP digest/bytes and printed this actual record without
replaying a case. Original/adapted body SHA256 is
`b76add060cc9e030bc8769492783ed3ceb5e4482eb02cc83f1597c5b6007c769`; generated kernel module SHA256 is
`b14b37870d78356c56b208c292847809748a90538e145ba1c53a5a2d31b24849`. Header compatibility adaptation preserves original
record bodies and is not a claim of fresh native4.35 re-export.

Authentic diagnostics: four source-bound cases, each with profile_collection_complete=true and kernel_qualified=false. In unprofiled/profiled order: repeated-subproblem accepted/accepted; Church resource_exhausted/resource_exhausted; init-prelude timeout/timeout; stuck projection rejected/rejected. A passing collection job is not a
passing kernel case. Complete generated operation/admission and profile
benchmarks are preserved in their artifacts. Native pair-search ABBA samples
were 441131 / 497411 / 536087 / 465521 ns (frozen/worker/worker/frozen;
1024 entries, 200 calls), which establish **no pair-worker speedup**. Broader
performance/release D remains open; no general speedup is claimed. The source-local
A-B-B-A admission comparison still shows binder32 at 589.676 ms DAG versus
236.775 ms V1 (2.49x) and chain32 at 428.887 ms versus 281.820 ms (1.52x).
Each value is the median of that variant's two warm sample totals, not a
per-declaration time. Binder32 input construction is 93.880 ms DAG versus
0.799 ms V1. These are
same-source architecture comparisons, not a causal before/after T03a estimate.
All 128 operation and 24 admission observations, all 32 operation groups, six
admission groups and six profile summaries are preserved in the permanent receipt.

## Preserved source and failure history

Original `034999734f2574876a747c967dd03bcc6904b395` is fully observed and
**NOT A-qualified**: native integration119352848567 failed on eight
`discard (← action)` IO elaboration errors. Its generated integration,
correctness and six research jobs passed. Its full 193-case comparison failed with 173 matches,
two separate safety agreements, 17 timeouts, one Church resource exhaustion, and zero unsupported results.
Actual safe case 16 independently rejected for the precise recursor-headed
occurrence reason; the saved body remained identical. Profiles passed collection
only. See `evidence/2026-10-22-034-terminal-qualification.json`.

Concurrent fixture-repair parent
`33466d0b516df9d0496d181dd1c4b619b9954c7c` is preserved, with all its own
terminal outcomes in `evidence/2026-10-22-334-terminal-qualification.json`.
Its integration39640766956, correctness39640766736 and all six research39640766908 jobs passed, qualifying334 for scoped A by its own gates. Arena39640766732 failed with173matches,2safety agreements,17timeouts,1Church resource exhaustion and0unsupported. Its evidence is separate from 7b14; no parallel group/cache/
Quot/name-worker research was silently merged.

T03a production first landed at b60cb6a53b71899b033f758e3e730df06821f808.
The YAML replacement-escaping validation failure and focused total23/reserved
proof-binder failure remain in history. Repairs changed workflow/fixture/proof
text, not T03a production code. Corrected22a1d1721c26f7170cfbc5829603d4d5760fce2f
focused native run 39644321489 passed before the full 7b14 qualification.
Its receipt remains `evidence/2026-10-22-t03a-native-preflight.json`.

## Milestones and next implementation boundary

- **A:** scoped independent provider qualified at exact 7b14 by its own complete gates.
- **B:** open. T03b, full actual String.ofList (T01F), V1 inductive admission,
  recursive metadata import, eager ingress decode and four whole-operation
  fallbacks remain.
- **C:** open; exact 7b14 full 193-case comparison FAIL: 173 matches / 2 safety agreements / 17 timeouts / 1 resource exhaustion / 0 unsupported. Church, host timeouts and explicit
  safety-contract reconciliation remain.
- **D:** open. Whole-operation regressions, complete comparable performance and
  release qualification remain; global soundness/refinement/backend preservation
  obligations are not discharged by local equations or finite tests.

**After the existing combined-source qualification: T03b preexisting-session ownership.** Each public `psKernelV1RunDag`
still starts with `PsKernelDagExecutionState.mk session List.nil`; previous
session constants have no current-batch owners. T03a's second batch intentionally
owns only new Fast and asserts old Nat ownership absent. Derive private current
batch references only from the session's already admitted environment, preserving
immutable environment identity and original external input IDs. Do not trust
caller-supplied tables or receipts. Require direct old-constant checking/WHNF/
DefEq across separate calls and stale/mismatched owner, universe, private-ID,
full-state and late-error atomicity negatives in native/official and both
generated routes. Do not repeat the broad architecture audit.

---

## Preserved work-state history (verbatim)

# Current integration checkpoint — qualified base and measured name-worker promotion

Observed: 2026-10-21T18:16:44Z.
Branch: `integration/psc1-pskernel-expr-v2-lean435-20261021`.
This containing source integrates the exact name-comparison workers and tests from
`34126793178021a9cd1bdb37aa6fe17c0fab41c6` into the qualified new-prefix parent
`7b14affc854e7bc99e4778ac155ae805dd273226`, preserving both source histories.
Its own native, portable, canonical, generated, proof, benchmark and provider
qualification is **NOT RUN at commit creation**. A push must qualify this exact
combined revision; neither parent result is inherited.

## Latest exact source evidence

| Exact source | Native | Portable .lean | Canonical .ps | Generated JS | Proof | Benchmark | Arena | Provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 7b14affc854e7bc99e4778ac155ae805dd273226 | PASS | PASS | PASS | PASS | PASS | PASS collection; mixed performance | IN PROGRESS | PASS |
| 34126793178021a9cd1bdb37aa6fe17c0fab41c6 | PASS | PASS | PASS | PASS | PASS | PASS paired admission experiment | FAIL: all193,17timeouts,1fuel,1unsupported | PASS |
| Containing combined source | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

7b14's full [integration39645765038](https://github.com/dwijayuda/pskernel/actions/runs/39645765038),
[correctness39645764867](https://github.com/dwijayuda/pskernel/actions/runs/39645764867)
and [research39645765012](https://github.com/dwijayuda/pskernel/actions/runs/39645765012)
are terminal SUCCESS, all10jobs. Native119380795456/generated119380794907,
native119380794896/canonical119380794398 and all6research jobs are green.
The complete182-module portable profile,139-module canonical graph, real
PSC1/TypeScript7.0.2 outputs, detached empty-PATH execution, native24provider
cases and both JS routes'24CLI+8API cases passed. Official provider reference
checks five cases, including a real four-declaration batch.
New-prefix controls passed24owners/7recursors/6direct cases/3private IDs,
5official families/6positive/7negative controls and605generated assertions on
each JS route. All21 recursor/local publication proof statements passed.
Both frozen-parent defect sentinels, invalid-recursive-occurrence controls,
280-case mutual admission, fresh per-member budgets, scanner, binder-spine,
ordered DefEq and retained semantic gates remain present.

See `evidence/2026-10-21-new-prefix-qualified-receipt.json` for exact job URLs,
terminal outcomes, source-specific markers and all native/canonical/JS artifact
digests. This qualifies the documented limited developer/provider scope (A);
it does not qualify full V2 replacement (B) or full Lean Arena compatibility (C).
7b14 Arena39645764921 and authentic profiles39645764955 were still active at
this observation. Historical “pending” sections below are retained receipts.

## Change and measured reason

Only `Core/Name.lean` changes production semantics implementation: explicit
argument string/name comparison workers avoid constructing recursive curried
closures before the actual arguments are supplied. Public curried entry points,
character operations, raw-position behavior, arbitrary Nat fuel, name equality,
hash-collision handling and partial application ABI retain their exact results.
Eight source equations quantify over all raw strings/positions/fuel and names;
proof-file dependencies remain within propext/Classical.choice/Quot.sound.
No kernel fuel, admission policy, cache policy, hash authority or trusted runtime
path changes.

The regression files and existing integration/correctness/lake definitions add
the exact qualified341 tests:24576 raw comparisons,64 complete string pairs,
16raw controls,24long strings,400name pairs,4depth1024 names,10real checked
declarations,10official positives/4negatives and50237assertions per generated
route, including7partial-application executions. Existing7b14 new-prefix and
parent-regression gates are preserved rather than replacing whole workflows
with older research versions.

The pinned [paired experiment39645953379/job119381453525](https://github.com/dwijayuda/pskernel/actions/runs/39645953379/job/119381453525)
completed48correct public-admission samples,16authentic-case observations and
two138-case transport control suites on one AMD EPYC7763 runner in sequential
ABBA order, comparing f9e9b20f... with34126793.... The six DAG warm batch means
fell6.64%–29.45% (1.07×–1.42× speed ratios). Full report and summary are preserved
at [b3ff5e90c8113303c11c88d809ae4ffb10364449](https://github.com/dwijayuda/pskernel/tree/b3ff5e90c8113303c11c88d809ae4ffb10364449/psc1/packages/pskernel-core/evidence);
the summary and qualification receipt are included here.
This is a descriptive two-observation comparison per source, not a statistical
or whole-kernel speedup claim. Retained heap is mixed. DAG chain8 RSS increased
192432→195732KiB; the authentic stuck-elimination rejection's RSS increased
421436→449388KiB despite shorter runtime33.94→31.29s. Church still exhausted
fuel4096 and Prelude still timed out60s. That experiment used2048MiB V8
old-space, not an OS RSS cap; do not describe it as a hard2GiB host test.

## Current corpus and next executable work

Exact334 source's all193 Arena39640766732 now finished FAIL with173matches
(105accepted,60kernel rejection,1metadata rejection,7transport rejection),
2separately classified unsafe/partial safety-contract agreements,17host timeouts,
1Church fuel exhaustion,0unsupported. Exact341 Arena39640227692 finished FAIL:
172matches (105accepted,59kernel,1metadata,7transport),2safety,17timeouts,
1fuel,1unsupported. The sole classification difference is the already repaired
rec-missing-ih occurrence; this integration retains that repair. The official
corpus remains122accepted/71rejected with authenticated original body bytes
and adapted historical metadata headers, not a fresh native4.35 export.
Matching outcomes include transport/metadata refusals, not just admitted proofs.

Next, observe this exact combined push through terminal integration/correctness/
research and all193 outcomes. Keep the checked new-prefix carrier architecture.
T03b initial-session owners, coherent Quot-owner port and fallback retirement
remain unfinished. Four whole-operation fallback families, eager decode and
recursive metadata import remain; V1 stays the default/reference. The indexed
cache is held separately:5de's paired metadata8/32 admission regressed39.9%/27.4%;
384's explicit-worker repair must pass its own paired performance test before
promotion. Its native/generated/research gates are now green; canonical was
still at the final capability step when observed. A bounded host-only Church
DefEq trace is being prepared against pinned369bee58 to identify the actual
fuel-exhaustion path; no unexecuted trace is evidence.

Hard cgroup controls at275833e70351684b10256ec922aa90d13e813159 passed70parser,
6live and24progress controls, including touched-buffer OOM and descendant
cleanup, but a full authenticated193-case production2GiB run remains required.
Full-kernel DirectJS remains explicitly UNSUPPORTED. No global soundness theorem,
full V2 completion or full compatibility is claimed. No merge to main or package
publication is authorized by this checkpoint.

---

# Current T03a candidate — native preflight PASS; full qualification next

Observed: 2026-10-22 Asia/Jakarta (2026-10-21T17:37:37Z).
The completion plan's authoritative new-prefix implementation is complete.
Focused source `22a1d1721c26f7170cfbc5829603d4d5760fce2f` passed
[39644321489/job119375775009](https://github.com/dwijayuda/pskernel/actions/runs/39644321489/job/119375775009):
318-job native build, inherited official/independent occurrence controls,
24new declarations/7recursors/6direct cases/3private-ID negatives,
5official families/6positive/7negative controls, and all21 retained/new proof
equations. Seven equations are new. No forbidden proof axiom was observed.
Artifact12365544901 SHA256
`e9cfade93d8677334d8cc6489e05ad94292a697f754913169d586ca2411f62eb`.
The23-count and reserved-binder failures remain in history; production code was
unchanged by those fixture corrections.

This containing checkpoint records the preflight and is **NOT A-QUALIFIED at
creation**. The integration push must run its own complete native, authentic
portable .lean, canonical .ps, both detached generated, retained proof/provider
and benchmark gates. Observe the unchanged full193 comparison separately.
Do not inherit22a's focused result or a predecessor's full result as containing
source qualification. Last fully observed scoped A remains3aa until one complete
successor's own mandatory gates pass.

## Original034 qualification finished before new full qualification

Every originally requested run is terminal at exact
`034999734f2574876a747c967dd03bcc6904b395`; none was restarted.

| Run | Terminal result |
| --- | --- |
| Integration39637759611 | FAIL: native119352848567 fixture elaboration; generated119352848385 PASS |
| Correctness39637759709 | PASS: native119352848485 and canonical119352849214 |
| Research39637759603 | PASS: all six jobs |
| Full Arena39637759569 | FAIL: official119352847788 PASS; generated119354877930 records all193 |
| Authentic profiles39637759606 | PASS collection only,138controls; not kernel qualification |

Full193 records173matches (105accept/60kernel/1metadata/7transport),
2separate unsafe/partial contract agreements,17host timeouts,1Church fuel
exhaustion,0unsupported. Fuel4096,60seconds/case,2048MiB Node heap and2workers
are unchanged. Exact saved case16 `bugs/rec-missing-ih.ndjson` was independently
rejected at kernel-admission with coreInvoked=true, containsUnsafeOrPartial=false
and the precise invalid recursor-headed occurrence reason. Original/adapted body
SHA256 `b76add060cc9e030bc8769492783ed3ceb5e4482eb02cc83f1597c5b6007c769`
matches byte-for-byte. Generated module SHA256
`1452bf67b05e2d79094d67a27ef4d06ebbf9284e5f53c3175656c4f9c71371f2`.
Read-only inspection39644408838/job119376068451 authenticated source, run,
artifact12367210000, ZIP digest and bytes; it reran no kernel case.
See `evidence/2026-10-22-034-terminal-qualification.json` for all exact receipts.
034remains NOT A-qualified because of its native fixture failure.

Concurrent repair source `33466d0b516df9d0496d181dd1c4b619b9954c7c` is the
preserved parent of T03a. Its existing native integration119363358120 and native
correctness119363357569 passed, including both frozen-parent sentinels and all
occurrence controls. Its generated/canonical/research/Arena jobs were still
active at this observation. Continue observing them as separate source receipts;
do not duplicate, cancel, or inherit them. No parallel group/cache/Quot/name-worker
research source is silently included by this T03a batch.

## Next finite task

Finish this candidate's exact full qualification and record failures honestly.
After T03a passes, implement T03b preexisting-session ownership. Keep B open:
V1 inductive admission, recursive metadata import, eager ingress decode and all
four whole-operation fallbacks remain. T01F full String.ofList, global proof and
backend obligations, Church/timeouts, safety-contract alignment and performance/
release D remain open. Do not repeat the architecture audit or claim a general
speedup from finite examples.

---

## Preserved implementation and qualification history (verbatim)

# Current T03a implementation candidate

## 2026-10-22 — T03a candidate and evidenced native fixture repair

Initial live documentation HEAD was `45d8c3e52b6bd2c78ad4e656828b5c0ce79d19a1`;
implementation under qualification was `034999734f2574876a747c967dd03bcc6904b395`.
Immediately before this commit the live branch advanced concurrently to
`33466d0b516df9d0496d181dd1c4b619b9954c7c`, containing the same eight-call native
fixture repair, printed parent log and a source-bound failure receipt. This
candidate uses334 as its parent and preserves that complete work-state/history.
Existing334 qualification is observed as well; it is not rerun or inherited.
The existing five implementation034 qualification runs were inspected before any
replacement full pipeline. This batch is NOT QUALIFIED at creation. Exact3aa
remains the latest fully qualified scoped A until this candidate's own complete
mandatory gates terminate successfully; no predecessor qualification is inherited.

### Evidenced failure and correction

Implementation034 native integration job119352848567/run39637759611 failed
before executing the invalid-occurrence oracle/sentinel: its new native fixture
contained eight `discard (← action)` applications passing an extracted value
where Lean requires an IO action. The existing cache-mode parent reproduction
did pass. Read-only Actions diagnostic
[39640250554/job119361567049](https://github.com/dwijayuda/pskernel/actions/runs/39640250554/job/119361567049)
retrieved artifact12365440836 and printed the exact eight errors (lines127,128,
129,130,135,137,166,167), verifying ZIP SHA256
`709d73791269923f65cc4ec56424bcc1fd6855c4f140b3f123dce3ef74d01b17`.
It reran no kernel test. The inherited334 repair uses `discard (action)` at those eight sites,
retaining every action and assertion. The baseline test log is now printed before
the existing exact marker/status checks, so a subsequent failure is visible.

### Candidate workflow validation correction

First focused candidate `b60cb6a53b71899b033f758e3e730df06821f808` queued native
run39643101364. GitHub rejected the two edited full workflow files before jobs
were created (runs39643097899 and39643099513): a draft replacement string
misinterpreted the literal regular-expression end anchor followed by a quote,
duplicating the remainder of each YAML file. This successor restores one intact
copy and the exact JS positive/negative marker checks. No executable kernel,
test assertion, limit or failure classification changes. The focused native
run remains useful for diagnosis; final qualification must use this successor's
own complete gates. No duplicate full pipeline was launched.

### First focused native result and bounded test corrections

Candidate b60 native run39643101364/job119371513923 completed FAIL. Its318-job
kernel build and generated-test syntax check passed. The inherited occurrence
fixture passed both exact official and independent controls. The new T03a test
executed all owner/type/rule/input-ID/private-ID/old-tail checks before a mistaken
total-count assertion: checked Nat contributes four entries (Nat/zero/succ/rec),
so4+8+4+5+3 =24, with seven recursors. This successor corrects the exact total
in native/JS fixtures and workflow markers, preserving every semantic assertion.
The ownership proof used reserved binder name `matches`; it is renamed
`compatible`. The other six new equations already checked. Production source
is unchanged. This source needs its own successful focused and full gates.
Failed focus artifact12365713306 has SHA256
`51ea676c4185592860d5c87061301a1aef1e62ec8781015e1748a5ee4f34d027`.

Original034 full193 run39637759569/job119354877930 is terminal FAIL:
173 matches (105accept/60kernel/1metadata/7transport),2separate safety agreements,
17host timeouts,1Church resource exhaustion,0unsupported, fuel4096. The actual
unchanged case16 (console17/193) now reports official=rejected,
pskernel=rejected, matched_kernel_rejection. Its saved detailed record is being
authenticated separately. This does not repair034's native fixture failure or
qualify the T03a successor. All six original034 research jobs are terminal PASS.

### Bounded T03a implementation

`API/DagGenerated.lean` now walks only the new prefix of the successfully checked
final environment, stopping before the first exact name found in the previous
environment. Final recursor types/rule RHSs, restored nested headers/constructors
and renamed auxiliary recursors come exclusively from that final checked state.
Ordinary/mutual type IDs reuse only matching current-command input refs already
staged after admission. Nested requests import their final restored types; raw
nested input IDs and flattening-only families are not published.

The old three-argument ordinary helper remains unchanged. Production
`RunCommandsWithSource` supplies its previous and current environments to the new
entry. The original input table remains the external ID boundary; generated IDs
are private. A late import failure returns internalError before any batch result.
Unexpected prefix kinds are an internal invariant error, not semantic rejection.
There is no environment-size prepass, whole old-environment scan, new checking
authority, fuel change or callback-state reconstruction.

Focused native/official and both detached generated-route tests cover a genuine
two-family mutual declaration, Tree/List nested restoration including its final
auxiliary recursor, nested no-aux dispatch, structured/numeric names, two original
universe parameters, nonzero IDs, exact input-ID reuse, private IDs, absent or
mismatched owners, malformed universes, old-tail poison, failure atomicity, an
unrelated appended declaration and two public batches. The second batch owns
only its new Fast family; preexisting-session refs remain T03b. Seven added
source equations audit state preservation, arbitrary-tail stopping and atomic
error results. Original recursor/K/major/state/resource/negative suites remain.

The focused Actions branch is `work/psc1-pskernel-t03a-prefix-20261021`.
Its native gate checks this bounded slice before integration's final full gates.
Implementation034's other existing runs and the concurrent334 successor's
already launched runs must be observed to terminal and recorded separately. Do not launch duplicate full qualification or claim this source is A
until its exact native, both generated routes, canonical, proof and provider gates
pass. Full Arena C and performance/release D stay separate from scoped A.

B is still open: inductive admission remains V1, generated metadata import remains
recursive, eager ingress decode and all four public whole-operation fallbacks
remain. T01F full actual String environment, T03b preexisting-session ownership,
Church/resource/timeouts, safety-contract reconciliation and global proof/backend
obligations are unchanged. Default fuel4096 and all published limits are intact.


---

## Preserved integration history (verbatim)

# Current implementation — execute the occurrence fixture actions correctly

Observed: 2026-10-21 17:05:06 UTC
Integration parent: `45d8c3e52b6bd2c78ad4e656828b5c0ce79d19a1`
Implementation/test predecessor: `034999734f2574876a747c967dd03bcc6904b395`
Status: **IN PROGRESS; this corrected source is NOT RUN at commit time.**

Exact034 native integration[39637759611/job119352848567](https://github.com/dwijayuda/pskernel/actions/runs/39637759611/job/119352848567)
failed before the official occurrence oracle or semantic regression could run.
The existing cache-mode parent reproducer passed. The next parent overlay built,
but the new native fixture failed elaboration at eight `discard (← action)`
calls: `discard` requires an IO action; the do-bind had already extracted its
Environment/AdmissionResult. This is a native fixture source defect, not an
observed result from the new kernel guard.

The original redirected log was recovered without local tools in
[39640054167/job119360894356](https://github.com/dwijayuda/pskernel/actions/runs/39640054167/job/119360894356),
which authenticated exact producer/source and artifact12365440836
(5009bytes; ZIP SHA256
`709d73791269923f65cc4ec56424bcc1fd6855c4f140b3f123dce3ef74d01b17`).
That diagnostic collection passed; it does not qualify the kernel.
This successor removes only the eight premature binds and keeps every actual
official/kernel action, expected failure and assertion. The parent-reproduction
step now prints its saved diagnostic before enforcing the unchanged markers,
so a future fixture or semantic failure is directly visible in terminal logs.
No production kernel or generated test change accompanies this repair.

## Immediate required gates

Observe this exact successor's native, authentic PSC1, canonical, generated,
provider, proof and full193 Arena jobs to terminal. Preserve both expected
parent failures, restored controls,4096fuel and safety/error ordering.
Do not claim034 or this successor qualified from464's passing native checks
or from diagnostic collection.

Parallel research has independently qualified group-owner source
`89c8b988fc349fa57d7757c8d11fe0b94f9e9188` on integration39631113440,
correctness39631113291 and all six research39631113206 jobs. Its full193 run
39631113544 still FAILS:172matches (105accept/59kernel/1metadata/7transport),
2separate safety agreements,17timeouts,1fuel exhaustion and1unsupported.
The cache-only source `5deaf5880c83a76290520fa1176982dab0bf87a5` has
terminal native/generated integration39631703411 PASS; canonical completion
is being observed separately. Its full19339631703412 FAILS:175matches
(108accept/59kernel/1metadata/7transport),2safety,14timeouts,1resource,
1unsupported. All193 records exist; differences between runners alone do
not establish a causal speedup. The paired authenticated artifact experiment
39639125591 is running and has not yet yielded a reviewed performance result.

Those research sources are not silently included here. A history-preserving
combined group/cache source is prepared, preserving the cheapRec correction,
the safe recursor guard and all current documents; promote only after the
current integration blockers and component gates have been resolved.
The separate Quot owner and name/radix worker candidates remain explicitly
under qualification. V1 remains the default/reference, whole-operation
fallbacks remain, DirectJS is unsupported, and gatesB/C are not achieved.

---

## Preserved integration history (verbatim)

# PSKernel-Core Expression V2 integration work state

Date: 2026-10-21 (Asia/Jakarta; Actions timestamps use UTC)
Status: **IN PROGRESS — independent developer kernel; complete V2 and Arena gates remain open**
Integration branch: `integration/psc1-pskernel-expr-v2-lean435-20261021`
Lean: `leanprover/lean4:v4.35.0`, exact commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`
Generated path: authentic PSC1 → TypeScript `7.0.2` → Node `22`. Full-kernel DirectJS is unsupported.
Default kernel fuel: **4096**, unchanged. No new runtime axiom or trusted reduction path.






## 2026-10-21 — native cache/proof corrections pass; String fixture repair

Exact **8de5a76a7db17f4d7ea26eb55ddf79f53bfbc469** native integration
[job119330103262/run39631360558](https://github.com/dwijayuda/pskernel/actions/runs/39631360558/job/119330103262)
is terminal FAIL, so this source is not A-qualified. It compiled the complete
checker, reproduced the original3aa cheap-cache sentinel again, then passed the
new native cache-mode beta/let controls, both pair-scan all-input equations,
all16 fuel-worker/historical-mode proof audits, provider controls and native
benchmarks. Other mandatory suites executed independently.

Two String fixture defects failed: the retained old DAG probe still demanded
the deliberately removed unsupported branch; the new owner probe assumed two
equal independently imported Nat7 nodes had one ID. This successor replaces
the obsolete expectation with direct V1 parity and exact mandatory-callback
sentinels in both modes, and makes the selected-field probe compare structure
while returning the actual selected ID. Every owner-stage/error/resource and
public invalid-input control remains; no production source or limit is changed
by this fixture repair.

The new native hash-miss scan samples at8de are frozen562664ns, worker528249ns,
worker551563ns, frozen527838ns (1024 entries/200 calls per sample). These small,
mixed timings do not establish a performance improvement. Linear lookup cost
remains and no whole-kernel gain is claimed.

The completion plan now records the concrete T03a authoritative-new-prefix
algorithm and signatures. A separate host-only native theorem-stage probe is
committed at diagnostic **d3730ae4e72f91a5dda010bc6b7f40d4f379f780** on
research/psc1-arena-logical-20261021, run39631889379, with production369bee,
original input and4096 fuel unchanged. It was queued at this observation; no
first-failure result is invented. This is not integration qualification.

The containing successor is NOT RUN at creation. Exact3aa remains the latest
fully qualified scoped A until all this successor's own terminal gates pass.
Inspect fresh native, both generated routes, canonical, proof, provider,
benchmark and full193 results; then execute T03a without another broad audit.

## 2026-10-21 — exact-parent reproducer PASS; portability and proof repair

Candidate **4f6303fd90742ccc5e3d4f56b65dc658a7fb0eb5** is NOT qualified.
[Integration39630047130](https://github.com/dwijayuda/pskernel/actions/runs/39630047130)
native119325549240 actually reproduced the original3aa cheap-cache defect at
15:57:10Z with the required exact sentinel. The candidate then failed the new
pair lookup proof: simp left a definitionally equal goal. Generated119325548697
failed PSC1 parsing of an inline conditional argument in WhnfCore:277.
All five source workflows terminated FAIL; no skipped gate is a PASS.

This successor uses named Boolean cache-publication helpers, preserving the
same two-flag policy within the portable source grammar. The pair proof adds
rfl after rewriting. The existing unrestricted frozen WhnfCore equivalence
cannot hold after deliberately correcting cheapRec cache state. Its historical
beforeWhnfCoreWithFuel is retained unchanged; a separately named corrected
eager reference differs only in the five publication masks. The all-mode
delayed-worker theorem explicitly compares that corrected reference, while a
new all-input theorem proves exact historical result/state when cheapRec=false.
All other14 fuel-worker lemmas and the original15-worker PASS marker remain;
16 theorem axiom audits and a new corrected/historical-mode marker are mandatory.
No old buggy policy is relabeled equivalent to the correction.

The plan explicitly states that authentic case16 rec-missing-ih must match
official REJECTION after missing validation is implemented, while valid nested
controls must ACCEPT. Its current unsupported result is not a rejection.

The containing successor is NOT RUN at creation and requires fresh same-source
native, both generated routes, canonical, proof, provider, benchmark and full193
gates. Exact3aa remains the latest qualified scoped A until then. No fuel,
resource limit, runtime trust or existing semantic assertion is relaxed.

## 2026-10-21 — deep audit and bounded cache/WHNF corrections

Baseline **3aa077cb64ff06f76727decd01c43ad6c33f351d** is now fully observed for
the scoped independent developer provider: [integration39622318383](https://github.com/dwijayuda/pskernel/actions/runs/39622318383)
native119298737696/generated119298738193 PASS; [correctness39622318348](https://github.com/dwijayuda/pskernel/actions/runs/39622318348)
native119298737337/canonical119298737884 PASS; all six
[research39622318349](https://github.com/dwijayuda/pskernel/actions/runs/39622318349) PASS.
This is A only, using the independent V1 provider and authentic TypeScript7.0.2/Node22
routes. Full-kernel DirectJS remains unsupported.

The exact baseline [full193 Arena39622318341](https://github.com/dwijayuda/pskernel/actions/runs/39622318341)
is terminal FAIL:172 matching outcomes (105 acceptance,59 kernel,1 metadata,
7 transport),2 separately classified unsafe/partial safety agreements,17 host
timeouts,1 Church fuel exhaustion and1 nested unsupported case. No incomplete
result is a semantic rejection. [Permanent retrieved evidence](evidence/2026-10-21-3aa-deep-audit.json)
preserves the source/run/input/artifact identities and all21 diagnostics.
The strict current all193 predicate also requires explicit safety-contract
reconciliation; changing those labels to manufacture parity is forbidden.

The **containing correction is NOT RUN at creation**. Fresh exact-source native,
portable .lean, canonical .ps, both generated routes, local proofs, provider,
benchmarks and full Arena gates are mandatory. Never inherit the baseline PASS.

### Implemented source changes requiring fresh qualification

- Both V1 Reduction/WhnfCore and V2 WhnfOwned previously suppressed normal-core
  cache publication only for cheap projections. A cheap-recursion beta/let
  wrapper could publish a deliberately stuck recursor. The correction suppresses
  publication for either cheap flag, preserves actual reduction flags/ABI/fuel,
  and retains full-mode caching. New checked alias/recursor fixtures require
  cheap mode stays blocked, warm-full=cold-full=7 in both representations,
  no cheap publication, normal publication, zero-fuel precedence and official
  Lean check/DefEq. Linux CI must first reproduce the exact new sentinel against
  unmodified parent3aa production files, then restore and rebuild this source.
  Current production DefEq ordinarily uses cheapRec=false; no public false-proof
  acceptance is claimed from the internal mode-crossing defect.
- DAG String-literal projection now uses the existing canonical constructor
  builder and mandatory owning public-WHNF callback before ordinary field
  selection.1296 direct differentials,16 complete-state probes and32 failure
  probes are added in native and both generated routes. Native official Init
  adds8 valid/16 invalid controls. Minimal PS fixtures lack the complete real
  String.ofList closure: they prove branch/state/refusal parity and direct
  completion, not full authentic-prelude normalization. That qualification is
  a separate open T01F task.
- DefEqPair uses an explicit-argument worker under its unchanged curried ABI.
  A frozen original recursion has all-input worker/ABI equation theorems and
  printed axiom dependencies. Nine native/generated cache controls preserve
  collisions, reverse pairs, first errors, scope/FVar policy and zero-fuel order.
  The native ABBA scan microbenchmark has attainable hash misses; it is a local
  workload measurement, not a whole-kernel speed or complexity improvement.
- Existing mandatory assertions/counts remain. Native/generated/canonical
  workflows additionally require the new String, cache-mode and pair markers.
  The original four whole-operation fallback families, eager decode, recursive
  metadata import and V1 inductive admission remain. Default fuel4096 and all
  published resource/trust policies are unchanged.

### Authoritative completion handoff

Read [deep audit](docs/PSKERNEL_CORE_LEAN435_DEEP_AUDIT.md),
[ordered completion plan](docs/PSKERNEL_CORE_COMPLETION_PLAN.md),
[progress matrix](docs/PSKERNEL_CORE_PROGRESS_MATRIX.md) and
[ready-to-copy continuation](docs/AI_CONTINUATION_PROMPT.md).
Research compares pinned actual Lean, con-leche and con-ron sources and records
which mechanisms to adopt or reject. The queue separates A/B/C/D, implementation
from qualification, and local lemmas from unresolved global soundness/backend
preservation obligations.

After this source's gates terminate, fix any demonstrated mandatory failure
first. If qualified, next main slice is T03a checked mutual/nested generated
recursor ownership in API/DagGenerated; T08a host-only native Church theorem
stage attribution can proceed independently on the existing diagnostic branch.
Do not repeat a broad audit, reimplement completed slices, reset fuel, remove
negative cases, merge main or publish npm.


## 2026-10-21 15:02 UTC — integrate qualified complete-state carrier; fresh merge gates

The carrier source **`4894fce8c7d048ae188495bc2090fedfddf7fcb4`** is now
qualified for the documented scoped independent developer provider and its
mandatory V2 migration matrices. Its [integration 39614047016](https://github.com/dwijayuda/pskernel/actions/runs/39614047016)
is terminal PASS (native 119270188540, generated 119270188049);
[correctness 39614046627](https://github.com/dwijayuda/pskernel/actions/runs/39614046627)
is terminal PASS (native 119270185932, canonical 119270185717); all six
[research 39614046465](https://github.com/dwijayuda/pskernel/actions/runs/39614046465)
jobs passed. [Exact carrier receipt](evidence/2026-10-21-4894fce.json) preserves
file/artifact digests and source-bound summaries. The complete portable profile
has 182 modules/two roots; independently reconstructed and checked canonical
.ps has 139 modules, closure SHA256
`e89e31fa578cb57a0990f243a4e0fa9261b93caefc69b9a6c77329737c06ebd7`.
Native passes 24 detached empty-PATH protocol cases and five official fixtures;
each authentic generated route passes 24 protocol and eight API cases.
Complete-kernel DirectJS is explicitly UNSUPPORTED.

This integration merge retains both parents: previous integration
`a2590cc15c764dae9c6abfb941d6c3155ead5c81` and qualified carrier4894.
The **merge commit itself is NOT RUN at creation**. Its exact Git commit ID
and push-triggered terminal gates must be checked before assigning it a PASS.
No parent's CI is inherited. The source combines the single complete CheckState
WHNF/DefEq/inference callback owner, ordinary checked K recursor ownership,
K conversion and Nat/String/structure major normalization. The staged raw
WHNF ABI, terminal DefEq and original universe-negative controls are retained.
The canonical job retains its 75-minute build ceiling; kernel resources and
60-second Arena case limits are unchanged.

### Exact-source gate table

| Source | Native | Portable .lean | Canonical .ps | Generated JS | Local proofs | Benchmarks | Arena | Provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| a2590cc15c764dae9c6abfb941d6c3155ead5c81 | PASS | PASS | PASS | PASS | PASS | PASS selected; regressions | FAIL | PASS |
| 4894fce8c7d048ae188495bc2090fedfddf7fcb4 | PASS | PASS | PASS | PASS | PASS | PASS selected; regressions | IN PROGRESS | PASS |
| This history-preserving integration merge | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

Carrier4894 passes the mandatory non-K-major 126 public/504 core/360 owner/
432 reducer comparisons, K 108 public/432 core/648 reducer and 96 independent
owner-budget cases, the full carrier 42/56/540/38/44 and admission/public-WHNF
8/12/336/168 matrices, original mutual280/eight-official and all earlier smoke
controls. Actual checked positive and negative declarations have official Lean
fixtures. All required local proof/axiom-audit gates passed; local equations
and finite tests do not establish global soundness.

The carrier [full Arena 39614046557](https://github.com/dwijayuda/pskernel/actions/runs/39614046557)
is still running at this observation. Its official job 119270185141 passed;
no generated total is claimed until job 119271283488 terminates.

### Fully observed integration a259 and performance

The earlier exact integration a259 independently has terminal PASS in
[integration 39612691517](https://github.com/dwijayuda/pskernel/actions/runs/39612691517),
[correctness 39612691610](https://github.com/dwijayuda/pskernel/actions/runs/39612691610)
and all six [research 39612691695](https://github.com/dwijayuda/pskernel/actions/runs/39612691695)
jobs. Its complete [193-case Arena 39612691512](https://github.com/dwijayuda/pskernel/actions/runs/39612691512)
is terminal FAIL: **172 matching outcomes** (105 acceptance, 59 kernel rejection,
one metadata rejection, seven transport rejections), **two separately classified
unsafe/partial safety-contract agreements, 17 host timeouts, one kernel-resource
exhaustion and one unsupported case**. All 193 records and 21 nonmatching
diagnostics are preserved in [the permanent a259 receipt](evidence/2026-10-21-a2590cc.json).
Timeout indices are 23,72,78,80,82–87,90–94,96,98; index81 is Church fuel
exhaustion and index16 is unsupported nested recursive occurrences. Neither
timeout nor resource/unsupported outcome is counted as a parity pass.

[The performance report](PERFORMANCE_2026-10-21.md) now preserves fresh a259
and4894 samples and complete tables, including cold/warm, construction and RSS.
At4894, binder32 admission is 554.792 ms DAG versus 260.326 ms V1, construction
87.211 versus 0.730 ms and maximum RSS 357948 versus 340360 KiB. Projection8
WHNF is 52.455 versus 34.584 ms. Selected native unique/collision groups also
regress. Historical selected 8–16× gains are not a whole-kernel or current-source
claim. The existing generated comparison's 2048 MiB V8 old-space cap is not
an operating-system RSS cap.

### Authentic native resource attribution and remaining work

The separate [native replay 39620233494 / 119291437634](https://github.com/dwijayuda/pskernel/actions/runs/39620233494/job/119291437634)
is terminal PASS diagnostic collection at harness44ca03e, using exact production
`369bee5801bd5e4476837684fad3f7e1ca8c422c`.
[Permanent native receipt](evidence/2026-10-21-44ca03e-native-v1.json) shows that
original V1 admits three original Church requests and returns actual fuel
exhaustion on request index3 at fuel4096. Runtime was 0.689668 seconds including
launch; sampled VmHWM was at least 76,443,648 bytes. The cgroup charged-memory
peak of 15,990,784 bytes is different accounting from RSS. All 138 transport
and three actual native controls passed; exported metadata was never installed.
This reproduces the generated resource result, but official Lean accepts, so
the compatibility case remains open. It is not a current-merge kernel gate.

**A is achieved at exact a259 and4894 for the documented scoped V1 developer
provider; B and C remain unachieved.** V1 remains the default and separately
selectable reference. Four full-operation fallback sites, initial validated
arena decode, recursive generated-metadata import, V1 inductive admission,
missing mutual/nested and preexisting-session owners, and String-literal
projection WHNF remain. No new trusted runtime path or resource change is made.

The carrier history below is preserved verbatim. The distinct integration
work-state history at a259 is archived in
[evidence/work-state-integration-a2590cc.md](evidence/work-state-integration-a2590cc.md),
so neither side's receipts or earlier failures are overwritten.
Next: inspect this merge's exact native and both generated-route gates; qualify
the isolated String-projection slice, then complete post-admission mutual/nested
owners and the measured cache lookup bottleneck with full differential gates.
No asynchronous continuation is asserted.

## 2026-10-21 — repair recursor regression fixtures after exact884 native failure

Parent source: `88404214aebfea49824676f70bfc78125fe62e46`, carrier branch.
[Native integration job119266914119](https://github.com/dwijayuda/pskernel/actions/runs/39613110413/job/119266914119)
is terminal **FAIL** during fixture compilation. Production RecursorMajor,
RecursorK and the complete checker compiled, but the new runtime matrices and
proof steps were skipped. Native correctness119266910334 in
[39613110409](https://github.com/dwijayuda/pskernel/actions/runs/39613110409)
is terminal PASS; that separate job does not qualify the skipped regressions.
At this repair,884 generated integration was queued and canonical source checking
was still in progress. Those results cannot qualify this child.

The non-K V1 axiom fixture now wraps its header/safety in PsKernelAxiomInfo
(native and generated JS); the separate DAG request keeps its correct shape.
The K native fixture now uses explicit branch layout for two multiline assertions
and assigns its final arena to the existing mutable input instead of shadowing it.
Every assertion, fixture, callback, budget, matrix count and production source
is unchanged. This is a fixture correction, not a semantic relaxation.

This exact child is **NOT RUN** at creation for native integration, portable
source, canonical .ps, generated JS, proofs, benchmarks, Arena and provider.
Fresh push-triggered full gates are mandatory. Integrationa259 native integration
and native correctness are terminal PASS; its generated/canonical jobs still run.
The authentic diagnostic39607734805 has reached unchanged-limit profile collection
against pinned369bee; collection status is not kernel qualification.

Next: inspect this child's native build, matrices and local proof steps, then
both detached generated routes and their full provider controls. Preserve the
qualified727 receipts and the still-open B/C limitations below.

## 2026-10-21 — complete-owner K and major recursor candidate; fresh gates mandatory

Candidate branch: `research/psc1-pskernel-v2-carrier-20261021`.
Production review parent: `0a031a7bbbfc5040f2eeeb25c73432345dfb9634`;
previous pushed carrier: `bd35452a1c10f22bc7e863efafd1a868a3fe3b72`.
Integration now contains history-preserving merge
`a2590cc15c764dae9c6abfb941d6c3155ead5c81` of qualified staged727 and889;
the merge's own fresh jobs are pending. **This candidate is NOT RUN at creation**
for native, portable-source, canonical, generated, proof, benchmark, Arena and
provider gates. No parent's PASS is inherited.

### Implementation and mandatory coverage

`Checker/ExprV2/RecursorMajor.lean` directly walks checked private recursor types,
builds exact field projections, normalizes Nat/String majors and expands eligible
nonrecursive structures while retaining every callback's full CheckState.
String always performs the fixed public WHNF callback after exact construction.
`RecursorK.lean` implements the original infer/public-WHNF/index-guard/candidate/
infer/DefEq sequence. K uses the normalized major TYPE universes, runs before
the constructor shortcut, and retains the full state on false DefEq. Expression
mvars in indices and universe-only mvars remain distinct.

`Recursor.lean` now shares the post-conversion iota pipeline. Ordinary checked
K metadata is installed by `API/DagGenerated.lean` after validated admission,
using private appended nodes and original declaration IDs. The original raw
compatibility path remains explicitly limited. The two constructor-valued
intermediate conditionals are explicitly typed for portable inference.
No new runtime axiom, trusted hash, unsafe/extern/intrinsic path, resource limit,
callback predecessor, or failure-order rule is introduced.

Native and both authentic generated routes must run:
- Retained recursor252-public/504-core/720-owner/72-reducer matrices, original
  private-ID and universe-negative controls.
- Non-K major126-public/504-core/360-owner/432-reducer comparisons;4 full-owner
  sequences and40 exact failures;70 family walks/20 field-budget controls;
 24 raw String callbacks/48 failures with6 native official String checks.
  Six checked neutral-major cases and four strictly direct declaration admissions
  (2 valid/2 invalid) also have official native controls. Raw ill-typed String/
  Nat-rec probes are explicitly excluded from admitted-proof counts.
- K108-public/432-core/648-reducer/96-independent-budget comparisons;16 full-owner,
 16 failure-propagation and16 mvar-metadata controls;5 order/resource guards.
  Actual checked KUnit and indexed KEquality metadata, two checked theorem majors,
  six positive/three negative expressions and two strictly direct definition
  admissions are compared with V1 and native official Lean.
- Arena markers make each callback's appended graph changes observable, alongside
  every semantic cache and fresh counter. Deliberate arena-loss negatives verify
  the marker. An outer unsupported attempt cannot satisfy direct-admission tests.
- Existing14 recursor,21 owned-state and2 ABI lemmas, plus10 major and6 K local
  equations with printed axiom dependencies. The new statements establish local
  guard/state facts under explicit premises, not global semantic equivalence.

The carrierbd generated and canonical failures were a fixture defect at
owned-state-smoke.mjs:544–546. The five-argument callback factory was supplied
four arguments. This child supplies the result through explicit lambdas,
preserving every assertion and42/56/540/38/44 plus8/12/336/168 counts.
The new major JS test similarly wraps the flat local-value export into the
curried callback shape required by the checker. These are test ABI corrections.

### Exact predecessor evidence and remaining scope

Source727 native119237791103/generated119237790434 in integration39604699608,
native119237794295/canonical119237793626 in correctness39604700328 and all six
research39604699278 jobs are terminal PASS. This qualifies **A only for the
documented scoped V1 developer provider at727**. Portable closure177 modules/
two roots and canonical134 modules passed, as did detached native24 and each
generated24-provider/8-API exercise. Full-kernel DirectJS is UNSUPPORTED.

The [permanent727 receipt](evidence/2026-10-21-727b3dd.json) records all per-file
digests and193 exact Arena classifications. Arena39604699432 is terminal FAIL:
172 matching outcomes (105 accepted,59 kernel rejected,1 metadata rejected,
7 transport rejected),2 separate safety-contract agreements,17 host timeouts,
1 church reduction-budget error and1 unsupported nested-recursion case.
Carrierbd Arena39604877083 independently has the same category totals.
No timeout/resource/unsupported outcome is a parity pass.

[Performance receipts](PERFORMANCE_2026-10-21.md) preserve all19 native,
32 generated and6 admission groups at727, including slower collision/projection/
binder workloads and mixed memory. Binder32 admission is219.048ms V1 versus
555.452ms DAG per measured batch. There is no general V2 performance qualification.

Four public whole-operation fallback sites, initial whole-arena decoding,
recursive generated-metadata import, V1 inductive admission, incomplete owner
installation for mutual/nested recursors and String-literal projection WHNF
remain. V1 stays selectable and the default provider. **B/C remain unachieved.**
The resource diagnosticab61 in39607734805 builds pinned369bee and remains
IN PROGRESS; collection success will not imply checker parity.

Next executable action: inspect this exact candidate's push-triggered native
build and all independent regression steps; fix actual semantic, portability,
ABI or fixture defects without weakening gates. Then wait for both authentic
generated routes, local proofs, provider, performance and full193-case Arena
jobs to terminate. Promote only a qualified successor, using a fresh expected
integration SHA and preserving both branch histories.


## 2026-10-21 — recursor-major migration review, qualification pending

This source follows carrier `bd35452a1c10f22bc7e863efafd1a868a3fe3b72`.
At creation it is an unreferenced review commit; no production branch is changed.
Its new recursor semantics are **NOT RUN**. Native/generated/official regression
additions and exact-source full qualification are required before promotion.

The single owned recursor pipeline now handles validated ordinary K conversion,
String constructor expansion and non-recursive structure conversion directly
over canonical DAG IDs. The major family comes from the privately owned type
installed after complete checked inductive admission. K conversion precedes
the constructor shortcut; normalized major-type levels supply the candidate.
The expression-metavariable guard examines only indices after numParams.
Candidate inference and DefEq keep their exact order, argument order and full
returned state, including false. Public WHNF is mandatory at the same V1
positions even when the initial major reduction uses cheap core WHNF.

The checked generated metadata bridge installs ordinary K types and rules only
after validated admission, with the same original-ID/private publication guard.
That bridge still imports recursive expressions and inductive admission remains
a V1 operation. Existing callback-limited compatibility helpers preserve their
explicit K/String/structure unsupported boundary. No temporary checker, trusted
hash, new runtime axiom, fuel/depth increase or unsafe path is introduced.

Four public whole-operation fallbacks remain. This is not full V2 completion or
full Lean conformance. The additional native/generated tests must cover real
checked K and indexed equality metadata, official admission, fixed-fuel/depth
decisions, callback ownership and refusal order; the old metadata-owner absence
control now verifies exact installed K type/rule ownership. Other old assertions
remain. Existing14 recursor theorem statements are unchanged; simplifier lists
name the extracted common pipeline.

Parent carrierbd native integration119238388859 and native correctness119238388545
are terminal PASS, and its complete portable .lean check and independently
checked canonical .ps closure pass. Generated runtime qualification remains
IN PROGRESS at this review. Staged727 generated semantic/provider gates have
passed and its benchmark is running; its overall job remains IN PROGRESS.
Both727 andbd have all six research jobs PASS. The integration branch remains
the fully qualified limited-scope V1 developer provider at8892406; A PASS only
there, B incomplete, C FAIL.

The authentic resource diagnostic is isolated at
`ab61efebac4e0b09cc3bf57c09380ae53ac2cf7f`,
[run39607734805](https://github.com/dwijayuda/pskernel/actions/runs/39607734805),
still IN PROGRESS. It uses production369bee and unchanged proof body/fuel/host
limits; collection success will not qualify the kernel.


## 2026-10-21 — carrier boundary and generated ABI repair candidate

Branch: `research/psc1-pskernel-v2-carrier-20261021`.
Previous branch HEAD: `4dee3fe1dc6791aa491f101db876898e10449a01`.
The reviewed boundary/extraction object039eed is preserved as the parent of this
correction; it was never promoted to a branch or claimed to build. Before
qualification, its new full-state helper was renamed
`psKernelExprV2TryWhnfCheckStateWithFuel` to avoid the existing standalone raw
`TryWhnfStateWithFuel` export. The raw ABI and its callers remain intact.

In addition to the owner/extraction changes described below, this candidate
restores explicit zero/successor fuel staging in the two compatibility wrappers
`TryWhnfCoreModeWithLocalValuesFuel` and `TryWhnfStateWithLocalValuesFuel`.
The original immediate-lambda refactor changed PSC1's external argument shape;
both carrier6cb generated routes completed compilation but failed main-smoke3705
with undefined arena, while staged841 and ea84 failed the same call with undefined
recDepth. The exact prior carrier jobs were119220899565 and119220899827; staged
ea84 generated119228846446 is also terminal FAIL. These are runtime ABI failures,
not kernel rejections.

Both repaired wrappers call the same owned algorithm at the unchanged fuel.
Two local equalities compare their exact pre-repair bodies; early generated
probes require two staged exports, four fuel partial applications and six
real-state zero/successor result/error calls. All existing full smoke, callback
sentinels, owner matrices and new8/12/336/168 admission/public matrices remain.
The native proof gate now requires21 owner lemmas plus2 separate ABI lemmas.
No fuel, depth, elaborator, timeout or memory limit is raised.

This combined source is **NOT RUN** for all qualification gates at commit
creation. The staged branch now independently carries ABI repair727b3dd; its
earlier ea84 native PASS does not qualify either new source. Integration889
remains the terminal-green scoped Gate A checkpoint. Gate B is incomplete and
Gate C fails; both branches still require terminal native and both generated
qualification before promotion.

## 2026-10-21 — close full-state admission/public WHNF boundaries

Branch: `research/psc1-pskernel-v2-carrier-20261021`.
This source update follows `4dee3fe1dc6791aa491f101db876898e10449a01`.
All changed-source qualification gates are **NOT RUN** at commit creation.
Integration889 remains the qualified scoped provider; this branch is not promoted.

Exact parent [integration39602127491](https://github.com/dwijayuda/pskernel/actions/runs/39602127491)
failed native job119228992209 while elaborating the large
`PsKernelExprV2OwnedStateRegression.lean` declaration at line624; the unknown
`regression` error at line767 was cascading. Production kernel modules compiled,
and [native correctness119228991271](https://github.com/dwijayuda/pskernel/actions/runs/39602127347/job/119228991271)
passed. The fixture now extracts the existing262-line DefEq/failure group into
a private helper. Its probes, callbacks, ordering and assertions are preserved
exactly; neither Lean elaborator limits nor kernel resource limits are raised.

A boundary audit found two omitted full-state transitions:
`AdmissionEnsureSortWithFuel` and `AdmissionIsPropWithFuel` still initialized
a standalone WHNF-only owner and merged its partial result into an older state.
They now use complete-state normalization and retain the returned inference,
DefEq, unfold/failure caches and fresh counter. The internal shared sort helper
always runs public WHNF, including on syntactic sorts, matching SessionEnsureSort.
The proposition helper still runs inference-only first and mandatory WHNF second,
using the same fixed admission fuel. None/error propagation and malformed
callback-result refusal remain ordered.

`Check.lean` now supplies the fixed owning DefEq callback through
`psKernelExprV2TryWhnfCheckStateWithFuel` and a fresh declaration-aware public WHNF
boundary. `API/Dag.lean` uses that entry after its unchanged mandatory input
checking. The old WhnfState ABI remains a standalone compatibility wrapper;
production public WHNF no longer supplies NoOwnedDefEq to its recursor knot.
No earlier public check's caches are transferred into the new WHNF operation.

Required new coverage, in addition to all existing42/56/540/38/44 carrier counts:
8 admission owner probes,12 exact failure/decline cases,336 V1 admission-helper
comparisons and168 V1 standalone-public-WHNF comparisons. These include true/false
proposition decisions, nonsorts, malformed IDs, beta/zeta/iota, low fuel,
depth boundaries and mixed-context refusal. Eleven local ownership/ordering/fuel
lemmas supplement the previous10; no global soundness theorem is claimed.
Both generated routes require the new exact markers.

### Concurrent source observations, inspected 2026-10-21 12:56 UTC

| Source | Native integration | Native correctness | Portable source | Canonical runtime | .lean-generated runtime | Arena |
| --- | --- | --- | --- | --- | --- | --- |
| staged `ea84af3dea125b377ece3bd4fc4b8f95febe120e` | PASS119228846055 | PASS119228844582 | PASS .lean; canonical check IN PROGRESS | IN PROGRESS | IN PROGRESS | official PASS; generated IN PROGRESS |
| carrier parent `4dee3fe1dc6791aa491f101db876898e10449a01` | FAIL fixture elaboration | PASS119228991271 | research portable PASS; full job IN PROGRESS | IN PROGRESS | IN PROGRESS | official PASS; generated IN PROGRESS |

Staged native includes the corrected positive Box recursor at distinct universe
arguments[1,0],12 official valid and4 invalid recursor cases,3 official addDecl
fixtures, both retained Sort-u universe/elimination negatives, all prior guards
and proof gates. Exact parent carrier native proofs/matrices were NOT RUN because
its aggregate test target failed to elaborate. Generated jobs have not been
assumed successful.

Next critical path: inspect the changed source's native test compilation and all
independent gates; then both terminal generated routes and full Arena. Keep the
four explicit whole-operation fallbacks, K/major conversion and inductive/boundary
migration limitations visible. No acceptance or parity is inferred from host
timeouts or kernel exhaustion.

## 2026-10-21 — carrier dependency repair and preserved negative fixtures

Branch: `research/psc1-pskernel-v2-carrier-20261021`.
This source update follows parent `6cbeb1b3587335545d9d3a2bdd4b99c0c2244b4a`.
The full CheckState carrier remains isolated and **unqualified**. At commit
creation this changed source is **NOT RUN** for native, portable, canonical,
generated, proof, benchmark, Arena and provider gates.

Parent [integration39599736505](https://github.com/dwijayuda/pskernel/actions/runs/39599736505)
and [correctness39599736632](https://github.com/dwijayuda/pskernel/actions/runs/39599736632)
failed native compilation because the cycle-breaking refactor removed the
transitive import supplying `psKernelCheckNatSize`. `CheckCore.lean` now imports
`Checker.Reduction.PrimitiveData` explicitly; that leaf module only depends on
Context. The repair restores the existing checked numeric guard without changing
its implementation or introducing a second algorithm.

The commit also carries the three independently isolated staged841 repairs:
two terminal-false proof-irrelevance sentinels gain180 exact V1 comparisons and
two official negative fixtures; the positive recursor datatype uses
`Sort (succ u)`, with the original `Sort u` case retained as two exact
universe/elimination rejection controls; the guard proof's reserved
`exists` binder becomes `alreadyExists`. All existing matrices remain.
Both workflow routes require the new markers.

The full-state carrier requires42 state probes,56 exact propagated failure/decline
cases,540 differential cases,38 DefEq state probes and44 DefEq propagated cases,
plus10 local carrier lemmas. They have not yet passed on this repaired source.
Parent full .lean and canonical checks completed while generated compilation was
still running; those observations are source-specific, not runtime qualification.

Next critical path: complete native compilation and independent native gates on
this exact revision, fix any actual owner/budget/ABI defects, then inspect terminal
generated and canonical jobs. Four public whole-operation fallbacks remain.
K and general recursor-major conversion, inductive admission, public boundary
decode and complete Arena qualification are still open. No integration promotion,
fuel/depth increase or new trusted runtime path is included.

## 2026-10-21 — qualified integration889 and isolated migration blockers

The active integration branch remains at
`88924063a5d9761f52a130c6a581cac6901ad407`.
Its native, authentic portable-source, complete canonical .ps, generated
JavaScript and provider gates are terminal PASS. This establishes **Gate A for
the documented limited-scope V1 developer provider**, not complete V2 or full
Lean compatibility. V1 remains the default; full-kernel DirectJS is explicitly
UNSUPPORTED. Gate B remains incomplete and Gate C fails.

### Exact-source evidence matrix

| Exact source | Native integration | Portable .lean source | Canonical .ps qualification | Generated JS integration | Local proofs | Benchmark | Full Arena | Provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `88924063a5d9761f52a130c6a581cac6901ad407` | PASS | PASS | PASS | PASS | PASS | PASS, regressions remain | FAIL | PASS, native and both generated routes |
| `841a5f7a129dc9647789fc8080e635d4f1eea3ac` isolated staged | FAIL | PASS | IN PROGRESS | IN PROGRESS | FAIL | PASS, native | IN PROGRESS | PASS, native only |
| `6cbeb1b3587335545d9d3a2bdd4b99c0c2244b4a` isolated carrier | FAIL | PASS via canonical job's .lean check | IN PROGRESS | IN PROGRESS | NOT RUN | NOT RUN | IN PROGRESS | NOT RUN |

The in-progress cells describe the last actual inspection before this repair
commit. They do not inherit success from another revision; later terminal jobs
must be inspected at their own SHA. Native correctness at staged841 passed, but
its broader integration job failed. Carrier6cb native failed at compilation.

### Qualified integration receipts

- [Integration39595204321](https://github.com/dwijayuda/pskernel/actions/runs/39595204321):
  native119205679872 and generated119205679479, both terminal PASS.
- [Correctness39595204029](https://github.com/dwijayuda/pskernel/actions/runs/39595204029):
  native119205678982 and canonical119205679172, both terminal PASS.
- [Research39595203930](https://github.com/dwijayuda/pskernel/actions/runs/39595203930):
  all six jobs terminal PASS.

The authentic complete .lean closure and independently reconstructed/rechecked
canonical .ps closure both compile through PSC1 and TypeScript7.0.2. Generated
runtime checks execute in detached Node22 with empty PATH. Each generated route
passes24 provider protocol cases and8 direct API cases; native passes24 protocol
cases and the official reference checks5 fixtures with4 real batch declarations.
Native and generated main suites retain the mutual280/eight-official matrix,
fresh-member/budget sentinels, exact refusals and atomic publication controls.
Focused source889 gates cover infer-only1008, proof irrelevance1350, Nat1350 with
192 stage cases, lazy delta1800 with1024 stage/128 step cases, and FullShape342
stage/108 owner cases. Proof-file dependencies remain within the audited
propext/Classical.choice/Quot.sound set; no new trusted runtime path is added.

| Deliverable | Immutable artifact | ZIP SHA256 |
| --- | --- | --- |
| Native executable/provider package | [12343257329](https://github.com/dwijayuda/pskernel/actions/runs/39595204321/artifacts/12343257329) | `a4db9ab6bae642fb8ae217ba2be17e0781683d8c68ff29846ba993dd4b837151` |
| .lean-generated JS/provider | [12344847028](https://github.com/dwijayuda/pskernel/actions/runs/39595204321/artifacts/12344847028) | `cbf433ace671102ee86226243818dd79f35f21fc6addd2aef48219b1676520e0` |
| Canonical .ps closure and generated provider | [12345427809](https://github.com/dwijayuda/pskernel/actions/runs/39595204029/artifacts/12345427809) | `21fd178f87813bbc63ae01762f6e6e1867b398cd2ccd4065f515c6035ebd3c49` |

Per-file SHA256 receipts:
- native executable: `e11ae0d9ec43eb75f4302997e66decccafb0e785cc57e42daa07d73c1e208c3c`;
- .lean-generated JS: `d98ff997a6b483f9dc7e4c4a7301757bff78990b008740cbd90b70b506258814`;
- canonical-generated JS: `fad7b2683d78cf21e904f32ae65f3b4160f01408b9183dbd8889609e41ad03ca`;
- both generated TypeScript sources: `06432675edd28f6b7702be5eea746006cc0c0b8b6bac39d9edacccfdc3d01d44`;
- both declaration files: `e103d21b3581180d1636874d78677fef5c84c5a376fee8f21afb4f7d614e655c`;
- canonical source closure archive: `4511739cf74a1986943eb553f7dc58211a583e9927ccd9fcbc26a2c3de918611`.

Readable source, maps and runtime dependencies are included in the packages.
The manifests enumerate every file's hash. These are integrity receipts only;
they do not authorize kernel judgments. See PROVIDER.md for checked batch usage.

### Arena: complete accounting, distinct source revisions

Source889 [Arena39595203857](https://github.com/dwijayuda/pskernel/actions/runs/39595203857)
is terminal FAIL. Official119205678683 independently records122 accepted and71
rejected. Generated119206620264 records all193 unique zero-based case IDs:
170 matches =103 acceptance +59 kernel rejection +1 metadata rejection +7 transport
rejection;2 safety agreements;20 host timeouts;1 unsupported. There are no
classification changes from5544. Timeout IDs are23,72,78–87,90–96,98; unsupported
ID16 is bugs/rec-missing-ih.ndjson; contract IDs69/70 remain separate.
Generated artifact12345267214 SHA256
`5b23499767a15976c21848e7c24fb46091e22759076ca04271e57ba8891af485`;
official artifact12344061844 SHA256
`efb72274a71225ddca3513fd70591ad0845329ba9166ea79a4be1b0da91431b7`.

The isolated combined-slice source
`369bee5801bd5e4476837684fad3f7e1ca8c422c`,
[Arena39595801244](https://github.com/dwijayuda/pskernel/actions/runs/39595801244),
also fails full qualification but records two genuine additional acceptances:
ID79 perf/args-before-unfold and ID95 perf/repeated-subproblem. ID81 church-numerals
changes from host timeout to kernel reduction budget exhaustion (15.381s,
1,145,508KiB recorded peak RSS); it is still nonparity. Totals:
172 matches =105 acceptance +59 kernel rejection +1 metadata +7 transport;
2 contracts;17 host timeouts;1 kernel resource exhaustion;1 unsupported.
Remaining timeout IDs:23,72,78,80,82–87,90–94,96,98. Official119207666233
independently records122/71. These gains are not attributed to integration889
or to any one individual slice.
Generated artifact12346175319 SHA256
`67e31cfd6a155f24b437a28f83680800e1c64618d5c9133daf3344ccdb8bd8e8`;
official artifact12343308050 SHA256
`57e1c6cc1c24873f098cf390802bd226b0c448b50b2d30f4f84c453325882e7f`.

### Authentic first-decline evidence

[Diagnostic39596066101](https://github.com/dwijayuda/pskernel/actions/runs/39596066101),
job119208562177, is terminal PASS for collection only. Harness
`d4cff45683fd4ae77e6fb0ad96b6e4998cc6bd29` pins production
`5544bf8feffd8b6cb2aa9b9be7fe27002d8ea8a8`. Repeated-subproblem and church both
still time out; completed-outcome agreement is null, not success. All21/14
first-None records are printed without observation limits. Both theorem traces
first decline at DefEqResidualAfterFullWhnf with unchanged roots:47/156 in an
182-node arena for repeated;1790/1789 in a2031-node arena for church. This supports
the missing terminal residual boundary. It does not identify K/structure/String
major normalization. Artifact12345108676 SHA256
`5994ab03a42470b96b57372e0b9c253737c89b6abd65d4df92832180297ac7a4`.

### Performance and remaining gates

The new source889 section in PERFORMANCE_2026-10-21.md records every measured
workload, cold/warm latency, construction, native RSS and generated retained heap.
Selected gains coexist with material regressions: native collision depth8 is
8.170ms DAG versus4.033ms V1; generated binder32 admission is379.529ms DAG versus
215.493ms V1. The historical8.57–16.17x figures are not current whole-kernel claims.
The existing Arena memory option is V8 --max-old-space-size=2048, not an OS RSS cap.

Four public whole-operation fallback sites remain. Whole-arena boundary decode,
inductive admission/metadata construction, K and incomplete recursor-major
normalization remain migration work. Complete replacement, full Arena conformance,
a global soundness proof and a general performance guarantee are not claimed.

## 2026-10-21 12:27 UTC — isolated full-state carrier qualification branch

Branch: `research/psc1-pskernel-v2-carrier-20261021`.
This branch starts from current staged source
`841a5f7a129dc9647789fc8080e635d4f1eea3ac` and incorporates reviewed carrier
commit `136ee37d82d2896e278f3e2a8856b2dcb0b2d449`.
The strict mixed/binder/theorem selected-path repairs and independent native
failure-evidence conditions are retained. All four existing full workflows
include this branch; no gate, assertion, version pin or resource policy is skipped.

**Carrier native / authentic portable source / canonical .ps / generated runtime /
local proofs / performance / Arena / provider: NOT RUN at commit creation.**
The branch exists to obtain those exact-source results. Integration remains
`88924063a5d9761f52a130c6a581cac6901ad407`, whose native and .lean-generated
integration run39595204321 is terminal PASS. Carrier changes are not promoted
to the integration branch or default provider.

The complete carrier source/test history is retained through a second parent;
the corrected staged source is the first parent. New runtime logic is confined
to the reviewed operation-owned callback migration. The existing raw WhnfState
entry points remain thin ABI compatibility wrappers. Native official/adversarial
controls and full portable/canonical generated checks remain mandatory.

Next action: inspect this branch's full native and generated jobs, fix actual
source/proof/ABI/runtime failures, and compare the complete193 Arena records.
Only promote after the required exact-source gates finish. K, structure-major
and String-major recursor paths and four public whole-operation fallbacks remain
explicitly uncompleted at this checkpoint. No whole-V2 or full-Arena claim.

## 2026-10-21 — full CheckState carrier review assembled on current staged fixes

This commit assembles the reviewed callback-carrier refactor on staged source
`641ad59c3b1bbf701b0c28d4da92386096e5e65f`, retaining the guard staged-recursion
repair, native fixture keyword fixes, strict terminal DefEq fixtures, every
existing gate, and the canonical build-only 75-minute job ceiling. Its second
parent preserves the complete reviewed source/test history through
`43ac7506b5fe9442a3baa7b21e2cd733938caffe`. **This candidate is NOT RUN and is not
an integration promotion.** Do not inherit any previous source's CI result.

### Mechanism and supported scope

The primary WHNF, recursor, infer-only, checked inference and DefEq callback
paths now carry the complete seven-field CheckState through one callback knot.
The four-field WhnfState ABI remains as explicit compatibility wrappers. Pure
WHNF helpers lift their results into the current owning state; state returned
by a checker callback is used directly, preserving fresh counters, inference
caches, success/failure pairs and unfolding entries rather than merging into a
stale outer snapshot. No representation fields, acceptance shortcut or trusted
runtime primitive were added.

The recursor owner fixes each predecessor-budget callback exactly once while
retaining the DefEq callback supplied by its owning operation. Structural WHNF
recursion keeps those callbacks fixed. Typed local values come from the current
CheckContext. Existing mixed legacy-local, K, structure-major and String-major
unsupported paths retain explicit decline behavior. This refactor does not
promote those branches or remove the four public whole-operation fallback sites.
V1 remains the default checked provider and differential reference.

### Exact required qualification

The native/generated/canonical gates require all of:
- 42 full-state callback carrier probes and 56 exact error/decline propagation cases;
- 540 original-V1 WHNF comparisons over the established fuel/depth/public/core matrix;
- 38 DefEq carrier probes and 44 DefEq error/decline propagation cases;
- ten new local carrier/entry-guard lemmas, plus unchanged existing proof statements;
- all existing official, mutual280, guard, Quot, ordinary recursor, DefEq,
  transformation, provider, adversarial and performance gates.

The probes seed non-authorizing cache markers and verify every outer field,
fresh-counter and callback order. Unit/alias/Quot/recursor metadata comes from
actual checked declaration admission. These probe counts are not counts of
officially admitted theorems. The local lemmas establish boundary identities and
zero-fuel precedence, not whole-kernel equivalence or soundness. Native, authentic
PSC1, canonical closure, detached empty-PATH JavaScript and full Arena results
remain required at this candidate's exact committed SHA.

### Continuation

Inspect the staged641 and integration889 terminal jobs before promotion. Diagnose
any concrete carrier source/ABI/proof/runtime failure without weakening assertions.
Keep native and both generated routes source-identical. Full Arena qualification
remains open: the last complete5544 record had193 cases =170 matches,2 separate
safety agreements,20 host timeouts and1 unsupported case; no completion claim.

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


## 2026-10-21 — Safe residual recursor occurrence validation candidate

The unchanged frozen Arena case16 `bugs/rec-missing-ih.ndjson` (round tag5d7ca987618f1136aaa296057b50a2c10c4ce77a, blob522a6beef1ea4ad8b2995fd140d62b2930f7a38a) has22 singleton numNested0 groups. The Owner.step child contains Owner beneath a stuck checked Gate.rec head. Its existing ordinary route is correct; the old generic nested-unsupported message did not establish the semantic cause. Pinned Lean inductive.cpp435–450 rejects this safe residual after WHNF;485–486 skips positivity for unsafe inductives.

Add a narrow safe-only guard after the unchanged full-WHNF/direct-recursive/Pi sequence, requiring target in the reduced result and live recInfo head in the returned session. Register a new precise rejectedInvalid diagnostic; retain all generic unsupported outcomes, including unsafe, genuine nested heads and erased original-only occurrences. No importer/harness/limit change. Standalone regressions use actual checked Bool/Gate metadata, official env.addDeclCore doCheck=true, reducible/nonrecursive/erased/unsafe/nested/resource/no-publication controls; both generated routes run detached. CI also restores exact3aa Constructor/Outcome files beneath unchanged new tests and requires the official oracle marker followed by the intended rejection-assertion failure, then restores/rebuilds the candidate.

Implementation and qualification are separate. At this entry,464065d2e7823b4f62ac9888a2f8f98051031085 native integration119339896857 and native correctness119339896783 passed; generated/canonical/research/fullArena were still active. The last fully qualified A remains3aa pending completed successor gates. The containing safe-occurrence source must obtain fresh source-bound gates and unchanged authentic case16 replay before resolution is claimed. Current code review included the unsafe exclusion; no local builds/tests were run.

Church stage diagnostic d373 failed compilation (reserved prefix); host-only rename b71a4b1aed8d5a4113c635593fa70607d34a0159/run39636878473 is queued at this entry. Production there remains369bee; no first-failing-stage receipt yet. Next main source task after current qualification is T03a authoritative checked environment-prefix ownership; pair timing remains inconclusive and T01F stays open.


## 2026-10-21 — Final Ultra-to-regular-Pro handoff (2026-10-21T16:50:08.474Z)

Implementation HEAD at observation:034999734f2574876a747c967dd03bcc6904b395 (tree63a64b904ab6cfb96813d016b7944c3fa3fa93d4). This final handoff changes only documentation and the source-bound status receipt; no executable/test/workflow changes. Avoid duplicate full pipelines for documentation. Do not describe a documentation HEAD as newly source-qualified.

Four implemented corrections: owned String-projection slice; equivalent explicit-argument DefEq pair scan; V1/V2 cheapRec cache-publication isolation; safe-only residual recursor-headed positivity rejection. The last is not yet dynamically qualified; the first three passed complete native integration at464065d2e7823b4f62ac9888a2f8f98051031085/job119339896857, including parent failure reproduction, official comparisons, state/fuel controls and proof audits. Native correctness119339896783 also passed464. Its generated integration119339896329, canonical119339895721 and generated research119339897914 were still active; five other research jobs had passed. No all-backend promotion follows from those partial receipts.

Candidate034 runs already exist: integration39637759611 (generated119352848385/native119352848567 queued); correctness39637759709 (native119352848485/canonical119352849214 queued); research39637759603 (six jobs queued); fullArena39637759569 (official119352847788 PASS/generated119354877930 queued); authentic profile39637759606/job119352848125 started. Fetch live terminal state before acting; do not launch duplicates. Detailed observed job states are evidence/2026-10-21-final-handoff.json. Latest fully qualified scoped A remains3aa077cb64ff06f76727decd01c43ad6c33f351d, with its terminal integration/correctness/research receipts preserved above and in the audit. B/C/D remain open; authentic3aa full193 remains172matches/2safety agreements/17timeouts/1resource/1unsupported. Do not erase that historical failure or count diagnostic success as kernel qualification.

Separate Church diagnostic branch sourcef2e6c44a506a53dc294ae6569f8371e81ed6bdd5/run39638208348 is queued. It pins historical kernel369bee. d373 compilation failed on reserved prefix; b71 compiled and reproduced original resource exhaustion, then launcher argument allowlists refused stage modes. Both host-only issues are repaired; no first-failing-stage attribution has yet been observed. Inspect the new artifact rather than infer a stage.

Next regular Pro task: finish existing034 qualification, fix only evidenced failures, require unchanged case16 actual rejectedInvalid with official rejection and safe/unsafe/erased/nested controls. Scoped A gates and remaining C failures are distinct. Then implement T03a exactly as the plan's authoritative new-environment-prefix recipe specifies; no broad re-audit. T01F full actual String environment stays open. Pair timing remains inconclusive; no overall speedup/global soundness claim. The four final docs under docs/ are authoritative, including ready-to-copy AI_CONTINUATION_PROMPT.md. Preserve4096, resources, negative tests, history, defaultV1 and independent checker boundaries. No local builds, main merge or npm publication were performed.

