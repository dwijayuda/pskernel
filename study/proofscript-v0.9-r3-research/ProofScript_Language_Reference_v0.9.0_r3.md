# The ProofScript Language Reference v0.9.0 r3

Status: **accepted r3 language/design baseline; documentation/specification scope; not an implementation release or proof of soundness**

Grammar identity:

~~~text
ps-0.9-r3
~~~

Semantic pin:

~~~text
Lean 4.34.0
293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
~~~

## 0. Normative authority and completeness

r3 is a **complete normative delta** over one exact r2 artifact rather than a second approximate transcription of every unchanged r2 rule.

Inherited r2 authority:

~~~text
The ProofScript Language Reference v0.9.0
draft revision 2 / ps-0.9-r2
SHA-256:
d29c0b2d5780e6cdb08a4c9ac00cc7442a64b1c8133b51c5f0c0e9a343b11b8d
~~~

Authority order:

1. this accepted r3 reference;
2. R3-AUTHORITY-AND-DELTA.md and R3-R2-INHERITANCE-MATRIX.md;
3. R3-GRAMMAR-AND-FEATURE-REGISTRY.md plus the machine-readable registries/schemas for the domains they define;
4. accepted r3 topic documents (profiles, contracts, application semantics, interop, migration, conformance);
5. the exact vendored r2 artifact identified above;
6. pinned Lean 4.34 source/environment for inherited Lean syntax and semantics;
7. tutorials/examples/research rationale.

If an r2 rule is not explicitly superseded, retired, restricted, or reclassified by r3, it remains normative unchanged.

Therefore r3 retains the detailed r2 rules for lexical syntax, type theory, primitives, modules, compiler phases, admission, erasure, backends, diagnostics, evidence manifests, artifact binding, and release snapshots except where this reference explicitly changes them.

## 1. Design commitment

ProofScript remains a general-purpose programming and theorem-proving language whose logical meaning is obtained through Lean-compatible elaboration and genuine kernel admission.

r3 changes the application-facing surface and platform profile, not the logical foundation.

The design goal is:

> make ProofScript predictable and comfortable for TypeScript developers while preserving Lean semantics and ProofScript theorem-proving and verification strengths.

The base continues to reject:

- JavaScript truthiness;
- implicit null/undefined;
- native any;
- prototype inheritance as native object semantics;
- unchecked casts as proof;
- hidden proof/runtime authority;
- JavaScript ASI;
- universal JavaScript statement blocks.

## 2. Central semantic relationship

For source p in environment E, the intended relationship remains conceptually:

~~~text
parsePS_r3(E, p) = surface
canonicalize_r3(E, surface) = canonicalLeanSyntax
meaningPS_r3(E, p) =
  meaningLean434(lowerEnv(E), canonicalLeanSyntax)
~~~

The relation is partial: malformed, unsupported, profile-incompatible, or semantically invalid source rejects.

The environment includes:

- imports;
- logical module identities;
- source profile;
- exact parser/notation/tactic registrations;
- options;
- instances;
- declaration dependencies;
- axiom policy;
- semantic bundle identities.

This equation defines intended meaning. It does not prove that a production parser/lowerer/checker implements it.

## 3. Source kinds

### 3.1 .ps

A .ps file uses the selected ProofScript edition/profile.

It can contain inherited Lean forms permitted by that profile plus registered r3 owned syntax.

### 3.2 .lean

A .lean file is genuine native Lean syntax.

ProofScript-only productions are not injected into its parser.

A standalone PSC implementation may support only an explicit subset; unsupported native Lean is rejected as unsupported rather than reinterpreted.

### 3.3 optional extension sources

A .psx or future dialect requires its own explicit grammar/profile identity.

It does not automatically inherit base verification or UI semantics.

## 4. Source profiles

r3 has two .ps source profiles over the same logical foundation.

### 4.1 ps-standard

Purpose:

- applications;
- npm packages;
- predictable LSP/formatter;
- AI-generated code;
- reproducible builds.

It has a closed/versioned syntax and fixed meta/tactic registration environment.

Ordinary dependencies cannot silently mutate the parser.

Exact profile rules are in:

~~~text
18-PS-STANDARD-REGISTRY.md
ps-standard-registry.json
~~~

### 4.2 ps-lean-extensible

Purpose:

- theorem proving;
- custom notation/macros/tactics;
- elaborators;
- Meta programming;
- Lean compatibility/research.

Every extension identity, load order, option, and host permission is part of the environment identity.

