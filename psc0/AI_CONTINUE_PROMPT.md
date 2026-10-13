# PSCV0 v7 — Continue M2 with Phase A and retained readable-source information

## Qualified starting point — 13 October 2026

Read live branch HEAD and latest CI before editing. Repository:
https://github.com/dwijayuda/pskernel · branch:
`psc0/pscv0-v7-native-lean-v1` · preserve draft PR
https://github.com/dwijayuda/pskernel/pull/109.

**M1 is complete for its declared selected scope.**
Executable `c00e146bd5c97788a4a6a39221849973aeafda84`;
[green Linux 38388627512](https://github.com/dwijayuda/pskernel/actions/runs/38388627512).
Later documentation commits are not newer executable qualifications.

- Official Lean 4.35.0-rc4, `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- 292 selected Standard declarations / 14 classes / 52 ordered instances.
- 175 portable / 183 native modules; profile `pscv0-v7-native-bounded/48`.
- 250 shared runtime observations; all original 198 retained; four panic cases.
- FNV `fnv1a64:5949916575031563783`.
- SHA-256 `sha256:f33d923e45baf8aa5dfa6755819737acabc09daf6d60934eb232133acaad069f`.

Kernel/RC4 oracle, negative/coherence cases, strict IR, JS/TS/Rust, V8/Wasmtime,
WIT/WAT/binary/ABI, declarations/maps and project integration all passed.
This does not complete M2, Phase A, v7, performance parity or compiler
semantic-preservation proofs.

## Recover the canonical state

Read:

1. [AI work state](AI_WORK_STATE.md), current top sections first.
2. [M1 completion and measured limits](docs/PSCV0_M1_COMPLETION_2026-10-13.md).
3. [Readable-output source/history audit and placement](docs/PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md).
4. [M0–M5 architecture](docs/PSCV0_NATIVE_LEAN_GRADE_ARCHITECTURE_REDESIGN_V1.md).
5. [A–E roadmap](docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md).
6. [M1/M2 audit](docs/PSCV0_M1_M2_IMPLEMENTATION_AUDIT_2026-10-13.md).
7. [Frozen Standard](docs/PSCV0_STANDARD_SNAPSHOT_V1.md) and
   [canonical v7 language reference](PSCV0_LANGUAGE_REFERENCE.md).

History is retained in AI_WORK_STATE and the
[prior continuation version](https://github.com/dwijayuda/pskernel/blob/b2e47ab9f5a45f6f3bdbd10db7ccb22a9bbe2a68/psc0/AI_CONTINUE_PROMPT.md).
Its instructions to finish M1 are superseded. Do not repeat qualified work.

## Accepted interleaving

M2 with remaining A; M3 with B; M4 with C/D; final M5/E.
Collect E evidence at each feature slice. Apply measured M5 improvements when
dependencies justify them.

M0 supplies typed proof/type/index erasure. M1 supplies exact selected indexing
and Standard closure. M2 strengthens elaboration/search; M3 dependent data and
total recursion; M4 class-driven effects/specs/verification obligations; M5
incremental compilation, optimization, tooling and final source presentation.

A finishes selected libraries/deriving/manifest; B dependent data and recursion;
C effects/control/IO boundaries; D checked tactics/specs/VCs; E final conformance.
Do not finish all M0–M5 before starting A–E; these are views of the same project.

## Next implementation: M2 instance-search architecture

Current `Ps.Meta.SynthInstance` provides checked invocation-local closed-answer
memoization, definitionally equivalent full-goal reuse, deterministic priority,
branch rollback, input-readiness postponement and typed Pi dictionaries.
Independent caps are 4096 goal visits and 4096 candidate checks.

**No generator/consumer waiter engine is implemented yet.** Inspect the complete
solver, InstanceTarget, Context/LevelContext, Unify, instance/local registries and
the application/elaboration constraint owners. Study pinned
[Lean/Meta/SynthInstance.lean](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Meta/SynthInstance.lean)
before design/implementation.

Replace active-cycle rejection and repeated DFS with bounded goal generators,
waiting consumers and answer propagation. Own each speculative metavariable
snapshot; never import branch-local assignments into a different branch.
Preserve local/ordered priority, fresh output parameters/output levels during
selection, and reconciliation with the caller only after selection.
Re-infer and unify replayed evidence with the exact dependent target.

Scope goal tables by environment/local instances. Pi binder introduction cannot
leak local witnesses into parent tables. Generalized term/universe answers need
sound abstraction and freshening; do not call a closed-answer graph alone full M2.
Unresolved dependent inputs, expected types, universes and defaults must ultimately
share a deterministic synthetic-constraint scheduler. Fail closed on exhaustion.

Replace obsolete search control rather than adding a second solver. Some
`psSolveInstanceMetavars` helpers are called by Application; inspect callers
before deleting. Qualify a coherent slice with minimal cycle/diamond/dependency/
priority/rollback/budget and pinned-oracle cases, plus existing integration.
Measure adversarial growth before calling full M2 complete.

Use the resulting mechanisms to extend remaining Phase A deriving/API work.
Choose the next actual capability from canonical source dependencies; do not
invent special cases solely for a synthetic search test.

## Readable output is part of the same implementation

Readable JS, TS, Rust, WAT and WIT already work for the selected native subset.
Keep shared ECMAScript lowering, Rust ownership/layout and Wasm GC/Canonical ABI
plans. Do not rebuild C0–C4b or revive historical bootstrap emitters.

C5 has bounded historical Lean/PS printers and round-trip/proof assets, but no
complete native selected-program reconstruction target. Retain information now
at its semantic owner: M2 binder groups/resolution/defaults/occurrences;
M3 patterns/motives/recursors/termination; M4 typed effects/specs/proofs.
Complete C5 printing/publication and correspondence under M5/E after required
A–D semantics exist. This supersedes blanket C5-after-all-A–E scheduling.

C5 branches from retained checked pre-erasure information, never runtime IR.
Reuse existing syntax/Doc/name/file contracts where appropriate. Preserve
comments, hygiene and explicit Standard/model correspondence; never introduce
sorry, new proof axioms or unchecked casts. Source replay alone is not C5;
checking two projections alone is not their equivalence proof.

Historical branch review found no missing full C5 implementation to merge.
The five-source/20-module closure at 0e8996d2 / Linux 38134451122 is real bounded
historical evidence, not current source authority or a self-hosting requirement.

## Preserve M1 and performance boundaries

Keep checked natural-order reflection, actual List/Array bounds, Fin adapters
preserving collection validity, exact optional dictionary lawfulness, and
nonreturning runtime bang panic. Option and generic indexing are universe aware;
selected List/Array remain Type 0. Proof automation is bounded, not full omega.

Array logical definitions and efficient runtime representation remain separate.
Keep the typed linear conversion builder/fold, family-index erasure classifier
and runtime-override trust ledger. Review intentional Standard changes before
updating FNV/SHA expectations; never weaken guards.

The M1 benchmark records substantial generated-JS overhead versus native Lean
(roughly 492–3357x for its small batches). Preserve raw workload/checksum/timing
evidence. General shared specialization/call/allocation work belongs to measured
M5 slices; no Standard-name shortcuts or high-performance parity claims.

## Execution and qualification boundaries

- Portable native `.lean`; official Lean checker; GitHub connector source edits
  and Linux GitHub Actions only. No local checkout/build or Desktop Commander.
- No pskernel-core, self-hosting, compiler-source `.ps` migration, new Rust-only
  source dialect, force push, branch deletion, main merge or unrelated redesign.
- Preserve Wasm GC internally; linear memory only at explicit ABI boundaries.
- Design from invariants and inspect the whole subsystem before broad edits.
  Implement coherent mechanisms, then focused validation and the existing
  integration gates. No test weakening or repeated full self-host loops.
- Keep exact-source distinctions between elaborated, kernel accepted, IR checked,
  emitted, runtime qualified, measured and formally proved.
- Update the TOP of AI_WORK_STATE, this prompt, roadmap and audit at qualified
  boundaries. Keep the Standard documentation aligned when its closure changes.

Start by reading live HEAD/CI and the M2 subsystem. Continue autonomously through
coherent dependency-driven slices; do not request repeated permission for
already authorized work or present a partial slice as complete v7.
