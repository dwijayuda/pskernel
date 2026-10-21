# PSC1 current execution checkpoint

Updated 2026-10-21. Active draft PR172, same non-force branch/history. GitHub
APIs and Linux Actions only. Optimization implementation219ad102a0c0b846a941f64e97ea071570a6e32c:
static/native/focused (now JS/TS/Rust)/all3 closures/G1/host SUCCESS.
Full39567037483/job119111960106 and aggregate gate119117837166 SUCCESS.
Tested mergef7fa6aaec0c9772f410bc458e6677e8b7b0a8e55; exact optimization
receipt in docs/PSC1_DEVELOPMENT_OPTIMIZATION_QUALIFICATION_2026-10-21.json.
Full scoped853s;8 selected heavy jobs total2074s. Readiness11 qualified finite
criteria/26 blocked; no complete family. Documentation-only scheduling still
needs an actual run to corroborate the tested zero-heavy selection.
The first router run correctly skips the unrelated specialization benchmark.

Actual next implementation, pending full CI:
Implementation4bdada4d6a3a1d257ac95d97e8046e8141c9a72d, run39572888092:
native and every compiler closure plus G1/host SUCCESS. Constructive witness
extension is source-normalized in both lanes and preserves all boundaries.
Early suites54 CompilerM/18 collections pass; Lean JSON core passes JS/TS/Rust.
Authored PS JsonValue.string pattern must use the same space-separated
constructor syntax as Result/Option/List; fix the remaining pattern here.

08c5 run39571719689 proves the constructor mechanism works in native admitted
ordinary tests and the actual Lean JSON application on JS/TS/Rust. Existing
128-budget and uninhabited/forged-source refusals pass. Full remains pending:
normalize method-style List.length into explicit applications in compiler
source (reached source census unsupportedTerm), and use PSC1 PS match-with /
space-separated constructor patterns in the authored PS application.

CI dependency selection now carries failed/cancelled update debt from the last
successful same-PR/same-base ancestor gate. The event.before interval alone
could omit a changed policy/target whose previous run was cancelled; regression
tests cover failed/cancelled/nonancestor/different-base histories. API/baseline
failure selects full qualification. The Actions token is read-only.

Run39569709984 reaches the real generic witness blocker after CLI correction:
PSC1_PARTIAL_NO_CHECKED_INHABITANT orderingStringFrom. Extend the existing
128-attempt/depth constructive witness search with declaration-driven
nonindexed constructors. Type parameters are fixed from the target; field
inhabitants and failed alternatives share the same remaining budget. Every
candidate is type-checked and independently admitted; no recursive body is
consulted. Retain uninhabited/recursive-only refusal and old budget tests.
New native tests cover enum, generic product field, failed-first alternative,
and recursive-only result. Both-grammar JSON application is the reached case.
Manual reusable jobs queue rather than cancel one another. Build object cache
keys distinguish job target sets, preventing a small closure cache from winning
and permanently omitting the compiler/test objects needed by other jobs.

Run39569086352: static/native/all3 closures pass; focused54 CompilerM +18
collection obligations and six independent native standard comparisons pass.
JSON was blocked before parsing by a runner option error: internal profile
ordinary-checked was sent to the CLI. Correct to public --assurance ordinary.
The full tier correctly did not start after this early failure.

- Collections compare six observations with a separate pinned native Lean
  standard List/Array/Except process. Missing reference identity refuses parity.
- JSON escapes now combine valid UTF-16 surrogate pairs. Existing jsonReadUnicode4
  remains the strict single-scalar API; isolated/malformed surrogates still
  produce invalidUnicode. The string parser uses the new pair-aware decoder.
- Both authored grammars compile a real three-module pure JSON-record processor:
  input records, transform/fold and entry observations. Seven finite cases cover
  emoji, minimum/maximum pairs, BMP neighbors, literal Unicode, mixed hex case,
  isolated/repeated/truncated surrogates, and preservation of scalar-only decoding.
  Valid outputs use the pinned native Lean JSON parser as reference. Negative
  surrogate expectations retain PSC1's stricter policy rather than Lean's
  replacement-character behavior.
