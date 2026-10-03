# r3 Normative Inheritance and Override Authority

Status: **normative for ProofScript v0.9-r3**

## 1. Why r3 is defined as a complete delta

The accepted r3 document is intentionally not a second approximate transcription of the entire Lean/ProofScript language.

To avoid losing the detailed compiler/runtime/module obligations already specified in r2, r3 is defined as a **complete normative delta** over one exact r2 artifact.

The inherited r2 authority is:

~~~text
Title: The ProofScript Language Reference v0.9.0
Revision: draft revision 2 / ps-0.9-r2
SHA-256:
d29c0b2d5780e6cdb08a4c9ac00cc7442a64b1c8133b51c5f0c0e9a343b11b8d
~~~

The pinned logical authority remains:

~~~text
Lean 4.34.0
293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
~~~

A conforming r3 implementation MUST bind both identities.

## 2. Authority order

When two rules appear to conflict, use this order:

1. the accepted r3 integrated reference;
2. the r3 normative companion documents and machine-readable registries;
3. this inheritance/override table;
4. the exact r2 artifact identified above;
5. the pinned Lean 4.34 source/registered environment for inherited Lean syntax/semantics;
6. tutorials, examples, design rationale, and external precedent.

A later item cannot override an earlier item.

The phrase "latest Lean" is never a semantic identity.

## 3. Total classification rule

Every normative r2 rule is classified in r3 as exactly one of:

- **inherited unchanged**;
- **superseded by r3**;
- **retired**;
- **profile-restricted**;
- **compatibility-only**.

If a rule is not listed in the explicit override tables below, it is **inherited unchanged**.

This rule makes the delta complete rather than selective.

## 4. r3 superseding rules

### 4.1 Parenthesized calls

r2:
- `D-CALL` requires adjacency;
- `f (x, y)` is protected native tuple application;
- `f()` is exactly one Unit argument.

r3:
- `E-CALL-PARENS-R3` replaces `D-CALL` in `.ps`;
- horizontal trivia/comments may separate a completed callable head from `(` according to the exact r3 call-gap rule;
- `f(x, y)` and `f (x, y)` are the same r3 call;
- one tuple argument is `f((x, y))`;
- empty calls use the r3 empty-call/default-completion rule in §17-R3-GRAMMAR-AND-FEATURE-REGISTRY;
- patterns still do not gain parenthesized-call syntax.

The old `D-CALL` ID is retired for r3 source and remains meaningful only when reading r2.

### 4.2 Structural brace bodies

r2 owned braces retain native outer layout/member-boundary behavior.

r3 owned braces are structural at the outer sequence level:

- structure/class fields: comma separated, **no trailing field comma**;
- inductive constructors: leading `|` markers;
- match alternatives: leading `|` markers;
- instance initializer fields: explicit/native semicolon sequence in brace mode;
- local `where` declarations: explicit/native semicolon sequence in brace mode;
- conditional branches: exactly one term;
- nested native child syntax can retain native layout.

This supersedes r2 §§16.2, 25, 27, 29, 31 and the corresponding owned grammar/feature rows only where those sections define outer owned-brace boundaries.

The r2 rule "no general ProofScript declaration terminator" remains inherited.

### 4.3 Zero-source-argument functions

r2 rejects `function f()`.

r3 accepts it and gives it the exact lowering defined in the r3 grammar document.

This supersedes r2 §17 and the old `PS_EMPTY_PARAMETER_GROUP` behavior for the specific `function ()` production.

Ordinary native `def` receives no hidden Unit/default binder.

### 4.4 Source profiles

r2's implementation-profile/capability model remains inherited, but r3 adds source-language profiles:

- `ps-standard`;
- `ps-lean-extensible`.

The exact Standard registration closure is defined by `ps-standard-registry.json`.

A source profile does not create a second logical theory.

### 4.5 Contracts

r2 ordinary theorem specifications remain fully valid.

r2 native intrinsic contracts are reclassified in r3 as:

~~~text
compatibility/oracle capability
not the semantic definition of PSC contracts
~~~

The stable r3 contract semantics is defined by `20-CONTRACT-CORE.md`.

Any r2 statement that describes the intrinsic mechanism as the selected contract semantics is superseded.

### 4.6 Application effects/async/resources

r2's distinctions among pure computation, IO, Task, transformer ordering, host exceptions, resources, and target semantics remain inherited.

r3 additionally defines the Standard application model in `21-APPLICATION-SEMANTICS.md`.

Target Promise/WASI primitives remain adapters, not source semantics.

### 4.7 npm / TypeScript interoperability

r2's foreign-boundary principles remain inherited.

r3 supersedes architectural placeholders with `InterfaceIR v1` and deterministic package-resolution identity defined in `22-INTERFACEIR-V1.md` and `interface-ir-v1.schema.json`.

## 5. Explicitly inherited critical r2 areas

The following r2 areas are inherited unchanged unless a preceding override applies.

### 5.1 Lexical and parser discipline

Inherited:

- Lean lexical treatment of identifiers/literals/comments/Unicode;
- source-byte/editor-position mapping;
- no global textual rewriting;
- L/D/E/X surface classes;
- committed ownership errors;
- category-aware `Lift` composition;
- native precedence except where an r3 owned production explicitly supersedes it;
- native patterns unless explicitly lifted;
- macro hygiene and binding preservation.

