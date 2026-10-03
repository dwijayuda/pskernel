# r3 First Formal Overlay Proof

Status: first small theorem completed; intentionally narrow.

## What is proved

The companion file proofs/Overlay.lean defines:

- a tiny source term model;
- a ParenthesizedCall AST;
- positional call arguments;
- lowering into curried application;
- a tiny evaluator with Nat and curried addition;
- concrete theorems for empty, one-argument, and two-argument lowering;
- a theorem that the modeled two-argument add call evaluates to the expected sum.

Lean 4.34.0 accepted the file.

Observed toolchain:

~~~text
Lean 4.34.0
293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
~~~

The recorded final file hash is in proofs/EVIDENCE.json.

## Why this slice

Parenthesized-call lowering is the highest-risk proposed r3 syntax change. The first theorem therefore establishes a formal model of the semantic idea before trying to prove the whole parser.

The modeled lowering satisfies:

~~~text
Call(h, [])      -> App h Unit
Call(h, [a])     -> App h a
Call(h, [a,b])   -> App (App h a) b
~~~

The evaluator models enough curried application to prove a two-argument addition example.

## What is not proved

This does not prove:

- trivia-insensitive lexical ownership;
- interaction with actual Lean parser categories;
- named/default/implicit arguments;
- generalized field notation;
- constructor resolution;
- macro/quotation behavior;
- binding hygiene;
- production source maps;
- the production r3 parser;
- equivalence to official Lean elaboration.

Those remain separate obligations.

## Next formal targets

1. formalize a tokenizer/category ownership relation;
2. prove deterministic ownership for the reserved callable-head + parenthesis region;
3. formalize migration of the r2 tuple neighbor;
4. relate the model AST to the actual production lowering AST;
5. add named arguments while preserving one native application argument sequence.

## Evidence classification

Formal theorem: completed for the toy model.
Production refinement: not established.
Frontend equivalence: not established.
Human usability: not measured.
