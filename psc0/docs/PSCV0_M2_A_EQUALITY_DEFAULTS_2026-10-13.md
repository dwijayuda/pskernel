# M2+A: checked equality deriving and structure defaults

Implementation revision: `503825c29ae3f0e89842c1ddb6c0ac811ded5024`.
Qualification is pending. This document records the design, not a green result.

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

## Structure defaults

The existing scoped optional-type syntax carries explicit field defaults.
Their annotations/defaults are elaborated before their binder group's names
enter scope. Constructor telescope substitution supplies preceding fields to
later defaults, including proof defaults.

Record completion uses the shared application/synthetic-constraint queue.
An omitted declared default remains mandatory; it is not a unification choice.
Missing required fields still leave an incompatible function result and reject.
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
