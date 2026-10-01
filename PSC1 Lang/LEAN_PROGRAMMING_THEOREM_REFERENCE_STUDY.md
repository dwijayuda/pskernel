# Lean Programming, Theorem-Proving, and Language-Reference Study

This document records the documentation research used to create the PSC1 books
and manual in this branch.

## Studied corpora

The study focused on three large documentation sets already vendored in
`study/`:

```text
study/functional_programming_in_lean/
study/theorem_proving_in_lean4/
study/lean4-language-reference/
```

The goal was not to copy prose or to make PSC1 synonymous with Lean. The goal
was to identify:

- teaching order that works for dependent functional programming;
- proof concepts that deserve their own progression;
- reference categories needed by implementers;
- where a small PSC1 deliberately diverges from full Lean.

## 1. Functional Programming in Lean: main lessons

The programming book progresses through:

```text
Getting to Know Lean
Hello, World!
Propositions / Proofs / Indexing
Overloading and Type Classes
Monads
Functors / Applicative / Monads
Monad Transformers
Programming with Dependent Types
Tactics / Induction / Proofs
Programming / Proving / Performance
```

Its most important pedagogical idea for PSC1 is that proofs should enter the
programming story when they solve a programming problem.

Examples include:

- indexing where a proof justifies safety;
- dependent types that move invariants into APIs;
- induction following recursive data;
- proofs relating a simple specification to a faster implementation;
- termination evidence for algorithms whose recursion is not syntactically
  obvious.

### PSC1 adaptation

PSC1 keeps that progression but changes the language mechanisms where necessary.

Lean book | PSC1 book
--- | ---
Getting to know Lean | Getting to Know PSC1
Hello World / Lake | `psc init/check/build/run` + `psconfig.json`
proof-carrying indexing | proof argument + Option/default array APIs
broad typeclass ecosystem | bounded class/instance/Decidable profile
Monad/Functor hierarchy | explicit semantic explanation, not first-freeze requirement
transformer stacks | one concrete compiler reader/state/error effect
dependent programming | Pi types, indexed-family model, bounded frontend
programming/proving/performance | CheckedCore/Erasure/VerifiedIR + multi-backend performance

The result is [Programming in ProofScript PSC1](./programming-in-proofscript/README.md).

## 2. Theorem Proving in Lean 4: main lessons

The theorem-proving book has a very effective conceptual order:

```text
Dependent Type Theory
Propositions and Proofs
Quantifiers and Equality
Tactics
Interacting with Lean
Inductive Types
Induction and Recursion
Structures and Records
Type Classes
Conversion Mode
Axioms and Computation
```

The key architectural lesson is that tactic proofs are secondary to proof
terms:

```text
proposition
-> goal
-> tactic operations
-> explicit proof term
-> kernel
```

PSC1 adopts this model directly.

### Current PSC1 tactic boundary

The current executable tactic parser/elaborator supports the bounded set:

```text
exact
exact?
assumption
intro
apply
refine
constructor
cases
induction
rfl
rw
simp only
```

The docs therefore go deep on those tactics instead of reproducing Lean
chapters for unsupported tactics.

### Intentional differences

Full Lean concept | PSC1 first profile
--- | ---
large tactic language | bounded proof-producing tactic family
conversion mode | not currently a PSC1 feature
unrestricted simplifier | explicit bounded `simp only`
large automation ecosystem | small `exact?` search + explicit proofs
full dependent cases/induction | bounded recursor-based implementation
custom tactics/macros | deferred language-extension system
full classical ecosystem | assumptions must be explicit/trackable

The result is
[Theorem Proving in ProofScript PSC1](./theorem-proving-in-proofscript/README.md).

## 3. Lean Language Reference: main lessons

The Lean Language Reference is organized for lookup rather than teaching.

Its major categories include:

- elaboration and compilation;
- type system;
- source files/modules;
- definitions;
- axioms;
- attributes;
- typeclasses;
- coercions;
- runtime code;
- terms;
- tactic proofs;
- propositions;
- basic types;
- monads/`do`;
- IO;
- notation/macros;
- build/distribution;
- validating proofs.

The most important lesson is the separation between **surface syntax**,
**elaboration**, **kernel meaning**, and **runtime compilation**.

PSC1 needs the same separation even though its language is smaller.

### PSC1 manual mapping