### 4.3 semantic imports across profiles

Standard may consume checked declarations/runtime exports from an Extensible package through the semantic-bundle format.

It does not import the producer's syntax/meta side effects.

Normative format:

~~~text
SEMANTIC-BUNDLE-v1.md
SEMANTIC-BUNDLE-v1.schema.json
~~~

## 5. Definitions and declaration aliases

Native def remains the general definition form.

function is a declaration-head alias for a parameterized native definition.

const is retained in r3 as a top-level/namespace parameterless native-definition alias.

const does not imply:

- JavaScript binding semantics;
- deep freezing;
- compile-time evaluation;
- local const syntax.

Local immutable bindings remain native let.

No ProofScript-wide declaration semicolon is introduced.

## 6. Zero-source-argument function sugar

r3 accepts:

~~~proofscript
function now(): Time :=
  ...
~~~

It lowers to a native function whose hidden Unit parameter is optional with default Unit:

~~~lean
def now (_ : Unit := ()) : Time :=
  ...
~~~

This preserves Lean's unary/curried core function model and preserves a function value.

Native def receives no such hidden binder automatically.

Implicit/instance binders may precede the empty explicit group according to the exact grammar.

The empty explicit group cannot be mixed with an ordinary explicit group in the same function header.

## 7. Parenthesized calls

r3 replaces adjacency-sensitive r2 D-CALL with E-CALL-PARENS-R3.

These have the same r3 .ps meaning:

~~~proofscript
f(x)
f (x)
~~~

and:

~~~proofscript
f(x, y)
f (x, y)
~~~

Both multi-argument forms denote one high-level Lean application with ordered curried arguments.

One tuple argument requires explicit extra grouping:

~~~proofscript
f((x, y))
~~~

Native .lean behavior is unchanged.

### 7.1 CallGap

Between a completed callable head and the opening parenthesis, r3 admits:

- inherited horizontal Lean space trivia (ordinary spaces under the pinned lexer; r3 does not add tab-as-whitespace);
- Lean comments as lexical trivia nodes.

A bare source line terminator outside a comment is not CallGap.

Thus:

~~~proofscript
f /- note -/ (x)
~~~

is a call, while:

~~~proofscript
f
(x)
~~~

is not E-CALL-PARENS-R3.

The canonical formatter emits:

~~~proofscript
f(x)
~~~

A block comment is treated as one trivia node; physical line breaks inside that comment do not create a bare line terminator between head and parenthesis.

### 7.2 Empty call: defaults versus required arguments

r3 defines:

~~~proofscript
f()
~~~

as:

> zero source-supplied explicit arguments, completing only parameters that are allowed to be omitted.

Canonical high-level Lean request:

~~~lean
f ..
~~~

The pinned Lean application elaborator performs its native insertion of:

- implicit parameters;
- instance implicit parameters;
- strict implicits as applicable;
- optional/default parameters;
- automatic parameters.

r3 then applies an acceptance predicate:

- every omitted explicit parameter must be native optional/automatic;
- an ordinary required explicit parameter may not be silently filled merely because ellipsis created a metavariable;
- unresolved metavariables remain rejection conditions.

Therefore:

~~~proofscript
function now(): Time := ...
now()                    -- hidden Unit default is inserted

function greet(name: String := "world"): String := ...
greet()                  -- declared default is inserted

function add(x: Nat): Nat := x + 1
add()                    -- reject: required explicit argument omitted
~~~

No JavaScript undefined value is introduced.

To obtain a function value, write the function value itself rather than using an empty call.

### 7.3 Nonempty calls

Nonempty parenthesized calls lower to one native high-level application syntax object.

Named arguments use:

~~~proofscript
connect(host, timeout := 5000)
~~~

and lower to native named-argument syntax.

A trailing comma remains allowed in a nonempty owned call:

~~~proofscript
f(x, y,)
~~~

Empty/doubled entries reject.

### 7.4 Field notation

r3 changes spacing around the call parenthesis, not spacing around dot notation.

Accepted inherited field notation:

~~~proofscript
users.map(render)
~~~

r3 does not add:

~~~proofscript
users .map(render)
~~~

Generalized field receiver placement remains type-directed according to pinned Lean elaboration.

### 7.5 Patterns

Parenthesized-call syntax is term-only.

Pattern syntax remains native:

~~~proofscript
| .some x => ...
~~~

not:

~~~proofscript
| .some(x) => ...
~~~

## 8. Explicit parameter groups

Registered function/header explicit groups use complete comma-separated binders:

