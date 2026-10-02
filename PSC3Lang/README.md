# ProofScript PSC3 Language Design

Status: **research and design draft — not an implementation or compatibility claim**

PSC3 is a proposed next language edition for ProofScript. It builds on the strongest PSC1/PSC2 ideas while treating the language as a serious product for ordinary application development, theorem proving, formal verification, and specification-enforced AI development.

PSC3 is not a request to discard PSC2. It is a design iteration intended to resolve PSC2 ambiguities, simplify the native user experience, improve JavaScript/TypeScript ecosystem adoption, and make the language's proof and verification advantages central rather than peripheral.

## Product objective

ProofScript should be usable to build complete applications, libraries, tools, services, browser code, and verified components in native ProofScript source.

The intended identity is:

~~~text
general-purpose programming
+ theorem proving
+ formal verification
+ specification-enforced development
+ first-class JavaScript ecosystem integration
+ portable execution
+ a small auditable proof-checking foundation
~~~

The project should compete with TypeScript on application-development experience while deliberately refusing TypeScript/JavaScript semantics that make strong reasoning difficult.

PSC3's design goal is not "TypeScript syntax with proofs" and not "Lean with JavaScript syntax."

It is:

> A coherent programming language where ordinary programs, specifications, and proofs share one semantic foundation, and where stronger guarantees can be added without changing the program's meaning.

## Three source surfaces

PSC3 proposes three explicitly different source surfaces over the same semantic platform.

### .lean — strict Lean compatibility profile

A supported .lean source file must be accepted by the pinned official Lean toolchain without ProofScript-only syntax.

Initial PSC3 research baseline:

~~~text
Lean stable profile: 4.34.1
~~~

PSC3 may support only a subset of Lean. It must never extend .lean syntax and still describe the result as Lean source.

The .lean frontend exists for:
- Lean users;
- theorem/library migration;
- shared proof development;
- compatibility testing;
- bootstrapping where useful.

### .ps — native ProofScript

.ps is the preferred application and library language.

It keeps the same logical/core meaning where it overlaps with .lean, but it is intentionally designed for:
- regular parsing;
- familiar function calls and blocks;
- predictable modules and imports;
- application programming;
- explicit effects and errors;
- excellent editor and AI-agent tooling.

PSC3 .ps does **not** inherit PSC2's whitespace-sensitive native distinction between f(x) and f (x). In native PSC3, ordinary call syntax is structurally parsed and formatting does not change arity.

### .psx — optional typed UI/component profile

.psx is proposed for browser/component applications.

It is not a separate programming language. Markup-like component syntax lowers to ordinary typed calls and values before semantic checking.

.psx should be framework-neutral in the language definition. React, Preact, DOM, server rendering, or other UI systems are adapters/libraries, not core semantics.

## Design constitution

PSC3 language proposals are judged by these rules.

1. **Ordinary programming must be straightforward.**
2. **Stronger guarantees must not silently change program behavior.**
3. **One mechanism is preferred over overlapping features.**
4. **Implicit behavior must be explainable by tooling.**
5. **Dependencies, effects, trust, and assumptions are explicit.**
6. **The kernel stays small; language simplicity is evaluated separately from kernel size.**
7. **Unsupported or ambiguous behavior fails closed.**
8. **Tooling is part of the language experience, not an afterthought.**
9. **Compatibility claims are versioned and measurable.**
10. **A feature is accepted because it improves complete programs, not because another language has it.**

This is "Go-like" philosophy in method rather than syntax: a small number of orthogonal, predictable mechanisms; explicit dependencies; fast tooling; and resistance to feature accumulation.

## High-level architecture

~~~text
.ps / supported .lean / .psx
              |
              v
      parser + resolver
              |
              v
   elaboration / Meta / VC
              |
              v
     canonical dependent Core
              |
              v
       kernel admission
              |
              v
         CheckedCore
              |
              v
  proved/validated erasure and lowering
              |
              v
      target-neutral RuntimeIR
         /                \
        v                  v
     JS target          Wasm target
        |                  |
      ESM JS         Wasm Component/Core
      .d.ts          WIT where applicable
