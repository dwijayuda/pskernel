# PSC1 AI work state

## Package qualification and project-boundary hardening

Package039888f8 passed40166009809:3,703,048 bytes,20 real compiler cases,
12 local/global CLI cases,32 candidate mappings,14 real checker comparisons,
31 refusal/rollback cases and packed public types. It fixes the npm-managed
shrinkwrap runtime-pin failure by preserving an immutable DEPENDENCY_LOCK.json.

The current follow-up closes project JSON to entryModule/sources/assurance only.
Source data cannot set output paths, service files, checkers or executor choices;
those require explicit host options. Added tests reject those fields and preserve
prior output. Additional root-only tests exercise all four candidate output
mappings using embedded JS/TS without optional executors. This latest hardening
must pass its actual package/source gates before being called qualified.

## Active slice: slim universal root and optional executors

Continue from PR #179 HEAD ba3bfb045619ceb2948820f874357b2058f79868 on
`feat/psc1-slim-universal-npm-20261025`. The prior PR and qualified artifacts are
preserved. This slice uses GitHub and Linux Actions only; no merge or npm publish.

Implementation is now prepared, **not yet qualified**: a fresh universal-format
proofscript@0.1.0-psc1.4 root containing only existing G3 JS/TS engines and the
mandatory official Lean4.35 linear-memory Wasm kernel. No native compiler/checker,
Rust executor, compiler-Wasm executor, formatter binary, SDK or Python/PHP payload
is included by default. Rust/Wasm execution and native comparison are explicit
optional installed packages, selected only through exact closed package/version/
manifest/index/resource pins from the already qualified artifacts. No discovery
from source text, arbitrary plugin names, downloads or silent fallback.

The root reuses generated-compiler-session.mjs unchanged for independent admission,
strict original/transformed IR and Linux transactional JS publication. Universal
checked compile API/stdout returns admitted JS without publication. Non-Linux
file publication is explicitly refused pending actual platform qualification.
A separate bounded candidate-only API retains JS/TS/Rust/Wasm-core emission from
the same compiler; it grants no admission/publication authority. The prior native
distribution still owns its qualified all-seven-output CLI and stays preserved.

Acceptance: packed root <50% of previous62181083 bytes; no OS/CPU/libc restriction
or native executable payload; offline fresh local/global installation; default
JS/TS without SDK/optional executors; explicit Rust/Wasm discovery/all four real
engines/both grammars; optional native/Wasm genuine checker agreement; rejection,
corruption/version/absence/policy/fault cases preserve previous output; actual
public API TypeScript consumer. Linux package qualification and normal selected
source CI must pass before recording success. Full macOS/Windows publication,
generated non-JS publication, component/provider dispatch and final release remain
separate incomplete requirements. No frozen compiler source or qualified G3 byte
is changed; do not rerun successful long self-host chains for this packaging slice.

Updated2026-10-25 Asia/Jakarta. Draft PR #179, branch
`integration/psc1-lean435-kernel-packages-20261025`, stacked on #178/
qualified55f9327e. Connected GitHub and cloud Actions only; routine development
is Linux. Explicitly requested macOS/Windows builds are separate release
qualification. Fetch live HEAD, use single-parent expected-HEAD non-force updates.
No merge or npm publication is authorized.

## Verified Wasm-default kernel and compiled-bundle milestone

Code/package checkpoint `cd6a16ba1c9efc5668507ee6b9eb125f2d3b2fad` passes
integrated run40161362270/job121073432577. Fresh global installation now passes inside the same integrated job. Earlier
standalone global run40160640974/job121071261017 also passed atd269846a.
The real installed CLI uses official Lean4.35 C++/Emscripten6.0.9 **linear-memory
Wasm by default**. Native is an explicit comparison; missing/corrupt/refusing
Wasm cannot fall back. Preserved native publication also checks its exact staged
admission graph with Wasm before commit, retaining original native checking.

The integrated seven-tarball artifact12586394254 has ZIP SHA256
`426c62ce4ca8fb87570d1ba169c681004d7da5e5faea80e2b3fbe07c9ef04b52`.
Core tgz62181083 bytes, SHA256
`02c5db1989adf3ada1ad39318c3efc05498a3f3132b2f21fa6a564aceea3f60a`.
Four missing/conflicting root/generated kernel declarations are refused by
all three CLI paths (12 cases), with the native checker available and prior output
preserved. Actual installed tests pass14 native/Wasm cases,20 compiler cases,24 CLI/JSON
application builds/88 observations,24 generated refusal/tamper cases,8 explicit
dual checks,2 native publication checks and public TypeScript API checks.
Default generated cases run with native compiler AND native checker unavailable.
Fresh global install executes8 builds, all engines/both grammars, offline empty
cache, native payloads unavailable, previous outputs preserved, corrupt Wasm refused.

