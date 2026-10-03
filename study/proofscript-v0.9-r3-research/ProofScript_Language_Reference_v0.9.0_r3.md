# The ProofScript Language Reference v0.9.0 r3

**Status:** accepted language/design specification; not an implementation release or proof of compiler correctness.

**Grammar identity:** `ps-0.9-r3`

**Semantic pin:** Lean 4.34.0, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`

This document is the **standalone normative human and AI/compiler-design reference** for ProofScript v0.9.0 r3. It does not require any previous ProofScript release, migration document, revision note, audit, or companion design document to determine the language/compiler contract.

The pinned Lean 4.34.0 implementation remains the semantic oracle for inherited Lean theory and native constructs. ProofScript-specific syntax, ownership, profiles, contracts, application semantics, interop boundaries, compiler phases, assurance rules, and conformance requirements are defined here.

## How to read this specification

Every numbered section carries one of these classifications:

- **[NORMATIVE LANGUAGE]** — observable source-language, type-system, runtime-semantic, formatting, or profile behavior required for conformance.
- **[NORMATIVE ASSURANCE]** — checker/compiler/evidence/security invariants required before making the associated correctness or release claim.
- **[IMPLEMENTATION GUIDANCE]** — recommended compiler/runtime architecture. An implementation may differ internally if it preserves all normative behavior and evidence boundaries.
- **[INFORMATIVE]** — examples, motivation, explanatory comparisons, non-goals, or evidence-status notes. Informative text does not introduce syntax.

Subsections inherit the classification of their containing numbered section unless explicitly marked otherwise.

Normative keywords:

- **MUST / MUST NOT** — conformance requirement.
- **SHOULD / SHOULD NOT** — strong recommendation; divergence requires a documented reason and MUST NOT alter normative behavior.
- **MAY** — explicitly permitted behavior.
- **reject** — the implementation MUST produce a non-success result appropriate to the owning phase; it MUST NOT silently reinterpret, weaken, or fall back.
- **unsupported** — recognized as outside the selected implementation/profile; unsupported input is not malformed but MUST NOT be accepted as if supported.

## Table of contents

1. Normative model
2. Profiles and environment identity
3. Lexical and parser ownership model
4. Exact surface grammar
5. Type system and core semantics
6. Primitive and data semantics
7. Modules, source identity, and packages
8. Stable PSC-owned contracts
9. Standard application semantics
10. npm / TypeScript interoperability
11. Compiler architecture
12. Elaboration and genuine admission
13. Erasure and executable semantics
14. Backends and preservation
15. Semantic bundles and InterfaceIR transport
16. Formatting and tooling
17. Versioning and compatibility
18. Evidence and release discipline
19. AI compiler implementation contract
20. Compiler data model guidance
21. Normative feature summary
22. Canonical examples
23. Non-goals and explicit exclusions
24. Evidence status of this reference
25. Parser algorithm and grammar summary
26. Generated machine-readable mirror policy
27. Final implementation directive

## Glossary

**Admission** — genuine checking of a candidate declaration by the selected logical checker/kernel so it can enter an accepted module.

**App** — cold Standard application computation description parameterized by capability set, typed error, and result.

**Artifact identity** — immutable identifier, normally content-addressed, for the exact bytes or structured object to which evidence applies.

**CallGap** — the narrowly defined horizontal trivia that may occur between a completed callable head and an r3 parenthesized-call opening parenthesis.

**Candidate declaration** — elaborated declaration not yet genuinely admitted.

**CapabilitySet** — canonical finite set of application capability identities. Set equality is semantic equality; canonical encoding is deterministic.

**CheckedCore** — canonical admitted Core declarations/terms before executable erasure. A `CheckedModule` contains CheckedCore plus module/environment metadata.

**CheckedModule** — module state constructible only through genuine admission or an explicitly sound recheck/import protocol.

**CompilerGenN** — bootstrap/self-host compiler generation label. Generation names do not identify a language edition or capability profile.

**Core** — elaborated kernel-facing dependent term/declaration language.

**RuntimeIR** — target-neutral executable IR after proof/type erasure and source-semantic lowering. Older planning terminology such as "RuntimeIR" maps to RuntimeIR plus explicit evidence status; the IR name itself does not grant verification authority.

**CompilerCapabilityProfile** — versioned statement of which language/frontend/elaboration/runtime facilities a concrete compiler implementation owns directly.

**FeatureOwner** — architectural layer responsible for implementing a capability: compiler frontend, elaborator, library, prover package, controlled extension, compatibility frontend, host boundary, post-PSC2 platform, or deferred/unsupported.

**LeanCompatibilityProfile** — bounded, versioned set of native Lean source constructs accepted by the ProofScript `.lean` frontend.

**Environment identity** — identity of all semantic inputs that can affect parsing, elaboration, checking, or execution claims, including imports, options, registrations, policies, and profile.

**E-class** — explicit ProofScript surface exception: syntax intentionally differs from a valid or plausible native Lean neighbor but lowers to the selected Lean-compatible meaning.

**D-class** — conservative surface decoration whose ownership/lowering does not intentionally reinterpret a valid protected native neighbor.

**Fiber** — started child execution created from a cold `App`.

**InterfaceIR** — versioned foreign-interface IR binding exact TypeScript/npm resolution to raw/safe/specification boundary information.

**Native** — exact construct/meaning inherited from the pinned Lean semantic environment, subject to the selected ProofScript source profile.

**Profile** — versioned source/environment capability set such as `ps-standard` or `ps-lean-extensible`.

**RuntimeFault** — unexpected runtime/host failure outside the ordinary typed application error channel.

**Semantic bundle** — exact transport/evidence envelope for importing checked declarations without importing source syntax/meta side effects.

**Source correspondence** — evidence that the accepted canonical/elaborated declaration corresponds to the original ProofScript source under the specified frontend relation.

**Standard** — the closed/versioned `ps-standard` source environment.

**Stream** — cold asynchronous sequence description; each subscription starts a distinct owned stream execution.


# Part I — Normative model

## 1. Purpose

**[INFORMATIVE]**

ProofScript is a general-purpose programming language and theorem-proving/formal-verification language whose logical meaning is defined through Lean-compatible elaboration and genuine kernel admission.

The r3 edition defines the application-facing syntax, source profiles, specification layer, application model, and foreign-interface model. It does not introduce a competing logical type theory.

The language is designed to make ordinary application programming more approachable to TypeScript/JavaScript developers while preserving exact dependent-type and proof semantics.

ProofScript deliberately does not import the following JavaScript/TypeScript semantics into its native language:

- JavaScript truthiness;
- implicit null or undefined;
- native any;
- prototype inheritance as native object semantics;
- arbitrary host exceptions as typed application errors;
- JavaScript automatic semicolon insertion;
- universal statement blocks;
- Promise as the definition of async semantics;
- declaration files as runtime validation or proof;
- structural unsoundness as the native proof/type model.

## 2. Normative authority and conformance

**[NORMATIVE ASSURANCE]**

This document is the sole ProofScript-specific normative authority for `ps-0.9-r3`.

No earlier ProofScript document contributes normative meaning.

The pinned Lean 4.34.0 environment is the external semantic oracle for the Lean constructs that this specification explicitly includes through a selected source/compiler/compatibility profile.

A construct existing in Lean 4 does **not** imply that the PSC2 compiler implements it.

A ProofScript implementation MAY support a documented subset of the language/profile. Unsupported input MUST fail closed and MUST NOT be approximated by a different semantic model.

Conformance has separate dimensions:

- **source conformance** — accepted/rejected source and ownership follow this specification;
- **logical conformance** — supported source lowers/elaborates to the specified Lean-compatible meaning and receives genuine admission;
- **compiler-capability conformance** — the implementation reports the exact compiler capability profile it supports;
- **Lean-compatibility conformance** — a `.lean` frontend reports the exact bounded compatibility profile it implements;
- **runtime conformance** — primitives, effects, resources, async, FFI, and target behavior satisfy the selected runtime profile;
- **assurance conformance** — claims are no stronger than the proofs, validators, tests, and assumptions actually recorded.

The core architectural rule is:

~~~text
If a capability can be an ordinary library, make it a library.
If it is only syntax ergonomics, lower/desugar it.
If it is proof automation, make it an untrusted proof-producing library.
If compiler participation is necessary, use a controlled versioned extension.
If it is foreign/target-specific, put it behind InterfaceIR/FFI.
Change Core or the kernel only when the capability genuinely cannot be represented above them.
~~~

## 3. Central semantic relationship

**[NORMATIVE ASSURANCE]**

For source p in environment E:

~~~text
parsePS_r3(E, p) = surfaceAST

canonicalize_r3(E, surfaceAST) = canonicalLeanSyntax

meaningPS_r3(E, p)
  = meaningLean434(lowerEnv(E), canonicalLeanSyntax)
~~~

The relation is partial.

Malformed, unsupported, profile-incompatible, elaboration-invalid, proof-invalid, or environment-incompatible source rejects.

Successful parsing alone does not establish meaning.

The environment includes at least:

- source edition;
- source profile;
- exact module/source identities;
- imports;
- syntax/tactic registration identity;
- options;
- instances and semantic registrations;
- axiom policy;
- semantic bundle identities;
- compiler/checker revision;
- target/runtime profile when an executable claim is requested.

## 4. Source kinds

**[NORMATIVE ASSURANCE]**

### 4.1 .ps

A .ps file uses a ProofScript edition/profile.

It can contain:

- inherited Lean forms allowed by the selected profile;
- registered ProofScript decorations;
- registered ProofScript surface exceptions.

### 4.2 .lean

A .lean file is native Lean syntax.

ProofScript productions MUST NOT be injected into `.lean`.

The PSC2 compiler does **not** promise full Lean 4 source compatibility.

The initial required compatibility profile is:

~~~text
lean-subset-psc2-v1
~~~

It is intentionally bounded to constructs whose canonical meaning the ProofScript pipeline owns.

Required `lean-subset-psc2-v1` families:

- `def`, `theorem`, `example`, and supported declaration modifiers;
- explicit, implicit, strict-implicit, and instance binders needed by the supported subset;
- universes/type applications used by supported declarations;
- structures, classes, instances, inductives, constructors, projections, and ordinary record construction/update where supported by PSC2;
- lambdas, lets, applications, literals, conditionals, and match;
- structural recursion and the explicitly supported recursion subset;
- supported propositions/equality/primitive operations;
- the selected Standard prover/tactic forms that the compiler capability profile advertises.

Excluded unless a later compatibility profile explicitly adds them:

- arbitrary user-defined `syntax`, `macro`, `macro_rules`, `elab`, or parser categories;
- unrestricted quotations/metaprogramming;
- arbitrary command/attribute registrations;
- unsupported tactics/automation;
- Lean compiler/runtime intrinsics not represented by the selected ProofScript semantic/runtime profiles;
- arbitrary environment-extension machinery;
- unsupported well-founded/dependent-pattern/compiler extensions.

Every rejection SHOULD identify the unsupported Lean compatibility feature.

The `.lean` frontend and `.ps` frontend MUST converge on one canonical semantic pipeline for their claimed overlap.

### 4.2.1 Lean compatibility reporting levels

Tooling SHOULD report bounded Lean compatibility by level rather than a single Boolean:

| Level | Meaning |
|---|---|
| L0 | lexical/basic native syntax recognized |
| L1 | core declarations/terms/binders |
| L2 | structures/inductives/classes/instances/owned recursion subset |
| L3 | selected standard prover/tactics/notation |
| L4 | Meta/macro/plugin compatibility |
| L5 | theorem-library compatibility |
| L6 | kernel/artifact compatibility |

`psc2-compiler-v1` targets **L2 plus explicitly listed L3 forms** for its `.lean` frontend. It does not imply L4–L6.

### 4.3 .psx and future dialects

No UI/JSX semantics are implied by the extension alone.

A dialect requires an explicit grammar/profile identity and assurance boundary.

---

# Part II — Profiles and environment identity

## 5. ps-standard

**[NORMATIVE ASSURANCE]**

Profile identity:

~~~text
ps-standard-0.9-r3
~~~

ps-standard is for:

- ordinary applications;
- libraries;
- npm packages;
- AI-generated code;
- deterministic formatting;
- predictable LSP/refactoring;
- reproducible parsing/elaboration.

It has a closed versioned source grammar and a fixed syntax/tactic/attribute environment.

Ordinary package source and dependencies cannot silently mutate parser tables.

A release claiming ps-standard-0.9-r3 MUST publish a materialized registration-closure manifest and SHA-256.

Host-installed extra parser/tactic/attribute registrations are not Standard merely because they are locally available.

## 6. ps-lean-extensible

**[NORMATIVE ASSURANCE]**

ps-lean-extensible uses the same logical foundation but permits declared:

- syntax categories;
- notation;
- macros;
- tactics;
- elaborators;
- Meta programming;
- parser extensions;
- extension host permissions.

The exact extension identities, order, options, and host permissions are part of the environment identity.

A macro or elaborator has no independent proof authority. Generated declarations still require ordinary admission.

## 7. Standard registry policy

**[NORMATIVE ASSURANCE]**

The Standard environment is rooted in exact versioned components such as:

~~~text
Lean.Init@4.34.0
Lean.Std@4.34.0
ProofScript.Standard@0.9-r3
~~~

The exact materialized registration closure is implementation/release data.

Standard ordinary source may use registered semantic declarations, instances, theorems, fixed tactics, and allowed attributes.

Standard ordinary source may not dynamically register new:

- syntax categories;
- syntax productions;
- notation/infix/prefix/postfix forms;
- macros;
- term/command/tactic elaborators;
- tactic syntax;
- deriving handlers;
- attribute handlers;
- parser extensions;
- pretty-printer or delaborator behavior that changes Standard source interpretation.

A future Standard profile revision may add a specific facility explicitly.

## 8. Standard semantic imports

**[NORMATIVE ASSURANCE]**

A Standard package may consume checked declarations from an Extensible package through:

~~~text
PSC Semantic Bundle v1
schemaVersion = psc-semantic-bundle-1.0.0
~~~

A Standard semantic import must not install the producer package's syntax/meta environment.

For a Standard import:

~~~text
syntaxMetaExports = []
hostBuildEffects = []
~~~

The importer verifies exact bundle/dependency/payload identities and rechecks/reconstructs declarations or uses an explicitly sound evidence protocol.

A semantic import does not grant filesystem/network/process permission.

Logical assumptions and runtime/external assumptions are reported separately.

### 8.1 Compiler capability profile

**[NORMATIVE ASSURANCE]**

The language edition and a compiler implementation are not the same thing.

This specification defines the language edition:

~~~text
ps-0.9-r3
~~~

The required first production/compiler capability target is:

~~~text
psc2-compiler-v1
~~~

A compiler claiming `psc2-compiler-v1` MUST publish an exact capability manifest rather than claiming "all Lean" or "all ProofScript" support.

The user-facing Standard distribution is a separate composition profile:

~~~text
psc2-standard-v1
  =
psc2-compiler-v1
  + selected Standard libraries
  + selected Standard prover packages
  + selected official Standard extensions
~~~

A feature can therefore be part of the PSC2 user experience without being implemented as compiler core syntax/logic.

A `psc2-standard-v1` release MUST publish its exact library/prover/extension manifest. The language specification does not turn those packages into kernel authority.

The compiler manifest records at least:

~~~text
languageEdition
sourceProfiles
compilerCapabilityProfile
leanCompatibilityProfile
kernelProfile
runtimeProfiles
backendProfiles
standardLibraryProfile
standardProverProfile
extensionApiVersions
unsupportedFeatureFamilies
~~~

### 8.2 Feature ownership classes

Every material capability belongs to one primary implementation owner:

| Owner | Meaning |
|---|---|
| `CORE` | logical/core semantic construct requiring checker/kernel representation |
| `PSC2_FRONTEND` | parser/name-resolution/desugaring feature required in the PSC2 compiler |
| `PSC2_ELAB` | elaboration/Meta feature required in the PSC2 compiler |
| `STANDARD_LIBRARY` | ordinary ProofScript library capability; not compiler syntax/authority |
| `STANDARD_PROVER` | proof/tactic/Meta library shipped in the standard distribution |
| `STANDARD_EXTENSION` | versioned official syntax/elaboration extension over existing semantics |
| `CONTROLLED_PLUGIN` | optional versioned plugin/extension; not part of base compiler conformance |
| `LEAN_COMPAT` | accepted only through the bounded `.lean` compatibility frontend/profile |
| `HOST_BOUNDARY` | Node/npm/filesystem/TypeScript/WASI/native adapter outside portable semantics |
| `POST_PSC2` | planned platform capability that does not block the first PSC2 compiler closure |
| `DEFERRED` | intentionally unsupported/fail-closed until a later version/profile |

A capability being useful or common in Lean does not move it into `PSC2_FRONTEND` or `PSC2_ELAB`.

### 8.3 PSC2 compiler ownership matrix

The following matrix reconciles the language with the PSC2 compiler and platform plans.

| Capability | Owner | PSC2 compiler v1 requirement | Notes |
|---|---|---:|---|
| core Pi/lambda/Prop/Type/Sort/Eq/inductives/recursors | `CORE` | yes | same Lean-compatible logical foundation |
| `def`, `const`, `function` | `PSC2_FRONTEND` + `PSC2_ELAB` | yes | lower to ordinary definitions |
| explicit/implicit/instance binders | `PSC2_ELAB` | yes | only supported Lean-compatible subset |
| parenthesized calls, named/default args, empty-call rules | `PSC2_FRONTEND` + `PSC2_ELAB` | yes | exact r3 semantics |
| generalized field/method notation | `PSC2_ELAB` | yes | deterministic/type-directed, never JS prototype dispatch |
| record/structure update | `PSC2_FRONTEND` + `PSC2_ELAB` | yes | constructor/projection semantics |
| constructor/nested/tuple/wildcard/basic literal patterns | `PSC2_FRONTEND` | yes | bounded pattern compiler |
| multi-scrutinee match | `STANDARD_EXTENSION` | no | desugars to supported matches |
| let/do pattern bindings | `STANDARD_EXTENSION` | no | may ship with Standard distribution |
| `if let` convenience | `STANDARD_EXTENSION` | no | sugar only |
| equation-style function definitions | `STANDARD_EXTENSION` | no | pattern/compiler sugar |
| namespace/open/section/shared-variable/name-resolution basics | `PSC2_FRONTEND` | yes | required for scalable projects |
| deterministic import/re-export/package API semantics | `PSC2_FRONTEND` | yes | exact module graph ownership |
| local recursion | `PSC2_ELAB` | yes | bounded supported form |
| mutual recursion | `PSC2_ELAB` | yes | supported form must be explicit |
| structural recursion | `PSC2_ELAB` | yes | ordinary verified total recursion |
| well-founded recursion | `PSC2_ELAB` + `STANDARD_PROVER` | bounded | explicit supported termination interface; not all Lean elaboration |
| `partial` / unsafe / noncomputable boundaries | `PSC2_ELAB` + runtime policy | yes where advertised | no proof/runtime authority confusion |
| `let mut`, reassignment, `for`, `while`, `break`, `continue` | `STANDARD_EXTENSION` | no | owned sugar over explicit state/effect/iteration semantics |
| typed try/recovery | `STANDARD_LIBRARY` + optional `STANDARD_EXTENSION` | no | over `Except`/App error semantics, not host exceptions |
| `abbrev`, opacity/transparency controls | `PSC2_ELAB` / `LEAN_COMPAT` | bounded | only exact supported semantics |
| typeclass search, priorities, local/scoped instances | `PSC2_ELAB` | yes, bounded | recursion/cycle/ambiguity fail closed |
| coercion insertion | `PSC2_ELAB` | yes, bounded | no TypeScript-style implicit coercion |
| `have`, `show`, `suffices`, `calc` | `STANDARD_PROVER` | no compiler-core blocker | elaborates to ordinary proof terms |
| `rw`, `cases`, `induction`, `by_cases`, `by_contra`, destructuring proof helpers | `STANDARD_PROVER` | no compiler-core blocker | require Meta/proof-term API, not kernel growth |
| `simp`, `simpa`, `simp only` | `STANDARD_PROVER` | no compiler-core blocker | proof-producing deterministic subsystem |
| large automation (`omega`, `ring`, `linarith`, search, SMT, AI proving) | `CONTROLLED_PLUGIN` / library | no | certificates/proof terms required for strict assurance |
| `classical` and `noncomputable` | `PSC2_ELAB` / `LEAN_COMPAT` | bounded | exact assumption/execution policy required |
| fixed Standard notation set | `STANDARD_EXTENSION` | no | frozen registry, not arbitrary parser mutation |
| attributes/registries | `STANDARD_EXTENSION` / `STANDARD_PROVER` | bounded | metadata has no proof authority |
| deriving | `CONTROLLED_PLUGIN` / official Standard extension | no | generated declarations still admitted normally |
| `requires` / `ensures` pure contract core | `PSC2_ELAB` + specification layer | yes for contract-enabled compiler | final evidence is kernel-checkable |
| `assert`, loop `invariant`, `old`, ghost/stateful contract sugar | `POST_PSC2` / verification extension | no | underlying logic may be used without dedicated sugar |
| `decreasing` convenience syntax | `STANDARD_EXTENSION` / termination tooling | no | explicit termination evidence remains available |
| App/Fiber/Resource/Stream semantic model | `STANDARD_LIBRARY` + runtime adapters | semantics specified; implementation may follow PSC2 core closure | no new kernel theory |
| InterfaceIR/importer/exporter | `POST_PSC2` + `HOST_BOUNDARY` | no | platform/interop layer, not parser/kernel prerequisite |
| Meta API / tactic API / safe reflection | `POST_PSC2` | no | versioned compiler-service layer |
| general controlled plugin API | `POST_PSC2` | no | follows Meta/service stabilization |
| broad npm/WIT/Rust binding generation | `POST_PSC2` | no | InterfaceIR-based |
| large stdlib/math/proof ecosystem | `STANDARD_LIBRARY` / ecosystem | no | grows above compiler/kernel |
| arbitrary Lean syntax/macros/custom elaborators | `DEFERRED` or `ps-lean-extensible` | no | never implied by PSC2 conformance |
| arbitrary Lean compiler intrinsics/runtime representation | `DEFERRED` / `HOST_BOUNDARY` | no | only explicit compatibility adapters may expose them |
| explicit universes/polymorphism used by supported source | `PSC2_ELAB` | yes, bounded | exact universe constraints for supported subset |
| visibility/public-private API boundaries | `PSC2_FRONTEND` | yes | deterministic package/API surface |
| quotient/extensionality support | `CORE` / kernel profile | bounded | explicit selected kernel profile, not syntax convenience |
| interactive `#check`, `#print`, `#reduce`, `#synth` | tooling / `STANDARD_PROVER` | no compiler-core blocker | development commands with no proof authority |
| interactive `#eval` | `HOST_BOUNDARY` tooling | no | may execute code; MUST NOT alter accepted module semantics |
| compiler/prover options | profile/configuration layer | bounded | only registered, identity-bound options; unknown options reject |
| runtime contract checking | `STANDARD_LIBRARY` / diagnostics | no | testing/diagnostic behavior, never formal proof |
| FFI declarations/adapters | `HOST_BOUNDARY` + InterfaceIR | bounded minimal FFI only | broad generated FFI is post-PSC2 |
| kernel-provider selection / dual checking | assurance layer | no source-language requirement | multiple checkers MAY validate one canonical semantics |
| TypeScript backend | backend package | yes for first JS self-host path | consumes RuntimeIR only |
| Rust backend | backend package / post core closure | no | same RuntimeIR, independent host lane |
| direct Wasm backend | backend package / post core closure | no | same RuntimeIR, explicit ABI/runtime profile |
| portable standard libraries | `STANDARD_LIBRARY` | no compiler-core blocker | Option/Result/List/collections/text/codecs/laws |
| safe compile-time reflection | `POST_PSC2` | no | versioned semantic service, no unchecked admission |
| plugin self-hosting | `POST_PSC2` | no | plugin implementation can be ProofScript once API stabilizes |