~~~proofscript
function select(n: Nat, i: Fin n): Fin n := i
~~~

Each comma entry has its own name/type.

A trailing comma is allowed in a nonempty explicit parameter group:

~~~proofscript
function select(n: Nat, i: Fin n,): Fin n := i
~~~

This rule is category-specific and does not imply trailing commas everywhere.

Native implicit/strict-implicit/instance binders retain native meaning.

## 9. Structural braces

When an r3-owned construct uses braces, the braces and explicit category separator/marker determine the **outer** member sequence.

Indentation inside that owned outer sequence is formatting, not a second hidden member-boundary system.

Nested inherited child syntax may retain native layout.

### 9.1 structures/classes

Canonical Standard presentation:

~~~proofscript
structure User where {
  name: String,
  active: Bool
}

class Sized(α: Type) where {
  size: α -> Nat
}
~~~

Commas appear between fields.

A trailing field comma is rejected.

Each field is a lifted native structure/class field declaration, so dependent fields, defaults, attributes, parents, documentation, and other supported native field behavior remain governed by the pinned grammar/elaborator.

### 9.2 inductives

~~~proofscript
inductive State(α: Type) where {
  | idle
  | ready(value: α)
}
~~~

The leading bar marks constructor boundaries.

No constructor comma/semicolon terminator is added.

### 9.3 match

~~~proofscript
match value with {
  | .none => fallback
  | .some x => x
}
~~~

The leading bar marks alternatives.

Patterns remain native; each RHS is one term.

### 9.4 instances

Brace-mode instance fields use the native semicolon-sequence role explicitly.

Semicolons belong to the instance initializer sequence, not the outer declaration.

### 9.5 local where

Brace-mode local declarations use their native local-declaration semicolon sequence.

At least one local declaration is required.

### 9.6 braced if

~~~proofscript
if (condition) { thenTerm } else { elseTerm }
~~~

Each branch is exactly one term.

This is not a JavaScript statement block.

### 9.7 do and tactics

Native do and tactic sequencing remain native/profile-inherited.

r3 structural-brace rules do not reinterpret their inner separators.

Exact grammar:

~~~text
R3-GRAMMAR-AND-FEATURE-REGISTRY.md
FEATURE-REGISTRY-r3.json
~~~

## 10. Lambdas, equality and logical vocabulary

r3 retains:

~~~proofscript
fun x => ...
:=
=
==
Prop
Type
Sort
theorem
by
where
~~~

No base TypeScript arrow-lambda syntax is added.

Definitional equality, propositional equality, and Boolean comparison remain distinct.

## 11. Exact inherited logical/type-system semantics

Unless explicitly overridden, r3 inherits r2/pinned Lean rules for:

- universes;
- dependent functions;
- proof irrelevance;
- inductive families/recursors;
- quotients;
- coercions;
- typeclass synthesis;
- implicit/strict-implicit/instance binders;
- optional/automatic parameters;
- structures and dependent fields;
- pattern matching and motives;
- recursive, well-founded, partial, unsafe, fixpoint/coinductive facilities;
- native theorem/tactic infrastructure.

r3 defines no competing approximate type system.

## 12. Stable contract core

Stable r3 contract semantics is:

~~~text
psc-contract-core-v1
~~~

Normative base source clauses:

~~~text
requires <Prop-term>
ensures result => <Prop-term>
~~~

For a pure total function:

~~~proofscript
function withdraw(balance: Nat, amount: Nat): Nat
  requires amount <= balance
  ensures result => result = balance - amount
:=
  balance - amount
~~~

accepted evidence must establish the normalized theorem about the actual accepted implementation.

Multiple clauses conjoin according to the contract core.

Dedicated success/error sugar, loop invariant sugar, old-state syntax, assert syntax, decreasing syntax, and state/effect clause syntax are not implicitly stable merely because the concepts are discussed.

Outcome-sensitive properties can use an ordinary match over the result.

The normalized contract model also carries:

- implementation identity;
- semantic dependency closure;
- axiom policy;
- termination class;
- effect frame;
- read frame;
- write frame;
- program-logic identity.

Pure functions have empty effect/read/write frames.

Higher-order callable contracts use generic logical relations such as:

~~~text
callRequires
callEnsures
callEffects
callReads
callWrites
~~~

without adding a second kernel theory.

Normative details:

~~~text
07-CONTRACTS-AND-SPECIFICATIONS.md
~~~

