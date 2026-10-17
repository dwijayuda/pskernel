# M2+A: checked equality deriving and structure defaults

Qualified executable `d7e28a3870cdc399eca3c63c6d305b10109d2eca`;
[green Linux 38418209663](https://github.com/dwijayuda/pskernel/actions/runs/38418209663),
job `115368221664`. Profile `pscv0-v7-native-bounded/49`.
This completes this bounded M2+A milestone, not all M2, Phase A or v7.

## Placement and scope

This is the next bounded slice of **M2+A**, before M3+B. It implements
`DecidableEq` for non-indexed, nonrecursive families with independent runtime
field types, completes `BEq` proof-field skipping, and admits checked structure
field defaults for constructor/record completion and `Inhabited` deriving.
Empty families are supported by their empty recursor.

Proof fields may depend on earlier runtime values. Computational fields that
require heterogeneous transport, indexed families, recursion and large-family
dispatch improvements remain with the general M3 data/recursion mechanisms.

`Repr` and `Hashable` remain unimplemented. Their next dependencies are real
Standard foundations, not parser dispatch entries:
- Repr requires the pinned `Std.Format` document algebra/rendering and actual
  quoting/precedence-aware instances. Replacing Format with String would change
  its public type and semantics.
- Hashable requires `UInt64`, exact modular operations and `mixHash`, together
  with audited portable runtime correspondence. Substituting Nat or an
  arbitrary hash algorithm would break the pinned interface/observations.

No additional roadmap track is introduced. Develop those foundations within
remaining A/M2 work and use the M3 machinery where they need recursion.

## Shared ownership

`Ps.Elab.DerivingContext` owns parameter/universe telescopes, checked dictionary
synthesis, field classification and the new generic eliminator builder.
A field is classified in its actual opened constructor context. Proof fields
retain their positions and may depend on earlier values. Runtime fields must
be independent of constructor locals for this slice.

The eliminator instantiates the actual recursor's motive universes, consumes
its parameter/motive telescope, and opens each actual minor with fresh locals.
Callbacks receive fields and the reconstructed constructor. BEq's former
private nested-recursor builder is removed. Structure BEq keeps its direct
projection path. There are no reserved numeric local identities.

The command still owns source order, instance registration, privacy and
generated-parent provenance. Each handler returns an ordinary closed Core
definition. Official Lean checks every declaration and proof.

## DecidableEq

The Standard additions are exactly two checked definitions: `DecidableEq`
and `decEq`, matching pinned Init/Prelude. DecidableEq is a reducible
`(a b : α) → Decidable (a = b)` alias over Sort u, not a new structure class,
axiom, primitive, or special instance-search rule. The M2 graph's existing
Pi introduction and local dictionaries handle these requirements.

A constructor pair generates decisions for runtime fields in declaration
order. Each decision's continuation sits in the positive branch, preserving
short-circuit evaluation. A negative field result refutes equality of the
whole values via a checked projection and equality congruence.

When every field is equal, the existing equality-constraint/substitution
engine transports the right context, including dependent proof fields.
Typed proof irrelevance closes the remaining constructor equality by refl.
Different constructors are separated by a checked recursor-built proposition;
Eq.rec transports True to False under the impossible equality.

No equality is inferred from BEq, and no new noConfusion axiom or unchecked
proof is introduced. Nested decisions share the existing Decidable model and
erasure; no backend-specific equality generator is added.

## M2 typed conversion

Application/let inference formerly used structural-only conversion, while
unification already had a typed proof-irrelevance rule. That split rejected
Eq.rec applications whose base differed from the expected value only in proof
fields. Reduction/congruence now has one shared walker with an optional typed
proof rule. Binder bodies are opened in their actual local context.
Inference and unification share the same closed, inferred-Prop rule; inference
uses a decreasing-fuel callback. No assignment or runtime equality is added.
Focused checks admit differing proofs of the same proposition and reject
different propositions and unequal runtime indices.

## Structure defaults

The existing scoped optional-type syntax carries explicit field defaults.
Their annotations/defaults are elaborated before their binder group's names
enter scope. Constructor telescope substitution supplies preceding fields to
later defaults, including proof defaults.

Record completion uses the shared application/synthetic-constraint queue.
An omitted declared default remains mandatory; it is not a unification choice.
Missing required explicit fields retain the source-owned missing-field diagnostic;
completed applications also require an empty queue and the expected family result.
Record updates retain omitted projections and only use defaults when constructing
a new value.

Inhabited preserves two-pass constructor selection and unused-requirement
pruning. A declared default is checked and used before dictionary synthesis.
Thus a seeded generic record needs no fabricated Inhabited assumption.

## Primary references

All source references are pinned to Lean RC4
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`:
[DecEq handler](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/Deriving/DecEq.lean),
[BEq handler](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/Deriving/BEq.lean),
[Inhabited handler](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/Deriving/Inhabited.lean),
[shared deriving utility](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/Deriving/Util.lean),
[Repr handler](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/Deriving/Repr.lean),
[Hashable handler](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/Deriving/Hashable.lean).
Independent upstream oracle examples and one combined portable fixture validate
the intended correspondence; executable checking is not a formal compiler
preservation proof.

## Qualification and review

- 183 portable / 191 native modules; official Lean 4.35.0-rc4 at the pin above.
- 276 observations across the existing JS/TS/Rust/GC-Wasm lanes, retaining all
  previous 263; four panic contracts. The added 13 cover public decEq,
  mixed-universe/generic dictionaries, payload equality/inequality and distinct
  tags, Unicode String payloads, declared/overridden/seeded defaults and proof fields.
- Independent upstream oracle, positive/negative typed-conversion invariants,
  92 existing phase-specific refusals, 8 do refusals and 1 opacity refusal pass.
  Focused deriving refusals cover missing dictionaries, dependent computational
  fields, recursion, indices, ill-typed defaults and missing required fields.
- Strict IR, source maps/declaration consumer, native project linking,
  WIT/WAT/binary/Canonical ABI, V8/Wasmtime and repeated component calls/post-return pass.
  629 declaration mappings and 37 generated-parent origins; declaration precision.
- Standard: 294 declarations / 14 classes / 52 instances.
  FNV `fnv1a64:8231265721298810139`;
  SHA `sha256:89c4125cc3ca36bf198421e64673659a0acdf0207004af46738d36d32fcfd540`.
  Two definitions were reviewed before updating strict drift guards, using
  independently observed digests from Linux 38416389933. Primitive/axiom
  authority is unchanged.
- The generalized-answer graph still reports 6 generators / 6 answers /
  1 generalized / 1 freshened answer. Ownership/replay limits remain unchanged.
- Restored-cache build: 7437 ms; warm build: 506 ms, not a cold-build result.
  Existing M1 elaboration samples: indexed 4/32 ms versus direct 1/5 ms at
  16/128 declarations; prelude 13 ms. Generated JS/native Lean ratios are
  roughly 495–3291x on the retained small runtime batches. These uncontrolled
  measurements establish neither performance parity nor a causal speedup or
  regression. General specialization/call/allocation improvements remain M5.

Architecture review: obsolete private BEq recursor construction and duplicated
proof-irrelevance code have been removed. Shared conversion, field planning,
recursor construction and synthetic completion own the general mechanisms.
No backend-specific deriving path, unchecked cast, new proof axiom, source
migration or self-host loop was introduced. Binary constructor dispatch is
still quadratic in constructor count; shared tag/same-constructor machinery
belongs to a measured general M3/M5 improvement, not a handler-specific patch.