### 8.4 Required PSC2 pattern profile

The first PSC2 compiler pattern profile is:

~~~text
psc2-pattern-v1
~~~

Required:

- variable and wildcard patterns;
- constructor patterns;
- nested constructor patterns;
- tuple/product patterns;
- supported literal patterns where literal matching has exact owned semantics;
- single-scrutinee match;
- dependent motive handling only for the explicitly supported subset.

Not required for the first PSC2 compiler closure:

- arbitrary Lean pattern elaboration;
- unsupported indexed/dependent motive synthesis;
- generalized pattern alternatives;
- equation compiler parity with Lean;
- user-defined pattern macros.

Those can be added through a later compiler capability revision or Standard extension.

### 8.5 Names/modules required for PSC2

The first PSC2 compiler closure MUST own enough deterministic name/module behavior for compiler-scale and package-scale code:

- namespace declarations;
- qualified names;
- explicit imports;
- deterministic `open` behavior for the selected subset;
- section/local variable scoping required by supported theorem/library source;
- visibility/public-private policy;
- deterministic re-export/package API representation;
- duplicate/ambiguous module-source rejection.

The compiler is not required to reproduce every Lean command or environment extension.

### 8.6 Standard prover and plugin boundary

The PSC2 compiler MUST provide the semantic services needed for proof-producing tooling:

~~~text
parse tactic/proof blocks
goal state
Meta operations
candidate term construction
kernel admission
~~~

It does **not** need every tactic name built into the compiler.

The Standard prover package may implement common tactics as ordinary untrusted programs over the Meta interface.

Large automation and AI proof search remain plugins/libraries unless a future Standard profile explicitly promotes them.

### 8.7 Post-PSC2 platform sequence

The recommended platform sequence after the first stable `psc2-compiler-v1` self-host closure is:

~~~text
P1  versioned Core / CheckedCore / CheckedModule / RuntimeIR contracts
P2  standard-library laws, tests, properties, differential conformance
P3  Meta API + tactic API + safe reflection
P4  controlled plugin API
P5  InterfaceIR + generated TypeScript/WIT/Rust foreign bindings
P6  App/Stream/Resource runtime implementations + cross-backend conformance
P7  large math/tactic/FFI/ecosystem expansion
~~~

Some work MAY overlap. These are not retroactive compiler-core requirements for the first `psc2-compiler-v1` fixed point unless an actual required compiler module depends on them. Some P2/P3 capabilities may be selected into `psc2-standard-v1` as ordinary libraries/prover packages without becoming compiler-core features.

### 8.7.1 Semantic artifact naming

This specification uses:

~~~text
Core
  -> genuine admission
CheckedCore
  -> module/environment packaging
CheckedModule
  -> erasure / executable lowering
RuntimeIR
~~~

`RuntimeIR` is a semantic artifact name, not an assurance claim. Preservation/checking evidence is recorded separately; an IR type name MUST NOT create proof authority.

Backends consume RuntimeIR (or a versioned serialization of it).

### 8.8 Naming: language profiles versus compiler generations

The name **PSC2** refers to the compiler/distribution capability family (`psc2-compiler-v1`, `psc2-standard-v1`), not to a bootstrap generation number.

Self-host iterations MUST use generation-neutral names such as:

~~~text
CompilerGen0
CompilerGen1
CompilerGen2
CompilerGen3
~~~

Example:

~~~text
compiler source --CompilerGen0--> CompilerGen1
compiler source --CompilerGen1--> CompilerGen2
~~~

Do not use `PSC2` or `PSC3` to mean compiler generations in new plans, evidence, or release reports.

### 8.9 Coverage rule

A feature can be part of the ProofScript user experience without being built into `psc2-compiler-v1`.

The compiler/profile claim is complete when:

1. every feature in this specification has an owner classification;
2. every `psc2-compiler-v1` required feature is implemented or explicitly reported unsupported;
3. library/Standard-prover/extension/post-PSC2 features have stable interfaces/lowering targets where the compiler must interact with them;
4. the compiler never claims full Lean compatibility merely because an extension/library can provide analogous functionality.

This is intentional architecture, not missing compiler coverage.

---

# Part III — Lexical and parser ownership model

## 9. Inherited lexical rules

**[NORMATIVE LANGUAGE]**

Unless r3 explicitly says otherwise, lexical treatment is inherited from the pinned Lean grammar.

This includes:

- identifiers;
- escaped identifiers;
- Unicode;
- numeric/string/character literals;
- Lean line comments;
- nested Lean block comments;
- tokenization rules;
- source spans.

ProofScript does not introduce JavaScript comment syntax.

Source transports use UTF-8 and preserve byte-offset/editor-position mapping.

## 10. Surface classes

**[NORMATIVE LANGUAGE]**

The source grammar uses four conceptual classes:

| Class | Meaning |
|---|---|
| L | inherited Lean syntax/meaning |
| D | conservative decoration |
| E | explicit ProofScript surface exception |
| X | semantic divergence excluded from the Lean-compatible base |

Parser ownership order:

~~~text
1. matching registered E production
2. matching registered D production
3. native production permitted by the selected profile
4. direct diagnostic / unsupported-feature
~~~

Once an owned discriminator commits, malformed owned syntax MUST NOT silently fall back to another grammar.

## 11. Native lifting

**[NORMATIVE LANGUAGE]**

Lift<C> means:

> use the pinned native production for category C, replacing only explicitly registered child-category slots with ProofScript-aware child parsers/lowerers.

Do not approximate a difficult native category by storing opaque text and later claiming it was parsed.

Do not globally rewrite punctuation before parsing.

Do not globally replace equals signs, semicolons, braces, comments, or parentheses.

---

# Part IV — Exact r3 surface grammar

## 12. Definitions

**[NORMATIVE LANGUAGE]**

Native def remains the general declaration.

function is a declaration-head alias for a parameterized definition.

const is a top-level/namespace parameterless-definition alias.

const does not mean:

- local JS const;
- deep freeze;
- compile-time evaluation;
- immutable object identity.

Local immutable bindings use native let.

No general ProofScript declaration semicolon exists.

## 13. Explicit parameter groups

**[NORMATIVE LANGUAGE]**

Example:

~~~proofscript
function select(n: Nat, i: Fin n): Fin n :=
  i
~~~

A comma-separated explicit group consists of complete binders:

~~~ebnf
ExplicitGroup :=
  "(" ExplicitEntry ("," ExplicitEntry)* ","? ")"

ExplicitEntry :=
  BinderIdent ":" PSTerm DefaultSuffix?
~~~

A trailing comma is allowed for a nonempty explicit parameter group.

This trailing-comma policy is category-specific.

## 14. Zero-source-argument functions

**[NORMATIVE LANGUAGE]**

r3 accepts:

~~~proofscript
function now(): Time :=
  ...
~~~

Canonical lowering:

~~~lean
def now (_ : Unit := ()) : Time :=
  ...
~~~

The hidden Unit binder is a native optional parameter whose default is Unit.

This preserves the unary/curried core model and allows the declaration to remain a function value.

Native def receives no hidden parameter.

Native non-explicit binders may precede the final empty explicit group.

The empty group cannot be mixed with another explicit group in the same function header.

Examples:

~~~proofscript
function factory {α: Type}(): Box α :=
  ...

function bad()(x: Nat): Nat := x   -- reject
function bad(x: Nat)(): Nat := x   -- reject
~~~

## 15. Parenthesized calls

**[NORMATIVE LANGUAGE]**

Parenthesized-call syntax is the E-class feature `E-CALL-PARENS-R3`.

These have the same .ps meaning:

~~~proofscript
f(x)
f (x)
~~~

and:

~~~proofscript
f(x, y)
f (x, y)
~~~

One tuple argument requires explicit extra grouping:

~~~proofscript
f((x, y))
~~~

The canonical formatter prints:

~~~proofscript
f(x)
f(x, y)
f((x, y))
~~~

### Postfix-call parser algorithm

The grammar is implemented as a postfix parse over a completed callable head rather than as mutually recursive `PSTerm ::= ParenthesizedCall ::= CallableHead ::= ParenthesizedCall` productions.

Conceptually:

~~~text
parseCallableTerm(category, input, env):
    head := parseCompletedHead(category, input, env)

    loop:
        if next tokens form CallGap followed by "(":
            head := parseOwnedParenthesizedCallSuffix(head)
            continue

        if the selected native/profile grammar owns another compatible postfix
           or projection suffix:
            head := parseNativeCompatiblePostfix(head)
            continue

        break

    return head
~~~

`parseOwnedParenthesizedCallSuffix` parses either:

~~~text
"(" ")"                         -> PsEmptyCall(head)
"(" CallArguments ")"           -> PsParenthesizedCall(head, arguments)
~~~

This algorithm is normative with respect to ownership/grouping; a compiler may use Pratt parsing, parser combinators, generated parsers, or another technique if it produces the same ownership and AST boundaries.

## 16. CallGap

**[NORMATIVE LANGUAGE]**

CallGap between a completed callable head and the opening parenthesis allows:

- inherited horizontal Lean space trivia;
- Lean comments that contain no physical line terminator.

r3 does not introduce tab-as-whitespace if the pinned lexer does not recognize it as such.

A physical source line terminator breaks parenthesized-call ownership.

Thus:

~~~proofscript
f (x)
f/- note -/(x)
~~~

are calls when the comment contains no line terminator.

But:

~~~proofscript
f
(x)
~~~

is not one r3 parenthesized call.

Multiline arguments are allowed after the opening parenthesis:

~~~proofscript
f(
  x,
  y,
)
~~~

## 17. Empty calls

**[NORMATIVE LANGUAGE]**

r3 defines:

~~~proofscript
f()
~~~

as:

> invoke f with zero source-supplied explicit arguments, completing only parameters that are semantically omittable.

Canonical high-level native request:

~~~lean
f ..
~~~

The pinned Lean application elaborator performs native insertion of:

- implicit parameters;
- instance parameters;
- strict implicits as applicable;
- optional/default parameters;
- automatic parameters.

Then the r3 acceptance check requires:

1. every omitted explicit parameter was represented by native optParam or autoParam;
2. no ordinary required explicit parameter was accepted merely because native ellipsis created or solved a metavariable;
3. no unresolved metavariable remains;
4. empty-call syntax never eta-abstracts required parameters.

Examples:

~~~proofscript
function now(): Time := ...
now()
-- hidden optional Unit defaults to ()

function greet(name: String := "world"): String := ...
greet()
-- declared default is inserted

function add(x: Nat): Nat := x + 1
add()
-- PS_EMPTY_CALL_REQUIRED_ARGUMENT
~~~

Explicit Unit remains different:

~~~proofscript
f(())
~~~

That is a nonempty call with one explicit Unit term.

To obtain a function value or ordinary partial application, use the function value or a nonempty/native application form rather than relying on f().

No JavaScript undefined value is introduced.

### Empty-call eligibility after type ascription

Empty-call eligibility is determined from the **actual elaborated callable type at the call site**, not from the historical declaration that produced the value.

Example:

~~~proofscript
function now(): Time := ...
const g: Unit -> Time := now

now()    -- valid: callable type retains the optional Unit parameter
g()      -- reject: g's ascribed type has an ordinary required Unit parameter
g(())    -- valid explicit Unit application
~~~

