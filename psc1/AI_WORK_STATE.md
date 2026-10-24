# PSC1 AI work state

Updated 2026-10-25 Asia/Jakarta. GitHub/Linux Actions only; fresh expected-HEAD
non-force updates. No merge or npm publication authorized.

## Active v2 G2/G3 qualification and measured Rust/Wasm blockers

Resumed from84cc15375e4236a902e8af6658d92a640c6aa22a/PR178 on2026-10-25.
Explicit request9359f07320eaf84af1e551fb86c38718150291ff launches Rust/Wasm
[40120346573](https://github.com/dwijayuda/pskernel/actions/runs/40120346573)
at the existing structured-v2 source. Do not duplicate or cancel its live jobs.
No current-v2 G2/G3/fixed-point success is claimed while it runs.

Bounded archived-G1 diagnostic766297e1/run40120526852 verifies exact producer
manifest/executable/captured source identities. Rustjob120950869895 passes
three default-stack GDB samples at60/120/180s: each is String::clone/memcpy
inside psJsonStringCharsAccWithFuel$worker, before psJsonParse completes.
This locates repeated whole-input copies, not the later stack-overflow site.
Wasmjob120950869762 retains240s V8 samples; Nat binary runtime arithmetic
dominates the top samples. Mapping exact production function indices is
separate diagnostic40120639238, not self-host qualification.

The active Rust fix structurally recognizes checked identity-forwarding,
read-only String intrinsic wrappers, and moves a same-position unchanged
String after evaluating every other tail argument into ordered temporaries.
It preserves public String signatures, all wrapper shadow/type/arity/fuel
guards, eta-capture snapshots, old paths for other arguments and all resource
limits. Focused Linux CI compares actual old/current Rust observations and
runs two million-character scans, both source grammars and enlarged G1;
a bounded G2 stack diagnostic follows. The first Rust fixture run40121512148 passes100 retained-original comparisons
and two million-character Unicode scans in1060ms. Its owned source census
caught a nested pattern syntax restriction;9fcab97b rewrites the same match
into the supported nested form. Unchanged v2 Rust G2 in40120346573 fails
after648336ms with stack overflow; no G2 candidate/G3/fixed point.

Exact Wasm mapper40121535934 verifies identical original/specialized IR and
8343 production function indices: the dominant sampled functions are Nat
compare/half/divmod/subtraction/addition/construction. The active runtime
change factors even divisors and handles division by one directly while
retaining the original odd-divisor arbitrary-Nat algorithm and division by
zero semantics. Differential Wasm tests retain the exact old divmod function,
share every other runtime function, use actual validated binaries, compare
against JS arbitrary-precision arithmetic and record workload timing.
Focused40121896995 passes703 Nat-divmod pairs/2812 actual Wasm results,
including513-bit inputs, zero/one/odd/even divisors and a BigInt oracle.
Sampled128-bit/128 workload351ms→297ms is a scoped measurement only.
Both grammar audits and enlarged Rust G1 pass at75adeaa7, closure
159b072e2c39365b67ec447b85f53d8389ba0b73e97c815976545d160d77294e.

The bounded G2 samples still show String copies. Exact archived worker
inspection40122554517 proves why: worker fusion intentionally uses fresh
parameters and typed lexical lets; the original same-position move check
does not follow those aliases. Extend String let moves only when the
existing conservative WorkerFusion.mentions visitor proves the original
local absent from the full body; exhaustion/escaping captures retain copies.
Tail arguments move only their last direct local occurrence after all other
argument snapshots. Add renamed-worker, duplicate, capture and exhaustion
regressions. This keeps worker fusion's capture-safe lexical IR unchanged.
The renamed-worker extension passes120 old/current observations and three
million-character scans. Both grammars and enlarged G1 pass8b61aea4, closure
d90f44e3e883c7502869fbfbf5eb312cee5d78ba61b893bb148a4900468c4ab3.
Actual G2 diagnostic40123048722/job120958550385 now reaches failure in8563ms:
GDB records repeated drop_in_place<List$spec$Char>/Rc::drop_slow frames,
SIGSEGV then SIGABRT. The exact recursive destruction site is established.

Add generic iterative final-owner reclamation only for private inductives
with an empty constructor and exact self-recursive Rc fields. Detach those
fields into a non-reentrant, thread-local drain; shared owners only decrement.
Public enum layouts/field move-out remain unchanged; match borrowed carriers
with identical cloned bindings. No unsafe code, leaked owners, increased stack
or resource limits. Focused tests compare retained recursive sharing results,
exercise a million-node private spine and compile public owned-field matches.
Focused40124112555/job120961745118 passes120 retained-original observations,
three million-character scans2054ms, and million-node private spine1064ms/
127632KiB maxRSS with public enum move-out preserved. G1 closureeeca0749
passes both grammars/all40+9 cases. The default-stack full G2 diagnostic now
runs180794ms without crashing; actual samples reach elaboration/type inference.
This is diagnostic progress, not G2 qualification.

The first isolated four-engine request4c1ad0f0/run40124889755 starts fromd771e1ca
with only workflow/request differences. It is superseded before qualification
by a resource-bound correction: keep the original zero-dividend fast return
before even-divisor factoring, so recursion always halves the dividend.
Add tiny dividends against a20001-bit divisor. Cancel only that exact stale
run via a validated Linux Actions control; preserve original v2 request9359
and its still-running Wasm job. Corrected-bound focused40125175783/job120964951312 PASSES707 operand pairs/
2828 actual Wasm results including20001-bit divisors, all Rust fixtures,
both grammars and enlarged G1 closure5411a98e. Original structured-v2 Wasm
request9359/run40120346573/job120950418397 genuinely PASSES G2/G3/fixedpoint
at closurea3350d64:1647713/1542403ms, peak2767832/2192844KiB. Rust at that
same old source remains failed; preserve individual Wasm success.

The first corrected four-engine requeste23afbdf/run40125830600 starts at
the exact primary0c75 snapshot. A final namespace regression supersedes it:
fully qualify the private cleanup runtime's standard-library types, Option
constructors, drop function and Drop trait so user declarations drop/Drop
cannot shadow them. Add both names to retained/current sharing fixtures.
No language semantics, target profile, public ABI or resource limit changes.
Full current-source qualification remains pending.

Preserve official Lean4.35.0, strict original/transformed IR and all prior
qualified sources/artifacts. G1/tools240s,checker120s,G2/G3 correctness1800s
and separate performance240s stay unchanged. No merge/publication.

## Preserved verified unified compiler milestone

Draft [PR178](https://github.com/dwijayuda/pskernel/pull/178), branch
feat/psc1-unified-selfhost-20261024, preserves PR177/base7cf50ecda689a3771bee0d91086ab43563a5c4d3.
One 120-module portable composition root reuses the existing frontend,
elaborator, checked pipeline and JS/TS/Rust/Wasm emitters. Execution engine and
output target are independent. Python/PHP stay outside that source closure,
with existing matching optional native packages. Native Wasm component and
all prior seven-backend functionality remain.

Current structured-v2 implementation325b130ada3eaa8962765bf6616e1db1cfc52425,
control `658df6d9e9bada4e11e369ab6d0e73d0dab74d4c`,
request `783cf8fceeda094b3e49b166e4d10af05e4b0413`.
Closurea3350d645a81ed17f69af59333978c60e3b8f9e1d6855a999e0bc5844e183990;
root `688ffd1dfdfdc7500a97772291977e36bb763da7520228db3b77f59f5793a313`.

- [40117051185](https://github.com/dwijayuda/pskernel/actions/runs/40117051185)
  PASSED actual G1 execution under all four engines: Rust 120940502844,
  TS 120940502851,Wasm 120940502852,JS 120940502886. Both grammar source audits,
  independent official admission, strict IR,160 cross-target cases and36
  envelope/optional-target refusals pass. Native compiler executables are
  removed after each sole seed call. **Current v2 G2/G3/fixed points are not run.**
- [Immutable readback40117873559](https://github.com/dwijayuda/pskernel/actions/runs/40117873559)/
  job `120942876835` PASSED nine exact archived records, captured source SHA256/
  closure digests, generated manifest/executable hashes and current four-engine
  originalIR/canonical-admission equality. Artifact `12569656720`,
  sha256:76e237d0d166ed4f3991fe7fea7676e048c89a3895fbb3bc0711e5fc089c05f3.
- Earlier string-envelope v1 source `b2ab4d340ddc85fbad6cc7ed47fb3a1c22ce11ac`
  genuinely qualified **JS and TS unified G1→G2→G3** in40113918732:
  JS 120931150386 G2/G3 1112514/1096375 ms;TS 120931150136925482/1009493ms.
  Both pass exact executable/source/admission/IR and four-target observations
  through all three generations (120 cases+27 envelope refusals per engine).
  The overall matrix failed for Rust/Wasm; individual JS/TS successes remain
  qualified on that exact source and are not inherited by changed v2.
- V1 Wasm G2 deadline1800101ms, noG3/fixedpoint. Initial Rust G1 target build
  exceeds240s at optimization 1. Archived15.2MB source diagnostic40114865357
  measures optimization 0/256 units51719ms;optimization 1/256240010ms failure.
  New unified Rust correctness uses0/256 only, stable Cargo path and exact
  verified inputs; historical single-emitter optimization 1 is unchanged.
  Retry0cf66b05/run `40115403218`/job `120935640656` passes G1/all 49 tests, then
  G2 stack-overflows after1179495ms. Exact stack site remains undiagnosed.
- V2 removes the whole-request escaped JSON string and directly decodes a
  structured inner request array through existing production APIs. No claim
  is made that it resolves long Rust/Wasm workloads until v2 G2/G3 executes.
- Long qualifications require validated request-only commits; G1-only mode is
  available. Normal full CI additionally requires native unified dispatch/
  refusal tests. All retained regression tests and qualification profiles remain.

Full [40117055147](https://github.com/dwijayuda/pskernel/actions/runs/40117055147)
PASSED: Linux `120943685823`/final gate120948016037;37/37 finite criteria,
0 blocked,releaseReady=true. All seven backends/both grammars, practical
applications, typed IO, minimum Python, optional-provider and installed-package
regressions pass. Review `783cf8fceeda094b3e49b166e4d10af05e4b0413` and tested
merge `b816df5d8082d2e805e99684e7ce2a2cc7224a54` have identical Git tree
cfc8b5304f943945d1a52bc9de2047fb4ad4b928. Artifact `12570094990`,
sha256:b16c12f209ae899aa74e74117c0e4bd7cf6868188400d37e34f280649178d6df.
The normal full gate executes the unified native dispatch/refusal tests.
All three matching native tarballs are retained: core SHA256
61460e75952c1a8125c0aebab6639837b141832fa751f658a2a7093514086ff6,
Python `f100acd470c266075d577dd1bdeb73eb62d1c38158f81cba806d79052f0dacbc`,
PHP `7e0301cd9f44ce2abca7d929cd013e5d45a1ded2c0bccc784400829b439c8ab2`.
Use matching builds; exact source/descriptor pins intentionally reject mixing.


This is a verified unified-service/G1 milestone with preserved older JS/TS
full-chain qualification. The existing proofscript@0.1.0-psc1.3 npm build is
still the native distribution; generated CLI/assets/provider/component
integration and current-v2 full self-host qualification remain pending.
No merge/publication. Stop as requested; no active qualification requests remain.

[Exact receipt](docs/PSC1_UNIFIED_SELFHOST_QUALIFICATION_2026-10-25.json),
[service guide](docs/PSC1_UNIFIED_COMPILER_SERVICE.md),
[roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) and
[executable continuation](docs/PSC1_UNIFIED_SELFHOST_CONTINUATION.md) own this
checkpoint. Preserve official Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
strict original/transformed IR, independent admission/source pairing/negative
tests and all memory/stack/fuel/security policies. G1/tools240s,checker120s,
G2/G3 correctness 1800s and performance240s stay separate; historical
Python/PHP3600s remains unchanged.

## Preserved earlier checkpoints (historical snapshots)

The following sections preserve prior evidence and then-current instructions.
Current status and the canonical receipts above govern continuation.

## Verified backend provider/package milestone — stopped as requested

**The requested milestone is complete. Stop after this checkpoint.** Implementation commits8c61a9c5,abd95b94,971718f5; required-CI review `70522c25ea3826c05ba2e80f7f1e9c7df0b58213`. Base17cc49f90318abc358c731601311b90b8f8ea9fb/PR176 remains preserved. Draft [PR177](https://github.com/dwijayuda/pskernel/pull/177), branch feat/psc1-backend-provider-packages-20261024. All writes expected-HEAD/non-force; GitHub/Linux Actions only. No merge/publication.

- Default unpublished proofscript@0.1.0-psc1.3 includes JS,TypeScript,Rust,Wasm core and Wasm component. Python/PHP are explicit matching @proofscript/backend-python and @proofscript/backend-php add-ons; neither is a default dependency.
- Core retains source capture, frontend/elaboration, independent official Lean admission, strict original/transformed IR, closed specialization, public ABI policy, target tooling, provenance and atomic publication. Separate workers revalidate IR/ABI and emit candidates only. Exact complete provider descriptors/native bytes/runtime resources are pinned by the core distribution; a rewritten provider manifest cannot authorize a replacement binary.
- Focused [40105565252](https://github.com/dwijayuda/pskernel/actions/runs/40105565252) at971718f5 PASSED source `120906418234`/package120906661489. Core symbol inventory excludes optional emitters; workers exclude PSC1 frontend/admission/publication/other emitter. Exact retained payload/IR comparisons,16 malformed identity/IR refusals,8 receipt refusals, actual both-grammar optional executions and missing-provider output preservation pass. Artifacts12564079454/12564308767 and exact digests are in the receipt.
- Offline installed core executes10 default grammar/target cases; both add-ons install independently and execute4 grammar/target cases.26 missing/pin/source/target/schema/binary/resource/self-authorized-hash cases preserve previous output. Strict independent TypeScript checking, native Rust, core Wasm and component execution pass. Existing local/global core, source-library, installed typed IO and runtime-resource canaries remain. Dedicated first package attempt40105154897 failed TypeScript7 TS5112; --ignoreConfig corrected explicit-file invocation with strict checks intact.
- Full [40106542849](https://github.com/dwijayuda/pskernel/actions/runs/40106542849) PASSED: Linux `120912148533`/final gate120918578150;37/37 criteria,0 blocked,releaseReady=true; all seven backends/both grammars, applications, minimum-Python and installed package/IO/library checks. Review `70522c25ea3826c05ba2e80f7f1e9c7df0b58213` and tested merge `063d1da64db9beb69a8303af5a2a8788233dc7dd` have identical Git treeb2d2ad3e24a07218c081eb20bc85670fd64e29e4. Artifact `12566181617`,sha256:be0a4ed3850383345acfbf2127d34caa32154ed6c5f8ac10304edd3d54899957.
- Normal full CI now requires the provider transport/dependency/refusal gate and exact-commit receipt. The package builder retains all three matching installable tarballs in the full artifact. Core SHA2566c06085e60ffde19c7418bf265e27b4ebc9a244572a388564beb8b1c0fdcab28; Python `7c9d2cbeb47dcdd2c680c5981cc1458ff59fb590c48ed1f0f96f243c4c2fbc07`; PHP `ea756a91fb6ccb1d8aaa7409f82b7b3c2ace8da22a94f59027ecb96b06e7c8d4`. Use all three from the same artifact; exact source/build pins intentionally reject mixed builds.

This qualifies the native Linux x64/glibc distribution/provider boundary, not a new unified generated compiler, cross-platform release, unrestricted compiler plugin system or formal backend-preservation theorem. Portable compiler sources/semantics and all source-library authority restrictions are unchanged. Preserve official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc, strictIR/source pairing/negative tests and all resource policies. Provider requests/responses64MiB,identity10s,emission120s; self-host G1/tools240s,checker120s,performance240s,historical1800s/3600s profiles remain separate and unchanged.

Prior Python/PHP retry40091210960 is terminal G2 deadline failure for both, no G3/fixed point: Python3600050ms/tree781728KiB,PHP3600059ms/tree1183780KiB. Actual failed artifacts and service/request/source-closure identities remain in this receipt. Do not replay these failures for packaging. Older Rust/TS/JS/Wasm qualifications remain pinned to their exact historical sources.

[Finite contract](BACKEND_PROVIDER_CONTRACT.json), [provider guide](docs/PSC1_BACKEND_PROVIDERS.md), [exact receipt](docs/PSC1_BACKEND_PROVIDER_QUALIFICATION_2026-10-24.json), [roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) and [continuation](docs/PSC1_BACKEND_PROVIDER_CONTINUATION.md) govern this checkpoint. Next only on authorization: unified generated multi-backend composition root and genuine enlarged-source qualification per claimed engine.

## Historical Python/PHP performance-fix checkpoint

Use connected GitHub tools/Linux Actions only, fresh expected-HEAD non-force updates, draft [PR176](https://github.com/dwijayuda/pskernel/pull/176). No merge or package publication authorized.

**This bounded milestone is complete; stop after this checkpoint.** The latest user instruction is “continue until milestone slice and then stop.” Source fixes and regression validation are complete; long compiler-generation results remain pending.

- Python b56da50567ac4051b6bea311c1b960ced1c97869: the two hot immutable UTF8 identity entries return without allocation/promotion. The8entry/32MiB budget, errors, eviction and oversized-input policy remain.
- PHP `13c5d4a60f4fd55dfe6667eca7406b5c5474aa8d`: canonical checked node reads use externally readonly public private(set) slots. ArrayAccess, indexed differential control, native legacy layout and iterative dead-node reclamation remain. Proven two-layer nonzero pure globals bypass redundant scheduled requests after identical callee/argument snapshots; dynamic calls, recursion, shadows and aliases retain scheduling.
- Review `b33027de36225e0a4f6d0f86572bd42115aad42a` corrects only a Lean reference comment delimiter after failed preflight40090723561. Production semantics are unchanged by that correction.
- Focused [40090956726](https://github.com/dwijayuda/pskernel/actions/runs/40090956726)/job120863330756 PASS:234895 UTF8 queries and20000 allocation-free alternating hits;11 canonical slot token restorations with every other token/runtime prefix exact; readonly mutation/reference refusals, frozen node-interface comparisons,2M dead-spine/collection tests, one static-call token restoration,200k dynamic alias/shadow recursion; all retained supervisor/transport/runtime/admitted-library guards and both87-module closures in both grammars. Artifact `12559320936`,sha256:1b585020c54677b28b70905317d16c027d9ded1d8a71376d264b0947614506d1.
- Full [40090959568](https://github.com/dwijayuda/pskernel/actions/runs/40090959568) PASSED: Linux `120865715808`, final gate120870365297;37/37 criteria,0 blocked, releaseReady=true. All seven backends, both grammars, practical applications, minimum-Python and installed native package/IO/library regressions. Review `b33027de` and tested merge `2867dadec3ed7e05fbc86c5cffafcc6bf8b8e292` share Git treef4d8a31f19e1574ba91348bc79e1c50aa76ee1ef. Qualification artifact `12559464310`,sha256:a71c38b06de7b8a8d2e378aae640bb075a3fdcb2b6fb8f268c2c5eb865a63942.
- One genuine BOTH-target correctness-3600s retry is running on qualification/psc1-python-php-3600s-20261024: control3a78709e01e0ca1dd0be2ed4f17b3e4b7170faf0, request336ff212bb810bcafa1573350355fbd1f6a0509e, [run `40091210960`](https://github.com/dwijayuda/pskernel/actions/runs/40091210960), Python `120864185036`/PHP `120864185108`. Compiler and critical host tools exactly matchb33027de; GitHub compare shows only workflow branch guard and request JSON differ. Both jobs entered genuine generation execution; no new G2/G3/fixed-point success is claimed. Preserve these running jobs.
- Earlier3600s run `40085445958` at requesta6a399c6 FAILED both G2 deadlines after both G1s passed independent admission/strict IR/all ten observations. Python3600060ms/tree peak781180KiB; PHP3600056ms/tree1180260KiB. Neither G3/fixed point ran. Immutable artifacts12558152936/12558950449 and readbacks40089881019/40089760678 remain in the exact receipt. Last inner CPU samples~3543s show busy workloads, not semantic progress; outer wait4 RSS is not interpreter peak and tree sums may double-count shared pages.

Correctness3600s extends ONLY exact G2-self/G3-self wall clocks. Preserve G1/corpus/tools240s,checker120s,historical correctness1800s,separate performance240s,official independent Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc, strict original/transformed IR/source pairing/negative tests,response128MiB,PHP1G/default stack,Python recursion/digit globals and semantic fuel. Jobs180min/execution170min fit hosted6h. No new compiler implementation or verification bypass.

**Next only on continuation:** fetch latest primary and qualification HEAD, then inspect run `40091210960` completed jobs/artifacts. Do not submit a duplicate request or cancel live work. Require genuine independent G1→G2→G3 and exact source/admission/IR/observation/raw-byte fixed points per target before calling it self-hosted. On failure diagnose the actual new workload; on success perform clean independent G1 reproduction. Performance240s remains separately unqualified. [Exact receipt](docs/PSC1_PYTHON_PHP_SELFHOST_QUALIFICATION_2026-10-24.json), [roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md), [executable continuation](docs/PSC1_PYTHON_PHP_SELFHOST_CONTINUATION.md).

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

Focused 40061782715/job120776657312 PASSED at source `133e5892`:
- Eleven all-input full JS API equalities against retained originals, covering
  decimal/type/expr lowering, validation, tail aliases/captures and printing.
  Move recursive prefixes beneath every dynamic input; scan233 owned definitions,
  reject all eleven original defects, test million-fuel early results/refusals.
- Three complete Wasm encoder API equalities: Except flatMap, byte chunks and
  UTF8 characters use fully applied reverse accumulators, preserving bytes,
  order and first-error priority, including100000-element cases.
- Three shared environment/constructor/recursor lookup equalities and100000
  early/missing/kind/duplicate-payload cases, source `146270cf`.
- All earlier52 Wasm prefix, six foundation and checked/erasure collector/index
  equalities; original fuel, errors, insertion/index and source/logical pairing.
- All retained JS lazy UTF8 views, capture/alias/fuel,10584 view comparisons,
  64 direct-dispatch order/trap tests, native/reference comparisons.
- Owned import-free GC Wasm transport,96-opcode/Unicode/Nat/Int cases and
  complete87/98-module Lean/PS source censuses. No verification or limit changes.

Earlier failures remain immutable in the receipt. In particular the older
shared-lookup-only JS baseline d7c6f166/run `40061402443` FAILED its G2 deadline:
1800233ms /3107644KiB, no G3/fixed point. It lacks the eleven later JS fixes.
Earlier Wasm stack traces reached encoder flatMap; the top Nat division frame
did not establish an arithmetic defect. Fix the demonstrated source class,
rather than raising stack/fuel or replacing the compiler architecture.

## Full Practical Core and review

[Full40062210987](https://github.com/dwijayuda/pskernel/actions/runs/40062210987)
PASSED: Linux `120780825013` and final gate120786364196;37/37 qualified,0 blocked,
releaseReady=true, all seven backends, both grammars, applications, minimum
Python and installed native package/IO/library regressions. Tested review HEAD
06186537cf9339fc3f24a7d13387c2ad55ee0749 and merge
980d096ca3e85b9ad2970f16602ad1d14a089d69 have identical Git tree
cbf312e1f4bca9e7085719c12b627be5c16099a7, verified through GitHub APIs and checkout log.
Artifact `12549325904`, digest
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
G1/corpus/tools240s, checker120s, historical G2/G3 correctness1800s and explicit Python/PHP correctness3600s, semantic fuel and
all memory/stack/security/refusal limits remain unchanged.

Official independent Lean4.35.0 checker
eb6cafb7290e8bd5f2937522d8d804f58f02bafc, strict original/transformed IR and
negative tests remain mandatory. All targets share the existing compiler
service, frontend, elaborator and checked pipeline. Only emission/runtime
carriers differ; no alternate handwritten compiler or native delegation.

Preserve qualified Rust branch fix/psc1-rust-owned-string-moves-20261023,
head83e18fe183498f7d8b0fc3e3faa5bdacc41cb23d, source `5e0b548e`/run `39908529181`,
G2/G3692788/660042ms. Preserve TS perf/psc1-erasure-applied-workers-20261023,
head84e1e16f61cec3d28d9fdc62d6eaca4f3c0a8577, source `748fd5fd`,
request079b26b9/run `39993829327`, G2/G3545895/588552ms; full39993835819 passed37/37.
These qualify older snapshots, not a fresh Rust/TS replay of changed common source.

The completed DirectJS/Wasm checkpoint has no active requests; the Python/PHP
mission above owns current qualification. Deferred Direct-target queue:
profile the now-completing exact generated compiler workload, optimize one
measured generic bottleneck with retained-original API/negative proofs, then
rerun changed-source focused and genuine qualification. Keep original240s
performance acceptance explicit. Independent full-chain repeatability is a
separate future evidence scope. Do not repeat unchanged correctness chains for
documentation-only updates. See the [executable continuation](docs/PSC1_DIRECT_SELFHOST_CONTINUATION.md).
