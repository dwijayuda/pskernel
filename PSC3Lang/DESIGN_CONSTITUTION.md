# PSC3 design constitution

**Proposed policy · draft 0.3 · 3 October 2026. Syntax authority: [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md).** This is a decision framework, not evidence that its goals have been achieved.

## 1. Identity

ProofScript is a general-purpose programming language with a genuine theorem prover and native formal verification. The same definitions should be usable in ordinary code, contracts and mathematics whenever their logical and executable meanings permit it. People may start with application programming and progressively use stronger specifications; adding a proof must not secretly change the program being executed.

TypeScript developers are a primary adoption audience, not a requirement to inherit JavaScript's object model. Lean users are a primary semantic and research audience, not a requirement to implement every Lean macro and compiler internal immediately. AI-assisted development is an important workflow, not the source of language meaning.

## 2. Priority order when requirements conflict

1. Do not misrepresent meaning, assumptions or evidence.
2. Preserve ProofScript v0.7 syntax/grammar and canonical Lean meaning; keep native `.lean` within its declared subset.
3. Enable complete, maintainable application workflows.
4. Make common code understandable with predictable elaboration and useful diagnostics.
5. Preserve mathematical and verification expressiveness above a constrained checker.
6. Improve runtime/build performance and ecosystem reach using measured evidence.
7. Add optional surface conveniences only through explicit future reference/extension proposals, not by silently changing v0.7.

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
| Stable editions, explicit experiments | Preserve reference grammar and track extension/library versions separately. | Reinterpreting a `.psx` file as ordinary verified source or deleting v0.7 call ownership. |

## 4. Go-inspired, not Go-shaped

Go's original design account concerns software-engineering problems including dependencies, build latency and maintainability. Its FAQ discusses reducing clutter; its compatibility policy makes source continuity a serious obligation with explicit exceptions. Its proposal process requires significant changes to be discussed and, when needed, designed before implementation. These are useful precedents, not proof that Go's exact feature choices fit a dependent language. [G01–G04](RESEARCH_SOURCES.md#engineering-and-design-method)

For PSC3 the corresponding rules are: canonical teaching examples within v0.7; readable generated interfaces; bounded and explainable inference; a category-aware formatter; a precise module graph; versioned evidence; and a recorded answer to each significant proposal. Small kernel size is only one budget. Reader complexity, elaboration cost, proof maintenance, runtime support and documentation cost also count.

## 5. Deliberate non-goals

The first stable profile is not a drop-in TypeScript parser, all of mathlib, a full Rust-like systems language, a verified browser/OS, a universal `.d.ts` translator or a new replacement for every JS framework. None is required for full application authorship in ProofScript.

Do not promise to prove arbitrary human intent, absence of every defect, side-channel freedom, UI accessibility in every rendered state, or correctness of unmodeled external services. Those require specific models, requirements and evidence.

Do not make all mathematical definitions executable. Do not make all executable programs total logical functions. Do not suppress serious mathematics merely to advertise a simpler core.

## 6. Native syntax and adoption tradeoff

Use the actual v0.7 design: TypeScript-friendly syntax where registered, Lean semantics through canonical lowering. `.ps` supports admitted `const`/`function` aliases, adjacent calls, explicit parameter grouping and category-specific braces. Native `.lean` retains its own grammar. Shared semantics is not a requirement for byte-identical sources.

This corrects the previous draft's stock-Lean-only `.ps` policy. It also rejects inventing a new TS-shaped surface: bare function block bodies, JS arrow lambdas, colon-named call arguments, optional-property `?`, braced command scopes and ESM source imports are not made ordinary PSC3 syntax.

The existing adjacency distinction has a real tooling cost. Address it with documented rules, protected-neighbor tests and formatter/source-map correctness, not a silent reinterpretation of v0.7. Proposals to change it belong to a separate reference revision.

Application libraries, inference, codecs, options records, typed endpoints and editor explanations complement the admitted surface. Optional `.psx` UI syntax remains explicitly experimental and outside the base grammar; plain UI APIs remain usable from both `.ps` and `.lean`.

## 7. Proposal acceptance template

Every substantial proposal records the user task, pain, alternatives, no-change option, exact source/library mechanism, v0.7 L/D/E/X classification or explicit extension status, canonical lowering, interactions, trust, diagnostics, bootstrap/dependency closure, performance hypotheses, positive/negative tests and migration consequences.

The author, implementer and adversarial reviewer should be distinguishable roles. No popularity count, successful proof, single benchmark or AI endorsement settles a design. The ledger records rationale and conditions for revisiting decisions. New grammar is never admitted merely by adding an attractive example to this directory.

## 8. Success criterion

A developer should be able to build, inspect and evolve a full app, then add useful proofs without moving to a different semantic language. A mathematician should use the same foundation without pretending every definition is runnable. An independent consumer should understand exactly what package evidence establishes. These are measurable objectives, not achieved claims.
