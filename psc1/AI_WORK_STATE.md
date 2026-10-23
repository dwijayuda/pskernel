# PSC1 active work state

Updated2026-10-23. Draft [PR172](https://github.com/dwijayuda/pskernel/pull/172).
Coordination branch: `fix/psc1-closure-normalization-20261021`.
Active implementation: `perf/psc1-erasure-applied-workers-20261023`.
Use connected GitHub tools and Linux Actions only. Fetch fresh HEAD; use expected
HEAD non-force updates. Preserve history. No merge or npm publication.

Read [compact current evidence](docs/PSC1_SELFHOST_PROFILES_QUALIFICATION_2026-10-23.json)
first; it derives from the exact Git blob of the
[canonical receipt](docs/PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json).
The frozen [Practical Core v1 contract](docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json)
remains the sole release contract:14 families,37 finite criteria.

## Current result and active request

TypeScript G2/G3/fixed point remain unqualified. Current all-input-proved erasure
worker source is `ba0d5f2916074b6331441b050a38fd0f12347604`,
code/proof checkpoint `f9675e05b063df1fb949f97188724d11134b7b26`.
Actual correctness-1800s request
`d2bc51fcce626297db491890551d2902c710a844`,
[run39964278626](https://github.com/dwijayuda/pskernel/actions/runs/39964278626),
job120449945559, is executing. Read its terminal receipt before claiming G2/G3.

The separate unchanged performance-240s request
`9a0a9e6f5b6b8c6546c1833b243115f97888c561`
(parent09f41833d1c2d5c62de8bc55a25e58076055cc06) ends at
[run39965349252](https://github.com/dwijayuda/pskernel/actions/runs/39965349252):
G1 independently admitted/built/executed, all10 cases passed; G2 timeout240170ms,
peakRSS2277344KiB. No G3/fixed point or240s badge.
Source closure85 is9db57f58b183ff8267116b762a8f6a35b1d375301883abc6881987a53bca1abc.
G1 source6e187da6190f21c88792a7fb92b63fd7e64632be1045b40fc95c33434bb20549;
JS executable3524d055b91e58db5b07cf9a6434a02c0c41886a613fe1e37c5b1dc0e7f823a8.
Artifacts, exact source inventories, tool hashes and graph identities are retained.

## Implemented and tested mechanisms

1. Lazy symbol tokens reuse the original two UTF8 views in eligible invariant
   String tail loops. Tokens retain no position arrays. Alias, shadow, capture,
   changed-argument and fresh-name guards preserve fallback behavior. Source
   String equality and semantic fuel are unchanged; no native equality substitute.
2. Size-only queries reuse a live view or count bytes without admitting an index.
   Cached valid-boundary extraction uses UTF16 slicing; cold/invalid/interior/
   out-of-range offsets retain the exact old scan. No capacity expansion.
   Extract-only modules include their required runtime.
3. Eight erasure classification/membership/lookups use fully applied workers
   with original public function types. This removes eager recursive prefixes
   before returned lambdas. Default type classifier4096 and whnf behavior remain.

[Native run39963603961](https://github.com/dwijayuda/pskernel/actions/runs/39963603961)
passes eight official all-input equalities against retained old definitions,
including arbitrary environment/fuel/locals/expressions and all list/query inputs.
Only standard propext/Quot.sound; no new axiom or native_decide.
Zero/forall fuel, first duplicates,100001-entry hits/misses, existing lexer/cursor/
codec/predicate/target-plan/negative gates and both85-module source audits pass.
Earlier cursor run39959279408 also passes16000 equality-loop and95576 extraction
comparisons, independent UTF8-size checks and max2-view/cache-admission checks.

Read-only audit39966960519 verifies the actual G1 manifest, source closure,
requests and original/transformed IR. Source and saturated erasure workers return
data with zero body lambdas. Legitimate function-valued generated variants remain
for partial application. An initially over-broad inspection was repaired without
changing compiler verification or executing another compiler.

## Completed TypeScript trials

| Source / request / run | Actual result | Self request | PeakRSS KiB |
| --- | --- | --- | --- |
| Applied lookups0938c895 /10ac556f /39914906360 | G1 ten cases; G2 timeout |1800149ms|1630836|
| Two-view Mapaae4aac4 /9f39ab51 /39920694158 | G1/runtime checks; G2 timeout; not selected |1800169ms|1787220|
| Tokens d520a49e /27f2a216 /39952593596 | G1 ten cases; G2 timeout |1800195ms|3050788|
| Same tokens /e6df0e0d /39952866650 | G1 ten cases; short G2 timeout |240202ms|2281004|
| Cursor cache edc3e17b /3dd9152a /39959835622 | G1 ten cases; G2 timeout |1800199ms|2989224|
| Same cursor cache /55fcd9d9 /39960115125 | G1 ten cases; short G2 timeout |240168ms|2370648|
| Applied erasure ba0d5f29 /d2bc51fc /39964278626 | Actual long run active |pending|pending|
| Same erasure /9a0a9e6f /39965349252 | G1 ten cases; short G2 timeout |240170ms|2277344|

Older shared-codec/predicate attempts and all history remain in the canonical
receipt. No completed trial above produces admitted G2 or G3. Sampled tree RSS is
separate from maxRSS and can double-count shared pages. Different-source censored
runs do not establish complete-workload speed or memory gains.

## Measured remaining work

The old220s profile39918874112 had StringEqual17099/27684 ticks,17090 under the
equality worker. Audits39953924361/39957038006 confirm the token path reaches G1.
Cursor profile39961304634 shows StringEqual8/26866 ticks and weak-set8025/26866,
mainly eager psErasureTypeValuedWithFuel construction. The proved worker change
reaches actual IR; new bounded profile39966590664 has StringEqual22/27480 and
weak-set114/27480. These are final30s windows of220s replays, not the last30s of
the1800s request; changed source can reach different phases.

Late diagnostic [run39967678751](https://github.com/dwijayuda/pskernel/actions/runs/39967678751)
is a single pinned up-to1750s G2 diagnostic replay at diagnostic source
d5ca074954b30fd51a0e696734128b0e03a023e8 is requested to locate the late cost.
It uses the existing G2/G3 correctness policy, unchanged heap/stack/stream/wire
limits and exact requestae97450bad8f2130d344b0ee98a63766e82849d2b7f897a2b700e7630bdeeb1e.
It grants no adoption, admission or qualification.

Native-leaf invoke and custom request-iterator prototypes remain unadopted:
20 byte-identical real corpus replays each;13704/13788ms and13016/13508ms.
The iterator also passes1080 protocol comparisons. These modest small-corpus
results do not establish G2 benefit. Cached extraction/size diagnostics give20
byte-identical replays at10680/12589ms; production evidence is recorded separately.
Do not retry unchanged1800s runs, repeat existing audits, expand cache/heap/stack/
fuel or float lambdas across effects/traps/captures without checked conditions.

## Preserved qualified references

Integrated code5ce2fc74 / mergea61eecf4 passes normal Linux39909569028:
all selected jobs,47 full steps and37/37 Practical Core criteria; both grammars,
all7 backends, four application categories, official admission, strict IR and
negative tests. Benchmark dependency-skipped. Main Lean compiler source remains
unchanged from78fe34b8; later compiler/backend candidates remain isolated.
Unpublished native tarball7b301ae944841aeda15b846a165e2d540a50846c36b1ded1e9daf07de0e6335b;
native executable60555378ce40e97d0bba8b4f8689031a98410d317911146cd369a41b75462ee7.
Artifact12483409585 expires2026-11-06T06:45:00Z.

Rust branch fix/psc1-rust-owned-string-moves-20261023 is untouched at83e18fe1.
Qualified source5e0b548e/request7d8865a0/run39908529181 genuinely passes G1/G2/G3,
official admission and exact source/closure/canonical-admission/original/target IR/
ten-case fixed points under1800s. G2/G3 692788/660042ms, RSS668192/668184KiB;
all executable bytesd55a8435a157f021e5a7c073037303429b9787729c963af3842a04b9fb009017.
Artifact12482993158 expires2027-01-21T05:56:14Z.240s and independent clean builds
remain unqualified. Preserve this exact source and successful evidence.

## Policy and next action

Performance-240s remains default,15-minute jobs. Correctness-1800s changes only
actual G2-self/G3-self to1800000ms;120-minute jobs/110-minute step. G1/corpus/builds
240000ms, checker120000ms, cleanup5s, streams32MiB, wire128MiB; all semantic fuel,
heap/stack, source/tool identities, strict original/transformed IR, negative and
unsupported-ABI refusals stay unchanged. Official Lean4.35.0 commit
eb6cafb7290e8bd5f2937522d8d804f58f02bafc remains authoritative. One native seed,
then native compiler executables removed; the independent checker remains.

Continue [the roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) and
[exact continuation](docs/PSC1_RUST_TS_SELFHOST_CONTINUATION.md) on the current
erasure branch. Wait for the active actual run, inspect the late diagnostic and
audit each new artifact once. Then fix the measured remaining class before
another request. After correctness, qualify240s separately and promote coherent
validated source with fresh full seven-backend/application CI. No merge/npm
publication. DirectJS G1 and its tracked G2 heap defect stay; ExpressionV2 research
remains independent and never replaces official checking.


## Late-window encoder bottleneck follow-up (2026-10-23)

Actual erasure G2 run39964278626 is terminal: timeout1800138ms, peak3002380KiB; G1/ten cases pass, noG2/G3/fixedpoint. Read-only audit39969728664 verifies its source/request/manifest and actual worker shapes. Diagnostic39967678751 replays the exact G2 request1750s and samples the final30s: WeakCollectionSet26481/27754 ticks (95.4%), primarily psIrEncodeTypeWithFuel23006 and psIrEncodeExprWithFuel3397 beneath WeakMapSet. StringEqual absent from the reported late hot frames. This is diagnostic, not qualification.

Continue on this branch: fully applied type/expression encoder workers remove the remaining eager fuel-prefix closure construction. Original public signatures, default4096, tagged transport bytes, fuel exhaustion/error order and official strict IR/admission remain unchanged. Retained exact originals and all-input Lean equalities plus focused source audits must pass before new actual G2/G3 requests. Qualified Rust branch stays83e18fe1; do not change it. Canonical/compact receipt will incorporate the terminal result and new candidate once validation completes.

Encoder focused validation39972917410/job120480001006 at5d819f69ba1ccda0689e7d354fdcab9295807c0d is SUCCESS: both worker all-input equalities use only propext/Quot.sound; wrapper/helper equivalence, zero/leaf transport tests, all prior proofs/negatives/runtime gates and85-module Lean/PS audits pass. Initial proof-script attempt39972417408 is preserved as failed (constructor/reflexivity closure); compiler code unchanged by repair. Next action is one genuine correctness1800s G1→G2→G3/fixed-point request; original240s remains separate. Do not infer generation qualification from this focused gate.
