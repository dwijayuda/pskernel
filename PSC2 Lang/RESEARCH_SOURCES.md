# PSC2 Research Sources and Evidence Notes

Status: **supporting research record**

This file records the main evidence used to build the PSC2 draft. It is not a
substitute for the normative PSC1 references or the eventual PSC2 specification.

## 1. ProofScript repository sources

Primary internal sources:

- `PSC1 Lang/README.md`;
- `PSC1 Lang/PSC1_LANGUAGE_REFERENCE.md`;
- `PSC1 Lang/SEMANTICS_RUNTIME_AND_EFFECTS.md`;
- `PSC1 Lang/CONFORMANCE_PORTABILITY_AND_STATUS.md`;
- `docs/PROOFSCRIPT_ARCHITECTURE.md`;
- `docs/plans/05_LANGUAGE_COMPLETION.md`;
- `docs/plans/06_DUAL_SOURCE_LEAN_INTEROP.md`;
- `docs/plans/07_SELF_HOSTING_FOUNDATION.md`;
- `docs/plans/08_RUST_BACKEND_NATIVE.md` where present on the live self-host
  branch;
- `docs/selfhost/WASM3_BACKEND.md` where present on the live self-host branch;
- `selfhost/ARCHITECTURE_MAP.md` on the Lean-bootstrap/reference branches.

PSC2 inherits the PSC1 v0.7/v0.6.1 source-reference policy. ProofScript v0.8 is
not used as the normative PSC1/PSC2 source baseline merely because it exists.

## 2. Lean reference baseline

The ProofScript repository currently uses Lean 4.34 as its semantic study
baseline. Relevant official material includes:

- Lean Language Reference:
  `https://lean-lang.org/doc/reference/latest/`
- Lean 4.34 release notes:
  `https://lean-lang.org/doc/reference/latest/releases/v4.34.0/`
- Namespaces and Sections:
  `https://lean-lang.org/doc/reference/latest/Namespaces-and-Sections/`
- Tactic Reference:
  `https://lean-lang.org/doc/reference/latest/Tactic-Proofs/Tactic-Reference/`
- Lean verification tutorial / `mvcgen`:
  `https://lean-lang.org/doc/tutorials/latest/mvcgen/`
- Lean programming documentation:
  `https://lean4.dev/language`
- Type-theory/programming/theorem-proving documentation linked from the Lean
  documentation site.

The live Lean docs currently track a newer 4.35 release candidate in some
pages. PSC2 research may learn from those changes, but ProofScript's pinned
semantic compatibility claims remain tied to the repository's selected baseline
until explicitly revised.

## 3. Lean 4.34 intrinsic verification findings

Lean 4.34 is particularly relevant to PSC2 because it introduced/expanded
experimental intrinsic verification syntax. Official release notes document:

- `requires` as the precondition clause of a definition contract;
- `ensures` as the postcondition clause;
- `assert` in `do` as a verification assertion with no required runtime effect;
- `for ... invariant ...` and richer invariant binders;
- `decreasing`-class verification support;
- `vcgen` integration;
- a `where finally | spec => ...` section for remaining verification goals.

The Lean parser source also explicitly defines `requiresClause` and
`ensuresClause` for `def` contracts.

Lean 4.34 warns that intrinsic verification is experimental. The current 4.35
release-candidate notes continue to evolve the feature (for example contract
binders and invariant forms) while still marking intrinsic verification as
experimental. Therefore PSC2 should copy the architecture and vocabulary, not
assume every transient parser detail is stable.

## 4. Lean program-verification foundation

Lean's `Std.Do` verification work provides an important architectural model:

```text
monadic/effectful program
  -> weakest-precondition / Hoare-style specification
  -> verification conditions
  -> ordinary Prop goals
  -> tactic/manual proof
  -> kernel-checked proof term
```

This is a strong match for ProofScript's desired trust boundary: the VC
generator can be untrusted because the final proof remains kernel checked.

## 5. Lean usage signals

Current GitHub code-search signals were gathered from `leanprover/lean4` and
`leanprover-community/mathlib4` while preparing PSC2. Approximate file matches:

