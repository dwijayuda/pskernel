# PSCV0 native implementation roadmap

Updated 16 October 2026. **M2 + Phase A is COMPLETE for the selected `pscv0-v7-native-bounded/73` profile.** Exact integration `2a7072064974cb0d051a1773a26caf15fc59838b` passed native and all three independent replay workflows. The authoritative checkpoint is [AI_WORK_STATE](../AI_WORK_STATE.md); the [M2+A exit review](PSCV0_M2_A_EXIT_REVIEW_2026-10-16.md) maps the unchanged criteria to implementation owners and evidence, and the [final integration receipt](PSCV0_M2_A_INTEGRATION_QUALIFICATION_2026-10-16.md) records exact runs, artifact and measurements. M3–M5 remain open.

This file separates the current dependency plan from dated progress journals. The research journal is preserved byte-for-byte in [research history](PSCV0_NATIVE_IMPLEMENTATION_ROADMAP_RESEARCH_HISTORY_2026-10-16.md), Git blob `9b26701a2a9da370569dc060857be85be0cb8e25`; the concurrent development journal is preserved in [development history](PSCV0_NATIVE_IMPLEMENTATION_ROADMAP_DEVELOPMENT_HISTORY_2026-10-16.md), blob `6e6b288443f65424f03c09de45d437fde3dcf1e6`. Their old stop instructions, pending runs and profile counts describe historical checkpoints, not current authority. No historical receipt or acceptance criterion is discarded.

## Architecture and trust boundaries

The semantic compiler remains native portable `.lean`, checked by official Lean **4.35.0**, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Preserve syntax -> resolution -> elaboration -> prepared Core -> official checking -> typed erasure -> validated IR -> backend boundaries, with one retained prepared graph across checking and emission. Study the pinned Lean implementation before substantial changes; reuse mechanisms, not frontend fallbacks or new unchecked authority.

Only `propext` and `Quot.sound` are approved logical assumptions. Newer v7.1/v7.2 language-reference proposals are preserved design work, not automatic admission of partial/unsafe/fixpoint policies into the selected executable profile. No pskernel-core, compiler-source `.ps` migration, self-hosting or C5 execution belongs to this M2+A task. Wasm uses GC for language objects and linear memory only at explicit Canonical ABI boundaries.

## Interleaved dependency order

| Milestone | Architecture | Feature phase and boundary |
| --- | --- | --- |
| M0 | Shared typed erasure, proof/type/index masks, strict runtime IR | Qualified selected foundation; not the whole language. |
| M1 | Checked indexing and selected Standard closure | Indexing portion of A is complete; retain its laws, refusal and performance gates. |
| M2 | Shared expected-type and universe constraints, scoped instance search, priorities/defaults, rollback, replay and source retention | Selected A complete and exact integration accepted; enables B–D without claiming those phases complete. |
| M3 | Dependent/mutual data, elimination and total recursion | Primarily B, including broader deriving families. |
| M4 | Class-driven effects, specifications, VC generation and assurance | Primarily C and D. |
| M5 | Incremental compilation, validated optimization, tooling and performance | Consolidates A–D and final E; full C5 reconstruction/correspondence belongs here. |

Execute **M2+A -> M3+B -> M4+C/D -> M5/E**. Collect E evidence throughout and apply measured performance work when dependencies justify it. Do not add feature-specific workarounds ahead of shared mechanisms. Runtime observations are not general compiler-preservation proofs.

## M2 + Phase A acceptance

The selected profile is `pscv0-v7-native-bounded/73`; it is not full v7 or all Lean extensions. The profile's declaration roster, live surface registries and selected policies are separately pinned. Completion requires all of the following, without weakening existing tests, budgets or assumptions.

1. **Checked indexing and libraries.** Retain actual Prop-valued GetElem/GetElem? validity, Decidable and lawfulness proofs, explicit/automatic proof forms, safe optional indexing and separately declared bang/panic behavior. Complete selected Float/Float32/scientific, fixed-word/BitVec, arrays/bytes/strings/collection conversions with checked logical assets and cross-target execution. Explicit USize/ISize 32/64 execution must not specialize opaque logical platform width.
2. **Selected deriving.** Inhabited, BEq, DecidableEq, Repr and Hashable generate genuine checked registered definitions and generated-source provenance. Unsupported families or arbitrary handlers fail closed. General recursive/indexed/dependent deriving remains M3+B, not an undeclared expansion of this selected gate.
3. **Common M2 constraints and search.** Expected types, operator identity, universe instantiation, ordinary/default priorities, structural scoped instance keys, consumer wakeup and fresh answer replay must preserve captured scopes and transactional rollback. Independent resource limits, collision checks, pending-work ownership and rejection paths remain enforced. Report measured scaling counters, not assumed complexity or complete Lean-elaborator equivalence.
4. **Source retention.** Preserve binder groups/IDs, references/projections, inserted arguments/evidence, final assignments and saved local contexts through scoped resumption. Exactly-once retained projections and containment checks are required. This is preparation for C5, not source reconstruction or round-trip correctness.
5. **Comprehensive selected registry and provenance.** Preserve independently observed dual declaration hashes and separate surface-v3 digest. Audit live notation/precedence, deriving parser/handlers, class/instance/default registries, tactics/effects, registered axioms, approved assumptions and available/unavailable proof prerequisites. Publish actual checked module-interface, public/private/body-exposure/import-order and target-profile receipts. A declaration digest alone does not describe the whole environment.
6. **Complete qualification and integration.** Require source/kernel/typed-IR, modules, readable JS/TS/Rust, both target profiles, GC core/component/WAT/WIT, repeated native Wasmtime/post-return and unchanged performance gates. Reconcile the exit inventory against actual results. Integrate both branch histories and concurrent documents, qualify the exact integration commit with native plus applicable independent F1/F2/F3-F4 replay, and update the draft PR and both handoffs. Never merge PR109.

