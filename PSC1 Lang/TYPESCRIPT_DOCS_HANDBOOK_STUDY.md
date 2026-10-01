# TypeScript Documentation / Handbook Study for PSC1

Status: documentation-design study used to build the PSC1 docs in this branch.

Study source:

```text
study/www.typescriptlang.org/docs/
study/www.typescriptlang.org/docs/handbook/
study/www.typescriptlang.org/docs/handbook/2/
study/www.typescriptlang.org/docs/handbook/modules/
study/www.typescriptlang.org/docs/handbook/declaration-files/
```

The goal of this study was **not** to copy TypeScript prose or transpose
TypeScript features into ProofScript. The goal was to understand why the
TypeScript documentation is approachable and apply the useful documentation
patterns to a very different language.

## 1. Main structural finding

The TypeScript corpus separates four reader jobs:

1. **Landing/discovery** — "where should I start?"
2. **Audience-specific onboarding** — new programmer, JavaScript programmer,
   OOP programmer, functional programmer.
3. **Handbook** — a progressive conceptual walkthrough.
4. **Reference/tooling** — modules, compiler options, declaration files,
   project references, configuration, and specialized details.

PSC1 now follows the same documentation architecture:

```text
PSC1 Lang/
  docs/
    README.md
    get-started/
    tooling-and-projects.md

  handbook/
    README.md
    01-... through 13-...

  reference/
    README.md
    ...

  PSC1_LANGUAGE_REFERENCE.md
  SYNTAX_AND_GRAMMAR.md
  SEMANTICS_RUNTIME_AND_EFFECTS.md
  CONFORMANCE_PORTABILITY_AND_STATUS.md
```

The important separation is:

```text
learning guide != quick reference != normative specification
```

## 2. TypeScript Handbook introduction pattern

The TypeScript handbook introduction explicitly explains:

- what the handbook is for;
- how it is structured;
- what readers should know afterward;
- what the handbook intentionally does not cover;
- that the handbook is not the language specification.

PSC1 adopts this pattern in `handbook/README.md`.

This is especially important for ProofScript because there are several
different sources of truth:

- friendly learning material;
- exact syntax reference;
- current implementation status;
- semantic authority in Lean 4.34;
- pskernel trust claims;
- self-host freeze plans.

Without an explicit role for each document, readers can easily confuse "easy
example" with "complete formal support".

## 3. Audience-specific introductions

TypeScript has short introductions tailored to prior knowledge.

The study corpus contains entry points for:

- new programmers;
- JavaScript programmers;
- OOP programmers;
- functional programmers;
- tooling.

PSC1 uses the same strategy, but chooses audiences that matter to this
language:

- `psc1-from-scratch.md`;
- `psc1-for-typescript-programmers.md`;
- `psc1-for-lean-programmers.md`;
- `psc1-in-5-minutes.md`;
- `tooling-and-projects.md`.

A separate "OOP programmer" page was not copied because PSC1 does not make OOP
the central data/abstraction model. The TypeScript idea is preserved — explain
the language relative to the reader's prior mental model — without importing
an irrelevant language feature hierarchy.

## 4. Progressive concept ordering

TypeScript's modern handbook progresses roughly from:

```text
basics
-> everyday types
-> narrowing
-> functions
-> objects
-> type manipulation/generics
-> classes
-> modules
```

PSC1's equivalent conceptual progression is:

```text
basics
-> everyday semantic types
-> functions
-> structures/inductives/pattern matching
-> generics/dependent types
-> propositions/proofs
-> typeclasses
-> recursion/totality
-> effects
-> modules/projects
-> FFI
-> backend portability
-> Lean source interoperability
```

This preserves the pedagogical gradient while following PSC1's actual semantic
center of gravity.

## 5. Why PSC1 has no TypeScript-style Narrowing chapter

TypeScript narrowing is central because TypeScript models JavaScript values with
unions, structural types, truthiness, `typeof`, `instanceof`, and
control-flow analysis.

Copying that chapter shape literally would teach the wrong mental model.

PSC1 instead has:

- inductive constructors;
- explicit pattern matching;
- dependent types;
- propositions/proof evidence.

Therefore the analogous learning task is handled by:

```text
04-data-and-pattern-matching.md
05-generics-and-dependent-types.md
06-propositions-and-proofs.md
```

## 6. Why PSC1 has no Object Types / Classes emphasis

TypeScript's handbook devotes major space to object types and classes because it
must describe JavaScript's object-oriented/structural ecosystem.

PSC1 explicitly rejects those as semantic foundations.

Its corresponding chapters emphasize:

- structures;
- inductives;
- functions;
- modules;
- typeclasses.

This matches the PSC1 small-language/Go-like freeze policy.

## 7. Everyday Types pattern

