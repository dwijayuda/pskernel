# PSC1 AI work state

Updated 2026-10-25 Asia/Jakarta. Draft PR #178; branch
`feat/psc1-unified-selfhost-20261024`. GitHub tools/Linux Actions only.
Use fresh expected-HEAD, single-parent non-force updates. No merge/npm publication.

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

## Tested installed candidate; production promotion pending CI

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

The exact tested package builder is now promoted. New primary production package
and required full CI are PENDING for this promotion. The last full source/host
checkpoint `c4f4c4b3` PASSED [40150264075](https://github.com/dwijayuda/pskernel/actions/runs/40150264075),
job121042005233/final gate121047122405:37/37 criteria,0 blocked, all seven backends,
both grammars, real applications, minimumPython, installed native/core/provider/
IO/library tests and actual globalPython/PHP execution. Reviewc4f4c4b3 and tested
mergeb15ea969 share tree411f21746dba916ecda147d63a8758f20a11035a.
Full artifact12583665578,ZIP34f59b0f33db0645a902561aa7fe2988676c0713bf614388a2e48354e0ecf4ce.

## Scope and remaining queue

The core provides native JS/TS/Rust/Wasm core/component output and all four
qualified generated execution engines. Python/PHP output remains optional.
Explicit `psc generated build --engine js|ts|rust|wasm-core` currently publishes
JS. Other generated publication targets, component/provider dispatch and final
release qualification remain incomplete; allFourEngineSelfHostQualified=true
does not imply allFourEngineReleaseQualified=true. No registry release is claimed.

1. Reconcile the promoted package/full CI, record exact production commits,
   artifact/tarball hashes and successful gate; fix an actual failure if any.
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
