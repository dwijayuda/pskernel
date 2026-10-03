# The ProofScript Language Reference v0.9.0 r3

Status: accepted r3 language/design baseline; documentation/specification scope; not an implementation release or proof of soundness.

This file is the main human and AI/compiler-design reference for ProofScript v0.9.0 r3.

An implementation agent SHOULD begin here. Companion files may provide machine-readable schemas, historical detail, research rationale, or release evidence, but this document states the language/compiler contract that those artifacts refine.

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

Authority order for ps-0.9-r3:

1. this document;
2. the accepted r3 machine-readable registries and schemas for the data domains they define;
3. R3-AUTHORITY-AND-DELTA.md and R3-R2-INHERITANCE-MATRIX.md;
4. accepted r3 topic documents;
5. the exact r2 baseline identified above for every rule not overridden by r3;
6. pinned Lean 4.34 source/environment for inherited Lean syntax and semantics;
7. examples, tutorials, research notes, and external precedents.

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

1. consult this document;
2. consult exact r2 inherited rule if not overridden;
3. consult pinned Lean 4.34 authority for inherited semantics;
4. if still unsupported, reject/raise a specification issue.

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