- Shared conformance runner adds JSON core observations, exact module/library
  hashes, type/refusal/publication checks; JS/TS/Rust early (full tier waits for native/focused success), all7 and minimum
  Python for qualification. Expected new obligations:98 JSON core,42 collection,
 126 CompilerM; minimum14+6+18. These are expectations, not passed CI claims.
- Typed console/file IO and complete practical applications remain blocked.
  A pure record-processing core does not complete the JSON/file application.

The finite contract remains fourteen families/37 criteria/four applications;
no scope expansion or completed-family claim. Manual psc1-practical-release
calls all existing native/closure/G1/scoped qualification and enforces
--require-ready. It must fail until all finite criteria and actual applications
have real qualification evidence. No merge/publication is performed.

The readiness artifact also derives queue statuses from the same exact-commit
suite evidence; none is manually promoted to qualified.

After CI, continue the dependency-ordered contract queue with bounded
inference/control cases and the typed IO/application gaps. G2/G3 remain deferred;
official Lean4.35 admission, strict IR, security/resource policies and every
previous regression remain required.

## Preserved optimization checkpoint


Updated 2026-10-21 by the explicit throughput optimization request. Remote HEAD
inspected before these changes:30c2cd9e857e043bb4f5c34ab0d19d0af8b62762.
Active draft PR172 on fix/psc1-closure-normalization-20261021. Base #171 and
all prior commits remain preserved; GitHub APIs and Linux Actions only.

The single active roadmap is docs/PSC1_DEVELOPMENT_ROADMAP.md. Its authoritative
machine-readable scope/remaining-work queue is
docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json: fourteen families,37 finite criteria,
four real applications, all seven targets and both authored grammars. No
existing functionality is removed. Generated readiness separates registered
implementation, tested subset, exact-commit full qualification and blocked
unbound cases. All full families/release remain incomplete; no readiness
percentage substitutes for acceptance.

CI now routes incremental commit dependencies through psc1-development.yml.
All original native/focused/closure/G1/full scoped assertions remain in reusable
manual workflows. Static-only documentation updates replace nine repeated heavy
jobs with none; focused authored CompilerM/collection changes select2 heavy jobs;
compiler-source changes select7; target/CI/authority changes select8, plus the
immutable benchmark only when selected. This is a deterministic scheduling
measurement, not a claimed elapsed-time speedup. Capture actual run durations
before claiming measured wall-clock improvement. Toolchain/exact-source Lake
caches never reuse admission or execution receipts. JS/TS/Rust are early targets.
Full exact-candidate qualification remains required before merge/release.
No merge, publication or branch-protection update is authorized here.

Latest pre-optimization30c: focused39564583962, native39564584113, all closures
39564584036, G1/host39564584032 SUCCESS. Full scoped39564584025 SUCCESS, including126 CompilerM +42 collection obligations
and minimum-Python18+6, all existing regressions and installed package checks.
Earlier fully qualified dd2328a5 receipts remain below. Do not infer qualification
of this optimization from earlier code.

Immediate actual development: close the collection-oracle independence gap.
The exact helper/native oracle can agree with the same library defect (the old
listLength returned0). Compare List length/append/reverse, persistent Array
updates/optional lookup and typed Except with native Lean standard operations;
then execute both authored grammars and all seven targets. Next take the finite
JSON application/Unicode blocker, without another architectural redesign.

Practical Core/compiler/backend and PSKernel-Core Expression V2 are independent
workstreams. Official Lean4.35.0 admission, strict IR, pairing, negative/security/
resource policies stay required. Preserve G1 and all prior source/artifact/CI
evidence. G2/G3 remain deferred until feature freeze; the tracked heap-exhaustion/
timeout defect remains open. No self-host milestone is the development priority.

## Preserved prior checkpoint and evidence


