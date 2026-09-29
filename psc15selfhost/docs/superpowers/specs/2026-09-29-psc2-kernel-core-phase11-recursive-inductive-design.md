# PSC2 KernelCore Phase 11 Design — Strictly-Positive Single-Family Recursive Inductives

Status: design proposed for review

Date: 2026-09-29

Branch: `psc2/kernel-core-phase11-recursive-inductive`

Baseline: accepted Phase 10 documentation head `4fe920031d64e76e7e07cdaf35015563f6bb9f58`

Accepted Phase 10 implementation/assurance SHA: `525452a87261036e63d2e2a4215e0049c96bcd71`

## 1. Purpose

Phase 11 extends the small PSC1-self-hostable KernelCore from the accepted Phase 10 non-recursive inductive/recursor surface to the smallest useful recursive-inductive admission surface.

The goal is to admit one strictly-positive recursive inductive family while preserving the existing trust-boundary principles:

- trusted source remains PSC1-subset `.lean`;
- actual `psc1 check` remains a hard gate;
- the kernel validates semantics but does not absorb elaborator/generator convenience machinery;
- mature `PSC1Kernel` remains the differential/reference oracle;
- unsupported recursive shapes fail closed;
- recursive recursor / induction-hypothesis semantics remain a separately designed later phase.

The intended result is a trusted admission layer able to represent common recursive datatypes such as list/tree-style single-family recursion without prematurely expanding into mutual, nested, or general positivity machinery.

## 2. Phase boundary

### In scope

Phase 11 adds trusted support for:

1. one already-bounded single inductive family;
2. direct recursive constructor fields whose field type is an application of the inductive being declared;
3. positive functional recursive fields of the form `(x : A) -> ... -> T params indices`, provided every function-domain binder is non-recursive;
4. uniform recursive uses of the family parameters and universe levels;
5. rejection of recursive occurrences inside recursive result indices;
6. rejection of negative recursive occurrences;
7. rejection of nested recursive occurrences through another type constructor;
8. final `isRec` and `isReflexive` metadata derived from accepted constructor shapes;
9. differential tests against the mature `PSC1Kernel` bounded recursive-inductive behavior;
10. Phase 1–11 aggregate assurance and full existing PSC2 regression execution.

### Explicitly out of scope

Phase 11 does **not** add:

- recursive recursor rule generation;
- induction-hypothesis generation or validation;
- recursive recursor iota semantics;
- mutual inductives;
- nested inductives;
- general positivity through arbitrary type constructors;
- positivity inference through reducible aliases beyond the explicitly reviewed WHNF surface;
- K conversion;
- structure eta;
- projection computation;
- literal-to-constructor recursor conversion;
- compiler `CheckedCore` provider cutover;
- replacement/removal of the mature `PSC1Kernel` reference oracle;
- a claim of full Lean 4.34 equivalence.

These remain separate later gates.

## 3. Why this phase is separate from recursive recursors

Recursive inductive admission and recursive recursor semantics are related but trust-distinct.

Phase 11 answers only:

> Is this constructor telescope a valid strictly-positive recursive occurrence of this one family, with uniform parameters/universes and safe indices?

A later phase must answer:

> Given accepted recursive constructor metadata, are supplied/generated recursor minors and induction hypotheses canonical and type-preserving, and does recursive iota reduce them correctly?

Keeping those questions separate has four benefits:

1. the positivity/admission TCB remains reviewable;
2. acceptance tests can isolate malformed recursive declarations independently of recursor behavior;
3. a future recursive-recursors phase can consume trusted recursive-field metadata instead of re-deriving positivity;
4. failures remain fail-closed rather than making recursor generation an admission authority.

## 4. Considered approaches

### Approach A — direct recursive fields only

Accept only constructor fields whose reduced type is directly `T params indices`.

Example accepted shape:

```text
List.cons : A -> List A -> List A
```

Advantages:

- smallest implementation;
- easiest termination/self-host proof shape;
- minimal new trusted metadata.

Disadvantages:

- immediately excludes positive functional recursive fields already supported by the mature reference;
- likely requires replacing the positivity analyzer in the next phase;
- creates avoidable semantic churn.

### Approach B — direct + positive functional recursive fields

Accept either:

```text
T params indices
```

or a positive function chain:

```text
(x1 : A1) -> ... -> (xn : An) -> T params indices
```

where every `Ai` is non-recursive and the final codomain is the same inductive family with valid uniform parameters/universe levels and non-recursive indices.

Advantages:

- matches the mature bounded reference model;
- still small and auditable;
- supports reflexive recursive fields without importing general nested/mutual positivity;
- gives later recursive-recursors work the metadata it needs.

Disadvantages:

- requires an explicit recursive-field shape analysis rather than a single direct occurrence test;
- slightly larger trusted surface.

### Approach C — general Lean-style positivity now

Attempt mutual, nested, arbitrary positive type-constructor traversal, recursor generation, and broader reducibility in one phase.

Rejected because it would substantially widen the TCB, mix independent correctness questions, and violate the project rule of moving complexity upward unless the kernel must own it.

### Decision

Use **Approach B**.

## 5. Trusted semantic model

### 5.1 Recursive-field classification

For each constructor field domain, KernelCore performs bounded weak-head analysis under the existing explicit resource configuration.

A field is classified as:

- **non-recursive** — no occurrence of the target family in the original or reduced field type;
- **direct recursive** — reduced type is exactly the target family applied to the required universe levels, uniform parameters, and the declared number of indices;
- **functional recursive** — reduced type is a chain of `forallE` binders whose domains contain no target-family occurrence, ending in a valid direct recursive result;
- **invalid recursive** — any recursive occurrence that does not fit the allowed direct/functional shape.

The classification must be based on the already-declared family name and admitted header metadata, not on user-provided convenience flags.

### 5.2 Strict positivity rule

The target inductive may not occur in a negative function-domain position.

For a functional recursive field:

```text
(x : A) -> R
```

KernelCore requires:

```text
containsTarget(A) = false
```

and recursively analyzes `R`.

If the target occurs in a function domain, admission fails closed with a dedicated negative-occurrence diagnostic.

### 5.3 Uniformity rule

Every accepted recursive result must use:

- the same target family name;
- exactly the expected universe levels;
- exactly the declared family parameters in uniform binder order;
- exactly the declared number of indices.

Recursive family occurrences with missing/extra/wrong parameters or mismatched universe arguments are rejected.

### 5.4 Recursive index rule

After consuming uniform parameters, the recursive result indices must not themselves contain an occurrence of the target inductive.

This rejects self-referential index shapes that exceed the bounded Phase-11 model.

### 5.5 Nested recursion rule

Recursive occurrences nested beneath another non-function type constructor are rejected.

Examples intentionally rejected in Phase 11 include shapes equivalent to:

```text
Box (T a)
Array (T a)
Option (T a)
```

unless a later reviewed phase introduces explicit positivity semantics for such constructors.

### 5.6 Constructor result rule

Constructor final results continue to use the accepted Phase-8 family result rules:

- same family;
- uniform parameters;
- correct universe arguments;
- correct index arity;
- no target-family occurrence inside result indices.

Phase 11 does not relax those constraints.

## 6. Recursive metadata

Phase 11 should introduce the smallest trusted metadata needed by later phases.

Conceptually:

```text
RecursiveFieldInfo
  fieldIndex / field identity
  functionArgs : list of binder metadata
  indices      : list of Expr
```

and per-constructor analysis sufficient to derive:

```text
isRec        = any recursive field exists
isReflexive  = any recursive field has one or more functional arguments
```

The exact storage shape may be simplified during planning if existing Phase-8/10 declaration metadata already carries enough canonical information.

Important constraint: Phase 11 must not store elaborator-only open local state in the trusted environment. Persisted recursive metadata must be closed/canonical or re-derivable from admitted closed constructor declarations.

## 7. Environment/admission behavior

Admission remains transactional/fail-closed.

For a recursive family:

1. validate family/header metadata using the existing Phase-8 path;
2. validate constructor universe parameters, safety, ownership, order, field counts, and result shape;
3. classify each constructor field under the positivity rules above;
4. reject the entire declaration on any invalid recursive occurrence;
5. only after all constructors are valid, publish final inductive metadata with `isRec` / `isReflexive` derived from trusted analysis;
6. preserve the original immutable environment on failure.

Phase 11 must not trust incoming `isRec` / `isReflexive` values as admission authority.

## 8. PSC1-subset / self-hostability constraints

Every new trusted module or trusted modification must continue to satisfy the actual flattened PSC1 source/self-host path.

Trusted KernelCore source must not introduce:

- `partial`;
- `unsafe`;
- `extern`;
- `implemented_by`;
- `IO`;
- Lean/Std implementation dependencies;
- custom syntax/macros/elaborators;
- `mutual` trusted definitions;
- host semantic caches/sessions/replay state;
- host `List` / `Option` as trusted semantic storage where KernelCore-local carriers are required by the established source profile.

Recursive helper definitions should follow the already-proven PSC1 structural-recursion pattern: one structurally decreasing argument, with changing context/binder-depth values captured or curried where necessary.

## 9. Differential oracle

The mature `PSC1Kernel` remains the semantic reference for this bounded recursive-inductive slice.

Relevant oracle behavior already supports:

- direct strictly-positive recursive fields;
- functional recursive fields when each function-domain binder is non-recursive and the final codomain is the same inductive;
- rejection of negative occurrences;
- rejection of nested occurrences;
- rejection of recursive indices;
- uniform parameter/universe checking;
- derivation of recursive/reflexive metadata.

Phase 11 parity tests compare observable accepted/rejected behavior and resulting trusted metadata without copying the mature implementation’s broader recursor-generation machinery into KernelCore.

## 10. Required test matrix

### Positive admission

At minimum:

1. direct recursive field — list-style recursion;
2. multiple constructors with only one recursive constructor;
3. multiple direct recursive fields if supported by the bounded reference surface;
4. functional recursive field with one non-recursive argument;
5. functional recursive field with multiple non-recursive arguments;
6. indexed recursive family with valid non-recursive indices;
7. accepted declarations set `isRec = true`;
8. accepted functional recursive declarations set `isReflexive = true`;
9. non-recursive Phase-8 declarations remain accepted and retain `isRec = false`.

### Rejection matrix

At minimum:

1. recursive occurrence in function domain (negative position);
2. recursive occurrence nested through another constructor/type;
3. recursive occurrence inside result indices;
4. recursive occurrence with nonuniform parameter argument;
5. wrong universe arguments;
6. wrong parameter count;
7. wrong index arity;
8. recursive occurrence in constructor metadata not belonging to the admitted family;
9. forged incoming `isRec` / `isReflexive` flags inconsistent with analyzed fields;
10. malformed recursive functional chain;
11. admission failure leaves original environment unchanged.

### Regression preservation

All existing permanent Phase 1–10 gates must remain green, including:

- Phase-8 non-recursive inductive tests;
- Phase-9 Quot tests;
- Phase-10 recursor admission/rejection/direct-iota tests;
- forged-minor rejection regression;
- Eq compatibility path;
- bootstrap closure isolation;
- actual KernelCore PSC1 source profile;
- full existing PSC2 regression suite.

## 11. Assurance gates

Phase 11 acceptance requires all of the following on the exact accepted implementation SHA:

1. dedicated recursive-inductive metadata tests;
2. dedicated recursive-inductive positive admission parity;
3. dedicated strict-positivity rejection matrix;
4. functional-positive recursive-field parity;
5. recursive metadata (`isRec` / `isReflexive`) parity;
6. environment transactional-failure regression;
7. actual `psc1 check` over the trusted KernelCore source closure;
8. `assurance:kernel-core:phase1` through `assurance:kernel-core:phase11` all green;
9. full existing `npm run check` green;
10. exact source-size/LOC evidence from the existing reproducible reporter, if retained by the current assurance command.

The acceptance record must pin:

- implementation/assurance SHA;
- exact workflow run and job;
- Lean version;
- source-profile module count;
- allowed claims and explicit non-claims.

## 12. Allowed claims after acceptance

If all gates are green, it will be valid to claim:

- KernelCore admits a bounded PSC1-self-hostable strictly-positive single-family recursive-inductive surface;
- direct recursive fields and positive functional recursive fields are supported on the reviewed profile;
- negative, nested, recursive-index, nonuniform-parameter, and malformed recursive occurrences fail closed;
- recursive/reflexive metadata is derived from trusted constructor analysis;
- all Phase 1–11 aggregate gates plus the existing PSC2 regression gate are green on the exact accepted SHA.

## 13. Explicit non-claims after acceptance

Phase 11 must not be used to claim:

- recursive induction-hypothesis semantics;
- recursive recursor rule generation;
- recursive recursor iota correctness;
- mutual inductives;
- nested inductives;
- arbitrary positivity through user-defined type constructors;
- general Lean positivity equivalence;
- K conversion;
- structure eta/projection computation;
- compiler `CheckedCore` provider cutover;
- replacement/removal of mature `PSC1Kernel`;
- full or formally proven Lean 4.34 equivalence.

## 14. Expected next phase

The strongest next semantic candidate after Phase 11 is a **separate recursive-recursor / induction-hypothesis phase** consuming Phase-11 trusted recursive-field metadata.

That later phase should validate or construct canonical recursive calls / IH binders and extend iota reduction for accepted recursive constructors without reopening positivity as a recursor concern.

Mutual/nested inductives should remain later and separately gated.

## 15. Summary

Phase 11 deliberately adds one missing trusted capability:

> bounded strict positivity for a single recursive inductive family, including direct and positive functional recursive fields, with uniform parameters/universes and fail-closed rejection of negative, nested, recursive-index and malformed occurrences.

It does **not** combine that capability with recursive recursor/IH semantics. This keeps the trusted kernel small, PSC1-self-hostable, reviewable, and aligned with the project rule that complexity stays outside the TCB until the kernel must own it.
