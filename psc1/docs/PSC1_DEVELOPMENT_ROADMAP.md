# PSC1 development roadmap

Updated 2026-10-25 Asia/Jakarta. Practical Core v1 stays frozen at fourteen
feature families and 37 finite criteria. Draft PR #178 contains one shared
compiler frontend, elaborator, checked IR and verification pipeline with seven
backends. No merge or package-registry publication is authorized.

## Qualified implementation and evidence

The portable compiler is frozen at implementation
`daa735017e34ee94da79d747c363237b4adbc4ef`, 120-module closure
`07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af`.
Later provider/package/host changes preserve those source bytes.

Rust request `2d27f142`, [40141718481](https://github.com/dwijayuda/pskernel/actions/runs/40141718481),
passes genuine G1/G2/G3, independent admission, strict original/transformed IR,
120 cross-target cases, 27 refusals and exact source/admission/IR/raw-executable/
four-output fixed points. G2/G3 take 2,139,961/2,160,767 ms, with service maxRSS
1,197,260/1,197,296 KiB. The explicit Rust correctness-3600s profile was necessary.
Immutable readback 40147896149 verifies every generation inventory.

Wasm on that same root passes request `0cabb7ed`,
[40147825207](https://github.com/dwijayuda/pskernel/actions/runs/40147825207),
job 121032956320, under the unchanged 1,800-second correctness profile.
G2/G3 take 1,090,090/1,091,869 ms; service maxRSS 2,904,948/2,719,740 KiB.
Readback 40151056584 verifies all source/admission/IR/executable inventories.
JavaScript and TypeScript also PASSED on closure 07eedac1 in request 0cabb7ed,
run 40147825207 (jobs 121032956240 and 121032956267). JS G2/G3 =
1,621,212 / 1,656,073 ms; TS = 1,453,401 / 1,411,839 ms, all within their
unchanged 1,800-second correctness profile. Service maxRSS respectively:
JS 3,568,508 / 3,496,952 KiB; TS 3,437,396 / 3,466,012 KiB.
Immutable readbacks 40152095695 (JS) and 40151632228 (TS) passed.
All four engines now independently qualify G1/G2/G3 and exact fixed points on
one source closure, with identical admission and original/specialized IR hashes.
The [four-engine receipt](docs/PSC1_UNIFIED_FOUR_ENGINE_QUALIFICATION_2026-10-25.json)
pins every request, job, archive, generation, executable and measurement.

Packaging implementation `c4f4c4b3` passes production
[40150260455](https://github.com/dwijayuda/pskernel/actions/runs/40150260455):
15 compiler cases, 18 application builds/66 observations, 20 negatives,
Rust/TS/Wasm and both grammars, with the native compiler disabled. Ten Rust
host transport lifetime/integrity tests and 26 host-session boundary tests
retain admission and transactional publication. Clean installed 40150356751
passes 12 local/global builds without checkout/build tree or compiler SDK/Python.

Four-engine candidate40152198370 passes20 compiler cases,24 application builds/
88 observations and26 negatives on one frozen root; fresh40152578991 passes16
local/global builds without checkout/compilerSDK/Python. Its exact builder is
promoted, with primary production/full CI pending. Generated publication is JS;
native core and optional Python/PHP remain. Final artifact guidance follows CI.
Full source/host checkpoint c4f4c4b3 PASSED40150264075,37/37 criteria/all seven backends/both grammars; review and tested merge share tree411f21746dba916ecda147d63a8758f20a11035a. Four-engine candidate40152198370 and fresh install40152578991 pass; the package promotion's production/full CI remains pending.

The optional-peer fix also passed full 40145805549 at `14cb3e30`, including
actual global Python/PHP execution in both grammars. It fixes offline npm
resolution without weakening exact provider descriptors.

## Single dependency-ordered remaining queue

| Order | Work | Status and finite acceptance |
| --- | --- | --- |
| 1 | Reconcile the existing frozen-root request | COMPLETE: all four engines pass on the same frozen source. Require terminal logs and immutable inventories; preserve successes/failures independently. |
| 2 | Integrate only qualified frozen-root engine assets | PARTIAL. Rust/TS/Wasm installed CLI passes. Add JS and refresh TS/Wasm only after their exact source/generation evidence passes; require installed corpus/apps/refusals and clean local/global execution. |
| 3 | Complete generated publication coverage | PARTIAL. JS publication passes. Extend to retained TS/Rust/Wasm/component outputs and optional-provider dispatch through existing admission, strict IR, target validation and atomic publication; explicit unsupported-ABI refusals remain. |
| 4 | Clean reproduction and final release qualification | PENDING. Current immutable readbacks and independent G1 reproduction are narrower than a clean full-generation replay. Require the exact final package/source qualification and authorization before merge/publication. |
| 5 | Meet the separate 240-second performance target | UNQUALIFIED. Profile real archived compiler requests. The isolated lexer candidate has an all-input equality proof and stage evidence; it is not promoted or whole-compiler qualified. Changes require focused/full regressions and genuine qualification on the changed root. |
| 6 | Broader extension and source readability | DEFERRED beyond frozen v1. Preserve working language features and source-only libraries; do not grant packages kernel, host or FFI authority. |

## Fixed policies

Official independent Lean 4.35.0 at
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, exact source/logical pairing,
strict original/transformed IR, semantic fuel, memory/stack limits, negative
tests and explicit unsupported-ABI refusals remain mandatory.
G1/corpus/build tools stay 240 seconds; checker stays 120 seconds.
Rust-only correctness-3600s extends only G2-self/G3-self, with a 190-minute job/
170-minute step. Existing correctness-1800s and performance-240s remain separate.
Correctness qualification does not grant performance qualification.

Normal development retains tiered, dependency-selected CI. Long runs require
closed-schema request-only commits with exact parents; ordinary edits do not
launch expensive self-host qualification. Documentation reconciliation reuses
successful code gates and never clears failed/cancelled test debt.

[AI state](../AI_WORK_STATE.md) records the exact checkpoint,
[runtime receipt](PSC1_RUST_NAT_RUNTIME_QUALIFICATION_2026-10-25.json) owns measured
attempts, and [continuation](PSC1_UNIFIED_SELFHOST_CONTINUATION.md) gives executable
next steps. Earlier roadmaps and all prior Rust/TS/JS/Wasm/Python/PHP generation
evidence remain preserved in Git history and their source-specific receipts.
PSKernel-Core research progresses independently; it does not replace official
Lean admission or block Practical Core development.
