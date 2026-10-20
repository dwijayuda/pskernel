# r3 Zero-Argument Function Sugar

Status: **accepted r3 design; surface sugar only; not implemented**

## Decision

Permit:

~~~proofscript
function now(): Time :=
  ...
~~~

as explicit source sugar for a function with one **optional Unit binder whose default is Unit**:

~~~lean
def now (_ : Unit := ()) : Time :=
  ...
~~~

The declaration sugar is independent from the more general r3 empty-call rule.

~~~proofscript
now()
~~~

is an empty source-level invocation. It lowers to the r3 empty-call application request; native optional-parameter insertion supplies the hidden default Unit.

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
- the empty group denotes one synthesized explicit `Unit` binder encoded as native `optParam Unit ()`;
- an empty group cannot be mixed with another explicit group.

Rejected:

~~~proofscript
function f()(x: Nat): Nat := x
function f(x: Nat)(): Nat := x
~~~

Allowed native non-explicit binders may precede the final empty explicit group:

~~~proofscript
function factory {α: Type}(): Box α :=
  ...
~~~

lowers conceptually to:

~~~lean
def factory {α : Type} (_ : Unit := ()) : Box α :=
  ...
~~~

No source name is introduced for the Unit binder unless diagnostics need a synthetic provenance identifier.
## Empty invocation, defaults, and partial application

The accepted r3 rule distinguishes declaration sugar, empty invocation, and explicit Unit application.

~~~proofscript
function answer(): Nat := 42
answer()     -- zero source arguments; hidden optional Unit defaults to ()
answer       -- the function value
answer(())   -- ordinary explicit Unit application
~~~

Optional/default parameters use the same empty-call mechanism:

~~~proofscript
function greeting(name: String := "world"): String :=
  name

const x: String := greeting()
~~~

Canonical empty-call lowering uses native high-level application ellipsis and then requires that no ordinary required explicit parameter was omitted.

A required non-default parameter therefore rejects:

~~~proofscript
function addOne(x: Nat): Nat := x + 1
addOne()     -- PS_EMPTY_CALL_REQUIRED_ARGUMENT
~~~

To obtain a partial function, use the function value or an ordinary nonempty/native application form.

The hidden Unit binder is encoded with native `optParam`. If an explicit type ascription erases that optional-parameter metadata, the empty-call convenience can also be erased; ordinary explicit `()` application remains available.

Implicit/instance parameters and optional/automatic parameters retain the pinned native insertion semantics.

## Methods

A generalized-field function can use an empty call after receiver resolution when the resulting high-level application can complete all omitted explicit parameters through native optional/automatic insertion under the r3 acceptance rule.

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
- <code>PS_EMPTY_CALL_REQUIRED_ARGUMENT</code> is an elaboration-facing explanation when <code>f()</code> lowers to Unit application but the resulting head cannot accept Unit.

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