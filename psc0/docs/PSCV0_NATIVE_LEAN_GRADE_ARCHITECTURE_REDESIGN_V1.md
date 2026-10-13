# PSCV0 — Native Compiler Architecture Redesign v1

**Readable-output integration (13 October 2026):** [audit and dependency plan](PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md).
Preserve qualified JS/TS/Rust/WAT/WIT. Build C5 source retention with M2–M4's
semantic owners and finish selected PS/Lean reconstruction under M5/E after
required A–D closure. C5 branches from retained checked information before
erasure. Backend performance D belongs to M5. No new milestone sequence,
compiler-source migration, self-hosting or pskernel-core work is introduced.

**M2 bounded graph qualification (13 October 2026):** `a98062b2ac346c66c7f687bfe7e190d12470ba4d`,
[Linux 38398901889](https://github.com/dwijayuda/pskernel/actions/runs/38398901889), 251 observations.
The generator/consumer work queue, owned-context propagation and checked shared
answer replay are implemented; generalized answers and the unified constraint
scheduler remain open. See [design and measured boundaries](PSCV0_M2_INSTANCE_GRAPH_2026-10-13.md).
Interleave remaining A deriving work with these M2 dependencies.

**M1 qualification (13 October 2026):** M1 is complete for its declared
selected scope at `c00e146bd5c97788a4a6a39221849973aeafda84`,
[Linux 38388627512](https://github.com/dwijayuda/pskernel/actions/runs/38388627512).
See [acceptance and measured limits](PSCV0_M1_COMPLETION_2026-10-13.md).
M2 and remaining A now interleave; full architecture and v7 remain incomplete.
The implementation-status paragraphs below describe historical checkpoints.

**Date:** 2026-10-13 · **State:** normative target architecture and migration plan, **not** an implementation-complete or verified claim.  
**Branch:** `psc0/pscv0-v7-native-lean-v1` · **Baseline studied:** `b16ce3ae23cf04b330882d17d5bba15c5cd3fa88` · **Pinned upstream:** Lean `4.35.0-rc4`, commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.  
**Execution constraints:** portable native `.lean` compiler, official Lean checker, GitHub-first / Linux CI, no pskernel-core, no self-hosting, no C5 migration, retain Wasm GC internals and explicit Canonical ABI adapters. Preserve history and existing external contracts; internal abstractions may be removed.

**M0 implementation status (qualified):** Replaced the obsolete assumption that all type-formers reify as IR generic types. The four-kind checked binder classification and shared source-position masks are implemented across data/structure declarations, typed applications, partial/canonical call handling and projections. `GetElem.valid` is erased as an index without weakening IR checks. The official Lean source oracle, JS/TS/Rust source artifact checks and new **192-observation JS/TS/Rust/Wasm/Wasmtime matrix** are all green at `a678594`, [Linux 38312162188](https://github.com/dwijayuda/pskernel/actions/runs/38312162188). This qualifies a selected M0 vertical slice, **not** every higher-order dependent erasure shape, a semantics-preservation proof, or the M1–M5 end state.

**M1 and M2 implementation evidence:** [`PSCV0_M1_M2_IMPLEMENTATION_AUDIT_2026-10-13.md`](PSCV0_M1_M2_IMPLEMENTATION_AUDIT_2026-10-13.md). New native qualified executable `f8900407eaaa921097e6cd49d58551ca6558ed96`, [Linux 38315275940](https://github.com/dwijayuda/pskernel/actions/runs/38315275940): selected Type-0 optional indexing, 194 cross-target observations and checked per-invocation class answer memoization passed. Full M1/M2 and Lean parity remain incomplete.

## Architecture milestones and feature phases: execution order

M0–M5 and A–E are two dependency-linked views of one project, not sequential
checklists. Finish the current M1 acceptance boundary before full M2. Thereafter,
interleave coherent feature slices with their enabling architecture:

| Milestone | Architecture | Feature phase |
| --- | --- | --- |
| M0 | Shared typed erasure, proof/type/index masks, strict runtime IR | Foundation for A–E |
| M1 | Checked indexing and selected Standard closure | Indexing portion of A |
| M2 | Instance search, expected types, universes, priorities and rollback | Remaining A; enables B–D |
| M3 | Dependent/mutual data, elimination and total recursion | Primarily B |
| M4 | Class-driven effects, specifications, VC generation and assurance | Primarily C and D |
| M5 | Incremental compilation, validated optimization, tooling and performance | Consolidates A–D; final E integration |

A completes selected Standard APIs, deriving and the supported-language manifest.
B completes dependent data and total recursive programming. C completes typed
effects, state/control flow and explicit IO/FFI. D completes selected checked
tactics, specifications and verified-emission obligations. E establishes complete
conformance and cross-target integration evidence.

Collect E evidence with every feature slice; apply M5 performance/tooling work
when measurements and dependencies justify it. Do not delay all feature work
until M5: M5 acceptance itself requires A–E conformance. Do not implement feature
special cases ahead of their shared mechanisms. These dependencies do not claim
that M0's qualified subset or any later full milestone is already complete.

## 0. Outcome and evaluation standard

Deliver a **maintainable, soundly checked selected language compiler**, with a sufficiently generic elaborator, explicit dependent erasure, one audited target-neutral IR, and high-performance JS/TS/Rust/Wasm GC backends. Architecture quality must be assessed against *actual pinned Lean designs*, not simply by matching source syntax or number of features.

**Equal/better-quality criteria must be measured, never declared:**
1. **Admission:** every accepted Core declaration and its assumptions validated by the official Lean kernel; malformed/unresolved definitions refused.
2. **Erasure:** proof/type/index erasure justified by a checked, total classification of the Core telescope. No `.unknown` in runtime IR. Type-level dependencies cannot be consumed at runtime.
3. **Semantic preservation:** selected source cases and backend results agree on observables; exact panic, overflow, string and numeric semantics, with a declared primitive trust ledger.
4. **Architecture:** one representation of each invariant, bounded deterministic resource behavior, stable source diagnostics, no duplicated lowering logic or test-case exceptions.
5. **Performance:** comparable measured compile latency/memory, typeclass search growth, runtime throughput/allocation, stack behavior, and worst-case valid inputs against pinned Lean; report regression as a regression.
6. **Assurance:** verified emission blocked by every unresolved proof, specification coverage, effect, assumption, termination or erasure obligation. This remains an end-state goal, not a capability today.

## 1. Upstream architectural lessons (source inspected)

| Concern | Lean RC4 source | Mechanism to adopt, not blindly transplant |
| --- | --- | --- |
| Kernel | [`src/kernel/type_checker.cpp`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/type_checker.cpp), [`environment.cpp`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/environment.cpp), [`inductive.cpp`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/inductive.cpp) | Minimal trusted acceptance, unsafe/partial separation, positivity / recursors; never claim the PSC front end to be another kernel |
| Parser/commands | [`Lean/Parser/Basic.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Parser/Basic.lean), [`Lean/Elab/Frontend.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/Frontend.lean) | Deterministic token+syntax ownership, parser extension/versioning, incremental environments and precise spans |
| Elaborator | [`Lean/Elab/App.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/App.lean), [`SyntheticMVars.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/SyntheticMVars.lean) | Uniform telescope walk, expected-type flow, postponed constraints and scheduled retries rather than eager one-off guessing |
| Typeclasses | [`Lean/Meta/SynthInstance.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Meta/SynthInstance.lean) | Tabled resolution, canonical/normalized goal keys, generator/consumer nodes, candidate priority, local-instance ordering and resource budgets |
| Induction / termination | [`Lean/Elab/Inductive.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/Inductive.lean), [`MutualDef.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/MutualDef.lean) | One positivity/elimination plan, checked recursors, SCC-aware mutual termination and explicit WF proof obligations |
| Proofs / indexed access | [`Init/GetElem.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/GetElem.lean), [`Init/Tactics.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/Tactics.lean) | True `Prop` validity, `Decidable` and `LawfulGetElem`, structured goal closing; no unchecked index shortcuts |
| Proof/type erasure | [`Lean/Compiler/LCNF/ToLCNF.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Compiler/LCNF/ToLCNF.lean), [`ToMono.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Compiler/LCNF/ToMono.lean), [`MonoTypes.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Compiler/LCNF/MonoTypes.lean) | **Separate type-formers, proof irrelevance, computable values and runtime-reifiable mono types.** Lean's `Arg.type` is erased in mono lowering; type formers need not become IR type arguments |
| Low-level compiler | [`LCNF/Main.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Compiler/LCNF/Main.lean), [`PassManager.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Compiler/LCNF/PassManager.lean), [`ToImpure.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Compiler/LCNF/ToImpure.lean) | Distinct typed lowering phases, typed passes/checkpoints, SCC & closure phases, allocation/resource analysis; do not duplicate optimization in each backend |
| Runtime specialization | [`LCNF/Specialize.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Compiler/LCNF/Specialize.lean), [`Init/Data/List/Impl.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/Data/List/Impl.lean) | Semantic baseline with separately justified specialization and regression budget; no silent assumption of `take/drop` complexity parity |

## 2. Current source findings and root-cause diagnosis

**Live baseline at design drafting:** `b16ce3ae23cf04b330882d17d5bba15c5cd3fa88`; last all-green *executable* `e1d463e10cbf5edd817e362ed35b21ee82c8c85b` ([Linux 38304955212](https://github.com/dwijayuda/pskernel/actions/runs/38304955212)). The newer [Linux 38307096314](https://github.com/dwijayuda/pskernel/actions/runs/38307096314) failed at typed IR emission after checked `GetElem` source with `unknown-type` annotations and equality operands. This audit does **not** claim green current HEAD.

- `Ps.Erasure.Basic`: `PsErasedBinderKind = type | proof | runtime`; `psErasureClassifyBinder` currently maps **both** reifiable type parameters and *higher-kinded `coll → idx → Prop` predicates* to `.type`.
- `Ps.Erasure.Definition`: every `.type` becomes a visible `PsVerifiedIrTypeParameter` and increases `typeArity`.
- `Ps.Erasure.Expr`: every `.type` application argument is passed to `psEraseRuntimeType`, which correctly cannot represent dependent `valid` and yields `.unknown`. Partial applications, lambdas, structures and recursors use related assumptions.
- `Ps.Erasure.Inductive`: **all** inductive params are currently assumed to be type parameters; class `GetElem` has four Core parameters but only three reasonable reifiable type arguments. `PsRuntimeStructureInfo.numParams` conflates Core parameter count with runtime type parameter count. Structure construction and projection implicitly inherit the mismatch.
- `Ps.CompilerIr.Model`: `PsVerifiedIrType.unknown` is a diagnostic intermediate, not a legal executable type; `Ps.CompilerIr.CheckTypes` correctly rejects it.
- `Ps.Host.NativeV7` explicitly checks official kernel admission **before** erasure; `Ps.Host.PrimitiveAudit` compares *signatures* of selected trusted primitives but does not prove implementation equivalence.
- `Ps.Meta.SynthInstance` implements fuel-limited priority search and active-key cycle rejection, not Lean's answer-tabled producer/consumer solver.
- `Ps.Elab.Do` has closed `identity | option | except` variants rather than class-driven effects; `Ps.Elab.Data` still gates positivity and nested recursion through selected shapes.

These are system-level boundaries; repairing `GetElem` by allowing unknown types would make future dependent classes unsafe/uncheckable.

## 3. Target architecture: typed, staged and proof-preserving

```text
Unicode .ps source + frozen source/capability manifest
  → Lossless token/syntax tree + source owner/span mapping
  → Pure macro/notation resolution (pinned registry + provenance)
  → Constraint-producing elaborator (terms, levels, classes, effects, recursion)
  → Closure solver (tabled instances; postponed goals; typed proof terms)
  → Kernel-ready Core + normalized declarations + proof/spec provenance
  → OFFICIAL LEAN KERNEL CHECK (no alternate checker)
  → CheckedSession[manifestDigest, kernelAdmission, CoreDeclGraph]
  → Typed erasure plan: CoreBinderRole × CoreIndexUse × RuntimeShape
  → Runtime-relevant ANF / typed IR (no unknown, no proof consumption)
  → IR validation: types + calls + arity + effects + proof-erasure evidence
  → Shared specialization/closure allocation passes
      ├── direct JS (ESM)
      ├── TS
      ├── Rust
      ├── Wasm GC core
      └── Wasm component with explicit Canonical ABI adapters
  → Artifact boundary
      checked: selected Core and runtime checks passed
      verified: ALSO every mandatory proof/spec/termination/effect/
                assumption/erasure obligation discharged
```

Do **not** put an executable erasure proof inside an ambient JS/TS/C ABI type. The checked erasure-plan identity belongs to a typed metadata layer alongside runtime IR, independent of readable frontend syntax.

### 3.1 One Core telescope and binder-role contract

Define *one* classification, used consistently by declarations, applications, constructor/recursor parameters and local functions:

| Role | Core meaning | Executable representation |
| --- | --- | --- |
| `runtimeValue` | ordinary computational argument | Runtime value and strict IR type |
| `runtimeType` | `α : Sort u`, whose **types** are expressible in the selected IR | Type parameter; must be reifiable at every application |
| `erasedTypeIndex` | higher-kinded type former / `coll → idx → Prop` / erased dependent parameter | **No** runtime value or IR type argument. Exact Core argument remains for type checking/instantiation |
| `erasedProof` | `p : Prop` | proof erased; if existing ABI needs Unit placeholder, it is explicitly audited and uniform |
| `unsupported` | shape whose runtime dependence cannot be proved absent or whose representation is unqualified | fail at typed erasure with an actionable phase diagnostic |

**Critical:** `Sort` vs `Prop` is computed using the checked Core context, *not* just syntactic names; for higher-order functions inspect the dependent telescope in the extended local context. A predicate family type may have `Pi` binders ending in `Sort 0` and must be erased as a family, not reified as `.unknown`.

**Proof obligation for erasing a parameter**: runtime body does not reference its value through an executable path; the erased Core value can still be substituted into types/propositions to type-check later binders. Any runtime use is a hard error.

**Plan shape** (conceptual; not all fields implemented yet):

```lean
structure CheckedErasureParam where
  sourceIndex : Nat
  sourceBinder : PsName
  coreDomain : PsExpr
  role : PsErasureBinderRole
  reifiedIrType : Option PsVerifiedIrType
structure CheckedErasureTelescope where
  sourceArity : Nat
  parameters : List CheckedErasureParam
  runtimeArity : Nat
  reifiedTypeArity : Nat
  -- independent source→target parameter/field maps and erasure ledger
```

Parameter/field plans preserve Core *source position* so a runtime constructor may have, say, four Core parameters but only three reified IR types. Require every call/record/recursor/projector and internal dictionary to consult the **same mask**, not a duplicate `take numParams` slice. Keep different source indices for fields and for reified type parameters.

### 3.2 Compiler stage invariants

- **Elaboration → checked Core:** no unresolved metavariables, unvalidated positivity, unproved termination, or hidden admitted assumptions; official Lean checker is the decision boundary.
- **Checked Core → erasure plan:** every source binder classified once, with explicit role and consistent source index; no speculative runtime side effects.
- **Erasure plan → runtime IR:** number and order of reified types and values exactly match the plan, across full and partial applications, closure captures, constructors, recursors and projections.
- **IR checker:** no `.unknown` annotations, no invented equality, no mismatched type substitution, no unbound runtime local, no erasure of computationally relevant data.
- **Backends:** implement only validated IR constructs; obey wasm GC + Canonical ABI isolation. Do not let a backend silently introduce evidence.
- **Assurance boundary:** emission cannot occur after failed kernel/IR/mandatory verified obligations.

### 3.3 Clean module boundaries and migration

`Ps.Erasure.Basic` should own the shared Core binder role and source-index plan; `Ps.Erasure.Definition`, `Ps.Erasure.Inductive` and `Ps.Erasure.Expr` should **consume**, never duplicate, the plan. `Ps.CompilerIr` remains backend-neutral. `Ps.Host.NativeV7` is the trusted *orchestration* boundary, not another proof kernel. A future provider-neutral checked-session type should be impossible to construct from ordinary prepared source.

Within the existing portable project, prefer a small number of strong types/functions over inheritance scaffolding, stringly typed accessors, generated fake `Unit` type arguments, identity casts, or legacy compatible paths.

## 4. Coherent implementation phases and acceptance gates

### M0 — Typed erasure redesign (first, BLOCKING)

1. Extract/rewrite **one** classifier covering runtime values, reifiable runtime types, erased predicate/type-former indices, and proofs. Verify on checked local contexts and nested dependent binder sequences.
2. Introduce a normalized Core parameter map for all closed declarations and inductives. Store source indices for retained runtime type parameters. Erase non-runtime predicate families and do not call `psEraseRuntimeType` on them.
3. Update declaration arity and name indices, local functions/partial application, dictionaries, inductive/structure constructors, recursors, `getElem` projection, polymorphic `GetElem.valid` domains, type equality and monomorphization **together**.
4. Add positive oracle cases with arbitrary user-defined `GetElem`, `valid xs i := i = 0`, `True`, `True ∧ True`; explicit/local/rfl/constructor proofs; invalid proof case must be rejected at elaboration. Type emission must cover strict JS/TS/Rust and Wasm if supported; don't count absent targets as passing.
5. CI must be green for official Lean, source emission, module closure, and all established 187-observation target regressions. Record precise SHA and CI; no snapshot drift unless selected Core prelude actually changes.

### M1 — Exact indexing universe and Standard closure

Faithfully implement `GetElem?` *extending* `GetElem`, dependent valid propositions, decidable witnesses, `LawfulGetElem`, optional lookup, true panic/default behavior (do **not** silently return default), checked List/Array/Fin instances and selected arithmetic proof generation. Lean standard `Option`/type universes must not be falsely reduced for the public contract. Record performance of list and array access separately.

### M2 — Elaborator architecture

Replace depth-first recomputation with normalized, answer-tabled instance resolution and suspended dependencies. Integrate expected-type constraints, universe metavariables, default argument priority and local/ordered instance registries; retain deterministic budgets and rollback. Implement against pinned source oracle with differential cases and measured worst-case complexity, not merely green happy paths. Retain ordered binder groups, resolved references, default/implicit decisions and occurrence provenance at these owners for C5; metadata must not change Core identity.

### M3 — Dependent data and recursion

Normalize data/recursor declarations and their runtime masks; generalize positivity/elimination plans, mutual SCC, nested uniform parameters, WF termination obligations, recursion erasure and proof irrelevance. Fail closed on unrepresentable recursion. Retain source-to-generated motives, equation/recursor associations and totality evidence for C5 rather than recovering them from erased IR.

### M4 — Class-driven effects, specifications, verification factory

One monad/effect dictionary elaborator; `State`, `Reader`, `Except` and selected transformers; effect/capability provenance and indexed `do`. Produce `given`/`requires`/`ensures` and VC proof constraints using the pinned `Std.WP` where suitable. Build a full proof/spec/effect/assumption/erasure ledger; *verified* emission gated on every mandatory obligation. Preserve typed source control/specification/proof provenance for all output projections.

### M5 — Lean-grade compilation and tooling

Incremental dependency graph with stable hash keys including frozen syntax/instance/environment state; typed ANF/LCNF-inspired phases and validations; selective specialization and closure layout; documented cost models and benchmarks for compiler+runtime. Use Lean's proven `@[csimp]` pattern conceptually for direct checked `List.take/drop` worker parity, without assuming a target-level optimization is proof. Complete C5 readable Lean/PS publication and checked correspondence after the required A–D semantics are available, using retention built during M2–M4. Finish shared naming/layout/origin precision alongside measured code improvements. Full Phase A–E conformance and independent differential/negative/cross-backend/source-correspondence evidence are required before any claim of equivalence.

## 5. Research/conformance registry for M0

| Test ID | Checked requirement | Failure condition |
| --- | --- | --- |
| `PS-CONF-ERASE-001` | `α : Type` reifies as a checked IR type parameter | Unknown or out-of-scope type variable |
| `PS-CONF-ERASE-002` | `P : coll → idx → Prop` is erased as an index in both dictionary declaration and use | Unchecked `unknown` argument or runtime proof predicate |
| `PS-CONF-ERASE-003` | `h : P xs i` never survives as executable evidence | Proof read at runtime |
| `PS-CONF-ERASE-004` | GetElem constructor and method have matching source→IR arity/shape | Incorrect generic arguments, application or source indices |
| `PS-CONF-ERASE-005` | Partial calls and returned functions preserve only their real runtime binders | Phantom type/proof parameter applied at runtime |
| `PS-CONF-ERASE-006` | Data constructor, structure projection and recursor use the same type-parameter source mask | Different substitutions or unknown-type |
| `PS-CONF-ERASE-007` | Unsupported runtime-dependent index use is refused, not represented as Unit/unknown | False acceptance |
| `PS-CONF-ERASE-008` | No change to existing native+JS/TS/Rust/Wasm GC regression outputs | Behavioral regression |
| `PS-CONF-ERASE-009` | Selected Standard FNV/SHA-256 and official Lean admitted declarations stable | Unreviewed drift |
| `PS-CONF-ERASE-010` | Fuel/resource budgets fail closed; no hidden auto-admission | Unbounded loops or unresolved goals |

**Reporting requirements:** separate *design complete*, *code implemented*, *official Lean admitted*, *IR validated*, *backend emitted*, *runtime behavior qualified*, *performance measured* and *full v7 accepted*. ACI/CI status never applies to a newer unqualified commit.

## 6. Explicit non-goals and tradeoffs

- Rewriting all PSCV0 as Lean's frontend is not a prerequisite; reuse official Lean checker and proving facilities at well-defined interfaces.
- Neither claiming parity with Lean from line count nor introducing a second independent kernel is sound engineering.
- The independent PSC surface remains useful if source ergonomics, verification-gated software compilation and direct JS/TS/Rust/Wasm backends are real differentiators.
- Do not treat existing Type-0 `Option`, `Decidable`, or class representations as full Lean universe fidelity before checking the pinned upstream declarations.
- New IR machinery must be no more complex than the properties it guarantees. Avoid universal representation features with no user-level necessity; preserve the ABI/Rust/GC backends that have already passed their selected observations.
