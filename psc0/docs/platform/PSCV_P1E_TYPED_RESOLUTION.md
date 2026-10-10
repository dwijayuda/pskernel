# PSCV P1-E — typed synthesis witnesses (not Standard conformance)

The selected normative PSCV-RC-v2 reference targets **Lean 4.35.0-rc3**.
P1-D grouped 9,742 ambient imported instances by 411 result class heads.
Those groups did **not** establish actual synthesis for a typed surface.

This P1-E experiment adds seven exact source-level `#synth` goals,
each with a separate `inferInstance` type-checking example in
`PSCVL/TypedInstanceWitness.lean`. CI uses the actual pinned Lean
elaborator, then captures printed synthesized term observations.
The `psc-imported-typed-witness/0` protocol binds exact normative
source, witness source and transcript identities. All results are
**observational** and retain false authority/certification fields.

The fixed goals cover Nat addition/multiplication/subtraction,
Int addition, String append, and Nat/Bool equality. These are **seven
surface samples**, not seven approved or closed Standard snapshot IDs.
The existing three direct Bool source-located IDs are separate.
The other 191 required Standard ID mappings remain unresolved.

The ambient `PSCVL.Policy` environment contains registrations that
may not be permitted by PSCV Standard. A #synth term does not establish
Standard's instance visibility, tie resolution, effect rules or
source-to-runtime refinement. The printed text is not independent kernel
replay or a trusted proof certificate. P1 closure still requires the
complete 194-ID source-located, typechecked, ordered allowed registry,
the approved coercion/simp/simproc/ext/grind and effect/WP closures,
normative manifest revision and behavioral conformance.

**P2–P5 remain later gates**: first soundly certified pure executable;
broader syntactic/contract/tactic/effect feature slices; verified
erasure/backend/runtime evidence; comprehensive independent conformance
and release replay. None can be claimed from this imported witness.

No changes to portable compiler, current native Core, release,
self-host seed, provider or production certificate gate.