Any coercion, wrapper, explicit type ascription, higher-order parameter, or exported foreign signature that erases native `optParam` / `autoParam` metadata also erases the corresponding empty-call omission privilege.

This rule prevents a compiler from guessing declaration ancestry to recover defaults.

## 18. Named arguments

**[NORMATIVE LANGUAGE]**

Inside an r3 parenthesized call:

~~~proofscript
connect(host, timeout := 5000)
~~~

lowers to native named-argument syntax.

Rules:

- name := expression is recognized only at an argument start;
- duplicate named arguments reject;
- name: value is not a named-call spelling;
- native parameter-name matching/elaboration remains authoritative.

## 19. Call trailing commas

**[NORMATIVE LANGUAGE]**

A nonempty call may use one trailing comma:

~~~proofscript
f(x, y,)
~~~

Rejected:

~~~proofscript
f(,)
f(x,,y)
~~~

## 20. Generalized field notation

**[NORMATIVE LANGUAGE]**

r3 changes spacing around the call parenthesis, not the dot.

Accepted:

~~~proofscript
users.map(render)
~~~

Not added by r3:

~~~proofscript
users .map(render)
~~~

The dot keeps its inherited adjacency requirement.

Receiver placement is type-directed by the pinned Lean elaborator. The PSC frontend must not hard-code the receiver as the first explicit parameter.

## 21. Patterns

**[NORMATIVE LANGUAGE]**

Parenthesized-call syntax is term-only.

Native pattern:

~~~proofscript
| .some x => ...
~~~

Not an r3 pattern:

~~~proofscript
| .some(x) => ...
~~~

## 22. Structural braces

**[NORMATIVE LANGUAGE]**

When an r3-owned construct uses braces, braces plus category-specific separators/markers determine the outer member sequence.

Indentation inside that owned outer sequence is formatting.

Nested inherited child categories can retain native layout rules.

### 22.1 structures

~~~proofscript
structure User where {
  name: String,
  active: Bool
}
~~~

Fields are comma-separated.

No trailing field comma.

Each field is a lifted native structure field, preserving supported dependent types/defaults/attributes/documentation.

Empty braces are admitted only where the lowered native declaration is semantically valid.

### 22.2 classes

~~~proofscript
class Sized(α: Type) where {
  size: α -> Nat
}
~~~

Same outer separator policy as structures.

### 22.3 inductives

~~~proofscript
inductive State(α: Type) where {
  | idle
  | ready(value: α)
}
~~~

Constructor boundary marker is leading vertical bar.

No constructor comma/semicolon terminator is introduced.

A zero-constructor body is parsed only where the corresponding native declaration is semantically valid.

### 22.4 match

~~~proofscript
match value with {
  | .none => fallback
  | .some x => x
}
~~~

Patterns remain native.

Each RHS is exactly one term.

### 22.5 instances

Brace-mode instance fields use explicit native semicolon sequence behavior:

~~~proofscript
instance : Sized String where {
  size(s: String): Nat := s.length;
}
~~~

A trailing semicolon is allowed only because the inherited instance sequence admits it.

### 22.6 local where

Brace-mode local declarations use the inherited local-declaration semicolon sequence.

At least one local declaration is required.

### 22.7 braced if

~~~proofscript
if (condition) { thenTerm } else { elseTerm }
~~~

Each branch is exactly one term.

This is not a JavaScript statement block and has no implicit return rule.

### 22.8 native do and tactics

Native do and tactic sequencing retain their own category rules.

Their semicolons are not general ProofScript declaration terminators.

## 23. Category-specific trailing commas

**[NORMATIVE LANGUAGE]**

| Category | Trailing comma |
|---|---|
| nonempty parenthesized call | allowed |
| nonempty explicit parameter group | allowed |
| structure fields | rejected |
| class fields | rejected |
| native tuple/pattern/record syntax | inherited native rule |

There is no universal trailing-comma rule.

---

# Part V — Inherited type system and core semantics

## 24. Logical foundation

**[NORMATIVE LANGUAGE]**

ProofScript uses the pinned Lean logical foundation.

Inherited concepts include:

- Prop;
- Type and Sort;
- universes;
- dependent function/Pi types;
- propositions as types;
- proof terms;
- inductive families;
- recursors;
- equality;
- quotients;
- coercions;
- typeclasses;
- proof irrelevance according to the selected theory;
- native elaboration and definitional equality.

ProofScript introduces no approximate TypeScript-like substitute for these concepts.

## 25. Function model

**[NORMATIVE LANGUAGE]**

Core functions are unary/curried.

Source conveniences such as:

~~~proofscript
function add(x: Nat, y: Nat): Nat := x + y
~~~

lower to native binder/application structure.

ProofScript does not define JavaScript-style multi-argument core functions.

Named/default/implicit/automatic behavior is delegated to the pinned high-level application semantics, subject to r3-owned source acceptance rules such as empty-call validation.

## 26. Structures, records, updates

**[NORMATIVE LANGUAGE]**

Structures retain nominal/logical declaration identity.

Record construction/update uses native semantics.

A record update involving dependent fields is accepted only if retained/rebuilt fields satisfy their dependent types.

Target object spread does not define source record-update semantics.

## 27. Inductives and matching

**[NORMATIVE LANGUAGE]**

Inductives retain:

- constructor typing;
- positivity;
- parameters and indices;
- motives;
- exhaustive/dependent elimination;
- mutual/nested behavior as supported by the selected environment.

Pattern syntax remains native unless explicitly registered.

## 28. Classes and instances

**[NORMATIVE LANGUAGE]**

Classes/typeclasses are native type-directed abstractions.

Instances are semantic registrations, not JavaScript classes.

Instance search is part of elaboration/environment identity.

## 29. Recursion and termination

**[NORMATIVE LANGUAGE]**

Inherited distinctions remain among:

- structural recursion;
- well-founded recursion;
- partial definitions;
- unsafe definitions;
- noncomputable definitions;
- selected fixpoint/coinductive facilities.

A termination proof is not the same as a partial-correctness proof.

A logical definition can be admitted while a separate runtime replacement still requires its own execution/preservation evidence.

---

# Part VI — Exact primitive and data semantics

## 30. Nat

**[NORMATIVE LANGUAGE]**

Nat denotes exact nonnegative natural numbers under the pinned semantics.

Important requirement:

~~~text
Nat subtraction truncates at zero.
~~~

Division/remainder use the exact selected native declarations, including selected zero-divisor behavior.

A JS number implementation does not define Nat.

## 31. Int

**[NORMATIVE LANGUAGE]**

Int uses the exact pinned Lean semantics.

Signed division/remainder must preserve the selected source behavior, including negative cases.

A target BigInt/native integer operator is not assumed equivalent without a representation/operation argument.

## 32. Fixed-width and target-word integers

**[NORMATIVE LANGUAGE]**

For fixed-width and target-word types, a target profile must specify:

- width;
- overflow/wrapping/checking;
- shifts;
- conversions;
- target-word width assumptions.

The target representation must preserve selected observable operations.

## 33. Floating point

**[NORMATIVE LANGUAGE]**

Floating-point values are not mathematical reals.

Preservation must account for selected:

- rounding;
- NaN;
- infinities;
- signed zero;
- target/runtime assumptions.

## 34. Bool

**[NORMATIVE LANGUAGE]**

Bool is distinct from Prop.

A true Boolean computation is not automatically proof evidence for an arbitrary proposition.

## 35. Char, String and ByteArray

**[NORMATIVE LANGUAGE]**

Pinned native semantics remain authoritative.

A JavaScript UTF-16 representation/index is an implementation relation, not the source definition of String.

Backend adapters must define conversions explicitly.

## 36. Collections and data types

**[NORMATIVE LANGUAGE]**

List, Array, Option, products, sums, subtypes, Fin, maps, iterators, and other native abstractions remain distinct.

Examples:

~~~text
List is not Array.
Option is not implicit undefined/null.
Fin n is not merely a runtime integer check.
~~~

A target may use efficient representations only under the required semantic relation.

---

# Part VII — Modules, source identity and packages

## 37. One authoritative source per module

**[NORMATIVE ASSURANCE]**

Each logical module resolves to one exact source snapshot.

If both M.ps and M.lean exist, a manifest must select one or the build rejects ambiguity.

A generated canonical .lean file is not a fallback source.

Missing inputs must not be replaced silently by:

- stale siblings;
- another branch;
- host-installed packages;
- old generated outputs.

## 38. Environment order

**[NORMATIVE ASSURANCE]**

Commands are processed in source/environment order.

Imports, options, instances, attributes, semantic registrations, syntax profile, and semantic-bundle identities contribute to environment identity.

## 39. Generated source/provenance

**[NORMATIVE ASSURANCE]**

Generated inputs record:

- generator identity;
- source identities;
- generation options/profile;
- exact generated bytes.

Evidence binds the bytes actually checked.

A release must not check one mutable file and publish a later reread without rebinding evidence.

---

# Part VIII — Stable PSC-owned contracts

## 40. Contract core identity

**[NORMATIVE LANGUAGE]**

Stable r3 contract semantics:

~~~text
psc-contract-core-v1
~~~

Normative base surface clauses:

~~~text
requires <Prop-term>
ensures result => <Prop-term>
~~~

The stable core applies to total pure functions.

The following syntax is not part of base r3 merely because the concepts are useful:

- dedicated success/error postcondition syntax;
- loop invariant syntax;
- assert syntax;
- old-state syntax;
- modifies/writes syntax;
- async contract sugar;
- decreasing syntax.

Future profiles may add such sugar without changing the underlying logical model.

## 41. Pure contract meaning

**[NORMATIVE LANGUAGE]**

For:

~~~proofscript
function f(x: A): B
  requires Pre(x)
  ensures result => Post(x, result)
:=
  implementation
~~~

the required evidence is equivalent to:

~~~text
forall x,
  Pre(x) ->
  Post(x, f(x))
~~~

where f is the actual admitted implementation.

Multiple requires clauses conjoin.

Multiple ensures clauses conjoin.

No requires means True.

No ensures means no functional contract theorem request; type correctness alone must not be reported as a proved functional postcondition.

## 42. Outcome-sensitive contracts

**[NORMATIVE LANGUAGE]**

For sum/error values, use ordinary matching inside the result relation:

~~~proofscript
function parse(input: String): Except ParseError User
  ensures result =>
    match result with {
      | .ok user => User.valid(user)
      | .error err => ParseError.describes(input, err)
    }
:=
  ...
~~~

Dedicated .ok/.error ensures syntax is not base r3.

## 43. Contract identity

**[NORMATIVE LANGUAGE]**

A normalized contract identity includes at least:

- exact implementation identity;
- normalized precondition;
- normalized postcondition/result relation;
- semantic dependency closure;
- axiom policy;
- environment identity;
- termination class;
- effect frame;
- read frame;
- write frame;
- program-logic version.

Changing a referenced predicate can invalidate contract evidence even when the source ensures text is unchanged.

## 44. Frame/effect semantics

**[NORMATIVE LANGUAGE]**

Every contract has semantic frame fields.

For a pure total function:

~~~text
effectFrame = {}
readFrame   = {}
writeFrame  = {}
~~~

For future effectful program logics:

- effectFrame lists permitted capability-operation identities;
- readFrame lists abstract mutable regions/resources whose state may influence behavior;
- writeFrame lists abstract mutable regions/resources that may be modified.

A postcondition about the return value does not authorize writes to unrelated state.

Capability permission and frame permission are distinct.

## 45. Higher-order callable contracts

**[NORMATIVE LANGUAGE]**

ProofScript is higher-order.

The logical specification layer defines generic relations conceptually:

~~~text
callRequires(f, args) : Prop
callEnsures(f, args, outcome) : Prop
callEffects(f, args) : EffectFrame
callReads(f, args) : ReadFrame
callWrites(f, args) : WriteFrame
~~~

A callable has only the specification that can be established by ordinary checked declarations/lemmas.

