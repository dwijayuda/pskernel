# ProofScript PSC3 Language Reference — Draft

Status: **research-derived normative draft**

This document proposes the PSC3 native language profile. It is not an implementation claim and is not frozen.

Where this document conflicts with PSC2, PSC3 is a proposed new edition rather than a silent mutation of PSC2.

## 1. Scope

PSC3 is designed to support:
- complete application development;
- reusable libraries;
- theorem proving;
- program verification;
- compiler/tool development;
- JavaScript ecosystem integration;
- direct JavaScript and WebAssembly deployment;
- specification-enforced human and AI development.

PSC3 keeps a small dependent logical foundation while making the native source language more regular and application-oriented than PSC2.

## 2. Source kinds

### 2.1 .ps

.ps is the canonical native PSC3 source form.

It is designed around:
- familiar calls;
- braces for owned blocks;
- explicit imports/exports;
- nominal algebraic data;
- pattern matching;
- typed errors;
- effects/capabilities;
- optional proof/specification syntax.

### 2.2 .lean

.lean is a strict subset/profile of pinned official Lean.

ProofScript syntax never extends .lean.

### 2.3 .psx

.psx enables component/markup syntax that desugars into ordinary typed .ps constructs.

See PSX_UI_PROFILE.md.

## 3. Lexical rules

### DECISION — formatting is not semantic call ownership

Native PSC3 does not preserve PSC2's distinction:

~~~text
f(x)
f (x)
~~~

Both are parsed as the same call in contexts where f is callable.

The canonical formatter emits:

~~~proofscript
f(x)
~~~

### DECISION — semicolons are formatter-controlled

The grammar should not require semicolons at every ordinary declaration/expression boundary when structural parsing is unambiguous.

The canonical formatter determines one style.

Exact automatic-semicolon rules remain an **OPEN GRAMMAR QUESTION**; PSC3 should avoid JavaScript-style context-sensitive ASI.

### Comments

Support:
- line comments;
- nested/documentable block comments where the lexer can do so predictably;
- documentation comments with structured tooling extraction.

## 4. Modules

### DECISION — explicit native imports and exports

Draft syntax:

~~~proofscript
import { User, decodeUser } from "./user"
import * as Http from "@proofscript/http"

export structure Config {
  port: UInt16
}

export function start(config: Config): App Unit {
  ...
}
~~~

Rules:
- import paths resolve through the PSC package/module graph;
- ambiguous resolution is an error;
- imports do not silently add global instances/notation beyond documented scope rules;
- package public APIs are explicit;
- emitted JS uses ESM.

Lean source retains Lean import/module syntax.

## 5. Declarations

### Canonical native declaration family

PSC3 proposes:

~~~text
function
const
structure
inductive
enum
class
instance
theorem
axiom
opaque
abbrev
namespace
~~~

### function

~~~proofscript
export function add(x: Nat, y: Nat): Nat {
  x + y
}
~~~

A function has ordinary curried/dependent semantic application after elaboration even when the source groups arguments.

### const

~~~proofscript
const defaultPort: UInt16 = 8080
~~~

const is a value declaration, not JavaScript object-freezing semantics.

### def

For migration and Lean-oriented coding, .ps MAY retain def as a supported alias/profile feature.

**CANDIDATE:** make function/const the canonical formatter output for ordinary native application code while retaining def for theorem-oriented or migration source.

This needs usability testing before freeze.

## 6. Values and bindings

Immutable bindings are the default.

~~~proofscript
let user = decodeUser(data)
~~~

Local mutable-looking variables are allowed only in owned imperative/effect contexts:

~~~proofscript
do {
  let mut total = 0
  for x in values {
    total = total + x
  }
  return total
}
~~~

Mutation of a local variable has language-defined lexical semantics. It is not JavaScript shared-object mutation.

Heap/reference mutation, if standardized, requires an explicit reference/effect abstraction.

## 7. Foundational scalar types

PSC3 inherits exact semantic separation:

~~~text
Nat
Int

UInt8 UInt16 UInt32 UInt64 USize
Int8 Int16 Int32 Int64 ISize

Float32 Float
Bool
Char
String
Unit
~~~

### Nat / Int

Exact mathematical integers.

Backend implementations may use arbitrary precision or proved range specialization.

### Fixed-width integers

Overflow, shifts, conversion, division and remainder semantics are defined by PSC3, never by JS/Wasm defaults.

### USize / ISize

Target-profile width is explicit in the build profile.

Portable code whose behavior depends on target width must expose that dependency.

### Float

Floating-point operations require a frozen IEEE-oriented semantic profile.

