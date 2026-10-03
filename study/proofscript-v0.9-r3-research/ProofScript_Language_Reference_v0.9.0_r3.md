# The ProofScript Language Reference v0.9.0 r3

Status: accepted r3 language/design baseline; documentation/specification scope; not an implementation release or proof of soundness.

This file is the **standalone normative human and AI/compiler-design reference** for ProofScript v0.9.0 r3.

A reader or implementation agent does not need to open another ProofScript design document to determine the language meaning. The complete r3 authority rules, exact grammar, feature/profile registries, contract/application/interop specifications, release-evidence gates, and the full inherited r2 baseline are embedded as appendices in this file.

External Lean 4.34 source remains the pinned semantic implementation/oracle for the underlying Lean theory, but this document contains the ProofScript language/compiler contract needed to understand and design the compiler.

Grammar identity:

~~~text
ps-0.9-r3
~~~

Semantic pin:

~~~text
Lean 4.34.0
293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
~~~

Inherited r2 baseline:

~~~text
ProofScript Language Reference v0.9.0
draft revision 2 / ps-0.9-r2
SHA-256:
d29c0b2d5780e6cdb08a4c9ac00cc7442a64b1c8133b51c5f0c0e9a343b11b8d
~~~

---

# Part I — Normative model

## 1. Purpose

ProofScript is a general-purpose programming language and theorem-proving/formal-verification language whose logical meaning is defined through Lean-compatible elaboration and genuine kernel admission.

r3 changes the application-facing syntax, source profiles, specification layer, application model, and foreign-interface model. It does not introduce a competing logical type theory.

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

## 2. Complete normative authority

r3 is a complete normative delta over one exact r2 artifact.

Authority order **inside this standalone file** for ps-0.9-r3:

1. Parts I–XXV of this document;
2. embedded r3 Appendices A–J for the specific domains they define;
3. embedded Appendix K, the exact r2 baseline, for every rule not overridden by r3;
4. the pinned Lean 4.34 source/environment as the semantic oracle for inherited Lean theory/implementation details;
5. non-normative examples/research rationale.

No separate ProofScript document is required to resolve the r3 language contract.

If this document is silent about an r2 semantic rule, the r2 rule remains normative unchanged unless the inheritance matrix explicitly marks it otherwise.

This preserves the detailed r2 requirements for:

- lexical syntax;
- native categories and precedence;
- dependent type theory;
- universes;
- structures, inductives, classes, instances;
- recursion, partiality, unsafe and noncomputable declarations;
- Nat, Int, floating-point, strings, bytes, collections;
- modules and source identity;
- theorem/axiom policies;
- parser ownership and hygiene;
- compiler phases;
- genuine declaration admission;
- erasure and RuntimeIR;
- primitive/runtime matrices;
- backend preservation;
- artifact binding;
- diagnostics and resource limits;
- evidence manifests and release snapshots.

## 3. Central semantic relationship

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

### 4.1 .ps

A .ps file uses a ProofScript edition/profile.

It can contain:

- inherited Lean forms allowed by the selected profile;
- registered ProofScript decorations;
- registered ProofScript surface exceptions.

### 4.2 .lean

A .lean file is native Lean syntax.

ProofScript productions MUST NOT be injected into .lean.

A standalone ProofScript compiler may support only a documented subset of native Lean. Unsupported native Lean is unsupported; it must not be reinterpreted into a different ProofScript form.

### 4.3 .psx and future dialects

No UI/JSX semantics are implied by the extension alone.

A dialect requires an explicit grammar/profile identity and assurance boundary.

---

# Part II — Profiles and environment identity

## 5. ps-standard

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

---

# Part III — Lexical and parser ownership model

## 9. Inherited lexical rules

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

Lift<C> means:

> use the pinned native production for category C, replacing only explicitly registered child-category slots with ProofScript-aware child parsers/lowerers.

Do not approximate a difficult native category by storing opaque text and later claiming it was parsed.

Do not globally rewrite punctuation before parsing.

Do not globally replace equals signs, semicolons, braces, comments, or parentheses.

---

# Part IV — Exact r3 surface grammar

## 12. Definitions

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

r3 replaces r2 adjacency-sensitive D-CALL with E-CALL-PARENS-R3.

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

## 16. CallGap

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

## 18. Named arguments

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

Core functions are unary/curried.

Source conveniences such as:

~~~proofscript
function add(x: Nat, y: Nat): Nat := x + y
~~~

lower to native binder/application structure.

ProofScript does not define JavaScript-style multi-argument core functions.

Named/default/implicit/automatic behavior is delegated to the pinned high-level application semantics, subject to r3-owned source acceptance rules such as empty-call validation.

## 26. Structures, records, updates

Structures retain nominal/logical declaration identity.

Record construction/update uses native semantics.

A record update involving dependent fields is accepted only if retained/rebuilt fields satisfy their dependent types.

Target object spread does not define source record-update semantics.

## 27. Inductives and matching

Inductives retain:

- constructor typing;
- positivity;
- parameters and indices;
- motives;
- exhaustive/dependent elimination;
- mutual/nested behavior as supported by the selected environment.

Pattern syntax remains native unless explicitly registered.

## 28. Classes and instances

Classes/typeclasses are native type-directed abstractions.

Instances are semantic registrations, not JavaScript classes.

Instance search is part of elaboration/environment identity.

## 29. Recursion and termination

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

Nat denotes exact nonnegative natural numbers under the pinned semantics.

Important requirement:

~~~text
Nat subtraction truncates at zero.
~~~

Division/remainder use the exact selected native declarations, including selected zero-divisor behavior.

A JS number implementation does not define Nat.

## 31. Int

Int uses the exact pinned Lean semantics.

Signed division/remainder must preserve the selected source behavior, including negative cases.

A target BigInt/native integer operator is not assumed equivalent without a representation/operation argument.

## 32. Fixed-width and target-word integers

For fixed-width and target-word types, a target profile must specify:

- width;
- overflow/wrapping/checking;
- shifts;
- conversions;
- target-word width assumptions.

The target representation must preserve selected observable operations.

## 33. Floating point

Floating-point values are not mathematical reals.

Preservation must account for selected:

- rounding;
- NaN;
- infinities;
- signed zero;
- target/runtime assumptions.

## 34. Bool

Bool is distinct from Prop.

A true Boolean computation is not automatically proof evidence for an arbitrary proposition.

## 35. Char, String and ByteArray

Pinned native semantics remain authoritative.

A JavaScript UTF-16 representation/index is an implementation relation, not the source definition of String.

Backend adapters must define conversions explicitly.

## 36. Collections and data types

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

Each logical module resolves to one exact source snapshot.

If both M.ps and M.lean exist, a manifest must select one or the build rejects ambiguity.

A generated canonical .lean file is not a fallback source.

Missing inputs must not be replaced silently by:

- stale siblings;
- another branch;
- host-installed packages;
- old generated outputs.

## 38. Environment order

Commands are processed in source/environment order.

Imports, options, instances, attributes, semantic registrations, syntax profile, and semantic-bundle identities contribute to environment identity.

## 39. Generated source/provenance

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

A precondition is not automatically a runtime check.

A verified caller must establish it.

An untrusted external caller requires either:

- an explicit runtime-validating wrapper; or
- a documented restricted/trusted boundary.

A generated TypeScript declaration does not discharge a ProofScript precondition.

## 47. VC generation

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

Contract evidence reports transitive logical assumptions separately from runtime/external assumptions.

Policy-disallowed assumptions, unresolved holes, or incomplete proof search do not become strict contract success.

---

# Part IX — Standard application semantics

## 49. Semantic profile

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

Constructing, storing, copying, or reusing:

~~~text
App Caps E A
~~~

starts no external/application work.

Execution begins only through an explicit runtime operation such as root run or scoped fork.

This is a deliberate difference from an already-running foreign Promise.

## 51. Exit and RuntimeFault

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

A computation requiring C1 can execute in an environment C2 only when the selected capability relation establishes C1 is contained in C2 or an explicit adapter provides the missing capability.

A package manifest aggregates reachable capabilities, but package metadata does not replace local effect visibility.

Hidden host globals do not expand Caps.

## 53. Pure functions and App

An ordinary function A -> B is pure with respect to application effects.

A pure function may construct an App value without starting it.

This allows pure domain functions and theorems to remain independent of runtime execution.

## 54. Fiber is started

Fiber denotes already-started child work.

Conceptually:

~~~text
fork   : App Caps E A -> App ParentCaps ParentE (Fiber Caps E A)
join   : Fiber Caps E A -> App ParentCaps ParentE (Exit E A)
cancel : Fiber Caps E A -> App ParentCaps ParentE Unit
~~~

Exact library error/capability parameters can be refined as long as these semantic relationships are preserved.

## 55. Structured concurrency

Fibers belong to an owning scope by default.

A scope cannot successfully finish while owned children are silently left running.

On scope exit:

1. cancellation is requested for unfinished children;
2. required cleanup runs;
3. the scope waits for terminal outcomes subject to explicit resource limits;
4. child/cleanup causes are combined without silent information loss;
5. detach is explicit and transfers ownership.

## 56. Cancellation

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

Resource represents acquisition plus deterministic release.

After successful acquisition, release is attempted exactly once on:

- success;
- typed failure;
- cancellation.

Once required cleanup begins, ordinary cooperative cancellation is shielded/masked until cleanup reaches a terminal result.

Fatal host/resource-limit outcomes remain separately reported.

If both body and cleanup fail, Standard semantics preserves both causes rather than silently dropping one.

Garbage collection/finalizers do not define deterministic resource semantics.

## 58. Race and timeout

race starts contenders in one structured scope.

The winner is the first terminal outcome selected by the scheduler trace.

Then the loser receives cancellation and required cleanup completes before the race scope finishes.

timeout is a race/deadline operation requiring an explicit monotonic-clock capability/model.

A timeout does not imply rollback of already-observed external effects.

## 59. Stream

Stream is cold until subscribed/consumed.

A subscription creates an owned running scope.

The model distinguishes:

- item;
- normal end;
- typed failure;
- cancellation;
- runtime-fault reporting.

The stream model includes backpressure/demand.

Unbounded push behavior requires a separately named buffering policy.

Closing/cancelling a subscription triggers owned cleanup.

Late foreign callback events after terminal close cannot revive the stream.

## 60. Native Lean IO/Task

Native Lean IO and Task remain inherited low-level/native abstractions.

Portable ps-standard APIs normally expose:

- App;
- Fiber;
- Resource;
- Stream.

Low-level runtime-adapter modules or ps-lean-extensible code may use native IO/Task under explicit profiles.

A theorem about App semantics does not automatically prove an IO adapter correct.

## 61. Target async adapters

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

Normative interop format:

~~~text
ProofScript InterfaceIR v1
schemaVersion = proofscript-interface-ir-1.0.0
resolverProfile = psc-node-exports-v1
~~~

InterfaceIR sits between TypeScript/npm declarations and native ProofScript APIs.

TypeScript declarations do not become ProofScript proof/type semantics directly.

## 63. Binding identity

An InterfaceIR binding identity includes:

- InterfaceIR schema version;
- TypeScript version/profile;
- TypeScript moduleResolution mode;
- resolver profile;
- package install/source identity;
- optional lockfile SHA-256;
- package name/version;
- exact package.json SHA-256;
- requested export subpath;
- custom conditions;
- ordered runtime condition trace;
- selected runtime entry path/format/SHA-256;
- ordered type/declaration condition trace;
- selected declaration entry path/SHA-256;
- referenced declaration file hashes;
- target runtime/platform;
- generator/importer identity.

Package version alone is not sufficient identity.

## 64. Runtime/type resolution

Runtime and type resolution are recorded separately.

The importer must record the exact selected branches.

A declaration branch must not be assumed to describe the selected runtime branch merely because both come from the same package version.

If they cannot be related under the recorded export/resolution policy, reject.

Representative diagnostic:

~~~text
PS_DTS_RUNTIME_TYPE_BRANCH_MISMATCH
~~~

## 65. Raw / safe / specification layers

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

JS number remains a foreign floating-number domain until converted.

JS bigint may map to Int, or to Nat only after nonnegativity validation.

Target arithmetic does not define source Nat/Int semantics.

## 68. Object/identity model

Plain data may be copied/decoded into owned nominal structures.

Identity-bearing/mutable objects such as DOM nodes normally become opaque foreign handles with effectful operations.

TypeScript readonly is static metadata, not proof of deep runtime immutability.

## 69. Functions and this

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

Preserve:

- original byte offsets;
- line/column positions;
- token categories;
- comments/trivia;
- syntax scopes/pre-resolved identities where inherited;
- source file/module identity.

CallGap decisions use actual lexical trivia, not normalized text.

## 76. Parser ownership algorithm

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

Lowering must preserve:

- user binding identity;
- native macro scopes;
- pre-resolved references where present;
- namespace/module identity.

Generated names require established freshness.

A guessed unusual prefix is not a hygiene proof.

## 82. Diagnostics

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

Elaboration produces candidate declarations.

Candidate declarations are not automatically trusted.

Genuine kernel admission checks the declaration under the selected logical environment.

Only after admission can the declaration become part of CheckedModule.

## 85. Admission invariants

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

Theorem assurance reports transitive assumption dependencies.

Classical/foundational assumptions are explicit policy inputs.

Foreign/runtime assumptions are reported separately from logical axioms.

A theorem about an external model is not proof that the external implementation satisfies the model.

---

# Part XIII — Erasure and executable semantics

## 87. Erasure

Erasure occurs only after genuine logical admission.

Remove proof/type content only where irrelevance permits it.

Do not erase runtime-relevant data merely because its type mentions proofs.

## 88. RuntimeIR

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

Direct Wasm similarly requires explicit representation/ABI/preservation rules.

WASI/Component Model async func/future/stream can serve as target mechanisms for psc-app-v1, but do not define source semantics.

## 93. External compilers

Using TypeScript/Rust/other external compilers for a route adds a preservation/toolchain assumption unless covered by evidence.

External compilation does not invalidate an already valid source theorem; it affects the executable-artifact assurance boundary.

## 94. Serialization and artifacts

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

# Part XVII — Migration from r2

## 99. Migration principle

Parse r2 using the r2 grammar first.

Do not reinterpret raw r2 bytes directly under r3 when meaning could change.

## 100. Call migration

Nonempty r2 D-CALL:

~~~text
r2 f(x,y)
  -> r3 f(x,y)
~~~

r2 native tuple application:

~~~text
r2 f (x,y)
  -> r3 f((x,y))
~~~

r2 empty D-CALL meant explicit Unit:

~~~text
r2 f()
  -> r3 f(())
~~~

Do not silently reinterpret old empty calls as r3 default completion.

## 101. Brace migration

r2 structure/class outer layout becomes r3 explicit field commas.

No trailing field comma is added.

Match/inductive bars remain bars.

Instance/local-where braced sequences receive their r3 explicit semicolon sequence.

Nested native do/tactic categories remain native.

## 102. Contract/profile migration

r2 experimental intrinsic contracts are not silently relabelled stable PSC contract evidence.

Migration classifies:

- expressible in stable r3 pure core;
- compatibility/oracle only;
- manual rewrite required;
- unsupported.

Projects select ps-standard only when their dependency syntax/meta behavior fits the closed Standard profile.

---

# Part XVIII — Evidence and release discipline

## 103. Acceptance result vocabulary

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

An AI/compiler agent MUST treat this section as an implementation discipline, not as permission to invent missing language semantics.

### 106.1 Do not change the language to make implementation easier

If a source case is unclear:

1. consult the relevant main section of this document;
2. consult the embedded r3 appendices in this file;
3. if the rule is inherited, consult the embedded exact r2 baseline in Appendix K;
4. use the pinned Lean 4.34 implementation only as the semantic oracle for inherited Lean details;
5. if still unsupported or genuinely unspecified, reject/raise a specification issue.

Do not silently choose a JavaScript/TypeScript interpretation.

### 106.2 Implement the smallest semantic slice first

Recommended order:

1. immutable source/profile/module identity;
2. lexer/source spans;
3. parser ownership framework;
4. const/function aliases;
5. explicit binder groups;
6. parenthesized nonempty calls;
7. empty calls;
8. structural braces;
9. native lifted terms/declarations;
10. canonical lowering;
11. reference-compatible elaboration;
12. genuine admission;
13. CheckedModule;
14. pure RuntimeIR;
15. primitive matrix;
16. direct JS pure slice;
17. contracts pure core;
18. Standard registry enforcement;
19. semantic bundles;
20. InterfaceIR;
21. App/Fiber/Resource/Stream runtime;
22. direct Wasm;
23. application/reference-platform layers.

Do not implement broad app syntax before the semantic core is stable.

### 106.3 Maintain a feature ledger

For each feature, maintain:

~~~text
featureId
specVersion
sourceProfile
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

CheckedModule should be constructible only through genuine admission or a sound recheck/import protocol.

A public caller must not be able to fabricate:

~~~text
{ checked: true }
~~~

and thereby authorize declarations.

## 110. Cache keys

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
| INTERFACEIR-V1 | interop | versioned npm/TypeScript boundary |

Retired:

~~~text
D-CALL r2 adjacency semantics
D-DECL-SEMI
r2 rejection of function f()
r2 outer-layout semantics for r3 structural braces
~~~

---

# Part XXII — Canonical examples

## 112. Values and functions

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

~~~proofscript
class Sized(α: Type) where {
  size: α -> Nat
}

instance : Sized String where {
  size(s: String): Nat := s.length;
}
~~~

## 116. Contract

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

~~~proofscript
theorem addZero(n: Nat): add(n, 0) = n := by {
  simp [add]
}
~~~

Tactic syntax/semantics remain selected native/Standard-profile behavior.

---

# Part XXIII — Non-goals and explicit exclusions

## 118. Base r3 does not add

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
- trust in .d.ts as runtime validation;
- hidden proof/verification fallbacks.

## 119. Future work does not silently become current syntax

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

This document establishes:

- accepted r3 design;
- exact source/profile rules at specification level;
- exact call/brace/default behavior at specification level;
- complete r2-delta authority;
- compiler phase/invariant requirements;
- stable pure contract semantics;
- application semantic architecture;
- InterfaceIR identity/interop architecture;
- migration/conformance/evidence requirements.

## 121. What this document does not establish

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

# Part XXV — Final implementation directive

## 122. Single-source compiler-design rule

For an AI or human designing the ProofScript compiler:

1. implement only behavior specified here or inherited by the exact r2/Lean authorities named here;
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

# Appendix A — Embedded r3 authority and complete-delta rules

The following is embedded so this standalone file contains its own authority definition.

Status: **normative for the accepted `ps-0.9-r3` documentation baseline**

## 1. Why r3 is defined as a complete delta

r3 does not re-transcribe every unchanged Lean/ProofScript semantic rule. Instead it incorporates the exact accepted r2 reference by immutable content identity and overrides only the sections listed by this document and the r3 normative companions.

This makes r3 complete without risking accidental divergence in unchanged primitive/runtime/kernel/compiler-assurance text.

## 2. Immutable base

The inherited base is:

~~~text
baseline/ProofScript_Language_Reference_v0.9.0_r2.md
SHA-256 d29c0b2d5780e6cdb08a4c9ac00cc7442a64b1c8133b51c5f0c0e9a343b11b8d
grammar ps-0.9-r2
semantic pin Lean 4.34.0
commit 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
~~~

The vendored baseline is historical/immutable. r3 never edits its interpretation in place.

## 3. r3 composition

The normative r3 language is:

~~~text
ProofScript r3
  = exact r2 baseline
  + accepted r3 overrides
  + r3 machine-readable registries/schemas
~~~

If r3 says nothing about an r2 rule, the r2 rule remains normative.

## 4. Authority order

For `ps-0.9-r3`, conflicts are resolved in this order:

1. `ProofScript_Language_Reference_v0.9.0_r3.md`;
2. `R3-AUTHORITY-AND-DELTA.md` and `R3-GRAMMAR-AND-FEATURE-REGISTRY.md`;
3. machine-readable `FEATURE-REGISTRY-r3.json`, `PS-STANDARD-REGISTRY-r3.json`, `SEMANTIC-BUNDLE-v1.schema.json`, and `INTERFACEIR-v1.schema.json`, for the fields/categories they normatively define;
4. `SEMANTIC-BUNDLE-v1.md` and `INTERFACEIR-v1.md`;
5. accepted topic design documents and `DECISIONS.md`;
6. the exact r2 baseline for everything not overridden;
7. tutorials/research notes as informative only.

Machine-readable schemas do not silently override prose outside their explicitly defined data-format domain.

## 5. Semantic authority

The Lean semantic pin remains unchanged:

~~~text
Lean 4.34.0
293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
~~~

A later Lean version is a different profile/revision.

Native `.lean` remains native Lean syntax. r3 surface rules apply only to `.ps` under an r3 profile.

## 6. Override families

r3 overrides/amends only these semantic families:

- application syntax around parenthesized calls and empty calls;
- structural-brace outer member delimitation;
- zero-argument `function` sugar;
- `const` acceptance policy;
- Standard versus Lean-Extensible source profiles;
- stable PSC-owned contract core;
- application effects/resources/async architecture;
- npm/`.d.ts` InterfaceIR;
- migration/formatting/diagnostics/feature registry affected by the above.

All unchanged r2 rules for primitives, exact Nat/Int behavior, universes, dependent types, theorem checking, source identity, modules, recursion, unsafe/partial computation, transactional admission, erasure, runtime primitives, compiler preservation, artifact binding, resource limits, evidence manifests and assumption reporting remain normative.

## 7. Evidence

r2 historical oracle/test evidence remains evidence about the exact programs and environment it recorded. It does not become new r3 frontend evidence merely because r3 inherits the corresponding semantic rule.

r3 design acceptance remains distinct from production implementation, formal refinement, backend preservation, human-study results and full-application execution.

# Appendix B — Embedded r3 → r2 inheritance/override matrix

Status: **normative authority map for `ps-0.9-r3`**

Base artifact: `baseline/ProofScript_Language_Reference_v0.9.0_r2.md`  
SHA-256: `d29c0b2d5780e6cdb08a4c9ac00cc7442a64b1c8133b51c5f0c0e9a343b11b8d`

"**Inherited unchanged**" means the r2 rule is normative in r3 with the same Lean 4.34 semantic pin. "Amended" means r2 remains in force except for the named r3 change. "Overridden" means the corresponding r3 rule replaces the r2 rule for r3 source.

| r2 § | Topic | r3 disposition |
|---:|---|---|
| 1 | Purpose and design principles | amended: accepted-r3 status/design commitment |
| 2 | Normative language and authority | overridden: r3 delta authority and precedence |
| 3 | The central semantic relationship | inherited unchanged |
| 4 | Source files and source identity | amended: profile identity/source authority |
| 5 | Capabilities and implementation profiles | overridden: ps-standard / ps-lean-extensible |
| 6 | Acceptance results and assurance labels | inherited unchanged |
| 7 | TypeScript-oriented design choices | amended: r3 TypeScript-familiarity decisions |
| 8 | Character stream, comments, and positions | inherited unchanged |
| 9 | Identifiers, keywords, and hygiene | inherited unchanged |
| 10 | Punctuation and grammatical categories | amended: category-specific punctuation incl. structural braces |
| 11 | Surface classes | amended: parenthesized call is E-class in r3 |
| 12 | Grammar composition and inherited grammar | amended: Standard has closed registry; Extensible records extensions |
| 13 | Precedence, grouping, and expression boundaries | overridden: call gap/newline/grouping rules |
| 14 | D-CALL: positional, empty, and grouped calls | overridden: E-CALL-PARENS-R3 + empty-call semantics |
| 15 | v0.9 call conveniences: explicit named arguments and trailing commas | amended: named calls/trailing commas remain category-specific |
| 16 | Declaration boundaries and native semicolons | overridden: structural owned braces and separators |
| 17 | Definition declarations and aliases | overridden: function() Unit sugar; const retained |
| 18 | Definition kinds, modifiers, and visibility | inherited unchanged |
| 19 | Binders, dependencies, and universes | inherited unchanged |
| 20 | Inference, annotations, and elaboration order | inherited unchanged |
| 21 | Named, default, automatic, and partially supplied arguments | overridden: empty call vs default/optional/auto parameters |
| 22 | Lambdas, closures, and higher-order functions | inherited unchanged |
| 23 | Operators, equality, and conditions | inherited unchanged |
| 24 | Braced conditionals | inherited unchanged |
| 25 | Structures and record values | overridden: structure/class field separators; no trailing field comma |
| 26 | Dependent fields and updates | inherited unchanged |
| 27 | Inductives, constructors, and pattern matching | amended: structural braced inductive/match sequences |
| 28 | Indexed, mutual, nested, and coinductive definitions | inherited unchanged |
| 29 | Classes, instances, and methods | amended: class/instance brace rules |
| 30 | Collections, absence, and error values | inherited unchanged |
| 31 | Local definitions, `where`, and recursion syntax | amended: local where brace separators |
| 32 | Pattern/equation functions and declaration suffixes | inherited unchanged |
| 33 | Scalars, literals, and primitive identity | inherited unchanged |
| 34 | Strings, characters, bytes, and identity | inherited unchanged |
| 35 | Pure computation and evaluation | inherited unchanged |
| 36 | Native `do`, local mutation, and control flow | inherited unchanged |
| 37 | Structural, well-founded, partial, and unsafe computation | inherited unchanged |
| 38 | Effects, state, and errors | inherited unchanged |
| 39 | IO, tasks, resources, and application libraries | overridden: App/Fiber/Resource/Stream/Capability model |
| 40 | Imports, namespaces, sections, and modules | amended: source profiles and semantic-bundle imports |
| 41 | Notation, macros, deriving, and metaprogramming | amended: Standard extension restrictions |
| 42 | The logical foundation | inherited unchanged |
| 43 | Propositions, types, and evidence | inherited unchanged |
| 44 | Theorems and structured proof forms | inherited unchanged |
| 45 | Rewriting, simplification, automation, and reflection | inherited unchanged |
| 46 | Axioms, classical mathematics, quotients, and noncomputability | inherited unchanged |
| 47 | Specifications as ordinary theorems | overridden: stable pure contract core |
| 48 | Native intrinsic contracts | amended: native intrinsic contracts are compatibility/oracle only |
| 49 | Assertions, invariants, termination clauses, and ghost state | amended: state/loop/async contract surface staged; frame/effect model added |
| 50 | Specification quality and assumption control | inherited unchanged |
| 51 | Required pipeline and phase invariants | inherited unchanged |
| 52 | Surface AST and feature registry | inherited unchanged |
| 53 | Parsing API and error recovery | inherited unchanged |
| 54 | Canonical lowering rules | inherited unchanged |
| 55 | Binding, provenance, and source maps | inherited unchanged |
| 56 | Elaboration and declaration admission | inherited unchanged |
| 57 | Comparing reference and production frontends | inherited unchanged |
| 58 | Erasure and executable IR | inherited unchanged |
| 59 | Preservation propositions and certificates | inherited unchanged |
| 60 | Target routes and external compilers | inherited unchanged |
| 61 | Exact emitted artifacts, linking, and release snapshots | inherited unchanged |
| 62 | Resource limits and checker build trust | inherited unchanged |
| 63 | Standard library layering | amended: Standard application-layer architecture |
| 64 | Packages and logical modules | amended: package profiles and semantic bundles |
| 65 | Foreign interfaces and typed boundary values | overridden: InterfaceIR raw/safe/spec boundary |
| 66 | Data conversion, callbacks, and Promise adaptation | amended: callbacks/Promise mapped through App/Stream semantics |
| 67 | Exporting libraries and complete applications | amended: npm export identity and generated bindings |
| 68 | Optional UI syntax and other extensions | inherited unchanged |
| 69 | Canonical formatting | amended: r3 formatter/call/brace rules |
| 70 | Diagnostics and language-server information | amended: r3 diagnostics |
| 71 | Migration from v0.7 and earlier PSC3/v0.9 drafts | overridden: r2->r3 migration |
| 72 | Source and specification compatibility | inherited unchanged |
| 73 | Conformance program | amended: r3 conformance matrix |
| 74 | Implementation and release gates | amended: design accepted, stable/1.0 evidence gates remain |
| 75 | Grammar notation and scope | inherited unchanged |
| 76 | Owned grammar | overridden: r3 owned grammar |
| 77 | Native category dependency map | amended: Standard registry closure |
| 78 | Feature registry summary | overridden: r3 feature registry |
| 79 | Diagnostic catalog | amended: r3 diagnostic additions |
| 80 | Normative lowering examples and pitfalls | overridden: r3 lowering examples |
| 81 | Evidence manifest contract | amended: profile/bundle/interface identities |
| 82 | What the study corpus established | inherited unchanged |
| 83 | Research conclusions and alternatives | amended: r3 research conclusions; call adjacency rationale retired |
| 84 | Programming-language theory used in the design | inherited unchanged |
| 85 | Executed evidence and its limitations | amended: historical evidence is not r3 frontend evidence |
| 86 | Formal obligations before stronger claims | amended: formal proof obligations |
| 87 | Practical implementation order | amended: implementation order |
| 88 | Reference register | amended: current official-source supplements |
| 89 | Final design commitment | amended: accepted r3 design commitment |