No specification is inferred from comments, tests, naming, or a foreign declaration alone.

## 46. Caller obligations

**[NORMATIVE LANGUAGE]**

A precondition is not automatically a runtime check.

A verified caller must establish it.

An untrusted external caller requires either:

- an explicit runtime-validating wrapper; or
- a documented restricted/trusted boundary.

A generated TypeScript declaration does not discharge a ProofScript precondition.

## 47. VC generation

**[NORMATIVE LANGUAGE]**

VC generation is untrusted proof construction.

It may:

- split goals;
- generate helper lemmas;
- use tactics;
- invoke solvers;
- produce certificates.

Strict acceptance requires final evidence checked under the selected proof/evidence protocol.

A solver response or proof of an unrelated True proposition does not authorize the implementation.

## 48. Assumptions

**[NORMATIVE LANGUAGE]**

Contract evidence reports transitive logical assumptions separately from runtime/external assumptions.

Policy-disallowed assumptions, unresolved holes, or incomplete proof search do not become strict contract success.

---

# Part IX — Standard application semantics

## 49. Semantic profile

**[NORMATIVE LANGUAGE]**

Standard application semantic profile:

~~~text
psc-app-v1
~~~

Conceptual types:

~~~text
App Caps E A
Exit E A
Fiber Caps E A
Resource Caps E A
Stream Caps E A
RuntimeFault
CancelReason
~~~

These are ordinary library/runtime concepts, not new kernel primitives.

## 50. App is cold

**[NORMATIVE LANGUAGE]**

Constructing, storing, copying, or reusing:

~~~text
App Caps E A
~~~

starts no external/application work.

Execution begins only through an explicit runtime operation such as root run or scoped fork.

This is a deliberate difference from an already-running foreign Promise.

## 51. Exit and RuntimeFault

**[NORMATIVE LANGUAGE]**

Typed application completion:

~~~text
Exit E A :=
  success A
  | failure E
  | cancelled CancelReason
~~~

Unexpected runtime/host faults are separate.

A root runtime may report a wider outcome such as:

~~~text
completed (Exit E A)
runtimeFault RuntimeFault
resourceLimit ResourceLimit
hostTerminated HostTermination
~~~

Ordinary typed catch handles failure E, not arbitrary RuntimeFault.

A foreign adapter can explicitly translate selected runtime faults into E; that translation is part of the adapter contract.

## 52. Capabilities

**[NORMATIVE LANGUAGE]**

Caps is an explicit local upper bound on permitted application capability classes.

Examples can include:

~~~text
Console
Clock
Random
FileSystem
Network
Process
Environment
Storage
Dom
~~~

CapabilitySet is a canonical finite set.

Normative set algebra:

~~~text
empty capability set        = {}
composition                  = set union
environment satisfaction     C_required ⊆ C_provided
equality                     = canonical set equality
~~~

Conceptually:

~~~text
pure : A -> App {} E A

map :
  (A -> B) ->
  App C E A ->
  App C E B

bind :
  App C1 E A ->
  (A -> App C2 E B) ->
  App (C1 ∪ C2) E B
~~~

The base combinators keep the same typed error parameter `E`. Combining computations with different typed error domains requires an explicit error mapping/injection before bind.

A computation requiring C1 can execute in an environment C2 only when `C1 ⊆ C2` or an explicit adapter provides the missing capability.

A package manifest aggregates reachable capabilities, but package metadata does not replace local effect visibility.

Hidden host globals do not expand Caps.

## 53. Pure functions and App

**[NORMATIVE LANGUAGE]**

An ordinary function A -> B is pure with respect to application effects.

A pure function may construct an App value without starting it.

This allows pure domain functions and theorems to remain independent of runtime execution.

## 54. Fiber is started

**[NORMATIVE LANGUAGE]**

Fiber denotes already-started child work.

A child can terminate with a result wider than `Exit E A` because runtime faults are deliberately not values of `E`.

~~~text
FiberOutcome E A :=
    completed (Exit E A)
  | runtimeFault RuntimeFault
  | resourceLimit ResourceLimit
  | hostTerminated HostTermination
~~~

Conceptually:

~~~text
fork :
  App C E A ->
  App ParentC ParentE (Fiber C E A)

join :
  Fiber C E A ->
  App JoinC JoinE (FiberOutcome E A)

cancel :
  Fiber C E A ->
  App CancelC CancelE Unit
~~~

A child `RuntimeFault` is therefore observable through the distinct `runtimeFault` branch of `FiberOutcome`; it is not silently converted into `failure E`.

Calling `run` or `fork` on the same cold `App` value twice starts two logically distinct executions unless the application itself explicitly shares a foreign handle/resource.

## 55. Structured concurrency

**[NORMATIVE LANGUAGE]**

Fibers belong to an owning scope by default.

A scope cannot successfully finish while owned children are silently left running.

On scope exit:

1. cancellation is requested for unfinished children;
2. required cleanup runs;
3. the scope waits for terminal outcomes subject to explicit resource limits;
4. child/cleanup causes are combined without silent information loss;
5. detach is explicit and transfers ownership.

## 56. Cancellation

**[NORMATIVE LANGUAGE]**

Cancellation is cooperative and two-phase.

~~~text
Running
  -> cancel requested
Cancelling
  -> Success | Failure | Cancelled
~~~

cancel is a request, not a terminal-result proof.

Normal completion/typed failure can race with cancellation according to the modeled scheduler relation.

Foreign adapters state whether external work can actually be cancelled.

Cancelling a local wait does not imply remote rollback.

## 57. Resource cleanup

**[NORMATIVE LANGUAGE]**

Resource represents acquisition plus deterministic release.

After successful acquisition, release is attempted exactly once on:

- success;
- typed failure;
- cancellation.

Once required cleanup begins, ordinary cooperative cancellation is shielded/masked until cleanup reaches a terminal result.

Fatal host/resource-limit outcomes remain separately reported.

Cleanup outcome composition is explicit:

~~~text
ResourceCause E R :=
    bodyFailure E
  | releaseFailure R
  | bodyAndRelease E R
  | cancellationAndRelease CancelReason R
  | runtimeFaultDuringRelease RuntimeFault
~~~

If the body succeeds and release fails, the release failure is retained.
If body and release both fail, both causes are retained.
If cancellation triggers cleanup and cleanup fails, both the cancellation reason and release failure are retained.

A concrete library MAY wrap these constructors in a broader application error type, but it MUST NOT discard one cause.

Garbage collection/finalizers do not define deterministic resource semantics.

## 58. Race and timeout

**[NORMATIVE LANGUAGE]**

race starts contenders in one structured scope.

The winner is the first terminal outcome selected by the scheduler trace.

Then the loser receives cancellation and required cleanup completes before the race scope finishes.

timeout is a race/deadline operation requiring an explicit monotonic-clock capability/model.

A timeout does not imply rollback of already-observed external effects.

## 59. Stream

**[NORMATIVE LANGUAGE]**

Stream is cold and reusable as a computation description unless a separately named adapter exposes a single-use foreign stream.

Each subscription creates a new owned execution scope.

Conceptually:

~~~text
subscribe :
  Stream C E A ->
  App C SubError (Subscription C E A)

request :
  Subscription C E A ->
  Nat ->
  App C SubError Unit

next :
  Subscription C E A ->
  App C SubError (StreamStep E A)

StreamStep E A :=
    item A
  | end
  | failure E
  | cancelled CancelReason
~~~

Demand is credit based:

- `request(n)` adds exactly `n` units of demand credit;
- one emitted item consumes one unit of credit;
- the producer MUST NOT emit more items than available credit plus an explicitly declared bounded prefetch buffer;
- `next` is equivalent to requesting one unit when no outstanding demand exists and then waiting for one terminal/item step;
- after `end`, `failure`, or `cancelled`, no further item can be emitted;
- closing/cancelling a subscription triggers owned, shielded cleanup.

RuntimeFault remains outside typed `StreamStep E A` and is reported through the containing application/runtime outcome.

A target adapter that cannot enforce these semantics MUST use a separately named weaker/buffered stream profile.

## 60. Native Lean IO/Task

**[NORMATIVE LANGUAGE]**

Native Lean IO and Task remain inherited low-level/native abstractions.

Portable ps-standard APIs normally expose:

- App;
- Fiber;
- Resource;
- Stream.

Low-level runtime-adapter modules or ps-lean-extensible code may use native IO/Task under explicit profiles.

A theorem about App semantics does not automatically prove an IO adapter correct.

## 61. Target async adapters

**[NORMATIVE LANGUAGE]**

JavaScript Promise/AbortController, AsyncIterable/ReadableStream, and WASI async/future/stream facilities are target adapter mechanisms.

They do not define ProofScript source semantics.

A target profile must document:

- start/hot/cold relationship;
- cancellation;
- errors/faults;
- ownership;
- cleanup;
- stream demand;
- external assumptions.

A target that cannot preserve the Standard relation rejects that capability or uses a separately named weaker profile.

---

# Part X — npm / TypeScript interoperability

## 62. InterfaceIR identity

**[NORMATIVE LANGUAGE]**

Normative interop format:

~~~text
ProofScript InterfaceIR v1
schemaVersion = proofscript-interface-ir-1.0.0
resolverProfile = psc-node-exports-v1
~~~

InterfaceIR sits between TypeScript/npm declarations and native ProofScript APIs.

TypeScript declarations do not become ProofScript proof/type semantics directly.

## 63. Binding identity

**[NORMATIVE LANGUAGE]**

An InterfaceIR binding identity includes a canonical `ResolverConfigId` and exact package-install identity in addition to the selected runtime/type entries.

### Canonical ResolverConfig

`ResolverConfig` is the canonical serialization of **every option that can affect module or declaration resolution under the selected TypeScript version/profile**.

At minimum, when relevant to the selected resolver version, it includes:

~~~text
typescriptVersion
moduleResolution
module
baseUrl
paths
rootDirs
moduleSuffixes
customConditions
resolvePackageJsonExports
resolvePackageJsonImports
types
typeRoots
preserveSymlinks
allowArbitraryExtensions
target/runtime condition profile
package-json resolver profile
~~~

The set is versioned by `typescriptVersion`: if a newer TypeScript version introduces another resolver-affecting option, that option becomes part of the canonical config for that resolver version even if it is not listed above.

~~~text
ResolverConfigId =
  sha256(canonicalSerialize(ResolverConfig))
~~~

### PackageInstallIdentity

`PackageInstallIdentity` identifies the actual resolved package node, not merely its semver.

It includes or binds:

~~~text
package-manager/resolver profile
lockfile identity when present
resolved package content/source identity
real/symlink policy
dependency-graph node identity
package root identity
~~~

An implementation MAY represent this as an opaque content-addressed package-store identity if the package manager guarantees those properties.

### Full binding identity

The binding identity includes:

- InterfaceIR schema version;
- ResolverConfigId;
- PackageInstallIdentity;
- package name/version;
- exact package.json SHA-256;
- requested export subpath;
- ordered runtime condition trace;
- selected runtime entry path/format/SHA-256;
- ordered type/declaration condition trace;
- selected declaration entry path/SHA-256;
- referenced declaration file hashes;
- target runtime/platform;
- generator/importer identity.

Package version alone is never sufficient.

## 64. Runtime/type resolution

**[NORMATIVE LANGUAGE]**

Runtime and type resolution are recorded separately.

The importer must record the exact selected branches.

A declaration branch must not be assumed to describe the selected runtime branch merely because both come from the same package version.

If they cannot be related under the recorded export/resolution policy, reject.

Representative diagnostic:

~~~text
PS_DTS_RUNTIME_TYPE_BRANCH_MISMATCH
~~~

## 65. Raw / safe / specification layers

**[NORMATIVE LANGUAGE]**

### Raw

Closest supported representation of the foreign API.

Can contain:

- ForeignValue;
- ForeignHandle;
- ForeignPromise;
- foreign receiver-bound functions;
- explicit presence states.

