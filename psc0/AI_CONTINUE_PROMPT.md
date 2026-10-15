# Continue PSC0 / PSCV0 v7 M2 + Phase A

## 15 October — Int arithmetic asset reproduced; strict hashes measured

Integration `5cffe9280f2f2bed07eb1f1a230eb1e924160bdd` compiled and regenerated the 28-declaration Int asset **byte-for-byte** in [native CI 38705958851](https://github.com/dwijayuda/pskernel/actions/runs/38705958851). The existing strict registry guard correctly refused the previous snapshot and independently measured **fnv1a64:17912930455396537674** and **sha256:a0f90d4ba911bd9be249bd72f8f0443e582eea41f21a56d192f27efb6b24ff44**. Both values are now pinned unchanged; no check is relaxed. The separate compact Float kernel replay [38705958724](https://github.com/dwijayuda/pskernel/actions/runs/38705958724) passed at that same integration SHA.

This snapshot update still requires complete native/backend and independent Float qualification at its own commit. The expanded mask bridge is isolated on `psc0/research-float-mask-int-model-v1`, commit `cee61377f12fe465238ca5b474422e43575a3761`, [CI 38706081222](https://github.com/dwijayuda/pskernel/actions/runs/38706081222), pending at this checkpoint. No executable Float, new assumption or M2+A completion is claimed.

## 15 October — coherent Int logical arithmetic integration candidate

Baseline: `bc613bc47f63e1fd3a9f1cb714317da46d78f12f`, following qualified `7742b4cd9599af315da4a1af1ba5c8f97a6ac290` (native [38701305472](https://github.com/dwijayuda/pskernel/actions/runs/38701305472), Float replay [38701305530](https://github.com/dwijayuda/pskernel/actions/runs/38701305530)). Actual baseline Standard: **1,832 declarations /25 classes /226 instances**, FNV `fnv1a64:8516648619442707737`, SHA-256 `sha256:606ab4df1a8517d7e3323d49ee4050cadc62612e433c541fd322f44e0b626f05`. The earlier 1bc8... SHA below was a documentation error; the source and successful exact-commit CI agree on 606ab4.... Existing 699 JS/TS/Rust observations and Wasm/Wasmtime passed.

Research `ab031712d4cf75c4860bb53ae76ca753d7b61b67`, [38705122100](https://github.com/dwijayuda/pskernel/actions/runs/38705122100), independently checked **28 declarations /9 roots /1 recursor rule**, replacing exactly Int.add/neg/sub/mul computational axioms. The actual native add_zero, neg_neg, add_neg_eq_sub, natCast_add and natCast_mul proofs replay without theorem cuts or new axioms; assumptions remain exactly propext/Quot.sound. This fixes the missing logical definitions behind the earlier Int proof refusal. Native Float constructors and all Float runtime features remain separate.

Integrated candidate: exact checked asset, frozen pre-arithmetic export boundary, recorded native reducibility, required byte-for-byte regeneration, and explicit checked-runtime-model audit entries. Fast Int intrinsics remain the executable implementation; proof dependencies are not runtime support. The strict old FNV/SHA pins are intentionally retained until independent candidate measurements; do not infer new fingerprints. **Main integration is pending complete native/backend and independent Float qualification at the same SHA.**

Pinned Lean sources studied: Init/Data/Int/Basic.lean and Lemmas.lean; tests/elab/intNegSucc.lean and test_extern_int.lean. Source references/design are in the existing scalar completion document. No pskernel-core, self-hosting, C5, unchecked proofs or trust expansion. M2+A remains incomplete.


## Working contract

GitHub canonical: dwijayuda/pskernel, branch psc0/pscv0-v7-native-lean-v1,
draft PR109. Inspect actual HEAD and exact-commit CI before writes; preserve
history using non-force expected-HEAD updates. The entry above describes an
integration candidate, not acceptance. Historical audit details remain in
AI_WORK_STATE.md; use its newest entries and live evidence.

Native portable .lean, pinned Lean 4.35.0 at
eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Study corresponding official
sources/tests before each substantial feature. No Desktop Commander,
pskernel-core, self-hosting, bootstrap, compiler-source .ps migration or C5.
Wasm GC internally, linear memory only at explicit ABI boundaries.
Only propext and Quot.sound are approved; do not ask again or expand them.
Classical.choice-dependent native research is not portable proof evidence.

## Next critical path

1. Qualify the current Int arithmetic integration. Inspect native and Float
   replay results. Pin only independently measured strict Standard hashes;
   require byte-for-byte asset regeneration, original kernel admission,
   existing 699 runtime observations per JS/TS/Rust and Wasm/Wasmtime gates.
   Fix general causes, never weaken acceptance or substitute axioms.
2. Re-evaluate expanded compact Float mask/field proof closure with the actual
   checked Int definitions. The existing 26-root /100-declaration Float
   candidate already passed and is integrated; do not repeat its implementation.
   Keep speculative proof cuts on research branches. Native all-input upstream
   correspondence currently imports Classical.choice and is not selected.
3. Complete F1 selected Float32/64 source constructors, proof-carrying validity,
   shared typed erasure/IR and canonical bits; then F2 arithmetic/equality,
   F3 literals/conversions/rounding, F4 all-target ABI. Keep logical equality
   distinct from IEEE BEq, preserve signed zero, normalize NaN per pinned Lean.
4. Continue independent M2+A requirements: explicit 32/64 USize/ISize profiles,
   selected Standard APIs, deriving/search/elaboration and comprehensive manifest.
   Follow existing M2+A → M3+B → M4+C/D roadmap; no unrelated later work.

Implement coherent features then validate at meaningful milestones. Before
advancing, update BOTH AI_WORK_STATE.md and this continuation prompt with exact
SHAs, CI results, remaining limitations and next dependencies. Never declare
M2+A complete from bounded green CI or Float proof research alone.
