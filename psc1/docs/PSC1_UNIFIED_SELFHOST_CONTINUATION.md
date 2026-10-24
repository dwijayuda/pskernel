# Continue PSC1 after the codec-frame milestone

Use connected GitHub tools and Linux GitHub Actions only. No local checkout,
files, builds or tests. Fetch latest HEAD of feat/psc1-unified-selfhost-20261024
and draft PR178 before expected-HEAD, non-force writes. Do not merge or publish.
Read psc1/AI_WORK_STATE.md, PSC1_DEVELOPMENT_ROADMAP.md,
PSC1_UNIFIED_V2_CODEC_QUALIFICATION_2026-10-25.json and the service guide.

Code checkpoint `5d4d4d1a1693de57fa16ecf796536d73040bbf64`/draft PR178;
120-module closure `e0f7640b77ee9eaa17e946c628de23f320f2943dc181ac6063a35c81ccb7ca66`.
[Full CI40133272707](https://github.com/dwijayuda/pskernel/actions/runs/40133272707)
PASSED37/37 finite Practical Core criteria. Rust G1 passes, but the genuine
G2 retry reaches its unchanged1800s deadline without an observed stack
overflow. No G2 candidate, G3 or fixed point exists for this snapshot.
Stop at this verified stack-correction milestone; Rust self-host correctness
and performance remain unqualified. Exact evidence:
[codec receipt](PSC1_UNIFIED_V2_CODEC_QUALIFICATION_2026-10-25.json).

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

Preserve v2 TS and Wasm request812094c1/run40126488125, closure92654df5:
both genuinely pass G1/G2/G3 and exact source/admission/IR/raw-executable/
four-target observation fixed points. TS G2/G3=1379563/1401815ms,
Wasm=1396916/1410393ms. Immutable readback40130870206/job120982103024
checks all source/executable inventories and admissions/IR parity, retaining
the same run's Rust overflow and JS1800s deadline as failures. The matrix's
overall failure does not invalidate its successful individual engines.
Preserve older v2 Wasm9359f073 and v1 JS/TSb2ab4d34 qualifications too.
Never inherit fixed-point evidence across source-closure changes.

The codec uses explicit return frames and tail unwinding for both application
axes, binders, let bodies and projections; side branches remain structurally
recursive. codec_spine_acc_eq/codec_spine_eq preserve the exact old opaque
append tree and refusal priority with no new axioms/fuel/stack allowance.
The existing static-schema theorem remains unconditional. All five10000-deep
generated Rust shapes pass; old/current checked observations match.

Rust also preserves guarded String-reader borrowing, ordered last-use moves,
iterative final-owner cleanup of eligible private recursive carriers and
unchanged public enum move-out ABI. Conservative scalar-only carrier omission
keeps the original runtime-free Boolean assertion unchanged; unknown types,
public/generic/named types, carrier expressions and scan exhaustion retain
the original path. e913a6d3 uses fully applied source-recursive visitors.
Wasm divmod's new recursive path halves the dividend; zero/one/odd/even/
arbitrary-precision behavior remains checked against the retained runtime.

Immediate task: profile, then fix the measured Rust G2 deadline.
Download immutable artifact12576967932 from run40133622389, verify ZIP
0f8f31d00fdb3def362dbcd979fd82649864ca90ca44d4a1be3a96a8cacb5bf8,
verify G1 manifesta3c309d25cf5bb855b1eb80b3a3ce07ad7c7e5bcfac287283fadb56dc6665005
and executable91b12534f04b80c8ee4be93f0cca6d6a915a8c44b6087f62db28a677e7620d42,
and replay exact request636624936f655a0412cf5ce0f31df9436bc9f311e63aee25d808f009a76f4118.
Use the existing diagnostic branch/workflow pattern to collect later-phase
GDB samples (for example900/1200/1500s) within the same1800s supervisor.
The existing abort workflow is still pinned to the older f5a00e75 failure;
update all subject hashes/IDs instead of silently reusing it.
Mark diagnostic receipts qualification=false; do not use native compilation
or increase stack/heap/fuel/deadlines. Resource heartbeats show consumption,
not the hot function. Implement only the actual generic bottleneck, preserve
exact semantic proofs/refusals and both grammar censuses, then retry genuine
G1/G2/G3 and fixed points. Keep all earlier TS/Wasm/JS evidence and failures.

Long qualification launches only through an explicit request-only commit.
For the separate qualification branch, first make a single-parent source
snapshot of the latest reviewed code (retain its current request file and
override only the workflow branch guard), and verify all non-.github root
tree identities against the source snapshot. No merge commit. Fetch its fresh
HEAD, then change exactly .github/qualification-requests/psc1-unified-selfhost.json:
```json
{
  "schema": "psc1-unified-selfhost-request/1",
  "branch": "qualification/psc1-codec-tail-workers-20261025",
  "parentCommit": "<fresh exact control HEAD>",
  "action": "qualify-independent-G1-G2-G3",
  "mode": "--self-host",
  "profile": "correctness-1800s",
  "g1TimeoutMs": 240000,
  "g2g3TimeoutMs": 1800000,
  "targets": ["rust"]
}
```
Choose only engines actually requiring new qualification; preserve all active
runs and terminal artifacts. cancel-in-progress remains false. Do not launch
duplicates. A G1-only action validate-independent-G1/mode --g1-only is available
for bounded normalization checks. Relevant Linux commands:
```sh
lake build psc1_codec_static_schema_tests psc1_unified_service_seed psc1_unified_service_tests psc1_independent_checker psc1_source_census_probe
.lake/build/bin/psc1_codec_static_schema_tests
node scripts/codec-spine-tests.mjs
node scripts/generated-target-source-audit.mjs rust unified
node scripts/generated-target-qualification.mjs rust --self-host correctness-1800s unified
```

Official independent Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
strict original/transformed IR, source/logical pairing, negative tests and
all memory/stack/fuel/security policies stay mandatory. G1/corpus/tools240s,
checker120s, G2/G3 correctness1800s, performance240s separate. Unified Rust
correctness keeps optimization0/256 units and stable verified Cargo inputs;
historical single-emitter optimization1 and Python/PHP3600s stay unchanged.

Native proofscript default JS/TS/Rust/Wasm core+component and exact-build
optional Python/PHP packages remain distinct from generated-engine assets.
Generated distribution/CLI/component/provider integration, clean independent
full reproduction and release/publication qualification remain unfinished.
Do not describe this compiler as fully released or formally proved correct.