Lean reference | PSC1 manual treatment
--- | ---
Elaboration and Compilation | processing, elaboration, pskernel, CheckedCore, erasure, VerifiedIR
The Type System | dependent Pi, Prop, universes, inductives, definitional equality
Source Files and Modules | deterministic `.ps` / bounded `.lean` module graph
Definitions | `def`, `const`, `function`, theorem, structure, inductive, class, instance
Attributes | only explicitly supported bounded metadata; not a broad first-freeze system
Type Classes | bounded class/instance/Decidable synthesis
Coercions | only explicitly supported behavior; not automatically inherited
Run-Time Code | VerifiedIR plus target backends/FFI
Terms | bounded PSC1 term grammar and D/E forms
Tactic Proofs | current bounded proof-producing tactics
Basic Propositions | Prop, Pi/implication, Eq; broader notation only when gated
Basic Types | frozen PSC1 scalar vocabulary + compiler collection capabilities
Monads/do | concrete compiler effect and owned `do` semantics
IO | explicit host capability boundary
Notations and Macros | replaced by closed registered-extension boundary
Build Tools | `psc`, `psconfig.json`, npm, backend artifacts
Validating Proofs | pskernel admission + explicit assurance layers

The result is [PSC1 Language Manual](./language-manual/README.md).

## 4. Reference findings that materially affect PSC1

### Parsing is not semantics

The Lean reference explicitly distinguishes parsing, elaboration, kernel
checking, and compilation.

PSC1 makes this even more important because it has two source frontends and
multiple runtime backends.

### Terms are the common semantic currency

Programs and proofs both become typed terms.

This is why PSC1 can have TypeScript-friendly call/declaration syntax without
inventing a TypeScript-like proof calculus.

### Inductives connect programming and proving

Constructors support ordinary data construction.

Recursors support:

- pattern matching;
- cases;
- induction.

PSC1's bounded `cases` and `induction` should therefore remain recursor-based
instead of becoming trusted tactic primitives.

### Typeclass inference is elaboration

Instance synthesis constructs an argument.

It is not runtime reflection and not kernel magic.

This supports a small TCB even if instance search grows more sophisticated.

### Proof validation must expose assumptions

The Lean reference distinguishes kernel trust from compiler-trusting paths and
tracks axioms.

PSC1 adopts the stricter rule:

- pskernel is the logical admission authority;
- host runtime execution is never implicit proof evidence;
- FFI assumptions and axioms remain visible;
- compiler correctness is a separate assurance dimension.

### Programming performance and proof correctness are separate but composable

The programming book demonstrates proofs that justify efficient array access,
termination, and equivalence.

PSC1 applies the same idea while keeping backends downstream of target-neutral
VerifiedIR.

A source theorem can prove an algorithmic relationship; separate compiler
assurance establishes that emitted targets preserve it.

## 5. Important Lean material intentionally not copied into PSC1

The study material is evidence, not a feature checklist.

PSC1 does not require first-freeze parity for:

- arbitrary syntax categories;
- macros and quotations;
- custom elaborators;
- custom tactic definitions;
- broad attribute systems;
- unrestricted coercion machinery;
- complete monad-transformer abstractions;
- every IO API;
- iterator syntax;
- full simplifier;
- `conv`;
- `grind`;
- `mvcgen`;
- broad classical/automation tactic libraries;
- full indexed dependent tactic elimination.

These may be future features or libraries, but copying them solely because Lean
documents them would violate PSC1's small-language policy.

## 6. Documentation architecture after this study

```text
PSC1 Lang/
  docs/                         audience-oriented entry points
  handbook/                     progressive general handbook
  programming-in-proofscript/   programming-first book
  theorem-proving-in-proofscript/ proof-first book
  language-manual/              lookup/reference manual
  reference/                    compact CLI/config/surface reference

  PSC1_LANGUAGE_REFERENCE.md    normative language profile
  SYNTAX_AND_GRAMMAR.md
  SEMANTICS_RUNTIME_AND_EFFECTS.md
  CONFORMANCE_PORTABILITY_AND_STATUS.md

  TYPESCRIPT_DOCS_HANDBOOK_STUDY.md
  LEAN_PROGRAMMING_THEOREM_REFERENCE_STUDY.md
```

This gives PSC1 the useful documentation separation seen in mature languages:

- onboarding;
- tutorial/handbook;
- programming book;
- theorem-proving book;
- detailed manual;
- normative specification;
- quick reference.

## 7. Maintenance rule

When Lean documentation describes a feature, PSC1 contributors should ask:

1. Does the self-host compiler or target language genuinely need it?
2. Can it be a library instead of syntax?
3. What is its kernel-facing semantic meaning?
4. Is it portable before backend lowering?
5. What is the trust impact?
6. Is there executable PSC1 evidence for claiming support?

Only after those questions are answered should the feature be promoted from
"studied Lean capability" to "PSC1 language capability."
