# PSC1 AI work state

## Frozen Rust qualification completed; other engines next

Rust request2d27f142/run40141718481/job121014751809 PASSED genuine G1/G2/G3
and exact source/admission/original+transformed IR/raw-executable/four-output
fixed points on120-module closure
07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af.
G2=2139961ms,service maxRSS1197260KiB;G3=2160767ms,1197296KiB.
Both exceed the former1800s cap; correctness-3600s was required. Performance240s
remains unqualified. G1/corpus/build240s,checker120s and all other policies stay.
Artifact12580184355,ZIPc294caabf1d814c9302d3d6f95177b7af03533b9d6ed3d947d856e39ad6ee0c0.
Both qualified attempts and every historical failure remain preserved.

The next explicit request qualifies JS/TS/Wasm on this exact same source closure
using their unchanged correctness-1800s profile. It does not repeat Rust or inherit
older TS/Wasm/JS evidence. Current primary14cb3e30 changes package installation
metadata/global regressions, not the portable compiler source or qualification
tools. Do not modify this frozen source while those runs are active.
A separate proved lexer candidate remains unpromoted. Primary package/CLI work
and full correctness results are recorded in the primary AI_WORK_STATE.md.


## Earlier control snapshot

## Active measured-runtime candidate and longer Rust qualification

Updated2026-10-25 Asia/Jakarta. Current control8966261900c7d019553fcef5b04bc9e90593c901
builds on primary941d2730. Existing qualified JS/TS/Wasm records remain immutable;
no qualification is inherited by the changed source. Work is continuing.

The exact archived Rust G2 profile40138165186/job121004032945 samples the
original request at300/600/900/1200/1500s. It measures BigUint cloning/dropping
in StringEq, decimal Nat literal parsing in JSON/admission encoding and strict
IR validation. This is a diagnostic, not a successful G2 candidate. The
archived old executable reaches strict IR validation by1500s. Alternative
LLVM builds either exceed the existing240s build limit, fail LLVM's own
verification, or still exceed1800s in G2; none is promoted.

Candidate65bd033b/56fee6b6 emits exact u64-constructible Nat literals through
BigUint::from and retains arbitrary-precision decimal parsing above u64.
It borrows immutable local Nat operands only where existing helpers already
accept references, retaining snapshots for computed operands. Unified Rust's
main crate staysopt0/256; only pinned numeric dependencies useopt3. Public
Nat representation, shared algorithms, semantic fuel and ABI are unchanged.
Retained-emitter comparisons cover14 numeric boundaries through256bits,
Unicode/String cursor observations, aliasing and computed-operand order.

User authorized a sensible longer timeout. Separate correctness-3600s is
now accepted for Rust G2-self/G3-self only. Existing correctness-1800s and
performance-240s remain explicit profiles. G1, corpus and build tools240s,
independent checker120s, memory/stack/fuel limits and refusals remain unchanged.
The hour profile uses a190-minute hosted job and170-minute qualification step;
GitHub's six-hour hosted-job cap permits this. Generated wire cannot choose
limits: a closed-schema request-only commit and exact parent are required.
Request-policy tests retain invalid-profile/deadline/target/tool refusals.

Focused40141004793/job121012548777 PASSED at8966261900c7d019553fcef5b04bc9e90593c901:
14 exact literal boundaries,120 ownership observations, three million-character
Unicode scans, codec deep-spine proofs/regressions,707 Wasm divmod pairs, both
120-module grammar censuses and genuine Rust G1/all40 cross-target cases plus9
envelope refusals. Source closure07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af.
G1 executable07f58b1f083da6f0757fdffd4866ae16535d193065cf95d9c56443b5548636d6.
Artifact12578628638,ZIP939144dd681f77eaf2e8dfaca88c12044433ffd9770bd272210af59708e3d944.
The bounded180s G2 diagnostic is not qualification. Full G2/G3/fixed point and
240s performance remain PENDING. The next request uses correctness-3600s.