The integrated workflow now qualifies fresh global installation before artifact
promotion, avoiding a second input commit and redundant source CI cancellation.
The unchanged qualified120-module compiler admission graph
`4a43d82487eb09e6efcac248d6db211e9c2854bd2a9e04a9202affce6bdd3e39`
passes BOTH real kernels in10734ms combined. This is independent logical rechecking,
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

[Install guide](docs/PSC1_KERNEL_PACKAGES.md),
[machine-readable evidence](docs/PSC1_KERNEL435_QUALIFICATION_2026-10-25.json) and
[executable continuation](docs/PSC1_KERNEL435_CONTINUATION.md) contain exact identities.
The final code/source regression run40161364575 PASSED at
`cd6a16ba1c9efc5668507ee6b9eb125f2d3b2fad`: full job121075449014 and final
gate121080510772,37/37 Practical Core criteria,0 blocked,seven backends/both
grammars, minimum Python and installed native npm/source libraries.
Tested merge`460a2f7057cd39bbc7489552ce2785c92c3de717` and branch HEAD have
identical tree`55cf04f9c8d50738f77cef82dded1e97478c6d3d`.
Full evidence artifact12586859725 ZIP SHA256
`48b75a7a58b25e145423c3584b54d2f5c296c91ab1c1a4930077a63f8275cd0d`.
This current source result supersedes pending/cancelled snapshots; all earlier
evidence remains historical. The installable integrated artifact remains the
separately qualified40161362270 package described above. Whole-toolchain final
cross-platform release is still incomplete.


## Final distribution contract and reference archive

[NPM_DISTRIBUTION_CONTRACT.json](NPM_DISTRIBUTION_CONTRACT.json) is authoritative.
Final root: qualified generated JS/TS execution, required default Wasm kernel and
all JS/TS/Rust/Wasm output capabilities. Optional compiled Rust/Wasm/native
execution bundles are separate from optional Python/PHP output providers.
Current integrated root is transitional Linux x64/glibc with native/four-engine
assets retained; allFourEngineSelfHostQualified=true,
allFourEngineReleaseQualified=false. Generated CLI publishes JS only today.

The supplied proofscript-psc0-ps-npm-packages.zip was inspected read-only for nested
tarball metadata/layout, with no archived code executed. Its old4.34/candidate-JS
trust policy, nonexistent .js exports where payloads are .mjs, and Linux-only
TypeScript tool are not inherited. New source/API scopes require actual working
runtime/type exports; partial .ps translations cannot be labeled full parity.

## Four-engine correctness milestone and package promotion

All four execution engines (JS, TS, Rust, Wasm) now independently PASS genuine
G1 → G2 → G3 and exact source/admission/original+specialized IR/raw-executable/
four-output fixed points on one frozen 120-module compiler source:
`07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af`,
implementation `daa735017e34ee94da79d747c363237b4adbc4ef`.
Each chain passes 120 cross-target cases and 27 envelope refusals. All generation
inventories were checked again through independent immutable archive readbacks.
Official independent Lean 4.35.0 remains authoritative.

| Engine | G2 request ms | G3 request ms | Service maxRSS KiB (G2/G3) | Correctness limit |
| --- | ---: | ---: | --- | ---: |
| JS | 1621212 | 1656073 | 3568508 / 3496952 | 1800s |
| TS | 1453401 | 1411839 | 3437396 / 3466012 | 1800s |
| Rust | 2139961 | 2160767 | 1197260 / 1197296 | 3600s |
| Wasm | 1090090 | 1091869 | 2904948 / 2719740 | 1800s |

Rust request2d27f142/run40141718481/job121014751809 required the new separate
one-hour correctness profile. Other engines passed request0cabb7ed/run40147825207
with unchanged1800s limits. Rust readback40147896149; JS40152095695;
TS40151632228; Wasm40151056584. Their admitted graph and both IR hashes match;
their printed source and executable bytes remain target-specific.
See the [exact four-engine receipt](docs/PSC1_UNIFIED_FOUR_ENGINE_QUALIFICATION_2026-10-25.json).
Performance240s is unqualified; clean full-chain replay and formal preservation/DDC
remain separate unfinished claims.

## Installed four-engine qualification

