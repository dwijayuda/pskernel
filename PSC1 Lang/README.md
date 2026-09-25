# PSC1 Language Reference

Status: **repository-derived PSC1 reference, branch draft**

Repository baseline: `dwijayuda/pskernel` `main` at
`165468c7f195c60906075e774543c1e65b3518f1`.

This directory consolidates the current ProofScript PSC1 language contract from
the repository's active architecture, plans, implementation evidence, and study
corpus. It is intentionally narrower than "everything Lean accepts" and newer
than the standalone v0.7 study draft where repository decisions have
deliberately revised or narrowed that draft.

## What PSC1 means here

PSC1 is the first frozen ProofScript language/capability profile sufficient to
express the ProofScript compiler naturally and carry it through the verified
self-host pipeline.

Do not confuse the **PSC1 language profile** with a generated compiler artifact
such as `PSC1.js`. The self-host plan also uses generation names such as PSC0,
PSC1 and PSC2 for compiler bootstrap stages. Those generation labels do not
change the language semantics defined here.

## Authority model

PSC1 has two different kinds of authority and they must not be conflated.

### Scope authority

For deciding **what belongs to PSC1**, use current repository state first:

1. executable gates and current implementation contracts on `main`;
2. `docs/plans/07_SELF_HOSTING_FOUNDATION.md`;
3. current architecture and anti-drift documents;
4. `study/proofscript-language-reference-v0.7.0/`;
5. `study/proofscript-language-reference-v0.6.1/` for compatible
   compiler-ready history.

The active repository explicitly selects the **ProofScript v0.7 line with
v0.6.1 as the compatible compiler-ready baseline**. ProofScript v0.8 is not a
normative PSC1 language reference.

### Semantic authority

For a feature PSC1 claims to support, its dependent-type, proof, recursion,
typeclass, equality, and foundational semantics follow the pinned Lean 4.34
model unless PSC1 explicitly records a separate portable runtime contract.

The pinned Lean source under `study/lean4-4.34.0/` is the primary semantic
reference. ProofScript does not gain permission to accept all Lean syntax merely
because Lean is the semantic authority.

## Core rule

> TypeScript-friendly surface syntax where it helps; Lean-compatible semantics
> wherever correctness depends on it; target-neutral runtime semantics before
> any backend lowering.

In particular:

- `def` is the canonical general definition declaration.
- `const` is a parameterless `def` alias.
- `function` is a parameterized `def` alias and requires an explicit
  declaration parameter group.
- `Prop`, dependent functions, inductives, definitional equality, proofs,
  typeclasses, recursion admissibility, and kernel acceptance retain
  Lean-compatible meaning.
- JavaScript, Rust, and WebAssembly representations are backend choices, not
  source-language semantics.
- Unsupported syntax or semantics fail closed.
- Parser success, generated TypeScript type checking, or runtime execution is
  never proof evidence. Final logical admission is through pskernel.

## Document map

- [PSC1_LANGUAGE_REFERENCE.md](./PSC1_LANGUAGE_REFERENCE.md) — normative
  language profile: design rules, declarations, terms, data, dependent types,
  proofs, recursion, effects, modules, interoperability, and portability.
- [SYNTAX_AND_GRAMMAR.md](./SYNTAX_AND_GRAMMAR.md) — consolidated source
  grammar, operator rules, D/E surface forms, canonical Lean lowering, and
  negative examples.
- [SEMANTICS_RUNTIME_AND_EFFECTS.md](./SEMANTICS_RUNTIME_AND_EFFECTS.md) —
  primitive/scalar semantics, collections, value identity, effects, FFI, and
  the shared CheckedCore/VerifiedIR contract.
- [CONFORMANCE_PORTABILITY_AND_STATUS.md](./CONFORMANCE_PORTABILITY_AND_STATUS.md)
  — conformance model, dual-source equivalence, backend obligations, assurance
  claims, required/optional/deferred matrix, and remaining SH7 freeze work.
- [SOURCE_EVIDENCE_MAP.md](./SOURCE_EVIDENCE_MAP.md) — research traceability,
  source precedence, and explicit resolution of conflicts between current plans,
  v0.7/v0.6.1 study material, pinned Lean 4.34, and current implementation.

## Learning documentation

The PSC1 folder now also contains a TypeScript-inspired documentation stack:

- [docs/README.md](./docs/README.md) — documentation landing page and learning paths;
- [docs/get-started/psc1-from-scratch.md](./docs/get-started/psc1-from-scratch.md) — first introduction;
- [docs/get-started/psc1-for-typescript-programmers.md](./docs/get-started/psc1-for-typescript-programmers.md) — migration of mental models from TS/JS;
- [docs/get-started/psc1-for-lean-programmers.md](./docs/get-started/psc1-for-lean-programmers.md) — PSC1 from a Lean background;
- [docs/get-started/psc1-in-5-minutes.md](./docs/get-started/psc1-in-5-minutes.md) — compact tour;
- [docs/tooling-and-projects.md](./docs/tooling-and-projects.md) — current psc/psconfig workflow;
- [handbook/README.md](./handbook/README.md) — 13-chapter progressive PSC1 Handbook;
- [reference/README.md](./reference/README.md) — quick lookup for language surface, CLI, and psconfig;
- [TYPESCRIPT_DOCS_HANDBOOK_STUDY.md](./TYPESCRIPT_DOCS_HANDBOOK_STUDY.md) — analysis of the TypeScript documentation architecture and how it maps to PSC1.

The Handbook is explanatory rather than normative. When a handbook example and
an exact language/conformance document appear to disagree, use the normative
reference and current executable gates.

## Normative wording

The words **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are
normative in these documents when capitalized.

A statement marked **OPEN FREEZE OBLIGATION** is intentionally unresolved in
the current repository. Implementations MUST NOT invent backend-specific
behavior to make such an item appear closed.

## PSC1 profile at a glance

### Required language/capability foundation

PSC1 requires:

- definitions, functions, lambdas, application, and `let`;
- `def`, `const`, and `function` source forms with one definition
  semantics;
- `if` and basic single-scrutinee `match`;
- structures, inductives, constructors, and projections;
- the scalar vocabulary:
  `Nat Int UInt8 UInt16 UInt32 UInt64 USize Int8 Int16 Int32 Int64 ISize
  Float Float32 Bool Char String Unit`;
- the bootstrap collection/data capabilities:
  `List`, `Option`, `Prod`, `Array`, ordered map/set families, and a
  `Result`/`Except`-style error ADT;
- dependent function types, `Prop`, proof terms, the required universe and
  metavariable machinery, implicit arguments, definitional equality, and the
  bounded class/instance/`Decidable` machinery used by the frozen compiler;
- structural recursion and a controlled executable `partial def` boundary;
- an explicit reader/state/error compiler effect with `do`, `pure`,
  `bind`, recovery, and transactional rollback;
- modules/imports, qualified names, deterministic resolution, source spans and
  diagnostics;
- the canonical JSON codec and versioned pskernel bridge used by self-hosting;
- canonical supported `.lean` <-> `.ps` translation with equal checked-core
  and executable-IR meaning;
- execution lowering through target-neutral VerifiedIR.

### Portable source principle

Pure source that depends only on portable PSC APIs is intended to be eligible
for TypeScript/JavaScript, Rust, and WebAssembly backends from the same
VerifiedIR. A target-specific capability or FFI dependency explicitly narrows
that target set.

### Explicitly not PSC1 semantics

PSC1 does not acquire any of the following merely because a backend or host
supports them:

- JavaScript truthiness, `any`, implicit `null`/`undefined`, prototypes,
  `this`, hoisting, or unrestricted early `return`;
- Rust ownership, borrowing, lifetimes, traits, `unsafe`, or Cargo semantics;
- WebAssembly value types, opcodes, memory/GC layout, WASI/WIT, or component
  model semantics;
- backend object identity or addresses as ordinary portable value identity;
- host exceptions, promises, evaluation order, or floating fast-math as
  language semantics;
- arbitrary Lean macros, custom syntax, custom elaborators, broad environment
  extensions, or unsafe implementation escape hatches.

## Design freeze principle

PSC1 follows a small-language policy: prefer one semantic mechanism and put
reusable convenience in libraries. Already-supported optional features remain
supported, but optionality does not make them blockers for PSC1 freeze.

A new REQUIRED language feature needs evidence from actual compiler source or a
frozen semantic obligation. Feature-count parity with another language is not
sufficient justification.

## Current freeze caveat

The repository has already frozen the scalar **type vocabulary**, but the full
machine-scalar operation/conversion matrix is still an **OPEN FREEZE
OBLIGATION**. Exact behavior for every accepted narrowing, division/remainder,
shift, integer/float conversion, NaN/signed-zero comparison, and target-word
conversion must be documented and executable-gated before SH7 can claim the
PSC1 freeze.

This reference therefore records that obligation instead of guessing at
semantics that the repository has not yet frozen.