Primary941d2730 full40138996117 PASSED all selected gates,37/37 criteria,0blocked,
seven backends/both grammars, practical applications and native core/optional
packages. Tested merge7606d172 and941d share tree1c268d41d81ee35aa4182fe59b4b87cfc2421df6.
Full artifact12578274080,ZIPadf631066e56a6fb0617c8132ab14b9ec0ac506a6a125c8e990f9222e8bd04e4.
This full gate predates the Nat candidate and does not qualify its changed source.

Installed generated package control941d2730/run40138989081 passed26 host
boundary checks,10 corpus cases and12 refusal/tamper cases with native compiler
unavailable. Diagnostic72de82f6/run40139913145 additionally passed12 real
application builds/44 observations: JsonRecords.Transform and PracticalCli.Args
in both grammars under qualified historical TS/Wasm engines, including Unicode,
surrogate/duplicate/shape/arity refusals and single-file commands.
These use historical closure92654df5 and publish independently admitted JS;
all native targets and optional Python/PHP remain available. No all-four-engine
or current-source generated release claim. Registry publication/merge remain
unauthorized.

Immediate queue: complete preflight; issue exact Rust correctness-3600s request;
record genuine G2/G3 source/admission/IR/executable/observation fixed points;
promote only verified runtime changes and installed application/adapter tests;
require full seven-backend/native package gate; update immutable package pins;
then qualify one frozen shared source under every engine.


Updated 2026-10-25 Asia/Jakarta. GitHub/Linux Actions only; fresh expected-HEAD
non-force updates. No merge or npm publication authorized.

## Active continuation: measured Rust performance and generated packages

Continued from3364d255 on2026-10-25; previous stop instruction below is a
completed historical milestone. Current user authorization continues development.
No compiler source or qualified engine bytes are changed by this package slice.

Exact Rust G2 diagnostic control39011c8a/run40138165186 replays archived
f707e037 G1 executable91b12534 and request63662493, sampling300/600/900/1200/1500s.
It is diagnostic only, with the unchanged1800s outer policy.
Build experiments40138326355/40138435314 retain failed opt1/no-LLVM240s and
LLVM instcombine fixed-point-verification failures. Verification is not bypassed.
A promotion-only opt0 experiment follows; none is promoted to production yet.

Generated package integration is implemented but CI PENDING: explicit
psc generated build dispatch uses immutable qualified historical TS/Wasm G3
engines on shared closure92654df5, existing official Lean4.35 host session,
exact imported-file pins and atomic publication. Initial generated publication
target is JS; all five native core targets and optional Python/PHP remain.
The wrapper retains the native CLI. It must work with native compiler removed,
both grammars, retained corpus/refusals and tampered imported-engine refusal.
This does not qualify current closuree0f7640b or an all-four-engine release.
New workflowpsc1-generated-package-integration.yml verifies immutable ZIPs,
packs an unpublished candidate and tests actual offline npm installation.
No npm registry publication or merge is authorized.

## Verified codec-frame milestone

