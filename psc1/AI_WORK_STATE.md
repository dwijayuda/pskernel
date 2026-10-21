# PSC1 — complete compiler sources and whole closures qualified; continue generation

Updated2026-10-21. Active draft [PR172](https://github.com/dwijayuda/pskernel/pull/172)
on fix/psc1-closure-normalization-20261021 preserves #171 at
1fad9ed53cda9b23ac30be9cea85e7857437564e and every intermediate commit.
Execute [the Sol High plan](docs/PSC1_SOL_HIGH_CONTINUATION_PROMPT.md)
continuously. The user explicitly requests no small-milestone handoff.

## Current continuation — normalize new index recursion; qualification pending

Atde26057a source census39540600631 refused the new StringSet module's
psStringSetBucketContains at27:1, structuralRecursionArity, in both lanes.
Its explicit list binder returns a String function, so direct self application
with2 arguments violates the portable structural recurrence shape. Bind the
partially applied smaller worker inside the returned lambda. Apply the same
correction to FromListWorker proactively. Native signatures/evaluation remain.

Linux benchmark39540600900 DID execute the exact fixture on both versions.
[Receipt](docs/PSC1_SPECIALIZATION_QUEUE_COMPARISON_2026-10-21.json).
Input3802251 bytes, SHA256a0780796c18ad15d4c880dcfd2356a84b8e76096adbd67e7b8dc2eaa40375097.
Parent refuses fuel-exhausted316ms/67880KiB; candidate completes full revalidated
output586ms/89492KiB with all128 concrete entries plus1 generic instance.
This demonstrates bounded completion, not lower wall time or memory; the parent
did less work because it refused. Native library compilation passed; whole portable
source qualification and actual G1 are still pending after the recursion fix.

## Stable specialization scheduling candidate

Parent a37a4ce61139db229f86d50645c65a0597119035 has final successful
full scoped39537087657, focused39537087675 and all3 exact-closure jobs39537087643.
Generated diagnostic39537087665 failed at actual native compiler generation:
request-loop / fuel-exhausted. No G1 was produced. This is separate from source
acceptance, independent admission and strict original IR, which passed.

The original loop charges every duplicate queued dependency against16384, even
when its canonical key was already seen. The candidate schedules each valid key
once, with a portable immutable string trie and full equality in collision buckets.
First-encounter FIFO order remains, malformed requests remain, every nongeneric
source declaration remains, and the existing singleton transformation and
before/after validation remain. The budget is STILL16384; zero-budget refusal
is unchanged. A dependency batch is captured with an empty queue because request
processing never reads the pending queue; it only appends dependencies.

Native assertions cover hash collisions, Unicode, persistent snapshots,4096 keys,
stable ordering, duplicate elimination, seen keys and malformed first-error order.
The new Linux comparison builds the SAME authored IR fixture against immutable
a37 and the candidate, checks exact input SHA256 parity, all128 concrete entries
retained plus one generic instance, unchanged limits, elapsed time and maximum
RSS. Expected baseline refusal and candidate acceptance are hypotheses until CI.
The generated compiler diagnostic separately reruns the ACTUAL full source workload.

Next: inspect both-grammar source gates and queue comparison, then the actual G0
seed/G1 execution. Do not raise limits or claim G1/fixed-point success from the
synthetic benchmark. Continue the plan, including session publication and G1/G2/G3,
after actual G1 semantics. Read-only retained-artifact inspection is manual-only;
its first successful original-artifact inspection remains in history.

## Earlier exact qualified checkpoint

Source head912dcc1c055f78ead505c057b1271b88fd1656e5.
Tested merge3c0e45261448a8c633fe82d4be79586d1ec1c90d.
All final GitHub workflow states were re-queried completed/success:
- [full scoped39527583902](https://github.com/dwijayuda/pskernel/actions/runs/39527583902),37/37 steps;
- [focused native39527583957](https://github.com/dwijayuda/pskernel/actions/runs/39527583957),11/11;
- [whole closures39527584037](https://github.com/dwijayuda/pskernel/actions/runs/39527584037), all3 phase jobs.

[Exact committed receipt](docs/PSC1_BACKEND_CLOSURES_QUALIFICATION_2026-10-21.json)
contains complete consolidated scoped qualification, per-lane canonical graph
identities, source/logical counts, partial names and all artifact metadata.
Scoped artifact12315040160:
sha256:4a63bc481457054c9e3fe9bcf44b7bab135d349e619bd1f962311ffa9dc0ec73.
Retention applies; committed receipts stay durable and are not authority tokens.

## Complete actual compiler closures

BOTH fresh grammar lanes accept every selected source module:
semantic67/67/67; DirectJS79/79/79; Rust84/84/84
(modules/parse/elaboration). Strict selected-phase gates run all source modules;
none is skipped. PS is owned canonical translation from repository Lean, retained
as actual readable parser inputs with byte counts/SHA256. It is not independently
authored PS compiler source.

Whole selected graphs actually passed independent official admission and original
strict IR validation in both lanes:
- semantic checked-only:2423 original/logical Core declarations;
- DirectJS ordinary-checked:3144 original /3146 logical declarations;
- Rust ordinary-checked:2961 original /2964 logical declarations.

Actual origin/member coverage equals the original source Core batch. Ordinary
logical expansion adds one retained private implementation body per actual partial:
DirectJS psBackendPublicTypeSupported and psJsNeedsUtf8Runtime; Rust the target
predicate and RuntimePlan typeRequirements/exprRequirements. The checker admits
the exact retained logical graph. Erasure then consumes the SAME immutable checked
batch or ordinary source/logical/body pairing; psCompilerOrdinaryIr repeats pairing
validation. The actual psStrictValidateModule entry point accepts the resulting
original IR. Canonical admission bytes match between lanes in each phase.

Official Lean4.35.0 checker commit
eb6cafb7290e8bd5f2937522d8d804f58f02bafc uses the unchanged provider-prelude
environment and kernel limits. Owned-kernel checks remain separate. This is exact
source-graph admission/IR evidence, not erasure/backend preservation, unrestricted
language conformance or generated compiler execution.

## Normalization and ownership

ParseDo124:67 and all subsequent syntax/elaboration/compiler/backend census
blockers are corrected. Complete module normalizations preserve all compiler
decision logic, validation/refusal order and existing budgets, using explicit
constructors, sequencing, typed callbacks and structural state workers.
Maintained both-lane gates and all prior native/runtime/refusal groups remain.

Unsupported private tokens formerly became trailing application arguments of a
preceding definition. Both parsers now refuse them cleanly. Original file-private
compiler helper leaf names move under explicit Ps.Internal.ElabData and
Ps.Internal.RustRuntimePlan owners; every call uses the qualified identity.
The active direct host excludes that reserved implementation namespace from public
entry roots while retaining the exact source/admission/runtime dependency graph.
This corrects the earlier Data normalization's global private leaf names.
[Ownership map and policy](docs/PSC1_COMPILER_INTERNAL_OWNERSHIP.md).
Actual handwritten Lean/PS captured-entry tests check admission, retained internal
helpers, hidden public roots and refusal of unqualified helper access.

Earlier immutable source/semantic/frontend receipts remain scoped to their
original source identities. New qualified checkpoint above includes this correction.

## Active continuation — canonical original IR identity, pending CI

Add portable CompilerIr.Encode, registered as an explicit Lake root and selected
DirectJS/Rust dependency. The candidate phase counts increase by one; do not
substitute the old79/84 checkpoint for the new live census. Every new source must
pass both maintained grammar gates.

[IR identity format](docs/PSC1_IR_IDENTITY_FORMAT.md) retains all constructor tags,
owners, labels, types, binders, list order and bodies; exact integer payloads are
decimal JSON strings. Encoding is data, not validation. Retain the actual original
IR that passed strict checking with size/hash and grammar byte parity, and derive
primitive inventories from those IR bytes. Exhausted serialization depth refuses.
New native tests cover independent JSON parsing, huge integers, Unicode/escapes,
graph/body identity changes, match labels/bindings/projections, malformed IR
validation and serialization exhaustion.

Add a LIVE DirectJS checked-only refusal test: the real complete backend source
with original partial functions must refuse unsupportedDeclaration before
independent admission; no automatic ordinary fallback. Explicit ordinary mode
continues as the separately qualified path.20 closure count/assurance contract
checks remain, alongside38 census integrity checks and every prior gate.

Next: qualify original/transformed IR identities and actual target emission, then
add/execute a portable scalar compiler facade. Native stage0 may generate G1 once;
afterwards deny native frontend/eraser/emitter delegation, retain the external
checker and target tools, and record actual subprocess allowlists. Execute
handwritten positive/negative multi-module/namespace/integer/Unicode/pattern/
handler/ordinary-loop cases, then identical compiler closure G1->G2->G3.
Rust owned aggregate callbacks and R1->R2->R3 follow with their own evidence.

## Commands and pending boundaries

Linux CI only:
- lake build psc1_source_census_probe psc1_backend_normalization_tests psc1_ir_encoding_tests
- node scripts/compiler-source-census-contract-tests.mjs
- node scripts/compiler-closure-contract-tests.mjs
- node scripts/compiler-source-census.mjs --strict-phase directjs-compiler
- node scripts/compiler-closure-assurance-tests.mjs
- node scripts/compiler-closure-qualification.mjs --phase semantic-compiler --assurance checked
- node scripts/compiler-closure-qualification.mjs --phase directjs-compiler --assurance ordinary-checked
- node scripts/compiler-closure-qualification.mjs --phase rust-compiler --assurance ordinary-checked

Generated compiler execution, transformed compiler IR, self-compilation and
G1/G2/G3/R1/R2/R3 remain not-run. Canonical IR encoding/inventories are pending in
the current candidate. No formal preservation theorem is provided. All14 full
Practical Core families remain incomplete. Efficient optional indexing/finite
iteration must be measured/fixed where actual compiler workloads reach them;
Rust aggregate closures, typed IO and remaining finite parity cases stay open.
Component Wasm ABI remains Bool-only. PSC2/Lean4.34 history is not current evidence.

GitHub/Linux CI exclusively; no local repository checkout/files/build/tests.
Fresh expected-SHA non-forced descendants only. No main merge/release/registry
publication, unchecked axiom/authority, source filtering, weakened tests or raised
existing budgets/pins. The final #171 scoped39508739868/focused39508739941 were
verified before continuation writes. Continue beyond this checkpoint.

## Canonical IR whole-closure result at68490479

[Exact run39529213948](https://github.com/dwijayuda/pskernel/actions/runs/39529213948)
completed success in all3 phase jobs. Tested merge
350b8caed3f0153f22c11147492508bf48e7cec0.
BOTH lanes accept semantic67/67/67, DirectJS80/80/80, Rust85/85/85 and actually
pass whole preparation, independent admission, original strict IR and canonical
IR artifact validation. Source/logical counts:2423/2423,3172/3174,2989/2992.
[Committed IR receipt](docs/PSC1_CANONICAL_COMPILER_IR_2026-10-21.json) retains
every actual lane hash, size, inventory and artifact identity. The live checked-only
DirectJS test also passed by actual unsupportedDeclaration refusal in BOTH lanes.

Exact original IR bytes/hash:
semantic3931582/f8610d242d5a627f82ab3727868bdefc551ef4a74e0bc35eb6ee581e0e336b36;
DirectJS4874708/97ffc97585a6a3c7f34e7841b5a53df5e093a32ef3c74607a98521bf3de85e6a;
Rust4925315/a6c950b58114e14d2a6fd422250d6214010fa0a18387f092a1ea0051d282f1bd.
Actual graph inventory in each phase has20 intrinsic tags and6 primitive types;
it is a whole-IR inventory, not a dynamic execution trace.

Focused39529214057 failed the new unit fixture's comparison between encoded text
and Lean.Json.compress output after parsing succeeded. Replace that formatting
assumption with comparison to an independently constructed complete expected
JSON value, retaining huge-integer/Unicode/order/body/match assertions and the
host's exact compact-byte parity checks. Print the two small expected/actual trees
on mismatch. This descendant's focused/full CI is pending. Do not claim the
unit fixture passed or transfer912dcc1's full scoped qualification to this head.
Target/transformed IR and actual generated compiler execution remain next.

## Full canonical IR checkpoint and next actual compiler candidate

Exact headEE8606baba02d268717cbe845ef772b73c2248b5 (lowercase in Git) passed
full scoped39529882113, focused39529882130 and all3 exact-closure jobs in
39529882129. Tested mergef128fa99e9153a50a55dbc453ae801ecba57b5e6.
[Full committed receipt](docs/PSC1_CANONICAL_COMPILER_IR_QUALIFICATION_2026-10-21.json)
contains actual lane/IR identities, all artifacts and consolidated scope. All8
new IR encoding assertions passed. Both actual checked-only backend refusals passed.

Continue with the NEW portable scalar compiler-service composition root.
It imports every previous DirectJS dependency plus the existing pure
Bridge.CompilerHost transport. Census roots now select the actual production
composition root, preserving the full prior module set and adding the facade/
transport. Expected new DirectJS module count82 is not a live qualification yet.
Its own full parse/elaboration must pass in both lanes. Shared syntax ownership
helpers give native and generated public-root decisions one production predicate.

[Service protocol/limits](docs/PSC1_GENERATED_COMPILER_SERVICE.md).
Candidate preparation, exact ordinary pairing, original/transformed IR checks,
JS target checks/printing and origin transport are production code, not a
handwritten host compiler. Candidate computation stays provisional until the
external host admits the exact graph. New native facade tests independently
check actual graphs, target syntax/execution and both-grammar missing/duplicate/
extra/malformed/wrong-body/partial/verified boundaries.

New psc1-generated-compiler Linux workflow builds the native seed/test/checker,
qualifies the full exact composition, generates G1 exactly once with native
stage0, checks/adopts its exact candidate, disables native compiler tools, then
runs actual G1 compiler semantics on a handwritten corpus with tool-role/identity/
resource records. The initial runner is diagnostic CI staging, not the complete
production atomic service publisher. Actual G1 execution is PENDING, not assumed.
No fixed point or source/backend preservation is claimed.

Next actionable CI commands:
lake build psc1_js_service_tests psc1_js_service_seed psc1_source_census_probe psc1_independent_checker;
.lake/build/bin/psc1_js_service_tests;
node scripts/compiler-source-census.mjs --strict-phase directjs-compiler;
node scripts/compiler-closure-qualification.mjs --phase directjs-compiler --assurance ordinary-checked;
node scripts/generated-compiler-diagnostic.mjs.
If the actual compiler workload exposes target planning/runtime/collection costs,
fix the general mechanism with measured evidence; do not raise limits or patch
particular declarations. Continue to session publication binding and real G1/G2/G3
after G1 actually executes, then Rust owned aggregate callbacks/generations.

Atcad9bc63 native service tests failed to compile because the local variable
syntax is a reserved Lean keyword (JsServiceTests66:7). Rename it targetSyntax;
all assertions remain. Generated workflow39533776394 and focused39533776401
stopped at native test compilation, before G1 generation. Do not claim execution.

## First actual compiler-target blocker — specialization, not source acceptance

Head0559453b5936ba15bf9cf92cfa47d1c8ab66d34f passed full scoped39534197238,
focused39534197158 and exact closures39534197273. Native facade tests independently
admitted/executed both-grammar program graphs and passed all refusal cases.
Actual complete composition remains82 modules in both lanes; DirectJS source/
logical Core counts3213/3215. Canonical original IR4951117 bytes:
1a2c0aed5c3bbb863dc2c2d5a9aeff658ae8922ba32da36467d904ce5f079a59.

Generated diagnostic39534197286 failed BEFORE producing G1. Native seed actually
ran once for25933ms, then returned status=refused, phase=specialization,
code=PSC1_BACKEND_SPECIALIZATION_FAILED. Read-only Linux artifact inspection
39535477289 recovered the exact348-byte response from artifact12317101575,
digestsha256:90ee85b793c1920e83c5002618ef5a802da91d52bfcba2a08488fd6b21da65af.
The old host assertion checked grammar before status and hid this refusal;
report status/phase/code first. Generated execution, self-compilation and fixed
points remain not-run.

Add general typed specialization diagnostics: preserve original tail-first seed
and first-error order, original singleton per-item transformation, request queue/
seen order, validation before/after and all64/128/16384 budgets. Record failed
stage, IR owner, original error and request key. Legacy APIs keep their exact
result/error types; shared closed-plan legacy messages are unchanged. The
production facade consumes the detailed plan, not a diagnostic-only alternate
compiler. Tests cover raw seed owner/order, request owner/key, forged input,
unchanged zero-budget refusal and public-coverage/legacy message correspondence.
This candidate is pending Linux qualification. Fix the actual traced mechanism;
do not bypass specialization or filter the compiler source to make G1 pass.
