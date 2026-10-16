# PSCV0 M2+A — all exact integration workflows passed

Updated 16 October 2026. Development integration `2a7072064974cb0d051a1773a26caf15fc59838b` has passed all four required workflows. The remaining action is recording its final exact artifact evidence and acceptance on development, not another compiler implementation or integration cycle.

## Exact successful integration

Development branch: `psc0/pscv0-v7-native-lean-v1`. Two preserved parents: `e6183db9ddeeb532cdad3c3aae8c3396c99574b9` and research `8cd3b9fe4a29da36f8fde96f1771d0198f356cc9`. All concurrent reference/README/audit/scalar files and both historical roadmap journals were preserved. PR109 remains draft/open with base `psc0/pscv0-v7-m1-parser-ownership-v1`; never merge.

Live GitHub check-runs confirmed SUCCESS on the same exact integration SHA:

- Native [38832366451](https://github.com/dwijayuda/pskernel/actions/runs/38832366451), job116753779387; completed 2026-10-16T01:16:49Z, including repeated native Wasmtime, measurements, artifacts and cleanup.
- F1 [38832366381](https://github.com/dwijayuda/pskernel/actions/runs/38832366381), job116753778925.
- F2 [38832366374](https://github.com/dwijayuda/pskernel/actions/runs/38832366374), job116753778916.
- F3/F4/platform [38832366314](https://github.com/dwijayuda/pskernel/actions/runs/38832366314), job116753778799.

This slice changes only the two default run IDs in the existing read-only compact diagnostic and both research handoffs. It targets the now-completed integration run38832366451. No compiler, proof, fixture, qualification command, permission, timeout or budget changes. Diagnostic success is evidence extraction, not a replacement for qualification.

## Final closure action

Read the diagnostic triggered by this workflow-only push, capture its exact native artifact ID/digest, manifest and performance measurements, then update development's M2+A acceptance/exit review/roadmap/BOTH handoffs and PR109 body. Point both research handoffs at the final development receipt. Read fresh refs and preserve concurrent changes. Do not substitute research performance numbers for this integration's measurements or rerun an already successful qualification merely to change pending prose.

## Existing research evidence and limits

Research compiler71489890970049293e78f33f9f9dc3826a0074b2 passed native38830077352 and F3/F4/platform38830077384. Source-identical8fc8154 passed F1 38831491203 and F2 38831491147. Research diagnostic38832102110 extracted artifact12017362168, digest sha256:d56700d7e7164aa234bf561d5a07215f21e543f956a19319a41657475a90862f. Full research receipt and criterion reconciliation are in development `docs/PSCV0_M2_A_RESEARCH_QUALIFICATION_2026-10-16.md` and `docs/PSCV0_M2_A_EXIT_REVIEW_2026-10-16.md`.

Research observed1069 each JS/TS/Rust,35 probes per32/64 profile across JS/TS/Rust/V8/Wasmtime,3599 declarations/39 classes/355 instances/13 defaults. Declaration SHA256 a7a45451faa0d1724642590262bda91d12ff49b6f711abd2f6255f883a5a8b1f; surfacev3 SHA256117f2692ea15046020e113cd0454c5befa73479ec43e9923cafcbfc1e2031ed8. Research generated-JS/native-Lean microbenchmark ratios364x–3412x are an explicit limitation, not a speed-target pass, production performance or a universal comparison. Integration metrics must be recorded separately.

## Working contract

User-owned public compiler/formal-verification repository dwijayuda/pskernel. GitHub connector/cloud Linux CI ONLY; no local files/checkouts/shell/build/tests/Desktop Commander. Native portable `.lean`, official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc; study pinned source before substantial compiler changes. Only propext/Quot.sound. No sorry/admission/weaker gates/larger budgets/pskernel-core/self-hosting/compiler-source `.ps` migration/C5 execution. Wasm GC internally, linear memory explicit ABI. Fresh expected-HEAD/non-force updates; both histories and BOTH handoffs every slice. Selected bounded73 qualification is not fullv7, all Lean extensions or global compiler preservation. M3+B -> M4+C/D -> M5/E remain later work; this task only closes M2+A.
