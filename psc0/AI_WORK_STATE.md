# PSCV0 — M3+B runtime slice awaiting qualification

Updated16 October2026. User requests M3+B plus deep performance diagnosis/fixes. M2+A is COMPLETE; M3+B remains OPEN.

## Working contract

User-owned public dwijayuda/pskernel; GitHub/cloud Linux CI ONLY. No local files/checkouts/shell/build/tests/Desktop Commander. Native portable .lean; official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc; study matching pinned source/tests. Only propext/Quot.sound; no sorry/admission, weakened gates, larger budgets, pskernel-core/self-hosting/compiler-source .ps migration/C5. Wasm GC internally, linear memory explicit ABI. Coherent mechanisms/minimal focused tests. Fresh expected-HEAD/non-force writes; preserve history/concurrent docs; update BOTH handoffs. PR109 draft/open, original base psc0/pscv0-v7-m1-parser-ownership-v1; NEVER merge.

Active dev psc0/pscv0-v7-native-lean-v1; old research retained. Order M3+B -> M4+C/D -> M5/E, with requested measured optimization alongside dependencies.

## Accepted M2+A baseline

Qualified integration2a7072064974cb0d051a1773a26caf15fc59838b; docs acceptance280e1e4e. Native38832366451(all33),F1 38832366381,F2 38832366374,F3-F4 38832366314 all SUCCESS. Artifact12018546813 digest sha256:6eb7d1fbe2bcb3ee8c95613406f24e4ec7d42d7c1314c9beacd43e8035b67dbe. Final M2+A receipt/exit/roadmap preserve full evidence and both histories.1069 each JS/TS/Rust,35 probes/profile,3599/39/355/13 environment counts. Historical247x–3158x collection ratios are not compiler speed or Rust measurements.

## New implementation candidate

Read docs/PSCV0_M3_B_EXECUTION_AND_PERFORMANCE_2026-10-16.md and PSCV0_M3_B_RUNTIME_SLICE_2026-10-16.md. Initial study commitc9279d8a launched38837301337/job116769178297; checksummed study completed with real generator/closure/GC costs. Initial hidden .study artifact publication was skipped; repair publication, do not claim an artifact exists.

This candidate adds Ps.BackendEcma.Sync (actual lowered-AST suspension analysis), removes unnecessary generators from synchronous lambdas/scopes/declarations, and extends the existing tail mechanism to uniform generic instantiations/aliases with type-changing fallback. General calls and higher-order/non-tail recursion retain the scheduler. No new representation/assumption/ABI/registry change. Source/intrinsic budgets unchanged. Details and pinned Lean sources in runtime-slice note.

Focused recognizer checks run inside existing native performance harness; one officially checked .ps generic m3Keep fixture tests100000 Nat/50000 Bool steps. Existing benchmark operations/counts/checksums are unchanged. This candidate is NOT qualified until its complete native pipeline passes. Fetch the live SHA and CI before claiming results.

Next: qualify exact candidate; obtain successful native artifact; paired baseline/candidate study on one runner (fix include-hidden-files). Record actual improvement or regression, not historical ratios across machines. Then continue shared dictionary/closure specialization where profiles justify it and M3 nested/mutual/data/motive/recursion/deriving exits. Neither full M3 completion nor resolution of all performance warnings is claimed.
