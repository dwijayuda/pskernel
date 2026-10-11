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
| Type inference and environment | Scoped typed metavariable assignment with universe constraints, local instances, universe instantiation, RC4 checking | Source universes, complete global class/instance registration and frozen Standard registry |
| Data and elimination | Structures, uniform indexed families, recursor-driven motives, dependent context reversion, homogeneous index constraints and impossible cases, nested/multiple typed pattern matrices and nomatch, proof-field storage erasure | Named discriminants, heterogeneous constraints, Type/existential fields, selected nested/mutual data |
| Recursion and runtime closure | Direct indexed recursion, changing-state workers; captured/nested recursor lifting qualified with typed traversal | Recursive pattern matrices, well-founded and mutual source recursion, complete runtime field profiles |
| Modules and libraries | Pure single-module v7 compiler; imports explicitly refused | Portable dependency graph/visibility, RC4 module exposure, pinned Standard/library manifests |
| Proofs and contracts | Term proofs checked by official Lean; selected logical primitives | Shared goal state, proof-producing tactic registry, selected automation, VC/effect/spec generation and assumption closure |
| Control and effects | Term if-let, pattern-let, matches and inferred matrix results; selected Except do | General typed do and do-pattern sequencing, mutable/early-return/loop lowering, registered effect families |
| Executable assurance | Checked prepared graph, typed IR validation, TS/JS integration | Complete v7 assurance/axiom/effect ledger, specified runtime/library fidelity and final release criteria |
| Portable source end state | Native portable authoring/import guard | Translate sufficient implemented closure to readable .ps, then explicit source/semantic/fixed-point qualification |

## Dependency-driven sequence

1. Captured/nested runtime recursion now uses checked Core helpers and the
   existing backend contract; broader well-founded/mutual recursion is separate.
2. The typed pattern matrix now serves nested/multiple discriminants,
   first-match behavior and pattern-derived terms through shared dependent
   telescopes/equality. Complete its remaining documented grammar/refinement
   boundaries as their type/recursion dependencies become available.
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

## Next requested backend milestone

After the current small class/instance milestone, implement a Rust backend before
full v7 completion. Reuse checked prepared Core and validated typed IR. Keep target
representation and runtime support inside backend/runtime modules; do not fork
source elaboration or proof checking. Define the initial Rust capability boundary
and compile/run the same compact application subset with the native Rust toolchain.
Full v7 and source/self-host migration remain subsequent milestones.
