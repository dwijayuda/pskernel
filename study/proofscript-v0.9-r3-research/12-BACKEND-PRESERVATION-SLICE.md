# r3 First Backend Preservation Slice

Status: first small semantic-preservation theorem completed; no claim about the production JS backend.

## Model

The companion proofs/Backend.lean defines a tiny RuntimeIR-like language:

~~~text
Nat literal
addition
one local binding
bound variable zero
~~~

and a tiny JS-core-like AST with corresponding constructs.

The lowerer recursively maps RuntimeIR expressions to JS-core expressions.

## Theorem

Lean 4.34.0 accepted:

~~~text
lower_preserves_eval:
  jeval (lower e) env = reval e env
~~~

for every expression in the modeled fragment and optional local environment.

It also accepted:

~~~text
emitted_ast_preserves
~~~

for the emitted AST and:

~~~text
emitted_bytes_bound
~~~

which binds the emitted String field to the model serializer output.

The exact file hash and observed axiom output are recorded in proofs/EVIDENCE.json.

## What this establishes

For this toy language only:

- syntax-directed lowering is total;
- target-model evaluation agrees with source-model evaluation;
- the emitted artifact object records bytes equal to its serializer output.

This is a real checked theorem over the model.

## What it does not establish

The serializer emits JS-looking text, but no theorem currently connects that text to the ECMAScript specification or a real JS parser/engine.

Therefore this does not prove:

- correctness of the current ProofScript RuntimeIR;
- correctness of the production direct-JS backend;
- correctness of actual JS parsing/evaluation;
- BigInt representation of all Nat operations;
- closures, recursion, constructors, strings, effects, errors, async, resources, or modules;
- source-to-RuntimeIR preservation;
- printer correctness beyond equality to the modeled serializer;
- exact executable bytes after bundling/minification.

Calling this an end-to-end JavaScript compiler proof would be false.

## Next preservation slice

Recommended next theorem chain:

~~~text
real restricted RuntimeIR
  -> defined JsIR
  -> canonical JS serializer
  -> independently parsed restricted JS
  -> small-step or big-step JS-subset semantics
~~~

Then prove value/termination preservation for:

- Bool;
- exact Nat addition/multiplication;
- local bindings;
- constructors/matches;
- pure functions.

Only after that add representation lemmas for more arithmetic and data.

## Evidence classification

Formal model theorem: completed.
Translation validation: not implemented.
Production backend theorem: not established.
Real JS-engine equivalence: not established.
