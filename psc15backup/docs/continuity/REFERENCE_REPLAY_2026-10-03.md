# Preserved checked compiler replay

The declarations-only compiler API at `bfab5af09c8269654410ec9f4ceaceb008dcfbe0`
completed one generated compiler replay of its exact 72-module source snapshot.
The explicit Lean WASM reference checked the admissions before the frozen
prepared module was emitted. The generated compiler reproduced the native
TypeScript and admissions bytes exactly, in 4,623,240 ms.

| Artifact | SHA-256 |
| --- | --- |
| Original source closure | `38fec582939f5b0e02a15d6f479efbae6d5d5e90f44faa9b294ce29586f29ac3` |
| Canonical admissions | `b995916150ae010f36af0c13d4aafaf590fb4eddcf6b512cf9c80920863faed4` |
| TypeScript, parent and generated child | `bb79d8a39be9a879ba18d3ede2f567dd32f3c17fd056974a368058063bafed93` |
| JavaScript, parent and generated child | `7fef852ddb121af7867809118743015f88564d9a3a5e991b55660352536e705d` |
| Exact checked native seed | `8d527c8557867f1eaadef2a5b6a4cd0ea795b807b2df7501f2a24a4dfdde1d22` |

The child JavaScript was compiled with pinned TypeScript 5.8.3, strict checking,
declarations and source maps, using the same options and basename as the parent.
Its bytes match the parent, including generated kernel code in that closure.
This is a reference-checked compiler result; the owned kernel did not admit the
complete source declarations.

All 72 source modules were also translated to canonical ProofScript by both the
native compiler and this generated child. Their bytes match for every module;
generated ProofScript-to-ProofScript re-emission is unchanged for every module.
The preserved native checked seed compiled these canonical modules through the
explicit WASM checker, reproducing the same admissions and TypeScript hashes.

The generated child's full checked compilation of the canonical modules is the
next replay. It runs independently from current development. The complete
documented generation sequence and owned joint release are not marked passed.

## Preservation and commands

All paths below are relative to the enclosing local task workspace, outside the
development Git checkout. Existing replay outputs were not overwritten.

- `work/checked-declarations-reference-17b4ff82-v2/`: exact snapshot, source,
  seed, patch, native compiler, generation-one TypeScript/admissions/result and
  `generation1-compiled/verification.json`.
- `work/replay-declarations-reference.cjs` and `.log`: original replay command
  and full log. It exited successfully; elapsed time includes observational CPU
  profiling, which did not replace semantic results.
- `work/replay-declarations-emission.cpuprofile` and
  `work/replay-declarations-emission-late.cpuprofile`: two non-pausing samples.
- `work/verify-reference-generation1.cjs`: strict compilation and JavaScript
  byte comparison.
- `work/verify-reference-canonical72.cjs` and
  `work/check-reference-canonical-native.mjs`: canonical-source and native
  reference checks. Results are in `work/reference-canonical72-bfab5af0/`.
- `work/replay-canonical-reference.cjs` and `.log`: the subsequent generated
  ProofScript replay, retaining its own admission and emission artifacts.

The original protected checkout `work/pskernel` and the earlier compiler/kernel
handoff snapshots remain separate. Current kernel development neither overwrites
their source nor substitutes a newer compiler into the preserved replay.
