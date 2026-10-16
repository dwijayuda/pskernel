# PSCV0 M2+A — live work state

Updated 16 October 2026. **M2+A OPEN.** User-owned public compiler/formal-verification repository `dwijayuda/pskernel`.

## Contract

GitHub connector/cloud Linux CI ONLY; no local files/checkouts/shell/build/tests/Desktop Commander. Native portable `.lean`; official Lean 4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Study corresponding pinned source before substantial changes. Only propext/Quot.sound assumptions. No sorry/admission, weakened gates, higher budgets, pskernel-core, self-hosting, compiler-source `.ps` migration or C5 execution. App fixtures allowed. GC Wasm internally; linear memory only explicit ABI.

Research `psc0/pscv0-v7-platform-words-research`; dev `psc0/pscv0-v7-native-lean-v1`. PR109 stays open/draft, base `psc0/pscv0-v7-m1-parser-ownership-v1`; NEVER merge. Fresh expected-HEAD/non-force writes; preserve both histories/concurrent docs. Update BOTH handoffs every slice. Order M2+A -> M3+B -> M4+C/D -> M5/E.

## Current executable and pending qualification

Compiler **71489890970049293e78f33f9f9dc3826a0074b2**, tree703c177880814740edaf49bf5ae2099c7a318d79, parentdc4a3c01. Native **38830077352/job116746591841**, independent **38830077384/job116746591874**. Latest native observation: build/parser and preceding frozen logical replays passed; abstract-platform replay running. Source/runtime/performance still pending. Fetch fresh status; never promote pending green. This receipt changes documentation only.

Rust intrinsic emission now reuses `Ps.CompilerIr.CheckTypes.psIrCheckIntrinsicSignature(op,typeArguments)` and renders signature.resultType in one typed block-local result. The IR field stores TYPE ARGUMENTS, not a result type. The first attempt dc4a3c01 FAILED compilation in38829386400/38829386386; its API mistake is corrected and documented. No duplicated typing table, new runtime helper, cast, extra clone, operand-order change or test modification. Checked codegen renaming already traverses intrinsic type arguments and reserves internal result names. See docs/PSCV0_M2_RUST_INTRINSIC_RESULT_TYPES_2026-10-16.md.

## Previous runtime evidence, not current acceptance

Native38827509921/job116738299607 at fe702130: build/parser/assets/source/Standard/solver/default/source-info/modules and GC/core/components PASS; JS/TS each1,069 shared observations PASS; both32/64 platform families35 probes each PASS on V8/Wasmtime/JS/TS/Rust. Rust shared application E0282 at application.rs:15589 (__ps_array_empty_with_capacity without inferable element type); native repeated Wasmtime/performance SKIPPED. Thus1,069 all-backend is not yet confirmed.

Compact cloud diagnostic38828783509/job116742409590 at afc619b8 extracted original logs/artifact12016012693, digest sha256:159ccb002c743b1c25d8fa3add7eaa3d046b950aa85b739b0a0bb47a1f980181. Diagnostic success is not compiler qualification. `.github/workflows/psc0-ci-diagnostic.yml` extracts completed-run failures/PASS markers/manifest/performance without enormous source dumps or local files; default currently38827509921.

fe702130 corrected WIT assertions to compare exact tool-normalized scalar signatures, accepting valid %value escaping without relaxing widths/types/arity. Generic Subtype Nat getNumBits correction3405c32a now executed both widths. Independent38823906736 passed3405c32a. Tactic synthesis be634b5 passes nested-rfl refusal unchanged. Preserve isolated global-default theorem/native oracle and typed-scalar shared fixture.

## Measured scope and acceptance documents

Profile `pscv0-v7-native-bounded/73`:3,599 declarations,39 classes,355 ordinary instances,13 defaults. FNV10704736494700616048; declaration SHA256 a7a45451faa0d1724642590262bda91d12ff49b6f711abd2f6255f883a5a8b1f; surfacev3 SHA256117f2692ea15046020e113cd0454c5befa73479ec43e9923cafcbfc1e2031ed8. Source4 checked programs/92 phase-specific refusals; instance growth2 generators/3 candidates at1/8/32 edges; generalized6 answers/1 generalized/1 freshened/6 generators. Prior JS/TS1239 declaration mappings/52 generated-parent origins.

The live roadmap is now concise and separates current dependency/acceptance criteria from historical status. BOTH prior roadmap texts are preserved byte-for-byte in the linked RESEARCH_HISTORY and DEVELOPMENT_HISTORY files; no historical evidence or gate was dropped. The existing M2_A_EXIT_REVIEW inventory remains applicable, with its older pending paragraphs superseded here. Runtime observations do not prove global backend preservation or whole-Lean elaborator equivalence.

## Integration preparation

Last dev e6183db9ddeeb532cdad3c3aae8c3396c99574b9; common base ac3887d173347d6f39356f93b646976941212b3f. Dev's TEN changed docs are both handoffs, v7.1/v7.2 refs, README, scalar note, roadmap, three audits. Preserve all six refs/README/audits and qualified F4 scalar receipt byteexact; reconcile handoffs and the new live roadmap, which already preserves both old roadmap blobs. Re-fetch heads, preserve two-parent history. New partial/unsafe/fixpoint design proposals do not expand selected scope. No dev update or PR-setting change yet.

A draft manifest wording blob326187da8d1f2dc683e1799f488e92718df01753 was diff-verified in unreferenced commit8aa3c378: ONLY7 additions/4 deletions describing later-phase unqualified boundaries; no hash payload, registry or admission change. It is NOT on research. Adopt only after full research green, as part of exact-integration qualification.

Finish current native source/kernel/module/all-backend/Wasmtime/performance gates, obtain actual metrics, reconcile exits, then history-preserving integration and EXACT-integration native plus applicable independent F1/F2/F3-F4. Update draft PR and both handoffs. Last all-green dev f1bb4bb8 had978 observations/native38793307283 and replays38793307234/38793307180/38793307143. M2+A/fullv7 remain open until current evidence supports their respective gates.