### 5.2 Definitions and type theory

Inherited:

- `def`, `theorem`, `example`, `abbrev`, `opaque`, `axiom`;
- native modifiers and opacity/reducibility meaning;
- explicit/implicit/strict-implicit/instance binders;
- universes, `Prop`, `Type`, `Sort`;
- native type inference, coercions, instances, default/automatic parameters;
- dependent structures/fields and native validity checks;
- inductives, recursors, positivity, motives, indexed/mutual/nested constructs;
- classes/typeclasses and generalized field notation;
- recursion, termination, partial/unsafe distinctions.

### 5.3 Exact primitive/data semantics

Inherited:

- exact `Nat` meaning, including truncated subtraction;
- exact pinned Nat division/remainder behavior;
- exact pinned `Int` division/remainder semantics;
- fixed-width integer/target-word behavior per selected declarations;
- floating-point behavior only according to the selected primitive/runtime profile;
- `Bool`, `Char`, `String`, `ByteArray`, `List`, `Array`, `Option`, products/sums/subtypes/`Fin` as distinct native abstractions;
- target representations must preserve the selected operations rather than define source meaning.

In particular, `List` is not silently an Array, JS `number` is not Nat/Int, and JS BigInt division is not automatically the selected Lean Int division.

### 5.4 Modules/source identity

Inherited:

- one authoritative source snapshot per logical module;
- explicit selection when `M.ps` and `M.lean` both exist;
- generated canonical `.lean` is not fallback source;
- no stale sibling/branch/host-package fallback;
- imports/options/registrations are environment identity;
- commands are processed in source/environment order;
- checked bytes are the bytes to which evidence/release identity binds.

### 5.5 Logic/proof/assumptions

Inherited:

- propositions are types and proof terms require genuine admission;
- Boolean truth is not automatically proposition evidence;
- ordinary theorems remain the stable baseline specification mechanism;
- assumption/axiom policy is explicit and transitive;
- unresolved holes/sorry/unknown solver results are not strict accepted evidence;
- specification weakness/vacuity is distinct from proof soundness.

### 5.6 Compiler pipeline and assurance

Inherited:

~~~text
source
 -> category-aware parse
 -> owned surface AST
 -> canonicalization/lowering
 -> Lean-compatible elaboration
 -> candidate declarations
 -> genuine kernel admission
 -> CheckedModule
 -> justified erasure/runtime lowering
 -> RuntimeIR
 -> target lowering
 -> exact emitted/linked artifacts
~~~

Inherited obligations include:

- phase-specific identities;
- transactional admission;
- immutable/revalidated checked state;
- no unresolved metavariables at admission;
- relevance before erasure;
- no unknown executable primitives;
- target preservation separated from source proof;
- serializer/artifact binding;
- bundling/link/minification as later assurance boundaries;
- exact release snapshot identity.

### 5.7 Acceptance/evidence labels

Inherited distinctions include at least:

~~~text
malformed-source
unsupported-feature
incompatible-environment
elaboration-rejected
kernel-rejected
proof-search-incomplete
resource-limit
cancelled
internal-error
accepted
~~~

and separate evidence for:

~~~text
source parsed
source elaborated
logical admission
contract proof
termination
source correspondence
erasure preservation
target preservation
artifact binding
external assumptions
test observation
~~~

No failure/exhaustion/unknown state becomes successful evidence.

## 6. Retired r2 rules

Retired in r3:

- adjacency-sensitive `D-CALL` ownership;
- the r2 protected-neighbor meaning of `f (x, y)` inside r3 `.ps`;
- r2 rejection of `function f()`;
- r2 outer-layout semantics for r3-owned structural brace sequences;
- any implication that experimental Lean intrinsic verification is the stable PSC contract semantic layer.

Historical r2 source keeps its old meaning under `ps-0.9-r2`.

## 7. Profile-restricted inherited rules

Some inherited Lean syntax is available only where the selected r3 source profile includes it.

`ps-standard` has the exact closed registry defined by `ps-standard-registry.json`.

`ps-lean-extensible` can use declared syntax/macro/elaborator extensions according to the pinned environment and explicit manifest.

A rule being valid Lean does not imply it is automatically in `ps-standard`.

## 8. Compatibility-only facilities

The following can remain compatibility/oracle facilities without defining the Standard source semantics:

- experimental Lean intrinsic contracts;
- arbitrary third-party parser mutation;
- host Meta code;
- target-specific unsafe/runtime replacement mechanisms.

Their use must be explicit in the capability/evidence manifest.

## 9. Normative completeness test

An r3 implementation question is answered as follows:

1. Check the accepted r3 reference and companion registries.
2. If r3 explicitly overrides the concern, use r3.
3. Otherwise read the exact r2 artifact identified by SHA-256 above.
4. For an inherited Lean construct, resolve its meaning through the pinned Lean 4.34 source/environment.
5. If the selected profile does not implement/permit that construct, return `unsupported-feature`; do not reinterpret it.

Therefore r3 is normatively complete even though it avoids copying every unchanged r2 paragraph.