Candidate `a32eef485c9067b4245b530af31c7b44eaa3d955`,
[40152198370](https://github.com/dwijayuda/pskernel/actions/runs/40152198370)/
job121045870069 PASSED 20 compiler cases,24 application builds/88 observations,
26 refusal/tamper checks, all four engines and both grammars. JSON-record and
CLI-argument sources exercise actual7/9-module applications. Native compiler
is disabled during generated compilation; exact assets, host dependencies,
independent checker and atomic publication remain required.

[Artifact12583067653](https://github.com/dwijayuda/pskernel/actions/runs/40152198370/artifacts/12583067653)
contains the unpublished four-engine core and matching optional Python/PHP tgzs.
ZIP SHA256 d6f2d578b0451b92f3d20778b0fe9983e310b656454d1a9daf7de3377f8d2f5a;
core4e4881d77c6a77cbad44faeb70798e71b76572fcedaee8cff01fcbe83f3ba711.
Matching Python/PHP hashes stay
a9e26065a916ba53405897a29bdcb6b0cb4b750fef516e2948ad0c30a1a3e1bd /
7eaaa1f667e9783803e2402ce5d1adb6bd0d867faf665dbb8c5e406a260afaec.
Do not mix older same-version files.

[Clean40152578991](https://github.com/dwijayuda/pskernel/actions/runs/40152578991)/
job121047018797 PASSED16 offline local/global builds across all engines/both
grammars, without checkout/build tree or compiler SDK/Python on execution PATH.
The Node-only Rust guard retains ten real integrity/lifetime regressions.
Ordinary requests remain240s.

Production55f9327ee738b5b2bf5d623c96280cb97de828b2 PASSED package40152769340/job121047594235 (20 compiler cases,24 application builds/88 observations,26 negatives) and full40152772905/job121049906606/final gate121055266402 (37/37 criteria,0 blocked,seven backends,both grammars). Tested mergef9713323bb3beed393255ff755da3dd2023febdc shares treed884c41c8097ac59c91081f019481f60625ba793 with review55. Production artifact12582649787 ZIPda6a88220337c601fcf401ea7e06a55c45988f96c0a5692d28e958ed07c61916, core29a837faedaabb8c7e6ae30cec19ac53680084b5188de0eef2b7eabbd4f09198. Full artifact12583743977 ZIP8b10c96a59fab176c0cf7dcc967720c8384870d97745859f0a3a99a71cc17194. All package artifacts remain unpublished.

## Single dependency-ordered remaining queue

| Order | Work | Status and finite acceptance |
| --- | --- | --- |
| 0 | Final source regression gate | QUALIFIED atcd6a16ba:40161364575,37/37,0 blocked, all selected gates passed. Default-Wasm installed local/global qualification40161362270 also passed. Final universal release remains incomplete. |
| 1 | Portable publication and final npm split | PENDING. Preserve Linux immutable generations/atomic prior-output behavior; implement and execute equivalent Windows/macOS publication. Slim universal JS/TS root requires genuine default Wasm checking, optional compiled bundle discovery with pins, no wrong-platform bundled default tools, real exports/types/bin, and all five platforms' actual offline local/global compilation. Keep existing working root available until replacement qualifies. |
| 2 | Generated TS publication | PENDING. Reuse shared admission/strict IR/publication; pinned independent TS consumer, equivalent observations, both grammars/all four engines, refusal/ABI/tamper and prior-output preservation. No native compiler fallback. |
| 3 | Generated Rust/Wasm output, components and optional providers | PENDING. Reuse existing checked emitters/runtime adapters; finish all relevant backend mappings and consumer tests. Additional Rust execution platforms need genuine binaries and bounded supervisors. Keep native CLI/Python/PHP providers working. |
| 4 | Clean reproduction and final release | PENDING. Immutable readbacks, installed tests and frozen graph checks are narrower than a clean full-generation replay. Exact final source/package/platform qualification and authorization required before merge or publication. |
| 5 | Original240-second performance target | UNQUALIFIED. Optimize measured real compiler workloads, preserve G1/checker/fuel/memory/stack limits. The isolated proved lexer candidate is stage-tested and unpromoted. Source changes require new-root qualification. |
| 6 | Broader language/extensions/readability | DEFERRED beyond frozen v1. Preserve all working features/source libraries. Optional packages grant no kernel/host/FFI authority. |

## Preserved policies and continuation

Official Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc, trustlevel0,
finite2000000-heartbeat/20000-recursion kernel bounds, exact source/logical pairing,
strict original/transformed IR, semantic fuel, memory/stack, negative tests and
unsupported ABI refusals remain required. G1/corpus/buildtools240s, checker120s,
original1800s correctness and240s performance remain unchanged. Rust-only3600s
applies only to G2/G3 compiler requests,190-minute job/170-minute step.

Resolved package-only failures remain in the qualification receipt and Git:
Windows Elan PATH setup (retry40155170697 passed); absent upstream shrinkwrap
(fixed using only exact pinned dependency lock/inventory); frozen JSON-null reader
(fixed3c9, integrated40161362270 passed). These do not change qualified compiler
source or kernel semantics. Earlier cancelled gates remain cancelled.

The [roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) owns the remaining queue.
[Execute the continuation](docs/PSC1_KERNEL435_CONTINUATION.md) after fetching
live HEAD/CI. Preserve original self-hosting and slim native evidence; do not
repeat successful long frozen chains for packaging/docs.
[Earlier detailed state](docs/history/AI_WORK_STATE_BEFORE_RUST_G3_PACKAGE_2026-10-25.md)
is preserved; its pending snapshots do not override current exact receipts.
