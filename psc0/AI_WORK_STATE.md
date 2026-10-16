# PSCV0 v7 — AI work state / regular-chat handoff

Updated16 October2026. M2+A remains OPEN. Continue actual implementation; this checkpoint supersedes stale pending runs below Git history.

## Working contract

User-owned public compiler/formal-verification repository dwijayuda/pskernel. GitHub connector/cloud Linux CI ONLY; no local files/checkouts/shell/build/tests/Desktop Commander. Native portable `.lean`, official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc; study corresponding pinned sources before substantial changes. Only propext and Quot.sound as logical assumptions. No sorry/admission, weakened gates, increased budgets, pskernel-core, self-hosting, compiler-source `.ps` migration or C5 execution. Application fixtures allowed. Wasm GC internally; linear memory only explicit ABI boundaries.

Research psc0/pscv0-v7-platform-words-research; dev psc0/pscv0-v7-native-lean-v1. PR109 remains open/draft, base psc0/pscv0-v7-m1-parser-ownership-v1; never merge. Fresh expected-HEAD/non-force writes and both parent histories/concurrent docs must be preserved. Update BOTH handoffs and relevant status every completed slice. Order M2+A -> M3+B -> M4+C/D -> M5/E; current task M2+A.

## Current compiler slice: preserve Rust intrinsic result typing

This commit changes only `packages/backend-rust/src/Ps/BackendRust/Expr.lean` plus documentation. The shared intrinsic branch previously discarded its validated result type. It now binds the existing primitive expression to an explicitly typed block-local result, using the existing Rust type renderer. This resolves return-only generic ambiguity such as nested empty arrays without a per-operation or fixture special case. Operand order, once-only evaluation, ownership/liveness/clones, runtime helpers, typed IR, assumptions, tests and budgets remain unchanged.

Study: pinned Lean `Compiler/IR/Basic.lean` FnBody.vdecl and `Compiler/IR/EmitLLVM.lean` declareVar/declareVars/emitVDecl; Rust official E0282 and let-typing reference. No LLVM dependency was introduced. Full evidence/invariants: docs/PSCV0_M2_RUST_INTRINSIC_RESULT_TYPES_2026-10-16.md. Fetch fresh native CI for this commit. It is not qualified yet.

## Exact preceding qualification

Native38827509921/job116738299607 at fe702130e6a1e12c529b4fd592db954f096b8493 completed FAILURE in step25 Rust shared application compilation. Build/parser/frozen assets, source/Standard/solver/default/source-info, real3-module, GC core/components and TypeScript/direct-JS gates PASSED. Both32/64 platform profiles passed35 shared probes each under GC/V8/Wasmtime/JS/TS/Rust. Both JS and TS passed all1069 shared application observations. Rust's platform application passed, but application.rs:15589 failed E0282 at __ps_array_empty_with_capacity: no inferable element type. Thus1069 is NOT yet a confirmed all-backend pass. Native repeated Wasmtime/performance were SKIPPED.

Read-only compact diagnostic afc619b81406647b55c58e8ea30973680f0658df/run38828783509/job116742409590 SUCCESS extracted that original result and actual manifest. Diagnostic success is not compiler qualification. Avoid enormous full native log imports; use the compact diagnostic workflow for failed context and artifact receipts.

The WIT spelling correction fe702130 reused existing tool-normalized exact scalar signatures instead of a regex rejecting valid `%value`. It preserved all expectations and enabled the GC gate to pass. Compiler3405c32a's generic Subtype Nat getNumBits layout correction now executed successfully on both target profiles. Independent F3/F4/platform38823906736/job116726744576 passed3405c32a. Earlier native38823906652 failed the WIT regex, not checkToIS or runtime width values.

## Current measured selected profile

Artifact12016012693 from38827509921, digest sha256:159ccb002c743b1c25d8fa3add7eaa3d046b950aa85b739b0a0bb47a1f980181:

- pscv0-v7-native-bounded/73;3599 declarations,39 classes,355 ordinary instances,13 defaults.
- FNV10704736494700616048; declaration SHA256 a7a45451faa0d1724642590262bda91d12ff49b6f711abd2f6255f883a5a8b1f; surfacev3 SHA256117f2692ea15046020e113cd0454c5befa73479ec43e9923cafcbfc1e2031ed8.
- Source gates:4 checked programs/92 phase-specific refusals; native instance growth edges1/8/32 kept2 generators/3 candidates with7/21/69 transitions; generalized replay6 answers/1 generalized/1 freshened/6 generators. Source-info, deriving, defaults, synthetic rollback, module/proof prerequisites and strict registries passed.
- JS/TS:1069 each,1239 declaration mappings and52 generated-parent origins. Both platform families35 probes each. Rust shared application and final performance still pending the current correction.

## Existing coherent implementation and exit review

Read docs/PSCV0_M2_A_EXIT_REVIEW_2026-10-16.md and roadmap; their older pending-run paragraphs are superseded here. Retained implementation: abstract logical platform words with explicit32/64 runtime profiles; checked polymorphic Array.filter; total strict UTF8; constructive logic/order; structural instance-key indexing and fresh scoped answer replay; retained operator identity and common expected-type/default scheduling; live notation/deriving/tactic/effect/assumption audits; saved source contexts/inserts/projections; actual checked module-interface provenance. General backend preservation is not established by runtime observations.

Prior tactic-owned synthesis correction be634b5 matches pinned Tactic/ElabTerm.lean and passes nested-rfl refusal unchanged. Keep isolated default-selection checked theorem/native oracle and typed-scalar shared operator observation; do not revive invalid global-default fixtures.

## Integration preparation — preserve all concurrent work

Last inspected dev e6183db9ddeeb532cdad3c3aae8c3396c99574b9; common base ac3887d173347d6f39356f93b646976941212b3f. PR109 independently confirmed open/draft. Dev changes TEN documentation paths: both handoffs, v7.1/v7.2 references, README, scalar note, roadmap and three audits. Preserve all six reference/README/audit files byte-for-byte from fresh dev; use its qualified F4 scalar receipt (research scalar is still identical to common base). Reconcile roadmap and current handoffs, preserve both histories. Newer partial/fixpoint/unsafe design proposals do not automatically expand this selected profile. No dev ref or PR settings changed yet.

Last fully qualified dev executable f1bb4bb810b2397a42ee5d04e4cc2af7dfc4c9d3:978 observations, native38793307283 and F1/F2/F3-F4 replays38793307234/38793307180/38793307143 all passed. Do not substitute this older baseline for current acceptance.

Finish fresh research native source/kernel/module/target32-64/JS/TS/Rust/GC/core/component/native-Wasmtime/performance gates. Reconcile M2+A exits, then integrate both histories/concurrent docs and qualify the EXACT integration HEAD with native and applicable independent F1/F2/F3-F4. Update draft PR and both handoffs with final counts/metrics. M2+A and full v7 remain OPEN. GitHub writes and push-triggered CI work; no forbidden fallback is needed.
