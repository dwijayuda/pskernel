# PSC1 development roadmap

Updated2026-10-25 Asia/Jakarta. Practical Core v1 remains frozen at14 feature
families and37 finite criteria. Draft PR #178 uses one existing frontend,
elaborator, checked IR and verification pipeline. All seven backends and both
source grammars remain required. No merge or registry publication is authorized.

## Qualified source and installed execution engines

All four JS/TS/Rust/Wasm execution engines independently pass genuine G1/G2/G3
and exact source/admission/original+specialized IR/raw-executable/four-output
fixed points on one frozen120-module compiler closure:
`07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af`,
implementation`daa735017e34ee94da79d747c363237b4adbc4ef`.
Each chain passes120 cross-target cases and27 envelope refusals; immutable
readbacks verify every generation's inventory. The checked admitted graph and
both IR hashes agree across all engines. Target source/executable hashes remain
distinct. [Exact four-engine evidence](PSC1_UNIFIED_FOUR_ENGINE_QUALIFICATION_2026-10-25.json).

| Engine | G2/G3 compiler-request ms | G2/G3 service maxRSS KiB | Correctness profile |
| --- | --- | --- | --- |
| JS | 1621212 / 1656073 | 3568508 / 3496952 | 1800s |
| TS | 1453401 / 1411839 | 3437396 / 3466012 | 1800s |
| Rust | 2139961 / 2160767 | 1197260 / 1197296 | 3600s |
| Wasm | 1090090 / 1091869 | 2904948 / 2719740 | 1800s |

Rust passes run40141718481/request2d27f142; JS/TS/Wasm pass
run40147825207/request0cabb7ed. The one-hour Rust profile was necessary; the other
profiles did not need increases. These measured real compiler workloads qualify
correctness, not the separate240-second performance target.

Package implementation55f9327e integrates those exact qualified G3 assets.
Candidate40152198370 passes20 compiler cases,24 application builds/88 observations,
26 refusal/tamper checks, four engines/both grammars, with native compiler disabled.
Fresh40152578991 passes16 offline local/global builds without checkout/build tree
or compiler SDK/Python on execution PATH. Node-only Rust supervision retains ten
real integrity/lifetime tests. Python/PHP remain matching optional providers.
Production55f9327ee738b5b2bf5d623c96280cb97de828b2 PASSED package40152769340/job121047594235 (20 compiler cases,24 application builds/88 observations,26 negatives) and full40152772905/job121049906606/final gate121055266402 (37/37 criteria,0 blocked,seven backends,both grammars). Tested mergef9713323bb3beed393255ff755da3dd2023febdc shares treed884c41c8097ac59c91081f019481f60625ba793 with review55. Production artifact12582649787 ZIPda6a88220337c601fcf401ea7e06a55c45988f96c0a5692d28e958ed07c61916, core29a837faedaabb8c7e6ae30cec19ac53680084b5188de0eef2b7eabbd4f09198. Full artifact12583743977 ZIP8b10c96a59fab176c0cf7dcc967720c8384870d97745859f0a3a99a71cc17194. All package artifacts remain unpublished.

Current generated CLI publication is JS. Native compilation retains JS/TS/Rust/
Wasm core/component and optional Python/PHP output. Execution-engine qualification
and output-target coverage have separate acceptance criteria. The package
records allFourEngineSelfHostQualified=true, allFourEngineReleaseQualified=false.
Use the [install guide](PSC1_GENERATED_PACKAGE.md) for exact tarballs and commands.

## Active kernel and platform integration mission

Latest development continues on `integration/psc1-lean435-kernel-packages-20261025`,
branched from qualified55f9327e. Routine development is Linux-only. The user
explicitly requested final native macOS/Windows builds and installed release tests;
those run in a separate release matrix. No merge or npm publication is authorized.

