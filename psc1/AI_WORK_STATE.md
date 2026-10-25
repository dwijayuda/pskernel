# PSC1 AI work state

Updated 2026-10-26 Asia/Jakarta. Active branch:
`feat/psc1-portable-checked-publication-20261026`, stacked on PR #187 at
`563ee855407581d0d34adcbc450ad77863f39f94`.
Use connected GitHub and Linux Actions only; refresh HEAD before writes, preserve
single-parent non-force history. No merge, registry or release publication is authorized.

The [roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) owns the remaining queue.
[Previous complete checkpoint](docs/history/AI_WORK_STATE_BEFORE_CHECKED_PUBLICATION_2026-10-26.md)
preserves PR #187 verbatim. Current changes are implemented but still qualifying;
do not call this a final qualification receipt.

## Implemented and current validation

- Portable canonical `current.json` layout, explicit opt-in alongside the preserved
  default legacy `current` symlink layout. Complete immutable generations,
  before/after resource verification, exclusive lock, stale-writer refusal,
  sealed inventory, file/directory fsync and one pointer-replace commit point.
  Public builds return immutable artifact/runtime paths.
- Distinguish pre-commit refusal from post-commit durability or cleanup uncertainty.
  Killed publishers leave diagnostic locks; unsafe automatic takeover is refused.
  Readback verifies exact manifest and complete inventory, and rejects symlinked
  generation roots. A recorded pointer does not prove power-loss durability.
- Actual Linux transaction run40236426372/job121298892084 passed the first fault,
  tamper, immutable-reader, stale-writer and SIGKILL cases. Extended tests add
  directory creation, reader-path and actual lock-cleanup failure cases; pending.
- Same private checked session now supports JS, TS, Rust and Wasm-core output.
  All four existing generated executors and both grammars remain supported.
  TS uses optional TypeScript7.0.2 plus its separately pinned native SDK package.
  Rust uses an optional Linux x64 consumer, locked BigInt dependencies, Syn2.0.106
  syntax/API inspection and exact external Rust1.90.0 SDK pins.
  Wasm reuses the existing typed import-free GC transport; callback ABI refuses.
- Diagnostic40236689438 passed every old installed regression and real complete
  compiler native/Wasm admission, then found missing TS native SDK in the offline
  package set. Focused40237315097/job121301530073 identified the exact dependency;
  it was included/pinned without weakening strict type checking.
- Locked Rust consumer diagnostic40237315097/job121301529891 passed. It is target
  consumer evidence, not yet checked Rust publication qualification.
- Extended transaction40237646865 exposed a reader name-shadowing mistake, fixed
  in e3266f82. Preserve the failed run as diagnostic evidence.
- Pinned formatting proposal40237692529/job121302676882 preserves executable AST
  for six host modules. The historical cleanup3089cbc3→446a0f21 AST proof stays
  separate from intentional target/publication changes.
- Current installed qualification runs execute actual published scalar/Unicode/IO
  outputs, real Rust consumers, SDK corruption/refusal and immutable prior paths,
  then all existing 264 application, 24 consumer/eight ABI-refusal and public-type
  regressions. Record terminal results before claiming success.

## Preserved compiler and policies

No portable Lean compiler source changed. Reuse all four qualified G3 payloads:
122 modules /4742 members, closure
`073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9`.
Same-source JS/TS/Wasm G1/G2/G3/fixed points:40223062370; Rust:40223086966.
Qualified prior npm0.1.0-psc1.5:40230101814. Prior source37/37:40230721977.
Exact identities remain in the archived checkpoint and dated receipts.

Official Lean4.35.0 commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
trust0, heartbeat/recursion bounds, actual independent admission, strict original
and transformed IR, ordinary source/logical pairing, semantic fuel, memory,
stack/lifetime limits and negative tests are unchanged. Compiler/tools240s,
checker120s; manual G2/G3 profiles and original240s performance target unchanged.
Default kernel remains official C++/Emscripten linear-memory Wasm. Compiler Wasm
retains GC. Python/PHP and all seven native mappings remain preserved.

The later scalar expansion found an integration delimiter defect in Rust public
value inventory parsing (40237884483): literal backslash-n instead of newline.
Fixed1b0e695e with the same exact expected API comparison, live per-case output
and archived immutable stores. Direct pinned native TypeScript execution9c9e8ef4
keeps its whole compiler invocation inside240 seconds. Current qualification is
still active; the first Nat-only four-target/engine/grammar and actual Rust link
suite in40237499042 has passed, with full existing applications still active.

## Next steps and explicit bounds

Finish active installed and normal dependency-selected source CI, fix actual
failures, then record exact source/job/artifact/package identities and update this
state/roadmap. Do not rerun unchanged G2/G3 chains for host-only packaging changes.
MacOS/Windows publication, additional target SDK platforms, Wasm component/provider
dispatch, source-package automatic resolution and final clean universal release
remain incomplete. Linux-only CI does not establish other-platform qualification.
Compile-only staging and readonly inventory do not acquire publication authority
or inherit the Linux-only commit guard. No semantic preservation proof is claimed.
