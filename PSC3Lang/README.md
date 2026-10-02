# ProofScript PSC3 — language and application-platform design

**Review draft 0.3 · 3 October 2026 · v0.7 syntax repair; research and proposed requirements, not a release.**

This directory designs the next language/platform iteration of **ProofScript in `dwijayuda/pskernel`**, not another project called ProofScript. Changes are confined to documentation. Existing PSC1/PSC2 implementations, package identities and toolchain pins are not modified or superseded in place.

## Syntax and grammar authority

All `.ps` syntax and grammar claims in this directory follow **[ProofScript Language Reference v0.7.0](../study/proofscript-language-reference-v0.7.0/ProofScript_Language_Reference_v0.7.0_authoritative_draft.md)** and its feature registry. [The local grammar contract](SYNTAX_AND_GRAMMAR_V07.md) records exact rules and reference identity. It supersedes the earlier draft's byte-identical `.ps`/`.lean` policy and any competing TS-like native syntax proposals.

`.ps` is ProofScript's v0.7 surface, with L/D/E category rules and canonical lowering. `.lean` remains a supported subset of pinned native Lean. They share semantic meaning where supported, not necessarily source bytes. Do not rename decorated `.ps` to `.lean` and treat that as a conformance check.

## Recommendation

Build a serious general-purpose language in which ordinary programs, mathematical definitions, specifications and independently checkable proofs share a coherent Lean-based foundation. Compete for TypeScript application work by making data modelling, libraries, UI, asynchronous services, interoperation, debugging and deployment excellent—not by copying JavaScript's semantic shortcuts or requiring every application function to have a functional-correctness proof.

The ambition is full applications authored in v0.7-based `.ps` or supported `.lean`, with explicitly profiled optional `.psx` views. A verified-library release can be an intermediate milestone; it is not the endpoint. Becoming dominant in the JS ecosystem is an aspiration, not an established market result or prediction. Adoption must be tested against actual migration and maintenance tasks.

### The central decisions

1. **One source-reference authority.** `.ps` uses ProofScript v0.7's admitted inherited, decorated and exception forms. Native `.lean` stays within the selected Lean subset. Official Lean checks canonical `.ps` lowering and native `.lean` through their separate frontend paths.
2. **A larger platform, not a larger logic.** Application capabilities grow through ordinary libraries, codecs, specification libraries, controlled extensions and explicit host adapters. Public capabilities are not restricted forever to the compiler's bootstrap subset.
3. **Optional UI syntax is explicitly profiled.** Under v0.7, `.psx` is a target-specific/non-Lean-compatible source boundary. Proposed UI markup requires its own dialect/version, lowering and evidence; it is not an admitted change to ordinary `.ps` and grants no automatic verification status.
4. **TypeScript ergonomics through v0.7 and workflows.** Use admitted `function`/`const` aliases, adjacent calls, braced data/match forms, inference, records, codecs, typed endpoints, ESM artifacts and editor feedback. Do not add unchecked `any`, implicit nullability, JS arrow lambdas or bare brace-bodied functions.
5. **Multiple deployment routes, one meaning.** Keep existing TS/Rust routes. Direct JS is a favored application-delivery target after coverage gates; direct Wasm is an independently gated optimization/assurance target. They must not become four equal-priority mandatory bootstrap dependencies.
6. **Evidence is explicit.** Source admission, contract proof, termination, source-to-Core correspondence, erasure preservation, target preservation, runtime assumptions and tests are separate claims. AI and plugins propose code and proofs; they cannot approve their own specifications or assumptions.

No proposed package, API, backend, extension or theorem is claimed implemented merely because it is described here. The v0.7 reference is itself S1 specified; this documentation repair does not promote its implementation or proof status.

## Reading map