Both existing kernel packages are being upgraded to official Lean4.35.0/current
canonical admissions v2. The official C++ Wasm checker remains Emscripten linear
memory, separate from PSC1's Wasm backend. Archive branch0408f18b established the
slim kernel-only initialization/narrow-import/-Os/remove-unused-Lake strategy.
Current25-module provider closure retains all finite kernel checks and semantic
bodies. Linux x64/arm64 run40154010946 PASS14 real reference-parity cases and
standalone execution; raw binaries4079232/4160016 bytes. macOS x64/arm64 jobs
121053490973/121053490842 in40154709416 PASS equivalent gates,2771584/2798528 bytes.
That matrix's overall failure is Windows setup, not a macOS success override.
Windows-only retry40155170697 is active after fixing Bash-path export to native
Elan PATH. Linear Wasm build40154206987 is active at630fa363; do not restart it.
No new4.35 npm package or full cross-platform toolchain is qualified yet.

Next: assemble only pinned successful artifacts, match exact25-module source
closure, pack and install offline locally/globally, execute public API acceptance/
rejection/tamper tests on every platform; finish actual linear Wasm differential
checking and package integration before claiming release readiness. Preserve
qualified120-module compilers and all four G3 artifacts. Whole toolchain platform
selection/native compiler/Rust executable transport and generated output parity
remain separate release blockers. See scripts/kernel435-* and kernel435 workflows.

## Single dependency-ordered remaining queue

| Order | Work | Status and finite acceptance |
| --- | --- | --- |
| 0 | Lean4.35 kernel packages and cross-platform release | ACTIVE. Exact native/linear-Wasm source, real kernel parity, pinned package assembly and installed local/global platform gates. See active mission above. |
| 1 | Generated TS publication | PENDING after kernel integration. Reuse shared host admission/publication; validate generated TS with a pinned independent consumer, equivalent observations, both grammars/all four installed engines, exact pins, refusal/ABI/tamper and previous-output preservation. No native compiler fallback. |
| 2 | Generated Rust/Wasm output, components and optional providers | PENDING. Use existing checked emitters and target tools; complete public ABI, typed IO/runtime adapters and all seven relevant mappings before declaring output parity. Preserve native CLI/providers throughout. |
| 3 | Clean reproduction and final release qualification | PENDING. Immutable readbacks, fresh installed runs and independent G1 reproduction are narrower than clean full-generation replay. Require the exact final source/package qualification and authorization before merge/publication. |
| 4 | Original240-second performance target | UNQUALIFIED. Profile archived real compiler requests. Keep G1/checker/resource limits unchanged. The isolated proved lexer candidate is stage-tested but not promoted or whole-compiler qualified. Source changes require focused/full regressions and genuine new-root qualification. |
| 5 | Broader language/extensions/readability | DEFERRED beyond frozen v1. Preserve all working features/source libraries; packages cannot grant kernel/host/FFI/runtime authority. |

## Fixed policies and development throughput

Official independent Lean4.35.0 at
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, exact source/logical pairing,
strict original/transformed IR, semantic fuel, memory/stack, negative tests and
unsupported-ABI refusals remain mandatory. G1/corpus/build tools240s and checker120s
stay unchanged. Separate Rust-only correctness3600s changes only G2-self/G3-self,
with190-minute job/170-minute step. Original1800s correctness and performance240s
remain separate. Longer correctness never grants the performance claim.

Use tiered/dependency-selected CI and cache successful exact-source builds.
Long self-host runs require closed-schema request-only commits with exact parents.
Do not repeat successful frozen chains for documentation or small packaging
milestones. Documentation-only reconciliation reuses successful code gates and
never clears failed/cancelled test debt. Compiler/kernel research progresses
independently; PSKernel-Core does not replace official admission or block Practical
Core development.

[AI state](../AI_WORK_STATE.md), [exact receipts](PSC1_UNIFIED_FOUR_ENGINE_QUALIFICATION_2026-10-25.json)
and [executable continuation](PSC1_UNIFIED_SELFHOST_CONTINUATION.md) own this queue.
[The preceding roadmap](history/PSC1_DEVELOPMENT_ROADMAP_BEFORE_RUST_G3_PACKAGE_2026-10-25.md)
and all earlier target-specific qualifications/failures remain preserved in Git.
Do not transfer source-specific evidence to changed compiler roots.
