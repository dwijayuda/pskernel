# PSCV0 M2+A — live work state

Updated16 October2026. M2+A OPEN. Repository dwijayuda/pskernel is the user's public compiler/formal-verification project.

## Contract

GitHub connector/cloud Linux CI ONLY; no local files/checkouts/shell/build/tests/Desktop Commander. Native portable .lean, official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc; study pinned corresponding source before substantial compiler changes. Only propext and Quot.sound assumptions. No sorry/admission, weaker gates, higher budgets, pskernel-core, self-hosting, compiler-source .ps migration or C5. App fixtures allowed. Wasm GC internally; linear memory only explicit ABI boundaries.

Research psc0/pscv0-v7-platform-words-research; dev psc0/pscv0-v7-native-lean-v1. PR109 stays open/draft, base psc0/pscv0-v7-m1-parser-ownership-v1; NEVER merge. Fresh expected-HEAD/non-force writes; preserve both histories/concurrent docs. Update BOTH this and AI_CONTINUE_PROMPT.md each completed slice. Order M2+A -> M3+B -> M4+C/D -> M5/E.

## Current correction and exact failed attempt

This commit corrects Rust intrinsic typing by REUSING psIrCheckIntrinsicSignature from existing Ps.CompilerIr.CheckTypes. The intrinsic IR field is TYPE ARGUMENTS, not a result type; instantiate its authoritative signature and render signature.resultType in a block-local typed result. Ordered once-only operands, ownership/liveness/clones/helpers, tests, assumptions and budgets are unchanged. Read docs/PSCV0_M2_RUST_INTRINSIC_RESULT_TYPES_2026-10-16.md. Pinned Lean IR/LLVM typed-binding and official Rust E0282/let references studied; no LLVM dependency added.

Parent dc4a3c01c9b5972df65e1f6481d7a6c50a030dfe FAILED compilation: native38829386400/job116744364477 and candidate38829386386/job116744364195. Exact error Expr.lean:93:48: List PsVerifiedIrType supplied to psRustEmitType expecting one PsVerifiedIrType. The first attempt incorrectly treated type arguments as a result type. This correction must receive fresh CI; do not label the first attempt qualified.

## Last runtime qualification

Native38827509921/job116738299607 at fe702130e6a1e12c529b4fd592db954f096b8493: build/parser/assets/source/Standard/solver/default/source-info/modules and GC/core/components PASS; JS and TS each1069 shared observations PASS; both32/64 platform families35 probes each PASS on V8/Wasmtime/JS/TS/Rust. Rust shared application E0282 at application.rs:15589, __ps_array_empty_with_capacity has an uninferred element type. Native repeated Wasmtime/performance SKIPPED. Thus1069 is NOT yet all-backend qualified.

Compact read-only diagnostic afc619b81406647b55c58e8ea30973680f0658df/run38828783509/job116742409590 extracted original logs and artifact12016012693 (sha256:159ccb002c743b1c25d8fa3add7eaa3d046b950aa85b739b0a0bb47a1f980181). It is not qualification. Avoid enormous full runtime logs: .github/workflows/psc0-ci-diagnostic.yml extracts exact errors, PASS markers, manifest and performance from completed runs entirely in cloud. Its current default target is38827509921.

The fe702130 WIT correction compares exact tool-normalized signatures instead of rejecting valid %value spelling. GetNumBits generic Subtype Nat correction3405c32a now executed successfully both widths. Independent F3/F4/platform38823906736 passed3405c32a. Tactic synthesis be634b5 passed nested-rfl refusal unchanged. Keep isolated global-default theorem/native oracle and typed-scalar shared fixture; no abandoned global-default harnesses.

## Measured selected profile and exits

Profile pscv0-v7-native-bounded/73:3599 declarations,39 classes,355 ordinary instances,13 defaults. FNV10704736494700616048; declaration SHA256 a7a45451faa0d1724642590262bda91d12ff49b6f711abd2f6255f883a5a8b1f; surfacev3 SHA256117f2692ea15046020e113cd0454c5befa73479ec43e9923cafcbfc1e2031ed8. Source4 checked programs/92 phase-specific refusals; instance-growth2 generators/3 candidates at1/8/32 edges; generalized6 answers/1 generalized/1 freshened/6 generators. JS/TS1239 declaration mappings/52 generated-parent origins.

Read docs/PSCV0_M2_A_EXIT_REVIEW_2026-10-16.md and existing roadmap; old pending-run paragraphs are superseded here. Inventory covers selected deriving, scoped synthetic/default/instance-key/replay invariants, operator protocol, source-info containment, live registries/assumptions/proof prerequisites, actual module-interface provenance and target profiles. Coherent implementations include platform words, Array.filter, strict UTF8 and constructive logic/order. Runtime observations are NOT global semantic-preservation proofs.

## Integration remains mandatory

Last dev e6183db9ddeeb532cdad3c3aae8c3396c99574b9; common base ac3887d173347d6f39356f93b646976941212b3f. Re-fetch both heads. Dev changes TEN docs: both handoffs, v7.1/v7.2 refs, README, scalar note, roadmap, three audits. Preserve six refs/README/audits byte-for-byte and its qualified F4 scalar receipt; reconcile roadmap/handoffs. Preserve both parent histories. New partial/unsafe/fixpoint proposals do not expand selected scope automatically. No dev update/PR-setting change yet.

Last all-green dev executable f1bb4bb810b2397a42ee5d04e4cc2af7dfc4c9d3:978 observations/native38793307283 and replays38793307234/38793307180/38793307143. Finish fresh research source/kernel/modules/all backends/Wasmtime/performance, reconcile exits, then two-parent integration and EXACT-integration native plus applicable F1/F2/F3-F4 qualification. Update draft PR and both handoffs with exact evidence. M2+A/fullv7 still OPEN. GitHub writes/push CI work.