## Global inheritance

Subsections inherit the disposition of their containing numbered section unless a more specific r3 document says otherwise.

In particular, r2's exact primitive/runtime/compiler-assurance rules remain normative where this matrix says inherited unchanged. This includes exact Nat/Int operations, fixed-width values, strings/bytes, source/module identity, recursion/partiality/unsafe distinctions, theorem/axiom policies, transactional admission, erasure, primitive matrices, preservation propositions, emitted-artifact binding, resource limits and evidence-manifest discipline.

Historical r2 evidence remains historical evidence; inheritance of a rule does not relabel an r2 test as an r3 frontend test.

# Appendix C — Embedded exact r3 overlay grammar and feature rules

Status: **normative for `ps-0.9-r3` surface ownership**

This document specifies the r3-owned overlay. Native categories not replaced here are inherited from the exact r2/Lean 4.34 baseline through `R3-AUTHORITY-AND-DELTA.md`.

## 1. Lexical rule for parenthesized calls

`CallGap` permits:
- zero or more inherited horizontal Lean space trivia (under the pinned lexer this means ordinary space, not a tab);
- Lean comments that contain **no physical line terminator**.

A physical line terminator ends the possibility of r3 parenthesized-call ownership between the completed head and the opening `(`.

Thus:

~~~proofscript
f(x)
f (x)
f/- comment -/(x)
~~~

are the same r3 call form, but:

~~~proofscript
f
(x)
~~~

is **not** one r3 parenthesized call.

Multiline argument lists remain valid **after** the opening parenthesis:

~~~proofscript
f(
  x,
  y,
)
~~~

A block comment containing a newline breaks `CallGap`.

This rule avoids calls crossing native `do`, tactic, local-declaration or other sequence boundaries invisibly.

## 2. Field notation

r3 does not change Lean field-notation adjacency.

~~~proofscript
users.map(render)   -- field notation + r3 call
users .map(render)  -- not added by r3
~~~

The dot must retain the inherited native adjacency rule.

## 3. Empty-call semantics

`f()` is an **empty source-level invocation**, not textually identical to `f(())`.

Its canonical high-level Lean application request is:

~~~lean
f ..
~~~

using Lean's native application ellipsis.

The pinned Lean elaborator performs ordinary insertion of implicit, instance-implicit, optional/default, and automatic parameters. r3 then applies an additional source-acceptance predicate:

1. every omitted **explicit** parameter must be represented by native `optParam` or `autoParam`;
2. an ordinary required explicit parameter may not be accepted merely because ellipsis created/inferred a metavariable for it;
3. unresolved metavariables remain rejection conditions;
4. empty-call syntax never eta-abstracts required parameters.

Consequences:

~~~proofscript
function now(): Time := ...
now()                         -- hidden optional Unit defaults to ()

function greet(name: String := "world"): String := ...
greet()                       -- native default is inserted

function add(x: Nat): Nat := x + 1
add()                         -- PS_EMPTY_CALL_REQUIRED_ARGUMENT
~~~

A nonempty call retains native-compatible partial-application behavior.

`function f()` lowers to one **optional Unit binder with default `()`**:

~~~lean
def f (_ : Unit := ()) := ...
~~~

This makes the zero-source-argument declaration participate in the same default-completion mechanism as ordinary optional parameters while preserving Lean's unary/curried core model.

An explicit `f(())` remains an ordinary nonempty call with one Unit argument.

An r2 empty D-CALL always meant an explicit Unit argument, so semantics-preserving r2→r3 migration rewrites:

~~~text
r2 f() -> r3 f(())
~~~

unless a migration tool has separately established and recorded a stronger source-level intent.

## 4. Owned grammar

~~~ebnf
PSFile              ::= ProfileCommandSequence EOF

PSCommand           ::= OwnedValueDecl
                      | BracedStructure
                      | BracedClass
                      | BracedInductive
                      | BracedInstance
                      | Lift<AllowedNativeCommand>

OwnedValueDecl      ::= Native<DefModifiers> ConstDecl
                      | Native<DefModifiers> FunctionDecl
                      | Native<DefModifiers> DecoratedDef

ConstDecl           ::= "const" Native<DeclId> ResultSpec? OwnedValue

FunctionDecl        ::= "function" Native<DeclId> FunctionBinders
                        ResultSpec? ContractClauses? OwnedValue

DecoratedDef        ::= "def" Native<DeclId> HeaderBinders?
                        ResultSpec? ContractClauses? OwnedValue

FunctionBinders     ::= OrdinaryFunctionBinders
                      | ZeroArgFunctionBinders

OrdinaryFunctionBinders ::= HeaderBinder+
ZeroArgFunctionBinders ::= Native<OtherDeclarationBinder>* EmptyFunctionGroup

EmptyFunctionGroup  ::= "(" ")"
HeaderBinders       ::= HeaderBinder+
HeaderBinder        ::= ExplicitGroup | Native<OtherDeclarationBinder>

ExplicitGroup       ::= "(" ExplicitEntry ("," ExplicitEntry)* ","? ")"
ExplicitEntry       ::= Native<BinderIdent> ":" PSTerm Native<DefaultSuffix>?

ResultSpec          ::= ":" PSTerm
OwnedValue          ::= ":=" PSDeclBody Native<TerminationSuffix>? WhereSuffix?
PSDeclBody          ::= Lift<NativeDeclBody>

WhereSuffix         ::= BracedWhere | Lift<NativeWhereDecls>
BracedWhere         ::= "where" "{" WhereField (";" WhereField)* ";"? "}"

BracedStructure     ::= Native<StructurePrefixAndHeader> "where"
                        "{" (StructField ("," StructField)*)? "}"
                        Native<DerivingSuffix>?

BracedClass         ::= Native<ClassPrefixAndHeader> "where"
                        "{" (ClassField ("," ClassField)*)? "}"
                        Native<DerivingSuffix>?

BracedInductive     ::= Native<InductivePrefixAndHeader> "where"
                        "{" Constructor* "}" Native<InductiveSuffix>?
Constructor         ::= "|" Lift<NativeConstructorBody>

BracedInstance      ::= Native<InstancePrefixAndHeader> "where"
                        "{" (InstanceField (";" InstanceField)* ";"?)? "}"

PSTerm              ::= ParenthesizedCall
                      | EmptyCall
                      | BracedIf
                      | BracedMatch
                      | Lift<AllowedNativeTerm>

ParenthesizedCall   ::= CallableHead CallGap "(" CallArguments ")"
EmptyCall           ::= CallableHead CallGap "(" ")"

CallArguments       ::= CallArgument ("," CallArgument)* ","?
CallArgument        ::= NamedCallArgument | PositionalCallArgument
NamedCallArgument   ::= Native<Ident> ":=" PSTerm
PositionalCallArgument ::= PSTerm

CallableHead        ::= Native<CompatibleCompletedHead>
                      | "(" PSTerm ")"
                      | ParenthesizedCall
                      | EmptyCall
                      | NativeProjectionOfCompletedHead

BracedIf            ::= "if" "(" PSTerm ")" "{" PSTerm "}"
                        "else" "{" PSTerm "}"

BracedMatch         ::= Native<MatchPrefixAndDiscriminantsWithLiftedTerms>
                        "with" "{" MatchAlternative+ "}"
MatchAlternative    ::= "|" Native<PatternGroup> "=>" PSTerm

ContractClauses     ::= PureContractClause*
PureContractClause  ::= "requires" PSTerm
                      | "ensures" Native<Ident> "=>" PSTerm

StructField         ::= Lift<NativeStructField>
ClassField          ::= Lift<NativeClassField>
InstanceField       ::= Lift<NativeWhereStructInstField>
WhereField          ::= Lift<NativeWhereLocalDecl>
~~~

The EBNF semicolons above are grammar notation, not ProofScript tokens.

Semantic predicates:
- `OrdinaryFunctionBinders` must contain at least one `ExplicitGroup`;
- `ZeroArgFunctionBinders` may contain only native non-explicit binders before the final empty group;
- empty structure/class/inductive/instance bodies are accepted only where the corresponding lowered native declaration is semantically valid;
- `BracedWhere` still requires at least one local declaration.

## 5. Structural brace rules

- Structure/class fields use commas **between** fields. Trailing field commas are rejected.
- Inductive constructors and match alternatives use leading `|` markers; no comma/semicolon is added.
- Instance and local-`where` braced sequences use explicit native semicolon separators; a trailing semicolon is allowed only because those inherited native sequence categories allow it.
- Braced conditional branches contain exactly one term.
- Native `do { ... }` and `by { ... }` retain native `do`/tactic sequencing. Their semicolons are not declaration terminators.
- Indentation inside the **outer r3-owned brace sequence** is formatting. Nested inherited child categories may still use their own native layout.

## 6. Comma policy

Trailing commas are category-specific:

| Category | trailing comma |
|---|---|
| nonempty r3 call | allowed |
| nonempty explicit parameter group | allowed |
| structure fields | rejected |
| class fields | rejected |
| native tuple/pattern/record categories | inherited native rule |

There is no universal "all comma lists allow trailing comma" rule.

## 7. Contract grammar scope

The normative r3 contract surface currently freezes only:
- zero or more `requires P`;
- zero or more `ensures result => Q`;
- total pure functions.

State/loop/async contract syntax is reserved for a later profile revision even though their semantic research direction is documented.

## 8. Ownership and committed errors

Once an owned discriminator commits, failure is a committed ProofScript error rather than silent fallback.

Examples:
- `function f()` commits to zero-source-argument function sugar (optional Unit default);
- callable head + `CallGap` + `(` commits to r3 call parsing;
- `structure ... where {` commits to r3 structural field grammar;
- `function ... requires` commits to the r3 pure contract clause grammar.

## 9. Feature IDs

The machine-readable registry is `FEATURE-REGISTRY-r3.json`. The important r3 additions/revisions are:
- `E-CALL-PARENS-R3`;
- `E-EMPTY-CALL-R3`;
- `D-FUNCTION-UNIT-R3`;
- `E-STRUCT-BODY-R3`;
- `E-CLASS-BODY-R3`;
- `E-INDUCTIVE-BODY-R3`;
- `E-MATCH-BODY-R3`;
- `E-INSTANCE-BODY-R3`;
- `E-WHERE-BODY-R3`;
- `S-PURE-CONTRACT-R3`;
- profile records `P-STANDARD-R3` and `P-LEAN-EXTENSIBLE-R3`.

# Appendix D — Embedded machine-readable r3 feature registry

The following JSON is normative for the feature-registry data fields it defines.

~~~json
{
  "schemaVersion": "proofscript-feature-registry-1",
  "language": "ProofScript",
  "grammarRevision": "ps-0.9-r3",
  "semanticPin": {
    "leanVersion": "4.34.0",
    "leanCommit": "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b"
  },
  "inheritedBase": {
    "grammarRevision": "ps-0.9-r2",
    "sha256": "d29c0b2d5780e6cdb08a4c9ac00cc7442a64b1c8133b51c5f0c0e9a343b11b8d"
  },
  "features": [
    {
      "id": "L-CORE-LEAN",
      "class": "L",
      "category": "registered-native",
      "status": "inherited",
      "target": "same native syntax/meaning"
    },
    {
      "id": "E-CALL-PARENS-R3",
      "class": "E",
      "category": "term",
      "status": "accepted",
      "discriminator": "CallableHead CallGap (",
      "target": "one native-compatible application object"
    },
    {
      "id": "E-EMPTY-CALL-R3",
      "class": "E",
      "category": "term",
      "status": "accepted",
      "discriminator": "CallableHead CallGap ()",
      "target": "native high-level ellipsis application plus r3 omitted-required-parameter acceptance check",
      "canonicalLean": "head ..",
      "omittedExplicitAcceptedKinds": [
        "optParam",
        "autoParam"
      ],
      "rejectOrdinaryRequiredExplicit": true
    },
    {
      "id": "D-NAMED-CALL",
      "class": "D",
      "category": "call-argument",
      "status": "inherited-amended",
      "target": "native named argument"
    },
    {
      "id": "D-TRAILING-COMMA-CALL",
      "class": "D",
      "category": "call-list",
      "status": "accepted",
      "target": "no additional argument"
    },
    {
      "id": "D-TRAILING-COMMA-PARAMS",
      "class": "D",
      "category": "explicit-binder-list",
      "status": "accepted",
      "target": "no additional binder"
    },
    {
      "id": "D-CONST-ALIAS",
      "class": "D",
      "category": "command",
      "status": "accepted",
      "target": "parameterless native def"
    },
    {
      "id": "D-FUNCTION-ALIAS-R3",
      "class": "D",
      "category": "command",
      "status": "accepted",
      "target": "native def"
    },
    {
      "id": "D-FUNCTION-UNIT-R3",
      "class": "D",
      "category": "function-header",
      "status": "accepted",
      "target": "native def with one optional Unit binder defaulting to ()",
      "headerRule": "native non-explicit binders may precede the final empty explicit group"
    },
    {
      "id": "D-EXPLICIT-PARAMS",
      "class": "D",
      "category": "header",
      "status": "inherited",
      "target": "ordered explicit native binders"
    },
    {
      "id": "E-IF-BRACE",
      "class": "E",
      "category": "term",
      "status": "inherited",
      "target": "native conditional; one term per branch"
    },
    {
      "id": "E-STRUCT-BODY-R3",
      "class": "E",
      "category": "structure-fields",
      "status": "accepted",
      "separator": "comma-between-only",
      "trailingSeparator": false
    },
    {
      "id": "E-CLASS-BODY-R3",
      "class": "E",
      "category": "class-fields",
      "status": "accepted",
      "separator": "comma-between-only",
      "trailingSeparator": false
    },
    {
      "id": "E-INDUCTIVE-BODY-R3",
      "class": "E",
      "category": "constructors",
      "status": "accepted",
      "separator": "leading-bar"
    },
    {
      "id": "E-MATCH-BODY-R3",
      "class": "E",
      "category": "match-alternatives",
      "status": "accepted",
      "separator": "leading-bar"
    },
    {
      "id": "E-INSTANCE-BODY-R3",
      "class": "E",
      "category": "instance-fields",
      "status": "accepted",
      "separator": "native-semicolon",
      "trailingSeparator": true
    },
    {
      "id": "E-WHERE-BODY-R3",
      "class": "E",
      "category": "local-declarations",
      "status": "accepted",
      "separator": "native-semicolon",
      "trailingSeparator": true
    },
    {
      "id": "S-PURE-CONTRACT-R3",
      "class": "S",
      "category": "declaration-contract",
      "status": "accepted",
      "scope": "total-pure-functions",
      "clauses": [
        "requires",
        "ensures"
      ]
    },
    {
      "id": "P-STANDARD-R3",
      "class": "P",
      "category": "source-profile",
      "status": "accepted",
      "registry": "PS-STANDARD-REGISTRY-r3.json"
    },
    {
      "id": "P-LEAN-EXTENSIBLE-R3",
      "class": "P",
      "category": "source-profile",
      "status": "accepted",
      "extensionPolicy": "declared-and-identity-bound"
    }
  ],
  "retired": [
    {
      "id": "D-CALL",
      "reason": "replaced by E-CALL-PARENS-R3"
    },
    {
      "id": "D-DECL-SEMI",
      "reason": "retired in r2 and remains retired"
    }
  ],
  "callGap": {
    "inheritedHorizontalWhitespace": [
      "space"
    ],
    "tabsIntroducedByR3": false,
    "comments": "Lean comments with no physical line terminator",
    "bareLineTerminator": false
  }
}
~~~

# Appendix E — Embedded machine-readable ps-standard registry

The following JSON is normative for the Standard-profile registry fields it defines.

~~~json
{
  "schemaVersion": "proofscript-standard-registry-1",
  "registryId": "ps-standard-0.9-r3",
  "grammarRevision": "ps-0.9-r3",
  "semanticPin": {
    "leanVersion": "4.34.0",
    "leanCommit": "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b"
  },
  "parserModel": "closed-snapshot-independent-of-package-import-side-effects",
  "allowDependencySyntaxMutation": false,
  "allowedSurfaceFeatures": [
    "E-CALL-PARENS-R3",
    "E-EMPTY-CALL-R3",
    "D-NAMED-CALL",
    "D-TRAILING-COMMA-CALL",
    "D-TRAILING-COMMA-PARAMS",
    "D-CONST-ALIAS",
    "D-FUNCTION-ALIAS-R3",
    "D-FUNCTION-UNIT-R3",
    "D-EXPLICIT-PARAMS",
    "E-IF-BRACE",
    "E-STRUCT-BODY-R3",
    "E-CLASS-BODY-R3",
    "E-INDUCTIVE-BODY-R3",
    "E-MATCH-BODY-R3",
    "E-INSTANCE-BODY-R3",
    "E-WHERE-BODY-R3",
    "S-PURE-CONTRACT-R3"
  ],
  "allowedCommandHeads": [
    "import",
    "namespace",
    "end",
    "section",
    "variable",
    "include",
    "omit",
    "open",
    "universe",
    "def",
    "function",
    "const",
    "theorem",
    "example",
    "abbrev",
    "opaque",
    "axiom",
    "structure",
    "class",
    "inductive",
    "instance",
    "mutual",
    "attribute",
    "set_option",
    "#check",
    "#print",
    "#reduce",
    "#eval"
  ],
  "allowedTermFamilies": [
    "identifier",
    "literal",
    "parenthesized",
    "tuple",
    "application",
    "namedArgument",
    "fieldNotation",
    "lambda",
    "let",
    "if",
    "match",
    "do",
    "record",
    "recordUpdate",
    "projection",
    "typeAscription",
    "dependentFunction",
    "forall",
    "exists",
    "proofTerm",
    "calc",
    "have",
    "show",
    "suffices"
  ],
  "fixedTacticHeads": [
    "rfl",
    "exact",
    "apply",
    "intro",
    "intros",
    "assumption",
    "constructor",
    "cases",
    "induction",
    "rw",
    "simp",
    "simp_all",
    "unfold",
    "change",
    "have",
    "show",
    "suffices",
    "decide",
    "omega",
    "grind"
  ],
  "allowedAttributeNames": [
    "simp",
    "instance",
    "default_instance",
    "inline",
    "macro_inline",
    "reducible",
    "irreducible",
    "deprecated",
    "inherit_doc",
    "pp_nodot"
  ],
  "forbiddenDynamicSyntaxHeads": [
    "syntax",
    "macro",
    "macro_rules",
    "elab",
    "elab_rules",
    "declare_syntax_cat",
    "notation",
    "infix",
    "infixl",
    "infixr",
    "prefix",
    "postfix"
  ],
  "forbiddenElaboratorAttributes": [
    "term_elab",
    "command_elab",
    "tactic"
  ],
  "quotationPolicy": "not-in-standard-source",
  "semanticImport": {
    "schemaVersion": "psc-semantic-bundle-1.0.0",
    "syntaxMetaExportsMustBeEmpty": true,
    "hostBuildEffectsMustBeEmpty": true,
    "exactBundleIdentityRequired": true
  },
  "nativeIOPolicy": "direct native IO/Task allowed only in modules explicitly marked nonportable-adapter; portable Standard application APIs use App",
  "environmentRoots": [
    "Lean.Init@4.34.0",
    "Lean.Std@4.34.0",
    "ProofScript.Standard@0.9-r3"
  ],
  "registrationClosure": {
    "materializedManifestRequired": true,
    "digestAlgorithm": "sha256",
    "releaseMustPublishDigest": true,
    "hostInstalledExtraRegistrationsAllowed": false
  },
  "hostSecurity": {
    "semanticImportGrantsHostPermissions": false,
    "arbitraryDependencyInstallScriptRequired": false
  },
  "cacheIdentity": [
    "grammarRevision",
    "registryId",
    "registrationClosureSha256",
    "leanSemanticCommit",
    "moduleSourceIdentities",
    "semanticBundleIdentities",
    "options",
    "semanticRegistrations",
    "axiomPolicy",
    "compilerRevision",
    "checkerRevision"
  ],
  "optionPolicy": {
    "allowedOptionUniverse": "options registered by the exact Standard registration closure",
    "unknownOption": "reject",
    "cacheRelevantOptionsMustBeIdentityBound": true,
    "hostSecurityOptionsMayNotBeEnabledBySemanticImports": true
  },
  "attributePolicy": {
    "allowedAttributeNames": [
      "simp",
      "instance",
      "default_instance",
      "inline",
      "macro_inline",
      "reducible",
      "irreducible",
      "deprecated",
      "inherit_doc",
      "pp_nodot"
    ],
    "newAttributeHandlerRegistration": false
  },
  "tacticPolicy": {
    "fixedHeads": [
      "rfl",
      "exact",
      "apply",
      "intro",
      "intros",
      "assumption",
      "constructor",
      "cases",
      "induction",
      "rw",
      "simp",
      "simp_all",
      "unfold",
      "change",
      "have",
      "show",
      "suffices",
      "decide",
      "omega",
      "grind"
    ],
    "dependencyMayAddTacticSyntax": false,
    "dependencyMayReplaceTacticElaborator": false
  }
}
~~~

# Appendix F — Embedded stable PSC contract specification

Status: **accepted r3 semantic design; production implementation pending.**

## Decision

ProofScript r3 owns the stable contract semantics, but the **normative r3 surface core is deliberately narrow**.

The frozen r3 contract surface contains:
- `requires P`;
- `ensures result => Q`;
- total pure functions.

Stateful/loop/async contract clauses such as surface `assert`, `invariant`, `modifies`, `decreasing`, old-state syntax, and async trace clauses are reserved for later profile revisions until their program logic is specified.

Lean intrinsic verification may remain an oracle or implementation path, but it is not the definition of PSC contracts.

The kernel still checks ordinary evidence; r3 adds no trusted contract primitive.

## Pure total functions

For:

~~~proofscript
function withdraw(balance: Nat, amount: Nat): Nat
  requires amount <= balance
  ensures result => result = balance - amount
:=
  balance - amount
~~~

the final accepted claim must be equivalent to:

~~~text
forall balance amount,
  amount <= balance ->
  withdraw balance amount = balance - amount
~~~

and it must refer to the actual accepted implementation declaration.

A VC generator that proves an unrelated True proposition cannot authorize the implementation.

## Normative pure contract semantics

For a declaration with preconditions `P₁ ... Pₙ` and postconditions `Q₁ ... Qₘ`, r3 normalizes:

~~~text
Pre x := P₁ x ∧ ... ∧ Pₙ x
Post x result := Q₁ x result ∧ ... ∧ Qₘ x result

ContractTheorem :=
  ∀ x, Pre x → Post x (implementation x)
~~~

with the corresponding dependent/multi-parameter generalization.

Zero `requires` means `True`. Zero `ensures` means the declaration has no contract theorem request.

The theorem identity binds to the exact admitted implementation and normalized specification dependency closure.

## Normalized contract model

A normalized contract contains:

- exact implementation identity;
- specification identity;
- precondition;
- outcome relation;
- optional state relation;
- optional termination obligation;
- semantic dependency closure;
- axiom policy;
- proof/evidence status.

Multiple preconditions conjoin. Result conditions are normalized by outcome rather than silently assuming success.

## Typed outcomes

For `Except E A` and other sum/result types, the stable r3 surface does **not** add separate success/error clause syntax.

Outcome-sensitive properties use the ordinary result binder plus native matching:

~~~proofscript
function parseUser(input: String): Except ParseError User
  ensures result =>
    match result with {
      | .ok user => User.valid(user)
      | .error err => ParseError.describes(input, err)
    }
:=
  ...
~~~

This keeps the stable contract grammar to `requires` and `ensures result => ...` while retaining full logical expressiveness.

A future convenience spelling such as separate `.ok`/`.error` postconditions requires an explicitly versioned contract-syntax revision.

## Caller obligations

A precondition is not runtime enforcement by itself.

Callers fall into four categories:

1. verified callers that prove the obligation;
2. dependent/proof-bearing APIs that receive evidence;
3. runtime boundary wrappers that validate a decidable condition;
4. explicitly trusted external callers.

Generated TypeScript declarations do not enforce ProofScript preconditions at runtime.

## Frame and effect semantics

Every contract has a semantic frame, even when the pure r3 surface does not spell it explicitly.

~~~text
FrameSpec {
  effectFrame
  readFrame
  writeFrame
}
~~~

For a total pure function, all three frames are empty.

`effectFrame` is a finite normalized set of permitted capability-operation identities.

`readFrame` identifies abstract mutable regions/foreign resources whose state may influence the result or trace.

`writeFrame` identifies abstract mutable regions/foreign resources the computation may modify.

For future stateful/application contracts, a postcondition about the returned value is not permission to mutate unrelated state.

The application type `App caps err result` provides an upper bound on permitted capability classes; a contract may narrow that effect frame but may not silently expand it.

Frame identities belong to the versioned program-logic model rather than raw target pointers. Frame/effect information is part of specification identity and evidence invalidation.

## Higher-order callable contracts

ProofScript is higher-order, so r3 freezes an ordinary logical model for function values without adding kernel primitives.

Conceptually:

~~~text
CallableSpec args result := {
  requires : args -> Prop
  ensures  : args -> result -> Prop
}

callRequires(f, args) : Prop
callEnsures(f, args, outcome) : Prop
callEffects(f, args) : EffectFrame
callReads(f, args) : ReadFrame
callWrites(f, args) : WriteFrame
~~~

A function value carrying/associated with a `CallableSpec` may be used by a higher-order theorem only through ordinary proved relationships connecting that value to `callRequires`, `callEnsures`, and any effect/read/write frame guarantees it relies on.

This model is analogous in purpose to higher-order pre/postcondition predicates in verification systems, but PSC defines its own predicates and proof obligations.

The r3 surface does not yet add special callable-contract syntax; ordinary theorem/library APIs expose these predicates first.

## Stateful and partial programs

Stateful specifications use explicit pre/post state relations. Partial functions can have partial-correctness and safety results without claiming termination. Long-running services may use trace/state invariants instead of total-return theorems.

The public assurance vocabulary must distinguish:

- partial correctness;
- termination;
- total correctness;
- trace safety.

## Stateful/loop/async contracts are staged

The semantics below are requirements for a future extension, not accepted r3 base-surface productions.

A future loop contract must cover initialization, preservation, normal exit, break, continue, early return, typed failure, and cancellation/effect exits when those constructs are present.

A future stateful contract must include an explicit frame/effect relation.

A future async contract must range over explicit outcomes/traces from the accepted application semantic model rather than pretending an async computation is a total pure return value.

## Ghost and erased values

Ghost values are explicitly classified. Runtime behavior must not depend on evidence that is erased. Failure to establish relevance/irrelevance rejects the executable claim.

## Specification identity

An approved specification includes:

- normalized contract AST;
- referenced predicates and types;
- imported theorem dependencies;
- selected program-logic version;
- semantic pin and profile;
- axiom policy.

Protecting only the textual ensures clause is insufficient if an agent can redefine its predicates.

## AI policy

Recommended repository policy:

~~~text
implementation: writable
proof scripts: writable
contracts: review-required
contract semantic dependencies: review-required
axiom policy: locked
foreign trust declarations: review-required
verification toolchain: locked
~~~

This is build/repository policy, not kernel authority.

