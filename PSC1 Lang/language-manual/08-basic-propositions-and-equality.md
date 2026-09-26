# 8. Basic Propositions and Equality

PSC1 propositions live in `Prop`.

## Truth and proof terms

A proposition is a type.

An inhabitant is a proof.

## Implication

Implication is represented through function/Pi structure.

A theorem:

```proofscript
theorem keep(P: Prop): P -> P := by
  intro h;
  exact h;
```

constructs a function from proof to proof.

## Universal quantification

The dependent function type is also the core representation of universal
quantification.

Theorem binders therefore quantify over their parameters.

## Equality

```proofscript
x = y
```

is propositional equality.

The semantic equality type is the polymorphic Lean-compatible `Eq`.

## Reflexivity

```proofscript
theorem selfEq {α: Type}(x: α): x = x := by rfl;
```

uses definitional reflexivity.

## Equality transport

`rw` uses an Eq proof to transport the goal across an equality.

This is proof construction, not text substitution.

## Bool equality

```proofscript
x == y
```

is executable Bool-valued equality for supported operations.

It is not the same object as `x = y`.

## Logical connectives and existentials

Lean defines many basic propositions using inductive types.

PSC1's foundational model is compatible with that approach, but the first
source/tactic profile does not automatically claim every Lean connective,
notation, eliminator, or classical tactic.

Only gated syntax/semantics belong to the PSC1 claim.

## Classical reasoning

Any classical axioms admitted by a project/environment must be visible in its
trust story.

PSC1 does not silently treat host computation as classical proof.