Proofs do not silently treat Float as Real.

### OPEN FREEZE OBLIGATION

PSC3 must publish a complete scalar operation/conversion table before language freeze.

## 8. Data

### Structures

~~~proofscript
structure User {
  id: UserId
  name: String
  email: Option String
}
~~~

Structures are nominal.

### Inductives

~~~proofscript
inductive Result(A: Type, E: Type) {
  | ok(value: A)
  | error(error: E)
}
~~~

### DECISION — Result parameter order

PSC3 standardizes:

~~~text
Result(A, E)
~~~

success type first, error type second.

Documentation and generated bindings must use this consistently.

### enum

Payload-free convenience:

~~~proofscript
enum Direction {
  north
  east
  south
  west
}
~~~

This lowers to an ordinary finite inductive type.

### Tuples

Tuples are product values, not a second object model.

## 9. Optional values

Portable PSC3 uses:

~~~text
Option A
~~~

There is no implicit null/undefined.

### CANDIDATE optional field sugar

~~~proofscript
structure User {
  nickname?: String
}
~~~

means:

~~~proofscript
structure User {
  nickname: Option String
}
~~~

### CANDIDATE optional chaining/nullish sugar

~~~proofscript
user.nickname?.trim()
user.nickname ?? user.name
~~~

These must have precise Option lowering and evaluation-order rules before adoption.

## 10. Function calls and arguments

~~~proofscript
connect(host, timeout: 5000, retries: 3)
~~~

### Positional arguments

Ordinary calls are comma-separated.

### Named arguments

A named argument refers to a stable declaration parameter name.

Unknown/duplicate names fail.

### Defaults

~~~proofscript
function connect(host: String, timeout: Duration = seconds(5)): Connection {
  ...
}
~~~

Defaults elaborate at the source level.

Their dependency and runtime evaluation behavior must be explicit.

## 11. Method notation

~~~proofscript
users.map(render)
text.trim()
~~~

Method notation is static elaboration.

Resolution order should be:
1. structure field/projection when syntactically a projection;
2. methods/functions explicitly associated with the receiver's nominal type/module;
3. imported extension methods permitted by explicit scope;
4. require a unique viable result.

No prototype lookup occurs.

### Explainability

~~~text
psc explain users.map
~~~

must report the selected declaration and inserted arguments.

## 12. Patterns and narrowing

One pattern system supports:
- variables;
- wildcard;
- constructor patterns;
- tuple patterns;
- nested patterns;
- literal patterns where defined;
- alternatives with compatible bindings;
- let-patterns;
- match;
- if-let;
- function clauses.

~~~proofscript
match state {
  | .ready(user) => render(user)
  | .failed(err) => renderError(err)
  | .idle | .loading => renderSpinner()
}
~~~

Exhaustiveness is required for expression matches unless the type/effect explicitly admits failure.

Pattern matching provides type refinement.

## 13. Conditionals and proof-aware refinement

Ordinary conditions use Bool.

Verified contexts may expose evidence associated with a decision procedure or proposition.

PSC3 must keep:
- Bool values;
- propositions;
- decidability/evidence;

distinct.

The compiler may bridge them through explicit standard interfaces.

## 14. Structure update

~~~proofscript
const next = {
  user with
  name = newName
}
~~~

Updates are immutable construction.

### Dependent-field rule — OPEN DESIGN

When a changed field appears in the type of another field, PSC3 must not blindly retain the old dependent field.

Candidate rule:
- unchanged independent fields may be retained;
- dependent fields whose type changes must be explicitly replaced or reconstructed through a typed update helper;
- tooling diagnoses the dependency.

This requires formal modeling before freeze.

## 15. Classes and instances

Classes are logical/type-directed interfaces, not OO classes.

~~~proofscript
class Show(A: Type) {
  show: A -> String
}
~~~

Native instance search must be:
- scoped;
- deterministic;
- bounded;
- cycle checked;
- explainable.

Priorities may exist, but ambiguous public behavior should not depend on arbitrary import/declaration order.

## 16. Coercions

Coercions are ordinary functions inserted by the elaborator.

Native PSC3 permits only bounded, deterministic chains.

Tooling exposes the inserted chain.

Dynamic JavaScript coercion is not part of PSC3.

## 17. Recursion and termination

### Total functions

Structural/well-founded definitions may participate in logical computation when admitted.

### Well-founded recursion

A termination/decreasing clause generates ordinary proof obligations.

### Partial runtime functions

PSC3 must support real application programs that may diverge.

Draft spelling:

~~~proofscript
partial function serveForever(...): App Never {
  ...
}
~~~

