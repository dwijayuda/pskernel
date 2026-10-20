# PSC1 current work state — qualified architecture foundation

Updated 2026-10-21. Branch: research/psc1-ultra-qualified-20261021.
Draft [PR #169](https://github.com/dwijayuda/pskernel/pull/169) continues preserved
[PR #168](https://github.com/dwijayuda/pskernel/pull/168) at
7e25943b991446ee2ab5a32b445238ef5af47cb5. Earlier #162/#163/#165/#166/#167
branches and histories remain intact. No main merge, release or npm publication.

## Exact qualification

Implementation 5496943a30423269654fffcd7579b3c5dd16b4f9 passed [scoped Linux 39495181966](https://github.com/dwijayuda/pskernel/actions/runs/39495181966)
and [focused native 39495181847](https://github.com/dwijayuda/pskernel/actions/runs/39495181847).
Tested merge: a4e3b9bd626c36437557b58f5e7dfb3c477fcf39. See the immutable
[foundation receipt](docs/PSC1_ULTRA_FOUNDATION_QUALIFICATION_2026-10-21.json).
The commit saving this work state is a documentation descendant; do not invent
its self-referential hash or silently transfer qualification across later code changes.

Reproductions are preserved: #168 run39490333445 failed the reverse handler
roundtrip; 8ad97dcc6fdfd3e6f8bebab8d77e895b4b5093ba run39492745046
reproduced the shared handler-loop mismatch, WIT keyword and TS prototype-field
defects while its native roundtrip workflow39492745174 passed. Corrected fixture
checkpoint9196093342837d816f9c328ff90e275476324e28, run39494671024, reached
actual DirectJS intrinsic-global and TS prototype-field mismatches in both
authored grammars. It was superseded/cancelled after reproduction, not qualified.

## Corrected and implemented

- Terminal compound do expressions retain grouping through Lean/PS/Lean
  translation without weakening dedented match/catch ownership.
- Pattern-let fallthrough remains outside a preceding catch, including later
  finite-loop iteration errors. Native Lean oracle and seven-target comparisons
  remain separate from logical admission.
- Shared erasure allocation prevents source bindings from capturing emitted
  ECMAScript intrinsics while retaining logical names, property labels,
  collision safety and source origins.
- TypeScript uses computed quoted data keys. Special-name structure construction
  and record literals execute independently under JS/TS in both authored grammars;
  constructor table/payload changes also retain ordinary constructor coverage.
- The direct Bool component plan rejects the exact pinned WIT keyword set.
  Owned component bytes, actual embedded core, WAT/interface validation,
  deterministic output and refusal-preserves-publication are exercised.
- Generated JS/Rust admission transport runs against the external official
  checker. It is transport only; candidate graph comes from native stage0.
- Compiler-source census records exact source/import identity, phase-specific
  refusals and first actionable diagnostics. Qualification aggregates all new
  receipts and refuses missing/mismatched evidence.

## Architecture and remaining boundary

Retain one shared AST/elaborator, canonical Core and checked expression IR.
Official Lean4.35.0, commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc, is the
active independent admission authority; owned PSKernel-Core is separately native-tested.
Ordinary source/body pairing, strict IR, target/ABI validation and atomic publication
remain mandatory. Verified requests refuse. No behavioral preservation theorem.

All fourteen full Practical Core families remain incomplete. The bounded
fourteen-family selection and exact acceptance policy are in
[decisions](docs/PSC1_PRACTICAL_CORE_DECISIONS.md) and
[parity](docs/PSC1_LANGUAGE_BACKEND_PARITY.md). Typed IO, Prop order decisions,
efficient optional indexing/finite iteration, Rust callbacks in aggregates,
and full compiler source acceptance remain concrete work.

Live census: semantic-compiler 67/40/35; directjs-compiler 79/48/41; rust-compiler 83/49/40 (modules/parse accepted/elaboration accepted). Current probe covers Lean parse/elaboration only;
independent admission, IR, generated compiler execution and repeated generations
remain not-run. Do not confuse a completed diagnostic with accepted source closure.

Wasm retains GC internals and qualified Bool-only component ABI. The
[Wasm v2 plan](docs/PSC1_WASM_ARCHITECTURE_V2.md) requires explicit linear-memory
Canonical ABI adapters before compound public values; no GC-native ABI claim.
Python/PHP public compound ABIs and broader effects remain unavailable.

## Continue

Use the complete [Sol High prompt](docs/PSC1_SOL_HIGH_CONTINUATION_PROMPT.md).
Read the finalized audit, selfhost, interop and refactoring designs once; verify
live head/CI, then implement dependency-ordered milestones. First strict dual-grammar
compiler census and required efficient data/control; then whole-closure admission/IR;
then real generated JS compiler with native delegation disabled; then G1/G2/G3,
followed by Rust and R1/R2/R3. Broad FFI/refactoring is not a prerequisite without
a demonstrated compiler dependency. Historical lean434/PSC2 selfhost receipts
cannot qualify the current4.35 JS/Rust compiler.

Repository development and qualification remain GitHub/Linux CI only.
Use expected-SHA non-forced updates. Preserve history and existing tests/budgets;
no unchecked authority or unapproved merge/publication. Keep exact completed/pending
boundaries in this file and the [execution status](docs/PSC1_ULTRA_EXECUTION_STATUS.json).
