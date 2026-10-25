# PSC1 development roadmap

Updated2026-10-25 Asia/Jakarta. Draft PR #180 follows qualified PR #179. Practical
Core v1 remains frozen at14 feature families/37 finite criteria. One existing
compiler source/frontend/elaborator/checked IR/verification pipeline serves all
seven backend mappings and both source grammars. No merge or npm publication.

## Current package result

Slim universal-format `proofscript@0.1.0-psc1.4` passes actual Linux package
run40166882825 at0a717520110c673006d3f5f5d7627e59d5853f62:
3,703,113-byte root, down94.04% from62,181,083. Root includes qualified JS/TS
executors and the mandatory official4.35 linear-memory Wasm checker only.
Rust/compiler-Wasm executors and native checking are explicit optional packages.
Exact package/version/index/manifest/resource/source/executable pins prohibit
arbitrary plugin selection, downloads and silent fallback.

Tests:20 real compiler cases/four engines/both grammars,12 local/global CLI cases,
48 candidate mappings,14 genuine checker comparisons,31 negative/rollback cases
and actual packed public types. Empty-cache offline installation begins without
optional/native payloads or SDK execution. Optional bundles are then installed
and actually executed through the same existing checked session.

[Install guide](PSC1_SLIM_UNIVERSAL_PACKAGE.md),
[qualification receipt](PSC1_SLIM_UNIVERSAL_QUALIFICATION_2026-10-25.json),
[continuation](PSC1_SLIM_UNIVERSAL_CONTINUATION.md).
The finite [npm distribution contract](../NPM_DISTRIBUTION_CONTRACT.json)
owns acceptance; exact CI evidence belongs in the receipt, not a volatile
self-reported contract status.

## Current qualification boundary

The root format and checked compile API/stdout are portable Node-only code; this
slice is tested on Linux only. JS checked publication preserves the existing
Linux fsync/lock/immutable-generation/atomic-current-pointer guarantee, and
explicitly refuses other OS publication. Kernel-Wasm stays official C++ linear
memory; optional compiler-Wasm stays PSC1's existing GC architecture.

Checked generated output is JS. Candidate-only JS/TS/Rust/Wasm-core output grants
no proof or publication authority. It is distinct from complete checked generated
publication. The previous native distribution and its all-seven-output CLI,
matching optional Python/PHP providers and real application evidence remain
preserved in [the prior guide](PSC1_KERNEL_PACKAGES.md) and Git history.

Normal source run40166884643 PASSED at code
`0a717520110c673006d3f5f5d7627e59d5853f62`: full job121091590002 and final
gate121096509883,37/37 Practical Core criteria,0 blocked,all seven backends/both
grammars,minimum Python and installed native npm/source libraries.
Tested merge`559ea387ad22999b7b6aedd073fd61c8a0c1bc28` and code HEAD share
tree`0a232bbdf67f6f8de60950142af3be17f1231e4d`.
Full artifact12589082030 ZIP SHA256
`1c0d30be97a68c7ca3fb25667dd8412dbb477d8df447960d12fd5b88764700a2`.
This is separate from slim package40166882825 and does not imply complete
cross-platform or checked non-JS generated publication qualification.


## One dependency-ordered queue

| Order | Work | Status and finite acceptance |
| --- | --- | --- |
| 0 | Slim root and optional executor integration | PACKAGE QUALIFIED40166882825. Source gate40166884643 PASSED37/37,0 blocked. Default JS/TS without native/optional payloads, explicit pinned Rust/Wasm local/global execution, independent checking and refusal/rollback are verified. |
| 1 | Slim real application/source-package coverage | PENDING. Compile/consume representative CLI/JSON/file/multi-module applications through the new root and both grammars; automatic source closure capture must not grant host/FFI authority. Keep previous native package functional. |
| 2 | Portable transactional publication | PENDING. Preserve Linux semantics and previous outputs. Implement actual equivalent macOS/Windows publication plus offline installed platform release gates; source-admission binaries or universal npm metadata alone do not qualify this. |
| 3 | Checked generated TS publication | PENDING. Reuse checked emitter/runtime/admission/publication, independent pinned TS consumers, all four executors/both grammars, negative/ABI/tamper/prior-output checks. |
| 4 | Checked Rust/Wasm/core/component/provider dispatch | PENDING. Reuse existing emitters and runtime adapters, complete all relevant target mappings/consumer gates. Python/PHP remain optional. Additional Rust execution platforms need genuine binaries and bounded supervisors. |
| 5 | Final clean reproduction and universal release | PENDING. Exact final source/package/platform qualification, full required reproduction and user authorization before merge/publication. |
| 6 | Original240-second performance target | UNQUALIFIED. Optimize measured real compiler workloads without changing semantic fuel, G1/checker or memory/stack policies. Isolated proved lexer31e10263 is unpromoted. |
| 7 | Broader language/extensions/readability | DEFERRED beyond frozen v1. Preserve all working features; optional source/API packages grant no kernel/host/FFI/runtime authority. |

## Preserved qualifications

Four genuine G1/G2/G3 chains and exact source/admission/both-IR/executable/four-output
fixed points share120-module closure
07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af,
implementationdaa735017e34ee94da79d747c363237b4adbc4ef.
Each chain has120 cross-target cases and27 refusals with successful immutable
readbacks. [Exact receipt](PSC1_UNIFIED_FOUR_ENGINE_QUALIFICATION_2026-10-25.json).

| Executor | G2/G3 request ms | Service maxRSS KiB | Correctness profile |
| --- | --- | --- | --- |
| JS | 1621212 /1656073 | 3568508 /3496952 | 1800s |
| TS | 1453401 /1411839 | 3437396 /3466012 | 1800s |
| Rust | 2139961 /2160767 | 1197260 /1197296 | 3600s |
| Wasm | 1090090 /1091869 | 2904948 /2719740 | 1800s |

Prior PR #179 default-Wasm integration40161362270 and source40161364575 passed
37/37/seven backends/both grammars; final docs40163908331 pass.
Native4.35 kernels40155475188 and official linear-Wasm40158859386 are installed
qualified on Linux x64/arm64, macOS x64/arm64 and Windows x64. Native raw kernels
are2.77–4.62MB each; whole native tgz6446239 bytes. Wasm tgz582533 bytes/module2212007.
Compiled bundle40158598464 qualifies Wasm candidate execution on five platforms
and Rust on Linux x64. These are distinct from full root-platform release.
[Exact prior receipt](PSC1_KERNEL435_QUALIFICATION_2026-10-25.json).

## Fixed policies and throughput

Official Lean4.35.0 at eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
trustlevel0, finite2000000-heartbeat/20000-recursion, independent admission,
strict original/transformed IR, source/logical pairing, semantic fuel,
memory/stack/lifetime, negatives and unsupported ABI refusals remain required.
G1/tools/corpus240s/checker120s unchanged; original1800s correctness and240s
performance remain separate; Rust-only3600s is G2/G3 requests only.

Use successful exact-source artifacts and dependency-selected CI. Package tests
qualify default local/global installation and optional bundles in one run. Keep
npm-managed metadata separate from the immutable runtime dependency-lock snapshot.
Do not rerun successful long frozen chains for package/docs-only changes.
PSKernel-Core research remains independent and does not replace official checking
or block Practical Core work.

[AI state](../AI_WORK_STATE.md) owns the current checkpoint; this roadmap owns
the single remaining queue. Earlier complete states remain available through Git
and the immutable qualification receipts.