**All six selected criteria are now satisfied.** Research compiler `71489890970049293e78f33f9f9dc3826a0074b2` passed its complete qualification; exact history-preserving integration `2a7072064974cb0d051a1773a26caf15fc59838b` independently passed native38832366451, F1 38832366381, F2 38832366374 and F3/F4/platform38832366314. Final artifact12018546813 and read-only diagnostic38835057984 record1069 each JS/TS/Rust,35 probes/profile,3599/39/355/13 environment counts and all required source/module/GC/ABI/native-host measurements. See the final receipt rather than stale pending snapshots. The [Rust intrinsic typing](PSCV0_M2_RUST_INTRINSIC_RESULT_TYPES_2026-10-16.md) correction and earlier platform/WIT corrections are qualified.

**Performance remains an explicit limitation.** Integration generated-JS/native-Lean collection microbenchmarks report approximately247x–3158x ratios. The unchanged benchmark passes output equality and records timing; this is not production-speed, no-regression or Rust-performance acceptance. Measured optimization and broader performance obligations remain below; no thresholds or budgets were relaxed to close M2+A.

## Phase B / M3 detailed exit

Complete selected heterogeneous/indexed/dependent and recursive type formation/elimination, nested and mutual inductives, constructor consistency/strict positivity, independent motive checking, recursive pattern matrices, and structural/well-founded total recursion. Validate invalid indices and termination refusals plus proof/runtime erasure across supported backends. No partial/unsafe escape around mandatory obligations. Expand deriving through these shared data mechanisms rather than isolated handlers.

## Phase C / M4 detailed exit

Generalize effects through common checked bind/pure elaboration and appropriate instances. Complete selected StateT/ReaderT/ExceptT, typed do, mutable/erased state, loops, early returns, throw/try/catch/finally and explicit world/IO/FFI boundaries. Specify effect/failure behavior independently of JavaScript exceptions and validate the cross-target IR and capability evidence.

## Phase D / M4 detailed exit

Produce kernel-checked proof terms for rewriting, selected simp/omega/grind and other admitted automation. Implement the selected given/requires/ensures, assertions, invariants/decreasing, Std.WP/vcgen and proof-tail obligations with traceable proof/specification/effect/assumption/termination/erasure ledgers. **Verified executable output is forbidden while any mandatory obligation remains unresolved.** Imported proof extensions require pinned provenance and official kernel validation; a helper's native availability does not establish selected Standard admission.

## Phase E / M5 detailed exit

Close the source-rule -> positive/negative conformance case -> exact failure phase -> pinned Lean elaborated-term/semantic correspondence -> verified IR/backend matrix. Independently validate assumption/primitive/erasure safety, cryptographic environment closure, multi-module/public APIs, JS/TS/Rust/GC-Wasm/Wasmtime parity and reproducible version/SHA/evidence receipts. Complete incremental/tooling/optimization/performance obligations and C5 source correspondence. Only then declare core/essential v7 complete; an all-green bounded M2 profile is insufficient.

## Existing outputs and deferred work

C0–C4b are existing foundations, not milestones to repeat. One ECMAScript program supplies direct JS and TS; Rust, WAT, WIT and binary formats extend their existing shared lowering/ABI plans. GC language data and Canonical ABI marshalling remain separate. Resources, callbacks, recursive/proof-bearing foreign construction and effects require explicit future APIs. Retain the [readable-output audit](PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md), [codegen design](PSCV0_NATIVE_CODEGEN.md), [Rust design](PSCV0_NATIVE_RUST.md) and [Wasm design](PSCV0_NATIVE_WASM.md).

C5 information retention happens during M2–M4; full selected Lean/PS reconstruction and correspondence is M5/E. Backend milestone D means measured performance/ownership work and is distinct from language Phase D specifications/proofs. Fine-grained debugger or optional declaration maps are separately named capabilities, not silently added acceptance conditions. Compiler-source migration, bootstrap/fixed-point qualification and independent kernel work remain separate future tasks.