A partial function:
- is executable;
- is not unfolded as total logical computation;
- cannot manufacture proof evidence;
- may still have partial-correctness/safety specifications under a program logic.

The exact proof model for partial/effectful programs is an **OPEN SEMANTIC DESIGN**.

## 18. Errors

Recoverable errors use Result/Except semantics.

PSC3 should provide concise propagation syntax.

**CANDIDATE**:

~~~proofscript
const config = try loadConfig(path)
~~~

or a postfix operator.

Final syntax should be selected through usability testing rather than copying Rust/Swift/JS mechanically.

Host exceptions are caught/translated only by explicit foreign adapters.

## 19. Effects and capabilities

Portable effects are explicit.

Standard capability families are expected for:
- filesystem;
- network;
- clock;
- randomness;
- process;
- environment;
- console;
- storage;
- browser/DOM.

PSC3 should initially prefer concrete, composable library effects/capabilities over adding a fully general algebraic-effect syntax to the language.

General effect handlers remain a research topic.

## 20. Resources

Deterministic resource cleanup is required for full applications.

**CANDIDATE semantic model**:

~~~proofscript
using file <- File.open(path) {
  ...
}
~~~

The construct must specify cleanup under:
- normal completion;
- typed error;
- early return;
- cancellation;
- panic/abort where recoverable.

Resource lifetime must not depend on garbage collection finalizers.

## 21. Task / async

~~~proofscript
async function fetchUser(id: UserId): Task (Result UserError User) {
  ...
}

const result = await fetchUser(id)
~~~

Task is a PSC semantic abstraction.

PSC3 should prefer structured concurrency:
- child tasks are scoped by default;
- cancellation propagation is defined;
- detached tasks require explicit capability/construct;
- timeout/race semantics are specified;
- cleanup interaction is specified.

This remains **OPEN FREEZE WORK**.

## 22. Theorem declarations

~~~proofscript
theorem addZero(n: Nat): n + 0 = n := by {
  simp
}
~~~

Proof syntax constructs ordinary evidence checked by the kernel.

Theorem bodies erase unless explicitly reified as data.

## 23. Contracts

~~~proofscript
function withdraw(balance: Nat, amount: Nat): Nat
  requires amount <= balance
  ensures result => result = balance - amount
{
  balance - amount
}
~~~

Contracts denote propositions/specifications.

They are not runtime assertions by default.

Standard forms:
- requires;
- ensures;
- assert;
- invariant;
- decreasing.

VC generation is untrusted proof construction.

## 24. Runtime checks

PSC3 provides explicit runtime validation/checking APIs.

A runtime check can be derived from a decidable contract where appropriate.

Its result is not automatically proof evidence.

## 25. Ghost/specification data

Proof/spec-only values may exist during checking.

They erase only when runtime irrelevance is established.

Observable computation cannot depend on erased ghost values.

## 26. Classical and noncomputable code

The theorem profile supports classical assumptions and noncomputable definitions.

Reachable noncomputable definitions cannot silently become executable JS/Wasm.

An executable realization must be separately supplied and connected by explicit evidence/assumption.

## 27. FFI

Foreign interfaces are explicit.

Every foreign binding has:
- target/platform;
- runtime type mapping;
- effect classification;
- failure behavior;
- trust/model status;
- optional specification theorem/model.

A typed binding is not automatically verified.

## 28. Extensions

Preferred order:

~~~text
library
-> source sugar
-> elaborator/Meta
-> typed registry
-> controlled plugin
-> semantic extension
-> kernel change only when unavoidable
~~~

Native .ps does not initially expose arbitrary grammar mutation.

## 29. Portability profiles

Suggested profiles:

~~~text
psc3-portable
psc3-js
psc3-browser
psc3-node
psc3-wasm
psc3-wasi
psc3-lean4341
~~~

A package declares required profiles/capabilities.

"Portable" means semantic portability, not identical performance or representation.

## 30. Claim vocabulary

Tools must distinguish:

~~~text
parsed
elaborated
type checked
kernel admitted
contract verified
termination proved
portable-profile checked
compiled
backend differential tested
translation validated
compiler-preservation proved
external assumptions present
~~~

No stronger claim is implied by a weaker one.

## 31. Deferred syntax decisions

Before syntax freeze, PSC3 must resolve:
- canonical function body grammar;
- semicolon policy;
- error propagation spelling;
- resource syntax;
- optional chaining semantics;
- dependent structure updates;
- async structured-concurrency rules;
- pattern destructuring in parameters;
- controlled notation/plugin grammar.

These are intentionally not hidden behind premature normative wording.