Updated 2026-10-21. Active draft [PR172](https://github.com/dwijayuda/pskernel/pull/172)
on fix/psc1-closure-normalization-20261021. Inspected remote HEAD before pivot:
1d5c45e01f9016365a440c8b8c05916249cfaa4c. Base #171 remains immutable at
1fad9ed53cda9b23ac30be9cea85e7857437564e. All commits/history preserved.
Use GitHub tools and Linux CI only.

## Active priority pivot (explicit user instruction)

The [development roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) supersedes the
self-host-first order in the older Sol High prompt. Continue actual Practical
Core, both authored grammars, seven backend mappings, architecture, practical
application compilation and runtime work. Do not stop at planning changes.
G2/G3/fixed-point qualification is deferred until a stable feature freeze.

Normal generated-compiler CI retains the full existing8-case G1 functionality
corpus, one native seed, complete-source admission/IR and host authority/refusal
checks. Full G1->G2->G3 uses the same controller with --self-host in the separate
manual psc1-selfhost-qualification workflow. No generation assertion is removed.
Expensive G2 CPU and fixed compiler profile workflows are also manual. Existing
scoped/native/closure/target/package gates remain unchanged. G1 artifacts use90-day
retention; exact historical source and qualification receipts remain preserved.

Latest pre-pivot HEAD1d5: scoped39552904242 SUCCESS; all3 whole-closure jobs
39552904236 SUCCESS; native39552904280 SUCCESS; fixed-input native comparison
39552904261 SUCCESS. Actual39552904167 passes all8 G1 cases, then G2 timeout
240177ms before publication. No G3/fixed point. Latest exact CPU replay
39552904187 is diagnostic success, G2 execution ETIMEDOUT240278ms.
[Tracked open performance defect](docs/PSC1_G2_PERFORMANCE_DEFECT_2026-10-21.md)
retains the original proven heap exhaustion, fusion correction and later timeout.

Next development: continue remaining Practical Core decisions after the qualified
CompilerM case contract below; prioritize genuine admitted Nat/Int Prop order
and shared condition/decision architecture, bounded inference/pattern cases,
practical IO capabilities and remaining backend/runtime obligations. Preserve complete compiler sources, checker pins,
strict IR, exact ordinary pairing and all prior regression/refusal tests.
Pivot G1 workflow39554231389 SUCCESS at implementationd5a1d66d9f0a1e6934656d330e5ad18db19cd409,
tested merged331ff43895c656e1dfb1ef31cd3bc60f841e308. Both generated and
host-session jobs pass. Same qualified G1 service bytes; all8 cases; no G2 attempt.
Artifacts12325240640/12324594397 now expire2027-01-19 (90days).
[Pivot receipt](docs/PSC1_PRIORITY_PIVOT_QUALIFICATION_2026-10-21.json).
Full scoped result is separate; the pre-next-commit run was cancelled by normal
concurrency, so do not claim its completion. New Practical Core tests are pending.

## Current fully qualified checkpoint — collections and G1 v2

Implementationdd2328a53e5e9a5384e474410f5123810330130c, tested merge
86f2c1aea281ba7303a5158a19df85b58c375d58. Full scoped39561579871/job119094250765
SUCCESS, all existing checks, minimum Python and installed packages included.
Normal cases:98 CompilerM +42 collection obligations, both authored grammars/
all7 targets; minimum Python14+6. Each obligation executes both Bool inputs.
All source/admission/strict-IR, type/refusal and publication-preservation checks
pass. [Exact collection/G1 receipt](docs/PSC1_COLLECTIONS_QUALIFICATION_2026-10-21.json).

Native39561580327, all3 whole closures39561579858 and focused39561580080 pass.
G1 workflow39561580142 passes all10 cases under pinned v2 manifest policy.
Service652ce79f0fcf5ba0c7f4e23f24a96cec1f36a65b5dd339adb93592a4d45cfd08,
artifact12328012635 to2027-01-19. Old5d30 G1/receipts remain preserved.
No G2/G3/fixed point attempt. All fourteen full families remain incomplete.

## Active next implementation — CompilerM source handlers, pending CI

Add2 authored CompilerM try/catch cases: lexical mutable rollback combined with
effect-state rollback and continuation; early return bypasses the handler and
preserves successful effect state. The native-only MonadExceptOf adapter invokes
the exact checked compilerThrow/compilerTryCatch library definitions. Retain all
earlier cases and collection suite. New matrix126 CompilerM +42 collections,
minimum18+6; no inference of success from the preceding7-case checkpoint.

Add cheap constructed-data v1/v2 generation manifest tests: exact8/10 cases,
missing/duplicate/unknown cases, stale/downgraded schema and unknown/empty/null
host policies must refuse; historical no-policy caller retains exactv1 behavior.
These objects grant no admission/publication authority. Normal G1 and manual
qualification both run the regressions. Preserve all actual host boundary tests.

## Earlier qualified CompilerM checkpoint



Implementation8ac752a7f3acfe696ee3e8cb1fe67398de040704, tested merge
574d481a3c0f0f1259d73f929a04d9dc2217fad0. Full scoped39557245201 SUCCESS
(all existing checks, minimum Python and installed packages).7 authored
CompilerM cases ×2 grammars ×7 targets =98 obligations, plus14 on minimum
Python3.14.8. Each executes both inputs; independent native observations,
admission/strict IR, all4 new refusals and prior-publication preservation pass.
The multi-export component is externally validated/WIT-compared and every
selected wrapper actually invoked. Rust Cargo executes returned captured
callbacks through product/Array/Option values with old captures intact.
[Exact receipt](docs/PSC1_COMPILERM_QUALIFICATION_2026-10-21.json).

Focused39557245308, native39557245196 and all3 complete closure jobs
39557245275 SUCCESS. G1 run39557245225 passes all8 cases with the same
5d30b555... service bytes; no G2 attempt. Artifact12326192682 retains exact
G1 to2027-01-19. Broad families/public aggregate ABI/preservation remain open.

Consolidator now requires exact-head normal/minimum CompilerM receipts and
their complete contract matrix before issuing its scoped receipt; this
additional bookkeeping is pending its next Linux run. Expensive profiles stay
manual; the G2 diagnostic now references the fresh90-day preserved G1 artifact.

## Earlier Practical Core implementation — pending at that time

Add six independently authored Lean/PS CompilerM programs: reader/state/modify
with old captures; finite-loop early return; typed failure skips continuation;
checked recovery restores original state; local reader scope; Unit/nested
product patterns. The native oracle evaluates the exact Result/Effect library
bodies with a native Monad syntax adapter; no backend provides expected values.
Only scalar Bool observation wrappers cross target public ABIs.

Add a finite versioned6×2×7 contract and receipt validator refusing missing,
duplicate, unknown, failed/skipped, missing-identity and absent-refusal rows.
Actual generated consumers observe each case with both Bool inputs. Keep
wrong-state/wrong-error/verified rejection and prior-publication preservation.
Run on all7 targets plus minimum Python through the existing scoped workflow.
This is new coverage/possible backend defect exposure, not a complete CompilerM
family claim. Await actual Linux results and correct reached failures.

## Reached stdlib import defect — corrected, Linux pending

Focused run39555457605 at a69039e2 fails all4 authored JS/Rust lanes at actual
project import: ProofScript.Data.Prod declares Prod already owned by Essential
Core. ProofScript.Data.Option likewise redeclares checked Option. Their helper
functions now extend the existing prelude identities; remove only the duplicate
type declarations in these authored library files, without changing compiler
duplicate checking or filtering any input. All helpers/imports remain.

Add an explicit duplicate-prelude Nat declaration refusal to every new matrix
lane, requiring duplicateDeclaration:Nat and preserving previous publication.
The checked native CompilerM reference and parity-contract rejection tests pass
in that run; target programs have not passed yet. Continue actual reached failures.

## Explicit multi-export Bool components — pending Linux qualification

The owned component schema/encoder already supports multiple concrete Bool
exports, but the host CLI only exposed one. Add --exports comma-separated names
to select an exact finite entry-owned set. Keep --export and no-selection
refusals. Host rejects empty/duplicate/non-entry selections before publication;
the existing strict input/core/signature/WIT checks and external validators
remain. Retain exact selected provenance and atomically publish the whole set.
CompilerM observation wrappers use lowercase WIT-compatible names and each is
invoked independently on components too; malformed selection attempts preserve
the previously published bundle. No aggregate ABI or host capability claim.

## Reached Rust callback storage — implementation pending CI

After the stdlib correction, run39555781169 accepts/admitted/executes both authored
JS grammars and all new refusals. Rust refuses phase=rust-lowering
location=function-storage reason=function-storage:run for actual CompilerM.
Implement recursive owned V(T): function types become Rc<dyn Fn(V(A)...) -> V(B)
+ 'static> through named generic arguments and arrays. Keep the existing outer
Rc field storage. Use the same owned global adapter for stored function values
as for arguments/locals. Traverse every stored callback body; strict whole IR
still checks field/type consistency before emission. Public ABI restrictions
remain separate. No unsafe/RefCell/cycles or enlarged limits are introduced.

Actual Rust and all-seven behavior are not yet qualified. Continue native,
closure-source acceptance, emitted Cargo and existing refusal/source tests.

## Owned callback runtime result and expanded data interactions

At93b590d8, focused39556431129/job119077157185 passes all24 original
six-case × both authored grammar × JS/Rust obligations, including native
observations, Cargo execution and all four refusal/publication checks per lane.
The3 whole-source closures are being checked separately. Native architecture
correctly flagged an old assertion expecting named closure storage to refuse.
Replace that obsolete feature-boundary assertion with positive owned storage
plus nested-unknown refusal; retain zero-depth/unknown/public/source checks.
The lifetime spelling is now explicitly + 'static.

Extend the actual corpus with a returned CompilerM callback retained through
generic product fields, Array and Option, valid/OOB optional lookup and old
captured state. It has independent authored inputs/native reference and all7
target obligations (7×2×7=98); qualification pending. Do not treat a type-printer
assertion as runtime evidence.

## Returned callback fixture syntax correction

Focused39556895516 refuses the new callback fixture's projection directly on
a parenthesized application in both grammars. That postfix form is outside the
current selected syntax. Bind the exact same computation to a typed immutable
program local and project program.run, as the existing CompilerM contract does.
The returned callback/Array/Option interactions and both observations remain.
General expression postfix field access remains an explicit syntax gap, not
silently claimed as supported by this correction.

## Active collection correctness and prelude composition — pending Linux

The pinned ordering audit confirms the current owned prelude represents
Decidable/Bool.decEq as opaque primitives. A complete ordering addition needs
constructive decision/conditional architecture; do not add unchecked axioms
or rebrand Bool comparisons as Prop. Pinned Lean4.35 Nat/Int definitions were
inspected; ordering remains unimplemented.

Actual stdlib inspection found List redundantly redeclares the prelude identity
and listLength drops every head without incrementing, returning0 for all lists.
Except also redeclares the prelude type. Correct their authored files to extend
the checked canonical types. Implement accumulator length/reverse helpers with
guarded returned-state lambdas, preserving the existing helper APIs.
arrayGetOption used whole-array map before lookup; use the already selected,
checked optional indexing syntax directly, retaining empty/huge-index behavior
without an element fallback.

Add3 authored both-grammar collection/Except cases (42 normal obligations and
6 minimum-Python obligations) through the same contract/target consumer engine.
Native reference evaluates exact List/Array/Option/Prod/Result/Effect helper
bodies over native types; each library hash is retained. Reject wrong element/
index types, duplicate prelude and verified requests; type cases must reach
elaboration refusal, and all failures preserve previous publication.
Keep the qualified7-case CompilerM suite too. All new changes are CI pending;
do not infer qualification from the earlier98-obligation checkpoint.

## Reached authored list-literal grammar gap — pending Linux

Focused39559431079 preserves all28 CompilerM JS/Rust obligations with the
expanded exact native libraries. The collection suite exposes that ordinary PS
list expressions were never wired into its primary parser (6:41 at '[').
Implement shared List literal parsing beside tuple/array parsing in ParseData,
using checked root List.nil/cons constructors, the existing delimited element
parser and unchanged input-derived fuel. Both Lean and PS entry points use it.
Keep the older Lean fuel helper available; no declarations are filtered.
Add canonical Core identity, empty/nested/trailing-comma translation tests and
malformed/type/array distinction refusals. Existing indexing adjacency remains.

The Lean collection fixture's unparenthesized nested do consumed its separator.
Use the existing explicitly grouped do form followed by the let semicolon;
this retains the same typed error behavior. Rerun actual source/application
and all existing tests; collection qualification remains pending.

## Collection fast qualification and G1 language regression

Atff2de157, focused39560097064/job119089006547 passes all28 CompilerM
and12 collection case/grammar/JS-Rust obligations, with exact native library
observations and required elaboration/assurance/publication refusals.
Native architecture39560096917 SUCCESS, including the new list canonical Core,
nested translation and malformed/type-boundary tests. All-seven/minimum/scoped
qualification is still pending.

The shared parser changed the portable compiler source. Preserve the old
qualified G1 artifacts/receipts and qualify the newly generated G1 honestly.
Append a real generated-compiler PS list positive case and malformed-list
parse refusal to the existing8-case corpus (now10 cases); no old case is removed.
The manual full-generation workflow inherits these assertions but stays deferred.

## Actual G1 list execution passed; corpus schema correction pending CI

Run39560655991/job119090833062 actually passes all5 generated positive cases,
including the new PS list expression, and all5 refusals. It then correctly
refuses generation metadata because the v1 reader still requires the old8 IDs
(PSC1_GENERATION_CORPUS_CHANGED). Preserve that gate: add explicit v2 with all10
required IDs, and pin v2 in the trusted host controller. Keep v1's exact8-case
reader behavior for historical G1 data; it is not current qualification.
No case is optional and no manifest can choose its schema against host policy.
New G1 service652ce79f0fcf5ba0c7f4e23f24a96cec1f36a65b5dd339adb93592a4d45cfd08
is observed only at this failed-metadata checkpoint, not yet fully qualified.
Native/whole-source checks pass; retain full scoped results separately.

## Historical evidence and implementation record

The entries below retain their original chronology and pending-at-the-time
language. Their old instructions to prioritize G2/G3 are superseded above.

## Earlier fusion source/harness corrections

Atd70c910b Native Lean compiled the new pass and tests. Both source grammars
refused WorkerFusion.sink164:1 with unknownName:sink because its recursive fuel
match sat inside an outer empty-arguments conditional. Put the fuel match at the
top and retain the same zero/empty behavior in its branches.

The raw fixture was correctly refused before fusion for external-import-abi-
unqualified. Remove that unsupported import; observe operand order/count through
private language-function parameters and an explicitly authored scalar JS harness.
Retain an assertion that imported raw wrappers refuse, and report exact checker
findings on any invalid fixture. No import/public ABI or checker rule changes.

The profiler now includes the actual shared closed plan. Compare identical graph/
original/pre-fusion inputs; actual closed IR and source are expected to change
under fusion and are validated separately. The prior quoting-only byte identity
receipt remains valid for its immutable pre-fusion checkpoint.

## Typed worker application fusion, Linux pending

The exact retained IR confirms psJsonStringCharsAccWithFuel has1 declaration
parameter and3 returned unary lambdas. Its saturated recursive alias application
was printed as nested generator invokes, retaining one chain per input byte.
[Typed worker design](docs/PSC1_TYPED_WORKER_FUSION.md).

Add the general CompilerIr.WorkerFusion pass to the shared closed backend plan.
It retains original declarations/partial uses, adds private full-arity companions
only for total guarded lambda-producing prefixes, preserves lexical scopes via
typed beta lets and exact-once alias captures, rewrites saturated applications,
and strictly rechecks the complete transformed module. Unsafe/unrecognized
prefixes stay untouched. No arbitrary recursor IH is globally delayed.
Normalize all11 structural returned-state helpers in Bridge.Json consistently;
their partial smaller worker is evaluated inside the state lambda.

New Linux tests compare baseline/fused early/full work, closures, shadowing,
strict operand order and divergence; forged typed wrappers still refuse.
The new module is an explicit Lake/import root with maintained parse/elab gates
in both grammars. Expected backend closures gain1 module; qualify actual counts.
All this code is PENDING native/source/target/G1/G2/G3 CI. Do not infer success.
Compiler limits and default Node heap/stack remain unchanged.

## Earlier measured G2 process abort

At3b189f589b0a4ad06eb1bcc666014220e72268df, actual G1 again passed all8 corpus
cases with recorded scalar observations. Real G2 self-compilation was then
attempted on identical captured compiler sources. The generated Node process
aborted withSIGABRT after131880ms, before any candidate/publication. No G3.
[Exact attempt](docs/PSC1_G2_FIRST_ATTEMPT_2026-10-21.json), run39545154962,
job119041551702. Request SHA256:
1353995b84b1e33f3c0942a758e94a41c68dcb8f8b5fbc74d8f19fc6db73b331.
Exact replay39546176974 now CONFIRMS a JavaScript heap exhaustion at125656ms.
[CPU/failure receipt](docs/PSC1_G2_CPU_FAILURE_2026-10-21.json).
89848 sampled ticks: WeakCollectionSet26.1%, WeakMapLookupHashIndex10.1%;
hot JS locations are the nested lambdas of psJsonStringCharsAccWithFuel at
G1.mjs626. UTF-8 helper itself accounts for0.1%; do not guess a cache patch.
The emitted scanner allocates wrapped worker closures while traversing input.
Inspect its EXACT retained original/specialized IR and emitted function next;
a read-only hash-checked inspector job is added to the profile workflow.
Then fix the general narrow worker/application mechanism and verify unchanged
strict evaluation/capture/escaping behavior. Existing Js tail aliases require
saturated declaration arity; a returned function worker does not satisfy that
condition merely because its recursive state call is in source tail position.
Do not globally delay arbitrary recursor hypotheses or alter memory limits.

The original host session recorded status/signal/time but discarded stderr.
Its rejected .stage directory was hidden from default artifact upload. Correct
the host diagnostic mechanism: retain stdout/stderr on process failure and move
rejected stages to non-hidden failed generations; retain failure state/events
without granting publication. Print a bounded stderr tail in Linux logs.
Publication failures preserve the prior pointer, including injected failures.

A separate Linux CPU-sampling replay downloads the exact qualified G1 artifact,
checks its known service hash and the exact failed G2 request hash, and executes
only that G1 through the fixed runner with Node --prof. No native compiler/checker
is installed/called and no response is adopted. Existing240s cap/default heap/
stack remain. A green profile collector is diagnostic only, never G2 qualification.
Use actual stderr and sampled hot code to correct the reached compiler mechanism,
then repeat real G1/G2/G3. Continue continuously.

## Latest actual G1 execution

Qualified implementation921eb1d7b8a5dc539d192ccda5a4ceb14c21ac52.
Tested mergeece4925682d426509868564f663c26c482f91a2a.
Generated workflow39543944316 is completed/success, including host boundary.
[Durable G1 receipt](docs/PSC1_G1_EXECUTION_QUALIFICATION_2026-10-21.json).
Actual G1 service SHA256:
7a1efe8d3e03e5c507d00e034651b81fa7d4062c5a459e9a356c9753aaaa531d.
Full compiler source closure83 modules, canonical admissions
1bbdfa80eb942ce1930b0889f77ff9c2bbe4115c6b22cdd83ce36bd7ab6e2d76;
original IR1b92f8a5a779211d187a3e70273d5e7337a8c096a650bc885d97124d3a5ce888;
specialized IRfd46ee97e13e06002abf33719e97c521036408333bcb3be87f5ed308669bb969.

Native stage0 generated G1 once. Its exact graph was independently admitted.
Native compiler binaries were then disabled; the explicit independent checker
remained. Actual G1 compiled/admitted/published/executed:
- Lean multi-module/internal ownership1546ms/564428KiB;
- PS exact huge integer/Unicode1055ms/391292KiB;
- Lean typed handler/pattern3593ms/387964KiB;
- Lean explicit Id ordinary while4732ms/409288KiB.
G1 refused wrong bodies, missing imports, checked-only partial and verified requests.
These are selected cases, not complete language families or preservation.

Focused39543944344 and all3 exact closure jobs39543944319 passed. Both grammar
lanes accept EVERY selected module: semantic68, DirectJS83, Rust86. Exact logical
counts2439,3254,3033; checked semantic and ordinary-checked backend graphs.
Owned PS compiler input is canonical translation from Lean, not independent PS
compiler authorship. Original graph/IR bytes match both lanes in each phase.
Full scoped39543944381 is now completed/success. [Full G1 qualification](docs/PSC1_G1_FULL_QUALIFICATION_2026-10-21.json) retains the complete scoped result and artifact identities.
The earlier fully scoped checkpointadcb8157 passed39541282484, focused39541282570
and closures39541282485; [complete earlier receipt](docs/PSC1_SCHEDULER_FULL_QUALIFICATION_2026-10-21.json).

## Current candidate — actual repeated JS generations

The new controller now attempts G1->G2->G3 over the IDENTICAL captured83-module
compiler+JS closure. No native frontend/eraser/emitter is available after G1.
The same official checker and target Node remain. Before successor publication,
canonical admissions, original/specialized IR and generated source must equal
G1. Each generation then executes the same corpus and actual observations.

Versioned psc1-js-generation/4.35.0-v1 manifests retain exact source-file inventory,
producer/service/seed/Node/checker/runner/host-controller identities and corpus
observations. Closed bundle verification rejects missing/extra/changed files,
stale graph/tool/manifest context and historical schemas; tests preserve originals.
Readers return DATA, not publication authority. The private live host session
still owns real execution/admission/target checks and the atomic pointer commit.
G2/G3 and fixed point are PENDING actual CI. On failure retain the process event,
stage files and last completed generation, then fix the reached mechanism.
Do not raise240s process,16384 specialization or existing stack/heap/checker caps.

## Mechanisms corrected and measured

ParseDo124:67 and every subsequent complete selected source blocker are normalized,
with original decisions/refusals/budgets retained and maintained both-lane gates.
Private compiler helpers retain explicit Ps.Internal owners, shared public-root
filtering and full internal source/admission/runtime graphs. Native deriving
instances live outside the portable closure. Canonical IR encoding retains all
data and exact decimal integer strings; it supplies identity, never authority.

Specialization formerly charged29185 repeated seed references against16384.
Stable canonical-key scheduling reduces these to653 initial unique requests;
752 final instances/2230 declarations complete without omitting source entries.
Hash trie buckets always check full strings. The same-input synthetic fixture
retains all128 concrete entries plus1 instance; baseline refuses, candidate finishes.
[Queue receipt](docs/PSC1_SPECIALIZATION_QUEUE_COMPARISON_2026-10-21.json).

Actual G0 then hit240s while quoting its19MB admission graph. Balanced immutable
UTF-8 span quoting preserves exact bytes. Fixed immutableadcb workload comparison
39543395472 completed/success: baseline times out in encode-admission-request;
candidate completes the full40217563-byte response33710ms (quoting769ms).
Admissions, original/specialized IR and generated JS hashes are IDENTICAL.
Independent ECMAScript serialization validates the transport bytes.
[Full comparison](docs/PSC1_COMPILER_TRANSPORT_COMPARISON_2026-10-21.json).
The profiler is diagnostic only; its output is never adopted as G1.

The host-only session pins inputs/options, whole candidate and tool identities;
it performs actual generated invocation, independent exact graph admission,
target syntax/export checks and closed inventory/hash rechecks under a lock.
One atomic current-pointer rename publishes an immutable generation. Prior
generations remain.24 host boundary checks passed on real checker/publication
state with explicitly native-prepared replay fixtures. Actual G1 uses this same
publisher. [Protocol](docs/PSC1_GENERATED_COMPILER_SERVICE.md).

The first ordinary fixture used unsupported plain Nat do and Prop '<'. Corrected
to the existing Id Nat / Bool Nat.blt contract, with both authored grammar cases
admitted and executed through the native facade. No language rule was widened.
The earlier3-case partial receipt remains immutable.

## Authority, remaining work and durable commands

Official checker: Lean4.35.0,
eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Owned kernel evidence is separate.
Keep ubuntu24.04, Node22.23.3, TS7.0.2, Rust1.90.0, Python3.14.8/3.15.0,
PHP8.5.11+GMP, wasm-tools1.254.0 and Wasmtime49.0.4 pins.
Use expected-HEAD guarded non-force descendant updates; no main merge/release/npm.

Next: inspect new generated workflow at exact candidate head, complete real
G2/G3 or resolve its actual bottleneck; verify current full scoped final state.
Then follow Rust owned callbacks and R1/R2/R3, measured collections/control,
finite fourteen-family grammar×target contract and typed console+UTF-8 file IO.
Wasm W1-W6, optional adapters and source refactoring stay in dependency order.
No formal erasure/backend preservation, broad conformance, complete14 families,
Rust fixed point or unrestricted self-host claim is made.

Linux reproduction:
lake build psc1_js_service_tests psc1_js_service_seed psc1_source_census_probe psc1_independent_checker;
.lake/build/bin/psc1_js_service_tests;
node scripts/compiler-source-census.mjs --strict-phase directjs-compiler;
node scripts/compiler-closure-qualification.mjs --phase directjs-compiler --assurance ordinary-checked;
node scripts/generated-compiler-diagnostic.mjs.
The diagnostic calls stage0 once, disables native tools, then runs generated
semantics and repeated-generation attempts; use its retained records on failure.