## VC generation

VC generation is untrusted proof construction.

~~~text
checked implementation
      +
normalized specification
      |
      v
untrusted VC generator / automation / SMT
      |
      v
proof term or checked certificate
      |
      v
ordinary admitted theorem
      |
      v
ContractEvidence(implementationId, specificationId)
~~~

Solver valid/unsat output is not strict-profile proof authority without reconstruction, a checked certificate, or an explicitly larger trust profile.

## Lean intrinsic compatibility

If the pinned intrinsic system overlaps:

- PSC may lower compatible contracts to it;
- generated specification theorems can be candidate evidence;
- experimental status remains visible;
- unsupported PSC features use the PSC path or reject.

PSC contract meaning does not change with upstream experimental implementation details.

## First implementation slice

The first implementation slice is exactly the frozen normative core:
- total pure functions;
- `requires`;
- `ensures result => ...`;
- empty pure frame;
- final admitted contract theorem;
- assumption reporting.

Higher-order `CallableSpec` is a library/logical interface that can be implemented alongside the pure core without adding syntax.

Typed-error outcome sugar, mutable-state frames, loops/invariants, termination clauses and async traces require later explicitly versioned contract profiles.

## Evidence status

Normative pure contract core, outcome-through-match rule, frame semantics, and higher-order callable model: **accepted for r3**.
Production contract elaborator: **not implemented**.
General VC correctness theorem: **not proved**.
AI policy enforcement: **not implemented**.

# Appendix G — Embedded application effects/resources/async specification

Status: **accepted r3 application-semantics direction; library/runtime implementation pending.**

## Decision

Use ordinary Lean-compatible library/runtime definitions rather than new kernel effects. The accepted semantic model is conceptually:

~~~text
App (caps : CapabilitySet) (err : Type) (result : Type)
Fiber (caps : CapabilitySet) (err : Type) (result : Type)
Exit err result
  | success result
  | failure err
  | cancelled CancelReason

RuntimeFault

Resource (caps : CapabilitySet) (err : Type) value
Stream   (caps : CapabilitySet) (err : Type) item
~~~

The exact Lean library encoding may use equivalent ordinary definitions, but it must preserve these relationships.

## Cold versus started computations

`App caps err result` is **cold**: constructing, copying, storing, or reusing an App value does not by itself start external work.

Work starts only through an explicit execution/start operation such as `run` or `fork`.

Each `run`/`fork` starts a distinct execution; `App` does not imply memoization. Re-executing an App that captures a stateful/foreign resource remains subject to that resource's explicit validity/lifetime semantics.

`Fiber caps err result` denotes already-started work and records the capability set of the child computation.

Conceptually:

~~~text
run  : CapEnv caps -> App caps err a -> native IO (Exit err a)
fork : App childCaps err a -> App parentCaps parentErr (Fiber childCaps err a)
join : Fiber childCaps err a -> App parentCaps parentErr (Exit err a)
cancel : Fiber childCaps err a -> App parentCaps parentErr Unit
~~~

The final library types may refine parent/child capability/error relationships, but they may not change the cold/start distinction.

## Pure functions

Ordinary functions remain pure with respect to application effects. A Standard-profile pure function cannot perform hidden filesystem, network, clock, random, process, DOM, or similar effects through ambient target globals.

## Execution outcomes

Ordinary recoverable application execution has exactly these terminal outcomes:

~~~text
Exit err result
  | success result
  | failure err
  | cancelled CancelReason
~~~

Unexpected host/runtime failures are represented separately as `RuntimeFault`.

A root runtime may therefore report a wider `RunOutcome` such as:

~~~text
completed (Exit err result)
runtimeFault RuntimeFault
resourceLimit ResourceLimit
hostTerminated HostTermination
~~~

without pretending those runtime outcomes inhabit the typed application error `err`.

A `RuntimeFault` is **not** catchable by ordinary typed-error handlers. A foreign/runtime adapter may explicitly translate selected faults into the declared typed error channel, and that translation is part of the adapter contract.

This avoids pretending every arbitrary JS throw, engine trap, process failure, or corrupted host condition inhabits the application's declared error type.

## Capabilities

Effects require declared capabilities such as filesystem, network, clock, random, process, environment, storage, console, and DOM.

Capabilities are visible in the application type through `App caps err result`, not only in package metadata.

`CapabilitySet` is a canonical finite type-level capability set. Its concrete Lean encoding may be a normalized list/set index, but equivalent sets must have a deterministic canonical identity for manifests/caches.

A computation requiring capability set `C1` can execute in an environment `C2` only when the selected capability relation establishes `C1 ⊆ C2` or an explicit adapter implements the missing capability.

A package manifest aggregates the capabilities reachable from its exported/runtime entry points. Availability of a host global does not grant a PSC capability automatically.

## Resource

`Resource caps err a` describes acquisition and deterministic release.

After successful acquisition, release is attempted exactly once on normal success, typed failure, and cancellation, subject only to explicitly reported fatal runtime limitations.

Once required deterministic cleanup begins, ordinary cooperative cancellation is **shielded/masked** until cleanup reaches a terminal result. This prevents cancellation from recursively interrupting release and silently leaking an owned resource.

Cleanup may still encounter an explicitly modeled timeout, typed release failure, RuntimeFault, resource limit, or host termination according to the selected runtime profile.

### Body/cleanup failure combination

The Standard semantics never silently drops one cause when both body and cleanup fail.

Conceptually the final cause relation distinguishes at least:

~~~text
body failure
release failure
body + release failure
cancellation + release failure
~~~

The exact public Lean datatype/API name can be chosen during library implementation, but preservation of both causes is normative.

### Cancellation

Cancellation is cooperative and two-phase:

~~~text
Running
  -> cancellation requested
Cancelling
  -> terminal Success | Failure | Cancelled
~~~

`cancel fiber` requests cancellation. It is not itself proof that the fiber is terminal.

Cancellation requests are idempotent at the semantic level. A cancellation request after terminal completion does not alter the already selected terminal result.

`join fiber` observes the terminal `Exit`; it does not restart the computation. Repeated joins observe the same terminal `Exit` (subject only to separately reported runtime faults/resource limits in the joining operation itself).

A normal completion or typed failure may race with a cancellation request according to the scheduler trace; the terminal outcome is whichever the semantic scheduler relation selects.

Foreign adapters state whether external work is actually cancellable. Cancelling a local wait does not prove a remote side effect was reversed.

## Race and timeout

Race selects the first terminal outcome observed by the scheduler trace, requests cancellation of losers, and waits for required loser cleanup before the race scope completes.

If the scheduler model admits nondeterminism, the specification reports the set/relation of permitted outcomes rather than inventing deterministic wall-clock ordering.

Timeout is a race with an explicit clock/deadline computation. Clock assumptions and late effects remain visible.

## Stream

`Stream caps err item` is **cold** until a consumer subscribes/starts consumption.

A subscription creates an owned running scope.

Stream semantics distinguishes:

~~~text
item
normal end
typed failure
cancelled
runtime fault at the runtime-reporting layer
~~~

The model includes backpressure/demand: an unbounded push producer is not assumed unless a separately named buffering policy says so.

Cancelling/closing a subscription triggers the same deterministic/shielded resource-cleanup discipline as other owned scopes.

JS `AsyncIterable` / `ReadableStream` and Wasm stream/future mechanisms are adapters rather than the definition of PSC Stream.

## Callbacks

A foreign callback binding records whether invocation is synchronous/reentrant or deferred, one-shot or repeated, retained or immediate, allowed after disposal, and how errors/cancellation are propagated.

## Mutable state

Native local mutation in do remains native elaboration. Shared mutable identity uses explicit reference/state abstractions.

## Native Lean IO/Task relationship

Native Lean `IO` and `Task` remain the low-level pinned substrate.

Portable `ps-standard` application APIs expose `App`, `Fiber`, `Resource`, and `Stream`.

Direct native `IO`/`Task` use is permitted only in modules explicitly marked as nonportable/native-adapter modules (or in `ps-lean-extensible`), and its capabilities/assumptions are reflected in the module/runtime manifest.

Thus the Standard model does not redefine Lean IO, but ordinary portable application code does not accidentally bypass capability/error/resource semantics through arbitrary native IO.

## JS mapping

A JS runtime may implement:

~~~text
App      -> cold PSC runtime description/state machine
run/fork -> Promise/event-loop machinery that starts work
Fiber    -> started handle plus cancellation controller/token
Resource -> bracket/finally runtime helper with cleanup shielding
Stream   -> PSC stream runtime plus adapters
~~~

A JavaScript Promise is normally already an eventual/running foreign handle and therefore adapts to the started/foreign-async side, not to the definition of cold `App`.

Promise rejection maps only through explicit failure/fault classification.

## Wasm mapping

Prefer versioned Component Model/WASI capabilities where they preserve the required behavior. WASI 0.3's `async func`, `future<T>`, and `stream<T>` are target mechanisms for implementing PSC's already-defined App/Fiber/Stream relations, not their source definition.

Map typed outcomes to variants/results and resources to explicit host resources. A weaker target must use a separately named weaker profile or reject.

## Contracts

Application specifications range over outcomes, state, and observable traces. A total pure theorem is not automatically a theorem about asynchronous IO behavior.

## Syntax policy

Do not add async, await, using, or other convenience syntax first. Prove and use the library semantics with ordinary functions/do. Add syntax only after the model and usability evidence justify it.

## Required conformance traces

The cross-target suite must cover success, typed failure, RuntimeFault, cancellation timing, timeout, races, child failure, detach, cleanup on every outcome, combined body/cleanup failure, stream backpressure, and late callbacks after disposal.

## Evidence status

Application semantic model (cold App, started Fiber, typed Exit, separate RuntimeFault, capability-indexed effects, structured scope, shielded Resource cleanup, Stream relation, native-IO boundary): **accepted for r3**.

Exact Lean library encoding: **not yet implemented/frozen at API-name level**.
JS runtime implementation/evidence: **not claimed by this documentation baseline**.
Direct Wasm implementation/evidence: **not claimed**.
Cross-target conformance: **not executed**.
Program-logic proof: **pending**.

# Appendix H — Embedded PSC Semantic Bundle v1

## H.1 Semantic-bundle normative prose

Status: **normative import protocol for `ps-standard` consuming checked semantic exports**

Schema: `SEMANTIC-BUNDLE-v1.schema.json`  
Schema identity: `psc-semantic-bundle-1.0.0`

## Purpose

A Standard package may depend on a library authored/elaborated under `ps-lean-extensible` without importing that library's parser, notation, macro, tactic-elaborator or host-meta side effects.

The boundary is a semantic bundle.

## Bundle layout

~~~text
<module>.psbundle/
  bundle.json
  declarations.bin
  runtime/
    ... optional target artifacts ...
~~~

`bundle.json` is UTF-8 JSON conforming to the schema.

`declarations.bin` uses versioned format `psc-checked-decls-v1`. Its internal binary encoding is owned by the checker/module-format version; a consumer MUST NOT trust it merely because it decodes.

## Required manifest identities

The manifest binds:

- logical module name;
- source profile and source identity;
- Lean semantic version/commit;
- checker/kernel identity;
- module-format version;
- source environment identity;
- direct dependency bundle identities;
- declaration payload hash/size;
- declaration name/kind/type/body identities;
- transitive/declared axiom dependencies;
- runtime exports and their artifact hashes, if any;
- evidence status;
- syntax/meta export list;
- build/host execution effect list;
- runtime/external assumption list.

For a bundle imported by `ps-standard`, both `syntaxMetaExports` and `hostBuildEffects` MUST be empty.

A semantic import therefore cannot install syntax/meta handlers and cannot require arbitrary dependency build/install code to execute merely to make checked declarations available.

## Import protocol

A Standard importer performs, in order:

1. validate `bundle.json` against the exact schema version;
2. verify semantic pin, checker/module-format compatibility and Standard registry policy;
3. verify every dependency bundle identity;
4. hash `declarations.bin` and compare size/hash;
5. recheck/import the declaration payload through the selected genuine checker protocol;
6. verify that imported declaration names/kinds/type/body identities match the checked payload;
7. recompute/report assumption dependencies under the active axiom policy;
8. accept runtime exports only under their separately declared runtime/ABI/evidence profile;
9. reject any syntax/meta export when importing into `ps-standard`;
10. reject any nonempty `hostBuildEffects` list for Standard semantic import;
11. record runtime/external assumptions separately from logical axiom dependencies.

A manifest Boolean such as `admitted: true` is never proof authority.

## Syntax/meta isolation

The bundle carries **no executable parser registration**.

The schema reserves `syntaxMetaExports` so an Extensible-to-Extensible transport can identify such exports, but Standard requires the array to be empty.

`hostBuildEffects` is separately recorded because logical syntax/meta side effects and operating-system/build execution permissions are different trust boundaries. Standard semantic import requires that list to be empty as well.

A theorem/type imported through the bundle cannot implicitly register notation, a macro, command elaborator, tactic or build script.

## Runtime exports

Runtime entries are optional and separately identified. A logical theorem bundle can be consumed without granting filesystem/network/process capability.

A runtime export records:
- target profile;
- ABI identity;
- artifact SHA-256;
- required capabilities;
- preservation/evidence status.

Logical admission does not imply target preservation.

The manifest-level `runtimeAssumptions` field records external/runtime relationships that are not logical axioms—for example a foreign library implementation assumption or a target ABI assumption.

## Canonical identity

The content hash of the complete `.psbundle` archive may identify distribution bytes, but the semantic import identity is the tuple of manifest/payload/dependency identities checked above.

Signatures may authenticate origin; they do not replace semantic checking.

## H.2 Semantic-bundle JSON Schema

The schema validates transport shape; logical correctness still requires the checking protocol described above.

~~~json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://proofscript.org/schema/psc-semantic-bundle-1.0.0.json",
  "title": "ProofScript Semantic Bundle v1 manifest",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "schemaVersion",
    "moduleName",
    "sourceProfile",
    "sourceIdentity",
    "leanSemantics",
    "checkerIdentity",
    "moduleFormatVersion",
    "environmentIdentity",
    "registryIdentity",
    "declarationPayload",
    "dependencies",
    "declarations",
    "axiomDependencies",
    "syntaxMetaExports",
    "runtimeExports",
    "evidence",
    "hostBuildEffects",
    "runtimeAssumptions"
  ],
  "properties": {
    "schemaVersion": {
      "const": "psc-semantic-bundle-1.0.0"
    },
    "moduleName": {
      "type": "string",
      "minLength": 1
    },
    "sourceProfile": {
      "enum": [
        "ps-standard",
        "ps-lean-extensible",
        "lean-native"
      ]
    },
    "sourceIdentity": {
      "$ref": "#/$defs/sha256"
    },
    "leanSemantics": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "version",
        "commit"
      ],
      "properties": {
        "version": {
          "const": "4.34.0"
        },
        "commit": {
          "const": "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b"
        }
      }
    },
    "checkerIdentity": {
      "type": "string",
      "minLength": 1
    },
    "moduleFormatVersion": {
      "const": "psc-checked-decls-v1"
    },
    "environmentIdentity": {
      "$ref": "#/$defs/sha256"
    },
    "registryIdentity": {
      "type": "string",
      "minLength": 1
    },
    "declarationPayload": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "path",
        "format",
        "sha256",
        "sizeBytes"
      ],
      "properties": {
        "path": {
          "const": "declarations.bin"
        },
        "format": {
          "const": "psc-checked-decls-v1"
        },
        "sha256": {
          "$ref": "#/$defs/sha256"
        },
        "sizeBytes": {
          "type": "integer",
          "minimum": 0
        }
      }
    },
    "dependencies": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "moduleName",
          "bundleManifestSha256"
        ],
        "properties": {
          "moduleName": {
            "type": "string",
            "minLength": 1
          },
          "bundleManifestSha256": {
            "$ref": "#/$defs/sha256"
          }
        }
      }
    },
    "declarations": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "name",
          "kind",
          "typeSha256"
        ],
        "properties": {
          "name": {
            "type": "string",
            "minLength": 1
          },
          "kind": {
            "enum": [
              "definition",
              "opaque",
              "theorem",
              "axiom",
              "inductive",
              "structure",
              "class",
              "instance"
            ]
          },
          "typeSha256": {
            "$ref": "#/$defs/sha256"
          },
          "bodySha256": {
            "anyOf": [
              {
                "$ref": "#/$defs/sha256"
              },
              {
                "type": "null"
              }
            ]
          }
        }
      }
    },
    "axiomDependencies": {
      "type": "array",
      "uniqueItems": true,
      "items": {
        "type": "string",
        "minLength": 1
      }
    },
    "syntaxMetaExports": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "runtimeExports": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "name",
          "targetProfile",
          "abiIdentity",
          "artifactSha256",
          "requiredCapabilities",
          "preservationStatus"
        ],
        "properties": {
          "name": {
            "type": "string",
            "minLength": 1
          },
          "targetProfile": {
            "type": "string",
            "minLength": 1
          },
          "abiIdentity": {
            "type": "string",
            "minLength": 1
          },
          "artifactSha256": {
            "$ref": "#/$defs/sha256"
          },
          "requiredCapabilities": {
            "type": "array",
            "uniqueItems": true,
            "items": {
              "type": "string",
              "minLength": 1
            }
          },
          "preservationStatus": {
            "enum": [
              "not-established",
              "tested",
              "translation-validated",
              "proved-fragment",
              "assumed"
            ]
          }
        }
      }
    },
    "evidence": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "logicalAdmission",
        "sourceCorrespondence",
        "erasurePreservation",
        "targetPreservation"
      ],
      "properties": {
        "logicalAdmission": {
          "enum": [
            "recheck-required",
            "checked"
          ]
        },
        "sourceCorrespondence": {
          "enum": [
            "not-established",
            "tested",
            "proved-fragment"
          ]
        },
        "erasurePreservation": {
          "enum": [
            "not-established",
            "tested",
            "proved-fragment"
          ]
        },
        "targetPreservation": {
          "enum": [
            "not-established",
            "tested",
            "translation-validated",
            "proved-fragment",
            "assumed"
          ]
        }
      }
    },
    "hostBuildEffects": {
      "type": "array",
      "uniqueItems": true,
      "items": {
        "type": "string",
        "minLength": 1
      }
    },
    "runtimeAssumptions": {
      "type": "array",
      "uniqueItems": true,
      "items": {
        "type": "string",
        "minLength": 1
      }
    }
  },
  "$defs": {
    "sha256": {
      "type": "string",
      "pattern": "^[0-9a-f]{64}$"
    }
  }
}
~~~

# Appendix I — Embedded InterfaceIR v1

## I.1 InterfaceIR normative prose

Status: **normative r3 binding interchange format**

Schema: `INTERFACEIR-v1.schema.json`  
Schema identity: `proofscript-interface-ir-1.0.0`

## 1. Resolution identity

An InterfaceIR file binds the runtime and type surfaces selected from an npm package. The identity includes:

- TypeScript version/profile;
- TypeScript `moduleResolution` mode;
- resolver profile `psc-node-exports-v1`;
- install/package-store identity and optional lockfile SHA-256;
- custom conditions;
- ordered effective export conditions;
- package name/version;
- exact `package.json` SHA-256;
- requested export subpath;
- ordered runtime condition trace;
- selected runtime entry, module format, and runtime-entry SHA-256;
- ordered type/declaration condition trace;
- selected declaration entry and declaration-entry SHA-256;
- every declaration-file SHA-256;
- target runtime/platform.

This is necessary because Node conditional exports can select different runtime entries and TypeScript's resolver can select explicit/versioned `types` conditions and custom conditions.

## 2. Resolution rule

The importer MUST use the declared TypeScript resolver/version for the type side and `psc-node-exports-v1` (or a future explicitly named resolver profile) for the runtime side.

It MUST record the complete ordered condition traces and the final selected entries rather than only the original module specifier.

The runtime entry bytes and selected type/declaration entry bytes are separately hashed. A package version or path alone is never sufficient binding identity.

If runtime/type entries cannot be shown to belong to the same requested package export surface under the recorded condition set, the binding rejects with `PS_DTS_EXPORT_CONDITION_MISMATCH`.

If the selected declaration branch is plausibly from a different conditional/export surface than the selected runtime branch and no explicit binding policy relates them, reject with `PS_DTS_RUNTIME_TYPE_BRANCH_MISMATCH`.

## 3. Support classes

Every declaration/type feature is classified as exactly one of:

- `native` — direct PSC type/value mapping;
- `specialized` — import-time finite specialization produces ordinary InterfaceIR;
- `runtime-adapter` — requires explicit conversion/lifetime/effect code;
- `opaque-handle` — identity-bearing foreign object;
- `import-normalization` — TypeScript-only type computation erased by a checked importer normalization result;
- `unsupported`.

Unsupported never becomes native `any`.

## 4. Required initial support matrix

| TypeScript / JS construct | r3 InterfaceIR treatment |
|---|---|
| string/boolean | native or checked text/bool adapter |
| number | runtime-adapter to chosen Float/checked Int/Nat domain |
| bigint | runtime-adapter; Nat checks nonnegativity |
| unknown / any | opaque ForeignValue; explicit refinement required |
| null / undefined / missing | explicit presence policy |
| arrays/tuples | adapter/native data according to copy/mutability policy |
| readonly | static metadata only; no deep-freeze theorem |
| literal/discriminated union | specialized/native variant where discriminator is defined |
| ambiguous structural union | runtime-adapter or unsupported |
| Promise | runtime-adapter to foreign async/App bridge |
| callback | runtime-adapter with retention/reentrancy/disposal metadata |
| class instance / DOM node | opaque-handle |
| receiver / `this` | explicit receiver metadata |
| simple generic | native/specialized when mapping is parametric and defined |
| overloads | specialized wrapper set or unsupported |
| conditional/mapped/template type | import-normalization for supported finite cases; otherwise unsupported |
| keyof / indexed access | import-normalization for finite schemas |
| branded type | validated wrapper, opaque brand, or explicit assumption |
| Iterable | runtime-adapter |
| AsyncIterable | runtime-adapter to Stream only with demand/cancel/cleanup semantics |
| type predicate/assertion signature | explicit runtime-refinement adapter; not proof by declaration alone |
| declaration/module augmentation | unsupported in Standard importer v1 unless normalized before InterfaceIR |
| callable/constructable object | explicit call/construct signatures; no implicit object-to-function coercion |

## 5. Raw, safe and specification layers

InterfaceIR records the **raw foreign shape**. Generated PSC packages may add:

- raw declarations;
- safe validators/codecs;
- resource/async adapters;
- optional logical models/specifications.

A specification about a foreign library remains an external model until implementation correspondence is separately established.

## 6. Presence

`missing`, `undefined`, `null` and `value` are distinct states in InterfaceIR.

A safe adapter may collapse them only through an explicit `presencePolicy` that reports lossiness.

## 7. Functions and effects

A function declaration records:
- receiver requirement;
- type parameters;
- parameters;
- result;
- sync kind;
- Promise/callback behavior;
- documented throw policy;
- effect/capability classification;
- overload group if any.

An arbitrary thrown JS value is not silently converted into the typed PSC error parameter.

## 8. Versioning

Changing the schema, resolver rules, support matrix or interpretation of a tagged node requires an InterfaceIR schema-version change.

The full binding identity includes the InterfaceIR bytes plus install identity, package.json identity, resolver profile, export subpath, ordered runtime/type condition traces, exact runtime-entry hash, exact type-entry/declaration hashes, TypeScript profile/version, target runtime/platform, and all referenced declaration hashes.

## I.2 InterfaceIR JSON Schema

The schema validates transport shape, not foreign implementation correctness.

