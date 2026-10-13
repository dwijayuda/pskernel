# PSCV0 v7 — Continue Phase A deriving with M2 and retained source information

## Qualified starting point — 13 October 2026

Read live branch HEAD and latest CI before editing. Repository:
https://github.com/dwijayuda/pskernel · branch:
`psc0/pscv0-v7-native-lean-v1` · preserve draft PR
https://github.com/dwijayuda/pskernel/pull/109.

**M1 is complete for its declared selected scope; the first M2 graph slice is qualified.**
Executable `a98062b2ac346c66c7f687bfe7e190d12470ba4d`;
[green Linux 38398901889](https://github.com/dwijayuda/pskernel/actions/runs/38398901889).
Later documentation commits are not newer executable qualifications.

- Official Lean 4.35.0-rc4, `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- 292 selected Standard declarations / 14 classes / 52 ordered instances.
- 177 portable / 185 native modules; profile `pscv0-v7-native-bounded/48`.
- 251 shared runtime observations; all preceding 250 retained; four panic cases.
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
4. [M2 graph design, ownership and qualification](docs/PSCV0_M2_INSTANCE_GRAPH_2026-10-13.md).
5. [M0–M5 architecture](docs/PSCV0_NATIVE_LEAN_GRADE_ARCHITECTURE_REDESIGN_V1.md).
6. [A–E roadmap](docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md).
7. [M1/M2 audit](docs/PSCV0_M1_M2_IMPLEMENTATION_AUDIT_2026-10-13.md).
8. [Frozen Standard](docs/PSCV0_STANDARD_SNAPSHOT_V1.md) and
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

## Next implementation: interleave Phase A deriving with M2

The bounded generator/consumer engine is implemented and qualified. Do not
restore the old active-cycle DFS or caller-reusable memo. Read:

- `Ps.Meta.InstanceCandidate`: speculative telescope preparation, checked replay.
- `Ps.Meta.InstanceSearch`: scope-owned generators, consumers, subscriptions,
  answer propagation, diagnostics and limits.
- `Ps.Meta.SynthInstance`: public facade plus Application's existing pending
  dictionary passes; those helpers still have callers.

A newly created generator has exactly one owning subscription (or the root).
Its selected descendant snapshot may return to that owner. Later subscribers
have unrelated snapshots: replay only meta-closed evidence, re-infer and unify
the exact target, never copy the donor context. Closed identical local signatures
are required for sharing. Each Pi introduction gets a fresh scope.

Preserve local/global ordered priority, fresh output arguments/output levels
during selection and post-selection reconciliation. Caller-preferred outputs
must not make lower-priority dictionaries win. Exhaustion returns the original
context. Limits: 4096 generators, 4096 candidate attempts, 32768 transitions;
default fuel 64 bounds derivation height, not host recursion depth.

Qualified compact evidence covers seeded/unseeded cycles, a diamond, conversion
reuse, Pi scope isolation, nested private-context output assignments and independent
budget refusals. Repeated dependency widths 1/8/32 use 2 generators, 3 candidates
and 7/21/69 transitions. One source oracle/runtime case yields 1466. Existing M1,
negative/coherence and all backend gates passed. This is not full Lean tabling:
generalized term/universe answers need abstraction/freshening, broader synthetic
constraints need one deterministic scheduler, and key lookup still scans linearly.

**Next capability:** inspect the complete `Ps.Elab.Deriving`, class/inductive
registration, constructor/family telescope helpers and pinned Lean deriving
implementations. The current Inhabited and BEq handlers are bounded to closed
families (BEq payloads also nonrecursive and independent). Extend parameter and
universe handling through a shared checked telescope mechanism, preserving
constructor prerequisites and local field dictionaries. Do not add blanket
requirements for unused parameters without checking the pinned semantics.
Keep indexed/recursive dependencies aligned with M3 rather than introducing
unchecked casts or ad hoc recursive witnesses.

Use real deriving needs to drive the remaining M2 generalization/constraint
work; do not duplicate existing elaboration or add a separate deriving solver.
Repr/DecidableEq/Hashable, broader scalar/APIs and the comprehensive environment
manifest remain Phase A work. Qualify coherent slices with minimal focused
checks and the existing integration gate, then update this handoff and work state.

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

Start by reading live HEAD/CI, the qualified M2 graph and the full deriving subsystem. Continue autonomously through
coherent dependency-driven slices; do not request repeated permission for
already authorized work or present a partial slice as complete v7.
