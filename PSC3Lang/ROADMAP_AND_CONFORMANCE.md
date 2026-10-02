# Implementation roadmap and conformance program

**Proposed gates, not a completion report or schedule estimate.** Delivery should advance through demonstrated capabilities rather than percentages derived from file counts.

## 1. Track separation

Maintain distinct tracks for language/source design, compiler bootstrap, independent kernel, platform/tooling, backend preservation and adoption research. They share versioned interfaces, but one track must not falsely claim completion because another is green.

Do not require all UI libraries or optional targets inside the compiler fixed-point closure. Do not let a small bootstrap subset become the permanent public-language limit. Do not claim a general-purpose release solely from kernel replay or a self-compilation result.

## 2. Milestones

| Gate | Deliverable | Acceptance evidence |
|---|---|---|
| G0: design baseline | Coherent source/extension/library decisions and pinned evidence. | Review contradictions; exact source paths and open questions; no implementation overclaims. |
| G1: semantic foundation | Exact supported source/elaboration closure; genuine admission seam; stable bootstrap profile. | Positive/negative native examples; no silent fallback; actual compiler execution and scoped checker evidence. |
| G2: application data core | Collections, codecs, endpoints, foreign presence/numeric/text adapters. | Native and cross-language examples; malformed inputs; law evidence where claimed. |
| G3: first full app | Browser/service Inventory Board plus CLI/library examples, one UI adapter and dev tooling. | Clean setup/build, no ad hoc user TS glue for supported APIs, forms/errors/persistence/cancellation/source maps. |
| G4: integrated verification | Useful domain theorem, specification-quality checks, protected spec workflow, proof package replay. | Deliberately false contract and weak-spec mutants rejected/detected as appropriate; exact statement binding. |
| G5: direct JS promotion | Full supported runtime corpus and generated-compiler cutover. | Actual next-generation execution, source/compiler parity criteria, clean ESM/TS consumers, diagnostics and source maps. |
| G6: UI syntax and SSR | Optional `.psx`, plain expansion, selected server-rendering integration. | Lean-under-extension and owned expansion tests; browser lifecycle; hydration; comparative usability evidence. |
| G7: extended targets | Rust native/Wasm profiles and direct Wasm profile. | Actual artifacts, ABI/runtime/capability checks, measured costs, explicit downstream assumptions. |
| G8: stronger preservation | Progressively proved erasure/lowering/runtime/serializer relationships. | Independently checked theorems/certificates bound to actual files, not only AST tests. |

Some work may run in parallel, but prerequisites remain explicit. For example, G3 requires a sufficiently specified application Async/resource subset, even if advanced concurrency proofs remain later. G5 is not required to use the existing TS route for G3.

## 3. Conformance families

| Test ID | Requirement | Positive and adversarial cases |
|---|---|---|
| S01 | Source identity | Byte-preserving `.ps` staging; stale sibling, duplicate module and undeclared import rejection. |
| S02 | Native meaning | Calls, tuples, binders, defaults, sections, instances and coercions match the pin. |
| S03 | Editions/extensions | Old PSC2 call/`.psx` forms never silently reinterpreted. |
| D01 | Dependent data | Valid record reconstruction; changed index with invalid retained field rejected. |
| D02 | Patterns | Nested/indexed cases and wildcard motives; unsupported elaboration rejected. |
| P01 | Logical policy | Valid proofs; false theorem, hidden sorry/user-axiom/native-result policy violations. |
| P02 | Contract binding | Actual program/spec theorem; changed predicate or omitted clause cannot reuse approval. |
| P03 | Erasure | Proof-field removal retains values/witnesses and runtime-relevant indices. |
| R01 | Numbers/text | Nat/Int, zero division, machine width, float cases, Unicode and boundary decoding. |
| R02 | Calls/closures | Returned functions, partial application, captured variables and alpha-renaming. |
| R03 | Partiality | Divergence-sensitive optimization and no invented partial equations. |
| E01 | State/errors | Transformer order, speculative rollback and external effects not rolled back. |
| E02 | Resources | Acquisition/body/release matrix, combined errors, cancellation and process-abort assumptions. |
| E03 | Async | First terminal event, scope lifetime, late results, uncooperative cancellation and bounded queues. |
| J01 | JS interfaces | Missing/undefined/null, getters/proxies policy, malformed DTOs, `this`, callback disposal and rejection reasons. |
| J02 | Packages | ESM/conditional exports, side effects, unknown entry points, transitive client/server capability leak. |
| U01 | Views | Typed props/events/children, native-library and `.psx` expansion agreement. |
| U02 | Framework | Hook/lifecycle constraints, subscriptions, keys, SSR and hydration per selected profile. |
| T01 | Tools | Original source diagnostics, semantic rename, invalidated caches, HMR reset/migration. |
| B01 | Artifacts | Exact emitted bytes, runtime/dependency identity and modified-output rejection. |
| B02 | Backend parity | Same specified portable behavior across available routes; distinguish resource/profile differences. |
| A01 | Agent policy | Attempts to weaken specs, assumptions, checker or CI policy are separated from implementation repair. |

