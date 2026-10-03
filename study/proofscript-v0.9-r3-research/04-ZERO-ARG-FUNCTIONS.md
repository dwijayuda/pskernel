# r3 Zero-Argument Function Sugar

Status: **accepted r3 design; surface sugar only; not implemented**

## Decision

Permit:

~~~proofscript
function now(): Time :=
  ...
~~~

as explicit source sugar for a function with one Unit binder:

~~~lean
def now (_ : Unit) : Time :=
  ...
~~~

The declaration sugar is independent from the more general r3 empty-call rule.

~~~proofscript
now()
~~~

is an empty source-level invocation. For this Unit-taking function, the empty-call elaborator synthesizes the required `()`.

This preserves Lean's unary/curried core model; r3 does not introduce a zero-arity core function.

## Why

The r2 rule rejects <code>function f()</code> while simultaneously defines <code>f()</code> as Unit application. For TypeScript developers this creates needless asymmetry.

Unit sugar removes ceremony without creating a new semantic mechanism.

The rule is intentionally limited to the <code>function</code> declaration alias. Native <code>def</code> keeps native binders and never receives an implicit Unit parameter.
## Grammar

Add:

~~~ebnf
FunctionExplicitGroup ::=
    "(" ExplicitEntry ("," ExplicitEntry)* ","? ")"
  | "(" ")"
~~~

Semantic predicate:
- exactly one empty explicit group is allowed in a <code>function</code> declaration;
- the empty group denotes one synthesized explicit Unit binder;
- an empty group cannot be mixed with another explicit group.

Rejected:

~~~proofscript
function f()(x: Nat): Nat := x
function f(x: Nat)(): Nat := x
~~~

Allowed implicit/instance binders may surround the Unit binder according to the declared grammar profile:

~~~proofscript
function factory {α: Type}(): Box α :=
  ...
~~~

lowers conceptually to:

~~~lean
def factory {α : Type} (_ : Unit) : Box α :=
  ...
~~~

No source name is introduced for the Unit binder unless diagnostics need a synthetic provenance identifier.
## Empty invocation, defaults, and partial application

The accepted r3 rule deliberately distinguishes declaration sugar, empty invocation, and explicit Unit application.

~~~proofscript
function answer(): Nat := 42
answer()     -- complete empty invocation; supplies Unit
answer       -- the function value
answer(())   -- ordinary explicit Unit application
~~~

Optional/default parameters also participate in empty invocation:

~~~proofscript
function greeting(name: String := "world"): String :=
  name

const x: String := greeting()
~~~

Here `greeting()` inserts the native default rather than passing Unit.

A required non-Unit parameter is not silently abstracted:

~~~proofscript
function addOne(x: Nat): Nat := x + 1
addOne()     -- PS_EMPTY_CALL_REQUIRES_ARGUMENT
~~~

To obtain a partial function, use the function value or a nonempty application whose native semantics leaves parameters unapplied.

For a function with a Unit parameter followed by a required parameter:

~~~proofscript
function staged(_: Unit, x: Nat): Nat := x
staged()     -- reject: x remains required
staged(())   -- explicit Unit application; may yield a partial function
~~~

Implicit/instance parameters and optional/automatic parameters retain native-compatible insertion.

## Methods

A Unit-taking generalized-field function can be called with an empty argument list after receiver resolution when the empty-call algorithm can satisfy every required explicit parameter according to its Unit/default rules.

The frontend constructs native field/application syntax; it does not hard-code receiver position.

## FFI and ABI

At the ProofScript semantic level, the Unit parameter exists.

A JS ABI MAY erase the represented Unit argument and emit a zero-parameter JavaScript function when the backend has a proved/validated calling-convention rule for that exported interface.

Generated TypeScript should normally expose:

~~~typescript
declare function now(): Time;
~~~

rather than an artificial Unit runtime parameter.

This is a backend representation decision, not a source semantic change.
## Canonical examples

~~~proofscript
function answer(): Nat := 42
const answerValue: Nat := answer()

function makeAdder(x: Nat): Nat -> Nat :=
  fun y => x + y

const addTwo: Nat -> Nat := makeAdder(2)
~~~

Only <code>answer()</code> uses the Unit sugar. Ordinary currying remains unchanged.

## Diagnostics

- <code>PS_FUNCTION_MULTIPLE_EMPTY_GROUPS</code>;
- <code>PS_FUNCTION_EMPTY_GROUP_MIXED</code>;
- <code>PS_UNIT_CALL_NONFUNCTION</code> is an elaboration-facing explanation when <code>f()</code> lowers to Unit application but the resulting head cannot accept Unit.

## Migration

r2 source contains no accepted empty <code>function</code> group, so this is source-compatible for previously accepted r2 syntax.

A rejected r2 <code>function f()</code> may become valid under r3 only when the r3 edition/profile is explicitly selected.

## Evidence required

- parser/elaborator conformance for Unit-only, default-only, mixed Unit/default, and required-non-Unit cases;
- interactions with implicit/instance/strict-implicit binders;
- method/receiver cases;
- JS ABI and generated `.d.ts` mapping;
- usability study.

Current status: **accepted r3 design rule; no production parser implementation claimed**.