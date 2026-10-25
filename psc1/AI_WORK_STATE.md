# PSC1 AI work state

Updated 2026-10-25 Asia/Jakarta. Draft PR #178; branch
`feat/psc1-unified-selfhost-20261024`. GitHub tools/cloud Actions only; routine development stays Linux.
Use fresh expected-HEAD, single-parent non-force updates. No merge/npm publication.

## Latest user requirement: default Wasm kernel and separate execution bundles

The final/default independent checker is now required to be
@proofscript/pskernel-lean-wasm4.35.0 (official C++/Emscripten linear memory).
Native Lean is explicit --kernel native|both; no silent native fallback is allowed.
The reference proofscript-psc0-ps-npm-packages.zip was read only as nested package
metadata/layout, with no scripts executed. Its old4.34/candidate-JS trust metadata,
mismatched .js/.mjs exports and Linux-only bundled TypeScript tool are not release
patterns to inherit. [Authoritative distribution contract](NPM_DISTRIBUTION_CONTRACT.json).

Root proofscript will provide qualified generated JS/TS execution, default Wasm
checking and JS/TS/Rust/Wasm output capabilities. Separate optional compiler-rust,
compiler-wasm and platform-native execution bundles reuse the existing compiler;
Python/PHP remain optional output providers. Compiler execution, output backend
and independent kernel are distinct. Modular source/API packages must ship real
working exports/types, not pretend independently compiled facades. The package
split is a final-release queue item; current integration bundles retain old assets.

Default selection implementation now uses a pinned Node/Wasm primary checker,
with explicit native/both comparison. Preserved native publication adds default
Wasm checking of the exact captured staged admissions before commit; its original
native internal checking is retained. The updated host-boundary/native-publisher
and installed-package tests must pass before this implementation is qualified.
The long real Wasm build remains40154206987; do not substitute4.34 bytes.

Native compiler source-admission release run40157017833 has PASSED all four new
platforms (Linux arm64, macOS x64/arm64, Windows x64), with SDK absent from execution
PATH. These are source/check/admission binary gates, not complete backend
publication or whole-toolchain npm qualification. The existing Linux publication
boundary remains a final cross-platform blocker.

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
Windows-only retry40155170697 has PASSED after fixing Bash-path export to native
Elan PATH. Linear Wasm build40154206987 is active at630fa363; do not restart it.
The native4.35 package is qualified on all five platforms as recorded below; linear Wasm and the full cross-platform compiler toolchain remain unqualified.

Next: assemble only pinned successful artifacts, match exact25-module source
closure, pack and install offline locally/globally, execute public API acceptance/
rejection/tamper tests on every platform; finish actual linear Wasm differential
checking and package integration before claiming release readiness. Preserve
qualified120-module compilers and all four G3 artifacts. Whole toolchain platform
selection/native compiler/Rust executable transport and generated output parity
remain separate release blockers. See scripts/kernel435-* and kernel435 workflows.

## Native kernel package milestone

Native package commit4deb99de/run40155475188 PASSES all five platform installed
jobs, same tarballc8ffd49220328ec2a96ac1c4388d828df255cc21537b2484b523710fe6c17371,
6446239 bytes for all five prebuilts combined. Native source closure25 modules,
f1bd2a7d42b9473945028ffa698f244b33afeb937224c5c8e37d8c50d9de0a2b.
Windows retry40155170697 passed,4616704-byte standalone binary. All native
binaries are below7000000 raw bytes. [Install guide](docs/PSC1_KERNEL_PACKAGES.md)
and [exact receipts](docs/PSC1_KERNEL435_QUALIFICATION_2026-10-25.json).

Host kernel CLI/pre-publication additional checking is implemented; run40155831321
passes32 boundary checks and10 Rust transport regressions. Its additional accepted
provider is a real native reference; it does not claim genuine Wasm acceptance.
Real linear Wasm40154206987 remains active; preserve the run/cache. Whole toolchain
cross-platform and integrated dual-check npm qualification remain INCOMPLETE.

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

## Executable kernel continuation and platform boundary

Draft PR #179 now owns this integration branch, stacked on the qualified #178
checkpoint55f9327e. [Executable continuation](docs/PSC1_KERNEL435_CONTINUATION.md)
contains exact inputs, triggers and remaining acceptance gates. Prepared package
workflows execute only after explicit successful artifact identities are committed;
old4.34 bytes cannot satisfy their checks. Core compiler/G3 assets are reused.

Static/installed public types40156453697 and40156780118 pass. New CLI source
transport selects Windows .exe and platform-specific library paths; release source-
admission run40157017833 is active on Linux arm64/macOS/Windows. This does not
qualify backend publication: host-tools/artifacts.mjs explicitly requires Linux,
and generated atomic pointer/fsync behavior also needs a portable contract.
The integrated compiler tarball remains Linux x64 until full platform qualification.
Latest PR normal CI must be checked after actual code changes; cancelled earlier
snapshots are not passing evidence. The long Wasm build40154206987 remains active.

## Scope and remaining queue

The core provides native JS/TS/Rust/Wasm core/component output and all four
qualified generated execution engines. Python/PHP output remains optional.
Explicit `psc generated build --engine js|ts|rust|wasm-core` currently publishes
JS. Other generated publication targets, component/provider dispatch and final
release qualification remain incomplete; allFourEngineSelfHostQualified=true
does not imply allFourEngineReleaseQualified=true. No registry release is claimed.

1. Complete the active Lean4.35 native/linear-Wasm kernel package and cross-platform release integration described above.
2. Complete generated publication targets/components/optional-provider dispatch
   through existing admission, strict IR, target validation and transactional
   publication. Engine selection and output-target selection are separate.
3. Complete clean full-generation reproduction/final release qualification.
   Optimize measured costs toward the separate240s performance profile.
4. Defer broader language/extensions/readability beyond frozen Practical Core v1;
   preserve every working language feature, both grammars and seven backends.

Official Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc, strict original/
transformed IR, exact source/logical pairing, semantic fuel, memory/stack,
negative tests and unsupported-ABI refusals remain unchanged.
G1/corpus/build tools240s,checker120s stay unchanged; separate Rust-only
correctness3600s changes only G2-self/G3-self (190-minute job/170-minute step).
Existing1800s correctness and240s performance are preserved.

The measured Nat constructors/borrowing/dependency optimization is promoted;
experimental LLVM flags are not. Isolated lexer code31e10263/run40143764706 is
proved/stage-tested but NOT promoted or whole-compiler qualified. Preserve the
frozen root and all historical qualification evidence.
The [roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) owns the finite remaining queue.
[Earlier detailed work state](docs/history/AI_WORK_STATE_BEFORE_RUST_G3_PACKAGE_2026-10-25.md)
is preserved verbatim; its pending snapshots do not override these results.
