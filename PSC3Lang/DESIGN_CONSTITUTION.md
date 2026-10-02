# PSC3 design constitution

**Proposed policy · draft 0.2 · 3 October 2026.** This document is a decision framework, not evidence that its goals have been achieved.

## 1. Identity

ProofScript is a general-purpose programming language with a genuine theorem prover and native formal verification. The same definitions should be usable in ordinary code, contracts and mathematics whenever their logical and executable meanings permit it. People may start with application programming and progressively use stronger specifications; adding a proof must not secretly change the program being executed.

TypeScript developers are a primary adoption audience, not a requirement to inherit JavaScript's object model. Lean users are a primary semantic and research audience, not a requirement to implement every Lean macro and compiler internal immediately. AI-assisted development is an important workflow, not the source of language meaning.

## 2. Priority order when requirements conflict

1. Do not misrepresent meaning, assumptions or evidence.
2. Preserve the declared Lean-subset semantics and explicit edition boundaries.
3. Enable complete, maintainable application workflows.
4. Make common code understandable with predictable elaboration and useful diagnostics.
5. Preserve mathematical and verification expressiveness above a constrained checker.
6. Improve runtime/build performance and ecosystem reach using measured evidence.
7. Add optional surface conveniences only when their benefit exceeds their interaction cost.

This order does not permit indefinite delivery postponement in pursuit of unlimited proof coverage. Unsupported guarantees must be reported while useful type-checked applications remain possible under explicit runtime profiles.

## 3. Operational principles

| Principle | Operational consequence | A proposal it rejects |
|---|---|---|
| One meaning, several evidence levels | Checking modes add evidence or reject a requested claim; they do not change arithmetic, effects or selected implementation. | A release flag silently wraps overflow or substitutes a different algorithm. |
| Ordinary programs first, proofs available | Collection, UI and service examples must work without explaining universes or manual proofs at every call. | Every HTTP handler must prove global termination before it can run. |
| Complexity must be explainable | Expose inferred arguments, methods, instances, coercions and foreign conversions. | Hidden import-order effects with no diagnostic explanation. |
| Composition before vocabulary | Prefer existing functions, inductives, monads and ordinary library types. | A new kernel node for optional chaining or UI markup. |
| Adoption includes the whole workflow | Formatter, project setup, watch mode, source maps, errors and packaging are release work. | Declaring application readiness because several expressions compile. |
| Foreign behavior is explicit | Represent nullability, mutability, identity, callbacks and failures at the boundary. | Treating every declaration in a `.d.ts` file as a proved foreign implementation. |
| Generated evidence is independently checked | A model, tactic or plugin cannot authorize its own assumptions. | Replacing an unsolved obligation with an axiom during an automatic repair. |
| Stable editions, explicit experiments | Preserve old source semantics; track extension and library versions separately. | Reinterpreting a PSC2 `.psx` escape file as a PSC3 view without migration. |

## 4. Go-inspired, not Go-shaped

Go's original design account concerns software-engineering problems including dependencies, build latency and maintainability. Its FAQ discusses reducing clutter; its compatibility policy makes source continuity a serious obligation with explicit exceptions. Its proposal process requires significant changes to be discussed and, when needed, designed before implementation. These are useful precedents, not proof that Go's exact feature choices fit a dependent language. [G01–G04](RESEARCH_SOURCES.md#engineering-and-design-method)

For PSC3 the corresponding rules are: one canonical teaching form; readable generated interfaces; bounded and explainable inference; one formatter per edition; a precise module graph; versioned evidence; and a recorded answer to each significant proposal. Small kernel size is only one budget. Reader complexity, elaboration cost, proof maintenance, runtime support and documentation cost also count.

## 5. Deliberate non-goals

The first stable profile is not a drop-in TypeScript parser, all of mathlib, a full Rust-like systems language, a verified browser/OS, a universal `.d.ts` translator or a new replacement for every JS framework. None is required for full application authorship in ProofScript.

Do not promise to prove arbitrary human intent, absence of every defect, side-channel freedom, UI accessibility in every rendered state, or correctness of unmodeled external services. Those require specific models, requirements and evidence.

Do not make all mathematical definitions executable. Do not make all executable programs total logical functions. Do not suppress serious mathematics merely to advertise a simpler core.

## 6. Native syntax and adoption tradeoff

The recommendation is strict native Lean forms in `.ps`/`.lean`, preserving the earlier source-identity goal. This has a real cost: a TypeScript developer must learn curried calls, Lean binders and expression-oriented control flow. Good tutorials cannot be assumed to erase that cost.

The compensating proposal is a much better application library and editor experience, familiar method-oriented APIs where native notation permits them, automatic import/code actions, options records and typed endpoints. An optional `.psx` extension serves UI readability without splitting ordinary source semantics.

A broader TS-like surface is not automatically unsound, but it would create another parser, migration model and source-correspondence obligation. It is deferred until comparative usability studies show that the strict design cannot meet adoption goals. It must then be a named extension/edition, never silently called stock Lean.

## 7. Proposal acceptance template

Every substantial proposal records: the user task; current pain; at least one alternative and the no-change alternative; exact syntax/library mechanism; upstream meaning; feature interactions; lowering; trust implications; diagnostics; bootstrap/dependency closure; performance measurements or hypotheses; positive/negative tests; and migration consequences.

The author, implementation reviewer and adversarial reviewer should be distinguishable roles. No single benchmark, popularity count, successful proof or AI endorsement settles a design. The decision ledger records accepted rationale and conditions for revisiting it.

## 8. Success criterion

A developer should be able to build, inspect and evolve a full app, then add useful proofs without moving to a different language. A mathematician should be able to use the same foundation without pretending all mathematics is a runnable service. An independent consumer should be able to tell exactly what a package's evidence establishes. These are measurable objectives, not claims achieved by this document.
