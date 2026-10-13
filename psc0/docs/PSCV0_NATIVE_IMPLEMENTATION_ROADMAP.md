# PSCV0 v7 native implementation roadmap

## Current qualified checkpoint — M1 universes and bounded index proofs (13 October 2026)

This section supersedes older checkpoint claims below.

- **Executable:** [4fe35ca32b8f3b49f85b89bb9b699d95f7fd7b7d](https://github.com/dwijayuda/pskernel/commit/4fe35ca32b8f3b49f85b89bb9b699d95f7fd7b7d).
- **Green Linux qualification:** [38382777891](https://github.com/dwijayuda/pskernel/actions/runs/38382777891), official Lean 4.35.0-rc4.
- **Selected Standard:** 258 declarations, 14 classes, 43 ordered instances; 171 portable / 179 native Lean modules.
- **Frozen FNV:** `fnv1a64:7381279441732502588`.
- **Frozen SHA-256:** `sha256:c1444324de1014fa01b9c82fb09f2a6ab96b824ac08ae6b6e548e2145fd61c85`.
- **215 shared runtime observations** passed in direct JS, strict TS, Rust, V8 Wasm GC and the native Wasmtime component host. All prior 198 observations remain.

Qualified: universe-polymorphic Option constructors/recursor, map/bind/getD/filter,
BEq and Inhabited; GetElem?, default implementation and both LawfulGetElem laws
at the element universe; higher-universe dictionary synthesis and erasure.
Explicit Option.bind may change universes; monadic Option do fixes a single
universe as RC4 does. An independent oracle and a negative do case cover that boundary.

Index automation now constructs checked natural-order proofs from definitional
normalization, closed comparisons, successor rules and bounded local transitivity
search. It is not full omega. Large natural indices remain arbitrary precision.
The unifier first tries congruence for a shared named application head, retaining
dictionary argument identity; failure rolls back and uses ordinary reduction.
This avoids unfolding an inferable dictionary argument into applied metavariables.

The official kernel admitted the selected definitions and source proofs; strict
IR and all existing runtime gates passed. Single-run all-target timings: parse
110 ms, elaborate 93 ms, prepare 121 ms, kernel 70 ms, erase 251 ms, emit 494 ms.
These are observations, not a controlled performance comparison.

**M1 remains incomplete.** Next: checked List/Fin indexing and optimized optional
laws, Array logical model and genuine size bounds, panic/alias/large-index coverage,
and controlled representative performance comparisons. Full M2 waiter tabling,
C5, pskernel-core and self-hosting remain excluded. Read live HEAD and CI first.

## Prior qualified checkpoint — M1 natural order (13 October 2026)

This section supersedes older status statements below; historical evidence is preserved.

- **Executable:** [064baf31641ff19785feae1416eb353b38737794](https://github.com/dwijayuda/pskernel/commit/064baf31641ff19785feae1416eb353b38737794).
- **Green Linux qualification:** [38379674588](https://github.com/dwijayuda/pskernel/actions/runs/38379674588), official Lean 4.35.0-rc4.
- **Selected Standard:** 258 declarations, 14 classes, 43 ordered instances.
- **Frozen FNV:** `fnv1a64:10485782345918084284`.
- **Frozen SHA-256:** `sha256:37a8c7e027c548b59a82060556e194051867ee10d02e5b02b1f20c4875693ce5`.
- **Native closure:** 171 portable / 179 total Lean modules.
- **Runtime observations:** 206 shared cases, preserving the previous 198; direct JS, strict TS, Rust, Wasm GC and Wasmtime component gates passed.

Qualified additions: Prop-only Nat.le recursor; checked zero, successor,
transitivity, predecessor/inversion and impossible-zero proofs; checked
Nat.ble logical model; checked Boolean reflection; Nat.decLe/Nat.decLt
dictionaries. Decidable.intro and its computational projection now erase
consistently to Bool. The reflection field is erased, not trusted as an
unchecked witness. Runtime comparison keeps the existing Nat.ble intrinsic.

The same run checked the independent RC4 source oracle and false-bound
rejection, admitted source proofs with the official kernel, validated strict
IR and qualified emitted artifacts. This is **not a compiler correctness
proof or full M1 completion**. A single measured all-target application run
reported prelude 10 ms, parse 98 ms, elaborate 93 ms, prepare 297 ms,
kernel 66 ms, erase 112 ms and emit 455 ms; these are observations, not
controlled performance comparisons.

**Next M1 dependencies:** universe-polymorphic Option/GetElem?/laws and
universe-aware do binding; bounded proof-producing index automation; complete
List/Array/Fin indexing, optimized optional laws, coherent panic behavior and
representative performance comparisons. Full M2 tabling, C5, pskernel-core
and self-hosting remain excluded. Re-read live HEAD and CI before editing.
Do not repeat the older Decidable-uniqueness work: it was already qualified.


## Latest M1 foundation qualification — 13 October 2026

**Newest independently qualified executable:** [`e0ac8c69c928261e21e9593ed3f2f4aa5157385a`](https://github.com/dwijayuda/pskernel/commit/e0ac8c69c928261e21e9593ed3f2f4aa5157385a), Linux GitHub Actions [38335736466](https://github.com/dwijayuda/pskernel/actions/runs/38335736466) **passed** (13 October 2026). This supersedes older executable-status statements below, which remain as preserved history. The pinned upstream is Lean 4.35.0-rc4 (`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`). The selected Standard now contains **234 declarations, 14 classes, 40 instances**, FNV `fnv1a64:403111548970955669`, SHA-256 `sha256:6e6f1fad15d4f0cb401a09c1ebc219c3f60dd50acb21061ca9eee4ab782bd85e`; portable/native closure remains 170/178 `.lean` modules with 198 shared runtime observations on TS, direct JS, Rust, and Wasm GC/Wasmtime.

The selected RC4-compatible decision foundation has been replaced with checked `Decidable` structure, constructor, projections, Boolean reflection predicate and reducible dependent `dite`. Native metavariable-closed proof irrelevance unifies **actual proofs of the same checked Prop**, not arbitrary data or Bool terms. An official-kernel source oracle proves excluded middle from a provided `Decidable` and equality of any two witnesses of one proposition. The independently quantified decision-dictionary uniqueness theorem remains **unproved**, following a dependent-elaboration mismatch, and there is still **no generic `LawfulGetElem` instance**. List/Array/Fin indexing, Type-0 Option generalization and M2 waiter tabling remain unqualified. The older `fc8bc8b` milestone below is historical.


**New-chat handoff (13 October 2026):** `psc0/AI_WORK_STATE.md` and `psc0/AI_CONTINUE_PROMPT.md` now specify the M1-then-M2 implementation order. Last green executable remains `fc8bc8b`, [CI 38323422371](https://github.com/dwijayuda/pskernel/actions/runs/38323422371); newer documents are not executable qualifications. M1's checked optional default and target panic are done; generic lawfulness and collections are open. M2's scoped answer memo and independent budgets are done; generator/consumer waiters remain open. Keep native `.lean`, minimal milestone tests, no pskernel-core/self-hosting/C5.

## Latest qualified native compiler milestone — 13 October 2026

**Qualified executable SHA:** `fc8bc8b1f16ed993fb144e2d396c0760c068630b`.
**All-green Linux Actions:** https://github.com/dwijayuda/pskernel/actions/runs/38323422371.
**Official Lean:** 4.35.0-rc4 (`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`).
**Bounded source profile:** `pscv0-v7-native-bounded/48`, **not** complete v7.

**Newest qualified M1/M2 update (supersedes historical milestone prose below):**
The selected Type-0 `GetElem?` is automatically derived at low priority from a checked `GetElem` dictionary and a dependent `Decidable` function. Kernel-proof validity remains separate from runtime Bool. Executable `outOfBounds` has a typed multi-target panic path; the selected positive/negative optional observations passed. A general `LawfulGetElem` instance is NOT qualified: reflexivity cannot identify independently provided decision procedures. `Ps.Meta.SynthInstance` now bounds both candidate checks and goal visits independently, postpones unresolved inputs, and reuses validated completed answers. **230 declarations, 14 classes, 40 ordered instances, 198 shared runtime observations**. Detailed proof blocker and next dependencies are in [M1/M2 implementation audit](PSCV0_M1_M2_IMPLEMENTATION_AUDIT_2026-10-13.md). Full M1/M2 and v7 remain incomplete.

**Historical M0 checkpoint (superseded by the qualified M1/M2 update above):** The earlier Lean RC4-style `GetElem` typeclass and proof-carrying
`xs[i]`/`xs[i]'h` elaboration now qualify for user-defined instances.
The generated validity tactic tries genuine assumptions, definitional
reflexivity and fuel-bounded recursive constructor proofs, refusing
unresolved goals. At the M0 checkpoint, parsed `xs[i]?` and `xs[i]!` were **not yet executable conformance**:
the full `GetElem?`/default/lawfulness and out-of-bounds panic contracts
remain open. See [GetElem RC4 design/parity audit](PSCV0_GETELEM_RC4_DESIGN_AUDIT.md).

The **historical** selected prelude milestone was **221 declarations, 13 classes and
37 ordered instances**, at FNV `fnv1a64:4160132988510892817` and SHA-256
`sha256:a02c9f39e6de1830497114edfaad5e9bdd5730110b562585e3f6ecc30b80b6d3`. The source-closure guard passed
**170 portable / 178 native Lean modules**. All established **194 shared
JS/TS/Rust/Wasm runtime observations** and official Lean native checks
remain green. These are bounded qualification observations, not a proof
of full Lean RC4 Standard or complete v7.

Further Phase A work: universe-polymorphic `Option`/related Standard
prerequisites, actual indexed List/Array/Fin validity and lawfulness
proofs, `GetElem?`/panic boundaries, complete deriving and scalar/API
coverage, and pinned imports/notation/tactic/effect/assumption closure.
Phases B–E and C5 remain as documented below.

**Historical architecture audit (failed precursor, now resolved by M0):** `1cc7deb56b2b6ec37ee3a6c1eac148d113899ac7`, [Linux 38307096314](https://github.com/dwijayuda/pskernel/actions/runs/38307096314) failed at `ir/emit` because dependent `GetElem` predicate/index arguments become `unknown` runtime IR type annotations. Lean RC4 source-level oracle passed. See [`PSCV0_V7_LEAN435RC4_SOURCE_ARCHITECTURE_REVIEW_2026-10-13.md`](PSCV0_V7_LEAN435RC4_SOURCE_ARCHITECTURE_REVIEW_2026-10-13.md). **The last green executable remains `e1d463e10cbf5edd817e362ed35b21ee82c8c85b` and run 38304955212.**

**M1/M2 accepted subset:** See [native M1/M2 implementation audit](PSCV0_M1_M2_IMPLEMENTATION_AUDIT_2026-10-13.md) for precise status. `GetElem?` Type-0 selected and tabled positive-answer memoization passed 194 observations, but neither full M1 nor full M2 is complete. This supersedes the older “parsed only” status above and the historical GetElem audit statements.

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

Selected language profiles 36–48, module foundation and M0 erasure redesign are recorded
in AI_WORK_STATE.md. Latest qualified executable source:
`f8900407eaaa921097e6cd49d58551ca6558ed96`, [Linux run 38315275940](https://github.com/dwijayuda/pskernel/actions/runs/38315275940).
The current shared matrix contains 198 runtime observations per target, including five original proof-indexed dictionary computations and two selected optional/bang observations. This does
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
| **A** | Pinned Standard environment, selected P0 language and runtime APIs | **In progress.** Current selected Standard **230 declarations / 14 classes / 40 instances**, FNV + SHA-256 gated, 198 shared observations. Qualified proof-carrying `GetElem`, Type-0 derived `GetElem?` from checked dependent `Decidable`, typed panic, and selected runtime results. Pending **generic `LawfulGetElem` proof**, faithful List/Array/Fin validity, Option universes, broader proof-producing index automation, further deriving/scalars/APIs and full notation/import/effect/assumption closure |
| **B** | Dependent and mutual data, elimination, strict positivity and total recursive programming | **Planned.** Complete heterogeneous index reasoning, dependent motives, nested/mutual inductives, recursive pattern matrices and well-founded/structural termination; refuse invalid/partial constructs |
| **C** | General class-driven typed do, state, effectful control and explicit IO/FFI boundaries | **Planned.** Complete Monad/Except/State/Reader and selected transformers, mutable/erased state, loops/early returns, try/catch/finally, effect/capability evidence and all-target preservation |
| **D** | Kernel-checked tactics, intrinsic specifications, VC generation and assurance ledger | **Planned.** Complete selected rewrite/simp/automation, RC4 given/requires/ensures/assert/invariant/decreasing, WP/VC proof attachment, and verified-emission block on *any* unresolved mandatory obligation |
| **E** | Comprehensive conformance, independent evidence and final core/essential v7 integration | **Planned.** Reference-to-`PS-CONF-*` matrix, differential RC4 checking, reproducible cryptographic Standard+assumption closure, multi-module runtime matrix and audited verified acceptance gates |

### Phase A detailed exit gate

- **GetElem:** implement pinned RC4 `GetElem` and `GetElem?` with actual Prop-valued validity and Decidable/proof instances; `xs[i]` and `xs[i]'h` cannot discard proofs; `xs[i]?` returns Option safely; `xs[i]!` is a separately declared panic/default behavior, not a bounds proof. Do not confuse existing checked `List.get?` with the four forms.
- **Deriving:** accepted selected trailing handlers `Inhabited`/`BEq`/`DecidableEq`/`Repr`/`Hashable` must produce genuine checked and registered definitions with generated-source provenance. Unsupported cases and arbitrary handlers fail closed.
- **Scalars/libraries:** complete pinned `Float`/`Float32`/scientific, fixed-width/`BitVec` and selected arrays/bytes/string/collection conversions, then prove and execute target parity.
- **Registry:** preserve the selected SHA-256 (`sha256:9c865069b931ad1bb44a9c4861cb9748964c99368d3a7e2c4f2c75e5a099d265`) and FNV (`fnv1a64:2902463666082847583`) roster drift gates; separately finish a comprehensive cryptographic RC4 module/notation/deriving/class/instance/tactic/effect/axiom manifest (not yet qualified). Recompute/approve intentional semantic changes; never silently overwrite a frozen expected hash.

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
