# Implementation roadmap and conformance program

**Proposed gates, not completion or timing claims. Syntax authority: [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md).** Advance through demonstrated capabilities, not file-count percentages.

## 1. Tracks

Separate source design/conformance, compiler bootstrap, independent kernel, platform/tooling, preservation and adoption research. Shared interfaces do not make one track complete when another passes.

Do not require UI/all targets inside the fixed-point closure, make the bootstrap subset a permanent public limit, or call kernel replay a full-app release. The surface baseline is already v0.7; implementation coverage and future extension proposals must be identified separately.

## 2. Milestones

| Gate | Deliverable | Acceptance evidence |
|---|---|---|
| G0: documentation baseline | One v0.7 source authority and coherent extension/library proposals. | Audit contradictory grammar, explicit paths/IDs and honest evidence states. |
| G1: source/semantic foundation | Supported L/D/E and inherited closure; true admission seam; stable bootstrap. | Reference corpus, canonical lowering, original spans, native `.lean` checks, actual compiler/checker runs. |
| G2: application data | Collections, codecs, endpoints and foreign conversions. | `.ps`/canonical-Lean and cross-language examples, malformed inputs and claimed laws. |
| G3: full app | Inventory Board plus CLI/library, one UI adapter and dev tools. | Clean setup/build, no essential hand-authored TS glue, errors/storage/cancellation/maps. |
| G4: verification | Domain theorem, spec-quality checks, protected workflow and proof replay. | False contract/weak-spec cases and exact statement binding. |
| G5: direct JS | Supported corpus and generated-compiler cutover. | Real next generation, parity criteria, clean consumers and maps. |
| G6: optional UI/SSR | Explicit `.psx` dialect with v0.7-library/canonical expansion. | Registered extension contract, runtime/lifecycle/hydration and usability evidence. |
| G7: additional targets | Rust native/Wasm and direct Wasm profiles. | Actual artifacts, ABI/capability conformance and explicit downstream assumptions. |
| G8: preservation | Erasure, runtime, target and serializer relations. | Independently checked evidence bound to exact files. |

Parallel work is possible, but G3 still needs a sufficiently specified Async/resource subset and G5 need not block use of the TS route. Stronger proof coverage and practical app delivery remain separate coordinated obligations.

## 3. Source conformance baseline

Start with [v0.7 feature-registry.json](../study/proofscript-language-reference-v0.7.0/conformance/feature-registry.json) and its [positive, negative and lowering corpus](../study/proofscript-language-reference-v0.7.0/conformance/README.md). Bind tests to the exact source-reference/registry revision.

Official Lean checks native `.lean` or the canonical lowering of `.ps`. Do not use byte-preserving extension renaming as the `.ps` acceptance gate. Reference S1 status is not upgraded by passing a documentation scan or similar-looking examples.