~~~

Direct JavaScript is the primary application target.

Direct WebAssembly is the preferred second strategic target, beginning with a deliberately bounded portable profile and expanding toward the Component Model/WASI ecosystem.

Additional TypeScript or Rust source emitters may exist as compatibility, migration, debugging, or ecosystem extensions. They are not required to define PSC3 runtime semantics.

## JavaScript ecosystem principle

JavaScript interoperability is a first-class language requirement.

PSC3 should make these workflows normal:

~~~text
npm package -> typed PSC binding
PSC library -> ESM JavaScript + .d.ts
PSC browser app -> JS bundle input
PSC server app -> Node/Bun/Deno-compatible ESM profile
PSC portable component -> direct Wasm + WIT/component metadata
~~~

A foreign declaration being typed does not make it verified. FFI and imported packages have an explicit trust/model status.

## Proof and verification principle

Theorem proving is not a plugin attached to an ordinary language. Proofs, propositions, contracts, and executable definitions share the dependent semantic foundation.

PSC3 keeps:
- Prop and proof terms;
- inductive and dependent types;
- universe polymorphism in the theorem profile;
- structured proofs;
- a proof-producing simplifier/tactic layer;
- requires/ensures/assert/invariant/decreasing;
- explicit assumption reporting;
- proof/spec erasure only when runtime irrelevance is justified.

The proof checker remains the final authority for logical claims.

Compiler correctness, FFI correctness, and runtime correctness are separate claims.

## Specification-enforced AI development

PSC3 should be unusually good for AI-generated software, but AI is not part of language soundness.

The desired workflow is:

~~~text
approved specification
        |
        v
AI or human implementation
        |
        v
proof / VC / certificate generation
        |
        v
independent checking
        |
        v
artifact + precise assurance report
~~~

An AI may propose implementation and proof changes. Weakening an approved specification, changing one of its semantic dependencies, or adding a trusted assumption is a different class of change and must be visible.

## Document map

- DESIGN_PHILOSOPHY.md — product philosophy, language constitution, non-goals and design criteria.
- RESEARCH_METHOD_AND_EVIDENCE.md — how PSC3 decisions are researched and validated.
- TYPESCRIPT_DEVELOPER_STUDY.md — TypeScript/JS habits worth supporting and habits PSC3 should reject.
- LEAN4_COMPATIBILITY.md — .lean profile and relationship with Lean semantics.
- PSC3_LANGUAGE_REFERENCE_DRAFT.md — consolidated language surface and semantic decisions.
- APPLICATION_AND_JS_ECOSYSTEM.md — full-app development and npm/JS platform strategy.
- PSX_UI_PROFILE.md — typed component/markup proposal.
- THEOREM_PROVER_AND_VERIFICATION.md — proof, contract and verification architecture.
- BACKENDS_RUNTIME_AND_PRESERVATION.md — JS/Wasm lowering and compiler-preservation strategy.
- STDLIB_PACKAGES_AND_FFI.md — standard library, packages and foreign interfaces.
- TOOLING_AI_AND_SDD.md — compiler/LSP/tooling and specification-enforced development.
- MIGRATION_FROM_PSC2.md — explicit PSC2-to-PSC3 migration rules.
- ROADMAP_AND_OPEN_QUESTIONS.md — prioritized implementation plan and unresolved research.
- RESEARCH_SOURCES.md — external research snapshot used by this design.

## Status discipline

Nothing in PSC3Lang means the feature exists.

Documents use:
- **DECISION** for a design choice adopted by this PSC3 draft;
- **CANDIDATE** for a preferred design still requiring validation;
- **RESEARCH** for an alternative under study;
- **DEFERRED** for useful work intentionally outside the initial PSC3 profile.

A future freeze requires executable conformance tests, representative application evidence, and explicit closure or deferral of every open semantic question.