| Document | Responsibility |
|---|---|
| [Syntax and grammar authority](SYNTAX_AND_GRAMMAR_V07.md) | v0.7 source rules, feature IDs, canonical lowering and examples. |
| [Design constitution](DESIGN_CONSTITUTION.md) | Identity, priorities, tradeoffs and Go-inspired decision rules. |
| [Research method and baseline](RESEARCH_METHOD_AND_BASELINE.md) | Reviewed scope, evidence quality and limits. |
| [TypeScript adoption study](TYPESCRIPT_ADOPTION_STUDY.md) | Developer workflows, v0.7 feature mappings and migration experiments. |
| [Lean profile](LEAN_PROFILE.md) | Source/reference pin, canonical lowering and compatibility dimensions. |
| [Language reference](LANGUAGE_REFERENCE.md) | Proposed language requirements subordinate to v0.7 syntax/grammar. |
| [Semantics and effects](SEMANTICS_AND_EFFECTS.md) | Execution, partiality, state, resources, async and scalars. |
| [JS interoperation](JS_INTEROP_AND_INTERFACE_IR.md) | Foreign types, InterfaceIR, adapters and npm import limits. |
| [Application platform](APPLICATION_PLATFORM.md) | Full-app architecture, UI/service/data/deployment support. |
| [PSX proposal](PSX_UI_PROPOSAL.md) | Explicit optional UI dialect, expansion, React and server rendering. |
| [Proofs and verification](THEOREM_PROVING_AND_VERIFICATION.md) | Mathematics, contracts, automation and assurance boundaries. |
| [Backends and preservation](BACKENDS_AND_PRESERVATION.md) | TS/Rust/direct JS/direct Wasm strategy and certificate architecture. |
| [Libraries and packages](STANDARD_LIBRARY_AND_PACKAGES.md) | Library layers, module graph, schemas and dependency policies. |
| [Tooling and specification-driven work](TOOLING_AND_SPEC_DRIVEN_DEVELOPMENT.md) | LSP, diagnostics, AI protocol and protected specifications. |
| [Examples](EXAMPLES.md) | v0.7 `.ps`, canonical/native `.lean`, mathematics and proposed app APIs. |
| [Migration](MIGRATION_FROM_PSC2.md) | Preserve v0.7 forms and explicitly review actual semantic changes. |
| [Decision ledger](DECISIONS_AND_OPEN_QUESTIONS.md) | Alternatives, corrections and remaining freeze questions. |
| [Roadmap and conformance](ROADMAP_AND_CONFORMANCE.md) | Acceptance gates, representative apps and research experiments. |
| [Experiments](EXPERIMENTS.md) | Historical bounded model/TS results and pending source-language gates. |
| [Research sources](RESEARCH_SOURCES.md) | Annotated source register, including the controlling v0.7 package. |
| [Design manifest](DESIGN_MANIFEST.json) | Machine-readable source authority and truthful evidence status. |

The v0.7 reference governs syntax and grammar. `LANGUAGE_REFERENCE.md` describes the proposed PSC3 profile within that authority. Domain documents refine their named areas but cannot override the source reference. Existing PSC1/PSC2 remain authoritative for their own editions. Source IDs resolve in the research register.

## Baselines and immediate implications

Repository design baseline: `main` at `65369c75c7b63124f1ba7f2289e573181db281f0`. This repair starts from the 21-file draft at `b07a5ae10535ebfc93350fe049b931876fd6d4f1` on `docs/psc3-language-design-20261003`.

The controlling v0.7 reference uses Lean **4.34.0**, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`, for canonical semantics. The earlier 4.34.1 study is retained only as a separately gated upgrade candidate. Neither an earlier draft pin nor a live upstream manual silently redefines the v0.7 grammar. Repository toolchain pins remain unchanged.

The earlier two-emitter proposal was broadened in response to the request favoring direct JS and Wasm. This syntax repair does not reverse that target strategy, delete TS/Rust work or move direct emitters into the bootstrap contract.

## What was and was not established

The earlier pass reported selected source/documentation review and isolated finite Python/TypeScript experiments. Those are historical, scoped results recorded in `EXPERIMENTS.md`; they are not newly executed parser or kernel tests.

This repair reviewed the controlling v0.7 reference/registry and the PSC3 documents. It does not claim a PSC build, Lean parser/lowering execution, proof replay, browser application, Rust/Wasm build, usability study or compiler-preservation proof. The first application release must close semantic gates and a useful full-app workflow. Documentation alignment is not soundness or production readiness.
