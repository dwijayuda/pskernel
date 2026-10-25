# T09 empty semantic cache: paired generated leaf preflight

## Fixed source identities

- Baseline kernel: `20224a295359abb201f56c72395690bf0bfac9fa`.
- Candidate kernel: `e503972553ae2d41d5ba7a26d7739fb32ee86b96`.
- Shared compiler source: `80005bb250a7324772db76d51684d23fbf0fe6ed`.
- Compiler run/attempt/job: `40149637831 / 1 / 121038541765`.
- Compiler artifact: `12581708293`, 2,420,207 ZIP bytes, SHA256 `c2d97da78b427c0f675c72568badb2897f041dabf1de82d145ada4cb9467c361`.
- Compiler executable SHA256: `13635a423d1343e9a4770be0b7e02d859a6b845b221a0363d19bfdfab8e3cc1c`.
- Candidate native69 run/attempt/job: `40157229337 / 1 / 121061091716`.
- Candidate native artifact: `12585087010`, 36,747 ZIP bytes, SHA256 `47507140e234f9aebb1ab7ecef289b78c579f330e696709529b3b60a3501d0fe`.

This experiment branch inherits the candidate's native evidence checkpoint `30d9f5f5ac38d2c7af9be72da1072754a15d89ef`. Its own commit identifies the workflow, driver and additional harness. It does not replace either fixed kernel identity. The candidate remains isolated from integration.

## Execution and qualification boundary

The workflow `.github/workflows/psc1-empty-semantic-cache-leaf.yml` runs one bounded Linux job. Before code generation, the driver checks producer run/attempt/source/job status, raw ZIP size/SHA256, every extracted compiler/native evidence file, all 69 actual ordered proof reports and their source/log/status receipt chain. Extraction uses the fixed official action. This is independent raw-digest and extracted-content verification; no independent ZIP parser is claimed.

Both variants use the same authenticated compiler. Each authentic CacheAnalysis dependency closure contains exactly eight Git-authenticated Lean files. The only paired production difference is CacheAnalysis.lean. The bootstrap adapter changes exactly four execution/path anchors in the pinned repository translator script; it does not change kernel source. The experiment archives these adaptations explicitly, checks the actual Lean source, reconstructs the canonical .ps closure, verifies its complete manifest and SHA256, checks it, builds TypeScript/JavaScript, and verifies the canonical bytes remained unchanged through generation.

The detached runtime uses Node22, TypeScript7.0.2, 2048MiB old-space, a 60-second command bound and empty PATH. It executes the unchanged `pskernel-closed-cache-analysis-smoke.mjs` (1,884 assertions) and a separate `pskernel-empty-semantic-cache-smoke.mjs` (one rejection control plus twenty exact cold empty-map queries). The new matrix uses actual generated constructors, compares against the predecessor equation, and checks input immutability including own string and symbol keys. Each variant must pass 1,905 assertions; the paired semantic receipts must match. Neither native proofs nor the full kernel are rebuilt in this experiment.

## Current status and next action

The native69 source is qualified only for its focused native proof inventory; see `qualification/T09_EMPTY_SEMANTIC_CACHE_NATIVE_e5039725.json`. This containing commit introduces the paired generated preflight. No result from that preflight is claimed yet.

Inspect the matching-source run after push; do not launch a duplicate. Read actual terminal logs, variant receipts, source manifests, input artifact verification and uploaded artifact identities. Repair runner/tooling failures without changing the fixed kernel sources or weakening controls. If both variants pass, a separate bounded microbenchmark may follow using the same compiler, fixed input matrix, fresh processes and explicit ABBA order. Whole-kernel regression checks and fresh full qualification remain necessary before adoption.

This helper change does not establish Church acceptance, Init.Prelude completion, full Arena conformance, overall performance qualification or complete kernel correctness. A remains historically scoped T01F qualified; B OPEN, C FAIL, D OPEN. The held transform optimization remains excluded.
