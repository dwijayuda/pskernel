# PSCV0 M2+A — completed and accepted

Updated 16 October 2026. **Selected M2 + Phase A is COMPLETE for `pscv0-v7-native-bounded/73`.** All required exact integration workflows passed and the final artifact evidence is recorded. The authoritative receipt is [M2+A integration qualification](docs/PSCV0_M2_A_INTEGRATION_QUALIFICATION_2026-10-16.md); [exit review](docs/PSCV0_M2_A_EXIT_REVIEW_2026-10-16.md) reconciles every selected criterion. Do not restart M2 implementation or repeat integration based on stale pending snapshots.

## Working contract

User-owned public compiler/formal-verification repository dwijayuda/pskernel. GitHub connector/cloud Linux CI ONLY; no local files/checkouts/shell/build/tests/Desktop Commander. Native portable `.lean`, official Lean4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Study pinned source before substantial changes. Only `propext`/`Quot.sound`; no sorry/admission, weaker gates, larger budgets, pskernel-core, self-hosting, compiler-source `.ps` migration or C5 execution. Wasm GC internally; linear memory only explicit ABI. Application fixtures are allowed. Prefer shared clean mechanisms and focused validation, not test-fix hunting.

Dev `psc0/pscv0-v7-native-lean-v1`; research `psc0/pscv0-v7-platform-words-research`. PR109 stays draft/open, base `psc0/pscv0-v7-m1-parser-ownership-v1`; NEVER merge. Fresh expected-HEAD/non-force writes, both histories and BOTH handoffs every completed slice. Established order: M2+A -> M3+B -> M4+C/D -> M5/E; this task closes M2+A only.

## Exact qualified integration and evidence

Qualified executable/integration SHA: **`2a7072064974cb0d051a1773a26caf15fc59838b`**. Both parents preserved: development `e6183db9ddeeb532cdad3c3aae8c3396c99574b9` and research `8cd3b9fe4a29da36f8fde96f1771d0198f356cc9`. Concurrent reference/README/audit/scalar files and both historical roadmap journals are retained. The only additional `.lean` change relative to qualified research7148989 was descriptive later-phase StandardManifest wording, with no registry/hash/admission change; the exact integration independently passed.

All SUCCESS at that same SHA:

- Native [38832366451](https://github.com/dwijayuda/pskernel/actions/runs/38832366451), job116753779387, all33 reported steps including setup/cleanup; completed2026-10-16T01:16:49Z.
- F1 [38832366381](https://github.com/dwijayuda/pskernel/actions/runs/38832366381), job116753778925.
- F2 [38832366374](https://github.com/dwijayuda/pskernel/actions/runs/38832366374), job116753778916.
- F3/F4/platform [38832366314](https://github.com/dwijayuda/pskernel/actions/runs/38832366314), job116753778799.

Read-only diagnostic38835057984/job116762208483 at research54575d2a extracted actual integration artifact **12018546813**, digest **sha256:6eb7d1fbe2bcb3ee8c95613406f24e4ec7d42d7c1314c9beacd43e8035b67dbe**. It is evidence extraction, not qualification. This acceptance revision changes only documentation: do not label a later receipt SHA as the tested compiler SHA. Fetch fresh HEAD before any further writes.

## Confirmed selected results

Integration observed **1,069 each JS/TS/Rust**, **35 probes per32/64 target profile** across JS/TS/Rust/V8/Wasmtime, three-module JS/TS/Rust and four-module GC execution, **1,239 declaration mappings/52 generated-parent origins**, repeated native Wasmtime/post-return, source4 checked/92 phase-specific refusals and separate typed-do/opaque boundary suites. Instance growth retained2 generators/3 candidates at1/8/32 edges, transitions7/21/69; generalized6 answers/1 generalized/1 freshened/6 generators. These are tested fixtures, not global preservation/complexity proofs.

Manifest: **3,599 declarations/39 classes/355 instances/13 defaults**; approved propext/Quot.sound; selected deriving Inhabited/BEq/DecidableEq/Repr/Hashable. FNV10704736494700616048; declaration SHA256 `a7a45451faa0d1724642590262bda91d12ff49b6f711abd2f6255f883a5a8b1f`; surfacev3 SHA256 `117f2692ea15046020e113cd0454c5befa73479ec43e9923cafcbfc1e2031ed8`.

Integration prelude5668ms; indexed128-definition elaboration88ms/kernel28ms/erase91ms/emit100ms. Integration generated-JS/native-Lean microbenchmark ratios **247.09x–3157.89x** remain a substantial performance limitation, NOT production speed, parity, optimization improvement or no-regression acceptance. The benchmark checks output equality and records timings, not a speed target or Rust runtime performance. Keep earlier research metrics labeled research; exact tables are in the separate final receipt.

## Research provenance, corrections and next boundary

Research71489890970049293e78f33f9f9dc3826a0074b2 passed native38830077352 and independent38830077384; source-identical8fc8154 passed F1 38831491203/F2 38831491147. Research diagnostic38832102110/artifact12017362168 and its distinct performance measurements remain documented in [research qualification](docs/PSCV0_M2_A_RESEARCH_QUALIFICATION_2026-10-16.md).

Preserve the qualified generic Subtype Nat getNumBits erasure3405c32a, exact WIT percent-identifier handlingfe702130, existing instantiated IR signature result typing7148989, tactic-owned synthesis and isolated default theorem/native oracle. No implementation or test changes were required during final closure.

There are **no remaining selected M2+A acceptance blockers**. Broader data/termination/deriving belongs to M3+B; effects/specifications/proof automation to M4+C/D; incremental/tooling/validated optimization/performance/C5/global integration to M5/E. Those remain open and were not started by this closure. Fullv7, all Lean extensions, general backend preservation, release performance, pskernel-core and self-hosting are not claimed. PR109 is a continuing draft, not a release/merge action.
