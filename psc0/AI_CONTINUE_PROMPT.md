# PSCV0 v7 — Complete remaining M2+A

## Current qualification — direct coercions and typed postponed results (13 October 2026)

Executable `35641f810e31f3c9d309c01028acd53ebe4112d9`;
[green Linux 38430940757](https://github.com/dwijayuda/pskernel/actions/runs/38430940757).
**293 shared runtime observations**, four panic contracts, **187 portable /
195 native modules**, profile `pscv0-v7-native-bounded/50`. Official RC4
kernel, independent oracle, all semantic/refusal gates, strict IR, readable
JS/TS/Rust, GC-Wasm V8/Wasmtime, WIT/WAT/components and project gates passed.

- Direct Coe, CoeFun and CoeSort use one checked class projection; no coercion
  chains or implicit lifting. Applications, annotations and expected types share
  these operations. Local dictionaries and APP-03 completion are qualified.
- Expected-term adaptation joins the transactional source/Core worklist.
  Mandatory defaults resolve before blocked result adaptation; failed attempts
  retain the original lexical scope and cannot leak assignments.
- Nonrecursive one-field wrappers whose erased uniform parameter determines
  their field use the concrete field representation. Type/proof-only fields
  erase; runtime fields depending on existential type fields remain refused.
  This does not introduce general higher-rank or existential runtime IR.

Standard: **308 declarations / 18 classes / 54 instances**, adding nine checked
coercion declarations and no global instances, axioms or primitives.
FNV `fnv1a64:946298686920218861`;
SHA `sha256:9afbebe8bf188a119b1bc223bc7f793da6f2dc08db9caa98e381d9e97662b234`.
See [direct coercion design/evidence](PSCV0_M2_DIRECT_COERCIONS_2026-10-13.md).

**M2+A remains incomplete.** The next source change introduces explicit
instance-search transparency, module-preserved reducibility and a reviewed
digest update; it is not yet qualified. Continue remaining Repr/Hashable,
faithful selected scalar/Float/BitVec/bytes/string/collection APIs, comprehensive
manifest, broader M2 coverage and C5 semantic retention. Keep the accepted
**M2+A → M3+B → M4+C/D → M5/E** dependencies and unchanged exit gates.
Native .lean and official Lean only; no pskernel-core, self-hosting or
compiler-source migration.


## Current qualification — M2+A scheduling, indexed lookup and literals (13 October 2026)

Executable `4d2e644d3974a6e6a4b68a15b7148bdb4f83e372`;
[green Linux 38425066964](https://github.com/dwijayuda/pskernel/actions/runs/38425066964).
**285 shared runtime observations**, four panic contracts, **186 portable /
194 native modules**, profile `pscv0-v7-native-bounded/50`.
Official Lean RC4 kernel, independent oracle, semantic refusals, strict IR,
JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI and project checks passed.

- One transactional worklist now serves Core constraints and captured source
  terms. Later arguments can determine record/lambda/tactic types; numeral
  fallback and mandatory defaults run after ordinary work reaches quiescence.
- Global instances are indexed by class while preserving priority/tie order.
  Generator buckets use rigid class plus lexical scope, followed by full
  definitionally-equal input checks. At 32 goals: zero generator comparisons
  across classes, 528 within one class. No general linearity claim.
- Numeric literals use genuine checked OfNat dictionaries. Typed Core
  application resolves class universes before search; deriving reuses it.
  Custom numeric types, local dictionaries and higher universes are qualified.

Standard: **299 declarations / 15 classes / 54 instances**.
The reviewed change adds OfNat/constructor/projection and Nat/Int dictionaries,
without new axioms or primitives.
FNV `fnv1a64:4206739069382061916`;
SHA-256 `sha256:00c6142b5f5b0e47abb8b317dc4fff3d595ab9f5e931822c4f48fca809758647`.

Direct Coe/CoeFun/CoeSort boundaries are implemented but **qualification is
pending** in subsequent source commits. They add nine checked declarations,
three classes and no global instances. Keep strict digest review.
See [scheduling and lookup](docs/PSCV0_M2_POSTPONED_ELABORATION_2026-10-13.md)
and [direct coercion design](docs/PSCV0_M2_DIRECT_COERCIONS_2026-10-13.md).

**M2+A is not complete.** Continue autonomously: remaining Repr/Hashable,
faithful scalar/Float/BitVec/bytes/string/collection APIs, comprehensive
module/notation/handler/tactic/effect/assumption manifest, broader M2 coverage
and C5 semantic retention. Keep dependent/indexed/recursive deriving with M3's
shared data/transport/termination work. Preserve
**M2+A → M3+B → M4+C/D → M5/E**; do not redefine the exit gates.
Native .lean, official kernel, GitHub source operations and Linux CI only.
No pskernel-core, self-hosting or compiler-source migration.

## Recover canonical state

Read current top sections of:
1. [AI work state](AI_WORK_STATE.md).
2. [Checked equality/defaults](docs/PSCV0_M2_A_EQUALITY_DEFAULTS_2026-10-13.md), then
   [Generalized answers and shared constraints](docs/PSCV0_M2_GENERALIZED_CONSTRAINTS_2026-10-13.md).
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

## Prior completed milestone: equality/defaults

- `DerivingContext` owns shared field classification and actual-minor recursor
  construction. The old BEq-only builder is removed.
- `DerivingDecEq` supports non-indexed, nonrecursive families with independent
  runtime fields, mixed universes, empty families and dependent proof fields.
  Positive evidence uses existing context transport and reflexivity; negative
  evidence uses projection congruence or constructor discrimination.
- BEq skips proof fields. Inhabited honors explicit structure defaults before
  dictionary synthesis, preserving two-pass selection and requirement pruning.
  Records use the shared completion queue and retain missing-field diagnostics.
- `Meta.Reduce.psDefEqReadOnlyWithProofs` shares conversion/congruence;
  `Meta.Infer.psInferGroundProofIrrelevance` is used by both inference and
  unification. Open binder bodies in their scoped contexts and require
  metavariable-free inferred propositions. Different runtime values and
  propositions remain distinct; there are focused negative checks.
- Standard adds exactly the checked aliases/API definitions DecidableEq and
  decEq. DecidableEq is a Sort-polymorphic Pi alias, not a new class; existing
  Pi-aware search solves its Decidable body. No axiom/primitive is added.
- 13 new observations, independent RC4 oracle, 629 declaration mappings and
  37 generated-parent origins are qualified. Maps retain declaration precision.

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
A declaration-facing term requires an empty shared queue; nested applications may defer captured syntax/Core work. Preserve mismatch versus
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

Use real Phase A needs to drive remaining M2 work. Repr and Hashable are the
remaining unimplemented allowlisted handlers. First implement their faithful
Standard dependencies: Std.Format document algebra/rendering, quoting and
precedence-aware instances for Repr; UInt64, exact modular operations and
mixHash/runtime correspondence for Hashable. Do not replace their public types
with String or Nat or fabricate opaque implementations. Reuse the shared field
and recursor mechanisms; interleave M3 data/recursion support where needed.

Broader selected libraries/scalars/APIs and the comprehensive environment
manifest remain open. DecidableEq, proof-field BEq and explicit structure
defaults are now qualified for the selected slice; do not reimplement them.
Keep dependent computational fields, indices and recursive deriving with the
general M3 data/transport/termination machinery.
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
(roughly 495–3291x in the latest retained run for its small batches). Preserve raw workload/checksum/timing
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

Start with live HEAD/CI, the equality/defaults design and the current abstraction, graph, synthetic, typed-conversion and deriving owners. Continue coherent dependency-driven work; update the work state at the next qualified boundary.
