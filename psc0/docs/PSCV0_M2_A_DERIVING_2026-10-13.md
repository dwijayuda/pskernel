# M2 + Phase A: parameter and universe-aware deriving

Date: 13 October 2026. Implementation staged; qualification pending.

## Roadmap placement

Follow **M2+A → M3+B → M4+C/D**. This slice connects Phase A deriving to
M2's existing checked instance graph. It does not finish M2 or Phase A.
Indexed/dependent/recursive deriving stays with the M3 data and recursion
work it needs. C5 source reconstruction, richer origins and performance work
remain on the existing roadmap; no new milestone is introduced.

## Shared mechanism and invariants

`DerivingContext` opens the admitted family's uniform-parameter telescope
using the ordinary binder/context machinery. The handler carries its actual
universe parameters, fresh local identities, and a fully applied family.
Class requirements use ordinary constant freshening, type inference and
unification; value parameters never receive bogus typeclass assumptions.
Constructor parameter application uses the same universe substitution and
telescope primitives as ordinary elaboration.

Each handler returns one ordinary definition with the established
`instInhabited` / `instBEq` name. Command elaboration retains handler order,
instance registration, privacy and origin ownership. Both type and value must
have no unresolved metavariables or escaped locals. Official Lean admission
remains authoritative; no host elaborator enters the portable closure.

- `Inhabited`: try every constructor without extra requirements first, then
  retry with type-correct parameter requirements. Fill fields in telescope
  order and substitute each default into later field types. Close only the
  requirements used by the selected value; phantom parameters do not create
  unnecessary `Inhabited` assumptions.
- `BEq`: build type-correct parameter requirements and synthesize each field
  comparison once. Independent nonrecursive fields may inhabit different
  universes. Structures use projections. Fieldless/payload inductives share
  one recursor builder with separate, inferred outer and inner motive
  universes and collision-free opened field telescopes.

The selected boundary remains non-indexed families and independent,
nonrecursive BEq fields. Dependent comparison requires evidence-producing
transport, and recursive comparison requires structural workers. Function
fields without BEq, unsupported deriving handlers, and these unimplemented
families continue to fail closed. Structure field-default semantics and
proof-field skipping are not added by this slice.

## M2 mechanisms strengthened

Projection inference and source projection lookup instantiate constructor
universe parameters with the actual major's levels before consuming its
uniform parameters. Raw projection inference also checks universe arity.

Level normalization factors a common successor:
`max (succ u) (succ v) = succ (max u v)`. This is the reusable normalization
law needed for mixed-universe record sorts to unify with `BEq : Type u → Type u`;
handlers do not guess universe predecessors or add a separate level solver.

Rigid application congruence retains the existing universe-first path and can
defer a failed head-universe equation until its typed arguments have fixed the
universe metavariables. The argument-first attempt starts from the original
snapshot, checks every argument, then must discharge all head-level equations
before committing. This handles max-universe instances without guessing levels
or publishing delayed unchecked equalities. It is a bounded spine mechanism,
not the still-open unified synthetic-constraint scheduler.

The generator/consumer instance graph and its ownership, replay and resource
bounds are unchanged. This slice exercises local polymorphic requirements
through that public synthesis API.

## Focused qualification plan

One combined source fixture adds generic, phantom, value-parameter,
Sort-polymorphic and mixed-universe families, kernel-checked reduction
equalities, and eight observations shared by JS/TS/Rust/GC-Wasm. Three
elaboration refusals cover missing parameter dictionaries, dependent fields
and a recursive generic family. The pinned Lean oracle independently checks
constructor selection, assumption pruning and runtime equality semantics.
Run the existing complete native Linux workflow once the code is committed;
retain all existing checks and snapshot digest guards.

## Pinned design references

Official Lean at `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`:

- [Inhabited deriving](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/Deriving/Inhabited.lean):
  two-pass constructor selection and used-requirement pruning.
- [BEq deriving](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/Deriving/BEq.lean)
  and [shared deriving utilities](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/Deriving/Util.lean):
  type-correct parameter requirements, constructor comparisons, and the
  evidence/recursion mechanisms needed for the larger deferred domain.

This uses the reference algorithms and invariants, not the host's syntax or
deriving implementation inside the portable compiler.