Code checkpoint `5d4d4d1a1693de57fa16ecf796536d73040bbf64`/draft PR178;
120-module closure `e0f7640b77ee9eaa17e946c628de23f320f2943dc181ac6063a35c81ccb7ca66`.
[Full CI40133272707](https://github.com/dwijayuda/pskernel/actions/runs/40133272707)
PASSED37/37 finite Practical Core criteria. Rust G1 passes, but the genuine
G2 retry reaches its unchanged1800s deadline without an observed stack
overflow. No G2 candidate, G3 or fixed point exists for this snapshot.
Stop at this verified stack-correction milestone; Rust self-host correctness
and performance remain unqualified. Exact evidence:
[codec receipt](docs/PSC1_UNIFIED_V2_CODEC_QUALIFICATION_2026-10-25.json).

The existing checked expression encoder now represents application, binder,
let-body and projection return paths as explicit frames and unwinds them by
direct tail calls. Side branches remain structurally recursive. It preserves
the exact original opaque String.Internal.append tree and error priority,
without a new fuel cutoff or increased stack/heap/time allowance.
CodecSpineReference retains the previous production source. codec_spine_acc_eq
and codec_spine_eq prove equality for every expression/frame stack; the
existing static-schema theorem remains unconditional. Pinned Lean reports
only standard propext/Quot.sound dependencies, no sorryAx or added axioms.

Focused40133269028/job120989348408 PASSED:44 old/current observations;
ten10000-deep expression shapes plus a10000-declaration admission fold
(12825ms,maxRSS34760KiB), both120-module grammar censuses and actual enlarged
Rust G1/all40 cross-target cases plus9 envelope refusals. Artifact12576126918,
ZIP09357b2b1c6ab48d1e9b8a7e3327544072cb0d333c7321def06c4e13871ee9fc.
The180s GDB sample is diagnostic only, not full G2 qualification.

Rust String reader forwarding and ordered last-use moves avoid repeated
whole-input copies; private recursive carriers with an empty constructor
reclaim final Rc owners through a non-reentrant queue. Public enum layouts/
owned field moves remain unchanged. Scalar-only selected modules omit unused
private prelude templates after a conservative carrier-use scan, preserving
the existing runtime-free Boolean regression. Unknown/generic/named types,
carrier operations and scan exhaustion retain the carrier path.

Wasm Nat divmod factors even divisors, handles divisor one and checks a zero
dividend first; each new recursive division step halves the dividend. The
old odd-divisor and division-by-zero paths remain. Differential actual Wasm
execution covers707 pairs/2828 results through513-bit inputs and20001-bit
divisors. All source, theorem, runtime, ownership, aliasing and namespace
regressions remain required in normal full/manual qualification workflows.

Preserve qualified structured-v2 TS and Wasm request812094c1/run40126488125,
closure92654df5c0a58fafd3ec9b9b045304706c5992c3eaa34de6b4aadab39a7e00c2.
Both execute G1/G2/G3 and exact source/admission/IR/raw-executable/four-output
fixed points: TS G2/G3=1379563/1401815ms;Wasm=1396916/1410393ms.
Immutable readback40130870206/job120982103024 verifies inventories, bytes,
IR/admission parity and all failed records. Its same-source Rust overflow and
JS1800278ms G2 deadline remain failures. Earlier v2 Wasm9359f073, v1 JS/TSb2ab4d34
and historical single-emitter successes remain pinned to their own source.
Do not inherit their qualifications onto this changed closure.

Full CI job120991938920 and final gate120997291745 pass all seven backends,
both grammars, real applications, typed IO, minimum Python, exact-build optional
providers and installed native core/source-library regressions. Review5d4d4d1a
and tested CI merge764078561a0b4a09dd7cccd1fac4174f566bf4c4 have identical tree
47b683bb30905531799e7e3717450e1644762c8f. Artifact12576144430,
ZIPfae7c60ccea2162d46a65b547d935f11216c5bfab3d2f5eb1aba4b620bb1ee7c.

Latest Rust requestf707e037b5f470ceee65891e0c735316ba097444 on
qualification/psc1-codec-tail-workers-20261025, control
d8a5ffa168f2744b5897420ecded84ef72475bda, reproduces the exact non-.github source
tree dfec32f502a08d8f56c2014707087c73ca563f1f from5d4d4d1a.
Run40133622389/job120990512358 passes G1/all49 tests, then G2 is hard-killed at
1800055ms. Sampled process-tree peak924096KiB; sampled CPU1889.15s includes
supervisors. The outer waited child's maxRSS103732KiB is not service peak RSS;
service-specific completed maxRSS is unavailable after the hard kill.
Producer manifesta3c309d25cf5bb855b1eb80b3a3ce07ad7c7e5bcfac287283fadb56dc6665005,
raw G1 executable91b12534f04b80c8ee4be93f0cca6d6a915a8c44b6087f62db28a677e7620d42,
G2 request636624936f655a0412cf5ce0f31df9436bc9f311e63aee25d808f009a76f4118.
Artifact12576967932,ZIP0f8f31d00fdb3def362dbcd979fd82649864ca90ca44d4a1be3a96a8cacb5bf8.
No native fallback, G2 candidate, G3, fixed point, or240s qualification.
Immutable readback40136555747/job120999195540 PASSED: exact inventory,
admission/IR/raw-executable verification and same-source independent G1
reproduction. This is not a clean full replay or a G2/G3 qualification.
Readback artifact12576759844,
ZIPae0106604fc1cc70be2ccf0c1ff8ced6033b3f37b4415a131bbcda7d9dc34e73.

## Dependency-ordered continuation queue

1. Profile the exact archived Rust G1/G2 request late in its1800s workload.
   Resource heartbeats do not identify the hot function. Use Linux CI only,
   verify the producer/request hashes above, sample later phases, and preserve
   the same stack/heap/fuel/deadline policy. This is the immediate release blocker.
2. Optimize only the measured generic cost with exact semantic regressions,
   both source grammars and independent checking; retry real Rust G2/G3 and
   exact source/admission/IR/raw-executable/four-output fixed points.
3. Freeze a shared root and qualify all four engines on that exact closure.
   TS/Wasm success on92654df5 and v1 JS/TS success remain historical, not new-root
   qualifications. Keep the JS1800s failure tracked.
4. Integrate generated assets/CLI, host admission/publication, component adapters
   and optional-provider dispatch. Current npm artifacts remain native-lean;
   Python/PHP remain optional and all seven native target mappings remain.
5. Clean independent full reproduction, release qualification and optimization
   toward the separate240s profile. No merge/npm publication without authorization.

Official independent Lean4.35.0 remains pinned to
eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Strict original/transformed IR,
source/logical pairing, negative tests, semantic fuel and all resource policies
remain. G1/corpus/tools240s; checker120s; G2/G3 correctness1800s; separate
performance240s; historical optional Python/PHP3600s. Longer correctness
success never qualifies the240s performance target.

## Source-diagnosis history for this milestone

- Original structured-v2 Rust/Wasm request9359f073/run40120346573: Wasm genuinely
  passes G1/G2/G3 and exact fixed point on closurea3350d64; Rust G2 overflows
  after648336ms. Retain both individual results despite the failed matrix.
- Archived-input profile40120526852: Rust spends early samples copying whole
  Strings in JSON character decoding. Exact Wasm function mapper40121535934
  verifies8343 indices and locates Nat runtime arithmetic. These are scoped
  diagnoses, not qualifications.
- Source8b61aea4/run40123048722 traces recursive List<Char> destruction after
 8563ms. Iterative private carrier reclamation and ordered String moves fix
  that earlier site; million-character and million-node regressions execute.
- Source0c75e855 restores the crucial dividend-halving resource bound; a3d3e0a9
  fully qualifies generated cleanup std paths against source names Drop/drop.
- Request812094c1/run40126488125: Rust G1 passes, G2 aborts after520538ms.
  Exact archived-G1 replay40128155977 verifies producer/request identities
  and records90 repeated psEncodeCodecExpr frames after517774ms.
- ca938791 initially tests text-chunk reassociation; the Lean proof correctly
  rejects opaque-append associativity.854b15ef replaces it with exact return
  frames. No new axiom or weakened theorem is introduced.
- dbc5069e removes unused private carriers from scalar-only selected output
  after full40126174119 exposed the unchanged runtime-free assertion.
  Request6963af8d/run40130336112 stops in source census before G1/G2;
  e913a6d3 fully applies the recursive visitor under lambdas in both grammars.
  The invalid attempt is retained, not counted as compiler execution.

- e98ea691/04771b2b/run40132435573 passes G1 but overflows after638133ms;
  its exact stack site is not traced. Preserve the failed comparison snapshot.
- b36632a3/5d4d4d1a fully apply the admission fold and reversal, retaining
  originals and all-state/list proofs. The final actual request reaches1800s
  without an observed overflow; the remaining blocker is a measured deadline,
  with its hot function still unprofiled.

## Historical initial unified compiler milestone

This is an archived earlier checkpoint; the current status and queue above govern.

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

The earlier full gate40126174119 fails its existing runtime-free Boolean
assertion: unused private prelude List templates gained a cleanup helper.
Keep that assertion unchanged. A conservative carrier-use scan now omits
all unused type templates only when selected declarations contain no carrier
types/operations and no types are public. Unknown/polymorphic types, named
types, constructor/record/match/projection operations and scan exhaustion
retain the existing carrier path. Focused and final gates must validate it.
