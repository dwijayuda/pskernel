# r3 Backend Preservation Slice Plan

Status: **accepted r3 backend-proof plan; no backend preservation theorem is claimed by this documentation branch**

## Purpose

Do not attempt a universal compiler-correctness theorem first.

Choose a tiny executable RuntimeIR fragment and one target semantics, then prove one complete semantic-preservation slice.

## Proposed first source fragment

A suitable RuntimeIR fragment includes:

~~~text
Bool
exact Nat literals
exact Nat addition/multiplication
local immutable bindings
pure function calls
small algebraic constructors/matches
~~~

Avoid effects, async, exceptions, strings, FFI, recursion, and optimization in the first theorem.

## Proposed first target

Direct JavaScript is the most useful first target if a sufficiently small explicit JS-core semantics is defined.

Direct Wasm is also viable, but should be a separate theorem once the source fragment and representation layer are stable.

## Required definitions

The proof should define:

- RuntimeIR syntax;
- RuntimeIR evaluation relation;
- target AST;
- target evaluation relation;
- value relation;
- lowering function;
- serializer relation;
- exact artifact identity relation;
- permitted resource/termination outcomes.

## Target theorem shape

For the chosen terminating pure fragment, prove something like:

~~~text
if
  source program P evaluates to value v
and
  lower(P) = T
then
  target program T evaluates to v'
and
  RelatedValue(v, v')
~~~

If target evaluation can fail for declared finite-resource reasons, state that relation explicitly rather than silently weakening the theorem.

## Serializer/artifact boundary

A theorem about an internal target AST does not prove the emitted file.

The first complete slice should eventually connect:

~~~text
Target AST
  -> canonical serializer
  -> exact emitted bytes
  -> independently parsed restricted target syntax
  -> target semantics
~~~

A hash identifies exact bytes; it does not prove the parser/serializer relation.

## Translation validation alternative

For later optimization passes, a sound per-artifact validator may be preferable:

~~~text
validate(sourceIR, targetIR, certificate) = accepted
  ->
Preserves(sourceIR, targetIR)
~~~

The validator itself needs a soundness argument.

## Explicit non-claims

This document does not claim:

- production RuntimeIR correctness;
- production direct-JS correctness;
- ECMAScript equivalence;
- correctness of JS BigInt as a complete Nat implementation;
- closure conversion correctness;
- source-to-RuntimeIR preservation;
- module/linker/bundler correctness;
- direct-Wasm correctness.

## Evidence status

Formal backend theorem: **not claimed in the final documentation-only branch state**.
Translation validator: **not implemented**.
Real target-semantics connection: **not established**.
Exact-artifact preservation: **not established**.
