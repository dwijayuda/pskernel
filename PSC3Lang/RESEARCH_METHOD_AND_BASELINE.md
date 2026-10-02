# Research method and repository baseline

**Research record with v0.7 syntax correction · 3 October 2026.** [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md) governs syntax/grammar. Recommendations, historical observations and new documentation review are distinct.

## 1. Reviewed scope and repair baseline

Repository: `dwijayuda/pskernel`. Original design baseline: `65369c75c7b63124f1ba7f2289e573181db281f0`, root tree `9c138519e9e48cb43b44eaab8da30ba44ec1f88a`. This repair starts from the 21-file PSC3 draft at `b07a5ae10535ebfc93350fe049b931876fd6d4f1` on `docs/psc3-language-design-20261003`.

The earlier research reviewed PSC1/PSC2 language, grammar, runtime, verification and bootstrap/kernel design material plus selected upstream documentation. This correction additionally reads the controlling v0.7 main reference and Appendix A registry, and audits every existing PSC3 document. The exact authority paths/blobs are recorded in [the grammar contract](SYNTAX_AND_GRAMMAR_V07.md) and manifest.

The earlier byte-identical `.ps`/`.lean` proposal conflicts with that reference and is withdrawn. V0.7 deliberately provides inherited L forms, conservative D decorations and registered E exceptions with canonical Lean lowering. Adjacent calls are a current rule, not an obsolete historical inconvenience to erase. The alias, pattern, punctuation and scope rules are correspondingly restored.

This is documentation-only. No compiler/kernel/runtime/package pin or implementation-completion status changes. It is not an all-branch or all-implementation audit.

## 2. Research questions

Which real TS workflows need support? Which admitted v0.7 mechanisms already address them? Which tasks need libraries, tooling or explicit extensions rather than new native grammar? Which foreign distinctions must remain visible? Can full apps be authored without repetitive glue? How do proof, partiality, resources and targets compose?

Answer those questions inside the selected reference before proposing grammar changes. A future syntax proposal must identify the exact v0.7 limitation, alternatives and required reference/registry evolution.

## 3. Evidence classes

| Class | Establishes | Does not establish |
|---|---|---|
| Controlling source reference/registry | Intended syntax, categories and lowering. | Implemented support or a proof beyond its reported S1 status. |
| Official language docs | Intended semantics/documented uses. | Population frequency or PSC correctness. |
| Framework examples | Concrete API/workflow needs. | Universal package compatibility or representative statistics. |
| Pinned source | Contents of that inspected parser/test/design. | Local execution or all-version parity. |
| Research papers/methods | A technique/process worth evaluating. | Automatic transfer of their results to PSC. |
| Historical finite model/TS experiments | Reported outcomes for enumerated candidate cases. | Parser/lowering acceptance, kernel soundness or production readiness. |
| Proposed studies | Falsifiable plans. | Already executed experiments. |

The 42-row TS study contains no invented population percentages. Earlier search-match counts remain noisy historical signals. Handbook prominence is not a census.

## 4. Source selection and precedence

For source syntax, first consult v0.7 and its registry/conformance corpus. PSC1/PSC2 and current implementation gates explain history and coverage, not permission to override the requested grammar in PSC3 docs.

TypeScript/framework/ECMAScript/Web IDL sources motivate data, UI, async, modules and boundaries. Lean sources define inherited/canonical semantics under the selected pin. Go and PLIERS inform engineering/research practice. Existing references are retained as the previous pass's research record; this repair does not claim a new comprehensive web study. [RESEARCH_SOURCES.md](RESEARCH_SOURCES.md)

Live manuals and new package versions do not silently enter a compatibility profile. Record exact dependency and runtime artifacts before claiming an adapter works.

## 5. Reference version policy

The v0.7 main reference selects Lean **4.34.0**, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`, for canonical meaning. The earlier proposed 4.34.1 pin and parser/tests are retained as upgrade research only. No root toolchain file is changed.

An actual upgrade requires explicit reference/profile revision, source/category audit, logical/kernel evidence and runtime conformance. Do not apply a later parser test to claim current v0.7 acceptance, or confuse source-reference version with the PSC3 platform edition.

## 6. Operational results and limits

The earlier pass reported Python 3.13.5, Node 22.16.0 and TypeScript 5.8.3 for isolated models/candidate boundary code, with no Lean/Lake. Those historical snippets/results remain in [EXPERIMENTS.md](EXPERIMENTS.md), labelled as not rerun by this correction.

This repair does not execute a PSC compiler, Lean parser/lowerer, proof replay, browser app, Rust/Wasm build or preservation proof. Documentation review is not a grammar conformance test. No participant study, repository-frequency census, dependency-closure inventory or AI productivity benchmark is claimed.

The repair checks documentation consistency against the reference and keeps all proposed APIs explicitly unimplemented. Actual source acceptance remains a future gate, using the exact original source and canonical result rather than extension renaming.

## 7. Decisive next research

Use stratified pinned projects across services, UI, libraries, tools and theorem code. Define AST categories before counting and exclude generated/vendor data. Publish sampling/extraction procedures. Measure tasks and maintenance, not just occurrences.

Compare v0.7 `.ps`, supported native `.lean`, TS workflows and separately labelled optional UI syntax with comparable training and counterbalanced tasks. Record comprehension, diagnostic/annotation burden, proof repair, interop and performance. PLIERS is a process reference, not an existing PSC usability result. [M01](RESEARCH_SOURCES.md#engineering-and-design-method)

A design may change based on evidence, but a syntax change must become an explicit reference/registry revision with migration—not an informal contradictory paragraph in an application document.
