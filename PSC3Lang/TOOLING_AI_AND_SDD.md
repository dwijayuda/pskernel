# PSC3 Tooling, AI and Specification-Enforced Development

Status: **product/tooling architecture draft**

Tooling quality is part of PSC3's language design.

A language intended to compete with TypeScript cannot treat editor latency, diagnostics, formatting, package management or build ergonomics as optional extras.

## 1. One primary tool

Proposed command:

~~~text
psc
~~~

Core workflow:

~~~text
psc new
psc add
psc bind
psc build
psc check
psc run
psc test
psc fmt
psc doc
psc prove
psc explain
psc migrate
~~~

Exact commands are product design, not language semantics, but PSC should avoid a fragmented collection of unrelated executables for normal work.

## 2. Fast development loop

Requirements:
- incremental parsing;
- incremental elaboration;
- dependency-aware checking;
- cached proof results;
- cached target generation;
- parallel work where deterministic;
- editor diagnostics without full application rebuild.

Performance budgets should be measured on representative repositories.

A theorem-heavy project may have different latency tiers from an ordinary app build.

## 3. Canonical formatter

PSC3 has one canonical formatter for native .ps/.psx.

Formatting:
- does not change semantics;
- eliminates style configuration debates;
- produces stable diffs;
- supports generated source;
- preserves comments/docs;
- is fast enough for editor/save hooks.

.lean source follows Lean formatting conventions/tooling rather than being reformatted as .ps.

## 4. LSP

The language server should provide:
- completion;
- signature help;
- hover;
- go-to-definition;
- references;
- rename;
- diagnostics;
- semantic highlighting;
- code actions;
- theorem goals;
- proof state;
- type/instance/coercion explanations;
- generated-code/source-map navigation.

Editor behavior should remain useful before every proof is complete.

## 5. psc explain

Implicit behavior must be inspectable.

Examples:

~~~text
psc explain expression
psc explain instance Show<User>
psc explain coercion expr
psc explain method users.map
psc explain contract withdraw
psc explain assumption theoremName
psc explain target module --js
~~~

The output should report:
- inferred type;
- selected declaration;
- inserted arguments;
- coercions;
- instance search path;
- relevant effect;
- proof obligations;
- assumptions;
- lowering/profile.

This is essential for both human understanding and AI agents.

## 6. Machine-readable diagnostics

Every diagnostic should have:
- stable code;
- source span;
- severity;
- structured payload;
- human message;
- related spans;
- suggested actions where safe.

AI tooling should consume structured compiler state rather than scrape terminal prose.

## 7. The agent interface

PSC3 should expose a stable programmatic interface for:
- symbol search;
- module API;
- inferred type;
- proof goals;
- contract dependencies;
- available lemmas;
- candidate checking;
- impact analysis;
- assurance status.

An agent can ask precise semantic questions rather than hallucinate project APIs.

## 8. Specification-enforced development

PSC3 distinguishes:

~~~text
requirements
formal approved specifications
implementation
proof/evidence
tests/observations
deployment assumptions
~~~

Not every product requirement is formalizable.

The toolchain should record which requirement has which evidence.

## 9. Protected specifications

An approved specification set may be placed under policy:

~~~text
spec policy:
  implementation: writable
  proofs: writable
  contracts: review-required
  spec dependencies: review-required
  axiom policy: locked
~~~

This is a repository/build policy, not proof-theory magic.

It prevents an automated repair loop from "succeeding" by weakening its acceptance criteria unnoticed.

## 10. Semantic spec dependency graph

The toolchain should compute dependencies from a specification to:
- referenced definitions;
- domain types;
- imported theorems;
- axioms;
- external models;
- semantic profile.

A change to a dependency can be more significant than a textual change to the contract.

## 11. AI repair loop

Recommended loop:

~~~text
fixed approved spec
      |
generate implementation/proof
      |
psc check
      |
structured goals/diagnostics
      |
revise
      |
kernel/validator acceptance
~~~

