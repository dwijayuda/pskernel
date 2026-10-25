# PSC1 host tools

This directory owns host orchestration and resource/publication policy. It does
not implement another semantic compiler or replace independent checking.

## Read in this order

1. `installed-engine-resolver.mjs`: resolve only closed installed engine/kernel
   selections; verify exact package versions, manifest/resource bytes and source pins.
2. `compiler-host-protocol.mjs`: bind captured source identity to the exact canonical
   admission request and actual independent checker response.
3. `generated-compiler-session.mjs`: private pending/executed/published session,
   strict response checks, original/transformed IR verdicts from the pinned compiler,
   independent admission, target/API checks and publication.
4. `artifacts.mjs`: existing native target tooling, maps, sealed generations and
   Linux publication contract.
5. `backend-providers.mjs`: native optional Python/PHP candidate workers.

The installed API in `../npm-cli/universal.mjs` composes the first three.
The CLI accepts a single source file or a project object with only
`entryModule`, `sources` and optional `assurance`.

## Invariants a refactor must preserve

- Source/wire/project metadata cannot select arbitrary tools, output paths or plugins.
- Resource bytes are checked against trusted distribution pins before/after execution.
- Default Wasm checking never falls back to native on absence, refusal or corruption.
- Candidate emission grants no independent admission or publication authority.
- Source bytes use fatal UTF-8 decoding; BOM bytes are captured rather than silently removed.
- G1/compiler requests remain 240 seconds and checker requests remain 120 seconds.
  Longer self-host correctness profiles do not change installed compilation policy.
- Linux publication uses the existing lock, complete immutable generations, fsync
  and atomic current-pointer commit. A failure preserves previously published output.
- Official Lean 4.35.0 admission, strict IR, fuel, memory and stack policies remain mandatory.

## Host readability checks

The scoped Prettier/Babel AST check compares the installed resolver, API and CLI
against immutable baseline 3089cbc369bc8a11f540c13140c7003c9dadf4a8.
Comments, positions and literal spelling metadata are ignored in that comparison;
executable AST structure is retained. Installed package tests still exercise actual
behavior, integrity refusals and publication failures.

The baseline comparison is a bounded guard for this cleanup, not a permanent ban
on behavior changes or a proof of JavaScript semantics. A future behavior change
must explicitly update its contract and evidence rather than silently repinning it.