Experimental Lean intrinsic verification is compatibility/oracle machinery, not PSC contract semantics.

## 13. Application semantics

Standard application semantic profile:

~~~text
psc-app-v1
~~~

Conceptual library types:

~~~text
App Caps E A
Exit E A
Fiber Caps E A
Resource Caps E A
Stream Caps E A
~~~

### 13.1 App

App is **cold**.

Constructing an App value starts no application/foreign effect.

Root run or scoped fork starts execution.

### 13.2 Exit versus RuntimeFault

Typed application completion:

~~~text
success A
failure E
cancelled CancelReason
~~~

RuntimeFault/resource-limit/host-termination outcomes live outside the ordinary typed E channel.

Ordinary typed catch does not silently catch arbitrary host/runtime faults.

### 13.3 capabilities

Caps is an explicit local upper bound on application capabilities.

Package/runtime manifests must agree with the type-level/equivalent capability model.

Hidden target globals do not expand Caps.

### 13.4 Fiber

Fiber is hot/started.

Fibers are structured/scoped by default.

Scope exit cancels unfinished children, waits for required terminal/cleanup behavior, and does not silently orphan children.

Detach is explicit.

### 13.5 cancellation

Cancellation request is not terminal completion.

Completion versus cancellation is decided by the modeled scheduler/trace relation.

### 13.6 Resource

Deterministic cleanup is not garbage collection.

Once required cleanup begins, ordinary cooperative cancellation is shielded/masked until cleanup reaches a terminal result, except explicit fatal host/resource-limit outcomes.

Body and cleanup failures are not silently collapsed.

### 13.7 Stream

Stream is cold until subscribed/consumed.

Its model distinguishes items, normal end, typed failure, cancellation, runtime fault reporting, and backpressure/demand.

### 13.8 native IO and Task

Native Lean IO/Task remain inherited low-level/native abstractions.

Portable Standard application APIs normally expose App/Fiber/Resource/Stream through runtime adapters.

Low-level adapters or Extensible code may use native IO/Task under explicit profiles.

### 13.9 target async primitives

JavaScript Promise/AbortController and WASI 0.3 async func/future/stream are target adapter mechanisms.

They do not define PSC source semantics.

Normative details:

~~~text
08-APPLICATION-EFFECTS-ASYNC-RESOURCES.md
~~~

No async/await/using syntax is added in base r3.

## 14. npm / TypeScript interoperability

Interop identity:

~~~text
psc-interface-ir-v1
psc-node-exports-v1
~~~

Pipeline:

~~~text
npm package + package exports + declaration files
                    |
                    v
             untrusted reader
                    |
                    v
              InterfaceIR v1
              /     |      \
           raw     safe     spec
~~~

A declaration file is not runtime validation and not proof.

### 14.1 binding identity

At minimum bind:

- package name/version;
- package.json SHA-256;
- install/lock identity;
- export subpath;
- runtime target/profile;
- module-resolution profile;
- ordered runtime condition trace;
- selected runtime entry path/hash;
- declaration-resolution trace;
- selected declaration entry path/hash;
- TypeScript declaration/profile version;
- InterfaceIR schema version.

### 14.2 raw/safe/spec

Raw layer preserves foreign identity/dynamics.

Safe layer validates/converts values and manages receiver/callback/resource/async semantics.

Specification layer optionally provides logical models, without pretending the foreign package implements them automatically.

### 14.3 dynamic/presence values

No hidden native any.

Preserve missing/undefined/null/value where relevant and require an explicit adapter mapping.

### 14.4 TypeScript advanced types

Simple generics/data/finite unions can map directly where justified.

Conditional/mapped/template-literal/keyof/indexed-access forms can be normalized by a bounded untrusted import phase where supported.

Unsupported forms reject rather than degrade to any.

Global/module augmentation and non-normalizable declaration merging are unsupported in Standard v1 unless explicitly pre-normalized by a named import profile.

### 14.5 exact formats

Normative documents:

~~~text
INTERFACEIR-v1.md
INTERFACEIR-v1.schema.json
~~~

## 15. Source/module identity

r3 inherits r2's source-identity rules:

- one exact authoritative source snapshot per logical module;
- explicit selection if both M.ps and M.lean are present;
- generated canonical .lean is not fallback source;
- no stale sibling, branch, or host-installed package fallback;
- generated inputs record generator/source provenance;
- release evidence binds the bytes actually checked.

Commands are processed in declared environment order.

Imports, options, instances, syntax registrations, and semantic bundle identities contribute to environment identity.

