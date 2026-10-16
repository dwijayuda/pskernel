# PSCV0 — M3+B runtime qualification and performance investigation

Updated 16 October 2026. The user requests M3+B implementation and deep performance diagnosis/fixes. M2+A is COMPLETE; M3+B remains OPEN.

## Working contract

User-owned public repository `dwijayuda/pskernel`. GitHub connector and cloud Linux CI ONLY: no local filesystem, checkout, shell, builds, tests or Desktop Commander. Native portable `.lean`; official Lean 4.35.0 at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Study matching pinned sources before substantial changes. Approved assumptions are only `propext` and `Quot.sound`. No sorry, unchecked admission, weaker gates, larger budgets, pskernel-core, self-hosting, compiler-source `.ps` migration or C5 execution. Wasm GC internally; linear memory only at explicit ABI boundaries. Coherent shared mechanisms and focused validation.

Development: `psc0/pscv0-v7-native-lean-v1`; old research is retained. Fresh expected-HEAD/non-force writes; preserve concurrent histories. Update BOTH handoffs after completed slices. PR109 remains draft/open on its original base `psc0/pscv0-v7-m1-parser-ownership-v1`; NEVER merge. Order M3+B -> M4+C/D -> M5/E, with the requested measured optimization alongside relevant dependencies.

## Accepted baseline

Integration `2a7072064974cb0d051a1773a26caf15fc59838b`, acceptance receipt `280e1e4e6b18e4f1ac17a1a6297602250ca27e2e`. Native 38832366451 (all 33 reported steps), F1 38832366381, F2 38832366374 and F3/F4/platform 38832366314 all passed that integration. Artifact 12018546813; digest `sha256:6eb7d1fbe2bcb3ee8c95613406f24e4ec7d42d7c1314c9beacd43e8035b67dbe`. The final M2+A receipt preserves full evidence. Do not repeat M2 integration.

Baseline: 1,069 observations each JS/TS/Rust, 35 probes per 32/64 profile, and 3,599 declarations / 39 classes / 355 instances / 13 defaults. The historical 247x–3,158x ratios concern generated-JS collection microbenchmarks versus native Lean, not native compiler throughput or Rust execution.

## Current source and exact qualification

Implementation `77627e5c0e8a10a48a2631fdf426cfa2a1feb847`; roster correction/current compiler candidate **`133af061d6aaff0eb6ed990abd341ca2a44d15e9`**. Candidate tree `46d6d6e4c1b1bd01f90710efa32e609cd4d6996f`.

- Initial native 38838501700 / job 116772905192 stopped before compilation: the new `Ps.BackendEcma.Sync` was missing from the portable Lake roots. No guard was relaxed. The correction registers that module in the existing library.
- Current native **38838737641 / job 116773647886**. Latest observation: compilation, parser/native cases, all preceding logical assets, source/Standard and module emission passed; GC/runtime/component qualification was running. Later TS/Rust/native-host/performance stages remain pending. Fetch fresh status; this is NOT a completed qualification claim.
- This handoff commit is documentation only. Do not attribute the candidate's eventual qualification to a different compiler SHA.

## Implemented slice

`Ps.BackendEcma.Sync` checks the actual lowered AST for suspension and fails closed at the existing budget. `Lower` emits ordinary synchronous lambdas/scopes/declarations and supports uniform generic self-tail/alias loops. Type-changing and general dynamic/non-tail calls retain the stack-safe fallback. No primitive representation, logical assumption, ABI or registry change.

The existing native performance harness includes focused uniform/type-changing/alias/callback/budget/direct-lambda recognizer checks, plus one officially checked generic `.ps` recursion fixture with Nat/Bool payloads at 100,000/50,000 steps. Original performance operations, counts, checksums and sample counts remain unchanged. These new runtime results are pending until the measurement stage runs.

## Diagnosis and next work

Baseline study 38837301337 / job 116769178297 at `c9279d8a` executed accepted artifact 12018546813. Longer checksummed batches still measured approximately 37.63 ms for listTail, 22.01 ms for fromList and 28.58 ms for toList at size 8,192. Generator/closure/scheduler/GC costs are observed. The hidden `.study` upload was skipped; the logs exist, but no study artifact was published. Repair publication before the paired run.

Read `docs/PSCV0_M3_B_RUNTIME_SLICE_2026-10-16.md`, `PSCV0_M3_B_SOURCE_REVIEW_2026-10-16.md` and the initial execution/performance note. The source review compares the actual TypeScript 7.0.2 transform, pinned Lean mutual/recursor/deriving implementation and inspected PSC0 owners. It separates source findings, background references and planned implementation; it does not claim full M3 coverage.

Next: finish exact native qualification, then run the same-runner baseline/candidate study using a successful native artifact and fix hidden-file publication. Record actual gains or regressions. Continue shared mutual/nested data, motives, total recursion and deriving; do not substitute a TypeScript rewrite or unchecked partial deriving for those mechanisms. No full M3 or production-performance completion is claimed.