~~~json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://proofscript.org/schema/interface-ir-1.0.0.json",
  "title": "ProofScript InterfaceIR v1",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "schemaVersion",
    "resolution",
    "declarations"
  ],
  "properties": {
    "schemaVersion": {
      "const": "proofscript-interface-ir-1.0.0"
    },
    "resolution": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "typescriptVersion",
        "moduleResolution",
        "customConditions",
        "effectiveConditions",
        "packageName",
        "packageVersion",
        "packageJsonSha256",
        "exportSubpath",
        "runtimeEntry",
        "runtimeFormat",
        "typesEntry",
        "declarationFiles",
        "targetRuntime",
        "targetPlatform",
        "installIdentity",
        "resolverProfile",
        "runtimeEntrySha256",
        "typesEntrySha256",
        "runtimeConditionTrace",
        "typeConditionTrace"
      ],
      "properties": {
        "typescriptVersion": {
          "type": "string",
          "minLength": 1
        },
        "moduleResolution": {
          "enum": [
            "node16",
            "nodenext",
            "bundler"
          ]
        },
        "customConditions": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "uniqueItems": true
        },
        "effectiveConditions": {
          "type": "array",
          "minItems": 1,
          "items": {
            "type": "string"
          }
        },
        "packageName": {
          "type": "string",
          "minLength": 1
        },
        "packageVersion": {
          "type": "string",
          "minLength": 1
        },
        "packageJsonSha256": {
          "$ref": "#/$defs/sha256"
        },
        "exportSubpath": {
          "type": "string",
          "minLength": 1
        },
        "runtimeEntry": {
          "type": "string",
          "minLength": 1
        },
        "runtimeFormat": {
          "enum": [
            "esm",
            "commonjs",
            "native-addon",
            "wasm",
            "other"
          ]
        },
        "typesEntry": {
          "type": "string",
          "minLength": 1
        },
        "declarationFiles": {
          "type": "array",
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "path",
              "sha256"
            ],
            "properties": {
              "path": {
                "type": "string",
                "minLength": 1
              },
              "sha256": {
                "$ref": "#/$defs/sha256"
              }
            }
          }
        },
        "targetRuntime": {
          "type": "string",
          "minLength": 1
        },
        "targetPlatform": {
          "type": "string",
          "minLength": 1
        },
        "installIdentity": {
          "type": "string",
          "minLength": 1
        },
        "lockfileSha256": {
          "$ref": "#/$defs/sha256"
        },
        "resolverProfile": {
          "const": "psc-node-exports-v1"
        },
        "runtimeEntrySha256": {
          "$ref": "#/$defs/sha256"
        },
        "typesEntrySha256": {
          "$ref": "#/$defs/sha256"
        },
        "runtimeConditionTrace": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "minItems": 1
        },
        "typeConditionTrace": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "minItems": 1
        }
      }
    },
    "declarations": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/declaration"
      }
    }
  },
  "$defs": {
    "sha256": {
      "type": "string",
      "pattern": "^[0-9a-f]{64}$"
    },
    "support": {
      "enum": [
        "native",
        "specialized",
        "runtime-adapter",
        "opaque-handle",
        "import-normalization",
        "unsupported"
      ]
    },
    "typeRef": {
      "oneOf": [
        {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "kind",
            "support"
          ],
          "properties": {
            "kind": {
              "enum": [
                "unit",
                "bool",
                "string",
                "number",
                "bigint",
                "unknown",
                "any",
                "null",
                "undefined",
                "foreignOpaque"
              ]
            },
            "support": {
              "$ref": "#/$defs/support"
            }
          }
        },
        {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "kind",
            "support",
            "element"
          ],
          "properties": {
            "kind": {
              "const": "array"
            },
            "support": {
              "$ref": "#/$defs/support"
            },
            "element": {
              "$ref": "#/$defs/typeRef"
            },
            "readonly": {
              "type": "boolean"
            }
          }
        },
        {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "kind",
            "support",
            "elements"
          ],
          "properties": {
            "kind": {
              "const": "tuple"
            },
            "support": {
              "$ref": "#/$defs/support"
            },
            "elements": {
              "type": "array",
              "items": {
                "$ref": "#/$defs/typeRef"
              }
            }
          }
        },
        {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "kind",
            "support",
            "fields"
          ],
          "properties": {
            "kind": {
              "const": "record"
            },
            "support": {
              "$ref": "#/$defs/support"
            },
            "fields": {
              "type": "array",
              "items": {
                "$ref": "#/$defs/field"
              }
            }
          }
        },
        {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "kind",
            "support",
            "members"
          ],
          "properties": {
            "kind": {
              "const": "union"
            },
            "support": {
              "$ref": "#/$defs/support"
            },
            "members": {
              "type": "array",
              "minItems": 1,
              "items": {
                "$ref": "#/$defs/typeRef"
              }
            }
          }
        },
        {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "kind",
            "support",
            "result"
          ],
          "properties": {
            "kind": {
              "enum": [
                "promise",
                "iterable",
                "asyncIterable"
              ]
            },
            "support": {
              "$ref": "#/$defs/support"
            },
            "result": {
              "$ref": "#/$defs/typeRef"
            }
          }
        },
        {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "kind",
            "support",
            "name"
          ],
          "properties": {
            "kind": {
              "enum": [
                "handle",
                "typeParam",
                "named"
              ]
            },
            "support": {
              "$ref": "#/$defs/support"
            },
            "name": {
              "type": "string",
              "minLength": 1
            }
          }
        }
      ]
    },
    "field": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "name",
        "type",
        "readonly",
        "presence"
      ],
      "properties": {
        "name": {
          "type": "string",
          "minLength": 1
        },
        "type": {
          "$ref": "#/$defs/typeRef"
        },
        "readonly": {
          "type": "boolean"
        },
        "presence": {
          "enum": [
            "required",
            "optional",
            "missing-or-undefined",
            "nullable",
            "explicit-four-state"
          ]
        }
      }
    },
    "parameter": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "name",
        "type",
        "optional",
        "kind"
      ],
      "properties": {
        "name": {
          "type": "string"
        },
        "type": {
          "$ref": "#/$defs/typeRef"
        },
        "optional": {
          "type": "boolean"
        },
        "kind": {
          "type": "string",
          "enum": [
            "required",
            "optional",
            "defaulted",
            "rest",
            "this"
          ]
        },
        "defaultSourceKnown": {
          "type": "boolean"
        }
      }
    },
    "declaration": {
      "oneOf": [
        {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "kind",
            "name",
            "support",
            "parameters",
            "result",
            "syncKind",
            "throwsPolicy",
            "sourceDeclarationSha256"
          ],
          "properties": {
            "kind": {
              "enum": [
                "function",
                "callSignature",
                "constructSignature",
                "constructor"
              ]
            },
            "name": {
              "type": "string",
              "minLength": 1
            },
            "support": {
              "$ref": "#/$defs/support"
            },
            "receiver": {
              "$ref": "#/$defs/typeRef"
            },
            "typeParameters": {
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "parameters": {
              "type": "array",
              "items": {
                "$ref": "#/$defs/parameter"
              }
            },
            "result": {
              "$ref": "#/$defs/typeRef"
            },
            "syncKind": {
              "enum": [
                "sync",
                "promise",
                "callback",
                "async-iterable",
                "unknown"
              ]
            },
            "throwsPolicy": {
              "enum": [
                "none-documented",
                "documented",
                "arbitrary-foreign",
                "unknown"
              ]
            },
            "overloadGroup": {
              "type": [
                "string",
                "null"
              ]
            },
            "sourceDeclarationSha256": {
              "$ref": "#/$defs/sha256"
            },
            "externalAssumptions": {
              "type": "array",
              "uniqueItems": true,
              "items": {
                "type": "string"
              }
            },
            "validationPolicy": {
              "type": "string"
            },
            "logicalModelIdentity": {
              "type": "string"
            }
          }
        },
        {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "kind",
            "name",
            "support",
            "fields",
            "sourceDeclarationSha256"
          ],
          "properties": {
            "kind": {
              "enum": [
                "interface",
                "class",
                "record"
              ]
            },
            "name": {
              "type": "string",
              "minLength": 1
            },
            "support": {
              "$ref": "#/$defs/support"
            },
            "fields": {
              "type": "array",
              "items": {
                "$ref": "#/$defs/field"
              }
            },
            "sourceDeclarationSha256": {
              "$ref": "#/$defs/sha256"
            },
            "externalAssumptions": {
              "type": "array",
              "uniqueItems": true,
              "items": {
                "type": "string"
              }
            },
            "validationPolicy": {
              "type": "string"
            },
            "logicalModelIdentity": {
              "type": "string"
            }
          }
        },
        {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "kind",
            "name",
            "support",
            "type",
            "sourceDeclarationSha256"
          ],
          "properties": {
            "kind": {
              "enum": [
                "const",
                "typeAlias",
                "enum",
                "namespace"
              ]
            },
            "name": {
              "type": "string",
              "minLength": 1
            },
            "support": {
              "$ref": "#/$defs/support"
            },
            "type": {
              "$ref": "#/$defs/typeRef"
            },
            "sourceDeclarationSha256": {
              "$ref": "#/$defs/sha256"
            },
            "externalAssumptions": {
              "type": "array",
              "uniqueItems": true,
              "items": {
                "type": "string"
              }
            },
            "validationPolicy": {
              "type": "string"
            },
            "logicalModelIdentity": {
              "type": "string"
            }
          }
        }
      ]
    }
  }
}
~~~

# Appendix J — Embedded pre-stable / 1.0 evidence gates

Status: **normative release-evidence plan; no gate is claimed completed by this documentation pass**

The accepted r3 design can exist before these gates run.

A stable/1.0 language-surface or stronger end-to-end assurance claim requires the relevant gates below.

## 1. Evidence labels

Keep separate:

~~~text
specified
research-reviewed
prototype-tested
oracle-tested
human-studied
formally-proved-model
production-refined
translation-validated
backend-preserved-fragment
full-app-tested
artifact-bound
external-assumption
~~~

No single verified boolean replaces these labels.

## 2. Usability gate

Use the protocol in 13-USABILITY-STUDY.md.

Minimum target cohort:

- 18 TypeScript developers: 6 junior, 6 mid, 6 senior;
- 6 Lean users with mixed theorem/application experience.

Required high-risk tasks:

- f(x) versus f (x);
- f((x,y)) versus f(x,y);
- f() with zero-source-arg function;
- f() with default-only function;
- f() rejection when required explicit parameters remain;
- call line break before parenthesis;
- structural braces and no trailing field comma;
- const semantics;
- Option versus undefined/null;
- typed failure versus runtime fault;
- contract pre/post meaning;
- source proof versus backend correctness.

### Pre-registered criteria

Before stable/1.0:

- no accepted syntax rule may show a persistent high-confidence semantic misconception rate without either redesign or explicit teaching/diagnostic mitigation;
- const remains subject to the existing comprehension threshold/review;
- the empty-call/default rule must perform materially better than the old Unit-only explanation on default-parameter tasks;
- structural braces must materially reduce member-boundary misunderstandings compared with r2 hybrid braces.

Preference alone is not a pass criterion.

Status: **pending; no participants run in this documentation pass**.

## 3. Frontend formal gate

First formal targets:

1. r3 call ownership model;
2. exact CallGap/no-bare-newline property;
3. empty-call canonical lowering to native ellipsis application;
4. acceptance predicate excluding omitted required explicit arguments;
5. zero-arg declaration lowering to optional Unit;
6. structural brace ownership/member-boundary model;
7. binding/hygiene preservation for the selected fragment;
8. production AST/refinement relation.

Required theorem classes:

~~~text
ownership determinism
lowering well-formedness
protected native-neighbor/profile behavior
binding preservation
source/canonical interpretation correspondence
production refinement for the proved fragment
~~~

Status: **planned, not executed here**.

## 4. Backend preservation gate

Start with a pure restricted RuntimeIR:

~~~text
Bool
exact Nat literals/addition/multiplication
local immutable bindings
pure function calls
small ADTs/matches
~~~

Define:

- source semantics;
- target AST/semantics;
- value relation;
- lowering;
- serializer relation;
- exact artifact relation.

Prove/validate an explicit preservation theorem before extending claims to more primitives.

Then add strings, exact Int operations, closures, recursion, and effects incrementally.

Status: **planned, not executed here**.

## 5. Primitive/runtime conformance gate

For every executable target profile, maintain a primitive matrix covering at least:

- Nat addition/multiplication/subtraction/division/remainder;
- Int signed division/remainder including negative cases;
- fixed-width integer operations;
- Bool;
- Char/String/ByteArray conversions;
- List versus Array representation/operations;
- constructor/tag representation;
- closure calling convention;
- noncomputable/partial/unsafe boundaries.

Each entry records:

~~~text
source declaration identity
target implementation
representation relation
edge-case behavior
evidence status
runtime assumptions
~~~

Unknown reachable primitive = target build rejection.

Status: **pending**.

## 6. Application semantics gate

For psc-app-v1, cross-target traces must exercise:

- cold App construction;
- run/fork start;
- Fiber join;
- typed failure;
- RuntimeFault separation;
- cancellation races;
- structured scope exit;
- detach;
- shielded cleanup;
- cleanup failure combinations;
- timeout/Clock;
- Stream demand/backpressure;
- Stream cancellation;
- Promise late completion;
- foreign callback after disposal.

Run the same semantic scenarios against direct JS and direct Wasm/WASI profiles where both advertise the capability.

Status: **pending**.

## 7. InterfaceIR/npm gate

Use real packages from several API shapes:

1. pure utility/data package;
2. schema/JSON validation package;
3. Promise-based HTTP API;
4. callback/event-emitter API;
5. receiver/class API;
6. UI/DOM-facing declarations;
7. package using conditional exports/subpaths;
8. advanced conditional/mapped/template types;
9. intentionally unsupported global/module augmentation case.

Required outcomes:

- exact runtime/type resolution identities;
- successful InterfaceIR generation for supported cases;
- explicit failure for unsupported cases;
- runtime validation where needed;
- generated PSC-exported declaration files checked by a clean TypeScript consumer;
- no hidden any fallback.

Status: **pending**.

## 8. Reference application gate

Before "full-app ready":

1. file-transform CLI;
2. HTTP/service application;
3. browser UI application using npm bindings;
4. published PSC npm library consumed by TypeScript;
5. verified domain/state-machine package.

Record:

- PSC handwritten source;
- handwritten foreign glue;
- generated code;
- assumptions;
- build/test results;
- proof results;
- target profile;
- runtime adapters;
- artifact identities.

No application is counted complete when essential logic is implemented only in handwritten JS/TS while being presented as PSC.

Status: **pending**.

## 9. Standard profile gate

Before stable Standard:

- materialize exact parser/tactic/attribute/deriving registration closure;
- publish registration-closure SHA-256;
- verify forbidden syntax/meta registrations fail closed;
- verify semantic bundles install no syntax/meta effects;
- exercise LSP/formatter across the full Standard grammar;
- verify cache invalidation on semantic/profile/environment changes.

Status: **pending**.

## 10. Contract gate

For psc-contract-core-v1:

- pure requires/ensures implementation identity;
- multiple clause conjunction;
- Except outcome property through ordinary match;
- changed predicate dependency invalidates evidence;
- axiom-policy rejection;
- higher-order callRequires/callEnsures model;
- empty effect/read/write frame for pure functions;
- effect/frame violation detected in the first effectful program-logic profile.

Status: **pending**.

## 11. Artifact/release gate

A stronger executable claim binds:

~~~text
source snapshot
canonical declaration bundle
checked module
runtime IR
target AST
serialized file
linked runtime/helper artifacts
package/export resolution
compile/link/bundle options
assumptions
~~~

to exact immutable identities.

Post-check edits, bundling, minification, framework transforms, and target compiler steps remain assumptions or receive separate evidence.

Status: **pending**.

## 12. Stable/1.0 decision

A stable/1.0 review receives:

- usability report;
- formal-proof report;
- conformance matrices;
- reference-application results;
- open-question status;
- migration assessment;
- any proposed syntax changes caused by evidence.

The review may still revise r3 surface rules before 1.0.

This document creates no presumption that an accepted r3 design must survive contradictory evidence unchanged.

# Appendix K — Complete inherited ProofScript v0.9-r2 baseline

## K.1 How to read this embedded baseline

The exact r2 reference below is included **inside this file** so no separate r2 document is required.

For r3:

- Parts I–XXV and Appendices A–J override r2 where they explicitly differ.
- Every r2 rule not overridden remains normative in r3.
- Historical r2 grammar identity remains `ps-0.9-r2`; it is not the r3 grammar identity.
- r2 evidence remains historical evidence about the recorded r2 programs/environment and is not automatically new r3 frontend evidence.

## K.2 Exact r2 reference

# The ProofScript Language Reference v0.9.0

**Compiler-oriented reference candidate · draft revision 2 · 3 October 2026**  
**Design:** a small, TypeScript-friendly surface over faithfully preserved Lean 4 semantics.  
**Normative semantic pin:** Lean **4.34.0**, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`.  
**Source lineage:** ProofScript v0.7.0; v0.6.1 supplies compatible historical context.  
**Grammar identity:** `ps-0.9-r2` / `lean-native-separators`; supersedes the earlier v0.9 draft's ProofScript-only semicolon rules.  
**Status:** proposed specification, not a released compiler, a proof of soundness, or a claim of complete Lean frontend implementation.

This document specifies the ProofScript-owned grammar, its composition with a pinned Lean grammar, canonical lowering, semantic and runtime boundaries, compiler interfaces, and conformance obligations. It is designed to be implemented rather than merely to describe attractive future features. The inherited language is specified by exact reference, not by a second, approximate transcription of Lean's entire extensible grammar.

A feature marked **specified** has a proposed contract. **Oracle-tested examples** are particular canonical Lean programs checked during this research. Neither label means that a production ProofScript parser has been proved correct. The original research and execution record is in [the study audit](research/STUDY_AUDIT.md). Revision-specific changes and validation are in [the revision notes](REVISION_NOTES_R2.md) and [semicolon evidence](research/SEMICOLON_REVISION_AUDIT.md).

> **Make Lean easier to approach; do not make its meaning approximate.**

## Contents

- [Part I — Identity, authority, and conformance](#part-i--identity-authority-and-conformance)
- [Part II — Lexical syntax and grammar composition](#part-ii--lexical-syntax-and-grammar-composition)
- [Part III — Declarations, functions, and data](#part-iii--declarations-functions-and-data)
- [Part IV — Computation, effects, and modules](#part-iv--computation-effects-and-modules)
- [Part V — Logic, theorem proving, and verification](#part-v--logic-theorem-proving-and-verification)
- [Part VI — Compiler and preservation contracts](#part-vi--compiler-and-preservation-contracts)
- [Part VII — Libraries, interoperability, and applications](#part-vii--libraries-interoperability-and-applications)
- [Part VIII — Tooling, migration, and release assurance](#part-viii--tooling-migration-and-release-assurance)
- [Part IX — Consolidated grammar and reference tables](#part-ix--consolidated-grammar-and-reference-tables)
- [Part X — Research basis and implementation sequence](#part-x--research-basis-and-implementation-sequence)

---

# Part I — Identity, authority, and conformance

## 1. Purpose and design principles

ProofScript is a general-purpose programming and theorem-proving language whose verified meaning is obtained through Lean-compatible elaboration and kernel admission. It supports ordinary application programming, mathematical definitions, proofs, and explicit program specifications. A developer need not prove a functional-correctness theorem for every function merely to write a typed application.

The design chooses a small number of visible decorations: familiar declaration aliases, comma-separated calls and parameters, and braces in named grammatical categories. It retains Lean vocabulary where changing the spelling would hide an important concept: `Prop`, `Type`, `Sort`, `def`, `theorem`, `structure`, `inductive`, `class`, `instance`, `fun`, `match`, `with`, `where`, `by`, `do`, `:=`, and equality.

The priorities, in order, are:

1. Preserve the declared meaning and accurately report evidence and assumptions.
2. Keep the surface grammar regular within each category and preserve established source distinctions.
3. Make everyday functions, records, collection APIs, errors, modules, and application tooling approachable.
4. Reuse existing semantic mechanisms instead of introducing parallel type, effect, or proof systems.
5. Make elaboration, lowering, and foreign boundaries inspectable.
6. Optimize only under the relevant semantic and representation obligations.

Small kernel size and user-facing simplicity are separate budgets. Moving a complicated feature into an elaborator removes neither its learning cost nor its interactions. Go's engineering account informs the emphasis on tools, dependency control, and maintenance; it does not require copying Go's type system. [G1]

**Non-goals of the base surface:** parsing arbitrary TypeScript; preserving arbitrary JavaScript dynamic behavior; changing Lean's typeclass search; adding prototype inheritance, truthiness, unchecked casts, implicit nullability, or a new effect calculus; making every mathematical definition executable; or equating type checking with verified application behavior.

## 2. Normative language and authority

**MUST**, **MUST NOT**, **SHOULD**, and **MAY** express requirements for a future implementation claiming this reference. An example is informative unless identified as a conformance case. An example's spelling alone does not authorize a new production.

Authority is ordered as follows:

| Concern | Authority |
|---|---|
| ProofScript-owned syntax and lowering | This v0.9 document and its matching feature registry. |
| Inherited syntax and elaboration | The pinned Lean source, its selected imports, parser registrations, and options. |
| Logical declaration checking | The selected pinned Lean logical profile and explicit axiom policy. |
| Executable primitives | Exact selected declaration/runtime definitions and the executable profile. |
| Historical source interpretation | The specification selected by that source's declared edition. |
| Tutorial and design explanation | Informative only; cannot override the authorities above. |

The repository baseline inspected was `65369c75c7b63124f1ba7f2289e573181db281f0`. The v0.7 reference blob is `8b4097363c5ade7d594b66706b94dff62400ff53`. Its canonical Lean pin is retained. Choosing a newer Lean patch requires an explicit reference revision and new evidence; the word “latest” is not a semantic identity. [R1, R2]

The v0.7 package describes a candidate reference with S1 evidence and a production-migration caveat. This new candidate does not retroactively close those gates, supersede old repository policies, or activate v0.9 in the current compiler. A compiler MAY reject the entire v0.9 profile until it implements the relevant contracts.

## 3. The central semantic relationship

For source `p` in environment `E`, define the intended meaning by the partial canonical lowering relation:

```text
parsePS09(E, p) = syntax
lower09(E, syntax) = canonicalLeanSyntax
meaningPS09(E, p) := meaningLean434(lowerEnv(E), canonicalLeanSyntax)
```

“Partial” here means that unsupported, malformed, or incompatible input is rejected. It is not permission for successful lowering to leave semantic holes.

The environment includes imports, module identities, macro and notation registrations, options, instances, declaration dependencies, and the selected profile. Meaning is not a function of source characters in isolation.

For a logical claim, the native interpretation is the admitted declaration environment. For an execution claim, it also includes the selected native executable semantics and primitive/runtime models. Kernel normalization alone is not an execution model for arbitrary partial definitions, IO, or runtime replacements. The execution relation must be stated separately where those constructs are involved.

A reference implementation MAY use official Lean to elaborate the canonical output. A standalone implementation MAY implement the same supported elaboration itself. Absence of Lean at runtime changes implementation dependencies, not the meaning of accepted programs.

This definition does not by itself prove that a parser, lowerer, source printer, standalone elaborator, kernel executable, or backend implements the intended relation. Each has its own proof or validation obligation. A valid proof of a changed proposition remains a proof of the wrong claim.

## 4. Source files and source identity

### 4.1 `.ps`

A `.ps` file uses the selected ProofScript edition. It may contain inherited Lean forms and the registered decorations/exceptions of that edition. It is not a `.lean` file with a different extension. Canonical lowering may change punctuation, declaration keywords, and AST structure while preserving the specified meaning.

### 4.2 `.lean`

A `.lean` file uses native Lean syntax under the pinned environment. ProofScript-only productions MUST NOT be injected into its parser. A standalone compiler can support a documented subset; valid native Lean outside that subset is **unsupported**, not a license to reinterpret it.

### 4.3 `.psx`

The suffix identifies an explicitly selected non-base source or extension profile. It does not imply automatic verification, JSX compatibility, or a particular UI language. An optional UI profile must name its grammar, expansion, environment, and assurance boundaries. The ordinary component library must remain usable from `.ps` and supported `.lean`.

### 4.4 Unique module input

Each logical module resolves to one exact source snapshot. When both `M.ps` and `M.lean` are present, a manifest must explicitly select one or the build rejects ambiguity. A generated `.lean` trace is not a fallback source. Missing dependencies MUST NOT be replaced with stale siblings, different branches, or host-installed packages silently.

Generated inputs must identify their generator and source provenance. Incremental checks and release publication must operate on the bytes actually checked, not reread a mutable file after approval.

## 5. Capabilities and implementation profiles

There is one semantic language, with separately reported implementation capabilities. Capabilities restrict coverage; they MUST NOT change a construct's meaning.

| Profile family | Meaning |
|---|---|
| `reference-lean434` | The overlay lowers supported source for the pinned official Lean environment. |
| `standalone-lean434` | An owned frontend/checker implements an explicitly listed subset of that meaning. |
| `exec-js`, `exec-ts`, `exec-rust`, `exec-wasm` | A supported executable closure and target runtime/ABI. |
| `intrinsic-contracts-434` | The experimental pinned intrinsic-verification environment. |
| `host-meta` | Explicit host metaprogramming and its execution permissions. |
| Named extension profile | Additional versioned syntax or library environment with its own evidence. |

An implementation manifest MUST enumerate supported feature IDs and inherited category registrations, with their dependencies. “Supports Lean” is insufficient. Grammar coverage, elaboration coverage, logical coverage, tactic/library coverage, runtime coverage, and preservation coverage are different fields.

A bootstrap implementation subset can be smaller than the public profile. A compiler does not need to use every feature it implements. Full applications are a platform goal, not a requirement that the compiler bootstrap depend on all platform libraries.

## 6. Acceptance results and assurance labels

The public checking interface distinguishes at least:

```text
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
```

Only the appropriate accepted result authorizes the exact requested claim. Unknown versions, exhaustion, internal exceptions, or failed checks MUST NOT become successful verification. A resource limit is not evidence that the proposition is false.

Reports distinguish: source parsed; source elaborated; declarations admitted; contract theorem proved; termination proved; source correspondence evidenced; erasure preserved; target preserved; and external assumptions. Tests and execution observations are separately recorded.

Retain the v0.7 evidence ladder where useful: S1 specified, S2 reference properties proved, S3 production implementation refined/validated, S4 formal-model connection, and S5 correspondence to a pinned official implementation. An ordinary successful Lean example is not S2 for a ProofScript overlay.

## 7. TypeScript-oriented design choices

TypeScript's documented strengths include contextual inference, generics, object-shaped APIs, discriminated unions, modules, and editor-oriented workflows. Its structural compatibility and deliberate soundness tradeoffs serve JavaScript compatibility. ProofScript uses the workflow lessons without importing those tradeoffs into its logic. [T1–T4]

| Familiar task | ProofScript mechanism | Deliberate difference |
|---|---|---|
| Define a function | `function f(x: T): U := e` | No hoisting, `this`, or universal return statement. |
| Define a constant | `const x: T := e` | Alias of a Lean definition, not object freezing. |
| Call with arguments | `f(x, y)` | Canonically curried Lean application. |
| Model records | `structure ... where { ... }` | Declared nominal/logical identity. |
| Model alternatives | `inductive` plus `match` | Exhaustive, potentially dependent elimination. |
| Generic function | Implicit `{α: Type}` and inference | No substitution of TS `<T>` for dependent binders. |
| Callback | `fun x => e` | One unambiguous lambda vocabulary. |
| Optional data | `Option α` | No implicit null/undefined. |
| Recoverable failure | `Except ε α` or an explicit user-defined result type | No silent import of host exceptions. |
| Async platform work | Native effects or a separately named library model | Promise does not define Lean `Task`. |
| Dynamic API input | Opaque foreign value followed by validation | No unchecked path to arbitrary proof-bearing data. |

The base does not add every attractive spelling. Optional chaining, JSX, bare arrow lambdas, ES-style imports, and brace-bodied functions can each be studied, but none is implicitly accepted by this reference.

---

# Part II — Lexical syntax and grammar composition

## 8. Character stream, comments, and positions

The base uses the pinned Lean lexical treatment of identifiers, literals, Unicode, escaping, and tokens. Compiler transport accepts UTF-8 source and MUST preserve a mapping from original byte offsets to editor positions. An implementation must not silently normalize identifiers or Unicode characters into different names.

Lean comments are retained:

```proofscript
-- A line comment.
/- A block comment, with /- nesting -/ where Lean allows it. -/
```

Documentation comments retain their native categories. Text inside comments, strings, character literals, quotations, and antiquotations is not rewritten as ordinary expression syntax.

JavaScript `//` and `/* ... */` comments are not added by the base profile. The v0.7 discussion used C-style comment-shaped text in an adjacency example; this reference uses the actual inherited spelling `f/- comment -/(x)`. That source declines D-CALL ownership. It does not turn arbitrary C-style text into a Lean comment.

Source spans MUST preserve the distinction between actual adjacency and separation by whitespace or comments. Normalizing away trivia before deciding ownership is incorrect.

## 9. Identifiers, keywords, and hygiene

Inherited identifier forms include the pinned native escaped and hierarchical identifiers. `const` and `function` are contextual declaration-head aliases. Their ownership requires the matching declaration production; the implementation MUST NOT globally rewrite every occurrence of those words.

An identifier with a familiar foreign spelling is not necessarily forbidden. A user may define an ordinary Lean-compatible name. The prohibition is on introducing a privileged `any` type, implicit truthiness, or another semantic escape merely from a spelling.

Names introduced by lowering MUST be hygienic. Preserve user binding identity and native macro scopes/pre-resolved references; do not rely on a “sufficiently unusual” textual prefix. Generated name allocation must either establish freshness or reject exhaustion. An unchecked `_overflow` fallback is not a freshness algorithm.

ProofScript-owned lowering normally introduces no new logical names. When auxiliaries are unavoidable, their scope, dependency, provenance, and relationship to source declarations must be explicit. [L7]

## 10. Punctuation and grammatical categories

| Token | Meaning in its relevant category |
|---|---|
| `:=` | Definition body, binding, named-argument assignment, or structure update as specified. |
| `=` | Propositional equality, not native assignment. |
| `==` | Boolean comparison through the selected Lean machinery. |
| `=>` | Native lambda/match/tactic binder delimiter where that category admits it. |
| `->` / `→` | Native function/Pi arrow. |
| `{ ... }` | A specific registered body, native record, binder, tactic block, or do sequence—not one universal block. |
| `;` | Only the role assigned by the corresponding pinned native Lean category; never a general ProofScript declaration terminator. |
| `<;>` | Native tactic combinator; distinct from a plain tactic-sequence `;`. |
| `,` | Call/header separator in a registered decoration; native meaning elsewhere. |
| `.` | Native hierarchical name/projection/generalized field notation under its own rules. |

No pass may globally erase semicolons, replace braces, introduce spaces before every parenthesis, replace `=` with `:=`, or strip `then` from arbitrary source. Canonical lowering operates on owned AST nodes and declared child slots.

## 11. Surface classes

| Class | Name | Requirement |
|---|---|---|
| L | Inherited Lean | Use the pinned category and its meaning. |
| D | Conservative decoration | Match a specified discriminator without displacing protected native neighbors. |
| E | Surface exception | Own an explicitly delimited category/context, with deterministic canonical lowering. |
| X | Semantic divergence | Excluded from the Lean-compatible base. |

A registered E form may intentionally differ from native parsing. The reference therefore does not promise that every string accepted by Lean receives identical parsing as `.ps`. It promises inherited behavior for L forms, protected-neighbor preservation for D forms, and documented ownership for E forms.

The parser must commit after a decisive owned prefix. A malformed owned construct cannot be retried as a permissive native fragment merely to get a successful parse. Conversely, when the discriminator never matched, ordinary native parsing remains available.

## 12. Grammar composition and inherited grammar

For each category `C`, parsing uses:

```text
1. the registered E production whose context and discriminator match;
2. the registered D production whose discriminator matches;
3. the exact selected native parser for C;
4. a diagnostic when no supported production succeeds.
```

`DEFER` is a parser-ownership result, not an assertion that input is valid. A standalone parser must implement the inherited forms it advertises. It cannot store unparsed strings and treat them as semantically admitted.

The composition operator is:

```text
Lift(P) = native production P with only its registered child-category slots
          replaced by the corresponding ProofScript-aware parser/lowerer.
```

