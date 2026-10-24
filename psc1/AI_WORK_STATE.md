# PSC1 AI work state

Updated 2026-10-24 Asia/Jakarta. Use connected GitHub tools and Linux Actions only.
Fetch exact HEAD before expected-HEAD non-force writes. No PR merge or npm
publication authorized. Practical Core v1 remains 14 families / 37 finite criteria.
[Roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) owns the dependency queue;
[canonical receipt](docs/PSC1_DIRECT_SELFHOST_QUALIFICATION_2026-10-24.json)
owns immutable attempts, artifacts, timings and source identities.

## PHP G1 accepted; G2 allocation diagnosis — 2026-10-24

Request59ef3544/run40071043260/job120804424493 proves that the capture fix
reduced seed candidate size from1002108077 to59452682 bytes; raw PHP source
18412349 bytes/SHA3623c6341e139a0febae0b5f8953cacabd0551b0af1406316369e30df41a53f5.
Native seed22138ms/maxRSS392476KiB. G1 independently admits, validates both
strict IR graphs and executes all ten positive/refusal cases with native compiler
tools removed. G2 FAILED after8372ms/maxRSS1122256KiB at unchanged PHP1G.
No G2/G3/fixed point is qualified. Artifact12551302677 digest
bda38c19687b8ad9a75d5c6c3e047481ed04ad0d3b579ad74449dcba93825fbc.

Read-only40071337944 locates the failure in psJsonStringToChars' explicit tail
loop. Instrumented-copy40071473414 atb16b8c6a confirms seven pending generators
while heap grows to1G; request1789940 bytes/1789677 scalars. This is a storage
cost, not a growing scheduler stack. Diagnostic timing is not qualification.

Current patch uses the validated owner/constructor field layout to emit a flat
packed internal inductive array, following the existing compact target pattern.
Fields still evaluate in original order before canonical positioning; match
indices resolve by owner/constructor/field, so reordered bindings remain correct.
Records, runtime bytes, public scalar ABI/refusals, checking and limits stay.
The same emitter retains legacy layout for differential tests. Require native
shape/order/Unicode/recursive/owner tests,200000-cell1G execution and full source
gate success before PHP-only retry. Python's unchanged run remains active.

## Python/PHP actual workload update — 2026-10-24 06:37 UTC

PHP job120800177269 in40069631375 FAILED before G1 admission: its native seed
candidate was1002108077 bytes, over the unchanged134217728-byte cap.
Read-only diagnosis40070297469 of the retained artifact found961724361 bytes
of encoded source and18816024 global-reference capture text occurrences.
The old emitter captured every global in every closure; this was quadratic.
Native seed25495ms/maxRSS4688184KiB. No PHP generation is qualified.

Sourceda5c5c6e894019f8200e0771512f7e232a3403c6 replaces only PHP global capture selection
with lexical free-variable demand; globals retain reference identity and order,
locals/helpers retain their original captures, and exhausted analysis falls back
to the complete original set. No memory, fuel, output or stack cap is increased.
Gate40070774006/job120803515773 PASSED both86-module/both-grammar censuses,
all prior proofs/runtime/library tests and144 legacy-fallback/output/refusal
comparisons plus independent PHP token comparison outside global use clauses.
The budget fallback theorem compiled. Commit4e4bfcb5a535af39925c5a601d39d08fcdca5bb7 adds
execution of lexical shadow/initializer/match/nested/forward/helper cases to both
gates (40070902724 pending). Require that success before a PHP-only retry.

Python job120800177259 remains active in40069631375. Do not duplicate it.
The PHP-only emitter change does not modify the Python captured compiler closure;
verify inventory identities before reusing evidence. Current-source full CI and
clean reproduction are still required separately.

## Python/PHP source-port checkpoint — superseded status below

