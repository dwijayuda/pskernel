# PSCV0 M2+A — research qualification complete; integration pending

Updated 16 October 2026. The selected M2+A implementation has passed the complete research pipeline. **M2+A final acceptance remains OPEN until exact integration qualification.**

## Contract

User-owned public compiler/formal-verification repository dwijayuda/pskernel. GitHub connector/cloud Linux CI ONLY; no local files/checkouts/shell/build/tests/Desktop Commander. Native portable `.lean`, official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc; study pinned source before substantial changes. Only propext/Quot.sound assumptions. No sorry/admission, weakened gates, larger budgets, pskernel-core, self-hosting, compiler-source `.ps` migration or C5 execution. Wasm GC internally; linear memory only explicit ABI. Application fixtures allowed.

Research psc0/pscv0-v7-platform-words-research; development psc0/pscv0-v7-native-lean-v1. PR109 stays draft/open, base psc0/pscv0-v7-m1-parser-ownership-v1; NEVER merge. Fresh expected-HEAD/non-force writes; preserve both histories/concurrent docs. Update BOTH handoffs each completed slice. Order M2+A -> M3+B -> M4+C/D -> M5/E.

## Completed research gates

Executable71489890970049293e78f33f9f9dc3826a0074b2:

- Native38830077352/job116746591841 completed SUCCESS, all33 reported steps including setup/cleanup. Source/kernel/typed-IR, frozen assets, Standard/solver/source-info, three-module, GC/core/components, JS/TS/Rust, repeated native Wasmtime/post-return and existing compiler/collection performance all PASSED. No stage remains pending or skipped.
- Independent F3/F4/platform38830077384/job116746591874 SUCCESS at7148989.
- Independent F1 run38831491203/job116751050169 and F2 run38831491147/job116751050177 SUCCESS at8fc8154f43f1cd88923044d6af72be9eb7467b40, which changes only documentation and F1/F2 research-branch triggers relative to7148989. Compiler/proof assets identical.
- F1 canonical model SHA256 aa427f06d0645a1e1a360710103766d1043fbb9875ae10d2a4104545baf6029179; constructor SHA256 a3b176361dcdc411a1110c4ceb308c6793d01fa0f9a2182a81959a766fe4b9b00d. F1 artifact12021637160 digest sha256:f73887dc3d7c9e3b2662051dd53e0165a8bdcce87f07234524f6ef3d005f37d0.

This receipt retargets the read-only compact CI diagnostic to completed native38830077352 so exact final observation counts, Standard manifest and measured performance can be extracted without enormous native logs. Diagnostic success is not compiler qualification. Retrieve its new run and record artifact metrics before integration.

## Corrections and measured scope

Rust intrinsic emission now reuses authoritative psIrCheckIntrinsicSignature(op,typeArguments) and existing type renderer for a typed block-local result; no operand/once-only/ownership/helper/test change. The first dc4a3c01 attempt misread the IR type-argument field and failed compilation;7148989 corrects it and the existing Rust runtime gate now passes. See M2_RUST_INTRINSIC_RESULT_TYPES design. Earlier fe702130 fixed valid WIT %value escaping with exact normalized signature comparison;3405c32a fixed generic Subtype Nat platform erasure. No assertions, budgets or logical assumptions were weakened.

Prior manifest: profile73,3,599 declarations/39 classes/355 instances/13 defaults; FNV10704736494700616048; declaration SHA256 a7a45451faa0d1724642590262bda91d12ff49b6f711abd2f6255f883a5a8b1f; surfacev3 SHA256117f2692ea15046020e113cd0454c5befa73479ec43e9923cafcbfc1e2031ed8. Prior1,069 JS/TS observations,35 platform probes per32/64 profile; now all runtime stages pass, but copy final numeric receipts from the new diagnostic rather than extrapolating.

## Integration still required

Read concise roadmap and M2_A_EXIT_REVIEW. Both historical research/development roadmap texts are preserved byteexact in linked history files. Reconcile existing selected criteria with actual green results, not a new scope or duplicated test inventory.

Last dev e6183db9ddeeb532cdad3c3aae8c3396c99574b9, common base ac3887d173347d6f39356f93b646976941212b3f:37 concurrent dev commits change TEN docs. Preserve six reference/README/audit files and qualified F4 scalar receipt byteexact; reconcile both handoffs/live roadmap and retain archived journals. Fetch fresh heads and compare. Newer partial/unsafe/fixpoint design proposals are not automatic selected-profile admission.

After final research metric extraction, integrate BOTH parents and preserve all concurrent docs. Verified unreferenced manifest wording blob326187da8d1f2dc683e1799f488e92718df01753 (commit8aa3c378) changes only descriptive later-phase boundaries, not hashes/registries/admission; it can accompany integration and must be tested there. Qualify EXACT integration commit with native/F1/F2/F3-F4, then update draft PR and both handoffs with final acceptance. No development ref or PR settings changed yet. Do not declare fullv7/C5/global backend preservation/self-hosting. Existing performance measures compiler phases and generated-JS collections versus native Lean, not Rust runtime performance.
