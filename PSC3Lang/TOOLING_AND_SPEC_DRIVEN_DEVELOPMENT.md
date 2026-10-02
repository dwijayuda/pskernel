# Tooling and specification-enforced development

**Proposed tooling contracts, not implemented commands.** A serious language needs useful human tools and exact machine interfaces. AI support should build on those same interfaces.

## 1. Coherent command experience

Candidate command families are `psc init`, `fmt`, `check`, `build`, `test`, `run`, `docs`, `explain` and `verify-artifact`. These names illustrate the intended integrated experience; they are not assertions that the current CLI implements them.

Templates should create a minimal library, CLI, browser app or browser/service app using the same module and capability model. The template explicitly records edition and source environment. Ordinary development must not require manually reconstructing the compiler's bootstrap workspace.

Go's engineering account and proposal practice motivate integrated, predictable tooling rather than a collection of unrelated configuration systems. [G01,G04](RESEARCH_SOURCES.md#engineering-and-design-method)

## 2. LSP requirements

The language server should share syntax/elaboration information with the compiler and support completion, hover, navigation, references, semantic rename, import actions, formatting and diagnostics. Proof goals and assumption summaries should be available without displacing ordinary programming information.

The inspected source is authoritative: source maps must lead back through `.psx` expansion, generated schema code and target output. A diagnostic on a foreign call should explain a missing adapter/capability, not claim that Lean type checking failed for an unrelated generated node.

Incremental caching keys include source/environment identities, options, instances, extension versions and relevant target profiles. Cancellation must stop obsolete work. An outdated proof result cannot be shown as evidence for the current source.

## 3. Diagnostic structure

Every diagnostic should provide a stable category, original span, relevant expansion span, module/symbol, expected/actual information, a short explanation and optional structured repair suggestions.

Distinguish malformed source, unsupported profile, native elaboration error, logical rejection, unresolved proof search, resource limit, cancellation, foreign boundary failure and internal error. An agent must not interpret every failure as an instruction to change the program.

Explain inferred methods, arguments, instances and coercions. Show which dependency makes an export nonportable or changes an assumption set. Suggestions must not automatically weaken specifications or erase meaningful distinctions.

## 4. Agent protocol

Expose versioned operations conceptually equivalent to: inspect symbols; inspect contract and dependency identities; inspect type/elaboration result; obtain goals; propose/check a patch; run selected tests; inspect artifact assurance. These are query/check operations, not permissions to edit arbitrary repository files.

An agent's allowed edit set should normally include implementation and proof scripts. Approved requirements, specification predicates, logical assumptions, verification policy, checker sources and release configuration require separate review. File-name protection alone is insufficient when definitions are imported transitively.

The agent may suggest changing a requirement, but that is a distinct change type with an explanation of strengthened preconditions, weakened postconditions, expanded effects or new assumptions. It must not count as a successful implementation repair automatically.

## 5. Acceptance loop

```text
Human-approved requirement/model
                |
Formal contract + examples + explicit assumptions
                |
Candidate implementation and proof construction
                |
Type/profile checks + final theorem checking + tests
                |
Artifact preservation/runtime evidence where available
                |
Independent policy-controlled release decision
```

A checker validates evidence of a stated claim; it does not prove that a human requirement has been fully formalized. A specification-quality tool should look for vacuity, contradictory preconditions, omitted failure paths and mutants that still satisfy the contract. Such results are scoped evidence, not automatic intent validation.

The loop has resource budgets and an honest unresolved outcome. Failure to prove is not permission to insert axioms, return a constant, redefine the specification or trust an external solver's unverified success.

## 6. Security of tools and extensions

Logical non-authority does not imply OS-level safety. A tactic, macro, plugin or package build script may read files or run processes in its host environment. Use explicit permissions, isolation and immutable snapshots appropriate to untrusted content.

A malicious agent able to edit the checker and CI policy can bypass an ordinary workspace guard. Release authority should use independently controlled inputs and artifacts. Never treat a report supplied by the agent as equivalent to running the required verification.

## 7. Documentation and learning

Teach TypeScript users native syntax through side-by-side tasks, not a misleading token substitution table. Start with functions, records, inductives, collection pipelines, options/errors and async library calls. Introduce contracts on one actual function, then dependent types and mathematical proofs as needed.

Teach Lean users the exact executable/adapter profile, package/module mapping, source identity, runtime assumptions and UI/data APIs. Do not imply that all native Lean code is automatically portable.

Generated documentation should show both ordinary API usage and optional guarantees, including the meaning and assumptions of those guarantees. A proof badge without the theorem is not sufficient.

## 8. Development versus release

Fast watch/HMR may run provisionally checked code with a visible status. Strict verified release blocks missing required evidence. Both modes execute the same language semantics; a difference in evidence is not permission to select another runtime behavior.

Hot replacement must migrate or reset state according to an explicit compatibility policy. Changed schemas, model types or initializers invalidate unsafe state retention. Changes to source/spec/runtime dependencies invalidate corresponding proof caches.

## 9. Measurements

Measure human comprehension, diagnostic resolution, unsupported-library work, proof burden, proof repair, annotation count and setup time. For agents, record model/version, allowed edits, budget, interventions, exact task/spec and held-out tests. Separate false acceptance from useful completion; rejecting everything is not a successful developer tool.

Track edit latency, proof checking cost, cache effectiveness and memory across representative projects. Proposed experiments are in the roadmap; none of those human/AI productivity studies were run in this pass.
