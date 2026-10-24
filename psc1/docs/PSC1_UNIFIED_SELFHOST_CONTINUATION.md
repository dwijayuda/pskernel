# Continue PSC1 from the measured Rust and installed CLI checkpoint

Use connected GitHub tools and Linux GitHub Actions only. No local repository
files, checkout, builds or tests. Fetch fresh PR178 and branch
feat/psc1-unified-selfhost-20261024 before expected-HEAD non-force writes.
Read AI_WORK_STATE.md, the roadmap, PSC1_RUST_NAT_RUNTIME_QUALIFICATION_2026-10-25.json
and PSC1_GENERATED_PACKAGE.md. No merge or registry publication.

Implementationdaa735017e34ee94da79d747c363237b4adbc4ef passes full40141923929
(job121017656399/final gate121021324743), all37 Practical Core criteria/seven
targets/both grammars/apps/native+optional packages. Tested mergeec90dc12 and
reviewdaa73501 share treeb58461d31dd53d217c1353b4373d4a87bf5e9d65.
Later documentation commits preserve compiler source closure
07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af.

FIRST inspect the existing frozen request2d27f1428e6a53a6de5006f950fc94f2d471b214,
parent9f24e3ac2a21a5faa1bf4a64b9225076fa52e681 on
qualification/psc1-rust-nat-runtime-20261025:
run40141718481/job121014751809. It was still active at2026-10-24 23:52UTC.
Do not duplicate/cancel/change an active request. Read completed logs only,
then verify immutable artifacts and real G2/G3 admissions/IR/source/raw bytes/
four-output observations. Record exact elapsed time and service RSS separately
from supervisor RSS. An intentionally killed diagnostic is not qualification.

The new Rust-only correctness-3600s profile is explicitly authorized; only
G2-self/G3-self get3600000ms. G1/corpus/build tools240000ms, checker120000ms,
190-minute job and170-minute qualification step. Existing1800s correctness/
240s performance profiles, semantic fuel, memory/stack, independent Lean4.35,
strict IR and negative/source pairing requirements remain unchanged.
A longer correctness pass grants no240s performance badge.

If the frozen run fails, diagnose its exact archived producer and request late
in the failing phase. The original profile40138165186 showed BigUint clones/
drops in StringEq and decimal literal parsing in JSON/admission/IR checks.
Promoted fixes use exact u64-range BigUint literals, unchanged larger fallback,
borrow immutable Nat operands, and optimize pinned numeric dependencies only.
No experimental LLVM flags are promoted. Do not retry unchanged source blindly,
increase unrelated limits, add logical assumptions or delegate compilation to
the native compiler.

The isolated optimization/psc1-lexer-string-suffix-20261025 branch has code
31e102637ed1984c71c96906fbbd3dc2fd8bf6d4/state39f38d64. Run40143764706/
job121020712723 passes all-input original-wrapper equality, retained320
comparisons/100001 tokens per grammar, both120-module censuses and actual
admitted Rust lexer probes on real compiler files. Stage-only gains include
CheckedAdmissions4039->439ms and Rust.Expr3001->341ms. It is NOT promoted, NOT
a full G1/G2/G3 qualification and NOT proof of whole-G2 speedup. Keep the
primary frozen while its chain runs. If relevant after a terminal failure,
promote with full native/G1 and genuine-generation gates on its changed root.

If Rust passes, preserve its exact frozen source and integrate the qualified
asset, then qualify other engines on that same root. Preserve historical v2
TS/Wasm request812094c1/closure92654df5 and v1 JS/TS sourceb2ab4d34 on their own
sources; never transfer fixed points across changed closures. Current installed
distribution deliberately labels this boundary and allFourEngineReleaseQualified=false.

Installed current candidate40144094413/job121021665068 passes offline install,
both engines/grammars, JSON+CLI modules,44 observations and14 negatives, with the
native compiler removed throughout generated compilation. Artifact12579329783
contains core and matching Python/PHP tarballs. ZIP
fa1321d92b4a3bece88e726a60ffbda77343116d04c28fb476770e2793b76322;
core203c7b58ec8e1b3c6aaa0cdaa5ead0aff942a9b4beb7ed1e865f83779ae5e3f0.
Packaging source isdaa73501; native sourceec90dc12; qualified G3 engines are
historical TS/Wasm closure92654df5. Generated path publishes JS initially.
Native targets and optional output providers remain available. Broaden generated
targets/components/provider integration only through the existing host admission,
strict IR, pinned assets, transactional publication and explicit ABI refusals.

Genuine Linux qualification command (inside controlled CI only):
```sh
lake build psc1_rust_nat_literal_tests psc1_codec_static_schema_tests psc1_unified_service_seed psc1_unified_service_tests psc1_independent_checker psc1_source_census_probe
node scripts/unified-selfhost-request-tests.mjs
node scripts/rust-nat-literal-tests.mjs
node scripts/generated-target-source-audit.mjs rust unified
node scripts/generated-target-qualification.mjs rust --self-host correctness-3600s unified
```

Launch only after a fresh, separately reviewed source/control checkpoint using
a request-only commit with the exact parent. Existing request schema fields:
schema=psc1-unified-selfhost-request/1, action=qualify-independent-G1-G2-G3,
mode=--self-host, profile=correctness-3600s, g1TimeoutMs=240000,
g2g3TimeoutMs=3600000, targets=["rust"], branch=<actual guarded branch>,
parentCommit=<fresh exact control HEAD>. Other engines retain their supported
separate profiles. Preserve every failed attempt and successful historical run.

Update AI_WORK_STATE.md, the single roadmap and canonical receipts with actual
results and pending boundaries. Finish clean reproduction/final release and
separate performance qualification before any authorized release. Formal compiler
preservation/DDC and unsupported platforms remain separate claims.
