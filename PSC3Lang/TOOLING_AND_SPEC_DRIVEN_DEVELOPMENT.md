# Tooling and specification-enforced development

**Proposed tooling contracts, not implemented commands. Syntax authority: [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md).** Human and AI tooling must consume the same source categories and semantic information.

## 1. Coherent commands and templates

Candidate families include `psc init`, `fmt`, `check`, `build`, `test`, `run`, `docs`, `explain` and `verify-artifact`. These names are proposals, not current CLI claims.

Templates create libraries, CLI or browser/service apps using one module/capability model, with explicit PSC edition, v0.7 source-reference/registry version and canonical Lean environment. `.ps` templates use admitted declarations/calls/braces; `.lean` templates use native forms. Do not generate a competing TS-style dialect or require users to reconstruct bootstrap workspaces.

Integrated predictable tools are motivated by Go's engineering/proposal practice, not by copying its semantics. [G01,G04](RESEARCH_SOURCES.md#engineering-and-design-method)

## 2. Parser, formatter and LSP

Share actual syntax, category ownership, lowering and elaboration information. Provide completion, hover, navigation, references, semantic rename, import actions and diagnostics, with proof goals/assumptions available alongside ordinary programming information.

The formatter preserves D-CALL adjacency and tuple distinctions. Adding whitespace/comments can alter ownership; never normalize `f(x,y)` into `f (x,y)` blindly. Respect `:=`, scoped semicolons, `where`/`with`, native patterns/tactics/do and command scopes. Canonical formatting is not permission to change v0.7 grammar.

Source maps traverse original `.ps` → canonical Lean/Core → targets, and any explicitly profiled `.psx` expansion. A compiler error must name the original span, not only an unrelated synthetic node. Cache keys include reference/registry, source/environment, options, instances, extension and target identities. Cancel obsolete work and invalidate stale proof evidence.

## 3. Diagnostics

Provide stable codes/categories, original and lowered/expanded spans, module/symbol, expected/actual information and safe structured repairs. Explain whether failure belongs to a v0.7 owned category, inherited unsupported feature, logical rejection, unresolved search, resource limit or foreign boundary.

Examples of useful grammar feedback: a bare block-bodied function needs the admitted `:= ...;` form; a constructor pattern uses `.some x`; a spaced tuple call is not a two-argument decoration; ESM syntax belongs in target metadata rather than a source import. Suggestions must preserve actual AST meaning.

Explain methods, arguments, instances, coercions and dependencies affecting portability/assumptions. Never silently weaken a specification to resolve a diagnostic.

## 4. Agent protocol

Versioned queries inspect symbols, types, goals, contracts/dependencies, target profiles and artifact evidence. Candidate-check operations do not grant arbitrary repository edit permission.

Provide agents the actual v0.7 grammar/feature registry and exact supported capability manifest. Do not let generic TS training examples override those inputs. Reject unregistered syntax instead of rescuing it with textual rewriting.

Ordinary allowed edits include implementation and proof scripts. Requirements, predicate dependencies, assumptions, checker sources and release policy need separate review. Proposed requirement changes report stronger preconditions, weaker results, broader effects or new assumptions; they do not count automatically as successful repairs.

## 5. Acceptance loop

```text
Approved requirement/model
          |
Formal contract + examples + assumptions
          |
Candidate v0.7 implementation / proof
          |
Category-aware parsing/lowering and type/profile checks
          |
Final theorem checking + separately labelled tests
          |
Artifact/runtime evidence where established
          |
Independent policy-controlled release
```

A checker establishes a stated claim, not complete formalization of human intent. Vacuity/contradiction/missing-error/mutant checks are scoped quality evidence. Budgets permit honest unresolved outcomes; failure never authorizes new axioms or changed specs.

## 6. Tool security

Logical non-authority is not OS safety. Tactics, macros, plugins and build scripts may have host capabilities; use explicit permissions, isolation and immutable snapshots. Source loading does not authorize execution.

An agent able to edit verifier/CI can bypass workspace guards. Release inputs and policy should be independently controlled. Supplied accepted reports do not substitute for actual checking.

## 7. Learning and documentation

Teach TypeScript users actual v0.7 examples: `function f(x : A) : B := ...;`, `fun`, admitted calls, `structure ... where { ... }`, `match ... with { | .some x => ...; }`, options/errors and ordinary async-library calls. Keep native `.lean` translations separately labelled and explain canonical correspondence.

Do not falsely say `.ps` is merely Lean with another suffix. Do not teach bare JS arrows, blocks, optional chaining or ESM source imports as accepted grammar. Explain the finite registered conveniences and their Lean meaning.

Lean users need executable/adapter coverage, package mapping, source lowering, runtime assumptions and platform APIs. Native Lean validity alone does not imply PSC compatibility. Docs show exact theorem/assumptions with badges, not badges alone.

## 8. Development versus release

Watch/HMR can use provisional checking with explicit status; strict release blocks missing evidence. Both use the same source semantics. HMR state retention needs a defined compatible migration/reset policy. Changed schemas, types, source, specs and runtimes invalidate affected state or proof caches.

## 9. Measurements

Measure comprehension, grammar mistakes, diagnostic repair, interop effort, proof burden, setup and latency. Agent benchmarks record grammar/reference identity, model/version, allowed edits, budgets, interventions and held-out tasks. Report false acceptance and useful completion separately.

The roadmap describes proposed studies; none was executed by this documentation repair. Tests of templates/formatter/lowerer against the v0.7 corpus are required before conformance claims.
