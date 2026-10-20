# r3 Formal Overlay Proof Plan

Status: **accepted r3 formal-proof plan; no formal proof is claimed by this documentation branch**

## Purpose

The first formal target should be deliberately small: one owned surface construct whose syntax, lowering, and interpretation can be modeled precisely before attempting a theorem about the full ProofScript frontend.

The recommended first construct is the r3 parenthesized call.

## Proposed model

Define a small source AST containing:

~~~text
Term
ParenthesizedCall
CallArgument
~~~

with enough canonical target structure to represent:

~~~text
f()
f(x)
f(x, y)
f((x, y))
~~~

The model should preserve the intended distinctions:

~~~text
EmptyCall(h)     -> native high-level application h .. + r3 omitted-required-argument acceptance predicate
Call(h, [a])     -> native application h a
Call(h, [a,b])   -> native application (native application h a) b
Tuple argument   -> one ordinary product-valued call argument
ZeroArgDecl(f)   -> native def f (_ : Unit := ())
~~~

This is a model of the intended lowering, not the production parser.

## First theorem targets

The first proof package should establish, for the selected formal model:

1. ownership determinism for the modeled call grammar;
2. lowering well-formedness;
3. correctness of empty-call canonicalization to native ellipsis application;
4. soundness of rejecting omitted ordinary required explicit parameters;
5. correctness of zero-source-argument declaration lowering to native optional Unit;
6. preservation of argument order/grouping;
7. a small interpretation-preservation theorem for a minimal callable language.

## Important exclusions

The first theorem should **not** claim to cover:

- the actual Lean lexer/parser;
- whitespace/comment/newline ownership in the production frontend;
- the full production native named/default/implicit argument elaborator beyond the modeled relation;
- generalized field notation;
- contextual constructors;
- macros or quotations;
- source maps;
- binding hygiene beyond the modeled fragment;
- production r3 parser refinement;
- exact equivalence to official Lean elaboration.

These require separate formal relations.

## Production connection that will eventually be needed

A useful proof chain is:

~~~text
actual .ps bytes
  -> production tokens
  -> production r3 AST
  -> formal overlay AST
  -> modeled canonical Lean AST
  -> production canonical Lean AST
~~~

Each arrow needs a stated relation. A theorem about an isolated model does not automatically establish the corresponding production implementation.

## Recommended next research

Before implementing the proof:

- finish the exact r3 D-CALL grammar;
- encode the already-accepted no-bare-newline CallGap rule;
- encode the accepted callable-head category and field-dot adjacency rule;
- document every protected/imported syntax interaction;
- define the production AST shape;
- define the formal AST independently enough to audit it.

## Evidence status

Formal proof: **not claimed in the final documentation-only branch state**.
Production refinement: **not established**.
Frontend equivalence: **not established**.
Human usability: **not measured**.
