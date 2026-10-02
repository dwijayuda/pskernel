# Research method and repository baseline

**Research record · 3 October 2026.** Recommendations are distinguished from upstream facts and actual experiments throughout this folder.

## 1. Scope actually reviewed

Repository: `dwijayuda/pskernel`. Main baseline: `65369c75c7b63124f1ba7f2289e573181db281f0`; root tree: `9c138519e9e48cb43b44eaab8da30ba44ec1f88a`. The root had no `PSC3Lang/` directory at inspection. No matching PSC3 branch was returned by the branch search.

The reviewed design material includes the PSC2 language reference and companion contracts, migration, feature-research and self-hosting documents; the inherited PSC1 grammar and semantic/runtime companion; and previously reviewed minimal-bootstrap and owned-kernel architecture snapshots. The new upstream tag and relevant parser/test sources were independently fetched. This is not an exhaustive review of every repository branch, implementation file or historical commit. [R01–R06](RESEARCH_SOURCES.md#repository-baselines)

Important inherited facts: PSC2 is a draft, the old grammar has special adjacent calls, the error-type examples disagree on `Result` parameter order, the runtime companion leaves an operation/conversion matrix open, and the proposed platform leaves several async/extension rules unresolved. These are reasons to refine the next edition, not evidence that every implementation has the same defect.

The main baseline remains unchanged by this documentation addition. A reviewed workstream's status must not be generalized to unrelated kernels or branches. No new self-hosting or kernel-completion claim is made.

## 2. Questions guiding the research

- What tasks do TypeScript ecosystem APIs actually ask developers to perform?
- Which native Lean mechanisms already serve those tasks, and which require library or tooling support?
- Which foreign semantic distinctions must remain visible at a JS boundary?
- Can a complete application be authored without writing ad hoc TS glue?
- Where does UI sugar help without creating a separate application logic?
- How can contracts and proofs compose with partiality, resources, external calls and optimization?
- Which target choices improve delivery without creating independent source semantics?

## 3. Evidence classes

| Class | What it establishes | What it does not establish |
|---|---|---|
| Official language specification/documentation | Intended semantics or documented usage. | Frequency among all developers; correctness of PSC's implementation. |
| Official framework documentation/examples | Concrete workflows and API patterns expected by that framework. | Representative population statistics; proof that all packages are compatible. |
| Pinned repository source | What the inspected parser, test or design actually contains. | That the test was run here; all-version compatibility. |
| Research methodology/compiler papers | A design process or formally scoped technique to investigate. | Automatic transfer of its results to PSC. |
| Local finite models and TS experiment | Observed outcomes for the enumerated cases and candidate code. | Lean acceptance, compiler preservation, production readiness or full semantic coverage. |
| Proposed user study/benchmark | A falsifiable evaluation plan. | An experiment already conducted. |

The feature study deliberately does not invent TypeScript usage percentages. Handbook prominence and framework examples are requirements evidence, not a frequency census. The earlier PSC2 search-match counts are historical noisy signals and were not remeasured as a population study.

## 4. Primary-source selection

TypeScript's Handbook supplies functions, data, narrowing, generics, type operators, compatibility and module concepts. React, Next.js, Vite, Zod, TanStack Query and tRPC supply application patterns: props/events, render boundaries, builds, decoding, asynchronous state and endpoint inference. Node, ECMAScript, Fetch and Web IDL supply boundary semantics. Lean's official manual and pinned source supply the semantic constraint. Go and PLIERS inform design discipline. [T01–T15, E01–E13, L01–L13, G01–G04, M01](RESEARCH_SOURCES.md)

Live documentation is labelled as such. The project has not pinned a complete JS ecosystem dependency matrix. New or changed APIs in live pages are not automatically accepted in the PSC3 profile. Before implementation, record package versions and exact declaration/runtime artifacts for each supported adapter.

## 5. Proposed Lean reference

Select v4.34.1, commit `5045d0056413266e57c625dcd7c365b10e377c52`, for the new design profile. The official September 24, 2026 release notes recommend the patch for runtime fixes; the tag resolves to that commit. This is a reason to evaluate the patch rather than assume the old runtime has identical behavior. It is not evidence of owned-kernel compatibility. [L01–L02](RESEARCH_SOURCES.md#lean-and-logical-foundations)

No root toolchain file, old profile or package identity is changed. Migration requires source, logical, runtime and independent-checker gates. A live manual may describe features beyond the selected pin; uncertain cases remain gated rather than inferred from the manual's navigation.

## 6. Research limitations and operational outcomes

Lean and Lake were not installed in the local working environment. No PSC build, proof replay, Lean compilation, `.psx` expansion, browser test, rustc build or Wasm execution was run. The available Node/TypeScript tools were used only for an isolated hand-authored boundary experiment. A finite Python model explored selected policy counterexamples. Commands and results are recorded in [EXPERIMENTS.md](EXPERIMENTS.md).

No user study, representative repository-frequency analysis, migration benchmark or complete dependency-closure inventory was executed. Full-app designs and package names are proposals, not installed products. This documentation commit should not trigger a stronger progress label in any existing implementation.

## 7. Next research that changes decisions

Use stratified, pinned sample projects spanning services, UI, libraries, tools and theorem code. Define syntax categories before counting, exclude vendored/generated code, and publish the sampling frame and extraction script. Measure task completion and maintenance, not only occurrence counts.

Compare plain Lean-subset authoring, library-supported PSC3, and optional UI syntax on the same tasks. Give comparable training; counterbalance task order; record experience and accessibility needs. Predeclare outcome measures and separate human results from AI-agent results. PLIERS supplies a relevant user-centered process, not a ready-made finding for this language. [M01](RESEARCH_SOURCES.md#engineering-and-design-method)

A design may be revised when evidence shows unacceptable annotation burden, surprising effects, unreliable diagnostics, excessive proof repair, poor interoperation or a runtime cost that defeats a target use case. Such revision must preserve old editions and record its rationale.
