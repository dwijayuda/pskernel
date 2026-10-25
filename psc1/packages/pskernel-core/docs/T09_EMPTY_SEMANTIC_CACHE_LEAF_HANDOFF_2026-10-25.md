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

## Current verified status and next action

[Run40158333460](https://github.com/dwijayuda/pskernel/actions/runs/40158333460), attempt1, job121064387870 passed at experiment `80182d1b95894fc3daa5c7fbcfe8b1a7adb687d9`. Both leaves passed authentic207 and canonical207 declarations, all eight fixed source inputs, generated syntax, unchanged1884 and new21 controls. The two actual runtime receipts match. The actual42 new labels are the exact21-label sequence twice.

The job independently checked both raw input ZIP digests and all13compiler/18native extracted files, including all69 ordered proofs. The new output artifact12585423993 has136files,5226483ZIPbytes,SHA256 `adf655c16ab115565e3bbeb8204cc2d1d25c8fa98b495d0bd8849926986e4d63`; its output contents have not yet received a separate download audit. The baseline generated JS is360259bytes/SHA256 `47c320361a197b3bfe4eeb16c7a95375ceed26869375d1fd941ed7c2cb34021e`; candidate is360611bytes/SHA256 `067b7c540f340ccfc12b730156f5fdee0fa288ec4b784640f788a8e1eec0d554`.

Full native evidence is `qualification/T09_EMPTY_SEMANTIC_CACHE_NATIVE_e5039725.json`; leaf evidence is `qualification/T09_EMPTY_SEMANTIC_CACHE_LEAF_80182d1b.json`. Both scope boundaries remain explicit. Integration is separately qualified20224 and does not contain this candidate.

Next implement the committed `T09_EMPTY_SEMANTIC_CACHE_MICROBENCH_PROTOCOL.md`: fourteen fixed cases,56fresh sequential ABBA processes, exact Node binary, fixed calls, full producer artifact verification before timing, and no full-kernel build. No performance measurement has run. Preserve the original whole-kernel four-case regression experiment, fresh full correctness qualification and independent artifact verification as later adoption gates.

This helper change does not establish Church acceptance, Init.Prelude completion, full Arena conformance, overall performance qualification or complete kernel correctness. A remains historically scoped T01F qualified; B OPEN, C FAIL, D OPEN. The held transform optimization remains excluded.
