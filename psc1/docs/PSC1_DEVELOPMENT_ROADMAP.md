# PSC1 development roadmap

Updated2026-10-25 Asia/Jakarta. Practical Core v1 stays frozen at14 feature
families/37 finite criteria. Draft PR #179 integrates kernels/packages on the
qualified #178 compiler checkpoint; one frontend, elaborator, checked IR and
verification pipeline remain shared. All seven backends/both grammars stay
required. No merge or publication is authorized.

## Verified Wasm-default kernel and compiled-bundle milestone

Code/package checkpoint `3c9fae34d8a8912cce638777611942327b67ca35` passes
integrated run40160064167/job121069555210. Fresh global install at
`d269846a50e33f15e18abe96b653735c0a93cf3e` passes40160640974/job121071261017.
The real installed CLI uses official Lean4.35 C++/Emscripten6.0.9 **linear-memory
Wasm by default**. Native is an explicit comparison; missing/corrupt/refusing
Wasm cannot fall back. Preserved native publication also checks its exact staged
admission graph with Wasm before commit, retaining original native checking.

The integrated seven-tarball artifact12585887196 has ZIP SHA256
`064d226b8dcc9d5275f801b6ed9791519f053b1ae3e80a04fe804c798357261a`.
Core tgz62180617 bytes, SHA256
`b2bf12d1d05c1f92361893411d761ff7b1418117f0e06c9985856768616b9346`.
Actual installed tests pass14 native/Wasm cases,20 compiler cases,24 CLI/JSON
application builds/88 observations,24 generated refusal/tamper cases,8 explicit
dual checks,2 native publication checks and public TypeScript API checks.
Default generated cases run with native compiler AND native checker unavailable.
Fresh global install executes8 builds, all engines/both grammars, offline empty
cache, native payloads unavailable, previous outputs preserved, corrupt Wasm refused.

The unchanged qualified120-module compiler admission graph
`4a43d82487eb09e6efcac248d6db211e9c2854bd2a9e04a9202affce6bdd3e39`
passes BOTH real kernels in6222ms combined. This is independent logical rechecking,
not full-generation replay, formal preservation or DDC.

Both kernel packages are now genuinely install-qualified on Linux x64/arm64 glibc,
macOS x64/arm64 and Windows x64: Native40155475188, Wasm40158859386.
Each platform passes28 offline local/global acceptance/rejection cases plus tamper
refusal without SDK/install scripts. Native binaries are2.77–4.62MB, all below7MB;
the complete five-platform native tgz is6446239 bytes. Wasm tgz582533 bytes contains
the real2212007-byte module. Genuine Wasm build40154206987 passed in1:08:25,
peak1521832KiB; retain the sealed toolchain cache and documented compatibility
patches, including native-equivalent finite task-heartbeat reset.

Separate genuine frozen G3 execution bundles are also implemented and qualified:
`@proofscript/compiler-wasm` (1370182-byte tgz, five platforms) and
`@proofscript/compiler-rust-linux-x64` (12917609-byte tgz, Linux x64/glibc),
run40158598464. They verify exact compiler/transport pins and expose candidate
APIs, with no admission/publication authority. Root CLI optional-bundle discovery
is still pending; the transitional root continues to embed all four engines.
The compiler Wasm GC architecture remains distinct from the linear-memory kernel.

Native compiler binaries pass real .lean/.ps source/admission checks on Linux
arm64/macOS x64+arm64/Windows x64 in40157017833. This narrower gate does not qualify
backend publication or the whole installed toolchain on those platforms.

[Install guide](PSC1_KERNEL_PACKAGES.md),
[machine-readable evidence](PSC1_KERNEL435_QUALIFICATION_2026-10-25.json) and
[executable continuation](PSC1_KERNEL435_CONTINUATION.md) contain exact identities.
The latest normal PR source regression gate must be terminal before recording it;
prior cancelled runs are not successes. Parent55's37/37 is historical baseline
evidence, not an automatic qualification of this integration branch.

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

## Final npm layout

[Authoritative distribution contract](../NPM_DISTRIBUTION_CONTRACT.json):
root proofscript defaults to generated JS/TS execution with required official
linear-memory Wasm checking; JS/TS/Rust/Wasm output capabilities remain core.
Optional compiled Rust/Wasm/native execution bundles and optional Python/PHP output
providers are distinct. The current root still embeds all four engines/native
assets and is Linux x64/glibc. Separate compiled bundles now exist and pass genuine
candidate API tests, but root optional discovery/slimming remains a release task.
Never ship nonexistent exports/types, a wrong-platform default tool or a source
facade labeled as an independent compiler. The supplied old archive is layout
reference only, not an authority or current trust policy.

## Single dependency-ordered remaining queue

| Order | Work | Status and finite acceptance |
| --- | --- | --- |
| 0 | Final source regression gate | Run normal dependency-selected source CI through every selected check; preserve failed/cancelled debt. Exact successful final source/package identities required. Current kernel/default-Wasm installed gates above are passed. |
| 1 | Portable publication and final npm split | PENDING. Preserve Linux immutable generations/atomic prior-output behavior; implement and execute equivalent Windows/macOS publication. Slim universal JS/TS root requires genuine default Wasm checking, optional compiled bundle discovery with pins, no wrong-platform bundled default tools, real exports/types/bin, and all five platforms' actual offline local/global compilation. Keep existing working root available until replacement qualifies. |
| 2 | Generated TS publication | PENDING. Reuse shared admission/strict IR/publication; pinned independent TS consumer, equivalent observations, both grammars/all four engines, refusal/ABI/tamper and prior-output preservation. No native compiler fallback. |
| 3 | Generated Rust/Wasm output, components and optional providers | PENDING. Reuse existing checked emitters/runtime adapters; finish all relevant backend mappings and consumer tests. Additional Rust execution platforms need genuine binaries and bounded supervisors. Keep native CLI/Python/PHP providers working. |
| 4 | Clean reproduction and final release | PENDING. Immutable readbacks, installed tests and frozen graph checks are narrower than a clean full-generation replay. Exact final source/package/platform qualification and authorization required before merge or publication. |
| 5 | Original240-second performance target | UNQUALIFIED. Optimize measured real compiler workloads, preserve G1/checker/fuel/memory/stack limits. The isolated proved lexer candidate is stage-tested and unpromoted. Source changes require new-root qualification. |
| 6 | Broader language/extensions/readability | DEFERRED beyond frozen v1. Preserve all working features/source libraries. Optional packages grant no kernel/host/FFI authority. |

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
and [executable continuation](PSC1_KERNEL435_CONTINUATION.md) own this queue.
[The preceding roadmap](history/PSC1_DEVELOPMENT_ROADMAP_BEFORE_RUST_G3_PACKAGE_2026-10-25.md)
and all earlier target-specific qualifications/failures remain preserved in Git.
Do not transfer source-specific evidence to changed compiler roots.
