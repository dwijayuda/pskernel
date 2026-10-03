# r3 Zero-Argument Function Sugar

Status: **accepted r3 design; surface sugar only; not implemented**

## Decision

Permit:

~~~proofscript
function now(): Time :=
  ...
~~~

as explicit source sugar for a Unit-taking function:

~~~lean
def now (_ : Unit) : Time :=
  ...
~~~

and keep:

~~~proofscript
now()
~~~

as one Unit application:

~~~lean
now ()
~~~

The core function model remains Lean's unary/curried model. r3 does not introduce a zero-arity core function.

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
## Partial application and inference

A Unit function is still an ordinary function.

The expression:

~~~proofscript
now
~~~

denotes the function value when the context permits it.

The expression:

~~~proofscript
now()
~~~

applies Unit.

The compiler must not automatically call every Unit function when referenced as a value.

Implicit arguments are still inserted by native elaboration:

~~~proofscript
function defaultValue {α: Type}[Default α](): α :=
  default
~~~

The explicit Unit application does not replace typeclass synthesis.

## Methods

A Unit-taking generalized-field function can be called with an empty argument list after receiver resolution if the canonical native function type expects Unit at the next explicit position.

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

- native oracle for equivalent Unit-taking functions;
- parsing tests with implicit/instance binders;
- method/partial-application tests;
- JS ABI and <code>.d.ts</code> conformance;
- usability study.

Current status: **accepted r3 design rule; no production parser implementation claimed**.