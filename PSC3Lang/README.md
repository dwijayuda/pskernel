# ProofScript PSC3 — language and application-platform design

**Review draft 0.2 · 3 October 2026 · research and proposed requirements, not a release.**

This directory designs the next language/platform iteration of **ProofScript in `dwijayuda/pskernel`**, not another project called ProofScript. It adds documentation only. Existing PSC1/PSC2 specifications, implementations, package identities, branches and toolchain pins are not changed or superseded in place.

## Recommendation

Build a serious general-purpose language in which ordinary programs, mathematical definitions, specifications and independently checkable proofs share a coherent Lean-based foundation. Compete for TypeScript application work by making data modelling, libraries, UI, asynchronous services, interoperation, debugging and deployment excellent—not by copying JavaScript's semantic shortcuts or requiring every application function to have a functional-correctness proof.

The ambition is full applications authored in `.ps` or supported `.lean`, with optional `.psx` views. A verified-library release can be an intermediate milestone; it is not the endpoint. Becoming dominant in the JS ecosystem is an aspiration, not an established market result or prediction. Adoption must be tested against actual migration and maintenance tasks.

### The central decisions

1. **One strict source foundation.** Ordinary PSC3 `.lean` is a documented syntactic and semantic subset of a pinned Lean environment. Ordinary `.ps` uses the same contents, staged byte-for-byte under the same logical module path for the official Lean oracle. There is no hidden TS-style source rewrite.
2. **A larger platform, not a larger logic.** Application capabilities grow through ordinary Lean-defined libraries, codecs, specification libraries, controlled extensions and explicit host adapters. Public capabilities are not restricted forever to the compiler's bootstrap subset.
3. **Optional UI syntax, never a trust escape.** `.psx` is proposed as an explicitly versioned UI extension, with deterministic expansion to the same view/component libraries available from plain `.ps` and `.lean`. It is not stock Lean syntax and is not PSC2's old mixed/unverified-file meaning.
4. **TypeScript ergonomics through workflows.** Prioritize inference, records/options, pattern refinement, collection APIs, typed endpoints, runtime decoding, callbacks, ESM packages, editor feedback and incremental development. Do not introduce unchecked `any`, implicit nullability or arbitrary JS structural subtyping into the logical foundation.
5. **Multiple deployment routes, one meaning.** Keep existing TS/Rust routes. Direct JS is a favored application-delivery target after coverage gates; direct Wasm is an independently gated optimization/assurance target. They must not become four equal-priority mandatory bootstrap dependencies.
6. **Evidence is explicit.** Source admission, contract proof, termination, source-to-Core correspondence, erasure preservation, target preservation, runtime assumptions and tests are separate claims. AI and plugins propose code and proofs; they cannot approve their own specifications or assumptions.

These are recommendations for this draft. No proposed package, API, backend, syntax extension or theorem is claimed implemented merely because it is described here.

## Reading map

| Document | Responsibility |
|---|---|
| [Design constitution](DESIGN_CONSTITUTION.md) | Identity, priorities, tradeoffs and Go-inspired decision rules. |
| [Research method and baseline](RESEARCH_METHOD_AND_BASELINE.md) | Reviewed scope, evidence quality and limits. |
| [TypeScript adoption study](TYPESCRIPT_ADOPTION_STUDY.md) | Developer workflows, feature decisions and migration experiments. |
| [Lean profile](LEAN_PROFILE.md) | Pin, accepted-subset rules, theory and compatibility dimensions. |
| [Language reference](LANGUAGE_REFERENCE.md) | **Authoritative proposed language rules within this directory.** |
| [Semantics and effects](SEMANTICS_AND_EFFECTS.md) | Execution, partiality, state, resources, async and scalars. |
| [JS interoperation](JS_INTEROP_AND_INTERFACE_IR.md) | Foreign types, InterfaceIR, adapters and npm import limits. |
| [Application platform](APPLICATION_PLATFORM.md) | Full-app architecture, UI/service/data/deployment support. |
| [PSX proposal](PSX_UI_PROPOSAL.md) | Optional UI extension, expansion, React and server rendering. |
| [Proofs and verification](THEOREM_PROVING_AND_VERIFICATION.md) | Mathematics, contracts, automation and assurance boundaries. |
| [Backends and preservation](BACKENDS_AND_PRESERVATION.md) | TS/Rust/direct JS/direct Wasm strategy and certificate architecture. |
| [Libraries and packages](STANDARD_LIBRARY_AND_PACKAGES.md) | Library layers, module graph, schemas and dependency policies. |
| [Tooling and specification-driven work](TOOLING_AND_SPEC_DRIVEN_DEVELOPMENT.md) | LSP, diagnostics, AI protocol and protected specifications. |
| [Examples](EXAMPLES.md) | Plain-source programming, mathematics and proposed application APIs. |
| [Migration](MIGRATION_FROM_PSC2.md) | Explicit edition changes and migration hazards. |
| [Decision ledger](DECISIONS_AND_OPEN_QUESTIONS.md) | Alternatives, recommendations and remaining freeze questions. |
| [Roadmap and conformance](ROADMAP_AND_CONFORMANCE.md) | Acceptance gates, representative apps and research experiments. |
| [Experiments](EXPERIMENTS.md) | Executed bounded model/TS experiments and unexecuted Lean gates. |
| [Research sources](RESEARCH_SOURCES.md) | Annotated primary-source register and version limitations. |
| [Design manifest](DESIGN_MANIFEST.json) | Machine-readable identity and truthful evidence status. |

`LANGUAGE_REFERENCE.md` governs language claims in this folder. Domain documents refine their named areas; a contradiction is a review defect, not permission to choose a convenient interpretation. Existing PSC1/PSC2 remain authoritative for their own editions. References such as T01, L01 and R01 resolve in the research register.

## Baselines and immediate implications

The repository design baseline is `main` at `65369c75c7b63124f1ba7f2289e573181db281f0`. The proposed new Lean reference is **v4.34.1**, source commit `5045d0056413266e57c625dcd7c365b10e377c52`. The tag was resolved through GitHub; the official patch notes recommend upgrading for runtime fixes. This is a proposed profile decision, not an assertion that the owned checker already supports the patch. Existing v4.34.0 pins remain unchanged. [L01–L02](RESEARCH_SOURCES.md#lean-and-logical-foundations)

The former standalone two-emitter proposal is deliberately broadened in response to the current request favoring direct JS and Wasm. This does not delete TS/Rust work or move direct emitters into the current bootstrap contract. The decision and cutover gates are in the backend document.

## What was and was not established

This pass reviewed repository specifications, earlier design material, official language/framework documents and selected upstream Lean parser/tests. It ran isolated finite Python models and a candidate TypeScript boundary experiment. It did **not** run PSC compiler or kernel suites, Lean examples, browser applications, Rust/Wasm compilation, human usability studies, npm corpus migration or preservation proofs. Lean and Lake were unavailable in the working container. See the exact experiment scope and outcomes rather than interpreting documentation volume as implementation progress.

The first application release must close both semantic gates and a useful full-app workflow. No proposal in this folder is a claim of soundness, production readiness, complete Lean compatibility or universal npm compatibility.
