# Native class and instance environment

The v7 compiler keeps class/instance registration in the portable environment.
Classes reuse structure elaboration, dependent fields, proof storage erasure and
canonical kernel admission. Registration is command metadata over the shared
declaration AST, not a second declaration elaborator.

## Invariants

- Class registration requires an elaborated structure. Global instances require
  an elaborated declaration whose result is a registered class.
- Every persistent environment insertion preserves class and instance registries.
  Each compiler request starts from its own immutable prelude environment.
- Source priorities are decimal naturals or low=100, mid=500, default=1000,
  high=10000. Locals precede globals; globals use descending numeric priority
  and most recently registered first for equal priorities.
- Candidate failure restores its incoming metavariable snapshot. Recursive
  search rejects an already active input key, then tries the next candidate.
  Output positions and output-only universes do not change cycle identity.
- Generated qualified projections are ordinary closed Core definitions. Class
  dictionary binders are instance-implicit; ordinary structure targets are explicit.
  Dependent field types substitute earlier Core projections.
- Record construction seeds known uniform parameters from the expected type
  before field elaboration, then uses the shared named-argument engine. Fields
  retain their declared order and annotation dependencies.

## Source boundary and validation

Selected class declarations and named/anonymous instance declarations use native
v7 declaration binders and newline-only field declaration headers. Field parameter
lambdas enclose their optional result ascription. Empty instance binder groups,
priority arithmetic and value-form instance declarations remain grammar refusals.

The compact existing composite application exercises prioritized global selection,
recursive generic dictionaries, local precedence, proof fields, qualified
projections and cyclic-candidate backtracking. Focused refusals exercise the
grammar and registration boundaries. [Native run 38171564012](https://github.com/dwijayuda/pskernel/actions/runs/38171564012)
passed at source a74153c8c1571ee01913b8db6af10d803767d005: official Lean
accepted the 264-declaration composite, all 50 phase-specific refusals passed,
and TypeScript strict compilation plus JavaScript runtime checks passed.
The exact receipt is recorded in AI_WORK_STATE.md.

Class output metadata and dependency-driven dictionary solving are described in
PSCV0_NATIVE_INSTANCE_OUTPUTS.md. Inputs remain ground; outputs can be inferred.
Complete tabled non-ground search, semi-output parameters, superclass derivation,
source attributes/default instances and imported registries remain separate.

## Reference

The pinned RC4 implementation separates candidate indexing/order and transactional
search from class metadata:
https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Meta/SynthInstance.lean

The portable search reuses its existing bounded solver and uses an input-cycle
guard; it does not import Lean.Meta into the portable compiler closure.