All other children, delimiters, precedence, options, and binding information are preserved. A lifted `fun` body may contain a decorated term; its binder grammar remains native. A match RHS may contain D-CALL; its patterns do not gain constructor-call syntax. A tactic's explicit term argument can use the selected term category without changing tactic semicolon combinators.

The exact inherited production source is `study/lean4-4.34.0/src/Lean/Parser/`, including `Basic`, `Term`, `Do`, `Command`, `Tactic`, `Module`, `Level`, `Attr`, `StrInterpolation`, and `Syntax`, plus parser registrations introduced by the pinned declared imports. This is normative incorporation by reference. It is not a claim that a small EBNF reproduces all of Lean's extensible grammar. [L1–L3]

## 13. Precedence, grouping, and expression boundaries

Native precedences and operator registrations remain authoritative. D-CALL is a postfix operation on a syntactically completed callable head. It binds before an enclosing whitespace application consumes that head as an argument.

```text
f(x) + y       lowers to (f x) + y
g f(x)         lowers to g (f x)
(g f)(x)       lowers to (g f) x
f(x).field     lowers to (f x).field
f(x)(y)        preserves the two syntactic application groups
```

Preserve grouping boundaries that can affect elaboration, optional arguments, or expected types. Lowering MUST NOT flatten every nested call into one argument list. Within a single D-CALL, preserve one native application argument sequence for elaboration; binary core application is constructed later by the native elaborator.

A completed head is an identifier (including a supported dotted constructor identifier), a parenthesized term, a projection/indexing expression whose native grammar produces a completed head, or an already completed D-CALL. Imported syntax may serve as a head only through an explicit compatible category registration. Parenthesize an arbitrary lower-precedence term before calling it.

Argument parsing stops at a comma or the matching `)` only at the call's own delimiter depth. Delimiters in records, strings, lambdas, nested calls, quotations, or native syntax are not separators of the outer call.

## 14. D-CALL: positional, empty, and grouped calls

**Feature ID:** `D-CALL`.

The opening `(` must begin immediately after the end of the callable head in the original source. Whitespace or a comment breaks that discriminator.

```proofscript
add(1, 2)
normalize(transform(x))
f()
f((x, y))
```

Canonical forms:

```lean
add 1 2
normalize (transform x)
f ()
f (x, y)
```

An empty argument list denotes **one Unit argument**. It does not mean “invoke a zero-parameter function,” “instantiate only implicit parameters,” or “supply every default.” Parameterless constants are referred to without a call; a thunk has an explicit `Unit → α` type or another named suspension abstraction.

Protected neighbors:

| Source | Ownership and interpretation |
|---|---|
| `f(x, y)` | D-CALL; two native application arguments. |
| `f((x, y))` | D-CALL; one product/tuple argument. |
| `f (x, y)` | Native application to one tuple. |
| `f (x)` | Native application to one parenthesized term. |
| `f/- comment -/(x)` | No D-CALL ownership; the native parser decides. |

D-CALL is not enabled in patterns. `.some(x)` is not a constructor pattern. A constructor term `.some(x)` is a term-level call when its native contextual constructor resolution is supported.

## 15. v0.9 call conveniences: explicit named arguments and trailing commas

Two narrowly defined additions are specified for the v0.9 overlay. They are new S1 requirements, not claims of existing compiler implementation.

### 15.1 `D-NAMED-CALL`

An argument in a D-CALL can be `name := PS_TERM`. It lowers to the native named-argument node `(name := loweredTerm)` within the same application sequence.

```proofscript
connect(host, timeout := 5000)
```

```lean
connect host (timeout := 5000)
```

A named argument is recognized only at an argument start when the next tokens are an identifier and `:=`. It is not a general assignment expression. `timeout: 5000` is not this grammar.

Duplicate names within the same call are rejected with a direct diagnostic. Names are resolved according to native parameter names; unavailable names and impossible applications are elaboration errors. Positional and named arguments retain native matching, implicit insertion, dependent elaboration, and default semantics. The lowerer must not invent TS overload dispatch or reorder evaluation on the basis of source keyword order.

Native named arguments in whitespace application remain available without this feature. This addition removes no protected neighbor.

### 15.2 `D-TRAILING-COMMA`

A **nonempty** decorated call or comma-separated explicit header group MAY end with one trailing comma. The comma carries no argument or binder and is omitted in canonical lowering.

```proofscript
add(1, 2,)
function add(x: Nat, y: Nat,): Nat := x + y
```

Empty entries, doubled commas, and `f(,)` are rejected. A trailing comma is not applied to inherited tuple/pattern syntax by this rule. These constraints make multiline editing convenient without changing the function model.

## 16. Declaration boundaries and native semicolons

**Policy:** ProofScript introduces no general statement/declaration terminator. Semicolons occur only where the corresponding pinned Lean category admits them. This policy is part of grammar revision `ps-0.9-r2`, not a formatting-only option.

The ordinary decorated definition shape is:

```text
[modifiers] (def | const | function) name header := body suffixes
```

No outer `;` follows the definition. Its body and suffixes have the same boundary discipline as the canonical native definition. This applies equally to a literal, application, record, conditional, match, proof term, or `do` expression. Aliases and decorations do not choose a different termination convention.

```proofscript
function activate(user: User): User :=
  { user with active := true }

function getOrElse(value: Option Nat, fallback: Nat): Nat :=
  match value with {
    | .none => fallback
    | .some x => x
  }
```

The brace closes its own record or match construct. A declaration boundary is determined by the enclosing native-compatible grammar, including layout, nesting, and suffixes—not by appending a semicolon or treating every newline as an end token.

### 16.1 Native roles are preserved

| Context | Revision-2 rule |
|---|---|
| `def`, `const`, `function`, theorem and other declaration kinds | No added command terminator; use the corresponding native body/suffix boundary. |
| Structure/class field **declarations** | Native `structFields` layout; no added field semicolons. |
| Inductive constructors and match alternatives | Native constructor/alternative markers and layout; no added alternative terminator. |
| Instance `where` field **initializers** | Preserve native `whereStructInst` / `sepByIndent` separators, including `;` where admitted. |
| Local `where` declarations | Preserve native local-declaration sequence separators, including optional/trailing `;` where admitted. |
| Local `let` expression | Preserve native `let x := value; body` and its layout form. |
| `do` sequence | Preserve native semicolon/newline sequencing and its nested scopes. |
| Tactic sequence | Preserve native `;` sequencing and the different `<;>` combinator. |
| Record **values** | Preserve native field-assignment syntax and comma/layout rules; do not substitute structure-declaration separators. |
| Literal, comment, quotation, or antiquotation | Never edit punctuation by textual appearance; parse in its own category. |

A semicolon that happens to be the last token on a line is not necessarily a declaration terminator. For example, it can belong to the final native `do` element, an instance-field sequence, or a local-declaration sequence. The parser and formatter must decide ownership from the syntax tree, not from a trailing-character test. [L2–L3]

```proofscript
function calculate(x: Nat): Nat :=
  let y := x + 1; y * 2

function compact(_: Unit): Nat :=
  Id.run(do { let mut x := 1; x := x + 1; return x; })

theorem twoTruths: True ∧ True := by {
  constructor; trivial; trivial
}

theorem twoTruthsAll: True ∧ True := by {
  constructor <;> trivial
}
```

Plain `;` sequences tactics; `<;>` applies the second tactic to each goal produced by the first. They must not be interchanged by desugaring or formatting. These examples illustrate inherited forms; the new evidence tests their canonical Lean counterparts, not a production PSC parser.

### 16.2 Braced decorations retain category structure

Braces remain optional registered surface decorations, not JavaScript statement blocks. `E-STRUCT-BODY` and `E-CLASS-BODY` wrap lifted native field sequences; `E-INDUCTIVE-BODY` wraps native constructor sequences; `E-MATCH-BODY` wraps native alternatives. `E-INSTANCE-BODY` and `E-WHERE-BODY` preserve the native sequence parsers that already admit semicolons in those contexts.

At an owned opening brace, establish a sequence-local position/layout scope. The first member establishes the sequence position according to the native sequence parser; subsequent members and continuation lines retain that parser's indentation and boundary checks. The matching closing brace ends only that owned sequence. Nested records, matches, quotations, tactics and `do` blocks establish their own scopes. Braces MUST NOT disable the native indentation checks inside members or turn each newline into a separator. Section 76 incorporates the exact native sequence combinators.

A single-member body may be compact where the native member grammar permits it. Multiple field declarations should use separate, consistently indented lines. Do not replace removed match/constructor/field terminators with commas or another invented general separator. Native marker and sequence rules decide which compact forms are possible. A same-line sequence accepted by native grammar remains distinct from a newline-based formatting convention.

A match RHS can contain `let y := e; body`, `by { ...; ... }`, or `do { ...; ... }`. Those nested semicolons remain part of the RHS; they never terminate the match alternative. An inner match's `|` must not be stolen as an outer alternative. Native layout, delimiter depth and parser continuation state resolve that nesting.

### 16.3 Boundaries, errors and migration

Keep native continuation rules for multiline applications, expressions, tactic bodies, `termination_by`, `decreasing_by`, `where`, and supported verification suffixes. Do not add JavaScript-style automatic semicolon insertion, a global newline-termination heuristic, or a preprocessing pass that strips semicolons.

A `;` that no valid active native subcategory can consume is rejected with `PS_UNEXPECTED_SEMICOLON` or the corresponding precise native syntax error. The diagnostic may suggest an explicit v0.7/earlier-draft migration, but the compiler MUST NOT retry another grammar silently. Missing layout/boundary structure is `PS_INVALID_LAYOUT` where attributable to the owned sequence, not permission to merge members or infer a missing terminator.

`D-DECL-SEMI` and `PS_MISSING_DECL_SEMICOLON` are retired from this revised default grammar. Historical source keeps its old interpretation through an explicitly selected legacy reader. Migration removes only obsolete punctuation identified by the old AST. This revision does not authorize modifying strings, native sequences, tactic combinators, or old archived evidence.


---

# Part III — Declarations, functions, and data

## 17. Definition declarations and aliases

`def` remains the canonical general definition keyword. `const` and `function` are declaration-head decorations lowering to `def`, not independent semantic kinds.

```proofscript
const answer: Nat := 42
const increment: Nat -> Nat := fun n => n + 1

function add(x: Nat, y: Nat): Nat :=
  x + y

def identity {α: Type}(x: α): α := x
```

Canonical Lean:

```lean
def answer : Nat := 42
def increment : Nat → Nat := fun n => n + 1

def add (x : Nat) (y : Nat) : Nat := x + y

def identity {α : Type} (x : α) : α := x
```

`const` has no declaration binders. It may have a function-valued type or inferred value type. Generic value definitions use `def` or `function` rather than hiding declaration parameters behind `const`.

`function` requires at least one nonempty explicit declaration parameter group. Implicit and instance binders may surround explicit groups in supported native order. A function taking no meaningful input can take `(_: Unit)`; it is then called with `f()`. No Unit binder is silently added to an empty header.

Rejected owned forms include:

```text
const add(x: Nat): Nat := x
function answer: Nat := 42
function answer(): Nat := 42
function square(x: Nat): Nat { x * x }
const answer = 42
```

The first misuses `const`; the next two do not supply an explicit parameter; the fourth is an unregistered statement-body grammar; the last replaces Lean binding syntax. These are syntax/profile errors, not logical theorems about the proposed bodies.

A definition becomes available according to native declaration and recursion rules. Aliases do not introduce JavaScript hoisting, overload sets, prototype methods, hidden receivers, or runtime object freezing.

## 18. Definition kinds, modifiers, and visibility

`theorem`, `example`, `abbrev`, `opaque`, `axiom`, and native definition modifiers retain their selected Lean meaning. Lowering MUST preserve the declaration kind, name, universe parameters, type, body, safety information, reducibility/opacity metadata, and relevant attributes.

An `abbrev` is a transparent abbreviation, not a distinct nominal type. A domain identifier that must not be confused with arbitrary natural numbers should use a structure, not merely `abbrev UserId := Nat`.

An `opaque` declaration is not a freely unfoldable definition. Opacity is semantically relevant to conversion and proof behavior; it must not be erased as a cosmetic attribute. A theorem declaration is not emitted as an ordinary runtime function merely because its proof can be represented by a term.

`private`, `protected`, `noncomputable`, `partial`, `unsafe`, native module modes, and supported public/meta annotations are inherited only with their exact upstream behavior. Source visibility is not a security sandbox. Module export policy and the name of a JavaScript export do not grant or remove logical derivability.

A compiler may implement only selected native modifiers, but it MUST reject unsupported ones instead of dropping them. A release profile should distinguish ordinary declarations, research axioms, runtime assumptions, and unavailable executable definitions.

## 19. Binders, dependencies, and universes

Binders preserve native roles:

```proofscript
(x: A)        -- explicit
{α: Type}     -- implicit
{{α: Type}}   -- strict implicit, where the pinned grammar admits this spelling
[C α]         -- instance implicit
```

Native Unicode variants are accepted according to the pin. The lowerer records binder kind and order; it does not infer that braces mean “generic type parameter” regardless of the enclosed type.

`D-EXPLICIT-PARAMS` comma-groups **complete single-name explicit binders** in registered declaration headers:

```proofscript
function select(n: Nat, i: Fin n): Fin n := i
```

```lean
def select (n : Nat) (i : Fin n) : Fin n := i
```

The type and any native default of a later parameter may depend on earlier parameters. The lowerer expands each group into native explicit binders in the same order. It does not make dependent parameters independent or reorder them for target calling conventions.

A comma group has a type for each entry. Forms such as `(x, y: Nat)` are not shorthand for `(x: Nat, y: Nat)`. Native shared-type binders such as `(x y : Nat)` remain native, without commas. Grouping rules do not automatically apply to lambda binders or pattern binders.

Universe declarations and polymorphism remain native. `Type u` abbreviates the appropriate sort; `Prop` and `Sort u` retain the pinned universe rules. Do not replace universe expressions with machine integer ranks or approximate level equality in a standalone checker. The source grammar does not add TypeScript `<T>` binders.

## 20. Inference, annotations, and elaboration order

Local type inference, implicit arguments, coercions, overloaded literals, and typeclass synthesis follow the chosen Lean elaboration environment. They are not reimplemented as TypeScript assignability.

Public signatures SHOULD expose useful types, effects, and dependencies, but explicit signatures are a style/interface recommendation unless a selected build policy requires them. A template MAY explicitly set `autoImplicit false`; the compiler MUST NOT silently use different options from the reference environment.

An application is elaborated as a whole native application syntax object. The native algorithm matches positional and named arguments to the function type, creates metavariables, uses expected types, handles missing explicit parameters/defaults, and schedules instance synthesis. Elaborating each argument first against an independently inferred type may change the result and is not an equivalent implementation. [L4]

Native instance priorities and declaration/import order may affect search. A standalone frontend must reproduce the accepted choice or report an unsupported case. It cannot replace that behavior with a different tie-breaking rule while retaining the same profile name.

Resource limits bound the implementation's search. A budget-exhausted request is incomplete, not permission to guess a candidate, insert an axiom, or weaken the expected type. The diagnostic should expose the unresolved constraint and selected environment.

## 21. Named, default, automatic, and partially supplied arguments

Defaults use supported native parameter syntax:

```proofscript
function connect(host: String, timeout: Nat := 5000): String × Nat :=
  (host, timeout)
```

The body above is a simple illustrative value, not an implemented network API.

Native call syntax remains valid:

```proofscript
connect "example" (timeout := 1000)
```

The v0.9 named-call decoration provides the corresponding term:

```proofscript
connect("example", timeout := 1000)
```

Defaults are native elaboration metadata associated with parameter types. They are not a runtime overload mechanism. Automatic parameters invoking tactics remain native capabilities and create ordinary proof obligations. The compiler must preserve their environment and not rerun them under a different namespace or option set.

Passing fewer explicit parameters can yield a function according to the native application algorithm. Named arguments can fill a later parameter while leaving an earlier one abstracted. Do not implement missing parameters by inserting JavaScript `undefined`.

A value explicitly representing absence is still an argument. Omission, `Option.none`, and a foreign `undefined` argument are not interchangeable.

## 22. Lambdas, closures, and higher-order functions

Lambdas use `fun`:

```proofscript
fun x => x + 1
fun (x: Nat) => x + 1
fun {α: Type} (x: α) => x
```

Their binder and pattern-lambda forms remain native. A term-level call in the body is recursively lowered, but a comma in the outer call is not allowed to split an inner parenthesized lambda or record.

```proofscript
users.map(fun user => user.name)
```

Function types retain native arrows and dependent Pi structure. The base does not add `(x) => e`, callback parameter destructuring with JavaScript semantics, or function objects carrying arbitrary dynamic properties.

Closures capture the values and lexical relationships specified by native elaboration. The runtime representation may be a JS closure or a code/environment record, but calling conventions and captured data must preserve the source meaning. Returning a function from a function is not a special case that may bypass erasure or omit parameters.

Compiler optimization must respect the distinction between total pure computation, partial computation, and observable effects. A closure capturing a logical value is not automatically a handle to mutable foreign state.

## 23. Operators, equality, and conditions

Operators are selected native notation over declarations. Their precedence, associativity, scoping, and elaboration are those of the registered environment. A convenient operator name does not authorize a new primitive.

Three relationships remain different:

| Relationship | Role |
|---|---|
| Definitional equality | Kernel conversion after the allowed reductions. |
| Propositional equality `x = y` | A type/proposition whose inhabitant is evidence. |
| Boolean comparison `x == y` | Computation through the selected `BEq`-style instance. |

A Boolean comparison returning true does not automatically prove equality. Verified use requires the relevant laws or a suitable decision procedure. Likewise, a programmer-supplied Boolean predicate cannot be treated as a sound refinement test without evidence connecting it to the proposition.

Conditions follow native Lean treatment of propositions with decidability and supported Boolean coercion. There is no numeric, string, or object truthiness. Native evidence-binding conditionals such as `if h : p then ... else ...` retain their branch contexts.

## 24. Braced conditionals

**Feature ID:** `E-IF-BRACE`.

```proofscript
function bounded(n: Nat): Nat :=
  if (n <= 10) { n } else { 10 }
```

Canonical Lean:

```lean
def bounded (n : Nat) : Nat :=
  if n <= 10 then n else 10
```

Each branch is exactly one term. The condition is parenthesized. There is no generic statement list inside these braces. A branch requiring sequencing uses a native `do` term or another explicitly supported term abstraction.

The parser recognizes this exception only after the complete owned discriminator `if ( ... ) {` is established in a term context. Native `if (c) then ... else ...` is still inherited. Once the E form has committed, a missing branch or missing `else` is an error.

An `else if` chain can use a nested native or decorated conditional as the single else term; the canonical presentation encloses the else term explicitly. No special C/JS dangling-else rule is introduced.

The lowerer preserves each condition/branch once in syntax and does not evaluate both branches or duplicate effectful subterms. The relationship of logical reduction to target execution is still a separate compiler obligation.

## 25. Structures and record values

**Feature ID:** `E-STRUCT-BODY`.

```proofscript
structure UserId where {
  value: Nat
}

structure User where {
  id: UserId
  name: String
  active: Bool
}
```

Canonical Lean uses the same declarations and fields with native layout. Fields are parsed as native field declarations, lifted only at registered term/header child slots. Field order, binder kinds, defaults, documentation, and attributes remain significant. The body uses lifted native `structFields` layout, not semicolon-separated field declarations.

The braces are not an object literal or a namespace. They delimit the declaration's field sequence. Empty or unusual structure forms are accepted only when their lowered native structure is supported and well-formed; braces do not invent constructor validity.

Record values and updates retain native syntax:

```proofscript
const example: User := {
  id := { value := 7 },
  name := "Ada",
  active := false
}

function activate(user: User): User :=
  { user with active := true }
```

Default fields, inherited fields, field-name resolution, source records in updates, and type ascription follow native elaboration. A backend cannot reinterpret construction as copying JS property descriptors or prototypes.

Native structure inheritance through `extends` remains available when supported. It is Lean parent-structure composition, not JavaScript prototype inheritance. A blanket ban on the word `extends` would wrongly remove an inherited semantic mechanism.

## 26. Dependent fields and updates

A structure may contain a field whose type depends on another field:

```proofscript
structure SizedData where {
  n: Nat
  data: Fin n -> Nat
}

function replaceData(n: Nat, f: Fin n -> Nat): SizedData :=
  { n := n, data := f }
```

Changing `n` can change the required type of `data`. The compiler must reconstruct a well-typed record under the native rules. It may use valid transport/equality evidence when available; it may not retain a mismatched field using a cast, resize it silently, or erase the dependency merely because it is inconvenient to emit.

A candidate update `{ s with n := s.n + 1 }` with arbitrary old `data` was rejected by the pinned Lean oracle in this research. That observation is a concrete negative example, not a proof of all dependent-update behavior.

Runtime erasure may remove type/proof fields only after relevance analysis. The data indexed by a size can still be runtime-relevant even when the size's type-level use disappears.

## 27. Inductives, constructors, and pattern matching

**Feature IDs:** `E-INDUCTIVE-BODY`, `E-MATCH-BODY`.

```proofscript
inductive LoadState(ε: Type, α: Type) where {
  | idle
  | loading(requestId: Nat)
  | ready(requestId: Nat, value: α)
  | failed(requestId: Nat, error: ε)
}
```

Constructors lower to native constructor declarations in the same order, with the same parameters, indices, universe expressions, result types, and metadata. Braces are presentation; they do not relax positivity, constructor result requirements, or elimination restrictions.

```proofscript
function getOrElse(value: Option Nat, fallback: Nat): Nat :=
  match value with {
    | .none => fallback
    | .some n => n
  }
```

The discriminants and RHS terms are ProofScript-aware term slots. Patterns remain native. Their variables, inaccessible patterns, literal interpretation, constructor resolution, and dependent refinement follow Lean.

Rejected as a pattern:

```text
| .some(n) => n
```

This does not prohibit `.some(n)` in a **term** context. Constructor declaration parameters, constructor applications, and constructor patterns are distinct categories.

A braced match has at least one alternative. Its lifted native alternative sequence uses `|`, `=>`, and native layout; there is no added `;` after an alternative. Preserve native multiple-discriminant and alternative-pattern groups. An RHS containing a local `let`, tactic sequence, or `do` retains the separators of that nested category. The grammar must not split alternatives by scanning for semicolons or every `|`.

```proofscript
function both(x: Option Nat, y: Option Nat): Nat :=
  match x, y with {
    | .some a, .some b => a + b
    | _, _ => 0
  }
```

Exhaustiveness and motives are elaborator obligations. A wildcard is not permission to ignore an unsupported indexed elimination. “Pattern lowering succeeded” does not establish that its recursor is valid until the declarations are admitted.

## 28. Indexed, mutual, nested, and coinductive definitions

The theorem profile can use the corresponding native capabilities. A standalone implementation must report exact coverage for mutual inductives, nested inductives, indexed families, generated recursors, and the native coinductive/fixpoint facilities of the selected environment.

The overlay does not create new positivity or termination rules. Parameters and indices must not be conflated. Constructor tables supplied by a frontend are not trusted merely because they are syntactically decodable.

Native mutual blocks retain `mutual ... end` command structure. Braced command scopes are not added. The version-specific `monotonicity_by` suffix remains inherited in the native contexts that support it; a declaration suffix is not a general proof-automation keyword usable anywhere.

Logical admission and executable support remain separate. A backend may reject an executable use of a valid theorem-level construction it cannot represent, while retaining the proof-only declaration.

## 29. Classes, instances, and methods

**Feature IDs:** `E-CLASS-BODY`, `E-INSTANCE-BODY`.

Classes are Lean typeclasses:

```proofscript
class Sized(α: Type) where {
  size: α -> Nat
}
```

The v0.7 prose includes braced instances without a separate registry entry. v0.9 makes that family explicit rather than hiding it in implementation behavior:

```proofscript
instance : Sized String where {
  size(s: String): Nat := s.length
}
```

`E-INSTANCE-BODY` parses the native instance header, then `where { fieldEntries }`. Entries use the lifted native `whereStructInst` field sequence and registered header/term decoration. Semicolons are permitted only as the native sequence already permits them; they are not mandatory per-field or outer-declaration terminators. Canonical examples prefer native layout. Lower to the same native `where` field AST, preserving field binders, result ascriptions, and bodies. Do not confuse this initializer sequence with `structFields`, which declares a structure/class and does not add semicolon separators.

Named instances, priorities, scoped/local modifiers, and deriving must be preserved when advertised. An unsupported modifier is an error. A generated instance is checked like any other declaration.

Generalized field notation is native type-directed resolution. The receiver is inserted at the native matching explicit parameter, which is not necessarily the first parameter. For instance, a collection API may have an earlier function parameter and later collection receiver. Lowering `xs.map(f)` by blindly constructing `map xs f` is incorrect. Construct native field/application syntax and let the compatible elaborator resolve it. [L4]

There is no automatic OO class hierarchy, method overriding, prototype mutation, `new`, or dynamic `this` in this class model. A foreign JS receiver is modeled separately at the interop boundary.

## 30. Collections, absence, and error values

`List`, `Array`, `ByteArray`, `Option`, `Prod`, `Sum`, `Subtype`, `Fin`, and other selected native declarations retain their own definitions. Their names must not become aliases for whichever target container is convenient.

`Option α` is the default portable absence vocabulary. A live JS object can distinguish missing property, explicit undefined, null, and present value; an interop codec may deliberately collapse those states but cannot call that a lossless conversion.

Native `Except ε α` is error-first. The v0.7 example defines a user `Result(α, ε)` as success-first. Both are ordinary types with different parameter conventions. This reference does not silently rename or reorder either. A standard application library SHOULD choose one documented convention consistently; adopting native `Except` avoids inventing an additional fundamental error hierarchy.

A list is not an array. An ordered map is not an unordered hash map. Equality and hashing require laws when used in proofs. Collection iteration order is a library contract, not JS object order or a Rust container's current iteration behavior.

Array indexing, optional access, proof-indexed access, and panic/defaulting access are different native APIs. A compiler MUST NOT substitute an unsafe/defaulting operation for proof-indexed access to make generated code run.

## 31. Local definitions, `where`, and recursion syntax

Ordinary `let`, `let rec`, and native `where` remain available. A local definition captures exactly its native lexical environment. Promoting it to a top-level helper requires correct capture and name handling, not text movement.

`E-WHERE-BODY` offers a braced local-declaration sequence in a declaration suffix:

```proofscript
function incrementTwice(x: Nat): Nat :=
  helper(helper(x))
where {
  helper(y: Nat): Nat := y + 1
}
```

Canonical Lean:

```lean
def incrementTwice (x : Nat) : Nat :=
  helper (helper x)
where
  helper (y : Nat) : Nat := y + 1
```

Entries are native local declaration shapes, not arbitrary top-level commands. Do not add `namespace`, imports, axioms, or environment-changing commands to this body through generic command parsing. Nested local declarations and termination suffixes follow the selected native grammar when supported.

For a decorated simple definition, native termination suffixes precede its native/registered `where` suffix in the underlying declaration AST. No added command terminator follows that suffix. The local declaration sequence preserves native `sepByIndent` semicolons where supported, including a trailing separator belonging to that sequence. Native equation-style definitions retain their own native boundaries, with no invented C-style body syntax.

The current example's canonical form is illustrative unless listed in the executed oracle corpus. The presence of local recursion in the public reference does not claim that every existing compiler backend implements closure conversion for it.

## 32. Pattern/equation functions and declaration suffixes

Native equation-style functions are supported through the pinned `declValEqns` and `matchAltsWhereDecls` categories. Their ordering, pattern discrimination, termination analysis, and scope are not redefined by the overlay.

Where an implementation advertises header decoration on an equation declaration, it must lower the header first while preserving the native equation body and suffix structure. It must not interpret an equation alternative as an ordinary do statement or silently terminate the declaration at an inner tactic semicolon.

The default teaching form for decorated application code is `:= expression` with native declaration boundaries; native equation forms are useful for recursive algorithms and theorem code. A canonical formatter can preserve both by category rather than forcing every native form into an unproved rewrite.

Unsupported mixtures of decorators and suffix categories must produce a capability diagnostic naming the combination. A claimed whole-profile implementation eventually needs interaction coverage, not only successful isolated features.

