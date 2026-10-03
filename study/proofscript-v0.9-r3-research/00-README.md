# ProofScript v0.9 r3 Language Research Workstream

Status: **accepted language specification plus supporting research/protocol documents; not an implementation release**  
Branch: research/proofscript-v0.9-r3  
Semantic pin: Lean 4.34.0, commit 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b

## Language authority

The sole normative authority for ProofScript source syntax and language semantics on this branch is:

~~~text
ProofScript_Language_Reference_v0.9.0_r3.md
~~~

The reference is standalone and language-only. It contains:

- language/profile identities;
- lexical and source rules;
- declarations and binders;
- terms and application;
- structures/classes/inductives/patterns;
- recursion and basic do semantics;
- primitive/data semantics;
- proof source;
- pure contract syntax/meaning;
- exact psc2-language-v1 coverage;
- exact lean-subset-psc2-v1 boundaries;
- psc2-standard-language-v1 language-facing closure;
- Post-PSC2 language candidates;
- owned grammar and canonical examples.

It intentionally does **not** define compiler architecture, self-host sequencing, backend architecture, cache layout, compiler IR implementation, release evidence, or package implementation.

No companion document may override language meaning.

## PSC2 language identities

~~~text
ps-0.9-r3
ps-standard-0.9-r3
ps-lean-extensible-0.9-r3

psc2-language-v1
psc2-standard-language-v1
lean-subset-psc2-v1
psc2-pattern-v1
~~~

psc2-compiler-v1 is a compiler/product claim. Its source-language requirement is exactly psc2-language-v1.

psc2-standard-v1 is a packaged distribution claim. Its language-facing Standard profile is psc2-standard-language-v1; libraries/provers/runtimes remain separately versioned packages rather than hidden additions to the base language.

## Post-PSC2 language roadmap

Language evolution after PSC2 is isolated in:

~~~text
POST_PSC2_LANGUAGE_ROADMAP.md
~~~

That roadmap discusses only future language candidates such as richer matching, imperative-looking sugar, richer verification syntax, application-effect syntax, controlled extensions, UI dialects, larger Lean compatibility profiles, and possible systems-language surfaces.

Compiler/platform sequencing belongs in the implementation plans, not the language roadmap.

## Machine-readable mirrors

These files mirror selected current profile rules:

- FEATURE-REGISTRY-r3.json
- PS-STANDARD-REGISTRY-r3.json

They are not independent language authorities. If a mirror disagrees with the language reference, the mirror is wrong and must be regenerated/fixed.

The active feature registry contains only current feature/profile identities. Historical inheritance and retired feature identities are research history, not active language definition.

## Scoped companion protocols

These documents may be normative for their own protocol, but are not source-language authorities:

- INTERFACEIR-v1.md / INTERFACEIR-v1.schema.json — foreign npm/TypeScript binding protocol;
- SEMANTIC-BUNDLE-v1.md / SEMANTIC-BUNDLE-v1.schema.json — checked semantic import protocol;
- 23-PRE-STABLE-EVIDENCE-GATES.md — release/evidence policy.

Application runtime semantics are researched separately in:

~~~text
08-APPLICATION-EFFECTS-ASYNC-RESOURCES.md
~~~

They remain library/runtime semantics unless a future language profile adds syntax over them.

## Implementation and planning documents

Compiler architecture, bootstrap/self-host work, RuntimeIR/backends, tooling, packages, and platform plans remain under docs/ and PSC2 Lang/.

They are implementation or research inputs. They may explain how to implement the language, but they cannot add source constructs or change source meaning.

In particular, a feature found in Lean 4 is not automatically:

- a psc2-language-v1 feature;
- a psc2-compiler-v1 requirement;
- a ps-standard feature.

Every language-facing capability must have explicit profile ownership.

## Research history

The numbered research files, decision ledger, acceptance report, old PSC2 research drafts, migration studies, and baseline snapshots are retained to explain why decisions were made.

They are not needed to interpret a current ProofScript program.

## Current completeness criterion

The source-language design is considered closed for this edition when every relevant capability is:

1. defined by the main reference;
2. explicitly included from the pinned native semantic categories;
3. selected by the closed Standard language profile;
4. assigned to a separate extensible profile;
5. listed as Post-PSC2 language work; or
6. explicitly excluded.

This is intentionally not Lean feature-count parity. Libraries, prover packages, official extensions, plugins, and foreign interfaces are expected to provide substantial user-facing power without turning every facility into compiler-core syntax.
