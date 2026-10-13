# Active continuation — 14 October 2026: foundation approval pending

Latest published implementation before this note: `c5aa4b2285249eced0bc69b306e488768c5118c3`.
The ToFormat/Repr/Hashable /60 checkpoint below remains the last full green.
Current quotient-mechanism and shared word-backend changes are under Linux
qualification; do not claim unsigned operations or full M2+A complete.

**Actual blocker:** automatic approval review rejected publishing a proposed
per-slice allowlist for exactly pinned Lean `propext` and `Quot.sound`.
The user was asked explicitly via the asynchronous question. Until approved,
retain the current refusal. If approved, do not ask again: apply the documented
trust change, export/review/admit the full unsigned slice, update both strict
digests from independent CI evidence, and continue remaining M2+A.

The candidate policy inventory at
[38469424406](https://github.com/dwijayuda/pskernel/actions/runs/38469424406)
reported 794 new declarations, exactly those two axioms and three used kernel
quotient descriptors. The exporter now closes the four-descriptor family.
No candidate asset has been admitted; no new assumption is in the active
Standard environment. CI explicitly verifies refusal at `Quot.sound` and
runs the unchanged /60 integration matrix afterward.

Implemented infrastructure: capture-avoiding function-valued recursive iota,
symbolic differential checks against actual Lean recursor rules; explicit
kernel quotient metadata, official generative admission/signature checks,
registered lift/ind reduction, isolated kernel computation and collision probes.
This is logical foundation work, not source well-founded recursion or general
quotient runtime support. Shared integer div/rem/shift lowering is implemented
but the full operation family still awaits source admission and qualification.

Next unsigned admission: freeze the current hash-stage replay base before
extending it; retain actual Nat.div instead of its old axiom; add explicit
HAdd/HSub/HMul/HDiv/HMod/Neg registrations for four widths; qualify the compact
12-operation vectors, zero division, wrapped shifts and higher-order/generic
calls against native Lean and all existing targets. Preserve all /60 cases.
Signed/word-sized values, Float/scientific, expanded BitVec/selected APIs,
comprehensive manifest, broader M2 evidence and C5 retention remain open.

See [reviewed design and approval boundary](docs/PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md).
No local shell/build, pskernel-core, compiler-source .ps migration or self-hosting.
Pinned official Lean 4.35.0; GitHub connector writes and Linux Actions only.

---

# PSCV0 v7 — Active work state

## Pinned Lean reference rule (14 October 2026)

Current pin: **Lean 4.35.0**, `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
[Migration and source comparison](docs/PSCV0_LEAN_435_PIN_2026-10-14.md).
Before any feature design, implementation or redesign, study the corresponding
official implementation and relevant tests at this pin. Record algorithms,
data structures, semantics, invariants, optimizations and the comparison with
PSC0; justify simplifications and validate against Lean where applicable.
Retain licensing/attribution when adapting code. This applies to M0–M5,
A–E, C5 and all future development; do not preserve obsolete internals merely
for compatibility.


## Current qualified boundary — Hashable and stable erased calls (14 October 2026)

Executable `d72fc7779b2e8d130915dfe4ace339634ba0addd`;
[green Linux 38466179341](https://github.com/dwijayuda/pskernel/actions/runs/38466179341).
**399 shared runtime observations**, four panic contracts, **217 portable /
227 native modules**, profile `pscv0-v7-native-bounded/60`.
Official **Lean 4.35.0**, independent oracle, semantic/refusal/search checks,
strict IR, JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI, projects and
existing performance gates pass. Performance parity is not established.

Standard: **672 declarations /23 classes /109 instances**.
FNV `fnv1a64:10680386315174967875`;
SHA `sha256:9a54d5747d3047abff68e3bd872b791f3489f719cf83e8aba6776d342f045cc0`.

Qualified: ToFormat/Repr and selected nonrecursive deriving; real UInt/BitVec
construction/conversions; unsigned Canonical ABI widths; Hashable class,
17 checked instances, selected nonrecursive deriving, native-compatible pair
and UTF-8 string hashes. Hashable's Prop and implicit fields retain pinned
semantics. Hash runtime algorithms are separately audited overrides of checked
opaque declarations, not kernel proofs of runtime implementation equivalence.

Shared erasure now lowers builtin Int.rec through a once-evaluated sign split.
Known generic calls preserve their original declaration binder masks when Sort
parameters specialize to Prop; irrelevant carriers and proof slots use Unit.
The same integration suite covers these mechanisms across every existing target.

The Nat.mod_lt and UInt/BitVec and hash foundation assets regenerate byte-for-byte
through the native-only exporter and fresh official kernel replay.
No new axioms, pskernel-core or self-hosting. Prior complete-spine WHNF and
reflexivity-before-evaluation repairs remain in place; the latest Wasm observation
source elaborates in 243 ms. This is a bounded measurement, not performance parity.

[Design, sources and qualification](docs/PSCV0_A_FORMAT_REPR_2026-10-14.md).
**Full M2+A remains incomplete.** Continue the unsigned-operation closure
candidate, signed/platform words, Float/scientific/BitVec/selected library APIs,
comprehensive manifest, broader M2 evidence and C5 semantic retention.
Recursive/indexed/dependent deriving remains M3+B.

Unsigned-operation candidate run38466911457 preserved all /60 gates, then
refused Acc's reflexive proof field. The follow-up implements general single-family
logical iota under recursive function telescopes and adds symbolic comparison of
every exported recursor rule with pinned Lean. Machine division/remainder/shifts
are prepared across backends; unsigned source methods await the checked asset.
See the scalar completion design; none of this marks M2+A complete.

## Active request and execution contract

Continue **remaining M2+A until completed**, then follow **M3+B → M4+C/D → M5/E**.
Do not stop at a small checkpoint or redefine the exit gates. Re-evaluate the
architecture, implement coherent mechanisms, then run focused and existing
integration validation. Preserve intended semantics, not obsolete internals.

- Repository: `dwijayuda/pskernel`; branch: `psc0/pscv0-v7-native-lean-v1`.
- Existing draft [PR 109](https://github.com/dwijayuda/pskernel/pull/109); preserve
  it and history. Check live HEAD, use expected-HEAD non-force updates.
- GitHub connector source operations and Linux Actions only. No local checkout,
  build or Desktop Commander.
- Native portable `.lean`, pinned official Lean `4.35.0`,
  `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
- No pskernel-core, self-hosting or compiler-source `.ps` migration.
- Wasm GC internally; linear memory only at explicit ABI boundaries.
- No unchecked proof/kernel fallback, fabricated axioms, weakened acceptance,
  arbitrary runtime casts, main merge or force push.

## Source of truth and dependencies

Read [canonical v7](PSCV0_LANGUAGE_REFERENCE.md),
[M0–M5 architecture](docs/PSCV0_NATIVE_LEAN_GRADE_ARCHITECTURE_REDESIGN_V1.md),
[A–E exit gates](docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md) and
[readable-output audit](docs/PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md).

M1's selected checked GetElem/Fin/List/Array/optional-lawfulness closure is
complete. M2/A carries inference/search, selected Standard and handlers.
M3/B owns indexed/dependent/recursive deriving with the general
data/transport/termination mechanisms. M4/C-D owns effects/specifications/VCs.
M5/E owns final optimization, C5 publication/correspondence and overall closure.
Collect E evidence and measured M5 improvements throughout.

## Qualified M2 mechanisms

- Shared generator/consumer search with persistent class/scope buckets,
  exact checked key comparison, cycles/diamonds, independent limits,
  generalized natural term/universe templates and fresh replay.
- Only a generator's owner adopts its speculative context. Shared recipients
  open templates in their own contexts and recheck the full target.
  Identical closed local signatures are required for sharing; Pi scopes differ.
- Outputs/output levels are fresh during selection and reconciled afterward.
  Caller preferences do not trigger lower-priority output backtracking.
- Limits: 4096 generators/candidates/answers, 32768 transitions, evidence height
  64. Scope escapes/synthetic obligations cannot be generalized. Failure rolls back.
- One transactional queue handles Core constraints, saved syntax, tactics,
  defaults, numeral fallback and typed expected-term adaptation. Ordinary work
  reaches quiescence before defaults. Declarations drain all pending work.
- Defaults use opaque holes and the declared checked default; expected types
  cannot replace them. Failed retries preserve lexical authority and roll back.
- Genuine OfNat, direct Coe/CoeFun/CoeSort and common typed Core application.
  No coercion chains or auto-lifting. APP-03 remains strict.
- Explicit instance transparency and module-preserved reducibility. Do not
  restore all-definition unfolding for search or eager unfolding of inferred types.

Owners: `Meta/Abstract`, `InstanceTarget`, `InstanceCandidate`,
`InstanceSearch`, `Synthetic`, `Reduce`, `Unify`; `Elab/Context`,
`Postponed`, `Application`, `Basic`, `Class`.
The SynthInstance facade has no independent retry engine.

[Graph](docs/PSCV0_M2_INSTANCE_GRAPH_2026-10-13.md),
[generalized answers](docs/PSCV0_M2_GENERALIZED_CONSTRAINTS_2026-10-13.md),
[scheduling/indexing/OfNat](docs/PSCV0_M2_POSTPONED_ELABORATION_2026-10-13.md),
[coercions](docs/PSCV0_M2_DIRECT_COERCIONS_2026-10-13.md).

## Deriving and runtime representation

Parameter/universe-aware Inhabited, BEq and DecidableEq share family/field/
recursor mechanisms. Inhabited honors explicit defaults and prunes unnecessary
requirements. BEq skips proofs; DecidableEq constructs checked equality or
refutation, including dependent proof fields and empty families. Selected
families are non-indexed/nonrecursive with independent computational fields.

Type/proof-only fields erase. Nonrecursive one-field wrappers whose erased
uniform parameter determines their field use its concrete runtime type.
Runtime existential-dependent fields and general higher-rank dictionaries remain
explicit refusals. Do not bypass unknown-type IR checks.

[Deriving](docs/PSCV0_M2_A_DERIVING_2026-10-13.md),
[equality/defaults](docs/PSCV0_M2_A_EQUALITY_DEFAULTS_2026-10-13.md).

## Active next implementation

ToFormat/Repr and the scalar proof foundation are qualified above. Continue
genuine Hashable with UInt64's bounded-value model and audited modular operations/
mixHash. Study pinned Init/Prelude, UInt/BitVec/Hashable and Deriving/Hashable.
The existing IR already implements fixed-width binary arithmetic/comparisons;
extend its shared conversion/shift plans instead of creating parallel runtimes.
UInt64 must retain its actual BitVec 64 / Fin (2^64) logical model. No substitute
public Nat types or invented bound proofs. General runtime wrapper unboxing must
not silently erase foreign construction invariants or change public WIT records.

The native StandardExport tool provides closed declaration conversion, no-new-
axiom policy, fresh trust-zero kernel replay and metadata signature checks.
StandardScalarArithmeticData is the generated .lean asset; its frozen boundary
must not be recomputed from the expanded environment. StandardClosure remains
a read-only dependency/reuse probe. Neither belongs to the portable graph.

Other A exits: Float/Float32/scientific, fixed-width/BitVec, selected bytes/string/
collection APIs and the comprehensive cryptographic module/public/import/
notation/handler/class/instance/tactic/effect/axiom manifest. The selected
declaration snapshot is not that complete manifest. Remaining M2 includes broader
scope/depth/resource parity and measurements plus C5 retention at
binder/resolution/implicit/default/occurrence owners. Coarse declaration maps
are not occurrence retention.

## Outputs, evidence and performance

Readable JS/TS/Rust/WAT/WIT already work for the qualified subset; extend shared
plans. Historical bounded Lean/PS printers are reusable, not complete C5.
Retain checked pre-erasure source semantics during M2–M4; publish C5 under M5/E.
Source replay is not reconstruction/correspondence, and two checked outputs are
not an equivalence proof.

Tests remain one compact native batch plus the existing independent oracle,
strict IR and cross-target/project/component gates. No self-host tests.
Keep exact distinctions between implemented, kernel accepted, runtime qualified,
measured and formally proved. Measured generated-JS overhead remains substantial;
no high-performance parity or general linearity claim.

The work-state file is intentionally consolidated. Detailed prior evidence
remains in the linked design/audit documents and Git history; obsolete
chronological instructions are not current authority.
