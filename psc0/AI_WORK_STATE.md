# PSCV0 M2+A — integration is now on development

Updated 16 October 2026. This research branch retains compiler7148989 and its fully green qualification. **The active remaining work is exact integration qualification on development, not another research implementation cycle.**

## Current integration and gate ownership

Development `psc0/pscv0-v7-native-lean-v1` was successfully advanced, expected-HEAD/non-force, to **2a7072064974cb0d051a1773a26caf15fc59838b**. Its verified parents are former dev **e6183db9ddeeb532cdad3c3aae8c3396c99574b9** and research **8cd3b9fe4a29da36f8fde96f1771d0198f356cc9**. Both histories and seven concurrent development reference/README/audit/scalar documents are preserved exactly. The other three changed development documents were reconciled handoffs/roadmap; both old roadmap journals are retained byte-for-byte.

Exact integration workflows are now RUNNING, not yet accepted:

- Native **38832366451**, job **116753779387**.
- F1 **38832366381**, job **116753778925**.
- F2 **38832366374**, job **116753778916**.
- F3/F4/platform **38832366314**, job **116753778799**.

All must pass the same exact2a707206 commit. Do not substitute the research run, repeat an already completed integration, reset either branch or merge PR109. PR109 was read and its body updated to this pending-integration state; it remains draft/open with base psc0/pscv0-v7-m1-parser-ownership-v1.

Read the more current development copies of `docs/PSCV0_M2_A_EXIT_REVIEW_2026-10-16.md` and `docs/PSCV0_M2_A_RESEARCH_QUALIFICATION_2026-10-16.md`. Final M2+A acceptance remains OPEN only until integration qualification and final receipts. Relative to qualified research, the only extra `.lean` change is descriptive later-phase manifest wording, no admission/hash payload change.

## Research already fully qualified

Compiler71489890970049293e78f33f9f9dc3826a0074b2: native38830077352/job116746591841 SUCCESS all33 reported steps including setup/cleanup, source, modules, all runtimes, repeated native Wasmtime/post-return and benchmark execution. Independent38830077384 SUCCESS; F1 38831491203/F2 38831491147 SUCCESS on source-identical8fc8154. Diagnostic38832102110/job116752955444 extracted native artifact12017362168, digest sha256:d56700d7e7164aa234bf561d5a07215f21e543f956a19319a41657475a90862f.

Measured1,069 each JS/TS/Rust,35 probes per32/64 profile across JS/TS/Rust/V8/Wasmtime,3599 declarations/39 classes/355 instances/13 defaults. Declaration SHA256 a7a45451faa0d1724642590262bda91d12ff49b6f711abd2f6255f883a5a8b1f; surfacev3 SHA256117f2692ea15046020e113cd0454c5befa73479ec43e9923cafcbfc1e2031ed8. Source and detailed counters are in the development research receipt.

Benchmark completion is NOT a speed-target pass: reported generated-JS/native-Lean ratios364x–3412x remain an explicit microbenchmark limitation. No timing threshold was relaxed; the existing script checks output equality and records times. Do not call this production performance or a global preservation proof.

## Contract and completion action

GitHub/cloud Linux CI ONLY; no local files/checkouts/shell/build/tests/Desktop Commander. Native portable `.lean`, official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc; pinned source study before substantial changes. Only propext/Quot.sound. No sorry/admission/weaker gates/larger budgets/pskernel-core/self-hosting/compiler-source `.ps` migration/C5 execution. Wasm GC internally, linear memory explicit ABI. Preserve draft PR/base/history. Update BOTH handoffs each slice.

On exact integration green, retarget the research read-only diagnostic workflow to completed38832366451, extract final receipts, then update development acceptance/roadmap/both handoffs/PR and point research handoffs to the final development checkpoint. Existing diagnostic default is38830077352; do not run it on unfinished jobs. M3+B -> M4+C/D -> M5/E remain later; no fullv7/Lean-wide/global-preservation/C5/self-host completion claim.