Passing tests provides bounded implementation evidence. A soundness or preservation theorem needs its own formal statement and checked proof.

## 4. Representative projects

Use a file-processing CLI; a browser/service app; a TS/Rust-consumable library; a verified codec/collection/state transition; a mathematical abstraction with dependent proofs; a scientific example relating Float behavior to a model; and a compiler/proof-tool component. Include changed requirements, dependency upgrades, refactoring and proof repair.

The compiler is one member of this corpus, not the whole language's usability benchmark. Toy snippets cannot reveal package boundaries, resource lifetime or incremental-build costs.

## 5. User-centered experiments

H1: strict native source plus good APIs/tooling is sufficiently learnable for TS developers. Compare against a baseline workflow and an explicitly labelled alternative surface prototype if needed. Separate syntax training from library gaps.

H2: `.psx` improves comprehension and maintenance for nontrivial views without hiding effects. Compare paired views, change props/events, locate a type error and repair a keyed list. Include plain `.lean` users as well as TS users.

H3: integrated contracts reduce incorrect accepted changes at acceptable authoring/repair cost. Include weak specifications and changed semantic dependencies, not only algorithm bugs.

H4: the proposed async/resource model is predictable. Ask users to explain cancellation, cleanup errors, stale callbacks and reused task descriptions before and after running examples.

Record participant experience, training, task order and exclusions; counterbalance where appropriate. Measure errors, task time, annotations, diagnostics, proof burden and repair. Do not infer broad productivity claims from a small formative sample. PLIERS is a relevant method reference. [M01](RESEARCH_SOURCES.md#engineering-and-design-method)

## 6. TypeScript corpus study to perform

Predeclare a stratified sampling frame spanning UI, services, reusable libraries and build/tools. Pin repositories and dependencies; exclude generated/vendor code; define AST categories before counting. Record callbacks, unions, optional fields, type operators, async, JSX and module patterns along with the application task they serve.

Publish scripts and limitations. Search-match counts and framework documentation are not a representative feature-frequency census. No such corpus measurement was executed in this pass.

## 7. Performance and adoption evidence

Measure cold build/start, warm edit latency, proof checking, artifact size, memory, execution throughput and interop costs on the corpus. Native-versus-Wasm choices must include host-call and serialization costs, not only a tight arithmetic loop.

Track complete-app setup effort, unsupported adapters and user-authored glue. For AI benchmarks record model/budget/version, permitted edits and human interventions. Report both useful completion and false acceptance. No numeric performance/adoption targets are asserted as achieved here.

## 8. Release records

Every promoted capability names its source/environment, test evidence, logical/runtime coverage and remaining assumptions. A partial result has a precise label. An unavailable dependency is unsupported, not silently replaced. A failure to prove is not a proof of incorrectness.

Freeze a coherent profile when its own required gates close; leave unrelated advanced features experimental. Preserve old editions and document migrations. The goal is a usable language whose guarantees remain understandable, not indefinite research or premature production claims.
