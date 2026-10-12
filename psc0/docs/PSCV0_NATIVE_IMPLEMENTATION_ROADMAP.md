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
| Type inference and environment | Scoped typed metavariable assignment with universe constraints, prioritized global/local instances, output-parameter metadata, dictionary dependency worklists and checked class methods, scoped source universes, symbolic level simplification, RC4 checking | Complete universe constraints/explicit suffixes, tabled non-ground search/semi-output parameters, attributes/default instances and frozen Standard registry |
| Data and elimination | Structures, uniform indexed families, recursor-driven motives, dependent context reversion, homogeneous index constraints and impossible cases, nested/multiple typed pattern matrices and nomatch, proof-field storage erasure | Named discriminants, heterogeneous constraints, Type/existential fields, selected nested/mutual data |
| Recursion and runtime closure | Direct indexed recursion, changing-state workers; captured/nested recursor lifting qualified with typed traversal | Recursive pattern matrices, well-founded and mutual source recursion, complete runtime field profiles |
| Modules and libraries | Pure single-module v7 compiler; imports explicitly refused | Portable dependency graph/visibility, RC4 module exposure, pinned Standard/library manifests |
| Proofs and contracts | Term proofs and typed goal state, exact/refine/apply/intro/assumption/rfl/constructor, focus/bullets/all_goals/any_goals, cases/induction/case/next checked by official Lean | Complete logical primitives, further goal control/elimination/rewriting, selected automation, VC/effect/spec generation and assumption closure |
| Control and effects | Prop/Bool and named-proof conditionals, term if-let, pattern-let, matches and inferred matrix results; selected Except do | General typed do and do-pattern sequencing, mutable/early-return/loop lowering, registered effect families |
| Executable assurance | Checked prepared graph, complete shared IR gate, native primitive signature/model audit, direct JS/TS/Rust integration with the same observations | Complete v7 assurance/axiom/effect ledger, specified runtime/library fidelity and final release criteria |
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

## Qualified backend milestones and remaining output work

Native profile 17 qualifies milestones A and B: one checked prepared graph,
actual shared IR validation, semantic/output name mapping, portable layout and
origin artifacts, plus Rust alongside TS. The same 285-declaration composite and
102 runtime observations pass in strict TypeScript/JavaScript and Rust. Target
representation and runtime policy remain in backend modules, never elaboration.
See PSCV0_NATIVE_CODEGEN.md and PSCV0_NATIVE_RUST.md for exact boundaries.

C0–C2 now implement validated artifact bundles, retained declaration spans and
generated-parent origins, a runtime API/WIT representability boundary, the
native primitive signature/model audit, shared structured ECMAScript lowering
and direct JS/declarations/source maps. See PSCV0_NATIVE_CODEGEN.md. Source maps
currently resolve to the owning declaration; token-level origins are not claimed.

The qualified integration profile is 33; exact source/run evidence is in
AI_WORK_STATE.md. One ECMAScript Program supplies JS and TS output. Direct JS
emission does not invoke a TypeScript compiler. The same 142 observations run
on direct JS, TS-compiled JS and Rust; the new declaration and mapping boundaries
have independent consumers.

C3 is qualified: typed direct core/component binary emission, readable WAT,
scalar WIT/canonical lifts, independent validation and an executed GC allocation
inside a lifted component. C4 has new GC value layouts, runtime authoring
combinators and limb arithmetic with focused qualification. This does not yet
admit arbitrary-precision source programs through the Wasm CLI.

The latest user choice is option A: GC language values and linear memory only at
explicit Canonical ABI boundaries. Remaining work preserves
PSCV0_DIRECT_JS_WASM_ARCHITECTURE.md: C4 full current-runtime core parity, C4b
aggregate WIT/Canonical ABI/component completion with allocation/post-return and
resource lifetimes, C5 readable pre-erasure Lean/ProofScript reconstruction,
then D measured performance/ownership work. Compiler-source .ps migration,
self-hosting and complete v7 conformance remain separate qualifications.
