# PSCV0 M2+A — completed; final authority is on development

Updated 16 October 2026. **Selected M2 + Phase A is COMPLETE for `pscv0-v7-native-bounded/73`.** Research implementation, qualification, history-preserving integration, all four exact integration gates and the final evidence/acceptance records are complete. Do not restart this milestone or repeat integration from older pending research paragraphs.

## Final development checkpoint

Development branch: `psc0/pscv0-v7-native-lean-v1`.

- Qualified integration: **`2a7072064974cb0d051a1773a26caf15fc59838b`**.
- Documentation-only acceptance child: **`280e1e4e6b18e4f1ac17a1a6297602250ca27e2e`**.
- [Final integration qualification](https://github.com/dwijayuda/pskernel/blob/280e1e4e6b18e4f1ac17a1a6297602250ca27e2e/psc0/docs/PSCV0_M2_A_INTEGRATION_QUALIFICATION_2026-10-16.md).
- [Accepted exit review](https://github.com/dwijayuda/pskernel/blob/280e1e4e6b18e4f1ac17a1a6297602250ca27e2e/psc0/docs/PSCV0_M2_A_EXIT_REVIEW_2026-10-16.md).

The acceptance diff was inspected: only five Markdown files, including roadmap and BOTH development handoffs; no compiler/proof/test/workflow/gate changes. PR109 body now records accepted selected M2+A and remains draft/open/unmerged on base `psc0/pscv0-v7-m1-parser-ownership-v1`. Both integration parents e6183db9 and8cd3b9fe, concurrent documentation and both historical roadmap journals are preserved.

## Exact integration receipts

All SUCCESS on2a707206: native [38832366451](https://github.com/dwijayuda/pskernel/actions/runs/38832366451)/job116753779387; F1 [38832366381](https://github.com/dwijayuda/pskernel/actions/runs/38832366381)/job116753778925; F2 [38832366374](https://github.com/dwijayuda/pskernel/actions/runs/38832366374)/job116753778916; F3/F4/platform [38832366314](https://github.com/dwijayuda/pskernel/actions/runs/38832366314)/job116753778799. Native passed all33 reported steps including setup/cleanup, source/modules/GC/runtimes/native Wasmtime/post-return/measurements/artifacts. Completed2026-10-16T01:16:49Z.

Research read-only diagnostic [38835057984](https://github.com/dwijayuda/pskernel/actions/runs/38835057984)/job116762208483 at54575d2a extracted actual integration artifact **12018546813**, digest **sha256:6eb7d1fbe2bcb3ee8c95613406f24e4ec7d42d7c1314c9beacd43e8035b67dbe**. It is evidence extraction, not a replacement qualification. The diagnostic default remains the completed integration run. No further diagnostic or qualification run is needed merely to update these pointers.

Integration:1069 each JS/TS/Rust;35 probes per32/64 profile across selected JS/TS/Rust/V8/Wasmtime lanes;3599 declarations/39 classes/355 instances/13 defaults;1239 declaration mappings/52 generated-parent origins; source4 checked/92 refusals plus boundary suites; three-module JS/TS/Rust/four-module GC execution and native repeated calls/post-return. Do not relabel1069 as identical Wasm exports.

Integration prelude5668ms; indexed128 elab88ms/kernel28ms/erase91ms/emit100ms. JS/native-Lean microbenchmark ratios247.09x–3157.89x remain a substantial limitation, not production-speed/no-regression or Rust-performance acceptance. The unchanged benchmark checks outputs and records times. Older research artifact12017362168 and364x–3412x research ratios remain separately attributed in the research receipt; use development's final tables for integration.

## Preserved research and working contract

Research retains compiler71489890970049293e78f33f9f9dc3826a0074b2, native38830077352/F3-F4-platform38830077384 successes, source-identical8fc8154 F1 38831491203/F2 38831491147 successes, and diagnostic38832102110. Older research exit/roadmap snapshots are historical; final status and subsequent dependency plan are on development. Do not reset or delete either branch or duplicate integration.

User-owned public compiler/formal-verification repository dwijayuda/pskernel. GitHub connector/cloud Linux CI ONLY; no local files/checkouts/shell/build/tests/Desktop Commander. Native portable `.lean`, official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc; study pinned source/tests before substantial compiler changes. Only propext/Quot.sound. No sorry/admission/weaker gates/larger budgets/pskernel-core/self-hosting/compiler-source `.ps` migration/C5 execution. Wasm GC internally, linear memory explicit ABI. Fresh expected-HEAD/non-force updates, both histories and BOTH handoffs per slice. PR109 stays draft; NEVER merge.

There are no remaining selected M2+A acceptance blockers. M3+B -> M4+C/D -> M5/E remain later work and were not started by this closure. No fullv7, Lean-wide equivalence, global compiler preservation, release performance, C5 or self-hosting completion is claimed. Continue from development only when further implementation is requested.
