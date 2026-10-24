# PSC1 development roadmap

## Active runtime and distribution queue

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


Updated 2026-10-25 Asia/Jakarta. Frozen Practical Core v1 remains14 families/
37 finite acceptance criteria. [AI state](../AI_WORK_STATE.md) owns continuation;
[codec qualification receipt](PSC1_UNIFIED_V2_CODEC_QUALIFICATION_2026-10-25.json)
owns exact code, source, CI, artifact and failed-attempt identities.

## Verified codec/admission stack milestone

Code checkpoint `5d4d4d1a1693de57fa16ecf796536d73040bbf64`/draft PR178;
120-module closure `e0f7640b77ee9eaa17e946c628de23f320f2943dc181ac6063a35c81ccb7ca66`.
[Full CI40133272707](https://github.com/dwijayuda/pskernel/actions/runs/40133272707)
PASSED37/37 finite Practical Core criteria. Rust G1 passes, but the genuine
G2 retry reaches its unchanged1800s deadline without an observed stack
overflow. No G2 candidate, G3 or fixed point exists for this snapshot.
Stop at this verified stack-correction milestone; Rust self-host correctness
and performance remain unqualified. Exact evidence:
[codec receipt](PSC1_UNIFIED_V2_CODEC_QUALIFICATION_2026-10-25.json).

Focused40133269028/job120989348408 PASSED:44 old/current observations;
ten10000-deep expression shapes plus a10000-declaration admission fold
(12825ms,maxRSS34760KiB), both120-module grammar censuses and actual enlarged
Rust G1/all40 cross-target cases plus9 envelope refusals. Artifact12576126918,
ZIP09357b2b1c6ab48d1e9b8a7e3327544072cb0d333c7321def06c4e13871ee9fc.
The180s GDB sample is diagnostic only, not full G2 qualification.

The implementation uses explicit expression return frames, a structural
comparison of application axes, and fully applied admission/reversal workers.
It preserves the exact opaque append tree, all-state height/order/refusal
semantics, original APIs and unconditional Lean equality proofs. Standard
propext/Quot.sound only; no new axiom or resource allowance.

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

Practical Core readiness is37/37 with0 blocked for the finite native release
contract. Generated distribution readiness is false: current-root Rust G2/G3,
all-engine frozen-root qualification and integration remain unfinished.

## Single dependency-ordered remaining queue

| Order | Work | Evidence/status |
| --- | --- | --- |
| 1 | Measured Rust G2 performance | BLOCKED at1800055ms on closuree0f7640b; no observed stack overflow or candidate. Profile exact archived input/executable late in the workload before choosing an optimization. |
| 2 | Rust G2/G3 and exact fixed point | PENDING: optimize the demonstrated generic cost; actual independent admission, strict IR, all120 cross-target cases/27 refusals and raw bytes required. Preserve240s as a separate target. |
| 3 | One frozen four-engine source | PENDING: TS/Wasm qualify92654df5; earlier JS/TS qualifyv1b2ab4d34. These do not qualifye0f7640b. JS92654df5 reaches its1800s G2 deadline. |
| 4 | Generated distribution integration | PENDING: assets/CLI, component adaptation, independent host admission/publication and optional-provider dispatch. Current installed core/Python/PHP packages are native and exact-build pinned. |
| 5 | Clean independent reproduction and release | PENDING: actual clean full replay, final release qualification and240s performance. Merge/npm publication require authorization. |
| 6 | Broader extensions/readability tools | DEFERRED: preserve finite Practical Core scope and existing working features. |

Official Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc, strict original/
transformed IR, source pairing, negative tests and all memory/stack/fuel/security
policies remain. G1/corpus/tools240s,checker120s,G2/G3 correctness1800s;
historical Python/PHP3600s remain unchanged.
Long chains require explicit request-only commits; ordinary edits do not launch
them. After a successful gate, documentation/receipt-only updates use the
existing dependency selector while carrying any failed/cancelled code debt.
See the [service guide](PSC1_UNIFIED_COMPILER_SERVICE.md) and
[executable continuation](PSC1_UNIFIED_SELFHOST_CONTINUATION.md).

## Preserved historical queues

The following are prior checkpoint snapshots. The queue above governs current
work; canonical receipts retain each exact qualified or failed source.

## Historical Python/PHP milestone queue



The user requested a stop after the verified milestone slice. This slice is complete; no further source work is authorized in this turn. Preserve active long qualification jobs.

| Order | Work | Finite acceptance and current evidence |
| --- | --- | --- |
| 1 | Measured backend fixes and regression | COMPLETE: Python `b56da505`/PHP `13c5d4a6`, review `b33027de`. Focused40090956726 PASS retained/runtime/token/readonly/deep tests and87 modules per target in both grammars. Full [40090959568](https://github.com/dwijayuda/pskernel/actions/runs/40090959568) PASSED: Linux `120865715808`, final gate120870365297;37/37 criteria,0 blocked, releaseReady=true. All seven backends, both grammars, practical applications, minimum-Python and installed native package/IO/library regressions. Review `b33027de` and tested merge `2867dadec3ed7e05fbc86c5cffafcc6bf8b8e292` share Git treef4d8a31f19e1574ba91348bc79e1c50aa76ee1ef. Qualification artifact `12559464310`,sha256:a71c38b06de7b8a8d2e378aae640bb075a3fdcb2b6fb8f268c2c5eb865a63942. |
| 2 | Genuine current-source generations | RUNNING, NOT QUALIFIED: request `336ff212`/run `40091210960`, Python `120864185036`/PHP `120864185108`. Exact compiler/tools snapshot ofb330; only guard/request differ. No duplicate request while active. |
| 3 | Qualification result reconciliation | On continuation, fetch terminal jobs and immutable artifacts; record exact identities, elapsed/CPU/peak metrics and actual admission/IR/ten-case/raw-byte fixed points. First3600s run `40085445958` remains an immutable two-target G2 deadline failure after G1 success. |
| 4 | Targeted follow-up or clean reproduction | If new attempt fails, fix a demonstrated generic cost with all retained guards before another chain. If it passes, clean fresh G1 without lake cache reproduces every qualified generation. Full source/regression gates alone never qualify G2/G3. |
| 5 | Performance and review | Original240s profile remains separately unqualified. Preserve qualified Rust/TS/JS/Wasm snapshots. Merge/publication require authorization and required qualification. |

Correctness3600s extends ONLY G2-self/G3-self. Preserve G1/tools/corpus240s,checker120s,historical1800s,performance240s,independent Lean4.35,strictIR,source pairing,negative/security tests,memory/stack/fuel and unsupported-ABI refusals. One shared compiler and one portable emitter per target.

The [AI state](../AI_WORK_STATE.md), [exact receipt](PSC1_PYTHON_PHP_SELFHOST_QUALIFICATION_2026-10-24.json) and [continuation](PSC1_PYTHON_PHP_SELFHOST_CONTINUATION.md) bind this queue to actual commits and results. Direct-target optimization remains deferred.

## Qualified compiler checkpoint

Source133e589288b563e74578b771ec35595beb3a9fe8, request `2d1f8244`,
[Linux `40062120079`](https://github.com/dwijayuda/pskernel/actions/runs/40062120079):
DirectJS and owned import-free DirectWasm independently PASS genuine G1→G2→G3
and exact source/admission/IR/ten-case/target-byte fixed points.
JS G2/G3:824066/832426ms; Wasm:876840/888398ms, within correctness1800s.
[Clean audit40064496804](https://github.com/dwijayuda/pskernel/actions/runs/40064496804)
also PASS: no restored .lake cache, fresh G1 reproduces exact source/admission/IR,
ten observations and source/executable bytes of each qualified G1/G2/G3.
A second clean full G2/G3 replay and a formal compiler-preservation/DDC proof are
separate claims and were not performed.

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

Preserve all working seven-backend functionality, both .lean/.ps grammars,
four real application categories, typed IO, bounded inference/control, checked
Nat/Int ordering, CLI/JSON processing, multi-module libraries and compiler-like
acceptance. No new feature families are added to frozen v1. Kernel research
continues independently and does not gate compiler development.

## Dependency-ordered remaining queue

| Order | Work | Finite acceptance and status |
| --- | --- | --- |
| 1 | Profile completed actual generated workloads toward original240s. | Pending performance work. Retain exact qualified artifacts/requests; sample complete phases and report elapsed/maxRSS separately from sampling overhead. Different target closures are not a matched backend comparison. |
| 2 | Fix the largest demonstrated generic cost. | Pending measurement. Small dependency-coherent source/runtime changes; retained-original all-input equality where applicable, refusal/fuel/order/capture guards, both grammars, focused generated runtime tests. Avoid speculative architecture replacement or alternate handwritten compilers. |
| 3 | Requalify changed source and evaluate performance independently. | Existing correctness1800s qualified for both direct targets; current times exceed240s, so performance240s remains unqualified. Source changes require genuine current-source G1/G2/G3/fixed points and seven-backend regressions; documentation edits do not. |
| 4 | Extend independent repeatability if a release requires it. | Clean G1 reproduction already passed for both; independent full-chain replay is not run. Reuse diagnostic/psc1-direct-clean-g1-20261024 at36d917b0; keep the narrower evidence boundary explicit. |
| 5 | Release review and publication. | Requires authorization and required final qualification. PR175 remains draft/unmerged; npm publication not authorized. |

The older direct-target checkpoint has no active runs; Python/PHP mission status above supersedes it.
Use the [architecture](PSC1_COMPILER_SELFHOST_ARCHITECTURE.md) for measured
mechanisms and [continuation](PSC1_DIRECT_SELFHOST_CONTINUATION.md) for executable
GitHub-only steps. Preserve exact older Rust/TS qualifications: Rust83e18fe1,
source `5e0b548e`/run `39908529181`; TS84e1e16f, source `748fd5fd`/run `39993829327`.
Do not label these as requalified after later common-source changes.

## Evidence and correctness policy

Official Lean 4.35.0 independent checker at eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
strict original/transformed IR, source/logical graph pairing, negative/refusal
tests and all resource/security/fuel limits remain mandatory.
G1/corpus/tools240s and checker120s remain unchanged. Python/PHP may explicitly
request correctnessG2/G33600s; historical1800s and performance240s stay separate.
Performance240s remains a separate test; longer correctness cannot qualify it.

Earlier failures and completed planning milestones are preserved in Git history
and the canonical receipt. They explain the diagnosed defect classes, rather
than constituting live blockers: eager unused recursive prefixes, ordered list
reconstruction and encoder spines, generator/GC allocation, and UTF8 cache-key
cost. The final fixes were qualified by actual generated compiler executions,
not source census or small fixtures alone.
