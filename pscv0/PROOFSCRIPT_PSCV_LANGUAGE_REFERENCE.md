# ProofScript Language Reference — PSCV Verified Profile

**Status:** normative design release candidate PSCV-RC-v2; semantic/source mappings repinned to Lean 4.35.0-rc3; Standard/verification manifest regeneration and implementation conformance evidence pending  
**Language:** ProofScript  
**Base language edition:** `ps-0.9-r3`  
**Primary verified profile:** `pscv-v1`  
**Closed-assurance policy:** `pscv-closed-v1`  
**Explicit-boundary policy:** `pscv-boundary-v1`  
**Base compiler milestone:** PSC2 / `psc2-compiler-v1`  
**PSCV compiler target:** `pscv-compiler-v1`  
**Inherited Standard profile:** `psc2-standard-language-v1`  
**Default closed source profile:** `ps-standard-0.9-r3`  
**Lean compatibility profile:** `lean-subset-psc2-v1`  
**Semantic pin:** Lean 4.35.0-rc3, commit `470d5ce1400764999581fd26d5d72b00d990b0f4`  
**PSCV verification semantics:** `PSCV-VERIFY-v1`  
**PSCV executable-certificate policy:** `PSCV-CERT-v1`  
**Standard environment manifest:** `STD-ENV-PSCV-V1-L435RC3-RC1.json`  
**Standard environment manifest SHA-256:** **PENDING — release-blocking regeneration against Lean 4.35.0-rc3**

> **PSCV release-candidate note.** PSCV is a strict verified-programming profile layered on the existing ProofScript/Lean-grounded semantics. This reference specifies the intended PSCV source restrictions, verification obligations, specification-coverage rules, effect boundaries, and compile gate. It does **not** claim that the current PSC2 compiler already implements PSCV.

> **Semantic-pin rule.** Lean 4.35.0-rc3 at commit `470d5ce1400764999581fd26d5d72b00d990b0f4` is the normative Lean semantic/source pin for PSCV-RC-v2. Its intrinsic verification implementation is a pinned reference/lowering basis for adopted facilities such as `given`, `requires`, `ensures`, proof-only `assert`, loop `invariant`/`decreasing`, `vcgen`, and erased verification state. Upstream marks that source surface experimental; PSCV therefore freezes its own stable `PSCV-VERIFY-v1` meaning and does not inherit later upstream changes without a new PSCV profile revision.

> **Verified-build rule.** A source file may be parsed, elaborated, diagnosed, and have obligations generated while verification is incomplete. An artifact claiming `pscv-v1` verified-executable status MUST NOT be emitted until all mandatory obligations in its reachable executable closure are closed by accepted evidence and all PSCV policy gates succeed.

> **Specification-integrity rule.** Verification proves the formal proposition that was actually approved; it does not prove that prose, diagrams, or human intention were complete. PSCV therefore distinguishes **specification coverage** from **proof closure** and binds verified evidence to an immutable approved specification identity.

> **Naming rule.** ProofScript is the programming language. PSCV is the strict verified-programming profile. PSC2 remains the existing compiler-development milestone and inherited implementation/profile closure on which a future PSCV compiler may bootstrap.

This reference defines the PSCV verified profile while retaining the base ProofScript language rules that PSCV inherits. Unsupported or weaker constructs do not silently regain authority through Lean, JavaScript, TypeScript, Rust, AI tools, SMT solvers, macros, or runtime behavior.

Compiler architecture, package formats, `.ps.md` literate-spec authoring details, AI orchestration, backend translation validation, and deployment provenance may have companion specifications, but the **semantic conditions for a source declaration to qualify for PSCV verified executable compilation are normative here**.

## Reference design basis (informative)

PSCV deliberately combines ideas from several mature systems while keeping one Lean-grounded proof theory and one ProofScript executable semantics.

| Reference model | What PSCV borrows | What PSCV does **not** copy |
|---|---|---|
| Lean 4.35.0-rc3 | dependent type theory, inductives, total/well-founded recursion, theorem/proof terms, proof erasure, typeclasses, practical `do`, `given`/`requires`/`ensures`, proof-only `assert`, loop `invariant`/`decreasing`, erased verification state, `vcgen`, weakest-precondition/Hoare infrastructure, proof-producing automation | unrestricted source extensibility, arbitrary `unsafe`/`partial` executable code, raw IO as if it were mathematically transparent, or silent semantic drift when upstream experimental verification syntax changes |
| Dafny | routine pre/postconditions, call-site precondition VCs, assertions, loop invariants, decreasing measures, verification-before-release discipline | SMT success as final proof authority or a second foundational logic |
| SPARK | a practical-language subset chosen for verifiability, modular contracts, specification-before-body development, explicit verification boundaries | Ada-specific ownership/tasking/runtime rules |
| Verus | explicit distinction between specification/proof/executable relevance and ghost erasure | Rust ownership/borrowing semantics or SMT-specific specification restrictions |
| F* | effect-specific weakest-precondition reasoning and total-computation discipline | a second effect/type theory independent of ProofScript's Lean-grounded semantics |
| ECMAScript / Rust references | grammar discipline, explicit conformance, separation of language semantics from implementation/tooling | JavaScript dynamic semantics or Rust memory/ownership semantics |
| TypeScript documentation | approachable application-programming presentation | structural typing, `any`, declaration merging, overload semantics, or handbook prose as proof |

The PSCV design is therefore **subset + proof obligations + proof-producing automation + compile gating**, not a union of features from other languages.

## Table of contents

- 1. Introduction
- 2. Conformance and Profiles
- 3. Specification Conventions
- 4. Language and Semantic Model
- 5. Lexical Structure
- 6. Source Files and Modules
- 7. Names and Scope
- 8. Declarations
- 9. Binders and Functions
- 10. Terms and Expressions
- 11. Structures and Records
- 12. Classes and Instances
- 13. Inductive Types
- 14. Patterns
- 15. Pattern Matching
- 16. Type System
- 17. Equality and Reduction
- 18. Recursion and Computability
- 19. Propositions and Proofs
- 20. Standard Prover
- 21. Contracts and Verification
- 22. Elaboration and Static Semantics
- 23. Computational and Runtime Semantics
- 24. Standard Environment
- 25. Basic Propositions and Logical Basis
- 26. Basic Types
- 27. Standard Collections and Library Boundary
- 28. Lean Compatibility
- 29. Language Extensions
- 30. Program Validation and Verified Compilation
- 31. Conformance
- 32. PSCV Verified Profile
- Appendix A — Complete grammar closure and owned grammar
- Appendix B — Separator rules
- Appendix C — Feature/profile registry
- Appendix D — Canonical examples
- Appendix E — Rejection index
- Appendix F — PSCV exclusions and boundaries
- Appendix G — Feature ownership matrix
- Appendix H — Glossary and terminology notes
- Appendix I — Lean 4.35.0-rc3 exact semantic/source mapping table
- Appendix J — Rule-to-conformance-test matrix
- Appendix K — Standard environment source manifest
- Appendix L — Lean 4 feature suitability for PSCV
- Appendix M — PSCV research basis and design rationale

## 1. Introduction

### 1.1 Purpose

The **ProofScript Language Reference — PSCV Verified Profile** defines the strict verified-programming profile named `pscv-v1`.

PSCV's purpose is to make executable software behave like a mathematical development without requiring every programmer to manually write low-level proof terms. Definitions construct programs; types and specifications state admissible behavior; verification conditions expose what remains to prove; tactics/solvers/AI may construct candidate evidence; the pinned proof-checking foundation decides whether that evidence is valid.

The defining product property is:

> **A verified PSCV build does not emit executable artifacts while mandatory proof, specification-coverage, effect, assumption, or erasure obligations remain unresolved.**

This is a reference, not a tutorial.

### 1.2 Relationship to ProofScript and PSC2

ProofScript remains the programming language.

`ps-0.9-r3` remains the inherited base surface edition. PSCV-RC-v2 independently repins every Lean-derived semantic/source mapping it uses to Lean 4.35.0-rc3 at commit `470d5ce1400764999581fd26d5d72b00d990b0f4`; this does not retroactively redefine historical non-PSCV `ps-0.9-r3` artifacts.

`psc2-compiler-v1` is the current compiler milestone.

`pscv-v1` is a **stricter profile** intended for a later `pscv-compiler-v1` capability target. PSCV inherits base constructs when they satisfy PSCV policy and rejects or restricts base constructs that prevent verified executable reasoning.

Conceptually:

~~~text
Lean 4.35.0-rc3 semantic foundation
        |
        v
ProofScript ps-0.9-r3
        |
        +---- psc2-standard-language-v1
        |
        v
PSCV pscv-v1
  + proof closure
  + specification coverage
  + verified effects
  + compile gating
  - partial executable closure
  - unsafe executable closure
  - undeclared assumptions
~~~

### 1.3 Scope

This document specifies:

- the inherited ProofScript syntax/semantics used by PSCV;
- PSCV source restrictions;
- PSCV contract and verification semantics;
- totality/termination rules;
- practical verified `do` constructs;
- proof/ghost/runtime relevance;
- specification coverage and approved-spec linkage;
- closed versus explicit-boundary assurance;
- mandatory verification conditions;
- the verified-executable compile gate;
- PSCV conformance obligations.

It deliberately does **not** claim that all software requirements can be formalized as propositions. Performance, external service behavior, UI qualities, deployment properties, and other non-logical requirements may require tests, benchmarks, runtime monitors, or explicit assumptions. They are not mislabeled as proofs.

### 1.4 Design boundary

PSCV follows five design laws.

1. **One logic.** Specifications, proofs, refined data, contracts, and executable definitions reduce to the same Lean-grounded logical foundation; PSCV introduces no second foundational proof logic.
2. **Total verified core.** Executable code that participates in PSCV verified status is total under the admitted recursion/effect semantics.
3. **Proof-producing automation.** Tactics, VC generators, SMT integrations, AI agents, and plugins may generate candidate evidence but have no independent proof authority.
4. **Explicit world boundary.** Raw IO, FFI, databases, networks, threads, foreign runtimes, and other externally controlled behavior are never silently promoted to mathematical truth.
5. **Maximum generation freedom, minimum acceptance freedom.** Humans or AI may generate arbitrary candidates within the source profile; only approved specifications plus deterministic checking determine verified acceptance.

### 1.5 Normative words

- **MUST / MUST NOT** — required behavior for the profile named by the surrounding rule.
- **SHOULD / SHOULD NOT** — recommended behavior that must not change program meaning.
- **MAY** — permitted behavior.
- **reject** — source/profile acceptance fails.
- **verification failure** — the program may remain analyzable but cannot produce a PSCV verified executable artifact.
- **unsupported** — outside the selected profile; no semantic fallback is permitted.
- **approved specification** — a formal specification identity accepted by the build policy; prose approval alone is not proof evidence.
- **proof closure** — every mandatory formal obligation has accepted proof evidence.
- **specification coverage** — every declaration/requirement required by policy is linked to an approved formal specification or explicit non-proof evidence class.

### 1.6 Companion specifications and manuals

This reference owns PSCV source/profile semantics and the semantic conditions for verified compilation. Companion documents may own concrete artifact encodings and tools:

| Companion document | Owns |
|---|---|
| **ProofScript Verified Spec-Driven Development** | RequirementIR, `.ps.md` authoring conventions, SpecCapsule workflows, AI/human approval workflows |
| **ProofScript Compiler Reference** | CLI syntax, config-file spelling, diagnostics, user-visible commands |
| **ProofScript Compiler Architecture** | internal AST/IR, `VerifiedExecutableModule`, pass implementation, bootstrap engineering |
| **PSKernel Reference** | trusted proof checking, admission, replay semantics |
| **ProofScript Package and Build Reference** | package identity, dependency locking, workspace/build reproducibility |
| **ProofScript Backend References** | target-specific code generation and translation-validation contracts |
| **ProofScript Tooling Reference** | LSP, formatter, editor proof-state and requirement/evidence UI |
| **ProofScript JavaScript/Interop References** | npm/ESM, InterfaceIR, `.d.ts`, Node/Web, FFI adapters |
| **ProofScript Programming Guide** | tutorials and task-oriented guidance |

Concrete `.ps.md`, JSON evidence, or provenance formats MAY evolve independently provided the formal claims ultimately referenced by a PSCV build have canonical identities and the semantics below are preserved.

### 1.7 PSCV objective

PSCV is successful when normal application code can look like practical functional/imperative programming while its accepted executable meaning is accompanied by machine-checkable evidence.

The intended user-facing spectrum is:

~~~text
data invariants      -> types / structures / subtypes
function behavior    -> requires / ensures
local facts          -> assert
loop correctness     -> invariant
termination          -> structural / termination_by / decreasing
effectful behavior   -> weakest-precondition specifications
module/API laws      -> theorems / external approved specifications
foreign behavior     -> explicit boundary assumptions/evidence
~~~

PSCV does **not** require a bespoke user-written theorem after every private helper. It requires sufficient approved specification and proof coverage for the reachable executable artifact under the selected policy.

## 2. Conformance and Profiles

A conforming implementation MUST identify the ProofScript edition, source profile, verification profile, Standard environment identity, and assurance policy under which a program is accepted.

Unsupported input MUST fail closed. A tool MUST NOT silently weaken `pscv-v1` into ordinary ProofScript, unrestricted Lean, JavaScript/TypeScript semantics, runtime assertions, or test-only evidence.

### 2.1 Profile taxonomy

| Identity | Role |
|---|---|
| `ps-0.9-r3` | base ProofScript language edition |
| `ps-standard-0.9-r3` | closed base Standard source profile |
| `ps-lean-extensible-0.9-r3` | explicitly extensible non-PSCV profile |
| `psc2-language-v1` | inherited PSC2 compiler feature closure |
| `psc2-standard-language-v1` | inherited closed Standard language-facing closure |
| `lean-subset-psc2-v1` | bounded Lean-source compatibility profile |
| `psc2-pattern-v1` | inherited bounded pattern profile |
| `pscv-v1` | strict verified programming source/semantic profile |
| `PSCV-VERIFY-v1` | contract/VC/WP verification semantics |
| `PSCV-CERT-v1` | executable certificate and compile-gating policy |
| `pscv-closed-v1` | no user/foreign assumptions in verified closure beyond the pinned logical foundation |
| `pscv-boundary-v1` | explicit, auditable foreign assumptions/boundary models are permitted |

### 2.2 Base profiles

The inherited base profile identities retain the meanings defined by the ProofScript r3 language edition. PSCV does not retroactively change ordinary `ps-standard-0.9-r3` source.

The important relationship is:

~~~text
pscv-v1
=
  inherited closed ProofScript Standard semantics
+ PSCV verification syntax and semantics
+ PSCV practical total-programming syntax
+ PSCV specification-coverage policy
+ PSCV verified-effect discipline
+ PSCV executable certificate
- `partial` from verified source
- user `axiom` from verified source
- `unsafe`
- unverified contracts as executable authority
- unrestricted source extensions
~~~

### 2.3 `pscv-v1` closed grammar

[pscv.profile.closed-grammar]

`pscv-v1` is closed and reproducible.

Ordinary dependencies MUST NOT silently add or replace:

- syntax categories;
- notation;
- macros;
- term/command elaborators;
- tactic syntax/elaborators;
- deriving handlers;
- parser extensions;
- attribute handlers;
- VC rules;
- specification-lemma registries;
- proof-oracle shortcuts.

A PSCV distribution MAY provide official proof-producing plugins, but their identities are part of the verification environment and their output remains kernel checked.

### 2.4 PSCV feature closure

[pscv.profile.feature-closure]

A conforming `pscv-v1` implementation MUST support or explicitly implement the following profile decisions.

| Feature family | PSCV requirement |
|---|---|
| modules/imports/namespaces/scopes | MUST support |
| dependent `Prop`/`Type`/`Sort`/Pi/Eq | MUST support |
| structures, inductives, indexed inductives | MUST support |
| `Subtype`, `Fin`, proof fields | MUST support |
| classes/instances/coercions | MUST support under closed deterministic environment |
| total `def` / `function` / `const` | MUST support |
| theorem/proof terms | MUST support |
| `abbrev` | MUST support |
| `opaque` | MUST support, subject to specification policy |
| `partial` | MUST reject in PSCV source |
| `unsafe` | MUST reject |
| user `axiom` | MUST reject in `pscv-closed-v1`; boundary assumptions use the explicit boundary mechanism |
| `noncomputable` | MAY occur in specification/proof closure; MUST NOT occur in reachable executable closure |
| structural recursion | MUST support |
| well-founded/measure recursion | MUST support through the PSCV total-recursion subset |
| unrestricted partial/fixpoint recursion | MUST reject unless a separately named non-PSCV profile owns it |
| pure `requires` / `ensures` | MUST support and MUST be verifiable |
| effectful `requires` / `ensures` | MUST support for verified effect families with a registered PSCV WP semantics |
| call-site precondition VCs | MUST generate |
| verified postcondition use after calls | MUST support |
| proof-only `assert` | MUST support |
| loop `invariant` | MUST support |
| loop/function `decreasing` / termination evidence | MUST support |
| proof-only/ghost state | MUST support with noninterference/erasure checks |
| local `let mut` / assignment | MUST support in the verified `do` subset |
| `for` / `while` / `break` / `continue` / early `return` | MUST support in the verified `do` subset with VC semantics |
| raw `IO` | MUST NOT count as closed verified computation |
| raw mutable references/aliasing | MUST NOT enter PSCV closed verified semantics without a separately verified capability/effect model |
| FFI/extern | only through explicit boundary policy and model |
| arbitrary Lean syntax/macros/Meta | MUST reject in PSCV Standard source |
| arbitrary native-evaluation proof axioms | MUST reject under `pscv-closed-v1` |
| open mandatory proof obligation | MUST block PSCV executable emission |
| missing mandatory specification coverage | MUST block PSCV executable emission |
| prohibited axiom/effect dependency | MUST block PSCV executable emission |

### 2.5 Assurance policies

#### `pscv-closed-v1`

[pscv.policy.closed]

A closed PSCV build permits only the pinned logical foundation and dependencies whose verified PSCV certificates satisfy this same closed policy.

No user axiom, unmodeled external function, raw IO behavior, unchecked native proof axiom, or foreign semantic assumption may appear in the transitive verified closure.

#### `pscv-boundary-v1`

[pscv.policy.boundary]

A boundary PSCV build may depend on explicitly declared external assumptions or adapters.

Each such boundary MUST:

- have a stable identity;
- state the logical model relied upon;
- state whether the relation to runtime behavior is proved, translation-validated, tested, monitored, or merely assumed;
- appear in the generated assurance evidence;
- never be presented as kernel proof of the external world's behavior.

### 2.6 Specification coverage policy

[pscv.spec.coverage]

Proof closure and specification coverage are independent.

A verified PSCV build MUST satisfy its declared coverage policy.

At minimum:

- every exported executable declaration MUST be associated with an approved formal specification;
- the association MAY be by an inline contract, an approved external specification, or an explicitly approved **type-as-specification** declaration;
- a private helper MAY be covered transitively by verified public roots, but still MUST satisfy PSCV totality/effect/axiom rules;
- every requirement marked **critical + proof-required** by the approved specification MUST have at least one linked formal claim with accepted proof evidence;
- lack of a specification is not equivalent to a trivially true specification.

A conforming assurance report MUST expose both:

~~~text
specification coverage
proof closure
~~~

### 2.7 Profile non-conversion

[pscv.profile.no-downgrade]

Source or artifacts claiming `pscv-v1` MUST NOT be silently interpreted or emitted under a weaker profile.

A deliberate downgrade to ordinary ProofScript is an explicit different build/product identity and loses PSCV verified status.

### 2.8 Feature/profile registry authority

Appendix C is the authoritative feature/profile registry. Section 32 is the authoritative integrated PSCV profile summary. In case a base-rule description and a PSCV-specific rule differ, the PSCV-specific rule governs only when `pscv-v1` is active.

## 3. Specification Conventions

### 3.1 Grammar notation

Grammar fragments use EBNF-like notation. Quoted text denotes literal source tokens. `?` denotes optional material, `*` zero or more repetitions, and `+` one or more repetitions.

A grammar nonterminal is normative only when it is:

1. defined directly by this reference, or
2. resolved by an exact mapping in Appendix I.

Undefined placeholders are not a complete grammar.

### 3.1.1 Grammar authority

[grammar.authority]

Normative ProofScript grammar productions are defined only in Appendix A and, for `StandardTactic`, Chapter 20.2.

Other chapters may show source examples and prose summaries, but MUST NOT redefine an owned grammar nonterminal. Appendix I may identify external pinned parser categories used by Appendix A; it does not independently add Standard grammar.

### 3.2 Normative semantic pin

[semantic.pin]

The semantic authority inherited by `ps-0.9-r3` is Lean 4.35.0-rc3 at commit:

~~~text
470d5ce1400764999581fd26d5d72b00d990b0f4
~~~

ProofScript inherits only the semantic/source families explicitly enumerated by Appendix I. A Lean feature is not part of ProofScript merely because it exists in that Lean release.

### 3.3 Mapping IDs

Each inherited family has a stable mapping ID of the form `LEAN-*`. A mapping identifies:

- the ProofScript feature;
- the admitted Lean 4.35.0-rc3 family;
- whether the mapping is semantic-only, source-compatible, or library-facing;
- ProofScript restrictions.

Normative text MUST use a mapping ID rather than the unqualified phrases “selected native” or “selected Lean-compatible”.

### 3.4 Rule IDs

Normative requirements that need conformance coverage use stable rule IDs in brackets, for example:

~~~text
[profile.standard.closed-grammar]
[lex.call-gap.newline]
[type.pi.form]
[defeq.beta]
[elab.implicit.insert]
[contract.obligation]
~~~

Rule IDs are stable across editorial renumbering. Appendix J maps rule IDs to conformance cases.

### 3.5 Core judgments

This reference uses the following schematic judgments:

~~~text
Γ ⊢ t : A
~~~

`t` has type `A` in local context `Γ`.

~~~text
Γ ⊢ A : Sort u
~~~

`A` is a well-formed type/proposition at universe level `u`.

~~~text
Γ ⊢ t ≡ u : A
~~~

`t` and `u` are definitionally equal at type `A`.

Surface elaboration is written schematically as:

~~~text
Γ ; E ⊢ s ⇝ t : A
~~~

where source `s`, under elaboration environment `E`, elaborates to core term `t` of type `A`.

### 3.6 Owned syntax

An **owned syntax** production is a ProofScript production whose source spelling or surface interpretation is defined directly here. Owned syntax may elaborate to a pinned Lean semantic family without importing unrelated Lean grammar.


### 3.7 Comma policy

[grammar.comma-policy-global]

ProofScript does not assign a universal meaning to `,`.

A comma separates items only in productions explicitly declared comma-oriented.

For every comma-oriented Standard production:

- commas between adjacent items are mandatory;
- one trailing comma after the final item is optional;
- the trailing comma contributes no value, field, argument, or semantic effect.

Structure/class/instance/local-`where` declaration sequences are not comma-oriented.

### 3.8 Normative versus informative material

Unless explicitly marked informative, rules in Chapters 1–31 and Appendices A–K are normative for the profiles to which they apply.

Future language proposals do not belong in this normative reference. A future feature becomes ProofScript only after adoption by a separately versioned language/profile specification.


## 4. Language and Semantic Model

ProofScript is a Lean-compatible dependent programming and theorem-proving language with a smaller application-oriented surface. The `psc2-language-v1` profile names the ProofScript feature closure required by the current PSC2 compiler milestone.

### 4.1 Core semantic term families

[core.term.forms]

For admitted source constructs, elaboration produces terms in the following semantic families:

- universes/sorts;
- constants with universe instantiation;
- dependent function/Pi types;
- lambdas;
- function application;
- `let` expressions;
- literals admitted by the active profile;
- inductive type constructors and data constructors;
- recursor/eliminator applications generated by admitted pattern matching;
- supported structure projections;
- proof terms.

Metavariables and elaborator-local variables are elaboration machinery, not source-level semantic constructors.

### 4.2 Contexts and environments

[type.context]

A local context `Γ` is an ordered sequence of typed local declarations. Later declarations may depend on earlier declarations.

A global environment `E` contains admitted constants, definitions, opaque declarations, inductive declarations, constructors, recursors, structure projections, theorem declarations, universe parameters, and profile-visible registrations.

A term is meaningful only when its typing derivation is valid in the active environment and profile.

### 4.3 Sorts and universes

[type.sort]

Universe levels are generated from:

~~~text
0
succ u
max u v
imax u v
universe parameter
~~~

Elaboration may additionally use universe metavariables internally; unresolved universe metavariables required for an accepted declaration MUST be solved or rejected.

The semantic pin uses the Lean 4.35.0-rc3 universe rules:

~~~text
Γ ⊢ Sort u : Sort (succ u)
~~~

`Prop` abbreviates `Sort 0`.

`Type u` abbreviates `Sort (succ u)`.

`Type` abbreviates `Type 0`.

### 4.4 Dependent function/Pi formation

[type.pi.form]

If:

~~~text
Γ ⊢ A : Sort u
Γ, x : A ⊢ B : Sort v
~~~

then:

~~~text
Γ ⊢ (x : A) -> B : Sort (imax u v)
~~~

subject to the pinned Lean 4.35.0-rc3 universe rules.

A non-dependent function `A -> B` is a Pi type in which `B` does not depend on the bound variable.

Binder visibility (`explicit`, `implicit`, `strict implicit`, `instance implicit`) affects elaboration/application, not the core Pi typing rule.

### 4.5 Lambda typing

[type.lambda]

If:

~~~text
Γ, x : A ⊢ t : B
Γ ⊢ A : Sort u
~~~

then:

~~~text
Γ ⊢ (fun x => t) : (x : A) -> B
~~~

The source binder family is restricted by the active ProofScript profile.

### 4.6 Application typing

[type.app]

If:

~~~text
Γ ⊢ f : (x : A) -> B
Γ ⊢ a : A
~~~

then:

~~~text
Γ ⊢ f a : B[x := a]
~~~

Multiple source arguments elaborate to nested unary applications.

### 4.7 Let typing

[type.let]

If:

~~~text
Γ ⊢ A : Sort u
Γ ⊢ v : A
Γ, x : A ⊢ body : B
~~~

then the admitted `let` term has the type obtained from `B` after substituting `v` for `x` according to the pinned Lean semantics.

### 4.8 Constants and universe instantiation

[type.const]

A reference to a global constant is well-typed only if:

- the name resolves deterministically;
- the number of supplied/inferred universe arguments matches the declaration;
- the declaration is visible under the active module/profile rules.

Universe instantiation is capture-avoiding and follows `LEAN-CORE-UNIVERSE-INST`.

### 4.9 Inductive families and constructors

[type.inductive]

Inductive declarations admitted by `ps-0.9-r3` use mapping `LEAN-CORE-IND`.

Normatively required properties include:

- well-formed parameter and index telescopes;
- constructor result types target the declared inductive family;
- strict positivity according to the pinned Lean 4.35.0-rc3 rule;
- generated constructors have the declared dependent function types;
- elimination/recursion used by admitted `match` forms is the corresponding pinned recursor/eliminator semantics.

ProofScript does not thereby admit every Lean equation-compiler or dependent-motive surface form.

### 4.10 Projections

[type.projection]

A structure projection is well-typed only for a structure family and field admitted by the active profile. Its result type is the field type after substituting the structure parameters and prior dependent fields as required by the structure declaration.

### 4.11 Equality, quotients, and proof irrelevance

[type.eq]

Propositional equality is the pinned Lean equality family mapped by `LEAN-CORE-EQ`.

[type.quot]

Quotient semantics are inherited only through `LEAN-CORE-QUOT`; ProofScript adds no independent quotient theory.

[type.proof-irrelevance]

Proof irrelevance follows the pinned Lean 4.35.0-rc3 theory: proofs of the same proposition are definitionally irrelevant for the purposes specified by that theory.

### 4.12 Conversion

[type.convert]

If:

~~~text
Γ ⊢ t : A
Γ ⊢ A ≡ B
Γ ⊢ B : Sort u
~~~

then `t` may be used where type `B` is required.

The definitional-equality relation used by conversion is specified in Chapter 17.

### 4.13 Semantic preservation boundary

[semantic.no-host-redefinition]

JavaScript, TypeScript, Rust, backend representation choices, or foreign runtime behavior MUST NOT redefine ProofScript typing, proof validity, definitional equality, or the core semantic families above.

Unsupported source rejects rather than silently acquiring host-language semantics.

### 4.14 Lean metatheoretic compatibility and proof trust

[metatheory.lean-defeq]

For the pinned Lean 4.35.0-rc3 core theory used by PSCV:

- definitional equality is reflexive and symmetric but is not assumed transitive by the kernel algorithm;
- alpha-renaming of bound variables is respected;
- beta/delta/iota/zeta/quotient reduction, function eta, supported single-constructor structure eta, and proof irrelevance participate as specified in Chapter 17;
- explicit/implicit/strict-implicit/instance binder information guides elaboration but does not create a second core typing theory.

Independent implementations MUST reproduce the pinned kernel acceptance relation rather than replace it with a conventional equivalence relation that merely looks similar.

[trust.proof-term]

A theorem is valid only when its final elaborated proof term is accepted by the pinned proof-checking foundation in the active global environment. Tactics, simplifiers, `omega`, `grind`, compiler optimizations, and code generators have no independent proof authority.

[trust.environment]

Proof trust is relative to the accepted global environment. Explicit `axiom` declarations and imported axioms remain logical assumptions; opaque declarations remain trusted only to the extent that their declaration was accepted by the kernel/checker.

[trust.no-proof-holes]

Standard ProofScript forbids unresolved proof holes in accepted theorem or verified-contract evidence. `sorry`, `admit`, synthetic unsolved metavariables, or equivalent admitted-hole mechanisms are not Standard proof evidence. A temporary `?_` introduced by `refine` is elaboration syntax only and MUST be solved before theorem acceptance.


## 5. Lexical Structure

### 5.1 Source encoding

[lex.encoding]

A Standard ProofScript source file is a byte sequence decoded as **UTF-8**.

Rules:

1. ill-formed UTF-8 rejects before tokenization;
2. one leading UTF-8 BOM (`EF BB BF`) is permitted and ignored;
3. no Unicode normalization is performed; identifiers that differ by Unicode code-point sequence remain distinct unless the pinned identifier grammar says otherwise;
4. source offsets used by diagnostics are byte offsets into the original UTF-8 file plus implementation-provided line/column information.

### 5.2 Line terminators

[lex.line-endings]

Before lexical grammar is applied:

- `CR LF` is normalized to one logical `LF`;
- `LF` is one logical line terminator;
- a lone `CR` outside a string/comment rejects in Standard source.

All grammar references to a *physical line terminator* mean the normalized logical `LF` above.

### 5.3 Horizontal whitespace and indentation

[lex.indentation]

Outside string/character literals and comments, Standard structural whitespace consists of:

- ASCII SPACE `U+0020`;
- normalized line terminator `LF`.

Horizontal TAB `U+0009` outside literals/comments rejects in `ps-standard-0.9-r3`. This makes indentation columns byte- and editor-independent.

Indentation depth is therefore the count of consecutive ASCII spaces from the immediately preceding logical line terminator to the first non-trivia token.

The bounded Lean compatibility frontend MAY accept additional whitespace accepted by the pinned Lean scanner, but Standard ProofScript uses the rule above.

### 5.4 Identifiers and literals

ProofScript identifiers and literal tokens are defined by mappings `LEAN-LEX-IDENT`, `LEAN-LEX-NAT`, `LEAN-LEX-SCIENTIFIC`, `LEAN-LEX-STRING`, and `LEAN-LEX-CHAR` in Appendix I, restricted by Appendix A.

Example:

~~~proofscript
const count: Nat := 42
const ratio: Float := 1.25
const name: String := "Alice"
const enabled: Bool := true
~~~

Literal meaning is determined by the elaborated target type, Appendix-I literal mappings, and the exact Standard registry snapshot.

### 5.5 Comments

[lex.comments]

ProofScript comments are the pinned Lean line/block forms mapped by `LEAN-LEX-COMMENT` and `LEAN-LEX-COMMENT-BLOCK`.

~~~proofscript
-- line comment

/- nested /- block -/ comment -/
~~~

Block comments may nest. Comments are ordinary trivia except where adjacency/layout rules inspect whether their decoded text contains a normalized line terminator. A block comment containing `LF` is line-breaking for native-application layout.

### 5.6 Lexical input elements and no automatic semicolon insertion

[lex.input-elements]

The lexical layer recognizes identifiers, literals, punctuators, comments, ASCII-space trivia, and logical line terminators. Trivia is ignored between ordinary syntactic tokens, but token source spans remain available to the parser for the explicit parenthesized-call adjacency rule. Logical line terminators remain observable to layout-sensitive productions.

[lex.no-asi]

ProofScript does not perform JavaScript automatic semicolon insertion. A newline never synthesizes a general statement terminator.

### 5.7 Parenthesized-call adjacency

[call.adjacency]

ProofScript-owned parenthesized call syntax is recognized only when the opening `(` is **immediately adjacent** to the final token of the callable expression.

Accepted as ProofScript parenthesized calls:

~~~proofscript
f(x)
add(1, 2)
obj.method(x)
~~~

Not ProofScript parenthesized calls:

~~~proofscript
f (x)
f/* comment */(x)
f
(x)
~~~

Any whitespace, comment, or line terminator between the callable and `(` prevents the ProofScript call suffix from being recognized.

This distinction is intentional because ProofScript also retains Lean-style whitespace application:

~~~proofscript
f (x)       -- Lean-style application to one parenthesized argument
f (x, y)    -- Lean-style application to one tuple argument
f(x, y)     -- ProofScript parenthesized call with two arguments
f((x, y))   -- ProofScript parenthesized call with one tuple argument
~~~

The adjacency test is lexical/source-position metadata, not a separate source token and not a whitespace grammar.

## 6. Source Files and Modules


### Modules and imports


#### Ordinary import

~~~proofscript
import Std.Data.List
import MyProject.Util
~~~

An ordinary `import M` makes `M`'s public declarations available to the current module.

It does **not** re-export `M` as part of the current module's public dependency surface.

Imports do not grant new Standard parser registrations.

#### public import

~~~proofscript
public import Public.Core
public import Public.Data
~~~

`public import M` imports `M` and re-exports the public declarations reachable through `M`'s public-import closure.

Rules:

- ordinary top-level declarations are public unless marked `private`;
- `private` declarations are never exported or re-exported;
- ordinary `import` does not re-export;
- `public import` does re-export;
- `open` affects local name resolution only and never re-exports;
- re-export preserves declaration identity;
- ambiguous imported/re-exported names reject deterministically.

The current ProofScript edition does not require TypeScript/ECMAScript-style selective export lists, default exports, or namespace exports as core syntax.

A curated public API should use a facade module:

~~~proofscript
import Internal.BigModule

def selectedValue := Internal.BigModule.selectedValue
theorem selectedLaw := Internal.BigModule.selectedLaw
~~~

or intentionally public-import whole public modules:

~~~proofscript
public import Public.Core
public import Public.Data
~~~

#### Qualified names

~~~proofscript
Foo.Bar.value
Namespace.Type.constructor
~~~

#### One authoritative source per module

A logical module resolves to one authoritative source selected by the package/build layer before language-level module processing begins.

If both:

~~~text
Foo.ps
Foo.lean
~~~

could define the same module and no explicit selection exists, the build must reject ambiguity.

---



### 6.1 Import-graph well-formedness


[module.import-header]

`import` and `public import` are source-file header commands.

- they are admitted only at top-level;
- every import MUST precede the first non-import command;
- imports inside `namespace` or `section` reject;
- after the first non-import command, a later import rejects.

This rule mirrors the source-file-header discipline while retaining ProofScript's smaller module syntax.

[module.import-acyclic]

The logical module import graph MUST be acyclic. A cycle in ordinary or `public import` edges rejects before declarations from any module in that cycle become visible.

[module.import-dedup]

A logical module imported through more than one path is loaded once by declaration identity. Reaching the same public declaration through multiple import paths does not create duplicate declarations or duplicate initial semantic registrations.

[module.import-order]

Import commands are processed in source order for the deterministic environment/order rules that explicitly depend on import order. Source order does not change declaration identity or permit an ambiguous name to win.


[module.registration-propagation]

Each compiled module has two semantic-registration views:

- **active registrations** — used while elaborating that module;
- **exported registrations** — made available to modules that import it.

For a module `M`:

1. `M`'s active registrations begin with the Standard manifest snapshot;
2. every direct ordinary or public import contributes its **exported** registrations to `M`'s active environment, in `[instance.import-order]` module order;
3. registrations declared by `M` itself are then added in source declaration order as the file is elaborated;
4. `M`'s exported registrations contain:
   - registrations declared by `M` itself that are public/eligible for that registry;
   - registrations exported through `public import` edges;
5. registrations obtained only through an ordinary `import` are active in `M` but are not re-exported through `M`.

This rule applies to source-extensible Standard registries: instances, default instances, coercions, and `[simp]` theorems. `simproc`, `ext`, and `grind` registration surfaces are not Standard-source-extensible.

[module.registration-dedup]

A semantic registration has the declaration identity of its registering declaration plus its registry kind. Reaching the same exported registration through multiple public-import paths contributes it once. Different declarations that register equivalent propositions/types remain distinct registrations and retain deterministic order.

### 6.1A PSCV certified imports

[pscv.module.certified-import]

When a PSCV verified module imports another module and relies on its public verified specifications without re-elaborating/unfolding its implementation, the imported module evidence MUST be validated against:

- logical module/declaration identities;
- expected source/specification/environment digests;
- proof/admission identities;
- active assurance policy.

A self-asserted `verified=true` field or stale cache entry is not sufficient.

An imported ordinary ProofScript/non-PSCV module may be used only where the active boundary policy explicitly classifies it; it cannot silently contribute proved specifications to `pscv-closed-v1`.


### 6.2 Source kinds

`.ps` source uses a ProofScript source profile. `.lean` source is accepted only through an explicit bounded Lean compatibility profile. ProofScript syntax is not implicitly injected into `.lean` files. A future dialect such as `.psx` requires its own grammar/profile identity.


## 7. Names and Scope

This chapter defines source-visible name identity, lexical shadowing, namespace lookup, `open`, imports, and ambiguity. Package/file lookup is specified elsewhere; once a logical module has been selected, the rules below determine declaration lookup.

### 7.1 Declaration identities

[name.decl-identity]

A top-level declaration identity is the pair:

~~~text
(logical module identity, fully qualified declaration name)
~~~

Two declarations with the same identity in one accepted environment are an error unless an explicitly specified declaration form says otherwise. ProofScript Standard does not use JavaScript/TypeScript declaration merging.

### 7.2 Qualified names

[name.qualified]

A qualified source name such as `Foo.Bar.value` is resolved as that qualified declaration name after applying only the current module's namespace prefix rules required to interpret whether the spelling is absolute or namespace-relative. Once a fully qualified candidate is formed, `open` declarations do not rewrite it.

### 7.3 Local bindings

[name.local]

For an unqualified identifier, lexically local bindings are searched first. If more than one local binding with the same source spelling is in scope, the innermost binding shadows outer bindings.

Local bindings include function/lambda binders, `let` binders, pattern binders, section variables, proof hypotheses, and local `where` declarations.

### 7.4 Declaration lookup tiers

[name.lookup]

If an unqualified name is not a local binding, declaration lookup uses the following tiers in order. A later tier is considered only if the current tier produces no candidate.

1. **Current namespace candidate** — `Current.Namespace.name`.
2. **Enclosing namespace prefixes**, from innermost to outermost.
3. **Opened namespace candidates** from active `open` commands.
4. **Imported root/public candidates** whose final component matches the source name.

At any tier: zero candidates continues; exactly one selects it; more than one distinct declaration identity rejects as ambiguous. There is no last-import-wins or last-open-wins rule.

### 7.5 `open`

[name.open]

`open M` adds `M` to the opened-namespace candidate set for the lexical scope in which the command is active. It affects unqualified lookup only; it does not import, re-export, rename, or mutate Standard grammar.

### 7.6 Imports and re-exports

[name.import]

`import M` makes the public declarations of `M` available to the current module's imported declaration environment.

`public import M` additionally makes the public declarations reachable through `M`'s public-import closure part of the importing module's exported declaration surface.

`private` declarations never enter an exported/re-exported surface.

If two imported/re-exported declarations create the same unqualified candidate at the same lookup tier, lookup rejects unless qualification removes the ambiguity.

### 7.7 Namespace declarations

[name.namespace]

`namespace N ... end N` prefixes declarations created in its body with `N` and pushes `N` onto the namespace lookup stack for that lexical region. Nested namespaces compose by qualified-name concatenation.

### 7.8 Sections

[name.section]

A `section` changes the local declaration/elaboration context but creates no declaration-name prefix by itself.

Section-variable dependency follows locator `LEAN-SCOPE-SECTION` in Appendix I plus the explicit `include`/`omit` rules below.

### 7.9 `include` and `omit`

[name.include-omit]

`include x` forces the named section dependency to be considered for subsequent supported declarations where the pinned dependency algorithm admits it. `omit x` removes that forced inclusion. Neither changes the type theory or runtime semantics.

### 7.10 Ambiguity and failure

[name.ambiguous]

A conforming implementation MUST reject unresolved or ambiguous declaration lookup. It MUST NOT choose by installation order, filesystem enumeration order, package installation time, or JavaScript/TypeScript property lookup.

### 7.11 Examples

~~~proofscript
namespace A
const x : Nat := 1
end A

namespace B
const x : Nat := 2
end B

open A
const y : Nat := x
~~~

`y` resolves to `A.x` if no same-tier competitor is opened.

~~~proofscript
open A
open B
const z : Nat := x
~~~

rejects because both `A.x` and `B.x` are candidates at the opened-namespace tier.

## 8. Declarations


### def


A <code>def</code> is an ordinary definition mapped by `LEAN-DECL-DEF` in Appendix I.

Unbraced body:

~~~proofscript
def double(n: Nat): Nat :=
  n + n
~~~

Braced body:

~~~proofscript
def double(n: Nat): Nat := {
  n + n
}
~~~

Both are semantically identical.

---


### const


A <code>const</code> is a module/namespace-level parameterless definition alias.

Unbraced:

~~~proofscript
const answer: Nat := 42
~~~

Braced:

~~~proofscript
const answer: Nat := {
  42
}
~~~

It does not mean:

- JS/TS rebinding restriction;
- object freezing;
- runtime constant folding;
- module hoisting.

A <code>const</code> may hold a function value:

~~~proofscript
const increment: Nat -> Nat := {
  fun n => n + 1
}
~~~

---


### function


A <code>function</code> is a declaration-head alias for an ordinary function definition with ProofScript explicit-parameter syntax.

Unbraced:

~~~proofscript
function add(x: Nat, y: Nat): Nat :=
  x + y
~~~

Braced:

~~~proofscript
function add(x: Nat, y: Nat): Nat := {
  x + y
}
~~~

The core function model remains curried/dependent.

---


### definition-body variants


Feature identity:

~~~text
D-DECL-BODY-BRACE-R3
~~~

Grammar:

**Normative grammar:** see Appendix A for `DefinitionBody`, `BracedDefinitionBody`.

Semantic identity:

~~~text
:= term
≡
:= { term }
~~~

[decl.function.body.single-term]

The braces are a single-term wrapper.

They do not add:

- statement sequencing;
- implicit return;
- JavaScript scope semantics;
- a second function model.

Valid:

~~~proofscript
function classify(x: Nat): Nat := {
  if (x == 0) {
    0
  } else {
    1
  }
}
~~~

Invalid as a declaration-body wrapper:

~~~proofscript
function invalid(): Nat := {
  1
  2
}
~~~

because two unrelated terms are not one <code>PSTerm</code>.

---


### record-literal ownership in declaration bodies


A direct record literal remains a complete term:

~~~proofscript
const user: User := {
  id := 1,
  name := "Alice"
}
~~~

This is not interpreted as a generic body block containing field statements.

If an explicit body wrapper around the record is desired:

~~~proofscript
const user: User := {
  {
    id := 1,
    name := "Alice"
  }
}
~~~

Both have the same resulting value meaning.

---


### theorem


~~~proofscript
theorem addZero(n: Nat): n + 0 = n := by {
  simp
}
~~~

A theorem is accepted only if its elaborated proof term is accepted by the pinned proof-checking foundation in Chapter 4 and Appendix I.

---


### example


~~~proofscript
example : 1 + 1 = 2 := by {
  rfl
}
~~~

An <code>example</code> checks a proposition/proof according to mapping `LEAN-DECL-EXAMPLE` in Appendix I and does not introduce a reusable named theorem.

---


### abbrev


~~~proofscript
abbrev UserId := Nat
~~~

An abbreviation follows `LEAN-DECL-ABBREV` and Chapter 17 transparency rules.

It is not only pretty-printer metadata.

---


### opaque


~~~proofscript
opaque hiddenValue: Nat := 42
~~~

Opacity follows `LEAN-DECL-OPAQUE` and Chapter 17 transparency rules.

It does not authorize an ill-typed definition.

---


[pscv.opaque.spec]

A public executable `opaque` declaration in PSCV MUST still satisfy specification coverage and proof closure in its defining verified module. Clients reason from its checked public specification rather than assuming an inaccessible body has arbitrary behavior.


### axiom

Base `ps-0.9-r3` defines `axiom` as an explicit trusted constant assumption.

PSCV changes the source policy.

[pscv.axiom.user-reject]

`pscv-closed-v1` MUST reject user-authored `axiom` declarations.

`pscv-boundary-v1` MUST also reject ordinary user `axiom` as the spelling for external runtime assumptions. Foreign assumptions belong to the explicit PSCV boundary/specification mechanism so they can be classified and audited separately from foundational logical axioms.

Imported theorem evidence is accepted only relative to its transitive axiom closure and the active PSCV assurance policy.

The pinned Lean foundational axioms remain part of the selected logical foundation and MUST be reported according to the PSKernel/assurance policy. They are not silently equated with user-provided axioms.

---

### partial

[pscv.partial.reject]

`partial` is outside `pscv-v1`.

A PSCV source module MUST reject a `partial` declaration rather than admitting it as a runtime-only helper.

Reason: a PSCV verified executable is required to have a total logical meaning for every reachable executable declaration. Lean's `partial` facility is useful in general programming but treats the resulting function as logically opaque and does not establish termination.

A package that requires unrestricted partial execution must place that code behind a separately identified non-PSCV/boundary component. Such a component cannot appear in `pscv-closed-v1`; in `pscv-boundary-v1` it is an explicit assumption/boundary and never inherits verified status.

---

### noncomputable

[pscv.noncomputable]

`noncomputable` remains useful for mathematical specification and proof.

Under `pscv-v1`:

- a noncomputable declaration MAY occur in the specification/proof dependency graph;
- it MUST satisfy ordinary typing/proof rules;
- it MUST NOT occur in the transitive runtime dependency closure of a `VerifiedExecutableModule`;
- proof-only reasoning may use classical/noncomputable constructions when allowed by the selected logical policy;
- runtime code generation MUST fail rather than fabricate an implementation for noncomputable data.

Thus PSCV separates **logical definability** from **executable realizability**.

---

### unsafe boundary

[pscv.unsafe.reject]

`unsafe` is excluded from `pscv-v1`.

A verified executable declaration MUST NOT transitively depend on an unsafe declaration.

Unsafe host/runtime functionality may be exposed only through a separately modeled boundary whose executable behavior is not granted proof authority. An unsafe implementation detail cannot be hidden behind a verified-looking PSCV declaration without an explicit boundary classification.

---

## 9. Binders and Functions


### explicit binders

[grammar.parameter-group-unified]

ProofScript uses one parenthesized explicit-parameter-group convention across ProofScript-owned declaration/constructor headers that admit explicit parameters:

~~~text
function f(x: A, y: B)
structure S(α: Type)
class C(α: Type)
inductive I(α: Type)
| ctor(value: α)
~~~

The exact admitted header for each declaration family is specified by its chapter/Appendix-A production, but every such explicit group reuses `ExplicitGroup` and therefore the same comma policy: commas between entries are mandatory and one trailing comma is optional.

ProofScript explicit parameter group:

~~~proofscript
function add(x: Nat, y: Nat): Nat := {
  x + y
}
~~~

Grammar:

**Normative grammar:** see Appendix A for `ExplicitGroup`, `ExplicitEntry`.

Trailing comma is allowed:

~~~proofscript
function add(
  x: Nat,
  y: Nat,
): Nat := {
  x + y
}
~~~

---


### implicit binders


~~~proofscript
function id {α: Type}(x: α): α := {
  x
}
~~~

Implicit binders use the insertion/elaboration algorithm `[elab.implicit.insert]` and mapping `LEAN-ELAB-IMPLICIT`.

---


### strict implicit binders


The current ProofScript edition includes strict implicit binders through mapping `LEAN-BINDER-STRICT` in Appendix I.

Canonical spelling:

~~~proofscript
function use {{α: Type}}(x: α): α := {
  x
}
~~~

The accepted strict-implicit delimiter is the Lean 4.35.0-rc3 strict-implicit form mapped by `LEAN-BINDER-STRICT` in Appendix I; `{{x : A}}` is the admitted ASCII spelling.

---


### instance binders


~~~proofscript
function sameValue {α: Type}[BEq α](x: α, y: α): Bool := {
  x == y
}
~~~

The instance argument may be synthesized only by the deterministic Standard instance algorithm in Chapter 22.

---


### default parameters


Grammar:

**Normative grammar:** see Appendix A for `DefaultSuffix`.

Example:

~~~proofscript
function greet(name: String := "world"): String := {
  "Hello, " ++ name
}
~~~

Defaults are elaboration/application semantics, not runtime overload dispatch.

---


### zero-source-argument functions


~~~proofscript
function zero(): Nat := {
  0
}
~~~

Conceptual lowering:

~~~text
function f(): R
≈
def f (_unit : Unit := ()) : R
~~~

Rules:

1. the empty explicit group is final;
2. native implicit/instance binders may precede it;
3. it cannot be followed by another explicit parameter group.

Rejected:

~~~proofscript
function bad()(x: Nat): Nat := x
function bad(x: Nat)(): Nat := x
~~~

---


### function-header grammar


**Normative grammar:** see Appendix A for `FunctionHeader`, `EmptyExplicitGroup`.

---


### lambdas


~~~proofscript
fun x => x + 1
~~~

Typed/dependent lambda forms follow mappings `LEAN-CORE-LAM` and `LEAN-BINDER-*` in Appendix I.

Example:

~~~proofscript
const idNat: Nat -> Nat := {
  fun x => x
}
~~~

TypeScript arrow syntax such as:

~~~text
x => x + 1
~~~

is not current base ProofScript syntax.

---


### function and Pi types


Simple function type:

~~~proofscript
Nat -> Nat
~~~

Dependent function type:

~~~proofscript
(n: Nat) -> Fin n -> Nat
~~~

The type of a later parameter/result may depend on an earlier value.

---


## 10. Terms and Expressions


### forall


Canonical proposition example:

~~~proofscript
forall x : Nat, x = x
~~~

Universal quantification is dependent-function formation over `Prop` as specified by `[type.pi.form]` and mapping `LEAN-TERM-FORALL`.

---


### exists


Canonical proposition example:

~~~proofscript
exists x : Nat, x = 0
~~~

Existence is a proposition, not merely a runtime search result.

---


### let


~~~proofscript
function plusOne(): Nat := {
  let x := 1
  x + 1
}
~~~

The complete <code>let ... body</code> form is one term.

A <code>let</code> binding does not imply mutable storage.

---


### parenthesized terms


~~~proofscript
(x)
(1 + 2)
~~~

Parentheses group a term according to the fixed precedence table in Chapter 24.2 and Appendix A.

---


### tuple/product terms

[tuple.comma-policy]

Tuple/product syntax is comma-oriented:

~~~proofscript
(1, 2)
("Alice", true)
(1, 2,)
~~~

Rules:

- a tuple/product term contains at least two elements;
- commas between tuple elements are mandatory;
- one trailing comma after the final element is optional;
- the trailing comma has no semantic effect and does not create an empty element.

Grammar:

**Normative grammar:** see Appendix A for `TupleTerm`.

One tuple passed as one parenthesized call argument requires another grouping layer:

~~~proofscript
tupled((1, 2))
~~~

---


### type ascription


~~~proofscript
(x : Nat)
(1 : Nat)
~~~

Type ascription participates in type checking/elaboration.

It is not an unchecked type assertion.

---


### parenthesized function calls


~~~proofscript
add(1, 2)
~~~

[call.parenthesized]

The opening parenthesis is token-adjacent to the callable as required by `[call.adjacency]`.

Whitespace before the parenthesis selects Lean-style application instead:

~~~proofscript
tupled (1, 2)
~~~

Here `(1, 2)` is one tuple argument. In contrast:

~~~proofscript
add(1, 2)
~~~

contains two ProofScript call arguments.

---


### call-argument grammar


**Normative grammar:** see Appendix A for `CallArguments`, `CallArgument`.

---


### named arguments


Grammar:

**Normative grammar:** see Appendix A for `NamedCallArgument`.

Example:

~~~proofscript
connect(
  host := "localhost",
  timeout := 5000,
)
~~~

Named arguments are application/elaboration semantics, not runtime object passing.

Within one parenthesized call, positional arguments precede named arguments; after the first named argument, all remaining arguments must be named. Exact semantics are `[call.named-order]` and `[call.named-target]`.

---


### call trailing comma


Accepted:

~~~proofscript
f(
  x,
  y,
)
~~~

The trailing comma adds no argument.

---


### empty calls


~~~proofscript
greet()
~~~

An empty call requests completion of omitted optional/automatic explicit parameters.

Accepted:

~~~proofscript
function greet(name: String := "world"): String := {
  name
}

greet()
~~~

Rejected:

~~~proofscript
function add1(x: Nat): Nat := {
  x + 1
}

add1()
~~~

because an ordinary required explicit argument remains.

---


### empty call versus explicit Unit


These are different:

~~~proofscript
f()
f(())
~~~

<code>f()</code> is empty-invocation/default completion.

<code>f(())</code> supplies an explicit <code>Unit</code> value as one argument.

---


### generalized field notation


~~~proofscript
users.map(toName)
value.method(arg)
~~~

Field/method notation is static/type-directed.

It is not JavaScript prototype lookup or arbitrary dynamic property dispatch.

---


### conditional expressions

ProofScript braced conditional:

~~~proofscript
if (condition) {
  thenTerm
} else {
  elseTerm
}
~~~

Grammar:

**Normative grammar:** see Appendix A for `BracedIf`.

[elab.if]

Conditional elaboration is deterministic:

1. elaborate `condition` without inserting an expected-type coercion solely to choose the conditional mode;
2. if its type is definitionally equal to `Bool`, elaborate a Boolean conditional using the pinned `Bool` eliminator/branch meaning: `true` selects the first branch and `false` the second;
3. otherwise, if its type is definitionally equal to `Prop`, synthesize `Decidable condition` using the Standard instance algorithm and elaborate the ordinary dependent-free Lean-compatible `ite` meaning;
4. otherwise reject;
5. elaborate both branches against the same expected type when one is available; otherwise elaborate the first branch, use its inferred type as the expected type of the second, and require the two resulting branch types to be definitionally equal.

[elab.if-no-truthiness]

No JavaScript/TypeScript truthiness conversion is performed. Numeric, string, object, option, and foreign values are not conditionals merely because a host language would treat them as truthy/falsy.

Each branch is exactly one term. The braces are not generic statement blocks.

---


### basic do notation

Base ProofScript retains the bounded braced `do` subset described by `LEAN-TERM-DO-BASIC`.

~~~proofscript
function load(): CompilerM Nat := do {
  let x ← readValue
  pure (x + 1)
}
~~~

Base forms are:

- term statement;
- simple `let`;
- identifier monadic bind;
- wildcard monadic bind;
- pure/return-style completion.

`do` remains monadic/effect sequencing, not a JavaScript statement block.

### PSCV verified `do`

[pscv.do.verified]

`pscv-v1` extends the base `do` surface with a closed set of practical imperative-looking forms whose meaning is still expressed through total monadic/state semantics and `PSCV-VERIFY-v1`.

Required PSCV forms include:

~~~text
let mut
assignment to local mutable variables
for
while
break
continue
early return
assert
ghost / ghost mut
invariant
decreasing
~~~

The exact PSCV-owned grammar is Appendix A.18.

These forms do not introduce shared JavaScript-style mutable object semantics.

#### Local mutable variables

~~~proofscript
do {
  let mut total := 0
  total := total + 1
  return total
}
~~~

[pscv.do.local-mutation]

A mutable local is local program state. Assignment is admitted only to an in-scope mutable local owned by the current `do` translation. PSCV v1 does not thereby introduce arbitrary aliased heap references.

Verification reasons about the corresponding state transformation.

#### Verified assertion

~~~proofscript
do {
  assert index <= xs.size
  ...
}
~~~

[pscv.assert]

`assert P` is verification-only:

1. `P` MUST elaborate to `Prop`;
2. PSCV generates an obligation proving `P` at that program point;
3. after that obligation is discharged, `P` is available to verification of subsequent code;
4. the assertion has no required runtime effect in a verified build;
5. optional runtime-check instrumentation belongs to tooling/testing and is not proof evidence.

#### Ghost state

~~~proofscript
do {
  ghost mut visited := []
  ...
}
~~~

[pscv.ghost]

A `ghost` binding is verification-only state.

Rules:

- ghost values MAY occur in specifications, invariants, assertions, and proofs;
- runtime-relevant values, branches, foreign calls, and returned executable data MUST NOT depend on ghost data after erasure;
- erasure/noninterference is a mandatory PSCV certificate obligation;
- a compiler unable to establish safe erasure MUST reject verified compilation.

`ghost` is PSCV-owned terminology. Implementations may bootstrap it using proof-erased or erased-state machinery, but its semantics are fixed by this reference rather than by a moving Lean experimental feature.

#### `for`

~~~proofscript
do {
  let mut total := 0
  for x in xs
    invariant total = prefixSum
  {
    total := total + x
  }
  return total
}
~~~

[pscv.loop.for]

A `for` loop over an admitted finite iterator is total only when the iterator's termination/cursor semantics are certified by the active verified library.

A loop that changes verification-relevant local state MUST have either:

- an explicit invariant; or
- a registered specification theorem whose application proves the equivalent initialization/preservation/exit obligations.

`break` and `continue` are included in the VC semantics; they do not bypass invariant preservation requirements.

#### `while`

~~~proofscript
do {
  let mut i := n
  while i > 0
    invariant 0 <= i
    decreasing i
  {
    i := i - 1
  }
  return i
}
~~~

[pscv.loop.while]

A `while` loop in verified executable code MUST establish:

1. invariant initialization;
2. invariant preservation for ordinary iteration;
3. invariant obligations for `continue`;
4. exit facts for normal condition failure and `break`;
5. a well-founded decreasing measure establishing termination.

A missing or unproved mandatory invariant/decreasing obligation blocks verified compilation.

#### Early return

[pscv.do.return]

Early `return` is part of the verified control-flow semantics. Every return path MUST establish the function's postcondition.

#### Effect restriction

[pscv.do.effect]

The surrounding monad/effect must be admitted by the verified-effect policy in Section 21 and Section 32. Merely having a Lean `Monad` instance is insufficient to grant PSCV verification semantics.

---

## 11. Structures and Records

### structures

[struct.body.braced-grouping]

ProofScript structure declarations preserve the Lean-like ordered field-declaration sequence and use braces only for grouping:

~~~proofscript
structure User where {
  id: Nat
  name: String
  active: Bool
}
~~~

Grammar:

**Normative grammar:** see Appendix A for `StructBody`.

`LeanStructFieldSequence` is the pinned `LEAN-LAYOUT-STRUCT-CLASS` structure-field sequence with only the explicit ProofScript outer braces added.

Rules:

- structure declaration fields are **not comma-separated**;
- multiple fields follow the pinned Lean structure-field layout;
- braces do not create statement semantics;
- field order remains declaration order;
- structure identity is logical/nominal, not TypeScript structural object identity.

This deliberately follows Lean's structure-field sequencing more closely than the previous comma-separated draft.

### PSCV structure invariants

[pscv.structure.invariant]

PSCV permits a structure to carry mathematical validity conditions through ordinary proof fields or through the PSCV-owned invariant sugar in Appendix A.18.

Conceptually:

~~~proofscript
structure Account where {
  balance : Int
}
invariant self => self.balance >= 0
~~~

lowers to an ordinary structure with an additional proof-only field whose type is the invariant proposition after substituting preceding fields.

Rules:

- the invariant MUST elaborate to `Prop` with the structure value binder in scope;
- elaboration is equivalent to adding a proof-only field for the invariant after the runtime fields;
- source record construction does not require the programmer to write that hidden field; instead it generates an invariant proof obligation and inserts the accepted proof term;
- every constructor/build/update path MUST provide or automatically prove the invariant;
- field update generates a fresh invariant obligation for the reconstructed value;
- the invariant proof is computationally irrelevant and subject to proof erasure;
- the hidden/synthesized proof field is not part of ordinary runtime field enumeration and cannot be used to smuggle runtime data;
- a public constructor that could bypass the invariant is not exported as an unchecked runtime construction path;
- ordinary explicit proof fields remain equivalent in expressive power.

This sugar exists because “valid values form a mathematical subset” is a recurring software pattern and `Subtype`/proof fields already have the required Lean-grounded semantics.


### record construction

[record.comma-policy]

Record/structure **values** are comma-oriented, matching Lean's structure-instance style:

~~~proofscript
const user: User := {
  id := 1,
  name := "Alice",
  active := true,
}
~~~

Grammar:

**Normative grammar:** see Appendix A for `RecordConstruction`, `RecordField`.

Rules:

- commas between multiple record fields are mandatory;
- one trailing comma is optional;
- the trailing comma has no semantic effect;
- field order does not change the declared structure identity.

Record construction elaborates to the corresponding admitted structure constructor under `LEAN-CORE-IND` and the declared structure field telescope.


[elab.record]

A `RecordConstruction` is accepted only when its target structure type is known from the expected type. Standard ProofScript does not guess a structure type solely from a set of field names.

Given target structure `S`:

1. resolve every source field name against `S`'s declared/inherited field telescope;
2. reject an unknown field;
3. reject a field supplied more than once;
4. elaborate supplied field values in declaration dependency order using the field's expected type after substituting earlier field values;
5. for an omitted field, use its declared default only when that field has an admitted declaration default; otherwise reject;
6. after all fields are assigned, elaborate the structure constructor application and require ordinary kernel typing.

Source field order does not alter the resulting structure value; dependency order is always the declared field order.

[elab.record-no-inhabited-fallback]

Standard record construction does not synthesize an omitted field merely from an `Inhabited` instance. Only an explicit declared field default may fill an omitted field.



### projections

~~~proofscript
const id: Nat := {
  user.id
}

const name: String := {
  user.name
}
~~~

Projection meaning comes from the declared structure.

### record update

[record-update.comma-policy]

Record update uses the same comma policy for multiple updated fields:

~~~proofscript
function activate(user: User): User := {
  { user with active := true }
}
~~~

and, when multiple fields are updated:

~~~proofscript
{ user with
  name := "Alice",
  active := true,
}
~~~

Conceptually:

**Normative grammar:** see Appendix A for `RecordUpdate`.

The final comma is optional and has no semantic effect.

Record update elaborates through the admitted structure constructor/projection semantics and preserves the declared structure type.


[elab.record-update]

For `{ base with f₁ := v₁, ... }`:

1. elaborate `base` and require its type to reduce to one admitted structure type `S`;
2. resolve every updated field against `S`;
3. reject unknown or duplicate updated fields;
4. process `S`'s fields in declaration order:
   - an updated field uses its supplied value;
   - an unchanged field uses the corresponding projection from `base`;
5. each chosen value is checked against the field type after substitution of the preceding reconstructed field values;
6. the reconstructed constructor application must type-check as `S`.

Thus updating a field on which later dependent fields rely is accepted only when the reconstructed later fields remain well-typed. There is no JavaScript object-spread or structural-object fallback.



It does not mean JavaScript object spread.


## 12. Classes and Instances

### classes

[class.body.braced-grouping]

Class declarations use the same Lean-like field-declaration sequencing as structures:

~~~proofscript
class Sized(α: Type) where {
  size: α -> Nat
}
~~~

Multiple class fields:

~~~proofscript
class Example(α: Type) where {
  first: α -> Nat
  second: α -> Bool
}
~~~

Grammar:

**Normative grammar:** see Appendix A for `ClassBody`.

`LeanClassFieldSequence` is the pinned `LEAN-LAYOUT-STRUCT-CLASS` class-field sequence with only the explicit ProofScript outer braces added.

Rules:

- class declaration fields are not comma-separated;
- multiple fields follow the pinned Lean class-field layout;
- braces are grouping only;
- `class` remains a type-directed/typeclass abstraction, not a JavaScript/TypeScript OO class.

### instances

[instance.body.braced-grouping]

ProofScript uses a finite owned instance-field grammar and braces as grouping:

~~~proofscript
instance : Sized String where {
  size(s: String): Nat := s.length
}
~~~

Each field has the class-field meaning defined by `[instance.fields]`. The braces do not create a statement block, and Standard does not admit semicolon-separated instance fields.

For multiple fields:

~~~proofscript
instance : Example String where {
  first(s: String): Nat := s.length
  second(s: String): Bool := s.length > 0
}
~~~

Conceptual body grammar:

**Normative grammar:** see Appendix A for `InstanceBody`.

Rules:

- the exact Standard grammar is `InstanceBody` / `InstanceFieldSequence` in Appendix A.12;
- a single field needs no separator;
- multiple fields are separated by normalized newlines at the current instance-body depth;
- semicolons are **not** Standard instance-field separators;
- commas are **not** instance-field separators;
- braces are grouping only, not runtime/block semantics;
- each `InstanceField` is checked against the declared class field telescope by `[instance.fields]`;
- native Lean `whereStructInst` spellings using `;` belong only to `lean-subset-psc2-v1` where explicitly enumerated.


[instance.fields]

The class type in the instance header determines the required instance-field telescope.

- unknown field names reject;
- duplicate field definitions reject;
- each supplied field is checked against its instantiated class-field type;
- omitted required fields reject unless the class declaration provides an admitted default implementation;
- field elaboration follows declaration dependency order, not source hash-map/order effects.

The completed instance value must type-check as the declared class application before it enters the instance registry.



---


### PSCV lawful abstractions

[pscv.class.laws]

PSCV encourages classes/structures whose public abstraction includes both executable operations and proposition-valued laws.

Conceptually:

~~~proofscript
class Codec(α: Type) where {
  encode: α -> ByteArray
  decode: ByteArray -> Except Error α
  roundTrip: forall x : α, decode(encode(x)) = .ok(x)
}
~~~

An instance of such a class must provide both the executable fields and proof evidence for the law fields.

Law fields:

- are ordinary proof fields in the Lean-grounded type theory;
- may be erased from runtime representation when computationally irrelevant;
- may be used by verification/specification lemmas of generic callers;
- are preferable to ad-hoc global assumptions for reusable abstractions.

The profile does not require every class to contain laws; specification coverage decides whether a public abstraction is sufficiently specified for the project.


### typeclass search


Given:

~~~proofscript
class Sized(α: Type) where {
  size: α -> Nat
}

instance : Sized String where {
  size(s: String): Nat := s.length
}
~~~

a function can request the class:

~~~proofscript
function sizeOf {α: Type}[Sized α](x: α): Nat := {
  Sized.size(x)
}
~~~

The instance may be synthesized only by the Chapter 22 Standard instance algorithm.

---


### coercions


The current ProofScript edition permits coercion insertion only through mapping `LEAN-ELAB-COERCION` in Appendix I.

Coercions are type-directed elaboration behavior.

They are not:

- JavaScript automatic conversions;
- TypeScript structural assignment;
- arbitrary runtime casts.

Ambiguous/unsupported coercion behavior rejects.

---


## 13. Inductive Types


### inductive types


~~~proofscript
inductive Result(ε: Type, α: Type) where {
  | ok(value: α)
  | error(error: ε)
}
~~~

Grammar:

**Normative grammar:** see Appendix A for `InductiveBody`.

The admitted inductive semantics include:

- constructor typing;
- positivity;
- parameters;
- indices;
- dependent elimination.

---


### constructors


Use constructors with a result type that determines all family parameters:

~~~proofscript
const okResult: Result String Nat := Result.ok(42)
const errorResult: Result String Nat := Result.error("failed")
~~~

[elab.constructor]

A qualified constructor application is elaborated against its declared constructor telescope. All family parameters/indices that are not supplied explicitly must be uniquely determined by supplied arguments, expected type, or deterministic unification; otherwise the application rejects with unresolved metavariables.

Shorthand constructor notation is admitted only when mapping `LEAN-ELAB-CTOR-SHORTHAND` can determine the constructor from the expected type:

~~~proofscript
const okResult: Result String Nat := .ok(42)
const errorResult: Result String Nat := .error("failed")
~~~

---


### indexed inductives


The current ProofScript edition preserves indexed/dependent inductive semantics through mapping `LEAN-CORE-IND` in Appendix I.

Canonical indexed-inductive example:

~~~proofscript
inductive Vec(α: Type): Nat -> Type where {
  | nil : Vec α 0
  | cons(n: Nat, value: α, tail: Vec α n) : Vec α (n + 1)
}
~~~

Only result-type forms admitted by `ps-0.9-r3` and `psc2-language-v1` are accepted.

---


## 14. Patterns


### Pattern profile


<code>psc2-pattern-v1</code> requires the following.

#### Variable pattern

~~~proofscript
| .some x => x
~~~

#### Wildcard pattern

~~~proofscript
| .error _ => fallback
~~~

#### Constructor pattern

~~~proofscript
| .some x => x
~~~

#### Nested constructor pattern

~~~proofscript
| .some (.ok x) => x
~~~

#### Tuple/product pattern

~~~proofscript
| (x, y) => x + y
~~~

where the containing native pattern category accepts that form.

#### Supported literal pattern

Example:

~~~proofscript
| 0 => base
~~~

where Standard `SupportedLiteralPattern` is exactly:

**Normative grammar:** see Appendix A for `SupportedLiteralPattern`.

No string, character, floating-point, fixed-width-integer, or user-defined literal pattern is Standard in `psc2-pattern-v1`.

---


## 15. Pattern Matching


### match


~~~proofscript
function getOrElse(value: Option Nat, fallback: Nat): Nat := {
  match value with {
    | .none => fallback
    | .some x => x
  }
}
~~~

Grammar:

**Normative grammar:** see Appendix A for `MatchBody`.

The `psc2-pattern-v1` profile requires single-scrutinee matching.

Not required by the `psc2-language-v1` profile:

- multi-scrutinee matching;
- arbitrary pattern alternatives;
- full Lean equation compiler;
- arbitrary dependent motive synthesis;
- user-defined pattern macros.

---


### 15.1 Pattern checking and binding

[match.pattern-check]

For `match scrutinee with { ... }`, first elaborate the single scrutinee and let its type be `S`.

Each alternative pattern is checked against `S`.

- a variable pattern matches any value and binds one fresh local with type `S`;
- `_` matches any value and binds nothing;
- a constructor pattern must name a constructor of the inductive family to which `S` reduces;
- constructor-pattern source arguments correspond to the constructor's explicit data fields after parameters/indices are instantiated from `S`;
- a nested constructor pattern recursively checks against the corresponding constructor-field type;
- a tuple pattern is the corresponding nested `Prod` constructor pattern;
- a `NatLiteral` pattern is admitted only when `S` is definitionally equal to `Nat`;
- `true`/`false` patterns are admitted only when `S` is definitionally equal to `Bool`.

[match.pattern-linearity]

A binder name may occur at most once in one pattern. Repeated binder names in a single pattern reject rather than creating an equality constraint.

### 15.2 Alternative order and runtime selection

[match.order]

Alternatives are tested in source order. The first matching alternative determines the branch.

An earlier variable or wildcard pattern therefore makes later alternatives unreachable. Unreachable alternatives MAY be diagnosed, but their presence does not change the first-match semantics.

### 15.3 Exhaustiveness

[match.exhaustive]

A Standard `match` must be exhaustive.

Coverage is checked structurally:

1. a variable or wildcard pattern covers the entire remaining scrutinee space;
2. for an inductive type, constructor patterns are grouped by constructor; every constructor must be covered, and nested fields must themselves be exhaustive when they contain nested refutable patterns;
3. `Bool` is exhaustive when both `true` and `false` are covered, unless a prior irrefutable pattern covers the remainder;
4. `Nat` literal patterns alone can never establish exhaustiveness; an irrefutable pattern or constructor-complete structural coverage is required.

Failure to establish coverage rejects the source. There is no runtime "match failure" meaning for an accepted Standard match.

### 15.4 Branch result type

[match.result-type]

Standard source has no explicit dependent `motive` syntax.

- when an expected result type is available, every branch is elaborated against it;
- otherwise, the first branch's inferred type becomes the expected type for later branches;
- all branch result types must be definitionally equal after pattern-bound locals are introduced;
- a result type that depends on the scrutinee value itself is outside this Standard match subset unless it is already fixed by the surrounding expected type without motive inference.

Arbitrary dependent motive synthesis remains outside `psc2-language-v1`.

### 15.5 Current boundary

The current compiler-stage pattern requirement remains intentionally bounded. Multi-scrutinee matching, unrestricted pattern alternatives, arbitrary motive synthesis, and user-defined pattern macros are not implied by this chapter.


## 16. Type System

Chapter 4 defines the core typing judgments. This chapter specifies the source-facing type forms admitted by `ps-0.9-r3`.

### 16.1 `Prop`

[type.prop]

~~~proofscript
P : Prop
~~~

`Prop` is `Sort 0`. Its inhabitants are proofs. A Boolean value is not automatically a proof.

### 16.2 `Type` and `Sort`

[type.universe.syntax]

~~~proofscript
Type
Type u
Sort u
~~~

`Type u` abbreviates `Sort (u + 1)` under the pinned universe semantics. Universe variables used by source declarations must be introduced or inferred according to the active profile.

### 16.3 Dependent function types

[type.pi.syntax]

~~~proofscript
(n: Nat) -> Fin n -> Nat
~~~

The type of later binders/results may depend on earlier values. Source syntax elaborates to the Pi-formation rule `[type.pi.form]`.

### 16.4 Type ascription and conversion

[type.ascription]

A type ascription `(t : A)` requires `A` to be a well-formed type and `t` to check against `A` modulo `[type.convert]`.

It is not an unchecked cast.

### 16.5 Inductive and structure types

[type.data]

Structure and inductive declarations are type-forming declarations only when their parameter/index/field/constructor types are well formed under Chapter 4 and Chapter 13.

### 16.6 Typeclass constraints

[type.class-constraint]

An instance binder such as `[C α]` elaborates to an instance-implicit Pi binder. Synthesis is elaboration behavior defined by `[elab.instance.insert]` and `[elab.instance.synth]`; it does not add a second typing relation.

### 16.7 Coercions

[type.coercion]

Coercions are not arbitrary conversions. Standard coercion insertion is exactly Chapter 22.10's bounded algorithm over the active coercion registry. `LEAN-ELAB-COERCION` is a pinned semantic/source locator for the inherited coercion classes/behavior; it does not override or enlarge the Standard algorithm.

### 16.8 PSCV refined-type sugar

[pscv.type.refine]

PSCV MAY expose the owned convenience form:

~~~proofscript
refine type Quantity := Nat
  where value => value > 0
~~~

Its logical meaning is an ordinary `Subtype` over the base type and predicate.

Conceptually:

~~~text
Quantity
≡
{ value : Nat // value > 0 }
~~~

Rules:

- the base expression MUST elaborate to a type;
- the predicate MUST elaborate to a proposition over one value of that type;
- constructing a refined value requires proof of the predicate;
- the proof component is computationally irrelevant under the ordinary subtype runtime semantics;
- coercion from the refined type to its base type MAY use the selected Standard subtype coercion;
- no unchecked cast from the base type to the refined type is introduced.

A compiler claiming `pscv-v1` MUST support this sugar or an explicitly versioned source-compatible spelling with identical lowering; the canonical PSCV spelling is the one above.

### 16.9 Rejection

[type.reject]

A source term rejects when required type formation, checking, conversion, universe solving, instance synthesis, coercion insertion, refined-type proof construction, or PSCV verification constraints cannot be completed according to the active profile. A conforming implementation MUST NOT fall back to JavaScript/TypeScript dynamic typing.

## 17. Equality and Reduction

### 17.1 Propositional equality

[eq.propositional]

~~~proofscript
theorem reflNat(n: Nat): n = n := by {
  rfl
}
~~~

`=` denotes the pinned propositional equality family mapped by `LEAN-CORE-EQ`. It is distinct from Boolean-valued equality such as `==`.

### 17.2 Definitional equality

[defeq.core]

Definitional equality is the conversion relation used by `[type.convert]`. For admitted ProofScript terms it is the Lean 4.35.0-rc3-pinned relation mapped by `LEAN-CORE-DEFEQ`, restricted to declarations/terms present in the active ProofScript environment.

The required reduction/equivalence families are:

#### Beta reduction

[defeq.beta]

~~~text
(fun x => body) arg
≡
body[x := arg]
~~~

#### Delta reduction

[defeq.delta]

A transparent defined constant may unfold to its definition according to its declaration transparency.

- `def` participates according to ordinary pinned definition transparency;
- `abbrev` is the Standard reducible declaration form and unfolds as specified by `LEAN-DECL-ABBREV`;
- `opaque` is the Standard opaque declaration form and does not unfold as ordinary source conversion;
- Standard source has no `@[reducible]`/`@[irreducible]` override syntax.

#### Iota / recursor reduction

[defeq.iota]

A recursor/eliminator applied to a constructor reduces to the corresponding minor premise/body according to the pinned inductive semantics.

Admitted `match` expressions obtain their computational meaning through this reduction after elaboration.

#### Zeta / let reduction

[defeq.zeta]

~~~text
let x := v
body
≡
body[x := v]
~~~

subject to the typed `let` semantics.

#### Projection reduction

[defeq.proj]

A projection from a value constructed by the corresponding structure constructor reduces to that declared field value, with dependent substitutions as required.

#### Quotient reduction

[defeq.quot]

Quotient reduction is inherited only through `LEAN-CORE-QUOT` and only for quotient operations admitted by the pinned logical foundation.

### 17.3 Eta principles

[defeq.eta-fun]

Function eta follows the pinned Lean theory for admitted functions.

[defeq.eta-structure]

Single-constructor structure eta follows the pinned Lean theory where the structure and projections satisfy the corresponding conditions.

### 17.4 Proof irrelevance

[defeq.proof-irrelevance]

Proof irrelevance is part of the pinned definitional-equality theory for proofs of the same proposition.

### 17.5 Transparency and rejection

[defeq.transparency]

An implementation may use any sound algorithm for conversion, but it MUST agree with the pinned semantic relation for admitted declarations.

Fuel limits, caches, heuristics, or backend representation are implementation details. Exhaustion MUST NOT be treated as proof that two terms are unequal when the specification relation says otherwise; an implementation that cannot decide a required check within its operational limits must fail explicitly rather than accept unsoundly.

## 18. Recursion and Computability

The current ProofScript edition admits **structural recursion only** for total recursive definitions. It does not inherit Lean's complete equation compiler or arbitrary well-founded termination elaboration.

### 18.1 Structural recursion model

[recursion.structural]

A total recursive declaration is accepted only when each recursive cycle can be justified by a designated structural argument and every recursive call satisfies the strict-subterm relation below.

### 18.2 Designated structural argument

[recursion.structural-arg]

For each recursive function in a strongly connected recursive group, exactly one explicit source parameter is its designated structural argument. It must have an admitted inductive-family type after elaboration.

The implementation may infer it only when the choice is unique; ambiguous structural arguments reject in `ps-0.9-r3`.

### 18.3 Strict structural subterm

[recursion.subterm]

Let `x` be the designated structural argument. A variable `y` is a direct strict structural subterm of `x` when `x` is eliminated by an admitted single-scrutinee `match`, a constructor alternative binds `y`, and the corresponding constructor field is a recursive occurrence of the same inductive family with the required parameters/indices.

The strict-subterm relation is the transitive closure of direct strict structural-subterm bindings exposed by nested admitted matches.

Arithmetic expressions such as `n - 1` are **not** structural-subterm evidence.

### 18.4 Self recursion

[recursion.self-call]

For every recursive self-call, the argument at the designated structural position MUST be a strict structural subterm of the caller's current structural argument. The remaining arguments must type-check normally. If any self-call fails this rule, the total definition rejects.

### 18.5 Local recursion

[recursion.local]

A recursive local declaration in a `where` group follows the same structural rules as a top-level recursive declaration.

### 18.6 Mutual recursion

[recursion.mutual]

For a mutually recursive strongly connected component:

- each function has exactly one designated structural argument;
- every recursive edge within the component passes a strict structural subterm to the callee's designated structural position;
- therefore every recursive cycle strictly decreases on every recursive edge.

Canonical example:

~~~proofscript
mutual
  function even(n: Nat): Bool := {
    match n with {
      | 0 => true
      | .succ k => odd(k)
    }
  }

  function odd(n: Nat): Bool := {
    match n with {
      | 0 => false
      | .succ k => even(k)
    }
  }
end
~~~

An `n - 1` call is not accepted as total structural recursion merely because it is mathematically decreasing.

### 18.7 Elaboration target

[recursion.elaboration]

An accepted structurally recursive declaration MUST elaborate to ordinary kernel-checkable terms using admitted recursor/eliminator semantics. The structural checker is not independent proof authority.

### 18.8 PSCV well-founded recursion

[pscv.recursion.well-founded]

The base `ps-0.9-r3` structural recursion rules remain valid in PSCV. In addition, PSCV requires a bounded, explicit total-recursion surface for algorithms that are not structurally recursive.

An admitted PSCV recursive declaration may use:

~~~text
termination_by measure
decreasing_by proof
~~~

subject to these rules:

1. `measure` MUST elaborate to a value in an admitted well-founded order;
2. every recursive call MUST generate a proof obligation that the measure decreases under that order;
3. `decreasing_by` is proof-construction syntax only; the resulting decrease evidence MUST be kernel accepted;
4. inferred termination is permitted only when the selected compiler can produce the same explicit checked decrease obligations; tooling SHOULD be able to materialize the inferred measure;
5. termination proof and functional-correctness proof are separate obligations;
6. failure or exhaustion of termination search is not evidence and blocks verified compilation.

The semantic target is ordinary kernel-checkable well-founded recursion. The termination elaborator has no independent proof authority.

This profile deliberately admits well-founded/measure recursion because practical verified software includes algorithms whose decrease is arithmetic or lexicographic rather than a syntactic constructor subterm.

### 18.9 Excluded PSCV recursion forms

[pscv.recursion.excluded]

PSCV v1 excludes from the verified executable closure:

- `partial`;
- unrestricted general recursion;
- recursion accepted only because the result type is inhabited;
- unsafe recursive definitions;
- `partial_fixpoint` unless a later PSCV effect/profile gives it an explicit verified partial-correctness semantics;
- coinductive/inductive fixpoint source forms unless a later profile specifies their executable/verification meaning;
- recursion whose termination is justified only by a native/compiler assertion that cannot be replayed as accepted proof evidence.

Course-of-values or lexicographic recursion MAY be admitted when encoded through the verified well-founded recursion mechanism above.

### 18.10 `partial`

Base ProofScript may describe `partial` as a runtime-only recursion boundary.

[recursion.partial]

For `pscv-v1`, `partial` source is rejected.

A module that must use partial execution belongs to a separately named non-PSCV or explicit-boundary component. Such a component cannot contribute to a `pscv-closed-v1` executable certificate.

[recursion.partial-trust]

No term whose meaning depends on a partial declaration may become PSCV proof evidence, approved specification meaning, or verified executable semantics.

### 18.11 `noncomputable`

[recursion.noncomputable]

`noncomputable` permits a logically valid total declaration whose ordinary executable realization is not required. It does not waive typing, positivity, proof, or totality rules.

### 18.12 Operational limits

[recursion.exhaustion]

Resource exhaustion during termination checking is not semantic evidence. An implementation unable to complete the required check must fail explicitly.

## 19. Propositions and Proofs

### proposition requirement

[proof.statement-prop]

For a Standard `theorem` or `example`, after elaborating declaration parameters the stated result type MUST have type `Prop`.

The proof body is elaborated against that proposition. A declaration such as `theorem t : Nat := 1` therefore rejects even though `1 : Nat` is an ordinary well-typed term.

This restriction is part of the Standard theorem/proof surface; ordinary data-producing declarations use `def`, `function`, `const`, `opaque`, or `abbrev`.




### proof terms


A theorem may be defined by an explicit proof term or a tactic block that produces one.

Example:

~~~proofscript
theorem identityProof(P: Prop, h: P): P := {
  h
}
~~~

where the explicit proof term is admitted by Appendix A and type-checks against the theorem proposition.

---


### by blocks

~~~proofscript
theorem addZero(n: Nat): n + 0 = n := by {
  simp
}
~~~

The block is proof/tactic syntax.

Within Standard's braced proof form, tactic sequencing is exactly `[prover.sequence]` from Chapter 20. Lean's native `;` tactical combinator is not Standard ProofScript syntax because it has tactic-composition semantics rather than separator semantics.

The bounded Lean-source compatibility profile may accept native Lean tactic spellings only when Appendix I.8 explicitly enumerates them.

A tactic implementation is not independent proof authority; an accepted theorem must end in a proof term accepted by the pinned proof-checking foundation.


---



### have


~~~proofscript
theorem chain(P: Prop, Q: Prop, hp: P, h: P -> Q): Q := by {
  have hq : Q := h(hp)
  exact hq
}
~~~

---


### show


Example proof form:

~~~proofscript
theorem t(P: Prop, h: P): P := by {
  show P
  exact h
}
~~~

---


### suffices


Example:

~~~proofscript
theorem t(P: Prop, Q: Prop, hPQ: P -> Q, hp: P): Q := by {
  suffices h : P from hPQ(h)
  exact hp
}
~~~

The accepted tactic/term form is exactly the Standard prover grammar in Chapter 20 and Appendix I.

---


### calc


~~~proofscript
theorem transEq(a: Nat, b: Nat, c: Nat, h1: a = b, h2: b = c): a = c := by {
  calc
    a = b := h1
    _ = c := h2
}
~~~

---


### classical


~~~proofscript
theorem excludedMiddle(P: Prop): P ∨ ¬P := by {
  classical
  by_cases h : P
  exact Or.inl h
  exact Or.inr h
}
~~~

Classical proof mode uses `[standard.classical]` and the pinned classical declarations; it does not alter the kernel theory.

---



### PSCV proof-closure policy

[pscv.proof.closure]

A PSCV verified executable may depend only on proof evidence whose complete transitive logical dependency closure satisfies the selected PSCV assurance policy.

Mandatory checks include:

- no unresolved metavariables;
- no `sorryAx` or equivalent admitted proof hole;
- no user axiom under `pscv-closed-v1`;
- no native/compiler-trust proof axiom under `pscv-closed-v1`;
- no unsafe declaration dependency;
- no partial declaration dependency;
- exact environment/profile identity recorded.

Proof automation is permitted to be heuristic, parallel, AI-assisted, solver-assisted, or implemented outside the TCB provided the final accepted evidence is independently checkable under the selected policy.

### PSCV classical reasoning

[pscv.proof.classical]

Classical reasoning MAY be used in propositions and proof-only computations when the selected logical policy permits it.

A data-producing definition whose runtime result depends on noncomputable classical choice is noncomputable and therefore cannot enter the PSCV executable closure.

A generated assurance report MUST expose the transitive foundational axiom set relied upon by public proof claims.

### Native evaluation boundary

[pscv.proof.native]

A proof that introduces an axiom representing trusted native/compiler evaluation is not accepted under `pscv-closed-v1`.

A weaker assurance policy MAY admit such evidence only under an explicit, named policy that reports the additional compiler trust. Ordinary use of `decide` that reduces to kernel-checkable proof evidence remains permitted.


## 20. Standard Prover

The Standard prover is a closed, versioned proof-construction surface. Tactics are elaboration/proof-construction mechanisms; they are not kernel primitives and do not gain independent proof authority.

[prover.soundness]

Every successful Standard tactic sequence MUST elaborate to proof evidence accepted by the pinned proof-checking foundation in Chapter 4 and Appendix I.

### 20.1 Fixed Standard tactic surface

[prover.standard.closed]

`psc2-standard-language-v1` admits exactly the following tactic families. The grammar below is the complete Standard source grammar; Lean parser variants not listed here belong only to a separately identified compatibility/extensible profile.

| Source head / variant | Mapping ID | Normative observable meaning |
|---|---|---|
| `rfl` | `LEAN-PROVER-RFL` | closes a goal using the pinned reflexivity procedure |
| `exact` | `LEAN-PROVER-EXACT` | closes the main goal when the supplied term checks against the target |
| `exact?` | `LEAN-PROVER-EXACTQ` | pinned proof search for an exact solution |
| `apply` | `LEAN-PROVER-APPLY` | refines the target using the supplied term and creates premises as goals |
| `refine` | `LEAN-PROVER-REFINE` | refinement where explicit `?_` holes become goals |
| `intro`, `intros` | `LEAN-PROVER-INTRO` | introduces target binders |
| `assumption` | `LEAN-PROVER-ASSUMPTION` | closes from a matching local hypothesis |
| `constructor` | `LEAN-PROVER-CONSTRUCTOR` | applies an admissible constructor to the target |
| `cases` | `LEAN-PROVER-CASES` | performs case analysis on one target term |
| `induction` | `LEAN-PROVER-INDUCTION` | performs induction on one target term |
| `rw` | `LEAN-PROVER-RW` | rewrites using the listed equality terms |
| `simp` | `LEAN-PROVER-SIMP` | simplifies using the fixed Standard simplifier environment plus supplied simp terms |
| `simpa` | `LEAN-PROVER-SIMPA` | simplifies and closes the goal; optional `using` term |
| `simp only` | `LEAN-PROVER-SIMP-ONLY` | simplifies only with the explicit simp list plus kernel-required definitional reduction |
| `simp_all` | `LEAN-PROVER-SIMP-ALL` | simplifies target and local hypotheses using the fixed Standard environment |
| `unfold` | `LEAN-PROVER-UNFOLD` | unfolds one or more named definitions |
| `change` | `LEAN-PROVER-CHANGE` | replaces the current target by a definitionally equal target |
| `dsimp` | `LEAN-PROVER-DSIMP` | definitional simplification with an optional explicit list |
| `have` | `LEAN-PROVER-HAVE` | introduces a proved intermediate proposition |
| `show` | `LEAN-PROVER-SHOW` | changes/presents the expected target |
| `suffices` | `LEAN-PROVER-SUFFICES` | creates a sufficient intermediate proposition |
| `by_cases` | `LEAN-PROVER-BY-CASES` | splits on one proposition |
| `by_contra` | `LEAN-PROVER-BY-CONTRA` | switches to contradiction proof |
| `exfalso` | `LEAN-PROVER-EXFALSO` | changes the target to `False` where valid |
| `subst` | `LEAN-PROVER-SUBST` | substitutes one or more local identifiers |
| `generalize` | `LEAN-PROVER-GENERALIZE` | generalizes one term to one identifier |
| `rcases` | `LEAN-PROVER-RCASES` | destructures evidence with the bounded proof-pattern grammar |
| `rintro` | `LEAN-PROVER-RINTRO` | introduces and destructures using bounded proof patterns |
| `obtain` | `LEAN-PROVER-OBTAIN` | obtains bounded-pattern evidence from one term |
| `use` | `LEAN-PROVER-USE` | supplies one or more witness terms |
| `ext` | `LEAN-PROVER-EXT` | applies fixed Standard extensionality rules |
| `decide` | `LEAN-PROVER-DECIDE` | constructs a proof through the admitted decidability mechanism |
| `omega` | `LEAN-PROVER-OMEGA` | pinned arithmetic proof automation |
| `grind` | `LEAN-PROVER-GRIND` | pinned Standard proof automation |
| `calc` | `LEAN-PROVER-CALC` | constructs an equality chain using the bounded Standard `calc` grammar |
| `classical` | `LEAN-PROVER-CLASSICAL` | enables pinned classical proof construction in the current proof scope |

### 20.2 Exact Standard tactic grammar

[prover.grammar]

~~~ebnf
StandardTactic :=
    RflTactic
  | ExactTactic
  | ExactSearchTactic
  | ApplyTactic
  | RefineTactic
  | IntroTactic
  | IntrosTactic
  | AssumptionTactic
  | ConstructorTactic
  | CasesTactic
  | InductionTactic
  | RewriteTactic
  | SimpTactic
  | SimpaTactic
  | SimpOnlyTactic
  | SimpAllTactic
  | UnfoldTactic
  | ChangeTactic
  | DSimpTactic
  | HaveTactic
  | ShowTactic
  | SufficesTactic
  | ByCasesTactic
  | ByContraTactic
  | ExfalsoTactic
  | SubstTactic
  | GeneralizeTactic
  | RCasesTactic
  | RIntroTactic
  | ObtainTactic
  | UseTactic
  | ExtTactic
  | DecideTactic
  | OmegaTactic
  | GrindTactic
  | CalcTactic
  | ClassicalTactic

RflTactic          := "rfl"
ExactTactic        := "exact" PSTerm
ExactSearchTactic  := "exact?"
ApplyTactic        := "apply" PSTerm
RefineTactic       := "refine" RefineTerm
RefineTerm         := PSTerm | "?_"
IntroTactic        := "intro" Identifier+
IntrosTactic       := "intros"
AssumptionTactic   := "assumption"
ConstructorTactic  := "constructor"
CasesTactic        := "cases" PSTerm
InductionTactic    := "induction" PSTerm
RewriteTactic      := "rw" "[" RewriteItem ("," RewriteItem)* ","? "]"
RewriteItem        := ("←")? PSTerm

SimpArgs           := "[" (SimpItem ("," SimpItem)* ","?)? "]"
SimpItem           := ("←")? PSTerm
SimpTactic         := "simp" SimpArgs?
SimpOnlyTactic     := "simp" "only" SimpArgs
SimpaTactic        := "simpa" SimpArgs? ("using" PSTerm)?
SimpAllTactic      := "simp_all" SimpArgs?
DSimpTactic        := "dsimp" SimpArgs?

UnfoldTactic       := "unfold" QualifiedIdentifier+
ChangeTactic       := "change" PSTerm
HaveTactic         := "have" Identifier ":" PSTerm ":=" PSTerm
ShowTactic         := "show" PSTerm
SufficesTactic     := "suffices" Identifier ":" PSTerm "from" PSTerm
ByCasesTactic      := "by_cases" Identifier ":" PSTerm
ByContraTactic     := "by_contra" Identifier?
ExfalsoTactic      := "exfalso"
SubstTactic        := "subst" Identifier+
GeneralizeTactic   := "generalize" PSTerm "=" Identifier

ProofPattern       :=
    Identifier
  | "_"
  | "(" ProofPattern ("," ProofPattern)+ ","? ")"
  | "⟨" ProofPattern ("," ProofPattern)+ ","? "⟩"

RCasesTactic       := "rcases" PSTerm "with" ProofPattern
RIntroTactic       := "rintro" ProofPattern+
ObtainTactic       := "obtain" ProofPattern ":=" PSTerm
UseTactic          := "use" PSTerm ("," PSTerm)* ","?
ExtTactic          := "ext" Identifier*
DecideTactic       := "decide"
OmegaTactic        := "omega"
GrindTactic        := "grind"

CalcTactic :=
  "calc" CalcFirstStep CalcNextStep+

CalcFirstStep :=
  PSTerm "=" PSTerm ":=" PSTerm

CalcNextStep :=
  TacticSep "_" "=" PSTerm ":=" PSTerm

ClassicalTactic    := "classical"
~~~

[prover.calc]

The Standard `calc` surface is deliberately smaller than Lean's general calculation syntax.

For:

~~~text
calc
  a = b := p₁
  _ = c := p₂
  ...
  _ = z := pₙ
~~~

each proof term `pᵢ` MUST check against the displayed propositional equality. The resulting tactic constructs the equality chain using the pinned `Eq.trans` declaration and preserves source step order.

Only propositional equality `=` chains are Standard. General relation inference, custom transitivity attributes, and omitted proof steps are excluded.

[prover.sequence]

A Standard `by { ... }` block is a newline/layout sequence of `StandardTactic` items. The next tactic is applied to the current first unsolved goal. Goals generated by a tactic are placed before the previously remaining goals, preserving the tactic's pinned goal order.

The Standard grammar does **not** include Lean tactic bullets, `case`, `all_goals`, tactic alternatives, tactic configuration records, tactic locations (`at ...`), `using` clauses except the `simpa ... using term` form above, `with` alternatives for `cases`/`induction`, or Lean's `;` tactical combinator.

`lean-subset-psc2-v1` may admit those native Lean forms only when separately enumerated by a source-compatible mapping; they are not Standard ProofScript syntax.

### 20.3 Source-profile isolation

[profile.standard.tactics]

Ordinary dependencies MUST NOT register new Standard tactic syntax or elaborators. Additional tactics or tactic syntax require an explicitly identified extensible or later Standard profile.

### 20.4 Examples

~~~proofscript
theorem refl(n: Nat): n = n := by {
  rfl
}
~~~

~~~proofscript
theorem useProof(P: Prop, h: P): P := by {
  exact h
}
~~~

~~~proofscript
theorem pairProof(P: Prop, Q: Prop, hp: P, hq: Q): P ∧ Q := by {
  constructor
  exact hp
  exact hq
}
~~~

~~~proofscript
theorem optionCases(x: Option Nat): True := by {
  cases x
  exact True.intro
  exact True.intro
}
~~~

### 20.5 Mechanical-validation requirement

[prover.validation]

Every Standard tactic row MUST have at least one positive executable-conformance obligation and at least one negative/adversarial obligation.

Appendix J assigns stable `PS-CONF-*` identities to those obligations. The reference-integrity suite is executable and passing; semantic parser/elaborator/tactic/kernel execution remains deferred until implementation validation.


## 21. Contracts and Verification

PSCV turns contracts from optional metadata into one of the primary ways executable behavior is specified and proved.

The base r3 contract proposition remains the logical anchor; PSCV adds mandatory proof closure, call-site use, effectful weakest-precondition semantics, local assertions, loop invariants, ghost state, and external approved specification linkage.

### 21.1 Pure contract grammar

[contract.syntax]

The inherited pure clauses remain and PSCV adds bounded frame/error clauses for verified effects:

~~~ebnf
ContractClause :=
    "requires" PSTerm
  | "ensures" Identifier "=>" PSTerm

PSCVEffectClause :=
    "reads" "[" PSTerm ("," PSTerm)* ","? "]"
  | "modifies" "[" PSTerm ("," PSTerm)* ","? "]"
  | "errors" Identifier "=>" PSTerm
~~~

PSCV additionally admits the `given` clause and contract-only `old(...)` term defined in Appendix A.18.

A contract is proof-level semantics. It is not an implicit runtime assertion.

### 21.2 Applicability

[contract.applicability]

Contracts may be attached only to total declarations.

Under PSCV:

- `partial` is rejected;
- executable `noncomputable` dependencies are rejected;
- pure functions use the pure contract proposition;
- effectful functions require an admitted PSCV weakest-precondition semantics;
- a function whose effect family lacks PSCV verification semantics cannot satisfy closed verified compilation merely by having syntactically well-formed clauses.

### 21.3 Scope and `given`

[contract.scope]

A `requires` clause is elaborated in the function's parameter/declaration scope.

An `ensures result => Post` clause additionally binds `result` at the logical successful-result type selected by the contract semantics.

[pscv.contract.given]

`given` introduces logical specification variables that:

- are in scope for following `requires` and `ensures` clauses;
- do not become runtime parameters;
- may be instantiated by verification/specification rules;
- are erased from executable meaning;
- cannot affect runtime control/data except through propositions already proved about runtime values.

This provides a stable PSCV-owned equivalent of logical contract binders; its semantics do not depend on experimental Lean syntax.

### 21.4 Well-formedness

[contract.wellformed]

Every `requires`/`ensures` proposition MUST elaborate to `Prop`.

A clause with unresolved metavariables, forbidden dependencies, ambiguous names, non-Prop result, unapproved logical assumptions, or disallowed effect references rejects or blocks verification according to the violated rule.

### 21.5 Pure contract proposition

[contract.obligation]

For a total pure function:

~~~text
f : (x₁ : A₁) -> ... -> (xₙ : Aₙ) -> B
~~~

with preconditions `Pre₁ ... Preₖ` and postconditions `Post₁ ... Postₘ`, the associated proposition is conceptually:

~~~text
forall x₁ ... xₙ,
  (Pre₁ ∧ ... ∧ Preₖ) ->
  (Post₁[result := f x₁ ... xₙ] ∧ ... ∧
   Postₘ[result := f x₁ ... xₙ])
~~~

using the real dependent telescope and capture-avoiding substitution.

Zero preconditions contribute `True`.

Under base ProofScript, zero postconditions may mean no functional claim. Under PSCV, a public executable declaration with no postcondition is still required to satisfy the active specification-coverage policy; it must be covered by an approved type-as-specification declaration, external formal claim, law, or other explicit approved specification.

### 21.6 Body verification semantics

[pscv.contract.body]

When verifying a contracted function:

1. each precondition is introduced as a hypothesis at function entry;
2. every normal return path MUST establish every required postcondition;
3. every early return path MUST establish the same relevant postconditions;
4. verified assertions/invariants may extend the proof context only after their own obligations are proved;
5. no runtime test is accepted in place of proof unless the requirement's approved evidence policy is explicitly non-proof.

### 21.7 PSCV contract acceptance

[contract.acceptance]

Base `ps-0.9-r3` distinguishes “specified” from “verified.”

PSCV adds a stronger executable rule:

[pscv.contract.required-proof]

A contracted executable declaration MAY be parsed/elaborated while its proof is open, but it MUST NOT enter `VerifiedExecutableModule` until accepted proof evidence exists for the exact required contract proposition/judgment.

Tools MUST distinguish at least:

~~~text
unspecified
specified
proof-open
verified
rejected
assumed-boundary
~~~

A specified-but-unverified contract is never usable as verified evidence in PSCV.

### 21.8 Caller precondition obligations

[pscv.contract.call-pre]

For a call to a function with verified precondition `Pre`, the verifier MUST generate an obligation establishing `Pre` at the call site, unless `Pre` is definitionally true or is already discharged by an equivalent checked fact.

Failure to prove the caller obligation blocks the caller's PSCV executable certificate.

This is a PSCV-specific strengthening of the base r3 contract model.

### 21.9 Using verified postconditions

[pscv.contract.call-post]

After a call whose contract proof is accepted, the verifier MAY use the verified postcondition as a logical fact about the returned result/effect state.

The fact comes from the checked contract theorem/judgment, not from trusting function metadata.

A dependency's contract may be used modularly without unfolding the implementation when the imported evidence identity is accepted.

### 21.10 Verification-only `assert`

[pscv.assert]

Inside an admitted verified computation:

~~~proofscript
assert P
~~~

generates an obligation for `P`.

Once proved, `P` is available to subsequent verification.

The assertion erases from verified executable semantics unless a separate diagnostic runtime-check mode is explicitly selected. A passing runtime assertion is not formal proof.

### 21.11 Loop invariants

[pscv.loop.invariant]

A loop invariant is a proposition over the logical loop state.

For each loop, verification MUST establish as applicable:

1. initialization before the first iteration;
2. preservation after ordinary iteration;
3. preservation/appropriate transfer across `continue`;
4. exit facts after condition failure;
5. exit facts after `break`;
6. facts required by code following the loop.

The VC generator is not proof authority; every accepted resulting proposition must be closed by checked evidence.

### 21.12 Decreasing/termination obligations

[pscv.loop.decreasing]

A `while`, repeat-like loop, or recursive definition requiring explicit termination evidence uses a measure/relation whose well-founded descent is proved.

For finite certified `for` iterators, termination may be inherited from the iterator's verified specification.

Termination and functional correctness are distinct obligations.

### 21.13 Ghost state and noninterference

[pscv.ghost.noninterference]

Ghost values exist only for specification/proof construction.

A PSCV compiler MUST establish that erasing ghost values cannot change:

- returned runtime data;
- runtime branch selection;
- number/order/parameters of externally observable effect operations;
- memory/resource behavior that is part of the source semantics;
- foreign calls;
- public exceptions/errors.

A runtime-relevant dependency on ghost state blocks verified compilation.

### 21.14 Effectful contracts and weakest-precondition semantics

[pscv.effect.wp]

An effect family `m` may participate in PSCV verification only through a closed, versioned specification interface equivalent in purpose to:

~~~text
WP m ps
WPMonad m ps
~~~

where the weakest-precondition interpretation maps a program and postcondition to a precondition and is proved compatible with the admitted sequencing operations.

The exact implementation need not reuse Lean's `Std.Do` types, but it MUST provide equivalent proof obligations with kernel-checkable meaning under `PSCV-VERIFY-v1`.

For a computation:

~~~text
prog : m A
~~~

a contract denotes a proposition equivalent to a Hoare/weakest-precondition judgment:

~~~text
{ Pre } prog { Post }
~~~

under the registered effect semantics.

### 21.14A Verified-effect law requirements

[pscv.effect.wp-laws]

Registering an effect as PSCV-verifiable requires checked law evidence sufficient for compositional VC generation.

At minimum the effect specification must establish the appropriate analogues of:

1. **monotonicity** — strengthening a postcondition cannot weaken soundness of the derived precondition;
2. **pure law** — the WP of `pure x` corresponds to applying the postcondition to `x`;
3. **bind law** — the WP of `x >>= f` composes the WP of `x` with the WP of `f`;
4. **operation specifications** — each primitive admitted effect operation has a checked specification theorem;
5. **representation independence** — backend implementation details do not redefine the logical state/post-shape.

A `Monad` instance alone is not a verification model.


### 21.15 Standard verified effect families

[pscv.effect.standard]

PSCV v1 requires verified specification support for at least:

- identity/pure computation;
- state;
- reader;
- typed error/exception (`Except`-style).

A distribution MAY additionally standardize Option-like failure, writer/logical accumulation, resource capabilities, tasks, streams, or other effects only through explicit profile/environment revisions.

Raw `IO` does not become verified merely because it is a monad.

### 21.16 State contracts

[pscv.effect.state]

Stateful contracts can relate pre-state, result, and post-state.

Conceptually:

~~~text
Pre  : State -> Prop
Post : Result -> State -> Prop
~~~

or an equivalent PSCV post-shape representation.

The logical state shape is defined by the verified effect model, not by JavaScript objects, Rust references, or backend layout.

### 21.16A Pre-state, reads, and modifies

[pscv.effect.frame]

For a verified state/resource effect, PSCV may use a contract-only pre-state expression:

~~~proofscript
old(expr)
~~~

Its meaning is evaluation of the admitted pure/model expression `expr` in the logical pre-state of the current contract. `old` has no runtime effect.

`reads [a, b, ...]` and `modifies [x, y, ...]` are frame clauses over **abstract state components/capabilities defined by the selected verified effect model**, not arbitrary host pointers.

A verified frame rule MUST establish:

- components outside `modifies` are unchanged unless the effect model explicitly defines a weaker relation;
- every state component observed by the specification is permitted by the `reads`/model rules;
- a callee's frame contract is respected compositionally by callers.

PSCV v1 does not use `modifies` to authorize arbitrary aliased heap mutation. A future heap/region profile must define aliasing and frame semantics separately.

### 21.16B Typed error postconditions

[pscv.effect.error-post]

For an admitted typed-error effect:

~~~proofscript
errors err => P
~~~

specifies a proposition for the error result/path.

The success `ensures` and `errors` clauses are checked against distinct postcondition branches of the effect's verified post-shape.

If no `errors` clause is present, the active effect/profile specifies the default error obligation; it MUST NOT silently infer that every error path satisfies arbitrary success claims.


### 21.17 Error contracts

[pscv.effect.error]

A typed-error effect MUST distinguish success and error postconditions where relevant.

A postcondition about a successful result cannot silently constrain an error path, and an error path cannot silently satisfy a success postcondition merely because no success result exists.

### 21.18 External/world effects

[pscv.effect.world]

Filesystem, network, database, clock, randomness, threads, device IO, raw FFI, and external services are not closed mathematical effects by default.

They may be used in:

- a separately verified abstract capability/effect whose laws are proved, or
- `pscv-boundary-v1` through explicit boundary assumptions/models.

Their presence prevents `pscv-closed-v1` status unless the entire relevant behavior is represented by accepted closed evidence.

### 21.19 Specification sources

[pscv.spec.source]

An approved formal specification for an executable declaration may originate from:

1. an inline PSCV contract;
2. the declaration's approved dependent/refinement type (“type as specification”);
3. a theorem/law explicitly linked to the declaration;
4. an external approved SpecCapsule formal claim.

Human-language prose, Markdown text, UML/SysML diagrams, examples, comments, or AI descriptions are not themselves formal propositions.

A recommended `.ps.md` workflow may embed formal ProofScript/PSCV claims beside prose, but only the elaborated formal claims and approved metadata enter the verified semantic identity.

### 21.20 SpecCapsule linkage

[pscv.spec.capsule]

For an external approved specification, the verified build MUST bind evidence to a stable specification identity that includes at least:

- project/module identity;
- formal claim identities;
- environment/profile identity;
- approved assumption policy;
- canonical digest.

Changing a formal claim or its semantic environment invalidates dependent proof certificates until re-verification succeeds.

The exact serialized file format belongs to the VSDD/build specification; the identity relationship is normative here.

### 21.20A Specification anti-weakening rule

[pscv.spec.anti-weakening]

Implementation/proof changes are not allowed to weaken an approved formal claim while retaining the same specification identity.

If an AI or human proposes to:

- delete a formal claim;
- replace it by a weaker proposition;
- broaden an allowed assumption;
- change a public API relation used by the claim;
- downgrade a proof-required requirement to test/assumption evidence;

the change is a **specification revision**, not an implementation repair.

The existing approval/certificate becomes stale until the new specification identity is explicitly approved according to project policy.

This rule is enforced semantically by identity/digest linkage even if filesystem permissions do not physically prevent the candidate generator from editing the authoring file.


### 21.21 Type-as-specification

[pscv.spec.by-type]

A declaration may explicitly state that its full approved type is its public behavioral specification.

This is appropriate for dependent/refinement APIs whose result type already captures the desired relation.

The choice MUST be explicit in the approved specification coverage data; PSCV does not assume that an ordinary type such as `Nat -> Bool` completely specifies intended behavior.

### 21.22 Canonical obligation identity

[contract.normalization]

Every PSCV obligation identity is computed after successful elaboration with:

- solved term/universe metavariables;
- fully qualified declaration identities;
- explicit universe instantiation;
- closed abstraction over local binders;
- metadata irrelevant to kernel meaning removed.

The base `PS-CORE-SEXPR-v1` encoding remains the canonical core-expression encoding unless a later version replaces it.

[pscv.contract.identity]

The PSCV obligation identity conceptually includes:

~~~text
pscv-obligation-v1:
  module
  declaration
  profile = pscv-v1
  verification_semantics = PSCV-VERIFY-v1
  specification_digest
  proposition_sha256
~~~

Two proofs are not interchangeable merely because an AI, test suite, or pretty-printer considers their source text equivalent.

### 21.23 Specification lemmas

[pscv.spec-lemma]

Reusable operations SHOULD expose checked specification theorems so callers can verify compositionally without unfolding implementations.

A specification registry is an index of checked declarations, not proof authority.

PSCV verification libraries SHOULD provide specifications for Standard collections, numeric operations, codecs, iterators, and admitted effects.

### 21.24 Runtime contract instrumentation

[contract.no-runtime-assert]

Formal contracts do not require runtime checks in a verified build.

A tool MAY compile executable approximations of selected contracts for debugging, testing, boundary validation, or monitoring, but MUST label this separately from proof.

### 21.25 Explicit verification proof attachment

[pscv.verify-declaration]

PSCV provides an optional proof-only declaration for cases where automatic verification does not close a declaration's aggregate obligation:

~~~proofscript
verify withdraw := by {
  omega
}
~~~

`verify target := proofTerm` means:

1. resolve `target` to one PSCV-specifiable declaration in the current/imported verified environment;
2. construct that declaration's exact aggregate `PSCV-VERIFY-v1` obligation from its approved specification and implementation identity;
3. elaborate `proofTerm` against that obligation;
4. store the resulting checked evidence under a stable derived verification identity.

The proof declaration does not modify the target's specification or executable body.

A target with changed source/spec/environment identity invalidates the attached verification evidence.

Automatic verification and explicit `verify` are two proof-construction routes to the **same obligation**, not different correctness standards.


### 21.26 Proof automation

[pscv.verification.automation]

A PSCV implementation SHOULD attempt automated discharge using a deterministic/profile-pinned pipeline such as:

~~~text
definitional reduction
-> simplification/specification lemmas
-> grind-class automation
-> arithmetic decision procedures
-> VC-specific simplification
-> controlled plugins/SMT reconstruction
-> AI proof search
-> user proof
~~~

The exact search strategy is not part of logical truth. Accepted evidence remains subject to the proof-checking foundation.

### 21.27 Verification failure

[pscv.verification.failure]

If a required contract, assertion, invariant, termination condition, call-site precondition, effect obligation, ghost-erasure condition, or linked formal claim remains open, the source may remain available to editors and `psc check`, but the affected reachable executable closure MUST NOT receive PSCV verified status or executable emission under the PSCV build command.

## 22. Elaboration and Static Semantics

Surface elaboration is observable when it changes source acceptance or the resulting core term. Internal data structures, traversal order that does not affect meaning, caching, and performance heuristics are implementation details.

### 22.1 Name resolution

[elab.name.resolve]

A name MUST resolve deterministically in the active local/module/profile environment. Ambiguous resolution rejects. There is no last-import-wins fallback.

### 22.2 Expected-type-directed checking

[elab.expected-type]

An expected type MAY constrain elaboration of admitted terms, including constructor shorthand, implicit arguments, coercions, lambdas, and proof terms. The resulting term MUST still satisfy the core typing rules.

### 22.2.1 Literal elaboration and defaulting

[elab.literal]

Standard literals elaborate as follows:

- a natural-number token `n` creates `OfNat α n` for the expected/inferred result type `α` and elaborates to `OfNat.ofNat`;
- a scientific-number token creates `OfScientific α` and elaborates to `OfScientific.ofScientific` using raw `Nat` mantissa/exponent components;
- unary `-` is not part of a numeric token; it is ordinary prefix `Neg.neg` applied after elaboration of the following numeric expression;
- string literals have the pinned Standard `String` type;
- character literals have the pinned Standard `Char` type;
- `true` and `false` have type `Bool`;
- `()` has type `Unit`.

[elab.literal-expected]

When an expected type is available, overloaded numeric/scientific literal synthesis first uses that expected type. Failure to synthesize the required `OfNat`/`OfScientific` instance rejects; Standard does not silently fall back to another numeric type.

[elab.defaulting-phase]

After ordinary constraint solving, expected-type propagation, and ordinary instance synthesis reach a fixed point, Standard performs one deterministic **defaulting phase** for still-stuck defaultable instance problems.

A problem is defaultable only when:

1. it arises from an overloaded literal/operator class problem created by Standard elaboration;
2. at least one class input needed for ordinary search is still an unassigned metavariable;
3. the goal has at least one matching entry in the active `default_instance` registry.

Defaultable problems are processed in original constraint-creation order.

For each problem:

1. try active default instances by descending priority;
2. for equal priority use the same deterministic declaration order as `[instance.order]`;
3. candidate application uses transactional `PS-UNIFY-v1` assignments;
4. recursively solve the candidate's instance-implicit prerequisites;
5. the first candidate that produces a complete solution wins;
6. after any successful assignment, reactivate blocked constraints and ordinary instance problems;
7. repeat to a fixed point.

If no default candidate succeeds and required metavariables remain unresolved, elaboration rejects.

[elab.literal-defaults]

The final frozen RC3 manifest MUST preserve these required default behaviors:

~~~text
unconstrained natural literal
  → default `OfNat Nat n`
  → Nat

unconstrained scientific literal
  → highest successful `OfScientific` default in manifest order
  → Float in STD-ENV-PSCV-V1-L435RC3-RC1-v6

unconstrained negative numeral
  → prefix Neg plus literal constraints;
    manifest defaulting may select Int when the `Neg` problem determines the type,
    then the `OfNat Int` instance completes the literal
~~~

Expected type always takes precedence over these defaults.

No host-language numeric defaulting, JavaScript `number`, or TypeScript contextual numeric rule participates.

### 22.3 Function application algorithm

[elab.apply]

Given a callable head and a source argument sequence, first partition the source arguments into:

- a positional prefix;
- followed by an optional named-argument suffix.

[call.named-order]

Once a named argument occurs, every later source argument in that parenthesized call MUST also be named. A positional argument after a named argument rejects.

Then elaboration proceeds over the function's Pi telescope:

1. Build the named-argument map; reject duplicate names immediately. When the current telescope binder has a matching named argument, elaborate that source argument against the binder type and mark the binder supplied. Named arguments may target explicit, ordinary-implicit, strict-implicit, or instance-implicit binders whose source name is present in the telescope.
2. For an ordinary implicit parameter, insert a fresh elaboration metavariable.  
   Rule: `[elab.implicit.insert]`, mapping `LEAN-ELAB-IMPLICIT`.
3. For an instance-implicit parameter, insert an instance metavariable and schedule synthesis.  
   Rule: `[elab.instance.insert]`.
4. For a strict-implicit parameter, insert a metavariable only when later named/positional source arguments require application beyond that binder.  
   Rule: `[elab.strict-implicit.insert]`.
5. For an explicit parameter, consume the next positional source argument if present.
6. If no explicit argument is present and the parameter has a default, use the declared default.  
   Rule: `[elab.default.insert]`.
7. If a ProofScript-owned empty call `f()` is being elaborated, every omitted explicit parameter MUST be satisfiable by the admitted optional/default/automatic mechanism; otherwise reject.  
   Rule: `[call.empty.required-argument]`.
8. After the telescope walk, reject every named argument whose name matched no binder.
9. Reject any positional argument left after the callable type is no longer a function type.
10. Run required instance synthesis and solve required metavariables; unresolved obligations needed for source acceptance reject.

Duplicate named arguments reject under `[call.named.duplicate]` before the telescope walk.

ProofScript parenthesized multi-argument calls still elaborate to nested unary core applications.

### 22.4 Named arguments

[elab.named]

Named arguments select declared parameter identities; they are not runtime object fields.

A name may be supplied at most once in one application. Named arguments do not reorder the core function type; they only select which source argument is associated with which binder.

[call.named-target]

A named argument must match a source-visible binder name in the callable Pi telescope. Supplying an instance-implicit binder by name supplies that binder directly and suppresses instance synthesis for that binder. Anonymous binders cannot be targeted by name.

Named arguments form a suffix of one ProofScript parenthesized call as required by `[call.named-order]`.

### 22.5 Default arguments

[elab.default.insert]

A declaration default is elaboration metadata associated with an explicit parameter. Supplying a default does not create runtime overload dispatch.

[elab.default-declaration]

For an explicit parameter:

~~~text
x : A := d
~~~

the default term `d` is elaborated **when the declaration is elaborated**, against expected type `A`, in the context of:

- declaration universe parameters;
- all preceding implicit/strict-implicit/instance/explicit parameters;
- declaration-visible global names.

The parameter `x` itself and every later parameter are not in scope in `d`.

The declaration stores the resulting elaborated default expression abstracted over the preceding telescope. An ill-typed or unresolved default rejects the declaration.

[elab.default-application]

At a call site, when explicit parameter `x` is omitted and has a declaration default:

1. instantiate the stored default with the already elaborated arguments for all preceding telescope binders;
2. use the instantiated result as the argument for `x`;
3. continue elaboration of later binders with that argument included in substitution.

The stored source default is not reparsed or re-elaborated in the caller's lexical scope. Caller-local names therefore cannot change its meaning.

### 22.6 Zero-source-argument function sugar

[elab.zero-source-function]

`function f(): R := body` elaborates according to the language's specified optional `Unit` binder model. It does not create a JavaScript-style independent zero-arity function model.

### 22.7 Empty calls

[call.empty]

`f()` requests completion of omitted explicit parameters.

If a required explicit parameter remains after all admitted completion rules, the source rejects.

`f()` is distinct from `f(())`, which supplies an explicit `Unit` value.


### 22.8 Standard unification and metavariable solving

[unify.standard]

`ps-standard-0.9-r3` uses the deterministic solver `PS-UNIFY-v1`. It is smaller than unrestricted Lean elaborator unification.

A **constraint** is one of:

~~~text
EqType(t, u, expectedSort?)
LevelEq(l₁, l₂)
HasType(t, A)
~~~

All constraints carry the local metavariable context in which they were created.

[unify.order]

Constraints enter one FIFO work queue in source/elaboration creation order. A constraint is processed until it:

- succeeds;
- assigns a metavariable;
- decomposes into new constraints appended in left-to-right order;
- becomes *blocked* on unresolved metavariables and is moved to the FIFO blocked queue;
- fails.

Whenever an assignment is made, blocked constraints whose blocker set changed are appended back to the work queue in their original creation order.

[unify.whnf]

Before rigid comparison, both sides are weak-head reduced using Chapter-17 definitional equality/transparency rules. A successful direct definitional-equality check discharges the constraint.

[unify.assign]

An unassigned metavariable `?m` may be assigned to term `t` only when:

1. `?m` does not occur in `t` (occurs check);
2. every free local in `t` belongs to `?m`'s local context;
3. the assignment type-checks against `?m`'s expected type;
4. the assignment does not capture a local variable.

For a metavariable application:

~~~text
?m x₁ ... xₙ
~~~

where each `xᵢ` is a distinct local bound variable, pattern assignment is permitted by assigning `?m` the corresponding lambda abstraction over those variables. No higher-order imitation/projection search is performed outside this pattern case.

[unify.decompose]

After weak-head reduction, rigid-rigid constraints decompose only when their outer constructors agree:

- `Sort` with `Sort` → universe-level constraint;
- same constant name → pairwise universe-level constraints;
- application with application → function constraint then argument constraint;
- Pi with Pi → domain constraint then codomain under one fresh shared local;
- lambda with lambda → binder-domain constraint, then body constraint under one fresh shared local;
- let with let → declared-type/value/body constraints;
- projection with same structure/projection index → projected-expression constraint.

Different rigid constructors fail unless Chapter 17 already establishes definitional equality.

[unify.level]

Universe solving uses structural equations over `zero`, parameters, `succ`, `max`, and `imax`, plus fresh universe metavariables. A universe metavariable may be assigned only when the assignment passes an occurs check. Standard unification performs no search over arbitrary inequational universe solutions; unresolved required universe equations reject.

[unify.postpone]

A constraint may be postponed only when its next deterministic rule depends on an unresolved metavariable. Postponement itself never guesses a term, type, instance, coercion, or universe level.

When both the work queue and reactivated queue are empty:

- unresolved constraints required for source acceptance reject;
- unresolved metavariables occurring only in discarded diagnostics/tooling state may be discarded.

[unify.no-search]

`PS-UNIFY-v1` performs no arbitrary higher-order search, no type-directed backtracking between unrelated term constructors, and no defaulting except the explicitly specified default-instance/default-argument mechanisms.

Instance synthesis may backtrack between instance candidates under Chapter 22.9; each candidate branch uses a transactional copy of `PS-UNIFY-v1` assignments.

[unify.result]

Two conforming implementations given the same source, expected types, and Standard environment MUST either:

- produce core terms equal under Chapter-17 definitional equality, or
- both reject.

Implementation heuristics, parallelism, cache state, hash iteration order, or operational fuel may not select a different accepted solution.

### 22.9 ProofScript Standard instance synthesis

[elab.instance.synth]

Standard instance synthesis is a deterministic bounded ProofScript algorithm over the active declaration environment. It is intentionally smaller than unrestricted Lean instance synthesis.

#### Candidate registry

[instance.registry]

The candidate registry contains local instance-implicit binders, accepted visible `instance` declarations, declarations tagged with the Standard `instance` attribute, and fixed Standard-prelude instances from Appendix K. Unrelated installed packages do not contribute unless imported.

#### Candidate order

[instance.order]

Candidate order is a total order.

1. **Local candidates first.** A candidate from a lexically nearer scope precedes one from an outer scope. Within the same lexical scope, later source declaration order precedes earlier source declaration order.
2. **Then global/current-module/imported candidates by descending numeric priority.**
3. For equal-priority global candidates, origin order is:
   1. declarations in the current logical module, later source declaration first;
   2. declarations in imported modules according to `ImportLinearization(currentModule)`; within each imported module, later source declaration first.
4. The same declaration identity reached through multiple public-import paths occurs only once, at its first origin position.

[instance.import-order]

`ImportLinearization(M)` is the deterministic depth-first preorder of `M`'s direct imports in source order:

1. visit each direct import from first to last as written in `M`;
2. when module `N` is first visited, append `N`;
3. then recursively visit `N`'s own direct imports in their source order;
4. an already visited logical module is skipped;
5. ordinary and `public import` participate identically in this search order; `public` affects re-export, not instance precedence.

Thus no filesystem order, package installation order, hash-map iteration order, or implementation-specific environment insertion order may affect instance selection.

The priority constants are fixed as:

~~~text
low     = 100
mid     = 500
default = 1000
high    = 10000
~~~

A source `instance` without explicit priority uses `default`.

#### Goal admissibility

[instance.goal]

The goal must reduce to an application of an admitted class declaration.

[instance.parameter-modes]

Every class parameter has one of three synthesis modes:

- `input` — the default;
- `out` — an output parameter;
- `semiOut` — a semi-output parameter.

Standard source does not expose `outParam` or `semiOutParam` declaration syntax. However, the pinned foundational classes used by Standard operators/coercions **do** have normative parameter-mode metadata. The exact mode table is `class_parameter_modes` in the Standard manifest.

Search readiness and matching are:

1. all `input` parameters must be sufficiently determined before candidate search begins; otherwise the problem is stuck/postponed;
2. `out` and `semiOut` parameters may be unresolved when search begins;
3. candidate selection first matches all `input` parameters;
4. a known `semiOut` goal parameter participates in candidate compatibility; an unknown `semiOut` parameter may be assigned only when the candidate determines a non-metavariable value for it;
5. an `out` goal parameter is ignored for candidate filtering; after a candidate and all recursive prerequisites succeed, the candidate-produced output is unified with the goal output, and a mismatch fails that branch;
6. ordinary parameters of the instance declaration itself are solved by `PS-UNIFY-v1`; instance-implicit parameters recursively invoke this search algorithm.

Standard search does not guess arbitrary input values.

[instance.parameter-mode-foundation]

The manifest fixes at least these non-input modes:

~~~text
HAdd/HSub/HMul/HDiv/HMod/HPow/HAppend/HShiftLeft/HShiftRight:
  input, input, out

Coe:
  semiOut, input

CoeOut:
  input, semiOut

CoeFun:
  input, out

CoeSort:
  input, out
~~~

All class parameters not listed by the manifest mode table are `input`.

#### Search

[instance.search]

For each candidate in order:

1. instantiate universe parameters freshly;
2. instantiate ordinary explicit/implicit instance parameters with fresh elaboration metavariables;
3. compare the candidate result class application with the goal using `[instance.parameter-modes]`:
   - unify `input` positions;
   - enforce known `semiOut` positions and require candidates to determine unknown `semiOut` positions;
   - defer `out` compatibility until the candidate branch otherwise succeeds;
4. recursively synthesize each instance-implicit prerequisite;
5. solve the candidate's remaining ordinary parameters with `PS-UNIFY-v1`;
6. assign/check `semiOut` results and then assign/check `out` results against the original goal;
7. if all checks succeed, return the candidate;
8. on branch failure, restore branch-local metavariable assignments and try the next candidate.

Cycles in the active search stack fail that branch. The first successful candidate wins.

#### Default instances

[instance.default]

The `default_instance` registry is consulted only by `[elab.defaulting-phase]`.

A fully specified class goal that ordinary instance synthesis exhausts is a failure and is **not** rescued merely because a default instance exists. Default instances are allowed to determine unresolved class parameters only during the explicit defaulting phase.

Candidate priority and equal-priority order are exactly `[instance.order]`.

#### Exclusions

[instance.excluded]

Standard ProofScript does not source-expose user `outParam`/`semiOutParam` declarations and does not depend on arbitrary tabled-search tuning options or environment state from unimported packages. Pinned foundational parameter modes in `[instance.parameter-modes]` are part of Standard semantics. Resource exhaustion fails explicitly.

The pinned Lean `SynthInstance` implementation remains an exact reference locator in Appendix I, but the normative Standard behavior is the smaller algorithm above.

### 22.10 Coercion insertion

[elab.coercion.insert]

ProofScript Standard uses a bounded coercion algorithm.

#### Registry

[coercion.registry]

The registry contains only visible instances of `Coe`, `CoeT`, `CoeSort`, and `CoeFun` from the fixed Standard manifest, imported modules, and current source declarations.

#### Ordinary coercion

[coercion.direct]

When `e : A` is checked against expected type `B`:

1. first try definitional equality `A ≡ B`;
2. otherwise attempt one direct `CoeT A e B`/ordinary coercion solution through `[elab.instance.synth]`;
3. require the resulting term's type to be definitionally equal to `B`;
4. otherwise fail the coercion attempt.

Standard does not perform arbitrary multi-hop coercion-chain search.

#### Coercion to function

[coercion.fun]

If source syntax requires application but the head is not a function, one `CoeFun` synthesis may be attempted. The result must reduce to a function type.

#### Coercion to sort

[coercion.sort]

When a term is required to denote a type/sort, one `CoeSort` synthesis may be attempted. The result must reduce to a sort.

#### Exclusions

[coercion.excluded]

Standard does not implicitly perform JavaScript conversions, TypeScript structural assignment, arbitrary runtime casts, automatic monad lifting, or arbitrary coercion chains. Lean's `autoLift` behavior is semantically fixed to **false** for Standard ProofScript.

### 22.11 Generalized field notation

[elab.field]

For `value.method(args...)`, field notation is resolved statically/type-directed:

1. elaborate `value`;
2. collect visible declarations whose final component is `method` and whose receiver parameter can accept the receiver type under ordinary definitional equality/bounded coercion;
3. use expected type information when it uniquely eliminates candidates;
4. require exactly one candidate;
5. elaborate as ordinary application with `value` supplied at the receiver position.

Dynamic property lookup, prototype search, and runtime `this` dispatch are not used.

### 22.12 Constructor shorthand

[elab.ctor-shorthand]

A shorthand such as `.some(x)` is accepted only when the expected type reduces to an admitted inductive family with exactly one visible constructor named `some`. Missing expected type or multiple remaining constructors rejects.

### 22.13 Rejection and implementation freedom

[elab.reject]

A conforming implementation may use different internal structures provided it follows the observable rules above, accepts/rejects the same source under the same profile/environment, and produces definitionally equivalent core meaning. Resource exhaustion MUST fail explicitly.

## 23. Computational and Runtime Semantics

PSCV preserves the distinction between logical meaning and executable representation.

### 23.1 Computational relevance

[runtime.relevance]

Every admitted declaration/expression is classified by its semantic role:

~~~text
SPEC   specification/model information
PROOF  proof/ghost information
EXEC   runtime-relevant computation
~~~

This classification may be inferred from types and contexts rather than written explicitly.

Proof and specification material may be referenced while establishing correctness, but runtime-observable behavior MUST NOT depend on material whose PSCV semantics require erasure.

### 23.2 Evaluation and reduction

[runtime.eval]

Source-level computation used by definitional equality is Chapter 17.

Backend execution may choose another strategy only when required source semantics are preserved.

### 23.3 Proof and ghost erasure

[runtime.proof-erasure]

Proofs in `Prop`, proof-only structure fields, admitted subtype evidence, and PSCV ghost state MAY be erased when computational irrelevance/noninterference is established.

[pscv.runtime.ghost-erasure]

Erasure MUST preserve PSCV observable executable behavior. If the compiler cannot prove or validate the required erasure relation for an artifact, PSCV verified emission fails.

### 23.4 Totality

[pscv.runtime.total]

Every reachable PSCV executable declaration MUST be total according to Chapter 18 and the selected verified effect semantics.

`partial` is not a PSCV runtime escape hatch.

### 23.5 Noncomputable declarations

[runtime.noncomputable]

A noncomputable declaration may exist in specification/proof reasoning but MUST NOT be required to produce runtime data in the verified executable closure.

### 23.6 Backend independence

[runtime.backend-independent]

Target representations MUST NOT redefine PSCV semantics.

In particular a backend MUST NOT silently reinterpret:

- `Nat` as floating JavaScript `number`;
- exact `Int` as host floating arithmetic;
- `String` as host-specific code-unit semantics when those differ;
- algebraic data as dynamic untyped objects without preserving constructor meaning;
- typed `Except` as arbitrary host exceptions;
- ProofScript functions as JavaScript `this`/prototype dispatch;
- proof/ghost fields as meaningful runtime payload.

### 23.7 Verified effect closure

[pscv.runtime.effect-closure]

A `VerifiedExecutableModule` records the admitted effect families reachable from every executable root.

An effect operation without an accepted `PSCV-VERIFY-v1` semantics is either:

- rejected under `pscv-closed-v1`; or
- classified as an explicit boundary under `pscv-boundary-v1`.

### 23.8 Foreign behavior

[runtime.foreign-boundary]

Foreign behavior is not proof evidence.

For each external binding used by a PSCV boundary build, the assurance evidence MUST identify:

- authored logical signature/model;
- runtime binding identity;
- assumption/evidence classification;
- exact dependency/provenance identity where available.

A `.d.ts`, C header, OpenAPI file, FFI signature, runtime test, or AI-generated model is not by itself a proof that the foreign implementation satisfies the model.

### 23.9 Verified executable handoff

[pscv.runtime.verified-handoff]

The verified code-generation pipeline has the conceptual type boundary:

~~~text
KernelAdmittedModule
      +
PSCV-CERT-v1
      |
      v
VerifiedExecutableModule
      |
      v
Erasure
      |
      v
VerifiedIR
      |
      v
Backend
~~~

A PSCV backend MUST NOT accept raw parsed source, unchecked elaborated source, open proof obligations, or merely “specified” declarations as a substitute for `VerifiedExecutableModule`.

### 23.10 Compilation assurance boundary

[pscv.runtime.compiler-assurance]

Source-level PSCV proof does not by itself prove that a backend implementation is semantics-preserving.

Assurance reports MUST distinguish at least:

~~~text
source logic: proved / not proved
compiler: unvalidated / tested / translation-validated / proved
foreign boundary: verified / validated / tested / assumed / unknown
provenance: recorded / reproducible / independently replayed
~~~

A PSCV language proof claim therefore remains honest even while compiler assurance is strengthened incrementally.

### 23.11 Operational limits

[runtime.exhaustion]

Resource exhaustion, timeouts, prover fuel, AI failure, SMT unknown, compiler limits, or unavailable external services MUST NOT be interpreted as logical success.

For a mandatory PSCV gate, inability to establish the required result is verification failure.

## 24. Standard Environment

`ps-standard-0.9-r3` is a closed source grammar plus a closed **initial Standard environment**. Imported source may contribute ordinary declarations and explicitly admitted semantic registrations, but unrelated installed packages do not affect parsing or elaboration.

### 24.1 Standard environment identity

[standard.identity]

~~~text
STD-ENV-PSCV-V1-L435RC3-RC1
Lean semantic pin:
  version: Lean 4.35.0-rc3
  commit: 470d5ce1400764999581fd26d5d72b00d990b0f4
ProofScript base surface:
  ps-0.9-r3
PSCV profile:
  pscv-v1 / PSCV-RC-v2
Registry manifest candidate:
  STD-ENV-PSCV-V1-L435RC3-RC1.json
Registry SHA-256:
  PENDING -- MUST be generated and frozen before final pscv-compiler-v1 conformance
~~~

Pinned Lean roots provide declaration/source provenance only. For this PSCV-RC-v2 design, the required Standard surface and registry policy are normative, while the concrete ordered `registry_snapshot` for Lean 4.35.0-rc3 is a **release-blocking generated artifact**. No implementation may claim final `pscv-compiler-v1` conformance until the candidate manifest is generated, provenance-validated, hashed, and frozen.


[standard.class-parameter-modes]

The final `STD-ENV-PSCV-V1-L435RC3-RC1.json` MUST contain the normative `class_parameter_modes` table used by Chapter 22 instance synthesis. Until that manifest is generated and frozen, this PSCV-RC-v2 design specifies the required algorithm and source provenance but does not authorize a final environment-conformance claim.

### 24.1A PSCV verification environment

[pscv.standard.verification-environment]

`pscv-v1` uses the PSCV-specific `STD-ENV-PSCV-V1-L435RC3-RC1` declaration/prover environment and a logically non-authoritative verification registry repinned to Lean 4.35.0-rc3.

The verification registry may index:

- checked function specification theorems;
- WP/effect instances and their law proofs;
- loop/iterator specification theorems;
- approved arithmetic/domain proof procedures;
- proof-producing plugins.

Rules:

1. every semantic theorem referenced by the registry must be an admitted declaration;
2. registry membership itself never proves the theorem;
3. ordinary dependencies cannot silently mutate the PSCV initial registry;
4. imported verified modules may contribute their exported specification theorems through deterministic module semantics;
5. the exact initial PSCV verification-registry manifest/digest MUST be frozen before an implementation claims final `pscv-compiler-v1` release conformance;
6. this PSCV-RC-v2 design does not fabricate a digest for a registry that has not yet been generated from an implementation.

This explicit “manifest still required” status is an implementation release gate, not permission for ambient Lean registrations.

### 24.1B Lean 4.35 intrinsic verification reference

[pscv.standard.lean435-verification]

Lean 4.35.0-rc3 is the pinned bootstrap/reference implementation for the intrinsic verification family used to validate PSCV lowering choices:

- `given`, `requires`, and `ensures` contract clauses;
- generated `f.spec` specification theorems;
- `vcgen` verification-condition generation;
- proof-only `assert`;
- loop `invariant` and `decreasing`;
- `erased`, `erased mut`, and erased monadic bindings used as verification-only state;
- weakest-precondition, Hoare-triple, frame, State/Reader/Except and exception-postcondition infrastructure in `Std.WP`.

The exact source locators are Appendix I.9. Upstream Lean reports this intrinsic source syntax as experimental. PSCV does **not** inherit that instability: `PSCV-VERIFY-v1` owns the normative meaning, and a future Lean RC/final release can change PSCV semantics only through a separately versioned PSCV profile/environment revision.

A conforming PSCV implementation MAY reuse the pinned Lean macro/elaborator/`vcgen` machinery as an untrusted proof producer. Final PSCV proof authority remains the kernel/checker; successful execution of the VC generator is never independent proof authority.

### 24.2 Standard notation and precedence

[standard.notation]

| Source | Kind | Prec. | Semantic target |
|---|---:|---:|---|
| `->`, `→` | R | 25 | Pi/non-dependent arrow |
| `∨`, `\/` | R | 30 | `Or` |
| `||` | L | 30 | Boolean `or` |
| `∧`, `/\\` | R | 35 | `And` |
| `&&` | L | 35 | Boolean `and` |
| `×` | R | 35 | `Prod` |
| `<`, `<=`, `≤`, `>`, `>=`, `≥` | N | 50 | `LT`/`LE`/`GT`/`GE` |
| `=` | N | 50 | `Eq` propositional equality |
| `≠` | N | 50 | `Not (Eq ...)` |
| `==` | N | 50 | `BEq.beq` Boolean equality |
| `!=` | N | 50 | pinned `bne`, definitionally `!(a == b)` |
| `+`, binary `-`, `++` | L | 65 | add/sub/append |
| `::` | R | 67 | `List.cons` |
| `*`, `/`, `%` | L | 70 | mul/div/mod |
| prefix `-` | prefix | 75 | negation |
| `<<<`, `>>>` | L | 75 | shifts |
| `^` | R | 80 | power |
| prefix `¬` | prefix | operand 40 | `Not` |
| prefix `!` | prefix | operand 40 | Boolean `not` |

Higher precedence binds more tightly. Parentheses override precedence. Field notation and parenthesized-call postfixes bind tighter than all infix operators.


[standard.equality-operators]

The four precedence-50 equality spellings are semantically distinct:

- `a = b` elaborates to `Eq a b : Prop`;
- `a ≠ b` elaborates to `Not (Eq a b) : Prop`;
- `a == b` elaborates through `BEq.beq` and has type `Bool`;
- `a != b` elaborates to the pinned `bne`, definitionally `!(a == b)`, and has type `Bool`.

`==`/`!=` therefore require the corresponding `BEq` synthesis path in `required_standard_surface`; `=`/`≠` do not.

No user-defined notation/infix/prefix/postfix declaration is permitted in Standard source.

### 24.3 Required Standard overloaded surface

[standard.required-surface]

This is the complete guaranteed overloaded operator/literal surface for Standard basis types. An operator/type combination not listed here is not guaranteed merely because Lean supports it.

| Surface ID | Guaranteed family | Required snapshot IDs |
|---|---|---|
| `Bool:!` | `Bool` | direct `Bool.not` |
| `Bool:!=` | `Bool × Bool` | `std.generic.beq-of-decidable`, `std.bool.decidableeq` |
| `Bool:&&` | `Bool` | direct `Bool.and` |
| `Bool:==` | `Bool × Bool` | `std.generic.beq-of-decidable`, `std.bool.decidableeq` |
| `Bool:||` | `Bool` | direct `Bool.or` |
| `Char:!=` | `Char × Char` | `std.generic.beq-of-decidable`, `std.char.decidableeq` |
| `Char:==` | `Char × Char` | `std.generic.beq-of-decidable`, `std.char.decidableeq` |
| `Fin:!=` | `Fin n × Fin n` | `std.generic.beq-of-decidable`, `std.fin.decidableeq` |
| `Fin:==` | `Fin n × Fin n` | `std.generic.beq-of-decidable`, `std.fin.decidableeq` |
| `Float32:!=` | `Float32 × Float32` | `std.float32.beq` |
| `Float32:*` | `Float32 × Float32` | `std.generic.hmul`, `std.float32.mul` |
| `Float32:+` | `Float32 × Float32` | `std.generic.hadd`, `std.float32.add` |
| `Float32:-` | `Float32 × Float32` | `std.generic.hsub`, `std.float32.sub` |
| `Float32:/` | `Float32 × Float32` | `std.generic.hdiv`, `std.float32.div` |
| `Float32:<` | `Float32 × Float32` | `std.float32.lt` |
| `Float32:<=` | `Float32 × Float32` | `std.float32.le` |
| `Float32:==` | `Float32 × Float32` | `std.float32.beq` |
| `Float32:>` | `Float32 × Float32` | `std.float32.lt` |
| `Float32:>=` | `Float32 × Float32` | `std.float32.le` |
| `Float32:literal` | `Float32` | `std.float32.ofnat`, `std.float32.ofscientific` |
| `Float32:prefix-` | `Float32` | `std.float32.neg` |
| `Float:!=` | `Float × Float` | `std.float.beq` |
| `Float:*` | `Float × Float` | `std.generic.hmul`, `std.float.mul` |
| `Float:+` | `Float × Float` | `std.generic.hadd`, `std.float.add` |
| `Float:-` | `Float × Float` | `std.generic.hsub`, `std.float.sub` |
| `Float:/` | `Float × Float` | `std.generic.hdiv`, `std.float.div` |
| `Float:<` | `Float × Float` | `std.float.lt` |
| `Float:<=` | `Float × Float` | `std.float.le` |
| `Float:==` | `Float × Float` | `std.float.beq` |
| `Float:>` | `Float × Float` | `std.float.lt` |
| `Float:>=` | `Float × Float` | `std.float.le` |
| `Float:literal` | `Float` | `std.float.ofnat`, `std.float.ofscientific` |
| `Float:prefix-` | `Float` | `std.float.neg` |
| `ISize:!=` | `ISize × ISize` | `std.generic.beq-of-decidable`, `std.isize.deq` |
| `ISize:%` | `ISize operands` | `std.generic.hmod`, `std.isize.mod` |
| `ISize:*` | `ISize operands` | `std.generic.hmul`, `std.isize.mul` |
| `ISize:+` | `ISize operands` | `std.generic.hadd`, `std.isize.add` |
| `ISize:-` | `ISize operands` | `std.generic.hsub`, `std.isize.sub` |
| `ISize:/` | `ISize operands` | `std.generic.hdiv`, `std.isize.div` |
| `ISize:<` | `ISize × ISize` | `std.isize.lt` |
| `ISize:<<<` | `ISize operands` | `std.generic.hshift-left`, `std.isize.shl` |
| `ISize:<=` | `ISize × ISize` | `std.isize.le` |
| `ISize:==` | `ISize × ISize` | `std.generic.beq-of-decidable`, `std.isize.deq` |
| `ISize:>` | `ISize × ISize` | `std.isize.lt` |
| `ISize:>=` | `ISize × ISize` | `std.isize.le` |
| `ISize:>>>` | `ISize operands` | `std.generic.hshift-right`, `std.isize.shr` |
| `ISize:^` | `ISize operands` | `std.generic.hpow`, `std.isize.pow` |
| `ISize:literal` | `ISize` | `std.isize.ofnat` |
| `ISize:prefix-` | `ISize` | `std.isize.neg` |
| `Int16:!=` | `Int16 × Int16` | `std.generic.beq-of-decidable`, `std.int16.deq` |
| `Int16:%` | `Int16 operands` | `std.generic.hmod`, `std.int16.mod` |
| `Int16:*` | `Int16 operands` | `std.generic.hmul`, `std.int16.mul` |
| `Int16:+` | `Int16 operands` | `std.generic.hadd`, `std.int16.add` |
| `Int16:-` | `Int16 operands` | `std.generic.hsub`, `std.int16.sub` |
| `Int16:/` | `Int16 operands` | `std.generic.hdiv`, `std.int16.div` |
| `Int16:<` | `Int16 × Int16` | `std.int16.lt` |
| `Int16:<<<` | `Int16 operands` | `std.generic.hshift-left`, `std.int16.shl` |
| `Int16:<=` | `Int16 × Int16` | `std.int16.le` |
| `Int16:==` | `Int16 × Int16` | `std.generic.beq-of-decidable`, `std.int16.deq` |
| `Int16:>` | `Int16 × Int16` | `std.int16.lt` |
| `Int16:>=` | `Int16 × Int16` | `std.int16.le` |
| `Int16:>>>` | `Int16 operands` | `std.generic.hshift-right`, `std.int16.shr` |
| `Int16:^` | `Int16 operands` | `std.generic.hpow`, `std.int16.pow` |
| `Int16:literal` | `Int16` | `std.int16.ofnat` |
| `Int16:prefix-` | `Int16` | `std.int16.neg` |
| `Int32:!=` | `Int32 × Int32` | `std.generic.beq-of-decidable`, `std.int32.deq` |
| `Int32:%` | `Int32 operands` | `std.generic.hmod`, `std.int32.mod` |
| `Int32:*` | `Int32 operands` | `std.generic.hmul`, `std.int32.mul` |
| `Int32:+` | `Int32 operands` | `std.generic.hadd`, `std.int32.add` |
| `Int32:-` | `Int32 operands` | `std.generic.hsub`, `std.int32.sub` |
| `Int32:/` | `Int32 operands` | `std.generic.hdiv`, `std.int32.div` |
| `Int32:<` | `Int32 × Int32` | `std.int32.lt` |
| `Int32:<<<` | `Int32 operands` | `std.generic.hshift-left`, `std.int32.shl` |
| `Int32:<=` | `Int32 × Int32` | `std.int32.le` |
| `Int32:==` | `Int32 × Int32` | `std.generic.beq-of-decidable`, `std.int32.deq` |
| `Int32:>` | `Int32 × Int32` | `std.int32.lt` |
| `Int32:>=` | `Int32 × Int32` | `std.int32.le` |
| `Int32:>>>` | `Int32 operands` | `std.generic.hshift-right`, `std.int32.shr` |
| `Int32:^` | `Int32 operands` | `std.generic.hpow`, `std.int32.pow` |
| `Int32:literal` | `Int32` | `std.int32.ofnat` |
| `Int32:prefix-` | `Int32` | `std.int32.neg` |
| `Int64:!=` | `Int64 × Int64` | `std.generic.beq-of-decidable`, `std.int64.deq` |
| `Int64:%` | `Int64 operands` | `std.generic.hmod`, `std.int64.mod` |
| `Int64:*` | `Int64 operands` | `std.generic.hmul`, `std.int64.mul` |
| `Int64:+` | `Int64 operands` | `std.generic.hadd`, `std.int64.add` |
| `Int64:-` | `Int64 operands` | `std.generic.hsub`, `std.int64.sub` |
| `Int64:/` | `Int64 operands` | `std.generic.hdiv`, `std.int64.div` |
| `Int64:<` | `Int64 × Int64` | `std.int64.lt` |
| `Int64:<<<` | `Int64 operands` | `std.generic.hshift-left`, `std.int64.shl` |
| `Int64:<=` | `Int64 × Int64` | `std.int64.le` |
| `Int64:==` | `Int64 × Int64` | `std.generic.beq-of-decidable`, `std.int64.deq` |
| `Int64:>` | `Int64 × Int64` | `std.int64.lt` |
| `Int64:>=` | `Int64 × Int64` | `std.int64.le` |
| `Int64:>>>` | `Int64 operands` | `std.generic.hshift-right`, `std.int64.shr` |
| `Int64:^` | `Int64 operands` | `std.generic.hpow`, `std.int64.pow` |
| `Int64:literal` | `Int64` | `std.int64.ofnat` |
| `Int64:prefix-` | `Int64` | `std.int64.neg` |
| `Int8:!=` | `Int8 × Int8` | `std.generic.beq-of-decidable`, `std.int8.deq` |
| `Int8:%` | `Int8 operands` | `std.generic.hmod`, `std.int8.mod` |
| `Int8:*` | `Int8 operands` | `std.generic.hmul`, `std.int8.mul` |
| `Int8:+` | `Int8 operands` | `std.generic.hadd`, `std.int8.add` |
| `Int8:-` | `Int8 operands` | `std.generic.hsub`, `std.int8.sub` |
| `Int8:/` | `Int8 operands` | `std.generic.hdiv`, `std.int8.div` |
| `Int8:<` | `Int8 × Int8` | `std.int8.lt` |
| `Int8:<<<` | `Int8 operands` | `std.generic.hshift-left`, `std.int8.shl` |
| `Int8:<=` | `Int8 × Int8` | `std.int8.le` |
| `Int8:==` | `Int8 × Int8` | `std.generic.beq-of-decidable`, `std.int8.deq` |
| `Int8:>` | `Int8 × Int8` | `std.int8.lt` |
| `Int8:>=` | `Int8 × Int8` | `std.int8.le` |
| `Int8:>>>` | `Int8 operands` | `std.generic.hshift-right`, `std.int8.shr` |
| `Int8:^` | `Int8 operands` | `std.generic.hpow`, `std.int8.pow` |
| `Int8:literal` | `Int8` | `std.int8.ofnat` |
| `Int8:prefix-` | `Int8` | `std.int8.neg` |
| `Int:!=` | `Int × Int` | `std.generic.beq-of-decidable`, `std.int.decidableeq` |
| `Int:%` | `Int × Int` | `std.generic.hmod`, `std.int.mod` |
| `Int:*` | `Int × Int` | `std.generic.hmul`, `std.int.mul` |
| `Int:+` | `Int × Int` | `std.generic.hadd`, `std.int.add` |
| `Int:-` | `Int × Int` | `std.generic.hsub`, `std.int.sub` |
| `Int:/` | `Int × Int` | `std.generic.hdiv`, `std.int.div` |
| `Int:<` | `Int × Int` | `std.int.lt` |
| `Int:<=` | `Int × Int` | `std.int.le` |
| `Int:==` | `Int × Int` | `std.generic.beq-of-decidable`, `std.int.decidableeq` |
| `Int:>` | `Int × Int` | `std.int.lt` |
| `Int:>=` | `Int × Int` | `std.int.le` |
| `Int:^` | `Int × Int` | `std.generic.hpow`, `std.generic.pow-nat`, `std.int.natpow` |
| `Int:literal` | `Int` | `std.int.ofnat` |
| `Int:prefix-` | `Int` | `std.int.neg` |
| `List:!=` | `List α × List α` (requires BEq α) | `std.list.beq` |
| `List:++` | `List α × List α` | `std.generic.happend`, `std.list.append` |
| `List:==` | `List α × List α` (requires BEq α) | `std.list.beq` |
| `Nat:!=` | `Nat × Nat` | `std.generic.beq-of-decidable`, `std.nat.decidableeq` |
| `Nat:%` | `Nat × Nat` | `std.generic.hmod`, `std.nat.mod` |
| `Nat:*` | `Nat × Nat` | `std.generic.hmul`, `std.nat.mul` |
| `Nat:+` | `Nat × Nat` | `std.generic.hadd`, `std.nat.add` |
| `Nat:-` | `Nat × Nat` | `std.generic.hsub`, `std.nat.sub` |
| `Nat:/` | `Nat × Nat` | `std.generic.hdiv`, `std.nat.div` |
| `Nat:<` | `Nat × Nat` | `std.nat.lt` |
| `Nat:<=` | `Nat × Nat` | `std.nat.le` |
| `Nat:==` | `Nat × Nat` | `std.generic.beq-of-decidable`, `std.nat.decidableeq` |
| `Nat:>` | `Nat × Nat` | `std.nat.lt` |
| `Nat:>=` | `Nat × Nat` | `std.nat.le` |
| `Nat:^` | `Nat × Nat` | `std.generic.hpow`, `std.generic.pow-nat`, `std.nat.natpow` |
| `Nat:literal` | `Nat` | `std.nat.ofnat` |
| `Option:!=` | `Option α × Option α` (requires BEq α) | `std.option.beq` |
| `Option:==` | `Option α × Option α` (requires BEq α) | `std.option.beq` |
| `Prod:!=` | `Prod α β × Prod α β` (requires BEq α and BEq β) | `std.prod.beq` |
| `Prod:==` | `Prod α β × Prod α β` (requires BEq α and BEq β) | `std.prod.beq` |
| `String:!=` | `String × String` | `std.generic.beq-of-decidable`, `std.string.decidableeq` |
| `String:++` | `String × String` | `std.generic.happend`, `std.string.append` |
| `String:==` | `String × String` | `std.generic.beq-of-decidable`, `std.string.decidableeq` |
| `UInt16:!=` | `UInt16 × UInt16` | `std.generic.beq-of-decidable`, `std.uint16.deq` |
| `UInt16:%` | `UInt16 operands` | `std.generic.hmod`, `std.uint16.mod` |
| `UInt16:*` | `UInt16 operands` | `std.generic.hmul`, `std.uint16.mul` |
| `UInt16:+` | `UInt16 operands` | `std.generic.hadd`, `std.uint16.add` |
| `UInt16:-` | `UInt16 operands` | `std.generic.hsub`, `std.uint16.sub` |
| `UInt16:/` | `UInt16 operands` | `std.generic.hdiv`, `std.uint16.div` |
| `UInt16:<` | `UInt16 × UInt16` | `std.uint16.lt` |
| `UInt16:<<<` | `UInt16 operands` | `std.generic.hshift-left`, `std.uint16.shl` |
| `UInt16:<=` | `UInt16 × UInt16` | `std.uint16.le` |
| `UInt16:==` | `UInt16 × UInt16` | `std.generic.beq-of-decidable`, `std.uint16.deq` |
| `UInt16:>` | `UInt16 × UInt16` | `std.uint16.lt` |
| `UInt16:>=` | `UInt16 × UInt16` | `std.uint16.le` |
| `UInt16:>>>` | `UInt16 operands` | `std.generic.hshift-right`, `std.uint16.shr` |
| `UInt16:^` | `UInt16 operands` | `std.generic.hpow`, `std.uint16.pow` |
| `UInt16:literal` | `UInt16` | `std.uint16.ofnat` |
| `UInt16:prefix-` | `UInt16` | `std.uint16.neg` |
| `UInt32:!=` | `UInt32 × UInt32` | `std.generic.beq-of-decidable`, `std.uint32.deq` |
| `UInt32:%` | `UInt32 operands` | `std.generic.hmod`, `std.uint32.mod` |
| `UInt32:*` | `UInt32 operands` | `std.generic.hmul`, `std.uint32.mul` |
| `UInt32:+` | `UInt32 operands` | `std.generic.hadd`, `std.uint32.add` |
| `UInt32:-` | `UInt32 operands` | `std.generic.hsub`, `std.uint32.sub` |
| `UInt32:/` | `UInt32 operands` | `std.generic.hdiv`, `std.uint32.div` |
| `UInt32:<` | `UInt32 × UInt32` | `std.uint32.lt` |
| `UInt32:<<<` | `UInt32 operands` | `std.generic.hshift-left`, `std.uint32.shl` |
| `UInt32:<=` | `UInt32 × UInt32` | `std.uint32.le` |
| `UInt32:==` | `UInt32 × UInt32` | `std.generic.beq-of-decidable`, `std.uint32.deq` |
| `UInt32:>` | `UInt32 × UInt32` | `std.uint32.lt` |
| `UInt32:>=` | `UInt32 × UInt32` | `std.uint32.le` |
| `UInt32:>>>` | `UInt32 operands` | `std.generic.hshift-right`, `std.uint32.shr` |
| `UInt32:^` | `UInt32 operands` | `std.generic.hpow`, `std.uint32.pow` |
| `UInt32:literal` | `UInt32` | `std.uint32.ofnat` |
| `UInt32:prefix-` | `UInt32` | `std.uint32.neg` |
| `UInt64:!=` | `UInt64 × UInt64` | `std.generic.beq-of-decidable`, `std.uint64.deq` |
| `UInt64:%` | `UInt64 operands` | `std.generic.hmod`, `std.uint64.mod` |
| `UInt64:*` | `UInt64 operands` | `std.generic.hmul`, `std.uint64.mul` |
| `UInt64:+` | `UInt64 operands` | `std.generic.hadd`, `std.uint64.add` |
| `UInt64:-` | `UInt64 operands` | `std.generic.hsub`, `std.uint64.sub` |
| `UInt64:/` | `UInt64 operands` | `std.generic.hdiv`, `std.uint64.div` |
| `UInt64:<` | `UInt64 × UInt64` | `std.uint64.lt` |
| `UInt64:<<<` | `UInt64 operands` | `std.generic.hshift-left`, `std.uint64.shl` |
| `UInt64:<=` | `UInt64 × UInt64` | `std.uint64.le` |
| `UInt64:==` | `UInt64 × UInt64` | `std.generic.beq-of-decidable`, `std.uint64.deq` |
| `UInt64:>` | `UInt64 × UInt64` | `std.uint64.lt` |
| `UInt64:>=` | `UInt64 × UInt64` | `std.uint64.le` |
| `UInt64:>>>` | `UInt64 operands` | `std.generic.hshift-right`, `std.uint64.shr` |
| `UInt64:^` | `UInt64 operands` | `std.generic.hpow`, `std.uint64.pow` |
| `UInt64:literal` | `UInt64` | `std.uint64.ofnat` |
| `UInt64:prefix-` | `UInt64` | `std.uint64.neg` |
| `UInt8:!=` | `UInt8 × UInt8` | `std.generic.beq-of-decidable`, `std.uint8.deq` |
| `UInt8:%` | `UInt8 operands` | `std.generic.hmod`, `std.uint8.mod` |
| `UInt8:*` | `UInt8 operands` | `std.generic.hmul`, `std.uint8.mul` |
| `UInt8:+` | `UInt8 operands` | `std.generic.hadd`, `std.uint8.add` |
| `UInt8:-` | `UInt8 operands` | `std.generic.hsub`, `std.uint8.sub` |
| `UInt8:/` | `UInt8 operands` | `std.generic.hdiv`, `std.uint8.div` |
| `UInt8:<` | `UInt8 × UInt8` | `std.uint8.lt` |
| `UInt8:<<<` | `UInt8 operands` | `std.generic.hshift-left`, `std.uint8.shl` |
| `UInt8:<=` | `UInt8 × UInt8` | `std.uint8.le` |
| `UInt8:==` | `UInt8 × UInt8` | `std.generic.beq-of-decidable`, `std.uint8.deq` |
| `UInt8:>` | `UInt8 × UInt8` | `std.uint8.lt` |
| `UInt8:>=` | `UInt8 × UInt8` | `std.uint8.le` |
| `UInt8:>>>` | `UInt8 operands` | `std.generic.hshift-right`, `std.uint8.shr` |
| `UInt8:^` | `UInt8 operands` | `std.generic.hpow`, `std.uint8.pow` |
| `UInt8:literal` | `UInt8` | `std.uint8.ofnat` |
| `UInt8:prefix-` | `UInt8` | `std.uint8.neg` |
| `USize:!=` | `USize × USize` | `std.generic.beq-of-decidable`, `std.usize.deq` |
| `USize:%` | `USize operands` | `std.generic.hmod`, `std.usize.mod` |
| `USize:*` | `USize operands` | `std.generic.hmul`, `std.usize.mul` |
| `USize:+` | `USize operands` | `std.generic.hadd`, `std.usize.add` |
| `USize:-` | `USize operands` | `std.generic.hsub`, `std.usize.sub` |
| `USize:/` | `USize operands` | `std.generic.hdiv`, `std.usize.div` |
| `USize:<` | `USize × USize` | `std.usize.lt` |
| `USize:<<<` | `USize operands` | `std.generic.hshift-left`, `std.usize.shl` |
| `USize:<=` | `USize × USize` | `std.usize.le` |
| `USize:==` | `USize × USize` | `std.generic.beq-of-decidable`, `std.usize.deq` |
| `USize:>` | `USize × USize` | `std.usize.lt` |
| `USize:>=` | `USize × USize` | `std.usize.le` |
| `USize:>>>` | `USize operands` | `std.generic.hshift-right`, `std.usize.shr` |
| `USize:^` | `USize operands` | `std.generic.hpow`, `std.usize.pow` |
| `USize:literal` | `USize` | `std.usize.ofnat` |
| `USize:prefix-` | `USize` | `std.usize.neg` |

[standard.surface-snapshot-closure]

Every `required_registry_ids` element in this matrix MUST occur exactly once in the final frozen `registry_snapshot`. A Standard toolchain MUST fail its environment self-check rather than claim `STD-ENV-PSCV-V1-L435RC3-RC1` when this invariant does not hold.

Canonical positive examples in this reference MUST use only listed operator/type combinations.

### 24.4 Grammar registrations

[standard.grammar]

The Standard parser registry consists exactly of the ProofScript-owned productions in Appendix A, mapped parser productions in Appendix I, and fixed Standard prover grammar in Chapter 20. Imports MUST NOT add parser categories, syntax declarations, macros, tactic parsers, or notation to Standard source.

### 24.5 Fixed semantic attributes

[standard.attributes]

The complete Standard user-written attribute surface is:

~~~text
simp
instance
default_instance
~~~

No other attribute is Standard source syntax.

[standard.attribute-semantics]

An attribute is applied only after its declaration has otherwise elaborated successfully. Attribute registration cannot make an ill-typed declaration valid.

[standard.attribute-simp]

Plain `@[simp]` uses mapping `LEAN-ATTR-SIMP`.

For Standard source:

- if the accepted declaration has a proposition type, the pinned handler preprocesses/registers it as a simplification theorem;
- if it is an ordinary definition accepted by the handler, the pinned handler registers the declaration/equation information for simplifier unfolding;
- if it is neither an admissible proposition nor an admissible definition, applying `@[simp]` rejects;
- Standard syntax exposes no simp-attribute inversion, pre/post, priority, custom simp-set, or simproc-registration modifiers.

Successful registration contributes its resulting simp entries through `[module.registration-propagation]` and `[standard.registration-order]`.

[standard.attribute-instance]

`@[instance]` uses mapping `LEAN-ATTR-INSTANCE`.

The already accepted declaration must be registrable as an instance for an admitted type class. The registration uses the explicit Standard priority when supplied and `default = 1000` otherwise. Failure of registration rejects the attributed declaration rather than silently ignoring the attribute.

[standard.attribute-default-instance]

`@[default_instance]` uses mapping `LEAN-ATTR-DEFAULT-INSTANCE`.

After reducing the declaration's leading Pi telescope, the resulting target must have the form:

~~~text
C args...
~~~

where `C` is an admitted type class. Otherwise the attribute rejects.

The attribute is global-only in Standard. It inserts the declaration into the default-instance registry using the explicit priority or the handler's Standard default. That registry is consulted only by `[elab.defaulting-phase]`.

[standard.attribute-boundary]

`inline`, `macro_inline`, `reducible`, `irreducible`, `deprecated`, `inherit_doc`, `pp_nodot`, arbitrary attribute handlers, and extension-defined attributes are **not** `ps-standard-0.9-r3` source syntax.

- code-generation/inlining controls belong to compiler/tooling specifications;
- documentation/pretty-printer annotations belong to tooling;
- additional transparency controls belong to an explicit compatibility/extension profile.

Standard source transparency is completely expressed by the declaration forms `def`, `abbrev`, and `opaque` plus Chapter 17; it does not require source `@[reducible]`/`@[irreducible]`.

### 24.6 Closed source-observable option state

[standard.options]

`set_option` is not Standard program syntax. `ps-standard-0.9-r3` has no user-settable source-observable elaboration or tactic options.

The Standard semantic option state is exactly:

| Option key | Fixed value |
|---|---|
| `autoImplicit` | `false` |
| `autoLift` | `false` |
| `unifier` | `PS-UNIFY-v1` |
| `unifier.constraintOrder` | `FIFO` |
| `unifier.higherOrderSearch` | `false` except pattern assignment |
| `instanceSearch` | Chapter 22.9 deterministic algorithm |
| `defaulting` | `[elab.defaulting-phase]` over normative `default_instance` registry |
| `coercionSearch` | Chapter 22.10 bounded direct algorithm |
| `tactic.semicolon` | `false` |
| `tactic.bullets` | `false` |
| `tactic.caseSyntax` | `false` |
| `tactic.locationSyntax` | `false` |
| `tactic.configSyntax` | `false` |
| `simp.registry` | exact frozen RC3 manifest snapshot (release-blocking) |
| `simproc.registry` | exact frozen RC3 manifest snapshot (release-blocking) |
| `ext.registry` | exact frozen RC3 manifest snapshot (release-blocking) |
| `grind.registry` | exact frozen RC3 manifest snapshot (release-blocking) |
| `exactSearch.config` | pinned default algorithm with no source config syntax |
| `omega.config` | pinned default algorithm with no source config syntax |
| `grind.config` | pinned default algorithm with no source config syntax |
| `resourceExhaustion` | explicit operational failure; never semantic success/failure evidence |

[standard.options-catchall]

Any Lean/compiler/tactic option not listed above is **not part of Standard source semantics**. An implementation may expose implementation/tooling controls only if changing them cannot change:

- parsing;
- source acceptance/rejection;
- selected name/instance/coercion;
- resulting core term up to definitional equality;
- theorem/proof acceptance.

If an otherwise hidden option changes one of those observables, the implementation is nonconforming unless that option is added to a newly versioned Standard environment identity.


### 24.7 Instance/default-instance registries

[standard.instances]

Once the release-blocking RC3 manifest is generated and frozen, the initial ordered instance/default-instance registries are exactly its `registry_snapshot.instances` and `registry_snapshot.default_instances`. The active program may extend them only as Chapter 22.9 permits. Before that freeze, an implementation MUST NOT claim final PSCV environment conformance.

Default-instance entries have their own manifest IDs and an `instance_id` field referencing the corresponding ordinary instance registration; this avoids duplicate semantic registration identities while preserving exact defaulting order.

### 24.8 Coercion registry

[standard.coercions]

Once the RC3 manifest is frozen, the initial coercion registry is exactly its `registry_snapshot.coercions`; active source may extend it only as Chapter 22.10 permits.

### 24.9 Simplifier registry

[standard.simp]

Once the RC3 manifest is frozen, the initial simplifier theorem registry is exactly `registry_snapshot.simp`; the initial simproc registry is exactly `registry_snapshot.simprocs`. The active environment may add visible imported/current `[simp]` theorems, but Standard source cannot register new simproc handlers. Unlisted root-closure registrations do not contribute.

`simp only` begins from kernel-required definitional reductions plus explicitly supplied simp arguments rather than the whole Standard simp theorem set.


[standard.registration-order]

For every Standard registry that source may extend:

1. initial entries appear in the exact order of the corresponding manifest array;
2. imported exported registrations follow `[module.registration-propagation]`;
3. within one imported module, registration order is source declaration order;
4. current-module registrations are appended in source declaration order;
5. removing/adding/reordering an ordinary import may therefore change the active registry only through these specified rules.

Instance/default-instance candidate selection additionally applies the priority/newest-first rules in Chapter 22.9; this registration order supplies the deterministic declaration order used there.

[standard.simp-intrinsics]

`registry_snapshot.simprocs` enumerates **environment-registered** simprocs only. Kernel/whnf reductions and simplifier procedures built directly into the exact pinned `LEAN-PROVER-SIMP` implementation are algorithm intrinsics, not ambient registry entries.

With the current manifest, the environment simproc array is empty. A conforming implementation MUST NOT import additional environment simprocs from unrelated Lean packages or the Lean root closure merely because the pinned Lean installation contains them.

### 24.10 Extensionality registry

[standard.ext]

Once the RC3 manifest is frozen, Standard `ext` uses exactly `registry_snapshot.ext`. `ext` is not a Standard user attribute in this edition, so ordinary Standard source cannot add global extensionality registrations.

### 24.11 Grind registry

[standard.grind]

Once the RC3 manifest is frozen, Standard `grind` uses exactly `registry_snapshot.grind` plus the pinned grind implementation procedures. Standard source cannot introduce new grind registration attributes.

### 24.12 Omega

[standard.omega]

`omega` is pinned to the Lean 4.35.0-rc3 locator in Appendix I and runs with Standard-fixed options. User source cannot replace or extend it.

### 24.13 Classical proof mode

[standard.classical]

`classical` enables pinned classical proof-construction declarations for the current proof scope. It does not change the kernel theory.

### 24.14 Tooling boundary

[standard.tooling-boundary]

The following are tooling/extensible-profile commands, not Standard program declarations:

~~~text
#check
#print
#reduce
#eval
set_option
~~~

### 24.15 Reproducibility

[standard.reproducible]

Two implementations claiming `ps-0.9-r3`, `ps-standard-0.9-r3`, and `STD-ENV-PSCV-V1-L435RC3-RC1` MUST provide semantically equivalent initial notation, instance, coercion, simp, ext, grind, tactic, and basic-type environments. A distribution may use a generated/precompiled registry only when its canonical `STD-ENV-PSCV-V1-L435RC3-RC1.json` digest equals the normative Appendix-K digest and its behavior satisfies the construction rule.

## 25. Basic Propositions and Logical Basis

This chapter distinguishes the core type theory from Standard proposition declarations.

### 25.1 Core logical forms

[logic.core]

| Form | Ownership | Exact authority |
|---|---|---|
| `Prop` | kernel/core | `[type.sort]`, `LEAN-CORE-SORT` |
| `Eq` / `=` | kernel-initialized equality family | `LEAN-CORE-EQ` |
| dependent `forall` / `∀` | Pi type with codomain in `Prop` | `[type.pi.form]`, `LEAN-TERM-FORALL` |
| proof irrelevance | kernel definitional equality | `[defeq.proof-irrelevance]` |
| quotient primitives | kernel logical foundation | `LEAN-CORE-QUOT` |

### 25.2 Standard proposition declarations

[logic.standard]

| Source form | Declaration/family | Ownership |
|---|---|---|
| `True` | `True` | Standard prelude inductive proposition |
| `False` | `False` | Standard prelude inductive proposition |
| `P ∧ Q` | `And P Q` | Standard prelude inductive proposition |
| `P ∨ Q` | `Or P Q` | Standard prelude inductive proposition |
| `¬ P` | `Not P` | Standard prelude definition |
| `exists x : A, P x` / `∃` | `Exists` | Standard existential proposition |
| `P -> Q` / `P → Q` | non-dependent Pi | core Pi semantics |

Their exact pinned source locator is `LEAN-LOGIC-PRELUDE` in Appendix I.

### 25.3 Constructive default

[logic.constructive]

ProofScript is constructive by default. Classical proof construction enters only through explicitly admitted classical declarations/commands such as `classical` and its pinned Standard environment.

### 25.4 Axioms

[logic.axiom]

An `axiom` declaration introduces a trusted constant with no body.

[logic.axiom-type]

For:

~~~text
axiom c (parameters...) : A
~~~

the parameter telescope and `A` MUST be well formed, with `A : Sort u` for some universe level `u`.

- if `A : Prop`, `c` is an explicit logical proposition assumption/proof constant;
- if `A : Type u` (or another admitted sort), `c` is an explicit trusted data/type-level constant assumption.

No proof or computational body is checked for the declaration itself. Every use therefore carries that axiom dependency in the trusted environment.

An axiom is not identified with a proved theorem or a definition, and it never gains definitional reduction behavior.

### 25.5 Boolean distinction

[logic.bool-distinct]

`Bool` is a data type and `Prop` is a proposition sort. Boolean connectives/equality do not automatically produce proofs without an explicit theorem/decidability bridge.

## 26. Basic Types

This chapter is the complete `ps-standard-0.9-r3` basis-type registry. Other libraries/source may define more types, but those are not required Standard basis types.

### 26.1 Registry

[basic-types.registry]

| Type/family | Standard status | Semantic category | Exact locator |
|---|---|---|---|
| `Unit` | required | one-constructor inductive | `LEAN-TYPE-UNIT` |
| `Bool` | required | two-constructor inductive | `LEAN-TYPE-BOOL` |
| `Nat` | required | natural-number inductive/kernel-optimized basis | `LEAN-TYPE-NAT` |
| `Int` | required | signed integer data family | `LEAN-TYPE-INT` |
| `UInt8`, `UInt16`, `UInt32`, `UInt64`, `USize` | required | fixed/word unsigned integers | `LEAN-TYPE-UINT-FAMILY` |
| `Int8`, `Int16`, `Int32`, `Int64`, `ISize` | required | fixed/word signed integers | `LEAN-TYPE-SINT-FAMILY` |
| `Float`, `Float32` | required | pinned floating families | `LEAN-TYPE-FLOAT` |
| `Char` | required | character family | `LEAN-TYPE-CHAR` |
| `String` | required | pinned string family | `LEAN-TYPE-STRING` |
| `ByteArray` | required | byte-sequence family | `LEAN-TYPE-BYTEARRAY` |
| `Prod α β` / tuples | required | product inductive | `LEAN-TYPE-PROD` |
| `Sum α β` | required | sum inductive | `LEAN-TYPE-SUM` |
| `Option α` | required | optional-value inductive | `LEAN-TYPE-OPTION` |
| `Except ε α` | required | typed result/error inductive | `LEAN-TYPE-EXCEPT` |
| `List α` | required | recursive list inductive | `LEAN-TYPE-LIST` |
| `Array α` | required | pinned array abstraction | `LEAN-TYPE-ARRAY` |
| `Fin n` | required | bounded natural family | `LEAN-TYPE-FIN` |
| `Subtype p` / `{x // p x}` | required | value plus proof family | `LEAN-TYPE-SUBTYPE` |

### 26.2 `Nat`

[type.nat]

`Nat` denotes exact nonnegative natural numbers. Subtraction truncates at zero; division/remainder use pinned `Nat` definitions; JavaScript `number` does not define its semantics.

### 26.3 `Int`

[type.int]

`Int` denotes exact signed integers under the pinned family.

### 26.4 Fixed-width and target-word integers

[type.fixed-int]

The exact required registry is:

~~~text
UInt8 UInt16 UInt32 UInt64 USize
Int8 Int16 Int32 Int64 ISize
~~~

Each fixed-width family preserves width/signedness. `USize`/`ISize` target-word assumptions belong to the backend target profile, while source operations/conversions must preserve pinned semantics for that target width.

[type.fixed-int-literals]

Fixed-width `OfNat` semantics are the pinned Lean semantics: source numeric literals are reduced modulo the type's width; signed fixed-width families interpret the resulting bit pattern according to their pinned signed representation. No overflow diagnostic is implied merely by the literal exceeding the nominal range.


### 26.5 Floating point

[type.float]

`Float` and `Float32` preserve pinned NaN, infinities, signed-zero, rounding, and operation behavior. They are distinct from exact `Nat`/`Int`.

### 26.6 `Bool`

[type.bool]

`Bool` has `true` and `false` and is distinct from `Prop`. Boolean operators use the fixed Standard notation/instance environment.

### 26.7 `Char`

[type.char]

`Char` and character literal semantics are pinned by `LEAN-TYPE-CHAR` / `LEAN-LEX-CHAR`.

### 26.8 `String`

[type.string]

`String` uses the pinned Lean semantic family. Backend UTF-16/UTF-8 representation does not redefine source semantics.

### 26.9 `ByteArray`

[type.bytearray]

`ByteArray` is distinct from `String`, `Array Char`, and arbitrary foreign buffers.

### 26.10 `Unit`

[type.unit]

`Unit` has exactly one admitted value/constructor in the Standard family.

### 26.11 Products and tuples

[type.prod]

`Prod α β` is the binary product family. Tuple syntax elaborates to nested products according to Appendix A.

### 26.12 `Sum`

[type.sum]

`Sum α β` is the Standard two-way algebraic sum.

### 26.13 `Option`

[type.option]

`Option α` is explicit algebraic presence/absence. `.none` is not JavaScript `null`/`undefined`.

### 26.14 `Except`

[type.except]

`Except ε α` is an explicit typed result/error family. Arbitrary host exceptions do not automatically inhabit `ε`.

### 26.15 `List`

[type.list]

`List α` is the Standard recursive list family and is distinct from `Array α`.

### 26.16 `Array`

[type.array]

`Array α` is the pinned Standard array family. Detailed convenience APIs are library-owned.

### 26.17 `Fin`

[type.fin]

`Fin n` carries a type-level bound indexed by `n`; it is not merely a runtime integer check.

### 26.18 Subtypes

[type.subtype]

A subtype pairs a value with proof of a proposition according to `LEAN-TYPE-SUBTYPE`; it is not a TypeScript brand.

### 26.19 Boolean versus propositional equality

[type.equality-kinds]

`x = y` is propositional equality. `x == y` is Boolean-valued equality when Standard resolves a `BEq` instance. They are distinct semantic categories.

## 27. Standard Collections and Library Boundary

### 27.1 Coverage status

The supplied language/planning material specifies the semantic status of several basis types and collections and defines what libraries are allowed to add, but it does **not** provide a complete Standard Library API catalog. This reference therefore records only the library semantics and ownership supported by the source material. A future complete Standard Library section may be incorporated into this same reference (or generated as API subpages) once the library's actual public declarations and contracts are available; they must not be invented by this document.


### List


Example:

~~~proofscript
function length {α: Type}(xs: List α): Nat := {
  match xs with {
    | .nil => 0
    | .cons _ rest => 1 + length(rest)
  }
}
~~~

<code>List</code> is semantically distinct from <code>Array</code>.

---


### Array


<code>Array α</code> is a separate Standard-library data family. Its language-facing identity is pinned by `LEAN-TYPE-ARRAY`; detailed API semantics remain library-owned.

It is not interchangeable with List merely because both may be iterable collections.

---


### Standard libraries versus language features


A capability can be part of the ProofScript user experience without being compiler-core syntax.

Typical library-owned families include:

- collections;
- codecs;
- parsers;
- application effects;
- resources;
- streams;
- theorem libraries;
- proof libraries;
- foreign-interface wrappers.

A library can add:

- types;
- functions;
- theorems;
- instances;
- data.

It cannot mutate Standard grammar.

---


Detailed convenience APIs for collections, codecs, parsers, application effects, resources, streams, theorem libraries, proof libraries, and foreign wrappers SHOULD be documented as Standard-library APIs even when the semantic basis is summarized in this reference. Their existence does not mutate Standard grammar.


## 28. Lean Compatibility

ProofScript is Lean-compatible only through explicit, bounded profiles. A Lean version number alone never implies full source compatibility. Appendix I is the normative mapping table for every inherited family used by this edition.

[lean-compat.enumeration]

`lean-subset-psc2-v1` is mechanically enumerable: non-tactic syntax consists exactly of Appendix-I mappings whose **Mode** contains `source-compatible`, subject to each row's restriction and the smaller grammar/semantic closures in Chapters 2, 24, and Appendix A. Tactic syntax consists exactly of the source-compatible variant rows in Appendix I.8. Rows whose Mode lacks `source-compatible` do not independently admit source syntax.

An implementation can therefore derive the compatibility-family set without interpreting prose labels.

### lean-subset-psc2-v1


A frontend claiming `lean-subset-psc2-v1` MUST accept non-tactic Lean spellings enumerated by Appendix-I rows marked `source-compatible`, and tactic spellings enumerated by Appendix I.8. No additional native Lean syntax is implied.

Required families include:

- <code>def</code>;
- <code>theorem</code>;
- <code>example</code>;
- <code>abbrev</code>;
- <code>opaque</code>;
- <code>axiom</code>;
- supported declaration modifiers;
- explicit/implicit/strict-implicit/instance binders;
- the universe syntax explicitly mapped by Appendix I;
- structures/classes/instances;
- inductives/constructors/projections;
- records/update;
- lambdas;
- lets;
- applications;
- literals;
- conditionals;
- match;
- <code>psc2-pattern-v1</code>;
- basic <code>do</code>;
- structural/local/mutual recursion;
- partial/noncomputable boundaries;
- the propositions, equality, and basis declarations enumerated in Chapters 25–26;
- the proof source forms and Standard prover registry enumerated in Chapters 19–20.

Excluded unless a later compatibility profile says otherwise:

- arbitrary <code>syntax</code>;
- <code>macro</code>;
- <code>macro_rules</code>;
- <code>declare_syntax_cat</code>;
- arbitrary notation declarations;
- arbitrary parser extensions;
- arbitrary term/command/tactic elaborators;
- unrestricted quotations/metaprogramming;
- arbitrary environment extensions;
- unsupported commands/attributes;
- arbitrary deriving handlers;
- arbitrary Lean compiler intrinsics;
- unsupported termination/compiler extensions.

Unsupported Lean source must reject explicitly.

---


## 29. Language Extensions

The default Standard profile is closed. Extension capabilities belong to explicitly identified extensible profiles. Ordinary dependencies must not silently change how Standard source parses or elaborates.

### 29.1 Extensible capabilities

An explicit extensible profile may admit declared syntax, notation, macros, parser extensions, term/command elaborators, tactic syntax/elaborators, Meta facilities, deriving handlers, or attribute handlers. Such extensions are part of the source/environment identity.

### 29.2 Trust rule

Extensions may construct candidate terms/declarations or proof terms; they do not gain independent proof authority. Accepted logical output remains subject to the pinned proof-checking foundation in Chapter 4 and Appendix I.



## 30. Program Validation and Verified Compilation

This chapter defines the PSCV compile gate.

A PSCV source project may be inspected while incomplete, but verified executable emission is a certified operation.

### 30.1 Base validation

[validation.program]

Before PSCV-specific verification, ordinary language checks MUST succeed:

1. input/UTF-8/lexical validation;
2. complete parsing;
3. deterministic name resolution;
4. elaboration and constraint solving;
5. instance/coercion selection;
6. type checking and definitional equality;
7. data/inductive positivity and structural checks;
8. recursion/termination elaboration;
9. theorem proof-term checking;
10. profile/environment identity validation.

Unsupported source rejects without fallback.

### 30.2 Approved specification identity

[pscv.validation.spec]

Before a verified executable root is certified, the build MUST select an approved specification identity.

The approved specification may be represented by a SpecCapsule or an equivalent canonical artifact, but MUST establish:

- which exported declarations require formal coverage;
- which critical requirements require proof evidence;
- which declarations use inline contracts, external claims, or type-as-specification;
- which external assumptions are permitted;
- the profile/environment identities under which the formal claims were elaborated;
- a canonical digest.

An implementation/proof candidate cannot silently change this identity and retain old approval.

### 30.3 Specification coverage gate

[pscv.validation.coverage]

The compiler/verifier MUST compute specification coverage before verified emission.

Verified emission fails if:

- an exported executable declaration requiring a formal spec has none;
- a critical proof-required requirement has no linked formal claim;
- an approved claim is linked to a different declaration/environment than the one being built;
- a required external boundary is undeclared.

Private helper declarations may be transitively covered, but must remain inside the verified executable closure and obey all local PSCV rules.

### 30.4 Verification-condition generation

[pscv.validation.vc]

The verifier MUST generate all mandatory PSCV obligations implied by the program, including as applicable:

- function contract/body refinement;
- call-site preconditions;
- postconditions at every return;
- assertions;
- loop invariant initialization/preservation/exit;
- loop and recursion termination;
- structure/refined-type invariants;
- effect/WP judgments;
- error-path postconditions;
- ghost noninterference/erasure safety;
- imported specification compatibility;
- boundary-model obligations;
- any semantic preservation obligation required to construct the checked executable handoff.

A VC generator is untrusted support machinery. Generated propositions gain authority only through accepted proof evidence.

### 30.5 Proof closure gate

[pscv.validation.proof-closure]

Every mandatory formal obligation reachable from the selected executable roots MUST be closed.

An obligation is closed only when its exact proposition/judgment is associated with proof evidence accepted by the selected proof-checking policy.

The following are not proof closure:

- “SMT returned sat/unsat” without accepted reconstruction/certificate under policy;
- AI confidence;
- runtime tests;
- examples;
- comments;
- a contract attribute with no proof;
- a serialized “verified=true” flag;
- a cached artifact not replayed/validated under its expected identity.

### 30.6 Axiom/trust closure

[pscv.validation.axiom-closure]

The transitive proof/declaration dependency closure MUST be checked against the active assurance policy.

For `pscv-closed-v1`, verified emission rejects at least:

- `sorryAx` or equivalent proof holes;
- user axioms;
- unsafe declarations;
- partial declarations;
- unapproved native/compiler proof axioms;
- unmodeled foreign semantic assumptions.

The selected pinned foundational axioms/theory remain visible in the assurance report.

### 30.7 Executable closure

[pscv.validation.exec-closure]

The build computes the transitive runtime dependency closure from each exported executable root.

Every member MUST be:

- total;
- executable;
- free of forbidden partial/unsafe/noncomputable runtime dependencies;
- within the admitted effect policy;
- kernel admitted where kernel admission applies;
- safely erasable with respect to proof/ghost material.

### 30.8 `PSCV-CERT-v1`

[pscv.validation.certificate]

A verified executable certificate conceptually records:

~~~text
PSCV-CERT-v1
  source/profile identity
  Standard environment identity
  PSCV verification semantics identity
  approved specification digest
  executable root identities
  reachable checked declaration identities
  obligation identities
  proof/admission identities
  axiom/trust closure
  effect/boundary closure
  erasure-safety status
  dependency artifact identities
~~~

The concrete serialization belongs to compiler/build specifications.

A certificate is not trusted merely because it is serialized. A consumer MUST validate/replay the evidence needed by its assurance policy.

### 30.9 Verified executable construction

[pscv.validation.verified-executable]

Only after Sections 30.1–30.8 succeed may the compiler construct the semantic state:

~~~text
VerifiedExecutableModule
~~~

Only `VerifiedExecutableModule` may enter the PSCV erasure/VerifiedIR/backend path.

A conforming implementation MUST NOT expose an alternative PSCV “fast path” that skips this state transition.

### 30.10 Compile gate

[pscv.validation.compile-gate]

Under a PSCV verified build command:

~~~text
open mandatory obligation
OR missing required specification coverage
OR forbidden trust/effect dependency
OR failed erasure/closure validation
=>
NO PSCV executable artifact
~~~

The implementation may still emit diagnostics, proof goals, non-executable checked artifacts, or editor metadata.

If a tool offers an explicitly weaker development/run mode, that output MUST have a distinct non-PSCV verified identity and MUST NOT be confused with a verified build.

### 30.11 Evidence aggregation

[pscv.validation.report]

Every successful PSCV verified build MUST be able to produce a machine-readable assurance summary and SHOULD produce a human-readable report.

The report MUST distinguish:

- approved requirements/formal claims;
- specification coverage;
- proof closure;
- theorem/contract identities;
- unproved/test-only/benchmark-only requirements;
- transitive axiom dependencies;
- external assumptions;
- effect/boundary status;
- compiler/backend assurance status;
- exact source/spec/environment/artifact identities.

A report SHOULD let a reviewer move from requirement → formal claim → implementation → obligation → proof/admission → executable artifact.

### 30.12 Staleness

[pscv.validation.staleness]

Changing any of the following invalidates affected certificates unless semantic-identity rules prove otherwise:

- formal specification;
- implementation definition;
- imported verified dependency;
- semantic/profile environment;
- verification semantics version;
- admitted effect model;
- allowed-assumption policy.

Stale proof caches MUST NOT grant executable verification.

### 30.13 Failure semantics

[pscv.validation.fail-closed]

When PSCV validation cannot decide or complete a mandatory check because of exhaustion, unsupported source, unavailable checker, unresolved ambiguity, solver failure, or missing evidence, it fails closed.

“Could not verify” is not “false,” but it is sufficient to block PSCV verified emission.

## 31. Conformance

### 31.1 PSCV source conformance

[pscv.conformance.source]

An implementation claiming `pscv-v1` MUST implement the complete PSCV profile closure in Section 2 and Appendix C, including its restrictions.

It is nonconforming to accept a forbidden Lean/ProofScript form and then merely omit it from verification.

### 31.2 Verification conformance

[pscv.conformance.verification]

A `pscv-compiler-v1` implementation MUST:

- generate the normative obligation classes required by Section 21 and Section 30;
- reject verified emission when any mandatory obligation is open;
- distinguish specified/unverified from verified;
- implement the contract call rule, not merely declaration-level contract checking;
- enforce ghost noninterference;
- enforce total executable closure;
- enforce the active axiom/effect/boundary policy.

Different internal VC algorithms are permitted only when they produce semantically equivalent proof obligations or checked refinement theorems.

### 31.3 Proof conformance

[pscv.conformance.proof]

Final proof acceptance MUST agree with the pinned proof-checking foundation for the claimed environment/profile.

Tactics, simplifiers, VC generators, AI agents, SMT tools, and compiler optimizers are outside the logical TCB unless a separately declared assurance policy explicitly expands it.

### 31.4 Compiler-stage conformance

The pre-existing `psc2-compiler-v1` and `psc2-standard-language-v1` identities retain their base r3 meanings.

Claiming PSC2 conformance does not imply PSCV conformance.

Claiming PSCV conformance requires PSCV-specific gates even when the same parser/elaborator/kernel implementation is reused.

### 31.5 Lean-compatibility conformance

`lean-subset-psc2-v1` remains the bounded Lean source-compatibility profile.

PSCV is not “all Lean minus unsafe.” Only explicitly enumerated PSCV source/semantic families are admitted.

### 31.6 Semantic conformance

A backend may choose representations and optimization strategies but MUST NOT redefine:

- source typing;
- proof validity;
- definitional equality;
- contract/refinement propositions;
- effect models;
- proof/ghost relevance;
- verified result/error semantics.

### 31.7 Verification-environment identity

[pscv.conformance.environment]

Any registry, theorem set, WP instance, plugin, extension, or semantic option capable of changing accepted PSCV source meaning or verification obligations MUST be reflected in a versioned environment/profile identity.

Proof-search heuristics that can only affect success/failure/performance MAY vary when they cannot change the meaning of accepted proof evidence.

### 31.8 Reference self-consistency

[conformance.reference-self-check]

A PSCV reference release MUST mechanically check at least:

- one authoritative grammar definition for each PSCV-owned nonterminal;
- no unresolved normative grammar aliases;
- no duplicate rule IDs;
- profile table consistency;
- PSCV feature-registry consistency;
- PSCV rejection/profile contradictions;
- Appendix-J coverage for all newly introduced PSCV rule IDs;
- environment/manifest identities referenced by the release.

### 31.9 Implementation validation

[pscv.conformance.execution]

Before `pscv-compiler-v1` can be called release-conformant, executable conformance tests MUST include positive and adversarial cases for at least:

- contract proof required before emission;
- caller-precondition failure;
- false postcondition;
- bad assertion;
- bad loop invariant;
- non-decreasing loop/recursion;
- ghost-to-runtime leak;
- user axiom;
- partial definition;
- unsafe dependency;
- noncomputable executable dependency;
- missing public specification;
- stale SpecCapsule digest;
- prohibited boundary in closed mode;
- declared boundary in boundary mode;
- clean proof replay;
- deliberate attempt to feed unchecked source directly to backend;
- proof cache/artifact identity mismatch.

### 31.10 Specification freeze and errata

[conformance.spec-freeze]

A frozen PSCV release identity includes at least:

~~~text
(base language edition,
 PSCV profile version,
 Lean semantic pin,
 normative reference version,
 Standard environment digest,
 PSCV verification-semantics version,
 PSCV verification-registry digest,
 certificate-policy version)
~~~

The first final implementation release MUST replace any design-RC “manifest pending” state with immutable generated evidence.

A semantic change to one component requires a new version/digest according to the ownership rules. Silent “change the spec to fit the compiler” behavior is nonconforming.

## 32. PSCV Verified Profile

This section is the compact normative summary of the profile.

### 32.1 Mathematical programming model

[pscv.model]

PSCV treats software as a set of mathematical constructions plus executable interpretations:

~~~text
data definition
+ validity propositions
+ total functions
+ function/effect contracts
+ laws/theorems
+ proofs
+ explicit world assumptions
~~~

The executable artifact is accepted only when the selected formal claims about its reachable verified closure have checked evidence.

### 32.2 Verification certificate

[pscv.certificate]

For a reachable executable declaration `d`, the conceptual certificate obligation is:

~~~text
Certificate(d) :=
    Total(d)
  ∧ SpecificationCovered(d)
  ∧ RefinesApprovedSpecification(d)
  ∧ CallerPreconditionsClosed(d)
  ∧ LocalAssertionsClosed(d)
  ∧ LoopAndRecursionObligationsClosed(d)
  ∧ EffectsAllowed(d)
  ∧ DependenciesCertified(d)
  ∧ AxiomClosureAllowed(d)
  ∧ GhostErasureSafe(d)
~~~

This notation is schematic; each conjunct denotes the corresponding normative judgments/rules in this reference.

A module is PSCV verified-executable only when the policy-required certificate holds for its entire reachable executable closure.

### 32.3 Definitions are not automatically behavioral theorems

[pscv.definition.not-self-specifying]

A declaration:

~~~proofscript
def f(x : A) : B := t
~~~

establishes, after elaboration/kernel checking, that `t` inhabits the declared type.

It does **not** automatically prove an unstated domain-specific intention about `f`.

Therefore PSCV requires specification coverage rather than the meaningless rule “every `def` must have an extra theorem regardless of what the theorem says.”

### 32.4 Preferred specification hierarchy

[pscv.spec.hierarchy]

PSCV SHOULD express correctness at the strongest natural layer:

1. **type/refinement invariant** when the property defines valid data;
2. **function contract** when the property describes one computation;
3. **class/structure law** when the property describes an abstraction;
4. **module/state-machine law** when behavior spans operations;
5. **effect/trace specification** when behavior involves state/effects;
6. **boundary assumption/evidence** when the world is outside closed logic.

This reduces annotation duplication while preserving strong proof meaning.

### 32.5 Modular verification

[pscv.modular]

A caller SHOULD verify against a dependency's checked public specification rather than unfold its implementation.

An imported PSCV module therefore exposes, conceptually:

~~~text
public API
+ approved formal specifications
+ checked proof/admission identities
+ assurance policy
```

not merely executable binaries or type declarations.

### 32.5A Module refinement evidence

[pscv.module.refinement]

A conforming implementation MUST be able to identify the checked evidence that connects each approved public formal claim to the implementation declaration(s) it constrains.

The evidence MAY be one generated aggregate refinement theorem or a set of individually checked obligation theorems/certificates.

What matters normatively is that a consumer can establish:

~~~text
approved public specification
        |
        v
checked implementation-refinement evidence
        |
        v
public executable declarations
~~~

without trusting source comments, AI summaries, or implementation-private metadata.


### 32.6 AI-generated software

[pscv.ai]

AI has no special source authority.

For high-assurance AI workflows:

- the approved specification identity SHOULD be read-only to the implementation/proof agent;
- the agent MAY generate implementations, local invariants, helper lemmas, proofs, and tests;
- a request to weaken/change the approved spec is a specification revision/challenge, not an implementation repair;
- the final checker MUST not trust the agent's “verified” metadata;
- clean replay SHOULD be used for high-value releases.

### 32.7 Closed versus boundary correctness

[pscv.assurance.vector]

A build MUST avoid the single ambiguous statement “everything is verified.”

At minimum, assurance has independent dimensions:

~~~text
specification coverage
logic/proof closure
proof replay
compiler preservation
foreign/boundary evidence
build provenance
```

`pscv-closed-v1` targets the strongest closed logical/effect story.

`pscv-boundary-v1` supports real applications while stating exactly where trust leaves the closed proof world.

### 32.8 Practicality rule

[pscv.practicality]

PSCV verification syntax SHOULD reduce annotation burden through:

- refined/dependent data types;
- reusable specification lemmas;
- lawful classes;
- automatic VC generation;
- proof-producing automation;
- proof-erased ghost state;
- modular checked specifications;
- high-quality counterexamples/diagnostics where available.

The language MUST NOT require a redundant public theorem for every private helper when the helper is transitively covered and the selected specification-coverage policy is satisfied.

### 32.9 No verified emission without evidence

[pscv.no-proof-no-build]

This is the defining PSCV rule:

> A PSCV verified build MUST NOT emit an executable artifact unless all mandatory specification-coverage, proof, totality, effect, trust, dependency, and erasure gates succeed.

## Appendix A — Complete grammar closure and owned grammar

### A.1 Grammar authority

[grammar.closure]

The normative Standard grammar is the union of:

1. the explicit ProofScript-owned productions below;
2. the exact pinned Lean parser productions identified in Appendix I;
3. the fixed Standard tactic/proof grammar in Chapter 20.

No other Lean parser category, macro, notation declaration, or imported syntax registration is admitted in `ps-standard-0.9-r3`.


### A.1.1 Grammar pipeline and goal symbol

[grammar.goal]

Standard parsing is:

~~~text
UTF-8 bytes
→ Chapter-5 normalized source characters/trivia
→ lexical tokens
→ SourceFile
→ EOF
~~~

`SourceFile` is the sole Standard syntactic goal. Acceptance requires one complete derivation of `SourceFile` with no unconsumed token.

[grammar.single-definition]

Every ProofScript-owned grammar nonterminal has exactly one authoritative EBNF definition in Appendix A or the finite Standard tactic grammar of Chapter 20. EBNF definitions of those same nonterminals elsewhere in the reference are forbidden.

[grammar.external-nonterminal-registry]

The following names are the complete externally pinned or cross-chapter grammar aliases used by Standard grammar.

| External/alias nonterminal | Normative authority |
|---|---|
| `LeanIdentifierToken` | `LEAN-LEX-IDENT` |
| `LeanNatLiteralToken` | `LEAN-LEX-NAT` |
| `LeanScientificLiteralToken` | `LEAN-LEX-SCIENTIFIC` |
| `LeanStringLiteralToken` | `LEAN-LEX-STRING` |
| `LeanCharLiteralToken` | `LEAN-LEX-CHAR` |
| `LeanLineComment` | `LEAN-LEX-COMMENT` |
| `LeanBlockComment` | `LEAN-LEX-COMMENT-BLOCK` |
| `LeanUniverseLevel` | `LEAN-GRAMMAR-LEVEL`, restricted by `[grammar.universe-level]` |
| `BinderIdent` | `LEAN-GRAMMAR-BINDER-ID` |
| `ImplicitBinder` | `LEAN-BINDER-IMPLICIT` |
| `StrictImplicitBinder` | `LEAN-BINDER-STRICT` |
| `InstanceBinder` | `LEAN-BINDER-INSTANCE` |
| `StandardInfixOperator`, `StandardPrefixOperator` | Chapter 24.2 |
| `ConstructorBody` | `LEAN-GRAMMAR-CTOR`, restricted by Chapter 13 |
| `VariablePattern`, `WildcardPattern`, `ConstructorPattern`, `NestedConstructorPattern`, `TuplePattern` | `LEAN-GRAMMAR-PATTERN`, restricted by `psc2-pattern-v1` |
| `LeanStructFieldSequence`, `LeanClassFieldSequence` | `LEAN-LAYOUT-STRUCT-CLASS` |
| `StandardTactic` | Chapter 20.2 |
| `EOF` | end of normalized source input |

No other unresolved grammar nonterminal is permitted in a published Standard reference.


### A.2 Complete source-file and command grammar

[grammar.source-file]

~~~ebnf
SourceFile :=
  CommandSequence? EOF

CommandSequence :=
  Command (CommandSep Command)* CommandSep?

CommandSep :=
  LineTerminator+

Command :=
    ImportCommand
  | NonImportCommand

NonImportCommand :=
    NamespaceCommand
  | SectionCommand
  | OpenCommand
  | VariableCommand
  | IncludeCommand
  | OmitCommand
  | UniverseCommand
  | Declaration

NestedCommandSequence :=
  NonImportCommand (CommandSep NonImportCommand)* CommandSep?

QualifiedIdentifier :=
  Identifier ("." Identifier)*

ModuleName := QualifiedIdentifier

ImportCommand :=
    "import" ModuleName
  | "public" "import" ModuleName

NamespaceCommand :=
  "namespace" QualifiedIdentifier CommandSep? NestedCommandSequence? "end" QualifiedIdentifier?

SectionCommand :=
  "section" Identifier? CommandSep? NestedCommandSequence? "end" Identifier?

OpenCommand :=
  "open" QualifiedIdentifier+

VariableCommand :=
  "variable" (NonExplicitBinder | ExplicitGroup)+

IncludeCommand :=
  "include" Identifier+

OmitCommand :=
  "omit" Identifier+

UniverseCommand :=
  "universe" Identifier+
~~~

[grammar.command-layout]

`CommandSep` is recognized only after a syntactically complete command at the current command-sequence nesting level. Line terminators inside a nested term, proof, comment, string, or braced subgrammar do not terminate the surrounding command.

`SourceFile` additionally satisfies `[module.import-header]`: the maximal prefix of top-level `CommandSequence` consisting of `ImportCommand`s is the import header; no `ImportCommand` may occur after that prefix. Nested command sequences contain no imports by grammar.

If a namespace/section closing label is present, it MUST match the corresponding opening label.

[grammar.declaration]

~~~ebnf
Declaration :=
    DefDeclaration
  | ConstDeclaration
  | FunctionDeclaration
  | TheoremDeclaration
  | ExampleDeclaration
  | AbbrevDeclaration
  | OpaqueDeclaration
  | AxiomDeclaration
  | StructureDeclaration
  | ClassDeclaration
  | InstanceDeclaration
  | InductiveDeclaration
  | MutualDeclaration

DeclPrefix :=
  AttributeBlock* Visibility?

Visibility :=
  "private"

DefinitionModifier :=
    "partial"
  | "noncomputable"

DeclParams :=
  NonExplicitBinder* ExplicitGroup?

DefDeclaration :=
  DeclPrefix DefinitionModifier? "def" Identifier DeclParams (":" PSTerm)? DefinitionBody

ConstDeclaration :=
  DeclPrefix "noncomputable"? "const" Identifier (":" PSTerm)? DefinitionBody

FunctionDeclaration :=
  DeclPrefix DefinitionModifier? FunctionHeader ContractClause* DefinitionBody

TheoremDeclaration :=
  DeclPrefix "theorem" Identifier DeclParams ":" PSTerm DefinitionBody

ExampleDeclaration :=
  "example" DeclParams ":" PSTerm DefinitionBody

AbbrevDeclaration :=
  DeclPrefix "abbrev" Identifier DeclParams (":" PSTerm)? DefinitionBody

OpaqueDeclaration :=
  DeclPrefix "opaque" Identifier DeclParams ":" PSTerm DefinitionBody

AxiomDeclaration :=
  DeclPrefix "axiom" Identifier DeclParams ":" PSTerm

StructureDeclaration :=
  DeclPrefix "structure" Identifier DeclParams "where" StructBody

ClassDeclaration :=
  DeclPrefix "class" Identifier DeclParams "where" ClassBody

PrioritySpec :=
  "(" "priority" ":=" Priority ")"

Priority :=
    NatLiteral
  | "low"
  | "mid"
  | "default"
  | "high"

InstanceDeclaration :=
  AttributeBlock* "private"? "instance" PrioritySpec? Identifier? DeclParams ":" PSTerm "where" InstanceBody

InductiveDeclaration :=
  DeclPrefix "inductive" Identifier DeclParams (":" PSTerm)? "where" InductiveBody

MutualDeclaration :=
  "mutual" CommandSep? MutualMember (CommandSep MutualMember)* CommandSep? "end"

MutualMember :=
    DefDeclaration
  | FunctionDeclaration
~~~

[grammar.attributes]

~~~ebnf
AttributeBlock :=
  "@[" StandardAttribute ("," StandardAttribute)* ","? "]"

StandardAttribute :=
    "simp"
  | "instance" Priority?
  | "default_instance" Priority?
~~~

Only the attribute names/forms above are Standard. Attribute handler registration remains closed by Chapter 24.

[grammar.top-level-complete]

A Standard source file is syntactically accepted only if its complete token stream is consumed by `SourceFile`. There is no implicit fallback from an unrecognized top-level form to arbitrary Lean commands.

### A.3 Lexical grammar

[grammar.lexical]

Source input and line normalization are exactly Chapter 5; Standard source is UTF-8, not an abstract implementation-defined Unicode string.

The following lexical classes are pinned to exact Lean locators in Appendix I:

~~~ebnf
LineTerminator :=
  <U+000A>

ASCII_SPACE :=
  <U+0020>

Identifier :=
  LeanIdentifierToken

NatLiteral :=
  LeanNatLiteralToken

ScientificLiteral :=
  LeanScientificLiteralToken

StringLiteral :=
  LeanStringLiteralToken

CharLiteral :=
  LeanCharLiteralToken

LineComment :=
  LeanLineComment

BlockComment :=
  LeanBlockComment

BlockCommentNoLF :=
  LeanBlockComment

ApplicationHorizontalTrivia :=
    ASCII_SPACE
  | BlockCommentNoLF

LayoutEdge :=
  LineTerminator*
~~~

Block comments are nestable according to the pinned Lean scanner.



Whitespace/trivia does not create JavaScript-style automatic semicolon insertion. A newline is grammatically significant only in explicitly defined block/layout productions.

### A.4 Tokens and contextual words

[grammar.tokens]

The fixed Standard keyword/contextual heads include:

~~~text
import public namespace section end open variable include omit universe private
def const function theorem example abbrev opaque axiom structure class instance
inductive mutual partial noncomputable where fun let if else match with
forall exists do by have show suffices calc requires ensures set_option
~~~

`set_option` is reserved for tooling/extensible source and rejects as a Standard program declaration.

ProofScript-owned words are contextual unless a production requires them as the leading token of that construct.

### A.5 Operator precedence

[grammar.precedence]

The Standard precedence/associativity table is Chapter 24.2 and is normative.

Pinned Lean precedence landmarks are:

~~~text
max  = 1024
arg  = 1023
lead = 1022
min  = 10
~~~

The dependent/non-dependent arrow parser has precedence 25 and parses its right-hand side recursively, giving right association.

Field notation and parenthesized call postfixes bind tighter than every infix operator in Chapter 24.2.


[grammar.operator-algorithm]

`OperatorTerm` is parsed by deterministic precedence climbing over the exact Chapter-24.2 operator table.

Let every infix operator have precedence `p` and associativity `L`, `R`, or `N`.

`parseExpr(minPrec)`:

1. parse one `PrefixTerm` as `lhs`;
2. while the next token is an infix operator with precedence `p >= minPrec`:
   - consume the operator;
   - if associativity is `L`, parse `rhs := parseExpr(p + 1)`;
   - if associativity is `R`, parse `rhs := parseExpr(p)`;
   - if associativity is `N`, parse `rhs := parseExpr(p + 1)` and reject if the resulting unparenthesized expression would contain another precedence-`p` operator on either side;
   - replace `lhs` by the operator application to `lhs` and `rhs`;
3. return `lhs`.

Prefix operators parse their operand at the operand precedence listed in Chapter 24.2. Postfix field/call syntax and native application are completed before infix precedence climbing.

[grammar.operator-nonassoc]

Unparenthesized chaining of non-associative precedence-50 relations rejects. For example, a source shape equivalent to `a < b < c` or `a = b = c` requires explicit parentheses and must then type-check normally.


### A.6 Complete Standard term grammar

[grammar.term]

The following productions close every Standard `PSTerm` family. Productions that delegate to a pinned Lean parser family name the exact mapping ID.

~~~ebnf
PSTerm :=
    OperatorTerm

OperatorTerm :=
  PrefixTerm InfixTail*

InfixTail :=
  StandardInfixOperator PrefixTerm

PrefixTerm :=
    StandardPrefixOperator PrefixTerm
  | ApplicationTerm

ApplicationTerm :=
  PostfixTerm (NativeApplicationGap PostfixTerm)*

NativeApplicationGap :=
    ApplicationHorizontalTrivia+
  | ApplicationHorizontalTrivia* LineTerminator ApplicationHorizontalTrivia*

PostfixTerm :=
  PrimaryTerm PostfixSuffix*

PostfixSuffix :=
    FieldSuffix
  | ParenthesizedCallSuffix

FieldSuffix :=
  "." Identifier

ParenthesizedCallSuffix :=
  "(" CallArguments? ")"

PrimaryTerm :=
    Identifier
  | Literal
  | SortTerm
  | ParenthesizedTerm
  | TupleTerm
  | TypeAscription
  | LambdaTerm
  | LetTerm
  | ForallTerm
  | ExistsTerm
  | RecordConstruction
  | RecordUpdate
  | ConstructorShorthand
  | BracedIf
  | MatchTerm
  | BasicDoTerm
  | ProofTerm

Literal :=
    NatLiteral
  | ScientificLiteral
  | StringLiteral
  | CharLiteral
  | "true"
  | "false"
  | "()"

SortTerm :=
    "Prop"
  | "Type" UniverseSuffix?
  | "Sort" UniverseLevel

UniverseSuffix :=
  UniverseLevel

UniverseLevel :=
  LeanUniverseLevel

ParenthesizedTerm :=
  "(" PSTerm ")"

TupleTerm :=
  "(" PSTerm "," PSTerm ("," PSTerm)* ","? ")"

TypeAscription :=
  "(" PSTerm ":" PSTerm ")"

LambdaTerm :=
  "fun" LambdaBinder+ "=>" PSTerm

LambdaBinder :=
    Identifier
  | "(" BinderIdent ":" PSTerm ")"
  | ImplicitBinder
  | StrictImplicitBinder
  | InstanceBinder

QuantBinder :=
    Identifier ":" PSTerm
  | "(" BinderIdent ":" PSTerm ")"
  | ImplicitBinder
  | StrictImplicitBinder
  | InstanceBinder

ForallTerm :=
  ("forall" | "∀") QuantBinder+ "," PSTerm

ExistsTerm :=
  ("exists" | "∃") QuantBinder+ "," PSTerm

LetTerm :=
  "let" BinderIdent TypeAnnotation? ":=" PSTerm TermBodySep PSTerm

TypeAnnotation :=
  ":" PSTerm

TermBodySep :=
  LineTerminator+

RecordConstruction :=
  "{" (RecordField ("," RecordField)* ","?)? "}"

RecordUpdate :=
  "{" PSTerm "with" RecordField ("," RecordField)* ","? "}"

RecordField :=
  Identifier ":=" PSTerm

ConstructorShorthand :=
  "." Identifier ParenthesizedCallSuffix?

BracedIf :=
  "if" "(" PSTerm ")" "{" PSTerm "}" "else" "{" PSTerm "}"

MatchTerm :=
  "match" PSTerm "with" MatchBody

ProofTerm :=
  "by" "{" LayoutEdge StandardTacticSequence LayoutEdge "}"
~~~

[grammar.term-body-layout]

`TermBodySep` is recognized only after a syntactically complete bound value at the current term/layout depth. A line terminator nested inside the bound value does not become the separator.

[grammar.application]

`ApplicationTerm` is the Standard subset of the pinned Lean application parser `LEAN-TERM-APPLICATION`. It is left-associative, and each additional `PostfixTerm` produces one unary core application.

[grammar.application-comment-newline]

`BlockCommentNoLF` is a `LeanBlockComment` whose decoded text contains no normalized `LF`.

A block comment containing a normalized line terminator is line-breaking trivia for application ownership and therefore cannot satisfy `ApplicationHorizontalTrivia`. Standard does not allow a newline hidden inside a block comment to bypass `[grammar.application-layout]`.

[grammar.application-layout]

If `NativeApplicationGap` contains a `LineTerminator`, the first token of the following `PostfixTerm` MUST be indented strictly deeper than the first token of the current application line. Otherwise that line terminator ends the application rather than belonging to `NativeApplicationGap`.


[grammar.parenthesized-call-adjacency]

A `ParenthesizedCallSuffix` may be consumed only when its opening `(` is source-position adjacent to the final token of the `PostfixTerm` it follows, with zero intervening bytes of whitespace or comment trivia.

If adjacency does not hold, the `(` begins an ordinary `ParenthesizedTerm`/`TupleTerm` that may participate in Lean-style native application through `NativeApplicationGap`.

[grammar.operator-term]

`StandardInfixOperator` and `StandardPrefixOperator` are exactly the operators in Chapter 24.2. Parsing uses that table's precedence/associativity and no imported notation.


### A.7 Explicit parameters and function headers

~~~ebnf
DefaultSuffix :=
  ":=" PSTerm

ExplicitGroup :=
  "(" ExplicitEntry ("," ExplicitEntry)* ","? ")"

EmptyExplicitGroup :=
  "(" ")"

ExplicitEntry :=
  BinderIdent ":" PSTerm DefaultSuffix?

FunctionHeader :=
  "function"
  Identifier
  NonExplicitBinder*
  (ExplicitGroup | EmptyExplicitGroup)
  (":" PSTerm)?

NonExplicitBinder :=
    ImplicitBinder
  | StrictImplicitBinder
  | InstanceBinder
~~~

The non-explicit binder grammars are the exact pinned productions listed in Appendix I.

### A.8 Declaration bodies

The normative rule is `[decl.function.body.single-term]` in Chapter 8.
~~~ebnf
DefinitionBody :=
  ":=" (PSTerm | BracedDefinitionBody) WhereBody?

BracedDefinitionBody :=
  "{" PSTerm "}"
~~~

A braced definition body contains exactly one `PSTerm`. Braces do not create generic statement sequencing.

### A.9 Parenthesized-call arguments

~~~ebnf
CallArguments :=
  CallArgument ("," CallArgument)* ","?

CallArgument :=
    NamedCallArgument
  | PSTerm

NamedCallArgument :=
  Identifier ":=" PSTerm
~~~

The call operation itself is the postfix `ParenthesizedCallSuffix` defined in A.6 and is subject to `[grammar.parenthesized-call-adjacency]`. There is no separate `ParenthesizedCall` nonterminal.

### A.10 Tuple/record comma policy and declaration bodies

[grammar.comma-policy]

The canonical productions for `TupleTerm`, `RecordConstruction`, `RecordUpdate`, and `RecordField` are defined once in A.6.

For comma-oriented productions, commas between adjacent items are mandatory, one final trailing comma is optional, and the trailing comma has no semantic effect.

~~~ebnf
StructBody :=
  "{" LayoutEdge LeanStructFieldSequence? LayoutEdge "}"

ClassBody :=
  "{" LayoutEdge LeanClassFieldSequence? LayoutEdge "}"
~~~

Structure/class fields use the pinned `LEAN-LAYOUT-STRUCT-CLASS` sequence; commas and semicolons are not field separators.

### A.11 Inductives and patterns

~~~ebnf
InductiveBody :=
  "{" LayoutEdge ("|" ConstructorBody)* LayoutEdge "}"

MatchBody :=
  "{" LayoutEdge ("|" PatternGroup "=>" PSTerm)+ LayoutEdge "}"

PatternGroup :=
    VariablePattern
  | WildcardPattern
  | ConstructorPattern
  | NestedConstructorPattern
  | TuplePattern
  | SupportedLiteralPattern

SupportedLiteralPattern :=
    NatLiteral
  | "true"
  | "false"
~~~

Only single-scrutinee `match` is Standard.

### A.12 Declaration-field and local declaration sequences

[grammar.field-layout]

Structure/class declaration fields continue to use the pinned Lean 4.35.0-rc3 field-layout categories:

| ProofScript context | Inner sequence authority | Accepted separator behavior |
|---|---|---|
| structure declaration body | `LEAN-LAYOUT-STRUCT-CLASS` | pinned structure-field layout; no comma/semicolon separator |
| class declaration body | `LEAN-LAYOUT-STRUCT-CLASS` | pinned class-field layout; no comma/semicolon separator |

Instance bodies and local `where` bodies are ProofScript-owned finite grammars:

~~~ebnf
InstanceBody :=
  "{" LayoutEdge InstanceFieldSequence? LayoutEdge "}"

InstanceFieldSequence :=
  InstanceField (InstanceSep InstanceField)*

InstanceField :=
  Identifier DeclParams (":" PSTerm)? ":=" PSTerm

InstanceSep :=
  LineTerminator+

WhereBody :=
  "{" LayoutEdge WhereDeclarationSequence? LayoutEdge "}"

WhereDeclarationSequence :=
  WhereDeclaration (WhereSep WhereDeclaration)*

WhereDeclaration :=
    LocalDefDeclaration
  | LocalFunctionDeclaration

LocalDefDeclaration :=
  DefinitionModifier? "def" Identifier DeclParams (":" PSTerm)? DefinitionBody

LocalFunctionDeclaration :=
  DefinitionModifier? FunctionHeader ContractClause* DefinitionBody

WhereSep :=
  LineTerminator+
~~~

[grammar.brace-layout-edge]

`LayoutEdge` consumes zero or more normalized line terminators immediately inside a layout-sensitive opening/closing brace. It is the sole rule that permits canonical leading/trailing newlines around instance, local-`where`, `do`, proof, structure/class, inductive, and match bodies.

Interior newline separators remain governed by the construct-specific sequence grammar and are not interchangeable with `LayoutEdge`.

[grammar.instance-where-layout]

`InstanceSep`/`WhereSep` are recognized only after a syntactically complete field/declaration at the current enclosing body depth.

A normalized line terminator nested inside an instance-field value, local declaration type/body, proof block, comment, or nested braces does not terminate the containing field/declaration.

Standard instance/local-`where` sequences are newline-only. Semicolons are not Standard separators.

No other Lean local-declaration form is Standard inside `where { ... }`. In particular, local `instance`, local theorem/axiom, arbitrary commands, syntax/macro declarations, and namespace/section commands are excluded.

The bounded Lean-source compatibility profile may accept native Lean `whereDecls`/`whereStructInst` semicolon spellings only under the exact source-compatible Appendix-I mappings.

### A.13 Conditional

The sole authoritative `BracedIf` production is A.6. Each branch contains exactly one `PSTerm`.

### A.14 Basic `do`

[grammar.do]

Standard ProofScript requires the braced spelling:

~~~ebnf
BasicDoTerm :=
  "do" "{" LayoutEdge DoSequence LayoutEdge "}"

DoSequence :=
  DoElem (DoSep DoElem)*

DoSep :=
  TermBodySep

DoElem :=
    SimpleLet
  | IdentifierBind
  | WildcardBind
  | CompletionTerm
  | TermStatement

SimpleLet :=
  "let" BinderIdent TypeAnnotation? ":=" PSTerm

IdentifierBind :=
  "let" BinderIdent TypeAnnotation? "←" PSTerm

WildcardBind :=
  "let" "_" TypeAnnotation? "←" PSTerm

CompletionTerm :=
    "pure" PSTerm
  | "return" PSTerm

TermStatement :=
  PSTerm
~~~

`DoSep` is accepted only between syntactically complete `DoElem`s. Standard `do` sequencing is newline-only; semicolon-separated native Lean spellings are outside Standard.

This is the exact Standard subset associated with `LEAN-TERM-DO-BASIC`; richer pinned Lean `do` forms, including semicolon-separated sequences, remain outside Standard.

### A.15 Proof/tactic block grammar

[grammar.proof]

`ProofTerm` is defined once in A.6. The tactic sequence is:

~~~ebnf
StandardTacticSequence :=
  StandardTactic (TacticSep StandardTactic)*

TacticSep :=
  LineTerminator+
~~~

[grammar.tactic-layout]

`TacticSep` is recognized only after a complete `StandardTactic` at the current proof-block depth. A line terminator nested inside a tactic argument term does not end the tactic.

`StandardTactic` is exactly Chapter 20.2. Lean tactic semicolons, bullets, `case`, and unenumerated syntax are excluded from Standard.

### A.16 Contracts

~~~ebnf
ContractClause :=
    "requires" PSTerm
  | "ensures" Identifier "=>" PSTerm

ContractedFunction :=
  FunctionHeader ContractClause* DefinitionBody
~~~

### A.17 Grammar completeness

[grammar.no-implicit-extension]

If a token sequence can only be parsed by a Lean syntax/notation/macro/command family not listed by Appendix A, Chapter 20, or Appendix I, it rejects under `ps-standard-0.9-r3`.

The extensible source profile may add grammar only under a distinct environment/profile identity.


### A.18 PSCV owned grammar

[pscv.grammar]

`pscv-v1` extends the base closed grammar with the finite productions below. No other Lean syntax is implied.

The PSCV parser admits the base `SourceFile` grammar with the following additional declaration/term alternatives and profile restrictions.

~~~ebnf
PSCVDeclaration :=
    PSCVDefDeclaration
  | PSCVFunctionDeclaration
  | RefineTypeDeclaration
  | PSCVStructureDeclaration
  | VerifyDeclaration

VerifyDeclaration :=
  "verify" QualifiedIdentifier ":=" ProofTerm

GivenClause :=
  "given" QuantBinder+

PSCVContractClause :=
    GivenClause
  | ContractClause
  | PSCVEffectClause

PSCVEffectClause :=
    "reads" "[" PSTerm ("," PSTerm)* ","? "]"
  | "modifies" "[" PSTerm ("," PSTerm)* ","? "]"
  | "errors" BinderIdent "=>" PSTerm

OldTerm :=
  "old" "(" PSTerm ")"

PSCVDefDeclaration :=
  DeclPrefix "def" Identifier DeclParams (":" PSTerm)?
  PSCVContractClause*
  PSCVDefinitionBody

PSCVFunctionDeclaration :=
  DeclPrefix FunctionHeader
  PSCVContractClause*
  PSCVDefinitionBody

PSCVDefinitionBody :=
  ":=" (PSTerm | BracedDefinitionBody)
  PSCVTerminationSuffix?
  WhereBody?

PSCVTerminationSuffix :=
  TerminationByClause DecreasingByClause?

TerminationByClause :=
  "termination_by" PSTerm

DecreasingByClause :=
  "decreasing_by" ProofTerm

RefineTypeDeclaration :=
  DeclPrefix
  "refine" "type" Identifier DeclParams
  ":=" PSTerm
  "where" BinderIdent "=>" PSTerm

PSCVStructureDeclaration :=
  DeclPrefix "structure" Identifier DeclParams "where" StructBody
  StructureInvariantClause*

StructureInvariantClause :=
  "invariant" BinderIdent "=>" PSTerm

PSCVDoTerm :=
  "do" "{" LayoutEdge PSCVDoSequence LayoutEdge "}"

PSCVDoSequence :=
  PSCVDoElem (DoSep PSCVDoElem)*

PSCVDoElem :=
    SimpleLet
  | IdentifierBind
  | WildcardBind
  | CompletionTerm
  | TermStatement
  | MutableLet
  | MutableAssignment
  | GhostLet
  | AssertElem
  | ForElem
  | WhileElem
  | BreakElem
  | ContinueElem

MutableLet :=
  "let" "mut" BinderIdent TypeAnnotation? ":=" PSTerm

MutableAssignment :=
  BinderIdent ":=" PSTerm

GhostLet :=
  "ghost" "mut"? BinderIdent TypeAnnotation? ":=" PSTerm

AssertElem :=
  "assert" PSTerm

LoopInvariantClause :=
  "invariant" PSTerm

LoopDecreasingClause :=
  "decreasing" PSTerm

ForElem :=
  "for" PatternGroup "in" PSTerm
  LoopInvariantClause*
  "{" LayoutEdge PSCVDoSequence? LayoutEdge "}"

WhileElem :=
  "while" PSTerm
  LoopInvariantClause+
  LoopDecreasingClause
  "{" LayoutEdge PSCVDoSequence? LayoutEdge "}"

BreakElem :=
  "break"

ContinueElem :=
  "continue"
~~~

[pscv.grammar.integration]

For `pscv-v1`:

- `PSCVDeclaration` is an additional `Declaration` alternative;
- `PSCVDoTerm` is an additional `PrimaryTerm` alternative and supersedes `BasicDoTerm` for PSCV code;
- `OldTerm` is an additional contract-only primary term admitted only where a verified effect model defines pre-state;
- `PSCVFunctionDeclaration` supersedes the base function-declaration production when PSCV-only clauses are present;
- `PSCVDefDeclaration` allows contracts and an explicit total-recursion suffix on `def`;
- the profile rejects `AxiomDeclaration` and any declaration using the `partial` modifier even though the base grammar can recognize them;
- `unsafe` remains outside the closed grammar;
- a structure invariant clause is outside the braces specifically to avoid importing/redefining the pinned Lean structure-field grammar.

[pscv.grammar.contract-order]

Within one PSCV contracted declaration:

1. zero or more `given` clauses come first;
2. zero or more `requires` clauses follow;
3. zero or more frame clauses (`reads`/`modifies`) follow;
4. success `ensures` and typed `errors` clauses follow;
5. interleaving an earlier clause class after a later one rejects.

[pscv.grammar.loop-clauses]

For `while`, at least one invariant and exactly one decreasing clause are required by grammar.

For `for`, explicit invariants are syntactically optional because an imported verified iterator specification may discharge the equivalent obligations; Section 21 still requires sufficient verification evidence.

[pscv.grammar.refine-type]

`RefineTypeDeclaration` is syntactic sugar for an admitted subtype/refinement construction and does not add a new kernel type former.



## Appendix B — Separator rules

### B.1 General comma policy

[grammar.comma-policy-summary]

ProofScript has no universal comma rule.

A comma is a separator only in a production explicitly defined as comma-oriented.

Current Standard comma-oriented forms are:

- explicit parameter groups;
- parenthesized call arguments;
- tuple/product elements;
- record construction fields;
- record update fields.

For all of them:

~~~text
item1, item2, item3
item1, item2, item3,
~~~

are both valid forms when the production contains three items.

The comma **between** two items is mandatory.

The comma after the final item is optional and has no semantic effect.

### B.2 Standard declaration/sequence separators

[grammar.standard-separator-philosophy]

The Standard separator policy is intentionally small:

~~~text
comma       → value/list-like comma groups
newline     → declaration/do/proof sequences
|           → constructors and match alternatives
adjacency   → ProofScript parenthesized-call ownership
~~~

Standard source has no general semicolon statement separator.

[grammar.sequence-separators]

Standard ProofScript uses newline/layout sequencing for:

- instance fields;
- local `where` declarations;
- braced `do` elements;
- braced tactic sequences.

Semicolon is not a Standard separator in these contexts.

`lean-subset-psc2-v1` may accept native Lean semicolon spellings only through explicit source-compatible mappings in Appendix I.

### B.3 Separator matrix

| Construct | Standard separator | Trailing separator |
|---|---|---|
| explicit parameter groups | `,` | optional `,` |
| parenthesized call arguments | `,` | optional `,` |
| tuples/products | `,` | optional `,` |
| record construction/update fields | `,` | optional `,` |
| structure/class declaration fields | layout/newline | none |
| instance fields | normalized newline | none |
| local `where` declarations | normalized newline | none |
| braced `do` elements | normalized newline | none |
| braced tactic sequence | normalized newline | none |
| inductive constructors | `|` | N/A |
| match alternatives | `|` | N/A |

### B.4 Formatter boundary (informative)

Canonical formatting policy belongs to the ProofScript tooling/formatter specification. This language reference specifies accepted separators and their semantics, but does not normatively require one formatter output style.

## Appendix C — Feature/profile registry


### Current registry identities


These IDs are the current machine-readable r3 feature/profile identifiers. They are included here so every active registry entry has a human-readable location in this handbook.

| Feature ID | Meaning |
|---|---|
| <code>L-CORE-LEAN</code> | explicitly included pinned Lean semantic categories |
| <code>M-PUBLIC-IMPORT-R3</code> | Lean-compatible <code>public import</code> module re-export |
| <code>D-CONST-ALIAS</code> | <code>const</code> parameterless-definition alias |
| <code>D-FUNCTION-ALIAS-R3</code> | <code>function</code> declaration alias |
| <code>D-FUNCTION-UNIT-R3</code> | zero-source-argument <code>function f()</code> sugar |
| <code>D-DECL-BODY-BRACE-R3</code> | single-term <code>:= { PSTerm }</code> body wrapper |
| <code>D-EXPLICIT-PARAMS</code> | comma-separated explicit parameter group |
| <code>E-CALL-PARENS-R3</code> | adjacent ProofScript-owned parenthesized call; trivia before `(` selects non-call syntax |
| <code>E-EMPTY-CALL-R3</code> | empty-call/default-completion syntax |
| <code>D-NAMED-CALL</code> | named argument syntax |
| <code>D-TRAILING-COMMA-CALL</code> | trailing comma in nonempty call |
| <code>D-TRAILING-COMMA-PARAMS</code> | trailing comma in explicit parameter group |
| <code>E-IF-BRACE</code> | one-term braced conditional branches |
| <code>E-STRUCT-BODY-R3</code> | braces group the pinned Lean-like structure field-declaration sequence |
| <code>E-CLASS-BODY-R3</code> | braces group the pinned Lean-like class field-declaration sequence |
| <code>E-INDUCTIVE-BODY-R3</code> | structural braced inductive constructors |
| <code>E-MATCH-BODY-R3</code> | structural braced match alternatives |
| <code>E-INSTANCE-BODY-R3</code> | ProofScript-owned braced instance body; Standard field sequencing is newline-only |
| <code>E-WHERE-BODY-R3</code> | ProofScript-owned braced local-`where` body; Standard declaration sequencing is newline-only |
| <code>N-BASIC-DO-PSC2</code> | required bounded braced `do` subset; Standard element sequencing is newline-only |
| <code>S-PURE-CONTRACT-R3</code> | pure requires/ensures contract surface |
| <code>P-STANDARD-R3</code> | closed Standard source profile |
| <code>P-LEAN-EXTENSIBLE-R3</code> | declared extensible source profile |
| <code>P-PSC2-LANGUAGE-V1</code> | required PSC2 language capability profile |
| <code>P-PSC2-STANDARD-LANGUAGE-V1</code> | Standard language-facing PSC2 profile |
| <code>P-LEAN-SUBSET-PSC2-V1</code> | bounded Lean compatibility profile |
| <code>P-PATTERN-PSC2-V1</code> | required PSC2 pattern profile |

---


### PSCV registry identities

[pscv.registry]

The PSCV profile adds these stable feature/policy identities.

| Feature/Profile ID | Meaning |
|---|---|
| `P-PSCV-V1` | strict verified ProofScript profile |
| `P-PSCV-CLOSED-V1` | closed assurance policy |
| `P-PSCV-BOUNDARY-V1` | explicit foreign-boundary assurance policy |
| `V-PSCV-VERIFY-V1` | PSCV contract/WP/VC semantics |
| `V-PSCV-CERT-V1` | verified executable certificate and compile gate |
| `V-PSCV-SPEC-COVERAGE` | mandatory specification coverage |
| `V-PSCV-CALL-PRE` | call-site precondition proof obligations |
| `V-PSCV-CALL-POST` | use of checked callee postconditions |
| `V-PSCV-ASSERT` | proof-only assertion |
| `V-PSCV-VERIFY-DECL` | explicit proof attachment for aggregate declaration obligation |
| `V-PSCV-LOOP-INVARIANT` | loop invariant VCs |
| `V-PSCV-DECREASING` | loop termination measure |
| `V-PSCV-GHOST` | proof-only ghost state and noninterference |
| `V-PSCV-WP` | verified effect weakest-precondition interface |
| `V-PSCV-WF-RECURSION` | well-founded/measure total recursion |
| `V-PSCV-STRUCT-INVARIANT` | structure invariant sugar |
| `V-PSCV-REFINE-TYPE` | subtype/refined-type sugar |
| `V-PSCV-VERIFIED-DO` | local mutation/loop verified do surface |
| `V-PSCV-NO-PARTIAL` | partial rejection |
| `V-PSCV-NO-USER-AXIOM` | closed-profile user-axiom rejection |
| `V-PSCV-NO-UNSAFE` | unsafe rejection |
| `V-PSCV-NONCOMPUTABLE-SPEC-ONLY` | noncomputable excluded from exec closure |
| `V-PSCV-VERIFIED-HANDOFF` | only certified module can reach codegen |
| `V-PSCV-SPEC-CAPSULE-LINK` | approved external formal-spec binding |
| `V-PSCV-ASSURANCE-VECTOR` | separate proof/compiler/boundary/provenance claims |

The inherited r3/PSC2 registry identities remain valid as base-profile identifiers. PSCV restrictions take precedence when the PSCV profile is active.


## Appendix D — Canonical example index

Appendix D deliberately does **not** duplicate source snippets from normative chapters. The source shown at the listed location is the authoritative canonical example.

| Example family | Authoritative location | Primary rule/surface |
|---|---|---|
| constant/definition body | Chapter 8 | `[decl.function.body.single-term]` |
| ordinary/generic/default/empty-call functions | Chapters 9–10 | `[grammar.parameter-group-unified]`, `[call.empty]` |
| structures and record values/updates | Chapter 11 | `[struct.body.braced-grouping]`, `[record.comma-policy]` |
| classes and instances | Chapter 12 | `[class.body.braced-grouping]`, `[instance.body.braced-grouping]` |
| inductives | Chapter 13 | `[type.inductive]` |
| patterns and `match` | Chapters 14–15 | `[match.scrutinee.single]` |
| structural recursion | Chapter 18 | `[recursion.structural]` |
| theorem/proof blocks | Chapters 19–20 | `[prover.soundness]`, `[grammar.proof]` |
| contracts | Chapter 21 | `[contract.obligation]` |
| basic `do` | Chapter 10 / Appendix A.14 | `[grammar.do]` |
| overloaded Standard operators | Chapter 24.3 | `[standard.required-surface]` |

The executable reference self-check treats positive `proofscript` source blocks in the normative chapters as the canonical-example corpus.


## Appendix E — Rejection index

Appendix E deliberately avoids repeating rejection snippets that already appear beside their normative rule. Concrete negative executable obligations are named in Appendix J.

| Rejection family | Normative rule | Negative obligation |
|---|---|---|
| omitted required explicit argument / invalid empty call | `[call.empty.required-argument]` | `PS-CONF-CALL-EMPTY-REQUIRED-ARGUMENT-N1` |
| invalid zero-argument function placement | `[elab.zero-source-function]` | `PS-CONF-ELAB-ZERO-SOURCE-FUNCTION-N1` |
| comma-separated structure/class declarations | `[struct.body.braced-grouping]`, `[class.body.braced-grouping]` | corresponding `PS-CONF-*-N1` obligations |
| multiple unrelated terms in a one-term declaration body | `[decl.function.body.single-term]` | `PS-CONF-DECL-FUNCTION-BODY-SINGLE-TERM-N1` |
| dynamic syntax/notation registration in Standard | `[grammar.no-implicit-extension]` | `PS-CONF-GRAMMAR-NO-IMPLICIT-EXTENSION-N1` |
| `unsafe` in Standard | profile exclusion rules | profile negative obligation |
| unlisted Lean tactic variants in `lean-subset-psc2-v1` | `[lean.tactic-variants]` | `PS-CONF-LEAN-TACTIC-VARIANTS-N1` |
| unresolved proof holes | `[trust.no-proof-holes]` | `PS-CONF-TRUST-NO-PROOF-HOLES-N1` |
| non-structural total recursion | `[recursion.subterm]` | `PS-CONF-RECURSION-SUBTERM-N1` |
| environment/digest mismatch | `[standard.registry-digest]` | `PS-CONF-STANDARD-REGISTRY-DIGEST-N1` |


### PSCV rejection index

| Rejection family | Normative rule | Required result |
|---|---|---|
| public executable declaration without required approved specification | `[pscv.validation.coverage]` | block verified emission |
| false/unproved postcondition | `[pscv.contract.required-proof]` | block verified emission |
| unmet callee precondition | `[pscv.contract.call-pre]` | block verified emission |
| failed `assert` | `[pscv.assert]` | block verified emission |
| invariant initialization/preservation failure | `[pscv.loop.invariant]` | block verified emission |
| missing/nondecreasing while measure | `[pscv.loop.decreasing]` | block verified emission |
| ghost value influences runtime behavior | `[pscv.ghost.noninterference]` | reject verified compilation |
| user axiom in closed profile | `[pscv.axiom.user-reject]` | reject |
| `partial` in PSCV source | `[pscv.partial.reject]` | reject |
| `unsafe` dependency | `[pscv.unsafe.reject]` | reject |
| executable depends on `noncomputable` | `[pscv.noncomputable]` | reject verified compilation |
| raw IO/FFI in closed profile | `[pscv.runtime.effect-closure]` | reject verified compilation |
| undeclared foreign assumption in boundary profile | `[pscv.policy.boundary]` | reject verified compilation |
| stale/mismatched spec digest | `[pscv.validation.staleness]` | block verified emission |
| unchecked source passed directly to backend | `[pscv.runtime.verified-handoff]` | implementation conformance failure |
| native/compiler proof axiom in closed policy | `[pscv.proof.native]` | reject verified proof closure |


## Appendix F — PSCV exclusions and boundaries

### F.1 Deliberately excluded from PSCV verified source

The following Lean/ProofScript facilities are deliberately outside the `pscv-v1` verified source profile unless a later separately versioned PSCV extension adopts exact semantics:

- `partial`;
- `unsafe`;
- ordinary user `axiom`;
- unresolved `sorry`/proof holes;
- unrestricted raw IO as closed verified behavior;
- arbitrary mutable references/aliasing without a verified capability/effect model;
- raw thread/task shared-memory concurrency without a verified concurrency model;
- arbitrary FFI/`extern` as closed verified behavior;
- arbitrary Lean syntax/macros/elaborators;
- arbitrary quotation/Meta source;
- custom parser categories;
- arbitrary attribute handlers;
- arbitrary source-defined tactic syntax;
- source options that can change semantic interpretation without a profile identity;
- unrestricted native/compiler-evaluation proof axioms in closed assurance;
- unrestricted `partial_fixpoint`, coinductive fixpoint, or inductive fixpoint executable forms;
- arbitrary host exceptions as typed error semantics;
- JavaScript Promise as the source definition of async behavior;
- dynamic property/prototype semantics;
- ambient `null`/`undefined`;
- native `any`;
- JavaScript truthiness;
- TypeScript structural assignability;
- unchecked runtime casts.

### F.2 Base features promoted into PSCV

Unlike the smaller PSC2 milestone closure, PSCV intentionally requires practical verified forms including:

- local `let mut`;
- local assignment;
- `for`;
- `while`;
- `break`;
- `continue`;
- early return;
- proof-only `assert`;
- loop `invariant`;
- loop `decreasing`;
- ghost state;
- well-founded/measure recursion;
- state/error/reader effect contracts.

These forms are accepted only with the PSCV verification semantics and compile gates defined in this reference.

### F.3 Future PSCV candidates

The following may be valuable but require separate semantic design before inclusion:

- verified resource/ownership capabilities;
- richer async/task contracts;
- structured concurrency;
- verified streams;
- separation-logic or region-style heap reasoning;
- temporal/liveness syntax;
- atomic/concurrent memory models;
- verified foreign-memory/pointer facilities;
- layout/ABI contracts;
- controlled deriving syntax;
- broader rich-pattern/equation syntax;
- UI-specific dialects.

### F.4 JavaScript/TypeScript semantics not imported

PSCV does not import JavaScript/TypeScript dynamic semantics merely because JavaScript is a deployment target.

Backends and adapters must preserve PSCV meaning or be identified as boundaries.

## Appendix G — Feature ownership matrix

### G.1 Ownership rule

For PSCV design, prefer:

~~~text
ordinary dependent/refinement type
  before
new verification syntax

ordinary library theorem/specification
  before
new kernel mechanism

proof-producing automation
  before
trusted solver/oracle

verified effect library
  before
raw world effect

official closed sugar
  before
open source extensibility

explicit boundary assumption
  before
pretending foreign behavior is proved
~~~

### G.2 Ownership decision table

| Need | Preferred owner |
|---|---|
| reusable ordinary computation | library |
| data validity | dependent/refinement type / proof field |
| function behavior | contract / theorem |
| algebraic laws | theorem/law fields in structures/classes |
| loop correctness | PSCV `invariant` / verified iterator spec |
| termination | structural or well-founded recursion / `decreasing` |
| state/error/reader verification | verified effect/WP library |
| resource/async/concurrency reasoning | separately versioned verified effect/capability library |
| proof automation | prover/plugin, outside logical TCB |
| requirement/spec documents | VSDD tooling + canonical formal claims |
| foreign runtime behavior | boundary model/adapter/evidence |
| TypeScript declaration normalization | InterfaceIR importer |
| npm/package resolution | package/platform layer |
| code-generation optimization | compiler/backend layer plus validation |
| target-specific ABI/memory | boundary/system profile |
| genuinely new logical meaning | only then core/kernel change |

### G.3 Language versus verification profile

A capability may be mandatory for `pscv-v1` without becoming a new kernel primitive.

In particular:

- `requires`/`ensures`/`assert`/`invariant`/`decreasing` are source/program-logic facilities;
- ghost state is source relevance/erasure policy;
- `VerifiedExecutableModule` is a compiler semantic state;
- SpecCapsule/EvidenceGraph are build/tooling artifacts;
- all final logical claims still reduce to ordinary propositions/proof terms or equivalent checked judgments over the pinned foundation.

## Appendix H — Glossary and terminology notes

### H.0 PSCV glossary additions

**PSCV** — the strict ProofScript verified-programming profile defined by `pscv-v1`.

**verified executable** — runtime code whose reachable closure satisfies `PSCV-CERT-v1` under an explicit assurance policy.

**proof closure** — all mandatory formal obligations have accepted proof evidence.

**specification coverage** — all declarations/requirements required by policy are linked to approved formal specifications or explicit non-proof evidence categories.

**approved specification** — a formal claim set with a stable identity/digest accepted by the project/release policy.

**SpecCapsule** — the recommended canonical artifact binding approved formal claims, assumptions, profiles, and identities; concrete serialization belongs to VSDD/build specifications.

**type as specification** — an explicit approval that a declaration's complete dependent/refinement type constitutes its public formal specification.

**ghost** — verification-only state/data that must be noninterfering with executable behavior and may be erased.

**boundary assumption** — an explicit proposition/model about externally controlled runtime behavior; it is not automatically proved by the PSCV source proof.

**verified effect** — an effect family equipped with admitted `PSCV-VERIFY-v1` weakest-precondition/Hoare semantics and law evidence.

**VerifiedExecutableModule** — the conceptual compiler state produced only after PSCV certificate gates succeed and required before PSCV code generation.

**assurance vector** — separate reporting of specification, logic/proof, compiler, boundary, and provenance assurance rather than a single ambiguous “verified” bit.


### H.1 Lean-fidelity syntax policy

When ProofScript surface syntax differs from Lean 4.35.0-rc3, the difference SHOULD have an explicit language-facing purpose.

The current edition classifies the main differences as follows:

| ProofScript surface choice | Lean-style baseline | Status |
|---|---|---|
| `function` declaration alias | `def` | retained: application-programming ergonomic alias |
| `const` parameterless definition alias | `def` | retained: explicit value-style declaration alias |
| unified parenthesized explicit parameter groups for functions/declarations/constructors | Lean binder sequence | retained: deliberate uniform ProofScript declaration/call syntax |
| adjacent parenthesized calls `f(x, y)` | whitespace application `f x y` / `f (x, y)` | retained: adjacency cleanly distinguishes multi-argument ProofScript calls from one-argument Lean application |
| named arguments in parenthesized calls | Lean named arguments | retained with ProofScript call syntax |
| empty calls `f()` | no separate Lean core arity model | retained: specified default/optional completion sugar |
| single-term declaration braces `:= { term }` | ordinary term body | retained: grouping only; no statement semantics |
| braced `if` | `if ... then ... else ...` | retained: owned surface sugar over the same conditional meaning |
| braced `match` | layout after `with` | retained: braces group the same ordered alternatives |
| braced inductive body | layout constructors | retained: braces group the same `|` constructor sequence |
| braced instance body | Lean `whereStructInst` sequence | Standard: newline-only; native Lean `;` retained only in `lean-subset-psc2-v1` |
| braced local `where` body | Lean `whereDecls` sequence | Standard: newline-only; native Lean `;` retained only in `lean-subset-psc2-v1` |
| structure/class field declarations | Lean layout fields | aligned: braces group the same layout-separated declaration sequence; no commas |
| braced `do` / proof blocks | Lean supports semicolon-rich forms; tactic `;` also has combinator semantics | Standard `do` and proof sequences are both newline-only; native Lean `;` is compatibility-profile-only |

A new divergence SHOULD NOT be introduced merely for parser convenience when an existing Lean-compatible boundary can be preserved cleanly.

For comma policy specifically, ProofScript distinguishes **list/value syntax** from **declaration sequences**:

- list/value syntax uses explicit commas and optional trailing commas;
- declaration sequences follow Lean-like layout inside optional ProofScript braces.



**ProofScript** — the programming language defined by this reference.


**PSC2** — the current compiler-development milestone and the historical/profile prefix used by its required feature-closure identifiers. PSC2 is not the language name.


**Native** — syntax or semantics taken from the pinned Lean environment only when the active ProofScript profile explicitly includes the category.


**Owned syntax** — a ProofScript production whose parsing or surface meaning is defined directly by the ProofScript specification.


**Source profile** — a versioned set of source grammar and registration rules used to interpret a file.


**Standard** — the closed `ps-standard-0.9-r3` source profile. Ordinary dependencies cannot mutate its grammar.


**Extensible** — `ps-lean-extensible-0.9-r3`, where explicitly declared syntax/Meta extensions are part of the profile/environment identity.


**`psc2-language-v1`** — the exact ProofScript source-language feature closure required by the `psc2-compiler-v1` milestone.


**`psc2-standard-language-v1`** — the PSC2 milestone feature closure plus the closed Standard notation, attributes, fixed semantic option values, and prover surface for that milestone.


**`lean-subset-psc2-v1`** — the bounded native Lean-source compatibility profile associated with the PSC2 compiler milestone. It does not imply full Lean compatibility.



---

## Appendix I — Lean 4.35.0-rc3 exact semantic/source mapping table

### I.1 Repository pin

[lean.pin]

All locators refer to:

~~~text
repository: https://github.com/leanprover/lean4
commit:     470d5ce1400764999581fd26d5d72b00d990b0f4
version:    Lean 4.35.0-rc3
~~~

A locator of the form:

~~~text
path @ blob-sha # symbol/category
~~~

is immutable under this specification. A path at the pinned repository commit is also immutable when a separate blob SHA is not repeated in the table.

### I.2 Core/kernel locators

| Mapping ID | Mode | Exact pinned locator | ProofScript use/restriction |
|---|---|---|---|
| `LEAN-CORE-SORT` | semantic | `src/kernel/type_checker.cpp @ a735a6e42febcc94b45808cbcf30afa4e4af1ca2 # infer_sort / infer_pi`; `src/kernel/level.h @ bc551a636252394de13a963151a4f78608555317` | sorts/universes/Pi universe computation |
| `LEAN-CORE-UNIVERSE-INST` | semantic | `src/kernel/instantiate.cpp @ b845eda9129cc689925e9fd198d19f45f5e3ced8 # instantiate / instantiate_rev`; `src/kernel/level.h @ bc551a636252394de13a963151a4f78608555317` | universe instantiation/substitution |
| `LEAN-CORE-PI` | semantic | `src/kernel/type_checker.cpp @ a735a6e42febcc94b45808cbcf30afa4e4af1ca2 # infer_pi` | Pi formation |
| `LEAN-CORE-LAM` | semantic | `src/kernel/type_checker.cpp @ a735a6e42febcc94b45808cbcf30afa4e4af1ca2 # infer_lambda` | lambda typing |
| `LEAN-CORE-APP` | semantic | `src/kernel/type_checker.cpp @ a735a6e42febcc94b45808cbcf30afa4e4af1ca2 # infer_app` | unary application |
| `LEAN-CORE-LET` | semantic | `src/kernel/type_checker.cpp @ a735a6e42febcc94b45808cbcf30afa4e4af1ca2 # infer_let` | typed `let` |
| `LEAN-CORE-DEFEQ` | semantic | `src/kernel/type_checker.cpp @ a735a6e42febcc94b45808cbcf30afa4e4af1ca2 # is_def_eq / whnf`; `src/kernel/expr_eq_fn.cpp @ fc157a34de8f9d76d3bb0a436862eee8f2daf67b` | conversion/definitional equality |
| `LEAN-CORE-IND` | semantic | `src/kernel/inductive.cpp @ 438f92d3f6df654dbd6bb1a131fd5a15997620e6 # inductive checking / recursor generation` | kernel inductive checking/recursors |
| `LEAN-CORE-EQ` | semantic | declaration: `src/Init/Prelude.lean @ f87ee970af5149d74434f09a89aedff1a8fdb2d2 # Eq`; kernel use/check: `src/kernel/quot.cpp @ 51d399d391cfb16a03071c24696c3f4ec68c98aa # check_eq_type` | propositional equality |
| `LEAN-CORE-QUOT` | semantic | `src/kernel/quot.cpp @ 51d399d391cfb16a03071c24696c3f4ec68c98aa # environment::add_quot` | quotient primitives |
| `LEAN-CORE-EXPR` | semantic | `src/kernel/expr.h @ ea5ce81a4b58792930899f737b01517dc777c387 # expr_kind` | core term constructors |

### I.3 Parser/elaboration locators

| Mapping ID | Mode | Exact pinned locator | Restriction |
|---|---|---|---|
| `LEAN-GRAMMAR-TERM` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # namespace Lean.Parser.Term` | only Appendix-A-listed term productions |
| `LEAN-GRAMMAR-PATTERN` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # matchAlts / pattern parser family` | only `psc2-pattern-v1` |
| `LEAN-GRAMMAR-BINDER-ID` | source-compatible | parser: `src/Lean/Parser/Term/Basic.lean @ f08650b1760f1dceff189043691cd5b4162b0445 # binderIdent`; elaboration: `src/Lean/Elab/Binders.lean @ 11f38a712a1b2233d5a315c2f28f444b04e00086 # toBinderViews / expandBinderIdent` | admitted binder identifiers only |
| `LEAN-GRAMMAR-LEVEL` | source-compatible | `src/Init/Notation.lean @ 9881a62e0ab999ad45cca44cbf54fc63e3b732bc # Parser.Level.level`; level elaboration is pinned to Lean 4.35.0-rc3 source at commit `470d5ce1400764999581fd26d5d72b00d990b0f4` | Standard restriction is `[grammar.universe-level]` |
| `LEAN-GRAMMAR-STRUCT-FIELD` | source-compatible | `src/Lean/Parser/Command.lean @ d838ea83564f634ff5a912c246bdcde6f46b96ef # structExplicitBinder / structImplicitBinder / structInstBinder / structSimpleBinder / structFields` | ProofScript braces group this field-declaration sequence; no comma/semicolon field separator |
| `LEAN-GRAMMAR-CLASS-FIELD` | source-compatible | `src/Lean/Parser/Command.lean @ d838ea83564f634ff5a912c246bdcde6f46b96ef # structFields / classTk / structure` | ProofScript braces group the pinned class-field sequence |
| `LEAN-GRAMMAR-CTOR` | source-compatible | `src/Lean/Parser/Command.lean @ d838ea83564f634ff5a912c246bdcde6f46b96ef # ctor / inductive` | ProofScript braced `|` sequence |
| `LEAN-GRAMMAR-INSTANCE-FIELD` | source-compatible | `src/Lean/Parser/Command.lean @ d838ea83564f634ff5a912c246bdcde6f46b96ef # whereStructInst`, using `Term.structInstField` | native Lean compatibility only; Standard uses Appendix A.12 owned `InstanceField` grammar |
| `LEAN-GRAMMAR-WHERE-FIELD` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # whereDecls` | native Lean compatibility only; Standard local declarations are Appendix A.12 |
| `LEAN-BINDER-IMPLICIT` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # implicitBinder`; `src/Lean/Elab/Binders.lean @ 11f38a712a1b2233d5a315c2f28f444b04e00086 # toBinderViews` | `{x : A}` |
| `LEAN-BINDER-STRICT` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # strictImplicitBinder`; `src/Lean/Elab/Binders.lean @ 11f38a712a1b2233d5a315c2f28f444b04e00086 # toBinderViews` | strict-implicit semantics; admitted ProofScript spelling is defined by the surface grammar |
| `LEAN-BINDER-INSTANCE` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # instBinder`; `src/Lean/Elab/Binders.lean @ 11f38a712a1b2233d5a315c2f28f444b04e00086 # toBinderViews` | instance-implicit binder |
| `LEAN-TERM-FORALL` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # forall` | admitted quantifier surface |
| `LEAN-TERM-EXISTS` | source-compatible | `src/Init/NotationExtra.lean @ 403cc1578424ed8466ed4963d93be58732339460 # macro "∃" / macro "exists"`, expanding explicit binders to `Exists`; proposition declaration provenance is `LEAN-LOGIC-PRELUDE` | admitted existential surface |
| `LEAN-TERM-DO-BASIC` | source-compatible | parser: `src/Lean/Parser/Do.lean @ 92fc8a4455d1ff1e2c61a427739c2dd9a4c5e800 # doSeqItem / doSeqIndent / doSeqBracketed`; elaboration: `src/Lean/Elab/Do/Basic.lean @ 29330123cc418b735fb06fb88376155fc490ffbe # elabDoSeq / elabDoElem` | Appendix A.14 subset only |
| `LEAN-LAYOUT-STRUCT-CLASS` | source-compatible | `src/Lean/Parser/Command.lean @ d838ea83564f634ff5a912c246bdcde6f46b96ef # structFields / structure` | ProofScript outer braces; inner structure/class field layout only |
| `LEAN-LAYOUT-INSTANCE` | source-compatible | `src/Lean/Parser/Command.lean @ d838ea83564f634ff5a912c246bdcde6f46b96ef # whereStructInst` | native Lean compatibility only; Standard `InstanceSep` is newline-only |
| `LEAN-LAYOUT-WHERE` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # whereDecls` | native Lean compatibility only; Standard `WhereSep` is newline-only |
| `LEAN-LAYOUT-DO` | source-compatible | `src/Lean/Parser/Do.lean @ 92fc8a4455d1ff1e2c61a427739c2dd9a4c5e800 # doSeqItem / doSeqIndent / doSeqBracketed / doSeq` | native Lean compatibility only; Standard `DoSep` is newline-only |
| `LEAN-LAYOUT-TACTIC` | source-compatible | `src/Lean/Parser/Term/Basic.lean @ f08650b1760f1dceff189043691cd5b4162b0445 # Tactic.tacticSeqBracketed / tacticSeq1Indented / tacticSeq` | source-compatible Lean profile only; Standard tactic grammar is Chapter 20 |

| `LEAN-TERM-APPLICATION` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # termParser/application parser family`; elaboration `src/Lean/Elab/Term.lean @ bde7a71b234a7d0e787614834662468bd68f3d06 # application elaboration` | Standard subset is Appendix A.6 |
| `LEAN-TERM-PAREN` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # parenthesized term parser` | Appendix A.6 |
| `LEAN-TERM-LAMBDA` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # fun/lambda parser`; `src/Lean/Elab/Term.lean @ bde7a71b234a7d0e787614834662468bd68f3d06 # lambda elaboration` | Appendix A.6 binder subset |
| `LEAN-TERM-LET` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # let parser`; `src/Lean/Elab/Term.lean @ bde7a71b234a7d0e787614834662468bd68f3d06 # let elaboration` | Appendix A.6 single-binding subset |
| `LEAN-TERM-ASCRIPTION` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # typed/ascription parser` | Appendix A.6 |
| `LEAN-TERM-FIELD` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # field notation parser`; elaboration `src/Lean/Elab/Term.lean @ bde7a71b234a7d0e787614834662468bd68f3d06` | semantics restricted by Chapter 22.11 |
| `LEAN-TERM-OPERATOR` | source-compatible | `src/Init/Notation.lean @ 9881a62e0ab999ad45cca44cbf54fc63e3b732bc` | only Chapter-24.2 fixed operators |
| `LEAN-TERM-SORT` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # sort/type parser family` | `Prop`/`Type`/`Sort` subset in Appendix A.6 |
| `LEAN-ELAB-IMPLICIT` | elaboration-reference | `src/Lean/Elab/Term.lean @ bde7a71b234a7d0e787614834662468bd68f3d06 # application elaboration`; binders locator above | overridden/closed by Chapter 22 algorithm |
| `LEAN-ELAB-INSTANCE` | elaboration-reference | `src/Lean/Meta/SynthInstance.lean @ 6a03f9943177bcedd15abdd89665da8dddfe996b # Lean.Meta.SynthInstance / getInstances / synthInstance` | reference locator; normative Standard algorithm is Chapter 22 |
| `LEAN-ELAB-COERCION` | elaboration-reference | `src/Lean/Meta/Coe.lean @ 2590b7f7491eaae9ee6bfc15c31576b5a0fe4473 # coerceSimple? / coerceToFunction? / coerceToSort? / coerce?` | bounded by Chapter 22; `autoLift=false` |
| `LEAN-ELAB-CTOR-SHORTHAND` | elaboration-reference | `src/Lean/Elab/Term.lean @ bde7a71b234a7d0e787614834662468bd68f3d06` anonymous-constructor elaboration | expected type must uniquely determine constructor |
| `LEAN-SCOPE-SECTION` | source-compatible | `src/Lean/Elab/Command.lean @ d1bb776105eda72d35b591e5fa781eedc8939224` section/namespace machinery | only section/variable/include/omit behavior admitted here |

### I.4 Lexical/notation locators

| Mapping ID | Mode | Exact pinned locator |
|---|---|---|
| `LEAN-LEX-IDENT` | source-compatible | `src/Lean/Parser/Basic.lean @ 8a0408220716ee4734aa9e47c1501eac186751e9 # identFnAux / identFn / ident` |
| `LEAN-LEX-COMMENT` | source-compatible | `src/Lean/Parser/Basic.lean @ 8a0408220716ee4734aa9e47c1501eac186751e9` comment scanner |
| `LEAN-LEX-COMMENT-BLOCK` | source-compatible | `src/Lean/Parser/Basic.lean @ 8a0408220716ee4734aa9e47c1501eac186751e9`; nested block comments |
| `LEAN-LEX-NAT` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # natural literal parser`; `OfNat` declarations from exact Standard registry snapshot |
| `LEAN-LEX-SCIENTIFIC` | source-compatible | scanner `src/Lean/Parser/Basic.lean @ 8a0408220716ee4734aa9e47c1501eac186751e9 # scientificLitFn / scientificLitNoAntiquot`; parser `src/Lean/Parser/Extra.lean @ b41124fb0f5d9b594350ae901eeed2b767b82f54 # scientificLit`; term parser `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # scientific`; elaborator `src/Lean/Elab/BuiltinTerm.lean @ 32906b9bc86949c726c2008f6a1caa0ec32464ae # elabScientificLit` | `OfScientific` from exact Standard registry snapshot |
| `LEAN-LEX-STRING` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # string literal parser` |
| `LEAN-LEX-CHAR` | source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d # character literal parser` |
| `LEAN-NOTATION-CORE` | source-compatible | `src/Init/Notation.lean @ 9881a62e0ab999ad45cca44cbf54fc63e3b732bc` — only Chapter 24.2 entries are admitted into Standard grammar |

### I.5 Declaration mappings

| Mapping ID | Mode | Exact pinned locator |
|---|---|---|
| `LEAN-DECL-DEF` | source-compatible | parser: `src/Lean/Parser/Command.lean @ d838ea83564f634ff5a912c246bdcde6f46b96ef # definition`; elaborator: `src/Lean/Elab/Declaration.lean @ 2b85bccd611a741d99f7cb886c531b832aa7447f # elabDeclaration` |
| `LEAN-DECL-EXAMPLE` | source-compatible | parser: `src/Lean/Parser/Command.lean @ d838ea83564f634ff5a912c246bdcde6f46b96ef # example`; declaration path: `src/Lean/Elab/Declaration.lean @ 2b85bccd611a741d99f7cb886c531b832aa7447f # elabDeclaration` |
| `LEAN-DECL-ABBREV` | source-compatible | parser: `src/Lean/Parser/Command.lean @ d838ea83564f634ff5a912c246bdcde6f46b96ef # abbrev`; elaborator: `src/Lean/Elab/Declaration.lean @ 2b85bccd611a741d99f7cb886c531b832aa7447f # elabDeclaration`; Chapter-17 transparency |
| `LEAN-DECL-OPAQUE` | source-compatible | parser: `src/Lean/Parser/Command.lean @ d838ea83564f634ff5a912c246bdcde6f46b96ef # opaque`; elaborator: `src/Lean/Elab/Declaration.lean @ 2b85bccd611a741d99f7cb886c531b832aa7447f # elabDeclaration` |
| `LEAN-DECL-MUTUAL` | source-compatible | parser: `src/Lean/Parser/Command.lean @ d838ea83564f634ff5a912c246bdcde6f46b96ef # mutual`; elaborator: `src/Lean/Elab/Declaration.lean @ 2b85bccd611a741d99f7cb886c531b832aa7447f # elabMutual`; termination restricted by Chapter 18 |

### I.6 Basic propositions/types locators

| Mapping ID | Mode | Exact pinned locator | Source identity |
|---|---|---|---|
| `LEAN-LOGIC-PRELUDE` | library-facing; source-compatible | `src/Init/Prelude.lean @ f87ee970af5149d74434f09a89aedff1a8fdb2d2` | `True`, `False`, `And`, `Or`, `Not`, `Exists`, `Unit`, `Bool`, `Nat`, foundational declarations |
| `LEAN-TYPE-UNIT` | library-facing; source-compatible | Prelude locator above | Standard basis |
| `LEAN-TYPE-BOOL` | library-facing; source-compatible | declaration `src/Init/Prelude.lean @ f87ee970af5149d74434f09a89aedff1a8fdb2d2 # Bool`; operations `src/Init/Data/Bool.lean @ 6345122bdf0b5b466121210144b5c291959cf851` | Standard basis |
| `LEAN-TYPE-NAT` | library-facing; source-compatible | declaration `src/Init/Prelude.lean @ f87ee970af5149d74434f09a89aedff1a8fdb2d2 # Nat`; library `src/Init/Data/Nat.lean @ fb40850f5969cb4ab551be3fe9a38f48c8849a01`; kernel natural-literal optimizations do not redefine source meaning | Standard basis |
| `LEAN-TYPE-INT` | library-facing; source-compatible | `src/Init/Data/Int.lean @ 12819af6d282c2e1b296070ddd2cdd229084e60b` | Standard basis |
| `LEAN-TYPE-UINT-FAMILY` | library-facing; source-compatible | `src/Init/Data/UInt.lean @ f60df7fea0978b86b31fddb2d670f2e8a3dd3791` | exact unsigned registry in Chapter 26 |
| `LEAN-TYPE-SINT-FAMILY` | library-facing; source-compatible | `src/Init/Data/SInt.lean @ e978b75aa3fb53f55e49cedccf9f33e10b7273ea` | exact signed registry in Chapter 26 |
| `LEAN-TYPE-FLOAT` | library-facing; source-compatible | root `src/Init/Data/Float.lean @ 2265cc1e4fa296a8b24281cf3a73e1c151304637`; concrete families/operations `src/Init/Data/Float/Float.lean @ 105ea3d5cf820ad3fd9e2d219dead31b64f6844c` and `src/Init/Data/Float/Float32.lean @ dbc4d183bc60beb0f9140906f756d401ce4119fc` | `Float`, `Float32` |
| `LEAN-TYPE-CHAR` | library-facing; source-compatible | `src/Init/Data/Char.lean @ 80d098519c3419eee8118b91822d336dd56f5be0` | `Char` |
| `LEAN-TYPE-STRING` | library-facing; source-compatible | `src/Init/Data/String.lean @ 70263d92300231a5d2bed1971bd2e171bd2a498a` | `String` |
| `LEAN-TYPE-BYTEARRAY` | library-facing; source-compatible | `src/Init/Data/ByteArray.lean @ eeab7dd85f5101fe7788624303dab3303617c512` | `ByteArray` |
| `LEAN-TYPE-PROD` | library-facing; source-compatible | declaration `src/Init/Prelude.lean @ f87ee970af5149d74434f09a89aedff1a8fdb2d2 # Prod`; library `src/Init/Data/Prod.lean @ 0ac2c7800544105686ed2410e7dd5857cd9bb359` | `Prod` |
| `LEAN-TYPE-SUM` | library-facing; source-compatible | `src/Init/Data/Sum.lean @ 6d89f77fba5552d8e84521e94351b0494126683e` | `Sum` |
| `LEAN-TYPE-OPTION` | library-facing; source-compatible | `src/Init/Data/Option.lean @ 3ab5b8a2fceaf42eda4bc31b58666396cd854d72` | `Option` |
| `LEAN-TYPE-EXCEPT` | library-facing; source-compatible | `src/Init/Control/Except.lean @ b40719f993670975dc3253c2e0f6f7f30db55073` | `Except` |
| `LEAN-TYPE-LIST` | library-facing; source-compatible | declaration `src/Init/Prelude.lean @ f87ee970af5149d74434f09a89aedff1a8fdb2d2 # List`; library `src/Init/Data/List.lean @ c2d0f3f1b43a1259db7980e95229b9f61c924cbb` | `List` |
| `LEAN-TYPE-ARRAY` | library-facing; source-compatible | `src/Init/Data/Array.lean @ d496733cf3b92da75e653c65a06ab0621691e805` | `Array` |
| `LEAN-TYPE-FIN` | library-facing; source-compatible | `src/Init/Data/Fin.lean @ c3bd39d2150183f55acbcdd8f833de418797a0f0` | `Fin` |
| `LEAN-TYPE-SUBTYPE` | library-facing; source-compatible | declaration `src/Init/Prelude.lean @ f87ee970af5149d74434f09a89aedff1a8fdb2d2 # Subtype`; library `src/Init/Data/Subtype.lean @ 3de593e3f15b6188fccd56bf68a1e05ca7b5ca23` | `Subtype` |

### I.6.1 Standard attribute-handler mappings

| Mapping ID | Mode | Exact pinned locator | Standard restriction |
|---|---|---|---|
| `LEAN-ATTR-SIMP` | elaboration-reference | handler `src/Lean/Meta/Tactic/Simp/Attr.lean @ 6f32b30f1af3a65538125fe5b8fbe2785e7c86c0 # mkSimpAttr / registerSimpAttr / simpExtension` | plain `@[simp]` only; no modifiers/custom sets/simproc source registration |
| `LEAN-ATTR-INSTANCE` | elaboration-reference | parser `src/Lean/Parser/Attr.lean @ 5b170c3d4d017181710c6cc260fe094f66f05b19 # instance`; handler `src/Lean/Meta/Instances.lean @ 98ed55bb22bb9d5af101bc354753b0b7f629b730 # addInstance / registerBuiltinAttribute instance` | Standard declaration attribute only; Standard priority rules |
| `LEAN-ATTR-DEFAULT-INSTANCE` | elaboration-reference | parser `src/Lean/Parser/Attr.lean @ 5b170c3d4d017181710c6cc260fe094f66f05b19 # default_instance`; handler `src/Lean/Meta/Instances.lean @ 98ed55bb22bb9d5af101bc354753b0b7f629b730 # addDefaultInstance / default_instance attribute` | global-only; reduced final target must be a type-class application |

### I.7 Standard prover exact locators

All rows use the repository/commit pin in I.1.

| Mapping ID | Mode | Exact locator |
|---|---|
| `LEAN-PROVER-RFL` | prover; source-compatible | `src/Lean/Elab/Tactic/Rfl.lean @ 26650837ddae11ebd8a69d2d52a60c6ee102e565` |
| `LEAN-PROVER-EXACT`, `LEAN-PROVER-APPLY`, `LEAN-PROVER-REFINE`, `LEAN-PROVER-INTRO`, `LEAN-PROVER-ASSUMPTION`, `LEAN-PROVER-CONSTRUCTOR`, `LEAN-PROVER-CASES`, `LEAN-PROVER-SUBST` | prover; source-compatible | `src/Lean/Elab/Tactic/BuiltinTactic.lean @ d9c4ce60d1060de505789cfdb0c71a1d98dcee8a`, exact builtin tactic heads matching the mapping IDs |
| `LEAN-PROVER-EXACTQ` | prover; source-compatible | `src/Lean/Elab/Tactic/LibrarySearch.lean @ 17e947a432cdd86e306fe41e656e9e0ee31e4bce # evalExact / exact?`; parser `src/Init/Tactics.lean @ 4cd586b2368c04282d0df635e06695c3ca2e2bbf # Lean.Parser.Tactic.exact?` |
| `LEAN-PROVER-INDUCTION` | prover; source-compatible | `src/Lean/Elab/Tactic/Induction.lean @ 4b8b54bd3a3d2669a79a33b16a1f7a0fcbaca450` |
| `LEAN-PROVER-RW` | prover; source-compatible | `src/Lean/Elab/Tactic/Rewrite.lean @ 75a3bbe03160f55708edbc2ba142d44f4b8ba7fb` |
| `LEAN-PROVER-SIMP`, `LEAN-PROVER-SIMP-ALL`, `LEAN-PROVER-SIMP-ONLY` | prover; source-compatible | `src/Lean/Elab/Tactic/Simp.lean @ e551319199e05bc3674c97a9408f51ff73b494b2` |
| `LEAN-PROVER-SIMPA` | prover; source-compatible | `src/Lean/Elab/Tactic/Simpa.lean @ 78a534372c1bd8f473ef5aeb5dd08dced228e444` |
| `LEAN-PROVER-UNFOLD` | prover; source-compatible | `src/Lean/Elab/Tactic/Unfold.lean @ fc4be802ed175298ae3096c467352b389b33918a` |
| `LEAN-PROVER-CHANGE` | prover; source-compatible | `src/Lean/Elab/Tactic/Change.lean @ 07722437f8c3fa7124969a031c5b00dda2d14c9c` |
| `LEAN-PROVER-DSIMP` | prover; source-compatible | parser `src/Init/Tactics.lean @ 4cd586b2368c04282d0df635e06695c3ca2e2bbf # Lean.Parser.Tactic.dsimp`; elaboration `src/Lean/Elab/Tactic/Simp.lean @ e551319199e05bc3674c97a9408f51ff73b494b2` |
| `LEAN-PROVER-HAVE`, `LEAN-PROVER-SHOW`, `LEAN-PROVER-SUFFICES` | prover; source-compatible | `src/Lean/Parser/Term.lean @ 4779992cb04db01105346e3b8eab5aed8f6ffe6d` plus `src/Lean/Elab/Term.lean @ bde7a71b234a7d0e787614834662468bd68f3d06` |
| `LEAN-PROVER-BY-CASES`, `LEAN-PROVER-BY-CONTRA`, `LEAN-PROVER-EXFALSO` | prover; source-compatible | `src/Lean/Elab/Tactic/FalseOrByContra.lean @ a3b45ce11a81326802cf813746c153da4ff62a93` plus the exact corresponding builtin tactic heads |
| `LEAN-PROVER-GENERALIZE` | prover; source-compatible | `src/Lean/Elab/Tactic/Generalize.lean @ f67e3b0cb6f5d4c1970d17380c16df3c01f5a424` |
| `LEAN-PROVER-RCASES`, `LEAN-PROVER-RINTRO`, `LEAN-PROVER-OBTAIN`, `LEAN-PROVER-USE` | prover; source-compatible | `src/Lean/Elab/Tactic/RCases.lean @ e1fda580b9107b66e104e2eb0f3316eb249d48c1` |
| `LEAN-PROVER-EXT` | prover; source-compatible | `src/Lean/Elab/Tactic/Ext.lean @ 526ed04905f730e568144cbf0043f439a6d86651` |
| `LEAN-PROVER-DECIDE` | prover; source-compatible | `src/Lean/Elab/Tactic/Decide.lean @ 2e1e51ccdd2b9a913df9e81100389995cbcb8764` |
| `LEAN-PROVER-OMEGA` | prover; source-compatible | `src/Lean/Elab/Tactic/Omega.lean @ 708d3657f2995a06b489e781f8739c80c7b7b8b1` |
| `LEAN-PROVER-GRIND` | prover; source-compatible | entry point: `src/Lean/Elab/Tactic/Grind/Main.lean @ b86a43bffd2bbc1fff37544149b30d85d84dd873 # evalGrind`; Standard theorem/registration state is the final frozen manifest `registry_snapshot.grind`, not ambient Lean imports |
| `LEAN-PROVER-CALC` | prover; source-compatible | equality declaration `src/Init/Prelude.lean @ f87ee970af5149d74434f09a89aedff1a8fdb2d2 # Eq`; chaining theorem `Eq.trans` from the pinned core/prelude; Standard syntax/step order are `[prover.calc]` | equality-only Standard calculation chain |
| `LEAN-PROVER-CLASSICAL` | prover; source-compatible | `src/Lean/Elab/Tactic/Classical.lean @ 6abca3eecc9fa2734b7c31322ca5d9332b6eaa2c` |


### I.8 Lean-source tactic variant registry

[lean.tactic-variants]

`lean-subset-psc2-v1` admits only the tactic source variants in this table. A tactic semantic mapping in I.7 does not by itself admit additional Lean parser variants.

| Variant ID | Mode | Accepted native Lean source form | Semantic mapping |
|---|---|---|---|
| `LEAN-SRC-TAC-RFL-BARE` | source-compatible | `rfl` | `LEAN-PROVER-RFL` |
| `LEAN-SRC-TAC-EXACT-TERM` | source-compatible | `exact term` | `LEAN-PROVER-EXACT` |
| `LEAN-SRC-TAC-EXACTQ-BARE` | source-compatible | `exact?` with no config/`using` | `LEAN-PROVER-EXACTQ` |
| `LEAN-SRC-TAC-APPLY-TERM` | source-compatible | `apply term` | `LEAN-PROVER-APPLY` |
| `LEAN-SRC-TAC-REFINE-TERM` | source-compatible | `refine term` / `refine ?_` | `LEAN-PROVER-REFINE` |
| `LEAN-SRC-TAC-INTRO-IDS` | source-compatible | `intro ident+` | `LEAN-PROVER-INTRO` |
| `LEAN-SRC-TAC-INTROS-BARE` | source-compatible | `intros` | `LEAN-PROVER-INTRO` |
| `LEAN-SRC-TAC-ASSUMPTION-BARE` | source-compatible | `assumption` | `LEAN-PROVER-ASSUMPTION` |
| `LEAN-SRC-TAC-CONSTRUCTOR-BARE` | source-compatible | `constructor` | `LEAN-PROVER-CONSTRUCTOR` |
| `LEAN-SRC-TAC-CASES-TERM` | source-compatible | `cases term` without `with`/`using`/`generalizing` | `LEAN-PROVER-CASES` |
| `LEAN-SRC-TAC-INDUCTION-TERM` | source-compatible | `induction term` without `with`/`using`/`generalizing` | `LEAN-PROVER-INDUCTION` |
| `LEAN-SRC-TAC-RW-LIST` | source-compatible | `rw [item, ...]` without location | `LEAN-PROVER-RW` |
| `LEAN-SRC-TAC-SIMP-ARGS` | source-compatible | `simp` or `simp [items]` without config/location/discharger | `LEAN-PROVER-SIMP` |
| `LEAN-SRC-TAC-SIMP-ONLY-ARGS` | source-compatible | `simp only [items]` | `LEAN-PROVER-SIMP-ONLY` |
| `LEAN-SRC-TAC-SIMPA-ARGS` | source-compatible | `simpa [items]? (using term)?` without config/location | `LEAN-PROVER-SIMPA` |
| `LEAN-SRC-TAC-SIMPALL-ARGS` | source-compatible | `simp_all [items]?` without config | `LEAN-PROVER-SIMP-ALL` |
| `LEAN-SRC-TAC-UNFOLD-NAMES` | source-compatible | `unfold ident+` | `LEAN-PROVER-UNFOLD` |
| `LEAN-SRC-TAC-CHANGE-TERM` | source-compatible | `change term` without location | `LEAN-PROVER-CHANGE` |
| `LEAN-SRC-TAC-DSIMP-ARGS` | source-compatible | `dsimp [items]?` without config/location/discharger | `LEAN-PROVER-DSIMP` |
| `LEAN-SRC-TAC-HAVE` | source-compatible | Chapter-20 `have ident : term := term` | `LEAN-PROVER-HAVE` |
| `LEAN-SRC-TAC-SHOW` | source-compatible | Chapter-20 `show term` | `LEAN-PROVER-SHOW` |
| `LEAN-SRC-TAC-SUFFICES` | source-compatible | Chapter-20 `suffices ident : term from term` | `LEAN-PROVER-SUFFICES` |
| `LEAN-SRC-TAC-BYCASES` | source-compatible | `by_cases ident : term` | `LEAN-PROVER-BY-CASES` |
| `LEAN-SRC-TAC-BYCONTRA` | source-compatible | `by_contra ident?` | `LEAN-PROVER-BY-CONTRA` |
| `LEAN-SRC-TAC-EXFALSO` | source-compatible | `exfalso` | `LEAN-PROVER-EXFALSO` |
| `LEAN-SRC-TAC-SUBST` | source-compatible | `subst ident+` | `LEAN-PROVER-SUBST` |
| `LEAN-SRC-TAC-GENERALIZE` | source-compatible | Chapter-20 `generalize term = ident` | `LEAN-PROVER-GENERALIZE` |
| `LEAN-SRC-TAC-RCASES` | source-compatible | Chapter-20 bounded proof pattern | `LEAN-PROVER-RCASES` |
| `LEAN-SRC-TAC-RINTRO` | source-compatible | Chapter-20 bounded proof pattern | `LEAN-PROVER-RINTRO` |
| `LEAN-SRC-TAC-OBTAIN` | source-compatible | Chapter-20 bounded proof pattern | `LEAN-PROVER-OBTAIN` |
| `LEAN-SRC-TAC-USE` | source-compatible | `use term (, term)*` | `LEAN-PROVER-USE` |
| `LEAN-SRC-TAC-EXT` | source-compatible | `ext ident*` without location/config | `LEAN-PROVER-EXT` |
| `LEAN-SRC-TAC-DECIDE` | source-compatible | `decide` | `LEAN-PROVER-DECIDE` |
| `LEAN-SRC-TAC-OMEGA` | source-compatible | `omega` | `LEAN-PROVER-OMEGA` |
| `LEAN-SRC-TAC-GRIND` | source-compatible | `grind` with no config | `LEAN-PROVER-GRIND` |
| `LEAN-SRC-TAC-CALC-EQ` | source-compatible | equality-only `calc` chain matching `[prover.calc]` | `LEAN-PROVER-CALC` |
| `LEAN-SRC-TAC-CLASSICAL` | source-compatible | `classical` | `LEAN-PROVER-CLASSICAL` |

Native Lean bullets, `case`, tactic `;`, tactic alternatives, `at` locations, configuration records, `cases ... with`, `induction ... with`, `using` clauses other than the admitted `simpa using`, and other Lean tactic syntax are not part of `lean-subset-psc2-v1`.


### I.8.1 Lean-source sequence-separator compatibility

[lean.sequence-semicolon-variants]

These variants belong to `lean-subset-psc2-v1`; none is Standard ProofScript syntax.

| Variant ID | Mode | Accepted native Lean source form | Mapping |
|---|---|---|---|
| `LEAN-SRC-INSTANCE-SEMICOLON` | source-compatible | `where` structure/instance fields separated by `;`, including one trailing `;` where Lean permits it | `LEAN-LAYOUT-INSTANCE` |
| `LEAN-SRC-WHERE-SEMICOLON` | source-compatible | local `where` declarations separated by `;`, including one trailing `;` where Lean permits it | `LEAN-LAYOUT-WHERE` |
| `LEAN-SRC-DO-SEMICOLON` | source-compatible | native Lean braced `do` sequence elements separated by `;` | `LEAN-LAYOUT-DO` |

### I.8A Lean 4.35 intrinsic verification locators

These mappings are normative reference/lowering locators for `PSCV-VERIFY-v1`. They do not transfer proof authority from the kernel to macros, elaborators, or VC generators.

| Mapping ID | Mode | Exact pinned locator | PSCV use/restriction |
|---|---|---|---|
| `LEAN-VERIFY-CONTRACT-435RC3` | elaboration-reference | `src/Lean/Elab/Tactic/Do/Contract.lean @ 7068ffa15544a334efe831bcf63735b48fb3d415 # contract expansion / specification theorem generation` | reference lowering for `given`/`requires`/`ensures`; PSCV still applies SpecCapsule and proof-closure policy |
| `LEAN-VERIFY-VCGEN-435RC3` | prover-reference | `src/Lean/Elab/Tactic/Do/VCGen.lean @ 5bbc95218f4c02c3d22e54d1d26d98d997ff2694 # vcgen` | untrusted VC/proof producer; resulting proof term must be checked |
| `LEAN-VERIFY-DO-SYNTAX-435RC3` | source-reference | `src/Lean/Parser/Do.lean @ 92fc8a4455d1ff1e2c61a427739c2dd9a4c5e800 # doErased / doLoopInvariant / doLoopDecreasing` | reference syntax/shape for erased state, loop invariants and variants; PSCV grammar remains Appendix A |
| `LEAN-VERIFY-DO-ELAB-435RC3` | elaboration-reference | `src/Lean/Elab/Do/Basic.lean @ 29330123cc418b735fb06fb88376155fc490ffbe # intrinsic verification option / mutable-erased state tracking` | reference elaboration behavior; upstream experimental warning is not PSCV semantics |
| `LEAN-VERIFY-ERASED-435RC3` | elaboration-reference | `src/Lean/Elab/BuiltinDo/Let.lean @ 6d04a6c55d134907f666855b1ec062f272f5a538 # erased do binding elaboration` | reference implementation of verification-only bindings/noninterference lowering |
| `LEAN-VERIFY-WP-435RC3` | library/prover-reference | `src/Std/WP.lean @ f08f3c969bbd258dbdff4eb777f0d360c516319d`; `src/Std/WP/Triple.lean @ fba8916ade5d38f106dea218b202d2fcbc4f89ee`; `src/Std/WP/Monad.lean @ 856c339f16b77efd12184fa551db557b7a3e2eb9` | weakest-precondition/Hoare/effect reference semantics for admitted PSCV effects |
| `LEAN-VERIFY-ASSERT-435RC3` | library/prover-reference | `src/Std/WP/Gadget/Assert.lean @ 456ad6f2f5380e1a431441563773ce5b12a82d7d` | reference proof-only assertion gadget |
| `LEAN-VERIFY-FRAME-435RC3` | library/prover-reference | `src/Std/WP/Frame.lean @ fee93fca3e20869e7c6ecd7eebbb23d9de9704a8`; `src/Std/WP/Monad/Frame.lean @ e72402d16c98c075218fe153ffaacb2028ded7a6` | frame-rule precedent; PSCV `reads`/`modifies` semantics remain profile-owned |
| `LEAN-VERIFY-ESTACK-435RC3` | library/prover-reference | `src/Std/WP/EStack.lean @ 3d2156a122df1f1ca5ac9672f4257cfaa2260f6f` | typed exception-postcondition reference model |

### I.9 Locator rule


[lean.locator-rule]

A moving documentation URL such as `/latest/` is never normative for a `LEAN-*` mapping.

Implementations may consult newer Lean documentation for explanation, but conformance is against the immutable commit/path/blob/symbol identities above and the ProofScript restrictions in this reference.
## Appendix J — Complete rule-to-conformance-obligation matrix

[conformance.rule-coverage]

Every standalone normative rule ID outside fenced examples appears exactly once below. Each rule has a stable positive and negative/adversarial executable-test identity.

| Rule ID | Positive obligation ID | Positive obligation | Negative obligation ID | Negative/adversarial obligation | Expected result | Status |
|---|---|---|---|---|---|---|
| `[basic-types.registry]` | `PS-CONF-BASIC-TYPES-REGISTRY-P1` | case satisfying rule | `PS-CONF-BASIC-TYPES-REGISTRY-N1` | case violating rule | behavior matches rule | execution deferred |
| `[call.adjacency]` | `PS-CONF-CALL-ADJACENCY-P1` | accepted source/module/proof case | `PS-CONF-CALL-ADJACENCY-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[call.empty]` | `PS-CONF-CALL-EMPTY-P1` | accepted source/module/proof case | `PS-CONF-CALL-EMPTY-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[call.named-order]` | `PS-CONF-CALL-NAMED-ORDER-P1` | accepted source/module/proof case | `PS-CONF-CALL-NAMED-ORDER-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[call.named-target]` | `PS-CONF-CALL-NAMED-TARGET-P1` | accepted source/module/proof case | `PS-CONF-CALL-NAMED-TARGET-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[call.parenthesized]` | `PS-CONF-CALL-PARENTHESIZED-P1` | accepted source/module/proof case | `PS-CONF-CALL-PARENTHESIZED-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[class.body.braced-grouping]` | `PS-CONF-CLASS-BODY-BRACED-GROUPING-P1` | accepted source/module/proof case | `PS-CONF-CLASS-BODY-BRACED-GROUPING-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[coercion.direct]` | `PS-CONF-COERCION-DIRECT-P1` | specified elaboration/validation case | `PS-CONF-COERCION-DIRECT-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[coercion.excluded]` | `PS-CONF-COERCION-EXCLUDED-P1` | specified elaboration/validation case | `PS-CONF-COERCION-EXCLUDED-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[coercion.fun]` | `PS-CONF-COERCION-FUN-P1` | specified elaboration/validation case | `PS-CONF-COERCION-FUN-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[coercion.registry]` | `PS-CONF-COERCION-REGISTRY-P1` | specified elaboration/validation case | `PS-CONF-COERCION-REGISTRY-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[coercion.sort]` | `PS-CONF-COERCION-SORT-P1` | specified elaboration/validation case | `PS-CONF-COERCION-SORT-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[conformance.canonical-example-wellformed]` | `PS-CONF-CONFORMANCE-CANONICAL-EXAMPLE-WELLFORMED-P1` | release/reference satisfying gate | `PS-CONF-CONFORMANCE-CANONICAL-EXAMPLE-WELLFORMED-N1` | release/reference violating gate | pass / block release | execution deferred |
| `[conformance.coverage-invariant]` | `PS-CONF-CONFORMANCE-COVERAGE-INVARIANT-P1` | release/reference satisfying gate | `PS-CONF-CONFORMANCE-COVERAGE-INVARIANT-N1` | release/reference violating gate | pass / block release | execution deferred |
| `[conformance.execution-deferred]` | `PS-CONF-CONFORMANCE-EXECUTION-DEFERRED-P1` | release/reference satisfying gate | `PS-CONF-CONFORMANCE-EXECUTION-DEFERRED-N1` | release/reference violating gate | pass / block release | execution deferred |
| `[conformance.reference-self-check]` | `PS-CONF-CONFORMANCE-REFERENCE-SELF-CHECK-P1` | release/reference satisfying gate | `PS-CONF-CONFORMANCE-REFERENCE-SELF-CHECK-N1` | release/reference violating gate | pass / block release | execution deferred |
| `[conformance.rule-coverage]` | `PS-CONF-CONFORMANCE-RULE-COVERAGE-P1` | release/reference satisfying gate | `PS-CONF-CONFORMANCE-RULE-COVERAGE-N1` | release/reference violating gate | pass / block release | execution deferred |
| `[conformance.spec-freeze]` | `PS-CONF-CONFORMANCE-SPEC-FREEZE-P1` | release/reference satisfying gate | `PS-CONF-CONFORMANCE-SPEC-FREEZE-N1` | release/reference violating gate | pass / block release | execution deferred |
| `[contract.acceptance]` | `PS-CONF-CONTRACT-ACCEPTANCE-P1` | valid contract case | `PS-CONF-CONTRACT-ACCEPTANCE-N1` | contract violating rule | specified state / reject | execution deferred |
| `[contract.applicability]` | `PS-CONF-CONTRACT-APPLICABILITY-P1` | valid contract case | `PS-CONF-CONTRACT-APPLICABILITY-N1` | contract violating rule | specified state / reject | execution deferred |
| `[contract.call]` | `PS-CONF-CONTRACT-CALL-P1` | valid contract case | `PS-CONF-CONTRACT-CALL-N1` | contract violating rule | specified state / reject | execution deferred |
| `[contract.core-type]` | `PS-CONF-CONTRACT-CORE-TYPE-P1` | valid contract case | `PS-CONF-CONTRACT-CORE-TYPE-N1` | contract violating rule | specified state / reject | execution deferred |
| `[contract.identity]` | `PS-CONF-CONTRACT-IDENTITY-P1` | valid contract case | `PS-CONF-CONTRACT-IDENTITY-N1` | contract violating rule | specified state / reject | execution deferred |
| `[contract.no-runtime-assert]` | `PS-CONF-CONTRACT-NO-RUNTIME-ASSERT-P1` | valid contract case | `PS-CONF-CONTRACT-NO-RUNTIME-ASSERT-N1` | contract violating rule | specified state / reject | execution deferred |
| `[contract.normalization]` | `PS-CONF-CONTRACT-NORMALIZATION-P1` | valid contract case | `PS-CONF-CONTRACT-NORMALIZATION-N1` | contract violating rule | specified state / reject | execution deferred |
| `[contract.obligation]` | `PS-CONF-CONTRACT-OBLIGATION-P1` | valid contract case | `PS-CONF-CONTRACT-OBLIGATION-N1` | contract violating rule | specified state / reject | execution deferred |
| `[contract.scope]` | `PS-CONF-CONTRACT-SCOPE-P1` | valid contract case | `PS-CONF-CONTRACT-SCOPE-N1` | contract violating rule | specified state / reject | execution deferred |
| `[contract.syntax]` | `PS-CONF-CONTRACT-SYNTAX-P1` | valid contract case | `PS-CONF-CONTRACT-SYNTAX-N1` | contract violating rule | specified state / reject | execution deferred |
| `[contract.verified]` | `PS-CONF-CONTRACT-VERIFIED-P1` | valid contract case | `PS-CONF-CONTRACT-VERIFIED-N1` | contract violating rule | specified state / reject | execution deferred |
| `[contract.wellformed]` | `PS-CONF-CONTRACT-WELLFORMED-P1` | valid contract case | `PS-CONF-CONTRACT-WELLFORMED-N1` | contract violating rule | specified state / reject | execution deferred |
| `[core.term.forms]` | `PS-CONF-CORE-TERM-FORMS-P1` | case satisfying rule | `PS-CONF-CORE-TERM-FORMS-N1` | case violating rule | behavior matches rule | execution deferred |
| `[decl.function.body.single-term]` | `PS-CONF-DECL-FUNCTION-BODY-SINGLE-TERM-P1` | accepted source/module/proof case | `PS-CONF-DECL-FUNCTION-BODY-SINGLE-TERM-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[defeq.beta]` | `PS-CONF-DEFEQ-BETA-P1` | core/trust case satisfying rule | `PS-CONF-DEFEQ-BETA-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[defeq.core]` | `PS-CONF-DEFEQ-CORE-P1` | core/trust case satisfying rule | `PS-CONF-DEFEQ-CORE-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[defeq.delta]` | `PS-CONF-DEFEQ-DELTA-P1` | core/trust case satisfying rule | `PS-CONF-DEFEQ-DELTA-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[defeq.eta-fun]` | `PS-CONF-DEFEQ-ETA-FUN-P1` | core/trust case satisfying rule | `PS-CONF-DEFEQ-ETA-FUN-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[defeq.eta-structure]` | `PS-CONF-DEFEQ-ETA-STRUCTURE-P1` | core/trust case satisfying rule | `PS-CONF-DEFEQ-ETA-STRUCTURE-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[defeq.iota]` | `PS-CONF-DEFEQ-IOTA-P1` | core/trust case satisfying rule | `PS-CONF-DEFEQ-IOTA-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[defeq.proj]` | `PS-CONF-DEFEQ-PROJ-P1` | core/trust case satisfying rule | `PS-CONF-DEFEQ-PROJ-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[defeq.proof-irrelevance]` | `PS-CONF-DEFEQ-PROOF-IRRELEVANCE-P1` | core/trust case satisfying rule | `PS-CONF-DEFEQ-PROOF-IRRELEVANCE-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[defeq.quot]` | `PS-CONF-DEFEQ-QUOT-P1` | core/trust case satisfying rule | `PS-CONF-DEFEQ-QUOT-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[defeq.transparency]` | `PS-CONF-DEFEQ-TRANSPARENCY-P1` | core/trust case satisfying rule | `PS-CONF-DEFEQ-TRANSPARENCY-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[defeq.zeta]` | `PS-CONF-DEFEQ-ZETA-P1` | core/trust case satisfying rule | `PS-CONF-DEFEQ-ZETA-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[elab.apply]` | `PS-CONF-ELAB-APPLY-P1` | specified elaboration/validation case | `PS-CONF-ELAB-APPLY-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[elab.coercion.insert]` | `PS-CONF-ELAB-COERCION-INSERT-P1` | specified elaboration/validation case | `PS-CONF-ELAB-COERCION-INSERT-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[elab.constructor]` | `PS-CONF-ELAB-CONSTRUCTOR-P1` | specified elaboration/validation case | `PS-CONF-ELAB-CONSTRUCTOR-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[elab.ctor-shorthand]` | `PS-CONF-ELAB-CTOR-SHORTHAND-P1` | specified elaboration/validation case | `PS-CONF-ELAB-CTOR-SHORTHAND-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[elab.default-application]` | `PS-CONF-ELAB-DEFAULT-APPLICATION-P1` | deterministically solvable elaboration/defaulting case | `PS-CONF-ELAB-DEFAULT-APPLICATION-N1` | forbidden/failing inference case | solve / reject | execution deferred |
| `[elab.default-declaration]` | `PS-CONF-ELAB-DEFAULT-DECLARATION-P1` | deterministically solvable elaboration/defaulting case | `PS-CONF-ELAB-DEFAULT-DECLARATION-N1` | forbidden/failing inference case | solve / reject | execution deferred |
| `[elab.default.insert]` | `PS-CONF-ELAB-DEFAULT-INSERT-P1` | deterministically solvable elaboration/defaulting case | `PS-CONF-ELAB-DEFAULT-INSERT-N1` | forbidden/failing inference case | solve / reject | execution deferred |
| `[elab.defaulting-phase]` | `PS-CONF-ELAB-DEFAULTING-PHASE-P1` | deterministically solvable elaboration/defaulting case | `PS-CONF-ELAB-DEFAULTING-PHASE-N1` | forbidden/failing inference case | solve / reject | execution deferred |
| `[elab.expected-type]` | `PS-CONF-ELAB-EXPECTED-TYPE-P1` | specified elaboration/validation case | `PS-CONF-ELAB-EXPECTED-TYPE-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[elab.field]` | `PS-CONF-ELAB-FIELD-P1` | specified elaboration/validation case | `PS-CONF-ELAB-FIELD-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[elab.if]` | `PS-CONF-ELAB-IF-P1` | specified elaboration/validation case | `PS-CONF-ELAB-IF-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[elab.if-no-truthiness]` | `PS-CONF-ELAB-IF-NO-TRUTHINESS-P1` | specified elaboration/validation case | `PS-CONF-ELAB-IF-NO-TRUTHINESS-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[elab.instance.synth]` | `PS-CONF-ELAB-INSTANCE-SYNTH-P1` | specified elaboration/validation case | `PS-CONF-ELAB-INSTANCE-SYNTH-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[elab.literal]` | `PS-CONF-ELAB-LITERAL-P1` | deterministically solvable elaboration/defaulting case | `PS-CONF-ELAB-LITERAL-N1` | forbidden/failing inference case | solve / reject | execution deferred |
| `[elab.literal-defaults]` | `PS-CONF-ELAB-LITERAL-DEFAULTS-P1` | deterministically solvable elaboration/defaulting case | `PS-CONF-ELAB-LITERAL-DEFAULTS-N1` | forbidden/failing inference case | solve / reject | execution deferred |
| `[elab.literal-expected]` | `PS-CONF-ELAB-LITERAL-EXPECTED-P1` | deterministically solvable elaboration/defaulting case | `PS-CONF-ELAB-LITERAL-EXPECTED-N1` | forbidden/failing inference case | solve / reject | execution deferred |
| `[elab.name.resolve]` | `PS-CONF-ELAB-NAME-RESOLVE-P1` | specified elaboration/validation case | `PS-CONF-ELAB-NAME-RESOLVE-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[elab.named]` | `PS-CONF-ELAB-NAMED-P1` | specified elaboration/validation case | `PS-CONF-ELAB-NAMED-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[elab.record]` | `PS-CONF-ELAB-RECORD-P1` | specified elaboration/validation case | `PS-CONF-ELAB-RECORD-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[elab.record-no-inhabited-fallback]` | `PS-CONF-ELAB-RECORD-NO-INHABITED-FALLBACK-P1` | specified elaboration/validation case | `PS-CONF-ELAB-RECORD-NO-INHABITED-FALLBACK-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[elab.record-update]` | `PS-CONF-ELAB-RECORD-UPDATE-P1` | specified elaboration/validation case | `PS-CONF-ELAB-RECORD-UPDATE-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[elab.reject]` | `PS-CONF-ELAB-REJECT-P1` | specified elaboration/validation case | `PS-CONF-ELAB-REJECT-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[elab.zero-source-function]` | `PS-CONF-ELAB-ZERO-SOURCE-FUNCTION-P1` | specified elaboration/validation case | `PS-CONF-ELAB-ZERO-SOURCE-FUNCTION-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[eq.propositional]` | `PS-CONF-EQ-PROPOSITIONAL-P1` | core/trust case satisfying rule | `PS-CONF-EQ-PROPOSITIONAL-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[grammar.application]` | `PS-CONF-GRAMMAR-APPLICATION-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-APPLICATION-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.application-comment-newline]` | `PS-CONF-GRAMMAR-APPLICATION-COMMENT-NEWLINE-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-APPLICATION-COMMENT-NEWLINE-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.application-layout]` | `PS-CONF-GRAMMAR-APPLICATION-LAYOUT-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-APPLICATION-LAYOUT-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.attributes]` | `PS-CONF-GRAMMAR-ATTRIBUTES-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-ATTRIBUTES-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.authority]` | `PS-CONF-GRAMMAR-AUTHORITY-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-AUTHORITY-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.brace-layout-edge]` | `PS-CONF-GRAMMAR-BRACE-LAYOUT-EDGE-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-BRACE-LAYOUT-EDGE-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.closure]` | `PS-CONF-GRAMMAR-CLOSURE-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-CLOSURE-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.comma-policy]` | `PS-CONF-GRAMMAR-COMMA-POLICY-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-COMMA-POLICY-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.comma-policy-global]` | `PS-CONF-GRAMMAR-COMMA-POLICY-GLOBAL-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-COMMA-POLICY-GLOBAL-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.comma-policy-summary]` | `PS-CONF-GRAMMAR-COMMA-POLICY-SUMMARY-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-COMMA-POLICY-SUMMARY-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.command-layout]` | `PS-CONF-GRAMMAR-COMMAND-LAYOUT-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-COMMAND-LAYOUT-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.declaration]` | `PS-CONF-GRAMMAR-DECLARATION-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-DECLARATION-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.do]` | `PS-CONF-GRAMMAR-DO-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-DO-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.external-nonterminal-registry]` | `PS-CONF-GRAMMAR-EXTERNAL-NONTERMINAL-REGISTRY-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-EXTERNAL-NONTERMINAL-REGISTRY-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.field-layout]` | `PS-CONF-GRAMMAR-FIELD-LAYOUT-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-FIELD-LAYOUT-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.goal]` | `PS-CONF-GRAMMAR-GOAL-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-GOAL-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.instance-where-layout]` | `PS-CONF-GRAMMAR-INSTANCE-WHERE-LAYOUT-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-INSTANCE-WHERE-LAYOUT-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.lexical]` | `PS-CONF-GRAMMAR-LEXICAL-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-LEXICAL-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.no-implicit-extension]` | `PS-CONF-GRAMMAR-NO-IMPLICIT-EXTENSION-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-NO-IMPLICIT-EXTENSION-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.operator-algorithm]` | `PS-CONF-GRAMMAR-OPERATOR-ALGORITHM-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-OPERATOR-ALGORITHM-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.operator-nonassoc]` | `PS-CONF-GRAMMAR-OPERATOR-NONASSOC-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-OPERATOR-NONASSOC-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.operator-term]` | `PS-CONF-GRAMMAR-OPERATOR-TERM-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-OPERATOR-TERM-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.parameter-group-unified]` | `PS-CONF-GRAMMAR-PARAMETER-GROUP-UNIFIED-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-PARAMETER-GROUP-UNIFIED-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.parenthesized-call-adjacency]` | `PS-CONF-GRAMMAR-PARENTHESIZED-CALL-ADJACENCY-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-PARENTHESIZED-CALL-ADJACENCY-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.precedence]` | `PS-CONF-GRAMMAR-PRECEDENCE-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-PRECEDENCE-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.proof]` | `PS-CONF-GRAMMAR-PROOF-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-PROOF-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.sequence-separators]` | `PS-CONF-GRAMMAR-SEQUENCE-SEPARATORS-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-SEQUENCE-SEPARATORS-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.single-definition]` | `PS-CONF-GRAMMAR-SINGLE-DEFINITION-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-SINGLE-DEFINITION-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.source-file]` | `PS-CONF-GRAMMAR-SOURCE-FILE-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-SOURCE-FILE-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.standard-separator-philosophy]` | `PS-CONF-GRAMMAR-STANDARD-SEPARATOR-PHILOSOPHY-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-STANDARD-SEPARATOR-PHILOSOPHY-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.tactic-layout]` | `PS-CONF-GRAMMAR-TACTIC-LAYOUT-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-TACTIC-LAYOUT-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.term]` | `PS-CONF-GRAMMAR-TERM-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-TERM-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.term-body-layout]` | `PS-CONF-GRAMMAR-TERM-BODY-LAYOUT-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-TERM-BODY-LAYOUT-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.tokens]` | `PS-CONF-GRAMMAR-TOKENS-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-TOKENS-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[grammar.top-level-complete]` | `PS-CONF-GRAMMAR-TOP-LEVEL-COMPLETE-P1` | accepted source/module/proof case | `PS-CONF-GRAMMAR-TOP-LEVEL-COMPLETE-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[instance.body.braced-grouping]` | `PS-CONF-INSTANCE-BODY-BRACED-GROUPING-P1` | accepted source/module/proof case | `PS-CONF-INSTANCE-BODY-BRACED-GROUPING-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[instance.default]` | `PS-CONF-INSTANCE-DEFAULT-P1` | specified elaboration/validation case | `PS-CONF-INSTANCE-DEFAULT-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[instance.excluded]` | `PS-CONF-INSTANCE-EXCLUDED-P1` | specified elaboration/validation case | `PS-CONF-INSTANCE-EXCLUDED-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[instance.fields]` | `PS-CONF-INSTANCE-FIELDS-P1` | specified elaboration/validation case | `PS-CONF-INSTANCE-FIELDS-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[instance.goal]` | `PS-CONF-INSTANCE-GOAL-P1` | specified elaboration/validation case | `PS-CONF-INSTANCE-GOAL-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[instance.import-order]` | `PS-CONF-INSTANCE-IMPORT-ORDER-P1` | specified elaboration/validation case | `PS-CONF-INSTANCE-IMPORT-ORDER-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[instance.order]` | `PS-CONF-INSTANCE-ORDER-P1` | specified elaboration/validation case | `PS-CONF-INSTANCE-ORDER-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[instance.parameter-mode-foundation]` | `PS-CONF-INSTANCE-PARAMETER-MODE-FOUNDATION-P1` | specified elaboration/validation case | `PS-CONF-INSTANCE-PARAMETER-MODE-FOUNDATION-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[instance.parameter-modes]` | `PS-CONF-INSTANCE-PARAMETER-MODES-P1` | specified elaboration/validation case | `PS-CONF-INSTANCE-PARAMETER-MODES-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[instance.registry]` | `PS-CONF-INSTANCE-REGISTRY-P1` | specified elaboration/validation case | `PS-CONF-INSTANCE-REGISTRY-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[instance.search]` | `PS-CONF-INSTANCE-SEARCH-P1` | specified elaboration/validation case | `PS-CONF-INSTANCE-SEARCH-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[lean-compat.enumeration]` | `PS-CONF-LEAN-COMPAT-ENUMERATION-P1` | case satisfying rule | `PS-CONF-LEAN-COMPAT-ENUMERATION-N1` | case violating rule | behavior matches rule | execution deferred |
| `[lean.locator-rule]` | `PS-CONF-LEAN-LOCATOR-RULE-P1` | accepted source/module/proof case | `PS-CONF-LEAN-LOCATOR-RULE-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[lean.pin]` | `PS-CONF-LEAN-PIN-P1` | accepted source/module/proof case | `PS-CONF-LEAN-PIN-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[lean.sequence-semicolon-variants]` | `PS-CONF-LEAN-SEQUENCE-SEMICOLON-VARIANTS-P1` | accepted source/module/proof case | `PS-CONF-LEAN-SEQUENCE-SEMICOLON-VARIANTS-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[lean.tactic-variants]` | `PS-CONF-LEAN-TACTIC-VARIANTS-P1` | accepted source/module/proof case | `PS-CONF-LEAN-TACTIC-VARIANTS-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[lex.comments]` | `PS-CONF-LEX-COMMENTS-P1` | accepted source/module/proof case | `PS-CONF-LEX-COMMENTS-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[lex.encoding]` | `PS-CONF-LEX-ENCODING-P1` | accepted source/module/proof case | `PS-CONF-LEX-ENCODING-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[lex.indentation]` | `PS-CONF-LEX-INDENTATION-P1` | accepted source/module/proof case | `PS-CONF-LEX-INDENTATION-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[lex.input-elements]` | `PS-CONF-LEX-INPUT-ELEMENTS-P1` | accepted source/module/proof case | `PS-CONF-LEX-INPUT-ELEMENTS-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[lex.line-endings]` | `PS-CONF-LEX-LINE-ENDINGS-P1` | accepted source/module/proof case | `PS-CONF-LEX-LINE-ENDINGS-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[lex.no-asi]` | `PS-CONF-LEX-NO-ASI-P1` | accepted source/module/proof case | `PS-CONF-LEX-NO-ASI-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[logic.axiom]` | `PS-CONF-LOGIC-AXIOM-P1` | core/trust case satisfying rule | `PS-CONF-LOGIC-AXIOM-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[logic.axiom-type]` | `PS-CONF-LOGIC-AXIOM-TYPE-P1` | core/trust case satisfying rule | `PS-CONF-LOGIC-AXIOM-TYPE-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[logic.bool-distinct]` | `PS-CONF-LOGIC-BOOL-DISTINCT-P1` | core/trust case satisfying rule | `PS-CONF-LOGIC-BOOL-DISTINCT-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[logic.constructive]` | `PS-CONF-LOGIC-CONSTRUCTIVE-P1` | core/trust case satisfying rule | `PS-CONF-LOGIC-CONSTRUCTIVE-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[logic.core]` | `PS-CONF-LOGIC-CORE-P1` | core/trust case satisfying rule | `PS-CONF-LOGIC-CORE-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[logic.standard]` | `PS-CONF-LOGIC-STANDARD-P1` | core/trust case satisfying rule | `PS-CONF-LOGIC-STANDARD-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[match.exhaustive]` | `PS-CONF-MATCH-EXHAUSTIVE-P1` | accepted source/module/proof case | `PS-CONF-MATCH-EXHAUSTIVE-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[match.order]` | `PS-CONF-MATCH-ORDER-P1` | accepted source/module/proof case | `PS-CONF-MATCH-ORDER-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[match.pattern-check]` | `PS-CONF-MATCH-PATTERN-CHECK-P1` | accepted source/module/proof case | `PS-CONF-MATCH-PATTERN-CHECK-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[match.pattern-linearity]` | `PS-CONF-MATCH-PATTERN-LINEARITY-P1` | accepted source/module/proof case | `PS-CONF-MATCH-PATTERN-LINEARITY-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[match.result-type]` | `PS-CONF-MATCH-RESULT-TYPE-P1` | accepted source/module/proof case | `PS-CONF-MATCH-RESULT-TYPE-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[metatheory.lean-defeq]` | `PS-CONF-METATHEORY-LEAN-DEFEQ-P1` | core/trust case satisfying rule | `PS-CONF-METATHEORY-LEAN-DEFEQ-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[module.import-acyclic]` | `PS-CONF-MODULE-IMPORT-ACYCLIC-P1` | accepted source/module/proof case | `PS-CONF-MODULE-IMPORT-ACYCLIC-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[module.import-dedup]` | `PS-CONF-MODULE-IMPORT-DEDUP-P1` | accepted source/module/proof case | `PS-CONF-MODULE-IMPORT-DEDUP-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[module.import-header]` | `PS-CONF-MODULE-IMPORT-HEADER-P1` | accepted source/module/proof case | `PS-CONF-MODULE-IMPORT-HEADER-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[module.import-order]` | `PS-CONF-MODULE-IMPORT-ORDER-P1` | accepted source/module/proof case | `PS-CONF-MODULE-IMPORT-ORDER-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[module.registration-dedup]` | `PS-CONF-MODULE-REGISTRATION-DEDUP-P1` | accepted source/module/proof case | `PS-CONF-MODULE-REGISTRATION-DEDUP-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[module.registration-propagation]` | `PS-CONF-MODULE-REGISTRATION-PROPAGATION-P1` | accepted source/module/proof case | `PS-CONF-MODULE-REGISTRATION-PROPAGATION-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[name.ambiguous]` | `PS-CONF-NAME-AMBIGUOUS-P1` | resolvable name | `PS-CONF-NAME-AMBIGUOUS-N1` | ambiguous/invisible name | resolve / reject | execution deferred |
| `[name.decl-identity]` | `PS-CONF-NAME-DECL-IDENTITY-P1` | resolvable name | `PS-CONF-NAME-DECL-IDENTITY-N1` | ambiguous/invisible name | resolve / reject | execution deferred |
| `[name.import]` | `PS-CONF-NAME-IMPORT-P1` | resolvable name | `PS-CONF-NAME-IMPORT-N1` | ambiguous/invisible name | resolve / reject | execution deferred |
| `[name.include-omit]` | `PS-CONF-NAME-INCLUDE-OMIT-P1` | resolvable name | `PS-CONF-NAME-INCLUDE-OMIT-N1` | ambiguous/invisible name | resolve / reject | execution deferred |
| `[name.local]` | `PS-CONF-NAME-LOCAL-P1` | resolvable name | `PS-CONF-NAME-LOCAL-N1` | ambiguous/invisible name | resolve / reject | execution deferred |
| `[name.lookup]` | `PS-CONF-NAME-LOOKUP-P1` | resolvable name | `PS-CONF-NAME-LOOKUP-N1` | ambiguous/invisible name | resolve / reject | execution deferred |
| `[name.namespace]` | `PS-CONF-NAME-NAMESPACE-P1` | resolvable name | `PS-CONF-NAME-NAMESPACE-N1` | ambiguous/invisible name | resolve / reject | execution deferred |
| `[name.open]` | `PS-CONF-NAME-OPEN-P1` | resolvable name | `PS-CONF-NAME-OPEN-N1` | ambiguous/invisible name | resolve / reject | execution deferred |
| `[name.qualified]` | `PS-CONF-NAME-QUALIFIED-P1` | resolvable name | `PS-CONF-NAME-QUALIFIED-N1` | ambiguous/invisible name | resolve / reject | execution deferred |
| `[name.section]` | `PS-CONF-NAME-SECTION-P1` | resolvable name | `PS-CONF-NAME-SECTION-N1` | ambiguous/invisible name | resolve / reject | execution deferred |
| `[profile.standard.tactics]` | `PS-CONF-PROFILE-STANDARD-TACTICS-P1` | case satisfying rule | `PS-CONF-PROFILE-STANDARD-TACTICS-N1` | case violating rule | behavior matches rule | execution deferred |
| `[proof.statement-prop]` | `PS-CONF-PROOF-STATEMENT-PROP-P1` | core/trust case satisfying rule | `PS-CONF-PROOF-STATEMENT-PROP-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[prover.calc]` | `PS-CONF-PROVER-CALC-P1` | accepted source/module/proof case | `PS-CONF-PROVER-CALC-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[prover.grammar]` | `PS-CONF-PROVER-GRAMMAR-P1` | accepted source/module/proof case | `PS-CONF-PROVER-GRAMMAR-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[prover.sequence]` | `PS-CONF-PROVER-SEQUENCE-P1` | accepted source/module/proof case | `PS-CONF-PROVER-SEQUENCE-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[prover.soundness]` | `PS-CONF-PROVER-SOUNDNESS-P1` | accepted source/module/proof case | `PS-CONF-PROVER-SOUNDNESS-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[prover.standard.closed]` | `PS-CONF-PROVER-STANDARD-CLOSED-P1` | accepted source/module/proof case | `PS-CONF-PROVER-STANDARD-CLOSED-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[prover.validation]` | `PS-CONF-PROVER-VALIDATION-P1` | accepted source/module/proof case | `PS-CONF-PROVER-VALIDATION-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[record-update.comma-policy]` | `PS-CONF-RECORD-UPDATE-COMMA-POLICY-P1` | case satisfying rule | `PS-CONF-RECORD-UPDATE-COMMA-POLICY-N1` | case violating rule | behavior matches rule | execution deferred |
| `[record.comma-policy]` | `PS-CONF-RECORD-COMMA-POLICY-P1` | case satisfying rule | `PS-CONF-RECORD-COMMA-POLICY-N1` | case violating rule | behavior matches rule | execution deferred |
| `[recursion.elaboration]` | `PS-CONF-RECURSION-ELABORATION-P1` | allowed total/partial recursion case | `PS-CONF-RECURSION-ELABORATION-N1` | forbidden recursion/dependency case | accept / reject | execution deferred |
| `[recursion.excluded]` | `PS-CONF-RECURSION-EXCLUDED-P1` | allowed total/partial recursion case | `PS-CONF-RECURSION-EXCLUDED-N1` | forbidden recursion/dependency case | accept / reject | execution deferred |
| `[recursion.exhaustion]` | `PS-CONF-RECURSION-EXHAUSTION-P1` | allowed total/partial recursion case | `PS-CONF-RECURSION-EXHAUSTION-N1` | forbidden recursion/dependency case | accept / reject | execution deferred |
| `[recursion.local]` | `PS-CONF-RECURSION-LOCAL-P1` | allowed total/partial recursion case | `PS-CONF-RECURSION-LOCAL-N1` | forbidden recursion/dependency case | accept / reject | execution deferred |
| `[recursion.mutual]` | `PS-CONF-RECURSION-MUTUAL-P1` | allowed total/partial recursion case | `PS-CONF-RECURSION-MUTUAL-N1` | forbidden recursion/dependency case | accept / reject | execution deferred |
| `[recursion.noncomputable]` | `PS-CONF-RECURSION-NONCOMPUTABLE-P1` | allowed total/partial recursion case | `PS-CONF-RECURSION-NONCOMPUTABLE-N1` | forbidden recursion/dependency case | accept / reject | execution deferred |
| `[recursion.partial]` | `PS-CONF-RECURSION-PARTIAL-P1` | allowed total/partial recursion case | `PS-CONF-RECURSION-PARTIAL-N1` | forbidden recursion/dependency case | accept / reject | execution deferred |
| `[recursion.partial-reference]` | `PS-CONF-RECURSION-PARTIAL-REFERENCE-P1` | allowed total/partial recursion case | `PS-CONF-RECURSION-PARTIAL-REFERENCE-N1` | forbidden recursion/dependency case | accept / reject | execution deferred |
| `[recursion.partial-signature]` | `PS-CONF-RECURSION-PARTIAL-SIGNATURE-P1` | allowed total/partial recursion case | `PS-CONF-RECURSION-PARTIAL-SIGNATURE-N1` | forbidden recursion/dependency case | accept / reject | execution deferred |
| `[recursion.partial-trust]` | `PS-CONF-RECURSION-PARTIAL-TRUST-P1` | allowed total/partial recursion case | `PS-CONF-RECURSION-PARTIAL-TRUST-N1` | forbidden recursion/dependency case | accept / reject | execution deferred |
| `[recursion.self-call]` | `PS-CONF-RECURSION-SELF-CALL-P1` | allowed total/partial recursion case | `PS-CONF-RECURSION-SELF-CALL-N1` | forbidden recursion/dependency case | accept / reject | execution deferred |
| `[recursion.structural]` | `PS-CONF-RECURSION-STRUCTURAL-P1` | allowed total/partial recursion case | `PS-CONF-RECURSION-STRUCTURAL-N1` | forbidden recursion/dependency case | accept / reject | execution deferred |
| `[recursion.structural-arg]` | `PS-CONF-RECURSION-STRUCTURAL-ARG-P1` | allowed total/partial recursion case | `PS-CONF-RECURSION-STRUCTURAL-ARG-N1` | forbidden recursion/dependency case | accept / reject | execution deferred |
| `[recursion.subterm]` | `PS-CONF-RECURSION-SUBTERM-P1` | allowed total/partial recursion case | `PS-CONF-RECURSION-SUBTERM-N1` | forbidden recursion/dependency case | accept / reject | execution deferred |
| `[runtime.backend-independent]` | `PS-CONF-RUNTIME-BACKEND-INDEPENDENT-P1` | case satisfying rule | `PS-CONF-RUNTIME-BACKEND-INDEPENDENT-N1` | case violating rule | behavior matches rule | execution deferred |
| `[runtime.eval]` | `PS-CONF-RUNTIME-EVAL-P1` | case satisfying rule | `PS-CONF-RUNTIME-EVAL-N1` | case violating rule | behavior matches rule | execution deferred |
| `[runtime.exhaustion]` | `PS-CONF-RUNTIME-EXHAUSTION-P1` | case satisfying rule | `PS-CONF-RUNTIME-EXHAUSTION-N1` | case violating rule | behavior matches rule | execution deferred |
| `[runtime.foreign-boundary]` | `PS-CONF-RUNTIME-FOREIGN-BOUNDARY-P1` | case satisfying rule | `PS-CONF-RUNTIME-FOREIGN-BOUNDARY-N1` | case violating rule | behavior matches rule | execution deferred |
| `[runtime.noncomputable]` | `PS-CONF-RUNTIME-NONCOMPUTABLE-P1` | case satisfying rule | `PS-CONF-RUNTIME-NONCOMPUTABLE-N1` | case violating rule | behavior matches rule | execution deferred |
| `[runtime.partial]` | `PS-CONF-RUNTIME-PARTIAL-P1` | case satisfying rule | `PS-CONF-RUNTIME-PARTIAL-N1` | case violating rule | behavior matches rule | execution deferred |
| `[runtime.proof-erasure]` | `PS-CONF-RUNTIME-PROOF-ERASURE-P1` | case satisfying rule | `PS-CONF-RUNTIME-PROOF-ERASURE-N1` | case violating rule | behavior matches rule | execution deferred |
| `[runtime.relevance]` | `PS-CONF-RUNTIME-RELEVANCE-P1` | case satisfying rule | `PS-CONF-RUNTIME-RELEVANCE-N1` | case violating rule | behavior matches rule | execution deferred |
| `[semantic.no-host-redefinition]` | `PS-CONF-SEMANTIC-NO-HOST-REDEFINITION-P1` | case satisfying rule | `PS-CONF-SEMANTIC-NO-HOST-REDEFINITION-N1` | case violating rule | behavior matches rule | execution deferred |
| `[semantic.pin]` | `PS-CONF-SEMANTIC-PIN-P1` | case satisfying rule | `PS-CONF-SEMANTIC-PIN-N1` | case violating rule | behavior matches rule | execution deferred |
| `[standard.attribute-boundary]` | `PS-CONF-STANDARD-ATTRIBUTE-BOUNDARY-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-ATTRIBUTE-BOUNDARY-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.attribute-default-instance]` | `PS-CONF-STANDARD-ATTRIBUTE-DEFAULT-INSTANCE-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-ATTRIBUTE-DEFAULT-INSTANCE-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.attribute-instance]` | `PS-CONF-STANDARD-ATTRIBUTE-INSTANCE-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-ATTRIBUTE-INSTANCE-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.attribute-semantics]` | `PS-CONF-STANDARD-ATTRIBUTE-SEMANTICS-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-ATTRIBUTE-SEMANTICS-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.attribute-simp]` | `PS-CONF-STANDARD-ATTRIBUTE-SIMP-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-ATTRIBUTE-SIMP-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.attributes]` | `PS-CONF-STANDARD-ATTRIBUTES-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-ATTRIBUTES-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.class-mode-provenance]` | `PS-CONF-STANDARD-CLASS-MODE-PROVENANCE-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-CLASS-MODE-PROVENANCE-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.class-parameter-modes]` | `PS-CONF-STANDARD-CLASS-PARAMETER-MODES-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-CLASS-PARAMETER-MODES-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.classical]` | `PS-CONF-STANDARD-CLASSICAL-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-CLASSICAL-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.coercions]` | `PS-CONF-STANDARD-COERCIONS-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-COERCIONS-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.declaration-provenance]` | `PS-CONF-STANDARD-DECLARATION-PROVENANCE-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-DECLARATION-PROVENANCE-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.equality-operators]` | `PS-CONF-STANDARD-EQUALITY-OPERATORS-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-EQUALITY-OPERATORS-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.ext]` | `PS-CONF-STANDARD-EXT-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-EXT-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.grammar]` | `PS-CONF-STANDARD-GRAMMAR-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-GRAMMAR-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.grind]` | `PS-CONF-STANDARD-GRIND-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-GRIND-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.identity]` | `PS-CONF-STANDARD-IDENTITY-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-IDENTITY-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.instances]` | `PS-CONF-STANDARD-INSTANCES-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-INSTANCES-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.manifest-filter]` | `PS-CONF-STANDARD-MANIFEST-FILTER-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-MANIFEST-FILTER-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.notation]` | `PS-CONF-STANDARD-NOTATION-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-NOTATION-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.omega]` | `PS-CONF-STANDARD-OMEGA-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-OMEGA-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.options]` | `PS-CONF-STANDARD-OPTIONS-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-OPTIONS-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.options-catchall]` | `PS-CONF-STANDARD-OPTIONS-CATCHALL-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-OPTIONS-CATCHALL-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.registration-order]` | `PS-CONF-STANDARD-REGISTRATION-ORDER-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-REGISTRATION-ORDER-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.registry-digest]` | `PS-CONF-STANDARD-REGISTRY-DIGEST-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-REGISTRY-DIGEST-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.registry-manifest]` | `PS-CONF-STANDARD-REGISTRY-MANIFEST-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-REGISTRY-MANIFEST-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.registry-provenance]` | `PS-CONF-STANDARD-REGISTRY-PROVENANCE-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-REGISTRY-PROVENANCE-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.registry-provenance-evidence]` | `PS-CONF-STANDARD-REGISTRY-PROVENANCE-EVIDENCE-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-REGISTRY-PROVENANCE-EVIDENCE-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.reproducible]` | `PS-CONF-STANDARD-REPRODUCIBLE-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-REPRODUCIBLE-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.required-surface]` | `PS-CONF-STANDARD-REQUIRED-SURFACE-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-REQUIRED-SURFACE-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.simp]` | `PS-CONF-STANDARD-SIMP-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-SIMP-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.simp-intrinsics]` | `PS-CONF-STANDARD-SIMP-INTRINSICS-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-SIMP-INTRINSICS-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.surface-snapshot-closure]` | `PS-CONF-STANDARD-SURFACE-SNAPSHOT-CLOSURE-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-SURFACE-SNAPSHOT-CLOSURE-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[standard.tooling-boundary]` | `PS-CONF-STANDARD-TOOLING-BOUNDARY-P1` | matching manifest/environment/provenance | `PS-CONF-STANDARD-TOOLING-BOUNDARY-N1` | violating manifest/environment/provenance | conform / reject profile claim | execution deferred |
| `[struct.body.braced-grouping]` | `PS-CONF-STRUCT-BODY-BRACED-GROUPING-P1` | accepted source/module/proof case | `PS-CONF-STRUCT-BODY-BRACED-GROUPING-N1` | nearest violating case | accept/meaning exactly as specified | execution deferred |
| `[trust.environment]` | `PS-CONF-TRUST-ENVIRONMENT-P1` | core/trust case satisfying rule | `PS-CONF-TRUST-ENVIRONMENT-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[trust.no-proof-holes]` | `PS-CONF-TRUST-NO-PROOF-HOLES-P1` | core/trust case satisfying rule | `PS-CONF-TRUST-NO-PROOF-HOLES-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[trust.proof-term]` | `PS-CONF-TRUST-PROOF-TERM-P1` | core/trust case satisfying rule | `PS-CONF-TRUST-PROOF-TERM-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[tuple.comma-policy]` | `PS-CONF-TUPLE-COMMA-POLICY-P1` | case satisfying rule | `PS-CONF-TUPLE-COMMA-POLICY-N1` | case violating rule | behavior matches rule | execution deferred |
| `[type.app]` | `PS-CONF-TYPE-APP-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-APP-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.array]` | `PS-CONF-TYPE-ARRAY-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-ARRAY-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.ascription]` | `PS-CONF-TYPE-ASCRIPTION-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-ASCRIPTION-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.bool]` | `PS-CONF-TYPE-BOOL-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-BOOL-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.bytearray]` | `PS-CONF-TYPE-BYTEARRAY-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-BYTEARRAY-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.char]` | `PS-CONF-TYPE-CHAR-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-CHAR-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.class-constraint]` | `PS-CONF-TYPE-CLASS-CONSTRAINT-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-CLASS-CONSTRAINT-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.coercion]` | `PS-CONF-TYPE-COERCION-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-COERCION-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.const]` | `PS-CONF-TYPE-CONST-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-CONST-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.context]` | `PS-CONF-TYPE-CONTEXT-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-CONTEXT-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.convert]` | `PS-CONF-TYPE-CONVERT-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-CONVERT-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.data]` | `PS-CONF-TYPE-DATA-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-DATA-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.eq]` | `PS-CONF-TYPE-EQ-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-EQ-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.equality-kinds]` | `PS-CONF-TYPE-EQUALITY-KINDS-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-EQUALITY-KINDS-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.except]` | `PS-CONF-TYPE-EXCEPT-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-EXCEPT-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.fin]` | `PS-CONF-TYPE-FIN-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-FIN-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.fixed-int]` | `PS-CONF-TYPE-FIXED-INT-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-FIXED-INT-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.fixed-int-literals]` | `PS-CONF-TYPE-FIXED-INT-LITERALS-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-FIXED-INT-LITERALS-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.float]` | `PS-CONF-TYPE-FLOAT-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-FLOAT-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.inductive]` | `PS-CONF-TYPE-INDUCTIVE-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-INDUCTIVE-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.int]` | `PS-CONF-TYPE-INT-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-INT-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.lambda]` | `PS-CONF-TYPE-LAMBDA-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-LAMBDA-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.let]` | `PS-CONF-TYPE-LET-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-LET-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.list]` | `PS-CONF-TYPE-LIST-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-LIST-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.nat]` | `PS-CONF-TYPE-NAT-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-NAT-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.option]` | `PS-CONF-TYPE-OPTION-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-OPTION-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.pi.form]` | `PS-CONF-TYPE-PI-FORM-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-PI-FORM-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.pi.syntax]` | `PS-CONF-TYPE-PI-SYNTAX-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-PI-SYNTAX-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.prod]` | `PS-CONF-TYPE-PROD-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-PROD-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.projection]` | `PS-CONF-TYPE-PROJECTION-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-PROJECTION-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.proof-irrelevance]` | `PS-CONF-TYPE-PROOF-IRRELEVANCE-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-PROOF-IRRELEVANCE-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.prop]` | `PS-CONF-TYPE-PROP-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-PROP-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.quot]` | `PS-CONF-TYPE-QUOT-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-QUOT-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.reject]` | `PS-CONF-TYPE-REJECT-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-REJECT-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.sort]` | `PS-CONF-TYPE-SORT-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-SORT-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.string]` | `PS-CONF-TYPE-STRING-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-STRING-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.subtype]` | `PS-CONF-TYPE-SUBTYPE-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-SUBTYPE-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.sum]` | `PS-CONF-TYPE-SUM-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-SUM-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.unit]` | `PS-CONF-TYPE-UNIT-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-UNIT-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[type.universe.syntax]` | `PS-CONF-TYPE-UNIVERSE-SYNTAX-P1` | core/trust case satisfying rule | `PS-CONF-TYPE-UNIVERSE-SYNTAX-N1` | non-related/forbidden case | kernel/trust relation as specified | execution deferred |
| `[unify.assign]` | `PS-CONF-UNIFY-ASSIGN-P1` | deterministically solvable elaboration/defaulting case | `PS-CONF-UNIFY-ASSIGN-N1` | forbidden/failing inference case | solve / reject | execution deferred |
| `[unify.decompose]` | `PS-CONF-UNIFY-DECOMPOSE-P1` | deterministically solvable elaboration/defaulting case | `PS-CONF-UNIFY-DECOMPOSE-N1` | forbidden/failing inference case | solve / reject | execution deferred |
| `[unify.level]` | `PS-CONF-UNIFY-LEVEL-P1` | deterministically solvable elaboration/defaulting case | `PS-CONF-UNIFY-LEVEL-N1` | forbidden/failing inference case | solve / reject | execution deferred |
| `[unify.no-search]` | `PS-CONF-UNIFY-NO-SEARCH-P1` | deterministically solvable elaboration/defaulting case | `PS-CONF-UNIFY-NO-SEARCH-N1` | forbidden/failing inference case | solve / reject | execution deferred |
| `[unify.order]` | `PS-CONF-UNIFY-ORDER-P1` | deterministically solvable elaboration/defaulting case | `PS-CONF-UNIFY-ORDER-N1` | forbidden/failing inference case | solve / reject | execution deferred |
| `[unify.postpone]` | `PS-CONF-UNIFY-POSTPONE-P1` | deterministically solvable elaboration/defaulting case | `PS-CONF-UNIFY-POSTPONE-N1` | forbidden/failing inference case | solve / reject | execution deferred |
| `[unify.result]` | `PS-CONF-UNIFY-RESULT-P1` | deterministically solvable elaboration/defaulting case | `PS-CONF-UNIFY-RESULT-N1` | forbidden/failing inference case | solve / reject | execution deferred |
| `[unify.standard]` | `PS-CONF-UNIFY-STANDARD-P1` | deterministically solvable elaboration/defaulting case | `PS-CONF-UNIFY-STANDARD-N1` | forbidden/failing inference case | solve / reject | execution deferred |
| `[unify.whnf]` | `PS-CONF-UNIFY-WHNF-P1` | deterministically solvable elaboration/defaulting case | `PS-CONF-UNIFY-WHNF-N1` | forbidden/failing inference case | solve / reject | execution deferred |
| `[validation.attributes]` | `PS-CONF-VALIDATION-ATTRIBUTES-P1` | specified elaboration/validation case | `PS-CONF-VALIDATION-ATTRIBUTES-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[validation.partial-boundary]` | `PS-CONF-VALIDATION-PARTIAL-BOUNDARY-P1` | specified elaboration/validation case | `PS-CONF-VALIDATION-PARTIAL-BOUNDARY-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |
| `[validation.program]` | `PS-CONF-VALIDATION-PROGRAM-P1` | specified elaboration/validation case | `PS-CONF-VALIDATION-PROGRAM-N1` | forbidden/ambiguous case | deterministic result / reject | execution deferred |

### J.1 Coverage invariant

[conformance.coverage-invariant]

The standalone normative rule-ID set, Appendix-J self-rules, and PSCV J.3 rule set MUST equal the union of Appendix-J rule IDs and the `PS-CONF-*` / `PSCV-CONF-*` obligation-ID domains. Duplicate rule definitions or obligation IDs are publication errors.

### J.2 Execution state

[conformance.execution-deferred]

The reference-integrity subset of conformance is executable and MUST pass for publication. Full parser/elaborator/prover/kernel conformance remains the implementation release gate.


### J.3 PSCV rule-to-conformance obligations

[pscv.conformance.rule-coverage]

Every standalone `pscv.*` rule in this reference has a positive and adversarial obligation identity below. A final `pscv-compiler-v1` release MUST replace the design-RC execution state with executable evidence.

| Rule ID | Positive obligation ID | Positive obligation | Negative obligation ID | Negative/adversarial obligation | Expected result | Status |
|---|---|---|---|---|---|---|
| `[pscv.ai]` | `PSCV-CONF-PSCV-AI-P1` | conforming PSCV case | `PSCV-CONF-PSCV-AI-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.assert]` | `PSCV-CONF-PSCV-ASSERT-P1` | conforming PSCV case | `PSCV-CONF-PSCV-ASSERT-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.assurance.vector]` | `PSCV-CONF-PSCV-ASSURANCE-VECTOR-P1` | conforming PSCV case | `PSCV-CONF-PSCV-ASSURANCE-VECTOR-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.axiom.user-reject]` | `PSCV-CONF-PSCV-AXIOM-USER-REJECT-P1` | conforming PSCV case | `PSCV-CONF-PSCV-AXIOM-USER-REJECT-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.certificate]` | `PSCV-CONF-PSCV-CERTIFICATE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-CERTIFICATE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.class.laws]` | `PSCV-CONF-PSCV-CLASS-LAWS-P1` | conforming PSCV case | `PSCV-CONF-PSCV-CLASS-LAWS-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.conformance.environment]` | `PSCV-CONF-PSCV-CONFORMANCE-ENVIRONMENT-P1` | conforming PSCV case | `PSCV-CONF-PSCV-CONFORMANCE-ENVIRONMENT-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.conformance.execution]` | `PSCV-CONF-PSCV-CONFORMANCE-EXECUTION-P1` | conforming PSCV case | `PSCV-CONF-PSCV-CONFORMANCE-EXECUTION-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.conformance.proof]` | `PSCV-CONF-PSCV-CONFORMANCE-PROOF-P1` | conforming PSCV case | `PSCV-CONF-PSCV-CONFORMANCE-PROOF-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.conformance.rule-coverage]` | `PSCV-CONF-PSCV-CONFORMANCE-RULE-COVERAGE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-CONFORMANCE-RULE-COVERAGE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.conformance.source]` | `PSCV-CONF-PSCV-CONFORMANCE-SOURCE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-CONFORMANCE-SOURCE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.conformance.verification]` | `PSCV-CONF-PSCV-CONFORMANCE-VERIFICATION-P1` | conforming PSCV case | `PSCV-CONF-PSCV-CONFORMANCE-VERIFICATION-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.contract.body]` | `PSCV-CONF-PSCV-CONTRACT-BODY-P1` | conforming PSCV case | `PSCV-CONF-PSCV-CONTRACT-BODY-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.contract.call-post]` | `PSCV-CONF-PSCV-CONTRACT-CALL-POST-P1` | conforming PSCV case | `PSCV-CONF-PSCV-CONTRACT-CALL-POST-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.contract.call-pre]` | `PSCV-CONF-PSCV-CONTRACT-CALL-PRE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-CONTRACT-CALL-PRE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.contract.given]` | `PSCV-CONF-PSCV-CONTRACT-GIVEN-P1` | conforming PSCV case | `PSCV-CONF-PSCV-CONTRACT-GIVEN-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.contract.identity]` | `PSCV-CONF-PSCV-CONTRACT-IDENTITY-P1` | conforming PSCV case | `PSCV-CONF-PSCV-CONTRACT-IDENTITY-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.contract.required-proof]` | `PSCV-CONF-PSCV-CONTRACT-REQUIRED-PROOF-P1` | conforming PSCV case | `PSCV-CONF-PSCV-CONTRACT-REQUIRED-PROOF-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.definition.not-self-specifying]` | `PSCV-CONF-PSCV-DEFINITION-NOT-SELF-SPECIFYING-P1` | conforming PSCV case | `PSCV-CONF-PSCV-DEFINITION-NOT-SELF-SPECIFYING-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.do.effect]` | `PSCV-CONF-PSCV-DO-EFFECT-P1` | conforming PSCV case | `PSCV-CONF-PSCV-DO-EFFECT-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.do.local-mutation]` | `PSCV-CONF-PSCV-DO-LOCAL-MUTATION-P1` | conforming PSCV case | `PSCV-CONF-PSCV-DO-LOCAL-MUTATION-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.do.return]` | `PSCV-CONF-PSCV-DO-RETURN-P1` | conforming PSCV case | `PSCV-CONF-PSCV-DO-RETURN-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.do.verified]` | `PSCV-CONF-PSCV-DO-VERIFIED-P1` | conforming PSCV case | `PSCV-CONF-PSCV-DO-VERIFIED-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.effect.error]` | `PSCV-CONF-PSCV-EFFECT-ERROR-P1` | conforming PSCV case | `PSCV-CONF-PSCV-EFFECT-ERROR-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.effect.error-post]` | `PSCV-CONF-PSCV-EFFECT-ERROR-POST-P1` | conforming PSCV case | `PSCV-CONF-PSCV-EFFECT-ERROR-POST-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.effect.frame]` | `PSCV-CONF-PSCV-EFFECT-FRAME-P1` | conforming PSCV case | `PSCV-CONF-PSCV-EFFECT-FRAME-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.effect.standard]` | `PSCV-CONF-PSCV-EFFECT-STANDARD-P1` | conforming PSCV case | `PSCV-CONF-PSCV-EFFECT-STANDARD-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.effect.state]` | `PSCV-CONF-PSCV-EFFECT-STATE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-EFFECT-STATE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.effect.world]` | `PSCV-CONF-PSCV-EFFECT-WORLD-P1` | conforming PSCV case | `PSCV-CONF-PSCV-EFFECT-WORLD-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.effect.wp]` | `PSCV-CONF-PSCV-EFFECT-WP-P1` | conforming PSCV case | `PSCV-CONF-PSCV-EFFECT-WP-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.effect.wp-laws]` | `PSCV-CONF-PSCV-EFFECT-WP-LAWS-P1` | conforming PSCV case | `PSCV-CONF-PSCV-EFFECT-WP-LAWS-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.ghost]` | `PSCV-CONF-PSCV-GHOST-P1` | conforming PSCV case | `PSCV-CONF-PSCV-GHOST-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.ghost.noninterference]` | `PSCV-CONF-PSCV-GHOST-NONINTERFERENCE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-GHOST-NONINTERFERENCE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.grammar]` | `PSCV-CONF-PSCV-GRAMMAR-P1` | conforming PSCV case | `PSCV-CONF-PSCV-GRAMMAR-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.grammar.contract-order]` | `PSCV-CONF-PSCV-GRAMMAR-CONTRACT-ORDER-P1` | conforming PSCV case | `PSCV-CONF-PSCV-GRAMMAR-CONTRACT-ORDER-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.grammar.integration]` | `PSCV-CONF-PSCV-GRAMMAR-INTEGRATION-P1` | conforming PSCV case | `PSCV-CONF-PSCV-GRAMMAR-INTEGRATION-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.grammar.loop-clauses]` | `PSCV-CONF-PSCV-GRAMMAR-LOOP-CLAUSES-P1` | conforming PSCV case | `PSCV-CONF-PSCV-GRAMMAR-LOOP-CLAUSES-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.grammar.refine-type]` | `PSCV-CONF-PSCV-GRAMMAR-REFINE-TYPE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-GRAMMAR-REFINE-TYPE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.loop.decreasing]` | `PSCV-CONF-PSCV-LOOP-DECREASING-P1` | conforming PSCV case | `PSCV-CONF-PSCV-LOOP-DECREASING-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.loop.for]` | `PSCV-CONF-PSCV-LOOP-FOR-P1` | conforming PSCV case | `PSCV-CONF-PSCV-LOOP-FOR-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.loop.invariant]` | `PSCV-CONF-PSCV-LOOP-INVARIANT-P1` | conforming PSCV case | `PSCV-CONF-PSCV-LOOP-INVARIANT-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.loop.while]` | `PSCV-CONF-PSCV-LOOP-WHILE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-LOOP-WHILE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.model]` | `PSCV-CONF-PSCV-MODEL-P1` | conforming PSCV case | `PSCV-CONF-PSCV-MODEL-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.modular]` | `PSCV-CONF-PSCV-MODULAR-P1` | conforming PSCV case | `PSCV-CONF-PSCV-MODULAR-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.module.certified-import]` | `PSCV-CONF-PSCV-MODULE-CERTIFIED-IMPORT-P1` | conforming PSCV case | `PSCV-CONF-PSCV-MODULE-CERTIFIED-IMPORT-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.module.refinement]` | `PSCV-CONF-PSCV-MODULE-REFINEMENT-P1` | conforming PSCV case | `PSCV-CONF-PSCV-MODULE-REFINEMENT-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.no-proof-no-build]` | `PSCV-CONF-PSCV-NO-PROOF-NO-BUILD-P1` | conforming PSCV case | `PSCV-CONF-PSCV-NO-PROOF-NO-BUILD-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.noncomputable]` | `PSCV-CONF-PSCV-NONCOMPUTABLE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-NONCOMPUTABLE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.opaque.spec]` | `PSCV-CONF-PSCV-OPAQUE-SPEC-P1` | conforming PSCV case | `PSCV-CONF-PSCV-OPAQUE-SPEC-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.partial.reject]` | `PSCV-CONF-PSCV-PARTIAL-REJECT-P1` | conforming PSCV case | `PSCV-CONF-PSCV-PARTIAL-REJECT-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.policy.boundary]` | `PSCV-CONF-PSCV-POLICY-BOUNDARY-P1` | conforming PSCV case | `PSCV-CONF-PSCV-POLICY-BOUNDARY-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.policy.closed]` | `PSCV-CONF-PSCV-POLICY-CLOSED-P1` | conforming PSCV case | `PSCV-CONF-PSCV-POLICY-CLOSED-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.practicality]` | `PSCV-CONF-PSCV-PRACTICALITY-P1` | conforming PSCV case | `PSCV-CONF-PSCV-PRACTICALITY-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.profile.closed-grammar]` | `PSCV-CONF-PSCV-PROFILE-CLOSED-GRAMMAR-P1` | conforming PSCV case | `PSCV-CONF-PSCV-PROFILE-CLOSED-GRAMMAR-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.profile.feature-closure]` | `PSCV-CONF-PSCV-PROFILE-FEATURE-CLOSURE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-PROFILE-FEATURE-CLOSURE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.profile.no-downgrade]` | `PSCV-CONF-PSCV-PROFILE-NO-DOWNGRADE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-PROFILE-NO-DOWNGRADE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.proof.classical]` | `PSCV-CONF-PSCV-PROOF-CLASSICAL-P1` | conforming PSCV case | `PSCV-CONF-PSCV-PROOF-CLASSICAL-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.proof.closure]` | `PSCV-CONF-PSCV-PROOF-CLOSURE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-PROOF-CLOSURE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.proof.native]` | `PSCV-CONF-PSCV-PROOF-NATIVE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-PROOF-NATIVE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.recursion.excluded]` | `PSCV-CONF-PSCV-RECURSION-EXCLUDED-P1` | conforming PSCV case | `PSCV-CONF-PSCV-RECURSION-EXCLUDED-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.recursion.well-founded]` | `PSCV-CONF-PSCV-RECURSION-WELL-FOUNDED-P1` | conforming PSCV case | `PSCV-CONF-PSCV-RECURSION-WELL-FOUNDED-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.registry]` | `PSCV-CONF-PSCV-REGISTRY-P1` | conforming PSCV case | `PSCV-CONF-PSCV-REGISTRY-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.runtime.compiler-assurance]` | `PSCV-CONF-PSCV-RUNTIME-COMPILER-ASSURANCE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-RUNTIME-COMPILER-ASSURANCE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.runtime.effect-closure]` | `PSCV-CONF-PSCV-RUNTIME-EFFECT-CLOSURE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-RUNTIME-EFFECT-CLOSURE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.runtime.ghost-erasure]` | `PSCV-CONF-PSCV-RUNTIME-GHOST-ERASURE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-RUNTIME-GHOST-ERASURE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.runtime.total]` | `PSCV-CONF-PSCV-RUNTIME-TOTAL-P1` | conforming PSCV case | `PSCV-CONF-PSCV-RUNTIME-TOTAL-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.runtime.verified-handoff]` | `PSCV-CONF-PSCV-RUNTIME-VERIFIED-HANDOFF-P1` | conforming PSCV case | `PSCV-CONF-PSCV-RUNTIME-VERIFIED-HANDOFF-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.spec-lemma]` | `PSCV-CONF-PSCV-SPEC-LEMMA-P1` | conforming PSCV case | `PSCV-CONF-PSCV-SPEC-LEMMA-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.spec.anti-weakening]` | `PSCV-CONF-PSCV-SPEC-ANTI-WEAKENING-P1` | conforming PSCV case | `PSCV-CONF-PSCV-SPEC-ANTI-WEAKENING-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.spec.by-type]` | `PSCV-CONF-PSCV-SPEC-BY-TYPE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-SPEC-BY-TYPE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.spec.capsule]` | `PSCV-CONF-PSCV-SPEC-CAPSULE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-SPEC-CAPSULE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.spec.coverage]` | `PSCV-CONF-PSCV-SPEC-COVERAGE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-SPEC-COVERAGE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.spec.hierarchy]` | `PSCV-CONF-PSCV-SPEC-HIERARCHY-P1` | conforming PSCV case | `PSCV-CONF-PSCV-SPEC-HIERARCHY-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.spec.source]` | `PSCV-CONF-PSCV-SPEC-SOURCE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-SPEC-SOURCE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.standard.verification-environment]` | `PSCV-CONF-PSCV-STANDARD-VERIFICATION-ENVIRONMENT-P1` | conforming PSCV case | `PSCV-CONF-PSCV-STANDARD-VERIFICATION-ENVIRONMENT-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.structure.invariant]` | `PSCV-CONF-PSCV-STRUCTURE-INVARIANT-P1` | conforming PSCV case | `PSCV-CONF-PSCV-STRUCTURE-INVARIANT-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.type.refine]` | `PSCV-CONF-PSCV-TYPE-REFINE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-TYPE-REFINE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.unsafe.reject]` | `PSCV-CONF-PSCV-UNSAFE-REJECT-P1` | conforming PSCV case | `PSCV-CONF-PSCV-UNSAFE-REJECT-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.validation.axiom-closure]` | `PSCV-CONF-PSCV-VALIDATION-AXIOM-CLOSURE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-VALIDATION-AXIOM-CLOSURE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.validation.certificate]` | `PSCV-CONF-PSCV-VALIDATION-CERTIFICATE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-VALIDATION-CERTIFICATE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.validation.compile-gate]` | `PSCV-CONF-PSCV-VALIDATION-COMPILE-GATE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-VALIDATION-COMPILE-GATE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.validation.coverage]` | `PSCV-CONF-PSCV-VALIDATION-COVERAGE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-VALIDATION-COVERAGE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.validation.exec-closure]` | `PSCV-CONF-PSCV-VALIDATION-EXEC-CLOSURE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-VALIDATION-EXEC-CLOSURE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.validation.fail-closed]` | `PSCV-CONF-PSCV-VALIDATION-FAIL-CLOSED-P1` | conforming PSCV case | `PSCV-CONF-PSCV-VALIDATION-FAIL-CLOSED-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.validation.proof-closure]` | `PSCV-CONF-PSCV-VALIDATION-PROOF-CLOSURE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-VALIDATION-PROOF-CLOSURE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.validation.report]` | `PSCV-CONF-PSCV-VALIDATION-REPORT-P1` | conforming PSCV case | `PSCV-CONF-PSCV-VALIDATION-REPORT-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.validation.spec]` | `PSCV-CONF-PSCV-VALIDATION-SPEC-P1` | conforming PSCV case | `PSCV-CONF-PSCV-VALIDATION-SPEC-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.validation.staleness]` | `PSCV-CONF-PSCV-VALIDATION-STALENESS-P1` | conforming PSCV case | `PSCV-CONF-PSCV-VALIDATION-STALENESS-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.validation.vc]` | `PSCV-CONF-PSCV-VALIDATION-VC-P1` | conforming PSCV case | `PSCV-CONF-PSCV-VALIDATION-VC-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.validation.verified-executable]` | `PSCV-CONF-PSCV-VALIDATION-VERIFIED-EXECUTABLE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-VALIDATION-VERIFIED-EXECUTABLE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.verification.automation]` | `PSCV-CONF-PSCV-VERIFICATION-AUTOMATION-P1` | conforming PSCV case | `PSCV-CONF-PSCV-VERIFICATION-AUTOMATION-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.verification.failure]` | `PSCV-CONF-PSCV-VERIFICATION-FAILURE-P1` | conforming PSCV case | `PSCV-CONF-PSCV-VERIFICATION-FAILURE-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |
| `[pscv.verify-declaration]` | `PSCV-CONF-PSCV-VERIFY-DECLARATION-P1` | conforming PSCV case | `PSCV-CONF-PSCV-VERIFY-DECLARATION-N1` | nearest adversarial/violating case | rule-specific accept/prove/reject/block behavior | design-RC: execution pending |

## Appendix K — `STD-ENV-PSCV-V1-L435RC3-RC1` source-manifest blueprint

This appendix defines the Lean 4.35.0-rc3 provenance blueprint for the PSCV Standard semantic/prover environment. The final generated registry snapshot and SHA-256 digest are intentionally **not fabricated** in this PSCV-RC-v2 design and remain a release gate.

All roots are from Lean repository commit `470d5ce1400764999581fd26d5d72b00d990b0f4`.

### K.1 Semantic declaration provenance roots

[standard.declaration-provenance]

These roots provide immutable Lean declaration/source provenance. **They do not activate Standard semantic registries.**

| Pinned source root | Blob SHA |
|---|---|
| `src/Init/Prelude.lean` | `f87ee970af5149d74434f09a89aedff1a8fdb2d2` |
| `src/Init/Core.lean` | `23e784c3806badcabd1e8f19c50946d66bc3c87a` |
| `src/Init/Notation.lean` | `9881a62e0ab999ad45cca44cbf54fc63e3b732bc` |
| `src/Init/Coe.lean` | `3284774273cdffc16d027339cc782606235bf993` |
| `src/Init/Classical.lean` | `d14cdb485afe5b127b844c5a9501d05528beb373` |
| `src/Init/Data/Nat.lean` | `fb40850f5969cb4ab551be3fe9a38f48c8849a01` |
| `src/Init/Data/Int.lean` | `12819af6d282c2e1b296070ddd2cdd229084e60b` |
| `src/Init/Data/UInt.lean` | `f60df7fea0978b86b31fddb2d670f2e8a3dd3791` |
| `src/Init/Data/SInt.lean` | `e978b75aa3fb53f55e49cedccf9f33e10b7273ea` |
| `src/Init/Data/OfScientific.lean` | `b34f3e6b476ffc0ddb95661670469acdf5477bd7` |
| `src/Init/Data/Bool.lean` | `6345122bdf0b5b466121210144b5c291959cf851` |
| `src/Init/Data/Char.lean` | `80d098519c3419eee8118b91822d336dd56f5be0` |
| `src/Init/Data/String.lean` | `70263d92300231a5d2bed1971bd2e171bd2a498a` |
| `src/Init/Data/ByteArray.lean` | `eeab7dd85f5101fe7788624303dab3303617c512` |
| `src/Init/Data/Float.lean` | `2265cc1e4fa296a8b24281cf3a73e1c151304637` |
| `src/Init/Data/Fin.lean` | `c3bd39d2150183f55acbcdd8f833de418797a0f0` |
| `src/Init/Data/Option.lean` | `3ab5b8a2fceaf42eda4bc31b58666396cd854d72` |
| `src/Init/Data/Prod.lean` | `0ac2c7800544105686ed2410e7dd5857cd9bb359` |
| `src/Init/Data/Sum.lean` | `6d89f77fba5552d8e84521e94351b0494126683e` |
| `src/Init/Data/Subtype.lean` | `3de593e3f15b6188fccd56bf68a1e05ca7b5ca23` |
| `src/Init/Data/Array.lean` | `d496733cf3b92da75e653c65a06ab0621691e805` |
| `src/Init/Data/List.lean` | `c2d0f3f1b43a1259db7980e95229b9f61c924cbb` |
| `src/Init/Control/Except.lean` | `b40719f993670975dc3253c2e0f6f7f30db55073` |

Their transitive import closure determines which pinned declarations may be referenced as provenance. Initial instance/default-instance/coercion/simp/simproc/ext/grind activation is exclusively the explicit manifest snapshot. Parser/macro registrations are inactive unless Appendix A/Appendix I admits them.

### K.2 Prover roots

| Pinned source root | Blob SHA |
|---|---|
| `src/Lean/Elab/Tactic/BuiltinTactic.lean` | `d9c4ce60d1060de505789cfdb0c71a1d98dcee8a` |
| `src/Lean/Elab/Tactic/Rfl.lean` | `26650837ddae11ebd8a69d2d52a60c6ee102e565` |
| `src/Lean/Elab/Tactic/LibrarySearch.lean` | `17e947a432cdd86e306fe41e656e9e0ee31e4bce` |
| `src/Lean/Elab/Tactic/Induction.lean` | `4b8b54bd3a3d2669a79a33b16a1f7a0fcbaca450` |
| `src/Lean/Elab/Tactic/Rewrite.lean` | `75a3bbe03160f55708edbc2ba142d44f4b8ba7fb` |
| `src/Lean/Elab/Tactic/Simp.lean` | `e551319199e05bc3674c97a9408f51ff73b494b2` |
| `src/Lean/Elab/Tactic/Simpa.lean` | `78a534372c1bd8f473ef5aeb5dd08dced228e444` |
| `src/Lean/Elab/Tactic/Unfold.lean` | `fc4be802ed175298ae3096c467352b389b33918a` |
| `src/Lean/Elab/Tactic/Change.lean` | `07722437f8c3fa7124969a031c5b00dda2d14c9c` |
| `src/Lean/Elab/Tactic/FalseOrByContra.lean` | `a3b45ce11a81326802cf813746c153da4ff62a93` |
| `src/Lean/Elab/Tactic/Generalize.lean` | `f67e3b0cb6f5d4c1970d17380c16df3c01f5a424` |
| `src/Lean/Elab/Tactic/RCases.lean` | `e1fda580b9107b66e104e2eb0f3316eb249d48c1` |
| `src/Lean/Elab/Tactic/Ext.lean` | `526ed04905f730e568144cbf0043f439a6d86651` |
| `src/Lean/Elab/Tactic/Decide.lean` | `2e1e51ccdd2b9a913df9e81100389995cbcb8764` |
| `src/Lean/Elab/Tactic/Omega.lean` | `708d3657f2995a06b489e781f8739c80c7b7b8b1` |
| `src/Lean/Elab/Tactic/Grind.lean` | `c169bf04f3fef133d197b2b6c01852c148d498d5` |
| `src/Lean/Elab/Tactic/Classical.lean` | `6abca3eecc9fa2734b7c31322ca5d9332b6eaa2c` |

### K.3 Registry-filter rule

[standard.manifest-filter]

Pinned roots provide semantic declarations and immutable source provenance. They do **not** implicitly activate registry entries.

The normative manifest's `registry_snapshot` arrays are the complete initial Standard registries:

- `instances`;
- `default_instances`;
- `coercions`;
- `simp`;
- `simprocs`;
- `ext`;
- `grind`.

Every snapshot entry has a stable manifest ID and immutable pinned source locator (`path`, `blob_sha`, `line`, and declaration name where stable). An entry absent from the array is inactive even if the pinned Lean root/import closure would register it in ordinary Lean.

Visible imported/current ProofScript declarations may extend only the registries that Chapters 22 and 24 explicitly permit. Standard source cannot extend simproc/ext/grind handler registries.


[standard.registry-provenance]

Every entry in the final frozen `registry_snapshot` MUST identify an immutable Lean source blob and a source line that denotes either:

- the registered instance/declaration itself; or
- the attribute/registration command that activates the named declaration.

For generated or `deriving instance` declarations, the source line naming the generation request is the provenance locator.

A release MUST validate that every `blob_sha` exists at the pinned Lean repository/commit and that every cited source line exists in that blob. Provenance validation is evidence about the manifest; it does not activate registrations not listed by the snapshot.

[standard.registry-provenance-evidence]

A release claiming this Standard environment MUST publish provenance evidence verifying every manifest `path`/`blob_sha`/`line` locator and every non-default class-parameter-mode locator against the pinned Lean repository.

This evidence is non-semantic: it verifies that the manifest points where it claims, while the manifest itself remains the normative registry authority.


[standard.class-mode-provenance]

Every non-default entry in manifest `class_parameter_modes` MUST cite the pinned foundational class declaration whose binder wrappers establish the `input`, `out`, or `semiOut` modes. These locators are validated as release evidence in the same manner as registry snapshot locators.

### K.4 Release-candidate registry-generation gate

[standard.registry-manifest]

A final implementation claiming `STD-ENV-PSCV-V1-L435RC3-RC1` MUST ship `STD-ENV-PSCV-V1-L435RC3-RC1.json`.

The generated file MUST contain:

- `lean_version = "4.35.0-rc3"`;
- `lean_commit = "470d5ce1400764999581fd26d5d72b00d990b0f4"`;
- `required_standard_surface`, the complete guaranteed basis-type overloaded surface from Chapter 24.3;
- `registry_snapshot`, the complete ordered initial instance/default-instance/coercion/simp/simproc/ext/grind registries;
- `class_parameter_modes`;
- the fixed PSCV verification-registry entries required by Chapter 21 and Section 24.1B;
- immutable path/blob/symbol provenance for every activated entry.

Canonicalization is UTF-8 JSON with object keys sorted lexicographically, no insignificant whitespace, and no trailing newline.

**Design-RC state:** the manifest SHA-256 is pending generation. The previous Lean-4.34-derived digest is invalid for this profile and MUST NOT be reused.

[standard.registry-digest]

A toolchain MUST NOT claim `STD-ENV-PSCV-V1-L435RC3-RC1` or final `pscv-compiler-v1` conformance until:

1. the RC3 manifest is generated from the pinned commit;
2. every required surface entry resolves;
3. every path/blob/symbol provenance locator validates;
4. registry order is mechanically frozen;
5. the canonical manifest SHA-256 is published into a subsequent normative revision; and
6. positive and adversarial conformance tests run against that exact digest.

Changing any guaranteed surface row, registry entry/order, notation, fixed semantic option, tactic list, basis type, verification lowering, root identity, or registry policy requires a new manifest digest and, when source meaning changes, a new environment/profile revision.

## Appendix L — Lean 4 feature suitability for PSCV

**Status:** informative research matrix that motivates the normative PSCV choices above. Normative semantics use the pinned Lean 4.35.0-rc3 mappings plus PSCV-owned rules.

The current Lean reference consulted for this PSCV study describes Lean 4.35.0-rc3. PSCV intentionally does not silently inherit that moving release candidate. Features added after the 4.34 semantic pin are marked as research precedent when relevant.

Legend:

| Status | Meaning |
|---|---|
| **CORE** | retained as foundational PSCV semantics |
| **PSCV** | required PSCV programming/verification surface |
| **RESTRICTED** | usable only under explicit PSCV restrictions |
| **PROOF-ONLY** | may participate in mathematical/specification reasoning but not runtime closure |
| **BOUNDARY** | external/world behavior; requires explicit model/assumption/evidence |
| **TOOLING** | useful development tool, not source proof authority |
| **EXCLUDED** | deliberately outside PSCV v1 verified source |
| **FUTURE** | promising but needs a separately versioned semantic profile |

### L.1 Core dependent type theory

| Lean capability | PSCV status | Rationale |
|---|---|---|
| `Prop`, `Type`, `Sort` | CORE | one language for programs/specifications/proofs |
| universe polymorphism | CORE | scalable generic libraries |
| dependent Pi/function types | CORE | expressive APIs/refinement |
| lambda/application/let | CORE | basic computation |
| propositional equality | CORE | fundamental reasoning |
| definitional equality | CORE | conversion/computation |
| proof irrelevance | CORE | proof erasure/semantic simplicity |
| quotient foundation | RESTRICTED | retain pinned foundation; not new source complexity |
| standard foundational axioms | RESTRICTED | explicit axiom closure/reporting |
| user axioms | EXCLUDED | defeat closed proof claims |
| classical reasoning | PROOF-ONLY / RESTRICTED | useful mathematically; runtime data becomes noncomputable where applicable |

### L.2 Data and abstraction

| Lean capability | PSCV status | Rationale |
|---|---|---|
| inductive types | CORE | algebraic data and induction |
| indexed/dependent inductives | CORE | make invariants/state indices explicit |
| mutual inductives | CORE | practical recursive models |
| structures | CORE | records/abstractions |
| proof fields | PSCV | lawful/valid structures |
| structure inheritance/class parents | RESTRICTED | allowed through deterministic closed profile |
| `Subtype` | CORE / encouraged | refinement values, proof erases |
| `Fin n` | CORE / encouraged | bounds by construction |
| `Sigma`/dependent pairs | RESTRICTED/library | useful dependent data; include only through an explicitly pinned PSCV library/profile |
| `Prod`, `Sum`, `Option`, `Except`, `List`, `Array` | CORE/library | practical basis |
| exact `Nat`/`Int` | CORE | mathematical arithmetic |
| fixed-width integers | PSCV | systems/application interoperability with exact pinned semantics |
| `Float`/`Float32` | RESTRICTED | proofs reason about IEEE/pinned float semantics, not reals |
| `String`, `Char`, `ByteArray` | PSCV | practical software data |
| dependent structure update | PSCV | accepted only when invariants/types re-establish |

### L.3 Definitions and recursion

| Lean capability | PSCV status | Rationale |
|---|---|---|
| `def` | PSCV | executable mathematical definition subject to certification |
| `function`/ProofScript alias | PSCV | ergonomic ordinary function |
| `const` | PSCV | value definition |
| `abbrev` | CORE | transparent abstraction |
| `opaque` | RESTRICTED | good modular boundary; public executable behavior needs approved spec |
| `theorem` | CORE | named proof |
| `example` | TOOLING | scratch/checking |
| structural recursion | PSCV | total by construction/elaboration |
| well-founded recursion | PSCV | needed for practical algorithms |
| `termination_by` | PSCV | explicit measure |
| `decreasing_by` | PSCV | explicit proof of descent |
| inferred termination | RESTRICTED | only if materializable/replayable as checked evidence |
| `partial` | EXCLUDED | no total logical executable meaning |
| `unsafe` | EXCLUDED | can break reasoning/runtime invariants |
| `noncomputable` | PROOF-ONLY | useful specs/math; excluded from runtime closure |
| `partial_fixpoint` | FUTURE | partial correctness may be useful but needs separate PSCV semantics |
| `coinductive_fixpoint` | FUTURE | liveness/coinduction needs explicit profile |
| `inductive_fixpoint` | FUTURE | logical facility, not PSCV v1 executable core |

### L.4 Pattern matching and functional ergonomics

| Lean capability | PSCV status | Rationale |
|---|---|---|
| exhaustive pattern match | PSCV | total case analysis |
| nested constructor patterns | PSCV | practical ADT code |
| multi-scrutinee match | FUTURE/ergonomic extension | useful, lowers to ordinary eliminators |
| equation-style definitions | FUTURE/ergonomic extension | highly pleasant for mathematics-like code |
| dependent match motives | RESTRICTED | only exact elaboration; never approximate |
| `if` over decidable propositions | PSCV | branches carry mathematical facts |
| generalized field notation | PSCV | practical API style, static only |
| named arguments | PSCV | readable APIs |
| default arguments | PSCV | elaboration sugar |
| user pattern macros | EXCLUDED | closed grammar |

### L.5 Typeclasses, coercions, automation registries

| Lean capability | PSCV status | Rationale |
|---|---|---|
| typeclasses | PSCV / controlled | lawful interfaces/generic programming |
| instance synthesis | PSCV / deterministic | useful but environment-sensitive |
| local/scoped instances | RESTRICTED | exact profile/environment identity |
| output/semi-output parameters | RESTRICTED | pinned foundational behavior |
| ordinary coercions | PSCV / bounded | ergonomics without dynamic casts |
| dependent coercions | RESTRICTED | powerful; require deterministic closed semantics |
| coercion chains | RESTRICTED | PSCV Standard keeps smaller bounded algorithm |
| arbitrary user notation | EXCLUDED Standard | hurts reproducibility/audit |
| fixed Standard notation | PSCV | readable source |
| `@[simp]` theorem registration | PSCV / controlled | scalable proof automation |
| arbitrary simprocs | plugin/tooling | proof-producing but environment-controlled |
| deriving framework | FUTURE official extension | useful ergonomics; must be closed/versioned |

### L.6 `do` and practical programming

| Lean capability | PSCV status | Rationale |
|---|---|---|
| monadic sequencing | PSCV | effectful programming |
| monadic bind | PSCV | explicit data-dependent effects |
| local `let` | PSCV | ordinary code |
| `let mut` | PSCV | practical local imperative style |
| local assignment | PSCV | practical algorithms with state semantics |
| `for` | PSCV | common iteration with invariant/spec obligations |
| `while` | PSCV | common iteration; invariant + termination required |
| early `return` | PSCV | practical control flow, postcondition checked |
| `break` / `continue` | PSCV | practical loops, included in VC semantics |
| exception handling syntax | RESTRICTED/FUTURE | use typed error semantics; broaden only with exact VC rules |
| arbitrary aliased heap mutation | EXCLUDED v1 | substantially harder frame/alias reasoning |
| local `ST`/references | RESTRICTED/FUTURE | allow through verified encapsulation/effect model |
| iterators/`ForIn` | PSCV via verified specs | reusable iteration semantics |

### L.7 Verification facilities

| Lean capability | PSCV status | Rationale |
|---|---|---|
| weakest-precondition semantics | PSCV | compositional verification basis |
| `WP`/`WPMonad` concept | PSCV | verified effects |
| Hoare triples | PSCV | effectful contracts |
| `mvcgen`/`vcgen` approach | PSCV architecture | VC generator untrusted, proof output checked |
| `requires` | PSCV | caller assumptions/obligations |
| `ensures` | PSCV | result/effect guarantee |
| proof-only `assert` | PSCV | local mathematical checkpoint |
| loop `invariant` | PSCV | inductive loop reasoning |
| `decreasing` loop measure | PSCV | totality |
| Lean 4.35.0-rc3 `given` | PSCV / pinned reference lowering | logical contract variables; normative meaning frozen by `PSCV-VERIFY-v1` |
| Lean 4.35.0-rc3 erased verification state | PSCV / pinned reference lowering | proof-only state; PSCV freezes noninterference and erasure requirements |
| spec lemmas | PSCV | modular reasoning |
| runtime contract checks | TOOLING | testing/diagnostics, not proof |
| frame/`modifies` syntax | FUTURE | may be needed with heap/capability models, not necessary for v1 local-state core |

### L.8 Proof language and tactics

| Lean capability | PSCV status | Rationale |
|---|---|---|
| explicit proof terms | CORE | smallest authority path |
| tactic `by` blocks | PSCV | practical proof authoring |
| `rfl`, `exact`, `apply`, `refine`, intro/cases/induction | PSCV | core proof work |
| `rw`, `simp`, `simpa`, `dsimp` | PSCV | routine reasoning |
| `calc` | PSCV | mathematics-like explanations |
| `omega` | PSCV | arithmetic automation |
| `grind` | PSCV | broad proof-producing automation |
| `decide` | RESTRICTED/PSCV | acceptable when final evidence is within policy |
| native/compiler evaluation proof axioms | EXCLUDED closed | expands trust beyond kernel/checker |
| external SMT | plugin | useful only with accepted proof reconstruction/certificate policy |
| AI prover | TOOLING/plugin | candidate proof generator, never authority |
| arbitrary custom tactic syntax | EXCLUDED Standard | closed grammar; plugins may expose structured APIs instead |
| proof holes/`sorry` | EXCLUDED | no verified meaning |

### L.9 Source extensibility and metaprogramming

| Lean capability | PSCV status | Rationale |
|---|---|---|
| custom syntax categories | EXCLUDED Standard | interpretation stability |
| notation declarations | EXCLUDED Standard | fixed readable grammar |
| macros/macro_rules | EXCLUDED Standard | dependency-driven syntax changes |
| term elaborators | EXCLUDED Standard | can change meaning before kernel checking |
| command elaborators | EXCLUDED Standard | can mutate global environment |
| tactic elaborators | EXCLUDED Standard | fixed source proof surface |
| quotations/Meta authoring | TOOLING / extension profile | excellent compiler/prover implementation tool, not PSCV Standard source |
| custom attributes | EXCLUDED Standard | closed registries |
| official versioned sugar | PSCV | acceptable when exact lowering/identity is specified |

### L.10 Effects, world, runtime and compiler

| Lean capability | PSCV status | Rationale |
|---|---|---|
| pure/Id | PSCV closed | direct mathematical computation |
| State/StateT | PSCV verified effect | WP semantics |
| Reader/ReaderT | PSCV verified effect | read-only logical environment |
| Except/ExceptT | PSCV verified effect | typed error semantics |
| OptionT | optional verified effect | explicit failure |
| IO | BOUNDARY | Lean docs explicitly note IO programs are generally hard to verify |
| filesystem/network/process/env | BOUNDARY | external world |
| clock/randomness | BOUNDARY/model | require explicit abstract model |
| mutable IO refs | BOUNDARY | alias/concurrency issues |
| threads/tasks | FUTURE/BOUNDARY | concurrency semantics needed |
| FFI `extern`/`export` | BOUNDARY | runtime implementation is foreign |
| compiler intrinsics | RESTRICTED/boundary | must not redefine source logic |
| `implemented_by`-style runtime replacement | EXCLUDED from closed semantic authority | logical body/runtime implementation gap must be explicit |
| `#eval` / interpreter | TOOLING | execution feedback, not proof |
| native code generation | backend | separate preservation assurance |
| proof erasure | PSCV | checked computational irrelevance |
| compiler optimization | backend | separate translation-validation/proof layer |

### L.11 Tooling and build ecosystem

| Lean capability | PSCV status | Rationale |
|---|---|---|
| InfoTrees/proof states | TOOLING / strongly encouraged | excellent human/AI feedback |
| LSP completions/diagnostics | TOOLING | usability |
| `#check`, `#print`, `#reduce` | TOOLING | inspection |
| `#print axioms` concept | PSCV audit requirement | transitive trust visibility |
| `lean4checker`/independent replay concept | PSCV high-assurance precedent | separation of generation/checking |
| Lake/package management | TOOLING/platform | not language truth |
| build cache | TOOLING | must not bypass evidence identity |
| code actions (e.g. termination hints) | TOOLING | excellent ergonomic support |
| formatter | TOOLING | no semantic authority |

### L.12 Research conclusion

The Lean feature inventory supports a strong PSCV design without a new kernel.

The facilities most valuable to PSCV are not exotic theorem-prover commands; they are the combination of:

~~~text
dependent/refinement data
+ total functions
+ lawful abstractions
+ practical `do` notation
+ verified effects / weakest preconditions
+ contracts / invariants / termination
+ proof-producing automation
+ proof erasure
+ a small independent checking boundary
~~~

The facilities most important to **exclude or isolate** are:

~~~text
partial
unsafe
user axioms
proof holes
unrestricted IO/FFI
unrestricted source extensibility
native/compiler proof trust
unmodeled aliasing/concurrency
~~~

This is why PSCV is best understood as a **verified profile of Lean-grounded ProofScript**, not as another theorem prover.

## Appendix M — PSCV research basis and design rationale

This PSCV revision was informed by the following external systems and current documentation.

### M.1 Lean 4

Normative PSCV semantics remain pinned to Lean 4.35.0-rc3 where inherited by Appendix I.

Current research additionally reviewed the Lean 4.35.0-rc3 reference/release notes because they demonstrate ongoing convergence toward intrinsic program verification:

- contracts with `requires` and `ensures`;
- loop/assert verification syntax;
- `given` logical contract variables;
- erased verification-only `do` state;
- weakest-precondition/Hoare infrastructure;
- `vcgen` improvements.

These 4.35 facilities remain explicitly experimental upstream and are therefore **design evidence**, not moving normative PSCV semantics.

Primary sources:

- https://lean-lang.org/doc/reference/latest/
- https://lean-lang.org/doc/reference/latest/releases/v4.35.0/
- https://lean-lang.org/doc/reference/latest/The--mvcgen--tactic/Predicate-Transformers/
- https://lean-lang.org/doc/tutorials/latest/mvcgen/
- https://lean-lang.org/doc/reference/latest/Definitions/Recursive-Definitions/
- https://lean-lang.org/doc/reference/latest/ValidatingProofs/
- https://lean-lang.org/doc/reference/latest/Functors___-Monads-and--do--Notation/Syntax/
- https://lean-lang.org/doc/reference/latest/Functors___-Monads-and--do--Notation/Varieties-of-Monads/
- https://lean-lang.org/doc/reference/latest/Notations-and-Macros/
- https://lean-lang.org/doc/reference/latest/Run-Time-Code/Foreign-Function-Interface/

### M.2 Dafny

Dafny provides strong precedent for routine software contracts, call-site precondition verification, loop invariants, decreases clauses, assertion VCs, and refusal to compile unchecked assumptions in ordinary verified workflows.

PSCV borrows the user expectation that verification obligations are normal programming feedback, while retaining explicit proof-term/kernel authority.

Sources:

- https://dafny.org/latest/VerificationOptimization/VerificationOptimization
- https://dafny.org/dafny/DafnyRef/DafnyRef
- https://dafny.org/dafny/HowToFAQ/Errors

### M.3 SPARK

SPARK is direct precedent for defining a practical subset of a general-purpose language by excluding constructs that defeat verification and extending contracts to support modular refinement.

It is also precedent for specification-before-body constructive development and for mixing proof with explicitly different evidence methods.

Sources:

- https://docs.adacore.com/spark2014-docs/html/lrm/introduction.html
- https://docs.adacore.com/spark2014-docs/html/ug/en/source/subprogram_contracts.html
- https://docs.adacore.com/spark2014-docs/html/ug/en/source/package_contracts.html

### M.4 Verus

Verus provides strong precedent for classifying specification/proof/executable relevance and erasing ghost code while verifying executable Rust behavior.

PSCV adopts the conceptual relevance separation without importing Rust ownership semantics.

Source:

- https://verus-lang.github.io/verus/guide/modes.html

### M.5 F*

F* provides long-standing evidence for dependent verification with total computations and effect-specific weakest-precondition reasoning.

PSCV uses the same architectural lesson while retaining Lean/ProofScript's own logic and effect libraries.

Sources:

- https://fstar-lang.org/tutorial/
- https://fstar-lang.org/tutorial/proof-oriented-programming-in-fstar.pdf

### M.6 Design choice summary

The selected PSCV v1 balance is:

~~~text
small logical authority
+ rich but closed source ergonomics
+ types for data invariants
+ contracts for computations
+ laws for abstractions
+ WP models for admitted effects
+ totality
+ automated proof construction
+ explicit external boundaries
+ proof/spec erasure
+ verified compilation gate
+ independent assurance reporting
~~~

This profile is intentionally stricter than ordinary Lean programming while aiming to be more pleasant for verified application development than a theorem-first workflow.


### M.7 Incremental implementation and bootstrap path

PSCV does not require the existing compiler to be formally verified before the profile can be implemented.

The recommended progression is:

~~~text
M0  existing PSC + PSKernel
    parse/elaborate/check base source

M1  pure PSCV
    required public specs
    pure requires/ensures
    proof-closure compile gate
    axiom/partial/unsafe rejection

M2  modular PSCV
    caller precondition VCs
    imported checked specification evidence
    SpecCapsule identity
    assurance report

M3  total algorithms
    well-founded recursion
    termination_by / decreasing proofs
    refined types / structure invariants

M4  practical verified do
    let mut / assignment
    for / while
    assert / invariant / decreasing
    ghost erasure

M5  verified effects
    State / Reader / Except WP models
    frames and typed error postconditions

M6  boundary applications
    explicit capability/FFI assumptions
    runtime conformance evidence

M7  compiler assurance
    certify selected PSC passes in PSCV
    translation validation
    progressively verified self-hosting
~~~

At the early stages PSC remains an untrusted producer of candidate terms/obligations; proof validity can still be checked independently by PSKernel and reference Lean lanes. Later stages can place parser/elaboration/erasure/VerifiedIR passes themselves under PSCV specifications without redesigning the language.

This avoids a circular “the compiler must already be proved before it can enforce proof” requirement.