| ID | Requirement | Positive/adversarial cases |
|---|---|---|
| S01 | Source identity and lowering | Original `.ps`, feature IDs, canonical output and maps; reject stale siblings/undeclared imports. |
| S02 | D-CALL discrimination | `f(x,y)` versus `f((x,y))` versus `f (x,y)`; whitespace/comments; nested calls and Unit argument. |
| S03 | Declaration aliases | Valid `const`/`function`/`def`; reject parameterized const, parameterless function and bare function blocks. |
| S04 | Category punctuation | `:=`, equality, owned semicolons/braces; `where` data and `with` matches; no global punctuation deletion. |
| S05 | Native categories | `.some x` versus forbidden decorated pattern; `fun`; tactics/do; `namespace ... end`; exact default/named forms. |
| S06 | Editions/extensions | Unregistered syntax rejected; existing `.psx` is not automatically UI or verified `.ps`. |
| S07 | Formatting and maps | Preserve discriminator, argument/tuple meaning, bindings and original diagnostic spans. |
| D01 | Dependent records | Valid reconstruction versus invalid retained indexed data. |
| D02 | Dependent patterns | Nested/indexed cases and motives; reject unsupported elaboration. |
| P01 | Logical policy | Valid proof; false theorem, hidden sorry/axiom/native-result rejection. |
| P02 | Contract identity | Actual program/spec theorem; changed predicates cannot reuse approval. |
| P03 | Erasure | Remove proofs without losing runtime witnesses/indices. |
| R01 | Primitives | Exact numbers, zero division, width, floats, Unicode and conversion. |
| R02 | Calls/closures | Returned functions, partial application, capture and renaming. |
| R03 | Partiality | Divergence-sensitive optimization and no fabricated equations. |
| E01 | State/errors | Transformer order, rollback and irreversible host effects. |
| E02 | Resources | Acquisition/body/release failures, cancellation and abort assumptions. |
| E03 | Async | Terminal arbitration, scopes, late/uncooperative work and queues. |
| J01 | JS boundary | Missing/undefined/null, accessors, DTOs, receivers, callbacks and rejected values. |
| J02 | Packages | Locked ESM conditions, initialization, unknown exports and client/server capabilities. |
| U01 | Views | Props/events/children; plain v0.7 library and explicit UI expansion parity. |
| U02 | Frameworks | Hooks, subscriptions, keys and SSR/hydration for selected profiles. |
| T01 | Tools | Original diagnostics, semantic rename, stale-cache invalidation and HMR resets. |
| B01 | Artifacts | Exact bytes/runtime/dependencies and modified-output rejection. |
| B02 | Target parity | Specified observables with explicit resource/profile differences. |
| A01 | Agent policy | Specification/assumption/checker/CI changes separated from implementation repair. |

These are planned tests. Passing finite tests is not a soundness or preservation theorem.

## 4. Representative projects

Use CLI, browser/service, TS/Rust-consumable library, verified codec/collection/state transition, mathematical abstraction, numerical-model and compiler/tool examples. Include dependency upgrades, changed requirements, refactoring and proof repair.

The compiler is one corpus member; snippets alone do not exercise package, lifetime or incremental-build behavior.

## 5. User-centered experiments

H1: v0.7 `.ps` plus good libraries/tooling is learnable for TypeScript developers. Compare supported native `.lean` and TS workflows with consistent training; do not substitute an unregistered surface and call it PSC conformance.

H2: an explicit `.psx` extension improves view comprehension without hiding effects. Compare library views and registered-candidate markup separately.

H3: contracts reduce incorrect accepted changes at tolerable authoring/repair cost. Include weak specifications and dependency tampering.

H4: Async/resource behavior is predictable across cancellation, cleanup failures, stale events and reused descriptions.

Record experience, training, order and exclusions; counterbalance where appropriate. Measure mistakes, time, annotations, diagnostic use and repair. Small studies do not establish universal productivity. [M01](RESEARCH_SOURCES.md#engineering-and-design-method)

## 6. TypeScript corpus study

Predeclare strata across UI, services, libraries and tools. Pin repositories/dependencies, exclude generated/vendor code, and define AST categories before counting. Record tasks alongside callbacks, unions, optional fields, type operators, async, JSX and modules.

Publish scripts and limitations. Framework examples and search counts are not a population census. This repair did not perform such a study.

## 7. Performance/adoption evidence

Measure builds, edits, proof cost, sizes, memory, runtime and marshalling on real corpus tasks. Include setup effort, unsupported bindings and handwritten glue. AI experiments report model/version/budget/allowed edits/interventions and both completion and false acceptance.

No numeric target is claimed achieved here.

## 8. Release records

Each promoted capability identifies source reference/registry, environment, actual tests, logical/runtime scope and assumptions. Unsupported dependencies are rejected, not replaced silently. Failed proof search is not incorrectness proof.

Freeze a coherent tested profile while leaving unrelated extensions experimental. Preserve v0.7 meaning and explicit migrations. The goal remains usable applications with understandable guarantees.