Raw is not validated.

### Safe

Performs:

- numeric conversion/range checks;
- presence/null/undefined policy;
- schema/data validation;
- receiver binding;
- callback/resource lifetime management;
- Promise/App adaptation;
- exception/rejection classification.

### Specification

Optional logical model/theorems.

A theorem about an abstract foreign model does not prove the external JS implementation matches it without a separately established correspondence/assumption.

## 66. Presence

**[NORMATIVE LANGUAGE]**

Where an API distinguishes them, InterfaceIR preserves:

~~~text
missing
undefined
null
value
~~~

An optional property does not automatically equal Option.

Safe adapters declare the mapping and whether it is lossy.

## 67. Numbers

**[NORMATIVE LANGUAGE]**

JS number remains a foreign floating-number domain until converted.

JS bigint may map to Int, or to Nat only after nonnegativity validation.

Target arithmetic does not define source Nat/Int semantics.

## 68. Object/identity model

**[NORMATIVE LANGUAGE]**

Plain data may be copied/decoded into owned nominal structures.

Identity-bearing/mutable objects such as DOM nodes normally become opaque foreign handles with effectful operations.

TypeScript readonly is static metadata, not proof of deep runtime immutability.

## 69. Functions and this

**[NORMATIVE LANGUAGE]**

A binding records:

- receiver/this requirement;
- type parameters;
- parameter kinds;
- optional/default/rest shape;
- result;
- sync kind;
- Promise/callback behavior;
- documented throw policy;
- effect/capability classification;
- overload group.

A receiver-dependent method is not silently equivalent to an unbound function.

## 70. Advanced TypeScript types

**[NORMATIVE LANGUAGE]**

Supported direct/specialized mappings can include:

- simple generics;
- tuples;
- object data;
- literal/discriminated unions;
- simple function types.

Import-time normalization may handle finite supported cases of:

- conditional types;
- mapped types;
- template-literal types;
- keyof;
- indexed access.

Classes/DOM/symbol-like identities typically map to handles/opaque values.

Unsupported forms, recursive type-level computation, unsupported global/module augmentation, or non-normalizable declaration merging reject.

Unsupported never becomes native any.

## 71. Promise/callback/iterable

**[NORMATIVE LANGUAGE]**

Promise remains a foreign async handle at the raw layer.

Adapters document:

- whether work already started;
- rejection classification;
- cancellation support;
- late completion;
- retained callback/resource behavior.

Callbacks document reentrancy, sync/deferred invocation, one-shot/repeated behavior, retention/disposal, execution context, and error translation.

AsyncIterable maps to Stream only under a defined cancellation/demand/cleanup relation.

---

# Part XI — Compiler architecture

## 72. Required phase pipeline

**[IMPLEMENTATION GUIDANCE]**

An AI/compiler implementer MUST preserve explicit phase boundaries.

~~~text
exact source bytes
  ->
source/profile/environment resolution
  ->
lexer/token stream + source spans
  ->
category-aware parser ownership
  ->
ProofScript surface AST
  ->
canonicalization/lowering
  ->
canonical Lean-compatible syntax
  ->
Lean-compatible elaboration
  ->
candidate declarations
  ->
genuine kernel admission
  ->
CheckedModule
  ->
relevance/erasure
  ->
RuntimeIR
  ->
target IR/AST
  ->
serializer
  ->
target bytes
  ->
link/bundle/package/deploy transforms
~~~

No phase can silently stand in for a later phase.

## 73. Compiler implementation rule for AI agents

**[IMPLEMENTATION GUIDANCE]**

An AI implementing the compiler SHOULD work feature-by-feature and phase-by-phase.

For every feature record:

~~~text
feature ID
source category
discriminator/ownership
surface AST node
source spans
child categories
canonical lowering
canonical target category
diagnostics
formatter rule
migration rule
profile availability
elaboration dependencies
runtime/backend relevance
evidence status
~~~

Do not implement a feature only as a regex/text transform.

## 74. Source/profile resolution

**[IMPLEMENTATION GUIDANCE]**

Before parsing:

1. resolve one exact source snapshot;
2. resolve edition/profile;
3. resolve module identity;
4. resolve Standard/extensible registry identity;
5. resolve imports/bundles;
6. reject source ambiguity;
7. construct the parser/environment identity.

Parser behavior must not depend on mutable undeclared host state.

## 75. Lexer/token representation

**[IMPLEMENTATION GUIDANCE]**

Preserve:

- original byte offsets;
- line/column positions;
- token categories;
- comments/trivia;
- syntax scopes/pre-resolved identities where inherited;
- source file/module identity.

CallGap decisions use actual lexical trivia, not normalized text.

## 76. Parser ownership algorithm

**[IMPLEMENTATION GUIDANCE]**

For every supported syntactic category:

~~~text
parseCategory(C, input, env):
  if matching registered E discriminator:
      commit to E parser
      if malformed: return owned diagnostic
  else if matching registered D discriminator:
      commit to D parser
      if malformed: return owned diagnostic
  else if native production C is permitted by profile:
      parse pinned native production/lifted child slots
  else:
      return unsupported-feature
~~~

A parser recovery path may produce editor diagnostics, but release compilation must not reinterpret a malformed committed E/D form as some permissive native neighbor.

## 77. Surface AST design

**[IMPLEMENTATION GUIDANCE]**

The surface AST should be typed by grammatical category, not one generic syntax tree plus text tags.

Representative nodes:

~~~text
PsFile
PsCommand
PsTerm
PsDecl
PsFunctionDecl
PsConstDecl
PsExplicitBinderGroup
PsParenthesizedCall
PsEmptyCall
PsNamedCallArg
PsBracedIf
PsBracedMatch
PsBracedStructure
PsBracedClass
PsBracedInductive
PsBracedInstance
PsBracedWhere
PsContract
~~~

Every owned node records:

- source span;
- feature ID;
- profile/grammar revision;
- owned delimiters/separators;
- child nodes;
- comments/trivia needed for formatting/migration.

Native syntax nodes should retain enough native identity/scopes for correct lifting/hygiene.

## 78. Canonical lowering requirements

**[IMPLEMENTATION GUIDANCE]**

Lower structurally from AST.

Do not:

- globally delete whitespace;
- replace punctuation in raw strings;
- flatten all nested application groups;
- invent target types before native elaboration;
- rewrite quoted syntax recursively unless that quoted category explicitly opts in.

Examples:

~~~text
function f(x:T):U := e
  -> native def f (x:T) : U := lower(e)

function f():U := e
  -> native def f (_ : Unit := ()) : U := lower(e)

f(x,y)
  -> one native high-level application with two source arguments

f()
  -> native high-level ellipsis application f ..
     plus r3 omitted-required-explicit acceptance check

f((x,y))
  -> one application argument containing a tuple

if (p) { a } else { b }
  -> native if p then a else b
~~~

## 79. Empty-call implementation algorithm

**[IMPLEMENTATION GUIDANCE]**

An implementation agent must not special-case TypeScript undefined.

Recommended algorithm:

1. parse E-EMPTY-CALL-R3;
2. lower the head;
3. emit a native high-level application request equivalent to head ..;
4. let the pinned-compatible elaborator insert implicit/instance/optional/automatic arguments;
5. retain metadata relating elaborated arguments to source parameters;
6. reject if an omitted explicit parameter was ordinary required rather than optParam/autoParam;
7. reject unresolved metavariables;
8. record generated/defaulted argument provenance for diagnostics/source maps.

This acceptance check belongs to source correspondence/elaboration policy, not the kernel.

## 80. Structural-brace parser algorithm

**[IMPLEMENTATION GUIDANCE]**

For r3-owned braces:

- outer separators/markers are structural;
- nested delimiters shield nested commas/semicolons/bars;
- nested child terms/types use their own categories;
- indentation does not terminate the outer member list;
- comments/strings/quotations do not produce outer separators.

Structure/class body:

~~~text
field (comma field)*
no trailing comma
~~~

Instance/where sequences use their specified native semicolon role.

Match/inductive use leading vertical-bar markers.

## 81. Hygiene and binding

**[IMPLEMENTATION GUIDANCE]**

Lowering must preserve:

- user binding identity;
- native macro scopes;
- pre-resolved references where present;
- namespace/module identity.

Generated names require established freshness.

A guessed unusual prefix is not a hygiene proof.

## 82. Diagnostics

**[NORMATIVE ASSURANCE]**

Diagnostics are phase-specific.

Representative r3 diagnostics:

~~~text
PS_VERSION_MISMATCH
PS_UNSUPPORTED_FEATURE
PS_UNREGISTERED_EXCEPTION
PS_AMBIGUOUS_OWNERSHIP
PS_CALL_LINE_BREAK_BEFORE_PAREN
PS_EMPTY_CALL_REQUIRED_ARGUMENT
PS_CALL_EMPTY_ENTRY
PS_CALL_DUPLICATE_NAMED_ARGUMENT
PS_CALL_TUPLE_MIGRATION_REQUIRED
PS_BRACE_FIELD_COMMA_REQUIRED
PS_BRACE_TRAILING_FIELD_COMMA
PS_BRACE_UNEXPECTED_SEPARATOR
PS_PROFILE_SYNTAX_EXTENSION_FORBIDDEN
PS_PROFILE_SEMANTIC_IMPORT_REQUIRED
PS_CONTRACT_IMPLEMENTATION_IDENTITY_MISMATCH
PS_CONTRACT_SPEC_DEPENDENCY_CHANGED
PS_DTS_EXPORT_CONDITION_MISMATCH
PS_DTS_RUNTIME_TYPE_BRANCH_MISMATCH
PS_DTS_UNSUPPORTED_TYPE_OPERATOR
PS_NATIVE_ELABORATION
PS_UNRESOLVED_METAVARIABLE
PS_KERNEL_REJECTION
PS_ASSUMPTION_POLICY
PS_INCOMPLETE_PROOF
PS_MODULE_AMBIGUITY
PS_MISSING_DEPENDENCY
PS_RUNTIME_PRIMITIVE_UNSUPPORTED
PS_ARTIFACT_IDENTITY_MISMATCH
PS_RESOURCE_LIMIT
PS_CANCELLED
PS_INTERNAL_ERROR
~~~

A native diagnostic may be attached as a structured cause.

Internal error, resource exhaustion, cancellation, unknown solver result, or unsupported behavior never becomes accepted verification.

---

# Part XII — Elaboration and genuine admission

## 83. Elaboration

**[NORMATIVE ASSURANCE]**

Elaboration remains Lean-compatible and type-directed.

It handles:

- implicit insertion;
- instance synthesis;
- coercions;
- expected types;
- named/default/automatic parameters;
- dependent binder relationships;
- overloaded/notation meanings from the selected environment.

The frontend should not reimplement TypeScript overload semantics as a substitute.

## 84. Candidate declarations versus admitted declarations

**[NORMATIVE ASSURANCE]**

Elaboration produces candidate declarations.

Candidate declarations are not automatically trusted.

Genuine kernel admission checks the declaration under the selected logical environment.

Only after admission can the declaration become part of CheckedModule.

## 85. Admission invariants

**[NORMATIVE ASSURANCE]**

Release admission requires at least:

- no unresolved metavariables;
- exact environment identity;
- exact dependency identities;
- policy-compliant assumptions;
- transactional failure behavior;
- no caller-constructible checked flag;
- immutable/revalidated checked artifacts.

A failed module must not leak partial declarations into the accepted environment.

## 86. Axioms and assumptions

**[NORMATIVE ASSURANCE]**

Theorem assurance reports transitive assumption dependencies.

Classical/foundational assumptions are explicit policy inputs.

Foreign/runtime assumptions are reported separately from logical axioms.

A theorem about an external model is not proof that the external implementation satisfies the model.

---

# Part XIII — Erasure and executable semantics

## 87. Erasure

**[NORMATIVE ASSURANCE]**