## 16. Standard semantic bundles

Standard semantic import uses:

~~~text
psc-semantic-bundle-v1
~~~

A bundle carries:

- Lean pin;
- logical module;
- declaration payload identity/module-format version;
- dependencies;
- assumptions;
- source/profile provenance;
- optional runtime exports.

For Standard import these must be empty:

~~~text
syntaxEffects
metaRegistrationEffects
hostBuildEffects
~~~

The importer rechecks/reconstructs declarations or consumes them through an explicit sound evidence protocol.

Normative schema:

~~~text
19-SEMANTIC-BUNDLE-FORMAT.md
semantic-bundle.schema.json
~~~

## 17. Primitive and data semantics

r3 inherits the exact r2/pinned primitive contracts.

Important consequences include:

### 17.1 Nat

Ordinary Nat arithmetic is exact over nonnegative integers.

Nat subtraction truncates at zero.

Division/remainder, including zero-divisor behavior, use the exact selected native declarations.

### 17.2 Int

Ordinary selected Int division/remainder use the pinned Lean semantics.

A target's native signed division is not assumed equivalent.

### 17.3 fixed-width/target-word types

Widths, overflow/wrapping/checking, shifts, conversions, and target-word width are target-profile obligations.

### 17.4 floating point

Floating semantics are not mathematical real arithmetic and retain selected rounding/NaN/infinity/signed-zero/platform obligations.

### 17.5 text/bytes

Char/String/ByteArray retain pinned native semantics.

JS UTF-16 indexing or another target representation does not define PSC String semantics.

### 17.6 collections

List, Array, Option, products/sums, subtype, Fin, maps, iterators, and other native declarations remain distinct.

A backend cannot substitute a convenient target container when its observable operations differ.

### 17.7 primitive matrix

Every executable profile requires an explicit reachable-primitive matrix.

Missing faithful primitive support rejects the target build.

## 18. Partiality, unsafe, noncomputability and runtime replacements

r3 inherits r2 distinctions among:

- total recursive definitions;
- well-founded recursion;
- partial definitions;
- unsafe definitions;
- noncomputable definitions;
- runtime/external implementations.

Kernel admission of a logical declaration does not prove its separate unsafe/runtime replacement preserves behavior.

An executable target reaching an unsupported noncomputable or unassured runtime realization rejects the stronger executable claim.

## 19. Proofs, axioms and assumptions

Proofs are admitted terms under the selected theory/policy.

Boolean computation is not automatically proposition evidence.

Axiom policy records exact permitted assumptions and transitive dependencies.

Unresolved holes, unknown solver outcomes, resource exhaustion, or policy-disallowed assumptions do not become strict accepted evidence.

A theorem about an external model does not itself prove that the external service implements the model.

## 20. Compiler and assurance pipeline

The inherited/r3 pipeline remains:

~~~text
exact source + edition/profile/environment
 -> category-aware parsing
 -> owned surface AST + provenance
 -> canonicalization/lowering
 -> Lean-compatible elaboration
 -> candidate declarations
 -> genuine kernel admission
 -> CheckedModule
 -> relevance/erasure/runtime lowering
 -> RuntimeIR
 -> target AST/IR
 -> serializer
 -> exact target bytes
 -> link/bundle/package/deployment
~~~

Phase boundaries are not interchangeable evidence.

In particular:

- parser success is not proof;
- elaborator success is not kernel admission;
- kernel admission is not compiler preservation;
- target type checking is not source correctness;
- owning the backend does not prove it;
- self-hosting is not a preservation theorem;
- a hash proves byte identity, not semantic equivalence.

## 21. Admission, checked state and caches

Inherited requirements include:

- no unresolved metavariables at admission;
- transaction-like failure behavior;
- failed modules do not leak partial declarations;
- checked artifacts are immutable/revalidated handles, not caller-constructible booleans;
- cache keys include relevant environment/context/transparency/universe/policy identities;
- serialized checked artifacts are rechecked or consumed through a sound evidence protocol.

## 22. Erasure and RuntimeIR

Erasure operates only after genuine logical admission.

Proof/type content is removed only when irrelevance permits it.

Runtime-relevant data cannot be discarded merely because its type mentions proofs.

RuntimeIR expresses source executable meaning independently of JS/Rust/Wasm representations.

Unknown runtime dependencies reject execution for that profile.

## 23. Backend preservation and artifacts

Preservation claims state:

- source/runtime semantics;
- target semantics;
- representation/value relation;
- effect/trace relation where relevant;
- termination/resource relation;
- assumptions.