---

# Part IV — Computation, effects, and modules

## 33. Scalars, literals, and primitive identity

The selected native types include `Nat`, `Int`, supported `UInt*`/`Int*` families, target-word types, floating types, `Bool`, `Char`, `String`, and `Unit`. A name is supported only with its actual declaration and primitive/runtime mapping. The reference does not invent a native declaration because a similarly named type appears in a target language.

Literal overloading, `OfNat`, negative syntax, decimal/scientific literals, characters, string escapes, and string interpolation follow the pinned grammar and elaborator. A bare numeral is not universally a JavaScript `number`. Context and instances determine its type.

Primitive recognition must validate the expected declaration identity, type, and role. An arbitrary user declaration named `Nat.add` cannot obtain a trusted reduction rule. A manifest containing a primitive name or hash does not replace checking its required semantics.

### 33.1 Exact naturals

For the ordinary native natural-number operations, the required values include:

| Operation | Meaning |
|---|---|
| `a + b`, `a * b` | Exact arithmetic over nonnegative integers. |
| `a - b` | Truncated subtraction: zero when `b > a`. |
| `a / b`, `b > 0` | Natural quotient. |
| `a % b`, `b > 0` | Natural remainder. |
| `a / 0` | Zero under the pinned ordinary Nat division operation. |
| `a % 0` | `a` under the pinned ordinary Nat remainder operation. |
| Comparisons | Native numerical relationships; Bool/Prop result depends on the chosen operation. |

The oracle corpus checked examples of underflow and zero division/remainder. Backend conformance requires the entire operation contract, not just those instances.

### 33.2 Exact integers

Ordinary pinned `Int` `/` and `%` use their selected native Euclidean operations. Distinct APIs such as truncating division must retain their distinct names and rules. For example, the oracle checked `(-5 : Int) / 2 = -3` and `(-5 : Int) % 2 = 1`. A JS BigInt expression using truncation toward zero is not automatically equivalent.

Zero-divisor, negative-divisor, conversion, and machine-boundary behavior are inherited per exact declaration. A backend's primitive matrix MUST name these operations explicitly rather than specify “use host integer division.”

### 33.3 Fixed-width and target-word values

Width, wrapping/checking behavior, shifts, narrowing, sign conversion, division, and conversion to/from exact integers are defined by the selected native operations. A Rust debug flag or Wasm opcode does not establish their meaning.

Target-word values include the target width in executable-profile identity. Code whose results depend on width is not promised bit-identical across 32-bit and 64-bit targets. A backend must not silently pick one width while advertising another.

### 33.4 Floating point

A floating contract concerns the selected floating model or a proved relation to a mathematical model. It is not automatically real-number arithmetic. Record rounding, NaN/infinity, signed zero, bit conversion, permitted nondeterminism, and runtime-library dependencies for every advertised operation.

If the native reference leaves behavior dependent on a platform primitive, that dependency must remain visible. A backend must either match the stated profile or reject the requested stronger deterministic claim. Fast-math, reassociation, and relaxed transformations are not silently allowed under a faithful profile.

### 33.5 Primitive-matrix completeness

The language's primitive meaning is fixed by the pin; executable support is declared in a matrix with one entry per reachable primitive and transitive runtime dependency. The matrix contains declaration identity, input/output representation, exceptional/resource outcomes, target implementation, and evidence. Missing entries reject execution for that target. This avoids replacing an incomplete implementation with an unspecified semantic default.

## 34. Strings, characters, bytes, and identity

Native `Char`, `String`, string positions/slices, and `ByteArray` operations retain their exact selected definitions. A backend may use UTF-8 buffers, JS strings, or another representation only with a relation preserving the operations it exposes.

JS string indexing and length operate on a different representation from many native text operations. A lossless foreign JS string may contain lone surrogates that cannot simply be treated as an ordinary Unicode-scalar string. Foreign interoperation must preserve such states in an explicit boundary type or reject/normalize them under a documented policy.

Do not use native memory layout as a network format. Specify encoding, endianness, bounds, and versioning for byte codecs. A conversion that rejects malformed text is different from one replacing invalid sequences.

Pure data identity is not target pointer identity. Copying, sharing, boxing, or garbage-collecting a logical value may be implementation choices when the observable semantics is preserved. Conversely, a foreign DOM node or resource handle has explicit identity/lifetime behavior and must not be smuggled into a pure record model.

## 35. Pure computation and evaluation

A type-theoretic reduction relation is not the entire executable semantics. Define separately the logical interpretation, admissible compiled implementation, and observable runtime behavior.

Native logical conversion may unfold and reduce according to the kernel's rules. Compiled code may use optimized representations and separate runtime implementations. Classical axioms and quotient-related constructions can obstruct kernel normalization without preventing suitable proof-erased execution. Choice used to construct data can require noncomputability. Do not assert that every closed kernel-accepted natural-number term necessarily reduces to a numeral under every admitted assumption policy. [B3]

In the executable profile, observable ordering is preserved according to the native computation and its specified primitive models. Effectful order is expressed through bind/do or another explicit computation abstraction, not guessed from pretty-printing.

Purity alone does not justify every code motion when partiality or failures are observable. Under a strict evaluation model, deleting an unused divergent argument may turn divergence into termination. Optimizations must state the hypotheses under which duplication, reordering, or erasure preserves behavior.

## 36. Native `do`, local mutation, and control flow

The pinned `Lean/Parser/Do.lean` explicitly supports a nonempty braced do sequence. Thus `do { ... }` is inherited, not a new JavaScript statement block. This was both source-inspected and exercised with the pinned Lean toolchain. [L2]

```proofscript
function sum(xs: List Nat): Nat :=
  Id.run(do {
    let mut total := 0;
    for x in xs do {
      total := total + x;
    };
    return total;
  })
```

The illustration uses native do syntax with ProofScript-aware term child slots. Its intended canonical counterpart is a native `Id.run do` program. An empty `do {}` is not introduced; use an appropriate explicit `pure ()` or other native action.

Native `let`, monadic binding with `←`/`<-`, `let mut`, assignment with `:=`, `for ... do`, `while`, `break`, `continue`, `return`, and error/recovery syntax retain their elaboration and scope. `=` is not reassignment. A loop does not acquire JavaScript iterator semantics because its body uses braces.

The do-element parser owns its separators and nested term slots. It must not strip every semicolon and hope a native parser will reconstruct the original sequencing. Likewise, an E-IF single-term branch is not itself a do sequence.

Mutable locals are elaborated under native restrictions. Capturing mutable-looking state in a closure must follow the pinned elaboration; the backend cannot independently choose between snapshot capture and a shared mutable cell.

Early return is meaningful only in the native contexts supporting it. It does not jump out of arbitrary nested pure expressions or callbacks as if they were JS statement functions.

## 37. Structural, well-founded, partial, and unsafe computation

Structural and well-founded recursive definitions use native termination analysis and proof mechanisms. A failed termination search establishes neither divergence nor an excuse to mark the definition total. Explicit `termination_by` and `decreasing_by` forms keep their native scopes and syntax.

`partial def` retains its native logical interpretation. The logical constant can appear in statements, but the executable body's equations are not automatically available as definitional equalities. A theorem about that opaque logical object is not automatically a theorem about every behavior of its compiled runtime body.

Native `partial_fixpoint`, inductive/coinductive fixpoints, and associated reasoning principles are individually gated inherited capabilities. Their monotonicity/order obligations cannot be replaced with “the test terminated.”

`unsafe`, external implementations, and runtime replacement mechanisms require explicit execution-trust accounting. A safe logical signature around an unsafe implementation may preserve logical consistency while the executable behavior diverges from the proved model. Certified execution must audit/reject or justify those replacements; type checking alone does not close the gap. [L5]

Long-running services and event loops are legitimate applications. Their useful properties may be trace safety, partial correctness, resource invariants, or conditional liveness—not total termination of the server. These claims require a corresponding model and must not be fabricated by unfolding opaque partial constants.

## 38. Effects, state, and errors

Lean effect types and native abstractions remain the base model. ProofScript does not replace `IO`, `StateT`, `ExceptT`, `ReaderT`, or native typeclasses with a different effect system by changing syntax.

Transformer order matters:

```text
StateT S (Except E) A     ~ S -> Except E (A × S)
ExceptT E (StateM S) A    ~ S -> (Except E A × S)
```

The first shape does not return a successful state pair on failure; the second returns final state alongside either outcome. A library alias must disclose its concrete semantics. Recovering from an error can produce different states under these arrangements. Discarding logical state does not undo a file write or network request. [B2]

Recoverable domain failures should use explicit typed values/effects. Host exceptions and rejected promises are translated only by a specified adapter. An arbitrary thrown JS value is not automatically a member of the application's declared error type.

A proposed application library may provide convenient ordinary definitions for state, capability descriptions, tasks, or resource handling. Such libraries require their own semantics and evidence. The base grammar does not silently introduce an `App` effect, a universal `try` propagation operator, or algebraic effects.

## 39. IO, tasks, resources, and application libraries

Native Lean `IO` and `Task` retain their pinned logical/runtime distinction. A JS Promise is not a native Lean Task merely because both eventually produce a value.

A portable library may use separately named types, such as `Psc.Async`, to describe different start, cancellation, and cleanup policies. Such names in this reference are **architectural examples, not installed or standardized APIs**. No `async function`, `await`, `using`, or `component` keyword is admitted by the base overlay.

Before a task/resource library is promoted, its contract must state:

| Question | Required answer |
|---|---|
| Start | Is constructing a task pure/cold, or does it schedule work? |
| Reuse | Does reuse start new work or await one shared handle? |
| Failure | Which typed and unexpected foreign failures can occur? |
| Cancellation | Is it a request, a terminal state, or both at different stages? |
| Children | Which scope owns them, and what does scope completion require? |
| Cleanup | What happens on success, failure, cancellation, and cleanup failure? |
| Timeout | Which clock/deadline is used, and what happens to late effects? |
| Resources | What is copied, shared, released, or explicitly detached? |

These are library/runtime requirements, not new kernel rules. A target lacking the required behavior must reject the capability or report a separately named weaker contract. A cancellation result does not prove a remote side effect was reversed.

Pure `.ps` or `.lean` library calls must remain an alternative to any future convenience syntax. Full-app readiness is measured by real supported workflows, not by the number of new keywords.

## 40. Imports, namespaces, sections, and modules

Imports use native logical module syntax:

```proofscript
import Init
import MyApp.Domain

namespace MyApp

function square(x: Nat): Nat := x * x

end MyApp
```

Namespaces, sections, variables, `open`, local/scoped declarations, native exports, attributes, options, and supported module visibility modes retain their exact upstream meaning. `namespace N { ... }`, `section { ... }`, and `import { x } from "pkg"` are not base replacements.

Module resolution maps logical names to one selected source snapshot and pinned package versions. Mapping into npm package exports is a build/interop concern; it does not turn native imports into Node runtime resolution accidentally.

Commands are processed in their declared environment order. A notation, macro, instance, or option registration can affect later parsing/elaboration. Do not parse all commands under the final environment or reorder them by file name. Speculative parsing/elaboration must roll back state on failure.

Module initialization and native module modes are supported only with exact declared semantics. A platform template SHOULD use explicit application entry points rather than inventing hidden top-level side effects. Build-time registration effects and runtime application effects are separately recorded.

## 41. Notation, macros, deriving, and metaprogramming

Native notation and macro facilities are powerful inherited capabilities, not permission for arbitrary unrecorded syntax. A reference environment records its parser/notation/macro/elaborator registrations. A standalone environment may support a bounded selection.

A third-party production colliding with an owned D/E region must have an explicit compatibility rule or be rejected. Imported syntax cannot silently override a ProofScript discriminator. The same rule applies to newly reserved command heads.

Macro expansion preserves hygiene, source references, and pre-resolved identities. Capturing an unrelated local variable is a source-correspondence defect even if the resulting term happens to type-check. The source and Core ASTs must remain distinct; a macro is not a global string substitution. [L7, P2]

Deriving and registries produce ordinary declarations and proof candidates. Registered `simp` or `spec` metadata is an index, not proof authority. Unknown attributes are rejected unless defined in the selected environment.

Native quotations/antiquotations preserve their category. Term decoration does not recursively rewrite arbitrary quoted text. Syntax-building Meta code and tactic implementations may be substantially larger than the kernel while remaining non-authoritative logically. Their operating-system permissions are a separate security issue.

---

# Part V — Logic, theorem proving, and verification

## 42. The logical foundation

ProofScript reuses the pinned dependent type theory rather than defining a weaker approximate calculus. The relevant foundation includes sorts/universes, dependent functions, binding/substitution, conversion, propositions, proof irrelevance, inductive families/recursors, and the selected quotient facilities.

A standalone checker must validate the actual inputs under its declared rules and policy: closedness, bound variables, universe parameters, types, bodies, positivity, recursor information, primitive identities, and environment consistency. Successful decoding is not successful admission.

An implementation may progress through smaller subsets, but its accepted results must be sound for the advertised subset. It cannot approximate level equivalence, replace dependent elimination with nondependent matching, or accept caller-supplied recursor tables merely because those shortcuts cover current examples.

Independent checkers are useful differential references, not interchangeable definitions. The repository's `lean4lean-master/divergences.md` documents intentional differences from upstream, including universe comparison and checking details. Reusing its algorithms does not automatically establish exact pinned acceptance equivalence. [R4]

## 43. Propositions, types, and evidence

A proposition is a type in `Prop`; a proof is an inhabitant admitted under the selected theory and assumptions. Data and propositions are related but not interchangeable.

```proofscript
theorem identityProof {P: Prop}(h: P): P := by {
  exact h
}
```

The proposition's meaning comes from the admitted declarations, not the theorem name or source comment. A function with Boolean output can be useful in a decision procedure, but its `true` output becomes logical evidence only through a justified bridge.

Dependent types can express invariants directly, for example `Fin n`, indexed vectors, or a subtype whose constructor carries a proof. Runtime use must preserve the data witness while erasing only justified irrelevant evidence.

Holes and unfinished proofs may exist in the editor. They must never be serialized as successful release proof evidence. Ordinary user axioms remain visible assumptions, not hidden implementations of unfinished proof search.

## 44. Theorems and structured proof forms

The theorem profile supports native proof terms and the selected tactic environment. Familiar structured forms include `have`, `show`, `suffices`, `calc`, explicit lambdas, and constructors.

```proofscript
function twice {α: Type}(f: α -> α, x: α): α :=
  f(f(x))

theorem twiceIdentity {α: Type}(x: α): twice((fun y => y), x) = x := by {
  rfl
}
```

The intended native theorem was included in the oracle examples in an equivalent native presentation. That does not certify the decorated header/call parser.

The tactic category keeps its own combinators and delimiters. Term arguments accepted by tactics may use the declared term overlay only in registered slots. Do not treat every `;` in a proof as a discarded declaration terminator: it may control tactic execution.

The standard prover should supply the relevant native capabilities for rewriting, simplification, cases, induction, and goal management. The base grammar does not freeze every tactic implementation or claim source compatibility with all third-party tactics.

## 45. Rewriting, simplification, automation, and reflection

`rw`, `simp`, induction, arithmetic procedures, search, and AI-generated proofs construct evidence. They do not authorize declarations independently of the kernel.

A simplifier must justify the rewrites and congruence steps used in its final proof. Fast untrusted search may choose candidate lemmas, but the resulting term or reconstructed certificate must be checked. A solver's bare `sat`/`unsat`/`valid` response is not proof authority in a strict profile.

Reflection is allowed when an ordinary theorem establishes a checker's soundness and the actual checker result is justified through accepted logical mechanisms. Compiling that checker to native code and trusting a returned Boolean without the required bridge introduces a separate trust assumption; naming the function “verified” does not remove it.

The pinned reference removed historical kernel native-reduction hooks. This profile MUST NOT revive `Lean.reduceBool`, `Lean.reduceNat`, or `Lean.trustCompiler` as silent kernel computation rules. Native/meta proof tactics, if admitted by a larger profile, report their actual assumptions. [R1]

Proof scripts and proof terms have different stability. Pin tactic/notation environments, retain replayable evidence where useful, and report script repair separately from statement or axiom changes.

## 46. Axioms, classical mathematics, quotients, and noncomputability

Axiom policy is independent of syntax version and checker package version. It specifies exact permitted declarations and tracks transitive dependencies. Names alone are insufficient.

Classical mathematics and noncomputable definitions are legitimate theorem-development activities. The standard mathematical profile may allow reviewed foundational assumptions, while a constructive profile may restrict them. Neither policy silently changes conversion rules.

Proof-irrelevant classical reasoning does not necessarily make an otherwise executable function noncomputable. Conversely, choice used to manufacture runtime data cannot be erased as though it were only a proof. Quotient computations and elimination restrictions must retain the selected native meaning. [B3]

Strict proof acceptance excludes unresolved `sorry`/`sorryAx`, fabricated native-result axioms, and arbitrary unapproved assumptions. A research build may display them, but must report the weaker claim accurately.

An external implementation specification is not automatically a logical axiom. Prefer explicit model parameters/hypotheses and separately reported implementation relationships. This keeps “the theorem follows from the model” distinct from “the external service implements the model.”

## 47. Specifications as ordinary theorems

The baseline specification mechanism is an ordinary theorem about an ordinary definition:

```proofscript
function debit(balance: Nat, amount: Nat): Except String Nat :=
  if (amount <= balance) {
    .ok(balance - amount)
  } else {
    .error("insufficient balance")
  }

theorem debitSuccess(balance: Nat, amount: Nat)(h: amount <= balance):
    debit(balance, amount) = .ok(balance - amount) := by {
  simp [debit, h]
}
```

This example states a successful-input property. It does not establish authorization, concurrency, financial units, or correct persistence. A complete application contract should also state relevant error and state-preservation behavior.

The final admitted theorem must identify the **actual implementation**, approved specification, and their fixed dependencies. Proving unrelated obligations generated by a buggy VC generator is insufficient.

For a total pure function the target relationship is conceptually:

```text
∀ x, Pre x → Post x (implementation x)
```

For stateful, partial, or asynchronous computations, use the corresponding program logic and outcome relation. The existence of a total function constructing an IO value does not establish total termination of the external computation represented by that value.

## 48. Native intrinsic contracts

The pinned intrinsic-verification mechanism is an **experimental inherited capability**, enabled under its exact imports/options. It is not rebranded as a newly stable proof primitive.

The inspected and executed native form uses:

```lean
import Std.Internal.Do
set_option experimental.intrinsic true

def unchanged (n : Nat) : Id Nat
    ensures result => result = n :=
  pure n
```

The oracle generated `unchanged.spec` and warned that `vcgen` remains experimental. The reference must preserve that warning/status rather than describe the feature as production-proved.

The pinned grammar accepts one optional `requires` followed by one optional `ensures`. Compound requirements use conjunction or ordinary predicates; repeated clause keywords are not silently concatenated. The postcondition may use supported native lambda/match forms. [L3]

If a decorated `def`/`function` header is combined with this capability, lower to the same native definition and contract clauses before native elaboration, preserving binders, native clause structure, and the declaration's native body/suffix boundary. No outer semicolon is introduced. The compiler must advertise and test this composition explicitly.

The native generated specification theorem remains separate from the function's ordinary executable type. A type-checked caller has not necessarily established the precondition. Verified callers discharge what their correctness argument needs; a proof-bearing API can require evidence explicitly through dependent binders.

## 49. Assertions, invariants, termination clauses, and ghost state

Native verification `assert` creates proof obligations under the selected intrinsic/program-logic environment. `assert!` is a runtime operation with its native panic behavior. The same English word does not give them the same assurance.

Loop invariants need initialization, preservation, exit, and supported control-flow obligations. The inspected native invariant facility is not universally available on every iterator: supported collection and effect interfaces, including relevant `PureForIn` requirements, are part of its capability contract. Multiple collections or unsupported containers must not silently bypass these restrictions. [L3]

Termination syntax remains native `termination_by`/`decreasing_by` or the selected fixpoint mechanism. This base does not invent a universal `decreasing` keyword on arbitrary loops. A future surface convenience must name its exact lowering and obligations.

Residual verification conditions use the pinned native proof-section grammar, including the supported `where finally | spec => ...` form. A braced `E-WHERE-BODY` is not automatically a replacement grammar for that proof section.

Native `erased` bindings and proof-only values must preserve their native scope and relevance semantics. Runtime data cannot depend on a removed witness. A failed relevance proof rejects the claimed erasure; it does not emit a default value.

## 50. Specification quality and assumption control

A sound proof of a weak specification can certify an unwanted program. A sorted-output contract alone can permit an always-empty implementation. A success-only postcondition may permit always failing. An impossible precondition can make a correctness implication vacuous.

Tooling SHOULD expose these possibilities using examples, witnesses, model checks where justified, and deliberately broken implementations. Such checks are evidence about specification quality, not proof that the specification captures every human requirement.

An approved specification includes semantic dependencies: predicate definitions, relevant types, imported declarations, axiom policy, and environment. Protecting only the text of `ensures P` is insufficient if an agent can redefine `P` to mean `True`.

A requirement change remains possible, but must be reviewed as a different operation from an implementation repair. An AI agent must not obtain a successful build by changing the verifier, release policy, specification dependency, or allowed assumptions without explicit authorization.

A counterexample is confirmed only when the reported model/input corresponds to the selected program semantics. A timeout, unknown solver result, or unsupported theory is not a counterexample.

---

# Part VI — Compiler and preservation contracts

## 51. Required pipeline and phase invariants

A conforming implementation separates the following roles even if some are fused for performance:

```text
Exact source + edition + environment
                  |
        Lexing and category-aware parsing
                  |
       Owned surface AST + source provenance
                  |
          Canonical syntax lowering
                  |
       Native-compatible elaboration / Meta
                  |
       Candidate canonical declarations
                  |
           Genuine kernel admission
                  |
               CheckedModule
                  |
        Relevance / erasure / runtime lowering
                  |
                 RuntimeIR
       +-----------+-------------+-----------+
       |           |             |           |
     TS AST      JS AST        Rust AST    Wasm IR
       |           |             |           |
      .ts         .js            .rs        .wasm
```

The parser does not decide theorem truth. The elaborator does not authorize its own declarations. A canonical codec does not replace kernel admission. A kernel proof does not establish erasure correctness. A target type checker does not establish ProofScript source correctness.

Each phase output must carry enough identity for diagnostics, reproducible checking, and evidence binding. Phase invariants are substantive: e.g. no unresolved metavariables at admission; no erased runtime dependencies in executable IR; no unknown target primitives at emission.

An API named `check` must describe what it actually checks. An admission-ready candidate must not be renamed `CheckedCore` or given a “kernel-admitted” generated-file banner until real admission occurs.

## 52. Surface AST and feature registry

Owned syntax nodes carry a feature ID, category, source span, child nodes, and the exact grammar-profile identity. Preserve native syntax information needed for elaboration, including identifier scopes and pre-resolved references.

A conceptual schema is:

```typescript
type SourceSpan = Readonly<{
  fileId: string;
  byteStart: number;
  byteEnd: number;
}>;

type OwnedNode = Readonly<{
  featureId: string;
  category: "term" | "command" | "header" | "field" | "localDecl";
  span: SourceSpan;
  children: readonly SurfaceNode[];
}>;

type SurfaceNode =
  | Readonly<{ kind: "owned"; value: OwnedNode }>
  | Readonly<{ kind: "native"; syntaxId: string; span: SourceSpan }>;
```

This is a transport/API illustration, not the full internal AST and not a security mechanism. A native node's `syntaxId` must refer to an actually parsed native tree with the required data; it must not hide arbitrary unchecked text.

The registry entry for every D/E feature includes category, discriminator, committed-error behavior, child-slot lifting, lowering relation, native target category, compatibility cost, introduced-version identity, dependencies, and positive/negative cases. New features cannot be enabled merely because their parser function happens to be linked.

The v0.9 additions are explicit: named arguments inside D-CALL, trailing commas in nonempty decorated lists, and the formerly implicit braced-instance family. Everything else in the owned base preserves or clarifies the v0.7 contract.

## 53. Parsing API and error recovery

A parser-ownership operation distinguishes:

```typescript
type Ownership<T> =
  | Readonly<{ kind: "owned"; node: T }>
  | Readonly<{ kind: "defer" }>
  | Readonly<{ kind: "committedError"; diagnostic: Diagnostic }>;
```

Once an owned discriminator commits, its grammar failure is not deferral. This distinction prevents malformed source from being reinterpreted through an unrelated permissive production.

Editor recovery may produce incomplete syntax nodes so that later declarations can still be displayed. Such nodes are provisional; they cannot enter an accepted module. A recovery parser and a release parser must agree on fully accepted source, and recovery must not change a valid earlier declaration to make a later error disappear.

Use explicit delimiter stacks and category stop conditions. Do not infer declaration ends from a raw brace counter that ignores strings, quotations, records, and nested tactics. A deterministic parser can still require environment state because imported notation and declarations affect native parsing.

An implementation must test committed-error behavior, not just successful lowering. Inputs with unmatched delimiters, duplicate named arguments, dangling commas, incomplete contracts, and unsupported patterns should identify the owned category and original source span.

## 54. Canonical lowering rules

The lowerer constructs native syntax trees with known categories. Producing text is a separate serialization step.

Let `L` be syntax-directed lowering and `Args` be one native application argument sequence:

```text
L(Call(h, [a1, ..., an])) = NativeApp(L(h), [LArg(a1), ..., LArg(an)])
L(Call(h, []))           = NativeApp(L(h), [NativeUnit])
LArg(Positional(e))      = NativePositional(L(e))
LArg(Named(n, e))        = NativeNamed(n, L(e))

L(Const(n, T?, e))       = NativeDef(n, [], L(T?)?, L(e))
L(Function(n, bs, T?, e))= NativeDef(n, flattenBinders(bs), L(T?)?, L(e))
L(IfBrace(c, t, e))      = NativeIf(L(c), L(t), L(e))
L(MatchBrace(ds, as))    = NativeMatch(map LDiscr ds, map LAlt as)
LAlt(patterns, rhs)     = NativeAlt(preserveNativePatterns(patterns), L(rhs))
```

Decorated call/list punctuation lowers to native syntax structure; it does not add core operations. Native sequence separators are interpreted in their own category, not discarded by a global punctuation pass. Names, binder kinds, order, modifiers, attributes, result annotations, and native options do survive where they affect meaning.

Class, structure, inductive, instance, and local `where` bodies lower to their corresponding native sequence categories. It is incorrect to collapse every braced form to a record or to convert every declaration to `def`.

Lowering should preserve each user subtree once unless the rule explicitly introduces a semantically justified transformation. Expected type propagation and elaboration happen after syntax construction. A textual unfolding of applications can lose expected-type information or alter insertion of defaults; use the native syntax relationship.

## 55. Binding, provenance, and source maps

Every user-originated node retains its original source association. Synthesized punctuation may have synthetic positions, but it must point through a provenance map to the owning source construct. Preserve nested expansion chains for imported macros and generated schema code.

The source map must distinguish:

```text
original source span
owned feature span
canonical syntax span
elaborated declaration/symbol
erased/runtime source association
final target position
```

Not every target instruction has a one-to-one source character. The mapping should represent generated/combined spans honestly rather than fabricate precision.

Renaming and formatting must operate on binding-aware structures. A fresh local name inserted by the lowerer cannot capture a free source name. Imported declaration names must resolve under the same environment as the intended canonical source, not the lowerer's current convenience namespace.

A formatter should preserve parser ownership. It may reformat an AST into a canonical equivalent spelling when the corresponding structural transformation is defined; it must not treat trivia changes as universally harmless around D-CALL.

## 56. Elaboration and declaration admission

Reference elaboration uses the exact selected Lean environment. Standalone elaboration owes the same claimed result relation for supported source, including typeclass/coercion selection and generated auxiliaries.

A successful declaration bundle has resolved names and metavariables, scoped universe parameters, correct dependencies, and explicit declaration kinds. A module checker reconstructs or imports only genuinely checked dependency state. Caller-provided environments must not smuggle unchecked declarations into erasure.