Erasure occurs only after genuine logical admission.

Remove proof/type content only where irrelevance permits it.

Do not erase runtime-relevant data merely because its type mentions proofs.

## 88. RuntimeIR

**[NORMATIVE ASSURANCE]**

RuntimeIR is a target-independent executable semantic layer.

It must preserve source executable behavior before choosing JS/Wasm representations.

RuntimeIR should represent or reference:

- values;
- closures;
- constructors/tags;
- pattern matching;
- local bindings;
- recursive calls where supported;
- exact primitive operations;
- effect/application operations;
- foreign handles/adapters;
- source/declaration provenance required for evidence.

## 89. Primitive matrix

**[NORMATIVE ASSURANCE]**

Every target profile must have an explicit primitive matrix.

Each reachable primitive records:

~~~text
source declaration identity
RuntimeIR operation
target implementation
representation relation
edge-case semantics
external/runtime assumptions
evidence status
~~~

Unknown reachable primitive support rejects target generation.

Do not add a semantic fallback that quietly changes behavior.

---

# Part XIV — Backends and preservation

## 90. Preservation is a separate claim

**[NORMATIVE ASSURANCE]**

Source proof correctness does not imply backend correctness.

A backend claim states:

- source/RuntimeIR semantics;
- target semantics;
- representation relation;
- value relation;
- effect/trace relation;
- termination/resource relationship;
- assumptions.

## 91. Direct JavaScript

**[NORMATIVE ASSURANCE]**

Direct JS is a valid target route only under explicit preservation/validation evidence.

Important obligations include:

- Nat/Int exact arithmetic;
- string/Unicode behavior;
- constructor representation;
- closure calling convention;
- effect ordering;
- resource cleanup;
- async/cancellation adapter behavior;
- foreign boundary validation.

Using BigInt/Promise/object spread does not by itself prove correctness.

## 92. Direct Wasm

**[NORMATIVE ASSURANCE]**

Direct Wasm similarly requires explicit representation/ABI/preservation rules.

WASI/Component Model async func/future/stream can serve as target mechanisms for psc-app-v1, but do not define source semantics.

## 93. External compilers

**[NORMATIVE ASSURANCE]**

Using TypeScript/Rust/other external compilers for a route adds a preservation/toolchain assumption unless covered by evidence.

External compilation does not invalidate an already valid source theorem; it affects the executable-artifact assurance boundary.

## 94. Serialization and artifacts

**[NORMATIVE ASSURANCE]**

A proof about target AST does not automatically prove:

- serializer correctness;
- emitted bytes;
- linker behavior;
- bundler/minifier transforms;
- framework transforms;
- package resolution;
- deployed environment.

Evidence must bind the exact endpoint being claimed.

A hash proves byte identity, not semantic equivalence.

---

# Part XV — Semantic bundles and InterfaceIR transport

## 95. PSC Semantic Bundle v1

**[NORMATIVE ASSURANCE]**

A Standard semantic bundle records at least:

- schema version;
- logical module;
- source profile/source identity;
- Lean semantic pin;
- checker identity;
- module format;
- environment identity;
- Standard registry identity;
- declaration payload hash/size;
- dependency bundle identities;
- declaration identities;
- axiom dependencies;
- syntax/meta exports;
- host build effects;
- runtime assumptions;
- optional runtime exports;
- evidence status.

For Standard import:

~~~text
syntaxMetaExports = []
hostBuildEffects = []
~~~

The manifest is transport/evidence routing data, not proof authority.

## 96. InterfaceIR schema role

**[NORMATIVE ASSURANCE]**

InterfaceIR JSON-schema validity only establishes transport shape.

It does not establish:

- TypeScript declaration correctness;
- runtime implementation correctness;
- safe-adapter correctness;
- logical-model correspondence.

Those require separate checks/evidence.

---

# Part XVI — Formatting and tooling

## 97. Canonical formatter

**[NORMATIVE LANGUAGE]**

For ps-standard, canonical formatting must not change AST ownership.

Key rules:

- print owned calls without a gap before opening parenthesis;
- keep f() distinct from f(());
- print one tuple argument with extra grouping;
- keep generalized-field dot adjacent;
- structure/class fields use commas between fields;
- no trailing structure/class field comma;
- one constructor/match alternative per canonical multiline line;
- preserve native semicolon versus tactic combinator distinctions;
- no general declaration semicolon;
- preserve binding/source-map identity.

## 98. LSP

**[IMPLEMENTATION GUIDANCE]**

The Standard LSP can rely on a closed grammar/registry.

The Extensible LSP loads declared extension identity.

The LSP should expose:

- source profile;
- feature ownership;
- canonical lowering preview;
- native elaboration cause;
- assumption/evidence state;
- contract status;
- target/runtime support status.

---

# Part XVII — Versioning and compatibility

## 99. Edition/profile identity

**[NORMATIVE ASSURANCE]**

A source file is interpreted under an explicit grammar/profile identity.

The implementation MUST NOT guess an edition from source contents when different editions could assign different meanings.

## 100. Migration tools

**[NORMATIVE ASSURANCE]**

A migration tool MUST:

- parse the source under its declared source grammar first;
- transform the AST structurally;
- preserve binding identity, theorem statements, assumptions, comments/provenance, and nested native categories;
- emit the destination grammar explicitly;
- report semantic changes that cannot be preserved mechanically.

A formatter is not a migrator.

## 101. Compatibility boundaries

**[NORMATIVE ASSURANCE]**

A package compiled under a different grammar/profile MAY interoperate only through a supported canonical/semantic bundle or explicit source migration.

A package MUST NOT be silently downgraded to a weaker source profile.

## 102. Future language revisions

**[NORMATIVE ASSURANCE]**

A future revision that changes parser ownership, source meaning, contract semantics, runtime semantics, InterfaceIR interpretation, or assurance identity MUST use a new explicit version/profile identity and migration/conformance plan.


# Part XVIII — Evidence and release discipline

## 103. Acceptance result vocabulary

**[NORMATIVE ASSURANCE]**

At minimum distinguish:

~~~text
accepted
malformed-source
unsupported-feature
incompatible-environment
elaboration-rejected
kernel-rejected
proof-search-incomplete
resource-limit
cancelled
internal-error
~~~

No failure/unknown/exhausted state becomes success.

## 104. Evidence dimensions

**[NORMATIVE ASSURANCE]**

Keep separate:

~~~text
specified
parsed
elaborated
logically-admitted
contract-proved
termination-proved
source-correspondence
erasure-preserved
target-preserved
artifact-bound
runtime-assumed
oracle-tested
prototype-tested
human-studied
full-app-tested
~~~

No single verified=true field is sufficient.

## 105. Pre-stable / 1.0 gates

**[NORMATIVE ASSURANCE]**

Before stable/1.0, the relevant evidence program includes:

- TypeScript/Lean usability study;
- frontend call/brace ownership and lowering proof/refinement;
- backend preservation slice;
- primitive/runtime conformance matrix;
- psc-app-v1 cross-target conformance;
- InterfaceIR real-package corpus;
- complete CLI/service/browser/npm reference applications;
- Standard registration-closure/LSP/formatter conformance;
- contract-core implementation/evidence tests;
- exact artifact/release binding.

The accepted r3 design exists before those gates complete.

The gates are evidence requirements, not permission to fabricate results.

---

# Part XIX — AI compiler implementation contract

## 106. Instructions to an AI implementing the compiler

**[IMPLEMENTATION GUIDANCE]**

An AI/compiler agent MUST treat this section as an implementation discipline, not as permission to invent missing language semantics.

### 106.1 Do not change the language to make implementation easier

If a source case is unclear:

1. consult the relevant section of this document;
2. identify the selected source profile, compiler capability profile, Lean compatibility profile, runtime profile, and extension set;
3. use the pinned Lean 4.34 implementation only as the semantic oracle for the native Lean constructs explicitly included by those profiles;
4. if the capability belongs to a library/Standard prover/controlled extension/post-PSC2 layer, do not move it into the compiler core merely for convenience;
5. if still unsupported or genuinely unspecified, reject or raise a specification issue.

Do not silently choose a JavaScript/TypeScript interpretation.

### 106.2 Implement the smallest semantic slice first

Recommended **PSC2 core-compiler closure** order:

1. immutable source/profile/module identity;
2. lexer/source spans;
3. parser ownership framework;
4. declarations, binders, calls, structures/inductives/classes;
5. bounded `psc2-pattern-v1`;
6. deterministic names/modules/imports/scopes;
7. canonical lowering;
8. Lean-compatible Meta/elaboration for the advertised subset;
9. genuine admission and CheckedModule;
10. bounded theorem/proof block support needed by compiler/library source;
11. erasure and pure RuntimeIR;
12. primitive/runtime matrix;
13. direct JavaScript pure/core execution slice;
14. Standard-profile registry enforcement;
15. source/module/package fixed-point infrastructure.

Then grow above that closure according to ownership:

~~~text
STANDARD_LIBRARY / STANDARD_PROVER
    -> richer proofs, data libraries, contracts, utilities

POST_PSC2 P3/P4
    -> Meta/tactic service API, reflection, controlled plugins

POST_PSC2 P5
    -> InterfaceIR and broad generated FFI

POST_PSC2 P6
    -> App/Fiber/Resource/Stream runtime implementations and conformance

additional backends
    -> Rust / direct Wasm over the same checked RuntimeIR
~~~

Do not make a post-PSC2/library/plugin capability a prerequisite for the first compiler generation that is supposed to create that capability unless an explicit bootstrap host/profile is recorded.

### 106.3 Maintain a feature ledger

For each feature, maintain:

~~~text
featureId
specVersion
sourceProfile
compilerCapabilityProfile
leanCompatibilityProfile
featureOwner
parserCategory
discriminator
ASTNode
loweringRule
canonicalTarget
diagnostics
formatterRule
migrationRule
elaborationDependencies
runtimeDependencies
bootstrapRequirement
extensionPackageOrPlugin
formalEvidence
testEvidence
implementationStatus
~~~

The ledger must distinguish specified from implemented/proved.

### 106.4 Keep unsupported paths fail-closed

If a required feature, primitive, target operation, syntax registration, semantic bundle, or InterfaceIR construct is unknown:

~~~text
reject
~~~

Do not:

- use another compiler silently;
- skip proof checking;
- insert any;
- approximate a target primitive;
- reuse a stale cache;
- downgrade a profile;
- ignore a dependency;
- turn exhaustion into success.

### 106.5 Preserve exact provenance

Every accepted declaration/artifact should be traceable to:

- source bytes;
- source profile;
- grammar/registry identity;
- canonical lowering identity;
- environment;
- checker;
- assumptions;
- target/runtime identities where relevant.

### 106.6 Separate frontend reference from production implementation

A reference frontend/oracle may use official Lean.

A standalone frontend can be implemented independently.

Agreement on tests is not a proof of equivalence.

Keep explicit evidence status for reference/production correspondence.

### 106.7 Never patch generated semantic output to fake source support

Fix the parser/lowerer/semantic pass that owns the behavior.

Generated canonical Lean/JS/Wasm is evidence/debug output, not the language source of truth.

---

# Part XX — Compiler data model recommendation

## 107. Suggested immutable identities

**[IMPLEMENTATION GUIDANCE]**

Useful identities include:

~~~text
SourceId
ModuleId
GrammarId
ProfileId
RegistryClosureId
EnvironmentId
DeclarationId
SpecificationId
CheckedModuleId
RuntimeIRId
TargetIRId
ArtifactId
SemanticBundleId
InterfaceIRBindingId
AxiomPolicyId
RuntimeProfileId
~~~

Use exact hashes/revisions where appropriate.

## 108. Suggested result types

**[IMPLEMENTATION GUIDANCE]**

Prefer explicit typed outcomes such as:

~~~text
ParseResult
ElaborationResult
AdmissionResult
ContractResult
RuntimeLoweringResult
TargetLoweringResult
ArtifactValidationResult
~~~