Translation validation is acceptable only with a stated validator soundness relationship.

A proof about target AST does not automatically cover the serializer, linked runtime, bundler, minifier, framework transform, or final deployed bytes.

Evidence must bind the exact artifact endpoint claimed.

## 24. Acceptance results and evidence

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

And distinguish evidence for:

~~~text
parsed
elaborated
logically admitted
contract proved
termination proved
source correspondence
erasure preservation
target preservation
artifact binding
runtime assumptions
test observation
human usability
~~~

No unknown/failure/exhaustion state becomes success.

## 25. Diagnostics

r3 retains the r2 diagnostic architecture and adds/revises diagnostics required by the exact r3 grammar/profile/contract/interop documents.

Key r3 additions include:

~~~text
PS_CALL_LINE_BREAK_BEFORE_PAREN
PS_EMPTY_CALL_REQUIRED_ARGUMENT
PS_CALL_TUPLE_MIGRATION_REQUIRED
PS_BRACE_FIELD_COMMA_REQUIRED
PS_BRACE_TRAILING_FIELD_COMMA
PS_PROFILE_SYNTAX_EXTENSION_FORBIDDEN
PS_CONTRACT_IMPLEMENTATION_IDENTITY_MISMATCH
PS_DTS_RUNTIME_TYPE_BRANCH_MISMATCH
~~~

Native diagnostics may remain structured causes.

## 26. Migration from r2

Migration parses r2 with the r2 grammar first.

At minimum:

~~~text
r2 D-CALL f(x,y)  -> r3 f(x,y)
r2 native f (x,y) -> r3 f((x,y))
r2 function f()   -> previously invalid; may become valid only under r3
r2 brace fields   -> r3 commas between fields, no trailing field comma
~~~

Comments, binding identity, theorem statements, assumptions, suffixes, and source provenance are preserved structurally.

A formatter is not the migrator.

## 27. Pre-stable / 1.0 evidence gates

The r3 design is accepted now.

Stable/1.0 freeze and stronger assurance claims require evidence described in:

~~~text
23-PRE-STABLE-EVIDENCE-GATES.md
~~~

Required future evidence families include:

- TypeScript/Lean usability study;
- frontend ownership/lowering formal slice;
- backend preservation slice;
- primitive/runtime target matrix;
- App/Fiber/Resource/Stream cross-target conformance;
- real InterfaceIR/npm corpus;
- complete reference applications;
- Standard registration-closure/LSP/formatter tests;
- contract-core checks;
- exact artifact/release binding.

No such gate is claimed completed merely by this documentation pass.

## 28. Companion normative files

The r3 normative set includes:

~~~text
ProofScript_Language_Reference_v0.9.0_r3.md
R3-AUTHORITY-AND-DELTA.md
R3-R2-INHERITANCE-MATRIX.md
R3-GRAMMAR-AND-FEATURE-REGISTRY.md
FEATURE-REGISTRY-r3.json
06-STANDARD-VS-EXTENSIBLE-PROFILES.md
PS-STANDARD-REGISTRY-r3.json
SEMANTIC-BUNDLE-v1.md
SEMANTIC-BUNDLE-v1.schema.json
07-CONTRACTS-AND-SPECIFICATIONS.md
08-APPLICATION-EFFECTS-ASYNC-RESOURCES.md
09-NPM-DTS-INTEROP.md
INTERFACEIR-v1.md
INTERFACEIR-v1.schema.json
23-PRE-STABLE-EVIDENCE-GATES.md
R3-ACCEPTANCE.md
DECISIONS.md
MANIFEST.json
~~~

If prose examples conflict with these normative rules, the authority order in §0 applies.

## 29. Current implementation/evidence status

This reference is a design/specification baseline.

It does not claim:

- production r3 parser/lowerer implementation;
- formal frontend refinement;
- backend preservation;
- completed App runtime;
- completed InterfaceIR importer/exporter;
- completed reference applications;
- completed human study.

Those are separately tracked future obligations.

## 30. Final r3 commitment

ProofScript r3 is:

> Lean-compatible dependent programming and theorem proving with a small, regular application-facing surface, a closed Standard profile, explicit extensible profile, stable contracts, explicit application effects/resources/async semantics, and inspectable JS/npm/Wasm boundaries.

The language does not gain stronger assurance from familiar punctuation alone.

Unsupported behavior fails explicitly, and every stronger claim names the evidence and assumptions that support it.
