# PSCV0 v7 native implementation roadmap

The canonical language target is PSCV0_LANGUAGE_REFERENCE.md at its recorded v7
digest, with Lean 4.35.0-rc4 semantics. This is an implementation dependency map,
not a conformance claim. Exact qualified sources/runs are in AI_WORK_STATE.md.
Historical generated-source milestones do not certify the current native source.

## End state and current development contract

Keep the portable semantic compiler in shared .lean modules, executed natively
and checked by the official Lean kernel. Preserve syntax -> resolution ->
elaboration -> canonical prepared Core -> checking -> typed erasure -> validated
IR -> backend boundaries. The host retains the same prepared graph across check
and emit. No Lean frontend fallback, alternate kernel on failure, or fabricated
proof authority is permitted.

Native language growth precedes compiler-source translation. The final readable
.ps migration and fixed-point qualification remain separate future milestones;
pskernel-core, self-host generation and independent kernel suites are outside
this development loop.

## Capability dependencies

| Capability family | Existing implementation/evidence | Remaining mechanisms |
|---|---|---|
| Source categories and scopes | Rich terms, calls/defaults, expected binders, namespaces/open/sections, grouped annotation scope | Full selected literals/operators, aliases/modifiers, syntax-preserving diagnostics |
| Type inference and environment | Core metas, unification, local instances, universe instantiation, RC4 checking | Source universes, complete global class/instance registration and frozen Standard registry |
| Data and elimination | Structures, uniform indexed families, recursor-driven motives, dependent context reversion, homogeneous index constraints and impossible cases | Pattern matrices, named discriminants, heterogeneous constraints, erased/existential fields, selected nested/mutual data |
| Recursion and runtime closure | Direct indexed recursion, changing-state workers; captured/nested recursor lifting under qualification | Recursive pattern matrices, well-founded and mutual source recursion, complete runtime field profiles |
| Modules and libraries | Pure single-module v7 compiler; imports explicitly refused | Portable dependency graph/visibility, RC4 module exposure, pinned Standard/library manifests |
| Proofs and contracts | Term proofs checked by official Lean; selected logical primitives | Shared goal state, proof-producing tactic registry, selected automation, VC/effect/spec generation and assumption closure |
| Control and effects | Selected Except do | General typed do, if-let/pattern bindings, mutable/early-return/loop lowering, registered effect families |
| Executable assurance | Checked prepared graph, typed IR validation, TS/JS integration | Complete v7 assurance/axiom/effect ledger, specified runtime/library fidelity and final release criteria |
| Portable source end state | Native portable authoring/import guard | Translate sufficient implemented closure to readable .ps, then explicit source/semantic/fixed-point qualification |

## Dependency-driven sequence

1. Remove captured/nested recursion restrictions once at Core preparation, using
   checked helper declarations and the existing backend contract.
2. Build one typed pattern-matrix mechanism for nested/multiple discriminants,
   first-match behavior and pattern-derived term forms, on the shared dependent
   telescope/equality machinery.
3. Extend data/instance and module environment ownership before broader library
   sugar, tactics and effects rely on it.
4. Build shared proof-goal and typed control mechanisms; implement selected
   automation and VC generation as proof-producing clients of those mechanisms.
5. Close the canonical capability and assurance ledger; only then begin the
   requested final compiler-source migration and generation qualification.

This ordering may change when source inspection reveals a stronger dependency.
A green compact fixture is evidence for its exact boundary, never completion of
an entire row. Validation first checks semantic invariants and actual admitted
terms, then the affected runtime path, while reusing compact integration inputs.