| Query | Repository | Approx. matches |
| --- | --- | ---: |
| `simp` | mathlib4 | 7,072 |
| `rw [` | mathlib4 | 6,224 |
| `have ` | mathlib4 | 4,552 |
| `simpa` | mathlib4 | 3,816 |
| `rcases` | mathlib4 | 2,264 |
| `calc` | mathlib4 | 1,744 |
| `by_cases` | mathlib4 | 1,536 |
| `let mut` | lean4 | 286 |
| broad `for ` | lean4 | 1,432 |
| `termination_by` | mathlib4 | 60 |

These numbers are deliberately described as **signals**:

- GitHub search reports files, not exact token counts;
- comments/examples may match;
- broad strings such as `for ` are especially noisy;
- repository revisions change counts;
- frequency alone does not determine language scope.

Even with those caveats, the signals make the broad conclusion robust:

- simplification/rewriting/structured local proofs are everyday theorem work;
- `rcases`/`calc`/`by_cases` are mainstream rather than exotic mathlib idioms;
- imperative-looking `do` programming is normal in Lean's implementation;
- explicit termination hints are specialized but solve a high-pain problem.

## 6. TypeScript research baseline

Official TypeScript Handbook material used in the PSC2 comparison includes:

- Handbook landing page:
  `https://www.typescriptlang.org/docs/handbook/`
- Everyday Types:
  `https://www.typescriptlang.org/docs/handbook/2/everyday-types.html`
- More on Functions:
  `https://www.typescriptlang.org/docs/handbook/2/functions.html`
- Object Types:
  `https://www.typescriptlang.org/docs/handbook/2/objects.html`
- Narrowing:
  `https://www.typescriptlang.org/docs/handbook/2/narrowing.html`
- Generics:
  `https://www.typescriptlang.org/docs/handbook/2/generics.html`
- Modules:
  `https://www.typescriptlang.org/docs/handbook/2/modules.html`
- TypeScript for Functional Programmers:
  `https://www.typescriptlang.org/docs/handbook/typescript-in-5-minutes-func.html`
- async/await release/reference material linked from the TypeScript docs.

The Handbook explicitly presents functions, object types, narrowing, classes,
generics and modules as everyday/core developer concepts. It documents default
parameters and parameter destructuring as normal function ergonomics, and
modern TypeScript relies on ECMAScript modules for scoped code organization.
Async/await and Promise typing are longstanding mainstream TypeScript
capabilities.

## 7. Cross-language interpretation

PSC2 does not mechanically import TypeScript syntax. Instead it asks what user
problem the feature solves.

Examples:

```text
TS method calls        -> PSC generalized static field/method notation
TS object spread       -> PSC immutable structure update
TS destructuring       -> PSC patterns
TS loops/mutation      -> PSC controlled do/state iteration sugar
TS optional values     -> PSC Option
TS exceptions          -> PSC Result/Except for expected failures
TS Promise/async       -> PSC Task + async/await sugar
TS interfaces/classes  -> PSC structures/classes/modules/functions
```

This preserves familiar ergonomics while keeping ProofScript's semantics
explicit and portable.

## 8. High-frequency vs high-pain distinction

PSC2 scope should use two axes:

### High frequency

Examples:

- method notation;
- patterns;
- namespace/module organization;
- `simp`/`rw`/`have`;
- loops in application/compiler code.

### High pain despite lower frequency

Examples:

- well-founded recursion/termination annotations;
- opacity/transparency control;
- loop invariants;
- contracts;
- async/task support for web/server adoption;
- controlled notation for domain mathematics.

A feature may deserve PSC2 standardization because its absence blocks an entire
class of realistic programs, not because it appears on every page.

## 9. Research conclusion

The strongest PSC2 candidates mostly do **not** justify a larger kernel.

They divide naturally into:

```text
source/elaboration ergonomics
proof/tactic/Meta libraries
verification/VC infrastructure
target-neutral standard libraries
controlled plugins
```

The PSC2 research therefore reinforces the PSC1 architecture rather than
contradicting it:

> keep the semantic foundation small; move capability upward.