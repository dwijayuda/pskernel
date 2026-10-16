# PSCV0 M2+A — live work state

Updated 16 October 2026. **M2+A OPEN pending full research and integration qualification.**

## Working contract

User-owned public compiler/formal-verification repository dwijayuda/pskernel. GitHub connector/cloud Linux CI ONLY; no local files/checkouts/shell/build/tests/Desktop Commander. Native portable `.lean`; official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Study pinned source before substantial changes. Only propext/Quot.sound assumptions; no sorry/admission, weakened gates, higher budgets, pskernel-core, self-hosting, compiler-source `.ps` migration or C5 execution. Wasm GC internally; linear memory only explicit ABI. Application fixtures allowed; minimal focused validation.

Research psc0/pscv0-v7-platform-words-research; dev psc0/pscv0-v7-native-lean-v1. PR109 stays draft/open with base psc0/pscv0-v7-m1-parser-ownership-v1; NEVER merge. Fresh expected-HEAD/non-force writes, preserve both histories/concurrent docs. Update BOTH handoffs each slice. M2+A -> M3+B -> M4+C/D -> M5/E.

## Current compiler and parallel qualification

Compiler71489890970049293e78f33f9f9dc3826a0074b2 is unchanged. Native38830077352/job116746591841 has passed compilation, parser, all logical asset replays, checked source/Standard and three-module emission; GC runtime step23 is running. JS/TS/Rust/native repeated Wasmtime/performance remain pending at this receipt. Independent F3/F4/platform38830077384/job116746591874 completed SUCCESS on this exact compiler.

This commit adds ONLY the active research branch to the existing F1/F2 workflow branch lists, plus these handoffs. Each workflow has one changed line; all commands, proof inputs, comparisons, permissions, pins, paths and budgets remain unchanged. Their new independent replays can run in parallel with the existing native runtime gate. Native workflow's path filter excludes these F1/F2 workflow files, so it is not cancelled/restarted. Fetch their runs for this commit, and fetch current native status before declaring success. This closes a research CI trigger omission, not a semantic gap or new test corpus.

Rust emission uses `Ps.CompilerIr.CheckTypes.psIrCheckIntrinsicSignature(op,typeArguments)` and the existing type renderer for one typed block-local intrinsic result. Operand ordering, once-only evaluation, ownership/clones/helpers and tests remain unchanged. The first attempt dc4a3c01 misread the IR field and failed compilation;7148989 corrects that and compiles. See docs/PSCV0_M2_RUST_INTRINSIC_RESULT_TYPES_2026-10-16.md. Shared codegen already renames intrinsic type arguments and reserves internal temporary names.

## Historical runtime baseline for this correction

Native38827509921/job116738299607 at fe702130 passed source/logical/module/GC gates,1,069 JS and TS observations each, and35 probes per32/64 profile under V8/Wasmtime/JS/TS/Rust. Rust shared application then failed E0282 at __ps_array_empty_with_capacity; repeated native Wasmtime/performance were skipped. Thus1,069 is not yet confirmed all-backend. The WIT signature correction fe702130 and generic Subtype Nat getNumBits correction3405c32a now executed successfully on both widths. Preserve prior tactic synthesis and isolated global-default qualification mechanisms.

Compact diagnostic38828783509/job116742409590 extracted artifact12016012693 (sha256:159ccb002c743b1c25d8fa3add7eaa3d046b950aa85b739b0a0bb47a1f980181). Measured profile73:3,599 declarations,39 classes,355 ordinary instances,13 defaults; FNV10704736494700616048; declaration SHA256 a7a45451faa0d1724642590262bda91d12ff49b6f711abd2f6255f883a5a8b1f; surfacev3 SHA256117f2692ea15046020e113cd0454c5befa73479ec43e9923cafcbfc1e2031ed8. Prior source4 checked/92 refused, graph2 generators/3 candidates at1/8/32 edges, generalized6 answers/1 generalized/1 freshened/6 generators. Obtain final actual runtime/metrics from completed CI, not these previous receipts.

## Exit review and integration

Read the concise roadmap and M2_A_EXIT_REVIEW instead of repeating the full inventory. Commit3bb633c preserved BOTH prior roadmap journals byteexact in linked research/development history files. Its current roadmap retains original selected M2+A and later B–E criteria without stale stop directions. Historical pending paragraphs are superseded here.

Dev last e6183db9ddeeb532cdad3c3aae8c3396c99574b9; common base ac3887d173347d6f39356f93b646976941212b3f. Fresh comparison confirms37 dev commits modifying TEN documentation paths: both handoffs, v7.1/v7.2 refs, README, scalar note, roadmap and three audits. Preserve six refs/README/audits and qualified F4 scalar receipt byteexact; reconcile both handoffs/current roadmap, keeping both historical journals. Newer partial/unsafe/fixpoint proposals do not expand selected admission. No dev ref or PR settings changed yet.

Verified unreferenced manifest wording8aa3c378/blob326187da8d1f2dc683e1799f488e92718df01753 changes ONLY descriptive later-phase boundaries (7 additions/4 deletions), not payload hashes/registries/admission. Adopt only after research green, within exact integration qualification.

Finish all research gates, reconcile exits with actual observations/metrics, integrate with BOTH parents, then qualify EXACT integration HEAD through native plus F1/F2/F3-F4. Update draft PR and both handoffs. Runtime conformance is not global semantic preservation. Existing performance comparison measures native compiler phases and generated-JS collections versus native Lean, not Rust runtime performance. Last fully green dev f1bb4bb8 had978 observations/native38793307283 and exact replays. No whole-v7/C5/self-host completion claim.