Do not encode all failure modes as generic exceptions.

## 109. CheckedModule

**[IMPLEMENTATION GUIDANCE]**

CheckedModule should be constructible only through genuine admission or a sound recheck/import protocol.

A public caller must not be able to fabricate:

~~~text
{ checked: true }
~~~

and thereby authorize declarations.

## 110. Cache keys

**[IMPLEMENTATION GUIDANCE]**

Caches must include all inputs that can change the result.

Examples:

### Parse cache

~~~text
source bytes
grammar revision
source profile
registration-closure identity
lexer/parser revision
~~~

### Elaboration cache

~~~text
parsed AST identity
imports/declarations
options
instances
semantic registrations
transparency/context
universe state
profile/environment identity
~~~

### Proof/admission cache

~~~text
candidate declaration
environment
axiom policy
kernel/checker identity
~~~

### Backend cache

~~~text
CheckedModule/RuntimeIR identity
target profile
primitive manifest
backend revision/options
runtime helper identities
~~~

A cache key that omits a semantic input is unsound.

---

# Part XXI — Normative feature summary

## 111. Active r3 feature families

**[NORMATIVE LANGUAGE]**

| ID | Class | Purpose |
|---|---|---|
| L-CORE-LEAN | L | inherited permitted native categories |
| D-CONST-ALIAS | D | parameterless native def alias |
| D-FUNCTION-ALIAS-R3 | D | function declaration alias |
| D-FUNCTION-UNIT-R3 | D | zero-source-argument function sugar |
| D-EXPLICIT-PARAMS | D | comma-separated explicit binder groups |
| D-NAMED-CALL | D | native named argument inside r3 call |
| D-TRAILING-COMMA-CALL | D | trailing comma in nonempty call |
| D-TRAILING-COMMA-PARAMS | D | trailing comma in explicit parameter group |
| E-CALL-PARENS-R3 | E | whitespace-insensitive parenthesized call under CallGap |
| E-EMPTY-CALL-R3 | E | zero-source-argument invocation/default completion |
| E-IF-BRACE | E | one-term braced conditional |
| E-STRUCT-BODY-R3 | E | structural structure field sequence |
| E-CLASS-BODY-R3 | E | structural class field sequence |
| E-INDUCTIVE-BODY-R3 | E | structural constructor sequence |
| E-MATCH-BODY-R3 | E | structural match alternative sequence |
| E-INSTANCE-BODY-R3 | E | structural instance initializer sequence |
| E-WHERE-BODY-R3 | E | structural local where declaration sequence |
| S-PURE-CONTRACT-R3 | semantic | stable requires/ensures pure contract core |
| P-STANDARD-R3 | profile | closed Standard source environment |
| P-LEAN-EXTENSIBLE-R3 | profile | declared extensible source environment |
| C-PSC2-COMPILER-V1 | compiler profile | required first PSC2 compiler-owned capability set |
| D-PSC2-STANDARD-V1 | distribution profile | compiler + selected Standard library/prover/extension capabilities |
| L-LEAN-SUBSET-PSC2-V1 | compatibility profile | bounded native Lean frontend subset |
| PATTERN-PSC2-V1 | compiler profile | bounded required PSC2 pattern compiler |
| INTERFACEIR-V1 | interop | versioned npm/TypeScript boundary |

This table lists current features only. Historical feature identities are not part of the language specification.

---

# Part XXII — Canonical examples

## 112. Values and functions

**[INFORMATIVE]**

~~~proofscript
const answer: Nat := 42

function add(x: Nat, y: Nat): Nat :=
  x + y

function greet(name: String := "world"): String :=
  "Hello, " ++ name

function now(): Time :=
  ...
~~~

Calls:

~~~proofscript
add(1, 2)
add (1, 2)      -- same r3 meaning
greet()         -- default completion
now()           -- hidden optional Unit default
~~~

Tuple:

~~~proofscript
tupled((1, 2))
~~~

## 113. Structures

**[INFORMATIVE]**

~~~proofscript
structure User where {
  id: Nat,
  name: String,
  active: Bool
}

function activate(user: User): User :=
  { user with active := true }
~~~

No trailing field comma.

## 114. Inductive and match

**[INFORMATIVE]**

~~~proofscript
inductive LoadState(ε: Type, α: Type) where {
  | idle
  | loading(requestId: Nat)
  | ready(requestId: Nat, value: α)
  | failed(requestId: Nat, error: ε)
}

function getOrElse(value: Option Nat, fallback: Nat): Nat :=
  match value with {
    | .none => fallback
    | .some x => x
  }
~~~

Patterns remain native.

## 115. Class and instance

**[INFORMATIVE]**

~~~proofscript
class Sized(α: Type) where {
  size: α -> Nat
}

instance : Sized String where {
  size(s: String): Nat := s.length;
}
~~~

## 116. Contract

**[INFORMATIVE]**

~~~proofscript
function debit(balance: Nat, amount: Nat): Except String Nat
  requires amount <= balance
  ensures result =>
    match result with {
      | .ok next => next = balance - amount
      | .error _ => False
    }
:=
  .ok(balance - amount)
~~~

The contract theorem must bind the actual admitted debit implementation.

## 117. Theorem

**[INFORMATIVE]**

~~~proofscript
theorem addZero(n: Nat): add(n, 0) = n := by {
  simp [add]
}
~~~

Tactic syntax/semantics remain selected native/Standard-profile behavior.

---

# Part XXIII — Non-goals and explicit exclusions

## 118. Base r3 does not add

**[INFORMATIVE]**

- TypeScript arrow lambdas;
- JavaScript truthiness;
- implicit null/undefined;
- native any;
- optional chaining;
- general JS statement blocks;
- automatic semicolon insertion;
- braced namespaces;
- async/await/using keywords;
- Promise as native task semantics;
- automatic JSX;
- arbitrary dependency parser mutation in Standard;
- full Lean 4 parser/macro/elaborator/metaprogramming parity as a PSC2 compiler requirement;
- trust in .d.ts as runtime validation;
- hidden proof/verification fallbacks.

## 119. Future work does not silently become current syntax

**[INFORMATIVE]**

The following can be researched later without being base r3 now:

- richer stateful contract syntax;
- loop invariant sugar;
- async contract syntax;
- UI/JSX dialects;
- new application syntax over psc-app-v1;
- larger InterfaceIR support;
- additional Standard tactics/notation.

Every addition requires a new explicit registry/spec/profile revision.

---

# Part XXIV — Evidence status of this reference

## 120. What this document establishes

**[INFORMATIVE]**

This document establishes:

- accepted r3 design;
- exact separation of language edition, PSC2 compiler capability, bounded Lean compatibility, library/extension ownership, and post-PSC2 platform work;
- exact source/profile rules at specification level;
- exact call/brace/default behavior at specification level;
- complete standalone language authority;
- compiler phase/invariant requirements;
- stable pure contract semantics;
- application semantic architecture;
- InterfaceIR identity/interop architecture;
- migration/conformance/evidence requirements.

## 121. What this document does not establish

**[INFORMATIVE]**

It does not establish:

- production parser correctness;
- production lowerer correctness;
- standalone elaborator equivalence;
- kernel implementation correctness;
- backend preservation;
- completed App runtime;
- completed InterfaceIR importer/exporter;
- completed reference applications;
- human usability results;
- stable/1.0 freeze.

Those require their own evidence.

---

# Part XXV — Parser algorithm and grammar summary

## 122. Completed-head postfix parsing

**[NORMATIVE LANGUAGE]**

Parenthesized call syntax is a postfix surface operation over a completed callable term.

A conforming parser behaves as if it used the following algorithm:

~~~text
parseCallableTerm(category, input, env):
    head := parseCompletedHead(category, input, env)

    loop:
        if next input is CallGap followed by "(":
            head := parseOwnedParenthesizedCallSuffix(head)
            continue

        if the selected native/profile grammar owns another compatible postfix:
            head := parseCompatibleNativePostfix(head)
            continue

        break

    return head
~~~

The owned call suffix is:

~~~text
"(" ")"               -> PsEmptyCall(head)
"(" arguments ")"     -> PsParenthesizedCall(head, arguments)
~~~

This algorithm defines ownership/grouping, not a required parser implementation technology.

## 123. Core owned grammar summary

**[NORMATIVE LANGUAGE]**

~~~ebnf
ExplicitGroup :=
  "(" ExplicitEntry ("," ExplicitEntry)* ","? ")"

ExplicitEntry :=
  BinderIdent ":" PSTerm DefaultSuffix?

CallArguments :=
  CallArgument ("," CallArgument)* ","?

CallArgument :=
    NamedCallArgument
  | PSTerm

NamedCallArgument :=
  Ident ":=" PSTerm

StructBody :=
  "{" (StructField ("," StructField)*)? "}"

ClassBody :=
  "{" (ClassField ("," ClassField)*)? "}"

InductiveBody :=
  "{" ("|" ConstructorBody)* "}"

MatchBody :=
  "{" ("|" PatternGroup "=>" PSTerm)+ "}"

InstanceBody :=
  "{" (InstanceField (";" InstanceField)* ";"?)? "}"

WhereBody :=
  "{" WhereField (";" WhereField)* ";"? "}"

BracedIf :=
  "if" "(" PSTerm ")" "{" PSTerm "}"
  "else" "{" PSTerm "}"
~~~

A structure/class trailing field comma is rejected.

# Part XXVI — Machine-readable mirror policy

## 124. Generated mirror authority

**[NORMATIVE ASSURANCE]**

Any JSON registry or schema distributed with an implementation is a **generated mirror** of this prose specification unless a future version explicitly says otherwise.

Rules:

1. the prose sections in this document are normative;
2. generated JSON MUST carry the same grammar/profile/schema version;
3. the generator SHOULD emit a source-section identifier for every generated rule;
4. a mismatch between generated JSON and this prose is a specification/build error;
5. generated JSON MUST NOT override, weaken, or silently extend the prose;
6. release tooling SHOULD regenerate mirrors from a structured source representation and compare them byte-for-byte to checked-in artifacts;
7. manually editing a generated mirror without changing the normative source does not change the language.

Representative mirror:

~~~json
{
  "grammar": "ps-0.9-r3",
  "semanticPin": "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b",
  "profiles": ["ps-standard", "ps-lean-extensible"],
  "call": {
    "gapAllowsBareLineBreak": false,
    "emptyCall": "native-ellipsis-plus-required-explicit-rejection",
    "tupleRequiresExtraGrouping": true
  },
  "structureFields": {
    "separator": ",",
    "trailingComma": false
  },
  "application": {
    "app": "cold",
    "fiber": "started",
    "stream": "cold-reusable-per-subscription"
  }
}
~~~

---

# Part XXVII — Final implementation directive

## 125. Single-source compiler-design rule

**[IMPLEMENTATION GUIDANCE]**

For an AI or human designing the ProofScript compiler:

1. implement only behavior specified here or inherited directly from the pinned Lean 4.34.0 semantic environment as this document permits;
2. preserve phase separation;
3. preserve exact source/environment identity;
4. use category-aware parsing and structural AST lowering;
5. delegate Lean-compatible semantics to compatible elaboration/admission rather than inventing TypeScript semantics;
6. keep Standard closed and Extensible explicit;
7. keep proofs, compiler correctness, runtime preservation, and foreign assumptions separate;
8. fail closed on unsupported or unknown behavior;
9. bind evidence to exact artifacts;
10. never weaken a specification or assumption policy merely to make a program compile.

The intended result is not a JavaScript language with optional proofs.

It is:

> a Lean-compatible dependent programming and theorem-proving language with a regular application-facing syntax, a closed Standard profile, explicit extensibility, stable specifications, explicit application effects/resources/async semantics, and inspectable npm/JS/Wasm boundaries.

That is the ProofScript v0.9.0 r3 compiler contract.
