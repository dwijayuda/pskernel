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


## Current qualified boundary — stable Lean and integer conversion (14 October 2026)

Executable `80c73a473808434f2b945bf97ff751f1201e6f3a`;
[green Linux 38439035494](https://github.com/dwijayuda/pskernel/actions/runs/38439035494).
**302 shared runtime observations**, four panic contracts, **190 portable /
198 native modules**, profile `pscv0-v7-native-bounded/54`.
Official **Lean 4.35.0** at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`;
independent oracle, semantic/refusal and graph gates, strict IR,
JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI, project and existing performance gates passed.
These measurements do not establish performance parity.

Standard: **315 declarations /18 classes /54 instances**, canonical v2:
FNV `fnv1a64:5885345544530235680`;
SHA `sha256:739169c3254d48e26471fd8be9bda480341a21788dcf67d683c5982e996ac634`.
Character and Unicode string quoting use checked definitions; native evaluation
provides independent comparison because upstream String.Internal.append is
kernel-opaque. Int/ofNat/negSucc now have actual checked datatype declarations,
with Int.rec and checked Int.toNat; the typed runtime override clamps negatives
without narrowing positive integers. Direct and first-class observations pass.
Historical RC4 receipts retain their original identities.

Full M2+A is **not complete**. Next: faithful Std.Format/Repr and remaining A/M2.

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

Quoting and stable-pin qualification are complete at the boundary above.
[Checked integer conversion](docs/PSCV0_A_INTEGER_CONVERSION_2026-10-14.md)
replaces three assumptions with the real Int inductive/constructors and adds
the recursor plus checked toNat. A typed runtime override preserves arbitrary
precision and clamps negatives; first-class conversion uses common completion.
Four shared observations and native equations pass at the qualified boundary.
[Format/Repr design](docs/PSCV0_A_FORMAT_REPR_2026-10-14.md) records the next implementation.

Continue Repr with real Std.Format document algebra, rendering and precedence;
Hashable with real UInt64/modular operations/mixHash. No String/Nat replacements
for their public types. Other A exits: faithful Float/Float32/scientific,
fixed-width/BitVec/bytes/string/collection APIs and comprehensive cryptographic
module/public/import/notation/handler/class/instance/tactic/effect/axiom manifest.
The current selected snapshot is not that full manifest.

Remaining M2 includes broader scope/depth/resource parity and measurements plus
C5 semantic retention at binder/resolution/implicit/default/occurrence owners.
Current coarse declaration maps are not occurrence retention. Do not claim
full host elaborator parity or infer completeness from a green bounded run.

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
