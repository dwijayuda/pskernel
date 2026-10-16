# PSCV0 — M3+B and measured performance work in progress

Updated 16 October 2026. User explicitly requested M3+B plus deep performance diagnosis and correction. M2+A is COMPLETE for pscv0-v7-native-bounded/73; do not reopen/reintegrate it. M3+B remains OPEN.

## Contract

User-owned public repository dwijayuda/pskernel; GitHub connector/cloud Linux CI ONLY. No local files/checkouts/shell/build/tests/Desktop Commander. Native portable .lean; pinned official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc; study matching pinned source/tests before substantial changes. Only propext/Quot.sound; no sorry, unchecked admission, weaker gates, larger budgets, pskernel-core, self-hosting, compiler-source .ps migration or C5 execution. Wasm GC internally, linear memory only explicit ABI. Coherent shared mechanisms and focused validation. Fresh expected-HEAD/non-force writes; preserve all histories/concurrent docs. PR109 remains draft/open on base psc0/pscv0-v7-m1-parser-ownership-v1; NEVER merge. Update BOTH handoffs every completed slice.

Active development psc0/pscv0-v7-native-lean-v1. Old research psc0/pscv0-v7-platform-words-research retains accepted provenance; do not reset it. Continue M3+B -> M4+C/D -> M5/E, with measured performance work alongside relevant dependencies as now explicitly requested.

## Accepted baseline — unchanged

Compiler integration2a7072064974cb0d051a1773a26caf15fc59838b, documentation acceptance280e1e4e6b18e4f1ac17a1a6297602250ca27e2e. Native38832366451 (all33 steps), F1 38832366381, F2 38832366374, F3/F4/platform38832366314 all SUCCESS at exact integration. Artifact12018546813; sha256:6eb7d1fbe2bcb3ee8c95613406f24e4ec7d42d7c1314c9beacd43e8035b67dbe. Complete durable evidence: docs/PSCV0_M2_A_INTEGRATION_QUALIFICATION_2026-10-16.md and exit review/roadmap. Both integration parents and all concurrent documents remain preserved.

Actual baseline:1069 each JS/TS/Rust (not identical Wasm exports);35 probes per32/64 profile;3599 declarations/39 classes/355 instances/13 defaults; checked source/modules/GC/native Wasmtime/post-return. Original JS/native-Lean microbenchmark ratios247.09x–3157.89x are historical, not a production-speed target or compiler-throughput ratio.

## New slice

Read docs/PSCV0_M3_B_EXECUTION_AND_PERFORMANCE_2026-10-16.md. Inspected benchmark, ECMA shared lowering/runtime/tail analyses, indexed Data elaborator and pinned Lean LCNF. Generic declarations are excluded from existing direct/tail lowering; other general calls use generators/WeakMap dispatch. This is a concrete optimization opportunity, not yet proof of the measured ratios' cause. Need preserve generic instantiations, evaluation/scope, higher-order callbacks and stack safety.

Added a read-only cloud study workflow: extracts the exact accepted native artifact and prints hot generated functions; dynamic checksummed longer batches, warmup, absolute timings and separately sampled CPU profiles. Its optional candidate-run input enables same-runner baseline/candidate comparison only after successful native qualification. No compiler or existing test/gate modification in this initial study slice. Fetch live workflow state; no results claimed yet.

Next: read study logs, implement and qualify conservative shared generic/direct/tail mechanisms, then execute remaining M3 data/elimination/total-recursion/deriving exits. Update the design and both handoffs with implementation SHA, exact tests and actual measurements. M3 is NOT complete, performance warning NOT solved by this initial diagnostic, and no TypeScript compiler rewrite is authorized or necessary merely because the benchmark is slow.
