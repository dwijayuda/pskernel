# PSC0 AI work state — PSCV0 readable-source bridge candidate

## Current implementation and evidence (2026-10-11)

Branch: `psc0/pscv0-readable-selfhost-v1`, created from adoption checkpoint `b64a95e4537dade93462e0232b5da54d79f9cb25` on `psc0/npm-modular-packages-v1`.
Current implementation checkpoint: `960692ed256f88e24cc03e7c5cd2b15e8ca67362`.

Native source run [38097055425](https://github.com/dwijayuda/pskernel/actions/runs/38097055425), job `114345006285`, **passed**: all four portable bridge modules type-check under Lean4.34.0; five PS/readable-Lean/PS round trips, four refusal cases and exact commented-source replay passed. The output contains native `do` syntax, not expanded match scaffolding.

Native artifact: `11685979857`, SHA-256 `6822d5d919d0a2024901474d209fff52f63adef54bca68ab5cfb8f563b0edd5e`.

The retained self-hosted compiler build in [38097055403](https://github.com/dwijayuda/pskernel/actions/runs/38097055403), job `114345006338`, was **in progress** when this state was written. Its native precondition and pinned-runtime installation passed. Read its actual jobs/logs before claiming a generated bridge, Windows conformance, RC4 correspondence or any new self-host qualification. No previous generated-bridge run passed.

## Authority and invariant boundaries

The uploaded `Lean4_ProofScript_PSCV0_Lean435rc4_Expanded_Lean_First_Unified_Language_Reference(2).md` is the selected future source-language reference: 230234 bytes, SHA-256 `a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0`. RC4 semantic pin: `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.

The original npm branch, main, kernel source, JS kernel adapter, compiler seed and stable CLI remain unchanged. Existing 69 compiler source files and the 64-module main compiler closure are not rewritten or requalified in this slice. New source additions are isolated under `packages/syntax/src/Ps/Syntax/Pscv0/`; adding these modules is NOT evidence that the old whole compiler now implements all PSCV0.

The retained builder is actual self-hosted PSC0 JavaScript from successful npm run `38075437516`, source `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`, artifact `11678641329`. Its manifest and tarball hashes are checked before installation. TypeScript7.0.2 is retained. Existing kernel runtime is used only for fixture checking, not regenerated.

No backwards-compatible old-PS option is being added to the future language. The old source-specific compiler and seed remain immutable bootstrap evidence. The bridge is written in the old seed-consumable `.lean` subset until it can itself compile readable authoring forms; this does not redefine the future user language.

## Implemented bounded capability

`declaration-except-do/1`: high-level declaration-body `do`, identifier/wildcard binds, immutable lets, term actions and terminal returns for an explicitly identified builtin `Except` result. Paired PS-braced and native-Lean-layout readers/printers preserve `do` intent. Separate lowering creates existing match/let/Except applications. Original source replay is exact; canonical printing with unanchored comments refuses explicitly.

Canonical owners:
- `Pscv0/Surface.lean`: source representation, printing primitives and hygienic lowering.
- `Pscv0/Read.lean`: balanced token/position do-sequence reader.
- `Pscv0/Commands.lean`: declaration header and explicit result-type delimiter ownership.
- `Pscv0/Module.lean`: complete capture, declaration/body association, paired views and semantic lowering.

No general monads, nested do, early returns, mutation, loops, exceptions, new classes/tactics, empty-call completion, richer projections/updates or complete comment formatter is claimed. Public `psc` does not yet select this bridge. Full compiler migration to authoritative `.ps` remains later work.

Implementation contract: [PSCV0_EXCEPT_DO_BRIDGE.md](docs/PSCV0_EXCEPT_DO_BRIDGE.md).
Validation ledger: [PSCV0_BRIDGE_VALIDATION.md](docs/PSCV0_BRIDGE_VALIDATION.md).
Capability record remains a candidate until generated-source tests and reference gates pass.

## Validation strategy and costs

The workflow first type-checks the new source and executes cheap native round trips. Then the retained C0 parses each new raw module before preparing unchanged dependencies. Its pure per-module preparation reports the exact failure phase. Only syntax/foundation modules plus the bridge are compiled, not the whole compiler/kernel. Existing prefix preparation was approximately six minutes in prior runs; do not rerun it for a source candidate with a known fast-native failure.

After emitted bridge JS exists, run `pscv0-bridge.test.mjs` against the actual generated module; compare source round trips, fixture admission streams and runtime behavior, with explicit negative cases. Windows reuses exactly that emitted bridge. An independent RC4 lane checks a theorem relating the actual generated readable and lowered fixture functions. Do not substitute native behavior for generated-JS qualification.

No full C2/C3 cycle, kernel rebuild, source authority switch or selected-seed promotion has been executed. Existing exact-source guards and tests are not relaxed or casually repinned.

## Recorded failures — retain their meaning

- `38094720290`: invalid job-level runner.temp expression; no code executed.
- `38095004877`: old C0 rejected expression cons sugar `::`; all new expression constructors normalized to List.cons, patterns retained.
- `38095258615`: native lane missing actual Foundation.List build prerequisite.
- `38095425532`: native Module source used reserved local names syntax/prefix; changed to sourceModule/importPrefix.
- `38095954154`: C0 raw preflight passed; elaboration rejected unqualified Option constructor values. Fixed the entire family to Option.none/Option.some.
- `38096114909`: native round trip exposed generic parser treating the last result-type argument before := as named assignment. Fixed declaration/type grammar ownership, not the example or test.
- `38095954144`: earlier native type-check-only success; not behavioral or generated-bridge success.

## Continuation rules

Read live branch HEAD and latest exact CI jobs. Preserve history and concurrent changes using expected-HEAD non-force updates. GitHub/cloud execution only: no local repo checkout/build/test, Desktop Commander, npm publication or main merge. Kernel work belongs to the other branch.

Finish this bounded bridge before adding further features. If the retained C0 still declines a new source form, identify its general bootstrap capability boundary and normalize the new source without altering old compiler semantics or relaxing tests. If a broader compiler change is required, document it as a separate qualification boundary rather than relabeling this candidate successful.

The preceding complete adoption state is retained at [AI_WORK_STATE_BEFORE_PSCV0_BRIDGE.md](docs/history/AI_WORK_STATE_BEFORE_PSCV0_BRIDGE.md). The original reference remains in the user attachment; the repository adoption record identifies it by hash, not a claimed verbatim repository copy.