The system can return:
- accepted;
- rejected;
- unresolved proof;
- counterexample;
- unsupported;
- resource limit;
- policy violation;
- internal error.

These states must not be collapsed into pass/fail.

## 12. AI-generated API use

The agent should have access to exact project/package APIs through the compiler index.

This reduces invented functions/parameters.

However:
- resolving a real API does not prove it is the right API;
- type-correct code can still be behaviorally wrong;
- specifications/tests remain necessary.

## 13. AI and FFI

An AI adding a new foreign binding must explicitly declare its trust/effect status.

Policy can forbid:
- new trusted assumptions;
- new dynamic escape usage;
- new external capabilities;

without separate approval.

## 14. Spec linting

PSC3 should offer checks that detect suspicious specifications.

Examples:
- contradictory preconditions;
- vacuous postconditions;
- unreachable branches;
- unused specification arguments;
- trivial results;
- an implementation mutant that still satisfies the spec;
- missing error-case specification.

These are quality signals, not proof that a specification captures human intent.

## 15. Mutation-based specification testing

For critical contracts, generate known-bad implementations:
- return constant;
- drop element;
- swap branch;
- omit validation;
- strengthen precondition;
- skip cleanup.

A useful spec should reject relevant mutants.

Mutation survival is evidence of underspecification, not necessarily a language soundness problem.

## 16. Requirement documents

PSC tooling may support structured requirement/spec documents connected to declarations.

Do not require prose planning to live in the programming language grammar.

An external planning system can reference stable PSC symbol/spec IDs.

## 17. Tests and proofs together

psc test should present:
- unit tests;
- property tests;
- integration tests;
- fuzz tests;
- proof/spec checks;

without implying the same guarantee.

The UI labels each evidence type.

## 18. Counterexample UX

A failed decidable/SMT-assisted property should show:
- concrete inputs/model where validated;
- path/branch;
- violated clause;
- distinction between confirmed counterexample and solver candidate.

## 19. Proof goal UX

Proof state should be accessible:
- inline;
- LSP panel;
- CLI;
- machine-readable API.

Common obligations should have explain/suggest support.

AI suggestions remain untrusted candidate proof construction.

## 20. Build artifacts and assurance report

Each build can produce a manifest containing:

~~~text
source profile
dependency lock
kernel identity
axiom/assumption set
verified declarations
unresolved declarations
FFI trust statuses
backend target
compiler-preservation status
runtime profile
artifact digests
~~~

Avoid one global "verified=true".

## 21. Package manager UX

The tool should combine:
- package discovery/add/remove/update;
- lockfile;
- npm binding generation;
- profile compatibility checks;
- provenance/assurance metadata.

Dependency changes trigger semantic/assurance impact reporting where possible.

## 22. Documentation

psc doc should combine:
- API docs;
- types;
- contracts;
- theorem statements;
- examples;
- capability/effect requirements;
- assurance status.

Documentation comments should support code references checked by the compiler.

## 23. Migration/refactoring

Semantic refactors need compiler awareness:
- rename;
- move;
- extract;
- change signature;
- migrate PSC edition;
- update deprecated library APIs;
- rewrite proof scripts.

The formatter/refactorer should never rely on fragile global text substitution.

## 24. Debugging

ProofScript is still an executable language.

PSC should support:
- source maps;
- stack traces;
- debug builds;
- runtime values;
- profiling;
- target-code inspection.

Proof erasure and optimized representations need debugging mappings back to source.

## 25. Observability of generated output

Developers should be able to request:
- canonical Core;
- erased RuntimeIR;
- generated JS;
- generated Wasm metadata;
- .d.ts;
- source maps;
- preservation/validation evidence.

"Magic compiler" is incompatible with PSC's philosophy.

## 26. AI benchmark

Before marketing PSC3 as an AI-first/spec-driven language, maintain a public benchmark including:
- API hallucination;
- semantic bug;
- weak specification;
- specification tampering;
- hidden assumption;
- FFI trust misuse;
- proof repair;
- cross-module change.

Measure correct accepted completion, not merely compiler pass rate.
