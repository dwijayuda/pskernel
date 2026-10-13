# PSCV0 v7 — Continue M2+A after generalized answers and synthetic constraints

## Qualified starting point — 13 October 2026

Read live HEAD and CI before editing. Repository:
https://github.com/dwijayuda/pskernel · branch:
`psc0/pscv0-v7-native-lean-v1` · preserve draft PR
https://github.com/dwijayuda/pskernel/pull/109.

Executable `c6468b17ef8f0a97c9e0df76c1ffe49f35c68279`; [green Linux 38411211335](https://github.com/dwijayuda/pskernel/actions/runs/38411211335).
Later docs-only commits do not change executable qualification.

- Official Lean 4.35.0-rc4: `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- 182 portable / 190 native modules; profile `pscv0-v7-native-bounded/48`.
- 263 shared runtime observations, retaining all earlier 260; four panic contracts.
- Standard: 292 declarations / 14 classes / 52 instances.
- FNV `fnv1a64:5949916575031563783`.
- SHA-256 `sha256:f33d923e45baf8aa5dfa6755819737acabc09daf6d60934eb232133acaad069f`.

Official kernel, independent RC4 oracle, semantic refusals, strict IR,
JS/TS/Rust, V8/Wasmtime, WIT/WAT/binary/ABI, declarations/maps and project
integration passed. **This completes a bounded M2+A milestone, not all M2,
Phase A, v7, high-performance parity or formal compiler preservation.**

## Recover canonical state

Read current top sections of:
1. [AI work state](AI_WORK_STATE.md).
2. [Generalized answers and shared constraints](docs/PSCV0_M2_GENERALIZED_CONSTRAINTS_2026-10-13.md).
3. [Instance graph ownership](docs/PSCV0_M2_INSTANCE_GRAPH_2026-10-13.md).
4. [Parameter/universe-aware deriving](docs/PSCV0_M2_A_DERIVING_2026-10-13.md).
5. [M0–M5 architecture](docs/PSCV0_NATIVE_LEAN_GRADE_ARCHITECTURE_REDESIGN_V1.md).
6. [A–E roadmap](docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md).
7. [M1/M2 audit](docs/PSCV0_M1_M2_IMPLEMENTATION_AUDIT_2026-10-13.md).
8. [Readable-output audit](docs/PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md),
   [Standard identity](docs/PSCV0_STANDARD_SNAPSHOT_V1.md), and
   [canonical v7 specification](PSCV0_LANGUAGE_REFERENCE.md).

Keep **M2+A → M3+B → M4+C/D → M5/E**. Collect E evidence and measured M5
improvements throughout. M1 is complete for its selected indexing/Standard
scope. Do not repeat qualified work or invent another milestone track.

## Current M2 owners and invariants

- `Ps.Meta.Abstract`: dependency-ordered natural term/universe templates and
  fresh opening. Template indices are private binders, not donor meta IDs.
  Each term parameter retains its allowed local scope.
- `Ps.Meta.InstanceCandidate`: speculative preparation and typed witness checks.
- `Ps.Meta.InstanceSearch`: per-invocation generator/consumer graph, generalized
  answer propagation and canonical closed answers. Earlier generalized answers
  remain available to later subscribers after a closed answer appears.
- `Ps.Meta.Synthetic`: scoped expected-type, dictionary and omitted-default
  queue; checked progress, quiescence, default phase and transactional limits.
- `Ps.Meta.SynthInstance`: facade only. The old pending-instance retry loop is
  removed; do not restore it.
- `Ps.Elab.Application` and `Proof`: shared queue callers and typed diagnostics.
- `Ps.Elab.Class`: global registration checks synthesis order and determined
  outputs through parameter-type dependency closure.

A newly created generator has one owning subscription (or root). Only that
owner may adopt the descendant context, including assignments in local
dictionary types. Other consumers open fresh answer templates in their own
snapshots and re-infer/unify the witness against their exact target. Sharing
still requires a closed identical local signature; Pi introductions get
distinct scope IDs. Synthetic/opaque obligations, delayed abstractions and
scope escapes cannot be generalized.

Preserve ordered priorities and fresh output arguments/output levels during
selection. Reconcile caller outputs only after selection; preferred outputs
must not choose lower-priority dictionaries. Root answers require no residual
term parameters. Universe parameters have separate closure/generalization rules.

Limits: 4096 generators, 4096 candidates, 4096 answers, 32768 transitions,
default evidence height 64. Queue attempts are bounded by 32768; productive
rounds remove constraints. Resource refusal returns the original state.

Omitted defaults use opaque holes, then checked explicit assignment of the
declared default. Expected types cannot replace them. Ordinary constraints
reach quiescence before defaults; retries retain individually checked progress.
A completed application requires an empty queue. Preserve mismatch versus
missing-dictionary diagnostics at this boundary.

Global instances must determine their outputs; a polymorphic local dictionary
is a different valid source of generalized answers. The independent RC4 oracle
covers both type-polymorphic and Nat-indexed local dictionary consumers.
Type-polymorphic runtime dictionary values remain outside the current
higher-rank IR: kernel acceptance and explicit erasure refusal are qualified.
Nat-indexed local dictionaries run across every existing target. Do not weaken
IR checks or introduce casts to force the higher-rank example through.

Compact graph evidence: 6 generators / 6 answers / 1 generalized answer /
1 freshened shared answer for two output specializations. Earlier repeated
dependency widths 1/8/32 still take 2 generators, 3 candidates and 7/21/69
transitions. These are bounded samples, not a general complexity proof.

## Next work in M2+A

Use real Phase A needs to drive remaining M2 work. Repr/DecidableEq/Hashable,
Inhabited structure defaults, BEq proof-field treatment, wider selected APIs and
the comprehensive environment manifest remain incomplete. Existing deriving
already shares the parameter/universe telescope and instance machinery; preserve
two-pass Inhabited selection/pruning and independent nonrecursive BEq fields.

Remaining M2 includes arbitrary postponed syntax, broader synthetic/tactic
scheduling and metavariable-depth/scoping parity, search/key scaling and C5
occurrence/decision retention. The new queue covers selected Core constraints,
not arbitrary syntax continuations or host elaborator parity.

Keep indexed/dependent/recursive deriving with **M3+B**, using general
data/transport/termination mechanisms. Higher-rank runtime dictionary values
need a deliberate shared IR/representation design, not an emitter workaround.
M4+C/D owns effects/specs/VCs; M5/E owns final optimization/tooling/source
publication and overall conformance.

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
(roughly 480–3881x in the latest retained run for its small batches). Preserve raw workload/checksum/timing
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

Start with live HEAD/CI and the current abstraction, graph, synthetic, application, class-registration and deriving owners. Continue coherent dependency-driven work; update the work state at the next qualified boundary.