Continue on feat/psc1-python-php-selfhost-20261024, draft
[PR176](https://github.com/dwijayuda/pskernel/pull/176), based on preserved
direct-target checkpoint6393226e5d29ad246e9421fe398d78c43954c6d9.
Verified executable/source checkpoint:24f93a383886894cb411ecb76ff38fa46dd47177.
[Source gate40069330525](https://github.com/dwijayuda/pskernel/actions/runs/40069330525),
job120799158087 PASSED at this checkpoint:86 modules per target, both .lean/.ps
grammars accepted with no refusals. Native build and all named runtime/state/
retained-emitter/admitted-library regressions pass. Seven state and four arity
complete API equalities are checked by official Lean4.35.0.
Artifact12550731070 digest432892ba71dfd10da59fcc150fa0220476fae2881c27d199cfca10820afb603d.
Source readiness is not generated compiler qualification. No Python/PHP G1,
G2/G3 or fixed-point qualification is claimed yet. Next commit is the isolated
explicit request for both targets, from this verified implementation.

Actual request30389b1f218ec9c2f35321e93104edb7bb19d747, parenta685da2c6c4090d103d09a855accfcda674b3cf6,
[run40069631375](https://github.com/dwijayuda/pskernel/actions/runs/40069631375)
was launched for both targets; see superseding actual-workload update above. Exact request-only gate120800073301 PASSED.
Python job120800177259 is active; PHP120800177269 failed before G1 admission. Re-query terminal evidence before making any qualification claim.
Documentation updates after the request do not change captured compiler source
or pinned harness/runtime files and do not cancel the manual generation jobs.

The existing emitters now have one portable implementation each:
Ps.BackendPython.Portable and Ps.BackendPhp.Portable. The old Module paths are
native compatibility adapters preserving existing APIs/defaults/metadata.
Both native CLI and generated compiler facades call the same portable emitter.
There is no second handwritten compiler, alternate frontend or native delegation.

The proved normal form is State -> Except Error (Prod Value State):
seven complete operation equalities to StateT (Except) passed official Lean;
four complete arity-dispatch equalities also passed the source gate.
The source port uses explicit state/results, flat constructor cases and typed
workers under dynamic inputs, without extending the frozen language grammar.
Ordered line/origin accumulators preserve printed output and offsets.

Linux40068694963/job120797262656 at62cd0f1b:
native build,34816 retained runtime catalog/order/duplicate/unknown comparisons,
seven state API proofs/tests,144 complete retained-emitter output/refusal
comparisons, and all four independently admitted/generated runtime probes
(Python/PHP × Lean/PS,104 runtime and8 state queries each) PASSED.
These are compiler/library regressions, not generated compiler qualification.
Both closures now contain86 modules and pass the full four-lane source census.
Contextual Except spellings, nested do RHSs, list/nested constructor patterns,
tuple action binds and recursive application arities were normalized as source
classes. Native compatibility APIs remain intact; no grammar/authority bypass.

The shared production harness supports both targets, the existing ten cases,
hash-bound unchanged-wire transport and the same independent admission/IR
pipeline. Python3.14.8 and PHP8.5.12/ext-gmp are pinned; qualification records
interpreter binary hashes. Guard40068963704 caught setup requesting8.5.11 but
installing8.5.12;8.5.12 is now explicit and exact-version drift remains fatal. Preserve G1/corpus/tools240s,checker120s,
G2/G3 correctness1800s, separate original performance240s and all other limits.
PHP retains1G; Python recursion and integer-digit global settings are unchanged.

Next: finish the whole source/negative gate, issue one request-only
.github/qualification-requests/psc1-python-php-selfhost.json commit from fresh HEAD,
then execute genuine independent G1→G2→G3/fixed points for both targets. Diagnose
actual generated requests rather than infer performance from fixtures.
Obtain full current-source37/37/seven-backend/application evidence and clean
reproduction separately. No merge or publication.
[Continuation](docs/PSC1_PYTHON_PHP_SELFHOST_CONTINUATION.md) and
[receipt](docs/PSC1_PYTHON_PHP_SELFHOST_QUALIFICATION_2026-10-24.json) own resumption.
The older direct-target performance queue below is deferred by this user mission.

## Completed DirectJS and owned DirectWasm mission

Source commit 133e589288b563e74578b771ec35595beb3a9fe8 is genuinely self-hosted
for both targets by request 2d1f8244d8402fbccd5a018890d61d8ed4d20775,
parent eefedf2a3f9f0002975870e8128bb0f404723946.
[Qualification 40062120079](https://github.com/dwijayuda/pskernel/actions/runs/40062120079)
PASSED both jobs: JS 120777813920 and Wasm 120777813877.
Each target used one native seed, disabled native compiler tools afterward,
executed G1 → G2 → G3, independently admitted each generation, validated strict
original/transformed IR, and passed all ten positive/negative observations.
Exact captured source/admission/IR/observation/target-byte fixed points passed.

| Target | Modules | G2 ms / maxRSS KiB | G3 ms / maxRSS KiB |
| --- | --- | --- | --- |
| DirectJS | 87 | 824066 / 3076776 | 832426 / 3179880 |
| Owned DirectWasm | 98 | 876840 / 1508096 | 888398 / 1816228 |

These are actual generated compiler workloads with different target closures,
not a matched backend speed benchmark. Memory uses Linux child maxRSS and
separately sampled descendant RSS; see exact execution events in the receipt.

JS closure: 5b1824ce8d98a9ec9068f351f28abab8485a9786510c47fd5b4cedeac8734a2e.
Wasm closure: 322f29eb0b4c734ea09c7f4ee53380633faa3799b367808c0d393783cd6e48c1.
JS source SHA256 across all three generations:
8dad2e7fb1e3eb834bed9fc7581b8f2cce36f834c5e7842f19b6f8bb904b871a.
Owned Wasm binary SHA256 across all three:
addc90b9cfff0dcbb8ea8d8f1d7824187750b5250514915608cda5607f170b72.
Artifacts: JS 12548433615; Wasm 12549160290. Digests, request and producer
identities are in the receipt. Operational manifests contain timings/events,
so different manifest hashes do not contradict equal compiler executable bytes.

## Independent clean G1 reproduction

[Audit 40064496804](https://github.com/dwijayuda/pskernel/actions/runs/40064496804)
PASSED both clean Linux jobs at diagnostic control commit
36d917b01a008fcae2259fc7a604b3e8a47e3db1 on
diagnostic/psc1-direct-clean-g1-20261024.
No .lake build cache was restored. Fresh native seed/checker builds execute
the production G1-only harness, independently admit G1, validate strict IR and
all ten cases, then compare exact source inventory, admissions, IR, observations
and JS source / Wasm hex+binary bytes against EACH qualified G1/G2/G3.
All comparisons passed. Artifacts 12548393011 (JS), 12548652944 (Wasm).
The diagnostic request/script/workflow are preserved on that branch.

Scope: independently rebuilt G1 reproduces the three previously qualified
generation artifacts. A second independent full G2/G3 replay was not run.
This is not a DDC or formal compiler semantic-preservation proof.

## Source mechanisms and regression evidence

Focused 40061782715/job120776657312 PASSED at source133e5892:
- Eleven all-input full JS API equalities against retained originals, covering
  decimal/type/expr lowering, validation, tail aliases/captures and printing.
  Move recursive prefixes beneath every dynamic input; scan233 owned definitions,
  reject all eleven original defects, test million-fuel early results/refusals.
- Three complete Wasm encoder API equalities: Except flatMap, byte chunks and
  UTF8 characters use fully applied reverse accumulators, preserving bytes,
  order and first-error priority, including100000-element cases.
- Three shared environment/constructor/recursor lookup equalities and100000
  early/missing/kind/duplicate-payload cases, source146270cf.
- All earlier52 Wasm prefix, six foundation and checked/erasure collector/index
  equalities; original fuel, errors, insertion/index and source/logical pairing.
- All retained JS lazy UTF8 views, capture/alias/fuel,10584 view comparisons,
  64 direct-dispatch order/trap tests, native/reference comparisons.
- Owned import-free GC Wasm transport,96-opcode/Unicode/Nat/Int cases and
  complete87/98-module Lean/PS source censuses. No verification or limit changes.

Earlier failures remain immutable in the receipt. In particular the older
shared-lookup-only JS baseline d7c6f166/run40061402443 FAILED its G2 deadline:
1800233ms /3107644KiB, no G3/fixed point. It lacks the eleven later JS fixes.
Earlier Wasm stack traces reached encoder flatMap; the top Nat division frame
did not establish an arithmetic defect. Fix the demonstrated source class,
rather than raising stack/fuel or replacing the compiler architecture.

## Full Practical Core and review

[Full40062210987](https://github.com/dwijayuda/pskernel/actions/runs/40062210987)
PASSED: Linux120780825013 and final gate120786364196;37/37 qualified,0 blocked,
releaseReady=true, all seven backends, both grammars, applications, minimum
Python and installed native package/IO/library regressions. Tested review HEAD
06186537cf9339fc3f24a7d13387c2ad55ee0749 and merge
980d096ca3e85b9ad2970f16602ad1d14a089d69 have identical Git tree
cbf312e1f4bca9e7085719c12b627be5c16099a7, verified through GitHub APIs and checkout log.
Artifact12549325904, digest
sha256:6ad48b109e2e995c344a6855a85de44380f6ee628b67f4033990a152598a7bf9.
This qualifies the tested compiler source; the final receipt update edits docs only.

Draft [PR175](https://github.com/dwijayuda/pskernel/pull/175) remains open,
unmerged, based on preserved PR174/integrationafed7c4b. The review branch
work/psc1-direct-selfhost-blockers-20261024 was advanced without force.
Final evidence reconciliation edits documentation only; compiler code remains
the qualified133e5892 source. No merge or package publication occurred.

## Boundaries and next executable work

The original performance-240s profile remains separate and unqualified;
the measured current G2/G3 times exceed240s. Correctness-1800s does not weaken it.
G1/corpus/tools240s, checker120s, G2/G3 correctness1800s, semantic fuel and
all memory/stack/security/refusal limits remain unchanged.

Official independent Lean4.35.0 checker
eb6cafb7290e8bd5f2937522d8d804f58f02bafc, strict original/transformed IR and
negative tests remain mandatory. All targets share the existing compiler
service, frontend, elaborator and checked pipeline. Only emission/runtime
carriers differ; no alternate handwritten compiler or native delegation.

Preserve qualified Rust branch fix/psc1-rust-owned-string-moves-20261023,
head83e18fe183498f7d8b0fc3e3faa5bdacc41cb23d, source5e0b548e/run39908529181,
G2/G3692788/660042ms. Preserve TS perf/psc1-erasure-applied-workers-20261023,
head84e1e16f61cec3d28d9fdc62d6eaca4f3c0a8577, source748fd5fd,
request079b26b9/run39993829327, G2/G3545895/588552ms; full39993835819 passed37/37.
These qualify older snapshots, not a fresh Rust/TS replay of changed common source.

No active self-host qualification requests remain. Next dependency queue:
profile the now-completing exact generated compiler workload, optimize one
measured generic bottleneck with retained-original API/negative proofs, then
rerun changed-source focused and genuine qualification. Keep original240s
performance acceptance explicit. Independent full-chain repeatability is a
separate future evidence scope. Do not repeat unchanged correctness chains for
documentation-only updates. See the [executable continuation](docs/PSC1_DIRECT_SELFHOST_CONTINUATION.md).
