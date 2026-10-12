# PSCV0 v7 native implementation roadmap

## Latest qualified native compiler milestone — 13 October 2026

**Qualified executable SHA:** `c810d6fe15d064968008d09849efd9ac5b2820de`.
**All-green Linux Actions:** https://github.com/dwijayuda/pskernel/actions/runs/38292170524.
**Official Lean:** 4.35.0-rc4 (`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`).
**Bounded source profile:** `pscv0-v7-native-bounded/48`, not complete v7.

The selected native Lean Standard environment now has a **reproducible
fingerprint**, `fnv1a64:3890664716772208725`. The portable serializer
captures all **208 installed declarations**, exact Core signatures/bodies
and constructor/recursor metadata, **11 class registrations**, **36 ordered
instance registrations**, priority/level metadata, and source aliases.
It length-prefixes every UTF-8 field and pins the upstream RC4 commit;
the FNV64 result is intentionally **not cryptographically strong** and
does **not confer proof authority**.

The separate exact Standard declaration/instance audit and expected
fingerprint gate now reject structural and metadata drift, including an
additional source-alias regression. Both the initial snapshot at
`c3445fc1`, [Linux 38291606077](https://github.com/dwijayuda/pskernel/actions/runs/38291606077),
and the pinned gate at `c810d6fe`, [Linux 38292170524](https://github.com/dwijayuda/pskernel/actions/runs/38292170524),
passed. The 168 portable/176 native Lean modules, 187 shared JS/TS/Rust/
V8 Wasm GC/Wasmtime observations, executable multi-module projects,
4 checked semantic programs and 92 negative observations remain green.
See `psc0/docs/PSCV0_STANDARD_SNAPSHOT_V1.md` for the deterministic
representation and trust limits.

Next core/essential requirements: fully faithful RC4 GetElem/GetElem?
with dependent validity proofs, allowlisted deriving handlers,
Float/scientific/fixed-width types, expanded collection/IO boundaries,
and the final cryptographic notation/import/tactic/effect/assumption
environment manifest. This selected fingerprint is a checkpoint, not
full v7 or full Standard conformance.

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
`c810d6fe15d064968008d09849efd9ac5b2820de`, [Linux run 38292170524](https://github.com/dwijayuda/pskernel/actions/runs/38292170524).
The shared matrix contains 187 runtime observations per target. This does
not constitute full v7 conformance or full RC4 module fidelity. Source
preparation, official admission checking, provenance, erasure and target
execution remain independent assurance boundaries.


The canonical language target is PSCV0_LANGUAGE_REFERENCE.md at its recorded v7
digest, with Lean 4.35.0-rc4 semantics. This is an implementation dependency map,
not a conformance claim. Exact qualified sources/runs are in AI_WORK_STATE.md.
Historical generated-source milestones do not certify the current native source.

## Complete Phase A–E language-first execution plan (authoritative overview)

This is the full dependency plan for **core/essential `pscv0` v7**, not five independently measured percentage scores. Phases may overlap where dependencies demand it. All require checked native `.lean` semantics; no other proof kernel or unchecked runtime escape is permitted. Sub-phases and acceptance detail are also present at the TOP of `psc0/AI_WORK_STATE.md`.

| Phase | Focus | Status and completion evidence |
|---|---|---|
| **A** | Pinned Standard environment, selected P0 language and runtime APIs | **In progress.** 208-declaration/11-class/36-instance deterministic FNV snapshot is qualified; exact RC4 GetElem validity/proof semantics, remaining deriving, Float/scientific/fixed-width/BitVec, complete curated APIs and cryptographic manifest remain |
| **B** | Dependent and mutual data, elimination, strict positivity and total recursive programming | **Planned.** Complete heterogeneous index reasoning, dependent motives, nested/mutual inductives, recursive pattern matrices and well-founded/structural termination; refuse invalid/partial constructs |
| **C** | General class-driven typed do, state, effectful control and explicit IO/FFI boundaries | **Planned.** Complete Monad/Except/State/Reader and selected transformers, mutable/erased state, loops/early returns, try/catch/finally, effect/capability evidence and all-target preservation |
| **D** | Kernel-checked tactics, intrinsic specifications, VC generation and assurance ledger | **Planned.** Complete selected rewrite/simp/automation, RC4 given/requires/ensures/assert/invariant/decreasing, WP/VC proof attachment, and verified-emission block on *any* unresolved mandatory obligation |
| **E** | Comprehensive conformance, independent evidence and final core/essential v7 integration | **Planned.** Reference-to-`PS-CONF-*` matrix, differential RC4 checking, reproducible cryptographic Standard+assumption closure, multi-module runtime matrix and audited verified acceptance gates |

### Phase A detailed exit gate

- **GetElem:** implement pinned RC4 `GetElem` and `GetElem?` with actual Prop-valued validity and Decidable/proof instances; `xs[i]` and `xs[i]'h` cannot discard proofs; `xs[i]?` returns Option safely; `xs[i]!` is a separately declared panic/default behavior, not a bounds proof. Do not confuse existing checked `List.get?` with the four forms.
- **Deriving:** accepted selected trailing handlers `Inhabited`/`BEq`/`DecidableEq`/`Repr`/`Hashable` must produce genuine checked and registered definitions with generated-source provenance. Unsupported cases and arbitrary handlers fail closed.
- **Scalars/libraries:** complete pinned `Float`/`Float32`/scientific, fixed-width/`BitVec` and selected arrays/bytes/string/collection conversions, then prove and execute target parity.
- **Registry:** supplement existing selected `fnv1a64:3890664716772208725` structural-drift check with a cryptographically pinned, complete RC4 module/notation/deriving/class/instance/tactic/effect/axiom manifest. Recompute/approve intentional semantic changes; never silently overwrite a frozen expected hash.

### Phase B detailed exit gate

Ensure formation/elimination of selected heterogeneous/indexed/dependent/recursive types, nested and mutual inductives, constructor consistency/positivity, independent motive checking, total structural and well-founded recursion. Check invalid indices/termination negative cases and runtime/proof erasure across all supported backends. No user `partial`/`unsafe` workaround.

### Phase C detailed exit gate

Generalize effects through common checked bind/pure/elaboration and appropriate instances, not a succession of one-off translations; add selected `StateT`/`ReaderT`/`ExceptT`, typed `do` and mutable/erased variables, loops, early return, throw/try/catch/finally and explicit world/IO boundaries. Specify effect and failure semantics independently of JS exceptions and validate the cross-target IR.

### Phase D detailed exit gate

Proof-producing tactics and rewriting/selected simp/omega/grind require pinned proof extensions and official kernel validation. Implement RC4-style `given`/`requires`/`ensures`, assertions, invariants/decreasing, `Std.WP`/`vcgen` and optional `where finally | spec` proof tails with a traceable obligation/effect/assumption/erasure ledger. **Verified executable output is forbidden while any mandatory proof, specification coverage, effect, assumption, termination or erasure obligation is unresolved.**

### Phase E detailed exit gate

Close a source-rule → positive/negative case → exact failure phase → Lean RC4 elaborated-term/semantic correspondence → verified IR/backend matrix. Independently validate assumption/primitive/erasure safety, crypto-pinned environment closure, multi-module linking and public APIs, JS/TS/Rust/Wasm GC/Wasmtime parity, and reproducible CI with fully recorded SHA, version/digest and evidence. Only then say core/essential v7 is complete. A green bounded profile is insufficient.

### Separate deferred workstreams: C5, backend D and later migration

**C5** readable pre-erasure source reconstruction, round-trip formatting and finer source maps happens **after** the A–E essential language closure. Existing backend **D** means *measured performance and ownership work*, not language Phase D. Compiler-source `.ps` migration, bootstrap/self-hosting, `pskernel-core` and wider P2 ecosystem are **not in this authorization**. Keep original protected branches/history, draft PR #109, Wasm GC internals and Canonical ABI-only linear memory.


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
