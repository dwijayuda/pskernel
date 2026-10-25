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
4. `checked-targets.mjs` and `transactional-publication.mjs`: pinned target consumers,
   immutable generations, pointer replacement and explicit commit outcomes.
5. `artifacts.mjs`: existing native target tooling, maps, sealed generations and
   Linux publication contract.
6. `backend-providers.mjs`: native optional Python/PHP candidate workers.

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
  and atomic current-pointer commit. Pre-commit failures preserve prior output;
  committed durability/cleanup uncertainty must be reported explicitly. Returned
  paths stay bound to the immutable generation. Other-platform commits remain refused.
- Official Lean 4.35.0 admission, strict IR, fuel, memory and stack policies remain mandatory.

## Host readability checks

The pinned Prettier/Babel check preserves the original formatting-only cleanup:
immutable cleanup 446a0f21 is compared with original baseline 3089cbc3. Live API,
CLI and resolver ASTs are compared with explicit explicit checked-target/publication feature
snapshots in Git ancestry. The guard records both relationships, rather than
calling intentional behavior changes formatting. See the dated checked-publication
qualification receipt and installed application/package tests.

Comments, positions and literal spelling metadata are ignored; executable AST
structure is retained. This bounded correspondence check is not a semantic proof.
An intentional behavior change needs its own contract and actual behavior
qualification before an explicit reviewed feature baseline update.
