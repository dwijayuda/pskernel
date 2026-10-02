# PSC3 Design Philosophy

Status: **research draft**

## 1. Language mission

ProofScript PSC3 is designed as a serious general-purpose programming language whose theorem prover and formal-verification system are native parts of the language rather than a separate verification DSL.

The language should be credible for:
- application developers coming from TypeScript;
- library authors targeting the JavaScript ecosystem;
- Lean programmers and theorem-prover researchers;
- verification engineers;
- compiler and tooling authors;
- AI-assisted/specification-driven development.

The design deliberately accepts that these audiences need different levels of sophistication. Ordinary application code must remain approachable without forcing every developer to interact with dependent proofs.

## 2. A Go-like philosophy, not a Go clone

PSC3 takes the following lessons from Go-style language engineering:

- optimize for large programs and long-lived codebases;
- make dependencies explicit;
- make parsing and formatting regular;
- prefer orthogonal concepts to feature overlap;
- provide one canonical formatter;
- keep the default toolchain integrated and fast;
- make build behavior reproducible and inspectable;
- reject features whose interaction cost is larger than their local convenience;
- treat readability after six months as a design requirement.

PSC3 does **not** copy Go's type system, error style, concurrency model, or syntax merely for familiarity.

Dependent types, propositions, tactics, formal specifications and mathematical notation are justified when they serve PSC3's mission.

## 3. Design laws

### Law 1 — One semantic language

.ps, the supported .lean subset, and .psx lower into one semantic platform.

They are not allowed to become three subtly different languages that happen to share libraries.

### Law 2 — One ordinary function model

Functions are values. Multiple source conveniences may elaborate to function application, but the core language should not accumulate unrelated method/function/constructor invocation semantics.

### Law 3 — Nominal data, explicit dynamic boundaries

PSC3 structures and inductives have declared identity and logical meaning.

JavaScript object-shape compatibility is handled by codecs/bindings at the boundary. TypeScript-style structural assignability is not the foundation of PSC3's type system.

### Law 4 — Absence and failure are explicit

Portable PSC3 does not use implicit null/undefined absence or host exceptions as the meaning of ordinary recoverable failure.

Option and Result/Except-style types are standard.

Convenient source syntax may make them pleasant to use without hiding their semantics.

### Law 5 — Effects are visible

Pure code remains referentially transparent under PSC semantics.

Filesystem, network, clock, randomness, process access, external mutable state and other observable capabilities are explicit in the application/runtime model.

### Law 6 — Verification is evidence, not a mode bit

A declaration is not "verified" because it was compiled with a verification flag.

A verification claim identifies:
- the exact statement;
- implementation/dependencies it refers to;
- assumptions and axiom policy;
- checker/profile;
- proof/certificate status;
- compiler/runtime assurance status when relevant.

### Law 7 — Kernel smallness is not language simplicity

Keeping syntax, tactics and libraries outside the trusted kernel is good trust engineering.

But a complicated elaborator can still create a complicated language.

Every implicit search, coercion, notation and extension mechanism must also be judged for predictability and tooling cost.

### Law 8 — Native syntax is regular

PSC3 .ps should be easy to tokenize, parse, format and transform.

Whitespace should not normally change which invocation grammar owns an expression.

The .lean compatibility frontend retains Lean syntax where supported.

### Law 9 — Powerful automation remains non-authoritative

Simp, tactics, SMT, AI proof search, deriving and VC generation may be sophisticated.

They produce candidate declarations/evidence. The proof checker decides logical acceptance.

### Law 10 — Backends do not define source semantics

JavaScript engines, Wasm runtimes, bundlers, npm, browser event loops and host APIs are implementation/deployment mechanisms.

They do not define Nat, equality, errors, Task, modules, or proof meaning.

## 4. Simplicity budget

Every proposed PSC3 feature must answer:

1. What common task becomes materially better?
2. Could a library solve it?
3. Could source sugar solve it?
4. Does it introduce a new semantic concept?
5. What existing features does it interact with?
6. Can users predict the interaction?
7. Can tooling explain the compiler's decision?
8. Does it complicate JS/Wasm lowering?
9. Does it enlarge logical or execution trust?
10. Is there a simpler alternative?

A feature that is easy to implement but difficult to compose is not cheap.

## 5. Native application experience

PSC3 should make ordinary code look ordinary.

Application developers should be able to write:
- modules;
- functions;
- structures and tagged unions;
- pattern matching;
- collection operations;
- local mutation syntax where useful;
- typed errors;
- async tasks;
- HTTP/JSON/application code;
- tests;
- UI components;
- npm bindings;

without first learning theorem tactics.

Verification is progressively available:
- ordinary type checking;
- exhaustiveness/refinement;
- contracts;
- invariants;
- proof obligations;
- theorem proofs;
- compiler-preservation evidence.

## 6. Progressive precision

PSC3 should support progressively stronger guarantees on the same definitions.

Example conceptual progression:

~~~proofscript
function withdraw(balance: Nat, amount: Nat): Result Error Nat := ...
~~~

then:

~~~proofscript
function withdraw(balance: Nat, amount: Nat): Result Error Nat
  ensures result =>
    match result with {
      | .ok next => next <= balance
      | .error _ => true
    } :=
  ...
~~~

The second version adds an explicit guarantee. It does not silently change arithmetic, error handling or evaluation order.

## 7. Default explicitness

PSC3 can infer aggressively when the result is deterministic and explainable.

Good implicit behavior:
- ordinary local type inference;
- generic parameter inference;
- deterministic instance resolution;
- method notation that has one clear candidate.

Bad implicit behavior:
- JS truthiness;
- arbitrary conversion chains;
- environment-dependent ambiguous method selection;
- host exception conversion;
- silently trusted FFI;
- hidden weakening of specifications.

The compiler should provide an "explain" facility for every important implicit choice.

## 8. Compatibility philosophy

Compatibility has multiple dimensions:
- source syntax;
- elaborated meaning;
- theorem compatibility;
- runtime semantics;
- package/artifact formats;
- tooling APIs.

PSC3 must report them separately.

A .lean frontend can be source-compatible with a Lean subset while .ps has a deliberately different surface.

A JavaScript package can be API-compatible with TypeScript consumers without adopting TypeScript's structural type theory.

## 9. Explicit non-goals

PSC3 does not initially aim for:
- full TypeScript source compatibility;
- full JavaScript dynamic semantics;
- full Lean parser/macro/Meta compatibility in .ps;
- arbitrary grammar mutation;
- unrestricted decorators;
- prototype inheritance as native object semantics;
- native any;
- implicit null/undefined;
- implicit JS truthiness;
- Promise behavior as the definition of Task;
- host exceptions as the definition of Result;
- every backend supporting every feature immediately;
- theorem verification automatically implying compiler or deployment correctness.

## 10. What success means

PSC3 should be considered successful when:

- TypeScript developers can build real applications without fighting the language;
- Lean developers recognize the logical foundation and can reuse a useful source subset;
- verification does not require a separate programming model;
- proof tooling scales to nontrivial libraries;
- npm/JS interop is routine rather than an escape hatch;
- the compiler is fast enough for interactive development;
- the standard library is sufficiently complete for full applications;
- generated JS/Wasm has an explicit preservation story;
- language decisions remain explainable and stable.

The benchmark is not the length of the feature list.

The benchmark is whether complete programs remain understandable.
