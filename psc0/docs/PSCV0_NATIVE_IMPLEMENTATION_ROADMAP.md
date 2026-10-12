# PSCV0 v7 native implementation roadmap

## Latest qualified native compiler milestone — 13 October 2026

**Executable source:** `70415686f1e7c13e4690c4f8bed549b1c882fe61`.
**Linux CI:** https://github.com/dwijayuda/pskernel/actions/runs/38286641968.
**Official checker:** Lean 4.35.0-rc4 (`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`).
**Profile:** `pscv0-v7-native-bounded/48`, not complete v7.

The portable semantic source now contains **168 portable / 176 native Lean
modules**, and **185 shared runtime observations** pass across direct JS,
TypeScript, Rust, V8 Wasm GC and Wasmtime. The checked three-file JS/TS/Rust
and four-module Wasm projects still run. Four checked semantic programs,
92 phase-specific refusals and compact module/Standard checks remain green.

Recent coherent Phase A work: selected checked `BEq` and `Inhabited`
dictionaries for `Prod α β`, requiring appropriate component instances
(qualified `82c601f5`, Linux run 38285466474); checked Type-0
`Except.bind/map/mapError/tryCatch/isOk/toOption` over the existing
`Except.rec` eliminator (qualified `9c644232`, run 38286353072);
and execution of success/error/recovery/mapError paths, including the
modeled String length primitive, in all five shared backend lanes
(qualified latest SHA, run 38286641968). Ordinary kernel proof checking,
erasure and runtime-model checking remain separate evidence boundaries.

No new primitive or alternate proof authority was introduced.
The native Standard signature/body/class/instance audit includes the new
declarations, but exact RC4 GetElem/index validity, selected remaining
deriving handlers, Float/scientific/fixed-width data, complete library APIs,
frozen Standard registry digest and final assurance closure remain open.
No C5, pskernel-core integration, or self-hosting yet.

## Current priority: core and essential language conformance first

User-directed priority override, 12 October 2026: **do not begin C5** until
the essential language/compiler semantics are implemented and qualified.
Keep native portable .lean authoritative; pskernel-core and self-hosting are
out of scope. Preserve previously qualified JS/TS/Rust and Wasm GC contracts.

The dependency path is: (1) pinned Standard/notation/typeclass environment and
remaining source forms, (2) module graph, public/private visibility and reusable
libraries, (3) dependent data and mutual/well-founded recursion with termination
obligations, (4) generic typed do/effects and structured state/control, and
(5) proof-producing tactics, rewriting, specs/VCs and an assurance ledger.
The next stage is chosen by architectural dependencies rather than counting
green tests. C5 reconstruction and compiler-source migration follow only when
the selected language surface is sufficient.

Selected language profiles 36–48 and the later module foundation are recorded
in AI_WORK_STATE.md. Latest qualified executable source:
`70415686f1e7c13e4690c4f8bed549b1c882fe61`, [Linux run 38286641968](https://github.com/dwijayuda/pskernel/actions/runs/38286641968).
The shared matrix contains 185 runtime observations per target. This does
not constitute full v7 conformance or full RC4 module fidelity. Source
preparation, official admission checking, provenance, erasure and target
execution remain independent assurance boundaries.


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
| Source categories and scopes | Native scoped terms/calls/binders, raw strings, grouped/radix literals, checked `s!` interpolation, selected proof/section grammar | Float/Float32/scientific tokens, exact GetElem and deriving syntax, remaining modifiers and source diagnostics |
| Type inference and environment | Scoped unification/levels/typeclasses, checked arithmetic/BEq/ToString/Inhabited with polymorphic Prod, List and Option dictionaries, Standard signature/body/instance audit, official Lean RC4 checker | Exact GetElem proof-index classes, remaining deriving handlers, floating/scalar/coercion semantics, full universe/search and pinned manifest/digest |
| Data and elimination | Structures, uniform indexed families, recursor-driven motives, dependent context reversion, homogeneous index constraints and impossible cases, nested/multiple typed pattern matrices and nomatch, proof-field storage erasure | Named discriminants, heterogeneous constraints, Type/existential fields, selected nested/mutual data |
| Recursion and runtime closure | Direct indexed recursion, changing-state workers; captured/nested recursor lifting qualified with typed traversal | Recursive pattern matrices, well-founded and mutual source recursion, complete runtime field profiles |
| Modules and libraries | Reachable import closure, private hygiene, selected re-exports/body opacity, JS/TS/Rust 3-file executable and V8/Wasmtime GC four-module execution, provenance and entry API | Complete RC4 generated public signature, collision/instance precedence and import ordering semantics |
| Proofs and contracts | Term proofs and typed goal state, exact/refine/apply/intro/assumption/rfl/constructor, focus/bullets/all_goals/any_goals, cases/induction/case/next checked by official Lean | Complete logical primitives, further goal control/elimination/rewriting, selected automation, VC/effect/spec generation and assumption closure |
| Control and effects | Checked Bool/Prop/if-let/match and selected Id/Option/Except typed do, checked Type-0 Except.bind/map/mapError/tryCatch/isOk/toOption and real cross-target error/recovery observations | General effect classes, mutable/early-return/loops, generalized do try/catch/finally and effect/fidelity laws |
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

The qualified integration profile is 35; exact source/run evidence is in
AI_WORK_STATE.md. One ECMAScript Program supplies JS and TS output, and direct
JS emission needs no TypeScript compiler. The same 142 observations now run
on JS, TS, Rust, Node/V8 Wasm core, and Wasmtime core/components.

C3, C4 and C4b are qualified for the current checked runtime and synchronous
pure public profile. GC data/closures, generic conventions and current
Nat/Int/String/Array semantics use shared runtime IR. WIT, readable WAT and
direct component binaries share one explicit Canonical ABI plan, including
memory32 marshalling, allocation and post-return. Complete extracted contracts
and WAT/binary correspondence have independent qualification. The public profile
admits ordinary nonrecursive concrete aggregates and integer adapters; resources,
callbacks, recursive/proof-bearing foreign construction and effects require
separate explicit APIs. See PSCV0_NATIVE_WASM.md.

The user-selected option A is preserved: GC language values, linear memory only
at explicit ABI boundaries. Remaining backend work is C5 readable pre-erasure
Lean/ProofScript reconstruction and D measured performance/ownership work.
Compiler-source .ps migration, self-hosting and full v7 remain separate.