Admission should be transactional: a failed declaration/module does not leave partially installed constants or cache facts visible to subsequent accepted checks. Caches must be keyed by relevant environment, context, transparency, universe, and policy identities. A type inferred under one context is not globally reusable by expression hash alone.

A checked artifact should be an instance-owned immutable handle or equivalent validated state, not merely a caller-constructible TS object with a Boolean field. Serialized artifacts are rechecked or imported through a sound evidence protocol. TypeScript branding alone cannot sandbox malicious same-process code.

## 57. Comparing reference and production frontends

Conformance must name the relation being checked:

| Relation | What is compared |
|---|---|
| Syntax identity | Native syntax trees, including required category/binding structure. |
| Defined normalization | Trees after a precisely specified, semantics-preserving normalization. |
| Elaborated correspondence | Admitted declarations related under a stated mapping of names/environments. |
| Runtime preservation | Observable execution under a representation/effect/resource relation. |

Hash equality can identify exact byte equality. Unequal hashes say nothing decisive about semantic equality; equal untrusted labels do not prove that the checked objects match. A normalization must not delete an important modifier, assumption, or side effect to force agreement.

Use the reference corpus to compare decorated source with its canonical Lean output. Include intentional mismatches and altered dependencies. The oracle should check the expected statement, not only whatever statement the candidate exporter supplied.

“Lean accepted it” is not proof that it means what the source intended. “Two checkers accepted it” is not a formal equivalence theorem between the checkers. These remain valuable but bounded observations.

## 58. Erasure and executable IR

Erasure operates on genuinely admitted declarations and a relevant executable environment. It removes proofs/types only where computational irrelevance is justified.

The erasure result records runtime parameters, retained values, constructor tags/fields, dependencies, and capability requirements. It must preserve the order and identity of runtime arguments after proof-parameter removal. It must not confuse a proof argument with a data argument whose type mentions a proof.

RuntimeIR describes the selected PSC/Lean executable meaning. It may contain functions, calls, bindings, constructor/projection operations, structured control flow, semantic primitive identities, and explicit capability operations. It must not define `Nat` as JS `number`, a structure as a Rust layout, or an effect as a Wasm opcode.

Backend representation choices belong in later target IR. The name `VerifiedIR` in an implementation is not a preservation theorem. Its acceptance conditions and associated evidence must be explicit.

If a runtime dependency is noncomputable, unsupported, unknown, or unsafely replaced without sufficient assurance, the compiler rejects the requested executable claim. It must not insert a stub, throw at an arbitrary reachable point, or call another checker as a hidden fallback.

## 59. Preservation propositions and certificates

A useful pure-program preservation theorem relates source and target through representation functions/relations:

```text
For every admitted input x and related target input tx:
    source execution and target execution have corresponding outcomes,
    with related results and the specified termination/resource behavior.
```

For effects, include observable traces and state relations. For nondeterministic models, refinement may be the appropriate relation. One must state which direction is proved; agreement only when both terminate is weaker than total-correctness preservation.

Prove regular transformations and runtime representation lemmas once. For changing or complex transformations, a proof-producing compiler may emit a certificate `c` for the concrete pair `(S,T)`, checked by a validator with the theorem:

```text
validate(S, T, c) = accepted  ->  Preserves(S, T)
```

The validator's soundness, evidence evaluation, and connection to actual artifacts are obligations. A checker named `validate` or a solver-generated Boolean is not sufficient.

Semantics and preservation relations can be ordinary formal definitions over ASTs. The logical kernel need not grow trusted TS/Rust/Wasm instructions. CompCert is a methodological precedent for carefully scoped compiler preservation, not a source of automatically applicable PSC proofs. [P4]

## 60. Target routes and external compilers

The language permits multiple routes over one meaning:

| Route | Use | Additional assurance boundary |
|---|---|---|
| TS source → external TS compiler → JS | Readable `.ts`, ecosystem integration, bootstrap. | Actual TS transformations/configuration and final JS. |
| Direct JS | ESM/application output. | JS lowering, printer, runtime helpers, engine. |
| Rust source → native/Wasm toolchain | `.rs` libraries and native/Wasm deployment. | Rust lowering, dependencies, compiler/linker/target behavior. |
| Direct Wasm | Explicit portable runtime/ABI profile. | Runtime representation, binary encoder, imports, engine. |

Owning a backend does not prove it. Using an external compiler does not invalidate the source theorem, but transfers to final-executable guarantees need the intervening relationships or explicit assumptions.

A restricted TS profile can support validation of actual `tsc` output against certified type-erased TS meaning. This is downstream translation validation, not an additional JS emitter. Every allowed transform or normalization still needs justification.

For Rust, safe source and successful `rustc` checks do not prove functional equivalence. Native and Wasm have different capabilities and target assumptions. A bounded validator for one optimization stage does not certify the whole downstream toolchain.

A Wasm validator checks module well-formedness, not the source contract. Direct Wasm still needs exact numbers, strings, ADTs, closures, memory/resource behavior, and host interfaces. No route may use a foreign runtime operation as hidden logical evidence.

## 61. Exact emitted artifacts, linking, and release snapshots

A proof about a target AST does not cover a printer that changes an operator or swaps arguments. Establish a verified/certified serializer or independently parse the emitted file and validate it against the proved target.

The checked identity covers the source, canonical declarations, runtime IR, target files, linked runtime, imports, compile options, ABI, and allowed assumptions. The release must use that exact immutable snapshot.

Bundling, minification, tree shaking, link-time optimization, framework transforms, or post-check edits may change behavior. They need evidence under the claimed preservation endpoint or must remain explicit assumptions. A source map or checksum does not prove that they are correct.

External consumers need interfaces that enforce or state the represented input domain. A TS `bigint` parameter is not a proof that the supplied integer is nonnegative. Proof-erased internal APIs should be exported through appropriate validators or a clearly restricted internal ABI.

## 62. Resource limits and checker build trust

A mathematical termination proof does not guarantee sufficient time, memory, stack, or operating-system resources on every machine. A certified executable profile either proves required bounds, permits specified resource outcomes, or states environmental assumptions.

Resource bounds on checking and compilation are equally explicit. Exhaustion cannot turn into a success stub, incomplete emitted artifact, or an unbounded hidden retry through another provider. Partial work is not accepted state.

A compiler generating proof candidates may be outside logical authority when an independent checker checks them. A compiler building the checker executable has a build-trust role: miscompilation could alter its acceptance behavior. Record and strengthen that chain through pinned builds, independent replay, diverse implementations where useful, and ultimately appropriate preservation evidence.

Self-hosting is actual generated-compiler execution and a stated fixed-point relationship. It is not a logical consistency proof and does not remove a compromised-seed concern merely by repetition. The compiler and kernel can be jointly bootstrapped without claiming that their source admission proves their implementations correct.

---

# Part VII — Libraries, interoperability, and applications

## 63. Standard library layering

The language foundation is small; the useful platform need not be. Application capabilities should be ordinary definitions, specifications, generators, and explicit adapters rather than a collection of new trusted constructs.

A standard distribution should separate:

| Layer | Responsibility |
|---|---|
| Pinned native foundation | The selected `Init`/`Std` declarations and exact logical semantics. |
| Portable data | Collections, text/bytes, codecs, domain data, and algorithms. |
| Specification libraries | Laws, program models, invariants, and admitted specification theorems. |
| Platform interfaces | IO, network, time, randomness, storage, process, UI, and resource models. |
| Runtime adapters | Actual JS/native/Wasm operations and their stated assumptions/evidence. |
| Tooling | Build, editor, test, document, import-generation, and migration services. |

The exact library API is independently versioned. This reference does not claim that the illustrative `Psc.*` namespaces exist today. A package may implement them without adding a new parser production when ordinary Lean definitions suffice.

Proof-only library dependencies may be removed from runtime only through justified erasure. Conversely, importing a theorem package must not implicitly enable browser capabilities or execute an unapproved build script.

## 64. Packages and logical modules

Follow the v0.7 JS-ecosystem direction: npm/package.json is the primary JS package substrate, with a namespaced ProofScript configuration and a reproducible dependency lock. Do not create an accidental second package-resolution authority in competition with npm while claiming the same dependency identities. A Lean/Lake oracle workspace can be generated explicitly from the selected source/module manifest.

The configuration records source edition, semantic pin, entry modules, unique source mapping, allowed compiler extensions, dependencies, target profiles, runtime ABI, capabilities, and assurance policy. Each identifier has a distinct role; package semver does not stand in for a Lean semantic version.

The logical source graph, elaboration/plugin graph, proof dependency graph, and runtime graph are distinct. All can be recorded without making every graph a bootstrap prerequisite.

Canonical `.ps` generation is an artifact, not a competing handwritten source implementation. A manifest identifies authoritative source and generated traces. Duplicate logical sources, import cycles unsupported by the module model, missing modules, symlink escapes, and target-incompatible dependencies must be diagnosed before a release claim is produced.

Package installation, macro execution, and proof checking are different permissions. Reading an import does not authorize an arbitrary installation script. Integrity/signature checks establish origin or byte identity, not semantic correctness.

## 65. Foreign interfaces and typed boundary values

Foreign interfaces are not part of the logical kernel. A versioned InterfaceIR or equivalent adapter contract can generate native declarations, `.ps` interfaces, wrappers, target bindings, and documentation.

Distinguish:

1. **Owned data:** decoded/copied values satisfying the PSC representation invariant.
2. **Foreign handles:** identity-bearing or mutable objects whose operations are explicit effects.
3. **Foreign operations:** calls with specified argument/result conversions, receiver, effects, and lifetime.

A foreign API declaration records package/export identity, target-resolution conditions, parameter/result representations, optionality, receiver binding, errors, synchrony, callbacks, resource behavior, and model/assumption status.

No arbitrary external signature returning a proof of `P` or a value of an unconstrained empty type can become a proof oracle. At a dependent boundary, runtime data must be validated or accompanied by independently checked evidence before it receives an invariant-bearing type.

A `.d.ts` importer supports a declared subset and rejects unsupported structural/type-level machinery rather than lowering it to a native unchecked `any`. An imported type annotation is not a theorem about a foreign implementation. Advanced conditional/mapped/template types may be specialized in an untrusted import phase, but the resulting interface still needs a correct mapping and an honest runtime boundary. [T2–T4]

## 66. Data conversion, callbacks, and Promise adaptation

For a JS data boundary, distinguish missing field, present undefined, null, and present value when the API does. A codec may deliberately map some of these to `Option.none`; it must not claim a general inverse if information was lost.

A decoder of arbitrary JS objects must account for getters, proxies, mutation, and reentrancy. “Read a property” may itself be an effect. Prefer a controlled data snapshot or explicitly model the operation. A structural TypeScript type is not proof that an object is immutable plain data.

Numeric conversions check the required domain. JS `number` to Nat needs the selected finite/integral/range contract. JS BigInt to Nat still needs nonnegativity. Exact large integers may require a specified JSON string/tag encoding rather than ordinary JSON numeric precision.

Foreign methods preserve the receiver. Callback interfaces specify whether calls are immediate/deferred, one-shot/repeated, reentrant, retained, and allowed after disposal. Registration should return a scoped handle when lifetime management is required.

An existing Promise may already be running. Attaching to it differs from starting a cold cancellable computation. Abort/cancellation support, rejection reasons, and late completions are explicit adapter semantics. The base does not assert Promise equivalence to native Lean `Task` or a proposed `Psc.Async` model.

## 67. Exporting libraries and complete applications

A JS package may contain ESM, `.d.ts`, source maps, runtime dependency identities, canonical declaration/proof bundles, and an assurance manifest. TS and Rust source artifacts remain valid deliverables when those routes are selected.

Erased proof parameters are not advertised as runtime arguments. APIs with constrained inputs require validating wrappers or a documented restricted ABI; nominal branding in `.d.ts` assists static users but does not constrain arbitrary JavaScript callers.

Complete supported applications should be authorable in `.ps` or `.lean`: domain models, codecs, routing, services, UI definitions, orchestration, and selected proofs. Foreign adapters inside the distribution do not require every user to hand-write TS glue, nor do they imply that the browser/database/framework was rewritten or verified.

Client/server separation needs transitive capability checks and explicit serialization, not merely shared type names. Framework transforms, secret access, side effects during module initialization, worker packaging, and server rendering each require tested deployment profiles.

A full-app acceptance corpus should include a browser/service application with typed errors, malformed-input handling, persistence, cancellation, and one useful verified domain transition. A proof about the in-memory transition does not automatically establish database isolation or network correctness.

## 68. Optional UI syntax and other extensions

The base does not admit JSX/TSX, a `component` declaration, or a new brace-return language. An optional `.psx` dialect must have an explicit extension ID and grammar, typed interpolation categories, hygienic expansion, source maps, and paired plain-library examples.

Prefer a term-local quotation over a second whole application language. The expansion should construct ordinary view/component values that can also be written using base `.ps` or native `.lean`. No unchecked JavaScript expression is silently accepted inside interpolation.

Props, children, events, keys, raw HTML, resource lifetimes, and renderer operations require defined library meanings. A React adapter must obey the framework's lifecycle constraints; well-typed view construction alone does not prove renderer correctness, hydration equivalence, accessibility, or injection freedom.

New syntax passes the same proposal test as the base: exact category, discriminator, lowering, environment, interaction cases, evidence status, and migration. Until that contract exists, a markup illustration is **extension pseudocode**, not v0.9 source.

---

# Part VIII — Tooling, migration, and release assurance

## 69. Canonical formatting

A conforming formatter preserves parsed meaning, ownership categories, names, comments, and the selected environment. Suggested `.ps` style uses `name: Type`, spaces around `:=`, adjacent decorated calls, and multiline native-compatible layout. It emits no ProofScript-only declaration, field-declaration, constructor, or match-alternative semicolons. Native `.lean` traces use ordinary Lean style.

```text
f(x, y)       not interchangeable by whitespace alone with f (x, y)
.some x       a pattern; do not format it into .some(x)
function ... := { ... }     no added declaration terminator
match ... with { ... }     native alternatives without added terminators
let x := e; body            preserve native let/body separation
do { action; return x; }    preserve native sequence separators
by { t1; t2 }               preserve native sequencing
by { t1 <;> t2 }            preserve the different all-goals combinator
```

Use layout rather than optional native separators where that is the canonical presentation and reparsing preserves the same AST. Compact native `let`, `do`, instance-initializer and local-`where` sequences may retain their legal semicolons. Never infer ownership by matching `};` or by deleting every line-ending `;`. A `;` inside a literal, comment or quotation is not formatting punctuation at all.

The formatter must round-trip AST/category identity up to its stated normalization. Test multiline applications, nested matches, nested proof/do sequences, suffix attachment, and native `;`/`<;>` separately. Formatting incomplete source may preserve unrecovered regions verbatim or report inability; it must not hide an error by producing accepted code with another meaning.

Formatting and migration are distinct operations. The r2 formatter rejects or preserves unsupported legacy syntax for an explicit migrator; it does not silently parse it under the previous draft and emit a new interpretation. A formatting rule cannot broaden the grammar or establish compiler preservation.

## 70. Diagnostics and language-server information

Diagnostics include a stable code, category, original span, related/expanded spans, selected profile, and actionable explanation. Avoid opaque target-language errors when the actual failure concerns an unsupported source feature or missing adapter.

The LSP/CLI should expose inferred types, selected methods, inserted arguments, coercions, instances, constraints, proof goals, assumption dependencies, canonical lowering, and target-capability requirements.

Cached diagnostics and proof results must be tied to source/environment identities. Changed imports, instances, options, specification predicates, or runtime implementations invalidate affected evidence. Stale successful results must not be displayed as current verification.

Suggested CLI capabilities—not claims of currently implemented commands—are source checking, canonical Lean emission, conformance testing, explanation, manifest inspection, formatting, tests, target builds, and independent artifact verification. Command spelling can evolve without changing the underlying language protocol.

## 71. Migration from v0.7 and earlier PSC3/v0.9 drafts

This is v0.9.0 **draft revision 2**, grammar identity `ps-0.9-r2`. Existing v0.7, PSC1/PSC2 and earlier v0.9-draft source keeps its declared interpretation. Version `0.9.0` alone is insufficient to distinguish these unfrozen drafts: record the grammar revision and exact registry/reference identity. The migrator parses the old grammar first and produces an explicit new source artifact.

| Earlier construct or proposal | Revised v0.9 treatment |
|---|---|
| `def`, `const`, `function` aliases, explicit parameters, D-CALL | Retained with faithful native semantics. |
| `D-DECL-SEMI` at the end of owned definitions | Retired from the r2 default. Remove only the old AST's added command terminator. |
| Added `;` after structure/class field declarations, constructors or match alternatives | Replace with native-compatible member/alternative layout; do not concatenate entries blindly. |
| Semicolons inside native `let`, `do`, tactics, instance initializers and local `where` sequences | Retain according to the corresponding native category. |
| Plain tactic `;` versus `<;>` | Preserve the original combinator and goal behavior. |
| Omitting `;` only after a closing brace | Replaced by the uniform rule: no added command terminator, regardless of the body's last token. |
| `.ps` as byte-identical `.lean` | Not adopted; D/E source still has explicit canonical lowering. |
| Removing D-CALL adjacency | Not adopted; tuple/protected-neighbor behavior is unchanged. |
| Bare `function ... { ... }`, TS arrow lambdas or implicit nullability | Still outside the base grammar. |
| Named arguments and trailing commas in D-CALL | Retained with their existing narrow contracts. |
| `E-INSTANCE-BODY` / `E-WHERE-BODY` | Retained; follow native sequence rules rather than impose mandatory semicolons. |
| Mandatory direct JS/Wasm switch | Still not a syntax-revision requirement; existing backend plans remain independently gated. |

A legacy top-level `const x: Nat := 1;` becomes `const x: Nat := 1`. A legacy body containing `let y := e; y` keeps that **inner** semicolon. A braced `do` ending in a native sequence semicolon retains it while any separate legacy declaration terminator is removed. A literal such as `"const x = 1;"` remains byte-identical.

No regex/global punctuation deletion is a valid migrator. Preserve binders, native application groups, tuple arity, layout-sensitive boundaries, suffix association, source positions, proof statements and assumptions. A changed grammar revision invalidates dependent parser/formatter caches and source-correspondence certificates; unchanged canonical Lean evidence may be reused only under the independently specified evidence policy.

The original v0.7 corpus remains untouched at its pinned repository location. The earlier v0.9 artifact is an archived draft, not a second silently accepted default grammar. Current conformance expectations identify r2 explicitly, retain case IDs where revised, and record changed outcomes in the revision notes.

## 72. Source and specification compatibility

Source syntax, elaboration behavior, logical assumptions, library APIs, proof scripts, portable bundles, runtime ABI, and backend preservation profiles have separate compatibility dimensions. Record them independently.

A tactic change may break proof-script replay while leaving the theorem meaningful. A source-compatible library change may alter runtime behavior or add a trusted assumption. A new optional syntax registration may collide with a previously imported parser. Each requires the appropriate version/review boundary.

A `.ps` file is not silently reclassified by its contents. Project metadata selects edition and extension environment. Mixed-version packages either use a supported adapter/canonical bundle boundary or are rejected.

Source compatibility is not a reason to retain an unsound implementation bug. A corrective release should identify the change and replay the relevant negative corpus. It must not conceal a reduced acceptance set as “no changes” merely because the surface grammar is unchanged.

## 73. Conformance program

The included `conformance/cases.jsonl` is an authored contract corpus. Cases state source category, required features, expected phase outcome, and canonical form or diagnostic where specified. They are not a claim that an owned parser already executes them.

Required test families include:

| Family | Essential positive and negative cases |
|---|---|
| Lexical/category ownership | Native comments, Unicode, delimiters in strings, committed failures, unknown extensions. |
| Calls | Unit, tuple, currying, nested groups, receiver position, named/default args, trailing commas. |
| Headers/declarations | Alias restrictions, binders, dependent order, modifiers, native boundaries, invalid layout, obsolete added terminators, suffixes. |
| Data/patterns | Dependent records, inherited parents, constructor terms versus patterns, indexed motives. |
| Effects/control | Native braced do, loops, mutation/capture, transformer order, partiality-sensitive optimization. |
| Proofs | False proofs, hidden assumptions, tactic categories, exact statement/dependency binding. |
| Intrinsic contracts | Valid and false clauses, duplicate clauses, missing evidence, loop capability restrictions. |
| Runtime/FFI | Numeric/string boundaries, stale callbacks, foreign receivers, malformed values and unknown capabilities. |
| Artifacts | Altered emitted bytes, wrong runtime identity, forged checked handles, cache context mismatches. |

The actual v0.7 positive/negative/lowering corpus remains a compatibility input. Updating v0.9 must not silently redefine those earlier expectations. Any case whose source relies on an under-specified v0.7 combination must be classified explicitly as clarified, newly specified, or unsupported.

## 74. Implementation and release gates

A useful sequence is:

1. Load the pinned environment/feature registry and validate version identities.
2. Implement category-preserving parsing and diagnostic ownership.
3. Implement canonical lowering for the old core decorations and new explicit v0.9 additions.
4. Compare canonical outputs and negative cases against pinned Lean.
5. Establish genuine declaration admission and immutable checked-state handling.
6. Complete an explicit executable primitive/data/call profile and target conformance.
7. Build a useful application and theorem corpus with exact assumptions.
8. Prove reference properties and incrementally establish production refinement/preservation.

Tests, proofs, and usability studies provide different evidence. The release label must not exceed its weakest relevant required boundary. A compiler that parses all examples but cannot check them is not a complete implementation. A kernel that checks generated proofs but cannot relate them to the requested source is not an end-to-end source verifier.

The language can support useful type-checked applications before every preservation theorem exists, provided their compilation/runtime assumptions are explicit. It must not call those applications fully proved simply because the user selected a strict-sounding flag.

---

# Part IX — Consolidated grammar and reference tables

## 75. Grammar notation and scope

This grammar specifies the owned overlay. `Native<C>` denotes the exact selected native parser/category `C`; `Lift<C>` replaces only approved recursive child slots with the corresponding ProofScript parser. It is a typed grammar dependency, not “any text until the next delimiter.”

`ADJ` means byte-adjacent token boundaries with no intervening whitespace/comment. `?`, `*`, and `+` are grammar multiplicities; quoted tokens are literal tokens. Square brackets in productions below indicate optional grammar unless quoted. Semantic predicates after productions are mandatory.

The composition, precedence, and committed-error rules in §§11–16 resolve overlaps. A parser generator must not treat the displayed alternatives as an unordered permissive union. Native declaration and tactic end conditions are supplied by their exact categories, not a universal newline heuristic.

## 76. Owned grammar

```ebnf
PSFile              ::= Lift<NativeCommandSequence(PSCommand)> EOF ;
PSCommand           ::= OwnedValueDecl
                      | BracedStructure | BracedClass | BracedInductive
                      | BracedInstance | Lift<NativeCommand> ;
OwnedValueDecl      ::= Native<DefModifiers> ConstDecl
                      | Native<DefModifiers> FunctionDecl
                      | Native<DefModifiers> DecoratedDef ;
ConstDecl           ::= "const" Native<DeclId> ResultSpec? OwnedValue ;
FunctionDecl        ::= "function" Native<DeclId> HeaderBinders
                        ResultSpec? NativeContracts? OwnedValue ;
DecoratedDef        ::= "def" Native<DeclId> HeaderBinders?
                        ResultSpec? NativeContracts? OwnedValue ;
HeaderBinders       ::= HeaderBinder+ ;
HeaderBinder        ::= ExplicitGroup | Native<OtherDeclarationBinder> ;
ExplicitGroup       ::= "(" ExplicitEntry ("," ExplicitEntry)* ","? ")" ;
ExplicitEntry       ::= Native<BinderIdent> ":" PSTerm Native<DefaultSuffix>? ;
ResultSpec          ::= ":" PSTerm ;
OwnedValue          ::= ":=" PSDeclBody Native<TerminationSuffix>?
                        WhereSuffix? ;
PSDeclBody          ::= Lift<NativeDeclBody> ;
WhereSuffix         ::= BracedWhere | Lift<NativeWhereDecls> ;
BracedWhere         ::= "where" "{" NativeLocalSequence "}" ;
NativeLocalSequence ::= Lift<NativeWhereLocalSequence> ;
BracedStructure     ::= Native<StructurePrefixAndHeader> "where"
                        "{" NativeFieldSequence "}" Native<DerivingSuffix>? ;
BracedClass         ::= Native<ClassStructurePrefixAndHeader> "where"
                        "{" NativeFieldSequence "}" Native<DerivingSuffix>? ;
NativeFieldSequence ::= Lift<NativeStructFields> ;
BracedInductive     ::= Native<InductivePrefixAndHeader> "where"
                        "{" NativeConstructorSequence "}" Native<InductiveSuffix>? ;
NativeConstructorSequence ::= Lift<NativeConstructorSequence> ;
BracedInstance      ::= Native<InstancePrefixAndHeader> "where"
                        "{" NativeInstanceFieldSequence "}" ;
NativeInstanceFieldSequence ::= Lift<NativeWhereStructInstFields> ;
PSTerm              ::= Lift<NativeTerm> | DecoratedCall | BracedIf | BracedMatch ;
DecoratedCall       ::= CallableHead ADJ "(" CallArguments? ")" ;
CallArguments       ::= CallArgument ("," CallArgument)* ","? ;
CallArgument        ::= NamedCallArgument | PositionalCallArgument ;
NamedCallArgument   ::= Native<Ident> ":=" PSTerm ;
PositionalCallArgument ::= PSTerm ;
CallableHead        ::= Native<CompatibleCompletedHead> | "(" PSTerm ")"
                      | DecoratedCall | NativeProjectionOfCompletedHead ;
BracedIf            ::= "if" "(" PSTerm ")" "{" PSTerm "}"
                        "else" "{" PSTerm "}" ;
BracedMatch         ::= Native<MatchPrefixAndDiscriminantsWithLiftedTerms>
                        "with" "{" NativeMatchSequence "}" ;
NativeMatchSequence ::= Lift<NativeMatchAlts> ;
PSDo                ::= Lift<NativeDoTerm> ;
PSProof             ::= Lift<NativeProofTerm> ;
PSTactic            ::= Lift<NativeTactic> ;
PSPattern           ::= Native<Pattern> ;
```

Mandatory predicates and clarifications:

- `function` has at least one nonempty explicit parameter group; `const` has no declaration binders.
- The single-entry explicit group follows native binder meaning. The comma-list owns the additional complete entries; no missing per-entry type is inferred by punctuation.
- Native multi-name binders and implicit/instance binders are inherited, not comma-rewritten.
- A trailing comma requires at least one entry and is owned only by `D-TRAILING-COMMA`.
- Duplicate named arguments in one D-CALL are rejected. Named matching remains native elaboration.
- Empty structure/inductive bodies are syntactic candidates only where the native lowered declaration is legal; formation/elaboration can reject them.
- Native structure parent/constructor and inductive result information resides in the header categories and must be preserved.
- There is no quoted `";"` production in an owned declaration or wrapper. Rule-final unquoted semicolons above are **EBNF notation**, not ProofScript tokens. All source semicolons come from the incorporated native categories.
- `NativeContracts` is the exact pinned optional requires/ensures category, enabled only with the declared intrinsic capability.
- The `where finally` verification suffix remains native unless an exact composition rule enables it. It is not an arbitrary command inside `NativeLocalSequence`.
- `PSTerm` does not create `PSTactic` or `PSPattern` productions implicitly.
- A native parenthesized tuple remains one term. An outer decorated comma never splits its contents.

### 76.1 Exact sequence dependencies

The sequence nonterminals above are incorporated parser compositions, not new permissive repetitions:

| Nonterminal | Pinned composition | Semicolon ownership |
|---|---|---|
| `PSDeclBody` | `Command.declBody`, with registered term slots lifted | No additional terminator; preserve the special native `by` boundary handling. |
| `NativeFieldSequence` | `Command.structFields` with its native field binders and layout checks | No extra field separators. |
| `NativeConstructorSequence` | The `many ctor` constructor sequence of `Command.inductive` | Native constructor marker/header boundaries, no extra `;`. |
| `NativeMatchSequence` | `Term.matchAlts`, using `matchAlt` and native pattern groups with a lifted RHS | No extra alternative separator. |
| `NativeInstanceFieldSequence` | The `Term.structInstFields (sepByIndent Term.structInstField "; " (allowTrailingSep := true))` portion of `Command.whereStructInst` | Native semicolons retained. |
| `NativeLocalSequence` | The `sepByIndent (ppGroup letRecDecl) "; " (allowTrailingSep := true)` portion of `Term.whereDecls` | Native semicolons retained. |
| Native `do` / tactic sequence | `Parser.Do` / `Parser.Tactic` and selected registrations | Preserve each category's exact sequence/combinator grammar. |

The owned braces add only a delimiter-scoped sequence position and matching-close condition; the native member parser, relative layout checks and nested continuations remain active. Canonical text printing may reindent an already parsed AST with a source map; it may not first strip braces/newlines and ask Lean to guess the AST. Unsupported layout combinations reject explicitly. Every wrapper requires standalone/reference composition tests before implementation support is claimed. [L2–L3]

## 77. Native category dependency map

These dependencies identify where a compiler must obtain inherited grammar behavior. Paths are relative to `study/lean4-4.34.0/src/Lean/` at the pinned repository snapshot.

| Category/concept | Primary source dependency | Required preservation |
|---|---|---|
| Tokenization and parser combinators | `Parser/Basic.lean`, `Parser/Types.lean` and lexer support | Token boundaries, trivia, positions, commit/recovery. |
| Native terms and arguments | `Parser/Term.lean`, `Parser/Term/Basic.lean` | Application groups, named/default arguments, binders, records, matches. |
| Native do sequences | `Parser/Do.lean` | Braced/layout sequence, separators, nested actions, loops, return. |
| Commands/declarations | `Parser/Command.lean` | Declaration kinds, modifiers, contracts, suffixes, stateful scopes. |
| Proof/tactic sequences | `Parser/Tactic.lean` and imported tactic registrations | Tactic combinators, term slots, proof state. |
| Modules | `Parser/Module.lean`, `Parser/Module/Syntax.lean` | Imports, module modes, visibility and dependency state. |
| Universes | `Parser/Level.lean` plus semantic level definitions | Exact level expressions and parameter scope. |
| Attributes/notation/macros | `Parser/Attr.lean`, `Parser/Syntax.lean`, `Parser/Extension.lean` | Registrations, scope, hygiene, collision policy. |
| String interpolation | `Parser/StrInterpolation.lean` | Literal segments and term-interpolation boundaries. |
| Intrinsic verification | `Parser/Command.lean`, `Parser/Do.lean`, `Std.Internal.Do` | Native clauses, assertions, invariants, generated specs. |

The exact transitive source and registration set is an environment manifest requirement. The root paths alone do not claim a complete dependency-closure audit. Imported libraries can introduce further syntax; they are pinned and registered explicitly.

A compiler may vendor or mechanically derive its native grammar tables, or use the official frontend as an oracle. It may not replace a difficult category with an approximate textual grammar while advertising identical coverage.

## 78. Feature registry summary

| ID | Class | Category | v0.9 disposition | Canonical target |
|---|---|---|---|---|
| `L-CORE-LEAN` | L | Registered native categories | Inherited, capability-scoped. | Same native syntax and meaning. |
| `L-DO-BRACKETED-434` | L | Term/do sequence | Confirmed in pinned source and canonical example. | Native braced/layout do AST. |
| `L-INTRINSIC-CONTRACTS-434` | L | Declaration/do | Experimental, explicitly selected. | Native specification mechanism. |
| `L-ERASED-DO-434` | L | Do element | Inherited capability. | Native verification-only binding. |
| `L-RECALL-434` | L | Command | Inherited capability. | Native checked restatement, not new declaration. |
| `L-MONOTONICITY-BY-434` | L | Declaration suffix | Inherited capability. | Native contextual suffix. |
| `L-LIA-GROBNER-PARAMS-434` | L | Tactic | Inherited capability. | Native tactic parameter parsing. |
| `D-CALL` | D | Term | Retained. | One native application argument sequence. |
| `D-EXPLICIT-PARAMS` | D | Decl/field/local header | Retained; scope explicit. | Ordered explicit native binders. |
| `D-CONST-ALIAS` | D | Command head | Retained. | Parameterless native `def`. |
| `D-FUNCTION-ALIAS` | D | Command head | Retained. | Native `def`, explicit parameter required. |
| `D-NAMED-CALL` | D | D-CALL argument | Newly specified. | Native named argument. |
| `D-TRAILING-COMMA` | D | Decorated nonempty list | Newly specified. | No additional argument/binder. |
| `E-IF-BRACE` | E | Term | Retained. | Native conditional, one term per branch. |
| `E-STRUCT-BODY` | E | Structure fields | Retained, r2 native-layout body. | Native field sequence, no added semicolons. |
| `E-CLASS-BODY` | E | Class fields | Retained, r2 native-layout body. | Native class field sequence, no added semicolons. |
| `E-INDUCTIVE-BODY` | E | Constructor list | Retained, r2 native sequence. | Native constructors/suffixes, no added terminators. |
| `E-INSTANCE-BODY` | E | Instance fields | Newly explicit registration. | Native instance field sequence. |
| `E-MATCH-BODY` | E | Match alternatives | Retained, r2 native sequence. | Native patterns/RHS boundaries, no added terminators. |
| `E-WHERE-BODY` | E | Local declarations | Retained. | Native local declaration sequence. |

The machine-readable registry contains **20 active feature records** and a separate retired-feature record for `D-DECL-SEMI`. The registry includes the grammar revision; unchanged feature IDs do not imply unchanged old separator contracts. Historical feature ID aliases must have an explicit mapping rather than silently claiming new proof status. Every row's present implementation-proof status is specified/inherited-contract, not production-proved by this document.

## 79. Diagnostic catalog

The following diagnostic categories are normative; wording and additional payloads can improve without changing meaning.

| Code | Condition |
|---|---|
| `PS_VERSION_MISMATCH` | Source/reference/environment identity incompatible. |
| `PS_UNSUPPORTED_FEATURE` | The selected implementation cannot honor a required feature. |
| `PS_UNREGISTERED_EXCEPTION` | An unregistered owned syntax extension is requested. |
| `PS_AMBIGUOUS_OWNERSHIP` | Competing source productions lack a declared compatibility rule. |
| `PS_CONST_WITH_PARAMS` | Declaration binders supplied to `const`. |
| `PS_FUNCTION_WITHOUT_PARAMS` | `function` lacks a nonempty explicit parameter group. |
| `PS_EMPTY_PARAMETER_GROUP` | Empty group used where an explicit declaration parameter is required. |
| `PS_UNEXPECTED_SEMICOLON` | A semicolon is not consumed by any valid active native category; legacy added terminators are not accepted in r2. |
| `PS_INVALID_LAYOUT` | An owned body fails its incorporated native layout/member-boundary contract. |
| `PS_EXPECTED_COLON_EQUALS` | An owned definition/binding uses an inadmissible body delimiter. |
| `PS_BLOCK_BODY_NOT_ADMITTED` | Bare brace-bodied function syntax requested. |
| `PS_EMPTY_LIST_ENTRY` | Empty/doubled decorated call/header entry. |
| `PS_DUPLICATE_NAMED_ARGUMENT` | Duplicate explicit named key in one decorated call. |
| `PS_NAMED_ARGUMENT_SYNTAX` | Unregistered named-argument spelling, such as `name: value`. |
| `PS_IF_REQUIRES_PARENS` | Braced conditional missing its condition parentheses. |
| `PS_BRANCH_REQUIRES_SINGLE_TERM` | A braced conditional branch contains an unregistered statement list. |
| `PS_PATTERN_CALL_NOT_ADMITTED` | D-CALL attempted in a native pattern position. |
| `PS_UNSUPPORTED_COMPOSITION` | Individually known features combined in an unsupported native category. |
| `PS_NATIVE_ELABORATION` | Canonical native elaboration rejects the candidate. |
| `PS_UNRESOLVED_METAVARIABLE` | A release declaration still contains an unresolved semantic hole. |
| `PS_KERNEL_REJECTION` | Actual declaration admission fails. |
| `PS_ASSUMPTION_POLICY` | A theorem depends on a disallowed assumption or shortcut. |
| `PS_INCOMPLETE_PROOF` | Required evidence was not established. |
| `PS_DEPENDENT_FIELD_MISMATCH` | An update/constructor cannot retain a field at its required type. |
| `PS_MODULE_AMBIGUITY` | More than one unselected source for a logical module. |
| `PS_MISSING_DEPENDENCY` | A required source/declaration/runtime dependency is unavailable. |
| `PS_NONCOMPUTABLE_EXECUTION` | A runtime request reaches an unavailable noncomputable realization. |
| `PS_RUNTIME_PRIMITIVE_UNSUPPORTED` | No faithful selected target implementation for a primitive. |
| `PS_FOREIGN_BOUNDARY` | Input/output conversion or external capability fails its contract. |
| `PS_ARTIFACT_IDENTITY_MISMATCH` | Evidence does not bind the bytes/dependencies being consumed. |
| `PS_RESOURCE_LIMIT` | Explicit time/fuel/memory/size budget exhausted. |
| `PS_CANCELLED` | The operation was cancelled without accepted completion. |
| `PS_INTERNAL_ERROR` | An unexpected implementation failure, never successful evidence. |

Native diagnostics can be attached as structured causes rather than replaced with an invented exact code. For example, the current Lean oracle reports a type mismatch for an invalid dependent update; an owned frontend can map that to a more specific user-facing category.

## 80. Normative lowering examples and pitfalls

The following table defines small relationships for the overlay, assuming identifiers/types exist in the declared environment. Parsing a term is not the same as elaborating a complete program.

| Source | Canonical relationship / outcome |
|---|---|
| `f(x)` | Native application `f x`. |
| `f(x, y)` | Native application with two arguments `f x y`. |
| `f((x, y))` | Native application with one tuple `f (x, y)`. |
| `f (x, y)` | Inherited application to a tuple. |
| `f()` | Native `f ()`. |
| `f(x,)` | Native `f x`, trailing-comma feature recorded. |
| `f(,)` | Reject an empty entry. |
| `f(x,,y)` | Reject an empty entry. |
| `f(x, n := 2)` | Native `f x (n := 2)`, named feature recorded. |
| `f(n := 1, n := 2)` | Reject duplicate named argument. |
| `f(n: 2)` | Not a named argument in this grammar. |
| `g f(x)` | Native `g (f x)`. |
| `f(x)(y)` | Preserve nested native application grouping. |
| `f/- c -/(x)` | Decline D-CALL; use native parser result. |
| `const x: Nat := 1` | Native parameterless definition. |
| `const f: Nat -> Nat := fun x => x` | Native function-valued definition. |
| `function f(x: Nat): Nat := x` | Native definition with one explicit binder. |
| `function f(): Nat := 1` | Reject empty declaration parameter group. |
| `function f(x: Nat): Nat { x }` | Reject bare block body. |
| `function f(x: Nat): Box := { value := x }` | No outer terminator; the declared Box representation must separately type-check. |
| `if (p) { a } else { b }` | Native `if p then a else b`. |
| `if p { a } else { b }` | Reject this unregistered braced conditional spelling. |
| `match o with { | .some x => f(x) | .none => 0 }` | Native patterns; recursively lowered RHS. |
| `match o with { | .some(x) => x }` | Reject decorated call syntax in pattern. |
| `fun x => f(x)` | Native lambda with lowered body. |
| `(x) => x` | No TS lambda production in the base. |
| `structure S where { x: Nat }` | Native structure field sequence. |
| `namespace N { ... }` | No braced namespace in the base. |
| `do { return x; }` | Inherited do sequence, meaningful only in native effect context. |
| `return x` in arbitrary pure context | No universal JS early-return production. |

A compiler should include contextual tests where the same punctuation occurs inside strings, quotes, proofs, indices, dependent types, and other nested categories. Simple string substitutions may appear to pass this table while failing those interactions.

## 81. Evidence manifest contract

A build manifest must separate reference identities from results. A representative shape is:

```json
{
  "proofscriptSpecVersion": "0.9.0",
  "sourceEdition": "ps-0.9",
  "grammarRevision": "ps-0.9-r2",
  "semicolonPolicy": "lean-native-separators",
  "leanSemantics": {
    "version": "4.34.0",
    "commit": "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b"
  },
  "featureRegistryVersion": "0.9.0-r2",
  "compilerRevision": "<exact-revision>",
  "moduleFormatVersion": "<exact-version>",
  "implementationProfile": "<declared-capability-manifest>",
  "environmentIdentity": "<imports-options-registration-closure>",
  "axiomPolicy": "<policy-identity>",
  "sourceIdentity": "<checked-source-snapshot>",
  "kernelIdentity": "<checker-revision-and-profile>",
  "runtimeProfile": "<target-abi-and-primitive-manifest>",
  "evidence": {
    "sourceCorrespondence": "not-established",
    "logicalAdmission": "not-established",
    "contractProof": "not-requested",
    "terminationProof": "not-requested",
    "erasurePreservation": "not-established",
    "targetPreservation": "not-established"
  },
  "externalAssumptions": [],
  "artifactIdentities": []
}
```

Angle-bracket fields above are explanatory placeholders, not valid production identities. A production validator rejects missing, placeholder, unknown, or incompatible required fields.

A manifest is a report and routing object. It is not authority to create a checked module. The actual evidence must be checked through the selected protocol and bound to exact inputs. An empty external-assumption list must be established, not assumed merely because the compiler omitted one.

---

# Part X — Research basis and implementation sequence

## 82. What the study corpus established

The full `study/` tree was inventoried at the pinned repository baseline. It contains nine top-level collections, 16,279 tree entries, and 14,750 files. The text-document selection contains 1,062 paths corresponding to 930 unique Git blobs. With selected parser, scalar, example, and conformance sources, 1,135 unique blobs totaling 222,986,706 bytes were retrieved and checked against their Git blob identities.

This is complete inventory/retrieval coverage for the stated text selection—not a claim that every document received an equally deep line-by-line review. Close reading prioritized the v0.7 reference, parser/lowering contract, native declaration/term/do parsers, function application, recursion, macros, monad transformers, theorem foundations, TypeScript functions/compatibility, and the independent checker's divergence notes.

The HTPI PDF was inventoried as an additional format; its HTML companion was used for this study. Web assets/fonts/search scripts are not prose documents and were not treated as language specifications. No third-party books or mirrored website contents are redistributed by this package.

The corpus includes duplicate pages and historical releases. A tutorial, saved website mirror, or independent checker snapshot may target a different release. Exact pinned Lean source and toolchain behavior take precedence for the selected profile. [R1–R6]

## 83. Research conclusions and alternatives

### 83.1 Why a thin decoration is preferred

A new JS-like type/effect system would need a separate semantic account, elaborate interoperation rules, and additional preservation arguments. A small syntax overlay can instead preserve the mature dependent language while improving common declaration and call presentation.

The chosen surface is intentionally not a token-for-token TypeScript imitation. `fun`, native binders, `:=`, native pattern syntax, and Lean command scopes make the semantic model visible. Their learning cost should be measured, but removing them by inventing partial substitutes would not be a free simplification.

### 83.2 Why the reference keeps call adjacency

A whitespace-insensitive native call design could be reasonable in a wholly new language. It would, however, alter v0.7's protected tuple/application neighbor and require an explicit migration. This version favors compatibility and a small lowering relation. The formatter exposes the distinction consistently.

### 83.3 Why bare brace-bodied functions are excluded

A bare body would need a decision about expression blocks, statement sequencing, implicit return, mutation, and termination punctuation. Native-boundary `:= expression` and `:= do { ... }` already distinguish pure term construction from effect sequencing. The simpler base avoids importing JS expectations about every brace block. Revision 2 also removes the old ProofScript-only declaration and alternative terminators; it preserves only native category-specific semicolons.

### 83.4 Why the additions are small

Named arguments inside decorated calls reuse native named-argument semantics. Trailing commas reuse an existing nonempty list without introducing an argument. Braced instance registration closes an existing prose/registry gap. Each has a specific grammar/lowering test rather than a broad new semantic mechanism.

### 83.5 Why “familiar” is not a completed empirical result

Official TypeScript documentation identifies common programming mechanisms; it is not a population-frequency study. No participant study or AI productivity benchmark was performed here. Adoption should be measured with API data, collection pipelines, callbacks, modules, errors, full applications, and proof-repair tasks—not only preferences about punctuation.

## 84. Programming-language theory used in the design

Harper's *Practical Foundations for Programming Languages* supplies the methodological separation of abstract syntax, static judgments, dynamics, and type-safety arguments. This reference applies that discipline by separating parsing, elaboration, logical checking, and runtime preservation; it does not borrow a small example calculus as a substitute for Lean. [P1]

Krishnamurthi's *Programming Languages: Application and Interpretation* distinguishes surface syntax from a smaller core and examines desugaring and lexical binding. That motivates separate ASTs, structural recursive lowering, and explicit hygiene/evaluation obligations rather than text replacement. [P2]

*Software Foundations* illustrates preservation/progress and Hoare-style reasoning in precisely specified example languages. The corresponding PSC obligations must be proved for PSC's actual relations. Partial correctness is not termination, and source type safety is not correctness of a foreign runtime. [P3]

These are selected chapter-level studies and methodological precedents—not a claim of reading every edition of every language-design book or transferring their proofs automatically. Go's engineering history adds a practical constraint: language, tools, dependencies, and maintainability should be designed together. [G1]

## 85. Executed evidence and its limitations

The authorized Windows environment had an existing Lean v4.34.0 toolchain. Its version output identified the exact semantic commit used by this reference. No compiler installation or global toolchain change was required.

The original research executed (retained historical evidence, not rerun by this revision):

- One canonical example file with record updates, Option matching, curried/tuple/Unit calls, dependent data, named/default arguments, braced do/loops, and 14 small theorems: **accepted**.
- One native intrinsic contract example: **accepted**, with an upstream experimental warning and a generated `.spec` theorem.
- Six negative canonical cases—false proof, invalid dependent update, numeric truthiness, tuple/arity mismatch, repeated native `ensures`, and false contract: **all rejected as expected**.
- A further assumption inspection of the intrinsic theorem reported `propext`, `Classical.choice`, and `Quot.sound`; those assumptions are not hidden or described as an assumption-free proof.

These are native Lean oracle checks of hand-authored canonical examples. They do not test a production ProofScript parser, execute a v0.9 lowerer, prove the overlay sound, or establish JS/Rust/Wasm equivalence. Positive syntax examples in this document remain candidate conformance inputs unless the accompanying record explicitly says what was executed.

The original evidence description is in [STUDY_AUDIT.md](research/STUDY_AUDIT.md), with authored source files and machine-readable observed results. The r2 native-separator checks have their own [audit](research/SEMICOLON_REVISION_AUDIT.md), exact source hashes and outcomes; they do not promote these original checks into new PSC frontend evidence. Documentation validation checks links, section/registry consistency, JSON, and case IDs; it is not a semantic checker.

## 86. Formal obligations before stronger claims

The first formal targets should be explicit and compositional:

| Obligation | Intended result |
|---|---|
| Ownership determinism | An accepted owned node has one declared category/feature interpretation. |
| Protected-neighbor preservation | A nonmatching decoration does not displace the selected native parse. |
| Syntax lowering well-formedness | Owned syntax lowers to an appropriate native syntax category. |
| Binding/hygiene preservation | Lowering preserves user references and introduces no accidental capture. |
| Environment correspondence | Imports/options/registrations and declarations relate to the intended environment. |
| Source theorem correspondence | The checked proposition is the one requested by the source/specification. |
| Standalone refinement | The owned implementation agrees with the defined reference on its claimed domain. |
| Erasure preservation | Removing irrelevant content preserves retained computation. |
| Target preservation | Runtime/target programs relate under stated representation/effect/resource models. |
| Artifact binding | Checked evidence covers the exact emitted and linked bytes consumed. |

Type-theoretic faithfulness is a design constraint and a proof target; it is not established simply by writing the equation defining intended meaning. The S1 reference becomes stronger only when these obligations are discharged for a stated scope.

## 87. Practical implementation order

Start with the registry, exact grammar/source/profile identities, lexer trivia, D-CALL, aliases, explicit headers, and native declaration/sequence boundaries. Implement braced if/data/match/where forms with separate category tests. Make native braced do a supported inherited capability, not a duplicate effect language.

Then implement the named/trailing-comma conveniences and explicit instance-body rule with native-oracle comparisons. Extend native coverage by coherent families: patterns/data, inference/typeclasses, recursion, modules, prover support, and explicitly selected intrinsic verification. Preserve failure and transactional boundaries throughout.

Keep one useful executable route stable while the language reference matures. UI and optional backend work should not destabilize the current compiler/kernel bootstrap. Full applications require libraries, interoperation, and tooling in addition to parser support.

For certification, prove a small complete path first: a useful source function and specification, correct lowering/erasure, a target implementation, and exact-file binding. Expand compositional coverage rather than claiming a universal compiler theorem from a fixed point or a large number of passing examples.

## 88. Reference register

All repository references below use base commit `65369c75c7b63124f1ba7f2289e573181db281f0` unless another exact commit is stated. External live pages are explanatory sources, not version pins. The source hashes and research classification belong in the audit/manifests.

### Repository and source lineage

- **[R1] ProofScript v0.7.0.** [Authoritative draft](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/proofscript-language-reference-v0.7.0/ProofScript_Language_Reference_v0.7.0_authoritative_draft.md), [feature registry](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/proofscript-language-reference-v0.7.0/appendices/A-complete-feature-registry.md), and conformance corpus. Main-reference blob `8b4097363c5ade7d594b66706b94dff62400ff53`.
- **[R2] ProofScript v0.6.1.** [Historical reference package](https://github.com/dwijayuda/pskernel/tree/65369c75c7b63124f1ba7f2289e573181db281f0/study/proofscript-language-reference-v0.6.1). Earlier semantic pin and compiler-facing contracts; not the v0.9 semantic authority.
- **[R3] Lean reference mirror.** [Repository collection](https://github.com/dwijayuda/pskernel/tree/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference). Full text inventory includes reference chapters, APIs, diagnostics, and historical release pages.
- **[R4] Lean4Lean.** [Divergence notes](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4lean-master/divergences.md). Useful independent-checker research, not automatic exact acceptance equivalence.
- **[R5] TypeScript mirror.** [Repository collection](https://github.com/dwijayuda/pskernel/tree/65369c75c7b63124f1ba7f2289e573181db281f0/study/www.typescriptlang.org). Workflow/API/type-system study; not a new PSC type theory.
- **[R6] Study tree.** [Pinned collection](https://github.com/dwijayuda/pskernel/tree/65369c75c7b63124f1ba7f2289e573181db281f0/study). Tree identity `d7cb9ece9bda552b960ba488fca0895c6ee92278`.

### Pinned Lean implementation and native semantics

- **[L1] Native term parser.** [Term.lean](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-4.34.0/src/Lean/Parser/Term.lean). Application, named arguments, records, functions, matches, and suffix categories.
- **[L2] Native do parser.** [Do.lean](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-4.34.0/src/Lean/Parser/Do.lean). Blob `611c62724a004dc4a635549275cc7ab23f40931c`; braced and layout do sequences.
- **[L3] Native declarations/contracts.** [Command.lean](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-4.34.0/src/Lean/Parser/Command.lean), blob `0b4083ac78f7a04ae6f6f29cb02c529ff76ed9e8`, and [intrinsic verification tests](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-4.34.0/tests/elab/intrinsicVerification.lean).
- **[L4] Function application.** [Mirrored native account](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Terms/Function-Application/index.html). Whole-application elaboration, implicit/default/named parameters, generalized field notation.
- **[L5] Recursion.** [Mirrored recursive-definition account](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Definitions/Recursive-Definitions/index.html). Total, partial, unsafe, and logical/runtime distinctions.
- **[L6] Scalar sources.** [Pinned Init/Data](https://github.com/dwijayuda/pskernel/tree/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-4.34.0/src/Init/Data). Exact selected primitive declarations and operation definitions.
- **[L7] Macro hygiene.** [Mirrored macro account](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Notations-and-Macros/Macros/index.html). Categories, scopes, pre-resolved names, and capture.

### Programming and theorem-development books in the study folder

- **[B1] How To Prove It with Lean.** [HTML collection](https://github.com/dwijayuda/pskernel/tree/65369c75c7b63124f1ba7f2289e573181db281f0/study/HTPIwL). Proof pedagogy and feedback. Its imported teaching tactics must not be misreported as default Lean syntax.
- **[B2] Functional Programming in Lean.** [Collection](https://github.com/dwijayuda/pskernel/tree/65369c75c7b63124f1ba7f2289e573181db281f0/study/functional_programming_in_lean), especially `Monad-Transformers/Ordering-Monad-Transformers/index.html`. Effects, data, dependent programming, and runtime considerations.
- **[B3] Theorem Proving in Lean 4.** [Collection](https://github.com/dwijayuda/pskernel/tree/65369c75c7b63124f1ba7f2289e573181db281f0/study/theorem_proving_in_lean4), especially `Axioms-and-Computation/index.html`. Logical foundations, proof development, classical assumptions, and executable meaning.

### TypeScript language design and use

- **[T1] Functions and inference.** [Official functions documentation](https://www.typescriptlang.org/docs/handbook/2/functions.html); also the pinned mirror. Contextual callbacks, generics, optional/rest parameters, and overloads.
- **[T2] Type compatibility.** [Official compatibility documentation](https://www.typescriptlang.org/docs/handbook/type-compatibility.html). Structural typing and deliberate soundness tradeoffs.
- **[T3] Narrowing and data.** [Narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html) and [object types](https://www.typescriptlang.org/docs/handbook/2/objects.html). Motivation for inspectable refinement and practical data APIs.
- **[T4] Generic/type-level APIs.** [Generics](https://www.typescriptlang.org/docs/handbook/2/generics.html) and the mirror's mapped/conditional/template-type chapters. Interoperability requirements, not a proposal to duplicate TypeScript's type checker in the kernel.

### Language theory and compiler methodology

- **[P1] Robert Harper, Practical Foundations for Programming Languages, second edition.** [Author page](https://www.cs.cmu.edu/~rwh/pfpl/) and [abbreviated online edition](https://www.cs.cmu.edu/~rwh/pfpl/abbrev.pdf). Selected syntax, static/dynamic semantics, and type-safety material; not a full-book audit.
- **[P2] Shriram Krishnamurthi, Programming Languages: Application and Interpretation.** [Desugaring](https://cs.brown.edu/courses/cs173/2012/book/first-desugar.html), [desugaring as a language feature](https://cs.brown.edu/courses/cs173/2012/book/Desugaring_as_a_Language_Feature.html), and [substitution/environments](https://cs.brown.edu/courses/cs173/2012/book/From_Substitution_to_Environments.html). Selected chapters from the 2012 online edition.
- **[P3] Software Foundations, Programming Language Foundations.** [Types](https://softwarefoundations.cis.upenn.edu/plf-current/Types.html) and [Hoare logic](https://softwarefoundations.cis.upenn.edu/plf-current/Hoare.html). Precise example-language proof obligations and partial-correctness reasoning.
- **[P4] CompCert.** [Compiler overview and correctness](https://compcert.org/man/manual001.html). Scope of behavioral preservation and external boundaries.
- **[G1] Rob Pike, Go at Google: Language Design in the Service of Software Engineering.** [Original design account](https://go.dev/talks/2012/splash.article). Build/tooling/dependency and maintenance discipline.

## 89. Final design commitment

ProofScript v0.9 should be understandable as **Lean with a carefully specified, modest TypeScript-friendly surface**, supported by excellent libraries, tools, and explicit assurance. It should not grow a competing logical type system merely to resemble familiar punctuation.

The practical promise is precise: accepted decorations have declared categories and canonical Lean meanings; unsupported features fail explicitly; proofs are independently checked; executable guarantees identify their compiler/runtime assumptions. Stronger claims require stronger evidence.

This reference is a substantial compiler contract and a proposed design baseline. It is not a substitute for implementing the parser, proving its lowering, measuring adoption, or establishing complete compiler preservation.

