# M2: explicit instance-search transparency

## Design and invariants

Pinned upstream: Lean 4.35.0-rc4, c29b6dda4f7c20e3eeaa717c4e565663c5cfa364.
Reference implementation:
- src/Lean/ReducibilityAttrs.lean defines the five statuses.
- src/Lean/Meta/SynthInstance.lean selects instance transparency.
- Native PrimitiveAudit records and verifies every selected definition whose
  identity exists upstream. Portable helper identities are labelled separately.

Core expression/declaration identity is unchanged. A persistent bucket index
holds reducibility metadata; explicit policy parameters govern the shared
reducer, congruence and unifier. Ordinary kernel-style checking retains full
definition conversion. Instance target preparation, candidate preparation,
candidate matching and generator-key comparison use instance transparency.
Checking a selected witness remains ordinary type checking, as does checking
a mandatory default. Speculative failures still roll back all assignments.

Source abbreviations are reducible; registered instances are instance-reducible.
Ordinary definitions are semireducible. Opaque bodies remain unavailable regardless
of metadata. Public interfaces preserve metadata alongside existing body exposure.
The ordered selected declarations' statuses enter the canonical v2 Standard payload.
Cached index shape is not hashed. No per-query environment copy or body deletion.

Numeral elaboration also checks the Nat fast path at instance transparency:
a hidden ordinary alias cannot bypass OfNat search merely because it reduces
under full conversion. Explicitly typed Nat terms still use ordinary checked
conversion where the source requests it.

## Validation and status

Implementation pending qualification. One compact boundary covers abbreviations,
local dictionaries, ordinary aliases, explicit conversion, imported abbreviation
metadata and digest drift. The independent pinned source oracle checks the same
positive/refusal boundary. All existing graph, runtime and backend gates remain.

Current last qualified executable is 35641f810e31f3c9d309c01028acd53ebe4112d9,
Linux run 38430940757, 293 shared observations. The intentional metadata payload
change must be reviewed and both expected digests repinned only after the strict
guard reports them. This is not full M2+A or v7 completion.