TypeScript's Everyday Types chapter succeeds because it teaches types from
values programmers actually write before moving to advanced type manipulation.

PSC1 mirrors that pattern in `02-everyday-types.md`, but the content is very
different.

The PSC1 chapter starts with the frozen semantic vocabulary:

```text
Nat Int
UInt8 UInt16 UInt32 UInt64 USize
Int8 Int16 Int32 Int64 ISize
Float Float32
Bool Char String Unit
```

and then introduces:

- functions;
- Option-style absence;
- Result-style errors;
- List;
- Array;
- Product;
- ordered Map/Set.

The chapter repeatedly distinguishes a language semantic type from target
representations such as JS `number`, Rust integers, or Wasm value types.

## 8. Example-first teaching

TypeScript pages commonly:

1. show a small example;
2. explain what the checker knows;
3. show a nearby invalid/misleading form;
4. generalize the rule;
5. point to the next topic.

PSC1 handbook chapters follow the same rhythm.

Examples are deliberately chosen from syntax already present in the repository
where possible, especially the ProofScript-authored stdlib.

That gives the docs dogfood value rather than inventing a separate tutorial
language.

## 9. "Next Steps" navigation

The TypeScript onboarding pages consistently end by directing the reader toward
the next useful resource.

Every PSC1 onboarding/handbook page likewise ends with an explicit next chapter
or reference destination.

This makes the documentation navigable even when rendered as plain Markdown
without a dedicated documentation website.

## 10. Modules: concept vs reference

TypeScript separates:

- a friendly Modules handbook page;
- deeper module theory;
- module reference;
- resolution/compiler-option guidance.

PSC1 adopts the same separation:

- `handbook/10-modules-and-projects.md` explains the model;
- `docs/tooling-and-projects.md` explains workflow;
- `reference/psconfig.md` gives exact configuration;
- normative dual-source/module behavior remains in the language/conformance
  references.

This avoids turning the handbook into a configuration schema dump.

## 11. Compiler options / project references pattern

TypeScript has dedicated material for:

- CLI;
- compiler options;
- project references;
- module resolution.

PSC1 similarly separates:

- CLI quick reference;
- `psconfig.json` reference;
- logical source-root resolution;
- runtimeDependencies;
- mixed `.ps`/`.lean` projects.

The content is repository-derived from current `packages/cli` and
`@proofscript/project`, not copied from old ProofScript CLI planning prose.

## 12. Declaration files: conceptual lesson for PSC1

TypeScript declaration-file documentation exists because static type declarations
and runtime JavaScript packages must be connected carefully.

PSC1's analogous high-risk boundary is FFI/runtime assumptions.

So PSC1 gives a dedicated handbook chapter to:

- logical signature vs runtime binding;
- exact dependency policy;
- proof-evidence boundary;
- pure/effectful capability classification;
- translation limitations;
- portability narrowing.

The documentation pattern transfers even though the mechanism differs.

## 13. Important differences intentionally preserved

The PSC1 docs do **not** imitate TypeScript by adding sections for:

- `any`;
- structural type compatibility;
- truthiness narrowing;
- `null`/`undefined` unions;
- TypeScript classes as the primary abstraction;
- conditional/mapped/template-literal type systems;
- TypeScript-specific declaration merging;
- JSX;
- CommonJS compatibility as a language semantic concern.

Those would teach a false model of PSC1.

## 14. ProofScript topics TypeScript does not need

PSC1 adds major handbook topics absent from TypeScript's semantic model:

- dependent Pi types;
- `Prop`;
- proof terms;
- kernel admission;
- tactic trust boundary;
- recursion/termination;
- proof erasure;
- typeclass evidence;
- explicit effect semantics;
- CheckedCore/VerifiedIR;
- cross-backend semantic portability;
- canonical Lean translation;
- self-host/source transition.

These are first-class chapters rather than appendices because they define what
makes ProofScript different.

## 15. Current-vs-normative documentation rule

The TypeScript docs largely describe one mature implementation.

PSC1 is still closing its self-host freeze, so its documentation needs one
extra discipline:

> Never blur language intent, current implementation evidence, and open freeze
> obligations.

The new docs therefore label open areas such as the full scalar
operation/conversion matrix rather than inventing details for tutorial
completeness.

## 16. Documentation maintenance rule

Future PSC1 docs should preserve the split:

### Put it in `docs/get-started/` when

the reader is deciding how to begin or translating from a prior language mental
model.

### Put it in `handbook/` when

the reader needs a conceptual, example-driven explanation of a PSC1 feature.

### Put it in `reference/` when

the reader already knows the concept and needs exact syntax/configuration.

### Put it in the normative PSC1 reference when

the statement defines semantic meaning, conformance, trust, or freeze
obligations.

That separation is the most valuable idea taken from the TypeScript study.
